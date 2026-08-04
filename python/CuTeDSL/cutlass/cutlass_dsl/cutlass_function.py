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

from __future__ import annotations

import ctypes
import inspect
from dataclasses import fields, is_dataclass
from typing import Any

from cutlass.compiler import (
    Abi,
    Const,
    DTypeCode,
    EnvStream,
    ExecutableFunction,
    Pointer,
    Shape,
    Stream,
    Tensor,
    Tuple,
    Unit,
    Var,
)

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

    Returns ``(address, keepalive)``; the keepalive is the tensor, which owns the
    descriptor buffer (freed when its capsule is collected)."""
    if not hasattr(value, "__c_pointers__"):
        raise TypeError(
            "CutlassCall expects a cute.Tensor argument (exposing "
            f"__c_pointers__); got {type(value).__name__}. Wrap it with "
            "cutlass.cute.runtime.from_dlpack(...) first."
        )
    # pointers[0] is the address of that cute::abi::MemRef buffer -- exactly the
    # <sym>_param_i_t the kernel's CutlassCall slot expects.
    pointers = value.__c_pointers__()
    return pointers[0], value


def _pack_tensor_tvm_ffi(value: Any) -> tuple[Any, Any]:
    """TvmFfi Tensor slot: a borrowed ``DLTensor*`` from the producer's DLPack
    capsule. The keepalive is the capsule, so its DLPack deleter does not run
    before the call consumes the tensor.

    Request ``stream=-1`` (no synchronization), like ``cute.runtime.from_dlpack``
    does, and fall back to a bare ``__dlpack__()`` for producers whose
    ``__dlpack__`` does not accept a ``stream`` kwarg. A bare call lets the
    producer pick its default stream behaviour, which on some torch versions
    forces an implicit stream sync -- avoided here since this is a per-call hot
    path."""
    try:
        capsule = value.__dlpack__(stream=-1)
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
    buf = binding.dtype.get_ctype()(value)
    return ctypes.addressof(buf), buf


def _pack_pointer(value: Any) -> tuple[Any, Any]:
    buf = ctypes.c_void_p(0 if value is None else int(value))
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


def _build_signature(params: list[Any]) -> inspect.Signature:
    """Build a Python signature from metadata parameter names."""
    return inspect.Signature(
        [
            inspect.Parameter(param.name, inspect.Parameter.POSITIONAL_OR_KEYWORD)
            for param in params
        ]
    )


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
        raise TypeError(f"{function.metadata.symbol_name}: {exc}") from exc

    args_by_name = bound.arguments
    return [
        args_by_name[param.name]
        for param in function.metadata.params
        if not _is_baked(param)
    ]


class CallableFunction:
    """ABI-agnostic callable wrapper over an ``ExecutableFunction``.

    Dispatches on ``metadata.abi`` to stage each parameter into the ``void**``
    slots ``ExecutableFunction.call`` expects. Only the Tensor slot differs by
    ABI:

      * CutlassCall -- the tensor's own cute-flat / ``cute::abi::MemRef``
        descriptor, reused via ``cute.Tensor.__c_pointers__()``.
      * TvmFfi      -- a borrowed ``DLTensor*`` from ``value.__dlpack__()``.
        Pass a DLPack producer (e.g. a torch.Tensor).

    ``Var`` / ``Stream`` / ``Pointer`` slots are ABI-identical. Construct this
    explicitly around the raw ``ExecutableFunction`` from
    ``Executor.get_executable_function``.
    """

    def __init__(self, function: ExecutableFunction) -> None:
        self._function = function
        self._abi = function.metadata.abi
        # Reject up front any top-level binding the caller cannot supply a value
        # for, so construction fails clearly instead of the call failing later
        # mid-pack: an EnvStream (its stream is fetched out-of-band) or a bare
        # Shape (it binds symbols derived from other args).
        for param in function.metadata.params:
            if isinstance(param, (EnvStream, Shape)):
                raise ValueError(
                    f"{function.metadata.symbol_name}: cannot wrap a function "
                    f"with a top-level {type(param).__name__} parameter "
                    f"{getattr(param, 'name', '?')!r} -- it carries no "
                    "caller-suppliable value"
                )
        self._callable_params = _callable_params(function)
        self.__signature__ = _build_signature(self._callable_params)

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
        if isinstance(binding, Tuple):
            return self._pack_tuple(binding, value)
        if isinstance(binding, Unit):
            return _pack_unit()
        raise ValueError(
            f"{self._function.metadata.symbol_name}: binding "
            f"{getattr(binding, 'name', '?')!r} of type "
            f"{type(binding).__name__} cannot be packed (supported: Tensor, Var, "
            "Const, Stream, Pointer, Tuple, Unit)"
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

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
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
