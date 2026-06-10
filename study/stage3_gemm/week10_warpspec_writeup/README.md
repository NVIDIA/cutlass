# Week 10 — 手写 WarpSpec GEMM v1（SM100 UMMA + TMEM）

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑退化路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 目标
- 不用 `CollectiveBuilder`，自己组装一个 WarpSpec GEMM kernel
- 跟 CPU ref 对齐，**正确性优先，性能不管**

## 写

`exercises/ex_warpspec_gemm_v1.cu` — 一个扁平的 SM100 GEMM：
- TileShape `<128,128,64>`、ClusterShape `<1,1,1>`（1-SM）
- pipeline depth = 2
- epilogue：从 TMEM 读累加器直接写回 GMEM（不带 alpha/beta/C）
- CPU ref 检查（M=N=K=512）

### 8 步骨架
```
host：
  1. 定义类型：TiledMma(UMMA atom) / smem swizzle layout / make_tma_copy(A,B)
  2. launch kernel<<<grid, 线程数, smem>>>（cluster 1×1×1）

device kernel()：
  3. tcgen05.alloc 申请 TMEM 累加器段
  4. warp 分工：1 producer warp + 1 MMA warp + 几个 epilogue warp
  5. producer：k_tile 循环 { producer_acquire → 发 TMA 搬 A/B → 字节到齐自动 commit }
  6. MMA：    k_tile 循环 { consumer_wait → elect_one 发 tcgen05.mma 累加进 TMEM → consumer_release }
  7. epilogue：tcgen05.ld 把 TMEM→RMEM → 写回 GMEM
  8. tcgen05.dealloc 释放 TMEM
```

### 零件速查（忘了回对应周）
| 零件 | 周 |
|------|----|
| `make_tiled_mma(UMMA atom)` | W3 / `mma_sm100_umma.hpp` |
| `Layout_K_SW128_Atom` swizzle | W2/W5（O3） |
| `make_tma_copy`（host 建 descriptor） | W6（O29） |
| `tcgen05.alloc` / TMEM 累加器 | W8（O31） |
| pipeline 四步协议 | W7（O30） |
| warp 分工 + load/mma 循环结构 | W9（抄 `sm100_gemm/mma_warpspecialized.hpp`） |

## WarpSpec 模式（v1）
```
┌─────────────────────────────────────┐
│  ┌──────────┐   ┌────────────────┐  │
│  │ TMA warp │──▶│  MMA warp       │  │
│  │(producer)│   │ (elect_one →    │  │
│  └──────────┘   │  tcgen05.mma)   │  │
│      mbarrier   └────────────────┘  │
│                    累加器在 TMEM     │
│                 ┌────────────────┐  │
│                 │ epilogue warps  │  │
│                 │ TMEM→RMEM→GMEM   │  │
│                 └────────────────┘  │
└─────────────────────────────────────┘
```

## 跑
```bash
# B200(SM100)
cmake .. -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=100a
make study_stage3_w10_ex_warpspec_gemm_v1 -j
./study_stage3_w10_ex_warpspec_gemm_v1 512 512 512    # 期望 PASSED
./study_stage3_w10_ex_warpspec_gemm_v1 4096 4096 4096

# 5060 Ti(SM120，退化路径：mma.sync + RMEM)
cmake .. -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=120a
```

## 自检
1. producer warp 用了多少线程？真正发 TMA 的是几个？
2. UMMA 由几个线程发射？累加器在 TMEM 让 MMA warp 比 SM90 的 consumer warpgroup 省了什么？
3. pipeline depth = 2 能让 TMA 和 UMMA 重叠吗？depth=1 会怎样？
4. `consumer_release` 该在什么同步点之后发？epilogue 读 TMEM 前怎么确认 UMMA 写完了？
5. `make_tma_copy` 传了哪些参数？它替你算好了什么（对照 W6）？
