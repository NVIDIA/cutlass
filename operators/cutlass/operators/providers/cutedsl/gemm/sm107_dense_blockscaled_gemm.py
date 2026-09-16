# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

from __future__ import annotations

import functools
import itertools
from typing import TYPE_CHECKING, Literal

import cutlass
from cutlass import testing

from cutlass.kernels.rubin.gemm.dense_blockscaled_gemm_universal import (
    Sm107BlockScaledGemmUniversal,
    Sm107BlockScaledPersistentDenseGemmKernel,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    GemmArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    GemmOperandsMetadata,
    OperatorMetadata,
    ScaledOperandConstraints,
)
from cutlass.operators.metadata.design.sm107 import Sm107DesignMetadata
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from ...cutedsl import CuTeDSLProvider
from ...cutedsl.integration_utils.builders import (
    gemm_major_modes,
    make_ptr,
)
from ...cutedsl.integration_utils.mma import (
    get_max_active_clusters,
)
from ...cutedsl.operator import CuteDslOperator

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arguments import EpilogueArguments
    from cutlass.operators.artifact import CompiledArtifact


@CuTeDSLProvider.register
class Sm107DenseBlockScaledGemmOperator(CuteDslOperator):
    """Block scaled dense GEMM operator for SM107."""

    supported_args_type = GemmArguments
    designed_for_min_cc = 107

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        operands: GemmOperandsMetadata = metadata.operands
        design: Sm107DesignMetadata = metadata.design
        _, mma_tiler, mma_inst_shape = _mma_shapes(
            operands.A.dtype,
            operands.B.dtype,
            design.tile_shape[1],
            design.use_2cta_mma,
            design.enable_breuse,
        )
        preferred_cluster_shape_mn = design.cluster_shape[:2]
        fallback_cluster_shape_mn = (
            design.fallback_cluster_shape[:2]
            if design.fallback_cluster_shape is not None
            else design.cluster_shape[:2]
        )

        self.impl = Sm107BlockScaledGemmUniversal(
            sf_vec_size=ScaleMode.numel(operands.A.mode),
            mma_inst_shape=mma_inst_shape,
            mma_tiler=mma_tiler,
            preferred_cluster_shape_mn=preferred_cluster_shape_mn,
            fallback_cluster_shape_mn=fallback_cluster_shape_mn,
            prefetch_dist=None,
        )

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr = self._construct_pointers(
            args, nullptr=True
        )
        major_modes = gemm_major_modes(self.metadata.operands)
        c_layout = (
            cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
            if major_modes.out == cutlass.cute.nvgpu.OutputMajorMode.N
            else cutlass.tensor_utils.LayoutEnum.COL_MAJOR
        )
        fake_problem_size = (
            cutlass.Int32(0),
            cutlass.Int32(0),
            cutlass.Int32(0),
            cutlass.Int32(0),
        )  # kernel requires a fake problem size for compile, real is provided at runtime

        return self.cute_compile(
            self.impl,
            a_ptr,
            b_ptr,
            sfa_ptr,
            sfb_ptr,
            c_ptr,
            (major_modes.A, major_modes.B, c_layout),
            fake_problem_size,
            get_max_active_clusters(self.impl.preferred_cluster_shape_mn),
            get_max_active_clusters(self.impl.fallback_cluster_shape_mn),
            cutlass.cute.runtime.make_fake_stream(),
            lambda x: x,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr = self._construct_pointers(args)
        self.cute_run(
            compiled_artifact.compiled_obj,
            a_ptr,
            b_ptr,
            sfa_ptr,
            sfb_ptr,
            c_ptr,
            args.problem_size,
            to_cuda_stream(stream),
        )

    def _construct_pointers(self, args: GemmArguments, nullptr: bool = False):
        """Return the ``(A, B, SFA, SFB, C)`` pointers the kernel is called with."""
        gmem = cutlass.AddressSpace.gmem
        return (
            make_ptr(args.A.quantized, nullptr, gmem, assumed_align=16),
            make_ptr(args.B.quantized, nullptr, gmem, assumed_align=16),
            make_ptr(args.A.scale, nullptr, gmem, assumed_align=32),
            make_ptr(args.B.scale, nullptr, gmem, assumed_align=32),
            make_ptr(args.out, nullptr, gmem, assumed_align=16),
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments | None = None,
    ) -> list[Sm107DenseBlockScaledGemmOperator]:
        if epilogue_args is not None:
            return []

        operators = []
        for operand_keys in _valid_operand_combos(args):
            operands = _make_operands_metadata(**operand_keys)
            operands_name = _operands_name_part(operands)
            for design, design_name in _valid_designs(
                operand_keys["a_dtype"], operand_keys["b_dtype"]
            ):
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operands_name + design_name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )
                if metadata_filter(metadata):
                    operators.append(cls(metadata))

        return operators


################################################################################
# Helpers to enumerate the configuration space
################################################################################


def _valid_operand_combos(args: GemmArguments | None) -> list[dict]:
    """Enumerate the operand configurations the kernel accepts.

    ``args``, when given, narrows the enumeration to the one configuration it
    describes; an empty result means this operator cannot serve it.
    """
    # Every value the kernel accepts for each operand parameter. Only a subset
    # of the cross product is legal, checked by _kernel_accepts_operands below.
    operand_keys = {
        "a_dtype": (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, cutlass.Float8E5M2),
        "b_dtype": (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, cutlass.Float8E5M2),
        "sf_dtype": (
            cutlass.Float8E8M0FNU,
            cutlass.Float8E4M3FN,
            cutlass.FloatNV8E5M3FNU,
        ),
        "out_dtype": (cutlass.Float32, cutlass.Float16, cutlass.BFloat16),
        "acc_dtype": (cutlass.Float32,),
        "sf_vec_size": (16, 32),
        "a_major": ("m", "k"),
        "b_major": ("n", "k"),
        "c_major": ("m", "n"),
    }

    if args is not None:
        requested_keys = _operand_keys_from_args(args)
        if requested_keys is None:
            return []
        # Arguments may only narrow the space above, never widen it.
        if any(
            value not in operand_keys[key] for key, (value,) in requested_keys.items()
        ):
            return []
        operand_keys |= requested_keys

    combos = [
        dict(zip(operand_keys, operand_values))
        for operand_values in itertools.product(*operand_keys.values())
    ]
    return [combo for combo in combos if _kernel_accepts_operands(**combo)]


def _operand_keys_from_args(args: GemmArguments) -> dict[str, tuple] | None:
    """Return the single operand configuration ``args`` asks for, or ``None``.

    The result carries one value per operand parameter, keyed as the enumerated
    space in ``_generate_operators`` is, so that it narrows that space by dict
    update. ``None`` means this operator cannot serve ``args`` at all.
    """
    if not isinstance(args, GemmArguments):
        return None
    if not (isinstance(args.A, ScaledOperand) and isinstance(args.B, ScaledOperand)):
        return None
    # A and B feed one MMA, which reads both scale factor tensors with a single
    # swizzle, dtype and vector size.
    if (
        args.A.swizzle != ScaleSwizzleMode.Swizzle32x4x4
        or args.B.swizzle != ScaleSwizzleMode.Swizzle32x4x4
        or args.A.scale.dtype != args.B.scale.dtype
        or ScaleMode.numel(args.A.mode) != ScaleMode.numel(args.B.mode)
    ):
        return None

    def major(operand, row_major: str, col_major: str) -> str | None:
        """Name of the contiguous mode, or None if no mode has unit stride."""
        stride = normalized_major_stride(
            operand.shape, operand.stride, prepend_zeros_to_rank=3
        )
        return {(0, 0, 1): row_major, (0, 1, 0): col_major}.get(stride)

    return {
        "a_dtype": (args.A.quantized.dtype,),
        "b_dtype": (args.B.quantized.dtype,),
        "sf_dtype": (args.A.scale.dtype,),
        "out_dtype": (args.out.dtype,),
        "acc_dtype": (args.accumulator_type,),
        "sf_vec_size": (ScaleMode.numel(args.A.mode),),
        "a_major": (major(args.A.quantized, "k", "m"),),
        "b_major": (major(args.B.quantized, "n", "k"),),
        "c_major": (major(args.out, "n", "m"),),
    }


def _kernel_accepts_operands(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    sf_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    sf_vec_size: int,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> bool:
    """Return whether the kernel supports this operand configuration."""
    if acc_dtype is not cutlass.Float32:
        return False
    try:
        Sm107BlockScaledPersistentDenseGemmKernel.is_valid_dtypes_and_scale_factor_vec_size(
            a_dtype, b_dtype, sf_dtype, sf_vec_size, out_dtype
        )
        Sm107BlockScaledPersistentDenseGemmKernel.is_valid_layouts(
            a_dtype, b_dtype, out_dtype, a_major, b_major, c_major
        )
    except testing.CantImplementError:
        return False
    return True


@functools.cache
def _valid_designs(
    a_dtype: cutlass.Numeric, b_dtype: cutlass.Numeric
) -> tuple[tuple[Sm107DesignMetadata, str], ...]:
    """Enumerate the designs the kernel accepts for given operand dtypes, and part of the kernel name it decides.

    Cached as there is a fixed set of design combinations that will be repeatedly used.
    """
    # Maximal list of independent design parameters
    # Other design parameters are not independent: they are derived from the
    # parameters below and/or operand dtypes (see _mma_shapes).
    design_keys = {
        "use_2cta_mma": (False, True),
        "enable_breuse": (False, True),
        "tile_n": (64, 128, 256),
        "preferred_cluster_shape": tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m in (1, 2, 4)  # max deliberate capped to 4 by kernel
            for cluster_n in (1, 2, 4)
        ),
        "fallback_cluster_shape": ((1, 1, 1), (1, 2, 1), (2, 1, 1)),
    }

    designs = []
    for design_values in itertools.product(*design_keys.values()):
        design_combo = dict(zip(design_keys, design_values))
        preferred = design_combo["preferred_cluster_shape"]
        fallback = design_combo["fallback_cluster_shape"]
        if not Sm107DesignMetadata.is_valid_fallback_cluster(preferred, fallback):
            continue

        cta_tile_shape, mma_tiler, mma_inst_shape = _mma_shapes(
            a_dtype,
            b_dtype,
            design_combo["tile_n"],
            design_combo["use_2cta_mma"],
            design_combo["enable_breuse"],
        )
        try:
            for cluster_shape in (preferred, fallback):
                Sm107BlockScaledPersistentDenseGemmKernel.is_valid_mma_tiler_and_cluster_shape(
                    a_dtype, b_dtype, mma_inst_shape, mma_tiler, cluster_shape[:2]
                )
        except testing.CantImplementError:
            continue

        design = Sm107DesignMetadata(
            mma_instruction_type=RubinTcgen05Mma,
            use_tma_store=True,
            use_2cta_mma=design_combo["use_2cta_mma"],
            enable_breuse=design_combo["enable_breuse"],
            tile_shape=cta_tile_shape,
            cluster_shape=preferred,
            fallback_cluster_shape=fallback,
        )
        designs.append((design, _design_name_part(design)))
    return tuple(designs)


################################################################################
# Helpers to map one configuration onto the kernel
################################################################################


def _mma_shapes(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    tile_n: int,
    use_2cta_mma: bool,
    enable_breuse: bool,
) -> tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]]:
    """Return ``(cta_tile_shape, mma_tiler, mma_inst_shape)`` for a configuration.

    * instruction M is 128 per participating CTA, so 256 for a 2CTA instruction;
    * instruction K is 128 for FP4 x FP4 and 64 for every MXF8F6F4 mix, and the
      mainloop always runs two instructions along K per tile;
    * B-reuse fires the instruction a second time along M, keeping B in place.

    ``mma_tiler`` spans all the CTAs cooperating on one instruction, while
    ``cta_tile_shape`` -- the tile shape the design metadata carries -- is that
    tiler as seen by one of them.
    """
    mma_ctas = 2 if use_2cta_mma else 1
    instructions_m = 2 if enable_breuse else 1
    is_nvf4 = a_dtype is cutlass.Float4E2M1FN and b_dtype is cutlass.Float4E2M1FN
    inst_k = 128 if is_nvf4 else 64

    mma_inst_shape = (128 * mma_ctas, tile_n, inst_k)
    mma_tiler = (mma_inst_shape[0] * instructions_m, tile_n, inst_k * 2)
    cta_tile_shape = (mma_tiler[0] // mma_ctas, tile_n, mma_tiler[2])
    return cta_tile_shape, mma_tiler, mma_inst_shape


def _make_operands_metadata(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    sf_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    sf_vec_size: int,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> GemmOperandsMetadata:
    """Make GemmOperandsMetadata from operand config keys."""
    stride_A = (0, 0, 1) if a_major == "k" else (0, 1, 0)
    stride_B = (0, 0, 1) if b_major == "n" else (0, 1, 0)
    stride_out = (0, 0, 1) if c_major == "n" else (0, 1, 0)

    alignment_bytes = 16

    def elements_per_line(dtype: cutlass.Numeric) -> int:
        return alignment_bytes * 8 // dtype.width

    # A scale factor tensor is a flat buffer whose size the swizzle layout
    # dictates rather than the problem shape, so only its base pointer is
    # constrained.
    def scale_constraints() -> DenseTensorConstraints:
        return DenseTensorConstraints(
            dtype=sf_dtype, stride=None, divisibility=1, ptr_alignment_bytes=32
        )

    scale_mode = (
        ScaleMode.Blockwise1x16 if sf_vec_size == 16 else ScaleMode.Blockwise1x32
    )
    return GemmOperandsMetadata(
        A=ScaledOperandConstraints(
            quantized=DenseTensorConstraints(
                dtype=a_dtype,
                stride=stride_A,
                divisibility=elements_per_line(a_dtype),
            ),
            scale=scale_constraints(),
            mode=scale_mode,
            swizzle=ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledOperandConstraints(
            quantized=DenseTensorConstraints(
                dtype=b_dtype,
                stride=stride_B,
                divisibility=elements_per_line(b_dtype),
            ),
            scale=scale_constraints(),
            mode=scale_mode,
            swizzle=ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=DenseTensorConstraints(
            dtype=out_dtype,
            stride=stride_out,
            divisibility=elements_per_line(out_dtype),
        ),
        accumulator_type=acc_dtype,
    )


def _operands_name_part(operands: GemmOperandsMetadata) -> str:
    """Build the operands half of an Operator name."""
    layout = strides_to_layout_string(
        operands.A.stride, operands.B.stride, operands.out.stride
    )
    # The scale factor swizzle is not part of the name: Swizzle32x4x4 is the
    # only mode this operator generates.
    return (
        "cutedsl.Sm107DenseBlockScaledGemmOperator"
        f"_{layout}"
        f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}"
        f"_SF{operands.A.scale.dtype}x{ScaleMode.numel(operands.A.mode)}"
        f"_acc{operands.accumulator_type}"
    )


def _design_name_part(design: Sm107DesignMetadata) -> str:
    """Build the design half of an Operator name."""
    return (
        f"_{'2' if design.use_2cta_mma else '1'}cta"
        f"_cluster{tuple_to_string(design.cluster_shape)}"
        f"{f'_fallback{tuple_to_string(design.fallback_cluster_shape)}' if design.fallback_cluster_shape is not None else ''}"
        f"_tile{tuple_to_string(design.tile_shape)}"
        f"{'_breuse' if design.enable_breuse else ''}"
    )
