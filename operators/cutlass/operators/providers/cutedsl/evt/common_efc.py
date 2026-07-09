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

# This is not to use module annotations from a future version but to change the type system to postpone the evaluation of annotations,
# about forward declaration and lazy type checking.
# See https://docs.python.org/3/library/__future__.html#future__.annotations and https://peps.python.org/pep-0563/.
from __future__ import annotations

import dataclasses
import enum
import functools
import inspect
import logging
import os
import types
import typing

import cutlass

"""
CUTLASS EFC Framework
"""

# List of available activation functions in the EFC Configuration class. This
# can be used for example in a CLI using this module.
ACTIVATION_FUNCTIONS = [
    "identity",
    "relu",
    "leaky_relu",
    "tanh",
    "sigmoid",
    "silu",
    "hardswish",
    "gelu",
]

# Some workaround for Python pre-3.12 f-string preventing the use of backslash.
NEWLINE_AND_TAB = "\n\t"
TAB = "\t"

# To have some verbosity, set the CUTE_DSL_EFC_LOG_LEVEL environment variable to
# INFO or even DEBUG before launching this program.
if log_level := os.environ.get("CUTE_DSL_EFC_LOG_LEVEL", None):
    logging.basicConfig(level=getattr(logging, log_level))
logger = logging.getLogger(__name__)


def log(message: str):
    """Helper function to log messages. Change logger.debug to another level
    here if needed.
    """
    logger.debug(message)


def if_debug(function):
    """Execute a function if in debug mode."""
    if logger.isEnabledFor(logging.DEBUG):
        function()


def if_info(function):
    """Execute a function if in info mode."""
    if logger.isEnabledFor(logging.INFO):
        function()


def mark_mlir(message: str):
    """Put some message in MLIR output to make MLIR assembly clearer or trace execution."""
    if_debug(lambda: cutlass.cute.printf(f"mark_mlir: {message}"))


def trace_in_mlir(func):
    """Decorator to trace function entry and exit in MLIR."""

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        function_name = func.__name__
        mark_mlir(f"entering {function_name}")
        result = func(*args, **kwargs)
        mark_mlir(f"leaving {function_name}")
        return result

    return wrapper


def create_named_epilogue(param_names, func):
    """Create a wrapper function with specific parameter names that delegates to an implementation function.

    This function solves a common problem in the EFC (Epilogue Fusion Configuration) framework:
    epilogue functions must have parameters with specific names (e.g., "alpha", "beta", "C", "D")
    to match the EFC calling convention, but you may want to generate these functions
    programmatically from a generic implementation.

    Instead of using string manipulation with exec() or eval() (which is insecure and breaks
    tooling), this function uses Python's inspect module to create a proper function signature
    that tools like debuggers, type checkers, and IDEs can understand.

    Args:
        param_names: List of parameter names for the generated function
                    (e.g., ["alpha", "beta", "C", "x_factor"])
        func: Implementation function that accepts the same number of arguments as param_names.
              The arguments will be passed in the order specified by param_names.

    Returns:
        A new function with the specified parameter names that calls func with those
        parameters in order. The wrapper preserves func's name and docstring, and
        has a proper signature for introspection.

    Example:
        # Generic implementation that doesn't care about parameter names
        def compute(a, b, c):
            return a + b * c

        # Create EFC-compliant function with required parameter names
        epilogue = create_named_epilogue(["alpha", "X", "Y"], compute)
        # Now epilogue(alpha=1, X=2, Y=3) calls compute(1, 2, 3)
        # and inspect.signature(epilogue) shows the correct parameter names

    Use Case:
        When programmatically generating epilogue functions with different tensor
        configurations, you need each function to have the right parameter names
        for the EFC framework to call them correctly with keyword arguments.

    """
    # Create Parameter objects for each parameter name, using standard Python argument binding.
    parameters = [
        inspect.Parameter(name, inspect.Parameter.POSITIONAL_OR_KEYWORD)
        for name in param_names
    ]

    # Create a new signature with the custom parameter names
    new_signature = inspect.Signature(parameters)

    # Create a wrapper function that accepts arguments according to the new signature
    def wrapper(*args, **kwargs):
        # Bind the provided arguments to our custom signature
        bound = new_signature.bind(*args, **kwargs)
        bound.apply_defaults()

        # Extract argument values in the order specified by param_names
        ordered_args = [bound.arguments[name] for name in param_names]

        # Call the original function with the properly ordered arguments
        return func(*ordered_args)

    # Assign the custom signature to the wrapper so introspection works correctly
    wrapper.__signature__ = new_signature
    wrapper.__name__ = getattr(func, "__name__", "generated_function")
    wrapper.__doc__ = func.__doc__

    return wrapper


def _validate_source_mode_map(source_mode_map, source_rank, target_rank):
    """Validate the source_mode_map for remap_modes() and torch_tensor_remap_modes().

    Checks that:
    - Every element is either ``True`` (broadcast) or an ``int`` (source mode index).
    - The map length matches the target rank.
    - The number of non-broadcast entries does not exceed the source rank
      (some source dims may be unused, e.g. size-1 dims that are implicitly
      broadcast).
    - No integer index exceeds the source rank.
    - No integer index is negative.
    - No integer index appears more than once.
    """
    for i, v in enumerate(source_mode_map):
        if v is not True and not isinstance(v, int):
            raise TypeError(
                f"source_mode_map[{i}] must be an int or True, got {type(v).__name__}: {v!r}"
            )
    if target_rank != len(source_mode_map):
        raise ValueError(
            f"The target layout rank ({target_rank}) and the source_mode_map "
            f"length ({len(source_mode_map)}) should be the same."
        )
    # The number of non-True entries must not exceed source_rank — but can be
    # less, allowing some source dims to be unused (e.g. size-1 broadcast dims
    # in a tensor like (1, N) where dim 0 is ignored).
    num_true = sum(v is True for v in source_mode_map)
    num_used = len(source_mode_map) - num_true
    if num_used > source_rank:
        raise ValueError(
            f"source_mode_map references {num_used} source dimensions but "
            f"the source only has {source_rank}. "
            f"The number of non-True entries must not exceed the source rank."
        )
    int_indices = [v for v in source_mode_map if v is not True]
    for v in int_indices:
        if v < 0:
            raise ValueError(
                f"source_mode_map contains a negative index ({v}). "
                f"All mode indices must be non-negative."
            )
        if v >= source_rank:
            raise ValueError(
                f"source_mode_map contains index {v} which exceeds the source "
                f"rank ({source_rank}). Valid indices are 0..{source_rank - 1}."
            )
    if len(int_indices) != len(set(int_indices)):
        duplicates = [v for v in int_indices if int_indices.count(v) > 1]
        raise ValueError(
            f"source_mode_map contains duplicate source mode indices: "
            f"{sorted(set(duplicates))}. Each source mode should appear at most once."
        )


def remap_modes(
    source: cutlass.cute.Tensor,
    target_shape: tuple,
    source_mode_map: tuple,
    info_tensor_name="",
    info_source_name="",
):
    """Remap modes of a source tensor to match a target shape.

    The source_mode_map is a sequence with a length matching the rank of
    the target shape.

    Each element is either an integer defining the mode of the source
    tensor to map at this place or ``True`` to express that the source
    tensor is broadcast for this mode.
    """
    ss = source.stride
    _validate_source_mode_map(source_mode_map, len(ss), len(target_shape))
    stride = tuple([0 if v is True else ss[v] for v in source_mode_map])
    log(f"remap_modes {stride = }")
    if_info(
        lambda: cutlass.cute.printf(
            f"cute remap_modes stride {info_tensor_name} from {info_source_name} {{}} to {{}} (target_shape {target_shape})",
            source.stride,
            stride,
        )
    )
    log(
        f"remap_modes shape {info_tensor_name} from {info_source_name} {source.shape} to {target_shape = }"
    )
    if_info(
        lambda: cutlass.cute.printf(
            f"cute remap_modes shape {info_tensor_name} from {info_source_name} {{}} to {target_shape = }",
            source.shape,
        )
    )
    broadcast_layout = cutlass.cute.make_layout(shape=target_shape, stride=stride)
    return cutlass.cute.make_tensor(source.iterator, broadcast_layout)


def torch_tensor_remap_modes(
    source: torch.Tensor, target_shape: tuple, source_mode_map: tuple
):
    """Remap modes of a source tensor to match a target shape.

    This is the PyTorch equivalent of remap_modes() for cutlass.cute.Tensor.

    The source_mode_map is a sequence with a length matching the rank of
    the target shape.

    Each element is either an integer defining the mode of the source
    tensor to map at this place or ``True`` to express that the source
    tensor is broadcast for this mode.
    """
    import torch

    ss = source.stride()
    _validate_source_mode_map(source_mode_map, len(ss), len(target_shape))
    stride = tuple([0 if v is True else ss[v] for v in source_mode_map])
    log(f"torch_tensor_remap_modes {stride = }")
    log(f"torch_tensor_remap_modes {target_shape = }")
    return torch.as_strided(source, size=target_shape, stride=stride)


class VariadicParameters:
    """Minimal mixin wrapper for variadic parameters for @cute.jit/@cute.kernel
    functions taking advantage that the DSL can ingest a recursive
    combination of tuples and lists.
    """

    class _UnassignedArgument:
        """Sentinel class to detect uninitialized arguments."""

        def __repr__(self):
            return "<UnassignedArgument>"

    def __init__(self, efc, parameter_names):
        # Add local shortcuts to the efc and gemm objects
        self.efc = efc
        self.gemm = efc.gemm
        self._create_parameter_class(parameter_names)
        self._init_args_with_unassigned()
        log(f"Initial {self.arg = }")

    def _create_parameter_class(self, parameter_names):
        """Create a dataclass with the given parameter names.

        The dataclass uses __slots__ to avoid assigning wrong arguments by error
        and has __getitem__/__setitem__ methods for dict-like access.
        """
        fields = [(name, typing.Any) for name in parameter_names]
        self._parameter_class = dataclasses.make_dataclass(
            "Parameter", fields, slots=True
        )
        self._add_item_accessors()

    def _add_item_accessors(self):
        """Add __getitem__ and __setitem__ methods to the parameter class.

        This allows accessing attributes by name, e.g., arg["a"] or parameter["b"].
        """

        def getitem(self, name):
            """Access the dataclass attribute by name."""
            return getattr(self, name)

        def setitem(self, name, value):
            """Set the dataclass attribute by name."""
            setattr(self, name, value)

        self._parameter_class.__getitem__ = getitem
        self._parameter_class.__setitem__ = setitem

    def _init_args_with_unassigned(self):
        """Initialize all arg attributes to _UnassignedArgument sentinel.

        This ensures any forgotten field will trigger a noticeable error.
        """
        self.arg = self._parameter_class(
            *(
                [self._UnassignedArgument]
                * len(dataclasses.fields(self._parameter_class))
            )
        )

    def pack_arguments(self, *args, **kwargs):
        """Pack the arguments as a tuple to pass them through a
        @cute.jit/@cute.kernel call.

        If some arguments are provided, pack them and set self.arg, otherwise
        just use the self.arg object by default.

        Return a tuple or None as an interface object since a
        @cute.jit/@cute.kernel can ingest a recursive combination of tuples and
        lists.
        """
        if args or kwargs:
            # Override the current argument object from the provided arguments, if any.
            self.arg = self._parameter_class(*args, **kwargs)
        # dataclasses.astuple(self.arg) breaks because it is recursive and
        # applies a deepcopy incompatible with the DSL magic. Just generate 1
        # level of tuple of object references.
        r = tuple(self.arg[f.name] for f in dataclasses.fields(self.arg))
        log(
            f"pack_arguments {args = }{NEWLINE_AND_TAB}{kwargs = }{NEWLINE_AND_TAB}{self.arg = }{NEWLINE_AND_TAB}{r = }"
        )
        # The DSL does not accept an empty tuple but can handle None. So
        # remap to None in that case.
        if not r:
            return None
        return r

    def unpack_parameters(self, p: tuple):
        """Unpack the parameters inside a @cute.jit/@cute.kernel function.

        Assign all the self.parameter attributes.
        """
        # Do the opposite mapping of None to an empty tuple to have the
        # parameter constructor happy.
        if p is None:
            p = ()
        # Instantiate the dataclass holding the parameters from the
        # individual parameter values.
        self.parameter = self._parameter_class(*p)
        log(f"unpack_parameters {p = }{NEWLINE_AND_TAB}{self.parameter = }")

    def instantiate_args(self):
        """Create an arg attribute from the Parameter class to be used
        as an alternative way to pass the arguments instead of using an
        explicit pack_arguments().

        All the arg attributes are initialized to a noticeable name so that
        any forgotten field will trigger an error.
        """
        self._init_args_with_unassigned()

    def extend_parameters(self, names):
        """Extend the dataclass with new field names.

        This creates a new dataclass that inherits all existing fields and adds
        the new ones. The existing arg/parameter values are preserved and new
        fields are initialized to _UnassignedArgument.

        Args:
            names: List of new parameter names to add to the dataclass.
        """
        if not names:
            return

        # Get existing field names and values from arg.
        existing_fields = [f.name for f in dataclasses.fields(self._parameter_class)]
        existing_arg_values = [self.arg[name] for name in existing_fields]

        # Also get existing parameter values if parameter exists.
        has_parameter = hasattr(self, "parameter")
        if has_parameter:
            existing_param_values = [self.parameter[name] for name in existing_fields]

        # Create new dataclass with combined fields.
        self._create_parameter_class(existing_fields + list(names))
        log(f"Extended parameters {dataclasses.fields(self._parameter_class) = }")

        # Reconstruct the arg object with existing values and new unassigned
        # fields.
        new_arg_values = existing_arg_values + [self._UnassignedArgument] * len(names)
        log(f"Extended parameters {new_arg_values = }")
        self.arg = self._parameter_class(*new_arg_values)

        # Also reconstruct parameter if it existed.
        if has_parameter:
            new_param_values = existing_param_values + [self._UnassignedArgument] * len(
                names
            )
            self.parameter = self._parameter_class(*new_param_values)

        log(f"Extended parameters with {names}, now {self.arg = }")


class EFC:
    """Epilogue Fusion Configuration."""

    # Helper functions for CuTe operations
    @staticmethod
    def maximum(x, y):
        """Element-wise maximum of 2 CuTe tensors"""
        x_type = x.element_type
        y_type = y.element_type
        if x_type is not y_type:
            raise TypeError(f"Type mismatch: x is {x_type}, y is {y_type}")
        return cutlass.cute.where(x > y, x, y)

    @staticmethod
    def minimum(x, y):
        """Element-wise minimum of 2 CuTe tensors"""
        x_type = x.element_type
        y_type = y.element_type
        if x_type is not y_type:
            raise TypeError(f"Type mismatch: x is {x_type}, y is {y_type}")
        return cutlass.cute.where(x < y, x, y)

    class JIT(VariadicParameters):
        """Handle Python/@cute.jit and its boundaries with Host."""

        # All the following customization functions should go somewhere else in
        # the long term, as part of a refactoring similar to CUTLASS
        # collective/main loop/epilogue...

        # The following foreach_... functions are some refinement of the EFC
        # ones to handle more precisely the broadcast tensors for example.

        def get_argument_or_remapped_tensor(self, name):
            """A remapped tensor is not passed as a parameter but synthesized and stored in self.remapped_tensors."""
            if tensor := self.remapped_tensors.get(name):
                return tensor
            return self.parameter[name]

        def get_remapped_tensor_or_itself(self, name):
            """For a remapped tensor name, return the remapped tensor view, otherwise return the tensor itself."""
            if self.efc.parameter_attributes[name].mapped_source:
                return self.remapped_tensors[name]
            return self.parameter[name]

        def foreach_tensor(self, function):
            """Execute the given function for each supplemental tensor,
            providing the tensor object from the JIT parameters.
            """

            def wrapper(tensor_name, attributes):
                function(
                    self.get_argument_or_remapped_tensor(tensor_name),
                    tensor_name,
                    attributes,
                )

            self.efc.foreach_tensor(wrapper)

        def foreach_non_degenerate_tensor(self, function):
            """Execute the given function for each supplemental tensor,
            providing the tensor object from the JIT parameters. Skip the tensor
            if it is a degenerate case as scalar in broadcast.
            """

            def wrapper(tensor_name, attributes):
                if not attributes.degenerate_to_scalar:
                    function(
                        self.get_argument_or_remapped_tensor(tensor_name),
                        tensor_name,
                        attributes,
                    )

            self.efc.foreach_tensor(wrapper)

        def foreach_remapped_tensor(self, function):
            """Execute the given function for each remapped tensor,
            providing the remapped tensor object if any.
            """

            def wrapper(tensor_name, attributes):
                if not attributes.degenerate_to_scalar:
                    # Call the function only if it ends up as a real tensor.
                    function(
                        self.remapped_tensors[tensor_name], tensor_name, attributes
                    )

            self.efc.foreach_remapped_tensor(wrapper)

        def foreach_remapped_tensor_as_scalar(self, function):
            """Execute the given function for each remapped tensor, providing
            the remapped tensor object only if it degenerates as a scalar
            because all the modes are broadcast.
            """

            def wrapper(tensor_name, attributes):
                if attributes.degenerate_to_scalar:
                    # Call the function only if it ends up as a scalar.
                    function(
                        self.remapped_tensors[tensor_name], tensor_name, attributes
                    )

            self.efc.foreach_remapped_tensor(wrapper)

        def foreach_argument(self, function):
            """Execute the given function for each supplemental argument,
            providing the parameter value from the JIT parameters.

            Note that remapped tensors are not direct parameters but are
            synthesized and accessed via self.remapped_tensors.
            """

            def wrapper(name, attributes):
                log(f"JIT.foreach_argument {name = }")
                function(
                    self.get_argument_or_remapped_tensor(name),
                    name,
                    attributes,
                )

            self.efc.foreach_argument(wrapper)

        @trace_in_mlir
        def handle_remapping(self):
            # Track the remapped tensors by their names.
            self.efc.jit.remapped_tensors = {}

            def f(tensor_name, attributes):
                log(f"handle_remapping of tensor {tensor_name}")
                log(f"{TAB}mapped_source {attributes.mapped_source}")
                log(f"{TAB}source_mode_map {attributes.source_mode_map}")
                self.efc.jit.remapped_tensors[tensor_name] = remap_modes(
                    source=self.efc.jit.parameter[attributes.mapped_source],
                    target_shape=self.efc.output_shape,
                    source_mode_map=attributes.source_mode_map,
                    info_tensor_name=tensor_name,
                    info_source_name=attributes.mapped_source,
                )
                log(
                    f"{TAB}self.efc.jit.remapped_tensors[{tensor_name}] = {self.efc.jit.remapped_tensors[tensor_name]}"
                )

            self.efc.foreach_remapped_tensor(f)

        @trace_in_mlir
        def record_tensor_dtypes(self):
            """It does not seem that the tma_tensor and tma_atom carry over the
            element type, so, store it here for later use.
            """
            self.tensor_dtype = {}

            def f(tensor, tensor_name, attributes):
                self.tensor_dtype[tensor_name] = tensor.element_type

            self.foreach_tensor(f)

        @trace_in_mlir
        def written_tensor_name_with_bigger_element_type(self):
            """The type of the written tensor is used to compute a lot of
            implementation details about tiling and so on in the kernel.

            The compilation phase has already checked that there is at least 1
            written tensor name.

            Return the name of the written tensor with the biggest
            element_type.

            """
            return max(
                (tensor_name for tensor_name in self.efc.written_tensor_names),
                key=lambda tensor_name: self.tensor_dtype[tensor_name].width,
            )

        @trace_in_mlir
        def read_tensor_name_with_bigger_element_type(self):
            """The type of the read tensor is used to compute a lot of
            implementation details about tiling and so on in the kernel. Return
            the name of the read tensor with the biggest element_type, or None
            if there is no read tensor.
            """
            if self.efc.read_tensor_names:
                return max(
                    (tensor_name for tensor_name in self.efc.read_tensor_names),
                    key=lambda tensor_name: self.tensor_dtype[tensor_name].width,
                )
            return None

        @trace_in_mlir
        def compute_stage(self):
            """Get the contribution from the tensors used in the EFC to the
            pipeline stage numbers.
            """
            self.smem_size_of_read_tensors = 0
            self.smem_size_of_written_tensors = 0
            self.tensor_dtype = {}

            def f(tensor, tensor_name, attributes):
                # It does not seem that the tma_tensor and tma_atom carry over
                # the element type, so, store it here for later use.
                self.tensor_dtype[tensor_name] = tensor.element_type

                smem_size_in_bytes_of_a_pipeline_stage = cutlass.cute.size_in_bytes(
                    tensor.element_type,
                    cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                        tensor.element_type, self.gemm.d_layout, self.gemm.epi_tile, 1
                    ),
                )
                # Prepare the information to be asked soon, to memoize this
                # loop.
                if attributes.is_read:
                    self.smem_size_of_read_tensors += (
                        smem_size_in_bytes_of_a_pipeline_stage
                    )
                    log(
                        f"JIT.compute_stage smem storage to read tensor {tensor_name}: {smem_size_in_bytes_of_a_pipeline_stage} bytes"
                    )

                if attributes.is_written:
                    self.smem_size_of_written_tensors += (
                        smem_size_in_bytes_of_a_pipeline_stage
                    )
                    log(
                        f"JIT.compute_stage smem storage to write tensor {tensor_name}: {smem_size_in_bytes_of_a_pipeline_stage} bytes"
                    )

            self.foreach_non_degenerate_tensor(f)

        @trace_in_mlir
        def smem_size_in_bytes_of_read_tensors(self):
            """Get the contribution in a smem pipeline stage from the tensors
            loaded in the EFC.
            """
            log(
                f"JIT.smem_size_in_bytes_of_read_tensors {self.smem_size_of_read_tensors = }"
            )
            return self.smem_size_of_read_tensors

        @trace_in_mlir
        def smem_size_in_bytes_of_written_tensors(self):
            """Get the contribution in a smem pipeline stage from the tensors
            stored in the EFC.
            """
            log(
                f"JIT.smem_size_in_bytes_of_written_tensors {self.smem_size_of_written_tensors = }"
            )
            return self.smem_size_of_written_tensors

        @trace_in_mlir
        def smem_layout(self):
            """Get the smem_layout for the tensors used in the EFC."""
            self.smem_layout_staged_read = {}
            self.smem_layout_staged_written = {}

            def f(tensor, tensor_name, attributes):
                log(f"JIT.smem_layout {tensor_name} = {tensor!s}")
                ref_tensor = self.get_argument_or_remapped_tensor(tensor_name)
                tensor_layout = cutlass.utils.LayoutEnum.from_tensor(ref_tensor)
                log(f"JIT.smem_layout tensor_layout[{tensor_name}] = {tensor_layout!s}")

                if attributes.is_read:
                    self.smem_layout_staged_read[tensor_name] = (
                        cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                            tensor.element_type,
                            tensor_layout,
                            self.gemm.epi_tile,
                            self.gemm.num_c_stage,
                        )
                    )
                    log(f"JIT.smem_layout read {self.gemm.num_c_stage = }")
                    log(
                        f"JIT.smem_layout read self.smem_layout_staged_read[{tensor_name}] = {self.smem_layout_staged_read[tensor_name]!s}"
                    )
                if attributes.is_written:
                    self.smem_layout_staged_written[tensor_name] = (
                        cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                            tensor.element_type,
                            tensor_layout,
                            self.gemm.epi_tile,
                            self.gemm.num_d_stage,
                        )
                    )
                    log(f"JIT.smem_layout written {self.gemm.num_d_stage = }")
                    log(
                        f"JIT.smem_layout written self.smem_layout_staged_written[{tensor_name}] = {self.smem_layout_staged_written[tensor_name]!s}"
                    )

            self.foreach_non_degenerate_tensor(f)

        @trace_in_mlir
        def create_tma_arguments(self):
            """Set the TMA related arguments for the tensors used in the EFC."""
            # Make the difference for read/written to handle the case a tensor
            # is both read and written.
            self.total_tma_load_bytes = 0  # Used by the PipelineTmaAsync
            self.tma_atom_read = {}
            self.tma_tensor_read = {}
            self.tma_atom_written = {}
            self.tma_tensor_written = {}

            def f(tensor, tensor_name, attributes):
                if attributes.is_read:
                    smem_layout = cutlass.cute.slice_(
                        self.smem_layout_staged_read[tensor_name], (None, None, 0)
                    )
                    self.total_tma_load_bytes += cutlass.cute.size_in_bytes(
                        tensor.element_type, smem_layout
                    )
                    (
                        self.tma_atom_read[tensor_name],
                        self.tma_tensor_read[tensor_name],
                    ) = cutlass.cute.nvgpu.cpasync.make_tiled_tma_atom(
                        cutlass.cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(),
                        tensor,
                        smem_layout,
                        self.gemm.epi_tile,
                    )
                    log(
                        f"JIT.create_tma_arguments tma_atom_read[{tensor_name}] = {self.tma_atom_read[tensor_name]!s}"
                    )
                    log(
                        f"JIT.create_tma_arguments tma_tensor_read[{tensor_name}] = {self.tma_tensor_read[tensor_name]!s}"
                    )

                if attributes.is_written:
                    smem_layout = cutlass.cute.slice_(
                        self.smem_layout_staged_written[tensor_name], (None, None, 0)
                    )
                    (
                        self.tma_atom_written[tensor_name],
                        self.tma_tensor_written[tensor_name],
                    ) = cutlass.cute.nvgpu.cpasync.make_tiled_tma_atom(
                        cutlass.cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
                        tensor,
                        smem_layout,
                        self.gemm.epi_tile,
                    )
                    log(
                        f"JIT.create_tma_arguments tma_atom_written[{tensor_name}] = {self.tma_atom_written[tensor_name]!s}"
                    )
                    log(
                        f"JIT.create_tma_arguments tma_tensor_written[{tensor_name}] = {self.tma_tensor_written[tensor_name]!s}"
                    )

            self.foreach_non_degenerate_tensor(f)

        @trace_in_mlir
        def create_supplemental_arguments_for_kernel(self):
            """Executed before launching the @cute.kernel function to set up the
            supplemental arguments to pass to the @cute.kernel function.

            In the @cute.kernel example, the parameters like `X_tma_tensor_read`
            or `Y_tma_tensor_written` correspond to `mX_mnl` and `mY_mnl`.
            """
            argument_names = []

            def compute_argument_names(value, name, attributes):
                if not attributes.is_tensor or attributes.degenerate_to_scalar:
                    # Just propagate the dynamic scalar with the same name or a
                    # scalar parameter for the degenerate tensor broadcast.
                    argument_names.append(name)
                else:
                    if attributes.is_read:
                        argument_names.append(f"{name}_tma_atom_read")
                        argument_names.append(f"{name}_tma_tensor_read")
                        argument_names.append(f"{name}_smem_layout_staged_read")
                    if attributes.is_written:
                        argument_names.append(f"{name}_tma_atom_written")
                        argument_names.append(f"{name}_tma_tensor_written")
                        argument_names.append(f"{name}_smem_layout_staged_written")

            self.foreach_argument(compute_argument_names)
            # Create the @cute.kernel-side meta-programming infrastructure
            # handling also the supplemental argument handling.
            self.efc.kernel = EFC.Kernel(self.efc, argument_names)

            arg = self.efc.kernel.arg

            def populate_the_kernel_arguments(value, name, attributes):
                if not attributes.is_tensor:
                    # Just propagate the dynamic scalar with the same name.
                    arg[name] = value
                elif attributes.degenerate_to_scalar:
                    # The tensor broadcast is optimized out as a single scalar
                    # from the tensor source which is implicitly broadcast when
                    # used but since it might be in device memory, pass it
                    # unchanged so it can be dereferenced inside the kernel.
                    arg[name] = self.efc.jit.parameter[attributes.mapped_source]
                else:
                    if attributes.is_read:
                        arg[f"{name}_tma_atom_read"] = self.tma_atom_read[name]
                        arg[f"{name}_tma_tensor_read"] = self.tma_tensor_read[name]
                        arg[f"{name}_smem_layout_staged_read"] = (
                            self.smem_layout_staged_read[name]
                        )
                    if attributes.is_written:
                        arg[f"{name}_tma_atom_written"] = self.tma_atom_written[name]
                        arg[f"{name}_tma_tensor_written"] = self.tma_tensor_written[
                            name
                        ]
                        arg[f"{name}_smem_layout_staged_written"] = (
                            self.smem_layout_staged_written[name]
                        )

            self.foreach_argument(populate_the_kernel_arguments)

    class Kernel(VariadicParameters):
        """Handle kernel part and @cute.jit/@cute.kernel boundaries."""

        def foreach_tensor(self, function):
            """Execute the given function for each supplemental tensor, skipping
            the degenerate scalar broadcast cases.
            """

            def wrapper(tensor_name, attributes):
                if not attributes.degenerate_to_scalar:
                    function(
                        tensor_name,
                        attributes,
                    )

            self.efc.foreach_tensor(wrapper)

        def foreach_read_tensor(self, function):
            """Execute the given function for each supplemental read tensor,
            skipping the degenerate scalar broadcast cases.
            """

            def wrapper(tensor_name, attributes):
                if not attributes.degenerate_to_scalar:
                    function(
                        tensor_name,
                        attributes,
                    )

            self.efc.foreach_read_tensor(wrapper)

        def foreach_written_tensor(self, function):
            """Execute the given function for each supplemental written tensor,
            skipping the degenerate scalar broadcast cases.
            """

            def wrapper(tensor_name, attributes):
                if not attributes.degenerate_to_scalar:
                    function(
                        tensor_name,
                        attributes,
                    )

            self.efc.foreach_written_tensor(wrapper)

        @trace_in_mlir
        def prefetch_tma_descriptors(self):
            """Prefetch the TMA descriptors for the tensors used in the EFC."""

            def f(tensor_name, attributes):
                if attributes.is_read:
                    cutlass.cute.nvgpu.cpasync.prefetch_descriptor(
                        self.parameter[f"{tensor_name}_tma_atom_read"]
                    )

                if attributes.is_written:
                    cutlass.cute.nvgpu.cpasync.prefetch_descriptor(
                        self.parameter[f"{tensor_name}_tma_atom_written"]
                    )

            self.foreach_tensor(f)

        @trace_in_mlir
        def allocate_smem(self):
            """Allocate the shared memory for all the supplemental tensors."""
            self.smem_read = {}
            self.smem_written = {}

            def f(tensor_name, attributes):
                element_type = self.efc.jit.tensor_dtype[tensor_name]
                if attributes.is_read:
                    smem_layout_staged = self.parameter[
                        f"{tensor_name}_smem_layout_staged_read"
                    ]
                    self.smem_read[tensor_name] = self.gemm.smem.allocate_tensor(
                        element_type=element_type,
                        layout=smem_layout_staged.outer,
                        byte_alignment=self.gemm.buffer_align_bytes,
                        swizzle=smem_layout_staged.inner,
                    )
                if attributes.is_written:
                    smem_layout_staged = self.parameter[
                        f"{tensor_name}_smem_layout_staged_written"
                    ]
                    self.smem_written[tensor_name] = self.gemm.smem.allocate_tensor(
                        element_type=element_type,
                        layout=smem_layout_staged.outer,
                        byte_alignment=self.gemm.buffer_align_bytes,
                        swizzle=smem_layout_staged.inner,
                    )

            self.foreach_tensor(f)

        @trace_in_mlir
        def partition_global_tensors_for_tiled_mma(self):
            """Partition the global supplemental tensors for TiledMMA_C/D."""
            self.tCgC_read = {}
            self.tCgD_written = {}

            def f(tensor_name, attributes):
                if attributes.is_read:
                    # (bM, bN, loopM, loopN, loopL)
                    gC_mnl = cutlass.cute.local_tile(
                        self.parameter[f"{tensor_name}_tma_tensor_read"],
                        cutlass.cute.slice_(self.gemm.mma_tiler, (None, None, 0)),
                        (None, None, None),
                    )
                    log(
                        f"Kernel.partition_global_tensors_for_tiled_mma: gC_mnl[{tensor_name}] = {gC_mnl!s}"
                    )
                    # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
                    self.tCgC_read[tensor_name] = self.gemm.thr_mma.partition_C(gC_mnl)
                    log(
                        f"Kernel.partition_global_tensors_for_tiled_mma: self.tCgC_read[{tensor_name}] = {self.tCgC_read[tensor_name]!s}"
                    )

                if attributes.is_written:
                    # (bM, bN, loopM, loopN, loopL)
                    gD_mnl = cutlass.cute.local_tile(
                        self.parameter[f"{tensor_name}_tma_tensor_written"],
                        cutlass.cute.slice_(self.gemm.mma_tiler, (None, None, 0)),
                        (None, None, None),
                    )
                    log(
                        f"Kernel.partition_global_tensors_for_tiled_mma: gD_mnl[{tensor_name}] = {gD_mnl!s}"
                    )
                    # (MMA, MMA_M, MMA_N, loopM, loopN, loopL)
                    self.tCgD_written[tensor_name] = self.gemm.thr_mma.partition_C(
                        gD_mnl
                    )
                    log(
                        f"Kernel.partition_global_tensors_for_tiled_mma: self.tCgD_written[{tensor_name}] = {self.tCgD_written[tensor_name]!s}"
                    )

            self.foreach_tensor(f)

        # The following functions are executed by the specialized warps for
        # epilogue computation.

        @trace_in_mlir
        def copy_and_partition_supplemental_rmem_tensors(
            self, tiled_copy_t2r, tTR_rAcc, epi_tidx, epi_tile
        ):
            # Load tensor.
            self.tiled_copy_s2r = {}
            self.tSR_rC = {}
            self.tSR_sC = {}

            # Store tensor.
            self.tiled_copy_r2s = {}
            self.tRS_rD = {}
            self.tRS_sD = {}
            self.bSG_sD = {}  # ((ATOM_V, REST_V), EPI_M, EPI_N)
            self.bSG_gD_partitioned = {}  # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)

            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors: tiled_copy_t2r = {tiled_copy_t2r!s}"
            )
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors: tTR_rAcc = {tTR_rAcc!s}"
            )
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors: epi_tile = {epi_tile!s}"
            )
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors: epi_tidx = {epi_tidx!s}"
            )

            def f(tensor_name, attributes):
                element_type = self.efc.jit.tensor_dtype[tensor_name]
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors: element_type[{tensor_name}] = {element_type!s}"
                )

                if attributes.is_read:
                    tTR_rC = cutlass.cute.make_rmem_tensor(tTR_rAcc.shape, element_type)
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors read: tTR_rC[{tensor_name}] = {tTR_rC!s}"
                    )

                    (
                        self.tiled_copy_s2r[tensor_name],
                        self.tSR_rC[tensor_name],
                        self.tSR_sC[tensor_name],
                    ) = self.gemm.epilogue_smem_copy_and_partition_load(
                        tiled_copy_t2r,
                        tTR_rC,
                        epi_tidx,
                        self.smem_read[tensor_name],
                    )

                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tiled_copy_s2r[{tensor_name}] = {self.tiled_copy_s2r[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tSR_sC[{tensor_name}] = {self.tSR_sC[tensor_name]!s}"
                    )

                if attributes.is_written:
                    # (T2R, T2R_M, T2R_N)
                    tTR_rD = cutlass.cute.make_rmem_tensor(tTR_rAcc.shape, element_type)
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: tTR_rD[{tensor_name}] = {tTR_rD!s}"
                    )

                    # utils.gemm.sm100.epilogue_smem_copy_and_partition uses
                    # explicitly "C" as the output matrix and introspects the
                    # gemm object while in this kernel "C" is used for read but
                    # "D" is for output according to the BLAS convention.
                    # So construct a minimal mock-up with the required
                    # information.
                    faux_gemm = types.SimpleNamespace()
                    faux_gemm.c_layout = self.gemm.d_layout
                    faux_gemm.c_dtype = self.gemm.d_dtype
                    faux_gemm.acc_dtype = self.gemm.acc_dtype
                    (
                        self.tiled_copy_r2s[tensor_name],
                        self.tRS_rD[tensor_name],  # (R2S, R2S_M, R2S_N)
                        self.tRS_sD[tensor_name],  # (R2S, R2S_M, R2S_N)
                    ) = cutlass.utils.gemm.sm100.epilogue_smem_copy_and_partition(
                        faux_gemm,
                        tiled_copy_t2r,  # (EPI_TILE_M, EPI_TILE_N)
                        tTR_rD,
                        epi_tidx,
                        self.smem_written[tensor_name],
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.smem_written[{tensor_name}] = {self.smem_written[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tiled_copy_r2s[{tensor_name}] = {self.tiled_copy_r2s[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tRS_rD[{tensor_name}] = {self.tRS_rD[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tRS_sD[{tensor_name}] = {self.tRS_sD[tensor_name]!s}"
                    )
                    (
                        _,
                        self.bSG_sD[tensor_name],  # ((ATOM_V, REST_V), EPI_M, EPI_N)
                        self.bSG_gD_partitioned[
                            tensor_name
                        ],  # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
                    ) = self.gemm.epilogue_gmem_copy_and_partition(
                        epi_tidx,
                        self.parameter[f"{tensor_name}_tma_atom_written"],
                        self.tCgD_written[tensor_name],
                        epi_tile,
                        self.smem_written[tensor_name],
                        element_type,
                    )

                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.parameter[{tensor_name}_tma_atom_written] = {self.parameter[f'{tensor_name}_tma_atom_written']!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tCgD_written[{tensor_name}] = {self.tCgD_written[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.smem_written[{tensor_name}] = {self.smem_written[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: element_type = {element_type!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.bSG_sD[{tensor_name}] = {self.bSG_sD[tensor_name]!s}"
                    )
                    log(
                        f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.bSG_gD_partitioned[{tensor_name}] = {self.bSG_gD_partitioned[tensor_name]!s}"
                    )

            self.foreach_tensor(f)

        @trace_in_mlir
        def slice_written_tensors_per_mma_tile_index(self, mma_tile_coord_mnl):
            """Slice the supplemental written tensors per MMA tile index."""
            self.bSG_gD = {}  # ((ATOM_V, REST_V), (EPI_M, EPI_N))

            def f(tensor_name, attributes):
                # ((ATOM_V, REST_V), EPI_M, EPI_N)
                bSG_gD = self.bSG_gD_partitioned[tensor_name][
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]
                log(
                    f"Kernel.slice_written_tensors_per_mma_tile_index: bSG_gD[{tensor_name}] = {bSG_gD!s}"
                )
                # Group the 2 last modes so the subtile_idx loop can iterate
                # through it using 1-D indexing.
                # ((ATOM_V, REST_V), (EPI_M, EPI_N))
                self.bSG_gD[tensor_name] = cutlass.cute.group_modes(
                    bSG_gD, 1, cutlass.cute.rank(bSG_gD)
                )
                log(
                    f"Kernel.slice_written_tensors_per_mma_tile_index: self.bSG_gD[{tensor_name}] = {self.bSG_gD[tensor_name]!s}"
                )

            self.foreach_written_tensor(f)

        @trace_in_mlir
        def load_tensors_from_smem_to_register(self, index):
            """Load supplemental tensors from shared memory to register."""

            def f(tensor_name, attributes):
                cutlass.cute.copy(
                    self.tiled_copy_s2r[tensor_name],
                    self.tSR_sC[tensor_name][
                        (
                            None,
                            None,
                            None,
                            index,
                        )
                    ],
                    self.tSR_rC[tensor_name],
                )
                log(
                    f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tiled_copy_s2r[{tensor_name}] = {self.tiled_copy_s2r[tensor_name]!s}"
                )
                log(
                    f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tSR_sC[{tensor_name}] = {self.tSR_sC[tensor_name]!s}"
                )
                log(
                    f"Kernel.load_tensors_from_smem_to_register cutlass.cute.copy: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
                )

            self.foreach_read_tensor(f)

        @trace_in_mlir
        def epilogue_computation(self, epilogue_context):
            """Execute the EFC epilogue."""
            epilogue_context.load = {}
            epilogue_context.store = {}

            def broadcast_degenerate_tensor_load(tensor_name, attributes):
                """Create the SSA Tensor for the degenerate tensor broadcast
                read.
                """
                if attributes.degenerate_to_scalar:
                    log(
                        f"Kernel.epilogue_computation broadcast_degenerate_tensor_load: broadcast scalar from {tensor_name} = {self.parameter[tensor_name]!s}"
                    )
                    # If the broadcast tensor degenerates to a scalar, just
                    # dereference the scalar at index 0 and broadcast it to a
                    # TensorSSA similar to the accumulator.
                    epilogue_context.load[tensor_name] = cutlass.cute.full_like(
                        epilogue_context.acc_vec,
                        self.parameter[tensor_name][0],
                        self.efc.gemm.epi_dtype,
                    )

            self.efc.foreach_remapped_tensor(broadcast_degenerate_tensor_load)

            def load_setup(tensor_name, attributes):
                # Retile the read subtile to fit the accumulator subtile vector
                # TV layout.
                epilogue_context.load[tensor_name] = (
                    self.tiled_copy_r2s[self.gemm.d_name_bigger]
                    .retile(self.tSR_rC[tensor_name])
                    .load()
                )
                log(
                    f"Kernel.epilogue_computation load_setup: {self.tiled_copy_r2s[self.gemm.d_name_bigger] = !s}"
                )
                log(
                    f"Kernel.epilogue_computation load_setup: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
                )
                log(
                    f"Kernel.epilogue_computation load_setup: self.tiled_copy_r2s[self.gemm.d_name_bigger].retile(self.tSR_rC[{tensor_name}]) = {self.tiled_copy_r2s[self.gemm.d_name_bigger].retile(self.tSR_rC[tensor_name])!s}"
                )
                log(
                    f"Kernel.epilogue_computation load_setup: epilogue_context.load[{tensor_name}] = {epilogue_context.load[tensor_name]!s}"
                )

            self.foreach_read_tensor(load_setup)

            def store_setup(tensor_name, attributes):
                epilogue_context.store[tensor_name] = self.tRS_rD[tensor_name]
                log(
                    f"Kernel.epilogue_computation store_setup: epilogue_context.store[{tensor_name}] = {epilogue_context.store[tensor_name]!s}"
                )

            self.foreach_written_tensor(store_setup)

            self.efc.specialized_epilogue(EFC.Phase.ThreadOperation, epilogue_context)()

        @trace_in_mlir
        def store_written_tensors_to_smem(self, d_buffer):
            """Store the EFC written tensors to shared memory."""

            def f(tensor_name, attributes):
                cutlass.cute.copy(
                    self.tiled_copy_r2s[tensor_name],
                    self.tRS_rD[tensor_name],
                    self.tRS_sD[tensor_name][(None, None, None, d_buffer)],
                )
                log(
                    f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tiled_copy_r2s[{tensor_name}] = {self.tiled_copy_r2s[tensor_name]!s}"
                )
                log(
                    f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_rD[{tensor_name}] = {self.tRS_rD[tensor_name]!s}"
                )
                log(
                    f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_sD[{tensor_name}] = {self.tRS_sD[tensor_name]!s}"
                )
                log(
                    f"Kernel.store_written_tensors_to_smem cutlass.cute.copy: self.tRS_sD[{tensor_name}][(None, None, None, d_buffer)] = {self.tRS_sD[tensor_name][(None, None, None, d_buffer)]!s}"
                )

            self.foreach_written_tensor(f)

        @trace_in_mlir
        def tma_store_written_tensors_to_gmem(self, d_buffer, subtile_idx):
            """Store with TMA the written EFC tensors to global memory."""

            def f(tensor_name, attributes):
                cutlass.cute.copy(
                    self.parameter[f"{tensor_name}_tma_atom_written"],
                    self.bSG_sD[tensor_name][(None, d_buffer)],
                    self.bSG_gD[tensor_name][(None, subtile_idx)],
                )
                log(
                    f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.parameter[{tensor_name}_tma_atom_written] = {self.parameter[f'{tensor_name}_tma_atom_written']!s}"
                )
                log(
                    f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_sD[{tensor_name}] = {self.bSG_sD[tensor_name]!s}"
                )
                log(
                    f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_sD[{tensor_name}][(None, d_buffer)] = {self.bSG_sD[tensor_name][(None, d_buffer)]!s}"
                )
                log(
                    f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_gD[{tensor_name}] = {self.bSG_gD[tensor_name]!s}"
                )
                log(
                    f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_gD[{tensor_name}][(None, subtile_idx)] = {self.bSG_gD[tensor_name][(None, subtile_idx)]!s}"
                )

            self.foreach_written_tensor(f)

        # The following functions are executed by the specialized warp for the
        # epilogue load.

        @trace_in_mlir
        def create_epilogue_subtile_tensors(self, tidx, epi_tile):
            """Setup the pipelines reading the EFC supplemental tensors."""
            self.bGS_sC = {}
            self.bGS_gC_partitioned = {}

            def f(tensor_name, attributes):
                (
                    _,
                    self.bGS_sC[tensor_name],
                    self.bGS_gC_partitioned[tensor_name],
                ) = self.gemm.epilogue_gmem_copy_and_partition(
                    tidx,
                    self.parameter[f"{tensor_name}_tma_atom_read"],
                    self.tCgC_read[tensor_name],
                    epi_tile,
                    self.smem_read[tensor_name],
                    self.efc.jit.tensor_dtype[tensor_name],
                )

            self.foreach_read_tensor(f)

        @trace_in_mlir
        def prepare_tensor_load_for_subtiles(
            self,
            mma_tile_coord_mnl,
        ):
            """Prepare the EFC tensors to be loaded by the subtiles and return the number of subtiles to compute."""
            self.bGS_gC = {}
            # In the case there is no supplemental tensor to load in the
            # epilogue:
            self._subtile_cnt = 0

            def f(tensor_name, attributes):
                self.bGS_gC[tensor_name] = self.bGS_gC_partitioned[tensor_name][
                    (
                        None,
                        None,
                        None,
                        *mma_tile_coord_mnl,
                    )
                ]
                self.bGS_gC[tensor_name] = cutlass.cute.group_modes(
                    self.bGS_gC[tensor_name],
                    1,
                    cutlass.cute.rank(self.bGS_gC[tensor_name]),
                )
                st_cnt = cutlass.cute.size(self.bGS_gC[tensor_name].shape, mode=[1])
                if self._subtile_cnt == 0:
                    # Keep the first loaded tensor as a reference.
                    self._subtile_cnt = st_cnt
                if st_cnt != self._subtile_cnt:
                    raise NotImplementedError(
                        f"Subtile count mismatch: tensor '{self.efc.read_tensor_names[0]}' has {self._subtile_cnt} subtiles, "
                        f"but tensor '{tensor_name}' has {st_cnt} subtiles. All tensors must have the same subtile count."
                    )

            self.foreach_read_tensor(f)

            return self._subtile_cnt

        @trace_in_mlir
        def load_tensor_subtiles(
            self, subtile_idx, c_pipeline, c_pipeline_producer_state
        ):
            """Load the subtiles of the EFC tensors."""

            def f(tensor_name, attributes):
                # Load supplemental tensor from global memory to shared memory.
                cutlass.cute.copy(
                    self.parameter[f"{tensor_name}_tma_atom_read"],
                    self.bGS_gC[tensor_name][(None, subtile_idx)],
                    self.bGS_sC[tensor_name][(None, c_pipeline_producer_state.index)],
                    tma_bar_ptr=c_pipeline.producer_get_barrier(
                        c_pipeline_producer_state
                    ),
                )

            self.foreach_read_tensor(f)

    class Phase(enum.Enum):
        ParameterAnalysis = enum.auto()
        """Epilogue function during analysis of its parameters."""

        ThreadOperation = enum.auto()
        """Epilogue function used for computation."""

        PyTorchEvaluation = enum.auto()
        """Epilogue function used for verification on CPU with PyTorch."""

    class _RemapModesAccessor:
        """Helper to enable ``C.remap_modes[:,0,1]`` syntax via ``__getitem__``.

        Converts ``slice(None)`` (``:`` in subscript notation) to ``True``
        (broadcast) and passes integers through as mode indices.
        """

        def __init__(self, tensor):
            self._tensor = tensor

        @staticmethod
        def _convert_subscript_element(i, k):
            """Convert a single subscript element to a source_mode_map entry.

            Only ``:`` (broadcast) and ``int`` (mode index) are valid.
            Reject everything else early with a clear message referencing
            the ``C.remap_modes[:, 0, 1]`` syntax.
            """
            if isinstance(k, int):
                return k
            if isinstance(k, slice):
                if k != slice(None):
                    raise TypeError(
                        f"remap_modes subscript element [{i}] is a "
                        f"non-trivial slice ({k.start}:{k.stop}:{k.step}). "
                        f"Only ':' (broadcast) is supported, "
                        f"e.g. C.remap_modes[:, 0, 1]."
                    )
                return True
            raise TypeError(
                f"remap_modes subscript element [{i}] has unsupported type "
                f"{type(k).__name__}: {k!r}. Each element must be ':' "
                f"(broadcast) or an int (mode index), "
                f"e.g. C.remap_modes[:, 0, 1]."
            )

        def __getitem__(self, key):
            if not isinstance(key, tuple):
                key = (key,)
            source_mode_map = tuple(
                self._convert_subscript_element(i, k) for i, k in enumerate(key)
            )
            return self._tensor.configuration.remap_modes(
                source=self._tensor,
                source_mode_map=source_mode_map,
            )

    class Tensor:
        """A proxy object to be used as an EFC argument to introspect or execute
        the epilogue configuration function in a given phase.
        """

        @dataclasses.dataclass
        class ParameterAttributes:
            """Store some characteristics of the epilogue parameters."""

            is_tensor: bool  # Tensor or scalar.
            is_read: bool = False  # This tensor is read.
            is_written: bool = False  # This tensor is written.
            # The name of the tensor to be remapped.
            mapped_source: str = None
            # The remapping modes to define the new tensor in respect to the
            # layout model. Each element is either an integer to express the
            # source mode to map at its place or `True` to broadcast the source
            # tensor for this mode.
            source_mode_map: tuple = None
            # True if the source_mode_map has only broadcast modes, so the
            # tensor can degenerate to a single scalar as an optimization.
            degenerate_to_scalar: bool = False

        def __init__(
            self,
            phase: typing.ForwardRef("EFC.Phase"),
            name: str,
            efc: EFC,
            configuration,
        ):
            """Initialize a tensor proxy bound to an EFC phase and configuration.

            This proxy tracks how an epilogue parameter is used during different
            phases of EFC execution and provides access to per-parameter metadata.
            It also captures the current configuration context so later `load()`
            and `store()` calls can route to the correct backend (analysis,
            kernel-thread operation, or PyTorch evaluation).

            Args:
                phase: Current EFC phase controlling the proxy behavior.
                name: Parameter name as declared in the epilogue function.
                efc: Owning EFC instance that holds shared state.
                configuration: Phase-specific configuration with runtime args.
            """
            self.phase = phase
            self.name = name
            self.efc = efc
            self.configuration = configuration
            self.attributes: EFC.Tensor.ParameterAttributes = efc.parameter_attributes[
                name
            ]
            log(f"Tensor {self.name = }")

        def load(self):
            """Load a tensor value inside the EFC function.

            The behavior depends on the phase:
            - ParameterAnalysis: mark the tensor as read and return a dummy value
            - ThreadOperation: load from the epilogue context and cast to epi dtype
            - PyTorchEvaluation: return the runtime tensor from evaluation inputs
            """
            log(f"Tensor.load {self.name = } {self.phase = }")
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Record that the tensor is read:
                    self.attributes.is_read = True
                    # Some value to have expression evaluation happy
                    return 1

                case EFC.Phase.ThreadOperation:
                    return self.configuration.epilogue_context.load[self.name].to(
                        self.efc.gemm.epi_dtype
                    )

                case EFC.Phase.PyTorchEvaluation:
                    return self.configuration.args[self.name]

                case _:
                    raise NotImplementedError(
                        f"load({self.name}) not implemented for phase {self.phase}"
                    )

        def store(self, value):
            """Store a tensor value inside the EFC function.

            The behavior depends on the phase:
            - ParameterAnalysis: mark the tensor as written (no data movement)
            - ThreadOperation: store into epilogue context with JIT dtype
            - PyTorchEvaluation: copy into the runtime output tensor
            """
            log(f"Tensor.store {self.name = } {self.phase = }")
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Record that the tensor is written:
                    self.attributes.is_written = True

                case EFC.Phase.ThreadOperation:
                    tRS_rD = self.configuration.epilogue_context.store[self.name]
                    tRS_rD.store(value.to(self.efc.jit.tensor_dtype[self.name]))

                case EFC.Phase.PyTorchEvaluation:
                    # Assign the PyTorch tensor target with the given value.
                    self.configuration.args[self.name].copy_(value)

                case _:
                    raise NotImplementedError(
                        f"store({self.name}) not implemented for phase {self.phase}"
                    )

        @property
        def remap_modes(self):
            """Remap modes of this tensor to match the output shape (m, n, l).

            Use subscript syntax with ``:`` for broadcast (``True``) and
            integers for mode indices::

                C.remap_modes[:,0,1].load()    # broadcast along first dim
                Y.remap_modes[1,0,2].store(v)  # transpose
                s.remap_modes[:,:,:].load()     # scalar broadcast

            This is a ``@property`` so that ``C.remap_modes`` (without
            parentheses) returns a helper object whose ``__getitem__``
            intercepts the ``[...]`` subscript.  Without ``@property``,
            ``C.remap_modes[:,0,1]`` would be a syntax error because
            Python would see ``remap_modes`` as an unsubscripted method
            object, not something that supports ``[]``.
            """
            return EFC._RemapModesAccessor(self)

    class Configuration:
        """Specialize the epilogue function provided by the user to be called in
        the compute kernel customization point at a given phase.
        """

        def __init__(self, efc: EFC, phase: EFC.Phase, *args):
            """According to the phase, args represent various things. For:
            - EFC.Phase.ParameterAnalysis:
              - args is empty and not used;
            - EFC.Phase.ThreadOperation:
              - args[0] is the epilogue_context;
            - EFC.Phase.PyTorchEvaluation:
              - args[0] is the matrix multiplication result as a torch.Tensor;
              - args[1] is a dict mapping argument names to the arguments, like
                the scalars or torch.Tensor. It is later extended when
                remap_modes() is used.
            """
            self.efc = efc
            self.phase = phase
            self._remap_cache = {}
            match self.phase:
                case EFC.Phase.ThreadOperation:
                    self.epilogue_context = args[0]

                case EFC.Phase.PyTorchEvaluation:
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
            given name.
            """
            if self.efc.parameter_attributes[name].is_tensor:
                # Delegate the phase-related behavior to the proxy Tensor object
                # itself.
                return EFC.Tensor(self.phase, name, self.efc, self)
            # Otherwise, we have a dynamic scalar parameter.
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Use some dummy value during introspection phase.
                    return cutlass.Float32(42).to(self.efc.gemm.epi_dtype)

                case EFC.Phase.ThreadOperation:
                    # Return directly the real kernel parameter with the same name.
                    return cutlass.Float32(self.efc.kernel.parameter[name]).to(
                        self.efc.gemm.epi_dtype
                    )

                case EFC.Phase.PyTorchEvaluation:
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
            access the EFC instance and its properties.
            """
            log(
                f"Configuration.__call__ evaluate the user EFC function {self.phase = } {self.arguments = }"
            )
            return self.efc.epilogue_function_configuration(self, *self.arguments)

        def accum(self):
            """Provide the accumulator value to the user."""
            log(f"Configuration.accum {self.phase = }")
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    log("Configuration.accum ParameterAnalysis 42!")
                    # The answer to anything.
                    return cutlass.Float32(42)

                case EFC.Phase.ThreadOperation:
                    log(
                        f"Configuration.accum ThreadOperation {self.epilogue_context.acc_vec = }"
                    )
                    return self.epilogue_context.acc_vec

                case EFC.Phase.PyTorchEvaluation:
                    log(f"Configuration.accum PyTorchEvaluation {self.accum_value = }")
                    return self.accum_value

                case _:
                    raise NotImplementedError(
                        f"accum() not implemented for phase {self.phase}"
                    )

        def remap_modes(
            self,
            source: EFC.Tensor,
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
            if not isinstance(source, EFC.Tensor):
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
                duplicates = sorted(
                    set(v for v in int_indices if int_indices.count(v) > 1)
                )
                raise ValueError(
                    f"source_mode_map contains duplicate source mode indices: "
                    f"{duplicates}. Each source mode must appear exactly once."
                )
            log(
                f"Configuration.remap_modes {source.name = } {source_mode_map = } {self.phase = }"
            )
            # Construct a new tensor as a remapped view with a mangled name
            # storing all the details.
            mangled_name = f"{source.name}__remapped__{'__'.join([str(e) for e in source_mode_map])}"
            # Return cached result if this exact remapping was already processed.
            # This avoids overwriting the ParameterAttributes entry (which would
            # lose is_read/is_written flags set by earlier .load()/.store() calls)
            # and avoids redundant EFC.Tensor proxy creation and PyTorch remapping.
            if mangled_name in self._remap_cache:
                return self._remap_cache[mangled_name]
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    log("EFC.remap_modes creates and registers a tensor")
                    # If the source_mode_map has only broadcast modes, it can be
                    # resolved to a scalar instead as an optimization.
                    broadcast_only = sum(v is True for v in source_mode_map) == len(
                        source_mode_map
                    )
                    # Register the new tensor.
                    self.efc.parameter_attributes[mangled_name] = (
                        EFC.Tensor.ParameterAttributes(
                            is_tensor=True,
                            mapped_source=source.name,
                            source_mode_map=source_mode_map,
                            degenerate_to_scalar=broadcast_only,
                        )
                    )

                case EFC.Phase.ThreadOperation:
                    log("EFC.remap_modes ThreadOperation returns Tensor proxy")
                    # Just use the proxy tensor as is, so .load() and .store()
                    # can work with it later.

                case EFC.Phase.PyTorchEvaluation:
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
            tensor = EFC.Tensor(self.phase, mangled_name, self.efc, self)
            self._remap_cache[mangled_name] = tensor
            return tensor

        # Some helper functions for common operations.

        def maximum(self, x, y):
            """Element-wise maximum of 2 tensors"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return EFC.maximum(x, y)
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.maximum(x, y)
                case _:
                    raise NotImplementedError(
                        f"maximum() not implemented for phase {self.phase}"
                    )

        def minimum(self, x, y):
            """Element-wise minimum of 2 tensors"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return EFC.minimum(x, y)
                case EFC.Phase.PyTorchEvaluation:
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
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return x
                case EFC.Phase.PyTorchEvaluation:
                    return x
                case _:
                    raise NotImplementedError(
                        f"identity() not implemented for phase {self.phase}"
                    )

        def relu(self, x):
            """ReLU activation function: f(x) = maximum(0, x)"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return EFC.maximum(x, self.full_like(x, 0))
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.nn.functional.relu(x)
                case _:
                    raise NotImplementedError(
                        f"relu() not implemented for phase {self.phase}"
                    )

        def leaky_relu(self, x, negative_slope=0.01):
            """Leaky ReLU activation function: f(x) = maximum(0, x) + negative_slope * minimum(0, x)"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    # Use self.full_like to have all the computation done with
                    # the same type as x element type.
                    zero = self.full_like(x, 0)
                    return EFC.maximum(x, zero) + EFC.minimum(x, zero) * self.full_like(
                        x, negative_slope
                    )
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.nn.functional.leaky_relu(x, negative_slope)
                case _:
                    raise NotImplementedError(
                        f"leaky_relu() not implemented for phase {self.phase}"
                    )

        def tanh(self, x):
            """Hyperbolic tangent activation function"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return cutlass.cute.tanh(x)
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.tanh(x)
                case _:
                    raise NotImplementedError(
                        f"tanh() not implemented for phase {self.phase}"
                    )

        def sigmoid(self, x):
            """Sigmoid activation function: f(x) = 1 / (1 + exp(-x))"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    # Use self.full_like to have all the computation done with
                    # the same type as x element type.
                    # sigmoid(x) = 1 / (1 + exp(-x))
                    return self.full_like(x, 1) / (
                        self.full_like(x, 1) + cutlass.cute.exp(-x)
                    )
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.sigmoid(x)
                case _:
                    raise NotImplementedError(
                        f"sigmoid() not implemented for phase {self.phase}"
                    )

        def silu(self, x):
            """SiLU (Swish) activation function: f(x) = x * sigmoid(x)"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    # silu(x) = x * sigmoid(x)
                    return x * self.sigmoid(x)
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.nn.functional.silu(x)
                case _:
                    raise NotImplementedError(
                        f"silu() not implemented for phase {self.phase}"
                    )

        def hardswish(self, x):
            """Hard Swish activation function: f(x) = x * relu6(x + 3) / 6"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    # Use self.full_like to have all the computation done with
                    # the same type as x element type.
                    # hardswish(x) = x * minimum(maximum(x + 3, 0), 6) / 6
                    relu6 = EFC.minimum(
                        EFC.maximum(x + self.full_like(x, 3), self.full_like(x, 0)),
                        self.full_like(x, 6),
                    )
                    return x * relu6 / self.full_like(x, 6)
                case EFC.Phase.PyTorchEvaluation:
                    import torch

                    return torch.nn.functional.hardswish(x)
                case _:
                    raise NotImplementedError(
                        f"hardswish() not implemented for phase {self.phase}"
                    )

        def gelu(self, x):
            """GELU (Gaussian Error Linear Unit) activation function."""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
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
                case EFC.Phase.PyTorchEvaluation:
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
            PyTorch.
            """

            def chameleon(self, *args, **kwargs):
                """The great impostor method.

                """
                log(f"Configuration.chameleon {name = } {self.phase = }")
                match self.phase:
                    case EFC.Phase.ParameterAnalysis:
                        # Just return a value to go on with the fake evaluation, in
                        # the case the function is expected to return a result. It
                        # will be ignored anyway in the opposite case.
                        return 1

                    case EFC.Phase.ThreadOperation:
                        # In the @cute.kernel context, just use the normal CuTe
                        # implementation.
                        return getattr(cutlass.cute, name)(*args, **kwargs)

                    case EFC.Phase.PyTorchEvaluation:
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

    def __init__(
        self,
        gemm,
        epilogue_function_configuration,
    ):
        """Construct an EFC instance."""
        self.gemm = gemm
        self.epilogue_function_configuration = epilogue_function_configuration
        self.analyze_epilogue(epilogue_function_configuration)

    def analyze_epilogue(self, epilogue_function_configuration):
        """Analyze the epilogue configuration function to extract its parameter
        names.
        """
        sig = inspect.signature(epilogue_function_configuration)
        names = list(sig.parameters)
        # Require the first parameter to be named "efc_config". This is very
        # intrusive but at the same time some people got confused when they
        # forgot this parameter.
        if names[0] != "efc_config":
            raise RuntimeError(
                "The epilogue configuration function must take efc_config as an argument"
            )

        # Keep all the argument names but the first "efc_config" one.
        self.epilogue_parameter_names = names[1:]
        log(f"{self.epilogue_parameter_names = }")

    def compile(self, *supplemental_arguments):
        """Compile with all the arguments to know the types during compilation
        while hiding the epilogue details.
        """
        if len(supplemental_arguments) != len(self.epilogue_parameter_names):
            raise ValueError(
                f"Expected {len(self.epilogue_parameter_names)} supplemental arguments "
                f"({', '.join(self.epilogue_parameter_names)}), got {len(supplemental_arguments)}."
            )
        # Update the active epilogue instance to use the new Parameter class
        self.analyze_epilogue_with_arguments(supplemental_arguments)
        # Create the metaprogramming objects for the @cute.jit and @cute.kernel
        # parts. For now just forward all the parameters as is.
        self.jit = EFC.JIT(self, self.epilogue_parameter_names)
        if not self.written_tensor_names:
            raise NotImplementedError(
                "The epilogue requires at least one written tensor to do something useful."
            )

    def analyze_epilogue_with_arguments(self, supplemental_arguments):
        # Keep track of the usage attributes of the tensors by their names.
        self.parameter_attributes = {}
        log(f"{self.analyze_epilogue_with_arguments}:")
        for name, a in zip(self.epilogue_parameter_names, supplemental_arguments):
            log(f"{name = } {a = }, {type(a) = }")
            self.parameter_attributes[name] = EFC.Tensor.ParameterAttributes(
                is_tensor=isinstance(a, cutlass.cute.Tensor)
            )

        # Evaluate the epilogue function for parameter analysis
        self.specialized_epilogue(EFC.Phase.ParameterAnalysis)()
        log(
            f"tensor attributes = {NEWLINE_AND_TAB}{NEWLINE_AND_TAB.join([name + ':' + TAB + str(attributes) for name, attributes in self.parameter_attributes.items()])}"
        )
        # Keep track of all the epilogue tensor use cases per name:
        self.used_tensor_names = []
        self.read_tensor_names = []
        self.written_tensor_names = []
        self.remapped_tensor_names = []
        for name, attributes in self.parameter_attributes.items():
            attributes = self.parameter_attributes[name]
            if not attributes.is_tensor:
                continue
            if attributes.is_read or attributes.is_written:
                self.used_tensor_names.append(name)
            if attributes.is_read:
                self.read_tensor_names.append(name)
            if attributes.is_written:
                self.written_tensor_names.append(name)
            if attributes.mapped_source:
                self.remapped_tensor_names.append(name)
        log(f"{TAB}{self.used_tensor_names = }")
        log(f"{TAB}{self.read_tensor_names = }")
        log(f"{TAB}{self.written_tensor_names = }")
        log(f"{TAB}{self.remapped_tensor_names = }")

    def specialized_epilogue(self, phase: typing.ForwardRef("EFC.Phase"), *args):
        """Construct a configuration of the epilogue specialized for a given
        phase. The arguments are opaque and depend on the actual phase use.
        """
        return EFC.Configuration(self, phase, *args)

    def foreach_argument(self, function):
        """Execute the given function for each supplemental argument of the epilogue."""
        for name, attributes in self.parameter_attributes.items():
            function(name, attributes)

    def foreach_tensor(self, function):
        """Execute the given function for each supplemental tensor."""
        for tensor_name in self.used_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_read_tensor(self, function):
        """Execute the given function for each supplemental read tensor."""
        for tensor_name in self.read_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_written_tensor(self, function):
        """Execute the given function for each supplemental written tensor."""
        for tensor_name in self.written_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_remapped_tensor(self, function):
        """Execute the given function for each supplemental remapped tensor."""
        for tensor_name in self.remapped_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def evaluate_on_cpu(self, matrix_multiplication_ref, args: tuple):
        """Evaluate the epilogue fusion configuration function on CPU for
        validation using the precomputed matrix multiplication result.

        Use PyTorch for now but could be whatever.
        """
        # A mapping from argument names to their values, scalars or torch.Tensor.
        epilogue_args = dict(zip(self.epilogue_parameter_names, args))
        # Evaluate the epilogue with PyTorch. The tensor arguments which are
        # stored are also evaluated and this is how some results are returned.
        self.specialized_epilogue(
            EFC.Phase.PyTorchEvaluation,
            matrix_multiplication_ref,
            epilogue_args,
        )()
