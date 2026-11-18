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


import argparse
import cuda.bindings.driver as cuda
from typing import Type
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute import experimental as cute_ext
from cutlass.cute.experimental.algorithm import (
    partition_and_copy,
    predicated_tensor_origin,
)
from cutlass._mlir.dialects import llvm

from cutlass.cute.arch.nvvm_wrappers import atomic_add as atomicAdd

if __name__ == "__main__":
    import sys
    import os

    sys.path.insert(
        0,
        os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "..")),
    )

from cute_ext.blackwell.top_k.block_scan import block_prefix_sum_kernel

from cutlass.torch import dtype as torch_dtype

"""
A high-performance topk kernel example based on radix-based filter algorithm for
the NVIDIA Blackwell SM100 architecture using CuTe DSL and cute_ext APIs.

This variant of blackwell/top_k/filter_top_k_padded.py exercises cute_ext APIs
for non-MMA SIMT kernels. It uses the standard @cute.kernel/@cute.jit decorators
and cute.compile. Compared with the original CuTe DSL example:
- All gmem→rmem copies use partition_and_copy with predicated_tensor_origin
- All register fragments use cute_ext.allocate instead of
  cute dialect make_fragment/make_fragment_like

The radix-based filter top-k algorithm mainly includes two phases: coarse filter and multi-round fine-grained filter.
For each phase:
1. histogram: Build a histogram of the input values using vectorized loads.
2. prefix sum: Find the threshold bin using prefix sum.
3. find target bin id: Find the target bin id using multiple rounds.
Finally, write the top-k values and indices to the output tensor.

Supported data types:
- Float32
- Float16
- BFloat16

To run this example:
.. code-block:: bash
    python examples/blackwell/sort/filter_top_k.py  \
      --dtype Float32 --num_rows 1 --num_cols 4096 --top_k 2048 --do_ref_check --do_benchmark

Constraints for this example:
* The problem size of num_cols >= vec_size, and we pad the input tensor 
  so that each row can be aligned to vec_size and could use vectorized copy.
* The problem size of top_k <= 2048.
* If the vector size is 256 bits, requiring the input tensor is 256B aligned.
* The input tensor has data contiguous on the n dimension (row-major).
* The supported input data types are Float32, Float16, or BFloat16.
"""


def half_as_ushort(half_val):
    """Interpret FP16 value as uint16 bit pattern"""
    return llvm.bitcast(cutlass.Uint16.mlir_type, half_val.ir_value())


def float_as_uint32(float_val):
    """Interpret FP32 value as uint32 bit pattern"""
    return llvm.bitcast(cutlass.Uint32.mlir_type, float_val.ir_value())


class FilteredTopKKernel:
    def __init__(
        self,
        dtype: cutlass.Numeric,
        num_cols: int,
        top_k: int,
        num_copy_bits: int = 256,
        return_val: bool = True,
    ):
        self.dtype = dtype
        self.num_cols = num_cols
        self.top_k = top_k
        self.num_copy_bits = num_copy_bits

        self.filtered_topk_max_k = 2048
        # 8 bits for radix-based filter.
        self.radix = 256

        if cutlass.const_expr(self.dtype == cutlass.Float32):
            self.num_buffer_smem_input_idx = 2
        else:
            self.num_buffer_smem_input_idx = 1

        # 65536 is the max index value for uint16.
        if cutlass.const_expr(self.num_cols <= 65536):
            self.index_type = cutlass.Uint16
            if cutlass.const_expr(self.num_buffer_smem_input_idx == 2):
                self.max_smem_input_size = 32 * 1024
            else:
                self.max_smem_input_size = 64 * 1024
        else:
            self.index_type = cutlass.Uint32
            if cutlass.const_expr(self.num_buffer_smem_input_idx == 2):
                self.max_smem_input_size = 16 * 1024
            else:
                self.max_smem_input_size = 32 * 1024

        self.filtered_topk_smem_input_size = min(
            self.max_smem_input_size, self.num_cols
        )

        self.return_val = return_val

        self.vec_size = num_copy_bits // dtype.width
        assert self.num_cols >= self.vec_size, (
            f"num_cols must be >= vec_size, but got {self.num_cols} and {self.vec_size}"
        )
        if cutlass.const_expr(
            dtype not in [cutlass.Float32, cute.BFloat16, cutlass.Float16]
        ):
            raise ValueError(f"Unsupported dtype: {dtype}")

        if cutlass.const_expr(dtype == cutlass.Float32):
            if self.num_cols >= self.vec_size * 1024:
                self.num_threads_per_cta = 1024
            else:
                if cutlass.const_expr(self.num_cols > 2048 and self.num_cols < 8192):
                    self.num_threads_per_cta = 512
                else:
                    self.num_threads_per_cta = 256
        else:
            if self.num_cols >= 43008:
                self.num_threads_per_cta = 1024
            else:
                if cutlass.const_expr(self.num_cols > 4096 and self.num_cols < 43008):
                    self.num_threads_per_cta = 512
                else:
                    self.num_threads_per_cta = 256

        # radix-based filter parameters.
        if cutlass.const_expr(dtype == cutlass.Float32):
            self.ordered_type = cute.Uint32
            self.first_refine_shift = 24
            self.num_refine_rounds = 4
        elif cutlass.const_expr(dtype in [cutlass.Float16, cute.BFloat16]):
            self.ordered_type = cute.Uint16
            self.first_refine_shift = 0
            self.num_refine_rounds = 1
    @cute.jit
    def to_coarse_key(self, x):
        """Convert to coarse 8-bit key for histogram"""

        if cutlass.const_expr(self.dtype == cutlass.Float32):
            # Convert to FP16 and extract high 8 bits
            h = x.to(cutlass.Float16)
            bits = half_as_ushort(h)

            key = cutlass.Uint16(0)

            # extract the sign bit
            # key = (bits & 0x8000) ? bits : ~bits & 0x7fff;
            if bits & 0x8000:
                key = cutlass.Uint16(bits)
            else:
                key = (bits ^ cutlass.Uint16(0xFFFF)) & cutlass.Uint16(0x7FFF)

            # high 8 bits
            return cute.Uint8((key >> 8) & 0xFF)
        else:
            # For half/bfloat16, extract high 8 bits directly
            if cutlass.const_expr(self.dtype == cutlass.Float16):
                bits = half_as_ushort(x)
            else:  # BFloat16
                bits = half_as_ushort(x)

            key = cute.Uint16(0)
            if bits & 0x8000:
                key = cutlass.Uint16(bits)
            else:
                key = (bits ^ cutlass.Uint16(0xFFFF)) & cutlass.Uint16(0x7FFF)
            # high 8 bits
            return cute.Uint8((key >> 8) & 0xFF)

    @cute.jit
    def to_ordered(self, x):
        """Convert to ordered integer for comparison"""
        if cutlass.const_expr(self.dtype == cutlass.Float32):
            bits = float_as_uint32(x)

            key = cutlass.Uint32(0)
            if bits & 0x80000000:
                key = cutlass.Uint32(bits)
            else:
                key = (bits ^ cutlass.Uint32(0xFFFFFFFF)) & cutlass.Uint32(0x7FFFFFFF)
            return cute.Uint32(key)
        else:
            if cutlass.const_expr(self.dtype == cutlass.Float16):
                bits = half_as_ushort(x)
            else:  # BFloat16
                bits = half_as_ushort(x)

            key = cute.Uint16(0)
            if bits & 0x8000:
                key = cutlass.Uint16(bits)
            else:
                key = (bits ^ cute.Uint16(0xFFFF)) & cute.Uint16(0x7FFF)
            return cute.Uint16(key)

    @cute.jit
    def prefix_sum_and_find_threshold_coarse(
        self,
        tidx,
        s_histogram,
        s_warp_sums,
        num_warps,
        s_threshold_bin_id,
        s_num_input,
        s_counter,
        s_last_remain,
        topk_remaining,
        s_num_input_idx=0,
    ):
        if cutlass.const_expr(self.radix <= self.num_threads_per_cta):
            previous = 0
            if tidx < cutlass.Int32(self.radix):
                val = s_histogram[tidx]
                val, total_sum = block_prefix_sum_kernel(
                    val, s_warp_sums, tidx, self.radix, num_warps, barrier_id=1
                )
                s_histogram[tidx] = val
                # sync among self.radix threads
                cute.arch.barrier(barrier_id=1, number_of_threads=self.radix)

                if tidx > 0:
                    previous = s_histogram[tidx - 1]
                if previous <= topk_remaining and s_histogram[tidx] > topk_remaining:
                    s_threshold_bin_id[0] = tidx
                    s_num_input[s_num_input_idx] = 0
                    # TODO: the difference between 1 and 2.
                    s_counter[0] = 0
            # sync among all threads in a cta.
            cute.arch.barrier()
        else:
            assert self.radix % self.num_threads_per_cta == 0
            previous_sum = 0
            val = 0
            total_sum = 0
            for i in range(tidx, self.radix, self.num_threads_per_cta):
                val = s_histogram[i]
                val, total_sum = block_prefix_sum_kernel(
                    val,
                    s_warp_sums,
                    tidx,
                    self.num_threads_per_cta,
                    num_warps,
                    barrier_id=2,
                    need_total_sum=True,
                )
                s_histogram[i] = val + previous_sum
                previous_sum = previous_sum + total_sum
            # sync among all threads in a cta.
            cute.arch.barrier()

            previous = 0
            run_loop = True
            if tidx > 0:
                previous = s_histogram[tidx - 1]
            if previous <= topk_remaining and s_histogram[tidx] > topk_remaining:
                s_threshold_bin_id[0] = tidx
                s_num_input[s_num_input_idx] = 0
                # the difference between coarse and fine-grained.
                s_counter[0] = 0
                run_loop = False

            if run_loop:
                run_next_loop = True
                for i in range(
                    tidx + self.num_threads_per_cta,
                    self.radix,
                    self.num_threads_per_cta,
                ):
                    if run_next_loop:
                        previous = s_histogram[i - 1]
                        if (
                            previous <= topk_remaining
                            and s_histogram[i] > topk_remaining
                        ):
                            s_threshold_bin_id[0] = i
                            s_num_input[s_num_input_idx] = 0
                            # the difference between coarse and fine-grained.
                            s_counter[0] = 0
                            run_next_loop = False
            # sync among all threads in a cta.
            cute.arch.barrier()

    @cute.jit
    def prefix_sum_and_find_threshold_fine_grained(
        self,
        tidx,
        s_histogram,
        s_warp_sums,
        num_warps,
        s_threshold_bin_id,
        s_num_input,
        s_counter,
        s_last_remain,
        topk_remaining,
        s_num_input_idx=0,
    ):
        if cutlass.const_expr(self.radix <= self.num_threads_per_cta):
            previous = 0
            if tidx < cutlass.Int32(self.radix):
                val = s_histogram[tidx]
                val, total_sum = block_prefix_sum_kernel(
                    val, s_warp_sums, tidx, self.radix, num_warps, barrier_id=1
                )
                s_histogram[tidx] = val
                # sync
                cute.arch.barrier(barrier_id=1, number_of_threads=self.radix)

                if tidx > 0:
                    previous = s_histogram[tidx - 1]
                if previous <= topk_remaining and s_histogram[tidx] > topk_remaining:
                    s_threshold_bin_id[0] = tidx
                    s_num_input[s_num_input_idx] = 0
                    # the first difference between coarse and fine-grained.
                    s_last_remain[0] = topk_remaining - previous
            cute.arch.barrier()
        else:
            assert self.radix % self.num_threads_per_cta == 0
            previous_sum = 0
            val = 0
            total_sum = 0
            for i in range(tidx, self.radix, self.num_threads_per_cta):
                val = s_histogram[i]
                val, total_sum = block_prefix_sum_kernel(
                    val,
                    s_warp_sums,
                    tidx,
                    self.num_threads_per_cta,
                    num_warps,
                    barrier_id=2,
                    need_total_sum=True,
                )
                s_histogram[i] = val + previous_sum
                previous_sum = previous_sum + total_sum
            # sync among all threads in a cta.
            cute.arch.barrier()

            previous = 0
            run_loop = True
            if tidx > 0:
                previous = s_histogram[tidx - 1]
            if previous <= topk_remaining and s_histogram[tidx] > topk_remaining:
                s_threshold_bin_id[0] = tidx
                s_num_input[s_num_input_idx] = 0
                # the difference between coarse and fine-grained.
                s_last_remain[0] = topk_remaining - previous
                run_loop = False
            if run_loop:
                run_next_loop = True
                for i in range(
                    tidx + self.num_threads_per_cta,
                    self.radix,
                    self.num_threads_per_cta,
                ):
                    if run_next_loop:
                        previous = s_histogram[i - 1]
                        if (
                            previous <= topk_remaining
                            and s_histogram[i] > topk_remaining
                        ):
                            s_threshold_bin_id[0] = i
                            s_num_input[s_num_input_idx] = 0
                            # the difference between coarse and fine-grained.
                            s_last_remain[0] = topk_remaining - previous
                            run_next_loop = False
            # sync among all threads in a cta.
            cute.arch.barrier()

    @cute.kernel
    def filtered_topk_kernel(
        self,
        input: cute.Tensor,
        output_indices: cute.Tensor,
        output_values: cute.Tensor,
        tiler_mn: cute.Shape,
        copy_atom: cute.CopyAtom,
        tiled_copy: cute.TiledCopy,
        aligned_size: cutlass.Constexpr,  # aligned size which is divisible by vec_size, vectorized copy
        left_size: cutlass.Constexpr,  # left size which is not divisible by vec_size, scalar copy
    ):
        """LIR (CuTe Experimental) implementation of TopK kernel based on radix-based filter algorithm."""
        # Thread and block indexing
        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()

        length = self.num_cols
        score = input[bidx, None]
        dst = output_indices[bidx, None]
        if cutlass.const_expr(self.return_val):
            dst_values = output_values[bidx, None]

        has_left_part = cutlass.const_expr(self.num_cols % self.vec_size != 0)
        shape = input.shape

        idX = cute.make_identity_tensor((shape[0], aligned_size))
        input_tensor = cute.make_tensor(
            input.iterator,
            cute.make_layout((shape[0], aligned_size), stride=input.stride),
        )

        # slice for CTAs
        gX, cX = [
            cute.local_tile(mT, tiler_mn, (bidx, None)) for mT in (input_tensor, idX)
        ]

        self.num_sub_tiles = gX.shape[2]

        thr_copy = tiled_copy.get_slice(tidx)

        tXgX = thr_copy.partition_S(gX)
        tXcX = thr_copy.partition_S(cX)[(0, None), None, None, None]
        tXrX = cute_ext.allocate(
            self.dtype,
            cutlass.AddressSpace.rmem,
            tXgX[None, None, None, 0].layout,
            alignment=32,
        )

        is_even_N = cutlass.const_expr(self.num_cols % tiler_mn[1] == 0)
        tXpX = (
            None
            if is_even_N
            else self.predicate_k(thr_copy.partition_S(cX), limit=aligned_size)
        )

        # Trivial case: length <= top_k
        if cutlass.const_expr(length <= self.top_k):
            for i in range(tidx, self.top_k, self.num_threads_per_cta):
                if i < length:
                    dst[i] = i
                    if cutlass.const_expr(self.return_val):
                        dst_values[i] = score[i]
                else:
                    dst[i] = -1
                    if cutlass.const_expr(self.return_val):
                        dst_values[i] = self.dtype(0.0)
        else:
            # Shared memory allocation
            smem = cutlass.memory.SmemAllocator()
            s_histogram_buf_layout = cute.make_ordered_layout(
                (self.radix + 128), order=(0)
            )
            s_histogram = smem.allocate_tensor(
                element_type=cutlass.Int32,
                layout=s_histogram_buf_layout,
                byte_alignment=128,
            )
            s_counter = smem.allocate_tensor(
                element_type=cutlass.Int32,
                layout=cute.make_ordered_layout((1), order=(0)),
                byte_alignment=128,
            )
            s_threshold_bin_id = smem.allocate_tensor(
                element_type=cutlass.Int32,
                layout=cute.make_ordered_layout((1), order=(0)),
                byte_alignment=128,
            )
            s_num_input = smem.allocate_tensor(
                element_type=cutlass.Int32,
                layout=cute.make_ordered_layout((2,), order=(0)),
                byte_alignment=128,
            )
            s_indices = smem.allocate_tensor(
                element_type=self.index_type,
                layout=cute.make_ordered_layout((self.filtered_topk_max_k,), order=(0)),
                byte_alignment=128,
            )
            s_input_idx = smem.allocate_tensor(
                element_type=self.index_type,
                layout=cute.make_ordered_layout(
                    (
                        self.num_buffer_smem_input_idx,
                        self.filtered_topk_smem_input_size,
                    ),
                    order=(1, 0),
                ),
                byte_alignment=128,
            )
            s_last_remain = smem.allocate_tensor(
                element_type=cutlass.Int32,
                layout=cute.make_ordered_layout((1), order=(0)),
                byte_alignment=128,
            )
            num_warps = cutlass.const_expr(
                min(self.radix, self.num_threads_per_cta) // cutlass.Int32(32)
            )
            s_warp_sums = smem.allocate_tensor(
                element_type=cute.Int32,
                layout=cute.make_ordered_layout((num_warps,), order=(0,)),
                byte_alignment=128,
            )

            topk_remaining = self.top_k

            val_one = 1
            val_one_negative = -1

            # Stage 1: Coarse histogram.
            if tidx < self.radix + 1:
                s_histogram[tidx] = 0
            cute.arch.barrier()

            # 1.1 Build histogram with vectorized loads
            vec_size = self.vec_size

            for tile_idx in range(self.num_sub_tiles):
                partition_and_copy(
                    thr_copy,
                    predicated_tensor_origin(gX[None, None, tile_idx]),
                    tXrX,
                )
                if cutlass.const_expr(tXpX is not None):
                    self._fill_oob(
                        tXrX,
                        tXpX[None, None, None, tile_idx],
                        -tXrX.element_type.inf,
                    )

                for i in cutlass.range(cute.size(tXrX), unroll_full=True):
                    bin_val = self.to_coarse_key(tXrX[i])
                    atomicAdd(
                        s_histogram.iterator + cutlass.Int32(bin_val),
                        val_one,
                        scope="cta",
                    )

            # for left part (left_size)
            if cutlass.const_expr(has_left_part):
                for j in range(tidx, left_size, self.num_threads_per_cta):
                    if j < left_size:
                        col_idx = cutlass.Int32(aligned_size + j)
                        raw = score[col_idx]
                        bin_val = self.to_coarse_key(raw)
                        atomicAdd(
                            s_histogram.iterator + cutlass.Int32(bin_val),
                            val_one,
                            scope="cta",
                        )

            cute.arch.barrier()

            # 1.2 and 1.3  Suffix sum to find threshold and find threshold bin
            self.prefix_sum_and_find_threshold_coarse(
                tidx,
                s_histogram,
                s_warp_sums,
                num_warps,
                s_threshold_bin_id,
                s_num_input,
                s_counter,
                s_last_remain,
                topk_remaining,
                s_num_input_idx=0,
            )

            threshold_bin = s_threshold_bin_id[0]
            if threshold_bin > 0:
                topk_remaining -= s_histogram[threshold_bin - 1]

            # 1.4 Collect indices
            if topk_remaining == 0:
                # Collect indices where bin > threshold
                for tile_idx in range(self.num_sub_tiles):
                    partition_and_copy(
                        thr_copy,
                        predicated_tensor_origin(gX[None, None, tile_idx]),
                        tXrX,
                    )
                    if cutlass.const_expr(tXpX is not None):
                        self._fill_oob(
                            tXrX,
                            tXpX[None, None, None, tile_idx],
                            -tXrX.element_type.inf,
                        )

                    for i in cutlass.range(cute.size(tXrX), unroll_full=True):
                        cur_tXcX = tXcX[None, None, None, tile_idx]
                        bin_val = self.to_coarse_key(tXrX[i])
                        if bin_val < threshold_bin:
                            pos = atomicAdd(s_counter.iterator, val_one, scope="cta")
                            idx = self.index_type(
                                cur_tXcX[i // vec_size][1] + i % vec_size
                            )
                            s_indices[pos] = idx

                # for left part (left_size)
                if cutlass.const_expr(has_left_part):
                    for j in range(tidx, left_size, self.num_threads_per_cta):
                        if j < left_size:
                            col_idx = cutlass.Int32(aligned_size + j)
                            raw = score[col_idx]
                            bin_val = self.to_coarse_key(raw)
                            if bin_val < threshold_bin:
                                pos = atomicAdd(
                                    s_counter.iterator, val_one, scope="cta"
                                )
                                idx = self.index_type(col_idx)
                                s_indices[pos] = idx

                cute.arch.barrier()

            else:
                # Reset histogram for refinement
                cute.arch.barrier()
                if tidx < self.radix + 1:
                    s_histogram[tidx] = 0
                cute.arch.barrier()

                # Filter and build refinement histogram
                for tile_idx in range(self.num_sub_tiles):
                    partition_and_copy(
                        thr_copy,
                        predicated_tensor_origin(gX[None, None, tile_idx]),
                        tXrX,
                    )
                    if cutlass.const_expr(tXpX is not None):
                        self._fill_oob(
                            tXrX,
                            tXpX[None, None, None, tile_idx],
                            -tXrX.element_type.inf,
                        )

                    for i in cutlass.range(cute.size(tXrX), unroll_full=True):
                        raw_input = tXrX[i]
                        bin_val = self.to_coarse_key(raw_input)
                        cur_tXcX = tXcX[None, None, None, tile_idx]
                        idx = self.index_type(cur_tXcX[i // vec_size][1] + i % vec_size)
                        if bin_val < threshold_bin:
                            pos = atomicAdd(s_counter.iterator, val_one, scope="cta")
                            s_indices[pos] = idx
                        elif bin_val == threshold_bin:
                            # pos = atomicAdd(s_num_input[0], 1)
                            pos = atomicAdd(s_num_input.iterator, val_one, scope="cta")
                            if pos < self.filtered_topk_smem_input_size:
                                s_input_idx[0, pos] = idx
                                ordered = self.to_ordered(raw_input)
                                sub_bin = (ordered >> self.first_refine_shift) & 0xFF
                                # atomicAdd(s_histogram[sub_bin], 1)
                                atomicAdd(
                                    s_histogram.iterator + cutlass.Int32(sub_bin),
                                    val_one,
                                    scope="cta",
                                )

                # for left part
                if cutlass.const_expr(has_left_part):
                    for j in range(tidx, left_size, self.num_threads_per_cta):
                        if j < left_size:
                            col_idx = cutlass.Int32(aligned_size + j)
                            raw = score[col_idx]
                            bin_val = self.to_coarse_key(raw)
                            if bin_val < threshold_bin:
                                pos = atomicAdd(
                                    s_counter.iterator, val_one, scope="cta"
                                )
                                idx = self.index_type(col_idx)
                                s_indices[pos] = idx
                            elif bin_val == threshold_bin:
                                pos = atomicAdd(
                                    s_num_input.iterator + cutlass.Int32(0),
                                    val_one,
                                    scope="cta",
                                )
                                if pos < self.filtered_topk_smem_input_size:
                                    s_input_idx[0, pos] = self.index_type(col_idx)
                                    ordered = self.to_ordered(raw)
                                    sub_bin = (
                                        ordered >> self.first_refine_shift
                                    ) & 0xFF
                                    atomicAdd(
                                        s_histogram.iterator + cutlass.Int32(sub_bin),
                                        val_one,
                                        scope="cta",
                                    )

                cute.arch.barrier()

                # Phase 2: Refinement rounds
                run_next_round = True
                for round in range(self.num_refine_rounds):
                    if run_next_round:
                        r_idx = round % 2
                        num_input = min(
                            s_num_input[r_idx], self.filtered_topk_smem_input_size
                        )

                        self.prefix_sum_and_find_threshold_fine_grained(
                            tidx,
                            s_histogram,
                            s_warp_sums,
                            num_warps,
                            s_threshold_bin_id,
                            s_num_input,
                            s_counter,
                            s_last_remain,
                            topk_remaining,
                            s_num_input_idx=r_idx ^ 1,
                        )

                        threshold = s_threshold_bin_id[0]
                        if threshold > 0:
                            topk_remaining -= s_histogram[threshold - 1]
                        offset = self.first_refine_shift - round * 8
                        is_last_round = round == self.num_refine_rounds - 1

                        if topk_remaining == 0:
                            for i in range(tidx, num_input, self.num_threads_per_cta):
                                idx = s_input_idx[r_idx, i]
                                idx = cutlass.Int32(idx)
                                bin_val = (self.to_ordered(score[idx]) >> offset) & 0xFF
                                if bin_val < threshold:
                                    pos = atomicAdd(
                                        s_counter.iterator, val_one, scope="cta"
                                    )
                                    s_indices[pos] = self.index_type(idx)
                            cute.arch.barrier()
                            # break
                            run_next_round = False
                        else:
                            # Reset histogram
                            cute.arch.barrier()
                            if tidx < self.radix + 1:
                                s_histogram[tidx] = 0
                            cute.arch.barrier()

                            for i in range(tidx, num_input, self.num_threads_per_cta):
                                idx = s_input_idx[r_idx, i]
                                idx = cutlass.Int32(idx)
                                raw_input = score[idx]
                                idx = self.index_type(idx)
                                bin_val = (self.to_ordered(raw_input) >> offset) & 0xFF
                                if bin_val < threshold:
                                    pos = atomicAdd(
                                        s_counter.iterator, val_one, scope="cta"
                                    )
                                    s_indices[pos] = idx
                                elif bin_val == threshold:
                                    if is_last_round:
                                        cur_pos = atomicAdd(
                                            s_last_remain.iterator,
                                            val_one_negative,
                                            scope="cta",
                                        )
                                        if cur_pos > 0:
                                            s_indices[self.top_k - cur_pos] = idx
                                    else:
                                        # pos = atomicAdd(s_num_input[r_idx ^ 1], 1)
                                        cur_pos = atomicAdd(
                                            s_num_input.iterator + (r_idx ^ 1),
                                            val_one,
                                            scope="cta",
                                        )
                                        if cur_pos < self.filtered_topk_smem_input_size:
                                            s_input_idx[r_idx ^ 1, cur_pos] = idx
                                            bin32 = self.to_ordered(raw_input)
                                            sub_bin = (bin32 >> (offset - 8)) & 0xFF
                                            # atomicAdd(s_histogram[sub_bin], 1)
                                            atomicAdd(
                                                s_histogram.iterator
                                                + cutlass.Int32(sub_bin),
                                                val_one,
                                                scope="cta",
                                            )
                            cute.arch.barrier()

            # Phase 3: Output phase
            vecsize_out = cutlass.const_expr(
                min(
                    self.top_k,
                    cute.ceil_div(self.top_k, self.num_threads_per_cta),
                    self.num_copy_bits // self.dtype.width,
                    # TODO: only tested for float32. need to check for other dtypes.
                    2,
                )
            )
            assert self.top_k % vecsize_out == 0

            nvec_per_thread = cutlass.const_expr(
                cute.ceil_div(self.top_k, vecsize_out * self.num_threads_per_cta)
            )
            topk_vals = cute_ext.allocate(
                self.dtype,
                cutlass.AddressSpace.rmem,
                cute.make_layout((vecsize_out, nvec_per_thread)),
                alignment=32,
            )
            topk_indices = cute_ext.allocate(
                cutlass.Int32,
                cutlass.AddressSpace.rmem,
                cute.make_layout((vecsize_out, nvec_per_thread)),
                alignment=32,
            )

            stride = self.num_threads_per_cta * vecsize_out
            for i in cutlass.range(nvec_per_thread, unroll_full=True):
                idx = i * stride + tidx % self.num_threads_per_cta * vecsize_out
                if idx < self.top_k:
                    for v in cutlass.range(vecsize_out, unroll_full=True):
                        index = s_indices[idx + v]
                        index = cutlass.Int32(index)
                        topk_indices[v, i] = index
                        if cutlass.const_expr(self.return_val):
                            topk_vals[v, i] = score[index]
            # [atom, rest_vec]
            mIndices_store = cute.tiled_divide(dst, (vecsize_out,))
            if cutlass.const_expr(self.return_val):
                mValues_store = cute.tiled_divide(dst_values, (vecsize_out,))
            # i represents the index of the vector in the output.
            for i in cutlass.range(cute.size(topk_vals.shape, [1]), unroll_full=True):
                col = i * self.num_threads_per_cta + tidx % self.num_threads_per_cta
                if col < self.top_k // vecsize_out:
                    cute.autovec_copy(topk_indices[None, i], mIndices_store[None, col])
                    if cutlass.const_expr(self.return_val):
                        cute.autovec_copy(topk_vals[None, i], mValues_store[None, col])

    def _get_tiled_copy(self):
        threads_per_row = self.num_threads_per_cta
        if cutlass.const_expr(self.dtype == cutlass.Float32):
            threshold_elems = 32768
        elif cutlass.const_expr(
            self.dtype == cutlass.Float16 or self.dtype == cutlass.BFloat16
        ):
            threshold_elems = 65536
        else:
            raise ValueError(f"Unsupported dtype: {self.dtype}")

        # vectorized load part
        aligned_size = (self.num_cols // self.vec_size) * self.vec_size
        vecs_per_thread = cute.ceil_div(
            cute.ceil_div(min(aligned_size, threshold_elems), self.vec_size),
            threads_per_row,
        )
        tiler_mn = (
            1,
            self.vec_size * vecs_per_thread * threads_per_row,
        )

        copy_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            self.dtype,
            num_bits_per_copy=self.num_copy_bits,
        )

        thr_layout = cute.make_ordered_layout(
            (1, threads_per_row),
            order=(1, 0),
        )
        val_layout = cute.make_layout((1, self.vec_size))
        tiled_copy = cute.make_tiled_copy_tv(copy_atom, thr_layout, val_layout)

        # left scarlar load part
        left_size = self.num_cols - aligned_size
        return (
            copy_atom,
            tiled_copy,
            tiler_mn,
            aligned_size,
            left_size,
        )

    @cute.jit
    def predicate_k(self, tAcA: cute.Tensor, limit: cutlass.Int32) -> cute.Tensor:
        tApA = cute_ext.allocate(
            cutlass.Int8,
            cutlass.AddressSpace.rmem,
            cute.make_layout(
                (
                    cute.size(tAcA, mode=[0, 1]),
                    cute.size(tAcA, mode=[1]),
                    cute.size(tAcA, mode=[2]),
                    cute.size(tAcA, mode=[3]),
                ),
                stride=(cute.size(tAcA, mode=[2]), 0, 1, cute.size(tAcA, mode=[2])),
            ),
            alignment=32,
        )
        for rest_v in cutlass.range_constexpr(tApA.shape[0]):
            for rest_k in cutlass.range_constexpr(tApA.shape[2]):
                for rest_t in cutlass.range_constexpr(tApA.shape[3]):
                    tApA[rest_v, 0, rest_k, rest_t] = cute.elem_less(
                        tAcA[(0, rest_v), 0, rest_k, rest_t][1], limit
                    )
        return tApA

    @cute.jit
    def _fill_oob(
        self, tXrX: cute.Tensor, tXpX: cute.Tensor, fill_value: cute.Numeric
    ) -> None:
        """Fill out-of-bounds values in register tensor.

        Args:
            tXrX: Register tensor to fill
            tXpX: Predicate tensor indicating valid elements
            fill_value: Value to fill OOB locations with
        """
        tXrX_fill = cute_ext.allocate(
            tXrX.element_type,
            cutlass.AddressSpace.rmem,
            tXrX[(None, 0), None, 0].layout,
            alignment=32,
        )
        tXrX_fill.fill(fill_value)
        for rest_v in cutlass.range_constexpr(tXrX.shape[0][1]):
            for rest_k in cutlass.range_constexpr(tXrX.shape[2]):
                if cutlass.const_expr(tXpX is not None):
                    if not tXpX[0, rest_v, rest_k]:
                        cute.autovec_copy(tXrX_fill, tXrX[(None, rest_v), None, rest_k])

    @cute.jit
    def __call__(
        self, input_values, output_indices, output_values, stream: cuda.CUstream
    ):
        """Host function for the filtered topk kernel"""
        num_rows = input_values.shape[0]
        # each cta processes one row of input.
        blocks = (num_rows, 1, 1)
        (
            copy_atom,
            tiled_copy,
            tiler_mn,
            aligned_size,
            left_size,
        ) = self._get_tiled_copy()
        self.filtered_topk_kernel(
            input_values,
            output_indices,
            output_values,
            tiler_mn,
            copy_atom,
            tiled_copy,
            aligned_size,
            left_size,
        ).launch(
            grid=blocks,
            block=(tiled_copy.size, 1, 1),
            stream=stream,
        )
        return



def run_filtered_topk(
    dtype: Type[cutlass.Numeric],
    num_rows,
    num_cols,
    top_k,
    num_copy_bits=256,
    do_ref_check=True,
    do_benchmark=False,
    warmup_iterations=10,
    iterations=100,
    use_cold_l2=True,
    print_verbose=True,
):
    """
    Prepare input tensors, launch GPU kernel, and reference checking.
    """
    if print_verbose:
        print("=" * 60)
        print("Launching Blackwell Filtered TopK Test")
        print("-" * 60)
        print(f"Data Types & Precision: {dtype}")
        print(f"    Input matrix: {dtype}")
        print(f"    Output indices: {cutlass.Int32}")
        print(f"    Output values: {dtype}")
        print(
            f"Input dimensions (num_rows, num_cols, top_k): {num_rows, num_cols, top_k}"
        )
        print(f"    num_rows: {num_rows}")
        print(f"    num_cols: {num_cols}")
        print(f"    top_k: {top_k}")
        print(f"Do reference checking: {do_ref_check}")
        print(f"Do benchmark: {do_benchmark}")
        print(f"Warmup iterations: {warmup_iterations}")
        print(f"Iterations: {iterations}")
        print(f"Use cold L2: {use_cold_l2}")
        print("=" * 60)

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Create fake tensors for compilation
    n = cute.sym_int()

    # We need to pad the input tensor so that each row can be aligned to vec_size and could use vectorized copy.
    vec_size = num_copy_bits // dtype.width
    num_cols_padded = (num_cols + vec_size - 1) // vec_size * vec_size
    # print(f"num_cols_padded = {num_cols_padded}")
    input_fake = cute.runtime.make_fake_compact_tensor(
        dtype, (n, num_cols_padded), stride_order=(1, 0), assumed_align=32
    )
    output_indices_fake = cute.runtime.make_fake_compact_tensor(
        cutlass.Int32,
        (n, top_k),
        stride_order=(1, 0),
    )
    output_values_fake = cute.runtime.make_fake_compact_tensor(
        dtype,
        (n, top_k),
        stride_order=(1, 0),
    )
    fake_stream = cute.runtime.make_fake_stream()

    filtered_topk_func = FilteredTopKKernel(
        dtype, num_cols, top_k, num_copy_bits=num_copy_bits
    )

    # Compile the kernel
    compiled_kernel = cute.compile(
        filtered_topk_func,
        input_fake,
        output_indices_fake,
        output_values_fake,
        stream=fake_stream,
    )

    # Run with torch tensors
    input_torch = torch.randn(
        num_rows, num_cols_padded, dtype=torch_dtype(dtype), device="cuda"
    )
    # put -inf to the padded part
    input_torch[:, num_cols:] = -float("inf")

    output_indices_torch = torch.empty(
        num_rows, top_k, dtype=torch.int32, device="cuda"
    )
    output_values_torch = torch.empty(
        num_rows, top_k, dtype=torch_dtype(dtype), device="cuda"
    )

    compiled_kernel(
        input_torch, output_indices_torch, output_values_torch, current_stream
    )

    if do_ref_check and top_k <= num_cols:
        torch.cuda.synchronize()

        torch_res_values, torch_res_indices = torch.topk(
            input_torch.cpu(), top_k, dim=1
        )

        output_val_sorted = torch.sort(
            output_values_torch.cpu(), dim=1, descending=True
        ).values
        output_val_ref_sorted = torch.sort(
            torch_res_values, dim=1, descending=True
        ).values

        assert torch.allclose(
            output_val_sorted, output_val_ref_sorted, rtol=1e-5, atol=1e-5
        )
        if print_verbose:
            print("PASSED")

    if do_benchmark:

        def generate_inputs():
            input_tensor = torch.randn(
                num_rows, num_cols, dtype=torch_dtype(dtype), device="cuda"
            )
            output_indices_tensor = torch.empty(
                num_rows, top_k, dtype=torch.int32, device="cuda"
            )
            output_values_tensor = torch.empty(
                num_rows, top_k, dtype=torch_dtype(dtype), device="cuda"
            )
            return cutlass.testing.JitArguments(
                input_tensor,
                output_indices_tensor,
                output_values_tensor,
                current_stream,
            )

        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                input_torch.numel() * input_torch.element_size()
                + output_indices_torch.numel() * output_indices_torch.element_size()
                + output_values_torch.numel() * output_values_torch.element_size()
            )
            workspace_count = cutlass.testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )
        time = cutlass.testing.benchmark(
            compiled_kernel,
            workspace_generator=generate_inputs,
            workspace_count=workspace_count,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=True,
            stream=current_stream,
        )
        if print_verbose:
            print(f"Time: {time} us")
        print(f"{dtype}-{num_rows}-{num_cols}-{top_k} {time}")
    torch.cuda.synchronize()


def run_topk(
    dtype: Type[cutlass.Numeric],
    num_rows: int,
    num_cols: int,
    top_k: int,
    num_copy_bits: int = 256,
    do_ref_check: bool = True,
    do_benchmark: bool = False,
    warmup_iterations: int = 10,
    iterations: int = 100,
    use_cold_l2: bool = True,
):
    run_filtered_topk(
        dtype,
        num_rows,
        num_cols,
        top_k,
        num_copy_bits,
        do_ref_check,
        do_benchmark,
        warmup_iterations,
        iterations,
        use_cold_l2,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Sm100 Dense BlockScaled GEMM."
    )
    parser.add_argument(
        "--dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        choices=[cutlass.Float32, cutlass.Float16, cutlass.BFloat16],
        help="Data type of the input matrix",
    )
    parser.add_argument(
        "--num_rows",
        type=int,
        default=8,
        help="num_rows",
    )
    parser.add_argument("--num_cols", type=int, default=4096, help="num_cols")
    parser.add_argument("--top_k", type=int, default=2048, help="top_k")
    parser.add_argument(
        "--num_copy_bits",
        type=int,
        default=256,
        help="num_copy_bits, used for vectorization",
    )
    parser.add_argument(
        "--do_ref_check",
        action="store_true",
        default=False,
        help="Do reference checking",
    )
    parser.add_argument(
        "--do_benchmark", action="store_true", default=False, help="Do benchmark test"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=10, help="Warmup iterations"
    )
    parser.add_argument("--iterations", type=int, default=100, help="Iterations")
    parser.add_argument(
        "--use_cold_l2", action="store_true", default=True, help="Use cold L2"
    )

    args = parser.parse_args()
    if args.top_k % 2 != 0:
        parser.error("top_k must be a multiple of 2 (got top_k={})".format(args.top_k))

    run_topk(
        dtype=args.dtype,
        num_rows=args.num_rows,
        num_cols=args.num_cols,
        top_k=args.top_k,
        num_copy_bits=args.num_copy_bits,
        do_ref_check=args.do_ref_check,
        do_benchmark=args.do_benchmark,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        use_cold_l2=args.use_cold_l2,
    )
