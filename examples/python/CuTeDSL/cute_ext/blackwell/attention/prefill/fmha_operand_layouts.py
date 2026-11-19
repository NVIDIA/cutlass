# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""FMHA operand layout helper.

Builds the canonical Q / K / V / O / LSE / sink CuTe layouts for fused
multi-head attention from a single ``(b, s_q, s_lse, s_k, h_q, h_k, d, dv)``
tuple. The goal is that an FMHA kernel can replace its inline
``cute.make_layout(...)`` blocks with a few ``operand_layouts.make_*_tensor(...)``
calls and get bit-identical layouts.

Layout family
-------------
All operand layouts share the hierarchical L mode

    ((h_r, h_k), b)        with    h_r = h_q // h_k

so MHA (``h_q == h_k``) and GQA (``h_q > h_k``) use the *same* layout family:
MHA simply collapses to ``h_r == 1``. Consumers (tilers, partitioners, MMA
setup) never have to fork on "is this GQA".

Operand conventions
-------------------
  Q  : K-major,  shape ``(s_q,  d,  ((h_r, h_k), b))``  -- (M, K, L)
  K  : K-major,  shape ``(s_k,  d,  ((h_r, h_k), b))``  -- (N, K, L), h_r broadcast
  V  : MN-major, shape ``(dv,   s_v, ((h_r, h_k), b))`` -- (K, N, L), h_r broadcast
  O  : K-major,  shape ``(s_q,  dv, ((h_r, h_k), b))``  -- (M, K, L)
  LSE: 2D,       shape ``(s_lse,     ((h_r, h_k), b))``
  sink: 1D,      shape ``(           ((h_r, h_k), b))``

Why K and V use stride 0 on the ``h_r`` mode
   GQA's defining feature is that ``h_r`` query heads share one K/V head.
   Putting stride 0 on the ``h_r`` sub-mode broadcasts a single (h_k) head
   across all its query-group siblings without copying.

Why LSE uses head-stride 1 (and outer stride h_r)
   Heads are the *innermost* dimension of an LSE row, matching the FlashInfer
   ``(total_q, h_q)`` convention. A row stride of ``h_q`` keeps row-major
   contiguity across heads.

Assumptions
-----------
* Fixed-seqlen attention: ``s_v == s_k``. Var-seqlen needs separate handling.
* Head-dim is innermost: stride 1 on the ``d`` (Q/K) and ``dv`` (V/O) modes.
"""

from typing import Tuple

import cutlass.cute as cute


# Type aliases -- the L mode is shared by every operand, so naming it once
# makes the per-operand signatures self-describing.
HeadBatchShape = Tuple[Tuple[int, int], int]  # ((h_r, h_k), b)
HeadBatchStride = Tuple[Tuple[int, int], int]


class FmhaOperandLayouts:
    """Canonical operand layout factory for fused multi-head attention.

    Construct once from a problem tuple, then call ``make_q_tensor(src)``,
    ``make_k_tensor(src)``, etc. to construct each operand's CuTe tensor over
    the caller-supplied storage.

    All sequence lengths, head counts, and head dims are stored as Python
    ``int``s so the resulting layouts are static (constant-folded by the DSL).
    """

    def __init__(
        self,
        problem_tuple: Tuple[int, int, int, int, int, int, int, int],
    ):
        """Build the layout factory from the 8-element problem tuple.

        :param problem_tuple: ``(b, s_q, s_lse, s_k, h_q, h_k, d, dv)`` where:

            * ``b``     -- batch size
            * ``s_q``   -- query sequence length
            * ``s_lse`` -- log-sum-exp sequence length (``== s_q`` here)
            * ``s_k``   -- key sequence length (``== s_v``, the value seqlen)
            * ``h_q``   -- number of query heads
            * ``h_k``   -- number of key/value heads; ``h_q`` must be a multiple
                           of ``h_k`` (GQA group ratio ``h_r = h_q // h_k``,
                           ``h_r == 1`` for plain MHA)
            * ``d``     -- Q/K head dimension
            * ``dv``    -- V head dimension (``== d`` except MLA: ``d=192,
                           dv=128``)
        """
        # Positional unpack of the tuple documented above.
        b, s_q, s_lse, s_k, h_q, h_k, d, dv = problem_tuple

        # Only validate when h_q / h_k are static Python ints. Inside a
        # @cute.jit body these come through as DSL Int32 values,
        # which can't be coerced to Python bool; in that case the caller is
        # responsible for validating at the host site (e.g. ``run()``).
        if isinstance(h_q, int) and isinstance(h_k, int):
            if h_k <= 0 or h_q <= 0 or h_q % h_k != 0:
                raise ValueError(
                    f"FmhaOperandLayouts: h_q={h_q} must be a positive multiple "
                    f"of h_k={h_k} (GQA requires h_q == h_r * h_k for integer "
                    f"h_r >= 1)."
                )

        self.b = b
        self.s_q = s_q
        self.s_lse = s_lse
        self.s_k = s_k
        self.s_v = s_k  # fixed-seqlen attention invariant
        self.h_q = h_q
        self.h_k = h_k
        self.h_r = h_q // h_k  # query-group ratio; MHA -> 1
        self.d = d
        self.dv = dv

        # Per-batch strides in elements. Q and O walk all h_q heads
        # (one head per query-group sibling); K and V only walk h_k heads
        # because the h_r mode is broadcast via stride 0; LSE walks h_q logits
        # per row.
        self.batch_stride_q = h_q * s_q * d
        self.batch_stride_k = h_k * s_k * d
        self.batch_stride_v = h_k * self.s_v * dv
        self.batch_stride_o = h_q * s_q * dv
        self.batch_stride_lse = h_q * s_lse

    def __repr__(self) -> str:
        return (
            "FmhaOperandLayouts("
            f"b={self.b}, s_q={self.s_q}, s_lse={self.s_lse}, s_k={self.s_k}, "
            f"h_q={self.h_q}, h_k={self.h_k}, h_r={self.h_r}, "
            f"d={self.d}, dv={self.dv})"
        )

    __str__ = __repr__

    # ------------------------------------------------------------------ helpers

    def _l_shape(self) -> HeadBatchShape:
        """The ``((h_r, h_k), b)`` L mode shared by every operand."""
        return ((self.h_r, self.h_k), self.b)

    @staticmethod
    def _make_tensor(src: cute.Tensor, shape, stride) -> cute.Tensor:
        """Build a tensor with the given (shape, stride) over ``src``'s storage."""
        layout = cute.make_layout(shape, stride=stride)
        return cute.make_tensor(src.iterator, layout)

    # -------------------------------------------------------------------- Q
    # K-major. (s_q, d, ((h_r, h_k), b)).
    #
    # Within one batch, query heads are packed contiguously: walking h_r flips
    # one head (stride d), walking h_k flips a query-group (stride d*h_r).

    def shape_q(self) -> Tuple[int, int, HeadBatchShape]:
        return (self.s_q, self.d, self._l_shape())

    def stride_q(self) -> Tuple[int, int, HeadBatchStride]:
        d = self.d
        seq_stride = d * self.h_q  # one s_q step crosses all heads
        head_strides = (d, d * self.h_r)  # (h_r-step, h_k-step)
        return (seq_stride, 1, (head_strides, self.batch_stride_q))

    def make_q_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_q(), self.stride_q())

    # -------------------------------------------------------------------- K
    # K-major, broadcast over the h_r sub-mode (GQA query-group sharing).

    def shape_k(self) -> Tuple[int, int, HeadBatchShape]:
        return (self.s_k, self.d, self._l_shape())

    def stride_k(self) -> Tuple[int, int, HeadBatchStride]:
        d = self.d
        seq_stride = d * self.h_k  # only h_k real heads in K
        head_strides = (0, d)  # h_r broadcast, h_k contiguous
        return (seq_stride, 1, (head_strides, self.batch_stride_k))

    def make_k_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_k(), self.stride_k())

    # -------------------------------------------------------------------- V
    # MN-major (head-dim outer along mode 0 with stride 1, sequence along mode 1).
    # h_r broadcast, like K.

    def shape_v(self) -> Tuple[int, int, HeadBatchShape]:
        return (self.dv, self.s_v, self._l_shape())

    def stride_v(self) -> Tuple[int, int, HeadBatchStride]:
        dv = self.dv
        seq_stride = dv * self.h_k
        head_strides = (0, dv)  # h_r broadcast, h_k contiguous
        return (1, seq_stride, (head_strides, self.batch_stride_v))

    def make_v_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_v(), self.stride_v())

    # -------------------------------------------------------------------- O
    # K-major, mirrors Q's head packing but with dv replacing d.

    def shape_o(self) -> Tuple[int, int, HeadBatchShape]:
        return (self.s_q, self.dv, self._l_shape())

    def stride_o(self) -> Tuple[int, int, HeadBatchStride]:
        dv = self.dv
        seq_stride = dv * self.h_q
        head_strides = (dv, dv * self.h_r)
        return (seq_stride, 1, (head_strides, self.batch_stride_o))

    def make_o_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_o(), self.stride_o())

    # ------------------------------------------------------------------- LSE
    # 2D layout with heads innermost (FlashInfer (total_q, h_q) convention).

    def shape_lse(self) -> Tuple[int, HeadBatchShape]:
        return (self.s_lse, self._l_shape())

    def stride_lse(self) -> Tuple[int, HeadBatchStride]:
        # Row stride is h_q so that one s_lse step advances past all heads of
        # the previous row.
        row_stride = self.h_q
        head_strides = (1, self.h_r)  # heads are contiguous within a row
        return (row_stride, (head_strides, self.batch_stride_lse))

    def make_lse_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_lse(), self.stride_lse())

    # ------------------------------------------------------------------ sink
    # 1D over h_q, with stride 0 on the batch mode so blk_coord[2] just picks
    # a head index regardless of batch.

    def shape_sink(self) -> HeadBatchShape:
        return self._l_shape()

    def stride_sink(self) -> HeadBatchStride:
        head_strides = (1, self.h_r)
        batch_stride = 0  # broadcast across batch
        return (head_strides, batch_stride)

    def make_sink_tensor(self, src: cute.Tensor) -> cute.Tensor:
        return self._make_tensor(src, self.shape_sink(), self.stride_sink())
