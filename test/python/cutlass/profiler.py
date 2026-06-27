#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

import os
import subprocess
import unittest
from unittest import mock

_COMPILED_CACHE_FILE = "compiled_cache.db"
_COMPILED_CACHE_EXISTED = os.path.exists(_COMPILED_CACHE_FILE)

from cutlass_cppgen.backend.library import DataType
from cutlass_cppgen.utils import profiler as profiler_module


def tearDownModule():
    if not _COMPILED_CACHE_EXISTED and os.path.exists(_COMPILED_CACHE_FILE):
        os.remove(_COMPILED_CACHE_FILE)


class _TensorDescription:
    def __init__(self, element):
        self.element = element


class _Operation:
    A = _TensorDescription(DataType.f16)
    B = _TensorDescription(DataType.f16)
    C = _TensorDescription(DataType.f16)

    def __init__(self, procedural_name):
        self._procedural_name = procedural_name

    def procedural_name(self):
        return self._procedural_name

    def layout_name_3x(self):
        return self._procedural_name.split("_")[-2]


class _ProblemSize:
    def __init__(self, m, n, k):
        self._m = m
        self._n = n
        self._k = k

    @property
    def m(self):
        return self._m

    @property
    def n(self):
        return self._n

    @property
    def k(self):
        return self._k


class _Arguments:
    def __init__(self, problem_size, batch_count):
        self.problem_size = problem_size
        self.batch_count = batch_count


class CUDAEventProfilerTest(unittest.TestCase):
    def _make_profiler(self, kernel_name):
        profiler = profiler_module.CUDAEventProfiler.__new__(
            profiler_module.CUDAEventProfiler
        )
        profiler.operation = _Operation(kernel_name)
        profiler.arguments = _Arguments(_ProblemSize(16, 8, 4), 2)
        profiler.warmup_iterations = 3
        profiler.iterations = 5
        return profiler

    def test_run_cutlass_profiler_preserves_cutlass3x_input_layout_names(self):
        kernel_name = (
            "cutlass3x_sm90_tensorop_gemm_f16_f16_f32_f16_f16_"
            "128x128x32_1x1x1_0_tnt_align8"
        )
        expected_kernel_name = (
            "cutlass3x_sm90_tensorop_gemm_f16_f16_f32_f16_f16_"
            "128x128x32_1x1x1_0_tnn_align8"
        )
        profiler = self._make_profiler(kernel_name)
        output = """
           Runtime: 1.25  ms
             Bytes: 1408  bytes
             FLOPs: 2560  flops
        """

        with mock.patch.object(
            profiler_module.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 0, stdout=output, stderr=""),
        ) as run:
            runtime = profiler.run_cutlass_profiler()

        command = run.call_args.args[0]
        self.assertIsInstance(command, list)
        self.assertIn(f"--kernels={expected_kernel_name}", command)
        self.assertNotIn("--kernels=" + kernel_name.replace("_tnt_", "_nnn_"), command)
        self.assertIn("--m=8", command)
        self.assertIn("--n=16", command)
        self.assertEqual(runtime, 1.25)
        run.assert_called_once_with(
            command,
            check=True,
            capture_output=True,
            text=True,
        )

    def test_run_cutlass_profiler_raises_if_runtime_is_missing(self):
        profiler = self._make_profiler("cutlass_sm80_tensorop_gemm_f16")
        output = """
             Bytes: 1408  bytes
             FLOPs: 2560  flops
        """

        with mock.patch.object(
            profiler_module.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 0, stdout=output, stderr=""),
        ):
            with self.assertRaisesRegex(
                RuntimeError, "Could not parse profiler runtime"
            ):
                profiler.run_cutlass_profiler()

    def test_run_cutlass_profiler_raises_if_problem_size_metrics_differ(self):
        profiler = self._make_profiler("cutlass_sm80_tensorop_gemm_f16")
        output = """
           Runtime: 1.25  ms
             Bytes: 1409  bytes
             FLOPs: 2560  flops
        """

        with mock.patch.object(
            profiler_module.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 0, stdout=output, stderr=""),
        ):
            with self.assertRaisesRegex(RuntimeError, "reported 1409 bytes"):
                profiler.run_cutlass_profiler()


if __name__ == "__main__":
    unittest.main()
