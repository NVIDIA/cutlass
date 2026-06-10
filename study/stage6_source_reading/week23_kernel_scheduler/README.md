# Week 23 — Kernel + Scheduler 精读

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，纯读源码 + 写笔记）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 目标
- 逐行读完 SM100 WarpSpec kernel，画出 1-SM / 2-SM UMMA 的时序图
- 理解 2-SM 配对 CTA 的 TMEM 累加器分配 / 协同机制
- 读 sm100 tile_scheduler 系列，理解 persistent / stream-K / grouped 三种调度策略

## 读

1. `include/cutlass/gemm/kernel/sm100_gemm_tma_warpspecialized.hpp` — 全文
   - 重点：warp/role 分工（TMA producer / UMMA MMA / epilogue）、1-SM vs 2-SM（`cta_group::1` vs `::2`）的 schedule 分流、UMMA 单线程发射、TMEM 累加器不被覆盖的机制
2. `include/cutlass/gemm/kernel/sm100_tile_scheduler.hpp` — persistent scheduler
   - 重点：`get_current_work()` 的动态分配逻辑
3. `include/cutlass/gemm/kernel/sm100_static_tile_scheduler.hpp` — 静态调度
   - 重点：静态 tile 映射 vs persistent 动态分配的取舍
4. `include/cutlass/gemm/kernel/sm100_tile_scheduler_stream_k.hpp` — stream-K
   - 重点：K 维度怎么拆、partial tile 怎么 reduce
5. `include/cutlass/gemm/kernel/sm100_tile_scheduler_group.hpp` — grouped GEMM
   - 重点：多 problem 的 tile id 拍平 + 查表

## 写

- `exercises/notes_sm100_kernel.md` — SM100 kernel 精读笔记：
  - 1-SM / 2-SM UMMA 的完整时序图（标注 barrier wait/arrive + UMMA 发射）
  - TMEM 累加器生命周期（1-SM 全在本 SM；2-SM 拆在配对 CTA）
  - 跟你 W12 手写版的对比：官方多做了什么？
- `exercises/notes_2sm_umma.md` — 2-SM UMMA 精读笔记：
  - 配对 CTA 协同算同一 tile 时 TMEM 累加器怎么分配 / 合并（SMEM 中转？mbarrier 协调？）
  - 跟 1-SM 的适用场景对比
- `exercises/notes_tile_scheduler.md` — Scheduler 精读笔记：
  - persistent / static / stream-K / grouped 几种策略的决策树
  - `get_current_work()` 的伪代码
  - stream-K 的 partial tile reduce 机制

## 自检
1. SM100 kernel 里 1-SM / 2-SM 切换怎么靠 `cta_group` 分流？两条路径共享多少代码？
2. 2-SM UMMA 模式下 TMEM 累加器 reduce 用的是什么同步原语？
3. Persistent scheduler 的 `get_current_work()` 是 atomic 还是 deterministic？
4. Stream-K 把 K 拆给多个 SM，partial result 怎么汇总？用 atomic add 还是 reduction kernel？
5. Grouped GEMM scheduler 的 tile id → (problem_idx, tile_in_problem) 是 O(1) 还是 O(log n)？
