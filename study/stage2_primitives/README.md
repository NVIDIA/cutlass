# Stage 2 — 硬件原语（SM90 + SM100 增量一起学）

预计 4 周（W5–W7 SM90 + W8 SM100 增量），约 60h。

> **硬件**：🟢 5060 Ti 主战（W6/W7 完全本地可跑；W5/W8 读源码 + 静态编译）
> 🟡 H20（W5 WGMMA 实测，1-2 hr sprint）｜ 🔴 B200（W8 UMMA + TMEM 实测，1-2 hr sprint）

## 阶段目标

- 能解释 WGMMA（SM90）和 UMMA（SM100）的核心差异：warpgroup-issue vs single-thread-issue、RMEM accumulator vs TMEM accumulator
- 能在 host 构造 TMA descriptor，在 kernel 里发起 `cp.async.bulk`（SM90 / SM100 / SM120 共用）
- 能用 `mbarrier` 写 producer / consumer 同步，理解 phase / arrive / wait
- 能解释 TMEM 分配 / 回收（`tcgen05.alloc / dealloc`），UMMA 单线程发射怎么同步
- 完成一个 minimal warpspec ping-pong toy（不必完整 GEMM，只验证同步正确）

> **课程顺序约定**：SM90 prim 一次性消化（W5-W7）后立刻学 SM100 prim（W8）——避免后续 SM100 GEMM/FA 阶段还要重新捡 WGMMA 细节。UMMA 文档大量写 "differs from WGMMA in X"，必须**先懂 WGMMA**。

## 周次

| 周 | 标题 | 主战硬件 | 输出 |
|----|------|---------|------|
| W5 | [WGMMA](week05_wgmma/) | 🟢 5060 Ti 读 + 🟡 H20 实测 | 跑通 wgmma_sm90.cu + 复刻最小版 |
| W6 | [TMA](week06_tma/) | 🟢 5060 Ti | 跑通 wgmma_tma_sm90.cu + 自写 TMA G→S 拷贝 |
| W7 | [Pipeline + Cluster](week07_pipeline_cluster/) | 🟢 5060 Ti | minimal mbarrier ping-pong toy |
| W8 | [TMEM + UMMA](week08_tmem_umma/) | 🟢 5060 Ti 读 + 🔴 B200 实测 | TMEM alloc + minimal UMMA toy |

> 入门前先读 [`sm90_hopper_overview.md`](sm90_hopper_overview.md)：Hopper 硬件改动 × 编程模型的完整梳理（两条主轴：Scale Up + Async），是 W5-W7 的认知地图，W8 SM100 也以这份为对照基线。

## CHECKPOINT — 进入 Stage 3 前必过

### 综合练习
写一个最小化的 warp-specialized 程序，**不要求是 GEMM**：
- 1 个 producer warp 用 TMA 把全局 1MB 数据加载到 smem
- 2 个 consumer warpgroup 轮流（ping-pong）从 smem 读出做 reduction
- 用 `mbarrier` + `PipelineState` 做同步
- 跑 4 轮，验证最终 reduction 结果与 CPU 一致

放置位置：`stage2_primitives/week07_pipeline_cluster/exercises/ex_warpspec_pingpong_toy.cu`。

> SM100 增量（W8）有自己的 mini CHECKPOINT：跑通 TMEM 分配 + minimal UMMA toy 即可（B200 上）。

### 口答 7 题
1. WGMMA 的 RS 模式（A 在寄存器）与 SS 模式（A 在 smem）各自适用什么场景？
2. WGMMA 的 smem layout 为什么必须用 swizzle？哪种 swizzle 配合 BF16 / FP16 / FP8？
3. TMA descriptor 在 host 上构造，传到 kernel 里的是什么？为什么不能在 kernel 里直接 `make_tma_descriptor`？
4. `cp.async.bulk` 与 `cp.async`（SM80）的本质差异是什么？为什么 TMA 需要 128B 对齐？
5. `mbarrier` 的 `phase` 是怎么避免 ABA 问题的？
6. `PipelineTmaAsync::producer_acquire` 内部做了什么？为什么需要 `producer_commit`？
7. Thread Block Cluster 的 DSMEM 跟普通 smem 在地址空间上有什么差别？
