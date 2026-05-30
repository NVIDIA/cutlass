# Stage 3 W13 — SM90 v3 → SM100 移植 diff 记录

> README 移植清单的实战展开。每改一处，记录原代码 / 新代码 / 为什么。Stage 3 v3 → ex_sm100_gemm 的改动总量应该 **< 100 行**，其余 90% 框架不变。

## 总览：5 处改动

| 项 | SM90 (v3) 写法 | SM100 写法 | 是哪一层的改动 |
|----|---------------|------------|-----------------|
| 1. MMA atom | `SM90_64x128x16_F16F16F16_SS<Major::K, Major::K>` | `SM100_MMA_F16BF16_SS<half_t, half_t, float, 128, 256, UMMA::Major::K, UMMA::Major::K>` | Layer 1 atom |
| 2. C accumulator | `tCrC = thr_mma.make_fragment_C(tCgC)` (rmem) | `tCtAcc = cta_mma.make_fragment_C(tCgC)` + TMEM alloc | Layer 3 collective |
| 3. Epilogue | `copy(tCrC, tCgC)` 或 RMEM→SMEM→TMA store | `tcgen05.ld` TMEM→RMEM → 写 gmem | Layer 3 collective epilogue |
| 4. Pipeline class | `PipelineTmaAsync` | `PipelineTmaUmmaAsync`（多 1 个 tmem 同步 mbarrier） | `include/cutlass/pipeline/sm100_pipeline.hpp` |
| 5. Cluster + MMA scope | cluster `<2,1,1>` multicast A，但 MMA 是 CTA-local | cluster `<2,1,1>` 时 2-CTA 也参与同一个 MMA（`cta_group::2`）| dispatch policy |

---

## 改动 1：MMA atom

### Before (v3)
```cpp
TiledMMA tiled_mma = make_tiled_mma(
    SM90_64x128x16_F16F16F16_SS<GMMA::Major::K, GMMA::Major::K>{});
```

### After (SM100)
```cpp
TiledMMA tiled_mma = make_tiled_mma(
    SM100_MMA_F16BF16_SS<half_t, half_t, float,
                         /*MmaM*/ 128, /*MmaN*/ 256,
                         UMMA::Major::K, UMMA::Major::K>{});
```

### 为什么
- SM100 用 tcgen05.mma，atom 单条 MMA 是 128×256×16（vs SM90 的 64×N×16）
- A/B 仍从 SMEM 读，但 accumulator 强制在 TMEM 不在 RMEM —— 这驱动了改动 2

---

## 改动 2：C accumulator 改用 TMEM

### Before (v3)
```cpp
ThrMMA thr_mma = mma.get_slice(threadIdx.x);
Tensor tCrC = thr_mma.make_fragment_C(tCgC);  // RMEM, warpgroup spread
clear(tCrC);
```

### After (SM100)
```cpp
// 1. 申请 TMEM
__shared__ uint32_t tmem_base_ptr;
using TmemAllocator = cute::TMEM::Allocator1Sm;
TmemAllocator alloc{};
if (warp0_elect) {
  alloc.allocate(TmemAllocator::Sm100TmemCapacityColumns, &tmem_base_ptr);
}
__syncthreads();

// 2. fragment_C 现在产出 TMEM tensor
ThrMMA cta_mma = tiled_mma.get_slice(0);   // SM100 是 CTA-scope 不是 thread-scope
Tensor tCtAcc = cta_mma.make_fragment_C(tCgC);
tCtAcc.data() = tmem_base_ptr;

// 3. 第一条 MMA 清零 TMEM 累加器（不再用 clear()）
tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;  // 第一条 MMA 自带清零
```

### 为什么
- TMEM 是新的分化硬件，必须运行时 alloc（不像 RMEM 是编译期分配）
- `cta_group::1` 单 SM 独占自己的 TMEM；`cta_group::2` 则两个 SM 联合编址（改动 5 用）
- ScaleOut::Zero/One 取代 `clear(tCrC)`：第一条 MMA 写零，后续 MMA 累加

---

## 改动 3：Epilogue 从 RMEM 改成 TMEM → RMEM → GMEM

### Before (v3)
```cpp
copy(tCrC, thr_mma.partition_C(gC));  // RMEM 直接写 GMEM
```

### After (SM100)
```cpp
// TMEM 不能直接写 GMEM —— 必须先 tcgen05.ld 搬回 RMEM
TiledCopy t2r = make_tmem_copy(SM100_TMEM_LOAD_32dp32b1x{}, tCtAcc);
ThrCopy   thr_t2r = t2r.get_slice(threadIdx.x);
Tensor tDtAcc = thr_t2r.partition_S(tCtAcc);   // TMEM source
Tensor tDgC   = thr_t2r.partition_D(tCgC);     // GMEM dest
Tensor tDrAcc = make_tensor<float>(shape(tDgC));
copy(t2r, tDtAcc, tDrAcc);                     // TMEM -> RMEM
copy(tDrAcc, tDgC);                            // RMEM -> GMEM
```

### 为什么
- TMEM 只有 `tcgen05.ld/st` 能访问，普通 store 指令不支持
- 这就是 W8 已经做过的 ex27 round-trip 模式，搬过来即用

---

## 改动 4：Pipeline 类换 `PipelineTmaUmmaAsync`

### Before / After
- 类名：`PipelineTmaAsync` → `PipelineTmaUmmaAsync`
- 多一个 mbarrier：**tmem-consumer barrier**（参考 `include/cutlass/pipeline/sm100_pipeline.hpp:200-400`）

### 为什么
- SM90 的 pipeline 只有"producer (TMA) ↔ consumer (WGMMA)"两段
- SM100 多了"MMA 完成 → TMEM 释放"这第三个事件 —— TMEM 不能在 MMA 没完之前被覆写
- `umma_arrive(&mbar)` 让 MMA 完成绑定到 mbarrier（W8 ex28 已经用过）

---

## 改动 5：cluster `<2,1,1>` + cta_group::2

### Before (v3)
```cpp
dim3 dimCluster(2, 1, 1);  // multicast A: 2 个 CTA 共享 A 的 multicast
// MMA 仍在每个 CTA 自己内部跑
```

### After (SM100)
```cpp
dim3 dimCluster(2, 1, 1);
TiledMMA tiled_mma = make_tiled_mma(
    SM100_MMA_F16BF16_SS<..., UMMA::Major::K, UMMA::Major::K>{},
    Layout<Shape<_2,_1,_1>>{});  // AtomThrID = 2，表示 atom 跨 2 个 CTA（TPC pair）
// MMA atom 自己变成 cta_group::2，2 个 SM 锁步算同一条 MMA
```

### 为什么
- 这就是你 sm100 笔记 一.3 揭示的"TPC 成为显式编程边界"在代码里的落地点
- MMA_M 翻倍到 256（每个 CTA 算 128），两个 SM 各算一半 → 共享 B operand 减半 SMEM 占用
- 5060 Ti(SM120) 不能跑 `cta_group::2`（cluster 退化到 1×1×1）—— 本周这部分必须租 B200 跑

---

## 总改动量统计（你做完后填）

- v3 总行数：______
- ex_sm100_gemm 总行数：______
- 实际改动行数：______（应 < 100）
- 大部分行数差异来自：______（注释 / 类型别名展开 / 完全新增的 epilogue）
