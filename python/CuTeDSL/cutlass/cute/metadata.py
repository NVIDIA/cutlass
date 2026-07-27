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

"""Build typed ``cutlass.compiler.metadata`` values directly from a CuTe DSL
kernel signature.

This walks the live ``(signature, args, kwonlyargs)`` of a ``@cute.jit`` kernel
straight into the typed C++ metadata hierarchy carried by
``CompilationArtifact``, reading the DSL-native argument types directly, so
downstream consumers (codegen, AOT wrapper generation, diagnostics) can
introspect the calling convention.

Its only MLIR dependency is the ``cute`` dialect's ``AddressSpace`` enum, used to
classify a tensor/pointer's memory space; it builds no IR and needs no active
MLIR context.
"""

import inspect
import struct
from dataclasses import fields as dataclass_fields, is_dataclass
from types import UnionType
from typing import (
    Any,
    Dict,
    Iterator,
    List,
    Optional,
    SupportsInt,
    Tuple,
    Type,
    Union,
    cast,
    get_args,
    get_origin,
    get_type_hints,
)

import cuda.bindings.driver as cuda

import cutlass.compiler as md
from cutlass._mlir.dialects import cute as _cute_ir
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.runtime.jit_arg_adapters import is_arg_annotation_constexpr
from cutlass.base_dsl.typing import Constexpr
from cutlass.compiler import DType, DTypeCode
from cutlass.cutlass_dsl import is_cute_algebra_type
from .runtime import _FakeStream
from .typing import (
    Numeric,
    Pointer,
    SymInt,
    Tensor,
    Boolean,
    Int4,
    Int8,
    Uint8,
    Int16,
    Uint16,
    Int32,
    Uint32,
    Int64,
    Uint64,
    Float16,
    BFloat16,
    Float32,
    TFloat32,
    Float64,
    Float6E2M3FN,
    Float6E3M2FN,
    Float8E5M2,
    Float8E4M3FN,
    Float8E8M0FNU,
    Float4E2M1FN,
)


# ---------------------------------------------------------------------------
# DType mapping
# ---------------------------------------------------------------------------

# Maps each supported CuTe ``Numeric`` subclass to a factory producing its
# metadata ``DType``. Mapping the subclass directly is exact: ``DType.from_string``
# only accepts canonical lowercase names like ``"int32"``, which ``str(Int32)``
# (``"Int32"``) is not.
_NUMERIC_TO_DTYPE_FACTORY = {
    Boolean: DType.bool_,
    # No named factory for 4-bit ints; construct from (code, bits) directly.
    Int4: lambda: DType(DTypeCode.Int, 4),
    Int8: DType.int8,
    Uint8: DType.uint8,
    Int16: DType.int16,
    Uint16: DType.uint16,
    Int32: DType.int32,
    Uint32: DType.uint32,
    Int64: DType.int64,
    Uint64: DType.uint64,
    Float16: DType.float16,
    BFloat16: DType.bfloat16,
    Float32: DType.float32,
    # TF32 has no distinct metadata DTypeCode; represent it as float32. This
    # drops the "this is TF32" distinction, which metadata cannot express.
    TFloat32: DType.float32,
    Float64: DType.float64,
    Float8E5M2: DType.float8_e5m2,
    Float8E4M3FN: DType.float8_e4m3fn,
    Float8E8M0FNU: DType.float8_e8m0fnu,
    Float6E2M3FN: DType.float6_e2m3fn,
    Float6E3M2FN: DType.float6_e3m2fn,
    Float4E2M1FN: DType.float4_e2m1fn,
}

# Numeric subclasses accepted as a plain scalar parameter: standard integer and
# float widths only -- sub-byte and narrow-float types appear only as tensor
# element types, never as scalar args.
_ACCEPTABLE_SCALAR_NUMERICS = frozenset(
    {
        Boolean,
        Int8,
        Uint8,
        Int16,
        Uint16,
        Int32,
        Uint32,
        Int64,
        Uint64,
        Float16,
        BFloat16,
        Float32,
        TFloat32,
        Float64,
    }
)


def _numeric_to_dtype(dtype: Type[Numeric]) -> DType:
    """Map a CuTe ``Numeric`` subclass to its metadata ``DType``.

    Raises ``DSLRuntimeError`` for unsupported dtypes (packed FP6x4) and for any
    subclass missing from the factory table. A drift guard asserts the mapped
    ``DType.bits`` equals the subclass ``width``, catching silent divergence if
    either side's dtype set changes (skipped for packed dtypes, whose storage
    width differs from the unpacked element bits by design).
    """
    try:
        factory = _NUMERIC_TO_DTYPE_FACTORY[dtype]
    except KeyError as exc:
        raise DSLRuntimeError(
            f"Metadata does not support dtype {dtype.__name__}."
        ) from exc

    result = factory()
    return result


# ---------------------------------------------------------------------------
# Memory space mapping (the lone MLIR enum dependency)
# ---------------------------------------------------------------------------

# DLPack ``DLDeviceType`` values (dlpack.h). A tensor's ``device_kind`` is a
# compile-time type-level property: GPU memory => CUDA, otherwise host => CPU.
_KDL_CPU = 1
_KDL_CUDA = 2


def _memspace_to_device_kind(memspace: "_cute_ir.AddressSpace") -> int:
    """Classify a tensor's device kind from its memory space: anything other than
    the generic space is GPU memory."""
    return _KDL_CPU if memspace == _cute_ir.AddressSpace.generic else _KDL_CUDA


def _memspace_to_address_space(memspace: "_cute_ir.AddressSpace") -> "md.AddressSpace":
    """Map a CuTe memory space to a metadata pointer address space: gmem -> global,
    everything else -> generic."""
    if memspace == _cute_ir.AddressSpace.gmem:
        return md.AddressSpace.Global
    return md.AddressSpace.Generic


# DLPack dtype names that DType.from_string cannot parse directly: a packed FP4
# name denotes the same unpacked element encoding.
_DLPACK_DTYPE_ALIASES: dict[str, str] = {
}


def _dlpack_dtype_to_dtype(dlpack_dtype: Any) -> DType:
    """Map a real tensor's backing DLPack dtype to its metadata ``DType``. The
    DLPack name is canonical lowercase, so ``DType.from_string`` parses it
    directly once a packed-FP4 name is resolved to its unpacked element."""
    name = str(dlpack_dtype)
    return DType.from_string(_DLPACK_DTYPE_ALIASES.get(name, name))


def _same_dtype(a: DType, b: DType) -> bool:
    return a.code == b.code and a.bits == b.bits and a.lanes == b.lanes


# DLPack DLDeviceType for the runtime device a real tensor lives on.
_DEVICE_TYPE_TO_KIND = {"cpu": _KDL_CPU, "cuda": _KDL_CUDA}


def _device_type_to_device_kind(device_type: Any) -> int:
    return _DEVICE_TYPE_TO_KIND.get(str(device_type), _KDL_CUDA)


def _normalize_divisibility(divisibility: Optional[int]) -> Optional[int]:
    """Collapse a trivial divisibility to ``None``. A ``SymInt`` defaults its
    divisibility to 1 ("divisible by 1" is no constraint); metadata expresses
    "no constraint" as ``None``, so emitting 1 would assert a noise ``% 1 == 0``."""
    return None if divisibility in (None, 1) else divisibility


# ---------------------------------------------------------------------------
# Dim symbol table
# ---------------------------------------------------------------------------


class _SymIntId:
    """Identity key for a ``SymInt``: the same instance shared across two tensor
    dimensions means those extents are the same runtime value. ``SymInt.__eq__``
    honours ``(width, divisibility, symbol)``, so value-equality would wrongly
    merge distinct extents -- dedup must key on object identity."""

    __slots__ = ("sym_int",)

    def __init__(self, sym_int: SymInt) -> None:
        self.sym_int = sym_int

    def __hash__(self) -> int:
        return id(self.sym_int)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, _SymIntId):
            return NotImplemented
        return self.sym_int is other.sym_int


class _DimSymbolTable:
    """Accumulates the per-function ``DimSymbol`` table while the walk builds dims.

    A shared ``SymInt`` instance resolves to one ``DimSymbol`` (so two ``Dim``s
    referencing the same ``SymbolId`` recover the "same extent" relationship);
    an anonymous dynamic dim gets a fresh symbol. ``SymbolId`` equals the
    symbol's index in ``symbols`` (first-encounter order).
    """

    def __init__(self) -> None:
        self.symbols: List["md.DimSymbol"] = []
        self._symint_to_id: Dict[_SymIntId, "md.SymbolId"] = {}
        self._num_shape = 0
        self._num_stride = 0

    def _next_name(self, is_stride: bool) -> str:
        if is_stride:
            name = f"s{self._num_stride}"
            self._num_stride += 1
        else:
            name = f"n{self._num_shape}"
            self._num_shape += 1
        return name

    def _append(
        self, name: str, bits: int, divisibility: Optional[int]
    ) -> "md.SymbolId":
        sid = md.SymbolId(len(self.symbols))
        self.symbols.append(
            md.DimSymbol(name=name, bits=bits, divisibility=divisibility)
        )
        return sid

    def dim_for_symint(self, sym: SymInt, *, is_stride: bool) -> "md.Dim":
        key = _SymIntId(sym)
        existing = self._symint_to_id.get(key)
        if existing is not None:
            return md.Dim(existing)
        name = sym.symbol or self._next_name(is_stride)
        sid = self._append(name, sym.width, _normalize_divisibility(sym.divisibility))
        self._symint_to_id[key] = sid
        return md.Dim(sid)

    def dim_for_anonymous(self, *, bits: int, is_stride: bool) -> "md.Dim":
        return md.Dim(self._append(self._next_name(is_stride), bits, None))


# ---------------------------------------------------------------------------
# Per-argument conversion
# ---------------------------------------------------------------------------


def _const_binding(name: str, arg: Any) -> "md.Binding":
    """Build a ``Const``/``Unit`` for a compile-time constexpr value, pinning its
    exact bit pattern for the wrapper to assert against."""
    if arg is None:
        return md.Unit(name=name)
    # bool before int (bool is a subclass of int).
    if isinstance(arg, bool):
        return md.Const(name=name, dtype=DType.bool_(), value=1 if arg else 0)
    if isinstance(arg, int):
        if not -(2**63) <= arg < 2**64:
            raise DSLRuntimeError(
                f"Constexpr int {arg} for {name!r} does not fit in 64 bits."
            )
        # Const carries a raw u64 bit pattern that a boundary equality check
        # reads back; wrap a negative value to its two's-complement u64. A
        # constexpr int is always int64 -- its value, not a narrow width, is
        # what gets asserted.
        return md.Const(
            name=name, dtype=DType.int64(), value=int(arg) & 0xFFFFFFFFFFFFFFFF
        )
    if isinstance(arg, float):
        bits = struct.unpack("<Q", struct.pack("<d", float(arg)))[0]
        return md.Const(name=name, dtype=DType.float64(), value=bits)
    raise DSLRuntimeError(
        f"Unsupported constexpr value for {name!r}: {type(arg).__name__}. "
        "Supported: None, int, bool, float."
    )


def _is_const_representable(value: Any) -> bool:
    """Whether ``_const_binding`` can pin this constexpr value as a ``Const`` /
    ``Unit`` -- only a scalar ``None`` / ``bool`` / ``int`` / ``float`` (``bool``
    is an ``int`` subclass). A non-scalar compile-time constexpr (a tuple, a
    type, a CuTe layout, a Numeric, ...) has no metadata representation, so it is
    pure compile-time specialization and is dropped from the calling convention
    (as it always was) rather than forced into an unrepresentable ``Const``."""
    return value is None or isinstance(value, (int, float))


def _tensor_binding(arg: "Tensor", name: str, table: _DimSymbolTable) -> "md.Tensor":
    """Convert a live CuTe tensor value to a metadata ``Tensor``.

    The ABI ``dtype`` is the type each cell is passed as at the boundary. For a
    real tensor that is the backing DLPack storage dtype; CuTe may set
    ``element_type`` to a different logical type (e.g. fp4 cells reinterpreted
    from ``uint8`` storage), recorded as ``element_dtype`` when it differs. A
    fake (descriptor-only) tensor has no separate storage, so its declared
    ``element_type`` is both the storage and logical type.
    """
    shape = arg.shape
    stride = arg.stride
    assert isinstance(shape, tuple) and isinstance(stride, tuple)

    shape_dims: List["md.Dim"] = []
    for i, dynamic in enumerate(arg.dynamic_shapes_mask):
        dim = shape[i]
        if not dynamic:
            shape_dims.append(md.Dim(int(cast(SupportsInt, dim))))
        elif isinstance(dim, SymInt):
            shape_dims.append(table.dim_for_symint(dim, is_stride=False))
        else:
            shape_dims.append(table.dim_for_anonymous(bits=32, is_stride=False))

    use_32bit_stride = getattr(arg, "_use_32bit_stride", False)
    stride_bits = 32 if use_32bit_stride else 64
    stride_dims: List["md.Dim"] = []
    for i, dynamic in enumerate(arg.dynamic_strides_mask):
        s = stride[i]
        if not dynamic:
            stride_dims.append(md.Dim(int(cast(SupportsInt, s))))
        elif isinstance(s, SymInt):
            stride_dims.append(table.dim_for_symint(s, is_stride=True))
        else:
            stride_dims.append(
                table.dim_for_anonymous(bits=stride_bits, is_stride=True)
            )

    if hasattr(arg, "_tvm_ffi_tensor"):
        storage_dtype = _dlpack_dtype_to_dtype(arg._tvm_ffi_tensor.dtype)
        logical_dtype = _numeric_to_dtype(arg.element_type)
        element_dtype = (
            None if _same_dtype(logical_dtype, storage_dtype) else logical_dtype
        )
        device_kind = _device_type_to_device_kind(arg._tvm_ffi_tensor.device.type)
    else:
        storage_dtype = _numeric_to_dtype(arg.element_type)
        element_dtype = None
        device_kind = _memspace_to_device_kind(arg.memspace)

    return md.Tensor(
        name=name,
        shape=shape_dims,
        dtype=storage_dtype,
        element_dtype=element_dtype,
        strides=stride_dims,
        data_address_space=_memspace_to_address_space(arg.memspace),
        device_kind=device_kind,
        data_alignment=getattr(arg, "_assumed_align", None),
    )


def _cute_shape_binding(arg: Any, name: str, table: _DimSymbolTable) -> "md.Shape":
    """Convert a flat CuTe shape/stride/coord argument to a metadata ``Shape``.

    A metadata ``Shape`` is a flat list of ``Dim``s, so a hierarchical
    (nested-tuple) shape has no representation here and is rejected.
    """
    dims: List["md.Dim"] = []
    for elem in arg:
        if isinstance(elem, bool):
            raise DSLRuntimeError(f"Unexpected bool in cute shape arg {name!r}.")
        if isinstance(elem, int):
            dims.append(md.Dim(int(elem)))
        elif isinstance(elem, SymInt):
            dims.append(table.dim_for_symint(elem, is_stride=False))
        elif isinstance(elem, Numeric):
            dims.append(table.dim_for_anonymous(bits=elem.dtype.width, is_stride=False))
        elif isinstance(elem, tuple):
            raise DSLRuntimeError(
                f"Nested cute shape arguments are not supported in metadata "
                f"for {name!r}."
            )
        else:
            raise DSLRuntimeError(
                f"Unexpected cute shape element {type(elem).__name__} in {name!r}."
            )
    return md.Shape(name=name, dims=dims)


def _to_binding(
    arg: Any,
    name: str,
    arg_type: Any,
    table: _DimSymbolTable,
    *,
    is_constexpr: bool = False,
) -> "md.Binding":
    """Convert one live argument to a metadata ``Binding``.

    Branch order is load-bearing: bool before int (bool is an int subclass),
    value-typed scalars before annotation-typed, NamedTuple before generic tuple.
    """
    if is_constexpr:
        return _const_binding(name, arg)

    if arg is None:
        return md.Unit(name=name)

    # Scalar Numeric, classified by runtime value then by annotation.
    if isinstance(arg, Numeric) and arg.dtype in _ACCEPTABLE_SCALAR_NUMERICS:
        return md.Var(name=name, dtype=_numeric_to_dtype(arg.dtype))
    if arg_type in _ACCEPTABLE_SCALAR_NUMERICS:
        return md.Var(name=name, dtype=_numeric_to_dtype(arg_type))

    # native_struct: an opaque handle passed by pointer.
    if (
        _native_struct_type(arg_type) is not None
        or _native_struct_type(arg) is not None
    ):
        return md.Var(name=name, dtype=DType.handle())

    if is_cute_algebra_type(arg_type):
        return _cute_shape_binding(arg, name, table)

    # Standalone SymInt scalar: a runtime integer, never a shared dim symbol.
    if isinstance(arg, SymInt):
        dtype = DType.int32() if arg.width == 32 else DType.int64()
        return md.Var(
            name=name,
            dtype=dtype,
            divisibility=_normalize_divisibility(arg.divisibility),
        )

    if isinstance(arg, Tensor):
        return _tensor_binding(arg, name, table)

    if isinstance(arg, Pointer) or arg_type == Pointer:
        space = md.AddressSpace.Generic
        if hasattr(arg, "memspace"):
            space = _memspace_to_address_space(arg.memspace)
        return md.Pointer(name=name, address_space=space)

    if isinstance(arg, _FakeStream):
        if arg.use_tvm_ffi_env_stream:
            return md.EnvStream(name=name)
        return md.Stream(name=name)

    if isinstance(arg, cuda.CUstream):
        return md.Stream(name=name)

    # NamedTuple: normalize to a Tuple by field order.
    if arg_type is not inspect.Parameter.empty and hasattr(arg_type, "_fields"):
        type_hints = get_type_hints(arg_type)
        element_types = [type_hints[field] for field in arg_type._fields]
        return _tuple_binding(arg, name, element_types, table)

    # Tuple[X, Y, ...] annotation.
    if arg_type is not inspect.Parameter.empty and get_origin(arg_type) is tuple:
        return _tuple_binding(arg, name, list(get_args(arg_type)), table)

    # Plain tuple/list without element annotations.
    if isinstance(arg, (tuple, list)):
        return _tuple_binding(arg, name, [None] * len(arg), table)

    # Unannotated runtime scalars (bool before int).
    if isinstance(arg, bool):
        return md.Var(name=name, dtype=DType.bool_())
    if isinstance(arg, int):
        return md.Var(name=name, dtype=DType.int32())
    if isinstance(arg, float):
        return md.Var(name=name, dtype=DType.float32())

    # Dataclass: each field becomes a tuple element; constexpr fields are pinned.
    if (
        is_dataclass(arg_type)
        if (arg_type is not None and arg_type is not inspect.Parameter.empty)
        else is_dataclass(type(arg))
    ):
        dc_type = (
            arg_type
            if (
                arg_type is not None
                and arg_type is not inspect.Parameter.empty
                and is_dataclass(arg_type)
            )
            else type(arg)
        )
        if not isinstance(arg, dc_type):
            raise DSLRuntimeError(
                f"Expected {dc_type.__name__} for argument {name}, got {type(arg)}"
            )
        # Field annotations are strings under PEP 563 (`from __future__ import
        # annotations`); resolve them the same way the NamedTuple branch above
        # does, so a nested dataclass or a Constexpr field is recognized rather
        # than mistaken for an unsupported scalar. Fall back to the raw
        # `f.type` if resolution fails (e.g. a locally-scoped class).
        try:
            field_types = get_type_hints(dc_type)
        except Exception:
            field_types = {}
        values = []
        for f in dataclass_fields(dc_type):
            field_type = field_types.get(f.name, f.type)
            # Mirror is_constexpr_field's check, but on the resolved type (its
            # raw `f.type` is a string under PEP 563).
            field_is_constexpr = (
                field_type is Constexpr or get_origin(field_type) is Constexpr
            )
            values.append(
                _to_binding(
                    getattr(arg, f.name),
                    f"{name}.{f.name}",
                    field_type,
                    table,
                    is_constexpr=field_is_constexpr,
                )
            )
        return md.Tuple(name=name, values=values)

    if arg_type is not None and (
        get_origin(arg_type) is UnionType or get_origin(arg_type) is Union
    ):
        for member_type in get_args(arg_type):
            try:
                return _to_binding(arg, name, member_type, table)
            except DSLRuntimeError:
                continue
        raise DSLRuntimeError(
            f"Unsupported argument {name!r} of type {type(arg)} for union "
            f"{arg_type}: no member matched."
        )

    raise DSLRuntimeError(
        f"Unsupported argument {name!r} of type {type(arg)} (annotation {arg_type})."
    )


def _tuple_binding(
    arg: Any,
    name: str,
    element_types: List[Any],
    table: _DimSymbolTable,
) -> "md.Tuple":
    if not isinstance(arg, (tuple, list)):
        raise DSLRuntimeError(
            f"Expected tuple/list for argument {name}, got {type(arg)}"
        )
    if len(arg) != len(element_types):
        raise DSLRuntimeError(
            f"Tuple length mismatch for argument {name}: expected "
            f"{len(element_types)}, got {len(arg)}"
        )
    values = [
        _to_binding(elem, f"{name}[{i}]", element_types[i], table)
        for i, elem in enumerate(arg)
    ]
    return md.Tuple(name=name, values=values)


def _native_struct_type(value: Any) -> Optional[type]:
    """Return the native_struct class a value or annotation represents, else None."""
    if value is None or value is inspect.Parameter.empty:
        return None
    if isinstance(value, type):
        return value if hasattr(value, "_struct_type") else None
    value_type = type(value)
    return value_type if hasattr(value_type, "_struct_type") else None


# ---------------------------------------------------------------------------
# Signature -> metadata: parameter / return / arg-index helpers
# ---------------------------------------------------------------------------


def _rectify_runtime_params(
    signature: inspect.Signature, args: Any, kwonlyargs: Any
) -> Iterator[Tuple[inspect.Parameter, Any, bool]]:
    """Yield ``(parameter, value, is_constexpr)`` for every top-level signature
    param, in order.

    Binds the call args to the signature and applies defaults. A compile-time
    ``Constexpr`` param whose value is a representable scalar (``None`` / ``int``
    / ``bool`` / ``float``) is NOT dropped -- it is yielded with
    ``is_constexpr=True`` so ``_to_binding`` pins it as a top-level ``Const`` /
    ``Unit`` (the baked literal). Such a Const then gets ``abi_arg_index = None``
    and ``ir_arg_index = None`` from ``_assign_arg_indices``: it is recorded in
    the metadata calling convention but forwarded to neither the ABI wrapper nor
    the kernel (it is baked in). A non-scalar constexpr (a tuple, a type, a CuTe
    layout, ...) has no metadata ``Const`` representation, so it is dropped (pure
    compile-time specialization, as it always was). The yielded parameters and
    values stay aligned.
    """
    bound = signature.bind_partial(*args, **kwonlyargs)
    bound.apply_defaults()
    for index, (name, parameter) in enumerate(signature.parameters.items()):
        is_constexpr = is_arg_annotation_constexpr(
            parameter.annotation, name, index, None
        )
        value = bound.arguments[name]
        if is_constexpr and not _is_const_representable(value):
            continue
        yield parameter, value, is_constexpr


def _return_binding(return_annotation: Any, table: _DimSymbolTable) -> "md.Binding":
    """Map a function's return annotation to its logical metadata return type.

    A missing / ``None`` / ``NoneType`` annotation is void (``Unit``). Otherwise
    the return has no runtime value, so it is dispatched on the annotation alone
    through ``_to_binding``: the empty sentinel skips its value-driven branches so
    the annotation path runs (e.g. a scalar Numeric -> ``Var``), reusing the same
    type-to-binding mapping as parameters.
    """
    if (
        return_annotation is inspect.Signature.empty
        or return_annotation is None
        or return_annotation is type(None)
    ):
        return md.Unit()
    # The return is dispatched on its annotation alone (an empty-sentinel value).
    # `_to_binding`'s composite / value-dependent branches (tuple, NamedTuple,
    # dataclass, cute algebra) would index that sentinel and crash. A composite
    # return is not a representable metadata return anyway -- the ABIs carry only
    # void or a scalar -- so reject it up front with a clear message.
    if (
        is_cute_algebra_type(return_annotation)
        or get_origin(return_annotation) is tuple
        or hasattr(return_annotation, "_fields")  # NamedTuple
        or (isinstance(return_annotation, type) and is_dataclass(return_annotation))
    ):
        raise DSLRuntimeError(
            f"Unsupported return annotation {return_annotation!r}: a kernel "
            f"metadata return must be void or a scalar; composite returns "
            f"(tuple / dataclass / cute algebra) are not representable."
        )
    return _to_binding(inspect.Parameter.empty, "", return_annotation, table)


def _assign_arg_indices(params: list) -> None:
    """Assign each binding's two argument indices from the user's signature.
    Both are the *generator's* to produce; the compiler only consumes them and
    must never re-derive or hardcode them.

    ``ir_arg_index`` -- the IR-function (kernel C-interface) argument index.
    Walks in declaration order (recursing into tuples) handing a running index
    to every forwarded leaf (Var / Tensor / Stream / Pointer / EnvStream).
    Stays ``None`` for what feeds no kernel arg: a baked ``Constexpr`` (-> Const),
    a void Unit, a Shape (binds symbols), and the structural tuple itself.

    ``abi_arg_index`` -- the slot index in the ABI call surface. TOP-LEVEL
    params only: each occupies one slot (a Tuple is a single slot; its elements
    stay ``None`` and are located by tree order within that slot's sub-array)
    EXCEPT ``EnvStream`` (stream fetched out-of-band), a top-level ``Const`` (a
    baked value), and a top-level ``Unit`` (a baked void / absent optional) --
    none occupy an ABI slot.
    """
    ir = 0
    abi = 0

    def visit_ir(binding: Any) -> None:
        nonlocal ir
        if isinstance(binding, md.Tuple):
            for elem in binding.values:
                visit_ir(elem)
        elif isinstance(
            binding, (md.Var, md.Tensor, md.Stream, md.Pointer, md.EnvStream)
        ):
            binding.ir_arg_index = ir
            ir += 1
        elif isinstance(binding, (md.Const, md.Shape, md.Unit)):
            # Const / Shape / Unit forward no kernel argument -- a baked
            # constant, a symbol-binding shape, or void -- so they get no
            # ir_arg_index and do not advance the counter.
            pass
        else:
            # Fail loudly on a binding type added later but not classified here,
            # rather than silently dropping its ir_arg_index.
            raise ValueError(
                f"_assign_arg_indices: unexpected binding type {type(binding).__name__}"
            )

    for param in params:
        visit_ir(param)
        # These three top-level bindings occupy NO ABI slot -- they stay
        # abi_arg_index=None, and the data-driven wrapper/Executor skip any param
        # lacking one, so the ABI surface is exactly the abi-bearing params:
        #   * EnvStream -- its stream is fetched out-of-band.
        #   * Const     -- a baked compile-time value (recorded, not forwarded).
        #   * Unit      -- a baked void / absent optional (Unit is just a Const
        #                  whose value is "nothing"), so it is treated the same.
        if not isinstance(param, (md.EnvStream, md.Const, md.Unit)):
            param.abi_arg_index = abi
            abi += 1


# ---------------------------------------------------------------------------
# Public entry points
# ---------------------------------------------------------------------------


def populate_function_metadata(
    fn: "md.FunctionMetadata",
    *,
    function_name: str,
    signature: inspect.Signature,
    args: Any,
    kwonlyargs: Any,
    display_name: Optional[str] = None,
) -> None:
    """Populate ``fn`` in place from a live CuTe DSL kernel signature.

    Use with ``FunctionMetadataList.emplace()`` to avoid the deep clone that
    ``list.append(FunctionMetadata(...))`` would incur::

        fn = artifact.metadata.emplace()
        populate_function_metadata(fn, function_name=..., signature=..., ...)
    """
    # Build all new field values locally before touching ``fn``. If any
    # conversion raises, ``fn`` stays in its prior state rather than being left
    # half-converted (e.g. a populated ``dim_symbol_table`` with stale ``params``).
    table = _DimSymbolTable()
    new_params = [
        _to_binding(
            value,
            parameter.name,
            parameter.annotation,
            table,
            is_constexpr=is_constexpr,
        )
        for parameter, value, is_constexpr in _rectify_runtime_params(
            signature, args, kwonlyargs
        )
    ]
    # The generator produces both argument-index maps (metadata -> IR and
    # metadata -> ABI slot) from the user's signature. The compiler only
    # consumes `ir_arg_index` / `abi_arg_index`; it never re-derives them.
    _assign_arg_indices(new_params)
    new_symbols = table.symbols
    # The function's logical return type, taken from the signature: void (no
    # annotation / -> None) is Unit, a scalar return is a Var. This metadata
    # records the logical calling convention; the machine-ABI return (e.g. a
    # CUDA status code) is the wrapper's separate realization, not modeled here.
    new_ret = _return_binding(signature.return_annotation, table)

    fn.symbol_name = function_name
    fn.display_name = display_name or function_name
    fn.dim_symbol_table.clear()
    for symbol in new_symbols:
        fn.dim_symbol_table.append(symbol)
    fn.params.clear()
    for param in new_params:
        fn.params.append(param)
    fn.ret = new_ret


def build_function_metadata(
    *,
    function_name: str,
    signature: inspect.Signature,
    args: Any,
    kwonlyargs: Any,
    display_name: Optional[str] = None,
) -> "md.FunctionMetadata":
    """Build a fresh ``FunctionMetadata`` from a live CuTe DSL kernel signature.

    Convenience for one-off use; for population destined for a list slot prefer
    ``populate_function_metadata`` + ``FunctionMetadataList.emplace()``.
    """
    fn = md.FunctionMetadata()
    populate_function_metadata(
        fn,
        function_name=function_name,
        signature=signature,
        args=args,
        kwonlyargs=kwonlyargs,
        display_name=display_name,
    )
    return fn
