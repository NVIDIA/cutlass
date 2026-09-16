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


import pytest
import torch

import cutlass

import cutlass.operators as ops

pytestmark = pytest.mark.arch("80")


def test_basic_keywords():
    def epi(accum, C, alpha, beta):
        D = (alpha * accum) + (beta * C)
        return D

    ops.EpilogueArguments(
        epilogue_fn=epi,
        D=torch.randn(10, 10),
        C=torch.randn(10, 10),
        alpha=1.0,
        beta=1.0,
    )


def test_missing_keywords():
    epifn = """
def epi(accum, C, alpha, beta):
    D = (alpha * accum) + (beta * C)
    F = relu(D)
    return D, F
"""
    try:
        # Missing F
        ops.EpilogueArguments(
            epilogue_fn=epifn,
            D=torch.randn(10, 10),
            C=torch.randn(10, 10),
            alpha=1.0,
            beta=1.0,
        )
    except ValueError as e:
        assert "F" in str(e)
    else:
        raise AssertionError("Failed to catch missing keyword")


def test_extra_keywords():
    epifn = """
def epi(accum, C, alpha, beta):
    D = (alpha * accum) + (beta * C)
    F = relu(D)
    return D, F
"""
    try:
        ops.EpilogueArguments(
            epilogue_fn=epifn,
            D=torch.randn(10, 10),
            C=torch.randn(10, 10),
            alpha=1.0,
            beta=1.0,
            F=torch.randn(10, 10),
            gamma=3.0,
        )
    except ValueError as e:
        assert "gamma" in str(e)
    else:
        raise AssertionError("Failed to catch extra keyword")


def test_load_store_transport_recorded():
    # Wrapping a tensor in Load/Store records the transport in `transports`
    # and unwraps the bare tensor into `tensors`.
    def epi(accum, C):
        D = accum + C
        return D

    C, D = torch.randn(10, 10), torch.randn(10, 10)
    args = ops.EpilogueArguments(
        epilogue_fn=epi,
        C=ops.Load(C, via=ops.Transport.ASYNC_GMEM_LOAD),
        D=ops.Store(D, via=ops.Transport.SYNC_GMEM_STORE, num_bits_per_copy=128),
    )
    assert args.tensors["C"] is C and args.tensors["D"] is D
    assert args.transports["C"].via is ops.Transport.ASYNC_GMEM_LOAD
    assert args.transports["D"].via is ops.Transport.SYNC_GMEM_STORE
    assert args.transports["D"].num_bits_per_copy == 128


def test_load_store_direction_mismatch_rejected():
    # A ``Load`` describes a read (inputs) and a ``Store`` a write (outputs);
    # a descriptor on the wrong-role parameter is rejected at construction.
    def epi(accum, C):
        D = accum + C
        return D

    with pytest.raises(ValueError, match="wrapped in Store"):
        ops.EpilogueArguments(
            epilogue_fn=epi, C=ops.Store(torch.randn(10, 10)), D=torch.randn(10, 10)
        )
    with pytest.raises(ValueError, match="wrapped in Load"):
        ops.EpilogueArguments(
            epilogue_fn=epi, C=torch.randn(10, 10), D=ops.Load(torch.randn(10, 10))
        )


def test_transport_string_is_normalized():
    # `via` accepts the enum's string value and normalizes to the enum.
    assert ops.Load(torch.randn(4), via="async_gmem_load").via is (
        ops.Transport.ASYNC_GMEM_LOAD
    )
    assert ops.Store(torch.randn(4), via="tma").via is ops.Transport.TMA


def test_bare_tensors_record_no_transport():
    def epi(accum, C):
        D = accum + C
        return D

    args = ops.EpilogueArguments(
        epilogue_fn=epi, C=torch.randn(10, 10), D=torch.randn(10, 10)
    )
    assert args.transports == {}


@pytest.mark.parametrize("bad_via", ["sync_gmem_store", "not_a_transport"])
def test_invalid_load_transport_rejected(bad_via):
    with pytest.raises(ValueError):
        ops.Load(torch.randn(4), via=bad_via)


@pytest.mark.parametrize("bad_via", ["sync_gmem_load", "async_gmem_load"])
def test_invalid_store_transport_rejected(bad_via):
    with pytest.raises(ValueError):
        ops.Store(torch.randn(4), via=bad_via)


def test_num_bits_per_copy_rejected_for_tma():
    # `num_bits_per_copy` sizes a direct copy's transaction; TMA derives its own
    # descriptor, so the combination is meaningless and must be rejected early
    # (TMA is the default `via`, so an explicit `via` is not even needed).
    with pytest.raises(ValueError, match="num_bits_per_copy"):
        ops.Load(torch.randn(4), num_bits_per_copy=128)
    with pytest.raises(ValueError, match="num_bits_per_copy"):
        ops.Store(torch.randn(4), via="tma", num_bits_per_copy=128)


def test_num_bits_per_copy_allowed_for_direct_transports():
    # Accepted for a direct GMEM copy: a positive case is simply a successful
    # construction (as in `test_basic_keywords`); that the width is actually
    # retained is checked in `test_load_store_transport_recorded`.
    ops.Load(torch.randn(4), via="sync_gmem_load", num_bits_per_copy=64)
    ops.Store(torch.randn(4), via="sync_gmem_store", num_bits_per_copy=128)


@pytest.mark.parametrize("bad_width", [64.0, "64", True])
def test_num_bits_per_copy_must_be_int(bad_width):
    # A bit count must be an int; a non-int width is rejected explicitly rather
    # than silently mis-sizing the copy downstream (`True` is a `bool`, which is
    # an `int` subclass but never a valid width).
    with pytest.raises(TypeError, match="num_bits_per_copy"):
        ops.Load(torch.randn(4), via="sync_gmem_load", num_bits_per_copy=bad_width)
    with pytest.raises(TypeError, match="num_bits_per_copy"):
        ops.Store(torch.randn(4), via="sync_gmem_store", num_bits_per_copy=bad_width)


# --- Reuse of one EpilogueArguments across operations -------------------------
#
# Building a `RuntimeArguments` traces the epilogue and converts its tensors to
# `TensorWrapper`. Both steps used to mutate the caller's object, so a second
# use of the same `EpilogueArguments` re-traced already-converted tensors and
# the fusion frontend rejected them.


def _epi_add_c(accum, C):
    D = accum + C
    return D


def _make_epilogue_args():
    """Return an epilogue plus the tensors it was built from."""
    C = torch.empty((1, 16, 16), dtype=torch.float32)
    D = torch.empty((1, 16, 16), dtype=torch.float32)
    return ops.EpilogueArguments(_epi_add_c, C=C, D=D), C, D


def _accum_element(gemm_args):
    """Element type the traced epilogue expects for its accumulator."""
    dag = gemm_args.epilogue.traced_epilogue.dag_ir
    for meta in dag.node_metas_topological_order():
        if meta.name == "accum":
            return meta.tensor.element
    raise AssertionError("traced epilogue has no 'accum' node")


def test_epilogue_arguments_reusable_across_gemm_arguments():
    epi_args, _, D = _make_epilogue_args()
    A = torch.empty((1, 16, 16), dtype=torch.float16)
    B = torch.empty((1, 16, 16), dtype=torch.float16)

    # The second construction is the one that used to raise.
    for _ in range(2):
        ops.GemmArguments(A, B, D, torch.float32, epilogue=epi_args)


def test_gemm_arguments_does_not_mutate_epilogue():
    # Same contract GemmArguments already honours for A/B/out: constructing it
    # leaves the caller's operands alone and works on copies.
    epi_args, C, D = _make_epilogue_args()
    A = torch.empty((1, 16, 16), dtype=torch.float16)
    B = torch.empty((1, 16, 16), dtype=torch.float16)

    args = ops.GemmArguments(A, B, D, torch.float32, epilogue=epi_args)

    assert args.epilogue is not epi_args
    # The caller's tensors are still their own tensors, not TensorWrappers.
    assert epi_args.tensors["C"] is C and epi_args.tensors["D"] is D
    # ...and the caller's object was not left carrying this GEMM's trace.
    assert not hasattr(epi_args, "traced_epilogue")


def test_gemm_arguments_epilogue_traces_are_independent():
    # Two GEMMs may share an epilogue while differing in accumulator type, which
    # the trace records on its `accum` node. Sharing one trace would therefore
    # give one of them the wrong accumulator element -- silently, since nothing
    # downstream re-checks it.
    epi_args, _, D = _make_epilogue_args()
    A = torch.empty((1, 16, 16), dtype=torch.float16)
    B = torch.empty((1, 16, 16), dtype=torch.float16)

    f32_gemm = ops.GemmArguments(A, B, D, torch.float32, epilogue=epi_args)
    f16_gemm = ops.GemmArguments(A, B, D, torch.float16, epilogue=epi_args)

    assert _accum_element(f32_gemm) != _accum_element(f16_gemm)


def test_trace_and_to_tensor_wrappers_are_repeatable():
    # The lower-level call chain, independently of any RuntimeArguments: the
    # conversion derives from the caller's tensors, so it never feeds its own
    # output back into the next trace.
    epi_args, _, _ = _make_epilogue_args()

    for _ in range(2):
        epi_args.trace((1, 16, 16), cutlass.Float32)
        epi_args.to_tensor_wrappers()


def test_epilogue_arguments_copy_is_shallow():
    # A copy gets its own containers but keeps the caller's tensors, so
    # converting the copy cannot write through to the original.
    epi_args, C, D = _make_epilogue_args()

    clone = epi_args.copy()

    assert clone.tensors is not epi_args.tensors
    assert clone.tensors["C"] is C and clone.tensors["D"] is D
    assert clone.epilogue_fn is epi_args.epilogue_fn

    clone.trace((1, 16, 16), cutlass.Float32)
    clone.to_tensor_wrappers()

    assert epi_args.tensors["C"] is C and epi_args.tensors["D"] is D
    assert not hasattr(epi_args, "traced_epilogue")
