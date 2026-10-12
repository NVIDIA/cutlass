.. Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
.. SPDX-License-Identifier: BSD-3-Clause
..
.. Redistribution and use in source and binary forms, with or without
.. modification, are permitted provided that the following conditions are met:
..
.. 1. Redistributions of source code must retain the above copyright notice, this
.. list of conditions and the following disclaimer.
..
.. 2. Redistributions in binary form must reproduce the above copyright notice,
.. this list of conditions and the following disclaimer in the documentation
.. and/or other materials provided with the distribution.
..
.. 3. Neither the name of the copyright holder nor the names of its
.. contributors may be used to endorse or promote products derived from
.. this software without specific prior written permission.
..
.. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
.. AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
.. IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
.. DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
.. FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
.. DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
.. SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
.. CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
.. OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
.. OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Layout Algebra
==============

CuTe provides an algebra of layouts — operations that combine layouts in
structured ways.  In the CuTe IR dialect, every operation in this algebra
is exposed as an op:

- **Composition** — functional composition of layouts.
- **Coalesce** — simplify a layout without changing its semantics.
- **Complement** — produce a "filler" layout that is disjoint from a
  given one.
- **Inverse** (left and right) — invert a layout's coordinate mapping.
- **Slice and Dice** — split a layout by an underscore pattern.
- **Products** — replicate a layout according to another layout (6
  variants).
- **Divides** — split a layout according to another (4 variants).
- **Tile to shape** — replicate a block layout to cover a target shape
  (``cute.tile_to_shape``).

Tiling and partitioning utilities are frequently used in kernels that build on
these algebraic operations.

Throughout these documents we use the same notation as the source
operations: ``A ∘ B`` for composition, ``A ⊗ B`` for product, and
``A ⊘ B`` for divide.  See
:doc:`01_cute_types` for the layout type itself.

This chapter is split into two sections:

.. toctree::
   :maxdepth: 1
   :hidden:

   02_layout_algebra/core_ops
   02_layout_algebra/products_and_divides

- :doc:`Core layout algebra ops <02_layout_algebra/core_ops>` — coalesce,
  composition, complement, inverses, slice / dice.
- :doc:`Products and divides <02_layout_algebra/products_and_divides>` —
  the replication and splitting families that drive CuTe's tiling and
  partitioning.
