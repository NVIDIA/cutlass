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

"""Restricted unpickling for signature metadata read from external ``.o``/``.so``
artifacts (see ``cutlass.cute.export.export.CuteSignatureProcessor``).

Threat model
------------
By the time this module's ``loads()`` runs, the artifact's object code has
already been JIT-linked and any embedded global constructors have already
executed (see ``ExternalBinaryModule``'s load order). This unpickler does not
close that native-code-execution surface -- it removes a *second*,
independent path to code execution that is reachable by tampering with a
single metadata string (``<prefix>_args_spec``) alone, without needing a
valid native payload at all. This is defense-in-depth, not the primary
mitigation for untrusted artifacts.

Design (v2)
-----------
v1 of this module restricted *which classes could be looked up*
(``find_class``/``GLOBAL``) by a module-prefix allowlist (``cutlass.``,
``cuda.``). That is the wrong axis: looking up a class is harmless on its
own -- the danger is *calling* one with attacker-controlled arguments
(``REDUCE``/``NEWOBJ``/``NEWOBJ_EX``/``INST``), or mutating one via
attacker-controlled ``setattr``/``__dict__`` update (``BUILD``). A
module-prefix allowlist that permits *looking up* any symbol in
``cutlass.*``/``cuda.*`` also permits *calling* any of them -- including
real, already-existing callables like ``cutlass.runtime.load_module``
(JIT-links an arbitrary path) or
``cutlass.base_dsl.env_manager.dump_sass`` (writes an arbitrary file and
shells out to ``nvdisasm`` with attacker-controlled flags). Restricting
lookup by module prefix does nothing to restrict what a looked-up callable
can do once invoked -- v1 left every callable in two large namespaces
reachable via ``REDUCE``.

v2 restricts the two privileges separately, by overriding the pickle VM's
own opcode handlers rather than approximating the opcode stream:

- ``find_class`` (``GLOBAL``/``STACK_GLOBAL``) may resolve any class in an
  allowed module -- this is what lets a real ``inspect.Signature`` carry
  ``cutlass.cute.typing.Tensor`` or ``cuda.bindings.driver.CUstream`` as a
  plain (uninstantiated) value in a ``Parameter.annotation`` slot. The
  looked-up object is *referenced*, never *called*, by this step alone.
- ``load_reduce``/``load_newobj``/``load_newobj_ex``/``load_inst``
  (construction) are overridden to only ever call one of exactly
  ``inspect.Signature``, ``inspect.Parameter``, ``inspect._ParameterKind``
  -- checked by identity against the real stdlib objects, not by name, so
  no amount of module/name spoofing changes what gets called.
- ``load_build`` (mutation) is overridden to only operate when the target
  instance's *class* is one of those same three types.

Because these handlers are the actual pickle VM code path (not a
lookahead/approximation over the opcode stream), there is no risk of the
restriction and the real execution diverging on some opcode combination we
did not anticipate.

The result: an attacker's pickle can *reference* any class in an allowed
module (needed so a real signature's annotations round-trip), but cannot
*call or mutate* anything except the three fixed stdlib types the format
actually needs. There is no "safe callable" namespace to enumerate and keep
in sync with the codebase -- the constructible set is three fixed objects,
independent of what ``cutlass``/``cuda`` happen to expose now or in the
future.

User-defined annotation types (custom structs, dataclasses satisfying the
``__extract_mlir_values__`` protocol) are supported via explicit opt-in
registration through :func:`register_signature_type` for the *lookup*
allowlist only -- they can appear as a referenced value, same as any other
annotation type, but (like every other looked-up class) can never be
constructed or mutated by the pickle stream itself.
"""

import inspect
import io
import pickle
import types
from typing import Any


# Modules whose members may be *referenced* (looked up via GLOBAL /
# STACK_GLOBAL and used as plain values, e.g. as a Parameter.annotation),
# subject to the __module__ re-check in _reject_if_unsafe_reference below.
# This allowlist governs REFERENCE only -- it is never consulted by the
# construction/mutation handlers below, which use the separate, closed
# _CONSTRUCTIBLE identity set instead. See the module docstring for why
# that separation is what makes this safe even though the reference
# allowlist is comparatively wide.
_ALLOWED_REFERENCE_MODULE_PREFIXES = (
    "cutlass.",
    "cuda.",
)

# Exact (module, name) pairs that may be *referenced* regardless of the
# prefix allowlist above -- narrow, stdlib-only pieces needed for a plain
# value (not construction) to round-trip: primitive type objects used as
# annotations (`int`, `str`, ...) and the small set of typing/operator
# machinery `typing.Optional[X]`/`typing.Union[X, Y]` pickle down to.
_EXACT_ALLOWED_REFERENCES = {
    ("builtins", "int"),
    ("builtins", "float"),
    ("builtins", "bool"),
    ("builtins", "str"),
    ("builtins", "bytes"),
    ("builtins", "list"),
    ("builtins", "dict"),
    ("builtins", "tuple"),
    ("builtins", "set"),
    ("builtins", "frozenset"),
    ("typing", "Union"),
    ("typing", "Optional"),
    ("_operator", "getitem"),
    ("builtins", "type"),
}

# builtins.type is deliberately NOT in _CONSTRUCTIBLE. type(x) (one
# argument: the type-of query CPython's own Optional[X]/Union[X, Y]
# pickling uses -- e.g. type(None) to reconstruct NoneType) is safe, but
# type(name, bases, namespace) (three arguments: dynamic class creation)
# is not -- it would let a crafted pickle define an arbitrary class with an
# attacker-chosen __reduce__/__init__ at unpickle time. load_reduce special-
# cases builtins.type separately from _CONSTRUCTIBLE specifically to allow
# only the one-argument form.

# The exact, closed set of *objects* (by identity, not by name) that
# load_reduce/load_newobj/load_newobj_ex/load_inst may call, and whose
# instances load_build may mutate. Fixed at import time from the real
# stdlib objects -- never derived from a name lookup, so nothing the
# pickle stream provides can add to this set.
#
# operator.getitem is included because typing.Optional[X]/typing.Union[X, Y]
# pickle down to REDUCE(operator.getitem, (typing.Union, (X, Y))) -- this
# is how CPython's own pickle support for typing generics works, not
# something introduced by this format. It is safe to include: getitem's own
# behavior is to call `__getitem__` on its first argument, and that first
# argument is *also* checked against _CONSTRUCTIBLE union
# _EXACT_ALLOWED_REFERENCES at the point it was referenced -- an attacker
# cannot substitute a dangerous first argument here without that reference
# already having been rejected by find_class.
_CONSTRUCTIBLE: frozenset[Any] = frozenset(
    {
        inspect.Signature,
        inspect.Parameter,
        inspect._ParameterKind,
        __import__("operator").getitem,
    }
)

# User-registered annotation types, keyed by (module, qualname). Widens the
# *reference* allowlist only -- never _CONSTRUCTIBLE, which is fixed above
# and not extensible at runtime.
_REGISTERED_REFERENCE_TYPES: set[tuple[str, str]] = set()


def register_signature_type(cls: type) -> None:
    """Opt in a user-defined annotation type for signature round-tripping.

    Call this once (e.g. at import time of the module defining ``cls``) for
    any custom type that may appear as a ``@cute.jit`` parameter annotation
    and therefore needs to survive ``CuteSignatureProcessor.dumps()`` /
    ``loads()``. Types are looked up by their *current* ``__module__`` and
    ``__qualname__``, so registration must happen after the class's final
    module assignment.

    This only permits ``cls`` to be *referenced* as a value (e.g. as an
    annotation) -- it does not permit the pickle stream to construct or
    mutate an instance of ``cls``; nothing outside ``_CONSTRUCTIBLE`` can be,
    and that set cannot be widened at runtime.
    """
    _REGISTERED_REFERENCE_TYPES.add((cls.__module__, cls.__qualname__))


def _reference_allowed(module_name: str) -> bool:
    return any(
        module_name.startswith(prefix)
        for prefix in _ALLOWED_REFERENCE_MODULE_PREFIXES
    )


class RestrictedUnpickler(pickle._Unpickler):
    """``pickle.Unpickler`` that separates two privileges pickle normally
    conflates:

    Deliberately subclasses ``pickle._Unpickler`` (the pure-Python
    implementation), not ``pickle.Unpickler`` (an alias for the C-accelerated
    ``_pickle.Unpickler`` on CPython). The C implementation has no
    overridable, per-opcode ``dispatch`` table -- overriding
    ``load_reduce``/``load_build``/etc. on a subclass of it does nothing,
    since the C loop never consults Python-level dispatch. This is slower
    than the C path, but this unpickler only ever runs against small
    (kilobyte-scale) signature metadata, not large data payloads, so the
    difference is immaterial here.

    - *referencing* a class/callable as a plain value (``GLOBAL`` /
      ``STACK_GLOBAL``) -- allowed for a module-prefix allowlist, because an
      annotation value is inert on its own;
    - *constructing or mutating* an object (``REDUCE`` / ``NEWOBJ`` /
      ``NEWOBJ_EX`` / ``INST`` / ``BUILD``) -- allowed only for the fixed,
      closed identity set in ``_CONSTRUCTIBLE``, enforced by overriding the
      opcode handlers themselves (not by pre-scanning the stream).

    See the module docstring for why this is the correct axis.
    """

    def find_class(self, module: str, name: str) -> Any:
        # Reject dotted names outright. A dotted STACK_GLOBAL name is
        # resolved by getattr-chaining through the *module*'s namespace,
        # which can reach names the module merely imported (e.g. a
        # cutlass.* module that does `import os` making "cutlass.foo.os"
        # reachable). The checks below only make sense against a plain,
        # non-dotted `name`.
        if "." in name:
            raise pickle.UnpicklingError(f"forbidden dotted global: {module}.{name}")

        if (module, name) in _REGISTERED_REFERENCE_TYPES:
            # Explicit opt-in via register_signature_type: the caller
            # vouched for this exact (module, qualname) pair, so the
            # __module__ re-check below (meant to catch names merely
            # *reachable through* an allowed module's namespace) does not
            # apply -- this IS the trusted target, not something found by
            # walking through one. Referencing it grants no call/mutate
            # rights regardless; _CONSTRUCTIBLE is unaffected.
            return super().find_class(module, name)

        # Exact stdlib pieces needed to reference plain-value annotations
        # (builtins.int/str/..., inspect.Signature/Parameter/..., the
        # typing.Union/Optional generics). Referencing these grants no
        # call/mutate rights -- that is governed separately by
        # _CONSTRUCTIBLE in the load_reduce/load_newobj/load_build handlers
        # below.
        if (module, name) in _EXACT_ALLOWED_REFERENCES or (
            module == "inspect"
            and name in ("Signature", "Parameter", "_ParameterKind", "_empty")
        ):
            return super().find_class(module, name)

        if _reference_allowed(module):
            resolved = super().find_class(module, name)
            self._reject_if_unsafe_reference(resolved, module)
            return resolved

        raise pickle.UnpicklingError(f"forbidden global: {module}.{name}")

    @staticmethod
    def _reject_if_unsafe_reference(resolved: Any, requested_module: str) -> None:
        # A module object itself must never be returned: even as a "plain
        # reference", a module exposes arbitrary further attribute access,
        # and (per the construction handlers below) module objects are
        # never in _CONSTRUCTIBLE, so this is purely an extra guard against
        # surprising downstream isinstance/attribute-access misuse.
        if isinstance(resolved, types.ModuleType):
            raise pickle.UnpicklingError(
                f"forbidden global: module object from {requested_module}"
            )
        # Re-check the resolved object's *own* module, not just the name it
        # was requested under. Prevents referencing e.g. `os.system` via a
        # cutlass/cuda module's local `os` binding -- and even if this
        # check were somehow bypassed, load_reduce below would still refuse
        # to *call* the result, since os.system is not in _CONSTRUCTIBLE.
        actual_module = getattr(resolved, "__module__", None)
        if actual_module is not None and not _reference_allowed(actual_module):
            raise pickle.UnpicklingError(
                f"forbidden global: resolved object's module {actual_module} "
                f"is not allowed (requested via {requested_module})"
            )

    # --- construction/mutation handlers: the actual security boundary ---
    #
    # These override pickle._Unpickler's real implementations (verified
    # against CPython's pickle module) with an added identity check against
    # _CONSTRUCTIBLE before doing anything else. Falling through to
    # super().load_xxx() for the allowed case keeps exact stdlib semantics
    # (slotstate handling, __setstate__ dispatch, etc.) rather than
    # reimplementing them.

    def load_reduce(self) -> None:
        func = self.stack[-2]
        args = self.stack[-1]
        if func is type:
            # Special-cased, not in _CONSTRUCTIBLE: only the one-argument
            # type-of-query form (type(None) -> NoneType, as CPython's own
            # Optional[X]/Union[X, Y] pickling uses) is safe. The
            # three-argument dynamic-class-creation form
            # (type(name, bases, namespace)) must stay forbidden -- it
            # would let a crafted pickle define an arbitrary class with an
            # attacker-chosen __reduce__/__init__ at unpickle time.
            if not (isinstance(args, tuple) and len(args) == 1):
                raise pickle.UnpicklingError(
                    "forbidden REDUCE: type() is only permitted as a "
                    "one-argument type-of query"
                )
        elif func not in _CONSTRUCTIBLE:
            raise pickle.UnpicklingError(
                f"forbidden REDUCE: {func!r} is not constructible"
            )
        super().load_reduce()

    dispatch = dict(pickle._Unpickler.dispatch)
    dispatch[pickle.REDUCE[0]] = load_reduce

    def load_newobj(self) -> None:
        cls = self.stack[-2]
        if cls not in _CONSTRUCTIBLE:
            raise pickle.UnpicklingError(
                f"forbidden NEWOBJ: {cls!r} is not constructible"
            )
        super().load_newobj()

    dispatch[pickle.NEWOBJ[0]] = load_newobj

    def load_newobj_ex(self) -> None:
        cls = self.stack[-3]
        if cls not in _CONSTRUCTIBLE:
            raise pickle.UnpicklingError(
                f"forbidden NEWOBJ_EX: {cls!r} is not constructible"
            )
        super().load_newobj_ex()

    if hasattr(pickle, "NEWOBJ_EX"):
        dispatch[pickle.NEWOBJ_EX[0]] = load_newobj_ex

    def load_inst(self) -> None:
        # INST (opcode 'i') is a legacy protocol-0 opcode that reads a
        # dotted module/class name directly from the pickle stream (not
        # from the stack) and instantiates it. It predates GLOBAL and is
        # not used by any modern pickle.dumps() output, but a crafted
        # payload could still contain it. Unconditionally forbidden: there
        # is no legitimate use of INST in this format.
        raise pickle.UnpicklingError("forbidden opcode: INST is not supported")

    dispatch[pickle.INST[0]] = load_inst

    def load_build(self) -> None:
        inst = self.stack[-2]
        if type(inst) not in _CONSTRUCTIBLE:
            raise pickle.UnpicklingError(
                f"forbidden BUILD: {type(inst)!r} instances are not mutable "
                f"by this format"
            )
        super().load_build()

    dispatch[pickle.BUILD[0]] = load_build


def restricted_loads(data: bytes) -> Any:
    """Safe drop-in replacement for ``pickle.loads(data)`` on signature
    metadata: rejects any payload that would construct or mutate anything
    other than ``inspect.Signature``/``Parameter``/``_ParameterKind``, or
    that would reference a class outside the DSL's own namespace (see
    module docstring)."""
    return RestrictedUnpickler(io.BytesIO(data)).load()
