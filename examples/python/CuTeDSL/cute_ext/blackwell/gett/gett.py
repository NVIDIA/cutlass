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

"""GETT (general tensor-tensor contraction) reference kernel and CLI.

A GETT is a GEMM whose M, N, K and L dimensions are each a *group* of tensor
modes rather than a single extent. The contraction is written as
C[c_modes] = A[a_modes] * B[b_modes], and each mode letter is classified by
where it appears:

  row (M)       in A and C        col (N)        in B and C
  reduction (K) in A and B        batch (L)      in A, B and C

GettCommandLine.parse() turns three mode strings plus an extent map into a
GettProblem: it derives those categories, computes column-major strides in the
order the modes were written, sorts each category by stride to promote
coalescing, and folds the per-category extents into the (M, K, L) / (N, K, L) /
(M, N, L) CuTe layouts the kernel launches over.

RefGettKernel is a deliberately naive element-wise triple loop, used as a
correctness reference for real GETT kernels, not as a performance target.
"""

import cutlass
from cutlass import cute
from cutlass.base_dsl.typing import Constexpr

import torch
from typing import List, Dict, Tuple
from functools import reduce
import operator


class GettProblem:
    """Extents and strides of one GETT, grouped by mode category.

    Every list is per-mode and index-aligned within its category, ordered as
    the layouts are built: ``M[i]`` has stride ``ldAm[i]`` in A and ``ldCm[i]``
    in C, and so on. ``total_*`` are the products of the per-mode extents, i.e.
    the flattened GEMM shape the reference kernel tiles over. ``layout_a/b/c``
    are (shape, stride) pairs of those grouped modes, ready for
    ``cute.make_layout``. Populated by GettCommandLine.parse(); a
    default-constructed instance is empty and not usable.
    """

    def __init__(self):
        # Row modes: appear in A and C/D
        self.M: List[int] = []
        self.ldAm: List[int] = []
        self.ldCm: List[int] = []

        # Column modes: appear in B and C/D
        self.N: List[int] = []
        self.ldBn: List[int] = []
        self.ldCn: List[int] = []

        # Reduction modes: appear in A and B
        self.K: List[int] = []
        self.ldAk: List[int] = []
        self.ldBk: List[int] = []

        # Batch modes: appear in all in/out tensors
        self.L: List[int] = []
        self.ldAl: List[int] = []
        self.ldBl: List[int] = []
        self.ldCl: List[int] = []

        self.layout_a = None
        self.layout_b = None
        self.layout_c = None

        self.total_m = 0
        self.total_n = 0
        self.total_k = 0
        self.total_l = 0


class RefGettKernel:
    """
    Naive reference GETT kernel (element-wise triple loop on GPU).
    """

    @cute.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        problem_info: Constexpr[GettProblem],
    ):
        grid = (
            cute.ceil_div(mD.layout.shape[0], 128),
            cute.ceil_div(mD.layout.shape[1], 128),
            mD.layout.shape[2],
        )

        self.kernel(mA, mB, mD, problem_info).launch(
            grid=grid,
            block=(32, 32, 1),
            cluster=(1, 1, 1),
        )

    @cute.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        problem_info: Constexpr[GettProblem],
    ):
        cta_tiler = (128, 128, problem_info.total_k)
        cta_tiler_mk = (cta_tiler[0], cta_tiler[2])
        cta_tiler_nk = (cta_tiler[1], cta_tiler[2])
        cta_tiler_mn = (cta_tiler[0], cta_tiler[1])

        gA = cute.zipped_divide(mA, cta_tiler_mk)
        gB = cute.zipped_divide(mB, cta_tiler_nk)
        gD = cute.zipped_divide(mD, cta_tiler_mn)

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, tid_y, _ = cute.arch.thread_idx()

        gA_tile = gA[(None, None), (cta_m, 0, cta_l)]
        gB_tile = gB[(None, None), (cta_n, 0, cta_l)]
        gD_tile = gD[(None, None), (cta_m, cta_n, cta_l)]

        thread_tiler = (32, 32, 1)
        thread_tiler_mk = (thread_tiler[0], thread_tiler[2])
        thread_tiler_nk = (thread_tiler[1], thread_tiler[2])
        thread_tiler_mn = (thread_tiler[0], thread_tiler[1])

        gA_thread = cute.zipped_divide(gA_tile, thread_tiler_mk)
        gB_thread = cute.zipped_divide(gB_tile, thread_tiler_nk)
        gD_thread = cute.zipped_divide(gD_tile, thread_tiler_mn)

        gA_thread_tile = gA_thread[(tid_x, 0), (None, None)]
        gB_thread_tile = gB_thread[(tid_y, 0), (None, None)]
        gD_thread_tile = gD_thread[(tid_x, tid_y), (None, None)]

        for m in cutlass.range(cute.size(gD_thread_tile, mode=[0]), unroll_full=True):
            for n in cutlass.range(
                cute.size(gD_thread_tile, mode=[1]), unroll_full=True
            ):
                gD_thread_tile[m, n] = cute.Float16(0.0)
                for k in cutlass.range(
                    cute.size(gA_thread_tile, mode=[1]), unroll_full=True
                ):
                    gD_thread_tile[m, n] += gA_thread_tile[m, k] * gB_thread_tile[n, k]


class GettCommandLine:
    @staticmethod
    def parse_modes(mode_str: str) -> List[str]:
        """Parse comma-separated mode string into list of characters"""
        return [c.strip() for c in mode_str.split(",")]

    @staticmethod
    def parse_extents(extent_str: str) -> Dict[str, int]:
        """Parse extent string like 'm:32,n:128,k:64' into dictionary

        Raises:
            ValueError: If an entry is not 'mode:size' or size is not an int.
        """
        extents = {}
        for pair in extent_str.split(","):
            mode, sep, size = pair.partition(":")
            if not sep or not mode.strip() or not size.strip():
                raise ValueError(f"Malformed extent {pair!r}, expected 'mode:size'")
            extents[mode.strip()] = int(size.strip())
        return extents

    @staticmethod
    def compute_strides(modes: List[str], mode_sizes: Dict[str, int]) -> Dict[str, int]:
        """Compute column-major strides for given modes and sizes"""
        strides = {}
        current = 1

        for mode in modes:
            strides[mode] = current
            current *= mode_sizes[mode]

        return strides

    @staticmethod
    def find_mode_categories(
        a_mode: List[str], b_mode: List[str], c_mode: List[str]
    ) -> Tuple[List[str], List[str], List[str], List[str]]:
        """Find semantic categories of modes"""
        # Convert to sets for intersection operations
        a_set = set(a_mode)
        b_set = set(b_mode)
        c_set = set(c_mode)

        # Find semantic categories using set intersections
        row_modes = sorted(list(a_set & c_set))  # in A and C
        col_modes = sorted(list(b_set & c_set))  # in B and C
        red_modes = sorted(list(a_set & b_set))  # in A and B
        bat_modes = sorted(list(set(row_modes) & set(col_modes)))  # in all three

        # Remove batch modes from other categories
        row_modes = [m for m in row_modes if m not in bat_modes]
        col_modes = [m for m in col_modes if m not in bat_modes]
        red_modes = [m for m in red_modes if m not in bat_modes]

        return row_modes, col_modes, red_modes, bat_modes

    @staticmethod
    def parse(
        mode_a: str, mode_b: str, mode_c: str, extents: str, verbose: bool = False
    ) -> GettProblem:
        """Parse GETT problem from command line arguments

        Raises:
            ValueError: If a tensor repeats a mode, or if a mode does not
                appear in exactly two tensors (row/col/reduction) or in all
                three (batch).
        """

        # Parse modes
        a_mode = GettCommandLine.parse_modes(mode_a)
        b_mode = GettCommandLine.parse_modes(mode_b)
        c_mode = GettCommandLine.parse_modes(mode_c)

        # find_mode_categories() derives categories from set intersections, so
        # a mode that appears once (or twice within one tensor) falls out of
        # every category and silently changes the contraction. Reject those
        # here instead of returning a problem the caller did not ask for.
        for tensor_name, modes in (("A", a_mode), ("B", b_mode), ("C", c_mode)):
            if len(modes) != len(set(modes)):
                raise ValueError(f"Duplicate modes in {tensor_name}: {modes}")

        mode_counts: Dict[str, int] = {}
        for mode in a_mode + b_mode + c_mode:
            mode_counts[mode] = mode_counts.get(mode, 0) + 1
        invalid = sorted(m for m, count in mode_counts.items() if count not in (2, 3))
        if invalid:
            raise ValueError(
                "Each mode must appear in exactly two tensors (row/col/"
                "reduction) or in all three (batch); invalid modes: "
                f"{', '.join(invalid)}"
            )

        # Parse extents
        mode_sizes = GettCommandLine.parse_extents(extents)

        # Initialize all modes to size 1 if not specified
        all_modes = set(a_mode + b_mode + c_mode)
        for mode in all_modes:
            if mode not in mode_sizes:
                mode_sizes[mode] = 1

        if verbose:
            print(
                f"C[{','.join(c_mode)}] = A[{','.join(a_mode)}] * B[{','.join(b_mode)}]"
            )
            for mode, size in mode_sizes.items():
                print(f"     {mode} : {size}")

        # Compute strides for each tensor
        mode_ldA = GettCommandLine.compute_strides(a_mode, mode_sizes)
        mode_ldB = GettCommandLine.compute_strides(b_mode, mode_sizes)
        mode_ldC = GettCommandLine.compute_strides(c_mode, mode_sizes)

        # Find mode categories
        row_modes, col_modes, red_modes, bat_modes = (
            GettCommandLine.find_mode_categories(a_mode, b_mode, c_mode)
        )

        if verbose:
            print(f"  rows : {row_modes}")
            print(f"  cols : {col_modes}")
            print(f"  reds : {red_modes}")
            print(f"  bats : {bat_modes}")

        # Sort modes within each category to promote coalescing
        # (Following the C++ logic for sorting by minimum stride and size)

        # Sort batched modes by min(ldAl, ldBl) and size
        bat_modes.sort(key=lambda l: (min(mode_ldA[l], mode_ldB[l]), mode_sizes[l]))

        # Sort reduction modes by min(ldAk, ldBk) and size
        red_modes.sort(key=lambda k: (min(mode_ldA[k], mode_ldB[k]), mode_sizes[k]))

        # Sort row modes by min(ldAm, ldCm) and ldAm
        row_modes.sort(key=lambda m: (min(mode_ldA[m], mode_ldC[m]), mode_ldA[m]))

        # Sort col modes by min(ldBn, ldCn) and ldBn
        col_modes.sort(key=lambda n: (min(mode_ldB[n], mode_ldC[n]), mode_ldB[n]))

        # Create result object
        problem = GettProblem()

        # Extract sizes and strides for each category
        problem.M = [mode_sizes[m] for m in row_modes]
        problem.ldAm = [mode_ldA[m] for m in row_modes]
        problem.ldCm = [mode_ldC[m] for m in row_modes]

        problem.N = [mode_sizes[n] for n in col_modes]
        problem.ldBn = [mode_ldB[n] for n in col_modes]
        problem.ldCn = [mode_ldC[n] for n in col_modes]

        problem.K = [mode_sizes[k] for k in red_modes]
        problem.ldAk = [mode_ldA[k] for k in red_modes]
        problem.ldBk = [mode_ldB[k] for k in red_modes]

        problem.L = [mode_sizes[l] for l in bat_modes]
        problem.ldAl = [mode_ldA[l] for l in bat_modes]
        problem.ldBl = [mode_ldB[l] for l in bat_modes]
        problem.ldCl = [mode_ldC[l] for l in bat_modes]

        problem.layout_a = (
            (problem.M, problem.K, problem.L),
            (problem.ldAm, problem.ldAk, problem.ldAl),
        )
        problem.layout_b = (
            (problem.N, problem.K, problem.L),
            (problem.ldBn, problem.ldBk, problem.ldBl),
        )
        problem.layout_c = (
            (problem.M, problem.N, problem.L),
            (problem.ldCm, problem.ldCn, problem.ldCl),
        )

        problem.total_m = reduce(operator.mul, problem.M, 1)
        problem.total_n = reduce(operator.mul, problem.N, 1)
        problem.total_k = reduce(operator.mul, problem.K, 1)
        problem.total_l = reduce(operator.mul, problem.L, 1)

        if verbose:
            M_size = reduce(operator.mul, problem.M, 1)
            N_size = reduce(operator.mul, problem.N, 1)
            K_size = reduce(operator.mul, problem.K, 1)
            L_size = reduce(operator.mul, problem.L, 1)

            print(f"     M : ({M_size}) ", end="")
            for i, m in enumerate(row_modes):
                print(f"{m}:{mode_sizes[m]} ", end="")
            print()

            print(f"     N : ({N_size}) ", end="")
            for i, n in enumerate(col_modes):
                print(f"{n}:{mode_sizes[n]} ", end="")
            print()

            print(f"     K : ({K_size}) ", end="")
            for i, k in enumerate(red_modes):
                print(f"{k}:{mode_sizes[k]} ", end="")
            print()

            print(f"     L : ({L_size}) ", end="")
            for i, l in enumerate(bat_modes):
                print(f"{l}:{mode_sizes[l]} ", end="")
            print()

            print(f"  ldAm : {problem.ldAm}")
            print(f"  ldAk : {problem.ldAk}")
            print(f"  ldAl : {problem.ldAl}")
            print(f"  ldBn : {problem.ldBn}")
            print(f"  ldBk : {problem.ldBk}")
            print(f"  ldBl : {problem.ldBl}")
            print(f"  ldCm : {problem.ldCm}")
            print(f"  ldCn : {problem.ldCn}")
            print(f"  ldCl : {problem.ldCl}")
            print(f"  layout_a : {problem.layout_a}")
            print(f"  layout_b : {problem.layout_b}")
            print(f"  layout_c : {problem.layout_c}")

        return problem

    @staticmethod
    def get_torch_tensors(
        problem: GettProblem,
        a_dtype: torch.dtype,
        b_dtype: torch.dtype,
        c_dtype: torch.dtype,
    ) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
        return (
            torch.empty(problem.total_l * problem.total_m * problem.total_k)
            .random_(-4, 4)
            .to(a_dtype)
            .cuda(),
            torch.empty(problem.total_l * problem.total_k * problem.total_n)
            .random_(-4, 4)
            .to(b_dtype)
            .cuda(),
            torch.empty(problem.total_l * problem.total_m * problem.total_n)
            .random_(-4, 4)
            .to(c_dtype)
            .cuda(),
            torch.zeros(problem.total_l * problem.total_m * problem.total_n)
            .to(c_dtype)
            .cuda(),
        )

    @staticmethod
    def get_cute_layouts(
        problem: GettProblem,
    ) -> Tuple[cute.Layout, cute.Layout, cute.Layout]:
        shape_a, stride_a = problem.layout_a
        shape_b, stride_b = problem.layout_b
        shape_c, stride_c = problem.layout_c
        return (
            cute.make_layout(
                (tuple(shape_a[0]), tuple(shape_a[1]), tuple(shape_a[2])),
                stride=(tuple(stride_a[0]), tuple(stride_a[1]), tuple(stride_a[2])),
            ),
            cute.make_layout(
                (tuple(shape_b[0]), tuple(shape_b[1]), tuple(shape_b[2])),
                stride=(tuple(stride_b[0]), tuple(stride_b[1]), tuple(stride_b[2])),
            ),
            cute.make_layout(
                (tuple(shape_c[0]), tuple(shape_c[1]), tuple(shape_c[2])),
                stride=(tuple(stride_c[0]), tuple(stride_c[1]), tuple(stride_c[2])),
            ),
        )
