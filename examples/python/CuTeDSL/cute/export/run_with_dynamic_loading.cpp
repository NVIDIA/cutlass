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
 * This example demonstrates how to load a CuTe module/function from a object
 * file or a shared library and run it in a CUDA kernel.
 *
 * To run this example:
 *
 * .. code-block:: bash
 *
 *    # prerequesites: export the compiled functions to object files and compile
 * them into a shared library python examples/cute/export/export_to_c.py # run
 * the example bash ./examples/cute/export/run_with_dynamic_loading.sh
 */

#include "CuteDSLRuntime.h"
#include <cuda_runtime.h>
#include <fstream>
#include <vector>

std::vector<unsigned char> read_file(const std::string &filename) {
  std::ifstream file(filename, std::ios::binary);
  std::vector<unsigned char> content((std::istreambuf_iterator<char>(file)),
                                     std::istreambuf_iterator<char>());
  return content;
}

void initialize_cuda_context() {
  // Initialize cuda context
  cudaSetDevice(0);
}

void check_error(CuteDSLRT_Error_t error) {
  if (error != CuteDSLRT_Error_Success) {
    printf("Got runtime error: %d\n", error);
    exit(1);
  }
}

// Copy the definition of the tensor from `print_tensor_example.h` to here
typedef struct {
  void *data;
  int32_t dynamic_shapes[2];
  int64_t dynamic_strides[1];
} print_tensor_Tensor_a_t;

// Copy the definition of the tensor from `add_one_example.h` to here
typedef struct {
  void *data;
  int32_t dynamic_shapes[2];
  int64_t dynamic_strides[1];
} add_one_Tensor_a_t;
typedef struct {
  void *data;
  int32_t dynamic_shapes[2];
  int64_t dynamic_strides[1];
} add_one_Tensor_b_t;

print_tensor_Tensor_a_t prepare_print_tensor_tensor() {
  print_tensor_Tensor_a_t tensor;
  tensor.data = NULL;
  tensor.dynamic_shapes[0] = 32;
  tensor.dynamic_shapes[1] = 16;
  tensor.dynamic_strides[0] = 16;
  return tensor;
}

add_one_Tensor_a_t prepare_add_one_tensor_a() {
  float a_host_ptr[32 * 16];
  for (int i = 0; i < 32 * 16; i++) {
    a_host_ptr[i] = i;
  }
  void *a_device_ptr;
  cudaMalloc(&a_device_ptr, sizeof(float) * 32 * 16);
  cudaMemcpy(a_device_ptr, a_host_ptr, sizeof(float) * 32 * 16,
             cudaMemcpyHostToDevice);
  add_one_Tensor_a_t tensor;
  tensor.data = (void *)a_device_ptr;
  tensor.dynamic_shapes[0] = 32;
  tensor.dynamic_shapes[1] = 16;
  tensor.dynamic_strides[0] = 16;
  return tensor;
}

add_one_Tensor_b_t prepare_add_one_tensor_b() {
  float b_host_ptr[32 * 16];
  for (int i = 0; i < 32 * 16; i++) {
    b_host_ptr[i] = 32 * 16 - i;
  }
  void *b_device_ptr;
  cudaMalloc(&b_device_ptr, sizeof(float) * 32 * 16);
  cudaMemcpy(b_device_ptr, b_host_ptr, sizeof(float) * 32 * 16,
             cudaMemcpyHostToDevice);
  add_one_Tensor_b_t tensor;
  tensor.data = (void *)b_device_ptr;
  tensor.dynamic_shapes[0] = 32;
  tensor.dynamic_shapes[1] = 16;
  tensor.dynamic_strides[0] = 16;
  return tensor;
}

void run_print_tensor_with_object_file() {

  // prepare tensor
  print_tensor_Tensor_a_t tensor = prepare_print_tensor_tensor();

  // prepare stream
  cudaStream_t stream;
  cudaStreamCreate(&stream);

  // load module and function
  CuteDSLRT_Module_t *module = nullptr;
  std::vector<unsigned char> print_tensor_example_o_bytes =
      read_file("build/print_tensor_example.o");
  size_t print_tensor_example_o_size = print_tensor_example_o_bytes.size();
  CuteDSLRT_Error_t error = CuteDSLRT_Module_Create_From_Bytes(
      &module, print_tensor_example_o_bytes.data(), print_tensor_example_o_size,
      nullptr, 0);
  check_error(error);

  CuteDSLRT_Function_t *function = nullptr;
  error = CuteDSLRT_Module_Get_Function(&function, module, "print_tensor");
  check_error(error);

  // run kernel, refer to the wrapper function in `print_tensor_example.h`
  int32_t cuda_result;
  void *args[3] = {&tensor, &stream, &cuda_result};
  error = CuteDSLRT_Function_Run(function, args, 3);
  check_error(error);

  // synchronize stream
  cudaStreamSynchronize(stream);

  // unload module
  error = CuteDSLRT_Module_Destroy(module);
  check_error(error);
  cudaStreamDestroy(stream);
}

void run_add_one_with_object_file() {
  // prepare a tensor
  add_one_Tensor_a_t tensor_a = prepare_add_one_tensor_a();

  // prepare b tensor
  add_one_Tensor_b_t tensor_b = prepare_add_one_tensor_b();

  // prepare stream
  cudaStream_t stream;
  cudaStreamCreate(&stream);

  // load module
  CuteDSLRT_Module_t *module = nullptr;
  std::vector<unsigned char> add_one_example_o_bytes =
      read_file("build/add_one_example.o");
  size_t add_one_example_o_size = add_one_example_o_bytes.size();
  CuteDSLRT_Error_t error = CuteDSLRT_Module_Create_From_Bytes(
      &module, add_one_example_o_bytes.data(), add_one_example_o_size, nullptr,
      0);
  check_error(error);

  CuteDSLRT_Function_t *function = nullptr;
  error = CuteDSLRT_Module_Get_Function(&function, module, "add_one");
  check_error(error);

  // run kernel, refer to the wrapper function in `add_one_example.h`
  int32_t cuda_result;
  void *args[4] = {&tensor_a, &tensor_b, &stream, &cuda_result};
  error = CuteDSLRT_Function_Run(function, args, 4);
  check_error(error);
  cudaStreamSynchronize(stream);

  // unload module
  error = CuteDSLRT_Module_Destroy(module);
  check_error(error);
  cudaStreamDestroy(stream);

  // check result
  float a_host_ptr[32 * 16];
  cudaMemcpy(a_host_ptr, tensor_a.data, sizeof(float) * 32 * 16,
             cudaMemcpyDeviceToHost);

  if (a_host_ptr[0] != 32 * 16 + 1) {
    printf("Error: a_host_ptr[0] = %f, expected %d\n", a_host_ptr[0], 32 * 16);
    exit(1);
  }
}

void run_example_with_shared_library() {
  // prepare tensor
  print_tensor_Tensor_a_t tensor = prepare_print_tensor_tensor();

  // prepare a tensor
  add_one_Tensor_a_t tensor_a = prepare_add_one_tensor_a();

  // prepare b tensor
  add_one_Tensor_b_t tensor_b = prepare_add_one_tensor_b();

  // prepare stream
  cudaStream_t stream;
  cudaStreamCreate(&stream);

  // load module
  CuteDSLRT_Module_t *module = nullptr;
  const char *shared_libs[] = {"build/libexport_example.so"};
  CuteDSLRT_Error_t error =
      CuteDSLRT_Module_Create_From_Bytes(&module, nullptr, 0, shared_libs, 1);
  check_error(error);

  // get print tensor function
  CuteDSLRT_Function_t *print_tensor_function = nullptr;
  error = CuteDSLRT_Module_Get_Function(&print_tensor_function, module,
                                        "print_tensor");
  check_error(error);

  // get add one function
  CuteDSLRT_Function_t *add_one_function = nullptr;
  error = CuteDSLRT_Module_Get_Function(&add_one_function, module, "add_one");
  check_error(error);

  // run print tensor kernel
  int32_t cuda_result;
  void *print_tensor_args[3] = {&tensor, &stream, &cuda_result};
  error = CuteDSLRT_Function_Run(print_tensor_function, print_tensor_args, 3);
  check_error(error);
  cudaStreamSynchronize(stream);

  // run add one kernel
  void *add_one_args[4] = {&tensor_a, &tensor_b, &stream, &cuda_result};
  error = CuteDSLRT_Function_Run(add_one_function, add_one_args, 4);
  check_error(error);
  cudaStreamSynchronize(stream);

  // unload module
  error = CuteDSLRT_Module_Destroy(module);
  check_error(error);
  cudaStreamDestroy(stream);
}

int main() {
  initialize_cuda_context();
  run_print_tensor_with_object_file();
  run_add_one_with_object_file();
  run_example_with_shared_library();
  return 0;
}
