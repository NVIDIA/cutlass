# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
A high-performance persistent grouped block-scaled GEMM (C_g = (A_g * SFA_g) * (B_g * SFB_g))
example for the NVIDIA Blackwell GeForce (SM120) architecture using CuTe DSL.

Supported operand and scale-factor combinations (via ``blockscaled_gemm_dispatch``):
    - NVFP4: (Float4E2M1FN, Float4E2M1FN, Float8E4M3FN, sf_vec_size=16),
      tile_shape_mnk in {(128, 128, 128), (128, 128, 256)}
    - MXFP4: (Float4E2M1FN, Float4E2M1FN, Float8E8M0FNU, sf_vec_size=32),
      tile_shape_mnk == (128, 128, 128)
    - MXFP8: (Float8E4M3FN/Float8E5M2, same, Float8E8M0FNU, sf_vec_size=32),
      tile_shape_mnk == (128, 128, 128)
    - Mixed FP4 x FP8: all 4 (Float4E2M1FN, Float8E4M3FN/Float8E5M2) and
      (Float8E4M3FN/Float8E5M2, Float4E2M1FN) pairs with
      (Float8E8M0FNU, sf_vec_size=32), tile_shape_mnk == (128, 128, 128)

Architecture overview (12 warps / 384 threads per CTA):
    - WG0 (warps 0..3, 232 regs/thread): MMA + epilogue on even tiles (0, 2, ...);
      warp 0 manages its own per-WG output tensormap slot (slot 4).
    - WG1 (warps 4..7, 232 regs/thread): MMA + epilogue on odd tiles (1, 3, ...);
      warp 4 manages its own per-WG output tensormap slot (slot 5).
    - WG2 (warps 8..11, 40 regs/thread):
      * warp 8: TMA load warp; updates per-group tensormaps for A/B/SFA/SFB
        (slots 0..3) and feeds the mainloop pipeline.
      * warp 9: dedicated grouped tile scheduler warp running
        ``StaticPersistentGroupTileScheduler`` and streaming 8-int32 tile packets
        through ``tile_info_pipeline`` to warps 0..8, keeping scheduler state out
        of the register-constrained MMA warpgroups.
      * warps 10..11: register-donor warps (decrease registers and return).

Example usage:

.. code-block:: bash

    python examples/python/CuTeDSL/cute/blackwell_geforce/kernel/blockscaled_grouped_gemm/grouped_blockscaled_gemm.py \
        --num_groups 4 \
        --problem_sizes_mnkl "(512,512,512,1),(256,768,384,1),(640,384,256,1),(128,256,128,1)" \
        --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN --sf_dtype Float8E4M3FN --sf_vec_size 16 \
        --c_dtype Float16 --tile_shape_mnk 128,128,128 --epi_tile 64,32
"""

import argparse
import functools
from inspect import isclass
from typing import List, Optional, Tuple, Type

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm120_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
import cutlass.utils.hopper_helpers as sm90_utils
from cutlass import testing
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack

try:
    from blackwell_geforce.kernel.blockscaled_gemm.blockscaled_gemm_dispatch import (
        FP4_SHIFT_BITS,
        make_ldmatrix_atom,
        make_sm120_blockscaled_mma_op,
    )
except ImportError:  # pragma: no cover - standalone script invocation
    import importlib.util
    from pathlib import Path

    _dispatch_path = (
        Path(__file__).resolve().parent.parent
        / "blockscaled_gemm"
        / "blockscaled_gemm_dispatch.py"
    )
    _spec = importlib.util.spec_from_file_location(
        "blockscaled_gemm_dispatch", _dispatch_path
    )
    _mod = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(_mod)
    FP4_SHIFT_BITS = _mod.FP4_SHIFT_BITS
    make_ldmatrix_atom = _mod.make_ldmatrix_atom
    make_sm120_blockscaled_mma_op = _mod.make_sm120_blockscaled_mma_op


def _align_up(val: int, align: int) -> int:
    return ((val + align - 1) // align) * align


class Sm120GroupedBlockScaledGemmKernel:
    """Persistent ping-pong grouped block-scaled GEMM kernel for SM120.

    :param sf_vec_size: Scale factor vector size (16 for NVFP4, 32 for MXFP4/MXFP8/mixed).
    :type sf_vec_size: int
    :param tile_shape_mnk: CTA tile shape (M, N, K).
    :type tile_shape_mnk: Tuple[int, int, int]
    :param epi_tile: Epilogue subtile shape (M, N).
    :type epi_tile: Tuple[int, int]
    :param acc_dtype: Accumulator data type (must be Float32).
    :type acc_dtype: Type[cutlass.Numeric]
    :param use_cached_problem_shapes: Enable double-buffered problem shape caching
        inside the tile scheduler warp.
    :type use_cached_problem_shapes: bool
    """

    bytes_per_tensormap = 128
    # Slots 0..3: A, B, SFA, SFB (owned by TMA load warp 8)
    # Slot 4: C for WG0 (owned by warp 0)
    # Slot 5: C for WG1 (owned by warp 4)
    num_tensormaps = 6
    num_sched_stage = 4
    # Packet layout: (is_valid, group_idx, tile_m, tile_n, m, n, k, k_tile_cnt)
    tile_info_elems = 8

    def __init__(
        self,
        sf_vec_size: int,
        tile_shape_mnk: Tuple[int, int, int] = (128, 128, 128),
        epi_tile: Tuple[int, int] = (64, 32),
        acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
        use_cached_problem_shapes: bool = True,
    ):
        self.acc_dtype = acc_dtype
        self.sf_vec_size = sf_vec_size
        self.cluster_shape_mnk = (1, 1, 1)
        self.tile_shape_mnk = tuple(tile_shape_mnk)
        self.epi_tile = tuple(epi_tile)
        self.use_cached_problem_shapes = use_cached_problem_shapes

        self.tiled_mma = None
        self.occupancy = 1
        self.num_mma_warps = 8
        self.tma_load_warp_id = self.num_mma_warps  # warp 8
        self.scheduler_warp_id = self.num_mma_warps + 1  # warp 9
        self.num_threads_per_warp = 32
        # 12 warps (384 threads): WG0 (0..3), WG1 (4..7), WG2 (8=DMA, 9=sched, 10..11=empty)
        self.threads_per_cta = 12 * self.num_threads_per_warp
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_120")

        self.ab_stage = None
        self.epi_stage = None
        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.sfa_smem_layout_staged = None
        self.sfb_smem_layout_staged = None
        self.epi_smem_layout_staged = None

        self.buffer_align_bytes = 1024
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=(self.num_mma_warps // 2) * self.num_threads_per_warp,
        )
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

    def _setup_attributes(self):
        mma_op, use_mxf8f6f4 = make_sm120_blockscaled_mma_op(
            self.a_dtype,
            self.b_dtype,
            self.acc_dtype,
            self.sf_dtype,
            self.sf_vec_size,
        )
        self.mixed_mode = self.a_dtype != self.b_dtype
        a_fp4_in_mixed = self.mixed_mode and self.a_dtype.width < 8
        b_fp4_in_mixed = self.mixed_mode and self.b_dtype.width < 8
        self.smem_alloc_a_dtype = cutlass.Int8 if a_fp4_in_mixed else self.a_dtype
        self.smem_alloc_b_dtype = cutlass.Int8 if b_fp4_in_mixed else self.b_dtype
        self.tma_internal_a_dtype = cutlass.Int8 if a_fp4_in_mixed else None
        self.tma_internal_b_dtype = cutlass.Int8 if b_fp4_in_mixed else None

        atom_shape = (2, 2, 1)
        atom_layout = cute.make_layout(atom_shape)
        permutation_mnk = sm120_utils.get_permutation_mnk(
            self.tile_shape_mnk, self.sf_vec_size, use_mxf8f6f4
        )
        self.tiled_mma = cute.make_tiled_mma(
            mma_op,
            atom_layout,
            permutation_mnk=permutation_mnk,
        )
        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

        sfa_smem_layout_per_stage = blockscaled_utils.sm120_make_smem_layout_sfa(
            self.tiled_mma,
            self.tile_shape_mnk,
            self.sf_vec_size,
            1,
        )
        sfb_smem_layout_per_stage = blockscaled_utils.sm120_make_smem_layout_sfb(
            self.tiled_mma,
            self.tile_shape_mnk,
            self.sf_vec_size,
            1,
        )

        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk,
            self.smem_alloc_a_dtype,
            self.smem_alloc_b_dtype,
            self.sf_dtype,
            sfa_smem_layout_per_stage,
            sfb_smem_layout_per_stage,
            self.epi_tile,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
        )
        if self.ab_stage <= 0 or self.epi_stage <= 0:
            raise ValueError(
                f"Insufficient shared memory on SM120 for tile={self.tile_shape_mnk}, "
                f"epi_tile={self.epi_tile}, a_dtype={self.a_dtype}, b_dtype={self.b_dtype}, "
                f"c_dtype={self.c_dtype} (ab_stage={self.ab_stage}, epi_stage={self.epi_stage})."
            )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.smem_alloc_a_dtype,
            self.a_layout,
            self.smem_alloc_b_dtype,
            self.b_layout,
            self.ab_stage,
            self.c_dtype,
            self.c_layout,
            self.epi_stage,
            self.sf_vec_size,
            self.tiled_mma,
        )

    @cute.jit
    def __call__(
        self,
        initial_a: cute.Tensor,
        initial_b: cute.Tensor,
        initial_c: cute.Tensor,
        initial_sfa: cute.Tensor,
        initial_sfb: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        problem_shape_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_address_sfasfb: cute.Tensor,
        total_num_clusters: cutlass.Constexpr[int],
        tensormap_cute_tensor: cute.Tensor,
        max_active_clusters: cutlass.Constexpr[int],
        stream: cuda.CUstream,
    ):
        """Setup TMA descriptors, shared storage, and launch the grouped GEMM kernel."""
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.c_dtype = initial_c.element_type
        self.sf_dtype = initial_sfa.element_type

        self.a_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_a)
        self.b_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_b)
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_c)

        self._setup_attributes()

        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_a.shape, self.sf_vec_size
        )
        initial_sfa_tensor = cute.make_tensor(initial_sfa.iterator, sfa_layout)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_b.shape, self.sf_vec_size
        )
        initial_sfb_tensor = cute.make_tensor(initial_sfb.iterator, sfb_layout)

        tma_atom_a, tma_tensor_a = self._make_tma_atoms_and_tensors(
            initial_a,
            self.a_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            1,
            internal_type=self.tma_internal_a_dtype,
        )
        tma_atom_b, tma_tensor_b = self._make_tma_atoms_and_tensors(
            initial_b,
            self.b_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            1,
            internal_type=self.tma_internal_b_dtype,
        )
        tma_atom_sfa, tma_tensor_sfa = self._make_tma_atoms_and_tensors(
            initial_sfa_tensor,
            self.sfa_smem_layout_staged,
            (self.tile_shape_mnk[0], self.tile_shape_mnk[2]),
            1,
            internal_type=cutlass.Int16,
        )
        tma_atom_sfb, tma_tensor_sfb = self._make_tma_atoms_and_tensors(
            initial_sfb_tensor,
            self.sfb_smem_layout_staged,
            (self.tile_shape_mnk[1], self.tile_shape_mnk[2]),
            1,
            internal_type=cutlass.Int16,
        )
        tma_atom_c, tma_tensor_c = self._make_tma_store_atoms_and_tensors(
            initial_c,
            self.epi_smem_layout_staged,
            self.epi_tile,
        )

        tile_sched_params, grid = self._compute_grid(
            total_num_clusters,
            max_active_clusters,
        )

        self.size_tensormap_in_i64 = self.num_tensormaps * self.bytes_per_tensormap // 8

        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int64, self.size_tensormap_in_i64],
                128,
            ]
            tile_info: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Int32, self.tile_info_elems * self.num_sched_stage
                ],
                16,
            ]
            mainloop_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.ab_stage * 2
            ]
            tile_info_pipeline_array_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_sched_stage * 2
            ]
            # PipelineOrder(depth=2, length=2) allocates depth * length = 4 mbarriers
            math_wg_order_barrier_array_ptr: cute.struct.MemRange[cutlass.Int64, 4]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_a_dtype, cute.cosize(self.a_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.smem_alloc_b_dtype, cute.cosize(self.b_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sSFA: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfa_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sSFB: cute.struct.Align[
                cute.struct.MemRange[
                    self.sf_dtype, cute.cosize(self.sfb_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype, cute.cosize(self.epi_smem_layout_staged)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        self.kernel(
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
            self.tiled_mma,
            self.cta_layout_mnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
            tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensor_address_sfasfb,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=[1, 1, 1],
            stream=stream,
            max_number_threads=[self.threads_per_cta, 1, 1],
            min_blocks_per_mp=1,
        )
        return

    @cute.jit
    def advance(self, state: pipeline.PipelineState, iterations: cutlass.Int32):
        """Advance a circular pipeline state by an arbitrary non-negative count."""
        total = state._index + iterations
        if ((total // state.stages) & 1) == 1:
            state._phase ^= 1
        state._index = total % state.stages
        state._count += iterations
        return state

    @cute.jit
    def make_and_init_order_barrier(self, order_mbar_ptr, group_id):
        stages_per_math_wg = 2
        return pipeline.PipelineOrder.create(
            barrier_storage=order_mbar_ptr,
            depth=stages_per_math_wg,
            length=2,
            group_id=group_id,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                128,
            ),
            defer_sync=True,
        )

    @cute.jit
    def _consume_tile_info(
        self,
        tile_info_pipeline: pipeline.PipelineAsync,
        tile_info_consumer_state: pipeline.PipelineState,
        sTile_info: cute.Tensor,
    ) -> Tuple[
        pipeline.PipelineState,
        cutlass.Boolean,
        cutlass.Int32,
        cutlass.Int32,
        cutlass.Int32,
        cutlass.Int32,
        cutlass.Int32,
        cutlass.Int32,
        cutlass.Int32,
    ]:
        """Consume one tile packet from ``sTile_info`` and release the pipeline slot."""
        tile_info_pipeline.consumer_wait(tile_info_consumer_state)
        cur_sTile = sTile_info[(None, tile_info_consumer_state.index)]
        work_tile_info = cute.make_rmem_tensor(cur_sTile.shape, cur_sTile.element_type)
        cute.autovec_copy(cur_sTile, work_tile_info)
        tile_info_pipeline.consumer_release(tile_info_consumer_state)
        tile_info_consumer_state.advance()
        is_valid = work_tile_info[0] == 1
        return (
            tile_info_consumer_state,
            is_valid,
            work_tile_info[1],
            work_tile_info[2],
            work_tile_info[3],
            work_tile_info[4],
            work_tile_info[5],
            work_tile_info[6],
            work_tile_info[7],
        )

    @cute.jit
    def _produce_tile_info(
        self,
        tile_info_pipeline: pipeline.PipelineAsync,
        tile_info_producer_state: pipeline.PipelineState,
        sTile_info: cute.Tensor,
        work_tile,
    ) -> pipeline.PipelineState:
        """Write one tile packet to ``sTile_info`` and commit the pipeline slot."""
        tile_info_pipeline.producer_acquire(tile_info_producer_state)
        with cute.arch.elect_one():
            cur_sTile_info = sTile_info[(None, tile_info_producer_state.index)]
            cur_sTile_info[0] = cutlass.Int32(work_tile.is_valid_tile)
            cur_sTile_info[1] = work_tile.group_search_result.group_idx
            cur_sTile_info[2] = work_tile.group_search_result.cta_tile_idx_m
            cur_sTile_info[3] = work_tile.group_search_result.cta_tile_idx_n
            cur_sTile_info[4] = work_tile.group_search_result.problem_shape_m
            cur_sTile_info[5] = work_tile.group_search_result.problem_shape_n
            cur_sTile_info[6] = work_tile.group_search_result.problem_shape_k
            cur_sTile_info[7] = work_tile.group_search_result.cta_tile_count_k
        cute.arch.sync_warp()
        tile_info_pipeline.producer_commit(tile_info_producer_state)
        tile_info_producer_state.advance()
        return tile_info_producer_state

    @cute.jit
    def make_tensor_abc_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        strides_abc: cute.Tensor,
        tensor_address_abc: cute.Tensor,
        tensor_index: int,
    ) -> cute.Tensor:
        """Construct a group-specific GMEM tensor view for A (0), B (1), or C (2)."""
        ptr_i64 = tensor_address_abc[(group_idx, tensor_index)]
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(
                f"dtype must be a subclass of cutlass.Numeric, got {type(dtype)}"
            )
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cutlass.AddressSpace.gmem, assumed_align=16
        )

        strides_tensor_gmem = strides_abc[(group_idx, tensor_index, None)]
        strides_tensor_reg = cute.make_rmem_tensor(
            cute.make_layout(2),
            strides_abc.element_type,
        )
        cute.autovec_copy(strides_tensor_gmem, strides_tensor_reg)
        stride_0 = strides_tensor_reg[0]
        stride_1 = strides_tensor_reg[1]
        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        if cutlass.const_expr(tensor_index == 0):
            m = problem_shape_mnk[0]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, k, c1), stride=(stride_0, stride_1, c0)),
            )
        elif cutlass.const_expr(tensor_index == 1):
            n = problem_shape_mnk[1]
            k = problem_shape_mnk[2]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((n, k, c1), stride=(stride_0, stride_1, c0)),
            )
        else:
            m = problem_shape_mnk[0]
            n = problem_shape_mnk[1]
            return cute.make_tensor(
                tensor_gmem_ptr,
                cute.make_layout((m, n, c1), stride=(stride_0, stride_1, c0)),
            )

    @cute.jit
    def make_tensor_sfasfb_for_tensormap_update(
        self,
        group_idx: cutlass.Int32,
        dtype: Type[cutlass.Numeric],
        problem_shape_mnk: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        tensor_address_sfasfb: cute.Tensor,
        tensor_index: int,
    ) -> cute.Tensor:
        """Construct a group-specific GMEM scale-factor tensor view for SFA (0) or SFB (1)."""
        ptr_i64 = tensor_address_sfasfb[(group_idx, tensor_index)]
        if cutlass.const_expr(
            not isclass(dtype) or not issubclass(dtype, cutlass.Numeric)
        ):
            raise TypeError(
                f"dtype must be a subclass of cutlass.Numeric, got {type(dtype)}"
            )
        tensor_gmem_ptr = cute.make_ptr(
            dtype, ptr_i64, cutlass.AddressSpace.gmem, assumed_align=16
        )

        c1 = cutlass.Int32(1)
        if cutlass.const_expr(tensor_index == 0):
            m = problem_shape_mnk[0]
            k = problem_shape_mnk[2]
            sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
                (m, k, c1), self.sf_vec_size
            )
            return cute.make_tensor(tensor_gmem_ptr, sfa_layout)
        else:
            n = problem_shape_mnk[1]
            k = problem_shape_mnk[2]
            sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
                (n, k, c1), self.sf_vec_size
            )
            return cute.make_tensor(tensor_gmem_ptr, sfb_layout)

    @cute.kernel
    def kernel(
        self,
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
        tiled_mma: cute.TiledMma,
        cta_layout_mnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        epi_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr[int],
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        ptrs_sfasfb: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """GPU device kernel performing SM120 persistent ping-pong grouped block-scaled GEMM."""
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        bidx, bidy, bidz = cute.arch.block_idx()
        bid = cute.arch.block_idx()
        grid_dim = cute.arch.grid_dim()

        if warp_idx == self.tma_load_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_sfa)
            cpasync.prefetch_descriptor(tma_atom_sfb)
            cpasync.prefetch_descriptor(tma_atom_c)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cluster_coord_mnk = cta_layout_mnk.get_flat_coord(cta_rank_in_cluster)

        a_smem_layout = cute.slice_(a_smem_layout_staged, (None, None, 0))
        b_smem_layout = cute.slice_(b_smem_layout_staged, (None, None, 0))
        sfa_smem_layout = cute.slice_(sfa_smem_layout_staged, (None, None, 0))
        sfb_smem_layout = cute.slice_(sfb_smem_layout_staged, (None, None, 0))
        tma_copy_bytes = (
            cute.size_in_bytes(self.a_dtype, a_smem_layout)
            + cute.size_in_bytes(self.b_dtype, b_smem_layout)
            + cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
            + cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        )

        # Allocate shared storage and initialize pipelines
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        tensormap_smem_ptr = storage.tensormap_buffer.data_ptr()
        stride_tm_i64 = self.bytes_per_tensormap // 8
        tensormap_a_smem_ptr = tensormap_smem_ptr
        tensormap_b_smem_ptr = tensormap_a_smem_ptr + stride_tm_i64
        tensormap_sfa_smem_ptr = tensormap_b_smem_ptr + stride_tm_i64
        tensormap_sfb_smem_ptr = tensormap_sfa_smem_ptr + stride_tm_i64

        sTile_info = storage.tile_info.get_tensor(
            cute.make_layout(
                (self.tile_info_elems, self.num_sched_stage),
                stride=(1, self.tile_info_elems),
            )
        )

        mainloop_pipeline_array_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()
        tile_info_pipeline_array_ptr = storage.tile_info_pipeline_array_ptr.data_ptr()
        math_wg_order_barrier_array_ptr = (
            storage.math_wg_order_barrier_array_ptr.data_ptr()
        )

        mainloop_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread
        )
        mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, self.num_mma_warps // 2
        )
        cta_layout_vmnk = cute.make_layout((1, *cta_layout_mnk.shape))
        mainloop_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self.ab_stage,
            producer_group=mainloop_pipeline_producer_group,
            consumer_group=mainloop_pipeline_consumer_group,
            tx_count=tma_copy_bytes,
            barrier_storage=mainloop_pipeline_array_ptr,
            cta_layout_vmnk=cta_layout_vmnk,
            defer_sync=True,
        )

        # Active tile-info consumers: 8 MMA warps + 1 TMA load warp = 288 threads
        num_tile_info_consumers = (self.num_mma_warps + 1) * self.num_threads_per_warp
        tile_info_pipeline = pipeline.PipelineAsync.create(
            barrier_storage=tile_info_pipeline_array_ptr,
            num_stages=self.num_sched_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_threads_per_warp
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_tile_info_consumers
            ),
            defer_sync=True,
        )

        warp_group_idx = cute.arch.make_warp_uniform(tidx // 128)
        math_wg_order_barrier = self.make_and_init_order_barrier(
            math_wg_order_barrier_array_ptr, warp_group_idx
        )
        cute.arch.mbarrier_init_fence()
        math_wg_order_state = math_wg_order_barrier.state

        # Shared memory tensors
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )
        sC = storage.sC.get_tensor(
            epi_smem_layout_staged.outer, swizzle=epi_smem_layout_staged.inner
        )
        sSFA = storage.sSFA.get_tensor(sfa_smem_layout_staged)
        sSFB = storage.sSFB.get_tensor(sfb_smem_layout_staged)

        # Coordinate tensors for TMA load / store
        gA_mkl = cute.local_tile(
            mA_mkl,
            cute.slice_(self.tile_shape_mnk, (None, 0, None)),
            (None, None, None),
        )
        gB_nkl = cute.local_tile(
            mB_nkl,
            cute.slice_(self.tile_shape_mnk, (0, None, None)),
            (None, None, None),
        )
        gSFA_mkl = cute.local_tile(
            mSFA_mkl,
            cute.slice_(self.tile_shape_mnk, (None, 0, None)),
            (None, None, None),
        )
        gSFB_nkl = cute.local_tile(
            mSFB_nkl,
            cute.slice_(self.tile_shape_mnk, (0, None, None)),
            (None, None, None),
        )
        gC_mnl = cute.local_tile(
            mC_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )

        # Partition TMA loads
        a_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (0, None, 0)).shape)
        a_cta_crd = cluster_coord_mnk[1]
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sA, 0, 2),
            cute.group_modes(gA_mkl, 0, 2),
        )

        b_cta_layout = cute.make_layout(cute.slice_(cta_layout_mnk, (None, 0, 0)).shape)
        b_cta_crd = cluster_coord_mnk[0]
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sB, 0, 2),
            cute.group_modes(gB_nkl, 0, 2),
        )

        tAsSFA, tAgSFA = cpasync.tma_partition(
            tma_atom_sfa,
            a_cta_crd,
            a_cta_layout,
            cute.group_modes(sSFA, 0, 2),
            cute.group_modes(gSFA_mkl, 0, 2),
        )
        tAsSFA = cute.filter_zeros(tAsSFA)
        tAgSFA = cute.filter_zeros(tAgSFA)

        tBsSFB, tBgSFB = cpasync.tma_partition(
            tma_atom_sfb,
            b_cta_crd,
            b_cta_layout,
            cute.group_modes(sSFB, 0, 2),
            cute.group_modes(gSFB_nkl, 0, 2),
        )
        tBsSFB = cute.filter_zeros(tBsSFB)
        tBgSFB = cute.filter_zeros(tBgSFB)

        # Per-CTA tensormap workspace pointers in GMEM
        tensormap_workspace_idx = (
            bidz * grid_dim[1] * grid_dim[0] + bidy * grid_dim[0] + bidx
        )
        tensormap_manager = cutlass.tensor_utils.TensorMapManager(
            cutlass.tensor_utils.TensorMapUpdateMode.SMEM,
            self.bytes_per_tensormap,
        )
        tensormap_a_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 0, None)].iterator
        )
        tensormap_b_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 1, None)].iterator
        )
        tensormap_sfa_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 2, None)].iterator
        )
        tensormap_sfb_gmem_ptr = tensormap_manager.get_tensormap_ptr(
            tensormaps[(tensormap_workspace_idx, 3, None)].iterator
        )

        # Ensure all mbarriers are visible before warps diverge
        cute.arch.sync_threads()

        # /////////////////////////////////////////////////////////////////////
        #  WG2: DMA Warp (8), Scheduler Warp (9), Empty Register Donors (10..11)
        # /////////////////////////////////////////////////////////////////////
        if warp_idx >= self.tma_load_warp_id:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

            if warp_idx == self.scheduler_warp_id:
                tile_sched = utils.StaticPersistentGroupTileScheduler.create(
                    tile_sched_params,
                    bid,
                    grid_dim,
                    self.tile_shape_mnk,
                    utils.create_initial_search_state(),
                    group_count,
                    problem_sizes_mnkl,
                    use_cached_problem_shapes=self.use_cached_problem_shapes,
                )
                tile_sched.prefetch_problem_shapes()
                work_tile = tile_sched.initial_work_tile_info()

                tile_info_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_sched_stage
                )

                # Emit initial tile (valid or terminating invalid tile)
                tile_info_producer_state = self._produce_tile_info(
                    tile_info_pipeline,
                    tile_info_producer_state,
                    sTile_info,
                    work_tile,
                )

                while work_tile.is_valid_tile:
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                    tile_info_producer_state = self._produce_tile_info(
                        tile_info_pipeline,
                        tile_info_producer_state,
                        sTile_info,
                        work_tile,
                    )

                tile_info_pipeline.producer_tail(tile_info_producer_state)

            elif warp_idx == self.tma_load_warp_id:
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_a, tensormap_a_smem_ptr, self.tma_load_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_b, tensormap_b_smem_ptr, self.tma_load_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_sfa, tensormap_sfa_smem_ptr, self.tma_load_warp_id
                )
                tensormap_manager.init_tensormap_from_atom(
                    tma_atom_sfb, tensormap_sfb_smem_ptr, self.tma_load_warp_id
                )

                mainloop_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.ab_stage
                )
                tile_info_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.num_sched_stage
                )
                last_group_idx = cutlass.Int32(-1)

                (
                    tile_info_consumer_state,
                    is_valid_tile,
                    cur_group_idx,
                    cur_tile_m,
                    cur_tile_n,
                    cur_m,
                    cur_n,
                    cur_k,
                    cur_k_tile_cnt,
                ) = self._consume_tile_info(
                    tile_info_pipeline, tile_info_consumer_state, sTile_info
                )

                while is_valid_tile:
                    if cur_k_tile_cnt > 0:
                        is_group_changed = cur_group_idx != last_group_idx
                        if is_group_changed:
                            real_tensor_a = self.make_tensor_abc_for_tensormap_update(
                                cur_group_idx,
                                self.a_dtype,
                                (cur_m, cur_n, cur_k),
                                strides_abc,
                                ptrs_abc,
                                0,
                            )
                            real_tensor_b = self.make_tensor_abc_for_tensormap_update(
                                cur_group_idx,
                                self.b_dtype,
                                (cur_m, cur_n, cur_k),
                                strides_abc,
                                ptrs_abc,
                                1,
                            )
                            real_tensor_sfa = (
                                self.make_tensor_sfasfb_for_tensormap_update(
                                    cur_group_idx,
                                    self.sf_dtype,
                                    (cur_m, cur_n, cur_k),
                                    ptrs_sfasfb,
                                    0,
                                )
                            )
                            real_tensor_sfb = (
                                self.make_tensor_sfasfb_for_tensormap_update(
                                    cur_group_idx,
                                    self.sf_dtype,
                                    (cur_m, cur_n, cur_k),
                                    ptrs_sfasfb,
                                    1,
                                )
                            )
                            tensormap_manager.update_tensormap(
                                (
                                    real_tensor_a,
                                    real_tensor_b,
                                    real_tensor_sfa,
                                    real_tensor_sfb,
                                ),
                                (
                                    tma_atom_a,
                                    tma_atom_b,
                                    tma_atom_sfa,
                                    tma_atom_sfb,
                                ),
                                (
                                    tensormap_a_gmem_ptr,
                                    tensormap_b_gmem_ptr,
                                    tensormap_sfa_gmem_ptr,
                                    tensormap_sfb_gmem_ptr,
                                ),
                                self.tma_load_warp_id,
                                (
                                    tensormap_a_smem_ptr,
                                    tensormap_b_smem_ptr,
                                    tensormap_sfa_smem_ptr,
                                    tensormap_sfb_smem_ptr,
                                ),
                            )
                            last_group_idx = cur_group_idx

                        tAgA_mkl = tAgA[(None, cur_tile_m, None, 0)]
                        tBgB_nkl = tBgB[(None, cur_tile_n, None, 0)]
                        tAgSFA_mkl = tAgSFA[(None, cur_tile_m, None, 0)]
                        tBgSFB_nkl = tBgSFB[(None, cur_tile_n, None, 0)]

                        mainloop_producer_state.reset_count()
                        # Acquire stage 0 before fencing tensormap updates so GMEM
                        # tensormap release overlaps with waiting for an empty stage.
                        mainloop_pipeline.producer_acquire(mainloop_producer_state)
                        if is_group_changed:
                            tensormap_manager.fence_tensormap_update(
                                tensormap_a_gmem_ptr
                            )
                            tensormap_manager.fence_tensormap_update(
                                tensormap_b_gmem_ptr
                            )
                            tensormap_manager.fence_tensormap_update(
                                tensormap_sfa_gmem_ptr
                            )
                            tensormap_manager.fence_tensormap_update(
                                tensormap_sfb_gmem_ptr
                            )
                        for k_tile_idx in cutlass.range(0, cur_k_tile_cnt, 1, unroll=1):
                            if k_tile_idx > 0:
                                mainloop_pipeline.producer_acquire(
                                    mainloop_producer_state
                                )

                            tAgA_k = tAgA_mkl[(None, mainloop_producer_state.count)]
                            tAsA_pipe = tAsA[(None, mainloop_producer_state.index)]
                            tBgB_k = tBgB_nkl[(None, mainloop_producer_state.count)]
                            tBsB_pipe = tBsB[(None, mainloop_producer_state.index)]
                            tAgSFA_k = tAgSFA_mkl[(None, mainloop_producer_state.count)]
                            tAsSFA_pipe = tAsSFA[(None, mainloop_producer_state.index)]
                            tBgSFB_k = tBgSFB_nkl[(None, mainloop_producer_state.count)]
                            tBsSFB_pipe = tBsSFB[(None, mainloop_producer_state.index)]

                            mbar_ptr = mainloop_pipeline.producer_get_barrier(
                                mainloop_producer_state
                            )
                            cute.copy(
                                tma_atom_a,
                                tAgA_k,
                                tAsA_pipe,
                                tma_bar_ptr=mbar_ptr,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_a_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            cute.copy(
                                tma_atom_b,
                                tBgB_k,
                                tBsB_pipe,
                                tma_bar_ptr=mbar_ptr,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_b_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            cute.copy(
                                tma_atom_sfa,
                                tAgSFA_k,
                                tAsSFA_pipe,
                                tma_bar_ptr=mbar_ptr,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfa_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            cute.copy(
                                tma_atom_sfb,
                                tBgSFB_k,
                                tBsSFB_pipe,
                                tma_bar_ptr=mbar_ptr,
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_sfb_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            mainloop_pipeline.producer_commit(mainloop_producer_state)
                            mainloop_producer_state.advance()

                    (
                        tile_info_consumer_state,
                        is_valid_tile,
                        cur_group_idx,
                        cur_tile_m,
                        cur_tile_n,
                        cur_m,
                        cur_n,
                        cur_k,
                        cur_k_tile_cnt,
                    ) = self._consume_tile_info(
                        tile_info_pipeline, tile_info_consumer_state, sTile_info
                    )

                mainloop_pipeline.producer_tail(mainloop_producer_state)

        # /////////////////////////////////////////////////////////////////////
        #  WG0 (warps 0..3) & WG1 (warps 4..7): Ping-Pong MMA + Epilogue
        # /////////////////////////////////////////////////////////////////////
        else:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            # Per-WG isolated output tensormap (slot 4 for WG0, slot 5 for WG1)
            tma_store_warp_id = warp_group_idx * 4
            tensormap_c_smem_ptr = cute.make_ptr(
                tensormap_smem_ptr.dtype,
                (tensormap_smem_ptr + (4 + warp_group_idx) * stride_tm_i64).toint(),
                cutlass.AddressSpace.smem,
                assumed_align=64,
            )
            tensormap_c_gmem_ptr = tensormap_manager.get_tensormap_ptr(
                tensormaps[(tensormap_workspace_idx, 4 + warp_group_idx, None)].iterator
            )
            tensormap_manager.init_tensormap_from_atom(
                tma_atom_c, tensormap_c_smem_ptr, tma_store_warp_id
            )

            thr_mma = tiled_mma.get_slice(tidx % 128)
            tCsA = thr_mma.partition_A(sA)
            tCsB = thr_mma.partition_B(sB)
            tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
            tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])
            tCrSFA = sm120_utils.partition_fragment_SFA(
                sSFA[None, None, 0], thr_mma, tidx
            )
            tCrSFB = sm120_utils.partition_fragment_SFB(
                sSFB[None, None, 0], thr_mma, tidx
            )
            tCgC = thr_mma.partition_C(gC_mnl)
            accumulators = cute.make_rmem_tensor(tCgC.shape[:3], self.acc_dtype)

            num_k_blocks = cute.size(tCrA, mode=[2])

            atom_copy_ldmatrix_A = make_ldmatrix_atom(
                self.a_dtype,
                transpose=self.a_layout.is_m_major_a(),
                num_matrices=4,
                mixed_mode=self.mixed_mode,
            )
            atom_copy_ldmatrix_B = make_ldmatrix_atom(
                self.b_dtype,
                transpose=self.b_layout.is_n_major_b(),
                num_matrices=4,
                mixed_mode=self.mixed_mode,
            )
            smem_tiled_copy_A = cute.make_tiled_copy_A(atom_copy_ldmatrix_A, tiled_mma)
            smem_tiled_copy_B = cute.make_tiled_copy_B(atom_copy_ldmatrix_B, tiled_mma)

            atom_copy_ldmatrix_SF = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self.sf_dtype,
            )
            smem_tiled_copy_SFA = cute.make_tiled_copy(
                atom_copy_ldmatrix_SF,
                sm120_utils.get_layoutSFA_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[0]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )
            smem_tiled_copy_SFB = cute.make_tiled_copy(
                atom_copy_ldmatrix_SF,
                sm120_utils.get_layoutSFB_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[1]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )

            thr_copy_ldmatrix_A = smem_tiled_copy_A.get_slice(tidx % 128)
            thr_copy_ldmatrix_B = smem_tiled_copy_B.get_slice(tidx % 128)
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)
            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            thr_copy_ldmatrix_SFA = smem_tiled_copy_SFA.get_slice(tidx % 128)
            thr_copy_ldmatrix_SFB = smem_tiled_copy_SFB.get_slice(tidx % 128)
            tCsSFA_copy_view = thr_copy_ldmatrix_SFA.partition_S(sSFA)
            tCrSFA_copy_view = thr_copy_ldmatrix_SFA.retile(tCrSFA)
            tCsSFB_copy_view = thr_copy_ldmatrix_SFB.partition_S(sSFB)
            tCrSFB_copy_view = thr_copy_ldmatrix_SFB.retile(tCrSFB)

            # Epilogue copy/tiling setup (hoisted outside the persistent tile loop)
            copy_atom_r2s = sm120_utils.sm120_get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )
            # StMatrix8x8x16bOp with Float16 provides the warp-MMA C-fragment
            # blueprint regardless of c_dtype; copy_atom_r2s performs the actual store.
            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(
                    self.c_layout.is_m_major_c(),
                    2,
                ),
                cutlass.Float16,
            )
            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)
            tiled_copy_r2s = cute.make_tiled_copy_S(copy_atom_r2s, tiled_copy_C_Atom)
            thr_copy_r2s = tiled_copy_r2s.get_slice(tidx % 128)
            tRS_sD = thr_copy_r2s.partition_D(sC)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            rD_shape = cute.shape(thr_copy_r2s.partition_S(sC))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)
            sepi_for_tma_partition = cute.group_modes(sC, 0, 2)

            tma_store_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                (self.num_mma_warps // 2) * self.num_threads_per_warp,
            )
            tma_store_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.epi_stage,
                producer_group=tma_store_producer_group,
            )

            epi_tile_m = self.epi_tile[0]
            epi_tile_n = self.epi_tile[1]
            mma_tile_m = self.tile_shape_mnk[0] // cute.size(tRS_rAcc, mode=[1])
            mma_tile_n = self.tile_shape_mnk[1] // cute.size(tRS_rAcc, mode=[2])

            mainloop_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.ab_stage
            )
            tile_info_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_sched_stage
            )
            last_group_idx = cutlass.Int32(-1)

            # Consume tile 0; WG1 skips tile 0's K-tiles and consumes tile 1
            (
                tile_info_consumer_state,
                is_valid_tile,
                cur_group_idx,
                cur_tile_m,
                cur_tile_n,
                cur_m,
                cur_n,
                cur_k,
                cur_k_tile_cnt,
            ) = self._consume_tile_info(
                tile_info_pipeline, tile_info_consumer_state, sTile_info
            )
            if warp_group_idx == 1 and is_valid_tile:
                mainloop_consumer_state = self.advance(
                    mainloop_consumer_state, cur_k_tile_cnt
                )
                (
                    tile_info_consumer_state,
                    is_valid_tile,
                    cur_group_idx,
                    cur_tile_m,
                    cur_tile_n,
                    cur_m,
                    cur_n,
                    cur_k,
                    cur_k_tile_cnt,
                ) = self._consume_tile_info(
                    tile_info_pipeline, tile_info_consumer_state, sTile_info
                )

            while is_valid_tile:
                accumulators.fill(0.0)
                mainloop_consumer_state.reset_count()

                # Wait for this warpgroup's MMA turn
                math_wg_order_barrier.wait(math_wg_order_state)

                if cur_k_tile_cnt > 0:
                    peek_ab_full_status = mainloop_pipeline.consumer_try_wait(
                        mainloop_consumer_state
                    )
                    mainloop_pipeline.consumer_wait(
                        mainloop_consumer_state, peek_ab_full_status
                    )

                    tCsA_p = tCsA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsB_p = tCsB_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsSFA_p = tCsSFA_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]
                    tCsSFB_p = tCsSFB_copy_view[
                        None, None, None, mainloop_consumer_state.index
                    ]

                    cute.copy(
                        smem_tiled_copy_A,
                        tCsA_p[None, None, 0],
                        tCrA_copy_view[None, None, 0],
                    )
                    cute.copy(
                        smem_tiled_copy_B,
                        tCsB_p[None, None, 0],
                        tCrB_copy_view[None, None, 0],
                    )
                    tCsSFA_p_filtered = cute.filter_zeros(tCsSFA_p)
                    tCsSFB_p_filtered = cute.filter_zeros(tCsSFB_p)
                    tCrSFA_copy_view_filtered = cute.filter_zeros(tCrSFA_copy_view)
                    tCrSFB_copy_view_filtered = cute.filter_zeros(tCrSFB_copy_view)
                    cute.copy(
                        smem_tiled_copy_SFA,
                        tCsSFA_p_filtered[None, None, 0],
                        tCrSFA_copy_view_filtered[None, None, 0],
                    )
                    cute.copy(
                        smem_tiled_copy_SFB,
                        tCsSFB_p_filtered[None, None, 0],
                        tCrSFB_copy_view_filtered[None, None, 0],
                    )

                    for _k_tile in cutlass.range(0, cur_k_tile_cnt - 1, 1, unroll=1):
                        for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                            k_block_next = (
                                0
                                if k_block_idx + 1 == num_k_blocks
                                else k_block_idx + 1
                            )

                            if k_block_idx == num_k_blocks - 1:
                                mainloop_pipeline.consumer_release(
                                    mainloop_consumer_state
                                )
                                mainloop_consumer_state.advance()

                                peek_ab_full_status = (
                                    mainloop_pipeline.consumer_try_wait(
                                        mainloop_consumer_state
                                    )
                                )
                                tCsA_p = tCsA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsB_p = tCsB_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsSFA_p = tCsSFA_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                tCsSFB_p = tCsSFB_copy_view[
                                    None, None, None, mainloop_consumer_state.index
                                ]
                                mainloop_pipeline.consumer_wait(
                                    mainloop_consumer_state, peek_ab_full_status
                                )

                            cute.copy(
                                smem_tiled_copy_A,
                                tCsA_p[None, None, k_block_next],
                                tCrA_copy_view[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_B,
                                tCsB_p[None, None, k_block_next],
                                tCrB_copy_view[None, None, k_block_next],
                            )
                            tCsSFA_p_filtered = cute.filter_zeros(tCsSFA_p)
                            tCsSFB_p_filtered = cute.filter_zeros(tCsSFB_p)
                            tCrSFA_copy_view_filtered = cute.filter_zeros(
                                tCrSFA_copy_view
                            )
                            tCrSFB_copy_view_filtered = cute.filter_zeros(
                                tCrSFB_copy_view
                            )
                            cute.copy(
                                smem_tiled_copy_SFA,
                                tCsSFA_p_filtered[None, None, k_block_next],
                                tCrSFA_copy_view_filtered[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_SFB,
                                tCsSFB_p_filtered[None, None, k_block_next],
                                tCrSFB_copy_view_filtered[None, None, k_block_next],
                            )

                            if cutlass.const_expr(
                                self.mixed_mode and self.a_dtype.width < 8
                            ):
                                a_view = cute.recast_tensor(
                                    tCrA[None, None, k_block_idx], cutlass.Int8
                                )
                                for _i in cutlass.range(
                                    cute.size(a_view), unroll_full=True
                                ):
                                    a_view[_i] = cutlass.Int8(
                                        a_view[_i] << FP4_SHIFT_BITS
                                    )
                            if cutlass.const_expr(
                                self.mixed_mode and self.b_dtype.width < 8
                            ):
                                b_view = cute.recast_tensor(
                                    tCrB[None, None, k_block_idx], cutlass.Int8
                                )
                                for _i in cutlass.range(
                                    cute.size(b_view), unroll_full=True
                                ):
                                    b_view[_i] = cutlass.Int8(
                                        b_view[_i] << FP4_SHIFT_BITS
                                    )

                            cute.gemm(
                                tiled_mma,
                                accumulators,
                                [
                                    tCrA[None, None, k_block_idx],
                                    tCrSFA[None, None, k_block_idx],
                                ],
                                [
                                    tCrB[None, None, k_block_idx],
                                    tCrSFB[None, None, k_block_idx],
                                ],
                                accumulators,
                            )

                    # Hoisted last k_tile
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_next = (
                            0 if k_block_idx + 1 == num_k_blocks else k_block_idx + 1
                        )

                        if k_block_idx == num_k_blocks - 1:
                            mainloop_pipeline.consumer_release(mainloop_consumer_state)
                            mainloop_consumer_state.advance()

                        if k_block_next > 0:
                            cute.copy(
                                smem_tiled_copy_A,
                                tCsA_p[None, None, k_block_next],
                                tCrA_copy_view[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_B,
                                tCsB_p[None, None, k_block_next],
                                tCrB_copy_view[None, None, k_block_next],
                            )
                            tCsSFA_p_filtered = cute.filter_zeros(tCsSFA_p)
                            tCsSFB_p_filtered = cute.filter_zeros(tCsSFB_p)
                            tCrSFA_copy_view_filtered = cute.filter_zeros(
                                tCrSFA_copy_view
                            )
                            tCrSFB_copy_view_filtered = cute.filter_zeros(
                                tCrSFB_copy_view
                            )
                            cute.copy(
                                smem_tiled_copy_SFA,
                                tCsSFA_p_filtered[None, None, k_block_next],
                                tCrSFA_copy_view_filtered[None, None, k_block_next],
                            )
                            cute.copy(
                                smem_tiled_copy_SFB,
                                tCsSFB_p_filtered[None, None, k_block_next],
                                tCrSFB_copy_view_filtered[None, None, k_block_next],
                            )

                        if cutlass.const_expr(
                            self.mixed_mode and self.a_dtype.width < 8
                        ):
                            a_view_h = cute.recast_tensor(
                                tCrA[None, None, k_block_idx], cutlass.Int8
                            )
                            for _i in cutlass.range(
                                cute.size(a_view_h), unroll_full=True
                            ):
                                a_view_h[_i] = cutlass.Int8(
                                    a_view_h[_i] << FP4_SHIFT_BITS
                                )
                        if cutlass.const_expr(
                            self.mixed_mode and self.b_dtype.width < 8
                        ):
                            b_view_h = cute.recast_tensor(
                                tCrB[None, None, k_block_idx], cutlass.Int8
                            )
                            for _i in cutlass.range(
                                cute.size(b_view_h), unroll_full=True
                            ):
                                b_view_h[_i] = cutlass.Int8(
                                    b_view_h[_i] << FP4_SHIFT_BITS
                                )

                        cute.gemm(
                            tiled_mma,
                            accumulators,
                            [
                                tCrA[None, None, k_block_idx],
                                tCrSFA[None, None, k_block_idx],
                            ],
                            [
                                tCrB[None, None, k_block_idx],
                                tCrSFB[None, None, k_block_idx],
                            ],
                            accumulators,
                        )

                # Pass MMA turn to peer warpgroup. Because each warpgroup owns an
                # isolated C tensormap slot (slot 4 / slot 5) and drained its own
                # previous TMA stores via producer_tail(), issue the C tensormap
                # update BEFORE waiting for the epilogue turn so the GMEM release
                # overlaps with the peer warpgroup epilogue and first stmatrix.
                math_wg_order_state = math_wg_order_barrier.arrive(math_wg_order_state)

                is_group_changed = cur_group_idx != last_group_idx
                if is_group_changed:
                    real_tensor_c = self.make_tensor_abc_for_tensormap_update(
                        cur_group_idx,
                        self.c_dtype,
                        (cur_m, cur_n, cur_k),
                        strides_abc,
                        ptrs_abc,
                        2,
                    )
                    tensormap_manager.update_tensormap(
                        (real_tensor_c,),
                        (tma_atom_c,),
                        (tensormap_c_gmem_ptr,),
                        tma_store_warp_id,
                        (tensormap_c_smem_ptr,),
                    )
                    last_group_idx = cur_group_idx

                math_wg_order_barrier.wait(math_wg_order_state)

                # /////////////////////////////////////////////////////////////
                #  Epilogue (also writes zeros when cur_k_tile_cnt == 0)
                # /////////////////////////////////////////////////////////////

                gC_mnl_slice = gC_mnl[(None, None, cur_tile_m, cur_tile_n, 0)]
                tcgc_for_tma_partition = cute.zipped_divide(gC_mnl_slice, self.epi_tile)
                bSG_sD, bSG_gD = cpasync.tma_partition(
                    tma_atom_c,
                    0,
                    cute.make_layout(1),
                    sepi_for_tma_partition,
                    tcgc_for_tma_partition,
                )

                epi_rest_m = bSG_gD.shape[1][0]
                epi_rest_n = bSG_gD.shape[1][1]
                for epi_m in cutlass.range_constexpr(epi_rest_m):
                    for epi_n in cutlass.range_constexpr(epi_rest_n):
                        mma_m_per_epi_m = epi_tile_m // mma_tile_m
                        mma_n_per_epi_n = epi_tile_n // mma_tile_n
                        for mma_n_in_epi in cutlass.range_constexpr(mma_n_per_epi_n):
                            for mma_m_in_epi in cutlass.range_constexpr(
                                mma_m_per_epi_m
                            ):
                                mma_n = (epi_n * mma_n_per_epi_n) + mma_n_in_epi
                                mma_m = (epi_m * mma_m_per_epi_m) + mma_m_in_epi
                                tRS_rD_slice = tRS_rD[
                                    (None, mma_m_in_epi, mma_n_in_epi)
                                ]
                                tRS_rAcc_slice = tRS_rAcc[(None, mma_m, mma_n)]
                                for elem_idx in cutlass.range_constexpr(
                                    cute.size(tRS_rD_slice)
                                ):
                                    tRS_rD_slice[elem_idx] = tRS_rAcc_slice[elem_idx]

                        tRS_rD_out = cute.make_rmem_tensor(
                            tRS_rD_layout.shape, self.c_dtype
                        )
                        acc_vec = tRS_rD.load()
                        tRS_rD_out.store(acc_vec.to(self.c_dtype))

                        epi_buffer = (epi_m * epi_rest_n + epi_n) % cute.size(
                            tRS_sD, mode=[3]
                        )
                        self.epilog_sync_barrier.arrive_and_wait()
                        cute.copy(
                            tiled_copy_r2s,
                            tRS_rD_out,
                            tRS_sD[(None, None, None, epi_buffer)],
                        )
                        cute.arch.fence_proxy("async.shared", space="cta")
                        self.epilog_sync_barrier.arrive_and_wait()

                        if warp_idx == tma_store_warp_id:
                            if cutlass.const_expr(epi_m == 0 and epi_n == 0):
                                if is_group_changed:
                                    tensormap_manager.fence_tensormap_update(
                                        tensormap_c_gmem_ptr
                                    )
                            cute.copy(
                                tma_atom_c,
                                bSG_sD[(None, epi_buffer)],
                                bSG_gD[(None, (epi_m, epi_n))],
                                tma_desc_ptr=tensormap_manager.get_tensormap_ptr(
                                    tensormap_c_gmem_ptr,
                                    cutlass.AddressSpace.generic,
                                ),
                            )
                            tma_store_pipeline.producer_commit()
                            tma_store_pipeline.producer_acquire()

                # Drain sC reads before handing epilogue turn to the peer warpgroup
                tma_store_pipeline.producer_tail()
                math_wg_order_state = math_wg_order_barrier.arrive(math_wg_order_state)

                # Consume peer tile to advance mainloop consumer state by peer's K-tiles,
                # then consume this warpgroup's next tile.
                (
                    tile_info_consumer_state,
                    peer_is_valid,
                    _pg,
                    _pm,
                    _pn,
                    _p_m,
                    _p_n,
                    _p_k,
                    peer_k_tile_cnt,
                ) = self._consume_tile_info(
                    tile_info_pipeline, tile_info_consumer_state, sTile_info
                )
                is_valid_tile = peer_is_valid
                if peer_is_valid:
                    mainloop_consumer_state = self.advance(
                        mainloop_consumer_state, peer_k_tile_cnt
                    )
                    (
                        tile_info_consumer_state,
                        is_valid_tile,
                        cur_group_idx,
                        cur_tile_m,
                        cur_tile_n,
                        cur_m,
                        cur_n,
                        cur_k,
                        cur_k_tile_cnt,
                    ) = self._consume_tile_info(
                        tile_info_pipeline, tile_info_consumer_state, sTile_info
                    )

        return

    @classmethod
    def _compute_stages(
        cls,
        tile_shape_mnk: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sfa_smem_layout: cute.Layout,
        sfb_smem_layout: cute.Layout,
        epi_tile: Tuple[int, int],
        c_dtype: Type[cutlass.Numeric],
        smem_capacity: int,
        occupancy: int,
    ) -> Tuple[int, int]:
        """Compute exact SMEM-safe (ab_stage, epi_stage) accounting for tensormaps,
        tile_info, barriers, and 1024-byte buffer alignments."""
        epi_stage_max = (tile_shape_mnk[0] // epi_tile[0]) * (
            tile_shape_mnk[1] // epi_tile[1]
        )
        epi_stage = min(epi_stage_max, 4)
        c_bytes_per_stage = cute.size(epi_tile) * c_dtype.width // 8
        # Keep epilogue SMEM <= 16 KiB when subtiling so wider outputs (e.g. FP32)
        # still preserve >= 2 A/B pipeline stages on SM120.
        if epi_stage > 1 and c_bytes_per_stage * epi_stage > 16384:
            epi_stage = max(1, 16384 // c_bytes_per_stage)
        epi_bytes = _align_up(c_bytes_per_stage * epi_stage, 1024)

        a_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        b_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        a_bytes_per_stage = cute.size(a_shape) * a_dtype.width // 8
        b_bytes_per_stage = cute.size(b_shape) * b_dtype.width // 8
        sfa_bytes_per_stage = (
            cute.size(cute.filter_zeros(sfa_smem_layout).shape) * sf_dtype.width // 8
        )
        sfb_bytes_per_stage = (
            cute.size(cute.filter_zeros(sfb_smem_layout).shape) * sf_dtype.width // 8
        )

        # Available SMEM after driver reservation (1 KiB per CTA)
        avail_smem = (smem_capacity - occupancy * 1024) // occupancy
        # Fixed pre-buffer header: tensormap_buffer (768 B) + tile_info (128 B) + mbarriers
        fixed_base = (
            cls.num_tensormaps * cls.bytes_per_tensormap
            + cls.tile_info_elems * cls.num_sched_stage * 4
            + cls.num_sched_stage * 2 * 8
            + 4 * 8
        )

        ab_stage = 0
        for candidate in range(1, 16):
            header_bytes = _align_up(fixed_base + candidate * 2 * 8, 1024)
            total_bytes = (
                header_bytes
                + _align_up(a_bytes_per_stage * candidate, 1024)
                + _align_up(b_bytes_per_stage * candidate, 1024)
                + _align_up(sfa_bytes_per_stage * candidate, 1024)
                + _align_up(sfb_bytes_per_stage * candidate, 1024)
                + epi_bytes
            )
            if total_bytes <= avail_smem:
                ab_stage = candidate
            else:
                break

        return ab_stage, epi_stage

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk: Tuple[int, int, int],
        epi_tile: Tuple[int, int],
        a_dtype: Type[cutlass.Numeric],
        a_layout: cutlass.tensor_utils.LayoutEnum,
        b_dtype: Type[cutlass.Numeric],
        b_layout: cutlass.tensor_utils.LayoutEnum,
        ab_stage: int,
        c_dtype: Type[cutlass.Numeric],
        c_layout: cutlass.tensor_utils.LayoutEnum,
        epi_stage: int,
        sf_vec_size: int,
        tiled_mma: cute.TiledMma,
    ):
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        a_is_k_major = a_layout.is_k_major_a()
        b_is_k_major = b_layout.is_k_major_b()
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]

        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                a_layout,
                a_dtype,
                a_major_mode_size,
            ),
            a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                b_layout,
                b_dtype,
                b_major_mode_size,
            ),
            b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        sfa_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfa(
            tiled_mma,
            tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )
        sfb_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfb(
            tiled_mma,
            tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )

        c_smem_shape = epi_tile
        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(
                c_layout,
                c_dtype,
                c_major_mode_size,
            ),
            c_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom,
            cute.append(c_smem_shape, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )

        return (
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            epi_smem_layout_staged,
        )

    @staticmethod
    def _compute_grid(
        total_num_clusters: int,
        max_active_clusters: cutlass.Constexpr[int],
    ) -> Tuple[utils.PersistentTileSchedulerParams, Tuple[int, int, int]]:
        problem_shape_ntile_mnl = (1, 1, cutlass.Int32(total_num_clusters))
        tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, (1, 1, 1)
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        return tile_sched_params, grid

    @staticmethod
    def _make_tma_store_atoms_and_tensors(
        tensor_c: cute.Tensor,
        epi_smem_layout_staged: cute.ComposedLayout,
        epi_tile: Tuple[int, int],
    ) -> Tuple[cute.CopyAtom, cute.Tensor]:
        epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))
        return cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            tensor_c,
            epi_smem_layout,
            epi_tile,
        )

    @staticmethod
    def _make_tma_atoms_and_tensors(
        tensor: cute.Tensor,
        smem_layout_staged: cute.ComposedLayout,
        smem_tile: Tuple[int, int],
        mcast_dim: int,
        internal_type: Optional[Type[cutlass.Numeric]] = None,
    ) -> Tuple[cute.CopyAtom, cute.Tensor]:
        op = (
            cpasync.CopyBulkTensorTileG2SOp()
            if mcast_dim == 1
            else cpasync.CopyBulkTensorTileG2SMulticastOp()
        )
        smem_layout = cute.slice_(smem_layout_staged, (None, None, 0))
        return cpasync.make_tiled_tma_atom(
            op,
            tensor,
            smem_layout,
            smem_tile,
            num_multicast=mcast_dim,
            internal_type=internal_type,
        )

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    ) -> bool:
        if acc_dtype != cutlass.Float32:
            return False
        if c_dtype not in {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }:
            return False
        fp8_dtypes = {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        if a_dtype == b_dtype:
            if a_dtype == cutlass.Float4E2M1FN:
                if sf_vec_size == 16 and sf_dtype == cutlass.Float8E4M3FN:
                    return True
                if sf_vec_size == 32 and sf_dtype == cutlass.Float8E8M0FNU:
                    return True
                return False
            if a_dtype in fp8_dtypes:
                return sf_vec_size == 32 and sf_dtype == cutlass.Float8E8M0FNU
            return False
        is_mixed_fp4_fp8 = (
            a_dtype == cutlass.Float4E2M1FN and b_dtype in fp8_dtypes
        ) or (a_dtype in fp8_dtypes and b_dtype == cutlass.Float4E2M1FN)
        return (
            is_mixed_fp4_fp8 and sf_vec_size == 32 and sf_dtype == cutlass.Float8E8M0FNU
        )

    @staticmethod
    def is_valid_layouts(
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        return a_major == "k" and b_major == "k" and c_major in {"n", "m"}

    @staticmethod
    def is_valid_tile_and_epi_shape(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
        epi_tile: Tuple[int, int],
    ) -> bool:
        tile = tuple(tile_shape_mnk)
        epi = tuple(epi_tile)
        if epi not in {(128, 128), (64, 32)}:
            return False
        if a_dtype == b_dtype == cutlass.Float4E2M1FN and sf_vec_size == 16:
            if tile not in {(128, 128, 128), (128, 128, 256)}:
                return False
        else:
            if tile != (128, 128, 128):
                return False
        # Check SMEM feasibility (e.g. epi=(128, 128) + FP32 + FP8 exceeds 98 KiB)
        smem_a_bytes = (
            tile[0]
            * tile[2]
            * (8 if (a_dtype != b_dtype and a_dtype.width < 8) else a_dtype.width)
            // 8
        )
        smem_b_bytes = (
            tile[1]
            * tile[2]
            * (8 if (a_dtype != b_dtype and b_dtype.width < 8) else b_dtype.width)
            // 8
        )
        sf_k_per_stage = tile[2] // sf_vec_size
        sfa_bytes = tile[0] * sf_k_per_stage
        sfb_bytes = tile[1] * sf_k_per_stage
        epi_stage_max = (tile[0] // epi[0]) * (tile[1] // epi[1])
        epi_stage = min(epi_stage_max, 4)
        c_bytes_per_stage = epi[0] * epi[1] * c_dtype.width // 8
        if epi_stage > 1 and c_bytes_per_stage * epi_stage > 16384:
            epi_stage = max(1, 16384 // c_bytes_per_stage)
        epi_bytes = _align_up(c_bytes_per_stage * epi_stage, 1024)
        header_bytes = _align_up(
            Sm120GroupedBlockScaledGemmKernel.num_tensormaps
            * Sm120GroupedBlockScaledGemmKernel.bytes_per_tensormap
            + Sm120GroupedBlockScaledGemmKernel.tile_info_elems
            * Sm120GroupedBlockScaledGemmKernel.num_sched_stage
            * 4
            + Sm120GroupedBlockScaledGemmKernel.num_sched_stage * 16
            + 4 * 8
            + 16,
            1024,
        )
        min_smem = (
            header_bytes
            + _align_up(smem_a_bytes, 1024)
            + _align_up(smem_b_bytes, 1024)
            + _align_up(sfa_bytes, 1024)
            + _align_up(sfb_bytes, 1024)
            + epi_bytes
        )
        avail_smem = cutlass.memory.get_smem_capacity_in_bytes("sm_120") - 1024
        return min_smem <= avail_smem

    @staticmethod
    def is_valid_tensor_alignment(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        if len(problem_sizes_mnkl) == 0:
            return False

        def check_contiguous_16b_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        for m, n, k, batch_l in problem_sizes_mnkl:
            if m <= 0 or n <= 0 or k < 0 or batch_l != 1:
                return False
            if (
                not check_contiguous_16b_alignment(
                    a_dtype, a_major == "m", (m, k, batch_l)
                )
                or not check_contiguous_16b_alignment(
                    b_dtype, b_major == "n", (n, k, batch_l)
                )
                or not check_contiguous_16b_alignment(
                    c_dtype, c_major == "m", (m, n, batch_l)
                )
            ):
                return False
        return True

    @classmethod
    def can_implement(
        cls,
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
        tile_shape_mnk: Tuple[int, int, int],
        epi_tile: Tuple[int, int],
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
        a_major: str = "k",
        b_major: str = "k",
        c_major: str = "n",
        acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    ) -> bool:
        """Check whether the given grouped block-scaled GEMM configuration is supported."""
        if not cls.is_valid_dtypes_and_scale_factor_vec_size(
            a_dtype, b_dtype, sf_dtype, sf_vec_size, c_dtype, acc_dtype
        ):
            return False
        if not cls.is_valid_layouts(a_major, b_major, c_major):
            return False
        if not cls.is_valid_tile_and_epi_shape(
            a_dtype, b_dtype, sf_vec_size, c_dtype, tile_shape_mnk, epi_tile
        ):
            return False
        if not cls.is_valid_tensor_alignment(
            problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
        ):
            return False
        return True


@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """Convert scale factor tensor from MKL layout to MMA M(32x4xrest_m)xK(4xrest_k)xL layout."""
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def create_tensor_and_stride(
    batch_l: int,
    mode0: int,
    mode1: int,
    is_mode0_major: bool,
    dtype: Type[cutlass.Numeric],
    is_dynamic_layout: bool = True,
) -> Tuple[int, torch.Tensor, cute.Tensor, torch.Tensor, Tuple[int, int]]:
    """Create a GPU tensor and CPU FP32 reference tensor for one group operand."""
    if mode1 == 0:
        # K == 0 group: keep empty reference and a minimal aligned dummy GPU buffer
        # (never dereferenced because K == 0 skips TMA loads).
        ref_cpu = torch.empty((batch_l, mode0, 0), dtype=torch.float32).permute(1, 2, 0)
        dummy_k = max(32, 16 * 8 // dtype.width)
        dummy_cpu = torch.zeros((batch_l, mode0, dummy_k), dtype=torch.float32).permute(
            1, 2, 0
        )
        cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
            dummy_cpu, dtype, is_dynamic_layout, assumed_align=16
        )
        stride = (1, mode0) if is_mode0_major else (mode1, 1)
        return torch_tensor.data_ptr(), torch_tensor, cute_tensor, ref_cpu, stride

    torch_tensor_cpu = cutlass_torch.matrix(
        batch_l,
        mode0,
        mode1,
        is_mode0_major,
        cutlass.Float32,
    )
    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        torch_tensor_cpu, dtype, is_dynamic_layout, assumed_align=16
    )
    stride = (1, mode0) if is_mode0_major else (mode1, 1)
    return (
        torch_tensor.data_ptr(),
        torch_tensor,
        cute_tensor,
        torch_tensor_cpu,
        stride,
    )


def create_tensors_abc_for_all_groups(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
):
    ref_torch_fp32_tensors_abc = []
    torch_tensors_abc = []
    cute_tensors_abc = []
    strides_abc = []
    ptrs_abc = []

    for m, n, k, batch_l in problem_sizes_mnkl:
        ptr_a, torch_a, cute_a, ref_a, stride_a = create_tensor_and_stride(
            batch_l, m, k, a_major == "m", a_dtype
        )
        ptr_b, torch_b, cute_b, ref_b, stride_b = create_tensor_and_stride(
            batch_l, n, k, b_major == "n", b_dtype
        )
        ptr_c, torch_c, cute_c, ref_c, stride_c = create_tensor_and_stride(
            batch_l, m, n, c_major == "m", c_dtype
        )
        ref_torch_fp32_tensors_abc.append([ref_a, ref_b, ref_c])
        ptrs_abc.append([ptr_a, ptr_b, ptr_c])
        torch_tensors_abc.append([torch_a, torch_b, torch_c])
        strides_abc.append([stride_a, stride_b, stride_c])
        cute_tensors_abc.append((cute_a, cute_b, cute_c))

    return (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_torch_fp32_tensors_abc,
    )


def create_scale_factor_tensor(
    batch_l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
):
    def ceil_div(a, b):
        return (a + b - 1) // b

    sf_k = max(1, ceil_div(k, sf_vec_size))
    ref_shape = (batch_l, mn, sf_k)

    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        batch_l,
        ceil_div(mn, atom_m[0] * atom_m[1]),
        ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )

    ref_permute_order = (1, 2, 0)
    mma_permute_order = (3, 4, 1, 5, 2, 0)

    ref_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
        ref_shape,
        torch.float32,
        permute_order=ref_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=1, max_val=3),
    )
    cute_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
        mma_shape,
        torch.float32,
        permute_order=mma_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=0, max_val=1),
    )

    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        from_dlpack(ref_f32_torch_tensor_cpu),
        from_dlpack(cute_f32_torch_tensor_cpu),
    )
    cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

    ref_f32_torch_tensor_cpu = (
        ref_f32_torch_tensor_cpu.permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(batch_l, mn, sf_k, sf_vec_size)
        .reshape(batch_l, mn, sf_k * sf_vec_size)
        .permute(*ref_permute_order)
    )
    ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

    cute_tensor, cute_torch_tensor = cutlass_torch.cute_tensor_like(
        cute_f32_torch_tensor_cpu,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    cute_tensor = cutlass_torch.convert_cute_tensor(
        cute_f32_torch_tensor,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
    )
    return (
        ref_f32_torch_tensor_cpu,
        cute_torch_tensor.data_ptr(),
        cute_tensor,
        cute_torch_tensor,
    )


def create_tensors_sfasfb_for_all_groups(
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
):
    ptrs_sfasfb = []
    torch_tensors_sfasfb = []
    cute_tensors_sfasfb = []
    refs_sfasfb = []

    for m, n, k, batch_l in problem_sizes_mnkl:
        sfa_ref, ptr_sfa, sfa_tensor, sfa_torch = create_scale_factor_tensor(
            batch_l, m, k, sf_vec_size, sf_dtype
        )
        sfb_ref, ptr_sfb, sfb_tensor, sfb_torch = create_scale_factor_tensor(
            batch_l, n, k, sf_vec_size, sf_dtype
        )
        ptrs_sfasfb.append([ptr_sfa, ptr_sfb])
        torch_tensors_sfasfb.append([sfa_torch, sfb_torch])
        cute_tensors_sfasfb.append((sfa_tensor, sfb_tensor))
        refs_sfasfb.append([sfa_ref, sfb_ref])

    return ptrs_sfasfb, torch_tensors_sfasfb, cute_tensors_sfasfb, refs_sfasfb


def create_initial_cute_tensors(
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
) -> Tuple[List[cute.Tensor], List[cute.Tensor], List[torch.Tensor]]:
    """Create minimal placeholder tensors for initial TMA descriptor construction."""
    alignment = 16

    def _min_size(dtype):
        divisibility = 32 if dtype == cutlass.Float4E2M1FN else 16
        min_sz = alignment * 8 // dtype.width
        return min_sz * ((divisibility + min_sz - 1) // min_sz)

    min_a = _min_size(a_dtype)
    min_b = _min_size(b_dtype)
    min_c = _min_size(c_dtype)
    min_sf = _min_size(sf_dtype)

    _, ta, ca, _, _ = create_tensor_and_stride(1, min_a, min_a, a_major == "m", a_dtype)
    _, tb, cb, _, _ = create_tensor_and_stride(1, min_b, min_b, b_major == "n", b_dtype)
    _, tc, cc, _, _ = create_tensor_and_stride(1, min_c, min_c, c_major == "m", c_dtype)
    _, tsfa, csfa, _, _ = create_tensor_and_stride(
        1, min_sf, min_sf, a_major == "m", sf_dtype
    )
    _, tsfb, csfb, _, _ = create_tensor_and_stride(
        1, min_sf, min_sf, b_major == "n", sf_dtype
    )
    return [ca, cb, cc], [csfa, csfb], [ta, tb, tc, tsfa, tsfb]


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool = True,
    a_dtype: Type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    b_dtype: Type[cutlass.Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: Type[cutlass.Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = 16,
    c_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    tile_shape_mnk: Tuple[int, int, int] = (128, 128, 128),
    epi_tile: Tuple[int, int] = (64, 32),
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    use_cached_problem_shapes: bool = True,
    **kwargs,
):
    """Run SM120 persistent grouped block-scaled GEMM with verification and benchmarking."""
    if num_groups != len(problem_sizes_mnkl):
        raise ValueError("num_groups must match len(problem_sizes_mnkl)")
    if any(batch_l != 1 for _, _, _, batch_l in problem_sizes_mnkl):
        raise ValueError("Grouped SM120 example requires l == 1 for all groups")

    a_dtype = getattr(cutlass, a_dtype) if isinstance(a_dtype, str) else a_dtype
    b_dtype = getattr(cutlass, b_dtype) if isinstance(b_dtype, str) else b_dtype
    sf_dtype = getattr(cutlass, sf_dtype) if isinstance(sf_dtype, str) else sf_dtype
    c_dtype = getattr(cutlass, c_dtype) if isinstance(c_dtype, str) else c_dtype

    print("Running SM120 Grouped BlockScaled GEMM test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, batch_l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{batch_l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, SF dtype: {sf_dtype}, "
        f"SF Vec size: {sf_vec_size}, C dtype: {c_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Tile Shape: {tile_shape_mnk}, Epilogue Tile: {epi_tile}")
    print(f"Host problem shape available: {host_problem_shape_available}")
    print(f"Use cached problem shapes: {use_cached_problem_shapes}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}, Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}, Use cold L2: {use_cold_l2}")

    if not Sm120GroupedBlockScaledGemmKernel.can_implement(
        a_dtype,
        b_dtype,
        sf_dtype,
        sf_vec_size,
        c_dtype,
        tile_shape_mnk,
        epi_tile,
        problem_sizes_mnkl,
        a_major,
        b_major,
        c_major,
    ):
        raise testing.CantImplementError(
            f"Unsupported testcase: a_dtype={a_dtype}, b_dtype={b_dtype}, "
            f"sf_dtype={sf_dtype}, sf_vec_size={sf_vec_size}, c_dtype={c_dtype}, "
            f"tile_shape_mnk={tile_shape_mnk}, epi_tile={epi_tile}, "
            f"majors=({a_major},{b_major},{c_major}), problem_sizes={problem_sizes_mnkl}"
        )

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(2025)

    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_f32_torch_tensors_abc,
    ) = create_tensors_abc_for_all_groups(
        problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
    )
    (
        ptrs_sfasfb,
        torch_tensors_sfasfb,
        cute_tensors_sfasfb,
        refs_f32_torch_tensors_sfasfb,
    ) = create_tensors_sfasfb_for_all_groups(problem_sizes_mnkl, sf_dtype, sf_vec_size)

    (
        initial_cute_tensors_abc,
        initial_cute_tensors_sfasfb,
        _initial_torch_keepalive,
    ) = create_initial_cute_tensors(
        a_dtype, b_dtype, sf_dtype, c_dtype, a_major, b_major, c_major
    )

    hardware_info = utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    max_active_clusters = sm_count

    tensormap_shape = (
        sm_count,
        Sm120GroupedBlockScaledGemmKernel.num_tensormaps,
        Sm120GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_gemm = Sm120GroupedBlockScaledGemmKernel(
        sf_vec_size=sf_vec_size,
        tile_shape_mnk=tile_shape_mnk,
        epi_tile=epi_tile,
        use_cached_problem_shapes=use_cached_problem_shapes,
    )

    tensor_of_dim_size_mnkl, _ = cutlass_torch.cute_tensor_like(
        torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )
    tensor_of_ptrs_sfasfb, tensor_of_ptrs_sfasfb_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_sfasfb, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    def compute_total_num_clusters(sizes, tile_mn):
        total = 0
        for m, n, _, _ in sizes:
            num_mn = tuple((x + y - 1) // y for x, y in zip((m, n), tile_mn))
            total += functools.reduce(lambda x, y: x * y, num_mn)
        return total

    if host_problem_shape_available:
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, tile_shape_mnk[:2]
        )
    else:
        total_num_clusters = max_active_clusters

    current_stream = cutlass_torch.default_stream()

    compiled_grouped_gemm = cute.compile(
        grouped_gemm,
        initial_cute_tensors_abc[0],
        initial_cute_tensors_abc[1],
        initial_cute_tensors_abc[2],
        initial_cute_tensors_sfasfb[0],
        initial_cute_tensors_sfasfb[1],
        num_groups,
        tensor_of_dim_size_mnkl,
        tensor_of_strides_abc,
        tensor_of_ptrs_abc,
        tensor_of_ptrs_sfasfb,
        total_num_clusters,
        tensor_of_tensormap,
        max_active_clusters,
        current_stream,
    )

    if not skip_ref_check:
        compiled_grouped_gemm(
            initial_cute_tensors_abc[0],
            initial_cute_tensors_abc[1],
            initial_cute_tensors_abc[2],
            initial_cute_tensors_sfasfb[0],
            initial_cute_tensors_sfasfb[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc,
            tensor_of_ptrs_abc,
            tensor_of_ptrs_sfasfb,
            tensor_of_tensormap,
            current_stream,
        )
        torch.cuda.synchronize()

        for group_idx in range(num_groups):
            m, n, k, batch_l = problem_sizes_mnkl[group_idx]
            a_ref, b_ref, c_ref = ref_f32_torch_tensors_abc[group_idx]
            sfa_ref, sfb_ref = refs_f32_torch_tensors_sfasfb[group_idx]

            if k == 0:
                ref = torch.zeros((m, n, batch_l), dtype=torch.float32)
            else:
                res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
                res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
                ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)

            c_ref_device = c_ref.cuda()
            cute.testing.convert(
                cute_tensors_abc[group_idx][2],
                from_dlpack(c_ref_device, assumed_align=16).mark_layout_dynamic(
                    leading_dim=(1 if c_major == "n" else 0)
                ),
            )
            c_out = c_ref_device.cpu()

            if c_dtype in (cutlass.Float32, cutlass.Float16, cutlass.BFloat16):
                torch.testing.assert_close(c_out, ref, atol=tolerance, rtol=1e-02)
            elif c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
                ref_f8_ = torch.empty(
                    (batch_l, m, n), dtype=torch.uint8, device="cuda"
                ).permute(1, 2, 0)
                ref_f8 = from_dlpack(ref_f8_, assumed_align=16).mark_layout_dynamic(
                    leading_dim=1
                )
                ref_f8.element_type = c_dtype
                ref_device = ref.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
                ref_tensor = from_dlpack(
                    ref_device, assumed_align=16
                ).mark_layout_dynamic(leading_dim=1)
                cute.testing.convert(ref_tensor, ref_f8)
                cute.testing.convert(ref_f8, ref_tensor)
                torch.testing.assert_close(
                    c_out, ref_device.cpu(), atol=tolerance, rtol=1e-02
                )

    def generate_tensors():
        (
            ptrs_abc_ws,
            torch_abc_ws,
            _,
            strides_abc_ws,
            _,
        ) = create_tensors_abc_for_all_groups(
            problem_sizes_mnkl, a_dtype, b_dtype, c_dtype, a_major, b_major, c_major
        )
        (
            ptrs_sfasfb_ws,
            torch_sfasfb_ws,
            _,
            _,
        ) = create_tensors_sfasfb_for_all_groups(
            problem_sizes_mnkl, sf_dtype, sf_vec_size
        )
        init_abc_ws, init_sfasfb_ws, init_keepalive_ws = create_initial_cute_tensors(
            a_dtype, b_dtype, sf_dtype, c_dtype, a_major, b_major, c_major
        )
        strides_ws, strides_ws_torch = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_ws, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )
        ptrs_abc_t_ws, ptrs_abc_ws_torch = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_ws, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )
        ptrs_sf_t_ws, ptrs_sf_ws_torch = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_sfasfb_ws, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )
        tensormap_ws, tensormap_ws_torch = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )
        jit_args = testing.JitArguments(
            init_abc_ws[0],
            init_abc_ws[1],
            init_abc_ws[2],
            init_sfasfb_ws[0],
            init_sfasfb_ws[1],
            tensor_of_dim_size_mnkl,
            strides_ws,
            ptrs_abc_t_ws,
            ptrs_sf_t_ws,
            tensormap_ws,
            current_stream,
        )
        jit_args.add_to_scope(
            [
                torch_abc_ws,
                torch_sfasfb_ws,
                init_keepalive_ws,
                strides_ws_torch,
                ptrs_abc_ws_torch,
                ptrs_sf_ws_torch,
                tensormap_ws_torch,
            ]
        )
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                sum(t.numel() * t.element_size() for t in grp)
                for grp in torch_tensors_abc + torch_tensors_sfasfb
            )
            + tensor_of_strides_abc_torch.numel()
            * tensor_of_strides_abc_torch.element_size()
            + tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            + tensor_of_ptrs_sfasfb_torch.numel()
            * tensor_of_ptrs_sfasfb_torch.element_size()
            + tensor_of_tensormap_torch.numel()
            * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    total_fmas = sum(m * n * k for m, n, k, _ in problem_sizes_mnkl)
    gflops = (2 * total_fmas / 1.0e9) / (exec_time / 1.0e6) if exec_time > 0 else 0.0
    print(f"Average Runtime : {exec_time / 1000:.4f} ms")
    print(f"GFLOPS          : {gflops:.2f}")
    return exec_time


def parse_arguments() -> argparse.Namespace:
    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError as exc:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            ) from exc

    def parse_comma_separated_tuples(s: str) -> List[Tuple[int, ...]]:
        if s.strip().startswith("("):
            tuples = s.strip().strip("()").split("),(")
            result = []
            tuple_len = None
            for t in tuples:
                nums = [int(x.strip()) for x in t.split(",")]
                if tuple_len is None:
                    tuple_len = len(nums)
                elif len(nums) != tuple_len:
                    raise argparse.ArgumentTypeError(
                        "All tuples must have the same length"
                    )
                result.append(tuple(nums))
            return result
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated tuples like '(128,128,128,1),(256,256,256,1)'"
        )

    parser = argparse.ArgumentParser(
        description="Example of SM120 Persistent Grouped BlockScaled GEMM on Blackwell GeForce."
    )
    parser.add_argument("--num_groups", type=int, default=2, help="Number of groups")
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=[(256, 256, 256, 1), (128, 384, 512, 1)],
        help="Problem sizes (M,N,K,L) for each group",
    )
    parser.add_argument(
        "--tile_shape_mnk",
        type=parse_comma_separated_ints,
        choices=[(128, 128, 128), (128, 128, 256)],
        default=(128, 128, 128),
        help="CTA tile shape (M,N,K)",
    )
    parser.add_argument(
        "--epi_tile",
        type=parse_comma_separated_ints,
        choices=[(128, 128), (64, 32)],
        default=(64, 32),
        help="Epilogue tile shape (M,N)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        default=False,
        help="Compute launch grid from host problem shapes instead of max active clusters",
    )
    parser.add_argument(
        "--disable_cached_problem_shapes",
        action="store_true",
        default=False,
        help="Disable double-buffered problem shape caching in tile scheduler",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--sf_vec_size", type=int, choices=[16, 32], default=16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--a_major", choices=["k"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of benchmark iterations"
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure cold L2 cache",
    )

    args = parser.parse_args()
    if len(args.problem_sizes_mnkl) != args.num_groups:
        parser.error("--problem_sizes_mnkl must contain exactly --num_groups tuples")
    for _, _, _, batch_l in args.problem_sizes_mnkl:
        if batch_l != 1:
            parser.error("l must be 1 for all groups")
    return args


if __name__ == "__main__":
    args = parse_arguments()
    run(
        num_groups=args.num_groups,
        problem_sizes_mnkl=args.problem_sizes_mnkl,
        host_problem_shape_available=args.host_problem_shape_available,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        sf_dtype=args.sf_dtype,
        sf_vec_size=args.sf_vec_size,
        c_dtype=args.c_dtype,
        a_major=args.a_major,
        b_major=args.b_major,
        c_major=args.c_major,
        tile_shape_mnk=args.tile_shape_mnk,
        epi_tile=args.epi_tile,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        use_cold_l2=args.use_cold_l2,
        use_cached_problem_shapes=not args.disable_cached_problem_shapes,
    )
    print("PASS")
