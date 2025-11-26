# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import os
import torch
import argparse

import numpy as np
import torch.distributed as dist
import torch.distributed._symmetric_memory as symm_mem
import cuda.bindings.driver as cuda
from cuda.core.experimental import Device
from cuda.pathfinder import load_nvidia_dynamic_lib

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import T
from cutlass._mlir.dialects import vector

try:
    import nvshmem.core
except ImportError as exc:
    raise ImportError(
        "nvshmem4py is required but not installed. Please install it using:\n"
        "  For CUDA 12: pip install nvshmem4py-cu12\n"
        "  For CUDA 13: pip install nvshmem4py-cu13\n"
        "Note: nvshmem4py version >= 0.1.3 is recommended."
    ) from None

try:
    load_nvidia_dynamic_lib("nvshmem_host")
except RuntimeError as exc:
    raise ImportError(
        "nvshmem lib is required but not installed. Please install it using:\n"
        "  For CUDA 12: pip install nvidia-nvshmem-cu12\n"
        "  For CUDA 13: pip install nvidia-nvshmem-cu13\n"
    ) from None

"""
A Distributed One-Shot All-Reduce Example using CuTe DSL and fine-grained memory control. This is a mirrored version of the 
existing tensorrt_llm kernel:
https://github.com/NVIDIA/TensorRT-LLM/blob/main/cpp/tensorrt_llm/kernels/communicationKernels/allReduceFusionKernels.cu

This example kernel demonstrates a one-shot all-reduce operation using the CuTe DSL with fine-grained memory control.
It uses dedicated communication buffers for data exchange, and these buffers act as ping-pong buffers. During the 
process, the kernel uses one buffer for communication and initializes the next buffer to all negative zeros.

In this kernel, each thread is only responsible for 128bits of data. The kernel will write it's local data to every
buffer at different ranks, then read the data from the local rank buffer. The buffer itself behaves as a barrier, 
if kernel read negtive 0, then it means data are not ready or not visible yet so that the kernel will read the data again.

If the input tensors from each device are not remotely accessible, this kernel can be used to perform the one-shot all-reduce 
since it uses communication buffers for data exchange.

The .SYS memory scope and .VOLATILE memory order are used to ensure that the data will be visible at the system scope.

.. code-block:: bash

    torchrun --nproc-per-node 8  examples/distributed/all_reduce_one_shot_lamport.py --M 8192 --N 8192
    torchrun --nproc-per-node 8  examples/distributed/all_reduce_one_shot_lamport.py \
        --M 8192 --N 8192 --benchmark --warmup_iterations 2 --iterations 10
"""


PING_PONG_SIZE = 3


class AllReduceOneShotLamportKernel:
    @cute.jit
    def __call__(
        self,
        rank: cutlass.Constexpr,
        world_size: cutlass.Constexpr,
        signal: cutlass.Int32,
        local_input: cute.Tensor,
        local_output: cute.Tensor,
        buffers: list[cute.Tensor],
        stream: cuda.CUstream,
    ):
        copy_bits = 128
        dtype = local_input.element_type
        vector_size = copy_bits // dtype.width

        thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
        val_layout = cute.make_ordered_layout((1, vector_size), order=(1, 0))
        tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

        grouped_buffers = [cute.group_modes(buffer, 0, 2) for buffer in buffers]
        tiled_buffers = [
            cute.zipped_divide(buffer, (tiler_mn, world_size, PING_PONG_SIZE))
            for buffer in grouped_buffers
        ]
        tiled_input = cute.zipped_divide(local_input, tiler_mn)
        tiled_output = cute.zipped_divide(local_output, tiler_mn)

        self.kernel(
            tiled_buffers,
            tiled_input,
            tiled_output,
            thr_layout,
            val_layout,
            signal,
            rank,
        ).launch(
            grid=[cute.size(tiled_input, mode=[1]), 1, 1],
            block=[cute.size(tv_layout, mode=[0]), 1, 1],
            stream=stream,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        buffers: list[cute.Tensor],
        local_input: cute.Tensor,
        local_output: cute.Tensor,
        thr_layout: cute.Layout,
        val_layout: cute.Layout,
        signal: cutlass.Int32,
        rank: cutlass.Constexpr,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()
        ping = signal % 3
        pong = (signal + 1) % 3

        buffer_local = buffers[rank]
        cta_coord = ((None, None), bidx)
        local_tile_in = local_input[cta_coord]
        local_tile_out = local_output[cta_coord]

        ping_coord = (((None, None), None, ping), bidx)
        pong_coord = (((None, None), None, pong), bidx)

        read_buffer = buffer_local[ping_coord]
        clear_buffer = buffer_local[pong_coord]

        write_coord = (((None, None), rank, ping), bidx)
        write_buffers = [buffer[write_coord] for buffer in buffers]

        # assume all buffers have the same element type with input
        copy_atom_load = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            buffers[0].element_type,
            num_bits_per_copy=128,
            memory_scope=cute.nvgpu.common.MemoryScope.SYS,
            memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        )
        copy_atom_store = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            buffers[0].element_type,
            num_bits_per_copy=128,
            memory_scope=cute.nvgpu.common.MemoryScope.SYS,
            memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        )
        tiled_copy = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
        thr_copy = tiled_copy.get_slice(tidx)

        thr_write_buffer_list = [
            thr_copy.partition_D(tensor) for tensor in write_buffers
        ]
        thr_read_buffer = thr_copy.partition_S(read_buffer)

        thr_clear_buffer = thr_copy.partition_D(clear_buffer)

        thr_in = thr_copy.partition_S(local_tile_in)
        thr_out = thr_copy.partition_D(local_tile_out)

        frg_in = cute.make_fragment_like(thr_in)
        frg_clear = cute.make_fragment_like(thr_clear_buffer)
        frg_acc = cute.make_fragment_like(thr_out)
        frg_acc.fill(0.0)

        # clear a next buffer to be all negtive 0
        clear_tensor = frg_clear.load()
        frg_size = cute.size(clear_tensor.shape)
        neg0_i32_vec = cute.full_like(clear_tensor, 0x80000000, cutlass.Int32)
        neg0_f32_vec = vector.bitcast(T.vector(frg_size, T.f32()), neg0_i32_vec)
        neg0_f32_tensor = cute.TensorSSA(
            neg0_f32_vec, clear_tensor.shape, cutlass.Float32
        )
        frg_clear.store(neg0_f32_tensor)
        cute.copy(copy_atom_store, frg_clear, thr_clear_buffer)

        # read local data to the register
        cute.copy(copy_atom_load, thr_in, frg_in)

        # write local data to every buffer at different ranks
        for thr_write_buffer in thr_write_buffer_list:
            cute.copy(copy_atom_store, frg_in, thr_write_buffer)

        frg_in_vector_neg0_i32 = cute.full_like(
            frg_in, cutlass.Int32(0x80000000), cutlass.Int32
        )
        frg_in_size = cute.size(frg_in.shape)

        # loop over each buffer and accumulate the data
        for i in cutlass.range_constexpr(len(buffers)):
            read_coord = (None, 0, 0, i)
            cute.copy(copy_atom_load, thr_read_buffer[read_coord], frg_in[None, 0, 0])
            frg_vector = frg_in.load()
            frg_vector_i32 = cute.TensorSSA(
                vector.bitcast(T.vector(frg_in_size, T.i32()), frg_vector),
                frg_in.shape,
                cutlass.Int32,
            )
            isNotNeg0 = cute.all_(
                cute.TensorSSA(
                    frg_vector_i32 != frg_in_vector_neg0_i32,
                    frg_in.shape,
                    cutlass.Boolean,
                )
            )
            # if the data is negtive 0, it means data are not ready or not visible yet, so we need to read the data again
            while not isNotNeg0:
                cute.copy(
                    copy_atom_load, thr_read_buffer[read_coord], frg_in[None, 0, 0]
                )
                frg_vector = frg_in.load()
                frg_vector_i32 = cute.TensorSSA(
                    vector.bitcast(T.vector(frg_in_size, T.i32()), frg_vector),
                    frg_in.shape,
                    cutlass.Int32,
                )
                isNotNeg0 = cute.all_(
                    cute.TensorSSA(
                        frg_vector_i32 != frg_in_vector_neg0_i32,
                        frg_in.shape,
                        cutlass.Boolean,
                    )
                )
            frg_acc.store(frg_in.load() + frg_acc.load())

        cute.copy(copy_atom_store, frg_acc, thr_out)


def run_all_reduce_one_shot(
    M,
    N,
    warmup_iterations=2,
    iterations=10,
    skip_ref_check=False,
    benchmark=True,
):
    rank = torch.distributed.get_rank()
    world_size = torch.distributed.get_world_size()
    if rank == 0:
        print("\nRunning Elementwise Add test with:")
        print(f"Tensor dimensions: [{M}, {N}]")
        print(f"GPU count: {world_size}")

    # init buffer tensors to be neg 0
    local_buffer_tensor = nvshmem.core.tensor([PING_PONG_SIZE, world_size, M, N,], dtype=torch.float32).neg_()
    buffer_tensor_list = [nvshmem.core.get_peer_tensor(local_buffer_tensor, rank).permute(2, 3, 1, 0) for rank in range(world_size)]
    signal = cutlass.Int32(0)
    input_tensor = torch.randn([M, N], device=f"cuda:{rank}")
    output_tensor = torch.zeros([M, N], device=f"cuda:{rank}")
    stream = cutlass.cuda.default_stream()
    all_reduce_one_shot_lamport_kernel = AllReduceOneShotLamportKernel()

    compiled_func = cute.compile(
        all_reduce_one_shot_lamport_kernel,
        rank,
        world_size,
        signal,
        from_dlpack(input_tensor, assumed_align=32),
        from_dlpack(output_tensor, assumed_align=32),
        [from_dlpack(t, assumed_align=32) for t in buffer_tensor_list],
        stream=stream,
    )

    if not skip_ref_check:
        compiled_func(
            signal,
            from_dlpack(input_tensor, assumed_align=32),
            from_dlpack(output_tensor, assumed_align=32),
            [from_dlpack(t, assumed_align=32) for t in buffer_tensor_list],
            stream,
        )
        if rank == 0:
            print("Verifying results...")
        dist.all_reduce(input_tensor, op=dist.ReduceOp.SUM)
        dist.barrier(device_ids=[rank])
        torch.testing.assert_close(input_tensor.cpu(), output_tensor.cpu())
        if rank == 0:
            print("Results verified successfully!")

    for t in buffer_tensor_list:
        nvshmem.core.free_tensor(t)

    if not benchmark:
        return

    free_func_and_tensor_pairs = []
    def add_free_func_and_tensor(free_func, tensor):
        free_func_and_tensor_pairs.append((free_func, tensor))

    def generate_tensors():
        local_buffer = nvshmem.core.tensor([PING_PONG_SIZE, world_size, M, N,], dtype=torch.float32).neg_()
        buffer_tensor_list = [nvshmem.core.get_peer_tensor(local_buffer, rank).permute(2, 3, 1, 0) for rank in range(world_size)]
        input_tensor = torch.randn([M, N], device=f"cuda:{rank}")
        output_tensor = torch.zeros([M, N], device=f"cuda:{rank}")

        ja = testing.JitArguments(
            cutlass.Int32(0),
            from_dlpack(input_tensor, assumed_align=32),
            from_dlpack(output_tensor, assumed_align=32),
            [from_dlpack(t, assumed_align=32) for t in buffer_tensor_list],
            stream=stream
        )
        for tensor in buffer_tensor_list:
            add_free_func_and_tensor(nvshmem.core.free_tensor, tensor)
        
        return ja
    avg_time_us = testing.benchmark(
        compiled_func,
        workspace_generator=generate_tensors,
        workspace_count=10,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    # Print execution results
    if rank == 0:
        print(f"Kernel execution time: {avg_time_us / 1e3:.4f} ms")
        print(
            f"Achieved memory throughput: {((world_size + 1) * output_tensor.numel() * 32 // 8) / (avg_time_us / 1e6) / 1e9:.2f} GB/s"
        )

    for free_func, tensor in free_func_and_tensor_pairs:
        free_func(tensor)

def torchrun_uid_init_bcast():
    """
    Initialize NVSHMEM using UniqueID with `torchrun` as the launcher

    It uses torch.distributed.broadcast on a NumPy array to handle the broadcasting
    """
    # Set Torch device
    local_rank = int(os.environ['LOCAL_RANK'])
    torch.cuda.set_device(local_rank)

    # nvshmem4py requires a cuda.core Device at init time
    dev = Device(local_rank)
    dev.set_current()
    global stream
    stream = dev.create_stream()

    # Initialize torch.distributed process group
    dist.init_process_group(
        backend="cpu:gloo,cuda:nccl",
    )

    # Extract rank, nranks from process group
    num_ranks = dist.get_world_size()

    # Create an empty uniqueid for all ranks
    uid = nvshmem.core.get_unique_id(empty=(local_rank != 0))
    uid_bytes = uid._data.view(np.uint8).copy()
    uid_tensor = torch.from_numpy(uid_bytes).cuda()
    dist.broadcast(uid_tensor, src=0)
    dist.barrier()
    uid._data[:] = uid_tensor.cpu().numpy().view(uid._data.dtype)

    nvshmem.core.init(device=dev, uid=uid, rank=local_rank, nranks=num_ranks, initializer_method="uid")


def torchrun_finalize():
    nvshmem.core.finalize()
    dist.destroy_process_group()


def main():
    parser = argparse.ArgumentParser(
        description="example of elementwise add to demonstrate the numpy/pytorch as input for kernels"
    )
    parser.add_argument("--M", default=1024, type=int)
    parser.add_argument("--N", default=1024, type=int)
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=10, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--benchmark", action="store_true")
    args = parser.parse_args()

    torchrun_uid_init_bcast()

    run_all_reduce_one_shot(args.M, args.N, args.warmup_iterations, args.iterations, args.skip_ref_check, args.benchmark)

    torchrun_finalize()

    return


if __name__ == "__main__":
    main()
