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

"""
Regression tests for issue #3681: CUDA error formatting must not probe
the GPU through ``env_manager.arch``. That property re-enters the error
constructor when detection itself fails.
"""

import importlib.util
import sys
import types
import unittest
from pathlib import Path


def _load_target_arch_helper():
    try:
        from cutlass.base_dsl.common import _target_arch_from_env_manager

        return _target_arch_from_env_manager
    except ModuleNotFoundError:
        root = Path(__file__).resolve().parents[3] / "python" / "CuTeDSL" / "cutlass"
        cutlass = types.ModuleType("cutlass")
        cutlass.__path__ = [str(root)]
        sys.modules.setdefault("cutlass", cutlass)
        base_dsl = types.ModuleType("cutlass.base_dsl")
        base_dsl.__path__ = [str(root / "base_dsl")]
        sys.modules["cutlass.base_dsl"] = base_dsl

        def _load(name: str, path: Path):
            spec = importlib.util.spec_from_file_location(name, path)
            module = importlib.util.module_from_spec(spec)
            sys.modules[name] = module
            assert spec.loader is not None
            spec.loader.exec_module(module)
            return module

        _load("cutlass.base_dsl.diagnostics", root / "base_dsl" / "diagnostics.py")
        common = _load("cutlass.base_dsl.common", root / "base_dsl" / "common.py")
        return common._target_arch_from_env_manager


_target_arch_from_env_manager = _load_target_arch_helper()


class _ArchProbeEnv:
    def __init__(self, configured=None):
        self._arch = configured
        self.arch_reads = 0

    def configured_arch(self):
        return self._arch

    @property
    def arch(self):
        self.arch_reads += 1
        raise AssertionError("error formatting must not detect the GPU")


class TestTargetArchFromEnvManager(unittest.TestCase):
    def test_none_manager_is_unknown(self):
        self.assertEqual(_target_arch_from_env_manager(None), "unknown")

    def test_uses_configured_arch_without_reading_arch(self):
        env = _ArchProbeEnv("sm_100a")
        self.assertEqual(_target_arch_from_env_manager(env), "sm_100a")
        self.assertEqual(env.arch_reads, 0)

    def test_unset_configured_arch_is_unknown_without_reading_arch(self):
        env = _ArchProbeEnv(None)
        self.assertEqual(_target_arch_from_env_manager(env), "unknown")
        self.assertEqual(env.arch_reads, 0)


if __name__ == "__main__":
    unittest.main()
