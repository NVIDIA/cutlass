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


import argparse
import os
import sys
from pathlib import Path
from typing import Tuple, Type, Union, Literal, Optional

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cutlass_dsl import Boolean, Int32
from cutlass.cute.runtime import make_ptr
from cutlass.cute.nvgpu import tcgen05, OperandMajorMode
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.kernels.utils import tile_scheduler

if __name__ == "__main__":
    current_dir = Path(__file__).resolve().parent
    sys.path.insert(0, str(current_dir / "../../../../"))

from cutlass.kernels.rubin.gemm.base.dense_blockscaled_gemm_persistent import (
    Sm107BlockScaledPersistentDenseGemmKernel,
    create_and_init_tensors_emulated,
    create_scale_factor_tensor,
    construct_abc_cute_pointers_emulated,
)


"""
This example provides an implementation of the SM107 batched dense blockscaled GEMM kernel, please note that the APIs and implementation details related to this kernel may change in future releases.

The primary goal of this example is to demonstrate mixed cluster launches: If
there are not enough resources to schedule a cluster with
preferred_cluster_shape_mn, then fallback_cluster_shape_mn is used.

A high-performance persistent batched dense blockscaled GEMM example for the NVIDIA Rubin SM107 architecture
using CUTE DSL.
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M") for MXF8 input type and can only be row-major("K") for NVF4 input type
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K") for MXF8 input type and can only be row-major("K") for NVF4 input type
- Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")
- Matrix SFA layout is filled internally according to A shape and BlockScaledBasicChunk, which has Mxceil_div(K, sf_vec_size)xL elements respectively
- Matrix SFB layout is filled internally according to B shape and BlockScaledBasicChunk, which has Nxceil_div(K, sf_vec_size)xL elements respectively

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Rubin's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements the B-keep/B-reuse feature, if applicable
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Support warp specialization to avoid explicit pipelining between mainloop load and mma

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp:
    - Load scale factor A/B from shared memory (SMEM) to tensor memory (TMEM) using tcgen05.cp instruction.
    - Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp:
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Type convert C matrix to output type.
    - Optionally store C matrix from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations,
      or directly store C matrix from registers (RMEM) to global memory (GMEM) without TMA operations.
    - Optionally accept an elementwise lambda function epilogue_op to apply to the output tensor:
      e.g., relu can set epilogue_op = lambda x: cute.where(x > 0, x, cute.full_like(x, 0))

SM107 tcgen05.mma.kind.block_scale instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Read scalefactor A from TMEM
- Read scalefactor B from TMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Input arguments to this example is shown below:

.. code-block:: bash

    python examples/cute/rubin/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent_mixed_clusters.py   \
        --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN                           \
        --sf_dtype FloatNV8E5M3FNU --sf_vec_size 16                             \
        --c_dtype Float16                                                       \
        --mma_tiler 256,128,256 --mma_inst_shape 128,128,128                    \
        --preferred_cluster_shape_mn 4,2                                        \
        --fallback_cluster_shape_mn 2,1                                         \
        --mnkl 8192,8192,1024,1

Constraints:
* Supported input data types: mxf8, nvf4
  see detailed valid dtype combinations in below Sm107BlockScaledGemmUniversal class documentation
* Mma tiler M must be 128, 256 or 512, MMA instruction shape M can be 128 or 256
* Mma tiler N and MMA instruction shape N must be 64/128/192/256
* B-reuse feature is enabled if (MMA tiler M // MMA instruction shape M) == 2
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if Mma instruction shape M is 256 (.2CTA)
* The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 16 and 32 for Float8 and Float4, respectively.
"""


class Sm107BlockScaledGemmUniversal(Sm107BlockScaledPersistentDenseGemmKernel):
    """Persistent dense block scaled GEMM kernel for Rubin
    This class implements batched matrix multiplication (C = A x SFA x B x SFB) with support for various data types
    and architectural features specific to Rubin GPUs with persistent tile scheduling and warp specialization.

    :param sf_vec_size: Scalefactor vector size.
    :type sf_vec_size: int
    :param mma_inst_shape: Shape of the Matrix Multiply-Accumulate (MMA) instruction (M,N,K)
    :type mma_inst_shape: Tuple[int, int, int]
    :param mma_tiler: Shape of the Matrix Multiply-Accumulate (MMA) instruction (M,N,K)
    :type mma_tiler: Tuple[int, int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]
    :param use_tma_store: Stage C through SMEM and store it with TMA; when False,
        C goes straight from registers to global memory with predicated stores.
    :type use_tma_store: bool
    :param precompute_scheduler_params: Host-prepare scheduler parameters
        (static/affine/no-reduction only), defaults to False.
    :type precompute_scheduler_params: bool

    :note: Supported combinations of A/B data types, SF data typs and SF vector size:
        - MXF8: A/B: Float8E5M2/Float8E4M3FN + SF: Float8E8M0FNU + sf_vec_size: 32
        - NVF4: A/B: Float4E2M1FN + SF: Float8E8M0FNU/Float8E4M3FN/FloatNV8E5M3FNU + sf_vec_size: 16/32

    :note: Supported accumulator data types:
        - Float32

    :note: Supported C data types:
        - Float32
        - Float16/BFloat16

    :note: Constraints:
        - Mma tiler M must be 128, 256 or 512, MMA instruction shape M can be 128 or 256
        - Mma tiler N and MMA instruction shape N must be 64/128/192/256
        - B-reuse feature is enabled if (MMA tiler M // MMA instruction shape M) == 2
        - Cluster shape M must be multiple of 2 if Mma tiler M is 256
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Also, Cluster shape M/N must be <= 4 for scale factor multicasts due to limited size of scale factors

    Example:
        >>> gemm = Sm107BlockScaledGemmUniversal(
        ...     sf_vec_size=16,
        ...     mma_inst_shape=(128,128,128),
        ...     mma_tiler=(256, 128, 256),
        ...     preferred_cluster_shape_mn=(4, 2),
        ...     fallback_cluster_shape_mn=(2, 1)
        ... )
        >>> compiled = cute.compile(
        ...     gemm,
        ...     a_ptr,
        ...     b_ptr,
        ...     sfa_ptr,
        ...     sfb_ptr,
        ...     c_ptr,
        ...     workspace_ptr,
        ...     layouts,
        ...     problem_mnkl,
        ...     stream,
        ...     Int32(1),  # placeholder for swizzle_size
        ...     Boolean(True),  # placeholder for raster_along_m
        ...     Int32(1),  # placeholder for max_active_clusters_fallback
        ...     epilogue_op,
        ... )
        >>> max_active_clusters = query_max_active_clusters(
        ...     fallback_cluster_shape_mn, split_k, reduction_strategy
        ... )
        >>> compiled(
        ...     a_ptr,
        ...     b_ptr,
        ...     sfa_ptr,
        ...     sfb_ptr,
        ...     c_ptr,
        ...     workspace_ptr,
        ...     problem_mnkl,
        ...     stream,
        ...     Int32(swizzle_size),
        ...     Boolean(raster_along_m),
        ...     Int32(max_active_clusters),
        ... )
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        prefetch_dist: Union[int, Literal["auto"]] = 0,
        use_tma_store: bool = True,
        split_k: int = 1,
        work_strategy: Literal["grid", "static", "clc"] = "static",
        rasterization_strategy: Literal["none", "affine"] = "affine",
        reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
        num_scheduler_stages: int = 1,
        use_pdl: bool = False,
        use_reduction_pdl: bool = False,
        precompute_scheduler_params: bool = False,
    ):
        super().__init__(
            sf_vec_size,
            mma_inst_shape,
            mma_tiler,
            preferred_cluster_shape_mn,
            prefetch_dist,
            use_tma_store=use_tma_store,
            split_k=split_k,
            work_strategy=work_strategy,
            rasterization_strategy=rasterization_strategy,
            reduction_strategy=reduction_strategy,
            num_scheduler_stages=num_scheduler_stages,
            use_pdl=use_pdl,
            use_reduction_pdl=use_reduction_pdl,
            fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        )

        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.precompute_scheduler_params = precompute_scheduler_params

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B/SFA/SFB
        - Computing epilogue subtile
        - Setting up A/B/SFA/SFB/C stage counts in shared memory
        - Computing A/B/SFA/SFB/C shared memory layout
        """
        # Compute mma instruction shapes
        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128), MMA_Inst_Shape_K)
        self.mma_inst_shape_sfb = (
            self.mma_inst_shape[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape[1], 128),
            self.mma_inst_shape[2],
        )

        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=(1, 1, 1),
            permutation_mnk=self._get_mma_permutation_mnk(),
        )

        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        # Compute mma/cluster/tile shapes
        self.mma_tiler_sfb = (
            self.mma_inst_shape_sfb[0],
            self.mma_inst_shape_sfb[1],
            self.mma_tiler[2],
        )

        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cta_tile_shape_mnk_sfb = (
            self.mma_tiler_sfb[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler_sfb[1],
            self.mma_tiler_sfb[2],
        )

        # Compute cluster layout; the K mode carries the cluster split-K ranks
        template_params = self.tile_scheduler_template_params
        self.preferred_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(template_params.cluster_shape),
            (tiled_mma.thr_id.shape,),
        )
        self.preferred_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout(template_params.cluster_shape),
            (tiled_mma_sfb.thr_id.shape,),
        )

        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(template_params.fallback_cluster_shape),
            (tiled_mma.thr_id.shape,),
        )
        self.fallback_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout(template_params.fallback_cluster_shape),
            (tiled_mma_sfb.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_preferred_mcast_ctas_a = cute.size(
            self.preferred_cluster_layout_vmnk.shape[2]
        )
        self.num_preferred_mcast_ctas_b = cute.size(
            self.preferred_cluster_layout_vmnk.shape[1]
        )
        self.is_preferred_a_mcast = self.num_preferred_mcast_ctas_a > 1
        self.is_preferred_b_mcast = self.num_preferred_mcast_ctas_b > 1

        self.num_fallback_mcast_ctas_a = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_fallback_mcast_ctas_b = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_fallback_a_mcast = self.num_fallback_mcast_ctas_a > 1
        self.is_fallback_b_mcast = self.num_fallback_mcast_ctas_b > 1

        # Compute epilogue subtile
        if cutlass.const_expr(self.tile_scheduler_template_params.is_cluster_splitk):
            self.epi_tile = self.cta_tile_shape_mnk[:2]
        else:
            self.epi_tile = sm107_utils.compute_epilogue_tile_shape(
                tiled_mma.op,
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        self.epi_tile_n = cute.size(self.epi_tile[1])

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.sf_dtype,
            self.sf_vec_size,
            self.smem_capacity,
            self.occupancy,
            self.enable_breuse,
            self.use_tma_store,
            self.tile_scheduler_template.get_smem_workspace_size(),
        )

        # Compute A/B/SFA/SFB/C shared memory layout
        self.a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.num_ab_stage,
        )
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.b_dtype,
            self.num_ab_stage,
        )
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.c_smem_layout_staged = None
        if cutlass.const_expr(self.use_tma_store):
            self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
                self.c_dtype,
                self.c_layout,
                self.epi_tile,
                self.num_c_stage,
            )

        # Compute number of TMEM columns for SFA/SFB/Accumulator
        self.tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.slice_(self.sfa_smem_layout_staged, (None, None, None, 0)),
        )
        self.tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.slice_(self.sfb_smem_layout_staged, (None, None, None, 0)),
        )

        # Each column entry in TMEM is 32-bit wide, and so we recast the TMEM layout
        # from its original data type to a 32-bit wide data type. Moreover, TMEM
        # addresses are expressed as (row << 16) | col, which in CUTE are expressed
        # as an affine transformation row * (1<<16) + col, which can be seen as a CUTE
        # layout of (row, col):(1<<16, 1). As a result, by masking out the upper 16 bits
        # (keeping only the lower 16 bits), we extract the cosize corresponding
        # to only the columns.
        self.num_sfa_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFA_layout))
            & 0x0000FFFF
        )
        self.num_sfb_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFB_layout))
            & 0x0000FFFF
        )
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        self.num_accumulator_tmem_cols = (
            self.cta_tile_shape_mnk[1]
            * self.num_acc_stage
            * (2 if self.enable_breuse else 1)
        )

        # Set prefetch distance for both initial and rolling prefetch (unified control)
        # "auto" = use num_ab_stage, 0 = disable prefetch (default), >0 = explicit distance
        if self.prefetch_dist_param == "auto":
            self.prefetch_dist = self.num_ab_stage
        else:
            self.prefetch_dist = self.prefetch_dist_param

        # Check if prefetch is enabled (prefetch_dist > 0)
        self.prefetch_enabled = self.prefetch_dist > 0

    @cute.jit
    def __call__(
        self,
        a_ptr: cute.Pointer,
        b_ptr: cute.Pointer,
        sfa_ptr: cute.Pointer,
        sfb_ptr: cute.Pointer,
        c_ptr: cute.Pointer,
        workspace: cute.Pointer,
        layouts: cutlass.Constexpr[
            Tuple[OperandMajorMode, OperandMajorMode, cutlass.tensor_utils.LayoutEnum]
        ],
        problem_mnkl: Tuple[int, int, int, int],
        stream: cuda.CUstream,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        max_active_clusters_fallback: Int32,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute the GEMM operation in steps:
        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors
        - Compute grid size with regard to hardware constraints
        - Define shared storage for kernel
        - Launch the kernel synchronously

        :param a_tensor: Input tensor A
        :type a_tensor: cute.Tensor
        :param b_tensor: Input tensor B
        :type b_tensor: cute.Tensor
        :param sfa_tensor: Scale factor tensor A
        :type sfa_tensor: cute.Tensor
        :param sfb_tensor: Scale factor tensor B
        :type sfb_tensor: cute.Tensor
        :param c_tensor: Output tensor C
        :type c_tensor: cute.Tensor
        :param workspace: Base pointer of the tile scheduler's GMEM scratch;
            schedules that need no scratch receive a null pointer.
        :type workspace: cute.Pointer
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        :param swizzle_size: Tiles per swizzle group, a launch-time parameter so one
            compiled kernel serves every value of it
        :type swizzle_size: Int32
        :param raster_along_m: Whether to rasterize along M (else N), a
            launch-time parameter like swizzle_size
        :type raster_along_m: Boolean
        :param max_active_clusters_fallback: occupancy cap on concurrently
            resident fallback clusters (launch-time value; see
            ``query_max_active_clusters``). Only the ``static`` work strategy
            uses it (its grid is one wave).
        :type max_active_clusters_fallback: Int32
        :param epilogue_op: Optional elementwise lambda function to apply to the output tensor
        :type epilogue_op: cutlass.Constexpr
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        """

        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a_ptr.value_type
        self.b_dtype: Type[cutlass.Numeric] = b_ptr.value_type
        self.sf_dtype: Type[cutlass.Numeric] = sfa_ptr.value_type
        self.c_dtype: Type[cutlass.Numeric] = c_ptr.value_type

        m, n, k, l = problem_mnkl
        self.a_major_mode, self.b_major_mode, self.c_layout = layouts

        self.out_dtype: Type[cutlass.Numeric] = self.c_dtype
        self.c_dtype = self.tile_scheduler_template_params.gmem_output_type(
            self.c_dtype
        )

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        a_layout = cute.make_ordered_layout((m, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.a_major_mode == OperandMajorMode.K):
            a_layout = cute.make_ordered_layout(
                (cute.assume(m, 32), k, l), order=(1, 0, 2)
            )
        b_layout = cute.make_ordered_layout((n, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.b_major_mode == OperandMajorMode.K):
            b_layout = cute.make_ordered_layout(
                (cute.assume(n, 32), k, l), order=(1, 0, 2)
            )
        c_layout = cute.make_ordered_layout((cute.assume(m, 32), n, l), order=(0, 1, 2))
        if cutlass.const_expr(
            self.c_layout == cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        ):
            c_layout = cute.make_ordered_layout(
                (m, cute.assume(n, 32), l), order=(1, 0, 2)
            )
        a_tensor = cute.make_tensor(a_ptr, a_layout)
        b_tensor = cute.make_tensor(b_ptr, b_layout)
        c_tensor = cute.make_tensor(c_ptr, c_layout)

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        # ((Atom_M, Rest_M),(Atom_K, Rest_K),RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            a_tensor.shape, self.sf_vec_size
        )
        sfa_tensor = cute.make_tensor(sfa_ptr, sfa_layout)

        # ((Atom_N, Rest_N),(Atom_K, Rest_K),RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            b_tensor.shape, self.sf_vec_size
        )
        sfb_tensor = cute.make_tensor(sfb_ptr, sfb_layout)

        atom_layout_mnk = (1, 1, 1)
        permutation_mnk = self._get_mma_permutation_mnk()

        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )

        tiled_mma.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma.set(tcgen05.Field.NEGATE_B, False)

        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        tiled_mma_sfb.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma_sfb.set(tcgen05.Field.NEGATE_B, False)

        tiled_mma_bkeep = None
        tiled_mma_breuse = None
        if cutlass.const_expr(self.enable_breuse):
            # The 'FILL' collector operation indicates that B data should be kept
            # for reuse in subsequent operations.
            tiled_mma_bkeep = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                self.a_major_mode,
                self.b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.FILL,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )
            tiled_mma_bkeep.set(tcgen05.Field.NEGATE_A, False)
            tiled_mma_bkeep.set(tcgen05.Field.NEGATE_B, False)

            # The 'LASTUSE' collector operation indicates that this is the last use
            # of the B data that was kept from the previous operation.
            tiled_mma_breuse = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                self.a_major_mode,
                self.b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.LASTUSE,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )

            tiled_mma_breuse.set(tcgen05.Field.NEGATE_A, False)
            tiled_mma_breuse.set(tcgen05.Field.NEGATE_B, False)

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            a_tensor,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.fallback_cluster_shape_mn, tiled_mma.thr_id
            ),
            a_tensor,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for B
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_B(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            b_tensor,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )

        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_B(
                self.fallback_cluster_shape_mn, tiled_mma.thr_id
            ),
            b_tensor,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for SFA
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            sfa_tensor,
            sfa_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=cutlass.Int16,
        )

        tma_atom_sfa_fallback, tma_tensor_sfa_fallback = (
            cute.nvgpu.make_tiled_tma_atom_A(
                sm100_utils.cluster_shape_to_tma_atom_A(
                    self.fallback_cluster_shape_mn, tiled_mma.thr_id
                ),
                sfa_tensor,
                sfa_smem_layout,
                self.mma_tiler,
                tiled_mma,
                self.fallback_cluster_layout_vmnk.shape,
                internal_type=cutlass.Int16,
            )
        )

        # Setup TMA load for SFB
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_SFB(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            sfb_tensor,
            sfb_smem_layout,
            self.mma_tiler_sfb,
            tiled_mma_sfb,
            self.preferred_cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Int16,
        )

        tma_atom_sfb_fallback, tma_tensor_sfb_fallback = (
            cute.nvgpu.make_tiled_tma_atom_B(
                sm100_utils.cluster_shape_to_tma_atom_SFB(
                    self.fallback_cluster_shape_mn, tiled_mma.thr_id
                ),
                sfb_tensor,
                sfb_smem_layout,
                self.mma_tiler_sfb,
                tiled_mma_sfb,
                self.fallback_cluster_layout_sfb_vmnk.shape,
                internal_type=cutlass.Int16,
            )
        )

        if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 192):
            x = tma_tensor_sfb.stride[0][1]
            y = cute.ceil_div(tma_tensor_sfb.shape[0][1], 4)

            new_shape = (
                (tma_tensor_sfb.shape[0][0], ((2, 2), y)),
                tma_tensor_sfb.shape[1],
                tma_tensor_sfb.shape[2],
            )
            # Use right multiplication for ScaledBasis (3 * x instead of x * 3)
            x_times_3 = 3 * x
            new_stride = (
                (tma_tensor_sfb.stride[0][0], ((x, x), x_times_3)),
                tma_tensor_sfb.stride[1],
                tma_tensor_sfb.stride[2],
            )
            tma_tensor_sfb_new_layout = cute.make_layout(new_shape, stride=new_stride)
            tma_tensor_sfb = cute.make_tensor(
                tma_tensor_sfb.iterator, tma_tensor_sfb_new_layout
            )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        sfa_copy_size = cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        self.num_tma_load_bytes = (
            a_copy_size + b_copy_size + sfa_copy_size + sfb_copy_size
        ) * atom_thr_size

        # Setup TMA store for C
        tma_atom_c, tma_tensor_c = self.tile_scheduler_template.get_gmem_tma(
            self.use_tma_store,
            workspace,
            c_tensor,
            self.c_smem_layout_staged,
            self.epi_tile,
        )

        # Reuse host-prepared scheduler state when computing the launch grid.
        precomputed_sched_params = None
        if cutlass.const_expr(self.precompute_scheduler_params):
            precomputed_sched_params = (
                self.tile_scheduler_template.prepare_sched_params(
                    c_tensor.shape,
                    cute.ceil_div(k, self.mma_tiler[2]),
                    swizzle_size,
                    raster_along_m,
                )
            )
        grid = self.tile_scheduler_template.get_grid_shape(
            c_tensor.shape,
            swizzle_size,
            raster_along_m,
            max_active_clusters_fallback,
            precomputed_sched_params=precomputed_sched_params,
        )

        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

            scheduler_bytes = self.tile_scheduler_template.get_smem_workspace_size()
            scheduler_buf: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int8, scheduler_bytes],
                self.tile_scheduler_template.smem_alignment,
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
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.mixed_cluster_kernel(
            tiled_mma,
            tiled_mma_bkeep,
            tiled_mma_breuse,
            tiled_mma_sfb,
            (tma_atom_a, tma_atom_a_fallback),
            (tma_tensor_a, tma_tensor_a_fallback),
            (tma_atom_b, tma_atom_b_fallback),
            (tma_tensor_b, tma_tensor_b_fallback),
            (tma_atom_sfa, tma_atom_sfa_fallback),
            (tma_tensor_sfa, tma_tensor_sfa_fallback),
            (tma_atom_sfb, tma_atom_sfb_fallback),
            (tma_tensor_sfb, tma_tensor_sfb_fallback),
            tma_atom_c,
            tma_tensor_c,
            (self.preferred_cluster_layout_vmnk, self.fallback_cluster_layout_vmnk),
            (
                self.preferred_cluster_layout_sfb_vmnk,
                self.fallback_cluster_layout_sfb_vmnk,
            ),
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.tCtSFA_layout,
            self.tCtSFB_layout,
            self.c_smem_layout_staged,
            self.epi_tile,
            workspace,
            swizzle_size,
            raster_along_m,
            epilogue_op,
            precomputed_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.tile_scheduler_template_params.cluster_shape,),
            fallback_cluster=(
                *self.tile_scheduler_template_params.fallback_cluster_shape,
            ),
            stream=stream,
            min_blocks_per_mp=1,
            smem_merge_branch_allocs=True,
            use_pdl=self.use_pdl,
        )

        if cutlass.const_expr(self.tile_scheduler_template.is_gmem_splitk):
            self.tile_scheduler_template.splitk_reduction(
                workspace,
                c_tensor,
                k,
                epilogue_op,
                stream,
                use_pdl=self.use_pdl,
                use_reduction_pdl=self.use_reduction_pdl,
            )
        return

    # GPU device kernel with preferred & fallback cluster sizes.
    @cute.kernel
    def mixed_cluster_kernel(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_bkeep: Optional[cute.TiledMma],
        tiled_mma_breuse: Optional[cute.TiledMma],
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: Tuple[cute.CopyAtom, cute.CopyAtom],
        mA_mkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_b: Tuple[cute.CopyAtom, cute.CopyAtom],
        mB_nkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_sfa: Tuple[cute.CopyAtom, cute.CopyAtom],
        mSFA_mkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_sfb: Tuple[cute.CopyAtom, cute.CopyAtom],
        mSFB_nkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: Tuple[cute.Layout, cute.Layout],
        cluster_layout_sfb_vmnk: Tuple[cute.Layout, cute.Layout],
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        tCtSFA_layout: cute.Layout,
        tCtSFB_layout: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_gmem_workspace_ptr: cute.Pointer,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        epilogue_op: cutlass.Constexpr,
        precomputed_sched_params: tile_scheduler.TileSchedulerPrecomputedParams
        | None = None,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.

        This kernel implements the preferred cluster feature, meaning that it tries to launch with
        the preferred_cluster_shape_mn as its priority, but if at runtime, there is not enough
        resources available to do so, it then uses the fallback_cluster_shape_mn
        """

        # Get cluster coordinates to determine if this is a preferred cluster
        if cutlass.const_expr(
            any(
                self.preferred_cluster_shape_mn[i] != self.fallback_cluster_shape_mn[i]
                for i in range(2)
            )
        ):
            cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
            is_preferred_cluster = (
                cbdim_x == self.preferred_cluster_shape_mn[0]
                and cbdim_y == self.preferred_cluster_shape_mn[1]
            )
        else:
            # Skip the block_in_cluster_dim check when mixed cluster is not needed
            is_preferred_cluster = True

        # mega-kernel approach has 2 mutually exclusive code branches, only one path runs per launch,
        # specify `smem_merge_branch_allocs=True` at launch to enables shared memory reuse between two paths
        if is_preferred_cluster:
            self.kernel_impl(
                tiled_mma,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                tiled_mma_sfb,
                tma_atom_a[0],
                mA_mkl[0],
                tma_atom_b[0],
                mB_nkl[0],
                tma_atom_sfa[0],
                mSFA_mkl[0],
                tma_atom_sfb[0],
                mSFB_nkl[0],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[0],
                cluster_layout_sfb_vmnk[0],
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                tCtSFA_layout,
                tCtSFB_layout,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_gmem_workspace_ptr,
                swizzle_size,
                raster_along_m,
                epilogue_op,
                self.preferred_cluster_shape_mn,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
                precomputed_sched_params,
            )
        else:
            self.kernel_impl(
                tiled_mma,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                tiled_mma_sfb,
                tma_atom_a[1],
                mA_mkl[1],
                tma_atom_b[1],
                mB_nkl[1],
                tma_atom_sfa[1],
                mSFA_mkl[1],
                tma_atom_sfb[1],
                mSFB_nkl[1],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[1],
                cluster_layout_sfb_vmnk[1],
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                tCtSFA_layout,
                tCtSFB_layout,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_gmem_workspace_ptr,
                swizzle_size,
                raster_along_m,
                epilogue_op,
                self.fallback_cluster_shape_mn,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
                precomputed_sched_params,
            )

    def can_compile(
        self,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        sf_vec_size: int,
    ) -> bool:
        """
        Check the part of the configuration the compiled kernel specializes on.
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param sf_dtype: The data type of the scale factor tensor
        :type sf_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major axis of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major axis of the C tensor
        :type c_major: Literal["m", "n"]
        :param sf_vec_size: The vector size
        :type sf_vec_size: int
        :return: True if the configuration can be compiled, False otherwise
        :rtype: bool
        """
        try:
            if self.precompute_scheduler_params:
                self.tile_scheduler_template_params.check_precompute_support()
            # Most rules are the same with the base kernel
            # (with preferred_cluster_shape_mn as its cluster shape)
            if not super().can_compile(
                a_dtype,
                b_dtype,
                sf_dtype,
                c_dtype,
                a_major,
                b_major,
                c_major,
                sf_vec_size,
            ):
                return False

            if (
                self.fallback_cluster_shape_mn[0]
                % (2 if self.mma_inst_shape[0] == 256 else 1)
                != 0
            ):
                raise testing.CantImplementError(
                    f"Invalid fallback cluster shape for a 2CTA MMA, fallback_cluster_shape_m: {self.fallback_cluster_shape_mn[0]}"
                )

            # Check preferred is multiple of fallback
            if (
                self.preferred_cluster_shape_mn[0] % self.fallback_cluster_shape_mn[0]
                != 0
                or self.preferred_cluster_shape_mn[1]
                % self.fallback_cluster_shape_mn[1]
                != 0
            ):
                raise testing.CantImplementError(
                    f"Preferred cluster shape {self.preferred_cluster_shape_mn} must be "
                    f"integer multiple of fallback cluster shape {self.fallback_cluster_shape_mn}"
                )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    def can_implement(
        self,
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        swizzle_size: int,
        raster_along: Literal["m", "n"],
    ) -> bool:
        """
        Check if the compiled kernel can execute this launch.
        :param mnkl: The problem size as a tuple (M, N, K, L).
        :type mnkl: Tuple[int, int, int, int]
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major axis of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major axis of the C tensor
        :type c_major: Literal["m", "n"]
        :param swizzle_size: Tiles per swizzle group for this launch
        :type swizzle_size: int
        :param raster_along: Rasterization order for this launch, already
            resolved to a concrete axis by
            ``TileSchedulerTemplate.resolve_rasterization``
        :type raster_along: Literal["m", "n"]
        :return: True if this launch can be executed, False otherwise
        :rtype: bool
        """
        try:
            if not super().can_implement(
                mnkl,
                a_dtype,
                b_dtype,
                c_dtype,
                a_major,
                b_major,
                c_major,
                swizzle_size,
                raster_along,
            ):
                return False
        except testing.CantImplementError:
            return False
        return True


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    sfa_ptr: cute.Pointer,
    sfb_ptr: cute.Pointer,
    c: cute.Tensor,  # (l, m, n)
    stream: cuda.CUstream,
    workspace: cute.Pointer,
    swizzle_size: Int32,
    raster_along_m: Boolean,
    max_active_clusters_fallback: Int32,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """
    Wrapper API for persistent block scaled GEMM kernel to follow the convention of PyTorch's batch matrix-multiply (bmm).

    :param gemm_op: Kernel operation, expects (a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, workspace, layouts, problem_mnkl, stream, swizzle_size, raster_along_m, epilogue_op)
    :type gemm_op: cutlass.Constexpr
    :param a: Input tensor of shape (l, m, k), or (m, k) when unbatched
    :type a: cute.Tensor
    :param b: Input tensor of shape (l, k, n), or (k, n) when unbatched
    :type b: cute.Tensor
    :param sfa_ptr: Pointer to the scale factors of A.
    :type sfa_ptr: cute.Pointer
    :param sfb_ptr: Pointer to the scale factors of B
    :type sfb_ptr: cute.Pointer
    :param c: Output tensor of shape (l, m, n), or (m, n) when unbatched
    :type c: cute.Tensor
    :param swizzle_size: Tiles per swizzle group for this launch
    :type swizzle_size: Int32
    :param raster_along_m: True rasterizes M-major, False N-major
    :type raster_along_m: Boolean
    :param max_active_clusters_fallback: Occupancy cap on concurrently resident
        fallback clusters. Only the ``static`` work strategy uses it.
    :type max_active_clusters_fallback: Int32
    :param epilogue_op: Optional elementwise lambda function to apply per output element, defaults to identity
    :type epilogue_op: cutlass.Constexpr, optional
    """

    # Give an unbatched operand a unit batch mode so the one permutation below
    # serves both ranks.
    a = cute.prepend_ones(a, up_to_rank=3)
    b = cute.prepend_ones(b, up_to_rank=3)
    c = cute.prepend_ones(c, up_to_rank=3)

    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    m, k, l = a.shape
    n = b.shape[0]
    layouts = (
        cutlass.tensor_utils.LayoutEnum.from_tensor(a).mma_major_mode(),
        cutlass.tensor_utils.LayoutEnum.from_tensor(b).mma_major_mode(),
        cutlass.tensor_utils.LayoutEnum.from_tensor(c),
    )

    gemm_op(
        a.iterator,
        b.iterator,
        sfa_ptr,
        sfb_ptr,
        c.iterator,
        workspace,
        layouts,
        (m, n, k, l),
        stream,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        epilogue_op,
    )


def run_scaled_mm_with_emulated_dtype(
    gemm_obj: Sm107BlockScaledGemmUniversal,
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    mma_tiler_mn: Tuple[int, int],
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    ref_check_device: str = "cuda",
    use_cold_l2: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    prefetch_dist: Union[int, Literal["auto"]] = 0,
    swizzle_size: int = 1,
    raster_order: Literal["m", "n", "heuristic"] = "m",
    **kwargs,
):
    """Execute a persistent batched dense blockscaled GEMM operation on Rubin architecture with performance benchmarking (emulated dtypes).

    This function prepares input tensors, configures and launches the persistent GEMM kernel,
    optionally performs reference validation, and benchmarks the execution performance.

    :param gemm_obj: A gemm object which is created and passed along to be used
    :type gemm_obj: A gemm_obj of Sm107BlockScaledGemmUniversal
    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param a_dtype: Data type for input tensor A
    :type a_dtype: Type[cutlass.Numeric]
    :param b_dtype: Data type for input tensor B
    :type b_dtype: Type[cutlass.Numeric]
    :param sf_dtype: Data type for scale factor tensor
    :type sf_dtype: Type[cutlass.Numeric]
    :param sf_vec_size: Vector size for scale factor tensor
    :type sf_vec_size: int
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[cutlass.Numeric]
    :param a_major/b_major/c_major: Memory layout of tensor A/B/C
    :type a_major/b_major/c_major: Literal["m", "n","k"]
    :param mma_tiler_mn: MMA tiling size.
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param tolerance: Tolerance value for reference validation comparison, defaults to 1e-01
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 0
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 1
    :type iterations: int, optional
    :param ref_check_device: Device the reference check runs on, one of "cuda", "cpu" or "skipped", defaults to "cuda"
    :type ref_check_device: str, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False
    :type use_cold_l2: bool, optional
    :param prefetch_dist: Prefetch distance for TMA operations ("auto"=use num_ab_stage, 0=disable, >0=explicit).
    :type prefetch_dist: Union[int, Literal["auto"]], optional
    :param swizzle_size: Tiles per swizzle group for this launch, defaults to 1
    :type swizzle_size: int, optional
    :param raster_order: Rasterization order for this launch; "heuristic" lets
        the tile scheduler pick one from the problem shape, defaults to "m"
    :type raster_order: Literal["m", "n", "heuristic"], optional
    :raises RuntimeError: If CUDA GPU is not available
    :raises ValueError: If the configuration is invalid or unsupported by the kernel
    :return: Execution time of the GEMM kernel
    :rtype: float
    """
    print(f"Running {gemm_obj.__class__.__name__} test (Emulated) with:")
    print(f"mnkl: {mnkl}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, SF dtype: {sf_dtype}, SF Vec size: {sf_vec_size}"
    )
    print(f"C dtype: {c_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}")
    print(f"Preferred cluster Shape (M, N): {preferred_cluster_shape_mn}")
    print(f"Fallback cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Reference check device: {ref_check_device}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(
        f"Work Strategy: {gemm_obj.work_strategy}, "
        f"Rasterization Strategy: {gemm_obj.rasterization_strategy}"
    )
    print(
        f"Split K: {gemm_obj.split_k}, "
        f"Reduction Strategy: {gemm_obj.reduction_strategy}"
    )
    print(
        f"Use PDL: {gemm_obj.use_pdl}, Use Reduction PDL: {gemm_obj.use_reduction_pdl}"
    )
    if prefetch_dist == "auto":
        print("Prefetch distance: auto (num_ab_stage)")
    elif prefetch_dist == 0:
        print("Prefetch: Disabled")
    else:
        print(f"Prefetch distance: {prefetch_dist}")

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # HardwareInfo needs the CUDA context torch binds when a device is selected.
    torch.cuda.set_device(torch.cuda.current_device())
    max_active_clusters = tile_scheduler.query_max_active_clusters(
        gemm_obj.fallback_cluster_shape_mn,
        gemm_obj.split_k,
        gemm_obj.reduction_strategy,
    )

    torch.manual_seed(1111)

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Construct CuTe Pointers
    a_ptr = make_ptr(a_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    b_ptr = make_ptr(b_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    c_ptr = make_ptr(c_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    sfa_ptr = make_ptr(sf_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=32)
    sfb_ptr = make_ptr(sf_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=32)

    a_major_mode = OperandMajorMode.K if a_major == "k" else OperandMajorMode.MN
    b_major_mode = OperandMajorMode.K if b_major == "k" else OperandMajorMode.MN
    c_layout = (
        cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        if c_major == "n"
        else cutlass.tensor_utils.LayoutEnum.COL_MAJOR
    )

    compiled_gemm = cute.compile(
        gemm_obj,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        make_ptr(cutlass.Int8, 0, cutlass.AddressSpace.gmem, assumed_align=16),
        (a_major_mode, b_major_mode, c_layout),
        (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
        current_stream,
        Int32(1),  # placeholder for swizzle_size
        Boolean(True),  # placeholder for raster_along_m
        Int32(1),  # placeholder for max_active_clusters_fallback
        lambda x: x,
    )

    workspace_bytes = gemm_obj.get_gmem_workspace_size([m, n, l])
    # ``_workspace_tensor`` is a keepalive: dropping it dangles ``workspace_ptr``.
    _workspace_tensor = None
    workspace_address = 0
    if workspace_bytes != 0:
        _workspace_tensor = torch.empty(
            workspace_bytes, dtype=torch.int8, device="cuda"
        )
        gemm_obj.initialize_workspace(_workspace_tensor, [m, n, l])
        workspace_address = _workspace_tensor.data_ptr()
    workspace_ptr = make_ptr(
        cutlass.Int8, workspace_address, cutlass.AddressSpace.gmem, assumed_align=16
    )

    raster_order, swizzle_size = gemm_obj.tile_scheduler_template.resolve_rasterization(
        raster_order,
        swizzle_size,
        mnkl,
        a_element_bytes=a_dtype.width // 8,
        b_element_bytes=b_dtype.width // 8,
    )
    if not gemm_obj.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        swizzle_size,
        raster_order,
    ):
        raise testing.CantImplementError(
            f"Unsupported launch for mnkl: {mnkl}, "
            f"swizzle_size: {swizzle_size}, raster_order: {raster_order}"
        )

    # Create Torch Tensors for A, scale factor A, B, scale factor B, C
    a_f32_ref, b_f32_ref, c, sfa_f32, sfb_f32 = create_and_init_tensors_emulated(
        mnkl,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        init_normal=init_normal,
        normal_mean=normal_mean,
        normal_std=normal_std,
    )

    sfa_f32_ref, sfa_reordered = create_scale_factor_tensor(
        l, m, k, sf_vec_size, sf_dtype, sfa_f32
    )
    sfb_f32_ref, sfb_reordered = create_scale_factor_tensor(
        l, n, k, sf_vec_size, sf_dtype, sfb_f32
    )
    # Construct CuTe Pointers

    a_ptr, b_ptr, c_ptr, _, _ = construct_abc_cute_pointers_emulated(
        a_f32_ref,
        b_f32_ref,
        c,
        a_dtype,
        b_dtype,
        c_dtype,
    )

    # Compute reference result
    if ref_check_device != "skipped":
        # Execute kernel once for reference checking
        compiled_gemm(
            a_ptr,
            b_ptr,
            sfa_reordered.iterator,
            sfb_reordered.iterator,
            c_ptr,
            workspace_ptr,
            (m, n, k, l),
            current_stream,
            Int32(swizzle_size),
            Boolean(raster_order == "m"),
            Int32(max_active_clusters),
        )

        # The reference runs on whichever device the caller asked for; the
        # scale factors follow the operands.
        device = ref_check_device
        res_a = torch.einsum(
            "mkl,mkl->mkl", a_f32_ref.to(device), sfa_f32_ref.to(device)
        )
        res_b = torch.einsum(
            "nkl,nkl->nkl", b_f32_ref.to(device), sfb_f32_ref.to(device)
        )
        ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)
        c_ref = ref.to(dtype=cutlass_torch.dtype(c_dtype))

        torch.testing.assert_close(c.to(device), c_ref, atol=tolerance, rtol=tolerance)

    def generate_inputs():
        # Create Torch Tensors for A, scale factor A, B, scale factor B, C
        a_f32_ref, b_f32_ref, c, sfa_f32, sfb_f32 = create_and_init_tensors_emulated(
            mnkl,
            sf_vec_size,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_normal=init_normal,
            normal_mean=normal_mean,
            normal_std=normal_std,
        )

        _, sfa_reordered = create_scale_factor_tensor(
            l, m, k, sf_vec_size, sf_dtype, sfa_f32
        )
        _, sfb_reordered = create_scale_factor_tensor(
            l, n, k, sf_vec_size, sf_dtype, sfb_f32
        )
        # Construct CuTe Pointers

        a_ptr, b_ptr, c_ptr, a_cute, b_cute = construct_abc_cute_pointers_emulated(
            a_f32_ref,
            b_f32_ref,
            c,
            a_dtype,
            b_dtype,
            c_dtype,
        )

        jit_args = cutlass.testing.JitArguments(
            a_ptr,
            b_ptr,
            sfa_reordered.iterator,
            sfb_reordered.iterator,
            c_ptr,
            workspace_ptr,
            (m, n, k, l),
            current_stream,
            Int32(swizzle_size),
            Boolean(raster_order == "m"),
            Int32(max_active_clusters),
        )
        # Keep references to external variables (e.g., Torch tensors when taking a view)
        jit_args.add_to_scope(
            [a_f32_ref, b_f32_ref, sfa_reordered, sfb_reordered, c, a_cute, b_cute]
        )
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_f32_ref.numel() * a_f32_ref.element_size()
            + b_f32_ref.numel() * b_f32_ref.element_size()
            + sfa_reordered.numel() * sfa_reordered.element_size()
            + sfb_reordered.numel() * sfb_reordered.element_size()
            + c.numel() * c.element_size()
        )
        workspace_count = cutlass.testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = cutlass.testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_inputs,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time  # Return execution time in microseconds


def run(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    mma_tiler: Tuple[int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    ref_check_device: str = "cuda",
    use_cold_l2: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    prefetch_dist: Union[int, Literal["auto"]] = 0,
    swizzle_size: int = 1,
    raster_order: Literal["m", "n", "heuristic"] = "m",
    use_tma_store: bool = True,
    split_k: int = 1,
    reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
    work_strategy: Literal["grid", "static", "clc"] = "static",
    rasterization_strategy: Literal["none", "affine"] = "affine",
    num_scheduler_stages: int = 1,
    use_pdl: bool = False,
    use_reduction_pdl: bool = False,
    precompute_scheduler_params: bool = False,
    **kwargs,
):
    """Execute the appropriate GEMM function based on dtype.

    :param precompute_scheduler_params: Host-prepare scheduler parameters
        (static/affine/no-reduction only), defaults to False.
    :type precompute_scheduler_params: bool, optional
    """
    # Configure gemm kernel
    gemm = Sm107BlockScaledGemmUniversal(
        sf_vec_size,
        mma_inst_shape,
        mma_tiler,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        prefetch_dist,
        use_tma_store=use_tma_store,
        split_k=split_k,
        work_strategy=work_strategy,
        rasterization_strategy=rasterization_strategy,
        reduction_strategy=reduction_strategy,
        num_scheduler_stages=num_scheduler_stages,
        use_pdl=use_pdl,
        use_reduction_pdl=use_reduction_pdl,
        precompute_scheduler_params=precompute_scheduler_params,
    )

    # Skip unsupported testcase
    if not gemm.can_compile(
        a_dtype,
        b_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        sf_vec_size,
    ):
        m, n, k, l = mnkl
        raise testing.CantImplementError(
            (
                f"Unsupported testcase a_dtype: {a_dtype}, b_dtype: {b_dtype}, sf_dtype: {sf_dtype}, "
                f"sf_vec_size: {sf_vec_size}, c_dtype: {c_dtype}, "
                f"mma_tiler: {mma_tiler}, mma_inst_shape: {mma_inst_shape}, "
                f"preferred_cluster_shape: {preferred_cluster_shape_mn}, "
                f"fallback_cluster_shape: {fallback_cluster_shape_mn}, "
                f"mnkl: ({m}, {n}, {k}, {l}), "
                f"a_major: {a_major}, b_major: {b_major}, c_major: {c_major}"
            )
        )

    exec_time = run_scaled_mm_with_emulated_dtype(
        gemm,
        mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        tolerance,
        warmup_iterations,
        iterations,
        ref_check_device,
        use_cold_l2,
        init_normal,
        normal_mean,
        normal_std,
        prefetch_dist,
        swizzle_size=swizzle_size,
        raster_order=raster_order,
    )

    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


def prepare_parser():
    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of Rubin (Sm107) Dense Persistent BlockScaled GEMM."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(512, 256, 256, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 256),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma inst shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
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
        "--ref_check_device",
        type=str,
        default="cuda",
        choices=["cuda", "cpu", "skipped"],
        help="Device for the reference check, or 'skipped' to omit it",
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
    parser.add_argument(
        "--prefetch_dist",
        type=lambda v: "auto" if v == "auto" else int(v),
        default=0,
        help="Prefetch distance for TMA operations (default: 0=disable, 'auto'=use num_ab_stage, >0=explicit distance)",
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
        choices=["m", "n", "heuristic"],
        default="m",
        help="Rasterization order of clusters ('heuristic' picks one from the problem shape)",
    )
    parser.add_argument(
        "--use_tma_store",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Store C through SMEM with TMA; --no-use_tma_store stores from registers",
    )
    parser.add_argument(
        "--split_k",
        type=int,
        default=1,
        help="Number of K partitions; requires a --reduction_strategy other than 'none'",
    )
    parser.add_argument(
        "--reduction_strategy",
        type=str,
        choices=["none", "gmem-splitk", "cluster-splitk"],
        default="none",
        help="How the K partitions are reduced: a second GMEM kernel, or in-kernel over DSMEM",
    )
    parser.add_argument(
        "--work_strategy",
        type=str,
        choices=["grid", "static", "clc"],
        default="static",
        help="How output tiles are handed to CTAs",
    )
    parser.add_argument(
        "--rasterization_strategy",
        type=str,
        choices=["none", "affine"],
        default="affine",
        help="How a work index is decoded into a tile coordinate",
    )
    parser.add_argument(
        "--num_scheduler_stages",
        type=int,
        default=1,
        help="Depth of the CLC work-fetch pipeline",
    )
    parser.add_argument(
        "--use_pdl",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Launch the GEMM with programmatic dependent launch",
    )
    parser.add_argument(
        "--use_reduction_pdl",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Launch the GMEM split-K reduction kernel with programmatic dependent launch",
    )
    parser.add_argument(
        "--precompute_scheduler_params",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Prepare scheduler parameters on the host (requires static/affine/none)",
    )
    return parser


if __name__ == "__main__":
    parser = prepare_parser()
    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values (M, N, K)")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values (M, N, K)")

    if len(args.preferred_cluster_shape_mn) != 2:
        parser.error("--preferred_cluster_shape_mn must contain exactly 2 values")

    if len(args.fallback_cluster_shape_mn) != 2:
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    print(
        "[DSL INFO] Compiling Rubin Persistent Dense Blockscaled GEMM with mixed clusters:"
    )
    print(
        f"[DSL INFO] A dtype: {args.a_dtype}, B dtype: {args.b_dtype}, C dtype: {args.c_dtype}"
    )
    print(f"[DSL INFO] SF dtype: {args.sf_dtype}, SF vector size: {args.sf_vec_size}")
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Mma Tiler (M, N, K): {args.mma_tiler}")
    print(f"[DSL INFO] Mma inst shape (M, N, K): {args.mma_inst_shape}")
    print(
        f"[DSL INFO] B-reuse feature is {'enabled' if args.mma_tiler[0] // args.mma_inst_shape[0] == 2 else 'disabled'}"
    )
    print(
        f"[DSL INFO] Preferred cluster Shape (M, N): {args.preferred_cluster_shape_mn}"
    )
    print(f"[DSL INFO] Fallback cluster Shape (M, N): {args.fallback_cluster_shape_mn}")

    # Execute GEMM with appropriate function based on dtype
    run(
        args.mnkl,
        args.a_dtype,
        args.b_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler,
        args.mma_inst_shape,
        args.preferred_cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.ref_check_device,
        args.use_cold_l2,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
        args.prefetch_dist,
        args.swizzle_size,
        args.raster_order,
        use_tma_store=args.use_tma_store,
        split_k=args.split_k,
        reduction_strategy=args.reduction_strategy,
        work_strategy=args.work_strategy,
        rasterization_strategy=args.rasterization_strategy,
        num_scheduler_stages=args.num_scheduler_stages,
        use_pdl=args.use_pdl,
        use_reduction_pdl=args.use_reduction_pdl,
        precompute_scheduler_params=args.precompute_scheduler_params,
    )
    print("PASS")
