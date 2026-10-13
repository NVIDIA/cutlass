# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from cutlass_cicd.common.env import detect_cuda_home, detect_cuda_major
from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.tests import distributed
from cutlass_cicd.cutedsl.tests.cute_export import (
    CUTE_EXPORT_TESTS,
    run_cute_export_flow,
)
from cutlass_cicd.cutedsl.tests.examples import collect_example_files


class CutedslFlowTest(unittest.TestCase):
    def make_context(self, root: Path) -> TestContext:
        source_dir = root / "source"
        workspace = root / "workspace"
        package_dir = root / "package"
        source_dir.mkdir()
        workspace.mkdir()
        return TestContext(
            source_dir=source_dir,
            workspace=workspace,
            sm="100",
            python="/tmp/wheel_test/bin/python",
            cuda_major=12,
            arch="x86_64",
            package_dir=package_dir,
            setup_environment=False,
        )

    def create_test_files(self, context: TestContext, tests: tuple) -> None:
        example_root = context.source_dir / "examples" / "python" / "CuTeDSL"
        for _, rel_path, _ in tests:
            test_path = example_root.joinpath(*rel_path.split("/"))
            test_path.parent.mkdir(parents=True, exist_ok=True)
            test_path.write_text("", encoding="utf-8")

    def test_cuda_major_uses_detected_cuda_home(self) -> None:
        with patch.dict(
            os.environ,
            {"CUDA_TOOLKIT_PATH": "/opt/toolkits/cuda-13.1"},
            clear=True,
        ):
            self.assertEqual(detect_cuda_home(), "/opt/toolkits/cuda-13.1")
            self.assertEqual(detect_cuda_major(), 13)

    def test_cuda_major_defaults_to_13_when_not_detected(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(detect_cuda_major(), 13)

    def test_example_collection_selects_only_runnable_sm100_entrypoints(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            example_root = context.source_dir / "examples" / "python" / "CuTeDSL"
            candidates = {
                "dsl_tutorials/run_me.py": True,
                "dsl_tutorials/no_main.py": False,
                "dsl_tutorials/benchmark_gemm.py": True,
                "dsl_tutorials/test_helper.py": True,
                "dsl_tutorials/jax/run_jax.py": True,
                "cute/blackwell/kernel.py": True,
                "cute/blackwell/kernel_103.py": True,
            }
            for rel_path, has_main in candidates.items():
                path = example_root / rel_path
                path.parent.mkdir(parents=True, exist_ok=True)
                source = (
                    "if __name__ == '__main__':\n    pass\n"
                    if has_main
                    else "pass\n"
                )
                path.write_text(source, encoding="utf-8")

            collected = {
                path.relative_to(example_root).as_posix()
                for path in collect_example_files(context)
            }

            self.assertEqual(
                collected,
                {
                    "cute/blackwell/kernel.py",
                    "dsl_tutorials/jax/run_jax.py",
                    "dsl_tutorials/run_me.py",
                },
            )

    def test_blackwell_only_iket_example_is_not_collected_on_sm80(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            example_root = context.source_dir / "examples" / "python" / "CuTeDSL"
            example_path = example_root / "dsl_tutorials/fp16_gemm_4_iket.py"
            example_path.parent.mkdir(parents=True)
            example_path.write_text(
                "if __name__ == '__main__':\n    pass\n",
                encoding="utf-8",
            )

            self.assertNotIn(
                example_path,
                collect_example_files(replace(context, sm="80")),
            )
            for sm in ("100", "103"):
                with self.subTest(sm=sm):
                    self.assertIn(
                        example_path,
                        collect_example_files(replace(context, sm=sm)),
                    )

    def test_sm120_extra_example_runs_only_on_sm120(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            example_root = context.source_dir / "examples" / "python" / "CuTeDSL"
            rel_path = (
                "cute_ext/blackwell/dense_gemm/"
                "sm120_dense_block_scaled_gemm_persistent_pingpong.py"
            )
            example_path = example_root / rel_path
            example_path.parent.mkdir(parents=True)
            example_path.write_text(
                "if __name__ == '__main__':\n    pass\n",
                encoding="utf-8",
            )

            for sm in ("100", "103"):
                with self.subTest(sm=sm):
                    self.assertNotIn(
                        example_path,
                        collect_example_files(replace(context, sm=sm)),
                    )

            self.assertIn(
                example_path,
                collect_example_files(replace(context, sm="120")),
            )

    def test_example_collection_excludes_unregistered_distributed_tests(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            example_root = context.source_dir / "examples" / "python" / "CuTeDSL"
            example_path = (
                example_root
                / "cute/blackwell/kernel/distributed/unregistered_distributed_test.py"
            )
            example_path.parent.mkdir(parents=True)
            example_path.write_text(
                "if __name__ == '__main__':\n    pass\n",
                encoding="utf-8",
            )

            for sm in ("100", "103"):
                with self.subTest(sm=sm):
                    self.assertNotIn(
                        example_path,
                        collect_example_files(replace(context, sm=sm)),
                    )

    def test_export_commands_set_missing_cuda_home_from_package(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            self.create_test_files(context, CUTE_EXPORT_TESTS)
            packaged_cuda = context.package_dir / "third_party" / "cuda"
            packaged_cuda.mkdir(parents=True)
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            with patch.dict(os.environ, {}, clear=True):
                run_cute_export_flow(context, runner)

            self.assertEqual(len(results), len(CUTE_EXPORT_TESTS))
            for result in results:
                assert result.command is not None
                self.assertEqual(result.command.env["CUDA_HOME"], str(packaged_cuda))

    def test_export_commands_do_not_override_existing_cuda_home(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            self.create_test_files(context, CUTE_EXPORT_TESTS)
            results = []
            runner = CommandRunner(dry_run=True, collect_result=results.append)

            with patch.dict(os.environ, {"CUDA_HOME": "/opt/cuda"}, clear=True):
                run_cute_export_flow(context, runner)

            for result in results:
                assert result.command is not None
                self.assertNotIn("CUDA_HOME", result.command.env)

    def test_single_gpu_skips_only_multicast_distributed_tests(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            context = self.make_context(Path(temp_dir))
            self.create_test_files(context, distributed.DISTRIBUTED_TESTS)
            results = []
            runner = CommandRunner(dry_run=False, collect_result=results.append)

            with (
                patch.object(distributed.sys, "version_info", (3, 12)),
                patch.object(distributed, "detect_gpu_count", return_value=1),
                patch.object(runner, "run", return_value=0) as run,
            ):
                distributed.run_distributed_flow(context, runner)

            skipped = {result.name for result in results if result.skipped}
            self.assertEqual(skipped, distributed.MULTICAST_TESTS)
            self.assertEqual(
                run.call_count,
                len(distributed.DISTRIBUTED_TESTS) - len(distributed.MULTICAST_TESTS),
            )
            for call in run.call_args_list:
                command = call.args[0]
                self.assertNotIn(command.name, distributed.MULTICAST_TESTS)
                process_count_index = command.args.index("--nproc-per-node") + 1
                self.assertEqual(command.args[process_count_index], "1")


if __name__ == "__main__":
    unittest.main()
