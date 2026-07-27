# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
Launch Completion Events and Programmatic Events Example
=======================================================

This module demonstrates the two CUDA kernel-launch attributes that record a
``cudaEvent_t`` / ``CUevent`` as part of a launch:

1. ``cudaLaunchAttributeLaunchCompletionEvent``
   The event is recorded when all blocks of the grid have begun executing
   (best-effort, used for launch ordering). This attribute is
   usable on **any** compute capability supported by CuTeDSL.

2. ``cudaLaunchAttributeProgrammaticEvent``
   Part of the Programmatic Dependent Launch (PDL) model. The event is recorded
   either:

   * after **every block** in the grid has called
     ``cute.arch.griddepcontrol_launch_dependents()`` (or terminated) - this is
     selected with ``trigger_at_block_start=0``. The kernel must call the trigger
     itself.
   * automatically at each block start - selected with ``trigger_at_block_start=1``.
     The timing is similar to the launch-completion event, but the resulting
     event remains part of the programmatic dependency model and is visible to
     the next kernel's ``cute.arch.griddepcontrol_wait()``.

   ``programmatic_event`` requires sm_90 (Hopper) or newer.

The example demonstrates each attribute by launching a kernel with the attribute
attached, passing the stream as a ``cudaStream_t`` (runtime bindings) and the event
either as a ``cudaEvent_t`` (runtime) or ``CUevent`` (driver). The events
themselves are created from PyTorch with ``torch.cuda.Event(enable_timing=False)``
so they carry ``cudaEventDisableTiming``, which is required by both launch
attributes.

Usage::

    python launch_completion_and_programmatic_events.py
"""

import argparse
from typing import Literal, Tuple, Union

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


# =============================================================================
# Feature gate - queried via torch
# =============================================================================


def supports_programmatic_event() -> bool:
    """``programmatic_event`` is part of the programmatic dependency model and requires Hopper (sm_90+)."""
    return torch.cuda.is_available() and torch.cuda.get_device_capability()[0] >= 9


# =============================================================================
# Kernels
# =============================================================================


@cute.kernel
def simple_kernel(out: cute.Tensor, value: cutlass.Int32):
    """Write ``value`` into each element of ``out``.

    Used to demonstrate ``launch_completion_event``: the event fires
    automatically when all blocks have begun executing.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx < cute.size(out, [0]) and bidx < cute.size(out, [1]):
        out[tidx, bidx] = value


@cute.kernel
def programmatic_trigger_kernel(
    out: cute.Tensor,
    value: cutlass.Int32,
    trigger_at_block_start: cutlass.Constexpr[bool],
):
    """Write ``value`` into each element of ``out``, then trigger the
    programmatic launch-completion signal.

    Used to demonstrate ``programmatic_event``.

    With ``trigger_at_block_start=False``, every block must execute
    ``cute.arch.griddepcontrol_launch_dependents()`` (from the DSL:
    ``cute.arch.griddepcontrol_launch_dependents()``) for the event to fire.
    With ``trigger_at_block_start=True`` the event fires automatically at the
    block start.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    cute.arch.griddepcontrol_wait()

    if cutlass.const_expr(not trigger_at_block_start):
        cute.arch.griddepcontrol_launch_dependents()

    if tidx < cute.size(out, [0]) and bidx < cute.size(out, [1]):
        out[tidx, bidx] = value


# =============================================================================
# JIT host functions - each exercises a single launch attribute
# =============================================================================


THREADS_PER_BLOCK = 128


@cute.jit
def launch_with_launch_completion_event(
    out: cute.Tensor,
    value: cutlass.Int32,
    stream: cuda_runtime.cudaStream_t,
    launch_completion_event: Union[cuda_runtime.cudaEvent_t, cuda_driver.CUevent],
):
    """Launch ``simple_kernel`` with ``launch_completion_event=launch_completion_event``."""
    simple_kernel(out, value).launch(
        grid=(cute.size(out, [1]), 1, 1),
        block=(cute.size(out, [0]), 1, 1),
        stream=stream,
        launch_completion_event=launch_completion_event,
        launch_completion_event_flags=0,  # Optional flags
    )


@cute.jit
def launch_with_programmatic_event(
    out: cute.Tensor,
    value: cutlass.Int32,
    stream: cuda_runtime.cudaStream_t,
    programmatic_event: Union[cuda_runtime.cudaEvent_t, cuda_driver.CUevent],
    trigger_at_block_start: cutlass.Constexpr[int] = 0,
):
    """Launch ``programmatic_trigger_kernel`` with ``programmatic_event=programmatic_event``."""
    programmatic_trigger_kernel(out, value, trigger_at_block_start == 1).launch(
        grid=(cute.size(out, [1]), 1, 1),
        block=(cute.size(out, [0]), 1, 1),
        stream=stream,
        programmatic_event=programmatic_event,
        programmatic_event_flags=0,  # Optional flags
        programmatic_event_trigger_at_block_start=trigger_at_block_start,  # Defaults to zero
        use_pdl=True,
    )


# =============================================================================
# Helpers for event creation and synchronization
# =============================================================================


def _make_event(
    kind: Literal["runtime", "driver"], init_stream: torch.cuda.Stream
) -> Tuple[torch.cuda.Event, Union[cuda_runtime.cudaEvent_t, cuda_driver.CUevent]]:
    """Create a CUDA event from torch with timing disabled and wrap it as the
    requested low-level API type.

    Using ``torch.cuda.Event(enable_timing=False)`` guarantees the underlying
    CUDA event is created with ``cudaEventDisableTiming``, which is required
    for ``launch_completion_event`` and ``programmatic_event`` launch attributes.

    PyTorch lazily initializes the underlying ``cudaEvent_t`` on the first
    ``record()`` call. We force initialization by recording the event.

    Returns ``(torch_event, cuda_event)``. The torch event
    must be kept alive for the lifetime of the wrapped cuda event. Torch will
    destroy the event when ``torch_event`` is garbage-collected.
    """
    torch_event = torch.cuda.Event(enable_timing=False)
    torch_event.record(init_stream)
    raw_event = int(torch_event.cuda_event)
    if raw_event == 0:
        raise RuntimeError("torch.cuda.Event was not created")
    if kind == "runtime":
        return torch_event, cuda_runtime.cudaEvent_t(raw_event)
    elif kind == "driver":
        return torch_event, cuda_driver.CUevent(raw_event)
    else:
        raise ValueError(
            f"Unknown event kind: {kind!r}; expected 'runtime' or 'driver'"
        )


# =============================================================================
# Run functions
# =============================================================================


def run_launch_completion_event_example(
    n_elements_per_block: int = 128,
    n_blocks: int = 48,
    launch_completion_event_kind: Literal["runtime", "driver"] = "runtime",
) -> None:
    """Run the ``launch_completion_event`` demonstration.

    Allocates an output tensor, launches ``simple_kernel`` with
    ``launch_completion_event`` attached, then blocks on the event using the
    matching API and verifies the output.
    """
    print(
        f"\n[Launch Completion Event] Running launch_completion_event example "
        f"(launch_completion_event_kind={launch_completion_event_kind!r}, "
        f"n_elements_per_block={n_elements_per_block}, n_blocks={n_blocks})"
    )

    out = torch.full(
        (n_elements_per_block, n_blocks), -1, dtype=torch.int32, device="cuda"
    )
    expected = torch.full(
        (n_elements_per_block, n_blocks), 0, dtype=torch.int32, device="cuda"
    )

    torch_stream = torch.cuda.default_stream()
    stream = cuda_runtime.cudaStream_t(torch_stream.cuda_stream)

    torch_event, launch_completion_event = _make_event(
        launch_completion_event_kind, torch_stream
    )

    out_tensor = from_dlpack(out)

    launch_with_launch_completion_event(out_tensor, 0, stream, launch_completion_event)

    torch_event.synchronize()

    torch.testing.assert_close(out, expected)
    print(
        f"[Launch Completion Event] {launch_completion_event_kind} event fired and output verified."
    )


def run_programmatic_event_example(
    n_elements_per_block: int = 128,
    n_blocks: int = 48,
    programmatic_event_kind: Literal["runtime", "driver"] = "runtime",
    trigger_at_block_start: int = 0,
) -> None:
    """Run the ``programmatic_event`` demonstration.

    Allocates an output tensor, launches ``programmatic_trigger_kernel`` with
    ``programmatic_event`` attached, then blocks on the event using the matching
    API and verifies the output.
    """
    if not supports_programmatic_event():
        raise RuntimeError("programmatic_event requires Hopper (sm_90) or newer")

    print(
        f"\n[Programmatic Event]  Running programmatic_event example "
        f"(programmatic_event_kind={programmatic_event_kind!r}, "
        f"n_elements_per_block={n_elements_per_block}, n_blocks={n_blocks}, "
        f"trigger_at_block_start={trigger_at_block_start})"
    )

    out = torch.full(
        (n_elements_per_block, n_blocks), -1, dtype=torch.int32, device="cuda"
    )
    expected = torch.full(
        (n_elements_per_block, n_blocks), 1, dtype=torch.int32, device="cuda"
    )

    torch_stream = torch.cuda.default_stream()
    stream = cuda_runtime.cudaStream_t(torch_stream.cuda_stream)

    out_tensor = from_dlpack(out)

    graph = torch.cuda.CUDAGraph()

    torch_event = None

    with torch.cuda.graph(graph):
        stream = cuda_runtime.cudaStream_t(torch.cuda.current_stream().cuda_stream)
        torch_event, programmatic_event = _make_event(
            programmatic_event_kind, torch_stream
        )
        launch_with_programmatic_event(
            out_tensor,
            0,
            stream,
            programmatic_event,
            trigger_at_block_start=trigger_at_block_start,
        )

        # Overlaps with the prior launch after every CTA has been launched
        launch_with_programmatic_event(
            out_tensor,
            1,
            stream,
            programmatic_event,
            trigger_at_block_start=trigger_at_block_start,
        )

    graph.replay()
    assert torch_event is not None, "torch.cuda.Event was not created"
    torch.cuda.synchronize()

    torch.testing.assert_close(out, expected)
    print(
        f"[Programmatic Event]  {programmatic_event_kind} event fired and output verified."
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=(
            "Demonstrate launch_completion_event and programmatic_event launch "
            "attributes with both cudaEvent_t and CUevent."
        )
    )
    parser.add_argument("--n-blocks", default=48, type=int)
    parser.add_argument("--n-elements-per-block", default=128, type=int)
    parser.add_argument("--use-driver-api", action="store_true")
    parser.add_argument("--trigger-at-block-start", action="store_true")
    args = parser.parse_args()

    run_launch_completion_event_example(
        n_elements_per_block=args.n_elements_per_block,
        n_blocks=args.n_blocks,
        launch_completion_event_kind="driver" if args.use_driver_api else "runtime",
    )

    if supports_programmatic_event():
        run_programmatic_event_example(
            n_elements_per_block=args.n_elements_per_block,
            n_blocks=args.n_blocks,
            programmatic_event_kind="driver" if args.use_driver_api else "runtime",
            trigger_at_block_start=1 if args.trigger_at_block_start else 0,
        )
    else:
        print("\nSkipping programmatic_event: requires Hopper (sm_90) or newer.")

    print("\nPASS")
