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
Unit tests for mutable objects passed as *arguments* to nested @cute.jit
helpers inside DSL dynamic control flow.

Dynamic `if`/`while` bodies are outlined into scf regions, and any object a
callee may mutate in place must be threaded through the region boundary
(yielded and rebound) so uses after the region see the region result rather
than a region-local SSA value. The region analyzer marks assignments and
method-call receivers, and it must mark plain-name call arguments the same
way: a nested helper such as

    @cute.jit
    def disable_accumulate(tiled_mma: cute.TiledMma):
        tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

called inside a dynamic `if` otherwise leaves the mutated TiledMma bound to
a value defined in the child region, and the next use of it fails MLIR
verification with "operand #0 does not dominate this use" (NVIDIA/cutlass
issue #3077 is the SM90 flavor of the same failure).

The extra threading must stay scoped to named variable captures that can
actually observe a mutation:

* immutable Python values (e.g. constexpr ints) and plain Python objects
  carrying no MLIR values must stay read-only, or they would be demoted to
  staged values (breaking e.g. `cutlass.range_constexpr` bounds) or fail
  flattening at the region boundary;
* region *results* (dynamic if-expression branch values) must keep being
  threaded even when they are plain Python literals, or
  `1 if pred else 2` silently constant-folds to its then-value.

The TiledMma mutation tests require a tcgen05-capable (SM 10.x) device
because `TiledMma.set` is the canonical in-place mutator; the read-only
guard tests are architecture-neutral, and the classification tests need no
GPU at all.
"""

import unittest

import cutlass
import cutlass.cute as cute
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.base_dsl.runtime.cuda import get_compute_capability_major_minor
from cutlass.cute.nvgpu import OperandMajorMode, tcgen05
from cutlass.cute.typing import BFloat16, Float32, Int32

try:
    _CC_MAJOR, _ = get_compute_capability_major_minor()
except Exception:  # no GPU / broken driver: only device-less tests can run
    _CC_MAJOR = None

try:
    import torch

    _HAS_TORCH_CUDA = torch.cuda.is_available()
except Exception:
    _HAS_TORCH_CUDA = False

requires_tcgen05 = unittest.skipUnless(
    _CC_MAJOR == 10,
    "TiledMma.set tests require a tcgen05-capable (SM 10.x) device",
)

requires_gpu_runtime = unittest.skipUnless(
    _CC_MAJOR is not None and _HAS_TORCH_CUDA,
    "runtime check requires a CUDA device and torch",
)


@cute.jit
def disable_accumulate(tiled_mma: cute.TiledMma):
    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)


@cute.jit
def enable_accumulate(tiled_mma: cute.TiledMma):
    tiled_mma.set(tcgen05.Field.ACCUMULATE, True)


def make_tiled_mma() -> cute.TiledMma:
    return sm100_utils.make_trivial_tiled_mma(
        BFloat16,
        BFloat16,
        OperandMajorMode.K,
        OperandMajorMode.K,
        Float32,
        tcgen05.CtaGroup.ONE,
        (64, 32),
    )


class TestMutatedCallArgInDynamicIf(unittest.TestCase):
    """A nested @cute.jit helper mutating its argument inside dynamic
    control flow must have the mutated value threaded out of the scf
    region."""

    @requires_tcgen05
    def test_helper_arg_mutated_inside_dynamic_if(self):
        """Positional argument. Used to fail MLIR verification with
        "operand #0 does not dominate this use" because the argument was
        not threaded out of the scf.if region."""

        @cute.kernel
        def kern(tiled_mma: cute.TiledMma, flag: Int32):
            if flag > 0:
                disable_accumulate(tiled_mma)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

        @cute.jit
        def entry(flag: Int32):
            tiled_mma = make_tiled_mma()
            kern(tiled_mma, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    @requires_tcgen05
    def test_helper_kwarg_mutated_inside_dynamic_if(self):
        """Same as above, with the mutated object passed as a keyword
        argument."""

        @cute.kernel
        def kern(tiled_mma: cute.TiledMma, flag: Int32):
            if flag > 0:
                disable_accumulate(tiled_mma=tiled_mma)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

        @cute.jit
        def entry(flag: Int32):
            tiled_mma = make_tiled_mma()
            kern(tiled_mma, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    @requires_tcgen05
    def test_helpers_in_both_branches(self):
        """Nested helpers mutating the argument in both branches of a
        dynamic if/else (the NVIDIA/cutlass#3077 shape)."""

        @cute.kernel
        def kern(tiled_mma: cute.TiledMma, flag: Int32):
            if flag > 0:
                disable_accumulate(tiled_mma)
            else:
                enable_accumulate(tiled_mma)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

        @cute.jit
        def entry(flag: Int32):
            tiled_mma = make_tiled_mma()
            kern(tiled_mma, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    @requires_tcgen05
    def test_helper_arg_mutated_inside_dynamic_while(self):
        """The same failure through the scf.while path: the loop yield is
        the use site that referenced the region-local value."""

        @cute.kernel
        def kern(tiled_mma: cute.TiledMma, flag: Int32):
            i = Int32(0)
            while i < flag:
                disable_accumulate(tiled_mma)
                i = i + Int32(1)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

        @cute.jit
        def entry(flag: Int32):
            tiled_mma = make_tiled_mma()
            kern(tiled_mma, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    @requires_tcgen05
    def test_inline_mutation_control(self):
        """Control: the same mutation written inline (a method call on the
        receiver) has always been threaded and must keep compiling."""

        @cute.kernel
        def kern(tiled_mma: cute.TiledMma, flag: Int32):
            if flag > 0:
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

        @cute.jit
        def entry(flag: Int32):
            tiled_mma = make_tiled_mma()
            kern(tiled_mma, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))


class TestReadOnlyCallArgsStayUnthreaded(unittest.TestCase):
    """Marking call arguments must not thread objects that cannot observe a
    mutation; threading them would demote compile-time constants to staged
    values or fail flattening at the region boundary."""

    def test_constexpr_int_arg_stays_constexpr(self):
        """A Python int passed to a helper inside a dynamic if must remain
        usable as a compile-time constant (e.g. as a range_constexpr
        bound) after the if."""

        @cute.jit
        def helper(x: Int32, n: cutlass.Constexpr):
            y = x + n

        @cute.kernel
        def kern(v: Int32, flag: Int32):
            n = 4
            if flag > 0:
                helper(v, n)
            acc = Int32(0)
            for i in cutlass.range_constexpr(n):
                acc = acc + v

        @cute.jit
        def entry(flag: Int32):
            kern(flag, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    def test_plain_python_object_arg_not_threaded(self):
        """A plain Python object holding no MLIR values, passed to a helper
        inside a dynamic if, must not be threaded through the region (it
        has nothing to rebind and is not flattenable)."""

        class Cfg:
            def __init__(self):
                self.n = 3

        @cute.jit
        def helper(x: Int32, cfg: cutlass.Constexpr):
            y = x + cfg.n

        @cute.kernel
        def kern(v: Int32, flag: Int32):
            cfg = Cfg()
            if flag > 0:
                helper(v, cfg)
            z = v + 1

        @cute.jit
        def entry(flag: Int32):
            kern(flag, flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))

    def test_list_arg_still_compiles(self):
        """A Python list holding staged values, passed to a mutating helper
        inside a dynamic if, keeps compiling (it is flattenable, so it may
        be threaded)."""

        @cute.jit
        def bump(xs):
            xs[0] = xs[0] + Int32(1)

        @cute.kernel
        def kern(flag: Int32):
            xs = [Int32(0)]
            if flag > 0:
                bump(xs)
            y = xs[0] + Int32(1)

        @cute.jit
        def entry(flag: Int32):
            kern(flag).launch(grid=(1, 1, 1), block=(32, 1, 1))

        cute.compile(entry, Int32(1))


class TestRegionResultsAlwaysThreaded(unittest.TestCase):
    """The mutability-based read-only rules apply only to named variable
    captures. Region results must keep being threaded even when they are
    immutable Python values, or dynamic if-expressions of literals would
    silently constant-fold to the then-value."""

    def test_classification_is_scoped_to_named_captures(self):
        # Imported here: REGION_RESULT_NAME does not exist before this fix,
        # and a module-level import would fail the whole file at collection.
        from cutlass.cutlass_dsl.cutlass import (
            REGION_RESULT_NAME,
            is_read_only_object,
        )

        # Named capture: an int cannot be mutated by a callee.
        self.assertTrue(is_read_only_object(4, "n"))
        # Region result (dynamic ternary branch value): must be threaded.
        self.assertFalse(is_read_only_object(4, REGION_RESULT_NAME))
        # No name information (hand-written selector calls): pre-existing
        # behavior, must be threaded.
        self.assertFalse(is_read_only_object(4, None))

    @requires_gpu_runtime
    def test_dynamic_ternary_of_literals_selects_at_runtime(self):
        """`1 if pred else 2` with a dynamic predicate must produce a
        select, not constant-fold to the then-value."""
        from cutlass.cute.runtime import from_dlpack

        @cute.kernel
        def kern(gA: cute.Tensor, flag: Int32):
            y = 1 if flag > 0 else 2
            gA[0] = y

        @cute.jit
        def entry(gA: cute.Tensor, flag: Int32):
            kern(gA, flag).launch(grid=(1, 1, 1), block=(1, 1, 1))

        a = torch.zeros(4, dtype=torch.int32, device="cuda")
        entry(from_dlpack(a), Int32(0))
        torch.cuda.synchronize()
        self.assertEqual(a[0].item(), 2)
        entry(from_dlpack(a), Int32(1))
        torch.cuda.synchronize()
        self.assertEqual(a[0].item(), 1)


if __name__ == "__main__":
    unittest.main()
