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

/*! \file
    \brief
*/

#include <iostream>
#include <vector>
#include <exception>
#include <random>
#include <cfloat>

#include "cute/tensor.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/fusion/operations.hpp"
#include "cutlass/epilogue/thread/activation.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"
#include "options.hpp"
#include "utils.hpp"
#include "sm90_lin_comb_elt_act_scaled.hpp"
#include "activation_kernel.cuh"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

#if 0
template<class T>
using ActivationFn = cutlass::epilogue::thread::ReLu<T>;
#elif 1
template<class T>
using ActivationFn = cutlass::epilogue::thread::SiLu<T>;
#else
template<class T>
using ActivationFn = cutlass::epilogue::thread::Identity<T>;
#endif

bool constexpr IsFp8         = true;  // whether to run with fp8 or fp16 input/output
bool constexpr Quantize      = true;  // whether to quantize output with a per-tensor scale factor
bool constexpr ExactMode     = false; // whether to reproduce unfused dual gemm+activation exactly
bool constexpr BiasBroadcast = true;  // whether bias is broadcast along columns in each group
bool constexpr Pingpong      = true;  // whether to use pingpong schedule

using ProblemShape = Shape<int,int,int>; // <M,N,K> per group
using GroupProblemShape = cutlass::gemm::GroupProblemShape<ProblemShape>;

// A matrix configuration
using         ElementA    = conditional_t<IsFp8, cutlass::float_e4m3_t, cutlass::half_t>; // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                                    // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;                  // Alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = conditional_t<IsFp8, cutlass::float_e5m2_t, cutlass::half_t>; // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                                 // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;                  // Alignment of B matrix in units of elements (up to 16 bytes)

// C matrix configuration
using         ElementC    = cutlass::half_t;                                              // Element type for C matrix operand
using         LayoutC     = cutlass::layout::ColumnMajor;                                 // Layout type for C matrix operand
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;                  // Alignment of C matrix in units of elements (up to 16 bytes)

// D matrix configuration
using         ElementD    = conditional_t<IsFp8, cutlass::float_e4m3_t, cutlass::half_t>; // Element type for D matrix operand
using         LayoutD     = cutlass::layout::ColumnMajor;                                 // Layout type for D matrix operand
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;                  // Alignment of D matrix in units of elements (up to 16 bytes)

int constexpr AlignmentM = max(make_tuple(cutlass::gemm::detail::is_mn_major_A<LayoutA>() ? AlignmentA : 1,
                                          cutlass::gemm::detail::is_m_major_C<LayoutC>()  ? AlignmentC : 1,
                                          cutlass::gemm::detail::is_m_major_C<LayoutD>()  ? AlignmentD : 1));
int constexpr AlignmentN = max(make_tuple(cutlass::gemm::detail::is_mn_major_B<LayoutB>() ? AlignmentB : 1,
                                          cutlass::gemm::detail::is_n_major_C<LayoutC>()  ? AlignmentC : 1,
                                          cutlass::gemm::detail::is_n_major_C<LayoutD>()  ? AlignmentD : 1));
int constexpr AlignmentK = max(make_tuple(cutlass::gemm::detail::is_k_major_A<LayoutA>()  ? AlignmentA : 1,
                                          cutlass::gemm::detail::is_k_major_B<LayoutB>()  ? AlignmentB : 1));

// Core kernel configurations
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ElementCompute      = float;                                          // Element type for epilogue compute
using ElementScalar       = float;                                          // Element type for scalar values (alpha, beta)
using ElementIntermediate = cutlass::half_t;                                 // Element type of intermediate result between GEMM and bias+activation
using ArchTag             = cutlass::arch::Sm90;                            // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;                 // Operator class tag
using EpiTileShape        = cutlass::epilogue::collective::EpilogueTileAuto;
using ClusterShape        = Shape<_1,_2,_1>;
using TileShapeK          = Int<128 * 8 / sizeof_bits<ElementA>::value>;

using KernelScheduleCooperative = conditional_t<cutlass::gemm::collective::detail::is_input_fp8<ElementA, ElementB>(),
                                                cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperativeFP8FastAccum,
                                                cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative>;

using KernelSchedulePingpong    = conditional_t<cutlass::gemm::collective::detail::is_input_fp8<ElementA, ElementB>(),
                                                cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpongFP8FastAccum,
                                                cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong>;

using KernelSchedule   = conditional_t<Pingpong, KernelSchedulePingpong, KernelScheduleCooperative>;
using EpilogueSchedule = conditional_t<Pingpong, cutlass::epilogue::PtrArrayTmaWarpSpecializedPingpong, cutlass::epilogue::PtrArrayTmaWarpSpecializedCooperative>;
using TileShape        = conditional_t<Pingpong, Shape<_128,_128,TileShapeK>, Shape<_128,_256,TileShapeK>>;

// GEMM setup

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    EpiTileShape,
    ElementAccumulator, ElementCompute,
    ElementC, LayoutC *, AlignmentC,
    ElementD, LayoutD *, AlignmentD,
    EpilogueSchedule,
    cutlass::epilogue::fusion::AccCastLinCombEltActScale<
      Quantize,
      ActivationFn,
      ElementD,
      ElementCompute,
      ElementC,
      ElementScalar,
      conditional_t<ExactMode, ElementIntermediate, ElementCompute>
    >
  >::CollectiveOp;

using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA *, AlignmentA,
    ElementB, LayoutB *, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    KernelSchedule
  >::CollectiveOp;

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    GroupProblemShape,
    CollectiveMainloop,
    CollectiveEpilogue
>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Reference GEMM setup

using CollectiveEpilogueRef = typename cutlass::epilogue::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    TileShape, ClusterShape, EpiTileShape,
    ElementAccumulator, ElementCompute,
    void,     LayoutC *, AlignmentC,
    ElementIntermediate, LayoutD *, AlignmentD,
    EpilogueSchedule,
    cutlass::epilogue::fusion::ScaledAcc<ElementIntermediate, ElementCompute, ElementScalar>
  >::CollectiveOp;

using CollectiveMainloopRef = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA *, AlignmentA,
    ElementB, LayoutB *, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogueRef::SharedStorage))>,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelRef = cutlass::gemm::kernel::GemmUniversal<
    GroupProblemShape,
    CollectiveMainloopRef,
    CollectiveEpilogueRef
>;

using GemmRef = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelRef>;

using StrideA = GemmKernel::InternalStrideA;
using StrideB = GemmKernel::InternalStrideB;
using StrideC = GemmKernel::InternalStrideC;
using StrideD = GemmKernel::InternalStrideD;

// Host-side allocations
std::vector<ProblemShape> problem_shapes_host;

std::vector<int64_t> offset_A;
std::vector<int64_t> offset_B;
std::vector<int64_t> offset_C;
std::vector<int64_t> offset_D;
std::vector<int64_t> offset_col_D_host;

std::vector<StrideA> stride_A_host;
std::vector<StrideB> stride_B_host;
std::vector<StrideC> stride_C_host;
std::vector<StrideD> stride_D_host;

std::vector<ElementScalar> alpha_host;
std::vector<ElementScalar> beta_host;
std::vector<ElementScalar> scale_host;

// Device-side allocations
cutlass::DeviceAllocation<ProblemShape> problem_shapes;

cutlass::DeviceAllocation<ElementA> block_A;
cutlass::DeviceAllocation<ElementB> block_B;
cutlass::DeviceAllocation<ElementC> block_C;
cutlass::DeviceAllocation<ElementD> block_D;
cutlass::DeviceAllocation<ElementD> block_D_ref;
cutlass::DeviceAllocation<ElementIntermediate> block_D_ref_gemm;

cutlass::DeviceAllocation<ElementA const*> ptr_A;
cutlass::DeviceAllocation<ElementB const*> ptr_B;
cutlass::DeviceAllocation<ElementC const*> ptr_C;
cutlass::DeviceAllocation<ElementD *> ptr_D;
cutlass::DeviceAllocation<ElementIntermediate *> ptr_D_ref;
cutlass::DeviceAllocation<int64_t> offset_col_D;

cutlass::DeviceAllocation<StrideA> stride_A;
cutlass::DeviceAllocation<StrideB> stride_B;
cutlass::DeviceAllocation<StrideC> stride_C;
cutlass::DeviceAllocation<StrideD> stride_D;

// Note, this is an array of pointers to alpha and beta scaling values per group
cutlass::DeviceAllocation<ElementScalar const*> ptr_alpha;
cutlass::DeviceAllocation<ElementScalar const*> ptr_beta;
cutlass::DeviceAllocation<ElementScalar> block_alpha;
cutlass::DeviceAllocation<ElementScalar> block_beta;
cutlass::DeviceAllocation<ElementScalar> block_scale;

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

using Options = GroupedGemmOptions;

/// Allocates device-side data
void allocate(const Options &options) {
  int64_t total_elements_A = 0;
  int64_t total_elements_B = 0;
  int64_t total_elements_C = 0;
  int64_t total_elements_D = 0;
  int64_t total_cols_D = 0;

  for (int32_t i = 0; i < options.groups; ++i) {

    cutlass::gemm::GemmCoord const& problem_size = options.problem_sizes[i];
    auto problem_shape_ref = make_shape(problem_size.m(), problem_size.n(), problem_size.k());
    auto [M, N, K] = problem_shape_ref;

    problem_shapes_host.push_back(make_shape(M, N, K));

    offset_A.push_back(total_elements_A);
    offset_B.push_back(total_elements_B);
    offset_C.push_back(total_elements_C);
    offset_D.push_back(total_elements_D);
    offset_col_D_host.push_back(total_cols_D);

    int64_t elements_A = M * K;
    int64_t elements_B = K * N;
    int64_t elements_C = M * N;
    int64_t elements_D = M * N;

    stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1}));
    stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1}));
    stride_C_host.push_back(cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1}));
    stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1}));

    if constexpr (BiasBroadcast) {
      get<1>(stride_C_host.back()) = 0;
      elements_C = M;
    }

    total_elements_A += elements_A;
    total_elements_B += elements_B;
    total_elements_C += elements_C;
    total_elements_D += elements_D;
    total_cols_D += N;
  }
  offset_col_D_host.push_back(total_cols_D);

  block_A.reset(total_elements_A);
  block_B.reset(total_elements_B);
  block_C.reset(total_elements_C);
  block_D.reset(total_elements_D);
  block_D_ref.reset(total_elements_D);
  block_D_ref_gemm.reset(total_elements_D);
  block_alpha.reset(options.groups);
  block_beta.reset(options.groups);
  block_scale.reset(1);

  problem_shapes.reset(options.groups);

  ptr_A.reset(options.groups);
  ptr_B.reset(options.groups);
  ptr_C.reset(options.groups);
  ptr_D.reset(options.groups);
  ptr_D_ref.reset(options.groups);
  ptr_alpha.reset(options.groups);
  ptr_beta.reset(options.groups);

  stride_A.reset(options.groups);
  stride_B.reset(options.groups);
  stride_C.reset(options.groups);
  stride_D.reset(options.groups);

  offset_col_D.reset(options.groups + 1);
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {

  //
  // Assign pointers
  //

  std::vector<ElementA const*>      ptr_A_host(options.groups);
  std::vector<ElementB const*>      ptr_B_host(options.groups);
  std::vector<ElementC const*>      ptr_C_host(options.groups);
  std::vector<ElementD*>            ptr_D_host(options.groups);
  std::vector<ElementIntermediate*> ptr_D_ref_host(options.groups);
  std::vector<ElementScalar const*> ptr_alpha_host(options.groups);
  std::vector<ElementScalar const*> ptr_beta_host(options.groups);

  std::mt19937 rng(2024);
  std::uniform_real_distribution<ElementScalar> alpha_dist(0.5, 2.0);
  std::uniform_real_distribution<ElementScalar> beta_dist(1.0, 1.0); // (0.0, 4.0);
  std::uniform_real_distribution<ElementScalar> scale_dist(0.5, 1.0);

  for (int32_t i = 0; i < options.groups; ++i) {
    ptr_A_host[i] = block_A.get() + offset_A[i];
    ptr_B_host[i] = block_B.get() + offset_B[i];
    ptr_C_host[i] = block_C.get() + offset_C[i];
    ptr_D_host[i] = block_D.get() + offset_D[i];
    ptr_D_ref_host[i] = block_D_ref_gemm.get() + offset_D[i];
    alpha_host.push_back(options.alpha == FLT_MAX ? alpha_dist(rng) : options.alpha);
    beta_host.push_back(options.beta == FLT_MAX ? beta_dist(rng) : options.beta);
    ptr_alpha_host[i] = block_alpha.get() + i;
    ptr_beta_host[i] = block_beta.get() + i;
  }
  scale_host.push_back(scale_dist(rng));

  problem_shapes.copy_from_host(problem_shapes_host.data());

  ptr_A.copy_from_host(ptr_A_host.data());
  ptr_B.copy_from_host(ptr_B_host.data());
  ptr_C.copy_from_host(ptr_C_host.data());
  ptr_D.copy_from_host(ptr_D_host.data());
  ptr_D_ref.copy_from_host(ptr_D_ref_host.data());
  ptr_alpha.copy_from_host(ptr_alpha_host.data());
  ptr_beta.copy_from_host(ptr_beta_host.data());

  stride_A.copy_from_host(stride_A_host.data());
  stride_B.copy_from_host(stride_B_host.data());
  stride_C.copy_from_host(stride_C_host.data());
  stride_D.copy_from_host(stride_D_host.data());

  offset_col_D.copy_from_host(offset_col_D_host.data());

  block_alpha.copy_from_host(alpha_host.data());
  block_beta.copy_from_host(beta_host.data());
  block_scale.copy_from_host(scale_host.data());

  cutlass::reference::device::BlockFillRandom(block_A.get(), block_A.size(), 2024, options.dist_a);
  cutlass::reference::device::BlockFillRandom(block_B.get(), block_B.size(), 2025, options.dist_b);
  cutlass::reference::device::BlockFillRandom(block_C.get(), block_C.size(), 2026, options.dist_c);
}

template <typename GemmT>
auto args_from_options_common(const Options &options, bool host_problem_shapes_available)
{
  cutlass::KernelHardwareInfo hw_info;
  hw_info.device_id = 0;
  hw_info.sm_count = options.sm_count > 0 
                   ? options.sm_count 
                   : cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  typename GemmT::Arguments arguments;
  decltype(arguments.epilogue.thread) fusion_args{};

  if (options.alpha != FLT_MAX) {
    fusion_args.alpha = options.alpha;
  }
  else {
    fusion_args.alpha_ptr_array = ptr_alpha.get();
    fusion_args.dAlpha = {{},{},1};
  }

  auto problem_shapes_host_ptr = host_problem_shapes_available ? problem_shapes_host.data() : nullptr;

  return make_tuple(fusion_args, hw_info, problem_shapes_host_ptr);
}

template <typename GemmT>
typename GemmT::Arguments
args_from_options(const Options &options, bool host_problem_shapes_available);

template <>
Gemm::Arguments
args_from_options<Gemm>(const Options &options, bool host_problem_shapes_available)
{
  auto [fusion_args, hw_info, problem_shapes_host_ptr] = args_from_options_common<Gemm>(options, host_problem_shapes_available);

  fusion_args.beta = options.beta;
  fusion_args.beta_ptr = block_beta.get();
  fusion_args.scale_ptr = Quantize ? block_scale.get() : nullptr;

  using RasterOrderOptions = cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90GroupParams<ProblemShape>::RasterOrderOptions;
  RasterOrderOptions raster = [&] {
    switch (options.raster) {
      case Options::RasterOrderOptions::Heuristic: return RasterOrderOptions::Heuristic;
      case Options::RasterOrderOptions::AlongM: return RasterOrderOptions::AlongM;
      case Options::RasterOrderOptions::AlongN: return RasterOrderOptions::AlongN;
      default: return RasterOrderOptions::Heuristic;
    }
  }();

  Gemm::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGrouped,
    {options.groups, problem_shapes.get(), problem_shapes_host_ptr},
    {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
    {fusion_args, ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
    hw_info,
    {options.swizzle, raster}
  };

  return arguments;
}

template <>
GemmRef::Arguments
args_from_options<GemmRef>(const Options &options, bool host_problem_shapes_available)
{
  auto [fusion_args, hw_info, problem_shapes_host_ptr] = args_from_options_common<GemmRef>(options, host_problem_shapes_available);

  using RasterOrderOptions = cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90GroupParams<ProblemShape>::RasterOrderOptions;
  RasterOrderOptions raster = [&] {
    switch (options.raster) {
      case Options::RasterOrderOptions::Heuristic: return RasterOrderOptions::Heuristic;
      case Options::RasterOrderOptions::AlongM: return RasterOrderOptions::AlongM;
      case Options::RasterOrderOptions::AlongN: return RasterOrderOptions::AlongN;
      default: return RasterOrderOptions::Heuristic;
    }
  }();

  GemmRef::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGrouped,
    {options.groups, problem_shapes.get(), problem_shapes_host_ptr},
    {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get()},
    {fusion_args, nullptr, stride_C.get(), ptr_D_ref.get(), stride_D.get()},
    hw_info,
    {options.swizzle, raster}
  };

  return arguments;
}

bool verify(const Options &options) {
  bool passed = true;
  for (int32_t i = 0; i < options.groups; ++i) {
    auto const& problem_size = options.problem_sizes[i];
    auto problem_shape = make_shape(problem_size.m(), problem_size.n(), problem_size.k());
    auto [M, N, K] = problem_shape;

    bool group_passed = false;
    if constexpr (ExactMode) {
      group_passed = cutlass::reference::device::BlockCompareEqual(
        block_D_ref.get() + offset_D[i], block_D.get() + offset_D[i], M * N);
    }
    else {
      group_passed = cutlass::reference::device::BlockCompareRelativelyEqual(
        block_D_ref.get() + offset_D[i], block_D.get() + offset_D[i], M * N, ElementD(options.tolerance), ElementD(options.nonzero_floor));
    }
    if (!group_passed && options.verbose) {
      std::cout << "Group " << i << " failed" << std::endl;
      print("D reference: "); print_device_tensor(make_tensor(block_D_ref.get() + offset_D[i], make_shape(M, N, 1), stride_D_host[i]));
      print("D  computed: "); print_device_tensor(make_tensor(block_D.get()     + offset_D[i], make_shape(M, N, 1), stride_D_host[i]));
    }
    passed &= group_passed;
  }
  return passed;
}

bool run(Options &options, bool host_problem_shapes_available = true)
{
  // Apply some restrictions on Grouped GEMM options
  for (int i = 0; i < options.groups; ++i) {
    if (options.problem_sizes[i].m() != options.problem_sizes[0].m()) {
      throw std::runtime_error("Variable M problem size is not supported by verification kernel");
    }
  }
  if (options.beta != FLT_MAX && options.beta != 1.f && options.beta != 0.f) {
    throw std::runtime_error("Specifying beta != 0/1 is not supported by verification kernel");
  }

  allocate(options);
  initialize(options);

  std::cout << "Groups      : " << options.groups  << std::endl;
  std::cout << "Problem Sizes, Alpha, Beta " << std::endl;
  for (int32_t i = 0; i < options.groups; ++i) {
    std::cout << "  " << shape_string(make_tuple(options.problem_sizes[i].m(), options.problem_sizes[i].n(), options.problem_sizes[i].k()));
    std::cout << ", " << alpha_host[i] << ", " << beta_host[i] << std::endl;
  }
  std::cout << "Data types: " << problem_desc_string<ElementA, ElementB, ElementAccumulator, ElementC, ElementD>() << std::endl;
  std::cout << "Activation function: " << activation_func_string<ActivationFn>() << std::endl;
  std::cout << "Kernel schedule: " << kernel_schedule_string<KernelSchedule>() << std::endl;
  std::cout << "GEMM tile shape: " << shape_string(TileShape{}) << std::endl;
  std::cout << "Epi tile shape: " << epilogue_tile_string(EpiTileShape{}) << std::endl;
  std::cout << "Cluster shape: " << shape_string(ClusterShape{}) << std::endl;
  std::cout << "Rasterization: " << options.raster_string() << " with a maximum CTA swizzle of " << options.swizzle << std::endl;
  std::cout << "Options: Quantize = " << Quantize << ", Exact = " << ExactMode << ", BiasBroadcast = " << BiasBroadcast << std::endl;

  Runner<Gemm> gemm(args_from_options<Gemm>(options, host_problem_shapes_available));
  Runner<GemmRef> gemm_ref(args_from_options<GemmRef>(options, host_problem_shapes_available));

  auto run_fused = [&](){ gemm.run(); };
  auto run_ref_gemm = [&](){ gemm_ref.run(); };
  auto run_activation = [&](){ 
    do_activation<ActivationFn>(
      block_D_ref.get(),
      block_D_ref_gemm.get(),
      Quantize ? block_scale.get() : static_cast<ElementScalar const*>(nullptr),
      options.beta != 0.f ? block_C.get() : static_cast<ElementC const*>(nullptr),
      BiasBroadcast,
      offset_col_D.get(),
      options.groups,
      options.problem_sizes.at(0).m(), // all problems have same M
      offset_col_D_host[options.groups],
      false);
  };
  auto run_unfused = [&](){ run_ref_gemm(); run_activation(); };

  run_fused();
  CUDA_CHECK(cudaDeviceSynchronize());

  // Correctness check
  bool passed = true;
  if (options.verify) {
    run_unfused();
    CUDA_CHECK(cudaDeviceSynchronize());

    passed = verify(options);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;
  }

  if (options.iterations > 0)
  {
    auto benchmark = [&](auto name, auto func)
    {
      BenchmarkResult result = run_benchmark(func, options.warmup, options.iterations);
      double avg_tflops = double(options.total_flops()) / result.avg_runtime_ms / 1e9; // FLOP/ms -> TFLOP/s
      printf(options.csv ? "%s,%.3f,%.0f\n" : "%20s  %20.3f  %20.0f\n",
             name, result.avg_runtime_ms, avg_tflops);
    };
    printf(options.csv ? "%s,%s,%s\n" : "%20s  %20s  %20s\n",
           "Kernel", "Runtime (ms)", "Throughput (Tflop/s)");
    benchmark("Fused", run_fused);
    benchmark("Unfused", run_unfused);
    benchmark("GEMM only", run_ref_gemm);
  }

  return passed;
}

#endif // defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.3 Toolkit to run this example
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 3)) {
    std::cerr << "This example requires CUDA 12.3 or newer.\n";
    return EXIT_SUCCESS;
  }

  try {
    Options options(AlignmentM, AlignmentN, AlignmentK);
    cutlass::CommandLine cmd(argc, args);
    options.parse(cmd);

    if (options.help) {
      options.print_usage(std::cout) << std::endl;
      return 0;
    }

    if (options.device >= 0) {
      CUDA_CHECK(cudaSetDevice(options.device));
    }
    else {
      CUDA_CHECK(cudaGetDevice(&options.device));
    }

    cudaDeviceProp props;
    CUDA_CHECK(cudaGetDeviceProperties(&props, options.device));
    if (props.major != 9 || props.minor != 0) {
      std::cerr << "This example requires a GPU of NVIDIA's Hopper Architecture (compute capability 90).\n";
      return EXIT_SUCCESS;
    }

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)
    if (!run(options, false)) {
      return EXIT_FAILURE;
    }
#endif
  }
  catch (std::exception const& e) {
    std::cerr << e.what() << std::endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
