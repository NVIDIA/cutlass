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

"""
redux.sync — Hardware warp reduction in CUTLASS DSL.

Demonstrates:

  - :func:`~cutlass.primitives.redux_sync` with all eight integer ops (``ADD``, ``MIN``,
    ``MAX``, ``AND``, ``OR``, ``XOR``, ``UMIN``, ``UMAX``) — a single
    ``redux.sync.{op}.{s32|u32}`` instruction; all 32 lanes receive the same
    broadcast result.
  - :func:`~cutlass.primitives.redux_sync` with ``FMIN`` / ``FMAX`` and the ``abs=True``
    modifier (sm_100a/sm_103a/sm_107a only) — ``redux.sync.{min|max}.abs.f32``;
    replaces a 5-step butterfly shuffle loop with one instruction.
  - Side-by-side: :func:`~cutlass.primitives.redux_sync` (1 instruction,
    sm_100a/sm_103a/sm_107a only) vs
    :func:`~cutlass.shuffle_sync_down` butterfly loop (5 instructions, sm_80+);
    both produce identical abs-max results.
  - Per-block abs-max → FP8 quantization (sm_100a/sm_103a/sm_107a only): the MXFP8 pattern from
    ``kgen/examples/sm100/perfbot/5_gelu_mxfp8.py``.

Four kernels, each with a dedicated ``compile_*()``, ``run_*()``,
and ``verify_*()`` following the canonical kernel template.

Naming convention (enforced throughout):

  ``lower_case`` params → ``cutlass.Int32``    → runtime, vary freely
  ``UPPER_CASE`` params → ``cutlass.Constexpr`` → baked at ``cute.compile`` time

PTX reference: §9.7.13.12 ``redux.sync``
API reference: ``cutlass/primitives warp-vote helpers``,
               ``cutlass/primitives wrappers``

Requires SM80+ for integer ops. FMIN/FMAX, including ``abs`` / ``nan``
modifiers, require sm_100a/sm_103a/sm_107a.

To run::

    python CuTeDSL/experimental/primitives/redux_sync.py                  # all four kernels (skips fp redux kernels on older HW)
    python CuTeDSL/experimental/primitives/redux_sync.py --kernel 1       # integer reductions (sm_80+)
    python CuTeDSL/experimental/primitives/redux_sync.py --kernel 4       # FP8 quantization   (sm_100a/sm_103a/sm_107a only)

"""

import cutlass
import argparse
import functools
import operator
from functools import lru_cache
from typing import Callable

import torch
import cuda.bindings.driver as cuda

import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Fixed kernel configurations (baked at compile time — not user-tunable)
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # threads per block for all four kernels (Constexpr)

# ---------------------------------------------------------------------------
# Kernel 4 — tunable compile-time parameter
# ---------------------------------------------------------------------------

_FP8_MAX: float = 448.0  # Float8E4M3FN max representable value (E4M3)

# ---------------------------------------------------------------------------
# Default problem sizes (runtime — vary freely without recompilation)
# ---------------------------------------------------------------------------

_DEFAULT_NUM_ROWS: int = 8  # batch rows for Kernel 4


# =============================================================================
# Kernel 1 — Integer Reductions
# =============================================================================


@cute.kernel
def integer_reductions_kernel(
    vals_arr: cutlass.Array,  # [_WARP_SIZE] Int32 — one value per lane
    out_arr: cutlass.Array,  # [8] Int32 — [ADD, MIN, MAX, AND, OR, XOR, UMIN, UMAX]
):
    """Apply all eight integer redux ops across a full 32-lane warp.

    Each :func:`~cutlass.primitives.redux_sync` call emits a single
    ``redux.sync.{op}.{s32|u32}`` instruction.  All participating lanes
    receive the same broadcast result; lane 0 writes the eight outputs.

    :param vals_arr: Input values, one per lane.
    :type vals_arr: cutlass.Array
    :param out_arr: Output array of eight reduced values.
    :type out_arr: cutlass.Array
    """
    tidx, _, _ = cute.arch.thread_idx()

    v = vals_arr[tidx]

    add_r = prims.redux_sync(
        v, prims.ReductionKind.ADD, 0xFFFFFFFF
    )  # wrapping signed sum
    min_r = prims.redux_sync(v, prims.ReductionKind.MIN, 0xFFFFFFFF)  # signed min
    max_r = prims.redux_sync(v, prims.ReductionKind.MAX, 0xFFFFFFFF)  # signed max
    and_r = prims.redux_sync(v, prims.ReductionKind.AND, 0xFFFFFFFF)  # bitwise AND
    or_r = prims.redux_sync(v, prims.ReductionKind.OR, 0xFFFFFFFF)  # bitwise OR
    xor_r = prims.redux_sync(v, prims.ReductionKind.XOR, 0xFFFFFFFF)  # bitwise XOR
    umin_r = prims.redux_sync(v, prims.ReductionKind.UMIN, 0xFFFFFFFF)  # unsigned min
    umax_r = prims.redux_sync(v, prims.ReductionKind.UMAX, 0xFFFFFFFF)  # unsigned max

    if tidx == 0:
        out_arr[0] = add_r
        out_arr[1] = min_r
        out_arr[2] = max_r
        out_arr[3] = and_r
        out_arr[4] = or_r
        out_arr[5] = xor_r
        out_arr[6] = umin_r
        out_arr[7] = umax_r


@cute.jit
def integer_reductions_host(
    vals: cutlass.Array,
    results: cutlass.Array,
    stream,
):
    """Launch :func:`integer_reductions_kernel` over one warp."""
    integer_reductions_kernel(vals, results).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_integer_reductions() -> Callable:
    """AOT-compile :func:`integer_reductions_host` for a fixed 32-element warp.

    :return: Compiled callable; runtime signature ``(vals, results, stream)``.
    :rtype: Callable
    """
    fake_vals = make_fake_compact_tensor(cutlass.Int32, (_WARP_SIZE,), assumed_align=4)
    fake_results = make_fake_compact_tensor(cutlass.Int32, (8,), assumed_align=4)
    return cute.compile(
        integer_reductions_host,
        fake_vals,
        fake_results,
        make_fake_stream(),
        options="--enable-tvm-ffi",
    )


def run_integer_reductions(fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(results, vals)``.

    Input values are ``0, 1, …, 31`` (lane indices).

    :param fn: Compiled callable from :func:`compile_integer_reductions`.
    :type fn: Callable
    :return: ``(results, vals)`` — GPU output tensor and input tensor.
    :rtype: tuple[torch.Tensor, torch.Tensor]
    """
    vals = torch.arange(0, _WARP_SIZE, dtype=torch.int32, device="cuda")
    results = torch.zeros(8, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(vals, results, stream)
    torch.cuda.synchronize()
    return results, vals


def verify_integer_reductions() -> None:
    """Compile, run, and assert all eight integer redux ops match torch reference.

    :raises AssertionError: If any op result does not match the reference.
    """
    fn = compile_integer_reductions()
    print("Compile kernel (integer_reductions) OK", flush=True)

    results, vals = run_integer_reductions(fn)
    print("Run kernel (integer_reductions, vals=0..31) OK", flush=True)

    v = vals.tolist()
    expected = torch.tensor(
        [
            sum(v),  # ADD  — 0+1+…+31 = 496
            min(v),  # MIN  — 0
            max(v),  # MAX  — 31
            functools.reduce(operator.and_, v),  # AND  — 0  (lane 0 = 0)
            functools.reduce(operator.or_, v),  # OR   — 31 (bits 0–4 all set)
            functools.reduce(operator.xor, v),  # XOR  — 0  (XOR of 0..31)
            min(v),  # UMIN — 0  (same as MIN for non-negative)
            max(v),  # UMAX — 31 (same as MAX for non-negative)
        ],
        dtype=torch.int32,
        device="cuda",
    )
    torch.testing.assert_close(results, expected, atol=0, rtol=0)
    print(
        f"verify (integer_reductions, "
        f"ADD={results[0].item()}, MIN={results[1].item()}, MAX={results[2].item()}): PASS"
    )


# =============================================================================
# Kernel 2 — Float Reductions (FMIN / FMAX / abs modifier)
# =============================================================================


@cute.kernel
def float_reductions_kernel(
    vals_arr: cutlass.Array,  # [_WARP_SIZE] Float32
    out_arr: cutlass.Array,  # [4] Float32 — [FMIN, FMAX, abs_FMAX, abs_FMIN]
):
    """Reduce ``vals_arr`` with FMIN / FMAX, with and without the ``abs`` modifier.

    ``abs=True`` applies ``|value|`` before each lane's contribution, so
    ``FMAX`` with ``abs`` returns ``max(|v_0|, …, |v_31|)`` (warp abs-max) in
    a single ``redux.sync.max.abs.f32`` instruction (sm_100a/sm_103a/sm_107a only).

    :param vals_arr: Input float values, one per lane.
    :type vals_arr: cutlass.Array
    :param out_arr: Output array of four reduced float values.
    :type out_arr: cutlass.Array
    """
    tidx, _, _ = cute.arch.thread_idx()

    v = vals_arr[tidx]

    fmin_r = prims.redux_sync(v, prims.ReductionKind.FMIN, 0xFFFFFFFF)
    fmax_r = prims.redux_sync(v, prims.ReductionKind.FMAX, 0xFFFFFFFF)
    # abs=True: each lane's |v| is used before the reduction
    # (sm_100a/sm_103a/sm_107a only).
    absmax_r = prims.redux_sync(
        v, prims.ReductionKind.FMAX, 0xFFFFFFFF, abs=True
    )  # max(|v|)
    absmin_r = prims.redux_sync(
        v, prims.ReductionKind.FMIN, 0xFFFFFFFF, abs=True
    )  # min(|v|)

    if tidx == 0:
        out_arr[0] = fmin_r
        out_arr[1] = fmax_r
        out_arr[2] = absmax_r
        out_arr[3] = absmin_r


@cute.jit
def float_reductions_host(
    vals: cutlass.Array,
    results: cutlass.Array,
    stream,
):
    """Launch :func:`float_reductions_kernel` over one warp."""
    float_reductions_kernel(vals, results).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_float_reductions() -> Callable:
    """AOT-compile :func:`float_reductions_host` for a fixed 32-element warp.

    :return: Compiled callable; runtime signature ``(vals, results, stream)``.
    :rtype: Callable
    """
    fake_vals = make_fake_compact_tensor(
        cutlass.Float32, (_WARP_SIZE,), assumed_align=4
    )
    fake_results = make_fake_compact_tensor(cutlass.Float32, (4,), assumed_align=4)
    return cute.compile(
        float_reductions_host,
        fake_vals,
        fake_results,
        make_fake_stream(),
        options="--enable-tvm-ffi",
    )


def run_float_reductions(fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(results, vals)``.

    Input values are ``-15.5, -14.5, …, 14.5, 15.5`` (32 evenly-spaced floats
    centred at zero so abs-max and abs-min are non-trivial).

    :param fn: Compiled callable from :func:`compile_float_reductions`.
    :type fn: Callable
    :return: ``(results, vals)`` — GPU output tensor and input tensor.
    :rtype: tuple[torch.Tensor, torch.Tensor]
    """
    vals = torch.linspace(-15.5, 15.5, _WARP_SIZE, dtype=torch.float32, device="cuda")
    results = torch.zeros(4, dtype=torch.float32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(vals, results, stream)
    torch.cuda.synchronize()
    return results, vals


def verify_float_reductions() -> None:
    """Compile, run, and assert FMIN/FMAX and abs results match torch reference.

    :raises AssertionError: If any result deviates from the reference by more
        than 1e-5.
    """
    fn = compile_float_reductions()
    print("Compile kernel (float_reductions) OK", flush=True)

    results, vals = run_float_reductions(fn)
    print("Run kernel (float_reductions, vals=-15.5..15.5) OK", flush=True)

    expected = torch.stack(
        [
            vals.min(),  # FMIN    — -15.5
            vals.max(),  # FMAX    —  15.5
            vals.abs().max(),  # abs_FMAX —  15.5
            vals.abs().min(),  # abs_FMIN —   0.5
        ]
    )
    torch.testing.assert_close(results, expected, atol=1e-5, rtol=0)
    print(
        f"verify (float_reductions, "
        f"FMIN={results[0].item():.1f}, FMAX={results[1].item():.1f}, "
        f"abs_FMAX={results[2].item():.1f}, abs_FMIN={results[3].item():.1f}): PASS"
    )


# =============================================================================
# Kernel 3 — redux_sync vs Butterfly Shuffle
# =============================================================================


@cute.kernel
def redux_vs_shuffle_kernel(
    vals_arr: cutlass.Array,  # [_WARP_SIZE] Float32
    redux_arr: cutlass.Array,  # [1] Float32 — abs-max from redux_sync
    shuffle_arr: cutlass.Array,  # [1] Float32 — abs-max from butterfly shuffle
):
    """Compute warp abs-max by two methods and write both results.

    *Method A* (:func:`~cutlass.primitives.redux_sync`, 1 instruction,
    sm_100a/sm_103a/sm_107a):
    ``redux.sync.max.abs.f32``

    *Method B* (butterfly shuffle, 5 instructions + broadcast, sm_80+):
    :func:`~cutlass.shuffle_sync_down` loop over offsets ``[16, 8, 4, 2, 1]``
    followed by :func:`~cutlass.shuffle_sync` to broadcast lane 0 to all lanes.

    Both methods produce the same result; Method A is preferred for its
    lower instruction count and register pressure.

    :param vals_arr: Input float values, one per lane.
    :type vals_arr: cutlass.Array
    :param redux_arr: Scalar output — abs-max from :func:`~cutlass.primitives.redux_sync`.
    :type redux_arr: cutlass.Array
    :param shuffle_arr: Scalar output — abs-max from butterfly shuffle.
    :type shuffle_arr: cutlass.Array
    """
    tidx, _, _ = cute.arch.thread_idx()

    v = vals_arr[tidx]

    # ── Method A: hardware redux (sm_100a/sm_103a/sm_107a) ───────────────────
    absmax_redux = prims.redux_sync(v, prims.ReductionKind.FMAX, 0xFFFFFFFF, abs=True)

    # ── Method B: butterfly shuffle (sm_80+) ─────────────────────────────────
    # abs(v) via sign-flip: max(v, 0 - v)
    absval = cute.math.max(v, 0.0 - v)
    for offset in [16, 8, 4, 2, 1]:
        other = cute.arch.shuffle_sync_down(absval, offset)
        absval = cute.math.max(absval, other)
    absmax_shuffle = cute.arch.shuffle_sync(absval, 0)  # broadcast lane 0 → all lanes

    if tidx == 0:
        redux_arr[0] = absmax_redux
        shuffle_arr[0] = absmax_shuffle


@cute.jit
def redux_vs_shuffle_host(
    vals: cutlass.Array,
    out_redux: cutlass.Array,
    out_shuffle: cutlass.Array,
    stream,
):
    """Launch :func:`redux_vs_shuffle_kernel` over one warp."""
    redux_vs_shuffle_kernel(vals, out_redux, out_shuffle).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_redux_vs_shuffle() -> Callable:
    """AOT-compile :func:`redux_vs_shuffle_host` for a fixed 32-element warp.

    :return: Compiled callable; runtime signature
        ``(vals, out_redux, out_shuffle, stream)``.
    :rtype: Callable
    """
    fake_vals = make_fake_compact_tensor(
        cutlass.Float32, (_WARP_SIZE,), assumed_align=4
    )
    fake_out = make_fake_compact_tensor(cutlass.Float32, (1,), assumed_align=4)
    return cute.compile(
        redux_vs_shuffle_host,
        fake_vals,
        fake_out,
        fake_out,
        make_fake_stream(),
        options="--enable-tvm-ffi",
    )


def run_redux_vs_shuffle(
    fn: Callable,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``(out_redux, out_shuffle, vals)``.

    Uses 32 random floats seeded at 42.

    :param fn: Compiled callable from :func:`compile_redux_vs_shuffle`.
    :type fn: Callable
    :return: ``(out_redux, out_shuffle, vals)`` — both GPU abs-max results and
        the input tensor (for computing the torch reference).
    :rtype: tuple[torch.Tensor, torch.Tensor, torch.Tensor]
    """
    torch.manual_seed(42)
    vals = torch.randn(_WARP_SIZE, dtype=torch.float32, device="cuda")
    out_redux = torch.zeros(1, dtype=torch.float32, device="cuda")
    out_shuffle = torch.zeros(1, dtype=torch.float32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(vals, out_redux, out_shuffle, stream)
    torch.cuda.synchronize()
    return out_redux, out_shuffle, vals


def verify_redux_vs_shuffle() -> None:
    """Compile, run, and assert both abs-max methods agree exactly, and match torch.

    :raises AssertionError: If the two methods differ, or if either deviates
        from the torch reference abs-max by more than 1e-5.
    """
    fn = compile_redux_vs_shuffle()
    print("Compile kernel (redux_vs_shuffle) OK", flush=True)

    out_redux, out_shuffle, vals = run_redux_vs_shuffle(fn)
    print("Run kernel (redux_vs_shuffle, vals=randn(seed=42)) OK", flush=True)

    # Both hardware methods must produce the same bits (exact match).
    torch.testing.assert_close(out_redux, out_shuffle, atol=0, rtol=0)
    # Both must match the torch reference abs-max.
    ref = vals.abs().max().unsqueeze(0)
    torch.testing.assert_close(out_redux, ref, atol=1e-5, rtol=0)
    print(
        f"verify (redux_vs_shuffle, ref={ref.item():.4f}, "
        f"redux={out_redux.item():.4f}, shuffle={out_shuffle.item():.4f}): PASS"
    )


# =============================================================================
# Kernel 4 — Per-Block Abs-Max → FP8 Quantization (sm_100a/sm_103a/sm_107a)
# =============================================================================


@cute.kernel
def absmax_quantize_kernel(
    inp: cute.Tensor,  # [num_rows, _WARP_SIZE] BF16
    fp8_arr: cutlass.Array,  # [num_rows, _WARP_SIZE] Float8E4M3FN
    scales_arr: cutlass.Array,  # [num_rows] Float32 — dequant scale = amax / FP8_MAX
    FP8_MAX_C: cutlass.Constexpr,
):
    """Quantize each 32-element BF16 row to FP8 using a per-row abs-max scale.

    One thread block per row, one warp per block: each of the 32 lanes owns one element.

    The per-row abs-max is computed with a single
    ``redux.sync.max.abs.f32`` instruction (sm_100a/sm_103a/sm_107a only), avoiding a
    5-step
    butterfly shuffle.  This is the MXFP8 block-quantization pattern used in
    ``kgen/examples/sm100/perfbot/5_gelu_mxfp8.py``, lines 152–159.

    :param inp: Input activations in BF16, shape ``[num_rows, _WARP_SIZE]``.
    :type inp: cute.Tensor
    :param fp8_arr: Quantized output in Float8E4M3FN.
    :type fp8_arr: cutlass.Array
    :param scales_arr: Per-row dequantization scales (``amax / FP8_MAX``).
    :type scales_arr: cutlass.Array
    :param FP8_MAX_C: Maximum representable FP8 value (448.0 for E4M3).
    :type FP8_MAX_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()
    row, _, _ = cute.arch.block_idx()

    inp_arr = cutlass.make_array_view(inp)

    fp8_max = FP8_MAX_C
    inv_fp8_max = 1.0 / FP8_MAX_C

    # Step 1: load BF16 element and widen to FP32
    x = inp_arr[row, tidx].to(cutlass.Float32)

    # Step 2: warp abs-max — single ``redux.sync.max.abs.f32``
    # (sm_100a/sm_103a/sm_107a only)
    amax = prims.redux_sync(x, prims.ReductionKind.FMAX, 0xFFFFFFFF, abs=True)

    # Step 3: guard against zero-valued rows; compute inverse scale
    safe_amax = cute.math.max(amax, 1e-12)
    inv_scale = (
        cute.math.rcp(safe_amax, approx=True, ftz=True) * fp8_max
    )  # = FP8_MAX / amax

    # Step 4: quantize — F2FP.SATFINITE saturates to ±448 automatically
    fp8_arr[row, tidx] = (x * inv_scale).to(cutlass.Float8E4M3FN)

    # Step 5: lane 0 writes the per-row dequantization scale
    if tidx == 0:
        scales_arr[row] = safe_amax * inv_fp8_max


@cute.jit
def absmax_quantize_host(
    inp: cute.Tensor,
    fp8_out: cutlass.Array,
    scales: cutlass.Array,
    stream,
    FP8_MAX_C: cutlass.Constexpr,
):
    """Launch :func:`absmax_quantize_kernel`; one thread block per row."""
    num_rows = inp.shape[0]
    absmax_quantize_kernel(inp, fp8_out, scales, FP8_MAX_C).launch(
        grid=(num_rows, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_absmax_quantize() -> Callable:
    """AOT-compile :func:`absmax_quantize_host`; ``num_rows`` stays symbolic.

    ``_WARP_SIZE`` (32) and ``_FP8_MAX`` (448.0) are baked as
    ``cutlass.Constexpr``; ``num_rows`` is kept as a runtime ``cutlass.Int32`` via
    ``cute.sym_int64()`` so the binary accepts any batch size without
    recompilation.

    :return: Compiled callable; runtime signature
        ``(inp, fp8_out, scales, stream)``.
    :rtype: Callable
    """
    sym_rows = cute.sym_int64()
    fake_inp = make_fake_compact_tensor(
        cutlass.BFloat16, (sym_rows, _WARP_SIZE), stride_order=(1, 0), assumed_align=2
    )
    fake_fp8 = make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (sym_rows, _WARP_SIZE),
        stride_order=(1, 0),
        assumed_align=1,
    )
    fake_sc = make_fake_compact_tensor(cutlass.Float32, (sym_rows,), assumed_align=4)
    return cute.compile(
        absmax_quantize_host,
        fake_inp,
        fake_fp8,
        fake_sc,
        make_fake_stream(),
        _FP8_MAX,  # FP8_MAX_C — baked as Constexpr, absent from runtime sig
        options="--enable-tvm-ffi",
    )


def run_absmax_quantize(
    fn: Callable,
    num_rows: int = _DEFAULT_NUM_ROWS,
) -> tuple[tuple[torch.Tensor, torch.Tensor], torch.Tensor]:
    """Allocate tensors, call ``fn``, and return ``((fp8_out, scales), inp)``.

    Returns outputs first so callers can write::

        (fp8_out, scales), inp = run_absmax_quantize(fn)
        # verify fp8_out against a torch reference computed from inp

    :param fn: Compiled callable from :func:`compile_absmax_quantize`.
    :type fn: Callable
    :param num_rows: Number of 32-element BF16 rows to quantize.
    :type num_rows: int
    :return: ``((fp8_out, scales), inp)``
    :rtype: tuple[tuple[torch.Tensor, torch.Tensor], torch.Tensor]
    """
    torch.manual_seed(0)
    inp = torch.randn(num_rows, _WARP_SIZE, dtype=torch.bfloat16, device="cuda")
    fp8_out = torch.zeros(
        num_rows, _WARP_SIZE, dtype=torch.float8_e4m3fn, device="cuda"
    )
    scales = torch.zeros(num_rows, dtype=torch.float32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(inp, fp8_out, scales, stream)
    torch.cuda.synchronize()
    return (fp8_out, scales), inp


def verify_absmax_quantize(num_rows: int = _DEFAULT_NUM_ROWS) -> None:
    """Compile, run, and assert FP8 output matches a torch reference.

    Scale tolerance: 1e-4.  Dequantized value tolerance: 0.1 (quantization
    noise from BF16 → FP8 rounding).

    :param num_rows: Number of rows to quantize.
    :type num_rows: int
    :raises AssertionError: If scale or dequantized value error exceeds tolerance.
    """
    fn = compile_absmax_quantize()
    print("Compile kernel (absmax_quantize) OK", flush=True)

    (fp8_out, scales), inp = run_absmax_quantize(fn, num_rows=num_rows)
    print(f"Run kernel (absmax_quantize, num_rows={num_rows}) OK", flush=True)

    # Torch reference: FP32 abs-max per row → scale → quantize
    inp_f32 = inp.float()
    ref_amax = inp_f32.abs().max(dim=-1).values  # [num_rows]
    ref_scale = ref_amax / _FP8_MAX  # [num_rows]
    ref_iscale = (_FP8_MAX / ref_amax).unsqueeze(-1)  # [num_rows, 1]
    ref_fp8 = (inp_f32 * ref_iscale).clamp(-_FP8_MAX, _FP8_MAX).to(torch.float8_e4m3fn)

    dq_got = fp8_out.float() * scales.unsqueeze(-1)
    dq_ref = ref_fp8.float() * ref_scale.unsqueeze(-1)

    torch.testing.assert_close(scales, ref_scale, atol=1e-4, rtol=0)
    torch.testing.assert_close(dq_got, dq_ref, atol=0.1, rtol=0)
    scale_err = (scales - ref_scale).abs().max().item()
    dq_err = (dq_got - dq_ref).abs().max().item()
    print(
        f"verify (absmax_quantize, num_rows={num_rows}, "
        f"scale_err={scale_err:.2e}, dq_err={dq_err:.4f}): PASS"
    )


# =============================================================================
# Architecture helpers
# =============================================================================

#: Kernels that require SM100+ (use ``redux.sync ... abs=True``).
_SM100_ONLY_KERNELS: frozenset[str] = frozenset({"2", "3", "4"})
_SM100_ONLY_NAMES: dict[str, str] = {
    "2": "float_reductions",
    "3": "redux_vs_shuffle",
    "4": "absmax_quantize",
}


def _sm_version() -> int:
    """Return the current device's compute capability as a plain integer.

    Examples: SM80 → 80, SM90 → 90, SM100 → 100.
    Returns 0 when no CUDA device is available.
    """
    if not torch.cuda.is_available():
        return 0
    prop = torch.cuda.get_device_properties(torch.cuda.current_device())
    return prop.major * 10 + prop.minor


# =============================================================================
# Top-level verify
# =============================================================================


def verify(kernel: str = "all") -> None:
    """Run the selected kernel verification(s).

    :param kernel: ``"1"``–``"4"`` for a single kernel, ``"all"`` for all four.
        Kernels 2, 3, and 4 use ``abs=True`` on :func:`~cutlass.primitives.redux_sync`
        (``redux.sync ... abs``), which requires **SM100+**.  On SM80/SM90
        devices those kernels are silently skipped when *kernel* is ``"all"``;
        requesting one of them explicitly raises :class:`RuntimeError`.
    :type kernel: str
    :raises ValueError: If ``kernel`` is not in ``{"1", "2", "3", "4", "all"}``.
    :raises RuntimeError: If CUDA is unavailable, or if an SM100-only kernel
        is requested explicitly on a pre-SM100 device.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA device required")

    sm = _sm_version()

    run_map = {
        "1": verify_integer_reductions,
        "2": verify_float_reductions,
        "3": verify_redux_vs_shuffle,
        "4": verify_absmax_quantize,
    }
    if kernel not in run_map and kernel != "all":
        raise ValueError(
            f"kernel must be one of {list(run_map) + ['all']}, got {kernel!r}"
        )

    # Explicit SM100-only kernel on incompatible hardware → hard error.
    if kernel in _SM100_ONLY_KERNELS and sm < 100:
        raise RuntimeError(
            f"Kernel {kernel} ({_SM100_ONLY_NAMES[kernel]}) requires SM100+; "
            f"current device is SM{sm}.  "
            f"Use --kernel 1 for the SM80-compatible integer-reduction kernel."
        )

    for k, fn in run_map.items():
        if kernel != "all" and k != kernel:
            continue
        if k in _SM100_ONLY_KERNELS and sm < 100:
            print(
                f"  [skip] kernel {k} ({_SM100_ONLY_NAMES[k]}) requires SM100+; "
                f"current device is SM{sm}"
            )
            continue
        fn()


# =============================================================================
# Entry point
# =============================================================================

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="redux.sync — hardware warp reduction examples",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--kernel",
        type=str,
        default="all",
        choices=["1", "2", "3", "4", "all"],
        help=(
            "kernel to run: "
            "1=integer_reductions [sm_80+], "
            "2=float_reductions   [sm_100a/sm_103a/sm_107a], "
            "3=redux_vs_shuffle   [sm_100a/sm_103a/sm_107a], "
            "4=absmax_quantize    [sm_100a/sm_103a/sm_107a], "
            "all=run all (skips fp redux kernels on older hardware)"
        ),
    )
    p.add_argument(
        "--num_rows",
        type=int,
        default=_DEFAULT_NUM_ROWS,
        help="batch rows for kernel 4 (absmax_quantize)",
    )
    args = p.parse_args()

    # Override the default for kernel 4 if --num_rows was supplied.
    if args.kernel in ("4", "all") and args.num_rows != _DEFAULT_NUM_ROWS:
        _original = verify_absmax_quantize
        verify_absmax_quantize = lambda: _original(num_rows=args.num_rows)  # noqa: E731

    verify(args.kernel)
