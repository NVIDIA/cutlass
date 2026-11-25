# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Focused autotuning tests; compilation and GPU timings are mocked."""

import unittest
from contextlib import contextmanager
from unittest.mock import Mock, patch

from cutlass import cute
from cutlass import testing
from cutlass.cute.testing import autotune_jit


class Kernel:
    stages = 1

    def __init__(self, dtype="float32", *, layout="row", tile=1, workspace=2):
        self.dtype, self.layout = dtype, layout
        self.tile, self.workspace = tile, workspace

    @cute.jit
    def __call__(self, size):
        pass


def make_target(kind):
    if kind == "class":
        return Kernel

    @cute.jit
    def kernel(size, tile=1, stages=1):
        pass

    return kernel


@contextmanager
def backend():
    def compile_kernel(*args, **kwargs):
        compiled = Mock()
        compiled.execution_args.get_constexpr_args.return_value = []
        return compiled

    benchmark = Mock(return_value=1.0)
    with (
        patch.object(cute, "compile", side_effect=compile_kernel) as compile_mock,
        patch.object(testing, "_benchmark_for_autotune", benchmark),
    ):
        yield compile_mock, benchmark


class TestAutotune(unittest.TestCase):
    def test_selects_fastest_config_and_caches(self):
        # Check that the autotuner selects the fastest configuration and caches it for future calls.
        for kind in ("function", "class"):
            with self.subTest(kind=kind), backend() as (compile_mock, benchmark):
                benchmark.side_effect = [3.0, 1.0, 3.0, 1.0]
                tuned = autotune_jit(
                    params_dict={"tile": [1, 2]}, update_on_change=["size"]
                )(make_target(kind))
                if kind == "class":
                    tuned = tuned()
                result = tuned(size=16)

                # Tile=2 is the second candidate and takes 1.0 us versus 3.0 us.
                # Its compiled kernel must be cached, called, and its result returned.
                best = benchmark.call_args_list[1].args[0]
                self.assertEqual(tuned._best_config[(16,)], {"tile": 2})
                self.assertIs(tuned._best_kernel[(16,)], best)
                self.assertIs(result, best.return_value)
                best.assert_called_once_with(size=16)

                # Positional size=16 must reuse the winner cached by the keyword call.
                self.assertIs(tuned(16), best.return_value)
                # Both counts stay at two: no additional compilation or benchmarking.
                self.assertEqual(compile_mock.call_count, 2)
                self.assertEqual(benchmark.call_count, 2)
                best.assert_called_with(16)

                # A new size tries both configurations again, increasing both counts to four.
                tuned(32)
                self.assertEqual(compile_mock.call_count, 4)
                self.assertEqual(benchmark.call_count, 4)
                # Each runtime size has its own cached configuration.
                self.assertEqual(set(tuned._best_config), {(16,), (32,)})

    def test_class_constructor_attributes(self):
        # Check fixed constructor arguments, tuned/derived values, and class overrides.
        with backend() as (compile_mock, benchmark):
            benchmark.side_effect = [3.0, 1.0]
            TunedKernel = autotune_jit(
                params_dict={"tile": [1, 2], "stages": [3]},
                derived_params={"workspace": lambda tile: tile * 2},
                update_on_change=["size"],
            )(Kernel)
            # Decorating a class preserves its inheritance relationship.
            self.assertTrue(issubclass(TunedKernel, Kernel))
            tuned = TunedKernel("float16", layout="column")
            result = tuned(size=16)

            # Inspect the actual kernel instances passed to cute.compile.
            candidates = [entry.args[0] for entry in compile_mock.call_args_list]
            # Each instance gets its tuned tile, stages=3, and derived workspace=tile*2.
            self.assertEqual(
                [(k.tile, k.stages, k.workspace) for k in candidates],
                [(1, 3, 2), (2, 3, 4)],
            )
            # Every candidate receives the fixed positional dtype and keyword layout.
            self.assertTrue(
                all(k.dtype == "float16" and k.layout == "column" for k in candidates)
            )
            # Override stages on the instances without changing the original class.
            self.assertEqual(Kernel.stages, 1)
            # The faster candidate (tile=2) is selected and its result is returned.
            self.assertEqual(tuned._best_config[(16,)], {"tile": 2, "stages": 3})
            best = tuned._best_kernel[(16,)]
            best.assert_called_once_with(size=16)
            self.assertIs(result, best.return_value)
            # Recorded configurations include the derived constructor values.
            self.assertEqual(
                [entry["config"]["workspace"] for entry in tuned.get_timings(size=16)],
                [2, 4],
            )

    def test_get_timings(self):
        # Users can read results without knowing cache keys or changing cached data.
        for kind in ("function", "class"):
            with self.subTest(kind=kind), backend() as (compile_mock, benchmark):
                benchmark.side_effect = [3.0, 1.0]
                tuned = autotune_jit(
                    params_dict={"tile": [1, 2]},
                    derived_params={"stages": lambda tile: tile * 2},
                    update_on_change=["size"],
                )(make_target(kind))
                if kind == "class":
                    tuned = tuned()
                with self.assertRaisesRegex(KeyError, "call the kernel first"):
                    tuned.get_timings(size=16)
                tuned(16)
                timings = tuned.get_timings(size=16)
                self.assertEqual(
                    timings,
                    [
                        {"config": {"tile": 1, "stages": 2}, "time_us": 3.0},
                        {"config": {"tile": 2, "stages": 4}, "time_us": 1.0},
                    ],
                )
                timings[0]["config"]["tile"] = 99
                timings.pop()
                # Accessor returns fresh dictionaries and does not tune or execute.
                self.assertEqual(
                    tuned.get_timings(16)[0]["config"], {"tile": 1, "stages": 2}
                )
                self.assertEqual(len(tuned.get_timings(16)), 2)
                with self.assertRaises(KeyError):
                    tuned.get_timings(32)
                self.assertEqual(compile_mock.call_count, 2)
                self.assertEqual(benchmark.call_count, 2)
                tuned._best_kernel[(16,)].assert_called_once_with(16)

    def test_prune_configs(self):
        # Check pruning for functions and classes.
        for kind in ("function", "class"):
            with self.subTest(kind=kind), backend() as (compile_mock, benchmark):
                seen = []

                # Only tile is declared; the autotuner must not pass stages here.
                def prune(tile):
                    seen.append(tile)
                    return tile == 2

                tuned = autotune_jit(
                    params_dict={"tile": [1, 2], "stages": [2, 3]},
                    prune_configs=prune,
                )(make_target(kind))
                if kind == "class":
                    tuned = tuned()
                tuned(16)

                # Timings contain only the two configurations accepted by the predicate.
                self.assertEqual(
                    [entry["config"] for entry in tuned.get_timings(16)],
                    [{"tile": 2, "stages": 2}, {"tile": 2, "stages": 3}],
                )
                # Rejected configurations never reach compilation or benchmarking.
                self.assertEqual(compile_mock.call_count, 2)
                self.assertEqual(benchmark.call_count, 2)
                # Inspect compile arguments to confirm both accepted tiles are two.
                for entry in compile_mock.call_args_list:
                    tile = (
                        entry.args[0].tile if kind == "class" else entry.kwargs["tile"]
                    )
                    self.assertEqual(tile, 2)
                # The predicate sees all four combinations, including rejected ones.
                self.assertEqual(seen, [1, 1, 2, 2])

    def test_prune_configs_rejects_all(self):
        # Rejecting every configuration raises before compilation or benchmarking.
        for kind in ("function", "class"):
            with self.subTest(kind=kind), backend() as (compile_mock, benchmark):
                tuned = autotune_jit(
                    params_dict={"tile": [1, 2]},
                    prune_configs=lambda tile: False,
                )(make_target(kind))
                if kind == "class":
                    tuned = tuned()
                # With no accepted candidate, the autotuner must report no winner.
                with self.assertRaisesRegex(ValueError, "No best kernel found"):
                    tuned(16)
                # Pruning happens before compilation and benchmarking, so neither runs.
                compile_mock.assert_not_called()
                benchmark.assert_not_called()


if __name__ == "__main__":
    unittest.main()
