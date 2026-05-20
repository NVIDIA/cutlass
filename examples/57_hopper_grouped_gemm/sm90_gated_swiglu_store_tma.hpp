// Copyright (c) Butterfingrz，13524387014@163.com

#pragma once

#include <cstdint>

#include <cutlass/cutlass.h>
#include <cutlass/fast_math.h>
#include <cutlass/numeric_conversion.h>
#include <cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp>
#include <cute/atom/copy_traits_sm90_tma.hpp>
#include <cuda_bf16.h>

namespace cutlass::epilogue::fusion {

using namespace cute;

CUTLASS_DEVICE __nv_bfloat162 tanh_approx_bf16x2(__nv_bfloat162 x) {
  uint32_t in_bits = reinterpret_cast<uint32_t const&>(x);
  uint32_t out_bits;
  asm("tanh.approx.bf16x2 %0, %1;" : "=r"(out_bits) : "r"(in_bits));
  return reinterpret_cast<__nv_bfloat162 const&>(out_bits);
}

// Full-TMA-pipeline EVT visitor for gated SwiGLU with N→N/2 shape transformation.
//
// Replaces the scalar-store visitor (Sm90GatedSwiGLUStore) with a three-stage
// pipeline: visit() → registers, postreduce() → R2S, tma_store() → TMA S2G.
//
// The GEMM output is [M, 2I] but SwiGLU output is [M, I]. This visitor handles
// the 2:1 N-dimension reduction: visit() accumulates full-width fragments into
// a register tensor (Sm90AuxStore pattern), postreduce() computes SwiGLU from
// (gate, up) pairs and scatter-writes half-width results to [EPI_M, EPI_N/2]
// shared memory, and tma_store() issues TMA async stores from smem to gmem.
//
// For PtrArray grouped GEMM, per-group TMA descriptor updates are managed at
// the kernel dispatch layer (not in the visitor). The epilogue collective
// maintains aux TMA descriptors via HasAuxTmaStore trait, and the kernel passes
// a pre-updated tensormap pointer through ConsumerStoreArgs.

template <
  int Stages,
  class EpilogueTile,
  class Element,
  class ElementCompute = float,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest,
  class SmemLayoutAtom_ = void,  // unused; kept for epilogue builder API compatibility
  class CopyOpR2S_     = void,   // unused; kept for epilogue builder API compatibility
  int Alignment = 128 / sizeof_bits_v<Element>,
  bool EnableNullptr = true,
  int ThreadCount_ = 128
>
struct Sm90GatedSwiGLUStoreTma {
  using ElementAux = Element;
  static constexpr bool HasAuxTmaStore = true;
  static_assert(Alignment * sizeof_bits_v<Element> % 128 == 0, "sub-16B alignment not supported");

  // --- Subtile geometry and per-thread counts ---

  // Half-width epilogue subtile for SwiGLU output: [EPI_M, EPI_N/2]
  static constexpr int EpiM_val  = size<0>(EpilogueTile{});
  static constexpr int EpiN_val  = size<1>(EpilogueTile{});
  static constexpr int EpiNH_val = EpiN_val / 2;
  using EpiM     = Int<EpiM_val>;
  using EpiNHalf = Int<EpiNH_val>;
  using HalfEpiTile = Shape<EpiM, EpiNHalf>;

  static constexpr int ThreadCount = ThreadCount_;
  static constexpr int ResultsPerThread = EpiM_val * EpiNH_val / ThreadCount;
  static_assert(EpiM_val * EpiNH_val % ThreadCount == 0,
      "Half-width epilogue tile must be evenly divisible by ThreadCount");

  // --- Smem layouts for TMA store ---
  // DEBUG: swizzle disabled to isolate S2G writeback correctness
  using SmemLayoutAtomHalf = Layout<Shape<_8, EpiNHalf>, Stride<EpiNHalf, _1>>;

  using SmemLayoutTma = decltype(tile_to_shape(
      SmemLayoutAtomHalf{},
      make_shape(EpiM{}, EpiNHalf{}),
      Step<_1, _2>{}));

  using SmemLayout = decltype(tile_to_shape(
      SmemLayoutTma{},
      make_shape(EpiM{}, EpiNHalf{}, Int<Stages>{}),
      Step<_1, _2, _3>{}));

  // --- TMA descriptor type ---

  // TMA copy type for [M, N_out] row-major output
  using TMA_Swiglu = decltype(make_tma_copy(
      SM90_TMA_STORE{},
      make_tensor(
          static_cast<Element const*>(nullptr),
          make_layout(make_shape(int32_t(0), int32_t(0)),
                      make_stride(int32_t(0), _1{}))),
      SmemLayoutTma{}));

  // --- Shared storage ---

  struct SharedStorage {
    alignas(cutlass::detail::alignment_for_swizzle(SmemLayout{}))
    array_aligned<Element, cosize(SmemLayout{})> smem_swiglu;
  };

  // --- Host-side arguments and device params ---

  struct Arguments {
    Element** ptr_swiglu_out_array = nullptr;
    int32_t N_out = 0;
    int32_t stride_swiglu = 0;
    float swiglu_alpha = 1.702f;  // SiLU approximation coefficient
    float swiglu_limit = 7.0f;   // bf16 clamp boundary (tanh saturates beyond this)
  };

  struct Params {
    TMA_Swiglu tma_store_swiglu;
    Element** ptr_swiglu_out_array;
    int32_t N_out;
    int32_t stride_swiglu;
    float swiglu_alpha;
    float swiglu_limit;
    bool is_nullptr = false;
  };

  // --- Static host methods ---

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const&, Arguments const& args, void*) {
    bool is_nullptr = (args.ptr_swiglu_out_array == nullptr);
    TMA_Swiglu tma{};
    if (!is_nullptr) {
      // 16B-aligned dummy address; real addresses set per-group on device
      Element const* ptr_dummy = reinterpret_cast<Element const*>(
          reinterpret_cast<uintptr_t>(args.ptr_swiglu_out_array) & ~uintptr_t(0xF));
      int32_t init_M = EpiM_val;  // safe default, replaced on device
      auto tensor_tmpl = make_tensor(
          make_gmem_ptr(ptr_dummy),
          make_layout(make_shape(init_M, args.N_out),
                      make_stride(static_cast<int32_t>(args.stride_swiglu), _1{})));
      tma = make_tma_copy(SM90_TMA_STORE{}, tensor_tmpl, SmemLayoutTma{});
    }
    return {tma, args.ptr_swiglu_out_array, args.N_out,
            args.stride_swiglu, args.swiglu_alpha, args.swiglu_limit, is_nullptr};
  }

  template <class ProblemShape>
  static bool
  can_implement(ProblemShape const&, Arguments const&) { return true; }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const&, Arguments const&) { return 0; }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const&, Arguments const&, void*, cudaStream_t,
      CudaHostAdapter* = nullptr) {
    return cutlass::Status::kSuccess;
  }

  // --- Constructors and member variables ---

  CUTLASS_HOST_DEVICE
  Sm90GatedSwiGLUStoreTma() { }

  CUTLASS_HOST_DEVICE
  Sm90GatedSwiGLUStoreTma(Params const& params, SharedStorage const& shared_storage)
    : params_ptr(&params),
      smem_swiglu(const_cast<Element*>(shared_storage.smem_swiglu.data())) {}

  Params const* params_ptr;
  Element* smem_swiglu;

  // --- Device predicate and TMA descriptor accessors ---

  CUTLASS_DEVICE bool
  is_producer_load_needed() const { return false; }

  CUTLASS_DEVICE bool
  is_C_load_needed() const { return false; }

  // Return the TMA descriptor template for aux_store_init() to copy into smem
  CUTLASS_DEVICE auto
  get_aux_tma_descriptor() const {
    return params_ptr->tma_store_swiglu.get_tma_descriptor();
  }

  // Replace address + dims/strides in the smem descriptor for the given batch/group
  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE void
  aux_tensormaps_replace(
      cute::TmaDescriptor& smem_desc,
      ProblemShape_MNKL problem_shape_mnkl,
      int32_t next_batch) {
    if constexpr (EnableNullptr) {
      if (params_ptr->is_nullptr) return;
    }
    Element* ptr_group = params_ptr->ptr_swiglu_out_array[next_batch];
    int32_t M = get<0>(problem_shape_mnkl);
    int32_t N_out = params_ptr->N_out;
    int32_t stride = params_ptr->stride_swiglu;

    cute::tma_descriptor_replace_addr_in_shared_mem(smem_desc, ptr_group);

    auto tensor_group = make_tensor(
        make_gmem_ptr(ptr_group),
        make_layout(make_shape(M, N_out), make_stride(stride, _1{})));
    constexpr int MaxRank = 5;
    cute::array<uint32_t, MaxRank> prob_shape  = {1,1,1,1,1};
    cute::array<uint64_t, MaxRank> prob_stride = {0,0,0,0,0};
    cute::detail::fill_tma_gmem_shape_stride(
        params_ptr->tma_store_swiglu, tensor_group, prob_shape, prob_stride);
    for (auto& s : prob_stride) {
      s = (s * sizeof_bits_v<Element>) / 8;
    }
    cute::tma_descriptor_replace_dims_strides_in_shared_mem(
        smem_desc, prob_shape, prob_stride);
  }

  // --- Callback factories ---

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const&) {
    return EmptyProducerLoadCallbacks{};
  }

  template <class RTensor, class SSwigluEpi, class STensorS2G, class GTensorS2G>
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
        cute::array<int, ResultsPerThread> const& result_m,
        cute::array<int, ResultsPerThread> const& result_n_half,
        RTensor&& tC_rFull,
        SSwigluEpi&& sSwiglu_epi,
        STensorS2G&& bSG_sSwiglu,
        GTensorS2G&& bSG_gSwiglu,
        Params const* params_ptr,
        cute::TmaDescriptor const* kernel_swiglu_tensormap)
      : result_m(result_m),
        result_n_half(result_n_half),
        tC_rFull(cute::forward<RTensor>(tC_rFull)),
        sSwiglu_epi(cute::forward<SSwigluEpi>(sSwiglu_epi)),
        bSG_sSwiglu(cute::forward<STensorS2G>(bSG_sSwiglu)),
        bSG_gSwiglu(cute::forward<GTensorS2G>(bSG_gSwiglu)),
        params_ptr(params_ptr),
        kernel_swiglu_tensormap(kernel_swiglu_tensormap) {}

    // --- Members ---

    cute::array<int, ResultsPerThread> result_m;       // target M coordinate per result
    cute::array<int, ResultsPerThread> result_n_half;   // target N/2 coordinate per result
    RTensor tC_rFull;                                   // full-width register tensor (CPY,CPY_M,CPY_N)
    SSwigluEpi sSwiglu_epi;              // (EpiM, EpiNH, PIPE) unpartitioned smem tensor
    STensorS2G bSG_sSwiglu;              // (TMA,EPI_M,EPI_N,PIPE) TMA S2G smem partition
    GTensorS2G bSG_gSwiglu;              // (TMA,EPI_M,EPI_N,m,n)  TMA S2G gmem partition
    Params const* params_ptr;
    cute::TmaDescriptor const* kernel_swiglu_tensormap;  // pre-updated by kernel dispatch

    // --- Pipeline callbacks ---

    CUTLASS_DEVICE void
    begin() {}

    CUTLASS_DEVICE bool
    begin_sync_needed() const {
      return false;
    }

    // --- Compute and store ---

    // Accumulate each fragment into the full-width register tensor (Sm90AuxStore pattern).
    // SwiGLU computation is deferred to postreduce() where the full subtile is available.
    template <typename ElementAccumulator, typename ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc,
          int epi_v, int epi_m, int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input) {

      if constexpr (EnableNullptr) {
        if (params_ptr->is_nullptr) return frg_input;
      }

      using ConvertInput = NumericArrayConverter<Element, ElementInput, FragmentSize, RoundStyle>;
      ConvertInput convert_input{};
      auto tC_rFull_frg = recast<Array<Element, FragmentSize>>(coalesce(tC_rFull));
      tC_rFull_frg(epi_v) = convert_input(frg_input);

      return frg_input;
    }

    // Compute SwiGLU from the fully-accumulated register tensor and scatter-write
    // results to swizzled half-width smem. CLayout guarantees compact index 2k = gate
    // (even N), 2k+1 = up (odd N), so we read bf16x2 pairs directly from tC_rFull.
    CUTLASS_DEVICE void
    postreduce(int epi_m, int epi_n, int store_iteration, bool issue_smem_store) {
      if constexpr (EnableNullptr) {
        if (params_ptr->is_nullptr) return;
      }

      if (!issue_smem_store) return;

      int pipe = store_iteration % Stages;

      auto const* full_ptr = reinterpret_cast<__nv_bfloat162 const*>(tC_rFull.data());

      __nv_bfloat16 alpha_half_s = __float2bfloat16_rn(
          params_ptr->swiglu_alpha * 0.5f);
      __nv_bfloat16 limit_s = __float2bfloat16_rn(params_ptr->swiglu_limit);
      __nv_bfloat162 alpha_half2 = __bfloat162bfloat162(alpha_half_s);
      __nv_bfloat162 limit2 = __bfloat162bfloat162(limit_s);
      __nv_bfloat162 neg_limit2 = __hneg2(limit2);
      __nv_bfloat162 half2_val = __bfloat162bfloat162(
          __float2bfloat16_rn(0.5f));

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < ResultsPerThread / 2; ++i) {
        __nv_bfloat162 gu0 = full_ptr[2 * i];
        __nv_bfloat162 gu1 = full_ptr[2 * i + 1];
        __nv_bfloat162 g_pair = __halves2bfloat162(
            __low2bfloat16(gu0), __low2bfloat16(gu1));
        __nv_bfloat162 u_pair = __halves2bfloat162(
            __high2bfloat16(gu0), __high2bfloat16(gu1));

        g_pair = __hmin2(g_pair, limit2);
        u_pair = __hmax2(__hmin2(u_pair, limit2), neg_limit2);

        __nv_bfloat162 ag = __hmul2(alpha_half2, g_pair);
        __nv_bfloat162 t = tanh_approx_bf16x2(ag);
        __nv_bfloat162 s = __hfma2(t, half2_val, half2_val);
        __nv_bfloat162 gs = __hmul2(g_pair, s);
        __nv_bfloat162 result = __hfma2(gs, u_pair, gs);

        auto* result_bf16 = reinterpret_cast<cutlass::bfloat16_t*>(&result);
        sSwiglu_epi(result_m[2*i], result_n_half[2*i], pipe) = result_bf16[0];
        sSwiglu_epi(result_m[2*i+1], result_n_half[2*i+1], pipe) = result_bf16[1];
      }
    }

    // S2G: TMA async store from smem to gmem using kernel-provided descriptor
    CUTLASS_DEVICE void
    tma_store(int epi_m, int epi_n, int store_iteration, bool issue_tma_store) {
      if constexpr (EnableNullptr) {
        if (params_ptr->is_nullptr) return;
      }

      if (issue_tma_store) {
        int pipe_idx = store_iteration % Stages;
        copy(params_ptr->tma_store_swiglu.with(kernel_swiglu_tensormap),
             bSG_sSwiglu(_,_,_,pipe_idx),
             bSG_gSwiglu(_,_,_,epi_m,epi_n));
      }
    }
  };

  template <
    bool ReferenceSrc,
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [m, n, k, l] = args.tile_coord_mnkl;

    // Smem view: [EpiM, EpiNH, Stages] — unpartitioned, for coordinate-based scatter writes
    auto sSwiglu_epi = cute::as_position_independent_swizzle_tensor(
        make_tensor(make_smem_ptr(smem_swiglu), SmemLayout{}));

    // --- Coordinate extraction from CLayout-aware tiled_copy ---
    auto cEpi = make_identity_tensor(args.epi_tile);    // (EpiM, EpiN)
    auto thr_tc = args.tiled_copy.get_slice(args.thread_idx);
    auto tC_cEpi = thr_tc.partition_S(cEpi);            // (CPY, CPY_M, CPY_N)

    // Pre-compute target (M, N_half) for each SwiGLU result.
    // Result k comes from gate/up pair at fragment indices (2k, 2k+1).
    // Gate element (2k) gives the output coordinate; N_half = N / 2.
    cute::array<int, ResultsPerThread> result_m;
    cute::array<int, ResultsPerThread> result_n_half;

    constexpr int CPY   = decltype(size<0>(tC_cEpi))::value;
    constexpr int CPY_M = decltype(size<1>(tC_cEpi))::value;

    CUTLASS_PRAGMA_UNROLL
    for (int k = 0; k < ResultsPerThread; ++k) {
      int flat = 2 * k;
      int c  = flat % CPY;
      int cm = (flat / CPY) % CPY_M;
      int cn = flat / (CPY * CPY_M);
      auto coord = tC_cEpi(c, cm, cn);
      result_m[k]      = get<0>(coord);
      result_n_half[k]  = get<1>(coord) / 2;
    }

    // Full-width register tensor for Sm90AuxStore-style accumulation in visit()
    auto tC_rFull = make_tensor<Element>(shape(tC_cEpi));             // (CPY,CPY_M,CPY_N)

    // --- TMA S2G partitions (unchanged) ---
    int32_t N_out = params_ptr->N_out;
    auto mSwiglu = params_ptr->tma_store_swiglu.get_tma_tensor(
        make_shape(M, N_out));

    constexpr int CtaM = size<0>(decltype(take<0,2>(args.tile_shape_mnk)){});
    constexpr int CtaNHalf = size<1>(decltype(take<0,2>(args.tile_shape_mnk)){}) / 2;
    auto half_cta_tile = make_shape(Int<CtaM>{}, Int<CtaNHalf>{});
    auto gSwiglu = local_tile(mSwiglu, half_cta_tile, make_coord(m, n));

    auto gSwiglu_epi = flat_divide(gSwiglu, HalfEpiTile{});

    auto thrblk_s2g = params_ptr->tma_store_swiglu.get_slice(_0{});
    auto bSG_sSwiglu = thrblk_s2g.partition_S(sSwiglu_epi);
    auto bSG_gSwiglu = thrblk_s2g.partition_D(gSwiglu_epi);

    return ConsumerStoreCallbacks<
        decltype(tC_rFull), decltype(sSwiglu_epi), decltype(bSG_sSwiglu), decltype(bSG_gSwiglu)>(
      result_m,
      result_n_half,
      cute::move(tC_rFull),
      cute::move(sSwiglu_epi),
      cute::move(bSG_sSwiglu),
      cute::move(bSG_gSwiglu),
      params_ptr,
      args.aux_store_tensormap);
  }
};

} // namespace cutlass::epilogue::fusion