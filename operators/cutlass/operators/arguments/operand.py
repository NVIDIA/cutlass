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

import enum
from dataclasses import dataclass, field
from enum import auto as enum_auto
from functools import cached_property
from typing import Any

from cutlass.operators.arguments.base import Operand
from cutlass.operators.typing import NumericLike, TensorLike
from cutlass.operators.utils.common import ceil_div, round_up
from cutlass.operators.utils.dtype import to_cutlass_type


@dataclass
class DenseTensor(Operand):
    """An operand encapsulating a simple, single dense tensor."""

    tensor: TensorLike

    @classmethod
    def _tensor_like_field_names(cls) -> tuple[str, ...]:
        return ("tensor",)

    def __copy__(self) -> DenseTensor:
        return DenseTensor(self.tensor)

    def __getattr__(self, attr: str) -> Any:
        if hasattr(self.tensor, attr):
            return getattr(self.tensor, attr)
        else:
            raise AttributeError(
                f"'{self.__class__.__name__}' object has no attribute '{attr}'"
            )

    # Without these, passing a DenseTensor in place of an unwrapped tensor
    # raised TypeError on Python 3.12+: the TensorLike check ignores __getattr__.
    def __dlpack__(self, *, stream: Any = None) -> Any:
        """Return a DLPack capsule for the wrapped tensor."""
        return self.tensor.__dlpack__(stream=stream)

    def __dlpack_device__(self) -> tuple[int, int]:
        """Return the DLPack device type and id of the wrapped tensor."""
        return self.tensor.__dlpack_device__()


@dataclass
class ScaledOperand(Operand):
    """An operand whose logical value is a quantized tensor multiplied by a tensor of scale factors.

    A ``ScaledOperand`` encapsulates physical :attr:`quantized` and :attr:`scale`
    tensors that together represent the logical value ``scale * quantized``:
    each entry of :attr:`scale` broadcasts and multiplies a contiguous block
    of :attr:`quantized`, where the block shape is given by :attr:`mode`.

    This Operand is typically used to express narrow-precision formats (such as
    OCP MXFP8 / MXFP4 and NVIDIA NVFP4), which store the data as a quantized
    narrow-precision tensor multiplied by a separate tensor of scale factors that recover
    dynamic range.

    The scale :attr:`mode` and :attr:`swizzle` describe the physical
    layout of the scale tensor.

    The :attr:`mode` describes how scale factors are broadcast over the quantized tensor,
    and therefore determines its size. It's usually dictated by the data format you
    seek to represent -- MXFP8 / MXFP4 / NVFP4 require specific scale modes.
    See :class:`ScaleMode` for more details.

    The :attr:`swizzle` describes the in-memory layout of the scale tensor.
    It's usually dictated by the hardware architecture -- for example, Blackwell block-scaled MMAs
    require a specific swizzle layout, and most kernels using them require the input to be
    pre-arranged in this layout.
    See :class:`ScaleSwizzleMode` for more details.

    Example:

        .. code-block:: python

            quantized_A = torch.randn(M, K, dtype=torch.float8_e4m3fn, device="cuda")
            scale_A = torch.randn(M, K // 32, dtype=torch.float8_e8m0fnu, device="cuda")
            A = ScaledOperand(
                quantized_A, scale_A, ScaleMode.Blockwise1x32, ScaleSwizzleMode.Swizzle32x4x4,
            )

    See Also:
        - :class:`ScaleMode`: granularity of the scaling, and the
          format-to-mode mapping.
        - :class:`ScaleSwizzleMode`: in-memory layout of the scale tensor.

    References:
        - `NVIDIA cuBLAS documentation for narrow precision data types <https://docs.nvidia.com/cuda/cublas/#narrow-precision-data-types-usage>`_
    """

    quantized: DenseTensor
    """Narrow-precision tensor holding the quantized values.

    The dequantized logical value is ``scale * quantized``: each scale factor broadcasts over a block of
    this tensor (block shape given by :attr:`mode`) and multiplies its values.
    """

    scale: DenseTensor
    """Tensor of scale factors.

    Each entry of this tensor broadcasts over a block of :attr:`quantized` and scales it.
    :attr:`mode` defines that broadcast, while :attr:`swizzle` names the required
    physical element order. Together they determine the required element count,
    but they do not define one canonical host tensor shape.

    This tensor must be contiguous and already arranged in the layout named by
    :attr:`swizzle`. :py:meth:`ScaledOperand.numel_scale` returns the required
    element count for one logical quantized shape. A consuming Operator may
    validate capacity and may require a carrier shape that communicates padded
    extents. Neither check validates the physical element order; callers must
    ensure that the values satisfy the swizzle contract.
    """

    mode: ScaleMode | tuple[int, ...]
    """Block shape over which each scale factor is broadcast.

    Typically, a block of quantized-tensor elements share the same scale factor value.
    The logical value of the scaled operand is the result of broadcasting
    the scale factor along the block shape described by ``mode``,
    and then multiplying it element-wise with the quantized tensor.

    This may be a :class:`ScaleMode` enum for commonly used block shapes, or
    a bare ``(L, M, K)`` tuple for custom block shapes.
    For instance, ``(1, 1, 32)`` means that each scale factor covers 32 elements
    along the K axis, and 1 element along the L and M axes.
    """

    swizzle: ScaleSwizzleMode
    """In-memory layout of the scale factor tensor.

    The scale factor tensor is sometimes required to be stored in a specific swizzled layout,
    often dictated by the hardware MMA's contract.
    """

    def __init__(
        self,
        quantized: TensorLike | DenseTensor,
        scale: TensorLike | DenseTensor,
        mode: ScaleMode | tuple[int, ...],
        swizzle: ScaleSwizzleMode,
    ):
        self.quantized = _operand_or_dense(quantized).copy()
        self.scale = _operand_or_dense(scale).copy()
        self.mode = mode
        self.swizzle = swizzle

    def __copy__(self) -> ScaledOperand:
        # Tensor operands must be recursively copied because they are Operands.
        return ScaledOperand(
            self.quantized.copy(),
            self.scale.copy(),
            self.mode,
            self.swizzle,
        )

    def __getattr__(self, attr: str) -> Any:
        if hasattr(self.quantized, attr):
            return getattr(self.quantized, attr)
        else:
            raise AttributeError(
                f"'{self.__class__.__name__}' object has no attribute '{attr}'"
            )

    @staticmethod
    def numel_scale(
        quantized_shape: tuple[int, ...],
        mode: ScaleMode | tuple[int, ...],
        swizzle: ScaleSwizzleMode,
    ) -> int:
        """Return the canonical scale element count for ``quantized_shape``.

        ``quantized_shape`` is ``(L, outer, K)`` for a 3D operand, where ``outer``
        is ``M`` for an A-side scale and ``N`` for a B-side scale. One scale factor
        covers ``V`` elements along ``K``, so the scale tensor has logical shape
        ``(L, outer, ceil_div(K, V))``.

        Returned value depends on ``swizzle``:

        - :attr:`ScaleSwizzleMode.SwizzleNone`:
          ``L * outer * ceil_div(K, V)``
        - :attr:`ScaleSwizzleMode.Swizzle32x4x4`:
          ``L * round_up(outer, 128) * round_up(ceil_div(K, V), 4)``

        where ``V = ScaleMode.numel(mode)`` is the number of quantized-tensor
        elements covered by one scale factor.

        This is the count corresponding to one logical ``quantized_shape``. When
        grouped scale storage is assembled by padding and concatenating per-group
        blocks, call ``numel_scale`` for each group's logical shape and sum the
        results. This generally differs from calling ``numel_scale`` once with the
        concatenated shape. See :attr:`IndexPtrGroupedGemmArguments.A` for details.

        Args:
            quantized_shape (tuple[int, ...]): Logical shape of the operand the
                scale will be paired with, as ``(L, outer, K)`` or
                ``(outer, K)``.
            mode (ScaleMode | tuple[int, ...]): Block shape of the scaling.
            swizzle (ScaleSwizzleMode): In-memory layout of the scale tensor.

        Returns:
            int: Required number of scale-factor elements.

        Raises:
            ValueError: If ``quantized_shape`` is not rank 2 or 3, or ``swizzle``
                is not a recognised :class:`ScaleSwizzleMode`.
        """
        if len(quantized_shape) == 3:
            L, outer, K = quantized_shape
        elif len(quantized_shape) == 2:
            L = 1
            outer, K = quantized_shape
        else:
            raise ValueError(
                f"quantized_shape must be rank 2 or 3, got rank {len(quantized_shape)}: {quantized_shape}"
            )

        V = ScaleMode.numel(mode)
        K_blocks = ceil_div(K, V)

        match swizzle:
            case ScaleSwizzleMode.SwizzleNone:
                return L * outer * K_blocks
            case ScaleSwizzleMode.Swizzle32x4x4:
                return L * round_up(outer, 128) * round_up(K_blocks, 4)
            case _:
                raise ValueError(f"Unrecognised ScaleSwizzleMode: {swizzle}")


class ScaleMode(enum.Enum):
    """An enum over commonly used block scaling modes for a :class:`ScaledOperand`.

    Each member's value is a ``(batch, row, col)`` tuple giving the
    shape of the block of quantized-tensor elements that share a scale factor.
    Each scale factor is broadcast & multiplied over this block of quantized-tensor
    elements.

    For block shapes that are not enumerated here, bare ``(batch, row, col)``
    tuples are also accepted as :attr:`ScaledOperand.mode`

    See Also:
        - :class:`ScaledOperand`: the operand that consumes this enum.
        - :class:`ScaleSwizzleMode`: in-memory layout of the scale tensor.
    """

    Blockwise1x16 = (1, 1, 16)
    """Scale over ``(1, 1, 16)`` block. Used by NVIDIA NVFP4 (FP8 E4M3 scale dtype)."""

    Blockwise1x32 = (1, 1, 32)
    """Scale over ``(1, 1, 32)`` block. Used by OCP MXFP8 / MXFP4 (E8M0 scale dtype)."""

    @classmethod
    def from_string(cls, value: str) -> ScaleMode:
        """Return the scale mode matching a profiler CLI spelling.

        Accepted values (case-insensitive):
            - ``"1x16"`` maps to :attr:`Blockwise1x16`.
            - ``"1x32"`` maps to :attr:`Blockwise1x32`.

        Args:
            value (str): Scale-mode spelling to parse.

        Returns:
            ScaleMode: Matching scale mode.

        Raises:
            ValueError: If ``value`` does not name a supported scale mode.
        """
        normalized = value.casefold()
        by_label = {str(mode).casefold(): mode for mode in cls}
        try:
            return by_label[normalized]
        except KeyError as e:
            raise ValueError(
                f"Invalid scale mode: {value!r}. Supported: {', '.join(by_label)}"
            ) from e

    @staticmethod
    def compare(
        mode1: ScaleMode | tuple[int, ...], mode2: ScaleMode | tuple[int, ...]
    ) -> bool:
        """Return whether two scale modes describe the same scaling.

        Allows mixed comparisons between :class:`ScaleMode` enums and bare
        tuples, and tolerates differing tuple lengths as long as the longer
        tuple has leading ``1`` s for the extra positions (so that, e.g.,
        ``(1, 1, 16) == (1, 16)``).

        Args:
            mode1 (ScaleMode | tuple[int, ...]): First mode.
            mode2 (ScaleMode | tuple[int, ...]): Second mode.

        Returns:
            bool: ``True`` if ``mode1`` and ``mode2`` describe the same scaling.
        """
        if isinstance(mode1, ScaleMode) and isinstance(mode2, ScaleMode):
            return mode1.value == mode2.value

        # One of the two modes is a tuple. Use tuple comparison and allow
        # for different lengths as long as long as the longer tuple contains
        # only 1s for the extra leading positions (i.e., allow (1,1,16) == (1, 16))
        tuple1 = mode1 if isinstance(mode1, tuple) else mode1.value
        tuple2 = mode2 if isinstance(mode2, tuple) else mode2.value

        if len(tuple1) == len(tuple2):
            return tuple1 == tuple2
        elif len(tuple1) < len(tuple2):
            padding = (1,) * (len(tuple2) - len(tuple1))
            return padding + tuple1 == tuple2
        else:
            padding = (1,) * (len(tuple1) - len(tuple2))
            return padding + tuple2 == tuple1

    def __eq__(self, other: ScaleMode | tuple[int, ...]) -> bool:
        return ScaleMode.compare(self, other)

    def __ne__(self, other: ScaleMode | tuple[int, ...]) -> bool:
        return not ScaleMode.compare(self, other)

    def __getitem__(self, index: int) -> int:
        return self.value[index]

    def __len__(self) -> int:
        return len(self.value)

    @staticmethod
    def _format_block_shape(block: tuple[int, ...]) -> str:
        """Return a compact ``AxBxC`` label, collapsing leading ``1`` s.

        Matches member naming and :meth:`compare` padding, e.g.
        ``(1, 1, 16)`` → ``"1x16"``.
        """
        dims = list(block)
        while len(dims) > 2 and dims[0] == 1:
            dims.pop(0)
        return "x".join(str(d) for d in dims)

    def __str__(self) -> str:
        """Return the compact row-by-column block shape used by the profiler CLI."""
        return self._format_block_shape(self.value)

    @staticmethod
    def numel(scale: ScaleMode | tuple[int, ...]) -> int:
        """Return the number of quantized-tensor elements scaled by one scale factor.

        For a scale mode of block shape ``(L, M, K)``, this is the block volume
        ``L * M * K`` -- the number of contiguous elements in a quantized tensor
        that share (and are multiplied by) the same scale factor.

        Args:
            scale (ScaleMode | tuple[int, ...]): Scale mode whose tuple entries
                give the block shape.

        Returns:
            int: Product of the entries of ``scale`` (e.g.
            ``numel(Blockwise1x32) == 32``).
        """
        res = 1
        for val in scale:
            res *= val
        return res


class ScaleSwizzleMode(enum.Enum):
    """In-memory layout of the scale tensor in a :class:`ScaledOperand`.

    Hardware MMAs that consume block-scaled inputs typically require their
    scale tensors to be stored in a specific non-trivial layout.

    ``ScaleSwizzleMode`` indicates that scale factors inside a :class:`ScaledOperand`
    are already stored in one of those specific layouts.

    Each Operator validates the contiguity and capacity required by its
    addressing scheme, but does not inspect or rearrange scale values. The
    producer of the scale tensor, typically a quantizer, is responsible for
    writing values in the named layout.

    See Also:
        - :class:`ScaledOperand`: the operand that consumes this enum.
        - :class:`ScaleMode`: granularity of the scaling.
        - PyTorch :class:`torch.nn.functional.SwizzleType`, which this enum closely resembles.
    """

    SwizzleNone = enum_auto()
    """Scale tensor stored in the natural ordering implied by :class:`ScaleMode`.

    For an ``(L, M, K)`` operand at mode ``(1, 1, V)``, this is a tensor of
    ``L * M * (K // V)`` scale factors with one value per ``mode`` block.
    """

    Swizzle32x4x4 = enum_auto()
    """1D block-scaling layout dictated by Blackwell ``tcgen05.mma`` block-scaled MMAs.

    This is used for MXFP8 / MXFP4 / NVFP4 GEMMs on Blackwell.
    Under this layout, each tile contains 128x4 scale factors, and the 128 rows are
    interleaved in groups of 32, matching the warp-group structure of the Blackwell tensor core.

    For a quantized tensor of shape ``(L, M, K)`` and a scale vector size of V,
    the scale tensor is required to have ``L * round_up(M, 128) * round_up(ceil_div(K, V), 4)``
    elements.

    References:
        - `NVIDIA cuDNN: The 128x4 Tiled Layout for Block Scaling Factors <https://nvidia.github.io/cudnn-frontend/mxfp8-scale-factor-128x4-layout/>`_
        - `NVIDIA cuBLAS: 1D Block Scaling Factors Layout <https://docs.nvidia.com/cuda/cublas/#d-block-scaling-factors-layout>`_
    """

    def __str__(self) -> str:
        """Return the compact swizzle-layout spelling used by the profiler CLI."""
        return self.name.removeprefix("Swizzle").lower()

    @classmethod
    def from_string(cls, value: str) -> ScaleSwizzleMode:
        """Return the scale swizzle matching a profiler CLI spelling.

        Accepted values (case-insensitive):
            - ``"none"`` maps to :attr:`SwizzleNone`.
            - ``"32x4x4"`` maps to :attr:`Swizzle32x4x4`.

        Args:
            value (str): Scale-swizzle spelling to parse.

        Returns:
            ScaleSwizzleMode: Matching scale swizzle.

        Raises:
            ValueError: If ``value`` does not name a supported scale swizzle.
        """
        normalized = value.casefold()
        by_label = {str(mode).casefold(): mode for mode in cls}
        try:
            return by_label[normalized]
        except KeyError as e:
            raise ValueError(
                f"Unsupported scale swizzle: {value!r}. Supported: {', '.join(by_label)}"
            ) from e


def _operand_or_dense(
    operand: TensorLike | Operand,
) -> Operand:
    """If operand is already a ``Operand``, return it. Otherwise, wrap it in a ``DenseTensor``.

    This is used for convenience interfaces to avoid needing to wrap dense tensors in a ``DenseTensor``
    class.

    Args:
        operand (TensorLike | Operand): The operand to convert

    Returns:
        Operand: The operand wrapped in a ``DenseTensor`` if it is a ``TensorLike``, otherwise the operand itself

    Raises:
        TypeError: If the operand is not a ``Operand`` or ``TensorLike``
    """
    if isinstance(operand, Operand):
        return operand
    if isinstance(operand, TensorLike):
        return DenseTensor(operand)
    raise TypeError(
        f"Expected operand to be a Operand or TensorLike, got {type(operand)}"
    )



def _dense_tensor(
    tensor: TensorLike | DenseTensor, *, name: str = "tensor"
) -> DenseTensor:
    """Normalize a tensor-like value while rejecting non-dense operands."""
    operand = _operand_or_dense(tensor)
    if not isinstance(operand, DenseTensor):
        raise TypeError(
            f"{name} must be a TensorLike or DenseTensor, got {type(tensor)}"
        )
    return operand



