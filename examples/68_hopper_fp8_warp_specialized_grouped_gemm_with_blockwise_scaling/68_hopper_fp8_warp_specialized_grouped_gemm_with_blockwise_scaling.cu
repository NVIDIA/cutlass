/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Grouped scale Hopper FP8 Grouped GEMM example using CUTLASS 3.0 APIs for NVIDIA Hopper architecture
    This example demonstrates a grouped scaled FP8 Grouped GEMM using the new CUTLASS 3.0.
    APIs on NVIDIA Hopper architecture. New features that will be showcased in this example are as follows:
    1. NVIDIA Hopper architecture introduces a new series of tensor core instructions (GMMA)
    which are more efficient than the Ampere tensor core instructions.
    2. NVIDIA Hopper architecture includes new Tensor Memory Accelerator (TMA) unit to transfer large
    blocks of data efficiently between global memory and shared memory. TMA also supports asynchronous
    copies between thread blocks in a cluster. This example also showcases on-the-fly modification of TMA
    descriptors to move between groups/problem_count (represented by groups).
    3. This example uses the Warp Specialized kernel design (see /media/docs/efficient_gemm.md for details).
    4. A simple way to tune the CTA rasterization direction and swizzle pattern of Hopper kernels. Both the
    CTA rasterization direction and swizzle pattern impact cross-CTA locality of accesses. By tuning we can
    improve performance.
    Examples:
      $ ./examples/68_hopper_fp8_warp_specialized_grouped_gemm_with_blockwise_scaling/68_hopper_fp8_warp_specialized_grouped_gemm_with_blockwise_scaling  \
        --m=2816 --n=3072 --k=16384 --save_aux=false --save_amax=false \
        --raster=h --swizzle=2 --benchmark=./test_benchmark.txt

      Where the test_benchmark.txt may look as such:
        0 256x512x128
        1 256x512x512
        2 512x256x128
        3 256x256x128
        4 256x512x1024
        5 1024x512x128 and so on
*/

#include <iostream>
#include <optional>
#include <fstream>
#include <sstream>
#include <vector>
#include <cfloat>

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/device/tensor_fill.h"

// Includes from examples directory
#include "helper.h"
#include "hopper_fp8_commandline.hpp"
#include "reference/host/gemm_with_groupwise_scaling.h"

using namespace cute;

using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) && defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using         ElementA    = cutlass::float_e4m3_t;                          // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;    // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = cutlass::float_e4m3_t;                          // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;    // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C matrix configuration
using         ElementC    = cutlass::float_e4m3_t;                          // Element type for C and D matrix operands
using         LayoutC     = cutlass::layout::ColumnMajor;                   // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

// D matrix configuration
using         ElementD    = ElementC;
using         LayoutD     = LayoutC;
constexpr int AlignmentD  = AlignmentC;

// Core kernel configurations
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ElementBlockScale   = float;                                          // Element type for blockscaling during accumulation
using ElementCompute      = float;                                          // Element type for epilogue computation

using TileShape_  = Shape<_128,_128,_128>;  // This one is just to make the compiler happy with verify()...

// ScaleGranularity{M,N}: number of {rows in A}/{columns in B} that share the same scaling factor
// Given TileShape = Shape<_128,_128,_128>:
//   ScaleGranularityM == 128 and ScaleGranularityN == 128 --> 2Dx2D (the shape of the scaling factor)
//   ScaleGranularityM == 1   and ScaleGranularityN == 128 --> 1Dx2D scaling
//   ScaleGranularityM == 128 and ScaleGranularityN == 1   --> 2Dx1D scaling
//   ScaleGranularityM == 1   and ScaleGranularityN == 1   --> 1Dx1D scaling
template <int ScaleGranularityM_, int ScaleGranularityN_>
struct GroupScaleConfig {
  using ArchTag       = cutlass::arch::Sm90;                          // Tag indicating the minimum SM that supports the intended feature
  using OperatorClass = cutlass::arch::OpClassTensorOp;               // Operator class tag
  using TileShape     = Shape<_128,_128,_128>;                        // Threadblock-level tile size
  using ClusterShape  = Shape<_1,_2,_1>;                              // Shape of the threadblocks in a cluster

  static constexpr int ScaleGranularityM = ScaleGranularityM_;
  static constexpr int ScaleGranularityN = ScaleGranularityN_;
  static constexpr int ScaleMsPerTile = size<0>(TileShape{}) / ScaleGranularityM;
  static constexpr int ScaleNsPerTile = size<1>(TileShape{}) / ScaleGranularityN;

  static_assert(size<0>(TileShape{}) == ScaleGranularityM * ScaleMsPerTile,
              "FP8 scaling granularity must evenly divide tile shape along M.");
  static_assert(size<1>(TileShape{}) == ScaleGranularityN * ScaleNsPerTile,
              "FP8 scaling granularity must evenly divide tile shape along N.");

  using KernelSchedule    = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperativeFP8BlockScaledAccum<ScaleGranularityM_, ScaleGranularityN_>;
  using EpilogueSchedule  = cutlass::epilogue::PtrArrayTmaWarpSpecializedCooperative;
  using EpilogueTileType  = cutlass::epilogue::collective::EpilogueTileAuto;
  using FusionOperation   = cutlass::epilogue::fusion::LinearCombination<ElementC, ElementAccumulator>;
};

using GroupScale1D1DConfig = GroupScaleConfig<                    1,                     1>;
using GroupScale1D2DConfig = GroupScaleConfig<                    1, size<1>(TileShape_{})>;
using GroupScale2D1DConfig = GroupScaleConfig<size<0>(TileShape_{}),                     1>;
using GroupScale2D2DConfig = GroupScaleConfig<size<0>(TileShape_{}), size<1>(TileShape_{})>;

template <typename ScheduleConfig>
struct GroupScaleGemm {
  using ArchTag           = typename ScheduleConfig::ArchTag;
  using OperatorClass     = typename ScheduleConfig::OperatorClass;
  using TileShape         = typename ScheduleConfig::TileShape;
  using ClusterShape      = typename ScheduleConfig::ClusterShape;
  using KernelSchedule    = typename ScheduleConfig::KernelSchedule;
  using EpilogueSchedule  = typename ScheduleConfig::EpilogueSchedule;
  using EpilogueTileType  = typename ScheduleConfig::EpilogueTileType;
  using FusionOperation   = typename ScheduleConfig::FusionOperation;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    TileShape, ClusterShape,
    EpilogueTileType,
    ElementAccumulator, ElementCompute,
    ElementC, LayoutC *, AlignmentC,
    ElementD, LayoutD *, AlignmentD,
    EpilogueSchedule,
    FusionOperation
  >::CollectiveOp;

  using CollectiveMainloopWithGroupWiseScaling = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA *, AlignmentA,
    ElementB, LayoutB *, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      ProblemShape,
      CollectiveMainloopWithGroupWiseScaling,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

using GroupScale1D1DGemm = GroupScaleGemm<GroupScale1D1DConfig>;
using GroupScale1D2DGemm = GroupScaleGemm<GroupScale1D2DConfig>;
using GroupScale2D1DGemm = GroupScaleGemm<GroupScale2D1DConfig>;
using GroupScale2D2DGemm = GroupScaleGemm<GroupScale2D2DConfig>;

// Extract information from Gemm kernel.
using EpilogueOutputOp  = typename GroupScale1D1DGemm::Gemm::EpilogueOutputOp;
using ElementScalar     = typename EpilogueOutputOp::ElementScalar;
using ActivationFunctor = typename EpilogueOutputOp::ActivationFn;

using StrideA = typename GroupScale1D1DGemm::Gemm::GemmKernel::InternalStrideA;
using StrideB = typename GroupScale1D1DGemm::Gemm::GemmKernel::InternalStrideB;
using StrideC = typename GroupScale1D1DGemm::Gemm::GemmKernel::InternalStrideC;
using StrideD = typename GroupScale1D1DGemm::Gemm::GemmKernel::InternalStrideD;

static_assert(cute::is_same_v<ElementAccumulator, ElementBlockScale>,
             "ElementAccumulator and ElementBlockScale should be same datatype");

/// Initialization

cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes;

std::vector<int64_t> offset_A;
std::vector<int64_t> offset_B;
std::vector<int64_t> offset_C;
std::vector<int64_t> offset_D;
std::vector<int64_t> offset_blockscale_A;
std::vector<int64_t> offset_blockscale_B;

std::vector<StrideA> stride_A_host;
std::vector<StrideB> stride_B_host;
std::vector<StrideC> stride_C_host;
std::vector<StrideD> stride_D_host;

std::vector<ElementAccumulator> alpha_host;
std::vector<ElementAccumulator> beta_host;

uint64_t seed;

cutlass::DeviceAllocation<ElementA> block_A;
cutlass::DeviceAllocation<ElementB> block_B;
cutlass::DeviceAllocation<ElementC> block_C;
cutlass::DeviceAllocation<ElementD> block_D;
cutlass::DeviceAllocation<ElementBlockScale> blockscale_block_A;
cutlass::DeviceAllocation<ElementBlockScale> blockscale_block_B;

cutlass::DeviceAllocation<const ElementA *> ptr_A;
cutlass::DeviceAllocation<const ElementB *> ptr_B;
cutlass::DeviceAllocation<const ElementC *> ptr_C;
cutlass::DeviceAllocation<ElementD *> ptr_D;
cutlass::DeviceAllocation<ElementD *> ptr_ref_D;
cutlass::DeviceAllocation<const ElementBlockScale *> ptr_blockscale_A;
cutlass::DeviceAllocation<const ElementBlockScale *> ptr_blockscale_B;

cutlass::DeviceAllocation<StrideA> stride_A;
cutlass::DeviceAllocation<StrideB> stride_B;
cutlass::DeviceAllocation<StrideC> stride_C;
cutlass::DeviceAllocation<StrideD> stride_D;

cutlass::DeviceAllocation<ElementAccumulator*> alpha_device;
cutlass::DeviceAllocation<ElementAccumulator*> beta_device;
cutlass::DeviceAllocation<ElementAccumulator> block_alpha;
cutlass::DeviceAllocation<ElementAccumulator> block_beta;

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) && defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED) 

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

using RasterOrderOptions = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90GroupParams<Shape<int,int,int>>::RasterOrderOptions;

/// Result structure
struct Result
{
  double avg_runtime_ms;
  double gflops;
  cutlass::Status status;
  cudaError_t error;
  bool passed;

  Result(
    double avg_runtime_ms = 0,
    double gflops = 0,
    cutlass::Status status = cutlass::Status::kSuccess,
    cudaError_t error = cudaSuccess)
  :
    avg_runtime_ms(avg_runtime_ms), gflops(gflops), status(status), error(error), passed(false)
  {}

};

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) && defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <class Element, class ScopeMin = std::nullopt_t, class ScopeMax = std::nullopt_t>
bool initialize_block(
  cutlass::DeviceAllocation<Element>& block,
  uint64_t seed=2023,
  ScopeMin scope_min = std::nullopt, ScopeMax scope_max = std::nullopt) {

  double _scope_max, _scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;
  if (bits_input == 1) {
    _scope_max = 2;
    _scope_min = 0;
  } else if (bits_input <= 8) {
    _scope_max = 2;
    _scope_min = -2;
  } else if (bits_input == 16) {
    _scope_max = 5;
    _scope_min = -5;
  } else {
    _scope_max = 8;
    _scope_min = -8;
  }
  if constexpr (!std::is_same_v<ScopeMax, std::nullopt_t>) {
    _scope_max = scope_max;
  }
  if constexpr (!std::is_same_v<ScopeMin, std::nullopt_t>) {
    _scope_min = scope_min;
  }
  cutlass::reference::device::BlockFillRandomUniform(
    block.get(), block.size(), seed, (Element) _scope_max, (Element) _scope_min, 0);

  return true;
}

/// Allocates device-side data
template <typename OptionType>
void allocate(const OptionType &options) {

  using TileShape = typename OptionType::GroupScaleConfig::TileShape;
  const int ScaleMsPerTile = OptionType::GroupScaleConfig::ScaleMsPerTile;
  const int ScaleNsPerTile = OptionType::GroupScaleConfig::ScaleNsPerTile;

  int64_t total_elements_A = 0;
  int64_t total_elements_B = 0;
  int64_t total_elements_C = 0;
  int64_t total_elements_D = 0;
  int64_t total_elements_blockscale_A = 0;
  int64_t total_elements_blockscale_B = 0;

  offset_A.clear();
  offset_B.clear();
  offset_C.clear();
  offset_D.clear();
  offset_blockscale_A.clear();
  offset_blockscale_B.clear();
  stride_A_host.clear();
  stride_B_host.clear();
  stride_C_host.clear();
  stride_D_host.clear();
  
  for (int32_t i = 0; i < options.groups; ++i) {

    auto problem = options.problem_sizes_host.at(i);
    auto M = get<0>(problem);
    auto N = get<1>(problem);
    auto K = get<2>(problem);

    auto blockscale_shape = shape(get<1>(cute::zipped_divide(cute::make_layout(problem), TileShape{})));
    auto groupscale_m = cute::get<0>(blockscale_shape) * ScaleMsPerTile; // We need to pad along M in scale tensor of A to prevent illegal memory access.
    auto groupscale_n = cute::get<1>(blockscale_shape) * ScaleNsPerTile; // We need to pad along N in scale tensor of A to prevent illegal memory access.
    auto blockscale_k = cute::get<2>(blockscale_shape);

    offset_A.push_back(total_elements_A);
    offset_B.push_back(total_elements_B);
    offset_C.push_back(total_elements_C);
    offset_D.push_back(total_elements_D);
    offset_blockscale_A.push_back(total_elements_blockscale_A);
    offset_blockscale_B.push_back(total_elements_blockscale_B);

    int64_t elements_A = M * K;
    int64_t elements_B = K * N;
    int64_t elements_C = M * N;
    int64_t elements_D = M * N;
    int64_t elements_blockscale_A = groupscale_m * blockscale_k;
    int64_t elements_blockscale_B = groupscale_n * blockscale_k;

    total_elements_A += elements_A;
    total_elements_B += elements_B;
    total_elements_C += elements_C;
    total_elements_D += elements_D;
    total_elements_blockscale_A += elements_blockscale_A;
    total_elements_blockscale_B += elements_blockscale_B;

    stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, {M, K, 1}));
    stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, {N, K, 1}));
    stride_C_host.push_back(cutlass::make_cute_packed_stride(StrideC{}, {M, N, 1}));
    stride_D_host.push_back(cutlass::make_cute_packed_stride(StrideD{}, {M, N, 1}));

  }

  block_A.reset(total_elements_A);
  block_B.reset(total_elements_B);
  block_C.reset(total_elements_C);
  block_D.reset(total_elements_D);
  block_alpha.reset(options.groups);
  block_beta.reset(options.groups);
  blockscale_block_A.reset(total_elements_blockscale_A);
  blockscale_block_B.reset(total_elements_blockscale_B);
}

/// Initialize operands to be used in the GEMM and reference GEMM
template <typename OptionType>
void initialize(const OptionType &options) {

  problem_sizes.reset(options.groups);
  problem_sizes.copy_from_host(options.problem_sizes_host.data());

  std::vector<ElementA *> ptr_A_host(options.groups);
  std::vector<ElementB *> ptr_B_host(options.groups);
  std::vector<ElementC *> ptr_C_host(options.groups);
  std::vector<ElementD *> ptr_D_host(options.groups);
  std::vector<ElementAccumulator *> ptr_alpha_host(options.groups);
  std::vector<ElementAccumulator *> ptr_beta_host(options.groups);
  std::vector<ElementBlockScale *> ptr_blockscale_A_host(options.groups);
  std::vector<ElementBlockScale *> ptr_blockscale_B_host(options.groups);

  alpha_host.clear();
  beta_host.clear();

  for (int i = 0; i < options.groups; i++) {
    ptr_A_host.at(i) = block_A.get() + offset_A.at(i);
    ptr_B_host.at(i) = block_B.get() + offset_B.at(i);
    ptr_C_host.at(i) = block_C.get() + offset_C.at(i);
    ptr_D_host.at(i) = block_D.get() + offset_D.at(i);
    ptr_blockscale_A_host.at(i) = blockscale_block_A.get() + offset_blockscale_A.at(i);
    ptr_blockscale_B_host.at(i) = blockscale_block_B.get() + offset_blockscale_B.at(i);
    alpha_host.push_back((options.alpha == FLT_MAX) ? static_cast<ElementAccumulator>((rand() % 5) + 1) : options.alpha);
    beta_host.push_back((options.beta == FLT_MAX) ? static_cast<ElementAccumulator>(rand() % 5) : options.beta);
    ptr_alpha_host.at(i) = block_alpha.get() + i;
    ptr_beta_host.at(i) = block_beta.get() + i;
  }

  ptr_A.reset(options.groups);
  ptr_A.copy_from_host(ptr_A_host.data());

  ptr_B.reset(options.groups);
  ptr_B.copy_from_host(ptr_B_host.data());

  ptr_C.reset(options.groups);
  ptr_C.copy_from_host(ptr_C_host.data());

  ptr_D.reset(options.groups);
  ptr_D.copy_from_host(ptr_D_host.data());

  ptr_blockscale_A.reset(options.groups);
  ptr_blockscale_A.copy_from_host(ptr_blockscale_A_host.data());

  ptr_blockscale_B.reset(options.groups);
  ptr_blockscale_B.copy_from_host(ptr_blockscale_B_host.data());

  stride_A.reset(options.groups);
  stride_A.copy_from_host(stride_A_host.data());

  stride_B.reset(options.groups);
  stride_B.copy_from_host(stride_B_host.data());

  stride_C.reset(options.groups);
  stride_C.copy_from_host(stride_C_host.data());

  stride_D.reset(options.groups);
  stride_D.copy_from_host(stride_D_host.data());

  alpha_device.reset(options.groups);
  alpha_device.copy_from_host(ptr_alpha_host.data());
  beta_device.reset(options.groups);
  beta_device.copy_from_host(ptr_beta_host.data());

  initialize_block(block_A, seed + 2022);
  initialize_block(block_B, seed + 2023);
  initialize_block(block_C, seed + 2024);
  initialize_block(blockscale_block_A, seed + 2025, -1, 1);
  initialize_block(blockscale_block_B, seed + 2026, -1, 1);

  block_alpha.copy_from_host(alpha_host.data());
  block_beta.copy_from_host(beta_host.data());

}

/// Populates a Gemm::Arguments structure from the given commandline options
template<typename GemmArguments, typename OptionType>
GemmArguments args_from_options(const OptionType &options, bool host_problem_shapes_available = true)
{
  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  int device_id = 0;
  cutlass::KernelHardwareInfo kernel_hw_info = cutlass::KernelHardwareInfo::make_kernel_hardware_info<typename GroupScale1D1DGemm::Gemm::GemmKernel>(device_id);

  GemmArguments arguments{
    cutlass::gemm::GemmUniversalMode::kGrouped,
    {options.groups, problem_sizes.get(), host_problem_shapes_available ? options.problem_sizes_host.data() : (decltype(options.problem_sizes_host.data())) nullptr},
    {ptr_A.get(), stride_A.get(), ptr_B.get(), stride_B.get(),
     ptr_blockscale_A.get(),
     ptr_blockscale_B.get()
    },
    {
      {}, // epilogue.thread
      ptr_C.get(), stride_C.get(),
      ptr_D.get(), stride_D.get()
    },
    kernel_hw_info
  };

  auto &fusion_args = arguments.epilogue.thread;
  if (options.alpha != FLT_MAX && options.beta != FLT_MAX) {
    // If both alpha/beta are provided (via cmd line args) and are scalar, i.e., same alpha/beta applies to all batches.
    fusion_args.alpha = options.alpha;
    fusion_args.beta = options.beta;
    fusion_args.alpha_ptr = nullptr;
    fusion_args.beta_ptr = nullptr;
    fusion_args.alpha_ptr_array = nullptr;
    fusion_args.beta_ptr_array = nullptr;
    // Single alpha and beta for all groups
    fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 0};
    fusion_args.dBeta = {cute::_0{}, cute::_0{}, 0};
  }
  else {
    // If pointers to alpha/beta are provided, i.e., alpha/beta can differ between batches/groups.
    fusion_args.alpha = 0;
    fusion_args.beta = 0;
    fusion_args.alpha_ptr = nullptr;
    fusion_args.beta_ptr = nullptr;
    fusion_args.alpha_ptr_array = alpha_device.get();
    fusion_args.beta_ptr_array = beta_device.get();
    // One alpha and beta per each group
    fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 1};
    fusion_args.dBeta = {cute::_0{}, cute::_0{}, 1};
  }

  arguments.scheduler.raster_order = options.raster;
  // The tile scheduler will swizzle up to 8 and with the nearest multiple of 2 (i.e., 1, 2, 4, and 8)
  arguments.scheduler.max_swizzle_size = options.swizzle;

  return arguments;
}

template <typename OptionType>
bool verify(const OptionType &options) {

  //
  // Compute reference output
  //

  std::vector<ElementA> block_A_host(block_A.size());
  std::vector<ElementB> block_B_host(block_B.size());
  std::vector<ElementC> block_C_host(block_C.size());
  std::vector<ElementD> block_D_host_kernel(block_D.size());
  std::vector<ElementD> block_D_host_ref(block_D.size());
  std::vector<ElementBlockScale> blockscale_block_A_host(blockscale_block_A.size());
  std::vector<ElementBlockScale> blockscale_block_B_host(blockscale_block_B.size());

  block_A.copy_to_host(block_A_host.data());
  block_B.copy_to_host(block_B_host.data());
  block_C.copy_to_host(block_C_host.data());
  block_D.copy_to_host(block_D_host_kernel.data());
  blockscale_block_A.copy_to_host(blockscale_block_A_host.data());
  blockscale_block_B.copy_to_host(blockscale_block_B_host.data());

  bool passed = true;
  for (int group_idx = 0; group_idx < options.groups; group_idx++) {
    // Group scaling tensors shapes based `ScaleGranularityM`, CTA Block (TileShape) and GEMM Problem shape
    auto [m, n, k] = options.problem_sizes_host.at(group_idx);
    auto gemm_problem_shape = cute::make_shape(m, n, k);
    auto blockscale_shape = shape(get<1>(cute::zipped_divide(cute::make_layout(gemm_problem_shape), TileShape_{})));
    auto blockscale_m = cute::get<0>(blockscale_shape);
    auto blockscale_n = cute::get<1>(blockscale_shape);
    auto blockscale_k = cute::get<2>(blockscale_shape);
    auto groupscale_m = blockscale_m * OptionType::GroupScaleConfig::ScaleMsPerTile;
    auto groupscale_n = blockscale_n * OptionType::GroupScaleConfig::ScaleNsPerTile;

    // Create instantiation for device reference gemm kernel
    auto A = cute::make_tensor(block_A_host.data() + offset_A.at(group_idx),
                              cute::make_layout(
                                  cute::make_shape(m, k, 1),
                                  stride_A_host.at(group_idx)
                                )
                              );
    auto B = cute::make_tensor(block_B_host.data() + offset_B.at(group_idx),
                              cute::make_layout(
                                cute::make_shape(n, k, 1),
                                stride_B_host.at(group_idx)
                                )
                              );
    auto C = cute::make_tensor(block_C_host.data() + offset_C.at(group_idx),
                              cute::make_layout(
                                  cute::make_shape(m, n, 1),
                                  stride_C_host.at(group_idx)
                                )
                              );
    auto D = cute::make_tensor(block_D_host_ref.data() + offset_D.at(group_idx),
                              cute::make_layout(
                                  cute::make_shape(m, n, 1),
                                  stride_D_host.at(group_idx)
                                )
                              );

    auto blockscale_A = cute::make_tensor(blockscale_block_A_host.data() + offset_blockscale_A.at(group_idx),
                                          cute::make_layout(
                                            cute::make_shape(groupscale_m, blockscale_k, 1),
                                            cute::make_stride(1, groupscale_m, groupscale_m * blockscale_k)
                                          )
                                        );
    auto blockscale_B = cute::make_tensor(blockscale_block_B_host.data() + offset_blockscale_B.at(group_idx),
                                          cute::make_layout(
                                            cute::make_shape(groupscale_n, blockscale_k, 1),
                                            cute::make_stride(1, groupscale_n, groupscale_n * blockscale_k)
                                          )
                                        );

    using unused_t = decltype(D);

    cutlass::reference::host::GettMainloopParams<
      ElementAccumulator,
      decltype(A),
      decltype(B),
      decltype(blockscale_A),
      decltype(blockscale_B),
      TileShape_
    > mainloop_params{
        A, B,                         // Operand Tensors
        blockscale_A, blockscale_B    // Groupwise scaling Tensors
    };

    cutlass::reference::host::GettEpilogueParams<
        ElementScalar,
        ElementScalar,
        ElementAccumulator,
        ElementCompute,
        decltype(C),
        decltype(D),
        unused_t, // bias
        unused_t, // Aux
        unused_t, // valpha
        unused_t, // vbeta
        ActivationFunctor
    > epilogue_params;

    epilogue_params.C = C;
    epilogue_params.D = D;
    epilogue_params.alpha = alpha_host.at(group_idx);
    epilogue_params.beta = beta_host.at(group_idx);

    // get reference result
    cutlass::reference::host::Gemm3x(mainloop_params, epilogue_params);

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    auto this_group_passed = std::equal(
      // std::execution::par_unseq,
      block_D_host_ref.data() + offset_D.at(group_idx),
      block_D_host_ref.data() + offset_D.at(group_idx) + m * n,
      block_D_host_kernel.data() + offset_D.at(group_idx)
    );
    
    passed &= this_group_passed;

#if 0
    std::cout << "Group: " << group_idx << " M: " << m << " N: " << n << " K: " << k << " Status: " << this_group_passed << std::endl;
#endif

  }

  return passed;
}

/// Execute a given example GEMM computation
template <typename Gemm, typename OptionType>
int run(OptionType &options, bool host_problem_shapes_available = true)
{
  using TileShape = typename OptionType::GroupScaleConfig::TileShape;
  const int ScaleGranularityM = OptionType::GroupScaleConfig::ScaleGranularityM;
  const int ScaleGranularityN = OptionType::GroupScaleConfig::ScaleGranularityN;
  const int ScaleMsPerTile    = OptionType::GroupScaleConfig::ScaleMsPerTile;
  const int ScaleNsPerTile    = OptionType::GroupScaleConfig::ScaleNsPerTile;

  allocate(options);
  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options<typename Gemm::Arguments>(options, host_problem_shapes_available);

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = Gemm::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check if the problem size is supported or not
  CUTLASS_CHECK(gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(gemm.run());

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  Result result;
  result.passed = verify(options);

  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

  if (!result.passed) {
   exit(-1);
  }

  // Run profiling loop
  if (options.iterations > 0)
  {
    GpuTimer timer;
    timer.start();
    for (int iter = 0; iter < options.iterations; ++iter) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

    // Compute average runtime and GFLOPs.
    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::string raster = "Heuristic";

    if (options.raster == RasterOrderOptions::AlongN) {
      raster = "Along N";
    }
    else if (options.raster == RasterOrderOptions::AlongM) {
      raster = "Along M";
    }

    std::cout << "  Problem Sizes, Alpha, Beta " << std::endl;
    for (int32_t i = 0; i < options.groups; ++i) {
      std::cout << "    " << options.problem_sizes_host.at(i);
      std::cout << ", " << alpha_host.at(i) << ", " << beta_host.at(i) << std::endl;
    }
    std::cout << "  Groups      : " << options.groups  << std::endl;
    std::cout << "  Tile shape (M, N, K): " << size<0>(TileShape{}) << ", " << size<1>(TileShape{}) << ", " << size<2>(TileShape{}) << std::endl;
    std::cout << "  ScaleGranularityM: " << ScaleGranularityM << " (ScaleMsPerTile: " << ScaleMsPerTile << ")" << std::endl;
    std::cout << "  ScaleGranularityN: " << ScaleGranularityN << " (ScaleNsPerTile: " << ScaleNsPerTile << ")" << std::endl;
    std::cout << "  Rasterization: " << raster << " with a maximum CTA swizzle of " << options.swizzle << std::endl;
    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS: " << result.gflops << std::endl;
    fflush(stdout);
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) && defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.0 Toolkit to run this example
  // and must have compute capability at least 90.
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 3)) {
    std::cerr << "This example requires CUDA 12.3 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major != 9) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Hopper Architecture or "
      << "later (compute capability 90 or greater).\n";
    return 0;
  }

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) && defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

  //
  // Parse options
  //

  Options<RasterOrderOptions, ProblemShape, GroupScale1D1DConfig> options_1d1d;
  Options<RasterOrderOptions, ProblemShape, GroupScale1D2DConfig> options_1d2d;
  Options<RasterOrderOptions, ProblemShape, GroupScale2D1DConfig> options_2d1d;
  Options<RasterOrderOptions, ProblemShape, GroupScale2D2DConfig> options_2d2d;

  options_1d1d.parse(argc, args);
  options_1d2d.parse(argc, args);
  options_2d1d.parse(argc, args);
  options_2d2d.parse(argc, args);

  if (options_1d1d.help) {
    options_1d1d.print_usage(std::cout) << std::endl;
    return 0;
  }

  //
  // Evaluate CUTLASS kernels
  //

  auto run_tests = [&] (bool host_problem_shapes_available = true) {
    std::cout << "Grouped GEMM kernel with 1D1D group scale" << std::endl;
    run<GroupScale1D1DGemm::Gemm>(options_1d1d, host_problem_shapes_available);
    std::cout << "Grouped GEMM kernel with 1D2D group scale" << std::endl;
    run<GroupScale1D2DGemm::Gemm>(options_1d2d, host_problem_shapes_available);
    std::cout << "Grouped GEMM kernel with 2D1D group scale" << std::endl;
    run<GroupScale2D1DGemm::Gemm>(options_2d1d, host_problem_shapes_available);
    std::cout << "Grouped GEMM kernel with 2D2D group scale" << std::endl;
    run<GroupScale2D2DGemm::Gemm>(options_2d2d, host_problem_shapes_available);
    std::cout << std::endl;
  };

  std::cout << "Running tests with host problem shapes:" << std::endl;
  run_tests(true);
  std::cout << "Running tests without host problem shapes:" << std::endl;
  run_tests(false);

#endif

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
