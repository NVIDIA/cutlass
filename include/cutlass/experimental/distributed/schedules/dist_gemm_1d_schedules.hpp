/***************************************************************************************************
 * Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*!
  \file 1-D Distributed GEMM Schedules

  Device/iteration mappings are defined with CuTe layouts, 
  since they are functions from integers to integers as well.
  
  Each mapping is defined as a rank-3 layout:
   First mode is the device mode, second mode is iteration, third mode is a "bias" term.
   Mappings are defined as: (x * device_idx + y * iteration + z) % TP
   Their CuTe layout equivalent would be: <<TP, TP, 1>, <x, y, z>>
  
  Assumption made in all schedules: TP == NumStages(Iterations)
*/

#pragma once

#include "cute/layout.hpp"
#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"

#include "cutlass/experimental/distributed/schedules/dist_gemm_base_schedule.hpp"

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::distributed::schedules {

template <class TP_>
struct ReduceScatter1D_TilingA_RotatingC: BaseSchedule<
    TP_,
    /* ProcessorTiler_ = */ cute::Shape<_1, _1, TP_, _1>,
    /* IterationTiler_ = */ cute::Shape<TP_, _1, _1, _1>,
    /* PeerDeviceMapping_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _0, cute::C<-1>>>,                  // (left neighbor) = device_idx - 1
    /* ProcessorMappingA_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingB_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingC_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingD_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* IterationMappingA_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, cute::C<-1>, cute::C<TP_{} - 1>>>,  // = device_idx - iter + TP - 1
    /* IterationMappingB_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_0, _0, _0>>,                           // (broadcast) = 0
    /* IterationMappingC_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* IterationMappingD_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* MemcpyA_ = */ false,
    /* MemcpyB_ = */ false,
    /* KernelWritesArrivalFlag_ = */ true,
    /* NumBuffersA_ = */ 0,
    /* NumBuffersB_ = */ 0,
    /* NumBuffersC_ = */ 0,
    /* NumBuffersD_  = */ TP_{} - 1> {};

template <class TP_>
struct ReduceScatter1D_TilingB_RotatingC: BaseSchedule<
    TP_,
    /* ProcessorTiler_ = */ cute::Shape<_1, _1, TP_, _1>,
    /* IterationTiler_ = */ cute::Shape<_1, TP_, _1, _1>,
    /* PeerDeviceMapping_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _0, cute::C<-1>>>,                  // (left neighbor) = device_idx - 1
    /* ProcessorMappingA_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingB_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingC_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingD_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* IterationMappingA_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_0, _0, _0>>,                           // (broadcast) = 0
    /* IterationMappingB_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, cute::C<-1>, cute::C<TP_{} - 1>>>,  // = device_idx - iter + TP - 1
    /* IterationMappingC_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* IterationMappingD_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* MemcpyA_ = */ false,
    /* MemcpyB_ = */ false,
    /* KernelWritesArrivalFlag_ = */ true,
    /* NumBuffersA_ = */ 0,
    /* NumBuffersB_ = */ 0,
    /* NumBuffersC_ = */ 0,
    /* NumBuffersD_  = */ TP_{} - 1> {};

template <class TP_>
struct AllGather1D_TilingCD_RotatingA: BaseSchedule<
    TP_,
    /* ProcessorTiler_ = */ cute::Shape<_1, TP_, _1, _1>,
    /* IterationTiler_ = */ cute::Shape<TP_, _1, _1, _1>,
    /* PeerDeviceMapping_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* ProcessorMappingA_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingB_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingC_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingD_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* IterationMappingA_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* IterationMappingB_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_0, _0, _0>>,                           // (broadcast) = 0
    /* IterationMappingC_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* IterationMappingD_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* MemcpyA_ = */ true,
    /* MemcpyB_ = */ false,
    /* KernelWritesArrivalFlag_ = */ false,
    /* NumBuffersA_ = */ TP_{} - 1,
    /* NumBuffersB_ = */ 0,
    /* NumBuffersC_ = */ 0,
    /* NumBuffersD_ = */ 0>{};

template <class TP_>
struct AllGather1D_TilingCD_RotatingB: BaseSchedule<
    TP_,
    /* ProcessorTiler_ = */ cute::Shape<TP_, _1, _1, _1>,
    /* IterationTiler_ = */ cute::Shape<_1, TP_, _1, _1>,
    /* PeerDeviceMapping_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* ProcessorMappingA_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingB_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingC_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* ProcessorMappingD_ = */ cute::Layout<cute::Shape<TP_, _1>, cute::Stride<_1, _0>>,                                    // (identity) = device_idx
    /* IterationMappingA_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_0, _0, _0>>,                           // (broadcast) = 0
    /* IterationMappingB_ = */ cute::Layout<cute::Shape<_1, _1, _1>, cute::Stride<_0, _0, _0>>,                             // (unreachable) = 0
    /* IterationMappingC_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* IterationMappingD_ = */ cute::Layout<cute::Shape<TP_, TP_, _1>, cute::Stride<_1, _1, _0>>,                           // = device + iter
    /* MemcpyA_ = */ false,
    /* MemcpyB_ = */ true,
    /* KernelWritesArrivalFlag_ = */ false,
    /* NumBuffersA_ = */ 0,
    /* NumBuffersB_ = */ TP_{} - 1,
    /* NumBuffersC_ = */ 0,
    /* NumBuffersD_ = */ 0>{};


} // namespace cutlass::distributed::schedules

///////////////////////////////////////////////////////////////////////////////

