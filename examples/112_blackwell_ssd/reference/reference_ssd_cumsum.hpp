/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#pragma once

#include <algorithm>
#include <random>

#include "cutlass/coord.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/tensor_view.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/gemm.h"
#include "cutlass/arch/arch.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/cuda_host_adapter.hpp"

#include "cute/int_tuple.hpp"
#include "cute/atom/mma_traits_sm100.hpp"
#include "cute/util/debug.hpp"
#include "cute/config.hpp"

namespace cutlass::ssd::kernel {

using namespace cute;

template<
  class Element_,
  class ElementD_,
  class TileShape_>
struct CumsumKernel {
  using Element = Element_;
  using ElementD = ElementD_;
  using TileShape = TileShape_; // L,D,N

  // Required by `device_kernel`
  static constexpr int MaxThreadsPerBlock = 128;
  static constexpr int MinBlocksPerMultiprocessor = 1;
  using ArchTag = arch::Sm90;

  static constexpr int AlignmentBytes = 16;

  struct SharedStorage {
    /* empty, no smem needed */
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);

  struct TransformArguments {
    const Element* ptr_DeltaA;
    ElementD* ptr_Cumsum;
  };

  struct TransformParams {
    const Element* ptr_DeltaA;
    ElementD* ptr_Cumsum;
  };
  
  using ProblemShape = cute::tuple<int, int, int, int>; // b, eh, c, l
  struct Arguments {
    ProblemShape problem_shape{};
    TransformArguments transform{};
    KernelHardwareInfo hw_info{};
  };

  struct Params {
    ProblemShape problem_shape{};
    TransformParams transform{};
    KernelHardwareInfo hw_info{};
  };

  static Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    return Params{
      ProblemShape{args.problem_shape},
      TransformParams{args.transform.ptr_DeltaA, args.transform.ptr_Cumsum}, 
      KernelHardwareInfo{args.hw_info}};
  }

  static Status
  can_implement(Arguments const& args) {
    return Status::kSuccess;
  }

  static size_t
  get_workspace_size(Arguments const& args) {
    return size_t(0);
  }

  static Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  static dim3
  get_grid_shape(Params const& params) {
    auto [B, EH, C, L] = params.problem_shape;
    return dim3(B*EH, 1, 1);
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTE_HOST_DEVICE
  void
  operator()(Params params, [[maybe_unused]] char* smem_buf = nullptr) {
    auto [B, EH, C, L] = params.problem_shape;

    auto layout = make_layout(make_shape(L, C, EH*B));

    auto mD_bcl = make_tensor(make_gmem_ptr(params.transform.ptr_DeltaA), make_layout(reverse(layout.shape()), reverse(layout.stride())));
    auto mC_bcl = make_tensor(make_gmem_ptr(params.transform.ptr_Cumsum), make_layout(reverse(layout.shape()), reverse(layout.stride())));
    auto cD_bcl = make_identity_tensor(shape(mD_bcl));

    int blk_idx = blockIdx.x;
    int thread_idx = threadIdx.x;

    auto tD = logical_divide(mD_bcl(blk_idx,_,_), make_shape(Int<128>{},_))(make_coord(thread_idx,_),_);
    auto tC = logical_divide(mC_bcl(blk_idx,_,_), make_shape(Int<128>{},_))(make_coord(thread_idx,_),_);
    auto cD = logical_divide(cD_bcl(blk_idx,_,_), make_shape(Int<128>{},_))(make_coord(thread_idx,_),_);

    static constexpr int NumPacked = AlignmentBytes / sizeof(ElementD);
    using PackedTypeDeltaA = uint_bit_t<sizeof_bits_v<Element> * NumPacked>;
    using PackedTypeCumsum = uint_bit_t<sizeof_bits_v<ElementD> * NumPacked>;

#if 0
    if (thread_idx % 128 == 0 && blk_idx == 0) {
      print("tD  : ");print(tD);print("\n");
      print("tC  : ");print(tC);print("\n");
      print("cD  : ");print(cD);print("\n");
    }
#endif

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < shape<0>(tD); ++i) {
      float last_element = 0.f;
      auto crd = cD(i,_0{});
      auto tD_recast = recast<PackedTypeDeltaA>(tD);
      auto tC_recast = recast<PackedTypeCumsum>(tC);
      if (elem_less(crd, shape(mD_bcl))) {
        for (int j = 0; j < shape<1>(tD_recast); ++j) {
          auto tD_slice = make_tensor<Element>(make_shape(Int<NumPacked>{}));
          auto tC_slice = make_tensor<ElementD>(make_shape(Int<NumPacked>{}));
          auto tD_slice_recast = recast<PackedTypeDeltaA>(tD_slice);
          auto tC_slice_recast = recast<PackedTypeCumsum>(tC_slice);

          tD_slice_recast(_0{}) = tD_recast(i,j);
          for (int k = 0; k < NumPacked; ++ k) {
            last_element += static_cast<float>(tD_slice(k));
            tC_slice(k) = static_cast<ElementD>(last_element);
          }
          tC_recast(i,j) = tC_slice_recast(_0{});
        }
      }
    }
  }

private:

};

} // End namespace cutlass
