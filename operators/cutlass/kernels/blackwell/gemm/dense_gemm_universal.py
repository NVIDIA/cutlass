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

import argparse
import dataclasses
import sys
from functools import lru_cache
from pathlib import Path
from typing import Literal

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.utils as utils
from cutlass import testing
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cutlass_dsl import Boolean, Int32
from cutlass.pipeline import PipelineEmpty, pipeline_init_arrive, pipeline_init_wait
from cutlass.utils import create_cute_tensor_for_fp8, is_fp8_dtype

if __name__ == "__main__":
    # Put the runtime/python/ root on sys.path so `import cutlass.kernels...`
    # resolves when this file is run as a standalone script. `cutlass` is an
    # implicit namespace package; this tree contributes `cutlass.kernels`, and it
    # merges with the DSL's `cutlass` (cute, base_dsl, ...) provided on the path.
    # From gemm/blackwell/ that root is four levels up.
    current_dir = Path(__file__).resolve().parent
    sys.path.insert(0, str(current_dir / "../../../../"))

from cutlass.kernels.utils import tile_scheduler

"""
A high-performance cluster launch control(CLC) dynamic persistent batched dense GEMM example
for the NVIDIA Blackwell SM100 architecture using CUTE DSL and the new tile scheduler API.

The CLC dynamic persistent scheduling technique performs dynamic loading balancing.
It has the ability to adapt available SMs rather than a statically selected number. To support this,
a new instruction is introduced to query for a new tile to compute. This new instruction is similar
to programmatic multicast in context of clusters in that the same starting tile ID for a given cluster
is broadcasted to all threadblocks in the cluster.
See `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-clusterlaunchcontrol-try-cancel>`.

- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support CLC dynamic persistent tile scheduling to have near perfect load balancing
    - Support warp specialization to avoid explicit pipelining between mainloop load and mma

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp:
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Type convert C matrix to output type.
    - Optionally store C matrix from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations,
      or directly store C matrix from registers (RMEM) to global memory (GMEM) without TMA operations.
    - Optionally accept an elementwise lambda function epilogue_op to apply to the output tensor:
      e.g., relu can set epilogue_op = lambda x: cute.where(x > 0, x, cute.full_like(x, 0))
4. Optionally has a scheduler warp if the user requests for dynamic persistence.

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Input arguments to this example is same as dense_gemm.py.

.. code-block:: bash

    python examples/cute/blackwell/kernel/dense_gemm/dense_gemm_persistent_dynamic.py                          \
      --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                  \
      --mma_tiler_mn 256,128 --cluster_shape_mn 2,1                             \
      --mnkl 8192,8192,8192,1                                                   \
      --use_tma_store --use_2cta_instrs

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/cute/blackwell/kernel/dense_gemm/dense_gemm_persistent_dynamic.py                     \
      --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32                 \
      --mma_tiler_mn 256,128 --cluster_shape_mn 2,1                            \
      --mnkl 8192,8192,8192,1                                                  \
      --use_tma_store --use_2cta_instrs                                        \
      --warmup_iterations 1 --iterations 10 --ref_check_device skipped


Constraints are same as dense_gemm.py:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2),
  see detailed valid dtype combinations in below PersistentDenseGemmKernel class documentation
* A/B tensor must have the same data type
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* Mma tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* OOB tiles are not allowed when TMA store is disabled
"""


def _compute_stages(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: tuple[int, int, int],
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    smem_capacity: int,
    tile_scheduler_bytes: int,
    occupancy: int,
    use_tma_store: bool,
    c_smem_layout: cute.Layout | None,
) -> tuple[int, int, int]:
    """Computes the number of stages for A/B/C operands based on heuristics.

    :param tiled_mma: The tiled MMA object defining the core computation.
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
    :type mma_tiler_mnk: tuple[int, int, int]
    :param a_dtype: Data type of operand A.
    :type a_dtype: type[cutlass.Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[cutlass.Numeric]
    :param c_dtype: Data type of operand C (output).
    :type c_dtype: type[cutlass.Numeric]
    :param smem_capacity: Total available shared memory capacity in bytes.
    :type smem_capacity: int
    :param tile_scheduler_bytes: Shared memory requested by tile scheduler in bytes.
    :type tile_scheduler_bytes: int
    :param occupancy: Target number of CTAs per SM (occupancy).
    :type occupancy: int
    :param use_tma_store: Whether TMA store is enabled.
    :type use_tma_store: bool
    :param c_smem_layout: Layout of C operand in shared memory, or None if not using TMA store.
    :type c_smem_layout: Union[cute.Layout, None]

    :return: A tuple containing the computed number of stages for:
             (ACC stages, A/B operand stages, C stages)
    :rtype: tuple[int, int, int]
    """
    # Default ACC stages
    num_acc_stage = 2

    # Default C stages
    num_c_stage = 2 if use_tma_store else 0

    # Calculate smem layout and size for one stage of A, B, and C with 1-stage
    a_smem_layout_stage_one = utils.sm100.make_smem_layout_a(
        tiled_mma, mma_tiler_mnk, a_dtype, 1
    )
    b_smem_layout_staged_one = utils.sm100.make_smem_layout_b(
        tiled_mma, mma_tiler_mnk, b_dtype, 1
    )

    ab_bytes_per_stage = cute.size_in_bytes(
        a_dtype, a_smem_layout_stage_one
    ) + cute.size_in_bytes(b_dtype, b_smem_layout_staged_one)
    mbar_helpers_bytes = 1024

    if use_tma_store:
        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout)
        c_bytes = c_bytes_per_stage * num_c_stage
    else:
        c_bytes = 0

    # Calculate A/B stages:
    # Start with total smem per CTA (capacity / occupancy)
    # Subtract reserved bytes and initial C stages bytes
    # Divide remaining by bytes needed per A/B stage
    num_ab_stage = (
        smem_capacity // occupancy
        - (mbar_helpers_bytes + c_bytes + tile_scheduler_bytes)
    ) // ab_bytes_per_stage

    # Refine epilogue stages:
    # Calculate remaining smem after allocating for A/B stages and reserved bytes
    # Add remaining unused smem to epilogue
    if use_tma_store:
        num_c_stage += (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_ab_stage
            - occupancy * (mbar_helpers_bytes + c_bytes)
        ) // (occupancy * c_bytes_per_stage)
    return num_acc_stage, num_ab_stage, num_c_stage


class PersistentDenseGemmKernel:
    """Implement batched matrix multiplication (C = A x B) with support for various data types and architectural features specific to Blackwell GPUs with persistent tile scheduling and warp specialization.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: tuple[int, int]
    :param use_tma_store: Whether to use Tensor Memory Access (TMA) for storing results
    :type use_tma_store: bool

    :note: In current version, A and B tensor must have the same data type
        - i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported

    :note: Supported A/B data types:
        - TFloat32
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported C data types:
        - Float32 (for float32 and int32 accumulator data types)
        - Int32 (for float32 and int32 accumulator data types)
        - Float16/BFloat16 (for fp32, fp16, and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16

    **Example:**
        gemm = PersistentDenseGemmKernel(
            acc_dtype=cutlass.Float32,
            use_2cta_instrs=True,
            mma_tiler_mn=(128, 128),
            cluster_shape_mn=(2, 2),
            use_tma_store=True
        )
        gemm(
            a, b, c, stream, workspace,
            Int32(swizzle_size), Boolean(raster_along_m),
            Int32(max_active_clusters_fallback), epilogue_op
        )
    """

    def __init__(
        self,
        acc_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        use_tma_store: bool,
        split_k: int = 1,
        work_strategy: Literal["grid", "static", "clc"] = "grid",
        rasterization_strategy: Literal["none", "affine"] = "none",
        reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
        num_scheduler_stages: int = 1,
        use_pdl: bool = False,
        use_reduction_pdl: bool = False,
        fallback_cluster_shape_mn: tuple[int, int] | None = None,
        precompute_scheduler_params: bool = False,
    ):
        """Initializes the configuration for a Blackwell dense GEMM kernel.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data types for MMA accumulator.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.
            - use_2cta_instrs: Boolean indicating if the tcgen05 MMA variant
              with cta_group=2 should be used.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        3. Output C tensor store mode:
            - use_tma_store: Boolean indicating whether to use Tensor Memory Access (TMA) for storing results.

        4. Split-K:
            - split_k: Number of K-partitions of each output tile.

        5. Tile scheduling: the work / rasterization / reduction strategies are
           named explicitly, and the swizzle size and rasterization order are
           separate runtime settings. Whether a setting is compatible with the chosen
           strategy is the strategy's call (``can_implement``).

        :param acc_dtype: Data type of the accumulator.
        :type acc_dtype: type[cutlass.Numeric]
        :param mma_tiler_mn: tuple (M, N) shape of the MMA instruction.
        :type mma_tiler_mn: tuple[int, int]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param cluster_shape_mn: tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: tuple[int, int]
        :param use_tma_store: Use Tensor Memory Access (TMA) or normal store for output C tensor.
        :type use_tma_store: bool
        :param split_k: split-K factor: number of K-partitions per output tile.
        :type split_k: int
        :param work_strategy: Tile scheduler work strategy, defaults to "grid".
        :type work_strategy: Literal["grid", "static", "clc"]
        :param rasterization_strategy: Tile scheduler rasterization strategy,
            defaults to "none".
        :type rasterization_strategy: Literal["none", "affine"]
        :param reduction_strategy: Tile scheduler reduction strategy; must be
            "none" exactly when ``split_k`` is 1. Defaults to "none".
        :type reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"]
        :param num_scheduler_stages: Number of tile scheduler pipeline stages, defaults to 4.
        :type num_scheduler_stages: int
        :param use_pdl: Whether to use inter-operator PDL: the GEMM is
            launched with the PDL attribute (and therefore waits on the
            previous grid before its first load), and the operator's last
            kernel signals dependent grids at its end. Defaults to False.
        :type use_pdl: bool
        :param use_reduction_pdl: Whether to use intra-operator PDL between
            the GEMM and reduction kernel (2-kernel split-K only): the
            reduction kernel is launched with the PDL attribute and waits
            before its first workspace read. Defaults to False.
        :type use_reduction_pdl: bool
        :param fallback_cluster_shape_mn: tuple (ClusterM, ClusterN) shape of the fallback cluster.
        :type fallback_cluster_shape_mn: tuple[int, int] | None
        :param precompute_scheduler_params: Prepare scheduler state on the host;
            requires static/affine/no-reduction scheduling. Defaults to False.
        :type precompute_scheduler_params: bool
        """
        self.acc_dtype: type[cutlass.Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.use_tma_store = use_tma_store
        self.use_pdl = use_pdl
        self.use_reduction_pdl = use_reduction_pdl
        self.precompute_scheduler_params = precompute_scheduler_params
        self.arch = "sm_100"

        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape_mn = cluster_shape_mn
        else:
            self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

        self.work_strategy = work_strategy
        self.rasterization_strategy = rasterization_strategy
        self.reduction_strategy = reduction_strategy
        self.num_sched_stages = num_scheduler_stages
        self.split_k = split_k

        _cta_tile_shape_mnk = (
            self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
            self.mma_tiler[1],
            1,
        )
        self.tile_scheduler_template_params = (
            tile_scheduler.TileSchedulerTemplateParams(
                acc_dtype=acc_dtype,
                work_strategy=self.work_strategy,
                rasterization_strategy=self.rasterization_strategy,
                reduction_strategy=self.reduction_strategy,
                num_scheduler_stages=self.num_sched_stages,
                cluster_shape_mn=self.cluster_shape_mn,
                split_k=split_k,
                cta_tile_shape_mnk=_cta_tile_shape_mnk,
                fallback_cluster_shape_mn=self.fallback_cluster_shape_mn,
            )
        )
        self.tile_scheduler_template = tile_scheduler.build_tile_scheduler_template(
            self.tile_scheduler_template_params
        )

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Set specialized warp ids
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5

        warp_ids = [
            self.mma_warp_id,
            self.tma_warp_id,
            *self.epilogue_warp_id,
        ]

        if self.tile_scheduler_template.requires_scheduler_warp:
            self.sched_warp_id = 6
            warp_ids.append(self.sched_warp_id)

        self.threads_per_cta = 32 * len(warp_ids)

        # Set barrier id for cta sync, epilogue sync and tmem ptr sync
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

    def get_gmem_workspace_size(self, problem_shape_mnl) -> int:
        """Host-side GMEM scheduler workspace size, in bytes, for this problem.

        Delegates to the tile scheduler template (built host-side in __init__),
        which sums the per-provider GMEM requirements. Returns 0 when no provider
        needs a GMEM workspace.

        :param problem_shape_mnl: Problem shape as (M, N, L).
        :return: Required GMEM workspace size in bytes.
        :rtype: int
        """
        return self.tile_scheduler_template.get_gmem_workspace_size(problem_shape_mnl)

    def initialize_workspace(self, workspace, problem_shape_mnl) -> None:
        """Host-side fill of the GMEM scheduler workspace, before it is uploaded.

        Delegates to the tile scheduler template, which populates the int8
        staging buffer in place. Plain host method -- not traced. Only reached
        when :meth:`get_gmem_workspace_size` is nonzero (see the guard in
        ``compile_bmm``).

        :param workspace: 1-D int8 staging buffer of length
            :meth:`get_gmem_workspace_size`, filled in place.
        :param problem_shape_mnl: Problem shape as (M, N, L).
        :rtype: None
        """
        self.tile_scheduler_template.initialize_workspace(workspace, problem_shape_mnl)

    def lazily_set_cta_tile_shape_mnk(self, cta_tile_shape_mnk) -> None:
        """Rebuild the scheduler template with the real CTA tile shape.

        :param cta_tile_shape_mnk: the real CTA tile shape (M, N, K)
        """
        cta_tile_shape_mnk = tuple(cta_tile_shape_mnk)
        if self.tile_scheduler_template_params.cta_tile_shape_mnk == cta_tile_shape_mnk:
            return
        self.tile_scheduler_template_params = dataclasses.replace(
            self.tile_scheduler_template_params,
            cta_tile_shape_mnk=cta_tile_shape_mnk,
        )
        self.tile_scheduler_template = tile_scheduler.build_tile_scheduler_template(
            self.tile_scheduler_template_params
        )

    def _create_tiled_mma(self):
        return utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs.

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/B/C stage counts in shared memory
        - Computing A/B/C shared memory layout
        - Computing tensor memory allocation columns
        """
        # Configure tiled mma
        tiled_mma = self._create_tiled_mma()

        # Compute mma/cluster/tile shapes
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.lazily_set_cta_tile_shape_mnk(self.cta_tile_shape_mnk)

        # Compute cluster layout (M,N only -- used for TMA multicast)
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Full cluster layout including split_k Z-dimension (used for CLC pipeline signaling)
        self.clc_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.tile_scheduler_template_params.cluster_shape),
            (tiled_mma.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        # Set up for fallback cluster
        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.fallback_cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Full cluster layout including split_k Z-dimension (used for CLC pipeline signaling)
        self.clc_fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(
                self.tile_scheduler_template_params.fallback_cluster_shape
            ),
            (tiled_mma.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a_fallback = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_mcast_ctas_b_fallback = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_a_mcast_fallback = self.num_mcast_ctas_a_fallback > 1
        self.is_b_mcast_fallback = self.num_mcast_ctas_b_fallback > 1

        # Compute epilogue subtile
        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = utils.sm100.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()

        tile_sched_smem_bytes = self.tile_scheduler_template.get_smem_workspace_size()

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        (
            self.num_acc_stage,
            self.num_ab_stage,
            self.num_c_stage,
        ) = _compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.smem_capacity,
            tile_sched_smem_bytes,
            self.occupancy,
            self.use_tma_store,
            c_smem_layout,
        )

        # Compute A/B/C shared memory layout
        self.a_smem_layout_staged = utils.sm100.make_smem_layout_a(
            tiled_mma, self.mma_tiler, self.a_dtype, self.num_ab_stage
        )
        self.b_smem_layout_staged = utils.sm100.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_ab_stage
        )

        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = utils.sm100.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

        # Compute the number of tensor memory allocation columns
        self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
            tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
        )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        stream: cuda.CUstream,
        workspace: cute.Pointer,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        max_active_clusters_fallback: Int32,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute the GEMM operation in the following steps.

        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors
        - Compute grid size with regard to hardware constraints
        - Define shared storage for kernel
        - Launch the kernel synchronously

        :param a: Input tensor A
        :type a: cute.Tensor
        :param b: Input tensor B
        :type b: cute.Tensor
        :param c: Output tensor C
        :type c: cute.Tensor
        :param stream: CUDA stream for asynchronous execution
        :type stream: cuda.CUstream
        :param max_active_clusters_fallback: Occupancy cap on concurrently resident
            fallback clusters (launch-time value; see ``query_max_active_clusters``).
            Only the ``static`` work strategy uses it (its grid is one wave).
        :type max_active_clusters_fallback: Int32
        :param epilogue_op: Optional elementwise lambda function to apply to the output tensor
        :type epilogue_op: cutlass.Constexpr
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        :raises AssertionError: If OOB (Out-Of-Bounds) tiles are present when TMA store is disabled.
        """
        # Setup static attributes before smem/grid/tma computation
        # NOTE: on this class, self.c_dtype is the dtype the MAIN kernel stores,
        # because everything downstream -- the epilogue tile, C smem staging, the
        # TMA store atom, and the shared utils.gemm.sm100 epilogue helpers (which
        # read gemm_kernel.c_dtype for fragment dtypes, casts, and copy sizing) --
        # derives from it. gmem_output_type() selects acc_dtype for GMEM
        # two-kernel split-K (kernel 1 stores full-precision partials) and the
        # user's C dtype otherwise; the user's dtype is kept in self.out_dtype
        # (the final output dtype), which the reduction kernel uses for its
        # epilogue cast and store into the user's C.

        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.c_dtype: type[cutlass.Numeric] = c.element_type
        self.out_dtype: type[cutlass.Numeric] = self.c_dtype
        if cutlass.const_expr(self.tile_scheduler_template_params.is_gmem_splitk):
            self.c_dtype = self.acc_dtype
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_dtype} != {self.b_dtype}")

        tiled_mma = self._create_tiled_mma()

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        b_smem_layout = cute.slice_(self.b_smem_layout_staged, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # Setup TMA load for A - FALLBACK
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

        # Setup TMA load for B - FALLBACK
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

        # Setup TMA store, if requested, for C
        tma_atom_c, tensor_c = self.tile_scheduler_template.get_gmem_tma(
            self.use_tma_store, workspace, c, self.c_smem_layout_staged, self.epi_tile
        )

        precomputed_sched_params = None
        if cutlass.const_expr(self.precompute_scheduler_params):
            precomputed_sched_params = (
                self.tile_scheduler_template.prepare_sched_params(
                    c.shape,
                    cute.ceil_div(a.shape[1], self.mma_tiler[2]),
                    swizzle_size,
                    raster_along_m,
                )
            )
        grid = self.tile_scheduler_template.get_grid_shape(
            c.shape,
            swizzle_size,
            raster_along_m,
            max_active_clusters_fallback,
            precomputed_sched_params=precomputed_sched_params,
        )

        # Launch the kernel synchronously
        self.mixed_cluster_kernel(
            tiled_mma,
            (tma_atom_a, tma_atom_a_fallback),
            (tma_tensor_a, tma_tensor_a_fallback),
            (tma_atom_b, tma_atom_b_fallback),
            (tma_tensor_b, tma_tensor_b_fallback),
            tma_atom_c,
            tensor_c,
            (self.cluster_layout_vmnk, self.fallback_cluster_layout_vmnk),
            (self.clc_cluster_layout_vmnk, self.clc_fallback_cluster_layout_vmnk),
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            workspace,
            swizzle_size,
            raster_along_m,
            epilogue_op,
            precomputed_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.tile_scheduler_template_params.cluster_shape,),
            fallback_cluster=(
                *self.tile_scheduler_template_params.fallback_cluster_shape,
            ),
            stream=stream,
            use_pdl=self.use_pdl,
            smem_merge_branch_allocs=True,
        )

        if cutlass.const_expr(self.tile_scheduler_template.is_gmem_splitk):
            self.tile_scheduler_template.splitk_reduction(
                workspace,
                c,
                a.shape[1],
                epilogue_op,
                stream,
                use_pdl=self.use_pdl,
                use_reduction_pdl=self.use_reduction_pdl,
            )

        return

    @cute.kernel
    def mixed_cluster_kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: tuple[cute.CopyAtom, cute.CopyAtom],
        mA_mkl: tuple[cute.Tensor, cute.Tensor],
        tma_atom_b: tuple[cute.CopyAtom, cute.CopyAtom],
        mB_nkl: tuple[cute.Tensor, cute.Tensor],
        tma_atom_c: cute.CopyAtom | None,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: tuple[cute.Layout, cute.Layout],
        clc_cluster_layout_vmnk: tuple[cute.Layout, cute.Layout],
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: cute.Layout | cute.ComposedLayout | None,
        epi_tile: cute.Tile,
        tile_sched_gmem_workspace_ptr: cute.Pointer,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        epilogue_op: cutlass.Constexpr,
        precomputed_sched_params: tile_scheduler.TileSchedulerPrecomputedParams
        | None = None,
    ):
        """GPU device kernel performing the Persistent batched GEMM computation with mixed cluster support.

        This kernel supports preferred and fallback clusters, meaning that it tries to launch with
        the preferred_cluster_shape_mn as its priority, but if at runtime, there is not enough
        resources available to do so, it then uses the fallback_cluster_shape_mn
        """
        if cutlass.const_expr(
            any(
                self.cluster_shape_mn[i] != self.fallback_cluster_shape_mn[i]
                for i in range(2)
            )
        ):
            # Get cluster coordinates to determine if this is a preferred cluster
            cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
            is_preferred_cluster = (
                cbdim_x == self.cluster_shape_mn[0]
                and cbdim_y == self.cluster_shape_mn[1]
            )
        else:
            # Skip the block_in_cluster_dim check when mixed cluster is not needed
            is_preferred_cluster = True

        # mega-kernel approach has 2 mutually exclusive code branches, only one path runs per launch,
        # specify `smem_merge_branch_allocs=True` at launch to enables shared memory reuse between two paths
        if is_preferred_cluster:
            self.kernel(
                tiled_mma,
                tma_atom_a[0],
                mA_mkl[0],
                tma_atom_b[0],
                mB_nkl[0],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[0],
                clc_cluster_layout_vmnk[0],
                a_smem_layout_staged,
                b_smem_layout_staged,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_gmem_workspace_ptr,
                swizzle_size,
                raster_along_m,
                epilogue_op,
                self.cluster_shape_mn,
                self.is_a_mcast,
                self.is_b_mcast,
                precomputed_sched_params,
            )
        else:
            self.kernel(
                tiled_mma,
                tma_atom_a[1],
                mA_mkl[1],
                tma_atom_b[1],
                mB_nkl[1],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[1],
                clc_cluster_layout_vmnk[1],
                a_smem_layout_staged,
                b_smem_layout_staged,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_gmem_workspace_ptr,
                swizzle_size,
                raster_along_m,
                epilogue_op,
                self.fallback_cluster_shape_mn,
                self.is_a_mcast_fallback,
                self.is_b_mcast_fallback,
                precomputed_sched_params,
            )

    # GPU device kernel
    @cute.jit
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom | None,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        clc_cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: cute.Layout | cute.ComposedLayout | None,
        epi_tile: cute.Tile,
        tile_sched_gmem_workspace_ptr: cute.Pointer,
        swizzle_size: Int32,
        raster_along_m: Boolean,
        epilogue_op: cutlass.Constexpr,
        cluster_shape_mn: tuple[int, int],
        is_a_mcast: bool,
        is_b_mcast: bool,
        precomputed_sched_params: tile_scheduler.TileSchedulerPrecomputedParams
        | None = None,
    ):
        """GPU device kernel performing the Persistent batched GEMM computation."""
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        mma_tile_coord_v = cta_rank_in_cluster % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        is_first_cta_in_cluster = cta_rank_in_cluster == 0
        # When split_k>1 the physical cluster extends along Z; fold out the Z stride
        # to get the MN-only rank for TMA partition. split_rank is this CTA's Z position.
        mn_cluster_size = cluster_shape_mn[0] * cluster_shape_mn[1]
        cta_rank_in_mn_cluster = cta_rank_in_cluster % mn_cluster_size
        (
            block_in_cluster_x,
            block_in_cluster_y,
            split_rank,
        ) = cute.arch.block_in_cluster_idx()
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_mn_cluster
        )
        full_block_in_cluster_coord_vmnk = clc_cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

            scheduler_bytes = self.tile_scheduler_template.get_smem_workspace_size()
            scheduler_buf: cute.struct.Align[
                cute.struct.MemRange[cutlass.Int8, scheduler_bytes],
                self.tile_scheduler_template.smem_alignment,
            ]

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Define TileSchedulerRuntimeParams here and create the tile scheduler
        # here. mC_mnl is the tensor this kernel stores to (for GMEM split-K,
        # the split-expanded accumulator view); the constructor de-expands its
        # L extent back to the real problem shape (see its docstring).
        tile_scheduler_runtime_params = tile_scheduler.TileSchedulerRuntimeParams(
            storage.scheduler_buf.data_ptr(),
            tile_sched_gmem_workspace_ptr,
            mC_mnl.shape,
            k_tile_cnt,
            swizzle_size,
            raster_along_m,
            self.tile_scheduler_template_params,
            precomputed_sched_params=precomputed_sched_params,
        )
        tile_sched = self.tile_scheduler_template.create(tile_scheduler_runtime_params)

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_tma_producer = (
            cute.size(cluster_layout_vmnk.shape[2])
            + cute.size(cluster_layout_vmnk.shape[1])
            - 1
        )
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        )
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            # Pipeline signaling must use the full physical cluster layout so internal
            # block_idx_in_cluster -> get_flat_coord() mappings remain valid when split_k>1.
            # The actual TMA multicast masks still use the MN-only cluster layout below.
            cta_layout_vmnk=clc_cluster_layout_vmnk,
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
            cta_layout_vmnk=clc_cluster_layout_vmnk,
            defer_sync=True,
        )

        # Initialize clc_pipeline (barrier) and states
        # Use full cluster size (including split_k) for CLC pipeline signaling
        if cutlass.const_expr(
            self.tile_scheduler_template.template_params.work_strategy == "clc"
        ):
            clc_pipeline_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread
            )
            full_cluster_size = (
                cute.size(cluster_shape_mn)
                * self.tile_scheduler_template_params.cluster_shape[2]
            )
            num_clc_consumer_threads = 32 * (
                1 + full_cluster_size * (1 + len(self.epilogue_warp_id) + 1)
            )
            clc_pipeline_consumer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread, num_clc_consumer_threads
            )
            clc_pipeline = pipeline.PipelineClcFetchAsync.create(
                barrier_storage=tile_sched.get_clc_mbar_ptr(),
                num_stages=self.num_sched_stages,
                producer_group=clc_pipeline_producer_group,
                consumer_group=clc_pipeline_consumer_group,
                tx_count=tile_sched.num_clc_response_bytes,
                cta_layout_vmnk=clc_cluster_layout_vmnk,
                defer_sync=True,
            )
        else:
            clc_pipeline = PipelineEmpty()

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
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        if cutlass.const_expr(self.tile_scheduler_template_params.is_cluster_splitk):
            cute.arch.mbarrier_init_fence()
            cute.arch.cluster_arrive_relaxed()
        else:
            pipeline_init_arrive(cluster_shape_mn=cluster_shape_mn, is_relaxed=True)

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_sched_stages
        )

        #
        # Setup smem tensor A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=a_smem_layout_staged.inner,
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=b_smem_layout_staged.inner,
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(is_a_mcast or is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                clc_cluster_layout_vmnk, full_block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                clc_cluster_layout_vmnk, full_block_in_cluster_coord_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, RestM, RestN, RestL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgC = thr_mma.partition_C(gC_mnl)
        idC = cute.make_identity_tensor(mC_mnl.shape)
        # (bM, bN, RestM, RestN, RestL)
        cC_mnl = cute.local_tile(
            idC, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCcC = thr_mma.partition_C(cC_mnl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), RestM, RestK, RestL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        if cutlass.const_expr(self.tile_scheduler_template_params.is_cluster_splitk):
            cute.arch.cluster_wait()
        else:
            pipeline_init_wait(cluster_shape_mn=cluster_shape_mn)

        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            if cutlass.const_expr(self.use_pdl):
                # Mandatory under the PDL launch attribute: the previous
                # grid's writes are only visible after this wait.
                cute.arch.griddepcontrol_wait()
            #
            # Persistent tile scheduling loop
            #
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler. Grid Z is L*split_k so divide
                # out the split_k factor to recover the batch index (no-op when split_k=1).
                k_start = work_tile.k_start
                k_end = work_tile.k_end
                k_tile_count = k_end - k_start

                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((atom_v, rest_v), RestK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), RestK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Tma load loop (K-partitioned for split-K)
                #
                for _k_tile in cutlass.range(0, k_tile_count, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    # Offset into global K tiles for this CTA's partition
                    k_tile_global = handle.count + k_start

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, k_tile_global)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, k_tile_global)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                    )

                    # Peek (try_wait) AB buffer empty for next k_tile
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_count:
                        peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Advance to next tile
                #
                work_tile, clc_consumer_state = tile_sched.fetch_next_work(
                    work_tile, clc_pipeline, clc_consumer_state
                )
            #
            # Wait A/B buffer empty
            #
            ab_producer.tail()

            if cutlass.const_expr(self.use_pdl or self.use_reduction_pdl):
                cute.arch.griddepcontrol_launch_dependents()

        #
        # Sched warp
        #
        # SIM102 intentionally not collapsed: cutlass.const_expr(...) must be the
        # sole condition of its `if` so the DSL elides the branch at compile time.
        # Folding it into an `and` traces this CLC-only body unconditionally, so
        # grid/static (no CLC pipeline) then hit the dummy PipelineEmpty.
        if cutlass.const_expr(self.tile_scheduler_template.requires_scheduler_warp):  # noqa: SIM102
            if warp_idx == self.sched_warp_id and is_first_cta_in_cluster:
                #
                # Persistent tile scheduling loop
                #
                clc_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.ProducerConsumer, self.num_sched_stages
                )

                while work_tile.is_valid_tile:
                    #
                    # Advance to next tile
                    #

                    clc_producer_state = tile_sched.advance_to_next_work(
                        work_tile, clc_pipeline, clc_producer_state
                    )

                    work_tile, clc_consumer_state = tile_sched.fetch_next_work(
                        work_tile, clc_pipeline, clc_consumer_state
                    )

                clc_pipeline.producer_tail(clc_producer_state)

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            #
            # Persistent tile scheduling loop
            #
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                k_start = work_tile.k_start
                k_end = work_tile.k_end
                k_tile_count = k_end - k_start

                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Mma mainloop (K-partitioned for split-K)
                #
                for k_tile in range(k_tile_count):
                    if is_leader_cta:
                        # Conditionally wait for AB buffer full
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        # tCtAcc += tCrA * tCrB
                        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                        tile_crd = (None, None, None, handle.index)
                        cute.gemm(
                            tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc
                        )

                        # Async arrive AB buffer empty
                        handle.release()

                        # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_count:
                            peek_ab_full_status = ab_consumer.try_wait()

                #
                # Async arrive accumulator buffer full
                #
                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                work_tile, clc_consumer_state = tile_sched.fetch_next_work(
                    work_tile, clc_pipeline, clc_consumer_state
                )
            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)

        sC = None
        if cutlass.const_expr(self.use_tma_store):
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
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
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

            # Identity for GMEM split-K (epilogue_op is applied once in the
            # reduction kernel after the split sum), epilogue_op otherwise.
            kernel1_epi_op = (
                self.tile_scheduler_template.swap_epilogue_for_identity_if_gmem_splitk(
                    epilogue_op
                )
            )

            # DSMEM split-K: pre-compute epilogue partitioning outside persistent loop
            if cutlass.const_expr(self.tile_scheduler_template.is_cluster_splitk):
                (
                    tTR_tAcc_base,
                    tTR_gC_partitioned,
                    tTR_cC_partitioned,
                    tiled_copy_t2r,
                    epilog_sync_barrier,
                    dsmem_full_phase,
                    dsmem_empty_phase,
                    num_tiles_done,
                ) = tile_sched.pre_fixup(
                    self,
                    tCgC,
                    tCcC,
                    tCtAcc_base,
                    tidx,
                    epi_tile,
                )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                k_start = work_tile.k_start
                k_end = work_tile.k_end
                k_tile_count = k_end - k_start

                cur_tile_coord = work_tile.tile_idx

                # The accumulator L slot for GMEM split-K, the tile's batch
                # index otherwise.
                cur_tile_l_idx = self.tile_scheduler_template.get_effective_l_idx(
                    work_tile
                )

                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_l_idx,
                )

                num_tiles_executed = tile_sched.get_num_tiles_executed()
                if cutlass.const_expr(self.tile_scheduler_template.is_cluster_splitk):
                    # ---- Cluster split-K epilogue with DSMEM scatter-reduce ----
                    # Non-TMA epilogue sets epi_tile == cta_tile so subtile_cnt == 1.

                    (
                        acc_consumer_state,
                        dsmem_full_phase,
                        dsmem_empty_phase,
                    ) = tile_sched.fixup_and_epilogue(
                        tTR_tAcc_base,
                        tTR_gC_partitioned,
                        tTR_cC_partitioned,
                        tiled_copy_t2r,
                        epilog_sync_barrier,
                        dsmem_full_phase,
                        dsmem_empty_phase,
                        num_tiles_done,
                        acc_consumer_state,
                        acc_pipeline,
                        mma_tile_coord_mnl,
                        kernel1_epi_op,
                        tidx,
                        split_rank,
                        block_in_cluster_x,
                        block_in_cluster_y,
                        self.acc_dtype,
                        self.c_dtype,
                        cluster_shape_mn,
                    )

                    num_tiles_done = num_tiles_done + 1

                elif cutlass.const_expr(self.use_tma_store):
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
                        kernel1_epi_op,
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
                        kernel1_epi_op,
                        mma_tile_coord_mnl,
                        acc_consumer_state,
                        acc_pipeline,
                    )
                #
                # Advance to next tile
                #
                work_tile, clc_consumer_state = tile_sched.fetch_next_work(
                    work_tile, clc_pipeline, clc_consumer_state
                )

            if cutlass.const_expr(self.use_tma_store):
                # Wait for C store complete
                c_pipeline.producer_tail()
            elif cutlass.const_expr(
                not self.tile_scheduler_template_params.is_cluster_splitk
            ):
                # Synchronize before TMEM dealloc (done by the caller)
                tmem_dealloc_barrier.arrive_and_wait()
            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

        # End-of-kernel scheduler hook (a no-op except for cluster split-K,
        # which keeps the DSMEM mailbox alive until all peers finish).
        tile_sched.finalize()

    @staticmethod
    def _compute_num_tmem_alloc_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler: tuple[int, int, int],
        num_acc_stage: int,
        arch: str,
    ) -> int:
        """Compute the number of tensor memory allocation columns.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler: The shape (M, N, K) of the MMA tile.
        :type mma_tiler: tuple[int, int, int]
        :param num_acc_stage: The stage of the accumulator tensor.
        :type num_acc_stage: int

        :return: The number of tensor memory allocation columns.
        :rtype: int
        """
        acc_shape = tiled_mma.partition_shape_C(mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(cute.append(acc_shape, num_acc_stage))
        num_tmem_alloc_cols = cutlass.memory.get_num_tmem_alloc_cols(
            tCtAcc_fake, arch=arch
        )

        return num_tmem_alloc_cols

    def check_supported_dtypes(
        self,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
    ):
        """Check if the dtypes are valid.

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param acc_dtype: The data type of the accumulator
        :type acc_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]

        :raises testing.CantImplementError: If the dtypes are invalid
        """
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Uint8,
            cutlass.Int8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if a_dtype not in valid_ab_dtypes or b_dtype not in valid_ab_dtypes:
            raise testing.CantImplementError(
                f"Unsupported AB dtype: {a_dtype} and {b_dtype}"
            )

        if self.acc_dtype not in {cutlass.Float32, cutlass.Float16, cutlass.Int32}:
            raise testing.CantImplementError(
                f"Unsupported accumulator dtype: {self.acc_dtype}"
            )

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.TFloat32,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },  # Float32 accumulator supports floating point AB types only
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
        }
        # Check compatibility between accumulator type and AB type
        if (
            a_dtype not in acc_ab_compatibility[self.acc_dtype]
            or b_dtype not in acc_ab_compatibility[self.acc_dtype]
        ):
            raise testing.CantImplementError(
                f"Unsupported AB dtype: {a_dtype} and {b_dtype} for accumulator dtype: {self.acc_dtype}"
            )

        # Define compatibility mapping between accumulator type and C type
        acc_c_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
            cutlass.Float16: {
                cutlass.BFloat16,
                cutlass.Float16,
            },
            cutlass.Int32: {
                cutlass.BFloat16,
                cutlass.Float16,
                cutlass.Float32,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
        }
        # Check compatibility between accumulator type and C type
        if c_dtype not in acc_c_compatibility[self.acc_dtype]:
            raise testing.CantImplementError(
                f"Unsupported C dtype: {c_dtype} for accumulator dtype: {self.acc_dtype}"
            )

    def check_mma_tiler_and_cluster_shape(self):
        """Check if the mma tiler and cluster shape are valid.

        :raises testing.CantImplementError: If the mma tiler and cluster shape are invalid
        """
        # Skip invalid mma tile shape
        if not (
            (not self.use_2cta_instrs and self.mma_tiler_mn[0] in [64, 128])
            or (self.use_2cta_instrs and self.mma_tiler_mn[0] in [128, 256])
        ):
            raise testing.CantImplementError(
                f"Invalid mma tiler & use_2cta_instrs: {self.mma_tiler_mn}, {self.use_2cta_instrs}"
            )
        if self.mma_tiler_mn[1] not in range(32, 257, 32):
            raise testing.CantImplementError(
                f"Invalid mma tiler N: {self.mma_tiler_mn[1]}"
            )
        # Skip illegal cluster shape
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster shape M: {self.cluster_shape_mn[0]}"
            )

        # Skip invalid cluster shape: the physically launched cluster
        # (cluster_shape[2] is split_k only for cluster split-K, else 1) must fit
        # in <= 16 hardware CTAs. Two-kernel (GMEM) split-K (cluster_shape[2] ==
        # 1) is therefore not bounded here by split_k.
        def is_power_of_2(x):
            return x > 0 and (x & (x - 1)) == 0

        total_cluster_size = (
            self.cluster_shape_mn[0]
            * self.cluster_shape_mn[1]
            * self.tile_scheduler_template_params.cluster_shape[2]
        )
        if (
            total_cluster_size > 16
            or self.cluster_shape_mn[0] <= 0
            or self.cluster_shape_mn[1] <= 0
            or not is_power_of_2(self.cluster_shape_mn[0])
            or not is_power_of_2(self.cluster_shape_mn[1])
        ):
            raise testing.CantImplementError(
                f"Invalid cluster shape: {self.cluster_shape_mn} with split_k={self.tile_scheduler_template_params.split_k}"
            )
        self.tile_scheduler_template.check_cluster_splitk_constraints(
            self.use_tma_store
        )

        cta_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        self._mailbox_elems_per_thread = (cta_m * self.mma_tiler_mn[1]) // 128
        shard_ept = self._mailbox_elems_per_thread // max(
            self.tile_scheduler_template_params.split_k, 1
        )
        self._mailbox_total_elems = (
            max(self.tile_scheduler_template_params.split_k - 1, 0) * 128 * shard_ept
        )

    def check_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        batch: int,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ):
        """Check if the tensor alignment is valid.

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param batch: The number of columns in the C tensor
        :type batch: int
        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :raises testing.CantImplementError: If the tensor alignment is invalid
        """

        # TODO: move to utils
        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k, batch))
            or not check_contiguous_16B_alignment(
                b_dtype, b_major == "n", (n, k, batch)
            )
            or not check_contiguous_16B_alignment(
                c_dtype, c_major == "m", (m, n, batch)
            )
        ):
            raise testing.CantImplementError(
                f"Invalid tensor alignment: {m}, {n}, {k}, {batch}, {a_dtype}, {b_dtype}, {c_dtype}, {a_major}, {b_major}, {c_major}"
            )

    def check_epilog_store_option(self, m: int, n: int):
        """Check if the epilogue store option is valid.

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int

        :raises testing.CantImplementError: If the epilogue store option is invalid
        """
        # Non TMA store version does not have predication, can not support OOB tiles
        cta_tile_shape_mn = (
            self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1),
            self.mma_tiler_mn[1],
        )
        if not self.use_tma_store and not (
            m % cta_tile_shape_mn[0] == 0 and n % cta_tile_shape_mn[1] == 0
        ):
            raise testing.CantImplementError(
                f"Problem shape {m}, {n} must be divisible by cta tile shape {cta_tile_shape_mn} for non TMA store"
            )

    def can_compile(
        self,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
    ) -> bool:
        """Determine if this configuration can be compiled by this kernel.

        :param a_dtype: Data type of input tensor A.
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Data type of input tensor B.
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: Data type of output tensor C.
        :type c_dtype: Type[cutlass.Numeric]
        :return: True if the configuration can be compiled.
        :rtype: bool

        :raises testing.CantImplementError: If the configuration is invalid.
        """
        self.check_supported_dtypes(a_dtype, b_dtype, c_dtype)
        self.check_mma_tiler_and_cluster_shape()
        if self.precompute_scheduler_params:
            self.tile_scheduler_template_params.check_precompute_support()
        return True

    def can_implement(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        swizzle_size: int,
        raster_along: Literal["m", "n"],
    ) -> bool:
        """Determine if the compiled kernel can execute this launch.

        :param a: Input tensor A of shape (l, m, k).
        :type a: cute.Tensor
        :param b: Input tensor B of shape (l, k, n).
        :type b: cute.Tensor
        :param c: Output tensor C of shape (l, m, n).
        :type c: cute.Tensor
        :param swizzle_size: tiles per swizzle group for this launch
        :type swizzle_size: int
        :param raster_along: rasterization order for this launch, already
            resolved to a concrete axis by
            ``TileSchedulerTemplate.resolve_rasterization``.
        :type raster_along: Literal["m", "n"]
        :return: True if this launch can be executed.
        :rtype: bool

        :raises testing.CantImplementError: If the launch is invalid.
        """
        batch, m, k = a.shape
        n = b.shape[2]
        a_major = "k" if a.stride[2] == 1 else "m"
        b_major = "k" if b.stride[1] == 1 else "n"
        c_major = "n" if c.stride[2] == 1 else "m"
        self.check_tensor_alignment(
            m,
            n,
            k,
            batch,
            a.element_type,
            b.element_type,
            c.element_type,
            a_major,
            b_major,
            c_major,
        )
        self.check_epilog_store_option(m, n)
        if not self.use_tma_store and self.tile_scheduler_template.visits_oob_tiles(
            (m, n, 0, 1), swizzle_size, raster_along
        ):
            raise testing.CantImplementError(
                f"problem shape {m}, {n} with swizzle_size {swizzle_size} leaves "
                "partially-filled clusters or swizzle groups, which a non-TMA "
                "store cannot predicate away"
            )
        if not self.tile_scheduler_template.can_implement(
            (m, n, k, batch), swizzle_size, raster_along
        ):
            raise testing.CantImplementError(
                "Tile scheduler cannot implement this configuration for problem "
                f"{(m, n, k, batch)} with swizzle_size={swizzle_size}, "
                f"raster_along={raster_along!r}"
            )
        return True


@cute.jit
def bmm(
    gemm_op: cutlass.Constexpr,
    a: cute.Tensor,  # (l, m, k)
    b: cute.Tensor,  # (l, k, n)
    c: cute.Tensor,  # (l, m, n)
    stream: cuda.CUstream,
    workspace: cute.Pointer,
    swizzle_size: Int32,
    raster_along_m: Boolean,
    max_active_clusters_fallback: Int32,
    epilogue_op: cutlass.Constexpr = lambda x: x,
):
    """Wrapper API for persistent GEMM kernel to follow the convention of PyTorch's batch matrix-multiply (bmm).

    Internally, the tensors are permuted to match CuTe's convention:
      - a: (m, k, l)
      - b: (n, k, l)
      - c: (m, n, l)

    :param gemm_op: Kernel operation, expects (a, b, c, stream, workspace,
        swizzle_size, raster_along_m, max_active_clusters_fallback, epilogue_op)
    :type gemm_op: cutlass.Constexpr
    :param a: Input tensor of shape (l, m, k), or (m, k) when unbatched
    :type a: cute.Tensor
    :param b: Input tensor of shape (l, k, n), or (k, n) when unbatched
    :type b: cute.Tensor
    :param c: Output tensor of shape (l, m, n), or (m, n) when unbatched
    :type c: cute.Tensor
    :param max_active_clusters_fallback: Occupancy cap on concurrently resident
        fallback clusters (launch-time value; see ``query_max_active_clusters``).
        Only the ``static`` work strategy uses it (its grid is one wave).
    :type max_active_clusters_fallback: Int32
    :param epilogue_op: Optional elementwise lambda function to apply per output element, defaults to identity
    :type epilogue_op: cutlass.Constexpr, optional
    """
    # Prepend a unbatched operand to match the 3-mode convention
    a = cute.prepend_ones(a, up_to_rank=3)
    b = cute.prepend_ones(b, up_to_rank=3)
    c = cute.prepend_ones(c, up_to_rank=3)

    # (l,m,k) -> (m,k,l)
    a = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[1, 2, 0]))
    # (l,k,n) -> (n,k,l)
    b = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[2, 1, 0]))
    # (l,m,n) -> (m,n,l)
    c = cute.make_tensor(c.iterator, cute.select(c.layout, mode=[1, 2, 0]))

    gemm_op(
        a,
        b,
        c,
        stream,
        workspace,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        epilogue_op,
    )


def prepare_tensors(
    mnkl: tuple[int, int, int, int],
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    init_random: bool = True,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
):
    """Prepare tensors for GEMM.

    Returns:
        tuple of (a_f32, b_f32, c_f32, a_storage, b_storage, c_storage):
        - *_f32: Float32 tensors with the logical data (for reference and fp8 conversion)
        - *_storage: Storage tensors for DLPack (uint8 for fp8, otherwise the target dtype)
    """
    import torch

    from cutlass.torch import dtype as torch_dtype

    m, n, k, batch = mnkl

    if a_major == "k":
        a_f32 = torch.empty((batch, m, k), dtype=torch.float32, device="cuda")
    elif a_major == "m":
        a_f32 = torch.empty((batch, k, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if b_major == "n":
        b_f32 = torch.empty((batch, k, n), dtype=torch.float32, device="cuda")
    elif b_major == "k":
        b_f32 = torch.empty((batch, n, k), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if c_major == "n":
        c_f32 = torch.empty((batch, m, n), dtype=torch.float32, device="cuda")
    elif c_major == "m":
        c_f32 = torch.empty((batch, n, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    # Initialize tensors with either uniform random or normal distribution
    for tensor in [a_f32, b_f32, c_f32]:
        if init_random:
            tensor.random_(-2, 3)
        else:
            tensor.normal_(mean=normal_mean, std=normal_std)

    # For float8 types, use uint8 as storage type to avoid dlpack limitation
    # (dlpack doesn't support float8 types)
    # For other types, convert to the target dtype
    a_storage_dtype = torch.uint8 if is_fp8_dtype(a_dtype) else torch_dtype(a_dtype)
    b_storage_dtype = torch.uint8 if is_fp8_dtype(b_dtype) else torch_dtype(b_dtype)
    c_storage_dtype = torch.uint8 if is_fp8_dtype(c_dtype) else torch_dtype(c_dtype)

    a_storage = a_f32.to(dtype=a_storage_dtype)
    b_storage = b_f32.to(dtype=b_storage_dtype)
    c_storage = c_f32.to(dtype=c_storage_dtype)

    return (a_f32, b_f32, c_f32, a_storage, b_storage, c_storage)


@lru_cache(maxsize=1)
def compile_bmm(
    mnkl: tuple[int, int, int, int],
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    acc_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: tuple[int, int] | tuple[int, int, int] = (256, 256),
    cluster_shape_mn: tuple[int, int] = (2, 1),
    fallback_cluster_shape_mn: tuple[int, int] = (2, 1),
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    split_k: int = 1,
    reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
    work_strategy: Literal["grid", "static", "clc"] = "clc",
    rasterization_strategy: Literal["none", "affine"] = "none",
    use_pdl: bool = False,
    use_reduction_pdl: bool = False,
    precompute_scheduler_params: bool = False,
):
    """Compile a persistent batched dense GEMM kernel for the given problem and configuration.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: tuple[int, int, int, int]
    :param a: Input tensor A.
    :type a: cute.Tensor
    :param b: Input tensor B.
    :type b: cute.Tensor
    :param c: Output tensor C.
    :type c: cute.Tensor
    :param acc_dtype: Accumulator data type for the matrix multiplication.
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Memory layout of tensor A.
    :type a_major: str
    :param b_major: Memory layout of tensor B.
    :type b_major: str
    :param c_major: Memory layout of tensor C.
    :type c_major: str
    :param mma_tiler: MMA tiling size (M, N) or (M, N, K), defaults to (256, 256).
    :type mma_tiler: Union[tuple[int, int], tuple[int, int, int]]
    :param cluster_shape_mn: Cluster shape (M, N), defaults to (2, 1).
    :type cluster_shape_mn: tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N), defaults to (2, 1).
    :type fallback_cluster_shape_mn: tuple[int, int]
    :param use_2cta_instrs: Whether to use 2CTA MMA instructions, defaults to True.
    :type use_2cta_instrs: bool
    :param use_tma_store: Whether to use TMA store, defaults to True.
    :type use_tma_store: bool
    :param epilogue_op: Elementwise epilogue applied to the output.
    :type epilogue_op: cutlass.Constexpr
    :param split_k: Split-K factor (K-partitions per output tile), defaults to 1.
    :type split_k: int
    :param reduction_strategy: Reduction strategy: "cluster-splitk" selects cluster
        (in-kernel DSMEM) split-K; "gmem-splitk" selects the two-kernel (GMEM)
        variant with equal-sized K ranges; "none" means no split-K. Defaults
        to "none".
    :type reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"]
    :param work_strategy: Tile scheduler kind: "grid", "static", or "clc", defaults to "clc".
    :type work_strategy: Literal["grid", "static", "clc"]
    :param rasterization_strategy: Rasterization strategy: "none"
        (identity; no swizzle/raster reorder) or "affine" (decodes the
        cluster-linear index). Defaults to "none".
    :type rasterization_strategy: Literal["none", "affine"]
    :param use_pdl: Whether to use inter-operator PDL (GEMM launched with the
        PDL attribute + wait; last kernel signals dependents), defaults to False.
    :type use_pdl: bool
    :param use_reduction_pdl: Whether to use intra-operator PDL between the
        GEMM and reduction kernel, defaults to False.
    :type use_reduction_pdl: bool
    :param precompute_scheduler_params: Prepare scheduler state on the host;
        requires static/affine/no-reduction scheduling. Defaults to False.
    :type precompute_scheduler_params: bool
    :return: A tuple of (compiled GEMM kernel callable, GMEM scheduler workspace
        pointer, backing tensor that keeps the workspace allocation alive, the
        kernel object for per-launch setting resolution/validation). The callable
        takes ``swizzle_size`` / ``raster_along_m`` / ``max_active_clusters_fallback``
        as launch arguments, so one artifact serves every value of them.
    :rtype: tuple[Callable, cute.Pointer, Optional[torch.Tensor], PersistentDenseGemmKernel]
    """
    import torch

    from cutlass.cute.runtime import make_fake_stream

    gemm = PersistentDenseGemmKernel(
        acc_dtype=acc_dtype,
        use_2cta_instrs=use_2cta_instrs,
        mma_tiler_mn=mma_tiler,
        cluster_shape_mn=cluster_shape_mn,
        use_tma_store=use_tma_store,
        split_k=split_k,
        work_strategy=work_strategy,
        rasterization_strategy=rasterization_strategy,
        reduction_strategy=reduction_strategy,
        use_pdl=use_pdl,
        use_reduction_pdl=use_reduction_pdl,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        precompute_scheduler_params=precompute_scheduler_params,
    )

    gemm.can_compile(a.element_type, b.element_type, c.element_type)

    problem_shape_mnl = [mnkl[0], mnkl[1], mnkl[3]]
    gmem_workspace_bytes = gemm.get_gmem_workspace_size(problem_shape_mnl)
    _workspace_tensor = None
    if gmem_workspace_bytes == 0:
        workspace = cute.runtime.nullptr(cutlass.Int8)
    else:
        _workspace_tensor = torch.empty(
            gmem_workspace_bytes, dtype=torch.int8, device="cuda"
        )
        gemm.initialize_workspace(_workspace_tensor, problem_shape_mnl)
        workspace = cute.runtime.from_dlpack(_workspace_tensor).iterator

    stream = make_fake_stream()
    compiled_fn = cute.compile(
        bmm,
        gemm,
        a,
        b,
        c,
        stream,
        workspace,
        Int32(1),  # placeholder for swizzle_size
        Boolean(True),  # placeholder for raster_along_m
        Int32(1),  # placeholder for max_active_clusters_fallback
        epilogue_op,
    )
    return compiled_fn, workspace, _workspace_tensor, gemm


def run(
    mnkl: tuple[int, int, int, int],
    ab_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: tuple[int, int] = (256, 256),
    cluster_shape_mn: tuple[int, int] = (2, 1),
    fallback_cluster_shape_mn: tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n", "heuristic"] = "heuristic",
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    ref_check_device: str = "cuda",
    use_cold_l2: bool = False,
    benchmark: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    split_k: int = 1,
    reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
    work_strategy: Literal["grid", "static", "clc"] = "clc",
    rasterization_strategy: Literal["none", "affine"] = "none",
    use_pdl: bool = False,
    use_reduction_pdl: bool = False,
    precompute_scheduler_params: bool = False,
    **kwargs,
):
    """Execute a persistent batched dense GEMM operation on Blackwell architecture with performance benchmarking.

    Prepares input tensors, configures and launches the persistent GEMM kernel,
    optionally performs reference validation, and benchmarks execution.

    :param mnkl: Problem size as a tuple (M, N, K, L).
    :type mnkl: tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B.
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C.
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Accumulator data type for the matrix multiplication.
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major: Memory layout of tensor A.
    :type a_major: str
    :param b_major: Memory layout of tensor B.
    :type b_major: str
    :param c_major: Memory layout of tensor C.
    :type c_major: str
    :param mma_tiler_mn: MMA tiling size (M, N), defaults to (256, 256).
    :type mma_tiler_mn: tuple[int, int], optional
    :param cluster_shape_mn: Cluster shape (M, N), defaults to (2, 1).
    :type cluster_shape_mn: tuple[int, int], optional
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N), defaults to (2, 1).
    :type fallback_cluster_shape_mn: tuple[int, int], optional
    :param use_2cta_instrs: Whether to use 2CTA MMA instructions, defaults to True.
    :type use_2cta_instrs: bool, optional
    :param use_tma_store: Whether to use TMA store, defaults to True.
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance for reference validation, defaults to 1e-01.
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations before benchmarking, defaults to 0.
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations to run, defaults to 1.
    :type iterations: int, optional
    :param ref_check_device: Device the reference check runs on, one of "cuda", "cpu" or "skipped", defaults to "cuda".
    :type ref_check_device: str, optional
    :param use_cold_l2: Whether to use circular buffer strategy to ensure cold L2 cache, defaults to False.
    :type use_cold_l2: bool, optional
    :param benchmark: Whether to only benchmark the kernel, defaults to False.
    :type benchmark: bool, optional
    :param init_normal: Whether to initialize tensors using normal distribution
        instead of uniform random, defaults to False.
    :type init_normal: bool, optional
    :param normal_mean: Mean for normal distribution initialization, defaults to 0.0.
    :type normal_mean: float, optional
    :param normal_std: Standard deviation for normal distribution initialization,
        defaults to 1.0.
    :type normal_std: float, optional
    :param swizzle_size: Tile scheduler swizzle size, defaults to 1.
    :type swizzle_size: int, optional
    :param raster_along: Tile scheduler rasterization order; "m", "n", or
        "heuristic" (resolved per problem by the rasterization strategy),
        defaults to "heuristic".
    :type raster_along: Literal["m", "n", "heuristic"], optional
    :param split_k: Split-K factor (K-partitions per output tile), defaults to 1.
    :type split_k: int, optional
    :param reduction_strategy: Reduction strategy: "cluster-splitk" selects cluster
        (in-kernel DSMEM) split-K; "gmem-splitk" selects the two-kernel (GMEM)
        variant with equal-sized K ranges; "none" means no split-K. Defaults
        to "none".
    :type reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"], optional
    :param work_strategy: Tile scheduler kind: "grid", "static", or "clc", defaults to "clc".
    :type work_strategy: Literal["grid", "static", "clc"]
    :param rasterization_strategy: Rasterization strategy: "none"
        (identity; no swizzle/raster reorder) or "affine" (decodes the
        cluster-linear index). Defaults to "none".
    :type rasterization_strategy: Literal["none", "affine"], optional
    :param use_pdl: Whether to use inter-operator PDL (GEMM launched with the
        PDL attribute + wait; last kernel signals dependents), defaults to False.
    :type use_pdl: bool, optional
    :param use_reduction_pdl: Whether to use intra-operator PDL between the
        GEMM and reduction kernel, defaults to False.
    :type use_reduction_pdl: bool, optional
    :param precompute_scheduler_params: Prepare scheduler state on the host;
        requires static/affine/no-reduction scheduling. Defaults to False.
    :type precompute_scheduler_params: bool
    :raises RuntimeError: If CUDA GPU is not available.
    :raises ValueError: If the configuration is invalid or unsupported by the kernel.
    :return: Execution time of the GEMM kernel.
    :rtype: float
    """
    import torch
    from cutlass.torch import dtype as torch_dtype

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Run and verify BMM with torch
    a_f32, b_f32, c_f32, a_storage, b_storage, c_storage = prepare_tensors(
        mnkl,
        ab_dtype,
        ab_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        init_random=not init_normal,
        normal_mean=normal_mean,
        normal_std=normal_std,
    )

    leading_dim_a = 2 if a_major == "k" else 1
    leading_dim_b = 1 if b_major == "k" else 2
    leading_dim_c = 2 if c_major == "n" else 1

    # Create CuTe tensors, passing float32 source for fp8 conversion
    a_ = create_cute_tensor_for_fp8(
        a_storage, ab_dtype, leading_dim_a, source_f32_tensor=a_f32
    )
    b_ = create_cute_tensor_for_fp8(
        b_storage, ab_dtype, leading_dim_b, source_f32_tensor=b_f32
    )
    c_ = create_cute_tensor_for_fp8(
        c_storage, c_dtype, leading_dim_c, source_f32_tensor=c_f32
    )

    max_active_clusters = tile_scheduler.query_max_active_clusters(
        fallback_cluster_shape_mn, split_k, reduction_strategy
    )

    print("Compile Blackwell Persistent Dense GEMM with:")
    print(f"ab_dtype: {ab_dtype}, c_dtype: {c_dtype}, acc_dtype: {acc_dtype}")
    print(f"a_major: {a_major}, b_major: {b_major}, c_major: {c_major}")
    print(f"mma_tiler_mn: {mma_tiler_mn}, cluster_shape_mn: {cluster_shape_mn}")
    print(f"use_2cta_instrs: {use_2cta_instrs}, use_tma_store: {use_tma_store}")
    print(f"swizzle_size: {swizzle_size}, raster_along: {raster_along}")
    print(f"split_k: {split_k}")

    compiled_fn, workspace_, _ws_tensor, gemm = compile_bmm(
        mnkl,
        a_,
        b_,
        c_,
        acc_dtype,
        a_major,
        b_major,
        c_major,
        mma_tiler_mn,
        cluster_shape_mn,
        fallback_cluster_shape_mn,
        use_2cta_instrs,
        use_tma_store,
        epilogue_op=lambda x: x,
        split_k=split_k,
        reduction_strategy=reduction_strategy,
        work_strategy=work_strategy,
        rasterization_strategy=rasterization_strategy,
        use_pdl=use_pdl,
        use_reduction_pdl=use_reduction_pdl,
        precompute_scheduler_params=precompute_scheduler_params,
    )

    raster_along, swizzle_size = gemm.tile_scheduler_template.resolve_rasterization(
        raster_along,
        swizzle_size,
        mnkl,
        a_element_bytes=ab_dtype.width // 8,
        b_element_bytes=ab_dtype.width // 8,
    )
    gemm.can_implement(a_, b_, c_, swizzle_size, raster_along)

    print("Running Blackwell Persistent Dense GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Reference check device: {ref_check_device}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    if ref_check_device != "skipped":
        # Use small random number for deterministic result for reference check
        compiled_fn(
            a_,
            b_,
            c_,
            current_stream,
            workspace_,
            Int32(swizzle_size),
            Boolean(raster_along == "m"),
            Int32(max_active_clusters),
        )
        torch.cuda.synchronize()

        # Manually quantize to be comparable
        # Use float32 source data for reference calculation, on whichever
        # device the caller asked for.
        device = ref_check_device
        ref = (
            torch.bmm(a_f32.to(device), b_f32.to(device))
            .to(dtype=torch_dtype(c_dtype))
            .to(dtype=torch.float32)
        )
        torch.cuda.synchronize()
        torch.testing.assert_close(
            c_storage.view(torch_dtype(c_dtype)).to(dtype=torch.float32).to(device),
            ref,
            atol=tolerance,
            rtol=1e-03,
        )

    if not benchmark:
        return 0

    def generate_tensors():
        # Use init_normal from outer scope, but force random init for Int8/Uint8 types
        use_normal_init = init_normal and (
            ab_dtype not in [cutlass.Int8, cutlass.Uint8]
        )
        a_f32, b_f32, c_f32, a_st, b_st, c_st = prepare_tensors(
            mnkl,
            ab_dtype,
            ab_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
            init_random=not use_normal_init,
            normal_mean=normal_mean,
            normal_std=normal_std,
        )
        a_ = create_cute_tensor_for_fp8(
            a_st, ab_dtype, leading_dim_a, source_f32_tensor=a_f32
        )
        b_ = create_cute_tensor_for_fp8(
            b_st, ab_dtype, leading_dim_b, source_f32_tensor=b_f32
        )
        c_ = create_cute_tensor_for_fp8(
            c_st, c_dtype, leading_dim_c, source_f32_tensor=c_f32
        )
        return testing.JitArguments(
            a_,
            b_,
            c_,
            current_stream,
            workspace_,
            Int32(swizzle_size),
            Boolean(raster_along == "m"),
            Int32(max_active_clusters),
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_storage.numel() * a_storage.element_size()
            + b_storage.numel() * b_storage.element_size()
            + c_storage.numel() * c_storage.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    # Return execution time in microseconds
    exec_time = testing.benchmark(
        compiled_fn,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )
    print(f"[DSL INFO] Execution time: {exec_time} microseconds per iteration")
    return exec_time



def _parse_comma_separated_ints(s: str) -> tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        ) from None


def prepare_parser():
    """Build the argument parser for the dense persistent GEMM example.

    :return: An argument parser populated with the common GEMM and benchmarking options.
    :rtype: argparse.ArgumentParser
    """
    parser = argparse.ArgumentParser(
        description="Example of Dense Persistent GEMM on Blackwell."
    )

    parser.add_argument(
        "--mnkl",
        type=_parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.TFloat32)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=[
            "default",
            "none",
        ],
        help="Benchmark the kernel with nsight or default (cutlass.testing.benchmark) or none",
    )
    parser.add_argument(
        "--ref_check_device",
        type=str,
        default="cuda",
        choices=["cuda", "cpu", "skipped"],
        help="Device for the reference check, or 'skipped' to omit it",
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
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    testing.add_tensor_init_args(parser, supports_int_dtypes=True)

    return parser


if __name__ == "__main__":
    parser = prepare_parser()

    # Kernel Configurations
    parser.add_argument(
        "--use_tma_store", action="store_true", help="Use tma store or not"
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(2, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=_parse_comma_separated_ints,
        default=(2, 1),
        help="Fallback cluster shape (comma-separated)",
    )

    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )

    parser.add_argument(
        "--mma_tiler_mn",
        type=_parse_comma_separated_ints,
        default=(128, 128),
        help="Mma tile shape (comma-separated)",
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
        choices=list(tile_scheduler.RASTERIZATION_ORDER_OPTIONS),
        default="heuristic",
        help="Rasterization order of clusters; 'heuristic' picks the order "
        "that makes the shorter tile axis the fast-varying one",
    )
    parser.add_argument(
        "--split_k",
        type=int,
        default=1,
        help="Split-K factor (K-partitions per output tile); reduced in-kernel "
        "via DSMEM when --reduction_strategy=cluster-splitk, else via a second GMEM "
        "reduction kernel",
    )
    parser.add_argument(
        "--reduction_strategy",
        type=str,
        choices=["none", "gmem-splitk", "cluster-splitk"],
        default="none",
        help="Tile scheduler reduction strategy: 'cluster-splitk' reduces "
        "in-kernel within the cluster (DSMEM); 'gmem-splitk' writes partials to "
        "a GMEM workspace and reduces them in a second kernel (equal-sized K "
        "ranges); 'none' means no split-K. Must be 'none' exactly when "
        "--split_k is 1",
    )
    parser.add_argument(
        "--work_strategy",
        type=str,
        choices=["grid", "static", "clc"],
        default="grid",
        help="Tile scheduler work strategy: 'grid' (one tile per CTA), 'static' "
        "(fixed persistent grid), or 'clc' (CLC dynamic persistent)",
    )
    parser.add_argument(
        "--rasterization_strategy",
        type=str,
        choices=["none", "affine"],
        default="none",
        help="Tile scheduler rasterization strategy: 'none' is the identity "
        "rasterizer (applies no swizzle and no raster reorder, and requires a "
        "'grid'/'clc' work strategy); 'affine' decodes the cluster-linear index, "
        "honoring --swizzle_size and --raster_order",
    )
    parser.add_argument(
        "--use_pdl",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Whether to use inter-operator PDL (overlap with the previous "
        "and next kernels in the stream)",
    )
    parser.add_argument(
        "--use_reduction_pdl",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Whether to use intra-operator PDL between the GEMM and reduction kernel",
    )

    parser.add_argument(
        "--precompute_scheduler_params",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Prepare scheduler state on the host (static/affine/no-reduction only)",
    )

    args = parser.parse_args()

    testing.validate_tensor_init_args(args, parser)

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    if len(args.fallback_cluster_shape_mn) != 2:
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    print("[DSL INFO] Compiling Blackwell Persistent Dense GEMM with:")
    print(
        f"[DSL INFO] A dtype: {args.ab_dtype}, B dtype: {args.ab_dtype}, C dtype: {args.c_dtype}, Acc dtype: {args.acc_dtype}"
    )
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Mma Tiler (M, N): {args.mma_tiler_mn}")
    print(f"[DSL INFO] Cluster Shape (M, N): {args.cluster_shape_mn}")
    print(f"[DSL INFO] Fallback Cluster Shape (M, N): {args.fallback_cluster_shape_mn}")
    print(
        f"[DSL INFO] 2CTA MMA instructions: {'True' if args.use_2cta_instrs else 'False'}"
    )
    print(f"[DSL INFO] Use TMA Store: {'True' if args.use_tma_store else 'False'}")
    print(f"[DSL INFO] Split-K: {args.split_k}")
    print(f"[DSL INFO] Reduction strategy: {args.reduction_strategy}")
    print(f"[DSL INFO] Use PDL: {args.use_pdl}")
    print(f"[DSL INFO] Use reduction PDL: {args.use_reduction_pdl}")

    run(
        args.mnkl,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.ref_check_device,
        args.use_cold_l2,
        args.benchmark == "default",
        args.init_normal,
        args.normal_mean,
        args.normal_std,
        args.split_k,
        reduction_strategy=args.reduction_strategy,
        work_strategy=args.work_strategy,
        rasterization_strategy=args.rasterization_strategy,
        use_pdl=args.use_pdl,
        use_reduction_pdl=args.use_reduction_pdl,
        precompute_scheduler_params=args.precompute_scheduler_params,
    )
    print("PASS")
