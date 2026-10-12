# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Tests for ``cute.arch.warp_reduction``.

``warp_reduction`` lowers to a single ``redux.sync`` when the operator, operand
type and target allow it and otherwise to a ``shfl.sync.bfly`` tree.  Both paths
must produce the same value on every lane, so every case below runs the kernel
and compares against a per-warp NumPy reference; the resolver that picks the
path is unit-tested separately.
"""

import operator
from functools import partial

import numpy as np
import pytest
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cutlass_dsl as cutlass_dsl
from cutlass import Float32, Int32, Int64, Uint32
from cutlass.base_dsl import Arch
from cutlass.cute.arch.nvvm_wrappers import (
    _warp_reduction_redux_kind,
    _warp_reduction_redux_supported,
)
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import target_version

WARP_SIZE = 32
NUM_WARPS = 4
NUM_THREADS = WARP_SIZE * NUM_WARPS

# Unsigned 32-bit tensors need a PyTorch build with torch.uint32.
_HAS_TORCH_UINT32 = hasattr(torch, "uint32")
_needs_uint32 = pytest.mark.skipif(
    not _HAS_TORCH_UINT32, reason="torch.uint32 is not available in this PyTorch build"
)


@cute.kernel
def _warp_reduce_kernel(
    inp: cute.Tensor, out: cute.Tensor, reduce_fn: cutlass.Constexpr
):
    tidx, _, _ = cute.arch.thread_idx()
    out[tidx] = reduce_fn(inp[tidx])


@cute.jit
def _warp_reduce_host(inp: cute.Tensor, out: cute.Tensor, reduce_fn: cutlass.Constexpr):
    _warp_reduce_kernel(inp, out, reduce_fn).launch(
        grid=[1, 1, 1], block=[NUM_THREADS, 1, 1]
    )


def _run(inp_np: np.ndarray, reduce_fn) -> np.ndarray:
    inp = torch.from_numpy(inp_np).cuda()
    out = torch.zeros_like(inp)
    inp_cute = from_dlpack(inp)
    out_cute = from_dlpack(out)
    cute.compile(_warp_reduce_host, inp_cute, out_cute, reduce_fn)(inp_cute, out_cute)
    torch.cuda.synchronize()
    return out.cpu().numpy()


def _grouped_reference(inp_np: np.ndarray, fn, group: int = WARP_SIZE) -> np.ndarray:
    """Apply ``fn`` to every ``group`` consecutive lanes and broadcast the result."""
    groups = inp_np.reshape(-1, group)
    return np.repeat(np.array([fn(g) for g in groups], dtype=inp_np.dtype), group)


def _wrap_sum(x: np.ndarray) -> np.ndarray:
    """32-bit wrap-around sum, matching both redux.sync.add and the shuffle tree."""
    total = int(np.sum(x.astype(np.int64))) & 0xFFFFFFFF
    if x.dtype == np.int32 and total >= 2**31:
        total -= 2**32
    return x.dtype.type(total)


def _xorsign_abs_max(x: np.ndarray) -> np.float32:
    """Reference for ``fmax(abs=True)``: ``max(|x|)`` carrying the XOR of all signs."""
    magnitude = np.max(np.abs(x))
    negative = bool(np.count_nonzero(np.signbit(x)) % 2)
    return np.float32(-magnitude if negative else magnitude)


_RNG = np.random.default_rng(0)

INT32_INPUTS = _RNG.integers(
    -(2**31), 2**31, size=NUM_THREADS, dtype=np.int64
).astype(np.int32)
# Values above 2**31 catch signed/unsigned confusion in max/min.
UINT32_INPUTS = _RNG.integers(0, 2**32, size=NUM_THREADS, dtype=np.int64).astype(
    np.uint32
)
FLOAT32_INPUTS = _RNG.standard_normal(NUM_THREADS).astype(np.float32) * 10.0
# Small integers as floats: the sum is exact regardless of association order,
# so the shuffle tree and any reference agree bit-for-bit.
FLOAT32_EXACT_INPUTS = _RNG.integers(-64, 64, size=NUM_THREADS).astype(np.float32)
FLOAT32_NAN_INPUTS = FLOAT32_INPUTS.copy()
FLOAT32_NAN_INPUTS[3::WARP_SIZE] = np.nan  # one NaN lane in every warp
FLOAT32_NAN_INPUTS[WARP_SIZE + 17] = np.nan  # a second one in warp 1
# All lanes negative except lane 0 of each warp: 31 negative signs XOR to a
# negative result under xorsign-abs, whereas a magnitude-only reduction would be
# positive.
FLOAT32_SIGNED_INPUTS = -np.abs(FLOAT32_INPUTS) - 1.0
FLOAT32_SIGNED_INPUTS[::WARP_SIZE] = np.abs(FLOAT32_SIGNED_INPUTS[::WARP_SIZE])
# Signed-zero ties: one +0.0 lane among -0.0 (and vice versa).  Both paths order
# -0.0 < +0.0, so fmax must return +0.0 and fmin -0.0 regardless of lane position.
FLOAT32_NEGZERO_TIE_INPUTS = np.full(NUM_THREADS, -0.0, dtype=np.float32)
FLOAT32_NEGZERO_TIE_INPUTS[5::WARP_SIZE] = 0.0
FLOAT32_POSZERO_TIE_INPUTS = np.full(NUM_THREADS, 0.0, dtype=np.float32)
FLOAT32_POSZERO_TIE_INPUTS[9::WARP_SIZE] = -0.0
FLOAT32_ALL_NAN_INPUTS = np.full(NUM_THREADS, np.nan, dtype=np.float32)
# Denormals (bit patterns 7 .. 7*128): the default paths preserve them, ftz=True
# flushes them and must therefore keep the shuffle path.
FLOAT32_DENORMAL_INPUTS = (
    (_RNG.integers(1, 129, size=NUM_THREADS).astype(np.uint32) * 7)
).view(np.float32)
FLOAT32_DENORMAL_SIGNED_INPUTS = FLOAT32_DENORMAL_INPUTS.copy()
FLOAT32_DENORMAL_SIGNED_INPUTS[4::WARP_SIZE] *= -1.0
FLOAT32_DENORMAL_SIGNED_INPUTS[11::WARP_SIZE] *= -1.0


def _signed_zero_max(x: np.ndarray) -> np.float32:
    return np.float32(0.0) if np.any(~np.signbit(x)) else np.float32(-0.0)


def _signed_zero_min(x: np.ndarray) -> np.float32:
    return np.float32(-0.0) if np.any(np.signbit(x)) else np.float32(0.0)


def _ftz_max(x: np.ndarray) -> np.float32:
    """fmax(ftz=True) over denormals: everything flushes, max of zeros is +0.0."""
    return np.float32(0.0)


def _ftz_min(x: np.ndarray) -> np.float32:
    """fmin(ftz=True) over denormals: flushed, -0.0 if any lane is negative."""
    return np.float32(-0.0) if np.any(np.signbit(x)) else np.float32(0.0)


def _wr(op, **kwargs):
    return lambda v: cute.arch.warp_reduction(v, op, **kwargs)


INT_CASES = [
    # (id, inputs, reduce_fn, numpy reference over one group, group size)
    ("i32_add", INT32_INPUTS, _wr(operator.add), _wrap_sum, WARP_SIZE),
    ("i32_max", INT32_INPUTS, _wr(cutlass_dsl.max), np.max, WARP_SIZE),
    ("i32_min", INT32_INPUTS, _wr(cutlass_dsl.min), np.min, WARP_SIZE),
    ("i32_and", INT32_INPUTS, _wr(operator.and_), np.bitwise_and.reduce, WARP_SIZE),
    ("i32_or", INT32_INPUTS, _wr(operator.or_), np.bitwise_or.reduce, WARP_SIZE),
    ("i32_xor", INT32_INPUTS, _wr(operator.xor), np.bitwise_xor.reduce, WARP_SIZE),
    (
        "i32_warp_reduction_sum",
        INT32_INPUTS,
        cute.arch.warp_reduction_sum,
        _wrap_sum,
        WARP_SIZE,
    ),
    (
        "i32_warp_reduction_max",
        INT32_INPUTS,
        cute.arch.warp_reduction_max,
        np.max,
        WARP_SIZE,
    ),
    # Sub-warp groups always take the shuffle path.
    (
        "i32_add_group8",
        INT32_INPUTS,
        _wr(operator.add, threads_in_group=8),
        _wrap_sum,
        8,
    ),
    (
        "i32_max_group4",
        INT32_INPUTS,
        _wr(cutlass_dsl.max, threads_in_group=4),
        np.max,
        4,
    ),
    ("u32_add", UINT32_INPUTS, _wr(operator.add), _wrap_sum, WARP_SIZE),
    ("u32_max", UINT32_INPUTS, _wr(cutlass_dsl.max), np.max, WARP_SIZE),
    ("u32_min", UINT32_INPUTS, _wr(cutlass_dsl.min), np.min, WARP_SIZE),
    (
        "u32_warp_reduction_max",
        UINT32_INPUTS,
        cute.arch.warp_reduction_max,
        np.max,
        WARP_SIZE,
    ),
]

FLOAT_CASES = [
    # No redux.sync floating-point add exists; this always takes the shuffle path.
    ("f32_add", FLOAT32_EXACT_INPUTS, _wr(operator.add), np.sum, WARP_SIZE),
    ("f32_fmax", FLOAT32_INPUTS, _wr(cute.arch.fmax), np.max, WARP_SIZE),
    ("f32_fmin", FLOAT32_INPUTS, _wr(cute.arch.fmin), np.min, WARP_SIZE),
    (
        "f32_warp_reduction_max",
        FLOAT32_INPUTS,
        cute.arch.warp_reduction_max,
        np.max,
        WARP_SIZE,
    ),
    (
        "f32_warp_reduction_sum",
        FLOAT32_EXACT_INPUTS,
        cute.arch.warp_reduction_sum,
        np.sum,
        WARP_SIZE,
    ),
    (
        "f32_fmax_group16",
        FLOAT32_INPUTS,
        _wr(cute.arch.fmax, threads_in_group=16),
        np.max,
        16,
    ),
    # NaN-quiet max: NaN lanes are ignored.
    (
        "f32_fmax_nan_quiet",
        FLOAT32_NAN_INPUTS,
        _wr(cute.arch.fmax),
        np.nanmax,
        WARP_SIZE,
    ),
    (
        "f32_fmin_nan_quiet",
        FLOAT32_NAN_INPUTS,
        _wr(cute.arch.fmin),
        np.nanmin,
        WARP_SIZE,
    ),
    # ftz has no redux.sync counterpart; normal inputs give the plain result.
    (
        "f32_fmax_ftz",
        FLOAT32_INPUTS,
        _wr(partial(cute.arch.fmax, ftz=True)),
        np.max,
        WARP_SIZE,
    ),
    # abs=True is the xorsign-abs form and must not be routed to redux.sync.abs.
    (
        "f32_fmax_xorsign_abs",
        FLOAT32_SIGNED_INPUTS,
        _wr(partial(cute.arch.fmax, abs=True)),
        _xorsign_abs_max,
        WARP_SIZE,
    ),
    (
        "f32_fmax_signed_zero_tie",
        FLOAT32_NEGZERO_TIE_INPUTS,
        _wr(cute.arch.fmax),
        _signed_zero_max,
        WARP_SIZE,
    ),
    (
        "f32_fmin_signed_zero_tie",
        FLOAT32_NEGZERO_TIE_INPUTS,
        _wr(cute.arch.fmin),
        _signed_zero_min,
        WARP_SIZE,
    ),
    (
        "f32_fmax_signed_zero_tie_pos",
        FLOAT32_POSZERO_TIE_INPUTS,
        _wr(cute.arch.fmax),
        _signed_zero_max,
        WARP_SIZE,
    ),
    (
        "f32_fmin_signed_zero_tie_pos",
        FLOAT32_POSZERO_TIE_INPUTS,
        _wr(cute.arch.fmin),
        _signed_zero_min,
        WARP_SIZE,
    ),
    (
        "f32_fmax_denormals",
        FLOAT32_DENORMAL_SIGNED_INPUTS,
        _wr(cute.arch.fmax),
        np.max,
        WARP_SIZE,
    ),
    (
        "f32_fmin_denormals",
        FLOAT32_DENORMAL_SIGNED_INPUTS,
        _wr(cute.arch.fmin),
        np.min,
        WARP_SIZE,
    ),
    (
        "f32_fmax_ftz_denormals",
        FLOAT32_DENORMAL_INPUTS,
        _wr(partial(cute.arch.fmax, ftz=True)),
        _ftz_max,
        WARP_SIZE,
    ),
    (
        "f32_fmin_ftz_denormals",
        FLOAT32_DENORMAL_SIGNED_INPUTS,
        _wr(partial(cute.arch.fmin, ftz=True)),
        _ftz_min,
        WARP_SIZE,
    ),
]


def _device_param(case):
    marks = [_needs_uint32] if case[0].startswith("u32") else []
    return pytest.param(*case[1:], id=case[0], marks=marks)


@pytest.mark.parametrize(
    "inputs,reduce_fn,reference,group",
    [_device_param(case) for case in INT_CASES + FLOAT_CASES],
)
def test_warp_reduction_matches_reference(inputs, reduce_fn, reference, group):
    out = _run(inputs, reduce_fn)
    expected = _grouped_reference(inputs, reference, group)
    np.testing.assert_array_equal(out, expected)
    if inputs.dtype == np.float32:
        # assert_array_equal treats -0.0 == +0.0; the sign of zero must match too.
        np.testing.assert_array_equal(np.signbit(out), np.signbit(expected))


@pytest.mark.parametrize(
    "reduce_fn",
    [
        _wr(cute.arch.fmax),
        _wr(cute.arch.fmin),
        _wr(partial(cute.arch.fmax, nan=True)),
        _wr(partial(cute.arch.fmin, nan=True)),
    ],
    ids=["fmax", "fmin", "fmax_nan", "fmin_nan"],
)
def test_warp_reduction_all_nan(reduce_fn):
    """A warp whose lanes are all NaN reduces to NaN on both the quiet and .NaN forms."""
    out = _run(FLOAT32_ALL_NAN_INPUTS, reduce_fn)
    assert np.isnan(out).all()


@pytest.mark.parametrize("op", ["fmax", "fmin"], ids=["fmax", "fmin"])
def test_warp_reduction_nan_propagating(op):
    """``partial(fmax, nan=True)`` propagates NaN to every lane of an affected warp."""
    fn = partial(getattr(cute.arch, op), nan=True)
    out = _run(FLOAT32_NAN_INPUTS, _wr(fn))
    ref = getattr(np, "max" if op == "fmax" else "min")
    expected = _grouped_reference(FLOAT32_NAN_INPUTS, ref)  # np.max propagates NaN
    assert np.array_equal(np.isnan(out), np.isnan(expected))
    finite = ~np.isnan(expected)
    np.testing.assert_array_equal(out[finite], expected[finite])


# ---------------------------------------------------------------------------
# Path selection (no GPU needed)
# ---------------------------------------------------------------------------

_MAX_OP = cute.arch.warp_reduction_max.keywords["op"]
_SUM_OP = cute.arch.warp_reduction_sum.keywords["op"]


@pytest.mark.parametrize(
    "value_type,op,expected",
    [
        (Int32, operator.add, ("add", False)),
        (Int32, _SUM_OP, ("add", False)),
        (Int32, cutlass_dsl.max, ("max", False)),
        (Int32, cutlass_dsl.min, ("min", False)),
        (Int32, _MAX_OP, ("max", False)),
        (Int32, operator.and_, ("and", False)),
        (Int32, operator.or_, ("or", False)),
        (Int32, operator.xor, ("xor", False)),
        (Uint32, operator.add, ("add", False)),
        (Uint32, cutlass_dsl.max, ("max", False)),
        (Float32, cute.arch.fmax, ("fmax", False)),
        (Float32, cute.arch.fmin, ("fmin", False)),
        (Float32, _MAX_OP, ("fmax", False)),
        (Float32, partial(cute.arch.fmax, nan=True), ("fmax", True)),
        (Float32, partial(cute.arch.fmin, nan=False), ("fmin", False)),
        # Not expressible as a single redux.sync:
        (Float32, operator.add, None),
        (Float32, _SUM_OP, None),
        (Float32, cutlass_dsl.max, None),
        (Float32, partial(cute.arch.fmax, abs=True), None),
        (Float32, partial(cute.arch.fmax, ftz=True), None),
        (Float32, partial(cute.arch.fmax, 1.0), None),
        (Int32, partial(operator.add), ("add", False)),
        (Int32, lambda x, y: x + y, None),
        (Int32, cute.arch.fmax, None),
        (Int64, operator.add, None),
        (cutlass.Int16, operator.add, None),
        (cutlass.Boolean, operator.or_, None),
    ],
)
def test_redux_kind_resolution(value_type, op, expected):
    assert _warp_reduction_redux_kind(value_type, op, WARP_SIZE) == expected


@pytest.mark.parametrize("group", [1, 2, 4, 8, 16])
def test_redux_kind_requires_full_warp(group):
    assert _warp_reduction_redux_kind(Int32, operator.add, group) is None
    assert _warp_reduction_redux_kind(Float32, cute.arch.fmax, group) is None


@pytest.mark.parametrize(
    "value_type,arch,expected",
    [
        (Float32, Arch.sm_90a, False),
        (Float32, Arch.sm_100, False),  # baseline target: no .f32 redux.sync
        (Float32, Arch.sm_100a, True),
        (Float32, Arch.sm_100f, True),
        (Float32, Arch.sm_103a, True),
        (Float32, Arch.sm_103f, True),
        (Float32, Arch.sm_120a, False),  # different family
        (Int32, Arch.sm_80, True),
        (Int32, Arch.sm_90a, True),
        (Int32, Arch.sm_100, True),
        (Uint32, Arch.sm_120a, True),
        # redux.sync only has 32-bit operand forms.
        (Int64, Arch.sm_100a, False),
        (cutlass.Int16, Arch.sm_100a, False),
        (cutlass.Boolean, Arch.sm_100a, False),
    ],
)
def test_redux_supported_on_target(value_type, arch, expected):
    if value_type is Float32:
        expected = expected and target_version(min_version="12.9")
    assert _warp_reduction_redux_supported(value_type, arch) is expected


# ---------------------------------------------------------------------------
# Code generation (compile-only, independent of the local GPU)
# ---------------------------------------------------------------------------

# Compile-only, so any GPU can run these, but ptxas must know the target:
# sm_100 / sm_100a need CUDA 12.8, sm_100f / sm_120a need CUDA 12.9.
_CODEGEN_ARCHS = ["sm_90a"]
if target_version(min_version="12.8"):
    _CODEGEN_ARCHS += ["sm_100", "sm_100a"]
if target_version(min_version="12.9"):
    _CODEGEN_ARCHS += ["sm_100f", "sm_120a"]


def _f32_redux_expected(arch: str) -> bool:
    return Arch.from_string(arch).is_family_of(Arch.sm_100f) and target_version(
        min_version="12.9"
    )


_CODEGEN_CASES = [
    # (id, torch dtype, reduce_fn, redux.sync expected for arch, shuffle rounds otherwise)
    ("f32_fmax", torch.float32, _wr(cute.arch.fmax), _f32_redux_expected, 5),
    (
        "f32_fmax_nan",
        torch.float32,
        _wr(partial(cute.arch.fmax, nan=True)),
        _f32_redux_expected,
        5,
    ),
    (
        "f32_warp_reduction_max",
        torch.float32,
        cute.arch.warp_reduction_max,
        _f32_redux_expected,
        5,
    ),
    ("f32_add", torch.float32, _wr(operator.add), lambda arch: False, 5),
    (
        "f32_fmax_abs",
        torch.float32,
        _wr(partial(cute.arch.fmax, abs=True)),
        lambda arch: False,
        5,
    ),
    (
        "f32_fmax_group16",
        torch.float32,
        _wr(cute.arch.fmax, threads_in_group=16),
        lambda arch: False,
        4,
    ),
    ("i32_add", torch.int32, _wr(operator.add), lambda arch: True, 5),
    ("i32_max", torch.int32, _wr(cutlass_dsl.max), lambda arch: True, 5),
    (
        "u32_max",
        getattr(torch, "uint32", None),
        _wr(cutlass_dsl.max),
        lambda arch: True,
        5,
    ),
    (
        "i32_add_group8",
        torch.int32,
        _wr(operator.add, threads_in_group=8),
        lambda arch: False,
        3,
    ),
    ("i32_lambda", torch.int32, _wr(lambda x, y: x + y), lambda arch: False, 5),
]


def _read_ptx(compiled) -> str:
    """``__ptx__`` is the PTX text, or the dump path on older releases."""
    ptx = compiled.__ptx__
    assert ptx, "PTX was not kept; pass --keep-ptx"
    return ptx if "\n" in ptx else open(ptx).read()


@pytest.mark.parametrize("arch", _CODEGEN_ARCHS)
@pytest.mark.parametrize(
    "dtype,reduce_fn,redux_expected,shuffle_rounds",
    [_device_param(case) for case in _CODEGEN_CASES],
)
def test_warp_reduction_codegen(
    tmp_path, arch, dtype, reduce_fn, redux_expected, shuffle_rounds
):
    """Whole-warp reductions lower to exactly one redux.sync where the target allows it."""
    inp = torch.zeros(NUM_THREADS, dtype=dtype, device="cuda")
    out = torch.zeros_like(inp)
    inp_cute, out_cute = from_dlpack(inp), from_dlpack(out)
    compiled = cute.compile(
        _warp_reduce_host,
        inp_cute,
        out_cute,
        reduce_fn,
        options=f"--gpu-arch {arch} --keep-ptx --dump-dir {tmp_path}",
    )
    ptx = _read_ptx(compiled)
    n_redux = ptx.count("redux.sync")
    n_shfl = ptx.count("shfl.sync")
    if redux_expected(arch):
        assert (n_redux, n_shfl) == (1, 0), ptx
    else:
        assert (n_redux, n_shfl) == (0, shuffle_rounds), ptx
