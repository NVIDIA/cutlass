/******************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/*! \file
    \brief generic device-to-device data movement kernel based for CuTe tensors.

    NOTE: this kernel assigns one element copy to every thread, and is by no means
    an efficient way of copying tensors. It should only be used for convenience in
    reference checks.

*/

#pragma once

#include "cute/layout.hpp"
#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/cuda_host_adapter.hpp"

namespace cutlass {

template <typename TensorSource, typename TensorDestination>
void device_copy(TensorSource      tensor_source,
                 TensorDestination tensor_destination,
                 cudaStream_t stream);


template <typename TensorSource, typename TensorDestination>
__global__ void device_copy_kernel(TensorSource const tensor_source, 
                                   TensorDestination tensor_destination) {
  auto linear_idx = blockIdx.x * blockDim.x + threadIdx.x;
  using ElementSrc = typename TensorSource::value_type;
  using ElementDst = typename TensorDestination::value_type;
  NumericConverter<ElementDst, ElementSrc> converter;
  if (linear_idx < size(tensor_source)) {
    tensor_destination(linear_idx) = converter(tensor_source(linear_idx));
  }
}

template <typename TensorSource, typename TensorDestination>
void device_copy(TensorSource      tensor_source,
                 TensorDestination tensor_destination,
                 cudaStream_t stream) {
  
  assert(tensor_source.size() == tensor_destination.size());

  auto numel = tensor_source.size();
  static constexpr int NumThreads = 128;
  auto grid_size = cute::ceil_div(numel, NumThreads);

  dim3 grid(grid_size);
  dim3 block(NumThreads);
  device_copy_kernel<<<grid, block, 0, stream>>>(tensor_source, tensor_destination);
}

} //namespace cutlass
