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

"""EFC leaf-utility module.

Holds logging, tracing, naming, and dtype-agnostic CuTe element-wise
helpers shared across the EFC modules (``_base``, ``_tensor``,
``_configuration``, ``_remap``).

This module has no dependencies on any other ``helpers.efc`` sibling --
it is the bottom of the EFC import graph by design.  Keep it that way:
do not add an ``import ._<sibling>`` here.
"""

from __future__ import annotations

import functools
import inspect
import logging
import os

import cutlass

# Some workaround for Python pre-3.12 f-string preventing the use of backslash.
NEWLINE_AND_TAB = "\n\t"
TAB = "\t"

# List of available activation functions in the EFC Configuration class.  This
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

# To have some verbosity, set the CUTE_DSL_EFC_LOG_LEVEL environment variable to
# INFO or even DEBUG before launching this program.  An invalid value falls
# back to WARNING with a one-shot warning rather than crashing module import.
if log_level := os.environ.get("CUTE_DSL_EFC_LOG_LEVEL"):
    resolved_level = getattr(logging, log_level.upper(), None)
    if isinstance(resolved_level, int):
        logging.basicConfig(level=resolved_level)
    else:
        logging.basicConfig(level=logging.WARNING)
        logging.getLogger(__name__).warning(
            "Ignoring invalid CUTE_DSL_EFC_LOG_LEVEL=%r", log_level
        )
logger = logging.getLogger(__name__)


def log(message: str):
    """Helper function to log messages.  Change ``logger.info`` to another level
    here if needed."""
    logger.info(message)


def if_debug(function):
    """Execute a function if in debug mode."""
    if logger.isEnabledFor(logging.DEBUG):
        function()


def if_info(function):
    """Execute a function if in info mode."""
    if logger.isEnabledFor(logging.INFO):
        function()


def mark_mlir(message: str):
    """Put some message in MLIR output to make MLIR assembly clearer or trace
    execution."""
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


def maximum(x, y):
    """Element-wise maximum of 2 CuTe tensors."""
    x_type = x.element_type
    y_type = y.element_type
    if x_type is not y_type:
        raise TypeError(f"Type mismatch: x is {x_type}, y is {y_type}")
    return cutlass.cute.where(x > y, x, y)


def minimum(x, y):
    """Element-wise minimum of 2 CuTe tensors."""
    x_type = x.element_type
    y_type = y.element_type
    if x_type is not y_type:
        raise TypeError(f"Type mismatch: x is {x_type}, y is {y_type}")
    return cutlass.cute.where(x < y, x, y)
