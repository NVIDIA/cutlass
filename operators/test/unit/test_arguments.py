# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Unit tests for :mod:`cutlass.operators.arguments`."""

import pytest
import torch

import cutlass

import cutlass.operators as ops


@pytest.mark.parametrize(
    "enum_type, value, label",
    [
        (ops.ScaleMode, ops.ScaleMode.Blockwise1x16, "1x16"),
        (ops.ScaleMode, ops.ScaleMode.Blockwise1x32, "1x32"),
        (ops.ScaleSwizzleMode, ops.ScaleSwizzleMode.SwizzleNone, "none"),
        (ops.ScaleSwizzleMode, ops.ScaleSwizzleMode.Swizzle32x4x4, "32x4x4"),
    ],
)
def test_scale_enum_string_round_trip(enum_type, value, label):
    assert str(value) == label
    assert enum_type.from_string(label.upper()) is value


@pytest.mark.parametrize(
    "enum_type, error",
    [
        (ops.ScaleMode, "Invalid scale mode"),
        (ops.ScaleSwizzleMode, "Unsupported scale swizzle"),
    ],
)
def test_scale_enum_from_string_rejects_unknown_value(enum_type, error):
    with pytest.raises(ValueError, match=error):
        enum_type.from_string("invalid")


class TestNumelScale:
    """Tests for :py:meth:`ops.ScaledOperand.numel_scale`."""

    def test_swizzle_none_blockwise1x32(self):
        # Natural ordering: L * outer * ceil_div(K, 32). No padding.
        # 1 * 256 * (1024 / 32) = 256 * 32 = 8192.
        assert ops.ScaledOperand.numel_scale(
            (1, 256, 1024),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.SwizzleNone,
        ) == (1 * 256 * (1024 // 32))

    def test_swizzle_none_blockwise1x16(self):
        # 2 * 64 * ceil_div(48, 16) = 2 * 64 * 3 = 384.
        assert ops.ScaledOperand.numel_scale(
            (2, 64, 48),
            ops.ScaleMode.Blockwise1x16,
            ops.ScaleSwizzleMode.SwizzleNone,
        ) == (2 * 64 * (48 // 16))

    def test_swizzle_none_partial_k_block(self):
        # K=33 with V=32 -> ceil_div(33, 32) = 2 K-blocks.
        assert ops.ScaledOperand.numel_scale(
            (1, 16, 33),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.SwizzleNone,
        ) == 1 * 16 * ((33 + 32 - 1) // 32)

    def test_swizzle32x4x4_aligned(self):
        # Aligned shape: M is a multiple of 128, K-blocks is a multiple of 4.
        # 1 * 256 * (1024 / 32) = 8192. round_up is a no-op here.
        assert ops.ScaledOperand.numel_scale(
            (1, 256, 1024),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ) == 1 * 256 * (1024 // 32)

    def test_swizzle32x4x4_pads_outer(self):
        # M=200 -> round_up(200, 128) = 256. K=1024 -> 32 K-blocks (already
        # a multiple of 4). 1 * 256 * 32 = 8192.
        assert (
            ops.ScaledOperand.numel_scale(
                (1, 200, 1024),
                ops.ScaleMode.Blockwise1x32,
                ops.ScaleSwizzleMode.Swizzle32x4x4,
            )
            == 8192
        )

    def test_swizzle32x4x4_pads_inner(self):
        # K=160 -> ceil_div(160, 32) = 5 K-blocks -> round_up(5, 4) = 8.
        # 1 * 256 * 8 = 2048.
        assert (
            ops.ScaledOperand.numel_scale(
                (1, 256, 160),
                ops.ScaleMode.Blockwise1x32,
                ops.ScaleSwizzleMode.Swizzle32x4x4,
            )
            == 2048
        )

    def test_swizzle32x4x4_pads_both(self):
        # M=200 -> 256, K-blocks = ceil_div(160, 32) = 5 -> 8.
        # L=2 * 256 * 8 = 4096.
        assert (
            ops.ScaledOperand.numel_scale(
                (2, 200, 160),
                ops.ScaleMode.Blockwise1x32,
                ops.ScaleSwizzleMode.Swizzle32x4x4,
            )
            == 4096
        )

    def test_swizzle32x4x4_blockwise1x16(self):
        # NVFP4-style: V=16. K=128 -> 8 K-blocks (a multiple of 4).
        # 1 * 128 * 8 = 1024.
        assert (
            ops.ScaledOperand.numel_scale(
                (1, 128, 128),
                ops.ScaleMode.Blockwise1x16,
                ops.ScaleSwizzleMode.Swizzle32x4x4,
            )
            == 1024
        )

    def test_tuple_mode(self):
        # Bare tuple mode is accepted (and equivalent to the named enum).
        as_enum = ops.ScaledOperand.numel_scale(
            (1, 200, 160),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        )
        as_tuple = ops.ScaledOperand.numel_scale(
            (1, 200, 160),
            (1, 1, 32),
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        )
        assert as_enum == as_tuple

    def test_2d_quantized_shape(self):
        # Rank-2 quantized shape is treated as L=1.
        assert ops.ScaledOperand.numel_scale(
            (256, 1024),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ) == ops.ScaledOperand.numel_scale(
            (1, 256, 1024),
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        )

    def test_invalid_rank_raises(self):
        with pytest.raises(ValueError, match="rank 2 or 3"):
            ops.ScaledOperand.numel_scale(
                (1, 1, 256, 1024),
                ops.ScaleMode.Blockwise1x32,
                ops.ScaleSwizzleMode.Swizzle32x4x4,
            )



class TestDenseTensor:
    def test_is_tensor_like(self):
        # Callers pass DenseTensor and unwrapped tensors interchangeably, so the
        # argument helpers' isinstance(x, TensorLike) gate must accept both.
        assert isinstance(ops.DenseTensor(torch.zeros(2)), ops.TensorLike)

    def test_forwards_dlpack(self):
        # Satisfying the protocol is not enough: a DLPack consumer must reach
        # the wrapped tensor through DenseTensor.
        tensor = torch.zeros(2)
        assert torch.from_dlpack(ops.DenseTensor(tensor)).shape == tensor.shape



class TestGroupedGemmArgumentsCompatibility:
    def test_delegates_to_m_offset_arguments(self, fixture_enable_tvm_ffi):
        A = torch.empty((8, 4), dtype=torch.float16)
        B = torch.empty((2, 4, 16), dtype=torch.float16)
        out = torch.empty((8, 16), dtype=torch.float16)
        offsets = torch.tensor([4, 8], dtype=torch.int32)

        with pytest.warns(
            DeprecationWarning, match="GroupedGemmArguments is deprecated"
        ):
            args = ops.GroupedGemmArguments(A, B, out, torch.float32, offsets)

        assert isinstance(args, ops.GroupedGemmArguments)
        assert isinstance(args, ops.IndexPtrGroupedGemmArguments)
        assert args.offsets_along == "m"


class TestIndexPtrGroupedGemmArguments:
    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape",
        [
            # "m": A is 2D, B is 3D, out is 2D.
            ("m", (8, 4), (2, 4, 16), (8, 16)),
            # "n": A is 3D, B is 2D, out is 2D.
            ("n", (2, 8, 4), (4, 16), (8, 16)),
            # "k": A is 2D, B is 2D, out is 3D (one M x N slab per group,
            # laid out group-first as (group_count, M, N)).
            ("k", (8, 4), (4, 16), (2, 8, 16)),
        ],
    )
    def test_constructs_all_offset_axes(
        self, offsets_along, A_shape, B_shape, out_shape, fixture_enable_tvm_ffi
    ):
        args = ops.IndexPtrGroupedGemmArguments(
            A=torch.empty(A_shape, dtype=torch.float16),
            B=torch.empty(B_shape, dtype=torch.float16),
            out=torch.empty(out_shape, dtype=torch.float16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([4, 8], dtype=torch.int32),
            offsets_along=offsets_along,
        )

        assert isinstance(args.A, ops.DenseTensor)
        assert isinstance(args.offsets, ops.DenseTensor)
        assert args.offsets_along == offsets_along
        assert args.offsets_value_divisibility == 1
        assert not args.accumulate_on_output

    def test_accepts_offsets_value_divisibility(self, fixture_enable_tvm_ffi):
        args = ops.IndexPtrGroupedGemmArguments(
            A=torch.empty((8, 4), dtype=torch.float16),
            B=torch.empty((2, 4, 16), dtype=torch.float16),
            out=torch.empty((8, 16), dtype=torch.float16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([4, 8], dtype=torch.int32),
            offsets_along="m",
            offsets_value_divisibility=4,
        )

        assert args.offsets_value_divisibility == 4

    def test_epilogue_may_change_output_shape(self, fixture_enable_tvm_ffi):
        epilogue = ops.EpilogueArguments(
            "def epi(accum): D = reshape(accum, new_shape=(8, 8)); return D",
            D=torch.empty((8, 8), dtype=torch.float16),
        )

        args = ops.IndexPtrGroupedGemmArguments(
            A=torch.empty((8, 4), dtype=torch.float16),
            B=torch.empty((2, 4, 16), dtype=torch.float16),
            out=torch.empty((8, 8), dtype=torch.float16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([4, 8], dtype=torch.int32),
            offsets_along="m",
            epilogue=epilogue,
        )

        assert args.out.shape == (8, 8)

    def test_accepts_operand_inputs(self, fixture_enable_tvm_ffi):
        A = ops.ScaledOperand(
            quantized=torch.empty((8, 32), dtype=torch.float16),
            scale=torch.empty((8, 1), dtype=torch.float16),
            mode=ops.ScaleMode.Blockwise1x32,
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        args = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=torch.empty((2, 32, 16), dtype=torch.float16),
            out=torch.empty((8, 16), dtype=torch.float16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([4, 8], dtype=torch.int32),
            offsets_along="m",
        )

        assert isinstance(args.A, ops.ScaledOperand)

    @pytest.mark.parametrize("scales", ["a", "b", "ab"])
    def test_accepts_per_group_scale_epilogue(self, scales, fixture_toggle_tvm_ffi):
        operand_a = ops.ScaledOperand(
            quantized=torch.empty((8, 32), dtype=torch.float16),
            scale=torch.empty((8, 1), dtype=torch.float16),
            mode=ops.ScaleMode.Blockwise1x32,
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        operand_b = ops.ScaledOperand(
            quantized=torch.empty((2, 32, 16), dtype=torch.float16),
            scale=torch.empty((2, 16), dtype=torch.float16),
            mode=ops.ScaleMode.Blockwise1x32,
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        epilogue = ops.PerGroupScaleEpilogueArguments(
            global_scale_a=(
                torch.ones(2, dtype=torch.float32) if "a" in scales else None
            ),
            global_scale_b=(
                torch.ones(2, dtype=torch.float32) if "b" in scales else None
            ),
        )

        args = ops.IndexPtrGroupedGemmArguments(
            A=operand_a,
            B=operand_b,
            out=torch.empty((8, 16), dtype=torch.float16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([4, 8], dtype=torch.int32),
            offsets_along="m",
            offsets_value_divisibility=4,
            epilogue=epilogue,
        )

        assert isinstance(args.epilogue, ops.PerGroupScaleEpilogueArguments)
        for name in ("a", "b"):
            scale = getattr(args.epilogue, f"global_scale_{name}")
            if name in scales:
                assert scale.shape == (2,)
                assert scale is not getattr(epilogue, f"global_scale_{name}")
            else:
                assert scale is None
        assert args.offsets_value_divisibility == 4

    @pytest.mark.parametrize("scale_name", ["global_scale_a", "global_scale_b"])
    def test_per_group_scale_epilogue_defaults_other_scale_to_none(
        self, scale_name, fixture_toggle_tvm_ffi
    ):
        epilogue = ops.PerGroupScaleEpilogueArguments(
            **{scale_name: torch.ones(2, dtype=torch.float32)}
        )
        assert getattr(epilogue, scale_name).shape == (2,)
        other_name = (
            "global_scale_b" if scale_name == "global_scale_a" else "global_scale_a"
        )
        assert getattr(epilogue.copy(), other_name) is None

    @pytest.mark.parametrize(
        "kwargs", [{}, {"global_scale_a": None, "global_scale_b": None}]
    )
    def test_per_group_scale_epilogue_requires_a_scale(self, kwargs):
        with pytest.raises(ValueError, match="cannot both be None"):
            ops.PerGroupScaleEpilogueArguments(**kwargs)

    @pytest.mark.parametrize(
        "global_scale_a_shape,global_scale_b_shape,error",
        [
            ((2, 1), (2,), "rank-1"),
            ((2, 1), None, "rank-1"),
            (None, (2, 1), "rank-1"),
            ((2,), (3,), "same shape"),
        ],
    )
    def test_per_group_scale_epilogue_validates_scale_shapes(
        self,
        global_scale_a_shape,
        global_scale_b_shape,
        error,
        fixture_enable_tvm_ffi,
    ):
        with pytest.raises(ValueError, match=error):
            ops.PerGroupScaleEpilogueArguments(
                global_scale_a=(
                    None
                    if global_scale_a_shape is None
                    else torch.ones(global_scale_a_shape, dtype=torch.float32)
                ),
                global_scale_b=(
                    None
                    if global_scale_b_shape is None
                    else torch.ones(global_scale_b_shape, dtype=torch.float32)
                ),
            )

    @pytest.mark.parametrize("scales", ["a", "b", "ab"])
    def test_rejects_mismatched_per_group_scale_shape(
        self, scales, fixture_enable_tvm_ffi
    ):
        operand_a = ops.ScaledOperand(
            quantized=torch.empty((8, 32), dtype=torch.float16),
            scale=torch.empty((8, 1), dtype=torch.float16),
            mode=ops.ScaleMode.Blockwise1x32,
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        operand_b = ops.ScaledOperand(
            quantized=torch.empty((2, 32, 16), dtype=torch.float16),
            scale=torch.empty((2, 16), dtype=torch.float16),
            mode=ops.ScaleMode.Blockwise1x32,
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )

        with pytest.raises(
            ValueError, match=f"global_scale_{scales[0]} must have shape"
        ):
            ops.IndexPtrGroupedGemmArguments(
                A=operand_a,
                B=operand_b,
                out=torch.empty((8, 16), dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along="m",
                epilogue=ops.PerGroupScaleEpilogueArguments(
                    global_scale_a=(
                        torch.ones(3, dtype=torch.float32) if "a" in scales else None
                    ),
                    global_scale_b=(
                        torch.ones(3, dtype=torch.float32) if "b" in scales else None
                    ),
                ),
            )

    @pytest.mark.parametrize("divisibility", [0, -1, 1.5, True, False])
    def test_rejects_invalid_offsets_value_divisibility(
        self, divisibility, fixture_enable_tvm_ffi
    ):
        with pytest.raises(ValueError, match="positive integer"):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty((8, 4), dtype=torch.float16),
                B=torch.empty((2, 4, 16), dtype=torch.float16),
                out=torch.empty((8, 16), dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along="m",
                offsets_value_divisibility=divisibility,
            )

    def test_accumulation_requires_k_offsets(self, fixture_enable_tvm_ffi):
        with pytest.raises(ValueError, match="only supported for offsets_along='k'"):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty((8, 4), dtype=torch.float16),
                B=torch.empty((2, 4, 16), dtype=torch.float16),
                out=torch.empty((8, 16), dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along="m",
                accumulate_on_output=True,
            )

    def test_accepts_blockwise_scaled_operands(self, fixture_enable_tvm_ffi):
        # Blockwise fp8 scales at a granularity with no ScaleMode member, so the
        # mode is given as a bare block-shape tuple.
        A = ops.ScaledOperand(
            quantized=torch.empty((256, 256), dtype=torch.float8_e4m3fn),
            scale=torch.empty((256, 2), dtype=torch.float32),
            mode=(1, 1, 128),
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        B = ops.ScaledOperand(
            quantized=torch.empty((2, 256, 128), dtype=torch.float8_e4m3fn),
            scale=torch.empty((2, 2, 1), dtype=torch.float32),
            mode=(1, 128, 128),
            swizzle=ops.ScaleSwizzleMode.SwizzleNone,
        )
        args = ops.IndexPtrGroupedGemmArguments(
            A=A,
            B=B,
            out=torch.empty((256, 128), dtype=torch.bfloat16),
            accumulator_type=torch.float32,
            offsets=torch.tensor([128, 256], dtype=torch.int32),
            offsets_along="m",
        )

        assert isinstance(args.A, ops.ScaledOperand)
        assert isinstance(args.B, ops.ScaledOperand)
        assert args.B.mode == (1, 128, 128)

    @pytest.mark.parametrize(
        "offsets, offsets_along, error",
        [
            (torch.ones((1, 2), dtype=torch.int32), "m", "rank 1"),
            (torch.ones(2, dtype=torch.float32), "m", "integer dtype"),
            (torch.ones(2, dtype=torch.int32), "batch", "offsets_along"),
        ],
    )
    def test_validates_offsets(self, offsets, offsets_along, error):
        with pytest.raises(ValueError, match=error):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty((8, 4), dtype=torch.float16),
                B=torch.empty((2, 4, 16), dtype=torch.float16),
                out=torch.empty((8, 16), dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=offsets,
                offsets_along=offsets_along,
            )

    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape, bad_operand",
        [
            # "m" requires A 2D, B 3D, out 2D. Only the bad operand is off-rank;
            # the others are valid for the axis so the check flags the intended one.
            ("m", (2, 8, 4), (2, 4, 16), (8, 16), "A"),
            ("m", (8, 4), (2, 4, 16), (2, 8, 16), "out"),
            # "n" requires A 3D, B 2D, out 2D.
            ("n", (2, 8, 4), (2, 4, 16), (8, 16), "B"),
            ("n", (2, 8, 4), (4, 16), (2, 8, 16), "out"),
            # "k" requires A 2D, B 2D, out 3D.
            ("k", (8, 4), (2, 4, 16), (2, 8, 16), "B"),
            ("k", (8, 4), (4, 16), (8, 16), "out"),
        ],
    )
    def test_rejects_invalid_operand_ranks(
        self,
        offsets_along,
        A_shape,
        B_shape,
        out_shape,
        bad_operand,
        fixture_enable_tvm_ffi,
    ):
        # Each offset axis constrains the rank of A, B, and out. Ranks that are
        # otherwise valid (2 or 3) but wrong for the chosen axis are rejected,
        # and the error names the offending operand and the active axis.
        with pytest.raises(
            ValueError,
            match=rf"{bad_operand} must be a tensor of rank .* offsets_along={offsets_along!r}",
        ):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty(A_shape, dtype=torch.float16),
                B=torch.empty(B_shape, dtype=torch.float16),
                out=torch.empty(out_shape, dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along=offsets_along,
            )

    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape, bad_operand",
        [
            # A 3D operand must be group-first (group_count, rows, cols); here the
            # leading dim (3) does not match group_count (2, from two offsets).
            ("m", (8, 4), (3, 4, 16), (8, 16), "B"),
            ("n", (3, 8, 4), (4, 16), (8, 16), "A"),
            ("k", (8, 4), (4, 16), (3, 8, 16), "out"),
        ],
    )
    def test_rejects_mismatched_group_dim(
        self,
        offsets_along,
        A_shape,
        B_shape,
        out_shape,
        bad_operand,
        fixture_enable_tvm_ffi,
    ):
        with pytest.raises(
            ValueError,
            match=rf"{bad_operand} is a 3D operand and must be laid out",
        ):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty(A_shape, dtype=torch.float16),
                B=torch.empty(B_shape, dtype=torch.float16),
                out=torch.empty(out_shape, dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along=offsets_along,
            )

    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape",
        [
            ("m", (8, 4), (0, 4, 16), (8, 16)),
            ("n", (0, 8, 4), (4, 16), (8, 16)),
            ("k", (8, 4), (4, 16), (0, 8, 16)),
        ],
    )
    def test_rejects_empty_group_list(self, offsets_along, A_shape, B_shape, out_shape):
        with pytest.raises(
            ValueError, match="At least one grouped GEMM problem is required"
        ):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty(A_shape, dtype=torch.float16),
                B=torch.empty(B_shape, dtype=torch.float16),
                out=torch.empty(out_shape, dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.empty((0,), dtype=torch.int32),
                offsets_along=offsets_along,
            )

    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape",
        [
            ("m", (8, 4), (2, 5, 16), (8, 16)),
            ("n", (2, 8, 4), (5, 16), (8, 16)),
            ("k", (8, 4), (5, 16), (2, 8, 16)),
        ],
    )
    def test_rejects_mismatched_k(self, offsets_along, A_shape, B_shape, out_shape):
        with pytest.raises(ValueError, match="A and B must have the same K"):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty(A_shape, dtype=torch.float16),
                B=torch.empty(B_shape, dtype=torch.float16),
                out=torch.empty(out_shape, dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along=offsets_along,
            )

    @pytest.mark.parametrize(
        "offsets_along, A_shape, B_shape, out_shape",
        [
            ("m", (8, 4), (2, 4, 16), (7, 16)),
            ("n", (2, 8, 4), (4, 16), (8, 15)),
            ("k", (8, 4), (4, 16), (2, 7, 16)),
        ],
    )
    def test_rejects_mismatched_output_shape(
        self, offsets_along, A_shape, B_shape, out_shape
    ):
        with pytest.raises(ValueError, match="out must have shape"):
            ops.IndexPtrGroupedGemmArguments(
                A=torch.empty(A_shape, dtype=torch.float16),
                B=torch.empty(B_shape, dtype=torch.float16),
                out=torch.empty(out_shape, dtype=torch.float16),
                accumulator_type=torch.float32,
                offsets=torch.tensor([4, 8], dtype=torch.int32),
                offsets_along=offsets_along,
            )
