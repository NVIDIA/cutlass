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
from math import log2, ceil
from typing import Optional, Union

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl import (
    extract_mlir_values,
    new_from_mlir_values,
)
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.mixed_input_helpers as mixed_input_utils
from cutlass.utils.mixed_input_helpers import TransformMode
import cutlass.cute.testing as testing
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.runtime import from_dlpack

"""
A mixed-input grouped GEMM example for the NVIDIA Blackwell SM100 architecture using CUTE DSL.

This example demonstrates an implementation of mixed-input grouped GEMM using a TMA plus Blackwell
SM100 TensorCore warp-specialized persistent kernel. It could be viewed as an extension of the batched
mixed-input GEMM example to support a specific grouped GEMM pattern, grouped gemm with contiguous offsets.

Specifically, the input A tensor is still in the shape of (M, K, L), and L is the number of groups. The
input B tensor is in the shape of (N, K) and the result C tensor is in the shape of (M, N). Tensor B
and tensor C are not divided into groups explititly and there is an extra input tensor cumsum defining
the mapping between the N mode to groups. The cumsum tensor is in the shape of (N+1) and cumsum[i]
defines the accumulated size along N mode for groups up to i(not including i):

   ```
           Group 0  Group 1  Group 2 .....    Group L-1
        -+--------+--------+--------+.....+----------------+
         |        |        |        |                         |
         |<- N0 ->|<- N1 ->|<- N2 ->|.....|<--    NL-1     -->|
         |        |        |        |                         |
        -+--------+--------+--------+.....+-------------------+
cumsum:  |   0    |   N0   | N0+N1  |.....| sum(N0,N1,...NL-2) | sum(N0,N1,...NL-1)
   ```

The computation flow is same as the batched mixed-input GEMM example. A is the narrow-precision tensor
and B holds data with a wider precision. MMA will work in the wide precision of tensor B and tensor A
will be transformed to the wide precision of tensor B following 1 of the 2 possible modes as follows:

1. convert-only mode:
    C = type_convert(A) x B

In convert-only mode, tensor A is directly converted to the wide precision of tensor B.

2. convert-scale mode:
    C = (type_convert(A) * scale) x B

In convert-scale mode, tensor A is first converted to the wide precision of tensor B and then scaled by the scale tensor.
The scale tensor is in the same precision as tensor B.
The mode is determined by tensor A's data type as follows:
- if tensor A is in int8 or uint8, convert-only mode is used.
- if tensor A is in int4, convert-scale mode is used.

The output tensor C could have the same precision as tensor B or fp32.

To run this example:

.. code-block:: bash

    python examples/blackwell/grouped_mixed_input_gemm.py      \
      --a_dtype Int8 --b_dtype BFloat16                        \
      --scale_granularity_m 0 --scale_granularity_k 0          \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 128,128,64 --cluster_shape_mn 1,1        \
      --mnkl 256,512,8192,1

Input A and B have int8 and bf16 data types, respectively. The Blackwell tcgen05 MMA tile shape
is specified as (128,128,64) and the cluster shape is (1,1). The MMA accumulator and output data type
are set as fp32 and bf16, respectively. As tensor A is int8, convert-only mode is used.
scale_granularity_m and scale_granularity_k are set as 0 for convert-only mode.

Here is an example of running convert-scale mode:

.. code-block:: bash

    python examples/blackwell/grouped_mixed_input_gemm.py      \
      --a_dtype Int4 --b_dtype BFloat16                        \
      --scale_granularity_m 1 --scale_granularity_k 256        \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 256,128,128 --cluster_shape_mn 2,1       \
      --use_2cta_instrs --mnkl 1024,8192,6144,16               \

Input A and B have int4 and bf16 data types, respectively. The scale granularity is set as (1,256),
which means each element along the m mode of tensor A has its own scale element and 256 contiguous elements
along the k mode share the same scale element. There is no scale reuse along the L mode. If the GEMM shape is
(M, N, K, L), then the scale tensor shape is (M // scale_granularity_m, K // scale_granularity_k, L),
which is (1024, 6144/256, 16) in this example.
The Blackwell tcgen05 MMA tile shape is specified as (256,128,128) and tcgen05 2CTA feature is enabled.
The cluster shape is (2,1). The MMA accumulator and output data type are set as fp32 and bf16, respectively.
As tensor A is int4, the convert-scale mode is used.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/blackwell/grouped_grouped_mixed_input  \
      --a_dtype Int8 --b_dtype BFloat16                        \
      --scale_granularity_m 0 --scale_granularity_k 0          \
      --c_dtype BFloat16 --acc_dtype Float32                   \
      --mma_tiler_mnk 128,128,64 --cluster_shape_mn 1,1        \
      --mnkl 256,512,8192,1                                    \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Besides the requirements from the batched mixed-input GEMM example, there are some constraints for this example:
* --use_tma_store option is removed as no alignment assumption is made for each group.
"""


class ContiguousGGSearchState:
    """
    The state of group search for grouped gemm with contiguous offsets.

    The state records the progress of group seach algorithm on 1 mode. It will be
    initialized once and updated in every round of group index search.

    :param last_tile_count: Number of cluster tiles before the current group
    :type last_tile_count: cutlass.Int32
    :param cur_boundary: The boundary of the current group, which is the size along the seach
                         mode before the next group
    :type cur_boundary: cutlass.Int32
    :param cur_tile_count: Number of cluster tiles searched so far
    :type cur_tile_count: cutlass.Int32
    :param cur_group_idx: The index of the current group
    :type cur_group_idx: cutlass.Int32
    :param cur_offset: The starting offset of the current group along the search mode
    :type cur_offset: cutlass.Int32
    :param cur_start: The starting offset of the current cluster tile size along the search mode
                      when group search is done
    :type cur_start: cutlass.Int32
    """

    def __init__(
        self,
        last_tile_count: cutlass.Int32,
        cur_boundary: cutlass.Int32,
        cur_tile_count: cutlass.Int32,
        cur_group_idx: cutlass.Int32,
        cur_offset: cutlass.Int32,
        cur_start: cutlass.Int32,
    ):
        self.last_tile_count = last_tile_count
        self.cur_boundary = cur_boundary
        self.cur_tile_count = cur_tile_count
        self.cur_group_idx = cur_group_idx
        self.cur_offset = cur_offset
        self.cur_start = cur_start

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self.last_tile_count)
        values.extend(extract_mlir_values(self.cur_boundary))
        values.extend(extract_mlir_values(self.cur_tile_count))
        values.extend(extract_mlir_values(self.cur_group_idx))
        values.extend(extract_mlir_values(self.cur_offset))
        values.extend(extract_mlir_values(self.cur_start))
        return values

    def __new_from_mlir_values__(self, values) -> "ContiguousGGSearchState":
        last_tile_count = new_from_mlir_values(self.last_tile_count, [values[0]])
        cur_boundary = new_from_mlir_values(self.cur_boundary, [values[1]])
        cur_tile_count = new_from_mlir_values(self.cur_tile_count, [values[2]])
        cur_group_idx = new_from_mlir_values(self.cur_group_idx, [values[3]])
        cur_offset = new_from_mlir_values(self.cur_offset, [values[4]])
        cur_start = new_from_mlir_values(self.cur_start, [values[5]])
        return ContiguousGGSearchState(
            last_tile_count,
            cur_boundary,
            cur_tile_count,
            cur_group_idx,
            cur_offset,
            cur_start,
        )


def create_initial_search_state() -> ContiguousGGSearchState:
    """
    Create an initial search state for grouped gemm with contiguous offsets.
    """
    return ContiguousGGSearchState(
        last_tile_count=cutlass.Int32(0),
        cur_boundary=cutlass.Int32(0),
        cur_tile_count=cutlass.Int32(0),
        cur_group_idx=cutlass.Int32(0),
        cur_offset=cutlass.Int32(0),
        cur_start=cutlass.Int32(0),
    )


class GroupedWorkTileInfo:
    """
    Tile info for grouped gemm with contiguous offsets.
    It's consutrcted from the search state and contains informtion needed for different warps.

    :param group_count: The total number of groups
    :type group_count: int
    :param cta_coord_m: The coordinate of the current CTA tile along the M mode
    :type cta_coord_m: cutlass.Int32
    :param coord_n: The starting offset on N mode for the current CTA tile
    :type coord_n: cutlass.Int32
    :param group_idx: The index of the current group
    :type group_idx: cutlass.Int32
    :param distance_to_boundary: The distance to the boundary of the current group
    :type distance_to_boundary: cutlass.Int32
    """

    def __init__(
        self,
        group_count: int,
        cta_coord_m: cutlass.Int32,
        coord_n: cutlass.Int32,
        group_idx: cutlass.Int32,
        distance_to_boundary: cutlass.Int32,
    ):
        self.cta_coord_m = cta_coord_m
        self.coord_n = coord_n
        self.group_idx = group_idx
        self.distance_to_boundary = distance_to_boundary
        self.group_count = group_count

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self.cta_coord_m)
        values.extend(extract_mlir_values(self.coord_n))
        values.extend(extract_mlir_values(self.group_idx))
        values.extend(extract_mlir_values(self.distance_to_boundary))
        return values

    def __new_from_mlir_values__(self, values):
        assert len(values) == 4
        new_cta_coord_m = new_from_mlir_values(self.cta_coord_m, [values[0]])
        new_coord_n = new_from_mlir_values(self.coord_n, [values[1]])
        new_group_idx = new_from_mlir_values(self.group_idx, [values[2]])
        new_distance_to_boundary = new_from_mlir_values(
            self.distance_to_boundary, [values[3]]
        )
        return GroupedWorkTileInfo(
            self.group_count,
            new_cta_coord_m,
            new_coord_n,
            new_group_idx,
            new_distance_to_boundary,
        )

    @property
    def is_valid_tile(self):
        return self.group_idx < self.group_count


class GroupedMixedInputGemmKernel:
    """
    Mixed-input grouped GEMM kernel for NVIDIA Blackwell SM100 architecture.

    This kernel supports GEMM operations where input tensors A and B have different
    data types, with tensor A being transformed to the precision of tensor B before
    matrix multiplication.
    Tensor A is in shape of [M, K, L] with L being the number of groups. Tensor B is in shape of [N, K] and group seach algorithm
    is applied on the N mode to find the group index for each CTA tile. A cumsum input tensor provides the offset of each group along the N mode.

    :param scale_granularity_m: Number of elements sharing the same scale factor along the M mode
    :type scale_granularity_m: int
    :param scale_granularity_k: Number of elements sharing the same scale factor along the K mode
    :type scale_granularity_k: int
    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mnk: Shape of the Matrix Multiply-Accumulate (MMA) tile (M, N, K)
    :type mma_tiler_mnk: tuple[int, int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: tuple[int, int]
    :param group_count: The total number of groups
    :type group_count: int
    """

    def __init__(
        self,
        scale_granularity_m: int,
        scale_granularity_k: int,
        acc_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        group_count: int,
    ):
        """
        Initializes the mixed-input GEMM kernel with a specified configuration.
        """
        # Scale granularity defines how many elements share the same scale factor
        # along the M and K modes.
        self.scale_granularity_m = scale_granularity_m
        self.scale_granularity_k = scale_granularity_k
        # Set transform mode
        if cutlass.const_expr(
            self.scale_granularity_m == 0 and self.scale_granularity_k == 0
        ):
            self.scale_mode = TransformMode.ConvertOnly
        else:
            self.scale_mode = TransformMode.ConvertScale
        self.group_count = group_count
        self.acc_dtype = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.mma_tiler = mma_tiler_mnk

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        # Set specialized warp ids
        self.epilog_warp_id = (
            0,
            1,
            2,
            3,
        )
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.scale_tma_warp_id = 6
        # Schedule warp to do the group search
        self.schedule_warp_id = 7
        self.transform_warp_id = (
            8,
            9,
            10,
            11,
        )
        # Define expected register count for different warps
        self.num_regs_epilogue_warps = 192
        self.num_regs_mma_warp = 96
        self.num_regs_tma_warps = 80
        self.num_regs_transform_warps = 208
        self.num_regs_schedule_warp = 64
        self.threads_per_cta = 32 * (
            max(
                (
                    self.mma_warp_id,
                    self.tma_warp_id,
                    self.scale_tma_warp_id,
                    *self.epilog_warp_id,
                    *self.transform_warp_id,
                )
            )
            + 1
        )

        # Set barrier id for cta sync, epilogue sync, tmem ptr sync, and transform sync
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            1, 32 * len(self.epilog_warp_id)
        )
        self.tmem_ptr_sync_barrier = pipeline.NamedBarrier(2, self.threads_per_cta)
        self.transform_sync_barrier = pipeline.NamedBarrier(
            3, 32 * len(self.transform_warp_id)
        )
        self.cta_sync_barrier = pipeline.NamedBarrier(4, self.threads_per_cta)
        self.sched_sync_barrier = pipeline.NamedBarrier(5, 32)

        self.smem_buffer_align_bytes = 1024


    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Deduce where the transformed A tensor is stored
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/scale/B/C stage counts in shared memory
        - Setting up transformed A stage count in shared memory or tensor memory
        - Computing A/transformed A/scale/B/C memory layout
        - Computing tensor memory allocation columns
        """
        # Deduce where the transformed A tensor is stored, shared memory(SMEM) or tensor memory(TMEM)
        self.transform_a_source = mixed_input_utils.get_transform_a_source(
            self.a_major_mode
        )
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cluster_tile_shape_mnk = (
            self.cluster_shape_mn[0] * self.cta_tile_shape_mnk[0],
            self.cluster_shape_mn[1] * self.cta_tile_shape_mnk[1],
            self.cta_tile_shape_mnk[2],
        )
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1

        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        # Compute tensor memory(TMEM) columns and stages for each pipeline
        (
            self.num_load2trans_stage,
            self.num_scale_load2trans_stage,
            self.num_trans2mma_stage,
            self.num_acc_stage,
            self.num_c_stage,
            self.num_tile_info_stage,
            self.num_acc_tmem_cols,
            self.num_a_tmem_cols,
        ) = self._compute_stages_and_tmem_cols(
            tiled_mma,
            self.mma_tiler,
            self.cta_tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.b_dtype,
            self.c_dtype,
            self.c_layout,
            self.transform_a_source,
            self.scale_granularity_m,
            self.scale_granularity_k,
            self.smem_buffer_align_bytes,
            self.scale_mode,
        )

        # Align TMEM columns for allocation
        # TMEM allocation requires power-of-2 column alignment
        # and must meet minimum allocation requirements
        self.num_tmem_alloc_cols = GroupedMixedInputGemmKernel.align_up(
            self.num_acc_tmem_cols + self.num_a_tmem_cols,
            cute.arch.SM100_TMEM_MIN_ALLOC_COLUMNS,
        )
        self.num_tmem_alloc_cols = 2 ** (ceil(log2(self.num_tmem_alloc_cols)))
        # Get smem layout for C tensor
        self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.c_dtype,
            self.c_layout,
            self.epi_tile,
            self.num_c_stage,
        )
        # Get smem layout for A, transformed A, and B
        (
            self.smem_layout_a,
            self.smem_layout_a_transform,
            self.smem_layout_b,
        ) = mixed_input_utils.compute_smem_layout(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.num_load2trans_stage,
            self.num_trans2mma_stage,
        )
        # Get smem layout for scale tensor
        self.smem_layout_scale_per_stage = None
        self.smem_layout_scale = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Get scale tile shape and smem layout for scale tensor
            (
                self.scale_tile_shape,
                self.smem_layout_scale_per_stage,
                self.smem_layout_scale,
            ) = mixed_input_utils.get_smem_layout_scale(
                self.mma_tiler,
                self.use_2cta_instrs,
                self.scale_granularity_m,
                self.scale_granularity_k,
                self.scale_major_mode,
                self.a_scale_dtype,
                self.num_scale_load2trans_stage,
            )

    def _validate_inputs(
        self,
        a: cute.Tensor,
        a_scale: Optional[cute.Tensor],
        b: cute.Tensor,
        c: cute.Tensor,
    ) -> None:
        """
        Validates input tensors and their properties.

        :param a: Input tensor A.
        :type a: cute.Tensor
        :param a_scale: Scale tensor for tensor A (None for ConvertOnly mode).
        :type a_scale: Optional[cute.Tensor]
        :param b: Input tensor B.
        :type b: cute.Tensor
        :param c: Output tensor C.
        :type c: cute.Tensor
        :raises ValueError: If inputs don't meet kernel requirements.
        """
        # Validate scale tensor major mode
        if cutlass.const_expr(
            self.scale_mode == TransformMode.ConvertScale
            and utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
            != tcgen05.OperandMajorMode.MN
        ):
            raise ValueError("scale_major_mode should be m-major")

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        a_scale: Optional[cute.Tensor],  # None for ConvertOnly mode
        b: cute.Tensor,
        cumsum: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """
        Executes the Mixed Input Grouped GEMM operation.

        This method sets up the kernel parameters, computes the grid size,
        defines the shared storage, and launches the kernel.

        The execution steps are as follows:
        - Setup static attributes before smem/grid/tma computation.
        - Setup TMA load/store atoms and tensors.
        - Compute grid size with regard to hardware constraints.
        - Define shared storage for kernel.
        - Launch the kernel synchronously.

        :param a: Input tensor A.
        :type a: cute.Tensor
        :param a_scale: Scale tensor for tensor A (None for ConvertOnly mode).
        :type a_scale: Optional[cute.Tensor]
        :param b: Input tensor B.
        :type b: cute.Tensor
        :param cumsum: tensor containing the cumulative size of each group along the search mode(aka, N mode in this example).
        :type cumsum: cute.Tensor
        :param c: Output tensor C.
        :type c: cute.Tensor
        :param max_active_clusters: Maximum number of active clusters to launch.
        :type max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream to launch the kernel on.
        :type stream: cuda.CUstream
        """
        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.a_scale_dtype: type[cutlass.Numeric] = (
            a_scale.element_type
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.c_dtype: type[cutlass.Numeric] = c.element_type
        self.mma_dtype = self.b_dtype

        self.a_major_mode = utils.LayoutEnum.from_tensor(a).mma_major_mode()
        self.scale_major_mode = (
            utils.LayoutEnum.from_tensor(a_scale).mma_major_mode()
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        self.b_major_mode = utils.LayoutEnum.from_tensor(b).mma_major_mode()
        self.c_layout = utils.LayoutEnum.from_tensor(c)
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Get gmem layout for scale tensor
            self.gmem_layout_scale = mixed_input_utils.get_gmem_layout_scale(
                a.shape,
                self.scale_granularity_m,
                self.scale_granularity_k,
                self.scale_major_mode,
            )

        # Validate inputs
        self._validate_inputs(a, a_scale, b, c)

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.mma_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
            self.transform_a_source,
        )
        # Set up gmem copy atoms for A, scale, and B
        a_op = mixed_input_utils.get_tma_atom_kind(
            self.is_a_mcast, self.use_2cta_instrs, False
        )
        b_op = mixed_input_utils.get_tma_atom_kind(
            self.is_b_mcast, self.use_2cta_instrs, True
        )
        a_scale_op = a_op
        # Deduce TMA copy atom and TMA tensor for A, scale, and B
        smem_layout_a_per_stage = cute.slice_(self.smem_layout_a, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            smem_layout_a_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )

        tma_atom_scale, tma_tensor_scale = None, None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            # Partition smem layout for scale tensor to make it compatible with TMA atom
            smem_layout_for_tma_atom = cute.get(
                tiled_mma._thrfrg_A(self.smem_layout_scale_per_stage.outer), mode=[1]
            )
            # ((MMA_M, MMA_K), REST_M, REST_K)
            smem_layout_for_tma_atom = cute.dice(
                smem_layout_for_tma_atom,
                (1, (1,) * cute.rank(self.smem_layout_scale_per_stage.outer)),
            )
            tma_atom_scale, tma_tensor_scale = cute.nvgpu.make_tiled_tma_atom_A(
                a_scale_op,
                cute.make_tensor(a_scale.iterator, self.gmem_layout_scale),
                smem_layout_for_tma_atom,
                # (SCALE_M, 1, SCALE_K)
                (self.scale_tile_shape[0], 1, self.scale_tile_shape[1]),
                tiled_mma,
                self.cluster_layout_vmnk.shape,
                internal_type=(
                    cutlass.TFloat32
                    if a_scale.element_type is cutlass.Float32
                    else None
                ),
            )

        smem_layout_b_per_stage = cute.slice_(self.smem_layout_b, (None, None, None, 0))
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            smem_layout_b_per_stage,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )

        # Calculate copy size for tensor A, B, and scale
        a_copy_size = cute.size_in_bytes(self.a_dtype, smem_layout_a_per_stage)
        b_copy_size = cute.size_in_bytes(self.b_dtype, smem_layout_b_per_stage)
        a_scale_copy_size = (
            cute.size_in_bytes(self.a_scale_dtype, self.smem_layout_scale_per_stage)
            if self.scale_mode is TransformMode.ConvertScale
            else 0
        )

        self.num_tma_load_bytes_a = a_copy_size
        self.num_tma_load_bytes_b = b_copy_size * cute.size(tiled_mma.thr_id.shape)
        self.num_tma_load_bytes_scale = a_scale_copy_size
        self.tile_sched_params, grid = self._compute_grid(
            c,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            max_active_clusters,
        )

        epi_smem_layout = cute.slice_(self.c_smem_layout_staged, (None, None, 0))
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            c,
            epi_smem_layout,
            self.epi_tile,
        )
        c_smem_size = cute.cosize(self.c_smem_layout_staged.outer)

        # Shared memory structure
        a_smem_size = cute.cosize(self.smem_layout_a.outer)
        b_smem_size = cute.cosize(self.smem_layout_b.outer)
        a_transform_smem_size = (
            cute.cosize(self.smem_layout_a_transform.outer)
            if self.transform_a_source == tcgen05.OperandSource.SMEM
            else 0
        )
        a_scale_smem_size = (
            cute.cosize(self.smem_layout_scale.outer)
            if self.scale_mode is TransformMode.ConvertScale
            else 0
        )

        @cute.struct
        class SharedStorage:
            # buffer holding group search results
            tile_info: cute.struct.MemRange[cutlass.Int32, 4 * self.num_tile_info_stage]
            a_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            a_scale_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_scale_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_scale_load2trans_stage
            ]
            a_trans2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            a_trans2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_trans2mma_stage
            ]
            b_load2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            b_load2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_load2trans_stage
            ]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tile_info_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_tile_info_stage
            ]
            tile_info_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_tile_info_stage
            ]
            tmem_dealloc_mbar_ptr: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        self.shared_storage = SharedStorage

        # Launch kernel
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_scale,
            tma_tensor_scale,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_c,
            tma_tensor_c,
            c,
            cumsum,
            self.group_count,
            self.cluster_layout_vmnk,
            self.smem_layout_a,
            self.smem_layout_scale,
            self.smem_layout_a_transform,
            self.smem_layout_b,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            min_blocks_per_mp=1,
            stream=stream,
        )
        return

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_s: Optional[cute.CopyAtom],
        mS_mkl: Optional[cute.Tensor],
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        tensor_c: cute.Tensor,
        cumsum: cute.Tensor,
        group_count: cutlass.Constexpr[int],
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout: cute.ComposedLayout,
        scale_smem_layout: cute.ComposedLayout,
        a_smem_layout_transform: cute.ComposedLayout,
        b_smem_layout: cute.ComposedLayout,
        c_smem_layout_staged: cute.ComposedLayout,
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
    ):
        """
        GPU device kernel performing the Persistent Mixed-Input Grouped GEMM computation.
        """
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        tidx, _, _ = cute.arch.thread_idx()
        bidx, bidy, bidz = cute.arch.block_idx()
        # Prefetch TMA descriptors
        if warp_idx == self.epilog_warp_id[0]:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                cpasync.prefetch_descriptor(tma_atom_s)
            cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2
        bidx, bidy, bidz = cute.arch.block_idx()
        # Compute how many k_tiles share the same scale
        num_k_tiles_per_scale = self.scale_granularity_k // self.cta_tile_shape_mnk[2]

        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize load2transform pipeline, which tracks the dependencies between TMA's loading
        # of A and B, and the transformation of A and MMA's consumption
        transform_thread_idx = (
            tidx - 32 * self.transform_warp_id[0]
            if tidx >= 32 * self.transform_warp_id[0]
            else tidx
        )
        a_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.a_load2trans_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.num_mcast_ctas_a * len(self.transform_warp_id),
            ),
            tx_count=self.num_tma_load_bytes_a,
            cta_layout_vmnk=cluster_layout_vmnk,
            tidx=transform_thread_idx,
            mcast_mode_mn=(1, 0),  # multicast for A will only happen on the M-mode
            defer_sync=True,
        )
        # Initialize scale_load2trans pipeline, which tracks the dependencies between TMA's loading
        # of scale, and the transformation of A
        scale_load2trans_pipeline = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            num_producers_a_scale = self.num_mcast_ctas_a
            scale_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
                barrier_storage=storage.a_scale_load2trans_full_mbar_ptr.data_ptr(),
                num_stages=self.num_scale_load2trans_stage,
                producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
                consumer_group=pipeline.CooperativeGroup(
                    pipeline.Agent.Thread,
                    num_producers_a_scale
                    * len(self.transform_warp_id)
                    * num_k_tiles_per_scale,
                ),
                tx_count=self.num_tma_load_bytes_scale,
                cta_layout_vmnk=cluster_layout_vmnk,
                tidx=transform_thread_idx,
                mcast_mode_mn=(
                    1,
                    0,
                ),  # multicast for scale_a will only happen on the M-mode
                defer_sync=True,
            )
        # Initialize transform2mma pipeline, which tracks the dependencies between the transformation
        # of A and MMA's consumption of transformed A
        cta_v_size = cute.size(cluster_layout_vmnk, mode=[0])
        trans2mma_pipeline = pipeline.PipelineAsyncUmma.create(
            barrier_storage=storage.a_trans2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_trans2mma_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.transform_warp_id) * cta_v_size,
            ),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )
        # Initialize pipeline for tensor B load to MMA
        # MMA warp informs TMA warp to proceed to load next tile of B tensor
        b_load2mma_pipeline = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.b_load2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.num_load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self.num_mcast_ctas_b
            ),
            tx_count=self.num_tma_load_bytes_b,
            cta_layout_vmnk=cluster_layout_vmnk,
            mcast_mode_mn=(0, 1),  # multicast for B will only happen on the N-mode
            defer_sync=True,
        )
        # Initialize accumulator pipeline, which tracks the dependencies between
        # MMA's computation of accumulators and epilogue warps' consumption of accumulators
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, cta_v_size * len(self.epilog_warp_id)
            ),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )
        # Initialize tile info pipeline, which tracks the dependencies between
        # tile scheduling warp and other warps
        # Skip scheduler warp and TMA scale load warp when scale_mode is ConvertOnly
        # when computing consumer thread count
        num_tile_info_pipeline_consumer_threads = (
            self.threads_per_cta
            - 32
            - (32 if self.scale_mode is TransformMode.ConvertOnly else 0)
        )
        tile_info_pipeline = pipeline.PipelineAsync.create(
            barrier_storage=storage.tile_info_full_mbar_ptr.data_ptr(),
            num_stages=self.num_tile_info_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 32 * 1),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                num_tile_info_pipeline_consumer_threads,
            ),
            defer_sync=True,
        )

        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf,
            barrier_for_retrieve=self.tmem_ptr_sync_barrier,
            allocator_warp_id=self.epilog_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True)

        # Setup smem tensor A/scale/B/C
        sC = smem.allocate_tensor(
            element_type=self.c_dtype,
            layout=c_smem_layout_staged.outer,
            byte_alignment=self.smem_buffer_align_bytes,
            swizzle=c_smem_layout_staged.inner,
        )
        sA_input = smem.allocate_tensor(
            element_type=self.a_dtype,
            layout=a_smem_layout.outer,
            byte_alignment=self.smem_buffer_align_bytes,
            swizzle=a_smem_layout.inner,
        )
        sS_input = (
            smem.allocate_tensor(
                element_type=self.mma_dtype,
                layout=scale_smem_layout.outer,
                byte_alignment=self.smem_buffer_align_bytes,
                swizzle=scale_smem_layout.inner,
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        sB_input = smem.allocate_tensor(
            element_type=self.b_dtype,
            layout=b_smem_layout.outer,
            byte_alignment=self.smem_buffer_align_bytes,
            swizzle=b_smem_layout.inner,
        )
        sA_transform = None
        # Get smem tensor for transformed A when transform_a_source is SMEM
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.SMEM):
            sA_transform = smem.allocate_tensor(
                element_type=self.mma_dtype,
                layout=a_smem_layout_transform.outer,
                byte_alignment=self.smem_buffer_align_bytes,
                swizzle=a_smem_layout_transform.inner,
            )
        sTile_info = storage.tile_info.get_tensor(
            cute.make_layout((4, self.num_tile_info_stage), stride=(1, 4))
        )

        # Compute multicast mask for A/B buffer full
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        s_full_mcast_mask = None
        if cutlass.const_expr(self.is_a_mcast or self.is_b_mcast or use_2cta_instrs):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            # scale tensor share the same multicast mask with A tensor
            s_full_mcast_mask = a_full_mcast_mask
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        # local_tile partition global tensors
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bM, bK, loopM, loopK, loopL)
        gS_mkl = (
            cute.local_tile(
                mS_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, loopM, loopN, loopL)
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        gC_mnl_simt = cute.local_tile(
            tensor_c, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Partition global tensor for TiledMMA_A/B/C
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgS = (
            thr_mma.partition_A(gS_mkl)
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
        tCgC = thr_mma.partition_C(gC_mnl)
        tCgC_simt = thr_mma.partition_C(gC_mnl_simt)

        # Setup copy atom to load A from shared memory for further transformation
        copy_atom_a_input = (
            cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(), self.a_dtype, num_bits_per_copy=32
            )
            if self.scale_mode is TransformMode.ConvertScale
            else None
        )
        a_smem_shape = tiled_mma.partition_shape_A(
            cute.dice(self.mma_tiler, (1, None, 1))
        )
        # Setup copy atom to store transformed A into tensor memory or shared memory
        copy_atom_a_transform = mixed_input_utils.get_copy_atom_a_transform(
            self.mma_dtype,
            self.use_2cta_instrs,
            self.transform_a_source,
            a_smem_shape,
            self.a_dtype,
        )

        # Partition global/shared tensor for TMA load A/B
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA_input, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )

        tCsS = None
        tSsS = None
        tSgS = None
        if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
            thr_mma_leader_cta = tiled_mma.get_slice(0)
            # (MMA, MMA_M, MMA_K, STAGE)
            tCsS = thr_mma_leader_cta.partition_A(sS_input)
            # ((atom_v, rest_v), STAGE)
            # ((atom_v, rest_v), loopM, loopK, loopL)
            tSsS, tSgS = mixed_input_utils.scale_tma_partition(
                tCsS,
                tCgS,
                tma_atom_s,
                block_in_cluster_coord_vmnk,
                a_cta_layout,
            )

        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), loopM, loopK, loopL)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB_input, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )

        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB_input)
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Cluster wait before TMEM alloc and ensure pipelines are ready
        pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        # TMEM allocation
        tmem.allocate(self.num_tmem_alloc_cols)
        tmem.wait_for_alloc()
        # Get the pointer to the TMEM buffer
        tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
        accumulators = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        tCrA = None
        if cutlass.const_expr(self.transform_a_source == tcgen05.OperandSource.TMEM):
            tmem_ptr_transform = cute.recast_ptr(
                accumulators.iterator + self.num_acc_tmem_cols, dtype=self.mma_dtype
            )
            tCrA = cute.make_tensor(
                tmem_ptr_transform,
                tiled_mma.make_fragment_A(a_smem_layout_transform.outer).layout,
            )
        else:
            tCrA = tiled_mma.make_fragment_A(sA_transform)

        # Schedule warp
        if warp_idx == self.schedule_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_schedule_warp)
            # Persistent tile scheduling loop
            tile_sched = utils.StaticPersistentRuntimeTileScheduler.create(
                tile_sched_params,
                (bidx, bidy, bidz),
                cute.arch.grid_dim(),
                inner_mode=0,
            )
            work_tile = tile_sched.initial_work_tile_info()
            tile_info_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_tile_info_stage
            )
            # Create initial group search state
            search_state = create_initial_search_state()
            not_last_tile = cutlass.Boolean(1)
            while not_last_tile:
                tile_info_pipeline.producer_acquire(tile_info_producer_state)
                cluster_tile_coord_mnl = work_tile.tile_idx
                cta_tile_coord_m = (
                    cluster_tile_coord_mnl[0] * self.cluster_shape_mn[0]
                    + block_in_cluster_coord_vmnk[1] * cute.size(tiled_mma.thr_id.shape)
                    + block_in_cluster_coord_vmnk[0]
                )
                cta_tile_offset_n = block_in_cluster_coord_vmnk[2]
                search_state = self.group_search(
                    group_count,
                    cluster_tile_coord_mnl[1],
                    search_state,
                    cumsum,
                    1,  # mode index to perform the search. 0 for M and 1 for N
                )
                cur_sTile_info = sTile_info[(None, tile_info_producer_state.index)]
                not_last_tile = search_state.cur_group_idx <= group_count
                # Store tile info into shared memory buffer
                with cute.arch.elect_one():
                    cur_sTile_info[0] = cta_tile_coord_m
                    cur_sTile_info[1] = (
                        search_state.cur_start
                        + cta_tile_offset_n * self.cta_tile_shape_mnk[1]
                    )
                    cur_sTile_info[2] = search_state.cur_group_idx - 1
                    cur_sTile_info[3] = (
                        search_state.cur_boundary
                        - search_state.cur_start
                        - (cta_tile_offset_n * self.cta_tile_shape_mnk[1])
                    )
                # Fence and barrier to ensure tile info store has finished
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                self.sched_sync_barrier.arrive_and_wait()
                # Commit tile info pipeline
                tile_info_pipeline.producer_commit(tile_info_producer_state)
                # Advance to next tile
                tile_info_producer_state.advance()
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            tile_info_pipeline.producer_tail(tile_info_producer_state)

        # Specialized TMA load warp for A/B tensor
        if warp_idx == self.tma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_tma_warps)
            # Persistent tile scheduling loop
            tile_info_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_tile_info_stage
            )
            tile_info_pipeline.consumer_wait(tile_info_consumer_state)
            work_tile = self.make_work_tile_info(
                sTile_info[(None, tile_info_consumer_state.index)]
            )
            cute.arch.fence_proxy(
                cute.arch.ProxyKind.async_shared,
                space=cute.arch.SharedSpace.shared_cta,
            )
            tile_info_pipeline.consumer_release(tile_info_consumer_state)
            tile_info_consumer_state.advance()
            a_load2trans_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )
            b_load2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_load2trans_stage
            )

            while work_tile.is_valid_tile:
                tAgA_slice = tAgA[
                    (
                        None,
                        work_tile.cta_coord_m // cute.size(tiled_mma.thr_id.shape),
                        None,
                        work_tile.group_idx,
                    )
                ]
                # Apply offset to B tensor based on group search result
                coord_n_offset = (
                    (work_tile.coord_n, 0, 0)
                    if cutlass.const_expr(
                        self.b_major_mode == tcgen05.OperandMajorMode.MN
                    )
                    else (0, work_tile.coord_n, 0)
                )
                tBgB_slice = cute.make_tensor(
                    (
                        tBgB.iterator[0] + coord_n_offset[0],
                        coord_n_offset[1] + tBgB.iterator[1],
                        coord_n_offset[2] + tBgB.iterator[2],
                    ),
                    cute.slice_(tBgB.layout, (None, 0, None, 0)),
                )

                a_load2trans_producer_state.reset_count()
                peek_load2trans_empty_status = cutlass.Boolean(1)
                if a_load2trans_producer_state.count < k_tile_cnt:
                    peek_load2trans_empty_status = (
                        a_load2trans_pipeline.producer_try_acquire(
                            a_load2trans_producer_state
                        )
                    )
                b_load2mma_producer_state.reset_count()
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.producer_acquire(
                        a_load2trans_producer_state, peek_load2trans_empty_status
                    )
                    b_load2mma_pipeline.producer_acquire(b_load2mma_producer_state)
                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, a_load2trans_producer_state.count)],
                        tAsA[(None, a_load2trans_producer_state.index)],
                        tma_bar_ptr=a_load2trans_pipeline.producer_get_barrier(
                            a_load2trans_producer_state
                        ),
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, b_load2mma_producer_state.count)],
                        tBsB[(None, b_load2mma_producer_state.index)],
                        tma_bar_ptr=b_load2mma_pipeline.producer_get_barrier(
                            b_load2mma_producer_state
                        ),
                        mcast_mask=b_full_mcast_mask,
                    )
                    a_load2trans_pipeline.producer_commit(a_load2trans_producer_state)
                    b_load2mma_pipeline.producer_commit(b_load2mma_producer_state)
                    a_load2trans_producer_state.advance()
                    b_load2mma_producer_state.advance()
                    if a_load2trans_producer_state.count < k_tile_cnt:
                        peek_load2trans_empty_status = (
                            a_load2trans_pipeline.producer_try_acquire(
                                a_load2trans_producer_state
                            )
                        )
                # Advance to next tile
                tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                work_tile = self.make_work_tile_info(
                    sTile_info[(None, tile_info_consumer_state.index)]
                )
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                tile_info_pipeline.consumer_release(tile_info_consumer_state)
                tile_info_consumer_state.advance()
            # Wait A/B buffer empty
            a_load2trans_pipeline.producer_tail(a_load2trans_producer_state)
            b_load2mma_pipeline.producer_tail(b_load2mma_producer_state)

        # Specialized TMA load for scale tensor
        if warp_idx == self.scale_tma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_tma_warps)
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                # Persistent tile scheduling loop
                tile_info_consumer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, self.num_tile_info_stage
                )
                tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                work_tile = self.make_work_tile_info(
                    sTile_info[(None, tile_info_consumer_state.index)]
                )
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                tile_info_pipeline.consumer_release(tile_info_consumer_state)
                tile_info_consumer_state.advance()
                scale_load2trans_producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer, self.num_scale_load2trans_stage
                )
                scale_k_tile_cnt = cute.size(mS_mkl.layout.shape[1][1])

                while work_tile.is_valid_tile:
                    # ((atom_v, rest_v), RestK)
                    tSgS_slice = tSgS[
                        (
                            None,
                            work_tile.cta_coord_m // cute.size(tiled_mma.thr_id.shape),
                            None,
                            work_tile.group_idx,
                        )
                    ]
                    # Filter zeros in rest mode
                    rest_filtered = cute.filter_zeros(tSgS_slice[(0, None)].layout)
                    tSgS_slice_filtered = cute.make_tensor(
                        tSgS_slice.iterator,
                        cute.make_layout(
                            (tSgS_slice.layout[0].shape, rest_filtered.shape),
                            stride=(tSgS_slice.layout[0].stride, rest_filtered.stride),
                        ),
                    )

                    scale_load2trans_producer_state.reset_count()
                    peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                    if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                        peek_scale_load2trans_empty_status = (
                            scale_load2trans_pipeline.producer_try_acquire(
                                scale_load2trans_producer_state
                            )
                        )
                    for k_tile in cutlass.range(0, scale_k_tile_cnt, 1, unroll=1):
                        scale_load2trans_pipeline.producer_acquire(
                            scale_load2trans_producer_state,
                            peek_scale_load2trans_empty_status,
                        )
                        # TMA load scale
                        cute.copy(
                            tma_atom_s,
                            tSgS_slice_filtered[
                                (None, scale_load2trans_producer_state.count)
                            ],
                            tSsS[(None, scale_load2trans_producer_state.index)],
                            tma_bar_ptr=scale_load2trans_pipeline.producer_get_barrier(
                                scale_load2trans_producer_state
                            ),
                            mcast_mask=s_full_mcast_mask,
                        )

                        scale_load2trans_producer_state.advance()
                        peek_scale_load2trans_empty_status = cutlass.Boolean(1)
                        if scale_load2trans_producer_state.count < scale_k_tile_cnt:
                            peek_scale_load2trans_empty_status = (
                                scale_load2trans_pipeline.producer_try_acquire(
                                    scale_load2trans_producer_state
                                )
                            )
                    # Advance to next tile
                    tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                    work_tile = self.make_work_tile_info(
                        sTile_info[(None, tile_info_consumer_state.index)]
                    )
                    cute.arch.fence_proxy(
                        cute.arch.ProxyKind.async_shared,
                        space=cute.arch.SharedSpace.shared_cta,
                    )
                    tile_info_pipeline.consumer_release(tile_info_consumer_state)
                    tile_info_consumer_state.advance()
                # Wait scale buffer empty
                scale_load2trans_pipeline.producer_tail(scale_load2trans_producer_state)

        # Specialized transform warps
        if warp_idx >= self.transform_warp_id[0]:
            cute.arch.warpgroup_reg_alloc(self.num_regs_transform_warps)
            transform_local_tidx = tidx - 32 * self.transform_warp_id[0]
            # Partition tensors for transform input and output and set up the copy atom
            # used for loading and storing transformed A tensor
            src_copy_a, dst_copy_a, tAsA_input, tAsA_transform = (
                mixed_input_utils.transform_partition(
                    self.transform_a_source,
                    self.scale_mode,
                    copy_atom_a_input,
                    copy_atom_a_transform,
                    sA_input,
                    (
                        tCrA
                        if self.transform_a_source == tcgen05.OperandSource.TMEM
                        else sA_transform
                    ),
                    transform_local_tidx,
                )
            )
            # make fragment for input A and transformed A
            tArA = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, tAsA_input.element_type
            )
            tArA_transform = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, self.mma_dtype
            )
            # Partition scale tensor
            smem_thr_copy_S = None
            tSsS_trans = None
            tSrS_copy = None
            tSrS = None
            if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS = (
                    mixed_input_utils.scale_partition(
                        src_copy_a, tCsS, transform_local_tidx, self.mma_dtype
                    )
                )
                assert cute.size(tSrS, mode=[0]) == cute.size(tArA, mode=[0]), (
                    "tSrS and tArA have different leading dimension"
                )
                assert cute.size(tSrS) == cute.size(tArA), (
                    "tSrS and tArA have different shape"
                )
            # Deduce a subtile size and tile tensors
            transform_tiler_size = min(
                cute.size(cute.coalesce(tAsA_input.layout), mode=[0]), 64
            )
            transform_tiler = cute.make_layout(transform_tiler_size)
            tArA_load = cute.flat_divide(tArA, transform_tiler)
            tArA_load = cute.group_modes(tArA_load, 1, cute.rank(tArA_load))
            tSrS_load = (
                cute.flat_divide(tSrS, transform_tiler)
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            tSrS_load = (
                cute.group_modes(tSrS_load, 1, cute.rank(tSrS_load))
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            tArA_transform_store = cute.flat_divide(tArA_transform, transform_tiler)
            tArA_transform_store = cute.group_modes(
                tArA_transform_store, 1, cute.rank(tArA_transform_store)
            )

            tile_info_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_tile_info_stage
            )
            tile_info_pipeline.consumer_wait(tile_info_consumer_state)
            work_tile = self.make_work_tile_info(
                sTile_info[(None, tile_info_consumer_state.index)]
            )
            cute.arch.fence_proxy(
                cute.arch.ProxyKind.async_shared,
                space=cute.arch.SharedSpace.shared_cta,
            )
            tile_info_pipeline.consumer_release(tile_info_consumer_state)
            tile_info_consumer_state.advance()
            a_load2trans_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.num_load2trans_stage,
            )
            scale_load2trans_consumer_state = (
                pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer,
                    self.num_scale_load2trans_stage,
                )
                if self.scale_mode is TransformMode.ConvertScale
                else None
            )
            trans2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer,
                self.num_trans2mma_stage,
            )
            while work_tile.is_valid_tile:
                a_load2trans_consumer_state.reset_count()
                peek_load2trans_full_status = cutlass.Boolean(1)
                if a_load2trans_consumer_state.count < k_tile_cnt:
                    peek_load2trans_full_status = (
                        a_load2trans_pipeline.consumer_try_wait(
                            a_load2trans_consumer_state
                        )
                    )
                peek_scale_load2trans_full_status = cutlass.Boolean(1)
                if cutlass.const_expr(self.scale_mode == TransformMode.ConvertScale):
                    scale_load2trans_consumer_state.reset_count()
                    peek_scale_load2trans_full_status = (
                        scale_load2trans_pipeline.consumer_try_wait(
                            scale_load2trans_consumer_state
                        )
                    )
                trans2mma_producer_state.reset_count()
                peek_trans2mma_empty_status = cutlass.Boolean(1)
                if trans2mma_producer_state.count < k_tile_cnt:
                    peek_trans2mma_empty_status = (
                        trans2mma_pipeline.producer_try_acquire(
                            trans2mma_producer_state
                        )
                    )

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    a_load2trans_pipeline.consumer_wait(
                        a_load2trans_consumer_state, peek_load2trans_full_status
                    )
                    tAsA_input_slice = tAsA_input[
                        (None, None, None, None, a_load2trans_consumer_state.index)
                    ]
                    tAsA_input_slice = cute.flat_divide(
                        tAsA_input_slice, transform_tiler
                    )
                    tAsA_input_slice = cute.group_modes(
                        tAsA_input_slice, 1, cute.rank(tAsA_input_slice)
                    )
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_wait(
                            scale_load2trans_consumer_state,
                            peek_scale_load2trans_full_status,
                        )
                    trans2mma_pipeline.producer_acquire(
                        trans2mma_producer_state, peek_trans2mma_empty_status
                    )
                    # load scale tensor when needed
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        if k_tile % num_k_tiles_per_scale == 0:
                            tSsS_slice = tSsS_trans[
                                (
                                    None,
                                    None,
                                    None,
                                    None,
                                    scale_load2trans_consumer_state.index,
                                )
                            ]
                            tSsS_slice_filtered = cute.make_tensor(
                                tSsS_slice.iterator,
                                cute.filter_zeros(tSsS_slice.layout),
                            )
                            cute.autovec_copy(tSsS_slice_filtered, tSrS_copy)
                        cur_scale_load2trans_consumer_state = (
                            scale_load2trans_consumer_state.clone()
                        )
                        if (k_tile + 1) % num_k_tiles_per_scale == 0:
                            scale_load2trans_consumer_state.advance()

                    cur_a_load2trans_consumer_state = (
                        a_load2trans_consumer_state.clone()
                    )
                    for idx in cutlass.range_constexpr(cute.size(tArA_load, mode=[1])):
                        # Load A from shared memory
                        cute.autovec_copy(
                            tAsA_input_slice[(None, idx)],
                            tArA_load[(None, idx)],
                        )
                        if cutlass.const_expr(
                            idx == cute.size(tArA_load, mode=[1]) - 1
                        ):
                            a_load2trans_consumer_state.advance()
                            if a_load2trans_consumer_state.count < k_tile_cnt:
                                peek_load2trans_full_status = (
                                    a_load2trans_pipeline.consumer_try_wait(
                                        a_load2trans_consumer_state
                                    )
                                )
                                if cutlass.const_expr(
                                    self.scale_mode == TransformMode.ConvertScale
                                ):
                                    peek_scale_load2trans_full_status = (
                                        scale_load2trans_pipeline.consumer_try_wait(
                                            scale_load2trans_consumer_state
                                        )
                                    )
                        # Convert it to mma dtype
                        tensor_transformed = (
                            tArA_load[(None, idx)].load().to(self.mma_dtype)
                        )
                        if cutlass.const_expr(
                            self.scale_mode == TransformMode.ConvertScale
                        ):
                            scale = cute.TensorSSA(
                                tSrS_load[(None, idx)].load(),
                                tensor_transformed.shape,
                                self.mma_dtype,
                            )
                            # Apply scale
                            tensor_transformed = tensor_transformed * scale
                        tArA_transform_store[(None, idx)].store(tensor_transformed)
                    # Store transformed A to tensor memory or shared memory
                    if cutlass.const_expr(dst_copy_a is not None):
                        cute.copy(
                            dst_copy_a,
                            tArA_transform,
                            tAsA_transform[
                                (None, None, None, None, trans2mma_producer_state.index)
                            ],
                        )
                    else:
                        cute.autovec_copy(
                            tArA_transform,
                            tAsA_transform[
                                (None, None, None, None, trans2mma_producer_state.index)
                            ],
                        )
                    # Ensure all transform threads have finished the copy and reached the fence
                    self.transform_sync_barrier.arrive_and_wait()
                    if cutlass.const_expr(
                        self.transform_a_source == tcgen05.OperandSource.TMEM
                    ):
                        cute.arch.fence_view_async_tmem_store()
                    else:
                        cute.arch.fence_proxy(
                            cute.arch.ProxyKind.async_shared,
                            space=cute.arch.SharedSpace.shared_cta,
                        )
                    if cutlass.const_expr(
                        self.scale_mode == TransformMode.ConvertScale
                    ):
                        scale_load2trans_pipeline.consumer_release(
                            cur_scale_load2trans_consumer_state
                        )

                    a_load2trans_pipeline.consumer_release(
                        cur_a_load2trans_consumer_state
                    )
                    # Signal the completion of transformation
                    trans2mma_pipeline.producer_commit(trans2mma_producer_state)
                    trans2mma_producer_state.advance()
                    if trans2mma_producer_state.count < k_tile_cnt:
                        peek_trans2mma_empty_status = (
                            trans2mma_pipeline.producer_try_acquire(
                                trans2mma_producer_state
                            )
                        )
                # Advance to next tile
                tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                work_tile = self.make_work_tile_info(
                    sTile_info[(None, tile_info_consumer_state.index)]
                )
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                tile_info_pipeline.consumer_release(tile_info_consumer_state)
                tile_info_consumer_state.advance()
            # Wait a_transform buffer empty
            trans2mma_pipeline.producer_tail(trans2mma_producer_state)

        # Specialized MMA warp
        if warp_idx == self.mma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_mma_warp)
            tCtAcc_base = accumulators
            # Persistent tile scheduling loop
            tile_info_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_tile_info_stage
            )
            tile_info_pipeline.consumer_wait(tile_info_consumer_state)
            work_tile = self.make_work_tile_info(
                sTile_info[(None, tile_info_consumer_state.index)]
            )
            cute.arch.fence_proxy(
                cute.arch.ProxyKind.async_shared,
                space=cute.arch.SharedSpace.shared_cta,
            )
            tile_info_pipeline.consumer_release(tile_info_consumer_state)
            tile_info_consumer_state.advance()
            trans2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_trans2mma_stage
            )
            b_load2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_load2trans_stage
            )
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )
            while work_tile.is_valid_tile:
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]
                b_load2mma_consumer_state.reset_count()
                trans2mma_consumer_state.reset_count()
                peek_trans2mma_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    if trans2mma_consumer_state.count < k_tile_cnt:
                        peek_trans2mma_full_status = (
                            trans2mma_pipeline.consumer_try_wait(
                                trans2mma_consumer_state
                            )
                        )
                    acc_pipeline.producer_acquire(acc_producer_state)

                    tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
                    # Mma mainloop
                    for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        trans2mma_pipeline.consumer_wait(
                            trans2mma_consumer_state, peek_trans2mma_full_status
                        )
                        b_load2mma_pipeline.consumer_wait(b_load2mma_consumer_state)
                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblock_coord_a = (
                                None,
                                None,
                                kblock_idx,
                                trans2mma_consumer_state.index,
                            )
                            kblock_coord_b = (
                                None,
                                None,
                                kblock_idx,
                                b_load2mma_consumer_state.index,
                            )

                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblock_coord_a],
                                tCrB[kblock_coord_b],
                                tCtAcc,
                            )
                            # Enable accumulate on tCtAcc after first kblock
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                        trans2mma_pipeline.consumer_release(trans2mma_consumer_state)
                        b_load2mma_pipeline.consumer_release(b_load2mma_consumer_state)
                        trans2mma_consumer_state.advance()
                        b_load2mma_consumer_state.advance()
                        peek_trans2mma_full_status = cutlass.Boolean(1)
                        if trans2mma_consumer_state.count < k_tile_cnt:
                            peek_trans2mma_full_status = (
                                trans2mma_pipeline.consumer_try_wait(
                                    trans2mma_consumer_state
                                )
                            )
                    # Async arrive accumulator buffer full
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                # Advance to next tile
                tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                work_tile = self.make_work_tile_info(
                    sTile_info[(None, tile_info_consumer_state.index)]
                )
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                tile_info_pipeline.consumer_release(tile_info_consumer_state)
                tile_info_consumer_state.advance()
            # Wait for accumulator buffer empty
            acc_pipeline.producer_tail(acc_producer_state)

        # Specialized epilogue warps
        if warp_idx < self.mma_warp_id:
            cute.arch.warpgroup_reg_alloc(self.num_regs_epilogue_warps)
            epi_tidx = tidx
            tCtAcc_base = accumulators
            # Partition for epilogue
            tiled_copy_t2r, tTR_tAcc_base, tTR_rAcc = (
                self.epilog_tmem_copy_and_partition(
                    epi_tidx, tCtAcc_base, tCgC, epi_tile, use_2cta_instrs
                )
            )

            tTR_rC = cute.make_rmem_tensor(tTR_rAcc.shape, self.c_dtype)
            tiled_copy_r2s, tRS_rC, tRS_sC = self.epilog_smem_copy_and_partition(
                tiled_copy_t2r, tTR_rC, epi_tidx, sC
            )
            (tma_atom_c, bSG_sC, bSG_gC_partitioned, simt_atom, tTR_gC_partitioned) = (
                self.epilog_gmem_copy_and_partition(
                    epi_tidx, tma_atom_c, tiled_copy_t2r, tCgC, tCgC_simt, epi_tile, sC
                )
            )

            # Predicates
            thr_mapping = cute.make_identity_tensor(
                (self.cta_tile_shape_mnk[0], self.cta_tile_shape_mnk[1])
            )
            thr_mapping_mn = cute.flat_divide(thr_mapping, epi_tile)
            thr_copy_t2r = tiled_copy_t2r.get_slice(epi_tidx)
            m_thr_offset = thr_copy_t2r.partition_D(thr_mapping_mn)
            m_thr_offset = cute.group_modes(m_thr_offset, 3, cute.rank(m_thr_offset))

            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            c_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilog_warp_id),
            )
            c_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_c_stage,
                producer_group=c_producer_group,
            )

            # Persistent tile scheduling loop
            tile_info_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_tile_info_stage
            )
            tile_info_pipeline.consumer_wait(tile_info_consumer_state)
            work_tile = self.make_work_tile_info(
                sTile_info[(None, tile_info_consumer_state.index)]
            )
            cute.arch.fence_proxy(
                cute.arch.ProxyKind.async_shared,
                space=cute.arch.SharedSpace.shared_cta,
            )
            tile_info_pipeline.consumer_release(tile_info_consumer_state)
            tile_info_consumer_state.advance()
            num_prev_subtiles = cutlass.Int32(0)
            while work_tile.is_valid_tile:
                bSG_gC = bSG_gC_partitioned[
                    (
                        None,
                        None,
                        None,
                        work_tile.cta_coord_m // cute.size(tiled_mma.thr_id.shape),
                        0,
                        0,
                    )
                ]
                tma_store_offset_coord = (
                    (work_tile.coord_n, 0, 0)
                    if cutlass.const_expr(self.c_layout.is_n_major_c())
                    else (0, work_tile.coord_n, 0)
                )
                bSG_gC = cute.make_tensor(
                    (
                        tma_store_offset_coord[0] + bSG_gC.iterator[0],
                        tma_store_offset_coord[1] + bSG_gC.iterator[1],
                        tma_store_offset_coord[2] + bSG_gC.iterator[2],
                    ),
                    bSG_gC.layout,
                )
                tTR_gC = tTR_gC_partitioned[
                    (
                        None,
                        None,
                        None,
                        None,
                        None,
                        work_tile.cta_coord_m // cute.size(tiled_mma.thr_id.shape),
                        0,
                        0,
                    )
                ]
                tTR_gC = cute.make_tensor(
                    tTR_gC.iterator + (work_tile.coord_n * tensor_c.layout.stride[1]),
                    tTR_gC.layout,
                )

                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                # Wait for accumulator buffer full
                acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gC = cute.group_modes(bSG_gC, 1, cute.rank(bSG_gC))
                tTR_gC = cute.group_modes(tTR_gC, 3, cute.rank(tTR_gC))

                # Store accumulator to global memory in subtiles
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Load accumulator from tensor memory buffer to register
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    if work_tile.distance_to_boundary >= self.cta_tile_shape_mnk[1]:
                        # Convert to C type
                        acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tRS_rC.store(acc_vec)
                        num_prev_subtiles += 1
                        c_buffer = num_prev_subtiles % self.num_c_stage
                        # Store C to shared memory
                        cute.copy(
                            tiled_copy_r2s,
                            tRS_rC,
                            tRS_sC[(None, None, None, c_buffer)],
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        cute.arch.fence_proxy(
                            cute.arch.ProxyKind.async_shared,
                            space=cute.arch.SharedSpace.shared_cta,
                        )
                        self.epilog_sync_barrier.arrive_and_wait()
                        # TMA store C to global memory
                        if warp_idx == self.epilog_warp_id[0]:
                            cute.copy(
                                tma_atom_c,
                                bSG_sC[(None, c_buffer)],
                                bSG_gC[(None, subtile_idx)],
                            )
                            c_pipeline.producer_commit()
                            c_pipeline.producer_acquire()
                        self.epilog_sync_barrier.arrive_and_wait()
                    else:
                        # Convert to C type
                        acc_vec = tTR_rAcc.load()
                        acc_vec = acc_vec.to(self.c_dtype)
                        tTR_rC.store(acc_vec)
                        # Compute predicate for SIMT store
                        tCpC = cute.make_rmem_tensor(
                            cute.make_layout(tTR_rC.shape),
                            cutlass.Boolean,
                        )
                        m_thr_slice = m_thr_offset[(None, None, None, subtile_idx)]
                        for i in cutlass.range(cute.size(tCpC), unroll_full=True):
                            tCpC[i] = (
                                m_thr_slice[(i)][0]
                                + work_tile.cta_coord_m * self.cta_tile_shape_mnk[0]
                                < tensor_c.shape[0]
                            ) and (m_thr_slice[(i)][1] < work_tile.distance_to_boundary)
                        # Store C to global memory
                        cute.copy(
                            simt_atom,
                            cute.flatten(tTR_rC),
                            cute.flatten(tTR_gC[(None, None, None, subtile_idx)]),
                            pred=cute.flatten(tCpC),
                        )
                # Async arrive accumulator buffer empty
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()
                # Advance to next tile
                tile_info_pipeline.consumer_wait(tile_info_consumer_state)
                work_tile = self.make_work_tile_info(
                    sTile_info[(None, tile_info_consumer_state.index)]
                )
                cute.arch.fence_proxy(
                    cute.arch.ProxyKind.async_shared,
                    space=cute.arch.SharedSpace.shared_cta,
                )
                tile_info_pipeline.consumer_release(tile_info_consumer_state)
                tile_info_consumer_state.advance()

            # Dealloc the tensor memory buffer
            tmem.relinquish_alloc_permit()
            self.epilog_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
            c_pipeline.producer_tail()

    @cute.jit
    def group_search(
        self,
        group_count: cutlass.Int32,
        linear_idx: cutlass.Int32,
        search_state: ContiguousGGSearchState,
        cumsum: cute.Tensor,
        search_mode: int,
    ) -> ContiguousGGSearchState:
        """
        Group search for contiguously grouped gemm.
        """
        not_found = linear_idx >= search_state.cur_tile_count
        next_boundary = cutlass.Int32(0)
        cur_group_idx = search_state.cur_group_idx
        cur_offset = search_state.cur_offset
        last_tile_count = search_state.last_tile_count
        cur_boundary = search_state.cur_boundary
        cur_tile_count = search_state.cur_tile_count
        if not_found:
            cur_group_idx = cur_group_idx + 1
        while not_found and cur_group_idx <= group_count:
            next_boundary = cumsum[cur_group_idx]
            num_m_blocks = cute.ceil_div(
                (next_boundary - cur_boundary),
                self.cluster_tile_shape_mnk[search_mode],
            )
            next_tile_count = num_m_blocks + cur_tile_count
            not_found = linear_idx >= next_tile_count

            last_tile_count = cur_tile_count
            cur_offset = cur_boundary
            cur_boundary = next_boundary
            cur_tile_count = next_tile_count
            if not_found:
                cur_group_idx = cur_group_idx + 1
        cur_start = cur_offset + self.cluster_tile_shape_mnk[search_mode] * (
            linear_idx - last_tile_count
        )
        return ContiguousGGSearchState(
            last_tile_count,
            cur_boundary,
            cur_tile_count,
            cur_group_idx,
            cur_offset,
            cur_start,
        )

    def make_work_tile_info(self, sTile_info: cute.Tensor):
        tile_info = cute.make_rmem_tensor(sTile_info.shape, sTile_info.element_type)
        cute.autovec_copy(sTile_info, tile_info)
        return GroupedWorkTileInfo(
            self.group_count, tile_info[0], tile_info[1], tile_info[2], tile_info[3]
        )

    def epilog_gmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tma_atom_c: cute.CopyAtom,
        tiled_copy_t2r: cute.TiledCopy,
        gC_mnl_tma: cute.Tensor,
        gC_mnl_simt: cute.Tensor,
        epi_tile: cute.Tile,
        sC: cute.Tensor,
    ) -> tuple[cute.CopyAtom, cute.Tensor, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """
        Partitions source and destination tensors for a global memory store.

        This method generates a tiled copy for storing results to global memory
        and partitions the source (register or shared memory) and destination
        (global memory) tensors accordingly. The behavior varies based on whether
        TMA store is enabled.

        :param tidx: The thread index in epilogue warp groups.
        :type tidx: cutlass.Int32
        :param tma_atom_c: The TMA copy atom.
        :type tma_atom_c: cute.CopyAtom
        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy.
        :type tiled_copy_t2r: cute.TiledCopy
        :param gC_mnl_tma: The global tensor C for TMA.
        :type gC_mnl_tma: cute.Tensor
        :param gC_mnl_simt: The global tensor C for SIMT Copy.
        :type gC_mnl_simt: cute.Tensor
        :param epi_tile: The epilogue tiler.
        :type epi_tile: cute.Tile
        :param sC: The shared memory tensor C.
        :return: A tuple containing the appropriate copy atom and partitioned
                 source and destination tensors for the store operation.
        :rtype: tuple[cute.CopyAtom, cute.Tensor, cute.Tensor, cute.CopyAtom, cute.Tensor]
        """
        gC_epi_tma = cute.flat_divide(
            gC_mnl_tma[((None, None), 0, 0, None, None, None)], epi_tile
        )
        gC_epi_simt = cute.flat_divide(
            gC_mnl_simt[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # TMA store
        sC_for_tma_partition = cute.group_modes(sC, 0, 2)
        gC_for_tma_partition = cute.group_modes(gC_epi_tma, 0, 2)
        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
        bSG_sC, bSG_gC = cpasync.tma_partition(
            tma_atom_c,
            0,
            cute.make_layout(1),
            sC_for_tma_partition,
            gC_for_tma_partition,
        )
        # SIMT Store
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        tTR_gC = thr_copy_t2r.partition_D(gC_epi_simt)
        simt_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.c_dtype)
        return tma_atom_c, bSG_sC, bSG_gC, simt_atom, tTR_gC

    def epilog_smem_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rC: cute.Tensor,
        tidx: cutlass.Int32,
        sC: cute.Tensor,
    ) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Partitions source and destination tensors for a shared memory store.

        This method generates a tiled copy for storing results to shared memory
        and partitions the source (register) and destination (shared memory)
        tensors accordingly.

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy.
        :param tTR_rC: The partitioned accumulator tensor.
        :param tidx: The thread index in epilogue warp groups.
        :param sC: The shared memory tensor to be copied and partitioned.
        :return: A tuple containing the tiled copy for the store operation and
                 the partitioned source and destination tensors.
        """
        copy_atom_r2s = sm100_utils.get_smem_store_op(
            self.c_layout, self.c_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sC = thr_copy_r2s.partition_D(sC)
        # (R2S, R2S_M, R2S_N)
        tRS_rC = tiled_copy_r2s.retile(tTR_rC)
        return tiled_copy_r2s, tRS_rC, tRS_sC

    def epilog_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        gC_mnl: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """
        Partitions source and destination tensors for a tensor memory load.

        This method generates a tiled copy for loading accumulators from tensor
        memory and partitions the source (tensor memory) and destination
        (register) tensors accordingly.

        :param tidx: The thread index in epilogue warp groups.
        :param tAcc: The accumulator tensor to be copied and partitioned.
        :param gC_mnl: The global tensor C.
        :param epi_tile: The epilogue tiler.
        :param use_2cta_instrs: Whether use_2cta_instrs is enabled.
        :return: A tuple containing the tiled copy for the load operation and
                 the partitioned source and destination tensors.
        """
        # Make tiledCopy for tensor memory load
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.c_layout,
            self.c_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tAcc_epi = cute.flat_divide(
            tAcc[((None, None), 0, 0, None)],
            epi_tile,
        )
        # (EPI_TILE_M, EPI_TILE_N)
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, loopM, loopN, loopL)
        gC_mnl_epi = cute.flat_divide(
            gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, loopM, loopN, loopL)
        tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    @staticmethod
    def align_up(x: int, align: int) -> int:
        """Align x up to the nearest multiple of align."""
        return (x + align - 1) // align * align

    @staticmethod
    def _compute_stages_and_tmem_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler_mnk: tuple[int, int, int],
        cta_tile_shape_mnk: tuple[int, int, int],
        epi_tile: cute.Tile,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        c_layout: utils.LayoutEnum,
        transform_a_source: tcgen05.OperandSource,
        scale_granularity_m: int,
        scale_granularity_k: int,
        smem_buffer_align_bytes: int,
        scale_mode: TransformMode,
    ) -> tuple[int, int, int, int, int, int, int, int]:
        """
        Compute pipeline stages and TMEM column allocation configurations.

        This method calculates the number of pipeline stages for different operations
        (tile_info, load2trans, trans2mma, accumulator, etc.) and determines TMEM column allocation
        based on available memory resources and tile configuration.

        :param tiled_mma: The tiled MMA object defining the core computation.
        :type tiled_mma: cute.TiledMma
        :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
        :type mma_tiler_mnk: tuple[int, int, int]
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param epi_tile: The epilogue tile shape.
        :type epi_tile: cute.Tile
        :param a_dtype: Data type of operand A.
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: Data type of operand B.
        :type b_dtype: type[cutlass.Numeric]
        :param c_dtype: Data type of operand C.
        :type c_dtype: type[cutlass.Numeric]
        :param c_layout: Layout enum of operand C.
        :type c_layout: utils.LayoutEnum
        :param transform_a_source: The source of the transformed A tensor.
        :type transform_a_source: tcgen05.OperandSource
        :param scale_granularity_m: The granularity of the scale tensor along the M mode.
        :type scale_granularity_m: int
        :param scale_granularity_k: The granularity of the scale tensor along the K mode.
        :type scale_granularity_k: int
        :param smem_buffer_align_bytes: The alignment of the shared memory buffer.
        :type smem_buffer_align_bytes: int
        :param scale_mode: The transform mode.
        :type scale_mode: TransformMode

        :return: A tuple containing the number of stages for:
                 (load2trans, scale_load2trans, transform2mma, accumulator, c, tile_info, tmem_acc_cols, tmem_a_cols)
        :rtype: tuple[int, int, int, int, int, int, int]
        - num_load2trans_stage: Stages for load-to-transform A and B tensors pipeline
        - num_scale_load2trans_stage: Stages for scale load-to-transform A tensor pipeline
        - num_trans2mma_stage: Stages for transform-to-MMA pipeline
        - num_acc_stage: Stages for accumulator-to-epilogue pipeline
        - num_c_stage: Stages for epilogue-to-output C pipeline
        - num_tile_info_stage: Stages for buffers storing tile info
        - num_acc_tmem_cols: TMEM columns for accumulator
        - num_a_tmem_cols: TMEM columns for transformed A tensor
        """
        # Compute tmem columns required for accumulator
        acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
        tCtAcc_stage1 = tiled_mma.make_fragment_C(cute.append(acc_shape, 1))
        num_tmem_acc_col_per_stage = utils.get_num_tmem_alloc_cols(tCtAcc_stage1, True)
        # Heuristic to decide the number of stages for accumulator
        sm100_tmem_columns = cute.arch.SM100_TMEM_CAPACITY_COLUMNS
        accumulator_stage_count = sm100_tmem_columns // num_tmem_acc_col_per_stage
        if transform_a_source == tcgen05.OperandSource.TMEM:
            if num_tmem_acc_col_per_stage < 128:
                accumulator_stage_count = 3
            elif num_tmem_acc_col_per_stage < 256:
                accumulator_stage_count = 2
            else:
                accumulator_stage_count = 1
        # transformed A in 16bit, thus 1 tmem column could hold 2 elements
        num_elts_per_tmem_col = 32 // tiled_mma.op.a_dtype.width
        num_tmem_cols_a_per_stage = GroupedMixedInputGemmKernel.align_up(
            (
                cta_tile_shape_mnk[2] // num_elts_per_tmem_col
                if transform_a_source == tcgen05.OperandSource.TMEM
                else 0
            ),
            4,
        )

        bytes_per_pipeline_stage = 16
        # By default, we use 2 stages for tile info
        num_tile_info_stage = 2
        tile_info_bytes = (
            cute.size_in_bytes(cute.Int32, cute.make_layout((4, num_tile_info_stage)))
            + bytes_per_pipeline_stage * num_tile_info_stage
        )

        c_stage_count = 2
        c_smem_layout_staged_one = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            1,
        )
        c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_staged_one)
        c_bytes = c_bytes_per_stage * c_stage_count

        smem_capacity = utils.get_smem_capacity_in_bytes("sm_100")
        if scale_mode == TransformMode.ConvertOnly:
            scale_load2trans_stage_count = 0
            a_scale_bytes_per_stage = 0
        else:
            # Ensure we have 4 buffers for scale tiles needed for 1 CTA tile
            a_scale_k_mode = max(cta_tile_shape_mnk[2] // scale_granularity_k, 1)
            a_scale_m_mode = max(cta_tile_shape_mnk[0] // scale_granularity_m, 1)
            scale_load2trans_stage_count = 4
            a_scale_bytes_per_stage = GroupedMixedInputGemmKernel.align_up(
                cute.size_in_bytes(
                    tiled_mma.op.a_dtype,
                    cute.make_layout((a_scale_m_mode, a_scale_k_mode)),
                ),
                smem_buffer_align_bytes,
            )
        a_scale_bytes = (
            a_scale_bytes_per_stage + bytes_per_pipeline_stage
        ) * scale_load2trans_stage_count
        caveout_smem_bytes = (
            bytes_per_pipeline_stage * accumulator_stage_count
            + a_scale_bytes
            + c_bytes
            + tile_info_bytes
        )

        # Compute transform stages if A is in TMEM
        num_tmem_acc_cols = GroupedMixedInputGemmKernel.align_up(
            accumulator_stage_count * num_tmem_acc_col_per_stage, 4
        )

        transform2mma_stage_count_a_source_tmem_potential = (
            (sm100_tmem_columns - num_tmem_acc_cols) // num_tmem_cols_a_per_stage
            if transform_a_source == tcgen05.OperandSource.TMEM
            else -1
        )
        if (
            transform_a_source == tcgen05.OperandSource.TMEM
            and transform2mma_stage_count_a_source_tmem_potential <= 0
        ):
            raise ValueError("Not enough TMEM capacity for selected tile size")
        a_load_bytes_per_stage = GroupedMixedInputGemmKernel.align_up(
            cute.size_in_bytes(
                a_dtype,
                cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
            ),
            smem_buffer_align_bytes,
        )
        b_load_bytes_per_stage = GroupedMixedInputGemmKernel.align_up(
            cute.size_in_bytes(
                b_dtype,
                cute.make_layout(
                    (
                        cta_tile_shape_mnk[1] // cute.size(tiled_mma.thr_id),
                        cta_tile_shape_mnk[2],
                    )
                ),
            ),
            smem_buffer_align_bytes,
        )
        ab_load_bytes_per_stage = (
            a_load_bytes_per_stage
            + b_load_bytes_per_stage
            + 2 * bytes_per_pipeline_stage
        )
        a_transform_bytes_per_stage = (
            GroupedMixedInputGemmKernel.align_up(
                cute.size_in_bytes(
                    tiled_mma.op.a_dtype,
                    cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
                ),
                smem_buffer_align_bytes,
            )
            if transform_a_source == tcgen05.OperandSource.SMEM
            else 0
        )

        a_transform_bytes_per_stage = (
            a_transform_bytes_per_stage + bytes_per_pipeline_stage
        )
        transform2mma_stage_count_a_source_smem_potential = (
            smem_capacity - caveout_smem_bytes
        ) // (ab_load_bytes_per_stage + a_transform_bytes_per_stage)
        transform2mma_stage_count = (
            min(
                transform2mma_stage_count_a_source_tmem_potential,
                transform2mma_stage_count_a_source_smem_potential,
            )
            if transform_a_source == tcgen05.OperandSource.TMEM
            else transform2mma_stage_count_a_source_smem_potential
        )
        load2transform_stage_count = (
            smem_capacity
            - caveout_smem_bytes
            - (transform2mma_stage_count * a_transform_bytes_per_stage)
        ) // ab_load_bytes_per_stage
        if (
            load2transform_stage_count < 2
            or transform2mma_stage_count < 2
            or accumulator_stage_count < 1
        ):
            raise ValueError("Not enough SMEM or TMEM capacity for selected tile size")
        num_tmem_a_cols = transform2mma_stage_count * num_tmem_cols_a_per_stage
        # Check if we can increase c_stage_count with leftover smem
        c_stage_count += (
            smem_capacity
            - load2transform_stage_count * ab_load_bytes_per_stage
            - transform2mma_stage_count * a_transform_bytes_per_stage
            - scale_load2trans_stage_count * a_scale_bytes_per_stage
            - c_bytes
        ) // c_bytes_per_stage

        return (
            load2transform_stage_count,
            scale_load2trans_stage_count,
            transform2mma_stage_count,
            accumulator_stage_count,
            c_stage_count,
            num_tile_info_stage,
            num_tmem_acc_cols,
            num_tmem_a_cols,
        )

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[utils.PersistentTileSchedulerParams, tuple[int, int, int]]:
        """
        Use persistent tile scheduler to compute the grid size for the output tensor C.
        """
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = (cluster_shape_mn[0], cluster_shape_mn[1], max_active_clusters)

        return tile_sched_params, grid

    def is_valid_tensor_alignment(
        m: int,
        n: int,
        k: int,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        scale_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        mma_tiler_mnk: tuple[int, int, int],
        use_2cta_instrs: bool,
        cluster_shape_mn: tuple[int, int],
        scale_granularity_m: int,
        scale_granularity_k: int,
    ) -> bool:
        """
        Check if the tensor alignments are valid for the given problem size and data types.
        """

        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        if not (
            check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k))
            and check_contiguous_16B_alignment(b_dtype, b_major == "n", (n, k))
            and check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n))
            and (
                scale_granularity_k == 0
                or check_contiguous_16B_alignment(
                    b_dtype, True, (m, k // scale_granularity_k)
                )
            )
        ):
            return False
        # Check if scale tensor matches the TMA load 128B alignment requirement
        cta_tile_shape_mnk = (
            mma_tiler_mnk[0] // (2 if use_2cta_instrs else 1),
            mma_tiler_mnk[1],
            mma_tiler_mnk[2],
        )
        if (
            scale_granularity_m > 0
            and (cta_tile_shape_mnk[0] // cluster_shape_mn[1] // scale_granularity_m)
            * (scale_dtype.width // 8)
            < 128
        ):
            return False

        return True

    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
    ) -> bool:
        """
        Check if the MMA tiler and cluster shape are valid for the given problem size.
        """
        if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
            return False

        if (mma_tiler[0] // (2 if use_2cta_instrs else 1)) not in [64, 128]:
            return False
        return True

    def can_implement(
        mnkl: tuple[int, int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        scale_granularity_m: int,
        scale_granularity_k: int,
        mma_tiler: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
    ) -> bool:
        """
        Check if the kernel can be implemented for the given tensor shapes and data types.
        """
        m, n, k, l = mnkl

        if not GroupedMixedInputGemmKernel.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler, cluster_shape_mn, use_2cta_instrs
        ):
            return False
        if not mixed_input_utils.is_valid_scale_granularity(
            scale_granularity_m, scale_granularity_k, a_dtype, k, mma_tiler[2]
        ):
            return False
        if not GroupedMixedInputGemmKernel.is_valid_tensor_alignment(
            m,
            n,
            k,
            a_dtype,
            b_dtype,
            c_dtype,
            b_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler,
            use_2cta_instrs,
            cluster_shape_mn,
            scale_granularity_m,
            scale_granularity_k,
        ):
            return False
        return True


def create_cumsum_tensor(
    num_groups: int,
    fused_n: int,
    alignment: int,
    uniform_distribution: bool = False,
) -> tuple[cute.Tensor, torch.Tensor]:
    """
    Create a tensor of shape (num_groups + 1) recording the cumulative sum of the elements in each group.
    """
    assert fused_n % alignment == 0, "fused_n must be divisible by alignment"
    if uniform_distribution:
        # keep a uniform distribution for debug and performance collection
        group_counts = torch.tensor([fused_n // num_groups] * num_groups)
    else:
        # sample group sizes with equal probability for each group
        probs = torch.ones(num_groups) / num_groups
        group_sizes = torch.multinomial(probs, fused_n // alignment, replacement=True)
        group_counts = torch.bincount(group_sizes, minlength=num_groups) * alignment
    print(group_counts.tolist())

    # Create cumulative sum
    cumsum_torch = torch.cat([torch.tensor([0]), group_counts.cumsum(0)])
    print(cumsum_torch.tolist())

    cumsum_tensor, _ = cutlass_torch.cute_tensor_like(
        cumsum_torch, cutlass.Int32, is_dynamic_layout=False
    )

    return cumsum_tensor, cumsum_torch.to("cpu")


def create_i4_tensor_and_scale(
    l: int,
    m: int,
    k: int,
    is_m_major: bool,
    dtype: type[cutlass.Numeric],
    scale_granularity_m: int,
    scale_granularity_k: int,
    is_dynamic_layout: bool = True,
    init_config: tuple = (
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-7, max_val=6),
    ),
    divisibility: int = 16,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[
    cute.Tensor,
    torch.Tensor,
    torch.Tensor,
    cute.Tensor,
    torch.Tensor,
    torch.Tensor,
]:
    """
    Create quantized 4-bit tensor and corresponding scale tensor.
    """
    lb_4b = -8 if dtype == cutlass.Int4 else 0
    up_4b = 7 if dtype == cutlass.Int4 else 15
    if not (
        init_config[0] == cutlass_torch.TensorInitType.RANDOM
        or init_config[0] == cutlass_torch.TensorInitType.SCALAR
    ):
        raise ValueError(
            "Only random and scalar initialization is supported for 4bit data type"
        )

    # Construct reference tensor in f32
    ref_fp32 = cutlass_torch.matrix(l, m, k, is_m_major, cutlass.Float32, *init_config)
    # Generate scale data and perform quantization
    num_scales = k // scale_granularity_k
    ref = ref_fp32.to(dtype=cutlass_torch.dtype(transformed_dtype)).reshape(
        m, num_scales, scale_granularity_k, l
    )
    # Get elements with maximum absolute value to compute scaling factors
    a_max = (
        torch.maximum(ref / up_4b, ref / lb_4b)
        if dtype == cutlass.Int4
        else torch.maximum(ref / up_4b)
    )
    a_scales, _ = torch.max(a_max, dim=2, keepdim=True)
    a_scale_inv = torch.where(a_scales == 0, 0, 1 / a_scales)
    a_quant = ref * a_scale_inv
    # Convert values to integer to avoid computation errors
    a_quant = a_quant.to(dtype=torch.int32).reshape((m, k, l)).to(dtype=torch.float32)
    # Construct cute scale tensor
    a_scales = a_scales.random_(-3, 3).reshape((m, num_scales, l))
    # Scale tensor is always m-major
    a_scales = a_scales.permute(2, 1, 0).contiguous().permute(2, 1, 0).to(device="cuda")
    # Construct A quantized tensor
    cute_a_quant_tensor, torch_a_quant_tensor = cutlass_torch.cute_tensor_like(
        a_quant,
        dtype,
        is_dynamic_layout=is_dynamic_layout,
        assumed_align=divisibility,
    )
    cute_scale_tensor = from_dlpack(a_scales, assumed_align=divisibility)
    for i, stride in enumerate(a_scales.stride()):
        if stride == 1:
            leading_dim = i
            break
    if is_dynamic_layout:
        cute_scale_tensor = cute_scale_tensor.mark_layout_dynamic(
            leading_dim=leading_dim
        )

    return (
        cute_a_quant_tensor,
        torch_a_quant_tensor,
        a_quant.to("cpu"),
        cute_scale_tensor,
        a_scales,
        a_scales.to("cpu"),
    )


def create_tensor_a(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: type[cutlass.Numeric],
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[cute.Tensor, Optional[cute.Tensor], torch.Tensor, Optional[torch.Tensor]]:
    """
    Create tensor A and scale tensor.
    """
    a_scale_tensor = None
    a_scale_torch_cpu = None
    if a_dtype in (cutlass.Int4,):
        (
            a_tensor,
            a_torch_gpu,
            a_torch_cpu,
            a_scale_tensor,
            a_scale_torch_gpu,
            a_scale_torch_cpu,
        ) = create_i4_tensor_and_scale(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
            scale_granularity_m,
            scale_granularity_k,
            divisibility=mixed_input_utils.get_divisibility(m if a_major == "m" else k),
            transformed_dtype=transformed_dtype,
        )
    else:
        a_torch_cpu = cutlass_torch.matrix(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
        )
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu,
            a_dtype,
            is_dynamic_layout=True,
            assumed_align=mixed_input_utils.get_divisibility(
                m if a_major == "m" else k
            ),
        )
    return a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu


def create_tensors(
    l: int,
    m: int,
    n: int,
    k: int,
    a_major: str,
    b_major: str,
    c_major: str,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    uniform_group_sizes: bool = False,
) -> tuple:
    """
    Create all input and output tensors for the mixed-input GEMM.
    """
    torch.manual_seed(2025)

    a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
        l,
        m,
        k,
        a_major,
        a_dtype,
        scale_granularity_m,
        scale_granularity_k,
        b_dtype,
    )

    # In GROUP mode, l specifies the number of groups. We'll fuse group into the n mode for tensor B and C.
    # Batch mode will be set to 1.
    num_groups = l
    fused_n = n * num_groups
    b_torch_cpu = cutlass_torch.matrix(
        1,  # batch=1
        fused_n,
        k,
        b_major == "n",
        b_dtype,
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-10, max_val=10),
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu,
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(n if b_major == "n" else k),
    )

    c_torch_cpu = cutlass_torch.matrix(
        1,  # batch=1
        m,
        fused_n,
        c_major == "m",
        c_dtype,
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )
    c_tensor = c_tensor.mark_compact_shape_dynamic(
        mode=(0 if c_major == "m" else 1),
        stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
        divisibility=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )
    # We need to ensure mode N satisfies 16B alignment for each group
    alignment_n = 16 * 8 // b_dtype.width
    cumsum_tensor, cumsum_torch = create_cumsum_tensor(
        num_groups, fused_n, alignment_n, uniform_distribution=uniform_group_sizes
    )

    return (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        cumsum_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        cumsum_torch,
        c_torch_gpu,
    )


def compare(
    a_torch_cpu: torch.Tensor,
    b_torch_cpu: torch.Tensor,
    a_scale_torch_cpu: Optional[torch.Tensor],
    cumsum_torch_cpu: torch.Tensor,
    c_torch_gpu: torch.Tensor,
    c_dtype: type[cutlass.Numeric],
    tolerance: float,
) -> None:
    """
    Compare kernel result with reference computation.
    """
    kernel_result = c_torch_gpu.cpu()
    assert kernel_result.shape[2] == 1, "batch mode must be 1"
    kernel_result = kernel_result.reshape(
        kernel_result.shape[0], kernel_result.shape[1]
    )
    # Compute reference result
    a_for_gemm = a_torch_cpu
    if a_scale_torch_cpu is not None:
        scale_shape = a_scale_torch_cpu.shape
        a_shape = a_torch_cpu.shape
        a_scale_torch_cpu = a_scale_torch_cpu.to(dtype=torch.float32).reshape(
            scale_shape[0], scale_shape[1], 1, scale_shape[2]
        )
        a_torch_cpu = a_torch_cpu.to(dtype=torch.float32).reshape(
            a_torch_cpu.shape[0], scale_shape[1], -1, a_torch_cpu.shape[2]
        )
        a_for_gemm = (a_torch_cpu * a_scale_torch_cpu).reshape(a_shape)
    # A in (m, k, l), b in (n, k), c in (m, n)
    assert cumsum_torch_cpu.shape[0] == a_for_gemm.shape[-1] + 1, (
        "cumsum tensor must have one more element than a_for_gemm"
    )
    assert b_torch_cpu.shape[2] == 1, (
        "b_torch_cpu must have a singleton dimension in the last position"
    )
    prev_idx = 0
    ref = torch.zeros((a_for_gemm.shape[0], b_torch_cpu.shape[0]), dtype=torch.float32)
    for group_idx in range(1, cumsum_torch_cpu.shape[0]):
        # No computation for current group
        if cumsum_torch_cpu[group_idx] == prev_idx:
            continue
        # Get A slice for current group
        sliced_a = a_for_gemm[:, :, group_idx - 1]
        # Get B slice for current group
        sliced_b = b_torch_cpu[prev_idx : cumsum_torch_cpu[group_idx], :, 0]
        sliced_ref = torch.einsum(
            "mk,nk->mn",
            sliced_a.to(dtype=torch.float32),
            sliced_b.to(dtype=torch.float32),
        )
        ref[:, prev_idx : cumsum_torch_cpu[group_idx]] = sliced_ref
        prev_idx = cumsum_torch_cpu[group_idx]
    # Convert ref to c_dtype
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Assert close results
    torch.testing.assert_close(kernel_result, ref_result, atol=tolerance, rtol=1e-05)


def get_advanced_compiler_control_path():
    """
    Return the path to the advanced compiler control file of this example. If not found, return None.
    """
    import os

    need_advanced_compiler_control = False
    try:
        from cutlass import CUDA_VERSION

        if CUDA_VERSION.major == 13 and CUDA_VERSION.minor == 1:
            need_advanced_compiler_control = True
    except ImportError:
        pass

    if not need_advanced_compiler_control:
        return None
    # Get the path to the advanced compiler control file
    current_dir = os.path.dirname(os.path.abspath(__file__))
    target_path = os.path.join(current_dir, "../advanced_compiler_control/gemm0.bin")
    if os.path.exists(target_path):
        print(f"Found advanced compiler control file at {target_path}")
        return target_path
    else:
        return None


def run(
    mnkl: tuple[int, int, int, int],
    scale_granularity_m: int,
    scale_granularity_k: int,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mnk: tuple[int, int, int],
    cluster_shape_mn: tuple[int, int],
    use_2cta_instrs: bool,
    tolerance: float,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    uniform_group_sizes: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
) -> None:
    """
    Run the mixed-input GEMM kernel with specified parameters.

    This function creates tensors, validates parameters, executes the kernel,
    optionally compares results with a reference implementation and reports
    kernel execution time.
    """
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise ValueError("CUDA is not available")

    # Check if given configuration is supported
    if not GroupedMixedInputGemmKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        scale_granularity_m,
        scale_granularity_k,
        mma_tiler_mnk,
        cluster_shape_mn,
        use_2cta_instrs,
    ):
        raise ValueError("GEMM configuration not supported")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    group_count = l
    mixed_input_gemm = GroupedMixedInputGemmKernel(
        scale_granularity_m,
        scale_granularity_k,
        acc_dtype,
        use_2cta_instrs,
        mma_tiler_mnk,
        cluster_shape_mn,
        group_count,
    )
    (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        cumsum_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        cumsum_torch_cpu,
        c_torch_gpu,
    ) = create_tensors(
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        c_major,
        a_dtype,
        b_dtype,
        c_dtype,
        scale_granularity_m,
        scale_granularity_k,
        uniform_group_sizes,
    )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1],
    )
    advanced_compiler_options = None
    advanced_compiler_control_path = get_advanced_compiler_control_path()
    if advanced_compiler_control_path:
        advanced_compiler_options = (
            f"--ptxas-options '--apply-controls={advanced_compiler_control_path}'"
        )
    compiled_kernel = cute.compile(
        mixed_input_gemm,
        a_tensor,
        a_scale_tensor,
        b_tensor,
        cumsum_tensor,
        c_tensor,
        max_active_clusters,
        current_stream,
        options=advanced_compiler_options,
    )

    if not skip_ref_check:
        compiled_kernel(
            a_tensor,
            a_scale_tensor,
            b_tensor,
            cumsum_tensor,
            c_tensor,
            current_stream,
        )
        compare(
            a_torch_cpu,
            b_torch_cpu,
            a_scale_torch_cpu,
            cumsum_torch_cpu,
            c_torch_gpu,
            c_dtype,
            tolerance,
        )

    # Early return if no performance measurement is needed
    if iterations <= 0:
        return

    def generate_tensors():
        a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
            l,
            m,
            k,
            a_major,
            a_dtype,
            scale_granularity_m,
            scale_granularity_k,
            b_dtype,
        )
        num_groups = l
        fused_n = n * num_groups
        b_torch_cpu = cutlass_torch.matrix(
            1,
            fused_n,
            k,
            b_major == "n",
            b_dtype,
            cutlass_torch.TensorInitType.RANDOM,
            cutlass_torch.RandomInitConfig(min_val=-10, max_val=10),
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu,
            b_dtype,
            is_dynamic_layout=True,
            assumed_align=mixed_input_utils.get_divisibility(
                n if b_major == "n" else k
            ),
        )
        c_torch_cpu = cutlass_torch.matrix(1, m, fused_n, c_major == "m", c_dtype)
        c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
            c_torch_cpu,
            c_dtype,
            is_dynamic_layout=True,
            assumed_align=mixed_input_utils.get_divisibility(
                m if c_major == "m" else n
            ),
        )
        c_tensor = c_tensor.mark_compact_shape_dynamic(
            mode=(0 if c_major == "m" else 1),
            stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
            divisibility=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
        )
        alignment_n = 16 * 8 // b_dtype.width
        cumsum_tensor, cumsum_torch_cpu = create_cumsum_tensor(
            num_groups, fused_n, alignment_n, uniform_distribution=uniform_group_sizes
        )
        return testing.JitArguments(
            a_tensor, a_scale_tensor, b_tensor, cumsum_tensor, c_tensor, current_stream
        )

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_gpu.numel() * c_torch_gpu.element_size()
            + a_scale_torch_cpu.numel() * a_scale_torch_cpu.element_size()
            if a_scale_torch_cpu is not None
            else 0
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mnkl", type=parse_comma_separated_ints, default=(128, 128, 128, 1)
    )
    parser.add_argument(
        "--mma_tiler_mnk", type=parse_comma_separated_ints, default=(128, 128, 128)
    )
    parser.add_argument(
        "--cluster_shape_mn", type=parse_comma_separated_ints, default=(1, 1)
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions feature",
    )
    parser.add_argument(
        "--a_dtype",
        type=cutlass.dtype,
        default=cutlass.Int4,
        choices=[cutlass.Int8, cutlass.Uint8, cutlass.Int4],
    )
    parser.add_argument(
        "--b_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        choices=[cutlass.BFloat16, cutlass.Float16],
    )
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="m")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--scale_granularity_m",
        type=int,
        default=1,
        help="Scale granularity along M dimension.",
    )
    parser.add_argument(
        "--scale_granularity_k",
        type=int,
        default=128,
        help="Scale granularity along K dimension.",
    )
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
        "--uniform_group_sizes", action="store_true", help="Use uniform group sizes"
    )
    args = parser.parse_args()
    run(
        args.mnkl,
        args.scale_granularity_m,
        args.scale_granularity_k,
        args.a_dtype,
        args.b_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler_mnk,
        args.cluster_shape_mn,
        args.use_2cta_instrs,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.uniform_group_sizes,
    )
    print("PASS")
