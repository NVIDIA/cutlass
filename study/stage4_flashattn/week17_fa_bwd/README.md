# Week 17 — FA Backward

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）  
> SM120 验证延到 W18（同 Stage，下一周）

## 目标
- 看懂 FA bwd 的 dQ / dK / dV 数学
- 跑通官方 FA bwd 示例
- 自写 FA bwd v1（正确性优先，性能不要求）

## 读
- `examples/python/CuTeDSL/blackwell/fmha_bwd.py` — 算法清晰，先看
- `examples/77_blackwell_fmha/kernel/sm100_fmha_bwd_kernel_tma_warpspecialized.hpp` — SM100 bwd kernel（含 `fmha_kernel_bwd_convert.hpp` / `fmha_kernel_bwd_sum_OdO.hpp` 辅助 kernel）
- `examples/77_blackwell_fmha/77_blackwell_fmha_bwd.cu` — bwd 入口示例
- FA2/FA3 paper 里 backward 公式推导

## FA bwd 数据流（简化）
```
dO ─┐
    ├→ 用 forward 时存的 logsumexp 重算 P
Q,K,V → S = QK^T → P = softmax(S) ─┐
                                    ├→ dV = P^T @ dO
                                    ├→ dP = dO @ V^T
                                    ├→ dS = dsoftmax(dP, P)  
                                    ├→ dQ = dS @ K
                                    └→ dK = dS^T @ Q
```

为什么常拆两个 kernel：
- dQ 在 row 维度并行（按 Q 的 row 切）
- dK/dV 在 col 维度并行（按 K 的 col 切）
- 同一个 kernel 里两种并行模式打架，拆开后各自最优

## 写
- `exercises/ex_fa_bwd_dkv.cu` — dK/dV 一个 kernel
- `exercises/ex_fa_bwd_dq.cu` — dQ 一个 kernel
- `exercises/ref_torch_bwd.py` — 用 PyTorch autograd 算 dQ/dK/dV 参考
- 验证 max abs diff < 0.05（bwd 数值更敏感）

## 跑
```bash
python ref_torch_bwd.py
make study_stage4_w17_ex_fa_bwd_dkv -j && ./study_stage4_w17_ex_fa_bwd_dkv
make study_stage4_w17_ex_fa_bwd_dq  -j && ./study_stage4_w17_ex_fa_bwd_dq
```

## 自检
1. forward 时为什么要 spit out logsumexp（而不是 max+sum 分别存）？
2. dsoftmax 公式是什么？为什么需要 P 自己（而不是 S）来算？
3. dQ kernel 与 dK/dV kernel 在 K dimension 上的 reduce 方向有什么不同？
4. atomic-add 在 dK/dV 里能不能避免？怎么避免？
5. d=128 时 bwd 的算术强度跟 fwd 比是高还是低？
