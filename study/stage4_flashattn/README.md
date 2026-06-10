# Stage 4 — FlashAttention（SM100 主线 → SM120 验证）

预计 5 周（W14–W17 SM100 Blackwell + W18 SM120 验证），约 75h。

> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证；FP4/FP6 量化 FA 实验也可在本地）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 阶段目标

- 推得动 online softmax 的数学（Dao et al. 那张表）
- 自写 FA forward kernel（SM100 UMMA + TMEM），跑过正确性 + 达到 `77_blackwell_fmha` 的 ≥ 80%
- 能写 FA backward 的 dQ/dK/dV 流程
- 能把 SM100 FA 在 SM120（5060 Ti）上验证 + decode/GQA 变体
- 加分项：在 5060 Ti 上做 fp4/fp6 量化 FA 实验

> 课程顺序：**SM100 FA 优化做透（W14-W17），再 SM120 验证 + decode/GQA 变体（W18）**。FA mental model 比 GEMM 更细（softmax / causal / pipeline），SM120 验证时只把 UMMA→mma.sync、TMEM→RMEM 退化即可。

## 周次

| 周 | 标题 | 主战硬件 | 输出 |
|----|------|---------|------|
| W14 | [FA 算法](week14_fa_algorithm/) | 🟢 5060 Ti / CPU | numpy/Python 写一份 online softmax 参考 |
| W15 | [FA fwd writeup](week15_fa_fwd_writeup/) | 🔴 B200 UMMA+TMEM + 🟢 5060 Ti 验证 | `ex_fa_fwd_v1.cu` 正确性通过 |
| W16 | [FA fwd optimize](week16_fa_fwd_optimize/) | 🔴 B200 | v2 ≥ 80% 77_blackwell_fmha；FP4 实验可选 |
| W17 | [FA bwd](week17_fa_bwd/) | 🔴 B200 + 🟢 5060 Ti | dQ/dK/dV 正确性 |
| W18 | [SM120 FA 验证 + GQA](week18_sm100_fa/) | 🟢 5060 Ti 实测 + 🔴 B200 对照 | SM120 FA + decode/GQA 变体 |

## CHECKPOINT — 进入 Stage 5 前必过

### 综合练习
- `ex_fa_fwd_v2.cu` 在 B200 上：
  - shape `(B=4, H=32, S=4096, d=128)`，causal=True，FP16
  - 性能 ≥ 80% `examples/77_blackwell_fmha`
  - 通过 PyTorch SDPA 正确性比对（rtol=1e-2）

### 口答 7 题
1. Online softmax 比朴素 softmax 多出来的 rescale 步骤数学上怎么推？
2. FA 的两次 GEMM（QK^T 和 PV）能不能用同一个 `TiledMma`？为什么？
3. 你的 K/V tile 加载顺序：先 K 再 V，还是 K/V 同时 prefetch？为什么？
4. Causal mask 在 tile 粒度怎么处理？对角线 tile 和上三角 tile 的差异？
5. d=128 vs d=96 在 B200 上的性能差距来源？
6. Persistent kernel 在 FA 里的收益主要来自哪？
7. FA bwd 的 dQ 和 dK/dV 为什么常拆成两个 kernel 分别算？
