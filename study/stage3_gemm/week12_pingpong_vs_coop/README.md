# Week 12 — 1-SM UMMA vs 2-SM UMMA

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

> **说明**：SM100 没有 SM90 那种 Pingpong / Cooperative 两份独立 kernel 文件。SM100 的 schedule 维度是 **`cta_group::1`（1-SM UMMA）vs `cta_group::2`（2-SM UMMA）**——后者让 cluster 里配对的两个 CTA 协同算同一个 output tile，TMEM 累加器拆在两个 SM 上。本周对照这两个变体（文件夹名保留 `week12_pingpong_vs_coop`，只换内容）。

## 目标
- 写出 1-SM UMMA 与 2-SM UMMA 两个变体，理解 cta_group 1 / 2 的骨架差异
- 在 B200 上做 benchmark，找出各自的最优工作负载（TMEM 用量 / cluster / 吞吐对比）
- 完成 Stage 3 CHECKPOINT：v3 ≥ 70% cuBLAS（B200）

## 读

> 本周读 SM100 kernel 的 schedule 逻辑 + dispatch policy；详见 [cutlass_reading_strategy.md §2](../../cutlass_reading_strategy.md#2-warpspec-kernel-骨架--includecutlassgemmkernel)。

- `include/cutlass/gemm/kernel/sm100_gemm_tma_warpspecialized.hpp` — 唯一的 SM100 WarpSpec kernel 骨架，**1-SM 和 2-SM 走同一份 kernel**，靠 `cta_group` / cluster shape 分流
  - 关注 schedule 逻辑：UMMA 由哪个 CTA 发射、2-SM 时配对 CTA 怎么协同同一 tile、TMEM 累加器怎么分配
- `include/cutlass/gemm/dispatch_policy.hpp` — SM100 的 mainloop policy / schedule tag（**真实存在**的有：`KernelTmaWarpSpecialized1SmSm100`、`KernelTmaWarpSpecialized2SmSm100`，以及底层 `KernelSchedule1Sm` / `KernelSchedule2Sm`）。先 grep 确认你要用的 tag 真的在这个文件里，再按真实存在的写
- `include/cutlass/gemm/collective/builders/sm100_common.inl` — Builder 怎么按 cluster shape 选 1-SM / 2-SM 路径

## 两种模式对比

| 维度 | 1-SM UMMA (`cta_group::1`) | 2-SM UMMA (`cta_group::2`) |
|------|---------------------------|----------------------------|
| 算一个 output tile 的 CTA 数 | 1 | 2（cluster 内配对，2-SM 协同） |
| UMMA 发射 | 本 CTA 单线程 `elect_one` | 配对里由 leader CTA 发 `tcgen05.mma`（`cta_group::2`） |
| TMEM 累加器 | 全在本 SM 的 TMEM | 拆在两个 SM 的 TMEM 上 |
| 单 tile 的 N（或 M）有效宽度 | 受单 SM TMEM 容量限制 | 翻倍（两个 SM 的 TMEM 合起来） |
| 适合场景 | tile 不大 / 占用受限 | 大 tile（N 大），靠 2-SM 摊 TMEM |
| B200 经验 | 中小 tile、调度灵活 | 大 GEMM，吞吐峰值 |

## 写
- `exercises/ex_warpspec_gemm_v3_pingpong.cu` — **1-SM UMMA 版**（`cta_group::1`，ClusterShape `<1,1,1>` 或 `<2,1,1>` 仅 multicast）
- `exercises/ex_warpspec_gemm_v3_cooperative.cu` — **2-SM UMMA 版**（`cta_group::2`，ClusterShape `<2,1,1>`，配对 CTA 协同算同一 tile）
- `exercises/bench.sh` — 跑下面 6 组 shape，记 TFLOPS + TMEM 用量

| Shape (M,N,K) | 类型 |
|---------------|------|
| 8192,8192,8192 | 大 GEMM |
| 4096,4096,4096 | 中等 |
| 128,8192,8192 | 短 M（decode-like） |
| 8192,128,8192 | 短 N |
| 4096,4096,16384 | 大 K |
| 16,8192,4096 | 极短 M |

- `exercises/PERFORMANCE.md` — 记录 6 组结果 + 对比 cuBLAS（B200）+ 两个变体的 TMEM/cluster 占用差异

## 跑
```bash
make study_stage3_w12_ex_warpspec_gemm_v3_pingpong -j
make study_stage3_w12_ex_warpspec_gemm_v3_cooperative -j
bash study/stage3_gemm/week12_pingpong_vs_coop/exercises/bench.sh
```

## 自检
1. `cta_group::2` 模式下，配对的两个 CTA 各算 output tile 的一半，最终 TMEM 累加器怎么分配 / 合并？
2. 2-SM UMMA 由哪个 CTA 发射 `tcgen05.mma`？另一个 CTA 在做什么？
3. 在 M=128 的 decode 场景为什么 2-SM UMMA 不一定划算？
4. 1-SM UMMA 的单 tile TMEM 用量比 2-SM 高还是低？为什么 2-SM 能开更大的 N tile？
5. 你的 v3 在 6 个 shape 中哪几个超过 70% cuBLAS（B200）？哪几个不达标？瓶颈分别是 UMMA 吞吐、TMEM 容量还是 TMA？
