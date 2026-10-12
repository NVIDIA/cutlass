.. _overview:

Overview
===========================

CUTLASS Python is the Python kernel-authoring stack in CUTLASS 4.x. It provides
the CUTLASS DSL package and documentation for writing high-performance CUDA
kernels with Python syntax while retaining explicit control over the GPU memory,
thread, and data hierarchy.



CUTLASS Python is organized as layered kernel-authoring APIs. Basic data types
provide typed building blocks. Above those, CuTe DSL provides a Python
programming model aligned with CuTe C++ concepts such as layouts, tensors, copy
atoms, MMA atoms, and tiled operations, while pipeline APIs compose asynchronous
data movement and work orchestration. These layers compile Python kernel code
through the CUTLASS Python compiler stack and NVIDIA CUDA toolchain to
JIT-compile CUDA kernels.



The CUTLASS Python documentation is organized around:

- :doc:`quick_start` for installation and environment setup.
- :doc:`cute_dsl` for the DSL programming model.
- :doc:`guides` for framework integration, debugging, profiling, autotuning,
  ahead-of-time compilation, and MMA programming guides.


- :doc:`apis` for Basic Data Types, CUDA (Jittable), CuTe, Pipeline, and
  Utilities.


- :doc:`limitations`, :doc:`deprecation`, and :doc:`faqs` for support boundaries,
  compatibility policy, and common questions.

Why CUTLASS Python?
============================

While CUTLASS offers exceptional performance through its C++ template abstractions, the complexity 
can present challenges for many developers. CUTLASS Python addresses this by:

- **Simplifying metaprogramming**: express compile-time configuration with Python
  instead of deeply nested C++ templates.
- **Accelerating iteration**: prototype kernels with familiar Python syntax and
  JIT compilation.
- **Lowering barriers**: learn GPU programming concepts through APIs that mirror
  CuTe C++ abstractions.
- **Maintaining performance focus**: generated code uses CUDA hardware
  primitives exposed through CUTLASS and CuTe APIs.

Students can learn GPU programming concepts without the complexity of C++ templates. 
Researchers and performance engineers can rapidly explore algorithms, prototype, and tune 
kernels before moving to production implementations.

Key Concepts and Approach
================================

CUTLASS Python lets developers describe CUDA kernels with Python syntax while
retaining explicit control over data types, memory hierarchy, tiling, and work
decomposition. Kernel code is compiled just-in-time through the CUTLASS Python
compiler stack and NVIDIA CUDA toolchain.

Core Abstractions
-----------------------------------

- **Basic data types** – Provide typed numeric, pointer, vector, and array
  building blocks used across the DSL.
- **CuTe** – Provides composable abstractions for tensor layout, data movement,
  and compute.

  - **Tensor** – Basic CuTe data object that combines a pointer or iterator
    with layout metadata.
  - **Layout** – Describes how data is organized in memory and across threads.
  - **Atom** – Represents a fundamental hardware operation such as
    matrix multiply-accumulate (MMA) or memory copy.
  - **Tiled operation** – Applies atoms across thread blocks and warps, for
    example ``TiledMma`` and ``TiledCopy``.


- **Pipelines** – Coordinate asynchronous copies, barriers, compute work, and
  producer/consumer warp groups.



For more on CuTe abstractions, refer to the `CuTe C++ library documentation <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cpp/cute/00_quickstart.md>`__.

Pythonic Kernel Expression
-----------------------------------

Developers express kernel logic, data movement, and computation using familiar
Python syntax and control flow. The APIs make tiling, threading strategies, and
data transformations explicit without requiring C++ template metaprogramming.

JIT Compilation
-----------------------------------

Python kernels are compiled at runtime into CUDA device code through the
CUTLASS Python compiler stack and CUDA toolchain, enabling rapid iteration and
interactive debugging.

Supported Features
=================================

For exact dependency versions, driver requirements, and installation commands,
refer to the :doc:`quick_start` section.

Platform Support
---------------------------------

- Linux on x86_64 and aarch64.
- Python and CUDA Toolkit versions listed in :doc:`quick_start`.

Kernel Authoring Capabilities
---------------------------------

- Python JIT functions and kernels with explicit static and dynamic values.


- Basic data types for typed values, pointers, and arrays.


- CuTe layout algebra, tensors, tiled copies, tiled MMA, and
  register/shared/global memory views.
- Architecture-specific GPU operations for warp-level, warpgroup-level, and
  Blackwell ``tcgen05`` programming.


- Pipeline APIs for producer/consumer and warp-specialized kernels.


- Integration guides for PyTorch, TVM FFI, notebooks, IKET profiling, autotuning,
  and ahead-of-time compilation.

Architecture Coverage
---------------------------------

- **NVIDIA Ampere and Ada:** warp-level MMA programming.
- **NVIDIA Hopper:** warpgroup MMA programming and TMA-oriented kernels.
- **NVIDIA Blackwell:** ``tcgen05`` MMA programming, TMEM-oriented kernels, and
  Blackwell-specific primitives.

For current constraints and unsupported features, refer to the :doc:`limitations` section.

Relationship to CUTLASS C++
=================================

CUTLASS Python is not a replacement for the CUTLASS C++ library or its 2.x and
3.x APIs. Instead, it is a high-productivity kernel authoring framework that
shares concepts with CUTLASS C++, including CuTe, pipelines, schedulers, tiled
copy, and tiled MMA.

- **Performance**: Generated kernels aim to match CUTLASS C++ kernels in performance; however, some performance gaps 
  may exist due to missing optimizations that have been added over the years to CUTLASS C++ and may be missing in the DSLs examples.
- **Library scope**: CUTLASS Python focuses on authoring and tuning individual
  kernel instances. It does not currently provide the full GEMM/Conv profiler
  or library interface available in CUTLASS C++.

Getting Started
================================

Use this path when learning CUTLASS Python:

- Start with :doc:`quick_start` to install dependencies and verify the
  environment.
- Read :doc:`cute_dsl` for the DSL programming model, including JIT functions,
  kernels, static values, control flow, and argument handling.
- Use :doc:`guides` for task-focused workflows such as framework integration,
  debugging, profiling, autotuning, AOT compilation, and MMA programming.


- Use :doc:`apis` as the reference for Basic Data Types, CuTe, Pipeline, and
  Utilities.


- Check :doc:`limitations`, :doc:`deprecation`, and :doc:`faqs` for support
  boundaries, compatibility policy, common questions, and known issues.

Current Status
=================================

CUTLASS Python is actively evolving with the CUTLASS 4.x releases. Interfaces
that are experimental or subject to change are documented through the
:doc:`deprecation` policy, API reference, and limitations pages. For known issues
and workarounds, consult :doc:`limitations` and :doc:`faqs`.

Community & Feedback
==================================

We welcome contributions and feedback from the developer community!

You can:

- Submit bug reports or feature requests via our `GitHub Issues page <https://github.com/NVIDIA/cutlass/issues>`__
- Join the CUTLASS community on `Discord <https://discord.com/channels/1019361803752456192/1150868614921064590>`__ to ask questions and share ideas
- Contribute examples, tutorials, or enhancements to the DSLs
- Report unclear or missing documentation
- Propose support for additional data types or kernel variants
- Help prioritize roadmap features by upvoting GitHub issues

Thank you for helping shape the future of CUTLASS DSLs!
