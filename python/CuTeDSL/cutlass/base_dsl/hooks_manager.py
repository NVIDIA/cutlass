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

"""Hooks that a DSL fires during tracing, compilation and execution.

Each point is a :class:`HookEvent`. A hook registered for an event is called
synchronously with one event object, for example a :class:`CompilationEvent`,
whose fields describe that point. Hooks are registered on the DSL instance
with ``register_hook``/``remove_hook``, or for the duration of a ``with``
block with ``hooks``; see ``BaseDSL.register_hook``.
"""

import enum
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Callable, Generator, Iterable

from .common import DSLRuntimeError

if TYPE_CHECKING:
    from .._mlir import ir
    from .compiler import CompileOptions
    from .jit_executor import JitFunctionArtifacts


class HookEvent(enum.Enum):
    """A point of tracing, compilation or execution at which hooks run."""

    #: After tracing and before the module is hashed. Hooks receive a
    #: :class:`TraceFinalizeEvent` and may inspect or annotate the module
    #: before its cache key is computed.
    POST_TRACE = "post_trace"
    #: After a compilation or an in-memory cache hit, once the compilation has
    #: finished. Hooks receive a :class:`CompilationEvent`.
    POST_COMPILE = "post_compile"
    #: Before each call to a compiled host function. Hooks receive a
    #: :class:`LaunchEvent`.
    PRE_EXECUTE = "pre_execute"


@dataclass(frozen=True)
class TraceFinalizeEvent:
    """Payload of :attr:`HookEvent.POST_TRACE`."""

    #: The DSL instance.
    owner: Any
    #: The finalized module. Hooks may modify it; changes affect its hash.
    module: "ir.Module"
    #: Identifies the trace.
    function_name: str


@dataclass(frozen=True)
class CompilationEvent:
    """Payload of :attr:`HookEvent.POST_COMPILE`.

    Device functions compiled with ``DeviceTarget`` are not reported, nor is
    ``cute.compile_to``, which exports the MLIR without compiling it. The hook
    runs after the compilation has finished, so it may compile other functions.
    """

    #: The DSL instance.
    owner: Any
    #: Name of the compiled function.
    function_name: str
    #: Identifies the compiled specialization. While a hook is registered it
    #: is computed even when caching is off; it is ``None`` for a function
    #: compiled with caching off while no hook was registered.
    module_hash: str | None
    #: ``True`` only for an in-memory cache hit; a function loaded from the
    #: file cache is reported like a fresh compilation, with ``False``.
    cache_hit: bool
    #: Artifacts of the compiled function, possibly holding ``None`` entries
    #: when artifact keeping is off.
    artifacts: "JitFunctionArtifacts | None"
    #: Compile options of this compilation.
    compile_options: "CompileOptions"
    #: The original Python function.
    func_body: Callable[..., Any] | None
    #: Maps kernel names to kernel attributes.
    kernel_info: dict[str, Any]


@dataclass(frozen=True)
class LaunchEvent:
    """Payload of :attr:`HookEvent.PRE_EXECUTE`.

    Calls are the implicit launch of a ``@jit`` call and every call to a
    compiled function, TVM FFI ones included. Calls through an executor
    returned by ``to(device)`` are not reported, except with TVM FFI, where
    ``to`` returns the compiled function itself. Each event describes one
    host-function call, which may launch zero, one, or multiple GPU kernels;
    hooks are not run separately for each GPU kernel. Hooks run before the
    call itself, so a call that fails afterwards, for example because TVM FFI
    rejects its arguments, is still reported. A hook exception stops the call.
    """

    #: The DSL instance.
    owner: Any
    #: Name of the compiled host entry point.
    function_name: str
    #: The hash the compilation hooks received for the compiled function,
    #: which ties the call to its compilation. ``None`` for a function compiled
    #: with caching off (for example by ``cute.compile``) while no compilation
    #: or launch hook was registered.
    module_hash: str | None
    #: Describes the kernels in the compilation.
    kernel_info: dict[str, Any]
    #: Runtime arguments, without ``Constexpr`` parameters. An implicit launch
    #: reports every runtime parameter with defaults applied, positional ones
    #: in ``args`` in declaration order and keyword-only ones in ``kwargs``. A
    #: call to a compiled function reports the arguments as passed.
    args: tuple[Any, ...]
    kwargs: dict[str, Any]
    #: Names of the runtime parameters, positional ones first, so ``args[i]``
    #: binds to ``arg_names[i]`` (positional arguments past ``len(arg_names)``
    #: are extra trailing arguments).
    arg_names: tuple[str, ...]
    #: The argument list handed to the compiled program, in a backend-specific
    #: form, or ``None`` on a TVM FFI call to a compiled function, where
    #: tvm-ffi converts the arguments itself. It is the list that is then
    #: passed to the compiled program.
    exe_args: list[Any] | None
    #: The ``JitExecutor`` serving the call, or ``None`` on the first call and
    #: with TVM FFI.
    executor: Any


_EVENT_LABELS = {
    HookEvent.POST_TRACE: "Trace finalize",
    HookEvent.POST_COMPILE: "Compilation",
    HookEvent.PRE_EXECUTE: "Launch",
}


def _hook_name(hook: Any) -> str:
    if isinstance(hook, PositionalTraceFinalizeHook):
        hook = hook.__wrapped__
    return getattr(hook, "__qualname__", getattr(hook, "__name__", repr(hook)))


class HookChannel:
    """The hooks of one event: global registrations plus the ones scoped to
    the current context, kept in a ``ContextVar``. Duplicates are ignored, and
    a hook exception is raised as ``DSLRuntimeError`` with it as the cause."""

    __slots__ = ("event", "label", "hooks", "scoped")

    def __init__(self, event: HookEvent, dsl_name: str) -> None:
        self.event = event
        self.label = _EVENT_LABELS[event]
        self.hooks: list[Callable[[Any], None]] = []
        self.scoped: ContextVar[tuple[Callable[[Any], None], ...]] = ContextVar(
            f"{dsl_name}_{event.value}_hooks", default=()
        )

    def __bool__(self) -> bool:
        # Checked on hot paths, so keep it to a list and a ContextVar lookup.
        return bool(self.hooks or self.scoped.get())

    def _check(self, hook: Any) -> None:
        if hook is None:
            raise DSLRuntimeError(f"{self.label} hook must not be None.")
        if not callable(hook):
            raise DSLRuntimeError(f"{self.label} hook must be callable.")

    def register(
        self, hook: Callable[..., None], adapt: Callable[[Any], Any] | None = None
    ) -> None:
        """Register ``hook``; ``adapt``, if given, wraps it after the checks."""
        self._check(hook)
        if adapt is not None:
            hook = adapt(hook)
        if hook not in self.hooks:
            self.hooks.append(hook)

    def remove(self, hook: Callable[[Any], None]) -> None:
        if hook in self.hooks:
            self.hooks.remove(hook)

    @contextmanager
    def scope(
        self,
        hooks: Callable[..., None] | Iterable[Callable[..., None]],
        adapt: Callable[[Any], Any] | None = None,
    ) -> Generator[None, Any, None]:
        """Add ``hooks`` to the current context for the ``with`` block, in
        order and without duplicates; ``adapt`` as for ``register``."""
        scoped_hooks: tuple[Callable[..., None], ...]
        if callable(hooks):
            scoped_hooks = (hooks,)
        else:
            try:
                scoped_hooks = tuple(hooks)
            except TypeError as e:
                raise DSLRuntimeError(
                    f"{self.label} hooks must be callable or iterable."
                ) from e
        for hook in scoped_hooks:
            self._check(hook)
        if adapt is not None:
            scoped_hooks = tuple(adapt(hook) for hook in scoped_hooks)

        combined = list(self.scoped.get())
        for hook in scoped_hooks:
            if hook not in combined:
                combined.append(hook)
        token = self.scoped.set(tuple(combined))
        try:
            yield
        finally:
            self.scoped.reset(token)

    def run(self, event: Any) -> None:
        hooks = list(self.hooks)
        for hook in self.scoped.get():
            if hook not in hooks:
                hooks.append(hook)
        for hook in hooks:
            try:
                hook(event)
            except Exception as e:
                # DSLRuntimeError inherits DSLBaseError, which formats ``cause``.
                raise DSLRuntimeError(
                    f"{self.label} hook failed: {_hook_name(hook)}", cause=e
                ) from e


class PositionalTraceFinalizeHook:
    """Adapts a hook of the ``register_trace_finalize_hook`` form,
    ``hook(owner, module, function_name)``, to a :class:`TraceFinalizeEvent`.
    It compares equal to the hook it wraps, so registering the same hook twice
    is still ignored and ``remove_hook`` accepts the original hook."""

    __slots__ = ("__wrapped__",)

    def __init__(self, hook: Callable[[Any, "ir.Module", str], None]) -> None:
        self.__wrapped__ = hook

    def __call__(self, event: TraceFinalizeEvent) -> None:
        self.__wrapped__(event.owner, event.module, event.function_name)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, PositionalTraceFinalizeHook):
            other = other.__wrapped__
        return self.__wrapped__ == other

    def __hash__(self) -> int:
        return hash(self.__wrapped__)
