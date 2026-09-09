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
Regression tests: DSL decorators must not retain the caller's frame in a
reference cycle.

Binding ``inspect.currentframe()`` to a local variable inside a decorator
(or any function) creates a frame self-cycle: the frame's locals reference
the frame itself, so the frame can only be reclaimed by the cyclic garbage
collector — and through ``f_back`` it keeps the entire caller stack,
including every frame's locals, alive until a collection runs.

Applications that disable automatic gc (e.g. CUDA-graph training loops)
then leak whatever the calling stack held at decoration time. When
kernel-bearing modules are imported lazily inside a model's forward pass,
that includes live activation tensors (multi-GiB per decoration site
observed in large training jobs).

These tests decorate/construct with a weakref-tracked sentinel held as a
local in the calling frame and assert the sentinel dies by refcounting
alone, with gc disabled. No GPU is required.
"""

import gc
import unittest
import weakref

import cutlass.cute as cute
from cutlass.base_dsl.common import DSLOperationBuildError


class _Sentinel:
    pass


class DecoratorFrameRefcycleTest(unittest.TestCase):
    def setUp(self):
        self._gc_was_enabled = gc.isenabled()
        gc.disable()

    def tearDown(self):
        if self._gc_was_enabled:
            gc.enable()
        gc.collect()

    def _assert_dies_by_refcount(self, probe, what):
        ref = probe()
        self.assertIsNone(
            ref(),
            f"{what} retained the calling frame in a reference cycle: a "
            "sentinel local of the caller is still alive after the caller "
            "returned (with gc disabled, only refcounting may free it)",
        )

    def test_jit_decoration_does_not_pin_caller_frame(self):
        def probe():
            sentinel = _Sentinel()
            ref = weakref.ref(sentinel)

            @cute.jit
            def _host():
                pass

            return ref

        self._assert_dies_by_refcount(probe, "@cute.jit decoration")

    def test_kernel_decoration_does_not_pin_caller_frame(self):
        def probe():
            sentinel = _Sentinel()
            ref = weakref.ref(sentinel)

            @cute.kernel
            def _knl():
                pass

            return ref

        self._assert_dies_by_refcount(probe, "@cute.kernel decoration")

    def test_experimental_kernel_decoration_does_not_pin_caller_frame(self):
        try:
            import cutlass.cute.experimental as experimental
        except Exception:
            self.skipTest("cute.experimental unavailable on this toolkit")

        def probe():
            sentinel = _Sentinel()
            ref = weakref.ref(sentinel)

            @experimental.kernel
            def _knl():
                pass

            return ref

        self._assert_dies_by_refcount(probe, "@cute.experimental.kernel decoration")

    def test_operation_build_error_does_not_pin_caller_frame(self):
        def probe():
            sentinel = _Sentinel()
            ref = weakref.ref(sentinel)
            # frameInfo=None triggers the automatic caller-frame capture.
            DSLOperationBuildError("regression probe", frameInfo=None)
            return ref

        self._assert_dies_by_refcount(probe, "DSLOperationBuildError construction")


if __name__ == "__main__":
    unittest.main()
