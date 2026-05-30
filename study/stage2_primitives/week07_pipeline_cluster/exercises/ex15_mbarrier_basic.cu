/***************************************************************************************************
 * Ex15 — mbarrier 基础：一个 warp 在单个 mbarrier 上 arrive/wait，观察 phase 翻转
 *
 * 目标：
 *   1. 把 cute::initialize_barrier / arrive_barrier / wait_barrier 这套裸 mbarrier API 用一遍
 *   2. 亲眼看到 phase bit 在「凑齐 arrive 数」后翻转，这是 mbarrier 避免 ABA 的核心
 *   3. 对比 __syncthreads：mbarrier 是「带 phase 的可复用栅栏」，能区分第 N 次和第 N+1 次同步
 *
 * 硬件：🟢 5060 Ti(SM120) 可跑（mbarrier 是 SM90+ 通用原语）。
 *
 * 机制：
 *   init(bar, count) 设定「需要 count 次 arrive 才翻 phase」。
 *   每个线程 arrive_barrier(bar) 贡献一次到达；凑满 count 后 barrier 的 phase bit 翻转。
 *   wait_barrier(bar, phase) 自旋等待，直到 barrier 的当前 phase != 传入的 phase（即已翻转）。
 *   配套约定：等完一轮就把本地 phase ^= 1，下一轮等新的 phase。
 *
 * 跑：
 *   ./study_stage2_w07_ex15_mbarrier_basic
 *   期望：打印 4 轮，每轮 thread0 报告「本轮等待的 phase」= 0,1,0,1
 *
 * 自检（README Q1/Q2）：
 *   - mbarrier.arrive 和 bar.sync 在硬件上是同一种实现吗？（不是：mbarrier 是 smem 里的
 *     64-bit 对象，支持 phase + 异步 arrive；bar.sync 是 named barrier，无 phase）
 **************************************************************************************************/
#include <cstdio>
#include <cute/tensor.hpp>     // 带入 cute::initialize_barrier / arrive_barrier / wait_barrier

using namespace cute;

constexpr int ROUNDS = 4;

__global__ static void mbarrier_basic_kernel() {
  __shared__ alignas(8) uint64_t bar;

  // 只用 1 个 warp（32 线程）。需要 32 次 arrive 才翻一次 phase。
  if (threadIdx.x == 0) {
    initialize_barrier(bar, /*thread_count=*/32);
  }
  __syncthreads();  // 保证 init 对全 warp 可见

  int phase = 0;
  for (int r = 0; r < ROUNDS; ++r) {
    // 32 个线程各 arrive 一次 -> 凑满 32 -> barrier phase 翻转
    arrive_barrier(bar);

    // 全 warp 等待 phase 翻转到位
    wait_barrier(bar, phase);

    if (threadIdx.x == 0) {
      printf("round %d: 等待的 phase = %d（凑满 32 arrive 后翻转）\n", r, phase);
    }

    // 关键：本地 phase 取反，下一轮等新 phase（这就是 ABA 的解法——
    //   同一个 barrier 复用，靠 phase bit 区分「这是第几次同步」）
    phase ^= 1;
  }
}

int main() {
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, 0);
  if (props.major < 9) {
    printf("Ex15 需要 SM90+（mbarrier）。当前 SM%d%d，跳过。\n", props.major, props.minor);
    return 0;
  }
  mbarrier_basic_kernel<<<1, 32>>>();
  cudaError_t e = cudaDeviceSynchronize();
  if (e != cudaSuccess) { printf("kernel error: %s\n", cudaGetErrorString(e)); return 1; }

  printf("\n思考：\n");
  printf("  - 把 init 的 count 改成 16，但仍 32 线程 arrive，会发生什么？（phase 一轮翻两次）\n");
  printf("  - 把 wait 的 phase 固定为 0 不翻转，第 2 轮会怎样？（第 2 轮直接放行/或死等，自己试）\n");
  return 0;
}
