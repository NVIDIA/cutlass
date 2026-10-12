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

"""Benchmark split-K TS GEMM variants against PyTorch ``torch.mm``.

This is the per-folder benchmark for tutorial 06. It is based on the older
``tools/bench_fp16_splitk_gemm.py`` sweep, but uses
``cutlass.testing.benchmark`` for both the TS kernel and PyTorch baseline.
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

import cuda.bindings.driver as cuda_driver
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
import torch
from cutlass import Numeric, testing
from cutlass.cute.runtime import from_dlpack

_TS_FILE = _SCRIPT_DIR / "01_gemm_split_k_fp16.py"
USE_CUDA_GRAPHS = True

PROFILE_CONFIGS = [
    (1024, 16, 1024),
    (1024, 16, 4096),
    (1024, 16, 8192),
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
    cuda_driver.cuInit(0)
    err, device_count = cuda_driver.cuDeviceGetCount()
    if err != cuda_driver.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A CUDA GPU is required to run this benchmark")


def _import_fresh(name: str, path: Path) -> ModuleType:
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


def _patch_kernel_config(
    module: ModuleType,
    tile_n: int | None,
    split_k: int,
) -> None:
    """
    Patch split-K and tile-N globals before compiling a variant.
    """
    mma = module.mma_tiler_mnk
    if tile_n is not None:
        mma = (mma[0], tile_n, mma[2])
        module.mma_tiler_mnk = mma
        if tile_n >= 128:
            module.ab_stages = 4

    module.split_k_factor = split_k
    module.cluster_shape = (1, 1, split_k)
    module.n_slice = mma[1] // split_k
    module.t2r_inst_repx = min(32, mma[1])
    module.subtile_cnt = mma[1] // module.t2r_inst_repx
    module.peers_per_subtile = module.t2r_inst_repx // module.n_slice
    module.dsmem_chunk_elems = mma[0] * module.n_slice


def _variant_label(
    tile_n: int,
    split_k: int,
    sweep_tile_n: bool,
    sweep_split_k: bool,
) -> str:
    parts = []
    if sweep_tile_n:
        parts.append(f"N={tile_n}")
    if sweep_split_k:
        parts.append(f"sk={split_k}")
    return "TS " + " ".join(parts) if parts else "TS"


def _is_aligned(
    config: tuple[int, int, int],
    module: ModuleType,
) -> bool:
    m, n, k = config
    k_multiple = module.split_k_factor * module.mma_tiler_mnk[2]
    return (
        m % module.mma_tiler_mnk[0] == 0
        and n % module.mma_tiler_mnk[1] == 0
        and k % k_multiple == 0
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
    stream: cuda_driver.CUstream,
) -> testing.JitArguments:
    arguments = testing.JitArguments(
        inputs.a_view,
        inputs.b_view,
        inputs.c_view,
        config,
        stream,
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


def _make_streamed_host_function(module: ModuleType) -> object:
    """
    Create a split-K host wrapper that launches on the benchmark stream.
    """

    @cute.jit
    def host_function(
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        mnk: tuple[int, int, int],
        stream: cuda_driver.CUstream,
    ) -> None:
        m, n, _k = mnk
        tma_a_desc = module.cuda.create_tensor_map_tiled_from_view(
            a,
            box_dims=(module.mma_tiler_mnk[0], module.tma_k_box),
            stride_order=(1, 0),
            swizzle=module.cuda.TensorMapSwizzle.s128b,
        )
        tma_b_desc = module.cuda.create_tensor_map_tiled_from_view(
            b,
            box_dims=(module.mma_tiler_mnk[1], module.tma_k_box),
            stride_order=(1, 0),
            swizzle=module.cuda.TensorMapSwizzle.s128b,
        )

        m_tiles = m // module.mma_tiler_mnk[0]
        n_tiles = n // module.mma_tiler_mnk[1]
        grid_shape = (m_tiles, n_tiles, module.split_k_factor)
        block_size = module.cute.arch.WARP_SIZE * 8
        module.kernel(
            tma_a_desc,
            tma_b_desc,
            c,
            mnk,
        ).launch(
            grid=grid_shape,
            block=[block_size, 1, 1],
            cluster=module.cluster_shape,
            stream=stream,
        )

    return host_function


def _validate_result(
    compiled_fn: object,
    inputs: InputSet,
    config: tuple[int, int, int],
    stream: cuda_driver.CUstream,
    torch_stream: torch.cuda.Stream,
    tolerance: float,
) -> None:
    _torch_mm_on_stream(inputs.a, inputs.b_t, inputs.c_torch, torch_stream)
    compiled_fn(inputs.a_view, inputs.b_view, inputs.c_view, config, stream)
    torch.cuda.synchronize()
    torch.testing.assert_close(
        inputs.c_ts,
        inputs.c_torch,
        atol=tolerance,
        rtol=1.0e-5,
    )


def _benchmark_torch(
    benchmark_inputs: list[InputSet],
    stream: cuda_driver.CUstream,
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
    stream: cuda_driver.CUstream,
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
        f"{'Variant':<18} {'M,N,K':<20} {'TS us':>10} {'Torch us':>10} "
        f"{'Speedup':>9} {'TS TFLOP/s':>12} {'Torch TFLOP/s':>14}"
    )
    print(header)
    print("-" * len(header))
    for row in rows:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}"
        print(
            f"{row.variant:<18} {config:<20} {row.ts_us:10.2f} "
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
        f"{'M,N,K':<20} {'Best TS config':<18} {'TS us':>10} "
        f"{'Torch us':>10} {'Speedup':>9} {'TS TFLOP/s':>12} "
        f"{'Torch TFLOP/s':>14}"
    )
    print("\nBest TS config per shape vs PyTorch:")
    print(header)
    print("-" * len(header))
    for row in best:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}"
        print(
            f"{config:<20} {row.variant:<18} {row.ts_us:10.2f} "
            f"{row.torch_us:10.2f} {row.speedup:8.2f}x "
            f"{row.ts_tflops:12.2f} {row.torch_tflops:14.2f}"
        )

    geomean = math.prod(row.speedup for row in best) ** (1.0 / len(best))
    print(f"\nBest-config geomean speedup vs PyTorch torch.mm: {geomean:.2f}x")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Benchmark tutorial 06 split-K TS GEMM vs PyTorch torch.mm"
    )
    parser.add_argument(
        "--configs",
        nargs="+",
        type=_parse_triplet,
        default=PROFILE_CONFIGS,
        help="Space-separated M,N,K tuples. Example: --configs 1024,512,2048",
    )
    parser.add_argument(
        "--tile-n",
        nargs="+",
        type=int,
        default=None,
        help="MMA tile-N values to profile. Default: source value.",
    )
    parser.add_argument(
        "--split-k",
        nargs="+",
        type=int,
        default=(2, 4, 8),
        help="Split-K factors to profile.",
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
    stream = cuda_driver.CUstream(torch_stream.cuda_stream)

    ref_module = _import_fresh("_bench04_ref", _TS_FILE)
    tile_n_values = args.tile_n or [ref_module.mma_tiler_mnk[1]]
    io_dtype = ref_module.io_dtype
    del ref_module

    variants = [
        (tile_n, split_k) for tile_n in tile_n_values for split_k in args.split_k
    ]
    sweep_tile_n = len(tile_n_values) > 1
    sweep_split_k = len(args.split_k) > 1

    rows: list[BenchRow] = []
    torch_times: dict[tuple[int, int, int], float] = {}
    benchmark_inputs: dict[tuple[int, int, int], list[InputSet]] = {}

    for variant_index, (tile_n, split_k) in enumerate(variants):
        module = _import_fresh(f"_bench04_ts_{variant_index}", _TS_FILE)
        _patch_kernel_config(module, tile_n, split_k)
        label = _variant_label(tile_n, split_k, sweep_tile_n, sweep_split_k)

        valid_configs = [
            config for config in args.configs if _is_aligned(config, module)
        ]
        if not valid_configs:
            k_multiple = module.split_k_factor * module.mma_tiler_mnk[2]
            print(
                f"SKIP {label}: no configs aligned to tile "
                f"{module.mma_tiler_mnk[0]}x{module.mma_tiler_mnk[1]} "
                f"and k multiple {k_multiple}"
            )
            continue

        compile_inputs = _create_inputs(valid_configs[0], io_dtype)
        host_function = _make_streamed_host_function(module)
        print(f"Compiling {label}...")
        compiled_fn = cute.compile[cute.FrontendNext, cute.GenerateLineInfo(True)](
            host_function,
            compile_inputs.a_view,
            compile_inputs.b_view,
            compile_inputs.c_view,
            valid_configs[0],
            stream,
        )

        for config in valid_configs:
            inputs = _create_inputs(config, io_dtype)
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
                    io_dtype,
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
                nvtx_tag=label.replace(" ", "_"),
            )
            rows.append(BenchRow(label, config, ts_us, torch_times[config]))

    _print_results(rows)


if __name__ == "__main__":
    main()
