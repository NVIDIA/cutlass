#pragma once

// Host-side data layout for the W4A8 grouped Int4xFP8 GEMM microbenchmarks.
//
// Two pieces:
//
//   W4A8SharedInputs<>    Owns A/B/scale/problem-size device buffers and the
//                         reordered B layout. NOT parameterized on the output
//                         buffer, so a single instance can feed multiple Gemm
//                         variants that share the W4A8 epilogue contract
//                         (same ColumnMajor LayoutC/D, same bf16 ElementD).
//                         Stride types are taken from the canonical baseline
//                         C1 schedule; every variant we ship uses an identical
//                         InternalStrideC/D.
//
//   W4A8GemmContext<Gemm> Owns block_D + ptr_D for one Gemm variant; constructs
//                         Gemm::Arguments wired to a W4A8SharedInputs<>.
//
// This split lets a non-baseline experiment instantiate two contexts (one for
// the C1 reference, one for the experimental schedule) over a single shared
// input set, run both, and compare D buffers element-wise.

#include <cstdint>
#include <vector>

#include "common/w4a8_bench_common.hpp"
#include "common/w4a8_kernel_common.cuh"
#include "common/sm90_int4_fp8_grouped_baseline.cuh"

#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/mixed_dtype_utils.hpp"

#include "helper.h"
#include "mixed_dtype_utils.hpp"

#ifdef INT4FP8_GROUPED_SUPPORTED

using namespace cute;

// Canonical Gemm whose stride types and reordered-B layout we reuse for every
// W4A8 variant. All schedules in this microbenchmark share these types.
using W4A8CanonicalSchedule = Int4Fp8C1BaselineSchedule;
using W4A8CanonicalGemm = typename W4A8CanonicalSchedule::GemmScaleOnly;
using W4A8CanonicalKernel = typename W4A8CanonicalGemm::GemmKernel;

using W4A8StrideA = StrideF;
using W4A8StrideB = StrideQ;
using W4A8StrideC = typename W4A8CanonicalKernel::InternalStrideC;
using W4A8StrideD = typename W4A8CanonicalKernel::InternalStrideD;
using W4A8StrideS = typename W4A8CanonicalKernel::CollectiveMainloop::StrideScale;
using W4A8LayoutB_Reordered = typename W4A8CanonicalSchedule::LayoutQ_Reordered;

/// Device buffers + per-group strides that are independent of the output Gemm.
struct W4A8SharedInputs {
  std::vector<int64_t> offset_A;
  std::vector<int64_t> offset_B;
  std::vector<int64_t> offset_D;
  std::vector<int64_t> offset_scale;

  std::vector<W4A8StrideA> stride_A_host;
  std::vector<W4A8StrideB> stride_B_host;
  std::vector<W4A8StrideC> stride_C_host;
  std::vector<W4A8StrideD> stride_D_host;
  std::vector<W4A8StrideS> stride_S_host;

  cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes_device;

  cutlass::DeviceAllocation<MmaType> block_A;
  cutlass::DeviceAllocation<QuantType> block_B;
  cutlass::DeviceAllocation<QuantType> block_B_modified;
  cutlass::DeviceAllocation<ElementScale> block_scale;
  cutlass::DeviceAllocation<cutlass::Array<ElementScale, 8>> block_scale_packed;

  cutlass::DeviceAllocation<const MmaType *> ptr_A;
  cutlass::DeviceAllocation<const QuantType *> ptr_B;
  cutlass::DeviceAllocation<const cutlass::Array<ElementScale, 8> *> ptr_scale_packed;
  cutlass::DeviceAllocation<void const *> ptr_C;

  cutlass::DeviceAllocation<W4A8StrideA> stride_A;
  cutlass::DeviceAllocation<W4A8StrideB> stride_B;
  cutlass::DeviceAllocation<W4A8LayoutB_Reordered> layout_B_reordered;
  cutlass::DeviceAllocation<W4A8StrideC> stride_C;
  cutlass::DeviceAllocation<W4A8StrideD> stride_D;
  cutlass::DeviceAllocation<W4A8StrideS> stride_S;

  // Sizes (in elements) of the per-group output, useful for callers that want
  // to allocate their own block_D buffers.
  int64_t total_D_elements = 0;
  int64_t total_A_elements = 0;
  int64_t total_B_elements = 0;
  int64_t total_scale_elements = 0;

  void allocate_and_init(W4A8BenchOptions const &opt,
                         std::vector<typename ProblemShape::UnderlyingProblemShape> &problem_host) {
    using US = typename ProblemShape::UnderlyingProblemShape;
    offset_A.clear();
    offset_B.clear();
    offset_D.clear();
    offset_scale.clear();
    stride_A_host.clear();
    stride_B_host.clear();
    stride_C_host.clear();
    stride_D_host.clear();
    stride_S_host.clear();

    int64_t total_A = 0;
    int64_t total_B = 0;
    int64_t total_D = 0;
    int64_t total_scale = 0;

    problem_host.resize(opt.groups);
    for (int i = 0; i < opt.groups; ++i) {
      int M = opt.m;
      int N = opt.n;
      int K = opt.k;
      problem_host[i] = US{M, N, K};

      int const scale_k = cutlass::ceil_div(K, opt.c);

      offset_A.push_back(total_A);
      offset_B.push_back(total_B * cutlass::sizeof_bits<QuantType>::value / 8);
      offset_D.push_back(total_D);
      offset_scale.push_back(total_scale);

      int64_t el_A = static_cast<int64_t>(M) * K;
      int64_t el_B = static_cast<int64_t>(K) * N;
      int64_t el_D = static_cast<int64_t>(M) * N;
      int64_t el_scale = static_cast<int64_t>(scale_k) * N;

      total_A += el_A;
      total_B += el_B;
      total_D += el_D;
      total_scale += el_scale;

      stride_A_host.push_back(cutlass::make_cute_packed_stride(W4A8StrideA{}, cute::make_shape(M, K, 1)));
      stride_B_host.push_back(cutlass::make_cute_packed_stride(W4A8StrideB{}, cute::make_shape(N, K, 1)));
      stride_C_host.push_back(cutlass::make_cute_packed_stride(W4A8StrideC{}, cute::make_shape(N, M, 1)));
      stride_D_host.push_back(cutlass::make_cute_packed_stride(W4A8StrideD{}, cute::make_shape(N, M, 1)));
      stride_S_host.push_back(cutlass::make_cute_packed_stride(W4A8StrideS{}, cute::make_shape(N, scale_k, 1)));
    }

    total_A_elements = total_A;
    total_B_elements = total_B;
    total_D_elements = total_D;
    total_scale_elements = total_scale;

    block_A.reset(total_A);
    block_B.reset(total_B);
    block_B_modified.reset(total_B);
    block_scale.reset(total_scale);
    block_scale_packed.reset(total_scale);

    std::vector<MmaType *> pA(opt.groups);
    std::vector<QuantType *> pB(opt.groups);
    std::vector<cutlass::Array<ElementScale, 8> *> pS(opt.groups);
    std::vector<void const *> pC(opt.groups, nullptr);

    for (int i = 0; i < opt.groups; ++i) {
      pA[i] = block_A.get() + offset_A[i];
      pB[i] = block_B_modified.get() + offset_B[i];
      pS[i] = block_scale_packed.get() + offset_scale[i];
    }

    ptr_A.reset(opt.groups);
    ptr_A.copy_from_host(pA.data());
    ptr_B.reset(opt.groups);
    ptr_B.copy_from_host(pB.data());
    ptr_scale_packed.reset(opt.groups);
    ptr_scale_packed.copy_from_host(pS.data());
    ptr_C.reset(opt.groups);
    ptr_C.copy_from_host(pC.data());

    stride_A.reset(opt.groups);
    stride_A.copy_from_host(stride_A_host.data());
    stride_B.reset(opt.groups);
    stride_B.copy_from_host(stride_B_host.data());
    stride_C.reset(opt.groups);
    stride_C.copy_from_host(stride_C_host.data());
    stride_D.reset(opt.groups);
    stride_D.copy_from_host(stride_D_host.data());
    stride_S.reset(opt.groups);
    stride_S.copy_from_host(stride_S_host.data());

    uint64_t seed = 2026;
    initialize_tensor(block_A, seed + 3);
    initialize_tensor(block_B, seed + 2);
    cutlass::unified_encode_int4b(block_B.get(), block_B_modified.get(), block_B.size());

    MixedDtypeOptions mixed_opts;
    mixed_opts.mode = 1;
    initialize_scale(block_scale, mixed_opts, seed + 1);
    cutlass::pack_scale_fp8<ElementScale, QuantType>(block_scale.get(), block_scale_packed.get(), block_scale.size());

    using LayoutAtomQuant = typename W4A8CanonicalSchedule::LayoutAtomQuant;
    std::vector<W4A8LayoutB_Reordered> layout_B_host(opt.groups);
    for (int i = 0; i < opt.groups; ++i) {
      int N = opt.n;
      int K = opt.k;
      auto shape_B = cute::make_shape(N, K, Int<1>{});
      auto layout_B = make_layout(shape_B, stride_B_host[i]);
      layout_B_host[i] = cute::tile_to_shape(LayoutAtomQuant{}, shape_B);
      cutlass::reorder_tensor(block_B_modified.get() + offset_B[i], layout_B, layout_B_host[i]);
    }
    layout_B_reordered.reset(opt.groups);
    layout_B_reordered.copy_from_host(layout_B_host.data());

    // The CUTLASS grouped GEMM expects (N, M, K) per group.
    for (int i = 0; i < opt.groups; ++i) {
      auto [M, N, K] = problem_host[i];
      problem_host[i] = make_tuple(N, M, K);
    }
    problem_sizes_device.reset(opt.groups);
    problem_sizes_device.copy_from_host(problem_host.data());
  }
};

/// Per-Gemm output buffer + Arguments builder. Borrows the W4A8SharedInputs
/// for inputs and strides; allocates its own block_D / ptr_D.
template <class Gemm>
struct W4A8GemmContext {
  using ElementOut = typename Gemm::EpilogueOutputOp::ElementOutput;

  W4A8SharedInputs *shared = nullptr;

  cutlass::DeviceAllocation<ElementOut> block_D;
  cutlass::DeviceAllocation<ElementOut *> ptr_D;

  void allocate(W4A8BenchOptions const &opt) {
    if (shared == nullptr) {
      std::cerr << "W4A8GemmContext::allocate: shared inputs not set\n";
      std::exit(EXIT_FAILURE);
    }
    block_D.reset(shared->total_D_elements);

    std::vector<ElementOut *> pD(opt.groups);
    for (int i = 0; i < opt.groups; ++i) {
      pD[i] = block_D.get() + shared->offset_D[i];
    }
    ptr_D.reset(opt.groups);
    ptr_D.copy_from_host(pD.data());
  }

  void zero_outputs() {
    if (block_D.size() == 0) return;
    w4a8_cuda_check(
        cudaMemsetAsync(block_D.get(), 0,
                        block_D.size() * sizeof(ElementOut),
                        /*stream=*/0),
        __LINE__);
  }

  typename Gemm::Arguments make_arguments(W4A8BenchOptions const &opt) const {
    cutlass::KernelHardwareInfo hw_info;
    hw_info.device_id = 0;
    // The cooperative grouped-GEMM scheduler launches a persistent grid of
    // exactly `sm_count` CTAs. With the device-queried SM count (132 on H200)
    // the runtime block scheduler places exactly 1 CTA per SM, even when
    // resource limits would allow 2. Experiments that want to exercise 2
    // CTAs/SM must inflate `sm_count` so the grid is large enough for the
    // runtime to co-locate two CTAs on each SM.
#ifdef CUTLASS_W4A8_SM_COUNT_OVERRIDE
    hw_info.sm_count = CUTLASS_W4A8_SM_COUNT_OVERRIDE;
#else
    hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);
#endif

    decltype(std::declval<typename Gemm::Arguments>().epilogue.thread) fusion_args{};
    fusion_args.alpha = opt.alpha;
    fusion_args.beta = opt.beta;
    fusion_args.alpha_ptr = nullptr;
    fusion_args.beta_ptr = nullptr;
    fusion_args.alpha_ptr_array = nullptr;
    fusion_args.beta_ptr_array = nullptr;
    fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 0};
    fusion_args.dBeta = {cute::_0{}, cute::_0{}, 0};

    return typename Gemm::Arguments{
        cutlass::gemm::GemmUniversalMode::kGrouped,
        {opt.groups, shared->problem_sizes_device.get(), nullptr},
        {shared->ptr_B.get(), shared->layout_B_reordered.get(), shared->ptr_A.get(),
         shared->stride_A.get(), shared->ptr_scale_packed.get(),
         shared->stride_S.get(), opt.c},
        {fusion_args, shared->ptr_C.get(), shared->stride_C.get(), ptr_D.get(),
         shared->stride_D.get()},
        hw_info};
  }
};

#endif // INT4FP8_GROUPED_SUPPORTED
