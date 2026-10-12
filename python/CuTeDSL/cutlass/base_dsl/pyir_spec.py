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


"""F-SPEC re-entry verification engine (V-11 SPEC-MATCH): re-resolves every
sealed specialization root path against a live call and refuses on drift.
The executor keeps only the ``_pyir_spec`` attr and a lazy hook into
``_pyir_validate_spec_reentry``."""

import sys
import types
from typing import Any, TYPE_CHECKING

from .common import DSLUserCodeError
from .diagnostics import DiagId
from .pyir_state import (
    _Sentinel,
    _SPEC_ATTR_ABSENT,
    _SPEC_ATTR_PRESENT,
    _SPEC_RECEIVER_DEAD,
    _SpecContainerSnapshot,
    _SpecTraceExitObject,
)

if TYPE_CHECKING:
    # Type-only: the executor imports this module lazily at validation time,
    # so a runtime import here would close an import cycle.
    from .jit_executor import ExecutionArgs


class _SpecUnresolvable:
    """Sentinel: a specialization root path does not resolve on this call."""


_SPEC_UNRESOLVABLE = _SpecUnresolvable()


class _SpecUnsupplied:
    """Sentinel: the root's argument is not part of THIS call's graph (an
    omitted trace-time-constant argument stays the compile-time capture)."""


_SPEC_UNSUPPLIED = _SpecUnsupplied()


class _SpecBinderFailed:
    """Sentinel: the launch binder could not produce this call's binding."""


_SPEC_BINDER_FAILED = _SpecBinderFailed()


def _spec_bound_call_arguments(
    execution_args: "ExecutionArgs | None", args: tuple, kwargs: dict
) -> "dict[str, Any] | _SpecBinderFailed":
    """THIS call's argument binding, produced by the launch binder itself
    (one name->position fact source, so validation == launch by construction);
    a receiver or constexpr-pruned parameter is never positional-bound."""
    if execution_args is None:
        return _SPEC_BINDER_FAILED
    try:
        return execution_args.bound_call_arguments(args, kwargs)
    except DSLUserCodeError:
        # The launch's own argument diagnostic: surface it here (fail closed).
        raise
    except Exception:
        return _SPEC_BINDER_FAILED


def _spec_resolve_root_path(
    root_path: tuple,
    bound_args: "dict[str, Any] | None",
    entry_func: Any,
) -> Any:
    """Resolve one (kind, key, steps) specialization root path against THIS
    call's argument graph / the entry function's own live roots."""
    kind, key, steps = root_path
    try:
        if kind == "arg":
            if bound_args is None or key not in bound_args:
                # The argument is absent from this call's graph: the handle
                # keeps its compile-time capture; nothing to compare.
                return _SPEC_UNSUPPLIED
            cur = bound_args[key]
        elif kind == "global":
            fn_globals = getattr(entry_func, "__globals__", None)
            if not fn_globals or key not in fn_globals:
                return _SPEC_UNRESOLVABLE
            cur = fn_globals[key]
        elif kind == "module":
            cur = sys.modules.get(key)
            if cur is None:
                return _SPEC_UNRESOLVABLE
        elif kind == "closure":
            closure = getattr(entry_func, "__closure__", None)
            if not closure or key >= len(closure):
                return _SPEC_UNRESOLVABLE
            cur = closure[key].cell_contents
        else:
            return _SPEC_UNRESOLVABLE
        for step_kind, step_key in steps:
            cur = _spec_step_into(cur, step_kind, step_key)
        return cur
    except DSLUserCodeError:
        raise  # the purity guard's curated refusal is never demoted
    except Exception:
        return _SPEC_UNRESOLVABLE


# C-level storage descriptors (slot members / getsets) read memory and run no
# user code: STORAGE by declared fact (DF-2).
_SPEC_STORAGE_DESCRIPTORS = (types.MemberDescriptorType, types.GetSetDescriptorType)
_SPEC_STAGE_MISS = _Sentinel("spec stage miss")


def _spec_attr_stage(cur: Any, key: str) -> "tuple[str, Any]":
    """Classify one attribute hop on *cur* along CPython's own attribute
    precedence (data descriptor -> instance storage -> non-data class entry ->
    ``__getattr__``), each stage STORAGE or CODE by structural facts alone
    (DF-2) -- nothing user-defined executes here.  Returns ``("data", value)``
    for a storage answer or ``("code", stage_kind)`` when reaching the value
    would execute class code; raises ``AttributeError`` on structural absence.
    A type-level ``__getattribute__`` override changes native semantics
    invisibly to a structural walk, so every hop on such a type is CODE.
    Class and module owners are symbol NAMESPACES -- never wrapper-family --
    so their native lookup protocol is the declared (DF-5) channel."""
    if isinstance(cur, (type, types.ModuleType)):
        return ("code", "namespace-lookup")
    klass = type(cur)
    getattribute = getattr(klass, "__getattribute__", object.__getattribute__)
    if (
        getattribute is not object.__getattribute__
        and getattribute is not type.__getattribute__
    ):
        return ("code", "__getattribute__")
    class_entry: Any = _SPEC_STAGE_MISS
    for k in klass.__mro__:
        if key in k.__dict__:
            class_entry = k.__dict__[key]
            break
    if class_entry is not _SPEC_STAGE_MISS:
        entry_type = type(class_entry)
        if isinstance(class_entry, _SPEC_STORAGE_DESCRIPTORS):
            # Declared C-storage read; an unset slot falls through to the
            # __getattr__ stage exactly as native lookup does.
            try:
                return ("data", class_entry.__get__(cur, klass))
            except AttributeError:
                class_entry = _SPEC_STAGE_MISS
        elif hasattr(entry_type, "__get__") and (
            hasattr(entry_type, "__set__") or hasattr(entry_type, "__delete__")
        ):
            return ("code", "data-descriptor")
    inst = getattr(cur, "__dict__", None)
    if isinstance(inst, dict):
        val = dict.get(inst, key, _SPEC_STAGE_MISS)
        if val is not _SPEC_STAGE_MISS:
            return ("data", val)
    if class_entry is not _SPEC_STAGE_MISS:
        if hasattr(type(class_entry), "__get__"):
            return ("code", "non-data-descriptor")
        return ("data", class_entry)
    if getattr(klass, "__getattr__", None) is not None:
        return ("code", "__getattr__")
    raise AttributeError(key)


def _spec_step_into(cur: Any, step_kind: str, step_key: Any) -> Any:
    """Re-resolve one recorded step against a live object.  An attr step is
    an owner-SLOT hop: container adoption models dict items as owner slots,
    so a mapping at the hop resolves its slot by key; any unknown step kind
    or failing access raises (the caller reads it as unresolvable).  On an
    MLIR value-tree WRAPPER (its class implements ``__extract_mlir_values__``)
    an attr hop resolves structurally only: executing ANY code stage there
    (descriptor or ``__getattr__``) would re-run trace-time IR construction
    against consumed SSA (a crash channel), so it refuses loudly as a
    record-time classification bug.
    A plain live object keeps full attribute semantics -- re-running its
    property against live state is the designed exact re-derivation."""
    if step_kind == "attr":
        if isinstance(cur, dict):
            return cur[step_key]
        stage, payload = _spec_attr_stage(cur, str(step_key))
        if stage == "data":
            return payload
        if getattr(type(cur), "__extract_mlir_values__", None) is not None:
            raise DSLUserCodeError(
                DiagId.SPEC_DESCRIPTOR_HOP,
                attr=str(step_key),
                owner_type=type(cur).__name__,
                path=f"{type(cur).__name__}.{step_key}",
            )
        # DF-5: the declared plain-object code channel -- re-running a live
        # property/__getattr__ against live state is the exact re-derivation.
        return getattr(cur, step_key)
    if step_kind == "item":
        return cur[step_key]
    if step_kind == "cell":
        return cur.__closure__[step_key].cell_contents
    if step_kind == "default":
        return cur.__defaults__[step_key]
    if step_kind == "kwdefault":
        return cur.__kwdefaults__[step_key]
    raise KeyError(step_kind)


def _spec_scalarize(value: Any) -> Any:
    """Reduce a value-semantic numeric wrapper to its constexpr Python scalar so
    a baked scalar row compares BY VALUE against a live wrapper (a fresh Int32
    carrying the same number is not stale); any other value passes through
    unchanged (opaque objects keep identity)."""
    try:
        from .pyir_core import _NO_CONST_VALUE, _pyir_meta_primitive_value

        prim = _pyir_meta_primitive_value(value)
        return prim if prim is not _NO_CONST_VALUE else value
    except Exception:
        return value


def _spec_payloads_equal(baked: Any, live: Any) -> bool:
    """Exact structural equality between a baked payload and a live value
    (bool never equates to int at any depth -- tuple interiors compare
    element-wise; a failing/ambiguous ``==`` is a mismatch).  A trace-written
    object row verifies IDENTITY: the live value must BE the trace-exit
    object.  A live value-semantic numeric wrapper reduces to its scalar first,
    so a baked scalar verifies its VALUE, not the fresh wrapper's identity."""
    if isinstance(baked, _SpecTraceExitObject):
        return baked.matches(live)
    if isinstance(baked, _SpecContainerSnapshot):
        return baked.matches(live)
    live = _spec_scalarize(live)
    baked = _spec_scalarize(baked)
    if isinstance(baked, bool) != isinstance(live, bool):
        return False
    if isinstance(baked, tuple) or isinstance(live, tuple):
        if type(baked) is not type(live) or len(baked) != len(live):
            return False
        return all(_spec_payloads_equal(b, v) for b, v in zip(baked, live))
    try:
        return (baked == live) is True
    except Exception:
        return False


def _spec_format_root_path(root_path: tuple) -> str:
    """Author-readable spelling of a specialization root path."""
    kind, key, steps = root_path
    if kind == "arg":
        text = f"argument {key}" if isinstance(key, int) else f"argument '{key}'"
    elif kind == "global":
        text = f"global '{key}'"
    elif kind == "module":
        text = f"module '{key}'"
    else:
        text = f"closure cell {key}"
    for step_kind, step_key in steps:
        if step_kind == "attr":
            text += f".{step_key}"
        elif step_kind == "item":
            text += f"[{step_key!r}]"
        elif step_kind == "default":
            text += f".__defaults__[{step_key}]"
        elif step_kind == "kwdefault":
            text += f".__kwdefaults__[{step_key!r}]"
        else:
            text += f".<cell {step_key}>"
    return text


def _spec_resolve_unsupplied_root(
    root_path: tuple, entry_func: Any, receiver: Any, sig_facts: "tuple | None"
) -> Any:
    """An argument absent from the launch binding is a compile-time capture
    living on the handle itself.  Its live verification root is the sealed
    RECEIVER (a bound method's fixed first binding) or the entry function's
    CURRENT default object -- both can drift after compile, so both are read
    live and compared.  Call structure comes from the SEALED signature facts
    (DF-1); the default read is ``__defaults__[i]`` / ``__kwdefaults__[name]``
    -- pure data, never signature-code execution.  A root with neither
    channel keeps the compile-time capture only when nothing at the call
    could name it; a receiver-rooted row with no sealed receiver, or a
    default-rooted row whose index map sealed inconsistent, is unverifiable."""
    kind, key, steps = root_path
    if kind != "arg":
        return _SPEC_UNSUPPLIED
    if sig_facts is None:
        return _SPEC_UNSUPPLIED
    first_param, default_index = sig_facts
    root: Any = _SPEC_UNSUPPLIED
    if key == first_param and receiver is not None:
        if receiver is _SPEC_RECEIVER_DEAD:
            # The record roots at the receiver parameter but the receiver
            # died before the seal: nothing live can re-verify the row.
            return _SPEC_UNRESOLVABLE
        root = receiver
    if root is _SPEC_UNSUPPLIED and default_index is not None:
        fact = default_index.get(key)
        if fact is not None:
            if fact[0] == "pos":
                dflts = getattr(entry_func, "__defaults__", None) or ()
                if fact[1] >= len(dflts):
                    return _SPEC_UNRESOLVABLE  # defaults shape drifted
                root = dflts[fact[1]]
            else:
                kwd = getattr(entry_func, "__kwdefaults__", None) or {}
                if key not in kwd:
                    return _SPEC_UNRESOLVABLE  # kw-only default dropped
                root = kwd[key]
    elif root is _SPEC_UNSUPPLIED and default_index is None:
        # Seal-time signature/live-shape disagreement: nothing here can be
        # index-resolved -- the row is unverifiable (fail closed, never
        # index-shifted).
        return _SPEC_UNRESOLVABLE
    if root is _SPEC_UNSUPPLIED:
        return _SPEC_UNSUPPLIED
    cur = root
    try:
        for step_kind, step_key in steps:
            cur = _spec_step_into(cur, step_kind, step_key)
        return cur
    except DSLUserCodeError:
        raise  # the purity guard's curated refusal is never demoted
    except Exception:
        return _SPEC_UNRESOLVABLE


def _spec_verify_probe_row(
    root_path: tuple,
    baked: Any,
    bound_args: "dict[str, Any] | None",
    entry_func: Any,
    receiver: Any,
    sig_facts: "tuple | None",
) -> None:
    """Re-run a presence/absence PROBE row: the owner prefix must still
    resolve (fail closed otherwise) and the final attr hop must re-answer the
    baked boolean -- a flipped probe answer refuses instead of re-entering
    stale; the value behind a present probe is free to change."""
    kind, key, steps = root_path
    if not steps:
        raise DSLUserCodeError(DiagId.SPEC_UNVERIFIABLE_REENTRY)
    prefix_path = (kind, key, steps[:-1])
    owner = _spec_resolve_root_path(prefix_path, bound_args, entry_func)
    if owner is _SPEC_UNSUPPLIED:
        owner = _spec_resolve_unsupplied_root(
            prefix_path, entry_func, receiver, sig_facts
        )
    if owner is _SPEC_UNSUPPLIED:
        return  # omitted-argument root: the handle keeps its capture
    if owner is _SPEC_UNRESOLVABLE:
        raise DSLUserCodeError(
            DiagId.STALE_SPECIALIZATION,
            path=_spec_format_root_path(root_path),
            baked=repr(baked),
            live="<unresolvable>",
        )
    try:
        _spec_step_into(owner, *steps[-1])
        live_present = True
    except (AttributeError, KeyError, IndexError, TypeError):
        live_present = False
    if live_present == (baked is _SPEC_ATTR_PRESENT):
        return
    raise DSLUserCodeError(
        DiagId.STALE_SPECIALIZATION,
        path=_spec_format_root_path(root_path),
        baked=repr(baked),
        live="<attribute %s>" % ("present" if live_present else "absent"),
    )


def _pyir_validate_spec_reentry(
    spec: "tuple | None",
    execution_args: "ExecutionArgs | None",
    args: tuple,
    kwargs: dict,
) -> None:
    """V-11 SPEC-MATCH at the only no-retrace reuse event: every recorded root
    path must re-resolve to its baked exact payload, and the record must be
    complete -- a compiled handle cannot re-trace, so a mismatch refuses.
    Rows the launch binding does not name verify through the handle's own
    live captures (sealed receiver, signature defaults) instead of being
    silently skipped."""
    if spec is None:
        return
    record, complete, entry_func, receiver = spec[:4]
    sig_facts = spec[4] if len(spec) > 4 else None
    bound_args = (
        _spec_bound_call_arguments(execution_args, args, kwargs) if record else None
    )
    if isinstance(bound_args, _SpecBinderFailed):
        # An arg-rooted record cannot be verified without the launch binding;
        # a compiled handle cannot re-trace, so fail closed.
        if any(rp[0] == "arg" for rp in record):
            raise DSLUserCodeError(DiagId.SPEC_UNVERIFIABLE_REENTRY)
        bound_args = None
    for root_path, baked in record.items():
        if baked is _SPEC_ATTR_ABSENT or baked is _SPEC_ATTR_PRESENT:
            _spec_verify_probe_row(
                root_path, baked, bound_args, entry_func, receiver, sig_facts
            )
            continue
        live = _spec_resolve_root_path(root_path, bound_args, entry_func)
        if live is _SPEC_UNSUPPLIED:
            live = _spec_resolve_unsupplied_root(
                root_path, entry_func, receiver, sig_facts
            )
        if live is _SPEC_UNSUPPLIED:
            continue
        if live is _SPEC_UNRESOLVABLE or not _spec_payloads_equal(baked, live):
            raise DSLUserCodeError(
                DiagId.STALE_SPECIALIZATION,
                path=_spec_format_root_path(root_path),
                baked=repr(baked),
                live="<unresolvable>" if live is _SPEC_UNRESOLVABLE else repr(live),
            )
    if not complete:
        raise DSLUserCodeError(DiagId.SPEC_UNVERIFIABLE_REENTRY)


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "sys",
    "types",
    "Any",
    "TYPE_CHECKING",
    "DSLUserCodeError",
    "DiagId",
    "_Sentinel",
    "_SPEC_ATTR_ABSENT",
    "_SPEC_ATTR_PRESENT",
    "_SPEC_RECEIVER_DEAD",
    "_SpecContainerSnapshot",
    "_SpecTraceExitObject",
    "_SpecUnresolvable",
    "_SPEC_UNRESOLVABLE",
    "_SpecUnsupplied",
    "_SPEC_UNSUPPLIED",
    "_SpecBinderFailed",
    "_SPEC_BINDER_FAILED",
    "_spec_bound_call_arguments",
    "_spec_resolve_root_path",
    "_SPEC_STORAGE_DESCRIPTORS",
    "_SPEC_STAGE_MISS",
    "_spec_attr_stage",
    "_spec_step_into",
    "_spec_scalarize",
    "_spec_payloads_equal",
    "_spec_format_root_path",
    "_spec_resolve_unsupplied_root",
    "_spec_verify_probe_row",
    "_pyir_validate_spec_reentry",
]
