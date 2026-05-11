#pragma once

using namespace cute;

// minimal alignemnt for hopper GroupedGemm https://github.com/NVIDIA/cutlass/issues/2042
static const constexpr size_t ALIGNMENT = 64;
static const constexpr size_t MAX_PROBLEM_COUNT = 512;
#ifdef INT4FP8_GROUPED_SUPPORTED

using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int, int, int>>; // <M,N,K> per group
using MmaType = cutlass::float_e4m3_t;
using QuantType = cutlass::int4b_t;
constexpr int TileShapeK = 128 * 8 / sizeof_bits<MmaType>::value;

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using ElementF = MmaType;
using LayoutF = cutlass::layout::RowMajor;                              // Layout type for A matrix operand
constexpr int AlignmentA = 128 / cutlass::sizeof_bits<ElementF>::value; // Alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using ElementQ = QuantType;                                             // Element type for B matrix operand
using LayoutQ = cutlass::layout::ColumnMajor;                           // Layout type for B matrix operand
constexpr int AlignmentB = 128 / cutlass::sizeof_bits<ElementQ>::value; // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// This example manually swaps and transposes, so keep transpose of input layouts
using LayoutF_Transpose = typename cutlass::layout::LayoutTranspose<LayoutF>::type;
using LayoutQ_Transpose = typename cutlass::layout::LayoutTranspose<LayoutQ>::type;

// Need to pass a pointer type to make the 3rd dimension of Stride be _0
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

template <typename ThreadBlockShape, typename TClusterShape>
struct GemmConfig {
    using TileShape = ThreadBlockShape;
    using ClusterShape = TClusterShape;
};

// Map a mainloop KernelSchedule to its matching epilogue schedule for ptr-array (grouped) GEMM.
template <typename KernelScheduleTag>
struct PtrArrayEpilogueScheduleFor {
    using type = cutlass::epilogue::PtrArrayTmaWarpSpecializedCooperative;
};
template <>
struct PtrArrayEpilogueScheduleFor<cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong> {
    using type = cutlass::epilogue::PtrArrayTmaWarpSpecializedPingpong;
};

template <typename TConfig,
          typename KernelScheduleTag = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative>
struct Int4Fp8GemmGivenSchedule {
    // Core kernel configurations
    using ElementAccumulator = float;                                 // Element type for internal accumulation
    using ArchTag = cutlass::arch::Sm90;                              // Tag indicating the minimum SM that supports the intended feature
    using OperatorClass = cutlass::arch::OpClassTensorOp;             // Operator class tag
    using TileShape = typename TConfig::TileShape;                    // Threadblock-level tile size
    using ClusterShape = typename TConfig::ClusterShape;              // Shape of the threadblocks in a cluster
    using StageCountType = cutlass::gemm::collective::StageCountAuto; // Stage count maximized based on the tile size
    using KernelSchedule = KernelScheduleTag;
    using EpilogueSchedule = typename PtrArrayEpilogueScheduleFor<KernelScheduleTag>::type;

    using LayoutAtomQuant = decltype(cutlass::compute_memory_reordering_atom<MmaType>());
    using LayoutQ_Reordered = decltype(cute::tile_to_shape(LayoutAtomQuant{}, Layout<Shape<int, int, Int<1>>, StrideQ>{}));

    using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
        cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
        TileShape, ClusterShape,
        cutlass::epilogue::collective::EpilogueTileAuto,
        ElementAccumulator, ElementAccumulator,
        ElementC, LayoutC*, AlignmentD,
        ElementD, LayoutD*, AlignmentD,
        EpilogueSchedule>::CollectiveOp;

    using CollectiveMainloopScaleOnly = typename cutlass::gemm::collective::CollectiveBuilder<
        ArchTag, OperatorClass,
        cute::tuple<ElementQ, cutlass::Array<ElementScale, 8>>, LayoutQ_Reordered*, AlignmentB,
        ElementF, LayoutF_Transpose*, AlignmentA,
        ElementAccumulator,
        TileShape, ClusterShape,
        cutlass::gemm::collective::StageCountAutoCarveout<
            static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
        KernelSchedule>::CollectiveOp;

    using GemmKernelScaleOnly = cutlass::gemm::kernel::GemmUniversal<
        ProblemShape,
        CollectiveMainloopScaleOnly,
        CollectiveEpilogue>;

    using GemmScaleOnly = cutlass::gemm::device::GemmUniversalAdapter<GemmKernelScaleOnly>;

    using StrideC = typename GemmKernelScaleOnly::InternalStrideC;
    using StrideD = typename GemmKernelScaleOnly::InternalStrideD;
    using StrideC_ref = cutlass::detail::TagToStrideC_t<LayoutC>;
    using StrideD_ref = cutlass::detail::TagToStrideC_t<LayoutD>;
    using StrideS = typename CollectiveMainloopScaleOnly::StrideScale;
    using StrideS_ref = cutlass::detail::TagToStrideB_t<LayoutScale>;
};
using DefaultConfig = GemmConfig<Shape<_128, _128, cute::Int<TileShapeK>>, Shape<_1, _1, _1>>;
using Int4Fp8DefaultSchedule = Int4Fp8GemmGivenSchedule<DefaultConfig>;
#endif
