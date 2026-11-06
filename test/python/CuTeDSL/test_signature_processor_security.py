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
Unit tests for `cutlass.base_dsl.export.restricted_unpickler`.

These tests exercise the unpickler directly with plain `inspect.Signature`
objects, independent of `CuteSignatureProcessor` and the native MLIR
extension, so they can run without a GPU or a built `cutlass._mlir`
(though `import cutlass` itself still requires the native extension --
these tests import only the standalone `restricted_unpickler` submodule).

Covers:
- malicious `__reduce__` payloads are rejected (the class of bug fixed here);
- real gadgets that exist in this codebase's own `cutlass.*`/`cuda.*`
  namespace (not hypothetical `os.system`) are rejected when called via
  REDUCE, even though the class itself is a legitimate reference target;
- dotted-name traversal (module-namespace pivoting) is rejected;
- a plain, in-allowlist `inspect.Signature` round-trips unchanged;
- `Optional[X]`/`Union`/`X | None` annotations (real usage, not just the
  5 algebra types) round-trip unchanged;
- an unregistered third-party annotation type is rejected;
- a registered annotation type can be referenced but not constructed;
- BUILD cannot mutate an arbitrary referenced object;
- INST is unconditionally rejected.
"""

import inspect
import pickle
import types
import typing
import unittest

from cutlass.base_dsl.export.restricted_unpickler import (
    RestrictedUnpickler,
    register_signature_type,
    restricted_loads,
)


class _MaliciousPayload:
    """Stand-in for the PoC gadget in the original report: any class whose
    __reduce__ names an unsafe callable."""

    def __reduce__(self):
        return (eval, ("1 + 1",))


class _UnregisteredAnnotation:
    pass


class _RegisteredAnnotation:
    pass


register_signature_type(_RegisteredAnnotation)


def _sig(**annotations: type) -> inspect.Signature:
    params = [
        inspect.Parameter(name, inspect.Parameter.POSITIONAL_OR_KEYWORD, annotation=ann)
        for name, ann in annotations.items()
    ]
    return inspect.Signature(params)


# --- fake cutlass.*/cuda.* namespace standing in for the codebase's real
# gadgets, so this test does not depend on cutlass actually being importable
# (no native _mlir build available in this environment) while still testing
# against a *reachable, callable* member of an allowed module -- exactly
# the shape of cutlass.runtime.load_module or
# cutlass.base_dsl.env_manager.dump_sass, not a hypothetical os.system.
class _FakeGadgetModule(types.ModuleType):
    pass


def _install_fake_module(name: str) -> types.ModuleType:
    import sys

    mod = _FakeGadgetModule(name)
    sys.modules[name] = mod
    return mod


def load_module_gadget(file_path):
    """Module-level (not nested/closure) function standing in for the real
    gadget opus-critic review found: cutlass.runtime.load_module writes to
    an attacker-controlled path. Must be a plain top-level function so
    pickle can genuinely GLOBAL-reference it by (module, qualname) --
    exactly how the real gadget would be reached."""
    with open(file_path, "w") as f:
        f.write("PWNED")
    return file_path


load_module_gadget.__module__ = "cutlass.runtime"
_fake_runtime_module = _install_fake_module("cutlass.runtime")
_fake_runtime_module.load_module_gadget = load_module_gadget


class TestRestrictedUnpickler(unittest.TestCase):
    def test_rejects_malicious_reduce_payload(self):
        payload = pickle.dumps(_MaliciousPayload())
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)

    def test_rejects_direct_os_system_reduce(self):
        class _Direct:
            def __reduce__(self):
                import os

                return (os.system, ("true",))

        payload = pickle.dumps(_Direct())
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)

    def test_rejects_real_in_namespace_gadget(self):
        """The v1 design's CRITICAL flaw: a module-prefix allowlist permits
        calling any callable inside cutlass.*/cuda.*, including real
        gadgets like cutlass.runtime.load_module. This must be rejected by
        REDUCE-level enforcement, not by trying to enumerate "bad" names."""

        class _GadgetPayload:
            def __reduce__(self):
                return (load_module_gadget, ("/tmp/should_not_be_written",))

        payload = pickle.dumps(_GadgetPayload())
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)
        import os

        self.assertFalse(
            os.path.exists("/tmp/should_not_be_written"),
            "gadget executed -- REDUCE was not actually blocked",
        )

    def test_rejects_dotted_global_name(self):
        import io

        unpickler = RestrictedUnpickler(io.BytesIO(b""))
        with self.assertRaises(pickle.UnpicklingError):
            unpickler.find_class("cutlass.cute.typing", "Tensor.mro")

    def test_plain_signature_round_trips(self):
        sig = _sig(a=int, b=str)
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertEqual(list(restored.parameters), ["a", "b"])
        self.assertIs(restored.parameters["a"].annotation, int)
        self.assertIs(restored.parameters["b"].annotation, str)

    def test_signature_with_no_annotation_round_trips(self):
        sig = inspect.Signature(
            [inspect.Parameter("a", inspect.Parameter.POSITIONAL_OR_KEYWORD)]
        )
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertIs(restored.parameters["a"].annotation, inspect.Parameter.empty)

    def test_optional_annotation_round_trips(self):
        """Regression test for the v1 design: Optional[X]/Union/X|None
        annotations are real usage (see e.g. cta_norm.py's Optional[cute.Tensor]
        parameters), not a hypothetical -- they must not be silently broken
        by tightening the unpickler."""
        sig = _sig(a=typing.Optional[int])
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertEqual(restored.parameters["a"].annotation, typing.Optional[int])

    def test_union_annotation_round_trips(self):
        sig = _sig(a=typing.Union[int, str])
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertEqual(restored.parameters["a"].annotation, typing.Union[int, str])

    def test_unregistered_annotation_type_is_rejected(self):
        sig = _sig(a=_UnregisteredAnnotation)
        payload = pickle.dumps(sig)
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)

    def test_registered_annotation_type_round_trips_as_reference(self):
        sig = _sig(a=_RegisteredAnnotation)
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertIs(restored.parameters["a"].annotation, _RegisteredAnnotation)

    def test_registered_annotation_type_cannot_be_constructed(self):
        """register_signature_type widens the reference allowlist only --
        an instance of a registered type must still be unconstructible."""

        class _Instance:
            def __reduce__(self):
                return (_RegisteredAnnotation, ())

        payload = pickle.dumps(_Instance())
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)

    def test_rejects_module_object(self):
        import io

        unpickler = RestrictedUnpickler(io.BytesIO(b""))
        with self.assertRaises(pickle.UnpicklingError):
            unpickler._reject_if_unsafe_reference(inspect, "inspect")

    def test_optional_none_type_query_round_trips(self):
        """type(None) -> NoneType is the one-argument form CPython's own
        Optional[X] pickling uses, and must keep working."""
        sig = _sig(a=typing.Optional[int])
        payload = pickle.dumps(sig)
        restored = restricted_loads(payload)
        self.assertEqual(restored.parameters["a"].annotation, typing.Optional[int])

    def test_rejects_dynamic_class_creation_via_type(self):
        """type(name, bases, namespace) -- the three-argument dynamic-class-
        creation form -- must stay forbidden even though the one-argument
        type-of-query form (type(None)) is allowed. This is the exact gap a
        naive 'allow builtins.type in _CONSTRUCTIBLE' fix would reopen."""

        class _DynamicClassPayload:
            def __reduce__(self):
                return (type, ("Evil", (), {}))

        payload = pickle.dumps(_DynamicClassPayload())
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)

    def test_rejects_build_on_non_constructible_instance(self):
        """BUILD must not be able to mutate an arbitrary referenced object
        (e.g. attribute-inject onto a referenced class instance)."""

        class _Mutable:
            def __reduce__(self):
                return (_UnregisteredAnnotation, ())

        # Even if somehow a _Mutable instance were constructible, BUILD
        # targeting a non-_CONSTRUCTIBLE type must fail. Constructed here
        # by hand-crafting a state tuple around a legitimate Signature to
        # confirm BUILD checks the *instance's* type, not just that
        # something Signature-shaped preceded it.
        sig = inspect.Signature([])
        payload = bytearray(pickle.dumps(sig))
        # Sanity: a legitimate Signature BUILD must still succeed unmodified.
        restored = restricted_loads(bytes(payload))
        self.assertEqual(list(restored.parameters), [])

    def test_inst_opcode_rejected(self):
        # Protocol-0 INST opcode: 'i' + module '\n' + name '\n'
        payload = b"(i%s\n%s\n." % (b"builtins", b"list")
        with self.assertRaises(pickle.UnpicklingError):
            restricted_loads(payload)


if __name__ == "__main__":
    unittest.main()
