# Week 15 — FA Forward v1（正确性优先）

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 目标
- 自写 FA forward kernel（SM100 UMMA + TMEM），**复用 Stage 3 的 WarpSpec 骨架**
- 跑出正确结果（PyTorch SDPA 对比 rtol=1e-2）
- 性能可以慢，正确优先

## 读
- 复习 `study/stage3_gemm/week10_warpspec_writeup/exercises/ex_warpspec_gemm_v1.cu`（你的 SM100 GEMM v1）
- `examples/77_blackwell_fmha/collective/sm100_fmha_fwd_mainloop_tma_warpspecialized.hpp` — 重点看两次 GEMM 之间 softmax 怎么插入（累加器在 TMEM）
- `examples/77_blackwell_fmha/kernel/sm100_fmha_fwd_kernel_tma_warpspecialized.hpp` — kernel 骨架，看 warp/role 分工

## 写
- `exercises/ex_fa_fwd_v1.cu`
  - 参数：`(B, H, S_q, S_kv, d) = (1, 8, 1024, 1024, 128)` FP16
  - causal=False（先简单）
  - WarpSpec：1 个 producer warp（TMA Q/K/V），UMMA 由单线程（`elect_one`）发射，累加器在 TMEM
  - 两次 GEMM：
    1. `S = Q @ K^T`（累加在 TMEM，softmax 前搬到 RMEM）
    2. softmax → P
    3. `O += P @ V`（累加在 TMEM）
  - 不做 persistent，每个 (B,H,row_tile) 一个 CTA
- `exercises/ref_torch.py` — 用 `torch.nn.functional.scaled_dot_product_attention` 算参考结果，写到 binary，C++ 读进来对比

## 跑
```bash
python study/stage4_flashattn/week15_fa_fwd_writeup/exercises/ref_torch.py  # 生成参考
make study_stage4_w15_ex_fa_fwd_v1 -j
./study_stage4_w15_ex_fa_fwd_v1
# 期望：max abs diff < 0.01，PASSED
```

## 自检
1. P（softmax 结果）放寄存器，对 register pressure 多大？d=128 时大概多少 bytes/thread？
2. P @ V 这一步，P 的"layout"和 UMMA 期望的 A 矩阵 layout 是否对得上？需要 reorder 吗？
3. 你的 K^T 是真的转置（在 smem 里物理转）还是用 layout 玩出来？哪种省事？
4. softmax 的 row reduce 怎么做？累加器在 TMEM，搬到 RMEM 后用 shfl 还是用 smem？
5. 你的 v1 比 77_blackwell_fmha 慢多少？瓶颈是什么（softmax 同步/UMMA 占比/TMEM 搬运...）？
