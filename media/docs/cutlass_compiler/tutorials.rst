Tutorials
=========

Guided introduction to layouts and layout algebra using CuTe IR's MLIR
syntax.  If you are new to CuTe, work through these in order.  If you
already know C++ CuTe, use them as a quick map from C++ concepts to their
MLIR equivalents.

.. toctree::
   :maxdepth: 1

   cute_concepts/01_cute_types
   cute_concepts/02_layout_algebra
   cute_concepts/03_advanced_constructors
   cute_concepts/04_accessors_and_size_index
   cute_concepts/05_arithmetic

Suggested reading order:

1. :doc:`CuTe Algebra Types <cute_concepts/01_cute_types>` — the core
   ``!cute.layout`` type, hierarchical shapes / strides / coords,
   static vs dynamic leaves, tiles, composed layouts, and swizzles.
2. :doc:`Layout algebra <cute_concepts/02_layout_algebra>` — the
   algebra ops: ``composition``, ``coalesce``, ``complement``, ``slice`` / ``dice``,
   inverses, products, divides.
3. :doc:`Advanced constructors <cute_concepts/03_advanced_constructors>` —
   shorthand layout constructors (``make_identity_layout``,
   ``make_ordered_layout``, ``make_layout_like``).
4. :doc:`Accessors and size / indexing <cute_concepts/04_accessors_and_size_index>` —
   read components out of CuTe values (``get_shape``, ``get_stride``,
   ``get``, ``select``, ``get_leaves``, ``get_scalars``) and compute
   sizes / coordinate-index conversions (``size``, ``cosize``,
   ``crd2idx``, ``idx2crd``).
5. :doc:`Arithmetic on CuTe values <cute_concepts/05_arithmetic>` —
   per-leaf tuple arithmetic and predicates (``tuple_add``,
   ``tuple_sub``, ``shape_div``, ``ceil_div``, ``equal``, ``elem_less``).
