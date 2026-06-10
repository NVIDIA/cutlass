# Week 18 — SM120 FA 验证 + decode/GQA 变体

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地实测 sm120 FA 退化路径 + decode/GQA）｜ 🔴 B200（SM100，作 UMMA+TMEM+2-SM 完整路径的对照基线）
> 本周承接 W15-W17 的 **SM100 主线 FA**——把 FA fwd 移植到 SM120（UMMA→mma.sync、TMEM→RMEM、2-SM→1-SM），并做 decode/GQA 低延迟变体

## 目标
- 跑通 `examples/python/CuTeDSL/blackwell/fmha.py` 与 `fmha_bwd.py`（B200 对照）
- 把 Stage 4 FA fwd（SM100）移植到 SM120，在 5060 Ti 上跑通 + 性能数字
- 做 decode/GQA 低延迟变体（参考 `examples/93_blackwell_low_latency_gqa`）
- 写完 Stage 4 CHECKPOINT 文档：`SM100_VS_SM120.md`

## 读
- `examples/python/CuTeDSL/blackwell/fmha.py` — SM100 FA fwd 参考实现（Python，逻辑清晰）
- `examples/93_blackwell_low_latency_gqa/tgv_gqa.cu` / `tgv_gqa.cuh` — decode/GQA 低延迟变体（SM120 GeForce 路径）
- `include/cutlass/gemm/collective/sm120_mma_tma.hpp` — SM120 mainloop（FA 复用同一套退化逻辑）

## SM100 → SM120 FA 移植清单

| 项 | SM100（B200，完整路径） | SM120（5060 Ti，退化路径） |
|----|--------------------------|-----------------------------|
| MMA atom | UMMA `tcgen05.mma`，单线程 `elect_one` 发射 | `mma.sync`，warpgroup 发射 |
| S / O 累加器 | TMEM | RMEM（退回寄存器） |
| P（softmax 结果） | TMEM 或 RMEM | RMEM |
| Cluster | 2-SM 可选（Q tile 切 2 个 CTA） | 退回 1-SM |
| Pipeline | 含 tmem mbarrier | 无 tmem mbarrier |
| 典型场景 | 训练 prefill 大吞吐 | 本地验证 + decode/GQA 低延迟 |

## 写
- `exercises/ex_sm120_fa_fwd.cu` — SM100 FA fwd 移植到 SM120 的版本，正确性优先
- `exercises/SM100_VS_SM120.md` — Stage 4 CHECKPOINT 文档，对比维度：
  - **B200（SM100，完整 TMEM/2-SM）vs 5060 Ti（SM120，退化路径）**
  - FA 算法层 0 改动，但 P 与 O 从 TMEM 退回 RMEM 触发的 layout 变更要列清楚
  - Pipeline 删掉的 tmem mbarrier
  - 性能差距：两卡相对各自基准（example 77 / cuBLAS）的占比、瓶颈差在哪
  - decode/GQA 变体（example 93）在 5060 Ti 上的低延迟表现

## 跑
```bash
cmake -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=120a ..   # 5060 Ti 本地
python examples/python/CuTeDSL/blackwell/fmha.py               # B200 对照
make study_stage4_w18_ex_sm120_fa_fwd -j && ./study_stage4_w18_ex_sm120_fa_fwd
```

## 自检
1. P / O 从 TMEM 退回 RMEM 后，SM120 上 register pressure 有多大影响？d=128 时能开多大 BlockM？
2. SM120 没有 TMEM，UMMA 的 A 矩阵从 TMEM 读这条路没了，P @ V 的 P 怎么喂给 `mma.sync`？
3. softmax rescale 在 SM100 上要 TMEM↔RMEM 来回搬，SM120 上少了这一跳，反而简单——为什么 SM100 还要绕？
4. 2-SM cluster 退回 1-SM 后，FA 的单 CTA 吞吐损失大不大？为什么 FA 里 2-SM 收益本来就比 GEMM 小？
5. decode/GQA（example 93）场景 batch/seq 很小，5060 Ti 上的瓶颈是 compute 还是 launch/latency？
