#################################################################################################
#
# Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
Profiler based on the cuda events
"""

import re
import subprocess

from cutlass_cppgen.utils.lazy_import import lazy_import
cuda = lazy_import("cuda.cuda")
cudart =  lazy_import("cuda.cudart")
import numpy as np

from cutlass_cppgen import CUTLASS_PATH
from cutlass_cppgen.backend.library import DataTypeSize
from cutlass_cppgen.op.op import OperationBase
from cutlass_cppgen.shape import GemmCoord
from cutlass_cppgen.utils.datatypes import is_numpy_tensor


_FLOAT_PATTERN = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"


def _parse_profiler_float(result, metric_name):
    match = re.search(
        rf"{re.escape(metric_name)}:\s+(?P<value>{_FLOAT_PATTERN})", result
    )
    if match is None:
        raise RuntimeError(
            f"Could not parse profiler {metric_name.lower()} from output:\n{result}"
        )
    return float(match.group("value"))


def _parse_profiler_int(result, metric_name):
    match = re.search(rf"{re.escape(metric_name)}:\s+(?P<value>\d+)", result)
    if match is None:
        raise RuntimeError(
            f"Could not parse profiler {metric_name.lower()} from output:\n{result}"
        )
    return int(match.group("value"))


class GpuTimer:
    def __init__(self) -> None:
        self.events = [
            cuda.cuEventCreate(cuda.CUevent_flags.CU_EVENT_DEFAULT)[1],
            cuda.cuEventCreate(cuda.CUevent_flags.CU_EVENT_DEFAULT)[1],
        ]

    def start(self, stream=None):
        if not stream:
            stream = cuda.CUstream(0)

        (err,) = cuda.cuEventRecord(self.events[0], stream)
        if err != cuda.CUresult.CUDA_SUCCESS:
            raise RuntimeError(f"CUDA Error {str(err)}")

    def stop(self, stream=None):
        if not stream:
            stream = cuda.CUstream(0)

        (err,) = cuda.cuEventRecord(self.events[1], stream)
        if err != cuda.CUresult.CUDA_SUCCESS:
            raise RuntimeError(f"CUDA Error {str(err)}")
        pass

    def stop_and_wait(self, stream=None):
        if not stream:
            stream = cuda.CUstream(0)

        self.stop(stream)
        if stream:
            (err,) = cuda.cuStreamSynchronize(stream)
            if err != cuda.CUresult.CUDA_SUCCESS:
                raise RuntimeError(f"CUDA Error {str(err)}")
        else:
            (err,) = cudart.cudaDeviceSynchronize()
            if err != cuda.CUresult.CUDA_SUCCESS:
                raise RuntimeError(f"CUDA Error {str(err)}")

    def duration(self, iterations=1):
        err, duration = cuda.cuEventElapsedTime(self.events[0], self.events[1])
        if err != cuda.CUresult.CUDA_SUCCESS:
            raise RuntimeError(f"CUDA Error {str(err)}")
        return duration / float(iterations)


class CUDAEventProfiler:
    def __init__(self, op: OperationBase, warmup_iterations: int=500, iterations: int=500, *args, **kwargs) -> None:
        self.arguments = op.run(*args, **kwargs)
        self.operation = op.operation
        self.warmup_iterations = warmup_iterations
        self.iterations = iterations
        self.timer = GpuTimer()

    #
    # Cutlass Python Interface Profiler
    #

    def __call__(self):
        for _ in range(self.warmup_iterations):
            self.operation.run(self.arguments)

        self.timer.start()
        for _ in range(self.iterations):
            self.operation.run(self.arguments)

        self.timer.stop_and_wait()
        runtime = self.timer.duration(self.iterations)
        return runtime

    #
    # CUTLASS Profiler
    #

    def run_cutlass_profiler(self):
        alpha = 1.0
        beta = 1.0

        profiler_path = CUTLASS_PATH + "/build/tools/profiler/cutlass_profiler"
        kernel_name = self.operation.procedural_name()
        verification_providers = "device"
        provider = "cutlass"
        problem_size = self.arguments.problem_size

        if "cutlass3x" in kernel_name:
            layout_name = self.operation.layout_name_3x()
            if layout_name[-1] == "t":
                # Some 3.x profiler manifests only include column-major output kernels.
                new_layout_name = layout_name[:-1] + "n"
                problem_size = GemmCoord(problem_size.n, problem_size.m, problem_size.k)
                kernel_name = kernel_name.replace(
                    f"_{layout_name}_", f"_{new_layout_name}_", 1
                )

        batch_count = self.arguments.batch_count

        cmd = [
            profiler_path,
            f"--kernels={kernel_name}",
            f"--verification-providers={verification_providers}",
            f"--providers={provider}",
            f"--m={problem_size.m}",
            f"--n={problem_size.n}",
            f"--k={problem_size.k}",
            f"--batch_count={batch_count}",
            f"--alpha={alpha}",
            f"--beta={beta}",
            f"--warmup-iterations={self.warmup_iterations}",
            f"--profiling-iterations={self.iterations}",
        ]

        try:
            completed = subprocess.run(
                cmd,
                check=True,
                capture_output=True,
                text=True,
            )
        except subprocess.CalledProcessError as exc:
            output = "\n".join(part for part in (exc.stdout, exc.stderr) if part)
            raise RuntimeError(
                f"CUTLASS profiler failed with exit code {exc.returncode}:\n{output}"
            ) from exc

        result = "\n".join(
            part for part in (completed.stdout, completed.stderr) if part
        )

        runtime = _parse_profiler_float(result, "Runtime")
        bytes_ = _parse_profiler_int(result, "Bytes")
        flops = _parse_profiler_int(result, "FLOPs")

        # check if the problem size matches
        expected_bytes = self.bytes(problem_size, batch_count, beta)
        if bytes_ != expected_bytes:
            raise RuntimeError(
                f"CUTLASS profiler reported {bytes_} bytes, expected {expected_bytes}."
            )

        expected_flops = self.flops(problem_size, batch_count, beta)
        if flops != expected_flops:
            raise RuntimeError(
                f"CUTLASS profiler reported {flops} FLOPs, expected {expected_flops}."
            )

        return runtime

    def bytes(self, problem_size, batch_count=1, beta=0.0):
        m = problem_size.m
        n = problem_size.n
        k = problem_size.k

        bytes = (
            (DataTypeSize[self.operation.A.element] * m // 8) * k
            + (DataTypeSize[self.operation.B.element] * n // 8) * k
            + (DataTypeSize[self.operation.C.element] * m // 8) * n
        )

        if beta != 0:
            bytes += (DataTypeSize[self.operation.C.element] * m // 8) * n

        bytes *= batch_count

        return bytes

    def flops(self, problem_size, batch_count=1, beta=0.0):
        m = problem_size.m
        n = problem_size.n
        k = problem_size.k

        flops_ = (m * n * k) * 2 * batch_count

        if beta != 0:
            flops_ += m * n * batch_count * 2

        return flops_
