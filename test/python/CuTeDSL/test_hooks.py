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


"""
Unit tests for the compilation hooks of ``BaseDSL``.

Hooks run at points of the compilation, one ``HookEvent`` each. A trace
finalize hook runs after tracing and before the module is hashed; a
compilation hook runs after each compilation or in-memory cache hit; a launch
hook runs before each call to a compiled host function, once per call however
many kernels it launches, and receives the runtime arguments of the call.
Compilation and launch hooks receive the module hash, which is how a tracer
ties a call to the compilation behind it.
``register_trace_finalize_hook`` and ``trace_finalize_hooks`` keep their
positional form on top of the same hooks.

The tests compile and launch a small kernel, so they need a CUDA GPU and skip
without one.
"""

import contextvars
import dataclasses
import functools
import importlib.util
import re
import unittest
import warnings
from unittest import mock

import torch

import cutlass
from cutlass import hooks as public_hooks
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.base_dsl.cache_helpers import JitCacheDict
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.compiler import CompileOptions
from cutlass.hooks import (
    CompilationEvent,
    HookEvent,
    LaunchEvent,
    TraceFinalizeEvent,
)
from cutlass.base_dsl.jit_executor import JitFunctionArtifacts
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import CuTeDSL


@cute.kernel
def _fill(t: cute.Tensor, value: cutlass.Int32):
    tidx, _, _ = cute.arch.thread_idx()
    t[tidx] = value


@cute.jit
def _launch(t: cute.Tensor, value: cutlass.Int32, threads: cutlass.Constexpr[int]):
    _fill(t, value).launch(grid=[1, 1, 1], block=[threads, 1, 1])


@cute.kernel
def _add(t: cute.Tensor, value: cutlass.Int32):
    tidx, _, _ = cute.arch.thread_idx()
    t[tidx] = t[tidx] + value


@cute.jit
def _fill_then_add(t: cute.Tensor, value: cutlass.Int32):
    _fill(t, value).launch(grid=[1, 1, 1], block=[32, 1, 1])
    _add(t, value).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _empty():
    pass


@cute.jit
def _launch_empty(threads: cutlass.Constexpr[int]):
    _empty().launch(grid=[1, 1, 1], block=[threads, 1, 1])


#: Every ``_launch`` call runs each of these once: tracing happens on every
#: call, a compilation hook runs on the compilation or the cache hit, and a
#: launch hook on the call.
_EVENTS = (HookEvent.POST_TRACE, HookEvent.POST_COMPILE, HookEvent.PRE_EXECUTE)


class _Recorder:
    """A hook that records every event it receives."""

    def __init__(self):
        self.events = []

    def __call__(self, event):
        self.events.append(event)

    def field(self, name):
        return [getattr(event, name) for event in self.events]


def _failing_hook(event):
    raise ValueError("hook bug")


def _failing_positional_hook(owner, module, function_name):
    raise ValueError("hook bug")


def _bind(event):
    """Name each runtime argument of a call the way a tracer does: ``args[i]``
    binds to ``arg_names[i]``, and ``kwargs`` are keyed by name already."""
    bound = dict(zip(event.arg_names, event.args))
    bound.update(event.kwargs)
    return bound


def _flat_message(exc):
    """Diagnostics are wrapped and colorized before they reach the user, so
    match against the message with that formatting flattened out."""
    return " ".join(re.sub(r"\x1b\[[0-9;]*m", "", str(exc)).split())


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class _HookTestCase(unittest.TestCase):
    def setUp(self):
        self.dsl = CuTeDSL._get_dsl()
        # A fresh in-memory JIT cache, so whether a call hits the cache does not
        # depend on the tests that ran before.
        self._patch(self.dsl, "jit_cache", JitCacheDict())
        # Caching on, whatever CUTE_DSL_NO_CACHE or CUTE_DSL_KEEP=ptx/cubin/sass
        # say, so the cache-hit tests do not depend on the environment.
        self.patch_envar(
            no_cache=False, keep_ptx=False, keep_cubin=False, keep_sass=False
        )
        self.data = torch.zeros(32, dtype=torch.int32, device="cuda")
        self.t = from_dlpack(self.data)

    def _patch(self, target, name, value):
        patcher = mock.patch.object(target, name, value)
        patcher.start()
        self.addCleanup(patcher.stop)

    def patch_envar(self, **settings):
        for name, value in settings.items():
            self._patch(self.dsl.envar, name, value)

    def register(self, event, hook):
        self.dsl.register_hook(event, hook)
        self.addCleanup(self.dsl.remove_hook, event, hook)


class TestHookRegistration(_HookTestCase):
    def test_public_and_dsl_apis_share_registrations_and_scopes(self):
        for event in _EVENTS:
            with self.subTest(event=event):
                hook = _Recorder()
                public_hooks.register_hook(event, hook)
                self.addCleanup(public_hooks.remove_hook, event, hook)
                self.dsl.register_hook(event, hook)
                with public_hooks.hooks(event, hook, dsl=self.dsl):
                    _launch(self.t, 1, 32)
                self.assertEqual(len(hook.events), 1)
                self.dsl.remove_hook(event, hook)
                _launch(self.t, 1, 32)
                self.assertEqual(len(hook.events), 1)
                self.register(event, hook)
                public_hooks.remove_hook(event, hook, dsl=self.dsl)
                _launch(self.t, 1, 32)
                self.assertEqual(len(hook.events), 1)

    def test_rejects_unknown_events_none_and_non_callables(self):
        for event in ("compilation", None):
            with self.subTest(event=event):
                with self.assertRaises(DSLRuntimeError):
                    self.dsl.register_hook(event, _Recorder())
        for event in _EVENTS:
            for hook in (None, 42):
                with self.subTest(event=event, hook=hook):
                    with self.assertRaises(DSLRuntimeError):
                        self.dsl.register_hook(event, hook)
            for hooks in (None, 42, [_Recorder(), None], [42]):
                with self.subTest(event=event, scoped=hooks):
                    with self.assertRaises(DSLRuntimeError):
                        with self.dsl.hooks(event, hooks):
                            pass

    def test_registering_twice_runs_once_and_removal_stops_it(self):
        for event in _EVENTS:
            with self.subTest(event=event):
                hook = _Recorder()
                self.dsl.register_hook(event, hook)
                self.dsl.register_hook(event, hook)
                try:
                    _launch(self.t, 1, 32)
                finally:
                    self.dsl.remove_hook(event, hook)
                _launch(self.t, 1, 32)
                self.assertEqual(len(hook.events), 1)
                # Removing a hook that is not registered is a no-op.
                self.dsl.remove_hook(event, hook)

    def test_scoped_hooks_apply_inside_the_block_only(self):
        for event in _EVENTS:
            with self.subTest(event=event):
                outer, inner = _Recorder(), _Recorder()
                with self.dsl.hooks(event, outer):
                    with self.dsl.hooks(event, [inner, outer]):
                        _launch(self.t, 1, 32)
                    _launch(self.t, 1, 32)
                _launch(self.t, 1, 32)
                # outer is in both scopes, and still runs once per call.
                self.assertEqual(len(outer.events), 2)
                self.assertEqual(len(inner.events), 1)

    def test_registered_and_scoped_hook_runs_once(self):
        for event in _EVENTS:
            with self.subTest(event=event):
                hook = _Recorder()
                self.register(event, hook)
                with self.dsl.hooks(event, hook):
                    _launch(self.t, 1, 32)
                self.assertEqual(len(hook.events), 1)

    def test_scoped_hooks_follow_the_context(self):
        """Scoped hooks live in a ``ContextVar``: a fresh context does not see
        them, a copied one inherits them, and leaving the block restores the
        previous state, also when the block raises."""
        call = functools.partial(_launch, self.t, 1, 32)
        for event in _EVENTS:
            with self.subTest(event=event):
                scoped, registered = _Recorder(), _Recorder()
                self.register(event, registered)
                with self.dsl.hooks(event, scoped):
                    call()
                    contextvars.Context().run(call)
                    contextvars.copy_context().run(call)
                self.assertEqual(len(scoped.events), 2)
                self.assertEqual(len(registered.events), 3)
                with self.assertRaises(ValueError), self.dsl.hooks(event, scoped):
                    raise ValueError("block failed")
                call()
                self.assertEqual(len(scoped.events), 2)
                self.assertEqual(len(registered.events), 4)


class TestTraceFinalizeHook(_HookTestCase):
    def test_legacy_apis_warn_once_at_the_user_call(self):
        def positional(owner, module, function_name):
            pass

        def register():
            self.dsl.register_trace_finalize_hook(positional)
            self.dsl.remove_hook(HookEvent.POST_TRACE, positional)

        def scoped():
            with self.dsl.trace_finalize_hooks(positional):
                pass

        def compile_legacy():
            cute.compile(_launch, self.t, 1, 32, trace_finalize_hooks=positional)

        for call in (register, scoped, compile_legacy):
            with self.subTest(call=call.__name__):
                with warnings.catch_warnings(record=True) as caught:
                    warnings.simplefilter("always", DeprecationWarning)
                    call()
                deprecations = [w for w in caught if w.category is DeprecationWarning]
                self.assertEqual(len(deprecations), 1)
                self.assertEqual(deprecations[0].filename, __file__)
                self.assertIn("POST_TRACE", str(deprecations[0].message))

    def test_event_form(self):
        traces, compilations = _Recorder(), _Recorder()
        self.register(HookEvent.POST_TRACE, traces)
        self.register(HookEvent.POST_COMPILE, compilations)
        _launch(self.t, 1, 32)
        (event,) = traces.events
        self.assertIsInstance(event, TraceFinalizeEvent)
        self.assertIs(event.owner, self.dsl)
        self.assertIsInstance(event.module, ir.Module)
        self.assertEqual(event.function_name, compilations.events[0].function_name)

    def test_positional_form(self):
        """register_trace_finalize_hook keeps its ``hook(owner, module,
        function_name)`` form, ignores a second registration of the same hook,
        and remove_hook takes the original hook."""
        calls = []

        def hook(owner, module, function_name):
            calls.append((owner, module, function_name))

        self.dsl.register_trace_finalize_hook(hook)
        self.dsl.register_trace_finalize_hook(hook)
        try:
            _launch(self.t, 1, 32)
        finally:
            self.dsl.remove_hook(HookEvent.POST_TRACE, hook)
        _launch(self.t, 1, 32)
        ((owner, module, function_name),) = calls
        self.assertIs(owner, self.dsl)
        self.assertIsInstance(module, ir.Module)
        self.assertIsInstance(function_name, str)

    def test_scoped_positional_form(self):
        calls = []

        def hook(owner, module, function_name):
            calls.append(function_name)

        with self.dsl.trace_finalize_hooks([hook, hook]):
            _launch(self.t, 1, 32)
        _launch(self.t, 1, 32)
        self.assertEqual(len(calls), 1)

    def test_cute_compile_hooks_apply_to_that_compile_only(self):
        calls = []

        def hook(owner, module, function_name):
            calls.append(function_name)

        cute.compile(_launch, self.t, 1, 32, trace_finalize_hooks=hook)
        _launch(self.t, 1, 32)
        self.assertEqual(len(calls), 1)

        # The hooks of a failed compile are removed too.
        with self.assertRaises(DSLRuntimeError):
            cute.compile(
                _launch, self.t, 1, 32, trace_finalize_hooks=_failing_positional_hook
            )
        cute.compile(_launch, self.t, 1, 32)

    def test_hook_may_annotate_the_module_before_hashing(self):
        def annotate(event):
            event.module.operation.attributes["cute_test.annotated"] = ir.UnitAttr.get()

        compilations = _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, compilations):
            cute.compile(_launch, self.t, 1, 32)
            with self.dsl.hooks(HookEvent.POST_TRACE, annotate):
                cute.compile(_launch, self.t, 1, 32)
        plain, annotated = compilations.field("module_hash")
        self.assertNotEqual(plain, annotated)

    def test_hook_error_is_wrapped(self):
        for register, hook, name in (
            (
                self.dsl.trace_finalize_hooks,
                _failing_positional_hook,
                "_failing_positional_hook",
            ),
            (
                functools.partial(self.dsl.hooks, HookEvent.POST_TRACE),
                _failing_hook,
                "_failing_hook",
            ),
        ):
            with self.subTest(hook=name):
                with register(hook):
                    with self.assertRaises(DSLRuntimeError) as ctx:
                        _launch(self.t, 1, 32)
                self.assertIn(
                    f"Trace finalize hook failed: {name}", _flat_message(ctx.exception)
                )
                self.assertIsInstance(ctx.exception.__cause__, ValueError)


class TestCompilationHook(_HookTestCase):
    def test_compile_hooks_are_scoped_and_deduplicated(self):
        outer, inner, traces = _Recorder(), _Recorder(), _Recorder()
        with public_hooks.hooks(HookEvent.POST_COMPILE, outer):
            cute.compile(
                _launch,
                self.t,
                1,
                32,
                hooks={
                    HookEvent.POST_TRACE: traces,
                    HookEvent.POST_COMPILE: [inner, outer],
                },
            )
            _launch(self.t, 1, 32)
        self.assertEqual(len(outer.events), 2)
        self.assertEqual(len(inner.events), 1)
        self.assertEqual(len(traces.events), 1)

    def test_compile_hook_failures_restore_all_scopes(self):
        recorder = _Recorder()
        for mapping in (
            [],
            {HookEvent.POST_TRACE: recorder, "unknown": recorder},
            {HookEvent.POST_TRACE: recorder, HookEvent.POST_COMPILE: None},
            {HookEvent.POST_TRACE: recorder, HookEvent.POST_COMPILE: _failing_hook},
        ):
            with self.subTest(mapping=mapping):
                with self.assertRaises(DSLRuntimeError):
                    cute.compile(_launch, self.t, 1, 32, hooks=mapping)
                count = len(recorder.events)
                cute.compile(_launch, self.t, 1, 32)
                self.assertEqual(len(recorder.events), count)

    def test_legacy_and_new_compile_hooks_compose_in_order(self):
        order = []

        def positional(owner, module, function_name):
            order.append("legacy")

        with self.assertWarns(DeprecationWarning):
            cute.compile(
                _launch,
                self.t,
                1,
                32,
                trace_finalize_hooks=positional,
                hooks={
                    HookEvent.POST_TRACE: lambda event: order.append("trace"),
                    HookEvent.POST_COMPILE: lambda event: order.append("compile"),
                },
            )
        self.assertEqual(order, ["legacy", "trace", "compile"])

    def test_reports_a_compilation_then_a_cache_hit(self):
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, hook):
            _launch(self.t, 1, 32)
            _launch(self.t, 1, 32)
        self.assertEqual(hook.field("cache_hit"), [False, True])
        first, second = hook.events
        self.assertIsInstance(first.module_hash, str)
        self.assertEqual(second.module_hash, first.module_hash)
        self.assertEqual(second.function_name, first.function_name)

    def test_payload(self):
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, hook):
            _launch(self.t, 1, 32)
        (event,) = hook.events
        self.assertIsInstance(event, CompilationEvent)
        self.assertIs(event.owner, self.dsl)
        self.assertIsInstance(event.artifacts, JitFunctionArtifacts)
        self.assertIsInstance(event.compile_options, CompileOptions)
        self.assertEqual(event.func_body.__name__, "_launch")
        self.assertTrue(any("_fill" in name for name in event.kernel_info))
        # Events are read-only.
        with self.assertRaises(dataclasses.FrozenInstanceError):
            event.cache_hit = True

    def test_each_specialization_has_its_own_hash(self):
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, hook):
            _launch(self.t, 1, 32)
            _launch(self.t, 1, 16)
        self.assertEqual(hook.field("cache_hit"), [False, False])
        first, second = hook.field("module_hash")
        self.assertNotEqual(first, second)

    def test_hash_is_computed_for_hooks_when_caching_is_off(self):
        """Without caching there is no cache key to compute, but compilation
        hooks still need the hash to tell specializations apart. Caching stays
        off."""
        self.patch_envar(no_cache=True)
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, hook):
            _launch(self.t, 1, 32)
            _launch(self.t, 1, 32)
        self.assertEqual(hook.field("cache_hit"), [False, False])
        first, second = hook.field("module_hash")
        self.assertIsInstance(first, str)
        self.assertEqual(first, second)

    def test_no_hash_without_compilation_hooks(self):
        """``cute.compile`` never caches, so it hashes the module only when a
        compilation hook needs the hash; a trace finalize hook does not."""
        self.assertIsNone(cute.compile(_launch, self.t, 1, 32).module_hash)
        with self.dsl.hooks(HookEvent.POST_TRACE, _Recorder()):
            self.assertIsNone(cute.compile(_launch, self.t, 1, 32).module_hash)
        with self.dsl.hooks(HookEvent.POST_COMPILE, _Recorder()):
            compiled = cute.compile(_launch, self.t, 1, 32)
        self.assertIsInstance(compiled.module_hash, str)

    def test_hook_may_compile_another_function(self):
        """The hook runs after the compilation has finished, so it can compile
        another function."""
        hook = _Recorder()
        inner = []

        def compile_once(event):
            hook(event)
            # Only the outer compilation compiles; the inner one is reported
            # to this hook too.
            if len(hook.events) == 1:
                inner.append(cute.compile(_launch_empty, 16))

        with self.dsl.hooks(HookEvent.POST_COMPILE, compile_once):
            compiled = cute.compile(_launch, self.t, 7, 32)
        outer_event, inner_event = hook.events
        self.assertNotEqual(outer_event.function_name, inner_event.function_name)
        self.assertNotEqual(outer_event.module_hash, inner_event.module_hash)
        self.assertIsNot(outer_event.kernel_info, inner_event.kernel_info)
        self.assertTrue(any("_fill" in name for name in outer_event.kernel_info))
        self.assertTrue(any("_empty" in name for name in inner_event.kernel_info))
        compiled(self.t, 7)
        inner[0]()
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 7))

    def test_hook_error_is_wrapped(self):
        with self.dsl.hooks(HookEvent.POST_COMPILE, _failing_hook):
            with self.assertRaises(DSLRuntimeError) as ctx:
                _launch(self.t, 1, 32)
        self.assertIn(
            "Compilation hook failed: _failing_hook", _flat_message(ctx.exception)
        )
        self.assertIsInstance(ctx.exception.__cause__, ValueError)
        # The DSL stays usable.
        _launch(self.t, 2, 32)
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 2))


class TestLaunchHook(_HookTestCase):
    def test_compile_scoped_execute_hooks_do_not_follow_the_function(self):
        scoped, outer = _Recorder(), _Recorder()
        with public_hooks.hooks(HookEvent.PRE_EXECUTE, outer):
            compiled = cute.compile(
                _launch, self.t, 1, 32, hooks={HookEvent.PRE_EXECUTE: scoped}
            )
            self.assertEqual(outer.events, [])
            compiled(self.t, 3)
            _launch(self.t, 4, 32)
        self.assertEqual(scoped.events, [])
        self.assertEqual(
            [_bind(event) for event in outer.events],
            [{"t": self.t, "value": value} for value in (3, 4)],
        )

    def test_arguments_bind_to_their_names_on_every_path(self):
        """Implicit calls and direct calls to a compiled function report the
        runtime arguments, without the Constexpr ``threads``."""
        compiled = cute.compile(_launch, self.t, 1, 32)
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
            _launch(self.t, 3, 32)
            _launch(self.t, value=4, threads=32)
            compiled(self.t, 5)
            compiled(self.t, value=6)
        self.assertEqual(
            [_bind(event) for event in hook.events],
            [{"t": self.t, "value": value} for value in (3, 4, 5, 6)],
        )
        for event in hook.events:
            self.assertIsInstance(event, LaunchEvent)
            self.assertEqual(event.arg_names, ("t", "value"))
        # The hook sees the objects the caller passed.
        self.assertIs(hook.events[0].args[0], self.t)
        # An implicit launch reports the runtime parameters in declaration
        # order, while a direct call reports keyword arguments as keywords.
        self.assertEqual(hook.events[1].args, (self.t, 4))
        self.assertEqual(hook.events[3].kwargs, {"value": 6})
        # The kernel still ran, with the last value.
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 6))

    def test_launch_carries_the_hash_of_its_compilation(self):
        compilations, launches = _Recorder(), _Recorder()
        with self.dsl.hooks(HookEvent.POST_COMPILE, compilations), self.dsl.hooks(
            HookEvent.PRE_EXECUTE, launches
        ):
            _launch(self.t, 1, 32)
            _launch(self.t, 1, 16)
            compiled = cute.compile(_launch, self.t, 1, 8)
            compiled(self.t, 1)
        self.assertEqual(
            launches.field("module_hash"), compilations.field("module_hash")
        )
        self.assertEqual(
            launches.field("function_name"), compilations.field("function_name")
        )
        self.assertEqual(launches.field("owner"), [self.dsl] * 3)

    def test_launch_hook_alone_gets_the_hash(self):
        """A launch hook needs the hash to tie a call to its compilation, so
        cute.compile computes it while only a launch hook is registered."""
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
            compiled = cute.compile(_launch, self.t, 1, 32)
            compiled(self.t, 1)
        self.assertIsInstance(compiled.module_hash, str)
        self.assertEqual(hook.field("module_hash"), [compiled.module_hash])

    def test_compilation_is_reported_before_its_launch(self):
        events = []
        with self.dsl.hooks(
            HookEvent.POST_COMPILE, lambda e: events.append("compile")
        ), self.dsl.hooks(HookEvent.PRE_EXECUTE, lambda e: events.append("launch")):
            _launch(self.t, 1, 32)
            _launch(self.t, 1, 32)
        self.assertEqual(events, ["compile", "launch"] * 2)

    def test_one_event_per_host_call(self):
        """A launch hook reports each call to a compiled host function once,
        however many kernels the call launches."""
        compiled = cute.compile(_fill_then_add, self.t, 7)
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
            _fill_then_add(self.t, 7)
            compiled(self.t, 7)
        self.assertEqual(len(hook.events), 2)
        for event in hook.events:
            # kernel_info describes the kernels of the compilation.
            self.assertEqual(len(event.kernel_info), 2)
        # Both kernels ran: fill with 7, then add 7.
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 14))

    def test_hook_error_aborts_the_launch(self):
        compiled = cute.compile(_launch, self.t, 1, 32)
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, _failing_hook):
            with self.assertRaises(DSLRuntimeError) as ctx:
                compiled(self.t, 9)
        self.assertIn("Launch hook failed: _failing_hook", _flat_message(ctx.exception))
        self.assertIsInstance(ctx.exception.__cause__, ValueError)
        # Launch hooks run before the kernel, so it never ran.
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 0))


@unittest.skipUnless(importlib.util.find_spec("tvm_ffi"), "needs apache-tvm-ffi")
class TestTVMFFILaunch(_HookTestCase):
    """With TVM FFI, a compiled function launches through its own ``__call__``
    instead of ``JitCompiledFunction.__call__``."""

    def setUp(self):
        super().setUp()
        self.patch_envar(enable_tvm_ffi=True)
        self.t = from_dlpack(self.data, enable_tvm_ffi=True)

    def test_each_launch_is_reported_once(self):
        compiled = cute.compile(_launch, self.t, 1, 32)
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
            _launch(self.t, 3, 32)
            compiled(self.t, 4)
            compiled(self.t, value=5)
        self.assertEqual(
            [_bind(event) for event in hook.events],
            [{"t": self.t, "value": value} for value in (3, 4, 5)],
        )
        # tvm-ffi converts the arguments of a direct call itself, so there are
        # no packed arguments to report.
        self.assertIsNone(hook.events[1].exe_args)
        torch.cuda.synchronize()
        self.assertTrue(torch.all(self.data == 5))

    def test_function_without_runtime_arguments(self):
        """Such a function compiles to the positional-only TVM FFI class,
        which has a ``__call__`` of its own."""
        # Imported here: the module needs tvm_ffi.
        from cutlass.cutlass_dsl.tvm_ffi_provider import TVMFFIJitCompiledFunction

        compiled = cute.compile(_launch_empty, 32)
        self.assertIsInstance(compiled, TVMFFIJitCompiledFunction)
        hook = _Recorder()
        with self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
            compiled()
        (event,) = hook.events
        self.assertEqual((event.args, event.kwargs), ((), {}))

    def test_uninitialized_function_is_not_reported(self):
        """A function that cannot run (for example one compiled for another
        architecture) fails before the hooks hear of the call."""
        from cutlass.cutlass_dsl.tvm_ffi_provider import (
            TVMFFIJitCompiledFunction,
            TVMFFIJitCompiledFunctionWithKwargs,
        )

        positional = cute.compile(_launch_empty, 32)
        with_kwargs = cute.compile(_launch, self.t, 1, 32)
        self.assertIsInstance(positional, TVMFFIJitCompiledFunction)
        self.assertIsInstance(with_kwargs, TVMFFIJitCompiledFunctionWithKwargs)
        cases = (
            (
                positional,
                (),
                mock.patch.object(
                    TVMFFIJitCompiledFunction, "__chandle__", return_value=0
                ),
            ),
            (
                with_kwargs,
                (self.t, 1),
                mock.patch.object(with_kwargs, "_kwargs_wrapper", None),
            ),
        )
        for compiled, args, uninitialized in cases:
            with self.subTest(cls=type(compiled).__name__):
                hook = _Recorder()
                with uninitialized, self.dsl.hooks(HookEvent.PRE_EXECUTE, hook):
                    with self.assertRaises(DSLRuntimeError):
                        compiled(*args)
                self.assertEqual(hook.events, [])


if __name__ == "__main__":
    unittest.main()
