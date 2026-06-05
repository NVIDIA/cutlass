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

from dataclasses import dataclass

import pytest
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@dataclass
class A:
    pass


@dataclass
class B:
    pass


@cute.kernel
def _test_empty_dataclass_kernel(out: cute.Tensor, tag: A | B):
    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 0:
        match tag:
            case A():
                out[0] = 0
            case B():
                out[0] = 1


@cute.jit
def _test_empty_dataclass_host(out: cute.Tensor, tag: A | B):
    _test_empty_dataclass_kernel(out, tag).launch(grid=[1, 1, 1], block=[1, 1, 1])


@pytest.mark.parametrize("tag,expected", [(A(), 0), (B(), 1)])
def test_empty_dataclass_union(tag, expected):
    out = torch.zeros(1, device="cuda", dtype=torch.int32)
    out_cute = from_dlpack(out).mark_layout_dynamic()
    compiled_fn = cute.compile(_test_empty_dataclass_host, out_cute, tag)
    compiled_fn(out_cute, tag)
    torch.cuda.synchronize()
    assert out.item() == expected
