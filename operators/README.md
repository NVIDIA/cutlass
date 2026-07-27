CUTLASS Operator API
====================

> [!NOTE]
> CUTLASS Operator API is currently in beta. All interfaces, names,
> and paths are subject to change.

CUTLASS Operator API is a Python interface for integrating kernels written in CUTLASS
Python DSLs (like [CuTe DSL](https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/overview.html)) into your code.

While DSLs focus on kernel authoring, CUTLASS Operator API focuses on ease of
managing and integrating those kernels into libraries that use CUTLASS.

It views kernels as end-to-end "Operators" that execute an operation (like a GEMM), and provides two things:

1. a **kernel-agnostic interface** for finding operators that support an
   operation/operands, inspecting their properties, and executing them — the same
   way regardless of which kernel each operator wraps.
2. a **registry** of officially maintained CUTLASS kernels exposed through that interface.


Example
-------

```python
import cutlass.operators as ops
import torch

A, B, out = (torch.randn(128, 128, device="cuda", dtype=torch.float16) for _ in range(3))

# Arguments express an operation, and the operands to it
args = ops.GemmArguments(A, B, out, accumulator_type=torch.float32)

# Find operators that support our provided arguments, and can run on SM100.
# Returns a list of ``Operator``s that wrap ready-to-compile CuTe DSL kernels.
operators = ops.get_operators(args, target_sm="100")

# JIT compile and execute one of the returned operators using our arguments
operators[0].run(args)
```

Why use it?
===========

Any software that uses kernels requires finding kernels that do what you want, wiring up glue code to call them,
and maintaining the integration as kernels evolve.
Without an integration layer, these tasks are manual, error-prone, and repeated for every kernel.
CUTLASS Operator API eases each of these tasks — as kernels rapidly evolve, you don't have
to choose between integration churn and adoption inertia.

**"Which kernel does what I want?"**

Without Operator API, finding the right kernel means reading kernel source code and manually
deducing support — which dtypes, layouts, tile sizes, arch features, etc. each kernel supports. Operator API
provides a simple ``get_operators(args)``: express the operation you want to run, and get all the
operators that support it. Each operator also exposes uniform metadata describing
its constraints and design features for more advanced inspection, instead of requiring you to deduce
from source code.

**"How do I get newer, faster, or fixed kernels?"**

Adopting kernels directly carries a maintenance burden to mirror bug fixes/optimizations into local copies and
monitor release notes for new relevant kernels. With Operator API, you **integrate once,
not perpetually**. New kernels, fixes, and optimizations land in the registry on each release, and you get
them automatically without changing your integration code — just upgrade ``nvidia-cutlass-operators``.

**"How do I call this kernel with my torch tensors?"**

Different kernels have different usage conventions — direct usage requires kernel-specific
glue code to convert your framework tensors to the kernel's expected inputs, set performance
options, and run preparation steps. Operator API wraps every kernel with a consistent interface: pass PyTorch (or any
DLPack-compatible) tensors directly into ``GemmArguments`` and call ``operator.run(args)``. That lets you swap operators without touching your call site.

It also supports:

- **Custom epilogue fusions with ease** — pass a plain Python function; Operator API lowers it onto
  CuTe DSL's Epilogue Fusion Configuration (EFC) framework and fuses it into supported kernels.
- **Bring-your-own-kernel** — register your own CuTe DSL kernels so you can call them through the same
  interfaces as pre-bundled ones from CUTLASS, with no separate integration path for in-house kernels.
- **Negligible runtime overhead** on top of invoking the underlying kernel directly.


How to use it?
==============

Installation
------------

To use with PyTorch, install the ``nvidia-cutlass-operators[torch]`` package:

```bash
pip install nvidia-cutlass-operators[torch]
```

Alternatively, choose which dependencies to install:

```bash
# Install only nvidia-cutlass-operators core
pip install nvidia-cutlass-operators

# Install all dependencies to develop, run tests, etc.
pip install nvidia-cutlass-operators[dev]
```

Next steps
----------

- [Basic GEMM tutorial](examples/000_gemm.ipynb) — a guided tour of the core interface concepts to run a minimal GEMM.
- More guided notebook tutorials in [examples/](examples/).
- [Full API reference](https://docs.nvidia.com/cutlass/latest/media/docs/operators/tutorials/index.html) for ``cutlass.operators``.


Supported and Upcoming Features
===============================

CUTLASS Operator API will support a wide range of functionality, configurations, and optimizations, all robustly tested.

**Current support:**

- Kernel coverage

  - Dense GEMMs (F32, F16, BF16, INT8) for Blackwell, Hopper, Ampere
    - Preferred and fallback cluster shapes
    - Static and dynamic scheduling
  - Block-scaled GEMMs (NVFP4, MXFP4, MXFP8, mixed input precision) for Blackwell
  - Grouped GEMM (Contiguous offset) for Blackwell
  - Low-latency TGV GEMM for Blackwell

- Custom epilogue fusions (e.g. activations, elementwise ops, aux load/store)
- CUDA Graph support
- Native support for PyTorch and other DLPack tensors
- Bring-your-own-kernel


**Upcoming support:**

- Additional GEMM kernel coverage: Sparsity, performance optimizations, grouped GEMM variants, and more
- Ahead-of-time compilation
- JAX Graph support
- nvMatmulHeuristics support

Community & Feedback
====================

We welcome contributions and feedback from the developer community. You can:

- File bug reports, feature requests, documentation gaps, and upvote roadmap items on the [CUTLASS GitHub Issues page](https://github.com/NVIDIA/cutlass/issues).
- Contribute examples, tutorials, or improvements via pull request to the [CUTLASS repository](https://github.com/NVIDIA/cutlass).
- Ask questions and share ideas in the [#cutlass channel](https://discord.com/channels/1019361803752456192/1150868614921064590) on [NVIDIA Developer Discord](https://discord.gg/nvidiadeveloper).
