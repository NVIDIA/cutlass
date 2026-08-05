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
