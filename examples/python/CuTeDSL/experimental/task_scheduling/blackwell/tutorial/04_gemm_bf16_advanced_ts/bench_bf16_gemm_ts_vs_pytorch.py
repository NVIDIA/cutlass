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

"""Benchmark clustered BF16 TS GEMM variants against PyTorch ``torch.mm``.

This is the per-folder benchmark for tutorial 04. It is based on the older
``tools/bench_fp16_gemm_3.py`` cluster sweep, but uses
``cutlass.testing.benchmark`` for both the TS kernel and the PyTorch baseline.
"""

# ruff: noqa: E402

import argparse
import importlib.util
import math
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType

_SCRIPT_DIR = Path(__file__).resolve().parent
_TS_ROOT = _SCRIPT_DIR.parent
_REPO_ROOT = _SCRIPT_DIR.parents[9]
for _path in (_SCRIPT_DIR, _TS_ROOT, _REPO_ROOT):
    _path_str = str(_path)
    if _path_str not in sys.path:
        sys.path.insert(0, _path_str)

try:
    import sitecustomize  # noqa: F401
except Exception:
    pass

import cuda.bindings.driver as cuda
import cutlass.utils as utils
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
import torch
from cutlass import Numeric, testing
from cutlass.cute.runtime import from_dlpack, make_fake_stream

_TS_FILE = _SCRIPT_DIR / "01_fp16_bf16_gemm_3_cluster.py"
USE_CUDA_GRAPHS = True

PROFILE_CONFIGS = [
    (2048, 2048, 4096),
    (4096, 4096, 4096),
    (8192, 4096, 4096),
    (4096, 4096, 8192),
    (8192, 8192, 4096),
]

DEFAULT_CLUSTERS = [
    (2, 1, 1),
    (4, 1, 1),
    (2, 2, 1),
    (4, 2, 1),
    (4, 4, 1),
]


@dataclass(frozen=True)
class InputSet:
    """
    CUDA tensors and CuTe views for one GEMM problem size.
    """

    a_view: object
    b_view: object
    c_view: object
    a: torch.Tensor
    b: torch.Tensor
    b_t: torch.Tensor
    c_ts: torch.Tensor
    c_torch: torch.Tensor


@dataclass(frozen=True)
class BenchRow:
    """
    One TS-vs-PyTorch timing result.
    """

    variant: str
    config: tuple[int, int, int]
    ts_us: float
    torch_us: float

    @property
    def speedup(self) -> float:
        return self.torch_us / self.ts_us

    @property
    def ts_tflops(self) -> float:
        m, n, k = self.config
        return 2.0 * m * n * k / (self.ts_us * 1.0e-6) / 1.0e12

    @property
    def torch_tflops(self) -> float:
        m, n, k = self.config
        return 2.0 * m * n * k / (self.torch_us * 1.0e-6) / 1.0e12


def _parse_triplet(value: str) -> tuple[int, int, int]:
    try:
        parts = tuple(int(x.strip()) for x in value.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"Invalid comma-separated triplet: {value}"
        ) from exc
    if len(parts) != 3:
        raise argparse.ArgumentTypeError(f"Expected 3 comma-separated ints: {value}")
    return parts


def _require_gpu() -> None:
    cuda.cuInit(0)
    err, device_count = cuda.cuDeviceGetCount()
    if err != cuda.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A CUDA GPU is required to run this benchmark")


def _import_fresh(name: str, path: Path) -> ModuleType:
    """
    Import ``path`` as ``name`` so compile-time globals can be patched.
    """
    spec = importlib.util.spec_from_file_location(name, str(path))
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load module from {path}")
    module = importlib.util.module_from_spec(spec)
    module_dir = str(path.parent)
    if module_dir not in sys.path:
        sys.path.insert(0, module_dir)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _patch_cluster_config(
    module: ModuleType,
    cluster: tuple[int, int, int],
    fallback: tuple[int, int, int] | None,
    dtype: str,
    use_clc_dynamic_scheduler: bool,
) -> None:
    """
    Apply CLI-selected compile-time settings before ``cute.compile``.
    """
    module._set_io_dtype(dtype)
    module.use_clc_dynamic_scheduler = use_clc_dynamic_scheduler

    module._validate_cluster_shape(cluster, option_name="--cluster")
    if fallback is not None:
        module._validate_fallback_cluster_shape(fallback, cluster)

    cm, cn, ck = cluster
    num_mma_ctas = module.num_mma_ctas
    mma_tiler_mnk = module.mma_tiler_mnk

    module.cluster_shape_mnk = cluster
    module.cluster_m = cm
    module.cluster_n = cn
    module.cluster_size = cm * cn
    module.num_pairs = (cm * cn) // num_mma_ctas
    module.num_pair_rows = cm // num_mma_ctas
    module.num_pair_cols = cn
    module.super_tile_m = (cm // num_mma_ctas) * mma_tiler_mnk[0]
    module.super_tile_n = cn * mma_tiler_mnk[1]
    module._a_mcast_template = sum(1 << (num_mma_ctas * c) for c in range(cn))
    module._b_mcast_template = sum(
        1 << (cn * num_mma_ctas * r) for r in range(cm // num_mma_ctas)
    )
    module.fallback_cluster_shape_mnk = fallback
    if hasattr(module.prepare_run, "cache_clear"):
        module.prepare_run.cache_clear()


def _variant_label(
    cluster: tuple[int, int, int],
    fallback: tuple[int, int, int] | None,
) -> str:
    label = f"TS {cluster[0]}x{cluster[1]}x{cluster[2]}"
    if fallback is not None:
        label += f" +fb{fallback[0]}x{fallback[1]}x{fallback[2]}"
    return label


def _get_max_active_clusters(
    cluster: tuple[int, int, int],
    fallback: tuple[int, int, int] | None,
) -> int:
    hw = utils.HardwareInfo()
    if fallback is not None:
        sm_count = hw.get_device_multiprocessor_count()
        preferred_ctas = cluster[0] * cluster[1]
        return sm_count // preferred_ctas
    return hw.get_max_active_clusters(cluster[0] * cluster[1])


def _is_aligned(config: tuple[int, int, int], module: ModuleType) -> bool:
    m, n, k = config
    return (
        m % module.super_tile_m == 0
        and n % module.super_tile_n == 0
        and k % module.mma_tiler_mnk[2] == 0
    )


def _create_inputs(
    config: tuple[int, int, int],
    io_dtype: type[Numeric],
) -> InputSet:
    m, n, k = config

    def make_tensor(rows: int, cols: int) -> torch.Tensor:
        return (
            torch.empty(rows, cols, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=cutlass_torch.dtype(io_dtype))
        )

    a = make_tensor(m, k)
    b = make_tensor(n, k)
    c_ts = torch.empty(m, n, dtype=cutlass_torch.dtype(io_dtype), device="cuda")
    c_torch = torch.empty_like(c_ts)
    return InputSet(
        a_view=from_dlpack(a).mark_layout_dynamic(),
        b_view=from_dlpack(b).mark_layout_dynamic(),
        c_view=from_dlpack(c_ts).mark_layout_dynamic(),
        a=a,
        b=b,
        b_t=b.t(),
        c_ts=c_ts,
        c_torch=c_torch,
    )


def _workspace_bytes(config: tuple[int, int, int], io_dtype: type[Numeric]) -> int:
    """
    Return bytes touched by one GEMM workspace for cold-L2 rotation.
    """
    m, n, k = config
    element_bytes = torch.empty((), dtype=cutlass_torch.dtype(io_dtype)).element_size()
    return (m * k + n * k + m * n) * element_bytes


def _make_torch_arguments(
    inputs: InputSet,
    torch_stream: torch.cuda.Stream,
) -> testing.JitArguments:
    arguments = testing.JitArguments(inputs.a, inputs.b_t, inputs.c_torch, torch_stream)
    arguments.add_to_scope([inputs])
    return arguments


def _make_ts_arguments(
    inputs: InputSet,
    config: tuple[int, int, int],
    stream: cuda.CUstream,
) -> testing.JitArguments:
    arguments = testing.JitArguments(
        inputs.a_view,
        inputs.b_view,
        inputs.c_view,
        config,
        stream,
        None,
    )
    arguments.add_to_scope([inputs])
    return arguments


def _create_benchmark_inputs(
    config: tuple[int, int, int],
    io_dtype: type[Numeric],
    warmup_iterations: int,
    iterations: int,
) -> list[InputSet]:
    workspace_count = testing.get_workspace_count(
        _workspace_bytes(config, io_dtype),
        warmup_iterations,
        iterations,
    )
    return [_create_inputs(config, io_dtype) for _ in range(workspace_count)]


def _make_workspace_generator(
    inputs: list[InputSet],
    make_arguments: Callable[[InputSet], testing.JitArguments],
) -> Callable[[], testing.JitArguments]:
    index = 0

    def next_arguments() -> testing.JitArguments:
        nonlocal index
        if index >= len(inputs):
            raise RuntimeError("benchmark requested more workspaces than prepared")
        arguments = make_arguments(inputs[index])
        index += 1
        return arguments

    return next_arguments


def _torch_mm_on_stream(
    a: torch.Tensor,
    b_t: torch.Tensor,
    out: torch.Tensor,
    torch_stream: torch.cuda.Stream,
) -> torch.Tensor:
    with torch.cuda.stream(torch_stream):
        return torch.mm(a, b_t, out=out)


def _validate_result(
    compiled_fn: object,
    inputs: InputSet,
    config: tuple[int, int, int],
    stream: cuda.CUstream,
    torch_stream: torch.cuda.Stream,
    tolerance: float,
) -> None:
    _torch_mm_on_stream(inputs.a, inputs.b_t, inputs.c_torch, torch_stream)
    compiled_fn(
        inputs.a_view,
        inputs.b_view,
        inputs.c_view,
        config,
        stream,
        None,
    )
    torch.cuda.synchronize()
    torch.testing.assert_close(
        inputs.c_ts,
        inputs.c_torch,
        atol=tolerance,
        rtol=1.0e-5,
    )


def _benchmark_torch(
    benchmark_inputs: list[InputSet],
    stream: cuda.CUstream,
    torch_stream: torch.cuda.Stream,
    warmup_iterations: int,
    iterations: int,
) -> float:
    prewarm_inputs = benchmark_inputs[0]
    _torch_mm_on_stream(
        prewarm_inputs.a,
        prewarm_inputs.b_t,
        prewarm_inputs.c_torch,
        torch_stream,
    )
    torch_stream.synchronize()
    return testing.benchmark(
        _torch_mm_on_stream,
        workspace_generator=_make_workspace_generator(
            benchmark_inputs,
            lambda inputs: _make_torch_arguments(inputs, torch_stream),
        ),
        workspace_count=len(benchmark_inputs),
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=USE_CUDA_GRAPHS,
        nvtx_tag="pytorch_torch_mm",
    )


def _benchmark_ts(
    compiled_fn: object,
    benchmark_inputs: list[InputSet],
    config: tuple[int, int, int],
    stream: cuda.CUstream,
    warmup_iterations: int,
    iterations: int,
    nvtx_tag: str,
) -> float:
    return testing.benchmark(
        compiled_fn,
        workspace_generator=_make_workspace_generator(
            benchmark_inputs,
            lambda inputs: _make_ts_arguments(inputs, config, stream),
        ),
        workspace_count=len(benchmark_inputs),
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=USE_CUDA_GRAPHS,
        nvtx_tag=nvtx_tag,
    )


def _print_results(rows: list[BenchRow]) -> None:
    if not rows:
        print("No benchmark rows were produced.")
        return

    header = (
        f"{'Variant':<22} {'M,N,K':<20} {'TS us':>10} {'Torch us':>10} "
        f"{'Speedup':>9} {'TS TFLOP/s':>12} {'Torch TFLOP/s':>14}"
    )
    print(header)
    print("-" * len(header))
    for row in rows:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}"
        print(
            f"{row.variant:<22} {config:<20} {row.ts_us:10.2f} "
            f"{row.torch_us:10.2f} {row.speedup:8.2f}x "
            f"{row.ts_tflops:12.2f} {row.torch_tflops:14.2f}"
        )

    geomean = math.prod(row.speedup for row in rows) ** (1.0 / len(rows))
    print(f"\nAll-TS-rows geomean speedup vs PyTorch torch.mm: {geomean:.2f}x")

    _print_best_results(rows)


def _print_best_results(rows: list[BenchRow]) -> None:
    best_rows: dict[tuple[int, int, int], BenchRow] = {}
    for row in rows:
        best = best_rows.get(row.config)
        if best is None or row.ts_us < best.ts_us:
            best_rows[row.config] = row

    best = [best_rows[config] for config in sorted(best_rows)]
    header = (
        f"{'M,N,K':<20} {'Best TS config':<22} {'TS us':>10} "
        f"{'Torch us':>10} {'Speedup':>9} {'TS TFLOP/s':>12} "
        f"{'Torch TFLOP/s':>14}"
    )
    print("\nBest TS config per shape vs PyTorch:")
    print(header)
    print("-" * len(header))
    for row in best:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}"
        print(
            f"{config:<20} {row.variant:<22} {row.ts_us:10.2f} "
            f"{row.torch_us:10.2f} {row.speedup:8.2f}x "
            f"{row.ts_tflops:12.2f} {row.torch_tflops:14.2f}"
        )

    geomean = math.prod(row.speedup for row in best) ** (1.0 / len(best))
    print(f"\nBest-config geomean speedup vs PyTorch torch.mm: {geomean:.2f}x")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Benchmark tutorial 04 clustered BF16 TS GEMM vs PyTorch torch.mm"
    )
    parser.add_argument(
        "--configs",
        nargs="+",
        type=_parse_triplet,
        default=PROFILE_CONFIGS,
        help="Space-separated M,N,K tuples. Example: --configs 4096,4096,4096",
    )
    parser.add_argument(
        "--clusters",
        nargs="+",
        type=_parse_triplet,
        default=DEFAULT_CLUSTERS,
        help="Cluster shapes as M,N,K. Example: --clusters 2,1,1 4,2,1",
    )
    parser.add_argument(
        "--no-fallbacks",
        action="store_true",
        help="Do not add fallback-cluster variants.",
    )
    parser.add_argument(
        "--clc-dynamic-scheduler",
        action="store_true",
        help="Compile with the CLC dynamic persistent scheduler enabled.",
    )
    parser.add_argument(
        "--dtype",
        choices=("fp16", "bf16"),
        default="bf16",
        help="Input/output dtype. Defaults to bf16 for this folder benchmark.",
    )
    parser.add_argument("--tolerance", type=float, default=1.0e-1)
    parser.add_argument("--warmup-iterations", type=int, default=10)
    parser.add_argument(
        "--iterations", "--runs", dest="iterations", type=int, default=100
    )
    parser.add_argument("--skip-validation", action="store_true")
    args = parser.parse_args()

    _require_gpu()
    torch.manual_seed(1111)
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    variants: list[tuple[tuple[int, int, int], tuple[int, int, int] | None]] = []
    fallback = (2, 1, 1)
    for cluster in args.clusters:
        variants.append((cluster, None))
        if not args.no_fallbacks and cluster != fallback:
            variants.append((cluster, fallback))

    rows: list[BenchRow] = []
    torch_times: dict[tuple[int, int, int], float] = {}
    benchmark_inputs: dict[tuple[int, int, int], list[InputSet]] = {}

    for variant_index, (cluster, fallback_cluster) in enumerate(variants):
        label = _variant_label(cluster, fallback_cluster)
        module = _import_fresh(f"_bench02_ts_{variant_index}", _TS_FILE)
        try:
            _patch_cluster_config(
                module,
                cluster,
                fallback_cluster,
                args.dtype,
                args.clc_dynamic_scheduler,
            )
        except ValueError as exc:
            print(f"SKIP {label}: {exc}")
            continue

        valid_configs = [
            config for config in args.configs if _is_aligned(config, module)
        ]
        if not valid_configs:
            print(
                f"SKIP {label}: no configs aligned to "
                f"super_tile {module.super_tile_m}x{module.super_tile_n} "
                f"and k_tile {module.mma_tiler_mnk[2]}"
            )
            continue

        compile_inputs = _create_inputs(valid_configs[0], module.io_dtype)
        max_active_clusters = _get_max_active_clusters(cluster, fallback_cluster)
        print(f"Compiling {label} with {args.dtype} inputs...")
        compiled_fn = cute.compile[cute.FrontendNext, cute.GenerateLineInfo(True)](
            module.host_function,
            compile_inputs.a_view,
            compile_inputs.b_view,
            compile_inputs.c_view,
            valid_configs[0],
            max_active_clusters,
            make_fake_stream(),
            None,
        )

        for config in valid_configs:
            inputs = _create_inputs(config, module.io_dtype)
            if not args.skip_validation:
                _validate_result(
                    compiled_fn,
                    inputs,
                    config,
                    stream,
                    torch_stream,
                    args.tolerance,
                )
            if config not in benchmark_inputs:
                benchmark_inputs[config] = _create_benchmark_inputs(
                    config,
                    module.io_dtype,
                    args.warmup_iterations,
                    args.iterations,
                )
            if config not in torch_times:
                torch_times[config] = _benchmark_torch(
                    benchmark_inputs[config],
                    stream,
                    torch_stream,
                    args.warmup_iterations,
                    args.iterations,
                )
            ts_us = _benchmark_ts(
                compiled_fn,
                benchmark_inputs[config],
                config,
                stream,
                args.warmup_iterations,
                args.iterations,
                nvtx_tag=label.replace(" ", "_").replace("+", "plus"),
            )
            rows.append(BenchRow(label, config, ts_us, torch_times[config]))

    _print_results(rows)


if __name__ == "__main__":
    main()
