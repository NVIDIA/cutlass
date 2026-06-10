# Week 20 — Token Routing + Permute

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地跑 sm120 路径验证；routing 是 CUDA core 逻辑，与 tensor core 架构无关，本地完整可跑）｜ 🔴 B200（SM100，实测 UMMA+TMEM+tcgen05）

## 目标
- 看懂 router 的 softmax + topk
- 写 permute（scatter）和 unpermute（gather）kernel，单元测试通过
- 理解 expert load 统计与 padding

## MoE 4 个核心操作

1. **Gate/Router**：`logits = X @ W_gate`，softmax + topk → 决定 token 去哪个 expert
2. **Permute**：按 expert id 把 token 重排（scatter） — 每个 expert 拿到自己负责的 token 集中存放
3. **Expert GEMM**：每个 expert 独立做两层 FFN（grouped GEMM）
4. **Unpermute**：结果按 token 原始顺序归位（gather），按 router weight 加权求和

## 读
- DeepSeek-V3 / Mixtral 等开源 MoE 推理代码（如 vLLM 的 MoE kernel）
- CUDA atomic 与 cooperative groups 文档

## 写
- `exercises/ex24_router.cu` — softmax + topk，输入 `X (T, H)` → `expert_ids (T, k)`, `expert_weights (T, k)`
- `exercises/ex25_permute.cu` — 给 `expert_ids`，输出每个 expert 的 `token_count`、`reorder_indices`、permuted X
- `exercises/ex26_unpermute.cu` — 反向操作，从 expert outputs 还原到原 token 顺序，按 router weights 加权

每个都跟 PyTorch reference 对比正确性。

## 跑
```bash
make study_stage5_w20_ex24_router -j && ./study_stage5_w20_ex24_router
make study_stage5_w20_ex25_permute -j && ./study_stage5_w20_ex25_permute
make study_stage5_w20_ex26_unpermute -j && ./study_stage5_w20_ex26_unpermute
```

## 自检
1. topk 在 GPU 上怎么实现？bitonic sort 还是 radix select？
2. permute 用 atomic counter 分配输出位置 vs 先 prefix sum 再写入，性能差异？
3. unpermute 的 gather 模式下，cache 命中率为什么差？
4. expert 容量（capacity）超出怎么 drop / overflow？训练 vs 推理处理不同？
5. permute + GEMM 能 fuse 吗？什么场景下 fuse 划算？
