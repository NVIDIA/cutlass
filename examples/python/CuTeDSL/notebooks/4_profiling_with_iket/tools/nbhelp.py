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

"""Display helpers used by the notebooks.

Keeps the notebooks themselves short: they call these rather than carrying
twenty lines of formatting each.
"""

from __future__ import annotations

import difflib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
KERNELS = REPO / "kernels"
FIGURES = REPO / "figures"

# Upstream kernels are not vendored: they resolve to the unmodified examples in this repository.
CUTEDSL = REPO.parents[1]
UPSTREAM = {"fmha.py": CUTEDSL / "cute" / "blackwell" / "kernel" / "attention" / "fmha" / "fmha.py"}


def _read(path: str | Path) -> list[str]:
    p = Path(path)
    if not p.is_absolute():
        p = REPO / p
    if not p.exists():
        raise FileNotFoundError(f"{p} not found (repo root: {REPO})")
    return p.read_text().splitlines()


def show_lines(path: str | Path, start: int, end: int, *, title: str | None = None) -> None:
    """Print a 1-indexed line range with line numbers."""
    lines = _read(path)
    print(title or f"{Path(path).name}  lines {start}-{end}")
    print("-" * 72)
    for i in range(start - 1, min(end, len(lines))):
        print(f"{i + 1:5d}  {lines[i]}")


def show_iket_calls(path: str | Path, *, limit: int | None = None, context: int = 0) -> None:
    """Print every IKET call site in a file, optionally with surrounding context.

    This is how the notebooks show instrumentation without pasting stale copies
    of it into markdown -- the output always reflects the file on disk.
    """
    lines = _read(path)
    hits = [i for i, l in enumerate(lines) if "iket.range_" in l or "iket.mark" in l]
    shown = hits[:limit] if limit else hits

    print(f"{Path(path).name}: {len(hits)} IKET call sites"
          + (f" (showing first {len(shown)})" if limit and len(hits) > limit else ""))
    print("-" * 72)

    prev = None
    for i in shown:
        lo, hi = max(0, i - context), min(len(lines), i + context + 1)
        if prev is not None and lo > prev:
            print("       ...")
        for j in range(max(lo, prev if prev is not None else lo), hi):
            mark = ">" if j == i else " "
            print(f"{mark}{j + 1:5d}  {lines[j]}")
        prev = hi


def show_instrumentation_diff(original: str | Path, instrumented: str | Path,
                              *, limit: int = 60) -> None:
    """Show what instrumenting added -- and assert it added nothing else.

    The claim every notebook makes is that the instrumented kernel differs from
    its origin by instrumentation only. This prints the diff so the reader can
    check that claim rather than take it on trust.
    """
    a, b = _read(original), _read(instrumented)
    diff = list(difflib.unified_diff(a, b, lineterm="",
                                     fromfile=Path(original).name,
                                     tofile=Path(instrumented).name))

    added = [l for l in diff if l.startswith("+") and not l.startswith("+++")]
    removed = [l for l in diff if l.startswith("-") and not l.startswith("---")]
    non_iket = [l for l in added if "iket." not in l and l.strip() != "+"]

    print(f"added {len(added)} lines, removed {len(removed)}")
    if non_iket:
        print(f"NOTE: {len(non_iket)} added line(s) are not IKET calls -- "
              f"this variant changes more than instrumentation.")
    else:
        print("every added line is an IKET call: instrumentation only.")
    print("-" * 72)
    for line in diff[:limit]:
        print(line)
    if len(diff) > limit:
        print(f"... ({len(diff) - limit} more diff lines)")


def figure(relpath: str, caption: str = "", width: str = "100%"):
    """Embed a reference figure with a caption."""
    from IPython.display import HTML, display

    p = FIGURES / relpath
    if not p.exists():
        print(f"[figure missing: {relpath}]")
        return
    rel = f"../figures/{relpath}"
    cap = (f"<figcaption style='font-size:0.85em;color:#555;padding-top:6px'>{caption}</figcaption>"
           if caption else "")
    display(HTML(
        f"<figure style='margin:0'><img src='{rel}' style='width:{width};"
        f"border:1px solid #ddd;border-radius:6px'/>{cap}</figure>"
    ))


def table(rows: list[tuple], headers: tuple) -> None:
    """Print a small aligned table without pulling in pandas."""
    cols = [headers] + [tuple(str(c) for c in r) for r in rows]
    widths = [max(len(row[i]) for row in cols) for i in range(len(headers))]
    print("  ".join(h.ljust(w) for h, w in zip(headers, widths)))
    print("  ".join("-" * w for w in widths))
    for r in cols[1:]:
        print("  ".join(c.ljust(w) for c, w in zip(r, widths)))


def kernel(*parts: str) -> str:
    """Absolute path to a kernel, for use in run-iket commands."""
    if parts[0] == "upstream":
        # Bare "upstream" is the examples root, which provides `helpers` on PYTHONPATH.
        return str(UPSTREAM[parts[1]] if len(parts) > 1 else CUTEDSL)
    return str(KERNELS.joinpath(*parts))
