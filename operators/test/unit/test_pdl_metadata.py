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

from dataclasses import dataclass

import pytest
from cuda.bindings import runtime as cuda_runtime

import cutlass

from cutlass.operators.arguments import (
    EarlyLaunchDependent,
    EarlyStart,
    GemmPerformanceControls,
    PDLProgrammaticEvent,
    ProgrammaticDependentLaunchControl,
    RuntimeArguments,
)
from cutlass.operators.config import GlobalOptions
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    EarlyStartMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    ProgrammaticDependentLaunchMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.metadata.design.base import BLASDesignMetadata
from cutlass.operators.mma import BlackwellTcgen05Mma


@dataclass
class PerformanceOnlyArguments(RuntimeArguments):
    """Runtime arguments used to test design metadata without operands."""


def make_design(
    pdl: ProgrammaticDependentLaunchMetadata | None = None,
) -> Sm100DesignMetadata:
    common = {
        "mma_instruction_type": BlackwellTcgen05Mma,
        "tile_shape": (64, 8, 128),
        "cluster_shape": (1, 1, 1),
        "num_smem_stages": 8,
        "use_2cta_mma": False,
        "use_tma_store": False,
    }
    if pdl is None:
        return Sm100DesignMetadata(**common)
    return Sm100DesignMetadata(**common, pdl=pdl)


def enabled_pdl_metadata() -> ProgrammaticDependentLaunchMetadata:
    return ProgrammaticDependentLaunchMetadata(
        early_launch_dependent=True,
        early_start=EarlyStartMetadata(),
    )


def event_pdl_control() -> ProgrammaticDependentLaunchControl:
    return ProgrammaticDependentLaunchControl(
        early_launch_dependent=EarlyLaunchDependent(
            pdl_programmatic_event=PDLProgrammaticEvent(
                programmatic_event=cuda_runtime.cudaEvent_t(1)
            ),
        ),
    )


def combined_pdl_control() -> ProgrammaticDependentLaunchControl:
    return ProgrammaticDependentLaunchControl(
        early_launch_dependent=EarlyLaunchDependent(
            pdl_programmatic_event=PDLProgrammaticEvent(
                programmatic_event=cuda_runtime.cudaEvent_t(1)
            ),
        ),
        early_start=EarlyStart(
            pdl_stream_serialization=True,
        ),
    )


def as_gemm_performance(
    pdl: ProgrammaticDependentLaunchControl | None,
) -> GemmPerformanceControls | None:
    """Compose ``pdl`` into a ``GemmPerformanceControls``, the only way design
    metadata now accepts PDL controls (PDL is no longer usable standalone as
    ``args.performance``)."""
    if pdl is None:
        return None
    return GemmPerformanceControls(pdl=pdl)


def test_early_start_metadata_normalizes_independent_operand_iterable() -> None:
    metadata = EarlyStartMetadata(independent_operands=["A", "B"])

    assert metadata.independent_operands == ("A", "B")


def make_operator_metadata(
    independent_operands: tuple[str, ...],
) -> OperatorMetadata:
    operand = DenseTensorConstraints(
        stride=(0, 0, 1),
        dtype=cutlass.Float16,
        divisibility=16,
    )
    operands = GemmOperandsMetadata(
        A=operand,
        B=operand,
        out=operand,
        accumulator_type=cutlass.Float32,
    )
    design = make_design(
        ProgrammaticDependentLaunchMetadata(
            early_launch_dependent=True,
            early_start=EarlyStartMetadata(
                independent_operands=independent_operands,
            ),
        )
    )
    return OperatorMetadata(
        operator_name="metadata-only-pdl-test",
        operator_class=object,
        supported_targets=[],
        operands=operands,
        design=design,
    )


@pytest.mark.parametrize("independent_operands", [(), ("A",), ("B",), ("A", "B")])
def test_operator_metadata_accepts_declared_pdl_independent_operands(
    independent_operands: tuple[str, ...],
) -> None:
    make_operator_metadata(independent_operands)


@pytest.mark.parametrize("operand", ["accumulator_type", "missing"])
def test_operator_metadata_rejects_undeclared_pdl_independent_operand(
    operand: str,
) -> None:
    with pytest.raises(ValueError, match="Invalid PDL independent_operands"):
        make_operator_metadata((operand,))


def test_operator_metadata_rejects_string_pdl_independent_operands() -> None:
    with pytest.raises(ValueError, match="iterable of operand names"):
        make_operator_metadata("A")  # type: ignore[arg-type]


def test_operator_metadata_rejects_none_pdl_independent_operands() -> None:
    with pytest.raises(ValueError, match="iterable of operand names"):
        make_operator_metadata(None)  # type: ignore[arg-type]


def test_operator_metadata_rejects_non_string_pdl_independent_operand() -> None:
    with pytest.raises(ValueError, match="independent operand names must be strings"):
        make_operator_metadata((1,))  # type: ignore[arg-type]


@pytest.mark.parametrize(
    "performance",
    [None, ProgrammaticDependentLaunchControl()],
)
def test_disabled_pdl_metadata_accepts_inactive_pdl_runtime_controls(
    performance: ProgrammaticDependentLaunchControl | None,
) -> None:
    metadata = ProgrammaticDependentLaunchMetadata()
    direct_status = metadata.supports(performance)
    design_status = make_design().supports(
        PerformanceOnlyArguments(performance=as_gemm_performance(performance))
    )

    assert direct_status
    assert design_status


@pytest.mark.parametrize(
    "performance",
    [
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(pdl_stream_serialization=True)
        ),
        event_pdl_control(),
        combined_pdl_control(),
    ],
)
def test_disabled_pdl_metadata_rejects_active_pdl_runtime_controls(
    performance: ProgrammaticDependentLaunchControl,
) -> None:
    metadata = ProgrammaticDependentLaunchMetadata()
    direct_status = metadata.supports(performance)
    design_status = make_design().supports(
        PerformanceOnlyArguments(performance=as_gemm_performance(performance))
    )

    assert not direct_status
    assert not design_status
    assert "does not support" in str(direct_status.error)
    assert str(design_status.error) == str(direct_status.error)


def test_pdl_metadata_accepts_no_runtime_pdl_controls() -> None:
    metadata = enabled_pdl_metadata()
    direct_status = metadata.supports(None)
    design_status = make_design(metadata).supports(PerformanceOnlyArguments())

    assert direct_status
    assert design_status


@pytest.mark.parametrize(
    "performance",
    [
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(pdl_stream_serialization=True)
        ),
        event_pdl_control(),
        combined_pdl_control(),
    ],
)
def test_pdl_metadata_accepts_supported_runtime_pdl_controls(
    performance: ProgrammaticDependentLaunchControl,
) -> None:
    metadata = enabled_pdl_metadata()
    direct_status = metadata.supports(performance)
    design_status = make_design(metadata).supports(
        PerformanceOnlyArguments(performance=as_gemm_performance(performance))
    )

    assert direct_status
    assert design_status


def test_early_launch_only_metadata_accepts_programmatic_event() -> None:
    metadata = ProgrammaticDependentLaunchMetadata(early_launch_dependent=True)

    assert metadata.supports(event_pdl_control())


def test_early_launch_control_presence_requests_compiled_support() -> None:
    control = ProgrammaticDependentLaunchControl(
        early_launch_dependent=EarlyLaunchDependent()
    )

    assert ProgrammaticDependentLaunchMetadata(early_launch_dependent=True).supports(
        control
    )
    assert not ProgrammaticDependentLaunchMetadata().supports(control)


def test_blas_design_without_pdl_metadata_rejects_pdl_control() -> None:
    design = BLASDesignMetadata(
        mma_instruction_type=BlackwellTcgen05Mma,
        tile_shape=(64, 8, 128),
        cluster_shape=(1, 1, 1),
    )
    args = PerformanceOnlyArguments(
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent()
            )
        )
    )

    assert not design.supports(args)


def test_early_launch_only_metadata_rejects_early_start_same_stream_serialization() -> (
    None
):
    metadata = ProgrammaticDependentLaunchMetadata(early_launch_dependent=True)

    status = metadata.supports(
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(pdl_stream_serialization=True)
        )
    )

    assert not status
    assert "early start" in str(status.error)


def test_early_start_only_metadata_accepts_early_start_same_stream_serialization() -> (
    None
):
    metadata = ProgrammaticDependentLaunchMetadata(early_start=EarlyStartMetadata())

    assert metadata.supports(
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(pdl_stream_serialization=True)
        )
    )


def test_early_start_only_metadata_rejects_early_launch_programmatic_event() -> None:
    metadata = ProgrammaticDependentLaunchMetadata(early_start=EarlyStartMetadata())

    status = metadata.supports(event_pdl_control())

    assert not status
    assert "early launch" in str(status.error)


@pytest.mark.parametrize(
    (
        "compiled_independent_operands",
        "runtime_independent_operands",
        "expected",
    ),
    [
        ((), (), True),
        ((), ("B",), True),
        (("B",), ("B",), True),
        (("B",), ("A", "B"), True),
        (("B",), (), False),
        (("A",), ("B",), False),
    ],
)
def test_pdl_metadata_validates_runtime_independent_operands(
    compiled_independent_operands: tuple[str, ...],
    runtime_independent_operands: tuple[str, ...],
    expected: bool,
) -> None:
    metadata = ProgrammaticDependentLaunchMetadata(
        early_start=EarlyStartMetadata(
            independent_operands=compiled_independent_operands
        )
    )
    performance = ProgrammaticDependentLaunchControl(
        early_start=EarlyStart(
            pdl_stream_serialization=True,
            independent_operands=runtime_independent_operands,
        ),
    )
    direct_status = metadata.supports(performance)
    design_status = make_design(metadata).supports(
        PerformanceOnlyArguments(performance=as_gemm_performance(performance))
    )

    assert bool(direct_status) is expected
    assert bool(design_status) is expected


def test_pdl_metadata_validates_independent_operands_for_event_launch() -> None:
    metadata = ProgrammaticDependentLaunchMetadata(
        early_launch_dependent=True,
        early_start=EarlyStartMetadata(independent_operands=("B",)),
    )

    unsupported = metadata.supports(
        ProgrammaticDependentLaunchControl(
            early_launch_dependent=event_pdl_control().early_launch_dependent,
            early_start=EarlyStart(independent_operands=("A",)),
        )
    )
    supported = metadata.supports(
        ProgrammaticDependentLaunchControl(
            early_launch_dependent=event_pdl_control().early_launch_dependent,
            early_start=EarlyStart(independent_operands=("B",)),
        )
    )

    assert not unsupported
    assert supported


def test_pdl_metadata_validates_independent_operands_without_launch_method() -> None:
    metadata = ProgrammaticDependentLaunchMetadata(
        early_start=EarlyStartMetadata(independent_operands=("B",))
    )

    status = metadata.supports(
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(independent_operands=("A",))
        )
    )

    assert not status



def test_pdl_control_normalizes_independent_operand_iterable() -> None:
    control = EarlyStart(independent_operands=["A", "B"])

    assert control.independent_operands == ("A", "B")


def test_pdl_control_rejects_string_independent_operands() -> None:
    with pytest.raises(ValueError, match="iterable of operand names"):
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(
                independent_operands="A"  # type: ignore[arg-type]
            )
        )


def test_pdl_control_rejects_none_independent_operands() -> None:
    with pytest.raises(ValueError, match="iterable of operand names"):
        EarlyStart(independent_operands=None)  # type: ignore[arg-type]


def test_pdl_control_rejects_non_string_independent_operand() -> None:
    with pytest.raises(ValueError, match="independent operand names must be strings"):
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(
                independent_operands=(1,)  # type: ignore[arg-type]
            )
        )


def test_pdl_control_accepts_stream_serialization_and_programmatic_event() -> None:
    control = combined_pdl_control()

    assert control.early_start is not None
    assert control.early_start.pdl_stream_serialization
    assert control.early_launch_dependent is not None
    assert control.early_launch_dependent.pdl_programmatic_event is not None
