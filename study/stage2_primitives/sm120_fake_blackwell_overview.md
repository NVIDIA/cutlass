# SM120 (消费 Blackwell) vs SM90/SM100 (数据中心)

## 框架：在 SM90/SM100 两条定律之上加一条判定

> 沿用 SM90/SM100 的两条定律（分化定律 / 进化定律 —— 见 `sm90_hopper_overview.md` 顶部）。SM120 是消费卡，问题从"加什么"换成"从 SM100 全集里留什么砍什么"，所以多一条判定：

- **(A) 通用性**：这个特性服务的 workload，在消费卡常见的负载里（卷积 / attention / 推理 / 图形）有多大占比？还是只服务数据中心 long-running GEMM？
- **(B) 代价**：硅片成本量级 —— 是大 SRAM / 大互联（大），还是控制路径 / 状态机（小）？

判定结果：

| (A) × (B) | 结果 |
|-----------|------|
| 通用 + 划算 | ✅ **留** |
| 通用 + 不划算 | ⬇️ **缩**（保留 API，容量/规模缩水） |
| 专用 + 划算 | 看情况，多数留作生态硬约束 |
| 专用 + 不划算 | ❌ **砍** |

## 核心论点

- SM120 和 SM100 的 SM 已是本质不同的设计，不是"阉割版"。
- 数据中心线（SM90/SM100）= 为大矩阵负载优化，愿意付大硅片代价。
- 消费线（SM120）= 为通用、跨负载场景优化，强调收益面广 + 成本可控。

---

## 一、分化定律的取舍（SM90/SM100 新增的独立硬件单元 → 消费卡几乎全砍）

> 分化定律产物 = 独立 die area。这一类在消费卡上几乎都判死刑，因为大硅片代价直接对应"面积成本"。

### 1.1 ❌ 砍：tcgen05 + TMEM（对应 SM100 一.1, 一.2）

- **SM100 角色**：Tensor Core 子系统化，累加器从寄存器堆迁到 TMEM（256 KB/SM 专用 SRAM）+ 单线程 CTA-scope 发起 MMA
- **判定**：通用性极低（纯大矩阵）+ 代价极高（TMEM 大 SRAM，全 GPU 几十 mm² 量级）
- **结论**：两条路同时判死刑的最典型案例 → 砍

### 1.2 ❌ 砍：2-SM Cooperative MMA（对应 SM100 一.3）

- **SM100 角色**：TPC 内紧耦合通路硬件 + `tcgen05.mma.cta_group::2`，让两个 SM 协同算一条 MMA_M=256 的大 MMA
- **判定**：通用性极低（纯大矩阵）+ 需新增 TPC 内互联硬件 → 砍

### 1.3 ❌ 砍：有效的 Cluster + DSMEM + SM-to-SM Network（对应 SM90 一.2）

- **SM90/SM100 角色**：GPC 内 SM 互联网络，跨 SM 协同把多个 SMEM "虚拟拼接"成更大逻辑 SMEM
- **判定**：通用性低（服务大 tile GEMM）+ 互联硬件代价不小 → 砍
- **SM120 表现**：cluster size 实际限制到 1×1×1（等于没有），SM-to-SM Network 不配置，只留 API 名义

### 1.4 ❌ 砍：CLC（Cluster Launch Control，对应 SM100 一.4）

- **SM100 角色**：CWD 内 dynamic scheduling 状态机，硬件级 persistent kernel + stream-K
- **判定**：通用性低（绑定 cluster + persistent GEMM）+ 配套硬件不少 → 砍

### 1.5 ✅ 留：TMA（对应 SM90 一.1）

- **SM90 角色**：从 LSU 分化出的大块多维 tensor 搬运引擎
- **判定**：通用性极高（卷积 / attention / GEMM / 图形 / 本地 LLM 推理都吃）+ 代价小（地址生成 + descriptor + 状态机，无大 SRAM）
- **关键洞察**：这是"分化定律产物在消费卡上保留"的少见例外 —— 因为它**已经升级成通用底座**，不绑定 wgmma；即使 Tensor Core 那段退回 `mma.sync`，TMA 依然加速 G→S 这一级
- **源码锚点**：消费卡仍走 `include/cute/arch/copy_sm90_tma.hpp`（和 H100 共用同一套 atom）

### 1.6 ❌ 砍：TMA multicast（对应 SM90 TMA 的配套）

- **SM90 角色**：一次 GMEM 读分发到 cluster 内多 SM
- **判定**：绑定 cluster —— cluster 都没了，multicast 失去依托 → 砍

---

## 二、进化定律的取舍（既有硬件的改造）

> 进化定律产物 = 控制路径 / 状态机改造，本身代价小，所以判定主要看 (A) 通用性。

### 2.1 ❌ 砍：WGMMA（对应 SM90 A1）

- **SM90 角色**：4th-gen Tensor Core 异步化，warp → warpgroup 粒度
- **判定**：通用性低（绑大 tile + warp specialization 流水线）+ 引入需新增 group counter + warpgroup 调度硬件，收益太专 → 砍
- **SM120 替代**：Tensor Core 退回 `mma.sync`（同步、warp 级），逐寄存器 scoreboard 同步够用

### 2.2 ✅ 留：mma.sync 全数据类型 + 新增 FP4/FP6/MX（对应 SM100 A3 的数据通路扩展）

- **判定**：通用性顶格（所有 AI workload 都用）+ 生态强制 —— 不支持 FP4/FP6/MX 的话，消费卡无法跑任何 FP4 模型，本地 LLM 推理是消费卡重点市场
- **代价**：数据通路扩展中等，但收益面是"所有 AI 应用" → 留

### 2.3 ✅ 留：mbarrier transaction count + Proxy Fence（对应 SM90 B1, B3）

- **判定**：TMA 留了，它的完成通知（mbarrier）和跨 proxy 可见性（Proxy Fence）就是配套必需
- **代价**：纯状态机 / 控制逻辑，面积极小
- **结论**：TMA 必要配套 + 几乎零成本 → 留

### 2.4 ✅ 留：setmaxnreg（对应 SM90 B2）

- **判定**：寄存器动态再分配对任何想做 warp 间不对称分工的 kernel 都有用，不绑大矩阵
- **代价**：Register File 控制器小状态机
- **结论**：通用 + 极低成本 → 留（注：消费卡上实际使用率不高，但留着不亏）

### 2.5 ✅ 留：stmatrix（SM90 配套指令）

- **判定**：寄存器↔SMEM 矩阵转置搬运，任何用 Tensor Core 的 kernel 都可能用
- **代价**：小
- **结论**：通用 + 低成本 → 留

---

## 三、通用升级的取舍（容量缩水）

> 这一类在 SM90/SM100 是"无新编程模型，只扩容量"。消费卡反向操作：能缩就缩。

### 3.1 ⬇️ SMEM per SM：228 KB → 128 KB

- **SM90/SM100**：unified L1/SMEM 256 KB，最大可分配给单 block **228 KB**
- **SM120**：unified L1/SMEM 128 KB per SM；**最大单 block 可用约 99 KB**（CUDA Blackwell Tuning Guide §1，compute capability 12.0）
- **判定**：大 SMEM 主要服务大 tile GEMM，消费 workload tile 小，~100 KB 够用；SRAM 是直接的面积成本 → 缩到够用为止

### 3.2 ⬇️ L2 / HBM / NVLink

- L2 容量、HBM 带宽（消费卡用 GDDR7 而非 HBM3e）、NVLink 都缩水
- 判定逻辑相同：大矩阵 long-running 才吃满，消费 workload 吃不动 → 缩

---

## 四、汇总表（按上面的章节分类一栏一栏对照）

| 特性 | 对应章节 | 原定律 | 通用性 | 代价 | 消费卡判定 |
|------|---------|--------|--------|------|------------|
| `mma.sync` + FP4/FP6/MX | 2.2 | 进化（数据通路扩展） | 顶格（所有 AI）+ 生态强制 | 中 | ✅ 留 |
| TMA | 1.5 | 分化（已成通用底座） | 高（卷积/attention/GEMM/图形/推理） | 小 | ✅ 留 |
| mbarrier / Proxy Fence | 2.3 | 进化 | 高（TMA 配套） | 极小 | ✅ 留 |
| `setmaxnreg` | 2.4 | 进化 | 中（通用分工） | 极小 | ✅ 留 |
| `stmatrix` | 2.5 | 进化 | 中（Tensor Core 通用） | 小 | ✅ 留 |
| `wgmma` | 2.1 | 进化 | 低（大矩阵 + warp spec） | 中 | ❌ 砍 |
| `tcgen05` + TMEM | 1.1 | 分化 | 极低（纯大矩阵） | 极高（SRAM） | ❌ 砍 |
| 2-SM MMA | 1.2 | 分化 | 极低（纯大矩阵） | 中（互联） | ❌ 砍 |
| Cluster/DSMEM/SM2SM | 1.3 | 分化 | 低（大矩阵协同） | 中高（互联） | ❌ 砍 |
| CLC | 1.4 | 分化 | 低（绑 cluster） | 中 | ❌ 砍 |
| TMA multicast | 1.6 | 分化配套 | 低（绑 cluster） | 小 | ❌ 砍 |
| 大 SMEM (228→128 KB) | 3.1 | 通用升级 | 低（大 tile） | 高（SRAM） | ⬇️ 缩 |

---

## 五、一句话提炼

- SM120 留下的全是"通用底座"：搬数据（TMA）、算小块（`mma.sync` 全精度）、配套同步（mbarrier / fence）—— 这些对卷积、attention、推理、图形都有价值，且代价可控。
- SM120 砍掉的全是"大矩阵专用 + 大硅片代价"：异步大 tile MMA（wgmma / tcgen05）、专用累加器存储（TMEM）、跨 SM 协同（cluster / DSMEM）—— 这些只为数据中心 long-running GEMM 服务，在消费卡上既无对应 workload，又要付大面积代价。
- **本质**：数据中心卡为"大矩阵吞吐"而生，愿意为 TMEM/cluster 这种专用大硅片买单；消费卡为"通用 + 成本"而生，只装收益面广、代价可控的通用底座。两者的 SM 已是不同物种，不是同一设计的高低配。

---

## 六、用此框架预测下一代消费卡（Rubin consumer）

按"通用性 × 代价"两条路推：

- **大概率保留**（通用底座 + 代价可控）：改进版 TMA、新的通用同步原语、新的低精度数据类型、新的 warp specialization 配套指令
- **大概率砍**（大矩阵专用 + 大硅片）：更大的专用 Tensor 存储（TMEM 后继）、更大范围的 SM 协同（4-SM/8-SM MMA 如果 SM100 后继加了）、persistent kernel 硬件调度的进一步扩展

这套框架可证伪、可预测，比"按面积砍"或"按配套砍"更准，因为它直接对应了 NVIDIA 真正在优化的东西：让消费卡通用够用 / 成本可控，同时守住数据中心卡的大矩阵护城河。

---

## 七、配套关系：SM90 / SM100 / SM120 三主轴回看

回到 SM90 笔记定义的两条主轴（Scale Up / Async），SM100 笔记新增的第三条（物理解耦）：

| 主轴 | SM90 | SM100 | SM120（消费卡）|
|------|------|-------|----------------|
| Scale Up（空间放大） | WGMMA + Cluster | tcgen05 + 2-SM CTA Pair + FP4/FP6 | **几乎全砍**，只留 FP4/FP6/MX 的数据类型扩展 |
| Async（时间放大） | mbarrier + setmaxnreg + Proxy Fence | + `tcgen05.commit` + TMEM 异步访问 + CLC | **基本保留**（TMA + mbarrier + Proxy Fence + setmaxnreg）|
| 物理解耦（资源放大） | （无） | TMEM + 单线程发起 MMA | **完全没有**，回退到寄存器堆 + warp 语义 |

结论：**Async 主轴在消费卡上几乎全留，Scale Up / 物理解耦主轴几乎全砍**。这印证了"通用底座保留 + 大矩阵专用砍"的判断 —— Async 主轴本身就是"通用同步原语"，与 workload 大小关系小；Scale Up / 物理解耦才是大矩阵专用的硬投入。
