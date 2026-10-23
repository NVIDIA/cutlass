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
Pytest test suite for hopper/attention/fmha.py.

Test organization
-----------------
L0 — compile and launch once (skip_ref_check=True, iterations=1)
    Cover head dimensions, masks and persistent / non-persistent scheduling.

L1 — correctness tests (GPU execution, checked against a PyTorch reference)
    Validate output and LSE for the same configurations, plus GQA,
    unaligned sequence lengths, fp8 inputs and the bottom-right causal mask.

Head dimension 256 is supported only by the non-persistent kernel with an
N tile below 128, and by the persistent kernel with an N tile of 32 or less
(see ``HopperFusedMultiHeadAttentionForward.can_implement``).
"""

import pytest

import cutlass
from hopper.kernel.attention.fmha import run


F16 = cutlass.Float16
BF16 = cutlass.BFloat16
F32 = cutlass.Float32
F8E4 = cutlass.Float8E4M3FN

NO_WINDOW = (-1, -1)

# (head_dim, mma_tiler_mn, is_persistent)
HEAD_DIM_CASES = [
    pytest.param(32, (64, 128), False, id="d32"),
    pytest.param(32, (64, 128), True, id="d32-persistent"),
    pytest.param(64, (64, 128), False, id="d64"),
    pytest.param(64, (64, 128), True, id="d64-persistent"),
    pytest.param(128, (64, 128), False, id="d128"),
    pytest.param(128, (64, 128), True, id="d128-persistent"),
    pytest.param(256, (64, 64), False, id="d256"),
    pytest.param(256, (64, 32), True, id="d256-persistent"),
]

# (is_causal, window_size)
MASK_CASES = [
    pytest.param(False, NO_WINDOW, id="no-mask"),
    pytest.param(True, NO_WINDOW, id="causal"),
    pytest.param(False, (128, 0), id="window-left128"),
    pytest.param(False, (96, 64), id="window-96-64"),
]


def _run(
    head_dim,
    mma_tiler_mn,
    is_persistent,
    is_causal=False,
    window_size=NO_WINDOW,
    batch=2,
    s_q=512,
    s_k=512,
    h_q=4,
    h_k=4,
    in_dtype=F16,
    out_dtype=F16,
    bottom_right_align=False,
    tolerance=1e-2,
    skip_ref_check=False,
):
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


@pytest.mark.parametrize("head_dim, mma_tiler_mn, is_persistent", HEAD_DIM_CASES)
@pytest.mark.parametrize("is_causal, window_size", MASK_CASES)
@pytest.mark.L0
@pytest.mark.L1(0)
def test_l0_head_dims_and_masks(
    head_dim, mma_tiler_mn, is_persistent, is_causal, window_size
):
    _run(
        head_dim,
        mma_tiler_mn,
        is_persistent,
        is_causal=is_causal,
        window_size=window_size,
        skip_ref_check=True,
    )


@pytest.mark.parametrize("head_dim, mma_tiler_mn, is_persistent", HEAD_DIM_CASES)
@pytest.mark.parametrize("is_causal, window_size", MASK_CASES)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_head_dims_and_masks(
    head_dim, mma_tiler_mn, is_persistent, is_causal, window_size
):
    _run(
        head_dim,
        mma_tiler_mn,
        is_persistent,
        is_causal=is_causal,
        window_size=window_size,
    )


@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.parametrize("is_causal", [False, True], ids=["no-mask", "causal"])
@pytest.mark.parametrize(
    "s_q, s_k",
    [
        pytest.param(300, 300, id="s300"),
        pytest.param(129, 1000, id="sq129-sk1000"),
        pytest.param(1, 777, id="sq1-sk777"),
    ],
)
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_partial_tiles(is_persistent, is_causal, s_q, s_k):
    _run(
        128,
        (64, 128),
        is_persistent,
        is_causal=is_causal,
        s_q=s_q,
        s_k=s_k,
        bottom_right_align=is_causal and s_q != s_k,
    )


@pytest.mark.parametrize("h_q, h_k", [(8, 2), (8, 1)], ids=["gqa4", "mqa"])
@pytest.mark.parametrize("is_persistent", [False, True], ids=["", "persistent"])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_grouped_query_heads(h_q, h_k, is_persistent):
    _run(128, (64, 128), is_persistent, is_causal=True, h_q=h_q, h_k=h_k)


@pytest.mark.parametrize("head_dim, mma_tiler_mn", [(64, (64, 128)), (128, (64, 128))])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_bf16(head_dim, mma_tiler_mn):
    _run(head_dim, mma_tiler_mn, True, is_causal=True, in_dtype=BF16, out_dtype=BF16)


@pytest.mark.parametrize("head_dim", [64, 128, 256])
@pytest.mark.L0(0)
@pytest.mark.L1
def test_l1_fp8(head_dim):
    _run(
        head_dim,
        (64, 128),
        False,
        is_causal=True,
        in_dtype=F8E4,
        out_dtype=F8E4,
        tolerance=0.13,
    )
