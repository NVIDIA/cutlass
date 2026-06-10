# Ex17 — CUTLASS 3.x 5 层 API 分层图

> 自己画一张 mermaid 或 ASCII 分层图，标出每层的关键类/文件，让"读完源码 → 能口头讲清楚"形成闭环。下面是参考骨架（**填空版**），你需要把括号里的占位补上，并在每个文件路径上点进去快速浏览一遍。

## 5 层 API 全景

```
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 5: Device                                                    │
│    用户接口（CUDA stream + 输入指针 + 输出指针）                     │
│    关键类: cutlass::gemm::device::__________                        │
│    文件:   include/cutlass/gemm/device/gemm_universal_adapter.h     │
│    职责:   把 Arguments 解析成 Params，launch kernel                │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 4: Kernel                                                    │
│    单个 CUDA kernel 的完整骨架                                       │
│    关键类: cutlass::gemm::kernel::__________  (sm100_gemm_*.hpp)    │
│    文件:   include/cutlass/gemm/kernel/gemm_universal.hpp + 各 sm100/sm120 变体 │
│    职责:   按 warp_idx 分流 → 调 collective load() / mma() / epilogue │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 3: Collective                                                │
│    "一个 CTA 干什么" 的逻辑：mainloop + epilogue                     │
│    关键类: cutlass::gemm::collective::__________ (CollectiveMma)    │
│    文件:   include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp │
│            include/cutlass/gemm/collective/sm120_mma_tma.hpp        │
│    职责:   load()=TMA producer, mma()=UMMA consumer（TMEM 累加器）, 二者用 pipeline 同步 │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Layer 2: Tiled Atom                                                │
│    Atom 的并行扩展：TiledMMA / TiledCopy（W3-W4 学过的东西）         │
│    关键类: cute::__________ , cute::__________                      │
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
