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

"""Operation-independent profiling results."""

from dataclasses import dataclass
from enum import Enum
from typing import TYPE_CHECKING, Protocol

from cutlass.operators.providers import Provider, available_providers

if TYPE_CHECKING:
    from cutlass.profiler.analysis import VerificationResult
    from cutlass.profiler.operations.desc import ProblemDesc


class ProfileMetrics(Protocol):
    """Metrics exposed by every profiling result.

    Throughput and arithmetic intensity are optional because not every
    operation has a meaningful FLOP count.
    """

    @property
    def operator_runtime_ms(self) -> float:
        """Return the average operator execution time in milliseconds."""
        ...

    @property
    def total_bytes(self) -> int:
        """Return the total number of bytes transferred."""
        ...

    @property
    def tflop_per_sec(self) -> float | None:
        """Return compute throughput when the operation defines FLOPs."""
        ...

    @property
    def flop_per_byte(self) -> float | None:
        """Return arithmetic intensity when the operation defines FLOPs."""
        ...


class ProfileStatus(str, Enum):
    """Outcome of one profiler invocation."""

    SUCCESS = "Success"
    FAIL = "Failed"
    TIMEOUT = "Timeout"
    NOT_SUPPORTED = "NotSupported"

    def __str__(self) -> str:
        """Return the serialized status spelling."""
        return self.value


def get_provider_name(provider: type[Provider]) -> str:
    """Return the registered command-line name of a provider type."""
    for name, provider_type in available_providers.items():
        if provider_type is provider:
            return name
    raise ValueError(f"Provider {provider.__name__} is not registered")


@dataclass
class ProfileResult:
    """Common result data produced by any operation profiler."""

    operator_name: str
    provider: type[Provider]
    operation_kind: str
    problem_id: int
    status: ProfileStatus
    metrics: ProfileMetrics
    cmd: str
    test_time_elapsed_ms: float
    problem: "ProblemDesc | None" = None
    verification: "VerificationResult | None" = None

    @classmethod
    def parse(
        cls,
        *,
        operator_name: str,
        provider: str,
        operation_kind: str,
        problem_id: int,
        status: str,
        metrics: ProfileMetrics,
        cmd: str,
        test_time_elapsed_ms: float,
        problem: "ProblemDesc | None" = None,
        verification: "VerificationResult | None" = None,
    ) -> "ProfileResult":
        """Create a typed result from serialized or command-line spellings."""
        try:
            provider_type = available_providers[provider]
        except KeyError as err:
            raise ValueError(f"Unknown provider: {provider}") from err
        try:
            profile_status = ProfileStatus(status)
        except ValueError as err:
            valid_statuses = [item.value for item in ProfileStatus]
            raise ValueError(
                f"Unknown profile status: {status}. Supported: {valid_statuses}"
            ) from err
        return cls(
            operator_name=operator_name,
            provider=provider_type,
            operation_kind=operation_kind,
            problem_id=problem_id,
            status=profile_status,
            metrics=metrics,
            cmd=cmd,
            test_time_elapsed_ms=test_time_elapsed_ms,
            problem=problem,
            verification=verification,
        )

    @property
    def provider_name(self) -> str:
        """Return the registered command-line name for this result's provider."""
        return get_provider_name(self.provider)
