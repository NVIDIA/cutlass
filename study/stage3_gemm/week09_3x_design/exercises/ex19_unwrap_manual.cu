/***************************************************************************************************
 * Ex19 — 跑通 example 70 (手动展开版)，列出 Builder 帮你推断了哪些类型
 *
 * 学习目标（先做 ex18 再做这个）：
 *   把 example 70（手动展开）与 ex18（Builder 简化）diff，把 Builder 帮你推断的类型
 *   找出来，写到本文件下方的"Builder 推断清单"里。这是真正理解 3.x 分层的最快路径——
 *   不是空读文档，而是"用户必填 vs Builder 推断"的精确边界。
 *
 * 用法：
 *   1. 复制 examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu 到本目录
 *   2. 与 ex18（Builder 版）做 diff，把"多出来的 typedef"标出来
 *   3. 跑通，正确性 PASSED
 *
 * Builder 推断清单（diff 后填空）：
 *
 *   类型                         | 在 70 里手写为                  | Builder 推断逻辑
 *   ----------------------------|--------------------------------|-----------------------------
 *   DispatchPolicy / StageCount | MainloopSm100TmaUmmaWarpSpecialized<__> | 按 smem 容量 / sizeof(Tile)
 *   SmemLayoutAtomA / B         | GMMA::Layout_K_SW128_Atom<T>    | 按 dtype + Major 选 swizzle
 *   SmemCopyAtomA / B           | auto (cute::DefaultCopy)        | TMA 路径用 cute::AutoVectorizingCopy
 *   MmaAtom (TiledMMA)          | SM100_MMA_F16BF16_SS<__>        | 按 TileShape_MNK 反推 N
 *   ...（继续填）
 *
 * 自检（做完 ex18+ex19 后回答）：
 *   1. 用户必填的 5 个参数 vs Builder 推断的 N 个类型，比例大约是？
 *      —— 这就是 "Builder 抽掉了 cutlass 知识的多少%"。
 *   2. 什么场景下你必须绕过 Builder 直接写手动版？
 *      —— 提示：非标准 swizzle / 自定义 epilogue fusion / 实验性 schedule
 *
 * 跑：
 *   make study_stage3_w09_ex19_unwrap_manual -j
 *   ./study_stage3_w09_ex19_unwrap_manual
 **************************************************************************************************/
#include <cstdio>

int main() {
  printf("Ex19 stub: 请把 examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu\n");
  printf("           的内容复制到这里，与 ex18 diff，把 Builder 推断清单的空格填上。\n");
  printf("\n");
  printf("完成标志：本程序输出 GEMM PASSED，且你能列出 Builder 推断的 >=5 个类型。\n");
  return 0;
}
