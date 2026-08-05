# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Benchmark tutorial 05 NVFP4 TS GEMM against PyTorch ``torch._scaled_mm``.

The PyTorch reference for this kernel is not plain ``torch.mm`` because the TS
kernel consumes packed NVFP4 operands plus scale factors. This script mirrors
``01_gemm_nvfp4.py`` tensor creation, then times both paths with
``cutlass.testing.benchmark``.
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
import cutlass
import cutlass.cute as cute
import torch
from cutlass import testing

_TS_FILE = _SCRIPT_DIR / "01_gemm_nvfp4.py"
USE_CUDA_GRAPHS = True

PROFILE_CONFIGS = [
    (4096, 4096, 4096, 1),
    (8192, 8192, 8192, 1),
]


@dataclass(frozen=True)
class TorchScaledMmBatch:
    """
    Precomputed per-batch PyTorch inputs for one NVFP4 scaled-mm.
    """

    a: torch.Tensor
    b_t: torch.Tensor
    scale_a: torch.Tensor
    scale_b: torch.Tensor
    out: torch.Tensor


@dataclass(frozen=True)
class Nvfp4Inputs:
    """
    Packed NVFP4 tensors, scale-factor tensors, and CuTe pointers.
    """

    a_ptr: cute.Pointer
    b_ptr: cute.Pointer
    sfa_ptr: cute.Pointer
    sfb_ptr: cute.Pointer
    c_ptr: cute.Pointer
    a_ref_f4: torch.Tensor
    b_ref_f4: torch.Tensor
    scale_a: list[torch.Tensor]
    scale_b: list[torch.Tensor]
    sfa_torch: torch.Tensor
    sfb_torch: torch.Tensor
    c_ts: torch.Tensor
    c_torch: torch.Tensor
    torch_batches: tuple[TorchScaledMmBatch, ...]


@dataclass(frozen=True)
class BenchRow:
    """
    One TS-vs-PyTorch timing result.
    """

    config: tuple[int, int, int, int]
    ts_us: float
    torch_us: float

    @property
    def speedup(self) -> float:
        return self.torch_us / self.ts_us

    @property
    def ts_tflops(self) -> float:
        m, n, k, batch = self.config
        return 2.0 * m * n * k * batch / (self.ts_us * 1.0e-6) / 1.0e12

    @property
    def torch_tflops(self) -> float:
        m, n, k, batch = self.config
        return 2.0 * m * n * k * batch / (self.torch_us * 1.0e-6) / 1.0e12


def _parse_quad(value: str) -> tuple[int, int, int, int]:
    try:
        parts = tuple(int(x.strip()) for x in value.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"Invalid comma-separated MNKL tuple: {value}"
        ) from exc
    if len(parts) != 4:
        raise argparse.ArgumentTypeError(f"Expected 4 comma-separated ints: {value}")
    return parts


def _require_gpu() -> None:
    cuda.cuInit(0)
    err, device_count = cuda.cuDeviceGetCount()
    if err != cuda.CUresult.CUDA_SUCCESS or device_count < 1:
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


def _configure_module(module: ModuleType, args: argparse.Namespace) -> None:
    if args.use_two_sf_load_warps and not args.use_two_tma_warps:
        raise ValueError("--use-two-sf-load-warps requires --use-two-tma-warps")
    if args.no_fuse_sf_copy_to_mma and not args.use_two_sf_load_warps:
        raise ValueError("--no-fuse-sf-copy-to-mma requires --use-two-sf-load-warps")
    module.use_two_tma_warps = args.use_two_tma_warps
    module.use_two_sf_load_warps = args.use_two_sf_load_warps
    module.fuse_sf_copy_to_mma = not args.no_fuse_sf_copy_to_mma
    module.use_clc_dynamic_scheduler = args.clc_dynamic_scheduler
    module.refresh_derived_config()


def _create_ref_scale_factor_tensor(
    batch: int,
    rows: int,
    sf_k: int,
) -> torch.Tensor:
    ref_shape = (batch, rows, sf_k)
    ref_f8_random_int = torch.randint(1, 3, ref_shape, dtype=torch.int8)
    ref_f8_torch_tensor_cpu = ref_f8_random_int.to(dtype=torch.float8_e4m3fn)
    return ref_f8_torch_tensor_cpu.permute(1, 2, 0)


def _create_cute_scale_factor_tensor(
    module: ModuleType,
    batch: int,
    rows: int,
    sf_k: int,
    ref_f8_torch_tensor_cpu_permuted: torch.Tensor,
) -> torch.Tensor:
    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        batch,
        module.ceil_div(rows, atom_m[0] * atom_m[1]),
        module.ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )
    mma_permute_order = (3, 4, 1, 5, 2, 0)

    rand_int_tensor = torch.randint(0, 2, mma_shape, dtype=torch.int8)
    cute_f8_torch_tensor_cpu = rand_int_tensor.to(dtype=torch.float8_e4m3fn)
    cute_f8_torch_tensor_cpu = cute_f8_torch_tensor_cpu.permute(*mma_permute_order)

    module.cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        module.make_ptr(
            cutlass.Float8E4M3FN,
            ref_f8_torch_tensor_cpu_permuted.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        module.make_ptr(
            cutlass.Float8E4M3FN,
            cute_f8_torch_tensor_cpu.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        rows,
        sf_k,
        batch,
        mma_shape,
    )
    return cute_f8_torch_tensor_cpu.cuda()


def _validate_config(module: ModuleType, config: tuple[int, int, int, int]) -> None:
    m, n, k, _batch = config
    if m % module.mma_tiler_mnk_per_cta[0] != 0:
        raise ValueError(f"m must be divisible by {module.mma_tiler_mnk_per_cta[0]}")
    if n % module.mma_tiler_mnk[1] != 0:
        raise ValueError(f"n must be divisible by {module.mma_tiler_mnk[1]}")
    if k % module.mma_tiler_mnk[2] != 0:
        raise ValueError(f"k must be divisible by {module.mma_tiler_mnk[2]}")


def _create_inputs(
    module: ModuleType,
    config: tuple[int, int, int, int],
) -> Nvfp4Inputs:
    m, n, k, batch = config
    sf_k = module.ceil_div(k, module.sf_vec_size)

    a_ref = torch.randint(
        0, 2, (batch, m, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)
    b_ref = torch.randint(
        0, 2, (batch, n, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)
    a_ref_f4 = a_ref.view(torch.float4_e2m1fn_x2)
    b_ref_f4 = b_ref.view(torch.float4_e2m1fn_x2)

    c_ts = torch.empty((batch, m, n), dtype=torch.float16, device="cuda").permute(
        1, 2, 0
    )
    c_torch = torch.empty_like(c_ts)

    sfa_ref = _create_ref_scale_factor_tensor(batch, m, sf_k)
    sfb_ref = _create_ref_scale_factor_tensor(batch, n, sf_k)
    sfa_torch = _create_cute_scale_factor_tensor(module, batch, m, sf_k, sfa_ref)
    sfb_torch = _create_cute_scale_factor_tensor(module, batch, n, sf_k, sfb_ref)
    scale_a = [module.to_blocked(sfa_ref[:, :, idx]).cuda() for idx in range(batch)]
    scale_b = [module.to_blocked(sfb_ref[:, :, idx]).cuda() for idx in range(batch)]
    torch_batches = tuple(
        TorchScaledMmBatch(
            a=a_ref_f4[:, :, idx],
            b_t=b_ref_f4[:, :, idx].transpose(0, 1),
            scale_a=scale_a[idx],
            scale_b=scale_b[idx],
            out=c_torch[:, :, idx],
        )
        for idx in range(batch)
    )

    return Nvfp4Inputs(
        a_ptr=module.make_ptr(
            module.ab_dtype,
            a_ref_f4.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=16,
        ),
        b_ptr=module.make_ptr(
            module.ab_dtype,
            b_ref_f4.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=16,
        ),
        sfa_ptr=module.make_ptr(
            module.sf_dtype,
            sfa_torch.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        sfb_ptr=module.make_ptr(
            module.sf_dtype,
            sfb_torch.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        c_ptr=module.make_ptr(
            module.c_dtype,
            c_ts.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        a_ref_f4=a_ref_f4,
        b_ref_f4=b_ref_f4,
        scale_a=scale_a,
        scale_b=scale_b,
        sfa_torch=sfa_torch,
        sfb_torch=sfb_torch,
        c_ts=c_ts,
        c_torch=c_torch,
        torch_batches=torch_batches,
    )


def _workspace_bytes(inputs: Nvfp4Inputs) -> int:
    tensors = [
        inputs.a_ref_f4,
        inputs.b_ref_f4,
        inputs.sfa_torch,
        inputs.sfb_torch,
        inputs.c_ts,
        *inputs.scale_a,
        *inputs.scale_b,
    ]
    return sum(t.numel() * t.element_size() for t in tensors)


def _make_ts_arguments(
    inputs: Nvfp4Inputs,
    config: tuple[int, int, int, int],
    stream: cuda.CUstream,
) -> testing.JitArguments:
    arguments = testing.JitArguments(
        inputs.a_ptr,
        inputs.b_ptr,
        inputs.sfa_ptr,
        inputs.sfb_ptr,
        inputs.c_ptr,
        config,
        stream,
    )
    arguments.add_to_scope([inputs])
    return arguments


def _make_torch_arguments(
    inputs: Nvfp4Inputs,
    torch_stream: torch.cuda.Stream,
) -> testing.JitArguments:
    arguments = testing.JitArguments(
        inputs.torch_batches,
        torch_stream,
    )
    arguments.add_to_scope([inputs])
    return arguments


def _create_benchmark_inputs(
    module: ModuleType,
    config: tuple[int, int, int, int],
    warmup_iterations: int,
    iterations: int,
) -> list[Nvfp4Inputs]:
    first_inputs = _create_inputs(module, config)
    workspace_count = testing.get_workspace_count(
        _workspace_bytes(first_inputs),
        warmup_iterations,
        iterations,
    )
    return [
        first_inputs,
        *(_create_inputs(module, config) for _ in range(workspace_count - 1)),
    ]


def _make_workspace_generator(
    inputs: list[Nvfp4Inputs],
    make_arguments: Callable[[Nvfp4Inputs], testing.JitArguments],
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


def _torch_scaled_mm_on_stream(
    batches: tuple[TorchScaledMmBatch, ...],
    torch_stream: torch.cuda.Stream,
) -> None:
    with torch.cuda.stream(torch_stream):
        for batch in batches:
            torch._scaled_mm(
                batch.a,
                batch.b_t,
                batch.scale_a,
                batch.scale_b,
                bias=None,
                out_dtype=torch.float16,
            )


def _torch_scaled_mm_reference_on_stream(
    batches: tuple[TorchScaledMmBatch, ...],
    torch_stream: torch.cuda.Stream,
) -> None:
    with torch.cuda.stream(torch_stream):
        for batch in batches:
            result = torch._scaled_mm(
                batch.a,
                batch.b_t,
                batch.scale_a,
                batch.scale_b,
                bias=None,
                out_dtype=torch.float16,
            )
            batch.out.copy_(result)


def _compile_ts(
    module: ModuleType,
    inputs: Nvfp4Inputs,
    config: tuple[int, int, int, int],
    stream: cuda.CUstream,
) -> object:
    return cute.compile(
        module.gemm,
        inputs.a_ptr,
        inputs.b_ptr,
        inputs.sfa_ptr,
        inputs.sfb_ptr,
        inputs.c_ptr,
        config,
        stream,
    )


def _benchmark_ts(
    compiled_fn: object,
    benchmark_inputs: list[Nvfp4Inputs],
    config: tuple[int, int, int, int],
    stream: cuda.CUstream,
    warmup_iterations: int,
    iterations: int,
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
        nvtx_tag="nvfp4_ts_gemm",
    )


def _benchmark_torch(
    benchmark_inputs: list[Nvfp4Inputs],
    stream: cuda.CUstream,
    torch_stream: torch.cuda.Stream,
    warmup_iterations: int,
    iterations: int,
) -> float:
    prewarm_inputs = benchmark_inputs[0]
    _torch_scaled_mm_on_stream(prewarm_inputs.torch_batches, torch_stream)
    torch_stream.synchronize()
    return testing.benchmark(
        _torch_scaled_mm_on_stream,
        workspace_generator=_make_workspace_generator(
            benchmark_inputs,
            lambda inputs: _make_torch_arguments(inputs, torch_stream),
        ),
        workspace_count=len(benchmark_inputs),
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=USE_CUDA_GRAPHS,
        nvtx_tag="pytorch_scaled_mm",
    )


def _validate_result(
    compiled_fn: object,
    inputs: Nvfp4Inputs,
    config: tuple[int, int, int, int],
    stream: cuda.CUstream,
    torch_stream: torch.cuda.Stream,
    tolerance: float,
) -> None:
    compiled_fn(
        inputs.a_ptr,
        inputs.b_ptr,
        inputs.sfa_ptr,
        inputs.sfb_ptr,
        inputs.c_ptr,
        config,
        stream,
    )
    _torch_scaled_mm_reference_on_stream(inputs.torch_batches, torch_stream)
    torch.cuda.synchronize()
    torch.testing.assert_close(
        inputs.c_ts,
        inputs.c_torch,
        atol=tolerance,
        rtol=1.0e-2,
    )


def _print_results(rows: list[BenchRow]) -> None:
    if not rows:
        print("No benchmark rows were produced.")
        return
    header = (
        f"{'M,N,K,L':<22} {'TS us':>10} {'Torch us':>10} {'Speedup':>9} "
        f"{'TS TFLOP/s':>12} {'Torch TFLOP/s':>14}"
    )
    print(header)
    print("-" * len(header))
    for row in rows:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}x{row.config[3]}"
        print(
            f"{config:<22} {row.ts_us:10.2f} {row.torch_us:10.2f} "
            f"{row.speedup:8.2f}x {row.ts_tflops:12.2f} {row.torch_tflops:14.2f}"
        )
    geomean = math.prod(row.speedup for row in rows) ** (1.0 / len(rows))
    print(f"\nAll-TS-rows geomean speedup vs PyTorch torch._scaled_mm: {geomean:.2f}x")

    _print_best_results(rows)


def _print_best_results(rows: list[BenchRow]) -> None:
    best_rows: dict[tuple[int, int, int, int], BenchRow] = {}
    for row in rows:
        best = best_rows.get(row.config)
        if best is None or row.ts_us < best.ts_us:
            best_rows[row.config] = row

    best = [best_rows[config] for config in sorted(best_rows)]
    header = (
        f"{'M,N,K,L':<22} {'Best TS config':<16} {'TS us':>10} "
        f"{'Torch us':>10} {'Speedup':>9} {'TS TFLOP/s':>12} "
        f"{'Torch TFLOP/s':>14}"
    )
    print("\nBest TS config per shape vs PyTorch:")
    print(header)
    print("-" * len(header))
    for row in best:
        config = f"{row.config[0]}x{row.config[1]}x{row.config[2]}x{row.config[3]}"
        print(
            f"{config:<22} {'TS':<16} {row.ts_us:10.2f} "
            f"{row.torch_us:10.2f} {row.speedup:8.2f}x "
            f"{row.ts_tflops:12.2f} {row.torch_tflops:14.2f}"
        )

    geomean = math.prod(row.speedup for row in best) ** (1.0 / len(best))
    print(f"\nBest-config geomean speedup vs PyTorch torch._scaled_mm: {geomean:.2f}x")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Benchmark tutorial 05 NVFP4 TS GEMM vs PyTorch torch._scaled_mm"
    )
    parser.add_argument(
        "--configs",
        nargs="+",
        type=_parse_quad,
        default=PROFILE_CONFIGS,
        help="Space-separated M,N,K,L tuples. Example: --configs 1024,1024,1024,1",
    )
    parser.add_argument("--use-two-tma-warps", action="store_true")
    parser.add_argument("--use-two-sf-load-warps", action="store_true")
    parser.add_argument("--no-fuse-sf-copy-to-mma", action="store_true")
    parser.add_argument("--clc-dynamic-scheduler", action="store_true")
    parser.add_argument("--tolerance", type=float, default=1.0e-1)
    parser.add_argument("--warmup-iterations", type=int, default=10)
    parser.add_argument(
        "--iterations", "--runs", dest="iterations", type=int, default=100
    )
    parser.add_argument("--skip-validation", action="store_true")
    args = parser.parse_args()

    _require_gpu()
    torch.manual_seed(1111)

    module = _import_fresh("_bench03_nvfp4_ts", _TS_FILE)
    try:
        _configure_module(module, args)
    except ValueError as exc:
        parser.error(str(exc))

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    rows: list[BenchRow] = []
    for config in args.configs:
        _validate_config(module, config)
        inputs = _create_inputs(module, config)
        print(f"Compiling NVFP4 TS GEMM for {config}...")
        compiled_fn = _compile_ts(module, inputs, config, stream)
        if not args.skip_validation:
            _validate_result(
                compiled_fn,
                inputs,
                config,
                stream,
                torch_stream,
                args.tolerance,
            )
        benchmark_inputs = _create_benchmark_inputs(
            module,
            config,
            args.warmup_iterations,
            args.iterations,
        )
        torch_us = _benchmark_torch(
            benchmark_inputs,
            stream,
            torch_stream,
            args.warmup_iterations,
            args.iterations,
        )
        ts_us = _benchmark_ts(
            compiled_fn,
            benchmark_inputs,
            config,
            stream,
            args.warmup_iterations,
            args.iterations,
        )
        rows.append(BenchRow(config, ts_us, torch_us))

    _print_results(rows)


if __name__ == "__main__":
    main()
