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

"""
RMSNorm on Blackwell (SM100) for tensors with more than 2**31 elements.

The tile of block bidx starts bidx * rows_per_block * N elements into x and
out. These cases put the last tile at 2**31 or 2**32 elements, where a 32-bit
offset faults or wraps. They need tens of GiB of device memory, so they are
large cases: run them with --only-large-case.
"""

import pytest
import torch

import cutlass

from blackwell.kernel.rmsnorm.rmsnorm import run


@pytest.mark.large_case
@pytest.mark.parametrize(
    "M, N",
    [
        (262145, 8192),  # 1 row per CTA, last tile at 2**31 elements
        (131073, 16384),  # 1 row per CTA, last tile at 2**31 elements
        (1048577, 4096),  # 2 rows per CTA, last tile at 2**32 elements
        (2097153, 2048),  # 4 rows per CTA, last tile at 2**32 elements
        (131073, 32768),  # 2-CTA cluster, last tile at 2**32 elements
    ],
)
def test_rmsnorm_past_int32_offsets(M, N):
    # x, out and the float32 reference in rmsnorm_ref peak near 16 bytes per
    # BFloat16 element.
    needed_bytes = 17 * M * N
    free_bytes, _ = torch.cuda.mem_get_info()
    if free_bytes < needed_bytes:
        pytest.skip(f"needs {needed_bytes / 2**30:.0f} GiB of free device memory")
    run(M=M, N=N, dtype=cutlass.BFloat16, has_weight=True, benchmark=False)
