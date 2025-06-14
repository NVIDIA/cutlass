/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Hopper GEMM example with different data types using CUTLASS 3.0 APIs for NVIDIA Hopper architecture

    This example shows how to perform INT4 x BF16 GEMM and scale up the INT4 weight during dequantization.

    The narrower type always passes through the register file. Therefore, in cases where the narrower type is operand B, the collective will implicitly swap 
    A and B in the main loop. However, as a result of this collective performing implicit swaps, it does not support TMA epilogues. Consequently, it is essential to consider this when constructing the epilogue, 
    as illustrated in this example.

    Note that in this example, we explicitly swap A and B in order to use TMA epilogues. We do this since TMA epilogues are more performant on problem sizes of interest.

    As an additional optimization, we can reorder the narrow data type tensor such that elements read into register file by the same thread are contiguous in global and shared memory.
    This promotes vectorization of shared memory loads and removes additional instructions on the critical path. For example, when MMA is performed in 16-bit data type, each thread reads
    4 groups of 2 elements that are logically contiguous in the same row (refer to https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#wgmma-64n16-a for thread-value layout).
    If the narrow type is INT4 and tensor is major in K dim, only 8 bits can be read at a time, leading to extra load instructions and suboptimal utilization of shared memory throughput.
    If we reorder the data offline to place all 16 elements read by a thread contiguously in memory, a single 64-bit load is sufficient. This reordering is often feasible when the quantized
    tensor is static (e.g. weight tensor of a NN layer at inference time). This example demonstrates how such a reordering can be performed and communicated to the kernel when the options.shuffle is set to true.

    Furthermore, the conversion from {INT4, UINT4} to {FP16, BF16} can benefit from pre-shuffling the weights in the order [0,2,4,6,1,3,5,7]. This allows multiple nibbles to be efficiently extracted and up-converted
    in parallel. The reordering is enabled by defining the layout type `ValueShuffle`. Refer to the partial specializations of `NumericArrayShuffleConverter` in "include/cutlass/detail/collective/mixed_input_utils.hpp"
    for more details.

    It is expected that the scale's K dimension be scale_k = ceil_div(problem_k, group_size). 
    
    Scales are always expected to be MN major. This means the fastest changing dimension must be M if A is scaled or N if B is scaled.
    
    If A is being scaled, the scales must have shape [M, scale_k],  while if B is scaled, it must have shape [N, scale_k].

    The implementation only supports "group-wise" scales. However, we can make it work for per-column scales by setting the group's size
    equal to the gemm problem K.

    Limitations:
      1) The INT4 weights have additional encoding requirements.
      2) The scales must be MN major. That means if A is scaled, it must be column major, but if B is scaled it must be row major.
      3) The scales must have the same layout and groupsize.
      4) The groupsize must be greater or equal to the tile shape k.
      5) Currently, TMA epilogues cannot be used when the narrow type is the B operand. This limitation arises because the implementation always swaps the 
         operands to ensure that the narrow type passes through the register file, and TMA epilogues do not currently support implicit swap + transpose operations. 
         We plan to address this limitation in the future. However, we address this in the example by explicitly swapping and transposing the operands.
    
    Optimizing suggestions:
      1) Use a small tile size, since the register pressure for this GEMM (and RS GEMM in general) is high (it uses a lot of register space).

    Examples:
      
      Runs the mixed input batched gemm (with batch size 2), converting B to the type of A (mode 0)
      $ ./examples/55_hopper_mixed_dtype_gemm/55_hopper_int4_bf16_gemm --m=2048 --n=2048 --k=2048 --l=2 --mode=0

      Runs the mixed input gemm, and applies a scaling factor to B before mma (mode 1). Applies a vector of scales to the entire
      matrix (group size is the same as the gemm k dimension).
      $ ./examples/55_hopper_mixed_dtype_gemm/55_hopper_int4_bf16_gemm --m=4096 --n=5120 --k=8192 --g=8192 --mode=1
*/

#include <iostream>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/device/tensor_fill.h"
#include "cutlass/util/reference/device/tensor_compare.h"

#include "helper.h"
#include "mixed_dtype_utils.hpp"
#include "packed_scale.hpp"
#include "reorder_utils.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////
using MmaType = cutlass::bfloat16_t;
using QuantType = cutlass::int4b_t;
constexpr int TileShapeK = 128 * 8 / sizeof_bits<MmaType>::value;

// A matrix configuration
using         ElementA    = MmaType;                                        // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;    // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = QuantType;                                      // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;    // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// This example manually swaps and transposes, so keep transpose of input layouts
using LayoutA_Transpose = typename cutlass::layout::LayoutTranspose<LayoutA>::type;
using LayoutB_Transpose = typename cutlass::layout::LayoutTranspose<LayoutB>::type;

using StrideA = cutlass::detail::TagToStrideA_t<LayoutA>;
using StrideB = cutlass::detail::TagToStrideB_t<LayoutB>;

// Define the CuTe layout for reoredered quantized tensor B
// LayoutAtomQuant places values that will be read by the same thread in contiguous locations in global memory.
// It specifies the reordering within a single warp's fragment
//using ValueShuffle = Layout<_1>;                          // no value reordering
using ValueShuffle = Layout<Shape<_2,_4>, Stride<_4,_1>>; // order [0,2,4,6,1,3,5,7]
int constexpr NumShuffleAtoms = 1;
using MmaAtomShape = Layout<Shape<_1,Int<NumShuffleAtoms>>>;
using LayoutAtomQuant = decltype(compute_memory_reordering_atom<MmaType, MmaAtomShape, ValueShuffle>());
using LayoutB_Reordered = decltype(tile_to_shape(LayoutAtomQuant{}, Layout<Shape<int,int,int>, StrideB>{}));

using ElementScale = MmaType;
using ElementZero = ElementScale;
using LayoutScale = cutlass::layout::RowMajor;

// C/D matrix configuration
using         ElementC    = cutlass::half_t;                                // Element type for C and D matrix operands
using         LayoutC     = cutlass::layout::RowMajor;                      // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

// D matrix configuration
using         ElementD    = ElementC;
using         LayoutD     = LayoutC;
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;

// Core kernel configurations
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ElementCompute      = float;                                          // Element type for epilogue computation
using ArchTag             = cutlass::arch::Sm90;                            // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;                 // Operator class tag
using TileShape           = Shape<_128,_128,cute::Int<TileShapeK>>;         // Threadblock-level tile size
using ClusterShape        = Shape<_1,_1,_1>;                                // Shape of the threadblocks in a cluster
using KernelSchedule      = cutlass::gemm::KernelTmaWarpSpecializedCooperative;  // Kernel to launch based on the default setting in the Collective Builder 
using EpilogueSchedule    = cutlass::epilogue::TmaWarpSpecializedCooperative;
using EpilogueTileType    = cutlass::epilogue::collective::EpilogueTileAuto;

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    EpilogueTileType,
    ElementAccumulator, ElementAccumulator,
    // Transpose layout of D here since we use explicit swap + transpose
    // the void type for C tells the builder to allocate 0 smem for the C matrix.
    // We can enable this if beta == 0 by changing ElementC to void below.
    ElementC, typename cutlass::layout::LayoutTranspose<LayoutC>::type, AlignmentC,
    ElementD, typename cutlass::layout::LayoutTranspose<LayoutD>::type, AlignmentD,
    EpilogueSchedule // This is the only epi supporting the required swap + transpose.
  >::CollectiveOp;

// ============================================================ MIXED INPUT NO SCALES ============================================================================
// The collective will infer that the narrow type should be upcasted to the wide type.
// We swap A and B operands to the builder here
using CollectiveMainloopConvertOnly = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementB, LayoutB_Transpose, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelConvertOnly = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopConvertOnly,
    CollectiveEpilogue
>;

using GemmConvertOnly = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelConvertOnly>;

using CollectiveMainloopConvertOnlyShuffled = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementB, LayoutB_Reordered, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelConvertOnlyShuffled = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopConvertOnlyShuffled,
    CollectiveEpilogue
>;

using GemmConvertOnlyShuffled = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelConvertOnlyShuffled>;

// =========================================================== MIXED INPUT WITH SCALES ===========================================================================
// The Scale information must get paired with the operand that will be scaled. In this example, B is scaled so we make a tuple of B's information and the scale information.
using CollectiveMainloopScaleOnly = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    cute::tuple<ElementB, ElementScale>, LayoutB_Transpose, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelScaleOnly = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopScaleOnly,
    CollectiveEpilogue
>;

using GemmScaleOnly = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelScaleOnly>;

using CollectiveMainloopScaleOnlyShuffled = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    cute::tuple<ElementB, ElementScale>, LayoutB_Reordered, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelScaleOnlyShuffled = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopScaleOnlyShuffled,
    CollectiveEpilogue
>;

using GemmScaleOnlyShuffled = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelScaleOnlyShuffled>;

// =========================================================== MIXED INPUT WITH SCALES AND ZEROS ==================================================================
// We specify scale + zero elements to indicate that we require both. Scales and biases have the same format.
using CollectiveMainloopScaleWithZeroPoint = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    cute::tuple<ElementB, ElementScale, ElementZero>, LayoutB_Transpose, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelScaleWithZeroPoint = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopScaleWithZeroPoint,
    CollectiveEpilogue
>;

using GemmScaleWithZeroPoint = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelScaleWithZeroPoint>;

using CollectiveMainloopScaleWithZeroPointShuffled = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    cute::tuple<ElementB, ElementScale, ElementZero>, LayoutB_Reordered, AlignmentB,
    ElementA, LayoutA_Transpose, AlignmentA,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<
      static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))
    >,
    KernelSchedule
  >::CollectiveOp;

using GemmKernelScaleWithZeroPointShuffled = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloopScaleWithZeroPointShuffled,
    CollectiveEpilogue
>;

using GemmScaleWithZeroPointShuffled = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelScaleWithZeroPointShuffled>;
// =================================================================================================================================================================

using StrideC = typename GemmKernelScaleOnly::StrideC;
using StrideD = typename GemmKernelScaleOnly::StrideD;

using StrideC_ref = cutlass::detail::TagToStrideC_t<LayoutC>;
using StrideD_ref = cutlass::detail::TagToStrideC_t<LayoutD>;

//
// Data members
//

/// Initialization
StrideA stride_A;
StrideB stride_B;
StrideC stride_C;
StrideC_ref stride_C_ref;
StrideD stride_D;
StrideD_ref stride_D_ref;
uint64_t seed;

LayoutB_Reordered layout_B_reordered;

using StrideS = typename CollectiveMainloopScaleOnly::StrideScale;
using StrideS_ref = cutlass::detail::TagToStrideB_t<LayoutScale>;
StrideS stride_S;
StrideS_ref stride_S_ref;

cutlass::DeviceAllocation<ElementA> block_A;
cutlass::DeviceAllocation<ElementB> block_B;
cutlass::DeviceAllocation<ElementA> block_B_dq;
cutlass::DeviceAllocation<ElementScale> block_scale;
cutlass::DeviceAllocation<ElementZero> block_zero;
cutlass::DeviceAllocation<ElementC> block_C;
cutlass::DeviceAllocation<typename GemmScaleOnly::EpilogueOutputOp::ElementOutput> block_D;
cutlass::DeviceAllocation<typename GemmScaleOnly::EpilogueOutputOp::ElementOutput> block_ref_D;

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options : MixedDtypeOptions{
  bool shuffle = true;

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);
    cmd.get_cmd_line_argument("shuffle", shuffle);

    this->MixedDtypeOptions::parse(argc, args);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "55_hopper_int4_bf16_gemm\n\n"
      << "  Hopper Mixed Data Type GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   The number of independent gemm problems with mnk shape\n"
      << "  --g=<int>                   The size of each group for the scales. To broadcast a vector of scales or zeros, set the group size to K.\n"
      << "  --mode=<int>                The mode to run the gemm. 0 does (A @ B), 1 means A @ (scale * B), 2 means A @ (scale * B + zero-point).\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n"
      << "  --warmup=<int>              Number of warmup iterations to perform.\n\n"
      << "  --shuffle=<boolean>         Enable the offline layout swizzling.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "55_hopper_int4_bf16_gemm" << " --m=1024 --n=512 --k=1024 -g=1024 --l=10 --alpha=2 --mode=2 --beta=0.707 \n\n";

    return out;
  }
};

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(Options const& options) {

  auto shape_B = cute::make_shape(options.n, options.k, options.l);
  int const scale_k = (options.k + options.g - 1) / options.g;
  stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(options.m, options.k, options.l));
  stride_B = cutlass::make_cute_packed_stride(StrideB{}, shape_B);
  // Reverse stride here due to swap and transpose
  stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(options.n, options.m, options.l));
  stride_C_ref = cutlass::make_cute_packed_stride(StrideC_ref{}, cute::make_shape(options.m, options.n, options.l));
  // Reverse stride here due to swap and transpose
  stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(options.n, options.m, options.l));
  stride_D_ref = cutlass::make_cute_packed_stride(StrideD_ref{}, cute::make_shape(options.m, options.n, options.l));

  auto layout_B = make_layout(shape_B, stride_B);

  auto a_coord = cutlass::make_Coord(options.m * options.l, options.k);
  auto b_coord = cutlass::make_Coord(options.k, options.n * options.l);
  auto c_coord = cutlass::make_Coord(options.m * options.l, options.n);

  block_A.reset(a_coord.product());
  block_B.reset(b_coord.product());
  block_B_dq.reset(b_coord.product());
  block_C.reset(c_coord.product());
  block_D.reset(c_coord.product());
  block_ref_D.reset(c_coord.product());

  block_scale.reset(scale_k * options.l * options.n);
  block_zero.reset(scale_k * options.l * options.n);

  initialize_tensor(block_A, seed + 2022);
  initialize_quant_tensor(block_B, seed + 2021);
  initialize_tensor(block_C, seed + 2020);
  initialize_scale(block_scale, options);
  initialize_zero(block_zero, options);

  auto shape_scale_zero = cute::make_shape(options.n, scale_k, options.l);
  stride_S = cutlass::make_cute_packed_stride(StrideS{}, cute::make_shape(options.n, scale_k, options.l));
  stride_S_ref = cutlass::make_cute_packed_stride(StrideS_ref{}, cute::make_shape(options.n, scale_k, options.l));
  auto layout_scale_zero = make_layout(shape_scale_zero, stride_S_ref);

  dequantize_weight(block_B_dq.get(), block_B.get(), layout_B, block_scale.get(), block_zero.get(), layout_scale_zero, options.g);

  if (options.shuffle) {
    // Repeat the reorder layout atom to tile the whole tensor shape 
    layout_B_reordered = tile_to_shape(LayoutAtomQuant{}, shape_B);
    reorder_tensor(block_B.get(), layout_B, layout_B_reordered);

    print("Quantized tensor layout: ");
    print(layout_B_reordered);
    print("\n");
  }
}

/// Populates a Gemm::Arguments structure from the given commandline options
/// Swap the A and B tensors, as well as problem shapes here.
template <typename Gemm>
typename Gemm::Arguments args_from_options(Options const& options)
{
  using Args = typename Gemm::Arguments;
  auto&& dB = [&]() {
    if constexpr (cute::is_same_v<Gemm, GemmConvertOnlyShuffled> ||
                  cute::is_same_v<Gemm, GemmScaleOnlyShuffled> ||
                  cute::is_same_v<Gemm, GemmScaleWithZeroPointShuffled>) {
      // offline swizzling is enabled.
      return layout_B_reordered;
    }
    else {
      return stride_B;
    }
  }();
  if (options.mode == MixedDtypeGemmMode::ConvertOnly) {
    return Args {
      cutlass::gemm::GemmUniversalMode::kGemm,
      {options.n, options.m, options.k, options.l},
      {block_B.get(), dB, block_A.get(), stride_A},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D}
    };
  } 
  else if (options.mode == MixedDtypeGemmMode::ScaleOnly) {
    return Args {
      cutlass::gemm::GemmUniversalMode::kGemm,
      {options.n, options.m, options.k, options.l},
      {block_B.get(), dB, block_A.get(), stride_A, block_scale.get(), stride_S, options.g},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D}
    };
  } 
  else if (options.mode == MixedDtypeGemmMode::ScaleWithZeroPoint) {
    return Args {
      cutlass::gemm::GemmUniversalMode::kGemm,
      {options.n, options.m, options.k, options.l},
      {block_B.get(), dB, block_A.get(), stride_A, block_scale.get(), stride_S, options.g, block_zero.get()},
      {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D}
    };
  } else {
    std::cerr << "Invalid mode " << options.mode << ". Must be 0, 1 or 2." << std::endl;
    exit(-1);
  }
}

bool verify(Options const& options) {
  //
  // Compute reference output
  //

  using CollectiveMainloopRef = typename cutlass::gemm::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      MmaType, LayoutA, AlignmentA,
      MmaType, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::collective::KernelScheduleAuto
    >::CollectiveOp;

  using CollectiveEpilogueRef = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementAccumulator,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::NoSmemWarpSpecialized
    >::CollectiveOp;

  using GemmKernelRef = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>, // Indicates ProblemShape
      CollectiveMainloopRef,
      CollectiveEpilogueRef
  >;

  using GemmRef = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelRef>;

  typename GemmRef::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, options.l},
    {block_A.get(), stride_A, block_B_dq.get(), stride_B},
    {{options.alpha, options.beta}, block_C.get(), stride_C_ref, block_ref_D.get(), stride_D_ref}
  };

  // Run the gemm where the scaling is performed outside of the kernel.
  GemmRef gemm_ref;
  size_t workspace_size = GemmRef::get_workspace_size(arguments);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);
  CUTLASS_CHECK(gemm_ref.can_implement(arguments));
  CUTLASS_CHECK(gemm_ref.initialize(arguments, workspace.get()));
  CUTLASS_CHECK(gemm_ref.run());

  // compare_reference
  ElementD const epsilon(1e-2f);
  ElementD const non_zero_floor(1e-4f);
  bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(block_ref_D.get(), block_D.get(), block_D.size(), epsilon, non_zero_floor);

  return passed;
}

/// Execute a given example GEMM computation
template <typename Gemm>
int run(Options &options)
{
  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options<Gemm>(options);

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
  MixedDtypeResult result;
  result.passed = verify(options);
  mixed_dtype_profiling(gemm, options, result);
  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;
  if (!result.passed) {
    exit(-1);
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

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
  if (props.major < 9) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Hopper Architecture or "
      << "later (compute capability 90 or greater).\n";
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

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
  if (options.mode == MixedDtypeGemmMode::ConvertOnly) {
    std::cout << "Running in no scale mode." << std::endl;
    if (options.shuffle) {
      std::cout << "Offline shuffle enabled." << std::endl;
      run<GemmConvertOnlyShuffled>(options);
    } else {
      std::cout << "Offline shuffle disabled." << std::endl;
      run<GemmConvertOnly>(options);
    }
  }
  else if (options.mode == MixedDtypeGemmMode::ScaleOnly) {
    if (options.g == options.k) {
      std::cout << "Running in per-column scale mode." << std::endl;
    } else {
      std::cout << "Running in group scale mode." << std::endl;
    }
    if (options.shuffle) {
      std::cout << "Offline shuffle enabled." << std::endl;
      run<GemmScaleOnlyShuffled>(options);
    } else {
      std::cout << "Offline shuffle disabled." << std::endl;
      run<GemmScaleOnly>(options);
    }
  }
  else if (options.mode == MixedDtypeGemmMode::ScaleWithZeroPoint) {
    if (options.g == options.k) {
      std::cout << "Running in per-column scale and zero mode." << std::endl;
    } else {
      std::cout << "Running in group scale and zero mode." << std::endl;
    }
    if (options.shuffle) {
      std::cout << "Offline shuffle enabled." << std::endl;
      run<GemmScaleWithZeroPointShuffled>(options);
    } else {
      std::cout << "Offline shuffle disabled." << std::endl;
      run<GemmScaleWithZeroPoint>(options);
    }
  }
#endif

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////