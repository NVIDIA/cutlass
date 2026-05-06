.. _dsl_struct_types:

Struct-like JIT Arguments
=========================

|DSL| supports several struct-like Python types as JIT function arguments.
Each provides a different trade-off between mutability, syntax convenience,
and low-level control.

.. |DSL| replace:: CuTe DSL

.. contents:: On this page
   :local:
   :depth: 2


Overview
--------

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Type
     - Mutable fields?
     - Notes
   * - ``typing.NamedTuple``
     - **No**
     - Tuple subclass — fields fixed at construction.
       Flattened field-by-field through the pytree system.
   * - ``@dataclass(frozen=True)``
     - **No**
     - Frozen dataclass — treated as a read-only pytree container,
       similar to ``NamedTuple``.


NamedTuple
----------

A ``typing.NamedTuple`` whose fields are DSL scalar types (``Int32``,
``Float32``, etc.) can be passed directly to ``@cute.jit`` /
``cute.compile`` without any boilerplate or protocol implementation.

**How it works.**  NamedTuples are registered as pytree containers in the DSL
tree system.  Each field is flattened individually through the existing DSL
type paths and reconstructed by calling the NamedTuple constructor on the way
into the kernel body.  Field attribute access (``tup.a``, ``tup.b``, …)
works exactly as in native Python.

Basic usage
^^^^^^^^^^^

.. code-block:: python

    from typing import NamedTuple
    import cutlass
    import cutlass.cute as cute

    class Vec3(NamedTuple):
        x: cutlass.Int32
        y: cutlass.Int32
        z: cutlass.Int32

    @cute.jit
    def print_vec(v: Vec3):
        cute.printf("x=%d y=%d z=%d\n", v.x, v.y, v.z)

    v = Vec3(x=cutlass.Int32(1), y=cutlass.Int32(2), z=cutlass.Int32(3))
    cute.compile(print_vec, v)(v)

Control flow on fields
^^^^^^^^^^^^^^^^^^^^^^

Fields are DSL values inside the kernel, so they work in ``if``/``else``
branches and ``for`` loops:

.. code-block:: python

    @cute.jit
    def clamp_positive(v: Vec3, out: cute.Tensor):
        """Write max(field, 0) for each component."""
        out[0] = cutlass.Int32(0) if v.x < cutlass.Int32(0) else v.x
        out[1] = cutlass.Int32(0) if v.y < cutlass.Int32(0) else v.y
        out[2] = cutlass.Int32(0) if v.z < cutlass.Int32(0) else v.z

    @cute.jit
    def triangular_sum(v: Vec3, out: cute.Tensor):
        """Sum 0..v.x-1 into out[0], and so on."""
        s = cutlass.Int32(0)
        for i in range(v.x):
            s = s + i
        out[0] = s

Creating a new NamedTuple value inside the kernel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NamedTuple fields are **immutable** — the same constraint as native Python
tuples.  Assigning ``tup.x = ...`` inside a kernel raises ``AttributeError``.
To "update" a field, construct a replacement NamedTuple:

.. code-block:: python

    @cute.jit
    def scale(v: Vec3, factor: cutlass.Int32, out: cute.Tensor):
        # Construct a new Vec3 with all fields scaled
        scaled = Vec3(x=v.x * factor, y=v.y * factor, z=v.z * factor)
        out[0] = scaled.x
        out[1] = scaled.y
        out[2] = scaled.z

Choosing the right type
-----------------------

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Use case
     - Recommended type
   * - Read-only config / parameters passed into a kernel
     - ``NamedTuple`` or ``@dataclass(frozen=True)``
   * - Accumulator or running state updated inside a kernel
     - ``@native_struct``
   * - Want Python-native immutable semantics (hashable, unpackable)
     - ``NamedTuple``
   * - Need fine-grained LLVM struct control (packing, zero-init)
     - ``@native_struct``


See also
--------

* :doc:`dsl_jit_arg_generation` — overview of JIT function argument protocols
* :doc:`dsl_dynamic_layout` — passing ``Layout`` objects as JIT arguments
