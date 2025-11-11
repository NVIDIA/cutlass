/***************************************************************************************************
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
#include <cute/util/compat.hpp>
#include <sycl/ext/intel/experimental/grf_size_properties.hpp>

#include <cute/tensor.hpp>

#include "cutlass/kernel_hardware_info.h"
#include "cutlass/platform/platform.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/util/sycl_event_manager.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_fill.h"

#include "../../common/sycl_cute_common.hpp"

#pragma clang diagnostic ignored "-Wpass-failed"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

using namespace cute;


template <class ATensor, class BTensor, class CTensor,
          class TiledMMA>
void
gemm_device(ATensor   const& A,         // (M,K)
            BTensor   const& B,         // (N,K)
            CTensor        & C,         // (M,N)
            TiledMMA const & mma)
{
  // -----
  // Setup
  // -----

  /* Get workgroup and local IDs */
  auto item = sycl::ext::oneapi::this_work_item::get_nd_item<2>();
  auto wg_m = int(item.get_group(1));
  auto wg_n = int(item.get_group(0));
  auto local_id = int(item.get_local_id(0));

  /* Create proxy coordinate tensors for each global tensor */
  Tensor cA = make_identity_tensor(A.shape());   // (M,K)
  Tensor cB = make_identity_tensor(B.shape());   // (N,K)
  Tensor cC = make_identity_tensor(C.shape());   // (M,N)

  /* Split GEMM into workgroup tiles, and identify our workgroup's tile (wg_coord) */
  auto wg_tile = mma.tile_mnk();
  auto wg_coord = make_coord(wg_m, wg_n, 0);

  Tensor gA = local_tile(cA, select<0,2>(wg_tile), make_coord(wg_m,_));  // (BLK_M,BLK_K,k)
  Tensor gB = local_tile(cB, select<1,2>(wg_tile), make_coord(wg_n,_));  // (BLK_N,BLK_K,k)
  Tensor gC = local_tile(cC, wg_tile, wg_coord, Step<_1,_1, X>{});       // (BLK_M,BLK_N)

  /* Create block 2D TiledCopies */
  auto copy_a = make_block_2d_copy_A(mma, A);
  auto copy_b = make_block_2d_copy_B(mma, B);
  auto copy_c = make_block_2d_copy_D(mma, C);

  /* Slice TiledCopy/TiledMMA operations to thread (work-item) level */
  auto thr_mma    =    mma.get_slice(local_id);
  auto thr_copy_a = copy_a.get_slice(local_id);
  auto thr_copy_b = copy_b.get_slice(local_id);

  /* Register fragments for MMA */
  auto tCrA = thr_mma.partition_sg_fragment_A(gA(_,_,0));
  auto tCrB = thr_mma.partition_sg_fragment_B(gB(_,_,0));

  /* Register fragments for copies */
  auto tArA = thr_copy_a.partition_sg_fragment_D(gA(_,_,0));
  auto tBrB = thr_copy_b.partition_sg_fragment_D(gB(_,_,0));

  /* Partition global tensor (proxies) for copies */
  Tensor tAgA = thr_copy_a.partition_S(gA);
  Tensor tBgB = thr_copy_b.partition_S(gB);

  /* Partition C */
  Tensor tCrC = partition_fragment_C(mma, select<0,1>(wg_tile));
  Tensor tCgC = thr_mma.partition_C(gC);    /* also matches copy_c's source layout */

  /* Create prefetch TiledCopy instances */
  auto prefetch_a = make_block_2d_prefetch(copy_a);
  auto prefetch_b = make_block_2d_prefetch(copy_b);

  auto thr_prefetch_A = prefetch_a.get_slice(local_id);
  auto thr_prefetch_B = prefetch_b.get_slice(local_id);

  /* Partition global tensor (proxies) for prefetch */
  auto pAgA = thr_prefetch_A.partition_S(gA);
  auto pBgB = thr_prefetch_B.partition_S(gB);

  /* Prefetch distance, in units of k tiles */
  const int prefetch_dist = 3;

  // ------
  // Kernel
  // ------

  constexpr int barrier_scope = 2;

  int k_tile_count = ceil_div(shape<1>(A), get<2>(wg_tile));
  int k_tile_prefetch = 0;

  /* Clear the accumulators */
  clear(tCrC);

  /* Warm up loops with prefetch to L1 */
  CUTE_UNROLL
  for (; k_tile_prefetch < prefetch_dist; k_tile_prefetch++) {
    prefetch(prefetch_a, pAgA(_,_,_,k_tile_prefetch));
    prefetch(prefetch_b, pBgB(_,_,_,k_tile_prefetch));
  }

  /* Main loop */
  for (int k_tile = 0; k_tile < k_tile_count; k_tile++, k_tile_prefetch++) {
    /* Split barrier keeping threads loosely together */
    barrier_arrive(barrier_scope);

    /* Copy A/B from global memory (ideally L1 cache) to registers */
    copy(copy_a, tAgA(_,_,_,k_tile), tArA);
    copy(copy_b, tBgB(_,_,_,k_tile), tBrB);

    /* Prefetch A/B tiles to L1 */
    prefetch(prefetch_a, pAgA(_,_,_,k_tile_prefetch));
    prefetch(prefetch_b, pBgB(_,_,_,k_tile_prefetch));

    /* Shuffle data from copy fragments to MMA fragments */
    reorder(tArA, tCrA);
    reorder(tBrB, tCrB);

    /* Accumulate C += A * B */
    gemm(mma, tCrA, tCrB, tCrC);

    /* Other half of split barrier */
    barrier_wait(barrier_scope);
  }

  /* Write C to global memory */
  copy(copy_c, tCrC, tCgC);
}



template <typename T, size_t = 0>
struct is_complete : std::false_type {};

template <typename T>
struct is_complete<T, 0 * sizeof(T)> : std::true_type {};

template <typename T>
static constexpr bool is_complete_v = is_complete<T>::value;


template <typename TA, typename TB, typename TC>
auto
choose_mma_op()
{
  if constexpr (is_complete_v<XE_DPAS_TT<8, TC, TA, TB>>)
    return XE_DPAS_TT<8, TC, TA, TB>{};
  else if constexpr (is_same_v<TA, cute::bfloat16_t>)
    return XE_DPAS_TT<8, float, cute::bfloat16_t>{};
  else  /* Use f16 by default as upconversion sequences are typically faster */
    return XE_DPAS_TT<8, float, cute::half_t>{};
}

template <class ATensor, class BTensor, class CTensor>
auto
choose_tiled_mma(ATensor const& A, BTensor const& B, CTensor const&)
{
  using TA = typename ATensor::element_type;
  using TB = typename BTensor::element_type;
  using TC = typename CTensor::element_type;

  auto op = choose_mma_op<TA,TB,TC>();

  constexpr bool byte = (cute::max(sizeof_bits_v<TA>, sizeof_bits_v<TB>) <= 8);
  constexpr bool a_t = is_constant_v<1, decltype(stride<0>(A))>;
  constexpr bool b_n = is_constant_v<1, decltype(stride<0>(B))>;

  constexpr bool use_1x_dpas_per_k = a_t                                  // Use one DPAS in k dimension for A^T case
                                  || (byte && b_n);                       //  pending compiler improvements (also int8 B^N).
  constexpr bool use_4x8_sg = ((sizeof_bits_v<TB> < sizeof_bits_v<TA>)    // Use smaller B loads for expensive reorders.
                                  && !(is_same_v<TB, cute::float_e5m2_t>))
                           || (b_n && sizeof_bits_v<TB> < 8);

  using _K = conditional_t<use_1x_dpas_per_k,
                           C<op.K>, C<op.K*2>>;

  using WGTile = Shape<_256, _256, _K>;                               // 256x256 WG tile size
  using SGLayout8x4 = Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>;  // 8x4 SG tiling, n-major
  using SGLayout4x8 = Layout<Shape<_4, _8, _1>, Stride<_8, _1, _0>>;  // 4x8 SG tiling, n-major
  using SGLayout = conditional_t<use_4x8_sg, SGLayout4x8, SGLayout8x4>;

  using MMA = typename TiledMMAHelper<MMA_Atom<decltype(op)>, Layout<WGTile>, SGLayout>::TiledMMA;

  return MMA{};
}

template <class, class, char, char> class GemmCuteName;
template <class ATensor, class BTensor, class CTensor, typename TA, typename TB, char layoutA, char layoutB>
void
gemm_cute(sycl::queue &Q,
          ATensor   const& A,         // (M,K)
          BTensor   const& B,         // (N,K)
          CTensor        & C)         // (M,N)
{
  auto mma = choose_tiled_mma(A, B, C);

  sycl::range<2> local = {size(mma), 1};
  sycl::range<2> global = {local[0] * ceil_div(shape<0>(B), get<1>(mma.tile_mnk())),
                           local[1] * ceil_div(shape<0>(A), get<0>(mma.tile_mnk()))};

  namespace syclex = sycl::ext::oneapi::experimental;
  namespace intelex = sycl::ext::intel::experimental;

  syclex::properties kernel_props {
    syclex::sub_group_size<16>,
    intelex::grf_size<256>
  };

  auto event = Q.parallel_for<GemmCuteName<TA, TB, layoutA, layoutB>>(sycl::nd_range<2>(global, local), kernel_props,
    [=](auto) {
      gemm_device(A, B, C, mma);
    }
  );

  EventManager::getInstance().addEvent(event);
}

template <class...> class GemmVerifyKernelName;
template <class ATensor, class BTensor, class CTensor>
bool
gemm_verify(sycl::queue &Q,
            ATensor const& A,         // (M,K)
            BTensor const& B,         // (N,K)
            CTensor const& C)         // (M,N)
{
  int m = size<0>(A);
  int n = size<0>(B);
  int k = size<1>(A);

  auto ok = sycl::malloc_shared<bool>(1, Q);
  *ok = true;

  Q.parallel_for<GemmVerifyKernelName<ATensor, BTensor, CTensor>>(sycl::range<2>(m, n), [=](sycl::item<2> id) {
    int i = id[0], j = id[1];

    using AccType = typename CTensor::element_type;
    using SignedAccType = ensure_signed_t<AccType>;

    auto c = AccType(0);
    for (int h = 0; h < k; h++)
      c += AccType(A(i,h)) * AccType(B(j,h));

    auto tol = AccType(1e-5f * k);
    if (std::abs(SignedAccType(c - AccType(C(i,j)))) > tol) {
#ifdef SHOW_DIFF
      printf("Error at (%d,%d): got %f, expected %f\n", i, j, double(C(i,j)), double(c));
#endif
      *ok = false;
    }
  }).wait();

  bool read_ok = *ok;

  sycl::free(ok, Q);

  return read_ok;
}

template <typename TA, typename TB, typename TC,
          char layoutA = 'R', char layoutB = 'R'>
void
test_case(sycl::queue &Q, int m, int n, int k)
{
  std::cout << type_str<TA>() << " (" << layoutA << ") x "
            << type_str<TB>() << " (" << layoutB << ") -> "
            << type_str<TC>() << ": \t";

  // Transpose B to match CuTe conventions
  constexpr char tlayoutB = layoutB ^ ('R' ^ 'C');

  // Prepare data:
  auto A = make_shared_usm_tensor<TA,  layoutA>(Q, m, k);
  auto B = make_shared_usm_tensor<TB, tlayoutB>(Q, n, k);
  auto C = make_shared_usm_tensor<TC,      'R'>(Q, m, n);

  random_fill(A);
  random_fill(B);
  zero_fill(C);

#ifndef SKIP_VERIFY
  auto A_ref = make_shared_usm_tensor<float,  layoutA>(Q, m, k);
  auto B_ref = make_shared_usm_tensor<float, tlayoutB>(Q, n, k);

  copy(A, A_ref);
  copy(B, B_ref);
#endif

  subbyte_pack(A);
  subbyte_pack(B);

  // Test accuracy:
  gemm_cute<decltype(A), decltype(B), decltype(C), TA, TB, layoutA, layoutB>(Q, A, B, C);
  Q.wait_and_throw();

#ifdef SKIP_VERIFY
  const bool ok = true;
  std::cout << "verification skipped";
#else
  bool ok = gemm_verify(Q, A_ref, B_ref, C);
  std::cout << (ok ? "passed" : "failed");
#endif

  if (ok) {
    // Test performance:
    const int timing_iterations = 100;
    GPU_Clock timer;

    timer.start();
    for (int i = 0; i < timing_iterations; ++i)
      gemm_cute<decltype(A), decltype(B), decltype(C), TA, TB, layoutA, layoutB>(Q, A, B, C);
    Q.wait_and_throw();

    double avg = timer.seconds() / timing_iterations;
    double tops = (2.0*m*n*k) * 1e-12;

    printf(", %4.3f TF/s", tops / avg, avg*1000);
  }

  free_usm_tensor(A, Q);
  free_usm_tensor(B, Q);
  free_usm_tensor(C, Q);

#ifndef SKIP_VERIFY
  free_usm_tensor(A_ref, Q);
  free_usm_tensor(B_ref, Q);
#endif

  std::cout << '\n';

  // Pause for a short period of time to allow the GPU to cool.
  static bool first = true;
  if (first)
    first = false;
  else
    sleep(1);
}


int main(int argc, char** argv)
{
  auto shift = [&] {
    return (argc-- > 0) ? *argv++ : nullptr;
  };

  auto parse_size = [&] {
    static constexpr int default_size = 4096;
    if (auto e = shift())
      return atoi(e);
    else
      return default_size;
  };

  (void) shift();

  auto m = parse_size();
  auto n = parse_size();
  auto k = parse_size();

  sycl::queue Q = compat::get_default_queue();

  // Native compute
  test_case<tfloat32_t, tfloat32_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<tfloat32_t, tfloat32_t, float, 'R', 'C'>(Q, m, n, k);
  test_case<tfloat32_t, tfloat32_t, float, 'C', 'R'>(Q, m, n, k);

  test_case<half_t, half_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, half_t, float, 'R', 'C'>(Q, m, n, k);
  test_case<half_t, half_t, float, 'C', 'R'>(Q, m, n, k);

  test_case<bfloat16_t, bfloat16_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, bfloat16_t, float, 'R', 'C'>(Q, m, n, k);
  test_case<bfloat16_t, bfloat16_t, float, 'C', 'R'>(Q, m, n, k);

  test_case<int8_t, int8_t, int32_t, 'R', 'R'>(Q, m, n, k);
  test_case<uint8_t, uint8_t, int32_t, 'R', 'C'>(Q, m, n, k);
  test_case<uint8_t, int8_t, int32_t, 'C', 'R'>(Q, m, n, k);

  test_case<int8_t, uint4_t, int32_t, 'R', 'C'>(Q, m, n, k);
  test_case<int4_t, uint8_t, int32_t, 'R', 'C'>(Q, m, n, k);

  test_case<uint4_t, uint4_t, uint32_t, 'R', 'C'>(Q, m, n, k);
  test_case<uint4_t, uint4_t, uint32_t, 'R', 'R'>(Q, m, n, k);

  // Upconversion cases
  test_case<half_t, float_e5m2_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, float_e5m2_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<float_e5m2_t, float_e5m2_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<float_e5m2_t, float_e5m2_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, float_e4m3_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, float_e4m3_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<float_e4m3_t, float_e4m3_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<float_e4m3_t, float_e4m3_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, float_e2m1_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, float_e2m1_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, uint8_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, uint8_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, int8_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, int8_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, uint4_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, uint4_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<half_t, int4_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<half_t, int4_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, float_e5m2_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, float_e5m2_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, float_e4m3_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, float_e4m3_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, float_e2m1_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, float_e2m1_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, uint8_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, uint8_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, int8_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, int8_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, uint4_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, uint4_t, float, 'R', 'C'>(Q, m, n, k);

  test_case<bfloat16_t, int4_t, float, 'R', 'R'>(Q, m, n, k);
  test_case<bfloat16_t, int4_t, float, 'R', 'C'>(Q, m, n, k);
}
