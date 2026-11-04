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

"""Per-range statistics from an IKET postprocessed JSON trace.

Written against the trace schema documented in the CUTLASS IKET profiling guide
(``media/docs/pythonDSL/guides/iket_profiling.rst``, "JSON Trace Shape"). That
guide states the JSON schema is experimental and may change between releases, so
this module validates the fields it depends on and fails with a clear message
rather than silently producing wrong numbers.

Timestamps in IKET traces are nanoseconds, not clock cycles.
"""

from __future__ import annotations

import json
import statistics
from dataclasses import dataclass
from pathlib import Path

NS_PER_US = 1000.0


class TraceSchemaError(RuntimeError):
    """The trace JSON does not have the shape this module expects."""


@dataclass
class RangeStats:
    name: str
    count: int
    median_ns: float
    mean_ns: float
    p90_ns: float
    total_ns: int

    @property
    def median_us(self) -> float:
        return self.median_ns / NS_PER_US

    @property
    def total_us(self) -> float:
        return self.total_ns / NS_PER_US


@dataclass
class LaunchSummary:
    kernel_name: str
    grid: tuple[int, int, int]
    block: tuple[int, int, int]
    warp_count: int
    span_ns: int | None
    ranges: list[RangeStats]

    @property
    def span_us(self) -> float | None:
        return None if self.span_ns is None else self.span_ns / NS_PER_US


def load(path: str | Path) -> dict:
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(
            f"{path} not found. Run the run-iket cell first, or point at a trace you already have."
        )
    with path.open() as fh:
        trace = json.load(fh)

    for key in ("stringTable", "launches"):
        if key not in trace:
            raise TraceSchemaError(
                f"'{key}' missing from {path.name}. The IKET JSON schema is experimental and may "
                f"have changed in your wheel; check the IKET profiling guide for the current shape."
            )
    return trace


def find_trace(output_dir: str | Path) -> Path:
    """Locate the postprocessed ``*.trace.json`` inside a run-iket output directory."""
    output_dir = Path(output_dir)
    hits = sorted(output_dir.glob("iket_pid_*.trace.json")) or sorted(output_dir.glob("*.trace.json"))
    if not hits:
        raise FileNotFoundError(
            f"No *.trace.json under {output_dir}. If run-iket succeeded but wrote no events, the "
            f"trace buffer most likely overflowed -- see notebook 11 on reducing instrumentation "
            f"density or using --enabled-cluster."
        )
    if len(hits) > 1:
        # More than one profiled process; the caller should disambiguate.
        raise ValueError(f"Multiple traces in {output_dir}: {[h.name for h in hits]}")
    return hits[0]


def all_launches(trace: dict) -> list[dict]:
    """Every profiled launch, including CUDA-graph-launched kernels.

    A graph-launched kernel (gemm 6 / PDL, for example) contributes nothing to
    ``launches`` -- its events live under ``graphLaunches``, keyed by graph exec.
    Reading only ``launches`` makes such a trace look empty.
    """
    launches = list(trace.get("launches", []))
    for entries in trace.get("graphLaunches", {}).values():
        launches.extend(entries)
    return launches


def summarize(trace: dict, *, launch_index: int = 0) -> LaunchSummary:
    """Aggregate per-range durations for one launch."""
    launches = all_launches(trace)
    if not launches:
        raise TraceSchemaError(
            "The trace contains no launches. The kernel may not have been instrumented, or IKET "
            "was stripped at compile time (run-iket sets CUTE_DSL_COMPILER_OPT=iket itself)."
        )
    launch = launches[launch_index]
    strings = trace["stringTable"]

    by_name: dict[str, list[int]] = {}
    for rng in launch.get("ranges", []):
        try:
            name = strings[rng["rangeNameIdx"]]
            duration = rng["endTs"] - rng["startTs"]
        except (KeyError, IndexError) as exc:
            raise TraceSchemaError(f"Unexpected range entry {rng!r}") from exc
        by_name.setdefault(name, []).append(duration)

    stats = [
        RangeStats(
            name=name,
            count=len(durs),
            median_ns=statistics.median(durs),
            mean_ns=statistics.fmean(durs),
            p90_ns=sorted(durs)[int(0.9 * (len(durs) - 1))],
            total_ns=sum(durs),
        )
        for name, durs in by_name.items()
    ]
    stats.sort(key=lambda s: s.total_ns, reverse=True)

    lifetimes = launch.get("warpLifetimes", [])
    span = None
    if lifetimes:
        span = max(w["endTs"] for w in lifetimes) - min(w["startTs"] for w in lifetimes)

    return LaunchSummary(
        kernel_name=launch.get("kernelName", "<unknown>"),
        grid=(launch.get("gridDimX", 0), launch.get("gridDimY", 0), launch.get("gridDimZ", 0)),
        block=(launch.get("blockDimX", 0), launch.get("blockDimY", 0), launch.get("blockDimZ", 0)),
        warp_count=len({w["locIdx"] for w in lifetimes}) if lifetimes else 0,
        span_ns=span,
        ranges=stats,
    )


def print_summary(summary: LaunchSummary, *, top: int | None = None) -> None:
    grid = "x".join(str(d) for d in summary.grid)
    block = "x".join(str(d) for d in summary.block)
    print(f"{summary.kernel_name}   grid {grid}  block {block}  warps traced {summary.warp_count}")
    if summary.span_us is not None:
        print(f"warp-lifetime span: {summary.span_us:.1f} us")
    print()
    print(f"{'range':<24}{'count':>8}{'median':>12}{'p90':>12}{'total':>12}")
    print("-" * 68)
    for rs in summary.ranges[:top]:
        print(f"{rs.name:<24}{rs.count:>8}{rs.median_us:>11.3f}u"
              f"{rs.p90_ns / NS_PER_US:>11.3f}u{rs.total_us:>11.2f}u")


def compare(a: LaunchSummary, b: LaunchSummary, *, label_a: str, label_b: str) -> None:
    """Side-by-side median durations for ranges present in both traces.

    Variant A/B comparison is the core move of this series -- a single trace tells
    you far less than two traces that differ in one design decision.
    """
    ma = {r.name: r.median_us for r in a.ranges}
    mb = {r.name: r.median_us for r in b.ranges}
    shared = [n for n in ma if n in mb]
    shared.sort(key=lambda n: abs(mb[n] - ma[n]), reverse=True)

    print(f"{'range':<24}{label_a:>12}{label_b:>12}{'delta':>12}")
    print("-" * 60)
    for name in shared:
        delta = mb[name] - ma[name]
        print(f"{name:<24}{ma[name]:>11.3f}u{mb[name]:>11.3f}u{delta:>+11.3f}u")

    only_a = sorted(set(ma) - set(mb))
    only_b = sorted(set(mb) - set(ma))
    if only_a:
        print(f"\nonly in {label_a}: {', '.join(only_a)}")
    if only_b:
        print(f"only in {label_b}: {', '.join(only_b)}")
