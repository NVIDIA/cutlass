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

import colorsys
from types import MappingProxyType
from typing import Callable, List, NamedTuple, Optional, Union

from ..cute import (
    Layout,
    ComposedLayout,
    append,
    is_static,
    make_layout,
    size,
    product_each,
    rank,
)
from ..cute.typing import IntTuple

__all__ = [
    "print_latex",
    "print_latex_tv",
    "PALETTES",
    "Band",
    "tikz_color_rainbow",
    "tikz_color_tv",
    "tikz_escape",
]


# Eight grays as percent-black, ordered so adjacent indices contrast
# strongly (light/dark interleaved) rather than forming a smooth ramp.
# Shared by the plain ``tikz_color_bwx8`` and the ``"bw"`` / ``"bw_dual"``
# TV palettes.
_BWX8_PERCENT = (0, 40, 20, 60, 10, 50, 30, 70)


def tikz_color_bwx8(idx: int) -> str:
    return "black!%02d" % _BWX8_PERCENT[idx % 8]


def tikz_color_white(idx: int) -> str:
    return "white"


def tikz_color_tv(tid: int, vid: int) -> str:
    """Eight-pastel TV palette, cycled by ``tid % 8`` (``vid`` unused).
    The default ``color`` for ``print_latex_tv``."""
    color_map = [
        "{rgb,255:red,175;green,175;blue,255}",
        "{rgb,255:red,175;green,255;blue,175}",
        "{rgb,255:red,255;green,255;blue,175}",
        "{rgb,255:red,255;green,175;blue,175}",
        "{rgb,255:red,210;green,210;blue,255}",
        "{rgb,255:red,210;green,255;blue,210}",
        "{rgb,255:red,255;green,255;blue,210}",
        "{rgb,255:red,255;green,210;blue,210}",
    ]
    return color_map[tid % 8]


def tikz_color_rainbow(index: int, count: int, saturation: float = 1.0) -> str:
    """Hue-wheel color for ``index`` in ``[0, count)``.

    The reusable "rainbow" primitive: hue = ``index / count`` with value
    pinned at 1, so every step is a distinct color.  (A physical rainbow
    has no purple->red wrap; this is the full HSV wheel, so the last
    indices loop back toward red.)  ``count`` clamps to >= 1 so a lone
    index stays well-defined.  ``saturation`` < 1 washes the color toward
    white -- the ``"rainbow_dual"`` palette uses that to render the value
    band paler than the thread band so the two are easy to tell apart.

    The palette factories below build on this primitive, spreading hues
    over the wheel by thread (and, for ``"rainbow_dual"``, by value).
    """
    count = max(count, 1)
    hue = (index % count) / count
    r, g, b = colorsys.hsv_to_rgb(hue, saturation, 1.0)
    return "{rgb,255:red,%d;green,%d;blue,%d}" % (
        round(r * 255),
        round(g * 255),
        round(b * 255),
    )


class Band(NamedTuple):
    """One horizontal fill band of a TV cell.  ``lo`` and ``hi`` are
    fractions in ``[0, 1]`` along the screen-vertical M axis (0 = the
    cell's top edge, 1 = its bottom edge); ``color`` is a TikZ fill spec.
    A single ``Band(0.0, 1.0, ...)`` is an ordinary one-fill cell; the
    ``"rainbow_dual"`` palette stacks two half-height bands."""

    lo: float
    hi: float
    color: str


# A *palette* is a factory ``palette(num_tid, num_vid) -> cell`` whose
# returned ``cell(tid, vid)`` honors the original ``color(tid, vid)``
# contract and returns either a single TikZ fill string (one fill spanning
# the cell) or a list of ``Band``s (stacked horizontal fills).  Building
# the palette as a closure lets it capture the thread / value counts (and
# any other parameters) without widening the per-cell signature -- the
# counts are needed to spread hues evenly over the wheel.


def _palette_pastel(num_tid: int, num_vid: int) -> Callable[[int, int], str]:
    """Eight-pastel palette (the default), cycled by thread."""
    return lambda tid, vid: tikz_color_tv(tid, vid)


def _palette_rainbow(num_tid: int, num_vid: int) -> Callable[[int, int], str]:
    """Single full-cell fill, hue spread over the wheel by thread."""
    return lambda tid, vid: tikz_color_rainbow(tid, num_tid)


def _palette_rainbow_dual(
    num_tid: int, num_vid: int
) -> Callable[[int, int], List[Band]]:
    """Two stacked bands: the thread hue (full saturation) over the value
    hue (reduced saturation, paler), so ``tid`` and ``vid`` read as two
    distinct hue channels rather than the weak saturation fade of a
    single hue, at the cost of two fills per cell."""

    def cell(tid: int, vid: int) -> List[Band]:
        return [
            Band(0.0, 0.5, tikz_color_rainbow(tid, num_tid)),
            Band(0.5, 1.0, tikz_color_rainbow(vid, num_vid, saturation=0.45)),
        ]

    return cell


# Monochrome counterparts of the color palettes above -- for B&W printing,
# papers, or a colorblind-safe fallback.


def _palette_white(num_tid: int, num_vid: int) -> Callable[[int, int], str]:
    """Blank cells: only the T#/V# labels and the grid show."""
    return lambda tid, vid: "white"


def _palette_bw(num_tid: int, num_vid: int) -> Callable[[int, int], str]:
    """Monochrome analogue of ``"pastel"``: the eight-gray bwx8 ramp,
    cycled by thread (``vid`` unused)."""
    return lambda tid, vid: tikz_color_bwx8(tid)


def _palette_bw_dual(num_tid: int, num_vid: int) -> Callable[[int, int], List[Band]]:
    """Monochrome analogue of ``"rainbow_dual"``: the thread gray over a
    lightened value gray, so ``tid`` and ``vid`` read as two bands.  The
    value band is scaled toward white -- the role the desaturation plays
    in ``"rainbow_dual"`` -- so the bottom band stays consistently paler
    than the top."""

    def cell(tid: int, vid: int) -> List[Band]:
        return [
            Band(0.0, 0.5, tikz_color_bwx8(tid)),
            Band(0.5, 1.0, "black!%d" % round(0.45 * _BWX8_PERCENT[vid % 8])),
        ]

    return cell


# Named palettes selectable by string -- the "map of palettes".  The
# ``palette`` argument of ``print_latex_tv`` also accepts a factory
# directly for one-off palettes.  Exposed as a read-only ``MappingProxyType``
# so a caller cannot mutate the shared registry and alter rendering
# process-wide; register a one-off palette by passing the factory directly.
PALETTES = MappingProxyType(
    {
        "pastel": _palette_pastel,
        "rainbow": _palette_rainbow,
        "rainbow_dual": _palette_rainbow_dual,
        "white": _palette_white,
        "bw": _palette_bw,
        "bw_dual": _palette_bw_dual,
    }
)


def tikz_escape(s: str) -> str:
    """Escape the LaTeX specials that show up in free-form title text
    (class paths, layout strings): ``\\``, ``_``, ``#``, ``&``, ``%``,
    ``$``, braces, ``^``, ``~``."""
    repl = {
        "\\": r"\textbackslash{}",
        "_": r"\_",
        "#": r"\#",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "{": r"\{",
        "}": r"\}",
        "^": r"\textasciicircum{}",
        "~": r"\textasciitilde{}",
    }
    return "".join(repl.get(c, c) for c in s)


def _latex_emitter(
    render_func: Callable[[str], None] | None,
) -> "tuple[Callable[..., None], Callable[[], None]]":
    """Build the output sink shared by ``print_latex`` and
    ``print_latex_tv``.

    Returns a pair ``(emit, finish)``:

    - ``emit(*args)`` writes one chunk of LaTeX.  With no ``render_func``
      it prints to stdout (the standalone-document path); otherwise it
      buffers the space-joined chunk for later delivery.
    - ``finish()`` hands the whole buffered ``{tikzpicture}`` to
      ``render_func`` in a single call (the embed-in-a-notebook path);
      it is a no-op when printing.

    Factoring this out keeps the two public functions from each
    re-declaring the identical buffer / dispatch logic (the form this
    started in before the helper was extracted).
    """
    buffer: List[str] = []

    def emit(*args: object) -> None:
        if render_func is None:
            print(*args)
        else:
            buffer.append(" ".join(str(arg) for arg in args))

    def finish() -> None:
        if render_func is not None:
            render_func(" ".join(buffer))

    return emit, finish


def print_latex(
    x: Union[Layout, ComposedLayout],
    *,
    color: Callable = tikz_color_bwx8,
    render_func: Callable[[str], None] | None = None,
) -> None:
    """
    Prints a layout.

    :param x: A layout
    :type x: Union[Layout, ComposedLayout]
    :param color: A function that returns TiKZ colors
    :type color: Callable
    :param render_func: Optional callback fed the ``{tikzpicture}`` body
        (without the standalone-document wrapper) in a single call,
        instead of printing a full LaTeX document to stdout.
    :type render_func: Callable[[str], None] | None
    """

    if not is_static(x):
        raise ValueError("Requires static input")
    if rank(x) > 2:
        raise ValueError("Requires rank <= 2 to print")

    if rank(x) == 1:
        layout = append(x, make_layout(1, stride=0))
    else:
        layout = x

    emit, finish = _latex_emitter(render_func)

    # The standalone-document wrapper is only useful for the print path;
    # the render hook receives just the {tikzpicture} body.
    if render_func is None:
        emit("%% Layout: {}", layout)
        emit("\\documentclass[convert]{standalone}")
        emit("\\usepackage{tikz}")
        emit("\\begin{document}")
    emit(
        "\\begin{tikzpicture}[x={(0cm,-1cm)},y={(1cm,0cm)},every node/.style={minimum size=1cm, outer sep=0pt}]"
    )

    M, N = product_each(x.shape)

    for m in range(M):
        for n in range(N):
            idx = layout((m, n))
            emit("\\node[fill=")
            emit(color(idx))
            emit("] at (%d,%d) {%d};\n" % (m, n, idx))
    emit(
        "\\draw[color=black,thick,shift={(-0.5,-0.5)}] (0,0) grid (%d,%d);\n\n" % (M, N)
    )
    for m in range(M):
        emit("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (m, -1, m))
    for n in range(N):
        emit("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (-1, n, n))

    ## Footer
    emit("\\end{tikzpicture}")
    if render_func is None:
        emit("\\end{document}")
    finish()


def print_latex_tv(
    layout_tv: Union[Layout, ComposedLayout],
    tile_mn: Union[IntTuple, Layout],
    *,
    color: Callable = tikz_color_tv,
    palette: Optional[Union[str, Callable]] = None,
    title: Optional[str] = None,
    axis_labels: bool = False,
    render_func: Callable[[str], None] | None = None,
) -> None:
    """
    Prints a tv layout for a tile M N. Everything must be static.

    :param layout_tv: A static thread value layout
    :type layout_tv: Union[Layout, ComposedLayout]
    :param tile_mn: A static M N tile
    :type tile_mn: Union[IntTuple, Layout]
    :param color: A function ``color(tid, vid) -> str`` returning a TikZ
        fill color for the cell owned by thread ``tid`` value ``vid``.
        Used when ``palette`` is ``None``; ignored otherwise.
    :type color: Callable
    :param palette: Optional richer cell coloring that supersedes
        ``color``.  Either the name of a built-in palette (a key of
        ``PALETTES``: the color ``"pastel"``, ``"rainbow"``,
        ``"rainbow_dual"`` or the monochrome ``"white"``, ``"bw"``,
        ``"bw_dual"``) or a factory ``palette(num_tid, num_vid) -> cell``
        where
        ``cell(tid, vid)`` returns either a TikZ fill string (one fill
        spanning the cell) or a list of ``Band``s (stacked horizontal
        fills).  The factory form lets a palette capture the thread /
        value counts -- needed to spread hues evenly over the wheel --
        without widening the per-cell ``(tid, vid)`` contract.
    :type palette: Optional[Union[str, Callable]]
    :param title: Optional title drawn above the figure, one line per
        ``\\n``-separated segment (e.g. the operator / function /
        tensor that produced this layout).  LaTeX specials are escaped.
    :type title: Optional[str]
    :param axis_labels: When ``True``, annotate the M (row, downward)
        and N (column, rightward) axis directions.  The picture's
        coordinate basis runs M down and N right; these labels make
        that orientation explicit so a reader can tell whether a
        thread's values are contiguous along the memory-major axis.
    :type axis_labels: bool
    :param render_func: Optional callback fed the ``{tikzpicture}`` body
        (without the standalone-document wrapper) in a single call,
        instead of printing a full LaTeX document to stdout.
    :type render_func: Callable[[str], None] | None
    """
    if not is_static(layout_tv) or not is_static(tile_mn):
        raise ValueError("Layout tv and tile_mn must be static")
    if rank(layout_tv) != 2:
        raise ValueError("Require layout_tv to be rank 2")

    emit, finish = _latex_emitter(render_func)

    # The standalone-document wrapper is only useful for the print path;
    # the render hook receives just the {tikzpicture} body.
    if render_func is None:
        emit("%% Layout TV: {}", layout_tv)
        emit("\\documentclass[convert]{standalone}")
        emit("\\usepackage{tikz}")
        emit("\\begin{document}")
    emit(
        "\\begin{tikzpicture}[x={(0cm,-1cm)},y={(1cm,0cm)},every node/.style={minimum size=1cm, outer sep=0pt}]\n"
    )

    if not isinstance(tile_mn, Layout):
        tile_mn = make_layout(tile_mn)

    M, N = product_each(tile_mn.shape)  # type: ignore[union-attr]
    filled = [[False for n in range(N)] for m in range(M)]

    num_tid = size(layout_tv, mode=[0])
    num_vid = size(layout_tv, mode=[1])

    # Resolve a per-cell ``cell(tid, vid)`` function.  Without a
    # ``palette`` we use ``color`` directly (it already has the
    # ``(tid, vid)`` contract).  A ``palette`` is a factory called once
    # with the thread / value counts, so it captures them in a closure
    # instead of taking them per cell.
    if palette is None:
        cell = color
    else:
        if isinstance(palette, str):
            if palette not in PALETTES:
                raise ValueError(
                    "Unknown palette %r; choose one of %s or pass a factory"
                    % (palette, sorted(PALETTES))
                )
            palette = PALETTES[palette]
        cell = palette(num_tid, num_vid)

    for tid in range(num_tid):
        for vid in range(num_vid):
            idx = layout_tv((tid, vid))
            m = (idx // tile_mn.stride[0]) % tile_mn.shape[0]  # type: ignore[operator, union-attr, index]
            n = (idx // tile_mn.stride[1]) % tile_mn.shape[1]  # type: ignore[operator, union-attr, index]
            if filled[m][n]:
                continue
            filled[m][n] = True
            # A cell is one or more horizontal bands stacked along the
            # screen-vertical M axis.  Normalize a bare fill string to a
            # single full-height band so both cases share one code path.
            bands = cell(tid, vid)
            if isinstance(bands, str):
                bands = [Band(0.0, 1.0, bands)]
            for band in bands:
                # Cell (m, n) spans [m-0.5, m+0.5] x [n-0.5, n+0.5]; the
                # band covers the M-fraction [lo, hi] (0 = top edge at
                # m-0.5).  Drawn as a filled rectangle.
                emit(
                    "\\path[fill=%s] (%g,%g) rectangle (%g,%g);\n"
                    % (
                        band.color,
                        m - 0.5 + band.lo,
                        n - 0.5,
                        m - 0.5 + band.hi,
                        n + 0.5,
                    )
                )
            # Fill-less T#/V# label on top of the band(s).
            emit("\\node at (%d,%d) {\\shortstack{T%d \\\\ V%d}};\n" % (m, n, tid, vid))

    emit(
        "\\draw[color=black,thick,shift={(-0.5,-0.5)}] (0,0) grid (%d,%d);\n\n" % (M, N)
    )
    for m in range(M):
        emit("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (m, -1, m))
    for n in range(N):
        emit("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (-1, n, n))

    # Optional axis-direction labels and title.  The basis maps a data
    # coord (a, b) to screen (b, -a), so the index labels sit just
    # outside the grid (column indices at data x=-1, row indices at
    # data y=-1); place these annotations just past those index labels
    # so they sit close to the numbering without overlapping it.
    if axis_labels:
        emit("\\node at (%g,%g) {\\Large N (col) $\\rightarrow$};\n" % (-1.7, N / 2.0))
        # Rotate the M label by pi/2 so it reads alongside the (vertical,
        # downward-running) M axis instead of across it.
        emit(
            "\\node[rotate=90] at (%g,%g) {\\Large $\\leftarrow$ M (row)};\n"
            % (M / 2.0, -2.0)
        )
    if title:
        body = " \\\\ ".join(
            "\\texttt{" + tikz_escape(line) + "}" for line in title.split("\n")
        )
        # Anchor the title by its south (bottom) edge so extra title
        # lines grow it upward without changing its gap from the N-axis
        # label below.  ``anchor`` is a canvas-space offset, unaffected
        # by the picture's M-down/N-right coordinate basis, so south is
        # always the visual bottom.
        emit(
            "\\node[anchor=south] at (%g,%g) {\\shortstack{%s}};\n"
            % (-2.2, N / 2.0, body)
        )

    ## Footer
    emit("\\end{tikzpicture}")
    if render_func is None:
        emit("\\end{document}")
    finish()
