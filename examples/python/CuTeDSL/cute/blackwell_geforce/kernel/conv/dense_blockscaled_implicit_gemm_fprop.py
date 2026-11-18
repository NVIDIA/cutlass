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
    create_scale_factor_tensor_swizzled,
    create_scale_factor_tensor_unswizzled,
    frontend_cache_token,
    make_fake_conv_tensor,
    parse_comma_separated_ints,
    prepare_fprop_tensors,
    rt_conv_scalars,
    sf_k_tile_channels,
    sfb_per_position_channels,
    solve_max_smem_stages,
    trace_conv_scalars,
)
from cutlass.memory import SmemAllocator, get_smem_capacity_in_bytes
from cutlass.tensor_utils import LayoutEnum

if __name__ == "__main__":
    # Sibling kernel modules are imported through their arch package root.
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from blackwell_geforce.kernel.blockscaled_gemm.blockscaled_gemm_dispatch import (
    make_ldmatrix_atom,
    make_sm120_blockscaled_mma_op,
)

"""
A high-performance 3D implicit-GEMM based block-scaled fprop convolution example for the
NVIDIA Blackwell Geforce
(SM120) architecture using CUTE DSL.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor D is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Operand loads: the input tensor A by Tensor Memory Access (TMA) im2col, which
      performs the
      im2col transformation on the fly; the filter tensor B and its scale factor SFB by
      TMA tiled;
      the input scale factor SFA by cp.async
    - Utilizes warp block-scaled MMA for matrix multiply-accumulate (MMA) operations: A
      and B are NVFP4 or MXFP8
      and carry per-block scale factors (SFA, SFB), read from shared memory through
      ldmatrix
    - Supports multi-stage pipeline to overlap computation and memory access
    - Ping-pong MMA warpgroups with parity-based tile ownership; a 256-wide N tile
      selects a cooperative tactic
      whose two warpgroups each compute one 128-wide output-channel half and share each
      A/SFA stage
    - CLC-based dynamic persistent tile scheduling
    - Fused epilogue computing in FP32, D = activation(alpha * acc + bias + beta *
      residual),
      with an optional per-output-channel bias, an optional residual (fused when beta !=
      0)
      and a compile-time activation

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

    python examples/CuTeDSL/cute/blackwell_geforce/kernel/conv/dense_blockscaled_implicit_gemm_fprop.py \
      --ncdhw 1,128,3,3,130 --ktrs 128,3,3,3                           \
      --ab_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
      --d_dtype Float16 --tile_shape_mnk 128,128,128                   \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                      \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/CuTeDSL/cute/blackwell_geforce/kernel/conv/dense_blockscaled_implicit_gemm_fprop.py \
      --ncdhw 1,128,3,3,130 --ktrs 128,3,3,3                           \
      --ab_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
      --d_dtype Float16 --tile_shape_mnk 128,128,128                   \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                      \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1                               \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* A/B data type is Float4E2M1FN (NVFP4) or Float8E4M3FN (MXFP8). Each pins its
  scale-factor format: NVFP4 takes a Float8E4M3FN scale over 16 channels, MXFP8 a
  Float8E8M0FNU scale over 32.
* A/B tensor must have the same data type
* Accumulator data type is Float32
* Output data type is BFloat16 or Float16; the output carries no scale factor
* CTA tile shape M must be 128, the row count of one scale-factor chunk
* CTA tile shape N must be 64, 96 or 128. 96 does not divide the 128-channel
  scale-factor
  chunk, so it serves problems needing a single N tile
* CTA tile shape (128, 256, 128) selects the cooperative tactic: NVFP4 only, K % 256 ==
  0
  or K % 256 > 128, and no residual
* CTA tile shape K must be 64 or 128 for NVFP4 and 64 for MXFP8. It need not divide the
  input channel count C, which only has to be a whole number of scale-factor atoms
  (4 * sf_vec_size channels)
* The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 8, 16, and 32 for Float16/BFloat16,
  Float8E4M3FN, and Float4E2M1FN, respectively.
* The bias, when supplied, is a length-K tensor of a 16- or 32-bit float type.
* The residual, when fused, has the shape, layout and data type of D.
"""


#
# Helpers to parse args
#


#
# Host setup and device kernel launch
#


class Sm120BlockScaledDenseImplicitGemmFpropKernel:
    """
    Persistent block-scaled 3D convolution kernel.
    The input (A) is expected to be in 5D tensor (NDHWC) format and is loaded via the
    TMA im2col load atom.
    The filter (B) is expected to be in 5D tensor (KTRSC) format and is loaded via the
    TMA tiled load atom.
    The filter scale factor (SFB) is loaded via the TMA tiled load atom, and the input
    scale factor (SFA) via cp.async.
    The output (D) is expected to be in 5D tensor (NZPQK) format and is stored via the
    im2col TMA store.
    The optional residual (C) has D's format and is loaded via the TMA im2col load atom.
    The implicit GEMM runs on ping-pong MMA warpgroups with parity-based tile ownership,
    scheduled by a CLC-based dynamic persistent tile scheduler; a (128, 256, 128) CTA
    tile selects a cooperative tactic whose two warpgroups each compute one 128-wide
    output-channel half.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param sf_vec_size: Channels one scale factor covers, 16 for NVFP4 and 32 for MXFP8
    :type sf_vec_size: int
    :param tile_shape_mnk: CTA tile shape (M, N, K); (128, 256, 128) selects the
        cooperative tactic
    :type tile_shape_mnk: Tuple[int, int, int]

    :note: The convolution geometry (filter T/R/S, padding, stride, dilation) is not a
        constructor parameter: T/R/S come from the filter tensor extents and
        pad/stride/dilation arrive as runtime Int32 operands to __call__, so a single
        compiled cubin serves any geometry.

    :note: In current version, A and B tensor must be C major. D tensor must be K major.

    :note: Supported A/B data types, which A and B share:
        - Float4E2M1FN (NVFP4), scaled by a Float8E4M3FN factor over 16 channels
        - Float8E4M3FN (MXFP8), scaled by a Float8E8M0FNU factor over 32 channels

    :note: The accumulator is Float32.

    :note: Supported D data types:
        - Float16/BFloat16, which carry no scale factor

    :note: Constraints:
        - CTA tile shape M must be 128, the row count of one scale-factor chunk
        - CTA tile shape N must be 64, 96 or 128; 96 does not divide the 128-channel
          scale-factor chunk, so it serves problems needing a single N tile
        - CTA tile shape (128, 256, 128) selects the cooperative tactic: NVFP4 only,
          K % 256 == 0 or K % 256 > 128, and no residual
        - CTA tile shape K must be 64 or 128 for NVFP4 and 64 for MXFP8
        - C must be a whole number of scale-factor atoms, 4 * sf_vec_size channels
        - The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
          i.e, number of elements is a multiple of 8, 16, and 32 for Float16/BFloat16,
          Float8E4M3FN, and Float4E2M1FN, respectively
        - The bias, when supplied, is a length-K tensor of a 16- or 32-bit float type
        - The residual C, when fused (beta != 0), has D's shape, layout and data type

    **Example:**

    .. code-block:: python
        conv = Sm120BlockScaledDenseImplicitGemmFpropKernel(
            acc_dtype=cutlass.Float32,
            sf_vec_size=16,
            tile_shape_mnk=(128, 128, 128),
        )
        conv(
            a, b, sfa, sfb, d,
            bias,  # optional length-K bias tensor, or None
            c,  # optional residual tensor with D's shape, or None
            alpha,  # FP32 runtime accumulator scale
            beta,  # compile-time residual scale; 0.0 compiles the residual away
            upper_pad_d, upper_pad_h, upper_pad_w,
            lower_pad_d, lower_pad_h, lower_pad_w,
            stride_d, stride_h, stride_w,
            dil_d, dil_h, dil_w,
            max_active_clusters,
            stream,
            epilogue_op,
        )
    """

    # Fixed for every configuration: the tiled MMA's warp layout and the
    # single-CTA cluster.
    atom_layout = (2, 2, 1)
    cluster_shape_mnk = (1, 1, 1)

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        tile_shape_mnk: Tuple[int, int, int],
    ):
        # Exactly the (128, 256, 128) tile selects the cooperative tactic: the
        # CTA tile splits into two adjacent 128-wide halves, one per math
        # warpgroup. Every attribute below works on the per-warpgroup half; only
        # the scheduler grid is computed on the full CTA tile.
        self.n_tiles_per_work = 2 if tile_shape_mnk == (128, 256, 128) else 1
        tile_shape_mnk = (
            tile_shape_mnk[0],
            tile_shape_mnk[1] // self.n_tiles_per_work,
            tile_shape_mnk[2],
        )
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
        self.sf_vec_size = sf_vec_size

        # Override the warp specialization: SFA is not a regular TMA box (a K tile
        # reads a different pixel per filter position), so it gets its own 4-warp
        # cp.async group right after the MMA warps. The TMA load, CLC scheduler and
        # residual G2S warps share the round-up warpgroup, so residual costs no
        # extra warps or registers.
        self.sfa_cpasync_warp_group_start = self.num_mma_warps
        self.sfa_cpasync_warp_group_size = 4
        self.tma_load_warp_id = (
            self.sfa_cpasync_warp_group_start + self.sfa_cpasync_warp_group_size
        )
        self.sched_warp_id = self.tma_load_warp_id + 1
        self.residual_tma_warp_id = self.sched_warp_id + 1
        # Second mainloop TMA load warp: the warpgroup round-up leaves one
        # warp with no role, so the k tiles are split between two issuers
        # by parity.
        self.tma_load_warp_2_id = self.residual_tma_warp_id + 1
        self.threads_per_cta = (
            self.num_mma_warps
            + self.sfa_cpasync_warp_group_size  # SFA cp.async DMA warp group
            + 1  # dedicated TMA load warp
            + self.num_sched_warps  # CLC scheduler warp
        ) * self.num_threads_per_warp

        # epi_tile is chosen in _setup_attributes once has_residual is known: a
        # residual epilogue needs a separate sC staging buffer, so it uses a
        # subtiled epi_tile to keep the epilogue smem (sD + sC) small enough
        # to preserve the A/B pipeline depth; without a residual the full (128,128)
        # epi_tile stores D in a single subtile and leaves the deepest A/B pipeline.
        self.epi_tile = None

        # The CLC scheduler warp plus the round-up unused warps form a whole extra
        # warpgroup whose only real work is the lightweight CLC producer loop; give
        # it the register-realloc floor so the freed budget goes to the MMA
        # warpgroups. Its value is shared by the scheduler and unused branches since
        # they belong to the same warpgroup.
        self.sched_register_requirement = 24
        self.mma_register_requirement = 224

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
        # The SF SMEM atom (BlockScaledBasicChunk) is indivisible along N: one
        # chunk spans blk_mn=128 output channels, so a tile_n below 128
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

        tC = cute.make_layout(self.atom_layout)
        permutation_mnk = sm120_utils.get_permutation_mnk(
            self.tile_shape_mnk, self.sf_vec_size, use_mxf8f6f4
        )
        self.tiled_mma = cute.make_tiled_mma(
            mma_op,
            tC,
            permutation_mnk=permutation_mnk,
        )

        # Scale factors are staged in chunks of 4 blocks along K, i.e. 4 * sf_vec_size
        # channels, and a chunk is never split. MXFP8 (vec 32): a chunk is 128 channels
        # but a K tile is 64, so one chunk is shared by 2 K tiles and each reads its
        # half via sf_base. NVFP4 (vec 16): a chunk is 64 channels, which every K tile
        # (64 or 128) covers, so ab_k_tiles_per_sf_k_tile is 1.
        self.sf_tile_k = sf_k_tile_channels(self.tile_shape_mnk[2], self.sf_vec_size)
        self.ab_k_tiles_per_sf_k_tile = self.sf_tile_k // self.tile_shape_mnk[2]
        # The SF tile takes the rounded-up N from above and the K cadence from here,
        # so a narrow tile_n stages a whole chunk and MXFP8 stages one
        # whole chunk along K.
        self.sf_tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.sf_tile_n,
            self.sf_tile_k,
        )

        # --- Epilogue tile ---
        # Pick the epilogue tile from whether a residual is fused: sC doubles the
        # epilogue smem, so the residual path takes a subtiled epi_tile to keep
        # sD + sC within the A/B pipeline's depth.
        epi_m, epi_n = (64, 64) if self.has_residual else (128, 128)
        # Clamp the subtile to the CTA tile, then halve epi_n until it divides tile_n.
        # A partial last subtile would be stored but not counted by the rest of the
        # epilogue, so the store would read past the accumulator. Example: with a
        # residual and tile_n=96, epi_n=64 leaves 32 over, so epi_n becomes 32.
        epi_m = min(epi_m, self.tile_shape_mnk[0])
        epi_n = min(epi_n, self.tile_shape_mnk[1])
        while self.tile_shape_mnk[1] % epi_n != 0:
            epi_n //= 2
        self.epi_tile = (epi_m, epi_n)

        # --- Pipeline stages and smem layouts ---
        # D gets one smem buffer per epilogue subtile, at most 4. C gets one: the
        # epilogue copies it to registers and frees it at once, so the residual warp
        # can load the next subtile. Whatever smem is left goes to A/B stages.
        num_d_stage_max = (self.tile_shape_mnk[1] // self.epi_tile[1]) * (
            self.tile_shape_mnk[0] // self.epi_tile[0]
        )
        self.num_d_stage = min(num_d_stage_max, 4)
        self.num_c_stage = 1
        self._solve_smem_stages(
            Sm120BlockScaledDenseImplicitGemmFpropKernel._make_shared_storage
        )

        assert self.num_d_stage > 0, (
            "num_d_stage <= 0, no enough shared memory. This case will be skipped."
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
            self.c_smem_layout_staged,
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
            self.num_c_stage,
            self.sf_vec_size,
            self.tiled_mma,
            self.sf_tile_shape_mnk,
            self.n_tiles_per_work,
        )

        # MMA-side view of the staged SFB chunk. The TMA stages whole 128-wide
        # chunks, but the mma only consumes the live tile_n columns, so the
        # consumer reads the same SMEM through a tile_n-wide layout whose modes
        # then match the B fragment's. Only N narrows: K stays on the SF cadence,
        # which is one whole chunk and can be wider than the A/B K tile.
        self.sfb_mma_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfb(
            self.tiled_mma,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[1], self.sf_tile_k),
            self.sf_vec_size,
            self.num_ab_stage * self.n_tiles_per_work,
        )

        # --- TMA transaction bytes ---
        # Compute the TMA transaction bytes of one A/B stage: one A tile, and a B and
        # an SFB tile per N tile of the work item
        if cutlass.const_expr(cute.rank(self.a_smem_layout_staged) == 4):
            a_smem_layout = cute.slice_(
                self.a_smem_layout_staged, (None, None, None, 0)
            )
        else:
            a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, 0))
        if cutlass.const_expr(cute.rank(self.b_smem_layout_staged) == 4):
            b_smem_layout = cute.slice_(
                self.b_smem_layout_staged, (None, None, None, 0)
            )
        else:
            b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, 0))
        sfb_smem_layout = cute.slice_(self.sfb_smem_layout_staged, (None, None, 0))
        self.num_tma_load_bytes = cute.size_in_bytes(
            self.a_dtype, a_smem_layout
        ) + self.n_tiles_per_work * (
            cute.size_in_bytes(self.b_dtype, b_smem_layout)
            + cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        )

        # --- Cluster layouts ---
        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

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
        self,
        a,
        b,
        d,
        c,
        sfb,
        rt_upper_pad_dhw,
        rt_lower_pad_dhw,
        rt_stride_dhw,
        rt_dil_dhw,
    ):
        """Set up TMA atoms and tensors for im2col convolution.

        Creates the A, B and D atoms, the SFB atom, and, when a residual is fused,
        the C atom.

        The pad / stride / dilation operands feed the im2col A descriptor corners.
        They arrive as runtime cutlass.Int32, which the rt_ prefix marks, so one
        compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param c: Residual tensor C - (N, Z, P, Q, K) layout, or None
        :param sfb: Block scale factor tensor for B
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)
        :returns: (tma_atom_a, tma_tensor_a, tma_atom_b, tma_tensor_b,
                tma_atom_d, tma_tensor_d, tma_atom_c, tma_tensor_c,
                tma_atom_sfb, tma_tensor_sfb)
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

        # Residual im2col G2S load, built on the output's ((Q,P,Z,N), K) GEMM view
        # and epilogue smem layout. Load mode needs the full im2col corner set, and
        # the residual is a 1x1x1 identity tap, so every corner and pad is 0.
        if cutlass.const_expr(self.has_residual):
            mC = cute.make_tensor(
                c.iterator, cute.select(c.layout, mode=[3, 2, 1, 0, 4])
            )
            mC = cute.group_modes(mC, begin=0, end=4)
            epi_smem_layout = cute.slice_(self.epi_smem_layout_staged, (None, None, 0))
            tma_atom_c, tma_tensor_c = cpasync.make_im2col_tma_atom(
                cpasync.CopyBulkTensorIm2ColG2SOp(),
                mC,
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
            tma_tensor_c = cute.coalesce(tma_tensor_c, target_profile=(1, 1))
            tma_tensor_c = add_dummy_batch_dimension(tma_tensor_c)
        else:
            tma_atom_c, tma_tensor_c = None, None

        tma_atom_sfb, tma_tensor_sfb = self._make_sfb_tiled_tma_atom(sfb, b)

        return (
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
            tma_atom_c,
            tma_tensor_c,
            tma_atom_sfb,
            tma_tensor_sfb,
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

        # Build the im2col TMA atom over the rank-2 SMEM layout.
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

    def _make_sfb_tiled_tma_atom(
        self, sfb: cute.Tensor, b: cute.Tensor
    ) -> Tuple[cute.CopyAtom, cute.Tensor]:
        """Make SFB's tiled TMA load atom.

        SFB is viewed in B's GEMM shape, output channels by GEMM-K, in the
        scale-factor atom layout.

        :param sfb: Block scale factor tensor for B
        :param b: Filter tensor B - (K, T, R, S, C) layout

        :return: (tma_atom_sfb, tma_tensor_sfb)
        """
        # Fill the B tensor out to the scale-factor atom layout:
        # ((Atom_N, Rest_N),(Atom_K, Rest_K),RestL). The channel extent is the span
        # SFB was allocated at, not C: the host pads each filter position to whole SF
        # K tiles, which puts every position on a tile boundary so a K tile stays
        # inside one position and the consumer can address it by its flat index.
        sfb_c_span = cute.ceil_div(b.shape[4], self.sf_tile_k) * self.sf_tile_k
        sfb_shape = (
            b.shape[0],
            sfb_c_span * b.shape[1] * b.shape[2] * b.shape[3],
            1,
        )
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            sfb_shape, self.sf_vec_size
        )
        sfb = cute.make_tensor(sfb.iterator, sfb_layout)

        return self._make_tma_atoms_and_tensors(
            sfb,
            self.sfb_smem_layout_staged,
            (self.sf_tile_shape_mnk[1], self.sf_tile_shape_mnk[2]),
            1,
            internal_type=cutlass.Int16,
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
        num_c_stage: int,
        sf_vec_size: int,
        tiled_mma: cute.TiledMma,
        sf_tile_shape_mnk: tuple[int, int, int] = None,
        n_tiles_per_work: int = 1,
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
        :param num_ab_stage: Number of stages for A/B tensors
        :type num_ab_stage: int
        :param d_dtype: Data type for output matrix D
        :type d_dtype: type[cutlass.Numeric]
        :param d_layout: leading dimension of the output matrix D
        :type d_layout: Layout
        :param num_d_stage: Number of epilogue stages
        :type num_d_stage: int
        :param n_tiles_per_work: Number of adjacent N tiles assigned to one
            scheduler work item. Two duplicates B/SFB stages while sharing A/SFA.
        :type n_tiles_per_work: int

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
            cute.append(a_smem_shape, num_ab_stage),
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
            cute.append(b_smem_shape, num_ab_stage * n_tiles_per_work),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        sfa_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfa(
            tiled_mma,
            sf_tile_shape_mnk,
            sf_vec_size,
            num_ab_stage,
        )

        sfb_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfb(
            tiled_mma,
            sf_tile_shape_mnk,
            sf_vec_size,
            num_ab_stage * n_tiles_per_work,
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
            cute.append(d_smem_shape, num_d_stage),
            order=(1, 0, 2) if d_layout.is_m_major_c() else (0, 1, 2),
        )
        # Residual staging layout: same per-subtile atom as the D store, sized by
        # num_c_stage. Single-buffered (num_c_stage=1) so it costs minimal smem and
        # leaves the A/B pipeline deep.
        c_smem_layout_staged = cute.tile_to_shape(
            d_smem_layout_atom,
            cute.append(d_smem_shape, num_c_stage),
            order=(1, 0, 2) if d_layout.is_m_major_c() else (0, 1, 2),
        )

        return (
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            epi_smem_layout_staged,
            c_smem_layout_staged,
        )

    def _make_shared_storage(self, *, num_ab_stage: int):
        """Complete shared-memory layout for one candidate A/B stage count.

        Stage selection sizes candidates through it and the device entry allocates
        through it. Every shared-memory consumer of this kernel is a field here, in
        three runs: pipeline barriers, small odds and ends, then the tensor buffers.
        """
        (
            a_smem,
            b_smem,
            sfa_smem,
            sfb_smem,
            epi_smem,
            c_smem,
        ) = self._make_smem_layouts(
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
            self.num_c_stage,
            self.sf_vec_size,
            self.tiled_mma,
            self.sf_tile_shape_mnk,
            self.n_tiles_per_work,
        )
        num_clc_stage = self.num_clc_stage
        num_bias_stage = self.num_bias_stage
        num_c_stage = self.num_c_stage
        has_bias = self.has_bias
        bias_dtype = self.bias_dtype if self.has_bias else self.d_dtype
        has_residual = self.has_residual
        cta_n = self.tile_shape_mnk[1]
        n_tiles_per_work = self.n_tiles_per_work
        a_dtype = self.a_dtype
        b_dtype = self.b_dtype
        sf_dtype = self.sf_dtype
        d_dtype = self.d_dtype
        align = SMEM_BUFFER_ALIGN_BYTES

        @cute.struct
        class SharedStorage:
            # Pipeline barriers, in construction order.
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, num_ab_stage * 2
            ]
            # The two math warpgroups order themselves through a depth-2
            # PipelineOrder (a turn before the mainloop in ping-pong mode, and a
            # turn before the epilogue in both modes), so the array holds 2 * 2
            # mbarriers.
            math_wg_order_barrier_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
            # PipelineTmaAsync mbarriers for the residual G2S load (full+empty per
            # stage). Sized by num_c_stage. Zero when beta == 0.
            c_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, num_c_stage * 2 if has_residual else 0
            ]
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
                cute.struct.MemRange[d_dtype, cute.cosize(epi_smem)], align
            ]
            # Ring of logical-work-tile bias rows: the TMA load warp stages each
            # tile's row and the owning math warpgroup reads it back, with a paired
            # work tile holding one cta_tile_n row per warpgroup in the same stage.
            # Zero length when no bias is supplied so it costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[
                    bias_dtype,
                    num_bias_stage * cta_n * n_tiles_per_work if has_bias else 0,
                ],
                SMEM_VECTOR_ALIGN_BYTES,
            ]
            # Residual staging: same per-subtile atom as sD, single-buffered
            # (num_c_stage=1) so it costs minimal smem and leaves the A/B pipeline
            # deep. The S2R read lines up with the acc fragment per subtile. Zero
            # length (no smem) when beta == 0.
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    d_dtype, cute.cosize(c_smem) if has_residual else 0
                ],
                align,
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[a_dtype, cute.cosize(a_smem)], align
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[b_dtype, cute.cosize(b_smem)], align
            ]
            sSFA: cute.struct.Align[
                cute.struct.MemRange[sf_dtype, cute.cosize(sfa_smem)], align
            ]
            sSFB: cute.struct.Align[
                cute.struct.MemRange[sf_dtype, cute.cosize(sfb_smem)], align
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

    # Stage one k tile of SFA, deriving the im2col coordinates from the geometry on
    # every call (the MXFP8 path). The walk is self-contained per k tile, so no
    # coordinate state stays live across iterations and register pressure stays low.
    @cute.jit
    def sfa_cpasync_copy_tile_from_coords(
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
    ) -> None:
        """Issue this k tile's SFA cp.async transfers into the staged smem tile.

        :param mSFA_mkl: The global SFA tensor
        :param sSFA: The staged SFA smem tensor
        :param tile_coord_mnl: This CTA's output tile coordinate
        :param sf_stage: The pipeline stage to write
        :param sfa_c_tile_idx: Channel-tile index within the filter position
        :param s_coord: Filter S coordinate of this k tile
        :param r_coord: Filter R coordinate of this k tile
        :param t_coord: Filter T coordinate of this k tile
        :param tidx: This thread's index within the CTA
        :param input_N: Batch extent of the input
        :param input_C: Channel count of the input
        :param input_D: Depth extent of the input
        :param input_H: Height extent of the input
        :param input_W: Width extent of the input
        :param output_Z: Depth extent of the output
        :param output_P: Height extent of the output
        :param output_Q: Width extent of the output
        :param rt_stride_d: Convolution stride along D
        :param rt_stride_h: Convolution stride along H
        :param rt_stride_w: Convolution stride along W
        :param rt_lower_pad_d: Leading padding along D
        :param rt_lower_pad_h: Leading padding along H
        :param rt_lower_pad_w: Leading padding along W
        :param rt_dil_d: Dilation along D
        :param rt_dil_h: Dilation along H
        :param rt_dil_w: Dilation along W
        """
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
        # Each lane loads one full SF K tile, the span the SMEM chunk atom holds.
        # When that tile covers several A/B K tiles they share a filter position, so
        # their scale factors are contiguous in gmem and one tile fills them all;
        # the consumer offsets into the live A/B-tile half via sf_base.
        sf_k_per_ktile = self.sf_tile_k // self.sf_vec_size
        # A chunk holds blk_sf consecutive scale factors, contiguous in both the
        # unswizzled source and the SMEM atom, so each chunk is a single 4-byte
        # cp.async. Consecutive chunks sit a K basic-block stride apart in SMEM, so
        # one copy is issued per chunk and the count follows sf_vec_size.
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
        # wider than C has trailing chunks with no backing storage. They pair with
        # A channels the TMA zero-fills, but must still name an in-bounds address and
        # land a finite value, since the MMA applies the scale before it can see the
        # operand is zero. Re-reading the pixel's first chunk gives both.
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

    # Stage one k tile of SFA from a gmem row offset and predicate the caller keeps
    # on per-tile state (the NVFP4 path). A lane's M token decomposition is
    # loop-invariant, so its divides run once per output tile and only the finished
    # offset and predicate are read every iteration.
    @cute.jit
    def sfa_cpasync_copy_tile_precomputed(
        self,
        mSFA_mkl: cute.Tensor,
        sSFA: cute.Tensor,
        sf_stage,
        sfa_c_tile_idx,
        sfa_row_off: cutlass.Int32,
        sfa_pred_val: cutlass.Boolean,
        tidx,
        input_C: cutlass.Int32,
    ) -> None:
        """Issue this k tile's SFA cp.async transfers into the staged smem tile.

        :param mSFA_mkl: The global SFA tensor
        :param sSFA: The staged SFA smem tensor
        :param sf_stage: The pipeline stage to write
        :param sfa_c_tile_idx: Channel-tile index within the filter position
        :param sfa_row_off: Gmem row offset of this lane's pixel, 0 when predicated off
        :param sfa_pred_val: Whether this lane's pixel is in bounds
        :param tidx: This thread's index within the CTA
        :param input_C: Channel count of the input
        """
        sfa_atom_copy = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            mSFA_mkl.element_type,
            num_bits_per_copy=32,
        )
        # The whole DMA warp group cooperates on the SFA copy: each lane owns one M
        # token of the tile and loads its scale factors as chunked 4-byte cp.async
        # copies. The caller hands each lane its gmem row offset and predicate,
        # maintained as running deltas over the filter walk.
        local_tid = tidx % 128
        sfa_predicate_tensor = cute.make_rmem_tensor(
            cute.make_layout((1,)),
            cutlass.Boolean,
        )
        sfa_predicate_tensor[0] = sfa_pred_val
        # Each lane loads one full SF K tile, the span the SMEM chunk atom holds.
        # When that tile covers several A/B K tiles they share a filter position, so
        # their scale factors are contiguous in gmem and one tile fills them all;
        # the consumer offsets into the live A/B-tile half via sf_base.
        sf_k_per_ktile = self.sf_tile_k // self.sf_vec_size
        # A chunk holds blk_sf consecutive scale factors, contiguous in both the
        # unswizzled source and the SMEM atom, so each chunk is a single 4-byte
        # cp.async. Consecutive chunks sit a K basic-block stride apart in SMEM, so
        # one copy is issued per chunk and the count follows sf_vec_size.
        sf_blk = 4
        sf_chunk_cnt = sf_k_per_ktile // sf_blk
        sf_k_base = (sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile) * sf_k_per_ktile

        # SMEM M coordinate is the 2-level ((32, 4)) mode; the global token of a
        # lane is (inner + 32 * outer) == local_tid, matching the layout that the
        # SM120 math path reads back.
        sf_m_inner = local_tid % 32
        sf_m_outer = local_tid // 32

        # A pixel owns only ceil(C / sf_vec_size) real scale factors, so a K tile
        # wider than C has trailing chunks with no backing storage. They pair with
        # A channels the TMA zero-fills, but must still name an in-bounds address and
        # land a finite value, since the MMA applies the scale before it can see the
        # operand is zero. Re-reading the pixel's first chunk gives both.
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

    def epilog_smem_store_copy_and_partition(
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

        # Allocate the epilogue's working registers. The epilogue arithmetic runs
        # in FP32, so they carry FP32 and the narrowing to the output type happens
        # in one step at the end.
        rD_shape = cute.shape(thr_copy_r2s.partition_S(sD))
        tRS_rD_layout = cute.make_layout(rD_shape[:3])
        tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, cutlass.Float32)
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
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        d: cute.Tensor,
        bias: Optional[cute.Tensor],
        c: Optional[cute.Tensor],
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
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ) -> None:
        """Execute fprop using the SM120 block-scaled GEMM mainloop.

        alpha is an FP32 runtime scalar applied to the accumulator before bias
        as D = act(alpha * acc + bias + beta * residual). It is passed at both
        cute.compile and the runtime launch, so its value stays out of the
        mangled name and one cubin serves any alpha.

        beta is a compile-time Constexpr, so beta == 0 folds the entire residual
        path (dedicated load warp, smem staging, TMA, add) away via DCE and
        beta != 0 compiles it in. A separate cubin is emitted per beta value; the
        residual tensor shares the output's shape/layout/dtype.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry. The same values feed both
        the host im2col A descriptor corner and the device SFA cp.async coord
        reconstruction, keeping A's load coords and SFA's in lockstep.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param sfa: Block scale factor tensor for A
        :param sfb: Block scale factor tensor for B, same element type as sfa
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param bias: Optional length-K per-output-channel bias tensor; None skips the
            bias path
        :param c: Optional per-element residual tensor sharing the output's
            shape, layout and dtype
        :param alpha: FP32 runtime scalar applied to the accumulator
        :param beta: Compile-time residual scale
        :param rt_upper_pad_d/h/w: Upper padding (D, H, W)
        :param rt_lower_pad_d/h/w: Lower padding (D, H, W)
        :param rt_stride_d/h/w: Convolution stride (D, H, W)
        :param rt_dil_d/h/w: Dilation (D, H, W)
        :param max_active_clusters: Host-resolved cluster count for the persistent grid
        :param stream: CUDA stream for asynchronous execution
        :param epilogue_op: Optional elementwise lambda function to apply to the output
            tensor
        """

        # Validate and set input-dependent attributes
        self._setup_conv_input_attrs(a, b, d)
        self.sf_dtype = sfa.element_type

        # Bias opt-in: caller supplies a length-K (output-channel) tensor. has_bias
        # is a compile-time branch, so no-bias compiles the bias path away.
        self.has_bias: bool = bias is not None
        self.bias_dtype: Optional[Type[cutlass.Numeric]] = (
            bias.element_type if bias is not None else None
        )

        # Residual opt-in: gated by the compile-time beta. beta == 0 compiles the
        # whole residual path away; beta != 0 requires a residual tensor sharing
        # the output's shape/layout/dtype (it is TMA-loaded through the output's
        # own store descriptor, run in reverse as a G2S load).
        self.beta = beta
        self.has_residual: bool = beta != 0.0

        self._setup_attributes()

        # Filter T/R/S come from the filter tensor b (K, T, R, S, C) as runtime Int32,
        # so one compiled cubin serves any T/R/S. A runtime extent also cannot be
        # proven == 1 at compile time, so the B im2col K layout keeps all four modes
        # (c,s,r,t) and both operands walk K at rank 4.
        rt_filter_trs = (b.shape[1], b.shape[2], b.shape[3])
        rt_upper_pad_dhw = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        rt_lower_pad_dhw = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        rt_stride_dhw = (rt_stride_d, rt_stride_h, rt_stride_w)
        rt_dil_dhw = (rt_dil_d, rt_dil_h, rt_dil_w)

        (
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_d,
            tma_tensor_d,
            tma_atom_c,
            tma_tensor_c,
            tma_atom_sfb,
            tma_tensor_sfb,
        ) = self._setup_conv_tma(
            a,
            b,
            d,
            c,
            sfb,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        scheduler_tile_shape_mnk = (
            self.tile_shape_mnk[0],
            self.tile_shape_mnk[1] * self.n_tiles_per_work,
            self.tile_shape_mnk[2],
        )
        # SM120 launches one-CTA clusters without swizzle.
        tile_sched_params, grid = compute_grid(
            tma_tensor_d, scheduler_tile_shape_mnk, (1, 1), 1, "m"
        )

        self.threads_per_cta = (self.threads_per_cta + 127) // 128 * 128

        # Per-output-channel bias broadcast to the output's ((Q,P,Z,N), K, 1) profile:
        # real stride 1 along the output channel (GEMM-N), stride 0 across every
        # spatial position, so the epilogue reads it through the accumulator's
        # partition_C chain. The static M extent keeps the smem-read layout static for
        # a vectorized load; the runtime N stride serves any output-channel count.
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

        self.shared_storage = (
            Sm120BlockScaledDenseImplicitGemmFpropKernel._make_shared_storage(
                self, num_ab_stage=self.num_ab_stage
            )
        )

        self.kernel(
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            # SFA is an unswizzled input-activation scale tensor in
            # (N*D*H*W, ceil(C / sf_vec_size), 1). The async-copy producer maps each
            # output tile and TRS coordinate back to this input-space tensor before
            # writing the SM120 SFA SMEM layout consumed by the MMA math path.
            sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_d,
            tma_tensor_d,
            mBias_mnl,
            tma_atom_c,
            tma_tensor_c,
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
            self.c_smem_layout_staged,
            tile_sched_params,
            cute.size(a, mode=[0]),
            cute.size(a, mode=[1]),
            cute.size(a, mode=[2]),
            cute.size(a, mode=[3]),
            cute.size(a, mode=[4]),
            cute.size(d, mode=[1]),
            cute.size(d, mode=[2]),
            cute.size(d, mode=[3]),
            rt_filter_trs[0],
            rt_filter_trs[1],
            rt_filter_trs[2],
            rt_lower_pad_dhw[0],
            rt_lower_pad_dhw[1],
            rt_lower_pad_dhw[2],
            rt_stride_dhw[0],
            rt_stride_dhw[1],
            rt_stride_dhw[2],
            rt_dil_dhw[0],
            rt_dil_dhw[1],
            rt_dil_dhw[2],
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
        mBias_mnl: Optional[cute.Tensor],
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: Optional[cute.Tensor],
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
        c_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        input_N: cutlass.Int32,
        input_D: cutlass.Int32,
        input_H: cutlass.Int32,
        input_W: cutlass.Int32,
        input_C: cutlass.Int32,
        output_Z: cutlass.Int32,
        output_P: cutlass.Int32,
        output_Q: cutlass.Int32,
        rt_filter_t: cutlass.Int32,
        rt_filter_r: cutlass.Int32,
        rt_filter_s: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
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
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_sfb)
            cpasync.prefetch_descriptor(tma_atom_d)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

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

        # One cp.async mbarrier arrive from each SFA lane (the copy spans the whole
        # DMA warp group) plus one elected arrive from each of the two TMA load warps.
        # Both TMA warps arrive on every stage even though only the k-tile's owner
        # issues the copies, which keeps the two warps on the same lap of the ring.
        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            self.sfa_cpasync_warp_group_size * self.num_threads_per_warp + 2,
        )
        mainloop_consumer_warps = self.num_mma_warps // 2
        if cutlass.const_expr(self.n_tiles_per_work == 2):
            mainloop_consumer_warps = self.num_mma_warps
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, mainloop_consumer_warps
        )

        cta_layout_vmnk = cute.make_layout((1, *cta_layout_mnk.shape))
        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self.num_ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            barrier_storage=mainloop_pipeline_array_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
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

        # Residual G2S load pipeline. The dedicated residual warp issues the TMA load
        # into sC; the owning math warpgroup consumes it (one full-barrier wait per
        # epilogue). Under ping-pong only one warpgroup consumes a given tile, so the
        # consumer count is a single warpgroup. Gated on has_residual.
        if cutlass.const_expr(self.has_residual):
            c_pipeline_array_ptr = storage.c_pipeline_array_ptr.data_ptr()
            c_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
            c_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mma_warps // 2,
            )
            c_pipeline = pipeline.PipelineTmaAsync.create(
                num_stages=self.num_c_stage,
                producer_group=c_producer_group,
                consumer_group=c_consumer_group,
                tx_count=cute.size_in_bytes(
                    self.d_dtype,
                    cute.slice_(c_smem_layout_staged, (None, None, 0)),
                ),
                barrier_storage=c_pipeline_array_ptr,
                cta_layout_vmnk=cta_layout_vmnk,
            )
        else:
            c_pipeline = None

        # Bias staging pipeline: a stage holds every bias row in the logical work
        # tile. In paired mode both math warpgroups read and release the stage.
        if cutlass.const_expr(mBias_mnl is not None):
            bias_pipeline = pipeline.PipelineCpAsync.create(
                num_stages=self.num_bias_stage,
                producer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread, self.num_threads_per_warp
                ),
                consumer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread, 128 * self.n_tiles_per_work
                ),
                barrier_storage=storage.bias_pipeline_array_ptr.data_ptr(),
                defer_sync=True,
            )
        else:
            bias_pipeline = None

        # CLC (Cluster Launch Control) pipeline. The scheduler warp is the sole
        # producer; the consumers are every math lane, the SFA cp.async DMA warp
        # group, both mainloop TMA load warps, and the scheduler warp itself
        # (self-consume for exit detection). Both math warpgroups peek every tile and
        # a parity counter decides which owns it, so the count spans all math warps.
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
                + 1  # second TMA load warp, also a tile-stream consumer
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

        #
        # Generate smem tensor A/B
        #
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
            sC = storage.sC.get_tensor(
                c_smem_layout_staged.outer, swizzle=c_smem_layout_staged.inner
            )
        else:
            sC = None
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)
        # Same SMEM as sSFB, viewed tile_n wide for the mma consumers.
        sSFB_mma = storage.sSFB.get_tensor(sfb_mma_layout_staged)
        # (logical_tile_n, STAGE) bias ring. Paired mode places the two adjacent
        # cta_tile_n rows contiguously in each stage.
        if cutlass.const_expr(mBias_mnl is not None):
            cta_n = self.tile_shape_mnk[1]
            logical_cta_n = cta_n * self.n_tiles_per_work
            sBias = storage.sBias.get_tensor(
                cute.make_layout(
                    (logical_cta_n, self.num_bias_stage), stride=(1, logical_cta_n)
                )
            )
        else:
            sBias = None

        #
        # Local_tile partition global tensors
        #
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
            gC_mnl = cute.local_tile(
                mC_mnl,
                cute.slice_(self.tile_shape_mnk, (None, None, 0)),
                (None, None, None),
            )
        else:
            gC_mnl = None
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
        # Bias: same partition_C chain as the accumulator, so the fragment read back
        # from smem lines up element-for-element with the acc fragment. The M-axis
        # stride-0 broadcast in mBias_mnl means each thread reads only its own N
        # column. The row is staged into this warpgroup's private sBias via cp.async.
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
            pipeline.PipelineUserType.Producer, self.num_ab_stage
        )
        mainloop_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_ab_stage
        )

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_clc_stage
        )

        # Residual G2S consumer state. Both math warpgroups advance it in phase:
        # the owner consumes+releases each subtile it reads, the non-owner skips
        # its tile by advancing the same number of subtile stages the residual
        # warp produced for it, so the ring counter stays aligned across tiles.
        if cutlass.const_expr(self.has_residual):
            c_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_c_stage
            )

        # Bias ring consumer state, advanced the same way: the TMA load warp
        # produces one stage per tile, so the non-owner advances past a skipped
        # tile's stage to keep the ring counter aligned with its next owned tile.
        if cutlass.const_expr(self.has_bias):
            bias_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_bias_stage
            )

        # SFA cp.async warp group: its lanes issue the SFA copies only
        if (
            warp_idx >= self.sfa_cpasync_warp_group_start
            and warp_idx < self.tma_load_warp_id
        ):
            cute.arch.setmaxregister_decrease(self.load_register_requirement)
            # The SFA warp group cooperatively issues the cp.async copy (one M token per
            # lane), waiting on the empty barrier and arriving on the full barrier via
            # the cp.async mbarrier path. The scalar coordinate walk is deterministic,
            # so every SFA warp runs it redundantly and stays in sync. NVFP4 hoists its
            # loop-invariant per-tile state; MXFP8 stays self-contained per k tile.
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
                    # far below 32k and the pads below 32), so they are packed
                    # into one value; the carry rebuild recovers them with
                    # arithmetic shifts.
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

                    # Count down so the loop carries only the remaining
                    # iteration count across the barrier wait below.
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
                        self.sfa_cpasync_copy_tile_precomputed(
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
                        self.sfa_cpasync_copy_tile_from_coords(
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
        # The two mainloop TMA load warps, which live in the CLC warpgroup
        elif warp_idx == self.tma_load_warp_id or warp_idx == self.tma_load_warp_2_id:
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
            # Which k tiles this warp issues. Both warps walk every tile so
            # their pipeline state and K coordinates stay in step; only the
            # owner of a tile sets that tile's transaction barrier and issues
            # its copies.
            producer_parity = cutlass.Int32(0)
            if warp_idx == self.tma_load_warp_2_id:
                producer_parity = cutlass.Int32(1)
            # These two warps are the only issuers of the A/B/SFB TMA loads. A
            # stage's owner sets its transaction barrier; both warps arrive on it,
            # and the SFA warpgroup contributes the cp.async arrives to the same
            # full barrier. Both walk the tile stream as CLC consumers.
            if cutlass.const_expr(mBias_mnl is not None):
                bias_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_bias_stage
                )
            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                tAgA_mkl = tAgA[(None, tile_coord_mnl[0], None, tile_coord_mnl[2])]
                n_tile_0 = tile_coord_mnl[1] * self.n_tiles_per_work
                tBgB_nkl_0 = tBgB[(None, n_tile_0, None, tile_coord_mnl[2])]
                # gSFB is tiled by the 128-wide SF chunk, so when tile_n is
                # narrower than a chunk several B N tiles map onto the same SF
                # tile and the SF N coordinate scales down accordingly.
                sf_n_coord_0 = n_tile_0 // self.n_tiles_per_sf_n_tile
                tBgSFB_nkl_0 = tBgSFB[(None, sf_n_coord_0, None, tile_coord_mnl[2])]
                if cutlass.const_expr(self.n_tiles_per_work == 2):
                    n_tile_1 = n_tile_0 + 1
                    tBgB_nkl_1 = tBgB[(None, n_tile_1, None, tile_coord_mnl[2])]
                    sf_n_coord_1 = n_tile_1 // self.n_tiles_per_sf_n_tile
                    tBgSFB_nkl_1 = tBgSFB[(None, sf_n_coord_1, None, tile_coord_mnl[2])]

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
                # SFB's per-position base, carried alongside the filter
                # counters. The walk visits filter positions in the same
                # S->R->T order SFB is laid out in, so the base advances by
                # one position's span whenever the channel counter carries and
                # returns to zero when the position odometer wraps.
                sfb_pos_base = cutlass.Int32(0)

                for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                    # Wait for the A/B/SFA buffers to be empty before writing.
                    mainloop_pipeline.sync_object_empty.wait(
                        mainloop_producer_state.index, mainloop_producer_state.phase
                    )
                    if k_tile % 2 == producer_parity:
                        # Set the transaction barrier for the A/B/SFB buffers, then
                        # issue the TMA loads.
                        mainloop_pipeline.sync_object_full.arrive(
                            mainloop_producer_state.index,
                            mainloop_pipeline.producer_mask,
                        )

                        tAgA_k = tAgA_mkl[(None, coord_iter)]
                        tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]

                        # After local_tile splits the channel into K-tiles, B's im2col
                        # view is (c_tile, (s, r, t)): the channel tile is a top-level
                        # mode and S/R/T a nested group. Runtime C and T/R/S extents
                        # cannot be proven == 1, so all four modes are always present.
                        tBgB_k_0 = tBgB_nkl_0[
                            (
                                None,
                                (
                                    sfa_c_tile_idx,
                                    sfa_s_idx,
                                    sfa_r_idx,
                                    sfa_t_idx,
                                ),
                            )
                        ]
                        tBsB_pipe_0 = tBsB[(None, mainloop_producer_state.index)]

                        # SFB's K mode is flat: one filter position's channels, then
                        # the next, in the S->R->T order the operands traverse. The
                        # span padding puts each position on a tile boundary, so the
                        # carried base names its first tile. The channel tile runs on
                        # the coarser SF cadence; the consumer reads its live part.
                        tBgSFB_k_0 = tBgSFB_nkl_0[
                            (
                                None,
                                sfb_pos_base
                                + sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile,
                            )
                        ]
                        tBsSFB_pipe_0 = tBsSFB[(None, mainloop_producer_state.index)]

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
                            tBgB_k_0,
                            tBsB_pipe_0,
                            tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                mainloop_producer_state
                            ),
                        )
                        cute.copy(
                            tma_atom_sfb,
                            tBgSFB_k_0,
                            tBsSFB_pipe_0,
                            tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                mainloop_producer_state
                            ),
                        )
                        if cutlass.const_expr(self.n_tiles_per_work == 2):
                            b_stage_1 = (
                                mainloop_producer_state.index + self.num_ab_stage
                            )
                            tBgB_k_1 = tBgB_nkl_1[
                                (
                                    None,
                                    (
                                        sfa_c_tile_idx,
                                        sfa_s_idx,
                                        sfa_r_idx,
                                        sfa_t_idx,
                                    ),
                                )
                            ]
                            tBgSFB_k_1 = tBgSFB_nkl_1[
                                (
                                    None,
                                    sfb_pos_base
                                    + sfa_c_tile_idx // self.ab_k_tiles_per_sf_k_tile,
                                )
                            ]
                            cute.copy(
                                tma_atom_b,
                                tBgB_k_1,
                                tBsB[(None, b_stage_1)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                ),
                            )
                            cute.copy(
                                tma_atom_sfb,
                                tBgSFB_k_1,
                                tBsSFB[(None, b_stage_1)],
                                tma_bar_ptr=mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                ),
                            )
                        # Mainloop pipeline's producer commit is a NOP for TMA.
                        mainloop_pipeline.producer_commit(mainloop_producer_state)
                    else:
                        # Not this warp's tile: it issues nothing, but it
                        # joins the stage's full barrier so the ring cannot lap it
                        # while it waits on the empty barrier above. See the
                        # producer arrive count where the pipeline is built.
                        with cute.arch.elect_one():
                            cute.arch.mbarrier_arrive(
                                mainloop_pipeline.producer_get_barrier(
                                    mainloop_producer_state
                                )
                            )
                    mainloop_producer_state.advance()
                    sfa_c_tile_idx = sfa_c_tile_idx + 1
                    if sfa_c_tile_idx >= c_tiles_per_fpos:
                        sfa_c_tile_idx = 0
                        sfb_pos_base = sfb_pos_base + sfb_c_tiles
                        sfa_s_idx = sfa_s_idx + 1
                        if sfa_s_idx >= rt_filter_s:
                            sfa_s_idx = 0
                            sfa_r_idx = sfa_r_idx + 1
                            if sfa_r_idx >= rt_filter_r:
                                sfa_r_idx = 0
                                sfa_t_idx = sfa_t_idx + 1
                                if sfa_t_idx >= rt_filter_t:
                                    sfa_t_idx = 0
                                    sfb_pos_base = cutlass.Int32(0)
                    coord_iter = cute.increment_coord(coord_iter, k_shape)

                # Stage this tile's bias row for its owning math warpgroup: wait
                # for the ring stage to drain, cp.async the row in, and commit so
                # each lane's arrive lands once its copies complete.
                if warp_idx == self.tma_load_warp_id:
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_pipeline.producer_acquire(bias_producer_state)
                        bias_lane_idx = tidx % self.num_threads_per_warp
                        n_base = tile_coord_mnl[1] * cta_n * self.n_tiles_per_work
                        # Each lane cp.async's contiguous 32-bit vectors
                        # (bias_elems_per_copy elements each) of this tile's bias row.
                        # Column-major stride so lane t owns [t*elems, (t+1)*elems);
                        # the output-channel axis has stride 1, so each segment is
                        # contiguous. n_active lanes cover cta_n.
                        n_active = cta_n * self.n_tiles_per_work // bias_elems_per_copy
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
                                # so tail lanes address bias columns with no backing
                                # storage. Guard each lane on its base channel:
                                # cp.async zero-fills on a false predicate, and that
                                # tail is only read for output the TMA store clamps.
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

            #
            # Copy Atom A/B retiling for TMA load A/B
            #
            atom_copy_ldmatrix_A = make_ldmatrix_atom(
                self.a_dtype,
                transpose=self.a_layout.is_m_major_a(),
                num_matrices=4,
            )
            atom_copy_ldmatrix_B = make_ldmatrix_atom(
                self.b_dtype,
                transpose=self.b_layout.is_n_major_b(),
                num_matrices=4,
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

            # In the default ping-pong tactic, parity assigns one scheduler tile
            # to one warpgroup. The paired tactic assigns both warpgroups
            # to adjacent N tiles within the same logical scheduler work item.
            tile_parity = cutlass.Int32(0)

            while work_tile.is_valid_tile:
                owns_tile = tile_parity == warp_group_idx
                if cutlass.const_expr(self.n_tiles_per_work == 2):
                    owns_tile = cutlass.Boolean(1)
                if owns_tile:
                    tile_coord_mnl = work_tile.tile_idx
                    consumer_tile_coord_mnl = tile_coord_mnl
                    if cutlass.const_expr(self.n_tiles_per_work == 2):
                        consumer_tile_coord_mnl = (
                            tile_coord_mnl[0],
                            tile_coord_mnl[1] * 2 + warp_group_idx,
                            tile_coord_mnl[2],
                        )
                    gD_mnl_slice = gD_mnl[(None, None, *consumer_tile_coord_mnl)]
                    # This tile's slice of the staged SF chunk. Consecutive N
                    # tiles share one chunk when tile_n is narrower than it, and
                    # a slice sits (tile_n/32) SF blocks past the previous one.
                    if cutlass.const_expr(self.n_tiles_per_sf_n_tile > 1):
                        sfb_n_slice = (
                            consumer_tile_coord_mnl[1] % self.n_tiles_per_sf_n_tile
                        )
                        tCsSFB_tile = cute.make_tensor(
                            tCsSFB_copy_view.iterator
                            + sfb_n_slice * (self.tile_shape_mnk[1] // 32) * 4,
                            tCsSFB_copy_view.layout,
                        )
                    else:
                        tCsSFB_tile = tCsSFB_copy_view
                    # Clear the accumulator
                    accumulators.fill(0.0)

                    #
                    # Pipelined MAINLOOP
                    #

                    mainloop_consumer_state.reset_count()
                    if cutlass.const_expr(self.n_tiles_per_work == 1):
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
                    # tCsA_p: (MMA, (4, MMA_M / 4), MMA_K), tCsA_p: (MMA, (4, MMA_N /
                    # 4), MMA_K)
                    tCsA_p = tCsA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    b_consumer_stage = mainloop_consumer_state.index
                    if cutlass.const_expr(self.n_tiles_per_work == 2):
                        b_consumer_stage += warp_group_idx * self.num_ab_stage
                    tCsB_p = tCsB_copy_view[None, None, None, b_consumer_stage]
                    tCsSFA_p = tCsSFA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsSFB_p = tCsSFB_tile[None, None, None, b_consumer_stage]
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
                                b_consumer_stage = mainloop_consumer_state.index
                                if cutlass.const_expr(self.n_tiles_per_work == 2):
                                    b_consumer_stage += (
                                        warp_group_idx * self.num_ab_stage
                                    )
                                tCsB_p = tCsB_copy_view[
                                    None, None, None, b_consumer_stage
                                ]
                                tCsSFA_p = tCsSFA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsSFB_p = tCsSFB_tile[
                                    None, None, None, b_consumer_stage
                                ]
                                mainloop_pipeline.consumer_wait(
                                    mainloop_consumer_state, peek_ab_full_status
                                )

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

                            # With more than one k_block the prefetch fills the
                            # k_block_next fragment while the MMA reads k_block_idx,
                            # so it is issued first. With exactly one, k_block_next
                            # wraps onto the fragment the MMA has yet to read, so
                            # the prefetch follows the MMA.
                            if cutlass.const_expr(num_k_blocks > 1):
                                prefetch_next_k_block()
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

                    # Ping-pong releases the other warpgroup's next mainloop here.
                    # Paired mode ran both mainloops together and uses the initial
                    # order token only to serialize the shared epilogue buffer.
                    if cutlass.const_expr(self.n_tiles_per_work == 1):
                        math_wg_order_state = math_wg_order_barrier.arrive(
                            math_wg_order_state
                        )

                    # Apply the per-tensor alpha scale in FP32 before bias/residual
                    # (D = act(alpha * acc + bias)). alpha is a runtime scalar, so
                    # this multiply lives in every cubin regardless of its value.
                    accumulators.store(accumulators.load() * alpha)

                    # Add per-output-channel bias in FP32 (D = act(alpha*acc + bias)).
                    # The TMA load warp has cp.async'd this tile's cta_tile_n bias
                    # values into the ring stage this warpgroup's consumer state points
                    # at; every thread loads its own N columns back and adds them to
                    # the accumulator, broadcast across M by mBias_mnl's stride-0 axis.
                    if cutlass.const_expr(mBias_mnl is not None):
                        bias_pipeline.consumer_wait(bias_consumer_state)
                        sBias_row = sBias[(None, bias_consumer_state.index)]
                        # Read back into a fragment aligned with the accumulator.
                        # The identity-coordinate partition gives each element its
                        # tile-local N column [0, cta_n), the linear index into the
                        # staged row (the producer applied n_base when staging from
                        # gmem and zero-filled any N-overhang).
                        tCcBias_tile = tCcBias[
                            (None, None, None, *consumer_tile_coord_mnl)
                        ]
                        tCrBias = cute.make_rmem_tensor(
                            accumulators.shape, mBias_mnl.element_type
                        )
                        for be in cutlass.range_constexpr(cute.size(tCrBias)):
                            bias_col = tCcBias_tile[be][1]
                            if cutlass.const_expr(self.n_tiles_per_work == 2):
                                bias_col += warp_group_idx * cta_n
                            tCrBias[be] = sBias_row[bias_col]
                        # Release the stage so the TMA load warp can refill it:
                        # every thread arrives only after its smem reads are done.
                        cute.arch.fence_proxy("async.shared", space="cta")
                        bias_pipeline.consumer_release(bias_consumer_state)
                        bias_consumer_state.advance()
                        accumulators.store(
                            accumulators.load() + tCrBias.load().to(cutlass.Float32)
                        )

                    #
                    # EPILOG
                    #

                    # Serialize the epilogue against the other warpgroup before
                    # touching the shared sD staging buffer. In paired mode wg0
                    # starts with the initial token and wg1 follows it.
                    math_wg_order_barrier.wait(math_wg_order_state)
                    (
                        tiled_copy_r2s,
                        thr_copy_r2s,
                        tRS_sD,
                        tRS_rAcc,
                        tRS_rD,
                        tRS_rD_layout,
                    ) = self.epilog_smem_store_copy_and_partition(
                        tiled_mma, accumulators, tidx, sD
                    )

                    bSG_sD, bSG_gD = self.epilog_gmem_copy_and_partition(
                        tma_atom_d, gD_mnl_slice, sD
                    )

                    # Residual read-back: partition sC with the thread slice the D
                    # store uses for its reg source, so tRS_sC carries tRS_rD's
                    # per-thread TV layout. A plain element copy then lands each
                    # stage in a congruent fragment, aligned with the accumulator.
                    if cutlass.const_expr(self.has_residual):
                        # (R2S, R2S_M, R2S_N, PIPE_D) reg-side view of the residual
                        # smem, congruent with tRS_rD.
                        tRS_sC = thr_copy_r2s.partition_S(sC)

                    # Initialize tma store pipeline
                    tma_store_producer_group = pipeline.CooperativeGroup(
                        pipeline.Agent.Thread,
                        self.num_mma_warps * self.num_threads_per_warp,
                    )
                    tma_store_pipeline = pipeline.PipelineTmaStore.create(
                        num_stages=self.num_d_stage,
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
                            # Wait for the G2S load, read it into a fragment shaped
                            # like tRS_rD, add beta*residual, then release the stage.
                            # beta is a compile-time constant folded into the add.
                            if cutlass.const_expr(self.has_residual):
                                c_pipeline.consumer_wait(c_consumer_state)
                                tRS_rC = cute.make_rmem_tensor(
                                    tRS_rD_layout.shape, self.d_dtype
                                )
                                cute.autovec_copy(
                                    tRS_sC[
                                        (
                                            None,
                                            None,
                                            None,
                                            c_consumer_state.index,
                                        )
                                    ],
                                    tRS_rC,
                                )
                                cute.arch.fence_proxy(
                                    "async.shared",
                                    space="cta",
                                )
                                c_pipeline.consumer_release(c_consumer_state)
                                c_consumer_state.advance()
                                tRS_rD.store(
                                    tRS_rD.load()
                                    + self.beta * tRS_rC.load().to(cutlass.Float32)
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
                    mainloop_consumer_state.advance(k_tile_cnt)
                    # Likewise skip this tile's residual: the residual warp
                    # produced one stage per output subtile for it, so advance the
                    # residual consumer state by that subtile count to keep the
                    # ring counter aligned with the next owned tile.
                    if cutlass.const_expr(self.has_residual):
                        c_subtiles_per_tile = (
                            self.tile_shape_mnk[0] // self.epi_tile[0]
                        ) * (self.tile_shape_mnk[1] // self.epi_tile[1])
                        c_consumer_state.advance(c_subtiles_per_tile)
                    # Likewise skip this tile's bias stage: the TMA load warp
                    # produced one per tile, so advance past it to stay aligned
                    # with the next owned tile.
                    if cutlass.const_expr(self.has_bias):
                        bias_consumer_state.advance()

                # Pull the next tile from the CLC response slot. Both MMA
                # warpgroups, the SFA cp.async group, both TMA load warps, and the
                # scheduler warp participate as consumers; the parity flip below
                # routes the tile to its owning warpgroup.
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
        # epi-subtile, into sC. Both math warpgroups consume their own
        # tile's residual from the same pipeline.
        elif warp_idx == self.residual_tma_warp_id:
            # Dedicated residual G2S load warp. The whole body is compiled only
            # when beta != 0; at beta == 0 this warp just sets the register floor
            # like the other idle round-up warps (has_residual gates on the same
            # const as the CLC consumer count and the smem/pipeline allocation, so
            # nothing here touches the None residual handles).
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
            if cutlass.const_expr(self.has_residual):
                c_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_c_stage
                )
                # Same gmem/smem TMA partition the epilogue consumer uses, so the
                # producer stages subtiles in the exact grid the consumer reads.
                sC_for_tma = cute.group_modes(sC, 0, 2)
                while work_tile.is_valid_tile:
                    tile_coord_mnl = work_tile.tile_idx
                    gC_slice = gC_mnl[(None, None, *tile_coord_mnl)]
                    tcg_c = cute.zipped_divide(gC_slice, self.epi_tile)
                    bGS_sC, bGS_gC = cpasync.tma_partition(
                        tma_atom_c,
                        0,
                        cute.make_layout(1),
                        sC_for_tma,
                        tcg_c,
                    )
                    c_rest_m = bGS_gC.shape[1][0]
                    c_rest_n = bGS_gC.shape[1][1]
                    for epi_m in cutlass.range_constexpr(c_rest_m):
                        for epi_n in cutlass.range_constexpr(c_rest_n):
                            c_pipeline.producer_acquire(c_producer_state)
                            cute.copy(
                                tma_atom_c,
                                bGS_gC[(None, (epi_m, epi_n))],
                                bGS_sC[(None, c_producer_state.index)],
                                tma_bar_ptr=c_pipeline.producer_get_barrier(
                                    c_producer_state
                                ),
                            )
                            c_pipeline.producer_commit(c_producer_state)
                            c_producer_state.advance()

                    # Walk the tile stream in lockstep with the epilogue consumers.
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()
                c_pipeline.producer_tail(c_producer_state)
        # Unused warps rounded up by the warpgroup register-realloc requirement.
        # Same warpgroup as the scheduler warp, so it must use the same count.
        else:
            cute.arch.setmaxregister_decrease(self.sched_register_requirement)
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
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        d_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
        beta: float = 0.0,
        c_dtype: Optional[Type[cutlass.Numeric]] = None,
        bias_dtype: Optional[Type[cutlass.Numeric]] = None,
        activation: str = "identity",
    ) -> bool:
        """Run every host-side check and tell whether the configuration is supported.

        The checks go from the structural ones to the geometry-derived ones: element
        and scale-factor types, epilogue activation, CTA tile shape, channel count,
        convolution geometry, tensor alignment, im2col descriptor limits.

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
        :param sf_dtype: Scale-factor element type, shared by SFA and SFB
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: Channels one scale factor covers
        :type sf_vec_size: int
        :param d_dtype: Output element type
        :type d_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator element type
        :type acc_dtype: Type[cutlass.Numeric]
        :param tile_shape_mnk: CTA tile shape (M, N, K)
        :type tile_shape_mnk: Tuple[int, int, int]
        :param beta: Compile-time residual coefficient
        :type beta: float
        :param c_dtype: Residual (C) element type, or None when no residual is passed
        :type c_dtype: Optional[Type[cutlass.Numeric]]
        :param bias_dtype: Bias element type, or None when no bias is supplied
        :type bias_dtype: Optional[Type[cutlass.Numeric]]
        :param activation: Name of the compile-time epilogue activation, one of
            EPILOGUE_ACTIVATIONS
        :type activation: str

        :return: True if the configuration can be implemented, False otherwise
        :rtype: bool
        """
        try:
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
            # The block-scaled MMA accumulates in FP32 only.
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
            # The residual path is compiled in by beta != 0 and reads C, so the two go
            # together. C is loaded by an im2col TMA atom built on D's geometry into
            # smem laid out like D's, so it must match D's dtype exactly.
            if (beta != 0.0) != (c_dtype is not None):
                raise testing.CantImplementError(
                    f"beta = {beta} with c_dtype = {c_dtype}: beta != 0 requires a "
                    "residual C and beta == 0 takes none."
                )
            if c_dtype is not None and c_dtype is not d_dtype:
                raise testing.CantImplementError(
                    f"Residual c_dtype ({c_dtype}) must equal d_dtype ({d_dtype})."
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
            # A 256-wide N tile selects the cooperative tactic; the checks below then
            # work on the per-warpgroup 128-wide half.
            if tile_shape_mnk[1] == 256:
                if ab_dtype is not cutlass.Float4E2M1FN:
                    raise testing.CantImplementError(
                        "tile_n=256 currently supports NVFP4 only"
                    )
                if tile_shape_mnk != (128, 256, 128):
                    raise testing.CantImplementError(
                        "a 256-wide N tile requires tile_shape_mnk=(128, 256, 128), "
                        f"got {tile_shape_mnk}"
                    )
                # A K that does not fill the 256-wide tile leaves the trailing work
                # item's high half short. The overhang itself is covered by the
                # usual partial-tile mechanisms; what the remainder decides is
                # whether the high half keeps a live channel, and at 128 or below
                # the second warpgroup would compute a tile that is fully discarded.
                if k % 256 != 0 and k % 256 <= 128:
                    raise testing.CantImplementError(
                        "tile_n=256 splits each work item into two 128-wide halves, "
                        "so a trailing remainder has to leave the high half live: K "
                        f"needs K % 256 == 0 or K % 256 > 128, got K = {k}"
                    )
                if beta != 0.0:
                    raise testing.CantImplementError(
                        "tile_n=256 does not support residual fusion"
                    )
                tile_shape_mnk = (
                    tile_shape_mnk[0],
                    tile_shape_mnk[1] // 2,
                    tile_shape_mnk[2],
                )
            # tile_m must be exactly 128: the block-scaled SF SMEM layout tiles the M
            # extent in units of blk_mn=128 (one BlockScaledBasicChunk row), so a tile_m
            # that is not a whole number of chunks fails that layout's own assert.
            if tile_shape_mnk[0] != 128:
                raise testing.CantImplementError(
                    f"tile_m must be 128 (the SF chunk's row count), got "
                    f"{tile_shape_mnk[0]}"
                )
            # tile_k for NVFP4 is 64 or 128: the MMA fills K in 64-channel steps and
            # the SF SMEM layout needs a whole 4-block atom (also 64 channels) per K
            # tile, so 64 is the floor. MXFP8 uses 64 so the fp8 operands keep a deep
            # A/B pipeline, and its 128-channel SF chunk then serves two A/B tiles.
            allowed_tile_k = (64,) if is_mxfp8 else (64, 128)
            allowed_tile_n = (64, 96, 128)
            if tile_shape_mnk[2] not in allowed_tile_k:
                raise testing.CantImplementError(
                    f"tile_k must be one of {allowed_tile_k} for {ab_dtype}, got "
                    f"{tile_shape_mnk[2]}"
                )
            # tile_n is bounded by the scale-factor chunk geometry: a chunk covers 128
            # output channels, is indivisible, and the SF layout a tile reads assumes
            # the tile starts on a chunk boundary. A tile_n off the 32-wide MMA N step
            # misses the SF block granularity, 32 has no ldmatrix partition for the
            # scale factors, and above 128 the N basic block stops covering the tile.
            tile_n = tile_shape_mnk[1]
            if tile_n not in allowed_tile_n:
                raise testing.CantImplementError(
                    f"tile_n must be one of {allowed_tile_n} for {ab_dtype} (bounded by "
                    f"the 128-channel SF chunk and its 32-row blocks), got {tile_n}"
                )
            # 64 and 128 divide a chunk, so every N tile sits inside one. 96 does not,
            # so only the first tile is chunk-aligned; it is restricted to problems that
            # need a single N tile, where it fills N exactly.
            n_tiles = (k + tile_n - 1) // tile_n
            if 128 % tile_n != 0 and n_tiles > 1:
                raise testing.CantImplementError(
                    f"tile_n={tile_n} does not divide the 128-channel SF chunk, so only "
                    f"the first N tile starts on a chunk boundary; it needs a single N "
                    f"tile but K={k} needs {n_tiles}. Use tile_n=64 or 128."
                )
            # A tighter bound on C: a whole number of scale-factor atoms of
            # 4 * sf_vec_size channels. SFA's 4-byte cp.async carries exactly one atom
            # and walks a row stride of C / sf_vec_size factors, which this keeps a
            # multiple of 4. It also makes the chunk redirect exact, since the factor
            # index and the row's factor count are both multiples of a chunk's 4.
            c = ncdhw[1]
            sf_atom_channels = sf_vec_size * 4
            if c % sf_atom_channels != 0:
                raise testing.CantImplementError(
                    f"{ab_dtype} requires C to be a multiple of {sf_atom_channels}, "
                    f"got C = {c}."
                )
            check_conv_geometry(
                ncdhw,
                (k, *filter_trs),
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            # C fills neither the K tile nor a whole SF K tile: a partial trailing tile
            # reads zero-filled operands, SFA redirects its spare chunks back inside the
            # pixel's own row, and SFB uses a span padded to whole SF K tiles. What
            # survives is the 16-byte alignment the TMA needs on a contiguous axis,
            # which C carries for the operands and K for the output.
            check_tensor_alignment(c, k, ab_dtype, d_dtype)
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


@lru_cache(maxsize=None)
def compile_conv(
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    tile_shape_mnk: Tuple[int, int, int],
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    beta: float = 0.0,
    activation: str = "identity",
    frontendnext: bool = False,
):
    """Build the kernel object, resolve host launch config, and cute.compile it.

    Every parameter is a hashable scalar that selects a cubin, so the result is
    cached unbounded: a repeat configuration skips both the trace and the compile.
    The tensors are stood in for by fakes built from the element types, because the
    compiled module reads nothing else from them.
    Which tensors exist follows from the scalars: a residual from beta, a bias from
    bias_dtype.

    Returns the compiled callable. Pad / stride / dilation reach the kernel as
    runtime cutlass.Int32, which the rt_ prefix marks, so one compiled cubin serves
    any geometry and the trace takes placeholder values; the caller boxes the real
    ones when it launches. The stream a compilation is handed never runs anything,
    so it is a fake one; the caller passes the real stream when it launches.

    :param ab_dtype: Element type of the input and filter tensors
    :param d_dtype: Element type of the output tensor
    :param acc_dtype: Accumulator data type
    :param sf_dtype: Element type of the block scale factors
    :param sf_vec_size: Channels one scale factor covers
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :param bias_dtype: Element type of the per-output-channel bias, or None for a
        cubin without the bias path
    :param beta: Compile-time residual scale; 0.0 compiles the residual path away
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
    sfa_ = make_fake_conv_tensor(sf_dtype, 3, 1)
    sfb_ = make_fake_conv_tensor(sf_dtype, 6, 3)
    bias_ = None if bias_dtype is None else make_fake_conv_tensor(bias_dtype, 1, 0)
    # The residual shares the output's descriptor and element type; beta alone says
    # whether the path is compiled in.
    c_ = make_fake_conv_tensor(d_dtype, 5, 4) if beta != 0.0 else None
    # alpha reaches the kernel as a runtime FP32, so a placeholder traces the same
    # module the caller's value launches against.
    alpha_ = cutlass.Float32(1.0)

    # The activation's device op is folded into the cubin, so a different activation
    # is a different kernel.
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    conv = Sm120BlockScaledDenseImplicitGemmFpropKernel(
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
    )
    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(1)
    stream = make_fake_stream()

    rt_conv_params = trace_conv_scalars()

    return cute.compile(
        conv,
        input_,
        filter_,
        sfa_,
        sfb_,
        output_,
        bias_,
        c_,
        alpha_,
        beta,
        *rt_conv_params,
        max_active_clusters,
        stream,
        epilogue_op,
    )


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
    c_dtype: Optional[Type[cutlass.Numeric]] = None,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    tile_shape_mnk: Tuple[int, int, int] = (128, 128, 128),
    tolerance: float = 1e-1,
    warmup_iterations: int = 0,
    iterations: int = 0,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    activation: str = "identity",
    use_bias: bool = False,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    alpha: float = 1.0,
    beta: float = 0.0,
    **kwargs,
):
    """Run 3D convolution and compare against a block-scaled PyTorch reference.

    The filter tensor uses native KTRSC layout (K, T, R, S, C) with C contiguous.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param stride_dhw: Stride (Sd, Sh, Sw)
    :param upper_pad_dhw: Upper padding (PadD, PadH, PadW)
    :param lower_pad_dhw: Lower padding (PadD, PadH, PadW)
    :param dil_dhw: Dilation (DilD, DilH, DilW)
    :param ab_dtype: Data type for A/B input tensors
    :param sf_dtype: Scale factor element type, E4M3 for NVFP4 and E8M0 for MXFP8
    :param sf_vec_size: Channels one scale factor covers, 16 for NVFP4 and 32 for MXFP8
    :param d_dtype: Data type for output tensor D
    :param c_dtype: Residual (C) data type; None takes the output type, which is the
        only value it can hold since C is staged in smem laid out like D's
    :param acc_dtype: Accumulator data type
    :param tile_shape_mnk: CTA tile shape (M, N, K)
    :param tolerance: Tolerance for result comparison
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param skip_ref_check: Whether to skip reference checking
    :param use_cold_l2: Whether to flush L2 cache between iterations
    :param activation: Compile-time epilogue activation, one per cubin
    :param use_bias: Add a per-output-channel bias as D = activation(alpha*acc + bias +
        beta*residual); bias and no-bias are separate cubins
    :param bias_dtype: Bias element type; None derives it from the output type
    :param alpha: Per-tensor accumulator scale. Runtime scalar: one cubin serves any
        value
    :param beta: Residual scaling; beta != 0 enables the residual path and beta == 0
        compiles it away. Compile-time constant: one cubin per value
    :param kwargs: Extra keyword arguments, accepted and ignored
    :return: Benchmark time in microseconds per iteration, or None when iterations is 0
    """
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example")

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs

    # Residual (C) shares the output's shape and im2col TMA descriptor, so its
    # dtype defaults to the output dtype when the caller does not set one.
    if c_dtype is None:
        c_dtype = d_dtype

    # Settle the bias element type before the configuration is checked, so the check
    # sees the type the bias tensor will actually carry.
    if use_bias and bias_dtype is None:
        bias_dtype = bias_dtype_for_output(d_dtype)
    # Every host-side check runs here, before any tensor or compile work.
    if not Sm120BlockScaledDenseImplicitGemmFpropKernel.can_implement(
        ncdhw,
        K,
        (T, R, S),
        upper_pad_dhw,
        lower_pad_dhw,
        stride_dhw,
        dil_dhw,
        ab_dtype,
        sf_dtype,
        sf_vec_size,
        d_dtype,
        acc_dtype,
        tile_shape_mnk,
        beta,
        c_dtype if beta != 0.0 else None,
        bias_dtype if use_bias else None,
        activation,
    ):
        raise testing.CantImplementError(
            f"Config not implementable: ncdhw={ncdhw}, ktrs={ktrs}, "
            f"stride={stride_dhw}, pad=({upper_pad_dhw}, {lower_pad_dhw}), "
            f"dilation={dil_dhw}, tile_shape_mnk={tile_shape_mnk}, "
            f"dtypes=({ab_dtype}, {sf_dtype}/{sf_vec_size}, {d_dtype}, {acc_dtype}), "
            f"bias_dtype={bias_dtype if use_bias else None}, beta={beta}, "
            f"activation={activation}"
        )
    Z, P, Q = compute_zpq(
        ncdhw[2:], ktrs[1:], stride_dhw, upper_pad_dhw, lower_pad_dhw, dil_dhw
    )

    gemm_m = N * Z * P * Q
    gemm_n = K
    gemm_k = C * T * R * S
    print("Running Blackwell Geforce SM120 NVFP4 fprop with:")
    print(f"ncdhw: {ncdhw}, ktrs: {ktrs}, zpq: {(Z, P, Q)}")
    print(f"implicit GEMM mnk: {(gemm_m, gemm_n, gemm_k)}")
    print(
        f"A/B dtype: {ab_dtype}, SF dtype: {sf_dtype}, D dtype: {d_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Tile Shape: {tile_shape_mnk}")
    print(f"Skip reference checking: {skip_ref_check}")

    input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
        ncdhw, ktrs, (Z, P, Q), ab_dtype
    )
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
    # Free staging buffers once consumed to bound peak memory and avoid OOM.
    del output_tensor

    sfa_ref, sfa_, sfa_storage = create_scale_factor_tensor_unswizzled(
        1, N * D * H * W, C, sf_vec_size, sf_dtype
    )
    # SFB is allocated with every filter position padded out to a whole number of SF
    # K tiles, the same span the kernel derives at runtime, so every position starts
    # on a tile boundary and no K tile addresses past the one it belongs to. The
    # padded channels pair with the B channels past C, which the TMA zero-fills, so
    # their scale factors never reach the result and only have to be finite.
    sfb_c_span = sfb_per_position_channels(C, tile_shape_mnk[2], sf_vec_size)
    sfb_ref, sfb_, sfb_storage = create_scale_factor_tensor_swizzled(
        1, gemm_n, sfb_c_span * T * R * S, sf_vec_size, sf_dtype
    )

    # Per-output-channel bias of length gemm_n = K, in the bias element type (the
    # epilogue's 16-bit floor keeps it wider than a narrow output). Added to the
    # accumulator in FP32 as D = act(alpha*acc + bias), broadcast across every
    # spatial position. Marked dynamic-layout so the length-K extent lowers to
    # runtime SSA; a static extent would freeze K into the compiled module.
    if use_bias:
        bias_storage = torch.randn(gemm_n, dtype=torch.float32, device="cuda").to(
            cutlass_torch.dtype(bias_dtype)
        )
        bias_ = from_dlpack(bias_storage, assumed_align=16).mark_layout_dynamic(
            leading_dim=0
        )
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
        c_f32_src = torch.randn((N, Z, P, Q, K), dtype=torch.float32, device="cuda")
        c_, c_storage = create_cute_tensor(c_f32_src, c_dtype, leading_dim=4)
    else:
        c_, c_storage, c_f32_src = None, None, None

    # A fresh non-default stream carries the kernel: CUDA graph capture, which the
    # benchmark below uses, requires one.
    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)
    # Pad / stride / dilation are boxed as runtime cutlass.Int32, which the rt_
    # prefix marks, so one compiled cubin serves any geometry: the launch scalars
    # lower to runtime SSA. The order here matches the kernel entry signature, and
    # the compile step boxes the same values independently.
    rt_conv_params = rt_conv_scalars(
        upper_pad=upper_pad_dhw,
        lower_pad=lower_pad_dhw,
        stride=stride_dhw,
        dil=dil_dhw,
    )

    compiled_conv = compile_conv(
        ab_dtype,
        d_dtype,
        acc_dtype,
        sf_dtype,
        sf_vec_size,
        tile_shape_mnk,
        bias_dtype=bias_dtype if use_bias else None,
        beta=beta,
        activation=activation,
        frontendnext=frontend_cache_token(),
    )
    print("Compiled conv kernel.", flush=True)

    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_conv(
        input_,
        filter_,
        sfa_,
        sfb_,
        output_,
        bias_,
        c_,
        alpha_,
        *rt_conv_params,
        current_stream,
    )
    torch_stream.synchronize()

    if not skip_ref_check:
        sfa_expanded = sfa_ref.squeeze(-1).reshape(N, D, H, W, C).cuda()
        sfb_expanded = (
            sfb_ref.squeeze(-1).reshape(K, T, R, S, sfb_c_span)[..., :C].cuda()
        )
        # The kernel has read A, so its f32 source takes the scale factors in place.
        scaled_input = input_tensor.mul_(sfa_expanded)
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del input_tensor, sfa_ref, sfa_expanded
        scaled_filter = filter_tensor.float() * sfb_expanded
        scaled_input_ncdhw = scaled_input.permute(0, 4, 1, 2, 3).contiguous()
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del scaled_input
        scaled_filter_kctrs = scaled_filter.permute(0, 4, 1, 2, 3).contiguous()
        if upper_pad_dhw == lower_pad_dhw:
            ref_nkzpq = F.conv3d(
                scaled_input_ncdhw,
                scaled_filter_kctrs,
                padding=upper_pad_dhw,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del scaled_input_ncdhw
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
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del scaled_input_ncdhw
            ref_nkzpq = F.conv3d(
                padded,
                scaled_filter_kctrs,
                stride=stride_dhw,
                dilation=dil_dhw,
            )
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del padded
        ref = ref_nkzpq.permute(0, 2, 3, 4, 1).contiguous()
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del ref_nkzpq
        # Scale the accumulator by alpha in FP32, then add the per-output-channel
        # bias before the activation, matching the device epilogue
        # (D = act(alpha*acc + bias)). bias_storage holds the exact bias-dtype values
        # the kernel loads, so float() reproduces them bit-for-bit.
        ref = alpha * ref
        if use_bias:
            ref = ref + bias_storage.float().reshape(1, 1, 1, 1, gemm_n).cuda()
        # Add the per-element residual in FP32 before the activation, matching the
        # device epilogue (D = act(alpha*acc + bias + beta*residual)).
        # c_storage holds the exact d_dtype values the kernel loads, so
        # float() reproduces them bit-for-bit.
        if has_residual:
            ref = ref + beta * c_storage.float().reshape(N, Z, P, Q, K).cuda()
        # Apply the epilogue activation folded into the kernel.
        ref = EPILOGUE_ACTIVATIONS[activation]["ref"](ref)

        d_ref_device = torch.empty((N, Z, P, Q, K), dtype=torch.float32, device="cuda")
        cute.testing.convert(
            output_,
            from_dlpack(d_ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=4
            ),
        )
        d_result = d_ref_device.cpu()
        # Free staging buffers once consumed to bound peak memory and avoid OOM.
        del d_ref_device
        # Narrow the reference through the device conversion path and widen it back,
        # so the comparison runs in the element type the kernel's output store rounds
        # to. Sub-byte and 8-bit types pack into a byte buffer, wider types keep their
        # native element type. The round trip runs on the K-major (N, Z, P, Q, K)
        # layout the kernel writes, whose leading extent carries the vectorized copy.
        ref_narrow_byte_storage = (d_dtype.is_float and d_dtype.width <= 8) or (
            d_dtype.is_integer and d_dtype.width == 4
        )
        ref_narrow_storage_dtype = (
            torch.uint8 if ref_narrow_byte_storage else cutlass_torch.dtype(d_dtype)
        )
        ref_narrow_storage = torch.empty(
            (N, Z, P, Q, K), dtype=ref_narrow_storage_dtype, device="cuda"
        )
        ref_narrow = from_dlpack(
            ref_narrow_storage, assumed_align=16
        ).mark_layout_dynamic(leading_dim=4)
        ref_narrow.element_type = d_dtype
        ref_device = ref.contiguous().cuda()
        ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
            leading_dim=4
        )
        cute.testing.convert(ref_tensor, ref_narrow)
        cute.testing.convert(ref_narrow, ref_tensor)
        torch.testing.assert_close(
            d_result, ref_device.cpu(), atol=tolerance, rtol=1e-2
        )
        print("✓ Results match within tolerance!")

    def generate_tensors():
        # Every tensor the kernel reads rotates per cold-L2 workspace, so each one is
        # rebuilt here and each one counts toward the workspace bytes below. alpha and
        # the geometry scalars are runtime values, not memory, and are reused.
        input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
            ncdhw, ktrs, (Z, P, Q), ab_dtype
        )
        input_, _ = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
        filter_, _ = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
        output_, _ = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
        _, ws_sfa_, _ = create_scale_factor_tensor_unswizzled(
            1, N * D * H * W, C, sf_vec_size, sf_dtype
        )
        _, ws_sfb_, _ = create_scale_factor_tensor_swizzled(
            1, gemm_n, sfb_c_span * T * R * S, sf_vec_size, sf_dtype
        )
        if use_bias:
            ws_bias_storage = torch.randn(
                gemm_n, dtype=torch.float32, device="cuda"
            ).to(cutlass_torch.dtype(bias_dtype))
            ws_bias_ = from_dlpack(
                ws_bias_storage, assumed_align=16
            ).mark_layout_dynamic(leading_dim=0)
        else:
            ws_bias_ = None
        if has_residual:
            ws_c_, _ = create_cute_tensor(
                torch.randn((N, Z, P, Q, K), dtype=torch.float32, device="cuda"),
                c_dtype,
                leading_dim=4,
            )
        else:
            ws_c_ = None
        # The workspace initializes on other streams; drain them so the
        # benchmark stream never reads a tensor mid-initialization.
        torch.cuda.synchronize()
        return testing.JitArguments(
            input_,
            filter_,
            ws_sfa_,
            ws_sfb_,
            output_,
            ws_bias_,
            ws_c_,
            alpha_,
            *rt_conv_params,
            current_stream,
        )

    if iterations > 0:
        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                input_storage.numel() * input_storage.element_size()
                + filter_storage.numel() * filter_storage.element_size()
                + output_storage.numel() * output_storage.element_size()
                + sfa_storage.numel() * sfa_storage.element_size()
                + sfb_storage.numel() * sfb_storage.element_size()
            )
            # beta*residual is output-sized, so it counts toward the bytes of each
            # cold-L2 workspace; bias is a small K vector but counted for symmetry.
            if bias_storage is not None:
                one_workspace_bytes += (
                    bias_storage.numel() * bias_storage.element_size()
                )
            if c_storage is not None:
                one_workspace_bytes += c_storage.numel() * c_storage.element_size()
            workspace_count = testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )

        # exec_time is in microseconds
        exec_time = testing.benchmark(
            compiled_conv,
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Blackwell GeForce (SM120) block-scaled 3D convolution via "
        "implicit GEMM"
    )

    # Convolution parameters
    parser.add_argument(
        "--ncdhw",
        type=parse_comma_separated_ints,
        default=(1, 128, 3, 3, 130),
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
            cutlass.Float4E2M1FN,
            cutlass.Float8E4M3FN,
        ],
        default=cutlass.Float4E2M1FN,
        help="A/B element type. NVFP4 pairs it with an E4M3 scale at a vector "
        "size of 16, MXFP8 with an E8M0 scale at 32",
    )
    parser.add_argument(
        "--sf_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float8E4M3FN,
            cutlass.Float8E8M0FNU,
        ],
        default=cutlass.Float8E4M3FN,
        help="Scale-factor element type, pinned by the A/B element type",
    )
    parser.add_argument(
        "--sf_vec_size",
        type=int,
        choices=[16, 32],
        default=16,
        help="Channels one scale factor covers, pinned by the A/B element type",
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.BFloat16,
            cutlass.Float16,
        ],
        default=cutlass.Float16,
    )
    parser.add_argument(
        "--c_dtype",
        type=cutlass.dtype,
        default=None,
        help="Residual (C) input data type. Defaults to --d_dtype; must equal "
        "it since C is staged in smem laid out like D's.",
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
        ],
        default=cutlass.Float32,
    )

    # Tile shape
    parser.add_argument(
        "--tile_shape_mnk",
        type=parse_comma_separated_ints,
        default=(128, 128, 128),
        help="CTA tile shape (M,N,K)",
    )

    # Validation and benchmark parameters
    parser.add_argument(
        "--tolerance", type=float, default=1e-1, help="Tolerance for validation"
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
        "--activation",
        type=str,
        default="identity",
        choices=sorted(EPILOGUE_ACTIVATIONS),
        help="Compile-time epilogue activation applied as D = activation(acc). "
        "One activation per cubin.",
    )
    parser.add_argument(
        "--use_bias",
        action="store_true",
        default=False,
        help="Add a per-output-channel bias, D = act(alpha*acc + bias + "
        "beta*residual). Bias and no-bias are separate cubins",
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
        "which has a 16-bit floor.",
    )
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
        args.sf_dtype,
        args.sf_vec_size,
        args.d_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.tile_shape_mnk,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        activation=args.activation,
        use_bias=args.use_bias,
        bias_dtype=args.bias_dtype,
        alpha=args.alpha,
        beta=args.beta,
    )
    print("PASS")
