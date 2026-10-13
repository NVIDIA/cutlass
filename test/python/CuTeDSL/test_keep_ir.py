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
Unit tests for the IR dumps of compiled functions.

``KEEP=ir`` keeps the IR after canonicalize and CSE in
``JitFunctionArtifacts.MLIR``. ``KEEP=ir-debug`` keeps the raw IR, before any
pass, in ``JitFunctionArtifacts.MLIR_RAW``, and also in ``MLIR`` unless
``KEEP=ir`` is set too. The tests compile a small kernel, so they need a CUDA
GPU and skip without one.
"""

import os
import tempfile
import unittest
from unittest import mock

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import CuTeDSL


@cute.kernel
def _fill(t: cute.Tensor, value: cutlass.Int32):
    tidx, _, _ = cute.arch.thread_idx()
    t[tidx] = value


@cute.jit
def _launch(t: cute.Tensor, value: cutlass.Int32, threads: cutlass.Constexpr[int]):
    _fill(t, value).launch(grid=[1, 1, 1], block=[threads, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestKeepIR(unittest.TestCase):
    def setUp(self):
        self.dsl = CuTeDSL._get_dsl()
        self.t = from_dlpack(torch.zeros(32, dtype=torch.int32, device="cuda"))
        dump_dir = tempfile.TemporaryDirectory()
        self.addCleanup(dump_dir.cleanup)
        # No IR dumps to start with, whatever CUTE_DSL_KEEP says; each test
        # turns on the ones it checks.
        self.patch_envar(dump_dir=dump_dir.name, keep_ir_clean=False, keep_ir=False)

    def patch_envar(self, **settings):
        for name, value in settings.items():
            patcher = mock.patch.object(self.dsl.envar, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def artifacts(self):
        return cute.compile(_launch, self.t, 1, 32).artifacts

    def test_no_ir_without_keep(self):
        artifacts = self.artifacts()
        self.assertIsNone(artifacts.MLIR)
        self.assertIsNone(artifacts.MLIR_RAW)

    def test_keep_ir_keeps_the_clean_ir(self):
        self.patch_envar(keep_ir_clean=True)
        artifacts = self.artifacts()
        self.assertIn("cute.memref.store", artifacts.MLIR)
        self.assertIsNone(artifacts.MLIR_RAW)

    def test_keep_ir_debug_keeps_the_raw_ir(self):
        self.patch_envar(keep_ir=True)
        artifacts = self.artifacts()
        self.assertIn("cute.memref.store", artifacts.MLIR_RAW)
        self.assertEqual(artifacts.MLIR, artifacts.MLIR_RAW)

    def test_keep_ir_and_ir_debug_keep_both(self):
        """With both, MLIR holds the clean IR as with KEEP=ir alone, and the raw
        IR, which the clean dump used to hide, is in MLIR_RAW."""
        self.patch_envar(keep_ir_clean=True)
        clean = self.artifacts().MLIR
        self.patch_envar(keep_ir=True)
        artifacts = self.artifacts()
        self.assertEqual(artifacts.MLIR, clean)
        self.assertIn("cute.memref.store", artifacts.MLIR_RAW)
        self.assertNotEqual(artifacts.MLIR_RAW, clean)

    def test_clean_ir_keeps_source_locations(self):
        """The clean dump runs its passes on a clone of the module. A clone made
        through the textual IR lost the source locations line info asks for."""
        self.patch_envar(keep_ir_clean=True, lineinfo=True)
        self.assertIn(os.path.basename(__file__), self.artifacts().MLIR)


if __name__ == "__main__":
    unittest.main()
