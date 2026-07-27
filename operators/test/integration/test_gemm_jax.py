# Copyright (c) 2026 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import jax
import jax.numpy as jnp
import pytest

import cutlass

import cutlass.operators as ops
from cutlass.operators.utils.device import device_or_env_target_sm

from test_utils import assert_close_with_reference_conversion

# The test exercises the JAX-to-GPU operator path, which requires a GPU backend.
pytestmark = pytest.mark.skipif(
    not any(d.platform == "gpu" for d in jax.devices()),
    reason="JAX has no GPU device available",
)

logger = logging.getLogger(__name__)


@pytest.mark.parametrize("M, N, K", [(256, 512, 128)])
def test_gemm_jax(M, N, K, fixture_toggle_tvm_ffi):
    key = jax.random.PRNGKey(2025)
    k1, k2 = jax.random.split(key)

    A = jax.random.normal(k1, (1, M, K), dtype=jnp.float16)
    B = jax.random.normal(k2, (1, K, N), dtype=jnp.float16)
    D = jnp.zeros((1, M, N), dtype=jnp.float16)

    args = ops.GemmArguments(A, B, D, accumulator_type=cutlass.Float32)
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")
    operator.run(args)

    reference = jnp.matmul(A, B)
    assert_close_with_reference_conversion(
        D, reference, cutlass.Float16, rtols=1e-2, atols=1e-2
    )
