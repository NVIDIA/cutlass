# Week 14 — FA 算法理解

预计 ~15h
> **硬件**：🟢 5060 Ti（CPU 推导 + numpy 参考 + Python DSL 实验，跟具体卡无关）

## 目标
- 推得动 online softmax 数学（不看公式能写出 m_i / l_i 的更新规则）
- 看懂 `examples/77_blackwell_fmha/collective/` 里的 mainloop 结构
- 看懂 `examples/python/CuTeDSL/blackwell/fmha.py`（先理解算法再啃 C++）

## 读
- Tri Dao 的 FA1 / FA2 / FA3 论文（按需）
- `examples/77_blackwell_fmha/` 整个目录走一遍
- `examples/77_blackwell_fmha/collective/sm100_fmha_fwd_mainloop_tma_warpspecialized.hpp` — mainloop（online softmax 在这里）
- `examples/python/CuTeDSL/blackwell/fmha.py` — Python 版本，逻辑更清晰

## FA 算法核心
```
GEMM:    A × B → C   （单次）
FA:      softmax(Q × K^T / √d) × V  
         = 两次 GEMM + online softmax，必须 fuse 在一个 kernel
```

每个 K/V tile 处理时维护：
- `m_i`：当前 row 的最大值（用于 numeric stability）
- `l_i`：归一化分母（去除 max 后的 exp 和）
- `O_i`：累加输出

每来一个新 tile：
1. 新 m_new = max(m_i, m_tile)
2. rescale 旧 O 和 l：`O_i ← O_i * exp(m_i - m_new)`、`l_i ← l_i * exp(m_i - m_new)`
3. 新 P = exp(S_tile - m_new)，l_i += sum(P)
4. O_i += P × V_tile
5. m_i ← m_new

## 写
- `exercises/ex20_online_softmax.py` — 用 numpy 写一版 online softmax，跟 `softmax(QK^T)V` ground truth 对比，shape 任选
- `exercises/ex21_88fmha_walkthrough.md` — 读 `examples/77_blackwell_fmha/`，画一张数据流图（Q/K/V tile 怎么加载、softmax 在哪、O 怎么写出）

## 跑
```bash
python study/stage4_flashattn/week14_fa_algorithm/exercises/ex20_online_softmax.py
```

## 自检
1. Online softmax 的 `m_i` 更新为什么是 `max`，不能用别的？
2. rescale 旧 O 和 l 时，为什么是 `exp(m_old - m_new)` 而不是 `exp(m_new - m_old)`？
3. 整个 attention 的 logsumexp（用于 backward）在 forward 里怎么 spit out？
4. Causal mask 让上三角 tile 整体跳过，半遮挡 tile（对角线）怎么处理？
5. d=128 时 P × V 的 GEMM 形状是 `(BlockM, d) = P @ V`，P 在哪里（寄存器还是 smem）？
