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
TMEM load STAT+SPARSIFY example for Rubin SM107.

Loads F32 data into TMEM via a TMEM store (``tcgen05.st``), then reads it
back via a TMEM load with the ``.red.spcompress`` qualifiers
(``tcgen05.ld.red.spcompress``, exposed as ``tcgen05.LdRedSPCompress32x32bOp``)
to produce 2:4 compressed data, packed metadata, and a per-row MAXABS
statistic reduction value.

Data flow::

    GMEM[F32] --global load--> RMEM --tcgen05.st--> TMEM
        --tcgen05.ld.red.spcompress--> RMEM --global store--> GMEM

The TMEM store and the TMEM load both use the ``.32dp32bit`` layout, so
they are natural inverses on a single unified TMEM address space.

.. code-block:: bash

    python examples/cute/rubin/tutorial/tmem_load_sparsify.py --mn 256,256

Constraints:
    * M must be divisible by 128
    * N must be divisible by 256
"""

import argparse
from typing import Tuple

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.runtime import from_dlpack

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
io_dtype = cutlass.Float32
tile_mn = (128, 256)
threads_per_cta = 128

# 65536 = 1 << 16 encodes the TMEM row-group in the logical address.
TMEM_ROW_STRIDE = 65536
TMEM_NUM_COLS = 512

# TMEM copy parameters (shared by the TMEM store and the TMEM load)
tmem_repeat = tcgen05.Repetition.x128
subtile_cnt = tile_mn[1] // tmem_repeat.value

# SPARSIFY output sizes per thread per sub-tile
sp_compressed_per_thread = tmem_repeat.value // 2
sp_meta_uint8_per_thread = tmem_repeat.value // 8
sp_stat_per_thread = 1


# ---------------------------------------------------------------------------
# Shared memory layout
# ---------------------------------------------------------------------------
@cute.struct
class SharedStorage:
    """Shared memory for TMEM allocation handshake."""

    tmem_holding_buf: cutlass.Int32


# ---------------------------------------------------------------------------
# GPU Kernel
# ---------------------------------------------------------------------------
@cute.kernel
def kernel(
    mInput: cute.Tensor,
    mOutCompressed: cute.Tensor,
    mOutMetadata: cute.Tensor,
    mOutStat: cute.Tensor,
):
    """TMEM load STAT+SPARSIFY kernel.

    For each CTA tile (128 x 256):
      1. Load F32 from GMEM into RMEM  (global load)
      2. Write RMEM into TMEM          (tcgen05.st, .32dp32bit)
      3. Read TMEM with STAT+SPARSIFY  (tcgen05.ld.red.spcompress, 2:4 MAXABS)
      4. Store compressed data + metadata + stat to GMEM  (global store)

    :param mInput:         (M, N) F32 input matrix.
    :param mOutCompressed: (M, N/2) F32 compressed output.
    :param mOutMetadata:   (M, N/8) U8 packed 2-bit metadata.
    :param mOutStat:       (M, N/tmem_repeat) F32 per-row MAXABS stat.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    #
    # Allocate TMEM
    #
    smem = cutlass.memory.SmemAllocator()
    storage = smem.allocate(SharedStorage)

    tmem_alloc_barrier = pipeline.NamedBarrier(
        barrier_id=1,
        num_threads=threads_per_cta,
    )
    tmem_alloc = cutlass.memory.TmemAllocator(
        storage.tmem_holding_buf.ptr,
        barrier_for_retrieve=tmem_alloc_barrier,
    )
    tmem_alloc.allocate(TMEM_NUM_COLS)

    #
    # Build TMEM tensor
    #
    tmem_alloc.wait_for_alloc()
    tmem_ptr = tmem_alloc.retrieve_ptr(io_dtype)

    tmem_layout = cute.make_layout(
        ((tile_mn[0], tile_mn[1]), 1, 1),
        stride=((TMEM_ROW_STRIDE, 1), 0, 0),
    )
    tTmemBuf = cute.make_tensor(tmem_ptr, tmem_layout)

    # Sub-tile into subtile_cnt pieces along N
    subtile_shape = ((tile_mn[0], tile_mn[1] // subtile_cnt),)
    tTmemBuf_sub = cute.zipped_divide(tTmemBuf, subtile_shape)

    #
    # Partition GMEM input with same mode structure
    #
    coord_mn = (bidx, bidy, None)
    gInput = cute.local_tile(
        mInput,
        (*tile_mn, 1),
        coord_mn,
        proj=(1, 1, None),
    )
    # Wrap (M_tile, N_tile) -> ((M_tile, N_tile), 1, 1) to match TMEM
    gmem_stride_m = cute.get(gInput.layout.stride, [0])
    gInput_tmem = cute.make_tensor(
        gInput.iterator,
        cute.make_layout(
            ((tile_mn[0], tile_mn[1]), 1, 1),
            stride=((gmem_stride_m, 1), 0, 0),
        ),
    )
    gInput_sub = cute.zipped_divide(gInput_tmem, subtile_shape)

    #
    # TMEM store tiled copy: RMEM -> TMEM
    #
    tmem_st_atom = cute.make_copy_atom(
        tcgen05.St32x32bOp(tmem_repeat),
        io_dtype,
    )
    tmem_st_tiled_copy = tcgen05.make_tmem_copy(
        tmem_st_atom,
        tTmemBuf_sub[None, 0],
    )
    tmem_st_thr_copy = tmem_st_tiled_copy.get_slice(tidx)

    tStSrc = tmem_st_thr_copy.partition_S(gInput_sub)  # GMEM source
    tStDst = tmem_st_thr_copy.partition_D(tTmemBuf_sub)  # TMEM destination
    rInput = cute.make_rmem_tensor(tStSrc[None, None, 0].shape, io_dtype)

    #
    # TMEM load STAT+SPARSIFY tiled copy: TMEM -> RMEM
    #
    sp_atom = cute.make_copy_atom(
        tcgen05.LdRedSPCompress32x32bOp(
            repeat=tmem_repeat,
            redOp=tcgen05.TmemLoadRedOp.MAXABS,
        ),
        io_dtype,
    )
    sp_tiled_copy = tcgen05.make_tmem_copy(
        sp_atom,
        tTmemBuf_sub[None, 0],
    )
    sp_thr_copy = sp_tiled_copy.get_slice(tidx)
    tSP_src = sp_thr_copy.partition_S(tTmemBuf_sub)

    # Compressed-data register buffer (sparse element type for MLIR)
    sparse_dtype = cute.get_sparse_elem_type(
        num_logical=2,
        num_phys=1,
        elem_type=io_dtype,
    )
    rData_raw = cute.make_rmem_tensor(
        ((sp_compressed_per_thread, 1), 1),
        io_dtype,
    )
    rData = cute.make_tensor(
        cute.recast_ptr(rData_raw.iterator, dtype=sparse_dtype),
        rData_raw.layout,
    )

    # Metadata register buffer (sparse element type for MLIR)
    meta_sparse_dtype = cute.get_sparse_elem_type(
        num_logical=8,
        num_phys=1,
        elem_type=cutlass.Uint8,
    )
    rMeta_raw = cute.make_rmem_tensor(
        ((sp_meta_uint8_per_thread, 1), 1),
        cutlass.Uint8,
    )
    rMeta = cute.make_tensor(
        cute.recast_ptr(rMeta_raw.iterator, dtype=meta_sparse_dtype),
        rMeta_raw.layout,
    )

    # STAT reduction register buffer (1 F32 per thread per sub-tile)
    rStat = cute.make_rmem_tensor(
        (sp_stat_per_thread, 1),
        io_dtype,
    )

    #
    # GMEM output tiling for compressed data, metadata, and stat
    #
    gOutComp = cute.local_tile(
        mOutCompressed,
        (tile_mn[0], tile_mn[1] // 2, 1),
        coord_mn,
        proj=(1, 1, None),
    )
    gOutMeta = cute.local_tile(
        mOutMetadata,
        (tile_mn[0], tile_mn[1] // 8, 1),
        coord_mn,
        proj=(1, 1, None),
    )
    gOutStat = cute.local_tile(
        mOutStat,
        (tile_mn[0], subtile_cnt, 1),
        coord_mn,
        proj=(1, 1, None),
    )

    #
    # Main loop: per sub-tile
    #
    tmem_alloc.relinquish_alloc_permit()

    for i in cutlass.range(subtile_cnt):
        # (a) GMEM -> RMEM
        cute.autovec_copy(tStSrc[None, None, i], rInput)

        # (b) TMEM store: RMEM -> TMEM
        cute.copy(tmem_st_tiled_copy, rInput, tStDst[None, None, i])

        # (c) TMEM load STAT+SPARSIFY: TMEM -> RMEM
        cute.copy(
            sp_tiled_copy,
            tSP_src[None, None, i],
            (rData, rMeta, rStat),
        )

        # (d) Store compressed F32 -> GMEM
        gOutComp_i = cute.local_tile(
            gOutComp,
            (1, sp_compressed_per_thread),
            (tidx, i),
        )
        cute.autovec_copy(
            cute.flatten(rData_raw),
            cute.flatten(gOutComp_i),
        )

        # (e) Store metadata U8 -> GMEM
        gOutMeta_i = cute.local_tile(
            gOutMeta,
            (1, sp_meta_uint8_per_thread),
            (tidx, i),
        )
        cute.autovec_copy(
            cute.flatten(rMeta_raw),
            cute.flatten(gOutMeta_i),
        )

        # (f) Store STAT F32 -> GMEM
        gOutStat_i = cute.local_tile(
            gOutStat,
            (1, sp_stat_per_thread),
            (tidx, i),
        )
        cute.autovec_copy(rStat, gOutStat_i)

    #
    # Cleanup
    #
    pipeline.sync(barrier_id=1)
    tmem_alloc.free(tmem_ptr)


# ---------------------------------------------------------------------------
# Host JIT
# ---------------------------------------------------------------------------
@cute.jit
def host_function(
    inp: cute.Tensor,
    out_compressed: cute.Tensor,
    out_metadata: cute.Tensor,
    out_stat: cute.Tensor,
):
    """Launch the TMEM load STAT+SPARSIFY kernel."""
    grid = cute.ceil_div((*inp.layout.shape, 1), tile_mn)
    kernel(inp, out_compressed, out_metadata, out_stat).launch(
        grid=grid,
        block=(threads_per_cta, 1, 1),
    )


# ---------------------------------------------------------------------------
# CPU Reference
# ---------------------------------------------------------------------------
def sparsify_reference_maxabs(dense):
    """2:4 MAXABS sparsification with ISA-faithful tie-breaking.

    For every group of 4 consecutive values along the last dimension,
    selects the 2 with the largest absolute value.  Tie-breaking follows
    the ISA convention (last index wins on >=).

    :param dense: (M, N) F32 tensor on CUDA.
    :returns: (compressed, metadata_nibbles)
        - compressed:       (M, N/2) F32
        - metadata_nibbles: (M, N/4) I32, each value = lo_idx | (hi_idx << 2)
    """
    import torch

    assert dense.shape[-1] % 4 == 0
    N = dense.shape[-1]
    leading = dense.shape[:-1]

    grouped = dense.reshape(*leading, N // 4, 4)
    abs_grouped = grouped.abs()

    # First pass: last index with max |value| (ISA uses >= scan)
    max_abs = abs_grouped.max(dim=-1, keepdim=True).values
    is_max = abs_grouped >= max_abs
    idx0 = 3 - is_max.flip(dims=[-1]).to(torch.int64).argmax(dim=-1)

    # Second pass: exclude idx0, find last remaining max |value|
    mask = torch.nn.functional.one_hot(idx0, 4).bool()
    abs_remaining = abs_grouped.clone()
    abs_remaining[mask] = -1
    max_abs2 = abs_remaining.max(dim=-1, keepdim=True).values
    is_max2 = abs_remaining >= max_abs2
    idx1 = 3 - is_max2.flip(dims=[-1]).to(torch.int64).argmax(dim=-1)

    lo = torch.minimum(idx0, idx1)
    hi = torch.maximum(idx0, idx1)
    top2 = torch.stack([lo, hi], dim=-1)

    compressed = torch.gather(grouped, -1, top2).reshape(*leading, N // 2)
    metadata_nibbles = (top2[..., 0] | (top2[..., 1] << 2)).to(torch.int32)
    return compressed, metadata_nibbles


def stat_reference_maxabs(dense, group_size):
    """Per-row MAXABS statistic over groups of consecutive columns.

    For every group of ``group_size`` consecutive columns, computes the
    maximum absolute value across the group for each row.

    :param dense: (M, N) F32 tensor.
    :param group_size: Number of columns per reduction group.
    :returns: (M, N / group_size) F32 tensor of MAXABS values.
    """

    M, N = dense.shape
    assert N % group_size == 0
    grouped = dense.reshape(M, N // group_size, group_size)
    return grouped.abs().amax(dim=-1)


def pack_metadata_i32(metadata_nibbles):
    """Pack 8 metadata nibbles into one I32 word.

    :param metadata_nibbles: (..., N/4) I32 tensor.
    :returns: (..., N/32) uint32 tensor.
    """
    import torch

    assert metadata_nibbles.shape[-1] % 8 == 0
    words = metadata_nibbles.reshape(
        *metadata_nibbles.shape[:-1],
        metadata_nibbles.shape[-1] // 8,
        8,
    ).to(torch.int64)
    packed = torch.zeros(
        words.shape[:-1],
        dtype=torch.int64,
        device=words.device,
    )
    for i in range(8):
        packed = packed | (words[..., i] << (4 * i))
    return packed.to(torch.uint32)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _wrap_cute_tensor(tensor, divisibility: int) -> cute.Tensor:
    """Wrap a PyTorch tensor as a CuTe tensor with dynamic layout markings.

    :param tensor: PyTorch CUDA tensor.
    :param divisibility: Divisibility hint for the dynamic compact-shape mode.
    :returns: CuTe tensor ready for kernel consumption.
    """
    return (
        from_dlpack(tensor, assumed_align=32)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=divisibility)
    )


def _parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    """Parse a comma-separated string of integers.

    :param s: Input string, e.g. ``"256,256"``.
    :returns: Tuple of parsed integers.
    :raises argparse.ArgumentTypeError: On malformed input.
    """
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


# ---------------------------------------------------------------------------
# Run & Verify
# ---------------------------------------------------------------------------
def run(mn: Tuple[int, int], tolerance: float) -> None:
    """Run the kernel and verify against CPU reference.

    :param mn: (M, N) problem dimensions.
    :param tolerance: Absolute tolerance for compressed-data comparison.
    """
    import torch

    m, n = mn

    stat_groups = n // tmem_repeat.value

    print("Running TMEM load STAT+SPARSIFY test with:")
    print(f"  Problem (M, N) : ({m}, {n})")
    print(f"  Tile (M, N)    : {tile_mn}")
    print(f"  dtype          : {io_dtype}")
    print(f"  STAT groups    : {stat_groups} (group_size={tmem_repeat.value})")
    print(f"  Tolerance      : {tolerance}")

    torch.manual_seed(42)

    # Allocate tensors
    inp = torch.randn(m, n, device="cuda", dtype=torch.float32)
    out_comp = torch.zeros(m, n // 2, device="cuda", dtype=torch.float32)
    out_meta = torch.zeros(m, n // 8, device="cuda", dtype=torch.uint8)
    out_stat = torch.zeros(m, stat_groups, device="cuda", dtype=torch.float32)

    # Launch kernel
    host_function(
        _wrap_cute_tensor(inp, n),
        _wrap_cute_tensor(out_comp, n // 2),
        _wrap_cute_tensor(out_meta, n // 8),
        _wrap_cute_tensor(out_stat, stat_groups),
        no_cache=True,
    )

    # CPU reference
    comp_ref, meta_nibbles = sparsify_reference_maxabs(inp)
    meta_ref = pack_metadata_i32(meta_nibbles)
    stat_ref = stat_reference_maxabs(inp, tmem_repeat.value)
    meta_gpu_u8 = out_meta.cpu()
    meta_ref_u8 = meta_ref.cpu().view(torch.uint8)

    # Verify compressed data
    print("[Verify] Compressed data ...", end=" ")
    torch.testing.assert_close(
        out_comp.cpu(),
        comp_ref.cpu(),
        atol=tolerance,
        rtol=0,
    )
    print("PASSED!")

    # Verify packed metadata
    print("[Verify] Packed metadata  ...", end=" ")
    if not torch.equal(meta_gpu_u8, meta_ref_u8):
        raise AssertionError("Packed metadata mismatch against CPU reference.")
    print("PASSED!")

    # Verify STAT reduction values
    print("[Verify] STAT maxabs     ...", end=" ")
    torch.testing.assert_close(
        out_stat.cpu(),
        stat_ref.cpu(),
        atol=tolerance,
        rtol=0,
    )
    print("PASSED!")


if __name__ == "__main__":
    import torch

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    parser = argparse.ArgumentParser(
        description="Minimal TMEM load STAT+SPARSIFY example (Rubin SM107)",
    )
    parser.add_argument(
        "--mn",
        type=_parse_comma_separated_ints,
        default=(256, 256),
        help="M,N dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=0.0,
        help="Absolute tolerance for verification (default: exact)",
    )
    args = parser.parse_args()

    if len(args.mn) != 2:
        parser.error("--mn must contain exactly 2 values")
    if args.mn[0] % tile_mn[0] != 0:
        parser.error(f"M must be divisible by {tile_mn[0]}")
    if args.mn[1] % tile_mn[1] != 0:
        parser.error(f"N must be divisible by {tile_mn[1]}")

    print("[DSL INFO] Compiling TMEM load STAT+SPARSIFY kernel for SM107")
    print(f"[DSL INFO] Problem (M, N): {tuple(args.mn)}")
    print(f"[DSL INFO] Tile    (M, N): {tile_mn}")

    run(tuple(args.mn), args.tolerance)
    print("PASS")
