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

"""Unit tests for the test-case MemPool.

These pin the properties the pool must hold for operands to stay independent:
distinct operands get distinct storage *and* distinct data, and a tensor never
runs past the end of its buffer. See the `test_utils.allocation` module docstring
for why independence is what the reference checks depend on.
"""

from unittest import mock

import pytest
import torch

import cutlass

from test_utils import allocation
from test_utils.allocation import (
    MAX_RANDOM_OFFSET,
    EmptyInitializationMode,
    MemPool,
    RandomIntInitializationMode,
    _pool_seed,
)

# Large enough that the aliasing signature (~K/2) and the legitimate
# random-walk spread (~0.5*sqrt(K)) are orders of magnitude apart.
K, M, N = 2048, 64, 64


def _span(shape: tuple[int, ...], stride: tuple[int, ...]) -> int:
    """Elements a strided view reaches: its largest index, plus one."""
    return 1 + sum((shape[i] - 1) * stride[i] for i in range(len(shape)))


def _operands() -> tuple[torch.Tensor, torch.Tensor]:
    """Return GEMM A (L,M,K) and B (L,K,N), both K-unit-stride, from one pool.

    ``randomly_offset`` is off so both operands start at offset 0. That makes the
    aliasing deterministic rather than a ~1/K coincidence of the random offsets,
    which is what made the original bug so intermittent.
    """
    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    a = pool.get(cutlass.Float8E5M2, (1, M, K), (M * K, K, 1), init, None, name="A")
    b = pool.get(cutlass.Float8E5M2, (1, K, N), (K * N, 1, K), init, None, name="B")
    return a, b


def test_distinct_operands_do_not_share_storage():
    a, b = _operands()
    assert a.untyped_storage().data_ptr() != b.untyped_storage().data_ptr()


def test_distinct_operands_hold_different_data():
    """Separate storage is not enough -- the *contents* must differ too.

    ``InitializationMode.create`` reseeds the RNG, so two buffers built from the
    same seed hold the same sequence and stay perfectly correlated even when they
    no longer overlap in memory.
    """
    a, b = _operands()
    n = min(a.numel(), b.numel())
    flat_a = a.flatten()[:n].to(torch.float32)
    flat_b = b.flatten()[:n].to(torch.float32)
    assert not torch.equal(flat_a, flat_b)


def test_operands_are_uncorrelated_enough_for_exact_accumulation():
    """The product must stay in the sqrt(K) regime, not the K regime.

    Operands drawn from {-1, -0.5, 0, 0.5, 1} give per-output-element
    sigma = 0.5*sqrt(K) ~ 22.6 here, so |out| stays far below K/8 = 256. Aliased
    operands instead put a diagonal at ~K/2 = 1024, which is what broke the
    fp16-accumulator exactness the reference checks rely on.
    """
    a, b = _operands()
    out = (a.to(torch.float32) @ b.to(torch.float32)).abs().max()
    assert float(out) < K / 8, (
        f"|out|max={float(out)} suggests correlated operands; expected the "
        f"random-walk regime around 0.5*sqrt({K})={0.5 * K**0.5:.1f}"
    )


def test_buffer_over_allocates_by_the_offset_bound_not_by_double():
    """A pooled buffer holds the data plus offset room, not twice the data.

    Sizing it ``2 * size_required`` made the over-allocation scale with the
    problem, which dominates the pool for large GEMMs. The offset only ever needs
    ``MAX_RANDOM_OFFSET`` elements of headroom.
    """
    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    shape, stride = (1, M, K), (M * K, K, 1)
    pool.get(cutlass.Float8E5M2, shape, stride, init, 16, name="A")

    (buffer,) = pool.tensors.values()
    assert buffer.numel() == _span(shape, stride) + MAX_RANDOM_OFFSET


def test_random_offset_is_bounded_but_still_varies():
    """Bounding the offset must not cost the alignment coverage it exists for.

    Alignment stress depends on the offset's residues modulo the alignments under
    test, not on its magnitude, so a bounded offset is as good as an unbounded one
    -- provided it still takes many distinct values and stays a multiple of the
    declared divisibility.
    """
    divisibility = 16
    shape, stride = (1, M, K), (M * K, K, 1)

    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    offsets = {
        pool.get(
            cutlass.Float8E5M2, shape, stride, init, divisibility, name="A"
        ).storage_offset()
        for _ in range(200)
    }

    assert len(offsets) > 1, "offset must still be randomised"
    assert all(o % divisibility == 0 for o in offsets)
    assert all(0 < o < MAX_RANDOM_OFFSET for o in offsets)
    # The bound is only safe if the buffer still covers the furthest tensor.
    (buffer,) = pool.tensors.values()
    assert max(offsets) + _span(shape, stride) <= buffer.numel()


def test_buffer_spans_the_tensor_without_double_counting():
    """A compact tensor must need exactly its element count, no more.

    The pool used to size buffers by ``sum(shape[i] * stride[i])``, which counts
    the outermost mode twice -- the outermost stride already covers everything
    beneath it -- and so over-allocated a compact tensor by close to 2x.
    """
    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    shape, stride = (1, M, K), (M * K, K, 1)
    pool.get(cutlass.Float8E5M2, shape, stride, init, None, name="A")

    (buffer,) = pool.tensors.values()
    numel = M * K
    assert buffer.numel() == numel + MAX_RANDOM_OFFSET
    # The discarded formula would have asked for roughly twice as much.
    assert sum(shape[i] * stride[i] for i in range(len(shape))) > 1.9 * numel


def test_rejects_degenerate_shapes():
    """An empty extent has no valid span, so it must be rejected outright."""
    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    with pytest.raises(ValueError, match="positive"):
        pool.get(cutlass.Float8E5M2, (1, 0, K), (0, K, 1), init, None, name="A")


def test_distinct_keys_get_distinct_seeds():
    """Every operand key in play must map to its own RNG stream.

    Two keys on one stream hold the same sequence, which recreates the operand
    correlation the per-name keying exists to prevent.
    """
    keys = [
        (name, str(dtype), str(mode))
        for name in ("A", "B", "out", "A_scale", "B_scale")
        for dtype in (cutlass.Float8E5M2, cutlass.BFloat16, cutlass.Float32)
        for mode in (
            RandomIntInitializationMode(min_val=-2, max_val=3, global_scale=0.5),
            RandomIntInitializationMode(min_val=-2, max_val=3, global_scale=1),
            EmptyInitializationMode(),
        )
    ]
    seeds = [_pool_seed(k) for k in keys]
    assert len(set(seeds)) == len(keys), "seed collision across live pool keys"


def test_seed_collision_is_reported_not_silently_accepted():
    """A collision must fail loudly; silently sharing data is the bug being fixed."""
    pool = MemPool(device="cpu")
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)
    shape, stride = (1, M, K), (M * K, K, 1)
    pool.get(cutlass.Float8E5M2, shape, stride, init, None, name="A")

    # Force the next distinct key onto the seed already claimed by "A".
    (claimed_seed,) = pool._seed_owners
    with (
        mock.patch.object(allocation, "_pool_seed", return_value=claimed_seed),
        pytest.raises(ValueError, match="derive seed"),
    ):
        pool.get(cutlass.Float8E5M2, shape, stride, init, None, name="B")


@pytest.mark.skipif(not torch.cuda.is_available(), reason="CUDA device required")
def test_worst_case_alignment_survives_a_host_generated_fill():
    """The random offset must still apply when the buffer is filled on the host.

    ``randomly_offset`` exists to hand the Operator a worst-case aligned pointer,
    so that an ``OperandConstraints`` alignment claim gets tested against
    something less friendly than a fresh allocation base.

    When the buffer cannot be generated on its own device it is generated on the
    host and copied over. That copy has to cover the whole backing store, before
    the offset view is taken -- copying the view instead reallocates, and while
    the strides survive, ``storage_offset`` resets to 0 and every operand comes
    back conveniently aligned. Nothing would fail; the coverage would just be
    gone, which is why it is pinned here.
    """
    divisibility = 16
    shape, stride = (1, M, K), (M * K, K, 1)
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)

    # Force the fill onto the host, as happens where torch has no kernels.
    with mock.patch.object(allocation, "reference_device", return_value="cpu"):
        pool = MemPool(device="cuda")
        tensor = pool.get(
            cutlass.Float8E5M2, shape, stride, init, divisibility, name="A"
        )

    assert tensor.is_cuda
    assert tensor.storage_offset() > 0, "the pool stopped offsetting its views"
    assert tensor.data_ptr() > tensor.untyped_storage().data_ptr(), (
        "tensor starts at the storage base, so it is aligned exactly as the "
        "allocator left it and the offset is not being tested"
    )


@pytest.mark.skipif(not torch.cuda.is_available(), reason="CUDA device required")
def test_host_generated_fill_holds_the_same_data_as_a_host_pool():
    """Generating on the host and copying over must not disturb the values.

    The fill picks its device from ``reference_device()`` rather than from the
    pool, so the same sequence is drawn either way and only the buffer's
    location changes.
    """
    shape, stride = (1, M, K), (M * K, K, 1)
    init = RandomIntInitializationMode.from_dtypes(cutlass.Float8E5M2, cutlass.BFloat16)

    with mock.patch.object(allocation, "reference_device", return_value="cpu"):
        on_device = MemPool(device="cuda").get(
            cutlass.Float8E5M2, shape, stride, init, None, name="A"
        )
        on_host = MemPool(device="cpu").get(
            cutlass.Float8E5M2, shape, stride, init, None, name="A"
        )

    assert torch.equal(on_device.cpu().to(torch.float32), on_host.to(torch.float32))
