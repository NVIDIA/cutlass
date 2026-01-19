/***************************************************************************************************
* Copyright (C) 2026 Intel Corporation, All rights reserved.
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
#include "cutlass/util/command_line.h"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_fill.h"

#include "../../common/sycl_cute_common.hpp"

#if defined(__clang__)
  #pragma clang diagnostic ignored "-Wpass-failed"
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
#elif defined(__GNUC__)
  #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

using namespace cute;
// Command line options parsing
struct Options {

  bool help;
  bool error;

  int m, n, k, iterations, verify;

  Options():
    help(false),
    error(false),
    m(4096), n(4096), k(4096), iterations(100)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m, 4096);
    cmd.get_cmd_line_argument("n", n, 4096);
    cmd.get_cmd_line_argument("k", k, 4096);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "GEMM Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

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
  using TA = typename ATensor::element_type;
  using TB = typename BTensor::element_type;
  auto coop_copy_a = make_coop_block_2d_copy_A(mma, A);
  auto coop_copy_b = make_coop_block_2d_copy_B(mma, B);
  // TODO: generate proper subgroup tensors
  auto coop_copy_a_ = make_coop_block_2d_copy_A(mma, make_tensor(A.data(), make_layout(shape(A), LayoutRight{})));
  auto coop_copy_b_ = make_coop_block_2d_copy_B(mma, make_tensor(B.data(), make_layout(shape(B), LayoutRight{})));
  auto [r2s_A, s2r_A] = make_A_slm_copies(mma, coop_copy_a);
  auto [r2s_B, s2r_B] = make_B_slm_copies(mma, coop_copy_b);
  auto copy_c = make_block_2d_copy_D(mma, C);

  // Shared memory buffers
  constexpr auto stages = 2;
  Layout a_slm_layout = make_layout(append<3>(typename decltype(r2s_A)::Tiler_MN{}, Int<stages>{}));
  Layout b_slm_layout = make_layout(append<3>(typename decltype(r2s_B)::Tiler_MN{}, Int<stages>{}));

  auto smemA = compat::local_mem<TA[size(a_slm_layout)]>();
  auto smemB = compat::local_mem<TB[size(b_slm_layout)]>();

  Tensor sA = make_tensor(make_smem_ptr(smemA), a_slm_layout);
  Tensor sB = make_tensor(make_smem_ptr(smemB), b_slm_layout);

  /* Slice TiledCopy/TiledMMA operations to thread (work-item) level */
  auto thr_mma    =    mma.get_slice(local_id);
  auto coop_thr_copy_a = coop_copy_a.get_slice(local_id);
  auto coop_thr_copy_b = coop_copy_b.get_slice(local_id);
  auto coop_thr_copy_a_ = coop_copy_a_.get_slice(local_id);
  auto coop_thr_copy_b_ = coop_copy_b_.get_slice(local_id);
  auto thr_r2s_A = r2s_A.get_slice(local_id);
  auto thr_r2s_B = r2s_B.get_slice(local_id);
  auto thr_s2r_A = s2r_A.get_slice(local_id);
  auto thr_s2r_B = s2r_B.get_slice(local_id);
  

  /* Register fragments for MMA */
  auto tCrA = thr_mma.partition_sg_fragment_A(gA(_,_,0));
  auto tCrB = thr_mma.partition_sg_fragment_B(gB(_,_,0));

  /* Register fragments for copies */
  auto tArA_in = coop_thr_copy_a.partition_sg_fragment_D(gA(_,_,0));
  auto tBrB_in = coop_thr_copy_b.partition_sg_fragment_D(gB(_,_,0));
  auto tArA_in_ = coop_thr_copy_a_.partition_sg_fragment_D(gA(_,_,0));
  auto tBrB_in_ = coop_thr_copy_b_.partition_sg_fragment_D(gB(_,_,0));
  auto tAsA_out = thr_r2s_A.partition_D(sA);
  auto tBsB_out = thr_r2s_B.partition_D(sB);
  auto tArA_out = thr_r2s_A.retile_S(tArA_in_);
  auto tBrB_out = thr_r2s_B.retile_S(tBrB_in_);
  auto tAsA_in = thr_s2r_A.partition_S(sA);
  auto tBsB_in = thr_s2r_B.partition_S(sB);
  auto tCrA_in = thr_s2r_A.retile_D(tCrA);
  auto tCrB_in = thr_s2r_B.retile_D(tCrB);
  
  /* Partition global tensor (proxies) for copies */
  Tensor tAgA = coop_thr_copy_a.partition_S(gA);
  Tensor tBgB = coop_thr_copy_b.partition_S(gB);

  /* Partition C */
  Tensor tCrC = partition_fragment_C(mma, select<0,1>(wg_tile));
  Tensor tCgC = thr_mma.partition_C(gC);    /* also matches copy_c's source layout */

  // ------
  // Kernel
  // ------

  int k_tile_count = ceil_div(shape<1>(A), get<2>(wg_tile));
  int k_tile_prefetch = 0;
  /* Clear the accumulators */
  clear(tCrC);

  /* Warm up loops with prefetch to SLM */
  CUTE_UNROLL
  for (; k_tile_prefetch < stages; k_tile_prefetch++) {
    // Global -> registers load
    copy(coop_copy_a, tAgA(_,_,_,k_tile_prefetch), tArA_in);
    copy(coop_copy_b, tBgB(_,_,_,k_tile_prefetch), tBrB_in);

    // Reorder input to output fragments, and write to SLM
    reorder(tArA_in, tArA_in_);
    reorder(tBrB_in, tBrB_in_);
    copy(r2s_A, tArA_out, tAsA_out(_,_,_,k_tile_prefetch));
    copy(r2s_B, tBrB_out, tBsB_out(_,_,_,k_tile_prefetch));
    // Barrier, with memory fence
    barrier_arrive(SPIRVScope::ScopeWorkgroup, SPIRVMemorySemantics::SemanticsRelease | SPIRVMemorySemantics::SemanticsWGMemory);
    barrier_wait(SPIRVScope::ScopeWorkgroup, SPIRVMemorySemantics::SemanticsAcquire | SPIRVMemorySemantics::SemanticsWGMemory);
  }
  /* Main loop */
  for (int k_tile = 0; k_tile < k_tile_count; k_tile++, k_tile_prefetch++) {
    // Load SLM -> registers
    copy(s2r_A, tAsA_in(_,_,_,k_tile%stages), tCrA_in);
    copy(s2r_B, tBsB_in(_,_,_,k_tile%stages), tCrB_in);

    // // Multiply
    gemm(mma, tCrA, tCrB, tCrC);
    // Barrier, with memory fence
    barrier_arrive(SPIRVScope::ScopeWorkgroup, SPIRVMemorySemantics::SemanticsRelease | SPIRVMemorySemantics::SemanticsWGMemory);
    barrier_wait(SPIRVScope::ScopeWorkgroup, SPIRVMemorySemantics::SemanticsAcquire | SPIRVMemorySemantics::SemanticsWGMemory);
    if(k_tile_prefetch < k_tile_count) {
      // Global -> registers load
      copy(coop_copy_a, tAgA(_,_,_,k_tile_prefetch), tArA_in);
      copy(coop_copy_b, tBgB(_,_,_,k_tile_prefetch), tBrB_in);

      // Reorder input to output fragments, and write to SLM
      reorder(tArA_in, tArA_in_);
      reorder(tBrB_in, tBrB_in_);
      copy(r2s_A, tArA_out, tAsA_out(_,_,_,k_tile_prefetch%stages));
      copy(r2s_B, tBrB_out, tBsB_out(_,_,_,k_tile_prefetch%stages));
    }
  }

  /* Write C to global memory */
  copy(copy_c, tCrC, tCgC);
}

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

  constexpr bool use_4x8_sg = ((sizeof_bits_v<TB> < sizeof_bits_v<TA>)    // Use smaller B loads for expensive reorders.
                                  && !(is_same_v<TB, cute::float_e5m2_t>))
                           || (b_n && sizeof_bits_v<TB> < 8);

  using WGTile = Shape<_256, _256,  C<op.K * 2>>;                               // 256x256 WG tile size
  using SGLayout8x4 = Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>;  // 8x4 SG tiling, n-major

  using SGLayout = SGLayout8x4;

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
test_case(sycl::queue &Q, int m, int n, int k, int iterations)
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

  auto A_ref = make_shared_usm_tensor<float,  layoutA>(Q, m, k);
  auto B_ref = make_shared_usm_tensor<float, tlayoutB>(Q, n, k);

  copy(A, A_ref);
  copy(B, B_ref);

  subbyte_pack(A);
  subbyte_pack(B);

  // Test accuracy:
  gemm_cute<decltype(A), decltype(B), decltype(C), TA, TB, layoutA, layoutB>(Q, A, B, C);
  Q.wait_and_throw();

  bool ok = gemm_verify(Q, A_ref, B_ref, C);
  std::cout << (ok ? "passed" : "failed");

  if (ok) {
    // Test performance:
    const int timing_iterations = iterations;
    GPU_Clock timer;

    timer.start();
    for (int i = 0; i < timing_iterations; ++i)
      gemm_cute<decltype(A), decltype(B), decltype(C), TA, TB, layoutA, layoutB>(Q, A, B, C);
    Q.wait_and_throw();

    double avg = timer.seconds() / timing_iterations;
    double tops = (2.0*m*n*k) * 1e-12;
    double io = (m * k * sizeof(TA) + n * k * sizeof(TB) +
                 m * n * sizeof(TC)) * 1e-9;
    printf(", [%4.3f]GB/s, %4.3f TF/s", io / avg, tops / avg, avg*1000);
  }

  free_usm_tensor(A, Q);
  free_usm_tensor(B, Q);
  free_usm_tensor(C, Q);

  free_usm_tensor(A_ref, Q);
  free_usm_tensor(B_ref, Q);

  std::cout << '\n';

  // Pause for a short period of time to allow the GPU to cool.
  static bool first = true;
  if (first)
    first = false;
  else
    sleep(1);
}

int main(int argc, const char** argv)
{
  //
  // Parse options
  //

  Options options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  sycl::queue Q = compat::get_default_queue();

  // Native compute
  test_case<tfloat32_t, tfloat32_t, float, 'R', 'R'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<tfloat32_t, tfloat32_t, float, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<tfloat32_t, tfloat32_t, float, 'C', 'R'>(Q, options.m, options.n, options.k, options.iterations);

  test_case<half_t, half_t, float, 'R', 'R'>(Q,  options.m, options.n, options.k, options.iterations);
  test_case<half_t, half_t, float, 'R', 'C'>(Q,  options.m, options.n, options.k, options.iterations);
  test_case<half_t, half_t, float, 'C', 'R'>(Q,  options.m, options.n, options.k, options.iterations);

  test_case<bfloat16_t, bfloat16_t, float, 'R', 'R'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<bfloat16_t, bfloat16_t, float, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<bfloat16_t, bfloat16_t, float, 'C', 'R'>(Q, options.m, options.n, options.k, options.iterations);

  test_case<int8_t, int8_t, int32_t, 'R', 'R'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<uint8_t, uint8_t, int32_t, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<uint8_t, int8_t, int32_t, 'C', 'R'>(Q, options.m, options.n, options.k, options.iterations);

  test_case<int8_t, uint4_t, int32_t, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<int4_t, uint8_t, int32_t, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);

  test_case<uint4_t, uint4_t, uint32_t, 'R', 'C'>(Q, options.m, options.n, options.k, options.iterations);
  test_case<uint4_t, uint4_t, uint32_t, 'R', 'R'>(Q, options.m, options.n, options.k, options.iterations);
}
