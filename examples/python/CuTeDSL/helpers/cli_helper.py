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

"""Command-line and configuration-printing helpers for the CuTe DSL examples.

Most examples take the same problem-shape, dtype, layout and benchmark
options, and echo them back in the same format.
This module provides centralize location for common CLI helpers to
add these options to an argparse.ArgumentParser.

The adders are opt-in and take the values that legitimately differ (defaults,
choices) as parameters. An example calls the groups it supports and declares the
rest itself::

    parser = argparse.ArgumentParser(description="Example of Dense GEMM on Blackwell.")
    cli.add_mnkl_arg(parser)
    cli.add_mma_tiler_arg(parser)
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.Float16, c=cutlass.Float16)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser, tolerance=1e-02)
    parser.add_argument("--use_2cta_instrs", action="store_true", ...)  # kernel-specific

The print helpers mirror the same split: the shared header and benchmark block
come from here, anything kernel-specific stays inline between them.
"""

import argparse
from typing import Iterable, Mapping, Optional, Sequence, Tuple, Type

import cutlass
from cutlass.base_dsl.typing import Numeric

#############################################################
# argparse types
#############################################################


def comma_separated_ints(s: str) -> Tuple[int, ...]:
    """argparse ``type`` for tuple options such as ``--mnkl 256,256,512,1``."""
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


def comma_separated_ints_of(count: int):
    """:func:`comma_separated_ints` that also rejects the wrong number of values.

    Use where a wrong-length tuple would otherwise fail deep in the kernel with
    an unhelpful message.
    """

    def parse(s: str) -> Tuple[int, ...]:
        values = comma_separated_ints(s)
        if len(values) != count:
            raise argparse.ArgumentTypeError(
                f"Expected {count} comma-separated integers, got {len(values)}"
            )
        return values

    return parse


#############################################################
# argument groups
#############################################################


def add_mnkl_arg(
    parser: argparse.ArgumentParser,
    *,
    default: Tuple[int, int, int, int] = (256, 256, 512, 1),
    strict_length: bool = False,
) -> None:
    """Add ``--mnkl``. ``strict_length`` rejects anything but 4 values."""
    parser.add_argument(
        "--mnkl",
        type=comma_separated_ints_of(4) if strict_length else comma_separated_ints,
        default=default,
        help="mnkl dimensions (comma-separated)",
    )


def add_mma_tiler_arg(
    parser: argparse.ArgumentParser,
    *,
    default: Tuple[int, int] = (128, 128),
    choices: Optional[Sequence[Tuple[int, int]]] = None,
    strict_length: bool = False,
    help: str = "Mma tile shape (comma-separated)",
) -> None:
    """Add ``--mma_tiler_mn``."""
    parser.add_argument(
        "--mma_tiler_mn",
        type=comma_separated_ints_of(2) if strict_length else comma_separated_ints,
        default=default,
        choices=choices,
        help=help,
    )


def add_cluster_shape_arg(
    parser: argparse.ArgumentParser,
    *,
    default: Tuple[int, int] = (1, 1),
    strict_length: bool = False,
    help: str = "Cluster shape (comma-separated)",
) -> None:
    """Add ``--cluster_shape_mn``."""
    parser.add_argument(
        "--cluster_shape_mn",
        type=comma_separated_ints_of(2) if strict_length else comma_separated_ints,
        default=default,
        help=help,
    )


def add_dtype_args(
    parser: argparse.ArgumentParser,
    *,
    ab: Optional[Type[Numeric]] = None,
    c: Optional[Type[Numeric]] = None,
    acc: Optional[Type[Numeric]] = cutlass.Float32,
    ab_choices: Optional[Sequence[Type[Numeric]]] = None,
    acc_choices: Optional[Sequence[Type[Numeric]]] = None,
) -> None:
    """Add the ``--ab_dtype`` / ``--c_dtype`` / ``--acc_dtype`` trio.

    Pass ``None`` for any of them to leave that flag out -- kernels that take
    separate A and B dtypes declare their own ``--a_dtype``/``--b_dtype``.
    """
    if ab is not None:
        parser.add_argument(
            "--ab_dtype", type=cutlass.dtype, default=ab, choices=ab_choices
        )
    if c is not None:
        parser.add_argument("--c_dtype", type=cutlass.dtype, default=c)
    if acc is not None:
        parser.add_argument(
            "--acc_dtype", type=cutlass.dtype, default=acc, choices=acc_choices
        )


def add_major_args(
    parser: argparse.ArgumentParser,
    *,
    a: Optional[Sequence[str]] = ("k", "m"),
    b: Optional[Sequence[str]] = ("k", "n"),
    c: Optional[Sequence[str]] = ("n", "m"),
) -> None:
    """Add ``--a_major`` / ``--b_major`` / ``--c_major``.

    Each value is the list of layouts the kernel accepts; the first is the
    default. Pass ``None`` to leave that flag out.
    """
    for name, choices in (("a", a), ("b", b), ("c", c)):
        if choices is None:
            continue
        choices = list(choices)
        parser.add_argument(
            f"--{name}_major", choices=choices, type=str, default=choices[0]
        )


def add_benchmark_args(
    parser: argparse.ArgumentParser,
    *,
    tolerance: Optional[float] = 1e-01,
    iterations: int = 1,
    warmup_iterations: int = 0,
) -> None:
    """Add the timing and validation flags every example shares.

    ``--tolerance`` is skipped when ``tolerance`` is ``None``, for kernels whose
    reference check is exact.
    """
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=warmup_iterations,
        help="Warmup iterations",
    )
    parser.add_argument(
        "--iterations", type=int, default=iterations, help="Number of iterations"
    )
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    if tolerance is not None:
        parser.add_argument(
            "--tolerance",
            type=float,
            default=tolerance,
            help="Tolerance for validation",
        )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )


#############################################################
# configuration printing
#############################################################


def print_problem_config(
    title: str,
    mnkl=None,
    *,
    dtypes: Optional[Mapping[str, Type[Numeric]]] = None,
    lines: Iterable[str] = (),
    majors: Optional[Mapping[str, str]] = None,
    mma_tiler_mn=None,
    cluster_shape_mn=None,
) -> None:
    """Print the problem header shared by the examples.

    :param mnkl: omitted when ``None`` -- grouped GEMMs list their per-group
        shapes through ``lines`` instead of one problem size
    :param dtypes: rendered as ``AB dtype: f16, C dtype: f16, Acc dtype: f32``
    :param lines: printed verbatim after ``dtypes``, for kernels whose operand
        set does not fit that one-line form (separate A/B dtypes, scale factors)
    :param majors: rendered as ``Matrix majors - A: k, B: k, C: n``
    """
    print(f"Running {title} test with:")
    if mnkl is not None:
        print(f"mnkl: {mnkl}")
    if dtypes:
        print(", ".join(f"{name} dtype: {dt}" for name, dt in dtypes.items()))
    for line in lines:
        print(line)
    if majors:
        print(
            "Matrix majors - "
            + ", ".join(f"{name}: {major}" for name, major in majors.items())
        )
    if mma_tiler_mn is not None:
        tiler_line = f"Mma Tiler (M, N): {mma_tiler_mn}"
        if cluster_shape_mn is not None:
            tiler_line += f", Cluster Shape (M, N): {cluster_shape_mn}"
        print(tiler_line)


def print_benchmark_config(
    *,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool,
    tolerance: Optional[float] = None,
) -> None:
    """Print the timing/validation block that closes every example's header."""
    if tolerance is not None:
        print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print(f"Use cold L2: {'True' if use_cold_l2 else 'False'}")
