# Week 10 — 手写 WarpSpec GEMM v1（SM100 UMMA + TMEM）

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）
> **关键**：B200 上你真能跑 SM100 WarpSpec mainloop 的所有架构特性（UMMA + TMEM 累加器 + tcgen05.mma 单线程发射）；5060 Ti 上用 `MainloopSm120TmaWarpSpecialized` 跑 sm120 路径（MMA atom 换成 mma.sync，无 TMEM/无 2-SM），用于本地快速验证框架。

## 目标
- 自己组装 WarpSpec GEMM kernel，**不用** `CollectiveBuilder`
- 跑出正确结果（跟 CPU ref 对齐）
- 性能不重要，正确性优先

## 读（**由浅入深**：pipeline → kernel 骨架 → mainloop → SM120 本地落地点）
1. `include/cutlass/pipeline/sm100_pipeline.hpp` — pipeline state 流转（W7 已读 sm90 概念，**先复习**：producer_acquire/commit、consumer_wait/release 四步协议是本周代码的骨架，SM100 上 mbarrier 由 UMMA 完成信号触发）
2. `examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu` — **参照实现**，先把它在 B200 上跑起来当 baseline，再写自己的 v1
3. `include/cutlass/gemm/kernel/sm100_gemm_tma_warpspecialized.hpp` — 基础 WarpSpec 完整骨架（必读）：看 `operator()` 怎么按 warp/role 分到 producer（TMA load）/ MMA（UMMA 发射）/ epilogue 分支
4. `include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp` — `load()` / `mma()` 分离 mainloop（最深，是 producer 和 UMMA consumer 的两段逻辑本体）：注意累加器在 **TMEM** 里，UMMA 由**单线程**（`elect_one`）发射
5. **🟢 5060 Ti 本地落地点**：`include/cutlass/gemm/collective/sm120_mma_tma.hpp` —— SM120 用的 mainloop，类名 `MainloopSm120TmaWarpSpecialized`（第 75 行）。配合 `include/cutlass/gemm/dispatch_policy.hpp:585+` 的 `KernelTmaWarpSpecialized{Cooperative,Pingpong}Sm120` 系列 dispatch policy。这是为什么本周框架能在 5060 Ti 上跑（sm120 退化路径，无 TMEM）的**真实文件依据**。

## WarpSpec 模式（SM100）

```
┌─────────────────────────────────────┐
│  CTA                                │
│  ┌──────────┐   ┌────────────────┐  │
│  │ TMA warp │   │  UMMA 发射线程  │  │
│  │(producer)│──▶│ (elect_one →    │  │
│  └──────────┘   │  tcgen05.mma)   │  │
│       mbarrier  └────────────────┘  │
│       同步        累加器在 TMEM     │
└─────────────────────────────────────┘
```

## 写
- `exercises/ex_warpspec_gemm_v1.cu` — v1 版本：
  - TileShape `<128,128,64>`、ClusterShape `<1,1,1>`
  - pipeline depth = 2（最小可工作）
  - 简单 epilogue：从 TMEM 读累加器直接写回 GMEM（不带 alpha/beta）
  - 通过 CPU ref 检查（M=N=K=512）

需要自己实现的关键细节：
- smem 的 swizzle layout（先用 `Layout_K_SW128_Atom`，能跑就行）
- producer warp：循环发起 TMA，`producer_acquire/commit`
- UMMA consumer：`consumer_wait`、`elect_one` 后发 `tcgen05.mma`（累加进 TMEM）、`consumer_release`
- 累加器在 **TMEM** 里，最终从 TMEM 读出写回 GMEM

## 跑
```bash
make study_stage3_w10_ex_warpspec_gemm_v1 -j
./study_stage3_w10_ex_warpspec_gemm_v1 512 512 512   # 期望 PASSED
./study_stage3_w10_ex_warpspec_gemm_v1 4096 4096 4096
```

## 自检
1. 你的 producer warp 用了多少线程？为什么？
2. UMMA 由几个线程发射？跟 WGMMA 的 128 线程（warpgroup）发射相比，`tcgen05.mma` 的 `elect_one` 单线程发射有什么区别？
3. pipeline depth = 2 时，TMA 和 UMMA 能重叠吗？什么时候重叠不上？
4. `consumer_wait` 之后才能发 UMMA，但 UMMA 是异步的——`consumer_release` 应该在什么同步点之后发？累加结果落在 TMEM，怎么确认它写完了？
5. 你的 v1 vs example 70 性能差多少？主要差距在哪？
