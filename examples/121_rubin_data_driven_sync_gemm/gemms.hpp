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


#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"

#include "cute/tensor.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "compat.hpp"

#include "cutlass/gemm/collective/dependency_tracking.hpp"
#include "cutlass/epilogue/collective/dependency_tracking.hpp"

#if defined(ARCH_MMA_SUPPORTED) && defined(CUDA_HOST_SUPPORTED)

#ifndef USE_CLC_SCHEDULER
using TileScheduler = cutlass::gemm::StaticPersistentScheduler;
#else
using TileScheduler = cutlass::gemm::DynamicPersistentScheduler;
#endif

// Consistent dtypes and memory layouts so we don't have to cast/transpose.
using Element            = cutlass::half_t;
using ElementAccumulator = float;
using ElementCompute     = float;
using Layout = cutlass::layout::RowMajor;

using ElementA = Element;
using LayoutA = Layout;
constexpr int AlignmentA = 128 / cutlass::sizeof_bits<ElementA>::value;

using ElementB = Element;
using LayoutB = Layout;
constexpr int AlignmentB = 128 / cutlass::sizeof_bits<ElementB>::value;

using ElementD = Element;
using LayoutD = Layout;
constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

using ArchTag             = cutlass::arch::Sm107;
using OperatorClass       = cutlass::arch::OpClassTensorOp;

#ifdef RUN_2CTA_GEMM
using TileShape           = cute::Shape<cute::_256, cute::_128, cute::_64>;
using ClusterShape        = cute::Shape<cute::_2, cute::_1, cute::_1>;
#else
using TileShape           = cute::Shape<cute::_128, cute::_128, cute::_64>;
using ClusterShape        = cute::Shape<cute::_1, cute::_1, cute::_1>;
#endif

using KernelSchedule      = cutlass::gemm::collective::KernelScheduleAuto;
using EpilogueSchedule    = cutlass::epilogue::collective::EpilogueScheduleAuto;
using EpilogueTileType    = cutlass::epilogue::collective::EpilogueTileAuto;

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    TileShape, ClusterShape,
    EpilogueTileType,
    ElementAccumulator, ElementCompute,
    void, LayoutD, 1,
    ElementD, LayoutD, AlignmentD,
    EpilogueSchedule,
    cutlass::epilogue::fusion::PlainAcc<ElementD, ElementCompute>
  >::CollectiveOp;

using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA, AlignmentA,
    ElementB, LayoutB, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

// CollectiveMainloop (and sometimes CollectiveEpilogue) is "patched" to create the expected
// dependency chaining behavior.
//
// The first kernel in the chain is strictly a producer, and does not need any consumer kernel logic
// (wait_on_dependent_grids or report valid).
//
// The last kernel in the chain is strictly a consumer, and does not need any producer logic such as
// launch_dependent_grids, or zero canonicalization (if data-driven sync), but it needs
// wait_on_dependent_grids if using PDL (reference) or report valid on the tensor being consumed (A or
// B).
//
// Kernels in between are both consumer and producer.

// Reference Producer & Consumer: early launch_dependent_grids + wait_on_dependent_grids
using GemmKernelDefault = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::EarlyPdl,
      cutlass::gemm::ConsumerRoleType::Pdl
    >,
    CollectiveEpilogue,
    TileScheduler
>;

// Reference Producer (1st GEMM): early launch_dependent_grids only
using GemmKernelDefaultFirst = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::EarlyPdl,
      cutlass::gemm::ConsumerRoleType::None
    >,
    CollectiveEpilogue,
    TileScheduler
>;

// Reference Consumer (last GEMM): wait_on_dependent_grids only
using GemmKernelDefaultLast = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::None,
      cutlass::gemm::ConsumerRoleType::Default
    >,
    CollectiveEpilogue,
    TileScheduler
>;

// Data-driven sync Producer (1st GEMM): early launch_dependent_grids only (== GemmKernelDefaultFirst)
using GemmKernelDataDrivenSyncFirst = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::EarlyPdl,
      cutlass::gemm::ConsumerRoleType::None
    >,
    cutlass::epilogue::collective::make_dependency_tracking<
      CollectiveEpilogue,
      /*IsDataDrivenSyncConsumer=*/true
    >,
    TileScheduler
>;

// Data-driven sync Producer & Consumer (A): early launch_dependent_grids + report valid on A
using GemmKernelDataDrivenSyncA = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::EarlyPdl,
      cutlass::gemm::ConsumerRoleType::ReportValidA
    >,
    cutlass::epilogue::collective::make_dependency_tracking<
      CollectiveEpilogue,
      /*IsDataDrivenSyncConsumer=*/true
    >,
    TileScheduler
>;

// Data-driven sync Producer & Consumer (B): early launch_dependent_grids + report valid on B
using GemmKernelDataDrivenSyncB = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::EarlyPdl,
      cutlass::gemm::ConsumerRoleType::ReportValidB
    >,
    cutlass::epilogue::collective::make_dependency_tracking<
      CollectiveEpilogue,
      /*IsDataDrivenSyncConsumer=*/true
    >,
    TileScheduler
>;

// Data-driven sync Consumer (A) (last GEMM): report valid on A only, no 0 canonicalization
using GemmKernelDataDrivenSyncALast = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::None,
      cutlass::gemm::ConsumerRoleType::ReportValidA
    >,
    cutlass::epilogue::collective::make_dependency_tracking<
      CollectiveEpilogue,
      /*IsDataDrivenSyncConsumer=*/false
    >,
    TileScheduler
>;

// Data-driven sync Consumer (B) (last GEMM): report valid on B only, no 0 canonicalization
using GemmKernelDataDrivenSyncBLast = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int, int, int, int>, // ProblemShape (M, N, K, L)
    cutlass::gemm::collective::make_dependency_tracking<
      CollectiveMainloop,
      cutlass::gemm::ProducerRoleType::None,
      cutlass::gemm::ConsumerRoleType::ReportValidB
    >,
    cutlass::epilogue::collective::make_dependency_tracking<
      CollectiveEpilogue,
      /*IsDataDrivenSyncConsumer=*/false
    >,
    TileScheduler
>;

using GemmReference        = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDefault>;
using GemmReferenceFirst   = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDefaultFirst>;
using GemmReferenceLast    = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDefaultLast>;

using GemmDataDrivenSyncProducer  = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDataDrivenSyncFirst>;
using GemmDataDrivenSyncConsumerA = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDataDrivenSyncA>;
using GemmDataDrivenSyncConsumerB = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDataDrivenSyncB>;

using GemmDataDrivenSyncConsumerALast = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDataDrivenSyncALast>;
using GemmDataDrivenSyncConsumerBLast = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelDataDrivenSyncBLast>;

#endif // defined(ARCH_MMA_SUPPORTED) && defined(CUDA_HOST_SUPPORTED)
