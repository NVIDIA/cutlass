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

from __future__ import annotations

import os
import random
from collections import defaultdict
from typing import TYPE_CHECKING

import pytest

import cutlass.operators as ops
from cutlass.operators.utils.device import device_or_env_target_sm

if TYPE_CHECKING:
    from collections.abc import Callable, Iterable

# Environment variable used to propagate the test level ("L0" / "L1" / "L2")
# to helpers invoked during test collection
_TEST_LEVEL_ENV_VAR = "CUTLASS_OPERATORS_TEST_LEVEL"


def get_test_level() -> str:
    """Return the test level set via ``CUTLASS_OPERATORS_TEST_LEVEL`` (defaults to ``"L0"``)."""
    return os.environ.get(_TEST_LEVEL_ENV_VAR, "L0")


def skip_if_unsupported_target(operator_targets: Iterable[ops.TargetSm | str]) -> None:
    """
    Skips the test if the current device or CUTE_DSL_ARCH does not support the requested Operator targets.

    :param operator_targets: Set of Operator targets to check compatibility for
    :type operator_targets: Iterable[TargetSm | str]
    """
    operator_targets = {ops.TargetSm.ensure(sm) for sm in operator_targets}

    device_sm = device_or_env_target_sm()
    if not device_sm.supports_operators_from(operator_targets):
        pytest.skip(
            f"Current device {device_sm} does not support requested Operator targets {operator_targets}"
        )



def _operators_for_class(
    operator_class: type[ops.Operator],
    extra_filter: Callable | None = None,
    seed: int | None = None,
    test_level: str | None = None,
    num_sample: int | None = None,
) -> list[ops.Operator]:
    """
    Returns a list of operators to test of type `operator_class`.

    For L2 tests, the full set of possible operators are returned.

    For L0 or L1 tests, a random sample of operators are returned. The sample is chosen so that there
    is at least one operator for every unique operands metadata and for every unique design metadata.
    L0 and L1 use distinct default seeds so that their sampled operator sets differ,
    maximising combined coverage when both levels are run.

    :param operator_class: The class of Operator to test
    :type operator_class: type[cutlass.operators.Operator]
    :param extra_filter: An extra filter function to apply to the metadata filter
    :type extra_filter: Callable | None
    :param seed: Override for the RNG seed.  When ``None``, the level-specific
        default (``L0=2025``, ``L1=2026``) is used.
    :type seed: int | None
    :param num_sample: Override for the per-group sample count at L0/L1.  When
        ``None``, the level-specific default (``L0=1``, ``L1=3``) is used.
    :type num_sample: int | None

    :return: A list of operators to test
    :rtype: list[cutlass.operators.Operator]
    """
    if extra_filter is None:

        def extra_filter(x):
            return True

    def metadata_filter(metadata):
        return metadata.operator_class is operator_class and extra_filter(metadata)

    operators = ops.get_operators(
        args=None,
        metadata_filter=metadata_filter,
    )

    if len(operators) == 0:
        raise ValueError(f"No operators found for Operator class {operator_class}")

    if test_level is None:
        # Read the test level from the ``CUTLASS_OPERATORS_TEST_LEVEL`` env
        # var (defaults to ``"L0"`` when unset).
        test_level = os.environ.get("CUTLASS_OPERATORS_TEST_LEVEL", "L0")

    valid_test_levels = ["L0", "L1", "L2"]
    if test_level not in valid_test_levels:
        raise ValueError(
            f"Invalid test level: {test_level}. Must be one of {valid_test_levels}."
        )

    if test_level == "L2":
        return operators

    # Seed the RNG with a level-specific default when the caller didn't
    # override, so L0 and L1 explore disjoint regions of the Operator space.
    seed = {"L0": 2025, "L1": 2026}[test_level] if seed is None else seed
    random.seed(seed)

    # L0 / L1 tests. Group operators by OperandsMetadata and DesignMetadata
    # so that we can sample from distinct categories
    operators_by_operands: defaultdict[str, list] = defaultdict(list)
    operators_by_design: defaultdict[str, list] = defaultdict(list)
    for operator in operators:
        operators_by_operands[str(operator.metadata.operands)].append(operator)
        operators_by_design[str(operator.metadata.design)].append(operator)

    # Sample operators from each unique operand metadata.  Caller-supplied
    # ``num_sample`` wins; otherwise fall back to the per-level default.
    num_sample = {"L0": 1, "L1": 3}[test_level] if num_sample is None else num_sample
    sampled_operators = []
    for operand_operators in operators_by_operands.values():
        sampled_operators.extend(
            random.sample(operand_operators, min(num_sample, len(operand_operators)))
        )

    # Sample operators from each unique design metadata. First remove design metadata that
    # has already been covered by operators previously sampled
    designs_already_sampled = {
        str(operator.metadata.design) for operator in sampled_operators
    }
    for design in designs_already_sampled:
        assert design in operators_by_design
        del operators_by_design[design]

    for design_operators in operators_by_design.values():
        sampled_operators.extend(
            random.sample(design_operators, min(num_sample, len(design_operators)))
        )

    return sampled_operators


def operators_for_classes(
    operator_classes: Iterable[type[ops.Operator]],
    extra_filters: dict[type[ops.Operator], Callable] | None = None,
    seed: int | None = None,
    test_level: str | None = None,
    num_sample: int | None = None,
) -> list[ops.Operator]:
    """
    Takes a list of Operator classes and returns instances of those classes with sufficient
    test coverage for the given test level.

    :param operator_classes: A list of Operator classes to test
    :type operator_classes: Iterable[type[cutlass.operators.Operator]]
    :param extra_filters: A dictionary of extra filter functions for each Operator class
    :type extra_filters: dict[type[cutlass.operators.Operator], Callable] | None
    :param seed: Override for the RNG seed.  When ``None``, a level-specific default is used
        (L0 and L1 use distinct seeds to cover disjoint Operator subsets).
    :type seed: int | None
    :param test_level: The test level ("L0", "L1", "L2")
    :type test_level: str
    :param num_sample: Override for the per-group sample count at L0/L1.  When
        ``None``, the level-specific default (``L0=1``, ``L1=3``) is used.
    :type num_sample: int | None

    :return: A list of operators to test
    :rtype: list[cutlass.operators.Operator]
    """
    if extra_filters is None:
        extra_filters = {}

    operators = [
        operator
        for operator_class in operator_classes
        for operator in _operators_for_class(
            operator_class,
            extra_filters.get(operator_class),
            seed,
            test_level,
            num_sample,
        )
    ]

    operators.sort(key=lambda x: x.metadata.operator_name)
    return operators
