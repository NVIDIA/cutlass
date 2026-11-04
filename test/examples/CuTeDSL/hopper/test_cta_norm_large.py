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


"""CTA norm heuristic coverage around and above the 1024-thread limit."""

import pytest
import cutlass
from hopper.kernel.cta_norm.cta_norm import CtaNorm, run_layernorm


@pytest.mark.parametrize(
    "N, expected", [(1024, 64), (32768, 1024), (33544, 1024), (65536, 1024)]
)
def test_heuristic_never_exceeds_block_limit(N, expected):
    assert CtaNorm(N, "rms").threads_per_cta == expected


@pytest.mark.parametrize("norm_type", ["rms", "layer"])
@pytest.mark.parametrize("N", [33544, 65536])
@pytest.mark.parametrize("dtype", [cutlass.Float16, cutlass.Float32])
def test_large_hidden_size_auto_threads(N, norm_type, dtype):
    run_layernorm(
        M=2,
        N=N,
        threads_per_cta=None,
        norm_type=norm_type,
        dtype=dtype,
        benchmark=False,
    )


def test_explicit_thread_override_is_preserved():
    assert CtaNorm(65536, "rms", threads_per_cta=128).threads_per_cta == 128
