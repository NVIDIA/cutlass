# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.commands import iter_file_commands, make_command


TVM_FFI_TESTS = (
    ("tvm_ffi_aot_export", "dsl_tutorials/tvm_ffi/aot_export.py", "python"),
    ("tvm_ffi_aot_use_in_torch", "dsl_tutorials/tvm_ffi/aot_use_in_torch.py", "python"),
    ("tvm_ffi_aot_use_in_jax", "dsl_tutorials/tvm_ffi/aot_use_in_jax.py", "python"),
    ("tvm_ffi_aot_use_in_cpp_bundle", "dsl_tutorials/tvm_ffi/aot_use_in_cpp_bundle.sh", "bash"),
)


def run_tvm_ffi_flow(context: TestContext, runner: CommandRunner) -> None:
    if context.sm not in {"80", "100"}:
        runner.skip(f"tvm_ffi_sm{context.sm}", f"No tvm_ffi flow for sm {context.sm}")
        return

    for name, args in iter_file_commands(context, TVM_FFI_TESTS, runner):
        runner.run(make_command(context, name, args))
