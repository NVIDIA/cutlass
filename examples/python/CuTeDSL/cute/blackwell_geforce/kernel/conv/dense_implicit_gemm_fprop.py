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
from functools import lru_cache
from typing import Optional, Tuple, Type
import sys

import cuda.bindings.driver as cuda

import torch
import torch.nn.functional as F

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.runtime import from_dlpack
from cutlass.torch import dtype as torch_dtype
import cutlass.utils as utils
from cutlass.memory import SmemAllocator, get_smem_capacity_in_bytes
from cutlass.tensor_utils import LayoutEnum
from cutlass.cute.nvgpu import cpasync
import cutlass.pipeline as pipeline
import cutlass.utils.hopper_helpers as sm90_utils
from cutlass.cute.arch.constants import WARPS_PER_WARPGROUP
from pathlib import Path

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.dynamic_persistent_tile_scheduler import (
    ClcDynamicPersistentTileScheduler,
    ClcDynamicPersistentTileSchedulerParams,
)
from helpers.conv_helpers import (
    EPILOGUE_ACTIVATIONS,
    SMEM_BUFFER_ALIGN_BYTES,
    SMEM_VECTOR_ALIGN_BYTES,
    add_dummy_batch_dimension,
    bias_dtype_for_output,
    check_conv_geometry,
    check_im2col_descriptor_limits,
    check_tensor_alignment,
    compute_fprop_im2col_params,
    compute_grid,
    compute_zpq,
    create_cute_tensor,
    frontend_cache_token,
    make_fake_conv_tensor,
    parse_comma_separated_ints,
    prepare_fprop_tensors,
    rt_conv_scalars,
    solve_max_smem_stages,
    trace_conv_scalars,
)

"""
A high-performance 3D implicit-GEMM based fprop convolution example for the NVIDIA
Blackwell Geforce
(SM120) architecture using CUTE DSL.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor D is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Operand loads: the input tensor A by Tensor Memory Access (TMA) im2col, which
      performs the
      im2col transformation on the fly, and the filter tensor B by TMA tiled
    - Utilizes warp MMA for matrix multiply-accumulate (MMA) operations
    - Supports multi-stage pipeline to overlap computation and memory access
    - Ping-pong MMA warpgroups with parity-based tile ownership
    - CLC-based dynamic persistent tile scheduling
    - Fused epilogue computing in FP32, D = activation(alpha * acc + bias + beta *
      residual),
      with an optional per-output-channel bias and a compile-time activation; this
      kernel
      currently supports only alpha = 1 and beta = 0

This implicit-GEMM based convolution works by converting the convolution into a GEMM
problem with the following mapping:
- GEMM M dimension maps to NxZxPxQ
- GEMM N dimension maps to K
- GEMM K dimension maps to TxRxSxC
During the load of input tensor to SMEM, the TMA operation performs the im2col
transformation on the input tensor A.
This transforms the A matrix into the required shape for the GEMM operation (NxZxPxQ by
TxRxSxC), and may involve replication of the input elements.
Filter tensor can be loaded to SMEM without any transformation.
The output tensor D is then stored to GMEM via the im2col TMA store (no transformation
necessary).

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/cute/blackwell_geforce/kernel/conv/dense_implicit_gemm_fprop.py \
      --ncdhw 1,64,8,8,8 --ktrs 128,3,3,3                          \
      --ab_dtype Float16 --d_dtype Float16 --acc_dtype Float32     \
      --tile_shape_mnk 128,128,64                                  \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                  \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/CuTeDSL/cute/blackwell_geforce/kernel/conv/dense_implicit_gemm_fprop.py \
      --ncdhw 1,64,8,8,8 --ktrs 128,3,3,3                          \
      --ab_dtype Float16 --d_dtype Float16 --acc_dtype Float32     \
      --tile_shape_mnk 128,128,64                                  \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                  \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1                           \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* Supported input data types: fp16, bf16, fp8 (e4m3, e5m2)
* A/B tensor must have the same data type
* Supported accumulator data types: fp16, fp32
* Supported output data types: fp16, bf16, fp32, fp8 (e4m3, e5m2)
* CTA tile shape M must be 32 or a multiple of 64: a whole number of the 32-row MMA
  tile, and a whole number of the epilogue tile, which caps at 64 rows
* CTA tile shape N must be a multiple of 32, the width of one MMA tile
* CTA tile shape K must be 32/64/128
* The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4 for Float32, 8 for Float16/BFloat16 and
  16 for Float8E4M3FN/Float8E5M2.
* The convolution geometry must leave a positive output extent, so that the problem
  covers at least one CTA tile along M and along N.
* The bias, when supplied, is a length-K tensor of a 16- or 32-bit float type
  (default derived from the output type).
"""


class Sm120DenseImplicitGemmFpropKernel:
    """
    Persistent 3D convolution kernel.
    The input (A) is expected to be in 5D tensor (NDHWC) format and is loaded via the
    TMA im2col load atom.
    The filter (B) is expected to be in 5D tensor (KTRSC) format and is loaded via the
    TMA tiled load atom.
    The output (D) is expected to be in 5D tensor (NZPQK) format and is stored via the
    im2col TMA store.
    The implicit GEMM runs on ping-pong MMA warpgroups with parity-based tile ownership,
    scheduled by a CLC-based dynamic persistent tile scheduler.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :type tile_shape_mnk: Tuple[int, int, int]

    :note: The convolution geometry (filter T/R/S, padding, stride, dilation) is not a
        constructor parameter: T/R/S come from the filter tensor extents and
        pad/stride/dilation arrive as runtime Int32 operands to __call__, so a single
        compiled cubin serves any geometry.

    :note: In current version, A and B tensor must be C major. D tensor must be K major.

    :note: In current version, A and B tensor must have the same data type

    :note: Supported A/B data types:
        - Float16/BFloat16
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32
        - Float16

    :note: Supported D data types:
        - Float32
        - Float16/BFloat16
        - Float8E4M3FN/Float8E5M2

    :note: Constraints:
        - CTA tile shape M must be 32 or a multiple of 64: a whole number of the 32-row
          MMA tile, and a whole number of the epilogue tile, which caps at 64 rows
        - CTA tile shape N must be a multiple of 32, the width of one MMA tile
        - CTA tile shape K must be 32/64/128
        - The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
          i.e, number of elements is a multiple of 4 for Float32, 8 for
          Float16/BFloat16 and 16 for Float8E4M3FN/Float8E5M2
        - The convolution geometry must leave a positive output extent
        - The bias, when supplied, is a length-K tensor of a 16- or 32-bit float type

    **Example:**

    .. code-block:: python
        conv = Sm120DenseImplicitGemmFpropKernel(
            acc_dtype=cutlass.Float32,
            tile_shape_mnk=(128, 128, 64),
        )
        conv(
            a, b, d,
            bias,  # optional length-K bias tensor, or None
            upper_pad_d, upper_pad_h, upper_pad_w,
            lower_pad_d, lower_pad_h, lower_pad_w,
            stride_d, stride_h, stride_w,
            dil_d, dil_h, dil_w,
            max_active_clusters,
            stream,
            epilogue_op,
        )
    """

    # Fixed for every configuration, so static checks read them off the class:
    # the tiled MMA's warp layout, the single-CTA cluster, and the M/N extent of
    # one warp MMA instruction (its K follows the input type).
    atom_layout = (2, 2, 1)
    cluster_shape_mnk = (1, 1, 1)
    mma_inst_mn = (16, 8)

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
    ):
        self.acc_dtype = acc_dtype
        self.tile_shape_mnk = tuple(tile_shape_mnk)
        self.tiled_mma = None
        self.num_mcast_ctas_a = None
        self.num_mcast_ctas_b = None
        self.is_a_mcast = False
        self.is_b_mcast = False

        self.occupancy = 1

        # Use 2 mma warpgroups for ping pong
        self.num_mma_warps = (
            self.atom_layout[0] * self.atom_layout[1] * self.atom_layout[2] * 2
        )
        self.num_dma_warps = 1
        self.num_sched_warps = 1  # CLC scheduler warp for dynamic persistent scheduling
        self.num_threads_per_warp = 32
        self.threads_per_cta = (
            self.num_mma_warps + self.num_dma_warps + self.num_sched_warps
        ) * self.num_threads_per_warp

        # Round up to the nearest warp group so that register reallocation works
        self.threads_per_cta = (self.threads_per_cta + 127) // 128 * 128

        # Shared memory capacity of the compile target.
        self.smem_capacity = get_smem_capacity_in_bytes()

        self.num_ab_stage = None
        self.num_d_stage = None
        self.num_clc_stage = 1

        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None

        self.shared_storage = None

        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=128,
        )
        # Bias staging ring depth: two rows let the DMA warp stage the next
        # tile's bias row while the current tile's owner reads its own.
        self.num_bias_stage = 2
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

    def _setup_conv_input_attrs(self, a, b, d) -> None:
        """Set input-dependent attributes for convolution.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        """
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.d_dtype = d.element_type

        # K-major layouts for all operands in the GEMM view
        self.a_layout = LayoutEnum.ROW_MAJOR
        self.b_layout = LayoutEnum.ROW_MAJOR
        self.d_layout = LayoutEnum.ROW_MAJOR

    def _setup_attributes(self) -> None:
        """Set up configurations that are dependent on convolution inputs."""
        # --- MMA and tile shapes ---
        # FP8 operands take the .e4m3/.e5m2 MMA on its K=32 atom, which is where
        # FP8's doubled rate lives: one instruction covers twice the K.
        is_fp8 = self.a_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        if is_fp8:
            self.mma_inst_mnk = (*self.mma_inst_mn, 32)
            op = cute.nvgpu.warp.MmaFP8Op(
                self.a_dtype,
                self.acc_dtype,
                self.mma_inst_mnk,
            )
        else:
            self.mma_inst_mnk = (*self.mma_inst_mn, 16)
            op = cute.nvgpu.warp.MmaF16BF16Op(
                self.a_dtype,
                self.acc_dtype,
                self.mma_inst_mnk,
            )

        tC = cute.make_layout(self.atom_layout)
        permutation_mnk = (
            self.atom_layout[0] * self.mma_inst_mn[0],
            self.atom_layout[1] * self.mma_inst_mn[1] * 2,
            self.atom_layout[2] * self.mma_inst_mnk[2],
        )
        self.tiled_mma = cute.make_tiled_mma(
            op,
            tC,
            permutation_mnk=permutation_mnk,
        )

        # --- Epilogue tile ---
        self.epi_tile = sm90_utils.compute_tile_shape_or_override(
            self.tile_shape_mnk, self.d_dtype, is_cooperative=False
        )

        # --- Pipeline stages and smem layouts ---
        # The epilogue drains through a fixed four-deep staging ring; every byte
        # left over goes to A/B stages, solved against the exact SharedStorage
        # footprint so the stage-scaled mbarriers and every alignment pad are
        # accounted for.
        self.num_d_stage = 4
        self._solve_smem_stages(Sm120DenseImplicitGemmFpropKernel._make_shared_storage)

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.a_layout,
            self.b_dtype,
            self.b_layout,
            self.num_ab_stage,
            self.d_dtype,
            self.d_layout,
            self.num_d_stage,
        )

        # --- TMA transaction bytes ---
        # Compute the TMA transaction bytes of one A/B stage
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, 0))
        self.num_tma_load_bytes = cute.size_in_bytes(
            self.a_dtype, a_smem_layout
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout)

        # --- Cluster layouts ---
        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

        self.num_mcast_ctas_a = self.cluster_shape_mnk[1]
        self.num_mcast_ctas_b = self.cluster_shape_mnk[0]
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

    def _solve_smem_stages(self, make_shared_storage) -> None:
        """Solve the deepest A/B stage count that fits in shared memory.

        :param make_shared_storage: Unbound _make_shared_storage of the kernel
            class, called with self for every candidate A/B stage count
        """
        counts = solve_max_smem_stages(
            lambda **kw: make_shared_storage(self, **kw),
            self.smem_capacity,
            primary="num_ab_stage",
            start={"num_ab_stage": 1},
        )
        self.num_ab_stage = counts["num_ab_stage"]

    def _setup_conv_tma(
        self, a, b, d, rt_upper_pad_dhw, rt_lower_pad_dhw, rt_stride_dhw, rt_dil_dhw
    ):
        """Set up TMA atoms and tensors for im2col convolution.

        The pad / stride / dilation operands feed the im2col A descriptor corners.
        They arrive as runtime cutlass.Int32, which the rt_ prefix marks, so one
        compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)
        :returns: (tma_atom_a, tma_tensor_a, tma_atom_b, tma_tensor_b,
                tma_atom_d, tma_tensor_d)
        """
        tma_atom_a, tma_tensor_a = self._make_a_im2col_tma_atom(
            a,
            b,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )
        tma_atom_b, tma_tensor_b = self._make_b_tiled_tma_atom(b)

        # --- D: TMA im2col store ---
        # Change view of output tensor from (N, Z, P, Q, K) to ((Q, P, Z, N), K)
        mD = cute.make_tensor(d.iterator, cute.select(d.layout, mode=[3, 2, 1, 0, 4]))
        mD = cute.group_modes(mD, begin=0, end=4)

        epi_smem_layout = cute.slice_(self.epi_smem_layout_staged, (None, None, 0))

        tma_atom_d, tma_tensor_d = cpasync.make_im2col_tma_atom(
            cpasync.CopyBulkTensorIm2ColS2GOp(),
            mD,
            epi_smem_layout,
            self.epi_tile,
        )
        tma_tensor_d = cute.coalesce(tma_tensor_d, target_profile=(1, 1))

        # Add dummy batch dimension to all tensors (GEMM kernel expects batch dimension)
        tma_tensor_a = add_dummy_batch_dimension(tma_tensor_a)
        tma_tensor_b = add_dummy_batch_dimension(tma_tensor_b)
        tma_tensor_d = add_dummy_batch_dimension(tma_tensor_d)

        return (
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
        )

    def _make_a_im2col_tma_atom(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        rt_upper_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_lower_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_stride_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_dil_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
    ) -> Tuple[cute.CopyAtom, cute.Tensor]:
        """Make A's im2col TMA load atom.

        A is the operand the im2col descriptor walks: it is viewed as
        ((W, H, D, N), C) so the descriptor's box slides over the spatial modes,
        and its corners come from the runtime pad/stride/dilation operands and the
        filter tensor's own extents.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)

        :return: (tma_atom_a, tma_tensor_a)
        """
        # Filter T/R/S sourced from the filter tensor (K, T, R, S, C): under the
        # dynamic tensor layout these extents are runtime Int32, so one compiled
        # cubin serves any T/R/S.
        rt_filter_trs = (b.shape[1], b.shape[2], b.shape[3])

        # Compute im2col descriptor parameters (DHW -> WHD order)
        (
            lower_corner_whd,
            upper_corner_whd,
            lower_padding_whd,
            upper_padding_whd,
            stride_whd,
            lower_srt,
            stride_srt,
        ) = compute_fprop_im2col_params(
            rt_filter_trs,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        a_copy_atom = cpasync.CopyBulkTensorIm2ColG2SOp()

        # Create 2-mode hierarchical tensor layout: (N, D, H, W, C) -> ((W, H, D, N), C)
        mA = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[3, 2, 1, 0, 4]))
        mA = cute.group_modes(mA, begin=0, end=4)

        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, 0))

        # Use the lower-level make_im2col_tma_atom (compatible with SM90-style rank-2
        # SMEM layouts)
        return cpasync.make_im2col_tma_atom(
            a_copy_atom,
            mA,
            a_smem_layout,
            # cta_tiler = (M, (K,)): the MMA tiler tiles the channel dimension, so
            # the K mode is nested to match the grouped channel mode of mA.
            (self.tile_shape_mnk[0], (self.tile_shape_mnk[2],)),
            lower_corner_whd,
            upper_corner_whd,
            lower_padding_whd,
            upper_padding_whd,
            stride_whd,
            lower_srt,
            stride_srt,
        )

    def _make_b_tiled_tma_atom(
        self, b: cute.Tensor
    ) -> Tuple[cute.CopyAtom, cute.Tensor]:
        """Make B's tiled TMA load atom.

        B is the filter, which reaches shared memory without any transformation: it
        is viewed as (K, (C, S, R, T)) so its GEMM-K mode groups the channel and
        filter-spatial modes.

        :param b: Filter tensor B - (K, T, R, S, C) layout

        :return: (tma_atom_b, tma_tensor_b)
        """
        # Change view of filter tensor from (K, T, R, S, C) to (K, (C, S, R, T)). The
        # reorder is a mode selection on the dynamic-layout filter tensor, so the view
        # inherits its runtime C/T/R/S extents and strides.
        mB = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[0, 4, 3, 2, 1]))
        mB = cute.group_modes(mB, begin=1, end=5)

        # The cta_tiler K mode is nested (tileK,): mB's K is the (C, S, R, T) group
        # with runtime S/R/T, and a nested tiler tiles only its first (channel) level.
        # That gives a static (tileK,) tile with the runtime S/R/T left in the rest,
        # so the TMA CTA V-map (the tiler composed with identity(gmem.shape)) stays
        # static while C and S/R/T stay runtime.
        return self._make_tma_atoms_and_tensors(
            mB,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], (self.tile_shape_mnk[2],)),
            1,
        )

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: tuple[int, int, int],
        epi_tile: tuple[int, int],
        a_dtype: type[cutlass.Numeric],
        a_layout: cute.Layout,
        b_dtype: type[cutlass.Numeric],
        b_layout: cute.Layout,
        num_ab_stage: int,
        d_dtype: type[cutlass.Numeric],
        d_layout: cute.Layout,
        num_d_stage: int,
    ) -> tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Create shared memory layouts for the A, B and D tensors.

        :param tile_shape_mnk: CTA tile shape (M, N, K)
        :type tile_shape_mnk: tuple[int, int, int]
        :param epi_tile: Epilogue tile shape
        :type epi_tile: tuple[int, int]
        :param a_dtype: Data type for matrix A
        :type a_dtype: type[cutlass.Numeric]
        :param a_layout: Layout for matrix A
        :type a_layout: cute.Layout
        :param b_dtype: Data type for matrix B
        :type b_dtype: type[cutlass.Numeric]
        :param b_layout: Layout for matrix B
        :type b_layout: cute.Layout
        :param num_ab_stage: Number of stages for the A/B tensors
        :type num_ab_stage: int
        :param d_dtype: Data type for the output matrix D
        :type d_dtype: type[cutlass.Numeric]
        :param d_layout: Layout for the output matrix D
        :type d_layout: cute.Layout
        :param num_d_stage: Number of epilogue stages
        :type num_d_stage: int

        :return: Tuple of shared memory layouts for A, B and the epilogue
        :rtype: Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
        """
        a_smem_layout_staged = sm90_utils.make_smem_layout_a(
            a_layout,
            tile_shape_mnk,
            a_dtype,
            num_ab_stage,
        )

        b_smem_layout_staged = sm90_utils.make_smem_layout_b(
            b_layout,
            tile_shape_mnk,
            b_dtype,
            num_ab_stage,
        )

        epi_smem_layout_staged = sm90_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            num_d_stage,
        )

        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    def _make_shared_storage(self, *, num_ab_stage: int):
        """Complete shared-memory layout for one candidate A/B stage count.

        Stage selection sizes candidates through it and the device entry allocates
        through it. Every shared-memory consumer of this kernel is a field here, in
        three runs: pipeline barriers, small odds and ends, then the tensor buffers.
        """
        a_smem, b_smem, d_smem = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.a_layout,
            self.b_dtype,
            self.b_layout,
            num_ab_stage,
            self.d_dtype,
            self.d_layout,
            self.num_d_stage,
        )
        num_clc_stage = self.num_clc_stage
        num_bias_stage = self.num_bias_stage
        has_bias = self.has_bias
        bias_dtype = self.bias_dtype if has_bias else self.d_dtype
        cta_n = self.tile_shape_mnk[1]
        a_dtype, b_dtype, d_dtype = self.a_dtype, self.b_dtype, self.d_dtype
        align = SMEM_BUFFER_ALIGN_BYTES

        @cute.struct
        class SharedStorage:
            # Pipeline barriers, in construction order.
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, num_ab_stage * 2
            ]
            # 2 Stage * 2 Groups order pipeline
            math_wg_order_barrier_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
            # PipelineCpAsync mbarriers for the bias staging ring (full+empty per
            # stage). Zero when no bias is supplied.
            bias_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, num_bias_stage * 2 if has_bias else 0
            ]
            clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_clc_stage * 2]
            # Small odds and ends.
            clc_response: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int32, num_clc_stage * 4], 16
            ]
            # Tensor buffers, last: epilogue staging first, then the mainloop
            # operand buffers at the very end of the storage, which keeps every
            # other field's offset fixed when an operand buffer grows.
            sD: cute.struct.Align[
                cute.struct.MemRange[d_dtype, cute.cosize(d_smem)], align
            ]
            # Ring of cta_tile_n bias rows: the DMA warp stages each tile's row and
            # the tile's owning math warpgroup reads it back. Each row carries the
            # bias element type, which has a 16-bit floor. Zero length without a
            # bias so it costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[
                    bias_dtype, num_bias_stage * cta_n if has_bias else 0
                ],
                SMEM_VECTOR_ALIGN_BYTES,
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[a_dtype, cute.cosize(a_smem)], align
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[b_dtype, cute.cosize(b_smem)], align
            ]

        return SharedStorage

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged: cute.ComposedLayout,
        smem_tile: tuple[int, int],
        mcast_dim: int,
        internal_type: Optional[Type[cutlass.Numeric]] = None,
    ) -> tuple[cute.CopyAtom, cute.Tensor]:
        """Create TMA atoms and tensors for input tensors.

        :param tensor: Input tensor (A or B)
        :type tensor: cute.Tensor
        :param smem_layout_staged: Shared memory layout for the tensor
        :type smem_layout_staged: cute.ComposedLayout
        :param smem_tile: Shared memory tile shape
        :type smem_tile: Tuple[int, int]
        :param mcast_dim: Multicast dimension
        :type mcast_dim: int
        :param internal_type: Element type the descriptor addresses, for a
            sub-byte operand whose storage type it cannot encode
        :type internal_type: Optional[Type[cutlass.Numeric]]

        :return: TMA atom and tensor
        :rtype: Tuple[cute.CopyAtom, cute.Tensor]
        """
        op = (
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp()
        )

        if cutlass.const_expr(cute.rank(smem_layout_staged) == 4):
            smem_layout = cute.slice_(smem_layout_staged, (None, None, None, 0))
        else:
            smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op,
            tensor,
            smem_layout,
            smem_tile,
            num_multicast=mcast_dim,
            internal_type=internal_type,
        )

        return tma_atom, tma_tensor

    def epilog_smem_store_copy_and_partition(
        self,
        tiled_mma: cute.TiledMma,
        accumulators: cute.Tensor,
        tidx: cutlass.Int32,
        sD: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor, cute.Layout]:
        """Make the tiledCopy for the register-to-smem store and partition with it.

        :param tiled_mma: Tiled MMA object, whose C partition sets the thread-value
            layout the store has to match
        :type tiled_mma: cute.TiledMma
        :param accumulators: The register accumulator tensor
        :type accumulators: cute.Tensor
        :param tidx: The thread index within the CTA
        :type tidx: cutlass.Int32
        :param sD: The shared memory staging tensor for D
        :type sD: cute.Tensor

        :return: A tuple containing (tiled_copy_r2s, tRS_sD, tRS_rAcc, tRS_rD,
            tRS_rD_layout) where:
            - tiled_copy_r2s: The tiled copy operation for register to smem copy(r2s)
            - tRS_sD: The partitioned tensor D (smem destination)
            - tRS_rAcc: The accumulator retiled to the store's fragment
            - tRS_rD: The register tensor the epilogue narrows into
            - tRS_rD_layout: Its layout, which the bias fragment reuses
        :rtype: Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor,
            cute.Layout]
        """
        copy_atom_r2s = sm90_utils.sm90_get_smem_store_op(
            self.d_layout,
            elem_ty_d=self.d_dtype,
            elem_ty_acc=self.acc_dtype,
        )

        # StMatrix is a 16-bit instruction; pass f16 so the partition
        # geometry is consistent regardless of d_dtype.
        # The actual rmem->smem store is performed by copy_atom_r2s above.
        copy_atom_C = cute.make_copy_atom(
            cute.nvgpu.warp.StMatrix8x8x16bOp(
                self.d_layout.is_m_major_c(),
                4,
            ),
            cutlass.Float16,
        )

        tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)

        tiled_copy_r2s = cute.make_tiled_copy_S(
            copy_atom_r2s,
            tiled_copy_C_Atom,
        )

        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx % 128)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        tRS_sD = thr_copy_r2s.partition_D(sD)
        # (R2S, R2S_M, R2S_N)
        tRS_rAcc = tiled_copy_r2s.retile(accumulators)

        # Allocate the epilogue's working registers. The epilogue arithmetic runs
        # in FP32, so they carry FP32 and the narrowing to the output type happens
        # in one step at the end.
        rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
        tRS_rD_layout = cute.make_layout(rD_shape[:3])
        tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, cutlass.Float32)
        return tiled_copy_r2s, tRS_sD, tRS_rAcc, tRS_rD, tRS_rD_layout

    def epilog_gmem_copy_and_partition(
        self,
        tma_atom_d: cute.CopyAtom,
        gD_mnl_slice: cute.Tensor,
        sD: cute.Tensor,
    ) -> Tuple[cute.Tensor, cute.Tensor]:
        """Partition shared memory (source) and global memory (destination) for the
        TMA store.

        :param tma_atom_d: The TMA copy atom for the D store
        :type tma_atom_d: cute.CopyAtom
        :param gD_mnl_slice: This CTA's tile of the global tensor D
        :type gD_mnl_slice: cute.Tensor
        :param sD: The shared memory staging tensor for D
        :type sD: cute.Tensor

        :return: A tuple containing (bSG_sD, bSG_gD), the partitioned shared memory
            and global tensors
        :rtype: Tuple[cute.Tensor, cute.Tensor]
        """
        sepi_for_tma_partition = cute.group_modes(sD, 0, 2)
        tcgc_for_tma_partition = cute.zipped_divide(gD_mnl_slice, self.epi_tile)

        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        return cute.nvgpu.cpasync.tma_partition(
            tma_atom_d,
            0,
            cute.make_layout(1),
            sepi_for_tma_partition,
            tcgc_for_tma_partition,
        )

    def epilog_bias_coord_partition(
        self,
        thr_mma: cute.ThrMma,
        gBias_mnl: cute.Tensor,
        bias_dtype: Type[cutlass.Numeric],
    ) -> Tuple[cute.Tensor, int, cute.CopyAtom]:
        """Partition the bias coordinates the epilogue indexes its staged row with.

        Identity coordinates run through the same mma C partition as the
        accumulator, so each fragment element carries its own (m, n). The n
        coordinate is the linear column into the staged row and is what gates the
        N overhang.

        :param thr_mma: This thread's slice of the tiled MMA
        :type thr_mma: cute.ThrMma
        :param gBias_mnl: This CTA's tile of the bias tensor
        :type gBias_mnl: cute.Tensor
        :param bias_dtype: The bias element type
        :type bias_dtype: Type[cutlass.Numeric]

        :return: A tuple containing (tCcBias, bias_elems_per_copy, bias_g2s_atom)
            where:
            - tCcBias: The partitioned identity coordinates
            - bias_elems_per_copy: Bias elements one lane moves per cp.async
            - bias_g2s_atom: The gmem->smem copy atom for the staging transfer
        :rtype: Tuple[cute.Tensor, int, cute.CopyAtom]
        """
        cBias_mnl = cute.make_identity_tensor(gBias_mnl.shape)
        tCcBias = thr_mma.partition_C(cBias_mnl)
        # cp.async transfers at least 32 bits, so each lane moves a 32-bit vector
        # of bias elements: one at a 32-bit bias width, two at 16 bits.
        bias_elems_per_copy = 32 // bias_dtype.width
        bias_g2s_atom = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            bias_dtype,
            num_bits_per_copy=32,
        )
        return tCcBias, bias_elems_per_copy, bias_g2s_atom

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        d: cute.Tensor,
        bias: Optional[cute.Tensor],
        rt_upper_pad_d: cutlass.Int32,
        rt_upper_pad_h: cutlass.Int32,
        rt_upper_pad_w: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ) -> None:
        """Execute the convolution operation.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param bias: Optional per-output-channel bias of length K, or None. Whether
            one is supplied is a compile-time branch, so a bias run and a no-bias run
            are separate cubins
        :param rt_upper_pad_d/h/w: Upper padding (D, H, W)
        :param rt_lower_pad_d/h/w: Lower padding (D, H, W)
        :param rt_stride_d/h/w: Convolution stride (D, H, W)
        :param rt_dil_d/h/w: Dilation (D, H, W)
        :param max_active_clusters: Maximum active clusters for scheduling
        :param stream: CUDA stream for asynchronous execution
        :param epilogue_op: Activation applied to the FP32 accumulator, folded into
            the cubin as a Constexpr, so each activation compiles to its own kernel
        """
        # Validate and set input-dependent attributes
        self._setup_conv_input_attrs(a, b, d)

        # Bias opt-in: the caller supplies a length-K (output-channel) tensor. has_bias
        # is a compile-time branch, so a no-bias run compiles the bias path away.
        self.has_bias: bool = bias is not None
        self.bias_dtype: Optional[Type[cutlass.Numeric]] = (
            bias.element_type if bias is not None else None
        )

        # Setup attributes (tiled_mma, smem layouts, stages, etc.)
        self._setup_attributes()

        # Pack the runtime pad/stride/dilation scalars into (D, H, W) tuples that
        # feed the im2col A descriptor corners.
        rt_upper_pad_dhw = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        rt_lower_pad_dhw = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        rt_stride_dhw = (rt_stride_d, rt_stride_h, rt_stride_w)
        rt_dil_dhw = (rt_dil_d, rt_dil_h, rt_dil_w)

        # Create im2col TMA atoms and tensors
        (
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
        ) = self._setup_conv_tma(
            a, b, d, rt_upper_pad_dhw, rt_lower_pad_dhw, rt_stride_dhw, rt_dil_dhw
        )

        # Compute grid from the reshaped D tensor (with dummy batch dim)
        # SM120 launches one-CTA clusters without swizzle.
        tile_sched_params, grid = compute_grid(
            tma_tensor_d, self.tile_shape_mnk, (1, 1), 1, "m"
        )

        # Build the mBias tensor with the output's (M, N, L) profile so the epilogue
        # can read it through the same partition_C chain as the accumulator. The M
        # extent is static to keep the partitioned smem-read layout static, while the
        # N axis stays runtime so one cubin serves any output-channel count.
        if cutlass.const_expr(self.has_bias):
            mBias_layout = cute.make_layout(
                (self.tile_shape_mnk[0], cute.size(d, mode=[4]), 1),
                stride=(0, 1, 0),
            )
            mBias_mnl = cute.make_tensor(bias.iterator, mBias_layout)
        else:
            mBias_mnl = None

        self.shared_storage = Sm120DenseImplicitGemmFpropKernel._make_shared_storage(
            self, num_ab_stage=self.num_ab_stage
        )

        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
            mBias_mnl,
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=[1, 1, 1],
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        mBias_mnl: Optional[cute.Tensor],
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """
        GPU device kernel performing the implicit-GEMM convolution.
        """

        #
        # Get cta/warp/thread idx
        #
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        bidx, bidy, bidz = cute.arch.block_idx()

        #
        # Prefetch Tma desc
        #
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        #
        # Get mcast mask
        #
        a_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=1
        )
        b_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=0
        )

        a_mcast_mask = a_mcast_mask if self.is_a_mcast else 0
        b_mcast_mask = b_mcast_mask if self.is_b_mcast else 0

        #
        # Alloc and init AB full/empty + ACC full mbar (pipeline)
        #
        smem = SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # mbar arrays
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()
        math_wg_order_barrier_array_ptr = (
            storage.math_wg_order_barrier_array_ptr.data_ptr()
        )
        clc_mbar_ptr = storage.clc_mbar_ptr.data_ptr()
        clc_response_ptr = storage.clc_response.data_ptr()

        # Threads/warps participating in this pipeline
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread
        )
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Warp, WARPS_PER_WARPGROUP
        )

        cta_layout_vmnk = cute.make_layout((1, *cta_layout_mnk.shape))
        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self.num_ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            barrier_storage=mainloop_pipeline_array_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        math_wg_order_barrier_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, 128
        )
        warp_group_idx = cute.arch.make_warp_uniform(tidx // 128)
        math_wg_order_barrier = pipeline.PipelineOrder.create(
            barrier_storage=math_wg_order_barrier_array_ptr,
            depth=2,
            length=2,
            group_id=warp_group_idx,
            producer_group=math_wg_order_barrier_group,
            defer_sync=True,
        )

        # CLC pipeline:
        # Consumers are the sched warp (self-consume for exit detection), the DMA warp,
        # and both MMA warpgroups. Each MMA warpgroup picks up every tile and uses a
        # parity counter to skip the ones owned by the other warpgroup.
        clc_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        clc_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            (self.num_mma_warps + self.num_dma_warps + self.num_sched_warps)
            * self.num_threads_per_warp,
        )
        clc_pipeline = pipeline.PipelineClcFetchAsync.create(
            num_stages=self.num_clc_stage,
            producer_group=clc_producer_group,
            consumer_group=clc_consumer_group,
            tx_count=16,
            barrier_storage=clc_mbar_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
            defer_sync=True,
        )

        # Bias staging pipeline: the DMA warp stages each tile's row and the owning
        # math warpgroup reads it back. The producer and consumer group sizes are
        # fixed at the DMA warp and one warpgroup, so a stage's participant set does
        # not depend on which warpgroup owns the tile.
        if cutlass.const_expr(mBias_mnl is not None):
            bias_pipeline = pipeline.PipelineCpAsync.create(
                num_stages=self.num_bias_stage,
                producer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread, self.num_threads_per_warp
                ),
                consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 128),
                barrier_storage=storage.bias_pipeline_array_ptr.data_ptr(),
                defer_sync=True,
            )
        else:
            bias_pipeline = None

        cute.arch.mbarrier_init_fence()
        #  Cluster arrive after barrier init
        if cute.size(self.cluster_shape_mnk) > 1:
            cute.arch.cluster_arrive_relaxed()

        #
        # Generate smem tensor A/B
        #
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        # (cta_tile_n, STAGE) ring of bias rows: the DMA warp fills the stage
        # its producer state points at, the tile's owning math warpgroup reads
        # the stage its consumer state points at.
        if cutlass.const_expr(mBias_mnl is not None):
            cta_n = self.tile_shape_mnk[1]
            sBias = storage.sBias.get_tensor(
                cute.make_layout((cta_n, self.num_bias_stage), stride=(1, cta_n))
            )
        else:
            cta_n = None
            sBias = None

        sD = storage.sD.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl,
            (self.tile_shape_mnk[0], (self.tile_shape_mnk[2],)),
            (None, None, None),
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl,
            (self.tile_shape_mnk[1], (self.tile_shape_mnk[2],)),
            (None, None, None),
        )
        # (bM, bN, loopM, loopN, loopL)
        gD_mnl = cute.local_tile(
            mD_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )
        # Bias shares the output's MNL tiling; its M axis carries a stride-0
        # broadcast so every spatial output row reads the same per-channel bias.
        if cutlass.const_expr(mBias_mnl is not None):
            gBias_mnl = cute.local_tile(
                mBias_mnl,
                cute.slice_(self.tile_shape_mnk, (None, None, 0)),
                (None, None, None),
            )
        else:
            gBias_mnl = None

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(tidx % 128)

        #
        # Partition shared tensor for TMA load A/B
        #
        #  TMA load A partition_S/D
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sA, 0, 2),
            cute.group_modes(gA_mkl, 0, 2),
        )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sB, 0, 2),
            cute.group_modes(gB_nkl, 0, 2),
        )

        #  Make frangments
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)
        tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
        tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])

        tDgD = thr_mma.partition_C(gD_mnl)
        acc_shape = tDgD.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)
        # Bias runs the same partition_C chain as the accumulator, so the fragment
        # read back from smem lines up element for element with the acc fragment.
        if cutlass.const_expr(mBias_mnl is not None):
            tCcBias, bias_elems_per_copy, bias_g2s_atom = (
                self.epilog_bias_coord_partition(
                    thr_mma, gBias_mnl, mBias_mnl.element_type
                )
            )
        else:
            tCcBias = None
            bias_elems_per_copy = None
            bias_g2s_atom = None

        # cluster wait for barrier init
        if cute.size(self.cluster_shape_mnk) > 1:
            cute.arch.cluster_wait()
        else:
            pipeline.sync(barrier_id=1)

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Create the tile scheduler (CLC-based dynamic persistent scheduler).
        tile_sched = ClcDynamicPersistentTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            clc_response_ptr,
        )
        work_tile = tile_sched.initial_work_tile_info()

        # Create the pipeline states for producer and consumer
        mainloop_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self.num_ab_stage
        )
        mainloop_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_ab_stage
        )

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_clc_stage
        )

        # MMA warp groups
        if warp_idx < self.num_mma_warps:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            num_k_blocks = cute.size(tCrA, mode=[2])

            #
            # Copy Atom A/B retiling for TMA load A/B
            #
            atom_copy_ldmatrix_A = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(self.a_layout.is_m_major_a(), 4),
                self.a_dtype,
            )
            atom_copy_ldmatrix_B = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(self.b_layout.is_n_major_b(), 4),
                self.b_dtype,
            )
            smem_tiled_copy_A = cute.make_tiled_copy_A(atom_copy_ldmatrix_A, tiled_mma)

            smem_tiled_copy_B = cute.make_tiled_copy_B(atom_copy_ldmatrix_B, tiled_mma)

            thr_copy_ldmatrix_A = smem_tiled_copy_A.get_slice(tidx % 128)
            thr_copy_ldmatrix_B = smem_tiled_copy_B.get_slice(tidx % 128)
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)

            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            # Parity counter: wg0 owns tiles at parity 0 (tile 0, tile 2, tile 4, ...),
            # wg1 owns parity 1. The warpgroup whose parity does NOT match skips the
            # tile and advances its mainloop_consumer_state by k_tile_cnt so DMA's
            # linear production stays
            # in phase with this warpgroup's next owned tile.
            tile_parity = cutlass.Int32(0)

            # Bias ring consumer state. The DMA warp produces one stage per tile,
            # so the non-owner advances past a skipped tile's stage to keep the
            # ring counter aligned with its next owned tile.
            if cutlass.const_expr(mBias_mnl is not None):
                bias_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.num_bias_stage
                )

            math_wg_order_state = math_wg_order_barrier.state
            while work_tile.is_valid_tile:
                if tile_parity == warp_group_idx:
                    math_wg_order_barrier.wait(math_wg_order_state)
                    tile_coord_mnl = work_tile.tile_idx

                    gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]
                    # Clear the accumulator
                    accumulators.fill(0.0)

                    #
                    # Pipelined MAINLOOP
                    #

                    mainloop_consumer_state.reset_count()

                    peek_ab_full_status = cutlass.Boolean(1)
                    if mainloop_consumer_state.count < k_tile_cnt:
                        peek_ab_full_status = mainloop_pipeline.consumer_try_wait(
                            mainloop_consumer_state
                        )

                    #  Wait for TMA copies to complete
                    mainloop_pipeline.consumer_wait(
                        mainloop_consumer_state, peek_ab_full_status
                    )
                    # tCsA_p: (MMA, (4, MMA_M / 4), MMA_K), tCsA_p: (MMA, (4, MMA_N /
                    # 4), MMA_K)
                    tCsA_p = tCsA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsB_p = tCsB_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    cute.copy(
                        smem_tiled_copy_A,
                        tCsA_p[None, None, 0],
                        tCrA_copy_view[None, None, 0],
                    )
                    cute.copy(
                        smem_tiled_copy_B,
                        tCsB_p[None, None, 0],
                        tCrB_copy_view[None, None, 0],
                    )

                    for k_tile in range(0, k_tile_cnt - 1, 1, unroll=1):
                        # unroll the loop
                        for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                            k_block_next = (
                                0
                                if k_block_idx + 1 == num_k_blocks
                                else k_block_idx + 1
                            )

                            if k_block_idx == num_k_blocks - 1:
                                cute.arch.fence_view_async_shared()
                                mainloop_pipeline.consumer_release(
                                    mainloop_consumer_state
                                )
                                mainloop_consumer_state.advance()

                                peek_ab_full_status = cutlass.Boolean(1)
                                peek_ab_full_status = (
                                    mainloop_pipeline.consumer_try_wait(
                                        mainloop_consumer_state
                                    )
                                )

                                # tCsA_p: (MMA, (4, MMA_M / 4), MMA_K), tCsA_p: (MMA,
                                # (4, MMA_N / 4), MMA_K)
                                tCsA_p = tCsA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsB_p = tCsB_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                mainloop_pipeline.consumer_wait(
                                    mainloop_consumer_state, peek_ab_full_status
                                )

                            # Prefetch smem into the next k_block's fragment. With
                            # more than one k_block it is issued before the MMA;
                            # with exactly one it wraps onto the fragment the MMA
                            # has yet to read, so it follows the MMA.
                            def prefetch_next_k_block() -> None:
                                cute.copy(
                                    smem_tiled_copy_A,
                                    tCsA_p[None, None, k_block_next],
                                    tCrA_copy_view[None, None, k_block_next],
                                )
                                cute.copy(
                                    smem_tiled_copy_B,
                                    tCsB_p[None, None, k_block_next],
                                    tCrB_copy_view[None, None, k_block_next],
                                )

                            if cutlass.const_expr(num_k_blocks > 1):
                                prefetch_next_k_block()
                            # Gemm of the current k_block
                            cute.gemm(
                                tiled_mma,
                                accumulators,
                                tCrA[None, None, k_block_idx],
                                tCrB[None, None, k_block_idx],
                                accumulators,
                            )
                            if cutlass.const_expr(num_k_blocks == 1):
                                prefetch_next_k_block()
                    # end of for loop
                    # Hoist out last k_tile

                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_next = (
                            0 if k_block_idx + 1 == num_k_blocks else k_block_idx + 1
                        )

                        if k_block_idx == num_k_blocks - 1:
                            cute.arch.fence_view_async_shared()

                            mainloop_pipeline.consumer_release(mainloop_consumer_state)
                            mainloop_consumer_state.advance()

                            # Signal other warpgroup to proceed
                            math_wg_order_state = math_wg_order_barrier.arrive(
                                math_wg_order_state
                            )

                        if k_block_next > 0:
                            cute.copy(
                                smem_tiled_copy_A,
                                tCsA_p[None, None, k_block_next],
                                tCrA_copy_view[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_B,
                                tCsB_p[None, None, k_block_next],
                                tCrB_copy_view[None, None, k_block_next],
                            )
                        # Gemm of the current k_block
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            tCrA[None, None, k_block_idx],
                            tCrB[None, None, k_block_idx],
                            accumulators,
                        )

                    # Read this tile's staged bias row back into a fragment the
                    # epilogue adds in FP32. One value per output channel is fetched
                    # once and reaches every M row through mBias_mnl's stride-0 M
                    # axis.
                    tCrBias = None
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_pipeline.consumer_wait(bias_consumer_state)
                        sBias_row = sBias[(None, bias_consumer_state.index)]
                        # The identity-coordinate partition hands each element its
                        # tile-local N column, which is the linear index into the
                        # staged row: the producer already applied n_base.
                        tCcBias_tile = tCcBias[(None, None, None, *tile_coord_mnl)]
                        tCrBias = cute.make_rmem_tensor(
                            accumulators.shape, mBias_mnl.element_type
                        )
                        for be in cutlass.range_constexpr(cute.size(tCrBias)):
                            tCrBias[be] = sBias_row[tCcBias_tile[be][1]]
                        # Release the stage so the DMA warp can refill it: every
                        # thread arrives only after its smem reads above are done.
                        cute.arch.fence_proxy("async.shared", space="cta")
                        bias_pipeline.consumer_release(bias_consumer_state)
                        bias_consumer_state.advance()

                    #
                    # EPILOG
                    #

                    (
                        tiled_copy_r2s,
                        tRS_sD,
                        tRS_rAcc,
                        tRS_rD,
                        tRS_rD_layout,
                    ) = self.epilog_smem_store_copy_and_partition(
                        tiled_mma, accumulators, tidx, sD
                    )
                    # The bias fragment carries the accumulator's shape, so the same
                    # retile lands each of its elements on the accumulator element it
                    # belongs to and one index addresses both.
                    tRS_rBias = None
                    if cutlass.const_expr(mBias_mnl is not None):
                        tRS_rBias = tiled_copy_r2s.retile(tCrBias)

                    # One epi tile covers a sub-range of the accumulator's M and N
                    # modes, and a tile spanning several n values is not contiguous in
                    # the accumulator's linearisation, so the block is addressed by
                    # its (m, n) coordinate.
                    acc_m_cnt = cute.size(tRS_rAcc, mode=[1])
                    rD_v_cnt = cute.size(tRS_rD, mode=[0])
                    rD_m_cnt = cute.size(tRS_rD, mode=[1])
                    rD_n_cnt = cute.size(tRS_rD, mode=[2])

                    bSG_sD, bSG_gD = self.epilog_gmem_copy_and_partition(
                        tma_atom_d, gD_mnl_slice, sD
                    )

                    gD_epi = cute.zipped_divide(gD_mnl_slice, self.epi_tile)
                    epi_tile_num = cute.size(gD_epi, mode=[1])
                    epi_tile_shape = gD_epi.shape[1]
                    epi_tile_layout = cute.make_layout(
                        epi_tile_shape, stride=(1, epi_tile_shape[0])
                    )
                    # Initialize tma store pipeline
                    tma_store_producer_group = pipeline.CooperativeGroup(
                        pipeline.Agent.Thread,
                        self.num_mma_warps * self.num_threads_per_warp,
                    )
                    tma_store_pipeline = pipeline.PipelineTmaStore.create(
                        num_stages=self.num_d_stage,
                        producer_group=tma_store_producer_group,
                    )

                    # Serialize epilogue between warp groups (guards shared sD)
                    math_wg_order_barrier.wait(math_wg_order_state)

                    for epi_idx in cutlass.range_constexpr(epi_tile_num):
                        # Widen this epi tile's accumulator elements into the FP32
                        # working registers, adding the bias there so the whole linear
                        # combination is formed at FP32 precision.
                        epi_m_blk, epi_n_blk = epi_tile_layout.get_hier_coord(epi_idx)
                        for epi_n in cutlass.range_constexpr(rD_n_cnt):
                            acc_n = epi_n_blk * rD_n_cnt + epi_n
                            for epi_m in cutlass.range_constexpr(rD_m_cnt):
                                acc_m = epi_m_blk * rD_m_cnt + epi_m
                                for epi_v in cutlass.range_constexpr(rD_v_cnt):
                                    acc_idx = epi_v + rD_v_cnt * (
                                        acc_m + acc_m_cnt * acc_n
                                    )
                                    epi_elem = tRS_rAcc[acc_idx].to(cutlass.Float32)
                                    if cutlass.const_expr(tRS_rBias is not None):
                                        epi_elem = epi_elem + tRS_rBias[acc_idx].to(
                                            cutlass.Float32
                                        )
                                    tRS_rD[
                                        epi_v + rD_v_cnt * (epi_m + rD_m_cnt * epi_n)
                                    ] = epi_elem

                        # Apply the activation in FP32, then cast to the output
                        # type. The op is folded into the cubin as a Constexpr, so each
                        # activation compiles to its own kernel.
                        tRS_rD_out = cute.make_rmem_tensor(
                            tRS_rD_layout.shape, self.d_dtype
                        )
                        acc_vec = epilogue_op(tRS_rD.load())
                        tRS_rD_out.store(acc_vec.to(self.d_dtype))

                        # Register to shared memory
                        epi_buffer = epi_idx % cute.size(tRS_sD, mode=[3])
                        cute.copy(
                            tiled_copy_r2s,
                            tRS_rD_out,
                            tRS_sD[(None, None, None, epi_buffer)],
                        )

                        cute.arch.fence_view_async_shared()
                        # barrier for sync
                        self.epilog_sync_barrier.arrive_and_wait()

                        # Get the global memory coordinate for the current epi tile.
                        gmem_coord = epi_tile_layout.get_hier_coord(epi_idx)
                        # Copy from shared memory to global memory
                        if warp_idx % 4 == 0:
                            cute.copy(
                                tma_atom_d,
                                bSG_sD[(None, epi_buffer)],
                                bSG_gD[(None, gmem_coord)],
                            )
                            tma_store_pipeline.producer_commit()
                            tma_store_pipeline.producer_acquire()
                        # barrier for sync
                        self.epilog_sync_barrier.arrive_and_wait()

                    tma_store_pipeline.producer_tail()
                    # Signal other warpgroup it can start its epilogue
                    math_wg_order_state = math_wg_order_barrier.arrive(
                        math_wg_order_state
                    )
                else:
                    # Advance past the k_tile_cnt stages the DMA warp produced for
                    # this tile.
                    mainloop_consumer_state.advance(k_tile_cnt)
                    # Likewise skip this tile's bias stage: the DMA warp produced
                    # one per tile, so advance past it to stay aligned with the
                    # next owned tile.
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_consumer_state.advance()

                # Pull the next tile from the CLC response slot. Both MMA warpgroups,
                # plus the DMA warp and the sched warp, participate as consumers.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
                tile_parity = cutlass.Int32(1) - tile_parity
            # End of while work_tile.is_valid_tile
        # End of MMA warp group
        # Start of DMA warp group
        elif warp_idx == self.num_mma_warps:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

            if cutlass.const_expr(mBias_mnl is not None):
                bias_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_bias_stage
                )

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx

                tAgA_mkl = tAgA[(None, tile_coord_mnl[0], None, tile_coord_mnl[2])]
                tBgB_nkl = tBgB[(None, tile_coord_mnl[1], None, tile_coord_mnl[2])]

                mainloop_producer_state.reset_count()
                k_shape = cute.shape(tAgA_mkl, mode=1)
                coord_iter = cute.repeat_like(0, k_shape)

                for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                    #
                    # Wait for A/B buffers to be empty before loading into them
                    # Also sets the transaction barrier for the A/B buffers
                    #
                    mainloop_pipeline.producer_acquire(mainloop_producer_state)

                    #
                    # Slice to global/shared memref to current k_tile
                    #
                    tAgA_k = tAgA_mkl[(None, coord_iter)]
                    tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]

                    tBgB_k = tBgB_nkl[(None, coord_iter)]
                    tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                    #
                    # TMA load A/B
                    #
                    cute.copy(
                        tma_atom_a,
                        tAgA_k,
                        tAsA_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                        mcast_mask=a_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_k,
                        tBsB_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                        mcast_mask=b_mcast_mask,
                    )
                    # Mainloop pipeline's producer commit is a NOP
                    mainloop_pipeline.producer_commit(mainloop_producer_state)
                    mainloop_producer_state.advance()

                    coord_iter = cute.increment_coord(coord_iter, k_shape)

                # Stage this tile's bias row for its owning math warpgroup: wait
                # for the ring stage to drain, cp.async the row in, and commit so
                # each lane's arrive lands once its copies complete.
                if cutlass.const_expr(mBias_mnl is not None):
                    bias_pipeline.producer_acquire(bias_producer_state)
                    bias_lane_idx = tidx % self.num_threads_per_warp
                    n_base = tile_coord_mnl[1] * cta_n
                    # Each lane cp.async's contiguous 32-bit vectors
                    # (bias_elems_per_copy elements each) of this tile's bias row.
                    # Column-major stride so lane t owns [t*elems, (t+1)*elems);
                    # the output-channel axis has stride 1, so each segment is
                    # contiguous. n_active lanes cover cta_n.
                    n_active = cta_n // bias_elems_per_copy
                    bias_row_layout = cute.make_layout(
                        (bias_elems_per_copy, n_active),
                        stride=(1, bias_elems_per_copy),
                    )
                    # cp.async needs 32-bit source and destination alignment; the
                    # tile base is a multiple of cta_tile_n, which keeps both on a
                    # 4-byte boundary, so re-annotate the pointers to satisfy the
                    # 32-bit atom.
                    gBias_row = cute.make_tensor(
                        (mBias_mnl.iterator + n_base).align(min_align=4),
                        bias_row_layout,
                    )
                    sBias_stage = sBias[(None, bias_producer_state.index)]
                    sBias_tiled = cute.make_tensor(
                        sBias_stage.iterator.align(min_align=4), bias_row_layout
                    )
                    bias_pred = cute.make_rmem_tensor(
                        cute.make_layout((1,)), cutlass.Boolean
                    )
                    # The warp has 32 lanes and the row needs n_active of them;
                    # each extra pass hands the lanes the next 32 vectors.
                    for bias_pass in cutlass.range_constexpr((n_active + 31) // 32):
                        bias_lane = bias_pass * 32 + bias_lane_idx
                        if bias_lane < n_active:
                            # The output-channel count need not divide cta_tile_n,
                            # so tail lanes would address bias columns with no
                            # backing storage. Predicate each lane on its base
                            # channel; a false predicate zero-fills, and that tail
                            # is only read for output the TMA store clamps away.
                            bias_pred[0] = cutlass.Boolean(
                                n_base + bias_lane * bias_elems_per_copy
                                < mBias_mnl.shape[1]
                            )
                            cute.copy_atom_call(
                                bias_g2s_atom,
                                gBias_row[(None, bias_lane)],
                                sBias_tiled[(None, bias_lane)],
                                pred=bias_pred,
                            )
                    cute.arch.cp_async_commit_group()
                    bias_pipeline.producer_commit(bias_producer_state)
                    bias_producer_state.advance()

                # Pull the next tile from the CLC queue.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            # end of while loop

            # Wait A/B buffer empty
            mainloop_pipeline.producer_tail(mainloop_producer_state)

        # Start of CLC scheduler warp
        elif warp_idx == self.num_mma_warps + self.num_dma_warps:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

            clc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_clc_stage
            )

            while work_tile.is_valid_tile:
                clc_pipeline.producer_acquire(clc_producer_state)
                tile_sched.advance_to_next_work(
                    clc_pipeline.producer_get_barrier(clc_producer_state)
                )
                clc_producer_state.advance()

                # Self-consume to learn whether the next tile is valid.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            clc_pipeline.producer_tail(clc_producer_state)

        # Unused warps
        else:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

        return

    @staticmethod
    def can_implement(
        ncdhw: Tuple[int, int, int, int, int],
        k: int,
        filter_trs: Tuple[int, int, int],
        upper_pad_dhw: Tuple[int, int, int],
        lower_pad_dhw: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dil_dhw: Tuple[int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
        bias_dtype: Optional[Type[cutlass.Numeric]] = None,
        activation: str = "identity",
    ) -> bool:
        """Run every host-side check and tell whether the configuration is supported.

        The checks go from the structural ones to the geometry-derived ones: element
        types, epilogue activation, CTA tile shape, convolution geometry, tensor
        alignment, cluster problem size, im2col descriptor limits.

        :param ncdhw: Input extents (N, C, D, H, W)
        :type ncdhw: Tuple[int, int, int, int, int]
        :param k: Output channel count, which is the implicit-GEMM N extent
        :type k: int
        :param filter_trs: Filter extents (T, R, S)
        :type filter_trs: Tuple[int, int, int]
        :param upper_pad_dhw: Trailing padding per spatial dimension
        :type upper_pad_dhw: Tuple[int, int, int]
        :param lower_pad_dhw: Leading padding per spatial dimension
        :type lower_pad_dhw: Tuple[int, int, int]
        :param stride_dhw: Convolution stride per spatial dimension
        :type stride_dhw: Tuple[int, int, int]
        :param dil_dhw: Dilation per spatial dimension
        :type dil_dhw: Tuple[int, int, int]
        :param ab_dtype: A/B element type
        :type ab_dtype: Type[cutlass.Numeric]
        :param d_dtype: Output element type
        :type d_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator element type
        :type acc_dtype: Type[cutlass.Numeric]
        :param tile_shape_mnk: CTA tile shape (M, N, K)
        :type tile_shape_mnk: Tuple[int, int, int]
        :param bias_dtype: Bias element type, or None when no bias is supplied
        :type bias_dtype: Optional[Type[cutlass.Numeric]]
        :param activation: Name of the compile-time epilogue activation, one of
            EPILOGUE_ACTIVATIONS
        :type activation: str

        :return: True if the configuration can be implemented, False otherwise
        :rtype: bool
        """
        try:
            allowed_ab_dtype = (
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            )
            if ab_dtype not in allowed_ab_dtype:
                raise testing.CantImplementError(
                    f"ab_dtype must be one of {allowed_ab_dtype}, got {ab_dtype}"
                )
            allowed_acc_dtype = (cutlass.Float32, cutlass.Float16)
            if acc_dtype not in allowed_acc_dtype:
                raise testing.CantImplementError(
                    f"acc_dtype must be one of {allowed_acc_dtype}, got {acc_dtype}"
                )
            allowed_d_dtype = (
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float32,
            )
            if d_dtype not in allowed_d_dtype:
                raise testing.CantImplementError(
                    f"d_dtype must be one of {allowed_d_dtype}, got {d_dtype}"
                )
            # The staged bias row is filled with 32-bit vectors and the epilogue's bias
            # floor is 16 bits, so the bias is one of these 16- or 32-bit floats.
            allowed_bias_dtype = (cutlass.Float16, cutlass.BFloat16, cutlass.Float32)
            if bias_dtype is not None and bias_dtype not in allowed_bias_dtype:
                raise testing.CantImplementError(
                    f"bias_dtype must be one of {allowed_bias_dtype}, got {bias_dtype}"
                )
            # The activation's device op is folded into the cubin, so only a name the
            # table carries can be served.
            if activation not in EPILOGUE_ACTIVATIONS:
                raise testing.CantImplementError(
                    f"Unsupported activation {activation!r}; "
                    f"choose from {sorted(EPILOGUE_ACTIVATIONS)}"
                )

            # The tile extents are host ints: this runs before any kernel IR exists.
            tile_m, tile_n = tile_shape_mnk[0], tile_shape_mnk[1]

            # The tiled MMA lays atom_layout warps over mma_inst_mn instructions, with
            # the N side permuted twice as wide. The CTA tile has to be a whole number
            # of those, so that every element of it is owned by a warp.
            atom_layout = Sm120DenseImplicitGemmFpropKernel.atom_layout
            mma_inst_mn = Sm120DenseImplicitGemmFpropKernel.mma_inst_mn
            mma_tile_m = atom_layout[0] * mma_inst_mn[0]
            mma_tile_n = atom_layout[1] * mma_inst_mn[1] * 2
            if tile_m % mma_tile_m != 0 or tile_n % mma_tile_n != 0:
                raise testing.CantImplementError(
                    f"CTA tile ({tile_m}, {tile_n}) must be a whole number of "
                    f"({mma_tile_m}, {mma_tile_n}) MMA tiles"
                )

            # The epilogue walks the CTA tile in epilogue tiles whose rows cap at a
            # fixed 64, so above 64 rows the CTA tile has to be a whole number of them:
            # a remainder step would store into the rows the next tile owns. The
            # epilogue's column count caps at the MMA tile width for every output type
            # here, so the check above covers N.
            epi_max_rows = 64
            if tile_m > epi_max_rows and tile_m % epi_max_rows != 0:
                raise testing.CantImplementError(
                    f"CTA tile M {tile_m} must be a multiple of the epilogue tile's "
                    f"{epi_max_rows} rows"
                )

            # The K tile is one of three widths, each a whole number of MMA K
            # instructions at either atom width.
            allowed_tile_k = (32, 64, 128)
            tile_k = tile_shape_mnk[2]
            if tile_k not in allowed_tile_k:
                # FP8 takes the K=32 MMA atom; every other input type here takes K=16.
                mma_inst_k = (
                    32 if ab_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2) else 16
                )
                raise testing.CantImplementError(
                    f"tile_k must be one of {allowed_tile_k}, got {tile_k} (the MMA K "
                    f"instruction is {mma_inst_k} channels wide)"
                )

            check_conv_geometry(
                ncdhw,
                (k, *filter_trs),
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            check_tensor_alignment(ncdhw[1], k, ab_dtype, d_dtype)
            # Implicit-GEMM M is N*Z*P*Q.
            z, p, q = compute_zpq(
                ncdhw[2:],
                filter_trs,
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            gemm_m = ncdhw[0] * z * p * q
            # A cluster needs at least as many CTA tiles along a dimension as it has
            # CTAs there, counted with a round-up since a partial tile still occupies a
            # CTA.
            m_tiles = -(-gemm_m // tile_m)
            n_tiles = -(-k // tile_n)
            cluster_mnk = Sm120DenseImplicitGemmFpropKernel.cluster_shape_mnk
            if m_tiles < cluster_mnk[0] or n_tiles < cluster_mnk[1]:
                raise testing.CantImplementError(
                    f"CTA tile count ({m_tiles}, {n_tiles}) from implicit-GEMM "
                    f"({gemm_m}, {k}) with cta_tile=({tile_m}, {tile_n}) cannot form one "
                    f"cluster of {cluster_mnk[:2]} CTAs"
                )
            check_im2col_descriptor_limits(
                filter_trs,
                upper_pad_dhw,
                lower_pad_dhw,
                stride_dhw,
                dil_dhw,
            )
        except (testing.CantImplementError, ValueError) as e:
            print(e)
            return False
        return True


#
# Helper functions
#


#
# Run function
#


@lru_cache(maxsize=None)
def compile_conv(
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    tile_shape_mnk: Tuple[int, int, int],
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    activation: str = "identity",
    frontendnext: bool = False,
):
    """Build the kernel object, resolve the host launch config, and cute.compile it.

    Every parameter is a hashable scalar that selects a cubin, so the result is
    cached unbounded: a repeat configuration skips both the trace and the compile.
    The tensors are stood in for by fakes built from the element types, because the
    compiled module reads nothing else from them.

    Returns the compiled callable. Pad / stride / dilation reach the kernel as
    runtime cutlass.Int32, which the rt_ prefix marks, so one compiled cubin serves
    any geometry and the trace takes placeholder values; the caller boxes the real
    ones when it launches. The stream a compilation is handed never runs anything,
    so it is a fake one; the caller passes the real stream when it launches.

    :param ab_dtype: Element type of the input and filter tensors
    :param d_dtype: Element type of the output tensor
    :param acc_dtype: Accumulator data type
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :param bias_dtype: Element type of the per-output-channel bias, or None for a
        cubin without the bias path
    :param activation: Name of the compile-time epilogue activation, one of
        EPILOGUE_ACTIVATIONS. One activation per cubin
    :param frontendnext: Whether the caller is running under the pyir frontend. A
        key-only parameter: the two frontends emit different cubins for the same
        inputs, so an artifact compiled under one must not be served to the other
    """
    from cutlass.cute.runtime import make_fake_stream

    input_ = make_fake_conv_tensor(ab_dtype, 5, 4)
    filter_ = make_fake_conv_tensor(ab_dtype, 5, 4)
    output_ = make_fake_conv_tensor(d_dtype, 5, 4)
    bias_ = None if bias_dtype is None else make_fake_conv_tensor(bias_dtype, 1, 0)

    # The activation's device op is folded into the cubin, so a different activation
    # is a different kernel.
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    conv = Sm120DenseImplicitGemmFpropKernel(
        acc_dtype=acc_dtype,
        tile_shape_mnk=tile_shape_mnk,
    )
    hardware_info = utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(1)

    return cute.compile(
        conv,
        input_,
        filter_,
        output_,
        bias_,
        *trace_conv_scalars(),
        max_active_clusters,
        make_fake_stream(),
        epilogue_op,
    )


def run(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    ab_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    d_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    tile_shape_mnk: Tuple[int, int, int] = (128, 128, 64),
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 0,
    use_cold_l2: bool = False,
    skip_ref_check: bool = False,
    use_bias: bool = False,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    activation: str = "identity",
    **kwargs,
):
    """Run 3D convolution and compare against PyTorch reference.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param stride_dhw: Stride (Sd, Sh, Sw)
    :param upper_pad_dhw: Upper padding (PadD, PadH, PadW)
    :param lower_pad_dhw: Lower padding (PadD, PadH, PadW)
    :param dil_dhw: Dilation (DilD, DilH, DilW)
    :param ab_dtype: Data type for A/B input tensors
    :param d_dtype: Data type for output tensor D
    :param acc_dtype: Accumulator data type
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :param tolerance: Tolerance for result comparison
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param use_cold_l2: Whether to flush L2 cache between iterations
    :param skip_ref_check: Whether to skip reference checking
    :param use_bias: Add a per-output-channel bias, D = activation(acc + bias).
        Whether a bias is supplied is a compile-time branch, so this selects a
        different cubin
    :param bias_dtype: Bias element type; None derives it from the output type
    :param activation: Name of the compile-time epilogue activation, one of
        EPILOGUE_ACTIVATIONS. One activation per cubin
    :param kwargs: Extra keyword arguments, accepted and ignored
    """
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs

    ab_dtype = getattr(cutlass, ab_dtype) if isinstance(ab_dtype, str) else ab_dtype
    d_dtype = getattr(cutlass, d_dtype) if isinstance(d_dtype, str) else d_dtype
    acc_dtype = getattr(cutlass, acc_dtype) if isinstance(acc_dtype, str) else acc_dtype

    # Settle the bias element type before the configuration is checked, so the check
    # sees the type the bias tensor will actually carry.
    if use_bias and bias_dtype is None:
        bias_dtype = bias_dtype_for_output(d_dtype)
    # Every host-side check runs here, before any tensor or compile work.
    if not Sm120DenseImplicitGemmFpropKernel.can_implement(
        ncdhw,
        K,
        (T, R, S),
        upper_pad_dhw,
        lower_pad_dhw,
        stride_dhw,
        dil_dhw,
        ab_dtype,
        d_dtype,
        acc_dtype,
        tile_shape_mnk,
        bias_dtype if use_bias else None,
        activation,
    ):
        raise testing.CantImplementError(
            f"Config not implementable: ncdhw={ncdhw}, ktrs={ktrs}, "
            f"stride={stride_dhw}, pad=({upper_pad_dhw}, {lower_pad_dhw}), "
            f"dilation={dil_dhw}, tile_shape_mnk={tile_shape_mnk}, "
            f"dtypes=({ab_dtype}, {d_dtype}, {acc_dtype}), "
            f"bias_dtype={bias_dtype if use_bias else None}, "
            f"activation={activation}"
        )
    Z, P, Q = compute_zpq(
        ncdhw[2:], ktrs[1:], stride_dhw, upper_pad_dhw, lower_pad_dhw, dil_dhw
    )

    print("Running Blackwell GeForce (SM120) 3D Convolution test with:")
    print(f"  Input shape (N, C, D, H, W): {ncdhw}")
    print(f"  Filter shape (K, C, T, R, S): ({K}, {C}, {T}, {R}, {S})")
    print(f"  Output shape (N, K, Z, P, Q): ({N}, {K}, {Z}, {P}, {Q})")
    print(f"  Stride (Sd, Sh, Sw): {stride_dhw}")
    print(f"  Upper padding (PadD, PadH, PadW): {upper_pad_dhw}")
    print(f"  Lower padding (PadD, PadH, PadW): {lower_pad_dhw}")
    print(f"  Dilation (DilD, DilH, DilW): {dil_dhw}")
    print(f"  A/B data type: {ab_dtype}")
    print(f"  D data type: {d_dtype}")
    print(f"  Accumulator type: {acc_dtype}")
    print(f"  Tile shape (M, N, K): {tile_shape_mnk}\n")

    # Per-output-channel bias of length K, in the bias element type, added to the
    # accumulator in FP32 as D = activation(acc + bias). Marked dynamic-layout so the
    # length-K extent lowers to runtime SSA: a static extent would freeze K into the
    # module and be read at that extent when it is reused at another K.
    if use_bias:
        bias_storage = torch.randn(K, dtype=torch.float32, device="cuda").to(
            torch_dtype(bias_dtype)
        )
        bias_ = from_dlpack(bias_storage, assumed_align=16).mark_layout_dynamic(
            leading_dim=0
        )
    else:
        bias_storage, bias_ = None, None

    # Create input and filter tensors
    input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
        ncdhw, ktrs, (Z, P, Q), ab_dtype
    )

    # Prepare cute tensors
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
    # Free staging buffers once consumed to bound peak memory and avoid OOM.
    del output_tensor

    print("Compiling kernel with cute.compile ...")
    compiled_fn = compile_conv(
        ab_dtype,
        d_dtype,
        acc_dtype,
        tile_shape_mnk,
        bias_dtype=bias_dtype if use_bias else None,
        activation=activation,
        frontendnext=frontend_cache_token(),
    )

    # A fresh non-default stream carries the kernel: CUDA graph capture, which the
    # benchmark below uses, requires one.
    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Run convolution. Pad / stride / dilation are passed as runtime
    # cutlass.Int32, which the rt_ prefix marks, so one compiled cubin serves any
    # geometry.
    print("Running Blackwell GeForce 3D convolution...")
    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_fn(
        input_,
        filter_,
        output_,
        bias_,
        *rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        current_stream,
    )
    torch_stream.synchronize()

    # TF32 off: the cuDNN reference convolution runs in full FP32.
    with torch.backends.cudnn.flags(enabled=True, allow_tf32=False):
        if not skip_ref_check:
            # Run PyTorch reference convolution
            print("Running PyTorch reference 3D convolution...")
            # Pytorch expects tensors to be in NCDHW format
            input_ncdhw = input_tensor.permute(0, 4, 1, 2, 3)
            # Free staging buffers once consumed to bound peak memory and avoid OOM;
            # the view holds the input from here on.
            del input_tensor
            if upper_pad_dhw != lower_pad_dhw:
                # F.conv3d only supports symmetric padding, so manually pad the input
                # F.pad takes padding in reverse dimension order
                pad_arg = (
                    lower_pad_dhw[2],
                    upper_pad_dhw[2],
                    lower_pad_dhw[1],
                    upper_pad_dhw[1],
                    lower_pad_dhw[0],
                    upper_pad_dhw[0],
                )
                input_ncdhw = F.pad(input_ncdhw, pad_arg)
                conv_padding = (0, 0, 0)
            else:
                conv_padding = upper_pad_dhw
            ref = F.conv3d(
                input_ncdhw,
                filter_tensor.permute(0, 4, 1, 2, 3),
                stride=stride_dhw,
                padding=conv_padding,
                dilation=dil_dhw,
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del input_ncdhw
            # Add the bias and apply the activation in FP32 before the output cast,
            # matching the device epilogue (D = activation(acc + bias)).
            # bias_storage holds the exact bias-dtype values the kernel loads,
            # so float() reproduces them bit for bit.
            if use_bias:
                ref = ref + bias_storage.float().reshape(1, K, 1, 1, 1)
            ref = EPILOGUE_ACTIVATIONS[activation]["ref"](ref)
            # Narrowing runs on the device, so magnitudes past the range of d_dtype
            # saturate to its largest finite value. Sub-byte and 8-bit types pack into
            # a byte buffer, wider types keep their native element type. The round trip
            # needs the K-major (N, Z, P, Q, K) layout the kernel writes, whose leading
            # extent carries the vectorized copy.
            ref_narrow_byte_storage = (d_dtype.is_float and d_dtype.width <= 8) or (
                d_dtype.is_integer and d_dtype.width == 4
            )
            ref_narrow_storage_dtype = (
                torch.uint8 if ref_narrow_byte_storage else torch_dtype(d_dtype)
            )
            ref_device = ref.permute(0, 2, 3, 4, 1).contiguous().cuda()
            ref_narrow_storage = torch.empty(
                ref_device.shape, dtype=ref_narrow_storage_dtype, device="cuda"
            )
            ref_narrow = from_dlpack(
                ref_narrow_storage, assumed_align=16
            ).mark_layout_dynamic(leading_dim=4)
            ref_narrow.element_type = d_dtype
            ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=4
            )
            cute.testing.convert(ref_tensor, ref_narrow)
            cute.testing.convert(ref_narrow, ref_tensor)
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del ref_narrow, ref_narrow_storage
            output_ref = ref_device.permute(0, 4, 1, 2, 3)
            # Compare results
            print("Comparing results...")

            # Transform output from (N, Z, P, Q, K) -> (N, K, Z, P, Q)
            output_f32 = output_storage.permute(0, 4, 1, 2, 3).to(torch.float32)
            output_ref_f32 = output_ref.to(torch.float32)

            torch.testing.assert_close(
                output_f32,
                output_ref_f32,
                atol=tolerance,
                rtol=1e-03,
            )
            print("✓ Results match within tolerance!")

    # Benchmark if requested
    if iterations > 0:
        print(
            f"\nBenchmarking with {warmup_iterations} warmup and {iterations} iterations..."
        )

        def generate_tensors():
            input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
                ncdhw, ktrs, (Z, P, Q), ab_dtype
            )
            input_, _ = create_cute_tensor(
                input_tensor,
                ab_dtype,
                leading_dim=4,
            )
            filter_, _ = create_cute_tensor(
                filter_tensor,
                ab_dtype,
                leading_dim=4,
            )
            output_, _ = create_cute_tensor(
                output_tensor,
                d_dtype,
                leading_dim=4,
            )
            # The bias is one of the tensors the kernel reads every iteration, so it
            # rotates with the rest of the workspace and counts toward its bytes.
            if use_bias:
                ws_bias_storage = torch.randn(K, dtype=torch.float32, device="cuda").to(
                    torch_dtype(bias_dtype)
                )
                ws_bias_ = from_dlpack(
                    ws_bias_storage, assumed_align=16
                ).mark_layout_dynamic(leading_dim=0)
            else:
                ws_bias_ = None
            # The workspace initializes on other streams; drain them so the
            # benchmark stream never reads a tensor mid-initialization.
            torch.cuda.synchronize()
            return testing.JitArguments(
                input_,
                filter_,
                output_,
                ws_bias_,
                *rt_conv_scalars(
                    upper_pad=upper_pad_dhw,
                    lower_pad=lower_pad_dhw,
                    stride=stride_dhw,
                    dil=dil_dhw,
                ),
                current_stream,
            )

        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                input_storage.numel() * input_storage.element_size()
                + filter_storage.numel() * filter_storage.element_size()
                + output_storage.numel() * output_storage.element_size()
            )
            if bias_storage is not None:
                one_workspace_bytes += (
                    bias_storage.numel() * bias_storage.element_size()
                )
            workspace_count = testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )

        exec_time = testing.benchmark(
            compiled_fn,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=True,
        )
        runtime_s = exec_time / 1.0e6
        fmas = (N * Z * P * Q) * K * (C * T * R * S)
        flop = 2 * fmas
        gflop = flop / 1.0e9
        gflops = gflop / runtime_s

        print("Average Runtime : ", exec_time / 1000, "ms")
        print("GFLOPS          : ", gflops)

        return exec_time


#
# Argument parsing and main
#


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Blackwell GeForce (SM120) 3D convolution via implicit GEMM"
    )

    # Convolution parameters
    parser.add_argument(
        "--ncdhw",
        type=parse_comma_separated_ints,
        default=(1, 64, 8, 8, 8),
        help="Input tensor shape (N,C,D,H,W)",
    )
    parser.add_argument(
        "--ktrs",
        type=parse_comma_separated_ints,
        default=(128, 3, 3, 3),
        help="Filter tensor shape components (K,T,R,S)",
    )
    parser.add_argument(
        "--stride_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Stride (Sd,Sh,Sw)",
    )
    parser.add_argument(
        "--upper_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Upper padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--lower_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Lower padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--dil_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Dilation (DilD,DilH,DilW)",
    )

    # Data type parameters
    parser.add_argument(
        "--ab_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ],
        default=cutlass.Float16,
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
        ],
        default=cutlass.Float16,
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
            cutlass.Float16,
        ],
        default=cutlass.Float32,
    )

    # Tile shape
    parser.add_argument(
        "--tile_shape_mnk",
        type=parse_comma_separated_ints,
        default=(128, 128, 32),
        help="CTA tile shape (M,N,K)",
    )

    # Validation and benchmark parameters
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=0,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        default=False,
        help="Skip reference checking",
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    # Epilogue
    parser.add_argument(
        "--use_bias",
        action="store_true",
        default=False,
        help="Add a per-output-channel bias, D = activation(acc + bias). Bias and "
        "no-bias are separate cubins",
    )
    parser.add_argument(
        "--bias_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
        ],
        default=None,
        help="Bias element type. Left unset it is derived from the output type, "
        "which has a 16-bit floor",
    )
    parser.add_argument(
        "--activation",
        type=str,
        default="identity",
        choices=sorted(EPILOGUE_ACTIVATIONS),
        help="Compile-time epilogue activation, D = activation(acc + bias). One "
        "activation per cubin",
    )

    args = parser.parse_args()

    if len(args.ncdhw) != 5:
        parser.error("--ncdhw must contain exactly 5 values (N,C,D,H,W)")
    if len(args.ktrs) != 4:
        parser.error("--ktrs must contain exactly 4 values (K,T,R,S)")
    if len(args.tile_shape_mnk) != 3:
        parser.error("--tile_shape_mnk must contain exactly 3 values (M,N,K)")

    run(
        args.ncdhw,
        args.ktrs,
        args.stride_dhw,
        args.upper_pad_dhw,
        args.lower_pad_dhw,
        args.dil_dhw,
        args.ab_dtype,
        args.d_dtype,
        args.acc_dtype,
        args.tile_shape_mnk,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.skip_ref_check,
        args.use_bias,
        args.bias_dtype,
        args.activation,
    )
    print("PASS")
