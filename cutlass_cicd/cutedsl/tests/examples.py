# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import os
from pathlib import Path
from typing import List, Set

from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.common.log import G_LOGGER
from cutlass_cicd.cutedsl.commands import make_command
from cutlass_cicd.cutedsl.paths import (
    get_example_root,
    has_main_entrypoint,
    join_rel_path,
    normalize_rel_path,
)
from cutlass_cicd.cutedsl.tests.cute_export import CUTE_EXPORT_TESTS
from cutlass_cicd.cutedsl.tests.distributed import (
    DISTRIBUTED_EXAMPLE_DIRS,
    DISTRIBUTED_TESTS,
)
from cutlass_cicd.cutedsl.tests.tvm_ffi import TVM_FFI_TESTS


EXAMPLE_DIRS_BY_SM = {
    "80": ("cute/ampere", "dsl_tutorials", "cute_ext/ampere"),
    "90": ("cute/hopper", "block_api/hopper"),
    "100": ("cute/blackwell", "dsl_tutorials", "cute_ext/blackwell", "block_api/blackwell"),
    "103": ("cute/blackwell", "dsl_tutorials", "cute_ext/blackwell", "block_api/blackwell"),
    "120": ("cute/blackwell_geforce",),
}

EXTRA_EXAMPLES_BY_SM = {
    "120": (
        "cute_ext/blackwell/dense_gemm/"
        "sm120_dense_block_scaled_gemm_persistent_pingpong.py",
    ),
}

EXAMPLE_SUPPORTED_SMS = {
    "dsl_tutorials/fp16_gemm_4_iket.py": frozenset({"100", "103"}),
}

HELPER_FILE_BASENAMES = {
    "utils.py",
    "sparse_utils.py",
    "fmha_helpers.py",
    "mixed_input_host_utils.py",
    "detect_gpu_arch.py",
}

WAIVED_EXAMPLE_SUFFIXES = (
    "mamba2_ssd/mamba2_ssd_reference.py",
    "mamba2_ssd/mamba2_ssd_tile_scheduler.py",
    "dsl_tutorials/tvm_ffi/error_reporting.py",
)

# TODO: Remove these paths to re-enable them in the L0 example flow after their
# temporary disablement is lifted.
TEMPORARILY_DISABLED_EXAMPLE_PATHS = {
    "cute/blackwell/kernel/attention/fmha/fmha.py",
    "dsl_tutorials/tvm_ffi/jit_and_use_in_jax.py",
}


def get_skip_relative_paths() -> Set[str]:
    skip_rel_paths = {
        normalize_rel_path(path) for path in TEMPORARILY_DISABLED_EXAMPLE_PATHS
    }
    for _, rel_path, _ in TVM_FFI_TESTS + CUTE_EXPORT_TESTS:
        skip_rel_paths.add(normalize_rel_path(rel_path))
    for _, rel_path, _ in DISTRIBUTED_TESTS:
        skip_rel_paths.add(normalize_rel_path(rel_path))
    return skip_rel_paths


def should_skip_collected_example(
    rel_path: str,
    file_name: str,
    sm: str,
    skip_rel_paths: Set[str],
) -> bool:
    if rel_path in skip_rel_paths:
        return True
    if rel_path.startswith(DISTRIBUTED_EXAMPLE_DIRS):
        return True
    supported_sms = EXAMPLE_SUPPORTED_SMS.get(rel_path)
    if supported_sms is not None and sm not in supported_sms:
        return True
    if sm == "100" and "103" in file_name:
        return True
    if sm in {"100", "103"} and "120" in file_name:
        return True
    if rel_path.startswith("dsl_tutorials/jax/") and sm not in {"100", "103"}:
        return True
    if file_name.startswith("benchmark"):
        return True
    if file_name.startswith("test_"):
        return True
    if file_name in HELPER_FILE_BASENAMES:
        return True
    if file_name.endswith("_utils.py"):
        return True
    return False


def collect_example_files(context: TestContext) -> List[Path]:
    rel_dirs = EXAMPLE_DIRS_BY_SM.get(context.sm, ())
    skip_rel_paths = get_skip_relative_paths()
    examples = set()
    example_root = get_example_root(context.source_dir)

    for rel_dir in rel_dirs:
        example_directory = join_rel_path(example_root, rel_dir)
        if not example_directory.is_dir():
            G_LOGGER.warning("Example dir %s does not exist", example_directory)
            continue

        for root, dirs, files in os.walk(example_directory):
            dirs[:] = [directory for directory in sorted(dirs) if directory != "__pycache__"]
            for file_name in sorted(files):
                if not file_name.endswith(".py") or file_name.startswith("_"):
                    continue

                full_path = Path(root) / file_name
                rel_path = normalize_rel_path(full_path.relative_to(example_root))
                if should_skip_collected_example(rel_path, file_name, context.sm, skip_rel_paths):
                    continue
                if not has_main_entrypoint(full_path):
                    continue
                examples.add(full_path)

    for rel_path in EXTRA_EXAMPLES_BY_SM.get(context.sm, ()):
        full_path = join_rel_path(example_root, rel_path)
        if not full_path.is_file():
            G_LOGGER.warning("Extra example %s does not exist", full_path)
            continue
        examples.add(full_path)

    return sorted(examples)


def parse_example_name(file_path: Path, example_root: Path) -> str:
    rel_path = normalize_rel_path(file_path.relative_to(example_root))
    return rel_path.replace(".py", "").replace("/", "_")


def is_waived_example(rel_path: str) -> bool:
    return any(rel_path.endswith(suffix) for suffix in WAIVED_EXAMPLE_SUFFIXES)


def should_waive_for_cuda12(rel_path: str, context: TestContext) -> bool:
    return context.cuda_major == 12 and rel_path.startswith("cute_ext/")


def run_examples_flow(context: TestContext, runner: CommandRunner) -> None:
    examples = collect_example_files(context)
    if not examples:
        runner.skip(f"examples_sm{context.sm}", f"No examples collected for sm {context.sm}")
        return

    example_root = get_example_root(context.source_dir)
    for file_path in examples:
        rel_path = normalize_rel_path(file_path.relative_to(example_root))
        example_name = parse_example_name(file_path, example_root)

        if is_waived_example(rel_path) or should_waive_for_cuda12(rel_path, context):
            runner.waive(example_name)
            continue

        args = [context.python, str(file_path)]
        runner.run(make_command(context, example_name, args, timeout=600))
