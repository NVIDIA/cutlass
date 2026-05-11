#pragma once

// Type aliases shared across every W4A8 grouped-GEMM microbenchmark variant.
// Including this header is enough to use ProblemShape / MmaType / QuantType /
// GemmConfig / PtrArrayEpilogueScheduleFor without dragging in a specific
// schedule template.
//
// Each kernel-config header (sm90_int4_fp8_grouped_baseline.cuh,
// sm90_int4_fp8_grouped_2cta.cuh, ...) #includes this file and then defines
// only the schedule struct it owns. This split lets a single .cu translation
// unit instantiate two different schedule templates (e.g. baseline C1 + the
// experimental decode_2cta) without ODR/redefinition errors.

#include "cutlass/util/mixed_dtype_utils.hpp"
#include "mixed_dtype_utils.hpp"

#include "cute/tensor.hpp"
#include "cute/numeric/integral_constant.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/numeric_types.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/layout.h"
#include "cutlass/integer_subbyte.h"
#include "cutlass/detail/layout.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"

using namespace cute;

#ifdef INT4FP8_GROUPED_SUPPORTED

// minimal alignemnt for hopper GroupedGemm https://github.com/NVIDIA/cutlass/issues/2042
static const constexpr size_t ALIGNMENT = 64;
static const constexpr size_t MAX_PROBLEM_COUNT = 512;

using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int, int, int>>; // <M,N,K> per group

using MmaType = cutlass::float_e4m3_t;
using QuantType = cutlass::int4b_t;
constexpr int TileShapeK = 128 * 8 / sizeof_bits<MmaType>::value;

// A matrix configuration
using ElementF = MmaType;
using LayoutF = cutlass::layout::RowMajor;
constexpr int AlignmentA = 128 / cutlass::sizeof_bits<ElementF>::value;

// B matrix configuration
using ElementQ = QuantType;
using LayoutQ = cutlass::layout::ColumnMajor;
constexpr int AlignmentB = 128 / cutlass::sizeof_bits<ElementQ>::value;

// Manual swap-and-transpose, so keep transposed input layouts for the kernel.
using LayoutF_Transpose = typename cutlass::layout::LayoutTranspose<LayoutF>::type;
using LayoutQ_Transpose = typename cutlass::layout::LayoutTranspose<LayoutQ>::type;

using StrideF = cute::remove_pointer_t<cutlass::detail::TagToStrideA_t<LayoutF*>>;
using StrideQ = cute::remove_pointer_t<cutlass::detail::TagToStrideB_t<LayoutQ*>>;

using ElementScale = cutlass::float_e4m3_t;
using LayoutScale = cutlass::layout::ColumnMajor;

// C/D matrix configuration
using ElementC = void;
using ElementD = cutlass::bfloat16_t;

using LayoutC = cutlass::layout::ColumnMajor;
using LayoutD = LayoutC;
constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

// (Threadblock tile, cluster shape) pair used by every Int4Fp8 schedule template.
template <typename ThreadBlockShape, typename TClusterShape>
struct GemmConfig {
    using TileShape = ThreadBlockShape;
    using ClusterShape = TClusterShape;
};

// Map a mainloop KernelSchedule to its matching epilogue schedule for ptr-array
// (grouped) GEMM. Two schedules supported: cooperative + pingpong.
template <typename KernelScheduleTag>
struct PtrArrayEpilogueScheduleFor {
    using type = cutlass::epilogue::PtrArrayTmaWarpSpecializedCooperative;
};
template <>
struct PtrArrayEpilogueScheduleFor<cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong> {
    using type = cutlass::epilogue::PtrArrayTmaWarpSpecializedPingpong;
};

#endif // INT4FP8_GROUPED_SUPPORTED
