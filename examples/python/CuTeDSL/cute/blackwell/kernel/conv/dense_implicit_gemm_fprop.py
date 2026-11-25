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
from typing import Optional, Tuple, Type, Union, Literal
from functools import lru_cache
import cuda.bindings.driver as cuda
import sys

import torch
import torch.nn.functional as F

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute.runtime import from_dlpack
from cutlass.torch import dtype as torch_dtype
import cutlass.utils as utils
from cutlass.memory import (
    SmemAllocator,
    TmemAllocator,
    get_smem_capacity_in_bytes,
)
from cutlass.tensor_utils import LayoutEnum
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
from pathlib import Path

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.dynamic_persistent_tile_scheduler import (
    ClcDynamicPersistentTileScheduler,
    ClcDynamicPersistentTileSchedulerParams,
)
from helpers.conv_helpers import (
    EPILOGUE_ACTIVATIONS,
    SMEM_BUFFER_ALIGN_BYTES,
    SMEM_VECTOR_ALIGN_BYTES,
    add_dummy_batch_dimension,
    bias_dtype_for_output,
    check_conv_geometry,
    check_im2col_descriptor_limits,
    check_cluster_shape,
    check_preferred_cluster_problem_size,
    check_swizzle_size,
    check_tensor_alignment,
    compute_grid,
    compute_zpq,
    create_cute_tensor,
    frontend_cache_token,
    make_fake_conv_tensor,
    parse_comma_separated_ints,
    prepare_fprop_tensors,
    rt_conv_scalars,
    solve_max_smem_stages,
    trace_conv_scalars,
)

"""
A high-performance 3D implicit-GEMM based fprop convolution example for the NVIDIA
Blackwell SM100 architecture using CUTE DSL.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor D is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Operand loads: the input tensor A by Tensor Memory Access (TMA) im2col, which
      performs the
      im2col transformation on the fly, and the filter tensor B by TMA tiled
    - Utilizes Blackwell's tcgen05 MMA for matrix multiply-accumulate (MMA) operations
      (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - CLC-based dynamic persistent tile scheduling
    - Fused epilogue computing in FP32, D = activation(alpha * acc + bias + beta *
      residual),
      with an optional per-output-channel bias and a compile-time activation; this
      kernel
      currently supports only alpha = 1 and beta = 0

This implicit-GEMM based convolution works by converting the convolution into a GEMM
problem with the following mapping:
- GEMM M dimension maps to NxZxPxQ
- GEMM N dimension maps to K
- GEMM K dimension maps to TxRxSxC
During the load of input tensor to SMEM, the TMA operation performs the im2col
transformation on the input tensor A.
This transforms the A matrix into the required shape for the GEMM operation (NxZxPxQ by
TxRxSxC), and may involve replication of the input elements.
Filter tensor can be loaded to SMEM without any transformation.
The output tensor D is then stored to GMEM via the im2col TMA store (no transformation
necessary).

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/cute/blackwell/kernel/conv/dense_implicit_gemm_fprop.py            \
      --ncdhw 1,128,32,32,32 --ktrs 256,3,3,3                         \
      --ab_dtype Float16 --d_dtype Float16 --acc_dtype Float32        \
      --use_2cta_instrs --mma_tiler_mn 256,128                        \
      --preferred_cluster_shape_mn 2,1 --fallback_cluster_shape_mn 2,1 \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                     \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/CuTeDSL/cute/blackwell/kernel/conv/dense_implicit_gemm_fprop.py        \
      --ncdhw 1,128,32,32,32 --ktrs 256,3,3,3                         \
      --ab_dtype Float16 --d_dtype Float16 --acc_dtype Float32        \
      --use_2cta_instrs --mma_tiler_mn 256,128                        \
      --preferred_cluster_shape_mn 2,1 --fallback_cluster_shape_mn 2,1 \
      --upper_pad_dhw 1,1,1 --lower_pad_dhw 1,1,1                     \
      --stride_dhw 1,1,1 --dil_dhw 1,1,1                                \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2),
  see detailed valid dtype combinations in below
  Sm100DenseImplicitGemmFpropKernel class documentation
* A/B tensor must have the same data type
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* Mma tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* Preferred cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Preferred cluster shape M must be multiple of 2 if use_2cta_instrs=True
* Preferred cluster shape M/N must be multiple of fallback cluster shape M/N
* The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
"""


class Sm100DenseImplicitGemmFpropKernel:
    """
    Persistent 3D convolution kernel.
    The input (A) is expected to be in 5D tensor (NDHWC) format and is loaded via the
    TMA im2col load atom.
    The filter (B) is expected to be in 5D tensor (KTRSC) format and is loaded via the
    TMA tiled load atom.
    The output (D) is expected to be in 5D tensor (NZPQK) format and is stored via the
    im2col TMA store.
    One kernel carries a code path per cluster shape and runs the one matching the
    cluster the launch actually formed, so a single launch serves both the preferred
    and the fallback cluster.

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tiler (M,N)
    :type mma_tiler_mn: Tuple[int, int]
    :param preferred_cluster_shape_mn: Preferred cluster dimensions (M,N) for optimal
        performance
    :type preferred_cluster_shape_mn: Tuple[int, int]
    :param fallback_cluster_shape_mn: Fallback cluster dimensions (M,N) for parallel
        processing
    :type fallback_cluster_shape_mn: Tuple[int, int]
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :type swizzle_size: int
    :param raster_along: Rasterization order of clusters. Only used when swizzle_size >
        1.
    :type raster_along: Literal["m", "n"]

    :note: The convolution geometry (filter T/R/S, padding, stride, dilation) is not a
        constructor parameter: T/R/S come from the filter tensor extents and
        pad/stride/dilation arrive as runtime Int32 operands to __call__, so a single
        compiled cubin serves any geometry.

    :note: In current version, A and B tensor must be C major. D tensor must be K major.

    :note: In current version, A and B tensor must have the same data type
        - i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported

    :note: Supported A/B data types:
        - TFloat32
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported D data types:
        - Float32, Float16/BFloat16, Int32, Int8/Uint8 (for float32 and int32
          accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: The epilogue arithmetic runs in FP32 for every accumulator type, so an
        Int32 output is the FP32 result converted back to Int32.

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256
          (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - Preferred cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Preferred cluster shape M/N must be positive and power of 2, total cluster
          size <= 16
        - Preferred cluster shape M/N must be multiple of fallback cluster shape M/N
        - The contiguous dimension of A/B/D tensors must be at least 16 bytes aligned,
          i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
          Float16/BFloat16, and Int8/Uint8/Float8, respectively

    **Example:**

    .. code-block:: python
        conv = Sm100DenseImplicitGemmFpropKernel(
            acc_dtype=cutlass.Float32,
            use_2cta_instrs=True,
            mma_tiler_mn=(128, 128),
            preferred_cluster_shape_mn=(4, 2),
            fallback_cluster_shape_mn=(2, 1),
        )
        conv(
            a, b, d,
            bias,  # optional length-K bias tensor, or None
            upper_pad_d, upper_pad_h, upper_pad_w,
            lower_pad_d, lower_pad_h, lower_pad_w,
            stride_d, stride_h, stride_w,
            dil_d, dil_h, dil_w,
            stream,
            epilogue_op,
        )
    """

    # The epilogue warps are fixed for every configuration, so they live on the
    # class, where static checks can read them.
    epilogue_warp_id = (0, 1, 2, 3)

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        swizzle_size: int = 1,
        raster_along: Literal["m", "n"] = "m",
    ):
        self.acc_dtype: Type[cutlass.Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        # cluster_shape_mn is the fallback cluster shape, which every launch is
        # guaranteed to be able to form; the fallback cluster layout and its
        # multicast counts are sized against it.
        self.cluster_shape_mn = fallback_cluster_shape_mn
        self.swizzle_size = swizzle_size
        self.raster_along = raster_along
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.arch = "sm_100"
        # Shared memory capacity of the compile target.
        self.smem_capacity = get_smem_capacity_in_bytes()

        self.num_clc_stage = 1
        # Response size is 4B * 4 elements
        self.num_clc_response_bytes = 16

        self.cta_group = (
            tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        self.tiled_mma = None

        # Set specialized warp ids
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.sched_warp_id = 6
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                self.sched_warp_id,
                *self.epilogue_warp_id,
            )
        )
        # Set barrier ids for the epilogue sync and the tmem ptr sync
        self.epilog_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2

        # Both shapes are kept: the kernel dispatches on which one the launch
        # actually formed.
        self.preferred_cluster_shape_mn = preferred_cluster_shape_mn
        self.fallback_cluster_shape_mn = fallback_cluster_shape_mn

    def _setup_conv_input_attrs(self, a, b, d) -> None:
        """Set input-dependent attributes.

        Sets a_dtype, b_dtype, d_dtype, a_major_mode, b_major_mode, d_layout.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        """
        self.a_dtype: Type[cutlass.Numeric] = a.element_type
        self.b_dtype: Type[cutlass.Numeric] = b.element_type
        self.d_dtype: Type[cutlass.Numeric] = d.element_type
        self.a_major_mode = cute.nvgpu.OperandMajorMode.K
        self.b_major_mode = cute.nvgpu.OperandMajorMode.K
        self.d_layout = LayoutEnum.ROW_MAJOR  # K dimension contiguous

    def _setup_attributes(self) -> None:
        """Set up configurations that are dependent on convolution inputs."""
        # --- MMA and tile shapes ---
        self.tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )
        mma_inst_shape_k = cute.size(self.tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            (mma_inst_shape_k * mma_inst_tile_k,),
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(self.tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        # --- Epilogue tile ---
        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )

        # --- Pipeline stages and smem layouts ---
        # ACC double-buffers in TMEM.
        self.num_acc_stage = 2
        self._solve_smem_stages(Sm100DenseImplicitGemmFpropKernel._make_shared_storage)
        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.d_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            self.num_ab_stage,
            self.num_d_stage,
        )

        # --- TMA transaction bytes and TMEM columns ---
        # Compute the TMA transaction bytes of one A/B stage across the MMA atom's CTAs
        atom_thr_size = cute.size(self.tiled_mma.thr_id.shape)
        a_smem_layout = cute.select(self.a_smem_layout_staged, mode=[0, 1, 2])
        b_smem_layout = cute.select(self.b_smem_layout_staged, mode=[0, 1, 2])
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Compute the number of tensor memory allocation columns
        self.num_tmem_alloc_cols = self._compute_num_tmem_alloc_cols(
            self.tiled_mma, self.mma_tiler, self.num_acc_stage, self.arch
        )

        # --- Cluster layouts ---
        self._setup_cluster_attrs()

    def _solve_smem_stages(self, make_shared_storage) -> None:
        """Solve the A/B and D pipeline stage counts that fit in shared memory.

        :param make_shared_storage: Unbound _make_shared_storage of the kernel
            class, called with self for every candidate stage assignment
        """
        # The D-store ring starts at two and deepens with whatever smem the A/B
        # pipeline leaves over -- A/B depth is filled first. Both are solved
        # against the exact SharedStorage footprint so the stage-scaled
        # mbarriers, the optional bias row and every alignment pad are accounted
        # for.
        counts = solve_max_smem_stages(
            lambda **kw: make_shared_storage(self, **kw),
            self.smem_capacity,
            primary="num_ab_stage",
            start={"num_ab_stage": 1, "num_d_stage": 2},
            deepen=("num_d_stage",),
        )
        self.num_ab_stage = counts["num_ab_stage"]
        self.num_d_stage = counts["num_d_stage"]

    def _setup_cluster_attrs(self) -> None:
        """Set up the preferred and fallback cluster layouts and their A/B multicast."""
        self.preferred_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.preferred_cluster_shape_mn, 1)),
            (self.tiled_mma.thr_id.shape,),
        )
        self.num_preferred_mcast_ctas_a = cute.size(
            self.preferred_cluster_layout_vmnk.shape[2]
        )
        self.num_preferred_mcast_ctas_b = cute.size(
            self.preferred_cluster_layout_vmnk.shape[1]
        )
        self.is_preferred_a_mcast = self.num_preferred_mcast_ctas_a > 1
        self.is_preferred_b_mcast = self.num_preferred_mcast_ctas_b > 1

        self.fallback_cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self.tiled_mma.thr_id.shape,),
        )
        self.num_fallback_mcast_ctas_a = cute.size(
            self.fallback_cluster_layout_vmnk.shape[2]
        )
        self.num_fallback_mcast_ctas_b = cute.size(
            self.fallback_cluster_layout_vmnk.shape[1]
        )
        self.is_fallback_a_mcast = self.num_fallback_mcast_ctas_a > 1
        self.is_fallback_b_mcast = self.num_fallback_mcast_ctas_b > 1

    def _setup_conv_tma(
        self,
        a,
        b,
        d,
        tiled_mma,
        rt_upper_pad_dhw,
        rt_lower_pad_dhw,
        rt_stride_dhw,
        rt_dil_dhw,
    ):
        """Set up TMA atoms and tensors for im2col convolution with dual cluster shapes.

        Creates preferred and fallback TMA atoms for A and B tensors, and a single
        TMA atom for D (im2col store is cluster-independent).

        The pad / stride / dilation operands feed the im2col A descriptor corners.
        They arrive as runtime cutlass.Int32, which the rt_ prefix marks, so one
        compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param tiled_mma: Tiled MMA configuration
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)
        :returns: (tma_atom_a_preferred, tma_tensor_a_preferred,
                tma_atom_a_fallback, tma_tensor_a_fallback,
                tma_atom_b_preferred, tma_tensor_b_preferred,
                tma_atom_b_fallback, tma_tensor_b_fallback,
                tma_atom_d, tma_tensor_d)
        """
        (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
        ) = self._make_a_im2col_tma_atoms(
            a,
            b,
            tiled_mma,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        (
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
        ) = self._make_b_tiled_tma_atoms(b, tiled_mma)

        # --- D: im2col TMA store (cluster-independent) ---
        # Change view of output tensor from (N, Z, P, Q, K) to ((Q, P, Z, N), K)
        mD = cute.make_tensor(d.iterator, cute.select(d.layout, mode=[3, 2, 1, 0, 4]))
        mD = cute.group_modes(mD, begin=0, end=4)

        epi_smem_layout = cute.slice_(
            self.d_smem_layout_staged, (None, None, (None, 0))
        )

        tma_atom_d, tma_tensor_d = cpasync.make_im2col_tma_atom(
            cpasync.CopyBulkTensorIm2ColS2GOp(),
            mD,
            epi_smem_layout,
            self.epi_tile,
        )
        tma_tensor_d = cute.coalesce(tma_tensor_d, target_profile=(1, 1))

        # Add dummy batch dimension to all tensors (GEMM expects batch dimension)
        tma_tensor_a_preferred = add_dummy_batch_dimension(tma_tensor_a_preferred)
        tma_tensor_a_fallback = add_dummy_batch_dimension(tma_tensor_a_fallback)
        tma_tensor_b_preferred = add_dummy_batch_dimension(tma_tensor_b_preferred)
        tma_tensor_b_fallback = add_dummy_batch_dimension(tma_tensor_b_fallback)
        tma_tensor_d = add_dummy_batch_dimension(tma_tensor_d)

        return (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_d,
            tma_tensor_d,
        )

    def _make_a_im2col_tma_atoms(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        tiled_mma: cute.TiledMma,
        rt_upper_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_lower_pad_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_stride_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
        rt_dil_dhw: Tuple[cutlass.Int32, cutlass.Int32, cutlass.Int32],
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """Make A's preferred and fallback im2col TMA load atoms.

        A is the operand the im2col descriptor walks: it is viewed as
        ((W, H, D, N), C) so the descriptor's box slides over the spatial modes,
        and its corners come from the runtime pad/stride/dilation operands and the
        filter tensor's own extents. The two atoms differ only in the cluster shape
        they multicast over, and each drops the multicast op when its cluster does
        not multicast A.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param tiled_mma: Tiled MMA configuration
        :param rt_upper_pad_dhw: Upper padding (D, H, W)
        :param rt_lower_pad_dhw: Lower padding (D, H, W)
        :param rt_stride_dhw: Convolution stride (D, H, W)
        :param rt_dil_dhw: Dilation (D, H, W)

        :return: (tma_atom_a_preferred, tma_tensor_a_preferred,
                tma_atom_a_fallback, tma_tensor_a_fallback)
        """
        # Create 2-mode hierarchical tensor layout: (N, D, H, W, C) -> ((W, H, D, N), C)
        mA = cute.make_tensor(a.iterator, cute.select(a.layout, mode=[3, 2, 1, 0, 4]))
        mA = cute.group_modes(mA, begin=0, end=4)

        a_smem_layout = cute.select(self.a_smem_layout_staged, mode=[0, 1, 2])
        a_internal_type = (
            cutlass.TFloat32 if mA.element_type is cutlass.Float32 else None
        )

        # Filter T/R/S come from the filter tensor (K, T, R, S, C), whose dynamic
        # layout makes the extents runtime Int32, so one cubin serves any T/R/S.
        rt_filter_trs = (b.shape[1], b.shape[2], b.shape[3])

        # --- A preferred ---
        a_copy_atom_preferred = (
            cpasync.CopyBulkTensorIm2ColG2SMulticastOp(cta_group=self.cta_group)
            if self.is_preferred_a_mcast
            else cpasync.CopyBulkTensorIm2ColG2SOp(cta_group=self.cta_group)
        )
        tma_atom_a_preferred, tma_tensor_a_preferred = (
            cute.nvgpu.make_im2col_tma_atom_A(
                a_copy_atom_preferred,
                mA,
                a_smem_layout,
                self.mma_tiler,
                tiled_mma,
                rt_filter_trs,
                rt_upper_pad_dhw,
                rt_lower_pad_dhw,
                rt_stride_dhw,
                rt_dil_dhw,
                self.preferred_cluster_layout_vmnk.shape,
                internal_type=a_internal_type,
            )
        )

        # --- A fallback ---
        a_copy_atom_fallback = (
            cpasync.CopyBulkTensorIm2ColG2SMulticastOp(cta_group=self.cta_group)
            if self.is_fallback_a_mcast
            else cpasync.CopyBulkTensorIm2ColG2SOp(cta_group=self.cta_group)
        )
        tma_atom_a_fallback, tma_tensor_a_fallback = cute.nvgpu.make_im2col_tma_atom_A(
            a_copy_atom_fallback,
            mA,
            a_smem_layout,
            self.mma_tiler,
            tiled_mma,
            rt_filter_trs,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=a_internal_type,
        )
        return (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
        )

    def _make_b_tiled_tma_atoms(
        self,
        b: cute.Tensor,
        tiled_mma: cute.TiledMma,
    ) -> Tuple[cute.CopyAtom, cute.Tensor, cute.CopyAtom, cute.Tensor]:
        """Make B's preferred and fallback tiled TMA load atoms.

        B is the filter, which reaches shared memory without any transformation: it
        is viewed as (K, (C, S, R, T)) so its GEMM-K mode groups the channel and
        filter-spatial modes. The two atoms differ only in the cluster shape they
        multicast over.

        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param tiled_mma: Tiled MMA configuration

        :return: (tma_atom_b_preferred, tma_tensor_b_preferred,
                tma_atom_b_fallback, tma_tensor_b_fallback)
        """
        b_smem_layout = cute.select(self.b_smem_layout_staged, mode=[0, 1, 2])
        # Change view of filter tensor from (K, T, R, S, C) to (K, (C, S, R, T))
        mB = cute.make_tensor(b.iterator, cute.select(b.layout, mode=[0, 4, 3, 2, 1]))
        mB = cute.group_modes(mB, begin=1, end=5)
        b_internal_type = (
            cutlass.TFloat32 if mB.element_type is cutlass.Float32 else None
        )

        # --- B preferred ---
        b_op_preferred = sm100_utils.cluster_shape_to_tma_atom_B(
            self.preferred_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_preferred, tma_tensor_b_preferred = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_preferred,
            mB,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.preferred_cluster_layout_vmnk.shape,
            internal_type=b_internal_type,
        )

        # --- B fallback ---
        b_op_fallback = sm100_utils.cluster_shape_to_tma_atom_B(
            self.fallback_cluster_shape_mn, tiled_mma.thr_id
        )
        tma_atom_b_fallback, tma_tensor_b_fallback = cute.nvgpu.make_tiled_tma_atom_B(
            b_op_fallback,
            mB,
            b_smem_layout,
            self.mma_tiler,
            tiled_mma,
            self.fallback_cluster_layout_vmnk.shape,
            internal_type=b_internal_type,
        )
        return (
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
        )

    @staticmethod
    def _make_smem_layouts(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        d_layout: LayoutEnum,
        epi_tile: cute.Tile,
        num_ab_stage: int,
        num_d_stage: int,
    ) -> Tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]:
        """Build the staged shared memory layouts for A, B and the epilogue.

        :param tiled_mma: The tiled MMA the operands feed
        :param mma_tiler: The MMA tiler shape (M, N, K)
        :param a_dtype: Element type of A
        :param b_dtype: Element type of B
        :param d_dtype: Element type of D
        :param d_layout: Layout enum of D
        :param epi_tile: The epilogue tiler
        :param num_ab_stage: Number of A/B pipeline stages
        :param num_d_stage: Number of epilogue pipeline stages

        :return: The A, B and epilogue layouts, each staged
        """
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma, mma_tiler, a_dtype, num_ab_stage
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma, mma_tiler, b_dtype, num_ab_stage
        )
        d_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            d_dtype, d_layout, epi_tile, num_d_stage
        )
        return a_smem_layout_staged, b_smem_layout_staged, d_smem_layout_staged

    def _make_shared_storage(self, *, num_ab_stage: int, num_d_stage: int):
        """Complete shared-memory layout for one candidate stage assignment.

        Stage selection sizes candidates through it and the device entry allocates
        through it. Every shared-memory consumer of this kernel is a field here, in
        three runs: pipeline barriers, small odds and ends, then the tensor buffers.
        """
        a_smem, b_smem, d_smem = self._make_smem_layouts(
            self.tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.b_dtype,
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            num_ab_stage,
            num_d_stage,
        )
        num_acc_stage = self.num_acc_stage
        num_clc_stage = self.num_clc_stage
        num_clc_response_bytes = self.num_clc_response_bytes
        has_bias = self.has_bias
        cta_tile_n = self.cta_tile_shape_mnk[1]
        a_dtype, b_dtype, d_dtype = self.a_dtype, self.b_dtype, self.d_dtype
        bias_dtype = self.bias_dtype if has_bias else d_dtype
        align = SMEM_BUFFER_ALIGN_BYTES

        @cute.struct
        class SharedStorage:
            # Pipeline barriers, in construction order.
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_ab_stage * 2]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_acc_stage * 2]
            tmem_dealloc_mbar: cutlass.Int64
            clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, num_clc_stage * 2]
            # Small odds and ends.
            tmem_holding_buf: cutlass.Int32
            clc_response: cute.struct.Align[
                cute.struct.MemRange[
                    cutlass.Int32, num_clc_response_bytes // 4 * num_clc_stage
                ],
                16,  # Align bytes
            ]
            # Tensor buffers, last: epilogue staging first, then the mainloop
            # operand buffers at the very end of the storage, which keeps every
            # other field's offset fixed when an operand buffer grows.
            # (EPI_TILE_M, EPI_TILE_N, STAGE)
            sD: cute.struct.Align[
                cute.struct.MemRange[d_dtype, cute.cosize(d_smem.outer)], align
            ]
            # (cta_tile_n,) staged bias row: one value per output channel of the
            # CTA tile, fetched once and read back by every epilogue thread. It
            # carries the bias element type, which has a 16-bit floor and so can be
            # wider than the output. Sized to zero when no bias is supplied so it
            # costs no smem.
            sBias: cute.struct.Align[
                cute.struct.MemRange[bias_dtype, cta_tile_n if has_bias else 0],
                SMEM_VECTOR_ALIGN_BYTES,
            ]
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[a_dtype, cute.cosize(a_smem.outer)], align
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[b_dtype, cute.cosize(b_smem.outer)], align
            ]

        return SharedStorage

    @staticmethod
    def _compute_num_tmem_alloc_cols(
        tiled_mma: cute.TiledMma,
        mma_tiler: Tuple[int, int, int],
        num_acc_stage: int,
        arch: str,
    ) -> int:
        """
        Compute the number of tensor memory allocation columns.

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

    def epilog_tmem_copy_and_partition(
        self,
        tidx: cutlass.Int32,
        tAcc: cute.Tensor,
        tCgD: cute.Tensor,
        epi_tile: cute.Tile,
        use_2cta_instrs: Union[cutlass.Boolean, bool],
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for tensor memory load, then use it to partition tensor
        memory (source) and register array (destination).

        :param tidx: The thread index in epilogue warp groups
        :param tAcc: The accumulator tensor to be copied and partitioned
        :param tCgD: The global tensor D to be copied and partitioned
        :param epi_tile: The epilogue tiler
        :param use_2cta_instrs: Whether use_2cta_instrs is enabled

        :return: A tuple containing (tiled_copy_t2r, tTR_tAcc, tTR_rAcc) where:
            - tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
            - tTR_tAcc: The partitioned accumulator tensor
            - tTR_rAcc: The accumulated tensor in register used to hold t2r results
        """
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            self.cta_tile_shape_mnk,
            self.d_layout,
            self.d_dtype,
            self.acc_dtype,
            epi_tile,
            use_2cta_instrs,
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
        tAcc_epi = cute.flat_divide(tAcc, epi_tile)
        # (EPI_TILE_M, EPI_TILE_N)
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
        )

        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
        tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        tCgD_epi = cute.flat_divide(tCgD, epi_tile)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        tTR_gD = thr_copy_t2r.partition_D(tCgD_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gD[(None, None, None, 0, 0, 0, 0, 0)].shape, self.acc_dtype
        )
        return tiled_copy_t2r, tTR_tAcc, tTR_rAcc

    def epilog_smem_store_copy_and_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tTR_rD: cute.Tensor,
        tidx: cutlass.Int32,
        sD: cute.Tensor,
    ) -> Tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
        """Make tiledCopy for shared memory store, then use it to partition register
        array (source) and shared memory (destination).

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :param tTR_rD: The partitioned accumulator tensor
        :param tidx: The thread index in epilogue warp groups
        :param sD: The shared memory tensor to be copied and partitioned

        :return: A tuple containing (tiled_copy_r2s, tRS_rD, tRS_sD) where:
            - tiled_copy_r2s: The tiled copy operation for register to smem copy(r2s)
            - tRS_rD: The partitioned tensor D (register source)
            - tRS_sD: The partitioned tensor D (smem destination)
        """
        copy_atom_r2s = sm100_utils.get_smem_store_op(
            self.d_layout, self.d_dtype, self.acc_dtype, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sD = thr_copy_r2s.partition_D(sD)
        # (R2S, R2S_M, R2S_N)
        tRS_rD = tiled_copy_r2s.retile(tTR_rD)
        return tiled_copy_r2s, tRS_rD, tRS_sD

    def epilog_gmem_copy_and_partition(
        self,
        atom: Union[cute.CopyAtom, cute.TiledCopy],
        gD: cute.Tensor,
        epi_tile: cute.Tile,
        sD: cute.Tensor,
    ) -> Tuple[cute.Tensor, cute.Tensor]:
        """Partition the TMA store's shared-memory source and global-memory destination.

        :param atom: The TMA copy atom for D
        :type atom: cute.CopyAtom or cute.TiledCopy
        :param gD: The global tensor D, already in the epilogue's partitioned layout
        :type gD: cute.Tensor
        :param epi_tile: The epilogue tiler
        :type epi_tile: cute.Tile
        :param sD: The shared memory tensor to be partitioned
        :type sD: cute.Tensor

        :return: A tuple containing (bSG_sD, bSG_gD) where:
            - bSG_sD: The partitioned shared memory tensor D
            - bSG_gD: The partitioned global tensor D
        :rtype: Tuple[cute.Tensor, cute.Tensor]
        """
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
        gD_epi = cute.flat_divide(gD, epi_tile)
        # ((ATOM_V, REST_V), EPI_M, EPI_N[, RestM, RestN, RestL])
        return cpasync.tma_partition(
            atom,
            0,
            cute.make_layout(1),
            cute.group_modes(sD, 0, 2),
            cute.group_modes(gD_epi, 0, 2),
        )

    def epilog_bias_smem_partition(
        self,
        tiled_copy_t2r: cute.TiledCopy,
        tidx: cutlass.Int32,
        sBias: cute.Tensor,
        epi_tile: cute.Tile,
    ) -> cute.Tensor:
        """Partition the CTA-staged bias row for the epilogue's shared memory reads.

        The row holds this CTA tile's output channels, so it is viewed as a CTA
        tile whose N axis is the channel (stride 1) and whose M axis repeats it
        (stride 0), then partitioned through the same tmem->rmem thread layout as
        the accumulator. Rooting that partition at the row itself is what puts a
        thread's own tile-local N offset on the shared memory pointer: whenever
        the CTA tile has fewer M rows than the epilogue has threads, the thread
        layout also spans N, and a partition rooted anywhere else hands every
        such thread the columns of the thread at N offset zero.

        :param tiled_copy_t2r: The tiled copy operation for tmem to register copy(t2r)
        :param tidx: The thread index in epilogue warp groups
        :param sBias: The staged bias row, one value per output channel of this CTA tile
        :param epi_tile: The epilogue tiler

        :return: The staged row partitioned as (T2R, T2R_M, T2R_N, SUBTILE), with
            the subtiles grouped to index alongside the accumulator's
        """
        # (cta_tile_m, cta_tile_n) - one channel per N column, repeated over M
        sBias_mn = cute.make_tensor(
            sBias.iterator,
            cute.make_layout(
                (self.cta_tile_shape_mnk[0], self.cta_tile_shape_mnk[1]),
                stride=(0, 1),
            ),
        )
        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
        sBias_epi = cute.flat_divide(sBias_mn, epi_tile)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
        tTR_sBias = tiled_copy_t2r.get_slice(tidx).partition_D(sBias_epi)
        return cute.group_modes(tTR_sBias, 3, 5)

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        d: cute.Tensor,
        bias: Optional[cute.Tensor],
        rt_upper_pad_d: cutlass.Int32,
        rt_upper_pad_h: cutlass.Int32,
        rt_upper_pad_w: cutlass.Int32,
        rt_lower_pad_d: cutlass.Int32,
        rt_lower_pad_h: cutlass.Int32,
        rt_lower_pad_w: cutlass.Int32,
        rt_stride_d: cutlass.Int32,
        rt_stride_h: cutlass.Int32,
        rt_stride_w: cutlass.Int32,
        rt_dil_d: cutlass.Int32,
        rt_dil_h: cutlass.Int32,
        rt_dil_w: cutlass.Int32,
        stream: cuda.CUstream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ) -> None:
        """Execute the persistent convolution with dynamic preferred-cluster scheduling.

        Pad / stride / dilation arrive as runtime cutlass.Int32, which the rt_ prefix
        marks, so one compiled cubin serves any geometry.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param d: Output tensor D - (N, Z, P, Q, K) layout
        :param bias: Optional length-K device tensor holding a
            per-output-channel bias added in FP32 as D = epilogue_op(acc + bias).
            Pass None for a cubin without the bias path.
        :param rt_upper_pad_d/h/w: Upper padding (D, H, W)
        :param rt_lower_pad_d/h/w: Lower padding (D, H, W)
        :param rt_stride_d/h/w: Convolution stride (D, H, W)
        :param rt_dil_d/h/w: Dilation (D, H, W)
        :param stream: CUDA stream for asynchronous execution
        :param epilogue_op: Optional elementwise lambda function to apply to the output
            tensor
        """
        self._setup_conv_input_attrs(a, b, d)
        self.has_bias: bool = bias is not None
        self.bias_dtype: Optional[Type[cutlass.Numeric]] = (
            bias.element_type if bias is not None else None
        )
        self._setup_attributes()

        # Pack the runtime pad/stride/dilation scalars into (D, H, W) tuples that
        # feed the im2col A descriptor corners.
        rt_upper_pad_dhw = (rt_upper_pad_d, rt_upper_pad_h, rt_upper_pad_w)
        rt_lower_pad_dhw = (rt_lower_pad_d, rt_lower_pad_h, rt_lower_pad_w)
        rt_stride_dhw = (rt_stride_d, rt_stride_h, rt_stride_w)
        rt_dil_dhw = (rt_dil_d, rt_dil_h, rt_dil_w)

        (
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_d,
            tma_tensor_d,
        ) = self._setup_conv_tma(
            a,
            b,
            d,
            self.tiled_mma,
            rt_upper_pad_dhw,
            rt_lower_pad_dhw,
            rt_stride_dhw,
            rt_dil_dhw,
        )

        # Compute grid size and scheduler params for both cluster shapes
        self.fallback_tile_sched_params, _ = compute_grid(
            tma_tensor_d,
            self.cta_tile_shape_mnk,
            self.fallback_cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
        )
        self.preferred_tile_sched_params, preferred_grid = compute_grid(
            tma_tensor_d,
            self.cta_tile_shape_mnk,
            self.preferred_cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
        )

        # Build mBias: the per-output-channel bias viewed with mD's (M, N, L)
        # profile. The M extent spans only a CTA tile because the epilogue stages one
        # tile's channels into shared memory; the real output-M size arrives at the
        # store site through the tile coordinate.
        if cutlass.const_expr(self.has_bias):
            mBias_layout = cute.make_layout(
                (
                    (self.cta_tile_shape_mnk[0], 1, 1, 1),
                    cute.size(d, mode=[4]),
                    1,
                ),
                stride=((0, 0, 0, 0), 1, 0),
            )
            mBias_mnl = cute.make_tensor(bias.iterator, mBias_layout)
        else:
            mBias_mnl = None

        self.shared_storage = Sm100DenseImplicitGemmFpropKernel._make_shared_storage(
            self, num_ab_stage=self.num_ab_stage, num_d_stage=self.num_d_stage
        )

        # Launch the kernel synchronously
        self.kernel(
            tma_atom_a_preferred,
            tma_tensor_a_preferred,
            tma_atom_a_fallback,
            tma_tensor_a_fallback,
            tma_atom_b_preferred,
            tma_tensor_b_preferred,
            tma_atom_b_fallback,
            tma_tensor_b_fallback,
            tma_atom_d,
            tma_tensor_d,
            mBias_mnl,
            self.tiled_mma,
            self.preferred_cluster_layout_vmnk,
            self.fallback_cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.d_smem_layout_staged,
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
        return

    # GPU device kernel - dispatches to the preferred or the fallback cluster path
    @cute.kernel
    def kernel(
        self,
        tma_atom_a_preferred: cute.CopyAtom,
        mA_mkl_preferred: cute.Tensor,
        tma_atom_a_fallback: cute.CopyAtom,
        mA_mkl_fallback: cute.Tensor,
        tma_atom_b_preferred: cute.CopyAtom,
        mB_nkl_preferred: cute.Tensor,
        tma_atom_b_fallback: cute.CopyAtom,
        mB_nkl_fallback: cute.Tensor,
        tma_atom_d: Optional[cute.CopyAtom],
        mD_mnl: cute.Tensor,
        mBias_mnl: Optional[cute.Tensor],
        tiled_mma: cute.TiledMma,
        preferred_cluster_layout_vmnk: cute.Layout,
        fallback_cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        d_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        preferred_tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        fallback_tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """
        GPU device kernel entry point for kernel with preferred cluster shape.
        """
        # Get cluster coordinates to determine if this is a preferred cluster
        cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
        is_preferred_cluster = (
            cbdim_x == self.preferred_cluster_shape_mn[0]
            and cbdim_y == self.preferred_cluster_shape_mn[1]
            and cbdim_z == 1
        )

        # Two mutually exclusive code branches, one per cluster shape; only one runs
        # per launch. smem_merge_branch_allocs=True at launch enables shared memory
        # reuse between the two paths.
        if is_preferred_cluster:
            self.cluster_specific_kernel(
                tma_atom_a_preferred,
                mA_mkl_preferred,
                tma_atom_b_preferred,
                mB_nkl_preferred,
                tma_atom_d,
                mD_mnl,
                mBias_mnl,
                tiled_mma,
                preferred_cluster_layout_vmnk,
                a_smem_layout_staged,
                b_smem_layout_staged,
                d_smem_layout_staged,
                epi_tile,
                preferred_tile_sched_params,
                self.is_preferred_a_mcast,
                self.is_preferred_b_mcast,
                self.preferred_cluster_shape_mn,
                epilogue_op,
            )
        else:
            self.cluster_specific_kernel(
                tma_atom_a_fallback,
                mA_mkl_fallback,
                tma_atom_b_fallback,
                mB_nkl_fallback,
                tma_atom_d,
                mD_mnl,
                mBias_mnl,
                tiled_mma,
                fallback_cluster_layout_vmnk,
                a_smem_layout_staged,
                b_smem_layout_staged,
                d_smem_layout_staged,
                epi_tile,
                fallback_tile_sched_params,
                self.is_fallback_a_mcast,
                self.is_fallback_b_mcast,
                self.fallback_cluster_shape_mn,
                epilogue_op,
            )

    @cute.jit()
    def cluster_specific_kernel(
        self,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        tma_atom_d: Optional[cute.CopyAtom],
        mD_mnl: cute.Tensor,
        mBias_mnl: Optional[cute.Tensor],
        tiled_mma: cute.TiledMma,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        d_smem_layout_staged: Union[cute.Layout, cute.ComposedLayout, None],
        epi_tile: cute.Tile,
        tile_sched_params: ClcDynamicPersistentTileSchedulerParams,
        effective_is_a_mcast: bool,
        effective_is_b_mcast: bool,
        cluster_shape: Tuple[int, int],
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """
        GPU device kernel performing the CLC dynamic persistent convolution computation.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch tma desc
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            cpasync.prefetch_descriptor(tma_atom_d)

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
        is_first_cta_in_cluster = cta_rank_in_cluster == 0
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b/acc full/empty, CLC, tensor memory dealloc barrier
        #
        # One allocation of the factory-built shared-storage layout; stage
        # selection sized its candidates through the same definition.
        smem = SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
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

        # Initialize clc_pipeline (barrier) and states
        clc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        cluster_size = cute.size(cluster_shape)
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
        # Tensor memory dealloc barrier init
        tmem = TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
        )

        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_shape, is_relaxed=True)

        # Initial clc response pointer
        clc_response_ptr = storage.clc_response.data_ptr()

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_clc_stage
        )

        #
        # Setup smem tensor A/B/C
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(
            effective_is_a_mcast or effective_is_b_mcast or use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, RestM, RestK, RestL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, RestN, RestK, RestL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )
        # (bM, bN, RestM, RestN, RestL)
        gD_mnl = cute.local_tile(
            mD_mnl, cute.slice_(self.mma_tiler, (None, None, 0)), (None, None, None)
        )
        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/C
        #
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, RestM, RestK, RestL)
        tCgA = thr_mma.partition_A(gA_mkl)
        # (MMA, MMA_N, MMA_K, RestN, RestK, RestL)
        tCgB = thr_mma.partition_B(gB_nkl)
        # (MMA, MMA_M, MMA_N, RestM, RestN, RestL)
        tCgD = thr_mma.partition_C(gD_mnl)

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
        pipeline_init_wait(cluster_shape_mn=cluster_shape)

        #
        # Construct the scheduler
        #
        tile_sched = ClcDynamicPersistentTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            clc_response_ptr,
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
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
                # Tma load loop
                #

                # Set up coord iterator to avoid incurring idx2crd at runtime
                # Permuted iteration order: K-tuple layout is (C,S,R,T) but we
                # iterate in (S,R,T,C) colex order so S advances innermost.
                # Tensor/TMA layouts are unchanged; we un-permute the coord at
                # slice time so A and B see the original (C,S,R,T) coord.
                k_shape_orig = cute.shape(tAgA_slice, mode=1)
                k_shape_perm = (
                    k_shape_orig[1],
                    k_shape_orig[2],
                    k_shape_orig[3],
                    k_shape_orig[0],
                )
                coord_perm = cute.repeat_like(0, k_shape_perm)
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    # Un-permute (s,r,t,c) -> (c,s,r,t) for slice
                    coord_iter = (
                        coord_perm[3],
                        coord_perm[0],
                        coord_perm[1],
                        coord_perm[2],
                    )

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, coord_iter)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, coord_iter)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                    )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt +
                    # k_tile + 1
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()

                    coord_perm = cute.increment_coord(coord_perm, k_shape_perm)

                #
                # Advance to next tile
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            #
            # Wait A/B buffer empty
            #
            ab_producer.tail()

        #
        # Specialized scheduler warp
        #
        if warp_idx == self.sched_warp_id and is_first_cta_in_cluster:
            #
            # Persistent tile scheduling loop
            #
            clc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.ProducerConsumer, self.num_clc_stage
            )

            while work_tile.is_valid_tile:
                #
                # Advance to next tile
                #
                clc_pipeline.producer_acquire(clc_producer_state)
                mbarrier_addr = clc_pipeline.producer_get_barrier(clc_producer_state)
                tile_sched.advance_to_next_work(mbarrier_addr)
                clc_producer_state.advance()

                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
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
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
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
                        if handle.count + 1 < k_tile_cnt:
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
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)

        # (EPI_TILE_M, EPI_TILE_N, STAGE)
        sD = storage.sD.get_tensor(
            d_smem_layout_staged.outer, swizzle=d_smem_layout_staged.inner
        )

        # (cta_tile_n,) staged bias row: one value per output channel in this
        # CTA's N-tile, fetched once and read back by every epilogue thread. Only
        # allocated on the bias path, so a no-bias cubin spends no smem on it.
        if cutlass.const_expr(mBias_mnl is not None):
            sBias = storage.sBias.get_tensor(
                cute.make_layout(self.cta_tile_shape_mnk[1])
            )
        else:
            sBias = None

        # Bias staging is a CTA-wide handoff: one warp's cp.async fills sBias and
        # every epilogue thread reads its own columns back, so they meet here.
        bias_sync_barrier = pipeline.NamedBarrier(
            barrier_id=self.epilog_sync_bar_id,
            num_threads=32 * len(self.epilogue_warp_id),
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

            #
            # Persistent tile scheduling loop for epilogue
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            assert tma_atom_d is not None and sD is not None
            d_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            d_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_d_stage, producer_group=d_producer_group
            )
            # Epilogue partitions, hoisted out of the tile loop: the tmem->rmem
            # and rmem->smem tilings and the TMA store partition depend only on
            # compile-time shapes.
            tCgD_t = utils.gemm.sm100.transform_partitioned_tensor_layout(tCgD)
            tCtAcc_t = utils.gemm.sm100.transform_partitioned_tensor_layout(tCtAcc_base)
            (
                tiled_copy_t2r,
                tTR_tAcc_base,
                tTR_rAcc,
            ) = self.epilog_tmem_copy_and_partition(
                tidx, tCtAcc_t, tCgD_t, epi_tile, self.use_2cta_instrs
            )
            tTR_rD = cute.make_rmem_tensor(tTR_rAcc.shape, self.d_dtype)
            (
                tiled_copy_r2s,
                tRS_rD,
                tRS_sD,
            ) = self.epilog_smem_store_copy_and_partition(
                tiled_copy_t2r, tTR_rD, tidx, sD
            )
            bSG_sD, bSG_gD_partitioned = self.epilog_gmem_copy_and_partition(
                tma_atom_d, tCgD_t, epi_tile, sD
            )

            # Bias read view: the staged row carries the same epi-tile and T2R
            # structure as the accumulator, so each thread's bias fragment lines
            # up with its acc fragment. It is tile invariant, since every tile
            # restages the row in place.
            if cutlass.const_expr(mBias_mnl is not None):
                # (T2R, T2R_M, T2R_N, SUBTILE)
                tTR_sBias = self.epilog_bias_smem_partition(
                    tiled_copy_t2r, tidx, sBias, epi_tile
                )
                # cp.async moves at least 32 bits, so each lane carries a
                # 32-bit-wide vector of bias elements: one at a 32-bit bias
                # width, two at 16 bits.
                bias_elems_per_copy = 32 // mBias_mnl.element_type.width
                bias_g2s_atom = cute.make_copy_atom(
                    cute.nvgpu.cpasync.CopyG2SOp(),
                    mBias_mnl.element_type,
                    num_bits_per_copy=32,
                )
            else:
                tTR_sBias = None
                bias_elems_per_copy = None
                bias_g2s_atom = None

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                num_tiles_executed = tile_sched.num_tiles_executed

                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gD = bSG_gD_partitioned[(None, None, None, *mma_tile_coord_mnl)]

                if cutlass.const_expr(mBias_mnl is not None):
                    # One cp.async per lane brings this tile's contiguous
                    # cta_tile_n bias values (channel stride 1) into sBias; the
                    # barrier below then lets every epilogue thread read its own
                    # columns back out of smem. A channel's value is fetched once
                    # and reused by every output row of the tile.
                    cta_n = self.cta_tile_shape_mnk[1]
                    n_base = mma_tile_coord_mnl[1] * cta_n
                    n_active = cta_n // bias_elems_per_copy
                    # (elems, lanes), column-major so lane t owns the contiguous
                    # block [t*elems, (t+1)*elems).
                    row_layout = cute.make_layout(
                        (bias_elems_per_copy, n_active),
                        stride=(1, bias_elems_per_copy),
                    )
                    # cp.async needs 32-bit alignment on both ends; n_base is a
                    # multiple of cta_tile_n, so re-annotate to satisfy the atom.
                    gBias_row = cute.make_tensor(
                        (mBias_mnl.iterator + n_base).align(min_align=4),
                        row_layout,
                    )
                    sBias_tiled = cute.make_tensor(
                        sBias.iterator.align(min_align=4), row_layout
                    )
                    # Tail lanes of a rounded-up N-tile address columns with no
                    # backing storage, so each lane is predicated; a false
                    # predicate writes zero and 16-byte channel alignment keeps
                    # every vector wholly in or out of bounds. One pass covers as
                    # many columns as the epilogue has threads, hence the loop.
                    num_bias_threads = 32 * len(self.epilogue_warp_id)
                    for lane_base in cutlass.range_constexpr(
                        0, n_active, num_bias_threads
                    ):
                        lane = lane_base + tidx
                        if lane < n_active:
                            bias_pred = cute.make_rmem_tensor(
                                cute.make_layout((1,)), cutlass.Boolean
                            )
                            bias_pred[0] = cutlass.Boolean(
                                n_base + lane * bias_elems_per_copy < mD_mnl.shape[1]
                            )
                            cute.copy_atom_call(
                                bias_g2s_atom,
                                gBias_row[(None, lane)],
                                sBias_tiled[(None, lane)],
                                pred=bias_pred,
                            )
                    cute.arch.cp_async_commit_group()
                    cute.arch.cp_async_wait_group(0)
                    bias_sync_barrier.arrive_and_wait()

                # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]

                acc_pipeline.consumer_wait(acc_consumer_state)

                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                bSG_gD = cute.group_modes(bSG_gD, 1, cute.rank(bSG_gD))

                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                num_prev_subtiles = num_tiles_executed * subtile_cnt
                for subtile_idx in cutlass.range_constexpr(subtile_cnt):
                    # Load the accumulator subtile from tensor memory
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)

                    # The epilogue arithmetic runs in FP32: widen the accumulator,
                    # add the bias there, apply the activation, and narrow once to
                    # the output type: D = epilogue_op(acc + bias).
                    acc_vec = tiled_copy_r2s.retile(tTR_rAcc).load().to(cutlass.Float32)
                    if cutlass.const_expr(mBias_mnl is not None):
                        tTR_rBias = cute.make_rmem_tensor(
                            tTR_rAcc.shape, mBias_mnl.element_type
                        )
                        cute.autovec_copy(
                            tTR_sBias[(None, None, None, subtile_idx)], tTR_rBias
                        )
                        bias_vec = tiled_copy_r2s.retile(tTR_rBias).load()
                        acc_vec = acc_vec + bias_vec.to(cutlass.Float32)
                    acc_vec = epilogue_op(acc_vec)
                    acc_vec = acc_vec.to(self.d_dtype)
                    tRS_rD.store(acc_vec)

                    # Store the subtile to shared memory
                    d_buffer = (num_prev_subtiles + subtile_idx) % self.num_d_stage
                    cute.copy(
                        tiled_copy_r2s, tRS_rD, tRS_sD[(None, None, None, d_buffer)]
                    )
                    cute.arch.fence_proxy("async.shared", space="cta")
                    bias_sync_barrier.arrive_and_wait()

                    # TMA store the subtile to global memory
                    if warp_idx == self.epilogue_warp_id[0]:
                        cute.copy(
                            tma_atom_d,
                            bSG_sD[(None, d_buffer)],
                            bSG_gD[(None, subtile_idx)],
                        )
                        d_pipeline.producer_commit()
                        d_pipeline.producer_acquire()
                    bias_sync_barrier.arrive_and_wait()

                bias_sync_barrier.arrive_and_wait()

                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()
                #
                # Advance to next tile
                #
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()

            # Wait for D store complete
            d_pipeline.producer_tail()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

    @staticmethod
    def can_implement(
        ncdhw: Tuple[int, int, int, int, int],
        k: int,
        filter_trs: Tuple[int, int, int],
        upper_pad_dhw: Tuple[int, int, int],
        lower_pad_dhw: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dil_dhw: Tuple[int, int, int],
        ab_dtype: Type[cutlass.Numeric],
        d_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        preferred_cluster_shape_mn: Tuple[int, int],
        fallback_cluster_shape_mn: Tuple[int, int],
        swizzle_size: int,
        raster_along: Literal["m", "n"],
        bias_dtype: Optional[Type[cutlass.Numeric]] = None,
        activation: str = "identity",
    ) -> bool:
        """Run every host-side check and tell whether the configuration is supported.

        The checks go from the structural ones to the geometry-derived ones: element
        types, epilogue activation, mma tiler and cluster shapes, convolution
        geometry, tensor alignment, cluster problem size and swizzle, im2col
        descriptor limits.

        :param ncdhw: Input extents (N, C, D, H, W)
        :type ncdhw: Tuple[int, int, int, int, int]
        :param k: Output channel count, which is the implicit-GEMM N extent
        :type k: int
        :param filter_trs: Filter extents (T, R, S)
        :type filter_trs: Tuple[int, int, int]
        :param upper_pad_dhw: Trailing padding per spatial dimension
        :type upper_pad_dhw: Tuple[int, int, int]
        :param lower_pad_dhw: Leading padding per spatial dimension
        :type lower_pad_dhw: Tuple[int, int, int]
        :param stride_dhw: Convolution stride per spatial dimension
        :type stride_dhw: Tuple[int, int, int]
        :param dil_dhw: Dilation per spatial dimension
        :type dil_dhw: Tuple[int, int, int]
        :param ab_dtype: A/B element type
        :type ab_dtype: Type[cutlass.Numeric]
        :param d_dtype: Output element type
        :type d_dtype: Type[cutlass.Numeric]
        :param acc_dtype: Accumulator element type
        :type acc_dtype: Type[cutlass.Numeric]
        :param use_2cta_instrs: Whether the MMA runs on a 2-CTA instruction
        :type use_2cta_instrs: bool
        :param mma_tiler_mn: MMA tiler shape (M, N)
        :type mma_tiler_mn: Tuple[int, int]
        :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
        :type preferred_cluster_shape_mn: Tuple[int, int]
        :param fallback_cluster_shape_mn: Fallback cluster shape (M, N), which every
            launch can form
        :type fallback_cluster_shape_mn: Tuple[int, int]
        :param swizzle_size: Tile-scheduler swizzle size
        :type swizzle_size: int
        :param raster_along: Tile-scheduler rasterization order
        :type raster_along: Literal["m", "n"]
        :param bias_dtype: Bias element type, or None when no bias is supplied
        :type bias_dtype: Optional[Type[cutlass.Numeric]]
        :param activation: Name of the compile-time epilogue activation, one of
            EPILOGUE_ACTIVATIONS
        :type activation: str

        :return: True if the configuration can be implemented, False otherwise
        :rtype: bool
        """
        try:
            # FP32 accumulates every float input and Int32 every integer one.
            allowed_acc_dtype = (cutlass.Float32, cutlass.Int32)
            if acc_dtype not in allowed_acc_dtype:
                raise testing.CantImplementError(
                    f"acc_dtype must be one of {allowed_acc_dtype}, got {acc_dtype}"
                )
            sm100_utils.check_int8_mma_arch(ab_dtype)
            # Define compatibility mapping between accumulator type and AB type
            acc_ab_compatibility = {
                cutlass.Float32: {
                    cutlass.Float16,
                    cutlass.BFloat16,
                    cutlass.TFloat32,
                    cutlass.Float8E4M3FN,
                    cutlass.Float8E5M2,
                },  # Float32 accumulator supports floating point AB types only
                cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
            }
            # Check compatibility between accumulator type and AB type
            if ab_dtype not in acc_ab_compatibility[acc_dtype]:
                raise testing.CantImplementError(
                    f"Unsupported AB dtype: {ab_dtype} for accumulator dtype: "
                    f"{acc_dtype}"
                )
            # Define compatibility mapping between accumulator type and D type
            acc_d_compatibility = {
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
                cutlass.Int32: {
                    cutlass.BFloat16,
                    cutlass.Float16,
                    cutlass.Float32,
                    cutlass.Int32,
                    cutlass.Int8,
                    cutlass.Uint8,
                },
            }
            # Check compatibility between accumulator type and D type
            if d_dtype not in acc_d_compatibility[acc_dtype]:
                raise testing.CantImplementError(
                    f"Unsupported D dtype: {d_dtype} for accumulator dtype: {acc_dtype}"
                )
            # The staged bias row is filled with 32-bit vectors and the epilogue's bias
            # floor is 16 bits, so the bias is one of these 16- or 32-bit types.
            allowed_bias_dtype = (
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float32,
                cutlass.Int32,
            )
            if bias_dtype is not None and bias_dtype not in allowed_bias_dtype:
                raise testing.CantImplementError(
                    f"bias_dtype must be one of {allowed_bias_dtype}, got {bias_dtype}"
                )
            # The activation's device op is folded into the cubin, so only a name the
            # table carries can be served.
            if activation not in EPILOGUE_ACTIVATIONS:
                raise testing.CantImplementError(
                    f"Unsupported activation {activation!r}; "
                    f"choose from {sorted(EPILOGUE_ACTIVATIONS)}"
                )
            # tcgen05.mma admits these M per CTA group, and fills N in 32-wide
            # steps up to 256.
            if not (
                (not use_2cta_instrs and mma_tiler_mn[0] in [64, 128])
                or (use_2cta_instrs and mma_tiler_mn[0] in [128, 256])
            ):
                raise testing.CantImplementError(
                    f"Invalid mma tiler & use_2cta_instrs: {mma_tiler_mn}, {use_2cta_instrs}"
                )
            if mma_tiler_mn[1] not in range(32, 257, 32):
                raise testing.CantImplementError(
                    f"Invalid mma tiler N: {mma_tiler_mn[1]}"
                )
            check_cluster_shape(
                use_2cta_instrs,
                preferred_cluster_shape_mn,
                fallback_cluster_shape_mn,
                swizzle_size,
                raster_along,
            )
            check_conv_geometry(
                ncdhw,
                (k, *filter_trs),
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            check_tensor_alignment(ncdhw[1], k, ab_dtype, d_dtype)
            # Implicit-GEMM M is N*Z*P*Q.
            z, p, q = compute_zpq(
                ncdhw[2:],
                filter_trs,
                stride_dhw,
                upper_pad_dhw,
                lower_pad_dhw,
                dil_dhw,
            )
            gemm_m = ncdhw[0] * z * p * q
            check_preferred_cluster_problem_size(
                gemm_m,
                k,
                use_2cta_instrs,
                mma_tiler_mn,
                preferred_cluster_shape_mn,
            )
            # Require enough clusters along the swizzled dimension
            check_swizzle_size(
                gemm_m,
                k,
                mma_tiler_mn,
                use_2cta_instrs,
                preferred_cluster_shape_mn,
                fallback_cluster_shape_mn,
                swizzle_size,
                raster_along,
            )
            check_im2col_descriptor_limits(
                filter_trs,
                upper_pad_dhw,
                lower_pad_dhw,
                stride_dhw,
                dil_dhw,
            )
        except (testing.CantImplementError, ValueError) as e:
            print(e)
            return False
        return True


@lru_cache(maxsize=None)
def compile_conv(
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    mma_tiler: Tuple[int, int] = (256, 256),
    preferred_cluster_shape_mn: Tuple[int, int] = (2, 1),
    fallback_cluster_shape_mn: Tuple[int, int] = (2, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = True,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    activation: str = "identity",
    frontendnext: bool = False,
):
    """
    Compile a 3D convolution kernel with CLC dynamic preferred cluster scheduling.

    Every parameter is a hashable scalar that selects a cubin, so the result is
    cached unbounded: a repeat configuration skips both the trace and the compile.
    The tensors are stood in for by fakes built from the element types, because the
    compiled module reads nothing else from them.

    :param ab_dtype: Element type of the input and filter tensors
    :param d_dtype: Element type of the output tensor
    :param acc_dtype: Accumulator data type
    :param mma_tiler: MMA tile shape (M, N)
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :param raster_along: Rasterization order of clusters. Only used when swizzle_size >
        1
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :param bias_dtype: Element type of the per-output-channel bias, or None for a
        cubin without the bias path
    :param activation: Name of the compile-time epilogue activation, one of
        EPILOGUE_ACTIVATIONS. One activation per cubin
    :param frontendnext: Whether the caller is running under the pyir frontend. A
        key-only parameter: the two frontends emit different cubins for the same
        inputs, so an artifact compiled under one must not be served to the other
    :return: Compiled kernel function
    """
    from cutlass.cute.runtime import make_fake_stream

    input = make_fake_conv_tensor(ab_dtype, 5, 4)
    filter = make_fake_conv_tensor(ab_dtype, 5, 4)
    output = make_fake_conv_tensor(d_dtype, 5, 4)
    bias = None if bias_dtype is None else make_fake_conv_tensor(bias_dtype, 1, 0)

    # The activation's device op is folded into the cubin, so a different activation
    # is a different kernel.
    epilogue_op = EPILOGUE_ACTIVATIONS[activation]["device"]

    # Create convolution kernel object
    conv_op = Sm100DenseImplicitGemmFpropKernel(
        acc_dtype,
        use_2cta_instrs,
        mma_tiler,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        swizzle_size,
        raster_along,
    )

    stream = make_fake_stream()
    return cute.compile(
        conv_op,
        input,
        filter,
        output,
        bias,
        *trace_conv_scalars(),
        stream,
        epilogue_op,
    )


def run(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    stride_dhw: Tuple[int, int, int] = (1, 1, 1),
    upper_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    lower_pad_dhw: Tuple[int, int, int] = (0, 0, 0),
    dil_dhw: Tuple[int, int, int] = (1, 1, 1),
    ab_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    d_dtype: Type[cutlass.Numeric] = cutlass.Float16,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    mma_tiler_mn: Tuple[int, int] = (128, 128),
    preferred_cluster_shape_mn: Tuple[int, int] = (1, 1),
    fallback_cluster_shape_mn: Tuple[int, int] = (1, 1),
    swizzle_size: int = 1,
    raster_along: Literal["m", "n"] = "m",
    use_2cta_instrs: bool = False,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 0,
    use_cold_l2: bool = False,
    skip_ref_check: bool = False,
    use_bias: bool = False,
    bias_dtype: Optional[Type[cutlass.Numeric]] = None,
    activation: str = "identity",
    **kwargs,
):
    """Run 3D convolution and compare against PyTorch reference.

    The filter tensor uses native KTRSC layout (K, T, R, S, C) with C contiguous.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param stride_dhw: Stride (Sd, Sh, Sw)
    :param upper_pad_dhw: Upper padding (PadD, PadH, PadW)
    :param lower_pad_dhw: Lower padding (PadD, PadH, PadW)
    :param dil_dhw: Dilation (DilD, DilH, DilW)
    :param ab_dtype: Data type for A/B input tensors
    :param d_dtype: Data type for output tensor D
    :param acc_dtype: Accumulator data type
    :param mma_tiler_mn: MMA tiler shape
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :param raster_along: Rasterization order of clusters. Only used when swizzle_size >
        1
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :param tolerance: Tolerance for result comparison
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param use_cold_l2: Whether to flush L2 cache between iterations
    :param skip_ref_check: Whether to skip reference checking
    :param use_bias: Add a per-output-channel bias as D = activation(acc + bias);
        bias and no-bias are separate cubins
    :param bias_dtype: Bias element type; None derives it from the output type
    :param activation: Compile-time epilogue activation, one per cubin
    :param kwargs: Extra keyword arguments, accepted and ignored
    """
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs

    # Settle the bias element type before the configuration is checked, so the check
    # sees the type the bias tensor will actually carry.
    if use_bias and bias_dtype is None:
        bias_dtype = bias_dtype_for_output(d_dtype)
    # Every host-side check runs here, before any tensor or compile work.
    if not Sm100DenseImplicitGemmFpropKernel.can_implement(
        ncdhw,
        ktrs[0],
        ktrs[1:],
        upper_pad_dhw,
        lower_pad_dhw,
        stride_dhw,
        dil_dhw,
        ab_dtype,
        d_dtype,
        acc_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        preferred_cluster_shape_mn,
        fallback_cluster_shape_mn,
        swizzle_size,
        raster_along,
        bias_dtype if use_bias else None,
        activation,
    ):
        raise testing.CantImplementError(
            f"Config not implementable: ncdhw={ncdhw}, ktrs={ktrs}, "
            f"stride={stride_dhw}, pad=({upper_pad_dhw}, {lower_pad_dhw}), "
            f"dilation={dil_dhw}, mma_tiler={mma_tiler_mn}, "
            f"use_2cta_instrs={use_2cta_instrs}, "
            f"cluster=({preferred_cluster_shape_mn}, {fallback_cluster_shape_mn}), "
            f"swizzle=({swizzle_size}, {raster_along}), "
            f"dtypes=({ab_dtype}, {d_dtype}, {acc_dtype}), "
            f"bias_dtype={bias_dtype if use_bias else None}, "
            f"activation={activation}"
        )
    Z, P, Q = compute_zpq(
        ncdhw[2:], ktrs[1:], stride_dhw, upper_pad_dhw, lower_pad_dhw, dil_dhw
    )

    print("Running Blackwell 3D Convolution test with:")
    print(f"  Input shape (N, C, D, H, W): {ncdhw}")
    print(f"  Filter shape (K, C, T, R, S): ({K}, {C}, {T}, {R}, {S})")
    print(f"  Output shape (N, K, Z, P, Q): ({N}, {K}, {Z}, {P}, {Q})")
    print(f"  Stride (Sd, Sh, Sw): {stride_dhw}")
    print(f"  Upper padding (PadD, PadH, PadW): {upper_pad_dhw}")
    print(f"  Lower padding (PadD, PadH, PadW): {lower_pad_dhw}")
    print(f"  Dilation (DilD, DilH, DilW): {dil_dhw}")
    print(f"  A/B data type: {ab_dtype}")
    print(f"  D data type: {d_dtype}")
    print(f"  Accumulator type: {acc_dtype}")
    print(f"  MMA tiler (M, N): {mma_tiler_mn}")
    print(f"  Preferred cluster shape (M, N): {preferred_cluster_shape_mn}")
    print(f"  Fallback cluster shape (M, N): {fallback_cluster_shape_mn}")
    print(f"  Swizzle size: {swizzle_size}")
    print(f"  Raster along: {raster_along}")
    print(f"  Use 2CTA instructions: {use_2cta_instrs}\n")

    # Create input and filter tensors
    input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
        ncdhw, ktrs, (Z, P, Q), ab_dtype
    )

    # Prepare cute tensors
    input_, input_storage = create_cute_tensor(input_tensor, ab_dtype, leading_dim=4)
    filter_, filter_storage = create_cute_tensor(filter_tensor, ab_dtype, leading_dim=4)
    output_, output_storage = create_cute_tensor(output_tensor, d_dtype, leading_dim=4)
    # Free staging buffers once consumed to bound peak memory and avoid OOM.
    del output_tensor

    # One bias value per output channel, in the bias element type: the epilogue's
    # 16-bit floor keeps it wider than a narrow output.
    if use_bias:
        bias_f32_src = torch.randn(ktrs[0], dtype=torch.float32, device="cuda")
        bias_, bias_storage = create_cute_tensor(
            bias_f32_src, bias_dtype, leading_dim=0
        )
    else:
        bias_storage = None
        bias_ = None

    # Compile convolution kernel
    print("Compiling kernel with cute.compile ...")
    compiled_fn = compile_conv(
        ab_dtype,
        d_dtype,
        acc_dtype,
        mma_tiler=mma_tiler_mn,
        preferred_cluster_shape_mn=preferred_cluster_shape_mn,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        swizzle_size=swizzle_size,
        raster_along=raster_along,
        use_2cta_instrs=use_2cta_instrs,
        bias_dtype=bias_dtype if use_bias else None,
        activation=activation,
        frontendnext=frontend_cache_token(),
    )

    # A fresh non-default stream carries the kernel: CUDA graph capture, which the
    # benchmark below uses, requires one.
    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Run convolution. Pad / stride / dilation are passed as runtime
    # cutlass.Int32, which the rt_ prefix marks, so one compiled cubin serves any
    # geometry.
    print("Running Blackwell 3D convolution...")
    # The inputs initialize on other streams; drain them so the kernel's
    # stream never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_fn(
        input_,
        filter_,
        output_,
        bias_,
        *rt_conv_scalars(
            upper_pad=upper_pad_dhw,
            lower_pad=lower_pad_dhw,
            stride=stride_dhw,
            dil=dil_dhw,
        ),
        current_stream,
    )
    torch_stream.synchronize()

    # TF32 off: the cuDNN reference convolution runs in full FP32.
    with torch.backends.cudnn.flags(enabled=True, allow_tf32=False):
        if not skip_ref_check:
            # Run PyTorch reference convolution
            print("Running PyTorch reference 3D convolution...")
            # Pytorch expects tensors to be in NCDHW format
            input_ncdhw = input_tensor.permute(0, 4, 1, 2, 3)
            # Free staging buffers once consumed to bound peak memory and avoid OOM;
            # the view holds the input from here on.
            del input_tensor
            if upper_pad_dhw != lower_pad_dhw:
                # F.conv3d only supports symmetric padding, so manually pad the input
                # F.pad takes padding in reverse dimension order: (W_before, W_after,
                # H_before, H_after, D_before, D_after)
                pad_arg = (
                    lower_pad_dhw[2],
                    upper_pad_dhw[2],
                    lower_pad_dhw[1],
                    upper_pad_dhw[1],
                    lower_pad_dhw[0],
                    upper_pad_dhw[0],
                )
                input_ncdhw = F.pad(input_ncdhw, pad_arg)
                conv_padding = (0, 0, 0)
            else:
                conv_padding = upper_pad_dhw
            output_ref = F.conv3d(
                input_ncdhw,
                filter_tensor.permute(0, 4, 1, 2, 3),
                stride=stride_dhw,
                padding=conv_padding,
                dilation=dil_dhw,
            ).to(dtype=torch.float32)
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del input_ncdhw
            # bias_storage holds the exact bias-dtype values the kernel loads, so
            # float() reproduces them bit for bit.
            if use_bias:
                output_ref = output_ref + bias_storage.float().view(1, -1, 1, 1, 1)
            output_ref = EPILOGUE_ACTIVATIONS[activation]["ref"](output_ref)
            # The kernel applies the activation on the FP32 sum and narrows once, on
            # the device, so magnitudes past d_dtype's range saturate to its largest
            # finite value. The round trip needs the K-major layout the kernel writes,
            # whose leading extent carries the vectorized copy.
            ref_narrow_byte_storage = (d_dtype.is_float and d_dtype.width <= 8) or (
                d_dtype.is_integer and d_dtype.width == 4
            )
            ref_narrow_storage_dtype = (
                torch.uint8 if ref_narrow_byte_storage else torch_dtype(d_dtype)
            )
            ref_device = output_ref.permute(0, 2, 3, 4, 1).contiguous().cuda()
            ref_narrow_storage = torch.empty(
                ref_device.shape, dtype=ref_narrow_storage_dtype, device="cuda"
            )
            ref_narrow = from_dlpack(
                ref_narrow_storage, assumed_align=16
            ).mark_layout_dynamic(leading_dim=4)
            ref_narrow.element_type = d_dtype
            ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=4
            )
            cute.testing.convert(ref_tensor, ref_narrow)
            cute.testing.convert(ref_narrow, ref_tensor)
            # Free staging buffers once consumed to bound peak memory and avoid OOM.
            del ref_narrow, ref_narrow_storage
            output_ref = ref_device.permute(0, 4, 1, 2, 3)
            # Compare results
            print("Comparing results...")

            # Convert to float32 for comparison
            # Transform output from (N, Z, P, Q, K) -> (N, K, Z, P, Q)
            output_f32 = output_storage.permute(0, 4, 1, 2, 3).to(torch.float32)
            output_ref_f32 = output_ref.to(torch.float32)

            # Verify results
            torch.testing.assert_close(
                output_f32,
                output_ref_f32,
                atol=tolerance,
                rtol=1e-03,
            )
            print("✓ Results match within tolerance!")

    # Benchmark if requested
    if iterations > 0:
        print(
            f"\nBenchmarking with {warmup_iterations} warmup and {iterations} iterations..."
        )

        def generate_tensors():
            input_tensor, filter_tensor, output_tensor = prepare_fprop_tensors(
                ncdhw, ktrs, (Z, P, Q), ab_dtype
            )
            input_, input_storage = create_cute_tensor(
                input_tensor,
                ab_dtype,
                leading_dim=4,
            )
            filter_, filter_storage = create_cute_tensor(
                filter_tensor,
                ab_dtype,
                leading_dim=4,
            )
            output_, output_storage = create_cute_tensor(
                output_tensor,
                d_dtype,
                leading_dim=4,
            )
            # The bias is one of the tensors the kernel reads every iteration, so it
            # rotates with the rest of the workspace and counts toward its bytes.
            if use_bias:
                ws_bias_, _ = create_cute_tensor(
                    torch.randn(ktrs[0], dtype=torch.float32, device="cuda"),
                    bias_dtype,
                    leading_dim=0,
                )
            else:
                ws_bias_ = None
            # The workspace initializes on other streams; drain them so the
            # benchmark stream never reads a tensor mid-initialization.
            torch.cuda.synchronize()
            return testing.JitArguments(
                input_,
                filter_,
                output_,
                ws_bias_,
                *rt_conv_scalars(
                    upper_pad=upper_pad_dhw,
                    lower_pad=lower_pad_dhw,
                    stride=stride_dhw,
                    dil=dil_dhw,
                ),
                current_stream,
            )

        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                input_storage.numel() * input_storage.element_size()
                + filter_storage.numel() * filter_storage.element_size()
                + output_storage.numel() * output_storage.element_size()
            )
            if bias_storage is not None:
                one_workspace_bytes += (
                    bias_storage.numel() * bias_storage.element_size()
                )
            workspace_count = testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )

        # exec_time is in microseconds
        exec_time = testing.benchmark(
            compiled_fn,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
            use_cuda_graphs=True,
        )
        runtime_s = exec_time / 1.0e6
        fmas = (N * Z * P * Q) * K * (C * T * R * S)
        flop = 2 * fmas
        gflop = flop / 1.0e9
        gflops = gflop / runtime_s

        print("Average Runtime : ", exec_time / 1000, "ms")
        print("GFLOPS          : ", gflops)

        return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Blackwell 3D convolution")

    # Convolution parameters
    parser.add_argument(
        "--ncdhw",
        type=parse_comma_separated_ints,
        default=(1, 128, 32, 32, 32),
        help="Input tensor shape (N,C,D,H,W)",
    )
    parser.add_argument(
        "--ktrs",
        type=parse_comma_separated_ints,
        default=(256, 3, 3, 3),
        help="Filter tensor shape components (K,T,R,S)",
    )
    parser.add_argument(
        "--stride_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Stride (Sd,Sh,Sw)",
    )
    parser.add_argument(
        "--upper_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Upper padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--lower_pad_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Lower padding (PadD,PadH,PadW)",
    )
    parser.add_argument(
        "--dil_dhw",
        type=parse_comma_separated_ints,
        default=(1, 1, 1),
        help="Dilation (DilD,DilH,DilW)",
    )

    # Data type parameters
    parser.add_argument(
        "--ab_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.TFloat32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Int8,
            cutlass.Uint8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ],
        default=cutlass.Float16,
        help="Data type for A/B input tensors",
    )
    parser.add_argument(
        "--d_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
            cutlass.Int32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Int8,
            cutlass.Uint8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ],
        default=cutlass.Float16,
        help="Data type for output tensor D",
    )
    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        choices=[cutlass.Float32, cutlass.Int32],
        default=cutlass.Float32,
        help="Accumulator data type. FP32 carries the float inputs and Int32 the "
        "integer ones.",
    )

    # Kernel parameters
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="MMA tiler shape (M,N)",
    )
    parser.add_argument(
        "--preferred_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 1),
        help="Preferred cluster shape (M,N)",
    )
    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(2, 1),
        help="Fallback cluster shape (M,N)",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Enable 2CTA MMA instructions",
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
        help="Rasterization order of clusters. Only used when swizzle_size > 1",
    )
    # Testing parameters
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-01,
        help="Tolerance for result comparison",
    )
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of warmup iterations",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=0,
        help="Number of benchmark iterations",
    )
    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference checking",
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--use_bias",
        action="store_true",
        help="Add a per-output-channel bias as D = activation(acc + bias). Bias and "
        "no-bias are separate cubins.",
    )
    parser.add_argument(
        "--bias_dtype",
        type=cutlass.dtype,
        choices=[
            cutlass.Float32,
            cutlass.Int32,
            cutlass.Float16,
            cutlass.BFloat16,
        ],
        default=None,
        help="Bias element type. Left unset it is derived from the output type, "
        "which has a 16-bit floor.",
    )
    parser.add_argument(
        "--activation",
        type=str,
        default="identity",
        choices=sorted(EPILOGUE_ACTIVATIONS),
        help="Compile-time epilogue activation applied as D = activation(acc + "
        "bias). One activation per cubin.",
    )

    args = parser.parse_args()

    if len(args.ncdhw) != 5:
        parser.error("--ncdhw must contain exactly 5 values (N,C,D,H,W)")
    if len(args.ktrs) != 4:
        parser.error("--ktrs must contain exactly 4 values (K,T,R,S)")
    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values (M,N)")

    run(
        args.ncdhw,
        args.ktrs,
        args.stride_dhw,
        args.upper_pad_dhw,
        args.lower_pad_dhw,
        args.dil_dhw,
        args.ab_dtype,
        args.d_dtype,
        args.acc_dtype,
        args.mma_tiler_mn,
        args.preferred_cluster_shape_mn,
        args.fallback_cluster_shape_mn,
        args.swizzle_size,
        args.raster_order,
        args.use_2cta_instrs,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.skip_ref_check,
        args.use_bias,
        args.bias_dtype,
        args.activation,
    )
    print("PASS")
