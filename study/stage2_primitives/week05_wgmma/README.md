# Week 5 — WGMMA (Warpgroup MMA)

预计 ~15h
> **硬件**：🟢 5060 Ti（读源码 + 静态编译 `sm_90a`，看 PTX）｜ 🟡 H20（实际跑 WGMMA + ncu 性能数字）  
> **5060 Ti 注意**：SM120 没有 WGMMA，本周只能读+静态编译，跑要租 H20

> **认知锚点**（对照 [`sm90_hopper_overview.md`](../sm90_hopper_overview.md)）：
> WGMMA = **进化定律 · Scale Up 主轴 A1**（warp→warpgroup 粒度放大）+ **Async 主轴交汇点**（`wgmma.mma_async` 异步发射）。
> 学的时候时刻问自己：这一步是在"放大单次操作"（Scale Up）还是"让操作异步重叠"（Async）？
> 对照 [`sm120_fake_blackwell_overview.md`](../sm120_fake_blackwell_overview.md)：WGMMA 是消费卡**砍掉**的（绑大矩阵 + warp spec），5060 Ti 退回 `mma.sync` —— 本周末尾会亲手验证这条。

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
- `exercises/ex12_wgmma_layout_print.cu` — **先做这个**（纯 host，任意卡可跑）：打印 N=8/64/128/256 的 WGMMA atom 的 LayoutA_TV / LayoutB_TV / LayoutC_TV，亲眼看 warpgroup=128 接线
- `exercises/ex11_wgmma_minimal.cu` — 单 CTA / 单 k-tile 64x64x64 TN GEMM，把 swizzled smem → cp.async → 一条 `cute::gemm` 发 WGMMA → fence/commit/wait → epilogue 主干走通（要 H20 实跑）

## 跑
```bash
# ex12 任意卡都能跑（包括 5060 Ti），它只是 layout 代数
make study_stage2_w05_ex12_wgmma_layout_print -j && ./study_stage2_w05_ex12_wgmma_layout_print
# ex11 要 Hopper；在 5060 Ti 上会因 arch 检查直接跳过
make study_stage2_w05_ex11_wgmma_minimal -j && ./study_stage2_w05_ex11_wgmma_minimal
```

### 🟢 5060 Ti 专属验证：亲手确认 SM120 没有 WGMMA
对照 `sm120_fake_blackwell_overview.md` 的"砍掉 wgmma"那条，用静态编译把它变成可触摸的事实：
```bash
# sm_90a 能编出 wgmma.mma_async；sm_120a 编不出（或退化）
nvcc -arch=sm_90a  -ptx exercises/ex11_wgmma_minimal.cu -I../../../../include -o /tmp/sm90.ptx && grep -c wgmma.mma_async /tmp/sm90.ptx
nvcc -arch=sm_120a -ptx exercises/ex11_wgmma_minimal.cu -I../../../../include -o /tmp/sm120.ptx 2>&1 | head  # 观察报错 / 无 wgmma
```
> 这一步把 overview 的"消费卡砍了什么"从结论变成你自己跑出来的证据。

## 自检
1. 一个 WGMMA 指令需要几个 warp 协作？为什么是 128 线程？
2. 为什么 `wgmma.fence` + `wgmma.commit_group` + `wgmma.wait_group` 是三步而不一步？
3. `wgmma.mma_async.sync.aligned.m64n128k16.f16.f16.f16` 中 m/n/k 各对应什么矩阵维度？
4. `Layout_MN_SW128_Atom` 中的 `SW128` 表示 128 byte swizzle，为什么 BF16/FP16 的 K-major 习惯 SW128 而 FP8 用 SW64？
5. RS 模式下 A 在寄存器，对 register pressure 有多大影响？什么时候必须用 SS？
