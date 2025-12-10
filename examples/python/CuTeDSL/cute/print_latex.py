# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import argparse
import cutlass
import cutlass.cute as cute
from cutlass.utils import print_latex, print_latex_tv
from cutlass import for_generate, yield_out

"""
A Latex Printing Example using CuTe DSL.
This example prints latex for a given layout or thread value layout.
The primary goal for this example is to demonstrate how to dump latex, which can then be
turned into an image in your favorite latex compiler.
To run this example:
.. code-block:: bash
    python examples/python/CuteDSL/cute/print_latex.py
    python examples/python/CuteDSL/cute/print_latex.py --tv_layout
To compile, pipe the output to a file and use a tool like pdflatex:
.. code-block:: bash
    python examples/python/CuTeDSL/cute/print_latex.py > latex.tex
    pdflatex latex.tex
"""


@cute.jit
def main(print_tv_layout: cutlass.Constexpr[bool]):
    # Note: only support compile time printing layouts
    if cutlass.const_expr(print_tv_layout):
        thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
        val_layout = cute.make_ordered_layout((4, 1), order=(1, 0))
        tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)
        print_latex_tv(tv_layout, tiler_mn)
    else:
        layout = cute.make_layout((10, 10))
        print_latex(layout)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="example of print latex and print latex tv"
    )
    parser.add_argument("--tv_layout", action="store_true")

    args = parser.parse_args()

    main(args.tv_layout)
