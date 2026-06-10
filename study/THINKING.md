# 思考 / 踩坑 / 方法论

> 跨 stage 的概念笔记、硬件约束、方法论。下一个接手仓库的 agent **务必读完再开始**——避免重复同样的错误。

---

## 一、硬件 / 编译

- **拥有的硬件**：**5060 Ti 16GB (SM120, Blackwell consumer)** —— 日常学习主战
- **租赁硬件**：H20 (SM90) ~$1-3/hr、B200 (SM100) ~$5-15/hr —— 只在需要 WGMMA / UMMA 真实跑通 + ncu 性能数字时短 sprint 用
- **目标**：手写 + 极致优化 Hopper/Blackwell GEMM、FlashAttention、Sparse MoE

**5060 Ti (SM120) 真实能力**（详见 O20）：
- **能跑**：W1-W4（SM80 atom）、W6 TMA、W7 Pipeline+Cluster、W9-W12 + W14-W21 的 WarpSpec 框架（用 `MainloopSm120TmaWarpSpecialized` 代替 WGMMA mainloop）、fp4/fp6 块缩放 mma.sync 量化实验
- **跑不了**：W5 WGMMA atom（要 H20）、W8/W13/W18 UMMA + TMEM（要 B200）、2-SM 配对 cluster（要 B200）

**Stage 内部 SM 串行**：每个 stage 先 SM90 优化做透、再 SM100 迁移，不并行。Stage 2 是例外——一次性消化 SM90 + SM100 prim 比拆两次学好（UMMA 文档大量"differs from WGMMA in X"）。

**编译命令**：`cmake -DCUTLASS_ENABLE_STUDY=ON -DCUTLASS_NVCC_ARCHS=120 ..`（5060 Ti）/ `90` (H20) / `100a` (B200) / `120;90;100a` (跨架构通用)

---

## 二、核心概念笔记

### O1. coalesce 的 merge 条件方向

`bw_coalesce` (`layout.hpp:780-814`) 的实际 merge 规则是 **`d_next == s_prev × d_prev`**（accumulator's stride 等于 incoming dim 的 size × stride），从右往左扫。
- 实战效果：row-major 永远不能 coalesce 成 1D（除非某维 size=1），col-major 才友好。
- `ex03_coalesce.cu` 文件头注释里写的 "`s0:s1*d1   s1:d1  =>  merge`" 方向**反了**，以源码为准。

### O2. bank conflict "N-way" 的定义

"N-way conflict" = **同一 cycle 撞同一 bank 的最大线程数**。
- 8x8 fp32 col=0 访问：8 lanes 命中 banks {0, 8, 16, 24} 各 2 次 → **2-way conflict**（不是 8-way）。
- 32x32 fp32 col=0 访问：32 lanes 全打 bank 0 → 32-way。

### O3. SW32/SW64/SW128 不是方 tile

CUTLASS 的标准 swizzle 都是 **8 行 × N chunks of 16B** 的非方 tile：
- SW128 = `Swizzle<3,4,3>` = 8 行 × 8 chunks（128B/row）
- SW64 = `Swizzle<2,4,3>` = 8 行 × **4** chunks（64B/row）—— **不是 4×4 tile**
- SW32 = `Swizzle<1,4,3>` = 8 行 × 2 chunks（32B/row）

S=3 是因为 Hopper 约定 **row 字段对齐到 offset 的 bit 7+**（外层 stride 撑出来），公式跨 SW 系列统一。

**三参数的 bank 几何对账**（机制 `apply(off)=off ^ ((off & yyy_msk)>>S)`）：
- **M**：`2^M=16`B = 一次 **128-bit 访问 = 4 banks**（不动的原子块）。M=4 不是"4B=1bank"，是 smem 高效访问以 128-bit 为单位。
- **M+S**：swizzle 周期 = 连续方向宽度 = `2^(M+S)` 字节。SW128 时 `2^7=128`B = 一条完整 bank line（32 banks×4B），S=3 来历。
- **B**：周期内打散几路。`2^B` 个 16B chunk 进拉丁方；B=3→8 chunk 填满 32 banks。上限 B=3（再大源/目标 bit 段重叠非法，且已满一条 line）。
- swizzle 主语是 **wgmma 地址生成器 / cp.async / TMA 写入**，不是"32 线程各自读"。写读同一 swizzle，逻辑不变、物理打散。

**四档 atom 的真实几何**（`mma_traits_sm90_gmma.hpp:75-104`，定义在 **bit** 域再 `upcast<sizeof_bits<T>>`）。另一维恒 `_8`(=core matrix 8 行)：

| atom | Swizzle | 连续 bit | =字节 | =banks | fp16 元素 |
|------|---------|------|------|------|------|
| INTER(无) | `<0,4,3>` | 128 | 16B | 4 | 8 |
| SW32 | `<1,4,3>` | 256 | 32B | 8 | 16 |
| SW64 | `<2,4,3>` | 512 | 64B | 16 | 32 |
| SW128 | `<3,4,3>` | 1024 | 128B | 32 | 64 |

**⚠️ 纠正旧算式**：fp16 SW128 连续方向 = `1024bit/16 = 64 元素 × 2B = 128B`，正确算式 **`64×2=128`**，那个 64 来自 `1024÷16`，**不是** WGMMA 的 atom-K=16（两个 K 别混：atom-K=16 是一条 wgmma 的 MMA 深度；swizzle 连续维=64 元素是 smem 摆放周期，无关）。atom 连续方向**恒 128B，与 dtype 无关**（fp8 是 128 元素仍 128B）。

**swizzle 是"尺寸匹配"不是"质量旋钮"**：atom 连续字节宽必须 = 你 smem tile 连续维的字节宽。
- 数据宽 128B(fp16 K-tile=64) → SW128 打满 32 bank。
- 数据宽 64B(fp16 K-tile=32 / fp8 K=64) → **只占 16 bank**，SW128 套不进(整除不进 tile)，SW64 在这 16 bank 内已无冲突 = 该 case 的"打满"。
- 用大了套不进，用小了 8 行在更宽数据里还撞。"只有 SW128 用满 32 bank"对，但不代表 SW64/32 没用——窄数据时它们才是"打满"。

### O4. CuTe 的 B 写作 `(N, K)`，不是 BLAS 的 `(K, N)`

权威出处：`media/docs/cpp/cute/0x_gemm_tutorial.md:80-81`：
> "CuTe follows the convention that the semantics of matrix modes is **`(M,K)` for `A`, `(N,K)` for `B`, and `(M,N)` for `C`**."

理由：让 A、B 都把 K 放在最后一维，K-reduce 循环写起来对称。**讲解时永远用 CuTe 约定**——除非明确在讨论 BLAS API。

### O5. CuTe 的 "X-major" 比 BLAS T/N 更准

`0x_gemm_tutorial.md:103`：
> "Instead of row-major or column-major (or Transposed and Not-Transposed), we have found it much more convenient to say that a matrix is **'M-major'**, **'N-major'**, or **'K-major'** based on which mode has stride-1."

BLAS↔CuTe 对照表（原文 line 107-112）：

| BLAS | A Majorness | A Layout | B Majorness | B Layout |
|------|-------------|----------|-------------|----------|
| NT   | M-major     | `(M,K):(1,ldA)` | N-major | `(N,K):(1,ldB)` |
| **TN** | **K-major** | `(M,K):(ldA,1)` | **K-major** | `(N,K):(ldB,1)` |
| NN   | M-major     | `(M,K):(1,ldA)` | K-major | `(N,K):(ldB,1)` |
| TT   | K-major     | `(M,K):(ldA,1)` | N-major | `(N,K):(1,ldB)` |

**TN = A、B 都 K-major** = 跟 MMA-TN 硬件天然一致。

### O6. Shape 写法顺序不重要，stride 才是真理

**Layout 物理顺序由 stride 决定，shape mode 写在前还是后只是命名**。`(M,K):(K,1)` 和 `(K,M):(1,K)` 指向同一段内存。CuTe 钉死 `(M,K), (N,K)` 是为了**库代码用统一标签**，物理上你随便换都行。

### O7. MMA-TN vs GEMM-TN 是两个层级

- **MMA-TN**（硬件层）：`mma.sync.aligned.m16n8k16.row.col` 强制 A、B K-contig。硬件只支持 TN，**没得选**。
- **GEMM-TN**（用户层）：用户传入的 A、B 在 GMEM 的 stride 配置。NN/NT/TN/TT 都可选，TN 最常用因为跟 MMA-TN 天然一致、无需 SMEM 转置。

### O8. 自下而上读源码

源码该 **PTX → Traits → Atom → Tiled → 算法** 这个方向读。先看 wrapper 再看里面 wrap 啥本末倒置——读者看到 `ALayout`/`ValLayoutSrc` 这些字段时还不知道是啥的容器。

### O9. 反对"空对空"练习

脱离实战场景的纯数学 / bit 推导练习无价值。**bank conflict / ncu 实测**之类的东西**放到能跑真实 kernel 的阶段做**（W10 WGMMA mainloop / W14 FA），不在 W2 单独搞 demo。

### O10. Divide 家族 + local_tile / local_partition 大图

**核心心智模型**：所有 divide / partition 函数都站在 `zipped_divide` 这一个节点之上，只是切刀方向或形状嵌套不同。

```
       composition + complement     (两个底层原语)
                  │
                  ▼
           logical_divide            按"原维度"嵌套
        ((BLK_M, m), (BLK_N, n))
                  │
                  │  tile_unzip 重组：按"角色"分组
                  ▼
           zipped_divide             ◄═══ 核心节点
        ((BLK_M, BLK_N), (m, n))
                  │
       ┌──────────┼──────────────────────┐
       │          │                      │
   形状变体     切 tile 维             切 rest 维
       │          ▼                      ▼
       │   outer_partition       inner_partition
       │   保留 rest             保留 tile
       │          │                      │
       │          ▼                      ▼
       │   local_partition       local_tile
       │   (thr_layout, thr_idx) (tile_shape, coord)
       │
       ├── tiled_divide  ((BLK), m, n)
       └── flat_divide   (BLK_M, BLK_N, m, n)
```

**5 个 divide** 指向同一坨地址，只是 shape tuple 嵌套方式不同：

| 函数 | shape | 怎么取第 (i, j) 块 |
|------|------|------|
| `logical_divide` | `((BLK_M, m), (BLK_N, n))` | `result((_,i), (_,j))` |
| `zipped_divide` | `((BLK_M, BLK_N), (m, n))` | `result(_, (i, j))` |
| `tiled_divide` | `((BLK_M, BLK_N), m, n)` | `result(_, i, j)` ← 最常用 |
| `flat_divide` | `(BLK_M, BLK_N, m, n)` | `result(_, _, i, j)` |

**2 个 partition** 在 zipped_divide 上切一刀：

| 函数 | 切哪边 | 保留哪边 | 语义 |
|------|--------|----------|------|
| `inner_partition` ≈ `local_tile` | 切 rest | 保留 tile | "我是第 (i,j) 个 CTA，给我那一块 tile" |
| `outer_partition` ≈ `local_partition` | 切 tile | 保留 rest | "我是第 t 个 thread，给我散在各个 tile 里的同一位置" |

**决策树**：
```
我要干啥？
├─ 算法层推导 layout                      → tiled_divide / flat_divide
├─ kernel 入口，CTA 取自己那块            → local_tile
├─ thread 协作搬一片 tile（GMEM→SMEM）    → local_partition
├─ 用 TiledCopy 抽象的协作搬运            → TiledCopy::partition_S/D
└─ 用 TiledMMA 给每 thread 取 MMA fragment → TiledMMA::partition_A/B/C
```

`TiledCopy::partition_S/D` 内部本质就是 `outer_partition` + 自动算的 thr_layout。`TiledMMA::partition_A/B/C` 在此基础上还套 (T, V) → element 的 ALayout 硬件接线。

### O11. Per-mode complement vs whole-layout complement——不该直接对比

`zipped_divide` 用 **per-mode complement**：tuple tiler 拆开，每个 mode 在**坐标空间**做 1D complement（cotarget = 该 mode size）。
直接调 `complement(layout, M)` 是 **whole-layout complement**：单个多维 layout 在**地址空间**做 complement（cotarget = 总尺寸）。

**两边输入根本不是同一类对象**——前者吃 tuple of 1D，后者吃单个多维 layout。强行对比要做空间转换，即使能凑出"image 集合相同"（紧凑 L 时），也不等于它们可互换。

它们是**不同 API 解决不同问题**：
- per-mode：tuple tiler API 配合 logical_divide 的 `((tile),(rest))` 嵌套结构，**为 tile-and-grid 切分服务**
- whole-layout：服务于代数原语场景（`logical_product` 复制块、`right_inverse` 求逆、填补非紧凑 layout 的洞、扩展 codomain）

### O12. MMA atom 内的 ALayout/BLayout/CLayout 是硬件接线图

**不是** GMEM→SMEM 加载映射，而是 MMA 指令执行那一刻、(lane_id, val_id) → 该元素在原子 tile 中的位置。

```
A 已经在 RMEM 里
    ↓
ALayout: (lane_id, val_id) → A 矩阵中的元素索引
    ↓
mma.sync 指令（硬件接线钉死）
```

**SM80 m16n8k16 fp16 ALayout 拆解**：
```
ALayout = ((_4, _8), (_2, _2, _2)) : ((_32, _1), (_16, _8, _128))
            └──T=32──┘└────V=8─────┘
```
- Thread mode (4, 8): t0=lane%4=threadID_in_group, t1=lane/4=groupID
- Value mode (2, 2, 2): (reg-internal pair, low/high-M, low/high-K) — 对应 4 个 .b32 register {a0,a1,a2,a3}

设计哲学：硬件接线包进 Layout 函数 → 编译期零开销 → 跨架构统一，上层 cute::gemm 不需要知道架构。

### O13. make_fragment_A/B/C 不只做检查

`mma_atom.hpp:120-195` 的三件事：

1. **检查**（`CUTE_STATIC_ASSERT_V`）：rank≥3、V 维 size 匹配 atom 期望、元素类型匹配
2. **分配寄存器存储**：
   - `make_fragment_C` 永远新建 RMEM tensor（C 是累加器）
   - `make_fragment_A/B`：若 `FrgTypeA` 是 view 类型，返回输入的 reinterpret view；否则新建
3. **跨架构选 view vs copy**：
   - SM80：A/B 必须在 RMEM → 新建寄存器存储
   - SM90 (WGMMA)：A/B 在 SMEM 由硬件 descriptor 读 → 返回 SMEM view，不复制
   - SM100 (UMMA)：类似 SMEM/TMEM view

让上层 `cute::gemm` 跨架构代码不变——同样调 `make_fragment_A`，SM80 分配 RMEM、SM90 给 SMEM view。

### O14. mma_unpack 是 Tensor → PTX 的胶水

`mma_traits.hpp:113` 的 `mma_unpack` 把 4 个 Tensor 翻译成位置参数喂给 `MMA_Op::fma`（裸 inline asm）：

1. 静态断言 4 个 tensor 都在 RMEM
2. `recast<RegTypeA>(A)`：把 `Tensor<half_t, ...>` shape (V=8) 重解释为 `Tensor<uint32_t, ...>` shape (V=4)
3. size 校验：recast 后的元素数必须等于 PTX 接口要的 register 数
4. `detail::explode`：用 integer pack expansion 展开成 N 个 `uint32_t&` 位置参数，调用 `MMA_Op::fma(d0, d1, a0, ..., a3, b0, b1, c0, c1)`

设计哲学：架构特化的 raw `fma` 函数手写 inline asm（每架构一份）；通用 `mma_unpack` 通过 recast + explode 适配任意 register 数。

### O15. partition_X 输出 VMK/VNK/VMN

`partition_C(tile_tensor)` 返回 **rank-3 tensor**：

| 函数 | 输出 shape | 含义 |
|------|-----------|------|
| `partition_A(gA)` | `(V, RestM, RestK)` | V = atom 内 per-thread 持值数（A 是 8）；RestM/K = 该 thread 沿 M/K 覆盖几个 atom |
| `partition_B(gB)` | `(V, RestN, RestK)` | 类似 |
| `partition_C(gC)` | `(V, RestM, RestN)` | C 没有 K |

V 维 size 是 atom 钉死的常量；RestM/RestN/RestK 跟着用户传进来的 tile size scale。`partition_X` 输出仍在原 memory（GMEM/SMEM），**只是 layout 换成 thread 视角**。配 `make_fragment_X` 才得到 register tensor。

### O16. cute::gemm 只占完整 GEMM kernel 的 ~1 行

`cute::gemm(mma, rA, rB, rC)` 只是**最内层的 mma 累加 + serpentine 优化**。完整 sgemm_sm80 ~150 行里，cute::gemm 占 1 行，其余是 local_tile + TiledCopy + cp.async + K-loop pipeline + epilogue。

### O17. GEMM-TN 实战占主流 80%+

GEMM-TN（A、B 都 K-major）在 GMEM 的 stride 配置**天然跟 MMA-TN 的硬件需求一致**——`cp.async` 灌进 SMEM 后 `ldmatrix` 直送 register，**无 SMEM 转置中转**。

其它三种 (NN/NT/TT) 都需要在 SMEM 转置部分操作数。业界 fp16/bf16 tensor core 生产 kernel ~80% 走 TN。PyTorch `torch.matmul(A, B)` 两个 row-major 实际是 TT 配置，后端通常先 transpose B 转成 TN。

### O18. local_partition 实现：outer_partition + thr_layout.get_flat_coord

源码 `tensor_impl.hpp:1079`：
```cpp
local_partition(tensor, thr_layout, thr_idx) {
  return outer_partition(tensor,
                         product_each(shape(thr_layout)),     // ① 每 thread tile size
                         thr_layout.get_flat_coord(thr_idx)); // ② thread idx → 多维 coord
}
```

`outer_partition` 跟 `inner_partition`（即 `local_tile`）相反：切 tile 维保留 rest 维。每个 thread 拿到散在各 tile 中、跟它角色一致的元素，而不是一整块 tile。典型场景：GMEM→SMEM 协作搬运，32 thread 各拿 4 fp16 形成合并访问。

### O19. complement 要求输入是单射 layout

源码 `layout.hpp:1203`：
```cpp
static_assert(not is_constant<0, decltype(new_shape)>::value,
              "Non-injective Layout detected in complement.");
```

非单射输入（如 `(2,2):(1,1)` 有两个坐标命中同一地址）会让 `new_shape` 算出 0，**编译失败**。源码先 `filter(layout)` 去 stride-0 和 size-1 modes，但剩下的必须单射。语义：complement 是"填补 L 没 hit 的地址"，L 内部 overlap 时"hit 哪些"和"hit 多少次"是两个概念。

### O20. SM120（5060 Ti）能力 — 不是 SM100 子集，也不是 SM80 加一点

源码 cross-check 结论：**SM120 ≈ "SM90 软件栈 + fp4/fp6 块缩放 mma.sync"**，跟 SM100 是**不同分支**（不是父子）。

| Cap | TMA | Cluster | WarpSpec 主循环 | MMA path | fp4/fp6 + 块缩放 | UMMA + TMEM |
|-----|-----|---------|----------------|----------|------------------|--------------|
| SM80 | ❌ | ❌ | ❌ | mma.sync (RMEM) | ❌ | ❌ |
| SM90 | ✅ | ✅ | ✅ | **WGMMA** (warpgroup async, RMEM) | ❌ | ❌ |
| **SM120 (5060 Ti)** | ✅ | ✅ (SM90 风格) | ✅ | **mma.sync** (warp issue, RMEM, 新 fp4/fp6/fp8 类型) | ✅ | ❌ |
| SM100 (B200) | ✅ | ✅ (含 2-SM 配对) | ✅ | **UMMA** (`tcgen05.mma`, 单线程 issue, TMEM) | ✅ | ✅ |

源码证据：
- `config.hpp:155-156` 启用 `CUTE_ARCH_MMA_SM120_ENABLED` + `CUTE_ARCH_TMA_SM120_ENABLED`
- `dispatch_policy.hpp:1430` 有 `MainloopSm120TmaWarpSpecialized`（带 ClusterShape + PipelineAsyncMmaStages）—— 一等公民
- `mma_sm120.hpp` 全是 `mma.sync` 不是 `tcgen05` —— SM120 没有 UMMA
- `mma_sm100_umma.hpp` 才是 UMMA，包含 `2x1SM_*`（2-CTA paired cluster）专属变体

**对 5060 Ti 用户的实际意义**：
- W6 TMA / W7 Pipeline+Cluster / W9-W12 WarpSpec GEMM / W14-W21 FA & MoE 的**整个软件框架可以在 5060 Ti 完整跑通**（用 `MainloopSm120TmaWarpSpecialized` 代替 SM90 WGMMA mainloop）
- 5060 Ti 跑不了：WGMMA atom（要 H20）、UMMA atom + TMEM（要 B200）、2-SM 配对 cluster（要 B200）
- 5060 Ti 上独有的：fp4 / fp6 块缩放 mma.sync（量化 FA、量化 MoE 实验的现成硬件）

### O21. TiledCopy 和 TiledMMA 本质是同一个问题：线程→元素映射

不管是 sgemm_1 的裸 ThreadLayout、还是 sgemm_2 的 TiledCopy/TiledMMA，解决的核心问题都是 **"把 0-255 这些线程 ID 映射到 (128, 8) 这块 tile 上"**。TiledCopy 和 TiledMMA 概念上是同一种东西——把 M 个 thread 映射到 N 个元素，区别只是每个 thread 执行 copy 还是 mma。

- 代码层面**没有共享基类**——`TiledCopy` 继承 `Copy_Atom`，`TiledMMA` 继承 `MMA_Atom`，各自独立
- 但底层都用同一套 layout 代数原语（`zipped_divide`、`logical_divide`、`compose`、`right_inverse`）
- 没合并的原因：MMA 多一个 **permutation** 步骤（硬件 lane→element 接线图）+ 用 4D 坐标 `(V,M,N,K)` 而非扁平 thr_idx
- 唯一的代码依赖方向：`copy_atom.hpp` include `mma_atom.hpp`（`make_tiled_copy_A/B/C` 从 TiledMMA 反推兼容的 TiledCopy）

裸 Layout 只解决**映射**；TiledCopy 同时解决**映射 + 指令选择**（Copy_Atom 编码了向量宽度和硬件指令类型）。

### O22. Val Layout + 数据 layout 配合保证向量化连续性

`UniversalCopy<uint128_t>` 怎么保证每线程搬的 4 个 float 在显存连续？**这是程序员的责任，不是框架自动推导的**。

```
Val Layout 的方向  ×  数据 layout 在那个方向的 stride  ==  连续
```

NT 情况：gmem A 是 m-major (stride=1 in M)，Val Layout `(4,1)` 沿 M 排 → 4 个连续地址 → 可发 128-bit load。
TN 情况：gmem A 是 k-major (stride=ldA in M)，M 方向不连续 → 退化为 `UniversalCopy<TA>` (32-bit) + Val `(1,1)`。

越宽的 Copy Atom 对连续性/对齐要求越严格。选错了不会编译报错，运行时 crash 或读错数据。

### O23. WGMMA 同步四件套：fence 是可见性栅栏，不是等待

`mma_sm90_gmma.hpp:42-103`。CuTe 函数名 ≠ PTX 直觉，对照表：

| CuTe | PTX | 性质 | 管 |
|------|-----|------|----|
| `warpgroup_arrive()` | `wgmma.fence.sync.aligned` | **可见性栅栏，不阻塞** | 入口 |
| `warpgroup_commit_batch()` | `wgmma.commit_group` | 封一个 wgmma 批次 | 中 |
| `warpgroup_wait<N>()` | `wgmma.wait_group N` | **阻塞**，等未完成 group≤N | 出口 |
| `warpgroup_fence_operand(r)` | `asm volatile("":"+r"(r))` | **零指令**纯编译器栅栏 | 累加器前后各一道 |

- `fence` 名为 arrive 但**不是"我到了/等待"**，是排序+可见性：保证 fence 前对累加器/smem 的写，对随后 wgmma 可见且不被重排。等待是 `wait_group` 干的。
- **三步而非一步**：fence(入口可见性)/commit(批次边界)/wait(出口等待) 三正交职责，合一就没法"发了先不等、留 N 个在飞"做流水线。
- `wait_group` 只数 wgmma（独立 scoreboard，跟 cp.async 的 group 计数分开两套），靠 commit 划批次，不靠匹配指令内容。

### O24. 为什么 wgmma 需要 fence —— async proxy

wgmma 通过独立的 **async proxy** 访问 smem/累加器寄存器，跟普通线程的 **generic proxy** 不是同一条路径、**不自动同步**。普通 scoreboard 不跨 proxy 工作 → 没 fence，tensor core 可能从 async proxy 读到 generic proxy 还没刷新的写（旧值）。`wgmma.fence` = 手动在两 proxy 间架可见性桥（同 CPU memory_fence 一类，故名 fence 不名 wait）。
- 同理：cp.async/TMA 写进 smem 后喂 wgmma 前也要 fence（一个 proxy 写、另一个读，跨 proxy）。
- `fence_operand`：累加器被 async proxy 后台异步读写，但 C++ 编译器不知道。`"+r"` 假装读写它，阻止编译器 (A) 把读累加器提前到 wait 前；(B) 在后台写期间复用/重排这些物理寄存器。标准写法：发射前 + 取用后各夹一道。

### O25. SS vs RS 结构差异就一处（A 来源），但带走 4 条

`mma_sm90_gmma.hpp` SS/RS 配对 atom。SS：A=`uint64_t[1]` descriptor，PTX ` %2` 单值；RS：A=`uint32_t[4]` 真寄存器，PTX `{%2,%3,%4,%5}` 花括号组。
1. **没有 RR**：B 永远是 descriptor（来自 smem），只有 A 有"进不进寄存器"的选择。
2. **RS 强制 A K-major**（`static_assert(tnspA==K)`）：寄存器里 A 是 ldmatrix 摆好的固定 fragment，wgmma 读寄存器走硬连线固定映射，**没有 SS 那种可编程 stride/descriptor 地址生成器**，无法转置。
3. **累加器 `"+r"(d0),"+r"(d1)`** 既输入又输出，印证 async proxy 后台读写。
4. **取舍**：SS 省寄存器但每次从 smem 读 A；RS 省一次 smem 读但吃寄存器（×流水级数，压 occupancy）。A 反复复用时值得 RS（如 FA 某操作数），否则 SS。

### O26. GMMA descriptor = 给地址生成器的"smem 取数说明书"

`mma_sm90_desc.hpp`（151 行，`union GmmaDescriptor` 64-bit）。**不用背 bit**，一句话：内容 = 起始地址 + 两个方向 stride(LBO/SBO) + swizzle 模式(layout_type_)，**纯几何零数据**。
- **两 stride 随 major 切换含义**（K：LBO=8行→下8行 / SBO=8列→下8列；MN：角色互换）。**SS 转置 = 互换这两个 stride 的角色**——这是 O12 "硬件接线图" 在 smem 侧的对应。
- 全是几何零数据 → 印证 SS 模式 A 不进寄存器：descriptor 只说"去哪取"，数据 wgmma 硬件自己流式读进 PE 阵列。
- **"smem 地址生成器"不是独立的 smem 控制器**，是 wgmma(GMMA) 单元内部解码 descriptor 的逻辑；smem bank 只管存储+仲裁，"按什么规则取"的智能在发起方。（微架构未公开，此为 PTX 语义+proxy 模型层结论。）

**descriptor 只认 4 种合法布局**（`mma_traits_sm90_gmma.hpp:162-194` 官方注释，不在表内 `make_gmma_desc` 拒绝）。Major-K 形如：
```
B128: Swizzle<3,4,3> o ((8,m),(T,2)):((8T,SBO),(1,T))   # 行恒(8,m)，swizzle 只缩放 leading
B64 : Swizzle<2,4,3> o ((8,m),(T,2)):((4T,SBO),(1,T))   # 4 chunk
B32 : Swizzle<1,4,3> o ((8,m),(T,2)):((2T,SBO),(1,T))   # 2 chunk
```
**swizzle 宽度与 leading 宽度死死配对**，每档唯一。两条不可让渡的硬约束：
1. **行轴恒 `(8,…)`**：core matrix 8 行是硬件常量，且靠**独立 SBO stride** 寻址。swizzle 只改另一维(leading-K)的 chunk 数(B32→2/B64→4/B128→8)。
2. **leading 维必须是某一行自己的连续 K**：MMA 沿它 unit-stride 走。

→ **swizzle 本质 = `8行 × N个leading-chunk` 的固定拉丁方**。"窄 K-tile 拼两行进一个 128B 周期"不行：等于侵占已被 SBO 占用的行轴，且让 MMA 的 unit-stride K-walk 在"row0 k=32"处跨读进 row1 的字节（descriptor 描述的逻辑布局在撒谎）。编码上也无"swizzle 128B 但行距 64B"这种组合。swizzle 透明(写读同函数)→ 不损坏数据，但逻辑映射错。**所以 swizzle 只能按行——是 core matrix 8 行固定 + 单行 K 连续两件事都不可让渡，不是设计偷懒。**

### O27. WGMMA 完整语义 = TV 线 + swizzle 线（SS 的 A/B TV 退化）

接 O12/O21（MMA atom 的 A/B/C layout 是 `(tid,value)→矩阵坐标` 的统一映射）。**但 SS 模式下 A/B_TV 退化成 T-stride=0**（ex12 实测 `LayoutA_TV: (_128,...):(_0,...)`），意味着 A/B 与 thread 无关、不归任何线程持有、整块在 smem 由硬件读。
- **C_TV 非退化**（T-stride≠0）：累加器真在寄存器、真按线程分。ex12 N=8：T 维 (4,8,4)=128，V 维 (2,2,1)=4（每线程 4 个 C 元素=2×uint32=4×f16）。epilogue 靠 C_TV（经 `partition_C`）反查"我这寄存器值写到 C 的哪个 (m,n)"。
- **结论**：TV 三件套对"进寄存器"的操作数才是完整语义（C 永远是；A/B 在 RS/mma.sync 时是）。**SS 的 A/B 不进寄存器 → TV 退化，真实语义转移到 smem swizzle layout + descriptor**。SS 把 A/B 从 TV 线甩给 swizzle 线（不占寄存器），只把 C 留在 TV 线 —— 这是 WGMMA 比 mma.sync 省寄存器的根本原因。
- **op/traits/atom 三层解耦**（`mma_atom.hpp`）：你写的 `SM90_64x8x16_..._SS` 只是 **MMA_Op**（alias，仅 `fma()`/PTX，无 layout）。`make_tiled_mma(op)` 重载(:548) 自动包成 `MMA_Atom<op>`(:45)，继承时按类型查 `MMA_Traits<op>`(:480, traits 文件) 拿 5 个 layout。换硬件只换 op+traits 特化，上层不动。

### O28. swizzled smem 的两种锚法：position-dependent vs independent

`pointer_flagged.hpp:98-123`。swizzled smem tensor 的 layout = `ComposedLayout<SwizzleFn, 中间锚, Layout>`，关键在中间项：

| | 中间锚 | swizzle XOR 作用于 | 数据指针 |
|---|---|---|---|
| `sA`（默认，position-**dependent**） | `smem_ptr_flag` | **绝对地址**+offset（地址低位参与） | 有 |
| `sA_pi`（`as_position_independent_swizzle_tensor`） | `Int<0>` | **仅 offset**（锚 tensor 自身 base，与绝对位置无关） | **同一个，仍在** |

- **常见误解**：不是"sA 含地址、sA_pi 不含"。**两者都握同一物理指针**（不然无法落地址）。变的只是 **swizzle 运算依不依赖绝对地址**。
- base 对齐到 swizzle 跨度时（`as_pi` 内有 assert `(address & mask)==0` 保证），两种锚算出的**物理布局完全一致**——换锚不改结果，纯实现机制。
- **为何要两种**（ex11 对称点）：**cp.async 写**侧用 `sA_pi`——通用 `copy` 循环靠 layout 从 base 算 offset，且 `partition_D` 会切/推进指针，swizzle 必须自参照 base0 才算得对；**wgmma 读**侧用 `sA`（`partition_A(sA)`）——`make_gmma_desc` 要读真实 smem 地址 + swizzle 模式，硬件在绝对地址上施加。
- 两侧物理布局一致 → 写进去的 = wgmma 读出的，"写读同一 swizzle、逻辑透明"在代码里的落点。
- 配套理解 layout 方向：CuTe Layout **恒为 `逻辑坐标→一维 offset`**（含 swizzle 那步 XOR），无"反过来"。`sA(m,k) ⟺ smemA[sA_layout(m,k)]`，你写逻辑坐标、layout 翻成物理槽。`partition_D` 分的是**逻辑元素**，swizzle 在**实际 load/store 那刻**才把逻辑翻成物理 —— 不是 partition 直接拿打散偏移。

### O29. TMA 核心（W6，加速模式）

**一条指令搬一整 tile**（G↔S），硬件自算地址、异步、单线程发射（区别于 wgmma 的 warpgroup 发射）。三个必知：
1. **descriptor 在 host 建**：128B TensorMap = {基址 + 各维 size/stride + box + swizzle 模式 + 越界行为}，靠驱动 `cuTensorMapEncode`，device 建不了，全 CTA 共享。kernel 里 TMA 只吃 **descriptor 指针 + smem 指针 + GMEM 坐标**（不吃 GMEM 指针——它封进 descriptor 当常量，这就是 `0z_tma_tensors.md` 那个 ArithTuple 坐标 tensor 的由来：layout 算出的是**坐标**不是 offset，stride 用基元素 `E<i>`=`1@i`）。
2. **mbarrier transaction count**（同步灵魂）：普通 barrier 等"**线程**到齐"，TMA barrier 等"**字节**到齐"。模板 `expect_tx(bar, tile_bytes)` → 发 TMA → `wait`；引擎搬完自动累加字节，凑够放行。函数在 `copy_sm90_desc.hpp`。
3. **proxy fence**：TMA 走 async proxy 写 smem，普通指令/wgmma 走 generic proxy 读 → 跨 proxy 不自动同步（**同 W5 wgmma fence 同源**），中间需 `fence.proxy.async`。

**128B 对齐到底对谁**（纠正：别一锅烩）：
| 对象 | 对齐 |
|---|---|
| global tensor 基址 | **16B** |
| 各维 global stride（字节） | 16B 倍数 |
| **smem 侧 box 地址** | **128B** ← "128B"真正来源 |
| box 内层 × 元素大小 | swizzle atom（SW128=128B，呼应 O3） |

三个"起点"别混：**global tensor 起点**=整矩阵基址(`&A[0][0]`，进 descriptor)；**box 起点**=本次搬的 tile 左上角坐标(运行时传)；**元素地址**=任意 `&A[i][j]`。

**descriptor 的 swizzle 字段 = W5 GMMA `layout_type`(B32/B64/B128) 同一套** → TMA 直接按 wgmma 要的 swizzle 摆进 smem，省中间重排。三套 group 计数互不干扰：cp.async / `cp.async.bulk`(TMA) / wgmma 各一套 scoreboard。

### O30. Pipeline + Cluster + Warp Specialization（W7，加速模式）

**mbarrier vs `__syncthreads`**：mbarrier = 带 **phase bit**、可**异步**(arrive 不阻塞)、可按**线程子集/字节**的 barrier。这是流水线地基；syncthreads 只能整 block 同步、无 phase、不异步。

**PipelineState = index + phase**：循环 buffer `depth` 个 slot。index 管空间(用哪个 slot)、phase 管时间(第几圈，每圈翻 0↔1)。**phase 不能用 `index%depth` 替代 → ABA 问题**：index 绕回 0 时分不清"本圈新写"还是"上圈残留"，phase bit 才能判数据新旧。

**4 步协议**：`producer_acquire`(等 slot 空,被 `consumer_release` 解锁) → `producer_commit`(数据好了通知，TMA 场景由字节到齐自动触发) → `consumer_wait`(等 slot 满) → `consumer_release`(用完通知 producer 可覆盖)。

**Warp Specialization（Hopper 才流行）**：warpgroup 分工 producer(专发 TMA)/consumer(专做 wgmma)。三支撑：**mbarrier**(子集同步,syncthreads 做不到) + **setmaxnreg**(consumer 多给寄存器、producer 少给，不对称分配提 occupancy) + **cluster/DSMEM**(多 SM 共享 smem)。

**Cluster/DSMEM**：多 CTA 绑一组互访 smem，`cluster_sync` 跨 CTA 同步，`cluster_to_smem_ptr`(本地 smem 地址 + 目标 CTA rank → DSMEM 地址)。**消费卡 cluster size≈1，基本空转，概念懂即可**。SM100 在其上加 CLC(硬件化 persistent + 动态 tile 调度)，Stage3 SM100 GEMM 再碰。

**ping-pong 至少 2 个 mbarrier**：一个表"slot 空(可写)"、一个表"slot 满(可读)"。1 个无法同时表达两个相反事件，producer/consumer 会互相覆盖/读脏。

### O31. TMEM + UMMA（W8 SM100/103，加速模式）

SM100 把 tensor core 从"warpgroup 协作 + 累加器在寄存器"升级为"**单线程发射 + 累加器在 TMEM + 双 SM 可锁步**"。全靠对比 W5 wgmma 理解：

| | WGMMA(SM90) | UMMA(SM100) |
|---|---|---|
| 发射 | warpgroup 128 线程 `.sync.aligned` | **单线程**(`elect_one` 发 `tcgen05.mma`) |
| 累加器 C | RMEM(128 线程摊开) | **TMEM**(256KB/SM 专用 SRAM) |
| A | SMEM/RMEM | SMEM/**TMEM** |
| 规模 | M64 | 单 SM M128；**2-SM 锁步 M256** |

- **TMEM**：累加器新家，不占寄存器→occupancy 大涨。专用指令 `tcgen05.alloc/dealloc`(生命周期) + `tcgen05.ld/st`(TMEM↔RMEM)。**代价：epilogue 多一跳 TMEM→RMEM→GMEM**(W5 是 RMEM 直接写)。
- **为何单线程能发**：累加器在 TMEM、操作数在 SMEM/TMEM(集中，descriptor 寻址)→ 不靠线程寄存器分散持有 → 无需协同。对比 wgmma 要 128 线程是因数据散在寄存器。
- **2-SM UMMA = cluster=2 结构必需**：`cta_group::2` 两 SM 锁步算 MMA_M=256，A/B 分摊两 CTA SMEM、累加器共享 TMEM。`mma_sm100_umma.hpp` 里 `::1`/`::2` 两套 PTX 并存。物理算力在 SM、协同通路在 TPC。
- **四层心智模型**(同 W3/W4)：`tcgen05.mma/.ld/.alloc` PTX → `mma_traits_sm100`+`copy_traits_sm100` 包 atom → `tmem_allocator_sm100` 管段 → 上层 kernel。
- **FP4/FP6/MX**(`tcgen05.mma.kind::f8f6f4/mxf4/nvf4`)：低精度+microscaling，**5060 Ti 唯一保留的 SM100 TC 能力**(本地 LLM 推理刚需，走 SM120 自有路径非 tcgen05)。消费卡砍 UMMA/TMEM/cluster。
  - **f8f6f4**=通用窄浮点通路(FP8/FP6/FP4 共享)，**无内置块缩放**。
  - **mxf4**=OCP MXFP4：FP4 + **block 32** + **E8M0**(8bit 纯指数)scale，跨厂商标准。
  - **nvf4**=NVFP4：FP4 + **block 16** + **E4M3**(FP8)scale → 更细更准，本地 LLM 推理主推。块越小/scale 越宽=越准越贵。

### O32. CUTLASS 3.x 五层分层（W9，Stage3 起点）

```
device      GemmUniversalAdapter   用户入口：workspace/参数检查/launch/grid
kernel      GemmUniversal          内核骨架：tile scheduler + 调 collective
collective  CollectiveMma(mainloop)+CollectiveEpilogue  ← 真正干活(TMA+pipeline+MMA / 累加器→GMEM)
tiled       TiledMMA/TiledCopy     线程组→元素映射(W4)
atom        MMA_Atom/Copy_Atom     单条 PTX(W5/W6)
```
- **CollectiveBuilder 价值**：用户只给 `TileShape_MNK`/`ClusterShape_MNK`/`KernelSchedule`/`EpilogueSchedule`，Builder 编译期自动推断 `DispatchPolicy`/`StageCount`(流水级)/`SmemLayoutAtom`(swizzle 选档,O3)/`SmemCopyAtom`/TMA 类型/寄存器分配。= 把 W5-W8 零件选型自动化。
- schedule(`Pingpong/Cooperative/Auto`) 是**模板参数→编译期**选死，非运行期。`Auto` 让 Builder 按 tile/arch 选。
- `TileShape<_128,_128,_64>`=block 算 M128×N128、K 每次 64 循环累加。**N 用 128 不用 256**：256 让 smem+累加器需求翻倍超容量/压 occupancy；128×128 是 Hopper 甜点。
- `ClusterShape<_2,_1,_1>`=2-CTA cluster，启用 TMA multicast / SM100 2-SM UMMA，要求 SM90+。
- 读序：**ex49 Builder 简化 → ex48 手动展开**(对比 Builder 推断了啥)，复用 W2"先 fused 再 unfuse"。W10-12 在 collective 层手写 mainloop，W13 写 SM100。
- 强制指定(绕过 Auto)：直接传具体 `KernelScheduleType` + 手动 `StageCount<N>`。

### O33. 五层是"库工程"不是"性能物理"——手写要什么、发挥空间在哪（战略）

打到 90% 吞吐**不需要复刻五层**。区分三类东西：
- **物理必需品(硬件决定,必须做)**：三级 tiling(block/warp/instruction) + 异步多级流水(TMA+多buffer) + 打满 MMA + 正确 swizzle + occupancy + epilogue 不拖。任何高性能 GEMM(cuBLAS/Triton/CUTLASS/你)都做这 6 件,跟用不用五层无关。
- **库工程(CUTLASS 为"当库"付的税)**：五层 + tag-dispatch,为了"一套代码支持几百种配置"。你只写一个 kernel 时是**纯负担**。
- **你的发挥空间(决定最后 10-20%)**：warp 角色分配 / pingpong-vs-coop / 流水级数 / tile-cluster 调参 / tile scheduler 光栅化顺序(L2 命中) / swizzle 选择 / epilogue fusion / Stream-K。

**手写 CuTe GEMM 需要什么**：那两个文件(kernel `operator()` + collective `load/mma`)只给**核心计算逻辑**,还缺：① **epilogue**(TMEM→GMEM 写出,在第三个文件 `sm100_epilogue_*`) ② **host 端 `make_tma_copy` + launch + cluster 配置** ③ **类型定义**(TiledMMA/swizzle/TMA atom)+ TMEM alloc/dealloc。但手写**单一配置**可塌缩成 **~300-400 行扁平 kernel**(砍 5 类 warp→3 类 / 砍 EVT / 砍 1-2SM 分支 / 砍 streamK / 砍泛化)。底层 UMMA/TMA/swizzle atom 从 cute 复用。**最优学法：复用底 2 层 cute,自己写上 3 层扁平版**(= DeepGEMM 路线)。

### O34. 五层内部的精确关系（kernel vs collective vs pipeline）

- **kernel 层 = `__global__` 指挥官**：管一个 CTA 的资源(smem/TMEM alloc)+ warp 角色分配 + 问 scheduler 要 tile + cluster 同步 + **调用** collective。**自己不算**,k_tile 循环体在 collective 里。
- **collective 层 = 真正的协作计算循环**：`CollectiveMma`(load+mma 的 k_tile 循环) 和 `CollectiveEpilogue`(写出循环) 是**两个平级的 collective**,kernel 层组合它们。epilogue 不是 mainloop 的子 loop。
- **"Collective" 命名来源**：并行计算的 collective operation(一群线程靠硬件特性协同)。它是**协作的边界**：上面 kernel 调度*独立*的 tile,下面 atom 是*单条*指令,中间这层"全员协同算一个 tile"。warp specialization 的 producer/consumer 流水就是它的体现。
- **CollectiveOp vs "KernelOp"**：CollectiveOp = `Builder<...>::CollectiveOp`(真实成员名,Builder 自动生成的第3层零件,有 mainloop+epilogue 两个)。"KernelOp" = **非真实 API 名**,练习俗称,实为 `GemmKernel = GemmUniversal<ProblemShape, Mainloop, Epilogue>`(第2层,手动 wrap 两个 CollectiveOp)。
- **`gemm_universal.hpp` 几乎是空的**：它只是 **dispatch 入口**——一串 `#include` 把各架构特化(`sm100_gemm_*`)拉进来 + `IsCutlass3` 判别,靠 enable_if + schedule tag 选中真正的特化。**真逻辑在 `sm100_gemm_tma_warpspecialized.hpp` 的 `operator()`**,别在 gemm_universal.hpp 卡时间。
- **pipeline 三方分工**：定义在 `pipeline/`(横切工具,非五层) / **配置在 kernel 层**(构造对象+配 producer-consumer 角色+初始 state) / **使用在 collective 层**(load/mma 里逐轮调 acquire/wait/release + 推进 state)。"配置在上层、使用在下层、定义在独立库"。

### O35. L2/L3 是两层嵌套 for,故意不合并

外层 = collective 的 k_tile 循环(**运行时**,含 TMA+同步);内层 = `cute::gemm` 里的 tile 展开(**编译期完全展开**,纯计算)。**能合(手写时 `cute::gemm` 就是循环里一行),但 CUTLASS 故意把 L2 留在 `cute/`**：① `cute::gemm` 跨算法复用(GEMM/FA/MoE/conv 全调它) ② "数据移动/同步"(L3)和"MMA 映射线程"(L2)正交。你 W10 手写 = 写 L3 循环 + 调 L2 那行 `cute::gemm`,白嫖 L2。

### O36. CUTLASS 文件名是 token 自描述 + 目录判别

文件名 = `架构_[特性前缀]_本体_[搬运]_[调度]_[变体后缀]`,从左到右读 token 就懂。找标准版 = 挑**无特殊 token** 的(`sm100_gemm_tma_warpspecialized` / `sm100_mma_warpspecialized`);`array_`=grouped、`blockscaled_`=MXFP4、`sparse_`/`complex_`/`emulated_`等=变体,**需要哪个翻哪个,不全读**。目录判别见 `cutlass_reading_strategy.md §0`(sm前缀=3.x看 / threadblock,warp,thread=2.x跳 / 上3层在 cutlass/gemm,下2层在 cute/)。kernel 目录混了 4 个 `tile_scheduler`(调度组件,非 kernel 本体)。

### O37. SM100 kernel 的 5 类 warp 角色(各 1 warp 的红利)

`sm100_gemm_tma_warpspecialized.hpp` operator()：`warp_idx<4` 直接当类别,`≥4` 归 Epilogue。
| warp | 角色 | 数量 | 干啥 |
|---|---|---|---|
| 0 | MMA | 1 warp | 发 UMMA(`elect_one` 单线程真发 tcgen05.mma),累加进 TMEM |
| 1 | Sched | 1 warp | CLC 动态调度(SM100 特有),领下一 tile |
| 2 | MainloopLoad | 1 warp | 发 TMA 搬 A/B |
| 3 | EpilogueLoad | 1 warp | 发 TMA 搬 C(beta=0 则空转) |
| 4-7 | Epilogue | 4 warp | TMEM→RMEM→EVT→GMEM 写出 D |
共 8 warp=256 线程。**核心红利**：UMMA/TMA 都单线程发射 + 累加器在 TMEM(不占线程寄存器)→ "发指令"角色全瘦成 1 warp,只有"逐元素并行"的 epilogue 用满 4 warp。比 SM90"两个满 warpgroup"更省、occupancy 更高。

### O38. GEMM 里 C 是外部输入不是结果 + 70/71 都用 Builder

- `D = alpha*(A@B) + beta*C`：**`A@B` 的结果是 `acc`(累加器);C 是另一个外部输入矩阵**(残差/bias),不是算出来的。`beta=0`(纯乘法)→ 跳过搬 C → EpilogueLoad warp 空转(源码 `is_epi_load_needed`)。
- **example 70 和 71 都用 `CollectiveBuilder`**(纠正"70 手动展开"的误解)。不存在"不用 Builder 的手动展开 example"——纯手写 collective 太长,只在源码 `sm100_mma_warpspecialized.hpp` 或你 W10 自己写。70=配置写死(最简);71=schedule/stage/EVT 模板化跑多套(展示旋钮)。

### O39. tile-based 编程 + Blackwell 把它逼成必然 + SM120 取舍

- **tile-based 编程**：编程粒度从"线程"升到"整块 tile"——你只说"tile C = tile A × tile B",线程怎么瓜分这块 tile 由框架(CuTe layout 代数 / Triton)自动算(= 你 W3-W5 学的 TV layout/swizzle/partition 被自动化)。代表:Triton/CuTe/TileLang/ThunderKittens/cuTile。**CuTe 是最底层的 tile 框架**。
- **Blackwell 为何逼成必然**：三支柱全 **tile 原生** —— UMMA(单线程发整块算)/TMEM(整块存,lane×column)/TMA(整块搬,瓦片坐标)。元素/线程粒度从主数据通路消失,thread-level 编程失效 → tile-based 从"可选"变"必然"。(tile 编程比 TMA 早,Ampere 用 cp.async 也能,但 I/O 是线程级;TMA 让 I/O 也 tile 化。)
- **SM120 取舍 = tile 模型 vs tile 规模**：保留 **TMA(tile-I/O 使能)+ 窄精度 tensor core(tile 算 + fp4 推理刚需)+ swizzle/mbarrier** = "tile 模型使能件"(缺了接不上现代推理生态);砍 **TMEM/UMMA/2-SM/DSMEM** = "tile 规模优化件"(数据中心吞吐,硅面积贵,单卡推理用不上,退回 mma.sync+RMEM)。**5060 Ti 能验证 tile kernel 逻辑骨架,验不出 TMEM/2-SM 性能**——这就是 W13"SM100→SM120 移植验证"验的是"对不对"非"快不快"。

### O40. FA 是英伟达形状的算子(NPU 命门 = SIMT+SIMD 混编)

(来自"NPU 为何难支持 FA"讨论,技术骨架部分)
- **FA 每代贴一代架构**：FA1/2→A100(IO-aware,online softmax 把 N×N 中间矩阵留 SRAM,纾解 HBM 带宽);FA3→Hopper(WS+TMA+WGMMA async,把 softmax 藏到 matmul 后);FA4→Blackwell(tcgen05/TMEM/2-SM + 补 exp 短板——exp 走 SFU/MUFU,tensor core 越快它越成瓶颈)。
- **NPU 命门**：Warp Specialization 本质 = **大块 SIMD 算力 + 灵活标量控制(softmax/调度/if-else)在 SRAM 级无缝混编**。纯 dataflow NPU(昇腾 AIC/AIV 过 GM 协同、纯 systolic)缺灵活 SIMT 控制层,做不到"matmul↔向量在快内存紧耦合",移植 FA 代价巨大。
- **三重未来诘问(真问题)**：① 动态 shape(GPU thread block 灵活切,NPU 固定尺度→padding/回调 host) ② 动态 if-else(MoE 路由/剪枝,GPU 标量分支便宜,NPU 深流水 flush) ③ 动态 tile size + SRAM 内 Shuffle/Permute(= swizzle 动态版,NPU 固定 layout 追不上)。
- 读法:技术骨架(FA 贴架构 / WS 是命门 / 三诘问)成立;内幕八卦(昇腾 1GB L2 / V-Cache)无法证实;"软件栈纯被动承接"是暴论。**印证你 B200 库方向的价值:壁垒在 warp 灵活性 + SRAM layout 控制,正是你 Stage2-4 啃的。**

---

## 三、方法论

1. **回答简短到位，不写小作文**。表格、清单优先于段落。
2. **不能编内容**。API 名、行号、shape、stride 这些精确的事情，**必须先查源码再答**。
3. **优先级**：源码 (`include/cute/`) > 官方文档 (`media/docs/cpp/cute/`) > 脑内记忆。脑内的东西永远要验证。
4. **大题目用 Explore agent 审计**：跨多文件的 cross-check / 路径审计交给 Explore，效率高。
5. **行话纠正要给 receipt**：用户问"X 是啥"时，引用源码 / 文档 line 号，让他能自查。
6. **实战 > 纯理论**：ncu / bank conflict / swizzle 这些放到能跑真 kernel 的阶段做（W10 GEMM、W14 FA），不在抽象阶段空对空 demo。
7. **架构特性查询逐项查源码** (`config.hpp` + `dispatch_policy.hpp` + 各 arch `mma_*.hpp` + `copy_*.hpp`)，不要凭"应该有/应该没有"猜。

---

## 四、给下个 agent 的接手指南

1. 先读 `study/README.md` + `study/PROGRESS.md` 看到了哪一周
2. 再读这个 THINKING.md（概念笔记 O1-O22 是参考材料，碰到对应主题直接引用 line 号）
3. **任何涉及 Layout / Swizzle / MMA atom / API 名 / shape / stride / 架构能力的问题先查源码**，引用 `include/cute/` 和 `media/docs/cpp/cute/`
4. **W3/W4 reading 顺序已经是自下而上**（PTX → Traits → Atom → Tiled → 算法），别退回 wrapper-first
5. **scaffold 必须 SM80-compatible**（5060 Ti 是主战硬件）
6. **不要在 W1-W4 阶段强加 ncu / bank conflict 实测**，挪到 W10+

PR / merge 流程：
- main 受保护，必须 PR 后 merge（直接 push 会 403）
- 用户的开发分支：`claude/review-progress-ex02-7MUIB`
- 用 `mcp__github__create_pull_request` + `mcp__github__merge_pull_request`
