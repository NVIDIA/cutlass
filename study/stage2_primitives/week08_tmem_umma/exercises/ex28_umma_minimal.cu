/***************************************************************************************************
 * Ex28 — 最小 UMMA：单 CTA 跑一块 tcgen05.mma（SM100）
 *
 * 这是 examples/cute/tutorial/blackwell/01_mma_sm100.cu 的「瘦身导读版」：
 *   保留它最小的单 MMA-tile 形态（cluster 1x1、cta_group::1、无 TMA、用 cooperative_copy 喂数），
 *   砍掉多 tile 网格，把 UMMA 相对 WGMMA 的 4 个关键差异用注释标出来。目的是对照 W5 的 ex11，
 *   一眼看清 SM90→SM100 的迁移点：
 *     ① 发起：warpgroup(128) → 单线程(elect_one_warp)
 *     ② 累加器：RMEM(warpgroup spread) → TMEM（必须 alloc）
 *     ③ 同步：wgmma.fence/commit/wait → umma_arrive + mbarrier(wait_barrier)
 *     ④ epilogue：直接读 RMEM → 必须先 tcgen05.ld 把 TMEM 搬回 RMEM
 *
 * MMA：tcgen05.mma.f16（F16xF16=F32），单条做 128x256x16；K=64 => 内部 4 次累加。
 *
 * 硬件：🔴 仅 B200(sm_100a)。5060 Ti(SM120) 无 UMMA/TMEM —— 非 SM100 上 return 0。
 *   静态看 PTX：nvcc -arch=sm_100a -ptx ex28_umma_minimal.cu && grep "tcgen05.mma\|tcgen05.ld" *.ptx
 **************************************************************************************************/
#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include <cute/algorithm/cooperative_copy.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>
#include "cutlass/arch/barrier.h"
#include "cutlass/util/helper_cuda.hpp"
#include "cutlass/half.h"

using namespace cute;

using TA = cutlass::half_t;
using TB = cutlass::half_t;
using TC = float;

// 单 MMA-tile 尺寸（tcgen05.mma.f16 的原生 128x256x16，K 用 4 个 block => 64）
constexpr int GM = 128, GN = 256, GK = 64;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

template <class SmemA, class SmemB, class TiledMMA, class MmaTiler>
struct SharedStorage {
  alignas(128) cute::ArrayEngine<TA, cosize_v<SmemA>> A;
  alignas(128) cute::ArrayEngine<TB, cosize_v<SmemB>> B;
  alignas(16)  uint64_t  mma_barrier;
  alignas(16)  uint32_t  tmem_base_ptr;
};

template <class ATensor, class BTensor, class CTensor,
          class MmaTiler, class TiledMMA, class SmemA, class SmemB>
__global__ static void umma_kernel(ATensor mA, BTensor mB, CTensor mC,
                                    MmaTiler mma_tiler, TiledMMA tiled_mma,
                                    SmemA sA_layout, SmemB sB_layout)
{
  using SS = SharedStorage<SmemA, SmemB, TiledMMA, MmaTiler>;
  extern __shared__ char smem_raw[];
  SS& smem = *reinterpret_cast<SS*>(smem_raw);

  // gA/gB/gC：本练习单 tile，直接整块
  Tensor gA = mA;  Tensor gB = mB;  Tensor gC = mC;

  Tensor sA = make_tensor(make_smem_ptr(smem.A.begin()), sA_layout);
  Tensor sB = make_tensor(make_smem_ptr(smem.B.begin()), sB_layout);

  // CTA-level partition（SM100 是 cluster-local MMA，单 CTA 时 slice(0)）
  ThrMMA cta_mma = tiled_mma.get_slice(0);
  Tensor tCsA = sA;  // 这里 sA_layout 已是 post-partition 形状
  Tensor tCsB = sB;
  Tensor tCgC = cta_mma.partition_C(gC);

  Tensor tCrA = cta_mma.make_fragment_A(tCsA);  // smem descriptor（A 从 SMEM 读）
  Tensor tCrB = cta_mma.make_fragment_B(tCsB);  // smem descriptor（B 从 SMEM 读）

  // ② 累加器在 TMEM：先 alloc，再把 base 填进 fragment_C ----------------------
  Tensor tCtAcc = cta_mma.make_fragment_C(tCgC);  // TMEM 张量（地址待填）
  bool elect_one_warp = (threadIdx.x / 32 == 0);
  uint32_t elect_one_thr = elect_one_sync();
  using TmemAllocator = cute::TMEM::Allocator1Sm;
  TmemAllocator tmem_allocator{};
  if (elect_one_warp) {
    tmem_allocator.allocate(TmemAllocator::Sm100TmemCapacityColumns, &smem.tmem_base_ptr);
  }
  __syncthreads();
  tCtAcc.data() = smem.tmem_base_ptr;

  // ③ mbarrier 初始化（UMMA 完成用 mbarrier 通知，而非 wgmma.wait）------------
  if (elect_one_warp && elect_one_thr) {
    cute::initialize_barrier(smem.mma_barrier, /*num_ctas*/ 1);
  }
  int phase = 0;
  __syncthreads();

  // ---- 喂数：gmem -> smem（cooperative_copy 自动向量化，128 线程协作）--------
  cooperative_copy<128>(threadIdx.x, gA, sA);
  cooperative_copy<128>(threadIdx.x, gB, sB);
  __syncthreads();

  // ① 发起：单线程语义。只让 warp0 进入，cute 内部用 elect_one 选唯一线程发 tcgen05.mma
  tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;  // 第一条 MMA 清零 TMEM 累加器
  if (elect_one_warp) {
    for (int kb = 0; kb < size<2>(tCrA); ++kb) {
      gemm(tiled_mma, tCrA(_,_,kb), tCrB(_,_,kb), tCtAcc);
      tiled_mma.accumulate_ = UMMA::ScaleOut::One;
    }
    cutlass::arch::umma_arrive(&smem.mma_barrier);  // MMA 完成 -> arrive mbarrier
  }
  cute::wait_barrier(smem.mma_barrier, phase);       // 全员等 MMA 落地

  // ④ epilogue：必须 tcgen05.ld 把 TMEM 累加器搬回 RMEM 再写 gmem -------------
  TiledCopy t2r = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tCtAcc);
  ThrCopy   thr_t2r = t2r.get_slice(threadIdx.x);
  Tensor tDtAcc = thr_t2r.partition_S(tCtAcc);
  Tensor tDgC   = thr_t2r.partition_D(tCgC);
  Tensor tDrAcc = make_tensor<TC>(shape(tDgC));
  copy(t2r, tDtAcc, tDrAcc);     // TMEM -> RMEM
  copy(tDrAcc, tDgC);            // RMEM -> gmem
  __syncthreads();

  if (elect_one_warp) {
    tmem_allocator.release_allocation_lock();
    tmem_allocator.free(smem.tmem_base_ptr, TmemAllocator::Sm100TmemCapacityColumns);
  }
}

#endif

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major != 10) {
    printf("Ex28 需要 Blackwell SM100(sm_100a)。当前 SM%d%d，跳过实跑。\n", props.major, props.minor);
    printf("静态看 PTX：nvcc -arch=sm_100a -ptx ex28_umma_minimal.cu && grep tcgen05.mma *.ptx\n");
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  // A:(M,K) K-major, B:(N,K) K-major, C:(M,N) N-major（TN GEMM）
  auto layout_A = make_layout(make_shape(Int<GM>{}, Int<GK>{}), make_stride(Int<GK>{}, _1{}));
  auto layout_B = make_layout(make_shape(Int<GN>{}, Int<GK>{}), make_stride(Int<GK>{}, _1{}));
  auto layout_C = make_layout(make_shape(Int<GM>{}, Int<GN>{}), make_stride(Int<GN>{}, _1{}));

  thrust::host_vector<TA> hA(GM*GK); thrust::host_vector<TB> hB(GN*GK);
  for (int i = 0; i < GM*GK; ++i) hA[i] = TA(float((i % 5) - 2));
  for (int i = 0; i < GN*GK; ++i) hB[i] = TB(float((i % 5) - 2));
  thrust::device_vector<TA> dA = hA; thrust::device_vector<TB> dB = hB;
  thrust::device_vector<TC> dC(GM*GN);

  Tensor mA = make_tensor(make_gmem_ptr(dA.data().get()), layout_A);
  Tensor mB = make_tensor(make_gmem_ptr(dB.data().get()), layout_B);
  Tensor mC = make_tensor(make_gmem_ptr(dC.data().get()), layout_C);

  TiledMMA tiled_mma = make_tiled_mma(
      SM100_MMA_F16BF16_SS<TA, TB, TC, GM, GN, UMMA::Major::K, UMMA::Major::K>{});

  auto mma_tiler = make_shape(Int<GM>{}, Int<GN>{}, Int<GK>{});
  auto mma_shape_A = partition_shape_A(tiled_mma, make_shape(Int<GM>{}, Int<GK>{}));
  auto mma_shape_B = partition_shape_B(tiled_mma, make_shape(Int<GN>{}, Int<GK>{}));
  auto sA_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TA>{}, mma_shape_A);
  auto sB_layout = UMMA::tile_to_mma_shape(UMMA::Layout_K_SW128_Atom<TB>{}, mma_shape_B);

  using SS = SharedStorage<decltype(sA_layout), decltype(sB_layout), decltype(tiled_mma), decltype(mma_tiler)>;
  int smem_bytes = sizeof(SS);
  auto* kernel = &umma_kernel<decltype(mA), decltype(mB), decltype(mC),
                              decltype(mma_tiler), decltype(tiled_mma),
                              decltype(sA_layout), decltype(sB_layout)>;
  cudaFuncSetAttribute(kernel, cudaFuncAttributeMaxDynamicSharedMemorySize, smem_bytes);

  kernel<<<1, 128, smem_bytes>>>(mA, mB, mC, mma_tiler, tiled_mma, sA_layout, sB_layout);
  CUTE_CHECK_LAST();

  thrust::host_vector<TC> hC = dC;
  float max_err = 0.f;
  for (int m = 0; m < GM; ++m)
    for (int n = 0; n < GN; ++n) {
      float acc = 0.f;
      for (int k = 0; k < GK; ++k) acc += float(hA[m*GK+k]) * float(hB[n*GK+k]);
      max_err = fmaxf(max_err, fabsf(acc - hC[m*GN+n]));
    }
  printf("UMMA max abs error = %.3f -> %s\n", max_err, (max_err < 1e-1f) ? "PASS" : "FAIL");
#else
  printf("CUTLASS_ARCH_MMA_SM100_SUPPORTED 未开启，跳过。\n");
#endif
  return 0;
}
