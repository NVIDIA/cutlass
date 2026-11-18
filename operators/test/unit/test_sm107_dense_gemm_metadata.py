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


import pytest

import cutlass
from cutlass import testing

import cutlass.operators.utils.generate as generate
from cutlass.operators.arguments.tile_scheduler_settings import RasterOrder
from cutlass.operators.metadata import (
    OperatorMetadata,
    Sm100DesignMetadata,
    Sm107DesignMetadata,
)
from cutlass.operators.metadata.design.tile_scheduler import (
    ClusterSplitKReductionMetadata,
    NoReductionMetadata,
    SplitKReductionMetadata,
    StaticPersistentMetadata,
    TileSchedulerMetadata,
    TileSwizzleRasterizationMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.providers.cutedsl.gemm import (
    sm107_dense_gemm_universal as dense,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_dense_gemm_universal import (
    Sm107DenseGemmUniversalOperator,
    _kernel_accepts_operands,
)

# The Rubin kernel's default schedule.
_DEFAULT_SCHEDULER = TileSchedulerMetadata(
    persistence=StaticPersistentMetadata(),
    reduction=NoReductionMetadata(),
    rasterization=TileSwizzleRasterizationMetadata(
        swizzle_size=(1, 2, 4, 8), raster_order=tuple(RasterOrder)
    ),
)


def _make_design(**overrides) -> Sm107DesignMetadata:
    params = {
        "mma_instruction_type": RubinTcgen05Mma,
        "use_2cta_mma": True,
        "tile_shape": (256, 256, 128),
        "cluster_shape": (4, 2, 1),
        "fallback_cluster_shape": (2, 1, 1),
        "use_tma_store": True,
        "enable_breuse": True,
        "tile_scheduler": _DEFAULT_SCHEDULER,
    }
    params.update(overrides)
    return Sm107DesignMetadata(**params)


def _make_operands(
    ab_dtype=cutlass.Float8E4M3FN,
    out_dtype=cutlass.Float16,
    acc_dtype=cutlass.Float32,
):
    return generate.construct_dense_gemm_operands(
        a_dtype=ab_dtype,
        b_dtype=ab_dtype,
        out_dtype=out_dtype,
        acc_dtype=acc_dtype,
        stride_A=(0, 0, 1),
        stride_B=(0, 0, 1),
        stride_out=(0, 0, 1),
        alignment_bytes=16,
    )


def _make_metadata(operands=None, **design_overrides) -> OperatorMetadata:
    return OperatorMetadata(
        operator_name="test_sm107_dense_gemm",
        operator_class=Sm107DenseGemmUniversalOperator,
        supported_targets=[],
        operands=operands if operands is not None else _make_operands(),
        design=_make_design(**design_overrides),
    )


def _kernel_can_compile(metadata: OperatorMetadata) -> bool:
    operands = metadata.operands
    try:
        Sm107DenseGemmUniversalOperator(metadata).impl.can_compile(
            operands.A.dtype, operands.B.dtype, operands.out.dtype
        )
    except testing.CantImplementError:
        return False
    return True


@pytest.mark.parametrize(
    "overrides, error",
    [
        (
            {"fallback_cluster_shape": (0, 1, 1)},
            "fallback_cluster_shape dimensions must be positive",
        ),
        (
            {"tile_shape": (0, 256, 128)},
            "tile_shape dimensions must be positive",
        ),
    ],
)
def test_sm107_design_rejects_invalid_configs(overrides, error):
    with pytest.raises(ValueError, match=error):
        _make_design(**overrides)


def test_sm107_design_allows_larger_clusters_than_sm100():
    """SM107 raises the non-portable cluster limit from 16 to 30 CTAs."""
    common = {
        "mma_instruction_type": RubinTcgen05Mma,
        "use_2cta_mma": False,
        "tile_shape": (128, 128, 128),
        "use_tma_store": True,
    }
    Sm107DesignMetadata(**common, cluster_shape=(4, 5, 1))
    with pytest.raises(ValueError, match="too large"):
        Sm100DesignMetadata(**common, cluster_shape=(4, 5, 1))
    with pytest.raises(ValueError, match="too large"):
        Sm107DesignMetadata(**common, cluster_shape=(4, 8, 1))


def test_sm107_operator_accepts_base_metadata():
    """Without this, every rejection below could pass for an unrelated reason."""
    assert _kernel_can_compile(_make_metadata())


@pytest.mark.parametrize(
    "tile_shape, use_2cta_mma, enable_breuse, expected_inst_shape",
    [
        ((128, 128, 128), False, False, (128, 128, 64)),
        ((128, 128, 128), True, False, (256, 128, 64)),
        # B-reuse issues the 256-row 2CTA instruction twice along M.
        ((256, 256, 128), True, True, (256, 256, 64)),
        # Instruction K stays at the FP8 width however deep the tile is.
        ((256, 256, 256), True, True, (256, 256, 64)),
    ],
)
def test_sm107_operator_derives_instruction_shape(
    tile_shape, use_2cta_mma, enable_breuse, expected_inst_shape
):
    metadata = _make_metadata(
        tile_shape=tile_shape,
        use_2cta_mma=use_2cta_mma,
        enable_breuse=enable_breuse,
    )
    assert _kernel_can_compile(metadata)

    operator = Sm107DenseGemmUniversalOperator(metadata)
    assert tuple(operator.impl.mma_inst_shape) == expected_inst_shape


@pytest.mark.parametrize(
    "tile_shape",
    [
        pytest.param((128, 256, 128), id="tile_m_not_256_for_2cta_breuse"),
        pytest.param((257, 256, 128), id="tile_m_off_by_one"),
        pytest.param((256, 256, 96), id="tile_k_not_multiple_of_inst_k"),
        # Each B-reuse accumulator stage rounds up to 512 TMEM columns, so two
        # stages exceed SM107's 576 columns.
        pytest.param((256, 160, 128), id="breuse_exceeds_tmem_n160"),
        pytest.param((256, 192, 128), id="breuse_exceeds_tmem_n192"),
        pytest.param((256, 224, 128), id="breuse_exceeds_tmem_n224"),
    ],
)
def test_sm107_operator_rejects_invalid_tile_shape(tile_shape):
    assert not _kernel_can_compile(_make_metadata(tile_shape=tile_shape))


@pytest.mark.parametrize(
    "ab_dtype, out_dtype, expected",
    [
        (cutlass.Float8E4M3FN, cutlass.BFloat16, True),
        (cutlass.Float8E4M3FN, cutlass.Float16, True),
        # The epilogue cannot write FP8 from an FP16 accumulator.
        (cutlass.Float8E4M3FN, cutlass.Float8E4M3FN, False),
        (cutlass.Float8E4M3FN, cutlass.Float8E5M2, False),
        (cutlass.Float16, cutlass.Float16, True),
        # There is no BF16 MMA into an FP16 accumulator.
        (cutlass.BFloat16, cutlass.BFloat16, False),
    ],
)
def test_sm107_operator_validates_fp16_accumulator_operands(
    ab_dtype, out_dtype, expected
):
    assert (
        _kernel_accepts_operands(
            a_dtype=ab_dtype,
            b_dtype=ab_dtype,
            out_dtype=out_dtype,
            acc_dtype=cutlass.Float16,
            a_major="k",
            b_major="n",
            c_major="n",
        )
        is expected
    )


@pytest.mark.parametrize(
    "a_dtype, b_dtype, expected",
    [
        (cutlass.Float8E4M3FN, cutlass.Float8E5M2, True),
        (cutlass.Float8E5M2, cutlass.Float8E4M3FN, True),
        (cutlass.Float8E4M3FN, cutlass.Float16, False),
        (cutlass.Float16, cutlass.Float8E4M3FN, False),
    ],
)
def test_sm107_operator_validates_mixed_input_dtypes(a_dtype, b_dtype, expected):
    assert (
        _kernel_accepts_operands(
            a_dtype=a_dtype,
            b_dtype=b_dtype,
            out_dtype=cutlass.Float16,
            acc_dtype=cutlass.Float32,
            a_major="k",
            b_major="n",
            c_major="n",
        )
        is expected
    )


@pytest.mark.parametrize(
    "ab_dtype, enable_breuse, expected",
    [
        (cutlass.Float8E4M3FN, True, True),
        (cutlass.Float16, False, True),
        (cutlass.Float16, True, False),
    ],
)
def test_sm107_operator_restricts_breuse_to_fp8(ab_dtype, enable_breuse, expected):
    metadata = _make_metadata(
        operands=_make_operands(ab_dtype=ab_dtype),
        tile_shape=(256 if enable_breuse else 128, 256, 128),
        enable_breuse=enable_breuse,
    )
    assert _kernel_can_compile(metadata) is expected


@pytest.mark.parametrize(
    "acc_dtype, expected",
    [(cutlass.Float32, True), (cutlass.Float16, False)],
)
def test_sm107_operator_restricts_cluster_split_k_to_fp32_accumulator(
    acc_dtype, expected
):
    """The cluster split-K DSMEM mailbox exchanges Float32 partials."""
    cluster_split_k = TileSchedulerMetadata(
        persistence=StaticPersistentMetadata(),
        reduction=ClusterSplitKReductionMetadata(split_count=(2,)),
        rasterization=_DEFAULT_SCHEDULER.rasterization,
    )
    metadata = _make_metadata(
        operands=_make_operands(acc_dtype=acc_dtype),
        use_2cta_mma=False,
        enable_breuse=False,
        tile_shape=(128, 128, 128),
        cluster_shape=(1, 2, 1),
        fallback_cluster_shape=(1, 1, 1),
        use_tma_store=False,
        tile_scheduler=cluster_split_k,
    )
    assert _kernel_can_compile(metadata) is expected


def test_sm107_dense_generates_non_tma_store_only_for_cluster_split_k(monkeypatch):
    gmem_split_k = TileSchedulerMetadata(
        persistence=StaticPersistentMetadata(),
        reduction=SplitKReductionMetadata(split_count=(2,)),
        rasterization=_DEFAULT_SCHEDULER.rasterization,
    )
    cluster_split_k = TileSchedulerMetadata(
        persistence=StaticPersistentMetadata(),
        reduction=ClusterSplitKReductionMetadata(split_count=(2,)),
        rasterization=_DEFAULT_SCHEDULER.rasterization,
    )
    design_values = (
        (
            False,
            False,
            False,
            128,
            128,
            (2, 1, 1),
            (1, 1, 1),
            _DEFAULT_SCHEDULER,
        ),
        (
            False,
            False,
            False,
            128,
            128,
            (2, 1, 1),
            (1, 1, 1),
            gmem_split_k,
        ),
        (
            False,
            False,
            False,
            128,
            128,
            (2, 1, 1),
            (1, 1, 1),
            cluster_split_k,
        ),
    )
    monkeypatch.setattr(dense.itertools, "product", lambda *args: design_values)
    monkeypatch.setattr(dense.scheduling, "enumerate_tile_schedulers", lambda: tuple())
    monkeypatch.setattr(
        dense.scheduling, "reduction_fits", lambda *args, **kwargs: True
    )
    monkeypatch.setattr(
        dense.SM107PersistentDenseGemmKernel,
        "is_valid_mma_tiler_and_cluster_shape",
        lambda *args, **kwargs: None,
    )

    designs = dense._valid_designs.__wrapped__(
        cutlass.Float8E4M3FN,
        cutlass.Float8E4M3FN,
        cutlass.Float32,
    )

    assert len(designs) == 1
    assert not designs[0].use_tma_store
    assert isinstance(
        designs[0].tile_scheduler.reduction, ClusterSplitKReductionMetadata
    )
