# Week 6 — TMA (Tensor Memory Accelerator)

预计 ~15h
> **硬件**：🟢 5060 Ti 完整可跑（SM120 原生支持 TMA，跟 SM90 共享 `CUTE_ARCH_TMA_SM120_ENABLED` 代码路径）

> **认知锚点**（对照 [`sm90_hopper_overview.md`](../sm90_hopper_overview.md)）：
> TMA = **分化定律 · 一.1**（从 LSU 分化出的独立搬运引擎）+ **双主轴交汇点**（一条指令搬一个 tile = Scale Up；异步执行 = Async）。
> 配套的 **B1 mbarrier transaction count**（等"字节到齐"而非"线程到齐"）和 **B3 Proxy Fence**（`fence.proxy.async`，保证 TMA 写完后跨 proxy 可见）也在本周。
> 对照 [`sm120_fake_blackwell_overview.md`](../sm120_fake_blackwell_overview.md)：TMA 是消费卡**保留**的（已成通用底座，卷积/attention/推理/图形都吃）—— 这就是为什么本周 5060 Ti 完全本地可跑，而 W5/W8 不行。

## 目标
- 能在 host 构造 TMA descriptor，理解 5D tensor 的 box / global stride / element stride
- 能在 kernel 里用 `cp.async.bulk.tensor` 做 G→S 异步搬运
- 跑通 `wgmma_tma_sm90.cu` 并改一改

## 读（**由浅入深**：概念 → PTX → 同步原语 → descriptor 构造 → 实战）
1. `media/docs/cpp/cute/0z_tma_tensors.md` — **先读这个**：TMA Tensor 概念文档，box / global stride / element stride 的直觉（最浅，建立全貌）
2. `include/cute/arch/copy_sm90_tma.hpp` — `cp.async.bulk.tensor` 的 PTX wrapper（看指令长什么样，1496 行但只挑 LOAD 几个 struct）
3. `include/cute/arch/copy_sm90_desc.hpp` — `initialize_barrier` / `set_barrier_transaction_bytes` / `wait_barrier`（mbarrier 的 transaction 机制，对应 overview B1；只有这几个函数，很短）
4. `include/cute/atom/copy_traits_sm90_tma.hpp` — `make_tma_copy` descriptor 构造（**最深**：1609 行，是 TMA 的核心魔法，看懂 box/stride 怎么编码进 128B TensorMap）
5. `examples/cute/tutorial/hopper/wgmma_tma_sm90.cu` — WGMMA + TMA 组合（整合，看上面几块怎么拼起来）
- **Proxy Fence**（overview B3）：搜 `fence.proxy.async` 在 cutlass 里的用法 —— TMA（async proxy）写 smem 后，普通指令（generic proxy）要读，必须 fence。这是真实 pipeline 的 bug 高发区，先建立意识，W7 写 pipeline 时会用到。

## 写
- `exercises/ex13_tma_g2s.cu` — 从 host 构造 1D / 2D / 3D 三种 TMA descriptor，每种发一次 G→S 搬运，验证内容
- `exercises/ex14_tma_multicast.cu` — 用 `cp.async.bulk.tensor.multicast` 让 cluster 内多个 CTA 共享一次加载

## 跑
```bash
make study_stage2_w06_ex13_tma_g2s -j && ./study_stage2_w06_ex13_tma_g2s
make study_stage2_w06_ex14_tma_multicast -j && ./study_stage2_w06_ex14_tma_multicast
```

ncu 验证：
- `dram__bytes_read.sum` 应为 `M*N*sizeof(T)`，而不是更多
- `l1tex__t_bytes.sum` 在 multicast 模式下应明显小于 N×（单 CTA 数据量）

## 自检
1. TMA descriptor 为什么要在 host 构造？如果在 kernel 里构造会怎样？
2. TMA 绕过 L1/L2 直接 G→S，对 L2 cache 还有用吗？什么时候依然命中 L2？
3. 128B 对齐要求是对什么对齐？元素地址、box 起点还是 global tensor 起点？
4. `cp.async.bulk.commit_group` 之后等待用什么指令？跟 SM80 的 `cp.async.wait_group` 是同一条吗？
5. multicast 适合什么模式（A 还是 B）？为什么大 K 时 multicast 收益大？
