#pragma once

// Slim baseline schedule: only the Int4Fp8GemmGivenSchedule<...> template and
// canonical configs. All shared types come from w4a8_kernel_common.cuh.
//
// This header is the canonical reference used by every non-baseline experiment
// for the equality check + fair-baseline timing.

#include "common/w4a8_kernel_common.cuh"

#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#ifdef INT4FP8_GROUPED_SUPPORTED

template <typename TConfig,
          typename KernelScheduleTag = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative>
struct Int4Fp8GemmGivenSchedule {
    using ElementAccumulator = float;
    using ArchTag = cutlass::arch::Sm90;
    using OperatorClass = cutlass::arch::OpClassTensorOp;
    using TileShape = typename TConfig::TileShape;
    using ClusterShape = typename TConfig::ClusterShape;
    using StageCountType = cutlass::gemm::collective::StageCountAuto;
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

// Default 128x128x128 cooperative (matches the original CUTLASS example).
using DefaultBaselineConfig = GemmConfig<Shape<_128, _128, cute::Int<TileShapeK>>, Shape<_1, _1, _1>>;
using Int4Fp8DefaultSchedule = Int4Fp8GemmGivenSchedule<DefaultBaselineConfig>;

// C1 winner from the baseline sweep: 128x16x128 cooperative. This is the
// canonical reference schedule for every non-baseline experiment that targets
// the M=1 decode regime.
using C1BaselineConfig = GemmConfig<Shape<_128, _16, cute::Int<TileShapeK>>, Shape<_1, _1, _1>>;
using Int4Fp8C1BaselineSchedule = Int4Fp8GemmGivenSchedule<C1BaselineConfig>;

#endif // INT4FP8_GROUPED_SUPPORTED
