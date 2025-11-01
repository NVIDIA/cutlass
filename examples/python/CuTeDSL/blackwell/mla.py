# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import argparse
import math
from typing import Type, Tuple, Optional, Callable
from types import SimpleNamespace
from functools import partial

import torch
import torch.nn.functional as F
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.cute.nvgpu.tcgen05 as tcgen05
import cutlass.cute.nvgpu.cpasync as cpasync
import cutlass.utils as utils
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack

"""
A Multi-Head Latent Attention (MLA) example for the NVIDIA Blackwell SM100 architecture using CUTE DSL

This example demonstrates an implementation of inference of multi-head latent attention using a TMA + Blackwell
SM100 TensorCore warp-specialized persistent kernel. The implementation integrates the (Qc + Qr)*(Kc + Kr)^T
matrix multiplication, softmax normalization, and softmax((Qc + Qr)*(Kc + Kr)^T)*Vc into a single kernel.
The kernel provides support for page table storage and variable-length KV cache sequences. It implements KV splitting
functionality to minimize latency when processing long KV sequences.

The kernel implements key optimizations including:
- Warp specialization for different computation phases (load, MMA, softmax, correction, epilogue)
- Pipeline stages between different warps for overlapping computation and memory access
- Support for different precision data types
- Two sub-kernels (split KV kernel and reduction kernel) that enable split KV processing

To run this example:

.. code-block:: bash

    python examples/blackwell/mla.py                                     \
      --batch_size 4 --latent_dim 512 --rope_dim 64                      \
      --num_heads 128 --seq_len 1024                                     \
      --in_dtype Float8E4M3FN --out_dtype Float16                        \
      --acc_dtype Float32 --lse_dtype Float32                            \
      --use_page_table --is_var_seq --is_var_split_kv                    \
      --is_persistent

The above example runs Multi-Head Latent Attention (MLA) with the following configuration:
- Batch size: 4
- Sequence length: 1024
- Latent dimension: 512
- RoPE dimension: 64
- Number of heads: 128
- Data types: Float8E4M3FN (input), Float16 (output), Float32 (accumulation and LSE)

It utilizes page table storage for the KV cache and enables both variable-length KV cache sequences
and variable split KV processing with persistent scheduling.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/blackwell/mla.py                                 \
      --batch_size 4 --latent_dim 512 --rope_dim 64                      \
      --num_heads 128 --seq_len 1024                                     \
      --in_dtype Float8E4M3FN --out_dtype Float16                        \
      --acc_dtype Float32 --lse_dtype Float32                            \
      --use_page_table --is_var_seq --is_var_split_kv                    \
      --is_persistent --warmup_iterations 3                              \
      --iterations 10 --skip_ref_check

Constraints for this example:
* Data type requirements:
  - Input/output: Float8E4M3FN or Float16
  - Accumulation and LSE: Float32
* Fixed architecture parameters:
  - Number of attention heads: 128
  - Latent dimension: 512
  - RoPE dimension: 64
* Input query modes should be (NumHeads, LatentDim/RopeDim, BatchSize)
* Input kv latent/rope modes should be (SeqLen, LatentDim/RopeDim, BatchSize)
* Query sequence length must be 1
* Only supports 2-CTA instructions
* Variable sequence length requires page table storage enabled
"""


class MLAStaticTileSchedulerParams:
    def __init__(
        self,
        is_persistent: bool,
        problem_shape_b: cute.Int32,
        cluster_shape_mnk: cute.Shape,
        split_kv: cutlass.Int32,
        *,
        loc=None,
        ip=None,
    ):
        """The static tile scheduler parameters prepared for MLA static tile scheduler.

        :param is_persistent: Whether to use persistent kernel mode
        :type is_persistent: bool
        :param problem_shape_b: The shape of the problem
        :type problem_shape_b: cute.Int32
        :param cluster_shape_mnk: The shape of the cluster
        :type cluster_shape_mnk: cute.Shape
        :param split_kv: The scalar factor for split KV
        """
        self.is_persistent = is_persistent
        self.problem_shape_b = problem_shape_b
        self.cluster_shape_mnk = cluster_shape_mnk
        self.split_kv = split_kv
        self.loc = loc
        self.ip = ip

    def __extract_mlir_values__(self):
        values = cutlass.extract_mlir_values(self.problem_shape_b)
        values += cutlass.extract_mlir_values(self.split_kv)
        return values

    def __new_from_mlir_values__(self, values):
        problem_shape_b = cutlass.new_from_mlir_values(
            self.problem_shape_b, (values[0],)
        )
        split_kv = cutlass.new_from_mlir_values(self.split_kv, (values[1],))
        return MLAStaticTileSchedulerParams(
            self.is_persistent,
            problem_shape_b,
            self.cluster_shape_mnk,
            split_kv,
            loc=self.loc,
        )


def create_mla_static_tile_scheduler_params(
    is_persistent: bool,
    problem_shape_b: cute.Int32,
    cluster_shape_mnk: cute.Shape,
    split_kv: cutlass.Int32,
) -> MLAStaticTileSchedulerParams:
    return MLAStaticTileSchedulerParams(
        is_persistent, problem_shape_b, cluster_shape_mnk, split_kv
    )


class MLAStaticTileScheduler:
    def __init__(
        self,
        params: MLAStaticTileSchedulerParams,
        current_work_linear_idx: cutlass.Int32,
        blk_coord: cute.Coord,
        grid_shape: cute.Shape,
        *,
        is_valid: bool = True,
        loc=None,
        ip=None,
    ):
        """The static tile scheduler for MLA split kv kernel.
        Based on `is_persistent`, it provides 2 modes for use:
        - Persistent mode: Launch fixed blocks and reschedule the data blocks.
        - Non-persistent mode: Launch dynamic blocks and exit when the current work is done.

        :param params: The static tile scheduler parameters
        :type params: MLAStaticTileSchedulerParams
        :param current_work_linear_idx: The linear index of the current work
        :type current_work_linear_idx: cutlass.Int32
        :param blk_coord: The coordinate of the current work
        :type blk_coord: cute.Coord
        :param grid_shape: The shape of the grid
        :type grid_shape: cute.Shape
        :param is_valid: Whether the current work is valid
        :type is_valid: bool
        """
        self.params = params
        self.blk_coord = blk_coord
        self.grid_shape = grid_shape
        self.current_work_linear_idx = current_work_linear_idx
        if params.is_persistent:
            self.persistent_blk_layout = cute.make_layout(
                (
                    params.cluster_shape_mnk[0],
                    1,
                    params.problem_shape_b,
                    params.split_kv,
                ),
                loc=loc,
                ip=ip,
            )
            self.num_blocks = cute.size(self.persistent_blk_layout, loc=loc, ip=ip)
            # Used for persistent scheduling
            self.num_persistent_sm = cute.size(grid_shape, loc=loc, ip=ip)
        else:
            self.is_valid = is_valid
        self.loc = loc
        self.ip = ip

    @staticmethod
    def get_grid_shape(
        params: MLAStaticTileSchedulerParams,
        max_active_clusters: int,
        *,
        loc=None,
        ip=None,
    ) -> cute.Shape:
        # called by host
        grid_shape = (
            params.cluster_shape_mnk[0],
            params.problem_shape_b,
            params.split_kv,
        )
        if params.is_persistent:
            return (
                cutlass.min(
                    max_active_clusters * cute.size(params.cluster_shape_mnk),
                    cute.size(grid_shape, loc=loc, ip=ip),
                ),
                1,
                1,
            )
        else:
            return grid_shape

    def get_current_work(self, *, loc=None, ip=None) -> utils.WorkTileInfo:
        is_valid = (
            self.current_work_linear_idx < self.num_blocks
            if self.params.is_persistent
            else self.is_valid
        )

        if self.params.is_persistent:
            blk_coord = self.persistent_blk_layout.get_hier_coord(
                self.current_work_linear_idx, loc=loc, ip=ip
            )
        else:
            blk_coord = (self.blk_coord[0], 0, self.blk_coord[1], self.blk_coord[2])

        return utils.WorkTileInfo(blk_coord, is_valid)

    def initial_work_tile_info(self, *, loc=None, ip=None):
        return self.get_current_work(loc=loc, ip=ip)

    def advance_to_next_work(self, *, advance_count=1, loc=None, ip=None):
        if self.params.is_persistent:
            self.current_work_linear_idx += advance_count * self.num_persistent_sm
        else:
            self.is_valid = False

    def __extract_mlir_values__(self):
        values = cutlass.extract_mlir_values(self.params)
        values.extend(cutlass.extract_mlir_values(self.current_work_linear_idx))
        values.extend(cutlass.extract_mlir_values(self.blk_coord))
        values.extend(cutlass.extract_mlir_values(self.grid_shape))
        return values

    def __new_from_mlir_values__(self, values):
        assert len(values) == 9
        new_params = cutlass.new_from_mlir_values(self.params, values[0:2])
        new_current_work_linear_idx = cutlass.new_from_mlir_values(
            self.current_work_linear_idx, [values[2]]
        )
        new_blk_coord = cutlass.new_from_mlir_values(self.blk_coord, values[3:6])
        new_grid_shape = cutlass.new_from_mlir_values(self.grid_shape, values[6:])
        return MLAStaticTileScheduler(
            new_params, new_current_work_linear_idx, new_blk_coord, new_grid_shape
        )


def create_mla_static_tile_scheduler(
    params: MLAStaticTileSchedulerParams,
    blk_coord: cute.Coord,
    grid_shape: cute.Shape,
) -> MLAStaticTileScheduler:
    return MLAStaticTileScheduler(params, blk_coord[0], blk_coord, grid_shape)


LOG2_E = 1.4426950408889634074
# avoid register indexing on array.
MAX_SPLITS = 256


class BlackwellMultiHeadLatentAttentionForward:
    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        lse_dtype: Type[cutlass.Numeric],
        mma_qk_tiler_mn: Tuple[int, int],
        mma_pv_tiler_mn: Tuple[int, int],
        max_active_clusters: int,
        is_persistent: bool,
        is_cpasync: bool,
        use_page_table: bool,
        is_var_seq: bool,
        is_var_split_kv: bool,
    ):
        """Initializes the configuration for a Blackwell Multi-Head Latent Attention (MLA) kernel.

        :param acc_dtype: Data type for accumulation S and O
        :type acc_dtype: Type[cutlass.Numeric]
        :param lse_dtype: Data type for output LSE
        :type lse_dtype: Type[cutlass.Numeric]
        :param mma_s_tiler: The (H, K) tile shape of the MMA instruction for S
        :type mma_s_tiler: Tuple[int, int]
        :param mma_p_tiler: The (H, D) tile shape of the MMA instruction for P
        :type mma_p_tiler: Tuple[int, int]
        :param max_active_clusters: Maximum number of active clusters
        :type max_active_clusters: int
        :param is_persistent: Whether to use persistent kernel mode
        :type is_persistent: bool
        :param is_cpasync: Whether to use CP async mode
        :type is_cpasync: bool
        :param use_page_table: Whether to use page table
        :type use_page_table: bool
        :param is_var_seq: Whether to use variable sequence length
        :type is_var_seq: bool
        :param is_var_split_kv: Whether to use variable split KV
        :type is_var_split_kv: bool
        """

        self.latent_dim = 512
        self.rope_dim = 64
        self.acc_dtype = acc_dtype
        self.lse_dtype = lse_dtype
        self.mma_qk_tiler_mn = mma_qk_tiler_mn
        self.mma_pv_tiler_mn = mma_pv_tiler_mn
        self.max_active_clusters = max_active_clusters
        self.is_persistent = is_persistent
        self.is_cpasync = is_cpasync
        self.use_page_table = use_page_table
        self.is_var_seq = is_var_seq
        self.is_var_split_kv = is_var_split_kv
        self.cluster_shape_mnk = (2, 1, 1)
        self.use_2cta_instrs = True
        # When using 2 CTAs with m=128: warps 0-1 handle accumulation for first half [0, n/2),
        # while warps 2-3 handle accumulation for second half [n/2, n)
        self.warps_in_n = 2
        self.num_compute_warps = 4
        self.threads_per_warp = 32
        self.num_load_warps = 2 if self.is_cpasync else 1
        mma_qk_tiler_k = self.rope_dim if self.is_cpasync else self.rope_dim * 2
        self.mma_qk_tiler = (
            self.mma_qk_tiler_mn[0],
            self.mma_qk_tiler_mn[1],
            mma_qk_tiler_k,
        )
        self.mma_pv_tiler = (
            self.mma_pv_tiler_mn[0],
            self.mma_pv_tiler_mn[1],
            self.mma_qk_tiler[1] * self.mma_qk_tiler[2] // self.mma_pv_tiler_mn[1],
        )
        self.iterations_qk_latent = self.latent_dim // self.mma_qk_tiler[2]
        self.iterations_qk_rope = mma_qk_tiler_k // self.mma_qk_tiler[2]
        self.iterations_qk = self.iterations_qk_latent + self.iterations_qk_rope
        self.iterations_pv_k = self.mma_qk_tiler[1] // self.mma_pv_tiler[2]
        self.iterations_pv_n = self.latent_dim // self.mma_pv_tiler[1]

        # Set specialized warp ids
        self.compute_warp_ids = (0, 1, 2, 3)
        self.correction_warp_ids = (4, 5, 6, 7)
        self.mma_warp_id = 8
        if self.is_cpasync:
            self.load_cp_async_warp_ids = (9, 10)
            self.load_pt_warp_id = 11
            self.threads_per_cta = self.threads_per_warp * len(
                (
                    self.mma_warp_id,
                    *self.load_cp_async_warp_ids,
                    self.load_pt_warp_id,
                    *self.compute_warp_ids,
                    *self.correction_warp_ids,
                )
            )
        else:
            self.load_tma_warp_id = 9
            self.empty_warp_ids = (10, 11)
            self.threads_per_cta = self.threads_per_warp * len(
                (
                    self.mma_warp_id,
                    self.load_tma_warp_id,
                    *self.compute_warp_ids,
                    *self.correction_warp_ids,
                    *self.empty_warp_ids,
                )
            )

        # register settings
        self.softmax_reg_num = 192
        self.correction_reg_num = 192
        self.other_reg_num = 112
        # Named barriers
        self.tmem_ptr_sync_bar = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=(
                self.threads_per_warp
                + self.threads_per_warp * self.num_compute_warps * 2
            ),
        )
        self.softmax_exchange_sync_bar = pipeline.NamedBarrier(
            barrier_id=2, num_threads=(self.threads_per_warp * self.num_compute_warps)
        )
        self.epilogue_exchange_sync_bar = pipeline.NamedBarrier(
            barrier_id=3, num_threads=(self.threads_per_warp * self.num_compute_warps)
        )

    def _setup_attributes(self):
        """Set up configurations and parameters for the MLA kernel operation.

        This method initializes and configures various attributes required for the
        execution of the multi-head latent attention kernel, mainly about the pipeline stages:

        - Sets up staging parameters for Q, K, V inputs and accumulator data
        - Configures pipeline stages for softmax, correction, and epilogue operations
        """

        self.load_q_stage = self.iterations_qk
        self.load_kv_stage = (24 if self.is_cpasync else 12) // (
            self.k_dtype.width // 8
        )
        self.mma_s_stage = 2
        self.p_mma_stage = 2
        self.p_cor_stage = 2
        self.mma_o_stage = 1
        self.load_pt_stage = self.load_kv_stage if self.is_cpasync else 1

        self.tmem_o_offset = self.mma_s_stage * self.mma_qk_tiler[1] // self.warps_in_n
        self.correction_factor_offset = (
            self.tmem_o_offset + self.latent_dim // self.warps_in_n
        )

    @cute.jit
    def __call__(
        self,
        q_latent: cute.Tensor,
        q_rope: cute.Tensor,
        c_latent: cute.Tensor,
        c_rope: cute.Tensor,
        page_table: cute.Tensor,
        o: cute.Tensor,
        lse: cute.Tensor,
        workspace: cute.Tensor,
        split_kv: cutlass.Int32,
        cache_seqs: Optional[cute.Tensor],
        block_split_kvs: Optional[cute.Tensor],
        softmax_scale: cutlass.Float32,
        output_scale: cutlass.Float32,
        stream: cuda.CUstream,
    ):
        """Execute the Multi-Head Latent Attention operation on the provided tensors.

        The method handles:
        1. Initialization of workspace for temporary split KV buffers
        2. Validation of tensor data types
        3. Initialization of hardware-specific parameters and memory layouts
        4. Configuration of TMA (Tensor Memory Access) operations
        5. Grid and work scheduling computation
        6. Kernel launch(split KV kernel and reduction kernel) with appropriate parameters

        :param q_latent: The query tensor with shape [num_head, latent_dim, batch_size]
        :type q_latent: cute.Tensor
        :param q_rope: The query RoPE tensor with shape [num_head, rope_dim, batch_size]
        :type q_rope: cute.Tensor
        :param c_latent: The key tensor with shape [seq_len, latent_dim, batch_size]
        :type c_latent: cute.Tensor
        :param c_rope: The key RoPE tensor with shape [seq_len, rope_dim, batch_size]
        :type c_rope: cute.Tensor
        :param page_table: The page table tensor with shape [page_count, batch_size]
        :type page_table: cute.Tensor
        :param o: The output tensor with shape [num_head, latent_dim, batch_size]
        :type o: cute.Tensor
        :param lse: The LSE tensor with shape [num_head, batch_size]
        :type lse: cute.Tensor
        :param workspace: The workspace tensor with 1-d shape prepared for acc_o and acc_lse
        :type workspace: cute.Tensor
        :param split_kv: The scalar factor for split KV
        :type split_kv: cutlass.Int32
        :param cache_seqs: The cache sequences tensor with shape [batch_size]
        :type cache_seqs: cute.Tensor
        :param block_split_kvs: The block split KV tensor with shape [batch_size]
        :type block_split_kvs: cute.Tensor
        :param softmax_scale: The scale factor for softmax
        :type softmax_scale: cutlass.Float32
        :param output_scale: The scale factor for the output
        :type output_scale: cutlass.Float32
        :param stream: The CUDA stream to execute the kernel on
        :type stream: cuda.CUstream

        :raises TypeError: If tensor data types don't match or aren't supported
        """

        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q_latent.element_type
        self.k_dtype = c_latent.element_type
        self.v_dtype = c_latent.element_type
        self.o_dtype = o.element_type

        # check type consistency
        if cutlass.const_expr(
            self.q_dtype != self.k_dtype or self.q_dtype != self.v_dtype
        ):
            raise TypeError(
                f"Type mismatch: {self.q_dtype} != {self.k_dtype} or {self.q_dtype} != {self.v_dtype}"
            )
        # check leading dimensions of input/output
        if cutlass.const_expr(q_latent.stride[1] != 1 or q_rope.stride[1] != 1):
            raise ValueError("q_latent and q_rope must have leading dimension 1")
        if cutlass.const_expr(c_latent.stride[1] != 1 or c_rope.stride[1] != 1):
            raise ValueError("c_latent and c_rope must have leading dimension 1")
        if cutlass.const_expr(o.stride[1] != 1):
            raise ValueError("o must have leading dimension 1")
        if cutlass.const_expr(lse.stride[0] != 1):
            raise ValueError("lse must have leading dimension 0")

        acc_o, acc_lse = self.initialize_workspace(
            q_latent.shape[0],
            q_latent.shape[1],
            q_latent.shape[2],
            split_kv,
            self.acc_dtype,
            workspace,
        )

        c_latent_tranpose_layout = cute.select(c_latent.layout, mode=[1, 0, 2])
        c_latent_transpose = cute.make_tensor(
            c_latent.iterator, c_latent_tranpose_layout
        )

        self.q_major_mode = tcgen05.OperandMajorMode.K
        self.k_major_mode = tcgen05.OperandMajorMode.K
        self.v_major_mode = tcgen05.OperandMajorMode.MN

        self._setup_attributes()

        cta_group = tcgen05.CtaGroup.TWO
        # the intermediate tensor p is from smem & k-major
        p_major_mode = tcgen05.OperandMajorMode.K
        qk_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.acc_dtype,
            cta_group,
            self.mma_qk_tiler[:2],
        )
        pv_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.acc_dtype,
            cta_group,
            self.mma_pv_tiler[:2],
        )

        cta_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape_mnk),
            (qk_tiled_mma.thr_id.shape,),
        )

        self.epi_tile = self.mma_pv_tiler[:2]

        q_smem_layout_staged = sm100_utils.make_smem_layout_a(
            qk_tiled_mma,
            self.mma_qk_tiler,
            self.q_dtype,
            self.load_q_stage,
        )
        kc_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.mma_qk_tiler,
            self.k_dtype,
            self.load_kv_stage,
        )
        p_smem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma,
            self.mma_pv_tiler,
            self.q_dtype,
            (self.iterations_pv_k * self.p_mma_stage),
        )
        p_smem_layout_staged = cute.logical_divide(
            p_smem_layout_staged, (None, None, None, self.iterations_pv_k)
        )
        vc_smem_layout_staged = sm100_utils.make_smem_layout_b(
            pv_tiled_mma,
            self.mma_pv_tiler,
            self.v_dtype,
            self.load_kv_stage,
        )
        if cutlass.const_expr(not self.is_cpasync):
            # TMA load for Q latent and rope
            tma_load_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(cta_group)

            q_smem_layout = cute.select(q_smem_layout_staged, mode=[0, 1, 2])
            tma_atom_q_latent, tma_tensor_q_latent = cute.nvgpu.make_tiled_tma_atom_A(
                tma_load_op,
                q_latent,
                q_smem_layout,
                self.mma_qk_tiler,
                qk_tiled_mma,
                cta_layout_vmnk.shape,
            )
            tma_atom_q_rope, tma_tensor_q_rope = cute.nvgpu.make_tiled_tma_atom_A(
                tma_load_op,
                q_rope,
                q_smem_layout,
                self.mma_qk_tiler,
                qk_tiled_mma,
                cta_layout_vmnk.shape,
            )
            # TMA load for c latent and k rope
            kc_smem_layout = cute.select(kc_smem_layout_staged, mode=[0, 1, 2])
            tma_atom_c_latent, tma_tensor_c_latent = cute.nvgpu.make_tiled_tma_atom_B(
                tma_load_op,
                c_latent,
                kc_smem_layout,
                self.mma_qk_tiler,
                qk_tiled_mma,
                cta_layout_vmnk.shape,
            )
            tma_atom_c_rope, tma_tensor_c_rope = cute.nvgpu.make_tiled_tma_atom_B(
                tma_load_op,
                c_rope,
                kc_smem_layout,
                self.mma_qk_tiler,
                qk_tiled_mma,
                cta_layout_vmnk.shape,
            )
            # TMA load for c latent transpose
            vc_smem_layout = cute.select(vc_smem_layout_staged, mode=[0, 1, 2])
            tma_atom_c_latent_transpose, tma_tensor_c_latent_transpose = (
                cute.nvgpu.make_tiled_tma_atom_B(
                    tma_load_op,
                    c_latent_transpose,
                    vc_smem_layout,
                    self.mma_pv_tiler,
                    pv_tiled_mma,
                    cta_layout_vmnk.shape,
                )
            )

            q_copy_size = cute.size_in_bytes(self.q_dtype, q_smem_layout) * cute.size(
                qk_tiled_mma.thr_id.shape
            )
            kc_copy_size = cute.size_in_bytes(self.k_dtype, kc_smem_layout) * cute.size(
                qk_tiled_mma.thr_id.shape
            )
            vc_copy_size = cute.size_in_bytes(self.v_dtype, vc_smem_layout) * cute.size(
                pv_tiled_mma.thr_id.shape
            )
            assert kc_copy_size == vc_copy_size, (
                "kc_copy_size and vc_copy_size must be the same"
            )

            self.tma_copy_q_bytes = q_copy_size
            self.tma_copy_kc_bytes = kc_copy_size
        else:
            self.tma_copy_q_bytes = 0
            self.tma_copy_kc_bytes = 0

        tile_sched_params, grid = self._compute_grid(
            o,
            split_kv,
            self.cluster_shape_mnk,
            self.max_active_clusters,
            self.is_persistent,
        )

        @cute.struct
        class SplitKVKernelSharedStorage:
            # Pipeline barriers
            load_q_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.load_q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.load_kv_stage * 2
            ]
            mma_s_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.mma_s_stage * 2]
            p_mma_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.p_mma_stage * 2]
            p_cor_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.p_cor_stage * 2]
            mma_o_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.mma_o_stage * 2]
            load_pt_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.load_pt_stage * 2
            ]

            # Smem tensors
            softmax_smem_exchange: cute.struct.MemRange[
                self.acc_dtype, self.num_compute_warps * self.threads_per_warp
            ]
            epilogue_smem_exchange: cute.struct.MemRange[
                self.acc_dtype, self.num_compute_warps * self.threads_per_warp
            ]

            smem_page_table: cute.struct.MemRange[
                cutlass.Int32, self.load_pt_stage * self.mma_qk_tiler[1]
            ]
            smem_q: cute.struct.Align[
                cute.struct.MemRange[self.q_dtype, cute.cosize(q_smem_layout_staged)],
                1024,
            ]
            smem_kc: cute.struct.Align[
                cute.struct.MemRange[self.k_dtype, cute.cosize(kc_smem_layout_staged)],
                1024,
            ]
            smem_p: cute.struct.Align[
                cute.struct.MemRange[self.q_dtype, cute.cosize(p_smem_layout_staged)],
                1024,
            ]
            # Tmem dealloc cluster barrier
            tmem_dealloc_mbar_ptr: cutlass.Int64

            # Tmem holding buffer
            tmem_holding_buf: cutlass.Int32

        softmax_scale_log2 = softmax_scale * LOG2_E
        # Launch the kernel synchronously
        if cutlass.const_expr(self.is_cpasync):
            self.split_kv_kernel(
                qk_tiled_mma,
                pv_tiled_mma,
                None,
                q_latent,
                None,
                q_rope,
                None,
                c_latent,
                None,
                c_rope,
                None,
                c_latent_transpose,
                page_table,
                o,
                lse,
                acc_o,
                acc_lse,
                split_kv,
                cache_seqs,
                block_split_kvs,
                softmax_scale_log2,
                output_scale,
                q_smem_layout_staged,
                kc_smem_layout_staged,
                p_smem_layout_staged,
                vc_smem_layout_staged,
                cta_layout_vmnk,
                tile_sched_params,
                SplitKVKernelSharedStorage,
            ).launch(
                grid=grid,
                block=[self.threads_per_cta, 1, 1],
                cluster=self.cluster_shape_mnk,
                smem=SplitKVKernelSharedStorage.size_in_bytes(),
                stream=stream,
                min_blocks_per_mp=1,
            )
        else:
            self.split_kv_kernel(
                qk_tiled_mma,
                pv_tiled_mma,
                tma_atom_q_latent,
                tma_tensor_q_latent,
                tma_atom_q_rope,
                tma_tensor_q_rope,
                tma_atom_c_latent,
                tma_tensor_c_latent,
                tma_atom_c_rope,
                tma_tensor_c_rope,
                tma_atom_c_latent_transpose,
                tma_tensor_c_latent_transpose,
                page_table,
                o,
                lse,
                acc_o,
                acc_lse,
                split_kv,
                cache_seqs,
                block_split_kvs,
                softmax_scale_log2,
                output_scale,
                q_smem_layout_staged,
                kc_smem_layout_staged,
                p_smem_layout_staged,
                vc_smem_layout_staged,
                cta_layout_vmnk,
                tile_sched_params,
                SplitKVKernelSharedStorage,
            ).launch(
                grid=grid,
                block=[self.threads_per_cta, 1, 1],
                cluster=self.cluster_shape_mnk,
                smem=SplitKVKernelSharedStorage.size_in_bytes(),
                stream=stream,
                min_blocks_per_mp=1,
            )
        if cutlass.const_expr(acc_o is not None):
            self.reduction_kernel(
                o,
                lse,
                acc_o,
                acc_lse,
                split_kv,
                cache_seqs,
                block_split_kvs,
            ).launch(
                grid=(q_latent.shape[0], 1, q_latent.shape[2]),
                block=[self.threads_per_warp * self.num_compute_warps, 1, 1],
                smem=MAX_SPLITS * self.acc_dtype.width // 8,
                stream=stream,
                min_blocks_per_mp=1,
            )

    @cute.kernel
    def split_kv_kernel(
        self,
        tiled_mma_qk: cute.TiledMma,
        tiled_mma_pv: cute.TiledMma,
        tma_atom_q_latent: Optional[cute.CopyAtom],
        mQL: cute.Tensor,
        tma_atom_q_rope: Optional[cute.CopyAtom],
        mQR: cute.Tensor,
        tma_atom_c_latent: Optional[cute.CopyAtom],
        mCL: cute.Tensor,
        tma_atom_c_rope: Optional[cute.CopyAtom],
        mKR: cute.Tensor,
        tma_atom_c_latent_transpose: Optional[cute.CopyAtom],
        mCLT: cute.Tensor,
        mPT: cute.Tensor,
        mO: Optional[cute.Tensor],
        mLSE: Optional[cute.Tensor],
        mAccO: Optional[cute.Tensor],
        mAccLSE: Optional[cute.Tensor],
        split_kv: cutlass.Int32,
        cache_seqs: cute.Tensor,
        block_split_kvs: cute.Tensor,
        softmax_scale_log2: cutlass.Float32,
        output_scale: cutlass.Float32,
        q_smem_layout_staged: cute.ComposedLayout,
        kc_smem_layout_staged: cute.ComposedLayout,
        p_smem_layout_staged: cute.ComposedLayout,
        vc_smem_layout_staged: cute.ComposedLayout,
        cta_layout_vmnk: cute.Layout,
        tile_sched_params: MLAStaticTileSchedulerParams,
        SharedStorage: cutlass.Constexpr,
    ):
        """The device split_kv kernel implementation of the Multi-Head Latent Attention.

        This kernel coordinates multiple specialized warps to perform different phases of the MLA computation:
        1. Load warp: Loads Q/C latent/rope data from global memory to shared memory using TMA
        2. MMA warp: Performs matrix multiplications (Q*K^T and P*V)
        3. Compute warps: Compute softmax and do rescaling on accumulators, and store the intermediate/final results
        to global memory

        The kernel produces either intermediate or final results of the MLA computation based on the split_kv parameter.
        When split_kv is 1, the kernel generates the final results directly. Otherwise, it produces intermediate results
        that will later be combined by a reduction kernel.

        The kernel implements a complex pipeline with overlapping computation and memory operations,
        using tensor memory access (TMA) for efficient data loading, warp specialization for different
        computation phases.

        :param tiled_mma_qk: Tiled MMA for Q*K^T
        :type tiled_mma_qk: cute.TiledMma
        :param tiled_mma_pv: Tiled MMA for P*V
        :type tiled_mma_pv: cute.TiledMma
        :param tma_atom_q_latent: TMA copy atom for query latent tensor
        :type tma_atom_q_latent: cute.CopyAtom
        :param mQL: query latent tensor
        :type mQL: cute.Tensor
        :param tma_atom_q_rope: TMA copy atom for query rope tensor
        :type tma_atom_q_rope: cute.CopyAtom
        :param mKR: Compressed rope tensor
        :type mKR: cute.Tensor
        :param tma_atom_c_latent: TMA copy atom for c latent tensor
        :type tma_atom_c_latent: cute.CopyAtom
        :param mCL: Compressed latent tensor
        :type mCL: cute.Tensor
        :param tma_atom_c_rope: TMA copy atom for c rope tensor
        :type tma_atom_c_rope: cute.CopyAtom
        :param mCLT: Compressed latent transpose tensor
        :type mCLT: cute.Tensor
        :param mPT: Page table tensor
        :type mPT: cute.Tensor
        :param mO: Output tensor
        :type mO: cute.Tensor
        :param mLSE: Log-sum-exp tensor
        :type mLSE: cute.Tensor
        :param mAccO: Intermediate accumulator output tensor
        :type mAccO: cute.Tensor
        :param mAccLSE: Intermediate accumulator log-sum-exp tensor
        :type mAccLSE: cute.Tensor
        :param split_kv: The split_kv parameter
        :type split_kv: cutlass.Int32
        :param cache_seqs: The variable sequence length tensor
        :type cache_seqs: cute.Tensor
        :param block_split_kvs: The per-block split_kv values tensor
        :type block_split_kvs: cute.Tensor
        :param softmax_scale_log2: The log2 scale factor for softmax
        :type softmax_scale_log2: cutlass.Float32
        :param output_scale: The scale factor for the output
        :type output_scale: cutlass.Float32
        :param q_smem_layout_staged: Shared memory layout for query tensor
        :type q_smem_layout_staged: cute.ComposedLayout
        :param kc_smem_layout_staged: Shared memory layout for key tensor
        :type kc_smem_layout_staged: cute.ComposedLayout
        :param p_smem_layout_staged: Shared memory layout for probability matrix
        :type p_smem_layout_staged: cute.ComposedLayout
        :param vc_smem_layout_staged: Shared memory layout for value tensor
        :type vc_smem_layout_staged: cute.ComposedLayout
        :param cta_layout_vmnk: Layout for compute threads
        :type cta_layout_vmnk: cute.Layout
        :param tile_sched_params: Scheduling parameters for work distribution
        :type tile_sched_params: MLAStaticTileSchedulerParams
        :param SharedStorage: Shared storage for the kernel
        :type SharedStorage: cutlass.Constexpr
        """

        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma_qk.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0

        # Coords inside cluster
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )

        # Prefetch tma descriptor
        if cutlass.const_expr(not self.is_cpasync):
            if warp_idx == self.mma_warp_id:
                cpasync.prefetch_descriptor(tma_atom_q_latent)
                cpasync.prefetch_descriptor(tma_atom_q_rope)
                cpasync.prefetch_descriptor(tma_atom_c_latent)
                cpasync.prefetch_descriptor(tma_atom_c_rope)
                cpasync.prefetch_descriptor(tma_atom_c_latent_transpose)

        # Alloc
        smem = utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        tmem_dealloc_mbar_ptr = storage.tmem_dealloc_mbar_ptr
        tmem_holding_buf = storage.tmem_holding_buf

        # Tensor memory dealloc barrier init
        if warp_idx == self.mma_warp_id:
            num_tmem_dealloc_threads = self.threads_per_warp * self.num_compute_warps
            with cute.arch.elect_one():
                cute.arch.mbarrier_init(tmem_dealloc_mbar_ptr, num_tmem_dealloc_threads)
        cute.arch.mbarrier_init_fence()

        load_q_pipeline = self.make_and_init_load_qkv_pipeline(
            storage.load_q_mbar_ptr.data_ptr(),
            cta_layout_vmnk,
            self.load_q_stage,
            self.tma_copy_q_bytes,
            self.is_cpasync,
        )
        load_kv_pipeline = self.make_and_init_load_qkv_pipeline(
            storage.load_kv_mbar_ptr.data_ptr(),
            cta_layout_vmnk,
            self.load_kv_stage,
            self.tma_copy_kc_bytes,
            self.is_cpasync,
        )
        mma_s_pipeline = self.make_and_init_mma_s_pipeline(
            storage.mma_s_mbar_ptr.data_ptr(), cta_layout_vmnk
        )
        p_mma_pipeline = self.make_and_init_p_mma_pipeline(
            storage.p_mma_mbar_ptr.data_ptr(), cta_layout_vmnk
        )
        p_cor_pipeline = self.make_and_init_p_cor_pipeline(
            storage.p_cor_mbar_ptr.data_ptr()
        )
        mma_o_pipeline = self.make_and_init_mma_o_pipeline(
            storage.mma_o_mbar_ptr.data_ptr(), cta_layout_vmnk
        )
        if cutlass.const_expr(self.is_cpasync):
            load_pt_pipeline = self.make_and_init_load_pt_pipeline(
                storage.load_pt_mbar_ptr.data_ptr()
            )

        # Cluster arrive after barrier init
        if cutlass.const_expr(cute.size(self.cluster_shape_mnk) > 1):
            cute.arch.cluster_arrive_relaxed()

        # Generate smem tensor Q/KC/VC/exchange
        # (MMA, MMA_H, MMA_R, PIPE)
        sQ = storage.smem_q.get_tensor(
            q_smem_layout_staged.outer, swizzle=q_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_R, PIPE)
        sKC = storage.smem_kc.get_tensor(
            kc_smem_layout_staged.outer, swizzle=kc_smem_layout_staged.inner
        )
        # (MMA, MMA_D, MMA_K, PIPE)
        # reuse smem
        sVC_ptr = cute.recast_ptr(sKC.iterator, vc_smem_layout_staged.inner)
        sVC = cute.make_tensor(sVC_ptr, vc_smem_layout_staged.outer)
        # (MMA, MMA_H, MMA_K)
        sP = storage.smem_p.get_tensor(
            p_smem_layout_staged.outer, swizzle=p_smem_layout_staged.inner
        )
        # (compute_threads,)
        softmax_smem_exchange = storage.softmax_smem_exchange.get_tensor(
            cute.make_layout(self.num_compute_warps * self.threads_per_warp)
        )
        epilogue_smem_exchange = storage.epilogue_smem_exchange.get_tensor(
            cute.make_layout(self.num_compute_warps * self.threads_per_warp)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        if cutlass.const_expr(cute.size(self.cluster_shape_mnk) > 1):
            cute.arch.cluster_wait()
        else:
            pipeline.sync(barrier_id=4)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Load warps, including page table and data tensors
        # ///////////////////////////////////////////////////////////////////////////////
        if cutlass.const_expr(self.is_cpasync):
            sPT = storage.smem_page_table.get_tensor(
                cute.make_layout((self.mma_qk_tiler[1], self.load_pt_stage))
            )
            # Load page table when isasync is true
            if warp_idx == self.load_pt_warp_id:
                cute.arch.warpgroup_reg_dealloc(self.other_reg_num)
                load_pt_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.load_pt_stage
                )
                tile_sched = create_mla_static_tile_scheduler(
                    tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()
                while work_tile.is_valid_tile:
                    blk_coord = work_tile.tile_idx
                    k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                        split_kv,
                        cache_seqs,
                        block_split_kvs,
                        blk_coord,
                    )
                    if k_tile_count > 0:
                        load_pt_common_params = SimpleNamespace(
                            blk_coord=blk_coord,
                            load_pt_pipeline=load_pt_pipeline,
                            mPT=mPT,
                            sPT=sPT,
                            tidx=tidx,
                            page_size=mCL.shape[0],
                        )
                        load_pt_producer_state = self.load_page_table(
                            load_pt_common_params,
                            k_index,
                            k_tile_count,
                            load_pt_producer_state,
                        )
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                load_pt_pipeline.producer_tail(load_pt_producer_state)

            if (
                warp_idx == self.load_cp_async_warp_ids[0]
                or warp_idx == self.load_cp_async_warp_ids[1]
            ):
                cute.arch.warpgroup_reg_dealloc(self.other_reg_num)
                load_pt_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.load_pt_stage
                )
                load_pt_release_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.load_pt_stage
                )
                load_q_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.load_q_stage
                )
                load_kv_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.load_kv_stage
                )
                load_kv_commit_state = load_kv_producer_state.clone()
                tile_sched = create_mla_static_tile_scheduler(
                    tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()
                while work_tile.is_valid_tile:
                    blk_coord = work_tile.tile_idx
                    k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                        split_kv,
                        cache_seqs,
                        block_split_kvs,
                        blk_coord,
                    )
                    if k_tile_count > 0:
                        load_cpasync_common_params = SimpleNamespace(
                            blk_coord=blk_coord,
                            load_pt_pipeline=load_pt_pipeline,
                            load_q_pipeline=load_q_pipeline,
                            load_kv_pipeline=load_kv_pipeline,
                            sPT=sPT,
                            tidx=tidx,
                            page_size=mCL.shape[0],
                        )
                        load_cpasync_qk_params = SimpleNamespace(
                            tiled_mma_qk=tiled_mma_qk,
                            mQL=mQL,
                            mQR=mQR,
                            mCL=mCL,
                            mKR=mKR,
                            sQ=sQ,
                            sKC=sKC,
                        )
                        load_cpasync_v_params = SimpleNamespace(
                            tiled_mma_pv=tiled_mma_pv,
                            mCLT=mCLT,
                            sVC=sVC,
                        )
                        (
                            load_pt_consumer_state,
                            load_pt_release_state,
                            load_q_producer_state,
                            load_kv_producer_state,
                            load_kv_commit_state,
                        ) = self.load_cpasync(
                            load_cpasync_common_params,
                            load_cpasync_qk_params,
                            load_cpasync_v_params,
                            k_index,
                            k_tile_count,
                            load_pt_consumer_state,
                            load_pt_release_state,
                            load_q_producer_state,
                            load_kv_producer_state,
                            load_kv_commit_state,
                        )
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                load_q_pipeline.producer_tail(load_q_producer_state)
                load_kv_pipeline.producer_tail(load_kv_producer_state)
        else:
            if (
                warp_idx >= self.empty_warp_ids[0]
                and warp_idx <= self.empty_warp_ids[-1]
            ):
                cute.arch.warpgroup_reg_dealloc(self.other_reg_num)
            if warp_idx == self.load_tma_warp_id:
                cute.arch.warpgroup_reg_dealloc(self.other_reg_num)
                load_q_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.load_q_stage
                )
                load_kv_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.load_kv_stage
                )
                tile_sched = create_mla_static_tile_scheduler(
                    tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()
                while work_tile.is_valid_tile:
                    blk_coord = work_tile.tile_idx
                    k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                        split_kv,
                        cache_seqs,
                        block_split_kvs,
                        blk_coord,
                    )
                    if k_tile_count > 0:
                        # Construct fixed common/tma_qk/tma_pv params for load_tma
                        tma_common_params = SimpleNamespace(
                            blk_coord=blk_coord,
                            local_split_kv=local_split_kv,
                            load_q_pipeline=load_q_pipeline,
                            load_kv_pipeline=load_kv_pipeline,
                            mPT=mPT,
                        )
                        tma_qk_params = SimpleNamespace(
                            tiled_mma_qk=tiled_mma_qk,
                            tma_atom_q_latent=tma_atom_q_latent,
                            tma_atom_q_rope=tma_atom_q_rope,
                            tma_atom_c_latent=tma_atom_c_latent,
                            tma_atom_c_rope=tma_atom_c_rope,
                            mQL=mQL,
                            mQR=mQR,
                            mCL=mCL,
                            mKR=mKR,
                            sQ=sQ,
                            sKC=sKC,
                        )
                        tma_pv_params = SimpleNamespace(
                            tiled_mma_pv=tiled_mma_pv,
                            tma_atom_c_latent_transpose=tma_atom_c_latent_transpose,
                            mCL=mCL,
                            mKR=mKR,
                            mCLT=mCLT,
                            sVC=sVC,
                        )
                        # Load tma
                        load_q_producer_state, load_kv_producer_state = self.load_tma(
                            tma_common_params,
                            tma_qk_params,
                            tma_pv_params,
                            k_index,
                            k_tile_count,
                            load_q_producer_state,
                            load_kv_producer_state,
                        )
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

                load_q_pipeline.producer_tail(load_q_producer_state)
                load_kv_pipeline.producer_tail(load_kv_producer_state)

        # ///////////////////////////////////////////////////////////////////////////////
        #  MMA warp
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.mma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.other_reg_num)
            # Alloc tensor memory buffer
            cute.arch.alloc_tmem(
                cute.arch.SM100_TMEM_CAPACITY_COLUMNS,
                tmem_holding_buf,
                is_two_cta=self.use_2cta_instrs,
            )

            # sync with compute warp before tmem ptr is retrieved
            self.tmem_ptr_sync_bar.arrive()

            # Retrieving tensor memory ptr and make accumulator tensor
            tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )

            load_q_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.load_q_stage
            )
            load_kv_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.load_kv_stage
            )
            mma_s_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.mma_s_stage
            )
            p_mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.p_mma_stage
            )
            mma_o_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.mma_o_stage
            )
            tile_sched = create_mla_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            while work_tile.is_valid_tile:
                blk_coord = work_tile.tile_idx
                k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                    split_kv, cache_seqs, block_split_kvs, blk_coord
                )
                if k_tile_count > 0:
                    mma_common_params = SimpleNamespace(
                        blk_coord=blk_coord,
                        local_split_kv=local_split_kv,
                        load_q_pipeline=load_q_pipeline,
                        load_kv_pipeline=load_kv_pipeline,
                        tmem_ptr=tmem_ptr,
                        is_leader_cta=is_leader_cta,
                        L=mCL.shape[1],
                    )
                    mma_qk_params = SimpleNamespace(
                        mma_s_pipeline=mma_s_pipeline,
                        sQ=sQ,
                        sKC=sKC,
                    )
                    mma_pv_params = SimpleNamespace(
                        p_mma_pipeline=p_mma_pipeline,
                        mma_o_pipeline=mma_o_pipeline,
                        sP=sP,
                        sVC=sVC,
                    )
                    (
                        tiled_mma_qk,
                        tiled_mma_pv,
                        load_q_consumer_state,
                        load_kv_consumer_state,
                        mma_s_producer_state,
                        p_mma_consumer_state,
                        mma_o_producer_state,
                    ) = self.mma(
                        mma_common_params,
                        mma_qk_params,
                        mma_pv_params,
                        k_tile_count,
                        tiled_mma_qk,
                        tiled_mma_pv,
                        load_q_consumer_state,
                        load_kv_consumer_state,
                        mma_s_producer_state,
                        p_mma_consumer_state,
                        mma_o_producer_state,
                    )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            mma_s_pipeline.producer_tail(mma_s_producer_state)
            mma_o_pipeline.producer_tail(mma_o_producer_state)

            cute.arch.relinquish_tmem_alloc_permit(is_two_cta=self.use_2cta_instrs)
            # Dealloc the tensor memory buffer
            cute.arch.mbarrier_wait(tmem_dealloc_mbar_ptr, 0)

            cute.arch.dealloc_tmem(
                tmem_ptr,
                cute.arch.SM100_TMEM_CAPACITY_COLUMNS,
                is_two_cta=self.use_2cta_instrs,
            )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Compute warp
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx >= self.compute_warp_ids[0]
            and warp_idx <= self.compute_warp_ids[-1]
        ):
            cute.arch.warpgroup_reg_alloc(self.softmax_reg_num)
            mma_s_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.mma_s_stage
            )
            p_mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.p_mma_stage
            )
            p_cor_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.p_cor_stage
            )
            mma_o_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.mma_o_stage
            )
            # sync with mma warp before retrieving tmem ptr
            self.tmem_ptr_sync_bar.wait()

            tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )

            tile_sched = create_mla_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            while work_tile.is_valid_tile:
                blk_coord = work_tile.tile_idx
                k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                    split_kv, cache_seqs, block_split_kvs, blk_coord
                )
                if k_tile_count > 0:
                    compute_common_params = SimpleNamespace(
                        blk_coord=blk_coord,
                        split_kv=split_kv,
                        local_split_kv=local_split_kv,
                        smem_exchange=softmax_smem_exchange,
                        mAccO=mAccO,
                        mO=mO,
                        K=cache_seqs[blk_coord[2]],
                        L=mCL.shape[1],
                        tmem_ptr=tmem_ptr,
                        tidx=tidx,
                        p_cor_pipeline=p_cor_pipeline,
                    )
                    compute_softmax_params = SimpleNamespace(
                        tiled_mma_qk=tiled_mma_qk,
                        sP=sP,
                        mma_s_pipeline=mma_s_pipeline,
                        p_mma_pipeline=p_mma_pipeline,
                        softmax_scale_log2=softmax_scale_log2,
                    )
                    mma_s_consumer_state, p_mma_producer_state, p_cor_producer_state = (
                        self.compute(
                            compute_common_params,
                            compute_softmax_params,
                            k_index=k_index,
                            k_tile_count=k_tile_count,
                            mma_s_consumer_state=mma_s_consumer_state,
                            p_mma_producer_state=p_mma_producer_state,
                            p_cor_producer_state=p_cor_producer_state,
                        )
                    )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            p_cor_pipeline.producer_tail(p_cor_producer_state)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction warp
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx >= self.correction_warp_ids[0]
            and warp_idx <= self.correction_warp_ids[-1]
        ):
            cute.arch.warpgroup_reg_alloc(self.correction_reg_num)
            p_cor_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.p_cor_stage
            )
            mma_o_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.mma_o_stage
            )
            # sync with mma warp before retrieving tmem ptr
            self.tmem_ptr_sync_bar.wait()

            tmem_ptr = cute.arch.retrieve_tmem_ptr(
                self.acc_dtype,
                alignment=16,
                ptr_to_buffer_holding_addr=tmem_holding_buf,
            )

            tile_sched = create_mla_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            while work_tile.is_valid_tile:
                blk_coord = work_tile.tile_idx
                k_index, k_tile_count, local_split_kv = self.get_k_tile_count(
                    split_kv, cache_seqs, block_split_kvs, blk_coord
                )
                if k_tile_count > 0:
                    compute_common_params = SimpleNamespace(
                        blk_coord=blk_coord,
                        split_kv=split_kv,
                        local_split_kv=local_split_kv,
                        smem_exchange=epilogue_smem_exchange,
                        mAccO=mAccO,
                        mO=mO,
                        K=cache_seqs[blk_coord[2]],
                        L=mCL.shape[1],
                        H=mQL.shape[0],
                        tmem_ptr=tmem_ptr,
                        tidx=tidx,
                        tiled_mma_pv=tiled_mma_pv,
                        p_cor_pipeline=p_cor_pipeline,
                        mma_o_pipeline=mma_o_pipeline,
                    )
                    compute_epilogue_params = SimpleNamespace(
                        output_scale=output_scale,
                        softmax_scale_log2=softmax_scale_log2,
                        mAccLSE=mAccLSE,
                        mLSE=mLSE,
                    )
                    p_cor_consumer_state, mma_o_consumer_state = self.correction(
                        compute_common_params,
                        compute_epilogue_params,
                        k_tile_count=k_tile_count,
                        p_cor_consumer_state=p_cor_consumer_state,
                        mma_o_consumer_state=mma_o_consumer_state,
                    )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Arrive for the tensor memory deallocation barrier
            cute.arch.mbarrier_arrive(tmem_dealloc_mbar_ptr, cta_rank_in_cluster ^ 1)

        return

    @cute.kernel
    def reduction_kernel(
        self,
        mO: cute.Tensor,
        mLSE: cute.Tensor,
        mAccO: cute.Tensor,
        mAccLSE: cute.Tensor,
        split_kv: cutlass.Int32,
        cache_seqs: cute.Tensor,
        block_split_kvs: cute.Tensor,
    ):
        """The reduction kernel for Multi-Head Latent Attention (MLA) that combines intermediate results
        from multiple split_kv blocks into final outputs.

        :param mO: Output tensor for storing final results
        :type mO: cute.Tensor
        :param mLSE: Log-sum-exp tensor for storing final LSE values
        :type mLSE: cute.Tensor
        :param mAccO: Accumulated output tensor from split_kv blocks
        :type mAccO: cute.Tensor
        :param mAccLSE: Accumulated LSE tensor from split_kv blocks
        :type mAccLSE: cute.Tensor
        :param split_kv: Number of split_kv blocks
        :type split_kv: cutlass.Int32
        :param cache_seqs: Cache sequence lengths tensor
        :type cache_seqs: cute.Tensor
        :param block_split_kvs: Per-block split_kv values tensor (for variable split_kv)
        :type block_split_kvs: cute.Tensor
        """
        bidx, _, bidz = cute.arch.block_idx()
        tidx, _, _ = cute.arch.thread_idx()
        blk_coord = (bidx, 0, bidz)
        local_split_kv = (
            block_split_kvs[blk_coord[2]] if self.is_var_split_kv else split_kv
        )
        k_tile_total = cute.ceil_div(cache_seqs[blk_coord[2]], self.mma_qk_tiler[1])
        k_tile_per_cta = cute.ceil_div(k_tile_total, local_split_kv)
        local_split_kv = cute.ceil_div(k_tile_total, k_tile_per_cta)

        # Alloc shared memory
        smem = utils.SmemAllocator()
        storage = smem.allocate(MAX_SPLITS * self.acc_dtype.width // 8, 16)
        lse_scale_ptr = cute.recast_ptr(storage, dtype=self.acc_dtype)
        smem_lse_scale = cute.make_tensor(lse_scale_ptr, cute.make_layout(MAX_SPLITS))

        gLSE = mAccLSE[blk_coord[0], None, blk_coord[2]]
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        if warp_idx == 0:
            # calculate the global lse and exp ^ (local_lse - global_lse)
            lse_per_thread = cute.ceil_div(MAX_SPLITS, self.threads_per_warp)

            local_lse = cute.make_rmem_tensor(
                cute.make_layout(lse_per_thread), self.lse_dtype
            )
            lse_max = -self.lse_dtype.inf
            # find the max lse
            for i in cutlass.range_constexpr(lse_per_thread):
                split_kv_idx = tidx + i * self.threads_per_warp
                local_lse[i] = (
                    gLSE[split_kv_idx]
                    if cute.elem_less(split_kv_idx, local_split_kv)
                    else -self.lse_dtype.inf
                )
                # reduce the local lse
                lse_max = cute.arch.fmax(lse_max, local_lse[i])
            lse_max = cute.arch.warp_reduction_max(lse_max)
            lse_max = lse_max if lse_max != -self.lse_dtype.inf else 0.0
            # calculate sum_lse
            sum_lse = 0.0
            for i in cutlass.range_constexpr(lse_per_thread):
                sum_lse += cute.math.exp2(local_lse[i] - lse_max, fastmath=True)
            sum_lse = cute.arch.warp_reduction_sum(sum_lse)
            # calculate the global_lse
            global_lse = (
                lse_max + cute.math.log2(sum_lse, fastmath=True)
                if not sum_lse == self.lse_dtype(0.0) or sum_lse != sum_lse
                else self.lse_dtype.inf
            )
            if tidx == 0:
                mLSE[blk_coord[0], blk_coord[2]] = global_lse
            # store the scale to shared memory
            for i in cutlass.range_constexpr(lse_per_thread):
                split_kv_idx = tidx + i * self.threads_per_warp
                if cute.elem_less(split_kv_idx, local_split_kv):
                    smem_lse_scale[split_kv_idx] = cute.math.exp2(
                        local_lse[i] - global_lse, fastmath=True
                    )

        pipeline.sync(barrier_id=4)

        elements_per_thread = cute.ceil_div(
            self.latent_dim, self.threads_per_warp * self.num_compute_warps
        )
        gAccO = mAccO[blk_coord[0], None, None, blk_coord[2]]
        rAccO = cute.make_rmem_tensor(
            cute.make_layout(elements_per_thread), self.acc_dtype
        )
        rO = cute.make_rmem_tensor(cute.make_layout(elements_per_thread), self.o_dtype)
        rAccO.fill(0.0)
        for i in range(local_split_kv):
            for j in cutlass.range_constexpr(elements_per_thread):
                element_idx = tidx + j * self.threads_per_warp * self.num_compute_warps
                rAccO[j] += gAccO[i, element_idx] * smem_lse_scale[i]
        rO.store(rAccO.load().to(self.o_dtype))
        for j in cutlass.range_constexpr(elements_per_thread):
            element_idx = tidx + j * self.threads_per_warp * self.num_compute_warps
            mO[blk_coord[0], element_idx, blk_coord[2]] = rO[j]
        return

    @staticmethod
    def get_split_kv(
        B: int, K: int, mma_qk_tiler_mn: tuple, max_active_blocks: int
    ) -> int:
        """Get the proper split_kv value for the MLA kernel based on parameters.

        :param B: Batch size
        :type B: int
        :param K: Sequence length
        :type K: int
        :param mma_qk_tiler_mn: MLA tiling parameters
        :type mma_qk_tiler_mn: tuple
        :param max_active_blocks: Maximum number of active blocks
        :type max_active_blocks: int
        :return: Split_kv value
        :rtype: int
        """
        max_splits = ceil_div(K, mma_qk_tiler_mn[1])
        blocks_per_batch = max(1, max_active_blocks // B)
        split_heur = min(max_splits, blocks_per_batch)
        k_waves = ceil_div(max_splits, split_heur)
        split_wave_aware = ceil_div(max_splits, k_waves)
        return split_wave_aware

    @cute.jit
    def get_k_tile_count(
        self,
        split_kv: cutlass.Int32,
        cache_seqs: cute.Tensor,
        block_split_kvs: cute.Tensor,
        blk_coord: cute.Coord,
    ) -> tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]:
        """Get the current k_index, k_tile_count, and local split_kv value for the MLA kernel.

        :param split_kv: Split_kv value
        :type split_kv: cutlass.Int32
        :param cache_seqs: Cache sequence lengths tensor
        :type cache_seqs: cute.Tensor
        :param block_split_kvs: Per-block split_kv values tensor
        :type block_split_kvs: cute.Tensor
        :param blk_coord: Block coordinate
        :type blk_coord: cute.Coord
        :return: k_index, k_tile_count, split_kv
        :rtype: tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32]
        """
        K = cache_seqs[blk_coord[2]]
        if cutlass.const_expr(self.is_var_split_kv):
            split_kv = block_split_kvs[blk_coord[2]]

        k_tile_total = cute.ceil_div(K, self.mma_qk_tiler[1])
        k_tile_per_cta = cute.ceil_div(k_tile_total, split_kv)
        k_index = blk_coord[3] * k_tile_per_cta
        k_tile_count = max(0, min(k_tile_total, k_index + k_tile_per_cta) - k_index)
        return k_index, k_tile_count, split_kv

    @cute.jit
    def load_page_table(
        self,
        common_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_count: cutlass.Int32,
        load_pt_producer_state: pipeline.PipelineState,
    ) -> pipeline.PipelineState:
        """Load warp to load page table. Updates the load pt producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param k_tile_count: The k tile count
        :type k_tile_count: cutlass.Int32
        :param load_pt_producer_state: The load pt producer state
        :type load_pt_producer_state: pipeline.PipelineState

        :return: The load pt producer state
        :rtype: pipeline.PipelineState
        """
        mPT = common_params.mPT[None, common_params.blk_coord[2]]
        page_per_tile = self.mma_qk_tiler[1] >> cute.arch.log2_of_pow2_int(
            common_params.page_size
        )
        tidx = common_params.tidx % self.threads_per_warp

        load_pt_pipeline = common_params.load_pt_pipeline
        while k_tile_count > 0:
            load_pt_pipeline.producer_acquire(load_pt_producer_state)

            elem_per_thread = cute.ceil_div(page_per_tile, self.threads_per_warp)

            # atom_async_copy: async copy atom for page table load
            atom_async_copy = cute.make_copy_atom(
                cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.ALWAYS),
                cutlass.Int32,
                num_bits_per_copy=cutlass.Int32.width,
            )
            mPT_for_copy = cute.flat_divide(mPT, (1,))
            sPT_for_copy = cute.flat_divide(common_params.sPT, (1,))
            # elem_per_thread is a dynamic value depends on the page_size setting.
            for i in range(elem_per_thread):
                idx = i * self.threads_per_warp + tidx
                if cute.elem_less(
                    k_index * page_per_tile + idx, mPT.shape[0]
                ) and cute.elem_less(idx, page_per_tile):
                    cute.copy(
                        atom_async_copy,
                        mPT_for_copy[None, k_index * page_per_tile + idx],
                        sPT_for_copy[None, idx, load_pt_producer_state.index],
                    )
                else:
                    sPT_for_copy[None, idx, load_pt_producer_state.index].fill(0)
            mbar_ptr = load_pt_pipeline.producer_get_barrier(load_pt_producer_state)
            load_pt_pipeline.producer_commit(load_pt_producer_state)
            load_pt_producer_state.advance()
            k_index += 1
            k_tile_count -= 1

        return load_pt_producer_state

    @cute.jit
    def load_cpasync(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        v_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_count: cutlass.Int32,
        load_pt_consumer_state: pipeline.PipelineState,
        load_pt_release_state: pipeline.PipelineState,
        load_q_producer_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
        load_kv_commit_state: pipeline.PipelineState,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
    ]:
        """Load warp to load cpasync. Updates the load cpasync producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param load_pt_consumer_state: The load pt consumer state
        :type load_pt_consumer_state: pipeline.PipelineState
        :param load_pt_release_state: The load pt release state
        :type load_pt_release_state: pipeline.PipelineState
        :param load_q_producer_state: The load q producer state
        :type load_q_producer_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState
        :param load_kv_commit_state: The load kv commit state
        :type load_kv_commit_state: pipeline.PipelineState

        :return: The load pt consumer state, the load pt release state, the load q producer state, the load kv producer state, the load kv commit state
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]
        """

        tidx = (
            common_params.tidx - self.threads_per_warp * self.load_cp_async_warp_ids[0]
        )

        # slice view the the global tensors for cpasync, their coords are from counting tensor coord.
        mCL_for_slice = cute.make_tensor(
            qk_params.mCL.iterator,
            cute.make_layout(
                (
                    (qk_params.mCL.shape[0], qk_params.mCL.shape[2]),
                    qk_params.mCL.shape[1],
                ),
                stride=(
                    (qk_params.mCL.stride[0], qk_params.mCL.stride[2]),
                    qk_params.mCL.stride[1],
                ),
            ),
        )
        mKR_for_slice = cute.make_tensor(
            qk_params.mKR.iterator,
            cute.make_layout(
                (
                    (qk_params.mKR.shape[0], qk_params.mKR.shape[2]),
                    qk_params.mKR.shape[1],
                ),
                stride=(
                    (qk_params.mKR.stride[0], qk_params.mKR.stride[2]),
                    qk_params.mKR.stride[1],
                ),
            ),
        )
        mCLT_for_slice = cute.make_tensor(
            v_params.mCLT.iterator,
            cute.make_layout(
                (
                    v_params.mCLT.shape[0],
                    (v_params.mCLT.shape[1], v_params.mCLT.shape[2]),
                ),
                stride=(
                    v_params.mCLT.stride[0],
                    (v_params.mCLT.stride[1], v_params.mCLT.stride[2]),
                ),
            ),
        )

        # make identity tensor for partition
        mCL_for_partition = cute.make_identity_tensor(
            (qk_params.mCL.shape[0] * qk_params.mCL.shape[2], qk_params.mCL.shape[1])
        )
        mKR_for_partition = cute.make_identity_tensor(
            (qk_params.mKR.shape[0] * qk_params.mKR.shape[2], qk_params.mKR.shape[1])
        )
        mCLT_for_partition = cute.make_identity_tensor(
            (v_params.mCLT.shape[0], v_params.mCLT.shape[1] * v_params.mCLT.shape[2])
        )

        # Flatten divide and partition global tensors for QK TMA load
        # (bM, bK, rM, rK, rL)
        mma_qk_tiler_mk = cute.select(self.mma_qk_tiler, mode=[0, 2])
        gQL = cute.flat_divide(qk_params.mQL, mma_qk_tiler_mk)
        gQR = cute.flat_divide(qk_params.mQR, mma_qk_tiler_mk)

        mma_qk_tiler_nk = cute.select(self.mma_qk_tiler, mode=[1, 2])
        gCL = cute.flat_divide(mCL_for_partition, mma_qk_tiler_nk)
        gKR = cute.flat_divide(mKR_for_partition, mma_qk_tiler_nk)

        thr_mma_qk = qk_params.tiled_mma_qk.get_slice(
            common_params.blk_coord[0] % cute.size(qk_params.tiled_mma_qk.thr_id)
        )
        tSgQL = thr_mma_qk.partition_A(gQL)
        tSgQR = thr_mma_qk.partition_A(gQR)

        tSgCL = thr_mma_qk.partition_B(gCL)
        tSgKR = thr_mma_qk.partition_B(gKR)

        # create cpasync tiled copy qk
        cpasync_bits = 128
        # thread for copy
        thread = self.threads_per_warp * self.num_load_warps
        # Value for copy
        value = cpasync_bits // self.q_dtype.width
        cpasync_q_tiled_copy = cute.make_cotiled_copy(
            cute.make_copy_atom(
                cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.GLOBAL),
                self.q_dtype,
                num_bits_per_copy=cpasync_bits,
            ),
            cute.make_ordered_layout((thread, value), (1, 0)),
            qk_params.sQ[None, None, None, 0].layout,
        )
        cpasync_kc_tiled_copy = cute.make_cotiled_copy(
            cute.make_copy_atom(
                cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.GLOBAL),
                self.q_dtype,
                num_bits_per_copy=cpasync_bits,
            ),
            cute.make_ordered_layout((thread, value), (1, 0)),
            qk_params.sKC[None, None, None, 0].layout,
        )
        cpasync_q_thr_copy = cpasync_q_tiled_copy.get_slice(tidx)
        cpasync_kc_thr_copy = cpasync_kc_tiled_copy.get_slice(tidx)
        # copy async partition
        tQgQL = cpasync_q_thr_copy.partition_S(tSgQL)
        tQgQR = cpasync_q_thr_copy.partition_S(tSgQR)
        tQsQ = cpasync_q_thr_copy.partition_D(qk_params.sQ)

        tKCgCL = cpasync_kc_thr_copy.partition_S(tSgCL)
        tKCgKR = cpasync_kc_thr_copy.partition_S(tSgKR)
        tKCsKC = cpasync_kc_thr_copy.partition_D(qk_params.sKC)

        gCLT = cute.flat_divide(
            mCLT_for_partition, cute.select(self.mma_pv_tiler, mode=[1, 2])
        )
        thr_mma_pv = v_params.tiled_mma_pv.get_slice(
            common_params.blk_coord[0] % cute.size(v_params.tiled_mma_pv.thr_id)
        )
        tOgCLT = thr_mma_pv.partition_B(gCLT)

        cpasync_v_tiled_copy = cute.make_cotiled_copy(
            cute.make_copy_atom(
                cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.GLOBAL),
                self.q_dtype,
                num_bits_per_copy=cpasync_bits,
            ),
            cute.make_ordered_layout((thread, value), (1, 0)),
            v_params.sVC[None, None, None, 0].layout,
        )
        cpasync_v_thr_copy = cpasync_v_tiled_copy.get_slice(tidx)
        tVCgCLT = cpasync_v_thr_copy.partition_S(tOgCLT)
        tVCsVC = cpasync_v_thr_copy.partition_D(v_params.sVC)

        # Use to record the in-flight cpasync stage count, wait and producer commit until `load_kv_stage - 1` cpasync arrive
        copy_in_flight_count = cutlass.Int32(0)

        qk_params.tiled_copy_q = cpasync_q_tiled_copy
        qk_params.tiled_copy_kc = cpasync_kc_tiled_copy
        qk_params.mCL_for_slice = mCL_for_slice
        qk_params.mKR_for_slice = mKR_for_slice
        qk_params.tQgQL = tQgQL
        qk_params.tQgQR = tQgQR
        qk_params.tQsQ = tQsQ
        qk_params.tKCgCL = tKCgCL
        qk_params.tKCgKR = tKCgKR
        qk_params.tKCsKC = tKCsKC

        v_params.tiled_copy_vc = cpasync_v_tiled_copy
        v_params.tVCgCLT = tVCgCLT
        v_params.tVCsVC = tVCsVC
        v_params.mCLT_for_slice = mCLT_for_slice

        # first load qk latent/rope
        (
            load_pt_consumer_state,
            load_q_producer_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        ) = self.load_cpasync_qk_one_k_tile(
            common_params,
            qk_params,
            k_index,
            load_pt_consumer_state,
            load_q_producer_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
            load_q=True,
        )

        k_index += 1
        k_tile_count -= 1

        # mainloop, load qk and v
        while k_tile_count > 0:
            (
                load_pt_consumer_state,
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
            ) = self.load_cpasync_qk_one_k_tile(
                common_params,
                qk_params,
                k_index,
                load_pt_consumer_state,
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
                load_q=False,
            )
            (
                load_pt_release_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
            ) = self.load_cpasync_v_one_k_tile(
                common_params,
                v_params,
                k_index - 1,
                load_pt_release_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
            )
            k_index += 1
            k_tile_count -= 1

        # load last tile of v
        (
            load_pt_release_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        ) = self.load_cpasync_v_one_k_tile(
            common_params,
            v_params,
            k_index - 1,
            load_pt_release_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        )

        padding_in_flight = 0
        while copy_in_flight_count + padding_in_flight < self.load_kv_stage - 1:
            padding_in_flight += 1
            cute.arch.cp_async_commit_group()
        # wait for previous cpasync arrive
        load_kv_pipeline = common_params.load_kv_pipeline
        while copy_in_flight_count > 0:
            cute.arch.cp_async_commit_group()
            cute.arch.cp_async_wait_group(self.load_kv_stage - 1)
            load_kv_pipeline.producer_commit(load_kv_commit_state)
            load_kv_commit_state.advance()
            copy_in_flight_count -= 1

        # wait all cpasync arrive
        cute.arch.cp_async_wait_group(0)
        return (
            load_pt_consumer_state,
            load_pt_release_state,
            load_q_producer_state,
            load_kv_producer_state,
            load_kv_commit_state,
        )

    @cute.jit
    def load_cpasync_one_smem_stage(
        self,
        common_params: SimpleNamespace,
        load_q_producer_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
        load_kv_commit_state: pipeline.PipelineState,
        copy_func: Callable,
        copy_in_flight_count: cutlass.Int32,
        load_q: bool,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        cutlass.Int32,
    ]:
        """Load one smem stage of cpasync. Reused for qkv load stages. Updates the load cpasync producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param load_pt_consumer_state: The load pt consumer state
        :type load_pt_consumer_state: pipeline.PipelineState
        :param load_q_producer_state: The load q producer state
        :type load_q_producer_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState
        :param load_kv_commit_state: The load kv commit state
        :type load_kv_commit_state: pipeline.PipelineState
        :param copy_func: The copy function
        :type copy_func: Callable
        :param copy_in_flight_count: The copy in-flight count
        :type copy_in_flight_count: cutlass.Int32
        :param load_q: Whether to load q
        :type load_q: bool

        :return: The load q producer state, the load kv producer state, the load kv commit state, the copy in-flight count
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, cutlass.Int32]
        """
        if cutlass.const_expr(load_q):
            common_params.load_q_pipeline.producer_acquire(load_q_producer_state)
        common_params.load_kv_pipeline.producer_acquire(load_kv_producer_state)
        producer_index = load_kv_producer_state.index
        copy_func(producer_index)
        cute.arch.cp_async_commit_group()

        if cutlass.const_expr(load_q):
            # directly commit the q producer state here, mma will wait for kv.
            common_params.load_q_pipeline.producer_commit(load_q_producer_state)
            load_q_producer_state.advance()
        load_kv_producer_state.advance()
        copy_in_flight_count += 1

        # wait cpasync arrive until the last stage
        load_kv_pipeline = common_params.load_kv_pipeline
        if copy_in_flight_count == self.load_kv_stage:
            cute.arch.cp_async_wait_group(self.load_kv_stage - 1)
            load_kv_pipeline.producer_commit(load_kv_commit_state)
            load_kv_commit_state.advance()
            copy_in_flight_count -= 1

        return (
            load_q_producer_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        )

    @cute.jit
    def load_cpasync_page_table_lookup_copy(
        self,
        tiled_copy: cute.TiledCopy,
        gKV: cute.Tensor,
        sKV: cute.Tensor,
        sPT: cute.Tensor,
        gKV_for_slice: cute.Tensor,
        k_index: cutlass.Int32,
        latent_idx: cutlass.Int32,
        qkv_stage_idx: cutlass.Int32,
        page_table_stage: cutlass.Int32,
        page_size: cutlass.Int32,
        transpose: bool = False,
    ):
        """Make page table lookup for KV cache latent/rope, then do atom copy of cpasync.

        :param tiled_copy: The tiled copy
        :type tiled_copy: cute.TiledCopy
        :param gKV: The global KV tensor
        :type gKV: cute.Tensor
        :param sKV: The sliced KV tensor
        :type sKV: cute.Tensor
        :param sPT: The sliced page table tensor
        :type sPT: cute.Tensor
        :param gKV_for_slice: The global KV for slice tensor
        :type gKV_for_slice: cute.Tensor
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param latent_idx: The latent index
        :type latent_idx: cutlass.Int32
        :param qkv_stage_idx: The qkv stage index
        :type qkv_stage_idx: cutlass.Int32
        :param page_table_stage: The page table stage
        :type page_table_stage: cutlass.Int32
        :param transpose: Whether to transpose the gKV_for_slice
        :type transpose: bool
        """
        rest_modes_start = 1
        rest_modes_end = 4
        if cutlass.const_expr(transpose):
            gKV_grouped = cute.group_modes(
                gKV[None, None, None, None, latent_idx, k_index],
                rest_modes_start,
                rest_modes_end,
            )
        else:
            gKV_grouped = cute.group_modes(
                gKV[None, None, None, None, k_index, latent_idx],
                rest_modes_start,
                rest_modes_end,
            )
        sKV_grouped = cute.group_modes(
            sKV[None, None, None, None, qkv_stage_idx], rest_modes_start, rest_modes_end
        )
        page_size_log2 = cute.arch.log2_of_pow2_int(page_size)
        page_per_tile = self.mma_qk_tiler[1] >> page_size_log2
        gKV_for_copy_offsets = cute.make_rmem_tensor(
            cute.size(gKV_grouped.shape[1]), cute.cosize(gKV_for_slice.layout).dtype
        )
        # unroll the rest of the loop to apply page table lookup.
        for i in cutlass.range_constexpr(cute.size(gKV_grouped.shape[1])):
            # get the coordinate of the gKV_for_slice
            coord = gKV_grouped[None, i].iterator
            if cutlass.const_expr(transpose):
                # fast path of mod & div here to avoid the division because of the page size is power of 2.
                page_coord = ((coord[1] & (page_size - 1)), coord[1] >> page_size_log2)
                new_coord = (coord[0], page_coord)
                new_coord_pt = new_coord[1][1] & (page_per_tile - 1)
                gKV_for_copy_offset = cute.crd2idx(
                    (
                        new_coord[0],
                        (new_coord[1][0], sPT[new_coord_pt, page_table_stage]),
                    ),
                    gKV_for_slice.layout,
                )
            else:
                # fast path of mod & div here to avoid the division because of the page size is power of 2.
                page_coord = (coord[0] & (page_size - 1), coord[0] >> page_size_log2)
                new_coord = (page_coord, coord[1])
                new_coord_pt = new_coord[0][1] & (page_per_tile - 1)
                gKV_for_copy_offset = cute.crd2idx(
                    (
                        (new_coord[0][0], sPT[new_coord_pt, page_table_stage]),
                        new_coord[1],
                    ),
                    gKV_for_slice.layout,
                )
            gKV_for_copy_offsets[i] = gKV_for_copy_offset
        cpasync_bits = 128
        for i in cutlass.range_constexpr(cute.size(gKV_grouped.shape[1])):
            # calculate the actual offset and apply.
            sKV_for_copy = sKV_grouped[None, i]
            gKV_for_copy_offset = cute.assume(
                gKV_for_copy_offsets[i], cpasync_bits // self.q_dtype.width
            )
            gKV_for_copy_iter = gKV_for_slice.iterator + gKV_for_copy_offset
            gKV_for_copy = cute.make_tensor(gKV_for_copy_iter, sKV_for_copy.layout)
            cute.copy(tiled_copy, gKV_for_copy, sKV_for_copy)
        return

    @cute.jit
    def load_cpasync_qk_one_k_tile(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        k_index: cutlass.Int32,
        load_pt_consumer_state: pipeline.PipelineState,
        load_q_producer_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
        load_kv_commit_state: pipeline.PipelineState,
        copy_in_flight_count: cutlass.Int32,
        load_q: bool,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        cutlass.Int32,
    ]:
        """Load one k tile of Q/K. Updates the load cpasync producer state.

        :param qk_params: The qk parameters
        :type qk_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param load_pt_consumer_state: The load pt consumer state
        :type load_pt_consumer_state: pipeline.PipelineState
        :param load_q_producer_state: The load q producer state
        :type load_q_producer_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState
        :param load_kv_commit_state: The load kv commit state
        :type load_kv_commit_state: pipeline.PipelineState
        :param copy_in_flight_count: The copy stage count
        :type copy_in_flight_count: int
        :param load_q: Whether to load q
        :type load_q: bool

        :return: The load pt consumer state, the load q producer state, the load kv producer state, the load kv commit state, the copy stage count
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, int]
        """
        common_params.load_pt_pipeline.consumer_wait(load_pt_consumer_state)
        page_table_stage = load_pt_consumer_state.index
        load_pt_consumer_state.advance()

        def copy_qk_latent(latent_idx, qkv_stage_idx):
            if load_q:
                cute.copy(
                    qk_params.tiled_copy_q,
                    qk_params.tQgQL[
                        None,
                        None,
                        None,
                        None,
                        0,
                        latent_idx,
                        common_params.blk_coord[2],
                    ],
                    qk_params.tQsQ[None, None, None, None, latent_idx],
                )
            # make sure the page table lookups first.
            self.load_cpasync_page_table_lookup_copy(
                qk_params.tiled_copy_kc,
                qk_params.tKCgCL,
                qk_params.tKCsKC,
                common_params.sPT,
                qk_params.mCL_for_slice,
                k_index,
                latent_idx,
                qkv_stage_idx,
                page_table_stage,
                common_params.page_size,
            )

        def copy_qk_rope(latent_idx, qkv_stage_idx):
            if load_q:
                cute.copy(
                    qk_params.tiled_copy_q,
                    qk_params.tQgQR[
                        None,
                        None,
                        None,
                        None,
                        0,
                        latent_idx,
                        common_params.blk_coord[2],
                    ],
                    qk_params.tQsQ[
                        None, None, None, None, self.iterations_qk_latent + latent_idx
                    ],
                )
            # make sure the page table lookups first.
            self.load_cpasync_page_table_lookup_copy(
                qk_params.tiled_copy_kc,
                qk_params.tKCgKR,
                qk_params.tKCsKC,
                common_params.sPT,
                qk_params.mKR_for_slice,
                k_index,
                latent_idx,
                qkv_stage_idx,
                page_table_stage,
                common_params.page_size,
            )

        # use dynamic loop here to avoid instruction cache miss.
        for i in range(self.iterations_qk_latent):
            (
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
            ) = self.load_cpasync_one_smem_stage(
                common_params,
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                partial(copy_qk_latent, i),
                copy_in_flight_count,
                load_q=load_q,
            )
        for i in range(self.iterations_qk_rope):
            (
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                copy_in_flight_count,
            ) = self.load_cpasync_one_smem_stage(
                common_params,
                load_q_producer_state,
                load_kv_producer_state,
                load_kv_commit_state,
                partial(copy_qk_rope, i),
                copy_in_flight_count,
                load_q=load_q,
            )

        return (
            load_pt_consumer_state,
            load_q_producer_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        )

    @cute.jit
    def load_cpasync_v_one_k_tile(
        self,
        common_params: SimpleNamespace,
        v_params: SimpleNamespace,
        k_index: cutlass.Int32,
        load_pt_release_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
        load_kv_commit_state: pipeline.PipelineState,
        copy_in_flight_count: cutlass.Int32,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        cutlass.Int32,
    ]:
        """Load one k tile of V. Updates the load cpasync producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param v_params: The v parameters
        :type v_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param load_pt_release_state: The load pt release state
        :type load_pt_release_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState
        :param load_kv_commit_state: The load kv commit state
        :type load_kv_commit_state: pipeline.PipelineState
        :param copy_in_flight_count: The copy in-flight count
        :type copy_in_flight_count: cutlass.Int32

        :return: The load pt release state, the load kv producer state, the load kv commit state, the copy in-flight count
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, cutlass.Int32]
        """
        page_table_stage = load_pt_release_state.index

        def copy_v_latent(iter_k_idx, latent_idx, qkv_stage_idx):
            # make sure the page table lookups first.
            self.load_cpasync_page_table_lookup_copy(
                v_params.tiled_copy_vc,
                v_params.tVCgCLT,
                v_params.tVCsVC,
                common_params.sPT,
                v_params.mCLT_for_slice,
                k_index * self.iterations_pv_k + iter_k_idx,
                latent_idx,
                qkv_stage_idx,
                page_table_stage,
                common_params.page_size,
                transpose=True,
            )

        # use dynamic loop here to avoid instruction cache miss.
        for i in range(self.iterations_pv_k):
            for j in range(self.iterations_pv_n):
                (
                    _,
                    load_kv_producer_state,
                    load_kv_commit_state,
                    copy_in_flight_count,
                ) = self.load_cpasync_one_smem_stage(
                    common_params,
                    None,
                    load_kv_producer_state,
                    load_kv_commit_state,
                    partial(copy_v_latent, i, j),
                    copy_in_flight_count,
                    load_q=False,
                )
        common_params.load_pt_pipeline.consumer_release(load_pt_release_state)
        load_pt_release_state.advance()
        return (
            load_pt_release_state,
            load_kv_producer_state,
            load_kv_commit_state,
            copy_in_flight_count,
        )

    @cute.jit
    def load_tma(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        v_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_count: cutlass.Int32,
        load_q_producer_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
    ) -> tuple[pipeline.PipelineState, pipeline.PipelineState]:
        """Load wrap to load Q/C latent/rope tensors. Updates the load qkv producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param qk_params: The qk parameters
        :type qk_params: SimpleNamespace
        :param v_params: The v parameters
        :type v_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param k_tile_count: The k tile count
        :type k_tile_count: cutlass.Int32
        :param load_q_producer_state: The load q producer state
        :type load_q_producer_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState

        :return: The load q producer state and load kv producer state
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState]
        """
        # page table
        mPT = None
        if cutlass.const_expr(self.use_page_table):
            mPT = common_params.mPT[None, common_params.blk_coord[2]]

        # Flatten divide and partition global tensors for QK TMA load
        # (bM, bK, rM, rK, rL)
        mma_qk_tiler_mk = cute.select(self.mma_qk_tiler, mode=[0, 2])
        gQL = cute.flat_divide(qk_params.mQL, mma_qk_tiler_mk)
        gQR = cute.flat_divide(qk_params.mQR, mma_qk_tiler_mk)

        mma_qk_tiler_nk = cute.select(self.mma_qk_tiler, mode=[1, 2])
        gCL = cute.flat_divide(qk_params.mCL, mma_qk_tiler_nk)
        gKR = cute.flat_divide(qk_params.mKR, mma_qk_tiler_nk)

        thr_mma_qk = qk_params.tiled_mma_qk.get_slice(
            common_params.blk_coord[0] % cute.size(qk_params.tiled_mma_qk.thr_id)
        )
        tSgQL = thr_mma_qk.partition_A(gQL)
        tSgQR = thr_mma_qk.partition_A(gQR)

        tSgCL = thr_mma_qk.partition_B(gCL)
        tSgKR = thr_mma_qk.partition_B(gKR)

        # tma partition for q, k latent/rope

        # smem: ((atom_v, rest_v), STAGE)
        # gmem: ((atom_v, rest_v), RestM, RestK, RestL)
        tQsQ, tQLgQL_mkl = cpasync.tma_partition(
            qk_params.tma_atom_q_latent,
            0,
            cute.make_layout(1),
            cute.group_modes(qk_params.sQ, 0, 3),
            cute.group_modes(tSgQL, 0, 3),
        )

        _, tQRgQR_mkl = cpasync.tma_partition(
            qk_params.tma_atom_q_rope,
            0,
            cute.make_layout(1),
            cute.group_modes(qk_params.sQ, 0, 3),
            cute.group_modes(tSgQR, 0, 3),
        )

        tKCsKC, tCLgCL = cpasync.tma_partition(
            qk_params.tma_atom_c_latent,
            0,
            cute.make_layout(1),
            cute.group_modes(qk_params.sKC, 0, 3),
            cute.group_modes(tSgCL, 0, 3),
        )

        _, tKRgKR = cpasync.tma_partition(
            qk_params.tma_atom_c_rope,
            0,
            cute.make_layout(1),
            cute.group_modes(qk_params.sKC, 0, 3),
            cute.group_modes(tSgKR, 0, 3),
        )

        tQLgQL = tQLgQL_mkl[None, None, None, common_params.blk_coord[2]]
        tQRgQR = tQRgQR_mkl[None, None, None, common_params.blk_coord[2]]

        # Flatten divide and partition global tensors for V TMA load
        mma_pv_tiler_nk = cute.select(self.mma_pv_tiler, mode=[1, 2])
        gCLT = cute.flat_divide(v_params.mCLT, mma_pv_tiler_nk)

        thr_mma_pv = v_params.tiled_mma_pv.get_slice(
            common_params.blk_coord[0] % cute.size(v_params.tiled_mma_pv.thr_id)
        )
        tOgCLT = thr_mma_pv.partition_B(gCLT)

        # tma partition for vc
        # smem: ((atom_v, rest_v), STAGE)
        # gmem: ((atom_v, rest_v), RestM, RestK, RestL)
        tVCsVC, tCLTgCLT = cpasync.tma_partition(
            v_params.tma_atom_c_latent_transpose,
            0,
            cute.make_layout(1),
            cute.group_modes(v_params.sVC, 0, 3),
            cute.group_modes(tOgCLT, 0, 3),
        )

        # set extra params
        common_params.mPT = mPT
        qk_params.tQLgQL = tQLgQL
        qk_params.tQRgQR = tQRgQR
        qk_params.tCLgCL = tCLgCL
        qk_params.tKRgKR = tKRgKR
        qk_params.tQsQ = tQsQ
        qk_params.tKCsKC = tKCsKC
        v_params.tCLTgCLT = tCLTgCLT
        v_params.tVCsVC = tVCsVC

        load_q_producer_state, load_kv_producer_state = self.load_tma_qk_one_k_tile(
            common_params,
            qk_params,
            k_index,
            k_tile_count,
            load_q_producer_state,
            load_kv_producer_state,
            load_q=True,
        )
        k_index += 1
        k_tile_count -= 1
        while k_tile_count > 0:
            load_q_producer_state, load_kv_producer_state = self.load_tma_qk_one_k_tile(
                common_params,
                qk_params,
                k_index,
                k_tile_count,
                load_q_producer_state,
                load_kv_producer_state,
                load_q=False,
            )
            load_kv_producer_state = self.load_tma_v_one_k_tile(
                common_params,
                v_params,
                k_index - 1,
                load_kv_producer_state,
            )
            k_index += 1
            k_tile_count -= 1

        # load last v tile
        load_kv_producer_state = self.load_tma_v_one_k_tile(
            common_params,
            v_params,
            k_index - 1,
            load_kv_producer_state,
        )
        return load_q_producer_state, load_kv_producer_state

    @cute.jit
    def load_tma_qk_one_k_tile(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_count: cutlass.Int32,
        load_q_producer_state: pipeline.PipelineState,
        load_kv_producer_state: pipeline.PipelineState,
        load_q: bool,
    ) -> tuple[pipeline.PipelineState, pipeline.PipelineState]:
        """Load one k-tile of Q/C latent/rope tensors. Updates the load qkv producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param qk_params: The qk parameters
        :type qk_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param k_tile_count: The k tile count
        :type k_tile_count: cutlass.Int32
        :param load_q_producer_state: The load q producer state
        :type load_q_producer_state: pipeline.PipelineState
        :param load_kv_producer_state: The load kv producer state
        :type load_kv_producer_state: pipeline.PipelineState
        :param load_q: Whether to load q
        :type load_q: bool

        :return: The load q producer state and load kv producer state
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState]
        """
        k_idx = cute.make_rmem_tensor(cute.make_layout(2), cutlass.Int32)
        # prefetch next K load to keep busy while we transpose-load from cache
        kPrefetchDistance = 1
        if cutlass.const_expr(self.use_page_table):
            k_idx[0] = common_params.mPT[k_index]
            k_idx[1] = common_params.mPT[k_index + kPrefetchDistance]
        else:
            k_idx[0] = common_params.blk_coord[2]
            k_idx[1] = common_params.blk_coord[2]
        for i in cutlass.range_constexpr(self.iterations_qk_latent):
            # load q once at first iteration
            if cutlass.const_expr(load_q):
                # get the mbar ptr from pipeline.
                tma_bar_ptr = common_params.load_q_pipeline.producer_get_barrier(
                    load_q_producer_state
                )
                # expect the extra bytes for q.
                common_params.load_q_pipeline.producer_acquire(load_q_producer_state)
                # load q latent
                cute.copy(
                    qk_params.tma_atom_q_latent,
                    qk_params.tQLgQL[None, 0, load_q_producer_state.index],
                    qk_params.tQsQ[None, load_q_producer_state.index],
                    tma_bar_ptr=tma_bar_ptr,
                )
                load_q_producer_state.advance()
            # get the mbar ptr from pipeline.
            tma_bar_ptr = common_params.load_kv_pipeline.producer_get_barrier(
                load_kv_producer_state
            )
            # expect the extra bytes for q.
            common_params.load_kv_pipeline.producer_acquire(load_kv_producer_state)
            # load k latent
            if cutlass.const_expr(self.use_page_table):
                cute.copy(
                    qk_params.tma_atom_c_latent,
                    qk_params.tCLgCL[None, 0, i, k_idx[0]],
                    qk_params.tKCsKC[None, load_kv_producer_state.index],
                    tma_bar_ptr=tma_bar_ptr,
                )
            else:
                cute.copy(
                    qk_params.tma_atom_c_latent,
                    qk_params.tCLgCL[None, k_index, i, k_idx[0]],
                    qk_params.tKCsKC[None, load_kv_producer_state.index],
                    tma_bar_ptr=tma_bar_ptr,
                )
            load_kv_producer_state.advance()

        for i in cutlass.range_constexpr(self.iterations_qk_rope):
            # load q rope once at first iteration
            if cutlass.const_expr(load_q):
                # get the mbar ptr from pipeline.
                tma_bar_ptr = common_params.load_q_pipeline.producer_get_barrier(
                    load_q_producer_state
                )
                # expect the extra bytes for q.
                common_params.load_q_pipeline.producer_acquire(load_q_producer_state)
                # load q rope
                cute.copy(
                    qk_params.tma_atom_q_rope,
                    qk_params.tQRgQR[None, 0, i],
                    qk_params.tQsQ[None, i + self.iterations_qk_latent],
                    tma_bar_ptr=tma_bar_ptr,
                )
                load_q_producer_state.advance()
            # get the mbar ptr from pipeline.
            tma_bar_ptr = common_params.load_kv_pipeline.producer_get_barrier(
                load_kv_producer_state
            )
            # expect the extra bytes for q.
            common_params.load_kv_pipeline.producer_acquire(load_kv_producer_state)
            # load k rope
            if cutlass.const_expr(self.use_page_table):
                cute.copy(
                    qk_params.tma_atom_c_rope,
                    qk_params.tKRgKR[None, 0, i, k_idx[0]],
                    qk_params.tKCsKC[None, load_kv_producer_state.index],
                    tma_bar_ptr=tma_bar_ptr,
                )
            else:
                cute.copy(
                    qk_params.tma_atom_c_rope,
                    qk_params.tKRgKR[None, k_index, i, k_idx[0]],
                    qk_params.tKCsKC[None, load_kv_producer_state.index],
                    tma_bar_ptr=tma_bar_ptr,
                )
            load_kv_producer_state.advance()

        for i in cutlass.range_constexpr(self.iterations_qk_latent):
            if cutlass.const_expr(self.use_page_table):
                if k_tile_count > kPrefetchDistance:
                    cute.prefetch(
                        qk_params.tma_atom_c_latent,
                        qk_params.tCLgCL[
                            None,
                            k_index,
                            i,
                            k_idx[1],
                        ],
                    )
            else:
                cute.prefetch(
                    qk_params.tma_atom_c_latent,
                    qk_params.tCLgCL[None, k_index + kPrefetchDistance, i, k_idx[1]],
                )

        for i in cutlass.range_constexpr(self.iterations_qk_rope):
            if cutlass.const_expr(self.use_page_table):
                if k_tile_count > kPrefetchDistance:
                    cute.prefetch(
                        qk_params.tma_atom_c_rope,
                        qk_params.tKRgKR[
                            None,
                            k_index,
                            i,
                            k_idx[1],
                        ],
                    )
            else:
                cute.prefetch(
                    qk_params.tma_atom_c_rope,
                    qk_params.tKRgKR[None, k_index + kPrefetchDistance, i, k_idx[1]],
                )
        return load_q_producer_state, load_kv_producer_state

    @cute.jit
    def load_tma_v_one_k_tile(
        self,
        common_params: SimpleNamespace,
        v_params: SimpleNamespace,
        k_index: cutlass.Int32,
        load_kv_producer_state: pipeline.PipelineState,
    ) -> pipeline.PipelineState:
        """Load one k-tile of compressed latent transpose tensor(v). Updates the load qkv producer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param v_params: The load tma v parameters
        :type v_params: SimpleNamespace
        :param k_index: The k index
        :type k_index: cutlass.Int32
        :param load_kv_producer_state: The load qkv producer state
        :type load_kv_producer_state: pipeline.PipelineState

        :return: The load qkv producer state
        :rtype: pipeline.PipelineState
        """
        k_idx = cute.make_rmem_tensor(cute.make_layout(1), cutlass.Int32)
        if cutlass.const_expr(self.use_page_table):
            k_idx[0] = common_params.mPT[k_index]
        else:
            k_idx[0] = common_params.blk_coord[2]
        for i in cutlass.range_constexpr(self.iterations_pv_k):
            for j in cutlass.range_constexpr(self.iterations_pv_n):
                # get the mbar ptr from pipeline.
                tma_bar_ptr = common_params.load_kv_pipeline.producer_get_barrier(
                    load_kv_producer_state
                )
                common_params.load_kv_pipeline.producer_acquire(load_kv_producer_state)
                if cutlass.const_expr(self.use_page_table):
                    cute.copy(
                        v_params.tma_atom_c_latent_transpose,
                        v_params.tCLTgCLT[None, j, i, k_idx[0]],
                        v_params.tVCsVC[None, load_kv_producer_state.index],
                        tma_bar_ptr=tma_bar_ptr,
                    )
                else:
                    cute.copy(
                        v_params.tma_atom_c_latent_transpose,
                        v_params.tCLTgCLT[
                            None,
                            j,
                            k_index * self.iterations_pv_k + i,
                            k_idx[0],
                        ],
                        v_params.tVCsVC[None, load_kv_producer_state.index],
                        tma_bar_ptr=tma_bar_ptr,
                    )
                load_kv_producer_state.advance()
        return load_kv_producer_state

    @cute.jit
    def mma(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        pv_params: SimpleNamespace,
        k_tile_count: cutlass.Int32,
        tiled_mma_qk: cute.TiledMma,
        tiled_mma_pv: cute.TiledMma,
        load_q_consumer_state: pipeline.PipelineState,
        load_kv_consumer_state: pipeline.PipelineState,
        mma_s_producer_state: pipeline.PipelineState,
        p_mma_consumer_state: pipeline.PipelineState,
        mma_o_producer_state: pipeline.PipelineState,
    ) -> tuple[
        cute.TiledMma,
        cute.TiledMma,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
    ]:
        """MMA warp to compute the result of Q*K^T and P*V. Updates the tiled mma and pipeline states.

        :param common_params: The common parameters for mma qk and pv
        :type common_params: SimpleNamespace
        :param qk_params: The mma qk parameters
        :type qk_params: SimpleNamespace
        :param pv_params: The mma pv parameters
        :type pv_params: SimpleNamespace
        :param k_tile_count: The k tile count
        :type k_tile_count: cutlass.Int32
        :param tiled_mma_qk: The tiled mma qk
        :type tiled_mma_qk: cute.TiledMma
        :param tiled_mma_pv: The tiled mma pv
        :type tiled_mma_pv: cute.TiledMma
        :param load_q_consumer_state: The load q consumer state
        :type load_q_consumer_state: pipeline.PipelineState
        :param load_kv_consumer_state: The load kv consumer state
        :type load_kv_consumer_state: pipeline.PipelineState
        :param mma_s_producer_state: The mma s producer state
        :type mma_s_producer_state: pipeline.PipelineState
        :param p_mma_consumer_state: The p mma consumer state
        :type p_mma_consumer_state: pipeline.PipelineState
        :param mma_o_producer_state: The mma o producer state
        :type mma_o_producer_state: pipeline.PipelineState

        :return: The tiled mma qk, the tiled mma pv, the load q consumer state, the load kv consumer state, the mma s producer state, the p mma consumer state, and the mma o producer state
        :rtype: tuple[cute.TiledMma, cute.TiledMma, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]
        """

        tSrQ = tiled_mma_qk.make_fragment_A(qk_params.sQ)
        tSrKC = tiled_mma_qk.make_fragment_B(qk_params.sKC)
        tOrP = tiled_mma_pv.make_fragment_A(pv_params.sP)
        tOrVC = tiled_mma_pv.make_fragment_B(pv_params.sVC)

        tStS_shape = tiled_mma_qk.partition_shape_C(
            cute.select(self.mma_qk_tiler, mode=[0, 1])
        )
        tStS_staged_fake = tiled_mma_qk.make_fragment_C(
            cute.append(tStS_shape, self.mma_s_stage)
        )
        # use real tmem ptr for tStS
        tStS_staged = cute.make_tensor(common_params.tmem_ptr, tStS_staged_fake.layout)
        tOtO_shape = tiled_mma_pv.partition_shape_C(
            cute.select(self.mma_pv_tiler, mode=[0, 1])
        )
        # mma O has 1 stage.
        assert self.mma_o_stage == 1, (
            "mma O has 1 stage, otherwise the tmem usage exceeds the limit."
        )
        tOtO = tiled_mma_pv.make_fragment_C(tOtO_shape)
        tOtO_layout = cute.append(
            tOtO.layout,
            cute.make_layout(
                common_params.L // self.mma_pv_tiler[1],
                stride=self.mma_pv_tiler[1] // self.warps_in_n,
            ),
        )
        tOtO_staged = cute.make_tensor(
            tStS_staged.iterator + self.tmem_o_offset, tOtO_layout
        )

        # set more parameters
        qk_params.tSrQ = tSrQ
        qk_params.tSrKC = tSrKC
        qk_params.tStS_staged = tStS_staged
        pv_params.tOrP = tOrP
        pv_params.tOrVC = tOrVC
        pv_params.tOtO_staged = tOtO_staged

        # mma O accumulates on K, so the accumlate flag is set to False once before all K blocks.
        tiled_mma_pv.set(tcgen05.Field.ACCUMULATE, False)
        load_q_pipeline = common_params.load_q_pipeline
        if common_params.is_leader_cta:
            load_q_release_state = load_q_consumer_state.clone()
            (
                tiled_mma_qk,
                load_q_consumer_state,
                load_kv_consumer_state,
                mma_s_producer_state,
            ) = self.mma_qk(
                common_params,
                qk_params,
                tiled_mma_qk,
                load_q_consumer_state,
                load_kv_consumer_state,
                mma_s_producer_state,
                wait_q=True,
            )
            k_tile_count -= 1

            while k_tile_count > 0:
                (
                    tiled_mma_qk,
                    load_q_consumer_state,
                    load_kv_consumer_state,
                    mma_s_producer_state,
                ) = self.mma_qk(
                    common_params,
                    qk_params,
                    tiled_mma_qk,
                    load_q_consumer_state,
                    load_kv_consumer_state,
                    mma_s_producer_state,
                    wait_q=False,
                )
                (
                    tiled_mma_pv,
                    load_kv_consumer_state,
                    p_mma_consumer_state,
                    mma_o_producer_state,
                ) = self.mma_pv(
                    common_params,
                    pv_params,
                    tiled_mma_pv,
                    load_kv_consumer_state,
                    p_mma_consumer_state,
                    mma_o_producer_state,
                )
                k_tile_count -= 1
            # release q consumer states
            for i in cutlass.range_constexpr(self.iterations_qk):
                load_q_pipeline.consumer_release(load_q_release_state)
                load_q_release_state.advance()
            (
                tiled_mma_pv,
                load_kv_consumer_state,
                p_mma_consumer_state,
                mma_o_producer_state,
            ) = self.mma_pv(
                common_params,
                pv_params,
                tiled_mma_pv,
                load_kv_consumer_state,
                p_mma_consumer_state,
                mma_o_producer_state,
            )

        return (
            tiled_mma_qk,
            tiled_mma_pv,
            load_q_consumer_state,
            load_kv_consumer_state,
            mma_s_producer_state,
            p_mma_consumer_state,
            mma_o_producer_state,
        )

    @cute.jit
    def mma_qk(
        self,
        common_params: SimpleNamespace,
        qk_params: SimpleNamespace,
        tiled_mma_qk: cute.TiledMma,
        load_q_consumer_state: pipeline.PipelineState,
        load_kv_consumer_state: pipeline.PipelineState,
        mma_s_producer_state: pipeline.PipelineState,
        wait_q: bool,
    ) -> tuple[
        cute.TiledMma,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
    ]:
        """Compute one k-tile of mma for Q*K^T. Updates the tiled MMA QK and pipeline states.

        :param qk_params: The qk parameters
        :type qk_params: SimpleNamespace
        :param tiled_mma_qk: The tiled mma qk
        :type tiled_mma_qk: cute.TiledMma
        :param load_q_consumer_state: The load q consumer state
        :type load_q_consumer_state: pipeline.PipelineState
        :param load_kv_consumer_state: The load kv consumer state
        :type load_kv_consumer_state: pipeline.PipelineState
        :param mma_s_producer_state: The mma s producer state
        :type mma_s_producer_state: pipeline.PipelineState

        :return: The tiled mma qk, the load q consumer state, the load kv consumer state, and the mma s producer state
        :rtype: tuple[cute.TiledMma, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]
        """
        tStS = qk_params.tStS_staged[None, None, None, mma_s_producer_state.index]

        qk_params.mma_s_pipeline.producer_acquire(mma_s_producer_state)
        tiled_mma_qk.set(tcgen05.Field.ACCUMULATE, False)
        load_q_pipeline = common_params.load_q_pipeline
        load_kv_pipeline = common_params.load_kv_pipeline
        for q_stage in range(self.iterations_qk_latent):
            if cutlass.const_expr(wait_q):
                load_q_pipeline.consumer_wait(load_q_consumer_state)
            load_kv_pipeline.consumer_wait(load_kv_consumer_state)
            kc_stage = load_kv_consumer_state.index
            for k_block in cutlass.range_constexpr(cute.size(qk_params.tSrQ.shape[2])):
                cute.gemm(
                    tiled_mma_qk,
                    tStS,
                    qk_params.tSrQ[None, None, k_block, q_stage],
                    qk_params.tSrKC[None, None, k_block, kc_stage],
                    tStS,
                )
                tiled_mma_qk.set(tcgen05.Field.ACCUMULATE, True)
            load_kv_pipeline.consumer_release(load_kv_consumer_state)
            load_kv_consumer_state.advance()
            if cutlass.const_expr(wait_q):
                load_q_consumer_state.advance()
        for q_stage in range(self.iterations_qk_rope):
            if cutlass.const_expr(wait_q):
                load_q_pipeline.consumer_wait(load_q_consumer_state)
            load_kv_pipeline.consumer_wait(load_kv_consumer_state)
            kc_stage = load_kv_consumer_state.index
            for k_block in cutlass.range_constexpr(
                self.rope_dim // tiled_mma_qk.shape_mnk[2]
            ):
                cute.gemm(
                    tiled_mma_qk,
                    tStS,
                    qk_params.tSrQ[
                        None, None, k_block, q_stage + self.iterations_qk_latent
                    ],
                    qk_params.tSrKC[None, None, k_block, kc_stage],
                    tStS,
                )
                tiled_mma_qk.set(tcgen05.Field.ACCUMULATE, True)
            load_kv_pipeline.consumer_release(load_kv_consumer_state)
            load_kv_consumer_state.advance()
            if cutlass.const_expr(wait_q):
                load_q_consumer_state.advance()

        qk_params.mma_s_pipeline.producer_commit(mma_s_producer_state)
        mma_s_producer_state.advance()
        return (
            tiled_mma_qk,
            load_q_consumer_state,
            load_kv_consumer_state,
            mma_s_producer_state,
        )

    @cute.jit
    def mma_pv(
        self,
        common_params: SimpleNamespace,
        pv_params: SimpleNamespace,
        tiled_mma_pv: cute.TiledMma,
        load_kv_consumer_state: pipeline.PipelineState,
        p_mma_consumer_state: pipeline.PipelineState,
        mma_o_producer_state: pipeline.PipelineState,
    ) -> tuple[
        cute.TiledMma,
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
    ]:
        """Compute one k-tile of mma for P*V. Updates the tiled mma pv and pipeline states.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param pv_params: The pv parameters
        :type pv_params: SimpleNamespace
        :param tiled_mma_pv: The tiled mma pv
        :type tiled_mma_pv: cute.TiledMma
        :param load_kv_consumer_state: The load kv consumer state
        :type load_kv_consumer_state: pipeline.PipelineState
        :param p_mma_consumer_state: The P MMA consumer state
        :type p_mma_consumer_state: pipeline.PipelineState
        :param mma_o_producer_state: The MMA o producer state
        :type mma_o_producer_state: pipeline.PipelineState

        :return: The tiled mma pv, the load qkv consumer state, the P MMA consumer state, and the MMA o producer state
        :rtype: tuple[cute.TiledMma, pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]
        """

        pv_params.mma_o_pipeline.producer_acquire(mma_o_producer_state)
        pv_params.p_mma_pipeline.consumer_wait(p_mma_consumer_state)
        load_kv_pipeline = common_params.load_kv_pipeline
        for p_stage in range(self.iterations_pv_k):
            accumulate_flag = tiled_mma_pv.get(tcgen05.Field.ACCUMULATE)
            for acc_stage in range(self.iterations_pv_n):
                load_kv_pipeline.consumer_wait(load_kv_consumer_state)
                tiled_mma_pv.set(tcgen05.Field.ACCUMULATE, accumulate_flag)
                vc_stage = load_kv_consumer_state.index
                tOtO = pv_params.tOtO_staged[None, None, None, acc_stage]
                for k_block in cutlass.range_constexpr(pv_params.tOrP.shape[2]):
                    cute.gemm(
                        tiled_mma_pv,
                        tOtO,
                        pv_params.tOrP[
                            None,
                            None,
                            k_block,
                            (p_stage, p_mma_consumer_state.index),
                        ],
                        pv_params.tOrVC[None, None, k_block, vc_stage],
                        tOtO,
                    )
                    tiled_mma_pv.set(tcgen05.Field.ACCUMULATE, True)
                load_kv_pipeline.consumer_release(load_kv_consumer_state)
                load_kv_consumer_state.advance()
        pv_params.p_mma_pipeline.consumer_release(p_mma_consumer_state)
        p_mma_consumer_state.advance()
        pv_params.mma_o_pipeline.producer_commit(mma_o_producer_state)
        mma_o_producer_state.advance()

        return (
            tiled_mma_pv,
            load_kv_consumer_state,
            p_mma_consumer_state,
            mma_o_producer_state,
        )

    @cute.jit
    def compute(
        self,
        common_params: SimpleNamespace,
        softmax_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_count: cutlass.Int32,
        mma_s_consumer_state: pipeline.PipelineState,
        p_mma_producer_state: pipeline.PipelineState,
        p_cor_producer_state: pipeline.PipelineState,
    ) -> tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]:
        """Compute warp to compute the result of softmax, rescale, and epilogue. Updates the related pipeline states.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param softmax_params: The softmax parameters
        :type softmax_params: SimpleNamespace
        :param k_index: The index of the k-tile
        :type k_index: cutlass.Int32
        :param k_tile_count: The number of k-tiles
        :type k_tile_count: cutlass.Int32
        :param mma_s_consumer_state: The MMA s consumer state
        :type mma_s_consumer_state: pipeline.PipelineState
        :param p_mma_producer_state: The P MMA producer state
        :type p_mma_producer_state: pipeline.PipelineState
        :param p_cor_producer_state: The P correction producer state
        :type p_cor_producer_state: pipeline.PipelineState

        :return: The MMA s consumer state, the P MMA producer state, and the P correction producer state
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState]
        """

        k_tile_total = cute.ceil_div(common_params.K, self.mma_qk_tiler[1])

        row_max = -self.acc_dtype.inf
        row_sum = self.acc_dtype(0)
        correction_factor = self.acc_dtype(1)
        while k_tile_count > 0:
            (
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
            ) = self.softmax_dispatch_apply_mask(
                common_params,
                softmax_params,
                k_index,
                k_tile_total,
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
            )
            k_index = k_index + 1
            k_tile_count = k_tile_count - 1

        return mma_s_consumer_state, p_mma_producer_state, p_cor_producer_state

    @cute.jit
    def correction(
        self,
        common_params: SimpleNamespace,
        epilogue_params: SimpleNamespace,
        k_tile_count: cutlass.Int32,
        p_cor_consumer_state: pipeline.PipelineState,
        mma_o_consumer_state: pipeline.PipelineState,
    ) -> tuple[pipeline.PipelineState, pipeline.PipelineState]:
        """Compute warp to compute the result of softmax, rescale, and epilogue. Updates the related pipeline states.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param epilogue_params: The epilogue parameters
        :type epilogue_params: SimpleNamespace
        :param k_index: The index of the k-tile
        :type k_index: cutlass.Int32
        :param k_tile_count: The number of k-tiles
        :type k_tile_count: cutlass.Int32
        :param p_cor_consumer_state: The P correction consumer state
        :type p_cor_consumer_state: pipeline.PipelineState
        :param mma_o_consumer_state: The MMA o consumer state
        :type mma_o_consumer_state: pipeline.PipelineState

        :return: The P correction consumer state, and the MMA o consumer state
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState]
        """

        p_cor_consumer_state, row_sum, row_max, correction_factor, no_correction = (
            self.get_correction_factor(common_params, p_cor_consumer_state)
        )
        k_tile_count = k_tile_count - 1
        while k_tile_count > 0:
            p_cor_consumer_state, row_sum, row_max, correction_factor, no_correction = (
                self.get_correction_factor(common_params, p_cor_consumer_state)
            )
            mma_o_consumer_state = self.rescale(
                common_params, mma_o_consumer_state, correction_factor, no_correction
            )
            k_tile_count = k_tile_count - 1

        mma_o_consumer_state = self.epilogue(
            common_params, epilogue_params, mma_o_consumer_state, row_sum, row_max
        )
        return p_cor_consumer_state, mma_o_consumer_state

    @cute.jit
    def softmax_dispatch_apply_mask(
        self,
        common_params: SimpleNamespace,
        softmax_params: SimpleNamespace,
        k_index: cutlass.Int32,
        k_tile_total: cutlass.Int32,
        mma_s_consumer_state: pipeline.PipelineState,
        p_mma_producer_state: pipeline.PipelineState,
        p_cor_producer_state: pipeline.PipelineState,
        row_max: cutlass.Float32,
        row_sum: cutlass.Float32,
        correction_factor: cutlass.Float32,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        cutlass.Float32,
        cutlass.Float32,
        cutlass.Float32,
    ]:
        """Dispatch whether to apply mask for softmax for last k tile.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param softmax_params: The softmax parameters
        :type softmax_params: SimpleNamespace
        :param k_index: The index of the k-tile
        :type k_index: cutlass.Int32
        :param k_tile_total: The total number of k-tiles
        :type k_tile_total: cutlass.Int32
        :param mma_s_consumer_state: The MMA s consumer state
        :type mma_s_consumer_state: pipeline.PipelineState
        :param p_mma_producer_state: The P MMA producer state
        :type p_mma_producer_state: pipeline.PipelineState
        :param p_cor_producer_state: The P correction producer state
        :type p_cor_producer_state: pipeline.PipelineState
        :param row_max: The row max
        :type row_max: cutlass.Float32
        :param row_sum: The row sum
        :type row_sum: cutlass.Float32
        :param correction_factor: The correction factor
        :type correction_factor: cutlass.Float32

        :return: The MMA s consumer state, the P MMA producer state, the row max, the row sum, and the correction factor
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, cutlass.Float32, cutlass.Float32, cutlass.Float32]
        """
        if k_index == k_tile_total - 1:
            (
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
            ) = self.softmax(
                common_params,
                softmax_params,
                k_index,
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
                True,
            )
        else:
            (
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
            ) = self.softmax(
                common_params,
                softmax_params,
                k_index,
                mma_s_consumer_state,
                p_mma_producer_state,
                p_cor_producer_state,
                row_max,
                row_sum,
                correction_factor,
                False,
            )
        return (
            mma_s_consumer_state,
            p_mma_producer_state,
            p_cor_producer_state,
            row_max,
            row_sum,
            correction_factor,
        )

    @cute.jit
    def softmax(
        self,
        common_params: SimpleNamespace,
        softmax_params: SimpleNamespace,
        k_index: cutlass.Int32,
        mma_s_consumer_state: pipeline.PipelineState,
        p_mma_producer_state: pipeline.PipelineState,
        p_cor_producer_state: pipeline.PipelineState,
        row_max: cutlass.Float32,
        row_sum: cutlass.Float32,
        correction_factor: cutlass.Float32,
        is_last_tile: bool,
    ) -> tuple[
        pipeline.PipelineState,
        pipeline.PipelineState,
        pipeline.PipelineState,
        cutlass.Float32,
        cutlass.Float32,
        cutlass.Float32,
    ]:
        """Softmax for one k-tile. Updates the related pipeline states and returns the computed results.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param softmax_params: The softmax parameters
        :type softmax_params: SimpleNamespace
        :param k_index: The index of the k-tile
        :type k_index: cutlass.Int32
        :param mma_s_consumer_state: The MMA s consumer state
        :type mma_s_consumer_state: pipeline.PipelineState
        :param p_mma_producer_state: The P MMA producer state
        :type p_mma_producer_state: pipeline.PipelineState
        :param p_cor_producer_state: The P correction producer state
        :type p_cor_producer_state: pipeline.PipelineState
        :param row_max: The row max
        :type row_max: cutlass.Float32
        :param row_sum: The row sum
        :type row_sum: cutlass.Float32
        :param correction_factor: The correction factor
        :type correction_factor: cutlass.Float32
        :param is_last_tile: Whether the last tile
        :type is_last_tile: bool

        :return: The MMA s consumer state, the P MMA producer state, the P correction producer state, the row max, the row sum, and the correction factor
        :rtype: tuple[pipeline.PipelineState, pipeline.PipelineState, pipeline.PipelineState, cutlass.Float32, cutlass.Float32, cutlass.Float32]
        """

        softmax_params.p_mma_pipeline.producer_acquire(p_mma_producer_state)
        softmax_params.mma_s_pipeline.consumer_wait(mma_s_consumer_state)

        # load S from tmem
        tStS_shape = softmax_params.tiled_mma_qk.partition_shape_C(
            cute.select(self.mma_qk_tiler, mode=[0, 1])
        )
        tStS_staged_fake = softmax_params.tiled_mma_qk.make_fragment_C(
            cute.append(tStS_shape, self.mma_s_stage)
        )
        tStS_staged = cute.make_tensor(common_params.tmem_ptr, tStS_staged_fake.layout)
        tStS = tStS_staged[None, None, None, mma_s_consumer_state.index]

        tAcc = tStS[(None, None), 0, 0]
        cta_qk_tiler = (
            self.mma_qk_tiler[0] // self.cluster_shape_mnk[0],
            self.mma_qk_tiler[1],
            self.mma_qk_tiler[2],
        )
        cS = cute.make_identity_tensor(cute.select(cta_qk_tiler, mode=[0, 1]))

        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)), self.acc_dtype
        )
        tmem_tiled_copy = tcgen05.make_tmem_copy(tmem_load_atom, tAcc)

        tidx = common_params.tidx % (self.num_compute_warps * self.threads_per_warp)

        tmem_thr_copy = tmem_tiled_copy.get_slice(tidx)
        tTR_tAcc = tmem_thr_copy.partition_S(tAcc)
        tTR_tS = tmem_thr_copy.partition_D(cS)

        tTR_rAcc = cute.make_fragment_like(tTR_tS, self.acc_dtype)

        cute.copy(tmem_tiled_copy, tTR_tAcc, tTR_rAcc)

        row_max_new = row_max
        for i in cutlass.range_constexpr(cute.size(tTR_rAcc)):
            if cutlass.const_expr(is_last_tile):
                tTR_rAcc[i] = (
                    tTR_rAcc[i]
                    if cute.elem_less(
                        tTR_tS[i][1] + self.mma_qk_tiler[1] * k_index,
                        common_params.K,
                    )
                    else -self.acc_dtype.inf
                )
            # update row_max
            row_max_new = cute.arch.fmax(row_max_new, tTR_rAcc[i])

        # if warps in N is 2, reduce row_max across warps (0, 1) and (2, 3)
        if cutlass.const_expr(self.warps_in_n == 2):
            common_params.smem_exchange[tidx] = row_max_new
            self.softmax_exchange_sync_bar.wait()
            row_max_new = cute.arch.fmax(
                row_max_new,
                common_params.smem_exchange[
                    (tidx + 64) % (self.num_compute_warps * self.threads_per_warp)
                ],
            )

        # find correction factor
        correction_factor = cute.math.exp2(
            (row_max - row_max_new) * softmax_params.softmax_scale_log2, fastmath=True
        )
        no_correction = cutlass.Int32(row_max == row_max_new)
        # softmax
        fma_b = (softmax_params.softmax_scale_log2, softmax_params.softmax_scale_log2)
        fma_c = (
            (0.0 - row_max_new) * softmax_params.softmax_scale_log2,
            (0.0 - row_max_new) * softmax_params.softmax_scale_log2,
        )

        for i in cutlass.range_constexpr(0, cute.size(tTR_rAcc), 2):
            tTR_rAcc[i], tTR_rAcc[i + 1] = cute.arch.fma_packed_f32x2(
                (tTR_rAcc[i], tTR_rAcc[i + 1]), fma_b, fma_c
            )
            tTR_rAcc[i] = cute.math.exp2(tTR_rAcc[i], fastmath=True)
            tTR_rAcc[i + 1] = cute.math.exp2(tTR_rAcc[i + 1], fastmath=True)

        tTR_rS = cute.make_fragment_like(tTR_tS, self.q_dtype)

        # quantize
        tTR_rS.store(tTR_rAcc.load().to(self.q_dtype))

        # create sP
        sP = softmax_params.sP[None, None, None, (None, p_mma_producer_state.index)]
        sP_mk_view = cute.make_tensor(
            sP.iterator,
            cute.make_layout(
                (
                    (sP.shape[0][0], sP.shape[1]),
                    (sP.shape[0][1], sP.shape[2], sP.shape[3]),
                ),
                stride=(
                    (sP.stride[0][0], sP.stride[1]),
                    (sP.stride[0][1], sP.stride[2], sP.stride[3]),
                ),
            ),
        )
        # change to PISL
        sP_wo_swizzle_iter = cute.recast_ptr(sP.iterator, swizzle_=None)
        swizzle_bits = (
            int(math.log2(self.mma_pv_tiler[2] * self.q_dtype.width // 8 // 32)) + 1
        )
        swizzle_base = 3 if self.q_dtype.width == 16 else 4
        sP_swizzle = cute.make_swizzle(swizzle_bits, swizzle_base, 3)
        sP_mk_view = cute.make_tensor(
            sP_wo_swizzle_iter,
            cute.make_composed_layout(sP_swizzle, 0, sP_mk_view.layout),
        )
        universal_copy_bits = 128
        smem_copy_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            self.q_dtype,
            num_bits_per_copy=universal_copy_bits,
        )
        smem_tiled_copy = cute.make_tiled_copy_D(smem_copy_atom, tmem_tiled_copy)
        smem_thr_copy = smem_tiled_copy.get_slice(tidx)
        rP_copy_view = smem_thr_copy.retile(tTR_rS)
        sP_copy_view = smem_thr_copy.partition_D(sP_mk_view)
        cute.copy(smem_tiled_copy, rP_copy_view, sP_copy_view)

        # row_sum, using `add_packed_f32x2` to reduce the number of instructions
        row_sum = row_sum * correction_factor
        row_sum_vec = (0.0, 0.0)
        for i in cutlass.range_constexpr(0, cute.size(tTR_rAcc), 2):
            row_sum_vec = cute.arch.add_packed_f32x2(
                row_sum_vec, (tTR_rAcc[i], tTR_rAcc[i + 1])
            )
        row_sum = row_sum_vec[0] + row_sum_vec[1] + row_sum

        # fence between tmem load and mma s
        cute.arch.fence_view_async_tmem_load()
        # fence between smem store and mma o
        cute.arch.fence_view_async_shared()

        softmax_params.mma_s_pipeline.consumer_release(mma_s_consumer_state)
        softmax_params.p_mma_pipeline.producer_commit(p_mma_producer_state)
        mma_s_consumer_state.advance()
        p_mma_producer_state.advance()

        # store correction factor/row_sum/row_max to tmem for correction warp
        common_params.p_cor_pipeline.producer_acquire(p_cor_producer_state)
        # pad for 4x32b
        corr_layout = cute.make_layout(
            (tAcc.shape[0], (4, tAcc.shape[1][1]), self.mma_s_stage),
            stride=(tAcc.stride[0], (1, tAcc.stride[1][1]), 4),
        )
        tCor = cute.make_tensor(
            common_params.tmem_ptr + self.correction_factor_offset,
            corr_layout,
        )
        cCor = cute.make_identity_tensor(tCor.shape)
        corr_tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(4)), self.acc_dtype
        )
        corr_tmem_store_tiled_copy = tcgen05.make_tmem_copy(corr_tmem_store_atom, tCor)
        corr_tmem_store_thr_copy = corr_tmem_store_tiled_copy.get_slice(tidx)
        cCor_for_copy = corr_tmem_store_thr_copy.partition_S(cCor)
        tCor_for_copy = corr_tmem_store_thr_copy.partition_D(tCor)
        rCor = cute.make_fragment_like(
            cCor_for_copy[None, None, None, 0], self.acc_dtype
        )
        rCor_int = cute.make_tensor(
            cute.recast_ptr(rCor.iterator, dtype=cutlass.Int32), rCor.layout
        )
        rCor[0] = row_sum
        rCor[1] = row_max_new
        rCor[2] = correction_factor
        rCor_int[3] = no_correction

        cute.copy(
            corr_tmem_store_tiled_copy,
            rCor,
            tCor_for_copy[None, None, None, p_cor_producer_state.index],
        )
        # fence between tmem store and correction warp
        cute.arch.fence_view_async_tmem_store()
        common_params.p_cor_pipeline.producer_commit(p_cor_producer_state)
        p_cor_producer_state.advance()

        return (
            mma_s_consumer_state,
            p_mma_producer_state,
            p_cor_producer_state,
            row_max_new,
            row_sum,
            correction_factor,
        )

    @cute.jit
    def _tmem_load_partition(
        self, common_params: SimpleNamespace, tiled_mma_pv: cute.TiledMma, iter_n: int
    ) -> tuple[
        cute.TiledMma, cute.TiledMma, cute.TiledMma, cute.TiledMma, cute.TiledMma
    ]:
        """Tensor memory load partition for rescale and epilogue.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param tiled_mma_pv: The tiled mma pv
        :type tiled_mma_pv: cute.TiledMma
        :param iter_n: The iteration number
        :type iter_n: int

        :return: The tiled mma pv, the tiled mma pv, the tiled mma pv, the tiled mma pv, the tiled mma pv
        :rtype: tuple[cute.TiledMma, cute.TiledMma, cute.TiledMma, cute.TiledMma, cute.TiledMma]
        """

        tOtO_shape = tiled_mma_pv.partition_shape_C(
            cute.select(self.mma_pv_tiler, mode=[0, 1])
        )
        tOtO = tiled_mma_pv.make_fragment_C(tOtO_shape)
        tOtO_layout = cute.append(
            tOtO.layout,
            cute.make_layout(
                common_params.L // self.mma_pv_tiler[1],
                stride=self.mma_pv_tiler[1] // self.warps_in_n,
            ),
        )
        tOtO = cute.make_tensor(
            common_params.tmem_ptr + self.tmem_o_offset, tOtO_layout
        )
        tOtO = tOtO[None, None, None, iter_n]

        tAcc = tOtO[(None, None), 0, 0]

        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)), self.acc_dtype
        )
        tmem_load_tiled_copy = tcgen05.make_tmem_copy(tmem_load_atom, tAcc)
        tmem_load_thr_copy = tmem_load_tiled_copy.get_slice(
            common_params.tidx % (self.num_compute_warps * self.threads_per_warp)
        )

        cta_pv_tiler = (
            self.mma_pv_tiler[0] // self.cluster_shape_mnk[0],
            self.mma_pv_tiler[1],
            self.mma_pv_tiler[2],
        )
        # Flatten divide and partition global tensors for O
        cta_pv_tiler_mn = cute.select(cta_pv_tiler, mode=[0, 1])

        gO = None
        if cutlass.const_expr(common_params.mAccO is not None):
            gO = cute.local_tile(
                common_params.mAccO[None, common_params.blk_coord[3], None, None],
                cta_pv_tiler_mn,
                (common_params.blk_coord[0], iter_n, common_params.blk_coord[2]),
            )
            cO = cute.local_tile(
                cute.make_identity_tensor(
                    common_params.mAccO[
                        None, common_params.blk_coord[3], None, None
                    ].shape
                ),
                cta_pv_tiler_mn,
                (common_params.blk_coord[0], iter_n, common_params.blk_coord[2]),
            )
        else:
            gO = cute.local_tile(
                common_params.mO,
                cta_pv_tiler_mn,
                (common_params.blk_coord[0], iter_n, common_params.blk_coord[2]),
            )
            cO = cute.local_tile(
                cute.make_identity_tensor(common_params.mO.shape),
                cta_pv_tiler_mn,
                (common_params.blk_coord[0], iter_n, common_params.blk_coord[2]),
            )
        tTR_tAcc = tmem_load_thr_copy.partition_S(tAcc)
        tTR_gO = tmem_load_thr_copy.partition_D(gO)
        tTR_cO = tmem_load_thr_copy.partition_D(cO)
        tTR_rAcc = cute.make_fragment_like(tTR_gO, self.acc_dtype)
        return tmem_load_tiled_copy, tAcc, tTR_tAcc, tTR_gO, tTR_cO, tTR_rAcc

    def get_correction_factor(
        self,
        common_params: SimpleNamespace,
        p_cor_consumer_state: pipeline.PipelineState,
    ) -> tuple[
        pipeline.PipelineState,
        cutlass.Float32,
        cutlass.Float32,
        cutlass.Float32,
        cutlass.Int32,
    ]:
        """Get the correction factor from the P correction consumer state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param p_cor_consumer_state: The P correction consumer state
        :type p_cor_consumer_state: pipeline.PipelineState

        :return: The P correction consumer state, the row_sum, the row_max, and the correction factor
        :rtype: tuple[pipeline.PipelineState, cutlass.Float32, cutlass.Float32, cutlass.Float32, cutlass.Int32]
        """
        common_params.p_cor_pipeline.consumer_wait(p_cor_consumer_state)
        tidx = common_params.tidx % (self.num_compute_warps * self.threads_per_warp)
        # load correction factor
        _, tAcc, _, _, _, _ = self._tmem_load_partition(
            common_params, common_params.tiled_mma_pv, 0
        )
        corr_layout = cute.make_layout(
            (tAcc.shape[0], (4, tAcc.shape[1][1]), self.p_cor_stage),
            stride=(tAcc.stride[0], (1, tAcc.stride[1][1]), 4),
        )
        tCor = cute.make_tensor(
            common_params.tmem_ptr + self.correction_factor_offset, corr_layout
        )
        cCor = cute.make_identity_tensor(tCor.shape)
        corr_tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(4)), self.acc_dtype
        )
        corr_tmem_load_tiled_copy = tcgen05.make_tmem_copy(corr_tmem_load_atom, tCor)
        corr_tmem_load_thr_copy = corr_tmem_load_tiled_copy.get_slice(tidx)
        tCor_for_copy = corr_tmem_load_thr_copy.partition_S(tCor)
        cCor_for_copy = corr_tmem_load_thr_copy.partition_D(cCor)
        rCor = cute.make_fragment_like(
            cCor_for_copy[None, None, None, 0], self.acc_dtype
        )
        rCor_int = cute.make_tensor(
            cute.recast_ptr(rCor.iterator, dtype=cutlass.Int32), rCor.layout
        )
        cute.copy(
            corr_tmem_load_tiled_copy,
            tCor_for_copy[None, None, None, p_cor_consumer_state.index],
            rCor,
        )
        row_sum = rCor[0]
        row_max = rCor[1]
        correction_factor = rCor[2]
        no_correction = rCor_int[3]

        common_params.p_cor_pipeline.consumer_release(p_cor_consumer_state)
        p_cor_consumer_state.advance()
        return p_cor_consumer_state, row_sum, row_max, correction_factor, no_correction

    @cute.jit
    def rescale(
        self,
        common_params: SimpleNamespace,
        mma_o_consumer_state: pipeline.PipelineState,
        correction_factor: cutlass.Float32,
        no_correction: cutlass.Int32,
    ) -> pipeline.PipelineState:
        """Rescale for one k-tile. Updates the related pipeline state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param mma_o_consumer_state: The mma o consumer state
        :type mma_o_consumer_state: pipeline.PipelineState
        :param correction_factor: The correction factor
        :type correction_factor: cutlass.Float32
        :param no_correction: Whether to apply correction factor
        :type no_correction: cutlass.Int32

        :return: The MMA o consumer state
        :rtype: pipeline.PipelineState
        """

        common_params.mma_o_pipeline.consumer_wait(mma_o_consumer_state)
        skip_correction = cute.arch.vote_all_sync(no_correction == 1)
        if not skip_correction:
            for iter_n in cutlass.range_constexpr(self.iterations_pv_n):
                # tmem load tiled copy and partition results.
                tmem_load_tiled_copy, tAcc, tTR_tAcc, tTR_gO, tTR_cO, tTR_rAcc = (
                    self._tmem_load_partition(
                        common_params, common_params.tiled_mma_pv, iter_n
                    )
                )

                # tmem store tiled copy
                tmem_store_atom = cute.make_copy_atom(
                    tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(32)), self.acc_dtype
                )
                tmem_store_tiled_copy = tcgen05.make_tmem_copy(tmem_store_atom, tAcc)

                # load o
                cute.copy(tmem_load_tiled_copy, tTR_tAcc, tTR_rAcc)
                # rescale, using `mul_packed_f32x2` to reduce the number of instructions
                for i in cutlass.range_constexpr(0, cute.size(tTR_rAcc), 2):
                    tTR_rAcc[i], tTR_rAcc[i + 1] = cute.arch.mul_packed_f32x2(
                        (
                            tTR_rAcc[i],
                            tTR_rAcc[i + 1],
                        ),
                        (correction_factor, correction_factor),
                    )

                # store o to tensor memory for next k tile
                cute.copy(tmem_store_tiled_copy, tTR_rAcc, tTR_tAcc)

        cute.arch.fence_view_async_tmem_store()
        common_params.mma_o_pipeline.consumer_release(mma_o_consumer_state)
        mma_o_consumer_state.advance()

        return mma_o_consumer_state

    @cute.jit
    def epilogue(
        self,
        common_params: SimpleNamespace,
        epilogue_params: SimpleNamespace,
        mma_o_consumer_state: pipeline.PipelineState,
        row_sum: cutlass.Float32,
        row_max: cutlass.Float32,
    ) -> pipeline.PipelineState:
        """Epilogue for one k-tile. Updates the related pipeline state.

        :param common_params: The common parameters
        :type common_params: SimpleNamespace
        :param epilogue_params: The epilogue parameters
        :type epilogue_params: SimpleNamespace
        :param mma_o_consumer_state: The mma o consumer state
        :type mma_o_consumer_state: pipeline.PipelineState
        :param row_sum: The row sum
        :type row_sum: cutlass.Float32
        :param row_max: The row max
        :type row_max: cutlass.Float32

        :return: The MMA o consumer state
        :rtype: pipeline.PipelineState
        """
        # mma_o pipeline consumer wait
        common_params.mma_o_pipeline.consumer_wait(mma_o_consumer_state)

        tidx = common_params.tidx % (self.num_compute_warps * self.threads_per_warp)

        # exchange row_sum between warps (0, 1) and (2, 3)
        if cutlass.const_expr(self.warps_in_n == 2):
            common_params.smem_exchange[tidx] = row_sum
            self.epilogue_exchange_sync_bar.wait()
            # (64, 2)
            row_sum = (
                row_sum
                + common_params.smem_exchange[
                    (tidx + 64) % (self.num_compute_warps * self.threads_per_warp)
                ]
            )
        for iter_n in cutlass.range_constexpr(self.iterations_pv_n):
            # tmem load tiled copy and partition results.
            tmem_load_tiled_copy, tAcc, tTR_tAcc, tTR_gO, tTR_cO, tTR_rAcc = (
                self._tmem_load_partition(
                    common_params, common_params.tiled_mma_pv, iter_n
                )
            )

            # load o
            cute.copy(tmem_load_tiled_copy, tTR_tAcc, tTR_rAcc)

            # apply output scale and normalize by row_sum
            for i in cutlass.range_constexpr(0, cute.size(tTR_rAcc), 2):
                tTR_rAcc[i], tTR_rAcc[i + 1] = cute.arch.mul_packed_f32x2(
                    (tTR_rAcc[i], tTR_rAcc[i + 1]),
                    (
                        epilogue_params.output_scale * cute.arch.rcp_approx(row_sum),
                        epilogue_params.output_scale * cute.arch.rcp_approx(row_sum),
                    ),
                )

            # store o to global memory
            tR2G_rO_src = None
            tR2G_rO_dst = tTR_gO
            if cutlass.const_expr(common_params.mAccO is None):
                tR2G_rO_src = cute.make_fragment_like(tTR_gO, self.o_dtype)
                # using final output dtype for o
                tR2G_rO_src.store(tTR_rAcc.load().to(self.o_dtype))
            else:
                # using accumulate dtype for o
                tR2G_rO_src = tTR_rAcc

            if cute.elem_less(tTR_cO[0][0], common_params.H):
                cute.autovec_copy(tR2G_rO_src, tR2G_rO_dst)

            # store the lse to global memory
            cta_pv_tiler = (
                self.mma_pv_tiler[0] // self.cluster_shape_mnk[0],
                self.mma_pv_tiler[1],
                self.mma_pv_tiler[2],
            )
            gLSE = None
            cLSE = None
            if cutlass.const_expr(epilogue_params.mAccLSE is None):
                gLSE = cute.local_tile(
                    epilogue_params.mLSE,
                    (cta_pv_tiler[0], 1, 1),
                    (
                        common_params.blk_coord[0],
                        common_params.blk_coord[1],
                        common_params.blk_coord[2],
                    ),
                    (1, None, 1),
                )
                cLSE = cute.local_tile(
                    cute.make_identity_tensor(epilogue_params.mLSE.shape),
                    (cta_pv_tiler[0], 1, 1),
                    (
                        common_params.blk_coord[0],
                        common_params.blk_coord[1],
                        common_params.blk_coord[2],
                    ),
                    (1, None, 1),
                )

            else:
                gLSE = cute.local_tile(
                    epilogue_params.mAccLSE[None, common_params.blk_coord[3], None],
                    (cta_pv_tiler[0], 1, 1),
                    (
                        common_params.blk_coord[0],
                        common_params.blk_coord[1],
                        common_params.blk_coord[2],
                    ),
                    (1, None, 1),
                )
                cLSE = cute.local_tile(
                    cute.make_identity_tensor(
                        epilogue_params.mAccLSE[
                            None, common_params.blk_coord[3], None
                        ].shape
                    ),
                    (cta_pv_tiler[0], 1, 1),
                    (
                        common_params.blk_coord[0],
                        common_params.blk_coord[1],
                        common_params.blk_coord[2],
                    ),
                    (1, None, 1),
                )
            lse = (
                cute.math.log2(row_sum, fastmath=True)
                + epilogue_params.softmax_scale_log2 * row_max
            )
            if cutlass.const_expr(self.warps_in_n == 2):
                if cute.elem_less(cLSE[tidx][0], common_params.H):
                    gLSE[tidx] = lse

        cute.arch.fence_view_async_tmem_load()
        common_params.mma_o_pipeline.consumer_release(mma_o_consumer_state)
        mma_o_consumer_state.advance()

        return mma_o_consumer_state

    def make_and_init_load_qkv_pipeline(
        self, load_qkv_mbar_ptr, cta_layout_vmnk, load_stages, tx_count, is_cpasync
    ) -> pipeline.PipelineTmaUmma:
        """Create and initialize the tma load qkv pipeline.

        :param load_qkv_mbar_ptr: The load qkv mbar pointer
        :type load_qkv_mbar_ptr: cute.Tensor
        :param cta_layout_vmnk: The cta layout vmnk
        :type cta_layout_vmnk: tuple[int, int, int]
        :param load_stages: The load stages
        :type load_stages: list[int]
        :param tx_count: The tx count
        :type tx_count: int
        :param is_cpasync: Whether to use cpasync
        :type is_cpasync: bool

        :return: The tma load qkv pipeline
        :rtype: pipeline.PipelineTmaUmma
        """
        if is_cpasync:
            load_qkv_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.load_cp_async_warp_ids)
                * self.threads_per_warp
                * self.cluster_shape_mnk[0],
            )
            load_qkv_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            )
            return pipeline.PipelineAsyncUmma.create(
                barrier_storage=load_qkv_mbar_ptr,
                num_stages=load_stages,
                producer_group=load_qkv_producer_group,
                consumer_group=load_qkv_consumer_group,
                cta_layout_vmnk=cta_layout_vmnk,
            )
        else:
            load_qkv_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.load_tma_warp_id])
            )
            load_qkv_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            )
            return pipeline.PipelineTmaUmma.create(
                barrier_storage=load_qkv_mbar_ptr,
                num_stages=load_stages,
                producer_group=load_qkv_producer_group,
                consumer_group=load_qkv_consumer_group,
                tx_count=tx_count,
                cta_layout_vmnk=cta_layout_vmnk,
            )

    def make_and_init_mma_s_pipeline(
        self, mma_s_mbar_ptr, cta_layout_vmnk
    ) -> pipeline.PipelineUmmaAsync:
        """Create and initialize the mma s pipeline.

        :param mma_s_mbar_ptr: The mma s mbar pointer
        :type mma_s_mbar_ptr: cute.Tensor
        :param cta_layout_vmnk: The cta layout vmnk
        :type cta_layout_vmnk: tuple[int, int, int]

        :return: The mma s pipeline
        :rtype: pipeline.PipelineUmmaAsync
        """

        mma_s_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, len([self.mma_warp_id])
        )
        consumer_thread_size = (
            self.threads_per_warp
            * len(self.compute_warp_ids)
            * self.cluster_shape_mnk[0]
        )
        mma_s_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            consumer_thread_size,
        )
        return pipeline.PipelineUmmaAsync.create(
            barrier_storage=mma_s_mbar_ptr,
            num_stages=self.mma_s_stage,
            producer_group=mma_s_producer_group,
            consumer_group=mma_s_consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
        )

    def make_and_init_p_mma_pipeline(
        self, p_mma_mbar_ptr, cta_layout_vmnk
    ) -> pipeline.PipelineAsyncUmma:
        """Create and initialize the p mma pipeline.

        :param p_mma_mbar_ptr: The p mma mbar pointer
        :type p_mma_mbar_ptr: cute.Tensor
        :param cta_layout_vmnk: The cta layout vmnk
        :type cta_layout_vmnk: tuple[int, int, int]

        :return: The p mma pipeline
        :rtype: pipeline.PipelineAsyncUmma
        """

        producer_thread_size = (
            self.threads_per_warp
            * len(self.compute_warp_ids)
            * self.cluster_shape_mnk[0]
        )
        p_mma_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            producer_thread_size,
        )
        p_mma_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, len([self.mma_warp_id])
        )
        return pipeline.PipelineAsyncUmma.create(
            barrier_storage=p_mma_mbar_ptr,
            num_stages=self.p_mma_stage,
            producer_group=p_mma_producer_group,
            consumer_group=p_mma_consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
        )

    def make_and_init_p_cor_pipeline(
        self, p_cor_mbar_ptr
    ) -> pipeline.PipelineAsyncUmma:
        """Create and initialize the p correction pipeline.

        :param p_cor_mbar_ptr: The p correction mbar pointer
        :type p_cor_mbar_ptr: cute.Tensor

        :return: The p correction pipeline
        :rtype: pipeline.PipelineAsyncUmma
        """

        producer_thread_size = self.threads_per_warp * len(self.compute_warp_ids)
        p_cor_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            producer_thread_size,
        )
        p_cor_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            producer_thread_size,
        )
        return pipeline.PipelineAsync.create(
            barrier_storage=p_cor_mbar_ptr,
            num_stages=self.p_cor_stage,
            producer_group=p_cor_producer_group,
            consumer_group=p_cor_consumer_group,
        )

    def make_and_init_mma_o_pipeline(
        self, mma_o_mbar_ptr, cta_layout_vmnk
    ) -> pipeline.PipelineUmmaAsync:
        """Create and initialize the mma o pipeline.

        :param mma_o_mbar_ptr: The mma o mbar pointer
        :type mma_o_mbar_ptr: cute.Tensor
        :param cta_layout_vmnk: The cta layout vmnk
        :type cta_layout_vmnk: tuple[int, int, int]

        :return: The mma o pipeline
        :rtype: pipeline.PipelineUmmaAsync
        """

        mma_o_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, len([self.mma_warp_id])
        )
        consumer_thread_size = (
            self.threads_per_warp
            * len(self.compute_warp_ids)
            * self.cluster_shape_mnk[0]
        )
        mma_o_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            consumer_thread_size,
        )
        return pipeline.PipelineUmmaAsync.create(
            barrier_storage=mma_o_mbar_ptr,
            num_stages=self.mma_o_stage,
            producer_group=mma_o_producer_group,
            consumer_group=mma_o_consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
        )

    def make_and_init_load_pt_pipeline(self, load_pt_mbar_ptr):
        """Create and initialize the load page table pipeline.

        :param load_pt_mbar_ptr: The load page table mbar pointer
        :type load_pt_mbar_ptr: cute.Tensor

        :return: The load page table pipeline
        :rtype: pipeline.PipelineAsync
        """
        load_pt_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.threads_per_warp * len([self.load_pt_warp_id]),
        )
        load_pt_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.threads_per_warp * len(self.load_cp_async_warp_ids),
        )
        return pipeline.PipelineCpAsync.create(
            barrier_storage=load_pt_mbar_ptr,
            num_stages=self.load_pt_stage,
            producer_group=load_pt_producer_group,
            consumer_group=load_pt_consumer_group,
        )

    @staticmethod
    def _compute_grid(
        o: cute.Tensor,
        split_kv: cutlass.Int32,
        cluster_shape_mnk: Tuple[int, int, int],
        max_active_clusters: int,
        is_persistent: bool,
    ) -> Tuple[MLAStaticTileSchedulerParams, Tuple[int, int, int]]:
        """Compute grid shape for the output tensor C.

        :param c: The output tensor C
        :type c: cute.Tensor
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]

        :return: Tile scheduler parameters and grid shape.
        :rtype: tuple[MLAStaticTileSchedulerParams, tuple[int, int, int]]
        """
        o_shape = o.shape
        tile_sched_params = create_mla_static_tile_scheduler_params(
            is_persistent,
            cute.size(o_shape[2]),
            cluster_shape_mnk,
            split_kv,
        )
        grid = MLAStaticTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @staticmethod
    def get_workspace_size(
        H: int,
        D: int,
        B: int,
        split_kv: int,
        acc_dtype: Type[cutlass.Numeric],
    ) -> int:
        """Get the extra workspace(device memory) size for the MLA kernel when split_kv is not 1.

        :param H: The height of the output tensor C
        :type H: int
        :param D: The depth of the output tensor C
        :type D: int
        :param B: The batch size of the output tensor C
        :type B: int
        :param split_kv: The split key-value of the output tensor C
        :type split_kv: int
        :param acc_dtype: The data type of the output tensor C
        :type acc_dtype: Type[cutlass.Numeric]

        :return: The workspace size for the MLA kernel
        :rtype: int
        """
        if split_kv == 1:
            return 0
        return B * H * split_kv * (D + 1) * acc_dtype.width // 8

    @cute.jit
    def initialize_workspace(
        self,
        H: cutlass.Int32,
        D: cutlass.Int32,
        B: cutlass.Int32,
        split_kv: cutlass.Int32,
        acc_dtype: Type[cutlass.Numeric],
        workspace: cute.Tensor,
    ) -> tuple[cute.Tensor, cute.Tensor]:
        """Initialize the workspace for the MLA kernel. Construct the intermediate tensors
        acc_o and acc_lse.

        :param H: The height of the output tensor C
        :type H: cutlass.Int32
        :param D: The depth of the output tensor C
        :type D: cutlass.Int32
        :param B: The batch size of the output tensor C
        :type B: cutlass.Int32
        :param split_kv: The split key-value of the output tensor C
        :type split_kv: cutlass.Int32
        :param acc_dtype: The data type of the output tensor C
        :type acc_dtype: Type[cutlass.Numeric]
        :param workspace: The workspace tensor
        :type workspace: cute.Tensor

        :return: The output tensor C and the workspace tensor
        :rtype: tuple[cute.Tensor, cute.Tensor]
        """
        acc_o, acc_lse = None, None
        if cutlass.const_expr(workspace is not None):
            align = 128 // self.q_dtype.width
            acc_o_layout = cute.make_layout(
                (H, split_kv, D, B),
                stride=(
                    cute.assume(split_kv * D, align),
                    cute.assume(D, align),
                    1,
                    cute.assume(H * split_kv * D, align),
                ),
            )
            acc_o_iter = cute.recast_ptr(workspace.iterator, dtype=acc_dtype)
            acc_o = cute.make_tensor(acc_o_iter, acc_o_layout)
            acc_lse_layout = cute.make_layout(
                (H, split_kv, B), stride=(split_kv, 1, H * split_kv)
            )
            acc_lse_iter = cute.recast_ptr(
                workspace.iterator + cute.cosize(acc_o_layout) * acc_dtype.width // 8,
                dtype=acc_dtype,
            )
            acc_lse = cute.make_tensor(acc_lse_iter, acc_lse_layout)
        return acc_o, acc_lse

    @staticmethod
    def can_implement(
        B: int,
        K: int,
        H: int,
        L: int,
        R: int,
        in_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        lse_dtype: Type[cutlass.Numeric],
        mma_qk_tiler_mn: Tuple[int, int],
        mma_pv_tiler_mn: Tuple[int, int],
        split_kv: int,
        is_persistent: bool,
        is_cpasync: bool,
        is_var_seq: bool,
        is_var_split_kv: bool,
        use_page_table: bool,
        page_size: int,
    ) -> bool:
        """Check if the MLA kernel can be implemented.

        :param H: The height of the output tensor C
        :type H: int
        :param K: The width of the output tensor C
        :type K: int
        :param L: The length of the output tensor C
        :type L: int
        :param R: The row of the output tensor C
        :type R: int
        :param B: The batch size of the output tensor C
        :type B: int
        :param in_dtype: The data type of the input tensor
        :type in_dtype: Type[cutlass.Numeric]
        :param out_dtype: The data type of the output tensor
        :type out_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param lse_dtype: The data type of the log-sum-exp
        :type lse_dtype: Type[cutlass.Numeric]
        :param mma_qk_tiler_mn: The tile shape of the query-key matrix multiplication
        :type mma_qk_tiler_mn: Tuple[int, int]
        :param mma_pv_tiler_mn: The tile shape of the probability-value matrix multiplication
        :type mma_pv_tiler_mn: Tuple[int, int]
        :param split_kv: The split key-value of the output tensor C
        :type split_kv: int
        :param is_persistent: Whether to use persistent kernel optimization
        :type is_persistent: bool
        :param is_cpasync: Whether to use cpasync
        :type is_cpasync: bool
        :param is_var_seq: Whether to use variable sequence length
        :type is_var_seq: bool
        :param is_var_split_kv: Whether to use variable split_kv
        :type is_var_split_kv: bool
        :param use_page_table: Whether to use page table
        :type use_page_table: bool
        :param page_size: The page size of the page table
        :type page_size: int

        :return: Whether the MLA kernel can be implemented
        :rtype: bool
        """
        if L != 512 or R != 64:
            return False
        if in_dtype not in [cutlass.Float8E4M3FN, cutlass.Float16]:
            return False
        if out_dtype not in [cutlass.Float8E4M3FN, cutlass.Float16]:
            return False
        if acc_dtype != cutlass.Float32 or lse_dtype != cutlass.Float32:
            return False
        if is_cpasync:
            if not use_page_table:
                return False
            if page_size & (page_size - 1) != 0:
                return False
            if page_size > mma_qk_tiler_mn[1]:
                return False
        else:
            if use_page_table and page_size != mma_qk_tiler_mn[1]:
                return False
        if mma_qk_tiler_mn[0] != mma_pv_tiler_mn[0] or mma_qk_tiler_mn[0] != 128:
            return False
        if is_var_split_kv and (not use_page_table or not is_var_seq):
            return False
        if is_var_seq and not use_page_table:
            return False
        if not is_cpasync and (H > 128 or (H < 128 and split_kv != 1)):
            return False
        if is_cpasync and H != 128:
            return False
        if K <= 0:
            return False
        return True


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def run(
    batch_size: int,
    seq_len: int,
    num_heads: int,
    latent_dim: int,
    rope_dim: int,
    in_dtype: Type[cutlass.Numeric],
    out_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    lse_dtype: Type[cutlass.Numeric],
    mma_qk_tiler_mn: Tuple[int, int],
    mma_pv_tiler_mn: Tuple[int, int],
    split_kv: int,
    is_persistent: bool,
    is_cpasync: bool,
    is_var_seq: bool,
    is_var_split_kv: bool,
    use_page_table: bool,
    page_size: int,
    softmax_scale: float,
    output_scale: float,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool,
    **kwargs,
):
    """Execute Multi-Head Latent Attention (MLA) on Blackwell architecture and validate results.

    This function creates random input tensors for query latent/rope, compressed latent/rope, and value,
    then performs the complete MLA computation pipeline. It supports configurable data types, tiling parameters,
    page table, variable sequence length, and variable split_kv. Results can be validated against a PyTorch reference
    implementation or run multiple times for performance measurement.

    :param batch_size: Batch size
    :type batch_size: int
    :param seq_len: Sequence length
    :type seq_len: int
    :param num_heads: Number of heads
    :type num_heads: int
    :param latent_dim: dimension of query/compressed latent
    :type latent_dim: int
    :param rope_dim: dimension of query/compressed rope
    :type rope_dim: int
    :param in_dtype: Input data type for query/compressed latent/rope tensors
    :type in_dtype: Type[cutlass.Numeric]
    :param out_dtype: Output data type for attention output
    :type out_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type for query-key matrix multiplication
    :type acc_dtype: Type[cutlass.Numeric]
    :param lse_dtype: Accumulator data type for log-sum-exp
    :type lse_dtype: Type[cutlass.Numeric]
    :param mma_qk_tiler_mn: Matrix multiply accumulate tile shape (M, N) for query-key matrix multiplication
    :type mma_qk_tiler_mn: Tuple[int, int]
    :param mma_pv_tiler_mn: Matrix multiply accumulate tile shape (M, N) for probability-value matrix multiplication
    :type mma_pv_tiler_mn: Tuple[int, int]
    :param split_kv: Split key-value
    :type split_kv: int
    :param is_persistent: Whether to use persistent kernel optimization
    :type is_persistent: bool
    :param is_cpasync: Whether to use cpasync
    :type is_cpasync: bool
    :param is_var_seq: Whether to use variable sequence length
    :type is_var_seq: bool
    :param is_var_split_kv: Whether to use variable split_kv
    :type is_var_split_kv: bool
    :param use_page_table: Whether to use page table
    :type use_page_table: bool
    :param page_size: Page size of the page table
    :type page_size: int
    :param softmax_scale: Attention score scaling factor
    :type softmax_scale: float
    :param output_scale: Output scaling factor
    :type output_scale: float
    :param tolerance: Maximum acceptable error for validation
    :type tolerance: float
    :param warmup_iterations: Number of warmup iterations
    :type warmup_iterations: int
    :param iterations: Number of iterations to run for performance testing
    :type iterations: int
    :param skip_ref_check: Skip validation against reference implementation
    :type skip_ref_check: bool
    :param use_cold_l2: Whether to use cold L2 cache
    :type use_cold_l2: bool

    :raises ValueError: If input shapes are incompatible or head dimension is unsupported
    :raises RuntimeError: If GPU is unavailable for computation
    """

    print("Running Blackwell MLA test with:")
    print(f"  batch_size: {batch_size}")
    print(f"  seq_len: {seq_len}")
    print(f"  num_heads: {num_heads}")
    print(f"  latent_dim: {latent_dim}")
    print(f"  rope_dim: {rope_dim}")
    print(f"  in_dtype: {in_dtype}")
    print(f"  out_dtype: {out_dtype}")
    print(f"  acc_dtype: {acc_dtype}")
    print(f"  mma_qk_tiler_mn: {mma_qk_tiler_mn}")
    print(f"  mma_pv_tiler_mn: {mma_pv_tiler_mn}")
    print(f"  split_kv: {split_kv}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  is_cpasync: {is_cpasync}")
    print(f"  is_var_seq: {is_var_seq}")
    print(f"  is_var_split_kv: {is_var_split_kv}")
    print(f"  use_page_table: {use_page_table}")
    print(f"  page_size: {page_size}")
    print(f"  softmax_scale: {softmax_scale}")
    print(f"  output_scale: {output_scale}")
    print(f"  tolerance: {tolerance}")
    print(f"  warmup_iterations: {warmup_iterations}")
    print(f"  iterations: {iterations}")
    print(f"  skip_ref_check: {skip_ref_check}")
    print(f"  use_cold_l2: {use_cold_l2}")

    # Prepare pytorch tensors: Q, K, V (random from 0 to 2) and O (all zero)
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    if not BlackwellMultiHeadLatentAttentionForward.can_implement(
        batch_size,
        seq_len,
        num_heads,
        latent_dim,
        rope_dim,
        in_dtype,
        out_dtype,
        acc_dtype,
        lse_dtype,
        mma_qk_tiler_mn,
        mma_pv_tiler_mn,
        split_kv,
        is_persistent,
        is_cpasync,
        is_var_seq,
        is_var_split_kv,
        use_page_table,
        page_size,
    ):
        raise TypeError(
            f"Unsupported testcase {in_dtype}, {out_dtype}, {acc_dtype}, {lse_dtype}, {mma_qk_tiler_mn}, {mma_pv_tiler_mn}, {split_kv}, {is_persistent}, {is_cpasync}, {is_var_seq}, {is_var_split_kv}, {use_page_table}, {page_size}"
        )

    torch.manual_seed(1111)

    def create_data_tensor(
        B,
        HK,
        D,
        dtype,
        is_dynamic_layout=True,
        page_table=None,
        cache_seqs=None,
        is_lse=False,
    ):
        shape = (B, HK, D)
        if page_table is not None:
            if cache_seqs is not None:
                max_seq_len = torch.max(cache_seqs)
                shape = (B * ceil_div(max_seq_len, page_size), page_size, D)
            else:
                shape = (B * ceil_div(HK, page_size), page_size, D)

        permute_order = (1, 2, 0)
        stride_order = (2, 0, 1)
        leading_dim = 1
        if is_lse:
            shape = (B, HK)
            permute_order = (1, 0)
            stride_order = (1, 0)
            leading_dim = 0

        init_config = cutlass.torch.RandomInitConfig(min_val=-2, max_val=2)

        torch_dtype = (
            cutlass_torch.dtype(dtype) if dtype != cutlass.Float8E4M3FN else torch.int8
        )

        # Create dtype torch tensor (cpu)
        torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            shape,
            torch_dtype,
            permute_order=permute_order,
            init_type=cutlass.torch.TensorInitType.RANDOM,
            init_config=init_config,
        )

        # Create dtype torch tensor (gpu)
        torch_tensor_gpu = torch_tensor_cpu.cuda()

        # Create f32 torch tensor (cpu)
        f32_torch_tensor = torch_tensor_cpu.to(dtype=torch.float32)

        # Create dtype cute tensor (gpu)
        # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
        cute_tensor = from_dlpack(
            torch_tensor_gpu, assumed_align=16, use_32bit_stride=True
        )
        cute_tensor.element_type = dtype
        if is_dynamic_layout:
            cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
            if not is_lse:
                cute_tensor = cute_tensor.mark_compact_shape_dynamic(
                    mode=leading_dim,
                    stride_order=stride_order,
                    divisibility=(128 // dtype.width),
                )

        cute_tensor = cutlass_torch.convert_cute_tensor(
            f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=is_dynamic_layout,
        )

        return f32_torch_tensor, cute_tensor, torch_tensor_gpu

    def create_cache_seqs(batch_size, seq_len, is_var_seq):
        cache_seqs_ref = torch.ones(batch_size, dtype=torch.int32) * seq_len
        cache_seqs_gpu = cache_seqs_ref.cuda()
        # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
        cache_seqs = from_dlpack(
            cache_seqs_gpu, assumed_align=16, use_32bit_stride=True
        ).mark_layout_dynamic()
        if is_var_seq:
            max_seq_len = seq_len
            min_seq_len = int(seq_len * 0.8)
            cache_seqs_ref = cutlass_torch.create_and_permute_torch_tensor(
                (batch_size,),
                torch.int32,
                init_type=cutlass.torch.TensorInitType.RANDOM,
                init_config=cutlass.torch.RandomInitConfig(
                    min_val=min_seq_len, max_val=max_seq_len + 1
                ),
            )
            cache_seqs_gpu = cache_seqs_ref.cuda()
            cache_seqs = from_dlpack(
                # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
                cache_seqs_gpu,
                assumed_align=16,
                use_32bit_stride=True,
            ).mark_layout_dynamic()
        return cache_seqs_ref, cache_seqs, cache_seqs_gpu

    def create_page_table(batch_size, seq_len, is_var_seq, use_page_table, page_size):
        page_table_ref, page_table, page_table_gpu = None, None, None
        if use_page_table:
            max_seq_len = seq_len if not is_var_seq else torch.max(cache_seqs_ref)
            page_count = ceil_div(max_seq_len, page_size)
            page_table_ref = torch.empty([batch_size, page_count], dtype=torch.int32)
            # use transposed index for page table to make sure the value is in bound of `batch_size * seq_len_block`. In practice, the value could be any positive values. This setting is only for testing purpose.
            for b in range(batch_size):
                for j in range(page_count):
                    page_table_ref[b, j] = b + j * batch_size
            page_table_gpu = page_table_ref.permute(1, 0).cuda()
            # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
            page_table = from_dlpack(
                page_table_gpu, assumed_align=16, use_32bit_stride=True
            ).mark_layout_dynamic(leading_dim=0)
        return page_table_ref, page_table, page_table_gpu

    def create_block_split_kvs(
        batch_size,
        split_kv,
        cache_seqs_ref,
        is_var_split_kv,
        mma_qk_tiler_mn,
        cluster_shape_mnk,
        max_active_clusters,
    ):
        block_split_kvs_ref, block_split_kvs, block_split_kvs_gpu = None, None, None
        # check if split_kv is valid otherwise do auto setting of split_kv
        if is_var_split_kv:
            block_split_kvs_ref = torch.zeros([batch_size], dtype=torch.int32)
            for b in range(batch_size):
                block_split_kvs_ref[b] = (
                    BlackwellMultiHeadLatentAttentionForward.get_split_kv(
                        batch_size,
                        cache_seqs_ref[b].item(),
                        mma_qk_tiler_mn,
                        max_active_clusters * cluster_shape_mnk[0],
                    )
                )
            split_kv = torch.max(block_split_kvs_ref).item()
            block_split_kvs_gpu = block_split_kvs_ref.cuda()
            # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
            block_split_kvs = from_dlpack(
                block_split_kvs_gpu, assumed_align=16, use_32bit_stride=True
            ).mark_layout_dynamic()
        elif split_kv <= 0:
            split_kv = BlackwellMultiHeadLatentAttentionForward.get_split_kv(
                batch_size,
                cache_seqs_ref[0].item(),
                mma_qk_tiler_mn,
                max_active_clusters * cluster_shape_mnk[0],
            )
        return split_kv, block_split_kvs_ref, block_split_kvs, block_split_kvs_gpu

    def create_workspace(num_heads, latent_dim, batch_size, split_kv, acc_dtype):
        workspace_size = BlackwellMultiHeadLatentAttentionForward.get_workspace_size(
            num_heads,
            latent_dim,
            batch_size,
            split_kv,
            acc_dtype,
        )

        workspace, workspace_torch = None, None
        if workspace_size > 0:
            workspace_torch = torch.empty([workspace_size], dtype=torch.int8).cuda()
            # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
            workspace = from_dlpack(
                workspace_torch, assumed_align=16, use_32bit_stride=True
            )
        return workspace, workspace_torch

    cache_seqs_ref, cache_seqs, cache_seqs_torch = create_cache_seqs(
        batch_size, seq_len, is_var_seq
    )
    page_table_ref, page_table, page_table_torch = create_page_table(
        batch_size, seq_len, is_var_seq, use_page_table, page_size
    )
    cluster_shape_mnk = (2, 1, 1)
    hardware_info = utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mnk[0] * cluster_shape_mnk[1]
    )
    split_kv, block_split_kvs_ref, block_split_kvs, block_split_kvs_torch = (
        create_block_split_kvs(
            batch_size,
            split_kv,
            cache_seqs_ref,
            is_var_split_kv,
            mma_qk_tiler_mn,
            cluster_shape_mnk,
            max_active_clusters,
        )
    )

    q_latent_ref, q_latent, q_latent_torch = create_data_tensor(
        batch_size,
        num_heads,
        latent_dim,
        in_dtype,
        is_dynamic_layout=True,
    )
    q_rope_ref, q_rope, q_rope_torch = create_data_tensor(
        batch_size,
        num_heads,
        rope_dim,
        in_dtype,
        is_dynamic_layout=True,
    )

    c_latent_ref, c_latent, c_latent_torch = create_data_tensor(
        batch_size,
        seq_len,
        latent_dim,
        in_dtype,
        is_dynamic_layout=True,
        page_table=page_table,
        cache_seqs=cache_seqs_ref,
    )
    c_rope_ref, c_rope, c_rope_torch = create_data_tensor(
        batch_size,
        seq_len,
        rope_dim,
        in_dtype,
        is_dynamic_layout=True,
        page_table=page_table,
        cache_seqs=cache_seqs_ref,
    )
    o_ref, o, o_torch = create_data_tensor(
        batch_size, num_heads, latent_dim, out_dtype, is_dynamic_layout=True
    )
    lse_ref, lse, lse_torch = create_data_tensor(
        batch_size, num_heads, 1, lse_dtype, is_dynamic_layout=True, is_lse=True
    )
    workspace, workspace_torch = create_workspace(
        num_heads, latent_dim, batch_size, split_kv, acc_dtype
    )

    mla = BlackwellMultiHeadLatentAttentionForward(
        acc_dtype,
        lse_dtype,
        mma_qk_tiler_mn,
        mma_pv_tiler_mn,
        max_active_clusters,
        is_persistent,
        is_cpasync,
        use_page_table,
        is_var_seq,
        is_var_split_kv,
    )

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    stream = cuda.CUstream(torch_stream.cuda_stream)

    # compile mla kernel
    compiled_mla = cute.compile(
        mla,
        q_latent,
        q_rope,
        c_latent,
        c_rope,
        page_table,
        o,
        lse,
        workspace,
        split_kv,
        cache_seqs,
        block_split_kvs,
        softmax_scale,
        output_scale,
        stream,
    )

    def torch_reference_mla(
        q_latent,
        q_rope,
        c_latent,
        c_rope,
        page_table,
        cache_seqs,
        softmax_scale=1.0,
        output_scale=1.0,
    ):
        # expand and concat q_latent and q_rope to have the dimension of sequence length for q
        q_ref = torch.cat([q_latent, q_rope], dim=1).permute(2, 0, 1).unsqueeze(2)
        # expand and concat c_latent and c_rope to have the dimension of num_heads for k and v
        if use_page_table:
            page_count = page_table_ref.shape[1]
            k_ref_paged = (
                torch.cat([c_latent, c_rope], dim=1)
                .permute(2, 0, 1)
                .reshape(batch_size * page_count, page_size, latent_dim + rope_dim)
            )
            v_ref_paged = c_latent.permute(2, 0, 1).reshape(
                batch_size * page_count, page_size, latent_dim
            )

            if is_var_seq:
                max_seq_len = torch.max(cache_seqs_ref)
            else:
                max_seq_len = seq_len

            k_ref = torch.zeros([batch_size, 1, max_seq_len, latent_dim + rope_dim])
            v_ref = torch.zeros([batch_size, 1, max_seq_len, latent_dim])
            k_ref = torch.index_select(
                k_ref_paged, 0, torch.flatten(page_table_ref)
            ).reshape(batch_size, 1, -1, latent_dim + rope_dim)[:, :, :max_seq_len, :]
            v_ref = torch.index_select(
                v_ref_paged, 0, torch.flatten(page_table_ref)
            ).reshape(batch_size, 1, -1, latent_dim)[:, :, :max_seq_len, :]
            for b in range(batch_size):
                k_ref[b, :, cache_seqs_ref[b] :, :] = 0
                v_ref[b, :, cache_seqs_ref[b] :, :] = 0
        else:
            k_ref = torch.cat([c_latent, c_rope], dim=1).permute(2, 0, 1).unsqueeze(1)
            v_ref = c_latent.permute(2, 0, 1).unsqueeze(1)

        o_ref = F.scaled_dot_product_attention(
            q_ref,
            k_ref,
            v_ref,
            attn_mask=None,
            dropout_p=0.0,
            scale=softmax_scale,
            is_causal=False,
        )
        s_ref = torch.einsum("bhld,bhsd->bhls", q_ref, k_ref)
        s_ref_max = torch.max(s_ref, dim=-1, keepdim=True).values
        softmax_scale_log2 = LOG2_E * softmax_scale
        s_ref_sum = torch.sum(
            torch.exp2((s_ref - s_ref_max) * softmax_scale_log2), dim=-1, keepdim=True
        )
        lse_ref = s_ref_max * softmax_scale_log2 + torch.log2(s_ref_sum)
        lse_ref = lse_ref.squeeze(3).squeeze(2).permute(1, 0)
        o_ref = o_ref * output_scale
        o_ref = o_ref.squeeze(2).permute(1, 2, 0)

        return o_ref, lse_ref

    if not skip_ref_check:
        # Execute kernel once for reference checking
        compiled_mla(
            q_latent,
            q_rope,
            c_latent,
            c_rope,
            page_table,
            o,
            lse,
            workspace,
            split_kv,
            cache_seqs,
            block_split_kvs,
            softmax_scale,
            output_scale,
            stream,
        )
        torch.cuda.synchronize()
        print("Verifying results...")
        if in_dtype == cutlass.Float8E4M3FN:
            tolerance = 0.13
        o_ref, lse_ref = torch_reference_mla(
            q_latent_ref,
            q_rope_ref,
            c_latent_ref,
            c_rope_ref,
            page_table,
            cache_seqs,
            softmax_scale,
            output_scale,
        )

        if out_dtype in [cutlass.Float8E5M2, cutlass.Float8E4M3FN]:
            # convert o back to f32 for comparison
            o_fp32, o_fp32_torch = cutlass_torch.cute_tensor_like(
                torch.empty(*o_torch.shape, dtype=torch.float32),
                cutlass.Float32,
                is_dynamic_layout=True,
                assumed_align=16,
            )
            cute.testing.convert(o, o_fp32)
            o = o_fp32_torch.cpu()
            ref_fp8, _ = cutlass_torch.cute_tensor_like(
                torch.empty(*o_ref.permute(2, 0, 1).shape, dtype=torch.uint8).permute(
                    1, 2, 0
                ),
                out_dtype,
                is_dynamic_layout=True,
                assumed_align=16,
            )
            o_ref_gpu = o_ref.cuda()
            # Set use_32bit_stride to True for small problem size(cosize(layout) <= Int32_max) for better performance.
            o_ref_f32 = from_dlpack(
                o_ref_gpu, use_32bit_stride=True
            ).mark_layout_dynamic(leading_dim=1)

            # convert ref : f32 -> fp8 -> f32
            cute.testing.convert(o_ref_f32, ref_fp8)
            cute.testing.convert(ref_fp8, o_ref_f32)

            o_ref = o_ref_gpu.cpu()
        else:
            o = o_torch.cpu().to(torch.float32)
        lse = lse_torch.cpu()
        lse_ref = lse_ref.to(cutlass.torch.dtype(lse_dtype))
        # Assert close results
        torch.testing.assert_close(o, o_ref, atol=tolerance, rtol=1e-05)
        torch.testing.assert_close(lse, lse_ref, atol=tolerance, rtol=1e-05)
        print("Results verified successfully!")

    def generate_tensors():
        _, cache_seqs, _ = create_cache_seqs(batch_size, seq_len, is_var_seq)
        _, page_table, _ = create_page_table(
            batch_size, seq_len, is_var_seq, use_page_table, page_size
        )
        _split_kv, _, block_split_kvs, _ = create_block_split_kvs(
            batch_size,
            split_kv,
            cache_seqs_ref,
            is_var_split_kv,
            mma_qk_tiler_mn,
            cluster_shape_mnk,
            max_active_clusters,
        )

        _, q_latent, _ = create_data_tensor(
            batch_size,
            num_heads,
            latent_dim,
            in_dtype,
            is_dynamic_layout=True,
        )
        _, q_rope, _ = create_data_tensor(
            batch_size,
            num_heads,
            rope_dim,
            in_dtype,
            is_dynamic_layout=True,
        )

        _, c_latent, _ = create_data_tensor(
            batch_size,
            seq_len,
            latent_dim,
            in_dtype,
            is_dynamic_layout=True,
            page_table=page_table,
            cache_seqs=cache_seqs_ref,
        )
        _, c_rope, _ = create_data_tensor(
            batch_size,
            seq_len,
            rope_dim,
            in_dtype,
            is_dynamic_layout=True,
            page_table=page_table,
            cache_seqs=cache_seqs_ref,
        )
        _, o, _ = create_data_tensor(
            batch_size, num_heads, latent_dim, out_dtype, is_dynamic_layout=True
        )
        _, lse, _ = create_data_tensor(
            batch_size, num_heads, 1, lse_dtype, is_dynamic_layout=True, is_lse=True
        )
        workspace, workspace_torch = create_workspace(
            num_heads, latent_dim, batch_size, _split_kv, acc_dtype
        )
        return testing.JitArguments(
            q_latent,
            q_rope,
            c_latent,
            c_rope,
            page_table,
            o,
            lse,
            workspace,
            _split_kv,
            cache_seqs,
            block_split_kvs,
            softmax_scale,
            output_scale,
            stream,
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            q_latent_torch.numel() * q_latent_torch.element_size()
            + q_rope_torch.numel() * q_rope_torch.element_size()
            + c_latent_torch.numel() * c_latent_torch.element_size()
            + c_rope_torch.numel() * c_rope_torch.element_size()
            + o_torch.numel() * o_torch.element_size()
            + lse_torch.numel() * lse_torch.element_size()
            + cache_seqs_torch.numel() * cache_seqs_torch.element_size()
        )
        if use_page_table:
            one_workspace_bytes += (
                page_table_torch.numel() * page_table_torch.element_size()
            )
        if is_var_split_kv:
            one_workspace_bytes += (
                block_split_kvs_torch.numel() * block_split_kvs_torch.element_size()
            )
        if workspace_torch is not None:
            one_workspace_bytes += (
                workspace_torch.numel() * workspace_torch.element_size()
            )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    avg_time_us = testing.benchmark(
        compiled_mla,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return avg_time_us  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_mma_tiler(s: str) -> Tuple[int, int, Tuple[int, int]]:
        ret = parse_comma_separated_ints(s)
        if len(ret) != 2:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected 2 comma-separated integers."
            )
        return (ret[0], ret[1])

    parser = argparse.ArgumentParser(description="Example of MLA on Blackwell.")

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Input data type",
    )

    parser.add_argument(
        "--out_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Output data type",
    )

    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="Accumulator data type",
    )

    parser.add_argument(
        "--lse_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="LSE data type",
    )
    parser.add_argument(
        "--mma_qk_tiler_mn",
        type=parse_mma_tiler,
        default=(128, 128),
        help="MMA tile shape (H, K)",
    )
    parser.add_argument(
        "--mma_pv_tiler_mn",
        type=parse_mma_tiler,
        default=(128, 256),
        help="MMA tile shape (H, D)",
    )

    parser.add_argument(
        "--is_persistent",
        action="store_true",
        help="Is persistent",
    )

    parser.add_argument(
        "--batch_size",
        type=int,
        default=1,
        help="Batch size",
    )

    parser.add_argument(
        "--seq_len",
        type=int,
        default=128,
        help="Sequence length of K/V",
    )

    parser.add_argument(
        "--num_heads",
        type=int,
        default=128,
        help="Number of heads of Q",
    )

    parser.add_argument(
        "--latent_dim",
        type=int,
        default=512,
        help="Latent dimension of Q/C",
    )

    parser.add_argument(
        "--rope_dim",
        type=int,
        default=64,
        help="Rope dimension of Q/C",
    )

    parser.add_argument(
        "--is_cpasync",
        action="store_true",
        help="Use cpasync for load or not",
    )

    parser.add_argument(
        "--is_var_seq",
        action="store_true",
        help="Use variable length of sequence length or not",
    )

    parser.add_argument(
        "--is_var_split_kv",
        action="store_true",
        help="Use variable length of split kv or not",
    )

    parser.add_argument(
        "--use_page_table",
        action="store_true",
        help="Use page table or not, must be True when is_cpasync is True",
    )

    parser.add_argument(
        "--page_size",
        type=int,
        default=128,
        help="Page size of page table",
    )

    parser.add_argument(
        "--split_kv",
        type=int,
        default=-1,
        help="Split KV setting",
    )

    parser.add_argument(
        "--softmax_scale",
        type=float,
        default=1.0,
        help="Scaling factor to scale softmax",
    )

    parser.add_argument(
        "--output_scale",
        type=float,
        default=1.0,
        help="Scaling factor to scale output",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-02, help="Tolerance for validation"
    )

    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of iterations for warmup",
    )

    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations after warmup",
    )

    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference check",
    )

    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        help="Use cold L2 cache",
    )

    args = parser.parse_args()

    run(
        args.batch_size,
        args.seq_len,
        args.num_heads,
        args.latent_dim,
        args.rope_dim,
        args.in_dtype,
        args.out_dtype,
        args.acc_dtype,
        args.lse_dtype,
        args.mma_qk_tiler_mn,
        args.mma_pv_tiler_mn,
        args.split_kv,
        args.is_persistent,
        args.is_cpasync,
        args.is_var_seq,
        args.is_var_split_kv,
        args.use_page_table,
        args.page_size,
        args.softmax_scale,
        args.output_scale,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )

    print("PASS")
