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

"""Run me to see a REMARK render:

    python show_remark.py

The kernel loads 64 values per thread and stores them reversed; compiled with
--ptxas-options '--maxrregcount=16' this forces ptxas to spill registers.
Register spills are perf-only -- the program is functionally CORRECT, just
slower -- so they are an opt-in REMARK. remarks{ptx} shows it; compile
SUCCEEDS:

    remark[ptxas]: ptxas detected register spills

Re-run with options="warnings{nvvm}" and the remark will NOT show (remarks are
gated to remarks{...}).
"""

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims

_N = 64  # values per thread -- enough to spill under maxrregcount=16


@cute.kernel
def reverse_store_spill_kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    tidx, _, _ = cute.arch.thread_idx()
    base = tidx * cutlass.Int32(_N)

    values = (
        (src.iterator.raw_ptr() + base)
        .load(count=_N, alignment=_N * cutlass.Int32.bytes)
        .to_elements()
    )

    prims.barrier_cta_sync(0)

    # Reversed store keeps all _N values live at once -> register pressure.
    for i in cutlass.range_constexpr(_N):
        (dst.iterator.raw_ptr() + base + cutlass.Int32(i)).store(values[_N - 1 - i])


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor, stream) -> None:  # noqa: ANN001
    reverse_store_spill_kernel(src, dst).launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def main() -> int:
    n = _N * 32
    src = make_fake_compact_tensor(cutlass.Int32, (n,), assumed_align=16)
    dst = make_fake_compact_tensor(cutlass.Int32, (n,), assumed_align=16)
    print(">>> cute.compile(host, options='remarks{ptx} --ptxas-options ...')\n")
    cute.compile(
        host,
        src,
        dst,
        make_fake_stream(),
        options="remarks{ptx} "
        "--ptxas-options '--maxrregcount=24 --override-directive-values'",
    )
    print(
        "\n>>> compile finished -- see remark[ptxas]: ptxas detected register spills above"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
