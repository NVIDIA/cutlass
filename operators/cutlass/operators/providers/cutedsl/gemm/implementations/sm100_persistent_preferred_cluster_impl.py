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

from collections.abc import Callable
from typing import Union

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.utils as utils
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cutlass_dsl import Int32
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

from .operator_helpers import PersistentTileSchedulerType
from .sm100_persistent_impl import PersistentDenseGemmKernel

"""
A high-performance persistent batched dense GEMM with preferred cluster support for the NVIDIA
Blackwell SM100 architecture using CUTE DSL.

Extends the base persistent dense GEMM (see ``sm100_persistent_impl.py``) with
support for two cluster shapes launched simultaneously:

- **Preferred cluster** (larger): handles the majority of output tiles, benefiting from
  wider TMA multicast and optional 2-CTA MMA instructions.
- **Fallback cluster** (smaller): handles the residual tiles that cannot fill a complete
  preferred cluster, ensuring all SMs remain occupied.

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using
   TMA operations. The TMA atom is selected based on the cluster shape each CTA belongs to.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma.
3. EPILOGUE warp:
   - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) via tcgen05.ld.
   - Type convert C matrix to output type.
   - Store C matrix from registers to global memory, optionally through SMEM via TMA.
   - Optionally apply an elementwise epilogue function to the output.

Constraints are:
* Same input data type support as PersistentDenseGemmKernel (fp16, bf16, tf32, int8,
  uint8, fp8).
* A/B tensor must have the same data type.
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True).
* Mma tiler N must be 32-256, step 32.
* Preferred cluster shape M/N must each be a power of 2 (≥ 1) and a multiple of the
  corresponding fallback cluster shape M/N. Total cluster size ≤ 16.
* Cluster shape M must be a multiple of 2 when use_2cta_instrs=True, for both shapes.
* The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned, i.e. the
  element count must be a multiple of 4 (TFloat32), 8 (Float16/BFloat16), or 16
  (Int8/Uint8/Float8) — matching the 16-byte TMA alignment requirement.
"""


class PersistentDenseGemmPreferredClusterKernel(PersistentDenseGemmKernel):
    """Persistent dense GEMM with preferred cluster (preferred + fallback cluster shapes).

    Extends :class:`PersistentDenseGemmKernel` to support launching with two
    cluster shapes simultaneously.  A larger *preferred* cluster shape is used for
    the bulk of the computation (better TMA multicast and optional 2-CTA MMA), while
    a smaller *fallback* cluster shape handles leftover tiles.
    """

    def __init__(
        self,
        acc_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: tuple[int, int],
        preferred_cluster_shape_mn: tuple[int, int],
        fallback_cluster_shape_mn: tuple[int, int],
        use_tma_store: bool,
        persistent_tile_scheduler_type: PersistentTileSchedulerType,
        epilogue_op: Callable,
    ):
        """Initialise a preferred-cluster GEMM kernel with a preferred (larger) and a fallback
        (smaller) cluster shape.  The base class is constructed with the fallback shape
        so that shared-memory layout and pipeline stage counts are sized conservatively;
        preferred-cluster TMA atoms and multicast masks are derived separately in
        :meth:`_setup_attributes`.

        :param acc_dtype: Accumulator data type.
        :type acc_dtype: type[cutlass.Numeric]
        :param use_2cta_instrs: Whether to use the tcgen05 cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param mma_tiler_mn: (M, N) MMA instruction tile shape.
        :type mma_tiler_mn: tuple[int, int]
        :param preferred_cluster_shape_mn: Preferred (larger) cluster shape (ClusterM, ClusterN).
        :type preferred_cluster_shape_mn: tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback (smaller) cluster shape (ClusterM, ClusterN).
        :type fallback_cluster_shape_mn: tuple[int, int]
        :param use_tma_store: Whether to use TMA for storing the output C tensor.
        :type use_tma_store: bool
        :param persistent_tile_scheduler_type: Persistent tile scheduler variant.
        :type persistent_tile_scheduler_type: PersistentTileSchedulerType
        :param epilogue_op: Elementwise function applied to the output after GEMM.
        :type epilogue_op: Callable
        """
        # Initialise the base class with the fallback cluster shape so that all
        # shared-memory and stage calculations are driven by the smaller shape.
        # The preferred cluster uses the same smem layout; only the TMA atom and
        # the cluster-pipeline synchronisation differ.
        super().__init__(
            acc_dtype=acc_dtype,
            use_2cta_instrs=use_2cta_instrs,
            mma_tiler_mn=mma_tiler_mn,
            cluster_shape_mn=fallback_cluster_shape_mn,
            use_tma_store=use_tma_store,
            persistent_tile_scheduler_type=persistent_tile_scheduler_type,
            epilogue_op=epilogue_op,
        )
        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn
        # self.fallback_cluster_shape_mn == self.cluster_shape_mn (inherited),
        # since the parent was initialised with fallback_cluster_shape_mn above.
        assert self.fallback_cluster_shape_mn == self.cluster_shape_mn

    # ------------------------------------------------------------------
    # Setup helpers
    # ------------------------------------------------------------------

    def _setup_attributes(self):
        """Extend base setup to also compute preferred-cluster layout and mcast info."""
        super()._setup_attributes()

        # Re-create tiled_mma (same call as in parent) to compute preferred layout.
        # Attributes like self.a_dtype, self.a_major_mode, etc., are set by the
        # parent's _setup_attributes caller (__call__) before _setup_attributes runs.
        tiled_mma = utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

        # Preferred cluster layout used for TMA multicast mask and pipeline sync.
        self.preferred_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.num_preferred_mcast_ctas_a = cute.size(
            self.preferred_cluster_layout_vmnk.shape[2]
        )
        self.num_preferred_mcast_ctas_b = cute.size(
            self.preferred_cluster_layout_vmnk.shape[1]
        )
        self.is_preferred_a_mcast = self.num_preferred_mcast_ctas_a > 1
        self.is_preferred_b_mcast = self.num_preferred_mcast_ctas_b > 1

        # Fallback attributes are simply those computed by the base class (which
        # was initialised with fallback_cluster_shape_mn).
        self.fallback_cluster_layout_vmnk = self.cluster_layout_vmnk
        self.num_fallback_mcast_ctas_a = self.num_mcast_ctas_a
        self.num_fallback_mcast_ctas_b = self.num_mcast_ctas_b
        self.is_fallback_a_mcast = self.is_a_mcast
        self.is_fallback_b_mcast = self.is_b_mcast

    # ------------------------------------------------------------------
    # Host-side JIT entry point
    # ------------------------------------------------------------------

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_preferred_clusters: cutlass.Constexpr = None,
        max_active_fallback_clusters: cutlass.Constexpr = None,
        stream: cuda.CUstream = None,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute preferred-cluster GEMM.

        Sets up TMA atoms for both preferred and fallback cluster shapes, computes
        the launch grid, and dispatches the mega-kernel with both cluster shapes.

        :param a: Input tensor A (L, M, K) or (M, K), row- or column-major.
        :type a: cute.Tensor
        :param b: Input tensor B (L, K, N) or (K, N), row- or column-major.
        :type b: cute.Tensor
        :param c: Output tensor C (L, M, N) or (M, N), row- or column-major.
        :type c: cute.Tensor
        :param max_active_preferred_clusters: Maximum concurrently active preferred clusters.
        :type max_active_preferred_clusters: cutlass.Constexpr
        :param max_active_fallback_clusters: Maximum concurrently active fallback clusters.
        :type max_active_fallback_clusters: cutlass.Constexpr
        :param stream: CUDA stream.
        :type stream: cuda.CUstream
        :param epilogue_op: Optional elementwise epilogue applied to the accumulator.
        :type epilogue_op: cutlass.Constexpr
        """

        def add_batch_mode(tensor: cute.Tensor) -> cute.Tensor:
            return cute.make_tensor(
                tensor.iterator,
                cute.prepend(tensor.layout, cute.make_layout(1), up_to_rank=3),
            )

        # Normalise A/B/C to rank-3 by prepending a batch mode of size 1 when
        # the input is 2D (non-batched).  This allows the rest of the kernel to
        # treat both batched (L, M, K) and non-batched (M, K) inputs uniformly
        # as (1, M, K) without any special-casing downstream.
        a = add_batch_mode(a)
        b = add_batch_mode(b)
        c = add_batch_mode(c)

        # Permute tensor modes from torch to cute convention
        # A: (L, M, K) -> (M, K, L)
        a = cute.make_tensor(a.iterator, cute.select(a.layout, [1, 2, 0]))
        # B: (L, K, N) -> (N, K, L)
        b = cute.make_tensor(b.iterator, cute.select(b.layout, [2, 1, 0]))
        # C: (L, M, N) -> (M, N, L)
        c = cute.make_tensor(c.iterator, cute.select(c.layout, [1, 2, 0]))

        # Capture dtype/layout info needed by _setup_attributes.
        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.c_dtype: type[cutlass.Numeric] = c.element_type
        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        tiled_mma = utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )
        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))

        # ------------------------------------------------------------------
        # TMA atoms for the preferred cluster
        # ------------------------------------------------------------------
        a_op_preferred = utils.sm100.cluster_shape_to_tma_atom_A(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_a_preferred, tma_tensor_a_preferred = cute.nvgpu.make_tiled_tma_atom_A(
            a_op_preferred,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )
        b_op_preferred = utils.sm100.cluster_shape_to_tma_atom_B(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_preferred, tma_tensor_b_preferred = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_preferred,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # ------------------------------------------------------------------
        # TMA atoms for the fallback cluster
        # ------------------------------------------------------------------
        a_op_fallback = utils.sm100.cluster_shape_to_tma_atom_A(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_tiled_tma_atom_A(
            a_op_fallback,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )
        b_op_fallback = utils.sm100.cluster_shape_to_tma_atom_B(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_fallback,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            # Response size is 4B * 4 elements
            self.num_clc_response_bytes = 16

        # ------------------------------------------------------------------
        # TMA atom for C output (cluster-independent)
        # ------------------------------------------------------------------
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), c, epi_smem_layout, self.epi_tile
            )

        # ------------------------------------------------------------------
        # Grid computation for preferred and fallback clusters
        # ------------------------------------------------------------------
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            # CLC: each cluster shape gets its own scheduler params so that
            # the dynamic load-balancer correctly scopes each cluster's tiles.
            # The per-cluster CLC params/grid computation is identical to the
            # base kernel's, so reuse the inherited helper rather than duplicating it.
            self.fallback_tile_sched_params, _ = (
                self._compute_grid_clc_dynamic_persistent_scheduler(
                    c,
                    self.cta_tile_shape_mnk,
                    self.fallback_cluster_shape_mn,
                )
            )
            self.preferred_tile_sched_params, preferred_grid = (
                self._compute_grid_clc_dynamic_persistent_scheduler(
                    c,
                    self.cta_tile_shape_mnk,
                    self.preferred_cluster_shape_mn,
                )
            )
        else:
            (
                self.preferred_tile_sched_params,
                preferred_grid,
                *_,
            ) = self._compute_preferred_cluster_grid(
                c,
                self.cta_tile_shape_mnk,
                self.preferred_cluster_shape_mn,
                max_active_preferred_clusters,
                self.fallback_cluster_shape_mn,
                max_active_fallback_clusters,
            )
            # Static scheduler derives tile coords from the shared (preferred-sized)
            # grid, so fallback clusters MUST reuse the preferred params.
            self.fallback_tile_sched_params = self.preferred_tile_sched_params

        # ------------------------------------------------------------------
        # Launch the mega-kernel with preferred cluster + fallback cluster
        # ------------------------------------------------------------------
        self.kernel(
            tiled_mma,
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            self.preferred_cluster_layout_vmnk,
            self.fallback_cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.preferred_tile_sched_params,
            self.fallback_tile_sched_params,
            epilogue_op,
        ).launch(
            grid=preferred_grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.preferred_cluster_shape_mn, 1),
            fallback_cluster=(*self.fallback_cluster_shape_mn, 1),
            stream=stream,
            smem_merge_branch_allocs=True,
        )

    # ------------------------------------------------------------------
    # Cluster-specific device function JIT (called from kernel below)
    # ------------------------------------------------------------------

    @cute.jit
    def cluster_specific_kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom | None,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        tile_sched_params: Union[
            utils.ClcDynamicPersistentTileSchedulerParams,
            utils.PersistentTileSchedulerParams,
        ],
        num_tma_producer: int,
        is_a_mcast: bool,
        is_b_mcast: bool,
        epilogue_op: cutlass.Constexpr,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: cute.Layout | cute.ComposedLayout | None,
        epi_tile: cute.Tile,
    ):
        """Cluster-specific inner kernel body.

        This function contains the full persistent GEMM loop parameterised by the
        cluster layout and TMA atoms for a single cluster shape (either preferred or
        fallback).  It is called from :meth:`kernel` after branching on the actual
        runtime cluster dimensions.

        :note: ``a_smem_layout_staged``, ``b_smem_layout_staged``,
            ``c_smem_layout_staged``, and ``epi_tile`` must be passed explicitly
            rather than captured via ``self.*`` because this function is called
            from a ``@cute.kernel`` region which is isolated — MLIR SSA values
            defined in the enclosing ``@cute.jit __call__`` scope cannot be
            referenced across the isolation boundary.

        :param tiled_mma: Tiled MMA atom.
        :type tiled_mma: cute.TiledMma
        :param tma_atom_a: TMA copy atom for operand A (multicast or unicast).
        :type tma_atom_a: cute.CopyAtom
        :param mA_mkl: Global A tensor (M, K, L) exposed to TMA.
        :type mA_mkl: cute.Tensor
        :param tma_atom_b: TMA copy atom for operand B.
        :type tma_atom_b: cute.CopyAtom
        :param mB_nkl: Global B tensor (N, K, L) exposed to TMA.
        :type mB_nkl: cute.Tensor
        :param tma_atom_c: TMA copy atom for output C (S2G), or None.
        :type tma_atom_c: cute.CopyAtom | None
        :param mC_mnl: Global output C tensor (M, N, L).
        :type mC_mnl: cute.Tensor
        :param cluster_layout_vmnk: Cluster layout for this branch (preferred or fallback).
        :type cluster_layout_vmnk: cute.Layout
        :param tile_sched_params: Tile scheduler parameters (same for both branches).
        :type tile_sched_params: utils.PersistentTileSchedulerParams
        :param num_tma_producer: Number of TMA producer threads for AB pipeline.
        :type num_tma_producer: int
        :param is_a_mcast: True when A is multicasted across the cluster.
        :type is_a_mcast: bool
        :param is_b_mcast: True when B is multicasted across the cluster.
        :type is_b_mcast: bool
        :param epilogue_op: Elementwise epilogue function.
        :type epilogue_op: cutlass.Constexpr
        :param a_smem_layout_staged: Staged SMEM layout for A (passed from kernel param).
        :type a_smem_layout_staged: cute.ComposedLayout
        :param b_smem_layout_staged: Staged SMEM layout for B (passed from kernel param).
        :type b_smem_layout_staged: cute.ComposedLayout
        :param c_smem_layout_staged: Staged SMEM layout for C, or None.
        :type c_smem_layout_staged: cute.Layout | cute.ComposedLayout | None
        :param epi_tile: Epilogue tile shape (passed from kernel param).
        :type epi_tile: cute.Tile
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch TMA descriptors
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        # CTA coordinates inside the cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        is_first_cta_in_cluster = cta_rank_in_cluster == 0
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        # Shared memory barriers and helpers
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):

            @cute.struct
            class SharedStorage:
                ab_full_mbar_ptr: cute.struct.MemRange[
                    cutlass.Int64, self.num_ab_stage * 2
                ]
                acc_full_mbar_ptr: cute.struct.MemRange[
                    cutlass.Int64, self.num_acc_stage * 2
                ]
                tmem_dealloc_mbar: cutlass.Int64
                tmem_holding_buf: cutlass.Int32
                clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 2]
                clc_response_align_bytes = self.num_clc_response_bytes
                clc_response: cute.struct.Align[
                    cute.struct.MemRange[cutlass.Int32, 4],
                    clc_response_align_bytes,
                ]

        else:

            @cute.struct
            class SharedStorage:
                ab_full_mbar_ptr: cute.struct.MemRange[
                    cutlass.Int64, self.num_ab_stage * 2
                ]
                acc_full_mbar_ptr: cute.struct.MemRange[
                    cutlass.Int64, self.num_acc_stage * 2
                ]
                tmem_dealloc_mbar: cutlass.Int64
                tmem_holding_buf: cutlass.Int32

        smem = utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # AB mainloop pipeline (TMA → SMEM → MMA)
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()

        # Accumulator pipeline (MMA → TMEM → epilogue)
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

        # CLC fetch pipeline (CLC dynamic scheduler only)
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            clc_pipeline_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread
            )
            cluster_size = cute.size(cluster_layout_vmnk)
            num_clc_consumer_threads = 32 * (
                1 + cluster_size * (1 + len(self.epilogue_warp_id) + 1)
            )
            clc_pipeline_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_clc_consumer_threads
            )
            clc_pipeline = pipeline.PipelineClcFetchAsync.create(
                barrier_storage=storage.clc_mbar_ptr.data_ptr(),
                num_stages=self.num_clc_stage,
                producer_group=clc_pipeline_producer_group,
                consumer_group=clc_pipeline_consumer_group,
                tx_count=self.num_clc_response_bytes,
                cta_layout_vmnk=cluster_layout_vmnk,
                defer_sync=True,
            )

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        tmem_dealloc_barrier = None
        if cutlass.const_expr(not self.use_tma_store):
            tmem_dealloc_barrier = pipeline.NamedBarrier(
                barrier_id=self.tmem_dealloc_sync_bar_id,
                num_threads=32 * len(self.epilogue_warp_id),
            )
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        pipeline_init_arrive(cluster_shape_mn=cluster_layout_vmnk, is_relaxed=True)

        # CLC state (CLC dynamic scheduler only)
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            clc_response_ptr = storage.clc_response.data_ptr()
            clc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_clc_stage
            )

        # SMEM tensors for A and B
        # SMEM source address needs to be 128-byte aligned for TMA
        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )

        # TMA multicast masks (needed for multicast TMA and 2-CTA MMA coordination)
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(is_a_mcast or is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        # Global tensor tiles partitioned per CTA
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)

        # TMA partition for A: map CTA coord → SMEM slot and global slice
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA partition for B
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        # MMA register fragments
        tCrA = tiled_mma.make_fragment_A(sA)
        tCrB = tiled_mma.make_fragment_B(sB)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        pipeline_init_wait(cluster_shape_mn=cluster_layout_vmnk)

        # Construct the tile scheduler (shared across all warp roles)
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            tile_sched = utils.ClcDynamicPersistentTileScheduler.create(
                tile_sched_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                clc_response_ptr,
            )
        else:
            tile_sched = utils.StaticPersistentTileScheduler.create(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
        work_tile = tile_sched.initial_work_tile_info()

        # ------------------------------------------------------------------
        # Warp-specialised TMA load loop
        # ------------------------------------------------------------------
        if warp_idx == self.tma_warp_id:
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                    )

                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()

                if cutlass.const_expr(self.use_clc_dynamic_scheduler):
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()
                else:
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

            ab_producer.tail()

        # ------------------------------------------------------------------
        # Warp-specialised scheduler warp (CLC dynamic scheduler only)
        # ------------------------------------------------------------------
        if cutlass.const_expr(self.use_clc_dynamic_scheduler):
            if warp_idx == self.sched_warp_id and is_first_cta_in_cluster:
                clc_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.ProducerConsumer, self.num_clc_stage
                )

                while work_tile.is_valid_tile:
                    clc_pipeline.producer_acquire(clc_producer_state)
                    mbarrier_addr = clc_pipeline.producer_get_barrier(
                        clc_producer_state
                    )
                    tile_sched.advance_to_next_work(mbarrier_addr)
                    clc_producer_state.advance()

                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()

                clc_pipeline.producer_tail(clc_producer_state)

        # ------------------------------------------------------------------
        # Warp-specialised MMA loop
        # ------------------------------------------------------------------
        if warp_idx == self.mma_warp_id:
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblk_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblk_crd = (None, None, kblk_idx, handle.index)
                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblk_crd],
                                tCrB[kblk_crd],
                                tCtAcc,
                            )
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                        handle.release()

                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                if cutlass.const_expr(self.use_clc_dynamic_scheduler):
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()
                else:
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

            acc_pipeline.producer_tail(acc_producer_state)

        sC = None
        if cutlass.const_expr(self.use_tma_store):
            sC = smem.allocate_tensor(
                element_type=self.c_dtype,
                layout=c_smem_layout_staged.outer,
                byte_alignment=128,
                swizzle=c_smem_layout_staged.inner,
            )

        # ------------------------------------------------------------------
        # Warp-specialised epilogue loop
        # ------------------------------------------------------------------
        if warp_idx < self.mma_warp_id:
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            if cutlass.const_expr(self.use_tma_store):
                assert tma_atom_c is not None and sC is not None
                c_producer_group = pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    32 * len(self.epilogue_warp_id),
                )
                c_pipeline = pipeline.PipelineTmaStore.create(
                    num_stages=self.num_c_stage, producer_group=c_producer_group
                )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                if cutlass.const_expr(not self.use_clc_dynamic_scheduler):
                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()
                else:
                    # CLC epilogue warps don't call advance_to_next_work (only
                    # the sched warp does), so track the tile count locally for
                    # correct C-store pipeline buffer indexing.
                    tile_sched._num_tiles_executed += Int32(1)

                num_tiles_executed = tile_sched.num_tiles_executed

                if cutlass.const_expr(self.use_tma_store):
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
                else:
                    acc_consumer_state = utils.gemm.sm100.epilogue(
                        self,
                        tidx,
                        tCtAcc_base,
                        tCgC,
                        epi_tile,
                        epilogue_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                    )

                if cutlass.const_expr(self.use_clc_dynamic_scheduler):
                    clc_pipeline.consumer_wait(clc_consumer_state)
                    work_tile = tile_sched.get_current_work()
                    clc_pipeline.consumer_release(clc_consumer_state)
                    clc_consumer_state.advance()

            if cutlass.const_expr(self.use_tma_store):
                c_pipeline.producer_tail()
            else:
                tmem_dealloc_barrier.arrive_and_wait()

            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

    # ------------------------------------------------------------------
    # GPU device kernel: routes to cluster_specific_kernel
    # ------------------------------------------------------------------

    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a_preferred: cute.CopyAtom,
        tma_tensor_a_preferred: cute.Tensor,
        tma_atom_a_fallback: cute.CopyAtom,
        tma_tensor_a_fallback: cute.Tensor,
        tma_atom_b_preferred: cute.CopyAtom,
        tma_tensor_b_preferred: cute.Tensor,
        tma_atom_b_fallback: cute.CopyAtom,
        tma_tensor_b_fallback: cute.Tensor,
        tma_atom_c: cute.CopyAtom | None,
        mC_mnl: cute.Tensor,
        preferred_cluster_layout_vmnk: cute.Layout,
        fallback_cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: cute.Layout | cute.ComposedLayout | None,
        epi_tile: cute.Tile,
        preferred_tile_sched_params: Union[
            utils.ClcDynamicPersistentTileSchedulerParams,
            utils.PersistentTileSchedulerParams,
        ],
        fallback_tile_sched_params: Union[
            utils.ClcDynamicPersistentTileSchedulerParams,
            utils.PersistentTileSchedulerParams,
        ],
        epilogue_op: cutlass.Constexpr,
    ):
        """Mega-kernel that dispatches to the appropriate cluster-specific body.

        At runtime, each CTA checks its actual cluster dimensions to determine
        whether it belongs to a preferred or fallback cluster and calls
        :meth:`cluster_specific_kernel` with the matching parameters.

        :note: ``smem_merge_branch_allocs=True`` must be set at launch so that
               the shared-memory allocations from both branches are merged.
        """
        cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
        is_preferred_cluster = (
            cbdim_x == self.preferred_cluster_shape_mn[0]
            and cbdim_y == self.preferred_cluster_shape_mn[1]
            and cbdim_z == 1
        )

        if is_preferred_cluster:
            self.cluster_specific_kernel(
                tiled_mma,
                tma_atom_a_preferred,
                tma_tensor_a_preferred,
                tma_atom_b_preferred,
                tma_tensor_b_preferred,
                tma_atom_c,
                mC_mnl,
                preferred_cluster_layout_vmnk,
                preferred_tile_sched_params,
                self.num_preferred_mcast_ctas_a + self.num_preferred_mcast_ctas_b - 1,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
                epilogue_op,
                a_smem_layout_staged,
                b_smem_layout_staged,
                c_smem_layout_staged,
                epi_tile,
            )
        else:
            self.cluster_specific_kernel(
                tiled_mma,
                tma_atom_a_fallback,
                tma_tensor_a_fallback,
                tma_atom_b_fallback,
                tma_tensor_b_fallback,
                tma_atom_c,
                mC_mnl,
                fallback_cluster_layout_vmnk,
                fallback_tile_sched_params,
                self.num_fallback_mcast_ctas_a + self.num_fallback_mcast_ctas_b - 1,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
                epilogue_op,
                a_smem_layout_staged,
                b_smem_layout_staged,
                c_smem_layout_staged,
                epi_tile,
            )

    # ------------------------------------------------------------------
    # Grid computation for preferred cluster
    # ------------------------------------------------------------------

    @staticmethod
    def _compute_preferred_cluster_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: tuple[int, int, int],
        preferred_cluster_shape_mn: tuple[int, int],
        max_active_preferred_clusters: cutlass.Constexpr,
        fallback_cluster_shape_mn: tuple[int, int],
        max_active_fallback_clusters: cutlass.Constexpr,
    ) -> tuple[
        utils.PersistentTileSchedulerParams,
        tuple[int, int, int],
        utils.PersistentTileSchedulerParams,
        tuple[int, int, int],
    ]:
        """Compute launch grids for the preferred and fallback cluster shapes.

        The preferred grid is sized so that its total CTA count does not exceed the
        fallback grid's total CTA count, and is rounded up to a multiple of the
        preferred cluster size.  This ensures the hardware can fill the preferred
        grid with a mix of preferred and fallback clusters.

        :param c: Output tensor C (M, N, L) used to determine tile count.
        :type c: cute.Tensor
        :param cta_tile_shape_mnk: CTA tile shape (M, N, K).
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param preferred_cluster_shape_mn: Preferred cluster shape (ClusterM, ClusterN).
        :type preferred_cluster_shape_mn: tuple[int, int]
        :param max_active_preferred_clusters: Maximum active preferred clusters.
        :type max_active_preferred_clusters: cutlass.Constexpr
        :param fallback_cluster_shape_mn: Fallback cluster shape (ClusterM, ClusterN).
        :type fallback_cluster_shape_mn: tuple[int, int]
        :param max_active_fallback_clusters: Maximum active fallback clusters.
        :type max_active_fallback_clusters: cutlass.Constexpr

        :returns: (preferred_tile_sched_params, preferred_grid,
                   fallback_tile_sched_params, fallback_grid)
        :rtype: tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int],
                      utils.PersistentTileSchedulerParams, tuple[int, int, int]]
        """
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape

        # Compute scheduler params for preferred cluster
        preferred_cluster_shape_mnl = (*preferred_cluster_shape_mn, 1)
        preferred_tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, preferred_cluster_shape_mnl
        )
        preferred_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            preferred_tile_sched_params, max_active_preferred_clusters
        )

        # Compute scheduler params for fallback cluster
        fallback_cluster_shape_mnl = (*fallback_cluster_shape_mn, 1)
        fallback_tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, fallback_cluster_shape_mnl
        )
        fallback_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            fallback_tile_sched_params, max_active_fallback_clusters
        )

        # Round the preferred grid up so it is a multiple of the preferred cluster
        preferred_grid = cute.round_up(preferred_grid, preferred_cluster_shape_mnl)

        # Cap the preferred launch grid so that its max CTA count ≤ the fallback
        # grid's max CTA count (which approximates the GPU's total SM capacity).
        # The preferred grid is the actual CUDA launch grid, so it cannot exceed
        # the hardware's CTA capacity.  At runtime, the vast majority of CTAs
        # will run as preferred clusters; only the small boundary fraction that
        # cannot fill a complete preferred cluster will run as fallback clusters.
        #
        # NOTE: when the problem is smaller than a single preferred cluster tile
        # (M < preferred_cluster_m * cta_m OR N < preferred_cluster_n * cta_n),
        # ``max_fallback_ctas < preferred_cluster_size`` and this floor
        # division would yield 0, producing a zero-sized grid Z dim and
        # triggering ``cudaErrorInvalidValue`` at launch. Such problem sizes
        # must be rejected by the caller; see the host-side guard in
        # ``PersistentDenseGemmPreferredClusterOperator._compile``.
        preferred_cluster_size = (
            preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
        )
        max_fallback_ctas = fallback_grid[0] * fallback_grid[1] * fallback_grid[2]
        max_preferred_clusters_count = max_fallback_ctas // preferred_cluster_size
        preferred_grid = (
            preferred_grid[0],
            preferred_grid[1],
            max_preferred_clusters_count,
        )

        return (
            preferred_tile_sched_params,
            preferred_grid,
            fallback_tile_sched_params,
            fallback_grid,
        )
