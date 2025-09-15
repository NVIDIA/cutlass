import os
import torch
import argparse
from typing import Type
from cuda.bindings import driver

import torch.distributed as dist
import torch.distributed._symmetric_memory as symm_mem
import torch.multiprocessing as mp

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


def setup(rank, world_size):
    # set environment variables for torch.distributed environment
    os.environ["MASTER_ADDR"] = "localhost"
    os.environ["MASTER_PORT"] = "12995"
    dist.init_process_group("nccl", rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)


def cleanup():
    dist.destroy_process_group()


@cute.kernel
def vector_add_kernel(
    g0: cute.Tensor,
    g1: cute.Tensor,
    g2: cute.Tensor,
    g3: cute.Tensor,
    g4: cute.Tensor,
    g5: cute.Tensor,
    g6: cute.Tensor,
    g7: cute.Tensor,
    gOut: cute.Tensor,
    tv_layout: cute.Layout,
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    cta_coord = (None, bidx)
    local_tile_out = gOut[cta_coord]
    local_tile_list = [
        g0[cta_coord],
        g1[cta_coord],
        g2[cta_coord],
        g3[cta_coord],
        g4[cta_coord],
        g5[cta_coord],
        g6[cta_coord],
        g7[cta_coord],
    ]

    copy_atom_load = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        g0.element_type,
        memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        memory_scope=cute.nvgpu.common.MemoryScope.SYS,
    )
    copy_atom_store = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        g0.element_type,
        memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        memory_scope=cute.nvgpu.common.MemoryScope.SYS,
    )
    tiled_copy = cute.make_tiled_copy_tv(copy_atom_load, tv_layout[0], tv_layout[1])
    thr_copy = tiled_copy.get_slice(tidx)

    thr_tensor_list = [thr_copy.partition_S(tensor) for tensor in local_tile_list]
    thr_out = thr_copy.partition_D(local_tile_out)
    frg_tensor_list = [cute.make_fragment_like(tensor) for tensor in thr_tensor_list]
    frg_acc = cute.make_fragment_like(thr_out)
    frg_acc.fill(0.0)

    for thr, frg in zip(thr_tensor_list, frg_tensor_list):
        cute.copy(copy_atom_load, thr, frg)
        tmp = frg.load() + frg_acc.load()
        frg_acc.store(tmp)

    cute.copy(copy_atom_store, frg_acc, thr_out)


@cute.jit
def vector_add(
    m0: cute.Tensor,
    m1: cute.Tensor,
    m2: cute.Tensor,
    m3: cute.Tensor,
    m4: cute.Tensor,
    m5: cute.Tensor,
    m6: cute.Tensor,
    m7: cute.Tensor,
    output: cute.Tensor,
):
    # define constants for future use
    num_of_elements = cute.size(m0.layout)
    # 128 threads per block and 4 elements per thread
    tv_layout = cute.make_layout(((128), (4)), stride=((1), (1)))
    tile = cute.size(tv_layout.shape)

    tensors = [m0, m1, m2, m3, m4, m5, m6, m7]
    divided_tensors = [
        cute.zipped_divide(tensor, cute.make_layout(tile)) for tensor in tensors
    ]
    gOut = cute.zipped_divide(output, cute.make_layout(tile))  # ((Tile),(Rest))
    vector_add_kernel(
        divided_tensors[0],
        divided_tensors[1],
        divided_tensors[2],
        divided_tensors[3],
        divided_tensors[4],
        divided_tensors[5],
        divided_tensors[6],
        divided_tensors[7],
        gOut,
        tv_layout,
    ).launch(
        grid=[num_of_elements // tile, 1, 1],
        block=[tv_layout.shape[0], 1, 1],
    )


def run_vector_add(rank, world_size, M, N, dtype: Type[cutlass.Numeric]):
    setup(rank, world_size)

    t = symm_mem.empty(M * N, device="cuda")
    hdl = symm_mem.rendezvous(t, dist.group.WORLD)
    # get tensors from other devices from the symmetric memory
    tensor_list = [hdl.get_buffer(rank, t.shape, t.dtype) for rank in range(world_size)]
    tensor_list[rank].random_(0, 100)

    # enable peer access
    driver.cuInit(0)
    dev_list = [driver.cuDeviceGet(i)[1] for i in range(world_size)]
    ctx_list = [driver.cuDevicePrimaryCtxRetain(dev)[1] for dev in dev_list]
    driver.cuCtxSetCurrent(ctx_list[rank])
    for i in range(world_size):
        if i == rank:
            continue
        driver.cuCtxEnablePeerAccess(ctx_list[i], 0)

    output = torch.zeros(M * N, device=f"cuda:{rank}")

    # we have to explicitly pass each tensor instead of a list of tensors
    vector_add(
        from_dlpack(tensor_list[0], assumed_align=32),
        from_dlpack(tensor_list[1], assumed_align=32),
        from_dlpack(tensor_list[2], assumed_align=32),
        from_dlpack(tensor_list[3], assumed_align=32),
        from_dlpack(tensor_list[4], assumed_align=32),
        from_dlpack(tensor_list[5], assumed_align=32),
        from_dlpack(tensor_list[6], assumed_align=32),
        from_dlpack(tensor_list[7], assumed_align=32),
        from_dlpack(output, assumed_align=32),
    )

    sum_tensor = sum([tensor.cpu() for tensor in tensor_list])

    if sum(sum_tensor.cpu() == output.cpu()) == sum_tensor.numel():
        print("test passed")
    else:
        print("test failed")
        print(sum_tensor.cpu())
        print(output.cpu())

    cleanup()


def main():

    world_size = torch.cuda.device_count()
    M = 1024
    N = 1024

    # each process will run run_vector_add on different device
    mp.spawn(
        run_vector_add,
        args=(world_size, M, N, cutlass.Float32),
        nprocs=world_size,
        join=True,
    )

    return


if __name__ == "__main__":
    main()
