/*
 * SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES.
 * All rights reserved. SPDX-License-Identifier: LicenseRef-NvidiaProprietary
 *
 * NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
 * property and proprietary rights in and to this material, related
 * documentation and any modifications thereto. Any use, reproduction,
 * disclosure or distribution of this material and related documentation
 * without an express license agreement from NVIDIA CORPORATION or
 * its affiliates is strictly prohibited.
 */
/**
 * This example demonstrates how to load a CuTe module/function from compilation
 * and static linking and run it in a CUDA kernel.
 *
 * To run this example:
 *
 * .. code-block:: bash
 *
 *    # prerequesites: export the compiled functions to object files and compile
 * them into a shared library python examples/cute/export/export_to_c.py # run
 * the example bash ./examples/cute/export/run_with_static_linking.sh
 */

#include "add_one_example.h"
#include "print_tensor_example.h"
#include <cuda_runtime.h>

void initialize_cuda_context() {
  // Initialize cuda context
  int device_id = 0;
  cudaSetDevice(device_id);
}

void run_print_tensor() {
  // prepare tensor
  print_tensor_Tensor_a_t tensor;
  tensor.data = NULL;
  tensor.dynamic_shapes[0] = 32;
  tensor.dynamic_shapes[1] = 16;
  tensor.dynamic_strides[0] = 16;

  // prepare stream
  cudaStream_t stream;
  cudaStreamCreate(&stream);

  // load module
  print_tensor_Kernel_Module_t module;
  print_tensor_Kernel_Module_Load(&module);

  // run kernel
  cute_dsl_print_tensor_wrapper(&module, &tensor, stream);

  // synchronize stream
  cudaStreamSynchronize(stream);

  // unload module
  print_tensor_Kernel_Module_Unload(&module);
  cudaStreamDestroy(stream);
}

void run_add_one() {
  // prepare a tensor
  add_one_Tensor_a_t a_tensor;
  float a_host_ptr[32 * 16];
  for (int i = 0; i < 32 * 16; i++) {
    a_host_ptr[i] = i;
  }
  void *a_device_ptr;
  cudaMalloc(&a_device_ptr, sizeof(float) * 32 * 16);
  cudaMemcpy(a_device_ptr, a_host_ptr, sizeof(float) * 32 * 16,
             cudaMemcpyHostToDevice);
  a_tensor.data = (void *)a_device_ptr;
  a_tensor.dynamic_shapes[0] = 32;
  a_tensor.dynamic_shapes[1] = 16;
  a_tensor.dynamic_strides[0] = 16;

  // prepare b tensor
  add_one_Tensor_b_t b_tensor;
  float b_host_ptr[32 * 16];
  for (int i = 0; i < 32 * 16; i++) {
    b_host_ptr[i] = 32 * 16 - i;
  }
  void *b_device_ptr;
  cudaMalloc(&b_device_ptr, sizeof(float) * 32 * 16);
  cudaMemcpy(b_device_ptr, b_host_ptr, sizeof(float) * 32 * 16,
             cudaMemcpyHostToDevice);

  b_tensor.data = (void *)b_device_ptr;
  b_tensor.dynamic_shapes[0] = 32;
  b_tensor.dynamic_shapes[1] = 16;
  b_tensor.dynamic_strides[0] = 16;

  // prepare stream
  cudaStream_t stream;
  cudaStreamCreate(&stream);

  // load module
  add_one_Kernel_Module_t module;
  add_one_Kernel_Module_Load(&module);

  // run kernel
  cute_dsl_add_one_wrapper(&module, &a_tensor, &b_tensor, stream);
  cudaStreamSynchronize(stream);

  // unload module
  add_one_Kernel_Module_Unload(&module);
  cudaStreamDestroy(stream);

  // check result
  cudaMemcpy(a_host_ptr, a_device_ptr, sizeof(float) * 32 * 16,
             cudaMemcpyDeviceToHost);

  if (a_host_ptr[0] != 32 * 16 + 1) {
    printf("Error: a_host_ptr[0] = %f, expected %d\n", a_host_ptr[0], 32 * 16);
  }
}

int main() {
  initialize_cuda_context();
  run_print_tensor();
  run_add_one();
  return 0;
}
