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

"""Generic hook for observers that emit IR alongside the schedule walk.

The task-scheduling framework does not know what an observer does with the
schedule; it only announces, while tracing, which construct it is about to
lower and when that construct is finished. An observer registers itself
here and reads whatever it needs off the objects it is handed. This
module names no observer: which ones exist, and whether any exists at
all, is not this package's business.

**The one obligation for a task-scheduling developer:** a walker method
that lowers one schedule construct carries ``@emits_ir("<kind>")``, where
the decorated body is exactly the region the construct traces. There is
nothing else to do — no import of an observer, no state to thread, no
call to update when an observer changes.

Placement rules that matter for correctness:

- ``@emits_ir`` goes OUTSIDE ``@cute.jit``: the DSL JIT preprocessor
  rewrites the function it decorates, so it must see the original one.
- Nothing on this path may abort lowering. Every dispatch swallows
  observer exceptions; a failing observer degrades its own output and
  leaves the kernel untouched.
- An observer must not hold per-construct state in a walker frame local:
  several walker methods are ``@cute.jit``-traced, and a local live
  across a traced loop is threaded as a loop iter-arg. Observers keep
  their own module-level stacks.

Construct kinds announced today are listed in :data:`CONSTRUCT_KINDS`.
"""

import functools
from typing import Any, Callable, Optional, Protocol

__all__ = [
    "CONSTRUCT_KINDS",
    "NO_NODE",
    "ScheduleIREmitter",
    "after_setup",
    "begin",
    "construct_kind",
    "emits_ir",
    "end",
    "register_ir_emitter",
    "registered_ir_emitters",
    "unregister_ir_emitter",
]


#: Every construct kind the walker announces. Adding a construct means
#: adding its kind here and decorating the method that lowers it; an
#: observer that does not know a kind still brackets it (conservatively)
#: rather than losing the region.
#: Handed to an observer in place of the construct object when the node
#: selector itself failed. An observer must treat it as "describe nothing"
#: and emit no payload: substituting the task would make the observer read
#: the wrong kind of object and report a bogus missing field.
NO_NODE = object()

CONSTRUCT_KINDS = (
    "task",
    "step",
    "drain",
    "domain_loop",
    "work_tile_loop",
    "cond",
)


class ScheduleIREmitter(Protocol):
    """Observer notified as the walker lowers each schedule construct.

    ``begin`` / ``end`` bracket exactly what one construct traces and
    always come in pairs (``end`` runs from a ``finally``). ``node`` is
    the framework object the construct was built from -- a schedule node,
    a ``Step``, a resource, or the task itself -- and its meaning is
    fixed per ``kind``.
    """

    def begin(self, kind: str, task: Any, node: Any) -> None:
        """The walker is about to trace one construct of ``kind``."""

    def end(self, kind: str, task: Any, node: Any) -> None:
        """The construct opened by the matching :meth:`begin` is complete."""

    def after_setup(self, manager: Any) -> None:
        """The manager finished declaring its resources and tasks."""


_emitters: list[ScheduleIREmitter] = []


def register_ir_emitter(emitter: ScheduleIREmitter) -> None:
    """Register ``emitter`` to observe every subsequent schedule walk.

    Registering the same object twice is a no-op, so a module that
    registers on import stays correct under a module reload.
    """
    if emitter not in _emitters:
        _emitters.append(emitter)


def unregister_ir_emitter(emitter: ScheduleIREmitter) -> None:
    """Remove ``emitter``; unknown emitters are ignored."""
    if emitter in _emitters:
        _emitters.remove(emitter)


def registered_ir_emitters() -> tuple[ScheduleIREmitter, ...]:
    """The currently registered emitters, in registration order."""
    return tuple(_emitters)


def begin(kind: str, task: Any, node: Any) -> None:
    """Announce the start of one construct to every registered emitter.

    Fail-open: an emitter that raises is skipped for this construct and
    the walk continues. NOTHING on this path may abort lowering.
    """
    # Snapshot: an observer may register or unregister from its own hook.
    for emitter in tuple(_emitters):
        try:
            emitter.begin(kind, task, node)
        except Exception:  # noqa: BLE001 - fail-open by design.
            pass


def end(kind: str, task: Any, node: Any) -> None:
    """Announce the end of the construct opened by :func:`begin`.

    Runs for every emitter even if one raises, so an emitter that keeps a
    begin/end stack is never left unbalanced by a sibling's failure.
    """
    for emitter in tuple(_emitters):
        try:
            emitter.end(kind, task, node)
        except Exception:  # noqa: BLE001 - fail-open by design.
            pass


def after_setup(manager: Any) -> None:
    """Announce that ``manager`` finished setting up resources and tasks.

    Unlike :func:`begin` / :func:`end` this is NOT fail-open: it runs
    outside the traced walk, and an emitter that rejects the schedule here
    (the ts audit raises a ``ValueError`` for a rejected schedule, honoring
    ``skip_validation``) must be able to stop the compile. Emitters are
    responsible for degrading their own infrastructure failures.

    Every emitter runs even when an earlier one rejects, so one observer's
    verdict never hides another's; the FIRST failure is re-raised once the
    loop is done.
    """
    failure: "Optional[BaseException]" = None
    for emitter in tuple(_emitters):
        try:
            emitter.after_setup(manager)
        except Exception as error:  # noqa: BLE001 - re-raised below.
            if failure is None:
                failure = error
    if failure is not None:
        raise failure


def _self_node(self: Any, *args: Any, **kwargs: Any) -> Any:
    """Default construct object: the task the walker method is bound to."""
    return self


def emits_ir(
    kind: str,
    node: Callable[..., Any] = _self_node,
) -> Callable[[Callable], Callable]:
    """Bracket a walker method as the lowering of one construct of ``kind``.

    ``node`` selects the framework object describing the construct from the
    method's own arguments (``self`` first); it defaults to the bound task.
    The decorated body must be EXACTLY the region the construct traces --
    setup that precedes the construct belongs in the caller.

    Apply outside ``@cute.jit``::

        @emits_ir("work_tile_loop", node=lambda self, node, ctx: node)
        @cute.jit
        def _run_work_tile_loop(self, node, ctx): ...
    """

    def decorate(method: Callable) -> Callable:
        # functools.wraps copies the DSL's own marker attributes
        # (``_dsl_cls``, ``_decorator_kind``, ``set_name_prefix``) onto the
        # wrapper. The PyIR call boundary classifies callables by
        # ``_dsl_cls`` (base_dsl/pyir_call_boundary.py), so this copy is
        # load-bearing, not cosmetic: dropping ``wraps`` would change how a
        # decorated ``@cute.jit`` walker method is classified.
        @functools.wraps(method)
        def wrapper(self: Any, *args: Any, **kwargs: Any) -> Any:
            try:
                construct = node(self, *args, **kwargs)
            except Exception:  # noqa: BLE001 - fail-open by design.
                # NOT ``self``: handing a task to an observer that expects
                # a schedule node would make it report a bogus missing
                # field instead of "I could not describe this construct".
                construct = NO_NODE
            begin(kind, self, construct)
            try:
                return method(self, *args, **kwargs)
            finally:
                end(kind, self, construct)

        # Makes the construct kind introspectable, so a test can assert the
        # walker's construct map without tracing a kernel.
        wrapper.__ir_construct_kind__ = kind  # type: ignore[attr-defined]
        return wrapper

    return decorate


def construct_kind(method: Any) -> "Optional[str]":
    """The construct kind ``method`` announces, or ``None`` if undecorated."""
    return getattr(method, "__ir_construct_kind__", None)
