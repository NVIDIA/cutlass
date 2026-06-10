# v1 → v2 优化指南（按预期收益排序，逐项做）

> 本周不另起新的脚手架 —— v2 就是把 W10 的 `ex_warpspec_gemm_v1.cu` 复制成 `ex_warpspec_gemm_v2.cu` 后逐项叠加优化。每项做完跑 ncu，把数据填到 `OPTIMIZATION_LOG.md`。

## 优化总览（与 README 的 checklist 一致，这里展开"具体改哪里"）

### 1. smem swizzle 配对 BF16/FP16 K-major（+30%）

- **改哪里**：v1 用的 `Layout_K_SW128_Atom<half_t>` 已经是 128B swizzle 了？如果是的话本项跳过。如果还在用 INTER/SW32/SW64，换成 `GMMA::Layout_K_SW128_Atom<T>`。
- **为什么 SW128 对 BF16/FP16**：K-major 时连续 8 个 fp16 = 16B，配 128B swizzle 周期能让 LDSM 完全分散到不同 bank。SW64 周期太短，FP8 才用。
- **ncu 验证**：`l1tex__data_bank_conflicts_pipe_lsu_mem_shared_op_ldsm` 应为 0
- **常见踩坑**：把 `partition_D` 喂的 sA 包过 `as_position_independent_swizzle_tensor`，否则 cp.async/TMA 写进去的物理位置和 UMMA 读取的 swizzled 视图对不上 → 全是错的数

### 2. pipeline depth 2 → 4 → 6（+20%）

- **改哪里**：`constexpr int STAGES = 2;` 改成 `STAGES = 4`，然后 6。注意 SharedStorage 容量会涨。
- **smem 占用公式**：`STAGES × (BLK_M × BLK_K + BLK_N × BLK_K) × sizeof(T) + 2 × STAGES × 8`
  - BLK 都是 128 × 64 fp16 = 16KB；STAGES=6 时 A+B = 6×32KB = 192KB
  - B200(SM100) 单 block 最大 ~228KB+/TBD → 还能放下，但接近上限
  - SM120 单 block 最大 ~99KB → **STAGES=4 已经超** → 5060 Ti 上 v2 这步最大只能到 STAGES=2 或 3
- **ncu 验证**：`smsp__inst_executed_pipe_tensor_op_hmma` 占比上升，`dram__throughput.avg.pct_of_peak_sustained_elapsed` 下降意味着 TMA 已经被吃满
- **何时不再增益**：当 producer 的 TMA bandwidth 已经把 dram 打满，再加 stage 也不会更快

### 3. TileShape `<128,128,64>` → `<128,256,64>`（+15%）

- **改哪里**：BLK_N 从 128 改到 256；MMA atom 从 `SM100_MMA_F16BF16_SS<..., 128, 128, ...>` 换成 `SM100_MMA_F16BF16_SS<..., 128, 256, ...>`（UMMA atom 改 N）
- **为什么 N 大效率高**：单条 UMMA（`tcgen05.mma`）算更多 FMA，指令发射开销摊得更薄；TMEM 累加器列数也会变（N 越大 accumulator 越多）
- **风险**：N=256 时 accumulator 占更多 TMEM 列。注意：SM100 累加器在 TMEM 不占线程寄存器，所以"逼近寄存器上限触发 spill"这条风险在 SM100 上其实变小；主要看 TMEM 列容量是否够用。（5060 Ti/SM120 退化路径用 RMEM 累加器，那条路径仍要看寄存器上限）
- **ncu 验证**：`smsp__sass_thread_inst_executed_op_hmma_pred_on` 占比上升；SM120 退化路径下 `launch__registers_per_thread` 不要超 240

### 4. ClusterShape `<2,1,1>` 启用 multicast（+10%）

- **改哪里**：dimCluster = {2,1,1}；TMA 用 `SM100_TMA_LOAD_MULTICAST` 加上 mcast_mask；`make_tma_atom` 传 cluster layout（参考 W6 ex14）
- **谁多播**：M 方向的 2 个 CTA 共享同一个 B（B 在 N 方向被复用）→ 多播 **B**；A 各 CTA 自己读
- **大 K vs 小 K**：K 越大，B 的总流量越大，multicast 省得越多 → 大 K 收益大
- **ncu 验证**：`dram__bytes_read` 应该约为非 multicast 的 1/2 (针对 B 的部分)
- **5060 Ti 限制**：SM120 cluster size 上限 < SM100，2x1 大概率支持，4x1 可能失败 → README 已经标注

### 5. Persistent scheduler（+5%）

- **改哪里**：kernel 顶层不再是"每个 CTA 算一个 tile 就退出"，而是"persistent CTA 循环领 tile"。最少改动：用 cutlass 已有的 SM100 persistent scheduler（在 `include/cutlass/gemm/kernel/sm100_tile_scheduler.hpp`）
- **收益来源**：减少 kernel launch overhead；让前面跑完的 CTA 继续干活（避免尾部空转）
- **ncu 验证**：`launch__grid_size` 减少（不再 = M/BLK_M × N/BLK_N）
- **风险**：persistent 会让同一个 SM 跨 tile，L2 复用会变 —— 大 problem 时是好事(B 矩阵可以缓存命中)，小 problem 反而可能慢

---

## EVT 选做（README 已标注）

如果上面 5 项做完还有时间，做 `ex_evt_bias_relu.cu`：

```cpp
// epilogue 改成 D = ReLU(alpha * A*B + beta * C + bias)
// 用 cutlass::epilogue::fusion 里的 visitor combinator：
//   tree(ReLU, Add(Add(Multiply(alpha, AB), Multiply(beta, C)), bias))
```

参考 `include/cutlass/epilogue/fusion/sm100_callbacks_tma_warpspecialized.hpp:1-300`。

**核心收益**：fused epilogue 不会在 RMEM↔SMEM↔GMEM 之间多绕一圈。看 SASS 验证：搜 `STG` 的次数，应该 = 1（只写 D），而不是写两次 D 再读回来 ReLU。

这是为 Stage 4 FA 的 softmax rescale 借鉴 visitor pattern 的预热。
