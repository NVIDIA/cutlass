# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import os
from typing import Any, Dict, Optional, Union
from functools import total_ordering
from dataclasses import dataclass

"""
This module provides a Exception classes DSL class for any Dialect.
"""


# Add color codes at the top of the file after imports
class Colors:
    """ANSI color codes for error messages"""

    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


# =============================================================================
# DSL Exceptions
# =============================================================================


class DSLBaseError(Exception):
    """
    Base exception for DSL-related errors.
    Provides optional contextual metadata to aid in debugging.
    """

    def __init__(
        self,
        message: str,
        line: Optional[int] = None,
        snippet: Optional[str] = None,
        filename: Optional[str] = None,
        error_code: Optional[Union[str, int]] = None,
        context: Optional[Union[Dict[str, Any], str]] = None,
        suggestion: Optional[str] = None,
        cause: Optional[BaseException] = None,
    ) -> None:
        self.message = message
        self.line = line
        self.filename = filename
        self.snippet = snippet
        self.error_code = error_code
        self.context = context
        self.suggestion = suggestion
        self.cause = cause

        super().__init__(self._format_message())

    def _format_message(self):
        """
        Formats the complete error message with available metadata.
        Override this in subclasses if you want to change formatting logic.
        """
        parts = [f"{self.__class__.__name__}: {self.message}"]

        if self.error_code is not None:
            parts.append(f"{Colors.BOLD}Error Code:{Colors.RESET} {self.error_code}\n")

        if self.line is not None:
            parts.append(f"  Line: {self.line}")

        if self.filename is not None:
            parts.append(f"  File: {self.filename}")

        if self.snippet:
            # Optionally truncate long snippets for readability
            parts.append(f"  Snippet: \n {self.snippet}")

        if self.cause:
            parts.append(f"  Caused exception: {self.cause}")

        if self.context:
            if isinstance(self.context, dict):
                parts.append(f"{Colors.BLUE}🔍 Additional Context:{Colors.RESET}\n")
                for key, value in self.context.items():
                    parts.append(f"    {key}: {value}")
            else:
                parts.append(
                    f"{Colors.BLUE}🔍 Additional Context:{Colors.RESET} {self.context}"
                )

        if self.suggestion:
            parts.append(f"{Colors.GREEN}💡 Suggestions:{Colors.RESET}")
            if isinstance(self.suggestion, (list, tuple)):
                for suggestion in self.suggestion:
                    parts.append(f" {Colors.GREEN}{suggestion}{Colors.RESET}")
            else:
                parts.append(f" {self.suggestion}")

        return "\n".join(parts)


class DSLRuntimeError(DSLBaseError):
    """
    Raised when an error occurs during JIT-time code generation in the DSL.
    """

    # Inherits all logic from DSLBaseError; override methods if you need
    # specialized behavior or formatting for runtime errors.
    pass


def _get_friendly_cuda_error_message(error_code, error_name):
    # Avoid circular dependency
    from .runtime.cuda import get_device_info

    """Get a user-friendly error message for common CUDA errors."""
    # Strip the byte string markers if present
    if isinstance(error_name, bytes):
        error_name = error_name.decode("utf-8")
    elif (
        isinstance(error_name, str)
        and error_name.startswith("b'")
        and error_name.endswith("'")
    ):
        error_name = error_name[2:-1]

    # Add target architecture info
    target_arch = os.getenv("CUTE_DSL_ARCH", "unknown")

    additional_info = {
        "CUDA_ERROR_INVALID_SOURCE": (
            f"{Colors.RED}❌ Failed to load CUDA kernel - likely architecture mismatch.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_NO_BINARY_FOR_GPU": (
            f"{Colors.RED}❌ CUDA kernel not compatible with your GPU.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_OUT_OF_MEMORY": (
            f"{Colors.RED}💾 CUDA out of memory error.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_DEVICE": (
            f"{Colors.RED}❌ Invalid CUDA device.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_NOT_INITIALIZED": (
            f"{Colors.RED}❌ CUDA context not initialized.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_CONTEXT": (
            f"{Colors.RED}❌ CUDA context not initialized.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_VALUE": (
            f"{Colors.RED}⚠️ Invalid parameter passed to CUDA operation.{Colors.RESET}\n\n"
            f"{Colors.YELLOW}This is likely a bug - please report it with:{Colors.RESET}"
        ),
        "CUDA_ERROR_INVALID_CLUSTER_SIZE": (
            f"{Colors.RED}❌ Invalid cluster size.{Colors.RESET}\n\n"
        ),
    }

    error_suggestions = {
        "CUDA_ERROR_INVALID_CONTEXT": (
            f"1. Check if CUDA context is properly initialized under your environment",
            f"2. Initialize CUDA context with `cuda.cuInit(0)` or `cutlass.cuda.initialize_cuda_context()`",
        ),
        "CUDA_ERROR_INVALID_SOURCE": (
            f"1. Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            f"2. Clear the compilation cache and regenerate the kernel",
            f"3. Check CUDA toolkit installation",
        ),
        "CUDA_ERROR_NO_BINARY_FOR_GPU": (
            f"Set env CUTE_DSL_ARCH to match your GPU architecture",
        ),
        "CUDA_ERROR_OUT_OF_MEMORY": (
            f"1. Reduce batch size",
            f"2. Reduce model size",
            f"3. Free unused GPU memory",
        ),
        "CUDA_ERROR_INVALID_DEVICE": (
            f"1. Check if CUDA device is properly initialized",
            f"2. Verify GPU is detected: nvidia-smi",
            f"3. Check CUDA_VISIBLE_DEVICES environment variable",
        ),
        "CUDA_ERROR_NOT_INITIALIZED": (
            f"1. Check CUDA driver installation",
            f"2. call `cuda.cuInit(0)` before any other CUDA operation",
            f"3. Run nvidia-smi to confirm GPU status",
        ),
        "CUDA_ERROR_INVALID_VALUE": (
            f"1. Your GPU model",
            f"2. SM ARCH setting",
            f"3. Steps to reproduce",
        ),
        "cudaErrorInsufficientDriver": (
            f"1. Run nvidia-smi to confirm CUDA driver version",
            f"2. Ensure the CUDA driver version meets the requirement of the installed cuda-python package",
        ),
    }

    message = (
        f"{error_name} (error code: {error_code}) \n"
        f"{additional_info.get(error_name, '')} \n\n{Colors.RESET}"
    )

    # Add debug information
    debug_info = f"\n- {Colors.BOLD}Error name: {error_name}\n"
    debug_info += f"- Error code: {error_code}\n"
    debug_info += f"- CUDA_TOOLKIT_PATH: {os.getenv('CUDA_TOOLKIT_PATH', 'not set')}\n"
    debug_info += (
        f"- Target SM ARCH: {os.getenv('CUTE_DSL_ARCH', 'not set')}{Colors.RESET}\n"
    )

    try:
        # Get GPU information using CUDA Python API
        debug_info += f"\n{Colors.BLUE}📊 GPU Information:{Colors.RESET}\n"
        gpu_info = get_device_info()
        debug_info += gpu_info.pretty_str()

        if target_arch and gpu_info.compatible_archs:
            debug_info += f"\n{Colors.BOLD}Compatibility Check:{Colors.RESET}\n"

            if target_arch not in gpu_info.compatible_archs:
                debug_info += (
                    f"{Colors.RED}❌ Error: Target SM ARCH {target_arch} is not compatible\n"
                    f"💡 Please use one of SM ARCHs: "
                    f"{Colors.GREEN}{', '.join(gpu_info.compatible_archs or [])}{Colors.RESET}\n"
                )
            elif target_arch != gpu_info.sm_arch:
                debug_info += (
                    f"{Colors.YELLOW}⚠️  Warning: Using compatible but non-optimal architecture\n"
                    f"• Current: {target_arch}\n"
                    f"• Recommended: {Colors.GREEN}{gpu_info.sm_arch}{Colors.RESET} (native)\n"
                )
            else:
                debug_info += f"{Colors.GREEN}✓ Using optimal architecture: {gpu_info.sm_arch}{Colors.RESET}\n"

    except Exception as e:
        debug_info += (
            f"\n{Colors.YELLOW}ℹ️  Could not retrieve GPU info: {str(e)}{Colors.RESET}"
        )

    return message, debug_info, error_suggestions.get(error_name, "")


class DSLCudaRuntimeError(DSLBaseError):
    """
    Raised when an error occurs during CUDA runtime code generation in the DSL.
    """

    # Inherits all logic from DSLRuntimeError; override methods if you need
    # specialized behavior or formatting for runtime errors.
    def __init__(self, error_code, error_name) -> None:
        self._error_code = error_code
        self._error_name = error_name
        message, debug_info, suggestion = _get_friendly_cuda_error_message(
            error_code, error_name
        )

        super().__init__(
            message, error_code=error_code, context=debug_info, suggestion=suggestion
        )


class DSLAstPreprocessorError(DSLBaseError):
    """
    Raised when an error occurs during AST preprocessing or visiting in the DSL.
    """

    # Same approach: You could override _format_message if you want
    # to emphasize AST node details or anything specific to preprocessing.
    pass


class DSLNotImplemented(DSLBaseError):
    """
    Raised when a feature of the DSL is not implemented yet.
    """

    # Useful for stubs in your DSL that you plan to implement in the future.
    pass


class CudaDriverDependencyError(DSLRuntimeError):
    """Custom error class for CUDA driver dependency issues"""

    def __init__(
        self,
        message: str,
    ):
        # Create a detailed error message with instructions
        detailed_message = f"""CUDA Driver Dependency Error

{message}

This error typically occurs when:
• NVIDIA GPU drivers are not installed on your system
• The installed drivers are incompatible with CUDA Toolkit 12.9 or latest version
• The libcuda.so.1 library is not accessible"""

        # Use DSLRuntimeError's structured approach
        super().__init__(
            detailed_message,
            suggestion=[
                "Install or update NVIDIA GPU drivers:",
                "  • Visit: https://www.nvidia.com/Download/index.aspx",
                "  • Download drivers compatible with CUDA Toolkit 12.9 or latest version",
                "  • Follow the installation instructions for your OS",
                "",
                "Verify driver installation:",
                "  • Run: nvidia-smi",
                "  • This should display GPU information without errors",
                "",
                "Check CUDA library availability:",
                "  • Run: ldconfig -p | grep libcuda",
                "  • This should show libcuda.so.1 in the output",
                "",
                "For more information, see:",
                "  • CUDA Toolkit documentation: https://docs.nvidia.com/cuda/",
                "  • CUTLASS DSL requirements: nvidia-cutlass-dsl documentation",
            ],
        )


def _get_cuda_version() -> str:
    # Client of this module should implement this function
    """
    Placeholder for CUDA version query.

    This function should be implemented by the client of this module.
    When implemented, it must return the CUDA version as a string, e.g. "12.2".

    Raises:
        NotImplementedError: Always, unless overridden by the package initializer or client.
    """
    raise NotImplementedError("_get_cuda_version is not implemented")


@total_ordering
@dataclass(frozen=True)
class DSLCudaVersion:
    """
    Class to represent the CUDA version used to build the DSL.
    """

    major: int
    minor: int

    def __init__(self, version: str):
        parts = version.split(".")
        object.__setattr__(self, "major", int(parts[0]))
        object.__setattr__(self, "minor", int(parts[1]))

    def __eq__(self, other):
        return self.major == other.major and self.minor == other.minor

    def __lt__(self, other):
        return [self.major, self.minor] < [other.major, other.minor]


def _coerce_to_cuda_version(
    value: Optional[Union[DSLCudaVersion, str]], param_name: str
) -> Optional[DSLCudaVersion]:
    """
    Coerce a value to DSLCudaVersion.

    :param value: The value to coerce (DSLCudaVersion, str, or None).
    :param param_name: The parameter name for error messages.
    :returns: DSLCudaVersion or None if value is None.
    :raises DSLRuntimeError: If value is not a supported type.
    """
    if value is None:
        return None
    if isinstance(value, DSLCudaVersion):
        return value
    if isinstance(value, str):
        return DSLCudaVersion(value)
    raise DSLRuntimeError(
        f"{param_name} must be a DSLCudaVersion or str, got {type(value).__name__}"
    )


def target_version(
    exact_version: Optional[Union[DSLCudaVersion, str]] = None,
    *,
    min_version: Optional[Union[DSLCudaVersion, str]] = None,
    max_version: Optional[Union[DSLCudaVersion, str]] = None,
) -> bool:
    """
    Check if the current CUDA version used to build the DSL matches an exact version
    or falls within specified bounds at compile-time.

    Only one of ``exact_version`` *or* ``min_version``/``max_version`` may be specified.
    At least one must be provided.

    :param exact_version: The required CUDA version (e.g., "12.3").
    :type exact_version: Optional[Union[DSLCudaVersion, str]]
    :param min_version: The minimum CUDA version required (inclusive, e.g., "12.0").
    :type min_version: Optional[Union[DSLCudaVersion, str]]
    :param max_version: The maximum CUDA version allowed (inclusive, e.g., "13.2").
    :type max_version: Optional[Union[DSLCudaVersion, str]]

    :returns: ``True`` if the CUDA version matches the requirement(s) specified.
    :rtype: bool

    :raises DSLRuntimeError:
        - If neither an ``exact_version`` nor version range is given.
        - If both an exact version and a range are provided.
        - If ``min_version`` > ``max_version``.
        - If any version parameter is not a DSLCudaVersion or str.

    **Examples**

    .. code-block:: python

        target_version(exact_version="12.3")
        # True if CUDA_VERSION == 12.3

        target_version(min_version="12.0")
        # True if CUDA_VERSION >= 12.0

        target_version(max_version="13.2")
        # True if CUDA_VERSION <= 13.2

        target_version(min_version="12.0", max_version="13.2")
        # True if 12.0 <= CUDA_VERSION <= 13.2
    """
    # Avoid circular dependency
    from .version_info import CUDA_VERSION

    # Coerce all version parameters to DSLCudaVersion at the start
    exact_v = _coerce_to_cuda_version(exact_version, "exact_version")
    min_v = _coerce_to_cuda_version(min_version, "min_version")
    max_v = _coerce_to_cuda_version(max_version, "max_version")

    # Sanity check
    is_range_check = min_v is not None or max_v is not None
    is_exact_version_check = exact_v is not None
    if is_range_check and is_exact_version_check:
        raise DSLRuntimeError(
            "Cannot use exact_version and [min_version, max_version] check at the same time"
        )

    if is_range_check:
        if min_v is None and max_v is None:
            raise DSLRuntimeError(
                "min_version and max_version cannot be None at the same time"
            )
        if min_v is not None and max_v is not None:
            if min_v > max_v:
                raise DSLRuntimeError("min_version must be less than max_version")

        result = True
        if min_v is not None:
            result = result and CUDA_VERSION >= min_v
        if max_v is not None:
            result = result and CUDA_VERSION <= max_v
        return result
    elif is_exact_version_check:
        return CUDA_VERSION == exact_v
    else:
        raise DSLRuntimeError(
            "either exact_version, min_version, or max_version must be provided"
        )
