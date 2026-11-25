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


"""CUDA graph handle types."""

from dataclasses import dataclass, field

import cutlass._mlir.ir as ir
from cutlass._mlir.dialects import cuda as cuda_dialect


@dataclass(frozen=True, eq=False)
class Graph:
    """Handle to a CUDA graph. Wraps an MLIR ``!cuda.graph`` value."""

    value: ir.Value = field(repr=False)

    @staticmethod
    def _get_mlir_type() -> ir.Type:
        """Return the MLIR dialect type for a CUDA graph.

        :return: MLIR type for a CUDA graph (``!cuda.graph``).
        :rtype: ir.Type
        """
        return cuda_dialect.GraphType.get()


@dataclass(frozen=True, eq=False)
class GraphExec:
    """Handle to an instantiated (executable) CUDA graph. Wraps an MLIR ``!cuda.graph_exec``
    value."""

    value: ir.Value = field(repr=False)

    @staticmethod
    def _get_mlir_type() -> ir.Type:
        """Return the MLIR dialect type for an executable CUDA graph.

        :return: MLIR type for an executable CUDA graph (``!cuda.graph_exec``).
        :rtype: ir.Type
        """
        return cuda_dialect.GraphExecType.get()


@dataclass(frozen=True, eq=False)
class GraphNode:
    """Handle to a node of a CUDA graph. Wraps an MLIR ``!cuda.graph_node`` value."""

    value: ir.Value = field(repr=False)

    @staticmethod
    def _get_mlir_type() -> ir.Type:
        """Return the MLIR dialect type for a CUDA graph node.

        :return: MLIR type for a CUDA graph node (``!cuda.graph_node``).
        :rtype: ir.Type
        """
        return cuda_dialect.GraphNodeType.get()


@dataclass(frozen=True, eq=False)
class KernelNodeParams:
    """Parameters of a kernel graph node (``cudaKernelNodeParams``). Wraps an MLIR
    ``!cuda.runtime.kernel_node_params`` value."""

    value: ir.Value = field(repr=False)

    @staticmethod
    def _get_mlir_type() -> ir.Type:
        """Return the MLIR dialect type for kernel node parameters.

        :return: MLIR type for kernel node parameters (``!cuda.runtime.kernel_node_params``).
        :rtype: ir.Type
        """
        return cuda_dialect.RuntimeKernelNodeParamsType.get()
