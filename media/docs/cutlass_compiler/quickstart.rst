Quickstart
==========

This is a tour of the CuTe IR dialect: what it is, how to read its
syntax, and how to run programs through the lowering pipeline.

---------------------------------------------------------------------------

What is CuTe IR?
----------------

CuTe IR is an MLIR dialect that exposes CuTe layout algebra as IR types
and operations.  Where the C++ CuTe library is a template-heavy
compile-time abstraction, CuTe IR encodes the same abstractions as MLIR
values — making them inspectable, transformable, and lowerable through
standard MLIR compiler passes.

If you know C++ CuTe, the mental model is:

========================== ==================================================
C++ CuTe                    CuTe IR
========================== ==================================================
``cute::Shape``             ``!cute.shape``
``cute::Stride``            ``!cute.stride``
``cute::Coord``             ``!cute.coord``
``cute::Tile``              ``!cute.tile``
``cute::Layout``            ``!cute.layout``
``cute::ComposedLayout``    ``!cute.composed_layout``
``cute::Swizzle``           ``!cute.swizzle``
``cute::composition``       ``cute.composition``
``cute::logical_product``   ``cute.logical_product``
…                           …
========================== ==================================================

Almost all layout-algebra primitives available in C++ CuTe have a
corresponding CuTe IR op.  See :doc:`the dialect reference <cute_dialect>`
for the full list.

---------------------------------------------------------------------------

A minimal program
-----------------

A trivial CuTe IR program builds a static layout and prints it:

.. code-block::

   func.func @main() {
     %l = cute.static : !cute.layout<"(4,8):(1,4)">
     cute.print(%l) : !cute.layout<"(4,8):(1,4)">
     return
   }

Save this as ``hello.mlir`` and run it end-to-end through the JIT host
pipeline:

.. code-block:: bash

   cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
                    -base-prepare -one-shot-convert-to-llvm hello.mlir \
     | mlir-runner -e main -entry-point-result=void
   # → (4,8):(1,4)

That's a complete CuTe program: layout construction → ``cute.print`` →
LLVM/NVVM → executed via ``mlir-runner``.

---------------------------------------------------------------------------

Reading the syntax
------------------

A CuTe type describes its value as a string parameter.  Three rules
cover most cases:

1. **Layouts** are written ``"shape:stride"``.  Both shape and stride
   can be nested tuples with parentheses.

   .. code-block::

      !cute.layout<"8:1">                     // rank-1 layout
      !cute.layout<"(4,8):(1,4)">             // rank-2, col-major
      !cute.layout<"((2,2),3):((1,4),8)">     // hierarchical / nested

2. **Dynamic** leaves are written ``?``.

   .. code-block::

      !cute.layout<"(?,8):(1,?)">             // dynamic shape + stride

3. **Composed layouts** stack an outer ``A``, an offset, and an inner
   ``B`` with ``∘``-style separator ``o``.  ``A`` may be a layout or a
   swizzle.

   .. code-block::

      !cute.composed_layout<"(4,8):(1,4) o 0 o (2,3):(1,2)">
      !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">

4. **Shapes, strides, and coords** use the same paren-tuple notation as
   the corresponding side of a layout.  A
   scalar is written bare; nested tuples nest with parentheses; ``?``
   marks dynamic leaves.

   .. code-block::

      !cute.shape<"5">                        // scalar shape
      !cute.shape<"(4,8)">                    // rank-2 shape
      !cute.shape<"((2,2),3)">                // hierarchical / nested
      !cute.shape<"(?,8)">                    // dynamic leaf

      !cute.stride<"1">                       // scalar stride
      !cute.stride<"(1,4)">                   // rank-2 stride
      !cute.stride<"?">                       // fully dynamic

      !cute.coord<"(2,3)">                    // rank-2 coordinate
      !cute.coord<"((1,0),2)">                // hierarchical coordinate

Constructing values
~~~~~~~~~~~~~~~~~~~

There are two ways to build CuTe values:

**A.** ``cute.static`` — fully compile-time constant.  Use whenever
every leaf is known.

.. code-block::

   %l = cute.static : !cute.layout<"(4,8):(1,4)">

**B.** ``cute.make_*`` — assembles a value from operand SSA values.
The result type encodes which leaves are dynamic.

.. code-block::

   // Suppose %m is a runtime i32 — the dynamic mode-0 extent.
   %s  = cute.make_shape(%m)
           : (i32) -> !cute.shape<"(?,8)">

   // Static stride — no operands needed; the ``?`` slot is filled at
   // construction time by the dynamic operand we supply.
   %d  = arith.constant 4 : i32
   %t  = cute.make_stride(%d)
           : (i32) -> !cute.stride<"(1,?)">

   // Combine shape + stride into a layout.
   %l  = cute.make_layout(%s, %t)
           : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
          -> !cute.layout<"(?,8):(1,?)">

The ``cute.make_*`` ops are the canonical entry point for dynamic
values that depend on runtime SSA values.  Each dynamic ``?`` slot
accepts any *scalar-index* operand — ``i32``, ``i64``, or a scalar
(rank-0) ``!cute.int_tuple`` — so a dynamic leaf can be sourced from
arith ops, a function argument, or another CuTe value.

---------------------------------------------------------------------------

The lowering pipeline
---------------------

A CuTe program goes through three CuTe passes before reaching the
``base`` (a selected set of upstream MLIR dialects) layer:

================================ ==================================================
Pass                              What it does
================================ ==================================================
``cute-fold-static``              Folds any op whose result is fully static to
                                  ``cute.static``.
``cute-expand-ops``               Lowers every CuTe op to a small surviving set
                                  (``make_*``, ``static``, ``print``).
``cute-to-base``                  Lowers the surviving set + every CuTe type to
                                  the ``base`` dialect (``arith``, ``func``,
                                  ``LLVM``, …).
================================ ==================================================

After ``cute-to-base`` no CuTe ops or CuTe types remain — the IR is
pure ``base`` and is handed to the base lowering tail:
``base-prepare`` canonicalizes/optimizes the post-CuTe IR,
``one-shot-convert-to-llvm`` lowers every remaining base op to LLVM
(and NVVM inside ``gpu.module``), and the optional
``attach-nvvm-target`` / ``emit-gpu-binary`` pair attaches an NVVM
target and emits a ``gpu.binary`` (PTX, cubin, or fatbin).  See the
`CUTLASS Compiler README <https://github.com/NVIDIA/cutlass/blob/main/cutlass_compiler/README.md>`__
for the rest of the
pipeline.

You can run individual passes for inspection.  Run cute-expand-ops on a
file and see the lowered IR:

.. code-block:: bash

   cute-opt -cute-fold-static -cute-expand-ops hello.mlir

Or run the full pipeline up to LLVM:

.. code-block:: bash

   cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
                    -base-prepare -one-shot-convert-to-llvm hello.mlir

---------------------------------------------------------------------------

Frequently-cited concepts
-------------------------

- **Static vs dynamic.** A layout is "fully static" when every shape
  and stride leaf is a compile-time integer.  Dynamic leaves use
  ``?`` and consume operand SSA values at construction time.
- **Coordinate types.** ``!cute.coord`` is a multidimensional
  coordinate.  Underscores (``_``) in a coord mark axes to slice
  along (see ``cute.slice`` / ``cute.dice``).
- **Tiles vs layouts.** A ``!cute.tile`` is a list of per-axis
  sub-layouts (or underscores).  Tiles are what the divide family of
  ops accepts; layouts are what the product family accepts.
- **Composed layouts.** ``A ∘ offset ∘ B`` — for instance, a swizzle
  applied to a shared-memory layout, or an affine remap applied to a
  tensor layout.  Most layout-algebra ops accept composed layouts
  wherever they accept layouts; the swizzle / affine outer ``A`` is
  threaded through unchanged.

---------------------------------------------------------------------------

Building and testing
--------------------

CuTe IR ships as a standalone CMake project rooted at
``cutlass_compiler/``.  It builds against LLVM/MLIR.

Fetch the pinned public LLVM revision (recorded in
``cutlass_compiler/LLVM_COMMIT``) and configure the project against
its bundled checkout:

.. code-block:: bash

   llvm_commit=$(tr -d '[:space:]' < cutlass_compiler/LLVM_COMMIT)
   git init cutlass_compiler/external/llvm-project
   git -C cutlass_compiler/external/llvm-project remote add origin \
     https://github.com/llvm/llvm-project.git
   git -C cutlass_compiler/external/llvm-project fetch --depth=1 origin "$llvm_commit"
   git -C cutlass_compiler/external/llvm-project checkout --detach FETCH_HEAD

   cmake -S cutlass_compiler -B build -G Ninja \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
     -DCUTLASS_COMPILER_USE_BUNDLED_LLVM=ON

   ninja -C build cute-opt base-opt cutlass-compiler

If you already have an LLVM/MLIR build tree, skip the bundled checkout
and point CMake at it:

.. code-block:: bash

   cmake -S cutlass_compiler -B build -G Ninja \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
     -DLLVM_DIR=/path/to/llvm-build/lib/cmake/llvm \
     -DMLIR_DIR=/path/to/llvm-build/lib/cmake/mlir

   ninja -C build cute-opt base-opt cutlass-compiler

For NVVM lowering tests, build LLVM with the ``NVPTX`` target as well
as ``Native``.  The bundled path defaults to ``Native;NVPTX``.

The most useful ``ninja`` targets to know upfront:

==================================== ==================================================
Target                                Purpose
==================================== ==================================================
``cute-opt``                          Cute-only opt driver (LIT-test workhorse)
``base-opt``                          Base-layer opt driver (post-``cute-to-base``)
``cutlass-compiler``                  Full opt driver covering the
                                      complete CuTe → base → LLVM pipeline
``check-cute``                        Run all CuTe LIT tests
``check-cute-unittests``              Run CuTe C++ gtest unit tests
``check-base``                        Run all base-layer LIT tests
``check-cutlass-integration``         End-to-end host (and device) integration tests
``check-cutlass-pipelinelit``         Cross-layer structural pipeline LIT tests
``check-cutlass-all``                 Aggregate of every suite
==================================== ==================================================

See the
`CUTLASS Compiler README <https://github.com/NVIDIA/cutlass/blob/main/cutlass_compiler/README.md>`__
for the full build reference, including how to reuse an existing LLVM
build tree, run individual LIT files, and enable the CUDA runner.

---------------------------------------------------------------------------

Where to go next
----------------

- :doc:`CuTe Algebra Types <cute_concepts/01_cute_types>` — the core
  ``!cute.layout`` type, shapes, strides, coordinates, hierarchical
  layouts, dynamic vs static leaves, tiles, composed layouts, and
  swizzles.
- :doc:`Layout algebra <cute_concepts/02_layout_algebra>` — learn the
  algebra ops: composition, coalesce, complement, slice/dice,
  inverses, products, divides.
- :doc:`Advanced constructors <cute_concepts/03_advanced_constructors>` —
  layout-like constructors (``make_identity_layout``,
  ``make_ordered_layout``, ``make_layout_like``).
- :doc:`Accessors and size / indexing <cute_concepts/04_accessors_and_size_index>` —
  read components out of CuTe values and compute sizes / coordinate
  conversions.
- :doc:`Arithmetic on CuTe values <cute_concepts/05_arithmetic>` — per-leaf tuple
  arithmetic and predicates (``tuple_add``, ``shape_div``,
  ``ceil_div``, ``equal``, ``elem_less``).
- :doc:`CuTe dialect reference <cute_dialect>` — every op, every
  type, every attribute, with operand / result types and assembly format.
