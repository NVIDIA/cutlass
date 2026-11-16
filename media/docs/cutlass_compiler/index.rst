CuTe IR Documentation
=====================

CuTe IR is an MLIR dialect stack for **CuTe layout algebra** on NVIDIA
GPUs.  It exposes the same hierarchical-layout abstractions that the
C++ CuTe library provides — shapes, strides, layouts, composed layouts,
swizzles, products, divides, and the surrounding algebra — as
first-class MLIR types and operations.

If you've worked with C++ CuTe, almost every concept here has a one-to-one
analogue in CuTe IR.  If you're new to CuTe, start with the
`Quickstart <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/quickstart.rst>`__ and then work through
the `Tutorials <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/tutorials.rst>`__.

---------------------------------------------------------------------------

Overview
--------

This documentation is split into four sections:

- `Quickstart <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/quickstart.rst>`__ — what CuTe IR is,
  how to read its syntax, and a minimal end-to-end example.  Start here.

- `Tutorials <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/tutorials.rst>`__ — guided introduction to layouts and the
  layout algebra.  Read these first if unfamiliar with CuTe.

- `Cute dialect reference <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/cute_dialect.rst>`__ — exhaustive reference for
  every op, type, and pass in the ``cute`` dialect.  Covers operand types,
  assembly format, traits, and pass options.

- `Base dialect reference <https://github.com/NVIDIA/cutlass/blob/main/media/docs/cutlass_compiler/base_dialect.rst>`__ — the base facade and its
  target-attach / GPU-binary-emit passes (``attach-nvvm-target``,
  ``emit-gpu-binary``, ``base-prepare``, ``one-shot-convert-to-llvm``).

For build, test, and tool-usage instructions see the top-level
`CUTLASS Compiler README <https://github.com/NVIDIA/cutlass/blob/main/cutlass_compiler/README.md>`__.
