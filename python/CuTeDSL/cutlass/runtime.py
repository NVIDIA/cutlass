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

from __future__ import annotations

import ctypes
import re
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Any, Literal, Optional, Type, Union

from cutlass._mlir import ir
import cutlass._mlir.dialects.cuda as _cuda_dialect
from cutlass.base_dsl import AddressSpace
from cutlass.base_dsl.env_manager import get_prefix_dsl_libs
from cutlass.base_dsl.export import ExternalBinaryModule

if TYPE_CHECKING:
    from cutlass.cute.runtime import _FakeTensor
    from cutlass.cute.typing import Numeric, SymInt


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

        # ':' before a path separator is a drive colon, not a separator.
        if sys.platform.startswith("win32"):
            libs = [p for p in re.split(r";|:(?![\\/])", libs) if p]  # type: ignore[assignment]
        else:
            libs = libs.split(":")  # type: ignore[assignment]

        # MSVC drops the "lib" prefix.
        runtime_name = (
            "cute_dsl_runtime.dll"
            if sys.platform.startswith("win32")
            else "libcute_dsl_runtime.so"
        )
        for path in libs:
            if path.endswith(runtime_name):
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

# Keep runtime library handles alive so they remain visible to the DSO loader.
_LOAD_MODULE_LIBS_CACHE: dict[str, ctypes.CDLL] = {}


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
    # A TVM-FFI module may be loaded after a non-TVM module has already
    # populated the cache, so load every dependency missing for this call.
    for path in find_runtime_libraries(enable_tvm_ffi=enable_tvm_ffi):
        if path not in _LOAD_MODULE_LIBS_CACHE and Path(path).exists():
            _LOAD_MODULE_LIBS_CACHE[path] = ctypes.CDLL(path)

    return ExternalBinaryModule(file_path, enable_tvm_ffi=enable_tvm_ffi)

# ---------------------------------------------------------------------------
# Host-side ``cutlass.Array`` compile-time placeholders.
# ---------------------------------------------------------------------------
# ``_FakeArray`` is the ``cutlass.Array`` analogue of
# ``cute.runtime._FakeTensor`` (the host-entry placeholder for ``cute.Tensor``).
# It carries the same MLIR signature and C-ABI as the cute-tensor entry path,
# so the kernel ABI is unchanged; the only difference is that the kernel body
# sees a ``cutlass.Array`` (``Array(tensor)``) instead of a
# ``cute.Tensor``. The factories mirror ``cute.runtime.make_fake_compact_tensor``
# / ``make_fake_tensor``.
#
# ``_FakeArray`` subclasses ``cute.runtime._FakeTensor``, but ``cute.runtime``
# imports THIS module at its top (for ``_FakeStream`` et al.; see
# ``cutlass/cute/runtime.py``) *before* it defines ``_FakeTensor``. Importing
# ``_FakeTensor`` at module scope here would therefore form a
# ``cutlass.runtime`` <-> ``cutlass.cute.runtime`` cycle during ``import
# cutlass``. The class is built lazily on first use, and the factories import
# their cute dependencies only when called -- long after ``import cutlass`` has
# completed.

_FAKE_ARRAY_CLS: Any = None


def _fake_array_cls() -> type:
    """Lazily build (and cache) the ``_FakeArray`` class.

    Deferred to first use to avoid the ``cutlass.runtime`` <->
    ``cutlass.cute.runtime`` import cycle described above.
    """
    global _FAKE_ARRAY_CLS
    if _FAKE_ARRAY_CLS is not None:
        return _FAKE_ARRAY_CLS

    from cutlass.cute.runtime import _FakeTensor

    class _FakeArray(_FakeTensor):  # type: ignore[valid-type, misc]
        """Compile-time placeholder for a ``cutlass.Array`` host-entry argument.

        Inherits MLIR-type, C-ABI, and host-side descriptor handling from
        ``cute.runtime._FakeTensor``. Only ``__new_from_mlir_values__`` differs:
        it reconstructs the in-kernel Python wrapper as a ``cutlass.Array``
        (``Array(tensor)``) rather than a bare cute tensor.
        """

        def __new_from_mlir_values__(self, values: list[object]) -> Any:
            # Reconstruct as a cute.Tensor first (parent path), then wrap it as a
            # cutlass.Array so the kernel body sees an Array. ``Array(tensor)`` is
            # the public way to view an existing tensor's memory as an Array, so
            # this carries no dependency on any other namespace. The import is
            # deferred to call time (this runs during kernel-body construction,
            # long after cutlass is fully imported).
            core_tensor = super().__new_from_mlir_values__(values)
            from cutlass.base_dsl.typing import Array

            return Array(core_tensor)

        @property
        def __cache_key__(self) -> tuple:
            # Must differ from _FakeTensor's key even when shape/dtype match, so
            # the compile cache distinguishes Array- vs Tensor-annotated host
            # entries (they emit different kernel-side wrappers / binaries).
            return ("cutlass._FakeArray",) + super().__cache_key__

        @property  # type: ignore[misc]
        def __class__(self) -> type:  # type: ignore[override]
            # The JIT executor validates host-entry args with
            # ``isinstance(arg, arg_annotation)``. For an ``a: cutlass.Array``
            # annotation, _FakeArray must report itself as cutlass.Array even
            # though its MRO descends from cute.Tensor -- mirroring
            # ``cute.runtime._Tensor.__class__``.
            from cutlass.base_dsl.typing import Array

            return Array

        def __str__(self) -> str:
            return f"FakeArray<{self.element_type}, {self.shape}, {self.stride}>"

    _FAKE_ARRAY_CLS = _FakeArray
    return _FAKE_ARRAY_CLS


def __getattr__(name: str) -> Any:
    # Expose ``cutlass.runtime._FakeArray`` (and ``from cutlass.runtime import
    # _FakeArray``) without an import-time dependency on cute.runtime.
    if name == "_FakeArray":
        return _fake_array_cls()
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def make_fake_compact_array(
    dtype: Type[Numeric],
    shape: tuple[Union[int, SymInt], ...],
    *,
    stride_order: Optional[tuple[int, ...]] = None,
    memspace: AddressSpace = AddressSpace.gmem,
    assumed_align: Optional[int] = None,
    use_32bit_stride: bool = False,
) -> _FakeTensor:
    """Create a fake ``cutlass.Array`` descriptor with a compact layout.

    Mirrors :func:`cutlass.cute.runtime.make_fake_compact_tensor`: same
    arguments, same stride-derivation logic. The only difference is the
    returned placeholder type, which causes the kernel body to see a
    ``cutlass.Array`` (rather than a ``cute.Tensor``) when this placeholder is
    passed to a compile entry point.

    :param dtype: Element data type.
    :param shape: Tensor extents in elements. Each entry may be static
        (``int``) or dynamic (:class:`~cutlass.cute.typing.SymInt`).
    :param stride_order: Permutation describing which mode is fastest changing.
        ``0`` means the innermost / stride-1 mode. Defaults to left-to-right
        order ``(0, 1, ..., n-1)``.
    :param memspace: Memory space where the fake array resides. Defaults to
        :attr:`AddressSpace.gmem`.
    :param assumed_align: Assumed byte alignment of the base pointer. If
        ``None``, defaults to one element width in bytes.
    :param use_32bit_stride: Use 32-bit symbolic strides instead of 64-bit ones
        for dynamic layouts. Only affects dynamically-derived stride entries.
    :returns: A ``_FakeArray`` placeholder.
    """
    from cutlass.cute.typing import SymInt

    if stride_order is not None:
        if len(stride_order) != len(shape):
            raise ValueError(
                f"stride_order ({stride_order}) must be empty or have same "
                f"length as shape ({shape})."
            )
    else:
        # Default stride order is left-to-right.
        stride_order = tuple(range(len(shape)))

    # Derive compact (possibly symbolic) strides from shape & stride_order.
    # Logic mirrors cute.runtime.make_fake_compact_tensor.
    stride: list[Any] = [None] * len(stride_order)
    stride_product: Union[int, SymInt] = 1
    for order in range(len(stride_order)):
        idx = stride_order.index(order)
        stride[idx] = stride_product
        stride_product *= shape[idx]  # type: ignore[assignment]

    stride_width: Literal[32, 64] = 32 if use_32bit_stride else 64
    stride_out = tuple(
        (
            SymInt(width=stride_width, divisibility=s.divisibility)
            if isinstance(s, SymInt)
            else s
        )
        for s in stride
    )

    return _fake_array_cls()(
        dtype,
        shape,
        stride=stride_out,
        memspace=memspace,
        assumed_align=assumed_align,
        use_32bit_stride=use_32bit_stride,
    )


def make_fake_array(
    dtype: Type[Numeric],
    shape: tuple[Union[int, SymInt], ...],
    stride: tuple[Union[int, SymInt], ...],
    *,
    memspace: AddressSpace = AddressSpace.gmem,
    assumed_align: Optional[int] = None,
) -> _FakeTensor:
    """Create a fake ``cutlass.Array`` descriptor with an explicit stride.

    Mirrors :func:`cutlass.cute.runtime.make_fake_tensor`: same arguments, same
    semantics. The only difference is the returned placeholder type, which
    causes the kernel body to see a ``cutlass.Array`` (rather than a
    ``cute.Tensor``) when this placeholder is passed to a compile entry point.

    :param dtype: Element data type.
    :param shape: Tensor extents in elements.
    :param stride: Explicit stride tuple in elements. Must have the same rank as
        ``shape``.
    :param memspace: Memory space where the fake array resides. Defaults to
        :attr:`AddressSpace.gmem`.
    :param assumed_align: Assumed byte alignment of the base pointer. If
        ``None``, defaults to one element width in bytes.
    :returns: A ``_FakeArray`` placeholder.
    """
    return _fake_array_cls()(
        dtype,
        shape,
        stride=stride,
        memspace=memspace,
        assumed_align=assumed_align,
    )
