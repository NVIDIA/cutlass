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
import typing
from collections import OrderedDict
from dataclasses import dataclass
from typing import TYPE_CHECKING

from cutlass.operators.fusion import EmptyTensor, trace, trace_in_out
from cutlass.operators.fusion.ir.store_nodes import ScalarReductionImpl
from cutlass.operators.utils.layout import LayoutType
from cutlass.operators.utils.tensor import TensorWrapper, is_torch_tensor

if TYPE_CHECKING:
    from collections.abc import Callable

    import cutlass.cute as cute
    from cutlass.cute.typing import Numeric


class EpilogueArguments:
    """Describes a user-defined epilogue that is fused on top of the operation described by the primary RuntimeArguments.

    An epilogue fusion is a custom function that performs tensor-level transformations on the
    result of a matrix multiplication. This transformation is fused into the kernel's epilogue,
    which stores the final output.

    ``EpilogueArguments`` encapsulates the epilogue function describing the transformation
    along with its arguments.

    To support flexible definition of epilogues, ``EpilogueArguments`` is
    defined generically as taking in an ``epilogue_fn`` and additional ``kwargs``.

    Under the hood, the AST for ``epilogue_fn`` is parsed to determine the
    operands and outputs of the epilogue. ``kwargs`` must contain Tensors or scalars
    for all operands and outputs in the provided epilogue.

    **Structure of ``epilogue_fn``**

    The ``epilogue_fn`` is a function describing the custom transformation
    on the accumulator tensor (intermediate result before the epilogue).

    The general structure of these functions is:

    .. code-block:: python

        def custom_epi_name(accum, *args) -> TensorType | tuple[TensorType, ...]:
            '''Compute the epilogue.

            # Args:
                accum (TensorType): Result of the primary operation (e.g.
                                ``A @ B`` for a GEMM) before the epilogue.
                *args: Additional tensors or scalars used in the epilogue
                        (e.g. aux tensors).

            # Returns:
                At least one tensor resulting from the epilogue computation.
            '''
            # Do some compute
            return D  # and potentially other values

    ``epilogue_fn`` must be a Python callable (or its string representation)
    that **must** satisfy the following constraints:

    * Takes a first positional argument named ``accum`` -- the result of the
      operation just before the epilogue. For a GEMM, ``accum = A @ B``.
    * Returns at least one tensor resulting from the epilogue. Currently the
      return list must contain at least one output named ``D``.
    * Each argument following ``accum`` is a tensor or scalar to be loaded.
    * Each variable in the return statement is a tensor or scalar to be stored.
    * Operations are represented in static single assignment (SSA) form. This means
      that each variable can be assigned exactly once.

    The underlying implementation of the epilogue in
    the kernel will determine how operands are loaded and stored.

    **Structure of ``kwargs``**

    ``kwargs`` must contain sample Tensors or scalars for all operands and outputs
    in the provided epilogue.
    For example, with an epilogue of:

    .. code-block:: python

        def my_epi(accum, alpha, C, beta):
            F = (accum * alpha) + (C * beta)
            D = relu(F)
            return D, F

    A user would need to construct epilogue arguments as follows:

    .. code-block:: python

        epi_args = EpilogueArguments(
            my_epi,
            alpha=..., C=..., beta=..., D=..., F=...
        )
    """

    def __init__(
        self,
        epilogue_fn: Callable | str,
        **kwargs,
    ):
        epilogue_inputs: list[str] = []
        epilogue_outputs: list[str] = []
        if epilogue_fn is not None:
            # Parse the epilogue_fn AST to get the required input and output arguments
            epilogue_inputs, epilogue_outputs = trace_in_out(epilogue_fn)

        # Get required input and output arguments from kwargs.
        # Deduplicate because a name can appear as both an input parameter
        # and an output (e.g. ``def epi(accum, D): ... return D``).
        self.tensors = OrderedDict()
        # Per-parameter data-transport overrides, keyed by parameter name.
        # A name is present only when the user wrapped its tensor in a
        # ``Load``/``Store`` descriptor; bare tensors default to TMA downstream.
        self.transports: dict[str, Load | Store] = {}
        for kw in dict.fromkeys(epilogue_inputs + epilogue_outputs):
            if kw not in kwargs:
                raise ValueError(
                    f"Argument {kw} is not provided in the kwargs of the EpilogueArguments constructor"
                )
            value = kwargs[kw]
            if isinstance(value, (Load, Store)):
                # Record how this tensor is moved, then unwrap to the bare
                # tensor so tracing, broadcasting and TensorWrapper all keep
                # seeing a plain tensor regardless of the chosen transport.
                self.transports[kw] = value
                value = value.tensor
            self.tensors[kw] = value
            del kwargs[kw]

        if len(kwargs) > 0:
            raise ValueError(
                f"Unexpected keyword arguments for epilogue: {kwargs.keys()}"
            )

        self.epilogue_fn = epilogue_fn

    @property
    def parameters(self) -> list[cute.Tensor | Numeric]:
        """Returns the list of input and output parameters of the epilogue."""
        return list(self.tensors.values())

    @property
    def parameter_names(self) -> list[str]:
        """Returns the list of names of the input and output parameters of the epilogue."""
        return list(self.tensors.keys())

    def _scalar_reduction_destinations(self) -> set[str]:
        """Return the names of outputs that back an all-MNL (scalar) reduction.

        These are the ``StoreNode``s whose ``underlying_impl`` is a
        ``ScalarReductionImpl`` (e.g. ``total`` in ``total = sum(accum)``). The
        EFC kernel folds into them with a cross-CTA atomic and requires a static
        single-element layout, so they must be wrapped with ``static_layout``.

        Returns:
            set[str]: Reduction-destination names (empty if there are none).

        Raises:
            RuntimeError: If the epilogue has not been traced yet.  The only
                caller (``to_tensor_wrappers``) runs right after ``trace``
                (see ``GemmArguments``), so an untraced epilogue here is a
                programming error -- returning an empty set instead would
                silently leave a reduction destination on the default dynamic
                layout, which the atomic fold only rejects much later, inside
                the kernel.
        """
        traced = getattr(self, "traced_epilogue", None)
        if traced is None:
            raise RuntimeError(
                "EpilogueArguments.to_tensor_wrappers() requires the epilogue "
                "to be traced first via EpilogueArguments.trace()."
            )
        return {
            meta.name
            for meta in traced.dag_ir.node_metas_topological_order()
            if isinstance(getattr(meta, "underlying_impl", None), ScalarReductionImpl)
        }

    def to_tensor_wrappers(self, permute: list[int] | None = None):
        """Converts the input and output parameters of the epilogue to TensorWrappers."""
        # Scalar-reduction destinations must reach the kernel as *static*
        # single-element tensors; the default dynamic-layout marking would give
        # them a ``?`` extent that the atomic-fold path rejects.  Only those
        # outputs are forced static -- every other tensor keeps the dynamic
        # layout used for problem-size reuse.
        static_names = self._scalar_reduction_destinations()
        for k, v in self.tensors.items():
            if is_torch_tensor(v):
                if permute is not None:
                    v = v.permute(permute)

                self.tensors[k] = TensorWrapper(v, static_layout=k in static_names)

    def trace(self, accumulator_shape: tuple[int, ...], accumulator_type: Numeric):
        """Traces the epilogue function and generates an internal representation of the epilogue.

        Args:
            accumulator_shape (tuple[int, ...]): The shape of the accumulator tensor. For example, for a GEMM, this would be the shape of the output tensor.
            accumulator_type (Numeric): The datatype of the accumulator tensor.
        """
        accumulator = EmptyTensor(
            element=accumulator_type,
            shape=accumulator_shape,
            layout_tag=LayoutType.RowMajor,
        )
        tensors_for_tracing = {**self.tensors, "accum": accumulator}

        # Parse the AST of the epilogue_fn again, this time with the set of required
        # tensors. This pass converts the epilogue into an internal representation and
        # performs a limited set of correctness checks (e.g., shape matches)
        #
        # Since all current providers are not based on C++ EVT, we do not need to convert
        # the DAG to a tree. If a provider that tightly matches the C++ EVT template structure,
        # this will need to be revisited.
        self.traced_epilogue = trace(
            self.epilogue_fn, tensors_for_tracing, requires_conversion_to_tree=False
        )


# Per-tensor transport descriptors, kept after ``EpilogueArguments`` so the
# top-level concept reads first (they are referenced only at call time).
class Transport(enum.Enum):
    """How a supplemental epilogue tensor moves between GMEM and registers.

    Mirrors the EFC kernel's transport catalog. ``TMA`` stages through shared
    memory; the ``*_GMEM_*`` variants use direct GMEM addressing, either
    synchronous to the issuing thread (``SYNC_GMEM_LOAD`` / ``SYNC_GMEM_STORE``)
    or asynchronous through shared memory via ``cp.async`` (``ASYNC_GMEM_LOAD``).
    """

    TMA = "tma"
    SYNC_GMEM_LOAD = "sync_gmem_load"
    SYNC_GMEM_STORE = "sync_gmem_store"
    ASYNC_GMEM_LOAD = "async_gmem_load"


# Which transports are valid for a read vs. a write, mirroring the EFC kernel.
_LOAD_TRANSPORTS = (Transport.TMA, Transport.SYNC_GMEM_LOAD, Transport.ASYNC_GMEM_LOAD)
_STORE_TRANSPORTS = (Transport.TMA, Transport.SYNC_GMEM_STORE)


@dataclass
class Load:
    """Describe how an epilogue input tensor is read.

    Wrap an :class:`EpilogueArguments` tensor kwarg to override the default
    (TMA) read transport, e.g.
    ``C=ops.Load(C, via=ops.Transport.ASYNC_GMEM_LOAD)``. Passing a bare tensor
    is equivalent to ``Load(tensor)`` (a TMA read).

    Args:
        tensor (TensorLike): The tensor to read.
        via (Transport | str): Read transport; one of ``TMA``,
            ``SYNC_GMEM_LOAD`` or ``ASYNC_GMEM_LOAD``. Strings are accepted.
        num_bits_per_copy (int | None): Transaction width for non-TMA
            transports; ``None`` auto-derives it.
    """

    tensor: typing.Any
    via: Transport | str = Transport.TMA
    num_bits_per_copy: int | None = None

    def __post_init__(self) -> None:
        self.via = Transport(self.via)
        if self.via not in _LOAD_TRANSPORTS:
            raise ValueError(
                f"Load transport must be one of "
                f"{[t.value for t in _LOAD_TRANSPORTS]}, got {self.via.value!r}."
            )
        # ``num_bits_per_copy`` is a transaction width in bits, so it must be an
        # int when set.  ``bool`` is an ``int`` subclass but never a valid width,
        # so reject it too -- otherwise ``num_bits_per_copy=True`` would silently
        # be taken as 1 bit downstream.
        if self.num_bits_per_copy is not None and (
            isinstance(self.num_bits_per_copy, bool)
            or not isinstance(self.num_bits_per_copy, int)
        ):
            raise TypeError(
                "Load num_bits_per_copy must be an int, got "
                f"{type(self.num_bits_per_copy).__name__}."
            )
        # ``num_bits_per_copy`` sizes a direct copy's transaction; TMA derives
        # its own descriptor, so the argument is meaningless there. Reject the
        # combination early rather than silently dropping it downstream.
        if self.via is Transport.TMA and self.num_bits_per_copy is not None:
            raise ValueError(
                "Load num_bits_per_copy is only valid for non-TMA transports, "
                f"not via={self.via.value!r}."
            )


@dataclass
class Store:
    """Describe how an epilogue output tensor is written.

    Wrap an :class:`EpilogueArguments` tensor kwarg to override the default
    (TMA) write transport, e.g.
    ``D=ops.Store(D, via=ops.Transport.SYNC_GMEM_STORE)``. Passing a bare
    tensor is equivalent to ``Store(tensor)`` (a TMA write).

    Args:
        tensor (TensorLike): The tensor to write.
        via (Transport | str): Write transport; one of ``TMA`` or
            ``SYNC_GMEM_STORE``. Strings are accepted.
        num_bits_per_copy (int | None): Transaction width for the direct
            store; ``None`` auto-derives it.
    """

    tensor: typing.Any
    via: Transport | str = Transport.TMA
    num_bits_per_copy: int | None = None

    def __post_init__(self) -> None:
        self.via = Transport(self.via)
        if self.via not in _STORE_TRANSPORTS:
            raise ValueError(
                f"Store transport must be one of "
                f"{[t.value for t in _STORE_TRANSPORTS]}, got {self.via.value!r}."
            )
        # See ``Load.__post_init__``: a bit count must be an int (and not a
        # ``bool``) when set.
        if self.num_bits_per_copy is not None and (
            isinstance(self.num_bits_per_copy, bool)
            or not isinstance(self.num_bits_per_copy, int)
        ):
            raise TypeError(
                "Store num_bits_per_copy must be an int, got "
                f"{type(self.num_bits_per_copy).__name__}."
            )
        # See ``Load.__post_init__``: a TMA store has no caller-set transaction
        # width, so ``num_bits_per_copy`` only makes sense for the direct store.
        if self.via is Transport.TMA and self.num_bits_per_copy is not None:
            raise ValueError(
                "Store num_bits_per_copy is only valid for non-TMA transports, "
                f"not via={self.via.value!r}."
            )
