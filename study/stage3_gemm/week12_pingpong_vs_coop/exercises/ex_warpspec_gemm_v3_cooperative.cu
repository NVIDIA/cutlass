/***************************************************************************************************
 * Ex_warpspec_gemm_v3_cooperative — 在 v2 基础上加 Cooperative 切换
 *
 * 与 Pingpong 的核心差异（这是 W12 的最大学习点）：
 *   Pingpong：    2 个 WG 算 **不同** tile，accumulator 各一份
 *   Cooperative： 2 个 WG 协同算 **同一个** tile，每个 WG 负责一半（典型：M 维各 64）
 *                 accumulator 在 register 里分开存 → epilogue 时不需要 reduce（M 维互斥）
 *
 * 实现要点：
 *   1) 仍是 2 个 consumer warpgroup，但 tile_M 翻倍到 BLK_M=256，每个 WG 负责 64 行
 *   2) TiledMMA 用 ClusterTileShape 配合 AtomThrID = <2,1,1>（atom 跨 2 个 warpgroup）
 *   3) full/empty barrier：每个 WG **共享** 同一组（因为算同一 tile） → 只需 STAGES 个，
 *      但 full barrier 的 arrive count = 1（仍是 producer），
 *      empty barrier 的 arrive count = 256（2 个 WG = 256 线程一起释放）
 *   4) KernelSchedule 等价于 `KernelTmaWarpSpecializedCooperative{Sm120}`
 *
 * 适用场景：
 *   ✓ M 小或 batch 小：单个 tile 就要 2 个 WG 才能填满算力
 *   ✓ K 大：每个 WG 干活时间长，调度开销摊得开
 *   ✗ M、N 都大：用 Pingpong 直接算两个不同 tile 更高吞吐
 *
 * 留给你的 TODO（比 Pingpong 简单一些，因为 tile 不需要分配）：
 *   T1) producer：完全和 v2 一样（一组 barrier，发 TMA 喂同一个 tile）
 *   T2) WG0 / WG1：算同一 tile 的不同 M 段（WG0 = m∈[0,64), WG1 = m∈[64,128)）
 *   T3) 关键：empty barrier 的 arrive count = 256，两个 WG 都 arrive 后 producer 才能覆写
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

constexpr int BLK_M = 256;   // Cooperative 用更大的 M tile，每个 WG 算一半
constexpr int BLK_N = 128;
constexpr int BLK_K = 64;
constexpr int STAGES = 4;

template <class ...>
__global__ static void warpspec_gemm_v3_cooperative_kernel(/* 同 v2，barrier arrive count 改变 */) {
  int warp_idx = threadIdx.x / 32;
  bool is_producer = (warp_idx == 0);
  int  wg = -1;
  if (warp_idx >= 4  && warp_idx < 8)  wg = 0;
  if (warp_idx >= 8  && warp_idx < 12) wg = 1;

  // TODO(T1) producer 完全照搬 v2（一组 barrier，喂同一 tile）
  //   关键：initialize_barrier(empty[s], 256) —— 2 个 WG 各 128 个线程
  //
  // TODO(T2) WG0 负责 m_offset = 0 ~ 63，WG1 负责 m_offset = 64 ~ 127
  //   WG0 thr_mma 的 partition 在 sA 上偏移 0 行
  //   WG1 thr_mma 的 partition 在 sA 上偏移 64 行
  //   两个 WG 同步发 WGMMA（每个 WG 一条 SM90_64xNx16 atom，刚好 64 行）
  //
  // TODO(T3) 两个 WG arrive 同一个 empty[s] 后，producer 才能覆写
  //   这就是 "Cooperative accumulator 不需要 reduce" 的本质：M 维度本就互斥
}

int main(int argc, char** argv) {
  int M = argc > 1 ? atoi(argv[1]) : 4096;
  int N = argc > 2 ? atoi(argv[2]) : 4096;
  int K = argc > 3 ? atoi(argv[3]) : 4096;
  printf("v3 cooperative 脚手架 (M=%d N=%d K=%d)。完成 TODO(T1..T3) 后接 CPU 验证。\n", M, N, K);
  return 0;
}
