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

import argparse
import functools
import os
import sys
from typing import Tuple, Type, Union, List, Literal

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.nvgpu.tcgen05.mma import CollectorOp
from cutlass.cute.runtime import from_dlpack
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.rubin_helpers as sm107_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from rubin.kernel.blockscaled_grouped_gemm.grouped_blockscaled_gemm import (
    Sm107GroupedBlockScaledGemmKernel,
    create_tensors_abc_for_all_groups,
    create_tensors_sfasfb_for_all_groups,
    create_tensor_and_stride,
)


"""
This example provides an experimental implementation of the SM107 grouped blockscaled GEMM kernel
with mixed cluster launches, please note that the APIs and implementation details related to this
kernel may change in future releases.

The primary goal of this example, compared to the one in grouped_blockscaled_gemm.py,
is around the usage of mixed cluster launches: If there are not enough resources to schedule a
cluster with preferred_cluster_shape_mn, then a fallback_cluster_shape_mn is used.

A grouped blockscaled GEMM example for the NVIDIA Rubin SM107 architecture using CUTE DSL.

This example demonstrates an implementation of grouped blockscaled GEMM using a TMA plus
Rubin SM107 TensorCore warp-specialized persistent kernel.
The grouped GEMM workload computes a batch of GEMM operations with distinct problem sizes.
Pointers to matrices in global memory are passed to the kernel in an array (also held in global memory).
This array of tensor maps are then loaded from global memory into shared memory, and updated on shared memory,
i.e., using cutlass.tensor_utils.TensorMapUpdateMode.SMEM in this example.
Similarly, problem shapes and strides are also stored in arrays in GMEM.

This differs from "Batched Array" GEMM since the size of each GEMM problem in the grouped GEMM concept may be distinct.

To run this example:

.. code-block:: bash

    python examples/cute/rubin/kernel/blockscaled_grouped_gemm/grouped_blockscaled_gemm_mixed_clusters.py                              \\
      --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN --sf_dtype Float8E8M0FNU --sf_vec_size 16      \\
      --c_dtype Float16                                                                            \\
      --mma_tiler 256,128,256 --mma_inst_shape 128,128,128                                         \\
      --preferred_cluster_shape_mn 4,2 --fallback_cluster_shape_mn 2,1                             \\
      --problem_sizes_mnkl "(8192,1280,256,1),(256,384,1536,1),(640,1280,256,1),(640,256,256,1)"    \\
      --num_groups 4

Constraints:
* Supported input data types: nvf4/mxf8(f8e4m3fn/f8e5m2)
  see detailed valid dtype combinations in below Sm107GroupedBlockScaledGemmMixedClustersKernel class documentation
* Mma tiler M must be 128, 256 or 512
* Mma tiler N must be 64, 128, 192 or 256
* Mma tiler K must be 128 for FP8/FP8 or mixed FP8/FP4 inputs, and 256 for FP4/FP4 inputs
* Mma instruction shape M must be 128 (.1CTA), or 256 (.2CTA)
* Mma instruction shape N must be the same as Mma tiler N
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M/N must be <= 4 for scale factor multicasts due to limited size of scale factors
* Cluster shape M must be multiple of 2 if Mma tiler M is 256(use_2cta_instrs)
* The l mode(aka, batch size) for each group must be 1.
* The majorness for A, B and C must be the same across all groups.
* The contiguous dimension of A/B/C tensors in each group must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 16 and 32 for Float8 and Float4, respectively.
"""


def ceil_div(a, b):
    return (a + b - 1) // b


class Sm107GroupedBlockScaledGemmMixedClustersKernel(Sm107GroupedBlockScaledGemmKernel):
    """Grouped block scaled GEMM kernel with mixed cluster support for Rubin.
    This class implements grouped matrix multiplication with support for mixed cluster launches:
    if there are not enough resources to schedule a cluster with preferred_cluster_shape_mn,
    then a fallback_cluster_shape_mn is used.

    :param sf_vec_size: Scalefactor vector size.
    :type sf_vec_size: int
    :param mma_inst_shape: Shape of the Matrix Multiply-Accumulate (MMA) instruction (M,N,K)
    :type mma_inst_shape: Tuple[int, int, int]
    :param mma_tiler: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N,K)
    :type mma_tiler: Tuple[int, int, int]
    :param preferred_cluster_shape_mn: Preferred cluster dimensions (M,N) for parallel processing
    :type preferred_cluster_shape_mn: Tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster dimensions (M,N) when preferred is unavailable
    :type fallback_cluster_shape_mn: Tuple[int, int]

    :note: Supported combinations of A/B data types, SF data types and SF vector size:
        - Float4E2M1FN/Float4E2M1FN + Float8E8M0FNU + 16/32
        - Float4E2M1FN/Float4E2M1FN + Float8E4M3FN + 16/32
        - Float4E2M1FN/Float4E2M1FN + FloatNV8E5M3FNU + 16/32
        - Float8E4M3FN/Float8E5M2 in all four pairs + Float8E8M0FNU + 32
        - Float4E2M1FN mixed with Float8E4M3FN/Float8E5M2 in as A,B or B,A types + Float8E8M0FNU + 32

    :note: Supported accumulator data types:
        - Float32

    :note: Supported C data types:
        - Float32
        - Float16/BFloat16
        - Float8E4M3FN/Float8E5M2
        - Float4E2M1FN

    :note: Constraints:
        - MMA tiler M must be 128, 256, or 512
        - MMA instruction shape M must be 128 (.1CTA) or 256 (.2CTA)
        - MMA tiler N (and MMA instruction shape N) must be 128, or 256
        - B-reuse feature is enabled if (MMA tiler M / MMA instruction shape M == 2)
        - Cluster shape M must be multiple of 2 if Mma tiler M is 256
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Cluster shape M/N must be <= 4 for scale factor multicasts due to limited size of scale factors
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_inst_shape: Tuple[int, int, int],
        mma_tiler: Tuple[int, int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
    ):
        super().__init__(
            sf_vec_size,
            mma_inst_shape,
            mma_tiler,
            preferred_cluster_shape_mn,
        )

        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs.

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout for both preferred and fallback clusters
        - Computing multicast CTAs for A/B/SFA/SFB
        - Computing epilogue subtile
        - Setting up A/B/SFA/SFB/C stage counts in shared memory
        - Computing A/B/SFA/SFB/C shared memory layout
        """
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

        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        self.mma_tiler_sfb = (
            self.mma_inst_shape_sfb[0],
            self.mma_inst_shape_sfb[1],
            self.mma_tiler[2],
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        self.cluster_tile_shape_mnk = tuple(
            x * y
            for x, y in zip(
                self.cta_tile_shape_mnk, (*self.preferred_cluster_shape_mn, 1)
            )
        )

        # Compute cluster layout for preferred cluster
        self.preferred_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.preferred_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )

        # Compute cluster layout for fallback cluster
        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.fallback_cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        self.fallback_cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.fallback_cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )

        # Compute number of multicast CTAs for A/B (preferred)
        self.num_preferred_mcast_ctas_a = cute.size(
            self.preferred_cluster_layout_vmnk.shape[2]
        )
        self.num_preferred_mcast_ctas_b = cute.size(
            self.preferred_cluster_layout_vmnk.shape[1]
        )
        self.is_preferred_a_mcast = self.num_preferred_mcast_ctas_a > 1
        self.is_preferred_b_mcast = self.num_preferred_mcast_ctas_b > 1

        # Compute number of multicast CTAs for A/B (fallback)
        self.num_fallback_mcast_ctas_a = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_fallback_mcast_ctas_b = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_fallback_a_mcast = self.num_fallback_mcast_ctas_a > 1
        self.is_fallback_b_mcast = self.num_fallback_mcast_ctas_b > 1

        # Compute epilogue subtile
        self.epi_tile = sm107_utils.compute_epilogue_tile_shape(
            tiled_mma.op,
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.c_layout,
            self.c_dtype,
        )

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = self._compute_stages(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.epi_tile,
            self.c_dtype,
            self.c_layout,
            self.sf_dtype,
            self.sf_vec_size,
            self.smem_capacity,
            self.occupancy,
        )

        # Compute A/B/SFA/SFB/C shared memory layout
        self.a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.num_ab_stage,
        )
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            self.mma_tiler,
            self.b_dtype,
            self.num_ab_stage,
        )
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.num_ab_stage,
        )
        self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.c_dtype,
            self.c_layout,
            self.epi_tile,
            self.num_c_stage,
        )

        mbar_smem_bytes = self._get_mbar_smem_bytes(
            num_acc_stage=self.num_acc_stage,
            num_ab_stage=self.num_ab_stage,
            num_c_stage=self.num_c_stage,
        )

        tensormap_smem_bytes = (
            Sm107GroupedBlockScaledGemmKernel.bytes_per_tensormap
            * Sm107GroupedBlockScaledGemmKernel.num_tensormaps
        )
        if (
            mbar_smem_bytes
            + tensormap_smem_bytes
            + Sm107GroupedBlockScaledGemmKernel.tensor_memory_management_bytes
            > self.reserved_smem_bytes
        ):
            raise ValueError(
                f"smem consumption for mbar and tensormap {mbar_smem_bytes + tensormap_smem_bytes} exceeds the "
                f"reserved smem bytes {self.reserved_smem_bytes}"
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
        preferred_max_active_clusters: cutlass.Constexpr,
        fallback_max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        """Execute the grouped GEMM operation with mixed cluster support.

        :param initial_a: Initial tensor A, used for data type and majorness information.
        :type initial_a: cute.Tensor
        :param initial_b: Initial tensor B, used for data type and majorness information.
        :type initial_b: cute.Tensor
        :param initial_c: Initial tensor C, used for data type and majorness information.
        :type initial_c: cute.Tensor
        :param initial_sfa: Initial tensor SFA, used for data type and majorness information.
        :type initial_sfa: cute.Tensor
        :param initial_sfb: Initial tensor SFB, used for data type and majorness information.
        :type initial_sfb: cute.Tensor
        :param group_count: The number of GEMM groups.
        :type group_count: cutlass.Constexpr[int]
        :param problem_shape_mnkl: Tensor containing the (M, N, K, L) shape for each group.
        :type problem_shape_mnkl: cute.Tensor
        :param strides_abc: Tensor containing the strides for A, B, and C for each group.
        :type strides_abc: cute.Tensor
        :param tensor_address_abc: Tensor containing the base addresses for A, B, and C.
        :type tensor_address_abc: cute.Tensor
        :param tensor_address_sfasfb: Tensor containing the base addresses for SFA and SFB.
        :type tensor_address_sfasfb: cute.Tensor
        :param total_num_clusters: Total number of clusters needed for all groups.
        :type total_num_clusters: cutlass.Constexpr[int]
        :param tensormap_cute_tensor: Tensor for storing tensormaps.
        :type tensormap_cute_tensor: cute.Tensor
        :param preferred_max_active_clusters: Maximum number of preferred active clusters.
        :type preferred_max_active_clusters: cutlass.Constexpr
        :param fallback_max_active_clusters: Maximum number of fallback active clusters.
        :type fallback_max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream for asynchronous execution.
        :type stream: cuda.CUstream
        """
        self.a_dtype = initial_a.element_type
        self.b_dtype = initial_b.element_type
        self.sf_dtype = initial_sfa.element_type
        self.c_dtype = initial_c.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            initial_b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(initial_c)

        # Setup attributes that dependent on gemm inputs
        self._setup_attributes()

        # Setup sfa/sfb tensor by filling A/B tensor to scale factor atom layout
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_a.shape, self.sf_vec_size
        )
        initial_sfa = cute.make_tensor(initial_sfa.iterator, sfa_layout)

        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            initial_b.shape, self.sf_vec_size
        )
        initial_sfb = cute.make_tensor(initial_sfb.iterator, sfb_layout)

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

        tiled_mma_sfb = sm107_utils.make_blockscaled_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.sf_dtype,
            self.sf_vec_size,
            cute.nvgpu.tcgen05.CtaGroup.ONE,
            self.mma_inst_shape_sfb,
            a_collector_op=CollectorOp.DISCARD,
            b_collector_op=CollectorOp.DISCARD,
        )

        tiled_mma_sfb.set(tcgen05.Field.NEGATE_A, False)
        tiled_mma_sfb.set(tcgen05.Field.NEGATE_B, False)

        tiled_mma_bkeep = None
        tiled_mma_breuse = None
        if cutlass.const_expr(self.enable_breuse):
            tiled_mma_bkeep = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                self.a_major_mode,
                self.b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.FILL,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )
            tiled_mma_bkeep.set(tcgen05.Field.NEGATE_A, False)
            tiled_mma_bkeep.set(tcgen05.Field.NEGATE_B, False)

            tiled_mma_breuse = sm107_utils.make_blockscaled_trivial_tiled_mma(
                self.a_dtype,
                self.b_dtype,
                self.a_major_mode,
                self.b_major_mode,
                self.sf_dtype,
                self.sf_vec_size,
                self.cta_group,
                self.mma_inst_shape,
                a_collector_op=CollectorOp.DISCARD,
                b_collector_op=CollectorOp.LASTUSE,
                atom_layout_mnk=atom_layout_mnk,
                permutation_mnk=permutation_mnk,
            )

            tiled_mma_breuse.set(tcgen05.Field.NEGATE_A, False)
            tiled_mma_breuse.set(tcgen05.Field.NEGATE_B, False)

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # Setup TMA load for A (preferred)
        a_smem_layout = cute.select(
            self.a_smem_layout_staged,
            mode=list(range(cute.rank(self.a_smem_layout_staged) - 1)),
        )
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )
        # Setup TMA load for A (fallback)
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.fallback_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_a,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for B (preferred)
        b_smem_layout = cute.select(
            self.b_smem_layout_staged,
            mode=list(range(cute.rank(self.b_smem_layout_staged) - 1)),
        )
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_B(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
        )
        # Setup TMA load for B (fallback)
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_B(
                self.fallback_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_b,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
        )

        # Setup TMA load for SFA (preferred)
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.make_tiled_tma_atom_A(
            sm100_utils.cluster_shape_to_tma_atom_A(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_sfa,
            sfa_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=cutlass.Int16,
        )
        # Setup TMA load for SFA (fallback)
        tma_atom_sfa_fallback, tma_tensor_sfa_fallback = (
            cute.nvgpu.make_tiled_tma_atom_A(
                sm100_utils.cluster_shape_to_tma_atom_A(
                    self.fallback_cluster_shape_mn, tiled_mma.thr_id
                ),
                initial_sfa,
                sfa_smem_layout,
                self.mma_tiler,
                tiled_mma,
                self.fallback_cluster_layout_vmnk.shape,
                internal_type=cutlass.Int16,
            )
        )

        # Setup TMA load for SFB (preferred)
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sm100_utils.cluster_shape_to_tma_atom_SFB(
                self.preferred_cluster_shape_mn, tiled_mma.thr_id
            ),
            initial_sfb,
            sfb_smem_layout,
            self.mma_tiler_sfb,
            tiled_mma_sfb,
            self.preferred_cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Int16,
        )
        # Setup TMA load for SFB (fallback)
        tma_atom_sfb_fallback, tma_tensor_sfb_fallback = (
            cute.nvgpu.make_tiled_tma_atom_B(
                sm100_utils.cluster_shape_to_tma_atom_SFB(
                    self.fallback_cluster_shape_mn, tiled_mma.thr_id
                ),
                initial_sfb,
                sfb_smem_layout,
                self.mma_tiler_sfb,
                tiled_mma_sfb,
                self.fallback_cluster_layout_sfb_vmnk.shape,
                internal_type=cutlass.Int16,
            )
        )

        # This modifies the layout to handle overlapping 256x(# of scale factors for a single column of B (nNSF)) logical blocks for SFB when cta_tile_shape_n=192
        if cutlass.const_expr(self.cta_tile_shape_mnk[1] == 192):
            x = tma_tensor_sfb.stride[0][1]
            y = cute.ceil_div(tma_tensor_sfb.shape[0][1], 4)

            new_shape = (
                (tma_tensor_sfb.shape[0][0], ((2, 2), y)),
                tma_tensor_sfb.shape[1],
                tma_tensor_sfb.shape[2],
            )
            x_times_3 = 3 * x
            new_stride = (
                (tma_tensor_sfb.stride[0][0], ((x, x), x_times_3)),
                tma_tensor_sfb.stride[1],
                tma_tensor_sfb.stride[2],
            )
            tma_tensor_sfb_new_layout = cute.make_layout(new_shape, stride=new_stride)
            tma_tensor_sfb = cute.make_tensor(
                tma_tensor_sfb.iterator, tma_tensor_sfb_new_layout
            )

        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        sfa_copy_size = cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        self.num_tma_load_bytes = (
            a_copy_size + b_copy_size + sfa_copy_size + sfb_copy_size
        ) * atom_thr_size

        # Setup TMA store for C
        epi_smem_layout = cute.select(
            self.c_smem_layout_staged,
            mode=list(range(cute.rank(self.c_smem_layout_staged) - 1)),
        )
        tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
            cpasync.CopyBulkTensorTileS2GOp(),
            initial_c,
            epi_smem_layout,
            self.epi_tile,
        )

        # Compute grid size
        self.tile_sched_params, grid = self._compute_grid(
            total_num_clusters,
            self.preferred_cluster_shape_mn,
            self.fallback_cluster_shape_mn,
            preferred_max_active_clusters,
            fallback_max_active_clusters,
        )

        self.buffer_align_bytes = 1024
        self.size_tensormap_in_i64 = (
            Sm107GroupedBlockScaledGemmKernel.num_tensormaps
            * Sm107GroupedBlockScaledGemmKernel.bytes_per_tensormap
            // 8
        )

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            tensormap_buffer: cute.struct.MemRange[
                cutlass.Int64, self.size_tensormap_in_i64
            ]
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            sC: cute.struct.Align[
                cute.struct.MemRange[
                    self.c_dtype,
                    cute.cosize(self.c_smem_layout_staged.outer),
                ],
                self.buffer_align_bytes,
            ]
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(self.a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(self.b_smem_layout_staged.outer)
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

        self.shared_storage = SharedStorage

        # Launch the kernel synchronously
        self.mixed_cluster_kernel(
            tiled_mma,
            tiled_mma_bkeep,
            tiled_mma_breuse,
            tiled_mma_sfb,
            (tma_atom_a, tma_atom_a_fallback),
            (tma_tensor_a, tma_tensor_a_fallback),
            (tma_atom_b, tma_atom_b_fallback),
            (tma_tensor_b, tma_tensor_b_fallback),
            (tma_atom_sfa, tma_atom_sfa_fallback),
            (tma_tensor_sfa, tma_tensor_sfa_fallback),
            (tma_atom_sfb, tma_atom_sfb_fallback),
            (tma_tensor_sfb, tma_tensor_sfb_fallback),
            tma_atom_c,
            tma_tensor_c,
            (self.preferred_cluster_layout_vmnk, self.fallback_cluster_layout_vmnk),
            (
                self.preferred_cluster_layout_sfb_vmnk,
                self.fallback_cluster_layout_sfb_vmnk,
            ),
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.tCtSFA_layout,
            self.tCtSFB_layout,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            group_count,
            problem_shape_mnkl,
            strides_abc,
            tensor_address_abc,
            tensor_address_sfasfb,
            tensormap_cute_tensor,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.preferred_cluster_shape_mn, 1),
            fallback_cluster=(*self.fallback_cluster_shape_mn, 1),
            stream=stream,
            min_blocks_per_mp=1,
            smem_merge_branch_allocs=True,
        )
        return

    # GPU device kernel with preferred & fallback cluster sizes.
    @cute.kernel
    def mixed_cluster_kernel(
        self,
        tiled_mma: cute.TiledMma,
        tiled_mma_bkeep: cute.TiledMma,
        tiled_mma_breuse: cute.TiledMma,
        tiled_mma_sfb: cute.TiledMma,
        tma_atom_a: Tuple[cute.CopyAtom, cute.CopyAtom],
        mA_mkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_b: Tuple[cute.CopyAtom, cute.CopyAtom],
        mB_nkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_sfa: Tuple[cute.CopyAtom, cute.CopyAtom],
        mSFA_mkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_sfb: Tuple[cute.CopyAtom, cute.CopyAtom],
        mSFB_nkl: Tuple[cute.Tensor, cute.Tensor],
        tma_atom_c: cute.CopyAtom,
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: Tuple[cute.Layout, cute.Layout],
        cluster_layout_sfb_vmnk: Tuple[cute.Layout, cute.Layout],
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        tCtSFA_layout: cute.Layout,
        tCtSFB_layout: cute.Layout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout],
        epi_tile: cute.Tile,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        group_count: cutlass.Constexpr,
        problem_sizes_mnkl: cute.Tensor,
        strides_abc: cute.Tensor,
        ptrs_abc: cute.Tensor,
        ptrs_sfasfb: cute.Tensor,
        tensormaps: cute.Tensor,
    ):
        """
        GPU device kernel performing the grouped GEMM computation.

        This kernel implements mixed cluster shapes, meaning that it tries to launch with
        the preferred_cluster_shape_mn as its priority, but if at runtime, there is not enough
        resources available to do so, it then uses the fallback_cluster_shape_mn.
        """

        # Get cluster coordinates to determine if this is a preferred cluster
        cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
        is_preferred_cluster = (
            cbdim_x == self.preferred_cluster_shape_mn[0]
            and cbdim_y == self.preferred_cluster_shape_mn[1]
            and cbdim_z == 1
        )

        # mega-kernel approach has 2 mutually exclusive code branches, only one path runs per launch,
        # specify `smem_merge_branch_allocs=True` at launch to enables shared memory reuse between two paths
        if is_preferred_cluster:
            self.kernel_impl(
                tiled_mma,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                tiled_mma_sfb,
                tma_atom_a[0],
                mA_mkl[0],
                tma_atom_b[0],
                mB_nkl[0],
                tma_atom_sfa[0],
                mSFA_mkl[0],
                tma_atom_sfb[0],
                mSFB_nkl[0],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[0],
                cluster_layout_sfb_vmnk[0],
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                tCtSFA_layout,
                tCtSFB_layout,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                group_count,
                problem_sizes_mnkl,
                strides_abc,
                ptrs_abc,
                ptrs_sfasfb,
                tensormaps,
                self.preferred_cluster_shape_mn,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
            )
        else:
            self.kernel_impl(
                tiled_mma,
                tiled_mma_bkeep,
                tiled_mma_breuse,
                tiled_mma_sfb,
                tma_atom_a[1],
                mA_mkl[1],
                tma_atom_b[1],
                mB_nkl[1],
                tma_atom_sfa[1],
                mSFA_mkl[1],
                tma_atom_sfb[1],
                mSFB_nkl[1],
                tma_atom_c,
                mC_mnl,
                cluster_layout_vmnk[1],
                cluster_layout_sfb_vmnk[1],
                a_smem_layout_staged,
                b_smem_layout_staged,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                tCtSFA_layout,
                tCtSFB_layout,
                c_smem_layout_staged,
                epi_tile,
                tile_sched_params,
                group_count,
                problem_sizes_mnkl,
                strides_abc,
                ptrs_abc,
                ptrs_sfasfb,
                tensormaps,
                self.fallback_cluster_shape_mn,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
            )

    @staticmethod
    def _compute_grid(
        total_num_clusters: int,
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        preferred_max_active_clusters: cutlass.Constexpr,
        fallback_max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[
        utils.PersistentTileSchedulerParams,
        Tuple[int, int, int],
    ]:
        """Compute tile scheduler parameters and grid shape for mixed cluster grouped GEMM.

        :param total_num_clusters: Total number of clusters to process across all groups.
        :type total_num_clusters: int
        :param preferred_cluster_shape_mn: Preferred shape of each cluster in M, N dimensions.
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback shape of each cluster in M, N dimensions.
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param preferred_max_active_clusters: Maximum number of preferred active clusters.
        :type preferred_max_active_clusters: cutlass.Constexpr
        :param fallback_max_active_clusters: Maximum number of fallback active clusters.
        :type fallback_max_active_clusters: cutlass.Constexpr

        :return: A tuple containing:
            - tile_sched_params: Parameters for the persistent tile scheduler.
            - grid: Grid shape for kernel launch.
        :rtype: Tuple[utils.PersistentTileSchedulerParams, Tuple[int, int, int]]
        """
        # Preferred tile scheduler and grid
        preferred_cluster_shape_mnl = (*preferred_cluster_shape_mn, 1)

        problem_shape_ntile_mnl = (
            preferred_cluster_shape_mn[0],
            preferred_cluster_shape_mn[1],
            cutlass.Int32(total_num_clusters),
        )

        preferred_tile_sched_params = utils.PersistentTileSchedulerParams(
            problem_shape_ntile_mnl, preferred_cluster_shape_mnl
        )
        preferred_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            preferred_tile_sched_params, preferred_max_active_clusters
        )

        # Fallback tile scheduler and grid
        fallback_cluster_shape_mnl = (*fallback_cluster_shape_mn, 1)

        fallback_problem_shape_ntile_mnl = (
            fallback_cluster_shape_mn[0],
            fallback_cluster_shape_mn[1],
            cutlass.Int32(total_num_clusters),
        )

        fallback_tile_sched_params = utils.PersistentTileSchedulerParams(
            fallback_problem_shape_ntile_mnl, fallback_cluster_shape_mnl
        )
        fallback_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            fallback_tile_sched_params, fallback_max_active_clusters
        )

        # Align preferred grid to cluster shape
        preferred_grid = cute.round_up(preferred_grid, preferred_cluster_shape_mnl)

        # Compute max preferred clusters
        preferred_cluster_size_mn = (
            preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
        )
        max_ctas_for_fallback_cluster = (
            fallback_grid[0] * fallback_grid[1] * fallback_grid[2]
        )
        # Use floor division (not ceil_div) to compute max preferred cluster count.
        # The preferred cluster total CTA count must not exceed the fallback total,
        # otherwise when the division is not exact, the extra partial wave of
        # preferred clusters may force the hardware to schedule one additional wave,
        # causing significant performance regression.
        max_preferred_cluster_count = (
            max_ctas_for_fallback_cluster // preferred_cluster_size_mn
        )
        preferred_grid = (
            preferred_grid[0],
            preferred_grid[1],
            max_preferred_cluster_count,
        )

        return (
            preferred_tile_sched_params,
            preferred_grid,
        )

    @staticmethod
    def can_implement(
        problem_sizes_mnkl: List[Tuple[int, int, int, int]],
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
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """
        Check if the gemm can be implemented.

        :return: True if the gemm can be implemented, False otherwise
        :rtype: bool
        """
        try:
            if not Sm107GroupedBlockScaledGemmKernel.can_implement(
                problem_sizes_mnkl,
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
                preferred_cluster_shape_mn,
            ):
                return False

            if (
                fallback_cluster_shape_mn[0] % (2 if mma_inst_shape[0] == 256 else 1)
                != 0
            ):
                raise testing.CantImplementError(
                    f"Invalid fallback cluster shape for a 2CTA MMA, fallback_cluster_shape_m: {fallback_cluster_shape_mn[0]}"
                )

            # Check preferred is multiple of fallback
            if (
                preferred_cluster_shape_mn[0] % fallback_cluster_shape_mn[0] != 0
                or preferred_cluster_shape_mn[1] % fallback_cluster_shape_mn[1] != 0
            ):
                raise testing.CantImplementError(
                    f"Preferred cluster shape {preferred_cluster_shape_mn} must be "
                    f"integer multiple of fallback cluster shape {fallback_cluster_shape_mn}"
                )

            # Check that the problem is at least as large as the preferred cluster tile.
            # The mixed clusters kernel computes max_preferred_cluster_count as:
            #   max_ctas_for_fallback_cluster // preferred_cluster_size_mn
            # If the problem is smaller than one preferred cluster tile, this count
            # becomes zero, resulting in an invalid grid shape.
            preferred_tile_m = mma_tiler[0] * preferred_cluster_shape_mn[0]
            preferred_tile_n = mma_tiler[1] * preferred_cluster_shape_mn[1]
            for mnkl in problem_sizes_mnkl:
                m, n, k, l = mnkl
                if m < preferred_tile_m or n < preferred_tile_n:
                    raise testing.CantImplementError(
                        f"Problem size ({m}, {n}) is smaller than the preferred cluster tile "
                        f"({preferred_tile_m}, {preferred_tile_n})"
                    )
        except testing.CantImplementError as e:
            print(f"[DSL ERROR] CantImplementError: {e}")
            return False
        return True


def run(
    num_groups: int,
    problem_sizes_mnkl: List[Tuple[int, int, int, int]],
    host_problem_shape_available: bool,
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
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Run SM107 grouped blockscaled GEMM example with mixed cluster support.

    :return: Execution time of the GEMM kernel in microseconds
    :rtype: float
    """
    print("Running Rubin Grouped Blockscaled GEMM (Mixed Clusters) test with:")
    print(f"{num_groups} groups")
    for i, (m, n, k, l) in enumerate(problem_sizes_mnkl):
        print(f"Group {i}: {m}x{n}x{k}x{l}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, SF dtype: {sf_dtype}, SF Vec size: {sf_vec_size}"
    )
    print(f"C dtype: {c_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(
        f"Mma Tiler (M, N, K): {mma_tiler}, MMA instruction shape (M, N, K): {mma_inst_shape}"
    )
    print(f"Preferred cluster Shape (M, N): {preferred_cluster_shape_mn}")
    print(f"Fallback cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")

    # Skip unsupported testcase
    if not Sm107GroupedBlockScaledGemmMixedClustersKernel.can_implement(
        problem_sizes_mnkl,
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
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
    ):
        raise cutlass.testing.CantImplementError(
            f"Unsupported testcase {a_dtype}, {b_dtype}, {sf_dtype}, {sf_vec_size}, {c_dtype}, {mma_tiler}, "
            f"{mma_inst_shape}, preferred_cluster: {preferred_cluster_shape_mn}, "
            f"fallback_cluster: {fallback_cluster_shape_mn}, {problem_sizes_mnkl}, {a_major}, {b_major}, {c_major}"
        )

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(2026)

    # Create tensors A, B, C for all groups
    (
        ptrs_abc,
        torch_tensors_abc,
        cute_tensors_abc,
        strides_abc,
        ref_f32_torch_tensors_abc,
    ) = create_tensors_abc_for_all_groups(
        problem_sizes_mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
    )
    # Create tensors SFA, SFB for all groups
    (
        ptrs_sfasfb,
        torch_tensors_sfasfb,
        cute_tensors_sfasfb,
        refs_f32_torch_tensors_sfasfb,
    ) = create_tensors_sfasfb_for_all_groups(
        problem_sizes_mnkl,
        sf_dtype,
        sf_vec_size,
    )

    # Setup initial tensors for TMA of A, B and C
    alignment = 16
    divisibility_ab = 32 if cutlass.Float4E2M1FN in (a_dtype, b_dtype) else 16
    divisibility_c = 32 if c_dtype == cutlass.Float4E2M1FN else 16
    divisibility_sf = 16

    min_ab_width = min(a_dtype.width, b_dtype.width)
    min_ab_size = alignment * 8 // min_ab_width
    div_mul_ab = (divisibility_ab + min_ab_size - 1) // min_ab_size
    min_ab_size *= div_mul_ab

    min_c_size = alignment * 8 // c_dtype.width
    div_mul_c = (divisibility_c + min_c_size - 1) // min_c_size
    min_c_size = min_c_size * div_mul_c

    min_sf_size = alignment * 8 // sf_dtype.width
    div_mul_sf = (divisibility_sf + min_sf_size - 1) // min_sf_size
    min_sf_size = min_sf_size * div_mul_sf

    initial_cute_tensors_abc = [
        create_tensor_and_stride(1, min_ab_size, min_ab_size, a_major == "m", a_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_ab_size, min_ab_size, b_major == "n", b_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_c_size, min_c_size, c_major == "m", c_dtype)[2],
    ]
    initial_cute_tensors_sfasfb = [
        create_tensor_and_stride(1, min_sf_size, min_sf_size, a_major == "m", sf_dtype)[
            2
        ],
        create_tensor_and_stride(1, min_sf_size, min_sf_size, b_major == "n", sf_dtype)[
            2
        ],
    ]

    hardware_info = cutlass.utils.HardwareInfo()
    sm_count = hardware_info.get_max_active_clusters(1)
    preferred_max_active_clusters = hardware_info.get_max_active_clusters(
        preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1]
    )
    fallback_max_active_clusters = hardware_info.get_max_active_clusters(
        fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
    )

    # Prepare tensormap buffer for each SM
    num_tensormap_buffers = sm_count
    tensormap_shape = (
        num_tensormap_buffers,
        Sm107GroupedBlockScaledGemmKernel.num_tensormaps,
        Sm107GroupedBlockScaledGemmKernel.bytes_per_tensormap // 8,
    )
    tensor_of_tensormap, tensor_of_tensormap_torch = cutlass_torch.cute_tensor_like(
        torch.empty(tensormap_shape, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
    )

    grouped_blockscaled_gemm = Sm107GroupedBlockScaledGemmMixedClustersKernel(
        sf_vec_size,
        mma_inst_shape,
        mma_tiler,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
    )

    # layout (num_groups, 4):(4, 1)
    (
        tensor_of_dim_size_mnkl,
        tensor_of_dim_size_mnkl_torch,
    ) = cutlass_torch.cute_tensor_like(
        torch.tensor(problem_sizes_mnkl, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups, 3, 2):(6, 2, 1)
    tensor_of_strides_abc, tensor_of_strides_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(strides_abc, dtype=torch.int32),
        cutlass.Int32,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,3):(3, 1)
    tensor_of_ptrs_abc, tensor_of_ptrs_abc_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_abc, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # layout (num_groups,2):(2, 1)
    tensor_of_ptrs_sfasfb, tensor_of_ptrs_sfasfb_torch = cutlass_torch.cute_tensor_like(
        torch.tensor(ptrs_sfasfb, dtype=torch.int64),
        cutlass.Int64,
        is_dynamic_layout=False,
        assumed_align=16,
    )

    # Compute total number of cluster tiles
    def compute_total_num_clusters(
        problem_sizes_mnkl: List[tuple[int, int, int, int]],
        cluster_tile_shape_mn: tuple[int, int],
    ) -> int:
        total_num_clusters = 0
        for m, n, _, _ in problem_sizes_mnkl:
            num_clusters_mn = tuple(
                (x + y - 1) // y for x, y in zip((m, n), cluster_tile_shape_mn)
            )
            total_num_clusters += functools.reduce(lambda x, y: x * y, num_clusters_mn)
        return total_num_clusters

    def compute_cluster_tile_shape(
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
    ) -> tuple[int, int]:
        cta_tile_shape_mn = [128, mma_tiler_mn[1]]
        return tuple(x * y for x, y in zip(cta_tile_shape_mn, cluster_shape_mn))

    cluster_tile_shape_mn = compute_cluster_tile_shape(
        (mma_tiler[0], mma_tiler[1]), preferred_cluster_shape_mn
    )
    total_num_clusters = compute_total_num_clusters(
        problem_sizes_mnkl, cluster_tile_shape_mn
    )

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    if host_problem_shape_available:
        print("Problem shapes available on host and device")
        total_num_clusters = compute_total_num_clusters(
            problem_sizes_mnkl, cluster_tile_shape_mn
        )
    else:
        print("Problem shapes available only on device")
        total_num_clusters = preferred_max_active_clusters

    # Compile grouped GEMM kernel
    compiled_grouped_gemm = cute.compile(
        grouped_blockscaled_gemm,
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
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        current_stream,
    )

    # reference check
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
        print("Verifying results...")

        for i, (
            (a_ref, b_ref, c_ref),
            (sfa_ref, sfb_ref),
            (a_tensor, b_tensor, c_tensor),
            (m, n, k, l),
        ) in enumerate(
            zip(
                ref_f32_torch_tensors_abc,
                refs_f32_torch_tensors_sfasfb,
                cute_tensors_abc,
                problem_sizes_mnkl,
            )
        ):
            ref_res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
            ref_res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
            ref = torch.einsum("mkl,nkl->mnl", ref_res_a, ref_res_b)

            print(f"checking group {i}")
            c_ref_device = c_ref.cuda()

            cute.testing.convert(
                c_tensor,
                from_dlpack(c_ref_device, assumed_align=16).mark_layout_dynamic(
                    leading_dim=(1 if c_major == "n" else 0)
                ),
            )

            c_ref = c_ref_device.cpu()

            if c_dtype in (cutlass.Float32, cutlass.Float16, cutlass.BFloat16):
                torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)
            elif c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
                ref_f8_ = torch.empty(
                    *(l, m, n), dtype=torch.uint8, device="cuda"
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
                ref = ref_device.cpu()
                torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)
            elif c_dtype is cutlass.Float4E2M1FN:
                ref_f4_ = torch.empty(
                    *(l, m, n), dtype=torch.uint8, device="cuda"
                ).permute(1, 2, 0)
                ref_f4 = from_dlpack(ref_f4_, assumed_align=16).mark_layout_dynamic(
                    leading_dim=1
                )
                ref_f4.element_type = c_dtype
                ref_device = ref.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
                ref_tensor = from_dlpack(
                    ref_device, assumed_align=16
                ).mark_layout_dynamic(leading_dim=1)
                cute.testing.convert(ref_tensor, ref_f4)
                cute.testing.convert(ref_f4, ref_tensor)
                ref = ref_device.cpu()
                torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)

    def generate_tensors():
        (
            ptrs_abc_workspace,
            torch_tensors_abc_workspace,
            cute_tensors_abc_workspace,
            strides_abc_workspace,
            _,
        ) = create_tensors_abc_for_all_groups(
            problem_sizes_mnkl,
            a_dtype,
            b_dtype,
            c_dtype,
            a_major,
            b_major,
            c_major,
        )

        (
            ptrs_sfasfb_workspace,
            torch_tensors_sfasfb_workspace,
            cute_tensors_sfasfb_workspace,
            _,
        ) = create_tensors_sfasfb_for_all_groups(
            problem_sizes_mnkl,
            sf_dtype,
            sf_vec_size,
        )

        initial_cute_tensors_abc_workspace = [
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, a_major == "m", a_dtype
            )[2],
            create_tensor_and_stride(
                1, min_ab_size, min_ab_size, b_major == "n", b_dtype
            )[2],
            create_tensor_and_stride(
                1, min_c_size, min_c_size, c_major == "m", c_dtype
            )[2],
        ]
        initial_cute_tensors_sfasfb_workspace = [
            create_tensor_and_stride(
                1, min_sf_size, min_sf_size, a_major == "m", sf_dtype
            )[2],
            create_tensor_and_stride(
                1, min_sf_size, min_sf_size, b_major == "n", sf_dtype
            )[2],
        ]

        # Create new tensors for this workspace
        tensor_of_strides_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(strides_abc_workspace, dtype=torch.int32),
            cutlass.Int32,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_abc_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_abc_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensor_of_ptrs_sfasfb_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.tensor(ptrs_sfasfb_workspace, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
            assumed_align=16,
        )

        tensormap_workspace, _ = cutlass_torch.cute_tensor_like(
            torch.empty(tensormap_shape, dtype=torch.int64),
            cutlass.Int64,
            is_dynamic_layout=False,
        )

        args = cutlass.testing.JitArguments(
            initial_cute_tensors_abc_workspace[0],
            initial_cute_tensors_abc_workspace[1],
            initial_cute_tensors_abc_workspace[2],
            initial_cute_tensors_sfasfb_workspace[0],
            initial_cute_tensors_sfasfb_workspace[1],
            tensor_of_dim_size_mnkl,
            tensor_of_strides_abc_workspace,
            tensor_of_ptrs_abc_workspace,
            tensor_of_ptrs_sfasfb_workspace,
            tensormap_workspace,
            current_stream,
        )
        args.add_to_scope([torch_tensors_abc_workspace, torch_tensors_sfasfb_workspace])
        return args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            sum(
                [
                    sum(
                        [
                            torch_tensor.numel() * torch_tensor.element_size()
                            for torch_tensor in group_tensors
                        ]
                    )
                    for group_tensors in torch_tensors_abc + torch_tensors_sfasfb
                ]
            )
            + tensor_of_strides_abc_torch.numel()
            * tensor_of_strides_abc_torch.element_size()
            + tensor_of_ptrs_abc_torch.numel() * tensor_of_ptrs_abc_torch.element_size()
            + tensor_of_ptrs_sfasfb_torch.numel()
            * tensor_of_ptrs_sfasfb_torch.element_size()
            + tensor_of_tensormap_torch.numel()
            * tensor_of_tensormap_torch.element_size()
        )
        workspace_count = cutlass.testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = cutlass.testing.benchmark(
        compiled_grouped_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    runtime_s = exec_time / 1.0e6
    fmas = 0
    for group in range(num_groups):
        [M, N, K, _] = problem_sizes_mnkl[group]
        fmas += M * N * K
    flop = 2 * fmas
    gflop = flop / 1.0e9

    print("Average Runtime : ", exec_time / 1000, "ms")
    if runtime_s > 0:
        gflops = gflop / runtime_s
        print("GFLOPS          : ", gflops)

    return exec_time


def prepare_parser():
    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_comma_separated_tuples(s: str) -> List[Tuple[int, ...]]:
        if s.strip().startswith("("):
            tuples = s.strip("()").split("),(")
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
            "Invalid format. Expected comma-separated integers or list of tuples"
        )

    parser = argparse.ArgumentParser(
        description="Example of Grouped GEMM with Mixed Clusters on Rubin."
    )
    parser.add_argument(
        "--num_groups",
        type=int,
        default=2,
        help="Number of groups",
    )
    parser.add_argument(
        "--problem_sizes_mnkl",
        type=parse_comma_separated_tuples,
        default=((128, 128, 128, 1), (128, 128, 128, 1)),
        help="a tuple of problem sizes for each group (comma-separated tuples)",
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 256),
        help="Mma tile shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_shape",
        type=parse_comma_separated_ints,
        default=(128, 128, 128),
        help="Mma inst shape (M, N, K) (comma-separated)",
    )
    parser.add_argument(
        "--host_problem_shape_available",
        action="store_true",
        help="Enable the compute of grid based upon host problem shape",
    )
    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Preferred cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Fallback cluster shape (comma-separated)",
    )
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
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
    return parser


if __name__ == "__main__":
    parser = prepare_parser()
    args = parser.parse_args()

    if (
        len(args.problem_sizes_mnkl) != 0
        and len(args.problem_sizes_mnkl) != args.num_groups
    ):
        parser.error("--problem_sizes_mnkl must contain exactly num_groups tuples")

    for _, _, _, l in args.problem_sizes_mnkl:
        if l != 1:
            parser.error("l must be 1 for all groups")

    if len(args.mma_tiler) != 3:
        parser.error("--mma_tiler must contain exactly 3 values (M, N, K)")

    if len(args.mma_inst_shape) != 3:
        parser.error("--mma_inst_shape must contain exactly 3 values (M, N, K)")

    if len(args.preferred_cluster_shape_mn) != 2:
        parser.error("--preferred_cluster_shape_mn must contain exactly 2 values")

    if len(args.fallback_cluster_shape_mn) != 2:
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    print("[DSL INFO] Compiling Rubin Grouped Blockscaled GEMM with mixed clusters:")
    print(
        f"[DSL INFO] A dtype: {args.a_dtype}, B dtype: {args.b_dtype}, C dtype: {args.c_dtype}"
    )
    print(f"[DSL INFO] SF dtype: {args.sf_dtype}, SF vector size: {args.sf_vec_size}")
    print(
        f"[DSL INFO] Matrix majors - A: {args.a_major}, B: {args.b_major}, C: {args.c_major}"
    )
    print(f"[DSL INFO] Mma Tiler (M, N, K): {args.mma_tiler}")
    print(f"[DSL INFO] Mma inst shape (M, N, K): {args.mma_inst_shape}")
    print(
        f"[DSL INFO] B-reuse feature is {'enabled' if args.mma_tiler[0] // args.mma_inst_shape[0] == 2 else 'disabled'}"
    )
    print(
        f"[DSL INFO] Preferred cluster Shape (M, N): {args.preferred_cluster_shape_mn}"
    )
    print(f"[DSL INFO] Fallback cluster Shape (M, N): {args.fallback_cluster_shape_mn}")

    run(
        args.num_groups,
        args.problem_sizes_mnkl,
        args.host_problem_shape_available,
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
        args.preferred_cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
