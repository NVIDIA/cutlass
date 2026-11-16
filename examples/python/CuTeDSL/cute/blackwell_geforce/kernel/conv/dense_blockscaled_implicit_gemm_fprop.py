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
from typing import Tuple, Type, Optional
import os
import sys

import cuda.bindings.driver as cuda

import torch
import torch.nn.functional as F

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync
from cutlass import testing
import cutlass.pipeline as pipeline
from cutlass.cute.runtime import from_dlpack
import cutlass.torch as cutlass_torch
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
import cutlass.utils.blackwell_helpers as sm120_utils
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
from cutlass.memory import SmemAllocator
from cutlass.tensor_utils import LayoutEnum

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

# SM120 block-scaled GEMM dispatch helpers (sibling utility module). Try the
# namespace-package path first, which resolves when the examples root is on
# sys.path; fall back to the bare local import, which resolves when only this
# file's own directory is on sys.path[0].
try:
    from blackwell_geforce.kernel.blockscaled_gemm.blockscaled_gemm_dispatch import (
        FP4_SHIFT_BITS,
        make_ldmatrix_atom,
        make_sm120_blockscaled_mma_op,
    )
except ImportError:
    from blockscaled_gemm_dispatch import (  # noqa: E402
        FP4_SHIFT_BITS,
        make_ldmatrix_atom,
        make_sm120_blockscaled_mma_op,
    )

# Conv helpers shared with the legacy SM120 conv, imported on the same two paths.
try:
    from blackwell_geforce.kernel.conv.dense_implicit_gemm_fprop import (
        Sm120PersistentDenseImplicitGemmFpropKernel,
        _check_im2col_descriptor_limits,
        _check_tensor_alignment,
        _compute_im2col_params,
        create_cute_tensor,
        _parse_comma_separated_ints,
        _rt_conv_scalars,
        compute_zpq,
        prepare_tensors,
    )
except ImportError:
    from dense_implicit_gemm_fprop import (  # noqa: E402
        Sm120PersistentDenseImplicitGemmFpropKernel,
        _check_im2col_descriptor_limits,
        _check_tensor_alignment,
        _compute_im2col_params,
        create_cute_tensor,
        _parse_comma_separated_ints,
        _rt_conv_scalars,
        compute_zpq,
        prepare_tensors,
    )

"""
SM120 NVFP4 fprop in CuTe DSL.

The device mainloop is intentionally kept aligned with
dense_blockscaled_gemm_persistent_pingpong.py. Convolution is represented as an
implicit GEMM view:
- A: NDHWC im2col -> (N*Z*P*Q, C*T*R*S, 1)
- B: KTRSC -> (K, C*S*R*T, 1)
- D: NZPQK im2col store -> (N*Z*P*Q, K, 1)

SFB follows the SM120 block-scaled GEMM path. SFA is loaded by a single-CTA
async-copy producer into the same SMEM layout that the SM120 GEMM math path
consumes. Conv geometry (T/R/S, pad/stride/dilation, N/D/H/W) is passed as
runtime scalars, the channel count among them: SFB's per-position span is derived
from it at runtime, so one compiled kernel serves every C.
"""


# /////////////////////////////////////////////////////////////////////////////
#  Helpers to parse args
# /////////////////////////////////////////////////////////////////////////////


# /////////////////////////////////////////////////////////////////////////////
#  Host setup and device kernel launch
# /////////////////////////////////////////////////////////////////////////////


class Sm120BlockScaledPersistentDenseImplicitGemmFpropKernel(
    Sm120PersistentDenseImplicitGemmFpropKernel
):
    def __init__(
        self,
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
    ):
        super().__init__(acc_dtype, tile_shape_mnk)
        self.sf_vec_size = sf_vec_size

        # Override the warp specialization: SFA cannot be loaded by a TMA (a K tile
        # reads a different pixel per filter position, so the M address is not a
        # regular box), so it gets its own 4-warp cp.async group right after the MMA
        # warps. The TMA load, CLC scheduler, and residual G2S warps then share the
        # round-up warpgroup; the residual warp reuses an otherwise-idle slot, so
        # enabling residual grows neither the CTA nor the register budget.
        self.sfa_cpasync_warp_group_start = self.num_mma_warps
        self.sfa_cpasync_warp_group_size = 4
        self.tma_load_warp_id = (
            self.sfa_cpasync_warp_group_start + self.sfa_cpasync_warp_group_size
        )
        self.sched_warp_id = self.tma_load_warp_id + 1
        self.residual_tma_warp_id = self.sched_warp_id + 1
        self.threads_per_cta = (
            self.num_mma_warps
            + self.sfa_cpasync_warp_group_size  # SFA cp.async DMA warp group
            + 1  # dedicated TMA load warp
            + self.num_sched_warps  # CLC scheduler warp
        ) * self.num_threads_per_warp

        # epi_tile is chosen in _setup_attributes once has_residual is known: a
        # residual epilogue needs a separate sResidual staging buffer, so it uses a
        # subtiled epi_tile to keep the epilogue smem (sD + sResidual) small enough
        # to preserve the A/B pipeline depth; without a residual the full (128,128)
        # epi_tile is fastest (single subtile, deepest A/B pipeline).
        self.epi_tile = None

        # The CLC scheduler warp plus the round-up unused warps form a whole extra
        # warpgroup whose only real work is the lightweight CLC producer loop; give
        # it the register-realloc floor so the freed budget goes to the MMA
        # warpgroups. Its value is shared by the scheduler and unused branches since
        # they belong to the same warpgroup.
        self.sched_register_requirement = 24
        self.mma_register_requirement = 224

    def _setup_attributes(self):
        # Pick the epilogue tile from whether a residual is fused. Without a
        # residual the full-CTA epi_tile stores D in one subtile and leaves the
        # most smem for the A/B pipeline. With a residual, sResidual doubles the
        # epilogue smem, so a subtiled epi_tile keeps sD + sResidual small enough
        # to hold the A/B pipeline depth; (64,64) measured fastest across the
        # residual shapes.
        epi_m, epi_n = (64, 64) if self.has_residual else (128, 128)
        # The epilogue subtile cannot exceed the CTA tile, and its N extent has to
        # divide tile_n. The storing warpgroup takes its subtile count from the
        # tiled gmem tensor's rest mode, which rounds up, while the accumulator
        # index it builds per subtile is epi_n * (epi_tile_n // mma_tile_n) + ... --
        # so a remainder makes that index run past the accumulator fragment. The
        # residual skip count and the epilogue stage budget divide instead, which
        # rounds down. Halving epi_n until it divides keeps all three in agreement
        # for every tile_n. It only fires on the residual branch at tile_n=96, where
        # the starting 64 does not divide and halves to 32; without a residual the
        # starting 128 clamps to 96, which divides itself.
        epi_m = min(epi_m, self.tile_shape_mnk[0])
        epi_n = min(epi_n, self.tile_shape_mnk[1])
        while self.tile_shape_mnk[1] % epi_n != 0:
            epi_n //= 2
        self.epi_tile = (epi_m, epi_n)
        # The SF SMEM atom (BlockScaledBasicChunk) is indivisible along N: one
        # chunk spans blk_mn=128 output channels, so a tile_n below 128 still
        # stages a whole chunk and n_tiles_per_sf_n_tile consecutive N tiles share
        # it; the consumer offsets into its own slice of the chunk.
        self.sf_tile_n = ((self.tile_shape_mnk[1] + 127) // 128) * 128
        self.n_tiles_per_sf_n_tile = self.sf_tile_n // self.tile_shape_mnk[1]

        mma_op, use_mxf8f6f4 = make_sm120_blockscaled_mma_op(
            self.a_dtype,
            self.b_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
        )
        # mixed_mode carries the full mixed FP4 x FP8 machinery (Int8 SMEM/TMA
        # recast + FP4_SHIFT_BITS unpack) for a future mixed-dtype path. run_conv
        # currently gates ab_dtype to Float4E2M1FN, so a_dtype == b_dtype and
        # mixed_mode is always False here -- the shift branches are unreachable in
        # this example but kept so the mixed path can be enabled without a rewrite.
        self.mixed_mode = self.a_dtype != self.b_dtype
        # a_fp4_in_mixed / b_fp4_in_mixed: this side carries an FP4 operand in the
        # mixed FP4 x FP8 mode, so SMEM/TMA see Int8 storage and the mma.sync
        # consumer needs the LDSM b4x16_p64 unpack + register `<< FP4_SHIFT_BITS`.
        a_fp4_in_mixed = self.mixed_mode and self.a_dtype.width < 8
        b_fp4_in_mixed = self.mixed_mode and self.b_dtype.width < 8
        self.smem_alloc_a_dtype = cutlass.Int8 if a_fp4_in_mixed else self.a_dtype
        self.smem_alloc_b_dtype = cutlass.Int8 if b_fp4_in_mixed else self.b_dtype
        # `internal_type` for `_make_tma_atoms_and_tensors` is None when the dtype
        # already matches (TMA sees the native dtype), Int8 when we recast for FP4.
        self.tma_internal_a_dtype = cutlass.Int8 if a_fp4_in_mixed else None
        self.tma_internal_b_dtype = cutlass.Int8 if b_fp4_in_mixed else None
        atom_shape = (2, 2, 1)
        atom_layout = cute.make_layout(atom_shape)
        permutation_mnk = sm120_utils.get_permutation_mnk(
            self.tile_shape_mnk, self.sf_vec_size, use_mxf8f6f4
        )
        self.tiled_mma = cute.make_tiled_mma(
            mma_op,
            atom_layout,
            permutation_mnk=permutation_mnk,
        )

        # Scale-factor tiles decouple from the A/B K tile for MXFP8. The SF SMEM
        # atom (BlockScaledBasicChunk) spans 4 SF blocks along K, so at vec32 one
        # atom covers 4*32 = 128 channels: the SF K tile must be 128 even when the
        # A/B K tile is 64. One K128 SF chunk then serves two K64 A/B tiles, and
        # the consumer offsets into the live half via sf_base. NVFP4 keeps
        # ab_k_tiles_per_sf_k_tile == 1, so every SF path below is a no-op for it.
        self.sf_tile_k = sf_k_tile_channels(self.tile_shape_mnk[2], self.sf_vec_size)
        self.ab_k_tiles_per_sf_k_tile = self.sf_tile_k // self.tile_shape_mnk[2]
        # The SF tile takes the rounded-up N from above and the K cadence from here,
        # so a narrow tile_n still stages a whole chunk and MXFP8 still stages one
        # whole chunk along K.
        self.sf_tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.sf_tile_n,
            self.sf_tile_k,
        )

        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

        # Compute stage before compute smem layout
        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk,
            self.smem_alloc_a_dtype,
            self.smem_alloc_b_dtype,
            self.sf_dtype,
            self.epi_tile,
            self.d_dtype,
            self.smem_capacity,
            self.occupancy,
            self.has_residual,
        )

        # Residual G2S ring depth, independent of the D-store epi_stage. A single
        # buffer already hides the residual load: the dedicated residual warp runs
        # its own acquire/commit loop and stays a subtile ahead of the epilogue
        # consumer, which releases each stage right after the S2R read (before the
        # add), so the buffer turns over fast. A deeper ring only steals smem from
        # the A/B pipeline and lowers ab_stage, so keep it at 1.
        self.res_stage = 1

        assert self.epi_stage > 0, (
            "epi_stage <= 0, no enough shared memory. This case will be skipped."
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
            self.res_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.smem_alloc_a_dtype,
            self.a_layout,
            self.smem_alloc_b_dtype,
            self.b_layout,
            self.ab_stage,
            self.d_dtype,
            self.d_layout,
            self.epi_stage,
            self.res_stage,
            self.sf_vec_size,
            self.tiled_mma,
            self.sf_tile_shape_mnk,
        )
        # MMA-side view of the staged SFB chunk. The TMA stages whole 128-wide
        # chunks, but the mma only consumes the live tile_n columns, so the
        # consumer reads the same SMEM through a tile_n-wide layout whose modes
        # then match the B fragment's. Only N narrows: K stays on the SF cadence,
        # which is one whole chunk and can be wider than the A/B K tile.
        self.sfb_mma_layout_staged = _sm120_make_smem_layout_sfb(
            self.tiled_mma,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[1], self.sf_tile_k),
            self.sf_vec_size,
            self.ab_stage,
        )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        d: cute.Tensor,
        bias: Optional[cute.Tensor],
        residual: Optional[cute.Tensor],
        alpha: cutlass.Float32,
        beta: cutlass.Constexpr,
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
        rt_filter_t: cutlass.Int32,
        rt_filter_r: cutlass.Int32,
        rt_filter_s: cutlass.Int32,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute fprop using the SM120 block-scaled GEMM mainloop.

        alpha is an FP32 runtime scalar applied to the accumulator before bias
        as D = act(alpha * acc + bias + beta * residual). It is passed at both
        cute.compile and the runtime launch, so its value stays out of the
        mangled name and one cubin serves any alpha.

        beta is a compile-time Constexpr, so beta == 0 folds the entire residual
        path (dedicated load warp, smem staging, TMA, add) away via DCE and
        beta != 0 compiles it in. A separate cubin is emitted per beta value; the
        residual tensor shares the output's shape/layout/dtype.

        Pad/stride/dilation arrive as boxed cutlass.Int32 scalars so they lower
        to runtime SSA: one compiled cubin serves any pad/stride/dilation
        config. The SAME values feed BOTH the im2col A descriptor corner (host,
        _compute_im2col_params) and the device SFA cp.async coord reconstruction
        (sfa_cpasync_copy_tile); runtime-ing only one side would desync A's load
        coords from SFA's, zeroing the accumulator on any non-default config.
        """

        # setup static attributes before smem/grid/tma computation
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.d_dtype = d.element_type
        self.sf_dtype = sfa.element_type

        # Bias opt-in: caller supplies a length-K (output-channel) tensor. has_bias
        # is a compile-time branch, so no-bias compiles the bias path away.
        self.has_bias: bool = bias is not None
        # The bias register fragment is allocated with the bias tensor's dtype and
        # upconverted to FP32 for the add. Require bias to match the output dtype.
        if cutlass.const_expr(self.has_bias and bias.element_type is not self.d_dtype):
            raise RuntimeError(
                f"bias dtype ({bias.element_type}) must match output "
                f"dtype ({self.d_dtype})"
            )

        # Residual opt-in: gated by the compile-time beta. beta == 0 compiles the
        # whole residual path away; beta != 0 requires a residual tensor sharing
        # the output's shape/layout/dtype (it is TMA-loaded through the output's
        # own store descriptor, run in reverse as a G2S load).
        self.beta = beta
        self.has_residual: bool = beta != 0.0
        if cutlass.const_expr(self.has_residual and residual is None):
            raise RuntimeError("beta != 0 requires a residual tensor")
        if cutlass.const_expr(
            self.has_residual and residual.element_type is not self.d_dtype
        ):
            raise RuntimeError(
                f"residual dtype ({residual.element_type}) must match output "
                f"dtype ({self.d_dtype})"
            )

        if cutlass.const_expr(a.leading_dim != 4):
            raise RuntimeError("Input must be NDHWC with C contiguous")
        if cutlass.const_expr(b.leading_dim != 4):
            raise RuntimeError("Filter must be KTRSC with C contiguous")
        if cutlass.const_expr(d.leading_dim != 4):
            raise RuntimeError("Output must be NZPQK with K contiguous")

        # In the flattened GEMM view all operands are K-contiguous / row-major.
        self.a_layout = LayoutEnum.ROW_MAJOR
        self.b_layout = LayoutEnum.ROW_MAJOR
        self.d_layout = LayoutEnum.ROW_MAJOR

        self._setup_attributes()

        def add_dummy_batch_dimension(tensor):
            return cute.make_tensor(
                tensor.iterator, cute.append(tensor.layout, cute.make_layout(1))
            )

        # Filter T/R/S arrive as boxed cutlass.Int32 (not b.shape, which trace-
        # time resolves to compile-time ints). Runtime extents keep the B im2col
        # K layout at full rank 4 (c,s,r,t): when an extent is a compile-time 1
        # the tile partition collapses that mode, but a runtime extent cannot be
        # proven == 1 at compile time so the mode is retained — matching A's
        # always-rank-4 K traversal and letting one cubin serve any T/R/S.
        rt_filter_trs = (rt_filter_t, rt_filter_r, rt_filter_s)
        rt_upper_pad_dhw = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        rt_lower_pad_dhw = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        rt_stride_dhw = (rt_stride_d, rt_stride_h, rt_stride_w)
        rt_dil_dhw = (rt_dil_d, rt_dil_h, rt_dil_w)

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
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        # A im2col: (N,D,H,W,C) -> ((W,H,D,N), C), descriptor K=(C,S,R,T).
        a_gemm = cute.make_tensor(
            a.iterator,
            cute.select(a.layout, mode=[3, 2, 1, 0, 4]),
        )
        a_gemm = cute.group_modes(a_gemm, begin=0, end=4)

        # B: (K,T,R,S,C) -> reorder to (K, (C,S,R,T)) for K-coordinate indexing.
        # Reorder the mark_layout_dynamic filter tensor's modes instead of
        # rebuilding a compact layout from scalars: the reordered view inherits
        # the tensor's runtime C/T/R/S extents and strides, so no channel or
        # filter extent is baked into the cubin.
        b_gemm = cute.make_tensor(
            b.iterator, cute.select(b.layout, mode=[0, 4, 3, 2, 1])
        )
        b_gemm = cute.group_modes(b_gemm, begin=1, end=5)

        # D im2col store: (N,Z,P,Q,K) -> ((Q,P,Z,N), K).
        d_gemm = cute.make_tensor(
            d.iterator, cute.select(d.layout, mode=[3, 2, 1, 0, 4])
        )
        d_gemm = cute.group_modes(d_gemm, begin=0, end=4)

        # Build mBias tensor: a per-output-channel bias broadcast to the same
        # ((Q,P,Z,N), K, 1) = (M, N, L) profile as the output. The bias varies
        # along the output channel K (GEMM-N, real stride 1) and broadcasts across
        # every spatial output position (GEMM-M = Q,P,Z,N modes carry stride 0), so
        # the epilogue reads it through the same partition_C chain as the
        # accumulator and each thread lands on its own N-column bias scalar. The M
        # (spatial) modes are stride-0 broadcast, so a static M extent (the CTA
        # tile size) keeps the partitioned smem-read layout static for a vectorized
        # load while the N axis carries a runtime stride so one cubin serves any
        # output-channel count.
        if cutlass.const_expr(self.has_bias):
            mBias_layout = cute.make_layout(
                (
                    (self.tile_shape_mnk[0], 1, 1, 1),
                    cute.size(d, mode=[4]),
                    1,
                ),
                stride=((0, 0, 0, 0), 1, 0),
            )
            mBias_mnl = cute.make_tensor(bias.iterator, mBias_layout)
        else:
            mBias_mnl = None

        # SFA is an unswizzled input-activation scale tensor in
        # (N*D*H*W, ceil(C / sf_vec_size), 1). The async-copy producer maps each
        # output tile and TRS coordinate back to this input-space tensor before
        # writing the SM120 SFA SMEM layout consumed by the MMA math path.
        sfa_tensor = sfa

        # Setup SFB tensor by filling B tensor to scale factor atom layout.
        # ((Atom_N, Rest_N),(Atom_K, Rest_K),RestL)
        #
        # The channel extent is the span SFB was allocated at, not C: the host pads
        # each filter position out to a whole number of SF K tiles. That padding is
        # what keeps the flat K mode usable -- it puts every filter position on a
        # tile boundary, so a K tile cut from the mode stays inside one position
        # while A and B take zero-filled channels for the tail, and the consumer
        # addresses a tile by its flat index. The span is derived from the runtime
        # channel count, so it never reaches the compiled code.
        sfb_c_span = cute.ceil_div(b.shape[4], self.sf_tile_k) * self.sf_tile_k
        sfb_shape = (
            b.shape[0],
            sfb_c_span * b.shape[3] * b.shape[2] * b.shape[1],
            1,
        )
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            sfb_shape, self.sf_vec_size
        )
        sfb_tensor = cute.make_tensor(sfb.iterator, sfb_layout)

        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, 0))
        tma_atom_a, tma_tensor_a = cpasync.make_im2col_tma_atom(
            cpasync.CopyBulkTensorIm2ColG2SOp(),
            a_gemm,
            a_smem_layout,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            lower_corner_whd,
            upper_corner_whd,
            lower_padding_whd,
            upper_padding_whd,
            stride_whd,
            lower_srt,
            stride_srt,
            internal_type=self.tma_internal_a_dtype,
        )
        tma_tensor_a = add_dummy_batch_dimension(tma_tensor_a)

        # B cta_tiler K mode is nested (tileK,), not flat tileK: b_gemm's K is the
        # nested (C,S,R,T) im2col group with runtime S/R/T. A nested tiler tiles
        # only the first (channel) level -> a static (tileK,) tile with runtime
        # S/R/T left in the rest, so the TMA CTA V-map (composition of the tiler
        # with identity(gmem.shape)) stays static while C and S/R/T stay runtime.
        # A flat tileK keeps the whole runtime nest and fails the static V-map
        # check.
        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            b_gemm,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], (self.tile_shape_mnk[2],)),
            1,
            internal_type=self.tma_internal_b_dtype,
        )
        tma_tensor_b = add_dummy_batch_dimension(tma_tensor_b)

        tma_atom_sfb, tma_tensor_sfb = self._make_tma_atoms_and_tensors(
            sfb_tensor,
            self.sfb_smem_layout_staged,
            (self.sf_tile_shape_mnk[1], self.sf_tile_shape_mnk[2]),
            1,
            internal_type=cutlass.Int16,
        )

        epi_smem_layout = cute.slice_(self.epi_smem_layout_staged, (None, None, 0))
        tma_atom_d, tma_tensor_d = cpasync.make_im2col_tma_atom(
            cpasync.CopyBulkTensorIm2ColS2GOp(),
            d_gemm,
            epi_smem_layout,
            self.epi_tile,
        )
        tma_tensor_d = cute.coalesce(tma_tensor_d, target_profile=(1, 1))
        tma_tensor_d = add_dummy_batch_dimension(tma_tensor_d)

        # Residual im2col G2S load: the exact inverse of the output's im2col S2G
        # store, so it builds the same ((Q,P,Z,N), K) GEMM view (from the residual
        # tensor's own iterator) and reuses the epilogue smem layout. Load mode
        # needs the full im2col corner set; the residual is a 1x1x1 identity tap
        # (same shape/layout/dtype as the output) so every corner/pad is 0, DHW
        # stride is 1, and the SRT lower/stride are 0/1.
        if cutlass.const_expr(self.has_residual):
            residual_gemm = cute.make_tensor(
                residual.iterator, cute.select(residual.layout, mode=[3, 2, 1, 0, 4])
            )
            residual_gemm = cute.group_modes(residual_gemm, begin=0, end=4)
            tma_atom_residual, tma_tensor_residual = cpasync.make_im2col_tma_atom(
                cpasync.CopyBulkTensorIm2ColG2SOp(),
                residual_gemm,
                epi_smem_layout,
                self.epi_tile,
                lower_corner_whd=(0, 0, 0),
                upper_corner_whd=(0, 0, 0),
                lower_padding_whd=(0, 0, 0),
                upper_padding_whd=(0, 0, 0),
                stride_whd=(1, 1, 1),
                lower_srt=(0, 0, 0),
                stride_srt=(1, 1, 1),
            )
            tma_tensor_residual = cute.coalesce(
                tma_tensor_residual, target_profile=(1, 1)
            )
            tma_tensor_residual = add_dummy_batch_dimension(tma_tensor_residual)
        else:
            tma_atom_residual, tma_tensor_residual = None, None

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
            # Two math warpgroups take turns at two points each -- before the
            # mainloop and before the epilogue -- so the array holds 2 * 2 mbarriers.
            math_wg_order_barrier_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
            clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_clc_stage * 2]
            clc_response: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int32, self.num_clc_stage * 4], 16
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_a_dtype, cute.cosize(self.a_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_b_dtype, cute.cosize(self.b_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sD: cute.struct.Align[
                cute.struct.MemRange[
                    self.d_dtype, cute.cosize(self.epi_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # Ring of cta_tile_n bias rows: the TMA load warp cp.async's each
            # tile's row into the stage its producer state points at, and the
            # tile's owning math warpgroup reads it back through its consumer
            # state. Zero length when no bias is supplied so it costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[
                    self.d_dtype,
                    self.bias_stage * self.tile_shape_mnk[1] if self.has_bias else 0,
                ],
                self.buffer_align_bytes,
            ]
            # Residual staging: same per-subtile atom as sD, single-buffered
            # (res_stage=1) so it costs minimal smem and leaves the A/B pipeline
            # deep. The S2R read lines up with the acc fragment per subtile. Zero
            # length (no smem) when beta == 0.
            sResidual: cute.struct.Align[
                cute.struct.MemRange[
                    self.d_dtype,
                    cute.cosize(self.res_smem_layout_staged)
                    if self.has_residual
                    else 0,
                ],
                self.buffer_align_bytes,
            ]
            # PipelineTmaAsync mbarriers for the residual G2S load (full+empty per
            # stage). Sized by res_stage. Zero when beta == 0.
            residual_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.res_stage * 2 if self.has_residual else 0
            ]
            # PipelineCpAsync mbarriers for the bias staging ring (full+empty per
            # stage). Zero when no bias is supplied.
            bias_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.bias_stage * 2 if self.has_bias else 0
            ]

        self.shared_storage = SharedStorage

        self.threads_per_cta = (self.threads_per_cta + 127) // 128 * 128

        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            sfa_tensor,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_d,
            tma_tensor_d,
            tma_atom_residual,
            tma_tensor_residual,
            mBias_mnl,
            alpha,
            beta,
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.sfb_mma_layout_staged,
            self.epi_smem_layout_staged,
            self.res_smem_layout_staged,
            tile_sched_params,
            cute.size(a, mode=[0]),
            cute.size(a, mode=[1]),
            cute.size(a, mode=[2]),
            cute.size(a, mode=[3]),
            cute.size(a, mode=[4]),
            cute.size(d, mode=[1]),
            cute.size(d, mode=[2]),
            cute.size(d, mode=[3]),
            rt_stride_dhw[0],
            rt_stride_dhw[1],
            rt_stride_dhw[2],
            rt_lower_pad_dhw[0],
            rt_lower_pad_dhw[1],
            rt_lower_pad_dhw[2],
            rt_dil_dhw[0],
            rt_dil_dhw[1],
            rt_dil_dhw[2],
            rt_filter_trs[0],
            rt_filter_trs[1],
            rt_filter_trs[2],
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=[1, 1, 1],
            stream=stream,
            max_number_threads=[self.threads_per_cta, 1, 1],
            min_blocks_per_mp=1,
        )
        return

    @cute.jit
    def advance(self, state: pipeline.PipelineState, iterations):
        if iterations < state.stages and ((state._index + iterations) >= state.stages):
            state._phase ^= 1
        if (
            iterations >= state.stages
            and (((state._index + iterations) // state.stages) % 2) == 1
        ):
            state._phase ^= 1
        state._index = (state._index + iterations) % state.stages
        state._count += iterations
        return state

    def _make_b_k_coord(
        self,
        c_tile_idx,
        s_idx,
        r_idx,
        t_idx,
    ):
        # After local_tile splits the channel into K-tiles, B's im2col K view is
        # (c_tile, (s, r, t)): the channel-tile is a top-level mode and S/R/T are
        # a nested group. All four modes are always present because the B layout
        # is built with runtime C and T/R/S extents — the partition cannot prove
        # any extent == 1 at compile time, so no mode ever collapses, and the
        # K-coord always carries (c_tile, s, r, t) as a flat 4-mode group.
        return (c_tile_idx, s_idx, r_idx, t_idx)

    @cute.jit
    def make_and_init_order_barrier(self, order_mbar_ptr, group_id):
        StagesPerMathWarpGroup = 2
        return pipeline.PipelineOrder.create(
            barrier_storage=order_mbar_ptr,
            depth=StagesPerMathWarpGroup,
            length=2,
            group_id=group_id,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                128,
            ),
            defer_sync=True,
        )

    @cute.jit
    def sfa_cpasync_copy_tile(
        self,
        mSFA_mkl: cute.Tensor,
        sSFA: cute.Tensor,
        tile_coord_mnl,
        sf_stage,
        sfa_c_tile_idx,
        s_coord,
        r_coord,
        t_coord,
        tidx,
        input_N: cutlass.Int32,
        input_C: cutlass.Int32,
        input_D: cutlass.Int32,
        input_H: cutlass.Int32,
        input_W: cutlass.Int32,
        output_Z: cutlass.Int32,
        output_P: cutlass.Int32,
        output_Q: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
    ):
        sfa_atom_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            mSFA_mkl.element_type,
            num_bits_per_copy=32,
        )
        # The whole 4-warp DMA group cooperates on the SFA copy: each of the 128
        # lanes owns exactly one M token of the 128 x (K/sf_vec_size) tile, so a
        # lane loads sf_k_per_ktile scale factors (vec16 -> 8, vec32 -> 4) as
        # sf_k_per_ktile//4 chunked 4-byte cp.async copies.
        # (warps 8..11 -> local_tid 0..127 via tidx % 128).
        local_tid = tidx % 128
        sfa_predicate_tensor = cute.make_rmem_tensor(
            cute.make_layout((1,)),
            cutlass.Boolean,
        )

        ZPQ = output_Z * output_P * output_Q
        PQ = output_P * output_Q
        DHW = input_D * input_H * input_W
        HW = input_H * input_W
        cta_m_tile_offset = tile_coord_mnl[0] * self.tile_shape_mnk[0]
        # A CTA loads one full SF K tile (self.sf_tile_k channels of scale
        # factors) per lane, which the SMEM BlockScaledBasicChunk atom holds. When
        # the SF K tile covers several A/B K tiles (ab_k_tiles_per_sf_k_tile > 1),
        # the paired A/B tiles share the same filter position, so their SF are
        # contiguous in the unswizzled gmem and one SF K tile fills them all; the
        # consumer offsets into the live A/B-tile half via sf_base.
        sf_k_per_ktile = self.sf_tile_k // self.sf_vec_size
        # SFA SMEM uses BlockScaledBasicChunks of blk_sf=4 consecutive scale
        # factors (one per channel group). Within a chunk the SF for consecutive
        # channel groups are contiguous (identity layout) in both the unswizzled
        # global source and the SMEM atom, so a chunk is a single 4-byte
        # cp.async; consecutive chunks are separated by the K basic-block stride
        # in SMEM, so we issue one copy per chunk. The chunk count adapts to
        # sf_vec_size (vec16 -> 8 SF -> 2 chunks; vec32 -> 4 SF -> 1 chunk).
        sf_blk = 4
        sf_chunk_cnt = sf_k_per_ktile // sf_blk
        sf_k_base = (sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile) * sf_k_per_ktile

        # SMEM M coordinate is the 2-level ((32, 4)) mode; the global token of a
        # lane is (inner + 32 * outer) == local_tid, matching the layout that the
        # SM120 math path reads back.
        sf_m_inner = local_tid % 32
        sf_m_outer = local_tid // 32

        rel_token = local_tid
        m_global = cta_m_tile_offset + rel_token
        n_idx = m_global // ZPQ
        zpq_rem = m_global % ZPQ
        z_idx = zpq_rem // PQ
        pq_rem = zpq_rem % PQ
        p_idx = pq_rem // output_Q
        q_idx = pq_rem % output_Q
        m_valid = m_global < (input_N * ZPQ)
        n_clamped = n_idx if m_valid else 0

        d_in = z_idx * rt_stride_d - rt_lower_pad_d + t_coord * rt_dil_d
        h_in = p_idx * rt_stride_h - rt_lower_pad_h + r_coord * rt_dil_h
        w_in = q_idx * rt_stride_w - rt_lower_pad_w + s_coord * rt_dil_w

        d_cl = d_in if d_in >= 0 else 0
        d_cl = d_cl if d_cl < input_D else 0
        h_cl = h_in if h_in >= 0 else 0
        h_cl = h_cl if h_cl < input_H else 0
        w_cl = w_in if w_in >= 0 else 0
        w_cl = w_cl if w_cl < input_W else 0
        sfa_m_addr = n_clamped * DHW + d_cl * HW + h_cl * input_W + w_cl

        sfa_pred_val = cutlass.Boolean(0)
        if m_valid:
            if d_in >= 0 and d_in < input_D:
                if h_in >= 0 and h_in < input_H:
                    if w_in >= 0 and w_in < input_W:
                        sfa_pred_val = cutlass.Boolean(1)
        sfa_predicate_tensor[0] = sfa_pred_val

        sfa_m_slice = mSFA_mkl[(sfa_m_addr, None, 0)]

        # A pixel owns only ceil(C / sf_vec_size) real scale factors, so a K tile
        # wider than C has trailing chunks with no backing storage. Reading one
        # would walk into the next pixel's scale factors, and off the end of the
        # buffer on the last pixel. Those chunks pair with the A channels past C,
        # which the im2col TMA zero-fills, so their scale factors never reach the
        # result -- but they must still name an in-bounds address, and must land a
        # finite value in SMEM, because the MMA applies the scale before it can
        # know the operand is zero. Re-reading the pixel's first chunk gives both.
        sf_real_blocks = cute.ceil_div(input_C, self.sf_vec_size)

        for c_chunk in cutlass.range_constexpr(sf_chunk_cnt):
            local_sf_k = sf_k_base + c_chunk * sf_blk
            gmem_sf_k = local_sf_k if local_sf_k < sf_real_blocks else 0
            tAgSFA_slice = cute.make_tensor(
                sfa_m_slice.iterator + gmem_sf_k,
                layout=cute.make_layout((sf_blk,)),
            )
            # Slice the whole chunk: span the K basic-block (mma_nsf) and the
            # blk_sf//mma_nsf middle mode for this chunk c_chunk. Their combined
            # extent is always blk_sf and is contiguous from the chunk base, so a
            # flat (blk_sf,) layout over the slice iterator is the identity copy.
            tAsSFA_slot = sSFA[
                (
                    (
                        (sf_m_inner, sf_m_outer),
                        0,
                    ),
                    ((0, None), None, c_chunk),
                    sf_stage,
                )
            ]
            tAsSFA_slice = cute.make_tensor(
                tAsSFA_slot.iterator,
                layout=cute.make_layout((sf_blk,)),
            )

            cute.copy_atom_call(
                sfa_atom_copy,
                tAgSFA_slice,
                tAsSFA_slice,
                pred=sfa_predicate_tensor,
            )

    @cute.jit
    def sfa_cpasync_copy_tile_row(
        self,
        mSFA_mkl: cute.Tensor,
        sSFA: cute.Tensor,
        sf_stage,
        sfa_c_tile_idx,
        sfa_row_off: cutlass.Int32,
        sfa_pred_val: cutlass.Boolean,
        tidx,
        input_C: cutlass.Int32,
    ):
        sfa_atom_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            mSFA_mkl.element_type,
            num_bits_per_copy=32,
        )
        # The whole 4-warp DMA group cooperates on the SFA copy: each of the 128
        # lanes owns exactly one M token of the 128 x (K/sf_vec_size) tile, so a
        # lane loads sf_k_per_ktile scale factors (vec16 -> 8, vec32 -> 4) as
        # sf_k_per_ktile//4 chunked 4-byte cp.async copies. The caller hands each
        # lane its gmem row offset and predicate, maintained as running deltas
        # over the filter walk.
        # (warps 8..11 -> local_tid 0..127 via tidx % 128).
        local_tid = tidx % 128
        sfa_predicate_tensor = cute.make_rmem_tensor(
            cute.make_layout((1,)),
            cutlass.Boolean,
        )
        sfa_predicate_tensor[0] = sfa_pred_val
        # A CTA loads one full SF K tile (self.sf_tile_k channels of scale
        # factors) per lane, which the SMEM BlockScaledBasicChunk atom holds. When
        # the SF K tile covers several A/B K tiles (ab_k_tiles_per_sf_k_tile > 1),
        # the paired A/B tiles share the same filter position, so their SF are
        # contiguous in the unswizzled gmem and one SF K tile fills them all; the
        # consumer offsets into the live A/B-tile half via sf_base.
        sf_k_per_ktile = self.sf_tile_k // self.sf_vec_size
        # SFA SMEM uses BlockScaledBasicChunks of blk_sf=4 consecutive scale
        # factors (one per channel group). Within a chunk the SF for consecutive
        # channel groups are contiguous (identity layout) in both the unswizzled
        # global source and the SMEM atom, so a chunk is a single 4-byte
        # cp.async; consecutive chunks are separated by the K basic-block stride
        # in SMEM, so we issue one copy per chunk. The chunk count adapts to
        # sf_vec_size (vec16 -> 8 SF -> 2 chunks; vec32 -> 4 SF -> 1 chunk).
        sf_blk = 4
        sf_chunk_cnt = sf_k_per_ktile // sf_blk
        sf_k_base = (sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile) * sf_k_per_ktile

        # SMEM M coordinate is the 2-level ((32, 4)) mode; the global token of a
        # lane is (inner + 32 * outer) == local_tid, matching the layout that the
        # SM120 math path reads back.
        sf_m_inner = local_tid % 32
        sf_m_outer = local_tid // 32

        # A pixel owns only ceil(C / sf_vec_size) real scale factors, so a K tile
        # wider than C has trailing chunks with no backing storage. Reading one
        # would walk into the next pixel's scale factors, and off the end of the
        # buffer on the last pixel. Those chunks pair with the A channels past C,
        # which the im2col TMA zero-fills, so their scale factors never reach the
        # result -- but they must still name an in-bounds address, and must land a
        # finite value in SMEM, because the MMA applies the scale before it can
        # know the operand is zero. Re-reading the pixel's first chunk gives both.
        sf_real_blocks = cute.ceil_div(input_C, self.sf_vec_size)

        for c_chunk in cutlass.range_constexpr(sf_chunk_cnt):
            local_sf_k = sf_k_base + c_chunk * sf_blk
            gmem_sf_k = local_sf_k if local_sf_k < sf_real_blocks else 0
            tAgSFA_slice = cute.make_tensor(
                mSFA_mkl.iterator + (sfa_row_off + gmem_sf_k),
                layout=cute.make_layout((sf_blk,)),
            )
            # Slice the whole chunk: span the K basic-block (mma_nsf) and the
            # blk_sf//mma_nsf middle mode for this chunk c_chunk. Their combined
            # extent is always blk_sf and is contiguous from the chunk base, so a
            # flat (blk_sf,) layout over the slice iterator is the identity copy.
            tAsSFA_slot = sSFA[
                (
                    (
                        (sf_m_inner, sf_m_outer),
                        0,
                    ),
                    ((0, None), None, c_chunk),
                    sf_stage,
                )
            ]
            tAsSFA_slice = cute.make_tensor(
                tAsSFA_slot.iterator,
                layout=cute.make_layout((sf_blk,)),
            )

            cute.copy_atom_call(
                sfa_atom_copy,
                tAgSFA_slice,
                tAsSFA_slice,
                pred=sfa_predicate_tensor,
            )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_d: cute.CopyAtom,
        mD_mnl: cute.Tensor,
        tma_atom_residual: Optional[cute.CopyAtom],
        mResidual_mnl: Optional[cute.Tensor],
        mBias_mnl: Optional[cute.Tensor],
        alpha: cutlass.Float32,
        beta: cutlass.Constexpr,
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        sfb_mma_layout_staged: cute.Layout,
        epi_smem_layout_staged: cute.ComposedLayout,
        res_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        input_N: cutlass.Int32,
        input_D: cutlass.Int32,
        input_H: cutlass.Int32,
        input_W: cutlass.Int32,
        input_C: cutlass.Int32,
        output_Z: cutlass.Int32,
        output_P: cutlass.Int32,
        output_Q: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        rt_filter_t: cutlass.Int32,
        rt_filter_r: cutlass.Int32,
        rt_filter_s: cutlass.Int32,
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
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_sfb)
            cpasync.prefetch_descriptor(tma_atom_d)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        if cutlass.const_expr(cute.rank(a_smem_layout_staged) == 4):
            a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, None, 0))
        else:
            a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        if cutlass.const_expr(cute.rank(b_smem_layout_staged) == 4):
            b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, None, 0))
        else:
            b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        sfb_smem_layout = cute.slice_(sfb_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = 0
        tma_copy_bytes += cute.size_in_bytes(self.a_dtype, a_smem_layout)
        tma_copy_bytes += cute.size_in_bytes(self.b_dtype, b_smem_layout)
        tma_copy_bytes += cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)

        # /////////////////////////////////////////////////////////////////////////////
        #  Alloc and init AB full/empty + ACC full mbar (pipeline)
        # /////////////////////////////////////////////////////////////////////////////
        smem = SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # mbar arrays
        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()
        math_wg_order_barrier_array_ptr = (
            storage.math_wg_order_barrier_array_ptr.data_ptr()
        )
        clc_mbar_ptr = storage.clc_mbar_ptr.data_ptr()
        clc_response_ptr = storage.clc_response.data_ptr()

        # Threads/warps participating in this pipeline. One elected TMA producer
        # arrive plus one cp.async mbarrier arrive from each SFA cp.async lane.
        # The SFA copy is spread across the full DMA warp group (4 warps = 128
        # lanes), so the full barrier expects 128 cp.async arrives plus the
        # single TMA producer arrive.
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.sfa_cpasync_warp_group_size * self.num_threads_per_warp + 1,
        )
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, self.num_mma_warps // 2
        )

        cta_layout_vmnk = cute.make_layout((1, *cta_layout_mnk.shape))
        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self.ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=tma_copy_bytes,
            barrier_storage=mainloop_pipeline_array_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
        )
        warp_group_idx = cute.arch.make_warp_uniform(tidx // 128)
        math_wg_order_barrier = self.make_and_init_order_barrier(
            math_wg_order_barrier_array_ptr, warp_group_idx
        )

        # Residual G2S load pipeline. The dedicated residual warp issues the TMA
        # load (single elected producer) into sResidual; the owning math
        # warpgroup consumes it (one full-barrier wait per epilogue). Under
        # ping-pong only one warpgroup consumes a given tile, so the consumer
        # count is a single warpgroup (num_mma_warps // 2 warps). Gated on
        # has_residual so beta == 0 allocates nothing.
        if cutlass.const_expr(self.has_residual):
            residual_pipeline_array_ptr = storage.residual_pipeline_array_ptr.data_ptr()
            residual_pipeline_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread
            )
            residual_pipeline_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mma_warps // 2,
            )
            residual_pipeline = pipeline.PipelineTmaAsync.create(
                num_stages=self.res_stage,
                producer_group=residual_pipeline_producer_group,
                consumer_group=residual_pipeline_consumer_group,
                tx_count=cute.size_in_bytes(
                    self.d_dtype,
                    cute.slice_(res_smem_layout_staged, (None, None, 0)),
                ),
                barrier_storage=residual_pipeline_array_ptr,
                cta_layout_vmnk=cta_layout_vmnk,
            )
        else:
            residual_pipeline = None

        # Bias staging pipeline: the TMA load warp cp.async's each tile's bias
        # row into the smem ring and the tile's owning math warpgroup reads it
        # back. The producer commit is a per-lane cp.async arrive from that
        # warp's 32 threads; the release is a per-thread arrive from the owning
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

        # CLC (Cluster Launch Control) pipeline. The scheduler warp is the sole
        # producer; the consumers are every math lane, the whole SFA cp.async DMA
        # warp group, and the scheduler warp itself (self-consume for exit
        # detection). Both math warpgroups peek every tile the scheduler emits and
        # a parity counter decides which one owns it, so the consumer count spans
        # all math warps, not half.
        clc_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        # The residual load warp also walks the tile stream as a CLC consumer when
        # beta != 0, so its 32 lanes join the consumer count. This term MUST gate
        # on the same const (self.has_residual) as the residual warp's CLC-consume
        # block, or the CLC producer/consumer counts diverge and the fetch pipeline
        # hangs.
        num_residual_clc_warps = 1 if cutlass.const_expr(self.has_residual) else 0
        clc_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            (
                self.num_mma_warps
                + self.sfa_cpasync_warp_group_size
                + 1  # dedicated TMA load warp
                + self.num_sched_warps
                + num_residual_clc_warps
            )
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

        cute.arch.mbarrier_init_fence()
        math_wg_order_state = math_wg_order_barrier.state

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
        sD = storage.sD.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )
        # Residual staging uses the same per-subtile atom as the D store so its
        # S2R read lines up with the accumulator fragment; it is single-buffered.
        if cutlass.const_expr(self.has_residual):
            sResidual = storage.sResidual.get_tensor(
                res_smem_layout_staged.outer, swizzle=res_smem_layout_staged.inner
            )
        else:
            sResidual = None
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)
        # Same SMEM as sSFB, viewed tile_n wide for the mma consumers.
        sSFB_mma = storage.sSFB.get_tensor(sfb_mma_layout_staged)
        # (cta_tile_n, STAGE) ring of bias rows: the TMA load warp fills the
        # stage its producer state points at, the tile's owning math warpgroup
        # reads the stage its consumer state points at.
        if cutlass.const_expr(mBias_mnl is not None):
            cta_n = self.tile_shape_mnk[1]
            sBias = storage.sBias.get_tensor(
                cute.make_layout((cta_n, self.bias_stage), stride=(1, cta_n))
            )
        else:
            sBias = None

        # ///////////////////////////////////////////////////////////////////////////////
        #  Local_tile partition global tensors
        # ///////////////////////////////////////////////////////////////////////////////
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl,
            (self.tile_shape_mnk[0], (self.tile_shape_mnk[2], 1, 1, 1)),
            (None, None, None),
        )
        # (bN, bK, loopN, loopK, loopL). K tile is nested (tileK,) so it tiles
        # only the channel (first) level of mB_nkl's (C,S,R,T) K group, leaving
        # runtime S/R/T in the loop-K rest — the TMA partition then sees a static
        # first mode and takes C and S/R/T at runtime. A flat tileK would
        # keep the whole runtime K nest static-checked and fail tma_partition.
        gB_nkl = cute.local_tile(
            mB_nkl,
            (self.tile_shape_mnk[1], (self.tile_shape_mnk[2],)),
            (None, None, None),
        )
        # (tN, tK, loopN, loopK, loopL). Tiled by the SF K tile (128 for MXFP8),
        # so one gmem K tile is a full BlockScaledBasicChunk covering the paired
        # A/B K tiles.
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            (self.sf_tile_shape_mnk[1], self.sf_tile_shape_mnk[2]),
            (None, None, None),
        )
        # (bM, bN, loopM, loopN, loopL)
        gD_mnl = cute.local_tile(
            mD_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )
        # (bM, bN, loopM, loopN, loopL) - residual shares the output's MNL tiling
        # (same (N,Z,P,Q,K) shape), so it tiles exactly like gD and the G2S load
        # lands in the same epi-subtile grid the epilogue consumes.
        if cutlass.const_expr(self.has_residual):
            gResidual_mnl = cute.local_tile(
                mResidual_mnl,
                cute.slice_(self.tile_shape_mnk, (None, None, 0)),
                (None, None, None),
            )
        else:
            gResidual_mnl = None
        # (bM, bN, loopM, loopN, loopL) - bias shares the output's MNL tiling; the
        # M axis carries a stride-0 broadcast so every spatial output row reads the
        # same per-output-channel (N) bias.
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
        if cutlass.const_expr(cute.rank(sA) == 4):
            sA_for_tma = cute.group_modes(sA, 0, 3)
        else:
            sA_for_tma = cute.group_modes(sA, 0, 2)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            sA_for_tma,
            cute.group_modes(gA_mkl, 0, 2),
        )
        tAsA = cute.filter_zeros(tAsA)
        tAgA = cute.filter_zeros(tAgA)

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        if cutlass.const_expr(cute.rank(sB) == 4):
            sB_for_tma = cute.group_modes(sB, 0, 3)
        else:
            sB_for_tma = cute.group_modes(sB, 0, 2)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            sB_for_tma,
            cute.group_modes(gB_nkl, 0, 2),
        )
        tBsB = cute.filter_zeros(tBsB)
        tBgB = cute.filter_zeros(tBgB)

        tBsSFB, tBgSFB = cpasync.tma_partition(
            tma_atom_sfb,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sSFB, 0, 2),
            cute.group_modes(gSFB_nkl, 0, 2),
        )
        tBsSFB = cute.filter_zeros(tBsSFB)
        tBgSFB = cute.filter_zeros(tBgSFB)

        #  Make frangments
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)

        tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
        tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])
        tCrSFA = sm120_utils.partition_fragment_SFA(sSFA[None, None, 0], thr_mma, tidx)
        tCrSFB = sm120_utils.partition_fragment_SFB(
            sSFB_mma[None, None, 0], thr_mma, tidx
        )

        tDgD = thr_mma.partition_C(gD_mnl)
        acc_shape = tDgD.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)
        # Bias: same partition_C chain as the accumulator, so the bias fragment
        # read back from smem lines up element-for-element with the acc fragment.
        # The M-axis stride-0 broadcast (built into mBias_mnl) means each thread
        # reads only its own N-column bias. The row is staged into this
        # warpgroup's private sBias via cp.async, then loaded to
        # registers.
        if cutlass.const_expr(mBias_mnl is not None):
            # Identity coordinates through the mma C partition, so each fragment
            # element carries its global (m, n). The n coordinate (minus the tile's
            # n_base) gives the linear column into this warpgroup's sBias row, and
            # gates the N-overhang (n >= gemm_n) mask.
            cBias_mnl = cute.make_identity_tensor(gBias_mnl.shape)
            tCcBias = thr_mma.partition_C(cBias_mnl)
            # cp.async transfers at least 32 bits, so each lane moves a 32-bit
            # vector of bias elements: two at the output's 16-bit width.
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
            cute.arch.sync_threads()

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

        # Residual G2S consumer state. Both math warpgroups advance it in phase:
        # the owner consumes+releases each subtile it reads, the non-owner skips
        # its tile by advancing the same number of subtile stages the residual
        # warp produced for it, so the ring counter stays aligned across tiles.
        if cutlass.const_expr(self.has_residual):
            residual_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.res_stage
            )

        # Bias ring consumer state, advanced the same way: the TMA load warp
        # produces one stage per tile, so the non-owner advances past a skipped
        # tile's stage to keep the ring counter aligned with its next owned tile.
        if cutlass.const_expr(self.has_bias):
            bias_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.bias_stage
            )

        # SFA cp.async warp group
        if (
            warp_idx >= self.sfa_cpasync_warp_group_start
            and warp_idx < self.tma_load_warp_id
        ):
            cute.arch.setmaxregister_decrease(self.load_register_requirement)
            # The 4-warp SFA group cooperatively issues the SFA cp.async copy
            # (one M token per lane). It waits on the empty barrier, loads its
            # scale factors, and arrives on the full barrier via the cp.async
            # mbarrier path. The dedicated TMA warp (separate warpgroup below)
            # issues A/B/SFB and contributes the single TMA arrive to the same
            # full barrier. The scalar coordinate iteration is deterministic, so
            # running it redundantly on every SFA warp keeps them in sync.
            #
            # NVFP4 walks the k tiles on hoisted per-tile state: a lane's M
            # token decomposition is loop-invariant, so its divides run once per
            # output tile, and the row offset and predicate are rebuilt only
            # when a filter counter carries. Only the finished offset and
            # predicate are read every iteration, which keeps the loop's
            # per-lane live set inside the SFA warp register budget. MXFP8
            # keeps the self-contained per-k-tile form.
            if cutlass.const_expr(self.sf_vec_size == 16):
                sfa_local_tid = tidx % 128
                sfa_ZPQ = output_Z * output_P * output_Q
                sfa_PQ = output_P * output_Q
                sfa_DHW = input_D * input_H * input_W
                sfa_HW = input_H * input_W
                sfa_sf_k_extent = mSFA_mkl.shape[1]
            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx

                mainloop_producer_state.reset_count()
                sfa_c_tile_idx = cutlass.Int32(0)
                sfa_s_idx = cutlass.Int32(0)
                sfa_r_idx = cutlass.Int32(0)
                sfa_t_idx = cutlass.Int32(0)
                c_tiles_per_fpos = cute.ceil_div(input_C, self.tile_shape_mnk[2])
                if cutlass.const_expr(self.sf_vec_size == 16):
                    # A lane's M token and its (n, z, p, q) decomposition hold
                    # for the whole output tile.
                    sfa_m_global = (
                        tile_coord_mnl[0] * self.tile_shape_mnk[0] + sfa_local_tid
                    )
                    sfa_n_idx = sfa_m_global // sfa_ZPQ
                    sfa_zpq_rem = sfa_m_global % sfa_ZPQ
                    sfa_z_idx = sfa_zpq_rem // sfa_PQ
                    sfa_pq_rem = sfa_zpq_rem % sfa_PQ
                    sfa_p_idx = sfa_pq_rem // output_Q
                    sfa_q_idx = sfa_pq_rem % output_Q
                    sfa_m_valid = sfa_m_global < (input_N * sfa_ZPQ)
                    sfa_n_clamped = sfa_n_idx if sfa_m_valid else 0
                    sfa_d_in = sfa_z_idx * rt_stride_d - rt_lower_pad_d
                    sfa_h_in = sfa_p_idx * rt_stride_h - rt_lower_pad_h
                    sfa_w_in = sfa_q_idx * rt_stride_w - rt_lower_pad_w
                    sfa_m_base = (
                        sfa_n_clamped * sfa_DHW
                        + sfa_d_in * sfa_HW
                        + sfa_h_in * input_W
                        + sfa_w_in
                    ) * sfa_sf_k_extent
                    # The h and w bases fit 16 bits each (spatial extents are
                    # far below 32k and the pads below 32), so they ride one
                    # register; the carry rebuild recovers them with arithmetic
                    # shifts, keeping the loop's carried live set minimal.
                    sfa_d_base = sfa_d_in + 0
                    sfa_hw_base = (sfa_h_in << 16) | (sfa_w_in & 0xFFFF)
                    # The offset and predicate change only when a filter counter
                    # does, so they are computed here and after each carry; a
                    # predicated-off row reads address 0, always in bounds, and
                    # its predicate suppresses the actual copy.
                    sfa_pred_val = cutlass.Boolean(0)
                    if sfa_m_valid:
                        if sfa_d_in >= 0 and sfa_d_in < input_D:
                            if sfa_h_in >= 0 and sfa_h_in < input_H:
                                if sfa_w_in >= 0 and sfa_w_in < input_W:
                                    sfa_pred_val = cutlass.Boolean(1)
                    sfa_row_off = sfa_m_base if sfa_pred_val else 0

                    # Counting up would keep the k-tile bound live across the
                    # barrier wait below and spill it to the stack.
                    sfa_iters_left = k_tile_cnt + 0
                    while sfa_iters_left > 0:
                        # Wait for the A/B/SFA buffers to be empty before
                        # writing.
                        mainloop_pipeline.sync_object_empty.wait(
                            mainloop_producer_state.index,
                            mainloop_producer_state.phase,
                        )
                        # All SFA lanes cooperatively load the SFA tile and
                        # each arrive on the full barrier when their cp.async
                        # completes.
                        self.sfa_cpasync_copy_tile_row(
                            mSFA_mkl,
                            sSFA,
                            mainloop_producer_state.index,
                            sfa_c_tile_idx,
                            sfa_row_off,
                            sfa_pred_val,
                            tidx,
                            input_C,
                        )
                        cute.arch.cp_async_commit_group()
                        mainloop_pipeline.sync_object_full.arrive_cp_async_mbarrier(
                            mainloop_producer_state.index
                        )
                        mainloop_producer_state.advance()
                        sfa_c_tile_idx = sfa_c_tile_idx + 1
                        if sfa_c_tile_idx >= c_tiles_per_fpos:
                            sfa_c_tile_idx = 0
                            sfa_s_idx = sfa_s_idx + 1
                            if sfa_s_idx >= rt_filter_s:
                                sfa_s_idx = 0
                                sfa_r_idx = sfa_r_idx + 1
                                if sfa_r_idx >= rt_filter_r:
                                    sfa_r_idx = 0
                                    sfa_t_idx = sfa_t_idx + 1
                                    if sfa_t_idx >= rt_filter_t:
                                        sfa_t_idx = 0
                            # Any carry level may have wrapped, so rebuild the
                            # coords, offset and predicate from the counters;
                            # this runs once per filter position, not per tile.
                            sfa_d_in = sfa_d_base + sfa_t_idx * rt_dil_d
                            sfa_h_in = (sfa_hw_base >> 16) + sfa_r_idx * rt_dil_h
                            sfa_w_in = (
                                (sfa_hw_base << 16) >> 16
                            ) + sfa_s_idx * rt_dil_w
                            sfa_row_delta = (
                                sfa_t_idx * rt_dil_d * sfa_HW
                                + sfa_r_idx * rt_dil_h * input_W
                                + sfa_s_idx * rt_dil_w
                            ) * sfa_sf_k_extent
                            sfa_pred_val = cutlass.Boolean(0)
                            if sfa_m_valid:
                                if sfa_d_in >= 0 and sfa_d_in < input_D:
                                    if sfa_h_in >= 0 and sfa_h_in < input_H:
                                        if sfa_w_in >= 0 and sfa_w_in < input_W:
                                            sfa_pred_val = cutlass.Boolean(1)
                            sfa_row_off = (
                                (sfa_m_base + sfa_row_delta) if sfa_pred_val else 0
                            )
                        sfa_iters_left -= 1
                else:
                    for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                        # Wait for the A/B/SFA buffers to be empty before
                        # writing.
                        mainloop_pipeline.sync_object_empty.wait(
                            mainloop_producer_state.index,
                            mainloop_producer_state.phase,
                        )
                        # All SFA lanes cooperatively load the SFA tile and
                        # each arrive on the full barrier when their cp.async
                        # completes.
                        self.sfa_cpasync_copy_tile(
                            mSFA_mkl,
                            sSFA,
                            tile_coord_mnl,
                            mainloop_producer_state.index,
                            sfa_c_tile_idx,
                            sfa_s_idx,
                            sfa_r_idx,
                            sfa_t_idx,
                            tidx,
                            input_N,
                            input_C,
                            input_D,
                            input_H,
                            input_W,
                            output_Z,
                            output_P,
                            output_Q,
                            rt_stride_d,
                            rt_stride_h,
                            rt_stride_w,
                            rt_lower_pad_d,
                            rt_lower_pad_h,
                            rt_lower_pad_w,
                            rt_dil_d,
                            rt_dil_h,
                            rt_dil_w,
                        )
                        cute.arch.cp_async_commit_group()
                        mainloop_pipeline.sync_object_full.arrive_cp_async_mbarrier(
                            mainloop_producer_state.index
                        )
                        mainloop_producer_state.advance()
                        sfa_c_tile_idx = sfa_c_tile_idx + 1
                        if sfa_c_tile_idx >= c_tiles_per_fpos:
                            sfa_c_tile_idx = 0
                            sfa_s_idx = sfa_s_idx + 1
                            if sfa_s_idx >= rt_filter_s:
                                sfa_s_idx = 0
                                sfa_r_idx = sfa_r_idx + 1
                                if sfa_r_idx >= rt_filter_r:
                                    sfa_r_idx = 0
                                    sfa_t_idx = sfa_t_idx + 1
                                    if sfa_t_idx >= rt_filter_t:
                                        sfa_t_idx = 0

                # Pull the next tile from the CLC response slot. The whole SFA
                # cp.async warp group participates as a CLC consumer.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            # end of while loop

            # Wait A/B/SFA buffers empty before the SFA warps exit (all lanes
            # only wait here, so the whole group can participate safely).
            mainloop_pipeline.producer_tail(mainloop_producer_state)
        # Dedicated TMA load warp, carried in the CLC warpgroup
        elif warp_idx == self.tma_load_warp_id:
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
            # Sole issuer of the A/B/SFB TMA loads. Sets the transaction barrier
            # for each stage and contributes the single TMA arrive; the SFA
            # warpgroup contributes the cp.async arrives to the same full
            # barrier. Walks the same tile stream as a CLC consumer.
            if cutlass.const_expr(mBias_mnl is not None):
                bias_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.bias_stage
                )
            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                tAgA_mkl = tAgA[(None, tile_coord_mnl[0], None, tile_coord_mnl[2])]
                tBgB_nkl = tBgB[(None, tile_coord_mnl[1], None, tile_coord_mnl[2])]
                # gSFB is tiled by the 128-wide SF chunk, so when tile_n is
                # narrower than a chunk several B N tiles map onto the same SF
                # tile and the SF N coordinate scales down accordingly.
                sf_n_coord = tile_coord_mnl[1] // self.n_tiles_per_sf_n_tile
                tBgSFB_nkl = tBgSFB[(None, sf_n_coord, None, tile_coord_mnl[2])]

                mainloop_producer_state.reset_count()
                k_shape = cute.shape(tAgA_mkl, mode=1)
                coord_iter = cute.repeat_like(0, k_shape)
                sfa_c_tile_idx = cutlass.Int32(0)
                sfa_s_idx = cutlass.Int32(0)
                sfa_r_idx = cutlass.Int32(0)
                sfa_t_idx = cutlass.Int32(0)
                c_tiles_per_fpos = cute.ceil_div(input_C, self.tile_shape_mnk[2])
                # SF K tiles one filter position spans, the count the host padded
                # SFB's per-position span to.
                sfb_c_tiles = cute.ceil_div(input_C, self.sf_tile_k)

                for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                    # Wait for the A/B/SFA buffers to be empty before writing.
                    mainloop_pipeline.sync_object_empty.wait(
                        mainloop_producer_state.index, mainloop_producer_state.phase
                    )
                    # Set the transaction barrier for the A/B/SFB buffers, then
                    # issue the TMA loads.
                    mainloop_pipeline.sync_object_full.arrive(
                        mainloop_producer_state.index,
                        mainloop_pipeline.producer_mask,
                    )

                    tAgA_k = tAgA_mkl[(None, coord_iter)]
                    tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]

                    tBgB_k = tBgB_nkl[
                        (
                            None,
                            self._make_b_k_coord(
                                sfa_c_tile_idx,
                                sfa_s_idx,
                                sfa_r_idx,
                                sfa_t_idx,
                            ),
                        )
                    ]
                    tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]

                    # SFB's K mode is flat: it runs one filter position's channels
                    # before moving to the next, and the positions in the S->R->T
                    # order A and B traverse. The span padding puts each position on
                    # a tile boundary, so a position holds sfb_c_tiles whole tiles
                    # and a tile's flat index is that count times the position plus
                    # the channel tile inside it. The channel tile is on the SF
                    # cadence, which is coarser whenever one SF chunk serves several
                    # A/B K tiles; each A/B stage still TMAs the whole chunk and the
                    # consumer reads its live part.
                    sfb_fpos = (
                        sfa_s_idx
                        + sfa_r_idx * rt_filter_s
                        + sfa_t_idx * (rt_filter_r * rt_filter_s)
                    )
                    tBgSFB_k = tBgSFB_nkl[
                        (
                            None,
                            sfb_fpos * sfb_c_tiles
                            + sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile,
                        )
                    ]
                    tBsSFB_pipe = tBsSFB[(None, mainloop_producer_state.index)]

                    cute.copy(
                        tma_atom_a,
                        tAgA_k,
                        tAsA_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_k,
                        tBsB_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                    )
                    cute.copy(
                        tma_atom_sfb,
                        tBgSFB_k,
                        tBsSFB_pipe,
                        tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                            mainloop_producer_state
                        ),
                    )
                    # Mainloop pipeline's producer commit is a NOP for TMA.
                    mainloop_pipeline.producer_commit(mainloop_producer_state)
                    mainloop_producer_state.advance()
                    sfa_c_tile_idx = sfa_c_tile_idx + 1
                    if sfa_c_tile_idx >= c_tiles_per_fpos:
                        sfa_c_tile_idx = 0
                        sfa_s_idx = sfa_s_idx + 1
                        if sfa_s_idx >= rt_filter_s:
                            sfa_s_idx = 0
                            sfa_r_idx = sfa_r_idx + 1
                            if sfa_r_idx >= rt_filter_r:
                                sfa_r_idx = 0
                                sfa_t_idx = sfa_t_idx + 1
                                if sfa_t_idx >= rt_filter_t:
                                    sfa_t_idx = 0
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

                # Walk the tile stream in lockstep with the SFA group.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            # end of while loop

            mainloop_pipeline.producer_tail(mainloop_producer_state)
        # MMA warp group
        elif warp_idx < self.num_mma_warps:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)
            num_k_blocks = cute.size(tCrA, mode=[2])
            # A/B K tiles one filter position spans. sf_base below indexes the SF
            # chunk by the tile's index inside its own filter position, which is what
            # stays aligned with the chunk when a position holds a fractional number
            # of chunks.
            c_tiles_per_fpos = cute.ceil_div(input_C, self.tile_shape_mnk[2])

            # ///////////////////////////////////////////////////////////////////////////////
            # Copy Atom A/B retiling for TMA load A/B
            # ///////////////////////////////////////////////////////////////////////////////
            atom_copy_ldmatrix_A = make_ldmatrix_atom(
                self.a_dtype,
                transpose=self.a_layout.is_m_major_a(),
                num_matrices=4,
                mixed_mode=self.mixed_mode,
            )
            atom_copy_ldmatrix_B = make_ldmatrix_atom(
                self.b_dtype,
                transpose=self.b_layout.is_n_major_b(),
                num_matrices=4,
                mixed_mode=self.mixed_mode,
            )
            smem_tiled_copy_A = cute.make_tiled_copy_A(atom_copy_ldmatrix_A, tiled_mma)
            smem_tiled_copy_B = cute.make_tiled_copy_B(atom_copy_ldmatrix_B, tiled_mma)

            atom_copy_ldmatrix_SF = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self.sf_dtype,
            )
            smem_tiled_copy_SFA = cute.make_tiled_copy(
                atom_copy_ldmatrix_SF,
                sm120_utils.get_layoutSFA_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[0]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )
            smem_tiled_copy_SFB = cute.make_tiled_copy(
                atom_copy_ldmatrix_SF,
                sm120_utils.get_layoutSFB_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[1]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )

            thr_copy_ldmatrix_A = smem_tiled_copy_A.get_slice(tidx % 128)
            thr_copy_ldmatrix_B = smem_tiled_copy_B.get_slice(tidx % 128)
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)
            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            thr_copy_ldmatrix_SFA = smem_tiled_copy_SFA.get_slice(tidx % 128)
            thr_copy_ldmatrix_SFB = smem_tiled_copy_SFB.get_slice(tidx % 128)
            tCsSFA_copy_view = thr_copy_ldmatrix_SFA.partition_S(sSFA)
            tCrSFA_copy_view = thr_copy_ldmatrix_SFA.retile(tCrSFA)
            tCsSFB_copy_view = thr_copy_ldmatrix_SFB.partition_S(sSFB_mma)
            tCrSFB_copy_view = thr_copy_ldmatrix_SFB.retile(tCrSFB)

            # Parity counter for the ping-pong warpgroups. The CLC scheduler
            # hands the same tile stream to both warpgroups; wg0 owns the tiles
            # at parity 0 (tile 0, 2, 4, ...) and wg1 owns parity 1. The
            # warpgroup whose parity does NOT match skips the tile and advances
            # its mainloop_consumer_state by k_tile_cnt so DMA's linear
            # production stays in phase with this warpgroup's next owned tile.
            tile_parity = cutlass.Int32(0)

            while work_tile.is_valid_tile:
                if tile_parity == warp_group_idx:
                    tile_coord_mnl = work_tile.tile_idx
                    gD_mnl_slice = gD_mnl[(None, None, *tile_coord_mnl)]
                    # This tile's slice of the staged SF chunk. Consecutive N
                    # tiles share one chunk when tile_n is narrower than it, and
                    # a slice sits (tile_n/32) SF blocks past the previous one.
                    if cutlass.const_expr(self.n_tiles_per_sf_n_tile > 1):
                        sfb_n_slice = tile_coord_mnl[1] % self.n_tiles_per_sf_n_tile
                        tCsSFB_tile = cute.make_tensor(
                            tCsSFB_copy_view.iterator
                            + sfb_n_slice * (self.tile_shape_mnk[1] // 32) * 4,
                            tCsSFB_copy_view.layout,
                        )
                    else:
                        tCsSFB_tile = tCsSFB_copy_view
                    # Clear the accumulator
                    accumulators.fill(0.0)

                    # /////////////////////////////////////////////////////////////////////////////
                    #  Pipelined MAINLOOP
                    # /////////////////////////////////////////////////////////////////////////////

                    mainloop_consumer_state.reset_count()
                    math_wg_order_barrier.wait(math_wg_order_state)
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
                    tCsSFA_p = tCsSFA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsSFB_p = tCsSFB_tile[
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

                    tCsSFA_p_filtered = cute.filter_zeros(tCsSFA_p)
                    tCsSFB_p_filtered = cute.filter_zeros(tCsSFB_p)
                    tCrSFA_copy_view_filtered = cute.filter_zeros(tCrSFA_copy_view)
                    tCrSFB_copy_view_filtered = cute.filter_zeros(tCrSFB_copy_view)

                    # One SF K tile holds ab_k_tiles_per_sf_k_tile A/B tiles worth
                    # of scale factors. sf_base picks the current A/B tile's half
                    # of the chunk (0 for NVFP4, where the ratio is 1).
                    sf_base = (
                        (mainloop_consumer_state.count % c_tiles_per_fpos)
                        % self.ab_k_tiles_per_sf_k_tile
                    ) * num_k_blocks
                    cute.copy(
                        smem_tiled_copy_SFA,
                        tCsSFA_p_filtered[None, None, sf_base],
                        tCrSFA_copy_view_filtered[None, None, 0],
                    )
                    cute.copy(
                        smem_tiled_copy_SFB,
                        tCsSFB_p_filtered[None, None, sf_base],
                        tCrSFB_copy_view_filtered[None, None, 0],
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

                                tCsA_p = tCsA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsB_p = tCsB_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsSFA_p = tCsSFA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsSFB_p = tCsSFB_tile[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                mainloop_pipeline.consumer_wait(
                                    mainloop_consumer_state, peek_ab_full_status
                                )

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
                                # sf_base picks the live A/B tile's part of the SF
                                # K chunk; the consumer count it reads has already
                                # been advanced above when k_block_idx is the last one.
                                sf_base = (
                                    (mainloop_consumer_state.count % c_tiles_per_fpos)
                                    % self.ab_k_tiles_per_sf_k_tile
                                ) * num_k_blocks
                                cute.copy(
                                    smem_tiled_copy_SFA,
                                    cute.filter_zeros(tCsSFA_p)[
                                        None, None, sf_base + k_block_next
                                    ],
                                    cute.filter_zeros(tCrSFA_copy_view)[
                                        None, None, k_block_next
                                    ],
                                )
                                cute.copy(
                                    smem_tiled_copy_SFB,
                                    cute.filter_zeros(tCsSFB_p)[
                                        None, None, sf_base + k_block_next
                                    ],
                                    cute.filter_zeros(tCrSFB_copy_view)[
                                        None, None, k_block_next
                                    ],
                                )

                            # With more than one k_block the prefetch targets a
                            # different register slot than the MMA is about to read,
                            # so issuing it first overlaps the load with the MMA.
                            # With exactly one, k_block_next wraps to the same slot
                            # and the tile has already been released, so prefetching
                            # first would overwrite the operands with the next tile's
                            # before the MMA consumes them; it has to come after.
                            if cutlass.const_expr(num_k_blocks > 1):
                                prefetch_next_k_block()
                            # Mixed FP4 x FP8 register-side bit shift before mma.sync to
                            # move the FP4 nibble (loaded into the LOW half of each Int8
                            # register byte by ldsm.b4x16_p64) into the MIDDLE of the byte
                            # where mma.sync.kind::mxf8f6f4 reads it. See blockscaled_gemm_dispatch.FP4_SHIFT_BITS.
                            if cutlass.const_expr(
                                self.mixed_mode and self.a_dtype.width < 8
                            ):
                                a_view = cute.recast_tensor(
                                    tCrA[None, None, k_block_idx], cutlass.Int8
                                )
                                for _i in cutlass.range_constexpr(cute.size(a_view)):
                                    a_view[_i] = cutlass.Int8(
                                        a_view[_i] << FP4_SHIFT_BITS
                                    )
                            if cutlass.const_expr(
                                self.mixed_mode and self.b_dtype.width < 8
                            ):
                                b_view = cute.recast_tensor(
                                    tCrB[None, None, k_block_idx], cutlass.Int8
                                )
                                for _i in cutlass.range_constexpr(cute.size(b_view)):
                                    b_view[_i] = cutlass.Int8(
                                        b_view[_i] << FP4_SHIFT_BITS
                                    )
                            cute.gemm(
                                tiled_mma,
                                accumulators,
                                [
                                    tCrA[None, None, k_block_idx],
                                    tCrSFA[None, None, k_block_idx],
                                ],
                                [
                                    tCrB[None, None, k_block_idx],
                                    tCrSFB[None, None, k_block_idx],
                                ],
                                accumulators,
                            )
                            if cutlass.const_expr(num_k_blocks == 1):
                                prefetch_next_k_block()
                            # end of for loop
                    # end of for loop
                    # Hoist out last k_tile
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_next = (
                            0 if k_block_idx + 1 == num_k_blocks else k_block_idx + 1
                        )

                        if k_block_idx == num_k_blocks - 1:
                            mainloop_pipeline.consumer_release(mainloop_consumer_state)
                            mainloop_consumer_state.advance()

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
                            tCsSFA_p_filtered = cute.filter_zeros(tCsSFA_p)
                            tCsSFB_p_filtered = cute.filter_zeros(tCsSFB_p)
                            tCrSFA_copy_view_filtered = cute.filter_zeros(
                                tCrSFA_copy_view
                            )
                            tCrSFB_copy_view_filtered = cute.filter_zeros(
                                tCrSFB_copy_view
                            )
                            sf_base = (
                                (mainloop_consumer_state.count % c_tiles_per_fpos)
                                % self.ab_k_tiles_per_sf_k_tile
                            ) * num_k_blocks
                            cute.copy(
                                smem_tiled_copy_SFA,
                                tCsSFA_p_filtered[None, None, sf_base + k_block_next],
                                tCrSFA_copy_view_filtered[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_SFB,
                                tCsSFB_p_filtered[None, None, sf_base + k_block_next],
                                tCrSFB_copy_view_filtered[None, None, k_block_next],
                            )
                        # Mixed FP4 x FP8 register-side bit shift before mma.sync (hoisted tail).
                        if cutlass.const_expr(
                            self.mixed_mode and self.a_dtype.width < 8
                        ):
                            a_view_h = cute.recast_tensor(
                                tCrA[None, None, k_block_idx], cutlass.Int8
                            )
                            for _i in cutlass.range_constexpr(cute.size(a_view_h)):
                                a_view_h[_i] = cutlass.Int8(
                                    a_view_h[_i] << FP4_SHIFT_BITS
                                )
                        if cutlass.const_expr(
                            self.mixed_mode and self.b_dtype.width < 8
                        ):
                            b_view_h = cute.recast_tensor(
                                tCrB[None, None, k_block_idx], cutlass.Int8
                            )
                            for _i in cutlass.range_constexpr(cute.size(b_view_h)):
                                b_view_h[_i] = cutlass.Int8(
                                    b_view_h[_i] << FP4_SHIFT_BITS
                                )
                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            [
                                tCrA[None, None, k_block_idx],
                                tCrSFA[None, None, k_block_idx],
                            ],
                            [
                                tCrB[None, None, k_block_idx],
                                tCrSFB[None, None, k_block_idx],
                            ],
                            accumulators,
                        )

                    # Signal the other warpgroup it may start its mainloop. The
                    # matching wait is deferred to just before the epilogue so the
                    # two warpgroups overlap this warpgroup's epilogue with the
                    # other's mainloop (CUTLASS ping-pong).
                    math_wg_order_state = math_wg_order_barrier.arrive(
                        math_wg_order_state
                    )

                    # Apply the per-tensor alpha scale in FP32 before bias/residual
                    # (D = act(alpha * acc + bias)). alpha is a runtime scalar, so
                    # this multiply lives in every cubin regardless of its value.
                    accumulators.store(accumulators.load() * alpha)

                    # Add per-output-channel bias in FP32 (D = act(alpha*acc + bias)).
                    # The TMA load warp has cp.async'd this tile's contiguous
                    # cta_tile_n bias values into the ring stage this warpgroup's
                    # consumer state points at; every thread loads its own N
                    # columns back and adds them to the accumulator. One value per
                    # output channel is fetched once and broadcast to all M rows
                    # via the stride-0 M axis of mBias_mnl.
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_pipeline.consumer_wait(bias_consumer_state)
                        sBias_row = sBias[(None, bias_consumer_state.index)]
                        # Read back into a fragment aligned with the accumulator. The
                        # identity-coordinate partition gives each element its tile-local
                        # N column [0, cta_n), which is exactly the linear index into
                        # the staged row (the producer already applied n_base when
                        # staging from gmem and zero-filled any N-overhang). Indexing
                        # the row by that tile-local column, rather than by a gmem
                        # channel stride, is what makes the smem read correct.
                        tCcBias_tile = tCcBias[(None, None, None, *tile_coord_mnl)]
                        tCrBias = cute.make_rmem_tensor(
                            accumulators.shape, mBias_mnl.element_type
                        )
                        for be in cutlass.range_constexpr(cute.size(tCrBias)):
                            tCrBias[be] = sBias_row[tCcBias_tile[be][1]]
                        # Release the stage so the TMA load warp can refill it:
                        # every thread arrives only after its smem reads are done.
                        cute.arch.fence_proxy("async.shared", space="cta")
                        bias_pipeline.consumer_release(bias_consumer_state)
                        bias_consumer_state.advance()
                        accumulators.store(
                            accumulators.load() + tCrBias.load().to(self.acc_dtype)
                        )

                    # /////////////////////////////////////////////////////////////////////////////
                    #  EPILOG
                    # /////////////////////////////////////////////////////////////////////////////

                    # Serialize the epilogue against the other warpgroup: wait for
                    # our turn before touching the shared sD staging buffer. Pairs
                    # with the mainloop-tail arrive above so this warpgroup's
                    # epilogue overlaps the other's mainloop.
                    math_wg_order_barrier.wait(math_wg_order_state)
                    (
                        tiled_copy_r2s,
                        thr_copy_r2s,
                        tRS_sD,
                        tRS_rAcc,
                        tRS_rD,
                        tRS_rD_layout,
                    ) = self.epilog_smem_copy_and_partition(
                        tiled_mma, accumulators, tidx, sD
                    )

                    bSG_sD, bSG_gD = self.epilog_gmem_copy_and_partition(
                        tma_atom_d, gD_mnl_slice, sD
                    )

                    # Residual read-back: partition sResidual with the same thread
                    # slice the D store uses for its reg source (partition_S), so
                    # tRS_sResidual has the exact per-thread reg-fragment TV layout
                    # of tRS_rD (which is allocated from this partition's shape).
                    # A plain element copy then reads each stage into a congruent
                    # reg fragment, so the FP32 add lines up with the accumulator.
                    if cutlass.const_expr(self.has_residual):
                        # (R2S, R2S_M, R2S_N, PIPE_D) reg-side view of the residual
                        # smem, congruent with tRS_rD.
                        tRS_sResidual = thr_copy_r2s.partition_S(sResidual)

                    # Initialize tma store pipeline
                    tma_store_producer_group = pipeline.CooperativeGroup(
                        pipeline.Agent.Thread,
                        self.num_mma_warps * self.num_threads_per_warp,
                    )
                    tma_store_pipeline = pipeline.PipelineTmaStore.create(
                        num_stages=self.epi_stage,
                        producer_group=tma_store_producer_group,
                    )

                    epi_rest_m = bSG_gD.shape[1][0]
                    epi_rest_n = bSG_gD.shape[1][1]
                    epi_tile_m = self.epi_tile[0]
                    epi_tile_n = self.epi_tile[1]
                    mma_tile_m = self.tile_shape_mnk[0] // cute.size(tRS_rAcc, mode=[1])
                    mma_tile_n = self.tile_shape_mnk[1] // cute.size(tRS_rAcc, mode=[2])

                    for epi_m in cutlass.range_constexpr(epi_rest_m):
                        for epi_n in cutlass.range_constexpr(epi_rest_n):
                            MmaMPerEpiM = epi_tile_m // mma_tile_m
                            MmaNPerEpiN = epi_tile_n // mma_tile_n
                            for mma_n_in_epi in cutlass.range_constexpr(MmaNPerEpiN):
                                for mma_m_in_epi in cutlass.range_constexpr(
                                    MmaMPerEpiM
                                ):
                                    mma_n = (epi_n * MmaNPerEpiN) + mma_n_in_epi
                                    mma_m = (epi_m * MmaMPerEpiM) + mma_m_in_epi
                                    tRS_rD_slice = tRS_rD[
                                        (None, mma_m_in_epi, mma_n_in_epi)
                                    ]
                                    tRS_rAcc_slice = tRS_rAcc[(None, mma_m, mma_n)]
                                    for elem_idx in cutlass.range_constexpr(
                                        cute.size(tRS_rD_slice)
                                    ):
                                        tRS_rD_slice[elem_idx] = tRS_rAcc_slice[
                                            elem_idx
                                        ]

                            # Add this subtile's residual in FP32 before the
                            # activation (D = act(alpha*acc + bias + beta*residual)).
                            # Wait for the residual warp's G2S load to land, read it
                            # into a fragment shaped like tRS_rD, add beta*residual,
                            # then release the stage. beta is a compile-time constant
                            # folded into the scaled add.
                            if cutlass.const_expr(self.has_residual):
                                residual_pipeline.consumer_wait(residual_consumer_state)
                                tRS_rResidual = cute.make_rmem_tensor(
                                    tRS_rD_layout.shape, self.d_dtype
                                )
                                cute.autovec_copy(
                                    tRS_sResidual[
                                        (
                                            None,
                                            None,
                                            None,
                                            residual_consumer_state.index,
                                        )
                                    ],
                                    tRS_rResidual,
                                )
                                cute.arch.fence_proxy(
                                    "async.shared",
                                    space="cta",
                                )
                                residual_pipeline.consumer_release(
                                    residual_consumer_state
                                )
                                residual_consumer_state.advance()
                                tRS_rD.store(
                                    tRS_rD.load()
                                    + self.beta
                                    * tRS_rResidual.load().to(self.acc_dtype)
                                )

                            # Apply the epilogue activation in FP32, then cast to the
                            # output type. Folded into the cubin as a Constexpr op, so
                            # each activation compiles to its own kernel.
                            tRS_rD_out = cute.make_rmem_tensor(
                                tRS_rD_layout.shape, self.d_dtype
                            )
                            acc_vec = epilogue_op(tRS_rD.load())
                            tRS_rD_out.store(acc_vec.to(self.d_dtype))

                            # Register to shared memory
                            epi_buffer = (epi_m * epi_rest_n + epi_n) % cute.size(
                                tRS_sD, mode=[3]
                            )
                            self.epilog_sync_barrier.arrive_and_wait()
                            cute.copy(
                                tiled_copy_r2s,
                                tRS_rD_out,
                                tRS_sD[(None, None, None, epi_buffer)],
                            )
                            cute.arch.fence_proxy(
                                "async.shared",
                                space="cta",
                            )
                            # barrier for sync
                            self.epilog_sync_barrier.arrive_and_wait()
                            # Get the global memory coordinate for the current epi tile.
                            gmem_coord = (epi_m, epi_n)
                            # Copy from shared memory to global memory
                            if warp_idx % 4 == 0:
                                cute.copy(
                                    tma_atom_d,
                                    bSG_sD[(None, epi_buffer)],
                                    bSG_gD[(None, gmem_coord)],
                                )
                                tma_store_pipeline.producer_commit()
                                tma_store_pipeline.producer_acquire()
                    tma_store_pipeline.producer_tail()
                    # Signal the other warpgroup it can start its epilogue.
                    math_wg_order_state = math_wg_order_barrier.arrive(
                        math_wg_order_state
                    )
                else:
                    # This warpgroup does not own the current tile. Advance the
                    # mainloop consumer state by the k_tile_cnt stages the DMA
                    # warp group produced for it, keeping DMA's linear production
                    # in phase with this warpgroup's next owned tile.
                    mainloop_consumer_state = self.advance(
                        mainloop_consumer_state, k_tile_cnt
                    )
                    # Likewise skip this tile's residual: the residual warp
                    # produced one stage per output subtile for it, so advance the
                    # residual consumer state by that subtile count to keep the
                    # ring counter aligned with the next owned tile.
                    if cutlass.const_expr(self.has_residual):
                        residual_subtiles_per_tile = (
                            self.tile_shape_mnk[0] // self.epi_tile[0]
                        ) * (self.tile_shape_mnk[1] // self.epi_tile[1])
                        residual_consumer_state = self.advance(
                            residual_consumer_state, residual_subtiles_per_tile
                        )
                    # Likewise skip this tile's bias stage: the TMA load warp
                    # produced one per tile, so advance past it to stay aligned
                    # with the next owned tile.
                    if cutlass.const_expr(self.has_bias):
                        bias_consumer_state.advance()

                # Pull the next tile from the CLC response slot. Both MMA
                # warpgroups, the SFA cp.async group, and the scheduler warp
                # participate as consumers; the parity flip below routes the tile
                # to its owning warpgroup.
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
                tile_parity = cutlass.Int32(1) - tile_parity
                # End of for k_tile loop
            # End of while loop
        # End of MMA warp group

        # CLC scheduler warp: sole producer of the CLC tile stream.
        elif warp_idx == self.sched_warp_id:
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
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
        # Dedicated residual G2S load warp (only compiled when beta != 0). Walks
        # the full tile stream as a CLC consumer -- like the TMA load warp -- and
        # issues the residual im2col G2S load for every output tile, one per
        # epi-subtile, into sResidual. Both math warpgroups consume their own
        # tile's residual from the same pipeline.
        elif warp_idx == self.residual_tma_warp_id:
            # Dedicated residual G2S load warp. The whole body is compiled only
            # when beta != 0; at beta == 0 this warp just sets the register floor
            # like the other idle round-up warps (has_residual gates on the same
            # const as the CLC consumer count and the smem/pipeline allocation, so
            # nothing here touches the None residual handles).
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
            if cutlass.const_expr(self.has_residual):
                residual_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.res_stage
                )
                # Same gmem/smem TMA partition the epilogue consumer uses, so the
                # producer stages subtiles in the exact grid the consumer reads.
                sResidual_for_tma = cute.group_modes(sResidual, 0, 2)
                while work_tile.is_valid_tile:
                    tile_coord_mnl = work_tile.tile_idx
                    gResidual_slice = gResidual_mnl[(None, None, *tile_coord_mnl)]
                    tcg_residual = cute.zipped_divide(gResidual_slice, self.epi_tile)
                    bGS_sResidual, bGS_gResidual = cpasync.tma_partition(
                        tma_atom_residual,
                        0,
                        cute.make_layout(1),
                        sResidual_for_tma,
                        tcg_residual,
                    )
                    residual_rest_m = bGS_gResidual.shape[1][0]
                    residual_rest_n = bGS_gResidual.shape[1][1]
                    for epi_m in cutlass.range_constexpr(residual_rest_m):
                        for epi_n in cutlass.range_constexpr(residual_rest_n):
                            residual_pipeline.producer_acquire(residual_producer_state)
                            cute.copy(
                                tma_atom_residual,
                                bGS_gResidual[(None, (epi_m, epi_n))],
                                bGS_sResidual[(None, residual_producer_state.index)],
                                tma_bar_ptr=residual_pipeline.producer_get_barrier(
                                    residual_producer_state
                                ),
                            )
                            residual_pipeline.producer_commit(residual_producer_state)
                            residual_producer_state.advance()

                    # Walk the tile stream in lockstep with the epilogue consumers.
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()
                residual_pipeline.producer_tail(residual_producer_state)
        # Unused warps rounded up by the warpgroup register-realloc requirement.
        # Same warpgroup as the scheduler warp, so it must use the same count.
        else:
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
        return

    def epilog_smem_copy_and_partition(
        self,
        tiled_mma: cute.TiledMma,
        accumulators: cute.Tensor,
        tidx: cutlass.Int32,
        sD: cute.Tensor,
    ) -> Tuple[
        cute.TiledCopy,
        cute.TiledCopy,
        cute.Tensor,
        cute.Tensor,
        cute.Tensor,
        cute.Layout,
    ]:
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

        :return: A tuple containing (tiled_copy_r2s, thr_copy_r2s, tRS_sD, tRS_rAcc,
            tRS_rD, tRS_rD_layout) where:
            - tiled_copy_r2s: The tiled copy operation for register to smem copy(r2s)
            - thr_copy_r2s: This thread's slice of it, which the residual read-back
              reuses so its register fragment is congruent with tRS_rD
            - tRS_sD: The partitioned tensor D (smem destination)
            - tRS_rAcc: The accumulator retiled to the store's fragment
            - tRS_rD: The register tensor the epilogue narrows into
            - tRS_rD_layout: Its layout, which the bias and residual fragments reuse
        :rtype: Tuple[cute.TiledCopy, cute.TiledCopy, cute.Tensor, cute.Tensor,
            cute.Tensor, cute.Layout]
        """
        copy_atom_r2s = sm120_utils.sm120_get_smem_store_op(
            self.d_layout,
            elem_ty_d=self.d_dtype,
            elem_ty_acc=self.acc_dtype,
        )

        # StMatrix is a 16-bit instruction; pass Float16 so the partition
        # geometry (which thread holds which element) is consistent
        # regardless of d_dtype. The actual rmem->smem store is performed
        # by copy_atom_r2s above, which is selected for the output type.
        copy_atom_C = cute.make_copy_atom(
            cute.nvgpu.warp.StMatrix8x8x16bOp(
                self.d_layout.is_m_major_c(),
                2,
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

        # Allocate D registers.
        rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
        tRS_rD_layout = cute.make_layout(rD_shape[:3])
        tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
        return tiled_copy_r2s, thr_copy_r2s, tRS_sD, tRS_rAcc, tRS_rD, tRS_rD_layout

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
        return cpasync.tma_partition(
            tma_atom_d,
            0,
            cute.make_layout(1),
            sepi_for_tma_partition,
            tcgc_for_tma_partition,
        )

    def _compute_stages(
        self,
        tile_shape_mnk: tuple[int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        sf_dtype: type[cutlass.Numeric],
        epi_tile: tuple[int, int],
        d_dtype: type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
        has_residual: bool = False,
    ) -> tuple[int, int]:
        """Computes the number of A/B and epilogue stages.

        The A/B stage count is chosen so the full SharedStorage (every pipeline
        mbar, whose count scales with the stage count, plus every operand array
        with its 1024B alignment padding) fits in smem. The count is derived by
        assembling the actual SharedStorage struct for a candidate stage count and
        reading its exact size_in_bytes(), then taking the largest that fits --
        rather than dividing capacity by a per-stage byte estimate that omits the
        alignment padding and the stage-scaled mbar bytes.

        :param tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :param smem_capacity: Total available shared memory capacity in bytes.
        :param occupancy: CTAs per SM. Always 1 for this persistent kernel.

        :return: (A/B operand stages, epilogue stages)
        :rtype: tuple[int, int]
        """
        epi_stage_max = (tile_shape_mnk[1] // epi_tile[1]) * (
            tile_shape_mnk[0] // epi_tile[0]
        )
        epi_stage = min(epi_stage_max, 4)
        res_stage = 1

        buffer_align_bytes = self.buffer_align_bytes
        num_clc_stage = self.num_clc_stage
        has_bias = self.has_bias
        cta_n = tile_shape_mnk[1]

        def smem_bytes(ab_stage: int) -> int:
            """Exact SharedStorage byte size for a candidate stage count.

            Builds the operand/SF/epi/residual layouts for this ``ab_stage`` and
            assembles the SharedStorage this kernel allocates. Every field mirrors
            the runtime SharedStorage in __call__; keep the two in sync so the byte
            total is exact.
            """
            (
                a_smem,
                b_smem,
                sfa_smem,
                sfb_smem,
                epi_smem,
                res_smem,
            ) = self._make_smem_layouts(
                tile_shape_mnk,
                epi_tile,
                a_dtype,
                self.a_layout,
                b_dtype,
                self.b_layout,
                ab_stage,
                d_dtype,
                self.d_layout,
                epi_stage,
                res_stage,
                sf_vec_size=self.sf_vec_size,
                tiled_mma=self.tiled_mma,
                sf_tile_shape_mnk=self.sf_tile_shape_mnk,
            )

            @cute.struct
            class ProbeStorage:
                """Field-for-field mirror of the runtime SharedStorage, sized for
                this stage count so size_in_bytes() gives the exact allocation."""

                mainloop_pipeline_array_ptr: cute.struct.MemRange[
                    cutlass.Int64, ab_stage * 2
                ]
                math_wg_order_barrier_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
                clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_clc_stage * 2]
                clc_response: cute.struct.Align[
                    cute.struct.MemRange[cutlass.Int32, num_clc_stage * 4], 16
                ]
                sA: cute.struct.Align[
                    cute.struct.MemRange[a_dtype, cute.cosize(a_smem)],
                    buffer_align_bytes,
                ]
                sB: cute.struct.Align[
                    cute.struct.MemRange[b_dtype, cute.cosize(b_smem)],
                    buffer_align_bytes,
                ]
                sSFA: cute.struct.Align[
                    cute.struct.MemRange[sf_dtype, cute.cosize(sfa_smem)],
                    buffer_align_bytes,
                ]
                sSFB: cute.struct.Align[
                    cute.struct.MemRange[sf_dtype, cute.cosize(sfb_smem)],
                    buffer_align_bytes,
                ]
                sD: cute.struct.Align[
                    cute.struct.MemRange[d_dtype, cute.cosize(epi_smem)],
                    buffer_align_bytes,
                ]
                sBias: cute.struct.Align[
                    cute.struct.MemRange[
                        d_dtype, self.bias_stage * cta_n if has_bias else 0
                    ],
                    buffer_align_bytes,
                ]
                sResidual: cute.struct.Align[
                    cute.struct.MemRange[
                        d_dtype, cute.cosize(res_smem) if has_residual else 0
                    ],
                    buffer_align_bytes,
                ]
                residual_pipeline_array_ptr: cute.struct.MemRange[
                    cutlass.Int64, res_stage * 2 if has_residual else 0
                ]
                bias_pipeline_array_ptr: cute.struct.MemRange[
                    cutlass.Int64, self.bias_stage * 2 if has_bias else 0
                ]

            return ProbeStorage.size_in_bytes()

        # A single A/B stage must fit: a tile whose one-stage SharedStorage already
        # exceeds capacity is unimplementable and is rejected upstream by
        # can_implement, so the lower-bound search below can assume >= 1 fits.
        if smem_bytes(1) > smem_capacity:
            raise RuntimeError(
                "tile too large for even one A/B stage; can_implement should have "
                "rejected it before reaching stage selection"
            )

        # Compute a lower bound that is guaranteed to fit, then scan upward once
        # (never downward) to the largest A/B stage whose exact SharedStorage
        # fits. Each added stage grows the four staged arrays (sA/sB/sSFA/sSFB) by
        # their raw per-stage bytes; the Align[1024] rounding of each array is a
        # one-time boundary crossing over the whole growth, so it contributes at
        # most 4*1024 B total. Bounding the alignment loss as that constant in the
        # numerator (rather than inflating every stage's slope) keeps the lower
        # bound within a few stages of the true maximum while still guaranteeing
        # cost(lb) <= cost(1) + (lb-1)*slope + 4*1024 <= capacity. size_in_bytes
        # is monotonic in the stage count, so the upward scan lands on the maximum.
        a_one, b_one, sfa_one, sfb_one, _, _ = self._make_smem_layouts(
            tile_shape_mnk,
            epi_tile,
            a_dtype,
            self.a_layout,
            b_dtype,
            self.b_layout,
            1,
            d_dtype,
            self.d_layout,
            epi_stage,
            res_stage,
            sf_vec_size=self.sf_vec_size,
            tiled_mma=self.tiled_mma,
            sf_tile_shape_mnk=self.sf_tile_shape_mnk,
        )
        slope = (
            cute.cosize(a_one) * a_dtype.width // 8
            + cute.cosize(b_one) * b_dtype.width // 8
            + cute.cosize(sfa_one) * sf_dtype.width // 8
            + cute.cosize(sfb_one) * sf_dtype.width // 8
            + 2 * 8  # two mainloop pipeline mbar (Int64) per stage
        )
        align_loss = 4 * buffer_align_bytes
        ab_stage = max(1, 1 + (smem_capacity - smem_bytes(1) - align_loss) // slope)
        while smem_bytes(ab_stage + 1) <= smem_capacity:
            ab_stage += 1
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
        res_stage: int,
        sf_vec_size: int,
        tiled_mma: cute.TiledMma,
        sf_tile_shape_mnk: tuple[int, int, int] = None,
    ) -> tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Create shared memory layouts for the A, B and D tensors.

        :param tile_shape_mnk: CTA tile shape (M,N,K). Sizes A/B/D/residual.
        :type tile_shape_mnk: Tuple[int, int, int]
        :param sf_tile_shape_mnk: CTA tile shape whose K sizes the SF SMEM. For
            MXFP8 the SF K tile (128) decouples from the A/B K tile (64); defaults
            to tile_shape_mnk when they match (NVFP4).
        :param epi_tile: Epilogue tile shape
        :type epi_tile: Tuple[int, int]
        :param a_dtype: Data type for matrix A
        :type a_dtype: type[cutlass.Numeric]
        :param a_layout: Layout for matrix A
        :type a_layout: Layout
        :param b_dtype: Data type for matrix B
        :type b_dtype: type[cutlass.Numeric]
        :param b_layout: Layout for matrix B
        :type b_layout: Layout
        :param ab_stage: Number of stages for A/B tensors
        :type ab_stage: int
        :param d_dtype: Data type for output matrix D
        :type d_dtype: type[cutlass.Numeric]
        :param d_layout: leading dimension of the output matrix D
        :type d_layout: Layout
        :param epi_stage: Number of epilogue stages
        :type epi_stage: int

        :return: Tuple of shared memory layouts for A, B and the epilogue
        :rtype: Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
        """
        if sf_tile_shape_mnk is None:
            sf_tile_shape_mnk = tile_shape_mnk

        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))

        a_is_k_major = a_layout.is_k_major_a()
        b_is_k_major = b_layout.is_k_major_b()
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]

        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                a_layout,
                a_dtype,
                a_major_mode_size,
            ),
            a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))

        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                b_layout,
                b_dtype,
                b_major_mode_size,
            ),
            b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        sfa_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfa(
            tiled_mma,
            sf_tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )

        sfb_smem_layout_staged = _sm120_make_smem_layout_sfb(
            tiled_mma,
            sf_tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )

        d_smem_shape = epi_tile
        d_major_mode_size = epi_tile[1] if d_layout.is_n_major_c() else epi_tile[0]
        d_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                d_layout,
                d_dtype,
                d_major_mode_size,
            ),
            d_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            d_smem_layout_atom,
            cute.append(d_smem_shape, epi_stage),
            order=(1, 0, 2) if d_layout.is_m_major_c() else (0, 1, 2),
        )
        # Residual staging layout: same per-subtile atom as the D store, sized by
        # res_stage. Single-buffered (res_stage=1) so it costs minimal smem and
        # leaves the A/B pipeline deep.
        res_smem_layout_staged = cute.tile_to_shape(
            d_smem_layout_atom,
            cute.append(d_smem_shape, res_stage),
            order=(1, 0, 2) if d_layout.is_m_major_c() else (0, 1, 2),
        )

        return (
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            epi_smem_layout_staged,
            res_smem_layout_staged,
        )

    @staticmethod
    def can_implement(
        tile_shape_mnk: Tuple[int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c: int,
        k: int,
        filter_trs: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dil_dhw: Tuple[int, int, int],
        upper_padding_dhw: Tuple[int, int, int],
        lower_padding_dhw: Tuple[int, int, int],
    ) -> None:
        """Rejects configurations this kernel cannot compile or would miscompute.

        Every constraint here is decidable from the tile shape, the input format
        and the channel counts, so it is checked before any compilation rather
        than surfacing as a deep layout error or a wrong result.

        :param tile_shape_mnk: CTA tile shape (M, N, K)
        :param ab_dtype: A/B element type
        :param sf_dtype: Scale-factor element type
        :param acc_dtype: Accumulator element type
        :param d_dtype: Output element type
        :param sf_vec_size: Channels one scale factor covers
        :param c: Input channel count
        :param k: Output channel count, which sets how many N tiles are needed
        :param filter_trs: Filter extents (T, R, S)
        :param stride_dhw: Convolution stride per spatial dimension
        :param dil_dhw: Dilation per spatial dimension
        :param upper_padding_dhw: Trailing padding per spatial dimension
        :param lower_padding_dhw: Leading padding per spatial dimension

        :raises testing.CantImplementError: If the configuration is unsupported
        """
        # Two validated input formats, each pinned to its scale-factor block size:
        #   NVFP4 : Float4E2M1FN A/B, sf_vec_size=16 (E4M3 scale).
        #   MXFP8 : Float8E4M3FN A/B, sf_vec_size=32 (E8M0 scale).
        is_mxfp8 = ab_dtype is cutlass.Float8E4M3FN
        if ab_dtype is cutlass.Float4E2M1FN:
            if sf_dtype is not cutlass.Float8E4M3FN or sf_vec_size != 16:
                raise testing.CantImplementError(
                    "Float4E2M1FN A/B requires sf_dtype=Float8E4M3FN and "
                    f"sf_vec_size=16, got sf_dtype={sf_dtype}, "
                    f"sf_vec_size={sf_vec_size}"
                )
        elif is_mxfp8:
            if sf_dtype is not cutlass.Float8E8M0FNU or sf_vec_size != 32:
                raise testing.CantImplementError(
                    "Float8E4M3FN A/B (MXFP8) requires sf_dtype=Float8E8M0FNU and "
                    f"sf_vec_size=32, got sf_dtype={sf_dtype}, "
                    f"sf_vec_size={sf_vec_size}"
                )
        else:
            raise testing.CantImplementError(
                f"This path supports Float4E2M1FN (NVFP4) and Float8E4M3FN (MXFP8) "
                f"A/B, got ab_dtype={ab_dtype}"
            )
        # tile_m must be exactly 128: the block-scaled SF SMEM layout tiles the M
        # extent in units of blk_mn=128 (one BlockScaledBasicChunk row), so a tile_m
        # that is not a whole number of chunks fails that layout's own assert.
        if tile_shape_mnk[0] != 128:
            raise testing.CantImplementError(
                f"tile_m must be 128 (the SF chunk's row count), got "
                f"{tile_shape_mnk[0]}"
            )
        # tile_k for NVFP4 is 64 or 128: the MMA fills K in 64-channel steps and the
        # SF SMEM layout needs a whole 4-block scale-factor atom (also 64 channels)
        # per K tile, so 64 is the floor and nothing between is expressible. Prefer
        # the value that equals C. 128 is the widest value tested.
        #
        # MXFP8 uses a 64 K tile so the fp8 A/B, at twice fp4's bytes per stage,
        # keeps a deep A/B pipeline in the smaller SM120 SMEM; its SF K tile stays
        # at one whole chunk of 4*vec32 = 128 channels, so one SF chunk serves two
        # A/B tiles.
        allowed_tile_k = (64,) if is_mxfp8 else (64, 128)
        allowed_tile_n = (64, 96, 128)
        if tile_shape_mnk[2] not in allowed_tile_k:
            raise testing.CantImplementError(
                f"tile_k must be one of {allowed_tile_k} for {ab_dtype}, got "
                f"{tile_shape_mnk[2]}"
            )
        # tile_n is bounded by the scale-factor chunk geometry. A chunk covers 128
        # output channels and is indivisible, and the SF layout a tile reads assumes
        # the tile starts on a chunk boundary. Values outside this set are each
        # ruled out for their own reason: a tile_n that is not a multiple of 32
        # misses the SF block granularity and would gain nothing anyway (the MMA
        # fills N in 32-wide units and rounds up); 32 has no ldmatrix partition for
        # the scale factors, which reach the MMA through ldmatrix; above 128 the N
        # basic block still describes only one chunk's four 32-row units, so the
        # layout stops covering the tile.
        tile_n = tile_shape_mnk[1]
        if tile_n not in allowed_tile_n:
            raise testing.CantImplementError(
                f"tile_n must be one of {allowed_tile_n} for {ab_dtype} (bounded by "
                f"the 128-channel SF chunk and its 32-row blocks), got {tile_n}"
            )
        # 64 and 128 divide a chunk, so every N tile sits inside one. 96 does not,
        # so only the first tile is chunk-aligned; it is restricted to problems that
        # need a single N tile, which is where it wins anyway by filling N exactly.
        n_tiles = (k + tile_n - 1) // tile_n
        if 128 % tile_n != 0 and n_tiles > 1:
            raise testing.CantImplementError(
                f"tile_n={tile_n} does not divide the 128-channel SF chunk, so only "
                f"the first N tile starts on a chunk boundary; it needs a single N "
                f"tile but K={k} needs {n_tiles}. Use tile_n=64 or 128."
            )
        # C neither has to fill the K tile nor be a whole number of scale-factor
        # atoms. A partial trailing K tile reads zero-filled A and B channels from
        # the TMA, whose global channel extent is C; SFA re-reads a chunk that is
        # already in bounds because the host rounds each pixel's row up to a whole
        # atom and zero-fills the tail; and SFB is addressed per filter position at
        # a span padded to whole K tiles. So the tail contributes nothing.
        #
        # One bound survives: the 16-byte alignment the TMA needs on a contiguous
        # axis. C is the contiguous axis of A and B, so a pixel's row -- C elements
        # of ab_dtype -- is the stride of the axis next to it, and the descriptor
        # requires that stride to be a multiple of 16 bytes (C % 32 == 0 for FP4,
        # C % 16 == 0 for FP8). K is the contiguous axis of D and carries the same
        # requirement against the output element type.
        _check_tensor_alignment(c, k, ab_dtype, d_dtype)
        # A tighter bound on C than that alignment: it must be a whole number of
        # scale-factor atoms, 4 * sf_vec_size channels. SFA's 4-byte cp.async carries
        # exactly one atom and walks a row stride of C / sf_vec_size factors, which
        # this keeps a multiple of the 4 the transfer needs. A C that splits an atom
        # would leave that stride unaligned, and padding the host allocation to hide
        # it would put the factors a position owns at an offset the kernel does not
        # address.
        sf_atom_channels = sf_vec_size * 4
        if c % sf_atom_channels != 0:
            raise testing.CantImplementError(
                f"{ab_dtype} requires C to be a multiple of {sf_atom_channels}, "
                f"got C = {c}."
            )
        # The block-scaled MMA accumulates in FP32 only -- its op rejects any other
        # accumulator type when it is built, past the point a host check can name the
        # problem.
        if acc_dtype is not cutlass.Float32:
            raise testing.CantImplementError(
                f"acc_dtype must be Float32, got {acc_dtype}"
            )
        # D is a 16-bit float. The epilogue converts the accumulator straight to D,
        # and a sub-byte output would additionally need its own scale-factor tensor
        # quantized from that accumulator, which nothing here emits.
        allowed_d_dtype = {cutlass.BFloat16, cutlass.Float16}
        if d_dtype not in allowed_d_dtype:
            raise testing.CantImplementError(
                f"D must be BFloat16 or Float16, got d_dtype={d_dtype}"
            )
        _check_im2col_descriptor_limits(
            filter_trs, stride_dhw, dil_dhw, upper_padding_dhw, lower_padding_dhw
        )


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


def _sm120_make_smem_layout_sfb(
    tiled_mma: cute.TiledMma,
    tile_shape_mnk: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
) -> cute.Layout:
    """
    Make smem layout for SFB based on:
    1. BlockScaledBasicChunk
    2. MMA tiler shape
    3. Scale factor vector size
    4. Number of stages

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param tile_shape_mnk: The mma tiler shape
    :type tile_shape_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFB
    :rtype: cute.Layout
    """

    # A single indivisible block will hold 4 scale factors of 128 rows/columns (A/B matrix).
    # 4 is chosen to make consecutive 32bits of data to have scale factors for only a single row(col).
    blk_mn = 128
    blk_sf = 4
    blk_elems = blk_mn * blk_sf

    assert sf_vec_size == 16 or sf_vec_size == 32, "sf_vec_size must be 16 or 32"
    assert isinstance(tile_shape_mnk, tuple)

    # Below a chunk the layout describes that chunk's leading tile_n columns, so
    # tile_n only has to land on the 32-row basic block. At or above a chunk the N
    # mode still spans exactly blk_sf blocks, so a tile_n that is not a whole number
    # of chunks would leave the layout covering fewer columns than the tile.
    assert tile_shape_mnk[1] % 32 == 0 and (
        tile_shape_mnk[1] < blk_mn or tile_shape_mnk[1] % blk_mn == 0
    ), (
        "tile_shape_mnk[1] must be a multiple of the 32-row SF basic block, and "
        f"either below blk_mn={blk_mn} or a whole number of chunks"
    )

    assert tile_shape_mnk[2] % sf_vec_size == 0, (
        "tile_shape_mnk[2] must be divisible by sf_vec_size"
    )

    mma_nsf = tiled_mma.shape_mnk[2] // sf_vec_size

    # A chunk holds blk_mn=128 columns and is indivisible in SMEM, so a tile_n
    # narrower than a chunk describes the leading tile_n columns of one chunk:
    # the N atom shrinks to (32, tile_n/32) while every stride, including the
    # K-mode chunk stride, still steps over whole chunks.
    n_chunks = max(1, tile_shape_mnk[1] // blk_mn)
    n_atom_blocks = min(blk_sf, tile_shape_mnk[1] // 32)

    mn_basic_block_shape = (32, n_atom_blocks)
    mn_basic_block_stride = (16, 4)
    k_basic_block_shape = (sf_vec_size, mma_nsf)
    k_basic_block_stride = (0, 1)

    sSFA_shapeN = (mn_basic_block_shape, n_chunks)
    sSF_strideN = (mn_basic_block_stride, blk_elems)

    assert tile_shape_mnk[2] % (blk_sf * mma_nsf) == 0, (
        "tile_shape_mnk[2] must be divisible by blk_sf * mma_nsf"
    )

    sSFA_shapeK = (
        k_basic_block_shape,
        blk_sf // mma_nsf,
        tile_shape_mnk[2] // sf_vec_size // blk_sf,
    )
    sSF_strideK = (
        k_basic_block_stride,
        mma_nsf,
        n_chunks * blk_elems,
    )

    sSFA_shape = (sSFA_shapeN, sSFA_shapeK)
    sSFA_stride = (sSF_strideN, sSF_strideK)

    smem_layout = cute.make_layout(sSFA_shape, stride=sSFA_stride)

    # A stage always spans whole chunks, so its stride comes from the chunk
    # count rather than the layout's cosize: a tile_n narrower than a chunk
    # addresses only part of the chunk it sits in, and a cosize would place the
    # next stage inside that same chunk.
    k_chunks = tile_shape_mnk[2] // sf_vec_size // blk_sf
    stage_stride = n_chunks * blk_elems * k_chunks

    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K, STAGE)
    sfb_smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(num_stages, stride=stage_stride),
    )

    return sfb_smem_layout_staged


def sf_k_tile_channels(cta_tile_k: int, sf_vec_size: int) -> int:
    """Channels one SF K tile spans.

    The SF SMEM atom holds 4 scale-factor blocks along K, so it covers
    4 * sf_vec_size channels and cannot be staged in part. A narrower A/B K tile
    therefore still stages a whole atom, and several A/B tiles then share one SF
    tile. Both the kernel and the host derive the SF cadence from here so they
    cannot drift apart.
    """
    return max(cta_tile_k, 4 * sf_vec_size)


def sfb_per_position_channels(c: int, cta_tile_k: int, sf_vec_size: int) -> int:
    """Channels of SFB one filter position spans: C rounded up to whole SF K tiles.

    SFB runs channels and filter positions together in one flat K mode, so a K tile
    that does not divide C would straddle two positions; rounding each position out
    to whole SF K tiles puts every position on a tile boundary, which keeps a tile
    inside one position and lets the consumer address it by its flat index. The
    bound is the SF tile, the width of the TMA box: a C that a 64-channel A/B tile
    divides still straddles two positions once a 128-channel SF chunk serves two of
    those tiles.

    The padded channels pair with the B channels past C, which the TMA zero-fills,
    so their scale factors never reach the result.

    The kernel derives the same span from its runtime channel count, so the padding
    never reaches the compiled code.
    """
    span = sf_k_tile_channels(cta_tile_k, sf_vec_size)
    return -(-c // span) * span


def create_scale_factor_tensor_swizzled(
    l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
) -> Tuple[torch.Tensor, cute.Tensor, torch.Tensor]:
    """SFB gmem tensor in the swizzled BlockScaledBasicChunk MMA layout (TMA
    load). Returns (f32 reference in MKL layout, cute tensor, backing storage)."""

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

    ref_f32_cpu = cutlass_torch.create_and_permute_torch_tensor(
        ref_shape,
        torch.float32,
        permute_order=ref_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
    )
    cute_f32_cpu = cutlass_torch.create_and_permute_torch_tensor(
        mma_shape,
        torch.float32,
        permute_order=mma_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=0, max_val=1),
    )

    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        from_dlpack(ref_f32_cpu),
        from_dlpack(cute_f32_cpu),
    )

    ref_f32_cpu = (
        ref_f32_cpu.permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(*ref_permute_order)
    )
    ref_f32_cpu = ref_f32_cpu[:, :k, :]
    # Round-trip the reference scale factors through the storage dtype so the
    # reference dequant uses the exact values the kernel reads. E8M0 (MXFP8)
    # snaps every scale to a power of two, so an un-rounded f32 reference would
    # disagree with the kernel on every non-pow2 block.
    ref_f32_cpu = ref_f32_cpu.to(cutlass_torch.dtype(dtype)).to(torch.float32)

    cute_f32 = cute_f32_cpu.cuda()

    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        cute_f32_cpu,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    cute_tensor = cutlass_torch.convert_cute_tensor(
        cute_f32,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
    )
    return ref_f32_cpu, cute_tensor, torch_tensor


def create_scale_factor_tensor_unswizzled(
    l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
) -> Tuple[torch.Tensor, cute.Tensor, torch.Tensor]:
    """SFA gmem tensor in natural (M, ceil(C/vec), L) unswizzled layout consumed
    by the hand-written cp.async producer (the gather-XOR-swizzle theorem
    forbids a TMA for SFA). Returns (f32 reference in MKL layout, cute tensor,
    backing storage)."""

    def ceil_div(a, b):
        return (a + b - 1) // b

    # The M-direction stride is sf_k and the 4-byte cp.async that walks it needs a
    # multiple of 4 factors. k is C here, which can_implement already requires to be
    # a whole number of scale-factor atoms, so the allocation carries no tail: the
    # caller's buffer is exactly the factors the problem owns.
    sf_k = ceil_div(k, sf_vec_size)

    sf_raw = torch.randint(1, 3, (mn, sf_k, l), dtype=torch.uint8, device="cpu")
    torch_tensor = sf_raw.to(dtype=cutlass_torch.dtype(dtype)).cuda()

    cute_tensor = from_dlpack(torch_tensor, assumed_align=16)
    cute_tensor.element_type = dtype
    # Mark the SFA gmem tensor layout dynamic (leading dim = the C/SF axis) so
    # its stride lowers to runtime SSA. Without it the static stride is baked
    # into the cubin, tying the compiled kernel to one C (the device reads mSFA
    # with this stride).
    cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=1)

    ref_f32_cpu = (
        sf_raw[:, :sf_k, :]
        .float()
        .permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(1, 2, 0)
    )
    ref_f32_cpu = ref_f32_cpu[:, :k, :]

    return ref_f32_cpu, cute_tensor, torch_tensor


# Compile-time epilogue activations, folded into the cubin as a Constexpr op
# (one activation per cubin). Each entry pairs the device-side op applied to the
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


def compile_conv(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    zpq: Tuple[int, int, int],
    input_: cute.Tensor,
    filter_: cute.Tensor,
    output_: cute.Tensor,
    sfa_: cute.Tensor,
    sfb_: cute.Tensor,
    bias_: Optional[cute.Tensor],
    residual_: Optional[cute.Tensor],
    alpha_: cutlass.Float32,
    beta: float,
    acc_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    tile_shape_mnk: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    upper_pad_dhw: Tuple[int, int, int],
    lower_pad_dhw: Tuple[int, int, int],
    dil_dhw: Tuple[int, int, int],
    epilogue_op: cutlass.Constexpr = lambda x: x,
    allow_hardware_query_failure: bool = False,
):
    """Build the kernel object, resolve host launch config, and cute.compile it.

    Returns the compiled callable. Pad/stride/dilation and filter T/R/S are boxed
    as cutlass.Int32 so the compiled entry scalars lower to runtime SSA (one cubin
    serves any of those values); the caller re-boxes them at launch time. The stream a
    compilation is handed never runs anything, so it is a fake one; the caller passes
    the real stream when it launches.
    """
    from cutlass.cute.runtime import make_fake_stream

    _, t, r, s = ktrs

    conv = Sm120BlockScaledPersistentDenseImplicitGemmFpropKernel(
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
    )
    hardware_info = cutlass.utils.HardwareInfo()
    try:
        max_active_clusters = hardware_info.get_max_active_clusters(1)
    except Exception:
        if not allow_hardware_query_failure:
            raise
        max_active_clusters = 1
    stream = make_fake_stream()

    compile_opts_parts = []
    dump_dir = os.environ.get("CUTE_DSL_DUMP_DIR")
    if dump_dir:
        compile_opts_parts.extend(
            [f"--dump-dir={dump_dir}", "--keep-cubin", "--keep-ptx"]
        )
    ptx_version = os.environ.get("CUTE_DSL_PTX_VERSION")
    if ptx_version:
        if ptx_version.isdigit():
            ptx_version = f"+ptx{ptx_version}"
        compile_opts_parts.append(f"--ptx-version={ptx_version}")
    compile_opts = " ".join(compile_opts_parts)

    rt_conv_params = (
        *_rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        cutlass.Int32(t),
        cutlass.Int32(r),
        cutlass.Int32(s),
    )

    return cute.compile(
        conv,
        input_,
        filter_,
        sfa_,
        sfb_,
        output_,
        bias_,
        residual_,
        alpha_,
        beta,
        *rt_conv_params,
        max_active_clusters,
        stream,
        epilogue_op,
        no_cache=True,
        **({"options": compile_opts} if compile_opts else {}),
    )


def run_conv(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    tile_shape_mnk: Tuple[int, int, int],
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    activation: str = "identity",
    use_bias: bool = False,
    alpha: float = 1.0,
    beta: float = 0.0,
):
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example")

    n, c, d, h, w = ncdhw
    k, t, r, s = ktrs
    # Reject malformed geometry before compute_zpq(), which floor-divides by each
    # stride: a zero stride would raise ZeroDivisionError, and a negative stride or
    # dilation would silently feed invalid extents into the host reference and the
    # device address reconstruction. Turn both into a clear ValueError up front.
    for name, values in {
        "stride_dhw": stride_dhw,
        "upper_pad_dhw": upper_pad_dhw,
        "lower_pad_dhw": lower_pad_dhw,
        "dil_dhw": dil_dhw,
    }.items():
        if len(values) != 3:
            raise ValueError(f"{name} must contain exactly 3 values, got {values}")
    if any(v <= 0 for v in stride_dhw):
        raise ValueError(
            f"stride_dhw must contain only positive values, got {stride_dhw}"
        )
    if any(v <= 0 for v in dil_dhw):
        raise ValueError(f"dil_dhw must contain only positive values, got {dil_dhw}")
    if t <= 0 or r <= 0 or s <= 0:
        raise ValueError(f"TRS must be positive, got {(t, r, s)}")
    Sm120BlockScaledPersistentDenseImplicitGemmFpropKernel.can_implement(
        tile_shape_mnk,
        ab_dtype,
        sf_dtype,
        acc_dtype,
        d_dtype,
        sf_vec_size,
        c,
        k,
        (t, r, s),
        stride_dhw,
        dil_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
    )

    z, p, q = compute_zpq(
        (d, h, w), (t, r, s), stride_dhw, upper_pad_dhw, lower_pad_dhw, dil_dhw
    )
    if z <= 0 or p <= 0 or q <= 0:
        raise ValueError(f"Invalid output spatial shape: {(z, p, q)}")

    gemm_m = n * z * p * q
    gemm_n = k
    gemm_k = c * t * r * s
    print("Running Blackwell Geforce SM120 NVFP4 fprop with:")
    print(f"ncdhw: {ncdhw}, ktrs: {ktrs}, zpq: {(z, p, q)}")
    print(f"implicit GEMM mnk: {(gemm_m, gemm_n, gemm_k)}")
    print(
        f"A/B dtype: {ab_dtype}, SF dtype: {sf_dtype}, D dtype: {d_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Tile Shape: {tile_shape_mnk}")
    print(f"Skip reference checking: {skip_ref_check}")

    # Resolve the compile-time epilogue activation. The device op is folded into
    # the cubin as a Constexpr; the reference op mirrors it on the host.
    if activation not in EPILOGUE_ACTIVATIONS:
        raise ValueError(
            f"Unsupported activation {activation!r}; "
            f"choose from {sorted(EPILOGUE_ACTIVATIONS)}"
        )
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    input_tensor, filter_tensor, output_tensor = prepare_tensors(ncdhw, ktrs, (z, p, q))
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)

    sfa_ref, sfa_tensor, sfa_storage = create_scale_factor_tensor_unswizzled(
        1, n * d * h * w, c, sf_vec_size, sf_dtype
    )
    # SFB is allocated with every filter position padded out to a whole number of SF
    # K tiles, the same span the kernel derives at runtime, so every position starts
    # on a tile boundary and no K tile addresses past the one it belongs to. The
    # padded channels pair with the B channels past C, which the TMA zero-fills, so
    # their scale factors never reach the result and only have to be finite.
    sfb_c_span = sfb_per_position_channels(c, tile_shape_mnk[2], sf_vec_size)
    sfb_ref, sfb_tensor, sfb_storage = create_scale_factor_tensor_swizzled(
        1, gemm_n, sfb_c_span * t * r * s, sf_vec_size, sf_dtype
    )

    # Per-output-channel bias (length gemm_n = K), dtype matches the output.
    # Added to the accumulator in FP32 as D = act(alpha*acc + bias), broadcast
    # across every spatial output position.
    if use_bias:
        bias_storage = torch.randn(gemm_n, dtype=torch.float32, device="cuda").to(
            cutlass_torch.dtype(d_dtype)
        )
        bias_ = from_dlpack(bias_storage, assumed_align=16)
    else:
        bias_storage, bias_ = None, None

    # Per-tensor alpha as an FP32 runtime scalar (D = act(alpha*acc + bias +
    # beta*residual)). Boxed once and passed at both cute.compile and every
    # launch so one cubin serves any alpha value.
    alpha_ = cutlass.Float32(alpha)

    # Residual (C): a per-element (N,Z,P,Q,K) tensor sharing the output's
    # shape/layout/dtype, added in FP32 as beta*residual. beta is a compile-time
    # constant, so beta == 0 needs no tensor and compiles the path away.
    has_residual = beta != 0.0
    if has_residual:
        residual_f32 = torch.randn((n, z, p, q, k), dtype=torch.float32, device="cuda")
        residual_, residual_storage = create_cute_tensor(
            residual_f32, d_dtype, leading_dim=4
        )
    else:
        residual_, residual_storage, residual_f32 = None, None, None

    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)
    # Box pad/stride/dilation and filter T/R/S as cutlass.Int32 so the launch
    # scalars lower to runtime SSA: one cubin serves any pad/stride/dilation/
    # T/R/S. Order must match the __call__ signature (compile_conv boxes the
    # same values independently for the cute.compile entry).
    rt_conv_params = (
        *_rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        cutlass.Int32(t),
        cutlass.Int32(r),
        cutlass.Int32(s),
    )

    compiled_conv = compile_conv(
        ncdhw,
        ktrs,
        (z, p, q),
        input_,
        filter_,
        output_,
        sfa_tensor,
        sfb_tensor,
        bias_,
        residual_,
        alpha_,
        beta,
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
        stride_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
        dil_dhw,
        epilogue_op=epilogue_op,
        allow_hardware_query_failure=skip_ref_check,
    )
    print("Compiled conv kernel.", flush=True)

    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_conv(
        input_,
        filter_,
        sfa_tensor,
        sfb_tensor,
        output_,
        bias_,
        residual_,
        alpha_,
        *rt_conv_params,
        current_stream,
    )
    torch_stream.synchronize()

    if not skip_ref_check:
        sfa_expanded = sfa_ref.squeeze(-1).reshape(n, d, h, w, c).cuda()
        sfb_expanded = (
            sfb_ref.squeeze(-1).reshape(k, t, r, s, sfb_c_span)[..., :c].cuda()
        )
        scaled_input = input_tensor.float() * sfa_expanded
        scaled_filter = filter_tensor.float() * sfb_expanded
        scaled_input_ncdhw = scaled_input.permute(0, 4, 1, 2, 3).contiguous()
        scaled_filter_kctrs = scaled_filter.permute(0, 4, 1, 2, 3).contiguous()
        if upper_pad_dhw == lower_pad_dhw:
            ref_nkzpq = F.conv3d(
                scaled_input_ncdhw,
                scaled_filter_kctrs,
                padding=upper_pad_dhw,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
        else:
            padded = F.pad(
                scaled_input_ncdhw,
                (
                    lower_pad_dhw[2],
                    upper_pad_dhw[2],
                    lower_pad_dhw[1],
                    upper_pad_dhw[1],
                    lower_pad_dhw[0],
                    upper_pad_dhw[0],
                ),
            )
            ref_nkzpq = F.conv3d(
                padded,
                scaled_filter_kctrs,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
        ref = ref_nkzpq.permute(0, 2, 3, 4, 1).contiguous()
        # Scale the accumulator by alpha in FP32, then add the per-output-channel
        # bias before the activation, matching the device epilogue
        # (D = act(alpha*acc + bias)). bias_storage holds the exact d_dtype values
        # the kernel loads, so float() reproduces them bit-for-bit.
        ref = alpha * ref
        if use_bias:
            ref = ref + bias_storage.float().reshape(1, 1, 1, 1, gemm_n).cuda()
        # Add the per-element residual in FP32 before the activation, matching the
        # device epilogue (D = act(alpha*acc + bias + beta*residual)).
        # residual_storage holds the exact d_dtype values the kernel loads, so
        # float() reproduces them bit-for-bit.
        if has_residual:
            ref = ref + beta * residual_storage.float().reshape(n, z, p, q, k).cuda()
        # Mirror the device epilogue activation folded into the kernel.
        ref = EPILOGUE_ACTIVATIONS[activation]["ref"](ref)

        d_ref_device = torch.empty((n, z, p, q, k), dtype=torch.float32, device="cuda")
        cute.testing.convert(
            output_,
            from_dlpack(d_ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=4
            ),
        )
        d_result = d_ref_device.cpu()
        torch.testing.assert_close(d_result, ref.cpu(), atol=tolerance, rtol=1e-2)
        print("Reference check passed.")

    def generate_tensors():
        # Only A/B/D rotate per cold-L2 workspace; the SF tensors, alpha, bias,
        # and residual are reused from the outer scope (small / not perf-relevant
        # to rotate), matching the golden benchmark.
        input_tensor, filter_tensor, output_tensor = prepare_tensors(
            ncdhw, ktrs, (z, p, q)
        )
        input_, input_ws = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
        filter_, filter_ws = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
        output_, output_ws = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
        jit_args = testing.JitArguments(
            input_,
            filter_,
            sfa_tensor,
            sfb_tensor,
            output_,
            bias_,
            residual_,
            alpha_,
            *rt_conv_params,
            current_stream,
        )
        # A from_dlpack tensor keeps its backing torch storage alive through the
        # DLPack capsule it holds, so this pin is redundant; it stays as an
        # explicit statement of the workspace's intended lifetime.
        references = [input_ws, filter_ws, output_ws]
        jit_args.add_to_scope(references)
        # The workspace initializes on other streams; drain them so the
        # benchmark stream never reads a tensor mid-initialization.
        torch.cuda.synchronize()
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            input_storage.numel() * input_storage.element_size()
            + filter_storage.numel() * filter_storage.element_size()
            + output_storage.numel() * output_storage.element_size()
            + sfa_storage.numel() * sfa_storage.element_size()
            + sfb_storage.numel() * sfb_storage.element_size()
        )
        # beta*residual is output-sized, so leaving it out shrinks the workspace
        # ring below the real working set and lets L2 stay warm -- an optimistic
        # cold-L2 measurement. bias is a small K vector but counted for symmetry.
        if bias_storage is not None:
            one_workspace_bytes += bias_storage.numel() * bias_storage.element_size()
        if residual_storage is not None:
            one_workspace_bytes += (
                residual_storage.numel() * residual_storage.element_size()
            )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    if iterations > 0:
        exec_time = testing.benchmark(
            compiled_conv,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=True,
        )
        gflop = 2 * gemm_m * gemm_n * gemm_k / 1e9
        gflops = gflop / exec_time * 1e6
        print(f"Execution time: {exec_time} microseconds per iteration")
        print(f"GFLOPS: {gflops}")
        return exec_time
    return 0


def run(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    ab_dtype: Type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: Type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = 16,
    d_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    tile_shape_mnk: Tuple[int, int, int] = (128, 128, 128),
    tolerance: float = 1e-1,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    activation: str = "identity",
    use_bias: bool = False,
    alpha: float = 1.0,
    beta: float = 0.0,
    **kwargs,
):
    return run_conv(
        ncdhw,
        ktrs,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        d_dtype,
        acc_dtype,
        tile_shape_mnk,
        tolerance,
        warmup_iterations,
        iterations,
        skip_ref_check,
        use_cold_l2,
        stride_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
        dil_dhw,
        activation,
        use_bias,
        alpha,
        beta,
    )


def parse_conv_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="SM120 NVFP4 static-specialized TRS fprop"
    )
    parser.add_argument(
        "--ncdhw", type=_parse_comma_separated_ints, default=(1, 128, 3, 3, 130)
    )
    parser.add_argument(
        "--ktrs", type=_parse_comma_separated_ints, default=(128, 3, 3, 3)
    )
    parser.add_argument(
        "--stride_dhw", type=_parse_comma_separated_ints, default=(1, 1, 1)
    )
    parser.add_argument(
        "--upper_pad_dhw", type=_parse_comma_separated_ints, default=(1, 1, 1)
    )
    parser.add_argument(
        "--lower_pad_dhw", type=_parse_comma_separated_ints, default=(1, 1, 1)
    )
    parser.add_argument(
        "--dil_dhw", type=_parse_comma_separated_ints, default=(1, 1, 1)
    )
    parser.add_argument(
        "--tile_shape_mnk",
        type=_parse_comma_separated_ints,
        choices=[
            (128, 128, 128),
            (128, 96, 128),
            (128, 64, 128),
            (128, 128, 64),
            (128, 96, 64),
            (128, 64, 64),
        ],
        default=(128, 128, 128),
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--sf_vec_size", type=int, choices=[16, 32], default=16)
    parser.add_argument("--d_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--tolerance", type=float, default=1e-1)
    parser.add_argument("--warmup_iterations", type=int, default=0)
    parser.add_argument("--iterations", type=int, default=1)
    parser.add_argument("--skip_ref_check", action="store_true", default=False)
    parser.add_argument("--use_cold_l2", action="store_true", default=False)
    parser.add_argument(
        "--activation",
        type=str,
        default="identity",
        choices=sorted(EPILOGUE_ACTIVATIONS),
        help="Compile-time epilogue activation applied as D = activation(acc). "
        "One activation per cubin.",
    )
    parser.add_argument("--use_bias", action="store_true", default=False)
    parser.add_argument(
        "--alpha",
        type=float,
        default=1.0,
        help="Per-tensor accumulator scale (D = act(alpha*acc + bias + "
        "beta*residual)). Runtime scalar: one cubin serves any value.",
    )
    parser.add_argument(
        "--beta",
        type=float,
        default=0.0,
        help="Residual scaling (D = act(alpha*acc + bias + beta*residual)); "
        "beta == 0 disables residual, beta != 0 enables it. Compile-time "
        "constant: one cubin per beta value.",
    )
    args = parser.parse_args()
    if len(args.ncdhw) != 5:
        parser.error("--ncdhw must contain exactly 5 values")
    if len(args.ktrs) != 4:
        parser.error("--ktrs must contain exactly 4 values")
    return args


if __name__ == "__main__":
    args = parse_conv_arguments()
    run(
        args.ncdhw,
        args.ktrs,
        args.stride_dhw,
        args.upper_pad_dhw,
        args.lower_pad_dhw,
        args.dil_dhw,
        args.ab_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.d_dtype,
        args.acc_dtype,
        args.tile_shape_mnk,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        activation=args.activation,
        use_bias=args.use_bias,
        alpha=args.alpha,
        beta=args.beta,
    )
    print("PASS")
