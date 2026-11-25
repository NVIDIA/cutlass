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
Persistent dense GEMM for the Rubin (SM107) architecture with split A/B
operand pipelines and one TMA load warp per operand, using CuTe DSL Extensions.

This is the Rubin persistent dense GEMM (``dense_gemm_persistent.py``) with
its mainloop synchronization restructured. The MMA math, tile scheduling, the
epilogue, the B-reuse path and the mixed FP8 pairs are unchanged, so the two
kernels are functionally equivalent. The differences in this kernel are:

- A and B are staged through separate TMA -> UMMA pipelines. Per k-tile the
  MMA warp waits on both pipelines but releases them independently: the A
  pipeline's MMA is declared ``MmaOperation(kind, MmaOperand.A)``. This uses the
  new tcgen05 commit variant in Rubin that completes once the MMA has read A from
  shared memory, before the accumulator is written. B keeps the regular commit.
- Each TMA producer has its own TMA load warp. The A warp refills A stages as fast as
  the MMAs release them - a single producer warp would issue A and B in program
  order and could not issue the next A load before its B acquire returned.
- The pipelines may have different depths. By default both get the depth a
  shared A+B pipeline would get; ``--mainloop_stages_ab`` pins the two counts.

Data types:

- A and B are independent element types. Any Float8E4M3FN / Float8E5M2 pair is
  legal. The F16/BF16 and TF32 are single-dtype, so they need ``a_dtype == b_dtype``.
- Supported operand types: Float8E4M3FN, Float8E5M2, Float16, BFloat16,
  TFloat32.
- Output D: Float32 / Float16 / BFloat16 / Float8E4M3FN / Float8E5M2 /
  Float4E2M1FN. Narrow (<= 8-bit) D is a plain saturating cast of the accumulator.

NOTE: The B-reuse feature is currently only supported for FP8 inputs, because
only the SM107 FP8 atom exposes the operand-collector ops it needs.

The B-reuse Feature:

  **B-reuse / REST_M > 1 path.** When the per-cluster ``mn_tiler`` is
  larger than the MMA atom shape (``mma_inst_shape_mn``) along M, a single
  cluster tile is covered by REST_M atom calls that share the same B
  operand. Setting ``mn_tiler[0] // mma_inst_shape_mn[0] == 2``
  will trigger the heuristic to enable this path.

The standard epilogue path handles one M atom per call, so with REST_M > 1 an
outer loop iterates over the M atoms with updated indexing: the CTA tile M is
2x larger, we break it into rest_m pieces and perform subtiling + tma store for
each piece. This outer loop can be wrapped into the utility with updated TMEM
layouts carrying the REST_M mode.
"""

import argparse
import os
import sys

import torch
import cuda.bindings.driver as cuda
from typing import Type, Tuple

import cutlass
from cutlass import utils
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
from cutlass import testing
from cutlass.cute.runtime import from_dlpack

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../.."))

from helpers import cli_helper as cli
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)


def _default_mma_inst_k(a_dtype: Type[Numeric], b_dtype: Type[Numeric]) -> int:
    """Default MMA instruction K for the operand dtype family.

    The SM107 FP8 atom takes the instruction K explicitly (32 or 64); the
    F16/BF16 and TF32 atoms have a fixed K derived from the dtype.
    """
    fp8_dtypes = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
    if a_dtype in fp8_dtypes and b_dtype in fp8_dtypes:
        return 64
    if a_dtype in (cutlass.Float16, cutlass.BFloat16):
        return 16
    # TFloat32 / Float32 operands run on the TF32 atom.
    return 8


class PersistentDenseGemmSplitABKernel:
    MAX_STAGES_PER_RING_2SM = 9

    def __init__(
        self,
        mn_tiler: tuple[int, int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        a_major_mode: cute.nvgpu.OperandMajorMode,
        b_major_mode: cute.nvgpu.OperandMajorMode,
        d_layout: cutlass.tensor_utils.LayoutEnum,
        max_active_clusters: int,
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (2, 1),
        fallback_cluster_shape_mn: Tuple[int, int] = None,
        max_active_fallback_clusters: int = None,
        swizzle_size: int = 1,
        raster_along_m: bool = True,
        mma_inst_shape: Tuple[int, int, int] | None = None,
        arch: str = "sm_107",
        mainloop_stages_ab: Tuple[int, int] | None = None,
    ):
        self.mn_tiler = mn_tiler
        # ``mma_dtype`` is (ab_dtype, acc_dtype) when A and B share an element
        # type, or (a_dtype, b_dtype, acc_dtype) for a mixed-input GEMM.
        if len(mma_dtype) == 2:
            ab_dtype, self.acc_dtype = mma_dtype
            self.a_dtype = ab_dtype
            self.b_dtype = ab_dtype
        elif len(mma_dtype) == 3:
            self.a_dtype, self.b_dtype, self.acc_dtype = mma_dtype
        else:
            raise ValueError(
                "mma_dtype must be (ab_dtype, acc_dtype) or "
                f"(a_dtype, b_dtype, acc_dtype), got {mma_dtype}"
            )
        # The instruction K cannot default to the tiler K: the FP8 atom only
        # accepts K in {32, 64}, so derive the default from the operand dtype.
        if mma_inst_shape is None:
            mma_inst_shape = (
                mn_tiler[0],
                mn_tiler[1],
                _default_mma_inst_k(self.a_dtype, self.b_dtype),
            )
        self.mma_inst_shape = mma_inst_shape
        self.tmem_output_dtype = tmem_output_dtype
        self.d_dtype = tmem_output_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.epilogue_op = epilogue_op
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast
        self.a_major_mode_ = a_major_mode
        self.b_major_mode_ = b_major_mode
        self.d_layout_ = d_layout
        self.max_active_clusters = max_active_clusters
        self.enable_breuse = True if mn_tiler[0] // mma_inst_shape[0] == 2 else False
        # A and B stage pipelines are separate; the A pipeline is released by the
        # Rubin smem-A-read commit, so its stages recycle earlier. The depths
        # come from `_split_mainloop_stages` unless pinned here.
        if mainloop_stages_ab is not None:
            if len(mainloop_stages_ab) != 2 or min(mainloop_stages_ab) < 1:
                raise ValueError(
                    "mainloop_stages_ab must be two positive stage counts "
                    f"(A, B), got {mainloop_stages_ab}"
                )
        self.mainloop_stages_ab = mainloop_stages_ab
        self.arch = utils.sm107.canonicalize_rubin_resource_arch(arch)
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes(self.arch)

        if swizzle_size <= 0:
            raise ValueError(
                f"swizzle_size must be a positive integer, got {swizzle_size}"
            )

        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape = self.cluster_shape
            self.max_active_fallback_clusters = max_active_clusters
        else:
            if fallback_cluster_shape_mn[0] < 1 or fallback_cluster_shape_mn[1] < 1:
                raise ValueError(
                    "fallback_cluster_shape_mn dims must be >= 1, got "
                    f"{fallback_cluster_shape_mn}"
                )
            if use_2cta_instrs and (
                fallback_cluster_shape_mn[0] < 2
                or fallback_cluster_shape_mn[0] % 2 != 0
            ):
                raise ValueError(
                    "2CTA mode requires fallback_cluster_shape_mn[0] >= 2 and "
                    f"a multiple of 2, got {fallback_cluster_shape_mn[0]}"
                )
            self.fallback_cluster_shape = (
                fallback_cluster_shape_mn[0],
                fallback_cluster_shape_mn[1],
                1,
            )
            self.max_active_fallback_clusters = (
                max_active_fallback_clusters
                if max_active_fallback_clusters is not None
                else max_active_clusters
            )

        # Validate the configuration up front so that unsupported tile /
        # cluster / dtype combinations fail fast with a clear message.
        self.can_implement()

    def can_implement(self):
        """Validate that this kernel supports the requested configuration.

        Checks the operand / accumulator dtypes together with the MMA tiler,
        MMA instruction shape and cluster shape. Raises
        ``testing.CantImplementError`` when the configuration is not supported.
        """
        #
        # Check supported Data types
        #
        # A and B are independent inputs, but each dtype family maps to one
        # tcgen05 atom and the atom decides whether a mix is legal
        # The SM107 FP8 atom takes a per-operand dtype, while the F16/BF16 and TF32 atoms
        # are built from a single operand dtype.
        supported_ab_dtypes = {
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Float32,
        }
        for name, dtype in (("a_dtype", self.a_dtype), ("b_dtype", self.b_dtype)):
            if dtype not in supported_ab_dtypes:
                raise testing.CantImplementError(
                    f"Unsupported {name}: {dtype}; supported: Float8E4M3FN, "
                    "Float8E5M2, Float16, BFloat16, TFloat32, Float32"
                )
        if not self._is_fp8() and self.a_dtype is not self.b_dtype:
            raise testing.CantImplementError(
                f"Unsupported operand pair {self.a_dtype} x {self.b_dtype}; "
                "only FP8 operands may differ (any Float8E4M3FN/Float8E5M2 "
                "pair). F16/BF16 and TF32 require a_dtype == b_dtype"
            )
        if self.acc_dtype not in {cutlass.Float32, cutlass.Float16}:
            raise testing.CantImplementError(
                f"Unsupported acc_dtype: {self.acc_dtype}; supported: Float32, Float16"
            )

        if self._is_tf32() and self.acc_dtype is not cutlass.Float32:
            raise testing.CantImplementError(
                f"TF32 operands require acc_dtype=Float32; got {self.acc_dtype}"
            )

        #
        # Check supported output type
        #
        supported_d_dtypes = {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float4E2M1FN,
        }
        if self.d_dtype not in supported_d_dtypes:
            raise testing.CantImplementError(
                f"Unsupported d_dtype: {self.d_dtype}; supported: Float32, "
                "Float16, BFloat16, Float8E4M3FN, Float8E5M2, Float4E2M1FN"
            )
        if (
            self.d_dtype is cutlass.Float4E2M1FN
            and self.d_layout_ is not cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        ):
            raise testing.CantImplementError(
                "Float4E2M1FN output must be n-major (row-major D)"
            )

        #
        # Check supported MMA tiler / instruction shape
        #
        # The cluster tile is covered by REST_M atom calls along M, so the tile
        # M must be an integer multiple of the instruction M.
        if self.mn_tiler[0] % self.mma_inst_shape[0] != 0:
            raise testing.CantImplementError(
                f"mn_tiler[0]={self.mn_tiler[0]} must be a multiple of "
                f"mma_inst_shape[0]={self.mma_inst_shape[0]}"
            )
        # REST_N != 1 is not supported: the tile N must match the instruction N.
        if self.mn_tiler[1] != self.mma_inst_shape[1]:
            raise testing.CantImplementError(
                f"mn_tiler[1]={self.mn_tiler[1]} must equal "
                f"mma_inst_shape[1]={self.mma_inst_shape[1]} "
                "(REST_N != 1 is not supported by this kernel)"
            )
        # Only REST_M == 1 (no B-reuse) or REST_M == 2 (B-reuse path) are
        # supported.
        rest_m = self.mn_tiler[0] // self.mma_inst_shape[0]
        if rest_m not in (1, 2):
            raise testing.CantImplementError(
                f"Unsupported REST_M={rest_m} (mn_tiler[0]={self.mn_tiler[0]}, "
                f"mma_inst_shape[0]={self.mma_inst_shape[0]}); "
                "REST_M must be 1 or 2"
            )
        # B-reuse (REST_M == 2) relies on the SM107 FP8 atom's operand-collector
        # ops; other dtypes build the SM100 atom from the full tile and cannot
        # cover REST_M > 1.
        if rest_m == 2 and not self._is_fp8():
            raise testing.CantImplementError(
                f"REST_M=2 (B-reuse) requires FP8 operands; got "
                f"{self.a_dtype} x {self.b_dtype}"
            )
        # The MMA instruction M is fixed by the CTA group (2-CTA doubles M).
        expected_inst_m = 256 if self.use_2cta_instrs else 128
        if self.mma_inst_shape[0] != expected_inst_m:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_m={self.mma_inst_shape[0]}; expected "
                f"{expected_inst_m} for use_2cta_instrs={self.use_2cta_instrs}"
            )
        if self.mma_inst_shape[1] not in (128, 256):
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_n={self.mma_inst_shape[1]}; "
                "expected 128 or 256"
            )
        # The SM107 FP8 atom takes the instruction K explicitly and only
        # accepts 32 or 64; the F16/BF16 and TF32 atoms have a fixed
        # dtype-derived K and ignore mma_inst_shape[2].
        if self._is_fp8() and self.mma_inst_shape[2] not in (32, 64):
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_k={self.mma_inst_shape[2]} for FP8 "
                "operands; the SM107 FP8 atom requires K in (32, 64)"
            )
        atom_k = (
            self.mma_inst_shape[2]
            if self._is_fp8()
            else _default_mma_inst_k(self.a_dtype, self.b_dtype)
        )
        # The mainloop issues mn_tiler[2] // atom_K MMA calls per K tile, so a
        # non-multiple tiler K would silently drop the K tail.
        if self.mn_tiler[2] % atom_k != 0:
            raise testing.CantImplementError(
                f"mn_tiler[2]={self.mn_tiler[2]} must be a multiple of the "
                f"MMA instruction K ({atom_k})"
            )

        #
        # TMEM capacity
        #
        # Each accumulator stage occupies mn_tiler[1] TMEM columns per atom;
        # B-keep/B-reuse doubles this because two atom accumulators are live
        # simultaneously. At least one stage must fit (576 columns on sm_107).
        cols_per_acc_stage = self.mn_tiler[1] * (2 if self.enable_breuse else 1)
        tmem_capacity_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)
        if cols_per_acc_stage > tmem_capacity_cols:
            raise testing.CantImplementError(
                "No accumulator stages fit in TMEM: cols_per_acc_stage="
                f"{cols_per_acc_stage} (mn_tiler[1]={self.mn_tiler[1]}, "
                f"enable_breuse={self.enable_breuse}) exceeds the "
                f"{tmem_capacity_cols}-column capacity of {self.arch}"
            )

        #
        # Cluster shape
        #
        cluster_shape_mn = (self.cluster_shape[0], self.cluster_shape[1])
        # Cluster M must be a multiple of the CTA-group size.
        if cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster_shape_m={cluster_shape_mn[0]} for "
                f"use_2cta_instrs={self.use_2cta_instrs}"
            )
        # Cluster dimensions must be positive powers of two with a total
        # cluster size of at most 16.
        if (
            cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            or cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or (cluster_shape_mn[0] & (cluster_shape_mn[0] - 1)) != 0
            or (cluster_shape_mn[1] & (cluster_shape_mn[1] - 1)) != 0
        ):
            raise testing.CantImplementError(
                f"Invalid cluster_shape: {cluster_shape_mn}"
            )

        return True

    def _is_fp8(self) -> bool:
        fp8_dtypes = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        return self.a_dtype in fp8_dtypes and self.b_dtype in fp8_dtypes

    def _is_tf32(self) -> bool:
        tf32_dtypes = (cutlass.TFloat32, cutlass.Float32)
        return self.a_dtype in tf32_dtypes and self.b_dtype in tf32_dtypes

    """
    Consider this example with mma_inst = 256x128 and mma_tiler = 512x128.
    In regular 2CTA mode, we have 2 CTAs cooperating to cover the tile in this format
    with per-CTA M=128:
                      REST_M = 0                 REST_M = 1
                  (atom call #0)             (atom call #1)
                  +-----------+--------+     +-----------+--------+
        M chunk:  | chunk0    | chunk1 |     | chunk2    | chunk3 |
        owner:    | CTA0      | CTA1   |     | CTA0      | CTA1   |
                  +-----------+--------+     +-----------+--------+
        M range:   [0..128)    [128..256)     [256..384)  [384..512)

    CTA0's A footprint across the kernel: chunk0 + chunk2  -> NON-contiguous in M
    CTA1's A footprint:                   chunk1 + chunk3  -> NON-contiguous in M

    This is what happens in the legacy path where we return a (1,1,1) permutation.

    With B-keep/B-reuse, we want CTA0 to hold a full tile worth the entire MMA-M and same for CTA1
    so that the B matrix can be reused.

                    REST_M = 0                 REST_M = 1
                  (atom call #0)             (atom call #1)
                  +-----------+              +-----------+
       CTA0 ->    |  chunk0   |              |  chunk1   |
                  | [0..128)  |              | [128..256)|
                  +-----------+              +-----------+
                                                  |
                                                  | (same B reused)
                                                  v
                  +-----------+              +-----------+
       CTA1 ->    |  chunk2   |              |  chunk3   |
                  | [256..384)|              | [384..512)|
                  +-----------+              +-----------+

    CTA0's A footprint: chunk0 + chunk1 = M[0..256)    -> CONTIGUOUS
    CTA1's A footprint: chunk2 + chunk3 = M[256..512)  -> CONTIGUOUS
    The layout of the permutation is of this form : (per-CTA M, CTA-index, REST_M) : (1, CTA stride, REST_M stride)
    Plugging in the values, we get a layout (128, 2, 2) : (1, 256, 128)
    So each CTA handles 128 rows, the stride between the starting rows in a CTA pair is 256
    and the stride across atoms within a CTA is 128.
    """

    def _get_mma_permutation_mnk(self):
        if cutlass.const_expr(self.use_2cta_instrs and self.enable_breuse):
            m_layout = cute.make_layout(
                shape=(self.mma_inst_shape[0] // 2, 2, 2),
                stride=(1, self.mma_inst_shape[0], self.mma_inst_shape[0] // 2),
            )
            return (m_layout, self.mma_inst_shape[1], self.mma_inst_shape[2])

        else:
            return (1, 1, 1)

    def _make_tiled_mma(self, cta_group):
        # FP8 inputs use the SM107 (Rubin) MMA op which requires the full
        # (M, N, K) instruction shape. Other dtypes (FP16/BF16/TF32/...)
        # use the SM100 helper which infers K from the operand dtype and
        # only takes (M, N).
        if self._is_fp8():
            return sm107_utils.make_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                self.a_major_mode_,
                self.b_major_mode_,
                self.acc_dtype,
                cta_group,
                self.mma_inst_shape,
                permutation_mnk=self._get_mma_permutation_mnk(),
            )
        return sm100_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode_,
            self.b_major_mode_,
            self.acc_dtype,
            cta_group,
            (self.mn_tiler[0], self.mn_tiler[1]),
        )

    def _setup_stages(self):
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.TWO
            if self.use_2cta_instrs
            else cute.nvgpu.tcgen05.CtaGroup.ONE
        )
        tiled_mma = self._make_tiled_mma(cta_group)
        mnk_tiler = self.mn_tiler
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = (
            mnk_tiler[0] // num_mma_ctas,
            mnk_tiler[1],
            mnk_tiler[2],
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout_,
            self.d_dtype,
        )
        (
            self.a_stage,
            self.b_stage,
            self.TMA_STORE_STAGE,
            self.acc_stage,
        ) = self._compute_stages(
            tiled_mma,
            mnk_tiler,
            self.a_dtype,
            self.b_dtype,
            epi_tile,
            self.d_dtype,
            self.d_layout_,
            self.smem_capacity,
            cute.arch.get_max_tmem_alloc_cols(self.arch),
            self.enable_breuse,
            self.use_2cta_instrs,
            mainloop_stages_ab=self.mainloop_stages_ab,
        )

    @staticmethod
    def _split_mainloop_stages(
        mainloop_budget: int,
        a_bytes_per_stage: int,
        b_bytes_per_stage: int,
        use_2cta_instrs: bool,
    ) -> tuple[int, int]:
        """Stage counts (A, B) of the two operand pipelines within ``mainloop_budget``.

        Both get the depth a shared A+B pipeline would get, so neither
        operand's prefetch window is shorter than in the single-pipeline variant.
        For 2SM MMAs, each pipeline is capped at 9 stages.

        :param mainloop_budget: Shared memory available to both pipelines, in bytes.
        :param a_bytes_per_stage: Size of one A stage in bytes.
        :param b_bytes_per_stage: Size of one B stage in bytes.
        :param use_2cta_instrs: Whether the MMAs are 2SM (``cta_group::2``).
        :return: (a_stages, b_stages)
        """
        ab_bytes_per_stage = a_bytes_per_stage + b_bytes_per_stage
        shared_stages = mainloop_budget // ab_bytes_per_stage
        if shared_stages < 1:
            raise testing.CantImplementError(
                f"one A+B stage needs {ab_bytes_per_stage} bytes of shared "
                f"memory per CTA but only {mainloop_budget} are available"
            )
        a_stages = b_stages = shared_stages
        if use_2cta_instrs:
            cap = PersistentDenseGemmSplitABKernel.MAX_STAGES_PER_RING_2SM
            a_stages, b_stages = min(a_stages, cap), min(b_stages, cap)
        return a_stages, b_stages

    @staticmethod
    def _compute_stages(
        tiled_mma,
        mma_tiler_mnk: tuple[int, int, int],
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        epi_tile,
        d_dtype: Type[Numeric],
        d_layout: cutlass.tensor_utils.LayoutEnum,
        smem_capacity: int,
        tmem_capacity_cols: int,
        enable_breuse: bool,
        use_2cta_instrs: bool,
        occupancy: int = 1,
        mainloop_stages_ab: Tuple[int, int] | None = None,
    ) -> tuple[int, int, int, int]:
        """Computes the stage counts of the A pipeline, the B pipeline, the TMA store and the accumulator.

        Heuristic: size the two operand pipelines with ``_split_mainloop_stages``,
        then allocate the remaining capacity to epilogue (TMA store) stages.
        Accumulator stages are derived from the TMEM column budget, capped at 2.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :param a_dtype: Data type of operand A.
        :param b_dtype: Data type of operand B.
        :param epi_tile: The epilogue tile shape.
        :param d_dtype: Data type of the output tensor D.
        :param d_layout: Layout enum of the output tensor D.
        :param smem_capacity: Total available shared memory capacity in bytes.
        :param tmem_capacity_cols: Total available TMEM capacity in columns.
        :param enable_breuse: Whether the B-keep/B-reuse path (REST_M = 2) is on.
        :param use_2cta_instrs: Whether the MMAs are 2SM (``cta_group::2``).
        :param occupancy: Target number of CTAs per SM, defaults to 1.
        :param mainloop_stages_ab: Optional explicit (A, B) stage counts for
            the two TMA load pipelines; rejected when they do not fit in shared
            memory.
        :return: (a_stages, b_stages, tma_store_stages, acc_stages)
        """
        # Each accumulator stage occupies mma_tiler_mnk[1] TMEM columns per
        # atom; B-keep/B-reuse doubles this because two atom accumulators are
        # live simultaneously (e.g. N=256 with B-reuse fits only one stage in
        # sm_107's 576 columns). can_implement guarantees at least one fits.
        cols_per_acc_stage = mma_tiler_mnk[1] * (2 if enable_breuse else 1)
        num_acc_stage = min(2, tmem_capacity_cols // cols_per_acc_stage)
        num_tma_store_stage = 2
        reserved_smem_bytes = 1024

        a_smem_layout_one = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            a_dtype,
            1,
        )
        b_smem_layout_one = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            b_dtype,
            1,
        )
        epi_smem_layout_one = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            1,
        )

        a_bytes_per_stage = cute.size_in_bytes(a_dtype, a_smem_layout_one)
        b_bytes_per_stage = cute.size_in_bytes(b_dtype, b_smem_layout_one)
        epi_bytes_per_stage = cute.size_in_bytes(d_dtype, epi_smem_layout_one)
        epi_bytes = epi_bytes_per_stage * num_tma_store_stage

        mainloop_budget = smem_capacity // occupancy - reserved_smem_bytes - epi_bytes
        a_stages, b_stages = PersistentDenseGemmSplitABKernel._split_mainloop_stages(
            mainloop_budget, a_bytes_per_stage, b_bytes_per_stage, use_2cta_instrs
        )

        mainloop_bytes = a_stages * a_bytes_per_stage + b_stages * b_bytes_per_stage
        if mainloop_stages_ab is not None:
            a_stages, b_stages = mainloop_stages_ab
            pinned_bytes = a_stages * a_bytes_per_stage + b_stages * b_bytes_per_stage
            if pinned_bytes > mainloop_budget:
                raise testing.CantImplementError(
                    f"mainloop_stages_ab={mainloop_stages_ab} needs "
                    f"{pinned_bytes} bytes of shared memory per CTA "
                    f"({a_bytes_per_stage} per A stage, {b_bytes_per_stage} "
                    f"per B stage) but only {mainloop_budget} are available"
                )
            # The TMA-store depth follows the pinned footprint, the rule the
            # single-ring kernel applies to its ring, so a pinned split at that
            # kernel's depth is its exact shared-memory twin.
            mainloop_bytes = pinned_bytes

        remaining_smem = (
            smem_capacity
            - occupancy * mainloop_bytes
            - occupancy * (reserved_smem_bytes + epi_bytes)
        )
        num_tma_store_stage += remaining_smem // (occupancy * epi_bytes_per_stage)
        return a_stages, b_stages, num_tma_store_stage, num_acc_stage

    @cute.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        stream: cuda.CUstream,
    ):
        self._setup_stages()

        cta_tile_mnk = (
            self.mn_tiler[0] // 2 if self.use_2cta_instrs else self.mn_tiler[0],
            self.mn_tiler[1],
            1,
        )
        num_ctas_mnl = cute.ceil_div(mD.shape, cta_tile_mnk)
        sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl,
            self.cluster_shape,
            swizzle_size=self.swizzle_size,
            raster_along_m=self.raster_along_m,
            fallback_cluster_shape_mnk=self.fallback_cluster_shape,
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            sched_params, self.max_active_clusters
        )
        self.kernel(mA, mB, mD, sched_params).launch(
            grid=grid,
            block=(7 * 32, 1, 1),
            cluster=self.cluster_shape,
            fallback_cluster=self.fallback_cluster_shape,
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        sched_params: PersistentTileSchedulerParams,
    ):
        # Determine CTA group based on 2-CTA mode
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE

        tiled_mma = self._make_tiled_mma(cta_group)

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        mnk_tiler = self.mn_tiler

        # Number of MMA instructions along K per loaded K-tile.
        # This derivation works for the SM100 and SM107 atoms.
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = mnk_tiler[2] // mma_inst_shape_k

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))

        a_stage = self.a_stage
        b_stage = self.b_stage
        acc_stage = self.acc_stage

        cta_m, cta_n, cta_l = cute.arch.block_idx()

        cluster_shape = cute_ext.get_cluster_shape(
            self.cluster_shape, self.fallback_cluster_shape
        )
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cluster_shape),
            (tiled_mma.thr_id.shape,),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        # MMA coordinate within cluster
        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )
        is_leader_cta = mma_coord_vmnk[0] == 0
        thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

        # Compute A/B shared memory layout
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            self.a_dtype,
            a_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            self.b_dtype,
            b_stage,
        )

        # UMMA ACC TMEM Layout. Built from partition_shape_C so the REST_M
        # mode survives for the per-atom epilogue slicing below.
        acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2])
        tmem_layout = tiled_mma.make_fragment_C(
            cute.append(acc_shape, acc_stage)
        ).layout

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            self.a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            self.b_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        # TMA multicast projection modes
        # A is shared by CTAs with same M (multicast across N, proj=2)
        # B is shared by CTAs with same N (multicast across M, proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine pipeline operation types based on 2-CTA mode and TMA multicast
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # TMA -> UMMA pipelines, one pipeline per operand.
        #
        # The A pipeline's MMA is declared `MmaOperation(kind, MmaOperand.A)`:
        # its consumer release lowers to the Rubin `tcgen05.commit` variant that
        # completes once the MMAs have read A from SMEM, so an A stage is handed
        # back to the A load warp without waiting for the MMAs to finish and
        # write the accumulator. B keeps the regular commit. Each pipeline
        # signals only its own operand's multicast set.
        a_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=a_stage,
            mma_operation_type=cute_ext.MmaOperation(
                mma_operation_type, cute_ext.MmaOperand.A
            ),
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )
        b_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=b_stage,
            mma_operation_type=cute_ext.MmaOperation(
                mma_operation_type, cute_ext.MmaOperand.B
            ),
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> Load to tensor memory pipeline
        # All epilogue warps release each stage - the arrival-count query
        # derives the CTA-pair fan-in for 2-CTA MMA from the pipeline type.
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_release_threads_per_cta=128,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load_a, [6]-tma_load_b.
        # The two load warps never wait on each other: each walks the tile schedule on its own and blocks only on its own pipeline.
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_a_warp_id = 5
        tma_load_b_warp_id = 6
        is_tma_a_thr = warp_idx == tma_load_a_warp_id
        is_tma_b_thr = warp_idx == tma_load_b_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4

        # store to smem -> TMA store to global
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        #
        # Persistent tile scheduling loop
        #
        tile_sched = StaticPersistentTileScheduler.create(
            sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        # Tile by the full mma_tile and V-split the per-CTA atoms
        # with `thr_mma.partition_{A,B}`.
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)

        # Number of K tiles in the mainloop.
        k_tile_cnt = cute.size(tCgA, mode=[4])

        if is_tma_a_thr:
            while work_tile.is_valid_tile:
                # The tile scheduler takes into account splitting of the M mode
                # for 2CTA instructions.
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_m = cur_tile_coord[0] // cluster_layout_v_size
                # Per-CTA M tile for A: (MMA, MMA_M, MMA_K, RestK)
                tAgA_slice = tCgA[
                    (None, None, None, mma_tile_coord_m, None, cur_tile_coord[2])
                ]
                for k in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # The acquire returns as soon as the MMAs have read the
                    # stage's A, which is what lets this warp run ahead of the
                    # B warp.
                    a_token, a_idx = a_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        tAgA_slice[(None, None, None, k)],
                        bufferA[None, None, None, a_idx],
                        cute_ext.get_mbarrier(a_token),
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    a_pipe.producer_commit_and_advance()
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            a_pipe.producer_tail()

        if is_tma_b_thr:
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                # Per-CTA N tile for B: (MMA, MMA_N, MMA_K, RestK)
                tBgB_slice = tCgB[
                    (None, None, None, cur_tile_coord[1], None, cur_tile_coord[2])
                ]
                for k in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    b_token, b_idx = b_pipe.producer_acquire_and_get_stage()
                    cute_ext.tma_load(
                        tBgB_slice[(None, None, None, k)],
                        bufferB[None, None, None, b_idx],
                        cute_ext.get_mbarrier(b_token),
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_B,
                    )
                    b_pipe.producer_commit_and_advance()
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            b_pipe.producer_tail()

        if is_mma_thr and is_leader_cta:
            while work_tile.is_valid_tile:
                _, idx = acc_pipe.producer_acquire_and_get_stage()
                accumulators_sliced = bufferAcc[None, None, None, idx]

                # Per k-tile: wait A, wait B, MMAs, release A (smem-A-read
                # commit), release B (regular commit).
                (a_pipe, b_pipe) = cute_ext.mainloop_mma(
                    tiled_mma,
                    bufferA,
                    bufferB,
                    accumulators_sliced,
                    0,
                    k_tile_cnt,
                    mma_inst_tile_k,
                    a_pipe,
                    b_pipe,
                    ab_buffer_same_pipeline=False,
                )

                acc_pipe.producer_commit_and_advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_epi_thr:
            # The MMA tiler covers REST_M = mn_tiler[0]/mma_inst_shape[0]
            # atom tiles along M; the TMEM accumulator carries one
            # output per atom.
            # epilogue_tma_store handles REST_N but not REST_M > 1
            # So we run a loop over REST_M and call epilogue_tma_store for each atom.

            # This gives us the rest mode of M - will be 2 in B-reuse mode
            epi_rest_m = self.mn_tiler[0] // self.mma_inst_shape[0]
            # Per-CTA M of a single atom = cta_tile_shape_mnk[0]/REST_M.
            # For 2CTA with TILE_M=512, this becomes 128 because
            # we have 2 CTAs and each should operate on half of the data.
            epi_atom_m_per_cta = cta_tile_shape_mnk[0] // epi_rest_m
            epi_atom_tile_shape_mnk = (
                epi_atom_m_per_cta,
                cta_tile_shape_mnk[1],
                cta_tile_shape_mnk[2],
            )

            while work_tile.is_valid_tile:
                _, idx = acc_pipe.consumer_wait_and_get_stage()

                for m_atom in range(epi_rest_m):
                    accumulators_per_atom = bufferAcc[(None, None), m_atom, 0, idx]
                    cta_d_tile_coord_per_atom = (
                        work_tile.tile_idx[0] * epi_rest_m + m_atom,
                        work_tile.tile_idx[1],
                        work_tile.tile_idx[2],
                    )
                    tma_store_pipe = cute_ext.epilogue_tma_store(
                        epi_atom_tile_shape_mnk,
                        self.use_2cta_instrs,
                        accumulators_per_atom,
                        mD,
                        cta_d_tile_coord_per_atom,
                        tma_store_pipe,
                        tma_store_warp_id,
                        self.epilogue_op,
                        d_major_mode=self.d_layout_,
                    )

                acc_pipe.consumer_release_and_advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Stage reuse across CTA tiles is protected by acquire_sync(), so
            # the pipeline is drained once here instead of per CTA tile.
            tma_store_pipe.tail()


def create_tensors(l, m, n, k, a_major, b_major, d_major, a_dtype, b_dtype, d_dtype):
    """Create A, B, D tensors using tensor_utils (handles FP8/FP4 via DLPack)."""
    from cutlass.utils.gemm.tensor_utils import get_gemm_tensors

    torch.manual_seed(1111)

    a_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if a_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    b_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if b_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    d_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if d_major == "n"
        else cute.nvgpu.OperandMajorMode.MN
    )

    (
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
        a_tensor,
        b_tensor,
        d_tensor,
    ) = get_gemm_tensors(
        m,
        n,
        k,
        l,
        (a_major_mode, b_major_mode, d_major_mode),
        (
            cutlass_torch.dtype(a_dtype),
            cutlass_torch.dtype(b_dtype),
            cutlass_torch.dtype(d_dtype),
        ),
    )

    return (
        a_tensor,
        b_tensor,
        d_tensor,
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
    )


def compare(
    a_torch_cpu,
    b_torch_cpu,
    d_cute_tensor,
    d_torch_gpu,
    d_dtype,
    d_major,
    tolerance,
):
    """Reference check: D = A @ B.

    FP8 A/B tensors do not support ``torch.einsum`` directly, so both operands
    are promoted to float32 first; float32 is a strict superset of FP8, so the
    promotion is exact.

    D is read back through ``cute.testing.convert`` rather than torch, because
    the narrow output types have no torch storage type of matching width. For
    those types (<= 8 bit) the float32 reference is also round-tripped through
    the hardware converter (f32 -> D -> f32) so rounding and saturation match
    the kernel's epilogue exactly.
    """

    def _to_f32(x):
        return x.to(torch.float32) if x.dtype != torch.float32 else x

    ref = torch.einsum("mkl,nkl->mnl", _to_f32(a_torch_cpu), _to_f32(b_torch_cpu))

    m, n, l = ref.shape[0], ref.shape[1], ref.shape[2]
    leading_dim = 1 if d_major == "n" else 0

    def _make_d_torch(dtype):
        if d_major == "m":
            return torch.empty(l, n, m, dtype=dtype, device="cuda").permute(2, 1, 0)
        return torch.empty(l, m, n, dtype=dtype, device="cuda").permute(1, 2, 0)

    gpu_f32_ = _make_d_torch(torch.float32)
    gpu_f32 = from_dlpack(gpu_f32_, assumed_align=16).mark_layout_dynamic(
        leading_dim=leading_dim
    )
    cute.testing.convert(d_cute_tensor, gpu_f32)
    gpu_result = gpu_f32_.cpu()

    if d_dtype.width <= 8:
        ref_narrow_ = _make_d_torch(torch.uint8)
        ref_narrow = from_dlpack(ref_narrow_, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim
        )
        ref_narrow.element_type = d_dtype

        ref_device = _make_d_torch(torch.float32)
        ref_device.copy_(ref)
        ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
            leading_dim=leading_dim
        )
        cute.testing.convert(ref_tensor, ref_narrow)
        cute.testing.convert(ref_narrow, ref_tensor)
        ref = ref_device.cpu()
    else:
        # Match the kernel's store precision before comparing.
        ref = ref.to(cutlass_torch.dtype(d_dtype)).to(torch.float32)

    torch.testing.assert_close(gpu_result, ref, atol=tolerance, rtol=1e-05)


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-02,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    fallback_cluster_shape_mn: Tuple[int, int] = None,
    swizzle_size: int = 1,
    raster_along: str = "m",
    mma_inst_shape: Tuple[int, int, int] | None = None,
    arch: str = "sm_107",
    a_dtype: Type[Numeric] | None = None,
    b_dtype: Type[Numeric] | None = None,
    use_cuda_graphs: bool = True,
    benchmark: str = "default",
    mainloop_stages_ab: Tuple[int, int] | None = None,
):
    """Execute a batched dense GEMM on Rubin with split A/B operand pipelines, one
    TMA load warp per operand, and performance benchmarking.

    This function prepares input tensors, configures and launches the GEMM kernel,
    optionally performs reference validation, and benchmarks the execution performance.

    This kernel demonstrates the B-keep/B-reuse feature on Rubin when using a 2x larger tile size than the MMA instruction shape.
    The MMA instruction shape is exposed as an optional argument to the user.
    For a 1CTA run, mma_inst_shape=128,128,64 and mma_tiler=256,128,128 would trigger the B-keep/B-reuse feature.
    This is internally handled within the compiler via heuristics.

    NOTE: B-reuse is currently only supported for FP8 inputs.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_tiler: MMA tiling size (M, N, K).
    :type mma_tiler: Tuple[int, int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param ab_dtype: Shared data type for input tensors A and B. Ignored for an
        operand whose per-operand override (`a_dtype` / `b_dtype`) is given.
    :type ab_dtype: Type[Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param use_2cta_instrs: Use 2-CTA (2SM) instructions for larger tile sizes
    :type use_2cta_instrs: bool
    :param fallback_cluster_shape_mn: Optional. When provided and different
        from cluster_shape_mn, the kernel runs in mixed-cluster mode.
    :type fallback_cluster_shape_mn: Optional[Tuple[int, int]]
    :param mma_inst_shape: Optional (M, N, K) shape of a single MMA instruction.
        When smaller than `mma_tiler` along M, a single dot covers
        REST_M > 1 atom tiles, exposing the B-reuse expansion opportunity.
        Defaults to `mma_tiler` M/N with a dtype-derived instruction K
        (REST_M = 1).
    :type mma_inst_shape: Tuple[int, int, int] | None
    :param a_dtype: Per-operand override for A; defaults to `ab_dtype`.
    :type a_dtype: Type[Numeric] | None
    :param b_dtype: Per-operand override for B; defaults to `ab_dtype`. Only
        FP8 operands may differ from A.
    :type b_dtype: Type[Numeric] | None
    :param use_cuda_graphs: Benchmark via CUDA graph replays, defaults to True.
    :type use_cuda_graphs: bool
    :param benchmark: Benchmark mode - "default" uses CUDA events, "cupti"
        uses CUPTI kernel-activity timing, "none" skips benchmarking.
    :type benchmark: str
    :param mainloop_stages_ab: Optional explicit (A, B) stage counts for the
        two pipelines; by default the kernel sizes them from the shared memory
        budget.
    :type mainloop_stages_ab: Optional[Tuple[int, int]]
    """
    if benchmark not in ("default", "cupti", "none"):
        raise ValueError(
            f"Invalid benchmark mode '{benchmark}'. "
            "Expected one of: default, cupti, none."
        )
    a_dtype = ab_dtype if a_dtype is None else a_dtype
    b_dtype = ab_dtype if b_dtype is None else b_dtype
    if mma_inst_shape is None:
        mma_inst_shape = (
            mma_tiler[0],
            mma_tiler[1],
            _default_mma_inst_k(a_dtype, b_dtype),
        )

    cli.print_problem_config(
        f"LIR Rubin ({arch.upper()}) Dense GEMM, split A/B pipelines, two TMA warps",
        mnkl,
        lines=[
            f"A dtype: {a_dtype}, B dtype: {b_dtype}, D dtype: {c_dtype}, "
            f"Acc dtype: {acc_dtype}",
        ],
        majors={"A": a_major, "B": b_major, "D": c_major},
    )
    print(f"Mma Tiler (M, N, K): {mma_tiler}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"Mma Inst Shape (M, N, K): {mma_inst_shape}")
    if fallback_cluster_shape_mn is not None:
        print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )
    print(f"Benchmark mode: {benchmark}")
    print(f"Use CUDA graphs: {'True' if use_cuda_graphs else 'False'}")

    m, n, k, l = mnkl
    d_dtype = c_dtype
    d_major = c_major

    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        a_dtype,
        b_dtype,
        d_dtype,
        a_major,
        b_major,
        d_major,
        output_tensor_name="D",
    )

    (
        a_tensor,
        b_tensor,
        d_tensor,
        a_torch_gpu,
        b_torch_gpu,
        d_torch_gpu,
    ) = create_tensors(l, m, n, k, a_major, b_major, d_major, a_dtype, b_dtype, d_dtype)

    a_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if a_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    b_major_mode = (
        cute.nvgpu.OperandMajorMode.K
        if b_major == "k"
        else cute.nvgpu.OperandMajorMode.MN
    )
    d_layout = (
        cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        if d_major == "n"
        else cutlass.tensor_utils.LayoutEnum.COL_MAJOR
    )
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )
    if fallback_cluster_shape_mn is not None:
        max_active_fallback_clusters = utils.HardwareInfo().get_max_active_clusters(
            fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
        )
    else:
        max_active_fallback_clusters = None

    dense_gemm = PersistentDenseGemmSplitABKernel(
        mn_tiler=mma_tiler,
        mma_dtype=(a_dtype, b_dtype, acc_dtype),
        tmem_output_dtype=d_dtype,
        a_major_mode=a_major_mode,
        b_major_mode=b_major_mode,
        d_layout=d_layout,
        epilogue_op=lambda x: x,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        max_active_fallback_clusters=max_active_fallback_clusters,
        swizzle_size=swizzle_size,
        raster_along_m=(raster_along == "m"),
        mma_inst_shape=mma_inst_shape,
        arch=arch,
        mainloop_stages_ab=mainloop_stages_ab,
    )

    torch_stream = torch.cuda.current_stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    compiled_dense_gemm = cute.compile(dense_gemm, a_tensor, b_tensor, d_tensor, stream)
    compiled_dense_gemm.engine.initialize()
    print(
        f"Mainloop stages (A, B): ({dense_gemm.a_stage}, {dense_gemm.b_stage})"
        f"{'' if mainloop_stages_ab is None else ' (pinned)'}"
    )

    compiled_dense_gemm(a_tensor, b_tensor, d_tensor, stream)

    if not skip_ref_check:
        compare(
            a_torch_gpu.cpu(),
            b_torch_gpu.cpu(),
            d_tensor,
            d_torch_gpu,
            d_dtype,
            d_major,
            tolerance,
        )
        print("check reference: PASS")

    if benchmark == "none":
        return 0

    # Graph capture requires a non-default stream; otherwise keep the current
    # stream so event timing measures the same stream the kernel launches on.
    bench_torch_stream = torch.cuda.Stream() if use_cuda_graphs else torch_stream
    bench_stream = cuda.CUstream(bench_torch_stream.cuda_stream)

    def generate_tensors():
        (
            a_tensor,
            b_tensor,
            d_tensor,
            a_torch_gpu,
            b_torch_gpu,
            d_torch_gpu,
        ) = create_tensors(
            l, m, n, k, a_major, b_major, d_major, a_dtype, b_dtype, d_dtype
        )
        args = testing.JitArguments(a_tensor, b_tensor, d_tensor, bench_stream)
        args.add_to_scope([a_torch_gpu, b_torch_gpu, d_torch_gpu])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_gpu.numel() * a_torch_gpu.element_size()
            + b_torch_gpu.numel() * b_torch_gpu.element_size()
            + d_torch_gpu.numel() * d_torch_gpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Run the workspace generator under bench_torch_stream so its launches,
    # the kernel, and the graph capture all share one capturable stream.
    with torch.cuda.stream(bench_torch_stream):
        exec_time = testing.benchmark(
            compiled_dense_gemm,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=bench_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=use_cuda_graphs,
            use_cupti=benchmark == "cupti",
        )

    runtime_s = exec_time / 1.0e6
    fmas = m * n * k * l
    flop = 2 * fmas
    gflop = flop / 1.0e9

    print("Average Runtime : ", exec_time / 1000, "ms")
    if runtime_s == 0:
        print("GFLOPS          :  n/a (zero measured runtime)")
    else:
        print("GFLOPS          : ", gflop / runtime_s)

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Dense GEMM on Rubin (SM107) with split A/B operand pipelines "
        "and one TMA load warp per operand."
    )

    cli.add_mnkl_arg(parser)
    parser.add_argument(
        "--mma_tiler",
        type=cli.comma_separated_ints,
        default=(128, 128, 128),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=cli.comma_separated_ints,
        default=None,
        help=(
            "MMA instruction (atom) shape M,N,K (comma-separated). When smaller "
            "than --mma_tiler along M, REST_M > 1 and the LIR B-reuse "
            "expansion pass becomes applicable. Defaults to --mma_tiler M/N "
            "with a dtype-derived instruction K."
        ),
    )
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.Float32, c=cutlass.Float32)
    # Per-operand overrides for a mixed-input GEMM; unset means "use --ab_dtype".
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=None,
        help="A element type; defaults to --ab_dtype.",
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=None,
        help="B element type; defaults to --ab_dtype. Only FP8 operands "
        "(Float8E4M3FN / Float8E5M2) may differ from A.",
    )
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser, tolerance=1e-02)

    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints,
        default=None,
        help="Optional fallback cluster shape (comma-separated).",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) instructions for larger tile sizes",
    )
    parser.add_argument(
        "--mainloop_stages_ab",
        type=cli.comma_separated_ints,
        default=None,
        help="Explicit A,B stage counts for the two operand pipelines (default: "
        "the depth a shared A+B pipeline would get). The TMA-store depth "
        "follows the pinned footprint, as in the single-ring kernel.",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_along",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )
    parser.add_argument("--arch", type=str, default="sm_107")
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=["default", "cupti", "none"],
        help="Benchmark mode: CUDA-event timing (default), CUPTI "
        "kernel-activity timing, or none",
    )
    parser.add_argument(
        "--use_cuda_graphs",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Benchmark via CUDA graph replays (default: on; "
        "--no-use_cuda_graphs to disable)",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values")

    if args.mma_inst_shape is not None and len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values")

    if (
        args.fallback_cluster_shape_mn is not None
        and len(args.fallback_cluster_shape_mn) != 2
    ):
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    if args.mainloop_stages_ab is not None:
        if len(args.mainloop_stages_ab) != 2:
            parser.error("--mainloop_stages_ab must contain exactly 2 values")

    exec_time = run(
        args.mnkl,
        args.mma_tiler,
        args.cluster_shape_mn,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
        args.use_2cta_instrs,
        fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
        swizzle_size=args.swizzle_size,
        raster_along=args.raster_along,
        mma_inst_shape=args.mma_inst_shape,
        arch=args.arch,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        use_cuda_graphs=args.use_cuda_graphs,
        benchmark=args.benchmark,
        mainloop_stages_ab=args.mainloop_stages_ab,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
