/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

// common
#include "cutlass/cutlass.h"
#include "cutlass/kernel_hardware_info.hpp"
#include "cute/tensor.hpp"

#include "../device/fmha.hpp"
#include "../kernel/sm100_fmha_bwd_dkdv_kernel_tma_warpspecialized.hpp"
#include "../kernel/sm100_fmha_bwd_dq_kernel_tma_warpspecialized.hpp"
#include "../kernel/fmha_kernel_bwd_sum_OdO.hpp"

#include <tuple>
////////////////////////////////////////////////////////////////////////////////

namespace cutlass::fmha::device {

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// CUTLASS 3.x API /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class Element,
    class ElementAccumulator,
    class TileShapeDKDV,
    class TileShapeDQ,
    class Mask
>
class Sm100Fmha2Bwd {
public:
  /// Argument structure: User API
  struct Arguments {
    // Q K D D_VO HB
    ProblemShape problem_shape;

    const Element* ptr_Q;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<int,int>, int>> stride_Q;
    const Element* ptr_K;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<cute::_0,int>, int>> stride_K;
    const Element* ptr_V;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<cute::_0,int>, int>> stride_V;

    const Element* ptr_O;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<int,int>, int>> stride_O;
    const ElementAccumulator* ptr_LSE;
    cute::tuple<cute::_1, cute::tuple<cute::tuple<int,int>, int>> stride_LSE;

    const Element* ptr_dO;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<int,int>, int>> stride_dO;

    Element* ptr_dK;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<cute::_0,int>, int>> stride_dK;
    Element* ptr_dV;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<cute::_0,int>, int>> stride_dV;
    Element* ptr_dQ;
    cute::tuple<int, cute::_1, cute::tuple<cute::tuple<int,int>, int>> stride_dQ;
    ElementAccumulator softmax_scale;

    cutlass::KernelHardwareInfo hw_info;
  };
  
  using OperationSumOdO = cutlass::fmha::device::FMHA<
    cutlass::fmha::kernel::FmhaKernelBwdSumOdO<ProblemShape, Element, ElementAccumulator>
  >;
  using OperationDKDV = cutlass::fmha::device::FMHA<
      cutlass::fmha::kernel::Sm100FmhaBwdDKDVKernelTmaWarpSpecialized<
          ProblemShape, Element, ElementAccumulator, TileShapeDKDV, Mask
      >
  >;
  using OperationDQ = cutlass::fmha::device::FMHA<
      cutlass::fmha::kernel::Sm100FmhaBwdDQKernelTmaWarpSpecialized<
          ProblemShape, Element, ElementAccumulator, TileShapeDQ, Mask
      >
  >;
  using KernelDKDV = typename OperationDKDV::Kernel;
  using KernelDQ   = typename OperationDQ::Kernel;

  struct Params {
    OperationSumOdO op_sum_OdO;
    OperationDKDV op_dkdv;
    OperationDQ op_dq;
  };

private:
  Params params_;

  static typename OperationSumOdO::Arguments to_sum_OdO_arguments(
        Arguments const& args,
        ElementAccumulator* sum_odo = nullptr,
        ElementAccumulator* scaled_lse = nullptr) {
    using namespace cute;
    auto [Q_, K, D, D_VO, HB] = args.problem_shape;
    auto [H, B] = HB;
    auto [H_R, H_K] = H;
    D = cutlass::round_up(D, 8);  // Alignment
    int Q = cutlass::round_up(static_cast<int>(Q_), 8);  // Alignment
    auto stride_sum_OdO = make_stride(_1{}, make_stride(make_stride(Q, Q*H_R), B == 1 ? 0 : Q*H_R*H_K));
    auto stride_scaled_lse = make_stride(_1{}, make_stride(make_stride(Q, Q*H_R), B == 1 ? 0 : Q*H_R*H_K));
    auto log2_e = log2f(expf(1.0f));
    return typename OperationSumOdO::Arguments {
      args.problem_shape,
      args.ptr_O, args.stride_O,
      args.ptr_dO, args.stride_dO,
      sum_odo, stride_sum_OdO,
      args.ptr_LSE, args.stride_LSE,
      scaled_lse, stride_scaled_lse,
      -1.0f, -log2_e
    };
  }

  static auto to_bwd_dkdv_arguments(
      Arguments const& args,
      ElementAccumulator* sum_OdO = nullptr, cute::tuple<cute::_1, cute::tuple<cute::tuple<int, int>, int>> const& stride_sum_OdO = {},
      ElementAccumulator* scaled_lse = nullptr, cute::tuple<cute::_1, cute::tuple<cute::tuple<int, int>, int>> const& stride_scaled_lse = {}) {
           
    return typename OperationDKDV::Arguments{
      args.problem_shape,
      { args.ptr_Q,  args.stride_Q,
        args.ptr_K,  args.stride_K,
        args.ptr_V,  args.stride_V,
        args.ptr_dO, args.stride_dO,
        scaled_lse, stride_scaled_lse,
        sum_OdO, stride_sum_OdO,
        args.softmax_scale },
      { args.ptr_dK, args.stride_dK,
        args.ptr_dV, args.stride_dV },
      args.hw_info
    };
  }
   
  static auto to_bwd_dq_arguments(
      Arguments const& args,
      ElementAccumulator* sum_OdO = nullptr, cute::tuple<cute::_1, cute::tuple<cute::tuple<int, int>, int>> const& stride_sum_OdO = {},
      ElementAccumulator* scaled_lse = nullptr, cute::tuple<cute::_1, cute::tuple<cute::tuple<int, int>, int>> const& stride_scaled_lse = {}) {
      
    return typename OperationDQ::Arguments{
      args.problem_shape,
      { args.ptr_Q,  args.stride_Q,
        args.ptr_K,  args.stride_K,
        args.ptr_V,  args.stride_V,
        args.ptr_dO, args.stride_dO,
        scaled_lse, stride_scaled_lse,
        sum_OdO, stride_sum_OdO,
        args.softmax_scale },
      { args.ptr_dQ, args.stride_dQ },
      args.hw_info
    };
  }

public:
  /// Determines whether the GEMM can execute the given problem.
  static Status
  can_implement(Arguments const& args) {
    Status status = Status::kSuccess;

    status = OperationSumOdO::can_implement(to_sum_OdO_arguments(args));
    if (status != Status::kSuccess) {
      return status;
    }

    status = OperationDKDV::can_implement(to_bwd_dkdv_arguments(args));
    if (status != Status::kSuccess) {
      return status;
    }

    status = OperationDQ::can_implement(to_bwd_dq_arguments(args));
    if (status != Status::kSuccess) {
      return status;
    }

    return status;
  }

  /// Gets the workspace size
  static size_t
  get_workspace_size(Arguments const& args) {
    auto [Q_, K, D, D_VO, HB] = args.problem_shape;
    auto [H, B] = product_each(HB);
    D = cutlass::round_up(D, 8);  // Alignment
    int Q = cutlass::round_up(static_cast<int>(Q_), 8);  // Alignment
    size_t workspace_bytes = 0;
    // OdO vector
    workspace_bytes += B*H*Q * sizeof(ElementAccumulator);
    // scaled LSE vector
    workspace_bytes += B*H*Q * sizeof(ElementAccumulator);

    return workspace_bytes;
  }

  /// Initializes state from arguments.
  Status
  initialize_split(Arguments const& args, void* workspace_sum_OdO, void* workspace_scaled_lse, cudaStream_t stream = nullptr) {
    CUTLASS_TRACE_HOST("Universal::initialize_split() - workspace_sum_OdO=" 
		    << workspace_sum_OdO << "stream: " << (stream ? "non-null" : "null"));

    auto [Q_, K, D, D_VO, HB] = args.problem_shape;
    auto [H, B] = product_each(HB);
    D = cutlass::round_up(D, 8);  // Alignment
    int Q = cutlass::round_up(static_cast<int>(Q_), 8);  // Alignment
    ElementAccumulator* sum_OdO = reinterpret_cast<ElementAccumulator*>(workspace_sum_OdO);
    ElementAccumulator* scaled_lse = reinterpret_cast<ElementAccumulator*>(workspace_scaled_lse);
    auto args_sum_OdO = to_sum_OdO_arguments(args, sum_OdO, scaled_lse);
    params_.op_sum_OdO.initialize(args_sum_OdO, nullptr, stream);
    auto args_bwd_dkdv = to_bwd_dkdv_arguments(
        args, sum_OdO, args_sum_OdO.stride_sum_OdO,
        scaled_lse, args_sum_OdO.stride_scaled_lse
    );
    params_.op_dkdv.initialize(args_bwd_dkdv, nullptr, stream);
    auto args_bwd_dq = to_bwd_dq_arguments(
        args, sum_OdO, args_sum_OdO.stride_sum_OdO,
        scaled_lse, args_sum_OdO.stride_scaled_lse
    );
    params_.op_dq.initialize(args_bwd_dq, nullptr, stream);

    return Status::kSuccess;
  }

  /// Initializes state from arguments.
  Status
  initialize(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr) {
    CUTLASS_TRACE_HOST("Universal::initialize() - workspace "
      << workspace << ", stream: " << (stream ? "non-null" : "null"));

    auto [Q_, K, D, D_VO, HB] = args.problem_shape;
    auto [H, B] = product_each(HB);
    D = cutlass::round_up(D, 8);  // Alignment
    int Q = cutlass::round_up(static_cast<int>(Q_), 8);  // Alignment
    char* workspace_chr = reinterpret_cast<char*>(workspace);
    ElementAccumulator* sum_OdO = reinterpret_cast<ElementAccumulator*>(workspace_chr);
    workspace_chr += B*H*Q * sizeof(ElementAccumulator);
    ElementAccumulator* scaled_lse = reinterpret_cast<ElementAccumulator*>(workspace_chr);
    workspace_chr += B*H*Q * sizeof(ElementAccumulator);
    return initialize_split(args, sum_OdO, scaled_lse, stream);
  }

  /// Primary run() entry point API that is static allowing users to create and manage their own params.
  /// Supplied params struct must be construct by calling Kernel::to_underling_arguments()
  static Status
  run(Params& params, cudaStream_t stream = nullptr) {
    CUTLASS_TRACE_HOST("FmhaDevice2Bwd::run()");

    Status result = Status::kSuccess;
    result = params.op_sum_OdO.run(stream);
    if (result != Status::kSuccess) {
      return result;
    }
    result = params.op_dkdv.run(stream);
    if (result != Status::kSuccess) {
      return result;
    }
    result = params.op_dq.run(stream);
    if (result != Status::kSuccess) {
      return result;
    }
    return Status::kSuccess;
  }

  //
  // Non-static launch overloads that first create and set the internal params struct of this kernel handle.
  //

  /// Launches the kernel after first constructing Params internal state from supplied arguments.
  Status
  run(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr) {
    Status status = initialize(args, workspace, stream);
    if (Status::kSuccess == status) {
      status = run(params_, stream);
    }
    return status;
  }

  /// Overload that allows a user to re-launch the same kernel without updating internal params struct.
  Status
  run(cudaStream_t stream = nullptr) {
    return run(params_, stream);
  }

};

////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::fmha::device

////////////////////////////////////////////////////////////////////////////////
