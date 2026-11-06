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
Pytest test suite for variable sequence lengths in hopper/attention/fmha.py.

Sequences are packed along the sequence dimension and described by cumulative
sequence lengths. Output and LSE are checked per sequence against a PyTorch
reference.

The lengths include empty and length-1 sequences, lengths around the 64-row
MMA tile and the 128-row CTA tile, so tiles both end inside a sequence and run
into the next one, and sequence starts that are not tile aligned.
"""

import pytest

import cutlass
from hopper.kernel.attention.fmha import default_softmax_scale, run


F16 = cutlass.Float16
BF16 = cutlass.BFloat16
F32 = cutlass.Float32
F8E4 = cutlass.Float8E4M3FN

NO_WINDOW = (-1, -1)

SEQLENS = (1, 0, 63, 64, 65, 128, 129, 700)

# (is_causal, window_size)
MASK_CASES = [
    pytest.param(False, NO_WINDOW, id="no-mask"),
    pytest.param(True, NO_WINDOW, id="causal"),
    pytest.param(False, (128, 0), id="window-left128"),
]


def _run(
    s_q,
    s_k,
    is_persistent,
    is_causal=False,
    window_size=NO_WINDOW,
    h_q=8,
    h_k=8,
    head_dim=128,
    mma_tiler_mn=(64, 128),
    in_dtype=F16,
    out_dtype=F16,
    bottom_right_align=False,
    tolerance=1e-2,
    skip_ref_check=False,
):
    batch = len(s_q) if isinstance(s_q, tuple) else len(s_k)
    run(
        q_shape=(batch, s_q, h_q, head_dim),
        k_shape=(batch, s_k, h_k, head_dim),
        in_dtype=in_dtype,
        out_dtype=out_dtype,
        qk_acc_dtype=F32,
        pv_acc_dtype=F32,
        mma_tiler_mn=mma_tiler_mn,
        is_persistent=is_persistent,
        is_causal=is_causal,
        bottom_right_align=bottom_right_align,
        scale_q=1.0,
        scale_k=1.0,
        scale_v=1.0,
        inv_scale_o=1.0,
        scale_softmax=0.0,
        window_size=window_size,
        tolerance=tolerance,
        warmup_iterations=0,
        iterations=1,
        skip_ref_check=skip_ref_check,
        use_cold_l2=False,
    )


@pytest.mark.parametrize(
    "h_q, h_k", [(8, 8), (8, 2), (8, 1)], ids=["mha", "gqa4", "mqa"]
)
@pytest.mark.parametrize("is_causal, window_size", MASK_CASES)
@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_masks_and_heads(is_persistent, is_causal, window_size, h_q, h_k):
    _run(
        SEQLENS,
        SEQLENS,
        is_persistent,
        is_causal=is_causal,
        window_size=window_size,
        h_q=h_q,
        h_k=h_k,
    )


@pytest.mark.parametrize("is_causal", [False, True], ids=["no-mask", "causal"])
@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_different_q_k_lengths(is_persistent, is_causal):
    # The causal mask is bottom-right aligned since each s_k >= s_q
    _run(
        (1, 0, 65, 300, 129),
        (77, 0, 65, 512, 200),
        is_persistent,
        is_causal=is_causal,
        h_q=8,
        h_k=2,
        bottom_right_align=is_causal,
    )


@pytest.mark.parametrize(
    "s_q, s_k",
    [
        pytest.param((1, 65, 300, 129), 256, id="varlen-q"),
        pytest.param(129, (1, 65, 300, 129), id="varlen-k"),
    ],
)
@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_q_or_k_only(is_persistent, s_q, s_k):
    _run(s_q, s_k, is_persistent, is_causal=True, h_q=8, h_k=2)


@pytest.mark.parametrize(
    "head_dim, mma_tiler_mn, is_persistent",
    [
        pytest.param(64, (64, 128), True, id="d64-persistent"),
        pytest.param(256, (64, 64), False, id="d256"),
    ],
)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_head_dims(head_dim, mma_tiler_mn, is_persistent):
    _run(
        SEQLENS,
        SEQLENS,
        is_persistent,
        is_causal=True,
        head_dim=head_dim,
        mma_tiler_mn=mma_tiler_mn,
    )


@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_bf16():
    _run(SEQLENS, SEQLENS, True, is_causal=True, in_dtype=BF16, out_dtype=BF16)


@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_varlen_fp8():
    # FP8 V is s-major, so each key length must be a multiple of 16
    _run(
        SEQLENS,
        (16, 0, 64, 64, 80, 128, 144, 704),
        False,
        is_causal=True,
        bottom_right_align=True,
        in_dtype=F8E4,
        out_dtype=F8E4,
        tolerance=0.13,
    )


@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_varlen_empty_keys(is_persistent):
    # Query rows of a sequence without keys are not written, so only check
    # that the kernel skips the sequence and completes.
    _run((64, 129, 1), (64, 0, 1), is_persistent, skip_ref_check=True)


@pytest.mark.L0(0)
def test_l0_default_softmax_scale_uses_head_dim_for_a_non_square_shape():
    """`run`'s default (scale_softmax=0.0) is 1/sqrt(head_dim), also when S_q is
    packed and differs from head_dim. ``1/sqrt(S_q)`` would silently change the
    result for a non-square shape, and S_q is a tuple on a variable-length side."""
    # S_q = 129 (packed) and S_q = 700, both with head_dim = 64.
    assert default_softmax_scale((3, (1, 65, 300, 129), 8, 64)) == pytest.approx(1 / 8)
    assert default_softmax_scale((3, 700, 8, 64)) == pytest.approx(1 / 8)
    assert default_softmax_scale((2, 129, 8, 128)) == pytest.approx(1 / 128**0.5)
