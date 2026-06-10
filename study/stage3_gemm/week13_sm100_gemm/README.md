# Week 13 — SM100 → SM120 移植

预计 ~15h
> **硬件**：🟢 5060 Ti（SM120，本地实测 sm120 退化路径 + 静态编译 `sm_120a`，主要是 mma.sync + RMEM 累加器的代码理解）｜ 🔴 B200（SM100，作 UMMA+TMEM+2-SM 完整路径的对照基线）
> 本周承接 W10-W12 的 **SM100 主线 GEMM**——核心改动是把 v3 移植到 SM120：MMA atom 从 UMMA（tcgen05.mma）→ mma.sync，累加器从 TMEM → RMEM，2-SM 配对 → 1-SM，其余 mainloop 框架大体不变

## 目标
- 把 Stage 3 v3（SM100 UMMA + TMEM）移植到 SM120（5060 Ti），跑出正确结果 + 本地性能数字
- 理解 SM120 没有 TMEM / 没有 2-SM 时 pipeline 语义怎么退化
- 产出 `MIGRATION_SM100_TO_SM120.md`，逐行记录 diff 语义

## 读（**由浅入深**：example 入门 → SM120 mainloop → dispatch policy → 对照 SM100）
1. `examples/79_blackwell_geforce_gemm/79a_blackwell_geforce_nvfp4_bf16_gemm.cu` — **先读**：SM120（GeForce）GEMM 入门，看 sm120 模板参数怎么填（narrow precision 为主，FP16 路径同理）
2. `include/cutlass/gemm/collective/sm120_mma_tma.hpp` — SM120 主 mainloop，类名 `MainloopSm120TmaWarpSpecialized`（第 75 行）：累加器在 **RMEM**，MMA 用 `mma.sync`（warpgroup 发射，无 TMEM / 无 2-SM）
3. `include/cutlass/gemm/dispatch_policy.hpp:585+` — `KernelTmaWarpSpecialized{Cooperative,Pingpong}Sm120` 系列 dispatch policy，确认 SM120 有哪些 schedule
4. `include/cutlass/gemm/collective/sm120_blockscaled_mma_tma.hpp` — blockscaled / narrow precision 变体（选读，SM120 的看家路径）
5. **对照**：回看 W10 的 `sm100_mma_warpspecialized.hpp`，逐行对比 UMMA→mma.sync、TMEM→RMEM 怎么退化

## SM100 → SM120 移植清单

| 项 | SM100 写法 | SM120 写法 |
|----|------------|------------|
| MMA atom | UMMA `SM100_MMA_F16BF16_SS`（tcgen05.mma） | `mma.sync` 系列（warpgroup 发射） |
| C accumulator | tmem 的 `tCtAcc` | rmem 的 `tCrC`（退回寄存器） |
| MMA 发射粒度 | 单线程 `elect_one` | warpgroup（无单线程发射） |
| Cluster | `<2,1,1>` 且 2-CTA 也参与 MMA | 退回 1-SM，cluster 仅做 multicast 或 `<1,1,1>` |
| Pipeline | `PipelineTmaUmmaAsync`（含 tmem 同步） | 退回 `PipelineTmaAsync`（无 tmem mbarrier） |
| Epilogue | tmem → rmem → smem → gmem | rmem → smem → gmem（少一跳） |

## 写
- `exercises/ex_sm100_gemm.cu` — 在 Stage 3 v3（SM100）基础上做最少改动移植到 SM120
- `exercises/MIGRATION_SM100_TO_SM120.md` — 逐行记录 diff 语义：**TMEM 怎么退化成 RMEM、2-SM 怎么退到 1-SM、tmem mbarrier 怎么删掉**

## 跑
```bash
cmake -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=120a ..   # 5060 Ti 本地
make study_stage3_w13_ex_sm100_gemm -j
./study_stage3_w13_ex_sm100_gemm 8192 8192 8192
ncu --set full -o sm120_gemm ./study_stage3_w13_ex_sm100_gemm 8192 8192 8192
```

## 自检
1. SM120（5060 Ti）上 cuBLAS FP16 峰值大约多少 TFLOPS？你的 sm120 移植版到了多少？
2. SM120 没有 TMEM，累加器退回 RMEM 后，单 CTA 能开多大的 tile？受什么限制（寄存器压力）？
3. 从 2-SM 退回 1-SM，单个 CTA 的 N tile 宽度怎么变？为什么 SM120 上开不了 SM100 那么大的 N？
4. SM120 的 pipeline 比 SM100 少了哪个 mbarrier？为什么不需要了？
5. 同一份 v3 在 B200（SM100）和 5060 Ti（SM120）上，相对各自 cuBLAS 的占比谁高？瓶颈差在哪？
