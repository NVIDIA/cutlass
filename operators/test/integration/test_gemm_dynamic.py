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

import logging
from pprint import pformat

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.metadata.design.tile_scheduler import (
    CLCDynamicPersistentTileSchedulerMetadata,
    StaticPersistentTileSchedulerMetadata,
)
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)

from test_utils import assert_close_with_reference_conversion

torch.manual_seed(2025)
logger = logging.getLogger(__name__)


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 512, 1024, 1),
        (256, 512, 64, 1),
        (256, 512, 64, 2),
    ],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Currently requires compiling for an arch in sm_100f family",
)
def test_gemm_persistent_tile_schedulers(
    M: int,
    N: int,
    K: int,
    L: int,
    fixture_toggle_tvm_ffi,
):
    """Test static and CLC persistent tile schedulers for dense GEMM."""
    ab_dtype = torch.float16
    c_dtype = torch.float16
    accumulator_type = torch.float32
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    reference = A @ B

    args = ops.GemmArguments(A, B, D, accumulator_type)

    def clc_dynamic_persistent_filter(metadata):
        scheduler = getattr(metadata.design, "tile_scheduler", None)
        if scheduler and isinstance(
            scheduler, CLCDynamicPersistentTileSchedulerMetadata
        ):
            return True
        return False

    def static_persistent_filter(metadata):
        scheduler = getattr(metadata.design, "tile_scheduler", None)
        if scheduler and isinstance(scheduler, StaticPersistentTileSchedulerMetadata):
            return True
        return False

    # Test one CLC-based tile scheduler kernel
    operators = ops.get_operators(
        args,
        metadata_filter=clc_dynamic_persistent_filter,
        target_sm=device_or_env_target_sm(),
    )
    assert len(operators) > 0

    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")

    operator.run(args)
    assert_close_with_reference_conversion(D, reference, D.dtype)

    # Reinitialize output tensor to ensure independent validation
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
    args = ops.GemmArguments(A, B, D, accumulator_type)

    operators = ops.get_operators(
        args,
        metadata_filter=static_persistent_filter,
        target_sm=device_or_env_target_sm(),
    )

    assert len(operators) > 0
    operator = operators[0]

    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")

    operator.run(args)
    assert_close_with_reference_conversion(D, reference, D.dtype)
