# Ex17 — CUTLASS 3.x 5 层 API 分层图

> 自己画一张 mermaid 或 ASCII 分层图，标出每层的关键类/文件，让"读完源码 → 能口头讲清楚"形成闭环。下面是参考骨架（**填空版**），你需要把括号里的占位补上，并在每个文件路径上点进去快速浏览一遍。

## 5 层 API 全景

```
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 5: Device                                                    │
│    用户接口（CUDA stream + 输入指针 + 输出指针）                     │
│    关键类: cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>  │
│    文件:   include/cutlass/gemm/device/gemm_universal_adapter.h     │
│    职责:   把 Arguments 解析成 Params，launch kernel                │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 4: Kernel                                                    │
│    单个 CUDA kernel 的完整骨架                                       │
│    关键类: cutlass::gemm::kernel::GemmUniversal  (sm100_gemm_*.hpp) │
│           = ex17 所说的 "KernelOp" = GemmKernel（非真实 API 名）    │
│    文件:   include/cutlass/gemm/kernel/gemm_universal.hpp(仅dispatch入口) + 真逻辑在 sm100_gemm_tma_warpspecialized.hpp │
│    职责:   按 warp_idx 分流 → 调 collective load() / mma() / epilogue │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 3: Collective                                                │
│    "一个 CTA 干什么" 的逻辑：mainloop + epilogue                     │
│    关键类: cutlass::gemm::collective::CollectiveMma (mainloop)      │
│            + cutlass::epilogue::collective::CollectiveEpilogue（平级另一个）│
│            = ex17 所说的 "CollectiveOp"（Builder<...>::CollectiveOp 的产物）│
│    文件:   include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp │
│            include/cutlass/gemm/collective/sm120_mma_tma.hpp        │
│    职责:   load()=TMA producer, mma()=UMMA consumer（TMEM 累加器）, 二者用 pipeline 同步 │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 2: Tiled Atom                                                │
│    Atom 的并行扩展：TiledMMA / TiledCopy（W3-W4 学过的东西）         │
│    关键类: cute::TiledMma , cute::TiledCopy                         │
│    文件:   include/cute/atom/mma_atom.hpp, copy_atom.hpp            │
│    职责:   把一个 MMA atom 复制 N 份组成更大的指令组                  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 1: Atom (PTX wrapper)                                        │
│    单条 PTX 指令的 C++ 包装                                         │
│    关键类: SM100 UMMA atom（一个 tcgen05.mma 指令的别名）          │
│    文件:   include/cute/arch/mma_sm100_umma.hpp (tcgen05.mma)       │
│            include/cute/arch/mma_sm120.hpp (mma.sync, fp4/fp6/fp8)  │
│            include/cute/arch/copy_sm100_tma.hpp (cp.async.bulk.tensor)│
│    职责:   inline asm                                               │
└─────────────────────────────────────────────────────────────────────┘
```

## 你的任务（在分层图上回答下面这些）

1. **Builder 在哪一层？** 答案不是 1-5 任何一层 —— 它是"编译期的辅助类"，把 Layer 3+4 的模板参数从用户视角的几个参数推断出来。Builder 文件: `include/cutlass/gemm/collective/builders/sm100_common.inl`。
2. **W9 的 example 70 和 71 各覆盖哪几层？**（提示：71 用 Builder 简化了 Layer 3+4，70 手动展开）
3. **W3 的 TiledMMA / W4 的 TiledCopy 是哪一层？** —— 与 stage3 的连接点正在这里。
4. **CollectiveOp 和 KernelOp 的关系？** —— 一个 Kernel = 1 个 mainloop CollectiveOp + 1 个 epilogue CollectiveOp。

把上面 4 个问题的答案，补在你最终的 `ex17_layered_diagram.md`（或者直接编辑这份）里。

---

## 答案

> ⚠️ 本文件层号是**自底向上**（Atom=Layer1，Device=Layer5）；聊天里我用的是**自顶向下**（Device=第1层）。同一套 5 层，只是编号方向相反，别混。下面按本文件的编号。

### Q1. Builder 在哪一层？
**不属于 1-5 任何一层**，是**编译期辅助工厂**。它的产物 `::CollectiveOp` 落在 Layer 3（collective）。Builder 把"用户视角的几个参数（dtype/Tile/Cluster/Schedule）"在编译期**推断出 Layer 3 collective 所需的几十个模板参数**（DispatchPolicy、StageCount、SmemLayoutAtom、各 atom……），顺带通过 schedule tag 选定 Layer 4 kernel 的特化。
文件：`include/cutlass/gemm/collective/builders/sm100_common.inl`（+ `sm100_blockscaled_umma_builder.inl` 等）。

### Q2. example 70 / 71 各覆盖哪几层？
**⚠️ 纠正题面**：70 和 71 **都用 Builder**，不存在"70 手动展开"。两者都是**用户代码**，都覆盖 **Layer 5+4+3 的组装**：
```
两个 CollectiveBuilder → 2 个 CollectiveOp(Layer3)   ← Builder 自动填
  → GemmUniversal<...>(Layer4 KernelOp)               ← 手动 wrap
  → GemmUniversalAdapter<...>(Layer5)                 ← 手动 wrap
```
- Layer 1-2（atom / tiled atom）：**不由用户写**，是 Builder 按 dtype/arch 自动选中的（藏在 CollectiveOp 内部）。
- 区别只是：**70 = 一套写死配置（最简入门）；71 = 把 schedule/stage/EVT 模板化、跑多套配置（展示 Builder 旋钮）**。
- 真正"不用 Builder 手写 Layer 3"的东西在源码 `sm100_mma_warpspecialized.hpp`，或你 W10 自己写的 v1。

### Q3. TiledMMA / TiledCopy 是哪一层？
**Layer 2（Tiled Atom）**。它们是 W3/W4 学的：把单个 atom（Layer 1）按线程/数据**平铺**成一组指令。Layer 3 的 collective 在 `mma()` 里调 `cute::gemm(tiled_mma, ...)` 就是用的它。这是 Stage 1-2（CuTe）和 Stage 3（CUTLASS）的接缝：**Layer 1-2 在 `cute/`，Layer 3-5 在 `cutlass/gemm/`**。

### Q4. CollectiveOp 和 KernelOp 的关系？
- **CollectiveOp**（Layer 3）= `CollectiveBuilder<...>::CollectiveOp` 的产物，是个 **collective**。**有两个**：mainloop 的 `CollectiveMma` + epilogue 的 `CollectiveEpilogue`。
- **"KernelOp"**（Layer 4）= **非真实 API 名**，是本练习给 `GemmKernel = cutlass::gemm::kernel::GemmUniversal<ProblemShape, CollectiveMainloop, CollectiveEpilogue>` 起的俗称。
- **关系**：
  ```
  1 个 KernelOp(GemmKernel) = ProblemShape
                            + 1 个 mainloop CollectiveOp
                            + 1 个 epilogue CollectiveOp
  ```
  即 **CollectiveOp 是 Builder 自动生成的零件（Layer3）；KernelOp 是你手动把两个 CollectiveOp + ProblemShape 拼成的 kernel（Layer4）**。CollectiveOp 是"被组装的"，KernelOp 是"组装结果"。
- 再上一层：`GemmUniversalAdapter<KernelOp>`（Layer5 Device）把 KernelOp 包成 host 句柄。
- 注意 `KernelOp` 不是真实类型名，源码里搜不到；真实名是 `GemmKernel` / `GemmUniversal`。`CollectiveOp` 才是真实成员名（`Builder::CollectiveOp`）。
