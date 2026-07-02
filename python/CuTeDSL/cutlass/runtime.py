# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import ctypes
import sys
from pathlib import Path
from typing import Any

from cutlass._mlir import ir
import cutlass._mlir.dialects.cuda as _cuda_dialect
from cutlass.base_dsl.env_manager import get_prefix_dsl_libs
from cutlass.base_dsl.export import ExternalBinaryModule


class _FakeStream:
    """A fake stream that can be used as a placeholder for a stream in compilation.

    When use_tvm_ffi_env_stream is True and the function is compiled with TVM-FFI,
    the argument will be skipped from the function signature and we pass in
    this value through the environment stream obtained from caller context
    (e.g. torch.cuda.current_stream()).
    """

    use_tvm_ffi_env_stream: bool

    def __init__(self, *, use_tvm_ffi_env_stream: bool = False) -> None:
        self.use_tvm_ffi_env_stream = use_tvm_ffi_env_stream

    def __str__(self) -> str:
        return "FakeStream"

    def __repr__(self) -> str:
        return self.__str__()

    def __new_from_mlir_values__(self, values: list[object]) -> object:
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self) -> list[int]:
        return [0]

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [_cuda_dialect.StreamType.get()]


def make_fake_stream(*, use_tvm_ffi_env_stream: bool = False) -> _FakeStream:
    """Create a fake stream that can be used as a placeholder for a stream in compilation.

    When use_tvm_ffi_env_stream is True and the function is compiled with TVM-FFI,
    the argument will be skipped from the function signature and we pass in
    this value through the environment stream obtained from caller context
    (e.g. torch.cuda.current_stream()). This can speedup the calling process
    since we no longer need to do stream query in python.

    :param use_tvm_ffi_env_stream: Whether to skip this parameter use environment stream instead.
    :type use_tvm_ffi_env_stream: bool
    """
    return _FakeStream(use_tvm_ffi_env_stream=use_tvm_ffi_env_stream)


def find_runtime_libraries(*, enable_tvm_ffi: bool = True) -> list[str]:
    """
    Find the runtime libraries that needs to be available for loading modules.

    :param enable_tvm_ffi: Whether to enable TVM-FFI.
    :type enable_tvm_ffi: bool, optional
    :return: A list of runtime libraries that needs to be available for loading modules.
    :rtype: list
    """

    def _get_cute_dsl_runtime_path() -> str | None:
        libs = get_prefix_dsl_libs("CUTE_DSL")
        if libs is None:
            return None

        # check if the separator is ; for windows
        if sys.platform.startswith("win32") and ";" in libs:
            libs = libs.split(";")  # type: ignore[assignment]
        else:
            libs = libs.split(":")  # type: ignore[assignment]

        for path in libs:
            if path.endswith("libcute_dsl_runtime.so"):
                return path

        return None

    libs = []
    cute_dsl_runtime_path = _get_cute_dsl_runtime_path()
    if cute_dsl_runtime_path:
        libs.append(cute_dsl_runtime_path)

    if enable_tvm_ffi:
        import tvm_ffi

        libs.append(tvm_ffi.libinfo.find_libtvm_ffi())

    return libs

# cache to load runtime libraries so they can be found by the DSO loader
_LOAD_MODULE_LIBS_CACHE: list[Any] = []


def load_module(
    file_path: str, *, enable_tvm_ffi: bool = False
) -> ExternalBinaryModule:
    """Load a module from a file path.

    :param file_path: The path to the module file
    :type file_path: str
    :param enable_tvm_ffi: Whether to enable TVM-FFI, defaults to False. When True, the module will be loaded as a TVM-FFI module.
    :type enable_tvm_ffi: bool, optional
    :return: A module object
    :rtype: module
    """
    if len(_LOAD_MODULE_LIBS_CACHE) == 0:
        # ensure the runtime libraries are loaded so they can be found by the DSO loader
        # no need to load tvm_ffi library here since it will be loaded by tvm_ffi package.
        for path in find_runtime_libraries(enable_tvm_ffi=False):
            if Path(path).exists():
                _LOAD_MODULE_LIBS_CACHE.append(ctypes.CDLL(path))

    return ExternalBinaryModule(file_path, enable_tvm_ffi=enable_tvm_ffi)
