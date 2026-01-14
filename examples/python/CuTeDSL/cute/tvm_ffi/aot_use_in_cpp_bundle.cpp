// clang-format off
/*
 * SPDX-FileCopyrightText: Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: LicenseRef-NvidiaProprietary
 *
 * NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
 * property and proprietary rights in and to this material, related
 * documentation and any modifications thereto. Any use, reproduction,
 * disclosure or distribution of this material and related documentation
 * without an express license agreement from NVIDIA CORPORATION or
 * its affiliates is strictly prohibited.
 */

// clang-format on
// This example shows how to interface with an AOT compiled function in a C++
// bundle. to build and run the example, run the following command in project
// root bash
// examples/cute/tvm_ffi/aot_use_in_cpp_bundle.sh

#include <cuda_runtime.h>
#include <iostream>
#include <tvm/ffi/container/tensor.h>
#include <tvm/ffi/error.h>
#include <tvm/ffi/extra/module.h>
#include <vector>

namespace ffi = tvm::ffi;

struct CUDANDAlloc {
  void AllocData(DLTensor *tensor) {
    size_t data_size = ffi::GetDataSize(*tensor);
    void *ptr = nullptr;
    cudaError_t err = cudaMalloc(&ptr, data_size);
    TVM_FFI_ICHECK_EQ(err, cudaSuccess)
        << "cudaMalloc failed: " << cudaGetErrorString(err);
    tensor->data = ptr;
  }

  void FreeData(DLTensor *tensor) {
    if (tensor->data != nullptr) {
      cudaError_t err = cudaFree(tensor->data);
      TVM_FFI_ICHECK_EQ(err, cudaSuccess)
          << "cudaFree failed: " << cudaGetErrorString(err);
      tensor->data = nullptr;
    }
  }
};

inline ffi::Tensor Empty(ffi::Shape shape, DLDataType dtype, DLDevice device) {
  return ffi::Tensor::FromNDAlloc(CUDANDAlloc(), shape, dtype, device);
}

// symbol from the shared library
extern "C" int __tvm_ffi_add_one(void *, const TVMFFIAny *, int32_t,
                                 TVMFFIAny *);

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
  cudaError_t err =
      cudaMemcpy(x.data_ptr(), host_x.data(), nbytes, cudaMemcpyHostToDevice);
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
