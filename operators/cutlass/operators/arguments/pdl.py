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

from collections.abc import Iterable
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import cuda.bindings.driver as cuda_driver
    import cuda.bindings.runtime as cuda_runtime



@dataclass(slots=True)
class ProgrammaticDependentLaunchControl:
    """Controls for Programmatic Dependent Launch (PDL) at runtime.

    PDL allows a dependent kernel to begin executing before its producer has
    completed.
    This class exposes the runtime controls for the PDL launch.
    A launch can use same-stream serialization, a programmatic CUDA event, or
    both.

    For same-stream serialization, the producer and consumer kernels must use
    the same stream. The consumer must enable ``pdl_stream_serialization`` to
    receive the early-launch signal.

    For a programmatic CUDA event, the producer must specify
    ``pdl_programmatic_event`` to signal the consumer.

    - ``early_launch_dependent`` controls when and how the producer signals
      consumer kernels. The signal may use a programmatic CUDA event.
    - ``early_start`` controls how a consumer starts before producer completion.
      It selects same-stream serialization and declares independent operands.

    For more details about PDL launches, see:
        https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/programmatic-dependent-launch.html#use-in-cuda-graphs

    Leave both controls as ``None`` to disable PDL behavior.
    """

    early_launch_dependent: EarlyLaunchDependent | None = None
    """Optional runtime controls for launching dependent work early."""

    early_start: EarlyStart | None = None
    """Optional runtime controls for starting before producer completion."""

    def is_enabled(self) -> bool:
        """Whether controls describe any PDL support."""
        return self.early_launch_dependent is not None or self.early_start is not None


@dataclass(frozen=True, slots=True)
class EarlyLaunchDependent:
    """Runtime controls for launching dependent work early."""

    pdl_programmatic_event: PDLProgrammaticEvent | None = None
    """Optional programmatic CUDA event to signal from this launch."""


@dataclass(frozen=True, slots=True)
class EarlyStart:
    """Runtime controls for starting before producer completion."""

    pdl_stream_serialization: bool = False
    """Whether to use same-stream serialization for this PDL launch.
    """

    independent_operands: Iterable[str] = ()
    """Operands that are independent of the producer for this launch.

    All input operands are dependent by default.

    Declaring independent operands allows the consumer kernel to load them
    without waiting for the producer to complete, which may improve performance.

    ``griddepcontrol_wait`` guards dependent operands but not independent
    operands. Incorrectly declaring a dependent operand as independent may cause
    a race condition.

    The runtime verifies that the selected kernel's compiled early-start
    behavior supports this declaration. An empty list means that all operands
    depend on the producer.
    """

    def __post_init__(self) -> None:
        if isinstance(self.independent_operands, str) or not isinstance(
            self.independent_operands, Iterable
        ):
            raise ValueError(
                "PDL independent_operands must be an iterable of operand names, "
                "not a string"
            )

        independent_operands = tuple(self.independent_operands)
        if any(not isinstance(name, str) for name in independent_operands):
            raise ValueError("PDL independent operand names must be strings")
        object.__setattr__(self, "independent_operands", independent_operands)


@dataclass(frozen=True, slots=True)
class PDLProgrammaticEvent:
    """Programmatic CUDA event launch attributes for PDL."""

    programmatic_event: cuda_driver.CUevent | cuda_runtime.cudaEvent_t
    """CUDA event to signal the dependent kernel."""

    programmatic_event_flags: int = 0
    """Optional event-record flags.

    See https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__EVENT.html.
    """

    programmatic_event_trigger_at_block_start: bool = False
    """Whether to trigger the programmatic event automatically at block start.

    ``True`` triggers the event automatically at block start.
    ``False`` requires the kernel to trigger the event manually.

    This affects the constructed graph edge. See
    https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/programmatic-dependent-launch.html.
    """
