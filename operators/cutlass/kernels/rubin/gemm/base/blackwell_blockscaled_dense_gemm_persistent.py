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

from typing import Optional, Type, Tuple, Literal

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl import Boolean, Int32
from cutlass.cute.nvgpu import tcgen05, OperandMajorMode
import cutlass.pipeline as pipeline
from cutlass.kernels.utils import tile_scheduler
from cutlass.cute.runtime import make_ptr


"""Blackwell SM100 block-scaled dense GEMM base for the Rubin SM107 kernels.

Not a runnable kernel: the standalone host/device paths were removed. Only the
pieces the SM107 subclasses inherit or import remain -- the constructor and
tile-scheduler template state, the ``is_valid_*`` pre-flight checks, and the
``scaled_mm`` traced entry.
"""


class Sm100BlockScaledPersistentDenseGemmKernel:
    """This class implements batched matrix multiplication (C = A x SFA x B x SFB) with support for various data types
    and architectural features specific to Blackwell GPUs with persistent tile scheduling and warp specialization.

    :param sf_vec_size: Scalefactor vector size.
    :type sf_vec_size: int
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: Tuple[int, int]

    :note: A and B may use different element data types (e.g. mixed f8f6f4). Each of
        a_dtype / b_dtype may independently be any of the supported element types below.

    :note: Supported combinations of A/B data types, SF data typs and SF vector size:
        - MXF8: A/B in {Float8E5M2, Float8E4M3FN} + SF: Float8E8M0FNU + sf_vec_size: 32
        - MXF4: A/B: Float4E2M1FN + SF: Float8E8M0FNU + sf_vec_size: 32
        - NVF4: A/B: Float4E2M1FN + SF: Float8E8M0FNU/Float8E4M3FN + sf_vec_size: 16
        - Mixed f8f6f4: A and B from different element types;
          restricted to SF: Float8E8M0FNU + sf_vec_size: 32

    :note: Supported accumulator data types:
        - Float32

    :note: Supported C data types:
        - Float32
        - Float16/BFloat16
        - Float8E4M3FN/Float8E5M2
    :note: Constraints:
        - MMA tiler M must be 128 or 256 (use_2cta_instrs)
        - MMA tiler N must be 64/128/192/256
        - Cluster shape M must be multiple of 2 if Mma tiler M is 256
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Also, Cluster shape M/N must be <= 4 for scale factor multicasts due to limited size of scale factors

    This base is not runnable; see the SM107 subclasses for usage.
    """

    def __init__(
        self,
        sf_vec_size: int,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool = True,
        split_k: int = 1,
        work_strategy: Literal["grid", "static", "clc"] = "static",
        rasterization_strategy: Literal["none", "affine"] = "affine",
        reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"] = "none",
        num_scheduler_stages: int = 1,
        use_pdl: bool = False,
        use_reduction_pdl: bool = False,
        fallback_cluster_shape_mn: Optional[Tuple[int, int]] = None,
    ):
        """Initializes the configuration for a Blackwell dense GEMM kernel.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data types for MMA accumulator, always set to Float32
            - sf_vec_size: Scalefactor A/B vector size.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        :param sf_vec_size: Scalefactor vector size.
        :type sf_vec_size: int
        :param mma_tiler_mn: Tuple (M, N) shape of the MMA instruction.
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: Tuple[int, int]
        :param use_tma_store: Stage C through SMEM and store it with TMA; when False,
            C goes straight from registers to global memory with predicated stores.
        :type use_tma_store: bool
        :param split_k: Number of K partitions; must be 1 iff ``reduction_strategy`` is "none".
        :type split_k: int
        :param work_strategy: How output tiles are handed to CTAs.
        :type work_strategy: Literal["grid", "static", "clc"]
        :param rasterization_strategy: How a work index is decoded into a tile coordinate.
        :type rasterization_strategy: Literal["none", "affine"]
        :param reduction_strategy: How the K partitions are reduced. "cluster-splitk"
            requires ``use_tma_store=False``: its DSMEM fixup needs the predicated
            register-to-global store only the non-TMA epilogue provides.
        :type reduction_strategy: Literal["none", "gmem-splitk", "cluster-splitk"]
        :param num_scheduler_stages: Depth of the CLC work-fetch pipeline.
        :type num_scheduler_stages: int
        :param use_pdl: Launch this kernel with programmatic dependent launch.
        :type use_pdl: bool
        :param use_reduction_pdl: Launch the GMEM split-K reduction kernel with PDL.
        :type use_reduction_pdl: bool
        :param fallback_cluster_shape_mn: Tuple (ClusterM, ClusterN) shape of the
            fallback cluster; defaults to ``cluster_shape_mn``.
        :type fallback_cluster_shape_mn: Optional[Tuple[int, int]]
        """

        self.acc_dtype = cutlass.Float32
        self.sf_vec_size = sf_vec_size
        self.use_2cta_instrs = mma_tiler_mn[0] == 256
        self.cluster_shape_mn = cluster_shape_mn
        self.use_tma_store = use_tma_store
        self.mma_tiler = (*mma_tiler_mn, 1)

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        self.epilog_warp_id = (
            0,
            1,
            2,
            3,
        )
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.threads_per_warp = 32
        self.epilog_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1,
            num_threads=self.threads_per_warp * len(self.epilog_warp_id),
        )
        self.tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=2,
            num_threads=self.threads_per_warp
            * len((self.mma_warp_id, *self.epilog_warp_id)),
        )
        self.epilogue_warp_id = self.epilog_warp_id
        self.epilog_sync_bar_id = self.epilog_sync_barrier.barrier_id
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_100")
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols("sm_100")

        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn or cluster_shape_mn
        self.split_k = split_k
        self.work_strategy = work_strategy
        self.rasterization_strategy = rasterization_strategy
        self.reduction_strategy = reduction_strategy
        self.num_sched_stages = num_scheduler_stages
        self.use_pdl = use_pdl
        self.use_reduction_pdl = use_reduction_pdl

        self.tile_scheduler_template_params = (
            tile_scheduler.TileSchedulerTemplateParams(
                acc_dtype=self.acc_dtype,
                work_strategy=self.work_strategy,
                rasterization_strategy=self.rasterization_strategy,
                reduction_strategy=self.reduction_strategy,
                num_scheduler_stages=self.num_sched_stages,
                cluster_shape_mn=self.cluster_shape_mn,
                split_k=self.split_k,
                cta_tile_shape_mnk=(
                    self.mma_tiler[0] // (2 if self.use_2cta_instrs else 1),
                    self.mma_tiler[1],
                    1,
                ),
                fallback_cluster_shape_mn=self.fallback_cluster_shape_mn,
            )
        )
        self.tile_scheduler_template = tile_scheduler.build_tile_scheduler_template(
            self.tile_scheduler_template_params
        )
        warp_ids = [self.mma_warp_id, self.tma_warp_id, *self.epilog_warp_id]
        # ``sched_warp_id`` is only read behind a ``requires_scheduler_warp`` guard.
        if self.tile_scheduler_template.requires_scheduler_warp:
            self.sched_warp_id = 6
            warp_ids.append(self.sched_warp_id)
        self.threads_per_cta = self.threads_per_warp * len(warp_ids)

    def get_gmem_workspace_size(self, problem_shape_mnl) -> int:
        """Bytes of GMEM scratch the schedule needs for ``problem_shape_mnl``.

        :param problem_shape_mnl: problem extents (M, N, L) in elements
        :type problem_shape_mnl: Sequence[int]
        """
        return self.tile_scheduler_template.get_gmem_workspace_size(problem_shape_mnl)

    def initialize_workspace(self, workspace, problem_shape_mnl) -> None:
        """Populate the GMEM workspace before the kernel reads it.

        :param workspace: 1-D int8 buffer of ``get_gmem_workspace_size`` bytes
        :param problem_shape_mnl: problem extents (M, N, L) in elements
        """
        self.tile_scheduler_template.initialize_workspace(workspace, problem_shape_mnl)

    @staticmethod
    def needs_unpack_tma(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """
        Decide whether TMA must use the UNPACK_U8 variant (U4_UNPACK_U8 /
        U6_UNPACK_U8) for narrow-precision operands.

        Unpack is required when:
          * Operand widths differ (mxf8f6f4 mixed-precision) — A and B must
            share a uniform byte-per-element SMEM layout, so the narrower
            operand is unpacked into 1B/elem containers in SMEM.
          * Either operand is 6-bit — there is no packed U6 TMA format,
            only U6_UNPACK_U8 exists.

        Otherwise (same-width and no 6-bit operand, e.g. f4xf4 / f8xf8 /
        f8E4M3xf8E5M2) TMA can use the natural packed format (U4 for 4-bit,
        U8 for 8-bit).

        :param a_dtype: Element data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: Element data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :return: True if UNPACK_U8 TMA format must be used, False otherwise
        :rtype: bool
        """
        if a_dtype.width != b_dtype.width:
            return True
        if a_dtype.width == 6 or b_dtype.width == 6:
            return True
        return False

    @staticmethod
    def is_valid_dtypes_and_scale_factor_vec_size(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        c_dtype: Type[cutlass.Numeric],
    ) -> bool:
        """
        Check if the dtypes and sf_vec_size are valid combinations

        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param sf_dtype: The data type of the scale factor
        :type sf_dtype: Type[cutlass.Numeric]
        :param sf_vec_size: The vector size of the scale factor
        :type sf_vec_size: int
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]

        :return: True if the dtypes and sf_vec_size are valid, False otherwise
        :rtype: bool
        """
        supported_ab_dtypes = {
            cutlass.Float4E2M1FN,
            cutlass.Float6E2M3FN,
            cutlass.Float6E3M2FN,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }

        # Check A/B element types
        if a_dtype not in supported_ab_dtypes or b_dtype not in supported_ab_dtypes:
            return False

        # Check SF element type
        if sf_dtype not in {cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN}:
            return False

        # sf_vec_size rules:
        #   * 16 is only supported for Float4E2M1FN x Float4E2M1FN (NVF4 / MXF4 fp4-pair)
        #   * 32 is required for every other A/B combination (MXF8, mxf8f6f4 mixed, MXF4-pair with MX scaling)
        # SF dtype pairing with sf_vec_size:
        #   * sf_vec_size == 16 requires sf_dtype in {Float8E4M3FN (NVF4), Float8E8M0FNU (MXF4)}
        #   * sf_vec_size == 32 requires sf_dtype == Float8E8M0FNU (MX scaling)
        both_fp4 = a_dtype is cutlass.Float4E2M1FN and b_dtype is cutlass.Float4E2M1FN
        if sf_vec_size == 16:
            if not both_fp4:
                return False
        elif sf_vec_size == 32:
            if sf_dtype is not cutlass.Float8E8M0FNU:
                return False
        else:
            return False

        # Check valid c_dtype
        if c_dtype not in {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        }:
            return False

        return True

    @staticmethod
    def is_valid_layouts(
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        a_major: Literal["m", "k"],
        b_major: Literal["n", "k"],
        c_major: Literal["m", "n"],
    ) -> bool:
        """
        Check if layouts and dtypes are valid combinations

        :param a_dtype: The data type of the A operand
        :type a_dtype: Type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: Type[cutlass.Numeric]
        :param c_dtype: The data type of the output tensor
        :type c_dtype: Type[cutlass.Numeric]
        :param a_major: The major dimension of the A tensor
        :type a_major: Literal["m", "k"]
        :param b_major: The major dimension of the B tensor
        :type b_major: Literal["n", "k"]
        :param c_major: The major dimension of the C tensor
        :type c_major: Literal["m", "n"]

        :return: True if the layouts are valid, False otherwise
        :rtype: bool
        """
        is_valid = True

        # FP4 operands can only be k-major (checked per operand)
        if a_dtype is cutlass.Float4E2M1FN and a_major != "k":
            is_valid = False
        if b_dtype is cutlass.Float4E2M1FN and b_major != "k":
            is_valid = False
        # FP4 output must be n-major
        if c_dtype is cutlass.Float4E2M1FN and c_major == "m":
            is_valid = False

        return is_valid

    @staticmethod
    def is_valid_mma_tiler_and_cluster_shape(
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
    ) -> bool:
        """
        Check if the mma tiler and cluster shape are valid

        :param mma_tiler_mn: The (M, N) shape of the MMA instruction tiler
        :type mma_tiler_mn: Tuple[int, int]
        :param cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster
        :type cluster_shape_mn: Tuple[int, int]

        :return: True if the mma tiler and cluster shape are valid, False otherwise
        :rtype: bool
        """
        is_valid = True
        # Skip invalid mma tile shape
        if mma_tiler_mn[0] not in [128, 256]:
            is_valid = False
        if mma_tiler_mn[1] not in [64, 128, 192, 256]:
            is_valid = False
        # Skip illegal cluster shape
        if cluster_shape_mn[0] % (2 if mma_tiler_mn[0] == 256 else 1) != 0:
            is_valid = False
        # Skip invalid cluster shape
        is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
        if (
            cluster_shape_mn[0] * cluster_shape_mn[1] > 16
            or cluster_shape_mn[0] <= 0
            or cluster_shape_mn[1] <= 0
            # Special cluster shape check for scale factor multicasts.
            # Due to limited size of scale factors, we can't multicast among more than 4 CTAs.
            or cluster_shape_mn[0] > 4
            or cluster_shape_mn[1] > 4
            or not is_power_of_2(cluster_shape_mn[0])
            or not is_power_of_2(cluster_shape_mn[1])
        ):
            is_valid = False
        return is_valid

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
        mma_tiler_mn: Tuple[int, int],
    ) -> bool:
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
        :param mma_tiler_mn: The (M, N) shape of the MMA instruction tiler,
            needed to verify per-CTA UNPACK alignment under 2CTA MMA.
        :type mma_tiler_mn: Tuple[int, int]

        :return: True if the problem shape is valid, False otherwise
        :rtype: bool
        """
        is_valid = True

        def check_contigous_16B_alignment(dtype, is_mode0_major, tensor_shape):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            # TMA requires the contiguous inner dimension to be a multiple of
            # 16 B (= 128 bits). Work in bits so non-byte-aligned widths
            # (e.g. 6-bit) are handled correctly: 16 * 8 // dtype.width is
            # wrong when dtype.width does not divide 128 (it returns 21 for
            # 6-bit instead of the real requirement K*6 % 128 == 0).
            return (num_major_elements * dtype.width) % (16 * 8) == 0

        def check_contigous_128_alignment(dtype, is_mode0_major, tensor_shape):
            # we only need to check alignment for subbyte dtype
            if dtype.width >= 8:
                return True
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 128
            return num_major_elements % num_contiguous_elements == 0

        if (
            not check_contigous_16B_alignment(a_dtype, a_major == "m", (m, k, l))
            or not check_contigous_16B_alignment(b_dtype, b_major == "n", (n, k, l))
            or not check_contigous_16B_alignment(c_dtype, c_major == "m", (m, n, l))
        ):
            is_valid = False
        # When an operand is loaded via the UNPACK TMA variant
        # (U4_UNPACK_U8 or U6_UNPACK_U8), its inner tensor dimension in bytes
        # must be a multiple of 64B (4-bit) or 96B (6-bit); both work out to
        # a multiple of 128 elements along the contiguous dim. The check only
        # applies to sub-byte operands and only when the pair triggers UNPACK.
        if Sm100BlockScaledPersistentDenseGemmKernel.needs_unpack_tma(
            a_dtype, b_dtype
        ) and (
            not check_contigous_128_alignment(a_dtype, a_major == "m", (m, k, l))
            or not check_contigous_128_alignment(b_dtype, b_major == "n", (n, k, l))
        ):
            is_valid = False
        # Additional UNPACK constraint for any sub-byte operand on its contig
        # axis: when a sub-byte A is m-major (contig=M) or a sub-byte B is
        # n-major (contig=N), the MMA tile's contig dim (after 2CTA M-split,
        # which splits M for both A and B on the non-multicast atom path)
        # must be a multiple of 128 elements to satisfy the 64B (fp4) /
        # 96B (fp6) inner-dim requirement of U4_/U6_UNPACK_U8. Observed
        # failures: (128,192)/(1,1)/m-n-m (1CTA) and (256,128)/(2,2)/m-n-m
        # (2CTA) trigger CUDA illegal instruction for fp6 when mma_tiler_N
        # (or N/2 after 2CTA split) is not a 128-multiple; the same rule
        # applies to any other sub-byte operand on its non-K contig axis.
        use_2cta_instrs = mma_tiler_mn[0] == 256
        cta_div = 2 if use_2cta_instrs else 1
        if (
            Sm100BlockScaledPersistentDenseGemmKernel.needs_unpack_tma(a_dtype, b_dtype)
            and a_major == "m"
            and a_dtype.width < 8
            and (mma_tiler_mn[0] // cta_div) % 128 != 0
        ):
            is_valid = False
        if (
            Sm100BlockScaledPersistentDenseGemmKernel.needs_unpack_tma(a_dtype, b_dtype)
            and b_major == "n"
            and b_dtype.width < 8
            and (mma_tiler_mn[1] // cta_div) % 128 != 0
        ):
            is_valid = False
        return is_valid


def scaled_mm(
    gemm_obj: Sm100BlockScaledPersistentDenseGemmKernel,
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
    stream: cuda.CUstream,
    swizzle_size: Int32,
    raster_along_m: Boolean,
    max_active_clusters_fallback: Int32,
    epilogue_op: cutlass.Constexpr = lambda x: x,
    options: str = "",
):
    """Compile the blockscaled GEMM for the given dtypes and majors."""
    a_ptr = make_ptr(a_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    b_ptr = make_ptr(b_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    c_ptr = make_ptr(c_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=16)
    sfa_ptr = make_ptr(sf_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=32)
    sfb_ptr = make_ptr(sf_dtype, 0, cutlass.AddressSpace.gmem, assumed_align=32)
    workspace_ptr = make_ptr(
        cutlass.Int8, 0, cutlass.AddressSpace.gmem, assumed_align=16
    )

    a_major_mode = OperandMajorMode.K if a_major == "k" else OperandMajorMode.MN
    b_major_mode = OperandMajorMode.K if b_major == "k" else OperandMajorMode.MN
    c_layout = (
        cutlass.tensor_utils.LayoutEnum.ROW_MAJOR
        if c_major == "n"
        else cutlass.tensor_utils.LayoutEnum.COL_MAJOR
    )
    return cute.compile(
        gemm_obj,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        workspace_ptr,
        (a_major_mode, b_major_mode, c_layout),
        (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
        stream,
        swizzle_size,
        raster_along_m,
        max_active_clusters_fallback,
        epilogue_op,
        options=options,
    )
