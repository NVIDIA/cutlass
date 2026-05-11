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

import builtins
from collections.abc import Iterator
from typing import Any, get_origin, get_type_hints

from .dsl import extract_mlir_values
from .typing import DslType

from .._mlir import ir
from .._mlir.dialects import llvm

from ._mlir_helpers import dsl_user_op


def _is_constexpr_annotation(ann: type) -> bool:
    """True if the annotation is Constexpr or Constexpr[T]."""
    from .typing import Constexpr

    return ann is Constexpr or get_origin(ann) is Constexpr


def _annotation_to_mlir_type(ann: type) -> ir.Type:
    """Resolve a type annotation to an MLIR type for struct fields.

    Supports DSL types with a class-level mlir_type (e.g. Int32, Float32),
    ir.Type instances, and other native_struct classes (for nested structs).
    Called at init/use time when MLIR context is available.
    """
    if isinstance(ann, ir.Type):
        return ann
    if hasattr(ann, "mlir_type"):
        mt = ann.mlir_type
        return mt() if callable(mt) else mt
    if hasattr(ann, "_struct_type"):
        return ann._struct_type
    raise TypeError(
        f"Struct field type must be an ir.Type, a DSL type with mlir_type, "
        f"or a native_struct class; got {ann!r}"
    )


class _StructTypeDescriptor:
    """Descriptor that resolves struct type from annotations on each access.

    Also provides :meth:`resolve` for use outside the descriptor protocol
    (e.g. in static methods like ``__get_mlir_types__`` and ``isinstance``).
    """

    _field_types_attr = "_field_types"

    def __init__(
        self, field_names: list, field_annotations: dict, packed: bool = False
    ):
        self._field_names = field_names
        self._field_annotations = field_annotations
        self._packed = packed

    def _resolve(self) -> tuple[ir.Type, list[ir.Type]]:
        """Resolve field annotations to MLIR types and build the struct type.

        Requires an active MLIR context. Not cached — MLIR types are tied to
        the context they were created in, and each JIT compilation may use a
        different context.
        """
        field_types = [
            _annotation_to_mlir_type(self._field_annotations[n])
            for n in self._field_names
        ]
        struct_type = llvm.StructType.get_literal(field_types, packed=self._packed)
        return struct_type, field_types

    def resolve(self) -> ir.Type:
        """Return the LLVM struct type (resolving and caching if needed)."""
        struct_type, _ = self._resolve()
        return struct_type

    def __get__(self, obj: Any, owner: type | None) -> ir.Type:
        if owner is None:
            owner = type(obj)
        struct_type, field_types = self._resolve()
        setattr(owner, self._field_types_attr, field_types)
        return struct_type


def native_struct(
    cls: type | None = None, *, zero_init: bool = True, packed: bool = False
) -> Any:
    """Decorator that mimics dataclass behavior but generates a native MLIR struct type.

    Can be used as ``@native_struct``, ``@native_struct(zero_init=False)``, or
    ``@native_struct(packed=True)``.

    ``zero_init`` (default True): if True, the struct is initialized with
    ``llvm.mlir.zero`` before inserting field values; if False, with ``llvm.mlir.undef``.

    ``packed`` (default False): if True, the LLVM struct type is created with the
    packed attribute (no padding between fields).

    The decorated class must use type annotations for all fields; each annotation
    must resolve to an DSL type (e.g. Int32, Float32, Pointer, etc.) or Constexpr. The decorator:

    - Builds an LLVM literal struct type ``!llvm.struct<(t1, t2, ...)>`` from the non-Constexpr
      field types.
    - Adds ``__init__(self, *, loc=None, ip=None, **kwargs)`` to construct from keyword
      arguments (one per MLIR field). Use ``cls.__new_from_mlir_values__([value])`` to wrap
      an existing ``ir.Value``.
    - Implements ``__extract_mlir_values__``, ``__new_from_mlir_values__``, and
      ``__get_mlir_types__`` so the class works as a DynamicExpression and JitArgument.
    - For each field ``name``, adds a property ``name`` to the class.
      Accessing ``instance.name`` gets the value of the field, optionally wrapping it in the annotated
      DSL type (for example, ``Int32``).
      Assigning to ``instance.name`` is supported and replaces the value of that field.
    - Fields annotated with ``Constexpr`` or ``Constexpr[T]`` are excluded from the
      native struct and from getters/setters; they can be passed as keyword arguments
      to ``__init__`` and are stored as normal Python attributes on the instance.
    - ``__setattr__`` is overridden so that only ``_value`` and Constexpr field names
      can be set; assigning any other attribute raises ``AttributeError`` (no new
      fields after init).

    Instance data is stored in ``_value`` (a single ir.Value of the struct type).

    Example::

        @native_struct
        class Vec2:
            x: Int32
            y: Int32

        @native_struct(zero_init=False)
        class Vec2Undef:
            x: Int32
            y: Int32

        @native_struct(packed=True)
        class PackedVec2:
            x: Int32
            y: Int32

        # From keyword arguments (loc= and ip= required)
        v = Vec2(x=x_val, y=y_val, loc=loc, ip=ip)

        # Get field (returns Int32 when annotation is Int32)
        x_val = v.x

        # Replace field
        v.x = new_x
    """

    def decorate(cls: type) -> type:
        hints = get_type_hints(cls)
        if not hints:
            raise TypeError(
                f"{cls.__name__}: @native_struct requires at least one type-annotated field"
            )
        # Split into MLIR fields (included in struct) and Constexpr fields (skipped).
        # Do not resolve annotations to MLIR types here; MLIR context may not exist yet.
        field_names = []
        field_annotations = {}
        constexpr_field_names = []
        for name, ann in hints.items():
            if _is_constexpr_annotation(ann):
                constexpr_field_names.append(name)
            else:
                field_names.append(name)
                field_annotations[name] = ann
        if not field_names:
            raise TypeError(
                f"{cls.__name__}: @native_struct requires at least one non-Constexpr field"
            )

        struct_type_descriptor = _StructTypeDescriptor(
            field_names, field_annotations, packed=packed
        )

        def __extract_mlir_values__(self: Any) -> list[ir.Value]:
            return [self._value]

        def __new_from_mlir_values__(self: Any, values: list[ir.Value]) -> Any:
            self._value = values[0]
            return self

        @dsl_user_op
        def __init__(
            self: Any,
            *args: Any,
            loc: ir.Location | None = None,
            ip: ir.InsertionPoint | None = None,
            **kwargs: Any,
        ) -> None:
            # Wrapping mode: single positional ir.Value
            # Note: this is builtins.isinstance, not the struct's own
            # isinstance() staticmethod (which hasn't been added to the
            # class yet at this point in decorate()).
            if len(args) == 1 and not kwargs and isinstance(args[0], ir.Value):
                struct_type = type(self)._struct_type
                if args[0].type != struct_type:
                    raise TypeError(
                        f"{cls.__name__}(): expected ir.Value of type "
                        f"{struct_type}, got {args[0].type}"
                    )
                self._value = args[0]
                return
            # Keyword-arg construction mode
            if len(args) > 0:
                raise TypeError(
                    f"{cls.__name__}() takes a single ir.Value or keyword "
                    f"arguments, got {len(args)} positional argument(s)"
                )
            # Populate Constexpr fields
            for name in constexpr_field_names:
                if name in kwargs:
                    setattr(self, name, kwargs.pop(name))
            extra = set(kwargs.keys()) - set(field_names) - set(constexpr_field_names)
            if extra:
                raise TypeError(
                    f"{cls.__name__}() got unexpected keyword argument(s): {sorted(extra)}"
                )
            struct_type = type(self)._struct_type
            if type(self)._struct_zero_init:
                val = llvm.mlir_zero(struct_type, loc=loc, ip=ip)
            else:
                val = llvm.mlir_undef(struct_type, loc=loc, ip=ip)
            for i, name in enumerate(field_names):
                v = kwargs.pop(name, None)
                if v is not None:
                    # Coerce Python literals (int, float, bool) using
                    # the field's type annotation (e.g. Int32(10)).
                    ann = field_annotations[name]
                    if isinstance(ann, DslType) and not hasattr(
                        v, "__extract_mlir_values__"
                    ):
                        v = ann(v)
                    elem = extract_mlir_values(v)
                    if len(elem) != 1:
                        raise TypeError(
                            f"Expected single value for field {name!r}, got {len(elem)}"
                        )
                    val = llvm.insertvalue(val, elem[0], position=[i], loc=loc, ip=ip)
            self._value = val

        # Build getter/setter for each field; need to capture in closure per field
        field_annotations_for_getter = hints

        def _make_getter(idx: int, name: str) -> Any:
            dsl_type = field_annotations_for_getter.get(name)

            def getter(
                self: Any,
                *,
                loc: ir.Location | None = None,
                ip: ir.InsertionPoint | None = None,
            ) -> Any:
                # Resolve struct type (and thus _field_types) on first use
                type(self)._struct_type
                elem_type = type(self)._field_types[idx]
                extracted = llvm.extractvalue(
                    res=elem_type,
                    container=self._value,
                    position=[idx],
                    loc=loc,
                    ip=ip,
                )
                # Wrap in DSL type if annotation is a callable type (e.g. Int32)
                if isinstance(dsl_type, DslType):
                    return dsl_type(extracted)
                if hasattr(dsl_type, "__new_from_mlir_values__"):
                    instance = dsl_type()  # type: ignore[misc]
                    return instance.__new_from_mlir_values__([extracted])
                return extracted

            getter.__name__ = name
            getter.__doc__ = f"Get the {name!r} field."
            return dsl_user_op(getter)

        def _make_setter(idx: int, name: str) -> Any:
            dsl_type = field_annotations_for_getter.get(name)

            def setter(
                self: Any,
                value: Any,
                *,
                loc: ir.Location | None = None,
                ip: ir.InsertionPoint | None = None,
            ) -> None:
                # Coerce Python literals using the field's type annotation.
                if isinstance(dsl_type, DslType) and not hasattr(
                    value, "__extract_mlir_values__"
                ):
                    value = dsl_type(value)
                elem = extract_mlir_values(value)
                if len(elem) != 1:
                    raise TypeError(
                        f"Expected single value for field {name!r}, got {len(elem)}"
                    )
                elem = elem[0]
                new_value = llvm.insertvalue(
                    self._value, elem, position=[idx], loc=loc, ip=ip
                )
                self._value = new_value

            setter.__name__ = f"set_{name}"
            setter.__doc__ = f"Set the {name!r} field."
            return dsl_user_op(setter)

        _allowed_attr_names = frozenset(
            field_names + constexpr_field_names + ["_value"]  # _value is internal
        )

        def __setattr__(self: Any, name: str, value: Any) -> None:
            if name not in _allowed_attr_names:
                raise AttributeError(
                    f"{type(self).__name__!r} does not allow setting attribute {name!r}; "
                    f"only fields {field_names + constexpr_field_names} are settable"
                )
            object.__setattr__(self, name, value)

        def __iter__(self: Any) -> Iterator[Any]:
            """Yield each field as its DSL-typed value (e.g. Int32, Boolean).

            Enables tuple unpacking: ``a, b = my_struct``.
            """
            for name in field_names:
                yield getattr(self, name)

        def __get_mlir_types__() -> list[ir.Type]:
            """Return MLIR types list — compatible with FFI ``_to_mlir_types``.

            Works on both the class and instances, so ``get_mlir_types(MyStruct)``
            and ``get_mlir_types(my_instance)`` both return ``[struct_type]``.
            """
            return [struct_type_descriptor.resolve()]

        def _isinstance(value: Any) -> bool:
            """Check if an ``ir.Value`` matches this struct type."""
            if not builtins.isinstance(value, ir.Value):
                return False
            return value.type == struct_type_descriptor.resolve()

        attrs = {
            "_field_names": field_names,
            "_field_annotations": field_annotations,
            "_constexpr_field_names": constexpr_field_names,
            "_struct_type": struct_type_descriptor,
            "mlir_type": struct_type_descriptor,
            "_struct_zero_init": zero_init,
            "_struct_packed": packed,
            "__init__": __init__,
            "__iter__": __iter__,
            "__setattr__": __setattr__,
            "__get_mlir_types__": staticmethod(__get_mlir_types__),
            "isinstance": staticmethod(_isinstance),
            "__extract_mlir_values__": __extract_mlir_values__,
            "__new_from_mlir_values__": __new_from_mlir_values__,
        }
        for idx, name in enumerate(field_names):
            attrs[name] = property(_make_getter(idx, name), _make_setter(idx, name))

        # Preserve existing methods and attributes that don't conflict
        for key, value in cls.__dict__.items():
            if key not in attrs and not key.startswith("__"):
                attrs[key] = value
        new_cls = type(cls.__name__, cls.__bases__, attrs)
        new_cls.__module__ = cls.__module__
        new_cls.__qualname__ = cls.__qualname__
        new_cls.__annotations__ = cls.__annotations__
        if cls.__doc__ is not None:
            new_cls.__doc__ = cls.__doc__
        return new_cls

    if cls is None:
        return decorate
    return decorate(cls)


def make_native_struct(
    name: str, *, zero_init: bool = True, packed: bool = False, **fields: Any
) -> type:
    """Create a native struct class dynamically from field name/type pairs.

    Unlike the ``@native_struct`` decorator which requires a class definition
    with static type annotations, this factory builds a struct class at runtime.
    This is useful when the struct layout is determined dynamically — for example,
    NVVM ops whose result struct depends on matrix dimensions or element types.

    The returned class behaves identically to a ``@native_struct``-decorated
    class: it supports ``ir.Value`` wrapping, keyword-arg construction, named
    field access, tuple unpacking via iteration, and the full DSL protocol.

    Example::

        ResultType = make_native_struct("WmmaLoadResult",
                                        d0=Int32, d1=Int32, d2=Int32, d3=Int32)
        ResultType.mlir_type   # → !llvm.struct<(i32, i32, i32, i32)>

        result = ResultType(raw_ir_value)
        result.d0              # → Int32 (via extractvalue)
        d0, d1, d2, d3 = result  # tuple unpacking

    Parameters
    ----------
    name : str
        Name for the generated class.
    zero_init : bool
        If True (default), keyword-arg construction zero-initializes before
        inserting fields; if False, uses ``llvm.mlir.undef``.
    packed : bool
        If True, create a packed LLVM struct (no padding).
    **fields
        Field names mapped to DSL types (e.g. ``d0=Int32, d1=Int32``).
        Order is preserved (Python 3.7+).

    Returns
    -------
    type
        A ``@native_struct`` class with the given fields.
    """
    if not fields:
        raise TypeError(f"make_native_struct({name!r}) requires at least one field")

    # Build a bare class with the right annotations, then delegate to native_struct
    cls = type(name, (), {"__annotations__": dict(fields)})
    return native_struct(cls, zero_init=zero_init, packed=packed)


__all__ = ["native_struct", "make_native_struct"]
