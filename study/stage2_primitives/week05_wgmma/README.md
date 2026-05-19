# Week 5 — WGMMA (Warpgroup MMA)

预计 ~15h
> **硬件**：🟢 5060 Ti（读源码 + 静态编译 `sm_90a`，看 PTX）｜ 🟡 H20（实际跑 WGMMA + ncu 性能数字）  
> **5060 Ti 注意**：SM120 没有 WGMMA，本周只能读+静态编译，跑要租 H20

## 目标
- 看到一条 `wgmma.mma_async.sync.aligned.m64nNk16` 能拆出每段含义
- 能解释 SS 模式下为什么 smem 必须是 swizzled 128B-aligned
- 能跑通 `wgmma_sm90.cu` 并解释每行作用

## 读
- `include/cute/arch/mma_sm90_gmma.hpp:42-100` — `wgmma` 同步原语 `warpgroup_arrive` / `warpgroup_wait<N>` / `warpgroup_commit_batch` / `warpgroup_fence_operand`（思想跟 cp.async fence/commit/wait 对称）
- `include/cute/arch/mma_sm90_gmma.hpp:139-225` — 挑 2 个 atom struct 对比：`MMA_64x8x16_F16F16F16_SS` vs `_RS`，看 PTX inline asm 差别（其余 60+ 个 size 变体跳）
- `include/cute/arch/mma_sm90_desc.hpp` — GMMA descriptor（64-bit 编码 SMEM 操作数），全文件 151 行
- `include/cute/atom/mma_traits_sm90_gmma.hpp:71-130` — WGMMA atom 的 layout
  ```cpp
  using Layout_MN_SW128_Atom_Bits = ComposedLayout<
      Swizzle<3,4,3>, smem_ptr_flag,
      Layout<Shape<_1024,_8>, Stride<_1,_1024>>>;
  ```
  - `upcast<sizeof_bits<Type>>` 把 bit 单位转换到元素单位
- `examples/cute/tutorial/hopper/wgmma_sm90.cu` — 最小 WGMMA 示例
- 跳过 `mma_sm90_gmma_ext.hpp`（60k 行自动生成枚举）和 `mma_sm90_gmma_sparse_ext.hpp`（56k 行）；sparse 留到 Stage 5 MoE

## 写
- `exercises/ex11_wgmma_minimal.cu` — 复刻 `wgmma_sm90.cu` 的核心逻辑，写注释解释每一步
- `exercises/ex12_wgmma_layout_print.cu` — 打印各种 N 维度（N=8,16,...,256）的 WGMMA atom 的 LayoutA_TV / LayoutB_TV / LayoutC_TV

## 跑
```bash
make study_stage2_w05_ex11_wgmma_minimal -j && ./study_stage2_w05_ex11_wgmma_minimal
make study_stage2_w05_ex12_wgmma_layout_print -j && ./study_stage2_w05_ex12_wgmma_layout_print
```

## 自检
1. 一个 WGMMA 指令需要几个 warp 协作？为什么是 128 线程？
2. 为什么 `wgmma.fence` + `wgmma.commit_group` + `wgmma.wait_group` 是三步而不一步？
3. `wgmma.mma_async.sync.aligned.m64n128k16.f16.f16.f16` 中 m/n/k 各对应什么矩阵维度？
4. `Layout_MN_SW128_Atom` 中的 `SW128` 表示 128 byte swizzle，为什么 BF16/FP16 的 K-major 习惯 SW128 而 FP8 用 SW64？
5. RS 模式下 A 在寄存器，对 register pressure 有多大影响？什么时候必须用 SS？
