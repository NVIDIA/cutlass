# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import sys
from typing import Optional, Tuple, Literal, Type, Union

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import Pointer
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.moe.moe_utils import (
    MoEGroupedGemmTensormapConstructor,
)
from blackwell.kernel.moe.moe_persistent_scheduler import (
    MoEStaticSchedulerParams,
    MoEStaticPersistentTileScheduler,
    MoEWorkTileInfo,
)
from blackwell.kernel.moe.moe_sched_extension import GroupedMmSchedExtension
from cutlass.utils.gemm.sm100 import (
    transform_partitioned_tensor_layout,
    epilogue_tmem_copy_and_partition,
    epilogue_smem_copy_and_partition,
)


class GroupedGemmKernel:
    """
    Grouped GEMM kernel for MoE operations.

    PyTorch interface (from torch.nn.functional.grouped_mm):
    - 2Dx3D (Forward): mat_a(tokens_sum, K) x mat_b(experts, K, N) -> out(tokens_sum, N)
    - 2Dx2D (Weight grad): mat_a(hidden, tokens_sum) x mat_b(tokens_sum, intermediate) -> out(experts, hidden, intermediate)

    Kernel interface uses "fake" GEMM MNKL domain:

    2Dx3D:
        A_cute: (gemm_fake_m, gemm_k, 1)     # fake_m = tokens_sum, scheduler will offset
        B_cute: (gemm_n, gemm_k, gemm_fake_l) # fake_l = expert_idx, scheduler will select
        C_cute: (gemm_fake_m, gemm_n, 1)     # fake_m = tokens_sum, scheduler will offset

    2Dx2D:
        A_cute: (gemm_m, gemm_fake_k, 1)     # fake_k = tokens_sum, scheduler will offset
        B_cute: (gemm_n, gemm_fake_k, 1)     # fake_k = tokens_sum, scheduler will offset
        C_cute: (gemm_m, gemm_n, gemm_fake_l) # fake_l = expert_idx, scheduler will select

    The scheduler handles the fake dimensions by:
    - For fake_m/fake_k: Computing token_offset from offs and adjusting tensor coord
    - For fake_l: Selecting expert slice via L coordinate
    """

    def __init__(
        self,
        scenario: Literal["2Dx3D", "2Dx2D"],
        out_dtype: Type[cutlass.Numeric],
        accumulate_on_output: bool,
        separate_tensormap_init: bool = True,
        fixed_expert_cnt: Optional[int] = None,
        acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
        mma_tiler_mnk: Tuple[int, int, int] = (128, 128, 64),
        cluster_shape_mnk: Tuple[int, int, int] = (1, 1, 1),
        use_2cta_instrs: bool = False,
    ):
        # User-provided configs
        self.scenario = scenario
        self.out_dtype = out_dtype
        self.accumulate_on_output = accumulate_on_output
        self.separate_tensormap_init = separate_tensormap_init
        self.fixed_expert_cnt = fixed_expert_cnt  # Not used yet...
        self.acc_dtype = acc_dtype
        self.mma_tiler_mnk = mma_tiler_mnk
        self.cluster_shape_mn = (cluster_shape_mnk[0], cluster_shape_mnk[1])
        self.use_2cta_instrs = use_2cta_instrs
        self.arch = "sm_100"

        if accumulate_on_output and scenario == "2Dx3D":
            raise ValueError(
                "Non-sense config: grad accumulate should only happens in 2Dx2D."
            )

        self._validate_mma_tiler_and_cluster_shape()

        # K dimension is deferred in _setup_attributes
        self.mma_tiler = (mma_tiler_mnk[0], mma_tiler_mnk[1], 1)

        # CTA group for tcgen05 MMA
        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        # Occupancy and warp specialization
        self.occupancy = 1
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.sched_warp_id = 6
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                self.sched_warp_id,
                *self.epilogue_warp_id,
            )
        )

        # Barrier IDs for synchronization
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

    def _validate_mma_tiler_and_cluster_shape(self):
        """Validate codegen-time MMA tiler and cluster shape constraints."""
        m, n = self.mma_tiler_mnk[0], self.mma_tiler_mnk[1]
        cm, cn = self.cluster_shape_mn

        if self.use_2cta_instrs:
            valid_m = [128, 256]
        else:
            valid_m = [64, 128]
        if m not in valid_m:
            raise ValueError(
                f"mma_tiler M ({m}) must be one of {valid_m} "
                f"(use_2cta_instrs={self.use_2cta_instrs})"
            )

        if n not in range(32, 257, 32):
            raise ValueError(f"mma_tiler N ({n}) must be a multiple of 32 in [32, 256]")

        if cm % (2 if self.use_2cta_instrs else 1) != 0:
            raise ValueError(
                f"cluster_shape M ({cm}) must be even when use_2cta_instrs=True"
            )

        is_pow2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if cm * cn > 16 or not is_pow2(cm) or not is_pow2(cn):
            raise ValueError(
                f"Invalid cluster_shape ({cm}, {cn}): each dim must be "
                f"a power of 2, and product must be <= 16"
            )

    def _create_tiled_mma(self) -> cute.TiledMma:
        """Create tiled MMA atom based on input dtypes and major modes."""
        return utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

    def _setup_attributes(self) -> None:
        """
        Set up configurations that depend on GEMM inputs.

        This method configures:
        - tiled_mma with correct dtypes and major modes
        - MMA/cluster/tile shapes
        - Cluster layout
        - Multicast CTA counts
        - Epilogue tile shape
        - Stage counts (ACC, A/B, C)
        - SMEM layouts for A/B/C
        - Tensor memory allocation columns
        - TMA load bytes
        """
        tiled_mma = self._create_tiled_mma()

        # Use user-specified K dimension directly from mma_tiler_mnk
        # Verify K is a multiple of the MMA instruction's native K size
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        assert self.mma_tiler_mnk[2] % mma_inst_shape_k == 0, (
            f"mma_tiler K ({self.mma_tiler_mnk[2]}) must be a multiple of "
            f"MMA instruction K ({mma_inst_shape_k})"
        )
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.mma_tiler_mnk[2],
        )

        # CTA tile shape
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        # Cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Multicast CTA counts
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Epilogue tile shape (always use TMA store for MoE)
        self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        # C SMEM layout for epilogue
        c_smem_layout = utils.sm100.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, 1
        )

        self.smem_capacity = utils.get_smem_capacity_in_bytes()

        # Compute stage counts
        self.num_acc_stage = 2
        self.num_c_stage = 2  # Always use TMA store for MoE

        a_smem_layout_stage_one = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, 1
        )
        b_smem_layout_stage_one = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, 1
        )

        ab_bytes_per_stage = cute.size_in_bytes(
            self.a_dtype, a_smem_layout_stage_one
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout_stage_one)
        mbar_helpers_bytes = 1024
        c_bytes_per_stage = cute.size_in_bytes(self.c_dtype, c_smem_layout)
        c_bytes = c_bytes_per_stage * self.num_c_stage

        self.num_sched_stages = 2
        sched_work_tile_bytes_per_stage = 16  # 4 fields * sizeof(Int32)
        sched_bytes = sched_work_tile_bytes_per_stage * self.num_sched_stages

        fixed_overhead = mbar_helpers_bytes + c_bytes + sched_bytes

        self.num_ab_stage = (
            self.smem_capacity // self.occupancy - fixed_overhead
        ) // ab_bytes_per_stage

        # Refine epilogue stages with remaining SMEM
        self.num_c_stage += (
            self.smem_capacity
            - self.occupancy * ab_bytes_per_stage * self.num_ab_stage
            - self.occupancy * fixed_overhead
        ) // (self.occupancy * c_bytes_per_stage)

        # SMEM layouts
        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )
        self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
        )

        # Tensor memory allocation columns
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        self.num_tmem_alloc_cols = utils.get_num_tmem_alloc_cols(
            tCtAcc_fake, arch=self.arch
        )

        # TMA load bytes
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

    def get_workspace_size(self, expert_cnt: int) -> int:
        """
        Workspace size for expert-wise TMA descriptors.

        2Dx3D: Need C desc per expert -> expert_cnt * TensormapDescBytes
        2Dx2D: Need A and B desc per expert -> 2 * expert_cnt * TensormapDescBytes
        """
        return MoEGroupedGemmTensormapConstructor.get_workspace_size(
            self.scenario, expert_cnt
        )

    @cute.jit
    def __call__(
        self,
        mat_a: cute.Tensor,  # PyTorch mat_a
        mat_b: cute.Tensor,  # PyTorch mat_b
        out: cute.Tensor,  # PyTorch output
        offs: cute.Tensor,  # (experts,) cumsum
        bias: Optional[cute.Tensor],
        workspace: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ) -> None:
        """
        Launch the grouped GEMM kernel.

        This method:
        1. Transforms PyTorch tensors to GEMM domain tensors
        2. Infers dtypes and major modes from GEMM domain tensors
        3. Sets up kernel attributes
        4. Creates TMA atoms for A, B, C
        5. Creates scheduler parameters
        6. Launches the kernel
        """
        if cutlass.const_expr(bias is not None):
            raise NotImplementedError("bias is not supported yet (align with torch).")

        # =====================================================================
        # Step 1: Transform PyTorch tensors to GEMM domain (fake MNKL)
        # =====================================================================

        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(self.scenario == "2Dx3D"):
            # mat_a: (tokens_sum, hidden) -> A_cute: (fake_m, k, 1)
            tokens_sum, hidden = mat_a.shape
            a_gemm = cute.make_tensor(
                mat_a.iterator,
                cute.make_layout(
                    (tokens_sum, hidden, c1),
                    stride=(mat_a.stride[0], mat_a.stride[1], c0),
                ),
            )

            # mat_b: (experts, hidden, intermediate) -> B_cute: (n, k, fake_l)
            experts, hidden_b, intermediate = mat_b.shape
            b_gemm = cute.make_tensor(
                mat_b.iterator,
                cute.make_layout(
                    (intermediate, hidden_b, experts),
                    stride=(mat_b.stride[2], mat_b.stride[1], mat_b.stride[0]),
                ),
            )

            # out: (tokens_sum, intermediate) -> C_cute: (fake_m, n, 1)
            c_gemm = cute.make_tensor(
                out.iterator,
                cute.make_layout(
                    (tokens_sum, intermediate, c1),
                    stride=(out.stride[0], out.stride[1], c0),
                ),
            )

            expert_cnt = experts
            intermediate_dim = intermediate
            hidden_dim = hidden

        else:  # 2Dx2D
            # mat_a: (hidden, tokens_sum) -> A_cute: (m, fake_k, 1)
            hidden, tokens_sum = mat_a.shape
            a_gemm = cute.make_tensor(
                mat_a.iterator,
                cute.make_layout(
                    (hidden, tokens_sum, c1),
                    stride=(mat_a.stride[0], mat_a.stride[1], c0),
                ),
            )

            # mat_b: (tokens_sum, intermediate) -> B_cute: (n, fake_k, 1)
            tokens_sum_b, intermediate = mat_b.shape
            b_gemm = cute.make_tensor(
                mat_b.iterator,
                cute.make_layout(
                    (intermediate, tokens_sum_b, c1),
                    stride=(mat_b.stride[1], mat_b.stride[0], c0),
                ),
            )

            # out: (experts, hidden, intermediate) -> C_cute: (m, n, fake_l)
            experts, hidden_c, intermediate_c = out.shape
            c_gemm = cute.make_tensor(
                out.iterator,
                cute.make_layout(
                    (hidden_c, intermediate_c, experts),
                    stride=(out.stride[1], out.stride[2], out.stride[0]),
                ),
            )

            expert_cnt = experts
            intermediate_dim = intermediate
            hidden_dim = hidden

        # =====================================================================
        # Step 2: Infer dtypes and major modes from GEMM domain tensors
        # =====================================================================

        self.a_dtype: Type[cutlass.Numeric] = a_gemm.element_type
        self.b_dtype: Type[cutlass.Numeric] = b_gemm.element_type
        self.c_dtype: Type[cutlass.Numeric] = c_gemm.element_type
        self.a_major_mode = utils.LayoutEnum.from_tensor(a_gemm).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b_gemm).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c_gemm)

        # =====================================================================
        # Step 3: Setup kernel attributes
        # =====================================================================

        k = self.mma_tiler_mnk[2]
        a_tile_bits = self.a_dtype.width * k
        b_tile_bits = self.b_dtype.width * k
        if cutlass.const_expr(a_tile_bits % 256 != 0):
            raise ValueError(
                f"a_dtype ({self.a_dtype.width}b) * mma_tiler K ({k}) = "
                f"{a_tile_bits}b, must be a multiple of 256b (MMA instruction K width)"
            )
        if cutlass.const_expr(b_tile_bits % 256 != 0):
            raise ValueError(
                f"b_dtype ({self.b_dtype.width}b) * mma_tiler K ({k}) = "
                f"{b_tile_bits}b, must be a multiple of 256b (MMA instruction K width)"
            )

        self._setup_attributes()
        tiled_mma = self._create_tiled_mma()

        # =====================================================================
        # Step 4: Create TMA atoms for A, B, C
        # =====================================================================

        # TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a_gemm,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b_gemm,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # TMA store for C (or TMA reduce for accumulate_on_output)
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            c_tma_op, c_gemm, epi_smem_layout, self.epi_tile
        )

        # =====================================================================
        # Step 5: Create MoEStaticSchedulerParams and compute grid
        # =====================================================================

        sched_params = MoEStaticSchedulerParams(
            scenario=self.scenario,
            expert_shape=(expert_cnt, intermediate_dim, hidden_dim),
            cta_tile_shape_mnk=self.cta_tile_shape_mnk,
            cluster_shape_mn=self.cluster_shape_mn,
        )

        grid = MoEStaticSchedulerParams.get_grid_shape(
            sched_params, max_active_clusters
        )

        # =====================================================================
        # Step 5.5: Launch desc init kernel (if separate_tensormap_init)
        # =====================================================================
        #
        # Pre-initialize expert-wise TMA descriptors in workspace before
        # the main kernel. Stream ordering guarantees completion before
        # the main kernel starts.
        #
        # 2Dx3D: C desc per expert  (C has dynamic fake_m per expert)
        # 2Dx2D: A,B desc per expert (A,B have dynamic fake_k per expert)
        #

        if cutlass.const_expr(self.separate_tensormap_init):
            self.desc_init_kernel(
                tiled_mma,
                a_gemm,
                b_gemm,
                c_gemm,
                offs,
                expert_cnt,
                workspace.iterator,
                self.cluster_layout_vmnk,
                self.a_smem_layout_staged,
                self.b_smem_layout_staged,
                self.c_smem_layout_staged,
                self.epi_tile,
            ).launch(
                grid=(expert_cnt, 1, 1),
                block=[32, 1, 1],
                stream=stream,
                min_blocks_per_mp=1,
            )

        # =====================================================================
        # Step 6: Launch kernel
        # =====================================================================

        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c,
            a_gemm,
            b_gemm,
            c_gemm,
            offs,
            sched_params,
            workspace.iterator,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=self.occupancy,
        )

    # GPU device kernel: TMA descriptor initialization
    @cute.kernel
    def desc_init_kernel(
        self,
        tiled_mma: cute.TiledMma,
        a_gemm: cute.Tensor,  # GEMM domain A (fake MNKL)
        b_gemm: cute.Tensor,  # GEMM domain B (fake MNKL)
        c_gemm: cute.Tensor,  # GEMM domain C (fake MNKL)
        offs: cute.Tensor,  # (experts,) cumsum
        expert_cnt: Union[cutlass.Int32, int],
        workspace_ptr: Pointer,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
    ):
        """
        Separate kernel to pre-initialize expert-wise TMA descriptors.

        Grid: (expert_cnt, 1, 1) - one block per expert
        Block: (32, 1, 1) - one warp per block

        Each block constructs and writes TMA descriptors for one expert
        to the pre-allocated workspace buffer.

        2Dx3D: Creates C descriptor per expert (C has dynamic fake_m per expert)
        2Dx2D: Creates A and B descriptors per expert (A/B have dynamic fake_k per expert)
        """
        # =================================================================
        # Reconstruct TMA constructor with explicit attributes
        # =================================================================

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, None, 0))
        epi_smem_layout = cute.select(c_smem_layout_staged, mode=[0, 1])

        a_tma_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_tma_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        tensormap_ctor = MoEGroupedGemmTensormapConstructor(
            scenario=self.scenario,
            a_dtype=self.a_dtype,
            b_dtype=self.b_dtype,
            c_dtype=self.c_dtype,
            a_smem_layout=a_smem_layout,
            b_smem_layout=b_smem_layout,
            epi_smem_layout=epi_smem_layout,
            a_tma_op=a_tma_op,
            b_tma_op=b_tma_op,
            c_tma_op=c_tma_op,
            tiled_mma=tiled_mma,
            mma_tiler=self.mma_tiler,
            cluster_layout_vmnk_shape=cluster_layout_vmnk.shape,
            epi_tile=epi_tile,
            a_tensor=a_gemm,
            b_tensor=b_gemm,
            c_tensor=c_gemm,
            offs=offs,
            workspace_ptr=workspace_ptr,
        )

        # =================================================================
        # Each block constructs descriptors for one expert
        # =================================================================

        expert_idx, _, _ = cute.arch.block_idx()
        tensormap_ctor.construct_and_write(expert_idx)

    # GPU device kernel: main GEMM kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        tma_tensor_a: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        tma_tensor_b: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        tma_tensor_c: cute.Tensor,
        a_gemm: cute.Tensor,  # GEMM domain A (fake MNKL)
        b_gemm: cute.Tensor,  # GEMM domain B (fake MNKL)
        c_gemm: cute.Tensor,  # GEMM domain C (fake MNKL)
        offs: cute.Tensor,  # (experts,) cumsum
        sched_params: MoEStaticSchedulerParams,
        workspace_ptr: Pointer,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
    ):
        """
        GPU device kernel for MoE Grouped GEMM.

        Warp specialization:
        - Warps 0-3: Epilogue warps (TMEM -> RMEM -> SMEM -> GMEM)
        - Warp 4: MMA warp (tcgen05.mma)
        - Warp 5: TMA load warp (also prefetches expert-wise TMA descriptors)

        The kernel uses MoEStaticPersistentTileScheduler to iterate over tiles
        across all experts. For each tile:
        1. TMA load warp fetches A/B tiles using get_gmem_tensor
        2. MMA warp performs matrix multiply-accumulate
        3. Epilogue warps store results using TMA store/reduce

        Note: Python objects holding MLIR values cannot be kernel params.
        The following are constructed inside the kernel from individually-passed params:
        - tensormap_ctor: MoEGroupedGemmTensormapConstructor (online tensormap builder)
        - ext: GroupedMmSchedExtension (domain conversion + TMA desc selection)
        """
        # =================================================================
        # Reconstruct dicts that can't be passed as kernel params
        # =================================================================

        # Construct TMA descriptor creator and scheduler extension
        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, None, 0))
        epi_smem_layout = cute.select(c_smem_layout_staged, mode=[0, 1])

        a_tma_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_tma_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        if cutlass.const_expr(self.accumulate_on_output):
            c_tma_op = cpasync.CopyReduceBulkTensorTileS2GOp()
        else:
            c_tma_op = cpasync.CopyBulkTensorTileS2GOp()

        tensormap_ctor = MoEGroupedGemmTensormapConstructor(
            scenario=self.scenario,
            a_dtype=self.a_dtype,
            b_dtype=self.b_dtype,
            c_dtype=self.c_dtype,
            a_smem_layout=a_smem_layout,
            b_smem_layout=b_smem_layout,
            epi_smem_layout=epi_smem_layout,
            a_tma_op=a_tma_op,
            b_tma_op=b_tma_op,
            c_tma_op=c_tma_op,
            tiled_mma=tiled_mma,
            mma_tiler=self.mma_tiler,
            cluster_layout_vmnk_shape=cluster_layout_vmnk.shape,
            epi_tile=epi_tile,
            a_tensor=a_gemm,
            b_tensor=b_gemm,
            c_tensor=c_gemm,
            offs=offs,
            workspace_ptr=workspace_ptr,
        )
        ext = GroupedMmSchedExtension(
            scenario=self.scenario, tensormap_ctor=tensormap_ctor
        )

        # =================================================================
        # Kernel setup
        # =================================================================

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        # CTA/thread coordinates
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        # =================================================================
        # SharedStorage
        # =================================================================

        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            sched_buf: cute.struct.MemRange[cutlass.Int32, self.num_sched_stages * 4]
            sched_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_sched_stages * 2
            ]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        smem = utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # =================================================================
        # Pipelines
        # =================================================================

        # AB pipeline (TMA load → MMA)
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_tma_producer = self.num_mcast_ctas_a + self.num_mcast_ctas_b - 1
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()

        # ACC pipeline (MMA → epilogue)
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = (
            len(self.epilogue_warp_id) * 32 * (2 if use_2cta_instrs else 1)
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Scheduler pipeline (sched warp → tma/mma/epi warps)
        sched_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 32)
        num_sched_consumer_threads = 32 * len(
            (self.tma_warp_id, self.mma_warp_id, *self.epilogue_warp_id)
        )
        sched_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_sched_consumer_threads
        )
        sched_pipeline = pipeline.PipelineAsync.create(
            num_stages=self.num_sched_stages,
            producer_group=sched_producer_group,
            consumer_group=sched_consumer_group,
            barrier_storage=storage.sched_mbar_ptr.data_ptr(),
            defer_sync=True,
        )

        # TMEM allocator
        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr.ptr,
        )

        # Cluster barrier sync after init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # =================================================================
        # SMEM tensors A/B
        # =================================================================

        # (MMA, MMA_M, MMA_K, STAGE)
        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )

        # Multicast masks
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        # MMA fragments (SMEM → TMEM partitions)
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Cluster wait before TMEM alloc
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # =================================================================
        # Scheduler warp (warp 6)
        # =================================================================

        sched_buf_ptr = storage.sched_buf.data_ptr()
        sched_copy_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), cutlass.Int32, num_bits_per_copy=128
        )
        sched_buf_tensor = cute.make_tensor(
            sched_buf_ptr, cute.make_layout((4, self.num_sched_stages), stride=(1, 4))
        )

        if warp_idx == self.sched_warp_id:
            scheduler = MoEStaticPersistentTileScheduler.create(
                sched_params, offs, cute.arch.block_idx(), cute.arch.grid_dim()
            )

            sched_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_sched_stages
            )

            # Always produce the initial work_tile_info first
            work_tile_info = scheduler.initial_work_tile_info()
            sched_pipeline.producer_acquire(sched_producer_state)
            rmem = work_tile_info.to_rmem_tensor()
            cute.copy(
                sched_copy_atom,
                rmem,
                sched_buf_tensor[(None, sched_producer_state.index)],
            )
            cute.arch.fence_proxy("async.shared", space="cta")
            sched_pipeline.producer_commit(sched_producer_state)
            sched_producer_state.advance()

            # Iterate remaining tiles starting from the first advance
            work_tile_info = scheduler.advance_to_next_work()
            while work_tile_info.is_valid_tile:
                ext.prefetch_for_expert(work_tile_info.expert_idx)
                sched_pipeline.producer_acquire(sched_producer_state)
                rmem = work_tile_info.to_rmem_tensor()
                cute.copy(
                    sched_copy_atom,
                    rmem,
                    sched_buf_tensor[(None, sched_producer_state.index)],
                )
                cute.arch.fence_proxy("async.shared", space="cta")
                sched_pipeline.producer_commit(sched_producer_state)
                sched_producer_state.advance()

                work_tile_info = scheduler.advance_to_next_work()

            # Write invalid sentinel (expert_idx = -1) so consumers exit
            sched_pipeline.producer_acquire(sched_producer_state)
            sentinel = MoEWorkTileInfo(
                cutlass.Int32(-1), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)
            )
            rmem = sentinel.to_rmem_tensor()
            cute.copy(
                sched_copy_atom,
                rmem,
                sched_buf_tensor[(None, sched_producer_state.index)],
            )
            cute.arch.fence_proxy("async.shared", space="cta")
            sched_pipeline.producer_commit(sched_producer_state)

            sched_pipeline.producer_tail(sched_producer_state)

        # =================================================================
        # TMA load warp (warp 5)
        # =================================================================

        if warp_idx == self.tma_warp_id:
            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt

                # Get real GEMM domain tensors + TMA desc ptrs via extension
                real_a, desc_ptr_a = ext.get_gmem_tensor(
                    "a",
                    tma_tensor_a,
                    offs,
                    work_tile_info,
                )
                real_b, desc_ptr_b = ext.get_gmem_tensor(
                    "b",
                    tma_tensor_b,
                    offs,
                    work_tile_info,
                )

                # local_tile for this tile's A and B
                gA_mkl = cute.local_tile(
                    real_a,
                    cute.slice_(self.mma_tiler, (None, 0, None)),
                    (None, None, None),
                )
                gB_nkl = cute.local_tile(
                    real_b,
                    cute.slice_(self.mma_tiler, (0, None, None)),
                    (None, None, None),
                )

                # MMA partition for TMA
                thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
                tCgA = thr_mma.partition_A(gA_mkl)
                tCgB = thr_mma.partition_B(gB_nkl)

                # TMA partition
                a_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
                )
                b_cta_layout = cute.make_layout(
                    cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
                )
                tAsA, tAgA = cpasync.tma_partition(
                    tma_atom_a,
                    block_in_cluster_coord_vmnk[2],
                    a_cta_layout,
                    cute.group_modes(sA, 0, 3),
                    cute.group_modes(tCgA, 0, 3),
                )
                tBsB, tBgB = cpasync.tma_partition(
                    tma_atom_b,
                    block_in_cluster_coord_vmnk[1],
                    b_cta_layout,
                    cute.group_modes(sB, 0, 3),
                    cute.group_modes(tCgB, 0, 3),
                )

                # Slice to current tile coords (L=0 for MoE, expert already selected)
                mma_tile_m = work_tile_info.tile_m_idx // cute.size(
                    tiled_mma.thr_id.shape
                )
                tAgA_slice = tAgA[(None, mma_tile_m, None, 0)]
                tBgB_slice = tBgB[(None, work_tile_info.tile_n_idx, None, 0)]

                # TMA load loop
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_a,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        tma_desc_ptr=desc_ptr_b,
                        mcast_mask=b_full_mcast_mask,
                    )

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            ab_producer.tail()

        # =================================================================
        # MMA warp (warp 4)
        # =================================================================

        if warp_idx == self.mma_warp_id:
            # Retrieve TMEM
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )
            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt
                if is_leader_cta:
                    tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                    # AB consumer mainloop
                    ab_consumer.reset()
                    peek_ab_full_status = cutlass.Boolean(1)
                    if k_tile_cnt > 0:
                        peek_ab_full_status = ab_consumer.try_wait()
                        acc_pipeline.producer_acquire(acc_producer_state)

                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, handle.index)
                        cute.gemm(
                            tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc
                        )
                        handle.release()

                    if k_tile_cnt > 0:
                        acc_pipeline.producer_commit(acc_producer_state)
                if k_tile_cnt > 0:
                    acc_producer_state.advance()

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            acc_pipeline.producer_tail(acc_producer_state)

        # =================================================================
        # SMEM tensor C (allocated after MMA section, same as dense)
        # =================================================================

        sC = smem.allocate_tensor(
            element_type=self.c_dtype,
            layout=c_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=c_smem_layout_staged.inner,
        )

        # =================================================================
        # Epilogue warps (warps 0-3)
        # =================================================================

        if warp_idx < self.mma_warp_id:
            # Allocate TMEM
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            sched_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stages
            )
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage, producer_group=c_producer_group
            )

            epilog_sync_barrier = pipeline.NamedBarrier(
                barrier_id=self.epilog_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )

            # Epilogue copy setup (same for all tiles, depends only on shapes)
            # Transform ACC layout: ((ATOM_M, ATOM_N), MMA_M, MMA_N, STAGE)
            #                    -> ((ATOM_M, MMA_M), (ATOM_N, MMA_N), STAGE)
            tCtAcc_transformed = transform_partitioned_tensor_layout(tCtAcc_base)

            num_tiles_executed = cutlass.Int32(0)

            # Read initial work_tile_info
            sched_pipeline.consumer_wait(sched_consumer_state)
            rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
            cute.copy(
                sched_copy_atom,
                sched_buf_tensor[(None, sched_consumer_state.index)],
                rmem,
            )
            work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
            cute.arch.fence_acq_rel_cta()
            sched_pipeline.consumer_release(sched_consumer_state)
            sched_consumer_state.advance()

            while work_tile_info.is_valid_tile:
                k_tile_cnt = work_tile_info.k_tile_cnt
                # Get real C tensor + TMA desc ptr via extension
                real_c, desc_ptr_c = ext.get_gmem_tensor(
                    "c",
                    tma_tensor_c,
                    offs,
                    work_tile_info,
                )

                # local_tile + partition for C
                gC_mnl = cute.local_tile(
                    real_c,
                    cute.slice_(self.mma_tiler, (None, None, 0)),
                    (None, None, None),
                )
                thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
                tCgC = thr_mma.partition_C(gC_mnl)
                tCgC_transformed = transform_partitioned_tensor_layout(tCgC)

                mma_tile_coord_mnl = (
                    work_tile_info.tile_m_idx // cute.size(tiled_mma.thr_id.shape),
                    work_tile_info.tile_n_idx,
                    cutlass.Int32(0),
                )

                # Partition for TMEM → RMEM copy
                tiled_copy_t2r, tTR_tAcc_base, tTR_rAcc = (
                    epilogue_tmem_copy_and_partition(
                        self,
                        tidx,
                        tCtAcc_transformed,
                        tCgC_transformed,
                        epi_tile,
                        use_2cta_instrs,
                    )
                )
                tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
                tiled_copy_r2s, tRS_rC, tRS_sC = epilogue_smem_copy_and_partition(
                    self, tiled_copy_t2r, tTR_rC, tidx, sC
                )

                # TMA partition for C store (with expert-wise desc_ptr)
                tCgC_epi = cute.flat_divide(tCgC_transformed, epi_tile)
                bSG_sC, bSG_gC_partitioned = cpasync.tma_partition(
                    tma_atom_c,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sC, 0, 2),
                    cute.group_modes(tCgC_epi, 0, 2),
                )
                bSG_gC = bSG_gC_partitioned[(None, None, None, *mma_tile_coord_mnl)]

                # Set TMEM buffer for current tile
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]

                # Wait for accumulator buffer full
                if k_tile_cnt > 0:
                    acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))

                # Store accumulator to global memory in subtiles
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = num_tiles_executed * subtile_cnt

                for subtile_idx in range(subtile_cnt):
                    # TMEM → RMEM
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    if cutlass.const_expr(self.scenario == "2Dx2D"):
                        if k_tile_cnt > 0:
                            cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    else:
                        cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                    # Convert to output dtype
                    acc_vec = cute.zeros_like(tiled_copy_r2s.retile(tTR_rAcc))
                    if cutlass.const_expr(self.scenario == "2Dx2D"):
                        if k_tile_cnt > 0:
                            acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    else:
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                    acc_vec = acc_vec.to(self.c_dtype)
                    tRS_rC.store(acc_vec)

                    # RMEM → SMEM
                    c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                    cute.copy(
                        tiled_copy_r2s, tRS_rC, tRS_sC[(None, None, None, c_buffer)]
                    )
                    cute.arch.fence_proxy("async.shared", space="cta")
                    epilog_sync_barrier.arrive_and_wait()

                    # SMEM → GMEM (TMA store or TMA reduce)
                    if warp_idx == self.epilogue_warp_id[0]:
                        cute.copy(
                            tma_atom_c,
                            bSG_sC[(None, c_buffer)],
                            bSG_gC[(None, subtile_idx)],
                            tma_desc_ptr=desc_ptr_c,
                        )
                        c_pipeline.producer_commit()
                        c_pipeline.producer_acquire()
                    epilog_sync_barrier.arrive_and_wait()

                # Release accumulator buffer
                if k_tile_cnt > 0:
                    acc_pipeline.consumer_release(acc_consumer_state)
                    acc_consumer_state.advance()
                num_tiles_executed += cutlass.Int32(1)

                # Read next work_tile_info
                sched_pipeline.consumer_wait(sched_consumer_state)
                rmem = cute.make_rmem_tensor((4,), cutlass.Int32)
                cute.copy(
                    sched_copy_atom,
                    sched_buf_tensor[(None, sched_consumer_state.index)],
                    rmem,
                )
                work_tile_info = MoEWorkTileInfo.from_rmem_tensor(rmem)
                cute.arch.fence_acq_rel_cta()
                sched_pipeline.consumer_release(sched_consumer_state)
                sched_consumer_state.advance()

            # Wait for C store complete
            c_pipeline.producer_tail()

            # Free TMEM
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)


# =============================================================================
# Host Validation
# =============================================================================

from dataclasses import dataclass, field
import re

import numpy as np
import torch
import cutlass.torch as cutlass_torch


def torch_version_lt(major: int, minor: int) -> bool:
    """Best-effort torch version check that tolerates local build suffixes."""
    match = re.match(r"^\s*(\d+)\.(\d+)", torch.__version__)
    if match is None:
        print(
            "WARNING: failed to parse torch.__version__, "
            "falling back to torch._grouped_mm host reference."
        )
        return True
    version = (int(match.group(1)), int(match.group(2)))
    return version < (major, minor)


@dataclass
class ProblemDesc:
    tokens: int
    experts: int
    top_k_select: int
    balance_route: bool
    hidden: int
    intermediate: int
    scenario: Literal["2Dx3D", "2Dx2D"]
    ab_dtype: torch.dtype
    out_dtype: torch.dtype
    acc_dtype: torch.dtype
    grad_accumulate: bool = False
    # GEMM-domain layout control (which axis is stride-1)
    # A (M, K): "k_major" (default) or "m_major"
    # B (N, K): "n_major" (default) or "k_major"
    # C (M, N): "n_major" (default) or "m_major"
    a_layout: Literal["k_major", "m_major"] = "k_major"
    b_layout: Literal["k_major", "n_major"] = "n_major"
    c_layout: Literal["m_major", "n_major"] = "n_major"

    def __str__(self) -> str:
        d = lambda t: str(t).split(".")[-1]
        route = "balanced" if self.balance_route else "random"
        return (
            f"ProblemDesc: {self.scenario} | tokens={self.tokens} experts={self.experts} "
            f"top_k={self.top_k_select} route={route} | hidden={self.hidden} intermediate={self.intermediate} | "
            f"{d(self.ab_dtype)}->{d(self.out_dtype)}(acc={d(self.acc_dtype)}) grad_acc={self.grad_accumulate} | "
            f"layout: A={self.a_layout} B={self.b_layout} C={self.c_layout}"
        )


@dataclass
class ImplDesc:
    mma_tiler_mnk: Tuple[int, int, int]
    cluster_shape_mnk: Tuple[int, int, int]
    use_2cta_instrs: bool
    static_expert_cnt: Optional[int] = None
    separate_tensormap_init: bool = True

    def __str__(self) -> str:
        tile = ",".join(map(str, self.mma_tiler_mnk))
        cluster = ",".join(map(str, self.cluster_shape_mnk))
        static_e = (
            self.static_expert_cnt if self.static_expert_cnt is not None else "dynamic"
        )
        return (
            f"ImplDesc: tile={tile} cluster={cluster} 2cta={self.use_2cta_instrs} | "
            f"static_E={static_e} sep_tmap={self.separate_tensormap_init}"
        )


@dataclass
class MiscDesc:
    perf_run: bool = False
    perf_e2e: bool = False
    compare_with_bmm: bool = False
    compare_with_sol: bool = False
    no_torch_210: bool = field(init=False)

    def __post_init__(self):
        self.no_torch_210 = torch_version_lt(2, 10)
        if self.perf_e2e and not self.perf_run:
            raise ValueError("--perf_e2e requires --perf_run to be enabled.")
        if self.perf_e2e and self.compare_with_sol:
            raise ValueError(
                "--perf_e2e and --compare_with_sol are mutually exclusive."
            )

    def __str__(self) -> str:
        ref = "bmm" if self.compare_with_bmm else "grouped_mm"
        return (
            f"MiscDesc: perf={self.perf_run} perf_e2e={self.perf_e2e} "
            f"ref={ref} sol={self.compare_with_sol} no_torch_210={self.no_torch_210}"
        )


def l2_flush(size_mb: int = 400) -> None:
    """Best-effort L2 flush by touching a large temporary tensor."""
    num_bytes = size_mb * 1024 * 1024
    flush_buf = torch.randint(0, 256, (num_bytes,), dtype=torch.uint8, device="cuda")
    del flush_buf


class GroupedGemmTester:
    def __init__(self, problem: ProblemDesc, impl: ImplDesc, misc: MiscDesc):
        self.problem = problem
        self.impl = impl
        self.misc = misc

        self.tokens_after_repeat = problem.tokens * problem.top_k_select
        self.expert_cnt = problem.experts
        self.hidden = problem.hidden
        self.intermediate = problem.intermediate

        self.A_tensor: torch.Tensor = None
        self.B_tensor: torch.Tensor = None
        self.C_tensor: torch.Tensor = None
        self.C_ref_tensor: torch.Tensor = None
        self.offs_tensor: torch.Tensor = None
        self.workspace_tensor: torch.Tensor = None

        # This should be a common func
        self.temp_type_mapping = {
            torch.float32: cutlass.Float32,
            torch.bfloat16: cutlass.BFloat16,
            torch.float16: cutlass.Float16,
        }

    def _generate_offs(self) -> torch.Tensor:
        """Generate group-end offsets.

        Some experts may receive 0 tokens (valid in real MoE routing).
        """
        total = self.tokens_after_repeat
        expert_cnt = self.expert_cnt

        if self.problem.balance_route:
            base = total // expert_cnt
            remainder = total % expert_cnt
            sizes = [base + (1 if i < remainder else 0) for i in range(expert_cnt)]
        else:
            proportions = np.random.dirichlet([0.5] * expert_cnt)
            raw = np.floor(proportions * total).astype(int)
            deficit = total - raw.sum()
            while deficit > 0:
                idx = int(np.argmin(raw / (proportions * total + 1e-12)))
                raw[idx] += 1
                deficit -= 1
            while deficit < 0:
                ratios = np.where(
                    raw > 0,
                    raw / (proportions * total + 1e-12),
                    -np.inf,
                )
                idx = int(np.argmax(ratios))
                raw[idx] -= 1
                deficit += 1
            sizes = raw.tolist()

        assert sum(sizes) == total

        cum = 0
        offsets = []
        for s in sizes:
            cum += s
            offsets.append(cum)
        return torch.tensor(offsets, dtype=torch.int32, device="cuda")

    def _generate_tensor(self, shape: Tuple) -> torch.Tensor:
        if self.misc.perf_run:
            return torch.randn(shape, dtype=self.problem.ab_dtype, device="cuda")
        else:
            return torch.randint(-1, 2, shape, device="cuda", dtype=torch.int8).to(
                self.problem.ab_dtype
            )

    def _get_stream(self) -> cuda.CUstream:
        return cuda.CUstream(torch.cuda.current_stream().cuda_stream)

    def generate_inputs(self) -> None:
        self.offs_tensor = self._generate_offs()

        tokens = self.tokens_after_repeat
        hidden = self.hidden
        intermediate = self.intermediate
        expert_cnt = self.expert_cnt

        if self.problem.scenario == "2Dx3D":
            # PyTorch shape: A (tokens, hidden), B (expert_cnt, hidden, intermediate), C (tokens, intermediate)
            # GEMM domain:   A (M=tokens, K=hidden), B (N=intermediate, K=hidden), C (M=tokens, N=intermediate)

            # GEMM A: k_major → K(hidden) stride-1;  m_major → M(tokens) stride-1
            if self.problem.a_layout == "k_major":
                self.A_tensor = self._generate_tensor((tokens, hidden))
            else:
                self.A_tensor = self._generate_tensor((hidden, tokens)).T

            # GEMM B: n_major → N(intermediate) stride-1;  k_major → K(hidden) stride-1
            if self.problem.b_layout == "n_major":
                self.B_tensor = self._generate_tensor(
                    (expert_cnt, hidden, intermediate)
                )
            else:
                self.B_tensor = self._generate_tensor(
                    (expert_cnt, intermediate, hidden)
                ).transpose(1, 2)

            # GEMM C: n_major → N(intermediate) stride-1;  m_major → M(tokens) stride-1
            if self.problem.c_layout == "n_major":
                self.C_tensor = torch.full(
                    (tokens, intermediate),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                )
            else:
                self.C_tensor = torch.full(
                    (intermediate, tokens),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                ).T

        elif self.problem.scenario == "2Dx2D":
            # PyTorch shape: mat_a (hidden, tokens), mat_b (tokens, intermediate), out (expert_cnt, hidden, intermediate)
            # out matches weight shape (expert_cnt, hidden, intermediate) for weight gradient
            # GEMM domain:   A (M=hidden, K=tokens), B (N=intermediate, K=tokens), C (M=hidden, N=intermediate)

            # GEMM A: k_major → K(tokens) stride-1;  m_major → M(hidden) stride-1
            if self.problem.a_layout == "k_major":
                self.A_tensor = self._generate_tensor((hidden, tokens))
            else:
                self.A_tensor = self._generate_tensor((tokens, hidden)).T

            # GEMM B: n_major → N(intermediate) stride-1;  k_major → K(tokens) stride-1
            if self.problem.b_layout == "n_major":
                self.B_tensor = self._generate_tensor((tokens, intermediate))
            else:
                self.B_tensor = self._generate_tensor((intermediate, tokens)).T

            # GEMM C: n_major → N(intermediate) stride-1;  m_major → M(hidden) stride-1
            if self.problem.c_layout == "n_major":
                self.C_tensor = torch.full(
                    (expert_cnt, hidden, intermediate),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                )
            else:
                self.C_tensor = torch.full(
                    (expert_cnt, intermediate, hidden),
                    -1,
                    dtype=self.problem.out_dtype,
                    device="cuda",
                ).transpose(1, 2)
            if self.problem.grad_accumulate:
                self.C_tensor *= 0
        else:
            raise ValueError(f"Unknown scenario: {self.problem.scenario}")

    def compute_reference(self) -> None:
        if self.misc.perf_run:
            return
        if self.misc.compare_with_bmm:
            self._compute_reference_bmm()
        else:
            self._compute_reference_grouped_mm()

    def _compute_reference_grouped_mm(self) -> None:
        grouped_mm_op = (
            torch._grouped_mm
            if self.misc.no_torch_210
            else torch.nn.functional.grouped_mm
        )
        self.C_ref_tensor = grouped_mm_op(
            self.A_tensor,
            self.B_tensor,
            offs=self.offs_tensor,
            out_dtype=self.problem.out_dtype,
        )

    def _compute_reference_bmm(self) -> None:
        """Manual per-expert torch.mm loop as reference (avoids grouped_mm bugs on small cases)."""
        # Preallocate the full reference output to avoid keeping both the per-expert
        # results list and the final cat/stack result alive at the same time.
        self.C_ref_tensor = torch.empty_like(self.C_tensor)

        prev = 0
        for i in range(self.expert_cnt):
            cur = self.offs_tensor[i].item()
            if self.problem.scenario == "2Dx3D":
                # A (tokens, hidden), B (E, hidden, intermediate) → C_i (tokens_i, intermediate)
                a_slice = self.A_tensor[prev:cur, :]
                b_slice = self.B_tensor[i]
                self.C_ref_tensor[prev:cur, :].copy_(torch.mm(a_slice, b_slice))
            else:  # 2Dx2D
                # A (hidden, tokens), B (tokens, intermediate) → C_i (hidden, intermediate)
                a_slice = self.A_tensor[:, prev:cur]
                b_slice = self.B_tensor[prev:cur, :]
                self.C_ref_tensor[i, :, :].copy_(torch.mm(a_slice, b_slice))
            prev = cur

    def create_kernel(self) -> GroupedGemmKernel:
        return GroupedGemmKernel(
            scenario=self.problem.scenario,
            out_dtype=self.temp_type_mapping[self.problem.out_dtype],
            accumulate_on_output=self.problem.grad_accumulate
            and self.problem.scenario == "2Dx2D",
            separate_tensormap_init=self.impl.separate_tensormap_init,
            fixed_expert_cnt=self.impl.static_expert_cnt,
            acc_dtype=self.temp_type_mapping[self.problem.acc_dtype],
            mma_tiler_mnk=self.impl.mma_tiler_mnk,
            cluster_shape_mnk=self.impl.cluster_shape_mnk,
            use_2cta_instrs=self.impl.use_2cta_instrs,
        )

    def run_kernel(self, kernel: GroupedGemmKernel) -> Optional[float]:
        """Run our CuTe kernel.

        Returns:
            Average kernel time in ms when perf_e2e is enabled, None otherwise.
        """
        workspace_size = kernel.get_workspace_size(self.expert_cnt)
        self.workspace_tensor = torch.full(
            (workspace_size,), 255, dtype=torch.uint8, device="cuda"
        )

        torch.cuda.synchronize()

        ab_cutlass_dtype = self.temp_type_mapping[self.problem.ab_dtype]
        out_cutlass_dtype = self.temp_type_mapping[self.problem.out_dtype]

        a_cute, self.A_tensor = cutlass_torch.cute_tensor_like(
            self.A_tensor, ab_cutlass_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_cute, self.B_tensor = cutlass_torch.cute_tensor_like(
            self.B_tensor, ab_cutlass_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_cute, self.C_tensor = cutlass_torch.cute_tensor_like(
            self.C_tensor, out_cutlass_dtype, is_dynamic_layout=True, assumed_align=16
        )
        is_dynamic_expert_cnt = self.impl.static_expert_cnt is None
        offs_cute, self.offs_tensor = cutlass_torch.cute_tensor_like(
            self.offs_tensor,
            cutlass.Int32,
            is_dynamic_layout=is_dynamic_expert_cnt,
            assumed_align=16,
        )
        workspace_cute, self.workspace_tensor = cutlass_torch.cute_tensor_like(
            self.workspace_tensor,
            cutlass.Uint8,
            is_dynamic_layout=is_dynamic_expert_cnt,
            assumed_align=128,
        )

        # Query max active clusters from hardware
        cluster_size = self.impl.cluster_shape_mnk[0] * self.impl.cluster_shape_mnk[1]
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)
        print(f"A_tensor: {tuple(self.A_tensor.shape)}:{self.A_tensor.stride()}")
        print(f"B_tensor: {tuple(self.B_tensor.shape)}:{self.B_tensor.stride()}")
        print(
            f"offset_tensor: {tuple(self.offs_tensor.shape)}:{self.offs_tensor.stride()}"
        )
        print(f"C_tensor: {tuple(self.C_tensor.shape)}:{self.C_tensor.stride()}")

        stream = self._get_stream()

        if self.misc.perf_e2e:
            compiled = cute.compile(
                kernel,
                a_cute,
                b_cute,
                c_cute,
                offs_cute,
                None,  # bias
                workspace_cute,
                max_active_clusters,
                stream,
            )

            warmup_iters = 4
            timed_iters = 4

            for _ in range(warmup_iters):
                l2_flush()
                compiled(
                    a_cute,
                    b_cute,
                    c_cute,
                    offs_cute,
                    None,  # bias
                    workspace_cute,
                    stream,
                )
            torch.cuda.synchronize()

            times = []
            for _ in range(timed_iters):
                l2_flush()
                torch.cuda.synchronize()
                start_evt = torch.cuda.Event(enable_timing=True)
                end_evt = torch.cuda.Event(enable_timing=True)
                start_evt.record()
                compiled(
                    a_cute,
                    b_cute,
                    c_cute,
                    offs_cute,
                    None,  # bias
                    workspace_cute,
                    stream,
                )
                end_evt.record()
                torch.cuda.synchronize()
                times.append(start_evt.elapsed_time(end_evt))

            avg_ms = sum(times) / len(times)
            print(f"[perf_e2e] Individual times (ms): {[f'{t:.4f}' for t in times]}")
            print(f"[perf_e2e] Average kernel time: {avg_ms:.4f} ms")
            return avg_ms
        else:
            l2_flush()
            kernel(
                a_cute,
                b_cute,
                c_cute,
                offs_cute,
                None,  # bias
                workspace_cute,
                max_active_clusters,
                stream,
            )
            torch.cuda.synchronize()
            return None

    def validate(self) -> None:
        if not self.misc.perf_run:
            assert torch.equal(self.C_tensor, self.C_ref_tensor), (
                "Validation failed: C_tensor != C_ref_tensor"
            )

    def run_sol_comparison(self) -> None:
        """Run a dense batched GEMM as Speed-of-Light reference.

        Reuses the same tensor memory from the grouped run by
        view/reshape/permute -- zero GPU allocation.
        """
        import sys, os

        _examples_root = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..", "..")
        )
        if _examples_root not in sys.path:
            sys.path.insert(0, _examples_root)

        from blackwell.kernel.dense_gemm.dense_gemm_persistent import (
            PersistentDenseGemmKernel,
        )

        tokens = self.tokens_after_repeat
        experts = self.expert_cnt
        assert tokens % experts == 0, (
            f"compare_with_sol requires tokens*top_k ({tokens}) "
            f"evenly divisible by experts ({experts}) so every group "
            f"has exactly the same size"
        )
        tpe = tokens // experts

        if self.problem.scenario == "2Dx3D":
            M, N, K, L = tpe, self.intermediate, self.hidden, experts
        else:  # 2Dx2D
            M, N, K, L = self.hidden, self.intermediate, tpe, experts

        # Reshape into GEMM-domain batch-last: A(M,K,L), B(N,K,L), C(M,N,L).
        # Data values are irrelevant (perf only) — just need correct shape
        # and stride pattern so the dense kernel sees the right major mode.
        if self.problem.a_layout == "k_major":
            a_sol = self.A_tensor.contiguous().view(L, M, K).permute(1, 2, 0)
            leading_dim_a = 1
        else:
            a_sol = self.A_tensor.contiguous().view(L, K, M).permute(2, 1, 0)
            leading_dim_a = 0

        if self.problem.b_layout == "n_major":
            b_sol = self.B_tensor.contiguous().view(L, K, N).permute(2, 1, 0)
            leading_dim_b = 0
        else:
            b_sol = self.B_tensor.contiguous().view(L, N, K).permute(1, 2, 0)
            leading_dim_b = 1

        if self.problem.c_layout == "n_major":
            c_sol = self.C_tensor.contiguous().view(L, M, N).permute(1, 2, 0)
            leading_dim_c = 1
        else:
            c_sol = self.C_tensor.contiguous().view(L, N, M).permute(2, 1, 0)
            leading_dim_c = 0

        from cutlass.cute.runtime import from_dlpack

        a_cute_sol = from_dlpack(a_sol, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim_a
        )
        b_cute_sol = from_dlpack(b_sol, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim_b
        )
        c_cute_sol = from_dlpack(c_sol, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim_c
        )

        mma_tiler_mn = self.impl.mma_tiler_mnk[:2]
        cluster_shape_mn = self.impl.cluster_shape_mnk[:2]
        cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(cluster_size)

        sol_kernel = PersistentDenseGemmKernel(
            acc_dtype=self.temp_type_mapping[self.problem.acc_dtype],
            use_2cta_instrs=self.impl.use_2cta_instrs,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            use_tma_store=True,
        )

        print(f"\n[SOL] Dense BMM: M={M} N={N} K={K} L={L}")
        print(f"[SOL] a_sol: {tuple(a_sol.shape)}:{a_sol.stride()}")
        print(f"[SOL] b_sol: {tuple(b_sol.shape)}:{b_sol.stride()}")
        print(f"[SOL] c_sol: {tuple(c_sol.shape)}:{c_sol.stride()}")

        l2_flush()
        sol_kernel(
            a_cute_sol,
            b_cute_sol,
            c_cute_sol,
            max_active_clusters,
            self._get_stream(),
        )
        torch.cuda.synchronize()

    def run(self) -> None:
        from torch.profiler import profile, ProfilerActivity

        print(self.problem)
        print(self.impl)
        print(self.misc)
        self.generate_inputs()
        kernel = self.create_kernel()

        if self.misc.perf_e2e:
            self.run_kernel(kernel)
        else:
            with profile(
                activities=[ProfilerActivity.CUDA], record_shapes=True
            ) as prof:
                self.compute_reference()
                self.run_kernel(kernel)
                if (
                    self.misc.compare_with_sol
                    and self.misc.perf_run
                    and self.problem.balance_route
                ):
                    self.run_sol_comparison()
            print(prof.key_averages().table(sort_by="cuda_time_total", row_limit=20))

        self.validate()


if __name__ == "__main__":
    import argparse

    def parse_dtype(s: str) -> torch.dtype:
        return getattr(torch, s)

    def parse_tuple(s: str) -> Tuple[int, ...]:
        return tuple(int(x) for x in s.split(","))

    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", type=int, default=128)
    parser.add_argument("--experts", type=int, default=128)
    parser.add_argument("--top_k_select", type=int, default=8)
    parser.add_argument("--balance_route", action="store_true", default=False)
    parser.add_argument("--hidden", type=int, default=2048)
    parser.add_argument("--intermediate", type=int, default=7168)
    parser.add_argument(
        "--scenario", type=str, default="2Dx3D", choices=["2Dx3D", "2Dx2D"]
    )
    parser.add_argument("--ab_dtype", type=str, default="bfloat16")
    parser.add_argument("--out_dtype", type=str, default="bfloat16")
    parser.add_argument("--acc_dtype", type=str, default="float32")
    parser.add_argument("--grad_accumulate", action="store_true", default=False)
    parser.add_argument(
        "--a_layout", type=str, default="k_major", choices=["k_major", "m_major"]
    )
    parser.add_argument(
        "--b_layout", type=str, default="n_major", choices=["k_major", "n_major"]
    )
    parser.add_argument(
        "--c_layout", type=str, default="n_major", choices=["m_major", "n_major"]
    )
    parser.add_argument("--mma_tiler_mnk", type=str, default="128,128,64")
    parser.add_argument("--cluster_shape_mnk", type=str, default="1,1,1")
    parser.add_argument("--use_2cta_instrs", action="store_true", default=False)
    parser.add_argument("--static_expert_cnt", type=int, default=None)
    parser.add_argument("--separate_tensormap_init", action="store_true", default=False)
    parser.add_argument("--perf_run", action="store_true", default=False)
    parser.add_argument("--perf_e2e", action="store_true", default=False)
    parser.add_argument("--compare_with_bmm", action="store_true", default=False)
    parser.add_argument("--compare_with_sol", action="store_true", default=False)
    args = parser.parse_args()

    problem = ProblemDesc(
        tokens=args.tokens,
        experts=args.experts,
        top_k_select=args.top_k_select,
        balance_route=args.balance_route,
        hidden=args.hidden,
        intermediate=args.intermediate,
        scenario=args.scenario,
        ab_dtype=parse_dtype(args.ab_dtype),
        out_dtype=parse_dtype(args.out_dtype),
        acc_dtype=parse_dtype(args.acc_dtype),
        grad_accumulate=args.grad_accumulate,
        a_layout=args.a_layout,
        b_layout=args.b_layout,
        c_layout=args.c_layout,
    )
    if not args.separate_tensormap_init:
        print(
            "Change separate_tensormap_init to True as current the fused version not implmented yet."
        )
        args.separate_tensormap_init = True
    impl = ImplDesc(
        mma_tiler_mnk=parse_tuple(args.mma_tiler_mnk),
        cluster_shape_mnk=parse_tuple(args.cluster_shape_mnk),
        use_2cta_instrs=args.use_2cta_instrs,
        static_expert_cnt=args.static_expert_cnt,
        separate_tensormap_init=args.separate_tensormap_init,
    )

    misc = MiscDesc(
        perf_run=args.perf_run,
        perf_e2e=args.perf_e2e,
        compare_with_bmm=args.compare_with_bmm,
        compare_with_sol=args.compare_with_sol,
    )
    if misc.no_torch_210:
        misc.compare_with_bmm = True
        print("Override to set --compare_with_bmm to avoid possible torch crash.")

    tester = GroupedGemmTester(problem, impl, misc)
    tester.run()
    print("PASS")
