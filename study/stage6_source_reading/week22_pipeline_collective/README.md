# Week 22 — Pipeline + Collective 精读

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，纯读源码 + 写笔记，不需要跑 kernel）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 目标
- 逐行读完 `sm100_pipeline.hpp`（1328 行），理解 phase bit / arrive / wait 的完整状态机 + TMEM consumer 同步
- 读 SM100 collective mainloop（`sm100_mma_warpspecialized.hpp`），理解 load/mma 分工

## 读

> 不再"先读 sm90 再读 sm100 diff"——SM100 是主线，直接精读 sm100。

1. `include/cutlass/pipeline/sm100_pipeline.hpp` — **全文精读**
   - 重点：`PipelineTmaUmmaAsync` 的 `producer_acquire` / `producer_commit` / `consumer_wait` / `consumer_release`
   - 重点：UMMA 完成信号怎么触发 mbarrier、TMEM consumer 的额外同步
   - 画出 phase bit 状态转移图
2. `include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp` — **全文**
   - 重点：`load()`（TMA producer）和 `mma()`（UMMA consumer，单线程 `elect_one` 发射）方法的循环结构、pipeline state 怎么传递、累加器在 TMEM
3. `include/cutlass/arch/barrier.h` — mbarrier 底层 wrapper（辅助理解 pipeline）

## 写

- `exercises/notes_pipeline_sm100.md` — SM100 pipeline 精读笔记：
  - phase bit 状态机图
  - producer/consumer 时序图（标注 mbarrier 操作 + UMMA 完成信号 + TMEM 同步）
  - 关键设计决策（为什么用 phase bit 不用 counter？为什么 depth 一般选 4/8？TMEM consumer 怎么影响 depth？）
- `exercises/notes_collective_mainloop.md` — collective mainloop 架构笔记：
  - load/mma 分工图
  - pipeline state 在 load 和 mma 之间怎么传递
  - warp specialization 的 barrier 同步点 + UMMA 单线程发射

## 自检
1. `PipelineTmaUmmaAsync` 的 `producer_acquire` 内部做了什么？为什么需要等 consumer release？
2. phase bit 翻转的时机是什么？如果 depth=4，phase 序列是什么？
3. collective mainloop 的 `load()` 方法里，TMA 发射和 mbarrier arrive 的顺序能不能反？
4. SM100 pipeline 比一个无 TMEM 的 pipeline 多了哪个 mbarrier？UMMA 的完成信号怎么传给 consumer？
5. 如果 pipeline depth 从 4 改成 8，smem 占用翻倍，但性能不一定翻倍——为什么？TMEM 容量又怎么限制 depth？
