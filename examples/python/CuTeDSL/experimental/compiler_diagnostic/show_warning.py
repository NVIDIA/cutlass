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

"""Run me to see a WARNING render:

    python show_warning.py

The kernel guards a uniform bulk-copy with a full-mask elect.sync, but launches
with a PARTIAL warp (block=4): the trailing partial warp may hang/fault. That is
legal-but-questionable, so it is a WARNING -- non-fatal, compilation SUCCEEDS:

    warning[nvvm-diag:C13]: full-mask elect.sync guards ... partial-warp launch

Needs an sm90+ target (cp.async.bulk). Re-run with options="remarks{ptx}" and
the warning will NOT show (warnings are gated to warnings{...}).
"""

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_stream
from cutlass.experimental import primitives as prims


@cute.kernel
def partial_warp_bulk_copy_kernel(gmem: cutlass.Array) -> None:
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)
    smem_dst = cutlass.Array(
        cutlass.Int32, 4, space=cutlass.AddressSpace.smem, alignment=16
    )

    # full-mask elect.sync around a uniform single-issuer bulk copy
    if prims.elect_sync():
        prims.cp_async_bulk_shared_cluster_global(smem_dst, gmem, mbar, 16)


@cute.jit
def host(gmem: cutlass.Array, stream) -> None:  # noqa: ANN001
    # block=(4,1,1): a partial warp -> trips the C13 partial-warp elect.sync check
    partial_warp_bulk_copy_kernel(gmem).launch(
        grid=(1, 1, 1), block=(4, 1, 1), stream=stream
    )


def main() -> int:
    gmem = cutlass.runtime.make_fake_compact_array(
        cutlass.Int32, (4,), assumed_align=16
    )
    print(">>> cute.compile(host, options='warnings{nvvm}')\n")
    cute.compile(host, gmem, make_fake_stream(), options="warnings{nvvm}")
    print(
        "\n>>> compile finished (warning non-fatal) -- see warning[nvvm-diag:C13] above"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
