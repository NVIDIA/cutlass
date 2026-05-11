#pragma once

#include <cstdint>
#include <vector>

#include "common/w4a8_bench_common.hpp"

#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/mixed_dtype_utils.hpp"

#include "helper.h"
#include "mixed_dtype_utils.hpp"

#include "sm90_int4_fp8_grouped.cuh"

using namespace cute;

/// Host-side buffer layout and initialization for the CUTLASS grouped Int4xFP8 GEMM.
/// Templated on the Gemm type so a single setup can serve every (TileShape, Cluster, Schedule)
/// variant in the sweep without re-allocating device memory.
template <class Gemm>
struct BaselineGroupedContext {
  using GemmKernel = typename Gemm::GemmKernel;
  using StrideC = typename GemmKernel::InternalStrideC;
  using StrideD = typename GemmKernel::InternalStrideD;
  using StrideS = typename GemmKernel::CollectiveMainloop::StrideScale;
  using LayoutB_Reordered = typename Int4Fp8DefaultSchedule::LayoutQ_Reordered;
  using StrideA = StrideF;
  using StrideB = StrideQ;

  std::vector<int64_t> offset_A;
  std::vector<int64_t> offset_B;
  std::vector<int64_t> offset_D;
  std::vector<int64_t> offset_scale;

  std::vector<StrideA> stride_A_host;
  std::vector<StrideB> stride_B_host;
  std::vector<StrideC> stride_C_host;
  std::vector<StrideD> stride_D_host;
  std::vector<StrideS> stride_S_host;

  cutlass::DeviceAllocation<typename ProblemShape::UnderlyingProblemShape> problem_sizes_device;

  cutlass::DeviceAllocation<MmaType> block_A;
  cutlass::DeviceAllocation<QuantType> block_B;
  cutlass::DeviceAllocation<QuantType> block_B_modified;
  cutlass::DeviceAllocation<ElementScale> block_scale;
  cutlass::DeviceAllocation<cutlass::Array<ElementScale, 8>> block_scale_packed;
  cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput> block_D;

  cutlass::DeviceAllocation<const MmaType *> ptr_A;
  cutlass::DeviceAllocation<const QuantType *> ptr_B;
  cutlass::DeviceAllocation<const cutlass::Array<ElementScale, 8> *> ptr_scale_packed;
  cutlass::DeviceAllocation<void const *> ptr_C;
  cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput *> ptr_D;

  cutlass::DeviceAllocation<StrideA> stride_A;
  cutlass::DeviceAllocation<StrideB> stride_B;
  cutlass::DeviceAllocation<LayoutB_Reordered> layout_B_reordered;
  cutlass::DeviceAllocation<StrideC> stride_C;
  cutlass::DeviceAllocation<StrideD> stride_D;
  cutlass::DeviceAllocation<StrideS> stride_S;

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

      stride_A_host.push_back(cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, 1)));
      stride_B_host.push_back(cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, 1)));
      stride_C_host.push_back(
          cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(N, M, 1)));
      stride_D_host.push_back(
          cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(N, M, 1)));
      stride_S_host.push_back(cutlass::make_cute_packed_stride(StrideS{}, cute::make_shape(N, scale_k, 1)));
    }

    block_A.reset(total_A);
    block_B.reset(total_B);
    block_B_modified.reset(total_B);
    block_D.reset(total_D);
    block_scale.reset(total_scale);
    block_scale_packed.reset(total_scale);

    std::vector<MmaType *> pA(opt.groups);
    std::vector<QuantType *> pB(opt.groups);
    std::vector<cutlass::Array<ElementScale, 8> *> pS(opt.groups);
    std::vector<typename Gemm::EpilogueOutputOp::ElementOutput *> pD(opt.groups);
    std::vector<void const *> pC(opt.groups, nullptr);

    for (int i = 0; i < opt.groups; ++i) {
      pA[i] = block_A.get() + offset_A[i];
      pB[i] = block_B_modified.get() + offset_B[i];
      pD[i] = block_D.get() + offset_D[i];
      pS[i] = block_scale_packed.get() + offset_scale[i];
    }

    ptr_A.reset(opt.groups);
    ptr_A.copy_from_host(pA.data());
    ptr_B.reset(opt.groups);
    ptr_B.copy_from_host(pB.data());
    ptr_D.reset(opt.groups);
    ptr_D.copy_from_host(pD.data());
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

    using LayoutAtomQuant = typename Int4Fp8DefaultSchedule::LayoutAtomQuant;
    std::vector<LayoutB_Reordered> layout_B_host(opt.groups);
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

    for (int i = 0; i < opt.groups; ++i) {
      auto [M, N, K] = problem_host[i];
      problem_host[i] = make_tuple(N, M, K);
    }
    problem_sizes_device.reset(opt.groups);
    problem_sizes_device.copy_from_host(problem_host.data());
  }

  typename Gemm::Arguments make_arguments(W4A8BenchOptions const &opt) const {
    cutlass::KernelHardwareInfo hw_info;
    hw_info.device_id = 0;
    hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

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
        {opt.groups, problem_sizes_device.get(), nullptr},
        {ptr_B.get(), layout_B_reordered.get(), ptr_A.get(), stride_A.get(), ptr_scale_packed.get(),
         stride_S.get(), opt.c},
        {fusion_args, ptr_C.get(), stride_C.get(), ptr_D.get(), stride_D.get()},
        hw_info};
  }
};
