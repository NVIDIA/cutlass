# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Callable, Union

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

__all__ = ["print_latex", "print_latex_tv"]


def tikz_color_bwx8(idx: int):
    color_map = [
        "black!00",
        "black!40",
        "black!20",
        "black!60",
        "black!10",
        "black!50",
        "black!30",
        "black!70",
    ]
    return color_map[idx % 8]


def tikz_color_white(idx: int):
    return "white"


def tikz_color_tv(tid: int, vid: int):
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


def print_latex(x: Union[Layout, ComposedLayout], *, color: Callable = tikz_color_bwx8):
    """
    Prints a layout.
    :param x: A layout
    :type x: Union[Layout, ComposedLayout]
    :param color: A function that returns TiKZ colors
    :type color: Callable
    """

    if not is_static(x):
        raise ValueError("Requires static input")
    if rank(x) > 2:
        raise ValueError("Requires rank <= 2 to print")

    if rank(x) == 1:
        layout = append(x, make_layout(1, stride=0))
    else:
        layout = x

    print("%% Layout: {}", layout)
    print("\\documentclass[convert]{standalone}")
    print("\\usepackage{tikz}")
    print("\\begin{document}")
    print(
        "\\begin{tikzpicture}[x={(0cm,-1cm)},y={(1cm,0cm)},every node/.style={minimum size=1cm, outer sep=0pt}]"
    )

    M, N = product_each(x.shape)

    for m in range(M):
        for n in range(N):
            idx = layout((m, n))
            print("\\node[fill=")
            print(color(idx))
            print("] at (%d,%d) {%d};\n" % (m, n, idx))
    print(
        "\\draw[color=black,thick,shift={(-0.5,-0.5)}] (0,0) grid (%d,%d);\n\n" % (M, N)
    )
    for m in range(M):
        print("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (m, -1, m))
    for n in range(N):
        print("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (-1, n, n))

    ## Footer
    print("\\end{tikzpicture}")
    print("\\end{document}")


def print_latex_tv(
    layout_tv: Union[Layout, ComposedLayout],
    tile_mn: Union[IntTuple, Layout],
    *,
    color: Callable = tikz_color_tv,
):
    """
    Prints a tv layout for a tile M N. Everything must be static.
    :param layout_tv: A static thread value layout
    :type layout_tv: Union[Layout, ComposedLayout]
    :param tile_mn: A static M N tile
    :type tile_mn: Union[IntTuple, Layout]
    :param color: A function that returns TiKZ colors
    :type color: Callable
    """
    if not is_static(layout_tv) or not is_static(tile_mn):
        raise ValueError("Layout tv and tile_mn must be static")
    if rank(layout_tv) != 2:
        raise ValueError("Require layout_tv to be rank 2")

    print("%% Layout TV: {}", layout_tv)
    print("\\documentclass[convert]{standalone}")
    print("\\usepackage{tikz}")
    print("\\begin{document}")
    print(
        "\\begin{tikzpicture}[x={(0cm,-1cm)},y={(1cm,0cm)},every node/.style={minimum size=1cm, outer sep=0pt}]\n"
    )

    if not isinstance(tile_mn, Layout):
        tile_mn = make_layout(tile_mn)

    M, N = product_each(tile_mn.shape)
    filled = [[False for n in range(N)] for m in range(M)]

    for tid in range(size(layout_tv, mode=[0])):
        for vid in range(size(layout_tv, mode=[1])):
            idx = layout_tv((tid, vid))
            m = (idx // tile_mn.stride[0]) % tile_mn.shape[0]
            n = (idx // tile_mn.stride[1]) % tile_mn.shape[1]
            if not filled[m][n]:
                filled[m][n] = True
                print(
                    "\\node[fill=%s] at (%d,%d) {\\shortstack{T%d \\\\ V%d}};\n"
                    % (color(tid, vid), m, n, tid, vid)
                )

    print(
        "\\draw[color=black,thick,shift={(-0.5,-0.5)}] (0,0) grid (%d,%d);\n\n" % (M, N)
    )
    for m in range(M):
        print("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (m, -1, m))
    for n in range(N):
        print("\\node at (%d,%d) {\\Large{\\texttt{%d}}};\n" % (-1, n, n))

    ## Footer
    print("\\end{tikzpicture}")
    print("\\end{document}")
