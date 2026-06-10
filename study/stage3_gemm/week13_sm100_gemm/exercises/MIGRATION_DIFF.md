# Stage 3 W13 — SM100 v3 → SM120 移植 diff 记录

> ⚠️ 方向反转：W12 产出的是 SM100 v3（UMMA / TMEM / 2-SM）。本周（W13）把它**移植到 SM120**
> （5060 Ti：mma.sync / RMEM / 无 2-SM / 1-SM）。
> 每改一处，记录原代码（SM100 v3）/ 新代码（SM120）/ 为什么。改动总量应该 **< 100 行**，其余 90% 框架不变。

## 总览：5 处改动（SM100 → SM120 退化方向）

| 项 | SM100 (v3) 写法 | SM120 写法 | 是哪一层的改动 |
|----|---------------|------------|-----------------|
| 1. MMA atom | `SM100_MMA_F16BF16_SS<half_t, half_t, float, 128, 256, UMMA::Major::K, UMMA::Major::K>` | SM120 `mma.sync` atom（CTA-local，N 回到 128） | Layer 1 atom |
| 2. C accumulator | `tCtAcc = cta_mma.make_fragment_C(tCgC)` + TMEM alloc | `tCrC = thr_mma.make_fragment_C(tCgC)` (RMEM) + `clear()` | Layer 3 collective |
| 3. Epilogue | `tcgen05.ld` TMEM→RMEM → 写 gmem | `copy(tCrC, tCgC)` RMEM→GMEM 直写 | Layer 3 collective epilogue |
| 4. Pipeline class | `PipelineTmaUmmaAsync`（多 1 个 tmem 同步 mbarrier） | `PipelineTmaAsync`（退回两段） | `include/cutlass/pipeline/sm100_pipeline.hpp` → SM120 退化 |
| 5. Cluster + MMA scope | cluster `<2,1,1>` + `cta_group::2`（2-CTA 同算一个 MMA） | cluster 退化 `<1,1,1>`，MMA 是 CTA-local（删 2-SM） | dispatch policy |

---

## 改动 1：MMA atom

### Before (SM100 v3)
```cpp
TiledMMA tiled_mma = make_tiled_mma(
    SM100_MMA_F16BF16_SS<half_t, half_t, float,
                         /*MmaM*/ 128, /*MmaN*/ 256,
                         UMMA::Major::K, UMMA::Major::K>{});
```

### After (SM120)
```cpp
// SM120 没有 UMMA/tcgen05，回到 mma.sync 的 warp/warpgroup atom，CTA-local，N 回到 128
TiledMMA tiled_mma = make_tiled_mma(
    /* SM120 mma.sync F16F16F32 atom */ ... {});
```

### 为什么
- SM120 没有 `tcgen05.mma`，单条 MMA 走 `mma.sync`（warp 级），不是 128×256×16 的 UMMA atom
- accumulator 也随之从 TMEM 退回 RMEM —— 这驱动了改动 2

---

## 改动 2：C accumulator 从 TMEM 退回 RMEM

### Before (SM100 v3)
```cpp
// TMEM alloc
__shared__ uint32_t tmem_base_ptr;
using TmemAllocator = cute::TMEM::Allocator1Sm;
TmemAllocator alloc{};
if (warp0_elect) { alloc.allocate(TmemAllocator::Sm100TmemCapacityColumns, &tmem_base_ptr); }
__syncthreads();

ThrMMA cta_mma = tiled_mma.get_slice(0);    // CTA-scope
Tensor tCtAcc = cta_mma.make_fragment_C(tCgC);
tCtAcc.data() = tmem_base_ptr;
tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;  // 第一条 MMA 自带清零
```

### After (SM120)
```cpp
// 不需要 TMEM alloc：累加器编译期分配在寄存器
ThrMMA thr_mma = tiled_mma.get_slice(threadIdx.x);   // thread-scope（不是 CTA-scope）
Tensor tCrC = thr_mma.make_fragment_C(tCgC);          // RMEM
clear(tCrC);                                          // 用 clear() 代替 ScaleOut::Zero
```

### 为什么
- SM120 累加器在寄存器，编译期分配，不需要运行时 alloc TMEM
- 没有 `cta_group::2`，回到 thread/warpgroup-scope 的 RMEM fragment
- `clear()` 取代 `ScaleOut::Zero/One`：mma.sync 是累加语义，靠 clear 先清零

---

## 改动 3：Epilogue 从 TMEM → RMEM → GMEM 退回 RMEM → GMEM 直写

### Before (SM100 v3)
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

### After (SM120)
```cpp
// 累加器本就在 RMEM，直接写 GMEM
copy(tCrC, thr_mma.partition_C(gC));           // RMEM -> GMEM
```

### 为什么
- SM120 没有 TMEM，累加器一直在 RMEM —— 省掉 `tcgen05.ld` 这一跳
- epilogue 反而比 SM100 简单（这是少数"退化更简单"的点）

---

## 改动 4：Pipeline 类从 `PipelineTmaUmmaAsync` 退回 `PipelineTmaAsync`

### Before / After
- 类名：`PipelineTmaUmmaAsync` → `PipelineTmaAsync`
- 少一个 mbarrier：去掉 **tmem-consumer barrier**

### 为什么
- SM100 的 pipeline 有三段："producer (TMA) → consumer (UMMA) → TMEM 释放"
- SM120 没有 TMEM 这第三个事件，退回 SM90 时代的两段："producer (TMA) ↔ consumer (mma.sync)"
- 不再需要 `umma_arrive`，mma.sync 完成由 warp 同步保证

---

## 改动 5：cluster `<2,1,1>` + cta_group::2 → cluster 退化 `<1,1,1>`

### Before (SM100 v3)
```cpp
dim3 dimCluster(2, 1, 1);
TiledMMA tiled_mma = make_tiled_mma(
    SM100_MMA_F16BF16_SS<..., UMMA::Major::K, UMMA::Major::K>{},
    Layout<Shape<_2,_1,_1>>{});  // AtomThrID = 2，atom 跨 2 个 CTA（TPC pair），cta_group::2
```

### After (SM120)
```cpp
dim3 dimCluster(1, 1, 1);        // SM120 不支持 2-SM UMMA，cluster 退化
TiledMMA tiled_mma = make_tiled_mma(
    /* SM120 mma.sync atom */ ... {});  // 无 AtomThrID=2，MMA 完全 CTA-local
```

### 为什么
- SM120 不能跑 `cta_group::2`（没有 2-SM UMMA），cluster 退化到 1×1×1
- MMA_M 从 256 回到 128（单 CTA 算一个完整 tile），不再两个 SM 各算一半
- 这是 SM100 v3 在 5060 Ti 上必须砍掉的最大特性 —— 也是性能差距的主要来源之一

---

## 总改动量统计（你做完后填）

- SM100 v3 总行数：______
- ex_sm100_gemm（SM120 目标）总行数：______
- 实际改动行数：______（应 < 100）
- 大部分行数差异来自：______（注释 / 类型别名展开 / 退化掉的 TMEM alloc + epilogue round-trip）
