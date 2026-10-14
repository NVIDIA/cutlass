# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

import shlex
import sys

from cutlass_cicd.common.env import detect_gpu_count, ensure_imex_channel
from cutlass_cicd.common.execution import CommandRunner, TestContext
from cutlass_cicd.cutedsl.commands import make_command
from cutlass_cicd.cutedsl.paths import get_example_root, join_rel_path


DISTRIBUTED_EXAMPLE_DIRS = ("cute/blackwell/kernel/distributed/",)


DISTRIBUTED_TESTS = (
    (
        "distributed_all_reduce_one_shot_lamport",
        "cute/blackwell/kernel/distributed/all_reduce_one_shot_lamport.py",
        "--M 8192 --N 8192",
    ),
    (
        "distributed_all_reduce_simple",
        "cute/blackwell/kernel/distributed/all_reduce_simple.py",
        "--M 1024 --N 512",
    ),
    (
        "distributed_all_reduce_tma",
        "cute/blackwell/kernel/distributed/all_reduce_tma.py",
        "--shape 1024,1024",
    ),
    (
        "distributed_all_reduce_two_shot_multimem",
        "cute/blackwell/kernel/distributed/all_reduce_two_shot_multimem.py",
        "--M 1024 --N 512",
    ),
    (
        "distributed_distributed_gemm_all_reduce_blackwell",
        "cute/blackwell/kernel/distributed/distributed_gemm_all_reduce_blackwell.py",
        "--ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32 --mma_tiler_mn 256,256 "
        "--cluster_shape_mn 2,1 --mnkl 1024,1000,1024,1 --warmup_iterations 3 "
        "--iterations 10 --use_tma_store --use_2cta_instrs --all_reduce LDMCxSTMC",
    ),
    (
        "distributed_distributed_gemm_reduce_scatter_blackwell",
        "cute/blackwell/kernel/distributed/distributed_gemm_reduce_scatter_blackwell.py",
        "--ab_dtype Float8E4M3FN --c_dtype Float16 --acc_dtype Float32 "
        "--mma_tiler_mn 256,256 --cluster_shape_mn 2,1 --mnkl 16384,4080,4096,1 "
        "--warmup_iterations 3 --iterations 10 --use_tma_store --use_2cta_instrs "
        "--reduce_scatter two_shot",
    ),
    (
        "distributed_dense_gemm_persistent_all_reduce",
        "cute/blackwell/kernel/distributed/distributed_dense_gemm_persistent_all_reduce.py",
        "--ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32 --mma_tiler_mn 256,256 "
        "--cluster_shape_mn 2,1 --mnkl 8192,8192,8192,1 --warmup_iterations 3 "
        "--iterations 10 --use_tma_store --use_2cta_instrs --all_reduce LDMCxSTMC",
    ),
    (
        "distributed_dense_gemm_persistent_reduce_scatter",
        "cute/blackwell/kernel/distributed/distributed_dense_gemm_persistent_reduce_scatter.py",
        "--ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32 --mma_tiler_mn 256,256 "
        "--cluster_shape_mn 2,1 --mnkl 8192,8192,8192,1 --warmup_iterations 3 "
        "--iterations 10 --use_tma_store --use_2cta_instrs --reduce_scatter LDMC",
    ),
    (
        "distributed_distributed_all_gather_gemm_blackwell",
        "cute/blackwell/kernel/distributed/distributed_all_gather_gemm_blackwell.py",
        "--ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32 --mma_tiler_mn 256,128 "
        "--cluster_shape_mn 2,1 --mnkl 8192,8192,8192,1 --use_tma_store "
        "--use_2cta_instrs",
    ),
)

MULTICAST_TESTS = frozenset(
    {
        "distributed_all_reduce_tma",
        "distributed_all_reduce_two_shot_multimem",
        "distributed_distributed_gemm_all_reduce_blackwell",
        "distributed_distributed_gemm_reduce_scatter_blackwell",
        "distributed_dense_gemm_persistent_all_reduce",
        "distributed_dense_gemm_persistent_reduce_scatter",
    }
)


def run_distributed_flow(context: TestContext, runner: CommandRunner) -> None:
    if sys.version_info >= (3, 14):
        runner.skip(
            f"distributed_sm{context.sm}",
            "torch.distributed does not support Python 3.14 yet",
        )
        return
    if context.sm != "100":
        runner.skip(f"distributed_sm{context.sm}", f"No distributed tests for sm {context.sm}")
        return

    if context.arch == "aarch64" and not context.dry_run:
        ensure_imex_channel()

    gpu_count = 8 if context.dry_run else detect_gpu_count()
    example_root = get_example_root(context.source_dir)
    for name, rel_path, flags in DISTRIBUTED_TESTS:
        test_path = join_rel_path(example_root, rel_path)
        if not test_path.exists():
            runner.skip(name, f"{test_path} does not exist")
            continue
        if gpu_count < 2 and name in MULTICAST_TESTS:
            runner.skip(
                name,
                "requires at least 2 GPUs with NVSHMEM multicast support",
            )
            continue

        args = [
            "torchrun",
            "--nproc-per-node",
            str(gpu_count),
            str(test_path),
        ]
        args.extend(shlex.split(flags))
        runner.run(make_command(context, name, args, timeout=600))
