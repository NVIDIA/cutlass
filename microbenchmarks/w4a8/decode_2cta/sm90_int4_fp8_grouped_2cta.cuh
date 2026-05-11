#pragma once

// Decode 2 CTAs/SM variant of the W4A8 grouped GEMM schedule.
//
// Identical to the baseline Int4Fp8GemmGivenSchedule except the mainloop pipeline
// depth is set explicitly via cutlass::gemm::collective::StageCount<kStages>
// instead of StageCountAutoCarveout. Capping the depth shrinks the per-CTA SMEM
// footprint, which together with the macro-overridden MmaRegisterRequirement and
// MinBlocksPerMultiprocessor (defined in this experiment's CMakeLists.txt) is
// intended to enable 2 CTAs per SM for the M=1 decode regime.

#include "common/w4a8_kernel_common.cuh"

#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#ifdef INT4FP8_GROUPED_SUPPORTED

template <typename TConfig,
          typename KernelScheduleTag = cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative,
          int kStages = 10>
struct Int4Fp8GemmGivenScheduleStaged {
    using ElementAccumulator = float;
    using ArchTag = cutlass::arch::Sm90;
    using OperatorClass = cutlass::arch::OpClassTensorOp;
    using TileShape = typename TConfig::TileShape;
    using ClusterShape = typename TConfig::ClusterShape;
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
        cutlass::gemm::collective::StageCount<kStages>,
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

#endif // INT4FP8_GROUPED_SUPPORTED
