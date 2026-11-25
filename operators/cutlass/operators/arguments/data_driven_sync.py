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


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncControls:
    """Runtime controls for data-driven producer-consumer synchronization.

    Data-driven synchronization allows a consumer operator to read the producer's
    outputs before the producer operator has completed. The controls may request a
    producer role, a consumer role, or both.

    Using data-driven synchronization requires additional launch configuration by the user.
    See the data-driven synchronization example notebook for more details.

    Typically paired with Programmatic Dependent Launch (PDL) to overlap
    the producer and consumer launches for concurrent reads/writes to the synchronized tensor.

    Specifying ``None`` means role is not implemented.
    """

    producer: DataDrivenSyncProducer | None = None
    """Optional controls for a launch that produces data consumers load with ``report_valid``."""

    consumer: DataDrivenSyncConsumer | None = None
    """Optional controls for a launch that consumes producer output with ``report_valid`` loads."""

    def is_enabled(self) -> bool:
        """Return whether either data-driven synchronization role is requested."""
        return self.producer is not None or self.consumer is not None


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncProducer:
    """Runtime controls for a data-driven sync producer.

    A data-driven sync producer writes data that a consumer may read before the
    producer operator completes. The producer output must use the TMA ``report_valid``
    sentinel pattern for unwritten data and must never produce a legitimate ``-0.0`` (``NaN`` for scale factors) in
    completed output.
    """

    assert_user_will_prefill: bool = False
    """Whether the user assumes responsibility for prefilling the output with the sentinel pattern.

    When ``True``, the operator's caller must fill its
    output with the sentinel pattern before launching dependent consumers. The producer will not perform the fill.

    When ``False``, the producer operator will initialize the output with the sentinel pattern.
    The user does not need to prefill the output.
    """


@dataclass(kw_only=True, slots=True)
class DataDrivenSyncConsumer:
    """Runtime controls for a data-driven sync consumer."""

    consumed_operands: tuple[str, ...] = ()
    """Operands that user wants consumer to load with ``report_valid`` enabled from a producer.

    Any operand in this list cannot contain the sentinel pattern as a legitimate computed value.

    Example: GemmArguments(A, B, out) -> consumed_operands=("B",)
    """
