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

"""Operator-API wrapper around ``nvMatmulHeuristics`` (CUTLASS3 backend).

Callers pass an nvMMH precision string and ``(A, B, out)`` majors as
``"t"`` (row-major) / ``"n"`` (column-major).
Requires ``nvidia-matmul-heuristics>=0.1.0.27`` (0.1.0.27 API shape).
"""

from __future__ import annotations

import ctypes
import functools
import os
from typing import TYPE_CHECKING, Any, Literal

if TYPE_CHECKING:
    from nvMatmulHeuristics import NvMatmulHeuristicsMatmulLayout

TnLayout = Literal["t", "n"]

# Only the devices we can actually rank today using nvmmh (SM100 dense GEMM) are
# mapped
_SUPPORTED_GPU_CC: dict[str, int] = {
    "B200": 100,
    "GB200_NVL": 100,
    "GB300_NVL": 100,
}


def gpu_compute_capability(gpu: str) -> int:
    """Return the compute capability nvMMH's ``gpu`` device name represents.

    Only SM100 devices are mapped -- nvmatmul doesn't rank other generations
    yet.

    Args:
        gpu (str): An ``NvMatmulHeuristicsNvidiaGpu`` member name (e.g.
            ``"B200"``).

    Returns:
        int: The compute capability of ``gpu``.

    Raises:
        KeyError: If ``gpu`` isn't a recognized, supported nvMMH device name.
    """
    try:
        return _SUPPORTED_GPU_CC[gpu]
    except KeyError:
        raise KeyError(
            f"Unsupported GPU: {gpu}. Note, currently only Blackwell GPU SKUs are supported for heuristics: {', '.join(_SUPPORTED_GPU_CC.keys())}"
        ) from None


class MatmulHeuristics:
    """Thin driver for ``nvMatmulHeuristics`` with the CUTLASS3 backend.

    Targets the ``nvidia-matmul-heuristics`` 0.1.0.27 API shape (GPU at
    construct time, ``setBackendValueProperty``, scalar ``m,n,k`` problem).
    """

    def __init__(self, gpu: str | None = None) -> None:
        import nvMatmulHeuristics

        self.mmh_lib = nvMatmulHeuristics
        self.gpu = gpu

        if "CUTLASS_NVMMH_SO_PATH" in os.environ:
            nvmmh_interface_ex = functools.partial(
                self.mmh_lib.NvMatmulHeuristicsInterfaceEx,
                path=os.environ["CUTLASS_NVMMH_SO_PATH"],
            )
        else:
            nvmmh_interface_ex = self.mmh_lib.NvMatmulHeuristicsInterfaceEx

        init_kwargs: dict[str, Any] = {
            "backend": self.mmh_lib.NvMatmulHeuristicsTarget["CUTLASS3"],
            "flags": self.mmh_lib.NvMatmulHeuristicsFlags.PERF_MODEL_BASED_AUTO_TUNING,
            "gpu": (
                self.mmh_lib.NvMatmulHeuristicsNvidiaGpu[self.gpu] if self.gpu else None
            ),
            "load_discovery_implicitly": True,
        }

        self.nvmmh = nvmmh_interface_ex(**init_kwargs)
        self.backend = self.nvmmh.createBackend(
            self.mmh_lib.NvMatmulHeuristicsTarget["CUTLASS3"]
        )

    def __del__(self) -> None:
        """Release backend resources owned by this wrapper."""
        try:
            if hasattr(self, "backend") and self.backend:
                self.nvmmh.destroyBackend(self.backend)
                self.backend = None
        except Exception:
            pass

    def _layout_from_tn(
        self, layouts: tuple[TnLayout, TnLayout, TnLayout]
    ) -> NvMatmulHeuristicsMatmulLayout:
        """Map ``(A, B, out)`` ``t``/``n`` majors to an nvMMH matmul layout.

        Returns:
            NvMatmulHeuristicsMatmulLayout: The matching nvMMH layout enum
            member for the given ``(A, B, out)`` majors.
        """
        if len(layouts) != 3:
            raise ValueError(f"Expected 3 layouts (A, B, out), got {len(layouts)}")
        for i, layout in enumerate(layouts):
            if layout not in ("t", "n"):
                raise ValueError(f"layouts[{i}] must be 't' or 'n', got {layout!r}")
        full_layout_str = "".join(layouts)
        input_layouts = full_layout_str[:2].upper()
        lh_layout = (
            input_layouts
            + "_"
            + ("ROW_MAJOR" if full_layout_str[-1] == "t" else "COL_MAJOR")
        )
        return self.mmh_lib.NvMatmulHeuristicsMatmulLayout[lh_layout]

    def _set_backend_property(self, backend_property: Any, value: int) -> None:
        """Set a backend property via ``setBackendValueProperty``."""
        c_val = ctypes.c_int(value)
        self.nvmmh.setBackendValueProperty(
            self.backend,
            backend_property,
            ctypes.byref(c_val),
            ctypes.sizeof(c_val),
        )

    def set_cta_div_n(self, div_n: int) -> None:
        self._set_backend_property(
            self.mmh_lib.NvMatmulHeuristicsBackendProperty.CTA_TILE_N_DIV_REQUIREMENT,
            div_n,
        )

    def set_cta_div_m(self, div_m: int) -> None:
        self._set_backend_property(
            self.mmh_lib.NvMatmulHeuristicsBackendProperty.CTA_TILE_M_DIV_REQUIREMENT,
            div_m,
        )

    def get_configs(
        self,
        m: int,
        n: int,
        k: int,
        batch_count: int,
        precision: str,
        layouts: tuple[TnLayout, TnLayout, TnLayout],
        align_a: int,
        align_b: int,
        void_c: bool = False,
        use_fast_acc: bool = True,
        count: int = 1,
    ) -> list[dict[str, Any]]:
        """Return up to ``count`` ranked configs for the given GEMM problem.

        Args:
            m (int): Problem extent M.
            n (int): Problem extent N.
            k (int): Problem extent K.
            batch_count (int): Batch (L) count.
            precision (str): nvMMH precision string (e.g. ``'HSH'``, ``'QQSS'``).
            layouts (tuple[TnLayout, TnLayout, TnLayout]): ``(A, B, out)``
                majors as ``'t'`` (row) / ``'n'`` (col).
            align_a (int): Alignment of operand A, in elements.
            align_b (int): Alignment of operand B, in elements.
            void_c (bool): Unused; kept for API compatibility with the former
                ``cutlass_library`` wrapper.
            use_fast_acc (bool): FP8 fast-accum toggle (applied as a backend
                property).
            count (int): Maximum number of configs to return (best-first).

        Returns:
            list[dict[str, Any]]: Config dicts with only the fields the
            Operator API matcher consumes today: CTA tile (M/N/K), cluster
            (M/N), and ``estimated_runtime``.
        """
        self._set_backend_property(
            self.mmh_lib.NvMatmulHeuristicsBackendProperty.DISABLE_FAST_ACC_FOR_FP8,
            0 if use_fast_acc else 1,
        )

        layout = self._layout_from_tn(layouts)
        matmul_problem = self.nvmmh.makeNvMatmulHeuristicsProblem(
            m, n, k, layout, batch_count
        )
        configs = self.nvmmh.getEx(
            matmul_problem, count, self.backend, precision=precision
        )

        # Only emit keys the matcher reads. Scheduler-related nvMMH fields
        # (swizzle, raster order, split-K) are omitted until
        # TileSchedulerMetadata can represent them for matching.
        ret: list[dict[str, Any]] = []
        for config in configs:
            kernel = config["kernel"]
            entry: dict[str, Any] = {
                "estimated_runtime": config["runtime"],
                "cta_tile_m": kernel.cta_tile_m,
                "cta_tile_n": kernel.cta_tile_n,
                "cta_tile_k": kernel.cta_tile_k,
                "cluster_m": kernel.cluster_m,
                "cluster_n": kernel.cluster_n,
            }
            ret.append(entry)

        return ret
