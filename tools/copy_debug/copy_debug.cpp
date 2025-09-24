/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include <cute/tensor.hpp>
#include <sycl/sycl.hpp>
#include <compat.hpp>

#include <cutlass/util/device_memory.h>
#include <compat/compat.hpp>
#include <cutlass/cutlass.h>

using namespace compat::experimental;
using namespace cute;

#define SUBGROUP_SIZE (16)

template <class...> class CopyKernelName;

template <class CopyInstruction, class TensorS, class fragment_size>
void copy_kernel(TensorS S) {
  using namespace cute;
  using Element = typename TensorS::value_type;

  // initialization
  if(thread(0)){
    for(int i=0; i<size(S); i++){
      S(i) = static_cast<Element>(i);
    }
  }
  syncthreads();

  using Copy = typename Copy_Traits<CopyInstruction, decltype(S)>::template DefaultTiledCopy<Element>;
  Copy tiled_copy_load{Copy{}.with(S)};
    
  auto thr_copy_load = tiled_copy_load.get_slice(ThreadIdxX());

  using actual_fragment_size = std::conditional_t<std::is_same_v<fragment_size, void>, C<Copy::NumValDst>, fragment_size>;
  Tensor fragment = make_tensor<Element>(make_shape(actual_fragment_size{},_1{},_1{}));
  clear(fragment);

  static_assert(actual_fragment_size::value >= Copy::NumValDst, "fragment is too small to hold all results!");
  Tensor fragment_copy_view = make_tensor(fragment.data(), make_shape(C<Copy::NumValDst>{},_1{},_1{}));
  auto blk_load_S = cute::get_xe_tensor(S.shape());
  // preferably we would not partition to be generic in case layouts in copies are wrong, but now that copies check size we need to
  auto thread_s = thr_copy_load.partition_S(blk_load_S(_,_,0));

  if(thread(0)){
    print("fragment_copy_view: "); print(fragment_copy_view); print("\n");
    print("thread_s: "); print(thread_s); print("\n");
  }
  
  copy(tiled_copy_load, thread_s, fragment_copy_view);
  
  for(int i=0;i<SUBGROUP_SIZE;i++){
    if(thread(i)){
      print("thread "); 
      if(i<10) print(" ");
      print(i); print(" ");
    }
  }
  for(int i = 0;i < size(fragment); i++){
    if(thread(0)){
      print("\n    ");
    }
    for(int j=0;j<SUBGROUP_SIZE;j++){
      if(thread(j)){
        if(fragment(i)<10) print(" ");
        if(fragment(i)<100) print(" ");
        if(fragment(i)<1000) print(" ");
        print(static_cast<int>(fragment(i))); print("      ");
      }
    }
  }
  if(thread(0)){
    print("\n");
  }
}

// by default select fragment size to match copy size. This can be set manually to a bigger value as copy size might be wrong
template <class CopyInstruction, class dtype, class fragment_size = void>
void copy(int global_M, int global_N) {
  using namespace cute;

  auto tensor_shape = make_shape(global_M, global_N, 1);
  int tensor_size = size(tensor_shape);
  cutlass::DeviceAllocation<dtype> src(tensor_size);

  Tensor tensor_S = make_tensor(make_gmem_ptr(src.get()), make_layout(tensor_shape, LayoutLeft{}));

  auto gridDim = compat::dim3(1);
  auto blockDim = compat::dim3(SUBGROUP_SIZE);
  launch<copy_kernel<CopyInstruction, decltype(tensor_S), fragment_size>, CopyKernelName<CopyInstruction, decltype(tensor_S)>>(
      launch_policy{gridDim, blockDim,
                    kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
      tensor_S);

  compat::wait_and_throw();
}

int main(){
  // for 16b copies use integers as floating point types could lose precision for bigger indices
  // for 8b copies you have to work with overflow
  //copy<XE_2D_U8x16x32_LD_T, uint8_t>(32, 32);
  copy<XE_2D_U8x32x4_LD_T, uint8_t>(256, 256);
  return 0;
}
