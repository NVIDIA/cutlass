# Week 9 — CUTLASS 3.x 分层设计

预计 ~15h
> **硬件**：🟢 5060 Ti（读源码 + 静态编译，主要是理解 3.x 分层，跨 SM90/SM100/SM120 共通）

## 目标
- 能画出 device → kernel → collective → tiled atom → atom 的分层图，每层指向具体文件
- 跑通 example 48 和 49，能解释每个模板参数
- 能说出 `CollectiveBuilder` 帮你省掉了哪些手写代码

## 读（**由浅入深**：概念 → Builder 入门 → 手动展开 → kernel/mainloop 源码）
1. `media/docs/cpp/cutlass_3x_design.md` — 设计哲学（最浅，建立直觉）
2. `media/docs/cpp/gemm_api_3x.md` — **必读**，5 层 API 设计文档
3. `examples/49_hopper_gemm_with_collective_builder/49_collective_builder.cu` — **Builder 简化版（先读这个）**：看用户视角最少要写哪些模板参数
4. `examples/48_hopper_warp_specialized_gemm/48_hopper_warp_specialized_gemm.cu` — 手动展开版（后读）：看 Builder 帮你推断了哪些类型
5. `include/cutlass/gemm/kernel/gemm_universal.hpp` — 3.x kernel 骨架（薄，81 行，容易啃）
6. `include/cutlass/gemm/collective/sm90_mma_tma_gmma_ss_warpspecialized.hpp:1-200` — mainloop 入口（最深）

> **顺序心得**：先 49（Builder 简化）后 48（手动展开）—— 这样能直接对比"Builder 帮我省了什么",而不是先被 48 的一堆模板参数糊脸。这是 stage1 W2 "先看 fused API 再看 unfuse" 的思路在 stage3 的复用。

## 写（顺序对应"读"的顺序：先 Builder 再手动展开）
- `exercises/ex17_layered_diagram.md` — 自己画一张分层图（mermaid 或 ASCII），标出每层关键类与文件
- `exercises/ex18_run_builder.cu` — **先做**：跑通 example 49（Builder 简化版），把"用户必须自己定的"模板参数全部标注（TileShape / ClusterShape / KernelSchedule / EpilogueSchedule）
- `exercises/ex19_unwrap_manual.cu` — **再做**：跑通 example 48（手动展开版），列出 Builder 帮你推断了哪些类型（DispatchPolicy、StageCount、SmemLayoutAtom、SmemCopyAtom 等）。直接 diff 两份 cu 的 typedef 区也行

## 跑
```bash
make study_stage3_w09_ex18_run_builder -j && ./study_stage3_w09_ex18_run_builder
make study_stage3_w09_ex19_unwrap_manual -j && ./study_stage3_w09_ex19_unwrap_manual
```

## 自检
1. `GemmUniversalAdapter` 在哪一层？为什么需要它？
2. `KernelSchedule::Pingpong / Cooperative / Auto` 是在编译期还是运行期切换？
3. `TileShape_MNK = Shape<_128,_128,_64>` 表示什么？为什么 N 维度多用 128 而不是 256？
4. `ClusterShape_MNK = Shape<_2,_1,_1>` 启用了什么？要求架构是？
5. Builder 选不好时的 fallback 是什么？怎么强制指定？
