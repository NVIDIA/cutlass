/***************************************************************************************************
 * Ex_warpspec_gemm_v3_pingpong — 在 v2 基础上加 ping-pong 切换
 *
 * 与 v2 的差异（**只改这几处**）：
 *   1) 2 个 consumer warpgroup（不是 1 个）：warp 4..7 = WG0，warp 8..11 = WG1
 *   2) 两个 WG 各自有独立的 accumulator（register 各一份），算不同 tile
 *   3) Tile 分配：WG0 算偶数 tile（0,2,4,...），WG1 算奇数 tile（1,3,5,...）
 *   4) full/empty barrier 数量翻倍：每个 WG 一组（共 2 × STAGES × 2 = 4 × STAGES 个）
 *   5) KernelSchedule 等价于 cutlass 里的 `KernelTmaWarpSpecializedPingpong{Sm120}`
 *
 * 适用场景（README 已列）：
 *   ✓ 大矩阵（M、N 都大）：两个 WG 各算一个 tile，两条 WGMMA 流并发
 *   ✗ M=128 这种短 M：tile 数太少，两个 WG 一人一半反而冷启动多
 *
 * 脚手架给你的：host driver、SharedStorage 布局（含 2×STAGES 组 barrier）、warp 分流
 * 留给你的 TODO（与 v1 共用大部分逻辑，只改 tile 分配）：
 *   T1) producer：参照 v2，但要发到两个 WG 的对应 buffer 上（barrier index 翻倍）
 *   T2) WG0 / WG1：各自的 main loop，tile 步长 = 2（隔一个）
 *   T3) epilogue：两个 WG 各自写自己的 (m_tile, n_tile) 区域
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

constexpr int BLK_M = 128;
constexpr int BLK_N = 128;
constexpr int BLK_K = 64;
constexpr int STAGES = 4;        // 来自 v2
constexpr int NUM_WG = 2;        // Pingpong 的核心：2 个 consumer warpgroup

template <class SmemLayoutA, class SmemLayoutB>
struct SharedStorage {
  alignas(128) cute::ArrayEngine<T, cosize_v<SmemLayoutA>> A;
  alignas(128) cute::ArrayEngine<T, cosize_v<SmemLayoutB>> B;
  // 每个 WG 一组 full/empty barrier
  alignas(16) uint64_t full [NUM_WG][STAGES];
  alignas(16) uint64_t empty[NUM_WG][STAGES];
};

// 主体省略：把 v2 kernel 复制过来，做下述 5 处改动后保存
// （完整脚手架太长，保留为指导性 stub；真正的 producer/consumer 体写在你自己的版本里）
template <class ...>
__global__ static void warpspec_gemm_v3_pingpong_kernel(/* 同 v2 但 barrier 多一维 wg */) {
  // warp_idx 分流
  int warp_idx = threadIdx.x / 32;
  bool is_producer = (warp_idx == 0);
  int  wg = -1;  // -1=producer, 0=WG0, 1=WG1
  if (warp_idx >= 4  && warp_idx < 8)  wg = 0;
  if (warp_idx >= 8  && warp_idx < 12) wg = 1;

  // TODO(T1) producer 发 TMA 时要 round-robin 到两个 WG 的对应 buffer
  //   for (k = 0; k < k_tiles; ++k) {
  //     int target_wg = (m_tile_for(k) % NUM_WG);  // 简化：偶数 tile 给 WG0
  //     int s = (k / NUM_WG) % STAGES;
  //     wait_barrier(empty[target_wg][s], ...);
  //     发 TMA -> arrive full[target_wg][s]
  //   }
  //
  // TODO(T2) WG0 / WG1 各自循环，步长 = NUM_WG
  //   for (k = wg; k < k_tiles; k += NUM_WG) { 等 full[wg][s], 发 WGMMA, arrive empty[wg][s] }
  //
  // TODO(T3) epilogue：WG0 写自己对应的 (m,n) tile，WG1 同理（不同 m_tile / n_tile）
}

int main(int argc, char** argv) {
  int M = argc > 1 ? atoi(argv[1]) : 4096;
  int N = argc > 2 ? atoi(argv[2]) : 4096;
  int K = argc > 3 ? atoi(argv[3]) : 4096;
  printf("v3 pingpong 脚手架 (M=%d N=%d K=%d)。完成 TODO(T1..T3) 后接 CPU 验证。\n", M, N, K);
  return 0;
}
