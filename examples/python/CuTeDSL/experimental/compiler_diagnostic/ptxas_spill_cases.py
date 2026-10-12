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

"""CuTe Python DSL examples for ptxas diagnostics.

This file contains small compile-only kernels that intentionally trigger ptxas
resource diagnostics. ptxas register-spill / local-memory findings are perf-only
(the program is functionally correct), so they are OPT-IN remarks under the
ptxas category — surfaced via the remark stream. Enabling a `ptxas` remark
filter both runs the ptxas-diagnostic pass and shows the findings; the examples
render them through the standard Python diagnostic formatter.
"""

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims


# Workaround: modern ptxas register-promotes a small, thread-id-
# indexed per-thread array into a select tree (0-byte stack frame), emitting no
# PTX local memory and silencing the local-memory diagnostic. Keep the array
# large enough -- and index it by a runtime-opaque value (loaded from global
# memory, below) -- so ptxas cannot promote it and must use addressable PTX
# local memory, reliably across ptxas versions/arches.
_LOCAL_REG_COUNT = 256
_GLOBAL_SPILL_VALUE_COUNT = 64


@cute.kernel
def _dynamic_index_local_memory_kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    tidx, _, _ = cute.arch.thread_idx()
    base = tidx * cutlass.Int32(_LOCAL_REG_COUNT)
    local_regs = cutlass.Array(cutlass.Int32, _LOCAL_REG_COUNT, alignment=16)

    for i in cutlass.range_constexpr(_LOCAL_REG_COUNT):
        local_regs[i] = (src.iterator.raw_ptr() + base + cutlass.Int32(i)).load()

    prims.barrier_cta_sync(0)

    # Index with a value loaded from global memory: ptxas cannot bound or
    # constant-fold it, so it cannot keep `local_regs` in registers and must
    # place the array in addressable PTX local memory. Using a thread-id-derived
    # index here would let ptxas register-promote the array on some toolchains,
    # yielding a 0-byte stack frame and no local-memory finding to report.
    dyn_idx = (src.iterator.raw_ptr() + tidx).load() & cutlass.Int32(
        _LOCAL_REG_COUNT - 1
    )
    indexed_register = local_regs[dyn_idx]
    (dst.iterator.raw_ptr() + tidx).store(indexed_register)


@cute.jit
def _host_dynamic_index_local_memory(
    src: cute.Tensor,
    dst: cute.Tensor,
    stream,
) -> None:  # noqa: ANN001
    _dynamic_index_local_memory_kernel(src, dst).launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


@cute.kernel
def _global_reverse_register_spill_kernel(src: cute.Tensor, dst: cute.Tensor) -> None:
    tidx, _, _ = cute.arch.thread_idx()
    base = tidx * cutlass.Int32(_GLOBAL_SPILL_VALUE_COUNT)

    values = (
        (src.iterator.raw_ptr() + base)
        .load(
            count=_GLOBAL_SPILL_VALUE_COUNT,
            alignment=_GLOBAL_SPILL_VALUE_COUNT * cutlass.Int32.bytes,
        )
        .to_elements()
    )

    prims.barrier_cta_sync(0)

    for i in cutlass.range_constexpr(_GLOBAL_SPILL_VALUE_COUNT):
        (dst.iterator.raw_ptr() + base + cutlass.Int32(i)).store(
            values[_GLOBAL_SPILL_VALUE_COUNT - 1 - i]
        )


@cute.jit
def _host_global_reverse_register_spill(
    src: cute.Tensor,
    dst: cute.Tensor,
    stream,
) -> None:  # noqa: ANN001
    _global_reverse_register_spill_kernel(src, dst).launch(
        grid=(1, 1, 1), block=(32, 1, 1), stream=stream
    )


def compile_dynamic_index_local_memory() -> None:
    element_count = _LOCAL_REG_COUNT * 32
    src = make_fake_compact_tensor(
        cutlass.Int32,
        (element_count,),
        assumed_align=16,
    )
    dst = make_fake_compact_tensor(
        cutlass.Int32,
        (32,),
        assumed_align=16,
    )
    # remarks{ptx} enables the ptxas-diagnostic pass and matches ptxas-category
    # perf remarks. Keep --remark-output unset so the Python diagnostic renderer
    # prints source frames instead of raw LLVM remark YAML.
    cute.compile(
        _host_dynamic_index_local_memory,
        src,
        dst,
        make_fake_stream(),
        options="remarks{ptx}",
    )


def compile_global_reverse_register_spill() -> None:
    element_count = _GLOBAL_SPILL_VALUE_COUNT * 32
    src = make_fake_compact_tensor(
        cutlass.Int32,
        (element_count,),
        assumed_align=16,
    )
    dst = make_fake_compact_tensor(
        cutlass.Int32,
        (element_count,),
        assumed_align=16,
    )
    cute.compile(
        _host_global_reverse_register_spill,
        src,
        dst,
        make_fake_stream(),
        options=(
            "remarks{ptx} "
            "--ptxas-options '--maxrregcount=16 --override-directive-values'"
        ),
    )


def main() -> int:
    for title, fn in (
        ("dynamic_index_local_memory", compile_dynamic_index_local_memory),
        ("global_reverse_register_spill", compile_global_reverse_register_spill),
    ):
        print(f"===== {title} =====", flush=True)
        fn()
        print(f"PASS {title}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
