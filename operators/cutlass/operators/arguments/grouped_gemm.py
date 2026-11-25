# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

from __future__ import annotations

import warnings
from dataclasses import dataclass, field
from typing import Literal, NamedTuple

from cutlass.cute.typing import Integer

from cutlass.operators.arguments.base import Operand, RuntimeArguments
from cutlass.operators.arguments.epilogue import (
    EpilogueArguments,
    EpilogueArgumentsBase,
    PerGroupScaleEpilogueArguments,
)
from cutlass.operators.arguments.operand import (
    DenseTensor,
    ScaledOperand,
    _operand_or_dense,
)
from cutlass.operators.config import GlobalOptions
from cutlass.operators.typing import NumericLike, TensorLike
from cutlass.operators.utils.dtype import to_cutlass_type


class IndexPtrGroupedGemmProblemSize(NamedTuple):
    """Problem shape for contiguous-offset grouped GEMM.

    Exactly one of M, N, or K is packed across groups, as selected by
    ``offsets_along``. Each value in ``offsets`` is the exclusive endpoint of
    one group along that dimension, matching the representation accepted by
    :class:`IndexPtrGroupedGemmArguments`.
    """

    M: int
    """M extent, summed across groups when ``offsets_along == "m"``."""
    N: int
    """N extent, summed across groups when ``offsets_along == "n"``."""
    K: int
    """K extent, summed across groups when ``offsets_along == "k"``."""
    G: int
    """Number of independent GEMMs."""
    offsets: tuple[int, ...]
    """Exclusive endpoint for each group along ``offsets_along``."""
    offsets_along: Literal["m", "n", "k"]
    """Logical GEMM dimension partitioned by ``offsets``."""



@dataclass
class IndexPtrGroupedGemmArguments(RuntimeArguments):
    """Arguments for a Grouped GEMM with contiguous tensors concatenated along M, N, or K.

    A grouped GEMM performs a series of independent GEMM operations, where each
    GEMM can have different matrix dimensions. In this particular class, we
    represent grouped GEMMs where exactly one dimension can vary
    across groups; the other two remain constant. All operands are dense tensors,
    packed and contiguous. For the operand with the varying dimension, its total
    size is ``sum(changing_dim) * fixed_dims``.

    ``offsets`` describes the problem boundaries along ``offsets_along``. It is a
    tensor delineating the ending positions of each problem in the group.

    When ``offsets_along == "m"`` the operands and computation are::

        A       : DenseTensor of shape (TotalM, K)   # TotalM = sum(M) over groups
        B       : DenseTensor of shape (group_count, K, N)
        out     : DenseTensor of shape (TotalM, N)
        offsets : DenseTensor of shape (group_count,) = [M0, M0+M1, ..., TotalM]

        start = 0
        for g in range(group_count):
            end = offsets[g]
            out[start:end, :] = A[start:end, :] @ B[g, :, :]
            start = end

    This is equivalent to Pytorch's 2Dx3D Grouped GEMM.

    Rows of ``A`` and ``out`` are sliced by ``offsets``; ``B`` is per group::

             A (TotalM x K)              B[g,:,:]  (K x N, per group)         out (TotalM x N)
                     K                          N                                  N
              <--------->                  <------->                          <------->
          0   ┌───────────┐  ┐            ┌─────────┐ ┐                     ┌─────────┐ ┐
              │    A0     │  │ M0   ─ @ ─ │   B0    │ │ K   ────────►       │  out0   │ │ M0
         M0   ├───────────┤  ┤            └─────────┘ ┘                     ├─────────┤ ┤
              │    A1     │  │ M1   ─ @ ─ ┌─────────┐ ┐                     │  out1   │ │ M1
        M0+M1 ├───────────┤  ┤            │   B1    │ │ K   ────────►       ├─────────┤ ┤
              │    A2     │  │ M2   ─ @ ─ └─────────┘ ┘                     │  out2   │ │ M2
        TotalM└───────────┘  ┘            ┌─────────┐ ┐                     └─────────┘ ┘
                ▲                         │   B2    │ │ K   ────────►
              offsets slice rows          └─────────┘ ┘
              [0:M0], [M0:M0+M1], ...

          per group g:   out[start:end, :]  =  A[start:end, :]  @  B[g, :, :]
                            (Mg x N)             (Mg x K)           (K x N)

    When ``offsets_along == "n"`` the operands and computation are::

        A       : DenseTensor of shape (group_count, M, K)
        B       : DenseTensor of shape (K, TotalN)   # TotalN = sum(N) over groups
        out     : DenseTensor of shape (M, TotalN)
        offsets : DenseTensor of shape (group_count,) = [N0, N0+N1, ..., TotalN]

        start = 0
        for g in range(group_count):
            end = offsets[g]
            out[:, start:end] = A[g, :, :] @ B[:, start:end]
            start = end

    This is equivalent to Pytorch's 3Dx2D Grouped GEMM.

    Columns of ``B`` and ``out`` are sliced by ``offsets``; ``A`` is per group::

          A[g,:,:] (M x K, per group)       B (K x TotalN)             out (M x TotalN)
                  K                          N0    N1    N2             N0    N1    N2
             <─────────>                  <────><────><────>        <────><────><────>
          ┌─────────────┐ ┐              ┌─────┬─────┬─────┐        ┌─────┬─────┬─────┐
          │     A0      │ │ M  ─ @ ─►    │     │     │     │        │     │     │     │
          └─────────────┘ ┘            K │ B0  │ B1  │ B2  │ K    M │out0 │out1 │out2 │ M
          ┌─────────────┐ ┐              │     │     │     │        │     │     │     │
          │     A1      │ │ M  ─ @ ─►    └─────┴─────┴─────┘        └─────┴─────┴─────┘
          └─────────────┘ ┘                 ▲     ▲     ▲
          ┌─────────────┐ ┐              offsets slice columns
          │     A2      │ │ M  ─ @ ─►     [0:N0], [N0:N0+N1], ...
          └─────────────┘ ┘

          per group g:   out[:, start:end]  =  A[g, :, :]  @  B[:, start:end]
                            (M x Ng)             (M x K)        (K x Ng)

    When ``offsets_along == "k"`` each K-slice is an independent GEMM whose
    M x N product is written to its own section in the output tensor::

        A       : DenseTensor of shape (M, TotalK)          # TotalK = sum(K) over groups
        B       : DenseTensor of shape (TotalK, N)
        out     : DenseTensor of shape (group_count, M, N)  # one M x N result per group
        offsets : DenseTensor of shape (group_count,) = [K0, K0+K1, ..., TotalK]

        start = 0
        for g in range(group_count):
            end = offsets[g]
            out[g, :, :] = A[:, start:end] @ B[start:end, :]
            start = end

    This is equivalent to Pytorch's 2Dx2D Grouped GEMM.

       ``offsets`` slice columns of ``A`` and rows of ``B``; each slice is one group::

          A (M x TotalK)                        B (TotalK x N)           out (group_count, M, N)
               K0     K1    K2                       N                        N
          <────><─────><─────>                     <──────>                <──────>
          ┌─────┬──────┬──────┐  ┐          0     ┌─────────┐ ┐     g=0  ┌─────────┐ ┐
        M │ A0  │  A1  │  A2  │  │ M              │   B0    │ │ K0       │  A0@B0  │ │ M
          └─────┴──────┴──────┘  ┘         K0     ├─────────┤ ┤          └─────────┘ ┘
             │      │      │                      │   B1    │ │ K1  g=1  ┌─────────┐ ┐
             │      │      └────@───► B2    K0+K1 ├─────────┤ ┤          │  A1@B1  │ │ M
             │      └───────────@───► B1          │   B2    │ │ K2       └─────────┘ ┘
             └──────────────────@───► B0   TotalK └─────────┘ ┘     g=2  ┌─────────┐ ┐
                                                                         │  A2@B2  │ │ M
                                                                         └─────────┘ ┘

          per group g:  out[g, :, :] = A[:, start:end] @ B[start:end, :]
                          (M x N)         (M x Kg)         (Kg x N)

    See Also:
        :doc:`Block-scaled grouped GEMM tutorial </media/docs/operators/tutorials/010_moe_grouped_gemm>`
    """

    A: DenseTensor | ScaledOperand
    """Input tensor A.

    The shape of A is (sum(M across all groups or TotalM), K) if offsets_along is "m" or
    (M, sum(K across all groups or TotalK)) if offsets_along is "k" or
    (group_count, M, K) if offsets_along is "n" where M, N, K are the dimensions of the GEMM problem.

    Pass a :class:`~cutlass.operators.ScaledOperand` for a block-scaled input: it
    adds one scale factor tensor, which the caller assembles as the concatenation
    of per-group blocks. Each block holds one group's scale factors, grown to
    whole layout atoms and arranged in the order named by
    :attr:`ScaledOperand.swizzle` on its own, so a block of ``(rows, cols)`` scale
    factors occupies ``round_up(rows, 128) * round_up(cols, 4)`` elements. The
    grouped extent is therefore ``sum(round_up(extent_g, P))`` over groups -- not
    ``round_up(sum(extent_g), P)`` -- where ``P`` is 128 rows for a grouped ``m``
    axis and 4 scale columns for a grouped ``k`` axis.

    Such a tensor is not one large arranged array that the groups index into. For
    a grouped ``m`` axis the two descriptions coincide, but for a grouped ``k``
    axis they do not, because the grouped axis is then interior to the atom
    tiling.

    A caller that assembles on the host knows the per-group extents and can size
    exactly. When a device-side quantizer fills the buffer instead they are not
    host-visible, so allocate the upper bound
    ``round_up(total, P) + (group_count - 1) * P``. Over-allocating is accepted:
    the Operator checks ``P``-alignment and a lower bound rather than an exact
    size, and the kernel derives each block's position from ``offsets``, so the
    unused tail is ignored.
    """

    B: DenseTensor | ScaledOperand
    """Input tensor B.

    The shape of B is (K, sum(N across all groups or TotalN)) if offsets_along is "n" or
    (sum(K across all groups or TotalK), N) if offsets_along is "k" or
    (group_count, K, N) if offsets_along is "m" where M, N, K are the dimensions of the GEMM problem.

    Pass a :class:`~cutlass.operators.ScaledOperand` for a block-scaled input: it
    adds one scale factor tensor, assembled as described on :attr:`A`.
    """

    out: DenseTensor | ScaledOperand
    """Output tensor.

    The shape of out is (sum(M across all groups or TotalM), N) if offsets_along is "m" or
    (M, sum(N across all groups or TotalN)) if offsets_along is "n" or
    (group_count, M, N) if offsets_along is "k" where M, N, K are the dimensions of the GEMM problem.

    Pass a :class:`~cutlass.operators.ScaledOperand` for a quantized output: the
    operator writes one scale factor tensor, which ``offsets`` partitions across
    groups just as it does the quantized tensor.
    """

    accumulator_type: NumericLike
    """Data type of the accumulator."""

    offsets: DenseTensor = field(metadata={"alignment_bytes": 4})
    """Integer tensor describing grouped-problem boundaries."""

    offsets_along: Literal["m", "n", "k"]
    """Logical GEMM dimension partitioned by ``offsets``."""

    offsets_value_divisibility: int = 1
    """A caller-provided divisor of every cumulative boundary in ``offsets``.

    A value ``D`` promises that ``offsets[g] % D == 0`` for every group and
    every invocation using these arguments. A weaker truthful promise is safe,
    but it may exclude Operators that require a stronger alignment guarantee.
    Callers should normally provide the strongest guarantee implied by how
    ``offsets`` are produced, without considering any particular kernel's
    requirement. Leave this as ``1`` when no stronger invariant is known.
    Device offsets are not copied to the host to verify this promise.

    For a block-scaled grouped GEMM the promise has a second consequence. When
    ``D`` is a multiple of the scale-factor padding ``P`` described on :attr:`A`,
    no group needs padding, so the scale-factor block boundaries coincide with
    the data boundaries; Operators that therefore skip deriving them on the
    device become available, and the exact grouped scale extent collapses to
    ``round_up(total, P)``. Such Operators compute the same result, so a stronger
    promise here can only widen the set of candidates.
    """

    accumulate_on_output: bool = False
    """Whether to add each group's product to that group's existing output slice.

    This option is valid only for ``offsets_along="k"``. For group ``g``,
    ``False`` computes ``out[g, :, :] = A_g @ B_g`` and ``True`` computes
    ``out[g, :, :] += A_g @ B_g``. Results from different groups are never
    accumulated into one another.
    """

    epilogue: EpilogueArgumentsBase | None = None
    """Optional custom or fixed epilogue to perform after each grouped GEMM."""

    _VALID_OFFSET_AXES = ("m", "n", "k")
    """Logical GEMM dimensions that ``offsets`` may partition."""

    @staticmethod
    def _validate_offset_axis(offsets_along: str) -> None:
        valid = IndexPtrGroupedGemmArguments._VALID_OFFSET_AXES
        if offsets_along not in valid:
            raise ValueError(
                f"offsets_along must be one of {valid}, got {offsets_along!r}"
            )

    def __init__(
        self,
        A: TensorLike | Operand,
        B: TensorLike | Operand,
        out: TensorLike | Operand,
        accumulator_type: NumericLike,
        offsets: TensorLike | Operand,
        offsets_along: Literal["m", "n", "k"],
        epilogue: EpilogueArgumentsBase | None = None,
        *,
        offsets_value_divisibility: int = 1,
        accumulate_on_output: bool = False,
    ):
        self.A = _operand_or_dense(A).copy()
        self.B = _operand_or_dense(B).copy()
        self.out = _operand_or_dense(out).copy()
        self.accumulator_type = accumulator_type
        self.offsets = _operand_or_dense(offsets).copy()
        self.offsets_along = offsets_along
        self.offsets_value_divisibility = offsets_value_divisibility
        self.accumulate_on_output = accumulate_on_output
        # Copy so the caller keeps reusable epilogue arguments.
        self.epilogue = None if epilogue is None else epilogue.copy()
        super().__init__()

    @classmethod
    def _numeric_like_field_names(cls) -> tuple[str, ...]:
        return ("accumulator_type",)

    def _validate(self) -> None:
        for name, operand in (("A", self.A), ("B", self.B), ("out", self.out)):
            shape = getattr(operand, "shape", None)
            if shape is None or len(shape) not in (2, 3):
                raise ValueError(f"{name} must be a tensor of rank 2 or 3, got {shape}")

        offsets_shape = getattr(self.offsets, "shape", None)
        if offsets_shape is None or len(offsets_shape) != 1:
            raise ValueError(f"offsets must be a tensor of rank 1, got {offsets_shape}")
        if isinstance(self.offsets, DenseTensor):
            _validate_integer_dense_tensor(self.offsets, name="offsets")
        self._validate_offset_axis(self.offsets_along)
        if (
            isinstance(self.offsets_value_divisibility, bool)
            or not isinstance(self.offsets_value_divisibility, int)
            or self.offsets_value_divisibility <= 0
        ):
            raise ValueError(
                "offsets_value_divisibility must be a positive integer, "
                f"got {self.offsets_value_divisibility!r}"
            )
        if self.accumulate_on_output and self.offsets_along != "k":
            raise ValueError(
                "accumulate_on_output is only supported for offsets_along='k'"
            )

        # The offset axis fixes the allowed rank of each operand (A, B, out).
        allowed_ranks = {
            "m": {"A": (2,), "B": (3,), "out": (2,)},
            "n": {"A": (3,), "B": (2,), "out": (2,)},
            "k": {"A": (2,), "B": (2,), "out": (3,)},
        }[self.offsets_along]
        group_count = offsets_shape[0]
        for name, operand in (("A", self.A), ("B", self.B), ("out", self.out)):
            ranks = allowed_ranks[name]
            shape = operand.shape
            if len(shape) not in ranks:
                expected = " or ".join(f"{rank}" for rank in ranks)
                raise ValueError(
                    f"{name} must be a tensor of rank {expected} when "
                    f"offsets_along={self.offsets_along!r}, got {shape}"
                )
            # A rank-3 operand is per-group and must be laid out group-first
            # as (group_count, rows, cols).
            if len(shape) == 3 and shape[0] != group_count:
                raise ValueError(
                    f"{name} is a 3D operand and must be laid out as "
                    f"(group_count, rows, cols) with group_count={group_count}, "
                    f"got {shape}"
                )

        if isinstance(self.epilogue, PerGroupScaleEpilogueArguments):
            for scale_name, global_scale in (
                ("global_scale_a", self.epilogue.global_scale_a),
                ("global_scale_b", self.epilogue.global_scale_b),
            ):
                if global_scale is not None and global_scale.shape != (group_count,):
                    raise ValueError(
                        f"{scale_name} must have shape ({group_count},), "
                        f"got {global_scale.shape}"
                    )

        self._validate_problem_shapes()

    def _validate_problem_shapes(self) -> None:
        """Validate the shared GEMM dimensions and per-group operand count."""
        match self.offsets_along:
            case "m":
                M, A_K = self.A.shape
                L, B_K, N = self.B.shape
                expected_out_shape = (M, N)
            case "n":
                L, M, A_K = self.A.shape
                B_K, N = self.B.shape
                expected_out_shape = (M, N)
            case "k":
                M, A_K = self.A.shape
                B_K, N = self.B.shape
                L = self.out.shape[0]
                expected_out_shape = (L, M, N)
            case _:
                raise ValueError(f"Unsupported offsets_along {self.offsets_along!r}")

        if L == 0:
            raise ValueError("At least one grouped GEMM problem is required.")
        if B_K != A_K:
            raise ValueError(f"A and B must have the same K; got {A_K} and {B_K}.")
        # A fused epilogue may transform the GEMM result shape, for example by
        # reducing it or by combining two accumulator columns with SwiGLU.
        # Its provider owns the corresponding output-shape validation.
        if self.epilogue is None and self.out.shape != expected_out_shape:
            raise ValueError(
                f"out must have shape {expected_out_shape}, got {self.out.shape}."
            )

    def __post_init__(self) -> None:
        super().__post_init__()
        self._validate()


@dataclass
class GroupedGemmArguments(IndexPtrGroupedGemmArguments):
    """Deprecated compatibility interface for M-offset grouped GEMM.

    Use :class:`IndexPtrGroupedGemmArguments` with ``offsets_along="m"``.
    """

    def __init__(
        self,
        A: TensorLike | Operand,
        B: TensorLike | Operand,
        out: TensorLike | Operand,
        accumulator_type: NumericLike,
        offsets: TensorLike | Operand,
        epilogue: EpilogueArgumentsBase | None = None,
    ):
        warnings.warn(
            "GroupedGemmArguments is deprecated; use "
            "IndexPtrGroupedGemmArguments(..., offsets_along='m') instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        super().__init__(
            A=A,
            B=B,
            out=out,
            accumulator_type=accumulator_type,
            offsets=offsets,
            offsets_along="m",
            epilogue=epilogue,
        )



def _is_integer_dense_tensor(tensor: DenseTensor) -> bool:
    dtype = getattr(tensor.tensor, "dtype", None)
    try:
        return issubclass(to_cutlass_type(dtype), Integer)
    except (KeyError, TypeError):
        # NumPy-compatible integer dtypes expose a kind of "i" or "u".
        return getattr(dtype, "kind", None) in ("i", "u")


def _validate_integer_dense_tensor(tensor: DenseTensor, *, name: str) -> None:
    if not _is_integer_dense_tensor(tensor):
        raise ValueError(f"{name} must have an integer dtype")
