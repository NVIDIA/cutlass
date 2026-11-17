# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Turn loaded CUTLASS functions into ordinary Python callables.

``CallableFunction`` is the recommended high-level wrapper for an
:class:`~cutlass.compiler.ExecutableFunction`.  It derives a Python signature
from the function metadata, packs arguments for the selected ABI, invokes the
compiled function, and decodes scalar results. Prefer TVM-FFI when it supports
the required interface. CutlassCall support uses a private, unstable
implementation ABI with no compatibility guarantee.
"""

from __future__ import annotations

import ctypes
import inspect
import operator
from collections.abc import Iterator, Sequence
from dataclasses import fields, is_dataclass
from typing import Any, SupportsIndex, cast

from ..base_dsl.common import DSLUserCodeError
from ..base_dsl.diagnostics import DiagId
from ..base_dsl.runtime.jit_arg_adapters import JitArgAdapterRegistry
from ..base_dsl.typing import implements_jit_argument

from cutlass.compiler import (
    Abi,
    Binding,
    Const,
    DTypeCode,
    EnvStream,
    ExecutableFunction,
    CustomType,
    Pointer,
    Shape,
    Stream,
    SymbolId,
    Tensor,
    Tuple,
    Unit,
    Var,
)

__all__ = ["CallableFunction"]

"""
This module contains Pythonic wrappers for functions compiled by a
cutlass.Compiler() instance. These classes are used by the implementation
and should not be used directly by the user.
"""


# ---------------------------------------------------------------------------
# DLPack capsule access (TvmFfi Tensor slot)
# ---------------------------------------------------------------------------
_PyCapsule_IsValid = ctypes.pythonapi.PyCapsule_IsValid
_PyCapsule_IsValid.restype = ctypes.c_int
_PyCapsule_IsValid.argtypes = [ctypes.py_object, ctypes.c_char_p]
_PyCapsule_GetPointer = ctypes.pythonapi.PyCapsule_GetPointer
_PyCapsule_GetPointer.restype = ctypes.c_void_p
_PyCapsule_GetPointer.argtypes = [ctypes.py_object, ctypes.c_char_p]


# ---------------------------------------------------------------------------
# Per-slot packing helpers. Each returns (slot_address, keepalive); the
# keepalive must outlive the call so its backing storage is not freed out from
# under the kernel.
# ---------------------------------------------------------------------------


def _pack_tensor_cutlass_call(value: Any) -> tuple[Any, Any]:
    """CutlassCall Tensor slot: reuse the cute.Tensor's own MemRef descriptor.

    What the kernel reads: ``_mlir_ciface_<sym>`` takes each tensor as a
    ``!cute.memref`` argument, which CuteToNVVM lowers to the cute-flat LLVM
    struct::

        { void* data;  <i32|i64> dyn_shapes[N];  <i32|i64> dyn_strides[M]; }

    Only the dynamic dims appear (N / M skip static dims, baked into the kernel),
    each field at its symbol's width (32- or 64-bit). The ``cutlass_call_<sym>``
    wrapper does not define a layout of its own -- it just loads the caller's
    slot as that ciface argument type and forwards it.

    What the cute.Tensor produces: ``__c_pointers__()`` builds, once and caches
    (``_c_pointers_cache``), a ``cute::abi::MemRef`` buffer with that same
    ``{data, dynamic shapes, dynamic strides}`` layout, via the host builder
    ``cute::abi::MemRef::build``.

    The host builder and the device ``!cute.memref`` lowering are generated from
    the *same* layout definition, so the two are byte-identical by construction. We
    therefore hand the kernel the cute.Tensor's descriptor directly -- no
    separate Python builder, no rebuild, no chance of the two drifting apart.

    Returns ``(address, keepalive)``; the keepalive is the tensor (or its
    adapter), which owns the descriptor buffer (freed when its
    capsule is collected).
    """

    # A raw DLPack producer (e.g. a torch.Tensor) has no __c_pointers__.
    # Fall back to JitArgAdapterRegistry.
    if not hasattr(value, "__c_pointers__"):
        adapter = JitArgAdapterRegistry.get_registered_adapter(value)
        if adapter is None:
            raise TypeError(
                "CutlassCall expects a cute.Tensor argument (exposing "
                f"__c_pointers__); got {type(value).__name__}. Wrap it with "
                "cutlass.cute.runtime.from_dlpack(...) first."
            )
        value = adapter(value)

    # pointers[0] is the address of that cute::abi::MemRef buffer -- exactly the
    # <sym>_param_i_t the kernel's CutlassCall slot expects.
    pointers = value.__c_pointers__()
    return pointers[0], value


def _pack_tensor_tvm_ffi(value: Any) -> tuple[Any, Any]:
    """TvmFfi Tensor slot: a borrowed ``DLTensor*`` from the producer's DLPack
    capsule (keepalive = the capsule, so its deleter doesn't run early).

    Pass ``stream=-1`` (no sync) on CUDA; DLPack requires ``stream=None`` on CPU,
    so pick it from ``__dlpack_device__()``. Fall back to a bare ``__dlpack__()``
    for producers without a ``stream`` kwarg.

    ``value`` is either a raw DLPack producer (e.g. a ``torch.Tensor``,
    already exposing ``__dlpack__`` directly) or a ``cute.Tensor`` built via
    ``from_dlpack(..., enable_tvm_ffi=True)``
    """
    if hasattr(value, "_tvm_ffi_tensor"):
        value = value._tvm_ffi_tensor
    elif not hasattr(value, "__dlpack__"):
        raise TypeError(
            "TvmFfi expects a DLPack producer (e.g. a torch.Tensor exposing "
            f"__dlpack__); got {type(value).__name__}. A cute.Tensor has no "
            "__dlpack__; pass the original DLPack producer, such as the torch "
            "tensor it was built from, or wrap it with "
            "cutlass.cute.runtime.from_dlpack(..., enable_tvm_ffi=True) first."
        )

    # device type 1 == kDLCPU (needs stream=None); tolerate a producer lacking
    # __dlpack_device__, but let a real error from it surface.
    stream: int | None = -1
    try:
        if value.__dlpack_device__()[0] == 1:
            stream = None
    except AttributeError:
        pass
    try:
        capsule = value.__dlpack__(stream=stream)
    except TypeError:
        capsule = value.__dlpack__()
    if not _PyCapsule_IsValid(capsule, b"dltensor"):
        raise TypeError(
            f"{type(value).__name__}.__dlpack__() returned a capsule whose name "
            "is not 'dltensor' (versioned DLPack capsules unsupported)"
        )
    pointer = _PyCapsule_GetPointer(capsule, b"dltensor")
    return pointer, capsule


def _pack_scalar(binding: Var | Const, value: Any) -> tuple[Any, Any]:
    # Const shares Var's ptr-to-scalar wire: the caller still supplies the
    # value (TvmFfi validates it equals the pinned literal, CutlassCall drops
    # it unchecked), so both pack identically from the binding's dtype.

    # A scalar-shaped opaque handle (DType.handle(), e.g. a CUDA event or a
    # native_struct) has no ctypes equivalent, so it packs like a Pointer
    # binding instead.
    if binding.dtype.code == DTypeCode.Handle:
        return _pack_pointer(value)

    from cutlass import Numeric

    if isinstance(value, Numeric):
        from cutlass.base_dsl.typing import TFloat32

        # For certain type combinations, there are not appropriate dtypes
        # which can simply create a value from the given value.
        # For those, we fall back to using __c_pointers__() to get the value.
        #
        # 16 bit floats: no underlying dtype exists.
        # TF32: LLVM uses i32 to store the bits.

        dtype = binding.dtype
        requires_c_pointers = (
            dtype.code == DTypeCode.BFloat
            or (dtype.code == DTypeCode.Float and dtype.bits == 16)
            or isinstance(value, TFloat32)
        )
        if requires_c_pointers:
            pointers = value.__c_pointers__()
            return pointers[0].value, pointers
        value = value.value
    buf = binding.dtype.get_ctype()(value)
    return ctypes.addressof(buf), buf


def _pack_pointer(value: Any) -> tuple[Any, Any]:
    # int() handles int / cuda.CUstream; a cute.Pointer (make_ptr) isn't int()-able,
    # so take the device address it wraps (._pointer).
    import cutlass.cute as cute

    if value is None:
        addr = 0
    elif isinstance(value, cute.Pointer):
        addr = value._pointer  # type: ignore[attr-defined]
    else:
        addr = int(value)
    buf = ctypes.c_void_p(addr)
    return ctypes.addressof(buf), buf


_INT64_MIN = -(1 << 63)
_INT64_MAX = (1 << 63) - 1


def _shape_leaf_as_int64(value: object, *, path: str) -> int:
    """Convert one logical Shape leaf without accepting lossy coercions."""
    from cutlass import Boolean, Integer

    # A CUTLASS Integer is the DSL spelling of an integer runtime value. Unwrap
    # it before invoking the Python integer protocol: Numeric.__index__ is also
    # present on floating-point DSL values, so accepting Numeric generically
    # would make the type check depend on its payload rather than its dtype.
    if isinstance(value, (bool, Boolean)):
        raise TypeError(
            f"shape leaf {path} expects an integer, got {type(value).__name__}"
        )
    if isinstance(value, Integer):
        value = value.value
    if not isinstance(value, SupportsIndex):
        raise TypeError(
            f"shape leaf {path} expects an integer, got {type(value).__name__}"
        )
    try:
        result = operator.index(value)
    except TypeError as exc:
        raise TypeError(
            f"shape leaf {path} expects an integer, got {type(value).__name__}"
        ) from exc
    if result < _INT64_MIN or result > _INT64_MAX:
        raise OverflowError(
            f"shape leaf {path} value {result} is outside the signed int64 range"
        )
    return result


def _pointer_address(value: object) -> int:
    """Return an address from the two forms produced by the JIT adapter."""
    if isinstance(value, int):
        return value
    if isinstance(value, ctypes.c_void_p):
        return value.value or 0
    raise TypeError(
        "expected a packed address as int or ctypes.c_void_p, "
        f"got {type(value).__name__}"
    )


def _flatten_shape_value(binding: Shape, value: object) -> list[int]:
    """Validate ``value`` against ``binding``'s tree and return ABI leaves."""

    def visit(nodes: Sequence[object], current: object, path: str) -> list[int]:
        if not isinstance(current, (tuple, list)):
            raise TypeError(
                f"shape param {binding.name!r} expects a tuple/list at {path}, "
                f"got {type(current).__name__}"
            )
        if len(current) != len(nodes):
            raise ValueError(
                f"shape param {binding.name!r} expects {len(nodes)} element(s) "
                f"at {path}, got {len(current)}"
            )

        leaves: list[int] = []
        for index, (node, element) in enumerate(zip(nodes, current)):
            element_path = f"{path}[{index}]"
            if not isinstance(node, tuple):
                if isinstance(element, (tuple, list)):
                    raise TypeError(
                        f"shape param {binding.name!r} expects an integer leaf "
                        f"at {element_path}, got {type(element).__name__}"
                    )
                leaves.append(_shape_leaf_as_int64(element, path=element_path))
            else:
                leaves.extend(visit(node, element, element_path))
        return leaves

    return visit(binding.dims, value, binding.name)


def _pack_shape(binding: Shape, value: object) -> tuple[Any, Any]:
    """Pack a Shape tree as ``int64_t[leaf_count]`` in DFS leaf order.

    The metadata retains the nested profile so the direct Python call can
    reject a mismatched hierarchy. The ABI intentionally remains flat: constant
    leaves are included, while wrappers forward dynamic leaves according to the
    Shape's per-leaf forwarding map.
    """
    dims = _flatten_shape_value(binding, value)
    buf = (ctypes.c_int64 * len(dims))(*dims)
    return ctypes.addressof(buf), buf


def _pack_unit() -> tuple[Any, Any]:
    # A Unit slot -- an optional arg traced as None (top-level), or a void
    # element of a Tuple. It feeds no kernel arg (ir_arg_index None) but still
    # occupies an ABI slot the wrapper reads and forwards nowhere, so hand it a
    # non-null placeholder. Any caller-supplied value for it is ignored.
    buf = ctypes.c_void_p(0)
    return ctypes.addressof(buf), buf


def _alloc_return(ret: Any) -> tuple[int, Any]:
    """For a non-Unit ``Var`` return, allocate a typed buffer the Executor
    writes into. Returns ``(ret_addr, ret_buf)``; ``ret_addr == 0`` for Unit."""
    if isinstance(ret, Var):
        buf = ret.dtype.get_ctype()()
        return ctypes.addressof(buf), buf
    return 0, None


def _decode_return(ret: Any, ret_buf: Any) -> Any:
    if ret_buf is None:
        return None
    # A Bool dtype lowers to ``ctypes.c_ubyte`` (not ``c_bool``), so ``.value``
    # is an int 0/1; convert it back to a Python bool.
    if isinstance(ret, Var) and ret.dtype.code == DTypeCode.Bool:
        return bool(ret_buf.value)
    return ret_buf.value


# ---------------------------------------------------------------------------
# Signature helpers
# ---------------------------------------------------------------------------


def _is_baked(binding: Any) -> bool:
    """Whether a binding is compiled in rather than caller-supplied: it occupies
    no ABI slot AND no IR argument (``abi_arg_index`` and ``ir_arg_index`` both
    None) -- a baked top-level ``Const`` (a fixed literal) or ``Unit`` (void /
    absent optional). Filtering on the indices, not the binding *type*, mirrors
    the data-driven C++ wrapper/Executor: a ``Const`` that DOES carry an ABI slot
    (e.g. a passed-and-validated value) stays a caller argument."""
    return binding.abi_arg_index is None and binding.ir_arg_index is None


def _callable_params(function: ExecutableFunction) -> list[Any]:
    """Metadata params the caller supplies a value for: every param EXCEPT a
    baked one (``_is_baked``). A baked param is recorded in the metadata but is
    not a caller arg; ``__call__`` still emits one placeholder ``Executor.call``
    slot for it (which the data-driven Executor skips), so the slot count stays
    ``params.size()`` -- only the user-facing signature drops it."""
    return [p for p in function.metadata.params if not _is_baked(p)]


def _build_signature(params: list[Any], defaults: dict[str, Any]) -> inspect.Signature:
    """Build a Python signature from metadata parameter names.

    :param params: The parameters of the function.
    :param defaults: The default values of the Python function.
    :return: The signature of the function.
    """
    result = []
    for param in params:
        default = defaults.get(param.name, inspect.Parameter.empty)
        result.append(
            inspect.Parameter(
                param.name, inspect.Parameter.POSITIONAL_OR_KEYWORD, default=default
            )
        )
    return inspect.Signature(result)


def _resolve_call_args(
    function: ExecutableFunction,
    signature: inspect.Signature,
    *args: Any,
    **kwargs: Any,
) -> list[Any]:
    """Bind positional and keyword arguments to metadata parameter order."""
    try:
        bound = signature.bind(*args, **kwargs)
    except TypeError as exc:
        provided = set(kwargs) | {
            name for name, param in list(signature.parameters.items())[: len(args)]
        }
        missing = [
            name
            for name, param in signature.parameters.items()
            if param.default is inspect.Parameter.empty and name not in provided
        ]
        if missing:
            raise DSLUserCodeError(DiagId.CALL_MISSING_ARGS, missing=missing) from exc
        raise TypeError(f"{function.metadata.symbol_name}: {exc}") from exc

    bound.apply_defaults()
    args_by_name = bound.arguments
    return [
        args_by_name[param.name]
        for param in function.metadata.params
        if not _is_baked(param)
    ]


class CallableFunction:
    """Recommended Python-callable wrapper over an ``ExecutableFunction``.

    Prefer ``Abi.TvmFfi`` when it supports the required interface.
    ``Abi.CutlassCall`` is a private, unstable implementation ABI with no
    compatibility guarantee.

    The wrapper derives its Python signature from the function metadata, so
    ``inspect.signature`` and keyword arguments use the exported parameter
    names. Metadata does not preserve the original Python parameter kinds or
    defaults: every exported parameter is a required positional-or-keyword
    argument. Supported bindings are ``Tensor``, ``Var``, ``Const``, ``Stream``,
    ``Pointer``, ``Shape``, ``Tuple``, and ``Unit``; baked top-level ``Const``
    and ``Unit`` bindings are omitted from the signature. Tensor values depend
    on the selected ABI: ``CutlassCall`` accepts a ``cute.Tensor``, while
    ``TvmFfi`` accepts a DLPack producer such as a ``torch.Tensor``. A Shape
    value must be a nested tuple/list matching the metadata profile, with
    integer leaves in signed 64-bit range. Scalar values must be convertible to
    the binding dtype's C representation. Returns must be ``Var`` (decoded to a
    Python scalar) or ``Unit`` (decoded to ``None``).

    Example:

    .. code-block:: python

       from cutlass.compiler import Abi, Executor
       from cutlass.cutlass_dsl import CallableFunction

       # object_artifact was compiled with Abi.TvmFfi.
       executor = Executor.from_object_artifact(object_artifact)
       kernel = CallableFunction(executor["my_kernel"])
       result = kernel(input_tensor, scale=1.0)

    :param function: Loaded executable function to wrap.
    :raises ValueError: If the return is not ``Var`` or ``Unit``, or if the
        function has a top-level ``EnvStream`` parameter, which has no
        caller-suppliable value.
    """

    def __init__(
        self, function: ExecutableFunction, python_defaults: dict[str, Any] | None = {}
    ) -> None:
        """
        Create a new CallableFunction.

        :param function: The ExecutableFunction to wrap.
        :param python_defaults: A dictionary of default values in the Python function.
        """
        self._function = function
        self._abi = function.metadata.abi
        if not isinstance(function.metadata.ret, (Var, Unit)):
            raise ValueError(
                f"{function.metadata.symbol_name}: cannot wrap a function "
                f"with a {type(function.metadata.ret).__name__} return binding "
                "(supported: Var, Unit)"
            )
        # Reject up front any top-level binding the caller cannot supply a value
        # for, so construction fails clearly instead of the call failing later
        # mid-pack: an EnvStream (its stream is fetched out-of-band).
        for param in function.metadata.params:
            if isinstance(param, EnvStream):
                raise ValueError(
                    f"{function.metadata.symbol_name}: cannot wrap a function "
                    f"with a top-level {type(param).__name__} parameter "
                    f"{getattr(param, 'name', '?')!r} -- it carries no "
                    "caller-suppliable value"
                )
        self._callable_params = _callable_params(function)
        if python_defaults is None:
            python_defaults = {}
        self.__signature__ = _build_signature(self._callable_params, python_defaults)

    def _pack_tensor(self, value: Any) -> tuple[Any, Any]:
        if self._abi == Abi.CutlassCall:
            return _pack_tensor_cutlass_call(value)
        if self._abi == Abi.TvmFfi:
            return _pack_tensor_tvm_ffi(value)
        raise ValueError(
            f"cannot pack a Tensor for ABI {self._abi!r} in "
            f"{self._function.metadata.symbol_name}: only CutlassCall and "
            "TvmFfi are supported"
        )

    def _pack_binding(self, binding: Any, value: Any) -> tuple[Any, Any]:
        """Pack one caller-supplied value for a leaf or Tuple binding into its
        ``(slot_address, keepalive)``. Shared by top-level params and Tuple
        elements so a new binding type is handled in one place. A baked top-level
        ``Const`` / ``Unit`` is handled by ``__call__`` before this (it consumes
        no value); a ``Const`` *element* inside a Tuple is a real passed value and
        packs like a scalar here."""
        if isinstance(binding, Tensor):
            return self._pack_tensor(value)
        if isinstance(binding, (Var, Const)):
            return _pack_scalar(binding, value)
        if isinstance(binding, (Stream, Pointer)):
            return _pack_pointer(value)
        if isinstance(binding, Shape):
            return _pack_shape(binding, value)
        if isinstance(binding, Tuple):
            return self._pack_tuple(binding, value)
        if isinstance(binding, CustomType):
            from cutlass.cute.metadata import JIT_ARGUMENT_CUSTOM_TYPE_ID

            if binding.id != JIT_ARGUMENT_CUSTOM_TYPE_ID:
                raise ValueError(
                    f"{self._function.metadata.symbol_name}: CustomType param "
                    f"{getattr(binding, 'name', '?')!r} has unexpected id "
                    f"{binding.id!r} (expected {JIT_ARGUMENT_CUSTOM_TYPE_ID!r})"
                )

            # If an object does not implement the JitArgument protocol,
            # the value used to compile it must have been adapted.
            # Look for a suitable adapter.
            adapted_value = None
            if not implements_jit_argument(value):
                adapter = JitArgAdapterRegistry.get_registered_adapter(value)
                if adapter is not None:
                    value = adapter(value)
                    adapted_value = value
                else:
                    raise ValueError(
                        f"{self._function.metadata.symbol_name}: CustomType param "
                        f"{getattr(binding, 'name', '?')!r} does not implement "
                        "the JIT argument protocol nor has a suitable adapter."
                    )

            # If the value was adapted, make sure to keep the original
            # and adapted values alive
            address, keep = self._pack_jit_argument(binding, value)
            if adapted_value is not None:
                return address, (adapted_value, keep)
            return address, keep
        if isinstance(binding, Unit):
            return _pack_unit()
        raise ValueError(
            f"{self._function.metadata.symbol_name}: binding "
            f"{getattr(binding, 'name', '?')!r} of type "
            f"{type(binding).__name__} cannot be packed (supported: Tensor, Var, "
            "Const, Stream, Pointer, Shape, Tuple, CustomType, Unit)"
        )

    def _pack_tuple(self, tup: Tuple, value: Any) -> tuple[Any, Any]:
        """One ABI slot for a Tuple (dataclass / tuple) param: a ``void*[M]``
        sub-array with one entry per element (Const and Unit included), in
        metadata order; nested tuples recurse via ``_pack_binding``. The sub-array
        shape is ABI-uniform -- only a Tensor element's bytes differ, packed by
        ``self._pack_tensor``. The Executor forwards this sub-array to the
        CutlassCall wrapper untouched, or materializes it into a borrowed
        ffi.Array for TvmFfi.

        ``value`` is the dataclass instance (or plain tuple) supplying the
        element values, in field order. Returns ``(sub_array_address,
        keepalive)``; the keepalive retains both the array object and every
        child buffer until after ``call()``."""
        elements = list(tup.values)
        if is_dataclass(value):
            element_values = [getattr(value, f.name) for f in fields(value)]
        else:
            element_values = list(value)
        if len(element_values) != len(elements):
            raise ValueError(
                f"{self._function.metadata.symbol_name}: tuple param "
                f"{tup.name!r} expects {len(elements)} elements, got "
                f"{len(element_values)}"
            )

        addresses: list[int] = []
        keepalive: list[Any] = []
        for element, element_value in zip(elements, element_values):
            address, keep = self._pack_binding(element, element_value)
            addresses.append(address)
            keepalive.append(keep)

        sub_array = (ctypes.c_void_p * len(addresses))(*addresses)
        return ctypes.addressof(sub_array), (sub_array, keepalive)

    def _pack_jit_argument(self, binding: CustomType, value: Any) -> tuple[Any, Any]:
        """Pack one CustomType binding by calling ``value.__c_pointers__()``
        to obtain one pointer per binding element. The keepalive retains both
        the pointer array and every individual pointer buffer until after
        ``call()``."""
        pointers = value.__c_pointers__()
        addresses = [p.value if hasattr(p, "value") else int(p) for p in pointers]
        if len(addresses) != len(binding.values):
            raise ValueError(
                f"{self._function.metadata.symbol_name}: CustomType param "
                f"{binding.name!r} has {len(binding.values)} elements but "
                f"__c_pointers__() returned {len(addresses)} pointers"
            )
        sub_array = (ctypes.c_void_p * len(addresses))(*addresses)
        return ctypes.addressof(sub_array), (sub_array, list(pointers))

    def _repack_shape_exe_args(
        self, binding: Shape, exe_arg_iter: Iterator[object]
    ) -> tuple[Any, Any]:
        """Rebuild a Shape param's flat ``int64_t[leaf_count]`` ABI slot.

        ``exe_args`` from ``_generate_jit_func_args`` contributes, for one shape
        argument, either one typed-scalar pointer per *dynamic* leaf (via
        ``get_c_pointers``, the default) or a single ``tvm_ffi.Shape`` object
        carrying every dim (``--enable-tvm-ffi``); constant dims contribute no
        entry and are filled from the metadata."""
        table = self._function.metadata.dim_symbol_table
        leaves = binding.leaves
        leaf_count = len(leaves)
        sym_positions = [i for i, dim in enumerate(leaves) if dim.is_symbol]
        # A leaf that is not a symbol carries its constant extent as an int.
        dims: list[int] = [
            0 if dim.is_symbol else cast(int, dim.value) for dim in leaves
        ]
        if sym_positions:
            first = next(exe_arg_iter)
            if isinstance(first, (int, ctypes.c_void_p)):
                raws = [first] + [
                    next(exe_arg_iter) for _ in range(len(sym_positions) - 1)
                ]
                for pos, raw in zip(sym_positions, raws):
                    addr = _pointer_address(raw)
                    # sym_positions holds symbol leaves, so value is a SymbolId.
                    symbol = cast(SymbolId, leaves[pos].value)
                    bits = table[symbol.value].bits
                    ctype = ctypes.c_int32 if bits == 32 else ctypes.c_int64
                    dims[pos] = ctypes.cast(addr, ctypes.POINTER(ctype)).contents.value
            elif isinstance(first, Sequence):
                # A tvm_ffi.Shape (sequence of ints) holding every DFS leaf.
                values: list[int] = [
                    _shape_leaf_as_int64(v, path=f"{binding.name}[leaf {i}]")
                    for i, v in enumerate(first)
                ]
                if len(values) != leaf_count:
                    raise ValueError(
                        f"{self._function.metadata.symbol_name}: shape param "
                        f"{binding.name!r} expects {leaf_count} leaves, "
                        f"got a shape with {len(values)}"
                    )
                dims = values
            else:
                raise TypeError(
                    f"{self._function.metadata.symbol_name}: shape param "
                    f"{binding.name!r} expects pointer arguments or a sequence "
                    f"of integer leaves, got {type(first).__name__}"
                )
        buf = (ctypes.c_int64 * leaf_count)(*dims)
        return ctypes.addressof(buf), buf

    def _repack_exe_binding(
        self, binding: Binding, exe_arg_iter: Iterator[object]
    ) -> tuple[Any, Any]:
        """Rebuild one metadata binding from the adapter's flat arguments."""
        if isinstance(binding, Shape):
            return self._repack_shape_exe_args(binding, exe_arg_iter)
        if isinstance(binding, Tuple):
            addresses: list[int] = []
            keepalive: list[Any] = []
            for elem in binding.values:
                addr, keep = self._repack_exe_binding(elem, exe_arg_iter)
                addresses.append(addr)
                keepalive.append(keep)
            sub_array = (ctypes.c_void_p * len(addresses))(*addresses)
            return ctypes.addressof(sub_array), (sub_array, keepalive)
        if isinstance(binding, CustomType):
            addresses = []
            keepalive = []
            for elem in binding.values:
                addr, keep = self._repack_exe_binding(elem, exe_arg_iter)
                addresses.append(addr)
                keepalive.append(keep)
            sub_array = (ctypes.c_void_p * len(addresses))(*addresses)
            return ctypes.addressof(sub_array), (sub_array, keepalive)
        if isinstance(binding, Const):
            value: bool | int | float
            if binding.dtype.code == DTypeCode.Bool:
                value = binding.as_bool()
            elif binding.dtype.code == DTypeCode.Int:
                value = binding.as_signed()
            elif binding.dtype.code == DTypeCode.UInt:
                value = binding.as_unsigned()
            else:
                value = binding.as_float()
            return _pack_scalar(binding, value)
        if isinstance(binding, Unit):
            return _pack_unit()
        if isinstance(binding, EnvStream):
            raise ValueError(
                f"{self._function.metadata.symbol_name}: cannot repack an "
                "EnvStream from execution arguments"
            )

        raw = next(exe_arg_iter)
        # Adapter entries may be plain integer addresses or ctypes pointers.
        addr = _pointer_address(raw)
        return addr, raw

    def call_with_exe_args(self, exe_args: list[Any]) -> Any:
        """Dispatch to ``_function.call`` from a flat list of pre-packed addresses.

        ``exe_args`` contains packed C-pointer values (``int`` or
        ``ctypes.c_void_p``) produced by ``dsl.py`` via
        ``_generate_jit_func_args``. The adapter flattens Tuple/dataclass fields
        and dynamic Shape leaves, while the Executor expects one slot per
        top-level metadata binding. Recurse through the metadata tree to rebuild
        Tuple sub-arrays and Shape ``int64_t[leaf_count]`` slots; reconstruct
        baked Const/Unit elements from metadata because they have no adapter
        entry."""
        exe_arg_iter = iter(exe_args)
        addresses: list[int] = []
        keepalive: list[Any] = []
        for param in self._function.metadata.params:
            addr, keep = self._repack_exe_binding(param, exe_arg_iter)
            addresses.append(addr)
            keepalive.append(keep)
        sentinel = object()
        if next(exe_arg_iter, sentinel) is not sentinel:
            raise ValueError(
                f"{self._function.metadata.symbol_name}: received more execution "
                "arguments than required by its metadata"
            )
        ret_addr, ret_buf = _alloc_return(self._function.metadata.ret)
        self._function.call(addresses, ret_addr)
        # keepalive holds any c_void_p wrappers alive across the call.
        return _decode_return(self._function.metadata.ret, ret_buf)

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        """Invoke the compiled function with its metadata-derived signature.

        Arguments may be positional or keyword values and are bound in
        metadata order. For ``CutlassCall``, Tensor parameters require a
        ``cute.Tensor``. For ``TvmFfi``, they require a DLPack producer such as
        ``torch.Tensor``. ``Var`` and ``Const`` scalars must be convertible to
        their metadata dtype's C representation. Shape values must match the
        recursive metadata profile and contain signed-64-bit integer leaves. A
        ``Var`` return is converted to its Python scalar value; a ``Unit``
        return becomes ``None``.

        :raises TypeError: If arguments do not match the metadata-derived
            signature or a value cannot be converted for its binding.
        :raises ValueError: If a binding or ABI is unsupported, a Tuple value
            is invalid, or a Shape value does not match the metadata profile.
        :raises OverflowError: If a Shape leaf is outside signed 64-bit range.
        :raises RuntimeError: If native function invocation fails.
        """
        ordered_args = _resolve_call_args(
            self._function, self.__signature__, *args, **kwargs
        )
        keepalive: list[Any] = []
        addresses: list[int] = []
        # One Executor.call slot per metadata param. A baked param (`_is_baked` --
        # a compiled-in top-level Const / Unit) is not a caller arg (excluded from
        # the signature), so it consumes no user value: emit a placeholder for its
        # slot, which the data-driven Executor skips (no abi_arg_index). Every
        # other param consumes one value from `ordered_args` (metadata order, with
        # the baked params filtered out, matching `_callable_params`).
        arg_iter = iter(ordered_args)
        for param in self._function.metadata.params:
            if _is_baked(param):
                address, keep = _pack_unit()
            else:
                address, keep = self._pack_binding(param, next(arg_iter))
            addresses.append(address)
            keepalive.append(keep)

        ret_addr, ret_buf = _alloc_return(self._function.metadata.ret)
        self._function.call(addresses, ret_addr)
        # `keepalive` holds each arg's buffer / capsule / tensor alive across the
        # call; released when this method returns.
        return _decode_return(self._function.metadata.ret, ret_buf)


# Sentinel stored in ``engine`` / ``capi_func`` so in-memory JIT cache treats
# cutlass-backed compiles as executable without an MLIR ExecutionEngine.
_CUTLASS_JIT_SENTINEL = object()


class CutlassCallJitCompiledFunction:
    """``JitCompiledFunction`` surface backed by ``cutlass.compiler`` + CutlassCall."""

    # Names ``__getattr__`` forwards to the composed ``JitCompiledFunction``
    # (``self._jit_base``): the compiled-artifact accessors plus the JIT
    # metadata / AOT-header surface this wrapper reuses rather than
    # reimplements. Everything NOT listed here (typos, or engine-only members
    # such as the ``to`` / ``dump_to_object`` helpers this wrapper overrides
    # with ``NotImplementedError``) falls through to the default ``object``
    # lookup, which raises the usual ``AttributeError`` instead of being
    # silently masked by the delegate.
    _DELEGATED_ATTRS = frozenset(
        {
            # Compiled-artifact accessors (``@property`` on the base).
            "__ptx__",
            "__cubin__",
            "__sass__",
            "__llvm_ir__",
            "__mlir__",
            # JIT metadata / bookkeeping.
            "seal_specialization",
            "function_name",
            "kernel_info",
            "execution_args",
            "artifacts",
            "jit_time_profiling",
            "prefix",
            "load_from_binary",
            "host_target",
            "jit_module",
            "has_gpu_module",
            "export_provider",
            # AOT header helpers.
            "generate_execution_args",
            "c_header_arguments",
            "dummy_prefix_name",
        }
    )

    def __init__(
        self,
        *,
        ir_module: Any,
        cutlass_call: CallableFunction | None,
        executor: Any | None,
        signature: inspect.Signature,
        function_name: str,
        kernel_info: dict[str, Any] | None,
        jit_time_profiling: bool,
        jit_function_artifacts: Any,
        compile_time_args: tuple[Any, ...],
        compile_time_kwargs: dict[str, Any],
        dynamic_args: tuple[Any, ...] = tuple(),
        dynamic_kwargs: dict[str, Any] | None = None,
        has_gpu_module: bool = True,
        host_target: Any = None,
    ) -> None:
        from cutlass.base_dsl.jit_executor import JitCompiledFunction

        if host_target is None:
            from cutlass.base_dsl.compiler import HostTarget

            host_target = HostTarget("")

        self._cutlass_call = cutlass_call
        self._executor = executor
        self._compile_time_args = compile_time_args
        self._compile_time_kwargs = compile_time_kwargs or {}
        self.ir_module = ir_module
        self.engine = _CUTLASS_JIT_SENTINEL
        self.capi_func = _CUTLASS_JIT_SENTINEL

        # Reuse ``JitCompiledFunction`` for AOT helpers and artifact properties.
        self._jit_base = JitCompiledFunction(
            ir_module,
            _CUTLASS_JIT_SENTINEL,
            _CUTLASS_JIT_SENTINEL,
            signature,
            function_name,
            kernel_info,
            jit_time_profiling,
            jit_function_artifacts,
            dynamic_args=dynamic_args,
            dynamic_kwargs=dynamic_kwargs or {},
            has_gpu_module=has_gpu_module,
            host_target=host_target,
        )

    def __getattr__(self, name: str) -> Any:
        # Forward only the known ``JitCompiledFunction`` surface (see
        # ``_DELEGATED_ATTRS``) to the composed base. Any other missing name
        # defers to the super class' default lookup, which raises the normal
        # ``AttributeError`` -- this also breaks the recursion for
        # ``_jit_base`` itself before ``__init__`` has set it.
        if name in self._DELEGATED_ATTRS:
            return getattr(self._jit_base, name)
        return super().__getattribute__(name)

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        if self._cutlass_call is None:
            raise ValueError("This instance was configured for device-only execution.")
        return self._cutlass_call(*args, **kwargs)

    def run_compiled_program(self, exe_args: list[Any]) -> int | None:
        """Run the compiled program."""
        if self._cutlass_call is None:
            raise ValueError("This instance was configured for device-only execution.")
        return self._cutlass_call.call_with_exe_args(exe_args)

    def to(self, device: Any = None) -> Any:
        raise NotImplementedError(
            "CutlassCallJitCompiledFunction.to() requires the MLIR ExecutionEngine "
            "and is not supported by the cutlass compiler backend yet."
        )

    def get_aux_func(
        self,
        func_class: Any,
        kernel: Any = None,
        *,
        required: bool = True,
    ) -> Any:
        raise NotImplementedError(
            "CutlassCallJitCompiledFunction.get_aux_func() requires engine symbol "
            "lookup and is not supported by the cutlass compiler backend yet."
        )

    def dump_to_object(self, function_prefix: str) -> bytes:
        raise NotImplementedError(
            "CutlassCallJitCompiledFunction.dump_to_object() requires the MLIR "
            "ExecutionEngine and is not supported by the cutlass compiler backend yet."
        )

    def export_to_c(
        self,
        file_path: str,
        file_name: str,
        function_prefix: str = "",
    ) -> None:
        raise NotImplementedError(
            "CutlassCallJitCompiledFunction.export_to_c() requires the MLIR "
            "ExecutionEngine and is not supported by the cutlass compiler backend yet."
        )
