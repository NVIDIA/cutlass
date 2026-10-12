// clang-format off
/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
 **************************************************************************************************/

#include <cuda_runtime.h>
#include <tvm/ffi/container/tensor.h>
#include <tvm/ffi/error.h>
#include <tvm/ffi/extra/module.h>
#include <iostream>
#include <vector>


namespace ffi = tvm::ffi;

struct CUDANDAlloc {
  void AllocData(DLTensor* tensor) {
    size_t data_size = ffi::GetDataSize(*tensor);
    void* ptr = nullptr;
    cudaError_t err = cudaMalloc(&ptr, data_size);
    TVM_FFI_ICHECK_EQ(err, cudaSuccess) << "cudaMalloc failed: " << cudaGetErrorString(err);
    tensor->data = ptr;
  }

  void FreeData(DLTensor* tensor) {
    if (tensor->data != nullptr) {
      cudaError_t err = cudaFree(tensor->data);
      TVM_FFI_ICHECK_EQ(err, cudaSuccess) << "cudaFree failed: " << cudaGetErrorString(err);
      tensor->data = nullptr;
    }
  }
};

inline ffi::Tensor Empty(ffi::Shape shape, DLDataType dtype, DLDevice device) {
  return ffi::Tensor::FromNDAlloc(CUDANDAlloc(), shape, dtype, device);
}

// symbol from the shared library
extern "C" int __tvm_ffi_add_one(void*, const TVMFFIAny*, int32_t, TVMFFIAny*);

// Redirects into the exported function in object
void CallAddOne(ffi::TensorView x, ffi::TensorView y) {
    tvm::ffi::Function::InvokeExternC(nullptr, __tvm_ffi_add_one, x, y);
}

int main() {
    DLDataType f32_dtype{kDLFloat, 32, 1};
    DLDevice cuda_device{kDLCUDA, 0};

    constexpr int ARRAY_SIZE = 10;

    ffi::Tensor x = Empty({ARRAY_SIZE}, f32_dtype, cuda_device);
    ffi::Tensor y = Empty({ARRAY_SIZE}, f32_dtype, cuda_device);

    std::vector<float> host_x(ARRAY_SIZE);
    for (int i = 0; i < ARRAY_SIZE; ++i) {
      host_x[i] = static_cast<float>(i);
    }

    size_t nbytes = host_x.size() * sizeof(float);
    cudaError_t err = cudaMemcpy(x.data_ptr(), host_x.data(), nbytes, cudaMemcpyHostToDevice);
    TVM_FFI_ICHECK_EQ(err, cudaSuccess)
        << "cudaMemcpy host to device failed: " << cudaGetErrorString(err);

    // Call into the FFI function; tensors remain on device because they carry a
    // kDLCUDA device tag.
    CallAddOne(x, y);

    std::vector<float> host_y(host_x.size());
    err = cudaMemcpy(host_y.data(), y.data_ptr(), nbytes, cudaMemcpyDeviceToHost);
    TVM_FFI_ICHECK_EQ(err, cudaSuccess)
        << "cudaMemcpy device to host failed: " << cudaGetErrorString(err);

    std::cout << "y after add_one_cuda(x, y)" << std::endl;
    for (float value : host_y) {
        std::cout << value << " ";
    }
    std::cout << std::endl;
    return 0;
}
