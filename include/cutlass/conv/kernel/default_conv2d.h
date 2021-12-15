/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

/*! \file
    \brief
      Default kernel-level implicit GEMM convolution definitions for threadblock-scoped epilogue.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/gemm/threadblock/default_mma.h"
#include "cutlass/gemm/threadblock/threadblock_swizzle.h"
#include "cutlass/conv/threadblock/threadblock_swizzle.h"
#include "cutlass/epilogue/threadblock/default_epilogue_simt.h"
#include "cutlass/epilogue/threadblock/default_epilogue_tensor_op.h"
#include "cutlass/epilogue/threadblock/default_epilogue_volta_tensor_op.h"
#include "cutlass/conv/convolution.h"
#include "cutlass/conv/threadblock/conv2d_tile_iterator.h"
#include "cutlass/conv/threadblock/implicit_gemm_pipelined.h"
#include "cutlass/conv/threadblock/implicit_gemm_multistage.h"
#include "cutlass/conv/threadblock/implicit_gemm_fprop_fusion_multistage.h"
#include "cutlass/conv/threadblock/implicit_gemm_wgrad_fusion_multistage.h"
#include "cutlass/conv/kernel/implicit_gemm_convolution.h"
#include "cutlass/conv/kernel/implicit_gemm_convolution_fusion.h"
#include "cutlass/conv/kernel/implicit_gemm_convolution_strided_dgrad.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
namespace kernel {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <
  typename ArchTag,
  typename Shape,
  typename WarpMmaTensorOp,
  int PartitionsK,
  typename OutputOp
>
struct DefaultConvEpilogue {
  using Epilogue = typename epilogue::threadblock::DefaultEpilogueTensorOp<
    Shape,
    WarpMmaTensorOp,
    PartitionsK,
    OutputOp,
    OutputOp::kCount
  >::Epilogue;
};

template <
  typename Shape,
  typename WarpMmaTensorOp,
  int PartitionsK,
  typename OutputOp
>
struct DefaultConvEpilogue<
  arch::Sm70,
  Shape,
  WarpMmaTensorOp,
  PartitionsK,
  OutputOp
> {

  using Epilogue = typename epilogue::threadblock::DefaultEpilogueVoltaTensorOp<
    Shape,
    WarpMmaTensorOp,
    PartitionsK,
    OutputOp,
    OutputOp::kCount
  >::Epilogue;
};
/////////////////////////////////////////////////////////////////////////////////////////////////

// Defaults for strided Dgrad
template <
  typename ArchTag,
  typename Shape,
  typename WarpMmaTensorOp,
  int PartitionsK,
  typename OutputOp
>
struct DefaultConvEpilogueStridedDgrad {
  using Epilogue = typename epilogue::threadblock::DefaultEpilogueTensorOpStridedDgrad<
    Shape,
    WarpMmaTensorOp,
    PartitionsK,
    OutputOp,
    OutputOp::kCount
  >::Epilogue;
};

template <
  typename Shape,
  typename WarpMmaTensorOp,
  int PartitionsK,
  typename OutputOp
>
struct DefaultConvEpilogueStridedDgrad<
  arch::Sm70,
  Shape,
  WarpMmaTensorOp,
  PartitionsK,
  OutputOp
> {

  using Epilogue = typename epilogue::threadblock::DefaultEpilogueVoltaTensorOpStridedDgrad<
    Shape,
    WarpMmaTensorOp,
    PartitionsK,
    OutputOp,
    OutputOp::kCount
  >::Epilogue;
};

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace conv
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
