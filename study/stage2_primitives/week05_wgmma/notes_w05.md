# W5 WGMMA — 学习笔记（读 + ex12）

> 这周的产出。"读"四个文件 + ex12 跑通。ex11（单 tile 实跑）等租 H20 再补。
> 本周问得比 README 深很多，核心收获是把**两条线**接上了：
> - **TV layout 线**（谁持有哪个元素 / 寄存器侧）
> - **swizzle + descriptor 线**（数据在 smem 物理怎么摆 / 硬件怎么读）
> SS 模式的精髓 = 把 A/B 从 TV 线甩给 swizzle 线（不占寄存器），只把 C 留在 TV 线。

---

## 1. WGMMA 同步四件套（`mma_sm90_gmma.hpp:42-103`）

| CuTe 函数 | PTX | 性质 | 管 wgmma 的 |
|-----------|-----|------|------|
| `warpgroup_arrive()` | `wgmma.fence.sync.aligned` | **可见性栅栏，不阻塞** | 入口 |
| `warpgroup_commit_batch()` | `wgmma.commit_group` | 封一个 wgmma 批次（划计数边界） | 中 |
| `warpgroup_wait<N>()` | `wgmma.wait_group N` | **阻塞**，等未完成 group ≤ N | 出口 |
| `warpgroup_fence_operand(reg)` | `asm volatile("":"+r"(reg))` | **零指令**纯编译器栅栏 | 累加器前后各一道 |

**关键纠正（自检 Q2）**：
- `fence` **不是等待**，是排序/可见性。它保证 fence 前对累加器/smem 的写，对随后的 wgmma **可见且不被重排**。"等待"是 `wait_group` 的事。
- 三步而非一步 = 三个正交职责：**fence 建可见性（入口）/ commit 划批次边界 / wait 按批次等待（出口）**。合一就没法"发了先不等、留 N 个在飞"做流水线。
- `wait_group` 只数 wgmma（独立 scoreboard，跟 cp.async 的 group 计数分开两套）。

**为什么需要 fence —— async proxy（深层原因）**：
wgmma 通过独立的 **async proxy** 访问 smem/寄存器，跟普通线程的 generic proxy **不是同一条路径，不自动同步**。普通 scoreboard 不跨 proxy 工作 → 没有 fence，tensor core 可能从 async proxy 读到 generic proxy 还没刷新的写（旧值/垃圾）。`wgmma.fence` = 手动在两个 proxy 间架可见性桥。这也是它叫 fence 不叫 wait 的原因（同 CPU memory_fence 一类）。

**`fence_operand` 拦什么**：累加器寄存器被 async proxy 在**后台异步读写**，但 C++ 编译器不知道（它以为 wgmma 那条 asm 执行完 accum 就是终值）。`"+r"` 假装读写 accum，阻止编译器：(A) 把读累加器提前到 wait 之前；(B) 在 wgmma 后台写期间复用/重排这些物理寄存器。标准写法：发射前 + 取用后各夹一道。

**与 cp.async 的关系**：同一个"异步指令组流水线"模式 —— `发一批 → commit_group → wait_group<N>`。区别：cp.async 异步的是**数据搬运**（DMA），wgmma 异步的是**计算**（tensor core）；wgmma 全带 `.sync.aligned`（warpgroup 128 线程收敛协同），cp.async 是 per-thread。

---

## 2. SS vs RS（`mma_sm90_gmma.hpp:139-219`）

结构差异就一处：**A 操作数来源**。但带走 4 条：

| | SS | RS |
|--|----|----|
| `ARegisters` | `uint64_t[1]`（descriptor） | `uint32_t[4]`（真寄存器装 8×f16） |
| PTX A 操作数 | ` %2`（单个=descriptor） | `{%2,%3,%4,%5}`（花括号=寄存器组） |
| 约束 | 无 | `static_assert(tnspA==K)` |
| B | descriptor | **仍是 descriptor** |

- **没有 RR**：B 永远来自 smem（descriptor），只有 A 有"进不进寄存器"的选择。
- **RS 强制 A K-major**：寄存器里 A 的布局是 ldmatrix 摆好的固定 fragment，wgmma 读寄存器走**硬连线固定映射，没有 SS 那种可编程 stride/descriptor 地址生成器**，所以没法转置 → 只能 K-major。
- **累加器 `"+r"(d0),"+r"(d1)`**：既输入又输出，印证 async proxy 后台读写。`CRegisters=uint32_t[2]` → m64n8 每线程持 2×uint32 = 4×f16。
- **选择（自检 Q5）**：SS 省寄存器但每次从 smem 读 A；RS 省一次 smem 读但吃寄存器（×流水级数，压 occupancy）。A 被反复复用时值得 RS（如 FA 的某操作数），否则 SS。

---

## 3. SS 转置靠改 descriptor（`mma_sm90_desc.hpp`，151 行）

核心就一个 `union GmmaDescriptor`（64-bit），**不用背 bit 布局**，懂一句话即可：

> descriptor = 交给 wgmma 地址生成器的"smem 取数说明书"，内容是**起始地址 + 两个方向 stride（LBO/SBO）+ swizzle 模式（layout_type_）**，纯几何零数据。

- **两个 stride 方向随 major 切换**：K-major 下 LBO=8行→下8行、SBO=8列→下8列；MN-major 下角色互换。**转置 = 互换这两个 stride 的角色**。
- `layout_type_`（2 bit）= SWIZZLE_NONE/32B/64B/128B，是软件侧 `Layout_*_Atom` 的硬件对应物。wgmma 读 smem 时按它自动 un-swizzle。
- 全是几何、零数据 → 印证 SS 模式 A 不进寄存器（descriptor 只是"去哪取"的说明，数据硬件自己流式读进 PE 阵列）。

**"smem 地址生成器"在哪**：不是独立的"smem 控制器"。它是 **wgmma(GMMA) 单元内部**的一段逻辑，解码 descriptor 的 stride/swizzle，自动生成访问 smem bank 的地址序列。smem bank 本身只管存储 + 仲裁，"按什么规则取"的智能在发起方。（具体微架构 NVIDIA 未公开，此为 PTX 语义 + proxy 模型层的确定结论。）

---

## 4. Swizzle 与 8 个 smem 砖块（`mma_traits_sm90_gmma.hpp:71-130`）

8 个 `Layout_*_Atom` = `{MN, K}-major × {INTER/SW32/SW64/SW128}` = wgmma 认的**全部**合法 smem 摆法。
- **两批**：`_Bits` 版按 bit 定义（swizzle 是物理的、类型无关）；`template<Type>` 版用 `upcast<sizeof_bits<Type>>` 换算到元素单位。
- **`using X = decltype(upcast<N>(Bits{}))` 语法**：`decltype(f(X{}))` = "f 喂入 X 的返回值类型"，纯编译期。CuTe 到处是这个套路（用函数算 layout，但 using 要类型，故 decltype）。

**Swizzle<B, M, S>（都是 bit 数）**：
| 参数 | 含义 | 这 8 个里 |
|------|------|-----------|
| **B** (Bits) | 参与 XOR 打散的 bit 数 = 打散几路 | **变量** 0/1/2/3 → INTER/SW32/64/128 |
| **M** (MBase) | 最低 M 位不动 = 不打散的原子块 | 固定 4 |
| **S** (Shift) | 被异或两段 bit 的间距 | 固定 3 |

机制：`apply(off) = off ^ ((off & yyy_msk) >> S)`，把高位段（行号 bit[M+S..]）XOR 进低位段（bit[M..]）。

**bank 几何对账（关键直觉）**：
- `2^M = 16` 字节 = 一次 **128-bit 访问 = 4 banks**（不动的原子块，块内连续读无冲突）
- `2^(M+S) = 2^7 = 128` 字节 = **一条 bank line = 32 banks** = swizzle 周期 ✅（用户自己推出来的）
- `2^B` = 这条 line 内被切成几个 chunk 互相打散：B=3 → 8 个 16B chunk → 8×8 拉丁方，**填满 32 banks**
- **B 越大打散越彻底**，上限 B=3（再大 bit 段重叠非法，且已填满整条 line）

**自检 Q4**：fp16 K=16 一行 = 16×2 = 128 字节 = 正好一条 line → 用满 SW128 最优。fp8 一行才 64 字节（半条 line）→ 用 SW128 浪费一半 chunk → 退 SW64。**swizzle 强度由"一行实际占多少 bank line"决定，刚好填满最优。**

**swizzle 目的（精确）**：让 **wgmma 地址生成器（及 cp.async/TMA 写入）访问 smem 时，一拍涉及的地址均匀打散到 32 banks**。主语是地址生成器，不是"32 线程各自读"。写入和读出用同一 swizzle，数据语义不变、物理始终打散。

---

## 5. ex12 输出解读 — TV layout（本周最核心收获）

`SM90_64x8x16_F16F16F16_SS`（N=8）打印：
```
ThrID:      _128:_1                       # 一条 WGMMA 需要 128 线程(1 warpgroup)，连续编号
ThrLayoutVMNK: (_128,_1,_1,_1)            # V=128(atom内线程), M=N=K=1(单 atom 没平铺)
LayoutA_TV: (_128,(_64,_16)):(_0,(...))   # T-stride=0 → 退化
LayoutB_TV: (_128,(_8,_16)):(_0,(...))    # T-stride=0 → 退化
LayoutC_TV: ((_4,_8,_4),(_2,_2,_1)):((_128,_1,_16),(_64,_8,_512))  # T-stride≠0 → 真分工
```

**TV layout 统一定义**：`(thread_id, value_index) → 矩阵元素的逻辑坐标(线性 offset)`。A/B/C 三个都是这同一种数学对象。

**但 SS 模式下 A/B 退化（T-stride=0）—— 这是 SS 的指纹**：
- stride=0 意味着"映射与 thread id 无关"→ A/B **不归任何线程持有**，整块在 smem 由硬件读。
- 所以 SS 的 A/B，TV layout **不携带真实分工信息**，真正语义转移到 smem swizzle layout + descriptor。

**C 非退化（T-stride≠0）—— 累加器真在寄存器、真按线程分**：
- `LayoutC_TV: ((4,8,4),(2,2,1))` → T 维 4×8×4=128，V 维 2×2×1=4（每线程 4 个 C 元素 = 2×uint32 = 4×f16 ✅）。
- offset 是 C(64×8) 列优先线性坐标：`m=off%64, n=off/64`，范围 0~511（512 个元素）。
- 实算分工：thread0 持 C 的 (0,0)(8,0)(0,1)(8,1)——**间隔的 4 个点，不是连续块**。T 的 (4,8,4)：t1(size8) 沿 N 铺 8 列；t0+t2 沿 M 铺行。V 的 (2,2)：v0→+1列, v1→+8行。
- **WGMMA 算完，结果按这个 pattern 散落在 128 线程寄存器里**，epilogue 必须用 LayoutC_TV（经 `partition_C`）反查"我这个寄存器值写到 C 的哪个 (m,n)"。

---

## 6. op / traits / atom 三层解耦（`mma_atom.hpp`）

你写的 `SM90_64x8x16_F16F16F16_SS` 只是 **MMA_Op**（alias → `MMA_64x8x16..._SS`，最底层只有 `fma()` 发 PTX，不懂 layout）。三层靠模板特化自动接：

```
SM90_64x8x16_..._SS{}              ← MMA_Op (fma/PTX)
  │ make_tiled_mma(MMA_Op) 重载(:548) 自动包
  ▼
MMA_Atom<op>  (:45)                ← 统一接口；继承时按类型查特化
  ▼
MMA_Traits<op>  (:480, traits 文件) ← 给 op 配 5 个 layout (ThrID/Shape/A_TV/B_TV/C_TV)
  ▼
Layout_K_SW128_Atom 等              ← 第 4 节那 8 个 swizzle 砖块
```

- layout **不在 op 文件里**，住在隔壁 `MMA_Traits<op>` 特化，靠 C++ 类型匹配挂钩。
- ex12 打印的 "MMA_Atom" 段内容全来自 `MMA_Traits<op>`。
- **设计意图**：换硬件（SM80 mma.sync → SM90 wgmma → SM100 umma）只换 op + traits 特化，上层 `MMA_Atom`/`make_tiled_mma`/`cute::gemm` 一行不动。

**`make_tiled_mma` 的作用**：把"一条硬件 MMA(atom)"放大成"一个 CTA tile 级操作"。输入 atom + `AtomLayoutMNK`（用几个 atom 怎么平铺，如 `2x1x1`=2 warpgroup=256 线程）→ 输出 `TiledMMA`，能 `partition_A/B/C` 把大张量按"谁管哪块"切片，`cute::gemm` 自动循环发够 wgmma 盖住 tile。ex12 没给 AtomLayout → 默认 1x1x1 → 单 atom 128 线程，看最小情况。

---

## 7. MMA 完整语义 = TV 线 + swizzle 线（用户总结的修正版）

> A_TV/B_TV/C_TV 都是 `(tid, value)→矩阵坐标` 的统一映射。**对"进寄存器"的操作数（C 永远是；A/B 在 RS/mma.sync 时是），这个映射就是完整语义。但 SS 模式的 A/B 不进寄存器，TV 退化成 stride=0，真正语义转移到 smem swizzle layout + descriptor。**

| 模式 | A/B 语义来自 | C 语义来自 | TV 三件套够吗 |
|------|------|------|------|
| mma.sync / RS（寄存器输入） | A_TV/B_TV（真分工） | C_TV | ✅ 够 |
| **WGMMA SS（smem 输入）** | **swizzle layout + descriptor**（A_TV 退化） | C_TV（真分工） | ❌ A/B 要看 smem 侧 |

SS 把 A/B 从 TV 线甩给 swizzle 线（不占寄存器），只把 C 留在 TV 线 —— 这就是 WGMMA 比 mma.sync 省寄存器的根本原因。

---

## 自检答案速查
1. **128 线程 = 1 warpgroup = 4 warp**。WGMMA 绑定 warpgroup 粒度发射（`.sync.aligned`）。
2. 见第 1 节：fence(可见性入口)/commit(批次边界)/wait(出口等待) 三正交职责，分开才能做流水线。
3. m64n128k16：**m=64 → A/C 的 M 维；n=128 → B/C 的 N 维；k=16 → A/B 的 K 维（一条指令的 K 深度）**。
4. 见第 4 节：由"一行占多少 bank line"决定；fp16 一行 128B 用满 SW128，fp8 一行 64B 用 SW64。
5. 见第 2 节：RS 吃寄存器压 occupancy，A 复用多时值得；否则 SS 省寄存器。

## 待办（等 H20）
- [ ] ex11 单 tile WGMMA 实跑（要 Hopper）
- [ ] ex12 跑 N=256，验证 C 的 value 维随 N 线性增长（N=8→4 个；N=256→?）
- [ ] 5060 Ti 静态验证：sm90a 有 wgmma.mma_async / sm120a 无
