# Stage 5 — Sparse MoE

预计 3 周（W19–W21），约 45h。

> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 阶段目标

- 看懂 grouped GEMM 与普通 GEMM 在调度上的差异
- 写一个 end-to-end MoE forward（router → permute → grouped GEMM × 2 → unpermute）
- 能解释 expert 间负载不均的处理

## 周次

| 周 | 标题 | 输出 |
|----|------|------|
| W19 | [Grouped GEMM](week19_grouped_gemm/) | 跑通 example 75/92 + 自写 minimal grouped GEMM |
| W20 | [Routing](week20_routing/) | router + permute + unpermute 单元测试 |
| W21 | [Fused MoE](week21_fused_moe/) | end-to-end MoE forward 正确性通过 |

## CHECKPOINT — 进入 Stage 6 前必过

### 综合练习
- `ex_moe_forward.cu`：8 个 expert，topk=2，hidden=2048，inter=8192，FP16
- 先跑 router 单测、permute 单测，再 end-to-end
- 与 PyTorch reference 对比 rtol=1e-2

### 口答 6 题
1. Grouped GEMM 跟普通 GEMM 的 tile scheduler 有什么本质区别？
2. permute（scatter）和 unpermute（gather）哪个更难？为什么？
3. expert 负载不均时（某个 expert 接到 50% token），动态 scheduler 怎么平衡？
4. router + permute fusion 能省什么？
5. FP8 expert weight 在 MoE 里怎么处理 scaling？
6. topk=2 的 token 路由到 2 个 expert，最终输出怎么加权（softmax of router logits）？
