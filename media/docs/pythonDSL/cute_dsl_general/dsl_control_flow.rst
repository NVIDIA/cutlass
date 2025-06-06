.. _dsl_control_flow:
.. |DC|        replace:: dynamic compilation
.. |IR|        replace:: intermediate representation (IR)
.. |DSL|       replace:: CuTe DSL
.. |Constexpr| replace:: **Constexpr** (compile-time Python value)

Control Flow
==================


Overview
--------
|DSL| walks Python’s AST and converts each control-flow construct it finds into
structured |IR|.  You can therefore write ordinary Python loops and branches
while the compiler decides—statement by statement—whether to

* **evaluate at compile time** if the controlling value is a |Constexpr|, or
* **emit intermediate representation (IR)** when the value is dynamic.


For a high-level discussion of the overall pipeline, see
:doc:`the code-generation overview <dsl_code_generation>`.

For Loops
---------
|DSL| recognises three kinds of ranges for ``for`` loops:

* ``range`` – the Python built-in
* ``cutlass.range_dynamic`` – always lowers to |IR|
* ``cutlass.range_constexpr`` – always unrolls at compile time


range(...)
~~~~~~~~~~~~~~~~~~~~~~~~~~~
The AST rewriter inserts a small helper stub.  At runtime the loop bounds are
inspected:

* **Constant bounds** → the loop is unrolled at compile time.
* **Dynamic bounds**  → the loop is emitted as structured |IR|.


cutlass.range_dynamic(...)
~~~~~~~~~~~~~~~~~~~~~~~~~~~
Use when you *always* want a loop in the generated |IR|, even if the bounds
look constant.


cutlass.range_constexpr(...)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Runs in the Python interpreter and is fully unrolled before code generation.
All loop indices must be |Constexpr|.


Limitations of Dynamic For Loops
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Early-exit ``break``, ``continue``, or raising exception are not yet supported.
* Operations in the loop body are traced only when tracing is active in that
  region.


**Example:**

.. code-block:: python

   @cute.jit
   def loop_example():
       n = 10

       # ❌ This loop is dynamic, early-exit isn't allowed.
       for i in cutlass.range_dynamic(n):
           if i == 5:
               break         # Early-exit
           cute.printf("%d\\n", i)

       # ✅ This loop is constexpr, early-exit is allowed.
       for i in cutlass.range_constexpr(n):
           if i == 5:
               break         # Early-exit
           cute.printf("%d\\n", i)

If-Else Statements
------------------

Standard Python ``if``/``else`` is supported.

* **Predicate is Constexpr (compile-time Python value)** → evaluated at compile time.
* **Predicate is dynamic**     → lowered to |IR|.

**Example:**

.. code-block:: python

   @cute.jit
   def main(const_var: cutlass.Constexpr, dynamic_var: cutlass.Int32):
       if const_var:                         # compile-time branch
           cute.printf("Const branch\\n")
       else:
           cute.printf("Const else\\n")

       if dynamic_var == 10:                 # dynamic branch
           cute.printf("Dynamic True\\n")
       else:
           cute.printf("Dynamic False\\n")

Similarly to for-loops, the ``if cutlass.const_expr`` and ``if cutlass.dynamic_expr`` constructs can
be used to force the evaluation at compile-time or the generation of IR, respectively. Unstructured
control flow is only supported when using ``if cutlass.const_expr``.

While Loops
-----------

Python ``while`` loops are always treated as **dynamic** because the loop condition may become
dynamic after the first iteration. Similarly to for-loops and ``if``/``else``, the
``while cutlass.const_expr`` and ``while cutlass.dynamic_expr`` constructs are available.

Compile-Time Metaprogramming
----------------------------

Mix compile-time constructs with normal |DSL| code to generate specialised
kernels without runtime overhead.  A compile-time flag can, for example, toggle
an optional **ReLU** epilogue:

.. code-block:: python

   @cute.kernel
   def gemm(..., do_relu: cutlass.Constexpr):
       # main GEMM work
       ...
       if const_expr(do_relu):    # compile-time guard
           # ReLU code is emitted only when do_relu is True
           ...

.. code-block:: text

   gemm(..., False)   # ReLU is omitted from the generated |IR|
   gemm(..., True)    # ReLU is included
