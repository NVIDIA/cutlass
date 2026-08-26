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
import argparse
import functools
from typing import Tuple, Type, Union, List, Optional

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
from cutlass.cute.nvgpu import cpasync
import cutlass.torch as cutlass_torch

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from rubin.kernel.grouped_gemm.grouped_gemm import (
    Sm107GroupedGemmKernel,
    create_tensors_for_all_groups,
    create_tensor_and_stride,
)


"""
A high-performance grouped GEMM example for the NVIDIA Rubin SM107 architecture with mixed cluster support.

This example provides an implementation of the SM107 grouped GEMM kernel with mixed cluster support.

The primary goal of this example, compared to the one in grouped_gemm.py,
is around the usage of mixed cluster launches: If there are not enough resources to schedule a cluster with
preferred_cluster_shape_mn, then a fallback_cluster_shape_mn is used.

.. code-block:: bash

    python examples/cute/rubin/kernel/grouped_gemm/grouped_gemm_mixed_clusters.py                   \\
        --num_groups 3                                                      \\
        --problem_sizes_mnkl "(128,128,128,1),(512,128,128,1),(128,256,128,1)" \\
        --a_dtype Float8E4M3FN --b_dtype Float8E4M3FN                      \\
        --c_dtype Float16 --acc_dtype Float32                              \\
        --mma_tiler 256,256,128 --mma_inst_shape 256,256,64                \\
        --preferred_cluster_shape_mn 2,2                                    \\
        --fallback_cluster_shape_mn 2,1                                     \\
        --use_2cta_instrs

Constraints:
* Supported input families are FP8, F16, BF16, FP32, and TF32
* Preferred cluster shape must be an integer multiple of fallback cluster shape
* Both cluster shapes must be valid for the MMA configuration
"""


class Sm107GroupedGemmMixedClustersKernel(Sm107GroupedGemmKernel):
    """Grouped GEMM kernel for Rubin with mixed cluster support.

    This class implements grouped matrix multiplication (C = A x B) with support for various data types
    and architectural features specific to Rubin GPUs with persistent tile scheduling and warp specialization.
    It extends the base kernel with mixed cluster launch capability, allowing the kernel to dynamically
    choose between a preferred cluster shape and a fallback cluster shape based on runtime resource availability.

    :param acc_dtype: Accumulator data type
    :type acc_dtype: Type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use 2CTA MMA instructions
    :type use_2cta_instrs: bool
    :param mma_tiler: MMA tile shape (M, N, K)
    :type mma_tiler: Tuple[int, int, int]
    :param mma_inst_shape: MMA instruction shape (M, N, K)
    :type mma_inst_shape: Tuple[int, int, int]
    :param preferred_cluster_shape_mn: Preferred cluster dimensions (M, N) for parallel processing
    :type preferred_cluster_shape_mn: Tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster dimensions (M, N) for parallel processing
    :type fallback_cluster_shape_mn: Tuple[int, int]
    :param tensormap_update_mode: Mode for updating the tensormap (GMEM or SMEM)
    :type tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode

    :note: Constraints:
        - Preferred cluster shape must be an integer multiple of fallback cluster shape
        - Both cluster shapes must be valid for the MMA configuration
        - See base class for additional constraints
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode = cutlass.tensor_utils.TensorMapUpdateMode.SMEM,
    ):
        """Initialize the Rubin grouped GEMM kernel with mixed cluster support.

        :param acc_dtype: Data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant
        :type use_2cta_instrs: bool
        :param mma_tiler: MMA tiler (M, N, K)
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: MMA instruction shape (M, N, K)
        :type mma_inst_shape: Tuple[int, int, int]
        :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param tensormap_update_mode: Mode for updating the tensormap (GMEM or SMEM), defaults to SMEM
        :type tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode, optional
        """
        # Call parent with preferred cluster shape
        super().__init__(
            acc_dtype,
            use_2cta_instrs,
            mma_tiler,
            mma_inst_shape,
            preferred_cluster_shape_mn,
            tensormap_update_mode,
        )

        # Store both cluster shapes
        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes for BOTH preferred and fallback clusters
        - Computing cluster layout for BOTH preferred and fallback clusters
        - Computing multicast CTAs for A/B for BOTH preferred and fallback clusters
        - Computing epilogue subtile
        - Setting up A/B/C stage counts in shared memory
        - Computing A/B/C shared memory layout
        - Computing tensor memory allocation columns
        """
        # Call parent to set up base attributes
        super()._setup_attributes()

        # Create tiled_mma for layout computation
        tiled_mma = self._create_tiled_mma()

        # Compute FALLBACK cluster layout
        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.fallback_cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B for FALLBACK
        self.num_fallback_mcast_ctas_a = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_fallback_mcast_ctas_b = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_fallback_a_mcast = self.num_fallback_mcast_ctas_a > 1
        self.is_fallback_b_mcast = self.num_fallback_mcast_ctas_b > 1

        # Rename parent's cluster_layout_vmnk to preferred_cluster_layout_vmnk
        self.preferred_cluster_layout_vmnk = self.cluster_layout_vmnk
        self.num_preferred_mcast_ctas_a = self.num_mcast_ctas_a
        self.num_preferred_mcast_ctas_b = self.num_mcast_ctas_b
        self.is_preferred_a_mcast = self.is_a_mcast
        self.is_preferred_b_mcast = self.is_b_mcast

    # GPU device kernel with preferred & fallback cluster sizes
    @cute.kernel
    def mixed_cluster_kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: Tuple[cute.CopyAtom, cute.CopyAtom],
        mA_mkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_b: Tuple[cute.CopyAtom, cute.CopyAtom],
        mB_nkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: Tuple[cute.Layout, cute.Layout],
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        tensormaps: cute.Tensor,
        tiled_mma_bkeep: Optional[cute.TiledMma] = None,
        tiled_mma_breuse: Optional[cute.TiledMma] = None,
    ):
        """
        GPU device kernel performing the grouped GEMM computation with mixed cluster support.

        This kernel implements mixed cluster shapes, meaning that it tries to launch with
        the preferred_cluster_shape_mn as its priority, but if at runtime, there is not enough
        resources available to do so, it then uses the fallback_cluster_shape_mn
        """

        # Get cluster coordinates to determine if this is a preferred cluster
        cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
        is_preferred_cluster = (
            cbdim_x == self.preferred_cluster_shape_mn[0]
            and cbdim_y == self.preferred_cluster_shape_mn[1]
            and cbdim_z == 1
        )

        # mega-kernel approach has 2 mutually exclusive code branches, only one path runs per launch,
        # specify `smem_merge_branch_allocs=True` at launch to enables shared memory reuse between two paths
        if is_preferred_cluster:
            self.kernel_impl(
                tiled_mma,
                tma_atom_a[0],
                mA_mkl[0],
                tma_atom_b[0],
                mB_nkl[0],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[0],
                a_smem_layout_staged,
                b_smem_layout_staged,
                epi_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                group_count,
                problem_sizes_mnkl,
                strides_abc,
                ptrs_abc,
                tensormaps,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                self.preferred_cluster_shape_mn,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
            )
        else:
            self.kernel_impl(
                tiled_mma,
                tma_atom_a[1],
                mA_mkl[1],
                tma_atom_b[1],
                mB_nkl[1],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[1],
                a_smem_layout_staged,
                b_smem_layout_staged,
                epi_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                group_count,
                problem_sizes_mnkl,
                strides_abc,
                ptrs_abc,
                tensormaps,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                self.fallback_cluster_shape_mn,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
            )

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        preferred_max_active_clusters: cutlass.Constexpr[int],
        fallback_max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        """Execute the grouped GEMM operation with mixed cluster support.

        :param initial_a: Initial tensor A
        :type initial_a: cute.Tensor
        :param initial_b: Initial tensor B
        :type initial_b: cute.Tensor
        :param initial_c: Initial tensor C
        :type initial_c: cute.Tensor
        :param group_count: Number of groups
        :type group_count: cutlass.Constexpr[int]
        :param problem_shape_mnkl: Problem shape tensor
        :type problem_shape_mnkl: cute.Tensor
        :param strides_abc: Strides tensor
        :type strides_abc: cute.Tensor
        :param tensor_address_abc: Tensor addresses
        :type tensor_address_abc: cute.Tensor
        :param total_num_clusters: Total number of clusters
        :type total_num_clusters: cutlass.Constexpr[int]
        :param tensormap_cute_tensor: Tensormap tensor
        :type tensormap_cute_tensor: cute.Tensor
        :param preferred_max_active_clusters: Maximum preferred active clusters
        :type preferred_max_active_clusters: cutlass.Constexpr[int]
        :param fallback_max_active_clusters: Maximum fallback active clusters
        :type fallback_max_active_clusters: cutlass.Constexpr[int]
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        """
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.c_dtype = initial_c.element_type
        self.enable_breuse = self.request_breuse and self.a_dtype in (
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        )

        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_c)

        tiled_mma = self._create_tiled_mma()
        # Create Bkeep-Breuse tiled_mma variants if enabled
        tiled_mma_bkeep = None
        tiled_mma_breuse = None
        if cutlass.const_expr(self.enable_breuse):
            tiled_mma_bkeep = self._create_tiled_mma_bkeep()
            tiled_mma_breuse = self._create_tiled_mma_breuse()

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A - PREFERRED
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.select(
            self.a_smem_layout_staged,
            mode=list(range(cute.rank(self.a_smem_layout_staged) - 1)),
        )

        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            initial_a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for A - FALLBACK
        a_op_fallback = utils.sm100.cluster_shape_to_tma_atom_A(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_tiled_tma_atom_A(
            a_op_fallback,
            initial_a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for B - PREFERRED
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.select(
            self.b_smem_layout_staged,
            mode=list(range(cute.rank(self.b_smem_layout_staged) - 1)),
        )
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            initial_b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for B - FALLBACK
        b_op_fallback = utils.sm100.cluster_shape_to_tma_atom_B(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_fallback,
            initial_b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        epi_smem_layout = cute.select(
            self.epi_smem_layout_staged,
            mode=list(range(cute.rank(self.epi_smem_layout_staged) - 1)),
        )
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            initial_c,
            epi_smem_layout,
            self.epi_tile,
        )

        # Compute grid size using preferred cluster shape
        self.tile_sched_params, grid = super()._compute_grid(
            total_num_clusters,
            self.preferred_cluster_shape_mn,
            preferred_max_active_clusters,
        )

        self.buffer_align_bytes = 1024
        self.size_tensormap_in_i64 = (
            0
            if self.tensormap_update_mode
            == cutlass.tensor_utils.TensorMapUpdateMode.GMEM
            else Sm107GroupedGemmKernel.num_tensormaps
            * Sm107GroupedGemmKernel.bytes_per_tensormap
            // 8
        )

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.epi_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel with mixed cluster support
        self.mixed_cluster_kernel(
            tiled_mma,
            (tma_atom_a, tma_atom_a_fallback),
            (tma_tensor_a, tma_tensor_a_fallback),
            (tma_atom_b, tma_atom_b_fallback),
            (tma_tensor_b, tma_tensor_b_fallback),
            tma_atom_c,
            tma_tensor_c,
            (self.preferred_cluster_layout_vmnk, self.fallback_cluster_layout_vmnk),
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensormap_cute_tensor,
            tiled_mma_bkeep,
            tiled_mma_breuse,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.preferred_cluster_shape_mn, 1),
            fallback_cluster=(*self.fallback_cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
            smem_merge_branch_allocs=True,
        )

    @staticmethod
    def can_implement(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
    ):
        """Check if the grouped gemm can be implemented with mixed clusters.

        :param problem_sizes_mnkl: List of problem sizes for each group
        :type problem_sizes_mnkl: List[Tuple[int, int, int, int]]
        :param a_dtype: Data type of tensor A
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Data type of tensor B
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: Data type of tensor C
        :type c_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator data type
        :type acc_dtype: Type[cutlass.Numeric]
        :param a_major: Major axis of tensor A
        :type a_major: str
        :param b_major: Major axis of tensor B
        :type b_major: str
        :param c_major: Major axis of tensor C
        :type c_major: str
        :param mma_tiler: MMA tiler shape
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: MMA instruction shape
        :type mma_inst_shape: Tuple[int, int, int]
        :param preferred_cluster_shape_mn: Preferred cluster shape
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback cluster shape
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param use_2cta_instrs: Whether to use 2CTA instructions
        :type use_2cta_instrs: bool
        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """
        try:
            # Check base implementation with preferred cluster
            if not Sm107GroupedGemmKernel.can_implement(
                problem_sizes_mnkl,
                a_dtype,
                b_dtype,
                c_dtype,
                acc_dtype,
                a_major,
                b_major,
                c_major,
                mma_tiler,
                mma_inst_shape,
                preferred_cluster_shape_mn,
                use_2cta_instrs,
            ):
                return False

            # Check fallback cluster is valid for 2CTA instructions if needed
            if fallback_cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
                raise testing.CantImplementError(
                    f"Invalid fallback cluster shape for 2CTA MMA, fallback_cluster_shape_m: {fallback_cluster_shape_mn[0]}"
                )

            # Check preferred is multiple of fallback
            if (
                preferred_cluster_shape_mn[0] % fallback_cluster_shape_mn[0] != 0
                or preferred_cluster_shape_mn[1] % fallback_cluster_shape_mn[1] != 0
            ):
                raise testing.CantImplementError(
                    f"Preferred cluster shape {preferred_cluster_shape_mn} must be "
                    f"integer multiple of fallback cluster shape {fallback_cluster_shape_mn}"
                )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """Run grouped GEMM example with mixed cluster support.

    :param num_groups: Number of groups
    :type num_groups: int
    :param problem_sizes_mnkl: Problem sizes for each group
    :type problem_sizes_mnkl: List[Tuple[int, int, int, int]]
    :param host_problem_shape_available: Whether problem shapes are available on host
    :type host_problem_shape_available: bool
    :param a_dtype: Data type of tensor A
    :type a_dtype: Type[cutlass.Numeric]
    :param b_dtype: Data type of tensor B
    :type b_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type of tensor C
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Major axis of tensor A
    :type a_major: str
    :param b_major: Major axis of tensor B
    :type b_major: str
    :param c_major: Major axis of tensor C
    :type c_major: str
    :param mma_tiler: MMA tiler shape
    :type mma_tiler: Tuple[int, int, int]
    :param mma_inst_shape: MMA instruction shape
    :type mma_inst_shape: Tuple[int, int, int]
    :param preferred_cluster_shape_mn: Preferred cluster shape
    :type preferred_cluster_shape_mn: Tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster shape
    :type fallback_cluster_shape_mn: Tuple[int, int]
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :type use_2cta_instrs: bool
    :param tensormap_update_mode: Tensormap update mode
    :type tensormap_update_mode: cutlass.tensor_utils.TensorMapUpdateMode
    :param tolerance: Tolerance for validation
    :type tolerance: float
    :param warmup_iterations: Number of warmup iterations
    :type warmup_iterations: int
    :param iterations: Number of iterations
    :type iterations: int
    :param skip_ref_check: Whether to skip reference checking
    :type skip_ref_check: bool
    :param use_cold_l2: Whether to use cold L2 cache, defaults to False
    :type use_cold_l2: bool, optional
    :param init_normal: Whether to use normal initialization, defaults to False
    :type init_normal: bool, optional
    :param normal_mean: Mean for normal initialization, defaults to 0.0
    :type normal_mean: float, optional
    :param normal_std: Standard deviation for normal initialization, defaults to 1.0
    :type normal_std: float, optional
    :return: Execution time of the GEMM kernel in microseconds
    :rtype: float
    """
    print("Running Rubin Grouped GEMM Mixed Clusters test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(
        f"Mma Tiler (M, N, K): {mma_tiler}, Mma Inst Shape (M, N, K): {mma_inst_shape}"
    )
    print(f"Preferred Cluster Shape (M, N): {preferred_cluster_shape_mn}")
    print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Tensor map update mode: {tensormap_update_mode}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    import torch

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch_tensors_abc = []
    torch_cpu_f32_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    # Run and verify with torch
    # create cpu tensors
    for group_idx, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        if a_major == "k":
            a_f32 = torch.empty((l, m, k), dtype=torch.float32).permute(1, 2, 0)
        elif a_major == "m":
            a_f32 = torch.empty((l, k, m), dtype=torch.float32).permute(2, 1, 0)
        if b_major == "k":
            b_f32 = torch.empty((l, n, k), dtype=torch.float32).permute(1, 2, 0)
        elif b_major == "n":
            b_f32 = torch.empty((l, k, n), dtype=torch.float32).permute(2, 1, 0)
        if c_major == "n":
            c_f32 = torch.empty((l, m, n), dtype=torch.float32).permute(1, 2, 0)
        elif c_major == "m":
            c_f32 = torch.empty((l, n, m), dtype=torch.float32).permute(2, 1, 0)

        # Initialize tensors with either normal distribution or random integers
        for tensor in [a_f32, b_f32, c_f32]:
            if init_normal:
                tensor.normal_(mean=normal_mean, std=normal_std)
            else:
                tensor.random_(-2, 3)

        torch_cpu_f32_tensors_abc.append([a_f32, b_f32, c_f32])

    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        _,
    ) = create_tensors_for_all_groups(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        torch_cpu_f32_tensors_abc,
    )

    # Setup initial tensors for TMA of A,B and C
    alignment = 16  # 16 bytes aligned
    min_ab_size = alignment * 8 // a_dtype.width
    min_c_size = alignment * 8 // c_dtype.width
    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]

    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    preferred_max_active_clusters = hardware_info.get_max_active_clusters(
        preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
    )
    fallback_max_active_clusters = hardware_info.get_max_active_clusters(
        fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
    )

    # Prepare tensormap buffer for each SM
    num_tensormap_buffers = sm_count
    tensormap_shape = (
        num_tensormap_buffers,
        Sm107GroupedGemmKernel.num_tensormaps,
        Sm107GroupedGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_gemm = Sm107GroupedGemmMixedClustersKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        mma_inst_shape,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        tensormap_update_mode,
    )

    print(f"problem_sizes_mnkl: {problem_sizes_mnkl}")

    # Check if configuration can be implemented
    if not Sm107GroupedGemmMixedClustersKernel.can_implement(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        mma_inst_shape,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        use_2cta_instrs,
    ):
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, mma_inst_shape = {mma_inst_shape}, "
            f"preferred_cluster_shape_mn = {preferred_cluster_shape_mn}, "
            f"fallback_cluster_shape_mn = {fallback_cluster_shape_mn}, "
            f"tensormap_update_mode = {tensormap_update_mode}"
        )

    # layout (num_groups, 4):(4, 1)
    tensor_of_dim_size_mnkl, tensor_of_dim_size_mnkl_torch = (
        cutlass_torch.cute_tensor_like(
            torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )
    )

    # layout (num_groups, 3, 2):(6, 2, 1)
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,3):(3, 1)
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # Compute total number of cluster tiles we need to compute for given grouped GEMM problem
    def compute_total_num_clusters(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        cluster_tile_shape_mn: Tuple[int, int],
    ) -> int:
        total_num_clusters = 0
        for m, n, _, _ in problem_sizes_mnkl:
            num_clusters_mn = tuple(
                (x + y - 1) // y for x, y in zip((m, n), cluster_tile_shape_mn)
            )
            total_num_clusters += functools.reduce(lambda x, y: x * y, num_clusters_mn)
        return total_num_clusters

    # Compute cluster tile shape
    def compute_cluster_tile_shape(
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
    ) -> Tuple[int, int]:
        cta_tile_shape_mn = list(mma_tiler)[0:2]
        if use_2cta_instrs:
            cta_tile_shape_mn[0] = cta_tile_shape_mn[0] // 2
        return tuple(x * y for x, y in zip(cta_tile_shape_mn, cluster_shape_mn))

    preferred_cluster_tile_shape_mn = compute_cluster_tile_shape(
        mma_tiler, preferred_cluster_shape_mn, use_2cta_instrs
    )

    # If the host problem shape is available, we will launch the grid with only
    # the necessary clusters. The function compute_total_num_clusters() does that.
    # If the problem shape only exists on device, we will need to launch all active
    # clusters possible on a device.
    if host_problem_shape_available:
        print("Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, preferred_cluster_tile_shape_mn
        )
    else:
        print("Problem shapes available only on device")
        total_num_clusters = preferred_max_active_clusters

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    # Compile grouped GEMM kernel
    compiled_grouped_gemm = cute.compile(
        grouped_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        total_num_clusters,
        tensor_of_tensormap,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        current_stream,
    )

    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_tensormap,
            current_stream,
        )

        # Compute reference result
        for group_idx, (a, b, c) in enumerate(torch_tensors_abc):
            ref = torch.einsum(
                "mkl,nkl->mnl",
                torch_cpu_f32_tensors_abc[group_idx][0].cpu(),
                torch_cpu_f32_tensors_abc[group_idx][1].cpu(),
            )

            print(f"group {group_idx}:")

            torch.testing.assert_close(
                c.cpu(),
                ref.to(cutlass_torch.dtype(c_dtype)),
                atol=tolerance,
                rtol=1e-05,
            )

    if iterations <= 0:
        return 0

    def generate_tensors():
        # Reuse existing CPU tensors and create new GPU tensors from them
        (
            ptrs_abc_workspace,
            torch_tensors_abc_workspace,
            cute_tensors_abc_workspace,
            strides_abc_workspace,
            _,
        ) = create_tensors_for_all_groups(
            problem_sizes_mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            torch_cpu_f32_tensors_abc,
        )

        initial_cute_tensors_abc_workspace = [
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, a_major == "m", a_dtype
            )[2],
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, b_major == "n", b_dtype
            )[2],
            create_tensor_and_stride(
                1, min_c_size, min_c_size, c_major == "m", c_dtype
            )[2],
        ]

        # Create new tensors for this workspace
        tensor_of_strides_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_workspace, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensormap_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.empty(total_num_clusters, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )

        args = testing.JitArguments(
            initial_cute_tensors_abc_workspace[0],
            initial_cute_tensors_abc_workspace[1],
            initial_cute_tensors_abc_workspace[2],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc_workspace,
            tensor_of_ptrs_abc_workspace,
            tensormap_workspace,
            current_stream,
        )
        args.add_to_scope([torch_tensors_abc_workspace])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                [
                    sum(
                        [
                            torch_tensor.numel() * torch_tensor.element_size()
                            for torch_tensor in group_tensors
                        ]
                    )
                    for group_tensors in torch_tensors_abc
                ]
            )
            +
            # Add size of strides tensor
            tensor_of_strides_abc_torch.numel()
            * tensor_of_strides_abc_torch.element_size()
            +
            # Add size of ptrs tensor
            tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            +
            # Add size of tensormap tensor
            tensor_of_tensormap_torch.numel() * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_comma_separated_tuples(s: str) -> List[Tuple[int, ...]]:
        if s.strip().startswith("("):
            # Split on ),( to separate tuples
            tuples = s.strip("()").split("),(")
            result = []
            tuple_len = None

            for t in tuples:
                # Parse individual tuple
                nums = [int(x.strip()) for x in t.split(",")]

                # Validate tuple length consistency
                if tuple_len is None:
                    tuple_len = len(nums)
                elif len(nums) != tuple_len:
                    raise argparse.ArgumentTypeError(
                        "All tuples must have the same length"
                    )

                result.append(tuple(nums))
            return result

        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers or list of tuples"
        )

    parser = argparse.ArgumentParser(
        description="Example of Grouped GEMM with Mixed Clusters on Rubin."
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=3,
        help="Number of groups",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=((128, 128, 128, 1), (512, 128, 128, 1), (128, 256, 128, 1)),
        help="a tuple of problem sizes for each group (comma-separated tuples)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Enable the compute of grid based upon host problem shape",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma inst shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 2),
        help="Preferred cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 1),
        help="Fallback cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--tensormap_update_mode",
        type=str,
        default="SMEM",
        help="Tensor map update mode",
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Data type of the A tensor",
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Data type of the B tensor",
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Data type of the C tensor",
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="Data type of the accumulator tensor",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal distribution for tensor initialization instead of random integers",
    )
    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean for normal distribution initialization",
    )
    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation for normal distribution initialization",
    )

    args = parser.parse_args()

    if (
        len(args.problem_sizes_mnkl) != 0
        and len(args.problem_sizes_mnkl) != args.num_groups
    ):
        parser.error("--problem_sizes_mnkl must contain exactly num_groups tuples")

    # l mode must be 1 for all groups
    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l must be 1 for all groups")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    if len(args.preferred_cluster_shape_mn) != 2:
        parser.error("--preferred_cluster_shape_mn must contain exactly 2 values")

    if len(args.fallback_cluster_shape_mn) != 2:
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    if args.tensormap_update_mode not in ["GMEM", "SMEM"]:
        parser.error("--tensormap_update_mode must be GMEM or SMEM")

    if args.tensormap_update_mode == "GMEM":
        tensormap_update_mode = cutlass.tensor_utils.TensorMapUpdateMode.GMEM
    else:
        tensormap_update_mode = cutlass.tensor_utils.TensorMapUpdateMode.SMEM

    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.host_problem_shape_available,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler,
        args.mma_inst_shape,
        args.preferred_cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.use_2cta_instrs,
        tensormap_update_mode,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
