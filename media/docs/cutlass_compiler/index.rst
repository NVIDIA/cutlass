CuTe IR Documentation
=====================

CuTe IR is an MLIR dialect stack for **CuTe layout algebra** on NVIDIA
GPUs.  It exposes the same hierarchical-layout abstractions that the
C++ CuTe library provides — shapes, strides, layouts, composed layouts,
swizzles, products, divides, and the surrounding algebra — as
first-class MLIR types and operations.

If you've worked with C++ CuTe, almost every concept here has a one-to-one
analogue in CuTe IR.  If you're new to CuTe, start with the
:doc:`Quickstart <quickstart>` and then work through
the :doc:`tutorials`.

---------------------------------------------------------------------------

Overview
--------

This documentation is split into four sections:

- :doc:`Quickstart <quickstart>` — what CuTe IR is,
  how to read its syntax, and a minimal end-to-end example.  Start here.

- :doc:`Tutorials <tutorials>` — guided introduction to layouts and the
  layout algebra.  Read these first if unfamiliar with CuTe.

- :doc:`Cute dialect reference <cute_dialect>` — exhaustive reference for
  every op, type, and pass in the ``cute`` dialect.  Covers operand types,
  assembly format, traits, and pass options.

- :doc:`Base dialect reference <base_dialect>` — the base facade and its
  target-attach / GPU-binary-emit passes (``attach-nvvm-target``,
  ``emit-gpu-binary``, ``base-prepare``, ``one-shot-convert-to-llvm``).

For build, test, and tool-usage instructions see the top-level
`CUTLASS Compiler README <https://github.com/NVIDIA/cutlass/blob/main/cutlass_compiler/README.md>`__.

---------------------------------------------------------------------------

LLM skill
---------

If you're using an LLM assistant to write CuTe IR code, install the skill from the
`CUTLASS Compiler skills.md <https://github.com/NVIDIA/cutlass/blob/main/cutlass_compiler/docs/skills.md>`__.
The skill teaches the assistant the CuTe dialect's syntax, common idioms,
and where to look in this documentation for any concept it doesn't
already know.
