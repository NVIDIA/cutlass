# SM120 (消费 Blackwell) vs SM90/SM100 (数据中心)

## 核心论点

- SM120 和 SM100 的 SM 已是本质不同的设计，不是"阉割版"。
- 数据中心线（SM90/SM100）= 为大矩阵负载优化，愿意付大硅片代价。
- 消费线（SM120）= 为通用、跨负载场景优化，强调收益面广 + 成本可控。
- 判别一个特性留还是砍，看两条路：
  - **(A) 收益是否通用** —— 跨多种 workload 都有价值，还是只服务大矩阵？
  - **(B) 代价是否划算** —— 在消费卡的目标负载下，硅片代价能不能被收益摊平？

---

## 一、SM120 保留的东西 —— 通用 + 划算

### 1. TMA (`cp.async.bulk.tensor`)

- **通用性**：服务所有"把大块多维数据搬进 SMEM"的场景 —— 卷积、attention、各种 GEMM、tile-based 图形渲染、本地 LLM 推理。不绑定 wgmma。即使 Tensor Core 那段退回 `mma.sync`，TMA 依然加速 global→shared 这一级、降低线程占用、改善流水线。
- **代价**：不带大块 SRAM，主要是地址生成 + descriptor 解析 + 状态机，面积小。
- **结论**：通用性极高 + 代价可控 → 必留

### 2. TMA 配套的异步原语（mbarrier transaction count、Proxy Fence）

- **通用性**：TMA 一旦保留，它的完成通知（mbarrier）和跨 proxy 可见性（Proxy Fence）就是配套必需，任何用 TMA 的 kernel 都要用。
- **代价**：纯状态机/控制逻辑，面积极小。
- **结论**：TMA 的必要配套 + 几乎零成本 → 必留

### 3. `setmaxnreg`

- **通用性**：寄存器动态再分配对任何想做 warp 间不对称分工的 kernel 都有用，不绑定大矩阵。
- **代价**：Register File 控制器的小状态机，面积极小。
- **结论**：通用 + 极低成本 → 留（注：在消费卡上实际使用率不高，但留着不亏）

### 4. `mma.sync` 全数据类型（FP16/BF16/FP8 + 新增 FP4/FP6/MX）

- **通用性**：这是 Tensor Core 的基础接口，所有 AI workload 都用。FP4/FP6/MX 是上层软件生态的硬约束 —— 不支持的话，消费卡无法运行任何 FP4 模型（本地 LLM 推理是消费卡的重要市场）。
- **代价**：数据通路扩展，中等，但收益面是"所有 AI 应用"。
- **结论**：通用性顶格 + 生态强制 → 必留

### 5. `stmatrix`

- **通用性**：寄存器↔SMEM 的矩阵转置搬运，任何用 Tensor Core 的 kernel 都可能用，不绑定大矩阵。
- **代价**：小。
- **结论**：通用 + 低成本 → 留

---

## 二、SM120 砍掉的东西 —— 专用 + 不划算

### 1. `wgmma`（warpgroup 异步 MMA）

- **为何砍**：wgmma 的价值绑定在"大 tile + 脱离寄存器堆 + warp specialization 流水线"上。这套范式服务的是数据中心 long-running GEMM。消费卡 Tensor Core 小，逐寄存器 scoreboard 同步够用，引入 wgmma 要新增 group counter + warpgroup 调度硬件，收益太专（只服务大矩阵）。
- **两条路判定**：通用性低（只服务大矩阵）+ 代价不划算（消费侧无对应 workload）→ 砍

### 2. `tcgen05` (UMMA) + TMEM

- **为何砍**：tcgen05 是 Tensor Core 子系统化 —— 单线程发起、CTA 范围、累加器迁到 TMEM。TMEM 是真正的大硅片代价：256 KB SRAM/SM，全 GPU 几十 mm² 量级。这套东西纯为"喂饱超大 Tensor Core、让累加器脱离寄存器堆"服务。
- **两条路判定**：通用性极低（纯大矩阵）+ 代价极高（TMEM 大 SRAM）→ 砍（这是两条路同时判死刑的最典型案例）

### 3. 2-SM Cooperative MMA (`tcgen05.mma.cta_group::2`)

- **为何砍**：让两个 SM 协同算一条超大 MMA（MMA_M 到 256）。纯粹服务大矩阵，需要 TPC 内紧耦合通路硬件。
- **两条路判定**：通用性极低 + 需新增互联硬件 → 砍

### 4. 有效的 Cluster + DSMEM + SM-to-SM Network

- **为何砍**：跨 SM 协同（把多 SM 的 SMEM 虚拟拼接成更大逻辑 SMEM）服务的是"单 SM SMEM 装不下大 tile"的场景 —— 又是大矩阵问题。SM120 把 cluster size 实际限制到 1×1×1（等于没有），SM-to-SM Network 不配置。
- **两条路判定**：通用性低（大矩阵协同）+ GPC 内互联硬件代价不小 → 砍（只留 API 名义，无硬件）

### 5. TMA multicast

- **为何砍**：一次 GMEM 读分发到 cluster 内多个 SM。它绑定 cluster —— cluster 都没了，multicast 失去依托。
- **两条路判定**：通用性低（绑定 cluster）+ 无 cluster 配套 → 砍

### 6. 大 SMEM 容量（228 KB → 128 KB）

- **为何砍**：大 SMEM 主要服务大 tile GEMM。消费 workload tile 小，128 KB 够用。SRAM 是直接的面积成本。
- **两条路判定**：大容量收益集中在大矩阵 + SRAM 直接占面积 → 砍到够用为止

---

## 三、汇总表

| 特性 | 通用性（跨负载?） | 代价 | 消费卡判定 | 逻辑 |
|------|-------------------|------|------------|------|
| `mma.sync` + FP4/FP6/MX | 顶格（所有 AI）+ 生态强制 | 中 | ✅ 留 | 通用 + 强制 |
| TMA | 高（卷积/attention/GEMM/图形/推理） | 小 | ✅ 留 | 通用 + 划算 |
| mbarrier / Proxy Fence | 高（TMA 配套） | 极小 | ✅ 留 | 配套 + 零成本 |
| `setmaxnreg` | 中（通用分工） | 极小 | ✅ 留 | 通用 + 零成本 |
| `stmatrix` | 中（Tensor Core 通用） | 小 | ✅ 留 | 通用 + 低成本 |
| `wgmma` | 低（大矩阵 + warp spec） | 中 | ❌ 砍 | 专用 + 不划算 |
| `tcgen05` + TMEM | 极低（纯大矩阵） | 极高（SRAM） | ❌ 砍 | 专用 + 代价大 |
| 2-SM MMA | 极低（纯大矩阵） | 中（互联） | ❌ 砍 | 专用 + 需新硬件 |
| Cluster/DSMEM/SM2SM | 低（大矩阵协同） | 中高（互联） | ❌ 砍 | 专用 + 代价不小 |
| TMA multicast | 低（绑定 cluster） | 小 | ❌ 砍 | 绑定已砍项 |
| 大 SMEM（228→128KB） | 低（大 tile） | 高（SRAM） | ⬇️ 缩 | 收益集中 + 占面积 |

---

## 四、一句话提炼

- SM120 留下的全是"通用底座"：搬数据（TMA）、算小块（`mma.sync` 全精度）、配套同步（mbarrier/fence）—— 这些对卷积、attention、推理、图形都有价值，且代价可控。
- SM120 砍掉的全是"大矩阵专用 + 大硅片代价"：异步大 tile MMA（wgmma/tcgen05）、专用累加器存储（TMEM）、跨 SM 协同（cluster/DSMEM）—— 这些只为数据中心 long-running GEMM 服务，在消费卡上既无对应 workload，又要付大面积代价。
- **本质**：数据中心卡为"大矩阵吞吐"而生，愿意为 TMEM/cluster 这种专用大硅片买单；消费卡为"通用 + 成本"而生，只装收益面广、代价可控的通用底座。两者的 SM 已是不同物种，不是同一设计的高低配。

---

## 五、这个框架的额外价值

你最终落到的"通用性 + 成本"两条路，比我们前面绕的"独立可用 vs 必须配套""硬件成本高低"都更扎实，原因是：

- "通用性"可以从产品定位直接判断，不需要拿不到的 die area 数据 —— 你只要问"这个特性服务的 workload 在消费卡上常见吗"，就能判
- "成本"只需要判量级（TMEM 带大 SRAM = 大；TMA 纯逻辑 = 小），不需要精确数字，而量级判断是公开信息能支撑的

所以这套框架可证伪、可预测。拿它去看下一代消费卡（Rubin consumer）：凡是"通用底座"性质的（改进版 TMA、新的通用同步原语、新数据类型）大概率保留；凡是"大矩阵专用 + 大硅片"的（更大的专用 Tensor 存储、更大范围的 SM 协同）大概率砍。这比"按面积砍"或"按配套砍"都更准，因为它直接对应了 NVIDIA 真正在优化的东西：让消费卡通用够用、成本可控，同时守住数据中心卡的大矩阵护城河。
