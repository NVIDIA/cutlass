# Week 10 — 手写 WarpSpec GEMM v1（SM100 UMMA + TMEM）

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 退化路径验证框架）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）
> **关键**：本周从"读"转"写"。W9 已经把 `sm100_gemm/mma_warpspecialized.hpp` 的**结构**读懂了——本周**不再重读它们**，只在写的时候当"抄结构的范本"翻。

## 目标
- **自己组装 WarpSpec GEMM kernel，不用 `CollectiveBuilder`**
- 跑出正确结果（跟 CPU ref 对齐），**正确性优先，性能不管**

---

## ⚠️ 本周和 W9 的分工（别重复劳动）

| | W9（已完成） | W10（本周） |
|---|---|---|
| 角色 | **读者**：理解五层 + SM100 kernel/collective 的结构 | **作者**：自己手写一个扁平 v1 |
| 看 `sm100_gemm/mma_warpspecialized.hpp` | 通读理解 `operator()` / `load()` / `mma()` 逻辑 | **不重读**，只当"抄骨架"的参照翻 |
| 类型构造（TiledMMA / TMA atom / smem layout / TMEM alloc） | **没碰**——Builder 全替你做了 | **本周核心**：这些得你亲手写 |

> **本周真正要新读的，是 W9 被 Builder 藏起来的那部分：怎么手动构造 GEMM 的"零件"。** mainloop 的循环逻辑你 W9 已经懂了。

## 读（**只读"手写必需的零件构造"，W9 已懂的不重读**）

> 这些就是 W9 里 `CollectiveBuilder` 在背后偷偷帮你做的事。手写不用 Builder = 你得自己来。每个只看你要用的那几个函数/类型，别通读。

1. **TiledMMA 怎么从 UMMA atom 建** — `include/cute/atom/mma_traits_sm100.hpp` + `include/cute/arch/mma_sm100_umma.hpp`：找 `SM100_MMA_F16BF16_SS` 这类 atom + 看 `make_tiled_mma(atom, ...)` 怎么包成 TiledMMA。这是你 v1 里 `TiledMma` 类型的来源。
2. **smem swizzle layout 怎么建** — 同文件里的 `Layout_K_SW128_Atom` / `UMMA::tile_to_mma_shape`（`sm100_mma_warpspecialized.hpp:178` 有用法）：v1 先无脑用 `Layout_K_SW128_Atom<half>`，能跑就行。
3. **TMA descriptor 怎么在 host 建** — `include/cute/atom/copy_traits_sm100_tma.hpp`：找 `make_tma_copy(...)` 的签名（host 端调，传 gmem tensor + smem layout）。这是 producer 发 TMA 的前提，**W9 完全没见过（Builder 做的）**。
4. **TMEM 怎么 alloc/dealloc** — `include/cute/arch/tmem_allocator_sm100.hpp`：看 `Allocator1Sm::allocate(num_columns, dst_ptr)` / `free(...)`（L60+）。累加器在 TMEM，你得显式申请一段列、用完释放。配 `include/cutlass/detail/sm100_tmem_helper.hpp` 看 helper。
5. **pipeline 对象怎么构造 + PipelineState** — `include/cutlass/pipeline/sm100_pipeline.hpp` 只看**构造部分**（`PipelineTmaUmmaAsync` 的构造 + `make_producer_start_state`）。四步协议（acquire/commit/wait/release）W7/W9 已懂，**不重读**，写的时候直接调。

> **范本（不是"读"，是"抄结构时翻"）**：`sm100_gemm_tma_warpspecialized.hpp`（warp 分工骨架）、`sm100_mma_warpspecialized.hpp`（load/mma 循环骨架）、`examples/70_blackwell_gemm/70_blackwell_fp16_gemm.cu`（host 端 launch + 验证）。卡住了翻它们对应那段，别从头读。

---

## 写（本周 90% 的精力在这）

`exercises/ex_warpspec_gemm_v1.cu` — 一个**扁平**的 SM100 GEMM（把 W9 学的五层塌缩进一个 kernel）：
- TileShape `<128,128,64>`、ClusterShape `<1,1,1>`（先 1-SM，不碰 2-SM）
- pipeline depth = 2（最小可工作）
- 简单 epilogue：从 TMEM 读累加器直接写回 GMEM（**不带 alpha/beta，不带 C**）
- 通过 CPU ref 检查（M=N=K=512）

### v1 的 8 步骨架（手写检查清单）
```
host 端：
  1. 定义类型：TiledMma(UMMA atom) / smem swizzle layout / make_tma_copy(A,B)
  2. launch kernel<<<grid, 256, smem>>>（cluster 1×1×1）

device kernel()：
  3. tcgen05.alloc 申请 TMEM 累加器段
  4. warp 分工（v1 简化：1 个 producer warp + 1 个 MMA warp + 几个 epilogue warp，不要 5 类那么细）
  5. producer：k_tile 循环 { producer_acquire → 发 TMA 搬 A/B → (字节到齐自动 commit) }
  6. MMA：    k_tile 循环 { consumer_wait → elect_one 发 tcgen05.mma 累加进 TMEM → consumer_release }
  7. epilogue：tcgen05.ld 把 TMEM→RMEM → 直接写回 GMEM
  8. tcgen05.dealloc 释放 TMEM
```
**第 5、6 步的循环体 = W9 读的 load()/mma() 的简化版（直接抄结构）；第 1、3、7、8 步 = W9 没碰过的，本周新写。**

## WarpSpec 模式（SM100，v1 简化版）
```
┌─────────────────────────────────────┐
│  CTA（v1：1 producer + 1 MMA + epi） │
│  ┌──────────┐   ┌────────────────┐  │
│  │ TMA warp │   │  MMA warp       │  │
│  │(producer)│──▶│ (elect_one →    │  │
│  └──────────┘   │  tcgen05.mma)   │  │
│      mbarrier   └────────────────┘  │
│      同步          累加器在 TMEM     │
│                 ┌────────────────┐  │
│                 │ epilogue warps  │  │
│                 │ TMEM→RMEM→GMEM   │  │
│                 └────────────────┘  │
└─────────────────────────────────────┘
```

## 跑
```bash
# B200(SM100，实测)
cmake .. -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=100a
make study_stage3_w10_ex_warpspec_gemm_v1 -j
./study_stage3_w10_ex_warpspec_gemm_v1 512 512 512    # 期望 PASSED
./study_stage3_w10_ex_warpspec_gemm_v1 4096 4096 4096

# 5060 Ti(SM120，本地验证框架，走 sm120 退化路径)
cmake .. -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=120a
# 注：sm120 无 TMEM/UMMA，本地版用 mma.sync + RMEM 累加器（见 W13 的退化思路）
```

## 自检
1. 你的 producer warp 用了多少线程？真正发 TMA 的是几个？为什么够？
2. UMMA 由几个线程发射（`elect_one`）？累加器在 TMEM 而非寄存器，这让 v1 的 MMA warp 比 SM90 的 consumer warpgroup 省了什么？
3. pipeline depth = 2 时，TMA 和 UMMA 能重叠吗？depth=1 会怎样？
4. `consumer_wait` 之后发 UMMA，但 UMMA 异步——`consumer_release` 该在什么同步点之后？累加结果落 TMEM，epilogue 读它之前怎么确认 UMMA 写完了？（提示：mbarrier 完成信号）
5. host 端 `make_tma_copy` 你传了哪些参数？它替你算好了什么（对照 W6 的 TMA descriptor）？
