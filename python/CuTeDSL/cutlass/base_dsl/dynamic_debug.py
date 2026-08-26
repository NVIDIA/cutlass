# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Global state and helpers for controlling dynamic loop debug output.

This is process-global tracing infrastructure independent of ``BaseDSL``; it is
factored out of ``dsl.py`` so the core DSL class stays focused on JIT
orchestration.
"""

from .._mlir import ir


# =============================================================================
# Dynamic Debug Control
# =============================================================================


class _DynamicDebugState:
    """
    Global state for controlling dynamic loop debug output.
    """

    def __init__(self) -> None:
        self.enabled = False
        self.max_depth: int | None = None
        self.current_depth = 0

    def should_print(self) -> bool:
        if not self.enabled:
            return False
        if self.max_depth is None:
            return True
        return self.current_depth <= self.max_depth

    def enter_level(self) -> None:
        self.current_depth += 1

    def exit_level(self) -> None:
        self.current_depth = max(0, self.current_depth - 1)

    def reset_depth(self) -> None:
        self.current_depth = 0


_dynamic_debug = _DynamicDebugState()


def set_dynamic_debug(enabled: bool, max_depth: int | None = None) -> None:
    """
    Enable or disable dynamic loop debug output.

    Args:
        enabled: Whether to enable debug output
        max_depth: Maximum nesting depth to print. None means unlimited.
    """
    _dynamic_debug.enabled = enabled
    _dynamic_debug.max_depth = max_depth
    _dynamic_debug.current_depth = 0


def get_dynamic_debug() -> tuple[bool, int | None, int]:
    """
    Get the current dynamic debug state.

    Returns:
        Tuple of (enabled, max_depth, current_depth)
    """
    return (
        _dynamic_debug.enabled,
        _dynamic_debug.max_depth,
        _dynamic_debug.current_depth,
    )


def should_print_dynamic_debug() -> bool:
    """
    Check if dynamic debug output should be printed at the current level.

    Returns:
        True if debug output is enabled and within max_depth limit.
    """
    return _dynamic_debug.should_print()


def get_dynamic_debug_level() -> int:
    """
    Get the current dynamic debug nesting level.

    Returns:
        Current nesting depth.
    """
    return _dynamic_debug.current_depth


class dynamic_debug_level:
    """
    Context manager for tracking nesting depth in dynamic debug output.

    Usage:
        with dynamic_debug_level():
            # Code at increased nesting level
            if should_print_dynamic_debug():
                print(f"Level {get_dynamic_debug_level()}: ...")
    """

    def __enter__(self) -> None:
        _dynamic_debug.enter_level()

    def __exit__(self, *args: object) -> None:
        _dynamic_debug.exit_level()


def reset_dynamic_debug_depth() -> None:
    """Reset the dynamic debug depth counter to 0."""
    _dynamic_debug.reset_depth()


def debug_print_mlir_values(
    obj: object, indent: int = 0, name: str | None = None, types_only: bool = False
) -> str:
    """
    Print a structured tree of MLIR values for debugging.

    Args:
        obj: The object to print
        indent: Current indentation level
        name: Optional name to display for this node
        types_only: If True, show MLIR types instead of full values

    Returns:
        str: A formatted string representation of the MLIR values tree
    """
    lines = []
    prefix = "  " * indent

    if name:
        type_name = name
    elif hasattr(obj, "__class__"):
        type_name = obj.__class__.__name__
    else:
        type_name = str(type(obj).__name__)

    if obj is None:
        lines.append(f"{prefix}{type_name}: (none)")
    elif isinstance(obj, ir.Value):
        if types_only:
            lines.append(f"{prefix}{type_name}: {obj.type}")
        else:
            lines.append(f"{prefix}{type_name}: {obj} : {obj.type}")
    elif hasattr(obj, "__extract_mlir_values__"):
        values = obj.__extract_mlir_values__()
        lines.append(f"{prefix}{type_name}:")
        if isinstance(values, dict):
            for key, val in values.items():
                if val is None:
                    lines.append(f"{prefix}  {key}: (static/none)")
                elif isinstance(val, ir.Value):
                    if types_only:
                        lines.append(f"{prefix}  {key}: {val.type}")
                    else:
                        lines.append(f"{prefix}  {key}: {val} : {val.type}")
                elif isinstance(val, (dict, list)):
                    lines.append(
                        f"{prefix}  {key}: {type(val).__name__} with {len(val)} items"
                    )
                else:
                    lines.append(f"{prefix}  {key}: {val}")
        elif isinstance(values, ir.Value):
            if types_only:
                lines.append(f"{prefix}  value: {values.type}")
            else:
                lines.append(f"{prefix}  value: {values} : {values.type}")
        elif isinstance(values, list):
            lines.append(f"{prefix}  [{len(values)} values]")
        else:
            lines.append(f"{prefix}  {values}")
    elif isinstance(obj, dict):
        lines.append(f"{prefix}{type_name}: dict with {len(obj)} items")
    elif isinstance(obj, (list, tuple)):
        lines.append(f"{prefix}{type_name}: [{len(obj)} items]")
    else:
        lines.append(f"{prefix}{type_name}: {obj}")

    return "\n".join(filter(None, lines))
