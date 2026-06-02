# CUTLASS 3.0 设计（cutlass_3x_design.md 完整翻译）

> 译自 `media/docs/cpp/cutlass_3x_design.md`。末尾 license 样板略。

CUTLASS 3.0 是对 CUTLASS 2.x 抽象的一次重大升级，目标是让 GEMM 层级各层都**更易用、更可组合**，同时仍在硬件上达到峰值性能。

## CUTLASS 3.0 的设计目标

（不分先后）

- 用 **CuTe layout 和 layout 代数**简化 GEMM 各层级中数据布局与线程布局的表达与操作。
- **减少具名类型(named types)的数量**，改善代码可读性、降低学习曲线。
- **默认功能正确**；做不到时给出**可操作的静态断言**(static assert)。
- 性能调优与自定义内核扩展有**单一、清晰的切入点**。
- 用 Tensor Core、TMA、thread block cluster 等特性，在 **NVIDIA Hopper** GPU 上提供出色性能。

## 一套全新的概念性 GEMM 层级

CUTLASS 2.x 把 GEMM 的各个活动部件，分解到一个**紧贴 GPU 架构组织方式**的层级里（详见 2.x GEMM API 文档）。但这种设计有时导致**耦合过紧**，难以扩展到不符合同一架构层级的新 GPU 特性。例如：

- Hopper 的 **warpgroup 级指令**(wgmma)，在 2.x 里**塞不进任何 warp 层或 thread 层**的 GEMM 概念。
- 即便是 Volta 的 tensor core，那种以 quad-pair 粒度原子存在的指令，使用前也得先在 warp 级 tile 一遍。

这暴露了那套抽象能力的**脆弱性**。

CUTLASS 3.0 **把接口层从硬件解耦**，转而围绕 **GEMM 算法本身的自然结构**(不绑定任何特定 GPU 世代)来组织。这让 CUTLASS 代码：

- 对 GPU 架构演进**更稳健**，
- 更不易**泄漏实现细节**，
- 无论架构具体细节如何，都给用户**一致的硬件加速接口**。

新的概念性 GEMM 层级详见 `gemm_api_3x.md`（含核心概念与类型的代码示例）。

## 采用 CuTe 的 Layout 和 Tensor

CUTLASS 3.0 引入新的核心库 **CuTe**，用来描述和操作"线程的张量"和"数据的张量"。CuTe 是一组 C++ CUDA 模板抽象，用于定义和操作**线程与数据的层次化多维 layout**。它提供 `Layout` 和 `Tensor` 对象，把数据的**类型、shape、内存空间、layout** 紧凑打包，同时替用户完成复杂的索引计算。

CUTLASS 3.0 在整个 GEMM 层级的模板中**全面采用 CuTe**，大幅简化设计、提升可组合性与可读性。

> 配图含义：CuTe 把众多具名 iterator 类型，归约成**单一的词汇类型 `Layout`**。

用各种逻辑线程/数据层次去编程大规模并行系统并不简单。CuTe 的价值：

- `cute::Layout` 始终维持坐标的**逻辑一致性**，让我们能在编译期对所有静态内层循环检查前置/后置条件。
- **显式的线程→数据映射**，让用户和内核作者能从源码的**单一位置**审视和推理操作。
- Layout 提供**单一调优点**——大多数优化都能通过精心选择线程/数据 layout 完成。
- **形式化代数**让"线程→数据映射"的操作和推理在源码中显式化。
- 单一词汇类型 `cute::Layout` **吞并了 2.x 中所有 iterator 和 layout**。2.x 用了大量定制 thread map、iterator、数据 layout；iterator 本质是 1-D 的，而 GPU 层级里遇到的大多数 layout 本质是 n-D 的。

## 减少具名类型与 iterator 概念的数量

2.x 的设计偏好为每种架构相关的线程/数据 layout 引入**定制的具名类型**。例如 `gemm::threadblock` 命名空间里有 `MmaMultistage`、`MmaPlanarComplexMultistage`、`MmaPipelined` 等等——尽管它们都是在为 GEMM 提供 mainloop。为了在泛型代码里统一拼写这些类型，2.x 通过 `default_x_configuration.h` 提供别名；但这些别名让代码**更难读**，因为用户得在脑子里做类型替换才能理解。

CUTLASS 3.0 大幅减少具名类型，靠：

- 用 `cute::Tensor` **替换所有内存域的 iterator 概念**；
- mainloop 和 epilogue 的实现**用 tag-dispatch 策略分发**，而不是命名新类型；
- kernel 层的 schedule 也**用 tag-dispatch 策略分发**，而不是命名新类型。

好处：

- **更容易写泛型代码**——主类型名共享同一词法，不必通过配置提供器走别名。
- **拉平学习曲线**——库只暴露少数几个具名类型，大幅降低所需的心智上下文。
- **提供清晰、单一的扩展点**——用户通过 dispatch 策略插入自己的定制。

## 默认正确，性能靠清晰、独立的调优点

2.x 把线程 layout 维护为**隐式的索引数学**，作为 1D iterator 的一部分实现。这意味着"线程→数据 layout 映射"**隐含在 C++ 代码的命令式结构里**，没有可用来操作这些映射的形式化代数。每个 iterator 都得**重新实现**自己的索引和映射逻辑。这让人难以理解现有 iterator 是怎么做映射的，更难为 GEMM 核心内层循环实现自定义 layout 函数。

CUTLASS 3.0 用**单一 layout 类型**替换了 2.x 所有 iterator 概念（线程张量和数据张量都用它）。然后在 GEMM 层级的每一层都用 **CuTe 的形式化 layout 代数**来操作两者之间的映射。CuTe layout 始终维持逻辑一致性；对于全静态 layout（如核心展开内层循环），还提供**编译期检查**——一旦一致性被破坏就编译失败。

如此一来，CuTe 把"线程→数据 layout 映射"**具象化(reify)**，让人更容易写出"构造即正确(correct by construction)"的代码。**只要它能编译，多半就是对的。**
