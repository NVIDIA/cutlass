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


"""End-to-end tests for OperatorMetadata.supports() for performance controls."""

from dataclasses import dataclass

import pytest

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments.base import RuntimeArguments
from cutlass.operators.arguments.data_driven_sync import (
    DataDrivenSyncControls,
    DataDrivenSyncProducer,
)
from cutlass.operators.arguments.pdl import (
    EarlyLaunchDependent,
    ProgrammaticDependentLaunchControl,
)
from cutlass.operators.arguments.performance import GemmPerformanceControls
from cutlass.operators.metadata.base import OperatorMetadata
from cutlass.operators.metadata.design.base import BLASDesignMetadata
from cutlass.operators.metadata.design.data_driven_sync import (
    DataDrivenSyncConsumerMetadata,
    DataDrivenSyncMetadata,
    DataDrivenSyncProducerMetadata,
)
from cutlass.operators.metadata.design.pdl import ProgrammaticDependentLaunchMetadata
from cutlass.operators.metadata.design.sm100 import Sm100DesignMetadata
from cutlass.operators.metadata.design.sm107 import Sm107DesignMetadata
from cutlass.operators.metadata.operands.base import OperandsMetadata
from cutlass.operators.mma import BlackwellTcgen05Mma, RubinTcgen05Mma
from cutlass.operators.status import Status


@dataclass
class PerformanceOnlyArguments(RuntimeArguments):
    """Runtime arguments used to test design metadata without operands."""


@dataclass
class _StubOperandsMetadata(OperandsMetadata):
    """No-op operand metadata that accepts any args/target_sm.

    A stand-in for GemmOperandsMetadata, whose supports() doesn't accept
    target_sm yet (a separate, pre-existing bug at metadata/operands/base.py).
    Using the real class here would raise TypeError before ever reaching the
    design checks these tests exercise.
    """

    def supports(
        self, args: RuntimeArguments, target_sm: TargetSm | None = None
    ) -> Status:
        return Status.success()


def _make_operator_metadata(design, supported_target: str) -> OperatorMetadata:
    return OperatorMetadata(
        operator_name="design-supports-chain-test",
        operator_class=object,
        supported_targets=[TargetSm(supported_target)],
        operands=_StubOperandsMetadata(),
        design=design,
    )


def _combined_pdl_and_data_driven_sync_args() -> PerformanceOnlyArguments:
    return PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent(),
            ),
            data_driven_sync=DataDrivenSyncControls(producer=DataDrivenSyncProducer()),
        ),
    )


def test_sm100_design_accepts_supported_pdl_through_operator_metadata() -> None:
    """Sm100DesignMetadata accepts a PDL request its metadata declares support for."""
    design = Sm100DesignMetadata(
        mma_instruction_type=BlackwellTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(early_launch_dependent=True),
    )
    metadata = _make_operator_metadata(design, "100a")
    args = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent(),
            ),
        ),
    )

    status = metadata.supports(args, target_sm="100a")

    assert status, f"Expected True, got {status}"


@pytest.mark.parametrize(
    "empty_variant",
    [
        PerformanceOnlyArguments(),
        PerformanceOnlyArguments(
            performance=GemmPerformanceControls(
                pdl=ProgrammaticDependentLaunchControl(
                    early_launch_dependent=None, early_start=None
                )
            )
        ),
    ],
)
def test_sm100_pdl_design_accepts_empty_performance_controls(
    empty_variant: object,
) -> None:
    """PDL-enabled Sm100DesignMetadata accepts args with no GemmPerformanceControls.

    Unlike data-driven, PDL does not require the caller to opt in or out explicitly:
    an operator with PDL support simply becomes available when the caller requests
    it via GemmPerformanceControls.pdl. Callers that provide no performance controls
    at all are treated as not requesting PDL, and the design falls through to the
    base BLASDesignMetadata check, which accepts them.

    This is intentionally different from data-driven (see
    test_sm107_data_driven_sync_producer_rejects_empty_performance_controls), which rejects
    empty controls because silently running without data-driven synchronization can
    produce incorrect results.
    """
    design = Sm100DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(early_launch_dependent=True),
    )
    metadata = _make_operator_metadata(design, "100a")

    status = metadata.supports(empty_variant, target_sm="100a")

    assert status, f"Expected True, got {status}"


def test_sm100_design_rejects_unsupported_pdl_through_operator_metadata() -> None:
    """Sm100DesignMetadata rejects a PDL request its metadata doesn't declare support for."""
    design = Sm100DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
    )
    metadata = _make_operator_metadata(design, "100a")
    args = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent(),
            ),
        ),
    )

    status = metadata.supports(args, target_sm="100a")

    assert not status, f"Expected False, got {status}"


def test_sm100_rejects_data_driven_sync() -> None:
    design = Sm100DesignMetadata(
        mma_instruction_type=BlackwellTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
    )

    data_driven = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            data_driven_sync=DataDrivenSyncControls(producer=DataDrivenSyncProducer())
        )
    )
    status = design.supports(data_driven, target_sm="100a")
    assert not status, f"Expected False, got {status}"


def test_sm107_no_data_driven_sync() -> None:
    """A vanilla (no data-driven sync, no PDL) Sm107DesignMetadata must not crash on default args."""
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
    )  # data_driven_sync and pdl both default-disabled
    metadata = _make_operator_metadata(design, "107a")

    status = metadata.supports(PerformanceOnlyArguments(), target_sm="107a")

    assert status, f"Expected True, got {status}"


@pytest.mark.parametrize(
    "empty_variant",
    [
        PerformanceOnlyArguments(),
        PerformanceOnlyArguments(
            performance=GemmPerformanceControls(
                data_driven_sync=DataDrivenSyncControls()
            )
        ),
    ],
)
def test_sm107_data_driven_sync_producer_rejects_empty_performance_controls(
    empty_variant: object,
) -> None:
    """While potentially safe to support, it provides restrictions on output tensor values that may interact poorly.

    Not worth the risk as a result even if -0.0 and 0xFF are not values users typically want.
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        data_driven_sync=DataDrivenSyncMetadata(
            producer=DataDrivenSyncProducerMetadata(),
        ),
    )
    metadata = _make_operator_metadata(design, "107a")
    args = empty_variant
    status = metadata.supports(args, target_sm="107a")
    assert not status, f"Expected False, got {status}"


@pytest.mark.parametrize(
    "empty_variant",
    [
        PerformanceOnlyArguments(),
        PerformanceOnlyArguments(
            performance=GemmPerformanceControls(
                data_driven_sync=DataDrivenSyncControls()
            )
        ),
    ],
)
def test_sm107_data_driven_sync_consumer_rejects_empty_performance_controls(
    empty_variant: object,
) -> None:
    """Potentially unsafe interaction if user doesn't intend to use data-driven sync so should be disabled.

    Not worth the risk even though a clearly unsafe interaction hasn't been illustrated yet.
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        data_driven_sync=DataDrivenSyncMetadata(
            consumer=DataDrivenSyncConsumerMetadata(),
        ),
    )
    metadata = _make_operator_metadata(design, "107a")
    args = PerformanceOnlyArguments()
    status = metadata.supports(args, target_sm="107a")
    assert not status, f"Expected False, got {status}"


def test_sm107_design_accepts_when_both_pdl_and_data_driven_sync_supported_through_operator_metadata() -> (
    None
):
    """Sm107DesignMetadata accepts when both PDL and data-driven are declared supported.

    Sm107 owns data-driven validation and chains to Sm100 for PDL.  When the design
    declares support for both and the args request both, the combined check passes.
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(early_launch_dependent=True),
        data_driven_sync=DataDrivenSyncMetadata(
            producer=DataDrivenSyncProducerMetadata(minimum_atomic_write_bytes=16)
        ),
    )
    metadata = _make_operator_metadata(design, "107a")

    status = metadata.supports(
        _combined_pdl_and_data_driven_sync_args(), target_sm="107a"
    )

    assert status, f"Expected True, got {status}"


def test_sm107_design_rejects_when_data_driven_sync_disabled_pdl_enabled_through_operator_metadata() -> (
    None
):
    """Sm107DesignMetadata rejects when PDL is supported but data-driven is not.

    The data-driven check is owned by Sm107 itself (not inherited).  Even though PDL
    passes (via Sm100), the data-driven rejection is not masked by PDL acceptance.
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(early_launch_dependent=True),
        data_driven_sync=DataDrivenSyncMetadata(),
    )
    metadata = _make_operator_metadata(design, "107a")

    status = metadata.supports(
        _combined_pdl_and_data_driven_sync_args(), target_sm="107a"
    )

    assert not status, f"Expected False, got {status}"


def test_sm107_design_rejects_when_pdl_disabled_data_driven_sync_enabled_through_operator_metadata() -> (
    None
):
    """Sm107DesignMetadata rejects when data-driven is supported but PDL is not.

    The PDL check is delegated to Sm100.  Even though data-driven passes (Sm107's own
    check), the PDL rejection from Sm100 is not masked by data-driven acceptance.
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(),
        data_driven_sync=DataDrivenSyncMetadata(
            producer=DataDrivenSyncProducerMetadata(minimum_atomic_write_bytes=16)
        ),
    )
    metadata = _make_operator_metadata(design, "107a")

    status = metadata.supports(
        _combined_pdl_and_data_driven_sync_args(), target_sm="107a"
    )

    assert not status, f"Expected False, got {status}"


def test_sm107_design_rejects_when_both_pdl_and_data_driven_sync_disabled_through_operator_metadata() -> (
    None
):
    """Sm107DesignMetadata rejects when neither PDL nor data-driven is supported."""
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        pdl=ProgrammaticDependentLaunchMetadata(),
        data_driven_sync=DataDrivenSyncMetadata(),
    )
    metadata = _make_operator_metadata(design, "107a")

    status = metadata.supports(
        _combined_pdl_and_data_driven_sync_args(), target_sm="107a"
    )

    assert not status, f"Expected False, got {status}"


def test_blas_design_rejects_combined_pdl_and_data_driven_sync_through_operator_metadata() -> (
    None
):
    """BLASDesignMetadata has no PDL/data-driven concept and rejects any non-None performance."""
    design = BLASDesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
    )
    metadata = _make_operator_metadata(design, "80")

    status = metadata.supports(
        _combined_pdl_and_data_driven_sync_args(), target_sm="80"
    )

    assert not status, f"Expected False, got {status}"


@pytest.mark.parametrize(
    ("minimum_atomic_write_bytes", "expected"),
    [(8, False), (16, True)],
)
def test_operator_metadata_supports_forwards_target_sm_to_sm107a_atomic_write_check(
    minimum_atomic_write_bytes: int, expected: bool
) -> None:
    """OperatorMetadata.supports(..., target_sm=...) must reach the sm107a data-driven sync check.

    target_sm in OperatorMetadata.supports() must be
    forwarded through design.supports(args, target_sm=target_sm) down to
    DataDrivenSyncProducerMetadata.supports(), which enforces the sm107a-only
    >=16-byte atomic write requirement. If target_sm were dropped anywhere in
    that chain, an unsafe producer (< 16 bytes) would be incorrectly accepted on
    sm107a.

    Inputs:
        design.data_driven_sync.producer.minimum_atomic_write_bytes = <parametrized: 8, 16>
        target_sm (passed to OperatorMetadata.supports)          = sm107a
    Expected:
        supports -> False when < 16 bytes, True when >= 16 bytes
    """
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        data_driven_sync=DataDrivenSyncMetadata(
            producer=DataDrivenSyncProducerMetadata(
                minimum_atomic_write_bytes=minimum_atomic_write_bytes,
                output_sentinel_prefill=True,
            ),
        ),
    )
    metadata = _make_operator_metadata(design, "107a")
    args = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            data_driven_sync=DataDrivenSyncControls(producer=DataDrivenSyncProducer()),
        ),
    )

    status = metadata.supports(args, target_sm="107a")

    assert bool(status) is expected, f"Expected {expected}, got {status}"


def test_operator_metadata_supports_skips_sm107a_atomic_write_check_without_target_sm() -> (
    None
):
    """Without target_sm, OperatorMetadata.supports() can't enforce arch-specific checks."""
    design = Sm107DesignMetadata(
        mma_instruction_type=RubinTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
        use_2cta_mma=False,
        use_tma_store=False,
        data_driven_sync=DataDrivenSyncMetadata(
            producer=DataDrivenSyncProducerMetadata(minimum_atomic_write_bytes=4),
        ),
    )
    metadata = _make_operator_metadata(design, "107a")
    args = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            data_driven_sync=DataDrivenSyncControls(producer=DataDrivenSyncProducer()),
        ),
    )

    status = metadata.supports(args)

    assert status, f"Expected True, got {status}"

    status_with_target = metadata.supports(args, target_sm="107a")

    assert not status_with_target, f"Expected False, got {status_with_target}"
