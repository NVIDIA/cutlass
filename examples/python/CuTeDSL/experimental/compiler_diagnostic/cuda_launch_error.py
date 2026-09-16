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

"""Run me to see CUDA launch runtime diagnostics:

    python cuda_launch_error.py

The host functions intentionally launch tiny valid kernels with invalid launch
settings. This exercises the TVM-FFI CUDA runtime error path and shows the
Python-rendered launch detail.
"""

import argparse
import sys

import torch

from cutlass import cute
from cutlass.base_dsl.common import DSLCudaRuntimeError
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def copy_one_kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    dst[0] = src[0]


@cute.jit
def host_too_many_threads(src: cute.Tensor, dst: cute.Tensor) -> None:
    copy_one_kernel(src, dst).launch(grid=(1, 1, 1), block=(4096, 1, 1))


@cute.jit
def host_too_much_dynamic_smem(src: cute.Tensor, dst: cute.Tensor) -> None:
    copy_one_kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1), smem=1073741824)


_CASES = {
    "block-threads": (
        host_too_many_threads,
        "block=(4096, 1, 1)",
    ),
    "dynamic-smem": (
        host_too_much_dynamic_smem,
        "smem=1073741824",
    ),
}


def _make_tensors() -> tuple[cute.Tensor, cute.Tensor]:
    src_torch = torch.ones((1,), dtype=torch.float32, device="cuda")
    dst_torch = torch.zeros((1,), dtype=torch.float32, device="cuda")
    return (
        from_dlpack(src_torch, enable_tvm_ffi=True),
        from_dlpack(dst_torch, enable_tvm_ffi=True),
    )


def _run_case(name: str) -> bool:
    host_func, description = _CASES[name]
    src, dst = _make_tensors()

    print(
        f">>> cute.compile({host_func.__name__}, options='--enable-tvm-ffi')",
        flush=True,
    )
    compiled_fn = cute.compile(host_func, src, dst, options="--enable-tvm-ffi")

    print(f">>> compiled_fn(src, dst)   # launches {description}\n", flush=True)
    try:
        compiled_fn(src, dst)
    except DSLCudaRuntimeError as exc:
        print(exc, file=sys.stderr)
        return True

    print(">>> unexpected: launch succeeded")
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--case",
        choices=(*_CASES.keys(), "all"),
        default="all",
        help="which invalid launch example to run",
    )
    args = parser.parse_args()

    case_names = _CASES.keys() if args.case == "all" else (args.case,)
    ok = True
    for case_name in case_names:
        print(f"=== {case_name} ===", flush=True)
        ok = _run_case(case_name) and ok
        print("", flush=True)

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
