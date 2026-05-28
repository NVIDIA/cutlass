# Blackwell (SM100) 硬件改动 × 编程模型 完整梳理

## 总览：Blackwell 的设计哲学

如果 Hopper 是"让 SM 从全能选手变成专注计算的核心 + 一圈协处理器"，那么 Blackwell 是把这条路走得更彻底：让 Tensor Core 自己拥有专属存储（TMEM）、专属指令发起方式（单线程发起）、专属协同模式（2-SM CTA pair）—— Tensor Core 几乎成了 SM 内部的独立子系统。

Hopper 的两条主轴（Scale Up + Async）在 Blackwell 上都被进一步推进，而且新增了一条主轴："Tensor Core 物理解耦"。

---

## 一、分化定律（新增独立 die area 的硬件）

### 1. TMEM (Tensor Memory)

- **从哪里分化**：寄存器堆（累加器）+ SMEM（操作数 staging）的部分功能
- **物理位置**：每个 SM 内 256 KB 专用 on-chip SRAM，物理上紧贴 Tensor Core
- **结构**：2D 寻址，128 lanes × 512 columns × 32-bit
- **带宽**：读 16 TB/s、写 8 TB/s（per SM），与 SMEM 带宽叠加
- **解决的问题**：Hopper 上 Tensor Core 累加器必须放在寄存器堆里，导致两个问题：
  - 寄存器堆压力巨大，WGMMA kernel 经常每线程用 200+ 寄存器，挤压 occupancy
  - 累加器和普通寄存器混用，Tensor Core 和 CUDA Core 抢寄存器堆端口
  - 让 Tensor Core 拥有专属存储后，这两个矛盾同时解开
- **编程模型**：`tcgen05.ld`（TMEM→寄存器）、`tcgen05.st`（寄存器→TMEM）、`tcgen05.cp`、`tcgen05.alloc`、`tcgen05.dealloc`

### 2. 5th-gen Tensor Core (tcgen05) 的物理重构

这里有一个细微但重要的判断：tcgen05 既有"分化"成分，也有"进化"成分，需要拆开看。

**真正的分化部分**：Tensor Core 的物理边界扩大，把累加器从寄存器堆迁移到 TMEM，并且新增了"单线程 CTA 范围发起"的硬件机制。这等于把 Tensor Core 从"sub-partition 内的功能单元"重新定义为"SM 范围的独立子系统"。

- **从哪里分化**：从 sub-partition 内分化，扩展为 SM 范围
- **解决的问题**：解除 Tensor Core 对寄存器堆的依赖，让算力进一步放大不被寄存器堆带宽限制

### 3. 2-SM Cooperative MMA 的硬件支持

- **从哪里分化**：全新增加的 TPC 内 SM-to-SM 协同硬件路径（在 Hopper 的 SM-to-SM Network 基础上又分化出一层"TPC 内的紧耦合通路"）
- **物理位置**：TPC 内两个 SM 之间的紧耦合互联，延迟比一般的 cluster 内 SM2SM 通信更低
- **解决的问题**：2-SM MMA 把 MMA 粒度再翻倍（MMA_M 最大到 256），且共享操作数减半 SMEM 占用 —— 让两个 SM 的 Tensor Core 协同完成同一条 MMA
- **编程模型**：`tcgen05.mma.cta_group::2`（指定 leader CTA 和 peer CTA）

### 4. CLC (Cluster Launch Control) 硬件

- **从哪里分化**：CWD 内部新增 dynamic scheduling 硬件状态机（超出 Hopper GDC 的范畴）
- **解决的问题**：把"persistent kernel + dynamic tile scheduling"这种过去靠软件做的负载均衡机制硬件化，kernel 可以通过 `clusterlaunchcontrol.try_cancel` 动态领取下一个 tile
- **编程模型**：`clusterlaunchcontrol.try_cancel`、CLC pipeline

---

## 二、进化定律（改造既有硬件）

按 Hopper 那套三分法：Scale Up 类、Async 类、Kernel 边界优化类。

### A 组：Scale Up 类

#### A1. tcgen05.mma 指令语义进化

- **升级了什么**：
  - 发起粒度从 warpgroup（128 线程）降到单线程，但作用范围扩大到整个 CTA 或 2-SM CTA pair
  - 操作数位置：A 可来自 SMEM 或 TMEM，B 来自 SMEM，累加器 D 必须在 TMEM
  - 指令延迟近乎常数（~11 cycle），不随 tile 大小变化
  - 吞吐：相比 WGMMA 提升 2-4 倍
- **解决的问题**：进一步降低指令发射开销，让单条 MMA 覆盖更大算力，同时把 warp/warpgroup 这个"中间层"从 MMA 语义里抹掉
- **编程模型**：`tcgen05.mma`、`tcgen05.mma.sp`（sparse）、各种 `.kind` 修饰符

#### A2. Preferred / Fallback Cluster Size

- **升级了什么**：CWD 调度逻辑进化，kernel 可以声明两个 cluster size（preferred + fallback），调度器优先按 preferred 分配，无法满足时降级到 fallback
- **解决的问题**：Hopper 上 cluster size 过大会导致"GPC 容量量化误差"（剩余 SM 无法启动新 cluster），Blackwell 允许灵活降级，充分利用所有 SM
- **编程模型**：kernel launch 时声明 `preferred_cluster` + `fallback_cluster`

#### A3. FP4 / FP6 / 微缩放数据类型

- **升级了什么**：Tensor Core 数据通路扩展，支持 FP4（E2M1）、FP6（E2M3、E3M2）、以及块缩放变体 NVFP4、MXFP4、MXFP6、MXFP8
- **解决的问题**：在相同 die area 下，通过降低精度倍增吞吐 —— FP4 吞吐是 FP8 的 2 倍，带块缩放的 MXFP4 是 4 倍
- **编程模型**：`tcgen05.mma.kind::f8f6f4`、`kind::mxf4`、`kind::nvf4` 等
- **配套硬件**：第二代 Transformer Engine，支持微张量缩放（micro-tensor scaling）

### B 组：Async 类

#### B1. Blackwell 特有的同步指令

- **升级了什么**：`tcgen05.commit`、`tcgen05.relinquish_alloc_permit` 等新指令，让 TMEM 分配/释放和 MMA 完成可以通过 mbarrier 同步
- **解决的问题**：TMEM 是新加的存储层，需要与 mbarrier 整合；2-SM MMA 完成时需要通知所有 peer CTA
- **编程模型**：`tcgen05.commit.mbarrier::arrive`（将 MMA 完成绑定到一个或多个 mbarrier）

#### B2. mbarrier 扩展（支持 TMEM 和 tcgen05 完成事件）

- **升级了什么**：mbarrier 现在能接收 TMEM 操作和 tcgen05 MMA 完成事件（在 Hopper 的 transaction count 基础上又扩展了事件类型）
- **解决的问题**：统一所有异步事件的 rendezvous —— 不光 TMA 和 WGMMA，还包括 tcgen05 MMA、TMEM 数据移动
- **编程模型**：沿用 mbarrier 系列，但新增的事件源（TMEM、tcgen05）对 mbarrier 透明

### C 组：Kernel 边界 / 调度优化类

#### C1. CLC 编程模型化

- **升级了什么**：CWD 内新增 CLC 状态机，允许 worker CTA 通过 `try_cancel` 动态领取 grid 中未启动的 cluster
- **解决的问题**：把过去靠软件做的 stream-K、persistent kernel 调度变成硬件原生支持，降低尾延迟、提升负载均衡
- **编程模型**：`clusterlaunchcontrol.try_cancel`、CLC pipeline、`PersistentTileSchedulerSm100`

---

## 三、通用升级（规格/容量提升）

- **L2 cache**：50 MB → 约 65-100 MB（B100/B200，具体看 SKU）
- **L1/SMEM 容量**：不变（仍 256 KB unified）—— 因为 2-SM MMA 让 SMEM 等效容量翻倍，所以不需要物理扩容
- **HBM**：HBM3 → HBM3e，带宽 3.35 TB/s → ~8 TB/s（B200），容量 80 GB → 192 GB
- **NVLink**：第四代 → 第五代：900 GB/s → 1.8 TB/s，NVL 域从 8 GPU 扩展到 72 GPU
- **双 die 设计**（B200 / B100）：两个 reticle-sized die 通过 10 TB/s NV-HBI 互联，对软件呈现为单 GPU
- **第二代 Transformer Engine**：支持 micro-tensor scaling 的硬件加速
- **第二代 Confidential Computing**：GPU TEE 增强

---

## 四、关键洞察：Blackwell 在你框架上的验证

### 验证一：你的预测大部分命中

回顾你在之前对话中的预测：

- ✅ TMEM（新分化的专用存储）—— 完全命中
- ✅ TCGen05（更大粒度 MMA）—— 完全命中
- ✅ Cluster Pair（更大协同单元）—— 完全命中，以 2-SM CTA pair 形式呈现
- ✅ 新的 fence 类型 / transaction 类型 —— 通过 `tcgen05.commit` 部分命中

### 验证二：两条主轴继续延伸，且新增一条

| 主轴 | Hopper | Blackwell 延伸 |
|------|--------|----------------|
| Scale Up（空间放大） | WGMMA + Cluster | tcgen05（单线程 CTA-scope MMA）+ 2-SM CTA Pair + FP4/FP6（数据密度放大） |
| Async（时间放大） | mbarrier transaction count + setmaxnreg + Proxy Fence | `tcgen05.commit` + TMEM 异步访问 + CLC 动态调度 |
| 🆕 物理解耦（资源放大） | （无独立主轴，资源都在 sub-partition） | TMEM（累加器从寄存器堆解耦）+ 单线程发起 MMA（MMA 从 warp 语义解耦） |

**新增第三条主轴的本质**：Hopper 已经让 SM 从"全能"分化成"通用部分 + TMA/Tensor Core 协处理器"，但 Tensor Core 还在"用通用资源"（寄存器堆、warp 语义）；Blackwell 把 Tensor Core 从通用资源池里彻底拔出来，让它有自己的存储（TMEM）、自己的语义（单线程发起）、自己的协同方式（2-SM）。这是比 Hopper 更深一层的解耦。

### 验证三：分化定律的触发规律继续生效

Tensor Core 在 Hopper 之前已经分化（Volta），Hopper 是 Tensor Core 的进化（WGMMA），Blackwell 则是 Tensor Core 的二次分化 —— 把累加器存储分化出来（TMEM）、把发起机制分化出来（单线程）。

这印证了你的判断：当一类硬件的工作负载继续高频化，即使它本身已经是分化产物，也会再次分化出更专用的子模块。Tensor Core 这条线已经分化了三次（Volta 出生 → Hopper warpgroup 化 → Blackwell TMEM 化），每次都对应一波算力跃迁。

### 验证四：warp specialization 范式的演进

Hopper 的 warp specialization 是：producer warp（发 TMA）+ consumer warpgroup（发 WGMMA）。
Blackwell 因为 MMA 发起退化成单线程，warp specialization 进化成更细粒度：

- TMA producer warp（发 TMA）
- MMA launcher warp（单线程发 `tcgen05.mma`）
- TMEM loader warp（从 TMEM 读累加器到寄存器，做 epilogue）
- Scheduler warp（发 CLC `try_cancel`）

一个 CTA 内有更多角色分工，每个角色更专一。这是 Hopper 趋势的自然延续。

---

## 五、给你的判断锚点

如果让我用一句话概括 Blackwell vs Hopper 的本质差异：

> Hopper 让 SM 学会异步；Blackwell 让 Tensor Core 学会独立。

Hopper 的关键词是"异步流水线"（TMA + WGMMA + mbarrier 联动）；Blackwell 的关键词是"Tensor Core 子系统化"（TMEM + 单线程发起 + 2-SM 协同，Tensor Core 像 SM 内部的一个独立子 GPU）。

如果说 Hopper 是 SM 内部的"专用化"达到一个高峰，Blackwell 则是把"专用化"提升到了 SM 内部子系统级别 —— SM 内部又出现了一个有自己存储、自己指令、自己协同模式的微型架构。

按这个趋势继续推，下一代（Rubin?）可以预测：Tensor Core 子系统会继续扩张，可能出现跨 SM 但低于 cluster 的新协同范围（类似 4-SM、8-SM MMA），TMEM 容量会继续增大，或者出现专门的 attention/softmax 协处理器 —— 这些都是当前框架可以预先布局的位置。
