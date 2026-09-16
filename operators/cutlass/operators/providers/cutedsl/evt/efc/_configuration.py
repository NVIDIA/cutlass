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
from ._helpers import log, maximum, minimum
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
                return 1
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
                return 1
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

    def identity(self, x):
        """Identity activation function: f(x) = x"""
        match self.phase:
            case Phase.ParameterAnalysis:
                return 1
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
                return 1
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
                return 1
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
                return 1
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
                return 1
            case Phase.ThreadOperation:
                # sigmoid(x) = 1 / (1 + exp(-x))
                # Equivalent to torch.sigmoid: compute in f32 and round
                # once back to the element type, so an f16 sigmoid is
                # bitwise-identical to torch's (which uses f32 opmath
                # internally for half-precision inputs).
                xf = x.to(cutlass.Float32) if x.dtype.width < 32 else x
                return (1.0 / (1.0 + cutlass.cute.exp(-xf))).to(x.dtype)
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
                return 1
            case Phase.ThreadOperation:
                # silu(x) = x * sigmoid(x)
                return x * self.sigmoid(x)
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
                return 1
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
                return 1
            case Phase.ThreadOperation:
                # Use self.full_like to have all the computation done with
                # the same type as x element type.
                # GELU approximation: 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3)))
                # Using a simpler approximation for CuTe
                sqrt_2_over_pi = self.full_like(x, 0.7978845608028654)
                return (
                    self.full_like(x, 0.5)
                    * x
                    * (
                        self.full_like(x, 1)
                        + cutlass.cute.tanh(
                            sqrt_2_over_pi
                            * (x + self.full_like(x, 0.044715) * x * x * x)
                        )
                    )
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
