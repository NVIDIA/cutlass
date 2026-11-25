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


"""JIT argument adapters for cuda-python graph handles."""

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

from cutlass._mlir import ir
from cutlass.base_dsl.runtime.cuda_handle_adapter import CudaHandleAdapter
from cutlass.cutlass_dsl import JitArgAdapterRegistry

from .types import Graph, GraphExec, GraphNode


class _GraphAdapter(CudaHandleAdapter):
    """Convert a CUDA graph handle to a :class:`Graph` for JIT arg generation."""

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [Graph._get_mlir_type()]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> Graph:
        assert len(values) == 1
        return Graph(values[0])


class _GraphExecAdapter(CudaHandleAdapter):
    """Convert a CUDA executable graph handle to a :class:`GraphExec` for JIT arg generation."""

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [GraphExec._get_mlir_type()]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> GraphExec:
        assert len(values) == 1
        return GraphExec(values[0])


class _GraphNodeAdapter(CudaHandleAdapter):
    """Convert a CUDA graph node handle to a :class:`GraphNode` for JIT arg generation."""

    def __get_mlir_types__(self) -> list[ir.Type]:
        return [GraphNode._get_mlir_type()]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> GraphNode:
        assert len(values) == 1
        return GraphNode(values[0])


for _handle_type, _adapter in (
    (cuda_runtime.cudaGraph_t, _GraphAdapter),
    (cuda_driver.CUgraph, _GraphAdapter),
    (cuda_runtime.cudaGraphExec_t, _GraphExecAdapter),
    (cuda_driver.CUgraphExec, _GraphExecAdapter),
    (cuda_runtime.cudaGraphNode_t, _GraphNodeAdapter),
    (cuda_driver.CUgraphNode, _GraphNodeAdapter),
):
    JitArgAdapterRegistry.register_jit_arg_adapter(_handle_type)(_adapter)
