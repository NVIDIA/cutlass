/***************************************************************************************************
 * Ex13 — TMA G→S：host 构造 descriptor，kernel 里发一次 cp.async.bulk.tensor 搬运
 *
 * 目标：
 *   1. 看清 TMA 的「host 构造 descriptor / device 发起搬运」两段式
 *   2. 用 mbarrier 的 transaction-count 机制等 TMA 完成（不是线程 arrive，是字节到齐）
 *   3. 验证搬进 smem 的内容 == gmem 原始内容（再 smem→gmem 写出对比）
 *
 * 硬件：🟢 5060 Ti(SM120) 原生支持 TMA，本练习完全本地可跑。
 *
 * TMA 两段式：
 *   host:   make_tma_copy(SM90_TMA_LOAD{}, gmem_tensor, smem_layout) 产出一个 TmaAtom，
 *           里面封了 128 字节的 TensorMap（global addr / box / stride / swizzle）。
 *   device: tma.with(mbar) 绑定一个 mbarrier，copy(...) 发 cp.async.bulk.tensor，
 *           TMA 引擎搬完后自己 complete_tx 更新 mbarrier 的字节计数。
 *
 * 跑：
 *   ./study_stage2_w06_ex13_tma_g2s
 *   期望：三种 box(1D/2D/3D) 全 PASS。
 *
 * 自检（对照 README 自检题）：
 *   - descriptor 为什么必须 host 构造？（cuTensorMapEncode 是 driver API，kernel 里没有）
 *   - 等 TMA 用 mbarrier 的 transaction bytes，而不是 cp.async.wait_group——为什么？
 **************************************************************************************************/
#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cute/tensor.hpp>
#include "cutlass/half.h"
#include "cutlass/util/helper_cuda.hpp"

using namespace cute;
using T = cutlass::half_t;

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)

// 把一块 (BLK_M, BLK_K) 的 tile 用 TMA 从 gmem 搬到 smem，再原样写回 outG 验证。
template <class TmaLoad, class GTensor, class SmemLayout>
__global__ static void tma_g2s_kernel(CUTLASS_GRID_CONSTANT TmaLoad const tma,
                                      GTensor mA, T* outG, SmemLayout smem_layout)
{
  // smem：tile 数据 + 一个 64-bit mbarrier
  __shared__ alignas(128) T smem[cosize_v<SmemLayout>];
  __shared__ alignas(8) uint64_t tma_bar;

  Tensor sA = make_tensor(make_smem_ptr(smem), smem_layout);   // (BLK_M, BLK_K)

  // 取第 0 块 tile（本练习只搬一块）
  Tensor gA = mA;                                              // 已是单 tile 大小

  // TMA partition：mode-0 全权交给 TMA，Int<0>/Layout<_1> = 不 multicast
  auto [tAgA, tAsA] = tma_partition(tma, Int<0>{}, Layout<_1>{},
                                    group_modes<0,2>(sA), group_modes<0,2>(gA));

  // 单线程发起 TMA（约定 thread 0）
  int lane_predicate = elect_one_sync();
  int warp_idx       = threadIdx.x / 32;

  if (warp_idx == 0 && lane_predicate) {
    initialize_barrier(tma_bar, /*thread_count=*/1);
  }
  __syncthreads();

  int phase = 0;
  if (warp_idx == 0 && lane_predicate) {
    // 声明这次 transaction 要等多少字节（= 整块 tile 的字节数）
    int tx_bytes = size(sA) * int(sizeof(T));
    set_barrier_transaction_bytes(tma_bar, tx_bytes);
    // 发 cp.async.bulk.tensor，绑定 tma_bar
    copy(tma.with(tma_bar), tAgA, tAsA);
  }
  // 所有线程在 mbarrier 上等「字节到齐」（不是等线程 arrive）
  wait_barrier(tma_bar, phase);

  // 验证：把 smem 内容写回 outG（每线程搬一个）
  for (int i = threadIdx.x; i < size(sA); i += blockDim.x) {
    outG[i] = sA(i);
  }
}

// 通用：构造一块形如 shape 的 K-major tile，用 TMA 搬一趟，比对内容。
template <class Shape>
bool test_box(char const* tag, Shape shape) {
  int n = size(shape);
  thrust::host_vector<T> hIn(n);
  for (int i = 0; i < n; ++i) hIn[i] = T(float(i % 17));
  thrust::device_vector<T> dIn = hIn;
  thrust::device_vector<T> dOut(n);

  // gmem tensor（compact，按 shape 的默认 row-major stride）
  auto gmem_layout = make_layout(shape, LayoutRight{});
  Tensor mA = make_tensor(make_gmem_ptr(dIn.data().get()), gmem_layout);

  // smem 布局 = 同 shape（不加 swizzle，纯搬运验证；swizzle 留给 WGMMA 配套时再上）
  auto smem_layout = make_layout(shape, LayoutRight{});

  // host 构造 TMA descriptor
  Copy_Atom tma = make_tma_copy(SM90_TMA_LOAD{}, mA, smem_layout);

  tma_g2s_kernel<<<1, 128>>>(tma, mA, dOut.data().get(), smem_layout);
  CUTE_CHECK_LAST();

  thrust::host_vector<T> hOut = dOut;
  bool ok = true;
  for (int i = 0; i < n && ok; ++i) ok = (float(hOut[i]) == float(hIn[i]));
  printf("  %-20s n=%4d  -> %s\n", tag, n, ok ? "PASS" : "FAIL");
  return ok;
}

#endif

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  // TMA 需要 SM90+（含 SM100 / SM120）
  if (props.major < 9) {
    printf("Ex13 需要 SM90+（Hopper/Blackwell）。当前 SM%d%d，跳过。\n", props.major, props.minor);
    return 0;
  }
#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) || defined(CUTE_ARCH_TMA_SM90_ENABLED)
  printf("TMA G->S 单块搬运验证：\n");
  test_box("1D box (256)",        make_shape(Int<256>{}));
  test_box("2D box (64,64)",      make_shape(Int<64>{}, Int<64>{}));
  test_box("3D box (8,16,16)",    make_shape(Int<8>{}, Int<16>{}, Int<16>{}));
#else
  printf("TMA 未启用（CUTE_ARCH_TMA_SM90_ENABLED），跳过。\n");
#endif
  return 0;
}
