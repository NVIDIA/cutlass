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

"""Validation, IR, and offline compilation of the L2 policy factory."""

import unittest
from itertools import product
from types import SimpleNamespace
from unittest.mock import patch

import cutlass
import cutlass.cute as cute
from cutlass import Float16, Float32, Int64
from cutlass._mlir import ir
from cutlass._mlir.dialects import func
from cutlass.cute.runtime import make_fake_tensor

Priority = cute.nvgpu.CacheEvictionPriority
make_l2_cache_policy = cute.nvgpu.make_l2_cache_policy


def _build_ir(body, major=8, arg_types=()):
    arch = {
        8: cutlass.Arch.sm_80,
        9: cutlass.Arch.sm_90,
        10: cutlass.Arch.sm_100f,
    }.get(major, SimpleNamespace(major=major))
    dsl = SimpleNamespace(get_arch_enum=lambda: arch)
    with patch("cutlass.cute.nvgpu.common.BaseDSL._get_dsl", return_value=dsl):
        with ir.Context(), ir.Location.unknown():
            module = ir.Module.create()
            with ir.InsertionPoint(module.body):
                fn = func.FuncOp(
                    "test", ir.FunctionType.get([t.mlir_type for t in arg_types], [])
                )
                block = fn.add_entry_block()
                with ir.InsertionPoint(block):
                    body(*block.arguments)
                    func.ReturnOp([])
            module.operation.verify()
            return str(module)


@cute.kernel
def _copy_kernel(
    src: cute.Tensor,
    dst: cute.Tensor,
    settings: cutlass.Constexpr,
    bind: cutlass.Constexpr[bool],
    fraction: Float32,
):
    if cutlass.const_expr(settings[1] is None):
        policy = cute.nvgpu.make_l2_cache_policy(
            settings[0], fraction=fraction, secondary=settings[2]
        )
    else:
        policy = cute.nvgpu.make_l2_cache_policy(
            settings[0], fraction=settings[1], secondary=settings[2]
        )
    reg = cute.make_rmem_tensor(src.shape, Float32)
    load = cute.make_copy_atom(cute.nvgpu.CopyG2ROp(), Float32, num_bits_per_copy=32)
    store = cute.make_copy_atom(cute.nvgpu.CopyR2GOp(), Float32, num_bits_per_copy=32)
    if cutlass.const_expr(bind):
        load = load.with_(cache_policy=policy)
        cute.copy(load, src, reg)
    else:
        cute.copy(load, src, reg, cache_policy=policy)
    cute.copy(store, reg, dst, cache_policy=policy)


@cute.jit
def _copy_entry(
    src: cute.Tensor,
    dst: cute.Tensor,
    settings: cutlass.Constexpr,
    bind: cutlass.Constexpr[bool],
    fraction: Float32,
):
    _copy_kernel(src, dst, settings, bind, fraction).launch(
        grid=(1, 1, 1), block=(1, 1, 1)
    )


class TestMakeL2CachePolicy(unittest.TestCase):
    def _validate_cache_policy(self, text, kind):
        self.assertIn("atom.set_value<cache_policy>", text)
        self.assertEqual(
            text.count("createpolicy.fractional"), 0 if kind == "raw" else 1
        )
        if kind != "raw":
            self.assertIn(
                "createpolicy.fractional.L2::evict_last.L2::evict_first.b64 "
                "{$w0}, {$r0};",
                text,
            )
            self.assertIn("-> i64", text)
        if kind == "static":
            self.assertIn("5.000000e-01 : f32", text)

    def test_invalid_fraction(self):
        for fraction in (0, -0.1, 1.1, float("nan"), float("inf")):
            with self.subTest(fraction=fraction):
                with self.assertRaisesRegex(ValueError, "fraction must be in"):
                    _build_ir(
                        lambda: make_l2_cache_policy(Priority.EVICT_LAST, fraction)
                    )
        for fraction in (True, "0.5", None):
            with self.subTest(fraction=fraction):
                with self.assertRaisesRegex(TypeError, "Float32"):
                    _build_ir(
                        lambda: make_l2_cache_policy(Priority.EVICT_LAST, fraction)
                    )

    def test_invalid_priorities(self):
        with self.assertRaisesRegex(TypeError, "primary"):
            _build_ir(lambda: make_l2_cache_policy("evict_last"))
        with self.assertRaisesRegex(ValueError, "NO_ALLOCATE"):
            _build_ir(lambda: make_l2_cache_policy(Priority.NO_ALLOCATE))
        for secondary in (
            Priority.EVICT_LAST,
            Priority.EVICT_NORMAL,
            Priority.NO_ALLOCATE,
        ):
            with self.subTest(secondary=secondary):
                with self.assertRaisesRegex(ValueError, "secondary"):
                    _build_ir(
                        lambda: make_l2_cache_policy(
                            Priority.EVICT_LAST, secondary=secondary
                        )
                    )

    def test_dialect_enum_alias(self):
        self.assertEqual(
            _build_ir(
                lambda: make_l2_cache_policy(cute.CacheEvictionPriority.EVICT_LAST)
            ),
            _build_ir(lambda: make_l2_cache_policy(Priority.EVICT_LAST)),
        )

    def test_pre_ampere_descriptor_is_rejected(self):
        with self.assertRaisesRegex(cutlass.DSLUserCodeError, "SM80 or newer"):
            _build_ir(lambda: make_l2_cache_policy(Priority.EVICT_LAST), major=7)

    def test_unsupported_copy_atoms_reject_cache_policy(self):
        space = cute.AddressSpace
        cases = (
            (cute.nvgpu.CopyUniversalOp, Float32, 32, 8, space.gmem, None),
            (cute.nvgpu.cpasync.CopyG2SOp, Float32, 128, 8, space.gmem, space.smem),
            (cute.nvgpu.CopyS2ROp, Float32, 32, 8, space.smem, None),
            (cute.nvgpu.CopyR2SOp, Float32, 32, 8, None, space.smem),
            (cute.nvgpu.cpasync.CopyBulkS2GOp, Float32, 128, 9, space.smem, space.gmem),
            (
                cute.nvgpu.cpasync.CopyBulkS2GByteMaskOp,
                Float32,
                128,
                10,
                space.smem,
                space.gmem,
            ),
            (cute.nvgpu.cpasync.CopyBulkS2SOp, Float32, 128, 9, space.smem, space.smem),
            (cute.nvgpu.cpasync.CopyDsmemStoreOp, Float32, 32, 9, None, space.smem),
            (cute.nvgpu.warp.LdMatrix8x8x16bOp, Float16, 32, 8, space.smem, None),
            (cute.nvgpu.warp.StMatrix8x8x16bOp, Float16, 32, 9, None, space.smem),
            (cute.nvgpu.tcgen05.Ld16x64bOp, Float32, 32, 10, space.tmem, None),
        )

        def body(op_type, dtype, bits, src_space, dst_space, route):
            atom = cute.make_copy_atom(op_type(), dtype, num_bits_per_copy=bits)
            policy = make_l2_cache_policy(Priority.EVICT_LAST)
            if route == "bind":
                atom.with_(cache_policy=policy)
            elif route == "unpack":
                atom._unpack(cache_policy=policy)
            else:

                def tensor(address_space):
                    if address_space is None:
                        return cute.make_rmem_tensor((1, 4), dtype)
                    return cute.make_tensor(
                        cute.make_ptr(dtype, 0, address_space, assumed_align=16),
                        cute.make_layout((1, 4)),
                    )

                cute.copy(
                    atom, tensor(src_space), tensor(dst_space), cache_policy=policy
                )

        for case, route in product(cases, ("copy", "bind", "unpack")):
            op_type, dtype, bits, major, src_space, dst_space = case
            with self.subTest(op=op_type.__name__, route=route):
                with self.assertRaisesRegex(
                    ValueError,
                    f"cache_policy is not supported by {op_type.__name__}; .*"
                    "L2 cache eviction policy",
                ):
                    _build_ir(
                        lambda: body(op_type, dtype, bits, src_space, dst_space, route),
                        major=major,
                    )

    def test_supported_copy_requires_int64_descriptor(self):
        def body(op_type, policy, bind):
            atom = cute.make_copy_atom(op_type(), Float32, num_bits_per_copy=32)
            if bind:
                atom.with_(cache_policy=policy)
            else:
                atom._unpack(cache_policy=policy)

        for op_type, policy, bind in product(
            (cute.nvgpu.CopyG2ROp, cute.nvgpu.CopyR2GOp),
            (
                Priority.EVICT_LAST,
                cute.CacheEvictionPriority.EVICT_LAST,
                1,
                Float32(0.5),
            ),
            (False, True),
        ):
            with self.subTest(op=op_type.__name__, policy=policy, bind=bind):
                with self.assertRaisesRegex(
                    TypeError,
                    "Int64 L2 policy descriptor; use cute.nvgpu.make_l2_cache_policy",
                ):
                    _build_ir(lambda: body(op_type, policy, bind))

    def test_unrolled_copy_reuses_descriptor(self):
        def body(fraction, kind, bind):
            src = cute.make_tensor(
                cute.make_ptr(Float32, 0, cute.AddressSpace.gmem, assumed_align=16),
                cute.make_layout((1, 4)),
            )
            dst = cute.make_rmem_tensor((1, 4), Float32)
            atom = cute.make_copy_atom(
                cute.nvgpu.CopyG2ROp(), Float32, num_bits_per_copy=32
            )
            if kind == "raw":
                policy = Int64(0x14F0000000000000)
            else:
                policy = make_l2_cache_policy(
                    Priority.EVICT_LAST,
                    0.5 if kind == "static" else Float32(fraction),
                    Priority.EVICT_FIRST,
                )
            self.assertIsInstance(policy, Int64)
            kwargs = {"cache_policy": policy}
            if bind:
                atom = atom.with_(**kwargs)
                kwargs = {}
            cute.copy(
                atom,
                src,
                dst,
                unroll_factor=1,
                **kwargs,
            )

        for kind, bind in product(
            ("static", "runtime", "raw"),
            (False, True),
        ):
            with self.subTest(kind=kind, bind=bind):
                text = _build_ir(
                    lambda fraction: body(fraction, kind, bind),
                    arg_types=(Float32,),
                )
                self._validate_cache_policy(text, kind)

    def test_bulk_load_accepts_factory_descriptor(self):
        def body(fraction, kind, bind):
            atom = cute.make_copy_atom(
                cute.nvgpu.cpasync.CopyBulkG2SOp(), Float32, num_bits_per_copy=128
            )
            barrier = cute.make_ptr(Int64, 0, cute.AddressSpace.smem, assumed_align=8)
            if kind == "raw":
                policy = Int64(0x14F0000000000000)
            else:
                policy = make_l2_cache_policy(
                    Priority.EVICT_LAST,
                    0.5 if kind == "static" else Float32(fraction),
                    Priority.EVICT_FIRST,
                )
            self.assertIsInstance(policy, Int64)
            kwargs = {"cache_policy": policy}
            if bind:
                atom = atom.with_(mbar_ptr=barrier, **kwargs)
                atom._unpack(mbar_ptr=barrier)
            else:
                atom._unpack(mbar_ptr=barrier, **kwargs)

        for kind, bind in product(
            ("static", "runtime", "raw"),
            (False, True),
        ):
            with self.subTest(kind=kind, bind=bind):
                text = _build_ir(
                    lambda fraction: body(fraction, kind, bind),
                    major=9,
                    arg_types=(Float32,),
                )
                self._validate_cache_policy(text, kind)

    def test_copy_compiles_without_gpu(self):
        src = make_fake_tensor(Float32, (4,), stride=(1,), assumed_align=16)
        dst = make_fake_tensor(Float32, (4,), stride=(1,), assumed_align=16)
        settings = (
            (Priority.EVICT_LAST, 0.5, Priority.EVICT_FIRST),
            (Priority.EVICT_FIRST, 1.0, Priority.EVICT_UNCHANGED),
            (Priority.EVICT_NORMAL, 0.25, Priority.EVICT_UNCHANGED),
            (Priority.EVICT_UNCHANGED, 1.0, Priority.EVICT_UNCHANGED),
            (Priority.EVICT_LAST, None, Priority.EVICT_FIRST),
        )
        for policy_settings in settings:
            for bind in (False, True):
                with self.subTest(settings=policy_settings, bind=bind):
                    cute.compile(
                        _copy_entry,
                        src,
                        dst,
                        policy_settings,
                        bind,
                        Float32(0.5),
                        options="--gpu-arch sm_80",
                    )


if __name__ == "__main__":
    unittest.main()
