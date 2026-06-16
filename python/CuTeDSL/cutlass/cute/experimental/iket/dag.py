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


"""
IKET DAG — lightweight dataflow dependency graph for kernel regions.

Usage::

    from cutlass.cute.experimental import iket

    dag = iket.dag("gemm_fp16_2stage")
    dag.edge("prologue_load", "MMA_mainloop", label="smem[0]", via="mbarrier")
    dag.edge("TMA_load",      "MMA_mainloop", label="smem[s]", via="mbarrier")
    dag.edge("MMA_mainloop",  "epilogue",     label="acc",     via="tcgen05_commit")

    # Inside @cute.kernel — use existing iket.range_start / range_end as usual.
    # The dag object is pure metadata; it never touches the IR.

    dag.save("gemm_fp16_2stage.iket_dag.json")

Regions are implicit — created automatically from edge endpoints.
No declarations, no context managers, no extra indentation.
"""

import json
import os
from dataclasses import dataclass, asdict
from typing import Optional, List, Set, Dict


@dataclass
class Edge:
    """A directed dataflow edge between two regions."""

    source: str
    target: str
    label: Optional[str] = None
    via: Optional[str] = None


class DAG:
    """
    A compile-time DAG describing dataflow between named kernel regions.

    Regions are not declared explicitly — they are created implicitly the
    first time they appear as an endpoint in :meth:`edge`.  At runtime the
    kernel uses the existing ``iket.range_start`` / ``iket.range_end`` API
    with matching region names; this class only records the dependency
    metadata for post-processing (Perfetto trace arrows).

    Parameters
    ----------
    name : str
        Human-readable name for this DAG (e.g. ``"gemm_fp16_2stage"``).
    """

    def __init__(self, name: str):
        self.name = name
        self._edges: List[Edge] = []
        self._regions: Set[str] = set()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def edge(
        self,
        source: str,
        target: str,
        *,
        label: Optional[str] = None,
        via: Optional[str] = None,
    ) -> "DAG":
        """
        Declare a dataflow dependency: *source* region produces data
        consumed by *target* region.

        Parameters
        ----------
        source : str
            Name of the producing region (must match a ``range_start`` name).
        target : str
            Name of the consuming region.
        label : str, optional
            What flows along this edge (e.g. ``"smem_A"``, ``"accumulator"``).
        via : str, optional
            Synchronization mechanism (e.g. ``"mbarrier"``, ``"tcgen05_commit"``,
            ``"barrier"``).

        Returns
        -------
        DAG
            ``self``, for chaining.
        """
        self._regions.add(source)
        self._regions.add(target)
        self._edges.append(Edge(source, target, label, via))
        return self

    @property
    def regions(self) -> List[str]:
        """Sorted list of region names (auto-populated from edges)."""
        return sorted(self._regions)

    @property
    def edges(self) -> List[Edge]:
        """All declared edges."""
        return list(self._edges)

    # ------------------------------------------------------------------
    # Serialization
    # ------------------------------------------------------------------

    def to_dict(self) -> Dict:
        """Return the DAG as a plain dict suitable for ``json.dump``."""
        return {
            "name": self.name,
            "regions": self.regions,
            "edges": [
                {k: v for k, v in asdict(e).items() if v is not None}
                for e in self._edges
            ],
        }

    def to_json(self, indent: int = 2) -> str:
        """Serialize the DAG to a JSON string."""
        return json.dumps(self.to_dict(), indent=indent)

    def save(self, path: Optional[str] = None) -> str:
        """
        Write the DAG JSON to disk.

        Parameters
        ----------
        path : str, optional
            Output file path.  Defaults to
            ``$CUTE_DSL_DUMP_DIR/<kernel_name>.iket_dag.json`` if the env
            var is set, otherwise ``<kernel_name>.iket_dag.json`` in cwd.

        Returns
        -------
        str
            The absolute path of the written file.
        """
        if path is None:
            filename = f"{self.name}.iket_dag.json"
            dump_dir = os.environ.get("CUTE_DSL_DUMP_DIR", "")
            if dump_dir:
                os.makedirs(dump_dir, exist_ok=True)
                path = os.path.join(dump_dir, filename)
            else:
                path = filename

        with open(path, "w") as f:
            f.write(self.to_json())
        return os.path.abspath(path)

    # ------------------------------------------------------------------
    # Dunder
    # ------------------------------------------------------------------

    def __repr__(self) -> str:
        return f"DAG({self.name!r}, regions={self.regions}, edges={len(self._edges)})"
