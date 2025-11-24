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
import time
import argparse

import numpy as np
import nvshmem.core
import torch
import torch.distributed as dist
from cuda.core.experimental import Device

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack


"""
A Distributed All-Reduce Addition Example using CuTe DSL and PyTorch Symmetric Memory.

This example kernel demonstrates distributed all-reduce across multiple GPUs using the SIMT copy 
of CuTe DSL and PyTorch's symmetric memory feature. Basic CuTe layout calculation is derived
from the elementwise_add.py example.

This kernel is a simple version of all-reduce. It will directly copy data from remote memory to 
registers, then accumulate the data and finally store the accumulated data back to local global memory.
If the input tensors from each device are remotely accessible, then this kernel can be used to perform the all-reduce.

On the host side, we use `torch.distributed._symmetric_memory` to manage the symmetric memory. We use `symm_mem.empty`
and `symm_mem.rendezvous` to create a symmetric tensor. Then we use `get_buffer` to get tensors that are accessible from all devices.
In this way, we can hide the details of CUDA driver API calls to enable access to remote memory.

.. code-block:: python

    t = symm_mem.empty((M, N), device=torch.device(f"cuda:{rank}"))
    hdl = symm_mem.rendezvous(t, dist.group.WORLD)
    # get tensors from other devices from the symmetric memory
    tensor_list = [hdl.get_buffer(rank, t.shape, t.dtype) for rank in range(world_size)]

To run this example:

.. code-block:: bash

    torchrun --nproc-per-node 8  examples/distributed/all_reduce_simple.py --M 1024 --N 512
    torchrun --nproc-per-node 8  examples/distributed/all_reduce_simple.py \
        --M 1024 --N 1024 --benchmark --warmup_iterations 2 --iterations 100
"""


@cute.kernel
def all_reduce_simple_kernel(
    inputs: list[cute.Tensor],
    gOut: cute.Tensor,
    thr_layout: cute.Layout,
    val_layout: cute.Layout,
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    # slice for CTAs
    # logical id -> address
    blk_coord = ((None, None), bidx)
    local_tile_out = gOut[blk_coord]
    local_tile_list = [t[blk_coord] for t in inputs]

    assert all(t.element_type == inputs[0].element_type for t in inputs)

    copy_atom_load = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        inputs[0].element_type,
    )
    copy_atom_store = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        inputs[0].element_type,
    )
    tiled_copy = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
    thr_copy = tiled_copy.get_slice(tidx)

    thr_tensor_list = [thr_copy.partition_S(tensor) for tensor in local_tile_list]
    thr_out = thr_copy.partition_D(local_tile_out)
    frg_tensor_list = [cute.make_fragment_like(tensor) for tensor in thr_tensor_list]
    frg_acc = cute.make_fragment_like(thr_out)
    frg_acc.fill(0.0)

    # load the frg at the same offset from all devices and accumulate the result in frg_acc
    for thr, frg in zip(thr_tensor_list, frg_tensor_list):
        cute.copy(copy_atom_load, thr, frg)
        tmp = frg.load() + frg_acc.load()
        frg_acc.store(tmp)

    # copy from register memory to global memory
    cute.copy(copy_atom_store, frg_acc, thr_out)


@cute.jit
def all_reduce_simple(
    inputs: list[cute.Tensor], output: cute.Tensor, copy_bits: cutlass.Constexpr = 128
):
    dtype = inputs[0].element_type
    vector_size = copy_bits // dtype.width

    thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
    val_layout = cute.make_ordered_layout((4, vector_size), order=(1, 0))
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

    divided_inputs = [cute.zipped_divide(tensor, tiler_mn) for tensor in inputs]
    gOut = cute.zipped_divide(output, tiler_mn)  # ((Tile),(Rest))
    all_reduce_simple_kernel(
        divided_inputs,
        gOut,
        thr_layout,
        val_layout,
    ).launch(
        grid=[cute.size(gOut, mode=[1]), 1, 1],
        block=[cute.size(tv_layout, mode=[0]), 1, 1],
    )


def run_all_reduce_simple(
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

    local_tensor = nvshmem.core.tensor((M, N), dtype=torch.float32)
    local_tensor.random_(0, 100)
    tensor_list = [nvshmem.core.get_peer_tensor(local_tensor, rank) for rank in range(world_size)]
    output = torch.zeros((M, N), device=f"cuda:{rank}")
    
    if rank == 0:
        print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    compiled_func = cute.compile(all_reduce_simple, [from_dlpack(t) for t in tensor_list], from_dlpack(output))
    compilation_time = time.time() - start_time
    if rank == 0:
        print(f"Compilation time: {compilation_time:.4f} seconds")
        print("Executing vector add kernel...")

    if not skip_ref_check:
        dist.barrier(device_ids=[rank])
        compiled_func([from_dlpack(t) for t in tensor_list], from_dlpack(output))
        if rank == 0:
            print("Verifying results...")
        dist.barrier(device_ids=[rank])
        torch.testing.assert_close(sum([t.cpu() for t in tensor_list]), output.cpu())
        if rank == 0:
            print("Results verified successfully!")
    
    for t in tensor_list:
        nvshmem.core.free_tensor(t)

    if not benchmark:
        return

    free_func_and_tensor_pairs = []
    def add_free_func_and_tensor(free_func, tensor):
        free_func_and_tensor_pairs.append((free_func, tensor))

    def generate_tensors():
        local_tensor = nvshmem.core.tensor((M, N), dtype=torch.float32)
        local_tensor.random_(0, 100)
        tensor_list = [nvshmem.core.get_peer_tensor(local_tensor, rank) for rank in range(world_size)]
        output = torch.zeros((M, N), device=f"cuda:{rank}")

        ja = testing.JitArguments(
            [from_dlpack(t) for t in tensor_list],
            from_dlpack(output),
        )
        for tensor in tensor_list:
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
            f"Achieved memory throughput: {((world_size + 1) * output.numel() * 32 // 8) / (avg_time_us / 1e6) / 1e9:.2f} GB/s"
        )
        print(f"First few elements of result: \n{output[:3, :3]}")

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

    run_all_reduce_simple(args.M, args.N, args.warmup_iterations, args.iterations, args.skip_ref_check, args.benchmark)

    torchrun_finalize()

    return


if __name__ == "__main__":
    main()
