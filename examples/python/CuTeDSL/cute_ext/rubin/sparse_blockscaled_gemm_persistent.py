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
#
# CuTe DSL staging expressions intentionally retain otherwise-unused Python
# locals for layout and descriptor provenance.
# ruff: noqa: F841

r"""SM107 sparse FP4 block-scaled GEMM.

A/B use E2M1 FP4 and E8M0 scales per 32 K elements; A is 2:4 sparse.
K extents below count logical elements before compression, not bytes.
SF denotes SFA/SFB together, and E is the sparse metadata.

Each MMA group has one CTA (instruction M = 128) or two CTAs (M = 256), with
N = 128 or 256. Doubling the output tile's M extent reuses B across two MMA
operations (FILL then LASTUSE).

Data flow for one output tile (W0-W7 are the eight warps in each CTA)::

  Global inputs       Shared memory          MMA-group leader W4
  A/B -- W5 TMA -----> [A/B stages] ----------------------> MMA
  E   -- W5 TMA -----> [E stages]  -- W4 S2T --> TMEM E ----^
  SF  -- W6 TMA -----> [SF stages] -- W4 S2T --> TMEM SF ---^
                                                         |
                                                  TMEM accumulator
                                                         |
                                               W0-3 T2R in each CTA
                                                         v
                                                     Registers
                                                  /             \
                                    direct R2G -> C       R2S -> shared C
                                                                  |
                                                         TMA store -> C
  W7 is idle. W5 loads E before A/B; W6 runs independently.

A/B stages are released after their final MMA read, SF/E after their final
S2T, and shared C after its TMA store completes.
W5 registers all A/B transfer bytes before publishing their shared stage; W6
does the same for SFA/SFB. Multicast release counts and masks cover every reader.
ACC has one stage, released after every epilogue warp finishes its final T2R.
Whole-tile register staging can overlap stores with the next MMA; the epilogue
helpers document its register-budget tradeoff.

Each mainloop block covers 768 K elements: four MMA steps of 192 elements
consume three A/B load stages of 256 elements (4 * 192 = 3 * 256 = 768).
For K <= 192, only one MMA step and one A/B stage are needed. Larger problems
keep all pipeline transitions even when padded MMA steps are skipped. All
roles follow the same output-tile sequence and wait for pending work at exit.

Supported configurations:

* A/B stored values are contiguous along K; output columns are contiguous.
  Output may be FP32, FP16, BF16 or FP8 E4M3/E5M2. M/L are positive; K is a
  positive multiple of 64. N is a positive multiple of 8 FP32, 16 FP16/BF16
  or 32 FP8 elements, keeping output rows 32-byte aligned.
* Cluster M/N are positive powers of two, with at most 16 CTAs total.
  Two-CTA instructions require even cluster M. Geometry is fixed per launch;
  selecting a smaller cluster requires constructing that schedule explicitly.
* Scale formats other than E8M0 and scale vectors other than 32 require
  corresponding MMA/copy/storage changes. M-contiguous output requires a
  matching epilogue. FP4 or block-scaled output requires group quantization
  and output scale factors; the current epilogue converts individual elements.

Run and verify one configuration::

    python sparse_blockscaled_gemm_persistent.py --mnkl 256,256,768,1 \
        --mma_inst_shape 256,256,192 --mma_tiler 256,256,768 \
        --cluster_shape_mn 2,1

Tile, cluster, pipeline stages, load sharing, loop unrolling and launch limits
are caller-controlled. ``make_kernel`` constructs exactly that configuration;
``run`` and the CLI use fixed stage caps when none are supplied. Buffer counts
may be reduced to fit the supplied SMEM budget. Workload tuning belongs in the
caller or benchmark harness. Pass compiler flags directly to ``cute.compile``
or through ``run(ptxas_options=...)`` / ``--ptxas_options``.
"""

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path

import torch

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as bs_layout
import cutlass.utils.rubin_helpers as sm107_utils
from cutlass.cute import experimental as cute_ext
from cutlass.cute.nvgpu import OperandMajorMode, cpasync, tcgen05
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.testing import assert_ as runtime_assert
from cutlass.base_dsl.typing import Integer
from cutlass.tensor_utils import LayoutEnum
from cutlass.utils.gemm.sm100 import transform_partitioned_tensor_layout
from cutlass.utils.gemm.tensor_utils import create_scale_factor_tensor

# Direct execution needs the shared CuTeDSL helpers root, as in other examples.
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from helpers import cli_helper as cli
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)


@dataclass(frozen=True)
class PipelineStageCaps:
    """Maximum buffer counts for A/B, scale factors, metadata and output.

    ``ab``, ``sf``, ``e`` and ``c`` select those four limits, respectively.
    The stage calculator may lower a limit to fit the supplied SMEM budget.
    ``c`` must be zero for direct store and positive for TMA store. A TMA-store
    depth is selected only when a complete output tile returns its pipeline
    cursor to stage zero, which lets every persistent work tile reconstruct the
    same CTA-local cursor safely.
    """

    ab: int
    sf: int
    e: int
    c: int = 0

    def __post_init__(self) -> None:
        for name, value in (
            ("ab", self.ab),
            ("sf", self.sf),
            ("e", self.e),
            ("c", self.c),
        ):
            if type(value) is not int:
                raise TypeError(f"pipeline stage cap {name} must be an integer")
        if min(self.ab, self.sf, self.e) <= 0 or self.c < 0:
            raise ValueError(
                "AB/SF/E stage caps must be positive and C must be non-negative"
            )


@dataclass(frozen=True)
class _PipelineStages:
    """Pipeline depths and their modeled per-CTA shared-memory footprint."""

    ab: int
    sf: int
    e: int
    c: int
    smem_bytes: int


@dataclass(frozen=True)
class _PipelineStageBytes:
    """Raw storage bytes contributed by one stage of each operand ring."""

    a: int
    b: int
    sfa: int
    sfb: int
    e: int
    c: int


@dataclass(frozen=True)
class _SparseInputAttributes:
    """Validated tensor extents and zero-copy views for one host invocation.

    These values belong to the current host trace. They are unpacked before
    launch and never cached on the kernel instance or passed as a kernel argument.
    """

    mnkl: tuple[Integer, Integer, Integer, Integer]
    sfa_tma_carrier: cute.Tensor
    sfb_tma_carrier: cute.Tensor
    e_sparse: cute.Tensor


@cute.jit
def epilogue_direct_store(
    cta_tile_shape_mnk,
    use_2cta_instrs: cutlass.Constexpr,
    epi_tile_shape,
    tmem_acc,
    gmem_d,
    cta_d_tile_coord,
    tid_x_in_group,
    acc_pipeline,
    predicate_output_store: cutlass.Constexpr,
    staged_register_budget: cutlass.Constexpr,
):
    """Copy FP32 TMEM accumulators through registers to global output.

    ``stage_accumulator`` holds all subtiles of this CTA's output tile as FP32
    values across the epilogue threads' registers. Otherwise, hold either the
    whole tile in the converted output type (``stage_converted``), or just one
    subtile at a time. Converted whole-tile staging is limited to one-CTA
    instructions. Staging here means register storage, not additional
    accumulator-pipeline stages.

    ``staged_register_budget`` limits each thread's storage in FP32-register
    units; zero selects the one-subtile path. Whole-tile staging releases TMEM
    before any global stores, allowing the next tile's MMA to overlap them.
    The one-subtile path releases it after the final T2R, before that subtile's
    conversion and store. Each epilogue warp signals its own completed reads.
    """

    acc_dtype = tmem_acc.element_type
    d_dtype = gmem_d.element_type
    d_major_mode = LayoutEnum.from_tensor(gmem_d)
    copy_atom_t2r = sm100_utils.get_tmem_load_op(
        cta_tile_shape_mnk,
        d_major_mode,
        d_dtype,
        acc_dtype,
        epi_tile_shape,
        use_2cta_instrs,
    )
    acc_epi = cute.flat_divide(tmem_acc, epi_tile_shape)
    tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi[None, None, 0, 0])
    gmem_d_tile = cute.zipped_divide(
        gmem_d, (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])
    )[(None, None), cta_d_tile_coord]
    gmem_d_epi = cute.flat_divide(gmem_d_tile, epi_tile_shape)
    gmem_d_epi_grouped = cute.group_modes(gmem_d_epi, 2, 4)
    acc_epi_grouped = cute.group_modes(acc_epi, 2, 4)
    epi_subtile_cnt = cute.size(gmem_d_epi_grouped, mode=[2])
    thr_copy_t2r = tiled_copy_t2r.get_slice(tid_x_in_group)
    rmem_layout = cute_ext.make_t2r_rmem_layout(
        tiled_copy_t2r,
        gmem_d_epi,
        tid_x_in_group,
    )
    # Prefer all FP32 subtiles if they fit. Otherwise, converted staging needs
    # one FP32 subtile for conversion plus all output subtiles in the narrower
    # type. If neither fits, reuse one subtile's registers throughout.
    # The compiler waits for each TMEM load before using its register values;
    # releasing ACC earlier changes overlap, not register-read safety.
    acc_registers = cute.cosize(rmem_layout)
    d_registers = acc_registers * d_dtype.width // acc_dtype.width
    stage_accumulator = acc_registers * epi_subtile_cnt <= staged_register_budget
    # Converted staging is restricted to one-CTA instructions.
    stage_converted = (
        not stage_accumulator
        and not use_2cta_instrs
        and (acc_registers + epi_subtile_cnt * d_registers <= staged_register_budget)
    )
    acc_depth = epi_subtile_cnt if stage_accumulator else 1
    d_depth = epi_subtile_cnt if stage_converted else 1
    rmem_acc = cute_ext.allocate(
        acc_dtype,
        cute.AddressSpace.rmem,
        cute.append(
            rmem_layout,
            cute.make_layout(acc_depth, stride=cute.cosize(rmem_layout)),
        ),
        alignment=32,
    )
    rmem_d = cute_ext.allocate(
        d_dtype,
        cute.AddressSpace.rmem,
        cute.append(
            rmem_layout,
            cute.make_layout(d_depth, stride=cute.cosize(rmem_layout)),
        ),
        alignment=32,
    )
    # Define this before the branch so both traced paths have a value.
    copy_atom_r2g = None
    if cutlass.const_expr(not predicate_output_store):
        # The full-tile entry point preserves the T2R thread map for a
        # 256-bit store. Partition D before the explicit copy
        # so its V/Rest profile matches the CopyR2G instruction exactly.
        copy_atom_r2g = cute.make_copy_atom(
            cute.nvgpu.CopyR2GOp(),
            d_dtype,
            num_bits_per_copy=256,
            l1c_evict_priority=cute.nvgpu.CacheEvictionPriority.NO_ALLOCATE,
        )
    # The bodies are written out per form rather than shared through a helper:
    # the DSL rejects a nested function that captures values used inside a
    # staged loop (SCOPE_CLOSURE_CAPTURE).
    if cutlass.const_expr(stage_accumulator):
        for subtile_idx in range(epi_subtile_cnt):
            cute_ext.partition_and_copy(
                thr_copy_t2r,
                acc_epi_grouped[None, None, subtile_idx],
                rmem_acc[None, None, None, subtile_idx],
            )
        # One elected lane per epilogue warp signals that ACC can be reused.
        acc_pipeline.consumer_release_and_advance(elect_one_sync=True)
        for subtile_idx in range(epi_subtile_cnt):
            rmem_d_slice = rmem_d[None, None, None, 0]
            rmem_d_slice.store(
                rmem_acc[None, None, None, subtile_idx].load().to(d_dtype)
            )
            gmem_subtile = gmem_d_epi_grouped[None, None, subtile_idx]
            if cutlass.const_expr(predicate_output_store):
                # Keep edge stores rooted at D so the compiler checks stores
                # against the original problem bounds.
                cute_ext.partition_and_copy(thr_copy_t2r, rmem_d_slice, gmem_subtile)
            else:
                fast_gmem_subtile = cute_ext.partition(
                    gmem_subtile,
                    tid_x_in_group,
                    layout_tv=thr_copy_t2r.layout_dst_tv_tiled,
                    tiler=thr_copy_t2r.tiler_mn,
                )
                fast_gmem_subtile = cute.logical_divide(
                    cute.group_modes(
                        fast_gmem_subtile, 0, cute.rank(fast_gmem_subtile)
                    ),
                    cute.make_layout(256 // d_dtype.width),
                )
                fast_rmem_d = cute.logical_divide(
                    cute.group_modes(rmem_d_slice, 0, cute.rank(rmem_d_slice)),
                    cute.make_layout(256 // d_dtype.width),
                )
                cute_ext.copy(fast_rmem_d, fast_gmem_subtile, copy_atom=copy_atom_r2g)
    elif cutlass.const_expr(stage_converted):
        for subtile_idx in range(epi_subtile_cnt):
            cute_ext.partition_and_copy(
                thr_copy_t2r,
                acc_epi_grouped[None, None, subtile_idx],
                rmem_acc[None, None, None, 0],
            )
            rmem_d[None, None, None, subtile_idx].store(
                rmem_acc[None, None, None, 0].load().to(d_dtype)
            )
        acc_pipeline.consumer_release_and_advance(elect_one_sync=True)
        for subtile_idx in range(epi_subtile_cnt):
            rmem_d_slice = rmem_d[None, None, None, subtile_idx]
            gmem_subtile = gmem_d_epi_grouped[None, None, subtile_idx]
            if cutlass.const_expr(predicate_output_store):
                # Keep edge stores rooted at D so the compiler checks stores
                # against the original problem bounds.
                cute_ext.partition_and_copy(thr_copy_t2r, rmem_d_slice, gmem_subtile)
            else:
                fast_gmem_subtile = cute_ext.partition(
                    gmem_subtile,
                    tid_x_in_group,
                    layout_tv=thr_copy_t2r.layout_dst_tv_tiled,
                    tiler=thr_copy_t2r.tiler_mn,
                )
                fast_gmem_subtile = cute.logical_divide(
                    cute.group_modes(
                        fast_gmem_subtile, 0, cute.rank(fast_gmem_subtile)
                    ),
                    cute.make_layout(256 // d_dtype.width),
                )
                fast_rmem_d = cute.logical_divide(
                    cute.group_modes(rmem_d_slice, 0, cute.rank(rmem_d_slice)),
                    cute.make_layout(256 // d_dtype.width),
                )
                cute_ext.copy(fast_rmem_d, fast_gmem_subtile, copy_atom=copy_atom_r2g)
    else:
        for subtile_idx in cutlass.range_constexpr(epi_subtile_cnt):
            cute_ext.partition_and_copy(
                thr_copy_t2r,
                acc_epi_grouped[None, None, subtile_idx],
                rmem_acc[None, None, None, 0],
            )
            if cutlass.const_expr(subtile_idx == epi_subtile_cnt - 1):
                acc_pipeline.consumer_release_and_advance(elect_one_sync=True)
            rmem_d_slice = rmem_d[None, None, None, 0]
            rmem_d_slice.store(rmem_acc[None, None, None, 0].load().to(d_dtype))
            gmem_subtile = gmem_d_epi_grouped[None, None, subtile_idx]
            if cutlass.const_expr(predicate_output_store):
                # Keep edge stores rooted at D so the compiler checks stores
                # against the original problem bounds.
                cute_ext.partition_and_copy(thr_copy_t2r, rmem_d_slice, gmem_subtile)
            else:
                fast_gmem_subtile = cute_ext.partition(
                    gmem_subtile,
                    tid_x_in_group,
                    layout_tv=thr_copy_t2r.layout_dst_tv_tiled,
                    tiler=thr_copy_t2r.tiler_mn,
                )
                fast_gmem_subtile = cute.logical_divide(
                    cute.group_modes(
                        fast_gmem_subtile, 0, cute.rank(fast_gmem_subtile)
                    ),
                    cute.make_layout(256 // d_dtype.width),
                )
                fast_rmem_d = cute.logical_divide(
                    cute.group_modes(rmem_d_slice, 0, cute.rank(rmem_d_slice)),
                    cute.make_layout(256 // d_dtype.width),
                )
                cute_ext.copy(fast_rmem_d, fast_gmem_subtile, copy_atom=copy_atom_r2g)
    return acc_pipeline


@cute.jit
def epilogue_tma_store(
    cta_tile_shape_mnk,
    use_2cta_instrs: cutlass.Constexpr,
    epi_tile_shape,
    tmem_acc,
    gmem_d,
    cta_d_tile_coord,
    tid_x_in_group,
    acc_pipeline,
    tma_store_stages: cutlass.Constexpr,
    tma_store_arrival_count: cutlass.Constexpr,
    staged_register_budget: cutlass.Constexpr,
    static_store_index: cutlass.Constexpr = False,
):
    """Copy TMEM accumulators through registers and shared memory to TMA stores.

    ``stage_accumulator`` holds all subtiles of this CTA's output tile as FP32
    values across the epilogue threads' registers, rather than one subtile at
    a time. This is register staging, not additional accumulator-pipeline
    stages. The per-thread ``staged_register_budget`` is in FP32-register units;
    zero selects the one-subtile path.

    Each participating warp releases ACC after its final T2R. Whole-tile
    staging does this before any conversion or output copies; the one-subtile
    path does it before converting and copying the last subtile. Both paths
    then use a separate SMEM ring for TMA stores. Its depth divides the number
    of output subtiles, returning its index to zero after each output tile.
    """

    acc_dtype = tmem_acc.element_type
    d_dtype = gmem_d.element_type
    d_major_mode = LayoutEnum.from_tensor(gmem_d)
    copy_atom_t2r = sm100_utils.get_tmem_load_op(
        cta_tile_shape_mnk,
        d_major_mode,
        d_dtype,
        acc_dtype,
        epi_tile_shape,
        use_2cta_instrs,
    )
    acc_epi = cute.flat_divide(tmem_acc, epi_tile_shape)
    tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi[None, None, 0, 0])
    tiled_copy_r2s = cute.make_tiled_copy_D(
        cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            d_dtype,
            num_bits_per_copy=128,
        ),
        tiled_copy_t2r,
    )
    gmem_d_tile = cute.zipped_divide(
        gmem_d, (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])
    )[(None, None), cta_d_tile_coord]
    gmem_d_epi = cute.flat_divide(gmem_d_tile, epi_tile_shape)
    gmem_d_epi_grouped = cute.group_modes(gmem_d_epi, 2, 4)
    acc_epi_grouped = cute.group_modes(acc_epi, 2, 4)
    epi_subtile_cnt = cute.size(gmem_d_epi_grouped, mode=[2])
    rmem_layout = cute_ext.make_t2r_rmem_layout(
        tiled_copy_t2r,
        gmem_d_epi,
        tid_x_in_group,
    )
    stage_accumulator = (
        cute.cosize(rmem_layout) * epi_subtile_cnt <= staged_register_budget
    )
    acc_depth = epi_subtile_cnt if stage_accumulator else 1
    rmem_staged_layout = cute.append(
        rmem_layout,
        cute.make_layout(acc_depth, stride=cute.cosize(rmem_layout)),
    )
    rmem_acc_staged = cute_ext.allocate(
        acc_dtype,
        cute.AddressSpace.rmem,
        rmem_staged_layout,
        alignment=32,
    )
    rmem_d = cute_ext.allocate(
        d_dtype,
        cute.AddressSpace.rmem,
        rmem_layout,
        alignment=32,
    )
    smem_d_layout = sm100_utils.make_smem_layout_epi(
        d_dtype,
        d_major_mode,
        epi_tile_shape,
        tma_store_stages,
    )
    smem_d = cute_ext.allocate(
        d_dtype,
        cute.AddressSpace.smem,
        smem_d_layout,
        alignment=1024,
    )
    warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

    if cutlass.const_expr(stage_accumulator):
        for subtile_idx in cutlass.range_constexpr(epi_subtile_cnt):
            cute_ext.partition_and_copy(
                tiled_copy_t2r.get_slice(tid_x_in_group),
                acc_epi_grouped[None, None, subtile_idx],
                rmem_acc_staged[None, None, None, subtile_idx],
            )
        # Each drain warp contributes once, only after its final T2R.
        acc_pipeline.consumer_release_and_advance(elect_one_sync=True)

    tma_store_pipeline = cute_ext.TMAStorePipeline(
        stages=tma_store_stages,
        arv_count=tma_store_arrival_count,
        barrier_id=9,
        tma_warp_id=0,
        index=cutlass.Int32(0),
    )
    for subtile_idx in cutlass.range_constexpr(epi_subtile_cnt):
        if cutlass.const_expr(stage_accumulator):
            rmem_d.store(
                rmem_acc_staged[None, None, None, subtile_idx].load().to(d_dtype)
            )
        else:
            cute_ext.partition_and_copy(
                tiled_copy_t2r.get_slice(tid_x_in_group),
                acc_epi_grouped[None, None, subtile_idx],
                rmem_acc_staged[None, None, None, 0],
            )
            if cutlass.const_expr(subtile_idx == epi_subtile_cnt - 1):
                # The final typed T2R has completed for this warp. Conversion
                # and output stores no longer access the accumulator.
                acc_pipeline.consumer_release_and_advance(elect_one_sync=True)
            rmem_d.store(rmem_acc_staged[None, None, None, 0].load().to(d_dtype))
        tma_store_pipeline.acquire_sync()
        if cutlass.const_expr(static_store_index):
            # The unrolled loop starts at zero and advances once per subtile.
            # Selected ring depths divide the subtile count, restoring zero
            # each tile. Keep the mutable pipeline state dynamic in both DSL
            # frontends while using this equivalent static address coordinate.
            current_store_index = subtile_idx % tma_store_stages
        else:
            current_store_index = tma_store_pipeline.get_index()
        cute_ext.partition_and_copy(
            tiled_copy_r2s.get_slice(tid_x_in_group),
            rmem_d,
            smem_d[None, None, current_store_index],
        )
        tma_store_pipeline.commit_sync()
        if warp_idx == 0:
            cute_ext.tma_store(
                smem_d[None, None, current_store_index],
                gmem_d_epi_grouped[None, None, subtile_idx],
            )
        tma_store_pipeline.release_advance()

    return acc_pipeline


class Sm107BlockScaledSparseGemmKernel:
    """Eight-warp implementation of one caller-selected SM107 schedule.

    ``mma_tiler_mn`` and ``cluster_shape_mn`` are required, while
    ``mma_inst_shape_mn`` defaults to (256, 256). ``cluster_shape_mn`` includes
    the two-CTA peer pair, rather than counting MMA groups. Supported geometry
    and warp ownership are summarized in the module overview; unsupported
    combinations fail at construction. Multicast carrier compatibility and
    reader counts are derived from this explicit geometry in ``__init__``.

    ``retain_ab_multicast`` shares full-K A/B loads across MMA groups;
    single-issue entries always retain their multicast carrier.
    ``stage_direct_output`` requests whole-tile register staging before direct
    stores. K <= 192 still streams subtiles; for larger K, staging depends on
    the register budget and the epilogue's support for converted staging (see
    ``epilogue_direct_store``).
    ``static_store_index`` uses constant shared-memory addresses in TMA stores.
    ``predicate_mma_tail`` skips padded MMA slots, preserving pipeline events.
    ``mma_loop_unroll`` is 1, 2 or 4; ``min_blocks_per_mp`` is the compiler
    occupancy hint (zero leaves it unspecified). All are explicit caller choices.

    ``use_tma_store`` selects one of two epilogue schedules.
    TMA uses one entry point with bounds checks, while direct stores
    specialize complete and partial output tiles.
    """

    ARCH = "sm_107"
    # Retain the original specialization constants as the default/API aliases.
    MMA_INSTRUCTION_MNK = (256, 256, 192)
    MMA_INSTRUCTION_K = MMA_INSTRUCTION_MNK[2]
    # Mirror the instruction/tile domain implemented by the reference schedule;
    # the underlying SM107 operation has a wider instruction-shape domain.
    SUPPORTED_MMA_INSTRUCTION_M = (128, MMA_INSTRUCTION_MNK[0])
    SUPPORTED_MMA_INSTRUCTION_N = (128, MMA_INSTRUCTION_MNK[1])
    SUPPORTED_M_TILE_INSTRUCTION_COUNTS = (1, 2)
    SUPPORTED_OUTPUT_DTYPES = (
        cutlass.Float32,
        cutlass.Float16,
        cutlass.BFloat16,
        cutlass.Float8E4M3FN,
        cutlass.Float8E5M2,
    )
    # Any power-of-two axis is legal within the total hardware cluster limit;
    # the product and the 2-CTA instruction peer-pair constraint are checked below.
    MAX_CLUSTER_SIZE = 16
    SUPPORTED_CLUSTER_M_EXTENTS = tuple(
        1 << exponent for exponent in range(MAX_CLUSTER_SIZE.bit_length())
    )
    SUPPORTED_CLUSTER_N_EXTENTS = SUPPORTED_CLUSTER_M_EXTENTS
    AB_TMA_PHASE_K = 256
    # Rubin's Tensor-E atom for the FP4 sparse path, from
    # ``rubin_helpers.make_tensor_e_atom_layout``. Mirrored here because the
    # multicast width has to be decided at configuration time, before any DSL
    # layout exists; the kernel body asserts the real atom against these so
    # they cannot drift.
    E_ATOM_M = 128
    E_ATOM_K = 128
    SF_VECTOR_SIZE = 32
    SCALE_MN_ATOM_ELEMENTS = 128
    SCALE_K_ATOM_ELEMENTS = 128
    SCALE_K_ATOM_BYTES = 512
    # Two rows represent one 512-byte K atom without flattening the TMA box.
    SCALE_TMA_MINOR_BYTES = 256
    # Validated partitioning limit for these scale carriers, also used by the
    # reference kernel. This is independent of the 16-CTA hardware cluster limit.
    SCALE_TMA_MAX_MULTICAST_PARTICIPANTS = 4
    SMEM_RESERVED_BYTES = 1024
    SMEM_ALLOCATION_ALIGNMENT = 128
    SMEM_PIPELINE_STAGE_BYTES = 16

    # Four drain warps, one MMA warp, and two producer warps; warp 7 is idle.
    WARP_SIZE = 32
    EPILOGUE_WARP_COUNT = 4
    MMA_WARP_ID = 4
    AB_E_LOAD_WARP_ID = 5
    # SFA and SFB share one warp and one ring, matching the reference
    # topology. They run the same number of carriers in lockstep
    # (carrier_tile_count == macro_tile_count) and already released against the
    # same mask and arrival count, so one barrier covers both.
    SF_LOAD_WARP_ID = 6
    # Stream one accumulator subtile at a time. Whole-tile staging increases
    # register pressure and delays useful output work on these schedules.
    DIRECT_STAGED_REGISTER_BUDGET = 0
    TMA_STAGED_REGISTER_BUDGET = 0

    @staticmethod
    def can_implement(
        mnkl: tuple[int, int, int, int],
        *,
        a_dtype: type[cutlass.Numeric] = cutlass.Float4E2M1FN,
        b_dtype: type[cutlass.Numeric] = cutlass.Float4E2M1FN,
        sfa_dtype: type[cutlass.Numeric] = cutlass.Float8E8M0FNU,
        sfb_dtype: type[cutlass.Numeric] = cutlass.Float8E8M0FNU,
        e_dtype: type[cutlass.Numeric] = cutlass.Uint8,
        c_dtype: type[cutlass.Numeric] = cutlass.Float16,
        a_alignment: int = 16,
        b_alignment: int = 16,
        sfa_alignment: int = 16,
        sfb_alignment: int = 16,
        e_alignment: int = 16,
        c_alignment: int = 32,
        a_is_k_major: bool = True,
        b_is_k_major: bool = True,
        c_is_n_major: bool = True,
    ) -> bool:
        """Return whether shape and static tensor metadata match the kernel."""

        if c_dtype not in Sm107BlockScaledSparseGemmKernel.SUPPORTED_OUTPUT_DTYPES:
            return False
        c_elements_per_32_bytes = 256 // c_dtype.width
        m, n, k, l = mnkl
        return (
            (m > 0)
            & (n > 0)
            & (k > 0)
            & (l > 0)
            & (n % c_elements_per_32_bytes == 0)
            & (k % 64 == 0)
            & (a_dtype == cutlass.Float4E2M1FN)
            & (b_dtype == cutlass.Float4E2M1FN)
            & (sfa_dtype == cutlass.Float8E8M0FNU)
            & (sfb_dtype == cutlass.Float8E8M0FNU)
            & (e_dtype == cutlass.Uint8)
            & (a_alignment >= 16)
            & (b_alignment >= 16)
            & (sfa_alignment >= 16)
            & (sfb_alignment >= 16)
            & (e_alignment >= 16)
            & (c_alignment >= 32)
            & a_is_k_major
            & b_is_k_major
            & c_is_n_major
        )

    @staticmethod
    def validate_problem_shape(
        m: int,
        n: int,
        k: int,
        l: int,
        *,
        c_dtype: type[cutlass.Numeric] = cutlass.Float16,
    ) -> None:
        """Validate the configuration's tensor-alignment contract.

        This configuration uses K-major FP4 A/B and N-major output. Each
        output row must be 32-byte aligned: N is a multiple of 8 for FP32,
        16 for FP16/BF16, or 32 for FP8. Scale-factor and metadata carriers
        include storage for complete 128-element K atoms; padding within those
        atoms is in bounds, not TMA zero-fill. ``pack_e_storage`` fills metadata
        padding with valid nonzero ``0xEE`` selectors. Compressed A contains K/2
        FP4 elements, so K must be a multiple of 64 to keep every K-major row
        16-byte aligned. M and the batch extent may be any positive size;
        TMA zero-fills beyond each input descriptor's bounds, and the kernel
        predicates edge stores.
        """

        if min(m, n, k, l) <= 0:
            raise ValueError("problem dimensions must be positive")
        if c_dtype not in Sm107BlockScaledSparseGemmKernel.SUPPORTED_OUTPUT_DTYPES:
            raise ValueError("Unsupported output c_dtype")
        c_elements_per_32_bytes = 256 // c_dtype.width
        if n % c_elements_per_32_bytes:
            raise ValueError(
                "Rubin sparse block-scaled GEMM requires N to be a multiple "
                f"of {c_elements_per_32_bytes} output elements, got {n}"
            )
        if k % 64:
            raise ValueError(
                "Rubin sparse block-scaled GEMM requires K to be a multiple "
                f"of 64 elements for compressed-A row alignment, got {k}"
            )

    @staticmethod
    def _carrier_modes_match(
        actual_shape: tuple,
        actual_stride: tuple,
        expected_shape: tuple,
        expected_stride: tuple,
    ) -> bool:
        """Compare every extent and stride of two flattened storage layouts.

        Bitwise combination preserves conditions on runtime tensor extents.
        """

        if len(actual_shape) != len(expected_shape):
            return False
        matches = (actual_shape[0] == expected_shape[0]) & (
            actual_stride[0] == expected_stride[0]
        )
        for mode in range(1, len(expected_shape)):
            matches = (
                matches
                & (actual_shape[mode] == expected_shape[mode])
                & (actual_stride[mode] == expected_stride[mode])
            )
        return matches

    @staticmethod
    def _validate_physical_carrier_layout(
        name: str,
        tensor: cute.Tensor,
        expected_layout: cute.Layout,
    ) -> None:
        """Check SF/E storage before rebuilding a view from its base pointer.

        The new view uses expected strides and padding, not the input tensor's
        layout. Reject a rank mismatch while tracing, and assert each extent
        and stride at runtime so a same-size but differently arranged tensor
        cannot silently be reinterpreted. This checks layout, not data values.
        """

        actual_layout = cute.flatten(tensor.layout)
        expected_layout = cute.flatten(expected_layout)
        expected_rank = cute.rank(expected_layout)
        if cutlass.const_expr(cute.rank(actual_layout) != expected_rank):
            raise ValueError(f"{name} physical carrier must have rank {expected_rank}")
        runtime_assert(
            Sm107BlockScaledSparseGemmKernel._carrier_modes_match(
                actual_layout.shape,
                actual_layout.stride,
                expected_layout.shape,
                expected_layout.stride,
            ),
            f"{name} physical carrier layout mismatch",
        )

    @classmethod
    def _scale_carrier_modes(cls, mn: int, k: int, l: int) -> tuple[tuple, tuple]:
        """Describe packed SF storage as a six-mode, broadcast-free DSL layout.

        ``mn`` is M for SFA or N for SFB. ``_scale_storage_modes`` describes the
        incoming rank-three allocation. This view exposes its block-scaled
        storage order without the two repeated, zero-stride dimensions in
        ``tile_atom_to_shape_SF``. ``_scale_tma_carrier_modes`` regroups the same
        bytes into TMA rows.
        """

        mn_atom_count = (mn + cls.SCALE_MN_ATOM_ELEMENTS - 1) // (
            cls.SCALE_MN_ATOM_ELEMENTS
        )
        k_atom_count = (k + cls.SCALE_K_ATOM_ELEMENTS - 1) // (
            cls.SCALE_K_ATOM_ELEMENTS
        )
        return (
            (32, 4, mn_atom_count, 4, k_atom_count, l),
            (
                16,
                4,
                k_atom_count * cls.SCALE_K_ATOM_BYTES,
                1,
                cls.SCALE_K_ATOM_BYTES,
                mn_atom_count * k_atom_count * cls.SCALE_K_ATOM_BYTES,
            ),
        )

    @classmethod
    def _scale_storage_modes(cls, mn: int, k: int, l: int) -> tuple[tuple, tuple]:
        """Describe the incoming SF allocation as (L, padded MN, padded scales).

        This matches ``create_scale_factor_tensor``: contiguous rank-three
        storage with MN padded to a multiple of 128 and the K scale count to a
        multiple of four (128 logical K elements). Its bytes already use the
        block-scaled order; this is allocation metadata, not a logical matrix
        of unpacked scales.
        ``_setup_attributes`` checks this layout before making zero-copy views.
        """

        padded_mn = (
            (mn + cls.SCALE_MN_ATOM_ELEMENTS - 1)
            // cls.SCALE_MN_ATOM_ELEMENTS
            * cls.SCALE_MN_ATOM_ELEMENTS
        )
        scale_count = (k + cls.SF_VECTOR_SIZE - 1) // cls.SF_VECTOR_SIZE
        scales_per_atom = cls.SCALE_K_ATOM_ELEMENTS // cls.SF_VECTOR_SIZE
        padded_scale_count = (
            (scale_count + scales_per_atom - 1) // scales_per_atom * scales_per_atom
        )
        return (
            (l, padded_mn, padded_scale_count),
            (
                padded_mn * padded_scale_count,
                padded_scale_count,
                1,
            ),
        )

    @classmethod
    def _make_scale_carrier_layout(cls, mn: int, k: int, l: int) -> cute.Layout:
        """Build the six-mode layout described by ``_scale_carrier_modes``."""

        shape, stride = cls._scale_carrier_modes(mn, k, l)
        return cute.make_layout(shape, stride=stride)

    @classmethod
    def _make_scale_carrier(
        cls,
        tensor: cute.Tensor,
        mn: int,
        k: int,
        l: int,
    ) -> cute.Tensor:
        """Reinterpret validated SF storage with the broadcast-free block layout.

        Reuse the input iterator: no allocation, copy or value permutation is
        performed. The caller must first check ``_scale_storage_modes`` because
        this view replaces, rather than preserves, the input tensor's strides.
        """

        return cute.make_tensor(
            tensor.iterator,
            cls._make_scale_carrier_layout(mn, k, l),
        )

    @classmethod
    def _scale_tma_carrier_modes(cls, mn: int, k: int, l: int) -> tuple[tuple, tuple]:
        """Describe the same SF bytes as a four-mode TMA copy view.

        The modes are contiguous byte, K segment, M/N block and batch. Each
        128-row block spanning 128 logical K elements holds 512 E8M0 bytes.
        Splitting it into two 256-byte rows preserves a one-to-one mapping to
        storage and lets TMA copy a 768-element K block with one multidimensional
        instruction.
        """

        mn_atom_count = (mn + cls.SCALE_MN_ATOM_ELEMENTS - 1) // (
            cls.SCALE_MN_ATOM_ELEMENTS
        )
        k_atom_count = (k + cls.SCALE_K_ATOM_ELEMENTS - 1) // (
            cls.SCALE_K_ATOM_ELEMENTS
        )
        rows_per_k_atom = cls.SCALE_K_ATOM_BYTES // cls.SCALE_TMA_MINOR_BYTES
        segment_count = k_atom_count * rows_per_k_atom
        k_bytes = k_atom_count * cls.SCALE_K_ATOM_BYTES
        return (
            (cls.SCALE_TMA_MINOR_BYTES, segment_count, mn_atom_count, l),
            (1, cls.SCALE_TMA_MINOR_BYTES, k_bytes, k_bytes * mn_atom_count),
        )

    @classmethod
    def _make_scale_tma_carrier(
        cls,
        tensor: cute.Tensor,
        mn: int,
        k: int,
        l: int,
    ) -> cute.Tensor:
        """Build the zero-copy view described by ``_scale_tma_carrier_modes``."""

        shape, stride = cls._scale_tma_carrier_modes(mn, k, l)
        return cute.make_tensor(tensor.iterator, cute.make_layout(shape, stride=stride))

    @staticmethod
    def _align_up(value: int, alignment: int) -> int:
        """Round a byte count up to an allocation boundary."""

        return ((value + alignment - 1) // alignment) * alignment

    def _pipeline_stage_bytes(self) -> _PipelineStageBytes:
        """Return the shared-memory bytes needed per stage of each operand."""

        cta_m, tile_n, group_k = self.cta_tile_shape_mnk
        b_mma_n = tile_n // self.cta_group_size
        return _PipelineStageBytes(
            a=cta_m * self.ab_tma_phase_k // 4,
            b=b_mma_n * self.ab_tma_phase_k // 2,
            sfa=cta_m * group_k // self.sf_vec_size,
            sfb=tile_n * group_k // self.sf_vec_size,
            e=cta_m * group_k // 8,
            c=(math.prod(self.epilogue_tile_shape_mn) * self.c_dtype.width // 8),
        )

    def _modeled_pipeline_smem_bytes(self, stages: _PipelineStages) -> int:
        """Model the aligned SMEM allocations used by one CTA.

        A stores two sparse FP4 values per four-element K group; B stores dense
        FP4. Scale factors store one E8M0 byte per vector, and E stores one
        metadata byte per eight-element K group. The offset walk follows
        allocation order, including the typed pipelines' full/empty mbarriers
        and driver-reserved bytes.
        """

        stage_bytes = self._pipeline_stage_bytes()
        offset = self._align_up(
            self.acc_stages * self.SMEM_PIPELINE_STAGE_BYTES,
            1024,
        )
        offset += stage_bytes.a * stages.ab
        offset = self._align_up(offset, 1024)
        offset += stage_bytes.b * stages.ab
        offset = self._align_up(offset, self.SMEM_ALLOCATION_ALIGNMENT)
        offset += stage_bytes.sfa * stages.sf
        offset = self._align_up(offset, self.SMEM_ALLOCATION_ALIGNMENT)
        offset += stage_bytes.sfb * stages.sf
        offset = self._align_up(offset, self.SMEM_ALLOCATION_ALIGNMENT)
        offset += stage_bytes.e * stages.e
        offset = self._align_up(offset, 8)
        offset += (stages.ab + stages.sf + stages.e) * self.SMEM_PIPELINE_STAGE_BYTES
        if stages.c:
            offset = self._align_up(offset, 1024)
            offset += stage_bytes.c * stages.c
        return offset + self.SMEM_RESERVED_BYTES

    def _make_epi_tile(self, mma_op, c_layout):
        """Select the Rubin epilogue tile and verify the host storage model.

        CuTe tiles contain region-local layout values, so selection runs in the
        kernel region. The constructor uses the context-free size helper for
        its host-only stage search. Checking the dimensions here prevents a
        helper-table update from silently changing the output ring footprint.
        Both direct and TMA epilogues consume this same selected tile. Changes
        to Rubin's sparse dispatch or tile table must update this query and
        the context-free size query in ``__init__`` together.
        """
        tile = sm107_utils.compute_epilogue_tile_shape(
            mma_op,
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            c_layout,
            self.c_dtype,
        )
        selected_shape = (cute.size(tile[0]), cute.size(tile[1]))
        assert selected_shape == self.epilogue_tile_shape_mn, (
            "Rubin epilogue selection must match the stage-storage model"
        )
        return tile

    def _compute_stages(self, smem_capacity: int) -> _PipelineStages:
        """Derive mode-specific pipeline depths under the SM107 SMEM budget.

        Caller limits bound the number of buffers independently of the memory
        budget. Within those limits, use the actual allocation order and
        per-stage byte counts for A, B, scale factors, metadata and output.

        The search keeps every ring able to run ahead before it spends the
        remaining budget on A/B lookahead: first a double-buffered output ring,
        then the largest common minimum depth for scale factors and metadata,
        and only then A/B depth. Each preference falls back if nothing fits.
        """

        stage_bytes = self._pipeline_stage_bytes()
        max_ab_stages = min(
            self.stage_caps.ab,
            smem_capacity
            // (stage_bytes.a + stage_bytes.b + self.SMEM_PIPELINE_STAGE_BYTES),
        )
        max_sf_stages = min(
            self.stage_caps.sf,
            smem_capacity
            // (stage_bytes.sfa + stage_bytes.sfb + self.SMEM_PIPELINE_STAGE_BYTES),
        )
        max_e_stages = min(
            self.stage_caps.e,
            smem_capacity // (stage_bytes.e + self.SMEM_PIPELINE_STAGE_BYTES),
        )
        max_c_stages = min(
            self.stage_caps.c,
            self.tma_store_subtile_count,
            smem_capacity // stage_bytes.c,
        )
        c_stage_candidates = (
            tuple(
                stages
                for stages in range(max_c_stages, 0, -1)
                if self.tma_store_subtile_count % stages == 0
            )
            if self.use_tma_store
            else (0,)
        )
        if not c_stage_candidates:
            raise ValueError(
                "TMA-store stage cap has no depth that restores the cursor "
                "after one output tile"
            )
        minimum_ab_stages = self.ab_phases_per_group
        if self.stage_caps.ab < minimum_ab_stages:
            raise ValueError(
                "AB stage cap must hold one complete K group: "
                f"need at least {minimum_ab_stages}, got {self.stage_caps.ab}"
            )
        # Prefer at least two output stages plus one extra AB stage beyond a
        # complete K group; fall back to minimum depths when the budget requires.
        double_buffered = tuple(stages for stages in c_stage_candidates if stages >= 2)
        search_passes = (
            (
                (double_buffered, minimum_ab_stages + 1),
                (c_stage_candidates, minimum_ab_stages),
            )
            if double_buffered and double_buffered != c_stage_candidates
            else ((c_stage_candidates, minimum_ab_stages),)
        )
        shared_floor = min(max_sf_stages, max_e_stages)
        for candidates, ab_floor in search_passes:
            for ring_floor in range(shared_floor, 0, -1):
                for ab_stages in range(max_ab_stages, ab_floor - 1, -1):
                    for c_stages in candidates:
                        for e_stages in range(max_e_stages, ring_floor - 1, -1):
                            for sf_stages in range(max_sf_stages, ring_floor - 1, -1):
                                stages = _PipelineStages(
                                    ab=ab_stages,
                                    sf=sf_stages,
                                    e=e_stages,
                                    c=c_stages,
                                    smem_bytes=0,
                                )
                                smem_bytes = self._modeled_pipeline_smem_bytes(stages)
                                if smem_bytes <= smem_capacity:
                                    return _PipelineStages(
                                        ab=stages.ab,
                                        sf=stages.sf,
                                        e=stages.e,
                                        c=stages.c,
                                        smem_bytes=smem_bytes,
                                    )
        raise ValueError(
            "SM107 sparse block-scaled GEMM cannot fit its minimum pipeline "
            f"configuration in {smem_capacity} bytes of shared memory"
        )

    @classmethod
    def _validate_schedule(
        cls,
        mma_inst_shape_mn: tuple[int, int],
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        use_tma_store: bool,
        stage_caps: PipelineStageCaps,
        smem_capacity: int,
        persistent_cluster_limit: int,
    ) -> None:
        """Reject instruction, tile, and launch combinations not implemented."""

        for name, shape in (
            ("mma_inst_shape_mn", mma_inst_shape_mn),
            ("mma_tiler_mn", mma_tiler_mn),
            ("cluster_shape_mn", cluster_shape_mn),
        ):
            if (
                type(shape) is not tuple
                or len(shape) != 2
                or any(type(extent) is not int for extent in shape)
            ):
                raise TypeError(f"{name} must be a pair of integers")
            if min(shape) <= 0:
                raise ValueError(f"{name} extents must be positive, got {shape}")
        if mma_inst_shape_mn[0] not in cls.SUPPORTED_MMA_INSTRUCTION_M:
            raise ValueError(
                "SM107 sparse MMA instruction M must be one of "
                f"{cls.SUPPORTED_MMA_INSTRUCTION_M}, got {mma_inst_shape_mn[0]}"
            )
        if mma_inst_shape_mn[1] not in cls.SUPPORTED_MMA_INSTRUCTION_N:
            raise ValueError(
                "this kernel supports sparse MMA instruction N in "
                f"{cls.SUPPORTED_MMA_INSTRUCTION_N}, got {mma_inst_shape_mn[1]}"
            )
        m_tile_instruction_count, m_remainder = divmod(
            mma_tiler_mn[0], mma_inst_shape_mn[0]
        )
        if (
            m_remainder != 0
            or m_tile_instruction_count not in cls.SUPPORTED_M_TILE_INSTRUCTION_COUNTS
            or mma_tiler_mn[1] != mma_inst_shape_mn[1]
        ):
            raise ValueError(
                "the tile must contain one or two instructions along M and "
                "exactly one instruction along N: "
                f"instruction={mma_inst_shape_mn}, tile={mma_tiler_mn}"
            )
        # ``cluster_shape_mn`` is the launch cluster and already folds in the
        # 2-CTA peer pair. Each extent must be a power of two within the
        # total hardware cluster limit, and under a 2-CTA instruction the M
        # extent must be a multiple of the peer-pair size so every pair stays
        # inside one cluster. The hardware also caps the total cluster size.
        num_mma_ctas = 2 if mma_inst_shape_mn[0] == 256 else 1
        if cluster_shape_mn[0] not in cls.SUPPORTED_CLUSTER_M_EXTENTS:
            raise ValueError(
                "cluster_shape_mn[0] must be a power of two in "
                f"{cls.SUPPORTED_CLUSTER_M_EXTENTS}, got {cluster_shape_mn[0]}"
            )
        if cluster_shape_mn[1] not in cls.SUPPORTED_CLUSTER_N_EXTENTS:
            raise ValueError(
                "cluster_shape_mn[1] must be a power of two in "
                f"{cls.SUPPORTED_CLUSTER_N_EXTENTS}, got {cluster_shape_mn[1]}"
            )
        cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        if cluster_size > cls.MAX_CLUSTER_SIZE:
            raise ValueError(
                f"cluster_shape_mn={cluster_shape_mn} has {cluster_size} CTAs, "
                f"exceeding the {cls.MAX_CLUSTER_SIZE}-CTA hardware limit"
            )
        if cluster_shape_mn[0] % num_mma_ctas != 0:
            raise ValueError(
                f"a {num_mma_ctas}-CTA instruction (mma_inst_shape_mn[0]="
                f"{mma_inst_shape_mn[0]}) requires cluster_shape_mn[0] to be a "
                f"multiple of {num_mma_ctas}, got {cluster_shape_mn[0]}"
            )
        if type(use_tma_store) is not bool:
            raise TypeError("use_tma_store must be a bool")
        if not isinstance(stage_caps, PipelineStageCaps):
            raise TypeError("stage_caps must be a PipelineStageCaps instance")
        if use_tma_store and stage_caps.c == 0:
            raise ValueError("TMA store requires a positive C stage cap")
        if not use_tma_store and stage_caps.c != 0:
            raise ValueError("direct store requires a zero C stage cap")
        if type(smem_capacity) is not int or smem_capacity <= 0:
            raise ValueError("smem_capacity must be a positive integer")
        architecture_capacity = cutlass.memory.get_smem_capacity_in_bytes(cls.ARCH)
        if smem_capacity > architecture_capacity:
            raise ValueError(
                f"smem_capacity exceeds {cls.ARCH} capacity "
                f"{architecture_capacity}: got {smem_capacity}"
            )
        if type(persistent_cluster_limit) is not int or persistent_cluster_limit <= 0:
            raise ValueError("persistent_cluster_limit must be a positive integer")

    def __init__(
        self,
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        *,
        mma_inst_shape_mn: tuple[int, int] = MMA_INSTRUCTION_MNK[:2],
        c_dtype: type[cutlass.Numeric] = cutlass.Float16,
        use_tma_store: bool,
        stage_caps: PipelineStageCaps,
        smem_capacity: int,
        persistent_cluster_limit: int,
        retain_ab_multicast: bool = False,
        stage_direct_output: bool = False,
        static_store_index: bool = False,
        predicate_mma_tail: bool = True,
        mma_loop_unroll: int = 1,
        min_blocks_per_mp: int = 0,
    ) -> None:
        if c_dtype not in self.SUPPORTED_OUTPUT_DTYPES:
            raise ValueError("Unsupported output c_dtype")
        self.c_dtype = c_dtype
        for name, value in (
            ("retain_ab_multicast", retain_ab_multicast),
            ("stage_direct_output", stage_direct_output),
            ("static_store_index", static_store_index),
            ("predicate_mma_tail", predicate_mma_tail),
        ):
            if type(value) is not bool:
                raise ValueError(f"{name} must be a bool")
        if type(mma_loop_unroll) is not int or mma_loop_unroll not in (1, 2, 4):
            raise ValueError("mma_loop_unroll must be 1, 2 or 4")
        if type(min_blocks_per_mp) is not int or min_blocks_per_mp < 0:
            raise ValueError("min_blocks_per_mp must be a nonnegative integer")
        if stage_direct_output and use_tma_store:
            raise ValueError("stage_direct_output requires direct output stores")
        self._validate_schedule(
            mma_inst_shape_mn,
            mma_tiler_mn,
            cluster_shape_mn,
            use_tma_store,
            stage_caps,
            smem_capacity,
            persistent_cluster_limit,
        )
        num_mma_ctas = 2 if mma_inst_shape_mn[0] == 256 else 1
        reuse_m = mma_tiler_mn[0] // mma_inst_shape_mn[0]
        self.use_2cta_instrs = num_mma_ctas == 2
        self.num_mma_ctas = num_mma_ctas
        self.reuse_m = reuse_m
        self.enable_breuse = reuse_m == 2
        # N256 B reuse needs a rolling K = 256 E window to fit the complete
        # typed TMEM allocation within SM107's 576-column capacity.
        self.enable_e_tmem_reuse = reuse_m == 2 and mma_tiler_mn[1] == 256
        self.cluster_shape = (*cluster_shape_mn, 1)
        self.cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        self.mma_inst_shape_mnk = (*mma_inst_shape_mn, self.MMA_INSTRUCTION_K)
        group_k = math.lcm(self.mma_inst_shape_mnk[2], self.AB_TMA_PHASE_K)
        self.mma_tiler_mnk = (*mma_tiler_mn, group_k)
        self.cta_group_size = self.num_mma_ctas
        self.cta_tile_shape_mnk = (
            mma_tiler_mn[0] // self.cta_group_size,
            mma_tiler_mn[1],
            group_k,
        )
        # The current Rubin helper selects the SM100 fallback for sparse MMA.
        # Its context-free size query keeps construction usable without an MLIR
        # region; _make_epi_tile verifies it against the actual Rubin selection.
        # A sparse dispatch/table change must update this size query and the
        # Rubin shape query in _make_epi_tile together, including direct store.
        self.epilogue_tile_shape_mn = sm100_utils.compute_epilogue_tile_size(
            self.cta_tile_shape_mnk[0],
            self.cta_tile_shape_mnk[1],
            self.use_2cta_instrs,
            self.c_dtype.width,
            d_is_m_major=False,
        )
        self.mma_sf_tiler = self.cta_tile_shape_mnk
        # B reuse keeps each K = 768 TMA landing carrier intact, but reuses one
        # K = 384 TMEM scale-factor window between the two MMA pairs.
        self.sf_tmem_k = group_k // 2 if self.enable_breuse else group_k
        self.ab_tma_phase_k = self.AB_TMA_PHASE_K
        self.ab_phases_per_group = group_k // self.ab_tma_phase_k
        self.mma_issues_per_group = group_k // self.mma_inst_shape_mnk[2]
        self.sf_vec_size = self.SF_VECTOR_SIZE
        self.tma_store_subtile_count = (
            self.cta_tile_shape_mnk[0] // self.epilogue_tile_shape_mn[0]
        ) * (self.cta_tile_shape_mnk[1] // self.epilogue_tile_shape_mn[1])
        self.sfa_scale_atom_count = (
            self.cta_tile_shape_mnk[0] // self.SCALE_MN_ATOM_ELEMENTS
        )
        self.sfb_scale_atom_count = self.mma_tiler_mnk[1] // self.SCALE_MN_ATOM_ELEMENTS
        self.sf_tma_minor_bytes = self.SCALE_TMA_MINOR_BYTES
        self.use_tma_store = use_tma_store
        # The caller chooses the performance tradeoffs. Multicast reduces
        # redundant loads but couples stage retirement; staging direct output
        # releases ACC earlier at the cost of registers. Static store indexing
        # and loop unrolling trade index/control work for larger live ranges.
        self.retains_ab_multicast = retain_ab_multicast
        self.stages_direct_output = stage_direct_output
        self.uses_static_store_index = static_store_index
        self.predicate_mma_tail = predicate_mma_tail
        self.mma_loop_unroll = mma_loop_unroll
        self.min_blocks_per_mp = min_blocks_per_mp
        self.stage_caps = stage_caps
        # One TMEM accumulator tile is reused after every epilogue warp has
        # finished T2R. Its single ownership stage is a protocol invariant;
        # output conversion and stores overlap the next tile after release.
        self.acc_stages = 1
        self.smem_capacity = smem_capacity
        stages = self._compute_stages(self.smem_capacity)
        self.ab_stages = stages.ab
        self.sf_stages = stages.sf
        self.e_stages = stages.e
        self.tma_store_stages = stages.c
        self.pipeline_smem_bytes = stages.smem_bytes
        self.threads_per_cta = self.WARP_SIZE * (self.EPILOGUE_WARP_COUNT + 4)
        self.acc_consumer_arrival_count = self.EPILOGUE_WARP_COUNT * self.cta_group_size
        self.tma_store_arrival_count = self.EPILOGUE_WARP_COUNT * self.WARP_SIZE
        # Wait for the MMA-group leaders along both multicast axes, counting
        # their common leader once, before reusing the shared SFA/SFB stage.
        self.scale_metadata_consumer_arrivals = (
            cluster_shape_mn[1] + cluster_shape_mn[0] // self.num_mma_ctas - 1
        )
        self.cta_pair_rank_mask = self.cta_group_size - 1
        self.persistent_cluster_limit = persistent_cluster_limit
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        self.mma_operation_type = (
            cute_ext.OperationTypeEnum.SM107_MMA_SCALED_SPARSE_2SM_SS
            if self.use_2cta_instrs
            else cute_ext.OperationTypeEnum.SM107_MMA_SCALED_SPARSE_1SM_SS
        )
        self.s2t_operation_type = (
            cute_ext.OperationTypeEnum.SM100_COPY_S2T_2SM
            if self.use_2cta_instrs
            else cute_ext.OperationTypeEnum.SM100_COPY_S2T
        )
        # Two different cluster layouts drive two different multicast answers.
        #
        # ``tma_op`` carries A, B, SFA and E over ``cluster_layout_vmnk``,
        # whose V mode is the peer pair. A 2-CTA instruction already spans that
        # pair, so multicast is needed only for extents beyond it: more than
        # one CTA group along M, or any N extent.
        #
        # ``tma_mcast_op`` carries SFB over ``cluster_layout_sfb_vmnk``, built
        # from a 1-CTA dummy atom so its V mode is one. SFB is the B-side scale
        # factor and is therefore shared across M and issued with
        # ``multicast_mode=1``: it multicasts whenever the raw M extent exceeds
        # one, which a 2-CTA instruction guarantees. Keying SFB off N instead
        # would both miss the CTA1 M>1 case and request a multicast the value
        # map cannot supply.
        self.use_tma_multicast = (
            cluster_shape_mn[0] // self.num_mma_ctas != 1 or cluster_shape_mn[1] != 1
        )
        self.sfb_use_tma_multicast = cluster_shape_mn[0] != 1
        # E multicast splits the K-atom mode, so cluster N must divide that
        # mode, not the total M*K atom count. K = 768 has six K = 128 atoms when
        # B reuse doubles M. Otherwise, each CTA loads the full metadata box.
        self.e_tma_k_atoms = self.cta_tile_shape_mnk[2] // self.E_ATOM_K
        self.e_use_tma_multicast = self.use_tma_multicast and (
            cluster_shape_mn[1] == 1 or self.e_tma_k_atoms % cluster_shape_mn[1] == 0
        )
        self.metadata_consumer_arrivals = (
            cluster_shape_mn[1] if self.e_use_tma_multicast else 1
        )
        if self.use_2cta_instrs:
            self.tma_op = (
                cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                if self.use_tma_multicast
                else cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
            )
            self.tma_mcast_op = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
        else:
            self.tma_op = (
                cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
                if self.use_tma_multicast
                else cute_ext.OperationTypeEnum.SM90_TMA_LOAD
            )
            self.tma_mcast_op = (
                cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
                if self.sfb_use_tma_multicast
                else cute_ext.OperationTypeEnum.SM90_TMA_LOAD
            )
        # The physical scale carrier retains a 256-byte contiguous mode.
        # Keep its multicast projection within the validated reference limit;
        # this is a conservative carrier-partitioning bound, not a hardware
        # 64-byte alignment rule derived by dividing 256 by four. Larger
        # projections use typed local loads while the launch cluster remains legal.
        # A/B choose their own single-issue or full-K transfer scope below.
        sf_unicast_op = (
            cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
            if self.use_2cta_instrs
            else cute_ext.OperationTypeEnum.SM90_TMA_LOAD
        )
        self.sfa_tma_op = (
            self.tma_op
            if cluster_shape_mn[1] <= self.SCALE_TMA_MAX_MULTICAST_PARTICIPANTS
            else sf_unicast_op
        )
        self.sfb_tma_op = (
            self.tma_mcast_op
            if cluster_shape_mn[0] <= self.SCALE_TMA_MAX_MULTICAST_PARTICIPANTS
            else sf_unicast_op
        )
        # SFA and SFB share one ring, so its lifecycle has to cover whichever of
        # the two multicasts. They project on opposite axes -- SFA along N, SFB
        # along M -- so at a 1xN cluster only SFA multicasts and at an Mx1
        # cluster only SFB does. The masked release form is required as soon as
        # either one does, because the stage is then replicated across the CTAs
        # that projection covers and every one of them must signal.
        #
        # The shared ring waits for the union of both reader groups, with their
        # common leader counted once in `scale_metadata_consumer_arrivals`.
        self.sf_tma_op = (
            self.tma_op
            if self.tma_op
            in (
                cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST,
                cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST,
            )
            else self.tma_mcast_op
        )
        # E rides the same projection as A but drops to a unicast load when its
        # box cannot be split that many ways. Its ring is created with this same
        # operation so the release mask and arrival count follow the load.
        self.e_tma_op = (
            self.tma_op
            if self.e_use_tma_multicast
            else (
                cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
                if self.use_2cta_instrs
                else cute_ext.OperationTypeEnum.SM90_TMA_LOAD
            )
        )

    @staticmethod
    def _make_a_smem_layout(
        atom_cta_m: int,
        reuse_m: int,
        ab_stages: int,
    ) -> cute.ComposedLayout:
        """Build A storage with an independent circular ring per M half.

        The no-reuse shape is kept byte-for-byte compatible with the
        established schedule. For B reuse, stage precedes the M-half mode so
        each half's stages are physically consecutive; this is the topology
        required by the typed circular sparse-dot descriptor.
        """

        layout_atom = tcgen05.make_smem_layout_atom(
            tcgen05.SmemLayoutAtomKind.K_SW64,
            cutlass.Uint8,
        )
        half_ring = tcgen05.tile_to_mma_shape(
            layout_atom,
            ((atom_cta_m, 16), 1, 4, ab_stages),
            order=(0, 1, 2),
        )
        if cutlass.const_expr(reuse_m == 1):
            return half_ring
        reuse_layout = cute.make_layout(
            reuse_m,
            stride=cute.cosize(half_ring.outer),
        )
        return cute.make_composed_layout(
            half_ring.inner,
            half_ring.offset,
            cute.append(half_ring.outer, reuse_layout),
        )

    @staticmethod
    def _make_circular_mma_inner(
        smem_layout: cute.Layout | cute.ComposedLayout,
    ) -> cute.Layout:
        """Expose the flattened physical block ring used by sparse dot.

        ``cute_ext.dot_block_scaled_sparse`` forms SM107 circular descriptors
        from a physical ``((MN, K_BLOCK), REST..., PIPE)`` layout. A uses its
        native 64-byte K_SW64 blocks and B uses 128-byte K_SW128 blocks; in
        both cases the pipeline stages stay in a flat trailing ring mode.
        """

        # Normalize the two legal staged-layout representations: an allocation
        # may retain its composed wrapper or expose the post-recast outer layout.
        return (
            smem_layout.outer
            if isinstance(smem_layout, cute.ComposedLayout)
            else smem_layout
        )

    def _get_mma_permutation_mnk(
        self,
    ) -> tuple[cute.Layout, int, int] | None:
        """Return the canonical CTA2 doubled-M value permutation."""

        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape_mnk[0] // 2, 2, 2),
                stride=(
                    1,
                    self.mma_inst_shape_mnk[0],
                    self.mma_inst_shape_mnk[0] // 2,
                ),
            )
            return (
                m_layout,
                self.mma_inst_shape_mnk[1],
                self.mma_inst_shape_mnk[2],
            )
        return None

    @staticmethod
    def _make_sparse_tiled_mma(
        raw_ab_dtype: type[cutlass.Numeric],
        acc_dtype: type[cutlass.Numeric],
        sf_dtype: type[cutlass.Numeric],
        sf_vec_size: int,
        instruction_shape: tuple[int, int, int],
        cta_group: tcgen05.CtaGroup,
        permutation_mnk: tuple[cute.Layout, int, int] | None,
        b_collector_op: tcgen05.CollectorOp = tcgen05.CollectorOp.DISCARD,
    ) -> cute.TiledMma:
        """Build one public sparse MMA variant with fixed B-collector semantics."""

        mma_op = tcgen05.SM107MmaMXF4NVF4BlockScaledSparseOp(
            ab_dtype=raw_ab_dtype,
            acc_dtype=acc_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            instruction_shape=instruction_shape,
            cta_group=cta_group,
            a_src=tcgen05.OperandSource.SMEM,
            a_major_mode=OperandMajorMode.K,
            b_major_mode=OperandMajorMode.K,
            sparse_metadata_format=tcgen05.SparseMetadataFormat.TID,
            a_collector_op=tcgen05.CollectorOp.DISCARD,
            b_collector_op=b_collector_op,
        )
        return cute.make_tiled_mma(
            cute.make_mma_atom(mma_op), permutation_mnk=permutation_mnk
        )

    def _create_tma_to_s2t_pipeline(
        self,
        num_stages: int,
        tma_operation_type: cute_ext.OperationTypeEnum,
        arrival_mask: cute.Int16,
        consumer_arrivals: int,
    ) -> tuple[
        cute_ext.PipelineState,
        cute_ext.PipelineState,
        cute_ext.PipelineState,
    ]:
        """Create the masked or maskless TMA-to-S2T lifecycle for one ring.

        The mask is a property of *this* ring's load, not of the launch. A
        producer that multicasts signals the barrier in every CTA its
        projection covers, so its consumer release must carry the runtime
        arrival mask; a 2-CTA MMA needs it for the same reason. A ring whose
        declared lifecycle is local must use the maskless form. SF may retain
        the conservative cluster lifecycle when its small loads are replicated;
        every named participant still releases before a stage can be reused.

        The distinction matters because the reader groups differ: at a 1x2
        cluster SFA and E multicast along N while SFB, which projects along M,
        does not. The compiler verifier rejects a mismatch in either direction
        rather than letting a release under- or over-signal.
        """

        multicasts = tma_operation_type in (
            cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST,
            cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST,
        )
        if cutlass.const_expr(self.use_2cta_instrs or multicasts):
            return cute_ext.create_pipeline(
                num_stages,
                tma_operation_type,
                self.s2t_operation_type,
                producer_arv_count=1,
                consumer_arv_count=consumer_arrivals,
                arrival_mask=arrival_mask,
            )
        return cute_ext.create_pipeline(
            num_stages,
            tma_operation_type,
            self.s2t_operation_type,
            producer_arv_count=1,
            consumer_arv_count=1,
        )

    @staticmethod
    def _make_sfb_stage_layout(
        sf_atom: cute.Layout,
        n: int,
        k: int,
    ) -> cute.Layout:
        """Tile the scale atom over an N128 or N256 SFB carrier."""
        if n == 128:
            return cute.tiled_product(
                sf_atom,
                cute.make_layout(
                    cute.shape_div((n, k), cute.product_each(sf_atom.shape))
                ),
            )
        if n != 256:
            raise ValueError(f"SFB stage layout requires N=128 or N=256, got {n}")
        sf_atom_n256 = cute.make_layout(
            shape=((32, 4, 2), (32, 4)),
            stride=((16, 4, k // 32 // 4 * 512), (0, 1)),
        )
        return cute.tiled_product(
            sf_atom_n256,
            cute.make_layout(
                cute.shape_div((n, k), cute.product_each(sf_atom_n256.shape))
            ),
        )

    def _launch_configured_kernel(
        self,
        a_compressed: cute.Tensor,
        b: cute.Tensor,
        sfa_tma_carrier: cute.Tensor,
        sfb_tma_carrier: cute.Tensor,
        e_sparse: cute.Tensor,
        c: cute.Tensor,
        tile_sched_params: PersistentTileSchedulerParams,
        persistent_cluster_count: Integer,
        grid: tuple[Integer, Integer, Integer],
        predicate_e_load: bool,
        predicate_output_store: bool,
        stream: cuda.CUstream,
        single_issue: bool = False,
    ) -> None:
        """Launch the selected input/output edge and K-range specialization."""

        self.kernel(
            a_compressed,
            b,
            sfa_tma_carrier,
            sfb_tma_carrier,
            e_sparse,
            c,
            tile_sched_params,
            persistent_cluster_count,
            predicate_e_load,
            predicate_output_store,
            single_issue,
        ).launch(
            grid=grid,
            block=(self.threads_per_cta, 1, 1),
            cluster=self.cluster_shape,
            smem=cute.Int64(self.smem_capacity),
            stream=stream,
            min_blocks_per_mp=self.min_blocks_per_mp,
        )

    def _setup_attributes(
        self,
        a_compressed: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        e: cute.Tensor,
        c: cute.Tensor,
    ) -> _SparseInputAttributes:
        """Validate the current inputs and prepare their sparse TMA views.

        Caller-derived configuration stays in ``__init__`` so host policy
        queries do not need a CUDA or MLIR context. Tensor-derived layouts
        remain local to this invocation; the device kernel builds its own
        region-local MMA, SFB partitioner and epilogue tile.
        """
        if cutlass.const_expr(c.element_type != self.c_dtype):
            raise ValueError("C tensor element type must match the configured c_dtype")
        m = cute.size(a_compressed, mode=[0])
        n = cute.size(b, mode=[0])
        k = cute.size(b, mode=[1])
        l = cute.size(a_compressed, mode=[2])
        runtime_assert(
            self.can_implement(
                (m, n, k, l),
                a_dtype=a_compressed.element_type,
                b_dtype=b.element_type,
                sfa_dtype=sfa.element_type,
                sfb_dtype=sfb.element_type,
                e_dtype=e.element_type,
                c_dtype=c.element_type,
                a_alignment=a_compressed.iterator.alignment,
                b_alignment=b.iterator.alignment,
                sfa_alignment=sfa.iterator.alignment,
                sfb_alignment=sfb.iterator.alignment,
                e_alignment=e.iterator.alignment,
                c_alignment=c.iterator.alignment,
                a_is_k_major=LayoutEnum.from_tensor(a_compressed).is_k_major_a(),
                b_is_k_major=LayoutEnum.from_tensor(b).is_k_major_b(),
                c_is_n_major=LayoutEnum.from_tensor(c).is_n_major_c(),
            ),
            "unsupported shape, dtype, major mode, or pointer alignment",
        )
        runtime_assert(
            cute.size(a_compressed, mode=[1]) * 2 == k,
            "compressed A must contain K/2 elements",
        )
        runtime_assert(cute.size(b, mode=[2]) == l, "A and B batch counts differ")
        runtime_assert(cute.size(c, mode=[0]) == m, "A and C M extents differ")
        runtime_assert(cute.size(c, mode=[1]) == n, "B and C N extents differ")
        runtime_assert(cute.size(c, mode=[2]) == l, "A and C batch counts differ")

        sfa_storage_shape, sfa_storage_stride = self._scale_storage_modes(m, k, l)
        sfb_storage_shape, sfb_storage_stride = self._scale_storage_modes(n, k, l)
        expected_sfa_layout = cute.make_layout(
            sfa_storage_shape,
            stride=sfa_storage_stride,
        )
        expected_sfb_layout = cute.make_layout(
            sfb_storage_shape,
            stride=sfb_storage_stride,
        )
        e_padded_m = cute.round_up(m, 128)
        e_padded_k = cute.round_up(k, 128)
        e_bytes_per_row = e_padded_k // 8
        expected_e_layout = cute.make_layout(
            (e_padded_m, e_bytes_per_row, l),
            stride=(e_bytes_per_row, 1, e_padded_m * e_bytes_per_row),
        )
        self._validate_physical_carrier_layout("SFA", sfa, expected_sfa_layout)
        self._validate_physical_carrier_layout("SFB", sfb, expected_sfb_layout)
        self._validate_physical_carrier_layout("E", e, expected_e_layout)

        # Construct the semantic sparse-metadata view and the physical scale
        # carriers outside the kernel boundary. Standard typed TMA owns its
        # partitioning, so its block arguments name complete, zero-stride-free
        # load boxes rather than the later broadcast-rich MMA/S2T views.
        raw_ab_dtype = cutlass.Float4E2M1FN
        problem_shape = (m, n, k, l)
        e_sparse_dtype = sm107_utils.make_sparse_e_dtype(raw_ab_dtype)
        e_sparse = cute.make_tensor(
            cute.recast_ptr(e.iterator, dtype=e_sparse_dtype),
            sm107_utils.make_sparse_gmem_layout_e(problem_shape, raw_ab_dtype),
        )
        # Give standard user SF storage an address-bearing atom hierarchy, then
        # preserve a multidimensional, zero-stride-free physical K carrier.
        # Each K = 128 atom becomes two 256-byte rows. For K = 768, TMA then
        # issues one four-dimensional instruction instead of decomposing a
        # flattened 3,072-byte span into twelve instructions.
        sfa_carrier = self._make_scale_carrier(sfa, m, k, l)
        sfb_carrier = self._make_scale_carrier(sfb, n, k, l)
        sfa_tma_carrier = self._make_scale_tma_carrier(sfa_carrier, m, k, l)
        sfb_tma_carrier = self._make_scale_tma_carrier(sfb_carrier, n, k, l)

        return _SparseInputAttributes(
            mnkl=(m, n, k, l),
            sfa_tma_carrier=sfa_tma_carrier,
            sfb_tma_carrier=sfb_tma_carrier,
            e_sparse=e_sparse,
        )

    @cute.jit
    def __call__(
        self,
        a_compressed: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        e: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """Build TMA descriptors and launch the configured sparse GEMM schedule.

        ``a_compressed`` and ``b`` are rank-three K-major FP4 tensors with
        shapes ``(M, K/2, L)`` and ``(N, K, L)`` respectively. ``sfa`` and
        ``sfb`` are standard padded rank-three vector-32 scale-factor storage;
        ``e`` is the padded Uint8 carrier for
        ``make_sparse_gmem_layout_e``. Their exact shapes and strides are
        validated before their pointers are reinterpreted. ``c`` is an N-major
        ``(M, N, L)`` tensor of the configured output type. All pointers must be
        at least 16-byte aligned;
        ``c`` is compiled with 32-byte alignment for the vector-store path.

        ``max_active_clusters`` is the device-reported capacity for the
        caller-provided cluster shape. The launch additionally applies the
        caller's persistent-cluster limit.
        """

        attributes = self._setup_attributes(a_compressed, b, sfa, sfb, e, c)
        m, n, k, l = attributes.mnkl
        sfa_tma_carrier = attributes.sfa_tma_carrier
        sfb_tma_carrier = attributes.sfb_tma_carrier
        e_sparse = attributes.e_sparse

        c_shape = cute.slice_(self.cta_tile_shape_mnk, (None, None, 0))
        c_tiled = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = c_tiled[(0, (None, None, None))].shape
        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl,
            self.cluster_shape,
            swizzle_size=1,
            raster_along_m=True,
        )
        persistent_cluster_count = min(
            max_active_clusters, self.persistent_cluster_limit
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, persistent_cluster_count
        )
        # The scheduler assigns work per cluster, so the unit that must divide
        # the problem is the whole cluster's output footprint, not one CTA
        # group's tile. When it does not divide, the trailing cluster contains
        # CTA groups whose tile lies entirely outside the problem; they still
        # run every pipeline iteration, so they must take the predicated store
        # entry rather than write a complete tile out of bounds.
        cluster_groups_m = self.cluster_shape[0] // self.num_mma_ctas
        cluster_tile_m = self.mma_tiler_mnk[0] * cluster_groups_m
        cluster_tile_n = self.cta_tile_shape_mnk[1] * self.cluster_shape[1]
        requires_predicated_output_store = (
            m % cluster_tile_m != 0 or n % cluster_tile_n != 0
        )
        requires_predicated_e_load = (
            m % cluster_tile_m != 0 or k % self.mma_tiler_mnk[2] != 0
        )
        # A single sparse issue needs only one AB phase. Select this on the
        # host so larger K retains its established device mainloop unchanged.
        if k <= self.MMA_INSTRUCTION_K:
            if cutlass.const_expr(self.use_tma_store):
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    False,
                    stream,
                    single_issue=True,
                )
            elif requires_predicated_output_store:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    True,
                    stream,
                    single_issue=True,
                )
            else:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    False,
                    stream,
                    single_issue=True,
                )
        elif cutlass.const_expr(self.use_tma_store):
            # Typed TMA retains D's original M/N bounds in its descriptor, so
            # one entry point safely suppresses out-of-bounds lanes for both
            # complete and partial output tiles.
            if requires_predicated_e_load:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    False,
                    stream,
                )
            else:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    False,
                    False,
                    stream,
                )
        elif requires_predicated_output_store:
            if requires_predicated_e_load:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    True,
                    stream,
                )
            else:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    False,
                    True,
                    stream,
                )
        else:
            if requires_predicated_e_load:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    True,
                    False,
                    stream,
                )
            else:
                self._launch_configured_kernel(
                    a_compressed,
                    b,
                    sfa_tma_carrier,
                    sfb_tma_carrier,
                    e_sparse,
                    c,
                    tile_sched_params,
                    persistent_cluster_count,
                    grid,
                    False,
                    False,
                    stream,
                )

    @cute.kernel
    def kernel(
        self,
        a_compressed: cute.Tensor,
        b: cute.Tensor,
        sfa_tma_carrier: cute.Tensor,
        sfb_tma_carrier: cute.Tensor,
        e_sparse: cute.Tensor,
        c: cute.Tensor,
        tile_sched_params: PersistentTileSchedulerParams,
        persistent_cluster_count: cutlass.Constexpr,
        predicate_e_load: cutlass.Constexpr,
        predicate_output_store: cutlass.Constexpr,
        single_issue: cutlass.Constexpr,
    ):
        """Execute the role-specialized persistent CTA1/CTA2 mainloop."""

        raw_ab_dtype: type[cutlass.Numeric] = cutlass.Float4E2M1FN
        sf_dtype: type[cutlass.Numeric] = cutlass.Float8E8M0FNU
        e_storage_dtype: type[cutlass.Numeric] = cutlass.Uint8
        acc_dtype: type[cutlass.Numeric] = cutlass.Float32
        m = cute.size(a_compressed, mode=[0])
        n = cute.size(b, mode=[0])
        k = cute.size(b, mode=[1])
        l = cute.size(a_compressed, mode=[2])
        e_sparse_dtype = sm107_utils.make_sparse_e_dtype(raw_ab_dtype)
        permutation_mnk = self._get_mma_permutation_mnk()
        tiled_mma = self._make_sparse_tiled_mma(
            raw_ab_dtype,
            acc_dtype,
            sf_dtype,
            self.sf_vec_size,
            self.mma_inst_shape_mnk,
            self.cta_group,
            permutation_mnk,
        )
        if cutlass.const_expr(self.enable_breuse):
            tiled_mma_bkeep = self._make_sparse_tiled_mma(
                raw_ab_dtype,
                acc_dtype,
                sf_dtype,
                self.sf_vec_size,
                self.mma_inst_shape_mnk,
                self.cta_group,
                permutation_mnk,
                tcgen05.CollectorOp.FILL,
            )
            tiled_mma_breuse = self._make_sparse_tiled_mma(
                raw_ab_dtype,
                acc_dtype,
                sf_dtype,
                self.sf_vec_size,
                self.mma_inst_shape_mnk,
                self.cta_group,
                permutation_mnk,
                tcgen05.CollectorOp.LASTUSE,
            )
        epilogue_tile = self._make_epi_tile(tiled_mma.op, LayoutEnum.from_tensor(c))
        # SFB needs the CTA1 block-scaled operand layout, independent of the
        # sparse instruction's K = 192 execution shape. The SM100 helper provides
        # that layout-only partitioner; it never emits an MMA instruction.
        # Computation uses the selected SM107 sparse CTA1/CTA2 atom above.
        dummy_tiled_mma_sfb = sm100_utils.make_blockscaled_trivial_tiled_mma(
            raw_ab_dtype,
            raw_ab_dtype,
            OperandMajorMode.K,
            OperandMajorMode.K,
            sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            (
                self.mma_inst_shape_mnk[0] // self.num_mma_ctas,
                self.mma_inst_shape_mnk[1],
            ),
        )
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape),
            (tiled_mma.thr_id.shape,),
        )
        cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape),
            (dummy_tiled_mma_sfb.thr_id.shape,),
        )
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cta_coord_vmnk = cluster_layout_vmnk.get_flat_coord(cta_rank_in_cluster)

        # Reuse one accumulator tile. Each epilogue warp in every participating
        # CTA signals when its TMEM reads finish; the MMA producer waits for
        # all these signals before overwriting the tile.
        acc_pipeline = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.acc_stages,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=self.acc_consumer_arrival_count,
            mma_operation_type=self.mma_operation_type,
        )
        acc_raw_pipeline = acc_pipeline.raw_pipeline
        acc_initial_producer_state = acc_pipeline.producer_state
        acc_initial_consumer_state = acc_pipeline.consumer_state

        # Four sparse MMA steps (K = 192 each) consume three A load stages.
        # Each stage holds 128 retained FP4 values per row after compression
        # (64 bytes per row, one K_SW64 phase). Each TMA load writes a complete,
        # independently aligned stage. The sparse dot derives a circular
        # descriptor from the ring when an instruction crosses a stage boundary.
        atom_cta_m = self.mma_inst_shape_mnk[0] // cute.size(tiled_mma.thr_id.shape)
        a_smem_layout = self._make_a_smem_layout(
            atom_cta_m,
            self.reuse_m,
            self.ab_stages,
        )
        # The sparse MMA consumes B through a K_SW128 Uint8 descriptor whose
        # K stage holds 128 bytes per row (256 FP4 values). Three independently
        # produced phases serve four K = 192 MMA steps; the middle steps use
        # circular descriptors across adjacent stages while the first and last
        # remain within one phase.
        b_smem_layout_atom = tcgen05.make_smem_layout_atom(
            tcgen05.SmemLayoutAtomKind.K_SW128, cutlass.Uint8
        )
        b_smem_layout = tcgen05.tile_to_mma_shape(
            b_smem_layout_atom,
            cute.append(
                (
                    (
                        self.mma_inst_shape_mnk[1] // cute.size(tiled_mma.thr_id.shape),
                        16,
                    ),
                    1,
                    8,
                ),
                self.ab_stages,
            ),
            order=(0, 1, 2),
        )
        # Build scale-factor and metadata layouts from blocks spanning 128
        # logical K elements. Form the K = 192 MMA views after the S2T copies
        # below; the amount held in TMEM depends on the B-reuse schedule.
        sf_layout_atom = bs_layout.BlockScaledBasicChunk(self.sf_vec_size).layout
        sfa_stage_layout = cute.tiled_divide(
            cute.tile_to_shape(
                sf_layout_atom,
                (self.mma_sf_tiler[0], self.mma_sf_tiler[2]),
                (2, 1),
            ),
            (128, 128),
        )
        sfb_stage_layout = self._make_sfb_stage_layout(
            sf_layout_atom,
            self.mma_sf_tiler[1],
            self.mma_sf_tiler[2],
        )
        if cutlass.const_expr(self.enable_breuse):
            # Keep all K = 768 scale factors in SMEM, but copy one K = 384 half
            # to TMEM at a time. Preserve the source strides so selecting a
            # half changes only the range copied, not its layout.
            sf_tmem_k_block_count = self.sf_tmem_k // self.SCALE_K_ATOM_ELEMENTS
            sfa_tmem_stage_layout = cute.make_layout(
                shape=(
                    sfa_stage_layout.shape[0],
                    sfa_stage_layout.shape[1],
                    sf_tmem_k_block_count,
                ),
                stride=sfa_stage_layout.stride,
            )
            sfb_tmem_stage_layout = cute.make_layout(
                shape=(
                    sfb_stage_layout.shape[0],
                    sfb_stage_layout.shape[1],
                    sf_tmem_k_block_count,
                ),
                stride=sfb_stage_layout.stride,
            )
        else:
            # Preserve the established no-reuse K = 768 TMEM layouts exactly.
            sfa_tmem_stage_layout = sfa_stage_layout
            sfb_tmem_stage_layout = sfb_stage_layout
        sfa_smem_layout = cute.append(
            sfa_stage_layout,
            cute.make_layout(
                self.sf_stages,
                stride=cute.cosize(cute.filter_zeros(sfa_stage_layout)),
            ),
        )
        sfb_smem_layout = cute.append(
            sfb_stage_layout,
            cute.make_layout(
                self.sf_stages,
                stride=cute.cosize(cute.filter_zeros(sfb_stage_layout)),
            ),
        )

        # E uses Rubin's unswizzled Tensor-E layout. S2T copies reorder its
        # blocks from SMEM (M, K) order to TMEM (K, M) order.
        e_smem_layout_atom = sm107_utils.make_tensor_e_atom_layout(raw_ab_dtype)
        # Multicast selection uses E_ATOM_M/K before this layout exists.
        # Check those constants against the actual layout to avoid selecting
        # an incompatible multicast width if the layout changes.
        assert cute.size(e_smem_layout_atom, mode=[0]) == self.E_ATOM_M, (
            "Tensor-E atom M changed: "
            f"{cute.size(e_smem_layout_atom, mode=[0])} != {self.E_ATOM_M}"
        )
        assert cute.size(e_smem_layout_atom, mode=[1]) == self.E_ATOM_K, (
            "Tensor-E atom K changed: "
            f"{cute.size(e_smem_layout_atom, mode=[1])} != {self.E_ATOM_K}"
        )
        e_smem_layout_untiled = cute.tile_to_shape(
            e_smem_layout_atom,
            (self.mma_sf_tiler[0], self.mma_sf_tiler[2]),
            order=(0, 1),
        )
        e_stage_layout = cute.tiled_divide(
            e_smem_layout_untiled,
            e_smem_layout_atom.shape,
        )
        e_smem_layout = cute.append(
            e_stage_layout,
            cute.make_layout(
                self.e_stages,
                stride=cute.cosize(e_smem_layout_untiled),
            ),
        )

        s_a = cute_ext.allocate(
            cutlass.Uint8, cute.AddressSpace.smem, a_smem_layout, alignment=1024
        )
        s_a_mma_layout = cute.recast_layout(
            raw_ab_dtype.width,
            cutlass.Uint8.width,
            s_a.layout,
        )
        s_a_mma_iterator = cute.recast_ptr(
            s_a.iterator,
            a_smem_layout.inner,
            dtype=raw_ab_dtype,
        )
        # Pair the recast iterator with the explicit composed layout so sparse
        # dot addresses the same K_SW64 bytes populated by TMA.
        s_a_mma = cute.make_tensor(s_a_mma_iterator, s_a_mma_layout)
        if cutlass.const_expr(self.enable_breuse):
            # Slice the independent physical rings before constructing the
            # composed MMA views. Each descriptor therefore wraps only among
            # stages belonging to the same M half.
            s_a_mma_bkeep = s_a_mma[None, None, None, None, 0]
            s_a_mma_breuse = s_a_mma[None, None, None, None, 1]
            a_circular_inner = self._make_circular_mma_inner(s_a_mma_bkeep.layout)
        else:
            a_circular_inner = self._make_circular_mma_inner(s_a_mma.layout)
        # Each sparse-dot call consumes one per-CTA M slice. B reuse supplies
        # two slices with the same operand layout.
        a_mma_outer = cute.make_ordered_layout(
            ((atom_cta_m, self.mma_inst_shape_mnk[2]), 1, 1),
            order=((1, 0), 2, 3),
        )
        a_mma_ring_outer = cute.append(
            a_mma_outer,
            cute.make_layout(
                self.ab_stages,
                # The stride is expressed in FP4 elements: 128 FP4 = 64 B.
                stride=atom_cta_m * 128,
            ),
        )
        s_b = cute_ext.allocate(
            cutlass.Uint8,
            cute.AddressSpace.smem,
            b_smem_layout,
            alignment=1024,
        )
        b_mma_mn = cute.size(tiled_mma.tv_layout_B[1][0])
        s_b_mma = cute.recast_tensor(s_b, raw_ab_dtype)
        s_b_mma_iterator = cute.recast_ptr(
            s_b.iterator,
            b_smem_layout.inner,
            dtype=raw_ab_dtype,
        )
        b_circular_inner = self._make_circular_mma_inner(s_b_mma.layout)
        b_mma_outer = cute.make_ordered_layout(
            ((b_mma_mn, self.mma_inst_shape_mnk[2]), 1, 1),
            order=((1, 0), 2, 3),
        )
        b_mma_ring_outer = cute.append(
            b_mma_outer,
            cute.make_layout(
                self.ab_stages,
                # The stride is expressed in FP4 elements: 256 FP4 = 128 B.
                stride=b_mma_mn * 256,
            ),
        )
        # Precompute one A/B view per MMA step. Each view fixes the within-stage
        # offset; the pipeline stage index selects its current position in the
        # ring. This avoids rebuilding the layouts inside the K loop.
        if cutlass.const_expr(self.enable_breuse):
            a_mma_bkeep_issue_rings = tuple(
                cute.make_tensor(
                    s_a_mma_bkeep.iterator,
                    cute.make_composed_layout(
                        a_circular_inner,
                        atom_cta_m * kblock * 32,
                        a_mma_ring_outer,
                    ),
                )
                for kblock in (0, 3, 2, 1)
            )
            a_mma_breuse_issue_rings = tuple(
                cute.make_tensor(
                    s_a_mma_breuse.iterator,
                    cute.make_composed_layout(
                        a_circular_inner,
                        atom_cta_m * kblock * 32,
                        a_mma_ring_outer,
                    ),
                )
                for kblock in (0, 3, 2, 1)
            )
        else:
            a_mma_issue_rings = tuple(
                cute.make_tensor(
                    s_a_mma_iterator,
                    cute.make_composed_layout(
                        a_circular_inner,
                        atom_cta_m * kblock * 32,
                        a_mma_ring_outer,
                    ),
                )
                for kblock in (0, 3, 2, 1)
            )
        b_mma_issue_rings = tuple(
            cute.make_tensor(
                s_b_mma_iterator,
                cute.make_composed_layout(
                    b_circular_inner,
                    b_mma_mn * kblock * 32,
                    b_mma_ring_outer,
                ),
            )
            for kblock in (0, 6, 4, 2)
        )
        a_tma_gmem = cute.recast_tensor(a_compressed, cutlass.Uint8)
        b_tma_gmem = cute.recast_tensor(b, cutlass.Uint8)
        a_tma_stage_shape = (atom_cta_m, 64)
        b_tma_stage_shape = (b_mma_mn, 128)
        a_tma_stage_grid = cute.zipped_divide(a_tma_gmem, a_tma_stage_shape)
        b_tma_stage_grid = cute.zipped_divide(b_tma_gmem, b_tma_stage_shape)
        # These byte-domain layouts describe one independently produced stage.
        # They exclude descriptor padding and match the transfer extent used
        # by each tma_load's transaction-byte accounting before the shared commit.
        a_tma_stage_layout = cute.make_layout(
            a_tma_stage_shape,
            stride=(1, atom_cta_m),
        )
        b_tma_stage_layout = cute.make_layout(
            b_tma_stage_shape,
            stride=(1, b_mma_mn),
        )
        s_sfa = cute_ext.allocate(
            sf_dtype, cute.AddressSpace.smem, sfa_smem_layout, alignment=128
        )
        s_sfb = cute_ext.allocate(
            sf_dtype, cute.AddressSpace.smem, sfb_smem_layout, alignment=128
        )
        s_e = cute_ext.allocate(
            e_sparse_dtype, cute.AddressSpace.smem, e_smem_layout, alignment=128
        )

        # Use the MMA's accumulator layout for the complete output tile,
        # including both M slices when B is reused.
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler_mnk[:2])
        acc_layout = tiled_mma.make_fragment_C(cute.append(acc_shape, 1)).layout
        t_sfa_one = bs_layout.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            sfa_tmem_stage_layout,
        )
        t_sfb_one = bs_layout.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            sfb_tmem_stage_layout,
        )
        # Give MMA a scale-factor view with its required row/K grouping.
        # The S2T copies use separate views of the same storage.
        mn_basic_block_shape = (32, 4)
        k_basic_block_shape = (self.sf_vec_size, 1)
        mma_atom_cta_m = self.mma_inst_shape_mnk[0] // self.num_mma_ctas
        sfa_mma_iter_shape = (
            (
                mn_basic_block_shape,
                mma_atom_cta_m // self.SCALE_MN_ATOM_ELEMENTS,
            ),
            k_basic_block_shape,
        )
        sfa_iter_layout = cute.make_layout(
            (
                sfa_mma_iter_shape,
                self.reuse_m,
                self.sf_tmem_k // self.sf_vec_size,
            )
        )
        sfb_mma_iter_shape = (
            (mn_basic_block_shape, self.mma_sf_tiler[1] // 128),
            k_basic_block_shape,
        )
        sfb_iter_layout = cute.make_layout(
            (
                sfb_mma_iter_shape,
                1,
                self.sf_tmem_k // self.sf_vec_size,
            )
        )
        t_sfa_mma_layout = bs_layout.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            sfa_iter_layout,
        )
        t_sfb_mma_layout = bs_layout.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler_mnk,
            self.sf_vec_size,
            sfb_iter_layout,
        )
        # MMA addresses E's K blocks before its M blocks, unlike the SMEM
        # layout's (M, K) order. Without B reuse, TMEM holds all K = 768
        # metadata. B reuse holds a K = 384 half, except N = 256 uses a rolling
        # K = 256 window.
        e_tmem_padded_m = cute.ceil_div(self.mma_sf_tiler[0], 128) * 128
        e_tmem_k = 256 if self.enable_e_tmem_reuse else self.sf_tmem_k
        e_tmem_untiled = cute.tile_to_shape(
            e_smem_layout_atom,
            (e_tmem_k, e_tmem_padded_m),
            order=(1, 2),
        )
        e_tmem_shape = cute.tiled_divide(e_tmem_untiled, (128, 128)).shape
        t_e_one = sm107_utils.make_sparse_tmem_layout_e(e_tmem_shape, raw_ab_dtype)
        if cutlass.const_expr(self.enable_breuse):
            # Allocate E using its packed byte layout so the allocation counts
            # stored bytes, not logical sparse entries.
            e_tmem_element_type = e_storage_dtype
            e_tmem_layout = cute.recast_layout(
                e_storage_dtype.width,
                e_sparse_dtype.width,
                t_e_one,
            )
        else:
            # Without B reuse, allocate the sparse layout and recast it below.
            e_tmem_element_type = e_sparse_dtype
            e_tmem_layout = t_e_one
        # The compiler packs ACC, SFA, SFB and E into one TMEM allocation and
        # manages its lifetime. Keep this declaration order to preserve their
        # column offsets.
        t_acc = cute_ext.allocate(
            acc_dtype,
            cute.AddressSpace.tmem,
            acc_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        t_sfa = cute_ext.allocate(
            sf_dtype,
            cute.AddressSpace.tmem,
            t_sfa_one,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        t_sfb = cute_ext.allocate(
            sf_dtype,
            cute.AddressSpace.tmem,
            t_sfb_one,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        t_e = cute_ext.allocate(
            e_tmem_element_type,
            cute.AddressSpace.tmem,
            e_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        t_sfa_mma = cute.make_tensor(t_sfa.iterator, t_sfa_mma_layout)
        t_sfb_mma = cute.make_tensor(t_sfb.iterator, t_sfb_mma_layout)
        if cutlass.const_expr(self.enable_breuse):
            t_e_storage = t_e
        else:
            # Recast the complete E tensor to bytes before slicing so slice
            # offsets follow its packed storage layout.
            t_e_storage = cute.recast_tensor(t_e, e_storage_dtype)
        t_e_mma = t_e_storage
        e_mma_issue_layout = cute.make_layout(
            ((mma_atom_cta_m, self.mma_inst_shape_mnk[2]), 1, 1),
            stride=((1, 0), 0, 0),
        )
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        tidx, _, _ = cute.arch.thread_idx()

        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        a_mcast_mask = cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, cta_coord_vmnk, mcast_mode=2
        )
        b_mcast_mask = cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, cta_coord_vmnk, mcast_mode=1
        )
        peer_coord_vmnk = (
            cta_coord_vmnk[0] ^ self.cta_pair_rank_mask,
            cta_coord_vmnk[1],
            cta_coord_vmnk[2],
            cta_coord_vmnk[3],
        )
        a_peer_mask = cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, peer_coord_vmnk, mcast_mode=2
        )
        b_peer_mask = cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, peer_coord_vmnk, mcast_mode=1
        )
        group_release_mask = a_mcast_mask | b_mcast_mask | a_peer_mask | b_peer_mask
        # A/B loads may be private to one MMA group or multicast across groups.
        # Match the pipeline to the load operation so a stage is reused only
        # after all local and remote readers finish. Single-issue entries keep
        # their multicast carrier; full-K entries use the caller's sharing choice.
        ab_tma_op = self.tma_op
        if cutlass.const_expr(not single_issue and not self.retains_ab_multicast):
            ab_tma_op = (
                cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
                if self.use_2cta_instrs
                else cute_ext.OperationTypeEnum.SM90_TMA_LOAD
            )
        # W5's A and B loads add expected bytes to one AB full barrier before
        # its sole producer commit. W4 retires each stage after both operands
        # have been read; the selected operation defines its reader scope.
        ab_pipeline = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.ab_stages,
            mma_operation_type=self.mma_operation_type,
            tma_operation_type=ab_tma_op,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )
        ab_raw_pipeline = ab_pipeline.raw_pipeline
        ab_initial_producer_state = ab_pipeline.producer_state
        ab_initial_consumer_state = ab_pipeline.consumer_state
        # W6 loads SFA/SFB for W4's S2T copies. Their shared pipeline release
        # mask covers both multicast directions. Keep this mask and arrival
        # count even for one-CTA 1x8/1x16 clusters, where both loads are local.
        # A local-only pipeline would require changing its operation, release
        # mask and arrival count together. E selects its own reader group below.
        # SF producer and consumer use separate stage/phase state.
        sf_raw_pipeline, sf_producer_state, sf_consumer_state = (
            self._create_tma_to_s2t_pipeline(
                self.sf_stages,
                self.sf_tma_op,
                group_release_mask,
                self.scale_metadata_consumer_arrivals,
            )
        )
        # E is shared along cluster N, like A. Separate E copies have readers
        # only in their local MMA group, not in unrelated groups along M.
        if cutlass.const_expr(self.e_use_tma_multicast):
            e_release_mask = a_mcast_mask | a_peer_mask
        else:
            e_release_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, cta_coord_vmnk, mcast_mode=0
            )
        e_raw_pipeline, e_producer_state, e_consumer_state = (
            self._create_tma_to_s2t_pipeline(
                self.e_stages,
                self.e_tma_op,
                e_release_mask,
                self.metadata_consumer_arrivals,
            )
        )
        # All CTAs in a cluster share blockIdx.z as their work index. The grid
        # cap gives every launched cluster an initial tile; each role stops at
        # the total output-cluster tile count.
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        initial_work_linear_idx = cutlass.Int32(cute.arch.block_idx()[2])
        problem_cluster_tile_count = cute.size(
            tile_sched_params.problem_layout_ncluster_mnl
        )
        k_tile_count = cute.ceil_div(k, self.mma_inst_shape_mnk[2])
        macro_tile_count = (
            1
            if single_issue
            else cute.ceil_div(k_tile_count, self.mma_issues_per_group)
        )
        # One K = 768 scale/metadata stage serves up to four MMA steps.
        carrier_tile_count = macro_tile_count

        # Expose each 128-row scale-factor block as twelve contiguous 256-byte
        # rows for K = 768. Preserve the additional M/N block index so TMA can
        # copy the complete stage with one multidimensional load. These views
        # omit the zero-stride broadcast modes used by MMA/S2T.
        sf_k_atom_count = self.mma_tiler_mnk[2] // self.SCALE_K_ATOM_ELEMENTS
        sf_tma_carrier_bytes = sf_k_atom_count * self.SCALE_K_ATOM_BYTES
        sf_tma_segment_count = sf_k_atom_count * (
            self.SCALE_K_ATOM_BYTES // self.SCALE_TMA_MINOR_BYTES
        )
        sfa_tma_stage_shape = (
            self.sf_tma_minor_bytes,
            sf_tma_segment_count,
            self.sfa_scale_atom_count,
            1,
        )
        sfb_tma_stage_shape = (
            self.sf_tma_minor_bytes,
            sf_tma_segment_count,
            self.sfb_scale_atom_count,
            1,
        )
        t_g_sfa_tma = cute.zipped_divide(sfa_tma_carrier, sfa_tma_stage_shape)
        t_g_sfb_tma = cute.zipped_divide(sfb_tma_carrier, sfb_tma_stage_shape)
        # Give the SMEM destination the same row grouping as the TMA source,
        # without changing its backing bytes or retaining broadcast modes.
        if cutlass.const_expr(self.enable_breuse):
            # B reuse gives each CTA two 128-row M blocks. Keep the third mode
            # that selects their separate K = 768 scale-factor storage.
            sfa_tma_stage_layout = cute.make_layout(
                (
                    self.sf_tma_minor_bytes,
                    sf_tma_segment_count,
                    self.sfa_scale_atom_count,
                ),
                stride=(
                    1,
                    self.sf_tma_minor_bytes,
                    sf_tma_carrier_bytes,
                ),
            )
        else:
            # Without B reuse, each CTA has just one 128-row M block.
            sfa_tma_stage_layout = cute.make_layout(
                (self.sf_tma_minor_bytes, sf_tma_segment_count),
                stride=(1, self.sf_tma_minor_bytes),
            )
        sfb_tma_stage_layout = cute.make_layout(
            (
                self.sf_tma_minor_bytes,
                sf_tma_segment_count,
                self.sfb_scale_atom_count,
            ),
            stride=(1, self.sf_tma_minor_bytes, sf_tma_carrier_bytes),
        )
        e_group_tiles = cute.local_tile(
            e_sparse,
            (self.mma_sf_tiler[0], self.mma_sf_tiler[2]),
            (None, None, None),
        )
        mma_sf_inst_shape_m = self.mma_inst_shape_mnk[0] // cute.size(
            tiled_mma.thr_layout_vmnk.shape[0]
        )
        e_tiled_layout = cute.tiled_divide(
            e_group_tiles.layout,
            (mma_sf_inst_shape_m, 128),
        )
        if cutlass.const_expr(predicate_e_load):
            # Tensor-level tiling retains the padded metadata carrier's M/K
            # bounds, so loads beyond its allocated extent are predicated.
            t_g_e = cute.tiled_divide(
                e_group_tiles,
                (mma_sf_inst_shape_m, 128),
            )
        else:
            # For statically complete M/K tilings, rebasing the same layout on
            # the tile iterator keeps the compact TMA coordinate descriptor.
            t_g_e = cute.make_tensor(e_group_tiles.iterator, e_tiled_layout)

        if warp_idx == self.AB_E_LOAD_WARP_ID:
            ab_producer_wave = cutlass.Int32(0)
            # Carry each pipeline's stage and phase through the K and output-
            # tile loops so each iteration continues from the previous state.
            for (
                work_linear_idx,
                ab_e_work_state,
                ab_e_work_result,
            ) in cutlass.for_generate(
                initial_work_linear_idx,
                problem_cluster_tile_count,
                cutlass.Int32(persistent_cluster_count),
                [
                    e_producer_state,
                    ab_initial_producer_state,
                    ab_producer_wave,
                ],
            ):
                (
                    e_work_producer_state,
                    ab_work_producer_state,
                    ab_producer_wave,
                ) = ab_e_work_state
                work_tile = tile_sched._get_current_work_for_linear_idx(work_linear_idx)
                coord = work_tile.tile_idx
                group_coord = (
                    cutlass.Int32(
                        cutlass.Uint32(coord[0]) // cute.size(tiled_mma.thr_id.shape)
                    ),
                    coord[1],
                    coord[2],
                )
                g_e_tile = t_g_e[(None, None, None, coord[0], None, group_coord[2])]
                for (
                    macro_tile,
                    ab_e_carrier_state,
                    ab_e_carrier_result,
                ) in cutlass.for_generate(
                    0,
                    macro_tile_count,
                    1,
                    [
                        e_work_producer_state,
                        ab_work_producer_state,
                        ab_producer_wave,
                    ],
                    unroll=cutlass.LoopUnroll(count=1),
                ):
                    (
                        e_carrier_producer_state,
                        ab_carrier_producer_state,
                        ab_producer_wave,
                    ) = ab_e_carrier_state
                    e_carrier_pipeline = cute_ext.GenericPipeline(
                        e_raw_pipeline,
                        self.e_stages,
                        e_carrier_producer_state,
                        e_consumer_state,
                    )
                    ab_carrier_pipeline = cute_ext.GenericPipeline(
                        ab_raw_pipeline,
                        self.ab_stages,
                        ab_carrier_producer_state,
                        ab_initial_consumer_state,
                    )
                    for buffer in cutlass.range_constexpr(
                        1 if single_issue else self.ab_phases_per_group
                    ):
                        # Issue E before A/B so its TMA load and later S2T
                        # copy can overlap operand loading.
                        if cutlass.const_expr(buffer == 0):
                            e_token, e_stage = (
                                e_carrier_pipeline.producer_acquire_and_get_stage()
                            )
                            e_mbar = cute_ext.get_mbarrier(e_token)
                            e_source = g_e_tile[(None, None, None, macro_tile)]
                            e_destination = s_e[None, None, None, e_stage]
                            assert cute.size(e_source) == cute.size(e_destination), (
                                "E TMA source/destination size mismatch: "
                                f"{cute.size(e_source)} != "
                                f"{cute.size(e_destination)}"
                            )
                            cute_ext.tma_load(
                                e_source,
                                e_destination,
                                e_mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=self.e_tma_op,
                                multicast_mode=2,
                                internal_type=cutlass.Uint64,
                                update_expect_tx=True,
                            )
                            e_carrier_pipeline.producer_commit_and_advance(
                                elect_one_sync=True,
                                elect_leader_cta=self.use_2cta_instrs,
                            )
                        ab_empty_ready = cutlass.Boolean(1)
                        if ab_producer_wave >= self.ab_stages:
                            # Check whether the next A/B stage is free before
                            # waiting. E was already issued and can progress
                            # during the wait.
                            ab_empty_ready = ab_carrier_pipeline.producer_try_acquire()
                        ab_token, ab_stage = (
                            ab_carrier_pipeline.producer_acquire_and_get_stage(
                                token=ab_empty_ready
                            )
                        )
                        ab_mbar = cute_ext.get_mbarrier(ab_token)
                        # Without B reuse, form both tensor maps before loading
                        # A then B. With B reuse, load each 128-row A slice into
                        # its own ring, then load B. All loads add transaction
                        # bytes to the same barrier before one producer commit.
                        if cutlass.const_expr(self.enable_breuse):
                            for a_half in cutlass.range_constexpr(self.reuse_m):
                                a_tile_coord = coord[0] * self.reuse_m + a_half
                                a_stage = s_a[None, None, None, ab_stage, a_half]
                                a_source = a_tma_stage_grid[
                                    (None, None),
                                    (
                                        a_tile_coord,
                                        macro_tile * self.ab_phases_per_group + buffer,
                                        group_coord[2],
                                    ),
                                ]
                                a_destination = cute.composition(
                                    a_stage,
                                    a_tma_stage_layout,
                                )
                                assert cute.size(a_source) == cute.size(
                                    a_destination
                                ), (
                                    "A TMA source/destination size mismatch: "
                                    f"{cute.size(a_source)} != "
                                    f"{cute.size(a_destination)}"
                                )
                                cute_ext.tma_load(
                                    a_source,
                                    a_destination,
                                    ab_mbar,
                                    vmnk_layout=cluster_layout_vmnk,
                                    tma_operation_type=ab_tma_op,
                                    multicast_mode=2,
                                    internal_type=cutlass.Uint8,
                                    update_expect_tx=True,
                                )
                            b_tile_coord = (
                                coord[1] * (self.mma_tiler_mnk[1] // b_mma_mn)
                                + mma_tile_coord_v
                            )
                            b_source = b_tma_stage_grid[
                                (None, None),
                                (
                                    b_tile_coord,
                                    macro_tile * self.ab_phases_per_group + buffer,
                                    group_coord[2],
                                ),
                            ]
                            b_destination = cute.composition(
                                s_b[None, None, None, ab_stage],
                                b_tma_stage_layout,
                            )
                            assert cute.size(b_source) == cute.size(b_destination), (
                                "B TMA source/destination size mismatch: "
                                f"{cute.size(b_source)} != {cute.size(b_destination)}"
                            )
                            cute_ext.tma_load(
                                b_source,
                                b_destination,
                                ab_mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=ab_tma_op,
                                multicast_mode=1,
                                internal_type=cutlass.Uint8,
                                update_expect_tx=True,
                            )
                        else:
                            a_source = a_tma_stage_grid[
                                (None, None),
                                (
                                    coord[0],
                                    macro_tile * self.ab_phases_per_group + buffer,
                                    group_coord[2],
                                ),
                            ]
                            a_destination = cute.composition(
                                s_a[None, None, None, ab_stage],
                                a_tma_stage_layout,
                            )
                            assert cute.size(a_source) == cute.size(a_destination), (
                                "A TMA source/destination size mismatch: "
                                f"{cute.size(a_source)} != "
                                f"{cute.size(a_destination)}"
                            )
                            b_tile_coord = (
                                coord[1] * (self.mma_tiler_mnk[1] // b_mma_mn)
                                + mma_tile_coord_v
                            )
                            b_source = b_tma_stage_grid[
                                (None, None),
                                (
                                    b_tile_coord,
                                    macro_tile * self.ab_phases_per_group + buffer,
                                    group_coord[2],
                                ),
                            ]
                            b_destination = cute.composition(
                                s_b[None, None, None, ab_stage],
                                b_tma_stage_layout,
                            )
                            assert cute.size(b_source) == cute.size(b_destination), (
                                "B TMA source/destination size mismatch: "
                                f"{cute.size(b_source)} != {cute.size(b_destination)}"
                            )
                            cute_ext.tma_load(
                                a_source,
                                a_destination,
                                ab_mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=ab_tma_op,
                                multicast_mode=2,
                                internal_type=cutlass.Uint8,
                                update_expect_tx=True,
                            )
                            cute_ext.tma_load(
                                b_source,
                                b_destination,
                                ab_mbar,
                                vmnk_layout=cluster_layout_vmnk,
                                tma_operation_type=ab_tma_op,
                                multicast_mode=1,
                                internal_type=cutlass.Uint8,
                                update_expect_tx=True,
                            )
                        ab_carrier_pipeline.producer_commit_and_advance(
                            elect_one_sync=True,
                            elect_leader_cta=self.use_2cta_instrs,
                        )
                        ab_producer_wave += 1
                    cutlass.yield_out(
                        [
                            e_carrier_pipeline.producer_state,
                            ab_carrier_pipeline.producer_state,
                            ab_producer_wave,
                        ]
                    )
                (
                    e_work_producer_state,
                    ab_work_producer_state,
                    ab_producer_wave,
                ) = ab_e_carrier_result
                cutlass.yield_out(
                    [
                        e_work_producer_state,
                        ab_work_producer_state,
                        ab_producer_wave,
                    ]
                )
            cute_ext.pipeline_tail(e_raw_pipeline, ab_e_work_result[0])
            cute_ext.pipeline_tail(ab_raw_pipeline, ab_e_work_result[1])

        elif warp_idx == self.SF_LOAD_WARP_ID:
            for (
                work_linear_idx,
                sf_work_state,
                sf_work_result,
            ) in cutlass.for_generate(
                initial_work_linear_idx,
                problem_cluster_tile_count,
                cutlass.Int32(persistent_cluster_count),
                [sf_producer_state],
            ):
                sf_work_producer_state = sf_work_state
                work_tile = tile_sched._get_current_work_for_linear_idx(work_linear_idx)
                coord = work_tile.tile_idx
                group_coord = (
                    cutlass.Int32(
                        cutlass.Uint32(coord[0]) // cute.size(tiled_mma.thr_id.shape)
                    ),
                    coord[1],
                    coord[2],
                )
                for (
                    carrier_tile,
                    sf_carrier_state,
                    sf_carrier_result,
                ) in cutlass.for_generate(
                    0,
                    carrier_tile_count,
                    1,
                    [sf_work_producer_state],
                    unroll=cutlass.LoopUnroll(count=1),
                ):
                    sf_carrier_pipeline = cute_ext.GenericPipeline(
                        sf_raw_pipeline,
                        self.sf_stages,
                        sf_carrier_state,
                        sf_consumer_state,
                    )
                    sf_token, sf_stage = (
                        sf_carrier_pipeline.producer_acquire_and_get_stage()
                    )
                    sf_mbar = cute_ext.get_mbarrier(sf_token)
                    # Add both SFA and SFB transfer sizes before the single
                    # producer commit. The shared stage becomes ready only
                    # after both transfers complete.
                    if cutlass.const_expr(self.enable_breuse):
                        # Load both 128-row M blocks using the CTA tile's M
                        # coordinate, not the MMA group's: each CTA owns a
                        # separate 256-row slice.
                        sfa_source_tma = t_g_sfa_tma[
                            (None, None, None, 0),
                            (0, carrier_tile, coord[0], group_coord[2]),
                        ]
                    else:
                        sfa_source_tma = t_g_sfa_tma[
                            (None, None, 0, 0),
                            (0, carrier_tile, coord[0], group_coord[2]),
                        ]
                    sfa_destination = s_sfa[None, None, None, sf_stage]
                    sfa_destination_tma = cute.make_tensor(
                        sfa_destination.iterator,
                        sfa_tma_stage_layout,
                    )
                    assert cute.size(sfa_source_tma) == cute.size(
                        sfa_destination_tma
                    ), (
                        "SFA TMA source/destination size mismatch: "
                        f"{cute.size(sfa_source_tma)} != "
                        f"{cute.size(sfa_destination_tma)}"
                    )
                    cute_ext.tma_load(
                        sfa_source_tma,
                        sfa_destination_tma,
                        sf_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=self.sfa_tma_op,
                        multicast_mode=2,
                        internal_type=cutlass.Uint64,
                        update_expect_tx=True,
                    )
                    sfb_source_tma = t_g_sfb_tma[
                        (None, None, None, 0),
                        (0, carrier_tile, group_coord[1], group_coord[2]),
                    ]
                    sfb_destination = s_sfb[None, None, None, sf_stage]
                    sfb_destination_tma = cute.make_tensor(
                        sfb_destination.iterator,
                        sfb_tma_stage_layout,
                    )
                    assert cute.size(sfb_source_tma) == cute.size(
                        sfb_destination_tma
                    ), (
                        "SFB TMA source/destination size mismatch: "
                        f"{cute.size(sfb_source_tma)} != "
                        f"{cute.size(sfb_destination_tma)}"
                    )
                    cute_ext.tma_load(
                        sfb_source_tma,
                        sfb_destination_tma,
                        sf_mbar,
                        vmnk_layout=cluster_layout_sfb_vmnk,
                        tma_operation_type=self.sfb_tma_op,
                        multicast_mode=1,
                        internal_type=cutlass.Uint64,
                        update_expect_tx=True,
                    )
                    sf_carrier_pipeline.producer_commit_and_advance(
                        elect_one_sync=True,
                        elect_leader_cta=self.use_2cta_instrs,
                    )
                    cutlass.yield_out([sf_carrier_pipeline.producer_state])
                sf_work_producer_state = sf_carrier_result
                cutlass.yield_out([sf_work_producer_state])
            cute_ext.pipeline_tail(sf_raw_pipeline, sf_work_result)

        elif warp_idx == self.MMA_WARP_ID and is_leader_cta:
            sfa_copy_atom = cute.make_copy_atom(
                tcgen05.Cp4x32x128bOp(self.cta_group), sf_dtype
            )
            sfb_copy_atom = cute.make_copy_atom(
                tcgen05.Cp4x32x128bOp(self.cta_group), sf_dtype
            )
            e_copy_atom = cute.make_copy_atom(
                tcgen05.Cp128x128bOp(self.cta_group), e_storage_dtype
            )
            t_sfa_compact = cute.filter_zeros(t_sfa)
            t_sfa_copy_view = cute.make_tensor(
                t_sfa_compact.iterator,
                cute.append(
                    cute.append(
                        t_sfa_compact[(None, 0, 0)].layout,
                        cute.make_layout(1),
                    ),
                    cute.make_layout(1),
                ),
            )
            tiled_sfa_copy = tcgen05.make_s2t_copy(sfa_copy_atom, t_sfa_copy_view)
            sfa_copy_slice = tiled_sfa_copy.get_slice(cute.Int32(0))

            t_sfb_compact = cute.filter_zeros(t_sfb)
            t_sfb_copy_view = cute.make_tensor(
                t_sfb_compact.iterator,
                cute.append(
                    cute.append(
                        t_sfb_compact[(None, 0, 0)].layout,
                        cute.make_layout(1),
                    ),
                    cute.make_layout(1),
                ),
            )
            tiled_sfb_copy = tcgen05.make_s2t_copy(sfb_copy_atom, t_sfb_copy_view)
            sfb_copy_slice = tiled_sfb_copy.get_slice(cute.Int32(0))
            tiled_e_copy = tcgen05.make_s2t_copy(e_copy_atom, t_e_storage)

            for (
                work_linear_idx,
                mma_work_state,
                mma_work_result,
            ) in cutlass.for_generate(
                initial_work_linear_idx,
                problem_cluster_tile_count,
                cutlass.Int32(persistent_cluster_count),
                [
                    sf_consumer_state,
                    e_consumer_state,
                    ab_initial_consumer_state,
                    ab_initial_consumer_state,
                    acc_initial_producer_state,
                ],
            ):
                (
                    sf_work_consumer_state,
                    e_work_consumer_state,
                    ab_wait_work_consumer_state,
                    ab_release_work_consumer_state,
                    acc_work_producer_state,
                ) = mma_work_state
                for (
                    macro_tile,
                    mma_carrier_state,
                    mma_carrier_result,
                ) in cutlass.for_generate(
                    0,
                    macro_tile_count,
                    1,
                    [
                        sf_work_consumer_state,
                        e_work_consumer_state,
                        ab_wait_work_consumer_state,
                        ab_release_work_consumer_state,
                        acc_work_producer_state,
                    ],
                    # Caller-selected unrolling trades loop overhead for code
                    # size and longer register live ranges.
                    unroll=cutlass.LoopUnroll(count=self.mma_loop_unroll),
                ):
                    (
                        sf_carrier_consumer_state,
                        e_carrier_consumer_state,
                        ab_wait_carrier_consumer_state,
                        ab_release_carrier_consumer_state,
                        acc_carrier_producer_state,
                    ) = mma_carrier_state
                    sf_carrier_pipeline = cute_ext.GenericPipeline(
                        sf_raw_pipeline,
                        self.sf_stages,
                        sf_producer_state,
                        sf_carrier_consumer_state,
                    )
                    e_carrier_pipeline = cute_ext.GenericPipeline(
                        e_raw_pipeline,
                        self.e_stages,
                        e_producer_state,
                        e_carrier_consumer_state,
                    )
                    ab_wait_carrier_pipeline = cute_ext.GenericPipeline(
                        ab_raw_pipeline,
                        self.ab_stages,
                        ab_initial_producer_state,
                        ab_wait_carrier_consumer_state,
                    )
                    ab_release_carrier_pipeline = cute_ext.GenericPipeline(
                        ab_raw_pipeline,
                        self.ab_stages,
                        ab_initial_producer_state,
                        ab_release_carrier_consumer_state,
                    )
                    acc_carrier_pipeline = cute_ext.GenericPipeline(
                        acc_raw_pipeline,
                        self.acc_stages,
                        acc_carrier_producer_state,
                        acc_initial_consumer_state,
                    )
                    # `set(ACCUMULATE, ...)` mutates the MMA atom. Keep the atom
                    # local to this loop body so neither frontend has to merge
                    # its state across nested loop regions.
                    if cutlass.const_expr(self.enable_breuse):
                        carrier_mma_atom_bkeep = cute.make_mma_atom(tiled_mma_bkeep.op)
                        carrier_mma_atom_breuse = cute.make_mma_atom(
                            tiled_mma_breuse.op
                        )
                    else:
                        carrier_mma_atom = cute.make_mma_atom(tiled_mma.op)
                    # A full K = 768 block uses three load stages for four
                    # K = 192 MMA steps. Unrolling keeps the within-stage
                    # offsets static; the release cursor tracks the ring slot.
                    # A offsets below count retained FP4 values after sparse
                    # compression; B offsets count logical K elements. Stage
                    # numbers are relative to the start of this K = 768 block.
                    #
                    #   MMA   wait cursor   A/B offset       release cursor
                    #    0       stage 0      0 / 0             --
                    #    1       stage 1     96 / 192          stage 0
                    #    2       stage 2    192 / 384          stage 1
                    #    3         --       288 / 576          stage 2
                    #
                    # Both cursors therefore advance three times and are
                    # realigned at the next K = 768 block.
                    for mma_idx in cutlass.range_constexpr(
                        1 if single_issue else self.mma_issues_per_group
                    ):
                        _, e_stage = e_carrier_pipeline.get_consumer_stage()
                        _, release_stage = (
                            ab_release_carrier_pipeline.get_consumer_stage()
                        )
                        issue_in_carrier = mma_idx

                        if cutlass.const_expr(mma_idx == 0):
                            current_stage = release_stage
                            if cutlass.const_expr(self.enable_breuse):
                                a_mma_bkeep_ring = a_mma_bkeep_issue_rings[0]
                                a_mma_breuse_ring = a_mma_breuse_issue_rings[0]
                            else:
                                a_mma_ring = a_mma_issue_rings[0]
                            b_mma_ring = b_mma_issue_rings[0]
                        elif cutlass.const_expr(mma_idx == 1):
                            current_stage = release_stage
                            if cutlass.const_expr(self.enable_breuse):
                                a_mma_bkeep_ring = a_mma_bkeep_issue_rings[1]
                                a_mma_breuse_ring = a_mma_breuse_issue_rings[1]
                            else:
                                a_mma_ring = a_mma_issue_rings[1]
                            b_mma_ring = b_mma_issue_rings[1]
                        elif cutlass.const_expr(mma_idx == 2):
                            current_stage = release_stage
                            if cutlass.const_expr(self.enable_breuse):
                                a_mma_bkeep_ring = a_mma_bkeep_issue_rings[2]
                                a_mma_breuse_ring = a_mma_breuse_issue_rings[2]
                            else:
                                a_mma_ring = a_mma_issue_rings[2]
                            b_mma_ring = b_mma_issue_rings[2]
                        else:
                            current_stage = release_stage
                            if cutlass.const_expr(self.enable_breuse):
                                a_mma_bkeep_ring = a_mma_bkeep_issue_rings[3]
                                a_mma_breuse_ring = a_mma_breuse_issue_rings[3]
                            else:
                                a_mma_ring = a_mma_issue_rings[3]
                            b_mma_ring = b_mma_issue_rings[3]

                        # The K = 768 SF/E stage supplies four K = 192 steps,
                        # organized as two K = 384 halves. Coordinates below
                        # are relative to each half: SF uses (scale offset,
                        # K = 128 block); E uses K = 128 block + byte offset.
                        #
                        #   issue  K start  SF within half  E within half
                        #     0       0          (0, 0)           0+0
                        #     1     192          (2, 1)           1+8
                        #     2     384          (0, 0)           0+0
                        #     3     576          (2, 1)           1+8
                        #
                        # B reuse overwrites the K = 384 SF window at issue 2;
                        # without reuse, all K = 768 scales are copied at issue 0.
                        # SF offset 2 and E byte offset 8 both denote 64 K elements.
                        if cutlass.const_expr(not self.enable_breuse):
                            if cutlass.const_expr(issue_in_carrier == 0):
                                _, sf_stage = (
                                    sf_carrier_pipeline.consumer_wait_and_get_stage()
                                )
                                cute_ext.partition_and_copy(
                                    sfa_copy_slice,
                                    cute.filter_zeros(
                                        s_sfa[None, None, None, sf_stage]
                                    ),
                                    t_sfa_compact,
                                )
                                cute_ext.partition_and_copy(
                                    sfb_copy_slice,
                                    cute.filter_zeros(
                                        s_sfb[None, None, None, sf_stage]
                                    ),
                                    t_sfb_compact,
                                )
                        elif cutlass.const_expr(
                            issue_in_carrier == 0 or issue_in_carrier == 2
                        ):
                            if cutlass.const_expr(issue_in_carrier == 0):
                                _, sf_stage = (
                                    sf_carrier_pipeline.consumer_wait_and_get_stage()
                                )
                            else:
                                _, sf_stage = sf_carrier_pipeline.get_consumer_stage()
                            if cutlass.const_expr(issue_in_carrier == 0):
                                sf_source_k_block = 0
                            else:
                                sf_source_k_block = 3
                            sfa_source_begin = s_sfa[
                                None,
                                None,
                                sf_source_k_block,
                                sf_stage,
                            ]
                            sfa_copy_source = cute.make_tensor(
                                sfa_source_begin.iterator,
                                sfa_tmem_stage_layout,
                            )
                            sfb_source_begin = s_sfb[
                                None,
                                None,
                                sf_source_k_block,
                                sf_stage,
                            ]
                            sfb_copy_source = cute.make_tensor(
                                sfb_source_begin.iterator,
                                sfb_tmem_stage_layout,
                            )
                            cute_ext.partition_and_copy(
                                sfa_copy_slice,
                                cute.filter_zeros(sfa_copy_source),
                                t_sfa_compact,
                            )
                            cute_ext.partition_and_copy(
                                sfb_copy_slice,
                                cute.filter_zeros(sfb_copy_source),
                                t_sfb_compact,
                            )
                        # Copy E in K = 384 halves at issues 0 and 2. Doubled-M
                        # N = 256 instead uses a rolling K = 256 window covering
                        # K = 128 blocks 0:2, 1:3, 3:5 and 4:6. Keep each copy
                        # adjacent to its MMA use so later copies do not
                        # overwrite live metadata.
                        if cutlass.const_expr(
                            self.enable_e_tmem_reuse
                            or issue_in_carrier == 0
                            or issue_in_carrier == 2
                        ):
                            if cutlass.const_expr(issue_in_carrier == 0):
                                e_carrier_pipeline.consumer_wait()
                            e_stage_compact = cute.filter_zeros(
                                cute.recast_tensor(
                                    s_e[None, None, None, e_stage],
                                    e_storage_dtype,
                                )
                            )
                            e_stage_km = cute.make_tensor(
                                e_stage_compact.iterator,
                                cute.make_layout(
                                    shape=(
                                        e_stage_compact.shape[0],
                                        e_stage_compact.shape[2],
                                        e_stage_compact.shape[1],
                                    ),
                                    stride=(
                                        e_stage_compact.stride[0],
                                        e_stage_compact.stride[2],
                                        e_stage_compact.stride[1],
                                    ),
                                ),
                            )
                            if cutlass.const_expr(self.enable_e_tmem_reuse):
                                if cutlass.const_expr(issue_in_carrier == 0):
                                    e_source_k_block = 0
                                elif cutlass.const_expr(issue_in_carrier == 1):
                                    e_source_k_block = 1
                                elif cutlass.const_expr(issue_in_carrier == 2):
                                    e_source_k_block = 3
                                else:
                                    e_source_k_block = 4
                                e_source_begin = e_stage_km[
                                    None, e_source_k_block, None
                                ]
                                e_source_window = cute.make_tensor(
                                    e_source_begin.iterator,
                                    cute.make_layout(
                                        shape=(
                                            e_stage_km.shape[0],
                                            2,
                                            e_stage_km.shape[2],
                                        ),
                                        stride=(
                                            e_stage_km.stride[0],
                                            e_stage_km.stride[1],
                                            e_stage_km.stride[2],
                                        ),
                                    ),
                                )
                                e_copy_source = e_source_window
                                e_copy_destination = t_e_storage
                            elif cutlass.const_expr(self.enable_breuse):
                                # N128 keeps one complete K = 384 E half in TMEM.
                                # Issue 2 replaces half 0 with blocks 3:6 after
                                # the issue-1 MMA pair has consumed it.
                                e_source_k_block = 0 if issue_in_carrier == 0 else 3
                                e_source_begin = e_stage_km[
                                    None, e_source_k_block, None
                                ]
                                e_copy_source = cute.make_tensor(
                                    e_source_begin.iterator,
                                    cute.make_layout(
                                        shape=(
                                            e_stage_km.shape[0],
                                            3,
                                            e_stage_km.shape[2],
                                        ),
                                        stride=(
                                            e_stage_km.stride[0],
                                            e_stage_km.stride[1],
                                            e_stage_km.stride[2],
                                        ),
                                    ),
                                )
                                e_copy_destination = t_e_storage
                            else:
                                e_src_pairs = cute.zipped_divide(
                                    e_stage_km,
                                    (e_stage_km.shape[0], 3, e_stage_km.shape[2]),
                                )
                                e_dst_pairs = cute.zipped_divide(
                                    t_e_storage,
                                    (
                                        t_e_storage.shape[0],
                                        3,
                                        t_e_storage.shape[2],
                                    ),
                                )
                                if cutlass.const_expr(issue_in_carrier == 0):
                                    e_pair_idx = 0
                                else:
                                    e_pair_idx = 1
                                e_copy_source = e_src_pairs[
                                    (
                                        None,
                                        ((None, None), e_pair_idx, None),
                                    )
                                ]
                                e_copy_destination = e_dst_pairs[
                                    (
                                        None,
                                        ((None, None), e_pair_idx, None),
                                    )
                                ]
                            cute_ext.partition_and_copy(
                                tiled_e_copy.get_slice(cute.Int32(0)),
                                e_copy_source,
                                e_copy_destination,
                            )
                            # A no-reuse carrier copies all SF at issue 0. B
                            # reuse retains the same K = 768 SMEM stage until its
                            # second K = 384 SF half is captured at issue 2.
                            if cutlass.const_expr(
                                (not self.enable_breuse and issue_in_carrier == 0)
                                or (self.enable_breuse and issue_in_carrier == 2)
                            ):
                                sf_carrier_pipeline.consumer_release_and_advance(
                                    elect_one_sync=True
                                )
                            # Issue the last E S2T copy before releasing its
                            # SMEM stage: issue 3 for the rolling window, or
                            # issue 2 otherwise.
                            if cutlass.const_expr(
                                (self.enable_e_tmem_reuse and issue_in_carrier == 3)
                                or (
                                    not self.enable_e_tmem_reuse
                                    and issue_in_carrier == 2
                                )
                            ):
                                e_carrier_pipeline.consumer_release_and_advance(
                                    elect_one_sync=True
                                )

                        if cutlass.const_expr(mma_idx < 3):
                            # The MMA leader waits for A/B only after issuing
                            # the independent scale-factor and metadata copies.
                            ab_wait_carrier_pipeline.consumer_wait()
                            ab_wait_carrier_pipeline.consumer_state = (
                                ab_wait_carrier_pipeline.increment_state(
                                    ab_wait_carrier_pipeline.consumer_state,
                                )
                            )

                        if cutlass.const_expr(issue_in_carrier == 0):
                            t_sfa_issue_bkeep = t_sfa_mma[None, 0, 0]
                            if cutlass.const_expr(self.enable_breuse):
                                t_sfa_issue_breuse = t_sfa_mma[None, 1, 0]
                            t_sfb_issue = t_sfb_mma[None, 0, 0]
                            t_e_issue_storage_bkeep = t_e_mma[None, 0, 0]
                            if cutlass.const_expr(self.enable_breuse):
                                t_e_issue_storage_breuse = t_e_mma[None, 0, 1]
                        elif cutlass.const_expr(issue_in_carrier == 1):
                            t_sfa_issue_bkeep = t_sfa_mma[None, 0, (2, 1)]
                            if cutlass.const_expr(self.enable_breuse):
                                t_sfa_issue_breuse = t_sfa_mma[None, 1, (2, 1)]
                            t_sfb_issue = t_sfb_mma[None, 0, (2, 1)]
                            if cutlass.const_expr(self.enable_e_tmem_reuse):
                                t_e_issue_storage_bkeep = t_e_mma[(None, 8), 0, 0]
                            else:
                                t_e_issue_storage_bkeep = t_e_mma[(None, 8), 1, 0]
                            if cutlass.const_expr(self.enable_breuse):
                                if cutlass.const_expr(self.enable_e_tmem_reuse):
                                    t_e_issue_storage_breuse = t_e_mma[(None, 8), 0, 1]
                                else:
                                    t_e_issue_storage_breuse = t_e_mma[(None, 8), 1, 1]
                        elif cutlass.const_expr(issue_in_carrier == 2):
                            if cutlass.const_expr(self.enable_breuse):
                                t_e_issue_storage_bkeep = t_e_mma[None, 0, 0]
                                t_e_issue_storage_breuse = t_e_mma[None, 0, 1]
                                t_sfa_issue_bkeep = t_sfa_mma[None, 0, 0]
                                t_sfa_issue_breuse = t_sfa_mma[None, 1, 0]
                                t_sfb_issue = t_sfb_mma[None, 0, 0]
                            else:
                                t_e_issue_storage_bkeep = t_e_mma[None, 3, 0]
                                t_sfa_issue_bkeep = t_sfa_mma[None, 0, (0, 3)]
                                t_sfb_issue = t_sfb_mma[None, 0, (0, 3)]
                        else:
                            if cutlass.const_expr(self.enable_breuse):
                                t_sfa_issue_bkeep = t_sfa_mma[None, 0, (2, 1)]
                                t_sfa_issue_breuse = t_sfa_mma[None, 1, (2, 1)]
                                t_sfb_issue = t_sfb_mma[None, 0, (2, 1)]
                                if cutlass.const_expr(self.enable_e_tmem_reuse):
                                    e_issue_k_block = 0
                                else:
                                    e_issue_k_block = 1
                                t_e_issue_storage_bkeep = t_e_mma[
                                    (None, 8), e_issue_k_block, 0
                                ]
                                t_e_issue_storage_breuse = t_e_mma[
                                    (None, 8), e_issue_k_block, 1
                                ]
                            else:
                                t_sfa_issue_bkeep = t_sfa_mma[None, 0, (2, 4)]
                                t_sfb_issue = t_sfb_mma[None, 0, (2, 4)]
                                t_e_issue_storage_bkeep = t_e_mma[(None, 8), 4, 0]

                        t_e_issue_bkeep = cute.make_tensor(
                            t_e_issue_storage_bkeep.iterator,
                            e_mma_issue_layout,
                        )
                        if cutlass.const_expr(self.enable_breuse):
                            t_e_issue_breuse = cute.make_tensor(
                                t_e_issue_storage_breuse.iterator,
                                e_mma_issue_layout,
                            )

                        # A and B retain their 64-byte and 128-byte rows in the
                        # circular rings. Static offsets select a 16-byte-aligned
                        # start for each MMA; the compiler derives current/next
                        # descriptors and wraparound without repacking the data.
                        # The stage stride also preserves 16-byte alignment.
                        if cutlass.const_expr(self.enable_breuse):
                            a_mma_bkeep = a_mma_bkeep_ring[
                                None, None, None, current_stage
                            ]
                            a_mma_breuse = a_mma_breuse_ring[
                                None, None, None, current_stage
                            ]
                        else:
                            a_mma = a_mma_ring[None, None, None, current_stage]
                        b_mma = b_mma_ring[None, None, None, current_stage]

                        # Complete M/K tiles need no MMA tail checks. Otherwise,
                        # the first K = 192 step in each block is always valid:
                        # 4 * macro_tile < ceil_div(K, 192). Only later steps
                        # may need a runtime bounds check.
                        logical_issue = macro_tile * self.mma_issues_per_group + mma_idx
                        if logical_issue == 0:
                            acc_carrier_pipeline.producer_acquire_and_get_stage()
                        if cutlass.const_expr(self.enable_breuse):
                            carrier_mma_atom_bkeep.set(
                                tcgen05.Field.ACCUMULATE, logical_issue != 0
                            )
                            carrier_mma_atom_breuse.set(
                                tcgen05.Field.ACCUMULATE, logical_issue != 0
                            )
                            t_acc_issue_bkeep = cute.append_ones(
                                t_acc[None, 0, 0, 0], up_to_rank=3
                            )
                            t_acc_issue_breuse = cute.append_ones(
                                t_acc[None, 1, 0, 0], up_to_rank=3
                            )
                            # Keep the collector pair adjacent: both MMAs share
                            # the exact B/SFB descriptor, while A/SFA/E/C select
                            # the two M halves of the doubled per-CTA tile.
                            # Apply the selected tail policy; every ring still drains.
                            if (
                                cutlass.const_expr(
                                    not self.predicate_mma_tail
                                    or not predicate_e_load
                                    or mma_idx == 0
                                )
                                or logical_issue < k_tile_count
                            ):
                                cute_ext.dot_block_scaled_sparse(
                                    carrier_mma_atom_bkeep,
                                    a_mma_bkeep,
                                    t_sfa_issue_bkeep,
                                    t_e_issue_bkeep,
                                    b_mma,
                                    t_sfb_issue,
                                    t_acc_issue_bkeep,
                                )
                                cute_ext.dot_block_scaled_sparse(
                                    carrier_mma_atom_breuse,
                                    a_mma_breuse,
                                    t_sfa_issue_breuse,
                                    t_e_issue_breuse,
                                    b_mma,
                                    t_sfb_issue,
                                    t_acc_issue_breuse,
                                )
                        else:
                            carrier_mma_atom.set(
                                tcgen05.Field.ACCUMULATE, logical_issue != 0
                            )
                            t_acc_issue = cute.append_ones(
                                t_acc[None, 0, 0, 0], up_to_rank=3
                            )
                            # Apply the selected tail policy; every ring still drains.
                            if (
                                cutlass.const_expr(
                                    not self.predicate_mma_tail
                                    or not predicate_e_load
                                    or mma_idx == 0
                                )
                                or logical_issue < k_tile_count
                            ):
                                cute_ext.dot_block_scaled_sparse(
                                    carrier_mma_atom,
                                    a_mma,
                                    t_sfa_issue_bkeep,
                                    t_e_issue_bkeep,
                                    b_mma,
                                    t_sfb_issue,
                                    t_acc_issue,
                                )

                        # MMA1 is the final reader of stage 0, MMA2 of stage 1,
                        # and MMA3 of stage 2. Separate wait/release cursors let
                        # the next-stage wait run ahead without freeing a stage
                        # that still has readers.
                        if cutlass.const_expr(mma_idx > 0):
                            ab_release_carrier_pipeline.consumer_release_and_advance(
                                elect_one_sync=True,
                            )

                        # The single-step entry has no later reader of its AB
                        # or E stage. With B reuse, also release SF here because
                        # this entry never reaches issue 2.
                        if cutlass.const_expr(single_issue):
                            if cutlass.const_expr(self.enable_breuse):
                                sf_carrier_pipeline.consumer_release_and_advance(
                                    elect_one_sync=True
                                )
                            e_carrier_pipeline.consumer_release_and_advance(
                                elect_one_sync=True
                            )
                            ab_release_carrier_pipeline.consumer_release_and_advance(
                                elect_one_sync=True
                            )

                    cutlass.yield_out(
                        [
                            sf_carrier_pipeline.consumer_state,
                            e_carrier_pipeline.consumer_state,
                            ab_wait_carrier_pipeline.consumer_state,
                            ab_release_carrier_pipeline.consumer_state,
                            acc_carrier_pipeline.producer_state,
                        ]
                    )

                (
                    sf_work_consumer_state,
                    e_work_consumer_state,
                    ab_wait_work_consumer_state,
                    ab_release_work_consumer_state,
                    acc_work_producer_state,
                ) = mma_carrier_result

                # Padded steps retain their waits/releases even when their MMA
                # is skipped; the single-step entry releases only one AB stage.
                # Signal ACC readiness after all issued MMAs complete.
                acc_work_pipeline = cute_ext.GenericPipeline(
                    acc_raw_pipeline,
                    self.acc_stages,
                    acc_work_producer_state,
                    acc_initial_consumer_state,
                )
                acc_work_pipeline.producer_commit_and_advance(elect_one_sync=True)
                cutlass.yield_out(
                    [
                        sf_work_consumer_state,
                        e_work_consumer_state,
                        ab_wait_work_consumer_state,
                        ab_release_work_consumer_state,
                        acc_work_pipeline.producer_state,
                    ]
                )

            # Wait for every epilogue warp to finish reading the final
            # accumulator tile before reuse or deallocation. Only the MMA
            # leader performs this producer tail; ACC is the last carried
            # pipeline state, after SF, E, AB wait and AB release.
            cute_ext.pipeline_tail(acc_raw_pipeline, mma_work_result[-1])

        elif warp_idx < self.EPILOGUE_WARP_COUNT:
            use_tma_epilogue = self.use_tma_store
            if cutlass.const_expr(self.enable_breuse):
                # Fold the outer MMA_M mode into the physical M tile so the
                # epilogue drains both collector-pair accumulator halves.
                t_acc_epilogue = transform_partitioned_tensor_layout(t_acc)
                t_acc_output = t_acc_epilogue[None, None, 0]
            else:
                t_acc_output = t_acc[((None, None), 0, 0, 0)]
            epilogue_work_tile = tile_sched._get_current_work_for_linear_idx(
                initial_work_linear_idx
            )
            initial_epilogue_coord = epilogue_work_tile.tile_idx
            for (
                work_linear_idx,
                epilogue_work_state,
                epilogue_work_result,
            ) in cutlass.for_generate(
                initial_work_linear_idx,
                problem_cluster_tile_count,
                cutlass.Int32(persistent_cluster_count),
                [
                    acc_initial_consumer_state,
                    initial_epilogue_coord[0],
                    initial_epilogue_coord[1],
                    initial_epilogue_coord[2],
                ],
            ):
                (
                    epilogue_acc_consumer_state,
                    coord_m,
                    coord_n,
                    coord_l,
                ) = epilogue_work_state
                epilogue_acc_pipeline = cute_ext.GenericPipeline(
                    acc_raw_pipeline,
                    self.acc_stages,
                    acc_initial_producer_state,
                    epilogue_acc_consumer_state,
                )
                coord = (coord_m, coord_n, coord_l)
                group_output_coord = (
                    cutlass.Int32(
                        cutlass.Uint32(coord[0]) // cute.size(tiled_mma.thr_id.shape)
                    ),
                    coord[1],
                    coord[2],
                )
                cta_output_coord = (
                    group_output_coord[0] * cute.size(tiled_mma.thr_id.shape)
                    + mma_tile_coord_v,
                    group_output_coord[1],
                    group_output_coord[2],
                )
                # Compute the next tile's coordinates before waiting for the
                # current accumulator, allowing this work to overlap MMA.
                next_work_tile = tile_sched._get_current_work_for_linear_idx(
                    work_linear_idx + cutlass.Int32(persistent_cluster_count)
                )
                next_coord = next_work_tile.tile_idx
                # The consumer wait emits the required AFTER_THREAD_SYNC fence
                # before the epilogue reads TMEM.
                epilogue_acc_pipeline.consumer_wait()
                if cutlass.const_expr(use_tma_epilogue):
                    # Four epilogue warps cooperatively publish each SMEM tile;
                    # warp zero alone issues the typed TMA store.
                    epilogue_acc_pipeline = epilogue_tma_store(
                        self.cta_tile_shape_mnk,
                        self.use_2cta_instrs,
                        epilogue_tile,
                        t_acc_output,
                        c,
                        cta_output_coord,
                        tidx,
                        epilogue_acc_pipeline,
                        self.tma_store_stages,
                        self.tma_store_arrival_count,
                        self.TMA_STAGED_REGISTER_BUDGET,
                        static_store_index=self.uses_static_store_index,
                    )
                else:
                    epilogue_acc_pipeline = epilogue_direct_store(
                        self.cta_tile_shape_mnk,
                        self.use_2cta_instrs,
                        epilogue_tile,
                        t_acc_output,
                        c,
                        cta_output_coord,
                        tidx,
                        epilogue_acc_pipeline,
                        predicate_output_store,
                        (
                            # Budget for a full FP32 tile, or narrowed output
                            # plus one FP32 conversion fragment per thread.
                            # The epilogue selects an eligible staging path
                            # within this budget, or streams subtiles.
                            (
                                cute.size(self.cta_tile_shape_mnk[:2])
                                if self.c_dtype == cutlass.Float32
                                else cute.size(epilogue_tile[0])
                                * cute.size(epilogue_tile[1])
                                + cute.size(self.cta_tile_shape_mnk[:2])
                                * self.c_dtype.width
                                // cutlass.Float32.width
                            )
                            // (self.EPILOGUE_WARP_COUNT * self.WARP_SIZE)
                            if self.stages_direct_output and not single_issue
                            else self.DIRECT_STAGED_REGISTER_BUDGET
                        ),
                    )
                cutlass.yield_out(
                    [
                        epilogue_acc_pipeline.consumer_state,
                        next_coord[0],
                        next_coord[1],
                        next_coord[2],
                    ]
                )
            if cutlass.const_expr(use_tma_epilogue):
                # Each output tile returns the store index to zero. Drain
                # outstanding stores after all output tiles have been issued.
                tma_store_pipeline = cute_ext.TMAStorePipeline(
                    stages=self.tma_store_stages,
                    arv_count=self.tma_store_arrival_count,
                    barrier_id=9,
                    tma_warp_id=0,
                    index=cutlass.Int32(0),
                )
                tma_store_pipeline.tail()

        # The AB/SF/E producer tails wait for all readers. The ACC tail waits
        # for the final TMEM reads, and the store tail waits for output copies.
        # These waits allow CTAs to exit without another cluster-wide wait;
        # the compiler handles two-CTA TMEM deallocation synchronization.


def make_kernel(
    mma_tiler_mn: tuple[int, int],
    cluster_shape_mn: tuple[int, int],
    *,
    mma_inst_shape_mn: tuple[int, int] = (
        Sm107BlockScaledSparseGemmKernel.MMA_INSTRUCTION_MNK[:2]
    ),
    c_dtype: type[cutlass.Numeric] = cutlass.Float16,
    use_tma_store: bool,
    stage_caps: PipelineStageCaps,
    smem_capacity: int,
    persistent_cluster_limit: int,
    retain_ab_multicast: bool = False,
    stage_direct_output: bool = False,
    static_store_index: bool = False,
    predicate_mma_tail: bool = True,
    mma_loop_unroll: int = 1,
    min_blocks_per_mp: int = 0,
) -> Sm107BlockScaledSparseGemmKernel:
    """Build one explicitly configured SM107 sparse GEMM schedule.

    ``mma_inst_shape_mn`` (default (256, 256)), ``mma_tiler_mn``, and
    ``cluster_shape_mn`` select the instruction and launch geometry;
    unsupported schedule families fail immediately. ``stage_caps`` supplies
    caller-selected buffer limits, reduced as needed to fit ``smem_capacity``
    using the kernel's allocation order and alignment requirements.
    ``c_dtype`` controls output storage and epilogue geometry (FP16 by default).
    ``use_tma_store`` selects the epilogue, and ``persistent_cluster_limit``
    caps the device-reported cluster capacity. The modeled allocation size is
    exposed as ``pipeline_smem_bytes``; the supplied launch budget includes
    the driver-reserved 1,024 bytes. The remaining keyword arguments select
    the load/epilogue/unroll/occupancy choices documented on the kernel class.
    """

    return Sm107BlockScaledSparseGemmKernel(
        mma_tiler_mn,
        cluster_shape_mn,
        mma_inst_shape_mn=mma_inst_shape_mn,
        c_dtype=c_dtype,
        use_tma_store=use_tma_store,
        stage_caps=stage_caps,
        smem_capacity=smem_capacity,
        persistent_cluster_limit=persistent_cluster_limit,
        retain_ab_multicast=retain_ab_multicast,
        stage_direct_output=stage_direct_output,
        static_store_index=static_store_index,
        predicate_mma_tail=predicate_mma_tail,
        mma_loop_unroll=mma_loop_unroll,
        min_blocks_per_mp=min_blocks_per_mp,
    )


# Preserve the established class spelling for existing callers.
Sm107SparseBlockScaledGemmKernel = Sm107BlockScaledSparseGemmKernel


def _validate_run_configuration(
    mnkl: tuple[int, int, int, int],
    mma_inst_shape: tuple[int, int, int],
    mma_tiler: tuple[int, int, int],
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    sf_dtype: type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    arch: str,
) -> None:
    """Reject unsupported public options before allocation or device setup."""
    for name, shape, rank in (
        ("mnkl", mnkl, 4),
        ("mma_inst_shape", mma_inst_shape, 3),
        ("mma_tiler", mma_tiler, 3),
    ):
        if len(shape) != rank or any(
            type(value) is not int or value <= 0 for value in shape
        ):
            raise ValueError(f"{name} must contain {rank} positive integers")
    Sm107BlockScaledSparseGemmKernel.validate_problem_shape(*mnkl, c_dtype=c_dtype)
    if (
        not Sm107BlockScaledSparseGemmKernel.can_implement(
            mnkl,
            a_dtype=a_dtype,
            b_dtype=b_dtype,
            sfa_dtype=sf_dtype,
            sfb_dtype=sf_dtype,
            c_dtype=c_dtype,
            a_is_k_major=a_major == "k",
            b_is_k_major=b_major == "k",
            c_is_n_major=c_major == "n",
        )
        or acc_dtype != cutlass.Float32
        or type(sf_vec_size) is not int
        or sf_vec_size != 32
    ):
        raise ValueError(
            "Sparse GEMM requires FP4 A/B, E8M0 vector-32 scales, supported floating C, "
            "FP32 accumulation, K-major A/B and N-major C"
        )
    instruction_k = Sm107BlockScaledSparseGemmKernel.MMA_INSTRUCTION_K
    group_k = math.lcm(instruction_k, Sm107BlockScaledSparseGemmKernel.AB_TMA_PHASE_K)
    if mma_inst_shape[2] != instruction_k or mma_tiler[2] != group_k:
        raise ValueError(
            f"Sparse MMA instruction K must be {instruction_k} and tiler K must be {group_k}"
        )
    if arch != Sm107BlockScaledSparseGemmKernel.ARCH:
        raise ValueError("This sparse example supports arch='sm_107' only")


# Host utilities keep the caller's seed deterministic without resetting global
# RNG state. The independent 2:4 decode separates the arithmetic reference from
# physical E packing; valid nonzero 0xEE edge padding exposes unpredicated reads.
# The general sparse factory chooses its own values and selectors and resets
# the Torch RNG. These fixtures require caller-seeded, signed E2M1-exact values
# and explicit nonzero metadata padding; scale factors still use the shared
# scale-factor factory.
_NONZERO_E2M1_VALUES = (0.5, 1.0, 1.5, 2.0, 3.0, -0.5, -1.0, -1.5)


_SPARSE_METADATA = (0x4, 0x8, 0xC, 0x9, 0xD, 0xE)


_SPARSE_POSITIONS = (
    (-1, -1),
    (-1, -1),
    (-1, -1),
    (-1, -1),
    (0, 1),
    (-1, -1),
    (-1, -1),
    (-1, -1),
    (0, 2),
    (1, 2),
    (-1, -1),
    (-1, -1),
    (0, 3),
    (1, 3),
    (2, 3),
    (-1, -1),
)


def _matrix_choices(
    rows: int,
    columns: int,
    batches: int,
    seed: int,
    choices: tuple[int, ...] | tuple[float, ...],
    dtype: torch.dtype,
    device: torch.device,
) -> torch.Tensor:
    """Create deterministic K-major test data without global RNG state."""

    batch = torch.arange(batches, dtype=torch.int32, device=device).reshape(-1, 1, 1)
    row = torch.arange(rows, dtype=torch.int32, device=device).reshape(1, -1, 1)
    column = torch.arange(columns, dtype=torch.int32, device=device).reshape(1, 1, -1)
    choice_table = torch.tensor(choices, dtype=dtype, device=device)
    mixed = (
        batch * 11
        + row * 7
        + column * 3
        + ((row + seed) * (column + 17) % 97) * 5
        + (column * column) % 89
        + seed
    )
    indices = mixed % len(choices)
    return choice_table[indices.to(torch.long)].permute(1, 2, 0)


def create_sparse_operands(
    mnkl: tuple[int, int, int, int], seed: int, device: torch.device
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Create logical operands for a validated ``(M, N, K, L)`` problem.

    Return FP32 compressed A ``(M, K/2, L)``, FP32 B ``(N, K, L)``, and
    Uint8 selector nibbles ``(M, K/4, L)`` on ``device``. Values are exactly
    representable in E2M1; ``seed`` deterministically chooses values and valid
    2:4 selector pairs without changing global RNG state. The caller validates
    positive dimensions and K alignment before constructing these tensors.
    """

    m, n, k, l = mnkl
    return (
        _matrix_choices(
            m,
            k // 2,
            l,
            seed,
            _NONZERO_E2M1_VALUES,
            torch.float32,
            device,
        ),
        _matrix_choices(
            n,
            k,
            l,
            seed + 1,
            _NONZERO_E2M1_VALUES,
            torch.float32,
            device,
        ),
        _matrix_choices(
            m,
            k // 4,
            l,
            seed + 2,
            _SPARSE_METADATA,
            torch.uint8,
            device,
        ),
    )


def decode_sparse_4_2(
    compressed_values: torch.Tensor, selector_nibbles: torch.Tensor
) -> torch.Tensor:
    """Decode compressed A and selector nibbles into FP32 ``(M, K, L)``.

    Inputs have shapes ``(M, K/2, L)`` and ``(M, K/4, L)`` on the same device.
    Each nibble selects two distinct positions in a group of four. Invalid
    encodings raise ``ValueError``; output positions not selected remain zero.
    This is an independent arithmetic reference, not the device's E layout.
    """

    m, compressed_k, batches = compressed_values.shape
    groups = compressed_k // 2
    positions = torch.tensor(
        _SPARSE_POSITIONS,
        dtype=torch.long,
        device=selector_nibbles.device,
    )[selector_nibbles.to(torch.long)]
    if bool((positions < 0).any().item()):
        raise ValueError("sparse selector contains an invalid 2:4 encoding")
    values = compressed_values.reshape(
        m,
        groups,
        2,
        batches,
    )
    expanded = torch.zeros(
        (m, groups, 4, batches),
        dtype=torch.float32,
        device=compressed_values.device,
    )
    expanded.scatter_(2, positions.permute(0, 1, 3, 2), values)
    return expanded.reshape(m, groups * 4, batches)


def pack_e_storage(selector_nibbles: torch.Tensor) -> torch.Tensor:
    """Pack Uint8 selectors ``(M, K/4, L)`` into Rubin's raw E layout.

    The caller supplies valid nibbles and K divisible by eight. Return Uint8
    storage ``(ceil(M/128)*128, ceil(K/128)*16, L)`` with contiguous batches
    and the within-batch E permutation expected by the sparse TMA descriptor.
    Logical M/K edges use valid nonzero ``0xEE`` padding, so partial tiles keep
    the same physical carrier contract as full tiles.
    """

    m, groups, batches = selector_nibbles.shape
    packed = (selector_nibbles[:, 0::2, :] | (selector_nibbles[:, 1::2, :] << 4)).to(
        torch.uint8
    )
    bytes_per_row = groups // 2
    # ``make_sparse_gmem_layout_e`` rounds both logical M and K to 128 before
    # forming the per-batch stride. Match that allocation contract so partial
    # M/K shapes do not make the descriptor address beyond the E buffer. Fill
    # padding with nonzero valid selector nibbles so an unpredicated edge read
    # changes the result instead of being hidden by zero padding.
    padded_m = math.ceil(m / 128) * 128
    padded_k = math.ceil((groups * 4) / 128) * 128
    padded_bytes_per_row = padded_k // 8
    base = torch.full(
        (batches, padded_m, padded_bytes_per_row),
        0xEE,
        dtype=torch.uint8,
        device=packed.device,
    )
    storage = base.permute(1, 2, 0)
    row = torch.arange(m, dtype=torch.long, device=packed.device).reshape(-1, 1)
    byte = torch.arange(
        bytes_per_row,
        dtype=torch.long,
        device=packed.device,
    ).reshape(1, -1)
    destination = row * 16 + (byte % 16) + (byte // 16) * padded_m * 16
    for batch in range(batches):
        storage[:, :, batch].reshape(-1)[destination.reshape(-1)] = packed[
            :, :, batch
        ].reshape(-1)
    return storage


def run(
    mnkl: tuple[int, int, int, int] = (256, 256, 256, 1),
    mma_inst_shape: tuple[int, int, int] = (256, 256, 192),
    mma_tiler: tuple[int, int, int] = (256, 256, 768),
    cluster_shape_mn: tuple[int, int] = (2, 1),
    a_dtype: type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    b_dtype: type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: type[cutlass.Numeric] = cutlass.Float8E8M0FNU,
    sf_vec_size: int = 32,
    c_dtype: type[cutlass.Numeric] = cutlass.Float16,
    acc_dtype: type[cutlass.Numeric] = cutlass.Float32,
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    *,
    use_tma_store: bool = False,
    num_load_stages_override: int | None = None,
    num_sf_stages_override: int | None = None,
    num_e_stages_override: int | None = None,
    num_store_stages_override: int | None = None,
    stage_caps: PipelineStageCaps | None = None,
    smem_capacity: int | None = None,
    persistent_cluster_limit: int | None = None,
    ptxas_options: str = "",
    retain_ab_multicast: bool = False,
    stage_direct_output: bool = False,
    static_store_index: bool = False,
    predicate_mma_tail: bool = True,
    mma_loop_unroll: int = 1,
    min_blocks_per_mp: int = 0,
    arch: str = "sm_107",
    seed: int = 73,
) -> torch.Tensor:
    """Run sparse block-scaled GEMM and check an independent FP32 reference.

    The caller selects the schedule and compiler options. Omitted stage caps
    use fixed limits (AB/SF/E = 12/8/8, C = 2 for TMA or 0 for direct stores),
    reduced to fit shared memory. These limits do not depend on problem size.
    K <= 192 uses the single-issue kernel specialization.
    ACC has one ownership stage and intentionally has no override. The compiler
    target follows the normal CuTe DSL environment.

    :param mnkl: Logical M, N, K and batch extent.
    :type mnkl: tuple[int, int, int, int]
    :param mma_inst_shape: MMA instruction M/N/K; sparse K is 192.
    :type mma_inst_shape: tuple[int, int, int]
    :param mma_tiler: Output-tile M/N and mainloop block K; K must be 768.
    :type mma_tiler: tuple[int, int, int]
    :param cluster_shape_mn: Fixed launch cluster; no runtime fallback geometry.
    :type cluster_shape_mn: tuple[int, int]
    :param a_dtype: Compressed A dtype; FP4 E2M1.
    :type a_dtype: type[cutlass.Numeric]
    :param b_dtype: Dense B dtype; FP4 E2M1.
    :type b_dtype: type[cutlass.Numeric]
    :param sf_dtype: Scale dtype; E8M0.
    :type sf_dtype: type[cutlass.Numeric]
    :param sf_vec_size: Scale vector length; 32.
    :type sf_vec_size: int
    :param c_dtype: Output dtype; FP32, FP16, BF16, FP8 E4M3 or FP8 E5M2.
    :type c_dtype: type[cutlass.Numeric]
    :param acc_dtype: Accumulator dtype; FP32.
    :type acc_dtype: type[cutlass.Numeric]
    :param a_major: A leading mode; k.
    :type a_major: str
    :param b_major: B leading mode; k.
    :type b_major: str
    :param c_major: Output leading mode; n.
    :type c_major: str
    :param use_tma_store: Copy output through shared memory with TMA, not R2G.
    :type use_tma_store: bool
    :param num_load_stages_override: Optional A/B stage cap.
    :type num_load_stages_override: int | None
    :param num_sf_stages_override: Optional scale-factor stage cap.
    :type num_sf_stages_override: int | None
    :param num_e_stages_override: Optional metadata stage cap.
    :type num_e_stages_override: int | None
    :param num_store_stages_override: Optional output stage cap.
    :type num_store_stages_override: int | None
    :param stage_caps: Combined caps, mutually exclusive with individual overrides.
    :type stage_caps: PipelineStageCaps | None
    :param smem_capacity: Launch budget in bytes; defaults to usable hardware capacity.
    :type smem_capacity: int | None
    :param persistent_cluster_limit: Resident-cluster cap; defaults to device capacity.
    :type persistent_cluster_limit: int | None
    :param ptxas_options: Explicit PTXAS flags; empty string uses compiler defaults.
    :type ptxas_options: str
    :param retain_ab_multicast: Share full-K A/B loads across MMA groups.
    :type retain_ab_multicast: bool
    :param stage_direct_output: Request whole-tile register staging for direct stores
        when the budget and epilogue permit it; K <= 192 still streams subtiles.
    :type stage_direct_output: bool
    :param static_store_index: Use constant SMEM indices in TMA output stores.
    :type static_store_index: bool
    :param predicate_mma_tail: Skip MMA slots outside the logical K extent.
    :type predicate_mma_tail: bool
    :param mma_loop_unroll: MMA loop unroll factor; 1, 2 or 4.
    :type mma_loop_unroll: int
    :param min_blocks_per_mp: Compiler occupancy hint; zero leaves it unspecified.
    :type min_blocks_per_mp: int
    :param arch: Resource architecture; sm_107.
    :type arch: str
    :param seed: Deterministic operand seed.
    :type seed: int
    :return: Validated output in c_dtype with shape (M, N, L).
    :rtype: torch.Tensor
    """
    _validate_run_configuration(
        mnkl,
        mma_inst_shape,
        mma_tiler,
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        arch,
    )
    if type(seed) is not int:
        raise ValueError("seed must be an integer")
    ring_overrides = (
        num_load_stages_override,
        num_sf_stages_override,
        num_e_stages_override,
        num_store_stages_override,
    )
    if stage_caps is not None and any(value is not None for value in ring_overrides):
        raise ValueError(
            "stage_caps and individual stage overrides are mutually exclusive"
        )
    if stage_caps is None:
        # Fixed caller-facing defaults, independent of M/N/K and dtype. The
        # constructor fits their physical allocations to the SMEM budget.
        defaults = (12, 8, 8, 2 if use_tma_store else 0)
        stage_caps = PipelineStageCaps(
            *(
                default if value is None else value
                for default, value in zip(defaults, ring_overrides)
            )
        )
    if smem_capacity is None:
        smem_capacity = (
            cutlass.memory.get_smem_capacity_in_bytes(arch)
            - Sm107BlockScaledSparseGemmKernel.SMEM_RESERVED_BYTES
        )
    if not isinstance(ptxas_options, str):
        raise ValueError("ptxas_options must be a string")
    options = (cute.PtxasOptions(ptxas_options),) if ptxas_options else ()
    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example")
    m, n, k, l = mnkl
    device = torch.device("cuda")
    # Materialize operands before the occupancy query so standalone execution
    # has a current CUDA context, just as the dense example's tensor setup does.
    a_values, b_values, selectors = create_sparse_operands(mnkl, seed, device)
    max_active_clusters = cutlass.utils.HardwareInfo().get_max_active_clusters(
        math.prod(cluster_shape_mn)
    )
    kernel = make_kernel(
        mma_inst_shape_mn=mma_inst_shape[:2],
        mma_tiler_mn=mma_tiler[:2],
        cluster_shape_mn=cluster_shape_mn,
        c_dtype=c_dtype,
        use_tma_store=use_tma_store,
        stage_caps=stage_caps,
        smem_capacity=smem_capacity,
        persistent_cluster_limit=(
            max_active_clusters
            if persistent_cluster_limit is None
            else persistent_cluster_limit
        ),
        retain_ab_multicast=retain_ab_multicast,
        stage_direct_output=stage_direct_output,
        static_store_index=static_store_index,
        predicate_mma_tail=predicate_mma_tail,
        mma_loop_unroll=mma_loop_unroll,
        min_blocks_per_mp=min_blocks_per_mp,
    )
    cli.print_problem_config(
        "CuTe DSL Rubin Sparse Block-Scaled GEMM",
        mnkl,
        lines=[
            f"MMA instruction: {mma_inst_shape}, tiler: {mma_tiler}",
            f"Cluster: {cluster_shape_mn}, store: {'TMA' if use_tma_store else 'direct'}",
            f"Pipeline stages AB/SF/E/C: {kernel.ab_stages}/{kernel.sf_stages}/"
            f"{kernel.e_stages}/{kernel.tma_store_stages}",
        ],
        majors={"A": "k-major", "B": "k-major", "C": "n-major"},
    )
    with torch.random.fork_rng(devices=[]):
        torch.random.set_rng_state(torch.Generator().manual_seed(seed + 3).get_state())
        sfa_ref, sfa, sfa_storage = create_scale_factor_tensor(
            m, k, l, sf_vec_size, sf_dtype
        )
        torch.random.set_rng_state(torch.Generator().manual_seed(seed + 4).get_state())
        sfb_ref, sfb, sfb_storage = create_scale_factor_tensor(
            n, k, l, sf_vec_size, sf_dtype
        )
    a, a_storage = cutlass_torch.cute_tensor_like(
        a_values,
        a_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    b, b_storage = cutlass_torch.cute_tensor_like(
        b_values,
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    e_storage = pack_e_storage(selectors)
    e = from_dlpack(e_storage, assumed_align=16).mark_layout_dynamic(leading_dim=1)
    e.element_type = cutlass.Uint8
    c_storage = torch.full(
        (l, m, n), float("nan"), dtype=cutlass_torch.dtype(c_dtype), device=device
    ).permute(1, 2, 0)
    # Torch does not export FP8 through DLPack on all supported versions.
    # The byte view preserves the actual FP8 storage and its element strides.
    c_dlpack = c_storage.view(torch.uint8) if c_dtype.width == 8 else c_storage
    c = from_dlpack(c_dlpack, assumed_align=32).mark_layout_dynamic(leading_dim=1)
    c.element_type = c_dtype
    # These annotations preserve the established dynamic tensor ABI. In FP4,
    # compressed A stores half the logical K extent; two values share one byte.
    for tensor, divisibility in ((a, 16), (b, 32), (c, 256 // c_dtype.width)):
        tensor.mark_compact_shape_dynamic(
            mode=1,
            stride_order=(2, 0, 1),
            divisibility=divisibility,
        )
    # Retain every converted backing allocation through execution and checking.
    storage_keepalive = (a_storage, b_storage, sfa_storage, sfb_storage)
    stream = cutlass_torch.current_stream()
    compiled = cute.compile[options](
        kernel, a, b, sfa, sfb, e, c, max_active_clusters, stream
    )
    compiled(a, b, sfa, sfb, e, c, stream)
    torch.cuda.synchronize()

    sparse_a = decode_sparse_4_2(a_values, selectors)
    scale_a, scale_b = sfa_ref.to(device=device), sfb_ref.to(device=device)
    previous_tf32 = torch.backends.cuda.matmul.allow_tf32
    torch.backends.cuda.matmul.allow_tf32 = False
    try:
        expected = torch.stack(
            [
                (sparse_a[:, :, batch] * scale_a[:, :, batch])
                @ (b_values[:, :, batch] * scale_b[:, :, batch]).transpose(0, 1)
                for batch in range(l)
            ],
            dim=2,
        )
    finally:
        torch.backends.cuda.matmul.allow_tf32 = previous_tf32
    if not bool(torch.isfinite(c_storage.float()).all().item()):
        raise AssertionError("Sparse GEMM produced nonfinite output")
    # FP8 conversion saturates finite values; compare against the independent
    # FP32 oracle with its format rounding bound, clamping only overflow.
    rtol = 0.01
    if c_dtype.width == 8:
        limits = torch.finfo(c_storage.dtype)
        expected = expected.clamp(limits.min, limits.max)
        rtol = 0.0625 if c_dtype == cutlass.Float8E4M3FN else 0.125
    torch.testing.assert_close(c_storage.float(), expected, atol=0.5, rtol=rtol)
    print("PASS")
    return c_storage


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse the dense-style CLI while keeping sparse-specific ring controls."""
    parser = argparse.ArgumentParser(
        description=(
            "SM107 sparse block-scaled GEMM (CuTe DSL); "
            "scale factors use E8M0 with vector length 32"
        )
    )
    cli.add_mnkl_arg(parser, default=(256, 256, 256, 1), strict_length=True)
    parser.add_argument(
        "--mma_inst_shape",
        type=cli.comma_separated_ints_of(3),
        default=(256, 256, 192),
        help="MMA instruction M,N,K; K must be 192",
    )
    parser.add_argument(
        "--mma_tiler",
        type=cli.comma_separated_ints_of(3),
        default=(256, 256, 768),
        help=(
            "Output tile M,N and mainloop block K; K must be 768; "
            "doubled M enables B reuse"
        ),
    )
    cli.add_cluster_shape_arg(parser, default=(2, 1), strict_length=True)
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    cli.add_dtype_args(parser, c=cutlass.Float16, acc=cutlass.Float32)
    cli.add_major_args(parser, a=("k",), b=("k",), c=("n",))
    parser.add_argument(
        "--use_tma_store",
        action="store_true",
        help="Store output through shared memory using TMA",
    )
    # ACC has one ownership stage; changing it requires a different TMEM protocol.
    parser.add_argument(
        "--num_load_stages_override",
        type=int,
        default=None,
        help="Override the A/B load-ring stage cap",
    )
    parser.add_argument(
        "--num_sf_stages_override",
        type=int,
        default=None,
        help="Override the scale-factor stage cap",
    )
    parser.add_argument(
        "--num_e_stages_override",
        type=int,
        default=None,
        help="Override the metadata stage cap",
    )
    parser.add_argument(
        "--num_store_stages_override",
        type=int,
        default=None,
        help="Override the output stage cap",
    )
    parser.add_argument(
        "--smem_capacity", type=int, default=None, help="Caller SMEM budget in bytes"
    )
    parser.add_argument(
        "--persistent_cluster_limit",
        type=int,
        default=None,
        help="Cap resident clusters",
    )
    parser.add_argument(
        "--ptxas_options",
        default="",
        help="Explicit assembler options; empty string selects compiler defaults",
    )
    parser.add_argument(
        "--retain_ab_multicast", action="store_true", help="Share full-K A/B loads"
    )
    parser.add_argument(
        "--stage_direct_output",
        action="store_true",
        help=(
            "Request whole-tile register staging for direct stores where supported; "
            "K <= 192 still streams subtiles"
        ),
    )
    parser.add_argument(
        "--static_store_index",
        action="store_true",
        help="Use constant TMA store indices",
    )
    parser.add_argument(
        "--predicate_mma_tail",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Skip MMA slots outside logical K (disable to execute padded slots)",
    )
    parser.add_argument("--mma_loop_unroll", type=int, choices=(1, 2, 4), default=1)
    parser.add_argument("--min_blocks_per_mp", type=int, default=0)
    parser.add_argument("--arch", default="sm_107", choices=("sm_107",))
    parser.add_argument("--seed", type=int, default=73)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    """Run the standalone example with explicit CLI-to-API argument mapping."""
    args = _parse_args(argv)
    run(
        mnkl=args.mnkl,
        mma_inst_shape=args.mma_inst_shape,
        mma_tiler=args.mma_tiler,
        cluster_shape_mn=args.cluster_shape_mn,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        c_dtype=args.c_dtype,
        acc_dtype=args.acc_dtype,
        a_major=args.a_major,
        b_major=args.b_major,
        c_major=args.c_major,
        use_tma_store=args.use_tma_store,
        num_load_stages_override=args.num_load_stages_override,
        num_sf_stages_override=args.num_sf_stages_override,
        num_e_stages_override=args.num_e_stages_override,
        num_store_stages_override=args.num_store_stages_override,
        smem_capacity=args.smem_capacity,
        persistent_cluster_limit=args.persistent_cluster_limit,
        ptxas_options=args.ptxas_options,
        retain_ab_multicast=args.retain_ab_multicast,
        stage_direct_output=args.stage_direct_output,
        static_store_index=args.static_store_index,
        predicate_mma_tail=args.predicate_mma_tail,
        mma_loop_unroll=args.mma_loop_unroll,
        min_blocks_per_mp=args.min_blocks_per_mp,
        arch=args.arch,
        seed=args.seed,
    )


if __name__ == "__main__":
    main()
