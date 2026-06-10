# Week 11 — WarpSpec GEMM v2：优化

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05；真 cuBLAS 对照基线）

## 目标
- 把 v1 的性能提到 **≥ 50% cuBLAS（B200）**
- 至少调通 3 项：smem swizzle / pipeline depth / cluster shape
- 写一份 OPTIMIZATION_LOG.md，每项优化对应 ncu 指标变化

## 读

> 本周读 builder 和 tile scheduler；详见 [cutlass_reading_strategy.md §3-§4](../../cutlass_reading_strategy.md#3-collective-mainloop--includecutlassgemmcollective) 和 [选读：EVT](../../cutlass_reading_strategy.md#evt--epilogue-visitor-tree)。

- `include/cute/atom/mma_traits_sm100_umma.hpp` — UMMA 的 swizzle atom（K-major / MN-major SW32/SW64/SW128），挑对的；累加器在 TMEM
- `include/cutlass/gemm/collective/builders/sm100_common.inl` — Builder 是怎么选 swizzle / depth / cluster（含 1-SM/2-SM）的，抄它的逻辑；blockscaled 路径见同目录 `sm100_blockscaled_umma_builder.inl`
- `include/cutlass/gemm/kernel/sm100_tile_scheduler.hpp` — persistent scheduler 入门
- **选读**：`include/cutlass/epilogue/collective/sm100_epilogue_tma_warpspecialized.hpp` + `include/cutlass/epilogue/fusion/sm100_callbacks_tma_warpspecialized.hpp`（及 `sm100_visitor_*.hpp`）— EVT 编译期组合

## 优化 checklist（按收益从大到小）

| # | 优化 | 预期收益 | ncu 验证指标 |
|---|------|---------|--------------|
| 1 | smem swizzle 配对 BF16/FP16 K-major | +30% | `l1tex__data_bank_conflicts` 应为 0 |
| 2 | pipeline depth 2 → 4 → 6 | +20% | `dram__bytes_read` / runtime 比例下降 |
| 3 | TileShape `<128,128,64>` → `<128,256,64>` | +15% | UMMA（tcgen05）指令占比上升 |
| 4 | ClusterShape `<2,1,1>` 开启 multicast | +10% | `dram__bytes_read` 减半（A 多播） |
| 5 | 加 persistent scheduler | +5% | kernel launch 数减少 |

## 写
- `exercises/ex_warpspec_gemm_v2.cu` — 在 v1 基础上叠加优化
- `exercises/OPTIMIZATION_LOG.md` — 每加一项：
  - diff（哪些行变了）
  - ncu 数据对比（before / after）
  - 是否符合预期，不符合的根因
- **选做**：`exercises/ex_evt_bias_relu.cu` — 用 EVT 给 v2 epilogue 加 `D = ReLU(alpha*A*B + beta*C + bias)`
  - 对比手写 epilogue 的 SASS，确认 EVT 没多读多写一次 GMEM
  - 用于以后 FA 的 softmax rescale + output accumulate 借鉴 visitor pattern

## 跑
```bash
make study_stage3_w11_ex_warpspec_gemm_v2 -j
./study_stage3_w11_ex_warpspec_gemm_v2 4096 4096 4096

ncu --set full -o v2 ./study_stage3_w11_ex_warpspec_gemm_v2 4096 4096 4096
```

## 自检
1. 为什么 K-major BF16 用 `Swizzle<3,4,3>`（128B）而不是 `<2,4,3>`（64B）？
2. pipeline depth = 6 时 smem 占用是多少？超 SM100 的 smem 容量了吗？TMEM 占用又是多少？
3. TileShape 改大后 TMEM 用量上升，会超出 TMEM 容量吗？怎么验证？
4. 2x1 cluster 让 A multicast 给 2 个 CTA，B 没多播；这对 K 大 / 小哪种更划算？
5. Persistent scheduler 减少 kernel launch，但每个 CTA 算多个 tile，对 cache 复用有什么影响？
