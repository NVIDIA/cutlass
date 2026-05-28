# Hopper (SM90) 硬件改动 × 编程模型 完整梳理

## 框架：两条定律（SM90/SM100/SM120 三份笔记共用）

- **进化定律**：既有硬件结构通过少量改动（新增状态机、扩展控制路径、把已有结构包装成新编程模型）就能达到新能力，无需占用独立 die area。
- **分化定律**：无法靠改造既有结构实现，必须新增独立硬件单元，占独立 die area。

> SM100 笔记沿用同一套定律分析"加了什么"，SM120 笔记在此基础上多一条判定（通用性 × 代价）分析"砍了什么"。

---

## 一、分化定律（新增独立 die area 的硬件）

### 1. TMA（Tensor Memory Accelerator）

- **从哪里分化**：LSU
- **解决的问题**：大块多维 tensor 搬运 + 自动适配 Tensor Core 需要的 swizzling 格式 + cluster 内分发 + SMEM→GMEM 时附带 atomic reduction
- **编程模型**：`cp.async.bulk.tensor`、`cp.async.bulk.tensor.multicast`、`cp.reduce.async.bulk`
- **源码锚点**：`include/cute/arch/copy_sm90_tma.hpp`（PTX 包装）+ `include/cute/atom/copy_traits_sm90_tma.hpp`（atom layout）
- **常用 PTX**：
  ```
  cp.async.bulk.tensor.{1..5}d.shared::cluster.global              ← G→S 异步搬 N 维 tile
  cp.async.bulk.tensor.{1..5}d.global.shared::cta                  ← S→G 写回
  cp.async.bulk.tensor.2d.shared::cluster.global.multicast::cluster ← cluster 内 multicast
  cp.reduce.async.bulk.tensor.{1..5}d.global.shared::cta.add       ← S→G 时累加（split-K 用）
  tensormap.replace.tile.global_address [tmap], ptr                ← 运行时改 TensorMap（变形状）
  ```
- **配套 host API**：`cuTensorMapEncodeTiled`（构造 128 字节 TensorMap 描述符）

### 2. SM-to-SM Network（GPC 内 SM 互联网络）

- **从哪里分化**：全新增加的片上互联，Ampere 完全无对应物
- **解决的问题**：GPC 内不同 SM 之间的低延迟数据通路，延迟介于本地 SMEM（~20-30 cycle）和 L2（~200 cycle）之间（~50-80 cycle）
- **编程模型**：无直接 PTX 指令暴露；被 DSMEM 访问、cluster mbarrier、TMA multicast 间接使用

### 3. L2 Compression Engine（Inline L2 Compression）

- **从哪里分化**：全新嵌入 L2 controller 的压缩/解压硬件块
- **解决的问题**：减少 HBM ↔ L2 之间的带宽消耗（footprint 不变，只省带宽）
- **编程模型**：无 PTX 指令，仅通过 `cuMemCreate` 的 `CU_MEM_ALLOCATION_COMP_GENERIC` flag 启用

---

## 二、进化定律（改造既有硬件）

按"解决的问题类型"分成三组：Scale Up 类、Async 类、独立的 kernel 边界优化类。

### A 组：Scale Up 类（让单次操作更大、更饱）

#### A1. 4th-gen Tensor Core（WGMMA）

- **升级了什么**：
  - 操作粒度从 warp（32 线程）升到 warpgroup（128 线程）
  - 从同步执行（`mma.sync`）变为异步执行（`wgmma.mma_async`）
  - **A、B 操作数可直接从 SMEM 读**（SS 模式：A 和 B 都在 SMEM；RS 模式：A 在 register，B 仍在 SMEM；都不再需要 ldmatrix 把 SMEM 的 operand 搬到 register）
  - 新增 FP8 数据类型（E4M3、E5M2）
  - 4 个 sub-partition（SMSP）的 Tensor Core 协同完成一条 WGMMA（warpgroup = 4 warp，每个 warp 占一个 SMSP）
- **解决的问题**：进一步提升 MMA 吞吐和喂数效率，降低指令开销，让单条指令驱动更多算力
- **编程模型**：`wgmma.mma_async`、`wgmma.fence`、`wgmma.commit_group`、`wgmma.wait_group`
- **源码锚点**：`include/cute/arch/mma_sm90_gmma.hpp`（PTX，含 fence/commit/wait + 各 dtype 的 `wgmma.mma_async`）+ `include/cute/atom/mma_traits_sm90_gmma.hpp`（atom layout，W3 学的 ThrID/ALayout 都在这里）
- **常用 PTX**：
  ```
  wgmma.fence.sync.aligned                                           ← register operand 同步屏障
  wgmma.mma_async.sync.aligned.m64nNk16.f16.f16.f16                  ← FP16 (N = 8..256, 8 的倍数)
  wgmma.mma_async.sync.aligned.m64nNk16.f32.bf16.bf16                ← BF16, fp32 累加
  wgmma.mma_async.sync.aligned.m64nNk32.f32.e4m3.e4m3                ← FP8 (k=32, fp32 累加)
  wgmma.commit_group.sync.aligned                                    ← 把之前发的 wgmma 打包
  wgmma.wait_group.sync.aligned N                                    ← 等到只剩 N 个 group 未完成
  ```
- **配套指令（SM90 新增）**：
  ```
  stmatrix.sync.aligned.x{1,2,4}.m8n8.shared.b16  [smem], {r0,...}   ← ldmatrix 的对称指令，
                                                                       epilogue 把 register C
                                                                       重排回 SMEM 时必用
  ```

#### A2. Thread Block Cluster（CWD + LSU + SMEM 控制器联动升级）

- **升级了什么**：
  - **CWD（Compute Work Distributor）** 新增 cluster 整体调度逻辑（all-or-nothing 分配到同一 GPC）
  - **LSU** 升级，能识别 `.shared::cluster` 地址空间，把远程 SMEM 访问路由到 SM-to-SM Network
  - **SMEM 控制器**升级，能响应来自 SM-to-SM Network 的远程访问请求
- **解决的核心问题**：让一组协同计算的 block 共享更大的 SMEM 容量和更大的 Tensor Core 算力（等价于把多 SM 的 SMEM "虚拟拼接" 成一个更大的逻辑 SMEM，8 个 block 的 cluster ≈ 1.78 MB = 8 × 228 KB），同时通信延迟远低于走 GMEM/L2
- **编程模型**：cluster launch 配置、DSMEM（`.shared::cluster` 地址空间）、cluster mbarrier、`cluster.sync()`、TMA multicast
- **常用 PTX**：
  ```
  barrier.cluster.arrive                                             ← cluster 级 arrive
  barrier.cluster.wait                                               ← cluster 级 wait
  mapa.shared::cluster.u32  dst, smem_ptr, rank                      ← 计算远程 SMEM 地址
                                                                       （把本地 SMEM ptr + cluster
                                                                       内 SM rank → 远程地址）
  ld.shared::cluster.b32   r, [remote_smem]                          ← 读远程 SMEM
  st.shared::cluster.b32   [remote_smem], r                          ← 写远程 SMEM
  ```
- **内置变量**：`%cluster_ctarank`（本 CTA 在 cluster 内的 rank）、`%cluster_nctaid`（cluster 大小）

### B 组：Async 类（让多硬件单元异步协作）

#### B1. Async Transaction Barrier（SMEM 控制器内 mbarrier 状态机进化）

- **升级了什么**：mbarrier 状态字从"只跟踪线程到达 count"扩展到"同时跟踪线程到达 count + 异步事务字节数（transaction count）"；新增 TMA 引擎到 mbarrier 的直接更新通路（TMA 完成时自己更新 pending_tx）
- **注意**：mbarrier 这个原语 Ampere 就有（SM80，PTX 7.0 引入），Hopper 是给它加了 transaction count 这个新维度
- **解决的问题**：事件完成通知（时间维度）—— 让 consumer 能等待"对方做完了"的信号，统一 TMA、WGMMA、warp 间同步的 rendezvous 机制
- **编程模型**：`mbarrier.expect_tx`、`mbarrier.complete_tx`、`mbarrier.try_wait`
- **常用 PTX**：
  ```
  mbarrier.init.shared::cta.b64        [bar], count                  ← 初始化（旧）
  mbarrier.expect_tx.shared::cta       [bar], bytes                  ← 声明等待 N 字节 (Hopper 新)
  mbarrier.arrive.expect_tx.shared::cta [bar], bytes                 ← arrive + expect 一步 (Hopper 新)
  mbarrier.complete_tx.shared::cta     [bar], bytes                  ← 由 TMA 完成时自己调
                                                                       (硬件 → mbarrier 直接通路)
  mbarrier.try_wait.parity.shared::cta phase, [bar]                  ← phase-bit 等待 (Hopper 新)
  ```

#### B2. Register File 仲裁器升级（setmaxnreg）

- **升级了什么**：Register File 控制器新增运行时配额重分配状态机，允许 warpgroup 在运行时动态归还或借取寄存器（Ampere 及之前是静态分配，kernel launch 时固定）
- **解决的问题**：配合 warp specialization，让 producer warpgroup（寄存器需求少）和 consumer warpgroup（寄存器需求大）能不对称分配寄存器
- **编程模型**：`setmaxnreg.inc.sync`、`setmaxnreg.dec.sync`
- **常用 PTX**：
  ```
  setmaxnreg.inc.sync.aligned.u32  232                               ← consumer warpgroup 借寄存器
  setmaxnreg.dec.sync.aligned.u32   40                               ← producer warpgroup 还寄存器
  ```
- **配套指令（SM90 新增）**：
  ```
  elect.sync u32 r, mask                                             ← warp 内挑唯一 leader 线程
                                                                       (用 mask 内最小 lane id)
                                                                       —— warp specialization 里
                                                                       让单个线程发 TMA 时必用
  ```

#### B3. Proxy Fence（SM 内 LSU + 内存 ordering 逻辑升级）

- **升级了什么**：LSU 指令解码器识别新的 fence 类型；内存系统 ordering 逻辑扩展，跟踪不同 proxy（generic / async）的 in-flight writes；不同 fence 类型触发不同的 flush 范围
- **解决的问题**：跨 proxy 的内存可见性（空间维度）—— 把普通 SM 指令（generic proxy）的写"刷"到 TMA / WGMMA（async proxy）能看到的层级
- **编程模型**：`fence.proxy.async`、`fence.proxy.alias`
- **常用 PTX**：
  ```
  fence.proxy.async                                                  ← generic → async 全局可见
  fence.proxy.async.shared::cluster                                  ← 仅刷 DSMEM proxy
  fence.proxy.async.global                                           ← 仅刷 global proxy
  fence.proxy.alias                                                  ← alias proxy (TMA 描述符更新后用)
  ```

### C 组：独立的 kernel 边界优化（不属于上面任何主轴）

#### C1. GDC / PDL（CWD 状态机 + SM→CWD 控制通路升级）

- **升级了什么**：CWD 内新增 "pending dependent kernel" 状态机；SM→CWD 控制通路新增 launch_dependents 消息类型；新增 dependent kernel 的资源预留逻辑
- **解决的问题**：消除 GPU 内部 kernel-to-kernel 的 launch 延迟，让下一个 kernel 在当前 kernel 还没跑完时就开始 setup
- **编程模型**：`griddepcontrol.launch_dependents`、`griddepcontrol.wait`
- **常用 PTX**：
  ```
  griddepcontrol.wait                                                ← 等父 kernel 通知可以开始
  griddepcontrol.launch_dependents                                   ← 通知 CWD 子 kernel 可以 launch
  ```

---

## 三、通用升级（规格/容量提升，无新编程模型）

- **SMEM/L1 unified SRAM**：192 KB → 256 KB per SM（单 block 最多用 **228 KB** SMEM，剩余给 L1/tex）
- **L2 cache**：40 MB → 50 MB
- **HBM2e → HBM3**（带宽显著提升）
- **NVLink 第三代 → 第四代**（单 GPU 总带宽 900 GB/s）
- **PCIe 4.0 → PCIe 5.0**
- **第二代 MIG**（多实例 GPU 隔离增强，新增 compute 隔离）
- **DPX 指令**（动态规划加速，用于 Smith-Waterman、Floyd-Warshall 等算法，使用场景较小众）

---

## 四、关键洞察：Hopper 设计的两条主轴

把六项进化按问题域分组后，能看出 Hopper 架构的两条主轴：

### 主轴一：Scale Up（把单次操作做大）—— 空间放大

- **涉及硬件**：WGMMA（A1）+ Cluster（A2）+ TMA + DSMEM
- **设计哲学**：单条指令驱动更多算力，单次搬运覆盖更多数据，单个协同单元包含更多 SM

### 主轴二：Async（让多硬件单元异步协作）—— 时间放大

- **涉及硬件**：TMA 异步 + WGMMA 异步 + mbarrier 扩展（B1）+ setmaxnreg（B2）+ Proxy Fence（B3）
- **设计哲学**：数据搬运和计算可以并行进行，producer/consumer 解耦，多种硬件路径并发工作

### 两条主轴正交且互补

- **Scale Up 让每次操作的"绝对性能"变高** → 但单次操作太大，如果同步执行会让其他硬件饿死
- **Async 让多种操作"重叠执行"** → 但异步需要 scale up 提供的"批量化"才划算（小操作异步化的开销大于收益）
- **必须同时进行，缺一不可** —— 这就是 Hopper 这一代变化感觉特别大的原因

### 双主轴的交汇点

- **TMA**：既是 scale up（一条指令搬一个 tile）又是 async（异步执行）。两条主轴的核心交汇点，缺了 TMA 两条主轴都跑不通
- **WGMMA**：既是 scale up（warp → warpgroup 粒度）又是 async（`wgmma.mma_async`）。第二个交汇点

### 为什么 Warp Specialization 在 Hopper 上才流行

Warp specialization 需要三个前提同时具备：

1. **异步执行能力**（否则 producer/consumer 没意义）→ 主轴二
2. **大粒度操作**（否则 producer 一次搬太少，specialization 收益不抵分工开销）→ 主轴一
3. **寄存器不对称分配**（否则不同角色 warp 寄存器需求一致，没必要分化）→ B2 setmaxnreg

Ampere 上有异步（`cp.async`）但 scale up 不够，所以 warp specialization 没流行；Hopper 上两条主轴都到位，CUTLASS 3.x 直接全面转向 warp specialization。

### 用这个框架预测 Blackwell

按这个框架预测，Blackwell 大概率沿两条主轴继续延伸：

- **Scale Up 继续**：TMEM（更专用的 Tensor 存储）、TCGen05（更大粒度 MMA）、cluster pair（更大协同单元）
- **Async 继续**：更细粒度的 fence、跨 cluster 的异步原语、新的 transaction 类型
- **新的双主轴交汇点**：TMEM（类似 Hopper 的 TMA，既是新存储又是异步配套）

---

## 五、配套关系总结

四件事是配套设计的，缺一个都跑不通完整的 warp-specialized async pipeline：

- TMA 没有 mbarrier（B1）就没法通知完成
- WGMMA 没有 TMA 喂数据就饿死
- Cluster 没有 SM-to-SM Network 就退化成普通 block 调度
- setmaxnreg（B2）没有 warp specialization 就没意义
- Proxy Fence（B3）没有跨 proxy 的异步硬件就没必要

Hopper 的整体设计哲学：让 SM 从"什么都自己干的全能选手"变成"专注计算的核心 + 一圈专用协处理器（TMA、Tensor Core、SM-to-SM Network）+ 一整套异步协作原语"。专用化的代价是失去灵活性，收益是面积/能效/性能数倍提升。

---

## 落到 Stage 2 学习路线

| 周 | 对应这份笔记的哪些条目 |
|---|---|
| W5 WGMMA | A1（4th-gen Tensor Core）+ 主轴二的 wgmma 同步原语 |
| W6 TMA | 一.1 TMA + B1 mbarrier + B3 Proxy Fence |
| W7 Pipeline + Cluster | A2 Cluster + 一.2 SM-to-SM Network + B2 setmaxnreg + 主轴一与主轴二的组合（warp specialization）|
| W8 TMEM + UMMA | 用这份笔记当 Hopper baseline，对照 SM100 看"新交汇点 TMEM"|

读完每周回来对照这张表，标对应硬件已掌握。
