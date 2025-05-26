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

// Referenced: 67_hopper_fp8_warp_specialized_gemm_with_blockwise_scaling

/*! \file
    \brief Blocked scale Ampere FP8 GEMM example using CUTLASS 3.0 APIs for NVIDIA Ampere Lovelace architecture.

    This example demonstrate a grouped scaled FP8 GEMM using the new CUTLASS 3.0.
    APIs on NVIDIA Ampere architecture. New features that will be showcased in this example are as follows:

    Examples:
      $ ./examples/85_ada_ampere_gemm_with_blockwise_scaling/85d_ampere_int8_gemm_with_blockwise_scaling_cute  \
        --m=2816 --n=3072 --k=16384
*/

#include <iostream>

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
#include "cutlass/epilogue/thread/activation.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/gett.hpp"

#include "helper.h"

using namespace cute;

template <typename ArchTag, typename Element, int BLK_M, int BLK_N, int BLK_K, int PipelineStages = 3, int WARP_M = 2, int WARP_N = 2>
struct SM8x_Byte_Gemm_Traits {
  static constexpr int MMA_WARP_M = WARP_M * 16;
  static constexpr int MMA_WARP_N = WARP_N * 16;
  static constexpr int MMA_WARP_K = 32;
  static constexpr int NUM_WARPS = WARP_M * WARP_N;
  static constexpr int NUM_THREADS = NUM_WARPS * 32;
  static constexpr int ELEMS_PER_COPY = sizeof(uint128_t) / sizeof(Element);
  static constexpr int THREADS_PER_ROW = BLK_K / ELEMS_PER_COPY;

  static_assert(
    !(std::is_same<Element, cutlass::float_e4m3_t>::value &&
      !std::is_same<ArchTag, cutlass::arch::Sm89>::value),
    "cutlass::float_e4m3_t is only supported on cutlass::arch::Sm89."
  );

  using MmaAtom = cute::conditional_t<cute::is_same_v<Element, cutlass::float_e4m3_t>,
    MMA_Atom<SM89_16x8x32_F32E4M3E4M3F32_TN>,
    MMA_Atom<SM80_16x8x32_S32S8S8S32_TN>>;

  using TileShape = Shape<Int<BLK_M>, Int<BLK_N>, Int<BLK_K>>;              // Threadblock-level tile size
  using ClusterShape  = Shape<_1,_1,_1>;                                    // Shape of the threadblocks in a cluster
  // This code section describes the MMA op and the tile size a warp will compute
  using TiledMma = TiledMMA<
    MmaAtom,
    Layout<Shape<Int<WARP_M>, Int<WARP_N>, _1>>, // WARP_M x WARP_N x 1 thread group
    Tile<Int<MMA_WARP_M>, Int<MMA_WARP_N>, Int<MMA_WARP_K>>>;

  using SmemLayoutAtom = decltype(composition(
      Swizzle<2,4,3>{},
      Layout<Shape <_8, Int<BLK_K>>,
              Stride<Int<BLK_K>, _1>>{}));
  using SmemLayoutAtomA = SmemLayoutAtom;
  using SmemLayoutAtomB = SmemLayoutAtom;

  using GmemTiledCopy = decltype(make_tiled_copy(
    Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, Element>{},
    Layout<Shape <Int<NUM_THREADS / THREADS_PER_ROW>, Int<THREADS_PER_ROW>>,
           Stride<Int<THREADS_PER_ROW>, _1>>{},
    Layout<Shape<_1,Int<ELEMS_PER_COPY>>>{}));
  using GmemTiledCopyA = GmemTiledCopy;
  using GmemTiledCopyB = GmemTiledCopy;

  using SmemCopyAtomA = Copy_Atom<SM75_U32x4_LDSM_N, Element>;
  using SmemCopyAtomB = Copy_Atom<SM75_U32x4_LDSM_N, Element>;
};

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using         ElementA    = int8_t;                                         // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand

// B matrix configuration
using         ElementB    = int8_t;                                         // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand

// C matrix configuration
using         ElementC    = int;                                            // Element type for C and D matrix operands
using         LayoutC     = cutlass::layout::ColumnMajor;                   // Layout type for C and D matrix operands

// D matrix configuration
using         ElementD    = float;
using         LayoutD     = LayoutC;
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;

using ArchTag       = cutlass::arch::Sm89;                          // Tag indicating the minimum SM that supports the intended feature

//
// Assembling the CollectiveMainloop type
//

// Number of pipelines you want to use
// 6: (64*128 + 128*128 + 64 + 1) * 6 = 147846 < 163840 (SM80 Shared Memory Size)
// 4: (128*128 + 128*128 + 128 + 1) * 4 = 131588 < 163840 (SM80 Shared Memory Size)
// 4: (64*128 + 128*128 + 64 + 1) * 4 = 98564 < 102400 (SM89 Shared Memory Size)
// 3: (128*128 + 128*128 + 128 + 1) * 3 = 98691 < 102400 (SM89 Shared Memory Size)
constexpr int PipelineStages = 4;
constexpr int BLK_M = 64;
constexpr int BLK_N = 128;
constexpr int BLK_K = 128;
using GemmTrait = SM8x_Byte_Gemm_Traits<ArchTag, ElementA, BLK_M, BLK_N, BLK_K, PipelineStages>;
using TileShape = GemmTrait::TileShape;
using DispatchPolicy = cutlass::gemm::MainloopSm80CpAsyncBlockScaling<PipelineStages, GemmTrait::ClusterShape>;

using ScaleConfig = decltype(cutlass::detail::sm90_trivial_blockwise_scale_config(TileShape{}));
using LayoutSFA     = decltype(ScaleConfig::deduce_layoutSFA());    // Layout type for SFA matrix operand
using LayoutSFB     = decltype(ScaleConfig::deduce_layoutSFB());    // Layout type for SFB matrix operand

// Mainloop
using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
        DispatchPolicy, TileShape,
        ElementA,
        cute::tuple<cutlass::detail::TagToStrideA_t<LayoutA>, LayoutSFA>,
        ElementB,
        cute::tuple<cutlass::detail::TagToStrideB_t<LayoutB>, LayoutSFB>,
        GemmTrait::TiledMma,
        GemmTrait::GmemTiledCopyA, GemmTrait::SmemLayoutAtomA, GemmTrait::SmemCopyAtomA, cute::identity,  // A
        GemmTrait::GmemTiledCopyB, GemmTrait::SmemLayoutAtomB, GemmTrait::SmemCopyAtomB, cute::identity   // B
>;

using ElementAccumulator  = typename CollectiveMainloop::ElementAccumulator;    // Element type for internal accumulation
using ElementBlockScale   = typename CollectiveMainloop::ElementBlockScale;     // Element type for blockscaling during accumulation

//
// Assembling the Collective Epilogue Type
//

using CollectiveEpilogue = cutlass::epilogue::collective::DefaultEpilogue<
        ElementC,
        cutlass::detail::TagToStrideC_t<LayoutC>,
        cutlass::detail::TagToStrideC_t<LayoutD>,
        cutlass::epilogue::thread::LinearCombination<
          ElementD,
          AlignmentD,
          ElementAccumulator,
          ElementD,
          cutlass::epilogue::thread::ScaleType::Default,
          cutlass::FloatRoundStyle::round_to_nearest,
          ElementC>,                                                            // Provide if ElementD differs from ElementC
        cutlass::gemm::EpilogueDefault>;
//
// Assembling the GemmKernel
//

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,
    CollectiveMainloop,
    CollectiveEpilogue>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Extract information from Gemm kernel.
using EpilogueOutputOp  = typename Gemm::EpilogueOutputOp;
using ElementScalar     = typename EpilogueOutputOp::ElementScalar;

using StrideA = typename Gemm::GemmKernel::StrideA;
using StrideB = typename Gemm::GemmKernel::StrideB;
using StrideC = typename Gemm::GemmKernel::StrideC;
using StrideD = typename Gemm::GemmKernel::StrideD;

static_assert(cute::is_same_v<ElementAccumulator, ElementBlockScale>,
             "ElementAccumulator and ElementBlockScale should be same datatype");

/// Initialization
StrideA stride_A;
StrideB stride_B;
StrideC stride_C;
StrideD stride_D;
LayoutSFA layout_SFA;
LayoutSFB layout_SFB;
uint64_t seed;

using LayoutScalar = cutlass::layout::PackedVectorLayout;

cutlass::HostTensor<ElementA  , LayoutA  > tensor_A;
cutlass::HostTensor<ElementB  , LayoutB  > tensor_B;
cutlass::HostTensor<ElementC  , LayoutC  > tensor_C;
cutlass::HostTensor<ElementD  , LayoutD  > tensor_D;
cutlass::HostTensor<ElementBlockScale, LayoutScalar> blockscale_tensor_A;
cutlass::HostTensor<ElementBlockScale, LayoutScalar> blockscale_tensor_B;
cutlass::HostTensor<ElementD  , LayoutD  > tensor_ref_D;

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help = false;
  bool verify = true;

  float alpha = 1.f, beta = 0.f;
  int iterations = 1000;
  int warmup = 1000;
  int m = 1024, n = 512, k = 1024, l = 1;
  float epsilon = 0.02f;
  float non_zero_floor = 1.f;

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("l", l);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("warmup", warmup);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("verify", verify);
    cmd.get_cmd_line_argument("epsilon", epsilon);
    cmd.get_cmd_line_argument("non-zero-floor", non_zero_floor);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "85d_ampere_int8_gemm_with_blockwise_scaling_cute\n\n"
      << "  Ampere INT8 GEMM using CUTLASS 3.0 API with Blockwise Scaling.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the l extent (batch) of the GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n"
      << "  --verify=<bool>             Verify the results.\n\n"
      << "  --epsilon=<float>           The epsilon value for comparing the results.\n\n"
      << "  --non-zero-floor=<float>    The none zero floor for comparing the results.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "85d_ampere_int8_gemm_with_blockwise_scaling_cute" << " --m=1024 --n=512 --k=1024 --alpha=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * m * n * k;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

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

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <typename Element, typename Layout>
bool initialize_tensor(
  cutlass::TensorView<Element, Layout> view,
  cutlass::Distribution::Kind dist_kind,
  uint64_t seed) {

  if (dist_kind == cutlass::Distribution::Uniform) {

    double scope_max, scope_min;
    int bits_input = cutlass::sizeof_bits<Element>::value;
    int bits_output = cutlass::sizeof_bits<Element>::value;

    if (bits_input == 1) {
      scope_max = 2;
      scope_min = 0;
    } else if (bits_input <= 8) {
      scope_max = 2;
      scope_min = -2;
    } else if (bits_output == 16) {
      scope_max = 5;
      scope_min = -5;
    } else {
      scope_max = 8;
      scope_min = -8;
    }

    cutlass::reference::host::TensorFillRandomUniform(
      view, seed, scope_max, scope_min, bits_input);
  }
  else if (dist_kind == cutlass::Distribution::AllZeros) {
    cutlass::reference::host::TensorFill(view);
  }
  else if (dist_kind == cutlass::Distribution::Identity) {

    cutlass::reference::host::TensorFillIdentity(view);
  }
  else if (dist_kind == cutlass::Distribution::Gaussian) {

    cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
  }
  else if (dist_kind == cutlass::Distribution::Sequential) {
    cutlass::reference::host::BlockFillSequential(view.data(), view.capacity());
  }
  else {
    throw std::runtime_error("Not implementated.");
  }

  return true;
}

/// Helper to initialize a block of device data (scale_tensors)
template <typename Element, typename Layout>
bool initialize_scale_tensor(
  cutlass::TensorView<Element, Layout> view,
  cutlass::Distribution::Kind dist_kind,
  uint64_t seed) {

  if (dist_kind == cutlass::Distribution::Uniform) {

    double scope_max, scope_min;

    scope_min = -1;
    scope_max = 1;

    cutlass::reference::host::TensorFillRandomUniform(
      view, seed, scope_max, scope_min);
  }
  else if (dist_kind == cutlass::Distribution::AllZeros) {
    cutlass::reference::host::TensorFill(view);
  }
  else if (dist_kind == cutlass::Distribution::Identity) {

    cutlass::reference::host::TensorFillIdentity(view);
  }
  else if (dist_kind == cutlass::Distribution::Gaussian) {

    cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
  }
  else if (dist_kind == cutlass::Distribution::Sequential) {
    cutlass::reference::host::BlockFillSequential(view.data(), view.capacity());
  }
  else {
    throw std::runtime_error("Not implementated.");
  }

  return true;
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {

  assert(options.m % CollectiveMainloop::ScaleGranularityM == 0);
  assert(options.n % CollectiveMainloop::ScaleGranularityN == 0);

  stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(options.m, options.k, options.l));
  stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(options.n, options.k, options.l));
  stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(options.m, options.n, options.l));
  stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(options.m, options.n, options.l));
  layout_SFA = ScaleConfig::tile_atom_to_shape_SFA(make_shape(options.m, options.n, options.k, options.l));
  layout_SFB = ScaleConfig::tile_atom_to_shape_SFB(make_shape(options.m, options.n, options.k, options.l));


  auto a_coord = cutlass::make_Coord(options.m * options.l, options.k);
  auto c_coord = cutlass::make_Coord(options.m * options.l, options.n);
  auto b_coord = cutlass::make_Coord(options.k, options.n * options.l);
  auto groupscale_a_coord = cutlass::make_Coord(size(filter_zeros(layout_SFA)));
  auto groupscale_b_coord = cutlass::make_Coord(size(filter_zeros(layout_SFB)));

  tensor_A.resize(a_coord);
  tensor_B.resize(b_coord);
  blockscale_tensor_A.resize(groupscale_a_coord);
  blockscale_tensor_B.resize(groupscale_b_coord);
  tensor_C.resize(c_coord);
  tensor_D.resize(c_coord);
  tensor_ref_D.resize(c_coord);

  cutlass::Distribution::Kind dist_A = cutlass::Distribution::Uniform;
  cutlass::Distribution::Kind dist_B = cutlass::Distribution::Uniform;
  cutlass::Distribution::Kind dist_C = cutlass::Distribution::Identity;
  cutlass::Distribution::Kind dist_scaleA = cutlass::Distribution::Uniform;
  cutlass::Distribution::Kind dist_scaleB = cutlass::Distribution::Uniform;

  initialize_tensor(tensor_A.host_view(), dist_A, seed + 2022);
  initialize_tensor(tensor_B.host_view(), dist_B, seed + 2023);
  initialize_tensor(tensor_C.host_view(), dist_C, seed + 2024);
  initialize_scale_tensor(blockscale_tensor_A.host_view(), dist_scaleA, seed + 2025);
  initialize_scale_tensor(blockscale_tensor_B.host_view(), dist_scaleB, seed + 2026);

#if 0 // Dump blockscaled tensors
  std::cout << "blockscale_tensor_A: " << groupscale_a_coord << std::endl;
  std::cout << blockscale_tensor_A.host_view() << "\n";
  std::cout << "blockscale_tensor_B: " << groupscale_b_coord << std::endl;
  std::cout << blockscale_tensor_B.host_view() << "\n";
#endif

  // Print group scaling tensors on the host side.
  tensor_A.sync_device();
  tensor_B.sync_device();
  tensor_C.sync_device();
  tensor_D.sync_device();
  blockscale_tensor_A.sync_device();
  blockscale_tensor_B.sync_device();
}

/// Populates a Gemm::Arguments structure from the given commandline options
template<typename GemmArguments>
GemmArguments args_from_options(const Options &options)
{
  GemmArguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, options.l},
    {tensor_A.device_data(),
     stride_A,
     tensor_B.device_data(),
     stride_B,
     blockscale_tensor_A.device_data(),
     layout_SFA,
     blockscale_tensor_B.device_data(),
     layout_SFB
     },
    {
      {}, // epilogue.thread
      tensor_C.device_data(), stride_C,
      tensor_D.device_data(), stride_D
    }
  };

  auto &fusion_args = arguments.epilogue.thread;

  fusion_args.alpha = CollectiveEpilogue::ThreadEpilogueOp::ElementCompute(options.alpha);
  fusion_args.beta = CollectiveEpilogue::ThreadEpilogueOp::ElementCompute(options.beta);

  return arguments;
}

/// Don't know why the compiler does not like verify() being templated...
bool verify(const Options &options) {
  //
  // Compute reference output
  //

  // Create instantiation for device reference gemm kernel
  auto A = cute::make_tensor(tensor_A.host_data(),
                             cute::make_layout(
                                cute::make_shape(options.m, options.k, options.l),
                                stride_A
                              )
                            );
  auto B = cute::make_tensor(tensor_B.host_data(),
                             cute::make_layout(
                               cute::make_shape(options.n, options.k, options.l),
                               stride_B
                              )
                            );
  auto C = cute::make_tensor(tensor_C.host_data(),
                             cute::make_layout(
                                cute::make_shape(options.m, options.n, options.l),
                                stride_C
                              )
                            );
  auto D = cute::make_tensor(tensor_ref_D.host_data(),
                             cute::make_layout(
                                cute::make_shape(options.m, options.n, options.l),
                                stride_D
                              )
                            );

  auto SFA = cute::make_tensor(blockscale_tensor_A.host_data(), layout_SFA);
  auto SFB = cute::make_tensor(blockscale_tensor_B.host_data(), layout_SFB);

  using unused_t = decltype(D);

  cutlass::reference::host::GettBlockScalingMainloopParams<
      CollectiveMainloop::ElementAccumulator,
      decltype(A),
      decltype(SFA),
      decltype(B),
      decltype(SFB)
    > mainloop_params{A, SFA, B, SFB};

  cutlass::reference::host::GettEpilogueParams<
      CollectiveEpilogue::ThreadEpilogueOp::ElementCompute,
      CollectiveEpilogue::ThreadEpilogueOp::ElementCompute,
      CollectiveEpilogue::ThreadEpilogueOp::ElementAccumulator,
      CollectiveEpilogue::ThreadEpilogueOp::ElementCompute,
      decltype(C),
      decltype(D),
      unused_t, // bias
      unused_t, // aux
      unused_t, // valpha
      unused_t  // vbeta
  > epilogue_params;

  epilogue_params.C = C;
  epilogue_params.D = D;
  epilogue_params.alpha = CollectiveEpilogue::ThreadEpilogueOp::ElementCompute(options.alpha);
  epilogue_params.beta = CollectiveEpilogue::ThreadEpilogueOp::ElementCompute(options.beta);

  // get reference result
  cutlass::reference::host::Gemm3x(mainloop_params, epilogue_params);

  // compare_reference
  bool passed = true;
  tensor_D.sync_host();
  passed &= cutlass::reference::host::TensorRelativelyEquals(tensor_D.host_view(), tensor_ref_D.host_view(), ElementD(options.epsilon), ElementD(options.non_zero_floor));
  double mse = cutlass::reference::host::TensorMSE(tensor_D.host_view(), tensor_ref_D.host_view());
  double mre = cutlass::reference::host::TensorMRE(tensor_D.host_view(), tensor_ref_D.host_view());
  double max_error = cutlass::reference::host::TensorGreatestError(tensor_D.host_view(), tensor_ref_D.host_view());
  std::cout << "  Result MSE: " << mse << ", MRE: " << mre << ", greatest error: " << max_error << std::endl;

#if 0
  std::cout << "tensor_ref_D.host_view() {" << std::endl
            << tensor_ref_D.host_view() << std::endl
            << "}"  << std::endl;
  std::cout << "tensor_D.host_view() {" << std::endl
            << tensor_D.host_view() << std::endl
            << "}"  << std::endl;
#endif

  return passed;
}


/// Execute a given example GEMM computation
int run(Options &options) {

  bool skip = false;
  std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
  std::cout << "  Tile shape (M, N, K): " << size<0>(TileShape{}) << ", " << size<1>(TileShape{}) << ", " << size<2>(TileShape{}) << std::endl;
  std::cout << "  ScaleGranularityM: " << CollectiveMainloop::ScaleGranularityM << " (ScaleMsPerTile: " << CollectiveMainloop::ScaleMsPerTile << ")" << std::endl;
  std::cout << "  ScaleGranularityN: " << CollectiveMainloop::ScaleGranularityN << " (ScaleNsPerTile: " << CollectiveMainloop::ScaleNsPerTile << ")" << std::endl;


  if (options.m < CollectiveMainloop::ScaleGranularityM) {
    std::cout << "  Skippig (m size: " << options.m << " less than ScaleGranularityM: " << CollectiveMainloop::ScaleGranularityM << "):" << std::endl;
    skip = true;
  }

  if (options.n < CollectiveMainloop::ScaleGranularityN) {
    std::cout << "  Skippig (n size: " << options.n << " less than ScaleGranularityN: " << CollectiveMainloop::ScaleGranularityN << "):" << std::endl;
    skip = true;
  }

  if (options.k < size<2>(TileShape{})) {
    std::cout << "  Skippig (k size: " << options.k << " less than TileShape[2]: " << size<2>(TileShape{}) << "):" << std::endl;
    skip = true;
  }

  if (!skip) std::cout << "  Running... " << std::endl;
  else return -1;

  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options<typename Gemm::Arguments>(options);

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
  if (options.verify) {
    result.passed = verify(options);

    std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;
  }
  else {
    result.passed = true;
  }

  // Run profiling loop
  if (options.iterations > 0)
  {
    GpuTimer timer;
    for (int iter = 0; iter < options.warmup + options.iterations; ++iter) {
      if (iter == options.warmup)
        timer.start();
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

    // Compute average runtime and GFLOPs.
    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS: " << result.gflops << std::endl;
    fflush(stdout);
  }

  return result.passed;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.0 Toolkit to run this example
  // and must have compute capability at least 90.
  if (__CUDACC_VER_MAJOR__ < 12) {
    std::cerr << "This example requires CUDA 12 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major < 8) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Ampere Architecture or "
      << "later (compute capability 80 or greater).\n";
    return 0;
  }
  //
  // Parse options
  //

  Options options;
  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  //
  // Evaluate CUTLASS kernels
  //

  bool passed = true;
  passed = run(options);
  if (!passed)
    return -1;

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
