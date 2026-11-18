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

"""CUDA graph APIs, types, adapters."""

from . import adapters  # noqa: F401
from .types import Graph, GraphExec, GraphNode, KernelNodeParams
from .ops import (
    create,
    add_kernel_node,
    instantiate,
    launch,
    destroy,
    exec_destroy,
    create_kernel_node_params,
    kernel_node_get_params,
    kernel_node_set_params,
    graph_node_as_i64,
)
from .runtime import (
    make_fake_graph,
    make_fake_graph_node,
)


__all__ = [
    # Graph handle types
    "Graph",
    "GraphExec",
    "GraphNode",
    "KernelNodeParams",
    # Graph construction and launch
    "create",
    "add_kernel_node",
    "instantiate",
    "launch",
    "destroy",
    "exec_destroy",
    # Kernel node parameters
    "create_kernel_node_params",
    "kernel_node_get_params",
    "kernel_node_set_params",
    "graph_node_as_i64",
    # Compile-time placeholders (AOT)
    "make_fake_graph",
    "make_fake_graph_node",
]
