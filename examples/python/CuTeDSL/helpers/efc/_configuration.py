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

"""EFC dispatch object passed to user epilogue functions.

Routes method calls between CuTe DSL intrinsics and PyTorch
reference operators based on the current ``Phase``.  Exposed on
the ``EFC`` namespace as ``EFC.Configuration`` via a ``ClassVar``
alias declared in ``_base.py``.
"""

# This is not to use module annotations from a future version but to change the type system to postpone the evaluation of annotations,
# about forward declaration and lazy type checking.
# See https://docs.python.org/3/library/__future__.html#future__.annotations and https://peps.python.org/pep-0563/.
from __future__ import annotations

import types
import typing

import cutlass

"""
CUTLASS EFC Framework
"""
from ._helpers import (
    ACTIVATION_FUNCTIONS,
    SplitPart,
    analysis_result_of,
    check_accum_split_fragment,
    log,
    maximum,
    minimum,
)
from ._phase import Phase
from ._remap import torch_tensor_remap_modes
from ._tensor import Tensor, Transport

if typing.TYPE_CHECKING:
    # Annotation-only reference to ``EFC`` from ``_base``; importing
    # it at runtime would be circular (``_base`` imports
    # ``Configuration`` from this module to populate the
    # ``EFC.Configuration`` class-attribute alias).  ``from __future__
    # import annotations`` keeps the parameter / attribute annotations
    # below as strings, so ``EFC`` is only resolved by type checkers.
    from ._base import EFC


def _sigmoid_f32(xf):
    """``1 / (1 + exp(-x))`` on a float32 fragment, the kernel's sigmoid.

    Shared by ``Configuration.sigmoid`` and ``Configuration.silu`` so the
    gated unit multiplies the unrounded float32 sigmoid.
    """
    return 1.0 / (1.0 + cutlass.cute.exp(-xf))


class Configuration:
    """Specialize the epilogue function provided by the user to be called in
    the compute kernel customization point at a given phase."""

    # Reduction-op aliases so user epilogues can write
    # ``op=efc_config.MAX`` instead of ``op=cute.ReductionOp.MAX``,
    # avoiding an otherwise-unnecessary ``cutlass.cute`` import in the
    # epilogue's defining module.  The full ``cute.ReductionOp`` enum
    # is exposed; the actually-implemented subset is gated separately
    # by ``_SUPPORTED_REDUCE_OPS`` in ``_tensor.py``, so writing
    # ``op=efc_config.MUL`` raises a clear ``ValueError`` from there
    # rather than an ``AttributeError`` here.
    ADD = cutlass.cute.ReductionOp.ADD
    MUL = cutlass.cute.ReductionOp.MUL
    MAX = cutlass.cute.ReductionOp.MAX
    MIN = cutlass.cute.ReductionOp.MIN

    # Re-export each ``Transport`` member directly on the class so
    # user epilogue bodies can reach them via the ``efc_config``
    # parameter they already receive, without needing a separate
    # ``from helpers.efc import Transport`` line:
    #
    #     v = v + bias.load(via=efc_config.SYNC_GMEM_LOAD)
    #     D.store(v, via=efc_config.SYNC_GMEM_STORE)
    #
    # The module-level import path remains available for users who
    # prefer the qualified ``Transport.SYNC_GMEM_LOAD`` form.
    TMA = Transport.TMA
    SYNC_GMEM_LOAD = Transport.SYNC_GMEM_LOAD
    SYNC_GMEM_STORE = Transport.SYNC_GMEM_STORE
    ASYNC_GMEM_LOAD = Transport.ASYNC_GMEM_LOAD

    def __init__(self, efc: EFC, phase: Phase, *args):
        """According to the phase, args represent various things. For:
        - Phase.ParameterAnalysis:
          - args is empty and not used;
        - Phase.ThreadOperation:
          - args[0] is the epilogue_context;
        - Phase.PyTorchEvaluation:
          - args[0] is the matrix multiplication result as a torch.Tensor;
          - args[1] is a dict mapping argument names to the arguments, like
            the scalars or torch.Tensor. It is later extended when
            remap_modes() is used.
        """
        self.efc = efc
        self.phase = phase
        self._remap_cache = {}
        match self.phase:
            case Phase.ThreadOperation:
                self.epilogue_context = args[0]

            case Phase.PyTorchEvaluation:
                self.accum_value = args[0]
                self.args = args[1]

        self.arguments = [
            # These are the original epilogue function parameters, it does
            # not include synthetic arguments used for tensor broadcast for
            # example.
            self._argument(name)
            for name in efc.epilogue_parameter_names
        ]

    def _argument(self, name):
        """Generate the argument used by the specialized epilogue with the
        given name."""
        if self.efc.parameter_attributes[name].is_tensor:
            # Delegate the phase-related behavior to the proxy Tensor object
            # itself.
            return Tensor(self.phase, name, self.efc, self)
        # Otherwise, we have a dynamic scalar parameter.
        match self.phase:
            case Phase.ParameterAnalysis:
                # Use some dummy value during introspection phase.
                return cutlass.Float32(42).to(self.efc.operation.epi_dtype)

            case Phase.ThreadOperation:
                # Return directly the real kernel parameter with the same name.
                return cutlass.Float32(self.efc.kernel.parameter[name]).to(
                    self.efc.operation.epi_dtype
                )

            case Phase.PyTorchEvaluation:
                # Just use the provided argument.
                return self.args[name]

            case _:
                raise NotImplementedError(
                    f"argument({name}) not implemented for phase {self.phase}"
                )

    def __call__(self):
        """Execute the epilogue provided by the end-user with some specific
        arguments crafted for the current phase.

        Pass self as an argument, to be seen as `efc_config`, a way to
        access the EFC instance and its properties."""
        log(
            f"Configuration.__call__ evaluate the user EFC function {self.phase = } {self.arguments = }"
        )
        return self.efc.epilogue_function_configuration(self, *self.arguments)

    def accum(self):
        """Provide the accumulator value to the user."""
        log(f"Configuration.accum {self.phase = }")
        match self.phase:
            case Phase.ParameterAnalysis:
                log("Configuration.accum ParameterAnalysis 42!")
                # The answer to anything.
                return cutlass.Float32(42)

            case Phase.ThreadOperation:
                log(
                    f"Configuration.accum ThreadOperation {self.epilogue_context.acc_vec = }"
                )
                return self.epilogue_context.acc_vec

            case Phase.PyTorchEvaluation:
                log(f"Configuration.accum PyTorchEvaluation {self.accum_value = }")
                return self.accum_value

            case _:
                raise NotImplementedError(
                    f"accum() not implemented for phase {self.phase}"
                )

    def gated(self, gate_activation: str) -> object:
        """The gated linear unit ``up * gate_activation(gate)``.

        Splits the accumulator in two along N -- the gate half first, the
        up half second -- and applies one of the built-in activations to
        the gate::

            D.store(efc_config.gated("silu"))    # SwiGLU

        The result has half the accumulator's elements, so ``D`` is half
        the output's N.

        Clamped or per-half-scaled variants need the halves themselves;
        use ``accum_split`` for those.

        :param gate_activation: Name of the activation to gate with, one
            of ``ACTIVATION_FUNCTIONS``.
        :type gate_activation: str
        :return: The gated result.
        :raises ValueError: If ``gate_activation`` is not a built-in
            activation.
        """
        if gate_activation not in ACTIVATION_FUNCTIONS:
            raise ValueError(
                f"gated() needs one of {ACTIVATION_FUNCTIONS}, got {gate_activation!r}."
            )
        gate, up = self.accum_split(2)
        return up * getattr(self, gate_activation)(gate)

    def swiglu(self) -> object:
        """SwiGLU: ``up * silu(gate)``.  See ``gated``."""
        return self.gated("silu")

    def geglu(self) -> object:
        """GeGLU: ``up * gelu(gate)``.  See ``gated``."""
        return self.gated("gelu")

    def reglu(self) -> object:
        """ReGLU: ``up * relu(gate)``.  See ``gated``."""
        return self.gated("relu")

    def accum_split(self, num_parts: int) -> tuple:
        """Split the accumulator into ``num_parts`` interleaved parts along N.

        Part ``i`` holds the accumulator elements whose N index is
        congruent to ``i`` modulo ``num_parts``::

            gate, up = efc_config.accum_split(2)
            D.store(up * efc_config.silu(gate))

        Each part has ``1 / num_parts`` of the accumulator's elements, so
        a tensor written from them is ``num_parts`` times narrower along N
        than the accumulator tile.

        :param num_parts: Number of interleaved parts, at least 2.
        :type num_parts: int
        :return: A ``num_parts``-tuple of accumulator parts.
        :rtype: tuple
        :raises ValueError: If ``num_parts`` is not a usable split factor
            for the accumulator fragment.
        """
        # Validate before touching any phase state, so the check does not
        # depend on the dispatch below.
        if not isinstance(num_parts, int) or num_parts < 2:
            raise ValueError(
                f"accum_split() needs an integer num_parts >= 2, got {num_parts!r}."
            )
        log(f"Configuration.accum_split {self.phase = } {num_parts = }")

        match self.phase:
            case Phase.ParameterAnalysis:
                # One narrowed thread-to-value map is built per kernel, so a
                # second factor would leave one of the two sets of parts with
                # a map built for the other's width.
                previous = self.efc.accum_split_factor
                if previous is not None and previous != num_parts:
                    raise ValueError(
                        f"An epilogue may use one accum_split factor; got "
                        f"{previous} and {num_parts}."
                    )
                # Only phase running before the layouts are fixed, so record
                # the split factor for the host-side output tile sizing.
                self.efc.accum_split_factor = num_parts
                # Marked dummies, so a store of any expression built from
                # them records that its tensor tiles narrower along N.
                return tuple(SplitPart(num_parts) for _ in range(num_parts))

            case Phase.ThreadOperation:
                return self._accum_split_fragment(num_parts)

            case Phase.PyTorchEvaluation:
                # The reference accumulator is (m, n, l), so split on mode 1.
                # An indivisible extent would slice into unequal parts and
                # surface later as an opaque shape mismatch; the thread
                # phase rejects the same split, so match it here.
                n = self.accum_value.shape[1]
                if n % num_parts != 0:
                    raise ValueError(
                        f"accum_split({num_parts}) needs the accumulator's n "
                        f"extent ({n}) to be a multiple of {num_parts}."
                    )
                return tuple(
                    self.accum_value[:, i::num_parts, :] for i in range(num_parts)
                )

            case _:
                raise NotImplementedError(
                    f"accum_split() not implemented for phase {self.phase}"
                )

    def _accum_split_fragment(self, num_parts: int) -> tuple:
        """Take ``num_parts`` strided views of the accumulator register fragment.

        The fragment is one thread's compact run of N-consecutive elements,
        so re-viewing it as ``(num_parts, n // num_parts)`` with stride ``(1, num_parts)`` puts
        part ``i`` at ``[i, None]``.  Cutting the fragment
        rather than the loaded ``TensorSSA`` keeps this in layout space,
        where it emits no instructions.
        """
        if getattr(self.epilogue_context, "accum_split_across_lanes", False):
            return self._accum_split_exchange(num_parts)
        fragment = self.epilogue_context.acc_frag
        # Normally already checked once per kernel by the operation; repeated
        # here so a body reaching this directly still gets the same error.
        n = check_accum_split_fragment(fragment, num_parts)
        interleaved = cutlass.cute.make_tensor(
            fragment.iterator,
            cutlass.cute.make_layout(
                shape=(num_parts, n // num_parts), stride=(1, num_parts)
            ),
        )
        log(f"Configuration._accum_split_fragment interleaved = {interleaved!s}")
        return tuple(
            interleaved[i, None].load().to(self.efc.operation.epi_dtype)
            for i in range(num_parts)
        )

    def _accum_split_exchange(self, num_parts: int) -> tuple:
        """Gather each part from the lane that holds it.

        Each thread's fragment holds only one part's columns, and each
        aligned run of ``num_parts`` lanes (the lanes sharing
        ``lane // num_parts``) holds the parts in order: this thread's
        own part is ``lane % num_parts``, and the lane holding ``part``
        at the same fragment slots is ``lane - own_part + part``
        (established by ``accum_split_across_lanes``).  One index shuffle
        per part and slot gathers all the parts; the fetched value is
        that part by construction.  The lanes of a run gather the same
        values, compute the same results, and store them through the
        ``extend_split_n`` view, whose addresses alias for the whole run
        -- the duplicate writes carry the same bytes.

        The parts keep the fragment's full width: every slot yields a
        result, so the store fragment equals the accumulator's, unlike
        the in-thread split where a part is ``1 / num_parts`` of it.
        """
        epi_dtype = self.efc.operation.epi_dtype
        fragment = self.epilogue_context.acc_frag
        if fragment.element_type.width != 32:
            raise NotImplementedError(
                f"accum_split({num_parts}) across lanes shuffles 32-bit "
                f"values, but the accumulator fragment holds "
                f"{fragment.element_type.__name__}."
            )
        # The fragment is compact and address-ordered (checked once per
        # kernel), so slot i of this thread's flat view pairs with slot i
        # of the lanes holding the other parts.
        # The shuffle moves one 32-bit element at a time.
        n = cutlass.cute.size(fragment)
        flat = cutlass.cute.make_tensor(fragment.iterator, cutlass.cute.make_layout(n))
        lane = cutlass.cute.arch.lane_idx()
        own_part = lane % num_parts
        parts = []
        for part in range(num_parts):
            holder = lane - own_part + part
            gathered = cutlass.cute.make_rmem_tensor(n, fragment.element_type)
            for i in range(n):
                gathered[i] = cutlass.cute.arch.shuffle_sync(flat[i], offset=holder)
            parts.append(gathered.load().to(epi_dtype))
        log(f"Configuration._accum_split_exchange {num_parts = } {n = }")
        return tuple(parts)

    def remap_modes(
        self,
        source: Tensor,
        source_mode_map: tuple,
    ):
        """Remap modes of a source tensor to match the output shape (m, n, l).

        The target shape is implicitly the output tensor shape derived
        from the GEMM input matrices A(m, k, l) and B(n, k, l).

        The source_mode_map is a sequence with a length matching the
        output rank.

        Each element is either an integer defining the mode of the source
        tensor to map at this place or `True` to express that the source
        tensor is broadcast for this mode.
        """
        # Validate that source is an EFC.Tensor proxy, not a raw scalar
        # or some other value passed by mistake.
        if not isinstance(source, Tensor):
            raise TypeError(
                f"remap_modes() expects an EFC.Tensor proxy as source, "
                f"got {type(source).__name__}: {source!r}. "
                f"Use remap_modes on a tensor parameter like "
                f"C.remap_modes[:, 0, 1], not on a scalar."
            )
        # The source must be an actual tensor parameter, not a scalar
        # like alpha or beta.
        if not source.attributes.is_tensor:
            raise ValueError(
                f"remap_modes() source '{source.name}' is a scalar "
                f"parameter, not a tensor. Only tensor parameters can "
                f"be remapped."
            )
        # Remapping an already-remapped tensor is likely a mistake:
        # remap the original source instead.
        if source.attributes.mapped_source is not None:
            raise ValueError(
                f"remap_modes() source '{source.name}' is already a "
                f"remapped view of '{source.attributes.mapped_source}'. "
                f"Remap the original tensor directly instead."
            )
        # Validate source_mode_map element types, bounds and uniqueness
        # early, before they propagate into harder-to-diagnose downstream
        # errors. The implied source rank is the number of int entries
        # (non-broadcast modes).
        int_indices = []
        for i, v in enumerate(source_mode_map):
            if v is True:
                continue
            if not isinstance(v, int):
                raise TypeError(
                    f"source_mode_map[{i}] must be an int or True "
                    f"(broadcast), got {type(v).__name__}: {v!r}."
                )
            int_indices.append(v)
        # The effective source rank is the max index + 1 (not the count
        # of indices), because some source dims may be unused (e.g.
        # size-1 broadcast dims in a tensor like (1, N) where dim 0 is
        # skipped via True).
        source_rank = (max(int_indices) + 1) if int_indices else 0
        # Check bounds. Guard with ``v is not True`` because bool is a
        # subclass of int in Python, so isinstance(True, int) is True.
        for i, v in enumerate(source_mode_map):
            if v is not True and isinstance(v, int) and not (0 <= v < source_rank):
                raise ValueError(
                    f"source_mode_map[{i}] = {v} is out of range for a "
                    f"source tensor of rank {source_rank}. Valid indices "
                    f"are 0..{source_rank - 1}."
                )
        if len(int_indices) != len(set(int_indices)):
            duplicates = sorted(set(v for v in int_indices if int_indices.count(v) > 1))
            raise ValueError(
                f"source_mode_map contains duplicate source mode indices: "
                f"{duplicates}. Each source mode must appear exactly once."
            )
        log(
            f"Configuration.remap_modes {source.name = } {source_mode_map = } {self.phase = }"
        )
        # Construct a new tensor as a remapped view with a mangled name
        # storing all the details.
        mangled_name = (
            f"{source.name}__remapped__{'__'.join([str(e) for e in source_mode_map])}"
        )
        # Return cached result if this exact remapping was already processed.
        # This avoids overwriting the ParameterAttributes entry (which would
        # lose is_read/is_written flags set by earlier .load()/.store() calls)
        # and avoids redundant EFC.Tensor proxy creation and PyTorch remapping.
        if mangled_name in self._remap_cache:
            return self._remap_cache[mangled_name]
        match self.phase:
            case Phase.ParameterAnalysis:
                log("EFC.remap_modes creates and registers a tensor")
                # If the source_mode_map has only broadcast modes, it can be
                # resolved to a scalar instead as an optimization.
                broadcast_only = sum(v is True for v in source_mode_map) == len(
                    source_mode_map
                )
                # Register the new tensor.
                self.efc.parameter_attributes[mangled_name] = (
                    Tensor.ParameterAttributes(
                        is_tensor=True,
                        mapped_source=source.name,
                        source_mode_map=source_mode_map,
                        degenerate_to_scalar=broadcast_only,
                    )
                )

            case Phase.ThreadOperation:
                log("EFC.remap_modes ThreadOperation returns Tensor proxy")
                # Just use the proxy tensor as is, so .load() and .store()
                # can work with it later.

            case Phase.PyTorchEvaluation:
                # Do the real PyTorch tensor remapping on the source
                # tensor using the accumulator shape as the output (m, n, l).
                remapped = torch_tensor_remap_modes(
                    self.args[source.name],
                    tuple(self.accum_value.shape),
                    source_mode_map,
                )
                log(
                    f"EFC.remap_modes PyTorchEvaluation self.args[{source.name}] = {self.args[source.name]}"
                )
                log(f"EFC.remap_modes PyTorchEvaluation {remapped = }")
                # Register the new tensor so it can be used later in an
                # expression.
                self.args[mangled_name] = remapped

            case _:
                raise NotImplementedError(
                    f"remap_modes({mangled_name = }) not implemented for phase {self.phase}"
                )

        # Cache and return the proxy tensor with the mangled name so it can
        # be used later in an expression.
        tensor = Tensor(self.phase, mangled_name, self.efc, self)
        self._remap_cache[mangled_name] = tensor
        return tensor

    # Some helper functions for common operations.

    def maximum(self, x, y):
        """Element-wise maximum of 2 tensors"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x, y)
            case Phase.ThreadOperation:
                return maximum(x, y)
            case Phase.PyTorchEvaluation:
                import torch

                return torch.maximum(x, y)
            case _:
                raise NotImplementedError(
                    f"maximum() not implemented for phase {self.phase}"
                )

    def minimum(self, x, y):
        """Element-wise minimum of 2 tensors"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x, y)
            case Phase.ThreadOperation:
                return minimum(x, y)
            case Phase.PyTorchEvaluation:
                import torch

                return torch.minimum(x, y)
            case _:
                raise NotImplementedError(
                    f"minimum() not implemented for phase {self.phase}"
                )

    # Define some activation functions inspired by:
    # - cutlass/python/cutlass_cppgen/epilogue/epilogue.py
    # - cutlass/python/cutlass_cppgen/backend/epilogue.py

    @staticmethod
    def _in_float32(x, f):
        """Evaluate ``f`` on ``x`` widened to float32, rounded once to ``x``'s type.

        The device evaluates exp, rcp and erf in float32 whatever the
        element type, so a narrow activation is a float32 computation
        with conversions around it.  Keeping one rounding, at the end,
        is torch's rule for half-precision inputs (float32 "opmath"), so
        a float16 or bfloat16 activation matches torch's bit for bit
        when the float32 computations agree.  Rounding an intermediate
        instead loses the result wherever that intermediate falls below
        the narrow type's resolution.

        :param x: Activation input, a fragment load of any float type.
        :param f: The activation on a float32 input.
        :return: ``f(x)`` in ``x``'s element type.
        """
        if x.dtype.width >= 32:
            return f(x)
        return f(x.to(cutlass.Float32)).to(x.dtype)

    def identity(self, x):
        """Identity activation function: f(x) = x"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                return x
            case Phase.PyTorchEvaluation:
                return x
            case _:
                raise NotImplementedError(
                    f"identity() not implemented for phase {self.phase}"
                )

    def relu(self, x):
        """ReLU activation function: f(x) = maximum(0, x)"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                return maximum(x, self.full_like(x, 0))
            case Phase.PyTorchEvaluation:
                import torch

                return torch.nn.functional.relu(x)
            case _:
                raise NotImplementedError(
                    f"relu() not implemented for phase {self.phase}"
                )

    def leaky_relu(self, x, negative_slope=0.01):
        """Leaky ReLU activation function: f(x) = maximum(0, x) + negative_slope * minimum(0, x)"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                # Use self.full_like to have all the computation done with
                # the same type as x element type.
                zero = self.full_like(x, 0)
                return maximum(x, zero) + minimum(x, zero) * self.full_like(
                    x, negative_slope
                )
            case Phase.PyTorchEvaluation:
                import torch

                return torch.nn.functional.leaky_relu(x, negative_slope)
            case _:
                raise NotImplementedError(
                    f"leaky_relu() not implemented for phase {self.phase}"
                )

    def tanh(self, x):
        """Hyperbolic tangent activation function"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                return cutlass.cute.tanh(x)
            case Phase.PyTorchEvaluation:
                import torch

                return torch.tanh(x)
            case _:
                raise NotImplementedError(
                    f"tanh() not implemented for phase {self.phase}"
                )

    def sigmoid(self, x):
        """Sigmoid activation function: f(x) = 1 / (1 + exp(-x))"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                return self._in_float32(x, _sigmoid_f32)
            case Phase.PyTorchEvaluation:
                import torch

                # torch.sigmoid computes internally in fp32
                return torch.sigmoid(x)
            case _:
                raise NotImplementedError(
                    f"sigmoid() not implemented for phase {self.phase}"
                )

    def silu(self, x):
        """SiLU (Swish) activation function: f(x) = x * sigmoid(x)"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                # Not ``x * self.sigmoid(x)``: that rounds the sigmoid to
                # ``x``'s type first, and sigmoid(-17) is 4e-8, below
                # float16's smallest subnormal step.
                return self._in_float32(x, lambda xf: xf * _sigmoid_f32(xf))
            case Phase.PyTorchEvaluation:
                import torch

                return torch.nn.functional.silu(x)
            case _:
                raise NotImplementedError(
                    f"silu() not implemented for phase {self.phase}"
                )

    def hardswish(self, x):
        """Hard Swish activation function: f(x) = x * relu6(x + 3) / 6"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                # Use self.full_like to have all the computation done with
                # the same type as x element type.
                # hardswish(x) = x * minimum(maximum(x + 3, 0), 6) / 6
                relu6 = minimum(
                    maximum(x + self.full_like(x, 3), self.full_like(x, 0)),
                    self.full_like(x, 6),
                )
                return x * relu6 / self.full_like(x, 6)
            case Phase.PyTorchEvaluation:
                import torch

                return torch.nn.functional.hardswish(x)
            case _:
                raise NotImplementedError(
                    f"hardswish() not implemented for phase {self.phase}"
                )

    def gelu(self, x):
        """GELU (Gaussian Error Linear Unit) activation function."""
        match self.phase:
            case Phase.ParameterAnalysis:
                return analysis_result_of(x)
            case Phase.ThreadOperation:
                # The erf form, 0.5 * x * (1 + erf(x / sqrt(2))): the same
                # gelu as the PyTorchEvaluation phase (``F.gelu``'s default)
                # and as the plain ``gelu`` of the CUTLASS Python API
                # (``cutlass::epilogue::thread::GELU``), so one epilogue
                # vocabulary carries one gelu.  The tanh approximation is
                # 4.8e-4 away at its worst (x = -2.7), which a gated
                # unit multiplies by the unbounded up half.
                #
                # In float32 because ``1 + erf`` cancels for negative x:
                # at float16 resolution the sum keeps a few ULPs of the
                # true value, and a gated unit multiplies that error by
                # the up half.
                return self._in_float32(
                    x,
                    lambda xf: (
                        xf
                        * 0.5
                        * (1.0 + cutlass.cute.math.erf(xf * 0.7071067811865476))
                    ),
                )
            case Phase.PyTorchEvaluation:
                import torch

                return torch.nn.functional.gelu(x)
            case _:
                raise NotImplementedError(
                    f"gelu() not implemented for phase {self.phase}"
                )

    def __getattr__(self, name):
        """Called when an attribute or method is not found.

        Hijack this mechanism to dispatch/emulate functions like
        cute.full_like() or torch.full_like() provided inside the epilogue
        function as self.full_like().

        This is required since the epilogue is used not only in a @cute.jit
        or @cute.kernel but also executed in a normal context for analyzing
        the epilogue content and even run in emulation with frameworks like
        PyTorch."""

        def chameleon(self, *args, **kwargs):
            """The great impostor method.

            """
            log(f"Configuration.chameleon {name = } {self.phase = }")
            match self.phase:
                case Phase.ParameterAnalysis:
                    # Just return a value to go on with the fake evaluation, in
                    # the case the function is expected to return a result. It
                    # will be ignored anyway in the opposite case.
                    return 1

                case Phase.ThreadOperation:
                    # In the @cute.kernel context, just use the normal CuTe
                    # implementation.
                    return getattr(cutlass.cute, name)(*args, **kwargs)

                case Phase.PyTorchEvaluation:
                    # In the PyTorch context, call the equivalent function
                    # with the same name.
                    import torch

                    return getattr(torch, name)(*args, **kwargs)

                case _:
                    raise NotImplementedError(
                        f"self.{name} not implemented for phase {self.phase}"
                    )

        # Update the function name to match the requested attribute name.
        chameleon.__name__ = name
        # Return chameleon blessed as a bound method of self.
        return types.MethodType(chameleon, self)
