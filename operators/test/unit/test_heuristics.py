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
Unit tests for the pluggable heuristics (ranking) layer of the Operator API.

These tests exercise the core seam only -- the ``Heuristic`` ABC, the registry,
and the optional ``heuristic=`` parameter on ``get_operators`` (including
narrowing to a subset of candidates, fail-loud ranking errors, and fail-loud
:class:`ImportError` for missing installs). They use sentinel objects in place
of real Operators and monkeypatch ``Manifest.get_operators``, so they need no
GPU and no concrete heuristic plugin.
"""

import pytest

import cutlass.operators as ops
from cutlass.operators.heuristics import (
    Heuristic,
    available_heuristics,
    get_heuristic,
    register_heuristic,
)


class _Sentinel:
    """A stand-in for an Operator; identity is all the ranking layer relies on."""

    def __init__(self, name: str):
        self.name = name

    def __repr__(self) -> str:
        return f"_Sentinel({self.name!r})"


class ReversingHeuristic(Heuristic):
    """Test heuristic that reverses the candidate order (a valid permutation)."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        return list(reversed(operators))


class SubsetHeuristic(Heuristic):
    """Valid heuristic that narrows to a subset of candidates (e.g. filter+rank)."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        return list(operators[:-1])


class DuplicatingHeuristic(Heuristic):
    """Invalid heuristic that duplicates a candidate beyond its original count."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        return [*operators, operators[0]]


class InventingHeuristic(Heuristic):
    """Invalid heuristic that returns an Operator not in the candidate list."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        return [*operators, _Sentinel("invented")]


class RaisingHeuristic(Heuristic):
    """Invalid heuristic that raises while ranking."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        raise RuntimeError("boom")


class TypeErrorHeuristic(Heuristic):
    """Heuristic that rejects unsupported args with TypeError (fail loud)."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        raise TypeError("expected GemmArguments")


class MutatingThenRaisingHeuristic(Heuristic):
    """Reorders ``operators`` in place, then raises (tests error propagation)."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        operators.reverse()
        raise RuntimeError("mutated then boom")


class MissingDepsHeuristic(Heuristic):
    """Heuristic that reports a missing optional install."""

    def rank(self, args, operators, *, target_sm=None, limit=None):
        raise ImportError("optional package 'fake-heuristics' is not installed")


class LimitCapturingHeuristic(Heuristic):
    """Records the ``limit`` passed into ``rank`` and reverses candidates."""

    last_limit = None

    def rank(self, args, operators, *, target_sm=None, limit=None):
        type(self).last_limit = limit
        return list(reversed(operators))


@pytest.fixture
def candidates(monkeypatch):
    """Three sentinel candidates returned by a stubbed ``Manifest.get_operators``."""
    ops_list = [_Sentinel("a"), _Sentinel("b"), _Sentinel("c")]
    monkeypatch.setattr(
        ops.Manifest,
        "get_operators",
        staticmethod(lambda *args, **kwargs: list(ops_list)),
    )
    return ops_list


class TestGetOperatorsHeuristicWiring:
    """Tests for the ``heuristic=`` parameter on ``get_operators``."""

    def test_no_heuristic_returns_unranked(self, candidates):
        """Without a heuristic, discovery order is unchanged (today's behavior)."""
        result = ops.get_operators()
        assert result == candidates

    def test_heuristic_instance_reorders(self, candidates):
        """A heuristic instance reorders the same objects best-first."""
        result = ops.get_operators(heuristic=ReversingHeuristic())
        assert result == list(reversed(candidates))
        # Same objects, only reordered.
        assert {id(op) for op in result} == {id(op) for op in candidates}

    def test_heuristic_string_is_rejected(self, candidates):
        """``get_operators`` only accepts a constructed Heuristic instance.

        A bare registry-name string is not resolved automatically -- some
        heuristics require constructor arguments (e.g.
        ``NvMatmulHeuristics(gpu=...)``), so ``get_operators`` cannot build one
        on the caller's behalf. Use :func:`~cutlass.operators.get_heuristic` to
        look up the class, then construct it explicitly.
        """
        register_heuristic("_test_reversing")(ReversingHeuristic)
        try:
            with pytest.raises(AttributeError):
                ops.get_operators(heuristic="_test_reversing")
        finally:
            available_heuristics.pop("_test_reversing", None)

    def test_raising_heuristic_propagates(self, candidates):
        """A ranking error must propagate when a heuristic was requested."""
        with pytest.raises(RuntimeError, match="boom"):
            ops.get_operators(heuristic=RaisingHeuristic())

    def test_inplace_mutation_then_raise_propagates(self, candidates):
        """In-place mutation before raise must not hide the ranking error."""
        with pytest.raises(RuntimeError, match="mutated then boom"):
            ops.get_operators(heuristic=MutatingThenRaisingHeuristic())

    def test_missing_deps_import_error_propagates(self, candidates):
        """A missing-install ImportError must not be swallowed."""
        with pytest.raises(ImportError, match="fake-heuristics"):
            ops.get_operators(heuristic=MissingDepsHeuristic())

    def test_type_error_propagates(self, candidates):
        """Invalid-usage TypeError must propagate when a heuristic is requested."""
        with pytest.raises(TypeError, match="GemmArguments"):
            ops.get_operators(heuristic=TypeErrorHeuristic())

    def test_subset_heuristic_returns_subset(self, candidates):
        """A heuristic may narrow to a subset (filter+rank) without raising."""
        result = ops.get_operators(heuristic=SubsetHeuristic())
        assert result == candidates[:-1]

    def test_duplicating_heuristic_raises(self, candidates):
        """A heuristic that duplicates a candidate beyond its count must raise."""
        with pytest.raises(RuntimeError, match="duplicated"):
            ops.get_operators(heuristic=DuplicatingHeuristic())

    def test_inventing_heuristic_raises(self, candidates):
        """A heuristic that returns an Operator outside the candidates must raise."""
        with pytest.raises(RuntimeError, match="not present"):
            ops.get_operators(heuristic=InventingHeuristic())

    def test_empty_candidate_list_is_ranked_trivially(self, monkeypatch):
        """An empty candidate list is a valid (empty) permutation, not a failure."""
        monkeypatch.setattr(
            ops.Manifest, "get_operators", staticmethod(lambda *a, **k: [])
        )
        assert ops.get_operators(heuristic=ReversingHeuristic()) == []

    def test_limit_without_heuristic_truncates_discovery_order(self, candidates):
        result = ops.get_operators(limit=2)
        assert result == candidates[:2]

    def test_limit_with_heuristic_forwards_and_truncates(self, candidates):
        LimitCapturingHeuristic.last_limit = None
        result = ops.get_operators(heuristic=LimitCapturingHeuristic(), limit=2)
        assert LimitCapturingHeuristic.last_limit == 2
        assert result == list(reversed(candidates))[:2]

    def test_non_positive_limit_raises(self, candidates):
        with pytest.raises(ValueError, match="positive"):
            ops.get_operators(limit=0)


class TestHeuristicRegistry:
    """Tests for the heuristic registry helpers."""

    def test_register_and_get_round_trip(self):
        register_heuristic("_test_roundtrip")(ReversingHeuristic)
        try:
            assert get_heuristic("_test_roundtrip") is ReversingHeuristic
            assert "_test_roundtrip" in available_heuristics
        finally:
            available_heuristics.pop("_test_roundtrip", None)

    def test_get_unknown_raises_keyerror(self):
        with pytest.raises(KeyError, match="_does_not_exist"):
            get_heuristic("_does_not_exist")

    def test_register_returns_class_unchanged(self):
        decorated = register_heuristic("_test_identity")(ReversingHeuristic)
        try:
            assert decorated is ReversingHeuristic
        finally:
            available_heuristics.pop("_test_identity", None)


def test_heuristic_is_abstract():
    """Heuristic cannot be instantiated without implementing ``rank``."""
    with pytest.raises(TypeError):
        Heuristic()
