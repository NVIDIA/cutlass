# Stage 3 CHECKPOINT — Pingpong vs Cooperative 性能报告

> 跑 `bash bench.sh` 把表填上，然后写"为什么"分析。Stage 3 CHECKPOINT 要求：
> - M=N=K=4096 ≥ 70% cuBLAS（约 ≥ 600 TFLOPS on H20）
> - M=N=K=8192 ≥ 75% cuBLAS（约 ≥ 700 TFLOPS on H20）

## 硬件 / 编译信息

- GPU：______________（H20 / B200 / 5060 Ti）
- nvcc 版本：______
- CUTLASS commit：______
- cuBLAS 版本：______
- 编译命令：`cmake .. -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=___`

## Pingpong vs Cooperative 6-shape 对照

| Shape (M,N,K) | 类型 | Pingpong TFLOPS | Cooperative TFLOPS | cuBLAS TFLOPS | Pingpong % | Coop % | 优势方 |
|---------------|------|-----------------|---------------------|---------------|------------|--------|--------|
| 8192,8192,8192 | 大 GEMM | | | | | | |
| 4096,4096,4096 | 中等 | | | | | | |
| 128,8192,8192 | 短 M (decode-like) | | | | | | |
| 8192,128,8192 | 短 N | | | | | | |
| 4096,4096,16384 | 大 K | | | | | | |
| 16,8192,4096 | 极短 M | | | | | | |

## 分析（每个 shape 一段）

### 8192 cube
- 谁赢：________
- 为什么：________（提示：两个 WG 各算一个 tile vs 协同算一个）

### 4096 cube
- 谁赢：________
- 距离 70% 目标：________

### 128 × 8192 × 8192（decode-like）
- 谁赢：________
- 为什么：________（提示：tile 数太少时 Pingpong 的两个 WG 闲一个）

### 8192 × 128 × 8192
- 谁赢：________

### 4096 × 4096 × 16384（大 K）
- 谁赢：________
- 为什么：________（提示：K 越大 Cooperative 每个 WG 干活时间越长，调度开销越摊得开）

### 16 × 8192 × 4096（极短 M）
- 谁赢：________
- ⚠️ 这个 shape 应该哪个都不及格 70% —— 写下你诊断的 roofline 瓶颈

## CHECKPOINT 30% 损失诊断（4096 cube 这个 shape）

用 ncu Roofline 论证你比 cuBLAS 慢的 30% 来自哪里：

- compute bound or memory bound：________
- 主要损失来源（选 1-3 项）：
  - □ TMA bandwidth 不够（dram 没打满）
  - □ WGMMA 之间 wait 时间过长（pipeline depth 不够）
  - □ register spill（accumulator 太大）
  - □ smem bank conflict（swizzle 没选对）
  - □ epilogue 写回开销
  - □ launch overhead（小 problem 才显著）
- ncu 截图 / 关键 metric 数据：________

## 结论：进 Stage 4 前的认知校准

1. Pingpong 适合的 workload 形状：________
2. Cooperative 适合的 workload 形状：________
3. 5060 Ti vs H20 上同一份代码性能差距 ≈ ____ × —— 主要差距来自 mma.sync vs WGMMA 的算力差
4. 距离"手写并极致优化 GEMM" 还差什么：________（Stage 7 调优会回到这）
