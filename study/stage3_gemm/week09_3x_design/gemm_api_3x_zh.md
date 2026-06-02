# CUTLASS 3.0 GEMM API（gemm_api_3x.md 完整翻译）

> 译自 `media/docs/cpp/gemm_api_3x.md`。末尾 license 样板略；GitHub 链接保留为路径。

CUTLASS 为 GPU 系统层级不同层次上的 **矩阵乘累加(MMA)** 操作，提供统一的编程模型。CUTLASS 3.0 的 GEMM API 对应以下层级（从高到低）：

1. **Device**（设备层）
2. **Kernel**（内核层）
3. **Collective**（集体层）
4. **Tiled MMA and Copy**（平铺 MMA/拷贝层）
5. **Atom**（原子层）

本文档详细讲前三层（Device / Kernel / Collective），简略讲 Tiled MMA/Copy 和 Atom 层，后两层细节引导读者去看 CuTe 教程。

## CUTLASS GEMM 模型

CUTLASS 实现的算法，把经典的"三重嵌套循环"GEMM 算法，表达成一个**镜像上述层级的平铺结构**。

下面的伪代码描述了面向 warp 同步矩阵乘指令（如 `mma.sync`）的 GEMM kernel 模型。整个操作称为 "Gemm"，因为假定有一个 epilogue 操作执行类似 BLAS 的通用矩阵更新。这是伪代码，仅用来说明各层分别对应 GEMM 的内层还是外层循环：

```c++
// cutlass::gemm::kernel::GemmUniversal: ClusterTileM / ClusterTileN 循环
//   要么由硬件光栅化(rasterize)，要么在 persistent kernel 中由内核调度。
// 对 thread block cluster 的并行
for (int cluster_m = 0; cluster_m < GemmM; cluster_m += ClusterTileM) {
  for (int cluster_n = 0; cluster_n < GemmN; cluster_n += ClusterTileN) {

    // cutlass::gemm::collective::CollectiveMma: 遍历所有 k-tile 的 mainloop
    // 这一阶段不做循环展开
    for (int k_tile = 0; k_tile < size<2>(gmem_tensor_A); k_tile++) {

      // cute::gemm(tiled_mma, a, b, c) 内部的循环；Dispatch 5: (V,M,K) x (V,N,K) => (V,M,N)
      // TiledMma 通过它的 Mma_Atom 使用硬件指令
      // TiledMma 的 atom layout / value layout / 排列(permutation) 定义迭代顺序
      for (int tiled_mma_k = 0; tiled_mma_k < size<2>(A); tiled_mma_k++) {
        for (int tiled_mma_m = 0; tiled_mma_m < size<1>(A); tiled_mma_m++) {
          for (int tiled_mma_n = 0; tiled_mma_n < size<1>(B); tiled_mma_n++) {

            // TiledMma 的向量模式分发到底层指令
            mma.call(d, a, b, c);
          } // tiled_mma_n
        } // tiled_mma_m
      } // tiled_mma_k
    } // k_tile mainloop
  } // cluster_m
} // cluster_n
```

最外三层嵌套 `for` 对应**对 thread block cluster 的并行**。代码里其实**不会**把它们写成显式 `for`——对 tile 的并行方案由 **CUDA grid launch 语义**隐含表达。但对于 **persistent kernel**，这三层循环会被写成源码里的**单个 `while` 循环**，它向 [work tile scheduler](include/cutlass/gemm/kernel/sm90_tile_scheduler.hpp) 查询要计算的问题 tile。

在这三层嵌套 `for` 内部，是把矩阵 tile 从 global memory 拉进更"本地"的内存（smem 或寄存器）并计算 MMA 的代码。这些 tiled copy 和 tiled mma 迭代通常**全静态、会被完全展开**。

## CUTLASS GEMM 组件

CUTLASS 用以下组件表达上述循环嵌套，它们按数据类型、layout、数学指令做特化：

| API 层级 | API 类 / 函数名 |
| --- | --- |
| Device | `cutlass::gemm::device::GemmUniversalAdapter` |
| Kernel | `cutlass::gemm::kernel::GemmUniversal` |
| Collective | `cutlass::gemm::collective::CollectiveMma`、`cutlass::epilogue::collective::DefaultEpilogue`、`cutlass::epilogue::collective::Epilogue` |
| Tiled (MMA/Copy) | `cute::TiledMma`、`cute::TiledCopy`、`cute::gemm()`、`cute::copy()` |
| Atom | `cute::Mma_Atom`、`cute::Copy_Atom` |

CUTLASS 3.0 组装 kernel 的方式：先在 **kernel 层**把 collective mainloop 和 collective epilogue 组合到一起，再用 **host 侧 adapter** 包起来，形成指向该 kernel 的 GEMM 句柄。

用户组装 kernel 的顺序（也是下面各节的顺序）：

1. 组装所需的 collective mainloop 和 epilogue；
2. 把它们组合成一个 kernel 类型；
3. 用 device 层 adapter 包装该 kernel。

这个顺序也体现在 [example 48](examples/48_hopper_warp_specialized_gemm) 里：

```c++
// 第 1 步：生成所需的 collective 层 mainloop 特化
using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA, AlignmentA,
    ElementB, LayoutB, AlignmentB,
    ElementAccumulator,
    TilesShape, ClusterShape,
    cutlass::gemm::collective::StageCountAuto,
    cutlass::gemm::collective::KernelScheduleAuto
  >::CollectiveOp;

// 第 2 步：指定 collective 层 epilogue 类型
using CollectiveEpilogue = cutlass::epilogue::collective::DefaultEpilogue<
    ElementC,
    cutlass::gemm::TagToStrideC_t<LayoutC>,
    cutlass::gemm::TagToStrideC_t<LayoutC>,
    cutlass::epilogue::thread::LinearCombination<ElementC, 1, ElementAccumulator, ElementAccumulator>>;

// 第 3 步：在 kernel 层把 mainloop 和 epilogue 组合到一起
using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    cute::Shape<int,int,int,int>, // ProblemShape [M,N,K,L]
    CollectiveMainloop,
    CollectiveEpilogue
>;

// 第 4 步：用 device adapter 包装 kernel::GemmUniversal，得到 host 侧句柄
using GemmHandle = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
```

文末还会简略讲 CuTe 的 tiled mma/copy 和 atom 层，再把读者引向 CuTe 专属文档。

---

### Collective API（集体层）

一个 **Collective** 是"**MMA atom 和 copy atom 被平铺到的最大线程集合**"。也就是 grid 中能利用硬件特性（加速通信与同步）协作的最大线程数。这些硬件特性包括：

- **异步数组拷贝**（如 global→shared）；
- 针对驻留 smem 的小 tile 的 **MMA 指令**；
- 对 cluster / thread block / warp 的**同步操作**；
- 确保异步操作间数据依赖被满足的**硬件加速（如 barrier）**。

Collective 用 `TiledMma` 和 `TiledCopy` API（见下文）来访问对 tile 的拷贝和 MMA 操作。

一个 Collective 里不同的并行单元（线程/warp/thread block）可能有**不同角色**。例如在"**warp 专精(warp-specialized)**"算法里，一些 warp 负责拷贝数据，另一些负责计算。但这些并行单元仍需**共享数据、协调访问**。比如 warp 专精算法里，把输入 tile 拷进 smem 的 **producer warp**，需要通知 **consumer MMA warp** 它们的 MMA 输入已就绪。

与之对比，`kernel::` 层 API 调度的是 grid 中**互相独立**的 tile 上的 collective。

Collective API **同时包含** MMA 的 "mainloop" 和 epilogue。它是 mainloop fusion、epilogue fusion 等优化的**组合点**，负责实现上面伪代码里的 `k_tile` 循环。

### Collective Mainloops（集体主循环）

`cutlass::gemm::collective::CollectiveMma` 类是 collective MMA mainloop 的主接口。"Mainloop" 指对 tile 的"主循环"——伪代码里的 "cluster tile k" 循环。算法需要做的任何对多个 tile 的循环都发生在这里。声明在 [collective_mma.hpp](include/cutlass/gemm/collective/collective_mma.hpp)：

```c++
namespace cutlass::gemm::collective {
template <
  class DispatchPolicy,
  class TileShape,
  class ElementA, class StrideA,
  class ElementB, class StrideB,
  class TiledMma,
  class GmemTiledCopyA, class SmemLayoutAtomA, class SmemCopyAtomA, class TransformA,
  class GmemTiledCopyB, class SmemLayoutAtomB, class SmemCopyAtomB, class TransformB
>
struct CollectiveMma {
  static_assert(sizeof(ElementA) == 0, "Could not find a mainloop specialization.");
};
}
```

- **`DispatchPolicy`**：collective 最重要的类型，详见下面"Collective Dispatch 策略"。
- **`StrideA` / `StrideB`**：`cute::Stride` 实例，表示 A、B 的 global memory layout。要求是 **rank-3**，对应 `[outer, inner, batch]` 三个 mode。每个 rank 都可以是多模态层次化 stride（实现张量缩并 tensor contraction 时会用到）。
- **`TiledMma`**：`cute::TiledMma` 实例。
- **`GmemTiledCopyA` / `GmemTiledCopyB`**：`cute::TiledCopy` 实例（详见下文 Tiled MMA/Copy）。
- **`SmemLayoutAtomA` / `SmemLayoutAtomB`**：`cute::Layout` 实例，表示**会被平铺到整个 collective 的 smem 上的最小 layout**。这个 layout **不含** pipeline 维，因此应是 **rank-2** layout，shape 为 `[outer, inner]`。
- **`SmemCopyAtomA` / `SmemCopyAtomB`**：用于把数据从 smem 搬进寄存器的 `Copy_Atom`。

注意：**CUTLASS 3.0 mainloop 不接受专门的累加器元素类型**。累加器类型从 `typename TiledMma::ValTypeC` 获得。还要注意，顶层 API 的 `ElementA`/`ElementB` 可以**不同于**面向 MMA 的 `TiledMma::ValTypeA`/`ValTypeB`——这允许 TMA 或用户提供的 transform 操作做**类型转换**。

### Collective Dispatch 策略

`CollectiveMma` 的实现**不是泛型的**，必须针对每种算法和 GPU 架构做特化。用户通过挑选匹配某个特化的模板参数来分发。CUTLASS 3.0 采用 **基于 tag 的 dispatch 策略类型**来特化 mainloop 实现并给它们加调优旋钮。

下面是用于分发到 Hopper TMA warp 专精 mainloop 实现的一个 dispatch 策略示例：

```c++
// smem 中 n-buffer（Hopper TMA），
// 与 Hopper GMMA 和 TMA 流水线化，
// warp 专精动态调度
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecializedCooperative
>
struct MainloopSm90TmaGmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
};
```

`Stages_` 让用户自由调整**流水线级数**；`ClusterShape_` 让用户参数化 **TMA multicast 发生其上的 thread block cluster 的 shape**。

collective dispatch 策略也是把各种 **kernel schedule 与任意 mainloop 自由组合**的主切入点。每个 mainloop 策略要么**规定**它需要配合的 `Schedule`，要么暴露一个模板 API 让用户从下列 schedule 子集里挑：

```c++
struct KernelCpAsyncWarpSpecialized { };
struct KernelCpAsyncWarpSpecializedPingpong { };
struct KernelCpAsyncWarpSpecializedCooperative { };
struct KernelTma { };
struct KernelTmaWarpSpecialized { };
struct KernelTmaWarpSpecializedPingpong { };
struct KernelTmaWarpSpecializedCooperative { };
```

- **一个 kernel schedule 能支持多个 mainloop 实现**。例如 `KernelMultistage` 能与多种 mainloop（`MainloopSm70TwoStage`、`MainloopSm80CpAsyncUnpredicated` 等）组合。
- **一个 mainloop 能与多个 kernel schedule 组合**。例如 `MainloopSm90TmaGmmaWarpSpecialized` 能与 `KernelTmaWarpSpecialized` / `...Pingpong` / `...Cooperative` 任一组合。

如设计文档所述，对核心词汇类型采用 tag dispatch 策略，让我们能为"概念上属于同一类"的所有操作维持**单一类型名**。好处：

- mainloop 与多 kernel（或反之）组合时**避免代码重复**；
- **更容易写泛型代码**，主类型名 `CollectiveMma` 在所有实现中不变；
- **提供清晰、单一的扩展点**，用户可基于自己的 dispatch 策略插入定制 mainloop。

### `CollectiveMma` 的 Collective Builder

主 `CollectiveMma` 是**专家级接口**，对 collective 微内核的所有属性给予完全控制。但用户往往只想要个**现成的、用简单配置参数化的** GEMM mainloop。CUTLASS 3.0 为此提供 [`CollectiveBuilder`](include/cutlass/gemm/collective/collective_builder.hpp)：

```c++
namespace cutlass::gemm::collective {
template <
  class ArchTag, class OpClass,
  class ElementA, class GmemLayoutA, int AlignmentA,
  class ElementB, class GmemLayoutB, int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK, class ClusterShape_MNK,
  class StageCountType, class KernelScheduleType,
  class Enable = void
>
struct CollectiveBuilder {
  static_assert(sizeof(ElementA) == 0, "Could not build a collective for given parameters.");
};
}
```

`CollectiveBuilder` 接收与 2.x 等价的输入模板参数，尝试从给定参数**构建性能最佳的 `CollectiveMma`**：

- **`ArchTag`**：`cutlass::arch::Sm*` 之一。
- **`OpClass`**：`cutlass::arch::OpClass*` 之一。
- **`ElementA`/`ElementB`**：A、B 的逻辑值类型。
- **`ElementAccumulator`**：指令中用的累加器类型。
- **`GmemLayoutA`/`GmemLayoutB`**：2.x layout tag，`layout::RowMajor` 或 `layout::ColumnMajor`。
- **`AlignmentA`/`AlignmentB`**：A、B 在 global memory 的对齐（以元素个数计）。
- **`TileShape_MNK`**：rank-3 `cute::Shape`，表示 M×N×K 的 collective tile shape。
- **`ClusterShape_MNK`**：rank-3 `cute::Shape`，表示 M×N×K 的 thread block cluster tile shape。
- **`StageCountType`**：`collective::StageCountAuto` 或 `collective::StageCount<N>` 实例。
- **`KernelScheduleType`**：`collective::KernelScheduleAuto`，或上面 dispatch 策略节里的某个具体 kernel schedule tag。

**`StageCountAuto`** 让 builder 计算单个 stage 在 smem 中的大小，并按"1 个 threadblock / SM occupancy"最大化 smem 使用。

**`KernelScheduleAuto`** 让 builder 为给定参数挑最佳可用 kernel schedule（也允许用户用具体 schedule 覆盖）。

注意：collective builder 仍处 **beta**，其功能未覆盖专家级 `CollectiveMma` API 的完整设计空间。未来版本会扩展所支持的 mainloop 类型；但 3.0 中 **builder API 仅支持 SM90 tensorop kernel**。builder API 未来可能随用户反馈改变。

如果 builder 能为给定参数提供 collective mainloop 类型，它会以 `CollectiveOp` 别名暴露。便捷参数化用法见 [example 49](examples/49_hopper_gemm_with_collective_builder)。

### Epilogue（尾声）

collective epilogue 实现涉及输出矩阵的**逐元素操作**。用户可提供自定义 epilogue，或用标准 epilogue。它们在 [include/cutlass/epilogue/collective/](include/cutlass/epilogue/collective/) 下，含 `DefaultEpilogue`、`Epilogue` 等类。

CUTLASS 提供的 collective epilogue **不**放在 `include/cutlass/gemm` 下、也不在 `cutlass::gemm` 命名空间，因为它们可用于 GEMM 以外的计算。

---

## Kernel API（内核层）

kernel 是 "grid 中所有 cluster 的集合"。kernel 层 schedule 有四大职责：

- **排序** kernel 内 collective 的执行，做必要的同步；
- 把 warp 专精 schedule 的线程**编排进各自的角色**；
- 执行必要的 **grid swizzling** 逻辑；
- 在调用 collective 前，用 thread block cluster value tile **平铺输入张量**。

Kernel API 是一个 grid（可能组成 cluster、也可能不）的入口，是融合背靠背 GEMM、epilogue 及其他操作的组合点。

CUTLASS 3.0 kernel 入口类是 `cutlass::gemm::kernel::GemmUniversal`（[gemm_universal.hpp](include/cutlass/gemm/kernel/gemm_universal.hpp)）。它是一个**无状态(stateless)、通用(universal)**的 device kernel，把 GEMM 实现为两部分的组合：collective mainloop + collective epilogue。

```cpp
namespace cutlass::gemm::kernel {
/*
 * 无状态通用 device GEMM kernel 类型，把 GEMM 视为
 * collective mainloop 和 collective epilogue 的组合。
 *
 * 根据第一个类型是否为 cute::tuple<> 来同时支持 2.x 和 3.x API。
 * 2.x: cutlass/gemm/kernel/gemm_universal.h
 * 3.x: cutlass/gemm/kernel/gemm_*.hpp
 *
 * 下面声明中 'Or' 前的名字指 3.x API 的类型参数顺序，
 * 'Or' 后的名字指 2.x 的顺序。没有两个名字的模板参数仅属于 3.x。
**/
template <
  class ProblemShapeOrThreadblockMma_,            // (m,n,k) 或 (m,n,k,l)
  class CollectiveMainloopOrEpilogue_,
  class CollectiveEpilogueOrThreadblockSwizzle_,
  class TileScheduler_ = void,
  class Enable = void
>
class GemmUniversal;
}
```

- **无状态(Stateless)**：调用方（如上面的 Device API）管理 kernel 的状态；kernel 只接收输入输出参数(`Params`)。
- **通用(Universal)**：`GemmUniversal` 对 3.0 和 2.x 接口、广泛的 kernel schedule 都适用。**若第一个模板参数是 `cute::Shape`，则假定其余参数实现 3.0 API；否则假定 2.x**。从 3.0 起，problem shape 被**提升为 kernel 的顶层模板 API**，支持全静态 GEMM 实例化（用户在编译期就知道部分/全部 problem shape，以榨取更多性能）。

*collective mainloop* 在本地 tile 上做 MMA；*collective epilogue* 处理 MMA 之后的操作（如 `C := beta*C + alpha*A*B` 里的 `beta*C` 部分）。

3.0 API 的 `kernel::GemmUniversal` 特化散布在 [include/cutlass/gemm/kernel/](include/cutlass/gemm/kernel/) 下的各种 `gemm_*.hpp`；2.x 特化在 `gemm_universal.h`。

CUTLASS 3.x 实现了 `kernel::GemmUniversal` 的多种体现，每种 kernel 层 schedule 针对一种 GEMM 调度算法和 GPU 架构特化，文件名形如 `{arch_tag}*.hpp`。**分发到哪个特化由 dispatch 策略的 `Schedule` 类型决定**。例如：

- `sm90_gemm_tma_warpspecialized_pingpong.hpp`：Hopper 上 warp 专精 mainloop + **persistent 调度**算法的特化；
- `sm90_gemm_tma_warpspecialized.hpp`：Hopper 上 warp 专精但**非 persistent** 算法的特化。

为了在支持的 kernel schedule 和 mainloop dispatch 策略间组合而**不必重复 collective mainloop 实现**，GEMM kernel 层 schedule 能与任何"在策略里把对应 kernel schedule 指定为 `Schedule` 类型"的 mainloop 组合：

```c++
// SM90 KernelMultistage kernel 的特化逻辑示例，
// 使它能与 MainloopSm80CpAsync、MainloopSm70TwoStage 等多种 mainloop 组合。
template <class ProblemShape_, class CollectiveMainloop_, class CollectiveEpilogue_, class TileScheduler_>
class GemmUniversal<
  ProblemShape_, CollectiveMainloop_, CollectiveEpilogue_, TileScheduler_,
  std::enable_if_t<std::is_base_of_v<KernelMultistage, typename CollectiveMainloop_::DispatchPolicy::Schedule>>>
```

---

## Device API（设备层）

Device API 是一个**通用、与 kernel 无关**的 host 接口，用于 kernel launch 和管理可复用 host 侧参数的生命周期。这是用户的 host 侧 `.cu` 代码调用 CUTLASS 单 GPU GEMM kernel 的方式，作用与 cuBLAS 相同、行为类似。

入口类是 `cutlass::gemm::device::GemmUniversalAdapter`（[gemm_universal_adapter.h](include/cutlass/gemm/device/gemm_universal_adapter.h)）。它是一个**有状态(stateful)、可复用(reusable)**的句柄，以 `cutlass::gemm::kernel` 类型参数化：

```c++
/*!
  GemmUniversalAdapter 是围绕 cutlass::gemm::kernel::* 类型的 kernel
  构建的有状态、可复用 GEMM 句柄。

  它管理底层 kernel::Params 结构体的生命周期，暴露从 host 侧 arguments
  创建它的 API。对高级用户，3.x 暴露了绕过有状态方法 / args->params
  下降过程的新静态方法。

  它支持实现 2.x 和 3.0 API 的 kernel 类型，但这是通过对两种 kernel API
  类型分别特化 GemmUniversalAdapter 的实现做到的，因此两种特化下行为可能不同。
*/
template <class GemmKernel_, class Enable = void>
class GemmUniversalAdapter;
```

- **有状态(Stateful)**：句柄实例含 kernel 运行所需的状态。用户必须**先初始化**句柄，再用初始化后的实例运行 kernel。有状态也意味着句柄能管理 kernel `Params`（kernel 自身参数）的生命周期。`GemmUniversalAdapter` 的一个重要职责是把用户的 `Arguments`（用户视角的 kernel 参数）**映射成** kernel 实际看到的 `Params`。高级用户可用 3.0 暴露的新静态方法绕过有状态方法、或不经中间 `Arguments` 直达 `Params`。
- **可复用(Reusable)**：句柄实例可用**不同 arguments**（如不同矩阵）多次调用 kernel。复用句柄可能比每次新建更高效。
- **以 kernel 类型参数化**：`GemmUniversalAdapter` 的行为取决于 GEMM kernel 类型。模板参数 `GemmKernel` 的合法实参：
  - `cutlass::gemm::kernel::GemmUniversal`（实现 3.x API kernel）；
  - `cutlass::gemm::kernel::GemmUniversal`（实现 2.x API kernel）；
  - 任何此前能与 `device::GemmUniversalAdapter` 组合的合法 2.x kernel 层 GEMM。

`GemmUniversalAdapter` 对 3.0 和 2.x kernel 呈现**单一 host 侧接口**，靠对两种 API 分别特化实现。元函数 `cutlass::gemm::detail::IsCutlass3GemmKernel` 用来区分 2.x 和 3.x kernel。

`GemmUniversalAdapter` 设置并启动 kernel，必要时用 **CUDA 扩展 launch API** 支持 thread block cluster。注意它**不指定 grid shape**——**grid shape 和其他 kernel 专属 launch 参数由 kernel 自己控制**。这使所有 3.0 kernel 能用同一套 launch 代码，把 kernel launch 与实际 kernel 解耦。

---

## Tiled MMA 和 Copy

Tiled MMA / Copy 是把 MMA atom / Copy atom **在线程和数据上平铺**，并可对结果平铺施加排列(permutation)。这一层最类比于 2.x 中 MMA 指令的 **warp 级平铺**，但它从"所有参与操作的线程"的视角看待平铺，并把概念推广到 copy 操作。其目的是用大量硬件加速的数学/数据搬运操作（各有其线程与数据的单元 layout）**构建可组合的 GPU 微内核**。Tiled MMA/Copy 类型把这些五花八门的硬件加速 CuTe Atom，呈现为**单一一致的 API**。

平铺后的操作表现得像**单个** MMA 或 copy 操作，用户在伪代码"内层"循环用 `cute::gemm()` 或 `cute::copy()` 调用它。

之所以叫 "tiled"（平铺），是因为它用 CuTe 提供的 Atom 构建更大的操作——就像把一块块瓷砖拼起来组成马赛克中可复用的部件。例如 CuTe 可能提供一个能在单个 warp 上、对固定 M/N/K 调用的 MMA Atom；CUTLASS 再用 `make_tiled_mma` 把它变成在整个 thread block 上、对更大 M/N/K 工作的操作。

## Atom API（原子层）

一个 **"Atom"** 是必须参与某个硬件加速数学/copy 操作执行的**最小线程与数据集合**。

Atom 的"原子性(不可分)"，**不是** `atomicAdd` 那种并发内存操作意义上的（那是"时间/因果上不可分"），而是**"空间上"不可分**——必须**一起**参与操作的值的数量、以及并行 worker 组。

Atom 用 CuTe Layout 表达其输入输出数组所需的维度和 stride，通常编译期固定。

Atom API 包装对实际硬件指令（加速 MMA 或 copy）的调用。用户可要求 GPU 架构专属实现，或只挑通用实现、依赖已启用的 GPU 架构。

更多关于 Atom 的信息见 CuTe 教程：
- [algorithms](../../../media/docs/cpp/cute/04_algorithms.md)（如 `gemm`、`copy`）
- [MMA Atoms](../../../media/docs/cpp/cute/0t_mma_atom.md)
- [GEMM 示例](../../../media/docs/cpp/cute/0x_gemm_tutorial.md)
