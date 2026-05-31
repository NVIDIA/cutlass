/***************************************************************************************************
 * Ex16 — PipelineState：trace 循环 buffer 的 (index, phase) 序列
 *
 * 目标：
 *   1. 用 cutlass::PipelineState<Stages> 这个真·循环 buffer 状态机，看它怎么把
 *      「线性的 k-tile 计数」映射成「(buffer index, phase bit)」
 *   2. 验证：index 在 [0, Stages) 循环；每绕回一圈 phase 翻一次
 *   3. 理解为什么 phase 不能用 index % depth 替代（README 自检 Q2）——
 *      index 只告诉你「用哪个 buffer」，phase 才告诉你「这个 buffer 现在是第几遍数据」，
 *      二者合起来才能在 producer/consumer 之间唯一标定一次 hand-off，避免 ABA。
 *
 * 硬件：🟢 任意 SM（PipelineState 只是算术，但方法是 CUTLASS_DEVICE，故跑在 kernel 里）。
 *
 * 跑：
 *   ./study_stage2_w07_ex16_pipeline_state
 *   期望（Stages=3）：
 *     step  index  phase   count
 *        0      0      0       0
 *        1      1      0       1
 *        2      2      0       2
 *        3      0      1       3    <- 绕回 index=0，phase 翻成 1
 *        4      1      1       4
 *        ...
 **************************************************************************************************/
#include <cstdio>
#include "cutlass/pipeline/sm90_pipeline.hpp"

constexpr int STAGES = 3;
constexpr int STEPS  = 8;

__global__ static void pipeline_state_kernel() {
  if (threadIdx.x != 0) return;

  // consumer 视角：从 (index=0, phase=0) 开始
  cutlass::PipelineState<STAGES> state;

  printf("step  index  phase   count\n");
  for (int s = 0; s < STEPS; ++s) {
    printf("%4d  %5d  %5u  %6u\n", s, state.index(), state.phase(), state.count());
    ++state;   // 前进一个 stage：index++，绕回时 phase^=1
  }

  // producer 视角：初始 phase 故意取反（buffer 初始为空，producer 比 consumer 超前一个 phase）
  printf("\nproducer start state（注意 phase 初值=1）：\n");
  auto p = cutlass::make_producer_start_state<cutlass::PipelineState<STAGES>>();
  printf("  producer: index=%d phase=%u count=%u\n", p.index(), p.phase(), p.count());
}

int main() {
  pipeline_state_kernel<<<1, 1>>>();
  cudaError_t e = cudaDeviceSynchronize();
  if (e != cudaSuccess) { printf("kernel error: %s\n", cudaGetErrorString(e)); return 1; }

  printf("\n自检：把 STAGES 改成 2，重跑，确认 index 只在 {0,1} 跳、每 2 步翻一次 phase。\n");
  return 0;
}
