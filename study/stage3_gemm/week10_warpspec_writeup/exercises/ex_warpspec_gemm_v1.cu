/***************************************************************************************************
 * Ex_warpspec_gemm_v1 — 手写 WarpSpec GEMM v1（不用 CollectiveBuilder）
 *
 * ★ 本周 CAPSTONE。脚手架给你：
 *     - host 端配置（TileShape / ClusterShape / pipeline depth）
 *     - device 端的 SharedStorage 布局 + barrier 数组
 *     - producer/consumer warp 分流的入口
 *     - CPU 参考 + 结果比对
 *   ★ 你要填的 TODO (5 块)：
 *     T1) producer：循环发 TMA 装载 A/B（参照 W6 TMA + example 70 的 `load()`）
 *     T2) producer 的 `producer_acquire/commit` 协议
 *     T3) consumer：循环等 mbarrier、单线程 `elect_one` 发 UMMA、`consumer_wait/release`
 *     T4) consumer：epilogue（TMEM 累加器 → gmem）
 *     T5) 把 SM100 / SM120 的 atom 分支补完（B200 主线用 SM100 UMMA；5060 Ti 本地用 SM120 那条）
 *
 * 性能不重要，正确性优先。M=N=K=512 通过 CPU 验证就过 W10。
 *
 * 硬件：
 *   🔴 B200(SM100)：主线。用 `SM100_MMA_F16BF16_SS` UMMA atom，累加器在 TMEM，
 *      单线程 `elect_one` 发 `tcgen05.mma`
 *      —— 关键代码路径在 include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp，
 *         dispatch 类 KernelTmaWarpSpecialized1SmSm100 / 2SmSm100
 *   🟢 5060 Ti(SM120)：本地验证。SM120 没有 UMMA/TMEM，走 mma.sync + RMEM 的 dispatch policy
 *
 * 参考：examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu —— 直接读它的 main loop
 **************************************************************************************************/
#include <cstdio>
#include <cstdlib>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include "cutlass/half.h"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;
using T = cutlass::half_t;

// 你的 GEMM 配置（最小可工作版）
constexpr int BLK_M = 128;
constexpr int BLK_N = 128;
constexpr int BLK_K = 64;
constexpr int STAGES = 2;  // 最小 pipeline depth（producer 和 consumer 能错开一拍）

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED) || 1  // 也允许 SM120 编译路径走进

// --- SharedStorage ----------------------------------------------------------
// 双 buffer（STAGES 个 tile） + full/empty 两组 mbarrier。和 W7 ping-pong 同构。
template <class SmemLayoutA, class SmemLayoutB>
struct SharedStorage {
  alignas(128) cute::ArrayEngine<T, cosize_v<SmemLayoutA>> A;
  alignas(128) cute::ArrayEngine<T, cosize_v<SmemLayoutB>> B;
  alignas(16)  uint64_t full[STAGES];   // producer arrive，consumer wait
  alignas(16)  uint64_t empty[STAGES];  // consumer arrive，producer wait
};

template <class TmaA, class TmaB, class SmemLayoutA, class SmemLayoutB, class TiledMMA>
__global__ static void warpspec_gemm_v1_kernel(
    CUTLASS_GRID_CONSTANT TmaA const tma_a,
    CUTLASS_GRID_CONSTANT TmaB const tma_b,
    T const* A_gmem, T const* B_gmem, T* C_gmem,
    int M, int N, int K,
    SmemLayoutA sA_layout, SmemLayoutB sB_layout, TiledMMA mma)
{
  extern __shared__ char smem_raw[];
  using SS = SharedStorage<SmemLayoutA, SmemLayoutB>;
  SS& smem = *reinterpret_cast<SS*>(smem_raw);

  // warp_idx 分流：warp 0 = producer (发 TMA)，warp 4..7 = consumer (其中单线程 elect_one 发 UMMA)
  // 注意：SM100 的 UMMA 是单线程发射（tcgen05.mma），不像 SM90 那样要整个 warpgroup 一起发 WGMMA
  int warp_idx = threadIdx.x / 32;
  bool is_producer = (warp_idx == 0);
  bool is_consumer = (warp_idx >= 4 && warp_idx < 8);  // consumer warp 组（MMA 由其中 elect_one 单线程发）

  // 初始化 barriers（让一个线程做）
  if (threadIdx.x == 0) {
    for (int s = 0; s < STAGES; ++s) {
      initialize_barrier(smem.full[s],  /*producer arrive 数*/ 1);
      initialize_barrier(smem.empty[s], /*consumer arrive 数*/ 1);  // UMMA 单线程 elect_one 释放
    }
  }
  __syncthreads();

  // k_tile 总数
  int k_tiles = (K + BLK_K - 1) / BLK_K;

  // ============================================================================
  // PRODUCER（warp 0，发 TMA）
  // ============================================================================
  if (is_producer) {
    // TODO(T1) 循环发 TMA 装载 A / B 到 smem buffer s = k % STAGES
    //   提示（参考 W6 ex13 + example 70 的 load()）：
    //     - tma_partition(tma_a, ..., group_modes<0,2>(sA), group_modes<0,2>(gA))
    //     - set_barrier_transaction_bytes(smem.full[s], bytes_a + bytes_b)
    //     - copy(tma_a.with(smem.full[s]), tAgA(_, k_tile), tAsA(_, s))
    //
    // TODO(T2) producer 在覆写 buffer s 之前要等 consumer 释放：
    //     wait_barrier(smem.empty[s], empty_phase);  // 第一轮 STAGES 个 tile 不用等
    //     每次绕回时翻 empty_phase
  }

  // ============================================================================
  // CONSUMER（warp 4..7；UMMA 由其中 elect_one 单线程发，累加器在 TMEM）
  // ============================================================================
  if (is_consumer) {
    // TODO(T3) 循环（累加器 tCtAcc 在 TMEM，不是 RMEM）：
    //   for (int k = 0; k < k_tiles; ++k) {
    //     int s = k % STAGES;
    //     wait_barrier(smem.full[s], full_phase);   // 等 producer 装好
    //     // 单线程发 UMMA（tcgen05.mma）：
    //     if (cute::elect_one_sync()) {
    //       // 第一条 MMA 用 ScaleOut::Zero 清零 TMEM 累加器，后续 One 累加
    //       gemm(mma, tCrA(_,_,_,s), tCrB(_,_,_,s), tCtAcc);  // 见 example 70 的 mma()
    //       cutlass::arch::umma_arrive(&smem.empty[s]);        // MMA 完成绑定到 mbarrier
    //     }
    //     如果绕回 STAGES 翻 full_phase
    //   }
    //   注意：UMMA 不再需要 warpgroup_fence/arrive/commit/wait —— 由 mbarrier + umma_arrive 同步
    //
    // TODO(T4) epilogue：把 TMEM 累加器 tCtAcc 经 tcgen05.ld 搬回 RMEM 再写 gC（最朴素直写）
    //   TiledCopy t2r = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tCtAcc);
    //   ... TMEM -> RMEM -> GMEM（参考 W8 TMEM round-trip）
  }
}

#endif

void cpu_gemm(thrust::host_vector<T> const& A, thrust::host_vector<T> const& B,
              thrust::host_vector<float>& C, int M, int N, int K) {
  for (int m = 0; m < M; ++m)
    for (int n = 0; n < N; ++n) {
      float acc = 0.f;
      for (int k = 0; k < K; ++k) acc += float(A[m*K+k]) * float(B[n*K+k]);
      C[m*N+n] = acc;
    }
}

int main(int argc, char** argv) {
  int M = argc > 1 ? atoi(argv[1]) : 512;
  int N = argc > 2 ? atoi(argv[2]) : 512;
  int K = argc > 3 ? atoi(argv[3]) : 512;

  cudaDeviceProp props; cudaGetDeviceProperties(&props, 0);
  // B200(SM100) 主线 UMMA+TMEM；SM120 走 mma.sync 退化路径（本地验证）
  if (props.major < 10) { printf("v1 主线需要 Blackwell SM100+。当前 SM%d%d（SM120 本地可走退化路径）。\n", props.major, props.minor); return 0; }

  thrust::host_vector<T> hA(M*K), hB(N*K);
  for (int i = 0; i < M*K; ++i) hA[i] = T(float((rand()%5)-2));
  for (int i = 0; i < N*K; ++i) hB[i] = T(float((rand()%5)-2));
  thrust::device_vector<T> dA = hA, dB = hB;
  thrust::device_vector<T> dC(M*N);

  // TODO(T5)：在这里实例化 SmemLayoutA/B（swizzle K-major）、TiledMMA、TMA descriptor，
  //           然后 launch warpspec_gemm_v1_kernel。每个 typedef 在 example 70 都能找到对应。
  printf("v1 脚手架就位。完成 TODO(T1..T5) 后，请打开下面这块的注释跑 CPU 验证。\n");

  /*  // 完成后取消注释 ↓
  thrust::host_vector<T> hC = dC;
  thrust::host_vector<float> ref(M*N);
  cpu_gemm(hA, hB, ref, M, N, K);
  float max_err = 0.f;
  for (int i = 0; i < M*N; ++i) max_err = fmaxf(max_err, fabsf(float(hC[i]) - ref[i]));
  printf("v1 max abs error = %.3f -> %s\n", max_err, (max_err < 1.f) ? "PASSED ✓ W10 通过" : "FAILED");
  */
  return 0;
}
