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
Unit tests for the ``nvmatmul`` heuristic plugin.

Matcher tests use synthetic config dicts and real ``Sm100DesignMetadata`` (no
optional package, no GPU). End-to-end ``rank()`` is skipped when the optional
dependency is absent.
"""

from types import SimpleNamespace

import pytest

import cutlass.operators as ops
from cutlass.operators.heuristics.nvmatmul import (
    MIN_NVMMH_VERSION,
    NvMatmulHeuristics,
    is_available,
)
from cutlass.operators.heuristics.nvmatmul._mapping import (
    NvmmhQuery,
    _config_matches_design,
    _tile_k_penalty,
    match_operators_to_configs,
)
from cutlass.operators.heuristics.nvmatmul.ranker import _version_tuple
from cutlass.operators.metadata import Sm100DesignMetadata
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.utils.device import device_or_env_target_sm


def make_design(tile, cluster, *, use_2cta=False):
    """Build an Sm100DesignMetadata with the given tile/cluster shapes."""
    return Sm100DesignMetadata(
        mma_instruction_type=BlackwellTcgen05Mma,
        tile_shape=tile,
        cluster_shape=cluster,
        use_2cta_mma=use_2cta,
        use_tma_store=True,
    )


def make_operator(design, name="op", *, min_cc=100):
    """A minimal Operator stand-in exposing ``metadata.design``,
    ``metadata.operator_name``, and ``metadata.operator_class.designed_for_min_cc``.
    """
    return SimpleNamespace(
        metadata=SimpleNamespace(
            design=design,
            operator_name=name,
            operator_class=SimpleNamespace(designed_for_min_cc=min_cc),
        ),
        name=name,
    )


def make_config(cta_m, cta_n, cluster_m, cluster_n, *, runtime=1.0, cta_k=64):
    """A synthetic nvMMH config dict with the fields the matcher reads."""
    return {
        "cta_tile_m": cta_m,
        "cta_tile_n": cta_n,
        "cta_tile_k": cta_k,
        "cluster_m": cluster_m,
        "cluster_n": cluster_n,
        "estimated_runtime": runtime,
    }


class TestConfigMatchesDesign:
    """Tests for MMA tile / cluster / 2-CTA match predicate."""

    def test_exact_match_2cta(self):
        # 2-CTA: Operator MMA tiler M is 2 * nvMMH cta_tile_m.
        design = make_design((128, 256, 64), (2, 1, 1), use_2cta=True)
        config = make_config(64, 256, 2, 1)
        assert _config_matches_design(design, config)

    def test_exact_match_1cta(self):
        design = make_design((64, 64, 64), (1, 1, 1), use_2cta=False)
        assert _config_matches_design(design, make_config(64, 64, 1, 1))

    def test_tile_mismatch(self):
        design = make_design((128, 128, 64), (2, 1, 1), use_2cta=True)
        assert not _config_matches_design(design, make_config(64, 256, 2, 1))

    def test_cluster_mismatch(self):
        design = make_design((128, 256, 64), (4, 1, 1), use_2cta=True)
        assert not _config_matches_design(design, make_config(64, 256, 2, 1))

    def test_2cta_mode_mismatch(self):
        # Even cluster_m implies 2-CTA; a 1-CTA design must not match.
        design_1cta = make_design((128, 256, 64), (2, 1, 1), use_2cta=False)
        assert not _config_matches_design(design_1cta, make_config(64, 256, 2, 1))


class TestNvmmhQueryFromArgs:
    """``NvmmhQuery.from_args`` must reject non-dense operands early."""

    def test_rejects_scaled_operand(self):
        torch = pytest.importorskip("torch")
        m, n, k = 64, 64, 32
        a = ops.ScaledOperand(
            torch.empty((m, k), dtype=torch.float16),
            torch.empty((m, k // 32), dtype=torch.float16),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.SwizzleNone,
        )
        args = ops.GemmArguments(
            A=a,
            B=torch.empty((k, n), dtype=torch.float16),
            out=torch.empty((m, n), dtype=torch.float16),
            accumulator_type=torch.float32,
        )
        with pytest.raises(TypeError, match="dense GEMM only"):
            NvmmhQuery.from_args(args)


class TestTileKPenalty:
    """Tests for the CTA tile-K tie-breaker."""

    def test_direct_equal(self):
        assert _tile_k_penalty(64, 64) == 0

    def test_none_is_zero(self):
        assert _tile_k_penalty(None, 64) == 0
        assert _tile_k_penalty(64, None) == 0

    def test_positive_gap(self):
        assert _tile_k_penalty(128, 64) == 64
        assert _tile_k_penalty(64, 16) == 48


class TestMatchOperatorsToConfigs:
    """Tests for the operator reordering."""

    def test_orders_by_config_rank(self):
        design_a = make_design((128, 256, 64), (2, 1, 1), use_2cta=True)
        design_b = make_design((64, 64, 64), (1, 1, 1), use_2cta=False)
        op_a = make_operator(design_a, "a")
        op_b = make_operator(design_b, "b")
        # config[0] (best) matches op_b; config[1] matches op_a.
        configs = [
            make_config(64, 64, 1, 1, runtime=0.5),
            make_config(64, 256, 2, 1, runtime=0.9),
        ]
        # Input order deliberately reversed relative to nvMMH preference.
        result = match_operators_to_configs([op_a, op_b], configs, 100)
        assert result == [op_b, op_a]

    def test_unmatched_dropped(self):
        matched = make_operator(make_design((128, 256, 64), (2, 1, 1), use_2cta=True))
        unmatched_1 = make_operator(make_design((64, 32, 64), (1, 1, 1)), "u1")
        unmatched_2 = make_operator(make_design((64, 64, 64), (1, 1, 1)), "u2")
        configs = [make_config(64, 256, 2, 1)]
        result = match_operators_to_configs(
            [unmatched_1, matched, unmatched_2], configs, 100
        )
        assert result == [matched]

    def test_out_of_scope_operator_excluded(self):
        sm100 = make_operator(make_design((128, 256, 64), (2, 1, 1), use_2cta=True))
        # A lower designed_for_min_cc (e.g. an SM80 Operator portable to SM100) is currently
        # out of scope excluded.
        other = make_operator(None, "other", min_cc=80)
        configs = [make_config(64, 256, 2, 1)]
        result = match_operators_to_configs([other, sm100], configs, 100)
        assert result == [sm100]

    def test_no_matches_raises(self):
        ops_list = [make_operator(make_design((64, 32, 64), (1, 1, 1)), "u1")]
        with pytest.raises(ValueError, match="No candidate Operator matched"):
            match_operators_to_configs(ops_list, [make_config(64, 256, 2, 1)], 100)

    def test_empty_configs_raises_when_operators_present(self):
        ops_list = [
            make_operator(make_design((128, 256, 64), (2, 1, 1), use_2cta=True), "x"),
            make_operator(make_design((64, 64, 64), (1, 1, 1)), "y"),
        ]
        with pytest.raises(ValueError, match="No candidate Operator matched"):
            match_operators_to_configs(list(ops_list), [], 100)

    def test_all_out_of_scope_raises(self):
        # All out of scope means nothing can match, same as no candidate
        # matching any config -- an empty result is never returned silently.
        ops_list = [
            make_operator(None, "a", min_cc=90),
            make_operator(None, "b", min_cc=90),
        ]
        with pytest.raises(ValueError, match="No candidate Operator matched"):
            match_operators_to_configs(ops_list, [make_config(64, 256, 2, 1)], 100)

    def test_result_never_invents_or_duplicates(self):
        ops_list = [
            make_operator(make_design((128, 256, 64), (2, 1, 1), use_2cta=True), "x"),
            make_operator(make_design((64, 64, 64), (1, 1, 1)), "y"),
            make_operator(make_design((32, 32, 64), (1, 1, 1)), "z"),
        ]
        # Only "y" matches this config; "x" and "z" are dropped, not invented
        # or duplicated.
        configs = [make_config(64, 64, 1, 1)]
        result = match_operators_to_configs(list(ops_list), configs, 100)
        result_ids = [id(op) for op in result]
        assert len(result_ids) == len(set(result_ids))
        assert set(result_ids) <= {id(op) for op in ops_list}
        assert result == [ops_list[1]]


class TestConstructor:
    """``NvMatmulHeuristics(gpu=...)`` -- required, validated at construction."""

    def test_supported_sm100_devices(self):
        for gpu in ("B200", "GB200_NVL", "GB300_NVL"):
            assert NvMatmulHeuristics(gpu=gpu).modeled_cc == 100

    def test_unsupported_device_raises(self):
        with pytest.raises(ValueError, match="only supports SM100"):
            NvMatmulHeuristics(gpu="H100_SXM")

    def test_unrecognized_device_raises(self):
        with pytest.raises(ValueError, match="only supports SM100"):
            NvMatmulHeuristics(gpu="not_a_real_gpu")

    def test_gpu_defaults_to_b200(self):
        """``NvMatmulHeuristics()`` (no ``gpu=``) must keep working."""
        heuristic = NvMatmulHeuristics()
        assert heuristic.gpu == "B200"
        assert heuristic.modeled_cc == 100


class TestRankFallbacks:
    """Dependency-free ``rank()`` behaviors that must never touch nvMMH."""

    def test_empty_operators_returns_empty(self):
        assert NvMatmulHeuristics(gpu="B200").rank(None, []) == []

    def test_non_gemm_args_raises(self):
        ops_list = [make_operator(None, "a"), make_operator(None, "b")]
        with pytest.raises(TypeError, match="GemmArguments"):
            NvMatmulHeuristics(gpu="B200").rank(None, list(ops_list))

    def test_is_available_returns_bool(self):
        assert isinstance(is_available(), bool)

    def test_min_version_constant(self):
        assert MIN_NVMMH_VERSION == "0.1.0.27"
        assert _version_tuple("0.1.0.27") >= _version_tuple(MIN_NVMMH_VERSION)
        assert _version_tuple("0.1.0.26") < _version_tuple(MIN_NVMMH_VERSION)

    def test_too_old_version_is_unavailable(self, monkeypatch):
        import sys
        from types import ModuleType

        monkeypatch.setitem(
            sys.modules, "nvMatmulHeuristics", ModuleType("nvMatmulHeuristics")
        )
        monkeypatch.setattr(
            "cutlass.operators.heuristics.nvmatmul.ranker.package_version",
            lambda _name: "0.1.0.26",
        )
        assert is_available() is False

    def test_missing_deps_raise_import_error(self, monkeypatch):
        """Explicit nvmatmul use must fail loud when optional deps are absent."""
        import builtins

        real_import = builtins.__import__

        def _block_nvmmh(name, globals=None, locals=None, fromlist=(), level=0):
            if name == "nvMatmulHeuristics":
                raise ImportError(f"No module named {name!r}")
            return real_import(name, globals, locals, fromlist, level)

        monkeypatch.setattr(builtins, "__import__", _block_nvmmh)
        # Make any args look like GemmArguments so rank() reaches the import.
        monkeypatch.setattr(
            "cutlass.operators.heuristics.nvmatmul.ranker.GemmArguments",
            object,
        )
        ops_list = [make_operator(None, "a")]
        with pytest.raises(ImportError, match="nvidia-matmul-heuristics"):
            NvMatmulHeuristics(gpu="B200").rank(object(), ops_list)

    def test_limit_shrinks_get_configs_count(self, monkeypatch):
        """``limit`` must reduce nvMMH ``get_configs`` count (overfetch * limit)."""
        from cutlass.operators.heuristics.nvmatmul import ranker as ranker_mod

        captured: dict[str, object] = {}

        class _FakeMatmulHeuristics:
            def __init__(self, gpu=None):
                captured["gpu"] = gpu

            def get_configs(self, *args, **kwargs):
                captured["count"] = kwargs["count"]
                return []

        monkeypatch.setattr(ranker_mod, "is_available", lambda: True)
        monkeypatch.setattr(
            ranker_mod.NvmmhQuery,
            "from_args",
            staticmethod(
                lambda _args: SimpleNamespace(
                    m=1,
                    n=1,
                    k=1,
                    batch_count=1,
                    precision="HSH",
                    layouts=("n", "t", "n"),
                    align_a=8,
                    align_b=8,
                )
            ),
        )
        monkeypatch.setattr(
            ranker_mod,
            "match_operators_to_configs",
            lambda operators, _configs, _modeled_cc: operators,
        )
        monkeypatch.setattr(ranker_mod, "GemmArguments", object)
        monkeypatch.setattr(
            "cutlass.operators.heuristics.nvmatmul._provider.MatmulHeuristics",
            _FakeMatmulHeuristics,
        )

        ops_list = [
            make_operator(None, "a"),
            make_operator(None, "b"),
            make_operator(None, "c"),
        ]
        overfetch = ranker_mod._CONFIG_OVERFETCH_FACTOR

        NvMatmulHeuristics(gpu="B200").rank(object(), list(ops_list), limit=1)
        assert captured["count"] == overfetch * 1
        assert captured["gpu"] == "B200"

        NvMatmulHeuristics(gpu="B200").rank(object(), list(ops_list), limit=None)
        assert captured["count"] == overfetch * len(ops_list)


@pytest.mark.skipif(
    not is_available(),
    reason="nvMatmulHeuristics not installed",
)
class TestEndToEndRank:
    """End-to-end ranking; only runs where the optional dependencies exist."""

    def test_rank_returns_subset_of_sm100_candidates(self):
        torch = pytest.importorskip("torch")
        # target_sm=host_sm below only discovers native SM100 Operators when
        # the host actually is SM100.
        host_sm = device_or_env_target_sm()
        if host_sm.cc != 100:
            pytest.skip(
                f"nvmatmul e2e ranking requires SM100 host (cc=100); got {host_sm}"
            )

        args = ops.GemmArguments(
            A=torch.empty((512, 256), dtype=torch.float16),
            B=torch.empty((256, 128), dtype=torch.float16),
            out=torch.empty((512, 128), dtype=torch.float16),
            accumulator_type=torch.float32,
        )
        # Restrict to SM100 candidates: older-generation Operators are often
        # still portable to an SM100 target and would fall outside nvmatmul's
        # scope (covered separately by test_rank_excludes_out_of_scope_operators).
        candidates = ops.get_operators(
            args,
            target_sm=host_sm,
            metadata_filter=lambda md: md.operator_class.designed_for_min_cc == 100,
        )
        if not candidates:
            pytest.skip("No SM100 GEMM operators available to rank")
        ranked = NvMatmulHeuristics(gpu="B200").rank(
            args, list(candidates), target_sm=host_sm
        )
        # A candidate that matches no recommended config is dropped, so
        # ranked can be a strict subset -- never a superset or a duplicate.
        ranked_ids = [id(op) for op in ranked]
        assert len(ranked_ids) == len(set(ranked_ids))
        assert set(ranked_ids) <= {id(op) for op in candidates}

    def test_rank_excludes_out_of_scope_operators(self):
        torch = pytest.importorskip("torch")
        host_sm = device_or_env_target_sm()
        if host_sm.cc != 100:
            pytest.skip(
                f"nvmatmul e2e ranking requires SM100 host (cc=100); got {host_sm}"
            )

        args = ops.GemmArguments(
            A=torch.empty((512, 256), dtype=torch.float16),
            B=torch.empty((256, 128), dtype=torch.float16),
            out=torch.empty((512, 128), dtype=torch.float16),
            accumulator_type=torch.float32,
        )
        # No metadata_filter: discovery also returns older-generation
        # Operators that are portable to an SM100 target.
        candidates = ops.get_operators(args, target_sm=host_sm)
        older = [
            op
            for op in candidates
            if op.metadata.operator_class.designed_for_min_cc != 100
        ]
        if not older:
            pytest.skip("No older-generation GEMM operators discovered for this target")
        ranked = NvMatmulHeuristics(gpu="B200").rank(
            args, list(candidates), target_sm=host_sm
        )
        older_ids = {id(op) for op in older}
        assert not any(id(op) in older_ids for op in ranked), (
            "Older-generation Operators should be excluded from the ranked result"
        )
        assert all(
            op.metadata.operator_class.designed_for_min_cc == 100 for op in ranked
        )
