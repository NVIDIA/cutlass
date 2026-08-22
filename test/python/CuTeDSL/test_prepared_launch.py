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
Unit tests for the prepared-launch API
(`JitCompiledFunction.prepare` / `PreparedLaunch.launch`).

A prepared launch binds a compiled function's runtime arguments to stable
storage once and replays the launch with in-place updates only, so it must be
observably identical to the normal call path. The tests here prove:

* bitwise parity with the normal call path on a real device kernel;
* argument mutation between launches (pointers, scalars of several widths,
  stream) takes effect, including raw-integer fast-path values and framework
  stream objects;
* launches never re-enter ExecutionArgs marshalling and reuse the packed
  argument array in place;
* the handle owns stable argument storage (long read-modify-write accumulate
  under GC/allocator churn);
* prepare-time eligibility errors for argument kinds that cannot be re-bound
  in place, and launch-time errors for arg-count/value-type/lifecycle misuse;
* per-thread instances launch concurrently without sharing state, and a
  single instance can be handed off between threads sequentially;
* explicitly device-bound executors (``to(device).prepare``) work;
* behavior under CUDA graph capture (captures cleanly; standard
  frozen-at-capture argument semantics; no corruption of later launches);
* a micro-benchmark of steady-state host launch cost, prepared vs direct.
"""

import ctypes
import gc
import threading
import time
import unittest

import cuda.bindings.driver as cuda_driver

import cutlass
import cutlass.cute as cute
from cutlass import DSLUserCodeError, PreparedLaunchError
from cutlass.cute.runtime import from_dlpack, make_ptr

try:
    import torch

    _HAS_TORCH_CUDA = torch.cuda.is_available()
except ImportError:
    _HAS_TORCH_CUDA = False

requires_gpu = unittest.skipUnless(
    _HAS_TORCH_CUDA, "prepared-launch tests need torch with a CUDA device"
)


@cute.kernel
def _scale_kernel(
    gOut: cute.Tensor, gIn: cute.Tensor, alpha: cutlass.Float32, n: cutlass.Int32
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    bdim, _, _ = cute.arch.block_dim()
    i = bidx * bdim + tidx
    if i < n:
        gOut[i] = gIn[i] * alpha


@cute.jit
def _scale(
    out_ptr: cute.Pointer,
    in_ptr: cute.Pointer,
    alpha: cutlass.Float32,
    n: cutlass.Int32,
    stream: cuda_driver.CUstream,
):
    layout = cute.make_layout(n)
    gOut = cute.make_tensor(out_ptr, layout)
    gIn = cute.make_tensor(in_ptr, layout)
    _scale_kernel(gOut, gIn, alpha, n).launch(
        grid=((n + 255) // 256, 1, 1), block=(256, 1, 1), stream=stream
    )


@cute.kernel
def _mixed_scalars_kernel(
    gOut: cute.Tensor,
    gIn: cute.Tensor,
    alpha: cutlass.Float64,
    bias: cutlass.Int64,
    flag: cutlass.Boolean,
    n: cutlass.Int32,
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    bdim, _, _ = cute.arch.block_dim()
    i = bidx * bdim + tidx
    if i < n:
        scaled = gIn[i].to(cutlass.Float64) * alpha + bias.to(cutlass.Float64)
        if flag:
            gOut[i] = scaled.to(cutlass.Float32)
        else:
            gOut[i] = -scaled.to(cutlass.Float32)


@cute.jit
def _mixed_scalars(
    out_ptr: cute.Pointer,
    in_ptr: cute.Pointer,
    alpha: cutlass.Float64,
    bias: cutlass.Int64,
    flag: cutlass.Boolean,
    n: cutlass.Int32,
    stream: cuda_driver.CUstream,
):
    layout = cute.make_layout(n)
    gOut = cute.make_tensor(out_ptr, layout)
    gIn = cute.make_tensor(in_ptr, layout)
    _mixed_scalars_kernel(gOut, gIn, alpha, bias, flag, n).launch(
        grid=((n + 255) // 256, 1, 1), block=(256, 1, 1), stream=stream
    )


@cute.kernel
def _accumulate_kernel(gAcc: cute.Tensor, gIn: cute.Tensor, n: cutlass.Int32):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    bdim, _, _ = cute.arch.block_dim()
    i = bidx * bdim + tidx
    if i < n:
        gAcc[i] = gAcc[i] + gIn[i]


@cute.jit
def _accumulate(
    acc_ptr: cute.Pointer,
    in_ptr: cute.Pointer,
    n: cutlass.Int32,
    stream: cuda_driver.CUstream,
):
    layout = cute.make_layout(n)
    gAcc = cute.make_tensor(acc_ptr, layout)
    gIn = cute.make_tensor(in_ptr, layout)
    _accumulate_kernel(gAcc, gIn, n).launch(
        grid=((n + 255) // 256, 1, 1), block=(256, 1, 1), stream=stream
    )


@cute.jit
def _scale_default(
    out_ptr: cute.Pointer,
    in_ptr: cute.Pointer,
    n: cutlass.Int32,
    stream: cuda_driver.CUstream,
    alpha: cutlass.Float32 = 2.5,
):
    layout = cute.make_layout(n)
    gOut = cute.make_tensor(out_ptr, layout)
    gIn = cute.make_tensor(in_ptr, layout)
    _scale_kernel(gOut, gIn, alpha, n).launch(
        grid=((n + 255) // 256, 1, 1), block=(256, 1, 1), stream=stream
    )


@cute.jit
def _tensor_signature(gA: cute.Tensor, alpha: cutlass.Float32):
    pass


@cute.jit
def _f16_scalar_signature(alpha: cutlass.Float16):
    pass


@cute.jit
def _sequence_signature(xs: list):
    pass


def _f32_ptr(tensor):
    return make_ptr(
        cutlass.Float32,
        tensor.data_ptr(),
        cute.AddressSpace.gmem,
        assumed_align=16,
    )


def _current_stream():
    return cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)


class _CompiledCache:
    """Compile each test function once per test session."""

    _cache: dict = {}

    @classmethod
    def scale(cls):
        if "scale" not in cls._cache:
            x = torch.zeros(16, device="cuda", dtype=torch.float32)
            cls._cache["scale"] = cute.compile(
                _scale, _f32_ptr(x), _f32_ptr(x), 1.0, 16, _current_stream()
            )
        return cls._cache["scale"]

    @classmethod
    def mixed(cls):
        if "mixed" not in cls._cache:
            x = torch.zeros(16, device="cuda", dtype=torch.float32)
            cls._cache["mixed"] = cute.compile(
                _mixed_scalars,
                _f32_ptr(x),
                _f32_ptr(x),
                1.0,
                cutlass.Int64(0),
                cutlass.Boolean(True),
                16,
                _current_stream(),
            )
        return cls._cache["mixed"]


@requires_gpu
class TestPreparedLaunchParity(unittest.TestCase):
    def test_bitwise_parity_with_direct_call(self):
        """The prepared path must produce bit-identical outputs to the
        normal call path for the same kernel and inputs; prepare() must
        also work before the compiled function was ever called directly."""
        compiled = _CompiledCache.scale()
        n = 4096
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y_direct = torch.full((n,), float("nan"), device="cuda")
        y_prepared = torch.full((n,), float("nan"), device="cuda")
        stream = _current_stream()

        prepared = compiled.prepare(_f32_ptr(y_prepared), _f32_ptr(x), 1.7, n, stream)
        result = prepared.launch(_f32_ptr(y_prepared), _f32_ptr(x), 1.7, n, stream)
        compiled(_f32_ptr(y_direct), _f32_ptr(x), 1.7, n, stream)
        torch.cuda.synchronize()

        self.assertEqual(result, 0)
        self.assertTrue(
            torch.equal(y_direct.view(torch.int32), y_prepared.view(torch.int32)),
            "prepared launch output differs bitwise from the direct call",
        )

    def test_argument_mutation_between_launches(self):
        """New pointers, scalar values, and stream between launches must all
        take effect; raw integer addresses/handles are accepted."""
        compiled = _CompiledCache.scale()
        stream = _current_stream()
        n1, n2 = 4096, 2048
        x1 = torch.randn(n1, device="cuda", dtype=torch.float32)
        x2 = torch.randn(n2, device="cuda", dtype=torch.float32)
        y1 = torch.empty_like(x1)
        y2 = torch.empty_like(x2)

        prepared = compiled.prepare(_f32_ptr(y1), _f32_ptr(x1), 2.0, n1, stream)
        prepared.launch(_f32_ptr(y1), _f32_ptr(x1), 2.0, n1, stream)

        # Everything changes: buffers, scalar values, and the value forms
        # (raw addresses, raw stream handle, Numeric instances).
        prepared.launch(
            y2.data_ptr(),
            x2.data_ptr(),
            cutlass.Float32(-0.25),
            cutlass.Int32(n2),
            int(stream),
        )
        torch.cuda.synchronize()

        self.assertTrue(torch.equal(y1, x1 * 2.0))
        self.assertTrue(torch.equal(y2, x2 * -0.25))

        # Keyword arguments are rectified like a normal call.
        prepared.launch(_f32_ptr(y2), _f32_ptr(x2), 3.0, n2, stream=stream)
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y2, x2 * 3.0))

    def test_scalar_widths_parity(self):
        """Float64/Int64/Boolean scalar slots update correctly and match the
        direct call bitwise, including flipping the Boolean between launches."""
        compiled = _CompiledCache.mixed()
        stream = _current_stream()
        n = 1024
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y_direct = torch.empty_like(x)
        y_prepared = torch.empty_like(x)

        prepared = compiled.prepare(
            _f32_ptr(y_prepared),
            _f32_ptr(x),
            1.0,
            cutlass.Int64(0),
            cutlass.Boolean(True),
            n,
            stream,
        )
        for alpha, bias, flag in [(0.5, 7, True), (-1.25, -3, False), (2.0, 0, True)]:
            compiled(
                _f32_ptr(y_direct),
                _f32_ptr(x),
                alpha,
                cutlass.Int64(bias),
                cutlass.Boolean(flag),
                n,
                stream,
            )
            prepared.launch(
                _f32_ptr(y_prepared),
                _f32_ptr(x),
                alpha,
                cutlass.Int64(bias),
                cutlass.Boolean(flag),
                n,
                stream,
            )
            torch.cuda.synchronize()
            self.assertTrue(
                torch.equal(y_direct.view(torch.int32), y_prepared.view(torch.int32)),
                f"bitwise mismatch for alpha={alpha}, bias={bias}, flag={flag}",
            )

    def test_framework_stream_at_launch(self):
        """launch() accepts a framework stream object exposing an integer
        ``cuda_stream`` attribute (e.g. torch.cuda.Stream) for a stream slot;
        the launch must actually run on that stream."""
        compiled = _CompiledCache.scale()
        n = 1024
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.zeros_like(x)
        prepared = compiled.prepare(_f32_ptr(y), _f32_ptr(x), 4.0, n, _current_stream())

        side_stream = torch.cuda.Stream()
        side_stream.wait_stream(torch.cuda.current_stream())
        prepared.launch(_f32_ptr(y), _f32_ptr(x), 4.0, n, side_stream)
        side_stream.synchronize()
        self.assertTrue(torch.equal(y, x * 4.0))

    def test_defaulted_argument_at_prepare_and_launch(self):
        """Omitted defaulted parameters bind through the signature at both
        prepare and launch, exactly like a direct call."""
        n = 512
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.zeros_like(x)
        stream = _current_stream()
        compiled = cute.compile(
            _scale_default, _f32_ptr(y), _f32_ptr(x), n, stream, 2.5
        )

        prepared = compiled.prepare(_f32_ptr(y), _f32_ptr(x), n, stream)
        prepared.launch(_f32_ptr(y), _f32_ptr(x), n, stream)
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y, x * 2.5))

        prepared.launch(y.data_ptr(), x.data_ptr(), n, int(stream), -1.0)
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y, x * -1.0))

    def test_launch_does_not_regenerate_execution_args(self):
        """The whole point of the fast path: positional launches must not
        re-enter ExecutionArgs marshalling, and the packed argument array
        must be reused in place rather than rebuilt."""
        compiled = _CompiledCache.scale()
        n = 256
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.empty_like(x)
        stream = _current_stream()
        prepared = compiled.prepare(_f32_ptr(y), _f32_ptr(x), 2.0, n, stream)
        packed_address = ctypes.addressof(prepared._packed_args)

        execution_args = compiled.jit_module.execution_args

        def fail_if_called(*args, **kwargs):
            raise AssertionError("prepared launch regenerated ExecutionArgs")

        original = execution_args.generate_execution_args
        execution_args.generate_execution_args = fail_if_called
        try:
            prepared.launch(_f32_ptr(y), _f32_ptr(x), 2.0, n, stream)
            prepared.launch(y.data_ptr(), x.data_ptr(), 3.0, n, int(stream))
        finally:
            execution_args.generate_execution_args = original
        torch.cuda.synchronize()

        self.assertEqual(ctypes.addressof(prepared._packed_args), packed_address)
        self.assertTrue(torch.equal(y, x * 3.0))

    def test_repeated_launch_storage_stability(self):
        """The handle must own stable argument storage: a long read-modify-
        write accumulate over many launches, with GC pressure and allocator
        churn in between, must not corrupt any argument slot. (The slow
        path's scalar ctypes storage is ephemeral; a prepared launch that
        merely snapshotted those addresses would dangle here.)"""
        n = 1024
        stream = _current_stream()
        ones = torch.ones(n, device="cuda", dtype=torch.float32)
        acc = torch.zeros(n, device="cuda", dtype=torch.float32)
        compiled = cute.compile(_accumulate, _f32_ptr(acc), _f32_ptr(ones), n, stream)
        prepared = compiled.prepare(_f32_ptr(acc), _f32_ptr(ones), n, stream)

        iters = 1000
        for i in range(iters):
            prepared.launch(acc.data_ptr(), ones.data_ptr(), n, int(stream))
            if i % 100 == 99:
                gc.collect()
                _churn = [ctypes.c_double(float(j)) for j in range(2000)]
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(acc, torch.full_like(acc, float(iters))))


@requires_gpu
class TestPreparedLaunchEligibility(unittest.TestCase):
    def test_dlpack_tensor_rejected(self):
        a = torch.zeros(32, device="cuda", dtype=torch.float32)
        compiled = cute.compile(_tensor_signature, from_dlpack(a), 1.0)
        with self.assertRaises(PreparedLaunchError) as raised:
            compiled.prepare(from_dlpack(a), 1.0)
        self.assertIn("gA", str(raised.exception))

    def test_non_ctypes_numeric_annotation_rejected(self):
        compiled = cute.compile(_f16_scalar_signature, 1.0)
        with self.assertRaises(PreparedLaunchError) as raised:
            compiled.prepare(1.0)
        self.assertIn("Float16", str(raised.exception))

    def test_sequence_argument_rejected(self):
        compiled = cute.compile(_sequence_signature, [1, 2])
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare([1, 2])

    def test_extra_tail_arguments_rejected(self):
        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(_f32_ptr(x), _f32_ptr(x), 1.0, 16, _current_stream(), 123)

    def test_multi_slot_custom_argument_rejected(self):
        """A user object marshalling to multiple ABI slots (custom
        ``__c_pointers__``) is not re-bindable in place and must be rejected
        at prepare time."""

        class MultiSlotStruct:
            def __c_pointers__(self):
                return [ctypes.c_void_p(), ctypes.c_void_p()]

        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(MultiSlotStruct(), _f32_ptr(x), 1.0, 16, _current_stream())

    def test_framework_stream_rejected_at_prepare(self):
        """prepare() marshals through the normal path, so a stream slot must
        be prepared with a CUstream; framework stream objects are accepted at
        launch time only."""
        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(
                _f32_ptr(x), _f32_ptr(x), 1.0, 16, torch.cuda.current_stream()
            )

    def test_missing_argument_diagnosed(self):
        """prepare() with too few arguments raises the same missing-argument
        diagnostic a direct call would (rectification is shared)."""
        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        with self.assertRaises(DSLUserCodeError):
            compiled.prepare(_f32_ptr(x), _f32_ptr(x), 1.0)

    def test_wrong_kind_value_rejected_at_prepare(self):
        """Classification is annotation-driven: a scalar for a declared
        pointer slot, or an integer for a declared stream slot, is rejected
        at prepare time instead of being mis-marshalled."""
        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        stream = _current_stream()
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(1.5, _f32_ptr(x), 1.0, 16, stream)
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(_f32_ptr(x), _f32_ptr(x), 1.0, 16, 7)

    def test_pointer_contract_lookalike_rejected(self):
        """An object that merely looks like a runtime pointer (c_void_p
        ``_desc`` plus ``__c_pointers__``) but marshals storage other than
        its ``_desc`` must be rejected at prepare, not silently re-bound to
        the wrong bytes on later launches."""

        class DescLookalike:
            def __init__(self):
                self._cell = ctypes.c_int32(7)
                self._desc = ctypes.c_void_p(0xDEAD0000)

            def __c_pointers__(self):
                return [ctypes.addressof(self._cell)]

        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        with self.assertRaises(PreparedLaunchError):
            compiled.prepare(DescLookalike(), _f32_ptr(x), 1.0, 16, _current_stream())

    def test_non_jit_executor_rejected(self):
        """TVM-FFI compiled functions override to() to return the compiled
        function itself (their calls dispatch through a different entry
        point); prepare() must reject such executors cleanly instead of
        recursing. Simulated by forcing a non-JitExecutor default executor."""
        compiled = _CompiledCache.scale()
        x = torch.zeros(16, device="cuda", dtype=torch.float32)
        args = (_f32_ptr(x), _f32_ptr(x), 1.0, 16, _current_stream())
        original = compiled._default_executor
        compiled._default_executor = object()
        try:
            with self.assertRaises(PreparedLaunchError):
                compiled.prepare(*args)
        finally:
            compiled._default_executor = original

    def test_direct_call_still_works_for_ineligible_args(self):
        """prepare() rejecting an argument mix must leave the normal call
        path untouched."""
        a = torch.zeros(32, device="cuda", dtype=torch.float32)
        compiled = cute.compile(_tensor_signature, from_dlpack(a), 1.0)
        compiled(from_dlpack(a), 1.0)  # no raise


@requires_gpu
class TestPreparedLaunchMisuse(unittest.TestCase):
    def _prepared(self):
        compiled = _CompiledCache.scale()
        x = torch.zeros(64, device="cuda", dtype=torch.float32)
        y = torch.empty_like(x)
        stream = _current_stream()
        args = (_f32_ptr(y), _f32_ptr(x), 1.0, 64, stream)
        return compiled.prepare(*args), args, (x, y)

    def test_launch_argument_count_mismatch(self):
        """Too few arguments without defaults raise the shared missing-
        argument diagnostic; extra arguments raise the shared too-many
        diagnostic — the same binding contract as a direct call."""
        prepared, args, _keep = self._prepared()
        with self.assertRaises(DSLUserCodeError):
            prepared.launch(*args[:-1])
        with self.assertRaises(DSLUserCodeError):
            prepared.launch(*args, 5)

    def test_launch_bad_stream_value(self):
        """Stream slots accept streams, framework streams, and raw integer
        handles only — not floats, bools, strings, or arbitrary objects."""
        prepared, args, _keep = self._prepared()

        class WithInt:
            def __int__(self):
                return 0

        for bad_stream in (1.75, True, "0", WithInt()):
            with self.assertRaises(PreparedLaunchError, msg=repr(bad_stream)):
                prepared.launch(*args[:-1], bad_stream)

    def test_launch_bad_boolean_value(self):
        """Boolean slots take bool/int values; truthiness of arbitrary
        objects is not silently coerced."""
        compiled = _CompiledCache.mixed()
        stream = _current_stream()
        n = 64
        x = torch.zeros(n, device="cuda", dtype=torch.float32)
        y = torch.empty_like(x)
        prepared = compiled.prepare(
            _f32_ptr(y),
            _f32_ptr(x),
            1.0,
            cutlass.Int64(0),
            cutlass.Boolean(True),
            n,
            stream,
        )
        for bad_flag in ("false", None, [], object()):
            with self.assertRaises(PreparedLaunchError, msg=repr(bad_flag)):
                prepared.launch(
                    _f32_ptr(y),
                    _f32_ptr(x),
                    1.0,
                    cutlass.Int64(0),
                    bad_flag,
                    n,
                    stream,
                )

    def test_launch_bad_value_type(self):
        prepared, args, _keep = self._prepared()
        bad = (args[0], "not a pointer", *args[2:])
        with self.assertRaises(PreparedLaunchError) as raised:
            prepared.launch(*bad)
        self.assertIn("in_ptr", str(raised.exception))

    def test_launch_after_module_unload(self):
        n = 64
        x = torch.zeros(n, device="cuda", dtype=torch.float32)
        y = torch.empty_like(x)
        stream = _current_stream()
        compiled = cute.compile(_scale, _f32_ptr(y), _f32_ptr(x), 1.0, n, stream)
        prepared = compiled.prepare(_f32_ptr(y), _f32_ptr(x), 1.0, n, stream)
        prepared.launch(_f32_ptr(y), _f32_ptr(x), 1.0, n, stream)
        torch.cuda.synchronize()
        compiled.jit_module.unload()
        with self.assertRaises(PreparedLaunchError):
            prepared.launch(_f32_ptr(y), _f32_ptr(x), 1.0, n, stream)


@requires_gpu
class TestPreparedLaunchThreads(unittest.TestCase):
    def test_one_instance_per_thread(self):
        """The documented threading model: each thread prepares its own
        instance; concurrent launches must not interfere (instances share no
        mutable state)."""
        compiled = _CompiledCache.scale()
        n, iters = 4096, 50
        errors = []

        def worker(alpha):
            try:
                stream_obj = torch.cuda.Stream()
                with torch.cuda.stream(stream_obj):
                    x = torch.randn(n, device="cuda", dtype=torch.float32)
                    y = torch.empty_like(x)
                    stream = cuda_driver.CUstream(stream_obj.cuda_stream)
                    prepared = compiled.prepare(
                        _f32_ptr(y), _f32_ptr(x), alpha, n, stream
                    )
                    for _ in range(iters):
                        y.fill_(0.0)
                        prepared.launch(_f32_ptr(y), _f32_ptr(x), alpha, n, stream)
                    stream_obj.synchronize()
                    if not torch.equal(y, x * alpha):
                        errors.append(f"wrong result for alpha={alpha}")
            except Exception as e:  # pragma: no cover - failure reporting
                errors.append(f"alpha={alpha}: {e!r}")

        threads = [
            threading.Thread(target=worker, args=(alpha,)) for alpha in (2.0, -3.0)
        ]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()
        self.assertEqual(errors, [])

    def test_cross_thread_handoff(self):
        """Instances are not thread-safe but are not thread-bound either:
        preparing on one thread and launching from another (sequential
        handoff, e.g. an init thread and a worker loop) must work."""
        compiled = _CompiledCache.scale()
        n = 1024
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.zeros_like(x)
        stream = _current_stream()
        prepared = compiled.prepare(_f32_ptr(y), _f32_ptr(x), 5.0, n, stream)
        errors = []

        def worker():
            try:
                prepared.launch(_f32_ptr(y), _f32_ptr(x), 5.0, n, stream)
            except Exception as e:  # pragma: no cover - failure reporting
                errors.append(repr(e))

        thread = threading.Thread(target=worker)
        thread.start()
        thread.join()
        torch.cuda.synchronize()
        self.assertEqual(errors, [])
        self.assertTrue(torch.equal(y, x * 5.0))


@requires_gpu
class TestPreparedLaunchDeviceBinding(unittest.TestCase):
    def test_explicit_device_executor_prepare(self):
        """prepare() mirrors the to()/__call__ split: an explicitly
        device-bound executor prepares and launches correctly."""
        compiled = _CompiledCache.scale()
        n = 512
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.zeros_like(x)
        stream = _current_stream()
        prepared = compiled.to(0).prepare(_f32_ptr(y), _f32_ptr(x), 3.0, n, stream)
        result = prepared.launch(_f32_ptr(y), _f32_ptr(x), 3.0, n, stream)
        torch.cuda.synchronize()
        self.assertEqual(result, 0)
        self.assertTrue(torch.equal(y, x * 3.0))


@requires_gpu
class TestPreparedLaunchCudaGraph(unittest.TestCase):
    def test_capture_and_replay(self):
        """A prepared launch is capturable into a CUDA graph through a
        capturing stream, with standard capture semantics: the argument bytes
        are frozen into the graph at capture time, later launch() argument
        updates affect neither the graph nor vice versa."""
        compiled = _CompiledCache.scale()
        n = 2048
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y_graph = torch.zeros_like(x)
        y_other = torch.zeros_like(x)
        stream = _current_stream()
        prepared = compiled.prepare(_f32_ptr(y_graph), _f32_ptr(x), 2.0, n, stream)

        # Warm up outside capture (loads the module, primes caches).
        prepared.launch(_f32_ptr(y_graph), _f32_ptr(x), 2.0, n, stream)
        torch.cuda.synchronize()

        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            capture_stream = torch.cuda.current_stream().cuda_stream
            result = prepared.launch(
                _f32_ptr(y_graph), _f32_ptr(x), 2.0, n, capture_stream
            )
        # Capture queues the launch into the graph; it must still report
        # success and must not have executed yet.
        self.assertEqual(result, 0)

        y_graph.zero_()
        graph.replay()
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y_graph, x * 2.0))

        # Ordinary launches after capture keep working and do not disturb
        # the captured graph (frozen-at-capture semantics).
        prepared.launch(_f32_ptr(y_other), _f32_ptr(x), -1.0, n, stream)
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y_other, x * -1.0))

        y_graph.zero_()
        y_other.zero_()
        graph.replay()
        torch.cuda.synchronize()
        self.assertTrue(torch.equal(y_graph, x * 2.0))
        self.assertTrue(torch.equal(y_other, torch.zeros_like(x)))


@requires_gpu
class TestPreparedLaunchBenchmark(unittest.TestCase):
    def test_benchmark_prepared_vs_direct(self):
        """Micro-benchmark of steady-state host launch cost. Asserts only the
        direction (prepared must not be slower than the direct call); the
        printed numbers are the evidence."""
        compiled = _CompiledCache.scale()
        n, iters, warmup = 4096, 1000, 100
        x = torch.randn(n, device="cuda", dtype=torch.float32)
        y = torch.empty_like(x)
        stream = _current_stream()
        args = (_f32_ptr(y), _f32_ptr(x), 2.0, n, stream)
        prepared = compiled.prepare(*args)
        y_addr, x_addr, handle = y.data_ptr(), x.data_ptr(), int(stream)

        def timed(fn):
            for _ in range(warmup):
                fn()
            torch.cuda.synchronize()
            start_event = torch.cuda.Event(enable_timing=True)
            end_event = torch.cuda.Event(enable_timing=True)
            start_event.record()
            start = time.perf_counter()
            for _ in range(iters):
                fn()
            wall_us = (time.perf_counter() - start) / iters * 1e6
            end_event.record()
            torch.cuda.synchronize()
            event_us = start_event.elapsed_time(end_event) / iters * 1e3
            return wall_us, event_us

        direct_wall, direct_event = timed(lambda: compiled(*args))
        prepared_wall, prepared_event = timed(
            lambda: prepared.launch(y_addr, x_addr, 2.0, n, handle)
        )

        print(
            f"\n[prepared-launch bench] direct call:     "
            f"{direct_wall:7.2f} us/call host wall, {direct_event:7.2f} us/call cuda-event\n"
            f"[prepared-launch bench] prepared launch: "
            f"{prepared_wall:7.2f} us/call host wall, {prepared_event:7.2f} us/call cuda-event"
        )
        self.assertLess(prepared_wall, direct_wall)


if __name__ == "__main__":
    unittest.main()
