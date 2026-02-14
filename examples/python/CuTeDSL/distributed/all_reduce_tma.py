# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
A Distributed All-Reduce Example using TMA (Tensor Memory Accelerator).

This example demonstrates distributed all-reduce across multiple GPUs using TMA
for data movement. It serves as a tutorial for TMA-based distributed operations,
not as a performance-optimized implementation.

Tensor Semantics:
    - Input:  Logical shape (world_size, S), where S is the per-rank tensor size
    - Output: Logical shape (world_size, S), each rank gets the sum of all inputs

Kernel Parameters:
    - input:  List of world_size tensors, each with shape S (accessible via NVSHMEM)
    - output: Single tensor with shape S, using multicast address for broadcast

Algorithm (Two-Shot):
    1. Each CTA loads data from all ranks at its assigned tile position (TMA Load)
    2. Accumulates the data locally in registers
    3. Stores the result via TMA multicast (broadcasts to all ranks)
    4. Cross-GPU barrier ensures completion before kernel exit

Tile Assignment:
    - Total tiles = ceil(S / elems_per_cta)
    - Each rank processes ceil(total_tiles / world_size) CTAs
    - CTA i on rank r processes global_tile_id = r * ctas_per_rank + i

TMA Usage Notes (for tutorial purposes, not perf-optimal):
    - Uses 1D TMA load to load from remote GPU memory via NVSHMEM addresses
    - Uses 1D TMA load to store to multicast address for broadcasting to all ranks
    - Supports any input shape by flattening to 1D and tiling linearly
    - Pipeline with 2 stages overlaps TMA loads across ranks

To run this example:

.. code-block:: bash

    torchrun --nproc-per-node 8 examples/distributed/all_reduce_tma.py --shape 1024,1024
    torchrun --nproc-per-node 8 examples/distributed/all_reduce_tma.py --shape 4,6,8,10,12
"""

import cutlass
import cutlass.utils as utils
import cutlass.cute as cute
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync


class AllReduceTmaKernel:
    """
    TMA-based distributed All-Reduce kernel.

    This kernel performs an all-reduce operation across multiple GPUs using TMA
    (Tensor Memory Accelerator) for efficient data movement.

    Algorithm (Two-Shot):
        1. Each CTA loads data from all ranks at its assigned tile position
        2. Accumulates the data locally in registers
        3. Stores the result via TMA multicast (broadcasts to all ranks)
        4. Cross-GPU barrier ensures completion before kernel exit

    The input/output tensors can be of any rank, as long as:
        - All input tensors and output tensor share the same layout
        - The layout is compact (no holes in memory)

    We traverse the tensors linearly in codomain (physical offset) order,
    which guarantees consistent logical coordinate access across all tensors.
    """

    _elems_per_cta: int = 128 * 128  # Elements processed per CTA
    _tma_threads: int = 32
    _consumer_threads: int = 128
    _threads_per_cta: int = _tma_threads + _consumer_threads
    _num_stages: int = 2

    def __init__(self, dtype):
        self.dtype = dtype

        # SMEM layout shape (will be converted to Layout in JIT context)
        self.smem_layout_shape = (self._elems_per_cta,)
        self.tiler = (self._elems_per_cta,)

        # TMA transaction bytes (computed from dtype size)
        # dtype.width is in bits, divide by 8 to get bytes
        self.tma_bytes = (dtype.width // 8) * self._elems_per_cta

        # Dynamically create SharedStorage type based on dtype
        elems = self._elems_per_cta
        stages = self._num_stages

        @cute.struct
        class SharedStorage:
            mbar_array: cute.struct.MemRange[cutlass.Int64, stages * 2]
            smem_buffer: cute.struct.Align[
                cute.struct.MemRange[dtype, elems * stages],  # stages 个 tile
                128,
            ]

        self._SharedStorage = SharedStorage

    @cute.jit
    def __call__(
        self,
        input_tensors: list[cute.Tensor],
        output_tensor_mc: cute.Tensor,
        flag: cute.Tensor,
        flag_mc: cute.Tensor,
        local_rank: cutlass.Constexpr,
        world_size: cutlass.Constexpr,
    ):
        """
        Host-side JIT function: creates TMA descriptors and launches kernel.

        Args:
            input_tensors: List of input tensors from each rank (world_size tensors)
            output_tensor_mc: Output tensor with multicast address
            flag: Synchronization flag (local view)
            flag_mc: Synchronization flag (multicast view)
            local_rank: This rank's ID
            world_size: Total number of ranks
        """
        # ======================================================================
        # Layout validation
        # ======================================================================
        ref_layout = input_tensors[0].layout
        ref_size = cute.size(ref_layout)
        ref_cosize = cute.cosize(ref_layout)

        # Check compact: size == cosize (no holes in memory)
        assert ref_size == ref_cosize, (
            f"Input tensor must be compact: size={ref_size}, cosize={ref_cosize}"
        )
        assert self.tma_bytes % 16 == 0, f"Not aligned to 16B, TMA should not be used."

        # Check all input tensors have the same layout
        for i in cutlass.range_constexpr(world_size):
            assert input_tensors[i].layout == ref_layout, (
                f"All input tensors must have the same layout. "
                f"input_tensors[0].layout={ref_layout}, "
                f"input_tensors[{i}].layout={input_tensors[i].layout}"
            )

        # Check output tensor has the same layout
        assert output_tensor_mc.layout == ref_layout, (
            f"Output tensor must have the same layout as input tensors. "
            f"input layout={ref_layout}, output layout={output_tensor_mc.layout}"
        )

        # ======================================================================
        # Extract tensor info
        # ======================================================================
        # Verify dtype matches
        assert input_tensors[0].element_type == self.dtype, (
            f"Input tensor dtype mismatch: expected {self.dtype}, "
            f"got {input_tensors[0].element_type}"
        )

        total_elems = ref_size

        # Flatten layout: treat tensor as 1D in codomain order
        flat_layout = cute.make_layout((total_elems,))

        # SMEM layout (created in JIT context)
        smem_layout = cute.make_layout(self.smem_layout_shape)

        # Create TMA load descriptors (one per rank)
        tma_load_op = cpasync.CopyBulkTensorTileG2SOp()
        tma_load_atoms = []
        tma_load_tensors = []

        for i in cutlass.range_constexpr(world_size):
            flat_input = cute.make_tensor(input_tensors[i].iterator, flat_layout)
            tma_atom, tma_tensor = cpasync.make_tiled_tma_atom(
                tma_load_op,
                flat_input,
                smem_layout,
                self.tiler,
            )
            tma_load_atoms.append(tma_atom)
            tma_load_tensors.append(tma_tensor)

        # Create TMA store descriptor
        tma_store_op = cpasync.CopyBulkTensorTileS2GOp()
        flat_output = cute.make_tensor(output_tensor_mc.iterator, flat_layout)
        tma_store_atom, tma_store_tensor = cpasync.make_tiled_tma_atom(
            tma_store_op,
            flat_output,
            smem_layout,
            self.tiler,
        )

        # Grid calculation
        num_tiles_total = cute.ceil_div(total_elems, self._elems_per_cta)
        ctas_per_rank = cute.ceil_div(num_tiles_total, world_size)

        # SMEM size from SharedStorage
        smem_bytes = self._SharedStorage.size_in_bytes()

        # Launch kernel
        self.kernel(
            tma_load_atoms,
            tma_load_tensors,
            tma_store_atom,
            tma_store_tensor,
            flag,
            flag_mc,
            local_rank,
            world_size,
            num_tiles_total,
            ctas_per_rank,
        ).launch(
            grid=[ctas_per_rank, 1, 1],
            block=[self._threads_per_cta, 1, 1],
            smem=smem_bytes,
        )

    @cute.kernel
    def kernel(
        self,
        # TMA atoms and tensors for loading from each rank
        tma_load_atoms: list[cute.CopyAtom],
        tma_load_tensors: list[cute.Tensor],
        # TMA atom and tensor for storing to multicast address
        tma_store_atom: cute.CopyAtom,
        tma_store_tensor: cute.Tensor,
        # Synchronization flags
        flag: cute.Tensor,
        flag_mc: cute.Tensor,
        # Rank info
        local_rank: cutlass.Constexpr,
        world_size: cutlass.Constexpr,
        # Grid info for tile calculation
        num_tiles_total: cutlass.Constexpr,
        ctas_per_rank: cutlass.Constexpr,
    ):
        # ======================================================================
        # Thread/Block indexing
        # ======================================================================
        tidx = cute.arch.thread_idx()[0]
        bidx = cute.arch.block_idx()[0]
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # ======================================================================
        # SMEM allocation
        # ======================================================================
        staged_smem_layout = cute.make_layout((self._elems_per_cta, self._num_stages))

        smem = utils.SmemAllocator()
        storage = smem.allocate(self._SharedStorage)
        mbar_ptr = storage.mbar_array.data_ptr()
        staged_smem_tensor = storage.smem_buffer.get_tensor(staged_smem_layout)

        # ======================================================================
        # TMA Pipeline setup
        # ======================================================================
        producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 1)
        consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, self._consumer_threads
        )

        tma_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=mbar_ptr,
            num_stages=self._num_stages,
            producer_group=producer_group,
            consumer_group=consumer_group,
            tx_count=self.tma_bytes,
            cta_layout_vmnk=cute.make_layout((1, 1, 1, 1)),
        )

        global_tile_id = local_rank * ctas_per_rank + bidx

        if global_tile_id < num_tiles_total:
            # ======================================================================
            # Warp 0: Producer - TMA Load from all ranks
            # ======================================================================
            if warp_idx == 0:
                producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self._num_stages
                )

                for rank_i in cutlass.range_constexpr(world_size):
                    tma_pipeline.producer_acquire(producer_state)

                    stage_idx = producer_state.index
                    smem_tile = cute.slice_(staged_smem_tensor, (None, stage_idx))

                    g_tensor_tiled = cute.zipped_divide(
                        tma_load_tensors[rank_i], self.tiler
                    )
                    g_tile = g_tensor_tiled[(None,), global_tile_id]

                    g_tile_flat = cute.group_modes(g_tile, 0, cute.rank(g_tile))
                    s_tile_flat = cute.group_modes(smem_tile, 0, cute.rank(smem_tile))

                    s_part, g_part = cute.nvgpu.cpasync.tma_partition(
                        tma_load_atoms[rank_i],
                        0,
                        cute.make_layout(1),
                        s_tile_flat,
                        g_tile_flat,
                    )

                    cute.copy(
                        tma_load_atoms[rank_i],
                        g_part,
                        s_part,
                        tma_bar_ptr=tma_pipeline.producer_get_barrier(producer_state),
                    )

                    tma_pipeline.producer_commit(producer_state)
                    producer_state.advance()

            # ======================================================================
            # Warp 1-4: Consumer - Load from smem, ADD, Store to smem
            # ======================================================================
            else:
                consumer_tid = tidx - self._tma_threads

                vec_size = 4
                chunk_size = vec_size * self._consumer_threads

                # ------------------------------------------------------------------
                # Initialize accumulator using stage 0's layout
                # ------------------------------------------------------------------
                # (elems, stages) -> (elems,)
                smem_tensor_wo_stage = cute.slice_(staged_smem_tensor, (None, 0))
                # (elems,) -> ((thr_vec,), (num_chunks,))
                smem_tensor_tiled_by_thr_vec = cute.zipped_divide(
                    smem_tensor_wo_stage, (chunk_size,)
                )
                # ((thr_vec,), (num_chunks,)) -> (((vec, threads),), (num_chunks,))
                smem_tensor_tiled_by_thr_vec_tiled_by_vec = cute.logical_divide(
                    smem_tensor_tiled_by_thr_vec, (vec_size,)
                )
                # (((vec, threads),), (num_chunks,)) -> ((vec,), (num_chunks,))
                per_thread_smem_tensor = cute.slice_(
                    smem_tensor_tiled_by_thr_vec_tiled_by_vec,
                    ((None, consumer_tid), None),
                )

                accum = cute.make_rmem_tensor(per_thread_smem_tensor.layout, self.dtype)
                accum.fill(self.dtype(0.0))

                # ------------------------------------------------------------------
                # Main loop: load from SMEM and accumulate
                # ------------------------------------------------------------------
                consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self._num_stages
                )

                for rank_i in cutlass.range_constexpr(world_size):
                    tma_pipeline.consumer_wait(consumer_state)

                    stage_idx = consumer_state.index
                    smem_tile = cute.slice_(staged_smem_tensor, (None, stage_idx))

                    # (elems,) -> ((thr_vec,), (num_chunks,))
                    smem_tiled_by_thr_vec = cute.zipped_divide(smem_tile, (chunk_size,))
                    # ((thr_vec,), (num_chunks,)) -> (((vec, threads),), (num_chunks,))
                    smem_tiled_by_thr_vec_tiled_by_vec = cute.logical_divide(
                        smem_tiled_by_thr_vec, (vec_size,)
                    )
                    # (((vec, threads),), (num_chunks,)) -> ((vec,), (num_chunks,))
                    per_thread_smem_view = cute.slice_(
                        smem_tiled_by_thr_vec_tiled_by_vec,
                        ((None, consumer_tid), None),
                    )

                    fragment = per_thread_smem_view.load()
                    accum.store(accum.load() + fragment)

                    tma_pipeline.sync_object_empty.arrive(
                        consumer_state.index, tma_pipeline.consumer_mask
                    )
                    consumer_state.advance()

                # Store accumulated result back to SMEM (stage 0)
                per_thread_smem_tensor.store(accum.load())

            # ======================================================================
            # Sync point: all warps meet here
            # ======================================================================
            cute.arch.sync_threads()

            # ======================================================================
            # Warp 0: TMA Store to multicast output
            # ======================================================================
            if warp_idx == 0:
                # Fence to ensure SMEM writes are visible
                cute.arch.fence_proxy("async.shared", space="cta")

                smem_tile_out = cute.slice_(staged_smem_tensor, (None, 0))

                g_output_tiled = cute.zipped_divide(tma_store_tensor, self.tiler)
                g_output_tile = g_output_tiled[(None,), global_tile_id]

                g_out_flat = cute.group_modes(
                    g_output_tile, 0, cute.rank(g_output_tile)
                )
                s_out_flat = cute.group_modes(
                    smem_tile_out, 0, cute.rank(smem_tile_out)
                )

                s_part, g_part = cute.nvgpu.cpasync.tma_partition(
                    tma_store_atom,
                    0,
                    cute.make_layout(1),
                    s_out_flat,
                    g_out_flat,
                )

                cute.copy(tma_store_atom, s_part, g_part)
                cute.arch.cp_async_bulk_commit_group()
                cute.arch.cp_async_bulk_wait_group(0)

        # ==================================================================
        # Cross-GPU barrier synchronization (thread 0 only)
        # ==================================================================
        if tidx == 0:
            sm_id_linear = (
                cute.arch.block_idx()[0]
                + cute.arch.block_idx()[1] * cute.arch.grid_dim()[0]
                + cute.arch.block_idx()[2]
                * cute.arch.grid_dim()[0]
                * cute.arch.grid_dim()[1]
            )

            # Signal completion to all ranks
            utils.distributed.multimem_red_add1(
                flag_mc.iterator + sm_id_linear,
                scope="sys",
                order="release",
            )

            # The same idx ctas wait until all peer ranks' ctas complete
            utils.distributed.spin_lock_atom_cas_relaxed_wait(
                flag.iterator + sm_id_linear,
                expected_val=world_size,
                reset_val=0,
                scope="sys",
            )


# =============================================================================
# HOST-SIDE DRIVER CODE
# =============================================================================

import os
import argparse
import math

import numpy as np
import torch
import torch.distributed as dist
from cuda.core.experimental import Device
from cuda.pathfinder import load_nvidia_dynamic_lib

from cutlass.cute.runtime import from_dlpack

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


def torchrun_uid_init_bcast():
    """Initialize NVSHMEM using UniqueID with torchrun as launcher."""
    local_rank = int(os.environ["LOCAL_RANK"])
    torch.cuda.set_device(local_rank)

    dev = Device(local_rank)
    dev.set_current()
    global stream
    stream = dev.create_stream()

    dist.init_process_group(backend="cpu:gloo,cuda:nccl")
    num_ranks = dist.get_world_size()

    uid = nvshmem.core.get_unique_id(empty=(local_rank != 0))
    uid_bytes = uid._data.view(np.uint8).copy()
    uid_tensor = torch.from_numpy(uid_bytes).cuda()
    dist.broadcast(uid_tensor, src=0)
    dist.barrier()
    uid._data[:] = uid_tensor.cpu().numpy().view(uid._data.dtype)

    nvshmem.core.init(
        device=dev, uid=uid, rank=local_rank, nranks=num_ranks, initializer_method="uid"
    )


def torchrun_finalize():
    """Finalize NVSHMEM and destroy process group."""
    nvshmem.core.finalize()
    dist.destroy_process_group()


def run_all_reduce_tma(
    shape: tuple,
    skip_ref_check: bool = False,
):
    """
    Run the TMA-based All-Reduce kernel.

    Args:
        shape: Tensor shape tuple, e.g., (4, 6, 8, 10)
        skip_ref_check: If True, skip reference result verification
    """
    local_rank = torch.distributed.get_rank()
    world_size = torch.distributed.get_world_size()

    # Calculate total elements
    total_elems = math.prod(shape)

    if local_rank == 0:
        print("\nRunning TMA All-Reduce test with:")
        print(f"  Tensor shape: {shape}")
        print(f"  Total elements: {total_elems}")
        print(f"  GPU count: {world_size}")

    # Allocate input tensor (symmetric memory, accessible from all ranks)
    local_input_tensor = nvshmem.core.tensor(shape, dtype=torch.float32)
    local_input_tensor.random_(0, 100)

    # Get peer tensors (views into each rank's input)
    peer_input_tensors = [
        nvshmem.core.get_peer_tensor(local_input_tensor, r) for r in range(world_size)
    ]

    if local_rank == 0:
        print(f"  Input tensor ptr: {local_input_tensor.data_ptr():#x}")

    # Allocate output tensor with multicast address
    local_output_tensor = nvshmem.core.tensor(shape, dtype=torch.float32)
    local_output_tensor.fill_(0)
    output_tensor_mc = nvshmem.core.get_multicast_tensor(
        nvshmem.core.Teams.TEAM_NODE, local_output_tensor
    )

    # Allocate synchronization flags
    # Flag size = ctas_per_rank (matches kernel's bidx indexing)
    elems_per_cta = AllReduceTmaKernel._elems_per_cta
    num_tiles = (total_elems + elems_per_cta - 1) // elems_per_cta
    ctas_per_rank = (num_tiles + world_size - 1) // world_size
    local_flag = nvshmem.core.tensor((ctas_per_rank,), dtype=torch.int32)
    local_flag.fill_(0)
    flag_mc = nvshmem.core.get_multicast_tensor(
        nvshmem.core.Teams.TEAM_NODE, local_flag
    )

    if local_rank == 0:
        print(f"  Number of tiles: {num_tiles}")
        print(f"  CTAs per rank: {ctas_per_rank}")
        print("Compiling kernel...")

    # Create kernel instance and compile
    kernel = AllReduceTmaKernel(cutlass.Float32)

    compiled_func = cute.compile(
        kernel,
        [from_dlpack(t) for t in peer_input_tensors],
        from_dlpack(output_tensor_mc),
        from_dlpack(local_flag),
        from_dlpack(flag_mc),
        local_rank,
        world_size,
    )

    if local_rank == 0:
        print("Compilation successful!")

    if not skip_ref_check:
        if local_rank == 0:
            print("Executing kernel...")

        dist.barrier(device_ids=[local_rank])
        compiled_func(
            [from_dlpack(t) for t in peer_input_tensors],
            from_dlpack(output_tensor_mc),
            from_dlpack(local_flag),
            from_dlpack(flag_mc),
        )
        dist.barrier(device_ids=[local_rank])

        if local_rank == 0:
            print("Verifying results...")

        # Compute expected result: sum of all inputs
        expected = sum([t.cpu() for t in peer_input_tensors])

        # Compare with actual output
        torch.testing.assert_close(expected, local_output_tensor.cpu())

        if local_rank == 0:
            print("Results verified successfully!")

    # Cleanup
    for i in range(world_size):
        if i != local_rank:
            nvshmem.core.free_tensor(peer_input_tensors[i])

    nvshmem.core.free_tensor(output_tensor_mc)
    nvshmem.core.free_tensor(flag_mc)
    nvshmem.core.free_tensor(local_input_tensor)
    nvshmem.core.free_tensor(local_output_tensor)
    nvshmem.core.free_tensor(local_flag)


def parse_shape(shape_str: str) -> tuple:
    """
    Parse shape string into tuple.
    Examples:
        "1024,1024" -> (1024, 1024)
        "2,3,4,5,6,7,8" -> (2, 3, 4, 5, 6, 7, 8)
    """
    return tuple(int(x.strip()) for x in shape_str.split(","))


def main():
    parser = argparse.ArgumentParser(
        description="TMA-based distributed all-reduce example"
    )
    parser.add_argument(
        "--shape",
        default="1024,1024",
        type=str,
        help="Tensor shape as comma-separated values, e.g., '1024,1024' or 4,6,8,10,12'",
    )
    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference result verification",
    )

    args = parser.parse_args()
    shape = parse_shape(args.shape)

    torchrun_uid_init_bcast()
    run_all_reduce_tma(
        shape=shape,
        skip_ref_check=args.skip_ref_check,
    )
    torchrun_finalize()


if __name__ == "__main__":
    main()
