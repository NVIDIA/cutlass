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

This module has no dependencies on any other ``cutlass.operators.providers.cutedsl.evt.efc`` sibling --
it is the bottom of the EFC import graph by design.  Keep it that way:
do not add an ``import ._<sibling>`` here.
"""

from __future__ import annotations

import functools
import inspect
import logging
import os

import cutlass
from cutlass.cute.core import ScaledBasis

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


def check_accum_split_fragment(fragment, num_parts: int):
    """Check that ``fragment`` admits a ``num_parts``-way interleaved split.

    ``Configuration.accum_split`` re-views the per-thread accumulator run
    as ``(num_parts, n // num_parts)`` with stride ``(1, num_parts)``, which needs a gap-free run
    whose length is a multiple of ``num_parts``.  A padded or swizzled fragment
    would make the view address elements that are not the neighbours the
    interleaving means, and a short run would drop elements.

    :param fragment: The retiled accumulator register fragment.
    :param num_parts: Number of interleaved parts.
    :type num_parts: int
    :return: The fragment's element count.
    :rtype: int
    :raises ValueError: If the fragment cannot be split ``num_parts`` ways.
    """
    layout = fragment.layout
    n = cutlass.cute.size(layout)
    # ``Configuration._accum_split_fragment`` re-views the fragment by linear
    # address, so the run must be contiguous *and* in address order: a compact
    # layout that is not, such as (2,4):(4,1), would make the stride-num_parts
    # view select elements that are not N-neighbours.  Coalescing a run that
    # qualifies leaves exactly ``n:1``.
    flat = cutlass.cute.coalesce(layout)
    if cutlass.cute.size(flat) != n or flat.stride != 1:
        raise ValueError(
            f"accum_split({num_parts}) needs a contiguous accumulator fragment, "
            f"got layout {layout} (coalesces to {flat})."
        )
    if n % num_parts != 0:
        raise ValueError(
            f"accum_split({num_parts}) needs the per-thread accumulator run "
            f"({n} elements) to be a multiple of {num_parts}."
        )
    return n


def _is_power_of_two(n: int) -> bool:
    return n > 0 and n & (n - 1) == 0


def accum_split_across_lanes(
    fragment, coordinate_fragment, num_parts: int, tiled_copy_t2r, epi_tile
) -> bool:
    """Decide where the columns an ``accum_split`` pairs are held.

    ``accum_split(num_parts)`` cuts every accumulator row into runs,
    ``num_parts`` consecutive columns starting at a multiple of
    ``num_parts``, and combines the columns of each run: part ``i`` is
    column ``i`` of every run, so the output has one column per run.  The
    epilogue body runs on register fragments, and which columns a thread
    holds is fixed by the TMEM-to-register copy's thread-value layout,
    which follows the MMA tiler.  Some tilers give each thread a run of
    consecutive columns of one row, so the pairing is a re-view of its
    own registers; others spread a row's consecutive columns over
    neighbouring lanes, so the columns to pair sit in other lanes'
    registers.  The kernel has to know which case holds and, in the
    second, how to find the lane holding a given part:
    ``Configuration._accum_split_exchange`` relies on ``lane % num_parts``
    being a thread's own part and ``lane - lane % num_parts + part`` the
    lane holding ``part`` at the same fragment slots.  This function
    establishes both once per kernel, at trace time, from the layouts
    alone.

    Both placements re-view the register fragment by linear address, so
    it is checked first (``check_accum_split_fragment``): a compact run in
    address order whose length is a multiple of ``num_parts``.

    * **In thread** (returns False): the fragment itself runs along whole
      runs of ``num_parts`` consecutive columns of one row, so the split
      is a register re-view.

    * **Across lanes** (returns True): each thread holds a single part,
      and each run of lanes, the ``num_parts`` lanes sharing
      ``lane // num_parts``, holds one run of columns in lane order, so a
      part's lane follows from integer arithmetic on the lane index.

    :param fragment: The retiled accumulator register fragment
        (``tTR_rAcc``).
    :param coordinate_fragment: The retiled accumulator coordinate
        fragment (``tTR_cAcc``), holding ``(m, n)`` coordinates.
    :param num_parts: Number of interleaved parts.
    :type num_parts: int
    :param tiled_copy_t2r: The TMEM-to-register tiled copy whose
        thread-value layout assigns accumulator columns to threads.
    :param epi_tile: The epilogue tile that copy partitions; its shape
        sizes the identity tensor the probes partition.
    :return: True when the parts are gathered from other lanes, False
        when a thread pairs them in its own registers.
    :rtype: bool
    :raises ValueError: When the fragment cannot be split, when neither
        placement pairs the columns, or when the copy's thread count is
        not a power of two.
    """
    check_accum_split_fragment(fragment, num_parts)

    layout = coordinate_fragment.layout
    sizes = cutlass.cute.flatten(layout.shape)
    steps = cutlass.cute.flatten(layout.stride)
    modes = [(size, step) for size, step in zip(sizes, steps) if size != 1]

    def n_step(step):
        # On the coordinate fragment a stride is a ``ScaledBasis``: its
        # ``mode`` names the epilogue-tile axis it steps along, 0 for M and
        # 1 for N, and its ``value`` is the step.  Only N tells the parts
        # apart.
        if isinstance(step, ScaledBasis) and list(step.mode) == [1]:
            return step.value
        return 0

    # In thread: the innermost mode of extent above 1 steps along N by 1
    # with a size a multiple of ``num_parts``, and every other N step is a
    # multiple of ``num_parts`` so each run starts at part 0.
    innermost_size, innermost_step = modes[0] if modes else (1, 0)
    outer_steps_whole = all(n_step(step) % num_parts == 0 for _, step in modes[1:])
    if (
        n_step(innermost_step) == 1
        and innermost_size % num_parts == 0
        and outer_steps_whole
    ):
        return False

    # Across lanes, first fact: every N step of the fragment is a multiple
    # of ``num_parts``, so a thread holds a single part.
    single_part = all(n_step(step) % num_parts == 0 for _, step in modes)

    # Second fact: the lanes of each aligned run hold the parts in order,
    # a property of the copy's thread-to-coordinate map.  Probing the
    # threads 1, 2, 4, ... reads the whole map: a CuTe layout is linear in
    # the digits of its coordinate, and with power-of-two extents every
    # binary digit of the thread index is a digit of its own, so the
    # coordinate of any thread is ``coord(0)`` plus the deltas of the
    # powers of two in its binary expansion.
    num_threads = tiled_copy_t2r.size
    if not _is_power_of_two(num_threads):
        raise ValueError(
            f"accum_split({num_parts}) expects a power-of-two thread count in "
            f"the TMEM-to-register copy, got {num_threads}."
        )
    identity = cutlass.cute.make_identity_tensor(
        cutlass.cute.product_each(cutlass.cute.shape(epi_tile))
    )

    # Each probe reads the (m, n) of the thread's first fragment element, a
    # static tuple.  Thread 0's is the tile origin, so it is also the
    # thread's coordinate delta from thread 0.  The probed threads below
    # ``num_parts`` are lanes of thread 0's run: thread ``t`` must sit on
    # the same row, ``t`` columns to the right, so the ``num_parts`` lanes
    # sharing ``lane // num_parts`` hold consecutive columns in lane order.
    # Every other probed thread must leave the part alone: its N delta is
    # a multiple of ``num_parts``.  Tile offsets are multiples of the tile
    # N and cannot change the part either.  ``num_parts`` must be a power
    # of two for a run of lanes to be aligned, and a run must fit in a
    # warp since the exchange shuffles by lane index.
    lanes_in_order = (
        _is_power_of_two(num_parts) and num_parts <= cutlass.cute.arch.WARP_SIZE
    )
    thread_deltas = []
    thread = 1
    while thread < num_threads:
        delta = tiled_copy_t2r.get_slice(thread).partition_D(identity)[0]
        thread_deltas.append(delta)
        if thread < num_parts:
            lanes_in_order = lanes_in_order and delta == (0, thread)
        else:
            lanes_in_order = lanes_in_order and delta[1] % num_parts == 0
        thread *= 2
    if single_part and lanes_in_order:
        return True
    raise ValueError(
        f"accum_split({num_parts}) cannot pair the columns: the fragment "
        f"does not run along adjacent N columns in groups of {num_parts}, "
        f"and the lanes do not hold the parts in order -- the columns to "
        f"pair are in other threads' registers.  Coordinate fragment: "
        f"{layout}; (m, n) deltas of threads 1, 2, 4, ...: {thread_deltas}."
    )


def extend_split_n(tensor, num_parts: int):
    """Full-width interleaved view of a tensor narrowed by ``accum_split``.

    A tensor written from ``accum_split(num_parts)`` parts has ``1 /
    num_parts`` of the output's N.  This re-views it at the output's full
    width by extending the N mode with a stride-0 sub-mode, fastest first::

        narrowed (M, NN, L)              : (sm, sn, sl)
        extended (M, (num_parts, NN), L) : (sm, (0, sn), sl)

    Accumulator column ``n`` then addresses the narrowed tensor's column
    ``n // num_parts`` -- the ``accum_split`` correspondence -- so the
    accumulator's own tilers and partitions apply to ``ye`` unchanged,
    and slicing the sub-mode at 0 recovers the real columns wherever an
    interface needs the narrow layout (a TMA descriptor cannot encode a
    stride-0 mode).

    :param tensor: The narrowed tensor, in kernel ``(M, N, L)`` order.
    :param num_parts: The ``accum_split`` factor it was written from.
    :type num_parts: int
    :return: The extended view, sharing ``tensor``'s memory.
    """
    m, nn, l = tensor.layout.shape
    sm, sn, sl = tensor.layout.stride
    return cutlass.cute.make_tensor(
        tensor.iterator,
        cutlass.cute.make_layout(
            (m, (num_parts, nn), l),
            stride=(sm, (0, sn), sl),
        ),
    )


def narrow_epi_tile_n(epi_tile, num_parts: int):
    """Narrow an epilogue tile's N mode by ``num_parts``.

    A tensor written from ``accum_split`` parts is ``num_parts`` times
    narrower along N than the accumulator, because accumulator column
    ``c`` contributes to output column ``c // num_parts``.  Every extent
    and stride along N therefore scales by ``1 / num_parts``::

        32:1            ->  16:1          (1 CTA)
        (16,2):(1,128)  ->  (8,2):(1,64)  (2 CTA, hierarchical N)

    The M mode is untouched.

    :param epi_tile: The accumulator's epilogue tiler.
    :param num_parts: Split factor to narrow by.
    :type num_parts: int
    :return: The tiler for a tensor written from the split parts.
    :raises ValueError: If the N mode cannot be scaled exactly.
    """
    tile_m, tile_n = epi_tile[0], epi_tile[1]
    shape = tile_n.shape
    stride = tile_n.stride

    innermost_stride = stride[0] if isinstance(stride, tuple) else stride
    innermost_extent = shape[0] if isinstance(shape, tuple) else shape
    if innermost_stride != 1:
        raise ValueError(
            f"Cannot narrow epilogue tile N ({tile_n}) by {num_parts}: "
            f"the innermost N stride is {innermost_stride}, expected 1."
        )
    if innermost_extent % num_parts != 0:
        raise ValueError(
            f"Cannot narrow epilogue tile N ({tile_n}) by {num_parts}: "
            f"innermost extent {innermost_extent} is not a multiple of "
            f"{num_parts}."
        )
    # The scaling is exactly a dtype recast: viewing ``num_parts`` unit-
    # stride elements as one wider element divides every extent and stride
    # along the mode by ``num_parts``, hierarchical modes included.
    return (tile_m, cutlass.cute.recast_layout(num_parts, 1, tile_n))


class SplitPart:
    """A ParameterAnalysis dummy carrying its ``accum_split`` provenance.

    That phase evaluates the epilogue over dummy values to discover
    structure -- which tensors are read, which are written.  Propagating
    the split factor through arithmetic extends that to a third fact:
    which tensors receive accumulator parts, and so tile narrower along N
    than the accumulator.  ``Tensor.store`` reads it off the stored value.

    Only the arithmetic an epilogue body performs is defined; the value
    itself is meaningless, as it is for every other dummy in this phase.
    """

    __slots__ = ("num_parts",)

    def __init__(self, num_parts: int):
        self.num_parts = num_parts

    def __repr__(self) -> str:
        return f"SplitPart({self.num_parts})"

    def combined_with(self, other) -> "SplitPart":
        """Propagate this mark across a binary operation.

        :raises ValueError: If ``other`` carries a different split factor,
            which would leave the result's width ambiguous.
        """
        if isinstance(other, SplitPart) and other.num_parts != self.num_parts:
            raise ValueError(
                f"Cannot combine accum_split({self.num_parts}) and "
                f"accum_split({other.num_parts}) parts in one expression."
            )
        return SplitPart(self.num_parts)


def _install_split_part_operators():
    """Give ``SplitPart`` the operators an epilogue body applies to a part."""
    for name in ("add", "sub", "mul", "truediv", "floordiv", "mod", "pow"):
        setattr(SplitPart, f"__{name}__", SplitPart.combined_with)
        setattr(SplitPart, f"__r{name}__", SplitPart.combined_with)
    for name in ("neg", "pos", "abs"):
        setattr(SplitPart, f"__{name}__", lambda self: SplitPart(self.num_parts))


_install_split_part_operators()


def split_factor_of(value):
    """The ``accum_split`` factor ``value`` was derived from, or None."""
    return value.num_parts if isinstance(value, SplitPart) else None


def analysis_result_of(*values):
    """The ParameterAnalysis dummy an elementwise operation returns.

    An elementwise operation maps each element in place, so a value built
    from ``accum_split`` parts is itself that many times narrower along N
    -- the mark has to survive the operation for ``Tensor.store`` to see
    it.  Marks with different factors reject, exactly as arithmetic
    between two parts does.

    :param values: The operation's operands, marked or not.
    :return: A ``SplitPart`` when any operand carries one, else ``1``.
    :raises ValueError: If two operands carry different split factors.
    """
    marks = [value for value in values if isinstance(value, SplitPart)]
    if not marks:
        return 1
    result = marks[0]
    for mark in marks[1:]:
        result = result.combined_with(mark)
    return result
