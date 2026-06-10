# Stage 6 — 源码精读

预计 3 周（W22–W24），约 45h。

> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）
> 你已经手写过 GEMM / FA / MoE，现在回头系统精读 CUTLASS 3.x SM100 源码，补全心智模型。
> 目标不是"再写一遍"，而是**读懂官方 SM100 实现的设计决策**，为 Stage 7 调优打基础。

## 阶段目标

- 能脱稿画出 CUTLASS 3.x 从 device → kernel → collective → atom 的完整数据流
- 能解释每层在哪个文件、关键 API 是什么、为什么这么分层
- 能对比 SM100 (B200) / SM120 (5060 Ti) 两架构在同一框架下的差异点
- 产出一份可复用的"双架构 cheat sheet"（SM100 / SM120）

## 周次

| 周 | 标题 | 精读内容 | 输出 |
|----|------|---------|------|
| W22 | [Pipeline + Collective](week22_pipeline_collective/) | `sm100_pipeline.hpp` 全文 + `sm100_mma_warpspecialized.hpp` collective mainloop | 带注释的架构图 + 设计决策笔记 |
| W23 | [Kernel + Scheduler](week23_kernel_scheduler/) | `sm100_gemm_tma_warpspecialized.hpp` 全文 + sm100 tile_scheduler 系列 + stream-K | annotated notes + 自己的 scheduler 变体 |
| W24 | [EVT + 架构对比](week24_evt_arch_compare/) | sm100 epilogue fusion 全套 + SM100/SM120 双架构全景对比 | 双架构 cheat sheet |

## CHECKPOINT — 进入 Stage 7 前必过

### 综合产出

1. **架构图**（手画或 mermaid）：CUTLASS 3.x 五层 API 的数据流 + 每层对应文件
2. **双架构 cheat sheet**：SM100 (B200) / SM120 (5060 Ti) 在 MMA / Pipeline / Cluster / Epilogue 上的差异一览表
3. **设计决策笔记**：至少 5 个"为什么官方这么做"的 insight（对比你自己手写时的选择）

### 口答 6 题

1. `PipelineTmaUmmaAsync` 的 phase bit 翻转时机是什么？为什么不用 counter？
2. Collective mainloop 的 `load` 和 `mma` 方法是怎么被 kernel 层调度的？
3. SM100 kernel 里 1-SM / 2-SM UMMA 的 barrier 同步点在哪？画出时序图。
4. `TileSchedulerPersistent` 的 `get_current_work()` 返回什么？stream-K 模式下怎么拆 K？
5. EVT 的 `Sm100TreeVisitor` 怎么把多个 fusion op 组合成一棵树？编译期还是运行期？
6. SM120 复用 SM100 的框架，但 MMA atom 不同（mma.sync vs tcgen05.mma）——框架怎么做到上层代码不变？
