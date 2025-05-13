# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
import enum
import math
import time
from typing import Type, Tuple

import torch
import torch.nn.functional as F
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.cute.nvgpu.tcgen05 as tcgen05
import cutlass.utils as utils
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack

"""
A fused multi-head attention (FMHA) example for the NVIDIA Blackwell SM100 architecture using CUTE DSL

This example demonstrates an implementation of fused multi-head attention using a TMA + Blackwell SM100
TensorCore warp-specialized persistent kernel. The implementation integrates the Q*K^T matrix multiplication,
softmax normalization, and softmax(Q*K^T)*V into a single kernel, avoiding intermediate data movement between
global memory and shared memory, thus improving computational efficiency.

The kernel implements key optimizations including:
- Warp specialization for different computation phases (load, MMA, softmax, correction, epilogue)
- Pipeline stages between different warps for overlapping computation and memory access
- Support for different precision data types
- Optional causal masking for autoregressive models

To run this example:

.. code-block:: bash

    python examples/blackwell/fmha.py                                     \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                       \
      --mma_tiler_mn 128,128                                              \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                         \
      --is_persistent

The above example runs FMHA with batch size 4, sequence length 1024, 8 attention heads, and head
dimension 64. The Blackwell tcgen05 MMA tile shape is (128, 128), and the kernel uses fp16 for input/output
with fp32 for accumulation.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/blackwell/fmha.py                                 \
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                       \
      --mma_tiler_mn 128,128                                              \
      --q_shape 4,1024,8,64 --k_shape 4,1024,8,64                         \
      --is_persistent --warmup_iterations 10                              \
      --iterations 10 --skip_ref_check

Constraints for this example:
* Supported head dimensions: 32, 64, and 128
* Number of heads in Q must be divisible by number of heads in K
* mma_tiler_mn must be 128,128
* Batch size must be the same for Q, K, and V tensors
* For causal masking, use --has_casual_mask (note: specify without =True/False)
* For persistent scheduling, use --is_persistent (note: specify without =True/False)
"""

class FmhaStaticTileSchedulerParams:
    def __init__(
        self,
        is_persistent: bool,
        problem_shape_mbh: cute.Shape,
        *,
        loc=None,
        ip=None,
    ):
        self.is_persistent = is_persistent
        self.problem_shape_mbh = problem_shape_mbh
        self._loc = loc
        self._ip = ip

    def __extract_mlir_values__(self):
        values, self._values_pos = [], []
        for obj in [self.is_persistent, self.problem_shape_mbh]:
            obj_values = cutlass.extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(self, values):
        obj_list = []
        for obj, n_items in zip(
            [self.is_persistent, self.problem_shape_mbh], self._values_pos
        ):
            obj_list.append(cutlass.new_from_mlir_values(obj, values[:n_items]))
            values = values[n_items:]
        return FmhaStaticTileSchedulerParams(*(tuple(obj_list)), loc=self._loc)


def create_fmha_static_tile_scheduler_params(
    is_persistent: bool,
    problem_shape_mbh: cute.Shape,
) -> FmhaStaticTileSchedulerParams:
    return FmhaStaticTileSchedulerParams(is_persistent, problem_shape_mbh)


class FmhaStaticTileScheduler:

    def __init__(
        self,
        params: FmhaStaticTileSchedulerParams,
        current_work_linear_idx: cutlass.Int32,
        blk_coord: cute.Coord,
        grid_shape: cute.Shape,
        *,
        loc=None,
        ip=None,
    ):
        self._params = params
        self._blk_coord = blk_coord
        self._grid_shape = grid_shape
        self._is_persistent = params.is_persistent
        self._current_work_linear_idx = current_work_linear_idx
        self._problem_shape_mbh = cute.make_layout(
            params.problem_shape_mbh, loc=loc, ip=ip
        )
        self._num_blocks = cute.size(self._problem_shape_mbh, loc=loc, ip=ip)
        self._is_first_block = True
        self.num_persistent_sm = cute.size(grid_shape, loc=loc, ip=ip)
        self._loc = loc
        self._ip = ip

    # called by host
    @staticmethod
    def get_grid_shape(
        params: FmhaStaticTileSchedulerParams,
        *,
        loc=None,
        ip=None,
    ) -> cute.Shape:
        if params.is_persistent:
            hardware_info = cutlass.utils.HardwareInfo()
            sm_count = hardware_info.get_device_multiprocessor_count()
            return (
                cutlass.min(
                    sm_count, cute.size(params.problem_shape_mbh, loc=loc, ip=ip)
                ),
                1,
                1,
            )
        else:
            return params.problem_shape_mbh

    def get_current_work(self, *, loc=None, ip=None) -> utils.WorkTileInfo:
        is_valid = (
            self._current_work_linear_idx < self._num_blocks
            if self._is_persistent
            else self._is_first_block
        )

        blk_coord = (0, 0, 0)
        if self._is_persistent:
            blk_coord = self._problem_shape_mbh.get_hier_coord(
                self._current_work_linear_idx, loc=loc, ip=ip
            )
        else:
            blk_coord = self._blk_coord

        # cur_tile_coord is (mid, 0, (bid, hid))
        cur_tile_coord = (
            blk_coord[0],
            0,
            (blk_coord[1], blk_coord[2]),
        )

        return utils.WorkTileInfo(cur_tile_coord, is_valid)

    def initial_work_tile_info(self, *, loc=None, ip=None):
        return self.get_current_work(loc=loc, ip=ip)

    def advance_to_next_work(self, *, advance_count=1, loc=None, ip=None):
        if self._is_persistent:
            self._current_work_linear_idx += advance_count * self.num_persistent_sm
        self._is_first_block = False

    def __extract_mlir_values__(self):
        values = cutlass.extract_mlir_values(self._params)
        values.extend(cutlass.extract_mlir_values(self._current_work_linear_idx))
        values.extend(cutlass.extract_mlir_values(self._blk_coord))
        values.extend(cutlass.extract_mlir_values(self._grid_shape))
        return values

    def __new_from_mlir_values__(self, values):
        assert len(values) == 10
        new_params = cutlass.new_from_mlir_values(self._params, values[0:3])
        new_current_work_linear_idx = cutlass.new_from_mlir_values(
            self._current_work_linear_idx, [values[3]]
        )
        new_blk_coord = cutlass.new_from_mlir_values(self._blk_coord, values[4:7])
        new_grid_shape = cutlass.new_from_mlir_values(self._grid_shape, values[7:])
        return FmhaStaticTileScheduler(
            new_params, new_current_work_linear_idx, new_blk_coord, new_grid_shape
        )


def create_fmha_static_tile_scheduler(
    params: FmhaStaticTileSchedulerParams,
    blk_coord: cute.Coord,
    grid_shape: cute.Shape,
) -> FmhaStaticTileScheduler:
    return FmhaStaticTileScheduler(params, blk_coord[0], blk_coord, grid_shape)


class MaskType(enum.Enum):
    NO_MASK = enum.auto()
    RESIDUAL_MASK = enum.auto()
    CAUSAL_MASK = enum.auto()


class FusedMask:
    def __init__(
        self,
        mask_type: MaskType,
        seq_len_k: cutlass.Int32,
        *,
        loc=None,
        ip=None,
    ):
        self._mask_type = mask_type
        self._seq_len_k = seq_len_k
        self._loc = loc
        self._ip = ip

    def get_trip_count(
        self,
        blk_coord: cute.Coord,
        tile_shape: cute.Shape,
    ) -> cutlass.Int32:
        result = 0
        if (
            self._mask_type == MaskType.NO_MASK
            or self._mask_type == MaskType.RESIDUAL_MASK
        ):
            result = cute.ceil_div(self._seq_len_k, tile_shape[1])
        elif self._mask_type == MaskType.CAUSAL_MASK:
            max_blocks_k = cute.ceil_div(self._seq_len_k, tile_shape[1])
            max_blocks_q = cute.ceil_div(
                (blk_coord[0] + 1) * tile_shape[0], tile_shape[1]
            )
            result = cutlass.min(max_blocks_k, max_blocks_q)
        return result

    @cute.jit
    def get_masked_trip_count(
        self,
        blk_coord: cute.Coord,
        tile_shape: cute.Shape,
    ) -> cutlass.Int32:
        result = 0
        if self._mask_type == MaskType.NO_MASK:
            result = 0
        elif self._mask_type == MaskType.RESIDUAL_MASK:
            if self._seq_len_k % tile_shape[1] != 0:
                result = 1
            else:
                result = 0
        elif self._mask_type == MaskType.CAUSAL_MASK:
            result = cute.ceil_div(tile_shape[0], tile_shape[1])
        return result

    @cute.jit
    def get_unmasked_trip_count(
        self,
        blk_coord: cute.Coord,
        tile_shape: cute.Shape,
    ) -> cutlass.Int32:
        result = 0
        if self._mask_type == MaskType.NO_MASK:
            result = self.get_trip_count(blk_coord, tile_shape)
        elif self._mask_type == MaskType.RESIDUAL_MASK:
            if self._seq_len_k % tile_shape[1] != 0:
                result = self.get_trip_count(blk_coord, tile_shape) - 1
            else:
                result = self.get_trip_count(blk_coord, tile_shape)
        elif self._mask_type == MaskType.CAUSAL_MASK:
            result = self.get_trip_count(
                blk_coord, tile_shape
            ) - self.get_masked_trip_count(blk_coord, tile_shape)
        return result

    @cute.jit
    def apply_mask(
        self,
        acc_qk: cute.Tensor,
        index_qk: cute.Tensor,
    ):
        if self._mask_type == MaskType.RESIDUAL_MASK:
            for i in range(cute.size(acc_qk)):
                pos = index_qk[i]
                if pos[1] >= self._seq_len_k:
                    acc_qk[i] = -cutlass.Float32.inf
        elif self._mask_type == MaskType.CAUSAL_MASK:
            for i in range(cute.size(acc_qk)):
                pos = index_qk[i]
                if pos[0] < pos[1] or pos[1] >= self._seq_len_k:
                    acc_qk[i] = -cutlass.Float32.inf

    def __extract_mlir_values__(self):
        values, self._values_pos = [], []
        for obj in [self._mask_type, self._seq_len_k]:
            obj_values = cutlass.extract_mlir_values(obj)
            values += obj_values
            self._values_pos.append(len(obj_values))
        return values

    def __new_from_mlir_values__(self, values):
        obj_list = []
        for obj, n_items in zip([self._mask_type, self._seq_len_k], self._values_pos):
            obj_list.append(cutlass.new_from_mlir_values(obj, values[:n_items]))
            values = values[n_items:]
        return FusedMask(*(tuple(obj_list)), loc=self._loc)


def create_fused_mask(
    mask_type: MaskType,
    seq_len_k: cutlass.Int32,
) -> FusedMask:
    return FusedMask(mask_type, seq_len_k)


class BlackwellFusedMultiHeadAttentionForward:
    def __init__(
        self,
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        mma_tiler: Tuple[int, int, int],
        is_persistent: bool,
        mask_type: MaskType,
    ):
        """Initializes the configuration for a Blackwell Fused Multi-Head Attention (FMHA) kernel.

        This configuration includes several key aspects:

        1.  Data Type Settings:
            - qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
            - pv_acc_dtype: Data type for P*V matrix multiplication accumulator

        2.  MMA Instruction Settings:
            - mma_tiler: The (M, N, K) shape of the MMA instruction unit
            - qk_mma_tiler: MMA shape for Q*K^T computation
            - pv_mma_tiler: MMA shape for P*V computation

        3.  Kernel Execution Mode:
            - is_persistent: Boolean indicating whether to use persistent kernel mode
            - mask_type: Specifies the type of mask to use (no mask, residual mask, or causal mask)

        :param qk_acc_dtype: Data type for Q*K^T matrix multiplication accumulator
        :type qk_acc_dtype: Type[cutlass.Numeric]
        :param pv_acc_dtype: Data type for P*V matrix multiplication accumulator
        :type pv_acc_dtype: Type[cutlass.Numeric]
        :param mma_tiler: The (M, N, K) shape of the MMA instruction
        :type mma_tiler: Tuple[int, int, int]
        :param is_persistent: Whether to use persistent kernel mode
        :type is_persistent: bool
        :param mask_type: Type of mask to use
        :type mask_type: MaskType
        """

        self.qk_acc_dtype = qk_acc_dtype
        self.pv_acc_dtype = pv_acc_dtype
        self.cta_tiler = (
            2 * mma_tiler[0],  # 2 Q tile per CTA
            mma_tiler[1],
            mma_tiler[2],
        )
        self.qk_mma_tiler = mma_tiler
        self.pv_mma_tiler = (
            mma_tiler[0],
            mma_tiler[2],
            mma_tiler[1],
        )
        self.cluster_shape_mn = (1, 1)
        self.is_persistent = is_persistent
        self.mask_type = mask_type

        self.softmax0_warp_ids = (0, 1, 2, 3)
        self.softmax1_warp_ids = (4, 5, 6, 7)
        self.correction_warp_ids = (8, 9, 10, 11)
        self.mma_warp_id = 12
        self.load_warp_id = 13
        self.epilogue_warp_id = 14
        self.empty_warp_id = 15
        SM100_TMEM_CAPACITY_COLUMNS = 512
        self.tmem_alloc_cols = SM100_TMEM_CAPACITY_COLUMNS

        self.threads_per_warp = 32
        self.threads_per_cta = self.threads_per_warp * len(
            (
                *self.softmax0_warp_ids,
                *self.softmax1_warp_ids,
                *self.correction_warp_ids,
                self.mma_warp_id,
                self.load_warp_id,
                self.epilogue_warp_id,
                self.empty_warp_id,
            )
        )

        self.cta_sync_bar_id = 0
        self.tmem_alloc_sync_bar_id = 1

        self.tmem_s0_offset = 0
        self.tmem_s1_offset = 128
        self.tmem_o0_offset = 256
        self.tmem_o1_offset = 384
        self.tmem_p0_offset = 32
        self.tmem_p1_offset = 160

        # vec buffer for row_max & row_sum
        self.tmem_vec0_offset = 0
        self.tmem_vec1_offset = 128

        self.num_regs_softmax = 192
        self.num_regs_correction = 96
        self.num_regs_other = 32
        self.num_regs_empty = 24

        self.buffer_align_bytes = 1024

        num_warps_per_warpgroup = 4
        self.softmax_warpgroup_count = (
            len((*self.softmax0_warp_ids, *self.softmax1_warp_ids))
            // num_warps_per_warpgroup
        )

    def _setup_attributes(self):
        """Set up configurations and parameters for the FMHA kernel operation.

        This method initializes and configures various attributes required for the
        execution of the fused multi-head attention kernel, mainly about the pipeline stages:

        - Sets up staging parameters for Q, K, V inputs and accumulator data
        - Configures pipeline stages for softmax, correction, and epilogue operations
        """

        self.q_stage = 2
        self.kv_stage = 4 if self.q_dtype.width == 8 else 3
        self.acc_stage = 1
        self.softmax_corr_stage = 1
        self.mma_corr_stage = 2
        self.mma_softmax_stage = 1
        self.epi_stage = 2

    @cute.jit
    def __call__(
        self,
        q: cute.Tensor,
        k: cute.Tensor,
        v: cute.Tensor,
        o: cute.Tensor,
        scale_softmax_log2: cutlass.Float32,
        scale_output: cutlass.Float32,
        stream: cuda.CUstream,
    ):
        """Execute the Fused Multi-Head Attention operation on the provided tensors.

        This method prepares the input tensors for processing, validates their shapes and types,
        configures the computation parameters, and launches the CUDA kernel.

        The method handles:
        1. Tensor layout transformations for specific memory access patterns
        2. Validation of tensor shapes and data types
        3. Initialization of hardware-specific parameters and memory layouts
        4. Configuration of TMA (Tensor Memory Access) operations
        5. Grid and work scheduling computation
        6. Kernel launch with appropriate parameters

        :param q: The query tensor with shape [seq_len_q, d_head, h_q, b]
        :type q: cute.Tensor
        :param k: The key tensor with shape [seq_len_k, d_head, h_k, b]
        :type k: cute.Tensor
        :param v: The value tensor with shape [seq_len_k, d_head, h_v, b]
        :type v: cute.Tensor
        :param o: The output tensor with shape [seq_len_q, d_head, h_q, b]
        :type o: cute.Tensor
        :param scale_softmax_log2: The log2 scale factor for softmax
        :type scale_softmax_log2: cutlass.Float32
        :param scale_output: The scale factor for the output
        :type scale_output: cutlass.Float32
        :param stream: The CUDA stream to execute the kernel on
        :type stream: cuda.CUstream
        :raises TypeError: If tensor data types don't match or aren't supported
        :raises RuntimeError: If tensor layouts aren't in supported formats
        """

        # setup static attributes before smem/grid/tma computation
        self.q_dtype = q.element_type
        self.k_dtype = k.element_type
        self.v_dtype = v.element_type
        self.o_dtype = o.element_type

        # (s, d, 1, h_k, b) -> (s, d, ((h_r, h_k), b))
        k = cute.make_tensor(
            k.iterator,
            cute.make_layout(
                (k.shape[0], k.shape[1], ((q.shape[2], k.shape[3]), k.shape[4])),
                stride=(
                    k.layout.stride[0],
                    k.layout.stride[1],
                    ((0, k.layout.stride[3]), k.layout.stride[4]),
                ),
            ),
        )
        # (s, d, 1, h_k, b) -> (d, s, ((h_r, h_k), b))
        v = cute.make_tensor(
            v.iterator,
            cute.make_layout(
                (v.shape[1], v.shape[0], ((q.shape[2], v.shape[3]), v.shape[4])),
                stride=(
                    v.layout.stride[1],
                    v.layout.stride[0],
                    ((0, v.layout.stride[3]), v.layout.stride[4]),
                ),
            ),
        )

        # (s, d, h_r, h_k, b) -> (s, d, ((h_r, h_k), b))
        q = cute.group_modes(cute.group_modes(q, begin=2, end=4), begin=2, end=4)
        o = cute.group_modes(cute.group_modes(o, begin=2, end=4), begin=2, end=4)

        self.q_major_mode = utils.LayoutEnum.from_tensor(q).mma_major_mode()
        self.k_major_mode = utils.LayoutEnum.from_tensor(k).mma_major_mode()
        self.v_major_mode = utils.LayoutEnum.from_tensor(v).mma_major_mode()
        self.o_layout = utils.LayoutEnum.from_tensor(o)

        if cutlass.const_expr(self.q_major_mode != tcgen05.OperandMajorMode.K):
            raise RuntimeError("The layout of q is not supported")
        if cutlass.const_expr(self.k_major_mode != tcgen05.OperandMajorMode.K):
            raise RuntimeError("The layout of k is not supported")
        if cutlass.const_expr(self.v_major_mode != tcgen05.OperandMajorMode.MN):
            raise RuntimeError("The layout of v is not supported")

        # check type consistency
        if cutlass.const_expr(self.q_dtype != self.k_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.k_dtype}")
        if cutlass.const_expr(self.q_dtype != self.v_dtype):
            raise TypeError(f"Type mismatch: {self.q_dtype} != {self.v_dtype}")
        self._setup_attributes()

        cta_group = tcgen05.CtaGroup.ONE
        # the intermediate tensor p is from tmem & k-major
        p_source = tcgen05.OperandSource.TMEM
        p_major_mode = tcgen05.OperandMajorMode.K
        qk_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            cta_group,
            self.qk_mma_tiler[:2],
        )
        pv_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            self.pv_mma_tiler[:2],
            p_source,
        )

        self.cluster_shape_mnk = (*self.cluster_shape_mn, 1)
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape_mnk),
            (qk_tiled_mma.thr_id.shape,),
        )

        self.epi_tile = self.pv_mma_tiler[:2]


        q_smem_layout_staged = sm100_utils.make_smem_layout_a(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.q_dtype,
            self.q_stage,
        )
        k_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.k_dtype,
            self.kv_stage,
        )
        p_tmem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.q_dtype,
            self.acc_stage,
        )
        v_smem_layout_staged = sm100_utils.make_smem_layout_b(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.v_dtype,
            self.kv_stage,
        )
        o_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            self.o_dtype,
            self.o_layout,
            self.epi_tile,
            self.epi_stage,
        )

        # TMA load for Q
        tma_load_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(cta_group)
        tma_store_op = cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp()

        q_smem_layout = cute.select(q_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_q, tma_tensor_q = cute.nvgpu.make_tma_tile_atom_A(
            tma_load_op,
            q,
            q_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        # TMA load for K
        k_smem_layout = cute.select(k_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_k, tma_tensor_k = cute.nvgpu.make_tma_tile_atom_B(
            tma_load_op,
            k,
            k_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )
        # TMA load for V
        v_smem_layout = cute.select(v_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_v, tma_tensor_v = cute.nvgpu.make_tma_tile_atom_B(
            tma_load_op,
            v,
            v_smem_layout,
            self.pv_mma_tiler,
            pv_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )

        o_cta_v_layout = cute.composition(
            cute.make_identity_layout(o.shape), self.epi_tile
        )
        o_smem_layout = cute.select(o_smem_layout_staged, mode=[0, 1])

        tma_atom_o, tma_tensor_o = cute.nvgpu.cpasync.make_tma_tile_atom(
            tma_store_op,
            o,
            o_smem_layout,
            o_cta_v_layout,
        )

        q_copy_size = cute.size_in_bytes(self.q_dtype, q_smem_layout)
        k_copy_size = cute.size_in_bytes(self.k_dtype, k_smem_layout)
        self.tma_copy_q_bytes = q_copy_size
        self.tma_copy_kv_bytes = k_copy_size

        self.tile_sched_params, grid = self._compute_grid(
            o,
            self.cta_tiler,
            self.is_persistent,
        )

        @cute.struct
        class SharedStorage:
            # Pipeline barriers
            load_q_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.kv_stage * 2]
            mma_s0_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.mma_softmax_stage * 2
            ]
            mma_s1_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.mma_softmax_stage * 2
            ]
            s0_corr_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.softmax_corr_stage * 2
            ]
            s1_corr_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.softmax_corr_stage * 2
            ]
            s0_s1_sequence_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.softmax_warpgroup_count
            ]
            corr_epi_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.epi_stage * 2]
            mma_corr_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.mma_corr_stage * 2
            ]
            max_reg_setting_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1]
            tmem_dealloc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1]
            # Tmem holding buffer
            tmem_holding_buf: cutlass.Int32
            # Smem tensors
            sO: cute.struct.Align[
                cute.struct.MemRange[self.o_dtype, cute.cosize(o_smem_layout_staged)],
                self.buffer_align_bytes,
            ]
            sQ: cute.struct.Align[
                cute.struct.MemRange[self.q_dtype, cute.cosize(q_smem_layout_staged)],
                self.buffer_align_bytes,
            ]
            sK: cute.struct.Align[
                cute.struct.MemRange[self.k_dtype, cute.cosize(k_smem_layout_staged)],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage
        fused_mask = create_fused_mask(self.mask_type, k.shape[0])

        # Launch the kernel synchronously
        self.kernel(
            qk_tiled_mma,
            pv_tiled_mma,
            tma_atom_q,
            tma_tensor_q,
            tma_atom_k,
            tma_tensor_k,
            tma_atom_v,
            tma_tensor_v,
            tma_atom_o,
            tma_tensor_o,
            scale_softmax_log2,
            scale_output,
            q_smem_layout_staged,
            k_smem_layout_staged,
            p_tmem_layout_staged,
            v_smem_layout_staged,
            o_smem_layout_staged,
            self.tile_sched_params,
            fused_mask,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=self.cluster_shape_mnk,
            smem=self.shared_storage.size_in_bytes(),
            stream=stream,
            min_blocks_per_mp=1,
        )

    #  GPU device kernel
    @cute.kernel
    def kernel(
        self,
        qk_tiled_mma: cute.TiledMma,
        pv_tiled_mma: cute.TiledMma,
        tma_atom_q: cute.CopyAtom,
        mQ_qdl: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_kdl: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_dkl: cute.Tensor,
        tma_atom_o: cute.CopyAtom,
        mO_qdl: cute.Tensor,
        scale_softmax_log2: cutlass.Float32,
        scale_output: cutlass.Float32,
        q_smem_layout_staged: cute.ComposedLayout,
        k_smem_layout_staged: cute.ComposedLayout,
        p_tmem_layout_staged: cute.ComposedLayout,
        v_smem_layout_staged: cute.ComposedLayout,
        o_smem_layout_staged: cute.ComposedLayout,
        tile_sched_params: FmhaStaticTileSchedulerParams,
        fused_mask: FusedMask,
    ):
        """The device kernel implementation of the Fused Multi-Head Attention.

        This kernel coordinates multiple specialized warps to perform different phases of the FMHA computation:
        1. Load warp: Loads Q, K, V data from global memory to shared memory using TMA
        2. MMA warp: Performs matrix multiplications (Q*K^T and P*V)
        3. Softmax warps: Compute softmax normalization on attention scores
        4. Correction warps: Apply adjustments to intermediate results
        5. Epilogue warp: Handles final output transformation and storage

        The kernel implements a complex pipeline with overlapping computation and memory operations,
        using tensor memory access (TMA) for efficient data loading, warp specialization for different
        computation phases, and optional attention masking.

        :param qk_tiled_mma: Tiled MMA for Q*K^T
        :type qk_tiled_mma: cute.TiledMma
        :param pv_tiled_mma: Tiled MMA for P*V
        :type pv_tiled_mma: cute.TiledMma
        :param tma_atom_q: TMA copy atom for query tensor
        :type tma_atom_q: cute.CopyAtom
        :param mQ_qdl: Partitioned query tensor
        :type mQ_qdl: cute.Tensor
        :param tma_atom_k: TMA copy atom for key tensor
        :type tma_atom_k: cute.CopyAtom
        :param mK_kdl: Partitioned key tensor
        :type mK_kdl: cute.Tensor
        :param tma_atom_v: TMA copy atom for value tensor
        :type tma_atom_v: cute.CopyAtom
        :param mV_dkl: Partitioned value tensor
        :type mV_dkl: cute.Tensor
        :param tma_atom_o: TMA copy atom for output tensor
        :type tma_atom_o: cute.CopyAtom
        :param mO_qdl: Partitioned output tensor
        :type mO_qdl: cute.Tensor
        :param scale_softmax_log2: The log2 scale factor for softmax
        :type scale_softmax_log2: cutlass.Float32
        :param scale_output: The scale factor for the output
        :type scale_output: cutlass.Float32
        :param q_smem_layout_staged: Shared memory layout for query tensor
        :type q_smem_layout_staged: cute.ComposedLayout
        :param k_smem_layout_staged: Shared memory layout for key tensor
        :type k_smem_layout_staged: cute.ComposedLayout
        :param p_tmem_layout_staged: Tensor memory layout for probability matrix
        :type p_tmem_layout_staged: cute.ComposedLayout
        :param v_smem_layout_staged: Shared memory layout for value tensor
        :type v_smem_layout_staged: cute.ComposedLayout
        :param o_smem_layout_staged: Shared memory layout for output tensor
        :type o_smem_layout_staged: cute.ComposedLayout
        :param tile_sched_params: Scheduling parameters for work distribution
        :type tile_sched_params: FmhaStaticTileSchedulerParams
        :param fused_mask: Masking configuration (causal/residual/none)
        :type fused_mask: FusedMask
        """

        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        # coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        # Alloc
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        load_q_pipeline = self.make_and_init_load_q_pipeline(
            storage.load_q_mbar_ptr.data_ptr()
        )
        load_kv_pipeline = self.make_and_init_load_kv_pipeline(
            storage.load_kv_mbar_ptr.data_ptr()
        )
        mma_s0_pipeline = self.make_and_init_mma_si_pipeline(
            storage.mma_s0_mbar_ptr.data_ptr()
        )
        mma_s1_pipeline = self.make_and_init_mma_si_pipeline(
            storage.mma_s1_mbar_ptr.data_ptr()
        )
        s0_corr_pipeline = self.make_and_init_si_corr_pipeline(
            storage.s0_corr_mbar_ptr.data_ptr()
        )
        s1_corr_pipeline = self.make_and_init_si_corr_pipeline(
            storage.s1_corr_mbar_ptr.data_ptr()
        )
        corr_epi_pipeline = self.make_and_init_corr_epi_pipeline(
            storage.corr_epi_mbar_ptr.data_ptr()
        )
        mma_corr_pipeline = self.make_and_init_mma_corr_pipeline(
            storage.mma_corr_mbar_ptr.data_ptr()
        )
        s0_s1_sequence_pipeline = self.make_and_init_si_sequence_pipeline(
            storage.s0_s1_sequence_mbar_ptr.data_ptr()
        )
        max_reg_setting_mbar_ptr = storage.max_reg_setting_mbar_ptr.data_ptr()
        tmem_dealloc_mbar_ptr = storage.tmem_dealloc_mbar_ptr.data_ptr()

        #  Correction & Epilogue & tmem barrier init
        if warp_idx == self.empty_warp_id:
            cute.arch.mbarrier_init_arrive_cnt(
                max_reg_setting_mbar_ptr,
                self.threads_per_warp
                * len(
                    (
                        self.empty_warp_id,
                        self.load_warp_id,
                        self.mma_warp_id,
                        self.epilogue_warp_id,
                        *self.correction_warp_ids,
                    )
                ),
            )
            cute.arch.mbarrier_init_arrive_cnt(
                tmem_dealloc_mbar_ptr,
                self.threads_per_warp
                * len(
                    (
                        *self.softmax0_warp_ids,
                        *self.softmax1_warp_ids,
                        *self.correction_warp_ids,
                    )
                ),
            )

        cute.arch.mbarrier_init_fence()

        #  Generate smem tensor Q/K/V/O
        # (MMA, MMA_Q, MMA_D, PIPE)
        sQ = storage.sQ.get_tensor(
            q_smem_layout_staged.outer, swizzle=q_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        sK = storage.sK.get_tensor(
            k_smem_layout_staged.outer, swizzle=k_smem_layout_staged.inner
        )
        # (MMA, MMA_K, MMA_D, PIPE)
        # Strip swizzle info to reuse smem
        sV_ptr = cute.recast_ptr(sK.iterator, v_smem_layout_staged.inner)
        sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)

        sO = storage.sO.get_tensor(
            o_smem_layout_staged.outer, swizzle=o_smem_layout_staged.inner
        )

        # Local tile partition global tensors
        # (bM, bK, loopM, loopK, loopL)  need to check
        gQ_qdl = cute.flat_divide(mQ_qdl, cute.select(self.qk_mma_tiler, mode=[0, 2]))
        qk_thr_mma = qk_tiled_mma.get_slice(0)  # default 1sm
        tSgQ_qdl = qk_thr_mma.partition_A(gQ_qdl)

        tQsQ, tQgQ_qdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_q,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sQ, 0, 3),
            cute.group_modes(tSgQ_qdl, 0, 3),
        )

        gK_kdl = cute.flat_divide(mK_kdl, cute.select(self.qk_mma_tiler, mode=[1, 2]))
        tSgK_kdl = qk_thr_mma.partition_B(gK_kdl)
        tKsK, tKgK_kdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_k,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sK, 0, 3),
            cute.group_modes(tSgK_kdl, 0, 3),
        )

        # (bM, bN, loopM, loopN, loopL)
        gV_dkl = cute.flat_divide(mV_dkl, cute.select(self.pv_mma_tiler, mode=[1, 2]))

        pv_thr_mma = pv_tiled_mma.get_slice(0)  # default 1sm
        tSgV_dkl = pv_thr_mma.partition_B(gV_dkl)
        tVsV, tVgV_dkl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_v,
            0,  # no multicast
            cute.make_layout(1),
            cute.group_modes(sV, 0, 3),
            cute.group_modes(tSgV_dkl, 0, 3),
        )

        tSrQ = qk_thr_mma.make_fragment_A(sQ)
        tSrK = qk_thr_mma.make_fragment_B(sK)
        tOrV = pv_thr_mma.make_fragment_B(sV)

        gO_qdl = cute.flat_divide(mO_qdl, cute.select(self.pv_mma_tiler, mode=[0, 1]))

        qk_acc_shape = qk_thr_mma.partition_shape_C(
            (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
        )
        tStS = qk_thr_mma.make_fragment_C(qk_acc_shape)

        pv_acc_shape = pv_thr_mma.partition_shape_C(
            (self.pv_mma_tiler[0], self.pv_mma_tiler[1])
        )
        tOtO = pv_thr_mma.make_fragment_C(pv_acc_shape)

        tStS0 = cute.make_tensor(tStS.iterator + self.tmem_s0_offset, tStS.layout)
        tStS1 = cute.make_tensor(tStS.iterator + self.tmem_s1_offset, tStS.layout)

        tOtO0 = cute.make_tensor(tOtO.iterator + self.tmem_o0_offset, tOtO.layout)
        tOtO1 = cute.make_tensor(tOtO.iterator + self.tmem_o1_offset, tOtO.layout)

        tP = cute.make_tensor(tStS.iterator, p_tmem_layout_staged.outer)
        tOrP = pv_thr_mma.make_fragment_A(tP)[None, None, None, 0]

        tOrP0 = cute.make_tensor(
            tOrP.iterator
            + self.qk_acc_dtype.width // self.q_dtype.width * self.tmem_p0_offset,
            tOrP.layout,
        )
        tOrP1 = cute.make_tensor(
            tOrP.iterator
            + self.qk_acc_dtype.width // self.q_dtype.width * self.tmem_p1_offset,
            tOrP.layout,
        )

        cute.arch.barrier(
            barrier_id=self.cta_sync_bar_id,
            number_of_threads=self.threads_per_cta,
        )

        # ///////////////////////////////////////////////////////////////////////////////
        #  EMPTY
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.empty_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_empty)
            cute.arch.mbarrier_arrive(max_reg_setting_mbar_ptr)

        # ///////////////////////////////////////////////////////////////////////////////
        #  LOAD
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.load_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_other)
            cute.arch.mbarrier_arrive(max_reg_setting_mbar_ptr)

            q_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.q_stage
            )
            kv_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.kv_stage
            )

            tile_sched = create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                tQgQ = tQgQ_qdl[None, None, 0, curr_block_coord[2]]
                tKgK = tKgK_kdl[None, None, 0, curr_block_coord[2]]
                tVgV = tVgV_dkl[None, 0, None, curr_block_coord[2]]

                # Q0
                q0_coord = 2 * curr_block_coord[0]
                load_q_pipeline.producer_acquire(q_producer_state)
                cute.copy(
                    tma_atom_q,
                    tQgQ[None, q0_coord],
                    tQsQ[None, q_producer_state.index],
                    tma_bar_ptr=load_q_pipeline.producer_get_barrier(q_producer_state),
                )
                q_producer_state.advance()

                # K0
                kv_coord = 0  # seqlen_kv_loop
                load_kv_pipeline.producer_acquire(kv_producer_state)
                cute.copy(
                    tma_atom_k,
                    tKgK[None, kv_coord],
                    tKsK[None, kv_producer_state.index],
                    tma_bar_ptr=load_kv_pipeline.producer_get_barrier(
                        kv_producer_state
                    ),
                )
                kv_producer_state.advance()

                # Q1
                q1_coord = q0_coord + 1
                load_q_pipeline.producer_acquire(q_producer_state)
                cute.copy(
                    tma_atom_q,
                    tQgQ[None, q1_coord],
                    tQsQ[None, q_producer_state.index],
                    tma_bar_ptr=load_q_pipeline.producer_get_barrier(q_producer_state),
                )
                q_producer_state.advance()

                # V0
                load_kv_pipeline.producer_acquire(kv_producer_state)
                cute.copy(
                    tma_atom_v,
                    tVgV[None, kv_coord],
                    tVsV[None, kv_producer_state.index],
                    tma_bar_ptr=load_kv_pipeline.producer_get_barrier(
                        kv_producer_state
                    ),
                )
                kv_producer_state.advance()
                kv_coord += 1

                seqlen_kv_loop_steps = (
                    fused_mask.get_trip_count(curr_block_coord, self.cta_tiler) - 1
                )
                for i in cutlass.range_dynamic(0, seqlen_kv_loop_steps, 1, unroll=1):
                    # Ki
                    load_kv_pipeline.producer_acquire(kv_producer_state)
                    cute.copy(
                        tma_atom_k,
                        tKgK[None, kv_coord],
                        tKsK[None, kv_producer_state.index],
                        tma_bar_ptr=load_kv_pipeline.producer_get_barrier(
                            kv_producer_state
                        ),
                    )
                    kv_producer_state.advance()
                    # Vi
                    load_kv_pipeline.producer_acquire(kv_producer_state)
                    cute.copy(
                        tma_atom_v,
                        tVgV[None, kv_coord],
                        tVsV[None, kv_producer_state.index],
                        tma_bar_ptr=load_kv_pipeline.producer_get_barrier(
                            kv_producer_state
                        ),
                    )
                    kv_producer_state.advance()
                    kv_coord += 1
                # End of seqlen_kv loop

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                # End of persistent scheduler loop

        # ///////////////////////////////////////////////////////////////////////////////
        #  MMA
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.mma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_other)
            cute.arch.mbarrier_arrive(max_reg_setting_mbar_ptr)

            # Alloc tmem buffer
            tmem_alloc_cols = cutlass.Int32(self.tmem_alloc_cols)
            cute.arch.alloc_tmem(tmem_alloc_cols, storage.tmem_holding_buf)
            cute.arch.barrier(
                barrier_id=self.tmem_alloc_sync_bar_id,
                number_of_threads=self.threads_per_warp,
            )
            mma_q_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.q_stage
            )
            mma_kv_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.kv_stage
            )
            mma_q_release_state = mma_q_consumer_state.clone()
            mma_kv_release_state = mma_kv_consumer_state.clone()
            mma_s0_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.mma_softmax_stage
            )
            mma_s1_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.mma_softmax_stage
            )
            mma_corr_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.mma_corr_stage
            )
            tile_sched = create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                # GEMM_QK00 (Q0 * K0 -> S0)
                # 1. wait for Q0
                load_q_pipeline.consumer_wait(mma_q_consumer_state)
                tSrQ0 = tSrQ[None, None, None, mma_q_consumer_state.index]
                mma_q_consumer_state.advance()
                # 2. wait for K0
                load_kv_pipeline.consumer_wait(mma_kv_consumer_state)
                tSrK0 = tSrK[None, None, None, mma_kv_consumer_state.index]
                mma_kv_consumer_state.advance()
                # 3. acquire empty S0 buffer
                mma_s0_pipeline.producer_acquire(mma_s0_producer_state)
                # 4. gemm
                num_kphases = cute.size(tSrQ0, mode=[2])
                for kphase_idx in range(num_kphases):
                    kphase_coord = (None, None, kphase_idx)
                    qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                    cute.gemm(
                        qk_tiled_mma,
                        tStS0,
                        tSrQ0[kphase_coord],
                        tSrK0[kphase_coord],
                        tStS0,
                    )
                # 5. release S0
                mma_s0_pipeline.producer_commit(mma_s0_producer_state)
                mma_s0_producer_state.advance()
                # End of GEMM (Q0 * K0 -> S0)

                # GEMM_QK10 (Q1 * K0 -> S1), K0 is ready in GEMM_QK00
                # 1. wait for Q1
                load_q_pipeline.consumer_wait(mma_q_consumer_state)
                tSrQ1 = tSrQ[None, None, None, mma_q_consumer_state.index]
                mma_q_consumer_state.advance()
                # 2. acquire empty S1
                mma_s1_pipeline.producer_acquire(mma_s1_producer_state)
                # 3. gemm
                num_kphases = cute.size(tSrQ1, mode=[2])
                for kphase_idx in range(num_kphases):
                    kphase_coord = (None, None, kphase_idx)
                    qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                    cute.gemm(
                        qk_tiled_mma,
                        tStS1,
                        tSrQ1[kphase_coord],
                        tSrK0[kphase_coord],
                        tStS1,
                    )
                # 4. release S1
                mma_s1_pipeline.producer_commit(mma_s1_producer_state)
                mma_s1_producer_state.advance()
                # 5. release K0
                load_kv_pipeline.consumer_release(mma_kv_release_state)
                mma_kv_release_state.advance()
                # End of GEMM (Q1 * K0 -> S1)
                # Note: Q0 & Q1 are still needed in the seqlen_kv loop
                # so we need to release them after the seqlen_kv loop

                # GEMM_PV00 (P0 * V0 -> O0_partial), O0 needs to be accumulated in the seqlen_kv loop
                # 1. wait for V0
                load_kv_pipeline.consumer_wait(mma_kv_consumer_state)
                tOrVi = tOrV[None, None, None, mma_kv_consumer_state.index]
                mma_kv_consumer_state.advance()
                # 2. acquire corrected O0_partial
                # Note: acquire corr first to take it out of the critical
                # path since softmax takes longer
                mma_corr_pipeline.producer_acquire(mma_corr_producer_state)
                # 3. acquire P0
                # this acquire returns the ownership of all of S0 to the mma warp
                # including the P0 part (inplaced in S0)
                mma_s0_pipeline.producer_acquire(mma_s0_producer_state)
                # 4. gemm
                num_kphases = cute.size(tOrP0, mode=[2])
                for kphase_idx in range(num_kphases):
                    kphase_coord = (None, None, kphase_idx)
                    pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                    cute.gemm(
                        pv_tiled_mma,
                        tOtO0,
                        tOrP0[kphase_coord],
                        tOrVi[kphase_coord],
                        tOtO0,
                    )
                # 5. release accumulated O0_partial
                mma_corr_pipeline.producer_commit(mma_corr_producer_state)
                mma_corr_producer_state.advance()
                # End of GEMM_PV00 (P0 * V0 -> O0_partial)

                seqlen_kv_loop_steps = (
                    fused_mask.get_trip_count(curr_block_coord, self.cta_tiler) - 1
                )
                # O1 hasn't been accumulated yet, its first MMA calculation doesn't need to accumulate
                pv_whether_acc = False
                for i in cutlass.range_dynamic(0, seqlen_kv_loop_steps, 1, unroll=1):
                    # GEMM_QK0i (Q0 * Ki -> S0)
                    # 1. wait for Ki
                    load_kv_pipeline.consumer_wait(mma_kv_consumer_state)
                    tSrKi = tSrK[None, None, None, mma_kv_consumer_state.index]
                    mma_kv_consumer_state.advance()
                    # 2. gemm
                    inner_num_kphases = cute.size(tSrQ0, mode=[2])
                    for kphase_idx in range(inner_num_kphases):
                        kphase_coord = (None, None, kphase_idx)
                        qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                        cute.gemm(
                            qk_tiled_mma,
                            tStS0,
                            tSrQ0[kphase_coord],
                            tSrKi[kphase_coord],
                            tStS0,
                        )
                    # 3. release S0
                    mma_s0_pipeline.producer_commit(mma_s0_producer_state)
                    mma_s0_producer_state.advance()
                    # End of GEMM_QK0i (Q0 * Ki -> S0)

                    # GEMM_PV1(i-1) (P1 * V(i-1) -> O1_partial), V(i-1) is ready in GEMM_PV0(i-1)
                    # 1. acquire corrected O1_partial
                    mma_corr_pipeline.producer_acquire(mma_corr_producer_state)
                    # 2. acquire P1
                    mma_s1_pipeline.producer_acquire(mma_s1_producer_state)
                    # 3. gemm
                    inner_num_kphases = cute.size(tOrP0, mode=[2])
                    for kphase_idx in range(inner_num_kphases):
                        kphase_coord = (None, None, kphase_idx)
                        pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, pv_whether_acc)
                        cute.gemm(
                            pv_tiled_mma,
                            tOtO1,
                            tOrP1[kphase_coord],
                            tOrVi[kphase_coord],
                            tOtO1,
                        )
                        pv_whether_acc = True
                    # 4. release accumulated O1_partial
                    mma_corr_pipeline.producer_commit(mma_corr_producer_state)
                    mma_corr_producer_state.advance()
                    # 5. release V(i-1)
                    load_kv_pipeline.consumer_release(mma_kv_release_state)
                    mma_kv_release_state.advance()
                    # End of GEMM_PV1(i-1) (P1 * V(i-1) -> O1_partial)

                    # GEMM_QK1i (Q1 * Ki -> S1), Q1 is ready in GEMM_QK10; Ki is ready in GEMM_QK0i
                    # 1. gemm
                    inner_num_kphases = cute.size(tSrQ1, mode=[2])
                    for kphase_idx in range(inner_num_kphases):
                        kphase_coord = (None, None, kphase_idx)
                        qk_tiled_mma.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                        cute.gemm(
                            qk_tiled_mma,
                            tStS1,
                            tSrQ1[kphase_coord],
                            tSrKi[kphase_coord],
                            tStS1,
                        )
                    mma_s1_pipeline.producer_commit(mma_s1_producer_state)
                    mma_s1_producer_state.advance()
                    # 2. release Ki
                    load_kv_pipeline.consumer_release(mma_kv_release_state)
                    mma_kv_release_state.advance()
                    # End of GEMM_QK1i (Q1 * Ki -> S1)

                    # GEMM_PV0i (P0 * Vi -> O0_partial)
                    # 1. wait for Vi
                    load_kv_pipeline.consumer_wait(mma_kv_consumer_state)
                    tOrVi = tOrV[None, None, None, mma_kv_consumer_state.index]
                    mma_kv_consumer_state.advance()
                    # 2. acquire corrected O0_partial
                    mma_corr_pipeline.producer_acquire(mma_corr_producer_state)
                    # 3. acquire P0
                    mma_s0_pipeline.producer_acquire(mma_s0_producer_state)
                    # 4. gemm
                    inner_num_kphases = cute.size(tOrP0, mode=[2])
                    for kphase_idx in range(inner_num_kphases):
                        kphase_coord = (None, None, kphase_idx)
                        pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                        cute.gemm(
                            pv_tiled_mma,
                            tOtO0,
                            tOrP0[kphase_coord],
                            tOrVi[kphase_coord],
                            tOtO0,
                        )
                    # 5. release accumulated O0_partial
                    mma_corr_pipeline.producer_commit(mma_corr_producer_state)
                    mma_corr_producer_state.advance()
                    # End of GEMM_PV0i (P0 * Vi -> O0_partial)
                # End of seqlen_kv loop

                # release Q0 & Q1
                load_q_pipeline.consumer_release(mma_q_release_state)
                mma_q_release_state.advance()
                load_q_pipeline.consumer_release(mma_q_release_state)
                mma_q_release_state.advance()

                # GEMM_PV1(i_end) (P1 * Vi_end -> O1)
                # 1. acquire corrected O1_partial
                mma_corr_pipeline.producer_acquire(mma_corr_producer_state)
                # 2. acquire P1
                mma_s1_pipeline.producer_acquire(mma_s1_producer_state)
                # 3. gemm
                num_kphases = cute.size(tOrP1, mode=[2])
                for kphase_idx in range(num_kphases):
                    kphase_coord = (None, None, kphase_idx)
                    pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                    cute.gemm(
                        pv_tiled_mma,
                        tOtO1,
                        tOrP1[kphase_coord],
                        tOrVi[kphase_coord],
                        tOtO1,
                    )
                # 4. commit accumulated O1
                mma_corr_pipeline.producer_commit(mma_corr_producer_state)
                mma_corr_producer_state.advance()
                # 5. release Vi_end
                load_kv_pipeline.consumer_release(mma_kv_release_state)
                mma_kv_release_state.advance()
                # End of GEMM_PV1(i_end) (P1 * Vi_end -> O1)

                # Commit S0 and S1
                mma_s0_pipeline.producer_commit(mma_s0_producer_state)
                mma_s0_producer_state.advance()
                mma_s1_pipeline.producer_commit(mma_s1_producer_state)
                mma_s1_producer_state.advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop

            # dealloc tmem buffer
            cute.arch.mbarrier_wait(tmem_dealloc_mbar_ptr, 0)
            tmem_alloc_cols = cutlass.Int32(self.tmem_alloc_cols)
            #  Retrieving tmem ptr and make acc
            tmem_ptr = cute.arch.retrieve_tmem_ptr(
                cutlass.Float32,
                alignment=16,
                ptr_to_buffer_holding_addr=storage.tmem_holding_buf,
            )

            cute.arch.dealloc_tmem(tmem_ptr, tmem_alloc_cols)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Epilogue
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.epilogue_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_other)
            cute.arch.mbarrier_arrive(max_reg_setting_mbar_ptr)

            corr_epi_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.epi_stage
            )
            corr_epi_release_state = corr_epi_consumer_state.clone()

            tile_sched = create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx

                o0_coord = 2 * curr_block_coord[0]
                o1_coord = o0_coord + 1
                gO = gO_qdl[None, None, None, 0, curr_block_coord[2]]
                tOsO, tOgO = cute.nvgpu.cpasync.tma_partition(
                    tma_atom_o,
                    0,
                    cute.make_layout(1),
                    cute.group_modes(sO, 0, 2),
                    cute.group_modes(gO, 0, 2),
                )

                # O0 O1 using the same pipeline
                # wait from corr, issue tma store on smem
                # O0
                # 1. wait for O0 final
                corr_epi_pipeline.consumer_wait(corr_epi_consumer_state)
                corr_epi_consumer_state.advance()
                # 2. copy O0 to gmem
                cute.copy(tma_atom_o, tOsO[None, 0], tOgO[None, o0_coord])
                cute.arch.cp_async_bulk_commit_group()
                # O1
                # 1. wait for O1 final
                corr_epi_pipeline.consumer_wait(corr_epi_consumer_state)
                corr_epi_consumer_state.advance()
                # 2. copy O1 to gmem
                cute.copy(tma_atom_o, tOsO[None, 1], tOgO[None, o1_coord])
                cute.arch.cp_async_bulk_commit_group()

                # Ensure O0 buffer is ready to be released
                cute.arch.cp_async_bulk_wait_group(1, read=True)
                corr_epi_pipeline.consumer_release(corr_epi_release_state)
                corr_epi_release_state.advance()
                # Ensure O1 buffer is ready to be released
                cute.arch.cp_async_bulk_wait_group(0, read=True)
                corr_epi_pipeline.consumer_release(corr_epi_release_state)
                corr_epi_release_state.advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop

        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax0
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx < self.softmax1_warp_ids[0]:
            # increase register after decreasing
            cute.arch.mbarrier_wait(max_reg_setting_mbar_ptr, 0)
            cute.arch.warpgroup_reg_alloc(self.num_regs_softmax)

            self.softmax(
                stage=0,
                scale_softmax_log2=scale_softmax_log2,
                qk_thr_mma=qk_thr_mma,
                tStS=tStS,
                tStSi=tStS0,
                mma_si_pipeline=mma_s0_pipeline,
                si_corr_pipeline=s0_corr_pipeline,
                s0_s1_sequence_pipeline=s0_s1_sequence_pipeline,
                tile_sched_params=tile_sched_params,
                fused_mask=fused_mask,
            )
            cute.arch.mbarrier_arrive(tmem_dealloc_mbar_ptr)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax1
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx < self.correction_warp_ids[0]
            and warp_idx >= self.softmax1_warp_ids[0]
        ):
            # increase register after decreasing
            cute.arch.mbarrier_wait(max_reg_setting_mbar_ptr, 0)
            cute.arch.warpgroup_reg_alloc(self.num_regs_softmax)

            self.softmax(
                stage=1,
                scale_softmax_log2=scale_softmax_log2,
                qk_thr_mma=qk_thr_mma,
                tStS=tStS,
                tStSi=tStS1,
                mma_si_pipeline=mma_s1_pipeline,
                si_corr_pipeline=s1_corr_pipeline,
                s0_s1_sequence_pipeline=s0_s1_sequence_pipeline,
                tile_sched_params=tile_sched_params,
                fused_mask=fused_mask,
            )
            cute.arch.mbarrier_arrive(tmem_dealloc_mbar_ptr)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx >= self.correction_warp_ids[0] and warp_idx < self.mma_warp_id:
            cute.arch.warpgroup_reg_dealloc(self.num_regs_correction)
            cute.arch.mbarrier_arrive(max_reg_setting_mbar_ptr)

            s0_corr_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.softmax_corr_stage
            )
            s1_corr_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.softmax_corr_stage
            )
            o_corr_consumer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Consumer, self.mma_corr_stage
            )
            corr_epi_producer_state = utils.make_pipeline_state(
                utils.PipelineUserType.Producer, self.epi_stage
            )

            cS = cute.make_identity_tensor((self.qk_mma_tiler[0], self.qk_mma_tiler[1]))
            tScS = qk_thr_mma.partition_C(cS)

            tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))

            tStS_vec0 = cute.make_tensor(
                tStS.iterator + self.tmem_vec0_offset, tStS_vec_layout
            )
            tStS_vec1 = cute.make_tensor(
                tStS.iterator + self.tmem_vec1_offset, tStS_vec_layout
            )

            tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
            tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)

            tmem_load_v_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(2)),
                self.qk_acc_dtype,
            )

            tiled_tmem_load_vec = tcgen05.make_tmem_copy(tmem_load_v_atom, tStS_vec0)
            thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))
            thr_tmem_load_vec = tiled_tmem_load_vec.get_slice(thread_idx)

            tTMEM_LOAD_VECtS0 = thr_tmem_load_vec.partition_S(tStS_vec0)
            tTMEM_LOAD_VECtS1 = thr_tmem_load_vec.partition_S(tStS_vec1)
            tTMEM_LOAD_VECcS = thr_tmem_load_vec.partition_D(tScS_vec)

            tile_sched = create_fmha_static_tile_scheduler(
                tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
            )
            work_tile = tile_sched.initial_work_tile_info()

            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx

                # Ignore first signal from softmax as no correction is required
                s0_corr_pipeline.consumer_wait(s0_corr_consumer_state)
                s0_corr_pipeline.consumer_release(s0_corr_consumer_state)
                s0_corr_consumer_state.advance()

                s1_corr_pipeline.consumer_wait(s1_corr_consumer_state)

                seqlen_kv_loop_steps = (
                    fused_mask.get_trip_count(curr_block_coord, self.cta_tiler) - 1
                )
                for i in cutlass.range_dynamic(0, seqlen_kv_loop_steps, 1, unroll=1):
                    # wait for S0
                    s0_corr_pipeline.consumer_wait(s0_corr_consumer_state)
                    tTMEM_LOAD_VECrS = cute.make_fragment(
                        tTMEM_LOAD_VECcS.shape, self.qk_acc_dtype
                    )
                    # read row_wise new global max
                    cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtS0, tTMEM_LOAD_VECrS)

                    scale_ = scale_softmax_log2 * (
                        tTMEM_LOAD_VECrS[0] - tTMEM_LOAD_VECrS[1]
                    )
                    scale = cute.arch.exp2(scale_)

                    mma_corr_pipeline.consumer_wait(o_corr_consumer_state)
                    self.correction_rescale(pv_thr_mma, tOtO0, scale)

                    s1_corr_pipeline.consumer_release(s1_corr_consumer_state)
                    s1_corr_consumer_state.advance()

                    cute.arch.fence_view_async_tmem_store()

                    mma_corr_pipeline.consumer_release(o_corr_consumer_state)
                    o_corr_consumer_state.advance()

                    s1_corr_pipeline.consumer_wait(s1_corr_consumer_state)

                    cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtS1, tTMEM_LOAD_VECrS)

                    scale_ = scale_softmax_log2 * (
                        tTMEM_LOAD_VECrS[0] - tTMEM_LOAD_VECrS[1]
                    )
                    scale = cute.arch.exp2(scale_)

                    mma_corr_pipeline.consumer_wait(o_corr_consumer_state)
                    self.correction_rescale(pv_thr_mma, tOtO1, scale)

                    s0_corr_pipeline.consumer_release(s0_corr_consumer_state)
                    s0_corr_consumer_state.advance()

                    cute.arch.fence_view_async_tmem_store()
                    mma_corr_pipeline.consumer_release(o_corr_consumer_state)
                    o_corr_consumer_state.advance()
                # End of seqlen_corr_loop_steps

                s1_corr_pipeline.consumer_release(s1_corr_consumer_state)
                s1_corr_consumer_state.advance()

                s0_corr_pipeline.consumer_wait(s0_corr_consumer_state)

                tTMEM_LOAD_VECrS = cute.make_fragment(
                    tTMEM_LOAD_VECcS.shape, self.qk_acc_dtype
                )
                cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtS0, tTMEM_LOAD_VECrS)
                cute.arch.fence_view_async_tmem_load()

                s0_corr_pipeline.consumer_release(s0_corr_consumer_state)
                s0_corr_consumer_state.advance()

                mma_corr_pipeline.consumer_wait(o_corr_consumer_state)
                corr_epi_pipeline.producer_acquire(corr_epi_producer_state)

                self.correction_epilog(
                    pv_thr_mma,
                    tOtO0,
                    scale_output / tTMEM_LOAD_VECrS[0],
                    sO[None, None, 0],
                )

                mma_corr_pipeline.consumer_release(o_corr_consumer_state)
                o_corr_consumer_state.advance()

                corr_epi_pipeline.producer_commit(corr_epi_producer_state)
                corr_epi_producer_state.advance()

                s1_corr_pipeline.consumer_wait(s1_corr_consumer_state)
                # load from V1
                cute.copy(tiled_tmem_load_vec, tTMEM_LOAD_VECtS1, tTMEM_LOAD_VECrS)
                cute.arch.fence_view_async_tmem_load()

                s1_corr_pipeline.consumer_release(s1_corr_consumer_state)
                s1_corr_consumer_state.advance()

                mma_corr_pipeline.consumer_wait(o_corr_consumer_state)

                corr_epi_pipeline.producer_acquire(corr_epi_producer_state)
                self.correction_epilog(
                    pv_thr_mma,
                    tOtO1,
                    scale_output / tTMEM_LOAD_VECrS[0],
                    sO[None, None, 1],
                )
                mma_corr_pipeline.consumer_release(o_corr_consumer_state)
                o_corr_consumer_state.advance()

                corr_epi_pipeline.producer_commit(corr_epi_producer_state)
                corr_epi_producer_state.advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            # End of persistent scheduler loop

            cute.arch.mbarrier_arrive(tmem_dealloc_mbar_ptr)

        return

    @cute.jit
    def softmax_step(
        self,
        stage: int,
        need_apply_mask: bool,
        row_max: cutlass.Float32,
        row_sum: cutlass.Float32,
        mma_si_consumer_state: utils.PipelineState,
        si_corr_producer_state: utils.PipelineState,
        s0_s1_sequence_state: utils.PipelineState,
        mma_si_pipeline: utils.PipelineAsync,
        si_corr_pipeline: utils.PipelineAsync,
        s0_s1_sequence_pipeline: utils.PipelineAsync,
        scale_softmax_log2: cutlass.Float32,
        cS: cute.Tensor,
        qk_thr_mma: cute.core.ThrMma,
        tiled_tmem_load: cute.TiledCopy,
        tiled_tmem_store: cute.TiledCopy,
        tiled_tmem_store_vec: cute.TiledCopy,
        thr_tmem_load: cute.CopyAtom,
        thr_tmem_store: cute.CopyAtom,
        thr_tmem_store_vec: cute.CopyAtom,
        tTMEM_LOADtS: cute.Tensor,
        tTMEM_STORE_VECtS: cute.Tensor,
        tTMEM_STOREtS_x4: cute.Tensor,
        fused_mask: cute.Tensor,
    ) -> Tuple[
        cutlass.Float32,
        cutlass.Float32,
        utils.PipelineState,
        utils.PipelineState,
        utils.PipelineState,
    ]:
        """Perform a single step of the softmax computation on a block of attention scores.

        This method processes one block of the attention matrix, computing numerically stable
        softmax by first finding the row maximum, subtracting it from all elements, applying
        exponential function, and then normalizing by the sum of exponentials. It also handles
        optional masking of attention scores.

        The method involves several key operations:
        1. Loading attention scores from tensor memory
        2. Applying optional masking based on position
        3. Computing row-wise maximum values for numerical stability
        4. Transforming scores using exp2(x*scale - max*scale)
        5. Computing row sums for normalization
        6. Coordinating pipeline synchronization between different processing stages

        :param stage: Processing stage (0 for first half, 1 for second half)
        :type stage: int
        :param need_apply_mask: Whether to apply attention masking
        :type need_apply_mask: bool
        :param row_max: Current maximum value for the row
        :type row_max: cute.core.Tensor
        :param row_sum: Current sum value for the row
        :type row_sum: cute.core.Tensor
        :param mma_si_consumer_state: Pipeline state for MMA consumer operations
        :type mma_si_consumer_state: utils.PipelineState
        :param si_corr_producer_state: Pipeline state for correction producer operations
        :type si_corr_producer_state: utils.PipelineState
        :param s0_s1_sequence_state: Pipeline state for sequence synchronization
        :type s0_s1_sequence_state: utils.PipelineState
        :param mma_si_pipeline: Pipeline for MMA operations
        :type mma_si_pipeline: utils.PipelineAsync
        :param si_corr_pipeline: Pipeline for correction operations
        :type si_corr_pipeline: utils.PipelineAsync
        :param s0_s1_sequence_pipeline: Pipeline for sequence synchronization
        :type s0_s1_sequence_pipeline: utils.PipelineAsync
        :param scale_softmax_log2: Log2 scale factor for softmax computation
        :type scale_softmax_log2: cutlass.Float32
        :param cS: Current slice of attention matrix
        :type cS: cute.Tensor
        :param qk_thr_mma: Thread MMA operation
        :type qk_thr_mma: cute.core.ThrMma
        :param tiled_tmem_load: Tiled copy operation for loading from tensor memory
        :type tiled_tmem_load: cute.TiledCopy
        :param tiled_tmem_store: Tiled copy operation for storing to tensor memory
        :type tiled_tmem_store: cute.TiledCopy
        :param tiled_tmem_store_vec: Tiled copy operation for storing vector data
        :type tiled_tmem_store_vec: cute.TiledCopy
        :param thr_tmem_load: Thread copy operation for loading
        :type thr_tmem_load: cute.CopyAtom
        :param thr_tmem_store: Thread copy operation for storing
        :type thr_tmem_store: cute.CopyAtom
        :param thr_tmem_store_vec: Thread copy operation for storing vector data
        :type thr_tmem_store_vec: cute.CopyAtom
        :param tTMEM_LOADtS: Tensor for loading from tensor memory
        :type tTMEM_LOADtS: cute.Tensor
        :param tTMEM_STORE_VECtS: Tensor for storing vector data
        :type tTMEM_STORE_VECtS: cute.Tensor
        :param tTMEM_STOREtS_x4: Tensor for storing processed data
        :type tTMEM_STOREtS_x4: cute.Tensor
        :param fused_mask: Mask configuration for attention masking
        :type fused_mask: cute.Tensor
        :return: Updated state values (row_max, row_sum, and pipeline states)
        :rtype: tuple
        """
        tilePlikeFP32 = (
            self.qk_mma_tiler[1] // cutlass.Float32.width * self.o_dtype.width
        )
        tScS = qk_thr_mma.partition_C(cS)
        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)

        tScS_P_layout = cute.composition(
            tScS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tScS_P = cute.make_tensor(tScS.iterator, tScS_P_layout)
        tTMEM_LOADcS = thr_tmem_load.partition_D(tScS)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)
        tTMEM_STOREcS = thr_tmem_store.partition_S(tScS_P)

        # Wait for Si
        mma_si_pipeline.consumer_wait(mma_si_consumer_state)
        tTMEM_LOADrS = cute.make_fragment(tTMEM_LOADcS.shape, self.qk_acc_dtype)
        cute.copy(tiled_tmem_load, tTMEM_LOADtS, tTMEM_LOADrS)

        if need_apply_mask:
            fused_mask.apply_mask(tTMEM_LOADrS, tTMEM_LOADcS)

        old_row_max = row_max
        row_max = tTMEM_LOADrS.load().reduce(cute.ReductionOp.MAX, row_max, 0)
        row_max_safe = row_max
        if row_max == -cutlass.Float32.inf:
            row_max_safe = 0.0

        tTMEM_STORE_VECrS = cute.make_fragment(
            tTMEM_STORE_VECcS.shape, self.qk_acc_dtype
        )
        tTMEM_STORE_VECrS[0] = old_row_max
        tTMEM_STORE_VECrS[1] = row_max_safe
        cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
        cute.arch.fence_view_async_tmem_store()
        # Notify correction wg that row_max is ready
        si_corr_pipeline.producer_commit(si_corr_producer_state)
        si_corr_producer_state.advance()

        tTMEM_STORErS_x4 = cute.make_fragment(tTMEM_STOREcS.shape, self.qk_acc_dtype)
        tTMEM_STORErS_x4_e = cute.make_tensor(
            cute.recast_ptr(tTMEM_STORErS_x4.iterator, dtype=self.q_dtype),
            tTMEM_LOADrS.layout,
        )

        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale

        # Sequence barrier wait
        if stage == 0:
            s0_s1_sequence_pipeline.producer_acquire(s0_s1_sequence_state)
        else:
            s0_s1_sequence_pipeline.consumer_wait(s0_s1_sequence_state)

        frg_cnt = 4
        frg_tile = cute.size(tTMEM_LOADrS) // frg_cnt
        tTMEM_LOADrS_frg = cute.logical_divide(tTMEM_LOADrS, cute.make_layout(frg_tile))
        tTMEM_STORErS_x4_e_frg = cute.logical_divide(
            tTMEM_STORErS_x4_e, cute.make_layout(frg_tile)
        )
        for j in range(frg_cnt):
            for k in range(0, cute.size(tTMEM_LOADrS_frg, mode=[0]), 2):
                tTMEM_LOADrS_frg[k, j], tTMEM_LOADrS_frg[k + 1, j] = (
                    cute.arch.fma_packed_f32x2(
                        (tTMEM_LOADrS_frg[k, j], tTMEM_LOADrS_frg[k + 1, j]),
                        (scale, scale),
                        (minus_row_max_scale, minus_row_max_scale),
                    )
                )
                tTMEM_LOADrS_frg[k, j] = cute.arch.exp2(tTMEM_LOADrS_frg[k, j])
                tTMEM_LOADrS_frg[k + 1, j] = cute.arch.exp2(tTMEM_LOADrS_frg[k + 1, j])
            s_vec = tTMEM_LOADrS_frg[None, j].load()
            tTMEM_STORErS_x4_e_frg[None, j].store(s_vec.to(self.q_dtype))

        # Sequence barrier arrive
        if stage == 0:
            s0_s1_sequence_pipeline.producer_commit(s0_s1_sequence_state)
        else:
            s0_s1_sequence_pipeline.consumer_release(s0_s1_sequence_state)
        s0_s1_sequence_state.advance()

        cute.copy(tiled_tmem_store, tTMEM_STORErS_x4, tTMEM_STOREtS_x4)
        cute.arch.fence_view_async_tmem_store()

        # Notify tensor core warp that P is ready
        mma_si_pipeline.consumer_release(mma_si_consumer_state)
        mma_si_consumer_state.advance()

        si_corr_pipeline.producer_acquire(si_corr_producer_state)

        acc_scale_ = scale * (old_row_max - row_max_safe)
        acc_scale = cute.arch.exp2(acc_scale_) * 0.5
        row_sum *= acc_scale
        local_row_sum_0 = (row_sum, row_sum)
        local_row_sum_1 = (0.0, 0.0)
        local_row_sum_2 = (0.0, 0.0)
        local_row_sum_3 = (0.0, 0.0)

        reduction_unroll = 4
        frg_tile = cute.size(tTMEM_LOADrS) // reduction_unroll
        tTMEM_LOADrS_frg = cute.logical_divide(tTMEM_LOADrS, cute.make_layout(frg_tile))

        for j in range(0, cute.size(tTMEM_LOADrS_frg, mode=[0]), 2):
            local_row_sum_0 = cute.arch.add_packed_f32x2(
                local_row_sum_0, (tTMEM_LOADrS_frg[j, 0], tTMEM_LOADrS_frg[j + 1, 0])
            )
            local_row_sum_1 = cute.arch.add_packed_f32x2(
                local_row_sum_1, (tTMEM_LOADrS_frg[j, 1], tTMEM_LOADrS_frg[j + 1, 1])
            )
            local_row_sum_2 = cute.arch.add_packed_f32x2(
                local_row_sum_2, (tTMEM_LOADrS_frg[j, 2], tTMEM_LOADrS_frg[j + 1, 2])
            )
            local_row_sum_3 = cute.arch.add_packed_f32x2(
                local_row_sum_3, (tTMEM_LOADrS_frg[j, 3], tTMEM_LOADrS_frg[j + 1, 3])
            )

        local_row_sum_0 = cute.arch.add_packed_f32x2(local_row_sum_0, local_row_sum_1)
        local_row_sum_2 = cute.arch.add_packed_f32x2(local_row_sum_2, local_row_sum_3)
        local_row_sum_0 = cute.arch.add_packed_f32x2(local_row_sum_0, local_row_sum_2)
        row_sum = local_row_sum_0[0] + local_row_sum_0[1]

        return (
            row_max,
            row_sum,
            mma_si_consumer_state,
            si_corr_producer_state,
            s0_s1_sequence_state,
        )

    # for both softmax0 and softmax1 warp group
    @cute.jit
    def softmax(
        self,
        stage: int,
        scale_softmax_log2: cutlass.Float32,
        qk_thr_mma: cute.core.ThrMma,
        tStS: cute.Tensor,
        tStSi: cute.Tensor,
        mma_si_pipeline: utils.PipelineAsync,
        si_corr_pipeline: utils.PipelineAsync,
        s0_s1_sequence_pipeline: utils.PipelineAsync,
        tile_sched_params: FmhaStaticTileSchedulerParams,
        fused_mask: FusedMask,
    ):
        """Compute softmax on attention scores from QK matrix multiplication.

        This method handles the softmax computation for either the first or second half of the
        attention matrix, depending on the 'stage' parameter. It calculates row-wise maximum
        and sum values needed for stable softmax computation, applies optional masking, and
        transforms raw attention scores into probability distributions.

        The implementation uses specialized memory access patterns and efficient math operations
        for computing exp(x) using exp2 functions. It also coordinates pipeline
        synchronization between MMA, correction, and sequence processing stages.

        :param stage: Processing stage (0 for first half, 1 for second half of attention matrix)
        :type stage: int
        :param scale_softmax_log2: Log2 scale factor for softmax operation
        :type scale_softmax_log2: cutlass.Float32
        :param qk_thr_mma: Thread MMA operation for QK matrix multiplication
        :type qk_thr_mma: cute.core.ThrMma
        :param tStS: Shared tensor for softmax input/output
        :type tStS: cute.Tensor
        :param tStSi: Input tensor containing attention scores
        :type tStSi: cute.Tensor
        :param mma_si_pipeline: Pipeline for synchronizing with MMA operations
        :type mma_si_pipeline: utils.PipelineAsync
        :param si_corr_pipeline: Pipeline for synchronizing with correction operations
        :type si_corr_pipeline: utils.PipelineAsync
        :param s0_s1_sequence_pipeline: Pipeline for synchronizing between stage 0 and 1
        :type s0_s1_sequence_pipeline: utils.PipelineAsync
        :param tile_sched_params: Parameters for tile scheduling
        :type tile_sched_params: FmhaStaticTileSchedulerParams
        :param fused_mask: Mask configuration for attention masking
        :type fused_mask: FusedMask
        """
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (
            self.threads_per_warp
            * (
                len(self.softmax0_warp_ids)
                if stage == 0
                else len(self.softmax1_warp_ids)
            )
        )

        cS_base = cute.make_identity_tensor(
            (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
        )

        tilePlikeFP32 = self.qk_mma_tiler[1] // 32 * self.o_dtype.width

        tScS = qk_thr_mma.partition_C(cS_base)

        tStS_vec_layout = cute.composition(tStS.layout, cute.make_layout((128, 2)))
        tmem_vec_offset = self.tmem_vec0_offset if stage == 0 else self.tmem_vec1_offset
        tStS_vec = cute.make_tensor(tStS.iterator + tmem_vec_offset, tStS_vec_layout)

        tScS_vec_layout = cute.composition(tScS.layout, cute.make_layout((128, 2)))
        tScS_vec = cute.make_tensor(tScS.iterator, tScS_vec_layout)

        tStS_P_layout = cute.composition(
            tStS.layout, cute.make_layout((128, tilePlikeFP32))
        )
        tmem_p_offset = self.tmem_p0_offset if stage == 0 else self.tmem_p1_offset
        tStS_P = cute.make_tensor(tStS.iterator + tmem_p_offset, tStS_P_layout)

        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)),
            self.qk_acc_dtype,
        )

        tiled_tmem_load = tcgen05.make_tmem_copy(tmem_load_atom, tStSi)
        thread_idx = tidx % (
            self.threads_per_warp
            * (
                len(self.softmax0_warp_ids)
                if stage == 0
                else len(self.softmax1_warp_ids)
            )
        )
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        tTMEM_LOADtS = thr_tmem_load.partition_S(tStSi)

        tmem_store_vec_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(2)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store_vec = tcgen05.make_tmem_copy(tmem_store_vec_atom, tStS_vec)
        thr_tmem_store_vec = tiled_tmem_store_vec.get_slice(thread_idx)

        tTMEM_STORE_VECtS = thr_tmem_store_vec.partition_D(tStS_vec)
        tTMEM_STORE_VECcS = thr_tmem_store_vec.partition_S(tScS_vec)
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(32)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tStS_P)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)
        tTMEM_STOREtS_x4 = thr_tmem_store.partition_D(tStS_P)

        mma_si_consumer_state = utils.make_pipeline_state(
            utils.PipelineUserType.Consumer, self.mma_softmax_stage
        )
        si_corr_producer_state = utils.make_pipeline_state(
            utils.PipelineUserType.Producer, self.softmax_corr_stage
        )
        s0_s1_sequence_state = utils.make_pipeline_state(
            (
                utils.PipelineUserType.Producer
                if stage == 0
                else utils.PipelineUserType.Consumer
            ),
            1,
        )

        tile_sched = create_fmha_static_tile_scheduler(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        while work_tile.is_valid_tile:
            curr_block_coord = work_tile.tile_idx
            logical_offset = (
                curr_block_coord[0] * self.cta_tiler[0] + stage * self.qk_mma_tiler[0],
                0,
            )

            cS = cute.domain_offset(logical_offset, cS_base)

            si_corr_pipeline.producer_acquire(si_corr_producer_state)
            unmask_count = fused_mask.get_unmasked_trip_count(
                curr_block_coord,
                self.cta_tiler,
            )

            row_max = -cutlass.Float32.inf
            row_sum = 0.0

            for i in cutlass.range_dynamic(0, unmask_count, 1, unroll=1):
                cS_iter = cute.domain_offset((0, i * self.qk_mma_tiler[1]), cS)
                (
                    row_max,
                    row_sum,
                    mma_si_consumer_state,
                    si_corr_producer_state,
                    s0_s1_sequence_state,
                ) = self.softmax_step(
                    stage,
                    False,
                    row_max,
                    row_sum,
                    mma_si_consumer_state,
                    si_corr_producer_state,
                    s0_s1_sequence_state,
                    mma_si_pipeline,
                    si_corr_pipeline,
                    s0_s1_sequence_pipeline,
                    scale_softmax_log2,
                    cS_iter,
                    qk_thr_mma,
                    tiled_tmem_load,
                    tiled_tmem_store,
                    tiled_tmem_store_vec,
                    thr_tmem_load,
                    thr_tmem_store,
                    thr_tmem_store_vec,
                    tTMEM_LOADtS,
                    tTMEM_STORE_VECtS,
                    tTMEM_STOREtS_x4,
                    fused_mask,
                )

            mask_count = fused_mask.get_masked_trip_count(
                curr_block_coord,
                self.cta_tiler,
            )

            for i in cutlass.range_dynamic(
                unmask_count, unmask_count + mask_count, 1, unroll=1
            ):
                cS_iter = cute.domain_offset((0, i * self.qk_mma_tiler[1]), cS)
                (
                    row_max,
                    row_sum,
                    mma_si_consumer_state,
                    si_corr_producer_state,
                    s0_s1_sequence_state,
                ) = self.softmax_step(
                    stage,
                    True,
                    row_max,
                    row_sum,
                    mma_si_consumer_state,
                    si_corr_producer_state,
                    s0_s1_sequence_state,
                    mma_si_pipeline,
                    si_corr_pipeline,
                    s0_s1_sequence_pipeline,
                    scale_softmax_log2,
                    cS_iter,
                    qk_thr_mma,
                    tiled_tmem_load,
                    tiled_tmem_store,
                    tiled_tmem_store_vec,
                    thr_tmem_load,
                    thr_tmem_store,
                    thr_tmem_store_vec,
                    tTMEM_LOADtS,
                    tTMEM_STORE_VECtS,
                    tTMEM_STOREtS_x4,
                    fused_mask,
                )

            mma_si_pipeline.consumer_wait(mma_si_consumer_state)

            tTMEM_STORE_VECrS = cute.make_fragment(
                tTMEM_STORE_VECcS.shape, self.qk_acc_dtype
            )
            tTMEM_STORE_VECrS[0] = row_sum
            tTMEM_STORE_VECrS[1] = row_max
            cute.copy(tiled_tmem_store_vec, tTMEM_STORE_VECrS, tTMEM_STORE_VECtS)
            cute.arch.fence_view_async_tmem_store()

            si_corr_pipeline.producer_commit(si_corr_producer_state)
            si_corr_producer_state.advance()

            si_corr_pipeline.producer_acquire(si_corr_producer_state)

            # Empty step to sync against pipe s
            mma_si_pipeline.consumer_release(mma_si_consumer_state)
            mma_si_consumer_state.advance()

            # Advance to next tile
            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()
        # End of persistent scheduler loop

    @cute.jit
    def correction_rescale(
        self,
        thr_mma: cute.core.ThrMma,
        tOtO: cute.Tensor,
        scale: cutlass.Float32,
    ):
        """Rescale intermediate attention results based on softmax normalization factor.

        This method performs a crucial correction step in the attention computation pipeline.
        When processing attention in blocks, the softmax normalization factors may change
        as new blocks are processed. This method rescales previously computed partial
        output values to account for updated normalization factors.

        The implementation uses efficient tensor memory operations to:
        1. Load existing partial attention output from tensor memory
        2. Apply the scaling factor to all elements
        3. Store the rescaled results back to tensor memory

        :param thr_mma: Thread MMA operation for the computation
        :type thr_mma: cute.core.ThrMma
        :param tOtO: Tensor representing partial attention output to be rescaled
        :type tOtO: cute.Tensor
        :param scale: Scaling factor to apply to the partial results
        :type scale: cutlass.Float32
        """
        pv_tiled_mma_shape = (
            self.pv_mma_tiler[0],
            self.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)
        tOcO = thr_mma.partition_C(cO)

        corr_tile_size = 16  # tuneable parameter
        tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.pv_acc_dtype,
        )
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(corr_tile_size)),
            self.pv_acc_dtype,
        )

        tOtO_i_layout = cute.composition(
            tOtO.layout, cute.make_layout((128, corr_tile_size))
        )
        tOcO_i_layout = cute.composition(
            tOcO.layout, cute.make_layout((128, corr_tile_size))
        )

        tOtO_i = cute.make_tensor(tOtO.iterator, tOtO_i_layout)
        tOcO_i = cute.make_tensor(tOcO.iterator, tOcO_i_layout)

        tiled_tmem_load = tcgen05.make_tmem_copy(tmem_load_atom, tOtO_i)
        tiled_tmem_store = tcgen05.make_tmem_copy(tmem_store_atom, tOtO_i)
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))
        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        thr_tmem_store = tiled_tmem_store.get_slice(thread_idx)

        tTMEM_LOADtO = thr_tmem_load.partition_S(tOtO_i)
        tTMEM_LOADcO = thr_tmem_load.partition_D(tOcO_i)

        tTMEM_STOREtO = thr_tmem_store.partition_D(tOtO_i)

        tTMrO = cute.make_fragment(
            (tTMEM_LOADcO.shape, 128 // corr_tile_size), self.pv_acc_dtype
        )
        for i in range(self.cta_tiler[2] // corr_tile_size):
            tTMrO_i_ = tTMrO[None, i]
            tTMrO_i_layout = cute.composition(
                tTMrO_i_.layout, cute.make_layout(tTMrO.shape[0])
            )
            tTMrO_i = cute.make_tensor(tTMrO_i_.iterator, tTMrO_i_layout)
            tTMEM_LOADtO_i = cute.make_tensor(
                tTMEM_LOADtO.iterator + i * corr_tile_size, tTMEM_LOADtO.layout
            )
            tTMEM_STOREtO_i = cute.make_tensor(
                tTMEM_STOREtO.iterator + i * corr_tile_size, tTMEM_STOREtO.layout
            )

            cute.copy(tiled_tmem_load, tTMEM_LOADtO_i, tTMrO_i)
            for j in range(0, cute.size(tTMrO_i), 2):
                tTMrO_i[j], tTMrO_i[j + 1] = cute.arch.mul_packed_f32x2(
                    (tTMrO_i[j], tTMrO_i[j + 1]),
                    (scale, scale),
                )
            cute.copy(tiled_tmem_store, tTMrO_i, tTMEM_STOREtO_i)

    @cute.jit
    def correction_epilog(
        self,
        thr_mma: cute.core.ThrMma,
        tOtO: cute.Tensor,
        scale: cutlass.Float32,
        sO: cute.Tensor,
    ):
        """Apply final scaling and transformation to attention output before writing to global memory.

        This correction_epilog function handles the final processing step for attention output values.
        It applies a scaling factor to the accumulated attention results and prepares the
        data for efficient transfer back to global memory.

        The method performs:
        1. Loading of accumulated attention results from tensor memory
        2. Application of the final output scaling factor
        3. Type conversion if necessary (typically from higher precision accumulator to output precision)
        4. Reorganization of data for optimal memory access patterns
        5. Preparation for efficient TMA store operations

        :param thr_mma: Thread MMA operation for the computation
        :type thr_mma: cute.core.ThrMma
        :param tOtO: Tensor containing accumulated attention output
        :type tOtO: cute.Tensor
        :param scale: Final scaling factor to apply to the output
        :type scale: cutlass.Float32
        :param sO: Shared memory tensor for the final output
        :type sO: cute.Tensor
        """

        pv_tiled_mma_shape = (
            self.pv_mma_tiler[0],
            self.pv_mma_tiler[1],
        )
        cO = cute.make_identity_tensor(pv_tiled_mma_shape)

        corr_tile_size = 32 * 8 // self.o_dtype.width
        tOsO = thr_mma.partition_C(sO)
        tOcO = thr_mma.partition_C(cO)

        tOtO_i = cute.logical_divide(tOtO, cute.make_layout((128, corr_tile_size)))
        tOcO_i = cute.logical_divide(tOcO, cute.make_layout((128, corr_tile_size)))
        tOsO_i = cute.logical_divide(tOsO, cute.make_layout((128, corr_tile_size)))
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.correction_warp_ids))

        epi_subtile = (self.epi_tile[0], corr_tile_size)
        tmem_copy_atom = sm100_utils.get_tmem_load_op(
            self.pv_mma_tiler,
            self.o_layout,
            self.o_dtype,
            self.pv_acc_dtype,
            epi_subtile,
            use_2cta_instrs=False,
        )

        tiled_tmem_load = tcgen05.make_tmem_copy(
            tmem_copy_atom, tOtO_i[(None, None), 0]
        )

        thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
        smem_copy_atom = sm100_utils.get_smem_store_op(
            self.o_layout, self.o_dtype, self.pv_acc_dtype, tiled_tmem_load
        )
        tiled_smem_store = cute.make_tiled_copy(
            smem_copy_atom,
            layout_tv=tiled_tmem_load.layout_dst_tv_tiled,
            tiler_mn=tiled_tmem_load.tiler_mn,
        )

        tTMEM_LOADtO = thr_tmem_load.partition_S(tOtO_i[(None, None), None])
        tTMEM_LOADsO = thr_tmem_load.partition_D(tOsO_i[(None, None), None])
        tTMEM_LOADoO = thr_tmem_load.partition_D(tOcO_i[(None, None), None])

        for i in range(self.cta_tiler[2] // corr_tile_size):
            tTMEM_LOADtO_i = tTMEM_LOADtO[None, 0, 0, i]
            tTMEM_LOADsO_i = tTMEM_LOADsO[None, 0, 0, i]
            tTMrO = cute.make_fragment(
                tTMEM_LOADoO[None, 0, 0, i].shape, self.pv_acc_dtype
            )
            cute.copy(tiled_tmem_load, tTMEM_LOADtO_i, tTMrO)
            for j in range(0, cute.size(tTMrO), 2):
                tTMrO[j], tTMrO[j + 1] = cute.arch.mul_packed_f32x2(
                    (tTMrO[j], tTMrO[j + 1]),
                    (scale, scale),
                )
            tSMrO = cute.make_fragment(tTMrO.shape, self.o_dtype)
            o_vec = tTMrO.load()
            tSMrO.store(o_vec.to(self.o_dtype))
            cute.copy(tiled_smem_store, tSMrO, tTMEM_LOADsO_i)

        # fence view async shared
        cute.arch.fence_proxy(
            cute.arch.ProxyKind.async_shared,
            space=cute.arch.SharedSpace.shared_cta,
        )

    def make_and_init_load_q_pipeline(self, load_q_mbar_ptr):
        load_q_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.load_warp_id])
        )
        load_q_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.mma_warp_id])
        )
        return utils.PipelineTmaUmma.create(
            barrier_storage=load_q_mbar_ptr,
            num_stages=self.q_stage,
            producer_group=load_q_producer_group,
            consumer_group=load_q_consumer_group,
            tx_count=self.tma_copy_q_bytes,
        )

    def make_and_init_load_kv_pipeline(self, load_kv_mbar_ptr):
        load_kv_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.load_warp_id])
        )
        load_kv_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.mma_warp_id])
        )
        return utils.PipelineTmaUmma.create(
            barrier_storage=load_kv_mbar_ptr,
            num_stages=self.kv_stage,
            producer_group=load_kv_producer_group,
            consumer_group=load_kv_consumer_group,
            tx_count=self.tma_copy_kv_bytes,
        )

    def make_and_init_mma_si_pipeline(self, mma_si_mbar_ptr):
        mma_si_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.mma_warp_id])
        )
        mma_si_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.softmax0_warp_ids),
            self.threads_per_warp * len(self.softmax0_warp_ids),
        )
        return utils.PipelineUmmaAsync.create(
            barrier_storage=mma_si_mbar_ptr,
            num_stages=self.mma_softmax_stage,
            producer_group=mma_si_producer_group,
            consumer_group=mma_si_consumer_group,
        )

    def make_and_init_si_corr_pipeline(self, si_corr_mbar_ptr):
        si_corr_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.softmax0_warp_ids),
            self.threads_per_warp * len(self.softmax0_warp_ids),
        )
        si_corr_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.correction_warp_ids),
            self.threads_per_warp * len(self.correction_warp_ids),
        )
        return utils.PipelineAsync.create(
            barrier_storage=si_corr_mbar_ptr,
            num_stages=self.softmax_corr_stage,
            producer_group=si_corr_producer_group,
            consumer_group=si_corr_consumer_group,
        )

    def make_and_init_corr_epi_pipeline(self, corr_epi_mbar_ptr):
        corr_epi_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.correction_warp_ids),
            self.threads_per_warp * len(self.correction_warp_ids),
        )
        corr_epi_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len([self.epilogue_warp_id]),
            self.threads_per_warp * len([self.epilogue_warp_id]),
        )
        return utils.PipelineAsync.create(
            barrier_storage=corr_epi_mbar_ptr,
            num_stages=self.epi_stage,
            producer_group=corr_epi_producer_group,
            consumer_group=corr_epi_consumer_group,
        )

    def make_and_init_mma_corr_pipeline(self, mma_corr_mbar_ptr):
        mma_corr_producer_group = utils.CooperativeGroup(
            utils.Agent.Thread, len([self.mma_warp_id])
        )
        mma_corr_consumer_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.correction_warp_ids),
            self.threads_per_warp * len(self.correction_warp_ids),
        )
        return utils.PipelineUmmaAsync.create(
            barrier_storage=mma_corr_mbar_ptr,
            num_stages=self.mma_corr_stage,
            producer_group=mma_corr_producer_group,
            consumer_group=mma_corr_consumer_group,
        )

    def make_and_init_si_sequence_pipeline(self, si_sequence_mbar_ptr):
        s0_sequence_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.softmax0_warp_ids),
            self.threads_per_warp * len(self.softmax0_warp_ids),
        )
        s1_sequence_group = utils.CooperativeGroup(
            utils.Agent.Thread,
            self.threads_per_warp * len(self.softmax1_warp_ids),
            self.threads_per_warp * len(self.softmax1_warp_ids),
        )
        return utils.PipelineAsync.create(
            barrier_storage=si_sequence_mbar_ptr,
            num_stages=1,
            producer_group=s0_sequence_group,
            consumer_group=s1_sequence_group,
        )

    @staticmethod
    def _compute_grid(
        o: cute.Tensor,
        cta_tiler: Tuple[int, int, int],
        is_persistent: bool,
    ) -> Tuple[FmhaStaticTileSchedulerParams, Tuple[int, int, int]]:
        o_shape = o.shape
        tile_sched_params = create_fmha_static_tile_scheduler_params(
            is_persistent,
            (
                cute.ceil_div(cute.size(o_shape[0]), cta_tiler[0]),
                cute.size(o_shape[2][0]),
                cute.size(o_shape[2][1]),
            ),
        )
        grid = FmhaStaticTileScheduler.get_grid_shape(tile_sched_params)

        return tile_sched_params, grid


def run_fmha_and_verify(
    q_shape: Tuple[int, int, int, int],
    k_shape: Tuple[int, int, int, int],
    in_dtype: Type[cutlass.Numeric],
    out_dtype: Type[cutlass.Numeric],
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    mma_tiler_mn: Tuple[int, int],
    is_persistent: bool,
    has_casual_mask: bool,
    scale_q: float,
    scale_k: float,
    scale_v: float,
    inv_scale_o: float,
    scale_softmax: float,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
):
    """Execute Fused Multi-Head Attention (FMHA) on Blackwell architecture and validate results.

    This function creates random input tensors for query, key, and value, then performs the
    complete FMHA computation pipeline. It supports configurable data types, tiling parameters,
    and various attention masking options. Results can be validated against a PyTorch reference
    implementation or run multiple times for performance measurement.

    The implementation leverages specialized tensor memory operations and efficient math
    operations optimized for Blackwell architecture, including pipelined computation stages
    for maximum throughput.

    :param q_shape: Query tensor shape (B, S_q, H, D) where B=batch size, S_q=query sequence length,
                    H=number of heads, D=head dimension
    :type q_shape: Tuple[int, int, int, int]
    :param k_shape: Key tensor shape (B, S_k, H_k, D) where B=batch size, S_k=key sequence length,
                    H_k=number of key heads (H must be divisible by H_k), D=head dimension
    :type k_shape: Tuple[int, int, int, int]
    :param in_dtype: Input data type for query, key and value tensors
    :type in_dtype: Type[cutlass.Numeric]
    :param out_dtype: Output data type for attention output
    :type out_dtype: Type[cutlass.Numeric]
    :param qk_acc_dtype: Accumulator data type for query-key matrix multiplication
    :type qk_acc_dtype: Type[cutlass.Numeric]
    :param pv_acc_dtype: Accumulator data type for probability-value matrix multiplication
    :type pv_acc_dtype: Type[cutlass.Numeric]
    :param mma_tiler_mn: Matrix multiply accumulate tile shape (M, N)
    :type mma_tiler_mn: Tuple[int, int]
    :param is_persistent: Whether to use persistent kernel optimization
    :type is_persistent: bool
    :param has_casual_mask: Whether to apply causal masking
    :type has_casual_mask: bool
    :param scale_q: Scaling factor for query tensor
    :type scale_q: float
    :param scale_k: Scaling factor for key tensor
    :type scale_k: float
    :param scale_v: Scaling factor for value tensor
    :type scale_v: float
    :param inv_scale_o: Inverse scaling factor for output tensor
    :type inv_scale_o: float
    :param scale_softmax: Attention score scaling factor (defaults to 1/sqrt(D) if set to 0)
    :type scale_softmax: float
    :param tolerance: Maximum acceptable error for validation
    :type tolerance: float
    :param warmup_iterations: Number of warmup iterations
    :type warmup_iterations: int
    :param iterations: Number of iterations to run for performance testing
    :type iterations: int
    :param skip_ref_check: Skip validation against reference implementation
    :type skip_ref_check: bool

    :raises ValueError: If input shapes are incompatible or head dimension is unsupported
    :raises RuntimeError: If GPU is unavailable for computation
    """

    print(f"Running Blackwell SM100 FMHA test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  in_dtype: {in_dtype}")
    print(f"  out_dtype: {out_dtype}")
    print(f"  qk_acc_dtype: {qk_acc_dtype}")
    print(f"  pv_acc_dtype: {pv_acc_dtype}")
    print(f"  mma_tiler_mn: {mma_tiler_mn}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  has_casual_mask: {has_casual_mask}")
    print(f"  scale_q: {scale_q}")
    print(f"  scale_k: {scale_k}")
    print(f"  scale_v: {scale_v}")
    print(f"  inv_scale_o: {inv_scale_o}")
    print(f"  scale_softmax: {scale_softmax}")
    print(f"  tolerance: {tolerance}")

    # Unpack parameters
    b, s_q, h, d = q_shape
    b_, s_k, h_k, d_ = k_shape

    if b != b_:
        raise ValueError("q & k must have the same batch size")

    if d != d_:
        raise ValueError("q & k must have the same head dimension")

    if d not in {32, 64, 128}:
        raise ValueError("head dimension must be 32, 64, or 128")

    if h % h_k != 0:
        raise ValueError("h must be divisible by h_k")

    if in_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16}:
        raise ValueError("in_dtype must be Float8E4M3FN or Float16")

    if out_dtype not in {cutlass.Float8E4M3FN, cutlass.Float16}:
        raise ValueError("out_dtype must be Float8E4M3FN or Float16")

    if qk_acc_dtype not in {cutlass.Float32}:
        raise ValueError("qk_acc_dtype must be Float32")

    if pv_acc_dtype not in {cutlass.Float32}:
        raise ValueError("pv_acc_dtype must be Float32")

    if iterations < 1:
        raise ValueError("iterations must be at least 1")

    h_r = h // h_k

    # Prepare pytorch tensors: Q, K, V (random from 0 to 2) and O (all zero)
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    def create_and_permute_tensor(b, s, h_r, h_k, d, dtype, is_dynamic_layout=True):
        # (b, s, h_r, h_k, d) -> (s, d, h_r, h_k, b)
        shape = (b, s, h_r, h_k, d)
        permute_order = (1, 4, 2, 3, 0)
        is_fp8 = dtype in {cutlass.Float8E5M2, cutlass.Float8E4M3FN}

        # torch does not support fp8 type
        torch_dtype = cutlass.torch.dtype(dtype) if not is_fp8 else torch.uint8

        # Create dtype torch tensor (cpu)
        torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            shape,
            torch_dtype,
            permute_order=permute_order,
            init_type=cutlass.torch.TensorInitType.RANDOM,
            init_config=cutlass.torch.RandomInitConfig(
                min_val=0 if is_fp8 else -2, max_val=2
            ),
        )
        # Create dtype torch tensor (gpu)
        torch_tensor_gpu = torch_tensor_cpu.cuda()

        # Create f32 torch tensor (cpu)
        f32_torch_tensor = torch_tensor_cpu.to(dtype=torch.float32)

        # Create dtype cute tensor (gpu)
        cute_tensor = from_dlpack(torch_tensor_gpu, assumed_align=16)
        cute_tensor.element_type = dtype
        if is_dynamic_layout:
            cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=1)
        cute_tensor = cutlass_torch.convert_cute_tensor(
            f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=is_dynamic_layout,
        )

        return f32_torch_tensor, cute_tensor, torch_tensor_gpu

    q_ref, q_tensor, q_torch = create_and_permute_tensor(
        b, s_q, h_r, h_k, d, in_dtype, is_dynamic_layout=True
    )
    k_ref, k_tensor, k_torch = create_and_permute_tensor(
        b, s_k, 1, h_k, d, in_dtype, is_dynamic_layout=True
    )
    v_ref, v_tensor, v_torch = create_and_permute_tensor(
        b, s_k, 1, h_k, d, in_dtype, is_dynamic_layout=True
    )
    o_ref, o_tensor, o_torch = create_and_permute_tensor(
        b, s_q, h_r, h_k, d, out_dtype, is_dynamic_layout=True
    )

    mma_tiler = (*mma_tiler_mn, d)

    mask_type = MaskType.NO_MASK
    if has_casual_mask:
        mask_type = MaskType.CAUSAL_MASK
    else:
        if s_k % mma_tiler_mn[1] != 0:
            mask_type = MaskType.RESIDUAL_MASK

    fmha = BlackwellFusedMultiHeadAttentionForward(
        qk_acc_dtype,
        pv_acc_dtype,
        mma_tiler,
        is_persistent,
        mask_type,
    )

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    if scale_softmax == 0.0:  # default to 1/sqrt(d)
        scale_softmax = 1.0 / math.sqrt(q_shape[1])
    log2_e = math.log2(
        math.exp(1.0)
    )  # gpu uses exp2 for perf concerns, we need an extra factor 'log2_e' here

    scale_softmax = scale_q * scale_k * scale_softmax
    scale_softmax_log2 = scale_softmax * log2_e
    scale_output = scale_v * inv_scale_o

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    # compile fmha kernel
    compiled_fmha = cute.compile(
        fmha,
        q_tensor,
        k_tensor,
        v_tensor,
        o_tensor,
        scale_softmax_log2,
        scale_output,
        current_stream,
    )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    # Warmup
    for _ in range(warmup_iterations):
        compiled_fmha(
            q_tensor,
            k_tensor,
            v_tensor,
            o_tensor,
            scale_softmax_log2,
            scale_output,
            current_stream,
        )

    # Execute kernel
    for _ in range(iterations):
        compiled_fmha(
            q_tensor,
            k_tensor,
            v_tensor,
            o_tensor,
            scale_softmax_log2,
            scale_output,
            current_stream,
        )

    torch.cuda.synchronize()

    def run_torch_fmha(
        q, k, v, scale_softmax=1.0, scale_output=1.0, has_casual_mask=False
    ):
        s_q, d, h_r, h_k, b = q.shape
        s_k = k.shape[0]

        # broadcast k and v to have the same shape as q
        k = k.expand(s_k, d, h_r, h_k, b)
        v = v.expand(s_k, d, h_r, h_k, b)

        q_tmp = q.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_q, d)
        k_tmp = k.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_k, d)
        v_tmp = v.permute(4, 2, 3, 0, 1).contiguous().view(b, -1, s_k, d)

        ref = F.scaled_dot_product_attention(
            q_tmp,
            k_tmp,
            v_tmp,
            attn_mask=None,
            dropout_p=0.0,
            scale=scale_softmax,
            is_causal=has_casual_mask,
        )
        ref = ref.view(b, h_r, h_k, s_q, d).permute(3, 4, 1, 2, 0) * scale_output

        return ref

    if not skip_ref_check:
        print("Verifying results...")
        ref = run_torch_fmha(
            q_ref, k_ref, v_ref, scale_softmax, scale_output, has_casual_mask
        )

        # Copy gpu result back
        gpu_o = o_torch.cpu()

        # convert ref to out_type
        if out_dtype == cutlass.Float16:
            ref_o = ref.to(cutlass.torch.dtype(out_dtype))
        elif out_dtype in {cutlass.Float8E4M3FN, cutlass.Float8E5M2}:
            # convert ref : f32 -> fp8 -> f32
            permute_order_0 = (4, 0, 2, 3, 1)
            permute_order_1 = (1, 4, 2, 3, 0)

            shape = (b, s_q, h_r, h_k, d)

            f8_torch_tensor = cutlass.torch.create_and_permute_torch_tensor(
                shape,
                torch.uint8,
                permute_order=permute_order_1,
                init_type=cutlass.torch.TensorInitType.SKIP,
            ).cuda()

            # Create dtype tensor (gpu)
            ref_o_tensor = from_dlpack(
                f8_torch_tensor, assumed_align=16
            ).mark_layout_dynamic(leading_dim=1)
            ref_o_tensor.element_type = out_dtype
            ref_o_tensor = cutlass.torch.convert_cute_tensor(
                # ref for torch tensor is contiguous in shape (b, h_r, h_k, s_q, d), but shape is (s, d, h_r, h_k, b)
                # need to make it contiguous first then permute
                ref.permute(permute_order_0).contiguous().permute(permute_order_1).cuda(),
                ref_o_tensor,
                out_dtype,
                is_dynamic_layout=True,
            )

            ref_o = f8_torch_tensor.cpu()

            # uint8 check; the minimum difference is 1
            tolerance = 2
        else:
            pass

        # Assert close results
        torch.testing.assert_close(gpu_o, ref_o, atol=tolerance, rtol=1e-05)
        print("Results verified successfully!")

if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(description="Example of FMHA on Blackwell.")

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Input data type",
    )

    parser.add_argument(
        "--out_dtype",
        type=cutlass.dtype,
        default=cutlass.Float16,
        help="Output data type",
    )

    parser.add_argument(
        "--qk_acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="QK accumulator data type",
    )

    parser.add_argument(
        "--pv_acc_dtype",
        type=cutlass.dtype,
        default=cutlass.Float32,
        help="PV accumulator data type",
    )

    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="MMA tile shape (M, N)",
    )

    parser.add_argument(
        "--is_persistent",
        action="store_true",
        help="Is persistent",
    )

    parser.add_argument(
        "--has_casual_mask",
        action="store_true",
        help="Whether to use casual mask",
    )

    parser.add_argument(
        "--q_shape",
        type=parse_comma_separated_ints,
        default=(1, 256, 8, 128),
        help="Shape of Q (B, S_q, H, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_comma_separated_ints,
        default=(1, 256, 8, 128),
        help="Shape of K (B, S_k, H_k, D)",
    )

    parser.add_argument(
        "--scale_q",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize Q",
    )

    parser.add_argument(
        "--scale_k",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize K",
    )

    parser.add_argument(
        "--scale_v",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize V",
    )

    parser.add_argument(
        "--inv_scale_o",
        type=float,
        default=1.0,
        help="Scaling factor to quantize O",
    )

    parser.add_argument(
        "--scale_softmax",
        type=float,
        default=0.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of iterations for warmup",
    )

    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations after warmup",
    )

    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference check",
    )

    args = parser.parse_args()

    if len(args.q_shape) != 4:
        parser.error("--q_shape must contain exactly 4 values")

    if len(args.k_shape) != 4:
        parser.error("--k_shape must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    run_fmha_and_verify(
        args.q_shape,
        args.k_shape,
        args.in_dtype,
        args.out_dtype,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.mma_tiler_mn,
        args.is_persistent,
        args.has_casual_mask,
        args.scale_q,
        args.scale_k,
        args.scale_v,
        args.inv_scale_o,
        args.scale_softmax,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
    )

    print("PASS")
