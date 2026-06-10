/***************************************************************************************************
 * Ex18 — 跑通 example 71 (Collective Builder 简化版)，标注用户必须自己定的 5 个模板参数
 *
 * 学习目标（**先做这个，再做 ex19**）：
 *   Builder 简化版让用户视角"只需填几个关键参数"，其他 Sm100 mainloop 内部细节
 *   (StageCount/SmemLayoutAtom/SmemCopyAtom/...) 全由 Builder 推断。本练习就是
 *   亲眼看一遍 "用户视角最少要填什么"。
 *
 * 用法：
 *   1. 复制 examples/71_blackwell_gemm_with_collective_builder/71_blackwell_gemm_with_collective_builder.cu 到本目录
 *      （或直接把它当库 #include 包过来；我们这里推荐"复制+注释"以便边读边标记）
 *   2. 在每个 using ... = Builder<...>::CollectiveOp; 之上写注释，解释每个参数的语义
 *   3. 跑通后保留你的注释版本
 *
 * 用户视角必填的 5 个关键参数（学完 example 71 后，把它们对应的代码行号填进来）：
 *   - TileShape_MNK      (CTA 一次算多大 tile)               line: ____
 *   - ClusterShape_MNK   (cluster 大小，<2,1,1> 启用 2-SM UMMA + multicast) line: ____
 *   - KernelSchedule     (Auto / 1-SM / 2-SM)               line: ____
 *   - EpilogueSchedule   (TmaWarpSpecialized 等)            line: ____
 *   - element types      (A/B/C 各自的 dtype 和 layout)      line: ____
 *
 * Builder 帮你推断了什么（对照 ex19 手动展开版来看，下面是预期答案）：
 *   - DispatchPolicy (StageCount 自动按 smem 容量算)
 *   - SmemLayoutAtom (按 dtype + major mode 选 SW128/SW64 swizzle)
 *   - SmemCopyAtom   (按 dtype 选 TMA)
 *   - MmaAtom        (按 element + tile 选 SM100_MMA_F16BF16_SS 系列 UMMA atom)
 *
 * 跑：
 *   make study_stage3_w09_ex18_run_builder -j
 *   ./study_stage3_w09_ex18_run_builder
 *
 * 硬件：🔴 B200（SM100）：用 SM100 的 KernelSchedule（1-SM / 2-SM UMMA），跑真 tcgen05.mma
 *      🟢 5060 Ti（SM120）：本地验证，走 SM120 mma.sync 退化 schedule
 *
 **************************************************************************************************/
#include <cstdio>

// 占位主程序：在本练习里，你的实际工作是把 example 71 复制过来并加注释；
// 这里给个 stub，让 CMake target 可以构建（不依赖 example 71 的实际内容）。
// 完成后请把下面的 stub 替换成 example 71 的实际代码 + 你的注释。
int main() {
  printf("Ex18 stub: 请把 examples/71_blackwell_gemm_with_collective_builder/71_blackwell_gemm_with_collective_builder.cu\n");
  printf("           的内容复制到这里，并在 Builder<...>::CollectiveOp 的每个参数上加注释，\n");
  printf("           对照 README \"用户必须自己定的 5 个模板参数\" 那一节。\n");
  printf("\n");
  printf("完成标志：本程序输出 GEMM PASSED，且你能脱稿讲清每个模板参数的语义。\n");
  return 0;
}
