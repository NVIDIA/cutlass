# Stage 3 — 手写 GEMM（SM100 主线 → SM120 验证）

预计 5 周（W9 3.x 设计 + W10–W12 SM100 Blackwell + W13 SM120 移植），约 75h。

> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 阶段目标

- 看懂 CUTLASS 3.x 的 5 层 API（device → kernel → collective → tiled atom → atom），能在每层定位文件
- 能从零写一个 warp-specialized SM100 GEMM kernel（不靠 `CollectiveBuilder`），用 UMMA + TMEM 累加器，跑出正确结果
- 能解释 1-SM UMMA vs 2-SM UMMA（`cta_group::1` vs `::2`）的差异，知道各自的 TMEM/cluster/吞吐权衡
- 能把 SM100 UMMA + TMEM mainloop 移植回 SM120（5060 Ti，无 TMEM / 无 2-SM 的退化路径）
- **CHECKPOINT**：自写 SM100 GEMM 在 B200 上 ≥ 70% cuBLAS；SM120 移植版在 5060 Ti 上跑通 + 性能对照

> 课程顺序：**SM100 GEMM 优化到底（W10-W12）后再做 SM120 移植（W13）**。UMMA/TMEM mental model 牢固后，SM120 移植的核心改动（UMMA→mma.sync、TMEM→RMEM、2-SM→1-SM）只是路径退化。

## 周次

| 周 | 标题 | 主战硬件 | 输出 |
|----|------|---------|------|
| W9 | [3.x 分层设计](week09_3x_design/) | 🟢 5060 Ti | 跑通 example 70/71，画一份分层架构图 |
| W10 | [WarpSpec writeup](week10_warpspec_writeup/) | 🔴 B200 UMMA+TMEM + 🟢 5060 Ti sm120 验证 | 自写 WarpSpec GEMM v1（正确即可）|
| W11 | [WarpSpec optimize](week11_warpspec_optimize/) | 同上 | v2：smem swizzle + pipeline depth 调参 |
| W12 | [1-SM vs 2-SM UMMA](week12_pingpong_vs_coop/) | 🔴 B200 | v3 双版本（1SM / 2SM），benchmark 对比 |
| W13 | [SM100→SM120 移植](week13_sm100_gemm/) | 🟢 5060 Ti 实测 + 🔴 B200 对照 | sm120 移植版，5060 Ti 性能数字 + 移植 diff 文档 |

## CHECKPOINT — 进入 Stage 4 前必过

### 综合练习
你的 `ex_warpspec_gemm_v3.cu`（SM100 版）在 B200 上：
- M=N=K=4096（FP16），≥ 70% cuBLAS
- M=N=K=8192，≥ 75% cuBLAS
- 写 PERFORMANCE.md：你比 cuBLAS 慢的部分主要损失在哪（用 ncu Roofline 论证）
- SM120 移植版在 5060 Ti 上跑通且数值正确

### 口答 8 题
1. CUTLASS 3.x 的 `Mainloop` 和 `CollectiveOp` 是同一个东西吗？
2. `CollectiveBuilder::CollectiveOp` 决定了哪些东西？哪些是用户必须自己定的？
3. 你的 v1（无优化）相比 cuBLAS 慢了多少倍？瓶颈是 UMMA 发射还是 TMA 拉取？
4. v2 加了 swizzle 后 bank conflict 应该是 0，但你的 ncu 数据里如果不是 0，可能是什么原因？
5. pipeline depth 选 4 vs 8 vs 12，对 smem 占用、TMEM 占用、性能各有什么影响？
6. 1-SM UMMA vs 2-SM UMMA 在 M=8192/N=8192 vs M=128/N=8192 上哪个更快？为什么？
7. 2-SM UMMA（`cta_group::2`）模式下两个 CTA 协同算同一个 tile，TMEM 累加器是怎么分配/合并的？
8. 你的 epilogue 是直接 TMEM→GMEM 还是经过 SMEM 二次组装？为什么？
