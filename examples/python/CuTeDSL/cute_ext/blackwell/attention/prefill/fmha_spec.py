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

from dataclasses import dataclass, replace
from typing import Optional, Tuple, Type, Union

import cutlass

from helpers import fmha_helpers as fmha_utils


@dataclass(frozen=True)
class FmhaKernelSpec:
    qk_acc_dtype: Type[cutlass.Numeric]
    pv_acc_dtype: Type[cutlass.Numeric]
    mma_tiler: Tuple[int, int]
    head_dim: int
    head_dim_v: int
    cta_tiler: Tuple[int, int, int]
    qk_mma_tiler: Tuple[int, int, int]
    pv_mma_tiler: Tuple[int, int, int]
    cluster_shape_mn: Tuple[int, int]
    is_persistent: bool
    mask_type: fmha_utils.MaskEnum
    enable_ex2_emulation: bool
    enable_skip_correction: bool
    q_dtype: Optional[Type[cutlass.Numeric]] = None
    k_dtype: Optional[Type[cutlass.Numeric]] = None
    v_dtype: Optional[Type[cutlass.Numeric]] = None
    o_dtype: Optional[Type[cutlass.Numeric]] = None

    softmax0_warp_ids: Tuple[int, ...] = (0, 1, 2, 3)
    softmax1_warp_ids: Tuple[int, ...] = (4, 5, 6, 7)
    correction_warp_ids: Tuple[int, ...] = (8, 9, 10, 11)
    mma_warp_id: int = 12
    load_warp_id: int = 13
    epilogue_warp_id: int = 14
    empty_warp_id: int = 15

    tmem_s0_offset: int = 0
    tmem_s1_offset: int = 128
    tmem_o0_offset: int = 256
    tmem_o1_offset: int = 384
    tmem_p0_offset: int = 160
    tmem_p1_offset: int = 32
    tmem_vec0_offset: int = 0
    tmem_vec1_offset: int = 128

    num_regs_softmax: int = 192
    num_regs_correction: int = 96
    num_regs_other: int = 32

    q_stage: int = 2
    p_mma_stage: int = 1
    acc_stage: int = 1
    softmax_corr_stage: int = 1
    mma_corr_stage: int = 2
    mma_softmax_stage: int = 1
    epi_stage: int = 2
    threads_per_warp: int = 32
    buffer_align_bytes: int = 1024

    @property
    def threads_per_cta(self) -> int:
        return self.threads_per_warp * len(self.all_warp_ids)

    @property
    def cluster_shape_mnk(self) -> Tuple[int, int, int]:
        return (*self.cluster_shape_mn, 1)

    @property
    def epi_tile(self) -> Tuple[int, int]:
        return self.pv_mma_tiler[:2]

    @property
    def softmax_warpgroup_count(self) -> int:
        num_warps_per_warpgroup = 4
        return len(self.softmax_warp_ids) // num_warps_per_warpgroup

    @property
    def softmax_warp_ids(self) -> Tuple[int, ...]:
        return (*self.softmax0_warp_ids, *self.softmax1_warp_ids)

    @property
    def all_warp_ids(self) -> Tuple[int, ...]:
        return (
            *self.softmax0_warp_ids,
            *self.softmax1_warp_ids,
            *self.correction_warp_ids,
            self.mma_warp_id,
            self.load_warp_id,
            self.epilogue_warp_id,
            self.empty_warp_id,
        )

    @property
    def tmem_alloc_warp_ids(self) -> Tuple[int, ...]:
        return (
            self.mma_warp_id,
            *self.softmax0_warp_ids,
            *self.softmax1_warp_ids,
            *self.correction_warp_ids,
        )

    @property
    def kv_stage(self) -> int:
        # TODO: adopt the CuTeDSL baseline's gmem latency-hiding config -- a
        # 4th KV stage for 16-bit dtypes, funded by dropping the sO SMEM
        # buffer, plus the 88/40 register split. This kernel is
        # TMA-store-only today, so it needs a non-TMA (STG) epilogue path
        # first; the extra stage is not free otherwise.
        assert self.q_dtype is not None
        if self.head_dim == 192 and self.q_dtype.width == 16:
            return 2
        return 4 if self.q_dtype.width == 8 else 3

    def with_dtypes(
        self,
        q_dtype: Type[cutlass.Numeric],
        k_dtype: Type[cutlass.Numeric],
        v_dtype: Type[cutlass.Numeric],
        o_dtype: Type[cutlass.Numeric],
    ) -> "FmhaKernelSpec":
        return replace(
            self,
            q_dtype=q_dtype,
            k_dtype=k_dtype,
            v_dtype=v_dtype,
            o_dtype=o_dtype,
        )


def make_fmha_spec(
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    mma_tiler: Tuple[int, int],
    head_dim: Union[int, Tuple[int, int]],
    is_persistent: bool,
    mask_type: fmha_utils.MaskEnum,
    enable_ex2_emulation: bool,
    enable_skip_correction: bool,
) -> FmhaKernelSpec:
    if isinstance(head_dim, tuple):
        head_dim_qk, head_dim_v = head_dim
        assert head_dim_qk == 192 and head_dim_v == 128, (
            f"When Headdim is a tuple, it's for MLA. Must be (192, 128), but got {head_dim}"
        )
    else:
        head_dim_qk = head_dim
        head_dim_v = head_dim

    return FmhaKernelSpec(
        qk_acc_dtype=qk_acc_dtype,
        pv_acc_dtype=pv_acc_dtype,
        mma_tiler=mma_tiler,
        head_dim=head_dim_qk,
        head_dim_v=head_dim_v,
        cta_tiler=(
            2 * mma_tiler[0],
            mma_tiler[1],
            head_dim_v,
        ),
        qk_mma_tiler=(
            *mma_tiler,
            head_dim_qk,
        ),
        pv_mma_tiler=(
            mma_tiler[0],
            head_dim_v,
            mma_tiler[1],
        ),
        cluster_shape_mn=(1, 1),
        is_persistent=is_persistent,
        mask_type=mask_type,
        enable_ex2_emulation=enable_ex2_emulation,
        enable_skip_correction=enable_skip_correction,
    )
