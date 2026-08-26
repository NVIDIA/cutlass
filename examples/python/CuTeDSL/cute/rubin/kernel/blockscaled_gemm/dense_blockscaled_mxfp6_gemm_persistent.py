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

import argparse
import os
import sys
from typing import Type, Tuple, Union, Literal

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.nvgpu import cpasync, tcgen05, OperandMajorMode
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils

# Make sibling and ancestor example directories importable.
# From this file's location (cute/rubin/kernel/blockscaled_gemm/):
#   ../../..   = cute/        -> 'rubin' and 'blackwell' packages
#   ../../../.. = CuTeDSL/    -> 'helpers' package (used by dense_blockscaled_gemm_persistent)
_here = os.path.dirname(os.path.abspath(__file__))
_cute_dir = os.path.normpath(os.path.join(_here, "../../.."))
_cutedsl_dir = os.path.normpath(os.path.join(_here, "../../../.."))
for _d in [_cute_dir, _cutedsl_dir]:
    if _d not in sys.path:
        sys.path.insert(0, _d)

from rubin.kernel.blockscaled_gemm.dense_blockscaled_gemm_persistent import (  # noqa: E402
    Sm107BlockScaledPersistentDenseGemmKernel,
    run_scaled_mm_with_emulated_dtype,
)


"""
Persistent dense block-scaled GEMM kernel for SM107 (Rubin).

Supported operand combinations
-------------------------------
  * FP6 x FP6   -- both operands are FP6 (Float6E3M2FN or Float6E2M3FN)
  * FP8 x FP6   -- A is FP8 (Float8E4M3FN or Float8E5M2), B is FP6
  * FP6 x FP8   -- A is FP6, B is FP8
  * FP4 x FP6   -- A is FP4 (Float4E2M1FN), B is FP6
  * FP6 x FP4   -- A is FP6, B is FP4

At least one operand must be FP6.  For FP8 x FP8 (both FP8), refer to the companion
example: dense_blockscaled_gemm_persistent.py

Unlike Blackwell, Rubin's MMA can consume packed FP6 operands directly from SMEM, so no
intermediate format conversion is required for the FP6 operand.

K-tile construction
--------------------
  Each MMA instruction covers K=64 elements.  The per-operand bytes per MMA are:
    FP6: 64 x 6/8 = 48 B  ->  3 x 128 B buffers per k-tile  (3 TMA loads)
    FP8: 64 x 8/8 = 64 B  ->  4 x 128 B buffers per k-tile  (4 TMA loads)
    FP4: 64 x 4/8 = 32 B  ->  4 x  64 B buffers per k-tile  (4 TMA loads)

  For FP6 operands, 8 back-to-back MMAs span 3 x 128 B buffers with circular addressing
  (data crosses buffer boundaries, so descriptors reference cur and next buffer).
  For FP8 operands, 2 MMAs fit cleanly in each 128 B buffer -- no circular spanning needed.
  For FP4 operands, 2 MMAs fit cleanly in each 64 B buffer -- no circular spanning needed.
  FP4 uses 4 pipeline stages per k-tile (same as FP8) so data and SF advance in lock-step.

Warp specialization
--------------------
  Two dedicated load warps and one MMA warp:
    fp6-warp  -- loads the FP6-typed operand data (or A+B in FP6)
    fp8-warp  -- loads the FP4/FP8-typed operand data + all SF (or SF only in FP6)

This GEMM kernel supports the following features:
    - TMA for efficient GMEM->SMEM data movement
    - Rubin tcgen05.mma (including 2-CTA instructions)
    - B-keep/B-reuse for both FP6 and FP8 B operands
    - TMA multicast with cluster to reduce L2 traffic
    - Persistent tile scheduling
    - Warp specialization

Example invocations
--------------------

FP6 x FP6:

.. code-block:: bash

    python dense_blockscaled_mxfp6_gemm_persistent.py                                               \
        --a_dtype Float6E3M2FN --b_dtype Float6E3M2FN                                               \
        --sf_dtype Float8E8M0FNU --sf_vec_size 32                                                   \
        --c_dtype Float16                                                                           \
        --mma_tiler 128,128,512 --mma_inst_shape 128,128,64                                         \
        --cluster_shape_mn 2,4 --swizzle_size 1 --raster_order m                                    \
        --mnkl 8192,8192,1024,1

FP8 x FP6 (A=FP8, B=FP6):

.. code-block:: bash

    python dense_blockscaled_mxfp6_gemm_persistent.py                                               \
        --a_dtype Float8E4M3FN --b_dtype Float6E3M2FN                                               \
        --sf_dtype Float8E8M0FNU --sf_vec_size 32                                                   \
        --c_dtype Float16                                                                           \
        --mma_tiler 128,128,512 --mma_inst_shape 128,128,64                                         \
        --cluster_shape_mn 2,4 --swizzle_size 1 --raster_order m                                    \
        --mnkl 8192,8192,1024,1

FP6 x FP8 (A=FP6, B=FP8):

.. code-block:: bash

    python dense_blockscaled_mxfp6_gemm_persistent.py                                               \
        --a_dtype Float6E3M2FN --b_dtype Float8E4M3FN                                               \
        --sf_dtype Float8E8M0FNU --sf_vec_size 32                                                   \
        --c_dtype Float16                                                                           \
        --mma_tiler 128,128,512 --mma_inst_shape 128,128,64                                         \
        --cluster_shape_mn 2,4 --swizzle_size 1 --raster_order m                                    \
        --mnkl 8192,8192,1024,1

FP4 x FP6 (A=FP4, B=FP6):

.. code-block:: bash

    python dense_blockscaled_mxfp6_gemm_persistent.py                                               \
        --a_dtype Float4E2M1FN --b_dtype Float6E3M2FN                                               \
        --sf_dtype Float8E8M0FNU --sf_vec_size 32                                                   \
        --c_dtype Float16                                                                           \
        --mma_tiler 128,128,512 --mma_inst_shape 128,128,64                                         \
        --cluster_shape_mn 2,4 --swizzle_size 1 --raster_order m                                    \
        --mnkl 8192,8192,1024,1

FP6 x FP4 (A=FP6, B=FP4):

.. code-block:: bash

    python dense_blockscaled_mxfp6_gemm_persistent.py                                               \
        --a_dtype Float6E3M2FN --b_dtype Float4E2M1FN                                               \
        --sf_dtype Float8E8M0FNU --sf_vec_size 32                                                   \
        --c_dtype Float16                                                                           \
        --mma_tiler 128,128,512 --mma_inst_shape 128,128,64                                         \
        --cluster_shape_mn 2,4 --swizzle_size 1 --raster_order m                                    \
        --mnkl 8192,8192,1024,1

Constraints:
* Supported A/B dtypes: FP6 (Float6E3M2FN, Float6E2M3FN), FP8 (Float8E4M3FN, Float8E5M2),
  or FP4 (Float4E2M1FN); exactly one operand must be FP6
  (use dense_blockscaled_gemm_persistent.py for FP8xFP8)
* All operands require K-major layout (a_major="k" / b_major="k")
* Mma tiler M must be 128, 256 or 512; MMA instruction shape M can be 128 or 256
* Mma tiler N and MMA instruction shape N must be 128 or 256
* Mma tiler K must be 512 and MMA instruction shape K must be 64 (8 MMAs per k-tile)
* B-reuse is enabled when (MMA tiler M // MMA instruction shape M) == 2
* Cluster shape M/N must be positive powers of 2, total cluster size <= 16
* Cluster shape M must be a multiple of 2 when MMA instruction shape M is 256 (.2CTA)
* FP6 operand contiguous dimension must be >= 48 B aligned
* FP4 operand contiguous dimension must be >= 32 B aligned
* FP8 operand contiguous dimension must be >= 16 B aligned

"""


def _is_fp6(dtype) -> bool:
    """Return True if dtype is a 6-bit floating-point type."""
    return dtype in {cutlass.Float6E3M2FN, cutlass.Float6E2M3FN}


def _is_fp4(dtype) -> bool:
    """Return True if dtype is a 4-bit floating-point type."""
    return dtype in {cutlass.Float4E2M1FN}


class _Mxfp6KTileCtx:
    """Full context for executing the 8 MMA phases of one K-tile.

    Handles FP6xFP6, FP8xFP6, FP6xFP8, FP4xFP6, and FP6xFP4 operand combinations.
    A and B each have independent pipeline stage handle lists.

    Owns:
      1. Per-operand pipeline stage handle lists (_a_bufs / _b_bufs), populated
         incrementally via set_a_stage / set_b_stage.
      2. Static coordinate tables for FP6 (circular buffer) and FP8 (simple).
      3. The split sA tensors (sA_bkeep / sA_breuse) when B-reuse is active.

    Phase schedule tables:

      phase              0    1    2    3    4    5    6    7
      FP6: k_subtile     0    3    6    1    4    7    2    5   (phase*3 % 8)
      FP6: cur_buf       0    0    0    1    1    1    2    2   (phase // 3)
      FP6: next_buf      0    0    1    1    1    2    2    2   ((phase+1) // 3)
      FP8: k_subtile     0    1    0    1    0    1    0    1   (phase % 2)
      FP8: buf           0    0    1    1    2    2    3    3   (phase // 2)
      SF idx             0    1    0    1    0    1    0    1   (phase % 2)

    Usage (FP6, both operands FP6):
        tile_ctx = _Mxfp6KTileCtx(a_dtype, b_dtype, fp6_buffer_full0, fp6_buffer_full0, sA, m, sf_k)
        # ... MMA 0, 1 ...
        tile_ctx.set_a_stage(1, fp6_buffer_full1); tile_ctx.set_b_stage(1, fp6_buffer_full1)
        # ... MMA 2, 3, 4 ...
        tile_ctx.set_a_stage(2, fp6_buffer_full2); tile_ctx.set_b_stage(2, fp6_buffer_full2)
        # ... MMA 5, 6, 7 ...
    """

    _FP6_K_SUBTILE = (0, 3, 6, 1, 4, 7, 2, 5)
    _FP6_CUR_IDX = (0, 0, 0, 1, 1, 1, 2, 2)
    _FP6_NEXT_IDX = (0, 0, 1, 1, 1, 2, 2, 2)
    # FP8: 128B per stage = 2 sub-MMAs of 64B each.
    # k-subtile index = byte_offset / 16: sub-MMA 0 starts at byte 0 (k_sub=0),
    # sub-MMA 1 starts at byte 64 (k_sub=4). The SMEM descriptor uses this as
    # its base pointer; the MMA instruction then reads 64 bytes from that base.
    _FP8_K_SUBTILE = (0, 4, 0, 4, 0, 4, 0, 4)
    # FP4: 64B per stage = 2 sub-MMAs of 32B each.
    # k-subtile index = byte_offset / 32: sub-MMA 0 starts at byte 0 (k_sub=0),
    # sub-MMA 1 starts at byte 32 (k_sub=1).
    _FP4_K_SUBTILE = (0, 1, 0, 1, 0, 1, 0, 1)
    # FP4 and FP8 share the same buffer/stage sequence: 4 stages, 2 MMAs each.
    _FP8_BUF_IDX = (0, 0, 1, 1, 2, 2, 3, 3)
    _SF_IDX = (0, 1, 0, 1, 0, 1, 0, 1)

    # Accumulator and SFA slice selectors for the two M-halves in the breuse scheme.
    # bkeep occupies the first M-half (index 0), breuse the second (index 1).
    ACC_BKEEP = (None, 0, 0)
    ACC_BREUSE = (None, 1, 0)
    SFA_BKEEP = (None, 0)
    SFA_BREUSE = (None, 1)

    def __init__(
        self,
        a_dtype,
        b_dtype,
        a_full0,
        b_full0,
        sA=None,
        m_per_cta=None,
        k_per_subtile=None,
    ):
        self._a_is_fp6 = _is_fp6(a_dtype)
        self._b_is_fp6 = _is_fp6(b_dtype)
        self._a_is_fp4 = _is_fp4(a_dtype)
        self._b_is_fp4 = _is_fp4(b_dtype)
        self._a_k_sub_bytes = 32 if _is_fp4(a_dtype) else 16
        # Up to 4 stage handles: FP6 uses indices 0-2, FP4/FP8 use 0-3.
        self._a_bufs = [a_full0, None, None, None]
        self._b_bufs = [b_full0, None, None, None]
        self.sA_bkeep = None
        self.sA_breuse = None
        if sA is not None:
            assert m_per_cta is not None and k_per_subtile is not None, (
                "_Mxfp6KTileCtx: m_per_cta and k_per_subtile must be provided "
                "when sA is given"
            )
            self._split_sA(sA, m_per_cta, k_per_subtile)

    def _split_sA(self, sA, m_per_cta: int, k_per_subtile: int) -> None:
        """Pre-compute the bkeep/breuse halves of the A SMEM tensor.

        All checks here are trace-time only: cute.size() returns a static Python
        int when the tensor layout is fully known at compile time, so the assert
        and the comparison never appear in the compiled kernel.
        """
        split = cute.tiled_divide(
            cute.coalesce(sA),
            cute.make_layout((m_per_cta, k_per_subtile)),
        )
        # cute.size() on a statically-shaped tensor returns a Python int here --
        # this assert runs at trace time and generates no IR.
        assert cute.size(split, mode=[1]) == 2, (
            f"_Mxfp6KTileCtx: sA split produced {cute.size(split, mode=[1])} "
            f"halves, expected 2 (bkeep + breuse). "
            f"Check m_per_cta={m_per_cta} and k_per_subtile={k_per_subtile} "
            f"match the sA layout."
        )
        self.sA_bkeep = cute.tiled_divide(
            split[((None, (0, None)), None, None)],
            cute.make_layout((m_per_cta, self._a_k_sub_bytes)),
        )
        self.sA_breuse = cute.tiled_divide(
            split[((None, (1, None)), None, None)],
            cute.make_layout((m_per_cta, self._a_k_sub_bytes)),
        )

    # --- stage registration ---

    def set_a_stage(self, stage_idx: int, handle) -> None:
        """Register a newly acquired A pipeline stage handle."""
        self._a_bufs[stage_idx] = handle

    def set_b_stage(self, stage_idx: int, handle) -> None:
        """Register a newly acquired B pipeline stage handle."""
        self._b_bufs[stage_idx] = handle

    # --- A operand coordinates ---

    def a_coord_cur(self, phase: int):
        """Current-buffer SMEM coordinate for operand A."""
        if cutlass.const_expr(self._a_is_fp6):
            return (
                None,
                0,
                self._FP6_K_SUBTILE[phase],
                self._a_bufs[self._FP6_CUR_IDX[phase]].index,
            )
        else:
            k_sub = (
                self._FP4_K_SUBTILE[phase]
                if cutlass.const_expr(self._a_is_fp4)
                else self._FP8_K_SUBTILE[phase]
            )
            return (
                None,
                0,
                k_sub,
                self._a_bufs[self._FP8_BUF_IDX[phase]].index,
            )

    def a_coord_next(self, phase: int):
        """Circular next-buffer SMEM coordinate for operand A (FP6 only)."""
        assert self._a_is_fp6, (
            "a_coord_next is only valid for FP6 A; FP4/FP8 have no circular next-buffer"
        )
        return (None, 0, 0, self._a_bufs[self._FP6_NEXT_IDX[phase]].index)

    # --- B operand coordinates ---

    def b_coord_cur(self, phase: int):
        """Current-buffer SMEM coordinate for operand B."""
        if cutlass.const_expr(self._b_is_fp6):
            return (
                None,
                0,
                self._FP6_K_SUBTILE[phase],
                self._b_bufs[self._FP6_CUR_IDX[phase]].index,
            )
        else:
            k_sub = (
                self._FP4_K_SUBTILE[phase]
                if cutlass.const_expr(self._b_is_fp4)
                else self._FP8_K_SUBTILE[phase]
            )
            return (
                None,
                0,
                k_sub,
                self._b_bufs[self._FP8_BUF_IDX[phase]].index,
            )

    def b_coord_next(self, phase: int):
        """Circular next-buffer SMEM coordinate for operand B (FP6 only)."""
        assert self._b_is_fp6, (
            "b_coord_next is only valid for FP6 B; FP4/FP8 have no circular next-buffer"
        )
        return (None, 0, 0, self._b_bufs[self._FP6_NEXT_IDX[phase]].index)

    # --- breuse A coordinates (1-D k_subtile form for split sA, dispatches on A dtype) ---

    def a_coord_cur_bkeep_breuse(self, phase: int):
        if cutlass.const_expr(self._a_is_fp6):
            a = self._a_bufs[self._FP6_CUR_IDX[phase]]
            return (None, self._FP6_K_SUBTILE[phase], a.index)
        else:
            a = self._a_bufs[self._FP8_BUF_IDX[phase]]
            k_sub = (
                self._FP4_K_SUBTILE[phase]
                if cutlass.const_expr(self._a_is_fp4)
                else self._FP8_K_SUBTILE[phase]
            )
            return (None, k_sub, a.index)

    def a_coord_next_bkeep_breuse(self, phase: int):
        if cutlass.const_expr(self._a_is_fp6):
            a = self._a_bufs[self._FP6_NEXT_IDX[phase]]
            return (None, 0, a.index)
        else:
            # FP4/FP8 have no circular spanning; next_src is unused
            a = self._a_bufs[self._FP8_BUF_IDX[phase]]
            k_sub = (
                self._FP4_K_SUBTILE[phase]
                if cutlass.const_expr(self._a_is_fp4)
                else self._FP8_K_SUBTILE[phase]
            )
            return (None, k_sub, a.index)

    # --- scale-factor coordinate ---

    def sf_coord(self, phase: int):
        return (None, None, self._SF_IDX[phase])


class Sm107Mxfp6BlockScaledPersistentDenseGemmKernel(
    Sm107BlockScaledPersistentDenseGemmKernel
):
    """Persistent batched GEMM (C = A x SFA @ B x SFB) for SM107 with FP6 data.

    Supports MXFP6, FP8xFP6, FP6xFP8, FP4xFP6, and FP6xFP4 using a
    two-pipeline warp-specialised design.  Exactly one operand must be FP6.

    :param sf_vec_size: Scale factor vector size (32).
    :type sf_vec_size: int
    :param mma_inst_shape: Shape of the MMA instruction (M, N, K). K must be 64.
    :type mma_inst_shape: Tuple[int, int, int]
    :param mma_tiler: Shape of the MMA tile (M, N, K). K must be 512 (8 x inst_K).
    :type mma_tiler: Tuple[int, int, int]
    :param cluster_shape_mn: CTA cluster dimensions (M, N).
    :type cluster_shape_mn: Tuple[int, int]

    :note: Supported A/B data types: FP6 (Float6E3M2FN, Float6E2M3FN),
        FP8 (Float8E4M3FN, Float8E5M2), or FP4 (Float4E2M1FN); exactly one must be FP6.
    :note: Supported SF data type: Float8E8M0FNU, sf_vec_size=32.
    :note: Supported accumulator data type: Float32.
    :note: Supported C data types: Float32, Float16, BFloat16.
    :note: Constraints:
        - MMA inst/tiler M must be 128 (1CTA) or 256 (2CTA); mma_inst_shape[0] == mma_tiler[0].
        - MMA inst/tiler N must be 128 or 256; mma_inst_shape[1] == mma_tiler[1].
        - mma_inst_shape[2] must be 64; mma_tiler[2] must be 512.
        - Cluster shape M/N must be power of 2, total size <= 16, each dim <= 4.
        - Cluster shape M must be multiple of 2 if mma_inst_shape[0] == 256.
        - All operands require K-major layout.

    Example:
        >>> gemm = Sm107Mxfp6BlockScaledPersistentDenseGemmKernel(
        ...     sf_vec_size=32,
        ...     mma_inst_shape=(256, 256, 64),
        ...     mma_tiler=(256, 256, 512),
        ...     cluster_shape_mn=(2, 4)
        ... )
        >>> gemm(a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, layouts, problem_mnkl, max_active_clusters, stream)
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        swizzle_size: int = 1,
        raster_order: str = "m",
    ):
        """Initializes static configuration for the SM107 MXFP6 circular-buffer GEMM.

        Interface matches Sm107BlockScaledPersistentDenseGemmKernel. For FP6 the K
        dimensions are fixed: mma_inst_shape[2]=64, mma_tiler[2]=512 (8 x inst_K).

        :param sf_vec_size: Scale factor vector size (32 for MXFP6).
        :type sf_vec_size: int
        :param mma_inst_shape: MMA instruction shape (M, N, K). K must be 64 for FP6.
        :type mma_inst_shape: Tuple[int, int, int]
        :param mma_tiler: MMA tile shape (M, N, K). K must be 512 for FP6.
        :type mma_tiler: Tuple[int, int, int]
        :param cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the CTA cluster.
        :type cluster_shape_mn: Tuple[int, int]
        :param swizzle_size: Swizzling size in units of cluster for improving L2 hit rate.
        :type swizzle_size: int
        :param raster_order: Rasterization order of clusters ('m' or 'n').
        :type raster_order: str
        """
        super().__init__(
            sf_vec_size,
            mma_inst_shape,
            mma_tiler,
            cluster_shape_mn,
            swizzle_size=swizzle_size,
            raster_order=raster_order,
        )

        # FP6 uses a split-TMA specialization: separate warps for A/B and SF loads.
        # Override warp IDs and thread count set by the parent.
        # fp6-pipe warp: in FP6 loads A+B data; in mixed loads only the FP6-operand data
        self.tma_fp6_warp_id = self.tma_warp_id  # warp 5
        # fp8-pipe warp: in FP6 loads SFA+SFB; in mixed loads FP4/FP8-operand data + all SF
        self.tma_fp8_warp_id = 6  # warp 6
        self.threads_per_cta = 32 * 7  # 4 epilogue + mma + fp6-warp + fp8-warp
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2

        # FP6 does not support TMA prefetch
        self.enable_breuse = True if mma_tiler[0] == mma_inst_shape[0] * 2 else False
        self.prefetch_enabled = False

    def _setup_attributes(self):
        """Set up kernel attributes that depend on runtime tensor inputs.

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B/SFA/SFB
        - Computing epilogue subtile
        - Setting up A/B/SFA/SFB/C stage counts in shared memory
        - Computing A/B/SFA/SFB/C shared memory layout
        """

        # In this example, we have a fixed strucuture that we follow:
        # 1. We want 2 MMAs to be covered by each SF buffer/stage
        # 2. As a result of it, we would have 4 SF buffer loads from SMEM to TMEM
        #    in each tile-k (8 MMAs)
        # 3. These s2t loads would happen deterministically at MMAs 1, 3, 5, and 7
        # 4. When we subtile SF for all the loads (g2s and s2t), we would consider
        #    a K-mode's subtile of mma_tiler.k / fp8_buffers_per_tile_k = 512 / 4 = 128
        # FP6 data: 8 MMAs x 48 B = 384 B = 3 x 128 B per k-tile
        # FP8 data (and SF): 8 MMAs x 64 B = 512 B = 4 x 128 B per k-tile
        # FP4 data: 8 MMAs x 32 B = 256 B = 4 x  64 B per k-tile
        fp6_buffers_per_tile_k = 3
        fp8_buffers_per_tile_k = 4
        fp4_buffers_per_tile_k = 4  # same stage count as FP8, smaller per-stage (64 B)
        self.fp6_buffers_per_tile_k = fp6_buffers_per_tile_k
        self.fp8_buffers_per_tile_k = fp8_buffers_per_tile_k
        self.fp4_buffers_per_tile_k = fp4_buffers_per_tile_k
        self.fp8_subtile_k = self.mma_tiler[2] // fp8_buffers_per_tile_k
        num_mma_per_tile_k = self.mma_tiler[2] // self.mma_inst_shape[2]
        self.num_mma_per_fp8_buffer = num_mma_per_tile_k // fp8_buffers_per_tile_k

        print(
            f"[DSL INFO] mma_tiler = {self.mma_tiler}, mma_inst_shape = {self.mma_inst_shape}"
        )
        print(
            f"[DSL INFO] Num MMAs per tile_k: {num_mma_per_tile_k}, "
            f"fp6/fp4/fp8 buffers per k-tile: "
            f"{fp6_buffers_per_tile_k}/{fp4_buffers_per_tile_k}/{fp8_buffers_per_tile_k}"
        )

        # Number of pipeline stages (buffers) per k-tile per operand.
        # FP4 uses the same count as FP8 (4) so data and SF advance in lock-step,
        # but its per-buffer byte size is halved (64 B instead of 128 B).
        self.a_buffers_per_tile_k = (
            fp6_buffers_per_tile_k
            if cutlass.const_expr(_is_fp6(self.a_dtype))
            else fp4_buffers_per_tile_k
            if cutlass.const_expr(_is_fp4(self.a_dtype))
            else fp8_buffers_per_tile_k
        )
        self.b_buffers_per_tile_k = (
            fp6_buffers_per_tile_k
            if cutlass.const_expr(_is_fp6(self.b_dtype))
            else fp4_buffers_per_tile_k
            if cutlass.const_expr(_is_fp4(self.b_dtype))
            else fp8_buffers_per_tile_k
        )
        # Total uint8 bytes per k-tile = 8 MMAs × (inst_K × dtype_width_bits / 8).
        # FP4: 8 × (64 × 4/8) = 256 B;  FP6: 8 × (64 × 6/8) = 384 B;
        # FP8: 8 × (64 × 8/8) = 512 B.
        self.a_num_bytes_per_tile_k = (
            num_mma_per_tile_k * self.mma_inst_shape[2] * self.a_dtype.width // 8
        )
        self.b_num_bytes_per_tile_k = (
            num_mma_per_tile_k * self.mma_inst_shape[2] * self.b_dtype.width // 8
        )
        # Per-buffer byte size (used for GMEM tiled_divide and SMEM layout).
        # FP4: 64 B;  FP6: 128 B;  FP8: 128 B.
        self.a_bytes_per_buffer = (
            self.a_num_bytes_per_tile_k // self.a_buffers_per_tile_k
        )
        self.b_bytes_per_buffer = (
            self.b_num_bytes_per_tile_k // self.b_buffers_per_tile_k
        )
        print(
            f"[DSL INFO] "
            f"A buffers/k-tile: {self.a_buffers_per_tile_k} "
            f"({self.a_bytes_per_buffer} B/buf, {self.a_num_bytes_per_tile_k} B total), "
            f"B buffers/k-tile: {self.b_buffers_per_tile_k} "
            f"({self.b_bytes_per_buffer} B/buf, {self.b_num_bytes_per_tile_k} B total)"
        )

        # Compute mma instruction shapes
        # (CTA_Tile_Shape_M, Round_Up(MMA_Tile_Shape_N, 128), MMA_Inst_Shape_K)
        self.mma_inst_shape_sfb = (
            self.mma_inst_shape[0] // (2 if self.use_2cta_instrs else 1),
            cute.round_up(self.mma_inst_shape[1], 128),
            self.mma_inst_shape[2],
        )
        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=(1, 1, 1),
            permutation_mnk=self._get_mma_permutation_mnk(),
        )

        dummy_tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        # Compute mma/cluster/tile shapes
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_layout_vmnk.shape[0]),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.mma_tiler_sfa = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            self.fp8_subtile_k,
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_sfb[0],
            self.mma_inst_shape_sfb[1],
            self.fp8_subtile_k,
        )

        # Compute cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (dummy_tiled_mma_sfb.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_sfb = cute.size(self.cluster_layout_sfb_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_sfb_mcast = self.num_mcast_ctas_sfb > 1

        # Compute epilogue subtile
        self.epi_tile = sm107_utils.compute_epilogue_tile_shape(
            tiled_mma.op,
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, num_load_stage, self.num_c_stage = (
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel._compute_stages(
                tiled_mma,
                self.mma_tiler,
                self.mma_tiler_sfa,
                self.mma_tiler_sfb,
                self.epi_tile,
                self.c_dtype,
                self.c_layout,
                self.sf_dtype,
                self.sf_vec_size,
                self.smem_capacity,
                self.occupancy,
                self.enable_breuse,
                self.a_dtype,
                self.b_dtype,
            )
        )
        # For simplicity, we have assumed the same number of load stages for both AB and SF pipelines
        self.num_ab_stage = num_load_stage
        self.num_sf_stage = num_load_stage

        print(
            f"[DSL INFO] stages: acc={self.num_acc_stage}, ab={self.num_ab_stage}, "
            f"sf={self.num_sf_stage}, c (epi)={self.num_c_stage}"
        )

        # Compute A/B/SFA/SFB/C shared memory layout
        # ((CTA_MMA_M, k_sub_bytes), 1, k_sub_count, num_ab_stage)
        self.a_smem_layout_staged = self.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
            self.a_dtype,
        )

        # ((CTA_MMA_M, k_sub_bytes), 1, k_sub_count, a_buffers_per_tile_k)
        self.a_smem_layout_staged_tma = self.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_buffers_per_tile_k,
            self.a_dtype,
        )

        # ((CTA_MMA_N, k_sub_bytes), 1, k_sub_count, num_ab_stage)
        self.b_smem_layout_staged = self.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.num_ab_stage,
            self.b_dtype,
        )

        # ((CTA_MMA_N, k_sub_bytes), 1, k_sub_count, b_buffers_per_tile_k)
        self.b_smem_layout_staged_tma = self.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.b_buffers_per_tile_k,
            self.b_dtype,
        )

        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler_sfa,
            self.sf_vec_size,
            self.num_sf_stage,
        )

        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler_sfb,
            self.sf_vec_size,
            self.num_sf_stage,
        )
        self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
        )

        self.tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                self.sfa_smem_layout_staged,
                mode=list(range(cute.rank(self.sfa_smem_layout_staged) - 1)),
            ),
        )
        self.tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                self.sfb_smem_layout_staged,
                mode=list(range(cute.rank(self.sfb_smem_layout_staged) - 1)),
            ),
        )

        # Each column entry in TMEM is 32-bit wide, and so we recast the TMEM layout
        # from its original data type to a 32-bit wide data type. Moreover, TMEM
        # addresses are expressed as (row << 16) | col, which in CUTE are expressed
        # as an affine transformation row * (1<<16) + col, which can be seen as a CUTE
        # layout of (row, col):(1<<16, 1). As a result, by masking out the upper 16 bits
        # (keeping only the lower 16 bits), we extract the cosize corresponding
        # to only the columns.
        self.num_sfa_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFA_layout))
            & 0x0000FFFF
        )
        self.num_sfb_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFB_layout))
            & 0x0000FFFF
        )
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        self.num_accumulator_tmem_cols = (
            self.cta_tile_shape_mnk[1]
            * self.num_acc_stage
            * (2 if self.enable_breuse else 1)
        )

    @staticmethod
    def _compute_stages(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: Tuple[int, int, int],
        mma_tiler_sfa: Tuple[int, int, int],
        mma_tiler_sfb: Tuple[int, int, int],
        epi_tile: cute.Tile,
        c_dtype: Type[cutlass.Numeric],
        c_layout: cutlass.tensor_utils.LayoutEnum,
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        smem_capacity: int,
        occupancy: int,
        with_breuse: bool,
        a_dtype: Type[cutlass.Numeric] = None,
        b_dtype: Type[cutlass.Numeric] = None,
    ) -> Tuple[int, int, int]:
        """Computes the number of stages for A/B/C operands based on heuristics.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :type mma_tiler_mnk: tuple[int, int, int]
        :param sf_tiler_mnk: The shape (M, N, K) of the SF tiler.
        :type sf_tiler_mnk: tuple[int, int, int]
        :param epi_tile: The epilogue tile shape.
        :type epi_tile: cute.Tile
        :param c_dtype: Data type of operand C (output).
        :type c_dtype: type[cutlass.Numeric]
        :param c_layout: Layout enum of operand C.
        :type c_layout: cutlass.tensor_utils.LayoutEnum
        :param sf_dtype: Data type of Scale factor.
        :type sf_dtype: type[cutlass.Numeric]
        :param sf_vec_size: Scale factor vector size.
        :type sf_vec_size: int
        :param smem_capacity: Total available shared memory capacity in bytes.
        :type smem_capacity: int
        :param occupancy: Target number of CTAs per SM (occupancy).
        :type occupancy: int

        :return: A tuple containing the computed number of stages for:
                 (ACC stages, Load operand stages (A/B, or SFA/SFB), C stages)
        :rtype: tuple[int, int, int]
        """
        # ACC stages
        # Note that here we have assumed the kernel have access to all TMEM capacity
        # associated with sm_107 architecture.
        num_acc_stage = 1 if (with_breuse and mma_tiler_mnk[1] in {192, 256}) else 2

        # Default C stages
        num_c_stage = 2

        # Calculate smem layout and size for one stage of A, B, SFA, SFB and C
        a_smem_layout_staged_one = (
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_smem_layout_a(
                tiled_mma,
                mma_tiler_mnk,
                1,  # a tmp 1 stage is provided
                a_dtype,
            )
        )

        b_smem_layout_staged_one = (
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_smem_layout_b(
                tiled_mma,
                mma_tiler_mnk,
                1,  # a tmp 1 stage is provided
                b_dtype,
            )
        )

        sfa_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mma_tiler_sfa,
            sf_vec_size,
            1,  # a tmp 1 stage is provided
        )
        sfb_smem_layout_staged_one = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mma_tiler_sfb,
            sf_vec_size,
            1,  # a tmp 1 stage is provided
        )

        c_smem_layout_staged_one = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )

        load_bytes_per_stage = (
            cute.size_in_bytes(cutlass.Uint8, a_smem_layout_staged_one)
            + cute.size_in_bytes(cutlass.Uint8, b_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfa_smem_layout_staged_one)
            + cute.size_in_bytes(sf_dtype, sfb_smem_layout_staged_one)
        )
        mbar_helpers_bytes = 1024
        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * num_c_stage

        # Calculate A/B/SFA/SFB stages:
        # Start with total smem per CTA (capacity / occupancy)
        # Subtract reserved bytes and initial C stages bytes
        # Divide remaining by bytes needed per A/B/SFA/SFB stage
        num_load_stage = (
            smem_capacity // occupancy - (mbar_helpers_bytes + c_bytes)
        ) // load_bytes_per_stage

        # Refine epilogue stages:
        # Calculate remaining smem after allocating for A/B/SFA/SFB stages and reserved bytes
        # Add remaining unused smem to epilogue
        num_c_stage += (
            smem_capacity
            - occupancy * load_bytes_per_stage * num_load_stage
            - occupancy * (mbar_helpers_bytes + c_bytes)
        ) // (occupancy * c_bytes_per_stage)

        return num_acc_stage, num_load_stage, num_c_stage

    @cute.jit
    def __call__(
        self,
        a_ptr: cute.Pointer,
        b_ptr: cute.Pointer,
        sfa_ptr: cute.Pointer,
        sfb_ptr: cute.Pointer,
        c_ptr: cute.Pointer,
        layouts: cutlass.Constexpr[
            Tuple[OperandMajorMode, OperandMajorMode, cutlass.tensor_utils.LayoutEnum]
        ],
        problem_mnkl: Tuple[int, int, int, int],
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute the GEMM operation in steps:
        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors
        - Compute grid size with regard to hardware constraints
        - Define shared storage for kernel
        - Launch the kernel synchronously

        Matches the pointer-based interface of Sm107BlockScaledPersistentDenseGemmKernel
        so that run_scaled_mm_with_emulated_dtype can drive compilation and execution.

        :param a_ptr: Pointer to input tensor A
        :param b_ptr: Pointer to input tensor B
        :param sfa_ptr: Pointer to scale factor tensor A
        :param sfb_ptr: Pointer to scale factor tensor B
        :param c_ptr: Pointer to output tensor C
        :param layouts: Constexpr tuple (a_major_mode, b_major_mode, c_layout)
        :param problem_mnkl: Problem dimensions (M, N, K, L)
        :param max_active_clusters: Maximum number of active clusters
        :param stream: CUDA stream for asynchronous execution
        :param epilogue_op: Optional elementwise lambda function to apply to the output tensor
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        """
        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: Type[cutlass.Numeric] = a_ptr.value_type
        self.b_dtype: Type[cutlass.Numeric] = b_ptr.value_type
        self.sf_dtype: Type[cutlass.Numeric] = sfa_ptr.value_type
        self.c_dtype: Type[cutlass.Numeric] = c_ptr.value_type

        m, n, k, l = problem_mnkl
        self.a_major_mode, self.b_major_mode, self.c_layout = layouts

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        # Construct A/B/C tensors from pointers and layouts
        a_layout = cute.make_ordered_layout((m, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.a_major_mode == OperandMajorMode.K):
            a_layout = cute.make_ordered_layout(
                (cute.assume(m, 32), k, l), order=(1, 0, 2)
            )
        b_layout = cute.make_ordered_layout((n, cute.assume(k, 32), l), order=(0, 1, 2))
        if cutlass.const_expr(self.b_major_mode == OperandMajorMode.K):
            b_layout = cute.make_ordered_layout(
                (cute.assume(n, 32), k, l), order=(1, 0, 2)
            )
        c_layout = cute.make_ordered_layout((cute.assume(m, 32), n, l), order=(0, 1, 2))
        if cutlass.const_expr(
            self.c_layout == cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        ):
            c_layout = cute.make_ordered_layout(
                (m, cute.assume(n, 32), l), order=(1, 0, 2)
            )
        a_tensor = cute.make_tensor(a_ptr, a_layout)
        b_tensor = cute.make_tensor(b_ptr, b_layout)
        c_tensor = cute.make_tensor(c_ptr, c_layout)

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            a_tensor.shape, self.sf_vec_size
        )
        sfa_tensor = cute.make_tensor(sfa_ptr, sfa_layout)

        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            b_tensor.shape, self.sf_vec_size
        )
        sfb_tensor = cute.make_tensor(sfb_ptr, sfb_layout)

        atom_layout_mnk = (1, 1, 1)
        permutation_mnk = self._get_mma_permutation_mnk()

        tiled_mma = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )

        tiled_mma.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma.set(tcgen05.Field.NEGATE_B, False)

        dummy_tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            atom_layout_mnk=atom_layout_mnk,
            permutation_mnk=permutation_mnk,
        )

        dummy_tiled_mma_sfb.set(tcgen05.Field.NEGATE_A, False)
        dummy_tiled_mma_sfb.set(tcgen05.Field.NEGATE_B, False)

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        # casting layout as uint8 for multicast
        a_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.a_smem_layout_staged_tma
        )
        a_tensor_uint8 = cute.recast_tensor(a_tensor, cutlass.Uint8)
        tma_atom_a, tma_tensor_a = cute.nvgpu.cpasync.make_tiled_tma_atom(
            a_op,
            a_tensor_uint8,
            a_smem_layout_tma_ready,
            (
                self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                self.a_num_bytes_per_tile_k,
            ),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for B
        b_op = sm100_utils.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        # casting layout as uint8 for multicast
        b_smem_layout_tma_ready = self.adapt_layout_for_tma_ab(
            self.b_smem_layout_staged_tma
        )

        b_tensor_uint8 = cute.recast_tensor(b_tensor, cutlass.Uint8)
        tma_atom_b, tma_tensor_b = cute.nvgpu.cpasync.make_tiled_tma_atom(
            b_op,
            b_tensor_uint8,
            b_smem_layout_tma_ready,
            (
                self.mma_tiler[1] // (2 if self.use_2cta_instrs else 1),
                self.b_num_bytes_per_tile_k,
            ),
            self.cluster_shape_mn[0] // cute.size(tiled_mma.thr_id.shape),
            internal_type=cutlass.Uint8,
        )

        # Setup TMA load for SFA
        sfa_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )

        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfa_op,
            sfa_tensor,
            self.adapt_layout_for_tma_sf(sfa_smem_layout),
            (
                self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                self.fp8_subtile_k,
            ),
            self.cluster_shape_mn[1],
            internal_type=cutlass.Int16,
        )

        # Setup TMA load for SFB
        sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.cpasync.make_tiled_tma_atom(
            sfb_op,
            sfb_tensor,
            self.adapt_layout_for_tma_sf(sfb_smem_layout),
            (self.mma_tiler_sfb[1], self.mma_tiler_sfb[2]),
            self.cluster_shape_mn[0],
            internal_type=cutlass.Int16,
        )

        # Setup TMA store for C
        epi_smem_layout = cute.select(
            self.c_smem_layout_staged,
            mode=list(range(cute.rank(self.c_smem_layout_staged) - 1)),
        )
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            c_tensor,
            epi_smem_layout,
            self.epi_tile,
        )

        a_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.a_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.a_smem_layout_staged_tma) - 1)),
            ),
        )
        b_copy_size = cute.size_in_bytes(
            cutlass.Uint8,
            cute.select(
                self.b_smem_layout_staged_tma,
                mode=list(range(cute.rank(self.b_smem_layout_staged_tma) - 1)),
            ),
        )
        sfa_copy_size = cute.size_in_bytes(
            self.sf_dtype,
            cute.select(
                self.sfa_smem_layout_staged,
                mode=list(range(cute.rank(self.sfa_smem_layout_staged) - 1)),
            ),
        )
        sfb_copy_size = cute.size_in_bytes(
            self.sf_dtype,
            cute.select(
                self.sfb_smem_layout_staged,
                mode=list(range(cute.rank(self.sfb_smem_layout_staged) - 1)),
            ),
        )
        # fp6-pipe tx: A+B data (FP6) | FP6-operand data only (mixed)
        # fp8-pipe tx: SFA+SFB (FP6) | FP8-operand data + SFA+SFB (mixed)
        a_is_fp6 = _is_fp6(self.a_dtype)
        b_is_fp6 = _is_fp6(self.b_dtype)
        if cutlass.const_expr(a_is_fp6 and b_is_fp6):
            self.num_tma_load_bytes_fp6_pipe = (
                a_copy_size + b_copy_size
            ) * atom_thr_size
            self.num_tma_load_bytes_fp8_pipe = (
                sfa_copy_size + sfb_copy_size
            ) * atom_thr_size
        elif cutlass.const_expr(not a_is_fp6):  # A=FP4/FP8, B=FP6
            self.num_tma_load_bytes_fp6_pipe = b_copy_size * atom_thr_size
            self.num_tma_load_bytes_fp8_pipe = (
                a_copy_size + sfa_copy_size + sfb_copy_size
            ) * atom_thr_size
        else:  # A=FP6, B=FP4/FP8
            self.num_tma_load_bytes_fp6_pipe = a_copy_size * atom_thr_size
            self.num_tma_load_bytes_fp8_pipe = (
                b_copy_size + sfa_copy_size + sfb_copy_size
            ) * atom_thr_size

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            c_tensor,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            max_active_clusters,
            self.swizzle_size,
            self.raster_order == "m",
        )

        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            fp6_pipe_full_mbar: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            fp6_pipe_empty_mbar: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            fp8_pipe_full_mbar: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            fp8_pipe_empty_mbar: cute.struct.MemRange[cutlass.Int64, self.num_sf_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Uint8, cute.cosize(self.b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.kernel(
            tiled_mma,
            dummy_tiled_mma_sfb,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_sfa,
            tma_tensor_sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tma_atom_c,
            tma_tensor_c,
            self.cluster_layout_vmnk,
            self.cluster_layout_sfb_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.tCtSFA_layout,
            self.tCtSFB_layout,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_sfa: cute.CopyAtom,
        mSFA_mkl: cute.Tensor,
        tma_atom_sfb: cute.CopyAtom,
        mSFB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        cluster_layout_sfb_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        tCtSFA_layout: cute.Layout,
        tCtSFB_layout: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_fp6_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_c)
        if warp_idx == self.tma_fp8_warp_id:
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, sfa+sfb full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # fp6-pipe: FP6 -> A+B data; mixed -> FP6-operand data only
        fp6_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        fp6_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        fp6_producer, fp6_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.fp6_pipe_full_mbar.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=fp6_producer_group,
            consumer_group=fp6_consumer_group,
            tx_count=self.num_tma_load_bytes_fp6_pipe,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

        # fp8-pipe: FP6 -> SFA+SFB; mixed -> FP8-operand data + SFA+SFB
        fp8_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        fp8_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        fp8_producer, fp8_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.fp8_pipe_full_mbar.data_ptr(),
            num_stages=self.num_sf_stage,
            producer_group=fp8_producer_group,
            consumer_group=fp8_consumer_group,
            tx_count=self.num_tma_load_bytes_fp8_pipe,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if use_2cta_instrs else 1
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
            arch=self.arch,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        #
        # Setup smem tensor A/B/SFA/SFB/C
        #
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )

        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)

        #
        # Compute multicast mask for A/B/SFA/SFB buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        sfa_full_mcast_mask = None
        sfb_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_sfb_vmnk, block_in_cluster_coord_sfb_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (BLK_M, BLK_K, m, k, l)
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_(
                (self.mma_tiler[0], self.mma_tiler[1], self.a_num_bytes_per_tile_k),
                (None, 0, None),
            ),
            (None, None, None),
        )
        # (BLK_N, BLK_K, n, k, l)
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_(
                (self.mma_tiler[0], self.mma_tiler[1], self.b_num_bytes_per_tile_k),
                (0, None, None),
            ),
            (None, None, None),
        )
        gSFA_mkl = cute.local_tile(
            mSFA_mkl,
            cute.slice_(
                (self.mma_tiler[0], self.mma_tiler[1], self.fp8_subtile_k),
                (None, 0, None),
            ),
            (None, None, None),
        )
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.mma_tiler_sfb, (0, None, None)),
            (None, None, None),
        )
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)

        # create tCgA_tmp
        tCgA_mkl_tmp = thr_mma.partition_A(gA_mkl)
        tCgA_layout = self.append_coalesce_layout(tCgA_mkl_tmp.layout)
        cta_tCgA = cute.make_tensor(tCgA_mkl_tmp.iterator, tCgA_layout)
        tCgA = cute.make_tensor(
            cta_tCgA.iterator,
            cute.tiled_divide(
                cta_tCgA.layout,
                (
                    self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                    self.a_bytes_per_buffer,
                ),
            ),
        )

        tCgB_nkl_tmp = thr_mma.partition_B(gB_nkl)
        tCgB_layout = self.append_coalesce_layout(tCgB_nkl_tmp.layout)
        cta_tCgB = cute.make_tensor(tCgB_nkl_tmp.iterator, tCgB_layout)
        tCgB = cute.make_tensor(
            cta_tCgB.iterator,
            cute.tiled_divide(
                cta_tCgB.layout,
                (
                    self.mma_tiler[1] // (2 if self.use_2cta_instrs else 1),
                    self.b_bytes_per_buffer,
                ),
            ),
        )

        tCgSFA_mkl_tmp = thr_mma.partition_A(gSFA_mkl)
        tCgSFA = tCgSFA_mkl_tmp

        thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
        tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)

        tCgC = thr_mma.partition_C(gC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )

        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 1),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 1),
        )

        # TMA partition for scale factor A
        sfa_cta_layout = a_cta_layout

        tAsSFA, tAgSFA = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfa,
            block_in_cluster_coord_vmnk[2],
            sfa_cta_layout,
            cute.group_modes(sSFA, 0, 3),
            cute.group_modes(tCgSFA, 0, 3),
        )

        tAsSFA_compact = cute.filter_zeros(tAsSFA)

        # TMA partition for scale factor B
        sfb_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
        )
        tBsSFB, tBgSFB = cute.nvgpu.cpasync.tma_partition(
            tma_atom_sfb,
            block_in_cluster_coord_sfb_vmnk[1],
            sfb_cta_layout,
            cute.group_modes(sSFB, 0, 3),
            cute.group_modes(tCgSFB, 0, 3),
        )
        tBsSFB_compact = cute.filter_zeros(tBsSFB)

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        #
        # Construct the scheduler
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # fp6-warp: loads FP6-operand data into fp6-pipe
        #   FP6         -- loads A (FP6) + B (FP6) combined in each stage
        #   A=FP8,B=FP6 -- loads B (FP6) only
        #   A=FP6,B=FP8 -- loads A (FP6) only
        #
        if warp_idx == self.tma_fp6_warp_id:
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                tAgA_slice = (
                    tAgA[
                        (
                            None,
                            None,
                            None,
                            mma_tile_coord_mnl[0],
                            None,
                            mma_tile_coord_mnl[2],
                        )
                    ]
                    if cutlass.const_expr(_is_fp6(self.a_dtype))
                    else None
                )
                tBgB_slice = (
                    tBgB[
                        (
                            None,
                            None,
                            None,
                            mma_tile_coord_mnl[1],
                            None,
                            mma_tile_coord_mnl[2],
                        )
                    ]
                    if cutlass.const_expr(_is_fp6(self.b_dtype))
                    else None
                )

                fp6_producer.reset()
                peek_fp6_empty = cutlass.Boolean(1)
                peek_fp6_empty = fp6_producer.try_acquire()

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    for buffer in cutlass.range(
                        self.fp6_buffers_per_tile_k, unroll_full=True
                    ):
                        fp6_empty = fp6_producer.acquire_and_advance(peek_fp6_empty)

                        if cutlass.const_expr(_is_fp6(self.a_dtype)):
                            cute.copy(
                                tma_atom_a,
                                cute.group_modes(
                                    tAgA_slice[(None, None, buffer, k_tile)], 0, 2
                                ),
                                tAsA[(None, fp6_empty.index)],
                                tma_bar_ptr=fp6_empty.barrier,
                                mcast_mask=a_full_mcast_mask,
                            )
                        if cutlass.const_expr(_is_fp6(self.b_dtype)):
                            cute.copy(
                                tma_atom_b,
                                cute.group_modes(
                                    tBgB_slice[(None, None, buffer, k_tile)], 0, 2
                                ),
                                tBsB[(None, fp6_empty.index)],
                                tma_bar_ptr=fp6_empty.barrier,
                                mcast_mask=b_full_mcast_mask,
                            )

                        peek_fp6_empty = cutlass.Boolean(1)
                        if not (
                            (k_tile == k_tile_cnt - 1)
                            and (buffer == self.fp6_buffers_per_tile_k - 1)
                        ):
                            peek_fp6_empty = fp6_producer.try_acquire()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            fp6_producer.tail()

        #
        #
        # fp8-warp: loads FP4/FP8-operand data (if any) + SFA + SFB into fp8-pipe
        #   FP6             -- loads SFA + SFB only
        #   A=FP4/FP8,B=FP6 -- loads A + SFA + SFB combined in each stage
        #   A=FP6,B=FP4/FP8 -- loads B + SFA + SFB combined in each stage
        #
        if warp_idx == self.tma_fp8_warp_id:
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                tAgSFA_slice = tAgSFA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                tBgSFB_slice = tBgSFB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]
                tAgA_slice = (
                    tAgA[
                        (
                            None,
                            None,
                            None,
                            mma_tile_coord_mnl[0],
                            None,
                            mma_tile_coord_mnl[2],
                        )
                    ]
                    if cutlass.const_expr(not _is_fp6(self.a_dtype))
                    else None
                )
                tBgB_slice = (
                    tBgB[
                        (
                            None,
                            None,
                            None,
                            mma_tile_coord_mnl[1],
                            None,
                            mma_tile_coord_mnl[2],
                        )
                    ]
                    if cutlass.const_expr(not _is_fp6(self.b_dtype))
                    else None
                )

                fp8_producer.reset()
                peek_fp8_empty = cutlass.Boolean(1)
                peek_fp8_empty = fp8_producer.try_acquire()

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    for stage in cutlass.range(
                        self.fp8_buffers_per_tile_k, unroll_full=True
                    ):
                        fp8_empty = fp8_producer.acquire_and_advance(peek_fp8_empty)

                        # FP8-operand data copy (only emitted when operand is FP8)
                        if cutlass.const_expr(not _is_fp6(self.a_dtype)):
                            cute.copy(
                                tma_atom_a,
                                cute.group_modes(
                                    tAgA_slice[(None, None, stage, k_tile)], 0, 2
                                ),
                                tAsA[(None, fp8_empty.index)],
                                tma_bar_ptr=fp8_empty.barrier,
                                mcast_mask=a_full_mcast_mask,
                            )
                        if cutlass.const_expr(not _is_fp6(self.b_dtype)):
                            cute.copy(
                                tma_atom_b,
                                cute.group_modes(
                                    tBgB_slice[(None, None, stage, k_tile)], 0, 2
                                ),
                                tBsB[(None, fp8_empty.index)],
                                tma_bar_ptr=fp8_empty.barrier,
                                mcast_mask=b_full_mcast_mask,
                            )

                        # SFA / SFB always loaded by fp8-warp
                        tAgSFA_compact = cute.filter_zeros(
                            tAgSFA_slice[
                                (None, k_tile * self.fp8_buffers_per_tile_k + stage)
                            ]
                        )
                        tBgSFB_compact = cute.filter_zeros(
                            tBgSFB_slice[
                                (None, k_tile * self.fp8_buffers_per_tile_k + stage)
                            ]
                        )
                        cute.copy(
                            tma_atom_sfa,
                            tAgSFA_compact,
                            tAsSFA_compact[(None, fp8_empty.index)],
                            tma_bar_ptr=fp8_empty.barrier,
                            mcast_mask=sfa_full_mcast_mask,
                        )
                        cute.copy(
                            tma_atom_sfb,
                            tBgSFB_compact,
                            tBsSFB_compact[(None, fp8_empty.index)],
                            tma_bar_ptr=fp8_empty.barrier,
                            mcast_mask=sfb_full_mcast_mask,
                        )

                        peek_fp8_empty = cutlass.Boolean(1)
                        if not (
                            k_tile == k_tile_cnt - 1
                            and stage == self.fp8_buffers_per_tile_k - 1
                        ):
                            peek_fp8_empty = fp8_producer.try_acquire()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            fp8_producer.tail()

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync for retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator/SFA/SFB tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # Make accumulator tmem tensor
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            sfa_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols,
                dtype=self.sf_dtype,
            )
            sfb_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + self.num_accumulator_tmem_cols + self.num_sfa_tmem_cols,
                dtype=self.sf_dtype,
            )
            tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)
            tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)

            #
            # Partition for S2T copy of SFA/SFB
            #
            (
                tiled_copy_s2t_sfa,
                tCsSFA_compact_s2t,
                tCtSFA_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFA, tCtSFA)
            (
                tiled_copy_s2t_sfb,
                tCsSFB_compact_s2t,
                tCtSFB_compact_s2t,
            ) = self.mainloop_s2t_copy_and_partition(sSFB, tCtSFB)

            #
            # Persistent tile scheduling loop
            #
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Get accumulator stage index
                acc_stage_index = acc_producer_state.index

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N, STAGE)
                tCtAcc = tCtAcc_base[(None, None, None, acc_stage_index)]

                fp6_consumer.reset()
                peek_fp6_full = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_fp6_full = fp6_consumer.try_wait()

                fp8_consumer.reset()
                peek_fp8_full = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_fp8_full = fp8_consumer.try_wait()

                is_first_iteration = True
                accumulate = False

                # Trace-time constants -- no runtime overhead.
                a_is_fp6 = _is_fp6(self.a_dtype)
                b_is_fp6 = _is_fp6(self.b_dtype)
                is_all_fp6 = a_is_fp6 and b_is_fp6

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    if is_leader_cta:

                        def s2t(fp8_stage_index):
                            coord = (None, None, None, None, fp8_stage_index)
                            cute.copy(
                                tiled_copy_s2t_sfa,
                                tCsSFA_compact_s2t[coord],
                                tCtSFA_compact_s2t,
                            )
                            cute.copy(
                                tiled_copy_s2t_sfb,
                                tCsSFB_compact_s2t[coord],
                                tCtSFB_compact_s2t,
                            )

                        # -- fp8-pipe stage 0: SF (+ FP8 data) for MMA 0, 1 -------
                        fp8_full0 = fp8_consumer.wait_and_advance(peek_fp8_full)
                        s2t(fp8_full0.index)
                        peek_fp8_full = fp8_consumer.try_wait()
                        # FP6: fp8-pipe is SF only -> release immediately after s2t
                        if cutlass.const_expr(is_all_fp6):
                            fp8_full0.release()

                        # -- fp6-pipe stage 0: FP6 data for MMA 0..2 --------------
                        fp6_full0 = fp6_consumer.wait_and_advance(peek_fp6_full)
                        peek_fp6_full = fp6_consumer.try_wait()

                        if is_first_iteration:
                            acc_pipeline.producer_acquire(acc_producer_state)
                            is_first_iteration = False

                        m_per_cta = self.mma_inst_shape[0] // (
                            2 if self.use_2cta_instrs else 1
                        )

                        # Route each operand to the correct pipe handle.
                        # FP6: both from fp6-pipe. Mixed: FP8-operand from fp8-pipe.
                        a_full0 = (
                            fp6_full0 if cutlass.const_expr(a_is_fp6) else fp8_full0
                        )
                        b_full0 = (
                            fp6_full0 if cutlass.const_expr(b_is_fp6) else fp8_full0
                        )
                        tile_ctx = _Mxfp6KTileCtx(
                            self.a_dtype,
                            self.b_dtype,
                            a_full0,
                            b_full0,
                            sA=sA if cutlass.const_expr(self.enable_breuse) else None,
                            m_per_cta=m_per_cta,
                            k_per_subtile=self.a_bytes_per_buffer,
                        )

                        def mma(idx):
                            nonlocal accumulate
                            self.make_desc_and_call_mma(
                                tiled_mma,
                                tCtAcc,
                                idx,
                                tile_ctx,
                                sA,
                                tCtSFA,
                                sB,
                                tCtSFB,
                                tCtAcc,
                                accumulate,
                            )
                            accumulate = True

                        mma(0)
                        mma(1)
                        # Mixed: fp8-pipe buf0 no longer needed after MMA 1
                        if cutlass.const_expr(not is_all_fp6):
                            fp8_full0.release()

                        # -- fp8-pipe stage 1: SF (+ FP8 data) for MMA 2, 3 -------
                        fp8_full1 = fp8_consumer.wait_and_advance(peek_fp8_full)
                        s2t(fp8_full1.index)
                        peek_fp8_full = fp8_consumer.try_wait()
                        if cutlass.const_expr(is_all_fp6):
                            fp8_full1.release()

                        # -- fp6-pipe stage 1: FP6 data for MMA 2..5 --------------
                        fp6_full1 = fp6_consumer.wait_and_advance(peek_fp6_full)
                        peek_fp6_full = fp6_consumer.try_wait()

                        a_full1 = (
                            fp6_full1 if cutlass.const_expr(a_is_fp6) else fp8_full1
                        )
                        b_full1 = (
                            fp6_full1 if cutlass.const_expr(b_is_fp6) else fp8_full1
                        )
                        tile_ctx.set_a_stage(1, a_full1)
                        tile_ctx.set_b_stage(1, b_full1)

                        # MMA 2: FP6 crosses buf0->buf1 (circular); FP4/FP8 uses buf1
                        mma(2)
                        fp6_full0.release()

                        mma(3)
                        if cutlass.const_expr(not is_all_fp6):
                            fp8_full1.release()

                        # -- fp8-pipe stage 2: SF (+ FP8 data) for MMA 4, 5 -------
                        fp8_full2 = fp8_consumer.wait_and_advance(peek_fp8_full)
                        s2t(fp8_full2.index)
                        peek_fp8_full = fp8_consumer.try_wait()
                        if cutlass.const_expr(is_all_fp6):
                            fp8_full2.release()

                        # FP8-operand stage 2 must be registered before mma(4)
                        # (_FP8_BUF_IDX[4] = 2; FP6 operand uses _FP6_CUR_IDX[4]=1, already set)
                        if cutlass.const_expr(not a_is_fp6):
                            tile_ctx.set_a_stage(2, fp8_full2)
                        if cutlass.const_expr(not b_is_fp6):
                            tile_ctx.set_b_stage(2, fp8_full2)

                        mma(4)

                        # -- fp6-pipe stage 2: FP6 data for MMA 5..7 --------------
                        fp6_full2 = fp6_consumer.wait_and_advance(peek_fp6_full)
                        peek_fp6_full = cutlass.Boolean(1)
                        if k_tile + 1 < k_tile_cnt:
                            peek_fp6_full = fp6_consumer.try_wait()

                        # FP6-operand stage 2 registered before mma(5)
                        # (_FP6_CUR_IDX[5]=1 already set; _FP6_NEXT_IDX[5]=2 needs buf2)
                        if cutlass.const_expr(a_is_fp6):
                            tile_ctx.set_a_stage(2, fp6_full2)
                        if cutlass.const_expr(b_is_fp6):
                            tile_ctx.set_b_stage(2, fp6_full2)

                        # MMA 5: FP6 crosses buf1->buf2; FP4/FP8 uses buf2
                        mma(5)
                        fp6_full1.release()
                        if cutlass.const_expr(not is_all_fp6):
                            fp8_full2.release()

                        # -- fp8-pipe stage 3: SF (+ FP8 data) for MMA 6, 7 -------
                        fp8_full3 = fp8_consumer.wait_and_advance(peek_fp8_full)
                        s2t(fp8_full3.index)
                        peek_fp8_full = cutlass.Boolean(1)
                        if k_tile + 1 < k_tile_cnt:
                            peek_fp8_full = fp8_consumer.try_wait()
                        if cutlass.const_expr(is_all_fp6):
                            fp8_full3.release()

                        # FP8-operand stage 3 (only when operand is FP8)
                        if cutlass.const_expr(not a_is_fp6):
                            tile_ctx.set_a_stage(3, fp8_full3)
                        if cutlass.const_expr(not b_is_fp6):
                            tile_ctx.set_b_stage(3, fp8_full3)

                        mma(6)
                        mma(7)
                        fp6_full2.release()
                        if cutlass.const_expr(not is_all_fp6):
                            fp8_full3.release()

                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)

        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sC = smem.allocate_tensor(
            element_type=self.c_dtype,
            layout=c_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=c_smem_layout_staged.inner,
        )

        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Bar sync for retrieve tensor memory ptr from shared memory
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )
            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage, producer_group=c_producer_group
            )

            epi_tiles_executed = cutlass.Int32(0)
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                #
                # Pre-advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                epi_tiles_executed += 1
                num_tiles_executed = epi_tiles_executed
                acc_consumer_state = utils.gemm.sm100.epilogue_tma_store(
                    self,
                    tidx,
                    warp_idx,
                    tma_atom_c,
                    tCtAcc_base,
                    sC,
                    tCgC,
                    epi_tile,
                    num_tiles_executed,
                    epilogue_op,
                    mma_tile_coord_mnl,
                    acc_consumer_state,
                    acc_pipeline,
                    c_pipeline,
                )

            # Wait for C store complete
            c_pipeline.producer_tail()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(acc_tmem_ptr)

    def make_desc_and_call_mma(
        self,
        tiled_mma: cute.TiledMma,
        d: cute.Tensor,
        mma_idx: int,
        tile_ctx: _Mxfp6KTileCtx,
        sA: cute.Tensor,
        sfA: cute.Tensor,
        sB: cute.Tensor,
        sfB: cute.Tensor,
        c: cute.Tensor,
        accumulate: bool = False,
    ) -> None:
        a_is_fp6 = _is_fp6(self.a_dtype)
        b_is_fp6 = _is_fp6(self.b_dtype)

        if cutlass.const_expr(self.enable_breuse):
            # B is the same tensor for both bkeep and breuse passes (B is reused).
            sB_cur = sB[tile_ctx.b_coord_cur(mma_idx)]
            sB_next = (
                sB[tile_ctx.b_coord_next(mma_idx)]
                if cutlass.const_expr(b_is_fp6)
                else None
            )
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_desc_and_call_mma_(
                tiled_mma.with_bkeep(accumulate=accumulate),
                d[tile_ctx.ACC_BKEEP],
                tile_ctx.sA_bkeep[tile_ctx.a_coord_cur_bkeep_breuse(mma_idx)],
                tile_ctx.sA_bkeep[tile_ctx.a_coord_next_bkeep_breuse(mma_idx)],
                sfA[tile_ctx.sf_coord(mma_idx)][tile_ctx.SFA_BKEEP],
                sB_cur,
                sB_next,
                sfB[tile_ctx.sf_coord(mma_idx)],
                c[tile_ctx.ACC_BKEEP],
                a_is_fp6=a_is_fp6,
                b_is_fp6=b_is_fp6,
            )
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_desc_and_call_mma_(
                tiled_mma.with_breuse(accumulate=accumulate),
                d[tile_ctx.ACC_BREUSE],
                tile_ctx.sA_breuse[tile_ctx.a_coord_cur_bkeep_breuse(mma_idx)],
                tile_ctx.sA_breuse[tile_ctx.a_coord_next_bkeep_breuse(mma_idx)],
                sfA[tile_ctx.sf_coord(mma_idx)][tile_ctx.SFA_BREUSE],
                sB_cur,
                sB_next,
                sfB[tile_ctx.sf_coord(mma_idx)],
                c[tile_ctx.ACC_BREUSE],
                a_is_fp6=a_is_fp6,
                b_is_fp6=b_is_fp6,
            )
        else:
            tiled_mma.set(tcgen05.Field.ACCUMULATE, accumulate)
            sA_cur = sA[tile_ctx.a_coord_cur(mma_idx)]
            sA_next = (
                sA[tile_ctx.a_coord_next(mma_idx)]
                if cutlass.const_expr(a_is_fp6)
                else None
            )
            sB_cur = sB[tile_ctx.b_coord_cur(mma_idx)]
            sB_next = (
                sB[tile_ctx.b_coord_next(mma_idx)]
                if cutlass.const_expr(b_is_fp6)
                else None
            )
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.make_desc_and_call_mma_(
                tiled_mma,
                d[tile_ctx.ACC_BKEEP],
                sA_cur,
                sA_next,
                sfA[tile_ctx.sf_coord(mma_idx)],
                sB_cur,
                sB_next,
                sfB[tile_ctx.sf_coord(mma_idx)],
                c[tile_ctx.ACC_BKEEP],
                a_is_fp6=a_is_fp6,
                b_is_fp6=b_is_fp6,
            )

    @staticmethod
    def make_desc_and_call_mma_(
        tiled_mma: cute.TiledMma,
        d: cute.Tensor,
        sA_cur: cute.Tensor,
        sA_next: cute.Tensor,  # None when A is FP4/FP8
        sfA: cute.Tensor,
        sB_cur: cute.Tensor,
        sB_next: cute.Tensor,  # None when B is FP4/FP8
        sfB: cute.Tensor,
        c: cute.Tensor,
        a_is_fp6: bool = True,
        b_is_fp6: bool = True,
    ) -> None:
        """Unified GEMM dispatch for FP6 (circular-buffer descriptor) and FP4/FP8 (single-buffer descriptor).

        FP6 operand: builds a circular SMEM descriptor from (cur, next) buffers.
        FP4/FP8 operand: builds a standard SMEM descriptor from cur only (no circular wrap).
        Both paths go through make_umma_smem_desc so the MMA instruction receives a
        properly typed descriptor, passing a raw Uint8 SMEM slice causes an LLVM cast
        failure during lowering.
        C and D may alias.  Caller is responsible for setting ACCUMULATE on tiled_mma.
        """
        if a_is_fp6:
            a_desc = tcgen05.make_umma_smem_desc(
                sA_cur.iterator,
                sA_cur.layout,
                "k" if tiled_mma.op.a_major_mode.name == "K" else "mn",
                next_src=sA_next.iterator,
            )
        else:
            a_desc = tcgen05.make_umma_smem_desc(
                sA_cur.iterator,
                sA_cur.layout,
                "k" if tiled_mma.op.a_major_mode.name == "K" else "mn",
            )
        a_tensor = cute.make_tensor(a_desc, cute.make_layout(1, stride=0))

        if b_is_fp6:
            b_desc = tcgen05.make_umma_smem_desc(
                sB_cur.iterator,
                sB_cur.layout,
                "k" if tiled_mma.op.b_major_mode.name == "K" else "mn",
                next_src=sB_next.iterator,
            )
        else:
            b_desc = tcgen05.make_umma_smem_desc(
                sB_cur.iterator,
                sB_cur.layout,
                "k" if tiled_mma.op.b_major_mode.name == "K" else "mn",
            )
        b_tensor = cute.make_tensor(b_desc, cute.make_layout(1, stride=0))

        return cute.mma_atom_call(
            tiled_mma,
            d,
            [a_tensor, cute.group_modes(sfA, 0, cute.rank(sfA))],
            [b_tensor, cute.group_modes(sfB, 0, cute.rank(sfB))],
            c,
        )

    # Utils
    @staticmethod
    def make_smem_layout_a(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
        a_dtype: Type[cutlass.Numeric],
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand A stored as Uint8.

        FP4 uses 32-byte K sub-tiles (k_sub_count=2, K_SW64 atom); all other dtypes
        use 16-byte K sub-tiles (k_sub_count=8, K_SW128 atom).  The atom kind is
        chosen via get_smem_layout_atom_ab so that MN-major layouts are also handled
        correctly (MN-major FP4 satisfies the UMMA_MN K>=32 constraint natively).

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int
        :param a_dtype: The data type of operand A (determines sub-tile size)
        :type a_dtype: Type[cutlass.Numeric]

        :return: SMEM layout for operand A
        :rtype: cute.Layout
        """
        is_k_major = tiled_mma.op.a_major_mode == OperandMajorMode.K
        m_per_cta = mma_tiler_mnk[0] // cute.size(tiled_mma.thr_layout_vmnk.shape[0])
        # FP4: 32-byte sub-tiles (2 per 64B stage); FP6/FP8: 16-byte (8 per 128B stage).
        k_sub_bytes = 32 if _is_fp4(a_dtype) else 16
        k_sub_count = 2 if _is_fp4(a_dtype) else 8
        atom_kind = sm100_utils.get_smem_layout_atom_ab(
            tiled_mma.op.a_major_mode,
            cutlass.Uint8,
            (m_per_cta, k_sub_bytes * k_sub_count),
        )
        return tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(atom_kind, cutlass.Uint8),
            cute.append(((m_per_cta, k_sub_bytes), 1, k_sub_count), num_stages),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )

    @staticmethod
    def make_smem_layout_b(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: cute.Tile,
        num_stages: int,
        b_dtype: Type[cutlass.Numeric],
    ) -> Union[cute.Layout, cute.ComposedLayout]:
        """
        Create the SMEM layout for operand B stored as Uint8.

        FP4 uses 32-byte K sub-tiles (k_sub_count=2, K_SW64 atom); all other dtypes
        use 16-byte K sub-tiles (k_sub_count=8, K_SW128 atom).  The atom kind is
        chosen via get_smem_layout_atom_ab so that MN-major layouts are also handled
        correctly (MN-major FP4 satisfies the UMMA_MN K>=32 constraint natively).

        :param tiled_mma: The tiled MMA atom
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The mma tiler shape (M, N, K)
        :type mma_tiler_mnk: cute.Tile
        :param num_stages: The number of stages
        :type num_stages: int
        :param b_dtype: The data type of operand B (determines sub-tile size)
        :type b_dtype: Type[cutlass.Numeric]

        :return: SMEM layout for operand B
        :rtype: cute.Layout
        """
        is_k_major = tiled_mma.op.b_major_mode == OperandMajorMode.K
        n_per_cta = mma_tiler_mnk[1] // cute.size(tiled_mma.thr_id.shape)
        # FP4: 32-byte sub-tiles (2 per 64B stage); FP6/FP8: 16-byte (8 per 128B stage).
        k_sub_bytes = 32 if _is_fp4(b_dtype) else 16
        k_sub_count = 2 if _is_fp4(b_dtype) else 8
        atom_kind = sm100_utils.get_smem_layout_atom_ab(
            tiled_mma.op.b_major_mode,
            cutlass.Uint8,
            (n_per_cta, k_sub_bytes * k_sub_count),
        )
        return tcgen05.tile_to_mma_shape(
            tcgen05.make_smem_layout_atom(atom_kind, cutlass.Uint8),
            cute.append(((n_per_cta, k_sub_bytes), 1, k_sub_count), num_stages),
            order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        )

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
    ):
        """Check that dtypes and sf_vec_size are valid for this kernel.

        Supported operand combinations (at least one operand must be FP6):
          - FP6 x FP6
          - FP8 x FP6
          - FP6 x FP8
          - FP4 x FP6
          - FP6 x FP4

        SF dtype is always Float8E8M0FNU and sf_vec_size is always 32.

        :param a_dtype: Data type of operand A.
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: Type[cutlass.Numeric]
        :param sf_dtype: Data type of the scale factor.
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: Scale factor vector size.
        :type sf_vec_size: int
        :param c_dtype: Data type of the output tensor C.
        :type c_dtype: Type[cutlass.Numeric]

        :raises testing.CantImplementError: If any constraint is violated.
        """
        _fp4_dtypes = {cutlass.Float4E2M1FN}
        _fp6_dtypes = {cutlass.Float6E3M2FN, cutlass.Float6E2M3FN}
        _fp8_dtypes = {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        _supported_dtypes = _fp4_dtypes | _fp6_dtypes | _fp8_dtypes

        if a_dtype not in _supported_dtypes:
            raise testing.CantImplementError(
                f"Unsupported a_dtype {a_dtype}. "
                f"Expected FP4 (Float4E2M1FN), FP6 (Float6E3M2FN, Float6E2M3FN), "
                f"or FP8 (Float8E4M3FN, Float8E5M2)"
            )
        if b_dtype not in _supported_dtypes:
            raise testing.CantImplementError(
                f"Unsupported b_dtype {b_dtype}. "
                f"Expected FP4 (Float4E2M1FN), FP6 (Float6E3M2FN, Float6E2M3FN), "
                f"or FP8 (Float8E4M3FN, Float8E5M2)"
            )
        # At least one operand must be FP6; FP4+FP4, FP4+FP8, FP8+FP4, FP8+FP8
        # all require a different kernel.
        if a_dtype not in _fp6_dtypes and b_dtype not in _fp6_dtypes:
            raise testing.CantImplementError(
                f"At least one operand must be FP6: a_dtype={a_dtype}, b_dtype={b_dtype}. "
                f"Use dense_blockscaled_gemm_persistent.py for FP8xFP8."
            )

        if sf_vec_size != 32:
            raise testing.CantImplementError(
                f"This kernel requires sf_vec_size==32, got {sf_vec_size}"
            )

        if sf_dtype != cutlass.Float8E8M0FNU:
            raise testing.CantImplementError(
                f"This kernel requires sf_dtype==Float8E8M0FNU, got {sf_dtype}"
            )

        _valid_c_dtypes = {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
        }
        if c_dtype not in _valid_c_dtypes:
            raise testing.CantImplementError(f"Unsupported c_dtype: {c_dtype}")

    @staticmethod
    def is_valid_layouts(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> None:
        """
        Check if layouts and dtypes are valid combinations.

        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major dimension of the A tensor
        :type a_major: str
        :param b_major: The major dimension of the B tensor
        :type b_major: str
        :param c_major: The major dimension of the C tensor
        :type c_major: str

        :raises testing.CantImplementError: If any layout/dtype combination is unsupported.
        """
        # FP6 operands require K-major layout.
        # FP4 and FP8 operands also require K-major layout.
        _fp6_dtypes = {cutlass.Float6E3M2FN, cutlass.Float6E2M3FN}
        if a_dtype in _fp6_dtypes and a_major != "k":
            raise testing.CantImplementError(
                f"FP6 A operand requires K-major layout, got '{a_major}'"
            )
        if b_dtype in _fp6_dtypes and b_major != "k":
            raise testing.CantImplementError(
                f"FP6 B operand requires K-major layout, got '{b_major}'"
            )
        if a_dtype not in _fp6_dtypes and a_major != "k":
            raise testing.CantImplementError(
                f"{a_dtype} A operand requires K-major layout, got '{a_major}'"
            )
        if b_dtype not in _fp6_dtypes and b_major != "k":
            raise testing.CantImplementError(
                f"{b_dtype} B operand requires K-major layout, got '{b_major}'"
            )

    @staticmethod
    def is_valid_mma_tiler(
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
    ):
        """Check that mma_inst_shape and mma_tiler are valid for MXFP6.

        :param mma_inst_shape: MMA instruction shape (M, N, K).
        :type mma_inst_shape: Tuple[int, int, int]
        :param mma_tiler: MMA tile shape (M, N, K).
        :type mma_tiler: Tuple[int, int, int]

        :raises testing.CantImplementError: If any constraint is violated.
        """
        # K constraints are fixed for FP6: inst_K=64, tiler_K = 8 x inst_K = 512
        if mma_inst_shape[2] != 64:
            raise testing.CantImplementError(
                f"MXFP6 requires mma_inst_shape[2]==64, got {mma_inst_shape[2]}"
            )
        if mma_tiler[2] != 512:
            raise testing.CantImplementError(
                f"MXFP6 requires mma_tiler[2]==512 (8 x inst_K=64), got {mma_tiler[2]}"
            )

        # M constraints
        if mma_inst_shape[0] not in [128, 256]:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_m: {mma_inst_shape[0]}, must be 128 (1CTA) or 256 (2CTA)"
            )

        # Checking for valid MMA tilers versus MMA instructions.
        b_reuse = mma_tiler[0] == mma_inst_shape[0] * 2
        if mma_tiler[0] != mma_inst_shape[0] and not b_reuse:
            raise testing.CantImplementError(
                f"Unsupported M-mode for the MMA tiler/instruction shape. "
                f"mma_tiler: {mma_tiler}, mma_inst_shape: {mma_inst_shape}"
            )

        # N constraints
        if mma_inst_shape[1] not in [128, 256]:
            raise testing.CantImplementError(
                f"Invalid mma_inst_shape_n: {mma_inst_shape[1]}, must be 128 or 256"
            )
        if mma_tiler[1] != mma_inst_shape[1]:
            raise testing.CantImplementError(
                f"mma_tiler[1]={mma_tiler[1]} must equal mma_inst_shape[1]={mma_inst_shape[1]} for MXFP6"
            )

    @staticmethod
    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        l: int,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
    ):
        """
        Check if the tensor alignment is valid

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param l: The number of columns in the C tensor
        :type l: int
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major axis of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major axis of the C tensor
        :type c_major: Literal["m", "n"]

        :raises testing.CantImplementError: If misaligned tensors.
        """

        def check_contigous_alignment(
            dtype, is_mode0_major, tensor_shape, alignment_bytes
        ):
            """Check if tensor satisfies the required byte alignment.

            :param dtype: Data type of the tensor
            :param is_mode0_major: Whether mode 0 is the major (contiguous) mode
            :param tensor_shape: Shape of the tensor (mode0, mode1, batch)
            :param alignment_bytes: Required alignment in bytes (e.g., 16 or 32)
            :return: True if alignment is satisfied
            """
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            # Calculate number of contiguous elements needed for alignment
            # alignment_bytes * 8 (bits per byte) / dtype.width (bits per element)
            num_contiguous_elements = alignment_bytes * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        # FP6 operands require 48B alignment (= 64 K-elements * 6 bits = one MMA K-extent).
        # FP4 operands require 32B alignment (= 64 K-elements * 4 bits = one MMA K-extent).
        # FP8 operands require 16B alignment (standard TMA granularity).
        def _align_bytes(dtype):
            if _is_fp6(dtype):
                return 48
            if _is_fp4(dtype):
                return 32
            return 16

        a_align = _align_bytes(a_dtype)
        b_align = _align_bytes(b_dtype)
        if (
            not check_contigous_alignment(a_dtype, a_major == "m", (m, k, l), a_align)
            or not check_contigous_alignment(
                b_dtype, b_major == "n", (n, k, l), b_align
            )
            or not check_contigous_alignment(c_dtype, c_major == "m", (m, n, l), 16)
        ):
            raise testing.CantImplementError("Invalid tensor alignment")

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
        sf_vec_size: int,
        mma_tiler: Tuple[int, int, int],
        mma_inst_shape: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """
        Check if the gemm can be implemented

        :param mnkl: The problem size as a tuple (M, N, K, L).
        :type mnkl: Tuple[int, int, int, int]
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param sf_dtype: The data type of the scale factor tensor
        :type sf_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major axis of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major axis of the C tensor
        :type c_major: Literal["m", "n"]
        :param sf_vec_size: The vector size
        :type sf_vec_size: int
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param mma_tiler: The (M, N, K) shape of the MMA tiler
        :type mma_tiler: Tuple[int, int, int]
        :param mma_inst_shape: The (M, N, K) shape of the MMA instruction
        :type mma_inst_shape: Tuple[int, int, int]
        :param cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster
        :type cluster_shape_mn: Tuple[int, int]
        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """

        try:
            # Skip unsupported types
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.is_valid_dtypes_and_scale_factor_vec_size(
                a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype
            )
            # Skip unsupported layouts
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.is_valid_layouts(
                a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )
            # Skip invalid mma tile shape
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.is_valid_mma_tiler(
                mma_inst_shape, mma_tiler
            )
            # Skip invalid cluster shape
            Sm107BlockScaledPersistentDenseGemmKernel.is_valid_cluster_shape(
                cluster_shape_mn, mma_inst_shape[0]
            )
            # Skip illegal problem shape for load/store alignment
            m, n, k, l = mnkl
            Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.is_valid_tensor_alignment(
                m, n, k, l, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
            )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True

    # Helper function for append and coalesce layout
    @staticmethod
    def append_coalesce_layout(layout):
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(part1, part2)
        result = cute.append(result, layout[3])
        result = cute.append(result, layout[4])
        result = cute.append(result, layout[5])
        return result

    @staticmethod
    def adapt_layout_for_tma_ab(composed_layout):
        layout = composed_layout.outer
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        part3 = cute.append(part2, layout[3])
        result = cute.append(part1, part3)
        return cute.make_composed_layout(
            composed_layout.inner, composed_layout.offset, result
        )

    @staticmethod
    def adapt_layout_for_tma_sf(layout):
        part1 = cute.coalesce(cute.append(layout[0][0], layout[1]))
        part2 = cute.coalesce(cute.append(layout[0][1], layout[2]))
        result = cute.append(cute.group_modes(part1, 0, cute.rank(part1)), part2)
        return result


def run(
    mnkl: Tuple[int, int, int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int],
    mma_inst_shape: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    swizzle_size: int = 1,
    raster_order: str = "m",
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """Run the SM107 MXFP6 GEMM using the same emulated-dtype harness as
    Sm107BlockScaledPersistentDenseGemmKernel.

    Delegates tensor creation, compilation, reference checking, and benchmarking
    to run_scaled_mm_with_emulated_dtype (imported from dense_blockscaled_gemm_persistent).
    """
    m, n, k, l = mnkl
    mma_tiler_mn = mma_tiler[:2]
    if not Sm107Mxfp6BlockScaledPersistentDenseGemmKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        sf_vec_size,
        mma_tiler,
        mma_inst_shape,
        cluster_shape_mn,
    ):
        raise cutlass.testing.CantImplementError(
            f"Unsupported testcase a_dtype={a_dtype}, b_dtype={b_dtype}, "
            f"sf_dtype={sf_dtype}, sf_vec_size={sf_vec_size}, c_dtype={c_dtype}, "
            f"mma_tiler={mma_tiler}, mma_inst_shape={mma_inst_shape}, "
            f"{cluster_shape_mn}, {m}, {n}, {k}, {l}, {a_major}, {b_major}, {c_major}"
        )

    gemm = Sm107Mxfp6BlockScaledPersistentDenseGemmKernel(
        sf_vec_size,
        mma_inst_shape,
        mma_tiler,
        cluster_shape_mn,
        swizzle_size,
        raster_order,
    )

    exec_time = run_scaled_mm_with_emulated_dtype(
        gemm,
        mnkl,
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        tolerance,
        warmup_iterations,
        iterations,
        skip_ref_check,
        use_cold_l2,
        init_normal,
        normal_mean,
        normal_std,
    )

    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of SM107 Rubin Persistent Dense MXFP6 BlockScaled GEMM."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(512, 512, 256, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 512),
        help="Mma tile shape (M, N, K) (comma-separated); K must be 512 for FP6",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma instruction shape (M, N, K) (comma-separated); K must be 64 for FP6",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 4),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=cutlass.Float6E3M2FN,
        help=(
            "A operand dtype. FP6: Float6E3M2FN, Float6E2M3FN. "
            "FP8: Float8E4M3FN, Float8E5M2. "
            "For A=FP8 and B=FP8 use dense_blockscaled_gemm_persistent.py instead."
        ),
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=cutlass.Float6E3M2FN,
        help=(
            "B operand dtype. FP6: Float6E3M2FN, Float6E2M3FN. "
            "FP8: Float8E4M3FN, Float8E5M2. "
            "For A=FP8 and B=FP8 use dense_blockscaled_gemm_persistent.py instead."
        ),
    )
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=32)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument(
        "--a_major",
        choices=["k"],
        type=str,
        default="k",
        help="A major mode. FP6 requires k-major; FP8 also uses k-major in this example.",
    )
    parser.add_argument(
        "--b_major",
        choices=["k"],
        type=str,
        default="k",
        help="B major mode. FP6 requires k-major; FP8 also uses k-major in this example.",
    )
    parser.add_argument("--c_major", choices=["n"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_order",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )
    testing.add_tensor_init_args(parser, supports_int_dtypes=False)

    args = parser.parse_args()

    testing.validate_tensor_init_args(args, parser)

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values (M, N, K)")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values (M, N, K)")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    run(
        args.mnkl,
        args.a_dtype,
        args.b_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler,
        args.mma_inst_shape,
        args.cluster_shape_mn,
        args.swizzle_size,
        args.raster_order,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
