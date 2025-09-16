/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include <sycl/sycl.hpp>
#include <syclcompat.hpp>

#include <cute/tensor.hpp>

#include "cutlass/util/print_error.hpp"
#include "cutlass/util/sycl_event_manager.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/kernel_hardware_info.h"
#include "cutlass/util/reference/device/tensor_compare.h"

template <class TA, class TB, class TC,
          class Alpha, class Beta>
bool verify(
  TA const* d_A,
  TB const* d_B,
  TC* d_C,
  int m,
  int n,
  int k,
  Alpha alpha,
  Beta beta,
  char transA,
  char transB
) {
  auto ref_d_C = syclcompat::malloc<TC>(m*n);
  cutlass::TensorRef ref_A_T(d_A, cutlass::layout::RowMajor::packed({m, k}));
  cutlass::TensorRef ref_A_N(d_A, cutlass::layout::ColumnMajor::packed({m, k}));
  
  cutlass::TensorRef ref_B_T(d_B, cutlass::layout::RowMajor::packed({k, n}));
  cutlass::TensorRef ref_B_N(d_B, cutlass::layout::ColumnMajor::packed({k, n}));

  cutlass::TensorRef ref_C(ref_d_C, cutlass::layout::RowMajor::packed({m, n}));
  cutlass::TensorRef ref_D(ref_d_C, cutlass::layout::RowMajor::packed({m, n}));

  if (transA == 'T' && transB == 'N') {
    cutlass::reference::device::GemmComplex(
      {m, n, k},
      alpha,
      ref_A_T,
      cutlass::ComplexTransform::kNone,
      ref_B_N,
      cutlass::ComplexTransform::kNone,
      beta,
      ref_C,
      ref_D,
      float(0),  // accumulator
      1,     // batch_count
      m * k, // batch_stride_A
      k * n, // batch_stride_B
      m * n, // batch_stride_C
      m * n  // batch_stride_D
    );
  } else if (transA == 'T' && transB == 'T') {
    cutlass::reference::device::GemmComplex(
      {m, n, k},
      alpha,
      ref_A_T,
      cutlass::ComplexTransform::kNone,
      ref_B_T,
      cutlass::ComplexTransform::kNone,
      beta,
      ref_C,
      ref_D,
      float(0),  // accumulator
      1,     // batch_count
      m * k, // batch_stride_A
      k * n, // batch_stride_B
      m * n, // batch_stride_C
      m * n  // batch_stride_D
    );
  } else if (transA == 'N' && transB == 'T') {
    cutlass::reference::device::GemmComplex(
      {m, n, k},
      alpha,
      ref_A_N,
      cutlass::ComplexTransform::kNone,
      ref_B_T,
      cutlass::ComplexTransform::kNone,
      beta,
      ref_C,
      ref_D,
      float(0),  // accumulator
      1,     // batch_count
      m * k, // batch_stride_A
      k * n, // batch_stride_B
      m * n, // batch_stride_C
      m * n  // batch_stride_D
    );
  } else {
    assert(false && "Not implemented");
  }


  // CUTLASS on SYCL uses the compatibility library syclcompat for e.g. default in-order queue
  syclcompat::wait();

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  bool passed = cutlass::reference::device::BlockCompareEqual(
    ref_d_C, d_C, m * n);

  return passed;
}

template <class ProblemShape, class CtaTiler,
          class TA, class AStride, class TiledCopyA,
          class TB, class BStride, class TiledCopyB,
          class TC, class CStride, class TiledCopyC, class TiledMma,
          class Alpha, class Beta>
void
gemm_device(ProblemShape shape_MNK, CtaTiler cta_tiler, int stages,
            TA const* A, AStride dA, TiledCopyA,
            TB const* B, BStride dB, TiledCopyB,
            TC      * C, CStride dC, TiledCopyC, TiledMma mma,
            Alpha alpha, Beta beta)
{
  using namespace cute;

  auto A_shape = select<0,2,3>(shape_MNK);  // 4, 16, 32, 1
  auto B_shape = select<1,2,3>(shape_MNK);
  auto C_shape = select<0,1,3>(shape_MNK);

  // Represent the full tensors
  auto mA = make_tensor(make_gmem_ptr(A), make_layout(A_shape, dA));
  auto mB = make_tensor(make_gmem_ptr(B), make_layout(B_shape, dB));
  auto mC = make_tensor(make_gmem_ptr(C), make_layout(C_shape, dC));

  auto copy_a = TiledCopyA{mA};  
  auto copy_b = TiledCopyB{mB};
  auto copy_c = TiledCopyC{mC};

  Tensor mA_coord = cute::get_xe_tensor(A_shape);   //(m,k,l)
  Tensor mB_coord = cute::get_xe_tensor(B_shape);   //(n,k,l)
  Tensor mC_coord = cute::get_xe_tensor(C_shape);   //(m,n,l)

  // Get the appropriate blocks for this thread block
  auto cta_coord = make_coord(syclcompat::work_group_id::x(), syclcompat::work_group_id::y(), 0);  // (m,n,k)

  Tensor gA = local_tile(mA_coord, select<0,2>(cta_tiler), make_coord(BlockIdxX(),_,BlockIdxZ()));  // (BLK_M,BLK_K,k)
  Tensor gB = local_tile(mB_coord, select<1,2>(cta_tiler), make_coord(BlockIdxY(),_,BlockIdxZ()));  // (BLK_N,BLK_K,k)
  Tensor gC = local_tile(mC_coord, cta_tiler, cta_coord, Step<_1,_1, X>{});  // (BLK_M,BLK_N)

  //
  // Define A/B partitioning and C accumulators
  //

  TiledMma tiled_mma;
  constexpr int sg_size = 16;
  auto sg = syclcompat::get_nd_item<1>().get_sub_group();
  auto first_thread_in_sg_idx = sg.get_group_linear_id() * sg_size;
  auto thr_mma = tiled_mma.get_slice(first_thread_in_sg_idx);

  // Partition global counting tensors for MMA
  Tensor tCgA = thr_mma.partition_A(gA);
  Tensor tCgB = thr_mma.partition_B(gB);
  Tensor tCgC = thr_mma.partition_C(gC);

  Tensor tCrA = make_tensor<TA>(make_fragment_layout(copy_a, tCgA(_,_,_,0).shape()));
  Tensor tCrB = make_tensor<TB>(make_fragment_layout(copy_b, tCgB(_,_,_,0).shape()));

  ThrCopy thr_copy_a = copy_a.get_slice(syclcompat::local_id::x());
  ThrCopy thr_copy_b = copy_b.get_slice(syclcompat::local_id::x());

  // Retile registers for copies
  Tensor tArA = thr_copy_a.retile_D(tCrA);
  Tensor tBrB = thr_copy_b.retile_D(tCrB);

  // Retile global counting tensors for copies
  Tensor tAgA = thr_copy_a.retile_S(tCgA);
  Tensor tBgB = thr_copy_b.retile_S(tCgB);

  //
  // PREFETCH
  //

  // constexpr int Num_SGs = size(tiled_mma);
  static constexpr auto ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;

  static constexpr auto BLK_M = get<0>(CtaTiler{});
  static constexpr auto BLK_N = get<1>(CtaTiler{});
  static constexpr auto BLK_K = get<2>(CtaTiler{});

  auto prefetch_a = cute::prefetch_selector<Shape<Int<BLK_M>,Int<BLK_K>>, Num_SGs>(copy_a);
  auto prefetch_b = cute::prefetch_selector<Shape<Int<BLK_N>,Int<BLK_K>>, Num_SGs>(copy_b);
  int thread_idx = int(ThreadIdxX());
  auto thr_prefetch_A = prefetch_a.get_slice(thread_idx);
  auto thr_prefetch_B = prefetch_b.get_slice(thread_idx);

  // Partition global tile for prefetch
  auto pAgA = thr_prefetch_A.partition_S(gA);
  auto pBgB = thr_prefetch_B.partition_S(gB);

  int prefetch_k = 0;

  // Clear the accumulators
  Tensor tCrC = partition_fragment_C(tiled_mma, take<0,2>(cta_tiler));
  clear(tCrC);

  constexpr int barrier_scope = 2;
  int k_tile_count = ceil_div(get<2>(shape_MNK), get<2>(cta_tiler));

  CUTLASS_PRAGMA_UNROLL
  for (; prefetch_k < stages; prefetch_k++) {
    prefetch(prefetch_a, pAgA(_, _, _, prefetch_k));
    prefetch(prefetch_b, pBgB(_, _, _, prefetch_k));
  }

  CUTLASS_PRAGMA_UNROLL
  for (int k_tile = 0; k_tile < k_tile_count; k_tile++, prefetch_k++) {
    barrier_arrive(barrier_scope);
    // Copy gmem to rmem for the first k_tile
    copy(copy_a, tAgA(_,_,_,k_tile), tArA);
    copy(copy_b, tBgB(_,_,_,k_tile), tBrB);

    if (prefetch_k < k_tile_count) {
      prefetch(prefetch_a, pAgA(_, _, _, prefetch_k));
      prefetch(prefetch_b, pBgB(_, _, _, prefetch_k));
    }

    cute::gemm(tiled_mma, tCrA, tCrB, tCrC);
    barrier_wait(barrier_scope);

  }

  //
  // Epilogue
  //
  copy(copy_c, tCrC, tCgC(_,_,_,0));

}

// Setup params for a NT GEMM
template <class TA, class TB, class TC,
          class Alpha, class Beta>
void
gemm_nt(int m, int n, int k,
        Alpha alpha,
        TA const* A, int ldA,
        TB const* B, int ldB,
        Beta beta,
        TC      * C, int ldC)
{
  using namespace cute;

  // Define shapes (dynamic)
  auto M = int(m);
  auto N = int(n);
  auto K = int(k);
  auto L = int(1);
  auto prob_shape = make_shape(M, N, K, L);                     // (M, N, K, L)

  // Define NT strides (mixed)
  auto dA = make_stride(Int<1>{}, ldA);                      // (dM, dK)
  auto dB = make_stride(Int<1>{}, ldB);                      // (dN, dK)
  auto dC = make_stride(ldC, Int<1>{});                      // (dM, dN)

  // Define CTA tile sizes (static)
  auto bM = Int<256>{};
  auto bN = Int<256>{};
  auto bK = Int< 32>{};
  auto cta_tiler = make_shape(bM, bN, bK);                   // (BLK_M, BLK_N, BLK_K)
  auto bP = Int<2>{};  // Pipeline

  // Define the thread layouts (static)                                  
  TiledCopy copyA = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x16x16_LD_T, decltype(dA)>, TA>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 k-major
                                    Layout<Shape<_16,_1>>{});              // Val layout  32x2

  TiledCopy copyB = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x32x32_LD_V, decltype(dB)>, TB>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_32,_2>>{});              // Val layout  16x1
  TiledCopy copyC = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U32x8x16_ST_N, decltype(dC)>, TC>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_8,_1>>{});              // Val layout  8x1

  TiledMMA mmaC = TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<decltype(cta_tiler)>,
                                 Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA{};

  auto dimBlock = syclcompat::dim3(size(mmaC));
  auto dimGrid  = syclcompat::dim3(size(ceil_div(M, bM)), size(ceil_div(N, bN)));

  constexpr int SubgroupSize = 16;
  constexpr int smem_size = 0;
  auto kernel_props = [] {
    return syclcompat::experimental::kernel_properties{
      sycl::ext::oneapi::experimental::sub_group_size<SubgroupSize>
    };
  }();
  syclcompat::experimental::launch_properties launch_props {
    sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
  };
  syclcompat::experimental::launch_policy policy{
    dimGrid, dimBlock, launch_props, kernel_props
  };
  auto event = syclcompat::experimental::launch<
    gemm_device<decltype(prob_shape), decltype(cta_tiler),
                TA, decltype(dA), decltype(copyA),
                TB, decltype(dB), decltype(copyB),
                TC, decltype(dC), decltype(copyC), decltype(mmaC),
                Alpha, Beta>>(policy, prob_shape, cta_tiler, bP,
                    A, dA, copyA,
                    B, dB, copyB,
                    C, dC, copyC, mmaC,
                    alpha, beta);

  EventManager::getInstance().addEvent(event);
}

// Setup params for a NT GEMM
template <class TA, class TB, class TC,
          class Alpha, class Beta>
void
gemm_tn(int m, int n, int k,
        Alpha alpha,
        TA const* A, int ldA,
        TB const* B, int ldB,
        Beta beta,
        TC      * C, int ldC)
{
  using namespace cute;

  // Define shapes (dynamic)
  auto M = int(m);
  auto N = int(n);
  auto K = int(k);
  auto L = int(1);
  auto prob_shape = make_shape(M, N, K, L);                     // (M, N, K, L)

  // Define TN strides (mixed)
  auto dA = make_stride(ldA, Int<1>{}, Int<0>{});                      // (dM, dK)
  auto dB = make_stride(ldB, Int<1>{}, Int<0>{});                      // (dN, dK)
  // auto dC = make_stride(Int<1>{}, ldC, Int<0>{});                      // (dM, dN)
  auto dC = make_stride(ldC, Int<1>{}, Int<0>{});   

  // Define CTA tile sizes (static)
  auto bM = Int<256>{};
  auto bN = Int<256>{};
  auto bK = Int< 32>{};
  auto cta_tiler = make_shape(bM, bN, bK);                   // (BLK_M, BLK_N, BLK_K)
  auto bP = Int<2>{};  // Pipeline

  // Define the thread layouts (static)
  TiledCopy copyA = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x32x32_LD_N, decltype(dA)>, TA>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 k-major
                                    Layout<Shape<_32,_2>>{});              // Val layout  32x2
  TiledCopy copyB = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x16x16_LD_T, decltype(dB)>, TB>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_16,_1>>{});              // Val layout  16x1
  TiledCopy copyC = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U32x8x16_ST_N, decltype(dC)>, TC>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_8,_1>>{});              // Val layout  8x1

  TiledMMA mmaC = TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<decltype(cta_tiler)>,
                                    Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA{};  // 256x128x16 TiledMMA

  auto dimBlock = syclcompat::dim3(size(mmaC));
  auto dimGrid  = syclcompat::dim3(size(ceil_div(M, bM)), size(ceil_div(N, bN)));

  constexpr int SubgroupSize = 16;
  constexpr int smem_size = 0;
  auto kernel_props = [] {
    return syclcompat::experimental::kernel_properties{
      sycl::ext::oneapi::experimental::sub_group_size<SubgroupSize>
    };
  }();
  syclcompat::experimental::launch_properties launch_props {
    sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
  };
  syclcompat::experimental::launch_policy policy{
    dimGrid, dimBlock, launch_props, kernel_props
  };
  auto event = syclcompat::experimental::launch<
    gemm_device<decltype(prob_shape), decltype(cta_tiler),
                TA, decltype(dA), decltype(copyA),
                TB, decltype(dB), decltype(copyB),
                TC, decltype(dC), decltype(copyC), decltype(mmaC),
                Alpha, Beta>>(policy, prob_shape, cta_tiler, bP,
                    A, dA, copyA,
                    B, dB, copyB,
                    C, dC, copyC, mmaC,
                    alpha, beta);
  EventManager::getInstance().addEvent(event);
}

template <class TA, class TB, class TC,
          class Alpha, class Beta>
void
gemm_tt(int m, int n, int k,
        Alpha alpha,
        TA const* A, int ldA,
        TB const* B, int ldB,
        Beta beta,
        TC      * C, int ldC)
{
  using namespace cute;

  // Define shapes (dynamic)
  auto M = int(m);
  auto N = int(n);
  auto K = int(k);
  auto L = int(1);
  auto prob_shape = make_shape(M, N, K, L);                     // (M, N, K, L)

  // Define NT strides (mixed)
  auto dA = make_stride(ldA, Int<1>{});                      // (dM, dK)
  auto dB = make_stride(Int<1>{}, ldB);                      // (dN, dK)
  auto dC = make_stride(ldC, Int<1>{});                      // (dM, dN)

  // Define CTA tile sizes (static)
  auto bM = Int<256>{};
  auto bN = Int<256>{};
  auto bK = Int< 32>{};
  auto cta_tiler = make_shape(bM, bN, bK);                   // (BLK_M, BLK_N, BLK_K)
  auto bP = Int<2>{};  // Pipeline

  // Define the thread layouts (static)

  TiledCopy copyA = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x32x32_LD_N, decltype(dA)>, TA>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 k-major
                                    Layout<Shape<_32,_2>>{});              // Val layout  32x2
  TiledCopy copyB = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U16x32x32_LD_V, decltype(dB)>, TB>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_32,_2>>{});              // Val layout  32x2
  TiledCopy copyC = make_tiled_copy(Copy_Atom<Copy_Traits<XE_2D_U32x8x16_ST_N, decltype(dC)>, TC>{},
                                    Layout<Shape<_1,_16>>{}, // Thr layout 1x16 n-major
                                    Layout<Shape<_8,_1>>{});              // Val layout  8x1

  TiledMMA mmaC = TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<decltype(cta_tiler)>,
                                 Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA{};

  auto dimBlock = syclcompat::dim3(size(mmaC));
  auto dimGrid  = syclcompat::dim3(size(ceil_div(M, bM)), size(ceil_div(N, bN)));

  // Cutlass only support simd_16
  constexpr int SubgroupSize = 16;
  constexpr int smem_size = 0;
  auto kernel_props = [] {
    return syclcompat::experimental::kernel_properties{
      sycl::ext::oneapi::experimental::sub_group_size<SubgroupSize>
    };
  }();
  syclcompat::experimental::launch_properties launch_props {
    sycl::ext::oneapi::experimental::work_group_scratch_size(smem_size),
  };
  syclcompat::experimental::launch_policy policy{
    dimGrid, dimBlock, launch_props, kernel_props
  };
  auto event = syclcompat::experimental::launch<
    gemm_device<decltype(prob_shape), decltype(cta_tiler),
                TA, decltype(dA), decltype(copyA),
                TB, decltype(dB), decltype(copyB),
                TC, decltype(dC), decltype(copyC), decltype(mmaC),
                Alpha, Beta>>(policy, prob_shape, cta_tiler, bP,
                    A, dA, copyA,
                    B, dB, copyB,
                    C, dC, copyC, mmaC,
                    alpha, beta);

  EventManager::getInstance().addEvent(event);
}

template <class TA, class TB, class TC,
          class Alpha, class Beta>
void
gemm(char transA, char transB, int m, int n, int k,
     Alpha alpha,
     TA const* A, int ldA,
     TB const* B, int ldB,
     Beta beta,
     TC      * C, int ldC)
{
  if (transA == 'N' && transB == 'T') {
    return gemm_nt(m, n, k, alpha, A, ldA, B, ldB, beta, C, ldC);
  } else
  if (transA == 'T' && transB == 'N') {
    return gemm_tn(m, n, k, alpha, A, ldA, B, ldB, beta, C, ldC);
  }
  if (transA == 'T' && transB == 'T') {
    return gemm_tt(m, n, k, alpha, A, ldA, B, ldB, beta, C, ldC);
  }
  assert(false && "Not implemented");
}


int main(int argc, char** argv)
{
  int m = 8192;
  if (argc >= 2)
    sscanf(argv[1], "%d", &m);

  int n = 8192;
  if (argc >= 3)
    sscanf(argv[2], "%d", &n);

  int k = 8192;
  if (argc >= 4)
    sscanf(argv[3], "%d", &k);

  char transA = 'T';
  if (argc >= 5)
    sscanf(argv[4], "%c", &transA);

  char transB = 'T';
  if (argc >= 6)
    sscanf(argv[5], "%c", &transB);

  using TA = cute::bfloat16_t;
  using TB = cute::bfloat16_t;
  using TC = float;
  using TI = float;

  TI alpha = 1.0;
  TI beta  = 0.0;

  std::cout << "M = " << m << std::endl;
  std::cout << "N = " << n << std::endl;
  std::cout << "K = " << k << std::endl;
  std::cout << "C = A^" << transA << " B^" << transB << std::endl;

  std::vector<TA> h_A(m*k);
  std::vector<TB> h_B(n*k);
  std::vector<TC> h_C(m*n);
  
  for (int j = 0; j < m*k; ++j) h_A[j] = static_cast<TA>( (rand()%21) - 10 );
  for (int j = 0; j < n*k; ++j) h_B[j] = static_cast<TB>( (rand()%21) - 10 );
  for (int j = 0; j < m*n; ++j) h_C[j] = static_cast<TC>(-1);

  auto d_A = syclcompat::malloc<TA>(m*k);
  auto d_B = syclcompat::malloc<TB>(k*n);
  auto d_C = syclcompat::malloc<TC>(m*n);

  syclcompat::memcpy<TA>(d_A, h_A.data(), m*k);
  syclcompat::memcpy<TB>(d_B, h_B.data(), k*n);
  syclcompat::memcpy<TC>(d_C, h_C.data(), m*n);

  int ldA = 0, ldB = 0, ldC = m;

  if (transA == 'N') {
    ldA = m;
  } else if (transA == 'T') {
    ldA = k;
  } else {
    assert(false);
  }

  if (transB == 'N') {
    ldB = k;
  } else if (transB == 'T') {
    ldB = n;
  } else {
    assert(false);
  }

  ldC = n;

  // Run once
  gemm(transA, transB, m, n, k,
       alpha,
       d_A, ldA,
       d_B, ldB,
       beta,
       d_C, ldC);
  syclcompat::wait_and_throw();

  bool passed = verify(
    d_A,
    d_B,
    d_C,
    m,
    n,
    k,
    alpha,
    beta,
    transA,
    transB
  );
  std::cout << "\n Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

  if(!passed) return -1;

  double tflops = (2.0*m*n*k) * 1e-12;

  const int timing_iterations = 100;
  GPU_Clock timer;

  // Timing iterations
  timer.start();
  for (int i = 0; i < timing_iterations; ++i) {
    gemm(transA, transB, m, n, k,
         alpha,
         d_A, ldA,
         d_B, ldB,
         beta,
         d_C, ldC);
  }
  syclcompat::wait();
  double cute_time = timer.seconds() / timing_iterations;
  printf("CUTE_GEMM:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);

  return 0;
}
