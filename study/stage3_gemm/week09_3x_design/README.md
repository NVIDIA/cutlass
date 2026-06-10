# Week 9 — CUTLASS 3.x 分层设计

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）；本周主要是理解 3.x 分层，跨 SM100/SM120 共通

## 目标
- 能画出 device → kernel → collective → tiled atom → atom 的分层图，每层指向具体文件
- 跑通 example 70 和 71，能解释每个模板参数
- 能说出 `CollectiveBuilder` 帮你省掉了哪些手写代码

## 读（**由浅入深**：概念 → Builder 最简入门 → Builder 旋钮展示 → kernel/mainloop 源码）

> ⚠️ **70 和 71 都用 `CollectiveBuilder`**。不存在"不用 Builder 的手动展开 example"——纯手写 collective 太长，只在源码 `sm100_mma_warpspecialized.hpp` 里，或你 W10 自己写。70 vs 71 的区别只是：**70 配置写死（最简单一套 fp16 GEMM）；71 把 schedule/stage/EVT 做成模板参数、跑多套配置展示 Builder 旋钮**。

1. `media/docs/cpp/cutlass_3x_design.md` — 设计哲学（最浅，建立直觉）
2. `media/docs/cpp/gemm_api_3x.md` — **必读**，5 层 API 设计文档
3. `examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu` — **最简入门（先读）**：一套固定 fp16 GEMM，看五层最小组装（2 个 Builder → GemmUniversal → Adapter）+ 1-SM/2-SM 的 MmaTile 决策
4. `examples/71_blackwell_gemm_with_collective_builder/71_blackwell_gemm_with_collective_builder.cu` — **Builder 旋钮展示（后读）**：同样的 Builder，但把 schedule/stage/EVT 模板化，看能调哪些参数
5. `include/cutlass/gemm/kernel/gemm_universal.hpp` — ⚠️**只是 dispatch 入口**（很薄、几乎没逻辑，靠 `IsCutlass3GemmKernel` 把 2.x/3.x 分流到不同特化）。真正的 kernel 逻辑在 `sm100_gemm_tma_warpspecialized.hpp` 的 `operator()`。别在这浪费时间，扫一眼分流机制即可
6. `include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp:1-200` — mainloop 入口（最深，UMMA + TMEM）

> **顺序心得**：先 70（最简）后 71（旋钮）—— 先看最小可用 GEMM，再看 Builder 能调什么。这是 stage1 W2 "先看 fused API 再看 unfuse" 的思路在 stage3 的复用。

## 写
- `exercises/ex17_layered_diagram.md` — 自己画一张分层图（mermaid 或 ASCII），标出每层关键类与文件
- `exercises/ex18_run_builder.cu` — **先做**：跑通 example 70/71，把"用户必须自己定的"模板参数全部标注（TileShape / ClusterShape / KernelSchedule / EpilogueSchedule）
- `exercises/ex19_unwrap_manual.cu` — **再做**：要看"Builder 帮你推断了哪些类型"（DispatchPolicy、StageCount、SmemLayoutAtom、SmemCopyAtom 等），**diff example 不够**（70/71 都用 Builder，diff 不出内部类型）——直接读 `sm100_mma_warpspecialized.hpp` 的模板参数列表，对照 Builder 填了什么

## 跑
```bash
make study_stage3_w09_ex18_run_builder -j && ./study_stage3_w09_ex18_run_builder
make study_stage3_w09_ex19_unwrap_manual -j && ./study_stage3_w09_ex19_unwrap_manual
```

## 自检
1. `GemmUniversalAdapter` 在哪一层？为什么需要它？
2. SM100 的 KernelSchedule（`KernelTmaWarpSpecialized1SmSm100` / `2SmSm100` / Auto）是在编译期还是运行期切换？
3. `TileShape_MNK = Shape<_128,_128,_64>` 表示什么？为什么 N 维度多用 128 而不是 256？
4. `ClusterShape_MNK = Shape<_2,_1,_1>` 启用了什么？在 SM100 上 2-CTA 除了 multicast 还参与 UMMA 吗？
5. Builder 选不好时的 fallback 是什么？怎么强制指定？
