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

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments.data_driven_sync import (
    DataDrivenSyncConsumer,
    DataDrivenSyncControls,
    DataDrivenSyncProducer,
)
from cutlass.operators.metadata.design.data_driven_sync import (
    DataDrivenSyncConsumerMetadata,
    DataDrivenSyncMetadata,
    DataDrivenSyncProducerMetadata,
)

# ---------------------------------------------------------------------------
# DataDrivenSyncMetadata Api tests
# ---------------------------------------------------------------------------


def test_data_driven_sync_metadata_default_is_not_enabled():
    """is_enabled returns False when neither producer nor consumer is enabled."""
    metadata = DataDrivenSyncMetadata()
    assert metadata.producer is None
    assert metadata.consumer is None
    assert not metadata.is_enabled()


def test_data_driven_sync_metadata_producer_only_is_enabled():
    """is_enabled returns True when only the producer role is supported."""
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(),
        consumer=None,
    )
    assert metadata.is_enabled()


def test_data_driven_sync_metadata_consumer_only_is_enabled():
    """is_enabled returns True when only the consumer role is supported."""
    metadata = DataDrivenSyncMetadata(
        producer=None,
        consumer=DataDrivenSyncConsumerMetadata(),
    )
    assert metadata.is_enabled()


def test_data_driven_sync_metadata_producer_and_consumer_is_enabled():
    """is_enabled returns True when both roles are supported."""
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(),
        consumer=DataDrivenSyncConsumerMetadata(),
    )
    assert metadata.is_enabled()


# Won't trigger any arch-specific checks for data-driven Sync.
_ANY_SM = TargetSm("80")


# ---------------------------------------------------------------------------
# Producer tests
# ---------------------------------------------------------------------------

# Test cases:
# Controls | Metadata | Target SM | supports Return
# -------- | -------- | ---------   ---------------
# producer.assert_user_will_prefill == False | producer.output_sentinel_prefill == False | Any | False
# producer.assert_user_will_prefill == True | producer.output_sentinel_prefill == False | Any | True
# producer.assert_user_will_prefill == True/False | producer.output_sentinel_prefill == True | Any | True
# Any | producer.minimum_atomic_write_bytes < 16  | sm107a | False
# Any | producer.minimum_atomic_write_bytes >= 16 | sm107a | True

def test_producer_no_prefill_fails():
    """Supports returns False when neither metadata nor user guarantees the sentinel prefill.

    The producer output must be initialized with the sentinel pattern before a consumer
    launches. If the metadata says the operator will not prefill (``output_sentinel_prefill=False``)
    and the user also does not assert they will prefill (``assert_user_will_prefill=False``),
    the sentinel is never written, causing incorrect consumer reads.

    Inputs:
        controls.producer.assert_user_will_prefill = False
        metadata.producer.output_sentinel_prefill  = False
        target_sm                                  = _ANY_SM (sm80, architecture-neutral)
    Expected:
        supports → False
    """
    controls = DataDrivenSyncControls(
        producer=DataDrivenSyncProducer(assert_user_will_prefill=False),
        consumer=None,
    )
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(output_sentinel_prefill=False),
        consumer=None,
    )

    status = metadata.supports(controls, _ANY_SM)

    assert not status, f"Expected False, got {status}"


def test_user_prefills_succeeds():
    """Supports returns True when user will prefill but operator won't.

    Inputs:
        controls.producer.assert_user_will_prefill = True
        metadata.producer.output_sentinel_prefill  = False
        target_sm                                  = _ANY_SM (sm80, architecture-neutral)
    Expected:
        supports → True
    """
    controls = DataDrivenSyncControls(
        producer=DataDrivenSyncProducer(assert_user_will_prefill=True),
        consumer=None,
    )
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(output_sentinel_prefill=False),
        consumer=None,
    )

    status = metadata.supports(controls, _ANY_SM)

    assert status, f"Expected True, got {status}"


@pytest.mark.parametrize("assert_user_will_prefill", [False, True])
def test_producer_metadata_prefills_succeeds(assert_user_will_prefill: bool):
    """Supports returns True when the operator metadata guarantees the sentinel prefill.

    When ``output_sentinel_prefill=True`` the operator itself writes the sentinel, so the
    consumer is always guaranteed to see it regardless of whether the user also claimed
    responsibility (``assert_user_will_prefill`` can be True or False).

    Inputs:
        controls.producer.assert_user_will_prefill = <parametrized: False, True>
        metadata.producer.output_sentinel_prefill  = True
        target_sm                                  = _ANY_SM (sm80, architecture-neutral)
    Expected:
        supports → True
    """
    controls = DataDrivenSyncControls(
        producer=DataDrivenSyncProducer(
            assert_user_will_prefill=assert_user_will_prefill
        ),
        consumer=None,
    )
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(output_sentinel_prefill=True),
        consumer=None,
    )

    status = metadata.supports(controls, _ANY_SM)

    assert status, f"Expected True, got {status}"


def test_producer_sm107a_small_atomic_write_fails():
    """Supports returns False when the atomic write size is below 16 bytes on sm107a.

    SM107a TMA report_valid consumers require at least 16-byte atomic writes so that a
    consumer load sees a fully-written value and not a partial sentinel mix.  A kernel
    that only atomically writes, e.g., 8 bytes would violate this and produce incorrect
    results on sm107a.

    Inputs:
        controls.producer.assert_user_will_prefill        = False  (irrelevant; atomic check fires first)
        metadata.producer.output_sentinel_prefill         = True   (irrelevant; atomic check fires first)
        metadata.producer.minimum_atomic_write_bytes      = 8      (< 16)
        target_sm                                         = sm107a
    Expected:
        supports → False
    """
    controls = DataDrivenSyncControls(
        producer=DataDrivenSyncProducer(assert_user_will_prefill=False),
        consumer=None,
    )
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(
            minimum_atomic_write_bytes=8,
            output_sentinel_prefill=True,
        ),
        consumer=None,
    )

    status = metadata.supports(controls, TargetSm("107a"))

    assert not status, f"Expected False, got {status}"


def test_producer_sm107a_sufficient_atomic_write_succeeds():
    """Supports returns True when the atomic write size meets the 16-byte sm107a requirement.

    Inputs:
        controls.producer.assert_user_will_prefill        = False
        metadata.producer.output_sentinel_prefill         = True
        metadata.producer.minimum_atomic_write_bytes      = 16     (>= 16)
        target_sm                                         = sm107a
    Expected:
        supports → True
    """
    controls = DataDrivenSyncControls(
        producer=DataDrivenSyncProducer(assert_user_will_prefill=False),
        consumer=None,
    )
    metadata = DataDrivenSyncMetadata(
        producer=DataDrivenSyncProducerMetadata(
            minimum_atomic_write_bytes=16,
            output_sentinel_prefill=True,
        ),
        consumer=None,
    )

    status = metadata.supports(controls, TargetSm("107a"))

    assert status, f"Expected True, got {status}"


# ---------------------------------------------------------------------------
# Consumer tests
# ---------------------------------------------------------------------------

# Test cases:
# Controls | Metadata | Target SM | supports Return
# -------- | -------- | ---------   ---------------
# consumer.consumed_operands == X | consumer.consumed_operands == X | Any | True
# consumer.consumed_operands == X | consumer.consumed_operands == Y | Any | False


def test_consumer_matching_consumed_operands_succeeds():
    """Supports returns True when the requested report_valid operands exactly match the metadata.

    The consumer operator loads exactly the operands listed in its metadata with report_valid
    enabled.  Requesting the same set means the operator can satisfy the user's requirement.

    Inputs:
        controls.consumer.consumed_operands  = ("A",)
        metadata.consumer.consumed_operands  = ("A",)
        target_sm                            = _ANY_SM (sm80, architecture-neutral)
    Expected:
        supports → True
    """
    controls = DataDrivenSyncControls(
        producer=None,
        consumer=DataDrivenSyncConsumer(consumed_operands=("A",)),
    )
    metadata = DataDrivenSyncMetadata(
        producer=None,
        consumer=DataDrivenSyncConsumerMetadata(consumed_operands=("A",)),
    )

    status = metadata.supports(controls, _ANY_SM)

    assert status, f"Expected True, got {status}"


def test_consumer_mismatched_consumed_operands_fails():
    """Supports returns False when the requested report_valid operands differ from the metadata.

    The report_valid operand set must be an exact match: the sentinel pattern is reserved for
    communication and must never appear as a valid computed value in those operands.
    Allowing a mismatch would either skip the report_valid on a required operand (incorrect
    reads) or apply it to an operand that can legitimately produce the sentinel pattern
    (spurious stalls or data corruption).

    Inputs:
        controls.consumer.consumed_operands  = ("A",)
        metadata.consumer.consumed_operands  = ("B",)
        target_sm                            = _ANY_SM (sm80, architecture-neutral)
    Expected:
        supports → False
    """
    controls = DataDrivenSyncControls(
        producer=None,
        consumer=DataDrivenSyncConsumer(consumed_operands=("A",)),
    )
    metadata = DataDrivenSyncMetadata(
        producer=None,
        consumer=DataDrivenSyncConsumerMetadata(consumed_operands=("B",)),
    )

    status = metadata.supports(controls, _ANY_SM)

    assert not status, f"Expected False, got {status}"
