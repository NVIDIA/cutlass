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

from types import EllipsisType

import pytest

import cutlass.operators as ops
from cutlass.operators.metadata.design.sm100 import Sm100DesignMetadata
from cutlass.operators.metadata.design.tile_scheduler import (
    ClusterSplitKReductionMetadata,
    NonPersistentMetadata,
    NoRasterizationMetadata,
    NoReductionMetadata,
    SplitKReductionMetadata,
    StaticPersistentMetadata,
    TileSchedulerMetadata,
    TileSwizzleRasterizationMetadata,
)
from cutlass.operators.metadata.operands.base import OperandsMetadata
from cutlass.operators.typing import AnyValue


class AnyOperandsMetadata(OperandsMetadata):
    """Operands metadata that accepts anything, to isolate the design check."""

    def supports(self, args) -> ops.Status:
        return ops.Status.success()


def make_design_with_scheduler(tile_scheduler) -> Sm100DesignMetadata:
    """Build an SM100 design around a tile scheduler, or around none at all."""
    return Sm100DesignMetadata(
        mma_instruction_type=object,
        tile_shape=(128, 128, 64),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=True,
        tile_scheduler=tile_scheduler,
    )


def make_design(
    *,
    reduction,
    rasterization,
    persistence=None,
) -> Sm100DesignMetadata:
    """Build an SM100 design around the requested scheduler strategies."""
    return make_design_with_scheduler(
        TileSchedulerMetadata(
            persistence=persistence or NonPersistentMetadata(),
            reduction=reduction,
            rasterization=rasterization,
        )
    )


def gemm_controls(**kwargs) -> ops.GemmPerformanceControls:
    """Wrap tile-scheduler settings in :class:`GemmPerformanceControls`."""
    if not kwargs:
        return ops.GemmPerformanceControls()
    return ops.GemmPerformanceControls(
        tile_scheduler_controls=ops.TileSchedulerControls(**kwargs)
    )


def supports(
    design: Sm100DesignMetadata,
    controls: ops.PerformanceControls | None | EllipsisType,
) -> ops.Status:
    """Check controls against a design through the public arguments path."""
    return design.supports(ops.RuntimeArguments(performance=controls))


def swizzle_controls(value: int) -> ops.GemmPerformanceControls:
    """Build a swizzle-size request."""
    return gemm_controls(swizzle_size=value)


def test_omitted_settings_stay_unset() -> None:
    rasterization = TileSwizzleRasterizationMetadata()
    assert rasterization.raster_order is None
    assert rasterization.swizzle_size is None
    assert SplitKReductionMetadata().split_count is None


def test_int_setting_accepts_narrowed_runtime_domain() -> None:
    rasterization = TileSwizzleRasterizationMetadata(swizzle_size=(1, 2, 3, 4))
    reduction = SplitKReductionMetadata(split_count=(2, 3, 4))
    assert rasterization.swizzle_size == (1, 2, 3, 4)
    assert reduction.split_count == (2, 3, 4)

    controls = gemm_controls(swizzle_size=2, split_count=2)
    design = make_design(rasterization=rasterization, reduction=reduction)
    assert supports(design, controls).error is None

    bad_controls_one = gemm_controls(swizzle_size=9, split_count=2)
    assert "swizzle_size=9" in str(supports(design, bad_controls_one).error)
    bad_controls_two = gemm_controls(swizzle_size=2, split_count=9)
    assert "split_count=9" in str(supports(design, bad_controls_two).error)


def test_setting_accepts_narrowed_raster_order_domain() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(
            raster_order=(ops.RasterOrder.ALONG_N,)
        ),
    )
    assert (
        supports(
            design,
            gemm_controls(raster_order=ops.RasterOrder.ALONG_N),
        ).error
        is None
    )
    status = supports(
        design,
        gemm_controls(raster_order=ops.RasterOrder.ALONG_M),
    )
    assert "raster_order" in str(status.error)


def test_metadata_settings_reject_unknown_types() -> None:
    with pytest.raises(ValueError, match="swizzle_size"):
        TileSwizzleRasterizationMetadata(swizzle_size="2")  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="raster_order"):
        TileSwizzleRasterizationMetadata(raster_order="n")  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="split_count"):
        SplitKReductionMetadata(split_count="2")  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="Unrecognized type"):
        ClusterSplitKReductionMetadata(split_count=2)  # type: ignore[arg-type]


def test_metadata_settings_reject_wildcard_over_other_values() -> None:
    """An int parameter accepts the wildcard domain of ``int`` and no other."""
    with pytest.raises(ValueError, match=r"swizzle_size: AnyValue\[str\]"):
        TileSwizzleRasterizationMetadata(swizzle_size=AnyValue(str))  # type: ignore[arg-type]
    with pytest.raises(ValueError, match=r"split_count: AnyValue\[RasterOrder\]"):
        SplitKReductionMetadata(split_count=AnyValue(ops.RasterOrder))  # type: ignore[arg-type]


def test_runtime_swizzle_size_accepts_any_control_value() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(
            raster_order=(ops.RasterOrder.ALONG_M, ops.RasterOrder.ALONG_N),
            swizzle_size=AnyValue(int),
        ),
    )
    controls = gemm_controls(
        raster_order=ops.RasterOrder.ALONG_N,
        swizzle_size=3,
    )
    assert supports(design, controls).error is None


def test_runtime_split_count_accepts_any_control_value() -> None:
    design = make_design(
        reduction=SplitKReductionMetadata(split_count=AnyValue(int)),
        rasterization=NoRasterizationMetadata(),
    )
    assert supports(design, gemm_controls(split_count=8)).error is None


def test_unset_rasterization_settings_reject_requested_values() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(),
    )
    status = supports(design, swizzle_controls(2))
    assert "swizzle_size=2" in str(status.error)


def test_unset_split_count_rejects_requested_count() -> None:
    design = make_design(
        reduction=SplitKReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    status = supports(design, gemm_controls(split_count=8))
    assert "split_count=8" in str(status.error)


def test_absent_metadata_strategy_rejects_control() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    controls = gemm_controls(rasterization=ops.RasterizationStrategy.TILE_SWIZZLE)
    assert "rasterization=" in str(supports(design, controls).error)


def test_compile_time_metadata_requires_exact_control_value() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(swizzle_size=(2,)),
    )
    assert supports(design, swizzle_controls(2)).error is None
    assert "swizzle_size=4" in str(supports(design, swizzle_controls(4)).error)


def test_tuple_metadata_accepts_only_its_domain() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(swizzle_size=(1, 2, 3, 4)),
    )
    assert supports(design, swizzle_controls(2)).error is None
    assert "swizzle_size=8" in str(supports(design, swizzle_controls(8)).error)


def test_compile_time_cluster_split_k_requires_exact_control() -> None:
    design = make_design(
        reduction=ClusterSplitKReductionMetadata(split_count=(4,)),
        rasterization=NoRasterizationMetadata(),
    )
    assert supports(design, gemm_controls(split_count=4)).error is None
    status = supports(design, gemm_controls(split_count=2))
    assert "split_count=2" in str(status.error)


def test_flat_split_count_matches_both_split_k_strategies() -> None:
    split_k = make_design(
        reduction=SplitKReductionMetadata(split_count=AnyValue(int)),
        rasterization=NoRasterizationMetadata(),
    )
    cluster_split_k = make_design(
        reduction=ClusterSplitKReductionMetadata(split_count=(2,)),
        rasterization=NoRasterizationMetadata(),
    )
    controls = gemm_controls(split_count=2)
    assert supports(split_k, controls).error is None
    assert supports(cluster_split_k, controls).error is None


def test_cluster_split_k_rejects_non_singleton_compile_time_tuple() -> None:
    with pytest.raises(ValueError, match="tuple of length 1"):
        ClusterSplitKReductionMetadata(split_count=(2, 4))  # type: ignore[arg-type]


def test_explicit_reduction_strategy_rejects_other_strategy() -> None:
    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    controls = gemm_controls(reduction=ops.ReductionStrategy.SPLIT_K)
    assert "reduction=" in str(supports(design, controls).error)


def test_no_reduction_with_split_count_fails_at_construction() -> None:
    with pytest.raises(ValueError, match="split_count"):
        ops.TileSchedulerControls(
            reduction=ops.ReductionStrategy.NO_REDUCTION,
            split_count=2,
        )


@pytest.mark.parametrize(
    "settings",
    [
        {"reduction": ops.ReductionStrategy.NO_REDUCTION, "split_count": 1},
        {
            "rasterization": ops.RasterizationStrategy.NO_RASTERIZATION,
            "swizzle_size": 1,
        },
        {
            "rasterization": ops.RasterizationStrategy.NO_RASTERIZATION,
            "raster_order": ops.RasterOrder.ALONG_M,
        },
    ],
)
def test_do_nothing_strategy_rejects_its_neutral_setting_value(settings) -> None:
    """No operator offers a setting its strategy does not have"""
    with pytest.raises(ValueError, match="must be unset"):
        ops.TileSchedulerControls(**settings)


def test_controls_reject_invalid_values() -> None:
    with pytest.raises(ValueError, match="split_count"):
        ops.TileSchedulerControls(split_count="3")  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="split_count"):
        ops.TileSchedulerControls(split_count=0)
    with pytest.raises(ValueError, match="swizzle_size"):
        ops.TileSchedulerControls(swizzle_size="3")  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="raster_order"):
        ops.TileSchedulerControls(raster_order="diagonal")  # type: ignore[arg-type]


def test_strategy_axes_canonicalize_none_to_do_nothing() -> None:
    """A strategy axis is always present, so ``None`` selects its do-nothing value."""
    controls = ops.TileSchedulerControls(reduction=None, rasterization=None)
    spelled_out = ops.TileSchedulerControls(
        reduction=ops.ReductionStrategy.NO_REDUCTION,
        rasterization=ops.RasterizationStrategy.NO_RASTERIZATION,
    )
    assert controls == spelled_out
    assert hash(controls) == hash(spelled_out)
    assert controls.requested_values() == {
        "reduction": ops.ReductionStrategy.NO_REDUCTION,
        "rasterization": ops.RasterizationStrategy.NO_RASTERIZATION,
    }


def test_canonicalized_axis_still_rejects_its_neutral_setting() -> None:
    """Canonicalization runs before the cross-setting checks."""
    with pytest.raises(ValueError, match="must be unset"):
        ops.TileSchedulerControls(reduction=None, split_count=2)
    with pytest.raises(ValueError, match="must be unset"):
        ops.TileSchedulerControls(rasterization=None, swizzle_size=2)


@pytest.mark.parametrize(
    ("reduction", "rasterization"),
    [
        (NoReductionMetadata(), NoRasterizationMetadata()),
        (SplitKReductionMetadata(), TileSwizzleRasterizationMetadata()),
    ],
)
def test_empty_performance_controls_support_tile_scheduler_metadata(
    reduction,
    rasterization,
) -> None:
    design = make_design(reduction=reduction, rasterization=rasterization)
    assert supports(design, gemm_controls()).error is None


def test_default_tile_scheduler_controls_is_ellipsis() -> None:
    controls = ops.GemmPerformanceControls()
    assert controls.tile_scheduler_controls is Ellipsis


def test_explicit_none_tile_scheduler_controls_differs_from_ellipsis() -> None:
    """``None`` demands an operator offering no tile scheduler controls.

    ``...`` accepts any operator.
    """
    omitted = ops.GemmPerformanceControls()
    explicit_none = ops.GemmPerformanceControls(tile_scheduler_controls=None)
    assert omitted.tile_scheduler_controls is Ellipsis
    assert explicit_none.tile_scheduler_controls is None

    without_scheduler = make_design_with_scheduler(None)
    assert supports(without_scheduler, omitted).error is None
    assert supports(without_scheduler, explicit_none).error is None

    with_scheduler = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    assert supports(with_scheduler, omitted).error is None
    status = supports(with_scheduler, explicit_none)
    assert "an operator without a tile scheduler metadata features" in str(status.error)


def test_default_performance_is_ellipsis() -> None:
    assert ops.RuntimeArguments().performance is Ellipsis


def test_performance_none_requires_an_operator_without_controls() -> None:
    """``performance=None`` asks for an operator that exposes no controls at all."""
    with_scheduler = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    assert supports(with_scheduler, ...).error is None
    assert "without performance" in str(supports(with_scheduler, None).error)

    without_scheduler = make_design_with_scheduler(None)
    assert supports(without_scheduler, ...).error is None
    assert supports(without_scheduler, None).error is None


def test_absent_design_metadata_accepts_unspecified_performance() -> None:
    """An operator without design metadata still matches a caller who asked for nothing."""
    metadata = ops.OperatorMetadata(
        operator_name="OperatorWithoutDesignMetadata",
        operator_class=object,
        supported_targets=[ops.TargetSm("80")],
        operands=AnyOperandsMetadata(),
    )
    assert metadata.supports(ops.RuntimeArguments()).error is None
    assert metadata.supports(ops.RuntimeArguments(performance=None)).error is None
    status = metadata.supports(ops.RuntimeArguments(performance=gemm_controls()))
    assert "design metadata is absent" in str(status.error)


def test_controls_for_another_operation_are_rejected() -> None:
    """Controls that are not GEMM controls will fail support check."""
    foreign = ops.PerformanceControls()

    with_scheduler = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    assert "GemmPerformanceControls" in str(supports(with_scheduler, foreign).error)

    without_scheduler = make_design_with_scheduler(None)
    assert "GemmPerformanceControls" in str(supports(without_scheduler, foreign).error)


class TestNoTileSchedulerMetadataFailsControls:
    """Designs without a tile scheduler must reject concrete setting requests."""

    def test_sm100_design_without_tile_scheduler_rejects_concrete_settings(
        self,
    ) -> None:
        without_scheduler = make_design_with_scheduler(None)
        status = supports(without_scheduler, swizzle_controls(257))
        test_str = "tile schedul"  # intentional shortening to match schedule/scheduling
        assert test_str in str(status.error)

        # Controls that address the tile scheduler at all assert that the
        # operator has one, even when every setting inside is left absent.
        status = supports(
            without_scheduler,
            gemm_controls(swizzle_size=None, raster_order=None),
        )
        assert test_str in str(status.error)

        # Expressing no opinion about the tile scheduler still matches.
        assert supports(without_scheduler, gemm_controls()).error is None

    def test_blas_design_without_tile_scheduler_rejects_concrete_settings(self) -> None:
        from cutlass.operators.metadata.design.base import BLASDesignMetadata

        design = BLASDesignMetadata(
            mma_instruction_type=object,
            tile_shape=(128, 128, 64),
            cluster_shape=(1, 1, 1),
        )
        status = supports(design, swizzle_controls(4))
        assert "no tile scheduler" in str(status.error)
        assert supports(design, gemm_controls()).error is None
        assert supports(design, None).error is None


def test_setting_level_none_is_same_as_ellipses() -> None:
    settings = ops.TileSchedulerControls(swizzle_size=None, split_count=None)
    assert settings.requested_values() == {"swizzle_size": None, "split_count": None}

    design = make_design(
        reduction=NoReductionMetadata(),
        rasterization=NoRasterizationMetadata(),
    )
    controls = ops.GemmPerformanceControls(tile_scheduler_controls=settings)
    assert supports(design, controls).error is None

    design_second = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(),
    )

    design_with_settings = make_design(
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(swizzle_size=(4,)),
    )
    controls = ops.GemmPerformanceControls(tile_scheduler_controls=settings)
    assert supports(design, controls).error is None
    assert supports(design_second, controls).error is None
    assert supports(design_with_settings, controls).error is not None


def test_requested_values_omit_unrequested_controls() -> None:
    controls = ops.TileSchedulerControls(swizzle_size=4)
    assert controls.requested_values() == {"swizzle_size": 4}


def test_requested_values_include_all_control_axes() -> None:
    controls = ops.TileSchedulerControls(
        reduction=ops.ReductionStrategy.SPLIT_K,
        split_count=8,
        rasterization=ops.RasterizationStrategy.TILE_SWIZZLE,
        raster_order=ops.RasterOrder.ALONG_N,
        swizzle_size=4,
    )
    assert controls.requested_values() == {
        "reduction": ops.ReductionStrategy.SPLIT_K,
        "split_count": 8,
        "rasterization": ops.RasterizationStrategy.TILE_SWIZZLE,
        "raster_order": ops.RasterOrder.ALONG_N,
        "swizzle_size": 4,
    }


def test_static_persistence_rejects_no_rasterization_request() -> None:
    design = make_design(
        persistence=StaticPersistentMetadata(),
        reduction=NoReductionMetadata(),
        rasterization=TileSwizzleRasterizationMetadata(),
    )
    controls = gemm_controls(rasterization=ops.RasterizationStrategy.NO_RASTERIZATION)
    assert supports(design, controls).error is not None
