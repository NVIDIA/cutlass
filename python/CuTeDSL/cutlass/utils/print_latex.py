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

import functools
import warnings
from typing import Any

from typing_extensions import deprecated

from cutlass.cute.viz import print_latex as _print_latex
from cutlass.cute.viz import print_latex_tv as _print_latex_tv
from cutlass.cute.viz import tikz_color_bwx8 as _tikz_color_bwx8
from cutlass.cute.viz import tikz_color_rainbow as _tikz_color_rainbow
from cutlass.cute.viz import tikz_color_tv as _tikz_color_tv
from cutlass.cute.viz import tikz_color_white as _tikz_color_white
from cutlass.cute.viz import tikz_escape as _tikz_escape


@deprecated(
    "cutlass.utils.print_latex.print_latex is deprecated; use "
    "cutlass.cute.viz.print_latex instead. It will be removed in a future release."
)
@functools.wraps(_print_latex)
def print_latex(*args: Any, **kwargs: Any) -> Any:
    return _print_latex(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.print_latex_tv is deprecated; use "
    "cutlass.cute.viz.print_latex_tv instead. It will be removed in a future "
    "release."
)
@functools.wraps(_print_latex_tv)
def print_latex_tv(*args: Any, **kwargs: Any) -> Any:
    return _print_latex_tv(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.tikz_color_bwx8 is deprecated; use "
    "cutlass.cute.viz.tikz_color_bwx8 instead. It will be removed in a future "
    "release."
)
@functools.wraps(_tikz_color_bwx8)
def tikz_color_bwx8(*args: Any, **kwargs: Any) -> Any:
    return _tikz_color_bwx8(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.tikz_color_rainbow is deprecated; use "
    "cutlass.cute.viz.tikz_color_rainbow instead. It will be removed in a future "
    "release."
)
@functools.wraps(_tikz_color_rainbow)
def tikz_color_rainbow(*args: Any, **kwargs: Any) -> Any:
    return _tikz_color_rainbow(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.tikz_color_tv is deprecated; use "
    "cutlass.cute.viz.tikz_color_tv instead. It will be removed in a future release."
)
@functools.wraps(_tikz_color_tv)
def tikz_color_tv(*args: Any, **kwargs: Any) -> Any:
    return _tikz_color_tv(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.tikz_color_white is deprecated; use "
    "cutlass.cute.viz.tikz_color_white instead. It will be removed in a future "
    "release."
)
@functools.wraps(_tikz_color_white)
def tikz_color_white(*args: Any, **kwargs: Any) -> Any:
    return _tikz_color_white(*args, **kwargs)


@deprecated(
    "cutlass.utils.print_latex.tikz_escape is deprecated; use "
    "cutlass.cute.viz.tikz_escape instead. It will be removed in a future release."
)
@functools.wraps(_tikz_escape)
def tikz_escape(*args: Any, **kwargs: Any) -> Any:
    return _tikz_escape(*args, **kwargs)


# PALETTES and Band are data objects shared with the canonical module, so the
# canonical objects themselves must be handed out rather than copies. A
# module-level __getattr__ (PEP 562) adds the deprecation warning instead.
def __getattr__(name: str) -> Any:
    if name in ("PALETTES", "Band"):
        warnings.warn(
            f"cutlass.utils.print_latex.{name} is deprecated; use "
            f"cutlass.cute.viz.{name} instead. It will be removed in a future "
            "release.",
            DeprecationWarning,
            stacklevel=2,
        )
        import cutlass.cute.viz as _viz

        return getattr(_viz, name)
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "PALETTES",  # noqa: F822  # provided by module __getattr__
    "Band",  # noqa: F822  # provided by module __getattr__
    "print_latex",
    "print_latex_tv",
    "tikz_color_bwx8",
    "tikz_color_rainbow",
    "tikz_color_tv",
    "tikz_color_white",
    "tikz_escape",
]
