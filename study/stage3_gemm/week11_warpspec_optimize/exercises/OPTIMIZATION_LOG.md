# v1 → v2 优化日志（模板，逐项填写）

> 跑命令：`ncu --set full -o v2_step{N} ./study_stage3_w11_ex_warpspec_gemm_v2 4096 4096 4096`
> 然后 `ncu-ui v2_step{N}.ncu-rep` 打开，找 README 列出的 metric 抄过来。

baseline（v1，未优化）：M=N=K=4096 FP16
- TFLOPS：______
- cuBLAS 对照：______ TFLOPS（B200 FP16 峰值约 2200+ TFLOPS，实测填 B200 量级或 TBD）
- 当前 % of cuBLAS：______%

---

## 步骤 1：smem swizzle (Layout_K_SW128_Atom)

- diff 行号：v1 第 ___ 行 → v2 第 ___ 行
- 变化：`____________` → `____________`
- ncu before / after：
  - `l1tex__data_bank_conflicts_pipe_lsu_mem_shared_op_ldsm`：______ → ______（应到 0）
  - TFLOPS：______ → ______（预期 +30%）
- 符合预期？□ 是 □ 否 —— 不符合的根因：__________

## 步骤 2：pipeline depth (STAGES 2 → 4)

- diff 行号：v1 第 ___ 行（`STAGES = 2`）→ v2 第 ___ 行（`STAGES = 4`）
- smem 占用计算：__________ KB（应 ≤ ~228KB+/TBD on B200(SM100)，≤ ~99KB on 5060 Ti(SM120)）
- ncu before / after：
  - `dram__throughput.avg.pct_of_peak_sustained_elapsed`：______ → ______
  - `smsp__inst_executed_pipe_tensor_op_hmma`：______ → ______
  - TFLOPS：______ → ______（预期 +20%）
- 符合预期？□ 是 □ 否

## 步骤 3：TileShape (128,128,64) → (128,256,64)

- diff 行号：v1 第 ___ 行 → v2 第 ___ 行
- MMA atom 也要换：`SM100_MMA_F16BF16_SS<..., 128, 128, ...>` → `SM100_MMA_F16BF16_SS<..., 128, 256, ...>`（UMMA atom 改 N）
- register 用量：`launch__registers_per_thread`：______（不要超 240，否则 spill）
- ncu before / after：
  - `smsp__sass_thread_inst_executed_op_hmma_pred_on`：______ → ______（占比应上升）
  - TFLOPS：______ → ______（预期 +15%）
- 符合预期？□ 是 □ 否

## 步骤 4：ClusterShape <2,1,1> + B multicast

- diff 行号：v1 第 ___ 行（dimCluster {1,1,1}）→ v2 第 ___ 行（{2,1,1}）
- TMA 改用 `SM100_TMA_LOAD_MULTICAST`：第 ___ 行
- ncu before / after：
  - `dram__bytes_read.sum`：______ → ______（应约为 1/2，针对 B）
  - TFLOPS：______ → ______（预期 +10%）
- 符合预期？□ 是 □ 否

## 步骤 5：Persistent scheduler（可选）

- 接入了 `PersistentTileScheduler`：□ 是 □ 否
- ncu before / after：
  - `launch__grid_size`：______ → ______
  - TFLOPS：______ → ______（预期 +5%）

---

## v2 最终结果

- 4096 cube：______ TFLOPS（______% of cuBLAS）
- 距离 50% 目标（W11 标线）：达成 □ 是 □ 否
- 距离 70% 目标（W12 CHECKPOINT）：______% 差距

## 复盘

1. 哪一步收益最大？是否符合 README checklist 的预期排序？
2. 哪一步没收益？根因是什么（v1 已经做对、配置不兼容、ncu 测错指标）？
3. 进 W12 之前，把这份日志通读一遍，把所有"未达预期"的项做 root-cause analysis。
