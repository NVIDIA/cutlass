# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""C++ TVM FFI registry integration and GPU-launch benchmark.

Run with ``pytest -s`` to print the native and kwargs-wrapper call costs. The
benchmark has no pass/fail performance threshold because host timings are
machine-dependent; it verifies that the C++ registry path is callable and
reports the result for regressions to be compared on the same machine.
"""

import subprocess
import sys

import pytest

torch = pytest.importorskip("torch")
tvm_ffi = pytest.importorskip("tvm_ffi")

import cutlass.cute as cute
from cutlass import Int32
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl.tvm_ffi_provider import TVMFFIJitCompiledFunction


pytestmark = pytest.mark.skipif(
    not torch.cuda.is_available(), reason="requires a CUDA-capable PyTorch runtime"
)


N = 128


@cute.kernel
def _cpp_registry_increment(src: cute.Tensor, dst: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    if tidx < Int32(N):
        dst[tidx] = src[tidx] + 1.0


@cute.jit
def _cpp_registry_positional_only(src: cute.Tensor, dst: cute.Tensor, /):
    _cpp_registry_increment(src, dst).launch(grid=[1, 1, 1], block=[N, 1, 1])


@cute.jit
def _cpp_registry_positional_or_keyword(src: cute.Tensor, dst: cute.Tensor):
    _cpp_registry_increment(src, dst).launch(grid=[1, 1, 1], block=[N, 1, 1])


def _tvm_ffi_config(flag):
    return subprocess.check_output([sys.executable, "-m", "tvm_ffi.config", flag]).decode().strip()


@pytest.fixture(scope="module")
def _cpp_registry_extension(tmp_path_factory):
    from torch.utils.cpp_extension import CUDA_HOME, load_inline

    if CUDA_HOME is None:
        pytest.skip("PyTorch could not locate the CUDA Toolkit")

    build_directory = tmp_path_factory.mktemp("tvm_ffi_cpp_registry")
    source = r"""
        #include <ATen/DLConvertor.h>
        #include <cuda_runtime_api.h>
        #include <chrono>
        #include <cstdint>
        #include <string>
        #include <torch/extension.h>
        #include <tvm/ffi/function.h>

        double benchmark_tvm_ffi_global(
            const std::string& name, at::Tensor& src, at::Tensor& dst, int iterations) {
          tvm::ffi::Function fn = tvm::ffi::Function::GetGlobalRequired(name);
          DLTensor dl_src = {};
          DLTensor dl_dst = {};
          at::toDLPackNonOwning(src, &dl_src);
          at::toDLPackNonOwning(dst, &dl_dst);
          TVMFFIAny raw_args[2] = {};
          for (int i = 0; i < 2; ++i) {
            raw_args[i].type_index = TVMFFITypeIndex::kTVMFFIDLTensorPtr;
            raw_args[i].zero_padding = 0;
          }
          raw_args[0].v_ptr = &dl_src;
          raw_args[1].v_ptr = &dl_dst;
          tvm::ffi::AnyView args[] = {
              tvm::ffi::AnyView::CopyFromTVMFFIAny(raw_args[0]),
              tvm::ffi::AnyView::CopyFromTVMFFIAny(raw_args[1]),
          };
          tvm::ffi::Any result;
          fn.CallPacked(args, 2, &result);
          TORCH_CHECK(cudaDeviceSynchronize() == cudaSuccess, "warm-up launch failed");
          auto start = std::chrono::steady_clock::now();
          for (int i = 0; i < iterations; ++i) {
            fn.CallPacked(args, 2, &result);
          }
          auto stop = std::chrono::steady_clock::now();
          TORCH_CHECK(cudaDeviceSynchronize() == cudaSuccess, "kernel launch failed");
          return std::chrono::duration<double, std::nano>(stop - start).count() /
                 static_cast<double>(iterations);
        }

        PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
          m.def("benchmark_tvm_ffi_global", &benchmark_tvm_ffi_global);
        }
    """
    return load_inline(
        name="cutlass_tvm_ffi_cpp_registry_benchmark",
        cpp_sources=source,
        extra_include_paths=[
            _tvm_ffi_config("--includedir"),
            _tvm_ffi_config("--dlpack-includedir"),
            f"{CUDA_HOME}/include",
        ],
        extra_cflags=["-std=c++20"],
        extra_ldflags=[
            f"-L{_tvm_ffi_config('--libdir')}",
            "-ltvm_ffi",
            f"-Wl,-rpath,{_tvm_ffi_config('--libdir')}",
            f"-L{CUDA_HOME}/lib64",
            "-lcudart",
        ],
        build_directory=str(build_directory),
        verbose=False,
    )


def test_tvm_ffi_cpp_registry_fast_path(_cpp_registry_extension):
    src = torch.arange(N, dtype=torch.float32, device="cuda")
    dst = torch.zeros_like(src)
    src_dsl = from_dlpack(
        src, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic()
    dst_dsl = from_dlpack(
        dst, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic()
    positional_only = cute.compile(
        _cpp_registry_positional_only,
        src_dsl,
        dst_dsl,
        options="--enable-tvm-ffi",
    )
    positional_or_keyword = cute.compile(
        _cpp_registry_positional_or_keyword,
        src_dsl,
        dst_dsl,
        options="--enable-tvm-ffi",
    )

    assert isinstance(positional_only, TVMFFIJitCompiledFunction)
    tvm_ffi.register_global_func(
        "cutlass.test.cpp_registry.positional_only", positional_only, override=True
    )
    tvm_ffi.register_global_func(
        "cutlass.test.cpp_registry.positional_or_keyword",
        positional_or_keyword,
        override=True,
    )

    registered = tvm_ffi.get_global_func("cutlass.test.cpp_registry.positional_only")
    assert registered.__chandle__() == positional_only.__chandle__()

    iterations = 1_000
    native_ns = _cpp_registry_extension.benchmark_tvm_ffi_global(
        "cutlass.test.cpp_registry.positional_only", src, dst, iterations
    )
    assert torch.equal(dst, src + 1)
    dst.zero_()
    wrapper_ns = _cpp_registry_extension.benchmark_tvm_ffi_global(
        "cutlass.test.cpp_registry.positional_or_keyword", src, dst, iterations
    )
    assert torch.equal(dst, src + 1)

    assert native_ns > 0
    assert wrapper_ns > 0
    print(
        f"C++ TVM FFI GPU-launch enqueue cost over {iterations:,} iterations: "
        f"positional-only={native_ns:.1f} ns, "
        f"kwargs-capable={wrapper_ns:.1f} ns"
    )
