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
from typing import Optional, Tuple, Type
import sys
import os

import cuda.bindings.driver as cuda

import torch
import torch.nn.functional as F

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.runtime import from_dlpack
import cutlass.torch as cutlass_torch
from cutlass.torch import dtype as torch_dtype
import cutlass.utils as utils
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

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

"""
A high-performance 3D implicit-GEMM based fprop convolution example for the NVIDIA Blackwell Geforce
(SM120) architecture using CUTE DSL.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor D is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) im2col mode for efficient input loading with on-the-fly
      im2col transformation
    - Utilizes warp MMA for matrix multiply-accumulate (MMA) operations
    - Supports multi-stage pipeline to overlap computation and memory access
    - Ping-pong MMA warpgroups with parity-based tile ownership
    - CLC-based dynamic persistent tile scheduling
    - Optional per-output-channel bias and a compile-time epilogue activation,
      D = activation(acc + bias)

This implicit-GEMM based convolution works by converting the convolution into a GEMM problem:
- GEMM M dimension maps to NxZxPxQ
- GEMM N dimension maps to K
- GEMM K dimension maps to TxRxSxC
During the load of input tensor to SMEM, the TMA operation performs the im2col transformation
on the input tensor A. Filter tensor can be loaded to SMEM without any transformation.
The output tensor D is stored to GMEM via TMA.

To run this example:

.. code-block:: bash

    python dense_implicit_gemm_fprop.py                            \\
      --ncdhw 1,64,8,8,8 --ktrs 128,3,3,3                          \\
      --tile_shape_mnk 128,128,64                                  \\
      --ab_dtype Float16 --d_dtype Float16 --acc_dtype Float32     \\
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                  \\
      --stride_dhw 1,1,1 --dil_dhw 1,1,1

Constraints:
* Supported input data types: fp16, bf16, fp8 (e4m3, e5m2)
* A/B tensor must have the same data type
* Supported accumulator data types: fp16, fp32
* Supported output data types: fp16, bf16, fp32
* CTA tile shape M must be 32 or a multiple of 64: a whole number of the 32-row MMA
  tile, and a whole number of the epilogue tile, which caps at 64 rows
* CTA tile shape N must be a multiple of 32, the width of one MMA tile
* CTA tile shape K must be 32/64/128. Prefer the one whose trailing partial K tile
  wastes fewest channels.
* The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 8 for Float16/BFloat16 and of 16 for
  Float8E4M3FN/Float8E5M2.
* The convolution geometry must leave a positive output extent, so that the problem
  covers at least one CTA tile along M and along N.
* The bias, when supplied, is a length-K tensor of the output data type.
"""


def _check_tensor_alignment(
    c: int,
    k: int,
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
):
    """Check if the tensor alignment is valid for convolution."""

    def check_contiguous_16B_alignment(dtype, num_major_elements):
        num_contiguous_elements = 16 * 8 // dtype.width
        return num_major_elements % num_contiguous_elements == 0

    if not check_contiguous_16B_alignment(
        d_dtype, k
    ) or not check_contiguous_16B_alignment(ab_dtype, c):
        raise testing.CantImplementError(
            f"Invalid tensor alignment: C = {c}, K = {k}, ab_dtype = {ab_dtype}, d_dtype = {d_dtype}"
        )


def _check_im2col_descriptor_limits(
    filter_trs: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dil_dhw: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
) -> None:
    """Rejects a convolution geometry the im2col tensor map cannot encode.

    :param filter_trs: Filter extents (T, R, S)
    :param stride_dhw: Convolution stride per spatial dimension
    :param dil_dhw: Dilation per spatial dimension
    :param upper_padding_dhw: Upper padding per spatial dimension
    :param lower_padding_dhw: Lower padding per spatial dimension

    :raises testing.CantImplementError: If a field cannot hold its value
    """
    # Fields of the 5D im2col tensor map are narrower than the convolution
    # parameters feeding them, and a 3D convolution always builds a 5D
    # descriptor, so those widths bind here. They come from the descriptor
    # encoding:
    #
    #   pixel-box corners   one 5-bit signed field per spatial dimension, so
    #                       [-16, 15] on W, H and D alike. The field holds both
    #                       corners, and its width follows the rank: the 16 bits
    #                       the encoding spends on corners are split across the
    #                       rank - 2 spatial dimensions, giving one 16-bit field
    #                       at rank 3, two 8-bit fields at rank 4, and three
    #                       5-bit fields here.
    #   traversal strides   3 bits holding the stride minus one, so [1, 8]
    #
    # A corner is not the padding itself -- the leading one is -lower_padding and
    # the trailing one is upper_padding - (filter - 1) * dilation -- so padding
    # and dilation trade against each other and only the combination is bounded.
    # A corner past its field truncates into range and moves the pixel box, so the
    # bound is enforced on the combination rather than on either input alone.
    corner_lo = -16
    corner_hi = 15
    max_element_stride = 8
    for dim, flt, dil, pad_up, pad_lo, stride in zip(
        ("D", "H", "W"),
        filter_trs,
        dil_dhw,
        upper_padding_dhw,
        lower_padding_dhw,
        stride_dhw,
        strict=True,
    ):
        leading_corner = -pad_lo
        trailing_corner = pad_up - (flt - 1) * dil
        if not corner_lo <= leading_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} leading im2col corner is -lower_padding = "
                f"{leading_corner}, outside the [{corner_lo}, {corner_hi}] the "
                f"descriptor's signed 5-bit corner encodes; lower_padding_"
                f"{dim.lower()} must be at most {-corner_lo}"
            )
        if not corner_lo <= trailing_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} trailing im2col corner is upper_padding - (filter - 1) * "
                f"dilation = {pad_up} - ({flt} - 1) * {dil} = {trailing_corner}, "
                f"outside the [{corner_lo}, {corner_hi}] the descriptor's signed "
                f"5-bit corner encodes"
            )
        if stride > max_element_stride:
            raise testing.CantImplementError(
                f"stride_{dim.lower()}={stride} exceeds the element stride of "
                f"{max_element_stride} a tensor map allows"
            )
        # A filter offset is dilation * tap index, so the largest one a dimension
        # reaches is (filter - 1) * dilation. It travels in an unsigned 5-bit
        # field per spatial dimension, so [0, 31] on W, H and D alike. Past it the
        # value wraps into 5 bits rather than saturating -- an offset of 32
        # arrives as 0, collapsing every tap onto one position -- which changes
        # the result without any fault, so it is bounded here even when both
        # corners are in range.
        #
        # This bound and the trailing corner share the (filter - 1) * dilation
        # term, so raising dilation moves both and a measurement that leaves
        # upper_padding at zero cannot tell which one it broke: the corner gives
        # out first, at an offset of 16. Raising upper_padding with the dilation
        # holds the corner at -16 and isolates this bound.
        max_filter_offset = 31
        filter_offset = (flt - 1) * dil
        if filter_offset > max_filter_offset:
            raise testing.CantImplementError(
                f"{dim} filter offset is (filter - 1) * dilation = ({flt} - 1) * "
                f"{dil} = {filter_offset}, past the {max_filter_offset} the "
                f"im2col descriptor encodes for {dim}"
            )


def _compute_im2col_params(
    filter_trs: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> Tuple[
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
]:
    """Compute im2col TMA descriptor parameters from convolution parameters.

    Converts convolution parameters (DHW order) to TMA descriptor parameters (WHD order).

    :returns: (lower_corner_whd, upper_corner_whd, lower_padding_whd,
               upper_padding_whd, stride_whd, lower_srt, stride_srt)
    """
    pad_upper_d, pad_upper_h, pad_upper_w = upper_padding_dhw
    pad_lower_d, pad_lower_h, pad_lower_w = lower_padding_dhw
    stride_d, stride_h, stride_w = stride_dhw
    dilation_d, dilation_h, dilation_w = dilation_dhw
    filter_t, filter_r, filter_s = filter_trs

    lower_corner_whd = (-pad_lower_w, -pad_lower_h, -pad_lower_d)
    upper_corner_whd = (
        pad_upper_w - ((filter_s - 1) * dilation_w),
        pad_upper_h - ((filter_r - 1) * dilation_h),
        pad_upper_d - ((filter_t - 1) * dilation_d),
    )
    lower_padding_whd = (pad_lower_w, pad_lower_h, pad_lower_d)
    upper_padding_whd = (pad_upper_w, pad_upper_h, pad_upper_d)
    stride_whd = (stride_w, stride_h, stride_d)
    lower_srt = (0, 0, 0)
    stride_srt = (dilation_w, dilation_h, dilation_d)

    return (
        lower_corner_whd,
        upper_corner_whd,
        lower_padding_whd,
        upper_padding_whd,
        stride_whd,
        lower_srt,
        stride_srt,
    )


class Sm120PersistentDenseImplicitGemmFpropKernel:
    """
    3D convolution kernel for SM120 (Blackwell GeForce) via implicit GEMM.
    The input (A) is expected in 5D tensor (NDHWC) format.
    The filter (B) is expected in 5D tensor (KTRSC) format.
    The output (D) is expected in 5D tensor (NZPQK) format.

    Ping-pong MMA warpgroups + CLC-based dynamic persistent scheduling.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :type tile_shape_mnk: Tuple[int, int, int]

    Convolution geometry (filter T/R/S, padding, stride, dilation) is not a
    constructor parameter: T/R/S come from the filter tensor extents and
    pad/stride/dilation arrive as runtime Int32 operands to __call__, so a
    single compiled cubin serves any geometry.
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
    ):
        self.acc_dtype = acc_dtype
        self.cluster_shape_mnk = (1, 1, 1)
        self.tile_shape_mnk = tuple(tile_shape_mnk)
        self.tiled_mma = None
        self.num_mcast_ctas_a = None
        self.num_mcast_ctas_b = None
        self.is_a_mcast = False
        self.is_b_mcast = False

        self.occupancy = 1
        self.atom_layout = (2, 2, 1)

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

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_120")

        self.ab_stage = None
        self.epi_stage = None
        self.num_clc_stage = 1

        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None
        self.epi_tile = None

        self.shared_storage = None
        self.buffer_align_bytes = 1024

        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=128,
        )
        # Bias staging ring depth: two rows let the DMA warp stage the next
        # tile's bias row while the current tile's owner still reads its own.
        self.bias_stage = 2
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

    def _setup_conv_input_attrs(self, a, b, d):
        """Validate and set input-dependent attributes for convolution.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        """
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.d_dtype = d.element_type

        # Only C-contiguous accepted for A/B, K-contiguous for C
        if cutlass.const_expr(a.leading_dim != 4):
            raise RuntimeError(
                "The layout of a is not supported (must be C-contiguous)"
            )
        if cutlass.const_expr(b.leading_dim != 4):
            raise RuntimeError(
                "The layout of b is not supported (must be C-contiguous)"
            )
        if cutlass.const_expr(d.leading_dim != 4):
            raise RuntimeError(
                "The layout of d is not supported (must be K-contiguous)"
            )

        # K-major layouts for all operands in the GEMM view
        self.a_layout = cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        self.b_layout = cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        self.d_layout = cutlass.tensor_utils.LayoutEnum.ROW_MAJOR

        # Check if input data types are compatible
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

    def _setup_conv_tma(self, a, b, d, upper_pad_op, lower_pad_op, stride_op, dil_op):
        """Set up TMA atoms and tensors for im2col convolution.

        The pad/stride/dilation operands feed the im2col A descriptor corners.
        Threading them as runtime cutlass.Int32 lets one compiled cubin serve
        any pad/stride/dilation config.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param upper_pad_op: Upper padding (D, H, W) as runtime cutlass.Int32 tuple
        :param lower_pad_op: Lower padding (D, H, W) as runtime cutlass.Int32 tuple
        :param stride_op: Convolution stride (D, H, W) as runtime cutlass.Int32 tuple
        :param dil_op: Dilation (D, H, W) as runtime cutlass.Int32 tuple
        :returns: (tma_atom_a, tma_tensor_a, tma_atom_b, tma_tensor_b,
                tma_atom_d, tma_tensor_d)
        """
        # Filter T/R/S sourced from the filter tensor b (K, T, R, S, C): under
        # the dynamic tensor layout these extents are runtime Int32, so one
        # compiled cubin serves any T/R/S.
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
        ) = _compute_im2col_params(
            rt_filter_trs,
            upper_pad_op,
            lower_pad_op,
            stride_op,
            dil_op,
        )

        # --- A: im2col TMA load ---
        a_copy_atom = cpasync.CopyBulkTensorIm2ColG2SOp()

        # Create 2-mode hierarchical tensor layout: (N, D, H, W, C) -> ((W, H, D, N), C)
        mA = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[3, 2, 1, 0, 4]))
        mA = cute.group_modes(mA, begin=0, end=4)

        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, 0))

        # Use the lower-level make_im2col_tma_atom (compatible with SM90-style rank-2 SMEM layouts)
        tma_atom_a, tma_tensor_a = cpasync.make_im2col_tma_atom(
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

        # --- B: tiled TMA load (filter reshaped to 2D) ---
        # Change view of filter tensor from (K, T, R, S, C) to (K, (C, S, R, T))
        mB = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[0, 4, 3, 2, 1]))
        mB = cute.group_modes(mB, begin=1, end=5)

        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            mB,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], (self.tile_shape_mnk[2],)),
            1,
        )

        # --- C: TMA im2col store ---
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
        def add_dummy_batch_dimension(tensor):
            new_layout = cute.append(tensor.layout, cute.make_layout(1))
            tensor = cute.make_tensor(tensor.iterator, new_layout)
            return tensor

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

    def _setup_attributes(self):
        # FP8 operands take the .e4m3/.e5m2 MMA on its K=32 atom, which is where
        # FP8's doubled rate lives: one instruction covers twice the K.
        is_fp8 = self.a_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        if is_fp8:
            self.mma_inst_mnk = (16, 8, 32)
            op = cute.nvgpu.warp.MmaFP8Op(
                self.a_dtype,
                self.acc_dtype,
                self.mma_inst_mnk,
            )
        else:
            self.mma_inst_mnk = (16, 8, 16)
            op = cute.nvgpu.warp.MmaF16BF16Op(
                self.a_dtype,
                self.acc_dtype,
                self.mma_inst_mnk,
            )

        tC = cute.make_layout(self.atom_layout)
        permutation_mnk = (
            self.atom_layout[0] * self.mma_inst_mnk[0],
            self.atom_layout[1] * self.mma_inst_mnk[1] * 2,
            self.atom_layout[2] * self.mma_inst_mnk[2],
        )
        self.tiled_mma = cute.make_tiled_mma(
            op,
            tC,
            permutation_mnk=permutation_mnk,
        )

        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

        self.num_mcast_ctas_a = self.cluster_shape_mnk[1]
        self.num_mcast_ctas_b = self.cluster_shape_mnk[0]
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        self.epi_tile = sm90_utils.compute_tile_shape_or_override(
            self.tile_shape_mnk, self.d_dtype, is_cooperative=False
        )

        # Compute stage before compute smem layout
        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.d_dtype,
            self.smem_capacity,
            self.occupancy,
        )

        if self.ab_stage < 1:
            raise testing.CantImplementError(
                f"CTA tile {self.tile_shape_mnk} leaves shared memory for "
                f"{self.ab_stage} A/B stages; it needs at least one"
            )

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
            self.ab_stage,
            self.d_dtype,
            self.d_layout,
            self.epi_stage,
        )

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
    ):
        """Execute the convolution operation.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param bias: Optional per-output-channel bias of length K, or None. Whether
            one is supplied is a compile-time branch, so a bias run and a no-bias run
            are separate cubins
        :param rt_upper_pad_d/h/w: Runtime upper padding (D, H, W) as Int32, so one
            compiled cubin serves any padding config without recompilation
        :param rt_lower_pad_d/h/w: Runtime lower padding (D, H, W) as Int32
        :param rt_stride_d/h/w: Runtime convolution stride (D, H, W) as Int32
        :param rt_dil_d/h/w: Runtime dilation (D, H, W) as Int32
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
        # The bias register fragment is allocated with the bias tensor's dtype and
        # upconverted to FP32 for the add, so the bias has to match the output type.
        if cutlass.const_expr(self.has_bias and bias.element_type is not self.d_dtype):
            raise testing.CantImplementError(
                f"bias dtype ({bias.element_type}) must match output dtype "
                f"({self.d_dtype})"
            )

        # Setup attributes (tiled_mma, smem layouts, stages, etc.)
        self._setup_attributes()

        # Pack the runtime pad/stride/dilation scalars into (D, H, W) tuples that
        # feed the im2col A descriptor corners. Keeping them as runtime Int32 lets
        # a single compiled cubin run any pad/stride/dilation configuration.
        upper_pad_op = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        lower_pad_op = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        stride_op = (rt_stride_d, rt_stride_h, rt_stride_w)
        dil_op = (rt_dil_d, rt_dil_h, rt_dil_w)

        # Create im2col TMA atoms and tensors
        (
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
        ) = self._setup_conv_tma(a, b, d, upper_pad_op, lower_pad_op, stride_op, dil_op)

        # Build the mBias tensor: a per-output-channel bias broadcast to the same
        # (M, N, L) profile as the output. The bias varies along the output channel K
        # (GEMM-N, real stride 1) and broadcasts across every spatial output position
        # (GEMM-M carries stride 0), so the epilogue reads it through the same
        # partition_C chain as the accumulator and each thread lands on its own
        # N-column bias scalar. A static M extent keeps the partitioned smem-read
        # layout static while the N axis carries a runtime extent, so one cubin serves
        # any output-channel count.
        if cutlass.const_expr(self.has_bias):
            mBias_layout = cute.make_layout(
                (self.tile_shape_mnk[0], cute.size(d, mode=[4]), 1),
                stride=(0, 1, 0),
            )
            mBias_mnl = cute.make_tensor(bias.iterator, mBias_layout)
        else:
            mBias_mnl = None

        # Compute grid from the reshaped C tensor (with dummy batch dim)
        tile_sched_params, grid = self._compute_grid(
            tma_tensor_d,
            self.tile_shape_mnk,
            max_active_clusters,
        )

        @cute.struct
        class SharedStorage:
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2
            ]
            # 2 Stage * 2 Groups order pipeline
            pingpong_pipeline_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
            clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_clc_stage * 2]
            clc_response: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int32, self.num_clc_stage * 4], 16
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sD: cute.struct.Align[
                cute.struct.MemRange[
                    self.d_dtype, cute.cosize(self.epi_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # Ring of cta_tile_n bias rows: the DMA warp cp.async's each tile's
            # row into the stage its producer state points at, and the tile's
            # owning math warpgroup reads it back through its consumer state.
            # Zero length without a bias so it costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[
                    self.d_dtype,
                    self.bias_stage * self.tile_shape_mnk[1] if self.has_bias else 0,
                ],
                self.buffer_align_bytes,
            ]
            # PipelineCpAsync mbarriers for the bias staging ring (full+empty per
            # stage). Zero when no bias is supplied.
            bias_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.bias_stage * 2 if self.has_bias else 0
            ]

        self.shared_storage = SharedStorage

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
    ):
        """
        GPU device kernel performing the batched GEMM computation.

        :param tma_atom_a: TMA copy atom for A tensor
        :type tma_atom_a: cute.CopyAtom
        :param mA_mkl: Input tensor A
        :type mA_mkl: cute.Tensor
        :param tma_atom_b: TMA copy atom for B tensor
        :type tma_atom_b: cute.CopyAtom
        :param mB_nkl: Input tensor B
        :type mB_nkl: cute.Tensor
        :param tma_atom_d: TMA copy atom for C tensor
        :type tma_atom_d: cute.CopyAtom
        :param mD_mnl: Output tensor D
        :type mD_mnl: cute.Tensor
        :param tiled_mma: Tiled MMA object
        :type tiled_mma: cute.TiledMma
        :param cta_layout_mnk: CTA layout
        :type cta_layout_mnk: cute.Layout
        :param a_smem_layout_staged: Shared memory layout for A
        :type a_smem_layout_staged: cute.ComposedLayout
        :param b_smem_layout_staged: Shared memory layout for B
        :type b_smem_layout_staged: cute.ComposedLayout
        :param epi_smem_layout_staged: Shared memory layout for epilogue
        :type epi_smem_layout_staged: cute.ComposedLayout
        """

        # ///////////////////////////////////////////////////////////////////////////////
        #  Get cta/warp/thread idx
        # ///////////////////////////////////////////////////////////////////////////////
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        bidx, bidy, bidz = cute.arch.block_idx()

        # /////////////////////////////////////////////////////////////////////////////
        #  Prefetch Tma desc
        # /////////////////////////////////////////////////////////////////////////////
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_a)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_b)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_d)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        # ///////////////////////////////////////////////////////////////////////////////
        # Get mcast mask
        # ///////////////////////////////////////////////////////////////////////////////
        a_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=1
        )
        b_mcast_mask = cute.make_layout_image_mask(
            cta_layout_mnk, cluster_coord_mnk, mode=0
        )

        a_mcast_mask = a_mcast_mask if self.is_a_mcast else 0
        b_mcast_mask = b_mcast_mask if self.is_b_mcast else 0
        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = cute.size_in_bytes(
            self.a_dtype, a_smem_layout
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout)

        # /////////////////////////////////////////////////////////////////////////////
        #  Alloc and init AB full/empty + ACC full mbar (pipeline)
        # /////////////////////////////////////////////////////////////////////////////
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # mbar arrays
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()
        pingpong_pipeline_array_ptr = storage.pingpong_pipeline_array_ptr.data_ptr()
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
            num_stages=self.ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=tma_copy_bytes,
            barrier_storage=mainloop_pipeline_array_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        )

        pingpong_pipeline_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 128)
        warp_group_idx = cute.arch.make_warp_uniform(tidx // 128)
        pingpong_pipeline = pipeline.PipelineOrder.create(
            barrier_storage=pingpong_pipeline_array_ptr,
            depth=2,
            length=2,
            group_id=warp_group_idx,
            producer_group=pingpong_pipeline_group,
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

        # Bias staging pipeline: the DMA warp cp.async's each tile's bias row
        # into the smem ring and the tile's owning math warpgroup reads it back.
        # The producer commit is a per-lane cp.async arrive from the DMA warp's
        # 32 threads; the release is a per-thread arrive from the owning
        # warpgroup's 128 threads, so each stage's participant set is fixed no
        # matter which warpgroup owns the tile.
        if cutlass.const_expr(mBias_mnl is not None):
            bias_pipeline = pipeline.PipelineCpAsync.create(
                num_stages=self.bias_stage,
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

        # ///////////////////////////////////////////////////////////////////////////////
        #  Generate smem tensor A/B
        # ///////////////////////////////////////////////////////////////////////////////
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
                cute.make_layout((cta_n, self.bias_stage), stride=(1, cta_n))
            )
        else:
            cta_n = None
            sBias = None

        sD = storage.sD.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Local_tile partition global tensors
        # ///////////////////////////////////////////////////////////////////////////////
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

        # //////////////////////////////////////////////////////////////////////////////
        #  Partition global tensor for TiledMMA_A/B/C
        # //////////////////////////////////////////////////////////////////////////////
        thr_mma = tiled_mma.get_slice(tidx % 128)

        # //////////////////////////////////////////////////////////////////////////////
        #  Partition shared tensor for TMA load A/B
        # //////////////////////////////////////////////////////////////////////////////
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
            # Identity coordinates through the mma C partition, so each fragment
            # element carries its own (m, n). The n coordinate is what indexes this
            # warpgroup's sBias row and what gates the N overhang.
            cBias_mnl = cute.make_identity_tensor(gBias_mnl.shape)
            tCcBias = thr_mma.partition_C(cBias_mnl)
            # cp.async transfers at least 32 bits, so each lane moves a 32-bit vector
            # of bias elements: two at the output's 16-bit width.
            bias_elems_per_copy = 32 // mBias_mnl.element_type.width
            bias_g2s_atom = cute.make_copy_atom(
                cute.nvgpu.cpasync.CopyG2SOp(),
                mBias_mnl.element_type,
                num_bits_per_copy=32,
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
            pipeline.PipelineUserType.Producer, self.ab_stage
        )
        mainloop_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.ab_stage
        )

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_clc_stage
        )

        # MMA warp groups
        if warp_idx < self.num_mma_warps:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            num_k_blocks = cute.size(tCrA, mode=[2])

            # ///////////////////////////////////////////////////////////////////////////////
            # Copy Atom A/B retiling for TMA load A/B
            # ///////////////////////////////////////////////////////////////////////////////
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
            # tile and advances its mainloop_consumer_state by k_tile_cnt so DMA's linear production stays
            # in phase with this warpgroup's next owned tile.
            tile_parity = cutlass.Int32(0)

            # Bias ring consumer state. The DMA warp produces one stage per tile,
            # so the non-owner advances past a skipped tile's stage to keep the
            # ring counter aligned with its next owned tile.
            if cutlass.const_expr(mBias_mnl is not None):
                bias_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.bias_stage
                )

            pingpong_pipeline_state = pingpong_pipeline.state
            while work_tile.is_valid_tile:
                if tile_parity == warp_group_idx:
                    pingpong_pipeline.wait(pingpong_pipeline_state)
                    tile_coord_mnl = work_tile.tile_idx

                    gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]
                    # Clear the accumulator
                    accumulators.fill(0.0)

                    # /////////////////////////////////////////////////////////////////////////////
                    #  Pipelined MAINLOOP
                    # /////////////////////////////////////////////////////////////////////////////

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
                    # tCsA_p: (MMA, (4, MMA_M / 4), MMA_K), tCsA_p: (MMA, (4, MMA_N / 4), MMA_K)
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

                                # tCsA_p: (MMA, (4, MMA_M / 4), MMA_K), tCsA_p: (MMA, (4, MMA_N / 4), MMA_K)
                                tCsA_p = tCsA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsB_p = tCsB_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                mainloop_pipeline.consumer_wait(
                                    mainloop_consumer_state, peek_ab_full_status
                                )

                            # Copy data from smem to tCrA/tCrB for the next k_block.
                            # Above one k_block the prefetch targets a different register
                            # slot than the MMA is about to read, so issuing it first
                            # overlaps the load. At exactly one, k_block_next wraps onto
                            # that same slot after the tile was released, so there it has
                            # to come after the MMA.
                            def prefetch_next_k_block():
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
                            pingpong_pipeline_state = pingpong_pipeline.arrive(
                                pingpong_pipeline_state
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

                    # Add the per-output-channel bias in FP32 (D = act(acc + bias)).
                    # The DMA warp has cp.async'd this tile's contiguous cta_tile_n
                    # bias values into the ring stage this warpgroup's consumer
                    # state points at; every thread loads its own N columns back
                    # and adds them to the accumulator. One value per output
                    # channel is fetched once and broadcast to all M rows by the
                    # stride-0 M axis of mBias_mnl.
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_pipeline.consumer_wait(bias_consumer_state)
                        sBias_row = sBias[(None, bias_consumer_state.index)]
                        # Read back into a fragment aligned with the accumulator.
                        # The identity-coordinate partition gives each element its
                        # tile-local N column in [0, cta_n), which is exactly the
                        # linear index into the staged row: the producer already
                        # applied n_base when staging from gmem and zero-filled any
                        # overhang. Indexing the row by that tile-local column,
                        # rather than by a gmem channel stride, is what makes the
                        # read correct.
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
                        accumulators.store(
                            accumulators.load() + tCrBias.load().to(self.acc_dtype)
                        )

                    # /////////////////////////////////////////////////////////////////////////////
                    #  EPILOG
                    # /////////////////////////////////////////////////////////////////////////////

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

                    tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(
                        copy_atom_C, tiled_mma
                    )

                    tiled_copy_r2s = cute.make_tiled_copy_S(
                        copy_atom_r2s,
                        tiled_copy_C_Atom,
                    )

                    thr_copy_r2s = tiled_copy_r2s.get_slice(tidx % 128)
                    # (R2S, R2S_M, R2S_N, PIPE_D)
                    tRS_sD = thr_copy_r2s.partition_D(sD)
                    # (R2S, R2S_M, R2S_N)
                    tRS_rAcc = tiled_copy_r2s.retile(accumulators)

                    # Allocate D registers.
                    rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
                    tRS_rD_layout = cute.make_layout(rD_shape[:3])
                    tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)

                    # One epi tile covers a sub-range of the accumulator's M and N
                    # modes. The accumulator linearises as v + V * (m + M * n), so a
                    # tile that spans several n values skips the whole m extent between
                    # them and its elements are not contiguous. How many n values a
                    # tile spans follows the output width -- a narrower element leaves
                    # room for a wider epi tile -- so the block has to be addressed by
                    # its (m, n) coordinate rather than by a flat offset.
                    acc_m_cnt = cute.size(tRS_rAcc, mode=[1])
                    rD_v_cnt = cute.size(tRS_rD, mode=[0])
                    rD_m_cnt = cute.size(tRS_rD, mode=[1])
                    rD_n_cnt = cute.size(tRS_rD, mode=[2])

                    sepi_for_tma_partition = cute.group_modes(sD, 0, 2)
                    tcgc_for_tma_partition = cute.zipped_divide(
                        gD_mnl_slice, self.epi_tile
                    )

                    bSG_sD, bSG_gD = cute.nvgpu.cpasync.tma_partition(
                        tma_atom_d,
                        0,
                        cute.make_layout(1),
                        sepi_for_tma_partition,
                        tcgc_for_tma_partition,
                    )

                    epi_tile_num = cute.size(tcgc_for_tma_partition, mode=[1])
                    epi_tile_shape = tcgc_for_tma_partition.shape[1]
                    epi_tile_layout = cute.make_layout(
                        epi_tile_shape, stride=(1, epi_tile_shape[0])
                    )
                    # Initialize tma store pipeline
                    tma_store_producer_group = pipeline.CooperativeGroup(
                        pipeline.Agent.Thread,
                        self.num_mma_warps * self.num_threads_per_warp,
                    )
                    tma_store_pipeline = pipeline.PipelineTmaStore.create(
                        num_stages=self.epi_stage,
                        producer_group=tma_store_producer_group,
                    )

                    # Serialize epilogue between warp groups (guards shared sD)
                    pingpong_pipeline.wait(pingpong_pipeline_state)

                    for epi_idx in cutlass.range_constexpr(epi_tile_num):
                        # Copy from accumulators to D registers
                        epi_m_blk, epi_n_blk = epi_tile_layout.get_hier_coord(epi_idx)
                        for epi_n in cutlass.range_constexpr(rD_n_cnt):
                            acc_n = epi_n_blk * rD_n_cnt + epi_n
                            for epi_m in cutlass.range_constexpr(rD_m_cnt):
                                acc_m = epi_m_blk * rD_m_cnt + epi_m
                                for epi_v in cutlass.range_constexpr(rD_v_cnt):
                                    tRS_rD[
                                        epi_v + rD_v_cnt * (epi_m + rD_m_cnt * epi_n)
                                    ] = tRS_rAcc[
                                        epi_v + rD_v_cnt * (acc_m + acc_m_cnt * acc_n)
                                    ]

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
                    pingpong_pipeline_state = pingpong_pipeline.arrive(
                        pingpong_pipeline_state
                    )
                else:
                    # Manually advance pipeline stage by the k_tile_cnt stages DMA produced.
                    for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                        mainloop_consumer_state.advance()
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
                    pipeline.PipelineUserType.Producer, self.bias_stage
                )

            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx

                tAgA_mkl = tAgA[(None, tile_coord_mnl[0], None, tile_coord_mnl[2])]
                tBgB_nkl = tBgB[(None, tile_coord_mnl[1], None, tile_coord_mnl[2])]

                mainloop_producer_state.reset_count()
                k_shape = cute.shape(tAgA_mkl, mode=1)
                coord_iter = cute.repeat_like(0, k_shape)

                for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                    # /////////////////////////////////////////////////////////////////////////////
                    #  Wait for A/B buffers to be empty before loading into them
                    #  Also sets the transaction barrier for the A/B buffers
                    # /////////////////////////////////////////////////////////////////////////////
                    mainloop_pipeline.producer_acquire(mainloop_producer_state)

                    # /////////////////////////////////////////////////////////////////////////////
                    #  Slice to global/shared memref to current k_tile
                    # /////////////////////////////////////////////////////////////////////////////
                    tAgA_k = tAgA_mkl[(None, coord_iter)]
                    tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]

                    tBgB_k = tBgB_nkl[(None, coord_iter)]
                    tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                    # /////////////////////////////////////////////////////////////////////////////
                    #  TMA load A/B
                    # /////////////////////////////////////////////////////////////////////////////
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
                            # A CTA N-tile rounds up to cta_tile_n, but the
                            # output-channel count need not divide it, so tail
                            # lanes address bias columns past the end with no
                            # backing storage. Guard each lane's vector on its
                            # base channel: in-bounds lanes copy from gmem,
                            # out-of-bounds lanes zero-fill (cp.async writes 0 on
                            # a false predicate). The zero tail is only read back
                            # for overhang output the TMA store clamps away.
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
    def _compute_stages(
        tile_shape_mnk: tuple[int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        epi_tile: tuple[int, int],
        d_dtype: type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
    ) -> tuple[int, int]:
        """Computes the number of stages for the A/B operands and the epilogue.

        :param tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type tile_shape_mnk: tuple[int, int, int]
        :param a_dtype: Data type of operand A.
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: type[cutlass.Numeric]
        :param epi_tile: Epilogue tile shape.
        :type epi_tile: tuple[int, int]
        :param d_dtype: Data type of the output D.
        :type d_dtype: type[cutlass.Numeric]
        :param smem_capacity: Total available shared memory capacity in bytes.
        :type smem_capacity: int
        :param occupancy: Target number of CTAs per SM (occupancy).
        :type occupancy: int

        :return: A tuple containing the computed number of stages for:
                 (A/B operand stages, epilogue stages)
        :rtype: tuple[int, int]
        """
        epi_stage = 4
        d_bytes_per_stage = cute.size(epi_tile) * d_dtype.width // 8
        epi_bytes = d_bytes_per_stage * epi_stage

        a_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        b_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        ab_bytes_per_stage = (
            cute.size(a_shape) * a_dtype.width // 8
            + cute.size(b_shape) * b_dtype.width // 8
        )
        mbar_helpers_bytes = 1024

        ab_stage = (
            (smem_capacity - occupancy * 1024) // occupancy
            - mbar_helpers_bytes
            - epi_bytes
        ) // ab_bytes_per_stage
        return ab_stage, epi_stage

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: tuple[int, int, int],
        epi_tile: tuple[int, int],
        a_dtype: type[cutlass.Numeric],
        a_layout: cute.Layout,
        b_dtype: type[cutlass.Numeric],
        b_layout: cute.Layout,
        ab_stage: int,
        d_dtype: type[cutlass.Numeric],
        d_layout: cute.Layout,
        epi_stage: int,
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
        :param ab_stage: Number of stages for the A/B tensors
        :type ab_stage: int
        :param d_dtype: Data type for the output matrix D
        :type d_dtype: type[cutlass.Numeric]
        :param d_layout: Layout for the output matrix D
        :type d_layout: cute.Layout
        :param epi_stage: Number of epilogue stages
        :type epi_stage: int

        :return: Tuple of shared memory layouts for A, B and the epilogue
        :rtype: Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
        """
        a_smem_layout_staged = sm90_utils.make_smem_layout_a(
            a_layout,
            tile_shape_mnk,
            a_dtype,
            ab_stage,
        )

        b_smem_layout_staged = sm90_utils.make_smem_layout_b(
            b_layout,
            tile_shape_mnk,
            b_dtype,
            ab_stage,
        )

        epi_smem_layout_staged = sm90_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            epi_stage,
        )

        return a_smem_layout_staged, b_smem_layout_staged, epi_smem_layout_staged

    @staticmethod
    def _compute_grid(
        d: cute.Tensor,
        tile_shape_mnk: tuple[int, int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[int, int, int]:
        """Compute grid shape for the output tensor D.

        :param d: The output tensor D
        :type d: cute.Tensor
        :param tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type tile_shape_mnk: tuple[int, int, int]

        :return: Grid shape for kernel launch.
        :rtype: tuple[int, int, int]
        """

        d_shape = cute.slice_(tile_shape_mnk, (None, None, 0))
        gd = cute.zipped_divide(d, tiler=d_shape)
        num_ctas_mnl = gd[(0, (None, None, None))].shape
        cluster_shape_mnl = (1, 1, 1)
        tile_sched_params = ClcDynamicPersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = ClcDynamicPersistentTileScheduler.get_grid_shape(tile_sched_params)
        return tile_sched_params, grid

    def can_implement(
        self,
        gemm_m: int,
        c: int,
        k: int,
        ab_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        filter_trs: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dil_dhw: Tuple[int, int, int],
        upper_padding_dhw: Tuple[int, int, int],
        lower_padding_dhw: Tuple[int, int, int],
        bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    ) -> None:
        """Rejects configurations this kernel cannot compile or would miscompute.

        Every constraint here is decidable from the tile shape, the element types
        and the problem extents, so it is checked before any tensor is allocated
        rather than surfacing as a rejected launch, an out-of-bounds store or a
        silently wrong result.

        :param gemm_m: Implicit-GEMM M extent, N*Z*P*Q
        :type gemm_m: int
        :param c: Input channel count
        :type c: int
        :param k: Output channel count, which is the implicit-GEMM N extent
        :type k: int
        :param ab_dtype: A/B element type
        :type ab_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator element type
        :type acc_dtype: Type[cutlass.Numeric]
        :param d_dtype: Output element type
        :type d_dtype: Type[cutlass.Numeric]
        :param filter_trs: Filter extents (T, R, S)
        :type filter_trs: Tuple[int, int, int]
        :param stride_dhw: Convolution stride per spatial dimension
        :type stride_dhw: Tuple[int, int, int]
        :param dil_dhw: Dilation per spatial dimension
        :type dil_dhw: Tuple[int, int, int]
        :param upper_padding_dhw: Upper padding per spatial dimension
        :type upper_padding_dhw: Tuple[int, int, int]
        :param lower_padding_dhw: Lower padding per spatial dimension
        :type lower_padding_dhw: Tuple[int, int, int]
        :param bias_dtype: Bias element type, or None when no bias is supplied
        :type bias_dtype: Optional[Type[cutlass.Numeric]]

        :raises testing.CantImplementError: If the configuration is unsupported
        """
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

        # tile_shape_mnk keeps K hierarchical as (M, N, (K,)), so M and N are plain
        # extents and this runs on the host, before any kernel IR exists.
        tile_m, tile_n = self.tile_shape_mnk[0], self.tile_shape_mnk[1]

        # The warp MMA covers 16 rows and 8 columns per instruction on every input
        # type this kernel takes -- only its K depth follows the type -- and the
        # tiled MMA lays atom_layout warps over that with the N side permuted twice
        # as wide. The CTA tile has to be a whole number of those, so that every
        # element of it is owned by a warp.
        mma_tile_m = self.atom_layout[0] * 16
        mma_tile_n = self.atom_layout[1] * 8 * 2
        if tile_m % mma_tile_m != 0 or tile_n % mma_tile_n != 0:
            raise testing.CantImplementError(
                f"CTA tile ({tile_m}, {tile_n}) must be a whole number of "
                f"({mma_tile_m}, {mma_tile_n}) MMA tiles"
            )

        # The epilogue walks the CTA tile in epilogue tiles, and that tile caps its
        # rows at 64 rather than deriving them from the CTA tile, so above 64 rows the
        # CTA tile has to be a whole number of them: a remainder step would store into
        # the rows the next tile owns. The epilogue's column count caps at the MMA tile
        # width for every output type here, so the check above covers N.
        epi_max_rows = 64
        if tile_m > epi_max_rows and tile_m % epi_max_rows != 0:
            raise testing.CantImplementError(
                f"CTA tile M {tile_m} must be a multiple of the epilogue tile's "
                f"{epi_max_rows} rows"
            )

        # The K tile is one of three widths, each a whole number of MMA K instructions
        # at either atom width. Pick the one whose trailing partial K tile wastes the
        # fewest channels, ceil(C / tile_k) * tile_k - C, with a tie going to the wider
        # tile, as far as the width that still leaves more than one A/B stage: the
        # narrowest spans a single MMA instruction and suits only a C no wider width
        # divides, and the widest leaves the 16-bit operands a single A/B stage.
        allowed_tile_k = (32, 64, 128)
        tile_k = self.tile_shape_mnk[2]
        if tile_k not in allowed_tile_k:
            # FP8 takes the K=32 MMA atom; every other input type here takes K=16.
            mma_inst_k = (
                32 if ab_dtype in (cutlass.Float8E4M3FN, cutlass.Float8E5M2) else 16
            )
            raise testing.CantImplementError(
                f"tile_k must be one of {allowed_tile_k}, got {tile_k} (the MMA K "
                f"instruction is {mma_inst_k} channels wide)"
            )

        # The bias fragment is allocated with the bias tensor's element type and
        # upconverted to FP32 for the add, so the bias carries the output's type.
        if bias_dtype is not None and bias_dtype is not d_dtype:
            raise testing.CantImplementError(
                f"bias dtype must match output dtype ({d_dtype}), got {bias_dtype}"
            )

        _check_tensor_alignment(c, k, ab_dtype, d_dtype)

        # A cluster is built out of CTA tiles, so it needs at least as many tiles
        # along a dimension as it has CTAs there. A trailing partial tile still
        # occupies a full CTA in the grid, so the tiles are counted with a round-up.
        # At the single-CTA cluster this kernel launches the floor is one tile per
        # dimension, which is what rejects a geometry whose output extent came out at
        # zero or below: the grid then has no tile to schedule and the launch is
        # refused with cudaErrorInvalidValue.
        m_tiles = -(-gemm_m // tile_m)
        n_tiles = -(-k // tile_n)
        cluster_mn = self.cluster_shape_mnk[:2]
        if m_tiles < cluster_mn[0] or n_tiles < cluster_mn[1]:
            raise testing.CantImplementError(
                f"CTA tile count ({m_tiles}, {n_tiles}) from implicit-GEMM "
                f"({gemm_m}, {k}) with cta_tile=({tile_m}, {tile_n}) cannot form one "
                f"cluster of {cluster_mn} CTAs"
            )

        _check_im2col_descriptor_limits(
            filter_trs, stride_dhw, dil_dhw, upper_padding_dhw, lower_padding_dhw
        )

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


# /////////////////////////////////////////////////////////////////////////////
#  Helper functions
# /////////////////////////////////////////////////////////////////////////////


def compute_zpq(
    dhw: Tuple[int, int, int],
    trs: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> Tuple[int, int, int]:
    """Compute output spatial dimensions Z, P, and Q with asymmetric padding."""
    D, H, W = dhw
    T, R, S = trs
    Sd, Sh, Sw = stride_dhw
    UpperPadD, UpperPadH, UpperPadW = upper_padding_dhw
    LowerPadD, LowerPadH, LowerPadW = lower_padding_dhw
    DilD, DilH, DilW = dilation_dhw
    Z = ((D + UpperPadD + LowerPadD - DilD * (T - 1) - 1) // Sd) + 1
    P = ((H + UpperPadH + LowerPadH - DilH * (R - 1) - 1) // Sh) + 1
    Q = ((W + UpperPadW + LowerPadW - DilW * (S - 1) - 1) // Sw) + 1
    return Z, P, Q


def create_cute_tensor(
    source_f32_tensor: torch.Tensor,
    dtype: Type[cutlass.Numeric],
    leading_dim: int = None,
) -> Tuple[cute.Tensor, torch.Tensor]:
    """Create a dynamic-layout cute tensor from a source f32 tensor.

    The tensor is always marked dynamic-layout: its non-leading extents lower to
    runtime SSA, so nothing about this tensor pins the kernel to a problem size.

    :param source_f32_tensor: Source f32 tensor
    :param dtype: Element type of the tensor to build
    :param leading_dim: Leading dimension for dynamic layout
    :return: Tuple of cute tensor and storage tensor
    """
    # FP4 needs packed storage: 2 elements per byte. cute_tensor_like cannot
    # build the half-byte layout, so allocate an int8 buffer viewed as the
    # packed fp4 type and convert the f32 source into it directly.
    if dtype == cutlass.Float4E2M1FN:
        shape = tuple(source_f32_tensor.shape)
        if shape[-1] % 2 != 0:
            raise ValueError(f"FP4 packed storage requires even trailing dim: {shape}")
        packed_shape = shape[:-1] + (shape[-1] // 2,)
        storage_int8 = torch.empty(packed_shape, dtype=torch.int8, device="cuda")
        storage_view = storage_int8.view(dtype=torch.float4_e2m1fn_x2)
        cute_tensor = from_dlpack(storage_view, assumed_align=16)
        cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
        if source_f32_tensor.numel() > 0:
            f32_tensor = from_dlpack(source_f32_tensor, assumed_align=16)
            f32_tensor = f32_tensor.mark_layout_dynamic(leading_dim=leading_dim)
            cute.testing.convert(f32_tensor, cute_tensor)
        return cute_tensor, storage_view

    cute_tensor, storage_tensor = cutlass_torch.cute_tensor_like(
        source_f32_tensor,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    return cute_tensor, storage_tensor


def prepare_tensors(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    zpq: Tuple[int, int, int],
) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Prepare f32 tensors for 3D convolution.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param zpq: Output spatial dimensions (Z, P, Q)
    :return: Tuple of input, filter, and output tensors
    """
    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs
    Z, P, Q = zpq

    input_tensor = torch.randint(
        -1,
        2,
        (N, D, H, W, C),
        dtype=torch.float32,
        device="cuda",
    )
    filter_tensor = torch.randint(
        -1,
        2,
        (K, T, R, S, C),
        dtype=torch.float32,
        device="cuda",
    )
    output_tensor = torch.empty((N, Z, P, Q, K), dtype=torch.float32, device="cuda")

    return input_tensor, filter_tensor, output_tensor


def _rt_conv_scalars(
    *,
    upper_pad: Tuple[int, int, int],
    lower_pad: Tuple[int, int, int],
    stride: Tuple[int, int, int],
    dil: Tuple[int, int, int],
) -> list:
    """Box the runtime conv geometry as cutlass.Int32 in the kernel's argument order.

    The order (upper pad, lower pad, stride, dilation, each D/H/W) must match the
    kernel __call__ signature; keyword-only parameters keep the four groups from
    being swapped at a call site.
    """
    return [
        cutlass.Int32(v) for group in (upper_pad, lower_pad, stride, dil) for v in group
    ]


# Compile-time epilogue activations, folded into the cubin as a Constexpr op (one
# activation per cubin). Each entry pairs the device-side op applied to the FP32
# output fragment with the torch op used to build the reference.
EPILOGUE_ACTIVATIONS = {
    "identity": {
        "device": lambda x: x,
        "ref": lambda x: x,
    },
    "relu": {
        "device": lambda x: cute.where(x > 0, x, cute.full_like(x, 0)),
        "ref": torch.nn.functional.relu,
    },
}


# /////////////////////////////////////////////////////////////////////////////
#  Run function
# /////////////////////////////////////////////////////////////////////////////


def compile_conv(
    input_: cute.Tensor,
    filter_: cute.Tensor,
    output_: cute.Tensor,
    bias_: Optional[cute.Tensor],
    acc_dtype: Type[cutlass.Numeric],
    tile_shape_mnk: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """Build the kernel object, resolve the host launch config, and cute.compile it.

    Returns the compiled callable. Pad/stride/dilation are boxed as cutlass.Int32 so
    the compiled entry scalars lower to runtime SSA and stay out of the mangled kernel
    name; one cubin then serves any of those values, and the caller re-boxes them at
    launch time. The stream a compilation is handed never runs anything, so it is a
    fake one; the caller passes the real stream when it launches.
    """
    from cutlass.cute.runtime import make_fake_stream

    conv = Sm120PersistentDenseImplicitGemmFpropKernel(
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
        *_rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
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
    iterations: int = 1,
    use_cold_l2: bool = False,
    skip_ref_check: bool = False,
    use_bias: bool = False,
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
    :param activation: Name of the compile-time epilogue activation, one of
        EPILOGUE_ACTIVATIONS. One activation per cubin
    """
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs

    ab_dtype = getattr(cutlass, ab_dtype) if isinstance(ab_dtype, str) else ab_dtype
    d_dtype = getattr(cutlass, d_dtype) if isinstance(d_dtype, str) else d_dtype
    acc_dtype = getattr(cutlass, acc_dtype) if isinstance(acc_dtype, str) else acc_dtype

    Z, P, Q = compute_zpq(
        (D, H, W),
        (T, R, S),
        stride_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
        dil_dhw,
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

    # Create convolution kernel. Convolution geometry (T/R/S, pad, stride,
    # dilation) is not baked into the kernel object: T/R/S come from the filter
    # tensor extents and pad/stride/dilation are passed as runtime Int32 to the
    # compiled function below.
    # Resolve the compile-time epilogue activation. The device op is folded into the
    # cubin, so a different activation is a different kernel.
    if activation not in EPILOGUE_ACTIVATIONS:
        raise testing.CantImplementError(
            f"Unsupported activation {activation!r}; "
            f"choose from {sorted(EPILOGUE_ACTIVATIONS)}"
        )
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    conv = Sm120PersistentDenseImplicitGemmFpropKernel(
        acc_dtype=acc_dtype,
        tile_shape_mnk=tile_shape_mnk,
    )
    conv.can_implement(
        N * Z * P * Q,
        C,
        K,
        ab_dtype,
        acc_dtype,
        d_dtype,
        (T, R, S),
        stride_dhw,
        dil_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
        d_dtype if use_bias else None,
    )

    # Per-output-channel bias of length K, in the output's dtype. Added to the
    # accumulator in FP32 as D = activation(acc + bias) and broadcast across every
    # spatial output position.
    if use_bias:
        bias_storage = torch.randn(K, dtype=torch.float32, device="cuda").to(
            torch_dtype(d_dtype)
        )
        bias_ = from_dlpack(bias_storage, assumed_align=16)
    else:
        bias_storage, bias_ = None, None

    # Create input and filter tensors
    input_tensor, filter_tensor, output_tensor = prepare_tensors(ncdhw, ktrs, (Z, P, Q))

    # Prepare cute tensors
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)

    print("Compiling kernel with cute.compile ...")
    compiled_fn = compile_conv(
        input_,
        filter_,
        output_,
        bias_,
        acc_dtype,
        tile_shape_mnk,
        stride_dhw=stride_dhw,
        upper_pad_dhw=upper_pad_dhw,
        lower_pad_dhw=lower_pad_dhw,
        dil_dhw=dil_dhw,
        epilogue_op=epilogue_op,
    )

    # Get current CUDA stream
    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Run convolution. Pad/stride/dilation are passed as runtime Int32 so one
    # cubin runs any pad/stride/dilation config.
    print("Running Blackwell GeForce 3D convolution...")
    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_fn(
        input_,
        filter_,
        output_,
        bias_,
        *_rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        current_stream,
    )
    torch_stream.synchronize()

    with torch.backends.cudnn.flags(enabled=False):
        if not skip_ref_check:
            # Run PyTorch reference convolution
            print("Running PyTorch reference 3D convolution...")
            # Pytorch expects tensors to be in NCDHW format
            input_ncdhw = input_tensor.permute(0, 4, 1, 2, 3)
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
            # Add the bias and apply the activation in FP32 before the output cast,
            # matching the device epilogue (D = activation(acc + bias)).
            # bias_storage holds the exact d_dtype values the kernel loads, so float()
            # reproduces them bit for bit.
            if use_bias:
                ref = ref + bias_storage.float().reshape(1, K, 1, 1, 1)
            ref = EPILOGUE_ACTIVATIONS[activation]["ref"](ref)
            output_ref = ref.to(dtype=torch_dtype(d_dtype)).to(dtype=torch.float32)
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
            print("Results match within tolerance!")

    # Benchmark if requested
    if iterations > 0:
        print(
            f"\nBenchmarking with {warmup_iterations} warmup and {iterations} iterations..."
        )

        def generate_tensors():
            input_tensor, filter_tensor, output_tensor = prepare_tensors(
                ncdhw, ktrs, (Z, P, Q)
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
            # The workspace initializes on other streams; drain them so the
            # benchmark stream never reads a tensor mid-initialization.
            torch.cuda.synchronize()
            return testing.JitArguments(
                input_,
                filter_,
                output_,
                bias_,
                *_rt_conv_scalars(
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


# /////////////////////////////////////////////////////////////////////////////
#  Argument parsing and main
# /////////////////////////////////////////////////////////////////////////////


def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Blackwell GeForce (SM120) 3D convolution via implicit GEMM"
    )

    # Convolution parameters
    parser.add_argument(
        "--ncdhw",
        type=_parse_comma_separated_ints,
        default=(1, 64, 8, 8, 8),
        help="Input tensor shape (N,C,D,H,W)",
    )
    parser.add_argument(
        "--ktrs",
        type=_parse_comma_separated_ints,
        default=(128, 3, 3, 3),
        help="Filter tensor shape components (K,T,R,S)",
    )
    parser.add_argument(
        "--stride_dhw",
        type=_parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Stride (Sd,Sh,Sw)",
    )
    parser.add_argument(
        "--upper_pad_dhw",
        type=_parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Upper padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--lower_pad_dhw",
        type=_parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Lower padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--dil_dhw",
        type=_parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Dilation (DilD,DilH,DilW)",
    )

    # Data type parameters
    parser.add_argument(
        "--ab_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
    )

    # Tile shape
    parser.add_argument(
        "--tile_shape_mnk",
        type=_parse_comma_separated_ints,
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
        default=1,
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
        args.activation,
    )
    print("PASS")
