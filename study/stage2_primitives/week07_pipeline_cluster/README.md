# Week 7 — Hardware Barrier + Thread Block Cluster

预计 ~15h
> **硬件**：🟢 5060 Ti 完整可跑（SM120 沿用 SM90 cluster：`cluster_sm90.hpp` 在 SM120 上可用，只是 cluster size 上限可能比 H100 / B200 小）

> **认知锚点**（对照 [`sm90_hopper_overview.md`](../sm90_hopper_overview.md)）：
> 本周是把"双主轴怎么协作"落地 —— **B1 mbarrier**（Async：事件完成通知）+ **A2 Cluster / 一.2 SM-to-SM Network**（Scale Up：多 SM 共享更大 SMEM）+ **B2 setmaxnreg**（Async：寄存器不对称分配）三者合起来 = **warp specialization**（overview"为什么 WS 在 Hopper 才流行"那段）。
> 对照 [`sm120_fake_blackwell_overview.md`](../sm120_fake_blackwell_overview.md)：mbarrier/setmaxnreg 消费卡**保留**（通用同步原语），但 cluster/DSMEM/SM-to-SM **砍掉**（5060 Ti 上 cluster size 实际≈1）—— 所以 CHECKPOINT 的 ping-pong 能跑，但跨 CTA 的 cluster 部分在 5060 Ti 上意义有限。
>
> **向前看（SM100 钩子）**：SM100 在 cluster 之上又加了 **CLC（Cluster Launch Control，overview SM100 一.4 + C1）**—— 把 persistent kernel + dynamic tile scheduling 硬件化（`clusterlaunchcontrol.try_cancel`）。本周不实操，但记住：Stage 3 SM100 GEMM 的调度核心就是它，到时回来看 `PersistentTileSchedulerSm100`。

## 目标
- 能解释 `mbarrier` 比 `__syncthreads` 强在哪
- 能用 `PipelineTmaAsync` 写 TMA producer / MMA consumer 同步
- 完成 Stage 2 CHECKPOINT：minimal warpspec ping-pong toy

## 读（**由浅入深 / 自下而上**：底层 mbarrier → cluster → 概念 → 上层抽象，正好配合练习 ex15→ex16）

> 完整阅读策略见 [cutlass_reading_strategy.md](../../cutlass_reading_strategy.md#1-pipeline-抽象--includecutlasspipeline)。

1. `include/cutlass/arch/barrier.h` — **先读这个**：最底层 mbarrier / NamedBarrier wrapper（`init` / `wait` / `arrive`），对应 ex15。952 行但只看 `ClusterBarrier` / `ClusterTransactionBarrier` 两个 struct
2. `include/cute/arch/cluster_sm90.hpp` — cluster 同步 API（`cluster_sync` / `block_rank_in_cluster`，仅 246 行，浅）
3. `media/docs/cpp/pipeline.md` — barrier 设计思想（概念文档，必读，建立 producer/consumer 模型）
4. `include/cutlass/pipeline/sm90_pipeline.hpp` — **最深，最后读**：`PipelineAsync` / `PipelineTmaAsync`（建立在上面三块之上的完整抽象），对应 ex16
   - `PipelineState`：循环 buffer 的 index + phase，避免 ABA
   - 4 步协议：`producer_acquire` → `producer_commit` → `consumer_wait` → `consumer_release`
   - `spread_arrivals_to_warpgroup`：barrier arrive 均摊到 warpgroup

## 写
- `exercises/ex15_mbarrier_basic.cu` — 单个 mbarrier 在 1 个 warp 内 arrive / wait，验证 phase 翻转
- `exercises/ex16_pipeline_state.cu` — 用 `PipelineState` 做循环 buffer，trace 出 (index, phase) 序列
- **CHECKPOINT**：`exercises/ex_warpspec_pingpong_toy.cu`
  - 1 个 producer warp + 2 个 consumer warpgroup 做 reduction（不是 GEMM）
  - 跑 4 轮，CPU ref 验证

## 跑
```bash
make study_stage2_w07_ex15_mbarrier_basic -j && ./study_stage2_w07_ex15_mbarrier_basic
make study_stage2_w07_ex16_pipeline_state -j && ./study_stage2_w07_ex16_pipeline_state
make study_stage2_w07_ex_warpspec_pingpong_toy -j && ./study_stage2_w07_ex_warpspec_pingpong_toy
```

## 自检
1. `mbarrier.arrive` 和 `bar.sync` 在硬件上是同一种实现吗？
2. `PipelineState` 的 phase 为什么不能用 index % depth 替代？
3. `producer_acquire` 阻塞在等待什么？被谁释放？
4. Cluster 内的 `bar.sync` 如何跨 CTA 工作？DSMEM 地址用 `cute::cluster_to_smem_ptr` 转换的语义是什么？
5. 在你的 ping-pong toy 里，最少需要几个 mbarrier？为什么不能用 1 个？
