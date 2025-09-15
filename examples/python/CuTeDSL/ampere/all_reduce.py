import os
import torch
import argparse
from cuda import cuda
from cuda.bindings import driver
from typing import Type

import torch.distributed as dist
import torch.distributed._symmetric_memory as symm_mem
import torch.multiprocessing as mp

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass._mlir.dialects import llvm, builtin, vector, arith

WORLD_SIZE = 8
PING_PONG_SIZE = 3


def setup(rank, world_size):
    # set environment variables for torch.distributed environment
    os.environ["MASTER_ADDR"] = "localhost"
    os.environ["MASTER_PORT"] = "12959"
    dist.init_process_group("nccl", rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)


def cleanup():
    dist.destroy_process_group()


class AllReduceKernel:

    @cute.jit
    def __call__(
        self,
        rank,
        signal,
        local_input: cute.Tensor,
        local_output: cute.Tensor,
        buffer0: cute.Tensor,
        buffer1: cute.Tensor,
        buffer2: cute.Tensor,
        buffer3: cute.Tensor,
        buffer4: cute.Tensor,
        buffer5: cute.Tensor,
        buffer6: cute.Tensor,
        buffer7: cute.Tensor,
        stream: cuda.CUstream,
    ):
        # define constants for future use
        num_of_elements = cute.size(local_input.layout)
        # 128 threads per block and 4 elements per thread
        tv_layout = cute.make_layout(((128), (4)), stride=((1), (1)))
        tile = cute.size(tv_layout.shape)

        buffers = [
            buffer0,
            buffer1,
            buffer2,
            buffer3,
            buffer4,
            buffer5,
            buffer6,
            buffer7,
        ]
        tiled_buffers = [
            cute.logical_divide(buffer, (tile, None, None)) for buffer in buffers
        ]

        tiled_input = cute.zipped_divide(local_input, cute.make_layout(tile))
        tiled_output = cute.zipped_divide(local_output, cute.make_layout(tile))
        self.kernel(
            tiled_buffers[0],
            tiled_buffers[1],
            tiled_buffers[2],
            tiled_buffers[3],
            tiled_buffers[4],
            tiled_buffers[5],
            tiled_buffers[6],
            tiled_buffers[7],
            tiled_input,
            tiled_output,
            tv_layout,
            cutlass.Int32(signal),
            cutlass.Int32(rank),
        ).launch(
            grid=[num_of_elements // tile, 1, 1],
            block=[tv_layout.shape[0], 1, 1],
            stream=stream,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        buffer0: cute.Tensor,
        buffer1: cute.Tensor,
        buffer2: cute.Tensor,
        buffer3: cute.Tensor,
        buffer4: cute.Tensor,
        buffer5: cute.Tensor,
        buffer6: cute.Tensor,
        buffer7: cute.Tensor,
        local_input: cute.Tensor,
        local_output: cute.Tensor,
        tv_layout: cute.Layout,
        signal: cutlass.Int32,
        rank: cutlass.Int32,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()
        ping = signal % 3
        pong = (signal + 1) % 3

        buffers = [
            buffer0,
            buffer1,
            buffer2,
            buffer3,
            buffer4,
            buffer5,
            buffer6,
            buffer7,
        ]

        def get_buffer():
            t = buffers[2]
            if rank == cutlass.Int32(0):
                t = buffers[0]
            if rank == cutlass.Int32(1):
                t = buffers[1]
            if rank == cutlass.Int32(2):
                t = buffers[2]
            if rank == cutlass.Int32(3):
                t = buffers[3]
            if rank == cutlass.Int32(4):
                t = buffers[4]
            if rank == cutlass.Int32(5):
                t = buffers[5]
            if rank == cutlass.Int32(6):
                t = buffers[6]
            if rank == cutlass.Int32(7):
                t = buffers[7]
            return t

        buffer_local = get_buffer()
        cta_coord = (None, bidx)
        local_tile_in = local_input[cta_coord]
        local_tile_out = local_output[cta_coord]

        ping_coord = ((None, bidx), None, ping)
        read_buffer = buffer_local[ping_coord]

        pong_coord = ((None, bidx), None, pong)
        clear_buffer = buffer_local[pong_coord]

        write_coord = ((None, bidx), rank, ping)
        write_buffers = [buffer[write_coord] for buffer in buffers]

        # assume all buffers have the same element type with input
        copy_atom_load = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            buffer0.element_type,
            num_bits_per_copy=64,
            memory_scope=cute.nvgpu.common.MemoryScope.SYS,
            memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        )
        copy_atom_store = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            buffer0.element_type,
            num_bits_per_copy=64,
            memory_scope=cute.nvgpu.common.MemoryScope.SYS,
            memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        )
        tiled_copy = cute.make_tiled_copy_tv(copy_atom_load, tv_layout[0], tv_layout[1])
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

        clear_tensor = frg_clear.load()
        frg_size = cute.size(clear_tensor.shape)
        neg0_i32_vec = cute.full_like(clear_tensor, 0x80000000, cutlass.Int32)
        neg0_f32_vec = vector.bitcast(T.vector(frg_size, T.f32()), neg0_i32_vec)
        neg0_f32_tensor = cute.TensorSSA(
            neg0_f32_vec, clear_tensor.shape, cutlass.Float32
        )
        frg_clear.store(neg0_f32_tensor)

        cute.copy(copy_atom_load, thr_in, frg_in)

        for thr_write_buffer in thr_write_buffer_list:
            cute.copy(copy_atom_store, frg_in, thr_write_buffer)

        cute.copy(copy_atom_store, frg_clear, thr_clear_buffer)

        frg_in_vector_neg0_i32 = cute.full_like(
            frg_in, cutlass.Int32(0x80000000), cutlass.Int32
        )
        frg_in_size = cute.size(frg_in.shape)

        for i in range(WORLD_SIZE):
            read_coord = (None, 0, i)
            cute.copy(copy_atom_load, thr_read_buffer[read_coord], frg_in[None, 0])
            frg_vector = frg_in.load()
            frg_vector_i32 = vector.bitcast(T.vector(frg_in_size, T.i32()), frg_vector)
            isNotNeg0 = cute.all_(frg_vector_i32 != frg_in_vector_neg0_i32)
            while not isNotNeg0:
                cute.copy(copy_atom_load, thr_read_buffer[read_coord], frg_in[None, 0])
                frg_vector = frg_in.load()
                frg_vector_i32 = vector.bitcast(
                    T.vector(frg_in_size, T.i32()), frg_vector
                )
                isNotNeg0 = cute.all_(frg_vector_i32 != frg_in_vector_neg0_i32)
            frg_acc.store(frg_in.load() + frg_acc.load())

        cute.copy(copy_atom_stg, frg_acc, thr_out)


def run_all_reduce(rank, M, N, dtype: Type[cutlass.Numeric]):
    setup(rank, WORLD_SIZE)

    input_tensor = torch.randn(M * N, device=f"cuda:{rank}")
    output_tensor = torch.zeros(M * N, device=f"cuda:{rank}")

    # init tensors on different devices
    t = symm_mem.empty(
        [
            PING_PONG_SIZE,
            WORLD_SIZE,
            M * N,
        ],
        device="cuda",
    ).neg_()
    hdl = symm_mem.rendezvous(t, dist.group.WORLD)
    buffer_tensor_list = [
        hdl.get_buffer(rank, t.shape, t.dtype).permute(2, 1, 0)
        for rank in range(WORLD_SIZE)
    ]

    # enable peer access
    driver.cuInit(0)
    dev_list = [driver.cuDeviceGet(i)[1] for i in range(WORLD_SIZE)]
    ctx_list = [driver.cuDevicePrimaryCtxRetain(dev)[1] for dev in dev_list]
    for i in range(WORLD_SIZE):
        driver.cuCtxSetCurrent(ctx_list[i])
        for j in range(WORLD_SIZE):
            if i == j:
                continue
            driver.cuCtxEnablePeerAccess(ctx_list[j], 0)
    driver.cuCtxSetCurrent(ctx_list[rank])

    stream = cutlass.cuda.default_stream()
    all_reduce_kernel = AllReduceKernel()
    dlpack_buffers = [from_dlpack(x, assumed_align=32) for x in buffer_tensor_list]
    all_reduce_kernel(
        rank,
        0,
        from_dlpack(input_tensor, assumed_align=32),
        from_dlpack(output_tensor, assumed_align=32),
        *dlpack_buffers,
        stream,
    )
    torch.cuda.synchronize(0)

    # use torch api to get reference and inplace stored to input_tensor
    ref_tensor = input_tensor.clone()
    dist.all_reduce(ref_tensor, op=dist.ReduceOp.SUM)

    # check result of output tensor, allow small error due to different accumulator datatypes
    equal_mask = (ref_tensor.cpu() - output_tensor.cpu()).abs() < 1e-4
    result = (equal_mask.sum()).item() == ref_tensor.numel()

    if result:
        print(f"rank {rank} test passed")
    else:
        print(f"rank {rank} test failed")
        print(
            "ref_tensor[ref_tensor != output_tensor]: ",
            ref_tensor[ref_tensor != output_tensor],
        )
        print(
            "output_tensor[ref_tensor != output_tensor]: ",
            output_tensor[ref_tensor != output_tensor],
        )

    cleanup()


def main():
    M = 1024
    N = 1024

    # each process will run run_all_reduce on different device
    mp.spawn(run_all_reduce, args=(M, N, cutlass.Float32), nprocs=WORLD_SIZE, join=True)

    return


if __name__ == "__main__":
    main()
