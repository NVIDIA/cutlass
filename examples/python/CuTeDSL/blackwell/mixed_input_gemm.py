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
from enum import Enum, auto
from math import log2, ceil
from typing import Optional, Union

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.cute.testing as testing
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.runtime import from_dlpack

"""
A mixed-input GEMM example for the NVIDIA Blackwell SM100 architecture using CUTE DSL.

This example demonstrates an implementation of mixed-input GEMM using a TMA plus Blackwell SM100 TensorCore
warp-specialized persistent kernel.

The inputs A and B have different data types. In this example, it's assumed that A is the narrow-precision tensor
and B holds data with a wider precision.
MMA will work in the wide precision of tensor B and tensor A will be transformed to the wide precision of tensor B
following 1 of the 2 possible modes as follows:

1. convert-only mode:
    C = type_convert(A) x B

In convert-only mode, tensor A is directly converted to the wide precision of tensor B.

2. convert-scale mode:
    C = (type_convert(A) * scale) x B

In convert-scale mode, tensor A is first converted to the wide precision of tensor B and then scaled by the scale tensor.
The scale tensor is in the same precision as tensor B.
The mode is determined by tensor A's data type as follows:
- if tensor A is in int8 or uint8, convert-only mode is used.
- if tensor A is in int4, convert-scale mode is used.

The output tensor C could have the same precision as tensor B or fp32.

To run this example:

.. code-block:: bash

    python examples/blackwell/mixed_input_gemm.py              \
      --a_dtype Int8 --b_dtype BFloat16                        \
      --scale_granularity_m 0 --scale_granularity_k 0          \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 128,128,64 --cluster_shape_mn 1,1        \
      --mnkl 256,512,8192,1

Input A and B have int8 and bf16 data types, respectively. The Blackwell tcgen05 MMA tile shape
is specified as (128,128,64) and the cluster shape is (1,1). The MMA accumulator and output data type
are set as fp32 and bf16, respectively. As tensor A is int8, convert-only mode is used.
scale_granularity_m and scale_granularity_k are set as 0 for convert-only mode.

Here is an example of running convert-scale mode:

.. code-block:: bash

    python examples/blackwell/mixed_input_gemm.py              \
      --a_dtype Int4 --b_dtype BFloat16                        \
      --scale_granularity_m 1 --scale_granularity_k 256        \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 256,128,128 --cluster_shape_mn 2,1       \
      --use_2cta_instrs --use_tma_store                        \
      --mnkl 1024,8192,6144,16

Input A and B have int4 and bf16 data types, respectively. The scale granularity is set as (1,256),
which means each element along the m mode of tensor A has its own scale element and 256 contiguous elements
along the k mode share the same scale element. There is no scale reuse along the L mode. If the GEMM shape is
(M, N, K, L), then the scale tensor shape is (M // scale_granularity_m, K // scale_granularity_k, L),
which is (1024, 6144/256, 16) in this example.
The Blackwell tcgen05 MMA tile shape is specified as (256,128,128) and tcgen05 2CTA feature is enabled.
The cluster shape is (2,1). The MMA accumulator and output data type are set as fp32 and bf16, respectively.
As tensor A is int4, the convert-scale mode is used.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/blackwell/mixed_input_gemm.py          \
      --a_dtype Int8 --b_dtype BFloat16                        \
      --scale_granularity_m 0 --scale_granularity_k 0          \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 128,128,64 --cluster_shape_mn 1,1        \
      --mnkl 256,512,8192,1                                    \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Besides the requirements from the Blackwell dense GEMM example, there are some constraints for this example:
* The narrow-precision is constrained to be int8, uint8, or int4 and the other data type is bf16 or f16.
* Output data types could only be fp16, bf16, or fp32.
* The scale_granularity_m must be 1 currently.
* The scale_granularity_k must be a multiple of mma_tiler_k and also be divisible by gemm_k.
* The scale tensor must be in m-major mode.
* OOB tiles are not allowed when TMA store is disabled
"""


class TransformMode(Enum):
    """
    An enumeration for the possible transform modes of a mixed-input GEMM.
    """

    ConvertOnly = auto()
    ConvertScale = auto()


class MixedInputGemmKernel:
    """
    Mixed-input GEMM kernel for NVIDIA Blackwell SM100 architecture.

    This kernel supports GEMM operations where input tensors A and B have different
    data types, with tensor A being transformed to the precision of tensor B before
    matrix multiplication.

    :param scale_granularity_m: Number of elements sharing the same scale factor along the M mode
    :type scale_granularity_m: int
    :param scale_granularity_k: Number of elements sharing the same scale factor along the K mode
    :type scale_granularity_k: int
    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mnk: Shape of the Matrix Multiply-Accumulate (MMA) tile (M, N, K)
    :type mma_tiler_mnk: tuple[int, int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: tuple[int, int]
    :param use_tma_store: Whether to use Tensor Memory Access (TMA) for storing results
    :type use_tma_store: bool
    """

    def __init__(
        self,
        scale_granularity_m: int,
        scale_granularity_k: int,
        acc_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_tma_store: bool,
    ):
        """
        Initializes the mixed-input GEMM kernel with a specified configuration.
        """
        # Scale granularity defines how many elements share the same scale factor
        # along the M and K modes.
        self.scale_granularity_m = scale_granularity_m
        self.scale_granularity_k = scale_granularity_k
        # Set transform mode
        if cutlass.const_expr(
            self.scale_granularity_m == 0 and self.scale_granularity_k == 0
        ):
            self.scale_mode = TransformMode.ConvertOnly
        else:
            self.scale_mode = TransformMode.ConvertScale
        self.acc_dtype = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.mma_tiler = mma_tiler_mnk
        self.use_tma_store = use_tma_store

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        # Set specialized warp ids
        self.epilog_warp_id = (
            0,
            1,
            2,
            3,
        )
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.scale_tma_warp_id = 6
        # 4 warps to do the transformation
        self.transform_warp_id = (
            8,
            9,
            10,
            11,
        )
        self.threads_per_cta = 32 * (
            max(
                (
                    self.mma_warp_id,
                    self.tma_warp_id,
                    self.scale_tma_warp_id,
                    *self.epilog_warp_id,
                    *self.transform_warp_id,
                )
            )
            + 1
        )

        # Set barrier id for cta sync, epilogue sync, tmem ptr sync, and transform sync
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            1, 32 * len(self.epilog_warp_id)
        )
        self.tmem_ptr_sync_barrier = pipeline.NamedBarrier(2, self.threads_per_cta)
        self.transform_sync_barrier = pipeline.NamedBarrier(
            3, 32 * len(self.transform_warp_id)
        )
        self.cta_sync_barrier = pipeline.NamedBarrier(4, self.threads_per_cta)

        self.smem_buffer_align_bytes = 1024

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Deduce where the transformed A tensor is stored
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/scale/B/C stage counts in shared memory
        - Setting up transformed A stage count in shared memory or tensor memory
        - Computing A/transformed A/scale/B/C memory layout
        - Computing tensor memory allocation columns
        """
        # Deduce where the transformed A tensor is stored, shared memory(SMEM) or tensor memory(TMEM)
        self.transform_a_source = self._get_transform_a_source(self.a_major_mode)
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        # Compute tensor memory(TMEM) columns and stages for each pipeline
        (
            self.num_load2trans_stage,
            self.num_scale_load2trans_stage,
            self.num_trans2mma_stage,
            self.num_acc_stage,
            self.num_c_stage,
            self.num_acc_tmem_cols,
            self.num_a_tmem_cols,
        ) = self._compute_stages_and_tmem_cols(
            tiled_mma,
            self.mma_tiler,
            self.cta_tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.c_layout,
            self.transform_a_source,
            self.scale_granularity_m,
            self.scale_granularity_k,
            self.smem_buffer_align_bytes,
            self.use_tma_store,
            self.scale_mode,
        )
        # Ensure load2trans and trans2mma pipelines share same stage count,
        # so we can use same pipeline stage index to slice both A and B buffers
        if cutlass.const_expr(self.num_load2trans_stage != self.num_trans2mma_stage):
            self.num_load2trans_stage = min(
                self.num_load2trans_stage, self.num_trans2mma_stage
            )
            self.num_trans2mma_stage = self.num_load2trans_stage

        # Align TMEM columns for allocation
        # TMEM allocation requires power-of-2 column alignment
        # and must meet minimum allocation requirements
        self.num_tmem_alloc_cols = MixedInputGemmKernel.align_up(
            self.num_acc_tmem_cols + self.num_a_tmem_cols,
            cute.arch.SM100_TMEM_MIN_ALLOC_COLUMNS,
        )
        self.num_tmem_alloc_cols = 2 ** (ceil(log2(self.num_tmem_alloc_cols)))
        # Get smem layout for C tensor when TMA store is enabled
        self.c_smem_layout_staged = (
            sm100_utils.make_smem_layout_epi(
                self.c_dtype,
                self.c_layout,
                self.epi_tile,
                self.num_c_stage,
            )
            if self.use_tma_store
            else None
        )
        # Get smem layout for A, transformed A, and B
        (
            self.smem_layout_a,
            self.smem_layout_a_transform,
            self.smem_layout_b,
        ) = self._compute_smem_layout(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.num_load2trans_stage,
            self.num_trans2mma_stage,
        )
        # Get smem layout for scale tensor
        self.smem_layout_scale_per_stage = None
        self.smem_layout_scale = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Get smem layout for scale tensor
            (
                self.smem_layout_scale_per_stage,
                self.smem_layout_scale,
            ) = self.get_smem_layout_scale()

    def _validate_inputs(
        self,
        a: cute.Tensor,
        a_scale: Optional[cute.Tensor],
        b: cute.Tensor,
        c: cute.Tensor,
    ) -> None:
        """
        Validates input tensors and their properties.

        :param a: Input tensor A.
        :type a: cute.Tensor
        :param a_scale: Scale tensor for tensor A (None for ConvertOnly mode).
        :type a_scale: Optional[cute.Tensor]
        :param b: Input tensor B.
        :type b: cute.Tensor
        :param c: Output tensor C.
        :type c: cute.Tensor
        :raises ValueError: If inputs don't meet kernel requirements.
        """
        # Validate scale tensor major mode
        if cutlass.const_expr(
            self.scale_mode == TransformMode.ConvertScale
            and utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
            != tcgen05.OperandMajorMode.MN
        ):
            raise ValueError("scale_major_mode should be m-major")

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        a_scale: Optional[cute.Tensor],  # None for ConvertOnly mode
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """
        Executes the Mixed Input GEMM operation.

        This method sets up the kernel parameters, computes the grid size,
        defines the shared storage, and launches the kernel.

        The execution steps are as follows:
        - Setup static attributes before smem/grid/tma computation.
        - Setup TMA load/store atoms and tensors.
        - Compute grid size with regard to hardware constraints.
        - Define shared storage for kernel.
        - Launch the kernel synchronously.

        :param a: Input tensor A.
        :type a: cute.Tensor
        :param a_scale: Scale tensor for tensor A (None for ConvertOnly mode).
        :type a_scale: Optional[cute.Tensor]
        :param b: Input tensor B.
        :type b: cute.Tensor
        :param c: Output tensor C.
        :type c: cute.Tensor
        :param max_active_clusters: Maximum number of active clusters to launch.
        :type max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream to launch the kernel on.
        :type stream: cuda.CUstream
        """
        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.a_scale_dtype: type[cutlass.Numeric] = (
            a_scale.element_type
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.c_dtype: type[cutlass.Numeric] = c.element_type
        self.mma_dtype = self.b_dtype

        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.scale_major_mode = (
            utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c)
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Get gmem layout for scale tensor
            self.gmem_layout_scale = self.get_gmem_layout_scale(a.shape)

        # Validate inputs
        self._validate_inputs(a, a_scale, b, c)

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )
        # Set up gmem copy atoms for A, scale, and B
        a_op = self._get_tma_atom_kind(self.is_a_mcast, self.use_2cta_instrs, False)
        b_op = self._get_tma_atom_kind(self.is_b_mcast, self.use_2cta_instrs, True)
        a_scale_op = a_op
        # Deduce TMA copy atom and TMA tensor for A, scale, and B
        smem_layout_a_per_stage = cute.slice_(self.smem_layout_a, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            smem_layout_a_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        tma_atom_scale, tma_tensor_scale = None, None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Partition smem layout for scale tensor to make it compatible with TMA atom
            smem_layout_for_tma_atom = cute.get(
                tiled_mma._thrfrg_A(self.smem_layout_scale_per_stage.outer), mode=[1]
            )
            # ((MMA_M, MMA_K), REST_M, REST_K)
            smem_layout_for_tma_atom = cute.dice(
                smem_layout_for_tma_atom,
                (1, (1,) * cute.rank(self.smem_layout_scale_per_stage.outer)),
            )
            tma_atom_scale, tma_tensor_scale = cute.nvgpu.make_tiled_tma_atom_A(
                a_scale_op,
                cute.make_tensor(a_scale.iterator, self.gmem_layout_scale),
                smem_layout_for_tma_atom,
                # (SCALE_M, 1, SCALE_K)
                (self.scale_tile_shape[0], 1, self.scale_tile_shape[1]),
                tiled_mma,
                self.cluster_layout_vmnk.shape,
                internal_type=(
                    cutlass.TFloat32
                    if a_scale.element_type is cutlass.Float32
                    else None
                ),
            )

        smem_layout_b_per_stage = cute.slice_(self.smem_layout_b, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            smem_layout_b_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # Calculate copy size for tensor A, B, and scale
        a_copy_size = cute.size_in_bytes(self.a_dtype, smem_layout_a_per_stage)
        b_copy_size = cute.size_in_bytes(self.b_dtype, smem_layout_b_per_stage)
        a_scale_copy_size = (
            cute.size_in_bytes(self.a_scale_dtype, self.smem_layout_scale_per_stage)
            if self.scale_mode is TransformMode.ConvertScale
            else 0
        )

        self.num_tma_load_bytes_a = a_copy_size
        self.num_tma_load_bytes_b = b_copy_size * cute.size(tiled_mma.thr_id.shape)
        self.num_tma_load_bytes_scale = a_scale_copy_size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            max_active_clusters,
        )

        tma_atom_c = None
        tma_tensor_c = None
        c_smem_size = 0
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.slice_(self.c_smem_layout_staged, (None, None, 0))
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(),
                c,
                epi_smem_layout,
                self.epi_tile,
            )
            c_smem_size = cute.cosize(self.c_smem_layout_staged.outer)

        # Shared memory structure
        a_smem_size = cute.cosize(self.smem_layout_a.outer)
        b_smem_size = cute.cosize(self.smem_layout_b.outer)
        a_transform_smem_size = (
            cute.cosize(self.smem_layout_a_transform.outer)
            if self.transform_a_source == tcgen05.OperandSource.SMEM
            else 0
        )
        a_scale_smem_size = (
            cute.cosize(self.smem_layout_scale.outer)
            if self.scale_mode is TransformMode.ConvertScale
            else 0
        )

        @cute.struct
        class SharedStorage:
            a_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_scale_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_scale_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_trans2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            a_trans2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            b_load2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            b_load2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # Tensor buffers
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            smem_C: cute.struct.Align[
                cute.struct.MemRange[self.c_dtype, c_smem_size],
                self.smem_buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            smem_A: cute.struct.Align[
                cute.struct.MemRange[self.a_dtype, a_smem_size],
                self.smem_buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            smem_B: cute.struct.Align[
                cute.struct.MemRange[self.b_dtype, b_smem_size],
                self.smem_buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            smem_A_transform: cute.struct.Align[
                cute.struct.MemRange[self.mma_dtype, a_transform_smem_size],
                self.smem_buffer_align_bytes,
            ]
            # (MMA, MMA_M_SCALE, MMA_K_SCALE, STAGE)
            smem_A_scale: cute.struct.Align[
                cute.struct.MemRange[self.mma_dtype, a_scale_smem_size],
                self.smem_buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch kernel
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_scale,
            tma_tensor_scale,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            self.cluster_layout_vmnk,
            self.smem_layout_a,
            self.smem_layout_scale,
            self.smem_layout_a_transform,
            self.smem_layout_b,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            smem=self.shared_storage.size_in_bytes(),
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
        tma_atom_s: Optional[cute.CopyAtom],
        mS_mkl: Optional[cute.Tensor],
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout: cute.ComposedLayout,
        scale_smem_layout: cute.ComposedLayout,
        a_smem_layout_transform: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
        c_smem_layout_staged: cute.ComposedLayout,
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """
        GPU device kernel performing the Persistent Mixed-Input GEMM computation.
        """
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        tidx, _, _ = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        # Prefetch TMA descriptors
        if warp_idx == self.epilog_warp_id[0]:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                cpasync.prefetch_descriptor(tma_atom_s)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2
        bidx, bidy, bidz = cute.arch.block_idx()
        # Compute how many k_tiles share the same scale
        num_k_tiles_per_scale = self.scale_granularity_k // self.cta_tile_shape_mnk[2]

        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize load2transform pipeline, which tracks the dependencies between TMA's loading
        # of A and B, and the transformation of A and MMA's consumption
        transform_thread_idx = (
            tidx - 32 * self.transform_warp_id[0]
            if tidx >= 32 * self.transform_warp_id[0]
            else tidx
        )
        a_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.a_load2trans_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mcast_ctas_a * len(self.transform_warp_id),
            ),
            tx_count=self.num_tma_load_bytes_a,
            cta_layout_vmnk=cluster_layout_vmnk,
            tidx=transform_thread_idx,
            mcast_mode_mn=(1, 0),  # multicast for A will only happen on the M-mode
        )
        # Initialize scale_load2trans pipeline, which tracks the dependencies between TMA's loading
        # of scale, and the transformation of A
        scale_load2trans_pipeline = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            num_producers_a_scale = self.num_mcast_ctas_a
            scale_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
                barrier_storage=storage.a_scale_load2trans_full_mbar_ptr.data_ptr(),
                num_stages=self.num_scale_load2trans_stage,
                producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
                consumer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    num_producers_a_scale
                    * len(self.transform_warp_id)
                    * num_k_tiles_per_scale,
                ),
                tx_count=self.num_tma_load_bytes_scale,
                cta_layout_vmnk=cluster_layout_vmnk,
                tidx=transform_thread_idx,
                mcast_mode_mn=(
                    1,
                    0,
                ),  # multicast for scale_a will only happen on the M-mode
            )
        # Initialize transform2mma pipeline, which tracks the dependencies between the transformation
        # of A and MMA's consumption of transformed A
        cta_v_size = cute.size(cluster_layout_vmnk, mode=[0])
        trans2mma_pipeline = pipeline.PipelineAsyncUmma.create(
            barrier_storage=storage.a_trans2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_trans2mma_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.transform_warp_id) * cta_v_size,
            ),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            cta_layout_vmnk=cluster_layout_vmnk,
        )
        # Initialize pipeline for tensor B load to MMA
        # MMA warp informs TMA warp to proceed to load next tile of B tensor
        b_load2mma_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.b_load2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mcast_ctas_b
            ),
            tx_count=self.num_tma_load_bytes_b,
            cta_layout_vmnk=cluster_layout_vmnk,
            mcast_mode_mn=(0, 1),  # multicast for B will only happen on the N-mode
        )
        # Initialize accumulator pipeline, which tracks the dependencies between
        # MMA's computation of accumulators and epilogue warps' consumption of accumulators
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, cta_v_size * len(self.epilog_warp_id)
            ),
            cta_layout_vmnk=cluster_layout_vmnk,
        )

        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf,
            barrier_for_retrieve=self.tmem_ptr_sync_barrier,
            allocator_warp_id=self.epilog_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr,
        )

        # Cluster arrive after barrier init
        if cutlass.const_expr(cute.size(self.cluster_shape_mn) > 1):
            cute.arch.cluster_arrive_relaxed()

        # Setup smem tensor A/scale/B/C
        sC = (
            storage.smem_C.get_tensor(
                c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
            )
            if self.use_tma_store
            else None
        )
        sA_input = storage.smem_A.get_tensor(
            a_smem_layout.outer, swizzle=a_smem_layout.inner
        )
        sS_input = (
            storage.smem_A_scale.get_tensor(
                scale_smem_layout.outer, swizzle=scale_smem_layout.inner
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        sB_input = storage.smem_B.get_tensor(
            b_smem_layout.outer, swizzle=b_smem_layout.inner
        )
        sA_transform = None
        # Get smem tensor for transformed A when transform_a_source is SMEM
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.SMEM):
            sA_transform = storage.smem_A_transform.get_tensor(
                a_smem_layout_transform.outer, swizzle=a_smem_layout_transform.inner
            )

        # Compute multicast mask for A/B buffer full
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        s_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            # scale tensor share the same multicast mask with A tensor
            s_full_mcast_mask = a_full_mcast_mask
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        # local_tile partition global tensors
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bM, bK, loopM, loopK, loopL)
        gS_mkl = (
            cute.local_tile(
                mS_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, loopM, loopN, loopL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Partition global tensor for TiledMMA_A/B/C
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgS = (
            thr_mma.partition_A(gS_mkl)
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
        tCgC = thr_mma.partition_C(gC_mnl)

        # Setup copy atom to load A from shared memory for further transformation
        copy_atom_a_input = (
            cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(), self.a_dtype, num_bits_per_copy=32
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        a_smem_shape = tiled_mma.partition_shape_A(
            cute.dice(self.mma_tiler, (1, None, 1))
        )
        # Setup copy atom to store transformed A into tensor memory or shared memory
        copy_atom_a_transform = self._get_copy_atom_a_transform(
            self.mma_dtype,
            self.use_2cta_instrs,
            self.transform_a_source,
            a_smem_shape,
            self.a_dtype,
        )

        # Partition global/shared tensor for TMA load A/B
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA_input, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )

        tCsS = None
        tSsS = None
        tSgS = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # (MMA, MMA_M, MMA_K, STAGE)
            tCsS = thr_mma.partition_A(sS_input)
            # ((atom_v, rest_v), STAGE)
            # ((atom_v, rest_v), loopM, loopK, loopL)
            tSsS, tSgS = self.scale_tma_partition(
                tCsS,
                tCgS,
                tma_atom_s,
                block_in_cluster_coord_vmnk,
                a_cta_layout,
            )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB_input, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB_input)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Cluster wait before TMEM alloc and ensure pipelines are ready
        if cutlass.const_expr(cute.size(self.cluster_shape_mn) > 1):
            cute.arch.cluster_wait()
        else:
            self.cta_sync_barrier.arrive_and_wait()

        # TMEM allocation
        tmem.allocate(self.num_tmem_alloc_cols)
        tmem.wait_for_alloc()
        # Get the pointer to the TMEM buffer
        tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
        accumulators = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        tCrA = None
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.TMEM):
            tmem_ptr_transform = cute.recast_ptr(
                accumulators.iterator + self.num_acc_tmem_cols, dtype=self.mma_dtype
            )
            tCrA = cute.make_tensor(
                tmem_ptr_transform,
                tiled_mma.make_fragment_A(a_smem_layout_transform.outer).layout,
            )
        else:
            tCrA = tiled_mma.make_fragment_A(sA_transform)

        # Specialized TMA load warp for A/B tensor
        if warp_idx == self.tma_warp_id:
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            a_load2trans_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )
            b_load2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                a_load2trans_producer_state.reset_count()
                peek_load2trans_empty_status = cutlass.Boolean(1)
                if a_load2trans_producer_state.count < k_tile_cnt:
                    peek_load2trans_empty_status = (
                        a_load2trans_pipeline.producer_try_acquire(
                            a_load2trans_producer_state
                        )
                    )
                b_load2mma_producer_state.reset_count()
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.producer_acquire(
                        a_load2trans_producer_state, peek_load2trans_empty_status
                    )
                    b_load2mma_pipeline.producer_acquire(b_load2mma_producer_state)
                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, a_load2trans_producer_state.count)],
                        tAsA[(None, a_load2trans_producer_state.index)],
                        tma_bar_ptr=a_load2trans_pipeline.producer_get_barrier(
                            a_load2trans_producer_state
                        ),
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, b_load2mma_producer_state.count)],
                        tBsB[(None, b_load2mma_producer_state.index)],
                        tma_bar_ptr=b_load2mma_pipeline.producer_get_barrier(
                            b_load2mma_producer_state
                        ),
                        mcast_mask=b_full_mcast_mask,
                    )
                    a_load2trans_pipeline.producer_commit(a_load2trans_producer_state)
                    b_load2mma_pipeline.producer_commit(b_load2mma_producer_state)
                    a_load2trans_producer_state.advance()
                    b_load2mma_producer_state.advance()
                    if a_load2trans_producer_state.count < k_tile_cnt:
                        peek_load2trans_empty_status = (
                            a_load2trans_pipeline.producer_try_acquire(
                                a_load2trans_producer_state
                            )
                        )
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait A/B buffer empty
            a_load2trans_pipeline.producer_tail(a_load2trans_producer_state)
            b_load2mma_pipeline.producer_tail(b_load2mma_producer_state)

        # Specialized TMA load for scale tensor
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            if warp_idx == self.scale_tma_warp_id:
                # Persistent tile scheduling loop
                tile_sched = utils.StaticPersistentTileScheduler.create(
                    tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
                )
                work_tile = tile_sched.initial_work_tile_info()
                scale_load2trans_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_scale_load2trans_stage
                )
                scale_k_tile_cnt = cute.size(mS_mkl.layout.shape[1][1])

                while work_tile.is_valid_tile:
                    cur_tile_coord = work_tile.tile_idx
                    mma_tile_coord_mnl = (
                        cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                        cur_tile_coord[1],
                        cur_tile_coord[2],
                    )
                    # ((atom_v, rest_v), RestK)
                    tSgS_slice = tSgS[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    # Filter zeros in rest mode
                    rest_filtered = cute.filter_zeros(tSgS_slice[(0, None)].layout)
                    tSgS_slice_filtered = cute.make_tensor(
                        tSgS_slice.iterator,
                        cute.make_layout(
                            (tSgS_slice.layout[0].shape, rest_filtered.shape),
                            stride=(tSgS_slice.layout[0].stride, rest_filtered.stride),
                        ),
                    )

                    scale_load2trans_producer_state.reset_count()
                    peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                    if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                        peek_scale_load2trans_empty_status = (
                            scale_load2trans_pipeline.producer_try_acquire(
                                scale_load2trans_producer_state
                            )
                        )
                    for k_tile in cutlass.range(0, scale_k_tile_cnt, 1, unroll=1):
                        scale_load2trans_pipeline.producer_acquire(
                            scale_load2trans_producer_state,
                            peek_scale_load2trans_empty_status,
                        )
                        # TMA load scale
                        cute.copy(
                            tma_atom_s,
                            tSgS_slice_filtered[
                                (None, scale_load2trans_producer_state.count)
                            ],
                            tSsS[(None, scale_load2trans_producer_state.index)],
                            tma_bar_ptr=scale_load2trans_pipeline.producer_get_barrier(
                                scale_load2trans_producer_state
                            ),
                            mcast_mask=s_full_mcast_mask,
                        )

                        scale_load2trans_producer_state.advance()
                        peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                        if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                            peek_scale_load2trans_empty_status = (
                                scale_load2trans_pipeline.producer_try_acquire(
                                    scale_load2trans_producer_state
                                )
                            )
                    # Advance to next tile
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                # Wait scale buffer empty
                scale_load2trans_pipeline.producer_tail(scale_load2trans_producer_state)

        # Specialized transform warps
        if warp_idx >= self.transform_warp_id[0]:
            transform_local_tidx = tidx - 32 * self.transform_warp_id[0]
            # Partition tensors for transform input and output and set up the copy atom
            # used for loading and storing transformed A tensor
            (
                src_copy_a,
                dst_copy_a,
                tAsA_input,
                tAsA_transform,
            ) = self.transform_partition(
                self.transform_a_source,
                self.scale_mode,
                copy_atom_a_input,
                copy_atom_a_transform,
                sA_input,
                (
                    tCrA
                    if self.transform_a_source == tcgen05.OperandSource.TMEM
                    else sA_transform
                ),
                transform_local_tidx,
            )
            # make fragment for input A and transformed A
            tArA = cute.make_rmem_tensor(
                cute.select(tAsA_input.layout, mode=[0, 1, 2, 3]).shape,
                dtype=tAsA_input.element_type,
            )
            tArA_transform = cute.make_rmem_tensor(
                cute.select(tAsA_input.layout, mode=[0, 1, 2, 3]).shape,
                dtype=self.mma_dtype,
            )
            # Partition scale tensor
            smem_thr_copy_S = None
            tSsS_trans = None
            tSrS_copy = None
            tSrS = None
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS = self.scale_partition(
                    src_copy_a, tCsS, transform_local_tidx, self.mma_dtype
                )
                assert cute.size(tSrS, mode=[0]) == cute.size(tArA, mode=[0]), (
                    "tSrS and tArA have different leading dimension"
                )
                assert cute.size(tSrS) == cute.size(tArA), (
                    "tSrS and tArA have different shape"
                )
            # Make all modes except mode0 into loops
            tArA_load = cute.group_modes(tArA, 1, cute.rank(tArA))
            tSrS_load = (
                cute.group_modes(tSrS, 1, cute.rank(tSrS))
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            tArA_transform_store = cute.group_modes(
                tArA_transform, 1, cute.rank(tArA_transform)
            )

            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            a_load2trans_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.num_load2trans_stage,
            )
            scale_load2trans_consumer_state = (
                pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer,
                    self.num_scale_load2trans_stage,
                )
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            trans2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer,
                self.num_trans2mma_stage,
            )
            while work_tile.is_valid_tile:
                a_load2trans_consumer_state.reset_count()
                peek_load2trans_full_status = cutlass.Boolean(1)
                if a_load2trans_consumer_state.count < k_tile_cnt:
                    peek_load2trans_full_status = (
                        a_load2trans_pipeline.consumer_try_wait(
                            a_load2trans_consumer_state
                        )
                    )
                if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                    scale_load2trans_consumer_state.reset_count()
                trans2mma_producer_state.reset_count()
                peek_trans2mma_empty_status = cutlass.Boolean(1)
                if trans2mma_producer_state.count < k_tile_cnt:
                    peek_trans2mma_empty_status = (
                        trans2mma_pipeline.producer_try_acquire(
                            trans2mma_producer_state
                        )
                    )

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.consumer_wait(
                        a_load2trans_consumer_state, peek_load2trans_full_status
                    )
                    # Load A from shared memory
                    cute.autovec_copy(
                        tAsA_input[
                            (None, None, None, None, a_load2trans_consumer_state.index)
                        ],
                        tArA,
                    )
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_wait(
                            scale_load2trans_consumer_state
                        )
                    trans2mma_pipeline.producer_acquire(
                        trans2mma_producer_state, peek_trans2mma_empty_status
                    )
                    # load scale tensor when needed
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        if k_tile % num_k_tiles_per_scale == 0:
                            tSsS_slice = tSsS_trans[
                                (
                                    None,
                                    None,
                                    None,
                                    None,
                                    scale_load2trans_consumer_state.index,
                                )
                            ]
                            tSsS_slice_filtered = cute.make_tensor(
                                tSsS_slice.iterator,
                                cute.filter_zeros(tSsS_slice.layout),
                            )
                            cute.autovec_copy(tSsS_slice_filtered, tSrS_copy)

                    for idx in cutlass.range_constexpr(cute.size(tArA_load, mode=[1])):
                        # Load tensor A and convert it to mma dtype
                        tensor_transformed = (
                            tArA_load[(None, idx)].load().to(self.mma_dtype)
                        )
                        if cutlass.const_expr(
                            self.scale_mode == TransformMode.ConvertScale
                        ):
                            scale = cute.TensorSSA(
                                tSrS_load[(None, idx)].load(),
                                tensor_transformed.shape,
                                self.mma_dtype,
                            )
                            # Apply scale
                            tensor_transformed = tensor_transformed * scale
                        tArA_transform_store[(None, idx)].store(tensor_transformed)
                    # Store transformed A to tensor memory or shared memory
                    if cutlass.const_expr(dst_copy_a is not None):
                        cute.copy(
                            dst_copy_a,
                            tArA_transform,
                            tAsA_transform[
                                (None, None, None, None, trans2mma_producer_state.index)
                            ],
                        )
                    else:
                        cute.autovec_copy(
                            tArA_transform,
                            tAsA_transform[
                                (None, None, None, None, trans2mma_producer_state.index)
                            ],
                        )
                    # Ensure all transform threads have finished the copy and reached the fence
                    self.transform_sync_barrier.arrive_and_wait()
                    if cutlass.const_expr(
                        self.transform_a_source == tcgen05.OperandSource.TMEM
                    ):
                        cute.arch.fence_view_async_tmem_store()
                    else:
                        cute.arch.fence_proxy(
                            cute.arch.ProxyKind.async_shared,
                            space=cute.arch.SharedSpace.shared_cta,
                        )
                    # Signal the completion of transformation
                    trans2mma_pipeline.producer_commit(trans2mma_producer_state)
                    # Signal the completion of using A and scale tensors
                    a_load2trans_pipeline.consumer_release(a_load2trans_consumer_state)
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_release(
                            scale_load2trans_consumer_state
                        )
                        if (k_tile + 1) % num_k_tiles_per_scale == 0:
                            scale_load2trans_consumer_state.advance()

                    a_load2trans_consumer_state.advance()
                    trans2mma_producer_state.advance()
                    if a_load2trans_consumer_state.count < k_tile_cnt:
                        peek_load2trans_full_status = (
                            a_load2trans_pipeline.consumer_try_wait(
                                a_load2trans_consumer_state
                            )
                        )
                    if trans2mma_producer_state.count < k_tile_cnt:
                        peek_trans2mma_empty_status = (
                            trans2mma_pipeline.producer_try_acquire(
                                trans2mma_producer_state
                            )
                        )
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait a_transform buffer empty
            trans2mma_pipeline.producer_tail(trans2mma_producer_state)

        # Specialized MMA warp
        if warp_idx == self.mma_warp_id:
            tCtAcc_base = accumulators
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            trans2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_trans2mma_stage
            )
            b_load2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_load2trans_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]
                b_load2mma_consumer_state.reset_count()
                trans2mma_consumer_state.reset_count()
                peek_trans2mma_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    if trans2mma_consumer_state.count < k_tile_cnt:
                        peek_trans2mma_full_status = (
                            trans2mma_pipeline.consumer_try_wait(
                                trans2mma_consumer_state
                            )
                        )
                    acc_pipeline.producer_acquire(acc_producer_state)

                    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
                    # Mma mainloop
                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        trans2mma_pipeline.consumer_wait(
                            trans2mma_consumer_state, peek_trans2mma_full_status
                        )
                        b_load2mma_pipeline.consumer_wait(b_load2mma_consumer_state)
                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblock_coord = (
                                None,
                                None,
                                kblock_idx,
                                trans2mma_consumer_state.index,
                            )

                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblock_coord],
                                tCrB[kblock_coord],
                                tCtAcc,
                            )
                            # Enable accumulate on tCtAcc after first kblock
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                        trans2mma_pipeline.consumer_release(trans2mma_consumer_state)
                        b_load2mma_pipeline.consumer_release(b_load2mma_consumer_state)
                        trans2mma_consumer_state.advance()
                        b_load2mma_consumer_state.advance()
                        peek_trans2mma_full_status = cutlass.Boolean(1)
                        if trans2mma_consumer_state.count < k_tile_cnt:
                            peek_trans2mma_full_status = (
                                trans2mma_pipeline.consumer_try_wait(
                                    trans2mma_consumer_state
                                )
                            )
                    # Async arrive accumulator buffer full
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # Wait for accumulator buffer empty
            acc_pipeline.producer_tail(acc_producer_state)

        # Specialized epilogue warps
        if warp_idx < self.mma_warp_id:
            epi_tidx = tidx
            tCtAcc_base = accumulators
            # Partition for epilogue
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = self.epilog_tmem_copy_and_partition(
                epi_tidx, tCtAcc_base, tCgC, epi_tile, use_2cta_instrs
            )

            tTR_rC = None
            tiled_copy_r2s = None
            simt_atom = None
            tRS_rC = None
            tRS_sC = None
            bSG_sC = None
            bSG_gC_partitioned = None
            tTR_gC_partitioned = None
            if cutlass.const_expr(self.use_tma_store):
                tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
                tiled_copy_r2s, tRS_rC, tRS_sC = self.epilog_smem_copy_and_partition(
                    tiled_copy_t2r, tTR_rC, epi_tidx, sC
                )
                (
                    tma_atom_c,
                    bSG_sC,
                    bSG_gC_partitioned,
                ) = self.epilog_gmem_copy_and_partition(
                    epi_tidx, tma_atom_c, tCgC, epi_tile, sC
                )
            else:
                (
                    simt_atom,
                    tTR_rC,
                    tTR_gC_partitioned,
                ) = self.epilog_gmem_copy_and_partition(
                    epi_tidx, tiled_copy_t2r, tCgC, epi_tile, sC
                )
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, (bidx, bidy, bidz), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            c_pipeline = None
            if cutlass.const_expr(self.use_tma_store):
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilog_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage,
                    producer_group=c_producer_group,
                )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                bSG_gC = None
                tTR_gC = None
                if cutlass.const_expr(self.use_tma_store):
                    bSG_gC = bSG_gC_partitioned[(None, None, None, *mma_tile_coord_mnl)]
                else:
                    tTR_gC = tTR_gC_partitioned[
                        (None, None, None, None, None, *mma_tile_coord_mnl)
                    ]

                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                # Wait for accumulator buffer full
                acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                if cutlass.const_expr(self.use_tma_store):
                    bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))
                else:
                    tTR_gC = cute.group_modes(tTR_gC, 3, cute.rank(tTR_gC))

                # Store accumulator to global memory in subtiles
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Load accumulator from tensor memory buffer to register
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    if cutlass.const_expr(self.use_tma_store):
                        # Convert to C type
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tRS_rC.store(acc_vec)
                        c_buffer = (num_prev_subtiles + subtile_idx) % self.num_c_stage
                        # Store C to shared memory
                        cute.copy(
                            tiled_copy_r2s,
                            tRS_rC,
                            tRS_sC[(None, None, None, c_buffer)],
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        cute.arch.fence_proxy(
                            cute.arch.ProxyKind.async_shared,
                            space=cute.arch.SharedSpace.shared_cta,
                        )
                        self.epilog_sync_barrier.arrive_and_wait()
                        # TMA store C to global memory
                        if warp_idx == self.epilog_warp_id[0]:
                            cute.copy(
                                tma_atom_c,
                                bSG_sC[(None, c_buffer)],
                                bSG_gC[(None, subtile_idx)],
                            )
                            c_pipeline.producer_commit()
                            c_pipeline.producer_acquire()
                        self.epilog_sync_barrier.arrive_and_wait()
                    else:
                        # Convert to C type
                        acc_vec = tTR_rAcc.load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tTR_rC.store(acc_vec)
                        # Store C to global memory
                        cute.autovec_copy(
                            tTR_rC, tTR_gC[(None, None, None, subtile_idx)]
                        )
                # Async arrive accumulator buffer empty
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Dealloc the tensor memory buffer
            tmem.relinquish_alloc_permit()
            self.epilog_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
            if cutlass.const_expr(self.use_tma_store):
                c_pipeline.producer_tail()

    def scale_tma_partition(
        self,
        tCsS: cute.Tensor,
        tCgS: cute.Tensor,
        tma_atom_s: cute.CopyAtom,
        block_in_cluster_coord_vmnk: cute.Coord,
        scale_cta_layout: cute.Layout,
    ) -> tuple[cute.Tensor, cute.Tensor]:
        """
        Perform TMA partition for scale tensor.

        This method partitions the gobal memory and shared memory buffer for scale tensor for TMA load.

        :param tCsS: Input scale shared memory tensor
        :type tCsS: cute.Tensor
        :param tCgS: Input scale global memory tensor
        :type tCgS: cute.Tensor
        :param tma_atom_s: TMA copy atom for scale tensor
        :type tma_atom_s: cute.CopyAtom
        :param block_in_cluster_coord_vmnk: CTA coord in the cluster
        :type block_in_cluster_coord_vmnk: cute.Coord
        :param scale_cta_layout: Layout of CTA from the view of the scale tensor
        :type scale_cta_layout: cute.Layout

        :return: A tuple containing (tSsS, tSgS) where:
            - tSsS: Partitioned scale tensor in shared memory
            - tSgS: Partitioned scale tensor in global memory
        :rtype: tuple[cute.Tensor, cute.Tensor]
        """
        tSsS, tSgS = cpasync.tma_partition(
            tma_atom_s,
            block_in_cluster_coord_vmnk[2],
            scale_cta_layout,
            cute.group_modes(tCsS, 0, 3),
            cute.group_modes(tCgS, 0, 3),
        )
        # Add rest_v mode
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tSsS = cute.make_tensor(
            tSsS.iterator,
            cute.make_layout(
                ((tSsS.layout.shape[0], 1), *tSsS.layout.shape[1:]),
                stride=(
                    (tSsS.layout.stride[0], 0),
                    *tSsS.layout.stride[1:],
                ),
            ),
        )
        tSgS = cute.make_tensor(
            tSgS.iterator,
            cute.make_layout(
                ((tSgS.layout.shape[0], 1), *tSgS.layout.shape[1:]),
                stride=(
                    (tSgS.layout.stride[0], 0),
                    *tSgS.layout.stride[1:],
                ),
            ),
        )
        return tSsS, tSgS

    def transform_partition(
        self,
        transform_a_source: tcgen05.OperandSource,
        scale_mode: TransformMode,
        copy_atom_a_input: cute.CopyAtom,
        copy_atom_a_transform: cute.CopyAtom,
        sA_input: cute.Tensor,
        A_transform: cute.Tensor,
        transform_local_tidx: cutlass.Int32,
    ) -> tuple[cute.TiledCopy, cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Partition tensors for transform input and output.

        This method sets up the copy atoms and partitions the shared/tensor memory
        for the transformation of tensor A.

        :param transform_a_source: Where the transformed tensor A is stored (TMEM or SMEM)
        :type transform_a_source: tcgen05.OperandSource
        :param scale_mode: The transform mode (ConvertOnly or ConvertScale)
        :type scale_mode: TransformMode
        :param copy_atom_a_input: Copy atom for loading A from shared memory
        :type copy_atom_a_input: cute.CopyAtom
        :param copy_atom_a_transform: Copy atom for storing transformed A
        :type copy_atom_a_transform: cute.CopyAtom
        :param sA_input: Input tensor A in shared memory
        :type sA_input: cute.Tensor
        :param A_transform: Transformed tensor A in tensor or shared memory
        :type A_transform: cute.Tensor
        :param transform_local_tidx: Local thread index for transformation warps
        :type transform_local_tidx: cutlass.Int32

        :return: A tuple containing (src_copy_a, dst_copy_a, tAsA_input, tA_transform) where:
            - src_copy_a: Tiled copy for source tensor
            - dst_copy_a: Tiled copy for destination tensor
            - tAsA_input: Partitioned input tensor A
            - tA_transform: Partitioned transformed tensor A
        :rtype: tuple[cute.TiledCopy, cute.TiledCopy, cute.Tensor, cute.Tensor]
        """
        if cutlass.const_expr(transform_a_source == tcgen05.OperandSource.TMEM):
            if cutlass.const_expr(
                cute.size(A_transform, mode=[0, 0]) == 128
                and cute.size(sA_input, mode=[0, 0]) == 64
            ):
                tensor_input = cute.make_tensor(
                    sA_input.iterator,
                    cute.logical_product(
                        sA_input.layout,
                        ((cute.make_layout(2, stride=0), None), None, None, None),
                    ),
                )
            else:
                tensor_input = sA_input
            reg2tmem_tiled_copy = tcgen05.make_tmem_copy(
                copy_atom_a_transform, A_transform[(None, None, None, 0)]
            )
            thr_reg2tmem_tiled_copy = reg2tmem_tiled_copy.get_slice(
                transform_local_tidx
            )
            partitioned_tensor_input = thr_reg2tmem_tiled_copy.partition_S(tensor_input)
            partitioned_tensor_transform = thr_reg2tmem_tiled_copy.partition_D(
                A_transform
            )
            src_copy_a = (
                cute.make_tiled_copy_S(copy_atom_a_input, reg2tmem_tiled_copy)
                if scale_mode is TransformMode.ConvertScale
                else None
            )
            dst_copy_a = reg2tmem_tiled_copy
            tAsA_input = partitioned_tensor_input
            tA_transform = partitioned_tensor_transform
        elif cutlass.const_expr(transform_a_source == tcgen05.OperandSource.SMEM):
            # Construct tiled_copy satisfying 8 contiguous elts per copy atom
            reg2smem_tiled_copy = cute.make_cotiled_copy(
                copy_atom_a_transform,
                cute.make_layout((128, 8), stride=(8, 1)),
                A_transform[(None, None, None, 0)].layout,
            )
            thr_reg2smem_tiled_copy = reg2smem_tiled_copy.get_slice(
                transform_local_tidx
            )
            partitioned_tensor_input = thr_reg2smem_tiled_copy.partition_S(sA_input)
            partitioned_tensor_transform = thr_reg2smem_tiled_copy.partition_D(
                A_transform
            )
            src_copy_a = (
                cute.make_tiled_copy_S(copy_atom_a_input, reg2smem_tiled_copy)
                if scale_mode is TransformMode.ConvertScale
                else None
            )
            # auto-vec copy is enough for copy from register to shared memory here
            dst_copy_a = None
            tAsA_input = partitioned_tensor_input
            tA_transform = partitioned_tensor_transform
        return src_copy_a, dst_copy_a, tAsA_input, tA_transform

    def scale_partition(
        self,
        src_copy_a: cute.TiledCopy,
        tCsS: cute.Tensor,
        transform_local_tidx: cutlass.Int32,
        mma_dtype: type[cutlass.Numeric],
    ) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor]:
        """
        Partition the scale tensor for transformation.

        This method prepares the copy atom and partitions the shared memory for the scale tensor.

        :param src_copy_a: Tiled copy for the source tensor
        :type src_copy_a: cute.TiledCopy
        :param tCsS: Scale tensor in shared memory
        :type tCsS: cute.Tensor
        :param transform_local_tidx: Local thread index for transformation warps
        :type transform_local_tidx: cutlass.Int32
        :param mma_dtype: Data type for the MMA operation
        :type mma_dtype: type[cutlass.Numeric]

        :return: A tuple containing (smem_thr_copy_S, tSsS_trans, tSrS) where:
            - smem_thr_copy_S: Tiled copy for the scale tensor
            - tSsS_trans: Partitioned scale tensor for transformation
            - tSrS_copy: Register fragment for the scale tensor
            - tSrS: view of scale tensor used for transformation computation
        :rtype: tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor]
        """
        smem_thr_copy_S = None
        tSsS_trans = None
        tSrS = None
        # Partition scale tensor
        smem_thr_copy_S = src_copy_a.get_slice(transform_local_tidx)
        tSsS_trans = smem_thr_copy_S.partition_S(tCsS)
        # Construct register fragment for scale tensor
        tSsS_layout_per_stage = tSsS_trans[(None, None, None, None, 0)].layout
        # tSrS for copy
        tSrS_copy = cute.make_rmem_tensor(
            cute.filter_zeros(tSsS_layout_per_stage).shape, mma_dtype
        )
        # tSrS view for transformation computation
        tSrS = cute.make_tensor(
            tSrS_copy.iterator,
            cute.make_layout(
                tSsS_layout_per_stage.shape, stride=tSrS_copy.layout.stride
            ),
        )
        return smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS

    def get_gmem_layout_scale(
        self, scale_shape_mkl: tuple[int, int, int]
    ) -> cute.Layout:
        """
        Get the layout of the scale tensor in global memory.

        :param scale_shape_mkl: The shape of the scale tensor (M, K, L).
        :type scale_shape_mkl: tuple[int, int, int]

        :return: The layout of the scale tensor in global memory.
        :rtype: cute.Layout
        """
        m, k, l = scale_shape_mkl
        shape_scale = (
            (self.scale_granularity_m, cute.ceil_div(m, self.scale_granularity_m)),
            (self.scale_granularity_k, cute.ceil_div(k, self.scale_granularity_k)),
        )
        if cutlass.const_expr(self.scale_major_mode == tcgen05.OperandMajorMode.MN):
            layout_mk = cute.make_layout(
                shape_scale,
                stride=(
                    (0, 1),
                    (0, cute.size(shape_scale[0][1])),
                ),
            )
        else:
            layout_mk = cute.make_layout(
                shape_scale,
                stride=(
                    (0, cute.size(shape_scale[1][1])),
                    (0, 1),
                ),
            )
        return cute.make_layout(
            (*layout_mk.shape, l),
            stride=(*layout_mk.stride, cute.cosize(layout_mk)),
        )

    def get_smem_layout_scale(self) -> tuple[cute.ComposedLayout, cute.ComposedLayout]:
        """
        Get the layout of the scale tensor in shared memory.

        :return: A tuple containing:
            - smem_layout_scale_per_stage: Shared memory layout for scale tensor per stage
            - smem_layout_scale: Shared memory layout for scale tensor
        :rtype: tuple[cute.ComposedLayout, cute.ComposedLayout]
        """
        self.scale_tile_shape = (
            (
                cute.size(self.mma_tiler[0]) // 2
                if self.use_2cta_instrs
                else cute.size(self.mma_tiler[0])
            ),
            cute.size(self.mma_tiler[2]),
        )
        size_mn = self.scale_tile_shape[0]
        size_k = self.scale_tile_shape[1]
        smem_size_mn = (
            self.scale_granularity_m if self.scale_granularity_m < size_mn else size_mn
        )
        smem_size_k = (
            self.scale_granularity_k if self.scale_granularity_k < size_k else size_k
        )
        div_mn = cute.ceil_div(size_mn, smem_size_mn)
        div_k = cute.ceil_div(size_k, smem_size_k)
        smem_atom_shape = (
            (smem_size_mn, div_mn),
            (smem_size_k, div_k),
        )
        if cutlass.const_expr(self.scale_major_mode == tcgen05.OperandMajorMode.MN):
            outer_layout = cute.make_layout(
                smem_atom_shape,
                stride=(
                    (0, 1),
                    (0, div_mn),
                ),
            )
        else:
            outer_layout = cute.make_layout(
                smem_atom_shape,
                stride=(
                    (0, div_k),
                    (0, 1),
                ),
            )
        # Apply a trivial swizzle to make it a composed layout, which could be used to construct TMA atom
        smem_layout_scale_per_stage = cute.make_composed_layout(
            cute.make_swizzle(0, 4, 3), 0, outer_layout
        )
        assert cute.rank(smem_layout_scale_per_stage) == 2, (
            "Scale layout must be rank 2"
        )

        assert (
            cute.size(self.mma_tiler[0])
            % cute.size(smem_layout_scale_per_stage.outer[0])
            == 0
        ), "smem_layout_scale_per_stage must equal the tile shape."
        assert (
            cute.size(self.mma_tiler[2])
            % cute.size(smem_layout_scale_per_stage.outer[1])
            == 0
        ), "smem_layout_scale_per_stage must evenly divide tile k shape."
        # Shared memory buffer for scale must be at least 128B to satisfy TMA requirement
        assert (
            cute.size_in_bytes(self.a_scale_dtype, smem_layout_scale_per_stage) >= 128
        ), "smem size for scale must be at least 128B"
        # Scale layout in smem with multiple stages
        smem_layout_scale = cute.append(
            smem_layout_scale_per_stage,
            cute.make_layout(
                (self.num_scale_load2trans_stage),
                stride=(cute.cosize(smem_layout_scale_per_stage.outer)),
            ),
        )
        return smem_layout_scale_per_stage, smem_layout_scale

    def epilog_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
    ) -> tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]:
        """
        Partitions source and destination tensors for a global memory store.

        This method generates a tiled copy for storing results to global memory
        and partitions the source (register or shared memory) and destination
        (global memory) tensors accordingly. The behavior varies based on whether
        TMA store is enabled.

        :param tidx: The thread index in epilogue warp groups.
        :type tidx: cutlass.Int32
        :param atom: The copy atom to be used (TMA or universal).
        :type atom: cute.CopyAtom or cute.TiledCopy
        :param gC_mnl: The global tensor C.
        :type gC_mnl: cute.Tensor
        :param epi_tile: The epilogue tiler.
        :type epi_tile: cute.Tile
        :param sC: The shared memory tensor C.
        :return: A tuple containing the appropriate copy atom and partitioned
                 source and destination tensors for the store operation.
        :rtype: tuple[cute.CopyAtom, cute.Tensor, cute.Tensor]
        """
        gC_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        if self.use_tma_store:
            tma_atom_c = atom
            sC_for_tma_partition = cute.group_modes(sC, 0, 2)
            gC_for_tma_partition = cute.group_modes(gC_epi, 0, 2)
            # ((ATOM_V, REST_V), EPI_M, EPI_N)
            # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
            bSG_sC, bSG_gC = cpasync.tma_partition(
                tma_atom_c,
                0,
                cute.make_layout(1),
                sC_for_tma_partition,
                gC_for_tma_partition,
            )
            return tma_atom_c, bSG_sC, bSG_gC
        else:
            tiled_copy_t2r = atom
            # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
            thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
            tTR_gC = thr_copy_t2r.partition_D(gC_epi)
            # (T2R, T2R_M, T2R_N)
            tTR_rC = cute.make_rmem_tensor(
                tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.c_dtype
            )
            simt_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.c_dtype)
            return simt_atom, tTR_rC, tTR_gC

    def epilog_smem_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Partitions source and destination tensors for a shared memory store.

        This method generates a tiled copy for storing results to shared memory
        and partitions the source (register) and destination (shared memory)
        tensors accordingly.

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy.
        :param tTR_rC: The partitioned accumulator tensor.
        :param tidx: The thread index in epilogue warp groups.
        :param sC: The shared memory tensor to be copied and partitioned.
        :return: A tuple containing the tiled copy for the store operation and
                 the partitioned source and destination tensors.
        """
        copy_atom_r2s = sm100_utils.get_smem_store_op(
            self.c_layout, self.c_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sC = thr_copy_r2s.partition_D(sC)
        # (R2S, R2S_M, R2S_N)
        tRS_rC = tiled_copy_r2s.retile(tTR_rC)
        return tiled_copy_r2s, tRS_rC, tRS_sC

    def epilog_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Partitions source and destination tensors for a tensor memory load.

        This method generates a tiled copy for loading accumulators from tensor
        memory and partitions the source (tensor memory) and destination
        (register) tensors accordingly.

        :param tidx: The thread index in epilogue warp groups.
        :param tAcc: The accumulator tensor to be copied and partitioned.
        :param gC_mnl: The global tensor C.
        :param epi_tile: The epilogue tiler.
        :param use_2cta_instrs: Whether use_2cta_instrs is enabled.
        :return: A tuple containing the tiled copy for the load operation and
                 the partitioned source and destination tensors.
        """
        # Make tiledCopy for tensor memory load
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.c_layout,
            self.c_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tAcc_epi = cute.flat_divide(
            tAcc[((None, None), 0, 0, None)],
            epi_tile,
        )
        # (EPI_TILE_M, EPI_TILE_N)
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, loopM, loopN, loopL)
        gC_mnl_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, loopM, loopN, loopL)
        tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    @staticmethod
    def align_up(x: int, align: int) -> int:
        """Align x up to the nearest multiple of align."""
        return (x + align - 1) // align * align

    @staticmethod
    def _compute_stages_and_tmem_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: tuple[int, int, int],
        cta_tile_shape_mnk: tuple[int, int, int],
        epi_tile: cute.Tile,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        transform_a_source: tcgen05.OperandSource,
        scale_granularity_m: int,
        scale_granularity_k: int,
        smem_buffer_align_bytes: int,
        use_tma_store: bool,
        scale_mode: TransformMode,
    ) -> tuple[int, int, int, int, int, int, int]:
        """
        Compute pipeline stages and TMEM column allocation configurations.

        This method calculates the number of pipeline stages for different operations
        (load2trans, trans2mma, accumulator, etc.) and determines TMEM column allocation
        based on available memory resources and tile configuration.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :type mma_tiler_mnk: tuple[int, int, int]
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param epi_tile: The epilogue tile shape.
        :type epi_tile: cute.Tile
        :param a_dtype: Data type of operand A.
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: type[cutlass.Numeric]
        :param c_dtype: Data type of operand C.
        :type c_dtype: type[cutlass.Numeric]
        :param c_layout: Layout enum of operand C.
        :type c_layout: utils.LayoutEnum
        :param transform_a_source: The source of the transformed A tensor.
        :type transform_a_source: tcgen05.OperandSource
        :param scale_granularity_m: The granularity of the scale tensor along the M mode.
        :type scale_granularity_m: int
        :param scale_granularity_k: The granularity of the scale tensor along the K mode.
        :type scale_granularity_k: int
        :param smem_buffer_align_bytes: The alignment of the shared memory buffer.
        :type smem_buffer_align_bytes: int
        :param use_tma_store: Whether TMA store is enabled.
        :type use_tma_store: bool
        :param scale_mode: The transform mode.
        :type scale_mode: TransformMode

        :return: A tuple containing the number of stages for:
                 (load2trans, scale_load2trans, transform2mma, accumulator, c, tmem_acc_cols, tmem_a_cols)
        :rtype: tuple[int, int, int, int, int, int, int]
        - num_load2trans_stage: Stages for load-to-transform A and B tensors pipeline
        - num_scale_load2trans_stage: Stages for scale load-to-transform A tensor pipeline
        - num_trans2mma_stage: Stages for transform-to-MMA pipeline
        - num_acc_stage: Stages for accumulator-to-epilogue pipeline
        - num_c_stage: Stages for epilogue-to-output C pipeline
        - num_acc_tmem_cols: TMEM columns for accumulator
        - num_a_tmem_cols: TMEM columns for transformed A tensor
        """
        # Compute tmem columns required for accumulator
        acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
        tCtAcc_stage1 = tiled_mma.make_fragment_C(cute.append(acc_shape, 1))
        num_tmem_acc_col_per_stage = utils.get_num_tmem_alloc_cols(tCtAcc_stage1, True)
        # Heuristic to decide the number of stages for accumulator
        sm100_tmem_columns = cute.arch.SM100_TMEM_CAPACITY_COLUMNS
        accumulator_stage_count = sm100_tmem_columns // num_tmem_acc_col_per_stage
        if transform_a_source == tcgen05.OperandSource.TMEM:
            if num_tmem_acc_col_per_stage < 128:
                accumulator_stage_count = 3
            elif num_tmem_acc_col_per_stage < 256:
                accumulator_stage_count = 2
            else:
                accumulator_stage_count = 1
        # transformed A in 16bit, thus 1 tmem column could hold 2 elements
        num_elts_per_tmem_col = 32 // tiled_mma.op.a_dtype.width
        num_tmem_cols_a_per_stage = MixedInputGemmKernel.align_up(
            (
                cta_tile_shape_mnk[2] // num_elts_per_tmem_col
                if transform_a_source == tcgen05.OperandSource.TMEM
                else 0
            ),
            4,
        )

        c_stage_count = 2 if use_tma_store else 0
        c_smem_layout_staged_one = (
            sm100_utils.make_smem_layout_epi(
                c_dtype,
                c_layout,
                epi_tile,
                1,
            )
            if use_tma_store
            else None
        )
        c_bytes_per_stage = (
            cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
            if use_tma_store
            else 0
        )
        c_bytes = c_bytes_per_stage * c_stage_count

        smem_capacity = utils.get_smem_capacity_in_bytes("sm_100")
        bytes_per_pipeline_stage = 16
        if scale_mode == TransformMode.ConvertOnly:
            scale_load2trans_stage_count = 0
            a_scale_bytes_per_stage = 0
        else:
            # Ensure we have 2 buffers for scale tiles needed for 1 CTA tile
            a_scale_k_mode = max(cta_tile_shape_mnk[2] // scale_granularity_k, 1)
            a_scale_m_mode = max(cta_tile_shape_mnk[0] // scale_granularity_m, 1)
            scale_load2trans_stage_count = 2
            a_scale_bytes_per_stage = MixedInputGemmKernel.align_up(
                cute.size_in_bytes(
                    tiled_mma.op.a_dtype,
                    cute.make_layout((a_scale_m_mode, a_scale_k_mode)),
                ),
                smem_buffer_align_bytes,
            )
        a_scale_bytes = (
            a_scale_bytes_per_stage + bytes_per_pipeline_stage
        ) * scale_load2trans_stage_count
        caveout_smem_bytes = (
            bytes_per_pipeline_stage * accumulator_stage_count + a_scale_bytes + c_bytes
        )

        # Compute transform stages if A is in TMEM
        num_tmem_acc_cols = MixedInputGemmKernel.align_up(
            accumulator_stage_count * num_tmem_acc_col_per_stage, 4
        )

        transform2mma_stage_count_a_source_tmem_potential = (
            (sm100_tmem_columns - num_tmem_acc_cols) // num_tmem_cols_a_per_stage
            if transform_a_source == tcgen05.OperandSource.TMEM
            else -1
        )
        if (
            transform_a_source == tcgen05.OperandSource.TMEM
            and transform2mma_stage_count_a_source_tmem_potential <= 0
        ):
            raise ValueError("Not enough TMEM capacity for selected tile size")
        a_load_bytes_per_stage = MixedInputGemmKernel.align_up(
            cute.size_in_bytes(
                a_dtype,
                cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
            ),
            smem_buffer_align_bytes,
        )
        b_load_bytes_per_stage = MixedInputGemmKernel.align_up(
            cute.size_in_bytes(
                b_dtype,
                cute.make_layout(
                    (
                        cta_tile_shape_mnk[1] // cute.size(tiled_mma.thr_id),
                        cta_tile_shape_mnk[2],
                    )
                ),
            ),
            smem_buffer_align_bytes,
        )
        ab_load_bytes_per_stage = (
            a_load_bytes_per_stage
            + b_load_bytes_per_stage
            + 2 * bytes_per_pipeline_stage
        )
        a_transform_bytes_per_stage = (
            MixedInputGemmKernel.align_up(
                cute.size_in_bytes(
                    tiled_mma.op.a_dtype,
                    cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
                ),
                smem_buffer_align_bytes,
            )
            if transform_a_source == tcgen05.OperandSource.SMEM
            else 0
        )

        a_transform_bytes_per_stage = (
            a_transform_bytes_per_stage + bytes_per_pipeline_stage
        )
        transform2mma_stage_count_a_source_smem_potential = (
            smem_capacity - caveout_smem_bytes
        ) // (ab_load_bytes_per_stage + a_transform_bytes_per_stage)
        transform2mma_stage_count = (
            min(
                transform2mma_stage_count_a_source_tmem_potential,
                transform2mma_stage_count_a_source_smem_potential,
            )
            if transform_a_source == tcgen05.OperandSource.TMEM
            else transform2mma_stage_count_a_source_smem_potential
        )
        load2transform_stage_count = (
            smem_capacity
            - caveout_smem_bytes
            - (transform2mma_stage_count * a_transform_bytes_per_stage)
        ) // ab_load_bytes_per_stage
        if (
            load2transform_stage_count < 2
            or transform2mma_stage_count < 2
            or accumulator_stage_count < 1
        ):
            raise ValueError("Not enough SMEM or TMEM capacity for selected tile size")
        num_tmem_a_cols = transform2mma_stage_count * num_tmem_cols_a_per_stage
        # Check if we can increase c_stage_count with leftover smem
        if use_tma_store:
            c_stage_count += (
                smem_capacity
                - load2transform_stage_count * ab_load_bytes_per_stage
                - transform2mma_stage_count * a_transform_bytes_per_stage
                - scale_load2trans_stage_count * a_scale_bytes_per_stage
                - c_bytes
            ) // c_bytes_per_stage

        return (
            load2transform_stage_count,
            scale_load2trans_stage_count,
            transform2mma_stage_count,
            accumulator_stage_count,
            c_stage_count,
            num_tmem_acc_cols,
            num_tmem_a_cols,
        )

    @staticmethod
    def _compute_smem_layout(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: tuple[int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        load2trans_stage_count: int,
        trans2mma_stage_count: int,
    ) -> tuple[
        cute.ComposedLayout,
        cute.ComposedLayout,
        cute.ComposedLayout,
    ]:
        """
        Compute shared memory layouts for tensor A, transformed A and tensor B.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :type mma_tiler_mnk: tuple[int, int, int]
        :param a_dtype: Data type of operand A.
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: type[cutlass.Numeric]
        :param load2trans_stage_count: Number of stages for load-to-transform pipeline.
        :type load2trans_stage_count: int
        :param trans2mma_stage_count: Number of stages for transform-to-MMA pipeline.
        :type trans2mma_stage_count: int

        :return: A tuple containing:
            - smem_layout_a: Shared memory layout for tensor A
            - smem_layout_a_transform: Shared memory layout for transformed tensor A
            - smem_layout_b: Shared memory layout for tensor B
        :rtype: tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
        """
        smem_layout_a = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            a_dtype,
            load2trans_stage_count,
        )
        smem_layout_a_transform = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            tiled_mma.op.a_dtype,
            trans2mma_stage_count,
        )
        smem_layout_b = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            b_dtype,
            load2trans_stage_count,
        )
        return (
            smem_layout_a,
            smem_layout_a_transform,
            smem_layout_b,
        )

    @staticmethod
    def _get_transform_a_source(
        a_major_mode: tcgen05.OperandMajorMode,
    ) -> tcgen05.OperandSource:
        """
        Determine the operand source for transformed A tensor based on the operand major mode.
        """
        if cutlass.const_expr(a_major_mode == tcgen05.OperandMajorMode.K):
            return tcgen05.OperandSource.TMEM
        else:
            return tcgen05.OperandSource.SMEM

    @staticmethod
    def _get_tma_atom_kind(
        mcast: cutlass.Boolean,
        use_2cta_instrs: bool,
        is_b: bool,
    ) -> Union[
        cpasync.CopyBulkTensorTileG2SMulticastOp, cpasync.CopyBulkTensorTileG2SOp
    ]:
        """
        Get the TMA atom kind based on 1) whether it's a multicast operation,
        2) whether 2CTA tcgen05.mma instruction is enabled, and
        3) whether it's a B tensor
        """
        # Not using .2CTA instructions for tensor A as the consumer is threads on different CTAs
        cta_group = (
            tcgen05.CtaGroup.TWO if (use_2cta_instrs and is_b) else tcgen05.CtaGroup.ONE
        )
        if cutlass.const_expr(mcast):
            return cpasync.CopyBulkTensorTileG2SMulticastOp(cta_group)
        return cpasync.CopyBulkTensorTileG2SOp(cta_group)

    @staticmethod
    def _get_copy_atom_a_transform(
        mma_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        transform_a_source: tcgen05.OperandSource,
        a_smem_shape: cute.Shape,
        a_dtype: type[cutlass.Numeric],
    ) -> cute.CopyAtom:
        """
        Determine the copy atom for transformed A tensor based on the operand source and tile size.
        """
        if cutlass.const_expr(transform_a_source == tcgen05.OperandSource.TMEM):
            if cutlass.const_expr(
                cute.size(a_smem_shape[0][0]) == 64 and (not use_2cta_instrs)
            ):
                copy_op_r2t = tcgen05.St16x256bOp(
                    tcgen05.Repetition(1), tcgen05.Unpack.NONE
                )
            else:
                copy_op_r2t = tcgen05.St32x32bOp(
                    tcgen05.Repetition(8), tcgen05.Unpack.NONE
                )
            return cute.make_copy_atom(copy_op_r2t, mma_dtype)
        else:
            return cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(), a_dtype, num_bits_per_copy=32
            )

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int]]:
        """
        Use persistent tile scheduler to compute the grid size for the output tensor C.
        """
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid

    def is_valid_scale_granularity(
        scale_granularity_m: int,
        scale_granularity_k: int,
        a_dtype: type[cutlass.Numeric],
        k: int,
        mma_tiler_k: int,
    ) -> bool:
        """
        Check if the scale granularity settings are valid for the given data type and problem size.
        """
        if a_dtype.width == 8:
            # No scale tensor for 8bit data type A
            if not (scale_granularity_m == 0 and scale_granularity_k == 0):
                return False
        elif a_dtype.width == 4:
            if scale_granularity_m != 1 or (
                scale_granularity_k == 0
                or k % scale_granularity_k != 0
                or scale_granularity_k % mma_tiler_k != 0
            ):
                return False
        return True

    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        scale_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        mma_tiler_mnk: tuple[int, int, int],
        use_2cta_instrs: bool,
        cluster_shape_mn: tuple[int, int],
        scale_granularity_m: int,
        scale_granularity_k: int,
    ) -> bool:
        """
        Check if the tensor alignments are valid for the given problem size and data types.
        """

        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if not (
            check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k))
            and check_contiguous_16B_alignment(b_dtype, b_major == "n", (n, k))
            and check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n))
            and (
                scale_granularity_k == 0
                or check_contiguous_16B_alignment(
                    b_dtype, True, (m, k // scale_granularity_k)
                )
            )
        ):
            return False
        # Check if scale tensor matches the TMA load 128B alignment requirement
        cta_tile_shape_mnk = (
            mma_tiler_mnk[0] // (2 if use_2cta_instrs else 1),
            mma_tiler_mnk[1],
            mma_tiler_mnk[2],
        )
        if (
            scale_granularity_m > 0
            and (cta_tile_shape_mnk[0] // cluster_shape_mn[1] // scale_granularity_m)
            * (scale_dtype.width // 8)
            < 128
        ):
            return False

        return True

    def is_valid_epilog_store_option(
        m: int,
        n: int,
        mma_tiler_mn: tuple[int, int],
        use_tma_store: bool,
        use_2cta_instrs: bool,
    ) -> bool:
        """
        Check if the epilogue store option is valid for the given problem size.
        """
        cta_tile_shape_mn = (
            mma_tiler_mn[0] // (2 if use_2cta_instrs else 1),
            mma_tiler_mn[1],
        )
        # No OOB tile support when TMA store is disabled
        if not use_tma_store:
            if not (m % cta_tile_shape_mn[0] == 0 and n % cta_tile_shape_mn[1] == 0):
                return False
        return True

    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
    ) -> bool:
        """
        Check if the MMA tiler and cluster shape are valid for the given problem size.
        """
        if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
            return False

        if (mma_tiler[0] // (2 if use_2cta_instrs else 1)) not in [64, 128]:
            return False
        return True

    def can_implement(
        mnkl: tuple[int, int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        scale_granularity_m: int,
        scale_granularity_k: int,
        mma_tiler: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
        use_tma_store: bool,
    ) -> bool:
        """
        Check if the kernel can be implemented for the given tensor shapes and data types.
        """
        m, n, k, l = mnkl

        if not MixedInputGemmKernel.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler, cluster_shape_mn, use_2cta_instrs
        ):
            return False
        if not MixedInputGemmKernel.is_valid_scale_granularity(
            scale_granularity_m, scale_granularity_k, a_dtype, k, mma_tiler[2]
        ):
            return False
        if not MixedInputGemmKernel.is_valid_tensor_alignment(
            m,
            n,
            k,
            a_dtype,
            b_dtype,
            c_dtype,
            b_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler,
            use_2cta_instrs,
            cluster_shape_mn,
            scale_granularity_m,
            scale_granularity_k,
        ):
            return False
        if not MixedInputGemmKernel.is_valid_epilog_store_option(
            m, n, mma_tiler[:2], use_tma_store, use_2cta_instrs
        ):
            return False
        return True


def create_i4_tensor_and_scale(
    l: int,
    m: int,
    k: int,
    is_m_major: bool,
    dtype: type[cutlass.Numeric],
    scale_granularity_m: int,
    scale_granularity_k: int,
    is_dynamic_layout: bool = True,
    init_config: tuple = (
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-7, max_val=6),
    ),
    divisibility: int = 16,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[
    cute.Tensor, torch.Tensor, torch.Tensor, cute.Tensor, torch.Tensor, torch.Tensor
]:
    """
    Create quantized 4-bit tensor and corresponding scale tensor.
    """
    lb_4b = -8 if dtype == cutlass.Int4 else 0
    up_4b = 7 if dtype == cutlass.Int4 else 15
    if not (
        init_config[0] == cutlass_torch.TensorInitType.RANDOM
        or init_config[0] == cutlass_torch.TensorInitType.SCALAR
    ):
        raise ValueError(
            "Only random and scalar initialization is supported for 4bit data type"
        )

    # Construct reference tensor in f32
    ref_fp32 = cutlass_torch.matrix(l, m, k, is_m_major, cutlass.Float32, *init_config)
    # Generate scale data and perform quantization
    num_scales = k // scale_granularity_k
    ref = ref_fp32.to(dtype=cutlass_torch.dtype(transformed_dtype)).reshape(
        m, num_scales, scale_granularity_k, l
    )
    # Get elements with maximum absolute value to compute scaling factors
    a_max = torch.maximum(ref / up_4b, ref / lb_4b)
    a_scales, _ = torch.max(a_max, dim=2, keepdim=True)
    a_scale_inv = torch.where(a_scales == 0, 0, 1 / a_scales)
    a_quant = ref * a_scale_inv
    # Convert values to integer to avoid computation errors
    a_quant = a_quant.to(dtype=torch.int32).reshape((m, k, l)).to(dtype=torch.float32)
    # Construct A quantized tensor
    cute_a_quant_tensor, torch_a_quant_tensor = cutlass_torch.cute_tensor_like(
        a_quant, dtype, is_dynamic_layout=is_dynamic_layout, assumed_align=divisibility
    )
    # Construct cute scale tensor
    a_scales = a_scales.random_(-3, 3).reshape((m, num_scales, l))
    # Scale tensor is always m-major
    a_scales = a_scales.permute(2, 1, 0).contiguous().permute(2, 1, 0).to(device="cuda")
    cute_scale_tensor = from_dlpack(a_scales, assumed_align=divisibility)
    for i, stride in enumerate(a_scales.stride()):
        if stride == 1:
            leading_dim = i
            break
    if is_dynamic_layout:
        cute_scale_tensor = cute_scale_tensor.mark_layout_dynamic(
            leading_dim=leading_dim
        )

    return (
        cute_a_quant_tensor,
        torch_a_quant_tensor,
        a_quant.to("cpu"),
        cute_scale_tensor,
        a_scales,
        a_scales.to("cpu"),
    )


def get_divisibility(contiguous_dim_size: int, upper_bound: int = 128) -> int:
    """
    Calculate the largest power of 2 divisibility factor for memory alignment.
    """
    # Check the largest power of 2 factor of contiguous_dim_size
    for i in range(int(log2(contiguous_dim_size)), 0, -1):
        if contiguous_dim_size % (2**i) == 0:
            return min(2**i, upper_bound)
    return 1


def create_tensor_a(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: type[cutlass.Numeric],
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[cute.Tensor, cute.Tensor, torch.Tensor, torch.Tensor]:
    """
    Create tensor A and scale tensor.
    """
    a_scale_tensor = None
    a_scale_torch_cpu = None
    if a_dtype in (cutlass.Int4,):
        (
            a_tensor,
            a_torch_gpu,
            a_torch_cpu,
            a_scale_tensor,
            a_scale_torch_gpu,
            a_scale_torch_cpu,
        ) = create_i4_tensor_and_scale(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
            scale_granularity_m,
            scale_granularity_k,
            divisibility=get_divisibility(m if a_major == "m" else k),
            transformed_dtype=transformed_dtype,
        )
    else:
        a_torch_cpu = cutlass_torch.matrix(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
        )
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu,
            a_dtype,
            is_dynamic_layout=True,
            assumed_align=get_divisibility(m if a_major == "m" else k),
        )
    return a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu


def create_tensors(
    l: int,
    m: int,
    n: int,
    k: int,
    a_major: str,
    b_major: str,
    c_major: str,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
) -> tuple:
    """
    Create all input and output tensors for the mixed-input GEMM.
    """
    torch.manual_seed(2025)

    a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
        l, m, k, a_major, a_dtype, scale_granularity_m, scale_granularity_k, b_dtype
    )

    b_torch_cpu = cutlass_torch.matrix(
        l,
        n,
        k,
        b_major == "n",
        b_dtype,
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-10, max_val=10),
    )
    c_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        n,
        c_major == "m",
        c_dtype,
    )

    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu,
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=get_divisibility(n if b_major == "n" else k),
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=get_divisibility(m if c_major == "m" else n),
    )
    c_tensor = c_tensor.mark_compact_shape_dynamic(
        mode=(0 if c_major == "m" else 1),
        stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
        divisibility=get_divisibility(m if c_major == "m" else n),
    )

    return (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        c_torch_gpu,
    )


def compare(
    a_torch_cpu: torch.Tensor,
    b_torch_cpu: torch.Tensor,
    a_scale_torch_cpu: Optional[torch.Tensor],
    c_torch_gpu: torch.Tensor,
    c_dtype: type[cutlass.Numeric],
    tolerance: float,
) -> None:
    """
    Compare kernel result with reference computation.
    """
    kernel_result = c_torch_gpu.cpu()
    # Compute reference result
    if a_scale_torch_cpu is not None:
        scale_shape = a_scale_torch_cpu.shape
        a_shape = a_torch_cpu.shape
        a_scale_torch_cpu = a_scale_torch_cpu.to(dtype=torch.float32).reshape(
            scale_shape[0], scale_shape[1], 1, scale_shape[2]
        )
        a_torch_cpu = a_torch_cpu.to(dtype=torch.float32).reshape(
            a_torch_cpu.shape[0], scale_shape[1], -1, a_torch_cpu.shape[2]
        )
        a_dequant = a_torch_cpu * a_scale_torch_cpu
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_dequant.reshape(a_shape),
            b_torch_cpu.to(dtype=torch.float32),
        )
    else:
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch_cpu.to(dtype=torch.float32),
            b_torch_cpu.to(dtype=torch.float32),
        )
    # Convert ref to c_dtype
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Assert close results
    torch.testing.assert_close(kernel_result, ref_result, atol=tolerance, rtol=1e-05)


def run(
    mnkl: tuple[int, int, int, int],
    scale_granularity_m: int,
    scale_granularity_k: int,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mnk: tuple[int, int, int],
    cluster_shape_mn: tuple[int, int],
    use_2cta_instrs: bool,
    use_tma_store: bool,
    tolerance: float,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
) -> None:
    """
    Run the mixed-input GEMM kernel with specified parameters.

    This function creates tensors, validates parameters, executes the kernel,
    optionally compares results with a reference implementation and reports
    kernel execution time.
    """
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise ValueError("CUDA is not available")

    # Check if given configuration is supported
    if not MixedInputGemmKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        scale_granularity_m,
        scale_granularity_k,
        mma_tiler_mnk,
        cluster_shape_mn,
        use_2cta_instrs,
        use_tma_store,
    ):
        raise ValueError("GEMM configuration not supported")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        c_torch_gpu,
    ) = create_tensors(
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        c_major,
        a_dtype,
        b_dtype,
        c_dtype,
        scale_granularity_m,
        scale_granularity_k,
    )

    mixed_input_gemm = MixedInputGemmKernel(
        scale_granularity_m,
        scale_granularity_k,
        acc_dtype,
        use_2cta_instrs,
        mma_tiler_mnk,
        cluster_shape_mn,
        use_tma_store,
    )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1],
    )
    compiled_kernel = cute.compile(
        mixed_input_gemm,
        a_tensor,
        a_scale_tensor,
        b_tensor,
        c_tensor,
        max_active_clusters,
        current_stream,
    )

    if not skip_ref_check:
        compiled_kernel(
            a_tensor,
            a_scale_tensor,
            b_tensor,
            c_tensor,
            current_stream,
        )
        compare(
            a_torch_cpu, b_torch_cpu, a_scale_torch_cpu, c_torch_gpu, c_dtype, tolerance
        )

    # Early return if no performance measurement is needed
    if iterations <= 0:
        return

    def generate_tensors():
        a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
            l, m, k, a_major, a_dtype, scale_granularity_m, scale_granularity_k, b_dtype
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu,
            b_dtype,
            is_dynamic_layout=True,
            assumed_align=get_divisibility(n if b_major == "n" else k),
        )
        c_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)
        c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
            c_torch_cpu,
            c_dtype,
            is_dynamic_layout=True,
            assumed_align=get_divisibility(m if c_major == "m" else n),
        )
        c_tensor = c_tensor.mark_compact_shape_dynamic(
            mode=(0 if c_major == "m" else 1),
            stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
            divisibility=get_divisibility(m if c_major == "m" else n),
        )
        return testing.JitArguments(
            a_tensor, a_scale_tensor, b_tensor, c_tensor, current_stream
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_gpu.numel() * c_torch_gpu.element_size()
            + a_scale_torch_cpu.numel() * a_scale_torch_cpu.element_size()
            if a_scale_torch_cpu is not None
            else 0
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mnkl", type=parse_comma_separated_ints, default=(128, 128, 128, 1)
    )
    parser.add_argument(
        "--mma_tiler_mnk", type=parse_comma_separated_ints, default=(128, 128, 128)
    )
    parser.add_argument(
        "--cluster_shape_mn", type=parse_comma_separated_ints, default=(1, 1)
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=cutlass.Int4,
        choices=[cutlass.Int8, cutlass.Uint8, cutlass.Int4],
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        choices=[cutlass.BFloat16, cutlass.Float16],
    )
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="m")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--scale_granularity_m",
        type=int,
        default=1,
        help="Scale granularity along M dimension.",
    )
    parser.add_argument(
        "--scale_granularity_k",
        type=int,
        default=128,
        help="Scale granularity along K dimension.",
    )
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
    args = parser.parse_args()

    run(
        args.mnkl,
        args.scale_granularity_m,
        args.scale_granularity_k,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler_mnk,
        args.cluster_shape_mn,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
    )
    print("PASS")
