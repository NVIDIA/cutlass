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
import math
import os
import sys
from typing import Optional, Tuple, Type, Union

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass import testing
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync, tcgen05


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))
from helpers import sparse_utils
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)

"""
A high-performance persistent batched sparse GEMM example for NVIDIA Blackwell SM100 architecture.

This kernel implements 2:4 structured sparse GEMM where matrix A has 50% sparsity:
- Matrix A is sparse (2:4 structured): MxKxL, compressed to store only non-zero values
- Matrix E is metadata: encodes sparsity pattern for A
- Matrix B is dense: NxKxL
- Matrix C is output: MxNxL

Key features:
- 2:4 structured sparsity (every 4 elements contain exactly 2 non-zeros)
- TMA loads for A (compressed), B (dense), and E (metadata)
- UTCCP instruction to copy metadata from SMEM to TMEM
- tcgen05.mma sparse instructions
- Persistent tile scheduling with warp specialization

Usage example:
    python examples/cute/blackwell/kernel/sparse_gemm/sparse_gemm_persistent.py \\
      --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32 \\
      --mma_tiler_mn 256,128 --cluster_shape_mn 2,1 \\
      --mnkl 8192,8192,8192,1 --use_tma_store --use_2cta_instrs
"""


def _compute_sparse_stages(
    mma_tiler_mnk: Tuple[int, int, int],
    a_raw_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    a_sparse_dtype: Type[cutlass.Numeric],
    e_sparse_dtype: Type[cutlass.Numeric],
    a_smem_layout_stage_one: cute.Layout,
    b_smem_layout_stage_one: cute.Layout,
    e_smem_layout_stage_one: cute.Layout,
    smem_capacity: int,
    occupancy: int,
    use_tma_store: bool,
    c_smem_layout: Union[cute.Layout, None],
) -> Tuple[int, int, int]:
    """Compute stage counts for sparse GEMM with A, B, E operands.

    For 2:4 structured sparsity:
    - Matrix A is stored compressed (50% size reduction)
    - Metadata E stores sparsity pattern (small overhead)
    - All three (A, B, E) use the same stage count for synchronization

    :param mma_tiler_mnk: MMA tiler shape (M, N, K)
    :param a_raw_dtype: Data type of sparse operand A (raw type, not wrapped with sparse_elem)
    :param b_dtype: Data type of operand B (Float16/BFloat16)
    :param c_dtype: Data type of output C
    :param a_sparse_dtype: Sparse element type for A (sparse_elem<2, a_raw_dtype>)
    :param e_sparse_dtype: Sparse element type for E (sparse_elem<8, uint8>)
    :param a_smem_layout_stage_one: A SMEM layout for single stage
    :param b_smem_layout_stage_one: B SMEM layout for single stage
    :param e_smem_layout_stage_one: E SMEM layout for single stage
    :param smem_capacity: Shared memory capacity in bytes
    :param occupancy: Target occupancy
    :param use_tma_store: Whether TMA store is used
    :param c_smem_layout: C shared memory layout (if TMA store enabled)
    :return: (num_acc_stage, num_abe_stage, num_c_stage)
    """
    # Accumulator pipeline stage count depends on N dimension
    # AccumulatorNPerCta = N dimension of the tile
    # If N > 224, use 1 stage; otherwise use 2 stages
    accumulator_n_per_cta = mma_tiler_mnk[1]
    num_acc_stage = 1 if accumulator_n_per_cta > 224 else 2
    num_c_stage = 2 if use_tma_store else 0

    a_dtype_bits = a_raw_dtype.width
    k_bytes = (a_dtype_bits * mma_tiler_mnk[2]) // 8
    is_hmma_two_kphase = (k_bytes == 128) and (a_dtype_bits == 16 or a_dtype_bits == 32)

    a_bytes = cute.size_in_bytes(a_sparse_dtype, a_smem_layout_stage_one)
    b_bytes = cute.size_in_bytes(b_dtype, b_smem_layout_stage_one)
    e_bytes = cute.size_in_bytes(e_sparse_dtype, e_smem_layout_stage_one) * (
        2 if is_hmma_two_kphase else 1
    )
    abe_bytes_per_stage = a_bytes + b_bytes + e_bytes

    mbar_helpers_bytes = 1024
    c_bytes_per_stage = (
        cute.size_in_bytes(c_dtype, c_smem_layout) if use_tma_store else 0
    )
    c_bytes = c_bytes_per_stage * num_c_stage

    # Calculate ABE stages
    num_abe_stage = (
        smem_capacity // occupancy - (mbar_helpers_bytes + c_bytes)
    ) // abe_bytes_per_stage

    # Refine C stages
    if use_tma_store:
        num_c_stage += (
            smem_capacity
            - occupancy * abe_bytes_per_stage * num_abe_stage
            - occupancy * (mbar_helpers_bytes + c_bytes)
        ) // (occupancy * c_bytes_per_stage)

    return num_acc_stage, num_abe_stage, num_c_stage


class SparsePersistentGemmKernel:
    """Sparse GEMM kernel with 2:4 structured sparsity and persistent scheduling.

    This kernel performs C = sparse_A x dense_B where A has 2:4 structured sparsity.

    :param acc_dtype: Accumulator data type
    :param use_2cta_instrs: Whether to use 2-CTA MMA instructions
    :param mma_tiler_mn: MMA tiler shape (M, N)
    :param cluster_shape_mn: Cluster shape (M, N)
    :param use_tma_store: Whether to use TMA store for output
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
    ):
        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.use_tma_store = use_tma_store
        self.arch = "sm_100"

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Warp specialization
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.threads_per_cta = 32 * len(
            (self.mma_warp_id, self.tma_warp_id, *self.epilogue_warp_id)
        )

        # Barrier IDs
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)

        # Metadata dtype is uint8
        self.e_raw_dtype = cutlass.Uint8

    def is_valid_dtypes(
        self, ab_dtype: Type[cutlass.Numeric], c_dtype: Type[cutlass.Numeric]
    ) -> bool:
        """Check if the data types are valid for sparse GEMM.

        For 2:4 structured sparsity on Blackwell, Float16, BFloat16,
        Float8E4M3FN, Float8E5M2, TFloat32 are supported.

        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]

        :return: True if the dtypes are valid, False otherwise
        :rtype: bool
        """
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.TFloat32,
        }
        if ab_dtype not in valid_ab_dtypes:
            return False

        # Accumulator type validation
        if self.acc_dtype not in {cutlass.Float32, cutlass.Float16}:
            return False

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.TFloat32,
            },
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
        }
        # Check compatibility between accumulator type and AB type
        if ab_dtype not in acc_ab_compatibility[self.acc_dtype]:
            return False

        # Define compatibility mapping between accumulator type and C type
        acc_c_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.TFloat32,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
        }
        # Check compatibility between accumulator type and C type
        if c_dtype not in acc_c_compatibility[self.acc_dtype]:
            return False

        return True

    def is_valid_mma_tiler_and_cluster_shape(self) -> bool:
        """Check if the mma tiler and cluster shape are valid.

        :return: True if the mma tiler and cluster shape are valid, False otherwise
        :rtype: bool
        """
        is_valid = True
        # Skip invalid mma tile shape
        if not (
            (not self.use_2cta_instrs and self.mma_tiler_mn[0] in [64, 128])
            or (self.use_2cta_instrs and self.mma_tiler_mn[0] == 256)
        ):
            is_valid = False
        if self.mma_tiler_mn[1] not in range(32, 257, 32):
            is_valid = False
        # Skip illegal cluster shape
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            is_valid = False
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            self.cluster_shape_mn[0] * self.cluster_shape_mn[1] > 16
            or self.cluster_shape_mn[0] <= 0
            or self.cluster_shape_mn[1] <= 0
            or not is_power_of_2(self.cluster_shape_mn[0])
            or not is_power_of_2(self.cluster_shape_mn[1])
        ):
            is_valid = False
        return is_valid

    def is_valid_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        l: int,
        ab_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
    ) -> bool:
        """Check if the tensor alignment is valid.

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor (before compression)
        :type k: int
        :param l: The batch size
        :type l: int
        :param ab_dtype: The data type of the A and B operands
        :type ab_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param c_major: The major axis of the C tensor
        :type c_major: str

        :return: True if the problem shape is valid, False otherwise
        :rtype: bool
        """
        is_valid = True

        # K dimension must be at least 8 and divisible by 8 for 2:4 structured sparsity
        # K dimension must be at least 4 and divisible by 4 for 1:2 structured sparsity
        if (ab_dtype.width == 16 or ab_dtype.width == 8) and (k < 8 or k % 8 != 0):
            return False
        if ab_dtype.width == 32 and (k < 4 or k % 4 != 0):
            return False

        # This is needed for the hierarchical metadata layout (see sparse_utils.py fp16_e_meta_reorder)
        if ab_dtype.width == 16 or ab_dtype.width == 8:
            if m % 128 != 0 or k % 128 != 0:
                return False

        def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            return num_major_elements % num_contiguous_elements == 0

        # For sparse A, check alignment with compressed K dimension (k // 2)
        if not check_contiguous_16B_alignment(ab_dtype, a_major == "m", (m, k // 2, l)):
            is_valid = False
        if not check_contiguous_16B_alignment(ab_dtype, b_major == "n", (n, k, l)):
            is_valid = False
        if not check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n, l)):
            is_valid = False

        return is_valid

    def is_valid_epilog_store_option(self, m: int, n: int) -> bool:
        """Check if the epilogue store option is valid.

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int

        :return: True if the epilogue store option is valid, False otherwise
        :rtype: bool
        """
        is_valid = True
        # None TMA store version does not have predication, can not support OOB tiles
        cta_tile_shape_mn = (
            self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1),
            self.mma_tiler_mn[1],
        )
        if not self.use_tma_store:
            if not (m % cta_tile_shape_mn[0] == 0 and n % cta_tile_shape_mn[1] == 0):
                is_valid = False
        return is_valid

    def can_implement(
        self, a: cute.Tensor, b: cute.Tensor, e: cute.Tensor, c: cute.Tensor
    ) -> bool:
        """Check if the given tensors can be implemented by this sparse kernel.

        :param a: Compressed sparse input tensor A
        :type a: cute.Tensor
        :param b: Dense input tensor B
        :type b: cute.Tensor
        :param e: Metadata tensor E for sparsity pattern
        :type e: cute.Tensor
        :param c: Output tensor C
        :type c: cute.Tensor

        :return: True if the sparse gemm supports the given config, False otherwise
        :rtype: bool
        """
        # A is compressed, so actual K = a.shape[1] * 2
        m, n, k_compressed, l = a.shape[0], b.shape[0], a.shape[1], a.shape[2]
        k = k_compressed * 2  # Uncompress K for validation

        # infer a_major, b_major, c_major
        is_m_major_a = cutlass.tensor_utils.LayoutEnum.from_tensor(a).is_m_major_a()
        is_n_major_b = cutlass.tensor_utils.LayoutEnum.from_tensor(b).is_n_major_b()
        is_m_major_c = cutlass.tensor_utils.LayoutEnum.from_tensor(c).is_m_major_c()
        a_major = "m" if is_m_major_a else "k"
        b_major = "n" if is_n_major_b else "k"
        c_major = "m" if is_m_major_c else "n"

        can_implement = True
        # Skip unsupported types
        if not self.is_valid_dtypes(a.element_type, c.element_type):
            can_implement = False
        # Skip invalid mma tile shape and cluster shape
        if not self.is_valid_mma_tiler_and_cluster_shape():
            can_implement = False
        # Skip illegal problem shape for load/store alignment
        if not self.is_valid_tensor_alignment(
            m, n, k, l, a.element_type, c.element_type, a_major, b_major, c_major
        ):
            can_implement = False
        # Skip invalid epilogue store option
        if not self.is_valid_epilog_store_option(m, n):
            can_implement = False

        return can_implement

    def _create_tiled_mma(self):
        """Create sparse tiled MMA instruction using helper from blackwell_helpers."""
        return sm100_utils.make_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            mma_tiler_mn=self.mma_tiler[:2],
        )

    def _setup_attributes(self):
        """Setup kernel attributes based on input tensors."""
        tiled_mma = self._create_tiled_mma()

        # Compute MMA shapes
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 2  # could be 2 or 4 for fp16/bf16
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

        # Cluster layout
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )

        # Multicast CTAs
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.num_mcast_ctas_e = self.num_mcast_ctas_a  # E follows A
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        self.is_e_mcast = self.num_mcast_ctas_e > 1

        # Epilogue tile
        if cutlass.const_expr(self.use_tma_store):
            self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                self.c_layout,
                self.c_dtype,
            )
        else:
            self.epi_tile = self.cta_tile_shape_mnk[:2]

        c_smem_layout = None
        if cutlass.const_expr(self.use_tma_store):
            c_smem_layout = sm100_utils.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, 1
            )

        # Create single-stage layouts for stage calculation
        a_smem_layout_stage_one = sm100_utils.make_sparse_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_raw_dtype,
            num_stages=1,
            sparsity=self.a_sparse_dtype.num_logical,
        )
        b_smem_layout_stage_one = sm100_utils.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, 1
        )
        e_smem_layout_stage_one = sm100_utils.make_sparse_smem_layout_e(
            tiled_mma,
            self.mma_tiler_e,
            self.a_raw_dtype,
            num_stages=1,
        )

        # Compute stage counts
        self.num_acc_stage, self.num_abe_stage, self.num_c_stage = (
            _compute_sparse_stages(
                self.mma_tiler,
                self.a_raw_dtype,
                self.b_dtype,
                self.c_dtype,
                self.a_sparse_dtype,
                self.e_sparse_dtype,
                a_smem_layout_stage_one,
                b_smem_layout_stage_one,
                e_smem_layout_stage_one,
                self.smem_capacity,
                self.occupancy,
                self.use_tma_store,
                c_smem_layout,
            )
        )
        # Shared memory layouts
        self.a_smem_layout_staged = sm100_utils.make_sparse_smem_layout_a(
            tiled_mma,
            self.mma_tiler,
            self.a_raw_dtype,
            self.num_abe_stage,
            sparsity=self.a_sparse_dtype.num_logical,
        )
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma, self.mma_tiler, self.b_dtype, self.num_abe_stage
        )

        # E (metadata) layout
        self.e_smem_layout_staged = sm100_utils.make_sparse_smem_layout_e(
            tiled_mma,
            self.mma_tiler_e,
            self.a_raw_dtype,
            self.num_abe_stage,
        )
        # C layout
        self.c_smem_layout_staged = None
        if self.use_tma_store:
            self.c_smem_layout_staged = sm100_utils.make_smem_layout_epi(
                self.c_dtype, self.c_layout, self.epi_tile, self.num_c_stage
            )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,  # Sparse compressed A
        b: cute.Tensor,  # Dense B
        e: cute.Tensor,  # Metadata E
        c: cute.Tensor,  # Output C
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Execute sparse GEMM.

        :param a: Sparse compressed input tensor A
        :param b: Dense input tensor B
        :param e: Metadata tensor E for sparsity pattern
        :param c: Output tensor C
        :param max_active_clusters: Maximum active clusters
        :param stream: CUDA stream
        :param epilogue_op: Optional epilogue operation
        """
        # Setup attributes
        self.a_raw_dtype = a.element_type
        self.b_dtype = b.element_type
        self.c_dtype = c.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b
        ).mma_major_mode()
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)

        # Check if input data types are compatible with MMA instruction
        if cutlass.const_expr(self.a_raw_dtype != self.b_dtype):
            raise TypeError(f"Type must match: {self.a_raw_dtype} != {self.b_dtype}")

        self.tensor_e_atom_k = cute.size(
            sm100_utils.make_tensor_e_atom_layout(self.a_raw_dtype), mode=[1]
        )
        self.mma_tiler_e = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            (self.mma_tiler[2] * self.tensor_e_atom_k)
            // math.gcd(self.mma_tiler[2], self.tensor_e_atom_k),
        )

        self.a_sparse_dtype = sm100_utils.make_sparse_a_dtype(self.a_raw_dtype)
        self.e_sparse_dtype = sm100_utils.make_sparse_e_dtype(self.a_raw_dtype)

        mnkl = (
            cute.size(a, mode=[0]),
            cute.size(b, mode=[0]),
            cute.size(b, mode=[1]),
            cute.size(a, mode=[2]),
        )

        sp_a_ptr = cute.recast_ptr(a.iterator, dtype=self.a_sparse_dtype)
        sp_a_layout = sm100_utils.make_sparse_gmem_layout_a(
            mnkl,
            a_raw_dtype=self.a_raw_dtype,
            is_k_major=(self.a_major_mode == cute.nvgpu.OperandMajorMode.K),
            sparsity=2,  # must be 2 for blackwell sparse gemm
        )
        self.sp_a_gmem_tensor = cute.make_tensor(sp_a_ptr, sp_a_layout)

        sp_e_ptr = cute.recast_ptr(e.iterator, dtype=self.e_sparse_dtype)
        sp_e_layout = sm100_utils.make_sparse_gmem_layout_e(
            mnkl,
            self.a_raw_dtype,
        )
        self.sp_e_gmem_tensor = cute.make_tensor(sp_e_ptr, sp_e_layout)

        tiled_mma = self._create_tiled_mma()

        # Setup attributes that depend on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(tiled_mma.thr_id.shape)

        # TMA setup for A (sparse)
        a_op = sm100_utils.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, tiled_mma.thr_id
        )
        a_smem_layout = cute.slice_(self.a_smem_layout_staged, (None, None, None, 0))
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            self.sp_a_gmem_tensor,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32
                if self.a_raw_dtype is cutlass.Float32
                else self.a_raw_dtype
            ),
        )

        # TMA setup for B (dense)
        b_op = sm100_utils.cluster_shape_to_tma_atom_B(
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
            internal_type=self.b_dtype,
        )
        # TMA setup for E (metadata)
        e_smem_layout = cute.slice_(self.e_smem_layout_staged, (None, None, None, 0))
        tma_atom_e, tma_tensor_e = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            self.sp_e_gmem_tensor,
            e_smem_layout,
            self.mma_tiler_e,
            tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=cutlass.Uint64,
        )

        a_copy_size = cute.size_in_bytes(self.a_sparse_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        e_copy_size = cute.size_in_bytes(self.e_sparse_dtype, e_smem_layout)
        self.num_tma_ab_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size
        self.num_tma_e_load_bytes = e_copy_size * atom_thr_size

        # TMA setup for C
        tma_atom_c = None
        tma_tensor_c = None
        if cutlass.const_expr(self.use_tma_store):
            epi_smem_layout = cute.select(self.c_smem_layout_staged, mode=[0, 1])
            tma_atom_c, tma_tensor_c = cpasync.make_tiled_tma_atom(
                cpasync.CopyBulkTensorTileS2GOp(), c, epi_smem_layout, self.epi_tile
            )

        # Compute grid
        self.tile_sched_params, grid = self._compute_grid(
            c, self.cta_tile_shape_mnk, self.cluster_shape_mn, max_active_clusters
        )

        # Launch kernel
        self.kernel(
            tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            tma_atom_e,
            tma_tensor_e,
            tma_atom_c,
            tma_tensor_c if self.use_tma_store else c,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.e_smem_layout_staged,
            self.c_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            smem=self.smem_capacity,
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_e: cute.CopyAtom,
        mE_mkl: cute.Tensor,
        tma_atom_c: Optional[cute.CopyAtom],
        mC_mnl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        e_smem_layout_staged: cute.ComposedLayout,
        c_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ):
        """Sparse GEMM device kernel with warp specialization."""
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        # Prefetch TMA descriptors
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_e)
            if cutlass.const_expr(self.use_tma_store):
                cpasync.prefetch_descriptor(tma_atom_c)

        use_2cta_instrs = cute.size(tiled_mma.thr_id.shape) == 2

        # Setup CTA coordinates
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        tidx, _, _ = cute.arch.thread_idx()

        # Allocate shared storage
        @cute.struct
        class SharedStorage:
            abe_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_abe_stage * 2
            ]
            acc_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.num_acc_stage * 2
            ]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32

        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(SharedStorage)

        # Initialize ABE pipeline for sparse GEMM
        abe_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        abe_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        abe_producer, abe_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.abe_full_mbar_ptr.data_ptr(),
            num_stages=self.num_abe_stage,
            producer_group=abe_pipeline_producer_group,
            consumer_group=abe_pipeline_consumer_group,
            tx_count=self.num_tma_ab_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

        # Initialize accumulator pipeline
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

        # TMEM allocation barriers
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

        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
            arch=self.arch,
        )

        # Cluster arrive
        pipeline_init_arrive(cluster_shape_mn=cluster_layout_vmnk, is_relaxed=True)

        # Allocate SMEM tensors
        sA = smem.allocate_tensor(
            element_type=self.a_sparse_dtype,
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
        sE = smem.allocate_tensor(
            element_type=self.e_sparse_dtype,
            layout=e_smem_layout_staged.outer,
            byte_alignment=128,
            swizzle=e_smem_layout_staged.inner,
        )

        # Compute multicast masks
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        e_full_mcast_mask = None
        if cutlass.const_expr(
            self.is_a_mcast or self.is_b_mcast or self.is_e_mcast or use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
            e_full_mcast_mask = a_full_mcast_mask  # E follows A multicast pattern

        # Local tile partition
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        gE_mkl = cute.local_tile(
            mE_mkl, cute.slice_(self.mma_tiler_e, (None, 0, None)), (None, None, None)
        )
        gC_mnl = cute.local_tile(
            mC_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        # Partition for TiledMMA
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)
        tCgE = thr_mma.partition_A(gE_mkl)
        tCgC = thr_mma.partition_C(gC_mnl)

        # TMA partitions
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

        # E partition (follows A pattern)
        tEsE, tEgE = cpasync.tma_partition(
            tma_atom_e,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sE, 0, 3),
            cute.group_modes(tCgE, 0, 3),
        )

        # MMA fragments
        tCrA = tiled_mma.make_fragment_A(sA)
        tCrB = tiled_mma.make_fragment_B(sB)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )

        # Compute UtccpReuseCnt for metadata reuse
        cta_k = self.mma_tiler[2]
        utccp_reuse_cnt = (
            (self.tensor_e_atom_k // cta_k) if (cta_k < self.tensor_e_atom_k) else 1
        )

        if cutlass.const_expr(utccp_reuse_cnt > 2):
            raise ValueError(
                f"mma_tiler K={cta_k} is too small for {self.a_raw_dtype} sparse "
                f"GEMM: the metadata atom has K={self.tensor_e_atom_k}, which "
                f"would require utccp_reuse_cnt={utccp_reuse_cnt}, but the kernel "
                f"only supports utccp_reuse_cnt in {{1, 2}}. Use "
                f"mma_tiler K >= {self.tensor_e_atom_k // 2}."
            )

        # Cluster wait
        pipeline_init_wait(cluster_shape_mn=cluster_layout_vmnk)
        #
        # Construct the scheduler
        #
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        # TMA Load warp (warp 5)
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
                tEgE_slice = tEgE[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]

                abe_producer.reset()
                peek_abe_empty_status = abe_producer.try_acquire()

                # Track iteration for E loading based on UtccpReuseCnt
                # For UtccpReuseCnt=1: load E every iteration
                # For UtccpReuseCnt=2: load E only on even iterations (iter % 2 == 0)
                k_utccp_tile_idx = 0

                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Determine if we need to load E metadata for this k_tile
                    load_e = (k_tile % utccp_reuse_cnt) == 0
                    expected_tx = (
                        self.num_tma_ab_load_bytes
                        + cutlass.Int32(load_e) * self.num_tma_e_load_bytes
                    )

                    handle = abe_producer.acquire_and_advance(
                        peek_abe_empty_status, expected_tx=expected_tx
                    )

                    # TMA load A, B
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

                    # TMA load E conditionally
                    if load_e:
                        cute.copy(
                            tma_atom_e,
                            tEgE_slice[(None, k_utccp_tile_idx)],
                            tEsE[(None, handle.index)],
                            tma_bar_ptr=handle.barrier,
                            mcast_mask=e_full_mcast_mask,
                        )
                        k_utccp_tile_idx += 1

                    peek_abe_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_abe_empty_status = abe_producer.try_acquire()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            abe_producer.tail()

        # MMA warp (warp 4)
        if warp_idx == self.mma_warp_id:
            # Wait for TMEM allocation
            tmem.wait_for_alloc()

            # Retrieve TMEM pointer and create accumulator tensor
            acc_tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            tCtAcc_base = cute.make_tensor(acc_tmem_ptr, tCtAcc_fake.layout)

            # Create metadata TMEM tensor (allocated after accumulators)
            e_tmem_layout = sm100_utils.make_sparse_tmem_layout_e(
                cute.slice_(e_smem_layout_staged, (None, None, None, 0)).shape,
                self.a_raw_dtype,
            )

            # Create TMEM pointer and tensor with correct layout
            acc_tmem_col_offset = tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
            if cutlass.const_expr(self.acc_dtype.width < 32):
                acc_tmem_col_offset = acc_tmem_col_offset * (32 // self.acc_dtype.width)
            e_tmem_ptr = cute.recast_ptr(
                acc_tmem_ptr + acc_tmem_col_offset,
                dtype=self.e_sparse_dtype,
            )
            tCtE = cute.make_tensor(e_tmem_ptr, e_tmem_layout)

            # Setup UTCCP copy for metadata (SMEM to TMEM)
            copy_atom_s2t_e = cute.make_copy_atom(
                tcgen05.Cp128x128bOp(self.cta_group),
                self.e_raw_dtype,
            )

            # Make tiled copy using recast TMEM tensor
            tCtE_recast = cute.recast_tensor(tCtE, self.e_raw_dtype)
            tiled_copy_s2t_E = tcgen05.make_s2t_copy(copy_atom_s2t_e, tCtE_recast)
            thr_copy_s2t_E = tiled_copy_s2t_E.get_slice(0)

            # Partition SMEM and TMEM tensors for S2T copy
            sE_recast = cute.recast_tensor(sE, self.e_raw_dtype)
            thr_tCsE_s2t_ = thr_copy_s2t_E.partition_S(sE_recast)

            # SMEM to TMEM copy requires source to be SMEM descriptor
            thr_tCsE_s2t = tcgen05.get_s2t_smem_desc_tensor(
                tiled_copy_s2t_E, thr_tCsE_s2t_
            )

            thr_tCtE_s2t = thr_copy_s2t_E.partition_D(tCtE_recast)

            # Persistent tile scheduling loop
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Track metadata stage index for UtccpReuseCnt > 1
                # math_mma_e_stage_idx toggles between 0 and 1 for UtccpReuseCnt=2
                math_mma_e_stage_idx = 0
                cur_tile_coord = work_tile.tile_idx
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                abe_consumer.reset()
                peek_abe_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_abe_full_status = abe_consumer.try_wait()

                # Wait for accumulator buffer empty
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                # Reset the ACCUMULATE field for each tile
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                # MMA mainloop
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        handle = abe_consumer.wait_and_advance(peek_abe_full_status)

                        # Copy metadata from SMEM to TMEM
                        if utccp_reuse_cnt == 1:
                            cute.copy(
                                tiled_copy_s2t_E,
                                thr_tCsE_s2t[(None, None, None, None, handle.index)],
                                thr_tCtE_s2t,
                            )
                        else:
                            # Copy only on even k_tiles
                            if (k_tile & 1) == 0:
                                cute.copy(
                                    tiled_copy_s2t_E,
                                    thr_tCsE_s2t[
                                        (None, None, None, None, handle.index)
                                    ],
                                    thr_tCtE_s2t,
                                )

                        # Sparse MMA with metadata
                        num_kblocks = cute.size(tCrA, mode=[2])
                        for kblk_idx in cutlass.range(num_kblocks, unroll_full=True):
                            kblk_crd = (None, None, kblk_idx, handle.index)
                            e_idx = math_mma_e_stage_idx * num_kblocks + kblk_idx

                            # Set metadata pointer to tiled_mma
                            e_kblock_coord = (None, None, e_idx)
                            tiled_mma.set(
                                tcgen05.Field.METADATA,
                                tCtE[e_kblock_coord].iterator,
                            )

                            # Sparse MMA
                            cute.gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[kblk_crd],
                                tCrB[kblk_crd],
                                tCtAcc,
                            )
                            tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

                        handle.release()

                        # Update metadata stage index after processing k_tile
                        if utccp_reuse_cnt != 1:
                            math_mma_e_stage_idx = math_mma_e_stage_idx ^ 1

                        peek_abe_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_abe_full_status = abe_consumer.try_wait()

                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            acc_pipeline.producer_tail(acc_producer_state)

        # Epilogue warps (warps 0-3)
        sC = None
        if cutlass.const_expr(self.use_tma_store):
            sC = smem.allocate_tensor(
                element_type=self.c_dtype,
                layout=c_smem_layout_staged.outer,
                byte_alignment=128,
                swizzle=c_smem_layout_staged.inner,
            )

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

            if cutlass.const_expr(self.use_tma_store):
                # Wait for C store complete
                c_pipeline.producer_tail()
            else:
                # Synchronize before TMEM dealloc (done by the caller)
                tmem_dealloc_barrier.arrive_and_wait()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        max_active_clusters: cutlass.Constexpr,
    ) -> Tuple[PersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Compute grid size for persistent scheduling."""
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        return tile_sched_params, grid


def round_to_tf32(t: torch.Tensor) -> torch.Tensor:
    """
    Rounds float32 to tf32 by round to nearest with ties to even.

    :param t: Tensor of any float dtype; converted to float32 first.
    :type t: torch.Tensor
    :return: A float32 tensor whose values are exactly representable in TF32.
    :rtype: torch.Tensor
    """

    bits = t.to(torch.float32).contiguous().view(torch.int32)
    round_bias = ((bits >> 13) & 1) + 0x0FFF
    rounded = (bits + round_bias) & ~0x1FFF

    # keep NaN and Inf
    is_special = (bits & 0x7F800000) == 0x7F800000
    return torch.where(is_special, bits, rounded).view(torch.float32)


def compare(
    a_torch_cpu,
    b_torch_cpu,
    c_torch_gpu,
    c_dtype,
    tolerance,
    ab_dtype=None,
):
    """Compare sparse GEMM kernel result with reference result.
    :param a_torch_cpu: Matrix A with structured sparsity on CPU, shape (M, K, L).
    :param b_torch_cpu: Dense matrix B on CPU, shape (N, K, L).
    :param c_torch_gpu: Kernel output tensor (any device).
    :param c_dtype: Output data type of C (used to cast the reference before
        the ``assert_close``).
    :type c_dtype: Type[cutlass.Numeric]
    :param tolerance: Absolute tolerance for the comparison.
    :type tolerance: float
    :param ab_dtype: Operand type the MMA consumed.
    :type ab_dtype: Optional[Type[cutlass.Numeric]]
    """
    # Copy gpu result back
    kernel_result = c_torch_gpu.cpu()

    # Compute reference result using sparse A and dense B.
    # a_torch_cpu shape: (m, k, l), b_torch_cpu shape: (n, k, l).
    a_ref = a_torch_cpu.to(dtype=torch.float32)
    b_ref = b_torch_cpu.to(dtype=torch.float32)

    if ab_dtype is cutlass.TFloat32:
        a_ref = round_to_tf32(a_ref)
        b_ref = round_to_tf32(b_ref)
    ref = torch.einsum("mkl,nkl->mnl", a_ref, b_ref)

    # Convert ref to c_dtype
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Assert close results
    torch.testing.assert_close(kernel_result, ref_result, atol=tolerance, rtol=1e-05)
    print("Result verification passed!")


def create_sparse_tensors(
    l: int,
    m: int,
    n: int,
    k: int,
    a_major: str,
    b_major: str,
    c_major: str,
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
) -> Tuple:
    """Create sparse tensor A (compressed), dense tensor B, metadata E, and output C.

    For 2:4 sparsity:
    - A is compressed: stores only non-zero values (50% of original size)
    - E is metadata (uint8): encodes which 2 of every 4 elements are non-zero
      Shape: (M, K//8, L) - each uint8 byte encodes 8 A elements (2 chunks of 4)
      Note: For FP16/BF16, metadata is automatically reordered to hierarchical layout

    For 1:2 sparsity:
    - A is compressed: stores only non-zero values (50% of original size)
    - E is metadata (uint8): encodes which 1 of every 2 elements are non-zero
      Shape: (M, K//4, L) - each uint8 byte encodes 4 A elements (1 chunk of 2)
      Note: Metadata is automatically reordered to hierarchical layout

    Constraints:
    - For 2:4 sparsity: K must be >= 8 and divisible by 8 (for metadata encoding)
    - For 1:2 sparsity: K must be >= 4 and divisible by 4 (for metadata encoding)
    - For FP16/BF16: M and K must be divisible by 128 (for hierarchical metadata layout)
    """

    if ab_dtype.width == 16 or ab_dtype.width == 8:
        # Validate k for 2:4 sparsity
        if k < 8:
            raise ValueError(
                f"k must be at least 8 for 2:4 structured sparsity with metadata encoding, got k={k}"
            )
        if k % 8 != 0:
            raise ValueError(
                f"k should be divisible by 8 for 2:4 structured sparsity (metadata encoding requirement), got k={k}"
            )
    elif ab_dtype.width == 32:
        # Validate k for 1:2 sparsity
        if k < 4:
            raise ValueError(
                f"k must be at least 4 for 1:2 structured sparsity with metadata encoding, got k={k}"
            )
        if k % 4 != 0:
            raise ValueError(
                f"k should be divisible by 4 for 1:2 structured sparsity (metadata encoding requirement), got k={k}"
            )
    else:
        raise ValueError(
            f"Unsupported ab_dtype: {ab_dtype} with width {ab_dtype.width}"
        )

    # For FP16/BF16, validate M and K divisibility by 128
    if ab_dtype.width == 16 or ab_dtype.width == 8:  # FP16 or BF16 or FP8
        if m % 128 != 0:
            raise ValueError(
                f"For FP16/BF16/FP8, M must be divisible by 128 for hierarchical metadata layout, got m={m}"
            )
        if k % 128 != 0:
            raise ValueError(
                f"For FP16/BF16/FP8, K must be divisible by 128 for hierarchical metadata layout, got k={k}"
            )

    torch.manual_seed(1111)

    a_compressed_torch_cpu = None
    e_torch_cpu = None

    if ab_dtype == cutlass.TFloat32:
        # Generates A with 1:2 sparsity, compresses it into A_compressed, and writes
        # E in the kernel's TMEM atom layout.
        (
            _a_full_tensor_cute,
            a_compressed_torch_cpu,
            a_torch_cpu,
            a_compressed_torch_cpu,
            _e_cute_cpu,
            e_torch_cpu,
        ) = sparse_utils.create_1_2_sparse_tensors(l, m, k, a_major, ab_dtype)

        del _a_full_tensor_cute, _e_cute_cpu

    elif (
        (ab_dtype == cutlass.Float16)
        or (ab_dtype == cutlass.BFloat16)
        or (ab_dtype == cutlass.Float8E4M3FN)
        or (ab_dtype == cutlass.Float8E5M2)
    ):
        sparse_gen = sparse_utils.SparseUtils(m, k, l, ab_dtype)
        a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)

        # Move to GPU for GPU-based sparse generation
        a_torch_gpu = a_torch_cpu.cuda()

        # Apply 2:4 sparsity pattern on GPU
        sparse_gen.generate_sparse_4_2_tensor_with_tensor(a_torch_gpu, run_on_cpu=False)

        a_compressed_torch_cpu = cutlass_torch.matrix(
            l,
            m,
            k // 2,
            a_major == "m",
            ab_dtype,
            init_type=cutlass_torch.TensorInitType.SKIP,
        )
        a_compressed_torch_gpu = a_compressed_torch_cpu.cuda()

        e_torch_cpu = cutlass_torch.matrix(
            l,
            m,
            k // 8,
            False,
            cutlass.Uint8,
            init_type=cutlass_torch.TensorInitType.SKIP,
        )
        e_torch_gpu = e_torch_cpu.cuda()

        # Compress the sparse tensor on GPU
        sparse_gen.compress(
            a_torch_gpu, a_compressed_torch_gpu, e_torch_gpu, run_on_cpu=False
        )

        # Move results back to CPU for reference check
        a_torch_cpu = a_torch_gpu.cpu()
        a_compressed_torch_cpu = a_compressed_torch_gpu.cpu()
        e_torch_cpu = e_torch_gpu.cpu()
    else:
        raise ValueError(
            f"Unsupported ab_dtype: {ab_dtype} with width {ab_dtype.width}"
        )

    # Create B (dense)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)

    # Create C (output)
    c_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype)

    # Convert to CUTE tensors
    a_compressed_tensor, _ = cutlass_torch.cute_tensor_like(
        a_compressed_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )

    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    e_tensor, _ = cutlass_torch.cute_tensor_like(
        e_torch_cpu, cutlass.Uint8, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    c_tensor.mark_compact_shape_dynamic(
        mode=1 if c_major == "n" else 0,
        stride_order=(2, 0, 1) if c_major == "n" else (2, 1, 0),
        divisibility=16,
    )

    return (
        a_compressed_tensor,
        b_tensor,
        e_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
        a_compressed_torch_cpu,
        e_torch_cpu,
    )


def run(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mn: Tuple[int, int] = (256, 256),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    *,
    benchmark: str = "default",
    **kwargs,
):
    """Execute sparse GEMM with 2:4 structured sparsity.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Data type for accumulation
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major/b_major/c_major: Memory layout of tensor A/B/C
    :type a_major/b_major/c_major: str
    :param mma_tiler_mn: MMA tiling size (M, N)
    :type mma_tiler_mn: Tuple[int, int], optional
    :param cluster_shape_mn: Cluster shape (M, N)
    :type cluster_shape_mn: Tuple[int, int], optional
    :param use_2cta_instrs: Whether to use 2-CTA instructions
    :type use_2cta_instrs: bool, optional
    :param use_tma_store: Whether to use TMA store
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance for reference validation, defaults to 1e-01
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations, defaults to 0
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations, defaults to 1
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference validation, defaults to False
    :type skip_ref_check: bool, optional
    :param init_normal: Whether to initialize tensors using normal distribution
        instead of uniform random, defaults to False.
    :type init_normal: bool, optional
    :param normal_mean: Mean for normal distribution initialization, defaults to 0.0.
    :type normal_mean: float, optional
    :param normal_std: Standard deviation for normal distribution initialization,
        defaults to 1.0.
    :type normal_std: float, optional
    :param benchmark: Timing backend: "cupti" (CUPTI kernel-activity timing),
        "default" (cutlass.testing.benchmark) or "none" (skip timing, return 0).
    :type benchmark: str, optional
    :raises RuntimeError: If CUDA GPU is not available
    :raises ValueError: If problem size is invalid for 2:4 structured sparsity or if the configuration is unsupported
    :return: Execution time of the sparse GEMM kernel in microseconds
    :rtype: float
    """
    sparsity_scheme = "1:2 (TF32)" if ab_dtype.width == 32 else "2:4 (FP16/BF16/FP8)"
    print(f"Running Blackwell Sparse GEMM ({sparsity_scheme}) with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"2CTA MMA: {use_2cta_instrs}, TMA Store: {use_tma_store}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")

    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU required!")

    torch_stream = torch.cuda.current_stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    (
        a_compressed_tensor,
        b_tensor,
        e_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
        a_compressed_torch_cpu,
        e_torch_cpu,
    ) = create_sparse_tensors(l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype)

    # Apply normal initialization to B if requested
    # Note: A is already sparsified by the selected factory, C is output
    if init_normal:
        b_torch_cpu.normal_(mean=normal_mean, std=normal_std)

    # Build sparse GEMM
    gemm = SparsePersistentGemmKernel(
        acc_dtype, use_2cta_instrs, mma_tiler_mn, cluster_shape_mn, use_tma_store
    )

    # Check if configuration can be implemented
    if not gemm.can_implement(a_compressed_tensor, b_tensor, e_tensor, c_tensor):
        raise testing.CantImplementError(
            f"The current config is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler_mn = {mma_tiler_mn}, cluster_shape_mn = {cluster_shape_mn}, "
            f"use_tma_store = {use_tma_store}, ab_dtype = {ab_dtype}, c_dtype = {c_dtype}, "
            f"acc_dtype = {acc_dtype}, mnkl = {mnkl}"
        )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    try:
        compiled_gemm = cute.compile(
            gemm,
            a_compressed_tensor,
            b_tensor,
            e_tensor,
            c_tensor,
            max_active_clusters,
            current_stream,
        )
    except (ValueError, TypeError) as e:
        raise testing.CantImplementError(
            f"Compilation failed for sparse GEMM config: {e}"
        ) from e

    if not skip_ref_check:
        compiled_gemm(a_compressed_tensor, b_tensor, e_tensor, c_tensor, current_stream)
        # Verify result - compare against reference using A matrix with 1:2 or 2:4 sparsity.
        compare(
            a_torch_cpu,
            b_torch_cpu,
            c_torch_gpu,
            c_dtype,
            tolerance,
            ab_dtype=ab_dtype,
        )

    if benchmark == "none":
        return 0

    # Benchmark kernel performance
    def generate_tensors():
        """Generate fresh tensor arguments for benchmarking."""
        a_compressed_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            a_compressed_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        e_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            e_torch_cpu, cutlass.Uint8, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor_bench.mark_compact_shape_dynamic(
            mode=1 if c_major == "n" else 0,
            stride_order=(2, 0, 1) if c_major == "n" else (2, 1, 0),
            divisibility=16,
        )
        return testing.JitArguments(
            a_compressed_tensor_bench,
            b_tensor_bench,
            e_tensor_bench,
            c_tensor_bench,
            current_stream,
        )

    workspace_count = 1

    exec_time = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cupti=benchmark == "cupti",
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Sparse GEMM with 1:2 or 2:4 Structured Sparsity"
    )

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        return tuple(int(x.strip()) for x in s.split(","))

    parser.add_argument(
        "--mnkl", type=parse_comma_separated_ints, default=(256, 256, 512, 1)
    )
    parser.add_argument(
        "--mma_tiler_mn", type=parse_comma_separated_ints, default=(128, 128)
    )
    parser.add_argument(
        "--cluster_shape_mn", type=parse_comma_separated_ints, default=(1, 1)
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--use_2cta_instrs", action="store_true")
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument("--use_tma_store", action="store_true")
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
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=["cupti", "default", "none"],
        help="Benchmark the kernel with cupti or default (cutlass.testing.benchmark) or none",
    )
    testing.add_tensor_init_args(parser, supports_int_dtypes=False)

    args = parser.parse_args()

    testing.validate_tensor_init_args(args, parser)

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
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
        benchmark=args.benchmark,
    )
    print("PASS")
