# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
from types import SimpleNamespace
from typing import Optional, Type, Tuple, Union

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.nvgpu import cpasync, tcgen05, OperandMajorMode
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils.blackwell_helpers as sm103_utils
import cutlass.utils.rubin_helpers as sm107_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.cute.runtime import from_dlpack
from dataclasses import dataclass, field

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # examples/CuTeDSL for `helpers`, examples/CuTeDSL/cute for `rubin`
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))
from helpers.sparse_utils import (
    create_4_2_sparse_tensors,
    make_zero_cute_tensor_on_gpu,
)
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)
from rubin.kernel.blockscaled_gemm.dense_blockscaled_gemm_persistent import (  # noqa: E402
    compute_sfd_reference,
    create_sfd_output_tensor,
    cvt_sf_M32x4xrm_K4xrk_L_to_MKL,
    decode_sfd_bytes_to_f32,
)

"""
This example provides an experimental implementation of the sm107 batched FP4 Ultra sparse blockscaled GEMM kernel,
please note that the APIs and implementation details related to this kernel may change in future releases.

A high-performance persistent batched FP4 Ultra sparse blockscaled GEMM example for the NVIDIA Rubin
architecture using CUTE DSL. This kernel leverages 4:2 structured sparsity on matrix A for improved performance.
    - Matrix A is MxKxL (4:2 structured sparse, compressed), L is batch dimension, A can only be row-major("K") for MXF4/NVF4 input type
    - Matrix B is NxKxL (dense), L is batch dimension, B can only be row-major("K") for MXF4/NVF4 input type
    - Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")
    - Matrix E is the sparse metadata tensor encoding the 4:2 sparsity pattern of A
    - Matrix SFA layout is filled internally according to A shape and sm107_BlockScaledBasicChunk, which has M×ceil_div(K, sf_vec_size)×L elements respectively
    - Matrix SFB layout is filled internally according to B shape and sm107_BlockScaledBasicChunk, which has N×ceil_div(K, sf_vec_size)×L elements respectively

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Rubin's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Support warp specialization with separate TMA warps for A/B, scale factors, and sparse metadata E
    - Utilizes circular buffer technique for optimal memory and computation overlap
    - Supports 4:2 structured sparsity on matrix A with sparse metadata tensor E

This GEMM works as follows:
    1. TMA A/B warp: Load compressed A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
    2. TMA SF warp: Load scale factor A/B from global memory (GMEM) to shared memory (SMEM) using TMA operations.
    3. TMA E warp: Load sparse metadata E from global memory (GMEM) to shared memory (SMEM) using TMA operations.
    4. MMA warp:
        - Load scale factor A/B from shared memory (SMEM) to tensor memory (TMEM) using tcgen05.cp instruction.
        - Load sparse metadata E from shared memory (SMEM) to tensor memory (TMEM) using tcgen05.cp instruction.
        - Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction to deal with circular buffering.
    5. Epilogue warps:
        - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
        - Type convert C matrix to output type.
        - Store C matrix directly from registers (RMEM) to global memory (GMEM) without TMA operations.
        - Optionally accept an elementwise lambda function epilogue_op to apply to the output tensor:
            e.g., relu can set epilogue_op = lambda x: cute.where(x > 0, x, cute.full_like(x, 0))

sm107 tcgen05.mma.kind.block_scale sparse instructions operate as follows:
    - Read compressed matrix A from two SMEM buffers(current buffer and next buffer)
    - Read matrix B from two SMEM buffers(current buffer and next buffer)
    - Read scalefactor A from TMEM
    - Read scalefactor B from TMEM
    - Read sparse metadata E from TMEM
    - Write accumulator to TMEM

The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Input arguments to this example is shown below:

.. code-block:: bash

    python examples/rubin/sm107_sparse_blockscaled_gemm_persistent.py        \
      --ab_dtype Float4E2M1FN --sf_dtype Float8E8M0FNU --sf_vec_size 32      \
      --c_dtype Float16                                                       \
      --mma_tiler_mn 256,256 --cluster_shape_mn 2,4                          \
      --mnkl 4096,4096,6144,1

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/rubin/sm107_sparse_blockscaled_gemm_persistent.py    \
      --ab_dtype Float4E2M1FN --sf_dtype Float8E8M0FNU --sf_vec_size 32      \
      --c_dtype Float16                                                       \
      --mma_tiler_mn 256,256 --cluster_shape_mn 2,4                          \
      --mnkl 4096,4096,6144,1                                                \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
    - Supported input data types: mxf4, nvf4 (with 4:2 structured sparsity on A)
        - see detailed valid dtype combinations in below Sm107BlockScaledPersistentSparseGemmKernel class documentation
    - A/B tensor must have the same data type
    - Mma tiler M must be 128 or 256(use_2cta_instrs)
    - Mma tiler N must be 128 or 256
    - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
    - Cluster shape M must be multiple of 2 if Mma tiler M is 256(use_2cta_instrs)
    - The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned,
        i.e, number of elements is a multiple of 32 for MXF4/NVF4.
"""


class Sm107BlockScaledPersistentSparseGemmKernel:
    """This class implements batched sparse matrix multiplication (C = A x SFA x B x SFB) with 4:2 structured
    sparsity on matrix A, support for FP4 data types, and architectural features specific to Rubin GPUs
    with persistent tile scheduling and warp specialization.

    :param sf_vec_size: Scalefactor vector size.
    :type sf_vec_size: int
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]

    :note: In current version, A and B tensor must have the same data type
        - i.e., mixing different types such as Float4E2M1FN for A and Float8E4M3FN for B is not supported

    :note: Supported combinations of A/B data types, SF data types and SF vector size:
        - A/B: Float4E2M1FN + SF: Float8E8M0FNU/Float8E4M3FN/FloatNV8E5M3FNU + sf_vec_size: 32 or 64

    :note: Supported accumulator data types:
        - Float32

    :note: Supported C data types:
        - Float32
        - Float16/BFloat16
        - Float8E4M3FN/Float8E5M2
    :note: Constraints:
        - MMA tiler M must be 128 or 256 (use_2cta_instrs)
        - MMA tiler N must be 128/256
        - Cluster shape M must be multiple of 2 if Mma tiler M is 256
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Cluster shape M/N must be <= 4 for scale factor multicasts due to limited size of scale factors

    Example:
        >>> gemm = Sm107BlockScaledPersistentSparseGemmKernel(
        ...     sf_vec_size=32,
        ...     mma_tiler_mn=(256, 256),
        ...     cluster_shape_mn=(2, 4)
        ... )
        >>> gemm(a_tensor, b_tensor, sfa_tensor, sfb_tensor, e_tensor, c_tensor, max_active_clusters, stream)
    """

    # tcgen05/driver reserved SMEM (EIATTR_RESERVED_SMEM_USED), counted by the
    # launch budget on top of static+dynamic but with no query API on sm_107a.
    RESERVED_SMEM_BYTES = 1024

    TMA_STORE_NUM_C_STAGE = 2

    def __init__(
        self,
        sf_vec_size: int,
        mma_inst_shape_mn: Tuple[int, int],
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
        swizzle_size: int = 1,
        raster_order: str = "m",
    ):
        """Initializes the configuration for a Rubin FP4 Ultra sparse blockscaled GEMM kernel.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data types for MMA accumulator, always set to Float32
            - sf_vec_size: Scalefactor A/B vector size.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.
            - mma_inst_shape_mn: The (M, N) shape of the MMA instruction. When
              mma_tiler_mn[0] // mma_inst_shape_mn[0] == 2, the Bkeep-Breuse
              pattern is enabled.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        :param sf_vec_size: Scalefactor vector size.
        :type sf_vec_size: int
        :param mma_tiler_mn: Tuple (M, N) shape of the MMA tiler.
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: Tuple[int, int]
        :param use_tma_store: Whether TMA store is enabled.
        :type use_tma_store: bool
        :param mma_inst_shape_mn: Tuple (M, N) shape of the MMA instruction.
            If None, defaults to mma_tiler_mn (no breuse).
        :type mma_inst_shape_mn: Optional[Tuple[int, int]]
        :param swizzle_size: Swizzle size for rasterization (1 = no swizzle).
        :type swizzle_size: int
        :param raster_order: Rasterization order, ``"m"`` or ``"n"``.
        :type raster_order: str
        """
        self.acc_dtype = cutlass.Float32
        self.sf_vec_size = sf_vec_size

        # If mma_inst_shape_mn is not provided, default to mma_tiler_mn (no breuse)
        if mma_inst_shape_mn is None:
            mma_inst_shape_mn = mma_tiler_mn

        self.mma_inst_shape_mn_param = mma_inst_shape_mn

        # use_2cta_instrs is determined by the instruction shape, not the tiler
        self.use_2cta_instrs = mma_inst_shape_mn[0] == 256
        self.cluster_shape_mn = cluster_shape_mn
        # K dimension is deferred in _setup_attributes
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.use_tma_store = use_tma_store
        self.swizzle_size = swizzle_size
        self.raster_order = raster_order
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        # Bkeep-Breuse pattern is controlled by mma_inst_shape and mma_tiler
        self.enable_breuse = (
            True if mma_tiler_mn[0] // mma_inst_shape_mn[0] == 2 else False
        )

        self.enable_E_tmem_reuse = (
            True if (self.enable_breuse and mma_tiler_mn[1] == 256) else False
        )

        self.occupancy = 1
        # Set specialized warp ids
        self.epilogue_warp_id = (
            0,
            1,
            2,
            3,
        )
        self.mma_warp_id = 4
        self.tma_ab_warp_id = 5
        self.tma_sf_warp_id = 6
        self.tma_e_warp_id = 7
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_ab_warp_id,
                self.tma_sf_warp_id,
                self.tma_e_warp_id,
                *self.epilogue_warp_id,
            )
        )
        # Set barrier id for epilogue sync and tmem ptr sync
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

        self.arch = "sm_107"
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)

        self.sf_buffers_per_tile_k = 2 if self.sf_vec_size == 32 else 1
        self.e_buffers_per_tile_k = 2

    def _get_mma_permutation_mnk(self):
        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape_mnk[0] // 2, 2, 2),
                stride=(1, self.mma_inst_shape_mnk[0], self.mma_inst_shape_mnk[0] // 2),
            )
            return (m_layout, self.mma_inst_shape_mnk[1], self.mma_inst_shape_mnk[2])

        else:
            return (1, 1, 1)

    def _setup_attributes(self):
        """Set up kernel attributes that depend on runtime tensor inputs.

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
        # Use the separate mma_inst_shape_mn_param (which may differ from mma_tiler for breuse)
        self.mma_inst_shape_mn = self.mma_inst_shape_mn_param

        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128), MMA_Inst_Shape_K)
        self.mma_inst_shape_mn_sfb = (
            self.mma_inst_shape_mn[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape_mn[1], 128),
        )

        tiled_mma = self.sm107_make_blockscaled_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        dummy_tiled_mma_sfb = self.sm107_make_blockscaled_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )

        # Compute mma/cluster/tile shapes
        self.mma_inst_shape_mnk = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            192,
        )

        num_mma_inst_per_mma_tiler = 4
        # For breuse, mma_tiler[0] is 2x mma_inst_shape_mn[0]; otherwise they are equal.
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            num_mma_inst_per_mma_tiler * self.mma_inst_shape_mnk[2],  # 768
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        blk_mn = 128
        self.cta_n_sf = cute.round_up(cute.size(self.cta_tile_shape_mnk[1]), blk_mn)
        self.mma_sf_tiler = (
            self.cta_tile_shape_mnk[0],
            self.cta_n_sf,
            self.cta_tile_shape_mnk[2] // self.sf_buffers_per_tile_k,
        )

        self.mma_e_tiler = (
            self.cta_tile_shape_mnk[0],
            self.cta_n_sf,
            self.cta_tile_shape_mnk[2] // self.e_buffers_per_tile_k,
        )

        # E tile shape per tma instruction
        self.mma_e_tiler_per_tma = (
            self.mma_e_tiler[0],
            self.mma_e_tiler[2],
            128,
        )

        self.sf_atom = self.sm107BlockScaledBasicChunk(
            self.sf_vec_size, tiled_mma.op.a_major_mode
        ).layout

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (dummy_tiled_mma_sfb.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_e = self.num_mcast_ctas_a  # E follows A
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1
        self.is_e_mcast = self.num_mcast_ctas_e > 1

        # Compute epilogue subtile
        self.epi_tile = utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        (
            self.num_acc_stage,
            self.num_ab_stage,
            self.num_sf_stage,
            self.num_e_stage,
            self.num_c_stage,
        ) = self._compute_block_scaled_sparse_stages(
            tiled_mma,
            self.mma_inst_shape_mn,
            self.mma_tiler,
            self.mma_sf_tiler,
            self.mma_e_tiler,
            self.e_sparse_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.sf_dtype,
            self.sf_vec_size,
            self.smem_capacity,
            self.occupancy,
            self.use_tma_store,
            self.enable_breuse,
        )

        # Compute A/B/SFA/SFB/C shared memory layout
        # ((CTA_MMA_M,16bytes),1,4,num_ab_stage)
        self.a_smem_layout_staged = self.sm107_make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.mma_inst_shape_mn,
            self.num_ab_stage,
        )

        # ((CTA_MMA_M,16bytes),1,8,3)
        self.a_smem_layout_staged_tma = self.sm107_make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.mma_inst_shape_mn,
            3,
        )

        # ((CTA_MMA_N,16bytes),1,8,num_ab_stage)
        self.b_smem_layout_staged = self.sm107_make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
        )

        # ((CTA_MMA_N,16bytes),1,8,3)
        self.b_smem_layout_staged_tma = self.sm107_make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            3,
        )

        # (((32,4),(sf_vec_size,4)),2,3,num_sf_stage) for 2cta breuse config
        self.sfa_smem_layout_staged = self.sm107_make_smem_layout_sfa(
            tiled_mma,
            self.mma_sf_tiler,
            self.sf_vec_size,
            self.num_sf_stage,
        )

        # (((32,4,2),(sf_vec_size,4)),1,3,num_sf_stage) for 2cta breuse config
        self.sfb_smem_layout_staged = self.sm107_make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_sf_stage,
        )

        # ((128,128),2,3,num_e_stage) for 2cta breuse config
        self.e_smem_layout_staged = self.sm107_make_smem_layout_e(
            tiled_mma, self.mma_inst_shape_mnk, self.mma_e_tiler, self.num_e_stage
        )

        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = sm103_utils.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

    @cute.jit
    def __call__(
        self,
        a_tensor: cute.Tensor,
        b_tensor: cute.Tensor,
        sfa_tensor: cute.Tensor,
        sfb_tensor: cute.Tensor,
        e_tensor: cute.Tensor,
        c_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
        sfd_ptr: Optional[cute.Pointer] = None,
        norm_const_tensor: Optional[cute.Tensor] = None,
        sfd_vec_size: cutlass.Constexpr[Optional[int]] = None,
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
        :param e_tensor: Sparse E tensor
        :type e_tensor: cute.Tensor
        :param c_tensor: Output tensor C
        :type c_tensor: cute.Tensor
        :param max_active_clusters: Maximum number of active clusters
        :type max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        :param epilogue_op: Optional elementwise lambda function to apply to the output tensor
        :type epilogue_op: cutlass.Constexpr
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        """
        # Setup static attributes before smem/grid/tma computation
        self.a_raw_dtype: Type[cutlass.Numeric] = a_tensor.element_type
        self.a_sparse_dtype = sm107_utils.make_sparse_a_dtype(self.a_raw_dtype)
        self.b_dtype: Type[cutlass.Numeric] = b_tensor.element_type
        self.sf_dtype: Type[cutlass.Numeric] = sfa_tensor.element_type
        self.e_raw_dtype: Type[cutlass.Numeric] = e_tensor.element_type
        self.e_sparse_dtype = sm107_utils.make_sparse_e_dtype(self.a_raw_dtype)
        self.c_dtype: Type[cutlass.Numeric] = c_tensor.element_type
        self.acc_dtype: cutlass.Float

        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a_tensor
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b_tensor
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c_tensor)
        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_raw_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_raw_dtype} != {self.b_dtype}")

        # Setup compressed A gmem tensor
        # convert a_tensor to sp_a_gmem_tensor
        # a_tensor dtype is fp4 with K/2 size.
        # sp_a_gmem_tensor dtype is sparse_elem<4,2> fp4 with K size.
        self.sp_a_gmem_tensor = cute.recast_tensor(a_tensor, dtype=self.a_sparse_dtype)

        mnkl = (
            cute.size(a_tensor, mode=[0]),
            cute.size(b_tensor, mode=[0]),
            cute.size(b_tensor, mode=[1]),
            cute.size(a_tensor, mode=[2]),
        )

        # Setup compressed E gmem tensor
        sp_e_ptr = cute.recast_ptr(e_tensor.iterator, dtype=self.e_sparse_dtype)
        self.sp_e_gmem_layout = sm107_utils.make_sparse_gmem_layout_e(
            mnkl,
            self.a_raw_dtype,
        )
        self.sp_e_gmem_tensor = cute.make_tensor(sp_e_ptr, self.sp_e_gmem_layout)

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        sfa_layout = cute.tile_to_shape(
            self.sf_atom, self.sp_a_gmem_tensor.shape, (2, 1, 3)
        )
        sfa_tensor = cute.make_tensor(sfa_tensor.iterator, sfa_layout)

        sfb_layout = cute.tile_to_shape(self.sf_atom, b_tensor.shape, (2, 1, 3))
        sfb_tensor = cute.make_tensor(sfb_tensor.iterator, sfb_layout)

        # Setup optional block-scaled D (SFD) output tensor in SF atom layout
        self.generate_sfd = sfd_ptr is not None
        sfd_tensor = None
        if cutlass.const_expr(self.generate_sfd):
            self.sfd_dtype: Type[cutlass.Numeric] = sfd_ptr.value_type
            self.sfd_vec_size = (
                self.sf_vec_size if sfd_vec_size is None else sfd_vec_size
            )
            if cutlass.const_expr(not self.use_tma_store):
                # The SFD reduction lives in the TMA-store epilogue only.
                raise ValueError("Block-scaled D output requires use_tma_store")
            # Single source of truth for the SFD pre-conditions (see
            # utils.gemm.sm100); raises ValueError at trace time.
            utils.gemm.sm100.validate_sfd_output(
                self.sfd_dtype,
                self.sfd_vec_size,
                self.c_dtype,
                c_is_row_major=self.c_layout
                == cutlass.tensor_utils.LayoutEnum.ROW_MAJOR,
                is_2cta_mma=self.cta_group != tcgen05.CtaGroup.ONE,
                is_b_reuse=self.enable_breuse,
            )
            # Note: N % sfd_vec_size divisibility is enforced by
            # can_implement() on the run()/test path.
            # ((Atom_M, Rest_M),(Atom_N, Rest_N),RestL)
            sfd_layout = blockscaled_utils.tile_atom_to_shape_SF(
                c_tensor.shape, self.sfd_vec_size
            )
            sfd_tensor = cute.make_tensor(sfd_ptr, sfd_layout)

        tiled_mma = self.sm107_make_blockscaled_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
            atom_layout_mnk=(1, 1, 1),
            permutation_mnk=self._get_mma_permutation_mnk(),
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        tiled_mma.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma.set(tcgen05.Field.NEGATE_B, False)

        dummy_tiled_mma_sfb = self.sm107_make_blockscaled_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_mn_sfb,
        )
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = sm103_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        # casting layout as uint8 for multicast
        a_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.a_smem_layout_staged_tma
        )
        a_tensor_uint8 = cute.recast_tensor(a_tensor, cutlass.Uint8)

        tma_atom_a, tma_tensor_a = cute.nvgpu.cpasync.make_tiled_tma_atom(
            a_op,
            a_tensor_uint8,
            a_smem_layout_tma_ready,
            # 192 corresponds to the number of uint8 elements along the K dimension in one mma tile.
            (self.cta_tile_shape_mnk[0], 192),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for B
        b_op = sm103_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        # casting layout as uint8 for multicast
        b_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.b_smem_layout_staged_tma
        )
        b_tensor_uint8 = cute.recast_tensor(b_tensor, cutlass.Uint8)

        tma_atom_b, tma_tensor_b = cute.nvgpu.cpasync.make_tiled_tma_atom(
            b_op,
            b_tensor_uint8,
            b_smem_layout_tma_ready,
            # 384 corresponds to the number of uint8 elements along the K dimension in one mma tile.
            (cute.size(tiled_mma.tv_layout_B[1][0]), 384),
            self.cluster_shape_mn[0] // cute.size(tiled_mma.thr_id.shape),
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for SFA
        sfa_op = sm103_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        sfa_smem_layout_tma_ready = self.adapt_layout_for_tma_sf(sfa_smem_layout)

        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfa_op,
            sfa_tensor,
            sfa_smem_layout_tma_ready,
            (self.mma_sf_tiler[0], self.mma_sf_tiler[2]),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint64,
        )

        # Setup TMA load for SFB
        sfb_op = sm103_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        sfb_smem_layout_tma_ready = self.adapt_layout_for_tma_sf(sfb_smem_layout)

        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfb_op,
            sfb_tensor,
            sfb_smem_layout_tma_ready,
            (self.mma_sf_tiler[1], self.mma_sf_tiler[2]),
            self.cluster_shape_mn[0] // cute.size(dummy_tiled_mma_sfb.thr_id),
            internal_type=cutlass.Uint64,
        )

        # Setup TMA load for E (metadata)
        self.tensor_e_atom_k = cute.size(
            sm107_utils.make_tensor_e_atom_layout(self.a_raw_dtype), mode=[1]
        )
        self.tma_tiler_e = (self.mma_e_tiler_per_tma[0], self.mma_e_tiler_per_tma[2])
        self.e_smem_layout_per_tma = self.sm107_make_smem_layout_e_tma(
            tiled_mma,
            self.mma_e_tiler_per_tma,
            self.num_e_stage,
        )

        tma_atom_e, tma_tensor_e = cute.nvgpu.cpasync.make_tiled_tma_atom(
            a_op,
            self.sp_e_gmem_tensor,
            self.e_smem_layout_per_tma,
            (self.mma_e_tiler_per_tma[0], self.mma_e_tiler_per_tma[2]),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint64,
        )

        # Setup TMA store for C
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(
                self.c_smem_layout_staged,
                mode=list(range(cute.rank(self.c_smem_layout_staged) - 1)),
            )

            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(),
                c_tensor,
                epi_smem_layout,
                self.epi_tile,
            )

        a_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.a_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.a_smem_layout_staged_tma) - 1)),
            ),
        )
        b_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.b_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.b_smem_layout_staged_tma) - 1)),
            ),
        )
        sfa_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.sfa_smem_layout_staged,
                mode=list(range(cute.rank(self.sfa_smem_layout_staged) - 1)),
            ),
        )
        sfb_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.sfb_smem_layout_staged,
                mode=list(range(cute.rank(self.sfb_smem_layout_staged) - 1)),
            ),
        )
        e_copy_size = cute.size_in_bytes(
            self.e_sparse_dtype,
            cute.select(
                self.e_smem_layout_staged,
                mode=list(range(cute.rank(self.e_smem_layout_staged) - 1)),
            ),
        )
        self.num_tma_load_bytes_ab = (a_copy_size + b_copy_size) * atom_thr_size
        self.num_tma_load_bytes_sf = (sfa_copy_size + sfb_copy_size) * atom_thr_size
        self.num_tma_load_bytes_e = e_copy_size * atom_thr_size

        # Compute grid size
        effective_raster_along_m = self.raster_order == "m"
        self.tile_sched_params, grid = self._compute_grid(
            c_tensor,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            max_active_clusters,
            self.swizzle_size,
            effective_raster_along_m,
        )

        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            sf_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            sf_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            e_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_e_stage]
            e_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_e_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_sfa,
            tma_tensor_sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_e,
            tma_tensor_e,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c_tensor,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.e_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            epilogue_op,
            sfd_tensor,
            norm_const_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_e: cute.CopyAtom,
        mE_mkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        e_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
        mSFD_mnl: Optional[cute.Tensor] = None,
        norm_const_tensor: Optional[cute.Tensor] = None,
    ):
        """
        GPU device kernel performing the Persistent batched sparse blockscaled GEMM computation.
        Delegates to kernel_impl with cluster-specific parameters from self.
        """
        self.kernel_impl(
            tiled_mma,
            tma_atom_a,
            mA_mkl,
            tma_atom_b,
            mB_nkl,
            tma_atom_sfa,
            mSFA_mkl,
            tma_atom_sfb,
            mSFB_nkl,
            tma_atom_e,
            mE_mkl,
            tma_atom_c,
            mC_mnl,
            cluster_layout_vmnk,
            cluster_layout_sfb_vmnk,
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            e_smem_layout_staged,
            c_smem_layout_staged,
            epi_tile,
            tile_sched_params,
            epilogue_op,
            self.cluster_shape_mn,
            self.is_a_mcast,
            self.is_b_mcast,
            self.is_e_mcast,
            self.sf_vec_size,
            mSFD_mnl,
            norm_const_tensor,
        )

    @cute.jit
    def kernel_impl(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_e: cute.CopyAtom,
        mE_mkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        e_smem_layout_staged: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
        cluster_shape_mn: Tuple[int, int],
        is_a_mcast: bool,
        is_b_mcast: bool,
        is_e_mcast: bool,
        sf_vec_size: cutlass.Constexpr,
        mSFD_mnl: Optional[cute.Tensor] = None,
        norm_const_tensor: Optional[cute.Tensor] = None,
    ):
        """
        GPU device kernel implementation performing the Persistent batched sparse blockscaled GEMM computation.
        Accepts cluster-specific parameters as arguments to support mixed cluster launches.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_ab_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)
        if warp_idx == self.tma_sf_warp_id:
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)
        if warp_idx == self.tma_e_warp_id:
            cpasync.prefetch_descriptor(tma_atom_e)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()
        is_leader_tid = (tidx % 32) == 0
        is_leader_block = bidx == 0 and bidy == 0 and bidz == 0

        #
        # Alloc and init: a+b full/empty, sfa+sfb full/empty, e full/empty,
        # accumulator full/empty, tensor memory dealloc barrier
        #
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes_ab,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        # Initialize mainloop sf_pipeline (barrier) and states
        sf_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        sf_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        sf_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.sf_full_mbar_ptr.data_ptr(),
            num_stages=self.num_sf_stage,
            producer_group=sf_pipeline_producer_group,
            consumer_group=sf_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes_sf,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        # Initialize mainloop e_pipeline (barrier) and states
        # E (sparsity metadata) only follows A's multicast pattern, no B component
        e_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        e_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        e_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.e_full_mbar_ptr.data_ptr(),
            num_stages=self.num_e_stage,
            producer_group=e_pipeline_producer_group,
            consumer_group=e_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes_e,
            cta_layout_vmnk=cluster_layout_vmnk,
            mcast_mode_mn=(1, 0),
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if use_2cta_instrs else 1
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

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem_dealloc_barrier = None
        if cutlass.const_expr(not self.use_tma_store):
            tmem_dealloc_barrier = pipeline.NamedBarrier(
                barrier_id=self.tmem_dealloc_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
            arch=self.arch,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/SFA/SFB/E
        #

        sA = smem.allocate_tensor(
            element_type=cutlass.Uint8,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        sB = smem.allocate_tensor(
            element_type=cutlass.Uint8,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )
        sSFA = smem.allocate_tensor(
            element_type=self.sf_dtype,
            layout=sfa_smem_layout_staged,
            byte_alignment=128,
            swizzle=None,
        )
        sSFB = smem.allocate_tensor(
            element_type=self.sf_dtype,
            layout=sfb_smem_layout_staged,
            byte_alignment=128,
            swizzle=None,
        )
        sE = smem.allocate_tensor(
            element_type=self.e_sparse_dtype,
            layout=e_smem_layout_staged,
            byte_alignment=128,
            swizzle=None,
        )

        #
        # Compute multicast mask for A/B/SFA/SFB/E buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        sfa_full_mcast_mask = None
        sfb_full_mcast_mask = None
        e_full_mcast_mask = None
        if cutlass.const_expr(
            is_a_mcast or is_b_mcast or is_e_mcast or use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )
            e_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )

        #
        # Local_tile partition global tensors
        #
        # (BLK_M, BLK_K, m, k, l)
        gA_mkl = cute.local_tile(
            mA_mkl,
            # 192 corresponds to the number of uint8 elements along the K dimension in one mma tile.
            cute.slice_((self.mma_tiler[0], self.mma_tiler[1], 192), (None, 0, None)),
            (None, None, None),
        )
        # (BLK_N, BLK_K, n, k, l)
        gB_nkl = cute.local_tile(
            mB_nkl,
            # 384 corresponds to the number of uint8 elements along the K dimension in one mma tile.
            cute.slice_((self.mma_tiler[0], self.mma_tiler[1], 384), (0, None, None)),
            (None, None, None),
        )
        gSFA_mkl = cute.local_tile(
            mSFA_mkl,
            cute.slice_(self.mma_sf_tiler, (None, 0, None)),
            (None, None, None),
        )
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_sf_tiler, (0, None, None)),
            (None, None, None),
        )
        gE_mkl = cute.local_tile(
            mE_mkl,
            cute.slice_(self.mma_e_tiler, (None, 0, None)),
            (None, None, None),
        )
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gB_nkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)

        # create tCgA_tmp
        tCgA_mkl_tmp = thr_mma.partition_A(gA_mkl)
        tCgA_layout = self.append_coalesce_layout(tCgA_mkl_tmp.layout)
        cta_tCgA = cute.make_tensor(tCgA_mkl_tmp.iterator, tCgA_layout)

        # ((CTA_MMA_M,256),Rest_MMA_M,Rest_MMA_K, m, k, l)
        num_tma_a_copy_uint8_elements = 64
        tCgA = cute.make_tensor(
            cta_tCgA.iterator,
            cute.tiled_divide(
                cta_tCgA.layout,
                (cute.size(self.cta_tile_shape_mnk[0]), num_tma_a_copy_uint8_elements),
            ),
        )
        tCgB_nkl_tmp = thr_mma.partition_B(gB_nkl)
        tCgB_layout = self.append_coalesce_layout(tCgB_nkl_tmp.layout)
        cta_tCgB = cute.make_tensor(tCgB_nkl_tmp.iterator, tCgB_layout)
        # ((CTA_MMA_N,256),Rest_MMA_N, Rest_MMA_K, n, k, l)
        num_tma_b_copy_uint8_elements = 128
        tCgB = cute.make_tensor(
            cta_tCgB.iterator,
            cute.tiled_divide(
                cta_tCgB.layout,
                (cute.size(tiled_mma.tv_layout_B[1][0]), num_tma_b_copy_uint8_elements),
            ),
        )

        self.mma_sf_inst_shape_m = self.mma_inst_shape_mnk[0] // cute.size(
            tiled_mma.thr_layout_vmnk.shape[0]
        )

        tCgSFA = cute.make_tensor(
            gSFA_mkl.iterator,
            cute.tiled_divide(
                gSFA_mkl.layout,
                (
                    self.mma_sf_inst_shape_m,
                    self.sf_vec_size * 4,
                ),
            ),
        )

        tCgSFB = cute.make_tensor(
            gSFB_nkl.iterator,
            cute.tiled_divide(
                gSFB_nkl.layout, (self.mma_sf_tiler[1], self.sf_vec_size * 4)
            ),
        )

        tCgE = cute.make_tensor(
            gE_mkl.iterator,
            cute.tiled_divide(
                gE_mkl.layout,
                (
                    self.mma_sf_inst_shape_m,
                    128,
                ),
            ),
        )

        tCgC = thr_mma.partition_C(gC_mnl)

        # Create identity tensor for C to use in epilogue predication
        idC = cute.make_identity_tensor(mC_mnl.shape)
        cC_mnl = cute.local_tile(
            idC, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCcC = thr_mma.partition_C(cC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B/SFA/SFB/E
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )

        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 1),
        )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )

        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 1),
        )

        # TMA load SFA partition_S/D
        sfa_cta_layout = a_cta_layout

        tAsSFA, tAgSFA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfa,
            block_in_cluster_coord_vmnk[2],
            sfa_cta_layout,
            cute.group_modes(sSFA, 0, 3),
            cute.group_modes(tCgSFA, 0, 3),
        )
        tAsSFA_compact = cute.filter_zeros(tAsSFA)

        # TMA load SFB partition_S/D
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )

        tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB_compact = cute.filter_zeros(tBsSFB)

        # TMA load E partition_S/D
        tEsE, tEgE = cpasync.tma_partition(
            tma_atom_e,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sE, 0, 3),
            cute.group_modes(tCgE, 0, 3),
        )
        tEsE_compact = cute.filter_zeros(tEsE)

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=cluster_shape_mn)

        #
        # Construct the scheduler
        #
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp for A/B tensors
        #
        if warp_idx == self.tma_ab_warp_id:
            #
            # Persistent tile scheduling loop for AB loads
            #
            buffers_per_k_tile = 3

            ab_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_ab_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                tAgA_slice = tAgA[
                    (
                        None,
                        None,
                        None,
                        mma_tile_coord_mnl[0],
                        None,
                        mma_tile_coord_mnl[2],
                    )
                ]
                tBgB_slice = tBgB[
                    (
                        None,
                        None,
                        None,
                        mma_tile_coord_mnl[1],
                        None,
                        mma_tile_coord_mnl[2],
                    )
                ]

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer_state.reset_count()
                peek_ab_empty_status = cutlass.Boolean(1)
                peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                    ab_producer_state
                )

                #
                # TMA load loop for A/B tensors
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Load buffers_per_k_tile buffers
                    for buffer in cutlass.range(buffers_per_k_tile, unroll_full=True):
                        # Acquire next empty AB buffer
                        ab_pipeline.producer_acquire(
                            ab_producer_state, peek_ab_empty_status
                        )

                        # TMA load A/B
                        cute.copy(
                            tma_atom_a,
                            tAgA_slice[(None, cur_tile_coord[0], buffer, k_tile)],
                            tAsA[(None, ab_producer_state.index)],
                            tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                ab_producer_state
                            ),
                            mcast_mask=a_full_mcast_mask,
                        )
                        cute.copy(
                            tma_atom_b,
                            cute.group_modes(
                                tBgB_slice[(None, None, buffer, k_tile)], 0, 2
                            ),
                            tBsB[(None, ab_producer_state.index)],
                            tma_bar_ptr=ab_pipeline.producer_get_barrier(
                                ab_producer_state
                            ),
                            mcast_mask=b_full_mcast_mask,
                        )

                        # Peek (try_wait) AB buffer empty for next buffer
                        ab_producer_state.advance()
                        peek_ab_empty_status = cutlass.Boolean(1)
                        # Check if we're not at the last buffer of the last k_tile
                        if not (
                            (k_tile == k_tile_cnt - 1)
                            and (buffer == buffers_per_k_tile - 1)
                        ):
                            peek_ab_empty_status = ab_pipeline.producer_try_acquire(
                                ab_producer_state
                            )

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Signal end of AB loads
            ab_pipeline.producer_tail(ab_producer_state)

        #
        # Specialized TMA load warp for scale factor tensors
        #
        if warp_idx == self.tma_sf_warp_id:
            #
            # Persistent tile scheduling loop for SF loads
            #
            sf_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_sf_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0],
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                tAgSFA_slice = tAgSFA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                tBgSFB_slice = tBgSFB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # Peek (try_wait) SF buffer empty
                sf_producer_state.reset_count()
                peek_sf_empty_status = cutlass.Boolean(1)
                peek_sf_empty_status = sf_pipeline.producer_try_acquire(
                    sf_producer_state
                )

                #
                # TMA load loop for scale factors
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Load SF stages based on sf_buffers_per_tile_k
                    for sf_stage in cutlass.range(
                        self.sf_buffers_per_tile_k, unroll_full=False
                    ):
                        # Acquire next empty SF buffer
                        sf_pipeline.producer_acquire(
                            sf_producer_state, peek_sf_empty_status
                        )

                        tAgSFA_compact = cute.filter_zeros(
                            tAgSFA_slice[
                                (None, k_tile * self.sf_buffers_per_tile_k + sf_stage)
                            ]
                        )
                        tBgSFB_compact = cute.filter_zeros(
                            tBgSFB_slice[
                                (None, k_tile * self.sf_buffers_per_tile_k + sf_stage)
                            ]
                        )

                        # TMA load SFA/SFB for this SF stage
                        cute.copy(
                            tma_atom_sfa,
                            tAgSFA_compact,
                            tAsSFA_compact[(None, sf_producer_state.index)],
                            tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                sf_producer_state
                            ),
                            mcast_mask=sfa_full_mcast_mask,
                        )
                        cute.copy(
                            tma_atom_sfb,
                            tBgSFB_compact,
                            tBsSFB_compact[(None, sf_producer_state.index)],
                            tma_bar_ptr=sf_pipeline.producer_get_barrier(
                                sf_producer_state
                            ),
                            mcast_mask=sfb_full_mcast_mask,
                        )

                        # Peek (try_wait) SF buffer empty for next stage
                        sf_producer_state.advance()
                        peek_sf_empty_status = cutlass.Boolean(1)
                        # Check if we're not at the last stage of the last k_tile
                        if not (
                            k_tile == k_tile_cnt - 1
                            and sf_stage == self.sf_buffers_per_tile_k - 1
                        ):
                            peek_sf_empty_status = sf_pipeline.producer_try_acquire(
                                sf_producer_state
                            )

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Signal end of SF loads
            sf_pipeline.producer_tail(sf_producer_state)

        #
        # Specialized TMA load warp for metadata E
        #
        if warp_idx == self.tma_e_warp_id:
            e_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_e_stage
            )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0],
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                tEgE_slice = tEgE[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]

                e_producer_state.reset_count()
                peek_e_empty_status = cutlass.Boolean(1)
                peek_e_empty_status = e_pipeline.producer_try_acquire(e_producer_state)

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Load E stages based on e_buffers_per_tile_k
                    for e_stage in cutlass.range(
                        self.e_buffers_per_tile_k, unroll_full=False
                    ):
                        e_pipeline.producer_acquire(
                            e_producer_state, peek_e_empty_status
                        )
                        tEgE_compact = cute.filter_zeros(
                            tEgE_slice[
                                (None, k_tile * self.e_buffers_per_tile_k + e_stage)
                            ]
                        )
                        cute.copy(
                            tma_atom_e,
                            tEgE_compact,
                            tEsE_compact[(None, e_producer_state.index)],
                            tma_bar_ptr=e_pipeline.producer_get_barrier(
                                e_producer_state
                            ),
                            mcast_mask=e_full_mcast_mask,
                        )

                        e_producer_state.advance()
                        peek_e_empty_status = cutlass.Boolean(1)
                        if not (
                            k_tile == k_tile_cnt - 1
                            and e_stage == self.e_buffers_per_tile_k - 1
                        ):
                            peek_e_empty_status = e_pipeline.producer_try_acquire(
                                e_producer_state
                            )

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            e_pipeline.producer_tail(e_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator/SFA/SFB/E tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # Make accumulator tmem tensor
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Make SFA tmem tensor
            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base),
                dtype=self.sf_dtype,
            )
            sfa_smem_per_stage = cute.slice_(
                sfa_smem_layout_staged, (None, None, None, 0)
            )

            tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                sfa_smem_per_stage,
            )

            MMA_M = self.mma_sf_tiler[0]
            MMA_N_SF = self.mma_sf_tiler[1]
            MMA_K_SF = self.mma_sf_tiler[2]
            mnBasicBlockShape = (32, 4)
            kBasicBlockShape_single = (self.sf_vec_size, 1)
            mma_iter_SFA_shape = (
                (mnBasicBlockShape, self.mma_sf_inst_shape_m // 128),
                kBasicBlockShape_single,
            )
            sSFA_iter_shape = (
                mma_iter_SFA_shape,
                self.mma_sf_tiler[0] // self.mma_sf_inst_shape_m,  # breuse dim
                MMA_K_SF // self.sf_vec_size,
            )
            sSFA_iter_layout = cute.make_layout(sSFA_iter_shape)
            mma_iter_SFB_shape = (
                (mnBasicBlockShape, MMA_N_SF // 128),
                kBasicBlockShape_single,
            )
            sSFB_iter_shape = (mma_iter_SFB_shape, 1, MMA_K_SF // self.sf_vec_size)
            sSFB_iter_layout = cute.make_layout(sSFB_iter_shape)

            tCtSFA_layout_mma = blockscaled_utils.make_tmem_layout_sfa(
                tiled_mma, self.mma_tiler, self.sf_vec_size, sSFA_iter_layout
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)
            tCtSFA_mma = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout_mma)

            # Make SFB tmem tensor
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr
                + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                + tcgen05.find_tmem_tensor_col_offset(tCtSFA),
                dtype=self.sf_dtype,
            )
            sfb_smem_per_stage = cute.slice_(
                sfb_smem_layout_staged, (None, None, None, 0)
            )
            tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma,
                self.mma_tiler,
                self.sf_vec_size,
                sfb_smem_per_stage,
            )
            tCtSFB_layout_mma = blockscaled_utils.make_tmem_layout_sfb(
                tiled_mma, self.mma_tiler, self.sf_vec_size, sSFB_iter_layout
            )
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)
            tCtSFB_mma = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout_mma)

            # Make E tmem tensor

            e_tmem_shape = self.sm107_get_tmem_layout_e(
                self.mma_inst_shape_mnk,
                self.mma_e_tiler,
                self.a_raw_dtype,
                self.enable_E_tmem_reuse,
            ).shape
            # e_tmem_shape: ((128, 128), 3, 2)
            # if enable_E_tmem_reuse is True, then e_tmem_shape: ((128, 128), 2, 2)

            e_tmem_layout = sm107_utils.make_sparse_tmem_layout_e(
                e_tmem_shape,
                self.a_raw_dtype,
            )
            e_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr
                + tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
                + tcgen05.find_tmem_tensor_col_offset(tCtSFA)
                + tcgen05.find_tmem_tensor_col_offset(tCtSFB),
                dtype=self.e_sparse_dtype,
            )
            tCtE = cute.make_tensor(e_tmem_ptr, e_tmem_layout)

            tCtE_mma = cute.recast_tensor(tCtE, cutlass.Uint8)

            # # Setup UTCCP copy for metadata (SMEM to TMEM)
            (
                tiled_copy_s2t_E,
                tCsE_compact_s2t,
                tCtE_compact_s2t,
            ) = self.mainloop__s2t_copy_and_partition_for_e(sE, tCtE)

            #
            # Partition for S2T copy of SFA/SFB
            #
            (
                tiled_copy_s2t_sfa,
                tCsSFA_compact_s2t,
                tCtSFA_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition_for_sf(sSFA, tCtSFA)
            (
                tiled_copy_s2t_sfb,
                tCsSFB_compact_s2t,
                tCtSFB_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition_for_sf(sSFB, tCtSFB)

            #
            # Persistent tile scheduling loop
            #
            ab_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_ab_stage
            )
            sf_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sf_stage
            )
            e_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_e_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Reshape sA from ((CTA_M,16),1,k_blks,stages) to ((MMA_M,16),CTA_M//MMA_M,k_blks,stages)
                # dim-1 is used for b-keep and b-reuse pattern.
                tCrA = cute.make_tensor(
                    sA.iterator,
                    self.sm107_make_smem_layout_a_for_mma(
                        tiled_mma,
                        self.mma_tiler,
                        self.mma_inst_shape_mnk,
                        self.num_ab_stage,
                    ).outer,
                )

                tCtAcc = tCtAcc_base[(None, 0, 0, acc_producer_state.index)]
                tCtAcc_keep = tCtAcc_base[(None, 0, 0, acc_producer_state.index)]
                tCtAcc_reuse = tCtAcc_base[(None, 1, 0, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer_state.reset_count()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_pipeline.consumer_try_wait(
                        ab_consumer_state
                    )

                # Peek (try_wait) SF buffer full
                sf_consumer_state.reset_count()
                peek_sf_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_sf_full_status = sf_pipeline.consumer_try_wait(
                        sf_consumer_state
                    )

                # Peek (try_wait) E buffer full
                e_consumer_state.reset_count()
                peek_e_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_e_full_status = e_pipeline.consumer_try_wait(e_consumer_state)

                # Reset the ACCUMULATE field for each tile
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                is_first_iteration = True

                def get_ab_smem_index(ab_consumer_state):
                    # get pipeline consumer_state index use in 1 k_tile
                    # 3 ab_consumer_state

                    # get ab_smem_index
                    ab_consumer_state_clone = ab_consumer_state.clone()

                    ab_smem_index = [ab_consumer_state.index]
                    ab_consumer_state_clone = ab_consumer_state.clone()
                    for _ in cutlass.range_constexpr(3):
                        ab_consumer_state_clone.advance()
                        ab_smem_index.append(ab_consumer_state_clone.index)

                    return ab_smem_index

                if cutlass.const_expr(self.enable_breuse):

                    def slice_e_smem_buffer(
                        tCsE_compact_s2t, e_index, mma_idx, enable_E_tmem_reuse=False
                    ):
                        """
                        Slice tCsE_compact_s2t by stage index and mma_idx, then
                        reshape with the tmem-reuse layout.

                        E Tmem Reuse:
                            E Tmem Reuse is used to reduce E tmem usage.
                            utccp E Atom Shape: (128,128)
                            without Tmem Reuse:
                                one utccp instruction shape: ((128,128),3,2)
                                E in Tmem shape: ((128,128),3,2)
                            with Tmem Reuse:
                                E in Tmem Shape: ((128,128),2,2). E tmem usage is reduced.
                                now we need 2 utccp instructions to copy E to Tmem.
                                every utccp instruction shape is ((128,128),2,2).
                        """

                        if cutlass.const_expr(enable_E_tmem_reuse == False):
                            return tCsE_compact_s2t[(None, None, None, None, e_index)]
                        else:
                            tCsE_compact_s2t_iter = tCsE_compact_s2t[
                                (None, None, None, None, e_index)
                            ]
                            # tmem_reuse_enabled layout:
                            #   (((128,1),1),1,2,2):(((1,1),0),0,256,128)
                            tCsE_compact_s2t_iter_layout = cute.make_layout(
                                shape=(((128, 1), 1), 1, 2, 2),
                                stride=(((1, 1), 0), 0, 256, 128),
                            )
                            need_update = mma_idx % 2
                            if cutlass.const_expr(need_update):
                                tCsE_compact_s2t_iter = tCsE_compact_s2t_iter[
                                    (None, None, 1, None)
                                ]
                            return cute.make_tensor(
                                tCsE_compact_s2t_iter.iterator,
                                tCsE_compact_s2t_iter_layout,
                            )

                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        if is_leader_cta:
                            # get 3 ab_smem_index used in this k_tile
                            ab_smem_index = get_ab_smem_index(ab_consumer_state)

                            ########
                            # MMA0 #
                            ########
                            mma_idx = 0

                            # pre slice SF
                            s2t_stage_coord = (
                                None,
                                None,
                                None,
                                None,
                                sf_consumer_state.index,
                            )
                            tCsSFA_compact_s2t_sliced = tCsSFA_compact_s2t[
                                s2t_stage_coord
                            ]
                            tCsSFB_compact_s2t_sliced = tCsSFB_compact_s2t[
                                s2t_stage_coord
                            ]

                            # pre slice E
                            tCsE_compact_s2t_sliced = slice_e_smem_buffer(
                                tCsE_compact_s2t,
                                e_consumer_state.index,
                                mma_idx,
                                self.enable_E_tmem_reuse,
                            )

                            # wait E
                            e_pipeline.consumer_wait(
                                e_consumer_state, peek_e_full_status
                            )

                            # wait SF
                            sf_pipeline.consumer_wait(
                                sf_consumer_state, peek_sf_full_status
                            )

                            # utccp SF
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t_sliced,
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t_sliced,
                                tCtSFB_compact_s2t,
                            )

                            # utccp E
                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t_sliced,
                                tCtE_compact_s2t,
                            )

                            # Wait for A/B data to be ready(MMA0, MMA1)
                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state0 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            # Peek (try_wait) AB buffer full for the next AB consume
                            # (always within this k_tile, no guard needed)
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                            # delay the acc acquire to ublock tmem
                            if is_first_iteration:
                                acc_pipeline.producer_acquire(acc_producer_state)
                                is_first_iteration = False

                            # MMA0
                            self.mma_bkeep_breuse(
                                mma_idx,
                                ab_smem_index,
                                tCrA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc_keep,
                                tCtAcc_reuse,
                            )

                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                            # release SF
                            sf_pipeline.consumer_release(sf_consumer_state)
                            sf_consumer_state.advance()
                            # Peek (try_wait) SF buffer full for the next SF consume
                            peek_sf_full_status = sf_pipeline.consumer_try_wait(
                                sf_consumer_state
                            )

                            ########
                            # MMA1 #
                            ########
                            mma_idx = 1

                            tCsE_compact_s2t_sliced = slice_e_smem_buffer(
                                tCsE_compact_s2t,
                                e_consumer_state.index,
                                mma_idx,
                                self.enable_E_tmem_reuse,
                            )

                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state1 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            # Peek (try_wait) AB buffer full for the next AB consume
                            # (always within this k_tile, no guard needed)
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t_sliced,
                                tCtE_compact_s2t,
                            )

                            self.mma_bkeep_breuse(
                                mma_idx,
                                ab_smem_index,
                                tCrA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc_keep,
                                tCtAcc_reuse,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state0)

                            e_pipeline.consumer_release(e_consumer_state)
                            e_consumer_state.advance()
                            # Peek (try_wait) E buffer full for the next E consume
                            peek_e_full_status = e_pipeline.consumer_try_wait(
                                e_consumer_state
                            )

                            ########
                            # MMA2 #
                            ########
                            mma_idx = 2

                            s2t_stage_coord = (
                                None,
                                None,
                                None,
                                None,
                                sf_consumer_state.index,
                            )
                            tCsSFA_compact_s2t_sliced = tCsSFA_compact_s2t[
                                s2t_stage_coord
                            ]
                            tCsSFB_compact_s2t_sliced = tCsSFB_compact_s2t[
                                s2t_stage_coord
                            ]

                            tCsE_compact_s2t_sliced = slice_e_smem_buffer(
                                tCsE_compact_s2t,
                                e_consumer_state.index,
                                mma_idx,
                                self.enable_E_tmem_reuse,
                            )

                            e_pipeline.consumer_wait(
                                e_consumer_state, peek_e_full_status
                            )

                            if cutlass.const_expr(sf_vec_size == 32):
                                sf_pipeline.consumer_wait(
                                    sf_consumer_state, peek_sf_full_status
                                )

                            if cutlass.const_expr(sf_vec_size == 32):
                                cute.copy(
                                    tiled_copy_s2t_sfa,
                                    tCsSFA_compact_s2t_sliced,
                                    tCtSFA_compact_s2t,
                                )
                                cute.copy(
                                    tiled_copy_s2t_sfb,
                                    tCsSFB_compact_s2t_sliced,
                                    tCtSFB_compact_s2t,
                                )

                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t_sliced,
                                tCtE_compact_s2t,
                            )

                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state2 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            # Peek (try_wait) AB buffer full for the next k_tile
                            peek_ab_full_status = cutlass.Boolean(1)
                            if ab_consumer_state.count < 3 * k_tile_cnt:
                                peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                    ab_consumer_state
                                )

                            # delay the acc acquire to ublock tmem
                            if is_first_iteration:
                                acc_pipeline.producer_acquire(acc_producer_state)
                                is_first_iteration = False

                            self.mma_bkeep_breuse(
                                mma_idx,
                                ab_smem_index,
                                tCrA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc_keep,
                                tCtAcc_reuse,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state1)

                            if cutlass.const_expr(sf_vec_size == 32):
                                sf_pipeline.consumer_release(sf_consumer_state)
                                sf_consumer_state.advance()
                                peek_sf_full_status = cutlass.Boolean(1)
                                if k_tile + 1 < k_tile_cnt:
                                    peek_sf_full_status = sf_pipeline.consumer_try_wait(
                                        sf_consumer_state
                                    )

                            ########
                            # MMA3 #
                            ########
                            mma_idx = 3
                            tCsE_compact_s2t_sliced = slice_e_smem_buffer(
                                tCsE_compact_s2t,
                                e_consumer_state.index,
                                mma_idx,
                                self.enable_E_tmem_reuse,
                            )
                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t_sliced,
                                tCtE_compact_s2t,
                            )

                            self.mma_bkeep_breuse(
                                mma_idx,
                                ab_smem_index,
                                tCrA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc_keep,
                                tCtAcc_reuse,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state2)

                            e_pipeline.consumer_release(e_consumer_state)
                            e_consumer_state.advance()
                            peek_e_full_status = cutlass.Boolean(1)
                            if k_tile + 1 < k_tile_cnt:
                                peek_e_full_status = e_pipeline.consumer_try_wait(
                                    e_consumer_state
                                )

                else:
                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        if is_leader_cta:
                            ab_smem_index = get_ab_smem_index(ab_consumer_state)

                            sf_pipeline.consumer_wait(
                                sf_consumer_state, peek_sf_full_status
                            )
                            e_pipeline.consumer_wait(
                                e_consumer_state, peek_e_full_status
                            )
                            s2t_stage_coord = (
                                None,
                                None,
                                None,
                                None,
                                sf_consumer_state.index,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[s2t_stage_coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[s2t_stage_coord],
                                tCtSFB_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t[
                                    (None, None, None, None, e_consumer_state.index)
                                ],
                                tCtE_compact_s2t,
                            )
                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state0 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            # Peek (try_wait) AB buffer full for the next AB consume
                            # (always within this k_tile, no guard needed)
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                            # delay the acc acquire to ublock tmem
                            if is_first_iteration:
                                acc_pipeline.producer_acquire(acc_producer_state)
                                is_first_iteration = False

                            # MMA0
                            self.mma_no_breuse(
                                0,
                                ab_smem_index,
                                sA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc,
                            )
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                            sf_pipeline.consumer_release(sf_consumer_state)
                            sf_consumer_state.advance()
                            peek_sf_full_status = cutlass.Boolean(1)
                            if cutlass.const_expr(sf_vec_size == 32):
                                peek_sf_full_status = sf_pipeline.consumer_try_wait(
                                    sf_consumer_state
                                )
                            else:
                                if k_tile + 1 < k_tile_cnt:
                                    peek_sf_full_status = sf_pipeline.consumer_try_wait(
                                        sf_consumer_state
                                    )
                            e_pipeline.consumer_release(e_consumer_state)
                            e_consumer_state.advance()
                            peek_e_full_status = cutlass.Boolean(1)
                            peek_e_full_status = e_pipeline.consumer_try_wait(
                                e_consumer_state
                            )

                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state1 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            # Peek (try_wait) AB buffer full for the next AB consume
                            # (always within this k_tile, no guard needed)
                            peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                ab_consumer_state
                            )

                            # MMA1
                            self.mma_no_breuse(
                                1,
                                ab_smem_index,
                                sA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state0)

                            if cutlass.const_expr(sf_vec_size == 32):
                                sf_pipeline.consumer_wait(
                                    sf_consumer_state, peek_sf_full_status
                                )
                            e_pipeline.consumer_wait(
                                e_consumer_state, peek_e_full_status
                            )
                            if cutlass.const_expr(sf_vec_size == 32):
                                s2t_stage_coord = (
                                    None,
                                    None,
                                    None,
                                    None,
                                    sf_consumer_state.index,
                                )
                                cute.copy(
                                    tiled_copy_s2t_sfa,
                                    tCsSFA_compact_s2t[s2t_stage_coord],
                                    tCtSFA_compact_s2t,
                                )
                                cute.copy(
                                    tiled_copy_s2t_sfb,
                                    tCsSFB_compact_s2t[s2t_stage_coord],
                                    tCtSFB_compact_s2t,
                                )
                            cute.copy(
                                tiled_copy_s2t_E,
                                tCsE_compact_s2t[
                                    (None, None, None, None, e_consumer_state.index)
                                ],
                                tCtE_compact_s2t,
                            )
                            ab_pipeline.consumer_wait(
                                ab_consumer_state, peek_ab_full_status
                            )
                            ab_consumer_state2 = ab_consumer_state.clone()
                            ab_consumer_state.advance()
                            peek_ab_full_status = cutlass.Boolean(1)
                            if ab_consumer_state.count < 3 * k_tile_cnt:
                                peek_ab_full_status = ab_pipeline.consumer_try_wait(
                                    ab_consumer_state
                                )

                            # MMA2
                            self.mma_no_breuse(
                                2,
                                ab_smem_index,
                                sA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state1)

                            if cutlass.const_expr(sf_vec_size == 32):
                                sf_pipeline.consumer_release(sf_consumer_state)
                                sf_consumer_state.advance()
                                peek_sf_full_status = cutlass.Boolean(1)
                                if k_tile + 1 < k_tile_cnt:
                                    peek_sf_full_status = sf_pipeline.consumer_try_wait(
                                        sf_consumer_state
                                    )
                            e_pipeline.consumer_release(e_consumer_state)
                            e_consumer_state.advance()
                            peek_e_full_status = cutlass.Boolean(1)
                            if k_tile + 1 < k_tile_cnt:
                                peek_e_full_status = e_pipeline.consumer_try_wait(
                                    e_consumer_state
                                )

                            # MMA3
                            self.mma_no_breuse(
                                3,
                                ab_smem_index,
                                sA,
                                sB,
                                tCtSFA_mma,
                                tCtSFB_mma,
                                tCtE_mma,
                                tiled_mma,
                                tCtAcc,
                            )

                            ab_pipeline.consumer_release(ab_consumer_state2)

                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Wait for accumulator buffer empty

            acc_pipeline.producer_tail(acc_producer_state)

        sC = None
        if cutlass.const_expr(self.use_tma_store):
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sC = smem.allocate_tensor(
                element_type=self.c_dtype,
                layout=c_smem_layout_staged.outer,
                byte_alignment=128,
                swizzle=c_smem_layout_staged.inner,
            )

        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)

            tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop for epilogue
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            if cutlass.const_expr(self.use_tma_store):
                assert tma_atom_c is not None and sC is not None
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilogue_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage, producer_group=c_producer_group
                )
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                #
                # Pre-advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

                num_tiles_executed = tile_sched.num_tiles_executed
                if cutlass.const_expr(self.use_tma_store):
                    sfd_config = None
                    if cutlass.const_expr(mSFD_mnl is not None):
                        # Validating factory: every config that reaches the
                        # epilogue has passed the SFD pre-condition checks.
                        sfd_config = utils.gemm.sm100.make_sfd_output_config(
                            mSFD_mnl,
                            self.sfd_vec_size,
                            self.c_dtype,
                            norm_const_tensor,
                            c_is_row_major=self.c_layout
                            == cutlass.tensor_utils.LayoutEnum.ROW_MAJOR,
                            is_2cta_mma=self.cta_group != tcgen05.CtaGroup.ONE,
                            is_b_reuse=self.enable_breuse,
                        )
                    acc_consumer_state = utils.gemm.sm100.epilogue_tma_store(
                        self,
                        tidx,
                        warp_idx,
                        tma_atom_c,
                        tCtAcc,
                        sC,
                        tCgC,
                        epi_tile,
                        num_tiles_executed,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        c_pipeline,
                        sfd_config=sfd_config,
                    )
                else:
                    acc_consumer_state = utils.gemm.sm100.epilogue(
                        self,
                        tidx,
                        tCtAcc,
                        tCgC,
                        epi_tile,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                        tCcC,
                        mC_mnl,
                    )

            if cutlass.const_expr(self.use_tma_store):
                # Wait for C store complete
                c_pipeline.producer_tail()
            else:
                # Synchronize before TMEM dealloc (done by the caller)
                tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

    @staticmethod
    def make_desc_and_call_mma(
        tiled_mma: cute.TiledMma,
        d: cute.Tensor,
        sA_cur: cute.Tensor,
        sA_next: cute.Tensor,
        sfA: cute.Tensor,
        e: cute.Tensor,
        sB_cur: cute.Tensor,
        sB_next: cute.Tensor,
        sfB: cute.Tensor,
        c: cute.Tensor,
    ) -> None:
        """Specialized sparse blockscaled GEMM for circular-buffered A/B from SMEM.

        Performs D <- A * SFA * B * SFB + C where A and B are described by circular
        SMEM descriptors constructed from the (current, next) buffers. C and D may alias.

        Some tcgen05 MMAs require explicitly toggling an accumulate field outside of
        this routine; the caller is responsible for that.

        All tensors must already be partitioned for the provided tiled MMA.

        For MMA Atoms that require single-threaded execution, the gemm op automatically handles thread
        election internally. Manual thread selection is not required in such cases.

        :param atom: MMA atom
        :type atom: cute.MmaAtom
        :param d: Destination tensor
        :type d: cute.Tensor
        :param sA_cur: Current shared memory tensor for operand A
        :type sA_cur: cute.Tensor
        :param sA_next: Next shared memory tensor for operand A, used for circular buffering
        :type sA_next: cute.Tensor
        :param sfA: Scale factor tensor for operand A
        :type sfA: cute.Tensor
        :param e: Sparse metadata tensor E, encoding the 4:2 sparsity pattern of A
        :type e: cute.Tensor
        :param sB_cur: Current shared memory tensor for operand B
        :type sB_cur: cute.Tensor
        :param sB_next: Next shared memory tensor for operand B, used for circular buffering
        :type sB_next: cute.Tensor
        :param sfB: Scale factor tensor for operand B
        :type sfB: cute.Tensor
        :param c: Third source tensor
        :type c: cute.Tensor
        :return: None
        :rtype: None
        """
        a_desc = tcgen05.make_umma_smem_desc(
            sA_cur.iterator,
            sA_cur.layout,
            "k" if tiled_mma.op.a_major_mode.name == "K" else "mn",
            next_src=sA_next.iterator,
        )
        b_desc = tcgen05.make_umma_smem_desc(
            sB_cur.iterator,
            sB_cur.layout,
            "k" if tiled_mma.op.b_major_mode.name == "K" else "mn",
            next_src=sB_next.iterator,
        )

        view_layout = cute.make_layout(1, stride=0)
        a_tensor = cute.make_tensor(a_desc, view_layout)
        b_tensor = cute.make_tensor(b_desc, view_layout)
        cute.mma_atom_call(tiled_mma, d, [a_tensor, sfA, e], [b_tensor, sfB], c)

    def set_mma_operand(
        self,
        mma_idx,
        ab_smem_index,
        sA,
        sB,
        tCtSFA_mma,
        tCtSFB_mma,
        tCtE_mma,
        vec_size,
    ):
        """Compute MMA operand slices for no-breuse path."""

        """
        SFA in TMEM(vec_size = 32):
        layout: ((((32,4),4),(32,1)),2,(4,3)):((((262144,4),8388608),(0,0)),48,(1,16))
        slice on the last dimension: (4,3).
            - 3 is the num of sf_atom in TMEM.
            - 2 is used for breuse.
        mma0 and mma2 begin at start of sf_atom_0. use coord (0,0) to slice.
        mma1 and mma3 begin at middle of sf_atom_1. use coord (2,1) to slice.

        E in TMEM:
        layout: ((128,16),3,2):((262144,1),16,48)
        slice on the last dimension: ((_, 16),3,2).
            - 16 is the size in bytes of e_atom.
            - 3 is the num of e_atom in TMEM.
            - 2 is used for breuse.
        mma1 and mma3 begin at middle of e_atom_1. use coord ((None, 8), 1, 0) to slice.
        mma0 and mma2 begin at start of e_atom_0. use coord (None, 0, 0) to slice.
        """

        # setup coord to slice TMEM address for SF and E
        if cutlass.const_expr(mma_idx == 0 or mma_idx == 2):
            sf_kblock_coord = (None, 0, 0)  # (0, 0) represents sf_atom 0 with offset 0
            e_kblock_coord = (None, 0, 0)
        else:
            sf_kblock_coord = (
                None,
                0,
                (2, 1),
            )  # (2, 1) repesents sf_atom 1 with offset 2
            e_kblock_coord = (
                (None, 8),
                1,
                0,
            )  # (8, 1) represents e_atom 1 with offset 8

        if cutlass.const_expr(vec_size == 64):
            if cutlass.const_expr(mma_idx == 0):
                sf_kblock_coord = (None, 0, (0, 0))
            elif cutlass.const_expr(mma_idx == 1):
                sf_kblock_coord = (None, 0, (3, 0))
            elif cutlass.const_expr(mma_idx == 2):
                sf_kblock_coord = (None, 0, (2, 1))
            elif cutlass.const_expr(mma_idx == 3):
                sf_kblock_coord = (None, 0, (1, 2))

        # setup coord to slice smem address for A and B
        # A B use circular buffer.
        # sA layout: ((CTA_M,16),1,4,num_stages):((64,1),0,16,16384)
        # sB layout: ((CTA_N,16),1,8,num_stages):((128,1),0,16,16384)
        if cutlass.const_expr(mma_idx == 0):
            stage_cur, stage_next, sA_offset, sB_offset = 0, 0, 0, 0
        elif cutlass.const_expr(mma_idx == 1):
            stage_cur, stage_next, sA_offset, sB_offset = 0, 1, 3, 6
        elif cutlass.const_expr(mma_idx == 2):
            stage_cur, stage_next, sA_offset, sB_offset = 1, 2, 2, 4
        else:
            stage_cur, stage_next, sA_offset, sB_offset = 2, 2, 1, 2

        k_block_coord_sA_cur = (None, 0, sA_offset, ab_smem_index[stage_cur])
        k_block_coord_sA_next = (None, 0, 0, ab_smem_index[stage_next])
        k_block_coord_sB_cur = (None, 0, sB_offset, ab_smem_index[stage_cur])
        k_block_coord_sB_next = (None, 0, 0, ab_smem_index[stage_next])

        return (
            sA[k_block_coord_sA_cur],
            sA[k_block_coord_sA_next],
            tCtSFA_mma[sf_kblock_coord],
            tCtE_mma[e_kblock_coord],
            sB[k_block_coord_sB_cur],
            sB[k_block_coord_sB_next],
            tCtSFB_mma[sf_kblock_coord],
        )

    def mma_no_breuse(
        self,
        mma_idx: int,
        ab_smem_index,
        sA,
        sB,
        tCtSFA_mma,
        tCtSFB_mma,
        tCtE_mma,
        tiled_mma,
        tCtAcc,
    ) -> None:
        """Combined set_mma_operand + single MMA for no-breuse path."""
        (
            mma_sA_cur,
            mma_sA_next,
            mma_tCtSFA,
            mma_tCtE,
            mma_sB_cur,
            mma_sB_next,
            mma_tCtSFB,
        ) = self.set_mma_operand(
            mma_idx,
            ab_smem_index,
            sA,
            sB,
            tCtSFA_mma,
            tCtSFB_mma,
            tCtE_mma,
            self.sf_vec_size,
        )
        self.make_desc_and_call_mma(
            tiled_mma,
            tCtAcc,
            mma_sA_cur,
            mma_sA_next,
            mma_tCtSFA,
            mma_tCtE,
            mma_sB_cur,
            mma_sB_next,
            mma_tCtSFB,
            tCtAcc,
        )

    def set_mma_operand_breuse(
        self,
        mma_idx,
        ab_smem_index,
        tCrA,
        sB,
        tCtSFA_mma,
        tCtSFB_mma,
        tCtE_mma,
        vec_size,
        enable_E_tmem_reuse,
    ):
        """Compute MMA operand slices for bkeep/breuse pattern."""
        # setup coord to slice TMEM address for SF and E
        if cutlass.const_expr(mma_idx == 0 or mma_idx == 2):
            sf_kblock_coord = (None, 0, 0)
            sf_kblock_keep_coord = (None, 0, 0)
            sf_kblock_reuse_coord = (None, 1, 0)
            e_kblock_coord = (None, 0, 0)
            e_kblock_keep_coord = (None, 0, 0)
            e_kblock_reuse_coord = (None, 0, 1)
        elif cutlass.const_expr(mma_idx == 1 or mma_idx == 3):
            sf_kblock_coord = (None, 0, (2, 1))
            sf_kblock_keep_coord = (None, 0, (2, 1))
            sf_kblock_reuse_coord = (None, 1, (2, 1))
            e_kblock_coord = ((None, 8), 1, 0)
            if cutlass.const_expr(enable_E_tmem_reuse):
                e_kblock_keep_coord = ((None, 8), 0, 0)
                e_kblock_reuse_coord = ((None, 8), 0, 1)
            else:
                e_kblock_keep_coord = ((None, 8), 1, 0)
                e_kblock_reuse_coord = ((None, 8), 1, 1)

        if cutlass.const_expr(vec_size == 64):
            if cutlass.const_expr(mma_idx == 0):
                sf_kblock_coord = (None, 0, (0, 0))
                sf_kblock_keep_coord = (None, 0, (0, 0))
                sf_kblock_reuse_coord = (None, 1, (0, 0))
            elif cutlass.const_expr(mma_idx == 1):
                sf_kblock_coord = (None, 0, (3, 0))
                sf_kblock_keep_coord = (None, 0, (3, 0))
                sf_kblock_reuse_coord = (None, 1, (3, 0))
            elif cutlass.const_expr(mma_idx == 2):
                sf_kblock_coord = (None, 0, (2, 1))
                sf_kblock_keep_coord = (None, 0, (2, 1))
                sf_kblock_reuse_coord = (None, 1, (2, 1))
            elif cutlass.const_expr(mma_idx == 3):
                sf_kblock_coord = (None, 0, (1, 2))
                sf_kblock_keep_coord = (None, 0, (1, 2))
                sf_kblock_reuse_coord = (None, 1, (1, 2))

        # setup coord to slice smem address for A and B
        # A B use circular buffer.
        # sA layout: ((128,16),2,4,num_stages):((64,1),8192,16,16384)
        # sB layout: ((CTA_N,16),1,8,num_stages):((128,1),0,16,16384)
        if cutlass.const_expr(mma_idx == 0):
            stage_cur, stage_next, sA_offset, sB_offset = 0, 0, 0, 0
        elif cutlass.const_expr(mma_idx == 1):
            stage_cur, stage_next, sA_offset, sB_offset = 0, 1, 3, 6
        elif cutlass.const_expr(mma_idx == 2):
            stage_cur, stage_next, sA_offset, sB_offset = 1, 2, 2, 4
        else:
            stage_cur, stage_next, sA_offset, sB_offset = 2, 2, 1, 2

        b_keep = 0
        b_reuse = 1

        k_block_coord_tCrA_keep_cur = (
            None,
            b_keep,
            sA_offset,
            ab_smem_index[stage_cur],
        )
        k_block_coord_tCrA_keep_next = (None, b_keep, 0, ab_smem_index[stage_next])
        k_block_coord_tCrA_reuse_cur = (
            None,
            b_reuse,
            sA_offset,
            ab_smem_index[stage_cur],
        )
        k_block_coord_tCrA_reuse_next = (None, b_reuse, 0, ab_smem_index[stage_next])
        k_block_coord_sB_cur = (None, 0, sB_offset, ab_smem_index[stage_cur])
        k_block_coord_sB_next = (None, 0, 0, ab_smem_index[stage_next])

        return (
            tCrA[k_block_coord_tCrA_keep_cur],
            tCrA[k_block_coord_tCrA_keep_next],
            tCrA[k_block_coord_tCrA_reuse_cur],
            tCrA[k_block_coord_tCrA_reuse_next],
            tCtSFA_mma[sf_kblock_keep_coord],
            tCtSFA_mma[sf_kblock_reuse_coord],
            tCtE_mma[e_kblock_keep_coord],
            tCtE_mma[e_kblock_reuse_coord],
            sB[k_block_coord_sB_cur],
            sB[k_block_coord_sB_next],
            tCtSFB_mma[sf_kblock_coord],
        )

    def mma_bkeep_breuse(
        self,
        mma_idx: int,
        ab_smem_index,
        tCrA,
        sB,
        tCtSFA_mma,
        tCtSFB_mma,
        tCtE_mma,
        tiled_mma,
        tCtAcc_keep,
        tCtAcc_reuse,
    ) -> None:
        """Combined set_mma_operand + bkeep MMA + breuse MMA pattern."""
        (
            mma_a_keep_cur,
            mma_a_keep_next,
            mma_a_reuse_cur,
            mma_a_reuse_next,
            mma_sfa_keep,
            mma_sfa_reuse,
            mma_e_keep,
            mma_e_reuse,
            mma_b_cur,
            mma_b_next,
            mma_sfb,
        ) = self.set_mma_operand_breuse(
            mma_idx,
            ab_smem_index,
            tCrA,
            sB,
            tCtSFA_mma,
            tCtSFB_mma,
            tCtE_mma,
            self.sf_vec_size,
            self.enable_E_tmem_reuse,
        )

        self.make_desc_and_call_mma(
            tiled_mma.with_bkeep(),
            tCtAcc_keep,
            mma_a_keep_cur,
            mma_a_keep_next,
            mma_sfa_keep,
            mma_e_keep,
            mma_b_cur,
            mma_b_next,
            mma_sfb,
            tCtAcc_keep,
        )
        self.make_desc_and_call_mma(
            tiled_mma.with_breuse(),
            tCtAcc_reuse,
            mma_a_reuse_cur,
            mma_a_reuse_next,
            mma_sfa_reuse,
            mma_e_reuse,
            mma_b_cur,
            mma_b_next,
            mma_sfb,
            tCtAcc_reuse,
        )

    @staticmethod
    def sm107_make_blockscaled_sparse_trivial_tiled_mma(
        ab_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        cta_group: tcgen05.CtaGroup,
        mma_tiler_mn: Tuple[int, int],
        atom_layout_mnk=(1, 1, 1),
        permutation_mnk=None,
        a_source: tcgen05.OperandSource = tcgen05.OperandSource.SMEM,
        a_collector_op: CollectorOp = CollectorOp.DISCARD,
        b_collector_op: CollectorOp = CollectorOp.DISCARD,
    ) -> sm107_utils.TiledMmaWrapper:
        """Create a blockscaled sparse trivial tiled MMA for sm107 (FP4 Ultra), K fixed to 192.

        Returns a tcgen05 sparse MMA configured for the given (M, N) tiler and CTA group.
        The instruction K dimension is fixed to 192 for sparse FP4 Ultra operations.

        :param ab_dtype: Data type of operands A and B (must be Float4E2M1FN)
        :type ab_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Data type of the accumulator (typically Float32)
        :type acc_dtype: Type[cutlass.Numeric]
        :param sf_dtype: Data type of the scale factor (typically 8-bit)
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: The vector size of the scale factor
        :type sf_vec_size: int
        :param cta_group: The CTA group configuration
        :type cta_group: tcgen05.CtaGroup
        :param mma_tiler_mn: The MMA tiler dimensions (M, N)
        :type mma_tiler_mn: Tuple[int, int]
        :param a_source: Source location for operand A (SMEM by default)
        :type a_source: tcgen05.OperandSource
        :param a_collector_op: Collector operation for operand A
        :type a_collector_op: CollectorOp
        :param b_collector_op: Collector operation for operand B
        :type b_collector_op: CollectorOp

        :return: A tiled MMA atom configured for sm107 sparse blockscaled operations
        :rtype: sm107_utils.TiledMmaWrapper

        :raises TypeError: If the data type is not supported.
        :raises ValueError: If the sf_vec_size is not supported.
        """
        mma_op = tcgen05.SM107MmaMXF4NVF4BlockScaledSparseOp(
            ab_dtype,
            acc_dtype,
            sf_dtype,
            sf_vec_size,
            (*mma_tiler_mn, 192),
            cta_group,
            a_source,
            a_collector_op=a_collector_op,
            b_collector_op=b_collector_op,
        )
        raw = cute.make_tiled_mma(
            cute.make_mma_atom(mma_op),
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )
        return sm107_utils.TiledMmaWrapper(raw._op, raw._trait)

    # Utils
    @staticmethod
    def sm107_make_smem_layout_a(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        mma_inst_shape_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand A using K_SW64 and Uint8.

        This function creates a SMEM layout for operand A using the make_smem_layout_atom function with K_SW64 kind and Uint8 element type.

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int

        :return: SMEM layout for operand A
        :rtype: cute.Layout
        """
        is_k_major = tiled_mma.op.a_major_mode == OperandMajorMode.K
        a_smem_layout_staged = tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(
                tcgen05.SmemLayoutAtomKind.K_SW64, cutlass.Uint8
            ),
            cute.append(
                (
                    (
                        mma_tiler_mnk[0]
                        // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
                        16,
                    ),
                    1,
                    4,
                ),
                num_stages,
            ),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )

        return a_smem_layout_staged

    # Utils
    @staticmethod
    def sm107_make_smem_layout_a_for_mma(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        mma_inst_shape_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand A using K_SW64 and Uint8.

        This function creates a SMEM layout for operand A using the make_smem_layout_atom function with K_SW64 kind and Uint8 element type.

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int

        :return: SMEM layout for operand A
        :rtype: cute.Layout
        """
        is_k_major = tiled_mma.op.a_major_mode == OperandMajorMode.K
        a_smem_layout_staged = tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(
                tcgen05.SmemLayoutAtomKind.K_SW64, cutlass.Uint8
            ),
            cute.append(
                (
                    (
                        mma_inst_shape_mnk[0]
                        // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
                        16,
                    ),
                    mma_tiler_mnk[0] // mma_inst_shape_mnk[0],  # breuse dim
                    4,
                ),
                num_stages,
            ),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )

        return a_smem_layout_staged

    @staticmethod
    def sm107_make_smem_layout_b(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand B using K_SW128 and Uint8.

        This function creates a SMEM layout for operand B using the make_smem_layout_atom function with K_SW128 kind and Uint8 element type.

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int

        :return: SMEM layout for operand B
        :rtype: cute.Layout
        """
        is_k_major = tiled_mma.op.b_major_mode == OperandMajorMode.K
        b_smem_layout_staged = tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(
                tcgen05.SmemLayoutAtomKind.K_SW128, cutlass.Uint8
            ),
            cute.append(
                ((mma_tiler_mnk[1] // cute.size(tiled_mma.thr_id.shape), 16), 1, 8),
                num_stages,
            ),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )
        return b_smem_layout_staged

    @staticmethod
    def sm107_make_smem_layout_e(
        tiled_mma: cute.TiledMma,
        mma_inst_shape_mnk: cute.Tile,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand E, specifically for FP4 Ultra sparse blockscaled gemm.

        This function creates a SMEM layout for operand E using the make_smem_layout_atom function with K_SW128 kind and Uint8 element type.

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int

        :return: SMEM layout for operand E
        :rtype: cute.Layout
        """
        tma_tiler = (
            mma_tiler_mnk[0],
            mma_tiler_mnk[2],
        )

        e_atom_layout = sm107_utils.make_tensor_e_atom_layout(tiled_mma.op.a_dtype)
        e_smem_layout = cute.tile_to_shape(e_atom_layout, tma_tiler, order=(0, 1))

        # ((atomM, atomK), restM, restK)
        e_smem_layout_tiled = cute.tiled_divide(e_smem_layout, e_atom_layout.shape)
        e_smem_layout_staged = cute.append(
            e_smem_layout_tiled,
            cute.make_layout(num_stages, stride=cute.cosize(e_smem_layout)),
        )
        return e_smem_layout_staged

    @staticmethod
    def sm107_make_smem_layout_e_tma(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand E, specifically for FP4 Ultra sparse blockscaled gemm.

        return ((128,2),(128,1)):((128,16384),(1,0))
        use atom K as 128 here to enable tma multicast.

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int

        :return: SMEM layout for operand E
        :rtype: cute.Layout
        """
        tma_tiler = (
            mma_tiler_mnk[0],
            mma_tiler_mnk[2],
        )
        e_atom_layout = sm107_utils.make_tensor_e_atom_layout(tiled_mma.op.a_dtype)
        e_smem_layout = cute.tile_to_shape(e_atom_layout, tma_tiler, order=(0, 1))
        return e_smem_layout

    @staticmethod
    def sm107_get_tmem_layout_e(
        mma_inst_shape_mnk: cute.Tile,
        mma_tiler_mnk: cute.Tile,
        a_raw_dtype: Type[cutlass.Numeric],
        enable_E_tmem_reuse: bool,
    ) -> cute.Layout:
        """
        Get the TMEM Layout for operand E, specifically for FP4 Ultra sparse blockscaled gemm.

        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param a_raw_dtype: The data type of the A tensor
        :type a_raw_dtype: Type[cutlass.Numeric]

        :return: The TMEM layout for operand E
        :rtype: cute.Layout
        """
        tile_k = mma_tiler_mnk[2]
        if enable_E_tmem_reuse:
            tile_k = 256
        padded_mn = cute.ceil_div(mma_tiler_mnk[0], 128) * 128

        atom_layout = sm107_utils.make_tensor_e_atom_layout(a_raw_dtype)
        un_tiled_e = cute.tile_to_shape(atom_layout, (tile_k, padded_mn), order=(1, 2))
        atom_M = 128
        tiler_e = (atom_M, 128)
        return cute.tiled_divide(un_tiled_e, tiler_e)

    @dataclass(frozen=True)
    class sm107BlockScaledBasicChunk:
        """
        Basic scale-factor atom layout decided by tcgen05 BlockScaled MMA Ops on sm107.

        Represents the fixed layout pattern for scale factors used by tcgen05
        BlockScaled MMA Ops on sm107. The layout is determined by the instruction
        specification and is not configurable.
        """

        sf_vec_size: int
        major_mode: OperandMajorMode = OperandMajorMode.K
        _layout: cute.Layout = field(init=False, repr=False)

        def __post_init__(self) -> None:
            if self.major_mode == OperandMajorMode.K:
                atom_shape = ((32, 4), (self.sf_vec_size, 4))
                atom_stride = ((16, 4), (0, 1))
            else:
                atom_shape = ((self.sf_vec_size, 4), (32, 4))
                atom_stride = ((0, 1), (16, 4))

            object.__setattr__(
                self, "_layout", cute.make_layout(shape=atom_shape, stride=atom_stride)
            )

        @property
        def layout(self) -> cute.Layout:
            return self._layout

    @staticmethod
    def sm107_make_smem_layout_sfa(
        tiled_mma: cute.TiledMma,
        mma_tiler: cute.Tile,
        sf_vec_size: int,
        num_stages: int,
    ) -> cute.Layout:
        """
        Make SMEM layout for SFA based on:
        1) sm107BlockScaledBasicChunk, 2) MMA tiler, 3) sf_vec_size, 4) stages.

        :param tiled_mma: The tiled MMA
        :type tiled_mma: cute.TiledMma
        :param mma_tiler: The mma tiler shape
        :type mma_tiler: cute.Tile
        :param sf_vec_size: The scale factor vector size
        :type sf_vec_size: int
        :param num_stages: The number of stages
        :type num_stages: int

        :return: Smem layout for SFA
        :rtype: cute.Layout
        """

        sfa_tile_shape = (
            mma_tiler[0],
            mma_tiler[2],
        )

        sf_atom = Sm107BlockScaledPersistentSparseGemmKernel.sm107BlockScaledBasicChunk(
            sf_vec_size, tiled_mma.op.a_major_mode
        ).layout

        # ((Atom_M, Rest_M),(Atom_K, Rest_K))
        smem_layout = cute.tile_to_shape(
            sf_atom,
            sfa_tile_shape,
            (2, 1),
        )

        # ((Atom_M, Atom_K), Rest_M, Rest_K)
        smem_layout = cute.tiled_divide(
            smem_layout, (cute.size(sf_atom.shape[0]), cute.size(sf_atom.shape[1]))
        )

        sfa_smem_layout_staged = cute.make_layout(
            shape=cute.append(smem_layout.shape, num_stages),
            stride=cute.append(
                smem_layout.stride,
                cute.size(cute.filter_zeros(smem_layout)),
            ),
        )
        return sfa_smem_layout_staged

    @staticmethod
    def sm107_make_smem_layout_sfb(
        tiled_mma: cute.TiledMma,
        mma_tiler: cute.Tile,
        sf_vec_size: int,
        num_stages: int,
    ) -> cute.Layout:
        """
        Make SMEM layout for SFB based on the basic chunk, MMA tiler, sf_vec_size, stages.

        :param tiled_mma: The tiled MMA
        :type tiled_mma: cute.TiledMma
        :param mma_tiler: The mma tiler shape
        :type mma_tiler: cute.Tile
        :param sf_vec_size: The scale factor vector size
        :type sf_vec_size: int
        :param num_stages: The number of stages
        :type num_stages: int

        :return: Smem layout for SFB
        :rtype: cute.Layout
        """
        sf_atom = Sm107BlockScaledPersistentSparseGemmKernel.sm107BlockScaledBasicChunk(
            sf_vec_size, tiled_mma.op.a_major_mode
        ).layout
        k_divisor = 2 if sf_vec_size == 32 else 1
        mma_sfb_tiler = (mma_tiler[1], mma_tiler[2] // k_divisor)
        if mma_sfb_tiler[0] == 128:
            sfb_smem_atom_layout = cute.tiled_product(
                sf_atom,
                cute.make_layout(
                    cute.shape_div(mma_sfb_tiler, cute.product_each(sf_atom.shape))
                ),
            )
        else:
            sf_k_major_atom256 = cute.make_layout(
                shape=(
                    (32, 4, 2),
                    (sf_vec_size, 4),
                ),
                stride=(
                    (16, 4, mma_sfb_tiler[1] // sf_vec_size // 4 * 512),
                    (0, 1),
                ),
            )
            sfb_smem_atom_layout = cute.tiled_product(
                sf_k_major_atom256,
                cute.make_layout(
                    cute.shape_div(
                        mma_sfb_tiler, cute.product_each(sf_k_major_atom256.shape)
                    )
                ),
            )

        sfb_smem_layout_staged = cute.make_layout(
            shape=cute.append(sfb_smem_atom_layout.shape, num_stages),
            stride=cute.append(
                sfb_smem_atom_layout.stride,
                cute.size(cute.filter_zeros(sfb_smem_atom_layout)),
            ),
        )
        return sfb_smem_layout_staged

    def mainloop__s2t_copy_and_partition_for_e(
        self,
        sE: cute.Tensor,
        tCtE: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for smem to tmem load for sparse metadata E tensor,
        then use it to partition smem memory (source) and tensor memory (destination).

        :param sE: The sparse metadata E tensor in smem
        :type sE: cute.Tensor
        :param tCtE: The sparse metadata E tensor in tmem
        :type tCtE: cute.Tensor

        :return: A tuple containing (tiled_copy_s2t_E, tCsE_compact_s2t, tCtE_compact_s2t) where:
            - tiled_copy_s2t_E: The tiled copy operation for smem to tmem load for E (s2t)
            - tCsE_compact_s2t: The partitioned E tensor in smem
            - tCtE_compact_s2t: The partitioned E tensor in tmem
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        copy_atom_s2t_e = cute.make_copy_atom(
            tcgen05.Cp128x128bOp(self.cta_group),
            self.e_raw_dtype,
        )
        tCtE_compact = cute.recast_tensor(tCtE, self.e_raw_dtype)

        tiled_copy_s2t_E = tcgen05.make_s2t_copy(copy_atom_s2t_e, tCtE_compact)
        thr_copy_s2t_E = tiled_copy_s2t_E.get_slice(0)

        sE_recast = cute.recast_tensor(sE, self.e_raw_dtype)
        tCsE_compact = cute.filter_zeros(sE_recast)

        # Swap M_blocks (mode 1) and K_blocks (mode 2) to match TMEM's (K, M) ordering.
        # Before: (atom, M=2, K=3, stages=6)  After: (atom, K=3, M=2, stages=6)
        tCsE_compact = cute.make_tensor(
            tCsE_compact.iterator,
            cute.make_layout(
                shape=(
                    tCsE_compact.shape[0],
                    tCsE_compact.shape[2],
                    tCsE_compact.shape[1],
                    tCsE_compact.shape[3],
                ),
                stride=(
                    tCsE_compact.stride[0],
                    tCsE_compact.stride[2],
                    tCsE_compact.stride[1],
                    tCsE_compact.stride[3],
                ),
            ),
        )

        tCsE_compact_s2t_ = thr_copy_s2t_E.partition_S(tCsE_compact)
        tCsE_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t_E, tCsE_compact_s2t_
        )

        tCtE_compact_s2t = thr_copy_s2t_E.partition_D(tCtE_compact)

        return tiled_copy_s2t_E, tCsE_compact_s2t, tCtE_compact_s2t

    def mainloop_s2t_copy_and_partition_for_sf(
        self,
        sSF: cute.Tensor,
        tSF: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Make tiledCopy for smem to tmem load for scale factor tensor, then use it to partition smem memory (source) and tensor memory (destination).

        :param sSF: The scale factor tensor in smem
        :type sSF: cute.Tensor
        :param tSF: The scale factor tensor in tmem
        :type tSF: cute.Tensor

        :return: A tuple containing (tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t) where:
            - tiled_copy_s2t: The tiled copy operation for smem to tmem load for scale factor tensor(s2t)
            - tCsSF_compact_s2t: The partitioned scale factor tensor in smem
            - tSF_compact_s2t: The partitioned scale factor tensor in tmem
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        # (MMA, MMA_MN, MMA_K, STAGE)
        tCsSF_compact = cute.filter_zeros(sSF)
        # (MMA, MMA_MN, MMA_K)
        tCtSF_compact = cute.filter_zeros(tSF)
        tCtSF_compact_copy = cute.make_tensor(
            tCtSF_compact.iterator,
            cute.append(
                cute.append(tCtSF_compact[(None, 0, 0)].layout, cute.make_layout((1))),
                cute.make_layout(1),
            ),
        )
        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact_copy)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t

    @staticmethod
    def _compute_total_smem_bytes(
        num_acc_stage: int,
        num_ab_stage: int,
        num_sf_stage: int,
        num_e_stage: int,
        num_c_stage: int,
        a_bytes_per_stage: int,
        b_bytes_per_stage: int,
        sfa_bytes_per_stage: int,
        sfb_bytes_per_stage: int,
        e_bytes_per_stage: int,
        c_bytes_per_stage: int,
        use_tma_store: bool,
    ) -> int:
        """Per-CTA SMEM the launch budget checks: static SharedStorage struct +
        128-aligned dynamic buffers (sA/sB/sSFA/sSFB/sE, plus sC when
        use_tma_store) + reserved SMEM. Mirrors the device SmemAllocator.
        """

        def _align(value: int, alignment: int = 128) -> int:
            return ((value + alignment - 1) // alignment) * alignment

        # SharedStorage: 2 Int64 mbars per pipeline + tmem_dealloc (Int64) +
        # tmem_holding (Int32).
        mbar_struct_bytes = (
            8 * 2 * (num_ab_stage + num_sf_stage + num_e_stage + num_acc_stage) + 8 + 4
        )

        total = _align(mbar_struct_bytes)
        total += _align(a_bytes_per_stage * num_ab_stage)
        total += _align(b_bytes_per_stage * num_ab_stage)
        total += _align(sfa_bytes_per_stage * num_sf_stage)
        total += _align(sfb_bytes_per_stage * num_sf_stage)
        total += _align(e_bytes_per_stage * num_e_stage)
        if use_tma_store:
            total += _align(c_bytes_per_stage * num_c_stage)
        total += Sm107BlockScaledPersistentSparseGemmKernel.RESERVED_SMEM_BYTES
        return total

    @staticmethod
    def _compute_block_scaled_sparse_stages(
        tiled_mma: cute.TiledMma,
        mma_inst_shape_mnk: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        mma_sf_tiler: Tuple[int, int, int],
        mma_e_tiler: Tuple[int, int, int],
        e_dtype: Type[cutlass.Numeric],
        epi_tile: cute.Tile,
        c_dtype: Type[cutlass.Numeric],
        c_layout: cutlass.tensor_utils.LayoutEnum,
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        smem_capacity: int,
        occupancy: int,
        use_tma_store: bool,
        with_breuse: bool = False,
    ) -> Tuple[int, int, int, int, int]:
        """Computes the number of stages for A/B and SF operands based on heuristics.

        sm107 requires separate stage counts for AB and SF pipelines.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler: The shape (M, N, K) of the MMA tiler.
        :type mma_tiler: tuple[int, int, int]
        :param epi_tile: The epilogue tile shape.
        :type epi_tile: cute.Tile
        :param c_dtype: Data type of operand C (output).
        :type c_dtype: type[cutlass.Numeric]
        :param c_layout: Layout enum of operand C.
        :type c_layout: cutlass.tensor_utils.LayoutEnum
        :param sf_dtype: Data type of Scale factor.
        :type sf_dtype: type[cutlass.Numeric]
        :param sf_vec_size: Scale factor vector size.
        :type sf_vec_size: int
        :param smem_capacity: Total available shared memory capacity in bytes.
        :type smem_capacity: int
        :param occupancy: Target number of CTAs per SM (occupancy).
        :type occupancy: int
        :param use_tma_store: Whether TMA store is enabled.
        :type use_tma_store: bool
        :param with_breuse: Whether Bkeep-Breuse pattern is enabled.
        :type with_breuse: bool

        :return: A tuple containing the computed number of stages for:
                 (ACC stages, A/B operand stages, SF stages, E stages, C stages)
        :rtype: tuple[int, int, int, int, int]
        """
        # ACC stages
        # When breuse is enabled with large N, limit to 1 acc stage due to TMEM capacity
        num_acc_stage = 1 if (with_breuse and mma_tiler[1] in {192, 256}) else 1

        # Fixed C depth on the TMA-store path, none on direct-STG.
        num_c_stage = (
            Sm107BlockScaledPersistentSparseGemmKernel.TMA_STORE_NUM_C_STAGE
            if use_tma_store
            else 0
        )

        # Calculate smem layout and size for one stage of A, B, SFA, SFB
        a_smem_layout_stage_one = (
            Sm107BlockScaledPersistentSparseGemmKernel.sm107_make_smem_layout_a(
                tiled_mma,
                mma_tiler,
                mma_inst_shape_mnk,
                1,
            )
        )
        b_smem_layout_staged_one = (
            Sm107BlockScaledPersistentSparseGemmKernel.sm107_make_smem_layout_b(
                tiled_mma,
                mma_tiler,
                1,
            )
        )
        sfa_smem_layout_staged_one = (
            Sm107BlockScaledPersistentSparseGemmKernel.sm107_make_smem_layout_sfa(
                tiled_mma,
                mma_sf_tiler,
                sf_vec_size,
                1,
            )
        )
        sfb_smem_layout_staged_one = (
            Sm107BlockScaledPersistentSparseGemmKernel.sm107_make_smem_layout_sfb(
                tiled_mma,
                mma_tiler,
                sf_vec_size,
                1,
            )
        )
        e_smem_layout_stage_one = (
            Sm107BlockScaledPersistentSparseGemmKernel.sm107_make_smem_layout_e(
                tiled_mma, mma_inst_shape_mnk, mma_e_tiler, 1
            )
        )

        c_smem_layout_staged_one = sm103_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )

        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * num_c_stage

        # Per-buffer byte sizes (each is a separate 128-aligned smem alloc);
        # combined ab/sf sums feed the initial stage estimate below.
        a_bytes_per_stage = cute.size_in_bytes(cutlass.Uint8, a_smem_layout_stage_one)
        b_bytes_per_stage = cute.size_in_bytes(cutlass.Uint8, b_smem_layout_staged_one)
        sfa_bytes_per_stage = cute.size_in_bytes(sf_dtype, sfa_smem_layout_staged_one)
        sfb_bytes_per_stage = cute.size_in_bytes(sf_dtype, sfb_smem_layout_staged_one)
        ab_bytes_per_stage = a_bytes_per_stage + b_bytes_per_stage
        sf_bytes_per_stage = sfa_bytes_per_stage + sfb_bytes_per_stage
        e_bytes_per_stage = cute.size_in_bytes(e_dtype, e_smem_layout_stage_one)

        mbar_helpers_bytes = 1024

        # Pack against the launchable budget (reserved SMEM subtracted).
        usable_smem_capacity = (
            smem_capacity
            - Sm107BlockScaledPersistentSparseGemmKernel.RESERVED_SMEM_BYTES
        )

        num_ab_sf_e_stage = (
            usable_smem_capacity // occupancy - (mbar_helpers_bytes + c_bytes)
        ) // (ab_bytes_per_stage + sf_bytes_per_stage + e_bytes_per_stage)

        num_ab_stage = num_ab_sf_e_stage
        num_sf_stage = num_ab_sf_e_stage
        num_e_stage = num_ab_sf_e_stage

        # C stages are fixed (set above), not greedily grown; leftover SMEM
        # stays as headroom.

        if (
            num_ab_stage == 6
            and num_sf_stage == 6
            and num_e_stage == 6
            and num_c_stage == 0
        ):
            num_ab_stage = 7
            num_sf_stage = 5
            num_e_stage = 5

        # Hard fit guarantee: shrink stages (C -> E -> SF -> AB, down to floors)
        # until the modeled allocation fits; if even the floors don't fit, fail
        # cleanly before launch so the caller can skip this tile.
        min_ab_stage = 2
        min_sf_stage = 2
        min_e_stage = 2
        min_c_stage = 1 if use_tma_store else 0

        def _modeled_total(ab, sf, e, c):
            return Sm107BlockScaledPersistentSparseGemmKernel._compute_total_smem_bytes(
                num_acc_stage,
                ab,
                sf,
                e,
                c,
                a_bytes_per_stage,
                b_bytes_per_stage,
                sfa_bytes_per_stage,
                sfb_bytes_per_stage,
                e_bytes_per_stage,
                c_bytes_per_stage,
                use_tma_store,
            )

        while (
            occupancy
            * _modeled_total(num_ab_stage, num_sf_stage, num_e_stage, num_c_stage)
            > smem_capacity
        ):
            if num_c_stage > min_c_stage:
                num_c_stage -= 1
            elif num_e_stage > min_e_stage:
                num_e_stage -= 1
            elif num_sf_stage > min_sf_stage:
                num_sf_stage -= 1
            elif num_ab_stage > min_ab_stage:
                num_ab_stage -= 1
            else:
                raise ValueError(
                    "sm107 sparse blockscaled GEMM: minimum SMEM stage config "
                    f"(ab={num_ab_stage}, sf={num_sf_stage}, e={num_e_stage}, "
                    f"c={num_c_stage}) requires "
                    f"{occupancy * _modeled_total(num_ab_stage, num_sf_stage, num_e_stage, num_c_stage)} B "
                    f"> smem_capacity {smem_capacity} B for this tile; the tile "
                    "is too large for this architecture and must be skipped."
                )

        return num_acc_stage, num_ab_stage, num_sf_stage, num_e_stage, num_c_stage

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
        swizzle_size: int = 1,
        raster_along_m: bool = True,
    ) -> Tuple[PersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Use persistent tile scheduler to compute the grid size for the output tensor C.

        :param c: The output tensor C
        :type c: cute.Tensor
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr
        :param swizzle_size: Swizzle size for rasterization (1 = no swizzle).
        :type swizzle_size: int
        :param raster_along_m: Rasterization order, True for AlongM.
        :type raster_along_m: bool

        :return: A tuple containing:
            - tile_sched_params: Parameters for the persistent tile scheduler.
            - grid: Grid shape for kernel launch.
        :rtype: Tuple[PersistentTileSchedulerParams, tuple[int, int, int]]
        """
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl,
            cluster_shape_mnl,
            swizzle_size=swizzle_size,
            raster_along_m=raster_along_m,
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
    ):
        """
        Check if the dtypes and sf_vec_size are valid combinations

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param sf_dtype: The data type of the scale factor
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: The vector size of the scale factor
        :type sf_vec_size: int
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]

        :raises testing.CantImplementError: If data types and/or scale factors are invalid
        """
        # Check valid ab_dtype
        if ab_dtype != cutlass.Float4E2M1FN:
            raise testing.CantImplementError(
                f"Unsupported AB data type: {ab_dtype}, only Float4E2M1FN is supported"
            )

        # Check valid sf_vec_size
        if sf_vec_size not in {32, 64}:
            raise testing.CantImplementError(
                f"Unsupported scale factor vector size: {sf_vec_size}, expected 32 or 64"
            )

        # Check valid sf_dtype
        if sf_dtype not in {
            cutlass.Float8E8M0FNU,
            cutlass.Float8E4M3FN,
            cutlass.FloatNV8E5M3FNU,
        }:
            raise testing.CantImplementError(
                f"Unsupported scale factor data type: {sf_dtype}"
            )

        # Check valid c_dtype
        if c_dtype not in {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }:
            raise testing.CantImplementError(f"Unsupported output data type: {c_dtype}")

    @staticmethod
    def is_valid_layouts(
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ):
        """
        Check if layouts and dtypes are valid combinations

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major dimension of the A tensor
        :type a_major: str
        :param b_major: The major dimension of the B tensor
        :type b_major: str
        :param c_major: The major dimension of the C tensor
        :type c_major: str

        :raises testing.CantImplementError: If input/output layouts are invalid
        """
        if ab_dtype is cutlass.Float4E2M1FN and not (a_major == "k" and b_major == "k"):
            raise testing.CantImplementError(
                f"Unsupported layouts for {ab_dtype}: a_major={a_major}, b_major={b_major}, "
                f"both A and B must be k-major"
            )
    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        mma_inst_shape_mn: Tuple[int, int],
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ):
        """
        Check if the mma tiler and cluster shape are valid

        :param mma_inst_shape_mn: The (M, N) shape of the MMA instruction
        :type mma_inst_shape_mn: Tuple[int, int]
        :param mma_tiler_mn: The (M, N) shape of the MMA instruction tiler
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster
        :type cluster_shape_mn: Tuple[int, int]

        :raises testing.CantImplementError: If the mma tiler or cluster shape is invalid
        """
        # Skip invalid mma tile shape
        # Valid: 128, 256 (non-breuse or 2-CTA), 512 (2-CTA breuse)
        if mma_tiler_mn[0] not in [128, 256, 512]:
            raise testing.CantImplementError(
                f"Invalid mma_tiler_m: {mma_tiler_mn[0]}, expected 128, 256 or 512"
            )
        if mma_tiler_mn[1] not in [128, 256]:
            raise testing.CantImplementError(
                f"Invalid mma_tiler_n: {mma_tiler_mn[1]}, expected 128 or 256"
            )
        # Skip illegal cluster shape
        # 2-CTA instructions (mma_inst_shape_mn[0]==256) require cluster_shape_mn[0] to be even
        if cluster_shape_mn[0] % (2 if mma_inst_shape_mn[0] == 256 else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster shape for a 2CTA MMA (mma_inst_shape_m={mma_inst_shape_mn[0]}): "
                f"cluster_shape_m must be even, got {cluster_shape_mn[0]}"
            )
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if cluster_shape_mn[0] <= 0 or cluster_shape_mn[1] <= 0:
            raise testing.CantImplementError(
                f"Invalid cluster shape {cluster_shape_mn}: dimensions must be positive"
            )
        if not is_power_of_2(cluster_shape_mn[0]) or not is_power_of_2(
            cluster_shape_mn[1]
        ):
            raise testing.CantImplementError(
                f"Invalid cluster shape {cluster_shape_mn}: dimensions must be powers of 2"
            )
        if cluster_shape_mn[0] * cluster_shape_mn[1] > 16:
            raise testing.CantImplementError(
                f"Invalid cluster shape {cluster_shape_mn}: cluster size must be <= 16"
            )
        # Special cluster shape check for scale factor multicasts.
        # Due to limited size of scale factors, we can't multicast among more than 4 CTAs.
        if cluster_shape_mn[0] > 4 or cluster_shape_mn[1] > 4:
            raise testing.CantImplementError(
                f"Invalid cluster shape {cluster_shape_mn}: scale factor multicast is limited "
                f"to 4 CTAs per dimension"
            )

    @staticmethod
    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        l: int,
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ):
        """
        Check if the tensor alignment is valid

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param l: The number of columns in the C tensor
        :type l: int
        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :raises testing.CantImplementError: If the problem shape violates load/store alignment
        """

        def check_contigous_alignment(
            dtype, is_mode0_major, tensor_shape, alignment_bytes
        ):
            """Check if tensor satisfies the required byte alignment.

            :param dtype: Data type of the tensor
            :param is_mode0_major: Whether mode 0 is the major (contiguous) mode
            :param tensor_shape: Shape of the tensor (mode0, mode1, batch)
            :param alignment_bytes: Required alignment in bytes (e.g., 16 or 32)
            :return: True if alignment is satisfied
            """
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            # Calculate number of contiguous elements needed for alignment
            # alignment_bytes * 8 (bits per byte) / dtype.width (bits per element)
            num_contiguous_elements = alignment_bytes * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        # Check A/B tensors for 16B alignment
        # Check C tensor for 32B alignment
        if not check_contigous_alignment(ab_dtype, a_major == "m", (m, k, l), 16):
            raise testing.CantImplementError(
                f"Tensor A (m={m}, k={k}, a_major={a_major}, {ab_dtype}) is not 16B aligned"
            )
        if not check_contigous_alignment(ab_dtype, b_major == "n", (n, k, l), 16):
            raise testing.CantImplementError(
                f"Tensor B (n={n}, k={k}, b_major={b_major}, {ab_dtype}) is not 16B aligned"
            )
        if not check_contigous_alignment(c_dtype, c_major == "m", (m, n, l), 32):
            raise testing.CantImplementError(
                f"Tensor C (m={m}, n={n}, c_major={c_major}, {c_dtype}) is not 32B aligned"
            )

    @staticmethod
    def can_implement(
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        mma_inst_shape_mn: Tuple[int, int],
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        m: int,
        n: int,
        k: int,
        l: int,
        a_major: str,
        b_major: str,
        c_major: str,
        use_tma_store: bool,
        sfd_dtype: Optional[Type[cutlass.Numeric]] = None,
        sfd_vec_size: Optional[int] = None,
    ) -> bool:
        """
        Check if the gemm can be implemented

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param sf_dtype: The data type of the scale factor tensor
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: The vector size
        :type sf_vec_size: int
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param mma_tiler_mn: The (M, N) shape of the MMA instruction tiler
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster
        :type cluster_shape_mn: Tuple[int, int]
        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param l: The number of columns in the C tensor
        :type l: int
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """
        try:
            # Skip unsupported types
            Sm107BlockScaledPersistentSparseGemmKernel.is_valid_dtypes_and_scale_factor_vec_size(
                ab_dtype, sf_dtype, sf_vec_size, c_dtype
            )
            # Skip unsupported layouts
            Sm107BlockScaledPersistentSparseGemmKernel.is_valid_layouts(
                ab_dtype, c_dtype, a_major, b_major, c_major
            )
            # Skip invalid mma tile shape and cluster shape
            Sm107BlockScaledPersistentSparseGemmKernel.is_valid_mma_tiler_and_cluster_shape(
                mma_inst_shape_mn, mma_tiler_mn, cluster_shape_mn
            )
            # Skip illegal problem shape for load/store alignment
            Sm107BlockScaledPersistentSparseGemmKernel.is_valid_tensor_alignment(
                m, n, k, l, ab_dtype, c_dtype, a_major, b_major, c_major
            )
            # Skip unsupported block-scaled D output (SFD) configurations. The
            # dtype/layout/CTA-mode pre-conditions come from the shared validator
            # (single source of truth, see utils.gemm.sm100); the TMA-store and
            # N-divisibility checks are shape/config facts only known here.
            if sfd_dtype is not None:
                effective_sfd_vec_size = (
                    sf_vec_size if sfd_vec_size is None else sfd_vec_size
                )
                if not use_tma_store:
                    raise testing.CantImplementError(
                        "Block-scaled D output (SFD) requires use_tma_store=True"
                    )
                # Translate the hard error into the skip semantics of can_implement().
                try:
                    utils.gemm.sm100.validate_sfd_output(
                        sfd_dtype,
                        effective_sfd_vec_size,
                        c_dtype,
                        c_is_row_major=c_major == "n",
                        is_2cta_mma=mma_inst_shape_mn[0] == 256,
                        is_b_reuse=mma_tiler_mn[0] // mma_inst_shape_mn[0] == 2,
                    )
                except ValueError as e:
                    raise testing.CantImplementError(str(e)) from e
                if n % effective_sfd_vec_size != 0:
                    raise testing.CantImplementError(
                        f"N ({n}) must be divisible by the SFD vector "
                        f"size ({effective_sfd_vec_size})"
                    )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    # Helper function for append and coalesce layout
    @staticmethod
    def append_coalesce_layout(layout):
        part1 = cute.make_layout(
            cute.size(layout[0][0]) * cute.size(layout[1]), stride=cute.E(1)
        )
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(part1, part2)
        result = cute.append(result, layout[3])
        result = cute.append(result, layout[4])
        result = cute.append(result, layout[5])
        return result

    @staticmethod
    def adapt_layout_for_tma_ab(composed_layout):
        # input:  S<3,4,3> o 0 o ((128,16),1,8,3):((128,1),0,16,16384)
        # output: S<3,4,3> o 0 o (128,(128,3)):(128,(1,16384))
        # for ctaValueMap: (128,384):(1@0,1@1)
        layout = composed_layout.outer
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        part3 = cute.append(part2, layout[3])
        result = cute.append(part1, part3)
        return cute.make_composed_layout(
            composed_layout.inner, composed_layout.offset, result
        )

    @staticmethod
    def adapt_layout_for_tma_sf(layout):
        # input: (((8,4,4),(16,4)),1,3):(((16,128,4),(0,1)),0,512)
        # output: ((32,4),(16,4,3)):((16,4),(0,1,512))
        # for ctaValueMap: ((8,4,4),(16,4,3)):((1@0@0@0,1@1@0@0,1@2@0@0),(1@0@0@1,1@1@0@1,1@1@1))
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(cute.group_modes(part1, 0, cute.rank(part1)), part2)
        return result


@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """Convert scale factor tensor from MKL layout to mma specification M(32x4xrest_m)xK(4xrest_k)xL layout"""
    # sf_mma_tensor has flatten shape (32, 4, rest_m, 4, rest_k, l)
    # group to ((32, 4, rest_m), (4, rest_k), l)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def run(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_inst_shape_mn: Tuple[int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    use_tma_store: bool = False,
    swizzle_size: int = 1,
    raster_order: str = "m",
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    sfd_dtype: Optional[Type[cutlass.Numeric]] = None,
    sfd_vec_size: Optional[int] = None,
    norm_const: float = 1.0,
    **kwargs,
):
    """Execute a persistent batched sparse blockscaled GEMM operation on Rubin architecture with performance benchmarking.

    This function prepares input tensors (including 4:2 sparse A with metadata E), configures and launches the
    persistent sparse GEMM kernel, optionally performs reference validation, and benchmarks the execution performance.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[cutlass.Numeric]
    :param sf_dtype: Data type for scale factor tensor
    :type sf_dtype: Type[cutlass.Numeric]
    :param sf_vec_size: Vector size for scale factor tensor
    :type sf_vec_size: int
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[cutlass.Numeric]
    :param a_major/b_major/c_major: Memory layout of tensor A/B/C
    :type a_major/b_major/c_major: str
    :param mma_tiler_mn: MMA tiling size.
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param use_tma_store: Whether to use TMA store.
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance value for reference validation comparison, defaults to 1e-01
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 0
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 1
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference result validation, defaults to False
    :type skip_ref_check: bool, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False
    :type use_cold_l2: bool, optional
    :param init_normal: Whether to initialize A/B with a normal distribution instead of the default random integers, defaults to False
    :type init_normal: bool, optional
    :param normal_mean: Mean for normal distribution initialization, defaults to 0.0
    :type normal_mean: float, optional
    :param normal_std: Standard deviation for normal distribution initialization, defaults to 1.0
    :type normal_std: float, optional
    :raises RuntimeError: If CUDA GPU is not available
    :raises ValueError: If the configuration is invalid or unsupported by the kernel
    """
    print("Running sm107 Persistent FP4 Ultra Sparse BlockScaled GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, SF dtype: {sf_dtype}, SF Vec size: {sf_vec_size}")
    print(f"C dtype: {c_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Use TMA Store: {'True' if use_tma_store else 'False'}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
    print(f"Init normal: {'True' if init_normal else 'False'}")
    if init_normal:
        print(f"Normal mean: {normal_mean}, Normal std: {normal_std}")

    import torch
    import cutlass.torch as cutlass_torch

    # Unpack parameters
    m, n, k, l = mnkl

    # Skip unsupported testcase
    if not Sm107BlockScaledPersistentSparseGemmKernel.can_implement(
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        mma_inst_shape_mn,
        mma_tiler_mn,
        cluster_shape_mn,
        m,
        n,
        k,
        l,
        a_major,
        b_major,
        c_major,
        use_tma_store,
        sfd_dtype=sfd_dtype,
        sfd_vec_size=sfd_vec_size,
    ):
        raise TypeError(
            f"Unsupported testcase {ab_dtype}, {sf_dtype}, {sf_vec_size}, {c_dtype}, mma_inst_shape_mn: {mma_inst_shape_mn}, mma_tiler_mn: {mma_tiler_mn}, cluster_shape_mn: {cluster_shape_mn}, {m}, {n}, {k}, {l}, {a_major}, {b_major}, {c_major}, "
            f"use_tma_store: {use_tma_store}, "
            f"sfd_dtype: {sfd_dtype}, sfd_vec_size: {sfd_vec_size}"
        )

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    # Create scale factor tensor SFA/SFB
    def create_scale_factor_tensor(l, mn, k, sf_vec_size, dtype):
        def ceil_div(a, b):
            return (a + b - 1) // b

        sf_k = ceil_div(k, sf_vec_size)
        ref_shape = (l, mn, sf_k)

        atom_m = (32, 4)
        atom_k = 4
        mma_shape = (
            l,
            ceil_div(mn, atom_m[0] * atom_m[1]),
            ceil_div(sf_k, atom_k),
            atom_m[0],
            atom_m[1],
            atom_k,
        )

        ref_permute_order = (1, 2, 0)
        mma_permute_order = (3, 4, 1, 5, 2, 0)

        if skip_ref_check:
            # GPU-resident zero tensor in MMA layout; skip fp32 ref + convert kernel.
            cute_tensor, cute_torch_tensor = make_zero_cute_tensor_on_gpu(
                mma_shape, mma_permute_order, dtype, assumed_align=16
            )
            return None, cute_tensor, cute_torch_tensor

        # Create f32 ref torch tensor (cpu)
        ref_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            ref_shape,
            torch.float32,
            permute_order=ref_permute_order,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=1,
                max_val=3,
            ),
        )

        # Create f32 cute torch tensor (cpu)
        cute_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            mma_shape,
            torch.float32,
            permute_order=mma_permute_order,
            init_type=cutlass_torch.TensorInitType.SCALAR,
            init_config=cutlass_torch.ScalarInitConfig(value=1.0),
        )

        # convert ref f32 tensor to cute f32 tensor
        # Use torch reshape+permute instead of @cute.jit cvt_sf_MKL_to_M32x4xrm_K4xrk_L
        # to avoid DSL preprocessor free-variable issues under simulator environments.
        # The conversion maps: ref(m, k, l) -> mma(m%32, (m//32)%4, m//128, k%4, k//4, l)
        rest_m = ceil_div(mn, atom_m[0] * atom_m[1])
        rest_k = ceil_div(sf_k, atom_k)
        padded_mn = rest_m * atom_m[0] * atom_m[1]
        padded_sf_k = rest_k * atom_k
        if padded_mn != mn or padded_sf_k != sf_k:
            padded_ref = torch.zeros(padded_mn, padded_sf_k, l, dtype=torch.float32)
            padded_ref[:mn, :sf_k, :] = ref_f32_torch_tensor_cpu
        else:
            padded_ref = ref_f32_torch_tensor_cpu.contiguous()
        # (mn, sf_k, l) -> (rest_m, atom_m[1], atom_m[0], rest_k, atom_k, l)
        padded_reshaped = padded_ref.reshape(
            rest_m, atom_m[1], atom_m[0], rest_k, atom_k, l
        )
        # permute to (atom_m[0], atom_m[1], rest_m, atom_k, rest_k, l) = (32, 4, rest_m, 4, rest_k, l)
        cute_f32_torch_tensor_cpu.copy_(padded_reshaped.permute(2, 1, 0, 4, 3, 5))
        cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

        # reshape makes memory contiguous
        ref_f32_torch_tensor_cpu = (
            ref_f32_torch_tensor_cpu.permute(2, 0, 1)
            .unsqueeze(-1)
            .expand(l, mn, sf_k, sf_vec_size)
            .reshape(l, mn, sf_k * sf_vec_size)
            .permute(*ref_permute_order)
        )
        # prune to mkl for reference check.
        ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

        # Create dtype cute torch tensor (cpu)
        cute_tensor, cute_torch_tensor = cutlass_torch.cute_tensor_like(
            cute_f32_torch_tensor_cpu,
            dtype,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        # Convert f32 cute tensor to dtype cute tensor
        cute_tensor = cutlass_torch.convert_cute_tensor(
            cute_f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=True,
        )
        return ref_f32_torch_tensor_cpu, cute_tensor, cute_torch_tensor

    def _build_workspace_tensors():
        """Allocate sparse A/E, dense B/C, and scale factor SFA/SFB for one workspace.

        Called once to seed the compile inputs (and optional reference check), and
        again inside ``generate_inputs()`` to produce fresh workspaces for
        ``cutlass.testing.benchmark``.
        """
        (
            a_tensor,
            a_compressed_tensor,
            a_ref,
            a_compressed_torch_cpu,
            e_tensor,
            e_torch_cpu,
        ) = create_4_2_sparse_tensors(
            l,
            m,
            k,
            a_major,
            ab_dtype,
            init_normal=init_normal,
            normal_mean=normal_mean,
            normal_std=normal_std,
            skip_ref_check=skip_ref_check,
        )

        if skip_ref_check:
            # B / C allocated directly on GPU, zero-filled. Skip fp32 ref tensor +
            # convert_cute_tensor entirely.
            b_ref = None
            c_ref = None
            b_tensor, b_torch = make_zero_cute_tensor_on_gpu(
                (l, n, k), (1, 2, 0), ab_dtype, assumed_align=16
            )
            c_tensor, c_torch = make_zero_cute_tensor_on_gpu(
                (l, m, n), (1, 2, 0), c_dtype, assumed_align=32
            )
        else:
            b_ref = cutlass_torch.matrix(
                l,
                n,
                k,
                False,
                cutlass.Float32,
                init_type=cutlass_torch.TensorInitType.RANDOM,
                init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
            )
            if init_normal:
                b_ref.normal_(mean=normal_mean, std=normal_std)

            c_ref = cutlass_torch.matrix(
                l,
                m,
                n,
                False,
                cutlass.Float32,
                init_type=cutlass_torch.TensorInitType.RANDOM,
                init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
            )
            b_tensor, b_torch = cutlass_torch.cute_tensor_like(
                b_ref, ab_dtype, is_dynamic_layout=True, assumed_align=16
            )
            c_tensor, c_torch = cutlass_torch.cute_tensor_like(
                c_ref, c_dtype, is_dynamic_layout=True, assumed_align=32
            )

        # Mark tensor with element divisibility for 16B alignment
        a_tensor.mark_compact_shape_dynamic(
            mode=1, stride_order=(2, 0, 1), divisibility=32
        )
        a_compressed_tensor.mark_compact_shape_dynamic(
            mode=1, stride_order=(2, 0, 1), divisibility=32
        )
        b_tensor.mark_compact_shape_dynamic(
            mode=1, stride_order=(2, 0, 1), divisibility=32
        )
        c_tensor.mark_compact_shape_dynamic(
            mode=1, stride_order=(2, 0, 1), divisibility=16
        )

        sfa_ref, sfa_tensor, sfa_torch = create_scale_factor_tensor(
            l, m, k, sf_vec_size, sf_dtype
        )
        sfb_ref, sfb_tensor, sfb_torch = create_scale_factor_tensor(
            l, n, k, sf_vec_size, sf_dtype
        )

        return SimpleNamespace(
            a_tensor=a_tensor,
            a_compressed_tensor=a_compressed_tensor,
            a_ref=a_ref,
            a_compressed_torch_cpu=a_compressed_torch_cpu,
            e_tensor=e_tensor,
            e_torch_cpu=e_torch_cpu,
            b_ref=b_ref,
            b_tensor=b_tensor,
            b_torch=b_torch,
            c_ref=c_ref,
            c_tensor=c_tensor,
            c_torch=c_torch,
            sfa_ref=sfa_ref,
            sfa_tensor=sfa_tensor,
            sfa_torch=sfa_torch,
            sfb_ref=sfb_ref,
            sfb_tensor=sfb_tensor,
            sfb_torch=sfb_torch,
        )

    w = _build_workspace_tensors()
    a_tensor = w.a_tensor
    a_compressed_tensor = w.a_compressed_tensor
    a_ref = w.a_ref
    a_compressed_torch_cpu = w.a_compressed_torch_cpu
    e_tensor = w.e_tensor
    e_torch_cpu = w.e_torch_cpu
    b_ref = w.b_ref
    b_tensor = w.b_tensor
    b_torch = w.b_torch
    c_ref = w.c_ref
    c_tensor = w.c_tensor
    c_torch = w.c_torch
    sfa_ref, sfa_tensor, sfa_torch = w.sfa_ref, w.sfa_tensor, w.sfa_torch
    sfb_ref, sfb_tensor, sfb_torch = w.sfb_ref, w.sfb_tensor, w.sfb_torch

    # Optional block-scaled D (SFD) output buffers
    generate_sfd = sfd_dtype is not None
    effective_sfd_vec_size = sf_vec_size if sfd_vec_size is None else sfd_vec_size
    sfd_torch = None
    sfd_ptr = None
    norm_const_torch = None
    norm_const_cute = None
    if generate_sfd:
        sfd_torch, sfd_ptr = create_sfd_output_tensor(
            l, m, n, effective_sfd_vec_size, sfd_dtype
        )
        norm_const_torch = torch.tensor(
            [norm_const], dtype=torch.float32, device="cuda"
        )
        norm_const_cute = from_dlpack(norm_const_torch)

    # Configure gemm kernel
    gemm = Sm107BlockScaledPersistentSparseGemmKernel(
        sf_vec_size,
        mma_inst_shape_mn,
        mma_tiler_mn,
        cluster_shape_mn,
        use_tma_store,
        swizzle_size,
        raster_order,
    )

    # Compute max active clusters on current device
    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    # Compile gemm kernel
    # Only append the SFD trailing arguments (incl. the constexpr epilogue_op
    # they follow) when SFD output is requested, keeping the non-SFD compile
    # signature unchanged.
    sfd_compile_args = (
        (lambda x: x, sfd_ptr, norm_const_cute, effective_sfd_vec_size)
        if generate_sfd
        else ()
    )
    compiled_gemm = cute.compile[cute.GenerateLineInfo(True)](
        gemm,
        a_compressed_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        e_tensor,
        c_tensor,
        max_active_clusters,
        current_stream,
        *sfd_compile_args,
    )

    # Compute reference result
    if not skip_ref_check:
        # Execute kernel once for reference checking
        sfd_runtime_args = (sfd_ptr, norm_const_cute) if generate_sfd else ()
        compiled_gemm(
            a_compressed_tensor,
            b_tensor,
            sfa_tensor,
            sfb_tensor,
            e_tensor,
            c_tensor,
            current_stream,
            *sfd_runtime_args,
        )
        torch.cuda.synchronize()

        res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
        res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
        ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)

        if generate_sfd:
            # Block-scaled D output: compare kernel SFD and the SFD-rescaled
            # quantized output against the shared host reference (same flow
            # as the dense kernel driver).
            def ceil_div(a, b):
                return (a + b - 1) // b

            sf_n = ceil_div(n, effective_sfd_vec_size)

            # Reference SFD and SFD-rescaled output. Computed on CPU: exp2 /
            # log2 on CUDA tensors go through torch's jiterator (nvrtc), which
            # may not support bring-up architectures.
            sfd_ref, d_ref_f32 = compute_sfd_reference(
                ref.cpu(),
                effective_sfd_vec_size,
                sfd_dtype,
                c_dtype,
                norm_const=norm_const,
            )

            # Quantize the rescaled reference through c_dtype (f32 -> c -> f32)
            d_ref_narrow_ = torch.empty(
                (l, m, n), dtype=torch.uint8, device="cuda"
            ).permute(1, 2, 0)
            d_ref_narrow = from_dlpack(
                d_ref_narrow_, assumed_align=16
            ).mark_layout_dynamic(leading_dim=1)
            d_ref_narrow.element_type = c_dtype
            d_ref_device = (
                d_ref_f32.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
            )
            d_ref_tensor = from_dlpack(
                d_ref_device, assumed_align=16
            ).mark_layout_dynamic(leading_dim=1)
            cute.testing.convert(d_ref_tensor, d_ref_narrow)
            cute.testing.convert(d_ref_narrow, d_ref_tensor)

            # Kernel output C -> f32 for comparison
            c_f32_check_ = torch.zeros(
                (l, m, n), dtype=torch.float32, device="cuda"
            ).permute(1, 2, 0)
            cute.testing.convert(
                c_tensor,
                from_dlpack(c_f32_check_, assumed_align=16).mark_layout_dynamic(
                    leading_dim=1
                ),
            )
            # Kernel SFD (atom layout bytes) -> f32 -> MKL order. Decoded on
            # CPU (exp2 goes through torch's jiterator, unavailable on
            # bring-up architectures).
            sfd_kernel_f32_mma = decode_sfd_bytes_to_f32(sfd_torch.cpu(), sfd_dtype)
            sfd_kernel_mkl = (
                torch.zeros((l, m, sf_n), dtype=torch.float32).permute(1, 2, 0).cpu()
            )
            cvt_sf_M32x4xrm_K4xrk_L_to_MKL(
                from_dlpack(sfd_kernel_f32_mma),
                from_dlpack(sfd_kernel_mkl),
            )

            # Compare SFD first: the output rescale depends on it, so an SFD
            # mismatch is the more fundamental signal.
            torch.testing.assert_close(
                sfd_kernel_mkl, sfd_ref.cpu(), atol=tolerance, rtol=tolerance
            )
            torch.testing.assert_close(
                c_f32_check_.cpu(), d_ref_device.cpu(), atol=tolerance, rtol=tolerance
            )
        else:
            # Convert c back to f32 for comparison.
            c_ref_device = c_ref.cuda()

            cute.testing.convert(
                c_tensor,
                from_dlpack(c_ref_device, assumed_align=32).mark_layout_dynamic(
                    leading_dim=(1 if c_major == "n" else 0)
                ),
            )
            kernel_result_f32 = c_ref_device.cpu()

            if c_dtype in (cutlass.Float32, cutlass.Float16, cutlass.BFloat16):
                torch.testing.assert_close(
                    kernel_result_f32, ref, atol=tolerance, rtol=1e-02
                )

            elif c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
                # Convert ref : f32 -> f8 -> f32
                ref_f8_ = torch.empty(
                    *(l, m, n), dtype=torch.uint8, device="cuda"
                ).permute(1, 2, 0)
                ref_f8 = from_dlpack(ref_f8_, assumed_align=32).mark_layout_dynamic(
                    leading_dim=1
                )
                ref_f8.element_type = c_dtype
                ref_device = ref.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
                ref_tensor = from_dlpack(
                    ref_device, assumed_align=32
                ).mark_layout_dynamic(leading_dim=1)
                cute.testing.convert(ref_tensor, ref_f8)
                cute.testing.convert(ref_f8, ref_tensor)
                ref = ref_device.cpu()
                # Compare the kernel output (c_ref holds the pre-launch host
                # init; c_ref.cuda() above copied it, so the kernel result
                # only lives in kernel_result_f32).
                torch.testing.assert_close(
                    kernel_result_f32, ref, atol=tolerance, rtol=1e-02
                )
    def generate_inputs():
        w_ = _build_workspace_tensors()
        sfd_scope = []
        sfd_ws_args = ()
        if generate_sfd:
            sfd_torch_ws, sfd_ptr_ws = create_sfd_output_tensor(
                l, m, n, effective_sfd_vec_size, sfd_dtype
            )
            norm_const_torch_ws = torch.tensor(
                [norm_const], dtype=torch.float32, device="cuda"
            )
            norm_const_cute_ws = from_dlpack(norm_const_torch_ws)
            sfd_ws_args = (sfd_ptr_ws, norm_const_cute_ws)
            sfd_scope = [sfd_torch_ws, norm_const_torch_ws, norm_const_cute_ws]
        jit_args = cutlass.testing.JitArguments(
            w_.a_compressed_tensor,
            w_.b_tensor,
            w_.sfa_tensor,
            w_.sfb_tensor,
            w_.e_tensor,
            w_.c_tensor,
            current_stream,
            *sfd_ws_args,
        )
        # Keep references alive for the lifetime of the workspace
        jit_args.add_to_scope(
            [
                w_.a_compressed_tensor,
                w_.b_tensor,
                w_.sfa_tensor,
                w_.sfb_tensor,
                w_.e_tensor,
                w_.c_tensor,
                w_.a_compressed_torch_cpu,
                w_.e_torch_cpu,
                w_.b_torch,
                w_.c_torch,
                w_.sfa_torch,
                w_.sfb_torch,
            ]
            + sfd_scope
        )
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_compressed_torch_cpu.numel() * a_compressed_torch_cpu.element_size()
            + b_torch.numel() * b_torch.element_size()
            + sfa_torch.numel() * sfa_torch.element_size()
            + sfb_torch.numel() * sfb_torch.element_size()
            + e_torch_cpu.numel() * e_torch_cpu.element_size()
            + c_torch.numel() * c_torch.element_size()
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

    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of sm107 FP4 Ultra Sparse Persistent BlockScaled GEMM."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(1024, 1024, 1536, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma instruction shape (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=32)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument(
        "--sfd_dtype",
        type=cutlass.dtype,
        default=None,
        help="Scale factor dtype for block-scaled D output (enables SFD generation)",
    )
    parser.add_argument(
        "--sfd_vec_size",
        type=int,
        default=None,
        help="Scale factor vector size for block-scaled D output (defaults to sf_vec_size)",
    )
    parser.add_argument(
        "--norm_const",
        type=float,
        default=1.0,
        help="Global normalization constant applied to SFD computation (1.0 for MX formats)",
    )
    parser.add_argument("--a_major", choices=["k"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n"], type=str, default="n")
    parser.add_argument(
        "--use_tma_store", action="store_true", help="Use tma store or not"
    )
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
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzle size for rasterization (1 = no swizzle)",
    )
    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal distribution for A/B tensor initialization instead of random integers",
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

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_inst_shape_mn) != 2:
        parser.error("--mma_inst_shape_mn must contain exactly 2 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error(
            "--cluster_shape_mn must contain exactly 2 values, but got %s"
            % args.cluster_shape_mn
        )

    run(
        args.mnkl,
        args.ab_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_inst_shape_mn,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.use_tma_store,
        args.swizzle_size,
        args.raster_order,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
        sfd_dtype=args.sfd_dtype,
        sfd_vec_size=args.sfd_vec_size,
        norm_const=args.norm_const,
    )
    print("PASS")
