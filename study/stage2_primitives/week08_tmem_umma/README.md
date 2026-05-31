# Week 8 — TMEM + UMMA

预计 ~15h
> **硬件**：🟢 5060 Ti（读源码 + 静态编译 `sm_100a`）｜ 🔴 B200（实测 UMMA + TMEM + tcgen05.ld/st）  
> **5060 Ti 注意**：SM120 没有 UMMA / TMEM，本周只能读+静态编译，跑要租 B200。这是承接 W5-W7 之后的 SM100 增量学习（紧跟 SM90 prim 趁热打铁）

> **认知锚点**（对照 [`sm100_blackwell_overview.md`](../sm100_blackwell_overview.md)，这是你自己写的笔记，本周是把它的"为什么"落成"怎么写代码"）：
> - **TMEM**（一.1，分化）：累加器从 RMEM 迁到 per-SM 256KB 专用 SRAM → ex27 亲手 alloc/读/写
> - **tcgen05.mma**（A1，进化）：发起从 warpgroup 退到单线程 → ex28 看 `elect_one_warp` 发 MMA
> - **2-SM MMA / TPC 显式编程边界**（一.3，你挖的最深洞察）：`cta_group::2` 让两个 SM 锁步算一条 MMA_M=256。ex28 用的是 `cta_group::1`（单 SM），但读 `mma_sm100_umma.hpp` 时务必对比 `::1` vs `::2` 两套 PTX 并存 —— 这就是"物理 HW 在 SM、协同通路在 TPC"的源码证据
> - **FP4/FP6/MX**（A3）：本周只跑 F16，但读 `tcgen05.mma.kind::*` 时留意 `f8f6f4`/`mxf4`/`nvf4` —— 这是 5060 Ti 唯一**保留**的 SM100 Tensor Core 能力（本地 LLM 推理刚需，见 `sm120_fake_blackwell_overview.md` 2.2）

## 目标
- 看懂 TMEM 是什么、怎么 alloc、怎么访问
- 看懂 UMMA 与 WGMMA 的核心差异
- 跑通一个 minimal SM100 MMA example

## 读（**自下而上**：PTX → Traits → 分配器 → 实战）

> 本周开始读 SM100 那部分 cutlass/；详见 [cutlass_reading_strategy.md §1（SM100 增量）](../../cutlass_reading_strategy.md#1-pipeline-抽象--includecutlasspipeline)。

1. `include/cute/arch/mma_sm100_umma.hpp` — **UMMA PTX wrappers**：`SM100_MMA_F16BF16_SS / TS / TT` 等，对应 `tcgen05.mma` 系列指令。从这里看 UMMA 的硬件接口。
2. `include/cute/arch/copy_sm100.hpp:618+` — **TMEM ↔ RMEM PTX wrappers**：`SM100_TMEM_LOAD_*` / `SM100_TMEM_STORE_*`，对应 `tcgen05.ld/st` 指令。
3. `include/cute/atom/mma_traits_sm100.hpp` — **UMMA atom traits**：Shape_MNK / ThrID / ALayout / BLayout / CLayout。注意文件名是 `mma_traits_sm100.hpp`（不是 `_umma` 后缀）。
4. `include/cute/atom/copy_traits_sm100.hpp` — TMEM ↔ RMEM 的 traits（也含 TMA）。
5. `include/cute/arch/tmem_allocator_sm100.hpp` — **TMEM 分配器**：`tcgen05.alloc / dealloc` 的 C++ 包装，知道了底下指令再来看 alloc API 更直观。
6. `examples/python/CuTeDSL/blackwell/dense_gemm.py` — 可执行参考（Python DSL，跑得通）。
7. `examples/cute/tutorial/blackwell/`（如果有）— C++ tutorial。

**心智模型**（跟 W3/W4 一致的 PTX → Traits → 抽象层 → 实战）：
```
tcgen05.mma / tcgen05.ld / tcgen05.alloc 三套 PTX
  → mma_traits_sm100 + copy_traits_sm100 把它们包成 atom
  → tmem_allocator 管 TMEM 段生命周期
  → 上层 collective / kernel 用 atom 跑 GEMM
```

## TMEM vs SMEM vs RMEM

| 内存 | SM90 角色 | SM100 角色 | 容量/SM | 访问 |
|------|----------|------------|---------|------|
| RMEM | A/B/C 都可放 | A/B 仍可放，C 不在这 | 64KB | 一切指令 |
| SMEM | 主要 staging | 同 SM90 | 228KB(SM90) / TBD(SM100) | LDS/STS, TMA |
| TMEM | — | C 矩阵专用 | 256KB | `tcgen05.ld/st`, UMMA 内置 |

## UMMA 与 WGMMA 差异

```
WGMMA (SM90):       UMMA (SM100):
A in SMEM/RMEM      A in SMEM/TMEM
B in SMEM           B in SMEM
C in RMEM (warpgroup spread)   C in TMEM
issuing: warpgroup (128 thread)   issuing: 1 thread (TCGen5)
```

UMMA 单线程发射、C 在 TMEM，意味着 epilogue 必须 TMEM→RMEM→GMEM。

## 写
- `exercises/ex27_tmem_alloc.cu` — alloc 一段 TMEM，写入数据，读回 RMEM 验证
- `exercises/ex28_umma_minimal.cu` — 最小 UMMA：(M,N,K)=(64,128,16) FP16，C 留 TMEM 然后搬出验证

## 跑
```bash
cmake -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=100a ..
make study_stage2_w08_ex27_tmem_alloc -j && ./study_stage2_w08_ex27_tmem_alloc
make study_stage2_w08_ex28_umma_minimal -j && ./study_stage2_w08_ex28_umma_minimal
```

### 🟢 5060 Ti 专属验证：亲手确认 SM120 没有 UMMA/TMEM
对照 `sm120_fake_blackwell_overview.md` 的"砍掉 tcgen05 + TMEM"那条（两条路同时判死刑的最典型案例）：
```bash
# sm_100a 能编出 tcgen05.mma / tcgen05.alloc；sm_120a 编不出
nvcc -arch=sm_100a -ptx exercises/ex28_umma_minimal.cu -I../../../../include -o /tmp/sm100.ptx && grep -c "tcgen05.mma" /tmp/sm100.ptx
nvcc -arch=sm_120a -ptx exercises/ex28_umma_minimal.cu -I../../../../include -o /tmp/sm120.ptx 2>&1 | head  # 观察缺失 / 报错
```
> 把"消费卡为何砍 TMEM（大 SRAM 代价）"从结论变成你跑出来的事实。

## 自检
1. TMEM 是 SM 私有还是 cluster 共享？
2. `tcgen05.alloc` 与 `__shared__` 声明在编译期 vs 运行期的差别？
3. UMMA 单线程发射，但谁来等 `mma.commit_group` 完成？
4. C 在 TMEM 时，accumulator 的 layout 是什么？跟 WGMMA 的 RMEM C 是同一种 partition 吗？
5. TMEM ↔ RMEM 的 `tcgen05.ld/st` 一次能搬多少 byte/thread？
