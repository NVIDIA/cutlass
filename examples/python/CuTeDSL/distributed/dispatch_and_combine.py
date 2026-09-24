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

"""
MoE Dispatch and Combine kernels ported from Triton-distributed (DeepEP) to CuTeDSL.

Single-node and multi-node multi-GPU implementation using NVSHMEM.

Dispatch: routes MoE tokens to target expert ranks via put_warp. NVSHMEM
          put transparently handles intra-node (P2P) and inter-node (IB)
          peers, mirroring DeepEP `kernel_dispatch_token`'s use of
          `libshmem_device.putmem_warp`. Supports two modes controlled by
          WITH_SCATTER_INDICES:
            True  - read pre-computed scatter indices from a tensor
            False - allocate slots on-the-fly via per-warp atomic_add
                    (matching Triton-distributed kernel_dispatch_token)
Combine:  per-peer route mirroring DeepEP `kernel_combine_token`'s
          `expert_node_idx == node_id` predicate. For experts on the
          same node (P2P-reachable on full-NVL hardware): direct LDG via
          `nvshmem_ptr` at SYS-scope VOLATILE — exactly the
          `dl.symm_at(input_buf, expert_rank)` + `tl.load` path in
          DeepEP. For experts on a different node: NVSHMEM `get_warp`
          fetches the slot into a local fragment, then accumulates.
          Variable names follow DeepEP convention (`expert_node_idx`,
          `node_id`, `local_world_size`).

To run (single node):
    torchrun --nproc-per-node 4 examples/distributed/test.py
To run (multi node):
    srun -p <slurm-partition> -N 2 --ntasks-per-node 1 \
        torchrun --nnodes 2 --nproc_per_node 4 \
                 --rdzv_endpoint=$MASTER_ADDR:29500 dispatch_and_combine.py
"""

import os
import argparse
import functools

import numpy as np
import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import Int32
from cuda.core import Device

import nvshmem.core
import nvshmem.core.device.cute as nvshmem_cute
from nvshmem.bindings.device.cute._cuteast import _CutePtrType
# Define nvshmem_ptr FFI with alignment=4 to match recast from Float32*
nvshmem_ptr_ffi = cute.ffi(
    name="nvshmem_ptr",
    params_types=[_CutePtrType(cutlass.Int8, alignment=4), cutlass.Int32],
    return_type=_CutePtrType(cutlass.Int8, alignment=4),
)

import torch
import torch.distributed as dist


# ---------------------------------------------------------------------------
# NVSHMEM init / finalize / compile helpers
# ---------------------------------------------------------------------------

_KERNEL_OBJECTS: list[nvshmem.core.NvshmemKernelObject] = []


def torchrun_uid_init_bcast():
    """Initialize NVSHMEM using UniqueID. Supports both launchers:

    - torchrun (single-node): reads RANK / LOCAL_RANK / WORLD_SIZE; the
      backend init_method is the c10d default (env://).
    - srun (multi-node): reads SLURM_PROCID / SLURM_LOCALID /
      SLURM_NTASKS / MASTER_ADDR / MASTER_PORT and bootstraps
      torch.distributed via the explicit `tcp://master:port` init
      method. This avoids torchrun's c10d-rendezvous backend, which
      hangs trying to bind MASTER_ADDR:port from non-master nodes.

    Either launcher converges on the same downstream code path: an
    NVSHMEM UID broadcast over the bootstrapped torch.distributed
    process group, then `nvshmem.core.init(initializer_method="uid")`.
    """
    if "RANK" in os.environ and "LOCAL_RANK" in os.environ:
        # torchrun path
        global_rank = int(os.environ["RANK"])
        local_rank = int(os.environ["LOCAL_RANK"])
        world_size = int(os.environ.get("WORLD_SIZE", "1"))
        init_method = None  # env:// default
    elif "SLURM_PROCID" in os.environ:
        # srun path (multi-node)
        global_rank = int(os.environ["SLURM_PROCID"])
        local_rank = int(os.environ["SLURM_LOCALID"])
        world_size = int(os.environ["SLURM_NTASKS"])
        master_addr = os.environ["MASTER_ADDR"]
        master_port = int(os.environ.get("MASTER_PORT", "29500"))
        init_method = f"tcp://{master_addr}:{master_port}"
        # The kernel reads LOCAL_WORLD_SIZE for the DeepEP node_id
        # arithmetic. SLURM exports SLURM_NTASKS_PER_NODE; mirror it
        # into LOCAL_WORLD_SIZE here so the kernel's host-side path
        # doesn't need to know about the launcher.
        os.environ.setdefault(
            "LOCAL_WORLD_SIZE",
            os.environ.get("SLURM_NTASKS_PER_NODE", str(world_size)))
    else:
        raise RuntimeError(
            "Cannot bootstrap: neither RANK/LOCAL_RANK (torchrun) nor "
            "SLURM_PROCID (srun) are set in the environment.")

    torch.cuda.set_device(local_rank)
    dev = Device(local_rank)
    dev.set_current()

    if init_method is None:
        dist.init_process_group(backend="cpu:gloo,cuda:nccl")
    else:
        dist.init_process_group(
            backend="cpu:gloo,cuda:nccl",
            init_method=init_method,
            rank=global_rank,
            world_size=world_size,
        )

    num_ranks = dist.get_world_size()

    uid = nvshmem.core.get_unique_id(empty=(global_rank != 0))
    uid_bytes = uid._data.view(np.uint8).copy()
    uid_tensor = torch.from_numpy(uid_bytes).cuda()
    dist.broadcast(uid_tensor, src=0)
    dist.barrier()
    uid._data[:] = uid_tensor.cpu().numpy().view(uid._data.dtype)

    nvshmem.core.init(device=dev, uid=uid, rank=global_rank, nranks=num_ranks,
                      initializer_method="uid")


def torchrun_finalize():
    nvshmem.core.finalize()
    dist.destroy_process_group()


def _nvshmem_device_bc():
    nvshmem_device_bc = nvshmem.core.find_device_bitcode_library()
    if not os.path.exists(nvshmem_device_bc):
        raise RuntimeError(f"NVSHMEM device bitcode not found at {nvshmem_device_bc}")
    return nvshmem_device_bc


def _compile_kernel(kernel, *example_args):
    nvshmem_device_bc = _nvshmem_device_bc()
    compiled = cute.compile(
        kernel,
        *example_args,
        options=f" --link-libraries={nvshmem_device_bc}",
    )
    compiled = compiled.to(Device().device_id)
    cuda_library = compiled.jit_module.cuda_library
    nvshmem_kernel = nvshmem.core.NvshmemKernelObject.from_handle(int(cuda_library[0]))
    nvshmem.core.library_init(nvshmem_kernel)
    _KERNEL_OBJECTS.append(nvshmem_kernel)
    return compiled


def _finalize_kernels():
    while _KERNEL_OBJECTS:
        nvshmem.core.library_finalize(_KERNEL_OBJECTS.pop())


# ---------------------------------------------------------------------------
# Dispatch kernel: route tokens to remote recv buffers
# ---------------------------------------------------------------------------
# Each warp iterates over tokens assigned to it, for each token iterates topk
# experts, allocates (or reads pre-computed) a slot in the recv buffer, then
# copies the full hidden vector via warp-cooperative tiled copy.

@cute.kernel
def dispatch_kernel(
    input_buf: cute.Tensor, # [num_tokens, hidden_size] float32 (nvshmem)
    output_buf: cute.Tensor, # [max_recv_tokens, hidden_size] float32 (nvshmem)
    topk_indices_tensor: cute.Tensor, # [num_tokens, topk] int32
    token_dst_scatter_idx: cute.Tensor, # [num_tokens, topk] int32
    recv_buf_offset_per_expert: cute.Pointer, # [world_size, experts_per_rank, world_size] int32
    num_input_tokens_per_rank: cute.Tensor, # [world_size] int32
    topk: cutlass.Int32,
    experts_per_rank: cutlass.Constexpr,
    local_rank: cutlass.Constexpr,
    world_size: cutlass.Constexpr,
    num_warps: cutlass.Constexpr,
    WITH_SCATTER_INDICES: cutlass.Constexpr,
):
    WARP_SIZE = 32
    tidx, tidy, tidz = cute.arch.thread_idx()
    bdimx, bdimy, bdimz = cute.arch.block_dim()
    gdimx, gdimy, gdimz = cute.arch.grid_dim()
    bidx, bidy, bidz = cute.arch.block_idx()

    cta_nums = gdimx * gdimy * gdimz
    threads_per_cta = bdimx * bdimy * bdimz
    warps_per_cta = threads_per_cta // WARP_SIZE
    warp_id = tidx // WARP_SIZE
    global_warp_id = bidx * warps_per_cta + warp_id
    total_warps = warps_per_cta * cta_nums

    num_tokens = num_input_tokens_per_rank[local_rank]

    for token_offset in range(global_warp_id, num_tokens, total_warps):
        for j in range(topk):
            expert_idx = topk_indices_tensor[token_offset, j]
            expert_rank = expert_idx // experts_per_rank

            if cutlass.const_expr(WITH_SCATTER_INDICES):
                store_idx = token_dst_scatter_idx[token_offset, j]
            else:
                # Atomic slot allocation (one thread per warp), matching
                # Triton-distributed atomic_add_per_warp pattern.
                expert_idx_intra_rank = expert_idx % experts_per_rank
                offset = (expert_rank * (experts_per_rank * world_size)
                          + expert_idx_intra_rank * world_size + local_rank)
                atomic_ptr = recv_buf_offset_per_expert + offset
                store_idx = Int32(0)
                lane_id = tidx % WARP_SIZE
                if lane_id == 0:
                    store_idx = cute.arch.atomic_add(
                        atomic_ptr, Int32(1), sem="relaxed", scope="gpu")
                # Broadcast lane-0 result to all threads in the warp
                store_idx = cute.arch.shuffle_sync(store_idx, 0)
                # Write back so combine kernel can read the scatter index
                token_dst_scatter_idx[token_offset, j] = store_idx

            src_row = input_buf[token_offset, None]
            dst_row = output_buf[store_idx, None]
            nvshmem_cute.put_warp(dst_row, src_row, expert_rank)


# ---------------------------------------------------------------------------
# Combine kernel: gather expert results and accumulate per-token
# ---------------------------------------------------------------------------
# Each warp iterates over tokens assigned to it, for each token iterates topk
# experts, loads the expert result from the scatter index, and accumulates
# across topk to produce the final output.

@cute.kernel
def combine_kernel(
    expert_output_buf: cute.Pointer, # NVSHMEM symmetric [max_tokens, hidden_size] float32
    combine_output_buf: cute.Pointer, # local [num_tokens, hidden_size] float32
    inter_node_get_buf: cute.Pointer, # NVSHMEM symmetric [num_tokens, hidden_size] float32 staging for inter-node get_warp
    topk_indices_tensor: cute.Tensor, # [num_tokens, topk] int32
    token_dst_scatter_idx: cute.Tensor, # [num_tokens, topk] int32
    num_input_tokens_per_rank: cute.Tensor, # [world_size] int32
    max_tokens: cutlass.Int32,
    topk: cutlass.Constexpr,
    _hidden_size: cutlass.Int32,
    experts_per_rank: cutlass.Constexpr,
    local_rank: cutlass.Constexpr,
    local_world_size: cutlass.Constexpr,
    num_warps: cutlass.Constexpr,
):
    # Mirror DeepEP `kernel_combine_token`: per-peer route by
    # `expert_node_idx == node_id`. Same-node experts use direct LDG via
    # `nvshmem_ptr` (DeepEP's `dl.symm_at(input_buf, expert_rank)` +
    # `tl.load`). Cross-node experts go through NVSHMEM `get_warp` into a
    # local symmetric staging buffer (DeepEP uses sender-push +
    # `intra_node_reduce_buf`; receiver-pull is the simpler get-side
    # mirror that uses no extra signal coordination).
    hidden_size = cute.assume(_hidden_size, divby=16)
    WARP_SIZE = 32
    tidx, tidy, tidz = cute.arch.thread_idx()
    bdimx, bdimy, bdimz = cute.arch.block_dim()
    gdimx, gdimy, gdimz = cute.arch.grid_dim()
    bidx, bidy, bidz = cute.arch.block_idx()

    cta_nums = gdimx * gdimy * gdimz
    threads_per_cta = bdimx * bdimy * bdimz
    warps_per_cta = threads_per_cta // WARP_SIZE
    warp_id = tidx // WARP_SIZE
    global_warp_id = bidx * warps_per_cta + warp_id
    total_warps = warps_per_cta * cta_nums

    # DeepEP convention: node_id = rank // local_world_size
    node_id = local_rank // local_world_size

    # SYS-scope volatile loads for reading remote GPU memory via nvshmem_ptr.
    # `CopyUniversalOp` carries the load/store semantics via its
    # `memory_scope` / `memory_order` keyword arguments.
    copy_atom_load = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        expert_output_buf.dtype,
        num_bits_per_copy=128,
        memory_scope=cute.nvgpu.common.MemoryScope.SYS,
        memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
    )
    # Local LDG copy for the post-get_warp staging buffer (same dtype,
    # but no SYS/VOLATILE semantics needed because get_warp already
    # synchronized the data into local symmetric memory).
    copy_atom_load_local = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        expert_output_buf.dtype,
        num_bits_per_copy=128,
    )
    copy_atom_store = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(), combine_output_buf.dtype, num_bits_per_copy=128)
    thr_layout = cute.make_ordered_layout((1, 32), order=(1, 0))
    val_layout = cute.make_ordered_layout((1, 4), order=(1, 0))
    tiled_copy_load = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
    tiled_copy_load_local = cute.make_tiled_copy_tv(copy_atom_load_local, thr_layout, val_layout)
    tiled_copy_store = cute.make_tiled_copy_tv(copy_atom_store, thr_layout, val_layout)
    copy_idx = tidx % WARP_SIZE
    thr_copy_load = tiled_copy_load.get_slice(copy_idx)
    thr_copy_load_local = tiled_copy_load_local.get_slice(copy_idx)
    thr_copy_store = tiled_copy_store.get_slice(copy_idx)

    num_tokens = num_input_tokens_per_rank[local_rank]

    # Partition output for stores
    output_layout = cute.make_ordered_layout((num_tokens, hidden_size), order=(1, 0))
    output_tensor = cute.make_tensor(combine_output_buf.align(16), output_layout)
    tDgD = thr_copy_store.partition_D(output_tensor)
    tSrS = cute.make_fragment_like(tDgD[None, 0, 0])
    accum = cute.make_fragment_like(tDgD[None, 0, 0])
    hidden_iter = cute.size(tDgD, mode=[2])

    # Local view over inter_node_get_buf (one slot per local token; this
    # is per-rank symmetric, so each (warp, token) lane has its own
    # row). The staging row is reused across topk iterations for that
    # token so we only need shape [num_tokens, hidden_size].
    #
    # Two views of the same memory:
    #   - stage_tensor_get: UNALIGNED — passed to `nvshmem_cute.get_warp`
    #     (the FFI prototype is `!cute.ptr<f32, gmem>` with no alignment
    #     qualifier; passing an aligned pointer triggers a CuTeDSL
    #     prototype-mismatch error).
    #   - stage_tensor: ALIGNED — partitioned through `thr_copy_load_local`
    #     and read via `cute.copy` for the local accumulation step.
    stage_layout = cute.make_ordered_layout((num_tokens, hidden_size), order=(1, 0))
    stage_tensor_get = cute.make_tensor(inter_node_get_buf, stage_layout)
    stage_tensor = cute.make_tensor(inter_node_get_buf.align(16), stage_layout)

    for token_offset in range(global_warp_id, num_tokens, total_warps):
        for k in range(hidden_iter):
            accum.fill(0.0)
            for j in cutlass.range_constexpr(topk):
                expert_idx = topk_indices_tensor[token_offset, j]
                expert_rank = expert_idx // experts_per_rank
                expert_node_idx = expert_rank // local_world_size
                scatter_idx = token_dst_scatter_idx[token_offset, j]

                if expert_node_idx == node_id:
                    # DeepEP same-node fast path: nvshmem_ptr direct LDG
                    # (equivalent to triton-dist's `dl.symm_at(input_buf,
                    # expert_rank)` + `tl.load`).
                    int8_ptr = cute.recast_ptr(expert_output_buf, dtype=cutlass.Int8)
                    remote_int8_ptr = nvshmem_ptr_ffi(int8_ptr, expert_rank)
                    remote_ptr = cute.recast_ptr(remote_int8_ptr, dtype=cutlass.Float32).align(16)

                    remote_layout = cute.make_ordered_layout(
                        (max_tokens, hidden_size), order=(1, 0))
                    remote_tensor = cute.make_tensor(remote_ptr, remote_layout)
                    tSgS_remote = thr_copy_load.partition_S(remote_tensor)

                    cute.copy(thr_copy_load, tSgS_remote[None, scatter_idx, k], tSrS)
                else:
                    # Inter-node fallback: NVSHMEM get_warp pulls one
                    # token slot from expert_rank's expert_output_buf
                    # into our local inter_node_get_buf row, then we
                    # load + accumulate. DeepEP uses sender-push for
                    # this leg; the receiver-pull mirror has the same
                    # semantics with no signal protocol.
                    src_layout = cute.make_ordered_layout(
                        (max_tokens, hidden_size), order=(1, 0))
                    src_tensor_get = cute.make_tensor(
                        cute.recast_ptr(expert_output_buf, dtype=cutlass.Float32),
                        src_layout)
                    nvshmem_cute.get_warp(
                        stage_tensor_get[token_offset, None],
                        src_tensor_get[scatter_idx, None],
                        expert_rank,
                    )
                    tSgS_local = thr_copy_load_local.partition_S(stage_tensor)
                    cute.copy(thr_copy_load_local, tSgS_local[None, token_offset, k], tSrS)
                accum.store(accum.load() + tSrS.load())

            cute.copy(thr_copy_store, accum, tDgD[None, token_offset, k])


# ---------------------------------------------------------------------------
# Host-side JIT wrappers
# ---------------------------------------------------------------------------

@cute.jit
def dispatch_jit(
    input_buf: cute.Tensor, # [num_tokens, hidden_size] float32 (nvshmem)
    output_buf: cute.Tensor, # [max_recv_tokens, hidden_size] float32 (nvshmem)
    topk_indices_tensor: cute.Tensor, # [num_tokens, topk] int32
    token_dst_scatter_idx: cute.Tensor, # [num_tokens, topk] int32
    recv_buf_offset_per_expert: cute.Tensor, # [world_size, experts_per_rank, world_size] int32
    num_input_tokens_per_rank: cute.Tensor, # [world_size] int32
    topk: cutlass.Int32,
    experts_per_rank: cutlass.Constexpr,
    local_rank: cutlass.Constexpr,
    world_size: cutlass.Constexpr,
    WITH_SCATTER_INDICES: cutlass.Constexpr,
):

    num_warps = 32
    cta_nums = 20

    dispatch_kernel(
        input_buf,
        output_buf,
        topk_indices_tensor,
        token_dst_scatter_idx,
        recv_buf_offset_per_expert.iterator,
        num_input_tokens_per_rank,
        topk,
        experts_per_rank,
        local_rank,
        world_size,
        num_warps,
        WITH_SCATTER_INDICES,
    ).launch(
        grid=[cta_nums, 1, 1],
        block=[num_warps * 32, 1, 1],
    )


@cute.jit
def combine_jit(
    expert_output_buf: cute.Tensor, # NVSHMEM symmetric [max_tokens, hidden_size] float32
    combine_output_buf: cute.Tensor, # local [num_tokens, hidden_size] float32
    inter_node_get_buf: cute.Tensor, # NVSHMEM symmetric [num_tokens, hidden_size] float32
    topk_indices_tensor: cute.Tensor, # [num_tokens, topk] int32
    token_dst_scatter_idx: cute.Tensor, # [num_tokens, topk] int32
    num_input_tokens_per_rank: cute.Tensor, # [world_size] int32
    max_tokens: cutlass.Int32,
    hidden_size: cutlass.Int32,
    topk: cutlass.Constexpr,
    experts_per_rank: cutlass.Constexpr,
    local_rank: cutlass.Constexpr,
    local_world_size: cutlass.Constexpr,
):

    num_warps = 32
    cta_nums = 20

    combine_kernel(
        expert_output_buf.iterator,
        combine_output_buf.iterator,
        inter_node_get_buf.iterator,
        topk_indices_tensor,
        token_dst_scatter_idx,
        num_input_tokens_per_rank,
        max_tokens,
        topk,
        hidden_size,
        experts_per_rank,
        local_rank,
        local_world_size,
        num_warps,
    ).launch(
        grid=[cta_nums, 1, 1],
        block=[num_warps * 32, 1, 1],
    )


# ---------------------------------------------------------------------------
# Reference checks
# ---------------------------------------------------------------------------

# Route classes a token-to-expert hop can fall into. The validator
# counts hits across (source_rank, dest_rank) pairs; a multi-node run
# should hit at least the first three of these (and ideally all four
# for non-trivial cluster shapes — `2x4` hits "self" and three remote
# classes; some `Nx1` shapes have no intra-node remote class).
_ROUTE_CLASSES = (
    "self",                             # peer == rank
    "intra_node_remote",                # peer != rank, same node
    "inter_node_same_local_rank",       # peer's local_rank == my local_rank
    "inter_node_diff_local_rank",       # peer's local_rank != my local_rank
)


def _classify_route(src_rank: int, dst_rank: int, local_world_size: int) -> str:
    """Classify a (src_rank -> dst_rank) hop into one of the four route
    classes used by the route_class_hits validator. The classification
    matches the per-peer routing the kernel performs."""
    if src_rank == dst_rank:
        return "self"
    src_node = src_rank // local_world_size
    dst_node = dst_rank // local_world_size
    if src_node == dst_node:
        return "intra_node_remote"
    if src_rank % local_world_size == dst_rank % local_world_size:
        return "inter_node_same_local_rank"
    return "inter_node_diff_local_rank"


def check_dispatch(input_buf, output_buf, topk_indices, scatter_idx,
                    num_tokens, topk, experts_per_rank, rank, world_size,
                    local_world_size=None, route_class_hits=None):
    """Verify multi-GPU dispatch correctness.
    Allgather inputs/indices from all ranks, then check that each rank's
    output_buf contains the correct data from the source ranks.

    If `local_world_size` and `route_class_hits` are provided, this also
    counts each (src_rank -> dst_rank) hop into the four route classes
    (self, intra_node_remote, inter_node_same_local_rank,
    inter_node_diff_local_rank). The caller asserts the expected
    classes were hit at least once after both dispatch tests run.
    """
    device = input_buf.device

    # Gather inputs from all ranks
    all_inputs = [torch.zeros_like(input_buf) for _ in range(world_size)]
    dist.all_gather(all_inputs, input_buf.contiguous())

    # Gather topk_indices from all ranks
    all_topk = [torch.zeros_like(topk_indices) for _ in range(world_size)]
    dist.all_gather(all_topk, topk_indices.contiguous())

    # Gather scatter_idx from all ranks
    all_scatter = [torch.zeros_like(scatter_idx) for _ in range(world_size)]
    dist.all_gather(all_scatter, scatter_idx.contiguous())

    # Gather output_buf from all ranks so GPU0 can verify cross-GPU transfers
    all_outputs = [torch.zeros_like(output_buf) for _ in range(world_size)]
    dist.all_gather(all_outputs, output_buf.contiguous())

    # --- Trace a few tokens from GPU0 to show dispatch paths ---
    if rank == 0:
        src = 0
        for t in [0, num_tokens // 2, num_tokens - 1]:
            experts = all_topk[src][t]
            dests = experts // experts_per_rank
            scatters = all_scatter[src][t]
            print(f"  [trace] GPU{src} token {t}: topk_experts={experts.tolist()}, "
                  f"dest_ranks={dests.tolist()}, scatter_idx={scatters.tolist()}")
            for j in range(topk):
                dst_rank = dests[j].item()
                slot = scatters[j].item()
                src_data = all_inputs[src][t, :4]
                actual_data = all_outputs[dst_rank][slot, :4]
                match = torch.allclose(actual_data, src_data, atol=1e-6, rtol=1e-5)
                print(f"    topk[{j}]: expert {experts[j].item()} -> GPU{dst_rank} "
                      f"output_buf[{slot}]  {'MATCH' if match else 'MISMATCH'}")

    # --- Full correctness check ---
    errors = 0
    for src_rank in range(world_size):
        dest_ranks = all_topk[src_rank] // experts_per_rank  # [num_tokens, topk]

        # Route classification: every (src_rank, dst_rank) hop in the
        # source rank's topk routing fans into one of four classes.
        # We count from rank 0's perspective only — other ranks see the
        # same classification because dest_ranks is allgathered.
        if route_class_hits is not None and local_world_size is not None and rank == 0:
            for j in range(topk):
                for dst in dest_ranks[:, j].tolist():
                    cls = _classify_route(src_rank, int(dst), local_world_size)
                    route_class_hits[cls] = route_class_hits.get(cls, 0) + 1

        for j in range(topk):
            mask = (dest_ranks[:, j] == rank)
            if not mask.any():
                continue

            token_indices = mask.nonzero(as_tuple=True)[0]
            scatter_indices = all_scatter[src_rank][token_indices, j].long()

            expected = all_inputs[src_rank][token_indices]
            actual = output_buf[scatter_indices]

            if not torch.allclose(actual, expected, atol=1e-6, rtol=1e-5):
                mismatch = ~torch.isclose(actual, expected, atol=1e-6, rtol=1e-5)
                num_mismatch = mismatch.any(dim=1).sum().item()
                errors += num_mismatch
                if rank == 0:
                    first_bad = mismatch.any(dim=1).nonzero()[0].item()
                    print(f"  [dispatch] FAIL: src={src_rank} topk={j}, "
                          f"{num_mismatch} mismatches")
                    print(f"    token {token_indices[first_bad].item()}: "
                          f"got {actual[first_bad, :4]}, "
                          f"expected {expected[first_bad, :4]}")

    return errors == 0


def check_combine(combine_output, expert_output_buf, topk_indices,
                   token_dst_scatter_idx, num_tokens, topk, experts_per_rank,
                   rank, world_size):
    """Verify multi-GPU combine correctness:
    combine_output[t] == sum_j(remote_expert_output[expert_rank_j][scatter_idx[t,j]])
    where expert_rank_j = topk_indices[t,j] // experts_per_rank
    """
    # Gather expert_output_buf from all ranks (each GPU's dispatch output)
    all_expert_outputs = [torch.zeros_like(expert_output_buf) for _ in range(world_size)]
    dist.all_gather(all_expert_outputs, expert_output_buf.contiguous())
    all_expert_stacked = torch.stack(all_expert_outputs)  # [world_size, max_tokens, hidden]

    expected = torch.zeros_like(combine_output[:num_tokens])
    for j in range(topk):
        expert_ranks = (topk_indices[:num_tokens, j] // experts_per_rank).long()
        slots = token_dst_scatter_idx[:num_tokens, j].long()
        expected += all_expert_stacked[expert_ranks, slots]

    if torch.allclose(combine_output[:num_tokens], expected, atol=1e-4, rtol=1e-4):
        return True

    mismatch = ~torch.isclose(combine_output[:num_tokens], expected, atol=1e-4, rtol=1e-4)
    num_mismatch = mismatch.any(dim=1).sum().item()
    if rank == 0:
        print(f"  [combine] FAIL: {num_mismatch}/{num_tokens} token mismatches")
        first_bad = mismatch.any(dim=1).nonzero()[0].item()
        print(f"    token {first_bad}: got {combine_output[first_bad, :4]}, "
              f"expected {expected[first_bad, :4]}")
    return False


# ---------------------------------------------------------------------------
# Main: run dispatch -> (simulated expert) -> combine, with ref checks
# ---------------------------------------------------------------------------

def run_moe_dispatch_combine(num_tokens, hidden, num_experts, topk,
                             benchmark=False, warmup_iterations=10,
                             iterations=100, save_baseline_to=None):
    rank = dist.get_rank()
    world_size = dist.get_world_size()
    experts_per_rank = num_experts // world_size

    # DeepEP convention: local_world_size == nproc_per_node, node_id ==
    # rank // local_world_size. Single-node runs collapse to
    # local_world_size == world_size.
    local_world_size = int(os.environ.get("LOCAL_WORLD_SIZE", world_size))
    if world_size % local_world_size != 0:
        raise RuntimeError(
            f"WORLD_SIZE ({world_size}) must be divisible by LOCAL_WORLD_SIZE "
            f"({local_world_size}); the topology assumes equal-size nodes.")
    nnodes = world_size // local_world_size
    node_id = rank // local_world_size

    if rank == 0:
        print(f"\nMoE Dispatch test (NVSHMEM put_warp, multi-GPU):")
        print(f"  num_tokens={num_tokens}, hidden={hidden}, "
              f"num_experts={num_experts}, topk={topk}")
        print(f"  world_size={world_size}, experts_per_rank={experts_per_rank}")
        print(f"  nnodes={nnodes}, local_world_size={local_world_size}")

    device = torch.cuda.current_device()
    torch.manual_seed(42 + rank)

    # --- Generate test data ---
    topk_indices_tensor = torch.randint(
        0, num_experts, (num_tokens, topk), dtype=torch.int32, device=device)

    # Compute destination rank for each (token, topk_slot)
    dest_ranks = topk_indices_tensor.int() // experts_per_rank  # [num_tokens, topk]

    # Count tokens sent to each destination rank
    send_counts = torch.zeros(world_size, dtype=torch.int64, device=device)
    for d in range(world_size):
        send_counts[d] = (dest_ranks == d).sum()

    # All-gather send_counts to compute scatter indices without collisions
    all_send_counts = [torch.zeros_like(send_counts) for _ in range(world_size)]
    dist.all_gather(all_send_counts, send_counts)

    # Compute max_recv_tokens (must be same on all ranks for nvshmem symmetric alloc)
    max_recv_tokens = 0
    for d in range(world_size):
        total = sum(all_send_counts[s][d].item() for s in range(world_size))
        max_recv_tokens = max(max_recv_tokens, int(total))
    max_recv_tokens = max(max_recv_tokens, 1)

    if rank == 0:
        print(f"  max_recv_tokens={max_recv_tokens}")

    # ------------------------------------------------------------------
    # Compute recv_buf_offset_per_expert
    # Layout: [expert_rank, expert_idx_intra_rank, src_rank]
    # Used by both WITH_SCATTER_INDICES modes
    # ------------------------------------------------------------------
    local_expert_counts = torch.zeros(num_experts, dtype=torch.int32, device=device)
    flat_expert_indices = topk_indices_tensor.reshape(-1).long()
    local_expert_counts.scatter_add_(
        0, flat_expert_indices,
        torch.ones(flat_expert_indices.shape[0], dtype=torch.int32, device=device))

    all_expert_counts = [torch.zeros_like(local_expert_counts) for _ in range(world_size)]
    dist.all_gather(all_expert_counts, local_expert_counts.contiguous())

    recv_buf_offset_data = torch.zeros(
        (world_size, experts_per_rank, world_size), dtype=torch.int32, device=device)
    for er in range(world_size):
        cumsum_val = 0
        for ei in range(experts_per_rank):
            expert_global = er * experts_per_rank + ei
            for sr in range(world_size):
                recv_buf_offset_data[er, ei, sr] = cumsum_val
                cumsum_val += all_expert_counts[sr][expert_global].item()

    # Assign scatter indices using the same expert-first layout as recv_buf_offset
    # This makes WITH_SCATTER_INDICES=True produce the same output layout as =False
    token_dst_scatter_idx = torch.zeros(
        (num_tokens, topk), dtype=torch.int32, device=device)
    counters = recv_buf_offset_data.clone()  # [world_size, experts_per_rank, world_size]
    for t in range(num_tokens):
        for j in range(topk):
            expert_idx = topk_indices_tensor[t, j].item()
            expert_rank = expert_idx // experts_per_rank
            expert_idx_intra_rank = expert_idx % experts_per_rank
            token_dst_scatter_idx[t, j] = counters[expert_rank, expert_idx_intra_rank, rank]
            counters[expert_rank, expert_idx_intra_rank, rank] += 1

    # Save random input so both test modes use identical data
    input_data = torch.randn((num_tokens, hidden), dtype=torch.float32, device=device)

    num_input_tokens_per_rank = torch.full(
        (world_size,), num_tokens, dtype=torch.int32, device=device)

    all_pass = True
    # Tally each topk hop into one of the four route classes across both
    # dispatch tests. Multi-node runs should hit at least three of these
    # (or all four for non-trivial topology).
    route_class_hits: dict[str, int] = {cls: 0 for cls in _ROUTE_CLASSES}

    # =====================================================================
    # Test 1: WITH_SCATTER_INDICES=False  (atomic slot allocation)
    # =====================================================================
    if rank == 0:
        print("\n--- WITH_SCATTER_INDICES=False (atomic allocation) ---")

    input_buf = nvshmem.core.tensor((num_tokens, hidden), dtype=torch.float32)
    input_buf.copy_(input_data)
    output_buf = nvshmem.core.tensor((max_recv_tokens, hidden), dtype=torch.float32)
    output_buf.fill_(0)

    scatter_idx_atomic = torch.zeros(
        (num_tokens, topk), dtype=torch.int32, device=device)
    recv_buf_offset = recv_buf_offset_data.clone()

    input_cute   = from_dlpack(input_buf)
    output_cute  = from_dlpack(output_buf)
    topk_idx_cute = from_dlpack(topk_indices_tensor)
    scatter_atomic_cute = from_dlpack(scatter_idx_atomic)
    recv_cute    = from_dlpack(recv_buf_offset)
    ntok_cute    = from_dlpack(num_input_tokens_per_rank)

    if rank == 0:
        print("Compiling dispatch kernel (WITH_SCATTER_INDICES=False)...")
    compiled_atomic = _compile_kernel(
        dispatch_jit,
        input_cute, output_cute, topk_idx_cute, scatter_atomic_cute,
        recv_cute, ntok_cute,
        topk, experts_per_rank, rank, world_size, False,
    )

    torch.cuda.synchronize()
    dist.barrier()

    if rank == 0:
        print("Running dispatch kernel...")
    compiled_atomic(
        input_cute, output_cute, topk_idx_cute, scatter_atomic_cute,
        recv_cute, ntok_cute,
        topk,
    )

    torch.cuda.synchronize()
    nvshmem_stream = Device().create_stream()
    nvshmem.core.barrier(nvshmem.core.Teams.TEAM_WORLD, stream=nvshmem_stream)
    nvshmem_stream.sync()

    ok_atomic = check_dispatch(
        input_buf, output_buf, topk_indices_tensor, scatter_idx_atomic,
        num_tokens, topk, experts_per_rank, rank, world_size,
        local_world_size=local_world_size, route_class_hits=route_class_hits)
    if rank == 0:
        print(f"  Dispatch check: {'PASS' if ok_atomic else 'FAIL'}")
    all_pass = all_pass and ok_atomic

    nvshmem.core.free_tensor(input_buf)
    nvshmem.core.free_tensor(output_buf)

    # =====================================================================
    # Test 2: WITH_SCATTER_INDICES=True  (pre-computed scatter indices)
    # =====================================================================
    if rank == 0:
        print("\n--- WITH_SCATTER_INDICES=True (pre-computed scatter) ---")

    input_buf = nvshmem.core.tensor((num_tokens, hidden), dtype=torch.float32)
    input_buf.copy_(input_data)
    output_buf = nvshmem.core.tensor((max_recv_tokens, hidden), dtype=torch.float32)
    output_buf.fill_(0)

    # Dummy recv_buf_offset (unused in this mode, but must be passed)
    recv_buf_offset_dummy = torch.zeros(
        (world_size, experts_per_rank, world_size), dtype=torch.int32, device=device)

    input_cute   = from_dlpack(input_buf)
    output_cute  = from_dlpack(output_buf)
    topk_idx_cute = from_dlpack(topk_indices_tensor)
    scatter_cute = from_dlpack(token_dst_scatter_idx)
    recv_dummy_cute = from_dlpack(recv_buf_offset_dummy)
    ntok_cute    = from_dlpack(num_input_tokens_per_rank)

    if rank == 0:
        print("Compiling dispatch kernel (WITH_SCATTER_INDICES=True)...")
    compiled_scatter = _compile_kernel(
        dispatch_jit,
        input_cute, output_cute, topk_idx_cute, scatter_cute,
        recv_dummy_cute, ntok_cute,
        topk, experts_per_rank, rank, world_size, True,
    )

    torch.cuda.synchronize()
    dist.barrier()

    if rank == 0:
        print("Running dispatch kernel...")
    compiled_scatter(
        input_cute, output_cute, topk_idx_cute, scatter_cute,
        recv_dummy_cute, ntok_cute,
        topk,
    )

    torch.cuda.synchronize()
    nvshmem_stream = Device().create_stream()
    nvshmem.core.barrier(nvshmem.core.Teams.TEAM_WORLD, stream=nvshmem_stream)
    nvshmem_stream.sync()

    ok_scatter = check_dispatch(
        input_buf, output_buf, topk_indices_tensor, token_dst_scatter_idx,
        num_tokens, topk, experts_per_rank, rank, world_size,
        local_world_size=local_world_size, route_class_hits=route_class_hits)
    if rank == 0:
        print(f"  Dispatch check: {'PASS' if ok_scatter else 'FAIL'}")
    all_pass = all_pass and ok_scatter

    nvshmem.core.free_tensor(input_buf)

    # =====================================================================
    # Test 3: Combine (dispatch -> identity expert -> combine)
    # Reuse output_buf from dispatch as expert_output_buf (identity expert).
    # Combine reads from remote GPUs' output_buf and accumulates per token.
    # Expected: combine_output[t] = sum_j(input_data[t]) = topk * input_data[t]
    # =====================================================================
    if rank == 0:
        print("\n--- Combine (using dispatch scatter_idx, identity expert) ---")

    combine_output_buf = torch.zeros(
        (num_tokens, hidden), dtype=torch.float32, device=device)

    # Per-rank symmetric staging for inter-node get_warp. Mirrors the
    # role of DeepEP's `intra_node_reduce_buf` (pre-shipping accum) but
    # used here as a receiver-side per-token landing pad. Sized for the
    # local rank's token count (NVSHMEM symmetric: same shape on every
    # rank, but each rank only writes its own slice).
    inter_node_get_buf = nvshmem.core.tensor(
        (num_tokens, hidden), dtype=torch.float32)
    inter_node_get_buf.fill_(0)

    expert_output_cute = from_dlpack(output_buf)  # NVSHMEM symmetric, filled by dispatch
    combine_cute = from_dlpack(combine_output_buf)
    inter_node_get_cute = from_dlpack(inter_node_get_buf)
    topk_idx_cute = from_dlpack(topk_indices_tensor)
    scatter_cute = from_dlpack(token_dst_scatter_idx)
    ntok_cute = from_dlpack(num_input_tokens_per_rank)

    if rank == 0:
        print("Compiling combine kernel...")
    compiled_combine = _compile_kernel(
        combine_jit,
        expert_output_cute, combine_cute, inter_node_get_cute,
        topk_idx_cute, scatter_cute,
        ntok_cute, max_recv_tokens, hidden,
        topk, experts_per_rank, rank, local_world_size,
    )

    torch.cuda.synchronize()
    dist.barrier()

    if rank == 0:
        print("Running combine kernel...")
    compiled_combine(
        expert_output_cute, combine_cute, inter_node_get_cute,
        topk_idx_cute, scatter_cute,
        ntok_cute, max_recv_tokens, hidden,
    )

    torch.cuda.synchronize()
    nvshmem_stream = Device().create_stream()
    nvshmem.core.barrier(nvshmem.core.Teams.TEAM_WORLD, stream=nvshmem_stream)
    nvshmem_stream.sync()

    ok_combine = check_combine(
        combine_output_buf, output_buf, topk_indices_tensor,
        token_dst_scatter_idx, num_tokens, topk, experts_per_rank,
        rank, world_size)
    if rank == 0:
        print(f"  Combine check: {'PASS' if ok_combine else 'FAIL'}")
    all_pass = all_pass and ok_combine

    # Route-class coverage check. The classes that MUST be hit
    # depend on topology:
    #   - nnodes == 1 and local_world_size == 1: only "self".
    #   - nnodes == 1 and local_world_size >= 2: "self" + "intra_node_remote".
    #   - nnodes >= 2: all four classes must be hit.
    # Missing required classes is a hard test failure: if the kernel's
    # per-peer route is under-exercised, a regression in that route
    # would slip past correctness silently. The check runs on rank 0
    # (where route_class_hits is populated) and feeds into all_pass
    # BEFORE the global reduce, so an asymmetric flip propagates
    # cleanly to every rank without deadlocking the next collective.
    if rank == 0:
        print("\nRoute class hits (across both dispatch tests):")
        for cls in _ROUTE_CLASSES:
            n = route_class_hits.get(cls, 0)
            marker = "*" if n > 0 else "-"
            print(f"  {marker} {cls}: {n}")
        expected_classes = ["self"]
        if local_world_size >= 2:
            expected_classes.append("intra_node_remote")
        if nnodes >= 2:
            expected_classes += ["inter_node_same_local_rank",
                                 "inter_node_diff_local_rank"]
        missing = [cls for cls in expected_classes
                   if route_class_hits.get(cls, 0) == 0]
        if missing:
            print(f"\n  ROUTE-CLASS COVERAGE FAIL: nnodes={nnodes} "
                  f"local_world_size={local_world_size}; required classes "
                  f"{expected_classes} not all populated; missing {missing}. "
                  "The kernel's per-peer route is under-exercised — increase "
                  "--num_tokens or --num_experts so cross-node routing fires "
                  "in both the inter_node_same_local_rank and "
                  "inter_node_diff_local_rank dimensions.")
            all_pass = False

    # CRITICAL: `all_pass` is rank-local (each rank computed its own
    # check_dispatch / check_combine result; rank 0 also folds in the
    # route-class coverage gate above). Any subsequent code path that
    # does a collective (dist.all_gather for the baseline writer, or
    # dist.barrier in the benchmark) MUST gate on a global pass —
    # otherwise an asymmetric pass/fail across ranks deadlocks. Reduce
    # the local bool with op=MIN so any single rank's failure (including
    # rank 0's route-class fail) flips the global flag false on every
    # rank.
    pass_tensor = torch.tensor(int(all_pass), dtype=torch.int32, device=device)
    dist.all_reduce(pass_tensor, op=dist.ReduceOp.MIN)
    all_pass = bool(pass_tensor.item())

    # =====================================================================
    if rank == 0:
        print(f"\n{'='*40}")
        if all_pass:
            print("All tests PASSED!")
        else:
            print("Some tests FAILED!")
        print(f"{'='*40}")

    # Optional: persist outputs as a reference snapshot for the parity
    # checker. All ranks contribute via dist.all_gather; rank 0 writes
    # the consolidated .npz so the consumer can verify bit-identity
    # of every rank's output_buf / combine_output_buf / scatter_idx
    # against a fresh run. Single-rank-only snapshots are insufficient
    # because non-rank-0 ranks dispatch into THEIR OWN output_buf, and
    # the combine path on rank N can only validate against the
    # all-rank dispatch result.
    if save_baseline_to is not None and all_pass:
        import numpy as np

        def _gather_to_rank0(tensor):
            """All-gather a tensor; only rank 0 returns the stacked
            tensor (shape [world_size, *tensor.shape]). Other ranks
            return None to signal "don't write."""
            tensor = tensor.contiguous()
            gathered = [torch.zeros_like(tensor) for _ in range(world_size)]
            dist.all_gather(gathered, tensor)
            if rank == 0:
                return torch.stack(gathered, dim=0)
            return None

        output_buf_by_rank = _gather_to_rank0(output_buf)
        combine_buf_by_rank = _gather_to_rank0(combine_output_buf)
        topk_by_rank = _gather_to_rank0(topk_indices_tensor)
        scatter_by_rank = _gather_to_rank0(token_dst_scatter_idx)

        if rank == 0:
            save_dir = os.path.dirname(save_baseline_to)
            if save_dir:
                os.makedirs(save_dir, exist_ok=True)
            # Capture non-data metadata so a consumer can detect
            # baseline / fresh-run shape or topology mismatch up front.
            try:
                hostname = os.uname().nodename
            except Exception:
                hostname = "unknown"
            np.savez(
                save_baseline_to,
                # all-rank arrays
                output_buf_by_rank=output_buf_by_rank.detach().cpu().numpy(),
                combine_output_buf_by_rank=combine_buf_by_rank.detach().cpu().numpy(),
                topk_indices_by_rank=topk_by_rank.detach().cpu().numpy(),
                scatter_idx_by_rank=scatter_by_rank.detach().cpu().numpy(),
                # legacy rank-0 arrays kept for backwards-compat readers
                output_buf=output_buf.detach().cpu().numpy(),
                combine_output_buf=combine_output_buf.detach().cpu().numpy(),
                topk_indices=topk_indices_tensor.detach().cpu().numpy(),
                scatter_idx=token_dst_scatter_idx.detach().cpu().numpy(),
                # shape / topology metadata
                world_size=np.int32(world_size),
                local_world_size=np.int32(local_world_size),
                nnodes=np.int32(nnodes),
                num_tokens=np.int32(num_tokens),
                hidden=np.int32(hidden),
                num_experts=np.int32(num_experts),
                topk=np.int32(topk),
                seed=np.int32(42),  # base seed; per-rank seed = base + rank
                hostname=np.array(hostname),
            )
            print(f"  baseline saved to {save_baseline_to} "
                  f"(all-rank: {output_buf_by_rank.shape[0]} ranks)")

    # =====================================================================
    # Benchmark (reuse compiled kernels and NVSHMEM buffers)
    # =====================================================================
    if benchmark and all_pass:
        # Re-allocate input_buf for dispatch benchmark (was freed earlier)
        input_buf = nvshmem.core.tensor((num_tokens, hidden), dtype=torch.float32)
        input_buf.copy_(input_data)
        input_cute = from_dlpack(input_buf)
        output_cute = from_dlpack(output_buf)
        topk_idx_cute = from_dlpack(topk_indices_tensor)
        scatter_cute = from_dlpack(token_dst_scatter_idx)
        recv_dummy_cute = from_dlpack(recv_buf_offset_dummy)
        ntok_cute = from_dlpack(num_input_tokens_per_rank)

        # Run dispatch once to fill output_buf for combine benchmark
        compiled_scatter(
            input_cute, output_cute, topk_idx_cute, scatter_cute,
            recv_dummy_cute, ntok_cute, topk,
        )
        torch.cuda.synchronize()
        nvshmem_stream = Device().create_stream()
        nvshmem.core.barrier(nvshmem.core.Teams.TEAM_WORLD, stream=nvshmem_stream)
        nvshmem_stream.sync()

        combine_output_buf2 = torch.zeros(
            (num_tokens, hidden), dtype=torch.float32, device=device)
        expert_output_cute = from_dlpack(output_buf)
        combine_cute2 = from_dlpack(combine_output_buf2)
        # Reuse the per-rank symmetric staging buffer allocated for the
        # correctness run; the benchmark path doesn't reallocate.
        inter_node_get_cute_bench = from_dlpack(inter_node_get_buf)

        dispatch_args = (
            input_cute, output_cute, topk_idx_cute, scatter_cute,
            recv_dummy_cute, ntok_cute, topk,
        )
        combine_args = (
            expert_output_cute, combine_cute2, inter_node_get_cute_bench,
            topk_idx_cute, scatter_cute,
            ntok_cute, max_recv_tokens, hidden,
        )
        run_moe_benchmark(
            compiled_scatter, compiled_combine,
            dispatch_args, combine_args,
            num_tokens, hidden, topk, rank,
            warmup_iterations, iterations,
        )
        nvshmem.core.free_tensor(input_buf)

    nvshmem.core.free_tensor(inter_node_get_buf)
    nvshmem.core.free_tensor(output_buf)


def _bench_kernel(kernel_fn, args, warmup, iterations):
    """Simple CUDA event timing for a kernel call."""
    for _ in range(warmup):
        kernel_fn(*args)
    torch.cuda.synchronize()

    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    start.record()
    for _ in range(iterations):
        kernel_fn(*args)
    end.record()
    torch.cuda.synchronize()
    return start.elapsed_time(end) * 1000.0 / iterations  # us


def run_moe_benchmark(compiled_dispatch, compiled_combine,
                      dispatch_args, combine_args,
                      num_tokens, hidden, topk,
                      rank, warmup_iterations=10, iterations=100):
    """Benchmark dispatch and combine kernels separately."""

    if rank == 0:
        print(f"\n{'='*40}")
        print(f"MoE Benchmark (warmup={warmup_iterations}, iter={iterations})")
        print(f"{'='*40}")

    bytes_moved = num_tokens * topk * hidden * 4  # float32

    # Benchmark Dispatch
    if rank == 0:
        print("\n--- Benchmark: Dispatch ---")
    dist.barrier()
    dispatch_time = _bench_kernel(
        compiled_dispatch, dispatch_args, warmup_iterations, iterations)
    if rank == 0:
        bw_gbps = bytes_moved / (dispatch_time * 1e-6) / 1e9
        print(f"  Dispatch time: {dispatch_time:.2f} us  "
              f"BW: {bw_gbps:.2f} GB/s")

    # Benchmark Combine
    if rank == 0:
        print("\n--- Benchmark: Combine ---")
    dist.barrier()
    combine_time = _bench_kernel(
        compiled_combine, combine_args, warmup_iterations, iterations)
    if rank == 0:
        bw_gbps = bytes_moved / (combine_time * 1e-6) / 1e9
        print(f"  Combine time:  {combine_time:.2f} us  "
              f"BW: {bw_gbps:.2f} GB/s")

    if rank == 0:
        print(f"\n  Summary:")
        print(f"    Dispatch: {dispatch_time:.2f} us")
        print(f"    Combine:  {combine_time:.2f} us")
        print(f"    Total:    {dispatch_time + combine_time:.2f} us")


def run(num_tokens, hidden, num_experts, topk, benchmark=False,
        warmup_iterations=10, iterations=100, save_baseline_to=None):
    torchrun_uid_init_bcast()
    try:
        run_moe_dispatch_combine(num_tokens, hidden, num_experts, topk,
                                 benchmark=benchmark,
                                 warmup_iterations=warmup_iterations,
                                 iterations=iterations,
                                 save_baseline_to=save_baseline_to)
    finally:
        _finalize_kernels()
        torchrun_finalize()


def main():
    parser = argparse.ArgumentParser(
        description="MoE Dispatch + Combine kernels (Triton-distributed -> CuTeDSL)"
    )
    parser.add_argument("--num_tokens", default=2560, type=int)
    parser.add_argument("--hidden", default=7168, type=int)
    parser.add_argument("--num_experts", default=256, type=int,
                        help="Total experts, must be divisible by world_size")
    parser.add_argument("--topk", default=8, type=int)
    parser.add_argument("--benchmark", action="store_true",
                        help="Run performance benchmarks after correctness tests")
    parser.add_argument("--warmup_iterations", default=10, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--save-baseline-to", default=None,
                        help="If set, rank 0 saves output_buf + combine_output_buf "
                             "(plus indices and shape constants) as a .npz file at "
                             "this path. Only writes when both check_dispatch and "
                             "check_combine pass. A subsequent run can compare "
                             "against this file to verify bit-identity.")
    args = parser.parse_args()

    run(args.num_tokens, args.hidden, args.num_experts, args.topk,
        benchmark=args.benchmark,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        save_baseline_to=args.save_baseline_to)


if __name__ == "__main__":
    main()
