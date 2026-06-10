# 学习进度跟踪

格式：每完成一周，在对应行打勾，记关键产出和 ncu 指标。

> **当前位置(2026-06-10)**：W9 ☑ 完成，下一站 **W10 手搓 SM100 GEMM v1**。
> **重大调整**：W9 之后全计划已转 **Blackwell-only**（SM100 主线 / SM120 验证，删 SM90）——见各 README + `cutlass_reading_strategy.md §0`。
> **本轮新增思考**：THINKING **O33-O40**（五层=库工程非性能/手写要什么；kernel-collective-pipeline 精确分工；L2L3 嵌套for；文件名 token；5类warp角色；C是输入非结果；tile-based编程+SM120取舍；FA是英伟达形状的算子）。
> W10 README 已重设计为"纯写"（零件 Stage1-2+W9 全学过，不重读）。

## 总览

| Stage | 周 | 状态 | 主要产出 | 完成日期 |
|-------|----|----|---------|---------|
| 1 | W1 — Layout basics | ☑ | `ex01_crd2idx_paper.md` + `ex01_verify.cu` + `ex02_layout_print.cu` + `ex03_coalesce.cu` + 5 道自检 | 2026-05-12 |
| 1 | W2 — Composition + Swizzle | ☑ | `ex04_composition_paper.md` + `ex04_verify.cu` + `ex05_swizzle_paper.md` + `ex06_hgemm_naive.cu` + 4 道自检（Q3 重写后） | 2026-05-12 |
| 1 | W3 — TiledMMA | ☑ | `ex07_tiled_mma_layout.cu`（输出验证通过：4 warp 起点 + V 维 stride 接 atom 接线）+ ex08 跳过（概念已懂：循环顺序影响 reg liveness）+ 自检 Q3/Q5 已懂；Q1/Q2/Q4 跳过（实现细节，Stage 6 再补）| 2026-05-18 |
| 1 | W4 — TiledCopy | ⏭ skip (first-pass) | 概念跟 W3 镜像 (THINKING O21)；原子指令 (cp.async/ldmatrix/pipeline) + ex09/ex10 + CHECKPOINT 一起推后到 Stage 2 之后补。第一遍 Stage 2 直接学 TMA/wgmma，cp.async/ldmatrix 大部分被新硬件抽走 | (待补) |
| 1 | **CHECKPOINT** | ☐ | sgemm_sm80 变体 + 5 道口答 | |
| 2 | W5 — WGMMA (SM90) | ◧ 读+ex12 done | 概念沉淀进 `THINKING.md` O23-O27 + O3 扩展（四件套/proxy/SS-RS/descriptor/swizzle↔bank line/TV 退化/三层解耦）；ex12 产出在 `week05_wgmma/ex12_findings.md`；自检 5 题全答 | 2026-06-01（ex11 实跑等 H20）|
| 2 | W6 — TMA (SM90/SM100/SM120 共用) | ◑ 核心过完 | **加速模式**：只啃核心 20%。读①`0z_tma_tensors.md` 通译 + TMA 核心机制（descriptor/mbarrier transaction/proxy fence/make_tma_copy/kernel 模板）已过；自检 5 题全答 | 2026-06-02 |
| 2 | W7 — Pipeline + Cluster (SM90) | ◑ 核心过完 | 加速模式：mbarrier vs syncthreads / PipelineState(index+phase 防 ABA) / 4 步协议 / warp specialization+setmaxnreg / cluster+DSMEM 核心已过；自检 5 题全答；概念进 THINKING O30 | 2026-06-02 |
| 2 | W8 — TMEM + UMMA (SM100 增量) | ◑ 核心过完 | 加速模式：UMMA vs WGMMA(单线程发射/累加器 TMEM)、TMEM alloc+ld/st、2-SM UMMA(cluster=2 结构必需)、FP4/MX、四层模型已过；概念进 THINKING O31。**Stage 2 收口** | 2026-06-02 |
| 2 | **CHECKPOINT** | ☐ | minimal warpspec ping-pong 玩具 + minimal UMMA toy | |
| 3 | W9 — 3.x 分层设计 | ☑ | 五层(device/kernel/collective/tiled/atom)+ Builder 自动推断 + CollectiveOp/KernelOp 关系；精读 example 70/71(都用 Builder)+ sm100_gemm/mma_warpspecialized(5 类 warp 角色/UMMA 单线程发射/TMEM 累加器)；ex17 分层图全解；O32；自检全答 | 2026-06-10 |
| 3 | W10 — WarpSpec writeup (SM100) | ☐ | | |
| 3 | W11 — WarpSpec optimize (SM100) | ☐ | | |
| 3 | W12 — 1-SM vs 2-SM UMMA (SM100) | ☐ | | |
| 3 | W13 — SM100→SM120 移植 | ☐ | | |
| 3 | **CHECKPOINT** | ☐ | SM100 GEMM ≥ 70% cuBLAS（B200）+ SM120 GEMM 在 5060 Ti 上跑通 | |
| 4 | W14 — FA 算法 | ☐ | | |
| 4 | W15 — FA fwd writeup (SM100) | ☐ | | |
| 4 | W16 — FA fwd optimize (SM100) | ☐ | | |
| 4 | W17 — FA bwd (SM100) | ☐ | | |
| 4 | W18 — SM120 FA 验证 + GQA | ☐ | | |
| 4 | **CHECKPOINT** | ☐ | SM100 FA fwd ≥ 80% 77_blackwell_fmha + SM120 FA 在 5060 Ti 上跑通 | |
| 5 | W19 — Grouped GEMM | ☐ | | |
| 5 | W20 — Routing | ☐ | | |
| 5 | W21 — Fused MoE | ☐ | | |
| 5 | **CHECKPOINT** | ☐ | end-to-end MoE forward 正确（fp16 / 可选 fp4 量化）| |
| 6 | W22 — Pipeline + Collective 精读 | ☐ | | |
| 6 | W23 — Kernel + Scheduler 精读 | ☐ | | |
| 6 | W24 — EVT + 架构对比 | ☐ | | |
| 6 | **CHECKPOINT** | ☐ | 架构图 + 双架构 cheat sheet（SM100/SM120）+ 设计决策笔记 | |
| 7 | 持续调优 | ☐ | | |

---

## ncu 关键指标基线（H20）

每跑通一个练习，就来这里记一行。便于横向对比。

| 练习 | M/N/K (or shape) | TFLOPS | sm__throughput | dram BW (GB/s) | wgmma 指令数 | 备注 |
|------|------------------|--------|----------------|----------------|--------------|------|
| `ex06_hgemm_naive` (W2) | 256/256/128 | (待测) | | | 0 (no tensor core) | 单线程一元素，仅做正确性 baseline |
| | | | | | | |

## ncu 关键指标基线（B200）

| 练习 | M/N/K | TFLOPS | sm__throughput | dram BW (GB/s) | umma 指令数 | tmem 占用 | 备注 |
|------|-------|--------|----------------|----------------|--------------|----------|------|
| | | | | | | | |

---

## 踩坑记录

每个坑一行，包含：现象 / 根因 / 修复 / 关联 commit。

| 日期 | 坑 | 根因 | 修复 | commit |
|------|----|----|------|---------|
| | | | | |

---

## 自检题失败记录

答不上来的题记在这里，回去重读对应 reading 后再来打勾。

| 周 | 题目 | 状态 |
|----|------|------|
| W3 | Q1: ThrID vs ALayout 关系 | 跳过；Stage 6 读 mma_traits 时补 |
| W3 | Q2: thrfrg_C 4 步哪步接硬件 | 跳过；Stage 6 读 mma_atom.hpp 时补 |
| W3 | Q4: serpentine 省多少 reg / 为什么 | 跳过；Stage 7 ncu 撞 spill 时回头看 gemm.hpp:260-390 |
| W4 | 整周跳过 (first-pass) | cp.async / ldmatrix / fence+wait_group / bank conflict 实测 / sgemm_sm80 pipeline / ex09/ex10/CHECKPOINT 全部推后；Stage 2 之后补 |
