/***************************************************************************************************
 * Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

using namespace cutlass;

#include "cutlass/arch/arch.h"

template <class Element_>
struct TransposeKernel {
  using Element = Element_;

  // TODO: use more threads to copy tensor
  static constexpr int MaxThreadsPerBlock = 1;
  static constexpr int MinBlocksPerMultiprocessor = 1;
  using ArchTag = cutlass::arch::Sm90;

  static constexpr int AlignmentBytes = 16;

  struct SharedStorage {
    /* empty */
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);

  // batch_size, seqlen_q_ori, num_heads_k, ngroups, head_size
  using ProblemShape = cute::tuple<int, int, int, int, int>;

  struct Arguments {
    const Element *ptrS{nullptr};
    Element *ptrD{nullptr};
    ProblemShape problem_shape{};
  };

  struct Params {
    const Element *ptrS{nullptr};
    Element *ptrD{nullptr};
    ProblemShape problem_shape{};
  };

  static Params
  to_underlying_arguments(Arguments const&args, void* workspace) {
    return Params{
      args.ptrS,
      args.ptrD,
      args.problem_shape
    };
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
    auto [B, S, H, G, D] = params.problem_shape;
    return dim3(B*S, H, G);
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTLASS_DEVICE
  void
  operator()(Params params, [[maybe_unused]] char* smem_buf = nullptr) {
    auto [B, S, H, G, D] = params.problem_shape;

    // default is column-major layout
    auto src_layout_ = make_layout(make_shape(D,G,H,S,B));
    auto src_layout = make_layout(reverse(src_layout_.shape()), reverse(src_layout_.stride()));

    auto dst_layout_ = make_layout(make_shape(D,H,G,S,B));
    auto dst_layout = make_layout(reverse(dst_layout_.shape()), reverse(dst_layout_.stride()));

    auto src_tensor = make_tensor(
      make_gmem_ptr(params.ptrS),
      group<0,2>(src_layout)
    );

    auto dst_tensor = make_tensor(
      make_gmem_ptr(params.ptrD),
      group<0,2>(dst_layout)
    );
    
    auto tS = src_tensor(blockIdx.x, blockIdx.y, blockIdx.z, _);
    auto tD = dst_tensor(blockIdx.x, blockIdx.y, blockIdx.z, _);

    copy(tS, tD);
  }
};