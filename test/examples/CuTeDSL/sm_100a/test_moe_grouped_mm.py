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
Tests for the MoE grouped_mm examples on Blackwell (SM100).

Random routing gives experts of any size, including empty ones. When tokens are
the stride-1 mode of A, B or C, each expert must start on a 16-byte boundary of
that tensor, so these cases check that the examples generate offsets that meet
it, and that the other layouts keep taking any offsets.
"""

import pytest
import torch

from blackwell.kernel.moe import torch_grouped_mm as gmm
from blackwell.kernel.moe import torch_scaled_grouped_mm as sgmm


@pytest.mark.parametrize(
    "scenario, a_layout, b_layout, c_layout",
    [
        ("2Dx3D", "k_major", "n_major", "n_major"),
        ("2Dx3D", "m_major", "n_major", "n_major"),
        ("2Dx3D", "k_major", "n_major", "m_major"),
        ("2Dx2D", "k_major", "n_major", "n_major"),
        ("2Dx2D", "m_major", "k_major", "n_major"),
        ("2Dx2D", "m_major", "n_major", "n_major"),
    ],
)
def test_grouped_mm_random_routing(scenario, a_layout, b_layout, c_layout):
    problem = gmm.ProblemDesc(
        tokens=1000,
        experts=16,
        top_k_select=2,
        balance_route=False,
        hidden=2048,
        intermediate=1536,
        scenario=scenario,
        ab_dtype=torch.bfloat16,
        out_dtype=torch.bfloat16,
        acc_dtype=torch.float32,
        a_layout=a_layout,
        b_layout=b_layout,
        c_layout=c_layout,
    )
    impl = gmm.ImplDesc(
        mma_tiler_mnk=(128, 128, 64),
        cluster_shape_mnk=(1, 1, 1),
        use_2cta_instrs=False,
    )
    gmm.GroupedGemmTester(problem, impl, gmm.MiscDesc()).run()


@pytest.mark.parametrize("scenario", ["2Dx3D", "2Dx2D"])
def test_scaled_grouped_mm_nvfp4_random_routing(scenario):
    problem = sgmm.ProblemDesc(
        tokens=128,
        experts=128,
        top_k_select=8,
        balance_route=False,
        hidden=2048,
        intermediate=7168,
        scenario=scenario,
        kind="nvfp4",
    )
    sgmm.ScaledGroupedGemmTester(problem, sgmm.ImplDesc(), sgmm.MiscDesc()).run()
