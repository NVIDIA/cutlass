# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from cutlass._mlir import ir

from .types import Graph, GraphNode


class _FakeGraph:
    """A fake cuda graph that can be used as a placeholder in compilation."""

    def __init__(self) -> None:
        pass

    def __str__(self) -> str:
        return "FakeGraph"

    def __repr__(self) -> str:
        return self.__str__()

    def __new_from_mlir_values__(self, values: list[object]) -> Graph:
        assert len(values) == 1
        return Graph(values[0])

    def __c_pointers__(self) -> list[int]:
        return [0]

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [Graph._get_mlir_type()]


class _FakeGraphNode:
    """A fake cuda graph node that can be used as a placeholder in compilation."""

    def __init__(self) -> None:
        pass

    def __str__(self) -> str:
        return "FakeGraphNode"

    def __repr__(self) -> str:
        return self.__str__()

    def __new_from_mlir_values__(self, values: list[object]) -> GraphNode:
        assert len(values) == 1
        return GraphNode(values[0])

    def __c_pointers__(self) -> list[int]:
        return [0]

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [GraphNode._get_mlir_type()]


def make_fake_graph() -> _FakeGraph:
    """Create a fake cuda graph that can be used as a placeholder in compilation."""
    return _FakeGraph()


def make_fake_graph_node() -> _FakeGraphNode:
    """Create a fake cuda graph node that can be used as a placeholder in compilation."""
    return _FakeGraphNode()
