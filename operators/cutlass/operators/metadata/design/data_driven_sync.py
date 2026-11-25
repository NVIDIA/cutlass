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

from dataclasses import dataclass
from typing import TYPE_CHECKING, ClassVar

from cutlass.operators.arch import TargetSm
from cutlass.operators.status import Status

if TYPE_CHECKING:
    from cutlass.operators.arguments.data_driven_sync import (
        DataDrivenSyncConsumer,
        DataDrivenSyncControls,
        DataDrivenSyncProducer,
    )


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncMetadata:
    """Describe an operator's data-driven synchronization capabilities.

    Data-driven synchronization allows a consumer operator to read producer-written
    operands before the producer operator has completed and fully computed its output.
    This metadata records whether an operator can produce such data, consume it, or both.

    The primary synchronization mechanism is the use of a sentinel pattern to communicate whether the chunk of data is ready to be read.
    The producer prepares the output tensor with the sentinel pattern before writing the computed results.
    The consumer polls the output tensor chunks and once a chunk has no sentinel pattern, then it is considered valid and can be read.

    The sentinel pattern is defined by the TMA ``report_valid`` load and is typically ``-0.0`` encoded for that data type.
    Scale factors use NaN ``0xff`` as the sentinel pattern.
    Software emulation of data-driven synchronization is not supported at this time.

    Typically used in conjunction with PDL to overlap the producer and consumer launches
    for concurrent reads/writes to the synchronized tensor.

    For the full up-to-date details on validity reporting (``report_valid``):
        https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#report-mechanisms-for-asynchronous-copy-operations
    """

    producer: DataDrivenSyncProducerMetadata | None = None
    """Capabilities for producing data streamed to data-driven sync consumers."""

    consumer: DataDrivenSyncConsumerMetadata | None = None
    """Capabilities for consuming operands streamed by data-driven sync producers."""

    def supports(
        self, perf_controls: DataDrivenSyncControls, target_sm: TargetSm | None = None
    ) -> Status:
        """Check whether the runtime controls are supported on ``target_sm``.

        Unfulfilled requested capabilities are reported in one status.

        Args:
            perf_controls (DataDrivenSyncControls): Runtime producer/consumer
                role requests to validate against this metadata.
            target_sm (TargetSm | None): Target compute capability to
                validate against, if known.

        Returns:
            Status: ``Status.success()`` if every requested role is
            supported, otherwise ``Status.fail(...)`` describing each
            unfulfilled request.
        """
        status = Status.success()
        if self.is_enabled() and not perf_controls.is_enabled():
            status = status.combine(
                Status.fail(
                    "An Operator that uses data-driven synchronization cannot safely support an empty performance controls."
                )
            )

        def producer_str(x) -> str:
            if x is None:
                return "not a data-driven sync producer"
            else:
                return "a data-driven sync producer"

        def consumer_str(x) -> str:
            if x is None:
                return "not a data-driven sync consumer"
            else:
                return "a data-driven sync consumer"

        # Must match to be supported.
        if (perf_controls.producer is not None) != (self.producer is not None):
            status = status.combine(
                Status.fail(
                    f"Operator is '{producer_str(self.producer)}' but requested '{producer_str(perf_controls.producer)}'. Must match."
                )
            )

        # Only call supports() if both are not None.
        if perf_controls.producer is not None and self.producer is not None:
            status = status.combine(
                self.producer.supports(perf_controls.producer, target_sm)
            )

        if (perf_controls.consumer is not None) != (self.consumer is not None):
            status = status.combine(
                Status.fail(
                    f"Operator is '{consumer_str(self.consumer)}' but requested '{consumer_str(perf_controls.consumer)}'. Must match."
                )
            )

        if perf_controls.consumer is not None and self.consumer is not None:
            status = status.combine(
                self.consumer.supports(perf_controls.consumer, target_sm)
            )

        return status

    def is_enabled(self) -> bool:
        """Return whether this operator supports either data-driven synchronization role."""
        return self.producer is not None or self.consumer is not None


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncProducerMetadata:
    """Producer-side data-driven synchronization metadata.

    A data-driven sync producer writes output that consumers may load and compute upon before the
    producer operator completes, using the sentinel pattern to denote data readiness.

    Completed output must never contain a legitimate sentinel pattern, because consumers interpret that
    pattern as unwritten data. As such, operator is responsible with canonicalizing computed output before writes.

    The sentinel pattern is defined as ``-0.0`` for data tensors and ``0xff`` for scale factors on sm107a.
    For other architectures, please refer to PTX documentation.
    """

    SM107A_MINIMUM_ATOMIC_WRITE_BYTES: ClassVar[int] = 16
    """Minimum atomic output write size, in bytes, that sm107a TMA ``report_valid`` consumers require."""

    REPORT_VALID_ATOMIC_WRITE_TARGETS: ClassVar[tuple[TargetSm, ...]] = (
        TargetSm.ensure("107a"),
        TargetSm.ensure("107f"),
    )
    """Targets whose TMA ``report_valid`` consumers require ``SM107A_MINIMUM_ATOMIC_WRITE_BYTES`` writes."""

    minimum_atomic_write_bytes: int = 0
    """Minimum size, in bytes, of an atomic output write. Auxiliary scale factors are excluded from this requirement."""

    output_sentinel_prefill: bool = True
    """Whether the operator prefills the output with the TMA ``report_valid`` sentinel pattern before consumer launch.

    When ``False``, the Operator's caller must initialize the output with the sentinel pattern and
    request that behavior within ``DataDrivenSyncControls``.
    """

    def supports(
        self,
        producer_controls: DataDrivenSyncProducer,
        target_sm: TargetSm | None = None,
    ) -> Status:
        """Check whether the runtime producer controls are supported on ``target_sm``.

        Args:
            producer_controls (DataDrivenSyncProducer): Runtime producer controls
                to validate against this metadata.
            target_sm (TargetSm | None): Target compute capability to
                validate against, if known.

        Returns:
            Status: ``Status.success()`` if the producer controls are
            supported, otherwise ``Status.fail(...)`` describing the reason.
        """
        if (
            target_sm is not None
            and target_sm in self.REPORT_VALID_ATOMIC_WRITE_TARGETS
            and self.minimum_atomic_write_bytes < self.SM107A_MINIMUM_ATOMIC_WRITE_BYTES
        ):
            return Status.fail(
                f"Producer's minimum atomic write for report_valid correctness on sm107a is "
                f"{self.SM107A_MINIMUM_ATOMIC_WRITE_BYTES} bytes. Kernel only atomically "
                f"writes {self.minimum_atomic_write_bytes} bytes."
            )

        if not (
            self.output_sentinel_prefill or producer_controls.assert_user_will_prefill
        ):
            return Status.fail(
                "Producer operator will not initialize output with the sentinel pattern and neither will the user. This would result in incorrect results."
            )

        return Status.success()


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncConsumerMetadata:
    """Consumer-side data-driven synchronization metadata.

    A data-driven sync consumer reads producer-written operands with TMA ``report_valid`` loads.
    A retry warp must reissue TMA ``report_valid`` loads until the data is valid.
    """

    consumed_operands: tuple[str, ...] = ()
    """Operands this operator loads with ``report_valid`` enabled.

    Requested operands must not produce the TMA ``report_valid`` sentinel pattern as a valid output value.
    """

    def supports(
        self, perf_controls: DataDrivenSyncConsumer, target_sm: TargetSm | None = None
    ) -> Status:
        """Check whether the runtime consumer controls request supported operands.

        Args:
            perf_controls (DataDrivenSyncConsumer): Runtime consumer controls to
                validate against this metadata.
            target_sm (TargetSm | None): Unused; kept for signature symmetry
                with the producer and aggregate ``supports`` methods.

        Returns:
            Status: ``Status.success()`` if the requested consumed operand
            set matches exactly, otherwise ``Status.fail(...)`` describing
            the mismatch.
        """
        if set(perf_controls.consumed_operands) != (set(self.consumed_operands)):
            # Must be exact. Cannot be subset because of the requirement that sentinel patterns are reserved and cannot be valid data.
            return Status.fail(
                "Operator must support exactly user-requested consumed operands loaded with report_valid.\n"
                + f"Requested: {set(perf_controls.consumed_operands)}\nSupported: {set(self.consumed_operands)}"
            )

        return Status.success()
