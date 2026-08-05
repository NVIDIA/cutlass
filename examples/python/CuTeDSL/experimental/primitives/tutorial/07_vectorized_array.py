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

"""Vectorized load/store and memory operations — slice syntax and alignment.

Covers five vectorized-access patterns: basic vector load/store with
slice syntax, element-wise arithmetic on vector registers, alignment
hints for optimal memory throughput, masked load/store for boundary
handling, and advanced memory qualifiers (volatile, invariant).
"""

import cutlass
import cutlass.cute as cute
import torch
from cutlass.experimental import primitives as prims


# =============================================================================
# Example 1: Basic Vectorized Load/Store with Arithmetic
# =============================================================================


@cute.kernel
def vector_add_kernel(
    a_arr: cutlass.Array,
    b_arr: cutlass.Array,
    c_arr: cutlass.Array,
    vector_size: cutlass.Constexpr[int],
):
    """Vectorized element-wise addition: c = a + b

    Uses slice syntax for vectorized memory access.
    PTX generated (for vector_size=4):
        ld.global.v4.b32  {%r1, %r2, %r3, %r4}, [%rd1];
        ld.global.v4.b32  {%r5, %r6, %r7, %r8}, [%rd2];
        add.f16x2         %r9, %r4, %r8;
        ...
        st.global.v4.b32  [%rd3], {%r12, %r11, %r10, %r9}
    """
    tx, _, _ = cute.arch.thread_idx()
    idx = tx * vector_size

    # Vectorized load, arithmetic, and store using slice syntax
    c_arr[idx:vector_size] = a_arr[idx:vector_size] + b_arr[idx:vector_size]


# =============================================================================
# Example 2: Aligned Memory Access
# =============================================================================


@cute.kernel
def aligned_copy_kernel(
    src_arr: cutlass.Array, dst_arr: cutlass.Array, vector_size: cutlass.Constexpr[int]
):
    """Demonstrates aligned vs non-aligned memory access.

    Aligned access generates vectorized PTX instructions:
        ld.global.v2.b64  {%rd5, %rd6}, [%rd3];
        st.global.v2.b64  [%rd4], {%rd5, %rd6};

    Non-aligned access generates scalar PTX instructions:
        ld.global.b32     %rd5, [%rd3+4];
        ld.global.b32     %rd6, [%rd3];
        st.global.b32     [%rd4+4], %rd5;
        st.global.b32     [%rd4], %rd6;
    """
    tx, _, _ = cute.arch.thread_idx()

    # Calculate alignment in bytes (vector_size * element_size)
    # For Float32 with vector_size=4: 4 * 4 = 16 bytes
    alignment = vector_size * 4  # 4 bytes per float32

    # Thread's starting index (aligned to vector_size boundary)
    idx = tx * vector_size

    # ALIGNED access: compiler can generate vectorized instructions
    # The alignment hint tells the compiler the address is properly aligned
    data = src_arr.load(idx, vector_size, alignment=alignment)
    dst_arr.store(data, idx, vector_size, alignment=alignment)


# =============================================================================
# Example 3: Advanced Memory Options (Volatile, Invariant)
# =============================================================================


@cute.kernel
def advanced_load_store_kernel(src_arr: cutlass.Array, dst_arr: cutlass.Array):
    """Demonstrates advanced load/store options.

    Options available:
    - is_volatile: Prevents compiler from optimizing away or reordering
      PTX: ld.global.volatile.b32

    - is_invariant: Promises loaded value won't change, allows caching
      PTX: may generate ld.global.nc.b32 (non-coherent/streaming)

    - alignment: Explicit memory alignment hint
    """
    tx, _, _ = cute.arch.thread_idx()
    bx, _, _ = cute.arch.block_idx()

    if bx == 0 and tx == 0:
        # Basic load/store
        val = src_arr.load(0)
        dst_arr.store(val, 0)

        # Volatile load: compiler cannot optimize away or reorder
        # Use for memory-mapped I/O or synchronization
        val_volatile = src_arr.load(1, is_volatile=True)
        dst_arr.store(val_volatile, 1, is_volatile=True)

        # Invariant load: promise the value won't change
        # Compiler may cache or hoist the load
        val_invariant = src_arr.load(2, is_invariant=True)
        dst_arr.store(val_invariant, 2)

        # Vector load with alignment
        vec4 = src_arr.load(4, vector_size=4, alignment=16)
        dst_arr.store(vec4, 4, alignment=16)


# =============================================================================
# Example 4: Masked Load/Store for Boundary Handling
# =============================================================================


@cute.kernel
def masked_copy_kernel(
    src_arr: cutlass.Array,
    dst_arr: cutlass.Array,
    valid_count: cutlass.Int32,
    vector_size: cutlass.Constexpr[int],
):
    """Copy with mask for handling array boundaries.

    When array size isn't divisible by vector_size, use masked operations
    to avoid out-of-bounds access. Elements outside the valid range are:
    - For load: replaced with a default value
    - For store: not written to memory
    """
    tx, _, _ = cute.arch.thread_idx()
    idx = tx * vector_size

    # Allocate mask array in local memory (boolean type)
    # Each element indicates if that vector lane is within bounds
    mask = cutlass.Array(cutlass.Boolean, vector_size)
    for i in range(vector_size):
        mask[i] = (idx + i) < valid_count

    # Masked load: only load elements where mask is True
    # Elements where mask is False get the default value (0.0)
    data = src_arr.masked_load(idx, vector_size, mask, default=cutlass.Float16(0.0))

    # Masked store: only store elements where mask is True
    # Elements where mask is False are not written
    dst_arr.masked_store(idx, data, mask)


# =============================================================================
# Example 5: Broadcast Write (Fill with scalar)
# =============================================================================


@cute.kernel
def broadcast_fill_kernel(
    dst_arr: cutlass.Array, fill_value: cutlass.Float32, count: cutlass.Int32
):
    """Fill array with a scalar value using broadcast write.

    PTX generated:
        mov.b32     %r2, 0f40000000;    // 2.0f
        mov.b64     %rd13, {%r2, %r2};   // pack into 64-bit
        st.global.v2.b64 [%rd4], {%rd13, %rd13};
    """
    tx, _, _ = cute.arch.thread_idx()
    bx, _, _ = cute.arch.block_idx()

    if bx == 0 and tx == 0:
        # Scalar store
        dst_arr.store(fill_value, 0)

        # Broadcast: store scalar to multiple elements
        # The scalar is replicated to fill the vector
        for i in range(count):
            dst_arr.store(fill_value, i)


# =============================================================================
# Host Functions
# =============================================================================


@cute.jit
def vector_add_host(
    matrix_a: cutlass.Array,
    matrix_b: cutlass.Array,
    matrix_c: cutlass.Array,
    vector_size: cutlass.Constexpr[int],
):
    """Launch vector addition kernel."""
    num_threads = matrix_a.shape[0] // vector_size
    block = (num_threads, 1, 1)
    grid = (1, 1, 1)

    prims.print_runtime(
        "Vector Add: {} threads, vector_size={}\n", num_threads, vector_size
    )

    vector_add_kernel(matrix_a, matrix_b, matrix_c, vector_size).launch(
        grid=grid, block=block
    )


@cute.jit
def aligned_copy_host(
    src: cutlass.Array, dst: cutlass.Array, vector_size: cutlass.Constexpr[int]
):
    """Launch aligned copy kernel."""
    num_threads = src.shape[0] // vector_size
    block = (num_threads, 1, 1)
    grid = (1, 1, 1)

    aligned_copy_kernel(src, dst, vector_size).launch(grid=grid, block=block)


@cute.jit
def advanced_load_store_host(src: cutlass.Array, dst: cutlass.Array):
    """Launch advanced load/store kernel."""
    advanced_load_store_kernel(src, dst).launch(grid=(1, 1, 1), block=(1, 1, 1))


@cute.jit
def masked_copy_host(
    src: cutlass.Array,
    dst: cutlass.Array,
    valid_count: cutlass.Int32,
    vector_size: cutlass.Constexpr[int],
):
    """Launch masked copy kernel."""
    # Round up to handle partial last chunk
    num_threads = (valid_count + vector_size - 1) // vector_size
    block = (num_threads, 1, 1)
    grid = (1, 1, 1)

    prims.print_runtime(
        "Masked Copy: {} valid elements, {} threads\n", valid_count, num_threads
    )

    masked_copy_kernel(src, dst, valid_count, vector_size).launch(
        grid=grid, block=block
    )


# =============================================================================
# Test 1: Basic Vectorized Addition
# =============================================================================

print("=" * 60)
print("Test 1: Basic Vectorized Addition")
print("=" * 60)

array_size = 16
vector_size = 8

a = torch.ones(array_size, dtype=torch.float16, device="cuda")
b = torch.ones(array_size, dtype=torch.float16, device="cuda") * 2
c = torch.zeros(array_size, dtype=torch.float16, device="cuda")

vector_add_host(
    cute.runtime.from_dlpack(a),
    cute.runtime.from_dlpack(b),
    cute.runtime.from_dlpack(c),
    vector_size,
)

expected = a + b
print(f"a:        {a}")
print(f"b:        {b}")
print(f"Expected: {expected}")
print(f"Result:   {c}")
torch.testing.assert_close(c, expected)
print("PASS\n")


# =============================================================================
# Test 2: Aligned Memory Copy
# =============================================================================

print("=" * 60)
print("Test 2: Aligned Memory Copy")
print("=" * 60)

array_size = 32
vector_size = 4

src = torch.arange(array_size, dtype=torch.float32, device="cuda")
dst = torch.zeros_like(src)

aligned_copy_host(
    cute.runtime.from_dlpack(src),
    cute.runtime.from_dlpack(dst),
    vector_size,
)

print(f"Source: {src}")
print(f"Dest:   {dst}")
torch.testing.assert_close(dst, src)
print("PASS\n")


# =============================================================================
# Test 3: Advanced Load/Store Options
# =============================================================================

print("=" * 60)
print("Test 3: Advanced Load/Store Options")
print("=" * 60)

src = torch.arange(16, dtype=torch.float32, device="cuda")
dst = torch.zeros_like(src)

advanced_load_store_host(cute.runtime.from_dlpack(src), cute.runtime.from_dlpack(dst))

print(f"Source: {src}")
print(f"Dest:   {dst}")
# Check first 8 elements (0, 1, 2, and 4-7 for vector load)
torch.testing.assert_close(dst[:3], src[:3])
torch.testing.assert_close(dst[4:8], src[4:8])
print("PASS\n")


# =============================================================================
# Test 4: Masked Copy with Non-Divisible Size
# =============================================================================

print("=" * 60)
print("Test 4: Masked Copy (handling boundaries)")
print("=" * 60)

# Array size not divisible by vector_size
total_size = 16  # Allocate enough space
valid_count = 13  # But only 13 elements are valid
vector_size = 8

src = torch.arange(total_size, dtype=torch.float16, device="cuda")
dst = torch.full((total_size,), -1.0, dtype=torch.float16, device="cuda")

masked_copy_host(
    cute.runtime.from_dlpack(src),
    cute.runtime.from_dlpack(dst),
    valid_count,
    vector_size,
)

# Only first 13 elements should be copied
print(f"Source:    {src[:valid_count]}")
print(f"Dest:      {dst[:valid_count]}")
print(f"Dest tail: {dst[valid_count:]} (should be -1, unmodified)")

torch.testing.assert_close(dst[:valid_count], src[:valid_count])
torch.testing.assert_close(
    dst[valid_count:],
    torch.full((total_size - valid_count,), -1.0, dtype=torch.float16, device="cuda"),
)
print("PASS\n")

print("=" * 60)
print("All tests passed!")
print("=" * 60)
