# W5 ex12 — WGMMA atom TV layout 实测产出

> 概念笔记已沉淀进 `study/THINKING.md`（O23-O27 + O3 扩展）。这里只留 ex12 的具体输出、自检答案、待办。

## ex12 输出（`SM90_64x8x16_F16F16F16_SS`, N=8）

```
ThrID:      _128:_1
ThrLayoutVMNK: (_128,_1,_1,_1)
LayoutA_TV: (_128,(_64,_16)):(_0,(_1,_64))     # T-stride=0 → 退化（SS 不分线程）
LayoutB_TV: (_128,(_8,_16)):(_0,(_1,_8))       # T-stride=0 → 退化
LayoutC_TV: ((_4,_8,_4),(_2,_2,_1)):((_128,_1,_16),(_64,_8,_512))  # T-stride≠0 → 真分工
size(tiled_mma) = 128
```

**读出的分工**（C 为 64×8 列优先，offset=m+n*64）：
- 每线程持 4 个 C 值（=2×uint32=4×f16，对上 `CRegisters=uint32_t[2]`）
- thread0 → C 的 (0,0)(8,0)(0,1)(8,1)：间隔点，非连续块
- T 维 (4,8,4)：t1(8) 沿 N 铺 8 列，t0+t2 沿 M 铺行；V 维 (2,2)：v0→+1列, v1→+8行

## 自检答案
1. **128 线程 = 1 warpgroup = 4 warp**（`.sync.aligned` warpgroup 粒度发射）
2. fence(可见性入口) / commit(批次边界) / wait(出口等待) 三正交职责，分开才能流水线 → 见 THINKING O24
3. m64n128k16：m=A/C 的 M 维，n=B/C 的 N 维，k=A/B 的 K 深度
4. fp16 一行 128B 用满 SW128，fp8 一行 64B 用 SW64 → 见 THINKING O3
5. RS 吃寄存器压 occupancy，A 复用多时值得；否则 SS 省寄存器 → 见 THINKING O25

## 待办（需硬件）
- [ ] ex11 单 tile WGMMA 实跑（要 H20）
- [ ] ex12 跑 N=256，验证 C value 维随 N 线性增长（N=8→4 个；N=256→?）
- [ ] 5060 Ti 静态验证：`nvcc -arch=sm_90a -ptx` 有 wgmma.mma_async / sm_120a 无
