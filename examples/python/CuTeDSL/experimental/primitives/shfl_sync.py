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

"""
shfl.sync — Warp-level shuffle using all four ShflKind variants.

Demonstrates:

  - :func:`~cutlass.primitives.shfl_sync` with ``prims.Shfl.IDX``  — indexed read /
    broadcast (``offset`` is an absolute source lane ID)
  - :func:`~cutlass.primitives.shfl_sync` with ``prims.Shfl.BFLY`` — butterfly XOR
    reduction (``offset`` is XOR-ed with the calling lane's ID)
  - :func:`~cutlass.primitives.shfl_sync` with ``prims.Shfl.UP``   — up-shift scan
    (``offset`` is subtracted from the calling lane's ID; ``is_valid``
    predicate indicates whether the source lane was in range)
  - :func:`~cutlass.primitives.shfl_sync` with ``prims.Shfl.DOWN`` — down-shift
    (``offset`` is added to the calling lane's ID)
  - Compile-time parameterisation: ``WARP_SIZE`` as ``cutlass.Constexpr``
  - Runtime parameterisation: number of rows varied without recompilation

Four kernels, each with a dedicated ``compile_*()``, ``run_()``,
and ``verify_*()`` following the canonical CUTLASS DSL kernel template.

To run::

    python CuTeDSL/experimental/primitives/shfl_sync.py                # all four kernels
    python CuTeDSL/experimental/primitives/shfl_sync.py --kernel 1     # idx broadcast
    python CuTeDSL/experimental/primitives/shfl_sync.py --kernel 2     # bfly reduction
    python CuTeDSL/experimental/primitives/shfl_sync.py --kernel 3     # up-shift scan
    python CuTeDSL/experimental/primitives/shfl_sync.py --kernel 4     # down-shift (sub-warp)

"""

import cutlass
import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import cuda.bindings.driver as cuda
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # threads per warp (compile-time constant)
_FULL_MASK: int = 0xFFFFFFFF  # all 32 lanes participate

# mask_and_clamp values for a full 32-lane warp:
#   idx / down / bfly: clamp = width-1 = 31,  segmask bits = 0  → 0x1F
#   up:                clamp = 0,              segmask bits = 0  → 0x00
_MAC_IDX_DOWN_BFLY: int = 0x1F
_MAC_UP: int = 0x00


# =============================================================================
# Kernel 1 — prims.Shfl.IDX: indexed read / broadcast
#
# Each lane reads val from source lane `src`.  With src=0 this broadcasts
# lane 0's value to all lanes.  The compile-time WARP_SIZE_C Constexpr
# demonstrates compile-time parameterisation.
# =============================================================================


@cute.kernel
def broadcast_kernel(
    src_arr: cutlass.Array,  # [WARP_SIZE]  Int32  — one value per lane
    dst_arr: cutlass.Array,  # [WARP_SIZE]  Int32  — broadcast result
    src_lane: cutlass.Int32,  # absolute source lane to broadcast from
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Broadcast ``src_vals[src_lane]`` to all lanes via ``prims.Shfl.IDX``.

    Each participating lane reads from the same absolute source lane.
    ``WARP_SIZE_C`` is baked at compile time; ``src_lane`` is a runtime value
    that can change without recompilation.

    :param src_arr: Per-lane input values.
    :type src_arr: cutlass.Array
    :param dst_arr: Output — same value on every lane after shuffle.
    :type dst_arr: cutlass.Array
    :param src_lane: Absolute source lane index in [0, 31].
    :type src_lane: cutlass.Int32
    :param WARP_SIZE_C: Compile-time warp size (baked by cute.compile).
    :type WARP_SIZE_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # prims.Shfl.IDX — read from absolute lane `src_lane`.
    # mask_and_clamp = 0x1F: full 32-lane warp, clamp boundary = 31.
    # ------------------------------------------------------------------
    my_val = src_arr[tidx]
    broadcast = prims.shfl_sync(
        _FULL_MASK,
        my_val,
        src_lane,  # absolute source lane (runtime)
        _MAC_IDX_DOWN_BFLY,
        prims.Shfl.IDX,
    )
    dst_arr[tidx] = broadcast


@cute.jit
def broadcast_host(
    src_vals: cutlass.Array,
    dst_vals: cutlass.Array,
    stream,
    src_lane: cutlass.Int32,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch :func:`broadcast_kernel` over one warp."""
    broadcast_kernel(src_vals, dst_vals, src_lane, WARP_SIZE_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_broadcast(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile the broadcast kernel with ``WARP_SIZE_C`` baked in.

    ``WARP_SIZE_C`` is the only compile-time parameter; ``src_lane`` stays
    symbolic so the binary accepts any source lane without recompilation.

    :param WARP_SIZE_C: Warp size baked at compile time (default 32).
    :type WARP_SIZE_C: int
    :return: Compiled callable; runtime signature
        ``(src_vals, dst_vals, stream, src_lane)``.
    :rtype: Callable
    """
    fake_src = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    fake_dst = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    return cute.compile(
        broadcast_host,
        fake_src,
        fake_dst,
        make_fake_stream(),
        0,  # src_lane — symbolic runtime arg
        WARP_SIZE_C,  # WARP_SIZE_C — baked as Constexpr
        options="--enable-tvm-ffi",
    )


def run_broadcast(
    fn: Callable,
    src_lane: int = 7,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(dst_vals, src_vals)``.

    Input values are lane indices ``0, 1, …, 31``.

    :param fn: Compiled callable from :func:`compile_broadcast`.
    :type fn: Callable
    :param src_lane: Source lane to broadcast from.
    :type src_lane: int
    :return: ``(dst_vals, src_vals)`` — output and input tensors.
    :rtype: tuple[torch.Tensor, torch.Tensor]
    """
    src = torch.arange(_WARP_SIZE, dtype=torch.int32, device="cuda")
    dst = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(src, dst, stream, src_lane)
    torch.cuda.synchronize()
    return dst, src


def verify_broadcast() -> None:
    """Compile, run (two src_lane variants), and assert broadcast correctness.

    Demonstrates runtime parameterisation: the same compiled binary handles
    ``src_lane=7`` and ``src_lane=15`` without recompilation.

    :raises AssertionError: If any lane receives the wrong value.
    """
    fn = compile_broadcast()
    print("Compile kernel (broadcast) OK", flush=True)

    for src_lane in (7, 15):
        dst, src = run_broadcast(fn, src_lane=src_lane)
        print(f"Run kernel (broadcast, src_lane={src_lane}) OK", flush=True)
        expected = torch.full((_WARP_SIZE,), src_lane, dtype=torch.int32, device="cuda")
        torch.testing.assert_close(dst, expected, atol=0, rtol=0)
        print(
            f"verify (broadcast, src_lane={src_lane}, "
            f"all lanes got {dst[0].item()}): PASS"
        )


# =============================================================================
# Kernel 2 — prims.Shfl.BFLY: butterfly XOR reduction (warp sum)
#
# Classic butterfly reduction: offset = 16, 8, 4, 2, 1.
# After 5 steps every lane holds the warp-wide sum.
# =============================================================================


@cute.kernel
def bfly_sum_kernel(
    vals_arr: cutlass.Array,  # [WARP_SIZE]  Int32 — one value per lane
    res_arr: cutlass.Array,  # [1]          Int32 — warp sum (written by lane 0)
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Compute warp sum with a 5-step butterfly (``prims.Shfl.BFLY``).

    ``res_arr[0]`` receives the sum; all lanes hold the same sum after the
    final step, but only lane 0 writes it to avoid redundant stores.

    :param vals_arr: Per-lane inputs.
    :type vals_arr: cutlass.Array
    :param res_arr: Output scalar (lane 0 writes).
    :type res_arr: cutlass.Array
    :param WARP_SIZE_C: Compile-time warp size.
    :type WARP_SIZE_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    acc = vals_arr[tidx]

    # ------------------------------------------------------------------
    # prims.Shfl.BFLY — source lane = (this lane) XOR offset.
    # mask_and_clamp = 0x1F: full 32-lane warp, no clamping needed for XOR.
    # Five steps halve the distance each time: 16→8→4→2→1.
    # ------------------------------------------------------------------
    for delta in [16, 8, 4, 2, 1]:
        other = prims.shfl_sync(
            _FULL_MASK,
            acc,
            delta,  # XOR mask
            _MAC_IDX_DOWN_BFLY,
            prims.Shfl.BFLY,
        )
        acc = acc + other

    # All lanes hold the warp sum; lane 0 is elected to write.
    if tidx == 0:
        res_arr[0] = acc


@cute.jit
def bfly_sum_host(
    vals: cutlass.Array,
    result: cutlass.Array,
    stream,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch :func:`bfly_sum_kernel` over one warp."""
    bfly_sum_kernel(vals, result, WARP_SIZE_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_bfly_sum(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile the butterfly reduction kernel.

    :param WARP_SIZE_C: Warp size baked at compile time.
    :type WARP_SIZE_C: int
    :return: Compiled callable; runtime signature ``(vals, result, stream)``.
    :rtype: Callable
    """
    fake_vals = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    fake_res = make_fake_compact_tensor(cutlass.Int32, (1,), assumed_align=4)
    return cute.compile(
        bfly_sum_host,
        fake_vals,
        fake_res,
        make_fake_stream(),
        WARP_SIZE_C,
        options="--enable-tvm-ffi",
    )


def run_bfly_sum(fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(result, vals)``.

    Input values are ``0, 1, …, 31`` (lane indices); expected sum = 496.

    :param fn: Compiled callable from :func:`compile_bfly_sum`.
    :type fn: Callable
    :return: ``(result, vals)`` — scalar output tensor and input tensor.
    :rtype: tuple[torch.Tensor, torch.Tensor]
    """
    vals = torch.arange(_WARP_SIZE, dtype=torch.int32, device="cuda")
    result = torch.zeros(1, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(vals, result, stream)
    torch.cuda.synchronize()
    return result, vals


def verify_bfly_sum() -> None:
    """Compile, run, and assert butterfly sum equals torch reference.

    :raises AssertionError: If the warp sum is incorrect.
    """
    fn = compile_bfly_sum()
    print("Compile kernel (bfly_sum) OK", flush=True)

    result, vals = run_bfly_sum(fn)
    print("Run kernel (bfly_sum, vals=0..31) OK", flush=True)

    # torch.sum on int32 promotes to int64 by default; pin it back to int32
    # so the comparison matches `result`'s dtype.
    expected = vals.sum(dtype=torch.int32).unsqueeze(0)  # 0+1+…+31 = 496
    torch.testing.assert_close(result, expected, atol=0, rtol=0)
    print(f"verify (bfly_sum, sum={result.item()}): PASS")


# =============================================================================
# Kernel 3 — prims.Shfl.UP: up-shift scan + is_valid predicate
#
# Each lane reads from lane (this_lane - delta).  Lanes where the source
# would underflow (lane < delta) get a clamped value AND is_valid=False.
# Demonstrates return_value_and_is_valid=True.
# =============================================================================


@cute.kernel
def up_shift_kernel(
    vals_arr: cutlass.Array,  # [WARP_SIZE]  Float32
    shifted_arr: cutlass.Array,  # [WARP_SIZE]  Float32 — value from lane-1
    valid_arr: cutlass.Array,  # [WARP_SIZE]  Int32   — 1 if source lane in range
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Shift values up by 1 lane and report validity via ``prims.Shfl.UP``.

    Lane *i* reads from lane *i-1*.  Lane 0 reads from a clamped source
    (itself, since ``mask_and_clamp=0x00`` clamps the lower boundary to 0),
    and ``is_valid`` for lane 0 is ``False``.

    :param vals_arr: Per-lane float inputs.
    :type vals_arr: cutlass.Array
    :param shifted_arr: Output — each lane holds the value from (lane - 1).
    :type shifted_arr: cutlass.Array
    :param valid_arr: Output — 1 if the source lane was in range, 0 otherwise.
    :type valid_arr: cutlass.Array
    :param WARP_SIZE_C: Compile-time warp size.
    :type WARP_SIZE_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    my_val = vals_arr[tidx]

    # ------------------------------------------------------------------
    # prims.Shfl.UP — source lane = (this lane) - delta.
    # mask_and_clamp = 0x00: lower clamp boundary = 0 (lane 0 clamps to 0).
    # return_value_and_is_valid=True: also return the validity predicate.
    # ------------------------------------------------------------------
    src_val, is_valid = prims.shfl_sync(
        _FULL_MASK,
        my_val,
        1,  # delta = 1: shift up by one lane
        _MAC_UP,
        prims.Shfl.UP,
        return_value_and_is_valid=True,
    )

    shifted_arr[tidx] = src_val
    # Store validity as Int32 (1 = valid, 0 = clamped / out-of-range)
    valid_arr[tidx] = is_valid


@cute.jit
def up_shift_host(
    vals: cutlass.Array,
    shifted: cutlass.Array,
    valid: cutlass.Array,
    stream,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch :func:`up_shift_kernel` over one warp."""
    up_shift_kernel(vals, shifted, valid, WARP_SIZE_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_up_shift(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile the up-shift kernel.

    :param WARP_SIZE_C: Warp size baked at compile time.
    :type WARP_SIZE_C: int
    :return: Compiled callable; runtime signature
        ``(vals, shifted, valid, stream)``.
    :rtype: Callable
    """
    fake_f32 = make_fake_compact_tensor(
        cutlass.Float32, (WARP_SIZE_C,), assumed_align=4
    )
    fake_i32 = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    return cute.compile(
        up_shift_host,
        fake_f32,
        fake_f32,
        fake_i32,
        make_fake_stream(),
        WARP_SIZE_C,
        options="--enable-tvm-ffi",
    )


def run_up_shift(fn: Callable) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(shifted, valid, vals)``.

    Input values are ``0.0, 1.0, …, 31.0``.

    :param fn: Compiled callable from :func:`compile_up_shift`.
    :type fn: Callable
    :return: ``(shifted, valid, vals)`` — shifted tensor, validity mask, input.
    :rtype: tuple[torch.Tensor, torch.Tensor, torch.Tensor]
    """
    vals = torch.arange(_WARP_SIZE, dtype=torch.float32, device="cuda")
    shifted = torch.zeros(_WARP_SIZE, dtype=torch.float32, device="cuda")
    valid = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(vals, shifted, valid, stream)
    torch.cuda.synchronize()
    return shifted, valid, vals


def verify_up_shift() -> None:
    """Compile, run, and assert up-shift values and validity predicate.

    Lane 0 should be invalid (source lane = -1 clamped to 0, is_valid=False).
    Lanes 1..31 should receive the value from lane-1 (is_valid=True).

    :raises AssertionError: If any shifted value or validity flag is wrong.
    """
    fn = compile_up_shift()
    print("Compile kernel (up_shift) OK", flush=True)

    shifted, valid, vals = run_up_shift(fn)
    print("Run kernel (up_shift, vals=0.0..31.0) OK", flush=True)

    # Lane 0: source clamped to lane 0 itself — value = 0.0, is_valid = 0
    # Lanes 1..31: source = lane-1 — value = float(lane-1), is_valid = 1
    expected_shifted = torch.cat(
        [torch.tensor([0.0], dtype=torch.float32), vals[:-1].cpu()]
    ).to("cuda")
    expected_valid = torch.cat(
        [
            torch.tensor([0], dtype=torch.int32),
            torch.ones(_WARP_SIZE - 1, dtype=torch.int32),
        ]
    ).to("cuda")

    torch.testing.assert_close(shifted, expected_shifted, atol=0.0, rtol=0)
    torch.testing.assert_close(valid, expected_valid, atol=0, rtol=0)
    print(
        f"verify (up_shift, "
        f"lane0_valid={valid[0].item()}, lane1_src={shifted[1].item():.1f}): PASS"
    )


# =============================================================================
# Kernel 4 — prims.Shfl.DOWN with sub-warp segmentation
#
# Divides the 32-lane warp into segments of width=8 (four segments of 8 lanes).
# Each segment shuffles independently; lanes near the high end of each segment
# clamp to the last lane of the same segment.
# =============================================================================

_SEG_WIDTH: int = 8  # lanes per segment (compile-time constant)


def _compute_mac_down(width: int) -> int:
    """Return mask_and_clamp for prims.Shfl.DOWN with given sub-warp width.

    Encodes: segmask = (WARP_SIZE - 1) XOR (width - 1), clamp = width - 1.

    :param width: Sub-warp segment width (power of 2, 1–32).
    :type width: int
    :return: Packed mask_and_clamp integer.
    :rtype: int
    """
    segmask = (_WARP_SIZE - 1) ^ (width - 1)
    clamp = width - 1
    return (segmask << 8) | clamp


@cute.kernel
def down_shift_segmented_kernel(
    vals_arr: cutlass.Array,  # [WARP_SIZE]  Int32
    shifted_arr: cutlass.Array,  # [WARP_SIZE]  Int32 — value from (lane + delta)
    valid_arr: cutlass.Array,  # [WARP_SIZE]  Int32 — 1 if source lane in range
    mac: cutlass.Int32,  # pre-computed mask_and_clamp (runtime)
    SEG_WIDTH_C: cutlass.Constexpr,
):
    """Shift values down by 1 lane within 8-lane segments via ``prims.Shfl.DOWN``.

    Each of the four 8-lane segments shuffles independently.  Lanes at the
    high end of each segment (``lane % SEG_WIDTH_C == SEG_WIDTH_C - 1``)
    clamp to themselves and return ``is_valid=False``.

    :param vals_arr: Per-lane inputs.
    :type vals_arr: cutlass.Array
    :param shifted_arr: Output — each lane holds the value from (lane + 1) in the
        same segment.
    :type shifted_arr: cutlass.Array
    :param valid_arr: Output — 1 if source lane in segment, 0 if clamped.
    :type valid_arr: cutlass.Array
    :param mac: Packed mask_and_clamp for ``width=SEG_WIDTH_C`` down-shuffle.
    :type mac: cutlass.Int32
    :param SEG_WIDTH_C: Compile-time segment width.
    :type SEG_WIDTH_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    my_val = vals_arr[tidx]

    # ------------------------------------------------------------------
    # prims.Shfl.DOWN — source lane = min(this lane + delta, clamp).
    # Sub-warp segmentation: mac encodes both the segment mask (bits [12:8])
    # and the per-segment clamp boundary (bits [4:0]).
    # return_value_and_is_valid=True: also return the validity predicate.
    # ------------------------------------------------------------------
    src_val, is_valid = prims.shfl_sync(
        _FULL_MASK,
        my_val,
        1,  # delta = 1
        mac,  # pre-computed mask_and_clamp (runtime)
        prims.Shfl.DOWN,
        return_value_and_is_valid=True,
    )

    shifted_arr[tidx] = src_val
    valid_arr[tidx] = is_valid


@cute.jit
def down_shift_segmented_host(
    vals: cutlass.Array,
    shifted: cutlass.Array,
    valid: cutlass.Array,
    stream,
    mac: cutlass.Int32,
    SEG_WIDTH_C: cutlass.Constexpr,
):
    """Launch :func:`down_shift_segmented_kernel` over one warp."""
    down_shift_segmented_kernel(vals, shifted, valid, mac, SEG_WIDTH_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_down_shift_segmented(SEG_WIDTH_C: int = _SEG_WIDTH) -> Callable:
    """AOT-compile the segmented down-shift kernel.

    ``SEG_WIDTH_C`` is baked at compile time; ``mac`` remains a runtime
    ``cutlass.Int32`` so the same binary can handle different sub-warp widths.

    :param SEG_WIDTH_C: Segment width baked at compile time.
    :type SEG_WIDTH_C: int
    :return: Compiled callable; runtime signature
        ``(vals, shifted, valid, stream, mac)``.
    :rtype: Callable
    """
    fake_i32 = make_fake_compact_tensor(cutlass.Int32, (_WARP_SIZE,), assumed_align=4)
    return cute.compile(
        down_shift_segmented_host,
        fake_i32,
        fake_i32,
        fake_i32,
        make_fake_stream(),
        0,  # mac — symbolic runtime arg
        SEG_WIDTH_C,  # SEG_WIDTH_C — baked as Constexpr
        options="--enable-tvm-ffi",
    )


def run_down_shift_segmented(
    fn: Callable,
    seg_width: int = _SEG_WIDTH,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(shifted, valid, vals)``.

    Input values are lane indices ``0, 1, …, 31``.

    :param fn: Compiled callable from :func:`compile_down_shift_segmented`.
    :type fn: Callable
    :param seg_width: Segment width for mask_and_clamp computation.
    :type seg_width: int
    :return: ``(shifted, valid, vals)`` — output tensors and input.
    :rtype: tuple[torch.Tensor, torch.Tensor, torch.Tensor]
    """
    vals = torch.arange(_WARP_SIZE, dtype=torch.int32, device="cuda")
    shifted = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    valid = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    mac = _compute_mac_down(seg_width)
    fn(vals, shifted, valid, stream, mac)
    torch.cuda.synchronize()
    return shifted, valid, vals


def verify_down_shift_segmented() -> None:
    """Compile, run (two seg_width variants), and assert results.

    Demonstrates runtime re-parameterisation of ``mac``:
    ``seg_width=8`` and ``seg_width=16`` run without recompilation.

    :raises AssertionError: If any shifted value or validity flag is wrong.
    """
    fn = compile_down_shift_segmented()
    print("Compile kernel (down_shift_segmented) OK", flush=True)

    for seg_width in (8, 16):
        shifted, valid, vals = run_down_shift_segmented(fn, seg_width=seg_width)
        print(
            f"Run kernel (down_shift_segmented, seg_width={seg_width}) OK",
            flush=True,
        )

        # Within each segment of `seg_width` lanes:
        #   lane i → reads from lane i+1 of same segment (if i+1 < seg_width)
        #   last lane in segment → clamped (reads self, is_valid=0)
        expected_shifted = vals.clone().cpu()
        expected_valid = torch.ones(_WARP_SIZE, dtype=torch.int32)
        for seg_start in range(0, _WARP_SIZE, seg_width):
            seg_end = seg_start + seg_width - 1
            for i in range(seg_start, seg_end):
                expected_shifted[i] = i + 1  # lane i+1 in same segment
            expected_shifted[seg_end] = seg_end  # clamped: reads self
            expected_valid[seg_end] = 0

        expected_shifted = expected_shifted.to("cuda")
        expected_valid = expected_valid.to("cuda")

        torch.testing.assert_close(shifted, expected_shifted, atol=0, rtol=0)
        torch.testing.assert_close(valid, expected_valid, atol=0, rtol=0)
        print(
            f"verify (down_shift_segmented, seg_width={seg_width}, "
            f"lane0={shifted[0].item()}, lane{seg_width - 1}={shifted[seg_width - 1].item()}, "
            f"valid{seg_width - 1}={valid[seg_width - 1].item()}): PASS"
        )


# =============================================================================
# Top-level verify
# =============================================================================


def verify(kernel: str = "all") -> None:
    """Run the selected kernel verification(s).

    :param kernel: ``"1"``–``"4"`` for a single kernel, ``"all"`` for all four.
    :type kernel: str
    :raises ValueError: If ``kernel`` is not in ``{"1", "2", "3", "4", "all"}``.
    :raises RuntimeError: If CUDA is unavailable.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA device required")

    run_map = {
        "1": verify_broadcast,
        "2": verify_bfly_sum,
        "3": verify_up_shift,
        "4": verify_down_shift_segmented,
    }
    if kernel not in run_map and kernel != "all":
        raise ValueError(
            f"kernel must be one of {list(run_map) + ['all']}, got {kernel!r}"
        )

    for k, fn in run_map.items():
        if kernel != "all" and k != kernel:
            continue
        fn()


# =============================================================================
# Entry point
# =============================================================================

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="shfl.sync — warp-level shuffle examples (all four ShflKind variants)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--kernel",
        type=str,
        default="all",
        choices=["1", "2", "3", "4", "all"],
        help=(
            "kernel to run: "
            "1=broadcast      [prims.Shfl.IDX,  sm_70+], "
            "2=bfly_sum       [prims.Shfl.BFLY, sm_70+], "
            "3=up_shift       [prims.Shfl.UP,   sm_70+], "
            "4=down_segmented [prims.Shfl.DOWN, sm_70+], "
            "all=run all four kernels"
        ),
    )
    args = p.parse_args()
    verify(args.kernel)
