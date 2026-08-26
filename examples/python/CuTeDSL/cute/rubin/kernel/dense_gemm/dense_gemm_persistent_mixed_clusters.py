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
from typing import Optional, Tuple, Type, Union, Literal
from functools import lru_cache

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.utils as utils
from cutlass.utils import create_cute_tensor_for_fp8
from cutlass.cute.nvgpu import cpasync

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))
    # dense_gemm_persistent.py imports from `helpers`, which lives at CuTeDSL/ (one level
    # above cute/). That import runs when this file is the __main__ entry point because
    # dense_gemm_persistent.py's own __main__ guard never fires in that case.
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))

from rubin.kernel.dense_gemm.dense_gemm_persistent import (
    SM107PersistentDenseGemmKernel,
    prepare_tensors,
)


"""
This example provides an implementation of the SM107 batched dense GEMM kernel with mixed cluster support.

The primary goal of this example, compared to the one in dense_gemm_persistent.py,
is around the usage of mixed cluster launches: If there are not enough resources to schedule a cluster with
preferred_cluster_shape_mn, then a fallback_cluster_shape_mn is used.

A high-performance persistent batched dense GEMM example for the NVIDIA Rubin SM107 architecture
using CuTe DSL.

.. code-block:: bash

    python examples/cute/rubin/kernel/dense_gemm/dense_gemm_persistent_mixed_clusters.py              \\
        --a_dtype Float8E4M3FN --b_dtype Float8E5M2                             \\
        --c_dtype Float16 --acc_dtype Float32                                   \\
        --mma_tiler 512,256,128 --mma_inst_shape 256,256,64                     \\
        --preferred_cluster_shape_mn 4,2                                        \\
        --fallback_cluster_shape_mn 2,1                                         \\
        --mnkl 8192,8192,8192,1                                                 \\
        --use_tma_store --use_2cta_instrs

Additional constraints:
- Supported A/B input types: Float16, BFloat16, TFloat32, Float8E4M3FN, Float8E5M2
- Bkeep-Breuse pattern (mma_tiler[0] == 2 * mma_inst_shape[0]) is only supported for FP8 inputs
- mma_inst_shape K=64 (FP8 only): M in the MMA tiler must be 128 (1 CTA) or 256 (2 CTAs)
- mma_inst_shape K=32 (FP8 only): same M constraints as Blackwell
- mma_inst_shape K=16 (Float16/BFloat16): same M constraints as Blackwell
- mma_inst_shape K=8 (TFloat32): same M constraints as Blackwell
- Preferred cluster shape must be an integer multiple of fallback cluster shape
"""


class SM107PersistentDenseGemmMixedClustersKernel(SM107PersistentDenseGemmKernel):
    """Persistent dense GEMM kernel for Rubin with mixed cluster support.

    This class implements batched matrix multiplication (C = A x B) with support for various data types
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
    :param use_tma_store: Whether to use TMA store
    :type use_tma_store: bool
    :param swizzle_size: Swizzling size in the unit of cluster for improving L2 cache hit rate
    :type swizzle_size: int
    :param raster_along: Rasterization order of clusters ('m' or 'n')
    :type raster_along: Literal["m", "n"]

    :note: Constraints:
        - Preferred cluster shape must be an integer multiple of fallback cluster shape
        - Both cluster shapes must be valid for the MMA configuration
        - See base class for additional constraints

    Example:
        >>> gemm = SM107PersistentDenseGemmMixedClustersKernel(
        ...     acc_dtype=cutlass.Float32,
        ...     use_2cta_instrs=True,
        ...     mma_tiler=(256, 128, 128),
        ...     mma_inst_shape=(256, 128, 64),
        ...     preferred_cluster_shape_mn=(4, 2),
        ...     fallback_cluster_shape_mn=(2, 1),
        ...     use_tma_store=True,
        ...     swizzle_size=1,
        ...     raster_along="m"
        ... )
        >>> compiled_gemm = cute.compile(
        ...     gemm,
        ...     a_tensor,
        ...     b_tensor,
        ...     c_tensor,
        ...     preferred_max_active_clusters,
        ...     fallback_max_active_clusters,
        ...     stream,
        ...     epilogue_op
        ... )
        >>> compiled_gemm(
        ...     a_tensor,
        ...     b_tensor,
        ...     c_tensor,
        ...     stream
        ... )
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        swizzle_size: int = 1,
        raster_along: Literal["m", "n"] = "m",
    ):
        """Initialize the Rubin persistent dense GEMM kernel with mixed cluster support.

        :param acc_dtype: Accumulator data type
        :type acc_dtype: Type[cutlass.Numeric]
        :param use_2cta_instrs: Whether to use 2CTA MMA instructions
        :type use_2cta_instrs: bool
        :param mma_tiler: MMA tiler (M, N, K)
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: MMA instruction shape (M, N, K)
        :type mma_inst_shape: Tuple[int, int, int]
        :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param use_tma_store: Whether to use TMA store
        :type use_tma_store: bool
        :param swizzle_size: Swizzle size
        :type swizzle_size: int
        :param raster_along: Raster along dimension ('m' or 'n')
        :type raster_along: Literal["m", "n"]
        """
        # Call parent with preferred cluster shape
        super().__init__(
            acc_dtype,
            use_2cta_instrs,
            mma_tiler,
            mma_inst_shape,
            preferred_cluster_shape_mn,
            use_tma_store,
            swizzle_size,
            raster_along,
        )

        # Store both cluster shapes
        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Delegating base setup (tiled MMA, MMA/cluster/tile shapes, epilogue subtile,
          A/B/C smem layouts, TMEM columns) to the parent class
        - Computing cluster layout for the FALLBACK cluster
        - Computing multicast CTAs for A/B for the FALLBACK cluster
        - Aliasing parent's cluster_layout_vmnk / mcast attributes as preferred_*
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
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: Tuple[cute.Layout, cute.Layout],
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
        tiled_mma_bkeep: Optional[cute.TiledMma] = None,
        tiled_mma_breuse: Optional[cute.TiledMma] = None,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation with mixed cluster support.

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
                c_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                epilogue_op,
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
                c_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                epilogue_op,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                self.fallback_cluster_shape_mn,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
            )

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_along: Literal["m", "n"],
        preferred_max_active_clusters: cutlass.Constexpr,
        fallback_max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[
        utils.PersistentTileSchedulerParams,
        Tuple[int, int, int],
    ]:
        """Use persistent tile scheduler to compute the grid size for the output tensor C.

        :param c: The output tensor C
        :type c: cute.Tensor
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param preferred_cluster_shape_mn: Preferred shape of each cluster in M, N dimensions
        :type preferred_cluster_shape_mn: tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback shape of each cluster in M, N dimensions
        :type fallback_cluster_shape_mn: tuple[int, int]
        :param swizzle_size: Swizzling size in the unit of cluster for improving L2 cache hit rate
        :type swizzle_size: int
        :param raster_along: Rasterization order of clusters ('m' or 'n')
        :type raster_along: Literal["m", "n"]
        :param preferred_max_active_clusters: Maximum number of preferred active clusters
        :type preferred_max_active_clusters: cutlass.Constexpr
        :param fallback_max_active_clusters: Maximum number of fallback active clusters
        :type fallback_max_active_clusters: cutlass.Constexpr

        :return: A tuple containing:
            - preferred_tile_sched_params: Parameters for the preferred persistent tile scheduler
            - grid: Grid shape for kernel launch
        :rtype: Tuple[
            utils.PersistentTileSchedulerParams,
            tuple[int, int, int]
        ]
        """
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape

        # Tile scheduler and grid shape for the preferred cluster
        preferred_cluster_shape_mnl = (*preferred_cluster_shape_mn, 1)

        preferred_tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, preferred_cluster_shape_mnl
        )
        preferred_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            preferred_tile_sched_params, preferred_max_active_clusters
        )

        # Tile scheduler and grid shape for the fallback cluster
        fallback_cluster_shape_mnl = (*fallback_cluster_shape_mn, 1)

        fallback_tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, fallback_cluster_shape_mnl
        )
        fallback_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            fallback_tile_sched_params, fallback_max_active_clusters
        )

        # Align preferred grid to cluster shape
        preferred_grid = cute.round_up(preferred_grid, preferred_cluster_shape_mnl)

        # Compute max preferred clusters: total blocks <= fallback total,
        # and is multiple of cluster size
        preferred_cluster_size_mn = (
            preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
        )
        max_ctas_for_fallback_cluster = (
            fallback_grid[0] * fallback_grid[1] * fallback_grid[2]
        )

        # Use floor division (not ceil_div) to compute max preferred cluster count.
        # The preferred cluster total CTA count must not exceed the fallback total,
        # otherwise when the division is not exact, the extra partial wave of
        # preferred clusters may force the hardware to schedule one additional wave,
        # causing significant performance regression.
        max_preferred_cluster_count = (
            max_ctas_for_fallback_cluster // preferred_cluster_size_mn
        )
        preferred_grid = (
            preferred_grid[0],
            preferred_grid[1],
            max_preferred_cluster_count,
        )

        return (
            preferred_tile_sched_params,
            preferred_grid,
        )

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """
        Check if the gemm can be implemented with mixed clusters

        :param mnkl: The problem size as a tuple (M, N, K, L)
        :type mnkl: Tuple[int, int, int, int]
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major axis of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major axis of the C tensor
        :type c_major: Literal["m", "n"]
        :param mma_tiler: The (M, N, K) shape of the MMA tiler
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: The (M, N, K) shape of the MMA instruction
        :type mma_inst_shape: Tuple[int, int, int]
        :param preferred_cluster_shape_mn: The (ClusterM, ClusterN) shape of the preferred CTA cluster
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: The (ClusterM, ClusterN) shape of the fallback CTA cluster
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """

        try:
            # Create a temporary kernel object to check base implementation
            temp_kernel = SM107PersistentDenseGemmKernel(
                acc_dtype=acc_dtype,
                use_2cta_instrs=(mma_inst_shape[0] > 128),
                mma_tiler=mma_tiler,
                mma_inst_shape=mma_inst_shape,
                cluster_shape_mn=preferred_cluster_shape_mn,
                use_tma_store=True,
            )

            # Check base implementation with preferred cluster
            if not temp_kernel.can_implement(
                mnkl,
                a_dtype,
                b_dtype,
                c_dtype,
                a_major,
                b_major,
                c_major,
            ):
                return False

            # Check fallback cluster is valid for 2CTA instructions if needed
            if (
                fallback_cluster_shape_mn[0] % (2 if mma_inst_shape[0] == 256 else 1)
                != 0
            ):
                raise testing.CantImplementError(
                    f"Invalid fallback cluster shape for a 2CTA MMA, fallback_cluster_shape_m: {fallback_cluster_shape_mn[0]}"
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

            # Check that the problem is at least as large as the preferred cluster tile.
            # The mixed clusters kernel computes max_preferred_cluster_count as:
            #   max_ctas_for_fallback_cluster // preferred_cluster_size_mn
            # If the problem is smaller than one preferred cluster tile, this count
            # becomes zero, resulting in an invalid grid shape.
            m, n, k, l = mnkl
            preferred_tile_m = mma_tiler[0] * preferred_cluster_shape_mn[0]
            preferred_tile_n = mma_tiler[1] * preferred_cluster_shape_mn[1]
            if m < preferred_tile_m or n < preferred_tile_n:
                raise testing.CantImplementError(
                    f"Problem size ({m}, {n}) is smaller than the preferred cluster tile "
                    f"({preferred_tile_m}, {preferred_tile_n})"
                )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        preferred_max_active_clusters: cutlass.Constexpr,
        fallback_max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute the GEMM operation with mixed cluster support in steps:
        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors for BOTH preferred and fallback clusters
        - Compute grid size with regard to hardware constraints
        - Launch the kernel synchronously

        :param a: Input tensor A
        :type a: cute.Tensor
        :param b: Input tensor B
        :type b: cute.Tensor
        :param c: Output tensor C
        :type c: cute.Tensor
        :param preferred_max_active_clusters: Maximum number of preferred active clusters
        :type preferred_max_active_clusters: cutlass.Constexpr
        :param fallback_max_active_clusters: Maximum number of fallback active clusters
        :type fallback_max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        :param epilogue_op: Optional elementwise lambda function to apply to the output tensor
        :type epilogue_op: cutlass.Constexpr
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        """

        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        self.c_dtype: Type[cutlass.Numeric] = c.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)

        # This override does not call the base __call__, so initialize the
        # runtime Bkeep-Breuse state before creating tiled MMA objects.
        self.enable_breuse = self._is_breuse_requested(
            self.mma_tiler, self.mma_inst_shape
        ) and self._is_breuse_supported(self.a_dtype, self.b_dtype)

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
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for A - FALLBACK
        a_op_fallback = utils.sm100.cluster_shape_to_tma_atom_A(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_tiled_tma_atom_A(
            a_op_fallback,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
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
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for B - FALLBACK
        b_op_fallback = utils.sm100.cluster_shape_to_tma_atom_B(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_fallback,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), c, epi_smem_layout, self.epi_tile
            )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.preferred_cluster_shape_mn,
            self.fallback_cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
            preferred_max_active_clusters,
            fallback_max_active_clusters,
        )

        # Launch the kernel synchronously with mixed cluster support
        self.mixed_cluster_kernel(
            tiled_mma,
            (tma_atom_a, tma_atom_a_fallback),
            (tma_tensor_a, tma_tensor_a_fallback),
            (tma_atom_b, tma_atom_b_fallback),
            (tma_tensor_b, tma_tensor_b_fallback),
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            (self.preferred_cluster_layout_vmnk, self.fallback_cluster_layout_vmnk),
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            epilogue_op,
            tiled_mma_bkeep,
            tiled_mma_breuse,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.preferred_cluster_shape_mn, 1),
            fallback_cluster=(*self.fallback_cluster_shape_mn, 1),
            stream=stream,
            smem_merge_branch_allocs=True,
        )


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    preferred_max_active_clusters: cutlass.Constexpr,
    fallback_max_active_clusters: cutlass.Constexpr,
    stream: cuda.CUstream,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Wrapper API for persistent GEMM kernel to follow the convention of PyTorch's batch matrix-multiply (bmm).

    Internally, the tensors are permuted to match CuTe's convention:
      - a: (m, k, l)
      - b: (n, k, l)
      - c: (m, n, l)

    :param gemm_op: Kernel operation, expects (a, b, c, preferred_max_active_clusters, fallback_max_active_clusters, stream, epilogue_op)
    :type gemm_op: cutlass.Constexpr
    :param a: Input tensor of shape (l, m, k)
    :type a: cute.Tensor
    :param b: Input tensor of shape (l, k, n)
    :type b: cute.Tensor
    :param c: Output tensor of shape (l, m, n)
    :type c: cute.Tensor
    :param preferred_max_active_clusters: Maximum number of preferred active clusters to launch
    :type preferred_max_active_clusters: cutlass.Constexpr
    :param fallback_max_active_clusters: Maximum number of fallback active clusters to launch
    :type fallback_max_active_clusters: cutlass.Constexpr
    :param epilogue_op: Optional elementwise lambda function to apply per output element, defaults to identity
    :type epilogue_op: cutlass.Constexpr, optional
    """
    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(
        a,
        b,
        c,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        stream,
        epilogue_op,
    )


@lru_cache(maxsize=1)
def compile_bmm(
    mnkl: Tuple[int, int, int, int],
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int] = (256, 256, 128),
    mma_inst_shape: Tuple[int, int, int] = (256, 256, 64),
    preferred_cluster_shape_mn: Tuple[int, int] = (4, 2),
    fallback_cluster_shape_mn: Tuple[int, int] = (2, 1),
    preferred_max_active_clusters: cutlass.Constexpr = None,
    fallback_max_active_clusters: cutlass.Constexpr = None,
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Compile a batched matrix multiplication kernel for Rubin with mixed cluster support.

    :param mnkl: Problem dimensions (M, N, K, L)
    :param a: Input tensor A
    :param b: Input tensor B
    :param c: Output tensor C
    :param acc_dtype: Accumulator data type
    :param a_major: Major dimension of A ("k" or "m")
    :param b_major: Major dimension of B ("k" or "n")
    :param c_major: Major dimension of C ("n" or "m")
    :param mma_tiler: MMA tile shape (M, N, K)
    :param mma_inst_shape: MMA instruction shape (M, N, K)
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
    :param preferred_max_active_clusters: Maximum preferred active clusters
    :param fallback_max_active_clusters: Maximum fallback active clusters
    :param use_2cta_instrs: Use 2CTA instructions
    :param use_tma_store: Use TMA store
    :param swizzle_size: Swizzle size
    :param raster_along: Raster along dimension ("m" or "n")
    :param epilogue_op: Epilogue operation
    :return: Compiled kernel function
    """
    from cutlass.cute.runtime import make_fake_stream

    # Build GEMM object
    gemm = SM107PersistentDenseGemmMixedClustersKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        mma_inst_shape,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        use_tma_store,
        swizzle_size,
        raster_along,
    )

    # Check if configuration can be implemented
    can_implement = gemm.can_implement(
        mnkl,
        a.element_type,
        b.element_type,
        c.element_type,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        mma_inst_shape,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
    )

    if not can_implement:
        raise testing.CantImplementError(
            f"The current config which is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, mma_inst_shape = {mma_inst_shape}, "
            f"preferred_cluster_shape_mn = {preferred_cluster_shape_mn}, "
            f"fallback_cluster_shape_mn = {fallback_cluster_shape_mn}, "
            f"use_tma_store = {use_tma_store}, "
            f"swizzle_size = {swizzle_size}, "
            f"raster_along = {raster_along}"
        )

    stream = make_fake_stream()
    return cute.compile(
        bmm,
        gemm,
        a,
        b,
        c,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        stream,
        epilogue_op,
    )


def run(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int] = (256, 256, 128),
    mma_inst_shape: Tuple[int, int, int] = (256, 256, 64),
    preferred_cluster_shape_mn: Tuple[int, int] = (4, 2),
    fallback_cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    benchmark: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """
    Execute a persistent batched dense GEMM operation on Rubin architecture with mixed cluster support and performance benchmarking.

    Prepares input tensors, configures and launches the persistent GEMM kernel with mixed cluster support,
    optionally performs reference validation, and benchmarks execution.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: Tuple[int, int, int, int]
    :param a_dtype: Data type for input tensor A.
    :type a_dtype: Type[cutlass.Numeric]
    :param b_dtype: Data type for input tensor B.
    :type b_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type for the matrix multiplication.
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Memory layout of tensor A.
    :type a_major: str
    :param b_major: Memory layout of tensor B.
    :type b_major: str
    :param c_major: Memory layout of tensor C.
    :type c_major: str
    :param mma_tiler: MMA tiling size (M, N, K), defaults to (256, 256, 128).
    :type mma_tiler: Tuple[int, int, int], optional
    :param mma_inst_shape: MMA instruction shape (M, N, K), defaults to (256, 256, 64).
    :type mma_inst_shape: Tuple[int, int, int], optional
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N), defaults to (4, 2).
    :type preferred_cluster_shape_mn: Tuple[int, int], optional
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N), defaults to (2, 1).
    :type fallback_cluster_shape_mn: Tuple[int, int], optional
    :param swizzle_size: Swizzling size in the unit of cluster for improving L2 cache hit rate, defaults to 1.
    :type swizzle_size: int, optional
    :param raster_along: Rasterization order of clusters ('m' or 'n'), defaults to 'm'.
    :type raster_along: Literal["m", "n"], optional
    :param use_2cta_instrs: Whether to use 2CTA MMA instructions, defaults to True.
    :type use_2cta_instrs: bool, optional
    :param use_tma_store: Whether to use TMA store, defaults to True.
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance for reference validation, defaults to 1e-01.
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 0.
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 1.
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference result validation, defaults to False.
    :type skip_ref_check: bool, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False.
    :type use_cold_l2: bool, optional
    :param benchmark: Whether to only benchmark the kernel, defaults to False.
    :type benchmark: bool, optional
    :param init_normal: Whether to use normal (Gaussian) initialization for tensors, defaults to False.
        When True, tensors are initialized with normal distribution N(normal_mean, normal_std).
    :type init_normal: bool, optional
    :param normal_mean: Mean of the normal distribution for initialization, defaults to 0.0.
    :type normal_mean: float, optional
    :param normal_std: Standard deviation of the normal distribution for initialization, defaults to 1.0.
    :type normal_std: float, optional
    :raises RuntimeError: If CUDA GPU is not available.
    :raises ValueError: If the configuration is invalid or unsupported by the kernel.
    :return: Execution time of the GEMM kernel.
    :rtype: float
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Check if configuration can be implemented
    preferred_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
    )
    fallback_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
    )

    # Run and verify BMM with torch
    a_f32, b_f32, c_f32, a_storage, b_storage, c_storage = prepare_tensors(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        init_random=not init_normal,
        normal_mean=normal_mean,
        normal_std=normal_std,
    )

    leading_dim_a = 2 if a_major == "k" else 1
    leading_dim_b = 1 if b_major == "k" else 2
    leading_dim_c = 2 if c_major == "n" else 1

    # Create CuTe tensors, passing float32 source for fp8 conversion
    a_ = create_cute_tensor_for_fp8(
        a_storage, a_dtype, leading_dim_a, source_f32_tensor=a_f32
    )
    b_ = create_cute_tensor_for_fp8(
        b_storage, b_dtype, leading_dim_b, source_f32_tensor=b_f32
    )
    c_ = create_cute_tensor_for_fp8(
        c_storage, c_dtype, leading_dim_c, source_f32_tensor=c_f32
    )

    compiled_fn = compile_bmm(
        mnkl,
        a_,
        b_,
        c_,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        mma_inst_shape,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        use_2cta_instrs,
        use_tma_store,
        swizzle_size,
        raster_along,
        epilogue_op=lambda x: x,
    )

    print("Running Rubin Persistent Dense GEMM Mixed Clusters test with:")
    print(f"mnkl: {mnkl}")
    print(f"Mma Tiler (M, N, K): {mma_tiler}")
    print(f"Mma Instruction Shape (M, N, K): {mma_inst_shape}")
    print(f"Preferred Cluster Shape (M, N): {preferred_cluster_shape_mn}")
    print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Use 2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Use TMA Store: {'True' if use_tma_store else 'False'}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(f"Swizzle Size: {swizzle_size}")
    print(f"Raster Along: {raster_along}")

    if not skip_ref_check:
        # Use small random number for deterministic result for reference check
        compiled_fn(a_, b_, c_, current_stream)

        # Manually quantize to be comparable
        # Use float32 source data for reference calculation
        ref = (
            torch.bmm(a_f32, b_f32)
            .to(dtype=torch_dtype(c_dtype))
            .to(dtype=torch.float32)
        )
        torch.testing.assert_close(
            c_storage.view(torch_dtype(c_dtype)).to(dtype=torch.float32),
            ref,
            atol=tolerance,
            rtol=1e-03,
        )

    if not benchmark:
        return 0

    def generate_tensors():
        # Use init_normal from outer scope, but force random init for Int8/Uint8 types
        use_normal_init = init_normal and (
            a_dtype not in [cutlass.Int8, cutlass.Uint8]
            and b_dtype not in [cutlass.Int8, cutlass.Uint8]
        )
        a_f32, b_f32, c_f32, a_st, b_st, c_st = prepare_tensors(
            mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_random=not use_normal_init,
            normal_mean=normal_mean,
            normal_std=normal_std,
        )

        a_ = create_cute_tensor_for_fp8(
            a_st, a_dtype, leading_dim_a, source_f32_tensor=a_f32
        )
        b_ = create_cute_tensor_for_fp8(
            b_st, b_dtype, leading_dim_b, source_f32_tensor=b_f32
        )
        c_ = create_cute_tensor_for_fp8(
            c_st, c_dtype, leading_dim_c, source_f32_tensor=c_f32
        )
        return testing.JitArguments(a_, b_, c_, current_stream)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_storage.numel() * a_storage.element_size()
            + b_storage.numel() * b_storage.element_size()
            + c_storage.numel() * c_storage.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Return execution time in microseconds
    exec_time = testing.benchmark(
        compiled_fn,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )
    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Dense Persistent GEMM with Mixed Clusters on Rubin."
    )

    parser.add_argument(
        "--mnkl",
        type=_parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=[
            "default",
            "none",
        ],
        help="Benchmark the kernel with default (cutlass.testing.benchmark) or none",
    )

    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
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
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal (Gaussian) initialization for tensors instead of uniform random",
    )

    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean of normal distribution for initialization (default: 0.0)",
    )

    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation of normal distribution for initialization (default: 1.0)",
    )

    # Kernel Configurations
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float8E5M2)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")

    parser.add_argument(
        "--use_tma_store", action="store_true", help="Use tma store or not"
    )

    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(4, 2),
        help="Preferred cluster shape (comma-separated)",
    )

    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(2, 1),
        help="Fallback cluster shape (comma-separated)",
    )

    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        default=False,
        help="Enable 2CTA MMA instructions feature",
    )

    parser.add_argument(
        "--mma_tiler",
        type=_parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )

    parser.add_argument(
        "--mma_inst_shape",
        type=_parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma instruction shape (M, N, K) (comma-separated)",
    )

    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )

    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    if len(args.preferred_cluster_shape_mn) != 2:
        parser.error("--preferred_cluster_shape_mn must contain exactly 2 values")

    if len(args.fallback_cluster_shape_mn) != 2:
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    print("[DSL INFO] Compiling Rubin Persistent Dense GEMM with Mixed Clusters:")
    print(
        f"[DSL INFO] A dtype: {args.a_dtype}, B dtype: {args.b_dtype}, C dtype: {args.c_dtype}, Acc dtype: {args.acc_dtype}"
    )
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Mma Tiler (M, N, K): {args.mma_tiler}")
    print(f"[DSL INFO] Mma Instruction Shape (M, N, K): {args.mma_inst_shape}")
    print(
        f"[DSL INFO] Preferred Cluster Shape (M, N): {args.preferred_cluster_shape_mn}"
    )
    print(f"[DSL INFO] Fallback Cluster Shape (M, N): {args.fallback_cluster_shape_mn}")
    print(
        f"[DSL INFO] 2CTA MMA instructions: {'True' if args.use_2cta_instrs else 'False'}"
    )
    print(f"[DSL INFO] Use TMA Store: {'True' if args.use_tma_store else 'False'}")
    print(
        f"[DSL INFO] B-reuse feature is {'enabled' if args.mma_tiler[0] // args.mma_inst_shape[0] == 2 else 'disabled'}"
    )

    run(
        args.mnkl,
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
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.benchmark == "default",
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
