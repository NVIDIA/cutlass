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

"""
This module provides jit executor related classes.

Pointer-address runtime arguments are opt-in. A compile-time example such as
``nullptr(dtype, space)`` marks the corresponding runtime argument as a
pointer slot, and
``ExecutionArgs.record_pointer_arg_specs_from_compile_args`` records that
metadata in ``_pointer_address_arg_specs``. Runtime calls may then pass an
integer address, ``ctypes.c_void_p``, a ctypes pointer object, or
``nullptr(...)`` for a null address. Native JIT execution packs raw
addresses into stable ``ctypes.c_void_p`` storage via ``_RuntimePointerArg``;
``nullptr(...)`` already provides that storage itself and is retained as a
keepalive when used as a temporary runtime argument. TVM FFI receives raw
integer addresses instead.

Plain integers are treated as pointer addresses only when the function
annotation is pointer-shaped. This avoids silently repacking ordinary scalar
integer parameters. Nested list/tuple compile-time arguments preserve the
sequence shape; mismatched runtime sequence lengths are left unchanged.
Arguments beyond the filtered runtime signature do not have annotation
metadata, so plain integer tail arguments stay scalar. Explicit ctypes pointer
tail arguments are still packed as pointer slots.
"""

import abc
import array
import ctypes
import inspect
import io
from typing import Any, NamedTuple, TYPE_CHECKING, ClassVar, cast, get_args, get_origin
from collections.abc import Callable, Sequence
import weakref
import threading
import collections
import os
import tempfile
from dataclasses import dataclass

# MLIR modules imports
from .._mlir import ir
from .._mlir.dialects import llvm

# Local modules imports
from . import typing as t
from .common import (
    DSLRuntimeError,
    DSLUserCodeError,
    DSLCudaRuntimeError,
)
from .diagnostics import DiagId
from .runtime import cuda as cuda_helpers
from .runtime.jit_arg_adapters import JitArgAdapterRegistry, is_arg_annotation_constexpr
from .typing import get_c_pointers
from .utils.logger import log
from .utils.timer import timer

if TYPE_CHECKING:
    from .compiler import HostTarget
    from .dsl import BaseDSL
    from .export.export import SignatureProcessor
    from .export.c_header_generator import CHeaderGenerator


@dataclass
class CudaModuleAndKernel:
    """A loaded CUDA kernel and its metadata."""

    sym: str
    cuda_module: Any
    kernel: Any
    attrs: dict[Any, int]


def get_escaped_cubin_bytes(cubin_data: bytes) -> bytes:
    """This function escapes cubin data from mlir raw bytecode to executable binary bytes"""

    def ishex(inp: int) -> bool:
        return (0x30 <= inp < 0x3A) or (0x41 <= inp < 0x47) or (0x61 <= inp < 0x67)

    converted = bytearray()
    idx = 0
    while idx < len(cubin_data):
        # escape the original bytes
        if cubin_data[idx] == 0x5C:
            # if data of idx is b'\\'
            if ishex(cubin_data[idx + 1]) and ishex(cubin_data[idx + 2]):
                converted += bytearray.fromhex(cubin_data[idx + 1 : idx + 3].decode())
                idx += 3
            elif cubin_data[idx + 1] == 0x5C:
                converted.append(cubin_data[idx])
                idx += 2
        else:
            # no escape, directly write
            converted.append(cubin_data[idx])
            idx += 1
    return bytes(converted)


def walk_module_and_get_cubin_data(
    module: ir.Module, sym: str, callback: Callable[[str, str, bytes], None]
) -> None:
    """This function is used to walk gpu binary op, extract the cubin inside, and process cubin data with callback."""

    def walk_gpu_binary_op(op: ir.Operation) -> ir.WalkResult:
        if op.name != "gpu.binary":
            return ir.WalkResult.ADVANCE
        s = io.BytesIO()
        op.write_bytecode(s)
        cubin_data = s.getvalue()
        if sym.encode() not in cubin_data:
            return ir.WalkResult.ADVANCE

        if "kernels" != op.opview.sym_name.value and sym != op.opview.sym_name.value:
            return ir.WalkResult.ADVANCE
        # function symbol of kernel(gpu.launch_func) is equal to sym name in mlir
        func_sym = sym
        if sym == op.opview.sym_name.value and not sym.endswith("_kernel"):
            func_sym = sym.rsplit("_", 1)[0]

        cubin_data = cubin_data.split(b'bin = "')[1].split(b'">')[0]
        cubin_data = get_escaped_cubin_bytes(cubin_data)
        callback(sym, func_sym, cubin_data)
        return ir.WalkResult.ADVANCE

    module.operation.walk(walk_gpu_binary_op)


def load_kernels_from_ir_module(
    module: ir.Module, kernel_info: dict[str, Any] | None
) -> list[CudaModuleAndKernel]:
    """Loads all kernels from the IR module that match the given set of symbols."""
    if not kernel_info:
        return []  # no modules

    # don't sort because the external kernel pointers are recorded in the order called in ir module.
    kernel_symbols = tuple(kernel_info.keys())

    # load cuda module/get function pointer from module and cache
    kernel_modules = collections.OrderedDict()
    for sym in kernel_symbols:
        log().debug(f"Loading CUDA module for symbol: {sym}")

        def walk_callback(sym: str, func_sym: str, cubin_data: bytes) -> None:
            if sym in kernel_modules:
                log().debug(f"Skipping already loaded symbol: {sym}")

            cubin_module = cuda_helpers.load_library_data(cubin_data)
            kernel = cuda_helpers.get_library_kernel(cubin_module, func_sym)

            # Setup attributes we want applied to the loaded kernel functions.
            # A copy is made so we can update one of the attributes.
            attrs = dict(kernel_info[sym])
            if cuda_helpers.get_driver_version() >= 11080:
                attrs[
                    cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED
                ] = 1

            kernel_modules[sym] = CudaModuleAndKernel(sym, cubin_module, kernel, attrs)

        walk_module_and_get_cubin_data(module, sym, walk_callback)

    return list(kernel_modules.values())


@dataclass
class ArgMeta:
    """Metadata for function arguments."""

    pos_names: list[str]
    kwonly_names: list[str]
    all_names: list[str]
    annotated_types: list[object]
    numeric_flags: list[bool]
    name_to_index: dict[str, int]
    pos_defaults: list[object]
    kwonly_defaults: list[object]
    arg_count: int


class KwargsWrapperSpec(NamedTuple):
    """A specification for keyword arguments wrapper."""

    arg_names: list[str]
    arg_defaults: tuple[Any, ...]
    kwonly_names: list[str]
    kwonly_defaults: dict[str, Any]


def _validate_pointer_address(address: int) -> None:
    if address < 0:
        raise DSLUserCodeError(
            DiagId.ARG_POINTER_NEGATIVE,
            address=address,
        )


class _RuntimePointerArg:
    """JIT argument wrapper for a raw pointer address supplied from Python."""

    def __init__(self, address: int) -> None:
        _validate_pointer_address(address)
        self._desc = ctypes.c_void_p(address)
        self._c_pointers_cache = [ctypes.addressof(self._desc)]

    def __c_pointers__(self) -> list[int]:
        return self._c_pointers_cache


PointerAddressArgSpec = bool | list[object] | tuple[object, ...] | None


def _is_ctypes_pointer(arg: object) -> bool:
    return isinstance(arg, (ctypes.c_void_p, ctypes._Pointer))


def _is_pointer_annotation(annotation: object) -> bool:
    if annotation is None:
        return False

    if isinstance(annotation, t.PointerMeta):
        return True

    if type(annotation).__name__ == "TypedPointer":
        return True

    if any(_is_pointer_annotation(arg) for arg in get_args(annotation)):
        return True

    return getattr(annotation, "__name__", None) == "Pointer" and getattr(
        annotation, "__module__", ""
    ).endswith(
        (
            "cutlass.base_dsl.typing",
            "cutlass.cute.typing",
            "cutlass.cute.core",
        )
    )


def _sequence_element_annotations(
    annotation: object, length: int, *, is_tuple: bool
) -> list[object]:
    args = get_args(annotation)
    if not args:
        return [None] * length

    origin = get_origin(annotation)
    if origin is tuple:
        if not is_tuple:
            return [None] * length
        if len(args) == 2 and args[1] is Ellipsis:
            return [args[0]] * length
        if len(args) == length:
            return list(args)
        return [None] * length

    if origin in (list, Sequence):
        return [args[0]] * length

    return [None] * length


def _python_pointer_address(arg: object) -> int | None:
    if isinstance(arg, bool):
        return None
    if getattr(arg, "_python_pointer_address_arg", False) is True:
        return 0
    if isinstance(arg, int):
        return arg
    if isinstance(arg, ctypes.c_void_p):
        return 0 if arg.value is None else int(arg.value)
    if isinstance(arg, ctypes._Pointer):
        value = ctypes.cast(arg, ctypes.c_void_p).value
        return 0 if value is None else int(value)
    return None


def _pointer_address_spec_from_compile_arg(
    arg: object, annotation: object = None
) -> PointerAddressArgSpec:
    if getattr(arg, "_python_pointer_address_arg", False) is True:
        return True

    if isinstance(arg, (list, tuple)):
        child_annotations = _sequence_element_annotations(
            annotation, len(arg), is_tuple=isinstance(arg, tuple)
        )
        child_specs = [
            _pointer_address_spec_from_compile_arg(x, child_annotations[index])
            for index, x in enumerate(arg)
        ]
        if any(spec is not None for spec in child_specs):
            return cast(
                PointerAddressArgSpec,
                tuple(child_specs) if isinstance(arg, tuple) else child_specs,
            )

    address = _python_pointer_address(arg)
    if address is not None:
        if _is_ctypes_pointer(arg) or _is_pointer_annotation(annotation):
            return True
        return None

    return None


def _convert_python_pointer_arg(
    arg: object, spec: PointerAddressArgSpec, *, for_tvm_ffi: bool = False
) -> tuple[object, bool]:
    if spec is None:
        return arg, False

    if spec is True:
        if (
            not for_tvm_ffi
            and getattr(arg, "_python_pointer_address_arg", False) is True
        ):
            return arg, True
        address = _python_pointer_address(arg)
        if address is None:
            return arg, False
        _validate_pointer_address(address)
        if for_tvm_ffi:
            return address, True
        return _RuntimePointerArg(address), True

    if isinstance(spec, (list, tuple)) and isinstance(arg, (list, tuple)):
        if len(arg) != len(spec):
            return arg, False
        changed = False
        converted = []
        for item, item_spec in zip(arg, spec):
            converted_item, item_changed = _convert_python_pointer_arg(
                item, cast(PointerAddressArgSpec, item_spec), for_tvm_ffi=for_tvm_ffi
            )
            converted.append(converted_item)
            changed = changed or item_changed
        if not changed:
            return arg, False
        return tuple(converted) if isinstance(arg, tuple) else converted, True

    return arg, False


class PreparedLaunchError(DSLUserCodeError):
    """Raised when a compiled function cannot be prepared for in-place launch.

    :meth:`JitCompiledFunction.prepare` validates every runtime argument up
    front; an argument mix it cannot re-bind in place raises this error at
    prepare time instead of failing (or silently mis-launching) later.
    ``compiled(*args)`` remains available for any argument mix.
    """


# Numeric scalar types a prepared launch can update in place, mapped to the
# ctypes storage their ``__c_pointers__`` marshalling produces (see
# ``NumericMeta`` and the ``Float32``/``Float64`` implementations in
# ``typing``). Types whose marshalling is not a plain ctypes scalar store
# (Float16/BFloat16 bit conversions, Int4/Int128) are intentionally absent
# and rejected at prepare time.
_PREPARED_NUMERIC_CTYPES: dict[Any, Any] = {
    t.Boolean: ctypes.c_bool,
    t.Int8: ctypes.c_int8,
    t.Int16: ctypes.c_int16,
    t.Int32: ctypes.c_int32,
    t.Int64: ctypes.c_int64,
    t.Uint8: ctypes.c_uint8,
    t.Uint16: ctypes.c_uint16,
    t.Uint32: ctypes.c_uint32,
    t.Uint64: ctypes.c_uint64,
    t.Float32: ctypes.c_float,
    t.Float64: ctypes.c_double,
    t.TFloat32: ctypes.c_float,
}

# Plain Python scalars marshal through the registered JIT argument adapter
# (``_convert_python_scalar``), which fixes their DSL type as follows.
_PREPARED_PYTHON_SCALAR_TYPES: dict[type, Any] = {
    bool: t.Boolean,
    int: t.Int32,
    float: t.Float32,
}


class _PreparedArgSlot:
    """Stable storage backing one packed argument slot of a prepared launch.

    ``prepare()`` snapshots the bytes the normal marshalling produced into
    ``storage`` once; later launches only rewrite ``storage`` in place via
    :meth:`write`, so the packed argument array never has to be rebuilt.
    """

    def __init__(self, name: str, ctype: Any) -> None:
        self.name = name
        self.storage = ctype()

    @property
    def address(self) -> int:
        return ctypes.addressof(self.storage)

    def snapshot(self, exe_arg: Any) -> None:
        """Copy the marshalled bytes referenced by ``exe_arg`` into this slot."""
        source = exe_arg.value if type(exe_arg) is ctypes.c_void_p else exe_arg
        ctypes.memmove(self.address, source, ctypes.sizeof(self.storage))

    def write(self, value: Any) -> None:
        """Rewrite the slot from ``value``; raises TypeError on a bad value."""
        raise NotImplementedError


class _PreparedPointerSlot(_PreparedArgSlot):
    """Pointer-sized slot for runtime pointers and pointer-address arguments."""

    def __init__(self, name: str, desc_owner: Any = None) -> None:
        super().__init__(name, ctypes.c_void_p)
        # Runtime pointer objects marshal the address of their c_void_p
        # ``_desc`` cell; remember the prepare-time argument so snapshot()
        # can verify the marshalling actually followed that contract.
        self._desc_owner = desc_owner

    def snapshot(self, exe_arg: Any) -> None:
        owner = self._desc_owner
        if owner is not None:
            self._desc_owner = None  # never outlive prepare()
            source = exe_arg.value if type(exe_arg) is ctypes.c_void_p else exe_arg
            if source != ctypes.addressof(owner._desc):
                # An object that looks like a runtime pointer (c_void_p
                # ``_desc`` plus ``__c_pointers__``) but marshals something
                # other than its ``_desc`` cannot be re-bound in place.
                raise PreparedLaunchError(
                    DiagId.LAUNCH_PREPARE_UNSUPPORTED_ARG,
                    arg_name=self.name,
                    arg_type=type(owner).__name__,
                )
            self.storage.value = owner._desc.value
            return
        super().snapshot(exe_arg)

    def write(self, value: Any) -> None:
        if type(value) is int:
            self.storage.value = value
            return
        # Runtime pointer storage contract: cute runtime Pointer objects and
        # _RuntimePointerArg both keep their address in a c_void_p ``_desc``.
        desc = getattr(value, "_desc", None)
        if type(desc) is ctypes.c_void_p:
            self.storage.value = desc.value
            return
        address = _python_pointer_address(value)
        if address is None:
            raise TypeError(f"expected a pointer-like value, got {type(value)!r}")
        self.storage.value = address


class _PreparedScalarSlot(_PreparedArgSlot):
    """Fixed-width numeric slot; accepts Python scalars and Numeric instances.

    Values are stored through plain ctypes assignment: the same bytes the
    normal marshalling would produce for values of the prepared kind, with
    ctypes conversion semantics (out-of-range integers truncate; a value the
    storage rejects, such as a float for an integer slot, raises instead of
    applying the DSL cast a direct call would).
    """

    def write(self, value: Any) -> None:
        self.storage.value = value.value if isinstance(value, t.Numeric) else value


class _PreparedBooleanSlot(_PreparedArgSlot):
    """Boolean slot; accepts bool/int values only (no truthiness coercion)."""

    def __init__(self, name: str) -> None:
        super().__init__(name, ctypes.c_bool)

    def write(self, value: Any) -> None:
        if isinstance(value, t.Numeric):
            value = value.value
        if type(value) is not bool and type(value) is not int:
            raise TypeError(f"expected a bool, got {type(value)!r}")
        self.storage.value = value


def _make_scalar_slot(name: str, ctype: Any) -> _PreparedArgSlot:
    if ctype is ctypes.c_bool:
        return _PreparedBooleanSlot(name)
    return _PreparedScalarSlot(name, ctype)


class _PreparedStreamSlot(_PreparedArgSlot):
    """Pointer-sized slot holding a raw CUDA stream handle."""

    def __init__(self, name: str) -> None:
        super().__init__(name, ctypes.c_void_p)

    def write(self, value: Any) -> None:
        if type(value) is int:
            self.storage.value = value
            return
        if isinstance(
            value, (cuda_helpers.cuda.CUstream, cuda_helpers.cudart.cudaStream_t)
        ):
            self.storage.value = int(value)
            return
        # Framework stream objects (e.g. torch.cuda.Stream) expose the raw
        # driver handle as an integer ``cuda_stream`` attribute.
        try:
            handle = value.cuda_stream
        except AttributeError:
            handle = None
        except Exception as e:
            raise TypeError(f"reading cuda_stream from {type(value)!r} failed") from e
        if type(handle) is int:
            self.storage.value = handle
            return
        raise TypeError(
            "expected a CUDA stream, a framework stream with an integer "
            f"cuda_stream attribute, or a raw integer handle, got {type(value)!r}"
        )


def _is_stream_annotation(annotation: Any) -> bool:
    return getattr(annotation, "__name__", None) in ("CUstream", "cudaStream_t")


def _is_stream_instance(arg: Any) -> bool:
    return isinstance(
        arg, (cuda_helpers.cuda.CUstream, cuda_helpers.cudart.cudaStream_t)
    )


def _prepared_slot_for_arg(
    name: str,
    arg: Any,
    annotation: Any,
    is_numeric: bool,
    spec: PointerAddressArgSpec,
) -> _PreparedArgSlot:
    """Classify one runtime argument into an in-place-updatable slot.

    Mirrors the marshalling decisions of ``generate_execution_args`` for the
    closed set of argument kinds whose storage a prepared launch can rewrite:
    pointer-address slots, numeric scalars with plain ctypes storage, CUDA
    streams, and runtime pointer objects. Classification is driven by the
    declared annotation where it is informative (numeric, pointer, stream),
    so a value of the wrong kind for a declared slot is rejected here rather
    than mis-marshalled; unannotated slots classify by value. Anything else —
    dlpack tensors, structs, sequences, custom JIT arguments — raises
    :class:`PreparedLaunchError`.
    """
    if spec is True and _python_pointer_address(arg) is not None:
        return _PreparedPointerSlot(name)
    if is_numeric:
        ctype = _PREPARED_NUMERIC_CTYPES.get(annotation)
        if ctype is not None:
            return _make_scalar_slot(name, ctype)
        raise PreparedLaunchError(
            DiagId.LAUNCH_PREPARE_UNSUPPORTED_ARG,
            arg_name=name,
            arg_type=getattr(annotation, "__name__", str(annotation)),
        )
    if _is_pointer_annotation(annotation):
        # A declared pointer slot must be prepared with a runtime pointer
        # (storage contract: address held in a c_void_p ``_desc``).
        desc = getattr(arg, "_desc", None)
        if type(desc) is ctypes.c_void_p and hasattr(arg, "__c_pointers__"):
            return _PreparedPointerSlot(name, desc_owner=arg)
        raise PreparedLaunchError(
            DiagId.LAUNCH_PREPARE_UNSUPPORTED_ARG,
            arg_name=name,
            arg_type=type(arg).__name__,
        )
    if _is_stream_annotation(annotation):
        # A declared stream slot must be prepared with a real CUDA stream
        # object (raw integer handles are accepted at launch time only).
        if _is_stream_instance(arg):
            return _PreparedStreamSlot(name)
        raise PreparedLaunchError(
            DiagId.LAUNCH_PREPARE_UNSUPPORTED_ARG,
            arg_name=name,
            arg_type=type(arg).__name__,
        )
    if isinstance(arg, t.Numeric):
        ctype = _PREPARED_NUMERIC_CTYPES.get(type(arg))
        if ctype is not None:
            return _make_scalar_slot(name, ctype)
    dsl_scalar_type = _PREPARED_PYTHON_SCALAR_TYPES.get(type(arg))
    if dsl_scalar_type is not None:
        return _make_scalar_slot(name, _PREPARED_NUMERIC_CTYPES[dsl_scalar_type])
    if _is_stream_instance(arg):
        return _PreparedStreamSlot(name)
    desc = getattr(arg, "_desc", None)
    if type(desc) is ctypes.c_void_p and hasattr(arg, "__c_pointers__"):
        return _PreparedPointerSlot(name, desc_owner=arg)
    raise PreparedLaunchError(
        DiagId.LAUNCH_PREPARE_UNSUPPORTED_ARG,
        arg_name=name,
        arg_type=type(arg).__name__,
    )


class ExecutionArgs:
    """Runtime argument binder for compiled JIT functions.

    Besides normal signature rectification and scalar casting, this class owns
    the pointer-address conversion contract.
    ``record_pointer_arg_specs_from_compile_args`` derives a lightweight spec
    tree from compile-time arguments, and
    ``generate_execution_args`` / ``convert_python_pointer_args_for_tvm_ffi`` use
    that spec to decide where Python pointer-like values may replace runtime
    pointer objects. Extra tail arguments are outside the signature and have no
    ``name_to_index`` entry or compile-example spec; only explicit ctypes
    pointer objects are repacked there.
    """

    def __init__(
        self,
        signature: inspect.Signature,
        function_name: str,
        full_arg_check: bool = False,
    ) -> None:
        self.function_name = function_name
        self.signature = self.filter_runtime_signature(signature)
        self.original_signature = signature
        self._missing = object()
        self._meta = self._build_meta()
        self._pointer_address_arg_specs: list[PointerAddressArgSpec] = [
            None
        ] * self._meta.arg_count
        self._has_pointer_address_arg_specs = False
        # When True (set when debugging mode is ON), generate_execution_args
        # runs thorough per-argument validation that is otherwise skipped to
        # keep the launch path fast.
        self._full_arg_check = full_arg_check
        self._tls = threading.local()

    @property
    def has_pointer_address_arg_specs(self) -> bool:
        """Whether this compiled signature has pointer-address conversion slots."""
        return self._has_pointer_address_arg_specs

    def record_pointer_arg_specs_from_compile_args(
        self, args: tuple[Any, ...], kwargs: dict[str, Any]
    ) -> None:
        """Record pointer conversion metadata from compile-time arguments.

        The resulting ``_pointer_address_arg_specs`` list is indexed like the
        filtered runtime signature. Each leaf is ``True`` for an argument slot
        that may accept a raw pointer address, ``None`` for ordinary arguments,
        or a nested list/tuple spec for sequence arguments.

        ``_pointer_address_spec_from_compile_arg`` marks explicit pointer
        arguments such as ``nullptr(...)`` and ctypes pointer objects. Plain
        ``int`` compile-time arguments are marked only when the corresponding
        annotation is pointer-shaped; this keeps scalar integer parameters from
        being packed as pointer slots. For mixed tuple annotations, element
        annotations are matched positionally. For generic sequence annotations
        such as
        ``list[cutlass.Pointer]`` or ``Sequence[cutlass.Pointer]``, the inner annotation
        is applied to each element.

        ``args``/``kwargs`` are first rectified through the function signature
        unless they already exactly match the positional runtime shape. That
        path may raise the usual argument-binding ``DSLRuntimeError`` cases:
        missing, unexpected, or duplicate arguments.
        """
        if not args and not kwargs:
            return

        if not kwargs and len(args) == self._meta.arg_count:
            input_args: Sequence[Any] = args
        else:
            input_args = self.get_rectified_args(args, kwargs)

        self._pointer_address_arg_specs = [
            _pointer_address_spec_from_compile_arg(
                arg, self._meta.annotated_types[index]
            )
            for index, arg in enumerate(input_args)
        ]
        self._has_pointer_address_arg_specs = any(
            spec is not None for spec in self._pointer_address_arg_specs
        )

    def convert_python_pointer_args_for_tvm_ffi(
        self, args: tuple[Any, ...], kwargs: dict[str, Any]
    ) -> tuple[tuple[Any, ...], dict[str, Any]]:
        """Convert pointer-like Python arguments for TVM FFI calls.

        TVM FFI expects pointer values as integer addresses rather than native
        JIT pointer-slot storage. This method walks positional arguments and
        keyword arguments using ``_pointer_address_arg_specs`` and
        ``_convert_python_pointer_arg``. ``name_to_index`` maps keyword names
        back to the signature slot whose compile-time spec controls conversion.

        Returns the original ``args`` and ``kwargs`` objects when nothing
        changed. If any conversion happens, returns a new positional tuple and,
        only when needed, a copied kwargs dict. Sequence shapes are preserved
        only when runtime list/tuple lengths match the compile-time arguments;
        a mismatched or unsupported value is left unchanged. Negative pointer
        addresses raise ``DSLRuntimeError``.
        """
        if not self._has_pointer_address_arg_specs:
            return args, kwargs

        converted_args = list(args)
        changed = False
        positional_count = min(len(converted_args), self._meta.arg_count)
        for index in range(positional_count):
            converted, did_convert = _convert_python_pointer_arg(
                converted_args[index],
                self._pointer_address_arg_specs[index],
                for_tvm_ffi=True,
            )
            if did_convert:
                converted_args[index] = converted
                changed = True

        converted_kwargs = kwargs
        for name, value in kwargs.items():
            kw_index = self._meta.name_to_index.get(name)
            if kw_index is None or kw_index >= len(self._pointer_address_arg_specs):
                continue
            converted, did_convert = _convert_python_pointer_arg(
                value,
                self._pointer_address_arg_specs[kw_index],
                for_tvm_ffi=True,
            )
            if did_convert:
                if converted_kwargs is kwargs:
                    converted_kwargs = dict(kwargs)
                converted_kwargs[name] = converted
                changed = True

        if not changed:
            return args, kwargs
        return tuple(converted_args), converted_kwargs

    def _build_meta(self) -> ArgMeta:
        """
        Precompute metadata for the fast-path execution.
        This metadata is static per function signature.
        """
        sig = self.signature

        pos_names = []
        kwonly_names = []
        annotated_types = []
        numeric_flags = []
        name_to_index = {}
        pos_defaults = []
        kwonly_defaults = []

        for name, param in sig.parameters.items():
            if param.kind == inspect.Parameter.KEYWORD_ONLY:
                kwonly_names.append(name)
                if param.default is not inspect.Parameter.empty:
                    kwonly_defaults.append(param.default)
                else:
                    kwonly_defaults.append(self._missing)
            else:
                pos_names.append(name)
                if param.default is not inspect.Parameter.empty:
                    pos_defaults.append(param.default)
                else:
                    pos_defaults.append(self._missing)
            annotated_types.append(
                param.annotation
                if param.annotation is not inspect.Parameter.empty
                else None
            )
            numeric_flags.append(isinstance(param.annotation, t.NumericMeta))
            name_to_index[name] = len(pos_names) + len(kwonly_names) - 1

        return ArgMeta(
            pos_names=pos_names,
            kwonly_names=kwonly_names,
            all_names=pos_names + kwonly_names,
            annotated_types=annotated_types,
            numeric_flags=numeric_flags,
            name_to_index=name_to_index,
            pos_defaults=pos_defaults,
            kwonly_defaults=kwonly_defaults,
            arg_count=len(pos_names) + len(kwonly_names),
        )

    def get_rectified_args(
        self, args: tuple[Any, ...], kwargs: dict[str, Any]
    ) -> list[Any]:
        """
        This function is used to rectify the args and kwargs to a final runtime argument list according to the args_spec.
        """
        pos_count = len(self._meta.pos_names)
        if len(args) > pos_count:
            raise DSLUserCodeError(
                DiagId.CALL_TOO_MANY_ARGS,
                expected=len(self._meta.pos_names),
                provided=len(args),
            )

        # Start with every slot marked missing, we overwrite as values/defaults bind
        rectified = [self._missing] * self._meta.arg_count
        pos_len = len(args)

        # Fill positional slots with the values from the caller
        rectified[:pos_len] = args

        # Fill positional slots the caller skipped with the defaults
        for i in range(pos_len, pos_count):
            default = self._meta.pos_defaults[i]
            if default is not self._missing:
                rectified[i] = default

        # Fill keyword-only slots with the defaults before user kwargs
        for j, default in enumerate(self._meta.kwonly_defaults):
            idx = pos_count + j
            if default is not self._missing:
                rectified[idx] = default

        # Fill keyword slots with the values from the caller
        for name, value in kwargs.items():
            idx = self._meta.name_to_index.get(name)  # type: ignore[assignment]
            if idx is None:
                raise DSLUserCodeError(
                    DiagId.CALL_UNEXPECTED_KWARG,
                    argument_name=name,
                )
            if idx < pos_len:
                raise DSLUserCodeError(
                    DiagId.CALL_DUPLICATE_ARGUMENT,
                    argument_name=name,
                )
            rectified[idx] = value

        if self._missing in rectified:
            missing_args = [
                name
                for i, name in enumerate(self._meta.all_names)
                if rectified[i] is self._missing
            ]
            raise DSLUserCodeError(
                DiagId.CALL_MISSING_ARGS,
                missing=missing_args,
            )

        return rectified

    def generate_execution_args(
        self, args: tuple[Any, ...], kwargs: dict[str, Any]
    ) -> tuple[list[Any], list[Any]]:
        """
        This function is the prune version of `generate_mlir_function_types` which only generates execution args
        to get rid of mlir context.
        """
        n = self._meta.arg_count
        extra_args = args[n:] if len(args) > n else ()
        args = args[:n] if len(args) > n else args

        exe_arg_chunks: list[list[ctypes.c_void_p] | None] = [None] * n

        adapted_args = []
        tls = self._tls
        adapter_caches = getattr(tls, "adapter_caches", None)
        if adapter_caches is None:
            adapter_caches = [dict() for _ in range(n)]
            tls.adapter_caches = adapter_caches

        input_args: Sequence[Any]
        if not kwargs and len(args) == n:
            input_args = args
        else:
            input_args = self.get_rectified_args(args, kwargs)

        if self._full_arg_check:
            self._validate_args_full(input_args)

        for index, arg in enumerate(input_args):
            pointer_arg, is_pointer_address = _convert_python_pointer_arg(
                arg, self._pointer_address_arg_specs[index]
            )
            if is_pointer_address:
                adapted_args.append(pointer_arg)
                exe_arg_chunks[index] = get_c_pointers(pointer_arg)
                continue

            cptr_method = getattr(arg, "__c_pointers__", None)
            if cptr_method is not None:
                exe_arg_chunks[index] = cptr_method()
                continue

            if self._meta.numeric_flags[index]:
                arg = t.cast(arg, self._meta.annotated_types[index])  # type: ignore[arg-type]
                exe_arg_chunks[index] = get_c_pointers(arg)
            else:
                arg_type = type(arg)
                cache = adapter_caches[index]
                adapter = cache.get(arg_type)
                if adapter is None:
                    adapter = JitArgAdapterRegistry.get_registered_adapter(arg)
                    if adapter is not None:
                        cache[arg_type] = adapter

                if adapter is not None:
                    arg = adapter(arg)
                    adapted_args.append(arg)

                exe_arg_chunks[index] = get_c_pointers(arg)

        exe_args = [p for chunk in exe_arg_chunks for p in chunk]  # type: ignore[union-attr]

        # Insert extra auxiliary arguments if any.
        for arg in extra_args:
            cptr_method = getattr(arg, "__c_pointers__", None)
            if cptr_method is not None:
                exe_args.extend(cptr_method())
            else:
                address = (
                    _python_pointer_address(arg) if _is_ctypes_pointer(arg) else None
                )
                if address is None:
                    exe_args.append(arg)
                else:
                    pointer_arg = _RuntimePointerArg(address)
                    adapted_args.append(pointer_arg)
                    exe_args.extend(pointer_arg.__c_pointers__())

        return exe_args, adapted_args

    def generate_prepared_slots(
        self, args: tuple[Any, ...], kwargs: dict[str, Any]
    ) -> list[_PreparedArgSlot]:
        """Validate and marshal arguments once for a prepared launch.

        Classifies every runtime argument into a stable, in-place-updatable
        slot (pointer / numeric scalar / CUDA stream), then runs the normal
        ``generate_execution_args`` marshalling once and snapshots the
        resulting bytes into private per-argument storage. Later launches only
        rewrite those bytes, so the initial slot contents — and therefore the
        launch itself — are bit-identical to a direct call with the same
        argument values.

        :raises PreparedLaunchError: If any argument cannot be re-bound in
            place (dlpack tensors, structs, sequences, custom JIT arguments,
            numeric types without plain ctypes storage such as Float16), or if
            extra arguments beyond the runtime signature are passed.
        """
        meta = self._meta
        n = meta.arg_count
        if len(args) > n:
            raise PreparedLaunchError(
                DiagId.LAUNCH_PREPARE_EXTRA_ARGS,
                expected=n,
                provided=len(args),
            )

        input_args: Sequence[Any]
        if not kwargs and len(args) == n:
            input_args = args
        else:
            input_args = self.get_rectified_args(args, kwargs)

        slots = [
            _prepared_slot_for_arg(
                meta.all_names[index],
                arg,
                meta.annotated_types[index],
                meta.numeric_flags[index],
                self._pointer_address_arg_specs[index],
            )
            for index, arg in enumerate(input_args)
        ]

        # Every eligible argument kind marshals to exactly one execution
        # argument, so the flat list maps 1:1 onto the slots.
        exe_args, _adapted_args = self.generate_execution_args(tuple(input_args), {})
        if len(exe_args) != len(slots):
            raise DSLRuntimeError(
                "prepared-launch classification disagrees with "
                f"generate_execution_args ({len(slots)} slots for "
                f"{len(exe_args)} execution arguments)"
            )
        for slot, exe_arg in zip(slots, exe_args):
            slot.snapshot(exe_arg)
        return slots

    def _arg_marshals_to_pointers(self, arg: Any, spec: PointerAddressArgSpec) -> bool:
        """Whether ``arg`` will contribute at least one C pointer at launch.

        Mirrors the marshalling decisions in ``generate_execution_args``:
        pointer-address slots, ``__c_pointers__`` providers, registered JIT
        argument adapters, and (recursively) sequences. An argument that
        matches none of these is silently dropped by ``get_c_pointers`` (it
        returns ``[]``), so the kernel would receive the wrong arguments.
        """
        # Pointer-address slot: converted to a _RuntimePointerArg when the value
        # carries a pointer address (raw int / ctypes pointer / nullptr marker,
        # which _python_pointer_address already reports). When it does not,
        # generate_execution_args falls through to the branches below, so we do
        # too rather than rejecting a value that still marshals.
        if spec is True and _python_pointer_address(arg) is not None:
            return True
        if hasattr(arg, "__c_pointers__"):
            return True
        try:
            if JitArgAdapterRegistry.get_registered_adapter(arg) is not None:
                return True
        except Exception:
            # Classification is best-effort; if adapter lookup itself trips,
            # defer to the normal launch path rather than raising here.
            return True
        if isinstance(arg, (list, tuple)):
            if isinstance(spec, (list, tuple)) and len(spec) == len(arg):
                return all(
                    self._arg_marshals_to_pointers(
                        item, cast(PointerAddressArgSpec, item_spec)
                    )
                    for item, item_spec in zip(arg, spec)
                )
            return all(self._arg_marshals_to_pointers(item, None) for item in arg)
        return False

    def _validate_args_full(self, input_args: Sequence[Any]) -> None:
        """Thorough per-argument validation, run when debugging mode is ON.

        The normal launch path skips these checks to minimize overhead and
        trusts the caller to pass well-formed arguments. When debugging mode is
        ON we instead validate each argument against the recorded specs and
        raise a precise error rather than silently mis-marshalling (an argument
        that yields zero C pointers) or crashing inside the C call.

        Note: mismatched runtime sequence lengths are intentionally tolerated
        (see the module docstring) and are not flagged here.
        """
        meta = self._meta
        for index, arg in enumerate(input_args):
            name = meta.all_names[index] if index < len(meta.all_names) else f"#{index}"
            spec = self._pointer_address_arg_specs[index]

            # Numeric scalars must be number-like so the later t.cast succeeds;
            # only reject clearly non-numeric values to avoid false positives on
            # the DSL's own numeric wrapper types.
            if meta.numeric_flags[index]:
                if arg is None or isinstance(arg, (str, bytes, list, tuple, dict, set)):
                    raise DSLUserCodeError(
                        DiagId.ARG_NOT_NUMERIC,
                        arg_name=name,
                        arg_type=type(arg).__name__,
                        context={"position": index},
                    )
                continue

            if not self._arg_marshals_to_pointers(arg, spec):
                raise DSLUserCodeError(
                    DiagId.ARG_NOT_MARSHALABLE,
                    arg_name=name,
                    arg_type=type(arg).__name__,
                    context={"position": index},
                )

    def get_kwargs_wrapper_spec(
        self, exclude_arg_names: Sequence[str] = ()
    ) -> KwargsWrapperSpec:
        """
        This function is used to get the kwargs wrapper spec from the original signature.
        """
        excluded_arg_names = set(exclude_arg_names)
        sig = self.original_signature

        arg_names = []
        arg_defaults = []
        kwonly_names = []
        kwonly_defaults = {}

        for i, (name, param) in enumerate(sig.parameters.items()):
            # We don't want *args or **kwargs to be included in the
            # KwargsWrapperSpec, so skip them here. Including them
            # breaks functions that use *args or **kwargs.
            if param.kind in (
                inspect.Parameter.VAR_POSITIONAL,
                inspect.Parameter.VAR_KEYWORD,
            ):
                continue
            is_kwonly = param.kind == inspect.Parameter.KEYWORD_ONLY
            annotation = param.annotation
            if (
                is_arg_annotation_constexpr(annotation, name, i, None)
                or name in excluded_arg_names
            ):
                continue
            arg_names.append(name) if not is_kwonly else kwonly_names.append(name)
            if param.default is not inspect.Parameter.empty:
                if is_kwonly:
                    kwonly_defaults[name] = param.default
                else:
                    arg_defaults.append(param.default)

        return KwargsWrapperSpec(
            arg_names=arg_names,
            arg_defaults=tuple(arg_defaults),
            kwonly_names=kwonly_names,
            kwonly_defaults=kwonly_defaults,
        )

    def get_rectified_args_from_original_args(
        self, full_args: Sequence[Any], full_kwargs: dict[str, Any]
    ) -> tuple[Any]:
        """
        This function is used to rectify the original arguments to the runtime
        arguments that matched the original signature.

        :param full_args: The original full arguments to filter.
        :param full_kwargs: The original full keyword arguments to filter.
        :return: The filtered arguments and keyword arguments.
        """
        sig = self.original_signature
        try:
            bound_args = sig.bind_partial(*full_args, **full_kwargs)
            bound_args.apply_defaults()
        except Exception as e:
            raise DSLRuntimeError(
                "failed to bind arguments to function signature",
                cause=e,
            )

        # Filter out the constexpr arguments
        for i, (name, param) in enumerate(sig.parameters.items()):
            if is_arg_annotation_constexpr(param.annotation, name, i, None):
                bound_args.arguments.pop(name)
                continue

        # Once the constexpr arguments are filtered out, we need to convert the bound arguments to the signature's type.
        bound_args = inspect.BoundArguments(self.signature, bound_args.arguments)
        runtime_args = bound_args.args
        runtime_kwargs = bound_args.kwargs

        pos_count = sum(
            1
            for param in self.signature.parameters.values()
            if param.kind
            in (
                inspect.Parameter.POSITIONAL_ONLY,
                inspect.Parameter.POSITIONAL_OR_KEYWORD,
            )
        )
        kw_count = sum(
            1
            for param in self.signature.parameters.values()
            if param.kind == inspect.Parameter.KEYWORD_ONLY
        )

        if len(runtime_args) != pos_count or len(runtime_kwargs) != kw_count:
            raise DSLUserCodeError(
                DiagId.CALL_SIGNATURE_MISMATCH,
                provided=len(runtime_args),
                provided_kw=len(runtime_kwargs),
            )

        return runtime_args + tuple(runtime_kwargs.values())

    def filter_runtime_signature(self, sig: inspect.Signature) -> inspect.Signature:
        filtered_params = []
        for i, (name, param) in enumerate(sig.parameters.items()):
            if param.kind in (
                inspect.Parameter.VAR_POSITIONAL,
                inspect.Parameter.VAR_KEYWORD,
            ):
                filtered_params.append(param)
                continue

            annotation = param.annotation

            if is_arg_annotation_constexpr(annotation, name, i, None):
                continue

            filtered_params.append(param)

        return sig.replace(parameters=filtered_params)

    def get_constexpr_args(self) -> list[dict[str, Any]]:
        """
        This function returns the constexpr args that have been pruned from the original function signature.
        The return type is a list of dicts, each dict contains the argument index (argument_index) and argument name (argument_name).

        :return: list of dicts, each dict contains the argument index (argument_index) and argument name (argument_name).
        :rtype: list[dict[str, int | str | None]]
        """
        if self.original_signature is None:
            return list()

        constexpr_args = list()
        for i, (name, param) in enumerate(self.original_signature.parameters.items()):
            if name not in self.signature.parameters.keys():
                constexpr_args.append({"argument_index": i, "argument_name": name})
        return constexpr_args


class JitExecuteContext:
    """Holds device specific context for execution."""

    def __init__(
        self,
        module: "JitModule",
        kernel_fns: list[Any] | None = None,
        context: cuda_helpers.DevicePrimaryContext | None = None,
    ) -> None:
        if kernel_fns is None:
            kernel_fns = []
        self.module = module
        self.kernel_functions: list[Any] = kernel_fns
        self.kernel_functions_ptrs = [ctypes.c_void_p(k.getPtr()) for k in kernel_fns]
        self.context = context


class JitModule:
    """Holds the execution engine and cuda modules."""

    def __init__(
        self,
        engine: Any,
        capi_func: Any,
        execution_args: ExecutionArgs,
        modules: list[CudaModuleAndKernel],
    ) -> None:
        self.engine = engine
        self.capi_func = capi_func
        self.execution_args = execution_args
        self.cuda_modules = modules
        self._unloaded = False

    def get_device_execute_context(self, device: Any = None) -> JitExecuteContext:
        if self._unloaded:
            raise RuntimeError(f"Can not get executor for unloaded module.")

        # Host only code no need to setup kernels
        if not self.cuda_modules:
            return JitExecuteContext(self)

        # We need a device at this point so get one if not provided.
        if device is None:
            device = cuda_helpers.get_current_device()
        elif isinstance(device, int):
            device = cuda_helpers.get_device(device)

        # Activate a primary context for the device:
        context = cuda_helpers.DevicePrimaryContext(device)

        # Get kernel functions from the kernels
        kernel_fns = []
        for m in self.cuda_modules:
            fn = cuda_helpers.get_function_from_kernel(m.kernel)
            kernel_fns.append(fn)

            # Set attributes for the kernel function
            for attr, val in m.attrs.items():
                cuda_helpers.set_kernel_attribute(fn, attr, val)

        # This instance will "own" a reference to the primary device context.
        # It will release the the reference once its no longer alive or
        # an explicit call to unload is made.
        #
        # The default module loading mode is CU_MODULE_LAZY_LOADING so
        # the module will not be loaded to the device until the first call
        # to execute it. # This can be modified using CUDA_MODULE_LOADING
        # environment variable.
        return JitExecuteContext(self, kernel_fns, context)

    def unload(self) -> None:
        try:
            for m in set([m.cuda_module for m in self.cuda_modules]):
                cuda_helpers.unload_library(m)
            self.cuda_modules.clear()
        except Exception as e:
            pass
        finally:
            self._unloaded = True

    def __del__(self) -> None:
        self.unload()


class JitExecutor:
    """An executable function that can be called to launch a device kernel.

    JitExecutor is tired to a specific device context and should only be called
    in a context on that device.
    """

    def __init__(
        self,
        jit_module: JitModule | Any,
        exec_context: JitExecuteContext | None,
        jit_time_profiling: bool,
    ) -> None:
        # JitExecutor will keep JitCompiledFunction alive so that the underlying
        # ExecutionEngine and module data is not discarded until runtime callables
        # are garbage collected.
        self.jit_module = jit_module
        self.exec_context = exec_context
        self.profiler = timer(enable=jit_time_profiling) if jit_time_profiling else None

        # Get the cuda result type from the capi function.
        # This is only set to i32 if CudaDialectJitModule is used.
        cuda_result_type = self.jit_module.capi_func.restype
        self.cuda_result = cuda_result_type() if cuda_result_type is not None else None

        # Pre-compute flags
        self._has_cuda_result = self.cuda_result is not None
        self._has_profiler = self.profiler is not None
        self._cuda_result_addr = (
            ctypes.addressof(self.cuda_result) if self._has_cuda_result else None  # type: ignore[arg-type]
        )

        if jit_time_profiling:
            self._get_invoke_packed_args_func = self.profiler(  # type: ignore[misc]
                self._get_invoke_packed_args
            )
            self.capi_func = self.profiler(self.jit_module.capi_func)  # type: ignore[misc]
        else:
            self._get_invoke_packed_args_func = self._get_invoke_packed_args
            self.capi_func = self.jit_module.capi_func

        # Pre-compute packed args metadata
        self._num_extra_args = 0
        if self._has_cuda_result:
            self._num_extra_args += 1
        self._kernel_ptrs: list[ctypes.c_void_p] | None
        if self.exec_context is not None:
            self._kernel_ptrs = self.exec_context.kernel_functions_ptrs
            self._num_extra_args += len(self._kernel_ptrs)
        else:
            self._kernel_ptrs = None
        self._tls = threading.local()

    # Assume each execution args has type `c_void_p` to reduce the overhead of `ctypes.cast`.
    def _get_invoke_packed_args(
        self, exe_args: list[Any]
    ) -> ctypes.Array[ctypes.c_void_p]:
        # Pre-calculate sizes once during init and cache
        num_base_args = len(exe_args)
        total_args = num_base_args + self._num_extra_args

        # Re-use packed args buffer if possible
        tls = self._tls
        packed_args = getattr(tls, "packed_args", None)
        capacity = getattr(tls, "capacity", 0)

        if packed_args is None or capacity < total_args:
            packed_args = (ctypes.c_void_p * total_args)()
            tls.packed_args = packed_args
            tls.capacity = total_args

            idx = num_base_args
            if self._has_cuda_result:
                packed_args[idx] = self._cuda_result_addr
                idx += 1
            if self._kernel_ptrs is not None:
                for ptr in self._kernel_ptrs:
                    packed_args[idx] = ptr
                    idx += 1

        for i in range(num_base_args):
            arg = exe_args[i]
            packed_args[i] = (
                arg if type(arg) is ctypes.c_void_p else ctypes.c_void_p(arg).value
            )

        return packed_args

    def generate_execution_args(
        self, *args: Any, **kwargs: Any
    ) -> tuple[list[Any], list[Any]]:
        return self.jit_module.execution_args.generate_execution_args(args, kwargs)

    def run_compiled_program(self, exe_args: list[Any]) -> int | None:
        try:
            packed_args = self._get_invoke_packed_args_func(exe_args)
            self.capi_func(packed_args)
            if not self._has_cuda_result:
                return None
            error_code = self.cuda_result.value  # type: ignore[union-attr]
            if error_code == 0:
                return error_code
            raise cuda_helpers.create_cuda_runtime_error(error_code)
        except DSLCudaRuntimeError as e:
            raise e
        except Exception as e:
            raise DSLRuntimeError(f"💥💥💥 Runtime Crash 💥💥💥", cause=e)

        return None

    def __call__(self, *args: Any, **kwargs: Any) -> int | None:
        exe_args, adapted_args = self.generate_execution_args(*args, **kwargs)
        return self.run_compiled_program(exe_args)

    def prepare(self, *args: Any, **kwargs: Any) -> "PreparedLaunch":
        """Bind arguments once and return a replayable :class:`PreparedLaunch`.

        Mirrors the :meth:`JitCompiledFunction.to` / ``__call__`` split: the
        prepared launch is tied to this executor's device context. See
        :meth:`JitCompiledFunction.prepare` for the full contract.
        """
        slots = self.jit_module.execution_args.generate_prepared_slots(args, kwargs)
        return PreparedLaunch(self, slots)


class PreparedLaunch:
    """A compiled function with its launch arguments bound to stable storage.

    Created by :meth:`JitCompiledFunction.prepare` (or
    :meth:`JitExecutor.prepare` for a device-bound executor). ``prepare()``
    runs the normal argument marshalling once and snapshots the marshalled
    bytes into private per-argument storage referenced by a private packed
    argument array; :meth:`launch` then only rewrites those bytes in place and
    invokes the compiled entry point directly. No Python objects are allocated
    per launch and no packing is repeated, which removes nearly all of the
    per-call host overhead of ``compiled(*args)``.

    A launch is bitwise-identical to calling the compiled function with the
    same argument values of the prepared kinds: the compiled entry point reads
    the same packed bytes either way. (A direct call additionally applies DSL
    numeric casts to scalar values of a mismatched kind; a prepared launch
    rejects such values with :class:`PreparedLaunchError` instead of silently
    converting.)

    **Lifecycle.** The instance keeps its executor — and therefore the JIT
    engine, loaded CUDA modules, and device context — alive. Launching after
    the owning module has been explicitly unloaded raises
    :class:`PreparedLaunchError`.

    **Threads.** Instances are not thread-safe: two threads launching through
    one instance would interleave writes to the same argument storage. Create
    one prepared launch per thread; instances never share mutable argument or
    result storage (each owns its slots, packed array, and CUDA result slot),
    so different instances of the same compiled function may launch
    concurrently. The compiled module and entry point are shared and
    read-only in normal operation; ``jit_module.unload()`` affects every
    instance of that module.

    **CUDA graphs.** :meth:`launch` issues the same driver launch as the
    normal call path, so it can be captured into a CUDA graph via a capturing
    stream. Standard capture semantics apply: the driver copies the argument
    bytes at capture time, so later ``launch`` argument updates do not change
    what a captured graph replays. A launch that is illegal during capture
    (e.g. onto the legacy default stream) raises the same CUDA error the
    normal call path would.
    """

    def __init__(self, executor: JitExecutor, slots: list[_PreparedArgSlot]) -> None:
        packed_args = (ctypes.c_void_p * (len(slots) + executor._num_extra_args))()
        for index, slot in enumerate(slots):
            packed_args[index] = slot.address

        # Private CUDA result storage: launches from this instance never race
        # the executor's shared result slot (or another instance's).
        index = len(slots)
        cuda_result = (
            type(executor.cuda_result)() if executor._has_cuda_result else None
        )
        if cuda_result is not None:
            packed_args[index] = ctypes.addressof(cuda_result)
            index += 1
        if executor._kernel_ptrs is not None:
            for ptr in executor._kernel_ptrs:
                packed_args[index] = ptr
                index += 1

        self._executor = executor
        self._jit_module = executor.jit_module
        self._slots = slots
        self._writers = [slot.write for slot in slots]
        self._packed_args = packed_args
        self._cuda_result = cuda_result
        self._capi_func = executor.capi_func

    def launch(self, *args: Any, **kwargs: Any) -> int | None:
        """Rewrite the bound argument storage in place and launch.

        Takes the same runtime arguments as calling the compiled function
        (keyword arguments and omitted defaulted parameters rectify through
        the signature; full positional calls are the fast path). Pointer
        arguments accept a runtime pointer object or a raw integer address;
        numeric arguments accept a Python scalar or a ``Numeric`` instance;
        stream arguments accept a CUDA stream object, a framework stream
        exposing an integer ``cuda_stream`` attribute (e.g.
        ``torch.cuda.Stream``), or a raw integer handle. Scalar values are
        written through the prepared ctypes storage with plain ctypes
        assignment semantics: out-of-range integers truncate to the declared
        width (the same trust-the-caller posture as the normal launch path),
        and a value the storage rejects — e.g. a float for an integer slot —
        raises :class:`PreparedLaunchError` instead of applying the implicit
        DSL cast a direct call would perform.

        :return: The CUDA result code (0) when the compiled function reports
            one, otherwise None — the same contract as calling the compiled
            function.
        :raises PreparedLaunchError: If the argument count does not match the
            prepared signature, a value's type cannot update its slot, or the
            compiled module has been unloaded.
        :raises DSLCudaRuntimeError: If the launch reports a CUDA error.
        """
        writers = self._writers
        if kwargs or len(args) != len(writers):
            # Same binding contract as a direct call: keyword arguments and
            # omitted defaulted parameters rectify through the signature,
            # raising the shared too-many/missing-argument diagnostics.
            args = tuple(
                self._jit_module.execution_args.get_rectified_args(args, kwargs)
            )
            if len(args) != len(writers):
                raise PreparedLaunchError(
                    DiagId.LAUNCH_PREPARED_ARG_COUNT,
                    expected=len(writers),
                    provided=len(args),
                )
        if self._jit_module._unloaded:
            raise PreparedLaunchError(DiagId.LAUNCH_PREPARED_MODULE_UNLOADED)
        index = 0
        try:
            for index, value in enumerate(args):
                writers[index](value)
        except (TypeError, ValueError) as e:
            raise PreparedLaunchError(
                DiagId.LAUNCH_PREPARED_BAD_VALUE,
                arg_name=self._slots[index].name,
                value_type=type(args[index]).__name__,
                cause=e,
            )
        self._capi_func(self._packed_args)
        if self._cuda_result is None:
            return None
        error_code = self._cuda_result.value
        if error_code == 0:
            return error_code
        raise cuda_helpers.create_cuda_runtime_error(error_code)


@dataclass
class JitFunctionArtifacts:
    """Holds artifacts for a JIT-compiled function."""

    PTX: str | None
    CUBIN: str | bytes | None
    SASS: str | None
    MLIR: str | None
    # Device compilation artifacts (set when DeviceTarget is enabled)
    device_header: str | None = None
    device_object_path: str | None = None

    def __post_init__(self) -> None:
        if self.PTX is not None and os.path.exists(self.PTX):
            try:
                with open(self.PTX, "r") as f:
                    self.PTX = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read PTX file '{self.PTX}': {e}")
        if self.CUBIN is not None and os.path.exists(self.CUBIN):
            try:
                with open(self.CUBIN, "rb") as f:
                    self.CUBIN = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read CUBIN file {self.CUBIN!r}: {e}")
        if self.SASS is not None and os.path.exists(self.SASS):
            try:
                with open(self.SASS, "r") as f:
                    self.SASS = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read SASS file '{self.SASS}': {e}")
        if self.MLIR is not None and os.path.exists(self.MLIR):
            try:
                with open(self.MLIR, "r") as f:
                    self.MLIR = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read MLIR file '{self.MLIR}': {e}")


@dataclass
class ExportProvider:
    """Holds the dsl specific settings for the export of the jit-compiled function."""

    dsl: "type[BaseDSL]"
    signature_processor: "SignatureProcessor"
    c_header_generator: "CHeaderGenerator"
    object_file_version: str
    mlirExecutionEngine: Any


class AuxRuntimeFunc(abc.ABC):
    """Abstract base class for auxiliary runtime host functions compiled by the DSL.

    Subclasses declare a ``name`` class attribute matching the host-function
    symbol suffix (e.g. ``"queryDeviceWorkspace"``) and implement ``__call__``
    with the user-facing argument signature.

    Instances are created by :meth:`JitCompiledFunction.get_aux_func`.
    """

    name: ClassVar[str]  # subclasses must set this

    def __init__(self, func_ptr: int, execution_args: ExecutionArgs) -> None:
        """Declare the constructor contract for :meth:`JitCompiledFunction.get_aux_func`.

        Subclasses replace this with an implementation; they are not required to
        call ``super().__init__``.
        """


class JitCompiledFunction:
    """Holds a compiled function."""

    export_provider: ExportProvider | None = None

    def __init__(
        self,
        ir_module: ir.Module,
        engine: Any,
        capi_func: Any,
        signature: inspect.Signature | None,
        function_name: str,
        kernel_info: dict[str, Any] | None,
        jit_time_profiling: bool,
        jit_function_artifacts: JitFunctionArtifacts | None,
        prefix: str | None = None,
        load_from_binary: bool = False,
        dynamic_args: tuple[Any] = tuple[Any](),
        dynamic_kwargs: dict[str, Any] = dict[str, Any](),
        has_gpu_module: bool = True,
        host_target: "HostTarget | None" = None,
    ) -> None:
        self.ir_module = ir_module
        self.engine = engine
        self.capi_func = capi_func
        self.function_name = function_name
        self.kernel_info = kernel_info if kernel_info is not None else dict[str, Any]()
        if signature is not None:
            # Enable thorough per-launch argument validation when debugging mode
            # is ON. Read it from the DSL's env manager so the launch path reads
            # a single stored boolean instead of the env on every call; when
            # export_provider is unset, validation stays off.
            full_arg_check = False
            if self.export_provider is not None:
                full_arg_check = self.export_provider.dsl._get_dsl().envar.debug
            self.execution_args = ExecutionArgs(
                signature, self.function_name, full_arg_check=full_arg_check
            )
            self.execution_args.record_pointer_arg_specs_from_compile_args(
                tuple(dynamic_args or ()), dynamic_kwargs or {}
            )
        self.jit_time_profiling = jit_time_profiling

        assert (
            isinstance(jit_function_artifacts, JitFunctionArtifacts)
            or jit_function_artifacts is None
        )
        self.artifacts = jit_function_artifacts
        self.prefix = prefix
        self.load_from_binary = load_from_binary

        # AOT cross-compile target for the host shim object. ``None`` or
        # an empty HostTarget = native build host (preserves prior behavior).
        # Lazy import: .compiler imports .env_manager which transitively
        # imports this module, so a top-level import would close the cycle.
        if host_target is None:
            from .compiler import HostTarget as _HostTarget

            host_target = _HostTarget("")
        self.host_target: "HostTarget" = host_target

        # This runtime state is stored here so that we can preserve the module
        # in the compiler cache. Callers can extend the lifetime of the module
        # by creating and retaining the executor.
        self.jit_module: JitModule | None = None
        self._executor_lock = threading.RLock()
        self._default_executor: JitExecutor | None = None

        # This is used to do early generation of the c header arguments to release the reference to the dynamic arguments.
        self._generate_c_header_arguments(dynamic_args, dynamic_kwargs)

        self.has_gpu_module = has_gpu_module

    @property
    def __ptx__(self) -> str | None:
        """Returns the PTX code of the JIT-compiled function."""
        return self.artifacts.PTX if self.artifacts is not None else None

    @property
    def __cubin__(self) -> str | bytes | None:
        """Returns the CUBIN data of the JIT-compiled function."""
        return self.artifacts.CUBIN if self.artifacts is not None else None

    @property
    def __sass__(self) -> str | None:
        """Returns the SASS code of the JIT-compiled function."""
        return self.artifacts.SASS if self.artifacts is not None else None

    @property
    def __mlir__(self) -> str | None:
        """Returns the MLIR code of the JIT-compiled function."""
        return self.artifacts.MLIR if self.artifacts is not None else None

    def _deserializer(self) -> list[CudaModuleAndKernel]:
        """Load the cuda module from the binary execution engine. This function will be injected as the
        JitCompiledFunction method which will be called by the jit executor to load the cuda module by AOT flow.
        @param self: The JitCompiledFunction object. This is the JitCompiledFunction object to load the cuda module.
        @param name: The name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
        @param execution_engine: The binary execution engine. This is the execution engine to load the cuda module.
        @param kernel_info: The kernel info. This is the kernel info to load the cuda module.
        @return: The list of cuda modules.
        """
        cubin_suffix = "cubin"
        if self.prefix is None:
            raise DSLRuntimeError("prefix is required to be set for binary loading")
        cubin_data = self.engine.lookup("_".join([self.prefix, cubin_suffix]))
        if not cubin_data:
            raise RuntimeError(
                "Unknown function " + "_".join([self.prefix, cubin_suffix])
            )
        cubin_module = cuda_helpers.load_library_data(cubin_data)
        # load cuda module/get function pointer from module and cache
        kernel_modules: collections.OrderedDict[str, CudaModuleAndKernel] = (
            collections.OrderedDict()
        )
        assert self.kernel_info is not None
        for sym, attrs in self.kernel_info.items():
            kernel = cuda_helpers.get_library_kernel(cubin_module, sym)
            if cuda_helpers.get_driver_version() >= 11080:
                attrs[
                    cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED
                ] = 1
            kernel_modules[sym] = CudaModuleAndKernel(sym, cubin_module, kernel, attrs)
        return list(kernel_modules.values())

    def _validate_engine(self) -> None:
        if self.engine is None:
            raise DSLRuntimeError(
                "The compiled function does not have a valid execution engine.",
                suggestion="For cross-compilation, please use `JitCompiledFunction.export_to_c` to serialize the compiled function and load/execute it on target device.",
            )

    def to(self, device: Any = None) -> JitExecutor:
        """Returns an executable function bound to the given device.

        For multi-device execution this method can be called for each device where
        the kernel will run.

        :param device: Specifies the device for the executor. If None the current device is used.
        :type device: Optional[Union[int, CUdevice]]
        :return: A callable executor function.
        :rtype: JitExecutor
        """
        self._validate_engine()
        with self._executor_lock:
            # We need to ensure that the modules are loaded if not already
            if self.jit_module is None:
                if self.ir_module is not None:
                    cuda_modules = load_kernels_from_ir_module(
                        self.ir_module, self.kernel_info
                    )
                self.jit_module = JitModule(
                    self.engine, self.capi_func, self.execution_args, cuda_modules
                )

            # Create a new executor that will be tied to a device context
            # n.b. host only modules do not load device specific modules or context.
            context = self.jit_module.get_device_execute_context(device)
            return JitExecutor(self.jit_module, context, self.jit_time_profiling)

    def generate_execution_args(
        self, *args: Any, **kwargs: Any
    ) -> tuple[list[Any], list[Any]]:
        return self.execution_args.generate_execution_args(args, kwargs)

    def get_aux_func(
        self, func_class: type[AuxRuntimeFunc], kernel: Callable[..., Any]
    ) -> AuxRuntimeFunc:
        """Look up and return an auxiliary runtime function for a specific kernel.

        ``kernel`` must be a ``@dsl_name.kernel``-annotated callable that was called
        inside the ``@dsl_name.jit`` function that produced this compiled object.
        The lookup resolves the symbol ``{kernel_name}_{func_class.name}`` for
        that specific kernel.

        :param func_class: A subclass of :class:`AuxRuntimeFunc` whose
            ``name`` class attribute identifies the host function suffix.
        :param kernel: A ``@dsl_name.kernel``-annotated callable.  Must have been
            called at least once inside a ``@dsl_name.jit`` function so that
            ``_dsl_kernel_name`` is set.
        :return: An instance of ``func_class`` initialised with the matched
            function pointer and ready to call.
        :raises TypeError: If ``func_class`` is not a subclass of
            :class:`AuxRuntimeFunc`.
        :raises ValueError: If ``kernel`` has no ``_dsl_kernel_name`` attribute.
        :raises DSLRuntimeError: If no matching symbol is found in the JIT engine.
        """
        if not (
            isinstance(func_class, type) and issubclass(func_class, AuxRuntimeFunc)
        ):
            raise TypeError(
                f"func_class must be a subclass of AuxRuntimeFunc, got {func_class!r}"
            )

        # Unwrap bound methods then @wraps wrappers to reach the original funcBody.
        func_body = getattr(kernel, "__func__", kernel)  # bound method → function
        func_body = getattr(func_body, "__wrapped__", func_body)  # jit_wrapper → func
        kernel_name = getattr(func_body, "_dsl_kernel_name", None)
        if kernel_name is None:
            raise ValueError(
                f"kernel {kernel!r} has no '_dsl_kernel_name' attribute. "
                "Make sure it has been called at least once inside a @cute.jit function."
            )

        self._validate_engine()

        sym_name = func_class.name
        candidate = f"{kernel_name}_{sym_name}"
        candidates = [candidate]
        if self.prefix is not None:
            candidates = [f"_mlir_{self.prefix}_{candidate}"] + candidates

        fn_ptr = None
        for c in candidates:
            fn_ptr = self.engine.raw_lookup(c)
            if fn_ptr:
                break

        if not fn_ptr:
            raise DSLRuntimeError(
                f"Host function '{sym_name}' not found in JIT engine. "
                f"Tried: {candidates}"
            )
        return func_class(fn_ptr, self.execution_args)

    def __call__(self, *args: Any, **kwargs: Any) -> int | None:
        """Executes the jit-compiled function under the currently active CUDA context.

        Calling this method multiple devices is not allowed and will result in unexpected
        CUDA errors. If you need to call the kernel on multiple devices use `to`
        to return a per-device function.
        """
        exe_args, adapted_args = self.execution_args.generate_execution_args(
            args, kwargs
        )
        executor = self._default_executor
        if executor is not None:  # Only lock on first call
            return executor.run_compiled_program(exe_args)
        return self.run_compiled_program(exe_args)

    def prepare(self, *args: Any, **kwargs: Any) -> "PreparedLaunch":
        """Bind arguments once and return a replayable :class:`PreparedLaunch`.

        Calling a compiled function re-marshals every argument: argument
        objects are rebuilt, scalars are cast into fresh ctypes storage, and
        the packed argument array is regenerated, even when only pointer
        addresses and scalar values change between calls. For launch-bound
        callers this method performs that work exactly once:
        ``prepare(*args)`` validates and marshals the arguments like a normal
        call, then snapshots the marshalled bytes into storage owned by the
        returned :class:`PreparedLaunch`, whose :meth:`PreparedLaunch.launch`
        rewrites the bytes in place and invokes the compiled entry point
        directly.

        .. code-block:: python

            compiled = cute.compile(fn, out_ptr, in_ptr, alpha, n, stream)
            prepared = compiled.prepare(out_ptr, in_ptr, alpha, n, stream)
            for step in range(steps):
                ...
                prepared.launch(out_ptr, in_ptr, alpha, n, stream)

        Eligibility is validated here, not at launch: every runtime argument
        must be a runtime pointer (``make_ptr``/pointer-address slot), a
        numeric scalar with plain ctypes storage (Boolean, Int8-Int64,
        Uint8-Uint64, Float32, Float64, TFloat32, or a plain Python
        bool/int/float), or a CUDA stream. Anything else — dlpack tensors,
        structs, sequences, custom JIT arguments — raises
        :class:`PreparedLaunchError`, and ``compiled(*args)`` remains the
        general path.

        Like ``__call__``, the prepared launch is bound to the default
        executor's device context; use ``to(device).prepare(...)`` for
        per-device prepared launches. See :class:`PreparedLaunch` for the
        lifecycle, threading, and CUDA-graph-capture contract.

        :param args: Runtime arguments, as passed to a normal call.
        :param kwargs: Runtime keyword arguments, as passed to a normal call.
        :return: A prepared launch bound to this function and device context.
        :rtype: PreparedLaunch
        :raises PreparedLaunchError: If any runtime argument is not eligible
            for in-place re-binding.
        """
        executor = self._ensure_default_executor()
        if not isinstance(executor, JitExecutor):
            # e.g. TVM-FFI compiled functions: their to() returns the compiled
            # function itself, which dispatches through its own entry point.
            raise PreparedLaunchError(
                DiagId.LAUNCH_PREPARE_UNSUPPORTED_EXECUTOR,
                function_kind=type(self).__name__,
            )
        return executor.prepare(*args, **kwargs)

    def _ensure_default_executor(self) -> JitExecutor:
        with self._executor_lock:
            if self._default_executor is None:
                log().debug("Creating default executor.")
                # We use a weak reference here so that this instance does not keep this
                # object alive as it hold a reference to self.
                proxy_self = weakref.proxy(self)
                self._default_executor = proxy_self.to(None)
        assert self._default_executor is not None
        return self._default_executor

    def run_compiled_program(self, exe_args: list[Any]) -> int | None:
        """Executes the jit-compiled function under the currently active CUDA context.

        Calling this method multiple devices is not allowed and will result in unexpected
        CUDA errors. If you need to call the kernel on multiple devices use `to`
        to return a per-device function.
        """
        return self._ensure_default_executor().run_compiled_program(exe_args)

    def _generate_c_header_arguments(
        self,
        dynamic_args: tuple[Any],
        dynamic_kwargs: dict[str, Any],
    ) -> None:
        """Generates the c header arguments for the AOT C header generation."""
        self.c_header_arguments = None
        from .export import CHeaderArguments

        if dynamic_args or dynamic_kwargs:
            self.dummy_prefix_name = "dummy_prefix_name"
            try:
                # This arguments may be generated failure due to not all the arguments (e.g. custom types) are supported by the AOT C header generator.
                assert self.export_provider is not None
                assert self.export_provider.c_header_generator is not None
                c_header_arguments, packed_args, declarations = (
                    self.export_provider.c_header_generator._generate_arguments(
                        self.dummy_prefix_name,
                        self.execution_args,
                        dynamic_args,
                        dynamic_kwargs,
                    )
                )
                self.c_header_arguments = CHeaderArguments(
                    self.dummy_prefix_name,
                    c_header_arguments,
                    packed_args,
                    declarations,
                    None,
                )
            except Exception as e:
                self.c_header_arguments = CHeaderArguments(
                    self.dummy_prefix_name,
                    [],
                    [],
                    [],
                    str(e),
                )

    def dump_to_object(
        self,
        function_prefix: str,
    ) -> bytes:
        """Dump the compiled ir function to a bytes object with ELF format. The bytes object contains the host
        launch entry function and cubin inside.

        @param function_prefix: The prefix name of the function. This is the user provided unique identifier name of the function to avoid symbol conflict in the generated object file.
        @return: The bytes object of the function.
        """
        # lazy import to avoid circular dependency
        from .export import get_export_module, encode_metadata_into_ir_module

        assert self.export_provider is not None, (
            "Export provider is not set for JitCompiledFunction."
        )
        export_module = get_export_module(self.ir_module, function_prefix)
        export_module = encode_metadata_into_ir_module(
            function_prefix,
            export_module,
            self.execution_args.signature,
            self.function_name,
            self.kernel_info,
            self.export_provider.signature_processor,
            self.export_provider.object_file_version,
        )

        cubin_data = None

        def strip_gpu_binary_op(op: ir.Operation) -> ir.WalkResult:
            if op.name == "gpu.binary":
                s = io.BytesIO()
                op.operation.write_bytecode(s)
                nonlocal cubin_data
                cubin_data = s.getvalue()
                cubin_data = cubin_data.split(b'bin = "')[1].split(b'">')[0]
                cubin_data = get_escaped_cubin_bytes(cubin_data)
                op.erase()
                return ir.WalkResult.ADVANCE
            return ir.WalkResult.ADVANCE

        # Strip gpu related to avoid the object file generating builtin module load/unload functions
        export_module.operation.walk(strip_gpu_binary_op)
        cubin_suffix = "cubin"
        if cubin_data is not None:
            cubin_array = array.array("b", cubin_data)
            with (
                export_module.context,
                ir.Location.unknown(),
                ir.InsertionPoint(export_module.body),
            ):
                new_binary_global_op = llvm.GlobalOp(
                    sym_name="_".join([function_prefix, cubin_suffix]),
                    global_type=ir.Type.parse(f"!llvm.array<{len(cubin_array)} x i8>"),
                    linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                    value=ir.DenseIntElementsAttr.get(cubin_array),
                    constant=True,
                )

        if "gpu.container_module" in export_module.operation.attributes:
            del export_module.operation.attributes["gpu.container_module"]
        # Generate the object file

        try:
            with tempfile.NamedTemporaryFile() as tmp_object_file:
                self.export_provider.mlirExecutionEngine.dump_object_file_pic(
                    export_module,
                    tmp_object_file.name,
                    "_".join([function_prefix, self.function_name]),
                    host_triple=self.host_target.triple,
                    host_cpu=self.host_target.cpu,
                    host_features=self.host_target.features,
                )
                with open(tmp_object_file.name, "rb") as f:
                    ret = f.read()
                return ret
        except Exception as e:
            raise DSLRuntimeError(f"Error dumping object file: {e}") from e

    def export_to_c(
        self,
        file_path: str,
        file_name: str,
        function_prefix: str = "",
    ) -> None:
        """Exports the jit-compiled function to a C compatible files(header/library).
        This is used for c/cpp AOT support.
        The `file_path` will be used as the directory to save the header and object files.
        The `file_name` will be used as the name of the header and object files. The same file name will always overwrite the existing file.
        The `function_prefix` will be used as the symbol prefix of the generated functions, it is guaranteed by
        the caller that the generated functions are unique.


        The c header file is generated with following components:
        1. The host launch entry function. And the structure definitions of the arguments.
        2. The device metadata load/unload functions.
        3. The cubin data array and len.

        The library contains the binary of the underlying host launch entry function.

        Host cross-compilation:
            The host CPU/OS that the emitted ``.o`` targets is set at
            compile time via the options string passed to ``cute.compile``,
            not via this method. To emit a cross-targeted host shim
            (currently AArch64 only)::

                compiled = cute.compile(
                    fn, *args,
                    options="--gpu-arch sm_100a --host-target linux-aarch64",
                )
                compiled.export_to_c(out_dir, "kernel")

            The resulting ``kernel.o`` is an ELF object for the requested
            AArch64 triple. Linking is the user's responsibility — invoke
            their cross linker against a sysroot containing ``<cuda.h>``
            and a target-built ``libcuda_dialect_runtime``. See
            ``python -m cutlass.cute.export.aot_config --target ...`` for
            ``-L`` / ``-l`` flag discovery. Non-AArch64 triples are not
            supported and fail with a clean "target not registered" error.

        @param jit_function: The jit-compiled function from `cute.compile`.
        @param file_path: The path to the directory where the header and object files will be saved.
        @param file_name: The name of the header and object files.
        @param function_prefix: The prefix of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file. Default to the `file_name`.
        """
        if function_prefix is None or function_prefix == "":
            function_prefix = file_name

        assert self.export_provider is not None, (
            "Export provider is not set for JitCompiledFunction."
        )
        # lazy import to avoid circular dependency
        from .export import get_export_module

        export_module = get_export_module(self.ir_module, function_prefix)
        # Generate the c header file
        assert self.export_provider.c_header_generator is not None
        assert self.export_provider.dsl is not None
        header_file_content = self.export_provider.c_header_generator(
            function_prefix,
            export_module,
            self.execution_args,
            self.function_name,
            self.kernel_info,
            self.c_header_arguments,  # type: ignore[arg-type]
            self.export_provider.dsl._get_dsl().name,
        )
        try:
            with open(os.path.join(file_path, file_name + ".h"), "w") as f:
                f.write(header_file_content)
        except Exception as e:
            raise DSLRuntimeError(f"Error writing header file: {e}") from e

        # Generate the object file
        object_file_content = self.dump_to_object(function_prefix)
        try:
            with open(os.path.join(file_path, file_name + ".o"), "wb") as f:
                f.write(object_file_content)
        except Exception as e:
            raise DSLRuntimeError(f"Error writing object file: {e}") from e
