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

# This not to use module annotations from future version but to change the type system to postpone the evaluation of annotations,
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
import torch

# To have some verbosity, set the CUTE_DSL_EFC_LOG_LEVEL environment variable to
# INFO or even DEBUG before launching this program.
if log_level := os.environ.get("CUTE_DSL_EFC_LOG_LEVEL", None):
    logging.basicConfig(level=getattr(logging, log_level))
logger = logging.getLogger(__name__)


def log(message: str):
    """Helper function to log messages. Change logger.info to another level here
    if needed."""
    logger.info(message)


"""
CUTLASS EFC Framework
"""

# Available activation functions in the EFC Configuration class
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


def if_debug(function):
    """Execute a function if in debug mode."""
    if logger.isEnabledFor(logging.DEBUG):
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


class VariadicParameters:
    """Minimal mixin wrapper for variadic parameters for @cute.jit/@cute.kernel
    functions taking advantage that the DSL to can ingest a recursive
    combination of tuples and lists."""

    def __init__(self, efc, parameter_names):
        # Add local shortcuts to the efc and gemm objects
        self.efc = efc
        self.gemm = efc.gemm
        # Create a dataclass to have an aggregate initializer.
        # Use __slots__ to avoid assigning wrong argument by error.
        fields = [(name, typing.Any) for name in parameter_names]
        self._parameter_class = dataclasses.make_dataclass(
            "Parameter", fields, slots=True
        )

        # Add some methods to the dataclass so we can access for example arg.a
        # and parameter.b also with arg["a"] or parameter["b"].
        def getitem(self, name):
            """Access the dataclass attribute by name."""
            return getattr(self, name)

        self._parameter_class.__getitem__ = getitem

        def setitem(self, name, value):
            """Set the dataclass attribute by name."""
            setattr(self, name, value)

        self._parameter_class.__setitem__ = setitem

        self.instantiate_args()
        logger.info(f"Initial {self.arg = }")

    def pack_arguments(self, *args, **kwargs):
        """Pack the arguments to pass them through a @cute.jit/@cute.kernel
        call.

        If some arguments are provided, pack them, otherwise just use the
        self.arg object by default.

        Return a tuple as an interface object since a @cute.jit/@cute.kernel
        can ingest a recursive combination of tuples and lists."""
        if args or kwargs:
            # Override the current argument object from the provided arguments, if any.
            self.arg = self._parameter_class(*args, **kwargs)
        # dataclasses.astuple(self.arg) breaks because it is recursive and
        # applies a deepcopy incompatible with the DSL magic. Just generate 1
        # level of tuple of object references.
        r = tuple(self.arg[f.name] for f in dataclasses.fields(self.arg))
        logger.info(f"pack_arguments {args = } {kwargs = } {self.arg = } {r = }")
        # The DSL does not accept an empty tuple but can handle None. So
        # remap to None in that case.
        if not r:
            return None
        return r

    def unpack_parameters(self, p: typing.Tuple):
        """Unpack the parameters inside a @cute.jit/@cute.kernel function.

        Assign all the self.parameter attributes."""
        # Do the opposite mapping of None to an empty tuple to have the
        # parameter constructor happy.
        if p is None:
            p = ()
        # Instantiate the dataclass holding the parameters from the
        # individual parameter values.
        self.parameter = self._parameter_class(*p)
        logger.info(f"unpack_parameters {p = } {self.parameter = }")

    def instantiate_args(self):
        """Create an arg attribute from the Parameter class to be used
        as an alternative way to pass the arguments instead of using an
        explicit pack_arguments().

        All the arg attributes are initialized to a noticeable name so that
        any forgotten field will trigger an error."""

        class _UnassignedArgument:
            """Sentinel class to detect uninitialized arguments"""

            def __repr__(self):
                return "<UnassignedArgument>"

        self.arg = self._parameter_class(
            *([_UnassignedArgument] * len(dataclasses.fields(self._parameter_class)))
        )


class EFC:
    """Epilogue Fusion Configuration."""

    # Helper functions for CuTe operations
    @staticmethod
    def maximum(x, y):
        """Element-wise maximum of 2 CuTe tensors"""
        x_type = x.element_type
        y_type = y.element_type
        assert x_type is y_type, f"Type mismatch: x is {x_type}, y is {y_type}"
        return cutlass.cute.where(x > y, x, y)

    @staticmethod
    def minimum(x, y):
        """Element-wise minimum of 2 CuTe tensors"""
        x_type = x.element_type
        y_type = y.element_type
        assert x_type is y_type, f"Type mismatch: x is {x_type}, y is {y_type}"
        return cutlass.cute.where(x < y, x, y)

    class JIT(VariadicParameters):
        """Handle Python/@cute.jit and its boundaries with Host."""

        # All the following customization functions should go somewhere else in
        # the long term, as part of a refactoring similar to CUTLASS
        # collective/main loop/epilogue...

        @trace_in_mlir
        def record_tensor_dtypes(self):
            """It does not seem that the tma_tensor and tma_atom carry over the
            element type, so, store it here for later use."""
            self.tensor_dtype = {}

            def f(tensor_name, attributes):
                tensor = self.parameter[tensor_name]
                self.tensor_dtype[tensor_name] = tensor.element_type

            self.efc.foreach_tensor(f)

        @trace_in_mlir
        def written_tensor_name_with_bigger_element_type(self):
            """The type of the written tensor is used to compute a lot of
            implementation details about tiling and so on in the kernel.

            The compilation phase has checked already there is at least 1
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
            implementation details about tiling and so on in the kernel. Return the name of the read tensor with the biggest element_type, or None if there is no read tensor."""
            if self.efc.read_tensor_names:
                return max(
                    (tensor_name for tensor_name in self.efc.read_tensor_names),
                    key=lambda tensor_name: self.tensor_dtype[tensor_name].width,
                )
            return None

        @trace_in_mlir
        def compute_stage(self):
            """Get the contribution from the tensors used in the EFC to the
            pipeline stage numbers."""
            self.smem_size_of_read_tensors = 0
            self.smem_size_of_written_tensors = 0
            self.tensor_dtype = {}

            def f(tensor_name, attributes):
                tensor = self.parameter[tensor_name]
                tensor_layout = cutlass.utils.LayoutEnum.from_tensor(tensor)
                if cutlass.const_expr(self.gemm.d_layout != tensor_layout):
                    error_msg = (
                        f"The tensor {tensor_name} has layout {tensor_layout} which is "
                        f"different from C/D specified layout {self.gemm.d_layout}."
                    )
                    raise ValueError(error_msg)

                # It does not seem that the tma_tensor and tma_atom carry over
                # the element type, so, store it here for later use.
                self.tensor_dtype[tensor_name] = tensor.element_type

                smem_size_in_bytes_of_a_pipeline_stage = cutlass.cute.size_in_bytes(
                    tensor.element_type,
                    cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                        tensor.element_type, self.gemm.d_layout, self.gemm.epi_tile, 1
                    ),
                )
                # Prepare the information to be asked soon, to recycle this
                # loop.
                if attributes.is_read:
                    self.smem_size_of_read_tensors += (
                        smem_size_in_bytes_of_a_pipeline_stage
                    )
                if attributes.is_written:
                    self.smem_size_of_written_tensors += (
                        smem_size_in_bytes_of_a_pipeline_stage
                    )

            self.efc.foreach_tensor(f)

        @trace_in_mlir
        def smem_size_in_bytes_of_read_tensors(self):
            """Get the contribution in a smem pipeline stage from the tensors
            loaded in the EFC."""
            logger.info(f"\t{self.smem_size_of_read_tensors = }")
            return self.smem_size_of_read_tensors

        @trace_in_mlir
        def smem_size_in_bytes_of_written_tensors(self):
            """Get the contribution in a smem pipeline stage from the tensors
            stored in the EFC."""
            logger.info(f"\t{self.smem_size_of_written_tensors = }")
            return self.smem_size_of_written_tensors

        @trace_in_mlir
        def smem_layout(self):
            """Get the smem_layout for the tensors used in the EFC."""
            self.smem_layout_staged_read = {}
            self.smem_layout_staged_written = {}

            def f(tensor_name, attributes):
                tensor = self.parameter[tensor_name]
                tensor_layout = cutlass.utils.LayoutEnum.from_tensor(tensor)
                log(f"JIT.smem_layout {tensor_name} = {tensor!s}")
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

            self.efc.foreach_tensor(f)

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

            def f(tensor_name, attributes):
                tensor = self.parameter[tensor_name]

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
                        f"JIT.tma_atom_read[{tensor_name}] = {self.tma_atom_read[tensor_name]!s}"
                    )
                    log(
                        f"JIT.tma_tensor_read[{tensor_name}] = {self.tma_tensor_read[tensor_name]!s}"
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
                        f"JIT.tma_atom_written[{tensor_name}] = {self.tma_atom_written[tensor_name]!s}"
                    )
                    log(
                        f"JIT.tma_tensor_written[{tensor_name}] = {self.tma_tensor_written[tensor_name]!s}"
                    )

            self.efc.foreach_tensor(f)

        @trace_in_mlir
        def create_supplemental_arguments_for_kernel(self):
            """Executed before launching the @cute.kernel function to set up the
            supplemental arguments to pass to the @cute.kernel function.

            In the @cute.kernel example, the parameters like `X_tma_tensor_read`
            or `Y_tma_tensor_written` correspond to `mX_mnl` and `mY_mnl`."""
            argument_names = []

            def compute_argument_names(name, attributes):
                if not attributes.is_tensor:
                    # Just propagate the dynamic scalar with the same name.
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

            self.efc.foreach_argument(compute_argument_names)
            # Create the @cute.kernel-side meta-programming infrastructure
            # handling also the supplemental argument handling.
            self.efc.kernel = EFC.Kernel(self.efc, argument_names)

            arg = self.efc.kernel.arg

            def populate_the_kernel_arguments(name, attributes):
                if not attributes.is_tensor:
                    # Just propagate the dynamic scalar with the same name.
                    arg[name] = self.parameter[name]
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

            self.efc.foreach_argument(populate_the_kernel_arguments)

    class Kernel(VariadicParameters):
        """Handle kernel part and @cute.jit/@cute.kernel boundaries."""

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

            self.efc.foreach_tensor(f)

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

            self.efc.foreach_tensor(f)

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

            self.efc.foreach_tensor(f)

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

            self.efc.foreach_tensor(f)

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

            self.efc.foreach_written_tensor(f)

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

            self.efc.foreach_read_tensor(f)

        @trace_in_mlir
        def epilogue_computation(self, epilogue_context):
            """Execute the EFC epilogue."""

            epilogue_context.load = {}
            epilogue_context.store = {}

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

            self.efc.foreach_read_tensor(load_setup)

            def store_setup(tensor_name, attributes):
                epilogue_context.store[tensor_name] = self.tRS_rD[tensor_name]
                log(
                    f"Kernel.epilogue_computation store_setup: epilogue_context.store[{tensor_name}] = {epilogue_context.store[tensor_name]!s}"
                )

            self.efc.foreach_written_tensor(store_setup)

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

            self.efc.foreach_written_tensor(f)

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

            self.efc.foreach_written_tensor(f)

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

            self.efc.foreach_read_tensor(f)

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

            self.efc.foreach_read_tensor(f)

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

            self.efc.foreach_read_tensor(f)

    class Phase(enum.Enum):
        ParameterAnalysis = enum.auto()
        """Epilogue function during analysis of its parameters."""

        ThreadOperation = enum.auto()
        """Epilogue function used for computation."""

        PyTorchEvaluation = enum.auto()
        """Epilogue function used for verification on CPU with PyTorch."""

    class Tensor:
        """A proxy object to be used as an argument to introspect or execute the
        epilogue configuration function in a given phase."""

        @dataclasses.dataclass
        class ParameterAttributes:
            """Store some characteristics of the epilogue parameters"""

            is_tensor: bool  # Tensor or scalar
            is_read: bool = False
            is_written: bool = False

        def __init__(
            self,
            phase: typing.ForwardRef("EFC.Phase"),
            name: str,
            efc: EFC,
            configuration,
        ):
            self.phase = phase
            self.name = name
            self.efc = efc
            self.configuration = configuration
            self.attributes: EFC.Tensor.ParameterAttributes = efc.parameter_attributes[
                name
            ]
            logger.info(f"Tensor {self.name = }")

        def load(self):
            """"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Record that the tensor is read:
                    self.attributes.is_read = True
                    # Some value to have expression evaluation happy
                    return 1

                case EFC.Phase.ThreadOperation:
                    # arg[0] is the epilogue_context from epilogue_computation().
                    return (
                        self.configuration.args[0]
                        .load[self.name]
                        .to(self.efc.gemm.epi_dtype)
                    )

                case EFC.Phase.PyTorchEvaluation:
                    # args[1] is VariadicParameters constructed in
                    # evaluate_on_cpu(). Use .arg and not .parameter since it is
                    # not used actually to handle variadic parameter passing
                    # here. Just return the PyTorch tensor.
                    # TODO: Need to map to matching cutlass type.
                    return self.configuration.args[1].arg[self.name]

                case _:
                    raise NotImplementedError(
                        f"load({self.name}) not implemented for phase {self.phase}"
                    )

        def store(self, value):
            """"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Record that the tensor is written:
                    self.attributes.is_written = True

                case EFC.Phase.ThreadOperation:
                    # arg[0] is the epilogue_context from epilogue_computation().
                    tRS_rD = self.configuration.args[0].store[self.name]
                    tRS_rD.store(value.to(self.efc.jit.tensor_dtype[self.name]))

                case EFC.Phase.PyTorchEvaluation:
                    # args[1] is VariadicParameters constructed in
                    # evaluate_on_cpu(). Use .arg and not .parameter since it is
                    # not used actually to handle variadic parameter passing
                    # here. Assign the PyTorch tensor target with the given
                    # value.
                    self.configuration.args[1].arg[self.name].copy_(value)

                case _:
                    raise NotImplementedError(
                        f"store({self.name}) not implemented for phase {self.phase}"
                    )

    class Configuration:
        """Specialize the epilogue provided by the user to be called in the
        compute kernel customization point at a given phase."""

        def __init__(self, efc: EFC, phase: EFC.Phase, *args):
            """"""
            self.efc = efc
            self.phase = phase
            # args[0] is the epilogue_context from the kernel for EFC.Phase.ThreadOperation.
            self.args = args
            self.arguments = [
                self._argument(name) for name in efc.epilogue_parameter_names
            ]

        def _argument(self, name):
            """Generate the argument used by the specialized epilogue with the
            given name"""
            if self.efc.parameter_attributes[name].is_tensor:
                # Delegate the phase-related behavior to the Tensor object
                # itself.
                return EFC.Tensor(self.phase, name, self.efc, self)
            # Otherwise, we have a dynamic scalar parameter.
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # Use some dummy value during introspection phase.
                    return cutlass.Float32(42).to(self.efc.gemm.epi_dtype)

                case EFC.Phase.ThreadOperation:
                    # TODO: Need to map to matching cutlass type.
                    # Return directly the real kernel parameter with the same name.
                    return cutlass.Float32(self.efc.kernel.parameter[name]).to(
                        self.efc.gemm.epi_dtype
                    )

                case EFC.Phase.PyTorchEvaluation:
                    # args[1] is VariadicParameters constructed in
                    # evaluate_on_cpu(). Use .arg and not .parameter since it is
                    # not used actually to handle variadic parameter passing
                    # here.
                    # TODO: Need to map to matching cutlass type.
                    return self.args[1].arg[name]

                case _:
                    raise NotImplementedError(
                        f"argument({name}) not implemented for phase {self.phase}"
                    )

        def __call__(self):
            """Execute the epilogue provided by the end-user with some specific
            arguments crafted for the current phase.

            Pass self as an argument, to be seen as `efc_config`, a way to
            access the EFC instance and its properties."""
            return self.efc.epilogue_function_configuration(self, *self.arguments)

        def accum(self):
            """Provide the accumulator value to the user."""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    # The answer to anything.
                    return cutlass.Float32(42)

                case EFC.Phase.ThreadOperation:
                    # args[0] is epilogue_context passed to
                    # efc.kernel.epilogue_computation().
                    return self.args[0].acc_vec

                case EFC.Phase.PyTorchEvaluation:
                    # Return matrix_multiplication_ref from evaluate_on_cpu().
                    return self.args[0]

                case _:
                    raise NotImplementedError(
                        f"accum() not implemented for phase {self.phase}"
                    )

        # Some helper functions for common operations.

        def maximum(self, x, y):
            """Element-wise maximum of 2 tensors"""
            match self.phase:
                case EFC.Phase.ParameterAnalysis:
                    return 1
                case EFC.Phase.ThreadOperation:
                    return EFC.maximum(x, y)
                case EFC.Phase.PyTorchEvaluation:
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
                    # same type as x element type.
                    zero = self.full_like(x, 0)
                    return EFC.maximum(x, zero) + EFC.minimum(x, zero) * self.full_like(
                        x, negative_slope
                    )
                case EFC.Phase.PyTorchEvaluation:
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
                    # same type as x element type.
                    # sigmoid(x) = 1 / (1 + exp(-x))
                    return self.full_like(x, 1) / (
                        self.full_like(x, 1) + cutlass.cute.exp(-x)
                    )
                case EFC.Phase.PyTorchEvaluation:
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
                    # same type as x element type.
                    # hardswish(x) = x * minimum(maximum(x + 3, 0), 6) / 6
                    relu6 = EFC.minimum(
                        EFC.maximum(x + self.full_like(x, 3), self.full_like(x, 0)),
                        self.full_like(x, 6),
                    )
                    return x * relu6 / self.full_like(x, 6)
                case EFC.Phase.PyTorchEvaluation:
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
                    # same type as x element type.
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

                TODO: add some level of configuration to tweak the CuTe/Python
                name mapping, handle some specific default values for some
                parameters..."""

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
        names."""
        sig = inspect.signature(epilogue_function_configuration)
        names = [name for name in sig.parameters.keys()]
        # Impose to have the first parameter named "efc_config". This is very
        # intrusive but at the same time some people got confused when they
        # forgot this parameter.
        if names[0] != "efc_config":
            raise RuntimeError(
                "The epilogue configuration function must take efc_config as an argument"
            )

        # Keep all the argument names but the first "efc_config" one.
        self.epilogue_parameter_names = names[1:]
        logger.info(f"{self.epilogue_parameter_names = }")

    def compile(self, supplemental_arguments):
        """Compile with all the arguments to know the types during compilation
        while hiding the epilogue detail1s."""
        assert len(supplemental_arguments) == len(self.epilogue_parameter_names)
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
        self.parameter_attributes = {}
        logger.info(f"{self.analyze_epilogue_with_arguments}:")
        for name, a in zip(self.epilogue_parameter_names, supplemental_arguments):
            logger.info(f"{name = } {a = }, {type(a) = }")
            self.parameter_attributes[name] = EFC.Tensor.ParameterAttributes(
                is_tensor=isinstance(a, cutlass.cute.Tensor)
            )

        # Evaluate the epilogue function for parameter analysis
        self.specialized_epilogue(EFC.Phase.ParameterAnalysis)()
        logger.info(f"\t{self.parameter_attributes = }")
        # Keep track of all the epilogue tensor use cases per name:
        self.used_tensor_names = []
        self.read_tensor_names = []
        self.written_tensor_names = []
        for name in self.epilogue_parameter_names:
            q = self.parameter_attributes[name]
            if not q.is_tensor:
                continue
            if q.is_read or q.is_written:
                self.used_tensor_names.append(name)
            if q.is_read:
                self.read_tensor_names.append(name)
            if q.is_written:
                self.written_tensor_names.append(name)
        logger.info(
            f"\t{self.used_tensor_names = }\n\t{self.read_tensor_names = }\n\t{self.written_tensor_names = }"
        )

    def specialized_epilogue(self, phase: typing.ForwardRef("EFC.Phase"), *args):
        """Construct a configuration of the epilogue specialized for a given
        phase. The arguments are opaque and depend on the actual phase use."""
        return EFC.Configuration(self, phase, *args)

    def foreach_argument(self, function):
        """Execute the given function for each supplemental argument of the epilogue."""
        for name in self.epilogue_parameter_names:
            attributes = self.parameter_attributes[name]
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

    def evaluate_on_cpu(self, matrix_multiplication_ref, *args):
        """Evaluate the epilogue fusion configuration function on CPU for
        validation using the precomputed matrix multiplication result.

        Use PyTorch for now but could be whatever."""
        # Recycle the VariadicParameters class to map the arguments according to
        # their names:
        epilogue_args = VariadicParameters(self, self.epilogue_parameter_names)
        epilogue_args.pack_arguments(*args)
        # Evaluate the epilogue with PyTorch. The tensor arguments which are
        # stored are also evaluated and this is how some results are returned.
        self.specialized_epilogue(
            EFC.Phase.PyTorchEvaluation,
            matrix_multiplication_ref,
            epilogue_args,
        )()
