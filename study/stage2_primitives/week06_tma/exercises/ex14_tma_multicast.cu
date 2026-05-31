/***************************************************************************************************
 * Ex14 — TMA multicast：一次 gmem 读，分发到 cluster 内多个 CTA 的 smem
 *
 * 目标：
 *   1. 理解 multicast：cp.async.bulk.tensor.multicast 一条指令把同一块 gmem 数据
 *      同时写进 cluster 内多个 CTA 的 smem（典型用法：GEMM 里 B 在 N 方向被多个 CTA 共享）
 *   2. 看 make_tma_copy 的 multicast 版（带 cluster layout）和 tma_partition 的 multicast 参数
 *   3. 验证 cluster 内每个 CTA 都拿到同一份数据
 *
 * 硬件：🟢 5060 Ti(SM120) 可跑，但 cluster size 上限可能比 H100/B200 小。
 *   本练习用 cluster=2（最小有意义的 multicast），SM120 应支持。
 *   ⚠️ 若 launch 报 cluster 不支持，把 CLUSTER_N 调回 1（退化成普通 TMA，multicast 失效）。
 *
 * multicast vs 普通 TMA 的关键差别：
 *   普通：  copy(tma.with(mbar), gA, sA)               每个 CTA 各读各的
 *   multi： copy(tma.with(mbar, mcast_mask), gA, sA)    一次读，按 mask 分发到多个 CTA
 *   收益：  大 K / 多 CTA 共享同一 operand 时，gmem 读带宽降为 1/CLUSTER（L1 流量也降）
 *
 * 跑：
 *   ./study_stage2_w06_ex14_tma_multicast
 *   ncu 看 dram__bytes_read.sum：multicast 下应约为 单 CTA 数据量（而非 ×CLUSTER）
 *
 * 自检：multicast 适合 A 还是 B？为什么大 K 时收益大？（README 自检 Q5）
 **************************************************************************************************/
#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include "cutlass/cluster_launch.hpp"
#include "cutlass/util/helper_cuda.hpp"
#include "cutlass/half.h"

using namespace cute;
using T = cutlass::half_t;

constexpr int TILE = 256;     // 一块 1D tile 的元素数
constexpr int CLUSTER_N = 2;  // cluster 内 CTA 数（multicast 目标数）

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)

template <class TmaLoad, class GTensor, class SmemLayout>
__global__ static void tma_multicast_kernel(CUTLASS_GRID_CONSTANT TmaLoad const tma,
                                            GTensor mA, T* outG, SmemLayout smem_layout)
{
  __shared__ alignas(128) T smem[cosize_v<SmemLayout>];
  __shared__ alignas(8) uint64_t tma_bar;

  Tensor sA = make_tensor(make_smem_ptr(smem), smem_layout);
  Tensor gA = mA;

  // cluster 内本 CTA 的 rank（0..CLUSTER_N-1）
  int cta_rank = block_rank_in_cluster();

  // multicast mask：cluster 内所有 CTA 都接收 -> 低 CLUSTER_N 位全 1
  uint16_t mcast_mask = (uint16_t(1) << CLUSTER_N) - 1;

  // multicast 版 tma_partition：第 3 个参数传 cluster layout，让 mode-0 按 CTA 分摊
  auto [tAgA, tAsA] = tma_partition(tma, cta_rank, Layout<Int<CLUSTER_N>>{},
                                    group_modes<0,2>(sA), group_modes<0,2>(gA));

  int lane_predicate = elect_one_sync();
  int warp_idx       = threadIdx.x / 32;

  if (warp_idx == 0 && lane_predicate) {
    initialize_barrier(tma_bar, 1);
  }
  cluster_sync();  // cluster 级同步：保证所有 CTA 的 mbarrier 都初始化好

  int phase = 0;
  if (warp_idx == 0 && lane_predicate) {
    int tx_bytes = size(sA) * int(sizeof(T));
    set_barrier_transaction_bytes(tma_bar, tx_bytes);
    // 绑定 mbarrier + multicast mask 一起发
    copy(tma.with(tma_bar, mcast_mask), tAgA, tAsA);
  }
  wait_barrier(tma_bar, phase);

  // 每个 CTA 把自己 smem 的内容写到 outG 的对应段，main 里检查两段是否一致
  T* out_for_this_cta = outG + cta_rank * size(sA);
  for (int i = threadIdx.x; i < size(sA); i += blockDim.x) {
    out_for_this_cta[i] = sA(i);
  }
  cluster_sync();
}

#endif

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major < 9) {
    printf("Ex14 需要 SM90+。当前 SM%d%d，跳过。\n", props.major, props.minor);
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)
  thrust::host_vector<T> hIn(TILE);
  for (int i = 0; i < TILE; ++i) hIn[i] = T(float(i % 31));
  thrust::device_vector<T> dIn = hIn;
  thrust::device_vector<T> dOut(TILE * CLUSTER_N);

  auto gmem_layout = make_layout(make_shape(Int<TILE>{}), LayoutRight{});
  Tensor mA = make_tensor(make_gmem_ptr(dIn.data().get()), gmem_layout);
  auto smem_layout = make_layout(make_shape(Int<TILE>{}), LayoutRight{});

  // multicast descriptor：make_tma_copy 多传一个 cluster layout 参数
  auto cluster_layout = Layout<Int<CLUSTER_N>>{};
  Copy_Atom tma = make_tma_copy(SM90_TMA_LOAD_MULTICAST{}, mA, smem_layout,
                                size<0>(cluster_layout));

  // cluster launch：grid = 1 个 cluster，cluster = CLUSTER_N 个 CTA
  dim3 grid(CLUSTER_N, 1, 1);
  dim3 block(128, 1, 1);
  dim3 cluster(CLUSTER_N, 1, 1);
  int smem_bytes = TILE * sizeof(T) + 16;

  void const* kernel = reinterpret_cast<void const*>(
      &tma_multicast_kernel<decltype(tma), decltype(mA), decltype(smem_layout)>);
  cutlass::ClusterLaunchParams params{grid, block, cluster, smem_bytes};
  cutlass::Status st = cutlass::launch_kernel_on_cluster(
      params, kernel, tma, mA, dOut.data().get(), smem_layout);
  CUTE_CHECK_LAST();
  if (st != cutlass::Status::kSuccess) {
    printf("cluster launch 失败 —— 可能是 SM120 不支持 cluster=%d，把 CLUSTER_N 调成 1 再试。\n", CLUSTER_N);
    return 0;
  }

  thrust::host_vector<T> hOut = dOut;
  bool ok = true;
  // 检查每个 CTA 拿到的数据都 == 原始数据
  for (int c = 0; c < CLUSTER_N && ok; ++c)
    for (int i = 0; i < TILE && ok; ++i)
      ok = (float(hOut[c*TILE + i]) == float(hIn[i]));
  printf("multicast 到 %d 个 CTA：%s\n", CLUSTER_N, ok ? "PASS（每个 CTA 都拿到同一份）" : "FAIL");
#else
  printf("TMA 未启用，跳过。\n");
#endif
  return 0;
}
