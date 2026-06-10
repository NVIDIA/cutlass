# `include/cutlass/` 阅读策略

`cutlass/` 目录共约 67 万行、671 个文件，大部分是 2.x 遗产，对"CuTe + 3.x + Blackwell（SM100/SM120）"的目标没价值。
本文是精确的取舍清单，**每条都标了对应在学习计划的哪一周用到**，不要一上来就全读。

---

## 0. 目录全景地图（先看这个，解决"一团糟"）

`include/cutlass/` 是 **2.x 和 3.x 的叠加态**，同一个 `gemm/` 目录塞了两代代码（2.x 用 `threadblock/`+`warp/` 表达层级；3.x 删掉它们改用 `collective/`，因为 wgmma 这种 warpgroup 指令塞不进"warp 层"）。

### 三条判别规则（记死这个）
```
① 文件名带 sm90_ / sm100_ / sm120_   →  3.x（看）
② 目录名是 collective/                →  3.x 独有（看）
③ 目录名是 threadblock/ / warp/ / thread/  →  2.x 遗产（跳！）
```

### 五层 → 目录映射（关键：上3层在 cutlass/，下2层在 cute/）
| 五层 | 在哪 | 几代 | 看哪些 |
|------|------|------|--------|
| 1 Device | `cutlass/gemm/device/` | 混 | 只 `gemm_universal_adapter.h` |
| 2 Kernel | `cutlass/gemm/kernel/` | 混 | **只 `sm90_*`/`sm100_*`**（其余 ~100 个 2.x 跳）|
| 3 Collective | `cutlass/gemm/collective/` | **纯 3.x** | **`sm90_*`/`sm100_*`** ★ |
| 4 Tiled | **`cute/atom/`** + `cute/algorithm/gemm.hpp` | CuTe | `TiledMma`/`TiledCopy`/`cute::gemm` |
| 5 Atom | **`cute/atom/`** + `cute/arch/` | CuTe | `mma_atom.hpp`/`mma_sm100_umma.hpp` |
| （横切）同步 | `cutlass/pipeline/` | 3.x | `sm100_pipeline.hpp` |

> **五层不全在 `cutlass/`**：上3层（device/kernel/collective）在 `cutlass/gemm/`，**下2层（tiled/atom）在 `cute/`**。这就是为什么 Stage1-2 学 CuTe、Stage3 才进 `cutlass/gemm`。

### `include/cutlass/` 顶层目录速判
| 目录 | 是什么 | 看不看 |
|------|--------|--------|
| `gemm/` | GEMM 上3层 | ★主战场，见上表 |
| `epilogue/` | 尾声 | `collective/`+`fusion/`(EVT) 是 3.x 看；`threadblock/`+`warp/` 跳 |
| `pipeline/` | 同步设施（横切，不属五层） | ★`sm100_pipeline.hpp` |
| `arch/` | 架构指令封装 | 看 `barrier.h` |
| `layout/` | 2.x layout tag(RowMajor等) | 只用 tag，不细读（3.x 用 CuTe Layout）|
| `conv/`/`reduction/`/`transform/`/`thread/`/`experimental/`/`detail/`/`platform/` | 卷积/规约/变换/工具 | 用到再看，默认跳 |

### 白名单（你实际要看的，就这些）
```
include/cute/                                        ← 第4-5层 + 一切 layout
include/cutlass/gemm/collective/sm100_* (sm120_*)    ← 第3层 ★W10 范本
include/cutlass/gemm/kernel/sm100_* (sm120_*)        ← 第2层
include/cutlass/gemm/device/gemm_universal_adapter.h ← 第1层
include/cutlass/pipeline/sm100_pipeline.hpp          ← 同步
include/cutlass/epilogue/collective/sm100_*          ← 尾声(3.x)
include/cutlass/epilogue/fusion/                     ← EVT(W11+)
```
**其余 ~90%（所有 threadblock/warp/thread + 无 sm 前缀的旧文件）当不存在。**

---

## 必读（约 5000 行，分散在 6 个文件）

### 1. Pipeline 抽象 — `include/cutlass/pipeline/`

| 文件 | 行数 | 何时读 |
|------|------|--------|
| `sm90_pipeline.hpp` | 1388 | [Stage 2 W7](stage2_primitives/week07_pipeline_cluster/) |
| `sm100_pipeline.hpp` | 1328 | [Stage 2 W8](stage2_primitives/week08_tmem_umma/) 之后，对照读 |

**`sm90_pipeline.hpp` 设计重点**（W7 必看）：
- `PipelineState`：循环 buffer 的 `index + phase`，避免 ABA 问题
- 4 步协议：`producer_acquire` → `producer_commit` → `consumer_wait` → `consumer_release`
- `spread_arrivals_to_warpgroup`：把 barrier `arrive` 均摊到 warpgroup 内所有线程，避免单线程瓶颈

写 FlashAttention / MoE kernel 时，producer/consumer 同步直接参照这个模式。

**`sm100_pipeline.hpp` 增量**（W8 必看）：
- 比 SM90 多一组 TMEM 相关 mbarrier
- consumer 语义在 UMMA 写 TMEM 之后才能 release
- `PipelineTmaUmmaAsync` 是 SM100 的主力

### 2. WarpSpec Kernel 骨架 — `include/cutlass/gemm/kernel/`

| 文件 | 行数 | 何时读 |
|------|------|--------|
| `sm100_gemm_tma_warpspecialized.hpp` | — | [Stage 3 W10](stage3_gemm/week10_warpspec_writeup/) — 写 v1 时直接抄结构（1-SM/2-SM 同一份 kernel）|
| `sm100_gemm_array_tma_warpspecialized.hpp` | — | [Stage 5 W19](stage5_moe/week19_grouped_gemm/) — grouped/array 变体 |

**SM100 WarpSpec kernel 的结构骨架**（W10/W12/W23）：
```
kernel()
├── if (is_producer_warp)
│     load()  ← TMA 异步搬运 A/B，配合 producer_acquire/commit
└── else (UMMA MMA warp / epilogue warp)
      mma()   ← tcgen05.mma 由单线程 elect_one 发射，累加器在 TMEM
```

写 FA / MoE kernel 骨架时，分工结构直接参考这个。1-SM (`cta_group::1`) 与 2-SM (`cta_group::2`) 的差别在配对 CTA 是否协同算同一 tile + TMEM 累加器怎么拆。

### 3. Collective Mainloop — `include/cutlass/gemm/collective/`

| 文件 | 行数 | 何时读 |
|------|------|--------|
| `sm100_mma_warpspecialized.hpp` | — | [Stage 3 W9 + W10](stage3_gemm/) — 主 mainloop（UMMA + TMEM）|
| `builders/sm100_common.inl` | — | [Stage 3 W11](stage3_gemm/week11_warpspec_optimize/) — 抄它的 swizzle/depth/1-SM-2-SM 选择逻辑 |
| `builders/sm100_blockscaled_umma_builder.inl` | — | Stage 3 W11 — blockscaled / narrow precision 路径 |
| `sm100_mma_array_warpspecialized.hpp` | — | [Stage 5 W19](stage5_moe/week19_grouped_gemm/) — array/grouped 变体 |

**设计亮点**（W10 必抓）：
- `load()` 和 `mma()` 是两个**独立函数**，分别由不同 warp 调用，通过 pipeline state 对齐；累加器在 TMEM，UMMA 由单线程 `elect_one` 发射
- 这种分离模式是写 FA 时 QK^T 与 PV 两阶段 mainloop 的直接参考——把它当模板复用

`builders/sm100_common.inl`（W11）：Builder 帮你做了什么——swizzle 选哪个、pipeline depth 设多少、1-SM/2-SM 怎么选、cluster shape 配合 multicast——直接抄它的判断逻辑到自己的 kernel。

### 4. Tile Scheduler — `include/cutlass/gemm/kernel/`

| 文件 | 何时读 |
|------|--------|
| `sm100_tile_scheduler.hpp` | [Stage 3 W11/W12](stage3_gemm/week11_warpspec_optimize/) — persistent scheduler 入门 |
| `sm100_static_tile_scheduler.hpp` | Stage 3 W12 / Stage 6 W23 — 静态调度 |
| `sm100_tile_scheduler_stream_k.hpp` | Stage 3 W12 / Stage 6 W23 — stream-K |
| `sm100_tile_scheduler_group.hpp` | [Stage 5 W19](stage5_moe/week19_grouped_gemm/) — Grouped GEMM 调度 |

**`get_current_work()` 的动态调度设计**：可以直接复用到自定义 MoE kernel 的 expert 负载均衡（Stage 5 W21）。

`stream-K` 是把 K 维度也切给不同 SM 协作算同一个 (M,N) tile，对极扁矩阵（M、N 小、K 大）有奇效。Stage 3 W12 的 1-SM vs 2-SM UMMA 之外，可以加一个 stream-K 变体作为额外练习。

---

## 选读（设计思路可借鉴）

### EVT — Epilogue Visitor Tree

| 文件 | 何时读 |
|------|--------|
| `epilogue/collective/sm100_epilogue_tma_warpspecialized.hpp` | [Stage 3 W11](stage3_gemm/week11_warpspec_optimize/) — epilogue TMA 写回（含 TMEM→RMEM）|
| `epilogue/fusion/sm100_callbacks_tma_warpspecialized.hpp` | Stage 3 W11 — EVT callback 组合 |
| `epilogue/fusion/sm100_visitor_*.hpp` | Stage 6 W24 — TreeVisitor 组合逻辑 |
| `epilogue/fusion/operations.hpp` | Stage 3 W11 — `LinearCombination` / `Bias` / `Activation` 等基础 op |

EVT 把 `alpha*C + beta*D`、bias add、activation 等后处理组合成一棵**编译期类型树**，在 kernel 里零开销展开。

**为什么是"选读"**：手写 GEMM 自己写 epilogue 可以不用 EVT，但写 FA 时 softmax rescale + output accumulate 的 visitor pattern 可以借鉴；写 MoE 时 SwiGLU fuse 在 first GEMM epilogue 也可以借鉴这个组合模式。

**Stage 3 W11 推荐**：读完 builder 后，加一个 EVT 练习 `ex_evt_bias_relu.cu`（在 v2 epilogue 加 bias + ReLU），看一遍编译产物的 SASS，确认确实没多读多写。

### 其它可选

- `include/cutlass/arch/barrier.h` — mbarrier 底层 wrapper（W7 顺手看）
- `include/cutlass/conv/` 的 3.x 部分 — 当前目标不涉及，但 conv 的 implicit GEMM 思路有趣

---

## 不用看（约 38 万行 2.x 遗产）

| 目录 | 行数 | 不看的原因 |
|------|------|-----------|
| `gemm/threadblock/` | 大头 | 2.x 的 `DefaultMmaCore`、tile iterator，全部被 collective 替代 |
| `gemm/warp/` | — | 2.x 的 `WarpMma`，被 TiledMma 替代 |
| `gemm/device/` 的 2.x 部分 | — | 被 `GemmUniversalAdapter` 统一 |
| `transform/threadblock/` | — | 2.x 的数据搬运，被 TMA 替代 |
| `epilogue/threadblock/` | — | 2.x epilogue，被 collective epilogue 替代 |
| `conv/` | — | 卷积，当前目标不涉及（如果将来要做 fused conv，再回来） |
| `reduction/` | — | 老 reduction，3.x 用 epilogue 表达 |

如何快速识别 2.x vs 3.x 文件：
- 文件名带 `sm90_` / `sm100_` 前缀 → 大概率 3.x
- 头文件用 `cute::` 类型 → 3.x
- 使用 `Mma_*::Shape` / `WarpShape` / `InstructionShape` 三层 shape 模板 → 2.x
- 路径里有 `threadblock/` / `warp/` 的目录 → 2.x

---

## 阅读节奏建议

- **不要一开始就读 5000 行**。每个文件在到对应周时再读，否则没上下文，看了也白看
- 读 `sm100_pipeline.hpp` 之前，先把 `media/docs/cpp/pipeline.md` 读一遍
- 读 `*_warpspecialized*.hpp` 时**对着 example 70/71 一起看**，光看 .hpp 容易迷路
- 每读一个文件，在 [PROGRESS.md](PROGRESS.md) 的踩坑记录里写一句"我以为 X 是 Y，实际是 Z"，强化记忆
