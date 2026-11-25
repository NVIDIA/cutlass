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
This module provides runtime utilities for JIT argument conversion in DSL.
"""

from contextlib import contextmanager
from contextvars import ContextVar
from typing import Callable, Any, Optional, ParamSpec, TypeVar, get_origin
from collections.abc import Iterator, Mapping
from dataclasses import is_dataclass, fields
from inspect import Parameter
from itertools import chain
from types import MappingProxyType
import threading


# Local modules imports
from ..common import DSLRuntimeError
from ..typing import (
    Constexpr,
    Int32,
    Float32,
    Boolean,
    NumericMeta,
    cast,
    get_c_pointers,
    get_mlir_types,
    implements_jit_argument,
    implements_dynamic_expression,
)
from ..utils.tree_utils import is_constexpr_field
from ..._mlir import ir


_ScopeArgs = ParamSpec("_ScopeArgs")
_ScopeResult = TypeVar("_ScopeResult")
_ExclusiveResult = TypeVar("_ExclusiveResult")


def _is_reserved_python_func_arg(
    arg_index: int, arg_name: str, func: Optional[Callable[..., Any]]
) -> bool:
    """
    Check if the argument is a reserved python function argument.
    """

    if arg_index != 0:
        return False

    if arg_name == "self":
        return True

    if func:
        is_classmethod = isinstance(func, classmethod) or (
            hasattr(func, "__func__") and isinstance(func.__func__, classmethod)
        )
        return arg_name == "cls" and is_classmethod
    return False


def is_arg_annotation_constexpr(
    arg_annotation: Any,
    arg_name: str,
    arg_index: int,
    owning_func: Optional[Callable[..., Any]],
) -> bool:
    """
    Check if the argument annotation is a constexpr.
    """
    return (
        _is_reserved_python_func_arg(arg_index, arg_name, owning_func)
        or (isinstance(arg_annotation, type) and issubclass(arg_annotation, Constexpr))  # type: ignore[misc]
        or (get_origin(arg_annotation) is Constexpr)
    )


def _is_type_argument(arg: Any, arg_annotation: Any) -> bool:
    """
    Check if the argument is a type argument like Type[X]
    """

    return isinstance(arg, type) and (
        arg_annotation is Parameter.empty or get_origin(arg_annotation) is type
    )


def is_argument_constexpr(
    arg: Any,
    arg_annotation: Any,
    arg_name: str,
    arg_index: int,
    owning_func: Callable[..., Any],
) -> bool:
    """
    Check if the argument is a constexpr.
    """
    return (
        is_arg_annotation_constexpr(arg_annotation, arg_name, arg_index, owning_func)
        or _is_type_argument(arg, arg_annotation)
        or arg is None
    )


class JitArgAdapterRegistry:
    """
    A registry to keep track of the JIT argument adapters.

    An adapter is a callable that converts a Python type to a type with following protocols supported:
    - JitArgument
    - DynamicExpression
    The converted type can then be further processed by DSL to generate arguments for JIT functions.

    Thread safety (copy-on-write)
    -----------------------------
    Since registrations happen during module import time for built-in types,
    and user-defined type registrations should happen before any
    compilations or launches, this class's thread safety is optimized for
    performance during compilation and launch.
    This is achieved by using copy-on-write semantics when new adapters
    are registered.

    - Every published mapping is immutable (a ``MappingProxyType`` or a
      ``frozenset``) and is never modified after it is assigned to the class.
    - A writer acquires a lock, builds a new mapping from the current
      one plus its change, and rebinds the class attribute. Rebinding an
      attribute is a single atomic store, so a reader either sees the old
      mapping or the new one, never a half-updated dict.
    - Readers read each attribute once into a local and never take a lock.
      Multi-step reads run on a mapping no other thread can change, so
      they cannot observe a concurrent insert or raise "dictionary changed
      size during iteration".

    This gives a single writer at a time with any number of concurrent
    readers, the same guarantee as a reader-writer lock, without readers
    paying for one. The cost is that a registration copies the mapping it
    changes, which is fine because registrations are rare and the mappings
    are small.

    Do not mutate the published mappings from outside this class; they are
    read-only proxies and the mutation raises ``TypeError``. Code that needs
    to make several changes without another writer interleaving (a user
    registering a set of adapters, a test fixture restoring the registry)
    does so inside :meth:`with_exclusive_access`.
    """

    # Serializes writers. Readers never take it. Reentrant so that the public
    # write API can be used inside ``with_exclusive_access``. A bare RLock in a
    # ``with`` statement pairs acquire and release atomically, so an async
    # exception cannot leave it held.
    _write_lock: threading.RLock = threading.RLock()

    # Common adapters shared by every DSL, with key=type and value=callable.
    # Keep this legacy public map for unscoped registrations. Scoped adapters
    # intentionally are not mirrored here: choosing one as the global value
    # would make behavior depend on module import order again.
    jit_arg_adapter_registry: Mapping[type, Any] = MappingProxyType({})

    # Dialect-specific adapters. A Python type may have a different adapter in
    # each scope (for example, CUstream maps to either gpu.async.token or
    # cuda.stream depending on the DSL compiling the function). Both the outer
    # and the inner mappings are immutable; a scoped registration republishes
    # both.
    scoped_jit_arg_adapter_registries: Mapping[str, Mapping[type, Any]] = (
        MappingProxyType({})
    )

    GPU_DIALECT_SCOPE = "gpu"
    CUDA_DIALECT_SCOPE = "cuda"

    # Per-thread and per-task by construction; needs no lock.
    _active_scope: ContextVar[str | None] = ContextVar(
        "jit_arg_adapter_scope", default=None
    )

    # Adapters keyed by fully-qualified type name ("module.QualName") for
    # types whose defining module is too expensive to import at registration
    # time (e.g. torch). Cached in jit_arg_adapter_registry for each concrete
    # type on first lookup of an instance, which can only exist once the module
    # is loaded.
    lazy_jit_arg_adapter_registry: Mapping[str, Any] = MappingProxyType({})

    # Top-level module names of the lazy registrations, so lookups of
    # unrelated types skip the qualified-name construction entirely.
    _lazy_adapter_module_roots: frozenset[str] = frozenset()

    # Default adapters for arguments we don't know type names beforehand
    # Default dataclass adapter
    default_dataclass_adapter: Callable[[object], Any] | None = None

    @classmethod
    def with_exclusive_access(
        cls, operation: Callable[[], _ExclusiveResult]
    ) -> _ExclusiveResult:
        """Run ``operation`` as the only writer to the registry and return its result.

        While ``operation`` runs, no other thread can register an adapter,
        set the default dataclass adapter, or promote a lazy adapter. Use it
        to group several registrations so another thread's registration
        cannot land between them::

            def register_my_adapters():
                JitArgAdapterRegistry.register_jit_arg_adapter(MyType)(my_adapter)
                JitArgAdapterRegistry.register_jit_arg_adapter(OtherType)(other)

            JitArgAdapterRegistry.with_exclusive_access(register_my_adapters)

        The public API is usable inside ``operation``; the writer lock is
        reentrant, and nested calls to this method are allowed.

        Exclusive access applies to writers only. Reads never block, so a
        lookup on another thread may observe a partial update: it can see the
        registry after the first registration inside ``operation`` and before
        the second. Each individual registration is still published atomically,
        so a reader never sees a half-built mapping, only an earlier or later
        complete one. Callers that need every registration visible before any
        lookup must finish ``operation`` before the lookups start.

        Code that rebinds the class attributes directly inside ``operation``
        must follow the copy-on-write rules: assign new immutable mappings,
        never mutate a published one.
        """
        with cls._write_lock:
            return operation()

    @classmethod
    def register_jit_arg_adapter(
        cls,
        python_type: "type | str | None" = None,
        *,
        scope: str | None = None,
        lazy: bool = False,
    ) -> Callable[[Any], Any]:
        """
        Register a JIT argument adapter callable

        This can be used as a decorator on any callable like:

        @register_jit_arg_adapter(my_py_type)
        def my_adapter_for_my_py_type(arg):
            ...

        @register_jit_arg_adapter(my_py_type)
        class MyAdapterForMyPythonType:
            ...

        Common adapters are registered per type. Dialect-specific adapters can
        pass ``scope=...`` and are registered per ``(scope, type)`` pair.
        Registering the same type twice in the same scope raises an error.

        With ``lazy=True`` the type is named by its fully-qualified
        "module.QualName" string instead, so registration never imports the
        defining module (e.g. torch). An instance of the type can only reach
        a JIT function after the application has imported its module, so the
        adapter is cached for the concrete type on first lookup. Named base
        classes also match their subclasses, allowing registration against a
        stable public type when implementations use private concrete types.
        """

        if python_type is None:
            raise DSLRuntimeError(
                "a Python type must be provided for registering JIT argument adapter"
            )
        lazy_module_root: str | None = None
        if lazy:
            if not isinstance(python_type, str):
                raise DSLRuntimeError(
                    "a fully-qualified 'module.QualName' string must be provided "
                    "for registering a lazy JIT argument adapter"
                )
            name_parts = python_type.split(".")
            if len(name_parts) < 2 or not all(name_parts):
                raise DSLRuntimeError(
                    "lazy JIT argument adapter type name must be fully-qualified "
                    "as 'module.QualName'"
                )
            if scope is not None:
                raise DSLRuntimeError(
                    "lazy JIT argument adapters do not support scoped registration"
                )
            lazy_module_root = name_parts[0]
        elif isinstance(python_type, str):
            raise DSLRuntimeError(
                "non-lazy JIT argument adapters must be registered with a Python type"
            )

        def decorator(adapter: Any) -> Any:
            if not callable(adapter):
                raise DSLRuntimeError(
                    "a callable must be provided for registering JIT argument adapter"
                )

            # The duplicate check and the publish must be one critical section,
            # otherwise two threads registering the same type both pass the
            # check and the second silently wins.
            with cls._write_lock:
                # Keys are ``str`` for the lazy registry and ``type`` otherwise;
                # the checks above already validated ``python_type`` matches.
                key: Any = python_type
                registry: Mapping[Any, Any]
                if lazy:
                    registry = cls.lazy_jit_arg_adapter_registry
                elif scope is None:
                    registry = cls.jit_arg_adapter_registry
                else:
                    registry = cls.scoped_jit_arg_adapter_registries.get(scope, {})
                if key in registry:
                    raise DSLRuntimeError(
                        f"JIT argument adapter for {python_type} "
                        "is already registered!",
                        context={
                            "Scope": scope,
                            "Registered adapter": registry[key],
                            "Adapter to be registered": adapter,
                        },
                    )
                updated = MappingProxyType({**registry, key: adapter})
                if lazy:
                    assert lazy_module_root is not None
                    # Publish the roots filter before the registry. Readers
                    # take no lock and read the registry first, then the
                    # roots, so a reader that sees the new registry has also
                    # seen the new roots. The reverse order would let the
                    # filter skip a type whose adapter is already published.
                    cls._lazy_adapter_module_roots = cls._lazy_adapter_module_roots | {
                        lazy_module_root
                    }
                    cls.lazy_jit_arg_adapter_registry = updated
                elif scope is None:
                    cls.jit_arg_adapter_registry = updated
                else:
                    cls.scoped_jit_arg_adapter_registries = MappingProxyType(
                        {**cls.scoped_jit_arg_adapter_registries, scope: updated}
                    )
            return adapter

        return decorator

    @classmethod
    def _resolve_lazy_adapter(
        cls, python_type: type, lazy_registry: Mapping[str, Any]
    ) -> Callable[..., Any] | None:
        """Find the lazy adapter for ``python_type`` or a base class, or None.

        Pure read on the ``lazy_registry`` mapping passed by the caller, which
        is the immutable object the caller already read, so the MRO walk
        cannot race with a registration.
        """
        for candidate_type in python_type.__mro__:
            type_qualname = f"{candidate_type.__module__}.{candidate_type.__qualname__}"
            adapter = lazy_registry.get(type_qualname)
            if adapter is not None:
                return adapter
        return None

    @classmethod
    def _cache_promoted_adapter(
        cls, python_type: type, adapter: Callable[..., Any]
    ) -> None:
        """Publish ``adapter`` for the concrete ``python_type`` in the common registry.

        This is the only write on the lookup path. It runs outside any reads of
        the registry, under ``_write_lock``, and re-checks the current mapping:
        two threads doing the first lookup of the same type both resolve the
        same lazy adapter, and whichever publishes second finds the entry
        already there and keeps it.
        """
        with cls._write_lock:
            current = cls.jit_arg_adapter_registry
            if python_type in current:
                return
            cls.jit_arg_adapter_registry = MappingProxyType(
                {**current, python_type: adapter}
            )

    @classmethod
    @contextmanager
    def using_scope(cls, scope: str | None) -> Iterator[None]:
        """Use ``scope`` for adapter lookup, including nested adaptations."""
        token = cls._active_scope.set(scope)
        try:
            yield
        finally:
            cls._active_scope.reset(token)

    @classmethod
    def call_with_scope(
        cls,
        scope: str | None,
        callback: Callable[_ScopeArgs, _ScopeResult],
        *args: _ScopeArgs.args,
        **kwargs: _ScopeArgs.kwargs,
    ) -> _ScopeResult:
        """Call ``callback`` with an adapter scope and restore the prior scope.

        This avoids the generator-based context-manager overhead on the compiled
        launch path while preserving the scope for nested adapter lookups.
        """
        token = cls._active_scope.set(scope)
        try:
            return callback(*args, **kwargs)
        finally:
            cls._active_scope.reset(token)

    @classmethod
    def get_registered_adapter(cls, arg: object) -> Any:
        """
        Get the registered JIT argument adapter for the given argument.

        A scoped lookup checks that scope first and then the common registry.
        An unscoped lookup remains compatible when exactly one scoped adapter
        exists, but reports ambiguity instead of silently choosing an adapter
        based on module import order.
        """
        # Transparency protocol (F-TRANSPARENT): a tracing observation wrapper
        # that declares a plain counterpart resolves and runs its adapter AS
        # that plain value. The wrapper type is a host-trace artifact and is
        # never registered, so an exact-type lookup would miss the plain type's
        # adapter and the argument would reach the JIT boundary unconverted.
        # Same consult as ``utils.tree_utils._tree_flatten``.
        if getattr(type(arg), "__pyir_plain_type__", None) is not None:
            plain_view: Any = arg.__pyir_plain_view__()  # type: ignore[attr-defined]
            plain_adapter = cls.get_registered_adapter(plain_view)
            if plain_adapter is None:
                return None
            return lambda wrapper: plain_adapter(wrapper.__pyir_plain_view__())

        python_type = type(arg)
        resolved_scope = cls._active_scope.get()

        # Read each published mapping once into a local. Every mapping is
        # immutable, so multi-step reads on any one of them (the MRO walk, the
        # scan over scopes) cannot race with a registration. The reads are not
        # a snapshot across attributes: a writer may rebind one between two of
        # them. That is harmless because no lookup rule spans two mappings,
        # except the roots filter, which registration publishes before the
        # lazy registry so the filter is never stale for a published adapter.
        scoped_registries = cls.scoped_jit_arg_adapter_registries
        common_registry = cls.jit_arg_adapter_registry
        lazy_registry = cls.lazy_jit_arg_adapter_registry
        lazy_roots = cls._lazy_adapter_module_roots

        adapter = None
        if resolved_scope is not None:
            adapter = scoped_registries.get(resolved_scope, {}).get(python_type)

        if adapter is None:
            adapter = common_registry.get(python_type)

        if (
            adapter is None
            and lazy_registry
            and not lazy_roots.isdisjoint(
                candidate_type.__module__.partition(".")[0]
                for candidate_type in python_type.__mro__
            )
        ):
            adapter = cls._resolve_lazy_adapter(python_type, lazy_registry)
            if adapter is not None:
                cls._cache_promoted_adapter(python_type, adapter)

        if adapter is None and resolved_scope is None:
            scoped_matches = [
                (registered_scope, registry[python_type])
                for registered_scope, registry in scoped_registries.items()
                if python_type in registry
            ]
            if len(scoped_matches) == 1:
                adapter = scoped_matches[0][1]
            elif len(scoped_matches) > 1:
                raise DSLRuntimeError(
                    f"JIT argument adapter for {python_type} is ambiguous; "
                    "perform the lookup inside "
                    "JitArgAdapterRegistry.using_scope(...) instead",
                    context={
                        "Registered scopes": [scope for scope, _ in scoped_matches]
                    },
                )

        if adapter is None:
            # Store this in a local variable to avoid a race condition.
            default_adapter = cls.default_dataclass_adapter
            if (
                default_adapter
                and not implements_jit_argument(arg, partial=True)
                and not implements_dynamic_expression(arg, partial=True)
                and is_dataclass(arg)
                and len(vars(arg)) == len(fields(arg))
            ):  # no extra/missing instance attrs
                adapter = default_adapter
        return adapter

    @classmethod
    def set_default_dataclass_adapter(cls, adapter: Callable[[object], Any]) -> None:
        """
        Set up a default dataclass adapter. If any user defined dataclass implements the JitArgument/DynamicExpression protocol,
        those impls will be honored instead of this default adapter.
        """
        # A single attribute store is already atomic; the lock keeps the rule
        # that every writer goes through ``_write_lock`` free of exceptions.
        with cls._write_lock:
            cls.default_dataclass_adapter = adapter


class DefaultDataclassAdapter:
    """
    Adapter for dataclass typed JIT arguments.
    """

    def __init__(self, arg: object) -> None:
        self._ir_fields: dict[str, object] = {}
        self._ir_fields_len: dict[str, int] = {}
        self._arg = arg
        for f in fields(arg):  # type: ignore[arg-type]
            arg_field = getattr(arg, f.name)
            if not is_constexpr_field(f, arg):
                if isinstance(f.type, NumericMeta) and not isinstance(
                    arg_field, f.type
                ):
                    self._ir_fields[f.name] = cast(arg_field, f.type)  # type: ignore[arg-type]
                else:
                    # Allow the nested fields to be adapted
                    arg_adapter = JitArgAdapterRegistry.get_registered_adapter(
                        arg_field
                    )
                    if arg_adapter is not None:
                        self._ir_fields[f.name] = arg_adapter(arg_field)
                    else:
                        self._ir_fields[f.name] = arg_field

    def __c_pointers__(self) -> list[Any]:
        return list(
            chain.from_iterable(get_c_pointers(v) for v in self._ir_fields.values())
        )

    def __get_mlir_types__(self) -> list[Any]:
        ir_types = []
        for f, v in self._ir_fields.items():
            types = get_mlir_types(v)
            self._ir_fields_len[f] = len(types)
            ir_types.extend(types)
        return ir_types

    def __new_from_mlir_values__(self, values: list[Any]) -> Any:
        from ..dsl import new_from_mlir_values  # deferred to avoid circular import

        kwargs = {}
        idx = 0
        for f in fields(self._arg):  # type: ignore[arg-type]
            if is_constexpr_field(f, self._arg):
                kwargs[f.name] = getattr(self._arg, f.name)
            else:
                kwargs[f.name] = new_from_mlir_values(
                    self._ir_fields[f.name],
                    values[idx : idx + self._ir_fields_len[f.name]],
                )
                idx += self._ir_fields_len[f.name]
        return type(self._arg)(**kwargs)

    def __extract_mlir_values__(self) -> list[ir.Value]:
        from ..dsl import extract_mlir_values  # deferred to avoid circular import

        return list(
            chain.from_iterable(
                extract_mlir_values(v) for v in self._ir_fields.values()
            )
        )


JitArgAdapterRegistry.set_default_dataclass_adapter(DefaultDataclassAdapter)


# =============================================================================
# JIT Argument Adapters
# =============================================================================


_PYTHON_SCALAR_CONVERSION_MAP = {
    int: Int32,
    float: Float32,
    bool: Boolean,
}


@JitArgAdapterRegistry.register_jit_arg_adapter(int)
@JitArgAdapterRegistry.register_jit_arg_adapter(float)
@JitArgAdapterRegistry.register_jit_arg_adapter(bool)
def _convert_python_scalar(arg: Any) -> Any:
    """
    Convert a Python scalar to a DSL type.
    """
    return _PYTHON_SCALAR_CONVERSION_MAP.get(type(arg))(arg)  # type: ignore[misc]


@JitArgAdapterRegistry.register_jit_arg_adapter(tuple)
@JitArgAdapterRegistry.register_jit_arg_adapter(list)
def _convert_python_sequence(arg: Any) -> Any:
    """
    Go through each element in the sequence and convert it to a type that can be
    further processed by DSL to generate the corresponding JIT argument(s).
    """
    adapted_arg = []
    for elem in arg:
        adapter = JitArgAdapterRegistry.get_registered_adapter(elem)
        if adapter is not None:
            converted_elem = adapter(elem)
            adapted_arg.append(converted_elem)
        else:
            # If no registered adapter is found, just return the original element
            adapted_arg.append(elem)

    assert len(adapted_arg) == len(arg)
    return type(arg)(adapted_arg)
