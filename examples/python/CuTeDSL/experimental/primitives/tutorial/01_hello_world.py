# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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

"""Hello World — minimal @cute.kernel / @cute.jit entry point.

Simplest possible cutlass DSL program: launches a 4-thread kernel, filters
by thread index, and prints from the device.  Start here to verify your
cutlass install and understand the two-decorator pattern (``@cute.kernel``
for device code, ``@cute.jit`` for host launch).
"""

import cutlass
import cutlass.cute as cute


@cute.kernel
def hello_world(meta_arg: cutlass.Constexpr, dynamic_arg: cutlass.Int32):
    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 1 or tidx == 3:
        cute.printf(
            "PASS tidx={} meta_arg={} dynamic_arg={}", tidx, meta_arg, dynamic_arg
        )


@cute.jit
def hello_world_host(meta_arg: cutlass.Constexpr, dynamic_arg: cutlass.Int32):
    hello_world(meta_arg, dynamic_arg).launch(grid=(1, 1, 1), block=(4, 1, 1))


# Step 1. Initialize CUDA context
cutlass.cuda.initialize_cuda_context()

# Step 2. Run the kernel
hello_world_host(10, 20)

# Expected output:
# PASS tidx=1 meta_arg=10 dynamic_arg=20
# PASS tidx=3 meta_arg=10 dynamic_arg=20
