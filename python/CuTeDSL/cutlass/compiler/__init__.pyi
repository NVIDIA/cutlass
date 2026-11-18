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

"""Compile, inspect, serialize, and execute CUTLASS compilation artifacts.

The public API models a compilation pipeline from CuTe-dialect MLIR through
native object code. Metadata classes describe the callable interface carried
alongside each artifact; they do not hold runtime argument values.
"""

from collections.abc import Iterable, Iterator, Mapping, Sequence
import enum
from typing import Literal, TypeAlias, overload

__all__: list[str]

class ArtifactType(enum.Enum):
    """Identify the program-payload representation at a compilation stage."""

    none = 0
    """No artifact or no next pipeline stage."""

    PreCompiledMlir = 1
    """MLIR before the configured MLIR pass pipeline.

    This is typically original front-end output, such as IR containing CuTe
    dialect operations.
    """

    CompiledMlir = 2
    """MLIR produced by the configured MLIR pass pipeline.

    It is ready for final lowering and translation to LLVM IR.
    """

    LlvmIr = 3
    """An LLVM IR module."""

    Object = 4
    """A native object file containing compiled host and/or device code."""

    Ptx = 5
    """NVIDIA PTX assembly for Device code."""

    LtoIr = 6
    """A binary CUDA Device LTO IR container."""

class TargetKind(enum.Enum):
    """Identify whether code targets the host, device, or both."""

    Host = 0
    """Host (CPU) code only."""

    Device = 1
    """Device (GPU) code only."""

    Heterogeneous = 2
    """Both host and device code."""

class DTypeCode(enum.Enum):
    """Identify the encoding family of a metadata scalar or tensor cell.

    The numeric values are stable wire-format values matching the
    corresponding DLPack data-type codes where applicable.
    """

    Int = 0
    """Signed integer encoding."""

    UInt = 1
    """Unsigned integer encoding."""

    Float = 2
    """IEEE-style floating-point encoding."""

    BFloat = 4
    """Brain floating-point encoding."""

    Bool = 6
    """Boolean encoding."""

    Handle = 3
    """Opaque handle encoding."""

    Float8E5M2 = 12
    """8-bit float with five exponent and two mantissa bits."""

    Float8E4M3FN = 10
    """Finite-only 8-bit float with four exponent and three mantissa bits."""

    Float8E8M0FNU = 14
    """Finite-only unsigned 8-bit exponent encoding."""

    Float6E2M3FN = 15
    """Finite-only 6-bit float with two exponent and three mantissa bits."""

    Float6E3M2FN = 16
    """Finite-only 6-bit float with three exponent and two mantissa bits."""

    Float4E2M1FN = 17
    """Finite-only 4-bit float with two exponent and one mantissa bit."""

class AddressSpace(enum.Enum):
    """Identify the LLVM NVPTX address space of a pointer."""

    Generic = 0
    """Generic address space."""

    Global = 1
    """Global device-memory address space."""

    Shared = 3
    """Per-thread-block shared-memory address space."""

    Constant = 4
    """Read-only constant-memory address space."""

    Local = 5
    """Per-thread local-memory address space."""

    Tensor = 6
    """Tensor-memory address space."""

    SharedCluster = 7
    """Cluster-visible shared-memory address space."""

class BindingTypeId(enum.Enum):
    """Identify the concrete metadata :class:`Binding` subclass."""

    Var = 0
    """A runtime scalar or handle variable."""

    Const = 1
    """A scalar value pinned at specialization time."""

    Shape = 2
    """A recursive tuple tree of shape-dimension expressions."""

    Tensor = 3
    """Tensor metadata and data-pointer constraints."""

    Stream = 4
    """A caller-supplied CUDA stream handle."""

    EnvStream = 5
    """A CUDA stream fetched from the execution environment."""

    Pointer = 6
    """A bare pointer with an address space."""

    Unit = 7
    """A void or no-value placeholder."""

    Tuple = 8
    """An ordered aggregate of nested bindings."""

    CustomType = 9
    """A Python object that implements the CustomType protocol."""

class Abi(enum.Enum):
    """Identify the calling convention emitted for a compiled function.

    Prefer :attr:`TvmFfi` for application code and public integrations when it
    supports the required interface. :attr:`CutlassCall` is a private, unstable
    implementation ABI with no compatibility guarantee.
    """

    Tbd = 0
    """ABI not yet locked; the default unresolved value.

    Host and Heterogeneous lowering replace ``Tbd`` with a concrete wrapper
    ABI. Device artifacts retain it because direct CUDA device functions do not
    use either host wrapper ABI.
    """

    TvmFfi = 1
    """Preferred when the TVM-FFI packed-function interface fits the use case."""

    CutlassCall = 2
    """Private, unstable ``cutlass_call_<symbol>(void **args)`` ABI.

    This implementation ABI has no compatibility guarantee."""

class DType:
    """Describe a scalar or tensor-cell encoding.

    Constructing without arguments creates ``int32`` with one lane. Pass
    ``code``, ``bits``, and optionally ``lanes`` for another encoding. Field
    order and widths match DLPack's ``DLDataType``.

    :param code: Encoding family.
    :param bits: Bits per lane.
    :param lanes: Vector lane count; defaults to one.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, code: DTypeCode, bits: int, lanes: int = 1) -> None: ...
    @property
    def code(self) -> DTypeCode:
        """Encoding family used to interpret this descriptor."""
        ...

    @code.setter
    def code(self, value: DTypeCode, /) -> None: ...
    @property
    def bits(self) -> int:
        """Number of bits in each lane."""
        ...

    @bits.setter
    def bits(self, value: int, /) -> None: ...
    @property
    def lanes(self) -> int:
        """Number of vector lanes."""
        ...

    @lanes.setter
    def lanes(self, value: int, /) -> None: ...
    @staticmethod
    def int8() -> DType:
        """Return a signed 8-bit integer descriptor."""
        ...

    @staticmethod
    def int16() -> DType:
        """Return a signed 16-bit integer descriptor."""
        ...

    @staticmethod
    def int32() -> DType:
        """Return a signed 32-bit integer descriptor."""
        ...

    @staticmethod
    def int64() -> DType:
        """Return a signed 64-bit integer descriptor."""
        ...

    @staticmethod
    def uint8() -> DType:
        """Return an unsigned 8-bit integer descriptor."""
        ...

    @staticmethod
    def uint16() -> DType:
        """Return an unsigned 16-bit integer descriptor."""
        ...

    @staticmethod
    def uint32() -> DType:
        """Return an unsigned 32-bit integer descriptor."""
        ...

    @staticmethod
    def uint64() -> DType:
        """Return an unsigned 64-bit integer descriptor."""
        ...

    @staticmethod
    def float16() -> DType:
        """Return an IEEE 16-bit floating-point descriptor."""
        ...

    @staticmethod
    def float32() -> DType:
        """Return an IEEE 32-bit floating-point descriptor."""
        ...

    @staticmethod
    def float64() -> DType:
        """Return an IEEE 64-bit floating-point descriptor."""
        ...

    @staticmethod
    def bfloat16() -> DType:
        """Return a 16-bit brain floating-point descriptor."""
        ...

    @staticmethod
    def bool_() -> DType:
        """Return a one-bit Boolean descriptor."""
        ...

    @staticmethod
    def handle(bits: int = 64) -> DType:
        """Return an opaque-handle descriptor with the requested bit width."""
        ...

    @staticmethod
    def float8_e5m2() -> DType:
        """Return an ``float8_e5m2`` descriptor."""
        ...

    @staticmethod
    def float8_e4m3fn() -> DType:
        """Return a finite-only ``float8_e4m3fn`` descriptor."""
        ...

    @staticmethod
    def float8_e8m0fnu() -> DType:
        """Return a finite-only unsigned ``float8_e8m0fnu`` descriptor."""
        ...

    @staticmethod
    def float6_e2m3fn() -> DType:
        """Return a finite-only ``float6_e2m3fn`` descriptor."""
        ...

    @staticmethod
    def float6_e3m2fn() -> DType:
        """Return a finite-only ``float6_e3m2fn`` descriptor."""
        ...

    @staticmethod
    def float4_e2m1fn() -> DType:
        """Return a finite-only ``float4_e2m1fn`` descriptor."""
        ...

    @staticmethod
    def from_string(s: str) -> DType:
        """Parse a canonical lane-one dtype name.

        This is the inverse of :func:`str` for descriptors with one lane;
        vector suffixes such as ``x4`` are not accepted.

        :param s: Name such as ``"int32"``, ``"float8_e5m2"``, or ``"bool"``.
        :returns: The corresponding descriptor.
        :raises ValueError: If ``s`` is not a recognized lane-one dtype.
        """
        ...

    def get_ctype(self) -> type:
        """Return the matching standard :mod:`ctypes` scalar class.

        :raises ValueError: If the dtype is multi-lane or has no standard
            ``ctypes`` representation, including float16, bfloat, handle, and
            other low-precision float encodings.
        """
        ...

    def __str__(self) -> str: ...
    def __repr__(self) -> str: ...

class Binding:
    """Base class for one slot in a function calling convention.

    Bindings describe the type and placement of arguments or results, not
    their runtime values. Instances are normally one of the concrete metadata
    classes such as :class:`Var`, :class:`Tensor`, or :class:`Tuple`.
    """

    @property
    def type_id(self) -> BindingTypeId:
        """Concrete binding type tag."""
        ...

    @property
    def name(self) -> str:
        """Calling-convention slot name, or an empty string when unnamed."""
        ...

    @name.setter
    def name(self, value: str, /) -> None: ...
    @property
    def ir_arg_index(self) -> int | None:
        """Index of the lowered kernel argument fed by this binding.

        ``None`` means the binding does not feed one kernel argument, as for a
        baked :class:`Const`, a :class:`Unit`, or a structural :class:`Tuple`
        container. A :class:`Shape` also carries ``None`` here because each of
        its dynamic leaves is independently wired to a lowered scalar kernel
        argument by internal per-leaf metadata.
        """
        ...

    @ir_arg_index.setter
    def ir_arg_index(self, value: int | None) -> None: ...
    @property
    def abi_arg_index(self) -> int | None:
        """Index of this top-level binding in the caller's ABI arguments.

        A top-level :class:`Tuple` or :class:`Shape` occupies one ABI slot.
        Tuple children are addressed by position within the nested array;
        Shape leaves are addressed by position in its depth-first flat
        ``int64`` buffer. Tuple children and Shape leaves do not carry their
        own ``abi_arg_index``.
        Top-level ``EnvStream``, ``Const``, and ``Unit`` bindings occupy no
        caller-supplied slot.
        """
        ...

    @abi_arg_index.setter
    def abi_arg_index(self, value: int | None) -> None: ...
    def __repr__(self) -> str: ...

class DimSymbol:
    """Describe a named runtime dimension extent.

    A function's :attr:`FunctionMetadata.dim_symbol_table` owns these symbols.
    Tensor and shape dimensions refer to them by :class:`SymbolId`. A TVM-FFI
    wrapper binds the first occurrence, enforces its constraints, and requires
    later occurrences to match. CutlassCall interprets native argument storage
    from the metadata without dynamically checking these constraints.

    Constructing without arguments creates an empty/default symbol.

    :param name: Diagnostic name such as ``"M"`` or ``"N"``.
    :param bits: Runtime ABI width, normally 32 or 64.
    :param divisibility: Optional declared constraint ``value % N == 0``;
        TVM-FFI wrappers enforce it dynamically.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(
        self, name: str, bits: int = 64, divisibility: int | None = None
    ) -> None: ...
    @property
    def name(self) -> str:
        """Human-readable dimension name; it need not be unique."""
        ...

    @name.setter
    def name(self, value: str, /) -> None: ...
    @property
    def bits(self) -> int:
        """Runtime ABI width of the extent, normally 32 or 64 bits."""
        ...

    @bits.setter
    def bits(self, value: int, /) -> None: ...
    @property
    def divisibility(self) -> int | None:
        """Declared runtime divisibility, or ``None`` for no constraint."""
        ...

    @divisibility.setter
    def divisibility(self, value: int | None) -> None: ...

class DimSymbolList:
    """Mutable sequence of :class:`DimSymbol` values.

    Construct an empty list, copy another ``DimSymbolList``, or copy values
    from any iterable. Integer indexing accepts negative indices; slices
    produce another ``DimSymbolList``. When obtained from
    :attr:`FunctionMetadata.dim_symbol_table`, mutations update the owning
    metadata object. Indexed elements are live references; replacing or
    structurally changing the list may invalidate saved references.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, value: DimSymbolList, /) -> None: ...
    @overload
    def __init__(self, value: Iterable[DimSymbol], /) -> None: ...
    def __len__(self) -> int: ...
    def __bool__(self) -> bool: ...
    def __repr__(self) -> str: ...
    def __iter__(self) -> Iterator[DimSymbol]: ...
    @overload
    def __getitem__(self, index: int, /) -> DimSymbol: ...
    @overload
    def __getitem__(self, index: slice, /) -> DimSymbolList: ...
    def clear(self) -> None:
        """Remove all symbols from the list."""
        ...

    def append(self, value: DimSymbol, /) -> None:
        """Append a copy of ``value``."""
        ...

    def insert(self, index: int, value: DimSymbol, /) -> None:
        """Insert a copy of ``value`` before ``index``."""
        ...

    def pop(self, index: int = -1) -> DimSymbol:
        """Remove and return the symbol at ``index``.

        :raises IndexError: If the list is empty or ``index`` is out of range.
        """
        ...

    def extend(self, values: DimSymbolList, /) -> None:
        """Append copies of all symbols in ``values``."""
        ...

    @overload
    def __setitem__(self, index: int, value: DimSymbol, /) -> None: ...
    @overload
    def __setitem__(self, index: slice, value: DimSymbolList, /) -> None: ...
    @overload
    def __delitem__(self, index: int, /) -> None: ...
    @overload
    def __delitem__(self, index: slice, /) -> None: ...

class SymbolId:
    """Refer to a runtime dimension symbol by table index.

    ``value`` indexes the owning function's
    :attr:`FunctionMetadata.dim_symbol_table`. Constructing without arguments
    is equivalent to ``SymbolId(0)``. Symbol IDs compare and hash by value.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, value: int = 0) -> None: ...
    @property
    def value(self) -> int:
        """Zero-based index into the owning function's symbol table."""
        ...

    @value.setter
    def value(self, value: int, /) -> None: ...
    def __eq__(self, value: SymbolId, /) -> bool: ...  # type: ignore[override]
    def __ne__(self, value: SymbolId, /) -> bool: ...  # type: ignore[override]
    def __hash__(self) -> int: ...

class Var(Binding):
    """Describe a runtime scalar, opaque handle, or pointer-like variable.

    TVM-FFI wrappers dynamically validate scalar type, range, and integer
    divisibility. CutlassCall loads native scalar storage according to the
    metadata without performing those dynamic checks.

    Constructing without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    :param dtype: Scalar storage type at the ABI boundary.
    :param element_dtype: Logical computation type when it differs from
        ``dtype``; ``None`` means they are the same.
    :param divisibility: Optional declared constraint ``value % N == 0``. It
        applies only to signed or unsigned integer variables and is enforced
        dynamically by TVM-FFI wrappers.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(
        self,
        name: str,
        dtype: DType,
        element_dtype: DType | None = None,
        divisibility: int | None = None,
    ) -> None: ...
    @property
    def dtype(self) -> DType:
        """Scalar storage type at the ABI boundary."""
        ...

    @dtype.setter
    def dtype(self, value: DType, /) -> None: ...
    @property
    def element_dtype(self) -> DType | None:
        """Logical computation type when different from :attr:`dtype`."""
        ...

    @element_dtype.setter
    def element_dtype(self, value: DType | None) -> None: ...
    @property
    def divisibility(self) -> int | None:
        """Declared integer divisibility, or ``None`` for no constraint."""
        ...

    @divisibility.setter
    def divisibility(self, value: int | None) -> None: ...

class Const(Binding):
    """Describe a scalar pinned at specialization time.

    ``value`` stores a raw 64-bit bit pattern interpreted according to
    ``dtype``. The value is baked into the kernel rather than forwarded as a
    kernel argument. A TVM-FFI wrapper validates tuple-contained constants
    against the pinned value; the CutlassCall wrapper drops them unchecked.

    Constructing without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    :param dtype: Type used to interpret ``value``.
    :param value: Raw bit pattern for the constant.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, name: str, dtype: DType, value: int) -> None: ...
    @property
    def dtype(self) -> DType:
        """Type used to interpret the raw constant value."""
        ...

    @dtype.setter
    def dtype(self, value: DType, /) -> None: ...
    @property
    def value(self) -> int:
        """Raw bit pattern holding the pinned constant."""
        ...

    @value.setter
    def value(self, value: int, /) -> None: ...
    def as_signed(self) -> int:
        """Interpret :attr:`value` as a signed 64-bit integer."""
        ...

    def as_unsigned(self) -> int:
        """Interpret :attr:`value` as an unsigned 64-bit integer."""
        ...

    def as_bool(self) -> bool:
        """Interpret :attr:`value` as a Boolean."""
        ...

    def as_float(self) -> float:
        """Decode the bit pattern using the configured floating-point dtype."""
        ...

class Dim:
    """Represent one shape or stride dimension.

    Construct an empty/default dimension, a compile-time constant extent from
    ``int``, or a reference to a runtime :class:`DimSymbol` from
    :class:`SymbolId`.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, const_extent: int) -> None: ...
    @overload
    def __init__(self, symbol: SymbolId) -> None: ...
    @property
    def value(self) -> int | SymbolId:
        """Constant extent or runtime-symbol reference."""
        ...

    @value.setter
    def value(self, value: int | SymbolId, /) -> None: ...
    @property
    def is_const(self) -> bool:
        """Whether :attr:`value` is a compile-time integer extent."""
        ...

    @property
    def is_symbol(self) -> bool:
        """Whether :attr:`value` refers to a runtime dimension symbol."""
        ...

class DimList:
    """Mutable sequence of :class:`Dim` values.

    Construct an empty list, copy another ``DimList``, or copy values from any
    iterable. Integer indexing accepts negative indices; slices produce
    another ``DimList``. Lists returned by tensor properties are live views:
    mutating them updates the owning metadata object. Indexed elements are live
    references; replacing or structurally changing the list may invalidate
    saved references.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, value: DimList, /) -> None: ...
    @overload
    def __init__(self, value: Iterable[Dim], /) -> None: ...
    def __len__(self) -> int: ...
    def __bool__(self) -> bool: ...
    def __repr__(self) -> str: ...
    def __iter__(self) -> Iterator[Dim]: ...
    @overload
    def __getitem__(self, index: int, /) -> Dim: ...
    @overload
    def __getitem__(self, index: slice, /) -> DimList: ...
    def clear(self) -> None:
        """Remove all dimensions from the list."""
        ...

    def append(self, value: Dim, /) -> None:
        """Append a copy of ``value``."""
        ...

    def insert(self, index: int, value: Dim, /) -> None:
        """Insert a copy of ``value`` before ``index``."""
        ...

    def pop(self, index: int = -1) -> Dim:
        """Remove and return the dimension at ``index``.

        :raises IndexError: If the list is empty or ``index`` is out of range.
        """
        ...

    def extend(self, values: DimList, /) -> None:
        """Append copies of all dimensions in ``values``."""
        ...

    @overload
    def __setitem__(self, index: int, value: Dim, /) -> None: ...
    @overload
    def __setitem__(self, index: slice, value: DimList, /) -> None: ...
    @overload
    def __delitem__(self, index: int, /) -> None: ...
    @overload
    def __delitem__(self, index: slice, /) -> None: ...

_ShapeInputNode: TypeAlias = Dim | SymbolId | int | Sequence["_ShapeInputNode"]
_ShapeSnapshotNode: TypeAlias = Dim | tuple["_ShapeSnapshotNode", ...]

class Shape(Binding):
    """Describe a recursive tuple tree of shape dimensions.

    ``dims`` is a tuple/list tree whose leaves are constant ``int`` values,
    :class:`SymbolId` references, or explicit :class:`Dim` values. Every
    container is part of the shape profile, including an empty nested
    container. Inputs are copied, and the internal tree-node and per-leaf
    kernel-wiring types are intentionally not exposed in Python.

    A top-level Shape occupies one ABI slot pointing to storage with one signed
    64-bit value per entry in :attr:`leaves`. The buffer contains every leaf in
    depth-first, left-to-right order, including compile-time constants.
    CutlassCall does not validate this buffer and forwards only dynamic leaves
    with kernel-argument wiring; constant leaves are not read. TVM-FFI validates
    the flattened values and symbol constraints. The recursive profile itself
    is metadata-only and must be checked before flattening.

    :param name: Calling-convention slot name.
    :param dims: Complete recursive shape profile. The outer value and every
        branch must be a tuple or list.
    :raises TypeError: If a branch or leaf has an unsupported Python type.
    :raises ValueError: If the metadata tree-depth limit is exceeded.
    :raises OverflowError: If an integer leaf is outside signed 64-bit range.
    """

    def __init__(
        self,
        name: str,
        dims: Sequence[_ShapeInputNode],
    ) -> None: ...
    @property
    def dims(self) -> tuple[_ShapeSnapshotNode, ...]:
        """Recursive tuple of detached :class:`Dim` snapshots.

        Mutating a returned Dim does not modify this Shape.
        """
        ...

    @property
    def leaves(self) -> tuple[Dim, ...]:
        """Detached Dim snapshots in depth-first, left-to-right ABI order."""
        ...

    @property
    def _leaf_ir_arg_indices(self) -> tuple[int | None, ...]:
        """Internal frontend view of the lowered kernel-argument wiring."""
        ...

    def _set_leaf_ir_arg_indices(self, indices: Sequence[int | None]) -> None:
        """Atomically install the complete frontend-generated Shape leaf wiring.

        Internal compiler API; constant leaves must map to ``None``.
        """
        ...

class Tensor(Binding):
    """Describe a tensor argument or result.

    Metadata records the tensor's ABI dtype, logical element dtype, shape,
    optional strides, data-pointer address space, DLPack device kind, and an
    optional alignment constraint. It does not hold a runtime data pointer.
    TVM-FFI wrappers dynamically validate the DLTensor's dtype, dimensions,
    device kind, and alignment. CutlassCall expects a native aggregate layout,
    which :meth:`ObjectArtifact.get_c_header` declares for top-level tensor
    parameters, and performs no dynamic constraint checks.
    Constructing without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    :param shape: Constant extents, :class:`SymbolId` references, or
        :class:`Dim` values.
    :param dtype: Cell storage type at the ABI boundary.
    :param element_dtype: Logical computation type when it differs from
        ``dtype``.
    :param strides: Explicit strides, or ``None`` for contiguous row-major
        layout.
    :param data_address_space: Address space of the runtime data pointer.
    :param device_kind: Declared DLPack ``DLDeviceType`` integer.
    :param data_alignment: Declared data-pointer alignment in bytes, or
        ``None`` for no constraint.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(
        self,
        name: str,
        shape: Iterable[Dim | SymbolId | int],
        dtype: DType,
        element_dtype: DType | None = None,
        strides: Iterable[Dim | SymbolId | int] | None = None,
        data_address_space: AddressSpace = AddressSpace.Generic,
        device_kind: int = 0,
        data_alignment: int | None = None,
    ) -> None: ...
    @property
    def data_address_space(self) -> AddressSpace:
        """Address space of the tensor's runtime data pointer."""
        ...

    @data_address_space.setter
    def data_address_space(self, value: AddressSpace, /) -> None: ...
    @property
    def shape(self) -> DimList:
        """Live, mutable shape dimensions; an empty list means rank zero."""
        ...

    @shape.setter
    def shape(self, value: DimList, /) -> None: ...
    @property
    def dtype(self) -> DType:
        """Cell storage type at the ABI boundary."""
        ...

    @dtype.setter
    def dtype(self, value: DType, /) -> None: ...
    @property
    def element_dtype(self) -> DType | None:
        """Logical computation type when different from :attr:`dtype`."""
        ...

    @element_dtype.setter
    def element_dtype(self, value: DType | None) -> None: ...
    @property
    def strides(self) -> DimList:
        """Live, mutable strides.

        An empty list represents contiguous row-major layout. Otherwise the
        stride rank should match :attr:`shape`.
        """
        ...

    @strides.setter
    def strides(self, value: DimList, /) -> None: ...
    @property
    def device_kind(self) -> int:
        """Declared DLPack device-type integer, such as CPU 1 or CUDA 2."""
        ...

    @device_kind.setter
    def device_kind(self, value: int, /) -> None: ...
    @property
    def data_alignment(self) -> int | None:
        """Declared data-pointer alignment in bytes, or ``None``."""
        ...

    @data_alignment.setter
    def data_alignment(self, value: int | None) -> None: ...

class Stream(Binding):
    """Describe a CUDA stream handle supplied explicitly by the caller.

    The binding carries only the inherited :attr:`Binding.name`. Constructing
    without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, name: str) -> None: ...

class EnvStream(Binding):
    """Describe a CUDA stream obtained from the execution environment.

    An environment stream is fetched out of band and occupies no caller ABI
    slot. It is omitted from a function's displayed FFI signature. The binding
    carries only the inherited :attr:`Binding.name`. Constructing without
    arguments creates a default metadata value.

    :param name: Metadata name for the environment-provided stream.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, name: str) -> None: ...

class Pointer(Binding):
    """Describe a bare pointer argument with an address space.

    Constructing without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    :param address_space: Address space of the runtime pointer.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(
        self, name: str, address_space: AddressSpace = AddressSpace.Generic
    ) -> None: ...
    @property
    def address_space(self) -> AddressSpace:
        """Address space of the runtime pointer."""
        ...

    @address_space.setter
    def address_space(self, value: AddressSpace, /) -> None: ...

class Unit(Binding):
    """Represent void, ``None``, or an otherwise absent value.

    ``Unit`` commonly describes a void function return. Constructing without
    arguments creates a default metadata value.

    :param name: Optional metadata name for the no-value slot.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, name: str) -> None: ...

class BindingList:
    """Owning mutable sequence of polymorphic :class:`Binding` values.

    Assignment and :meth:`append` deep-copy their input, so subsequent changes
    to the original binding do not affect the list. Integer indexing accepts
    negative indices and returns a live reference to the stored concrete
    binding. Out-of-range indexing, assignment, or deletion raises
    :class:`IndexError`. Assignment and :meth:`append` raise
    :class:`ValueError` if the inserted binding would exceed the maximum
    metadata tree depth of 64.
    """

    def __init__(self) -> None: ...
    def __len__(self) -> int: ...
    def __bool__(self) -> bool: ...
    def __getitem__(self, index: int, /) -> Binding: ...
    def __setitem__(self, index: int, value: Binding, /) -> None:
        """Replace an element with an owning, depth-checked copy of ``value``."""
        ...
    def __delitem__(self, index: int, /) -> None: ...
    def append(self, value: Binding, /) -> None:
        """Append an owning, depth-checked copy of ``value``."""
        ...

    def clear(self) -> None:
        """Remove all bindings from the list."""
        ...

    def __iter__(self) -> Iterator[Binding]: ...

class Tuple(Binding):
    """Describe an ordered aggregate of nested metadata bindings.

    Tuples model dataclass-like aggregate inputs and composite results. A
    top-level tuple occupies one ABI slot; its elements are packed in metadata
    order and nested tuples recurse. Constructor inputs are deep-copied, and
    the collection cannot be resized or reordered after construction.
    Constructing without arguments creates a default metadata value.

    :param name: Calling-convention slot name.
    :param values: Nested bindings in aggregate order.
    :raises ValueError: If the combined Tuple/Shape tree exceeds the maximum
        metadata tree depth of 64.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, name: str, values: Iterable[Binding]) -> None: ...
    @property
    def values(self) -> tuple[Binding, ...]:
        """Read-only tuple of live nested binding references.

        Non-structural fields on a returned binding remain mutable and update
        this Tuple.
        """
        ...

class CustomType(Binding):
    """Binding for a Python object that cannot be described by other bindings.

    The bindings in ``values`` describe the flat (non-structural) elements
    supplied by the DSL at call time.  Only :class:`Var`, :class:`Const`,
    :class:`Tensor`, :class:`Pointer`, :class:`Stream`, and :class:`Unit` are
    accepted as elements; :class:`Tuple`, :class:`Shape`, and
    :class:`CustomType` are rejected.  Constructor inputs are deep-copied and
    the collection cannot be resized or reordered after construction.
    Constructing without arguments creates a default metadata value.

    :param id: Numeric type identifier for this CustomType binding.
    :param name: Calling-convention slot name.
    :param values: Flat non-structural bindings describing the elements.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, id: int, name: str, values: Iterable[Binding]) -> None: ...
    @property
    def id(self) -> int:
        """Numeric type identifier for this CustomType binding."""
        ...

    @id.setter
    def id(self, value: int, /) -> None: ...
    @property
    def values(self) -> tuple[Binding, ...]:
        """Read-only tuple of live nested Binding references.

        The collection cannot be resized or reordered after construction.
        """
        ...

class FunctionMetadata:
    """Describe the logical calling convention of one generated function.

    ``symbol_name`` is the canonical exported symbol used for lookup.
    ``display_name`` remains a user-facing diagnostic name.
    Parameters and the return binding are deep-copied by the constructor;
    omitting ``ret`` creates a :class:`Unit` return.

    :param symbol_name: Non-empty exported function symbol.
    :param display_name: Optional user-facing function name.
    :param params: Top-level parameters in call order.
    :param ret: Logical return binding, or ``None`` for ``Unit``.
    :param abi: Calling convention. ``Tbd`` is also retained for a direct CUDA
        device function, where no host wrapper ABI applies.
    :raises ValueError: If a parameter or return binding exceeds the maximum
        metadata tree depth of 64.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(
        self,
        symbol_name: str,
        display_name: str = "",
        params: Iterable[Binding] | None = None,
        ret: Binding | None = None,
        abi: Abi = Abi.Tbd,
    ) -> None: ...
    @property
    def symbol_name(self) -> str:
        """Canonical AOT-exported function symbol."""
        ...

    @symbol_name.setter
    def symbol_name(self, value: str, /) -> None: ...
    @property
    def display_name(self) -> str:
        """User-facing diagnostic name, or an empty string to use the symbol."""
        ...

    @display_name.setter
    def display_name(self, value: str, /) -> None: ...
    @property
    def abi(self) -> Abi:
        """Calling convention locked in for this function.

        ``Tbd`` is permitted on pre-wrapper MLIR and Device artifacts. Host
        LLVM IR, host objects, and executors require ``TvmFfi`` or
        ``CutlassCall``.
        """
        ...

    @abi.setter
    def abi(self, value: Abi, /) -> None: ...
    @property
    def dim_symbol_table(self) -> DimSymbolList:
        """Live table of runtime dimensions referenced by :class:`SymbolId`."""
        ...

    @property
    def params(self) -> BindingList:
        """Live, mutable list of top-level parameters in call order."""
        ...

    @property
    def ret(self) -> Binding:
        """Logical return binding; :class:`Unit` represents void.

        Assignment deep-copies the binding. Reading returns a live reference
        owned by this metadata object. Assignment raises :class:`ValueError`
        if the binding exceeds the maximum metadata tree depth of 64.
        """
        ...

    @ret.setter
    def ret(self, value: Binding, /) -> None: ...
    def __str__(self) -> str: ...
    def __repr__(self) -> str: ...

class FunctionMetadataList:
    """Mutable sequence of :class:`FunctionMetadata` values.

    Construct an empty list, copy another ``FunctionMetadataList``, or copy
    values from any iterable. Integer indexing accepts negative indices;
    slices produce another ``FunctionMetadataList``. A list obtained from an
    artifact is a live view whose mutations update that artifact. Indexed
    elements are live references; replacing or structurally changing the list
    may invalidate saved references.
    """

    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, value: FunctionMetadataList, /) -> None: ...
    @overload
    def __init__(self, value: Iterable[FunctionMetadata], /) -> None: ...
    def __len__(self) -> int: ...
    def __bool__(self) -> bool: ...
    def __repr__(self) -> str: ...
    def __iter__(self) -> Iterator[FunctionMetadata]: ...
    @overload
    def __getitem__(self, index: int, /) -> FunctionMetadata: ...
    @overload
    def __getitem__(self, index: slice, /) -> FunctionMetadataList: ...
    def clear(self) -> None:
        """Remove all function records from the list."""
        ...

    def append(self, value: FunctionMetadata, /) -> None:
        """Append a deep copy of ``value``."""
        ...

    def insert(self, index: int, value: FunctionMetadata, /) -> None:
        """Insert a deep copy of ``value`` before ``index``."""
        ...

    def pop(self, index: int = -1) -> FunctionMetadata:
        """Remove and return the function record at ``index``.

        :raises IndexError: If the list is empty or ``index`` is out of range.
        """
        ...

    def extend(self, values: FunctionMetadataList, /) -> None:
        """Append deep copies of all records in ``values``."""
        ...

    @overload
    def __setitem__(self, index: int, value: FunctionMetadata, /) -> None: ...
    @overload
    def __setitem__(self, index: slice, value: FunctionMetadataList, /) -> None: ...
    @overload
    def __delitem__(self, index: int, /) -> None: ...
    @overload
    def __delitem__(self, index: slice, /) -> None: ...
    def emplace(self) -> FunctionMetadata:
        """Append a default record in place and return a live reference.

        Mutate the returned object before growing the list again: a later
        append, insert, extend, or emplace may reallocate the underlying vector
        and invalidate the reference.
        """
        ...

class CompilationArtifact:
    """Own one compiler-produced artifact from a compilation-pipeline stage.

    Each artifact contains a stage-specific program payload (MLIR, LLVM IR,
    PTX, CUDA LTO IR, or native object-file bytes), plus possibly empty metadata
    describing its exported functions and callable interface. The Host pipeline
    ends ``LlvmIr`` → ``Object``. The Device pipeline branches after
    ``LlvmIr`` into ``Ptx`` → ``Object`` or terminal ``LtoIr``.

    :meth:`Compiler.compile_to` consumes the input wrapper; after that, only
    :attr:`is_consumed` is safe to inspect and other accessors raise
    :class:`RuntimeError`. Use the returned artifact instead.

    ``str(artifact)`` provides a human-readable debugging view of the payload;
    its exact formatting is not a stable API.
    """

    @property
    def type_name(self) -> str:
        """Pipeline-stage name such as ``"PreCompiledMlir"`` or ``"Object"``."""
        ...

    @property
    def type_id(self) -> ArtifactType:
        """Pipeline-stage identifier."""
        ...

    @property
    def target_kind(self) -> TargetKind:
        """Whether the artifact contains host code, device code, or both."""
        ...

    @property
    def is_consumed(self) -> bool:
        """Whether :meth:`Compiler.compile_to` has consumed this wrapper."""
        ...

    @property
    def metadata(self) -> FunctionMetadataList:
        """Live metadata for functions exported by this artifact."""
        ...

    @metadata.setter
    def metadata(self, value: FunctionMetadataList, /) -> None: ...
    def __repr__(self) -> str: ...
    def __str__(self) -> str:
        """Return a human-readable debugging view of the artifact payload.

        Depending on the stage, this is MLIR assembly, LLVM IR assembly, PTX,
        or native object disassembly. LtoIr returns ``""`` because its payload
        is binary. The view contains only the payload and does not include the
        separate artifact metadata collection.
        Its exact formatting is not a stable API and must not be used as a
        serialization format. Use
        :func:`serialize_compilation_artifact` to round-trip both the payload
        and metadata.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class PreCompiledMlirArtifact(CompilationArtifact):
    """Own MLIR before the configured MLIR pass pipeline.

    This is typically original front-end output, such as IR containing CuTe
    dialect operations.
    """

    @staticmethod
    def from_textual_form(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> PreCompiledMlirArtifact:
        """Parse MLIR assembly bytes into an owning artifact.

        :raises ValueError: If ``data`` is not a valid MLIR module.
        """
        ...

    @staticmethod
    def from_bitcode(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> PreCompiledMlirArtifact:
        """Parse MLIR bytecode or textual assembly into an owning artifact.

        :raises ValueError: If ``data`` is not a valid MLIR module.
        """
        ...

    def get_bitcode(self) -> bytes:
        """Serialize the owned MLIR module as bytecode.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class CompiledMlirArtifact(CompilationArtifact):
    """Own MLIR produced by the configured MLIR pass pipeline.

    It is ready for final lowering and translation to LLVM IR.
    """

    @staticmethod
    def from_textual_form(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> CompiledMlirArtifact:
        """Parse lowered MLIR assembly bytes into an owning artifact.

        :raises ValueError: If ``data`` is not a valid MLIR module.
        """
        ...

    @staticmethod
    def from_bitcode(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> CompiledMlirArtifact:
        """Parse lowered MLIR bytecode or text into an owning artifact.

        :raises ValueError: If ``data`` is not a valid MLIR module.
        """
        ...

    def get_bitcode(self) -> bytes:
        """Serialize the owned MLIR module as bytecode.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class LlvmIrArtifact(CompilationArtifact):
    """Own an LLVM IR module."""

    @staticmethod
    def from_textual_form(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> LlvmIrArtifact:
        """Parse LLVM IR assembly bytes into an owning artifact.

        :raises ValueError: If ``data`` is not valid LLVM IR assembly.
        """
        ...

    @staticmethod
    def from_bitcode(
        data: bytes,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> LlvmIrArtifact:
        """Parse LLVM bitcode into an owning artifact.

        :raises ValueError: If ``data`` is not valid LLVM bitcode.
        """
        ...

    def get_bitcode(self) -> bytes:
        """Serialize the owned LLVM module as bitcode.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class PtxArtifact(CompilationArtifact):
    """Own NVIDIA PTX assembly for Device code.

    Every instance has :attr:`TargetKind.Device`. PTX syntax is validated by
    nvPTXCompiler when the artifact is compiled to :attr:`ArtifactType.Object`.
    """

    @staticmethod
    def from_textual_form(data: bytes) -> PtxArtifact:
        """Create an owning Device artifact from PTX assembly bytes.

        Exclude any C-string terminator from ``data``.

        :raises ValueError: If ``data`` is empty or contains any NUL byte.
        """
        ...

    def get_ptx(self) -> str:
        """Return PTX assembly without a trailing NUL terminator.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

    def get_c_header(self) -> str:
        """Generate direct CUDA Device declarations from function metadata.

        Unsupported declarations are replaced by explanatory comments. The
        result is empty when the artifact carries no metadata.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class LtoIrArtifact(CompilationArtifact):
    """Own a binary CUDA Device LTO IR container.

    Every instance has :attr:`TargetKind.Device`. This is not LLVM bitcode and
    is terminal in :class:`Compiler`; pass it to nvlink or nvJitLink together
    with the calling device code. The linker must support the LTO IR container
    emitted by the producer's libNVVM. Released CUDA toolchains guarantee LTO
    IR compatibility only within a CUDA major release, with a linker version
    at least as new as the producer. Development snapshots can use incompatible
    LTO container revisions.
    """

    @staticmethod
    def from_data(data: bytes) -> LtoIrArtifact:
        """Create an owning artifact from a CUDA LTO IR container.

        :raises ValueError: If ``data`` lacks the CUDA LTO IR signature.
        """
        ...

    def get_data(self) -> bytes:
        """Return a copy of the CUDA LTO IR container.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

    def get_c_header(self) -> str:
        """Generate direct CUDA Device declarations from function metadata.

        Unsupported declarations are replaced by explanatory comments. The
        result is empty when the artifact carries no metadata.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class ObjectArtifact(CompilationArtifact):
    """Own a native object file containing compiled host and/or device code."""

    def get_data(self) -> bytes:
        """Return a copy of the raw object-file bytes.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

    def get_c_header(self) -> str:
        """Generate ABI-specific C declarations for the object's entry points.

        A device artifact emits ``extern \"C\" __device__`` declarations
        suitable for inclusion by nvcc for the scalar/pointer subset that
        :class:`FunctionMetadata` can represent exactly; unsupported device
        declarations are replaced by an explanatory comment. For
        host/heterogeneous artifacts, the generated header declares either its
        ``cutlass_call_`` entry point and aggregate argument structs or its
        ``__tvm_ffi_`` safe-call entry point, according to the ABI recorded in
        the function metadata. It is empty when the artifact carries no
        metadata; Host entries whose ABI is :attr:`Abi.Tbd` are omitted.
        Device declarations do not use a host wrapper ABI.

        Prefer TVM-FFI declarations when they support the required interface.
        CutlassCall declarations expose a private, unstable ABI with no
        compatibility guarantee.

        :raises RuntimeError: If this artifact has been consumed.
        """
        ...

class ExecutableFunction:
    """Low-level runnable function materialized by an :class:`Executor`.

    Materialization resolves the entry symbol and may eagerly load CUDA code
    on every visible device. Cache this handle for repeated calls. It keeps its
    loaded code alive and may outlive the executor that created it.
    """

    @property
    def name(self) -> str:
        """Logical function name used for lookup."""
        ...

    @property
    def entry_symbol(self) -> str:
        """External wrapper symbol invoked by :meth:`call`."""
        ...

    @property
    def ret(self) -> Binding:
        """Logical return binding; treat the returned live view as read-only."""
        ...

    @property
    def metadata(self) -> FunctionMetadata:
        """Function metadata used to pack calls; treat this live view as read-only."""
        ...

    def call(self, arg_ptrs: Sequence[int], result_addr: int = 0) -> None:
        """Invoke the function using raw addresses in metadata-parameter order.

        Prefer TVM-FFI when it supports the required interface. CutlassCall
        support exercises a private, unstable implementation ABI with no
        compatibility guarantee.

        Supply one nonzero address for every entry in ``metadata.params``.
        The executor scatters ABI-bearing parameters according to
        :attr:`Binding.abi_arg_index`; top-level ``Const`` or ``Unit`` values
        without an ABI slot still require a nonzero placeholder, which is not
        read. Every nested tuple slot must also be nonzero.

        Slot layouts depend on the binding:

        * ``Var`` points to scalar storage of at least
          ``max(1, (dtype.bits + 7) // 8)`` bytes.
        * A top-level ``Const`` is normally an ignored placeholder. A tuple
          ``Const`` points to scalar storage like ``Var``; TVM-FFI validates
          the value, while CutlassCall drops it unchecked.
        * A TVM-FFI ``Tensor`` points to a DLPack ``DLTensor``. A CutlassCall
          ``Tensor`` points to the native flat aggregate declared by the
          generated C header; no repacking or validation is performed.
        * ``Pointer`` and ``Stream`` point to storage containing a ``void *``.
        * ``Tuple`` points directly to a ``void *[N]`` sub-array in metadata
          order; nested tuples recurse.
        * ``Shape`` points to storage with one signed 64-bit value per entry in
          the binding's :attr:`Shape.leaves`, in depth-first, left-to-right
          order and including constant leaves. A Shape nested in a Tuple uses
          the same layout in its element slot. For an empty Shape, pass any
          nonzero ignored placeholder. CutlassCall does not validate the
          storage and reads only dynamic leaves with kernel-argument wiring;
          constant leaves are not read. The Executor's TVM-FFI path validates
          flattened leaf values and symbol constraints but cannot recover or
          validate the recursive profile.
        * ``EnvStream`` is unsupported by this entry point. Invoke a TVM-FFI
          safe-call wrapper directly for that binding.

        Only ``Var`` and ``Unit`` returns are supported. For ``Var``,
        ``result_addr`` must point to writable storage of at least
        ``max(1, (ret.dtype.bits + 7) // 8)`` bytes. For ``Unit``, zero is
        allowed and any supplied buffer is left untouched. CutlassCall scalar
        returns are limited to ``Bool`` or at most 32-bit ``Int``/``UInt``.

        :param arg_ptrs: Raw, nonzero argument-slot addresses.
        :param result_addr: Raw result-buffer address, or zero for ``Unit``.
        :raises RuntimeError: If metadata, argument shape, result storage,
            symbol invocation, ABI validation, or the runtime call fails.
        """
        ...

    def __repr__(self) -> str: ...

class Executor:
    """Load and execute functions from an :class:`ObjectArtifact`.

    Create an executor once per deployable artifact and reuse it. ``executor[name]``
    is shorthand for :meth:`get_executable_function`; it raises ``KeyError``
    when metadata is present but the logical name is absent. Missing metadata
    and other loading failures raise ``RuntimeError``.
    """

    @staticmethod
    def register_global_function(name: str, address: int) -> None:
        """Register a host function for future executors in this library.

        Existing executors retain their registration snapshot. Keep the address
        valid for the process lifetime. Re-registering the same name and address
        succeeds. Registered functions resolve before shared-library symbols.

        :param name: Unmangled symbol name used by generated code.
        :param address: Nonzero host function address.
        :raises RuntimeError: If the name is empty, the address is zero, or the
            name is already registered with a different address.
        """
        ...

    @staticmethod
    def from_object_artifact(
        artifact: ObjectArtifact,
        shared_lib_paths: Sequence[str] = ...,
    ) -> Executor:
        """Load an object artifact and its optional host dependencies.

        The artifact is borrowed, not consumed. The resulting executor owns
        its loaded execution environment, so it remains usable independently
        of the Python artifact object. It uses a snapshot of the registered
        global functions taken during creation.

        A TVM-FFI artifact requires the TVM-FFI runtime library. Include its
        path in ``shared_lib_paths`` unless the process already provides its
        symbols.

        :param artifact: Native object payload to load.
        :param shared_lib_paths: Libraries used to resolve external symbols.
        :returns: A loaded executor.
        :raises RuntimeError: If metadata validation, object loading, or symbol
            resolution setup fails.
        """
        ...

    @property
    def shared_lib_paths(self) -> list[str]:
        """Copy of the shared-library paths loaded with this executor."""
        ...

    def lookup_raw_symbol(self, name: str) -> int:
        """Return a raw symbol address.

        Cache the result when calling repeatedly. The address is valid only
        while this executor remains alive.

        :param name: Exact native symbol to resolve.
        :raises RuntimeError: If the symbol cannot be found.
        """
        ...

    def get_executable_function(self, name: str) -> ExecutableFunction:
        """Materialize a callable by logical function name.

        This setup operation resolves the wrapper entry point and may eagerly
        load the CUDA binary on every visible device. Cache the returned
        handle; it keeps the loaded code alive and may outlive this executor.

        :param name: :attr:`FunctionMetadata.symbol_name` to materialize.
        :raises RuntimeError: If the function, entry symbol, or device code
            cannot be loaded.
        """
        ...

    def __getitem__(self, name: str) -> ExecutableFunction: ...
    def __repr__(self) -> str: ...

class Compiler:
    """Configurable compiler for driving artifacts through the pipeline.

    The base compiler has no MLIR pass pipeline configured. Use it when a custom
    pipeline is required. For CuTe-generated MLIR, :class:`CuteCompiler` is the
    recommended entry point because it preconfigures the standard CuTe MLIR
    pipeline and Device LLVM optimization before PTX/LTO IR emission.
    It initially selects the private, unstable
    :attr:`Abi.CutlassCall` ABI, which has no compatibility guarantee. Prefer
    :attr:`Abi.TvmFfi` when it supports the required interface.

    The device target must be set explicitly before compiling a Device artifact.
    The host target is detected from the current machine when not set. The base
    compiler ABI defaults to :attr:`Abi.Tbd`. Host/Heterogeneous lowering locks
    each function's ABI; Device lowering retains it because no host wrapper is
    emitted.
    """

    def __init__(self) -> None: ...
    def set_pipeline(
        self,
        artifact_type: ArtifactType,
        pipeline: str,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> None:
        """Set the pass pipeline after a source artifact stage.

        This method records the configuration. A compilation step that consumes
        the entry is responsible for validating the pipeline string.
        The Device ``LlvmIr`` pipeline is shared by the ``Ptx`` and ``LtoIr``
        output edges.

        :param artifact_type: Source stage of the compilation step.
        :param pipeline: Pass-pipeline specification for this transition.
        :param target_kind: Target shared by the source and destination.
            Defaults to :attr:`TargetKind.Heterogeneous`.
        :raises ValueError: If ``artifact_type`` has no pass-pipeline stage or
            an enum value is invalid.
        """
        ...

    def set_base_pipeline(self, pipeline: str) -> None:
        """Set the base pipeline for the PreCompiledMlir stage.

        :param pipeline: the pipeline without any options.
        """
        ...

    @property
    def base_pipeline(self) -> str:
        """Get the base pipeline for the PreCompiledMlir stage."""
        ...

    def get_pipeline(
        self,
        artifact_type: ArtifactType,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> str:
        """Return the pass pipeline stored for ``artifact_type`` / ``target_kind``.

        :param artifact_type: Source stage whose pipeline should be retrieved.
        :param target_kind: Target associated with the pipeline. Defaults to
            :attr:`TargetKind.Heterogeneous`.
        :returns: Stored pipeline string, or ``""`` if unset.
        """
        ...

    def set_host_target(self, triple: str, mcpu: str = "", mattr: str = "") -> None:
        """Set the host (CPU) target triple, CPU, and feature string.


        The values are stored immediately and validated when compilation runs.

        :param triple: LLVM triple such as ``"x86_64-unknown-linux-gnu"`` or
            ``"aarch64-unknown-linux-gnu"``.
        :param mcpu: LLVM CPU name, e.g. "neoverse-n1".
        :param mattr: Comma-separated LLVM feature list, e.g. "+lse".
        """
        ...

    @staticmethod
    def detect_host_triple() -> str:
        """Return the LLVM target triple detected for the current machine.

        An empty string indicates that target detection failed.
        """
        ...

    def set_device_target(self, arch: str) -> None:
        """Set the NVIDIA GPU architecture used for device code generation.

        Accepted names include ``sm_80``, ``sm_90a``, and supported ``sm_100``
        or newer variants with optional ``a``/``f`` suffixes. A rejected value
        leaves the previous target unchanged. Device artifact compilation fails
        until a target is set successfully.

        :param arch: GPU architecture name.
        :raises RuntimeError: If ``arch`` is not recognized.
        """
        ...

    def add_compile_option(self, key: str, value: str) -> None:
        """Set a compiler option, replacing an existing value for ``key``.

        Recognized keys include ``symbol-prefix``, ``opt-level``, and the
        Device-backend option strings ``nvvm-options`` / ``ptx-options``.
        ``nvvm-options`` must not contain ``-gen-lto``; request
        :attr:`ArtifactType.LtoIr` instead.
        """
        ...

    def set_abi(self, abi: Abi) -> None:
        """Select the ABI emitted during ``CompiledMlir`` → ``LlvmIr``.

        :attr:`Abi.Tbd` is the base compiler default. Host/Heterogeneous
        lowering locks each function's wrapper ABI; Device lowering emits no
        host wrapper and leaves it unchanged. Prefer :attr:`Abi.TvmFfi` when it
        supports the required host interface. :attr:`Abi.CutlassCall` is
        private and unstable, with no compatibility guarantee.
        """
        ...

    @property
    def abi(self) -> Abi:
        """Currently configured target ABI."""
        ...

    @overload
    @staticmethod
    def get_next_artifact_type(
        current: ArtifactType,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> ArtifactType:
        """Return the next stage on the default pipeline route.

        Device LLVM IR advances through Ptx to Object. Host/Heterogeneous LLVM
        IR advances directly to Object. LtoIr is selected explicitly as the
        final target of :meth:`compile_to` and is not on the default route.
        """
        ...

    @overload
    @staticmethod
    def get_next_artifact_type(
        current: ArtifactType,
        final_target: ArtifactType,
        target_kind: TargetKind = TargetKind.Heterogeneous,
    ) -> ArtifactType:
        """Return the next stage on the route to ``final_target``.

        This overload exposes the Device ``LlvmIr`` → ``LtoIr`` edge. It
        returns :attr:`ArtifactType.none` when the destination is the current
        stage, earlier, or unreachable for ``target_kind``.
        """
        ...

    @overload
    def compile_to(
        self,
        artifacts: CompilationArtifact,
        target: Literal[ArtifactType.CompiledMlir],
    ) -> CompiledMlirArtifact: ...
    @overload
    def compile_to(
        self,
        artifacts: CompilationArtifact,
        target: Literal[ArtifactType.LlvmIr],
    ) -> LlvmIrArtifact: ...
    @overload
    def compile_to(
        self,
        artifacts: CompilationArtifact,
        target: Literal[ArtifactType.Ptx],
    ) -> PtxArtifact: ...
    @overload
    def compile_to(
        self,
        artifacts: CompilationArtifact,
        target: Literal[ArtifactType.LtoIr],
    ) -> LtoIrArtifact: ...
    @overload
    def compile_to(
        self,
        artifacts: CompilationArtifact,
        target: Literal[ArtifactType.Object],
    ) -> ObjectArtifact: ...
    @overload
    def compile_to(
        self, artifacts: CompilationArtifact, target: ArtifactType
    ) -> CompilationArtifact:
        """Compile an artifact forward to ``target``, consuming the input.

        Intermediate stages run automatically. Once compilation begins, the
        input wrapper is consumed on both success and failure; continue with
        the returned object on success and do not reuse the input. The target
        must be a later stage—compiling to the same or an earlier stage fails.
        A Device artifact requires :meth:`set_device_target` to have been
        called successfully first.

        :param artifacts: Owning source artifact.
        :param target: Reachable later pipeline stage.
        :returns: A new owning artifact at ``target``.
        :raises RuntimeError: If the input was already consumed, the target is
            unreachable, a required pipeline is absent or invalid, metadata
            validation fails, or any lowering/code-generation step fails.
        """
        ...

class CuteCompiler(Compiler):
    """Recommended compiler for CuTe-generated MLIR.

    The standard Host/Heterogeneous and Device MLIR pipelines, Device LLVM
    optimization before PTX/LTO IR emission, and :attr:`Abi.CutlassCall` are
    preconfigured. CutlassCall is a private, unstable implementation ABI with
    no compatibility guarantee. Prefer :attr:`Abi.TvmFfi` when it supports the
    required interface. Set the inherited device target explicitly before
    compiling a Device artifact.
    """

    def __init__(self) -> None: ...

def serialize_compilation_artifact(artifact: CompilationArtifact) -> bytes:
    """Serialize an artifact payload and metadata into a self-contained buffer.

    The artifact is borrowed and remains usable.

    :param artifact: Artifact to serialize.
    :returns: Bytes accepted by :func:`deserialize_compilation_artifact`.
    :raises RuntimeError: If the artifact was consumed or serialization fails.
    """
    ...

def deserialize_compilation_artifact(data: bytes) -> CompilationArtifact:
    """Restore an owning artifact from serialized CUTLASS compiler bytes.

    :param data: Output of :func:`serialize_compilation_artifact`.
    :returns: The concrete artifact subclass encoded in ``data``.
    :raises RuntimeError: If the buffer is truncated, malformed, unsupported,
        or contains invalid metadata.
    """
    ...
