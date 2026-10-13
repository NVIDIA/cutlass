# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import json
import os
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from bloom import build as bloom_build
from cutlass_cicd.cutlass_cpp import build as cutlass_build


class BloomBuildTest(unittest.TestCase):
    def test_test_only_build_matches_package_only_archive_workflow(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source_dir = root / "source"
            workspace = root / "workspace"
            output = root / "build.tar.gz"
            params_file = root / "buildSpec.json"

            version_header = source_dir / "include" / "cutlass" / "version.h"
            version_header.parent.mkdir(parents=True)
            version_header.write_text(
                "#define CUTLASS_MAJOR 4\n"
                "#define CUTLASS_MINOR 5\n"
                "#define CUTLASS_PATCH 0\n",
                encoding="utf-8",
            )
            params_file.write_text(
                json.dumps(
                    {
                        "buildSpecCommon": {
                            "arch": "x86_64",
                            "compiler": "gcc",
                            "cuda": "12.9",
                            "jobCommon": {
                                "branchSpec": {"ref": "refs/heads/main"}
                            },
                            "os": "linux",
                            "packagingLevel": "package_only",
                        },
                        "scmProperties": {
                            "buildId": "dummy-build",
                            "buildRef": "0123456789abcdef",
                        },
                    }
                ),
                encoding="utf-8",
            )

            with patch.object(cutlass_build.shutil, "which", return_value=None):
                with patch.object(
                    cutlass_build.subprocess,
                    "check_call",
                ) as check_call:
                    result = bloom_build.main(
                        [
                            "-s",
                            str(source_dir),
                            "-w",
                            str(workspace),
                            "-o",
                            str(output),
                            "--params",
                            str(params_file),
                        ]
                    )

            self.assertEqual(result, 0)
            check_call.assert_called_once()
            self.assertEqual(
                check_call.call_args.args[0],
                ["nvcc", "--version"],
            )
            self.assertTrue((workspace / "install" / "build_params.json").is_file())
            self.assertTrue((workspace / "install" / "nvcc-v.txt").is_file())

            with tarfile.open(output, "r:gz") as archive:
                self.assertTrue(
                    {
                        "cutlass-4.5.0/build_params.json",
                        "cutlass-4.5.0/nvcc-v.txt",
                    }.issubset(archive.getnames())
                )
                build_params = json.load(
                    archive.extractfile("cutlass-4.5.0/build_params.json")
                )

            self.assertEqual(build_params["version"], "4.5.0")
            self.assertEqual(build_params["compile_type"], "release")
            self.assertEqual(build_params["cutlass_variant"], ["12.9", "x86_64", "linux", "gcc"])
            self.assertTrue(build_params["package_only"])

    def test_premerge_architecture_suffixes_are_preserved_in_order(self) -> None:
        cases = {
            "sm80;86;87;89": ("80", "86", "87", "89"),
            "sm90;90a": ("90", "90a"),
            "sm100a": ("100a",),
        }

        for suffix, expected in cases.items():
            with self.subTest(suffix=suffix):
                self.assertEqual(
                    cutlass_build.architectures_from_build_suffix(suffix),
                    expected,
                )

    def test_cmake_command_applies_extra_flags_after_legacy_defaults(self) -> None:
        config = {
            "arch": "x86_64",
            "compileType": "release",
            "extraBuildFlags": {
                "CUTLASS_BUILD_FOR_PROFILER_REGRESSIONS": "ON",
                "CUTLASS_USE_INTERNAL_TMA_DESC": "OFF",
                "CUTLASS_ENABLE_CUBLAS": "OFF",
                "CUTLASS_ENABLE_CUDNN": "OFF",
            },
            "os": "linux_rocky",
            "buildSuffix": "sm100a",
        }

        command = cutlass_build.cmake_configure_command(
            Path("/source"),
            Path("/workspace"),
            config,
        )

        self.assertIn("-DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc", command)
        self.assertNotIn("-DCMAKE_BUILD_TYPE=Release", command)
        self.assertIn("-DCUTLASS_NVCC_ARCHS=100a", command)
        self.assertLess(
            command.index("-DCUTLASS_ENABLE_CUBLAS=ON"),
            command.index("-DCUTLASS_ENABLE_CUBLAS=OFF"),
        )
        self.assertEqual(
            command[-4:],
            (
                "-DCUTLASS_BUILD_FOR_PROFILER_REGRESSIONS=ON",
                "-DCUTLASS_USE_INTERNAL_TMA_DESC=OFF",
                "-DCUTLASS_ENABLE_CUBLAS=OFF",
                "-DCUTLASS_ENABLE_CUDNN=OFF",
            ),
        )

    def test_cmake_command_applies_bloom_suffix_and_compiler_flags(self) -> None:
        config = {
            "arch": "x86_64",
            "buildSuffix": "clang17_device_sm100f;120f",
            "compileType": "debug",
            "compiler": "clang_17.0.6",
            "os": "linux_rocky",
        }

        command = cutlass_build.cmake_configure_command(
            Path("/source"),
            Path("/workspace"),
            config,
        )

        clang = "/home/utils/clang-17/bin/clang++"
        self.assertIn("-DCMAKE_BUILD_TYPE=Debug", command)
        self.assertIn("-DCMAKE_DEBUG_POSTFIX=d", command)
        self.assertIn("-DCUTLASS_NVCC_ARCHS=100f;120f", command)
        self.assertIn(f"-DCMAKE_CXX_COMPILER={clang}", command)
        self.assertIn(f"-DCMAKE_CUDA_HOST_COMPILER={clang}", command)
        self.assertIn(
            "-DCMAKE_CXX_FLAGS=-D__NV_NO_HOST_COMPILER_CHECK=1",
            command,
        )
        self.assertLess(
            command.index("-DCMAKE_CXX_COMPILER=clang++"),
            command.index(f"-DCMAKE_CXX_COMPILER={clang}"),
        )

    def test_build_all_kernels_suffix_does_not_require_an_sm(self) -> None:
        command = cutlass_build.cmake_configure_command(
            Path("/source"),
            Path("/workspace"),
            {
                "arch": "x86_64",
                "buildSuffix": "build_all_kernels",
                "os": "linux",
            },
        )

        self.assertIn("-DCUTLASS_LIBRARY_KERNELS=all", command)
        self.assertFalse(
            any(argument.startswith("-DCUTLASS_NVCC_ARCHS=") for argument in command)
        )

    def test_performance_build_includes_profiler_target(self) -> None:
        command = cutlass_build.cmake_build_command(
            Path("/workspace"),
            "16",
            {"artifactUrl": "https://artifacts/build-perf-sm100.tar.gz"},
        )

        self.assertEqual(
            command,
            (
                "cmake",
                "--build",
                "/workspace",
                "--verbose",
                "--target",
                "cutlass_profiler",
                "install",
                "--parallel",
                "16",
            ),
        )

    def test_cmake_allows_native_build_without_an_sm_suffix(self) -> None:
        command = cutlass_build.cmake_configure_command(
            Path("/source"),
            Path("/workspace"),
            {"arch": "x86_64", "buildSuffix": "premerge", "os": "windows"},
        )

        self.assertIn("-DTARGET_PLATFORM=x86_64", command)
        self.assertFalse(
            any(argument.startswith("-DCUTLASS_NVCC_ARCHS=") for argument in command)
        )

    def test_non_package_build_invokes_cmake_before_packaging(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source_dir = root / "source"
            workspace = root / "workspace"
            output = root / "build.tar.gz"
            params_file = root / "buildSpec.json"

            version_header = source_dir / "include" / "cutlass" / "version.h"
            version_header.parent.mkdir(parents=True)
            version_header.write_text(
                "#define CUTLASS_MAJOR 4\n"
                "#define CUTLASS_MINOR 6\n"
                "#define CUTLASS_PATCH 1\n",
                encoding="utf-8",
            )
            params_file.write_text(
                json.dumps(
                    {
                        "buildSpecCommon": {
                            "arch": "x86_64",
                            "buildSuffix": "sm90;90a",
                            "compileType": "release",
                            "compiler": "gcc_11.2.0",
                            "cuda": "12.9_external",
                            "jobCommon": {
                                "branchSpec": {"ref": "refs/heads/main"}
                            },
                            "os": "linux_rocky",
                        },
                        "scmProperties": {
                            "buildId": "full-build",
                            "buildRef": "0123456789abcdef",
                        },
                    }
                ),
                encoding="utf-8",
            )

            call_order = []

            def record_build(*_args):
                call_order.append("build")

            def record_package(*_args):
                call_order.append("package")

            with patch.object(
                cutlass_build,
                "build_install",
                side_effect=record_build,
            ):
                with patch.object(
                    cutlass_build,
                    "package_build",
                    side_effect=record_package,
                ):
                    result = bloom_build.main(
                        [
                            "-s",
                            str(source_dir),
                            "-w",
                            str(workspace),
                            "-o",
                            str(output),
                            "--params",
                            str(params_file),
                            "--num-processors",
                            "16",
                        ]
                    )

            self.assertEqual(result, 0)
            self.assertEqual(call_order, ["build", "package"])

    def test_cmake_configure_is_retried_once_before_install(self) -> None:
        with patch.object(
            cutlass_build.CommandRunner,
            "run",
            side_effect=(1, 0, 0),
        ) as run:
            cutlass_build.build_install(
                Path("/source"),
                Path("/workspace"),
                {
                    "arch": "x86_64",
                    "buildSuffix": "sm100a",
                    "os": "linux",
                },
                "8",
            )

        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args_list[0].args[0].name, "cmake_configure")
        self.assertEqual(run.call_args_list[1].args[0].name, "cmake_configure")
        self.assertEqual(run.call_args_list[2].args[0].name, "cmake_install")

    def test_debug_build_is_not_packaged(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            output = root / "build.tar.gz"

            with patch.object(cutlass_build, "normalize_install_tree") as normalize:
                cutlass_build.package_build(
                    root / "workspace",
                    output,
                    "4.8.0",
                    {"compile_type": "debug", "package_only": False},
                )

            normalize.assert_not_called()
            self.assertFalse(output.exists())

    def test_normalize_install_tree_matches_legacy_lib_layout(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            install_dir = Path(temp_dir) / "install"
            (install_dir / "include").mkdir(parents=True)
            (install_dir / "include" / "cudnn.h").write_text("internal")
            (install_dir / "lib").mkdir()
            (install_dir / "lib" / "libcutlass.a").write_text("cutlass")
            (install_dir / "lib64").mkdir()
            (install_dir / "lib64" / "libexisting.a").write_text("existing")

            cutlass_build.normalize_install_tree(install_dir, package_only=False)

            self.assertFalse((install_dir / "include" / "cudnn.h").exists())
            self.assertTrue((install_dir / "lib").is_symlink())
            self.assertEqual(os.readlink(install_dir / "lib"), "lib64")
            self.assertTrue((install_dir / "lib64" / "libcutlass.a").is_file())
            self.assertTrue((install_dir / "lib64" / "libexisting.a").is_file())
            self.assertEqual(
                os.readlink(install_dir / "lib64" / "libcutlassd.a"),
                "libcutlass.a",
            )

    def test_workspace_containing_source_is_never_cleaned(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            workspace = Path(temp_dir)
            source_dir = workspace / "source"
            source_dir.mkdir()
            marker = source_dir / "keep-me"
            marker.write_text("source", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "must not contain"):
                cutlass_build.prepare_workspace(workspace, source_dir)

            self.assertEqual(marker.read_text(encoding="utf-8"), "source")

    def test_unmarked_nonempty_workspace_is_never_cleaned(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            workspace = root / "workspace"
            source_dir = root / "source"
            workspace.mkdir()
            source_dir.mkdir()
            marker = workspace / "keep-me"
            marker.write_text("unrelated", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "unmarked, non-empty"):
                cutlass_build.prepare_workspace(workspace, source_dir)

            self.assertEqual(marker.read_text(encoding="utf-8"), "unrelated")

    def test_marked_workspace_can_be_safely_recreated(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            workspace = root / "workspace"
            source_dir = root / "source"
            workspace.mkdir()
            source_dir.mkdir()
            (workspace / cutlass_build._WORKSPACE_MARKER).touch()
            stale_file = workspace / "stale-build-output"
            stale_file.write_text("stale", encoding="utf-8")

            cutlass_build.prepare_workspace(workspace, source_dir)

            self.assertFalse(stale_file.exists())
            self.assertTrue(
                (workspace / cutlass_build._WORKSPACE_MARKER).is_file()
            )

    def test_workspace_symlink_is_rejected_before_resolution(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            target = root / "target"
            workspace = root / "workspace"
            target.mkdir()
            workspace.symlink_to(target, target_is_directory=True)

            with self.assertRaisesRegex(ValueError, "must not be a symlink"):
                cutlass_build._resolve_workspace(str(workspace))

            self.assertTrue(target.is_dir())


if __name__ == "__main__":
    unittest.main()
