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


"""Ops for constructing CUDA graphs."""

from typing import Any, Callable, Sequence

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

from cutlass.base_dsl.typing import Int32, Int64

import cutlass._mlir.ir as ir
from cutlass._mlir.dialects import cuda as cuda_dialect
from cutlass._mlir.dialects import cute as _cute_ir

from cutlass.base_dsl import dsl_user_op

from .types import Graph, GraphExec, GraphNode, KernelNodeParams


@dsl_user_op
def create(
    *,
    flags: Int32 | int = 0,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Graph:
    """Creates a graph (``cudaGraphCreate``).

    :param flags: Graph creation flags
    :type flags: Int32 | int
    :return: Newly created graph
    :rtype: Graph
    """
    cuda_result, graph = cuda_dialect.runtime_graph_create(
        Int32(flags).ir_value(loc=loc, ip=ip),
        results=[cuda_dialect.ResultType.get(), Graph._get_mlir_type()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)
    return Graph(graph)


@dsl_user_op
def add_kernel_node(
    graph: Graph,
    node_params: KernelNodeParams,
    dependencies: Sequence[GraphNode] | None = None,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> GraphNode:
    """Creates a kernel execution node and adds it to a graph (``cudaGraphAddKernelNode``).

    :param graph: Graph to which to add the node
    :type graph: Graph
    :param node_params: Parameters for the kernel node
    :type node_params: KernelNodeParams
    :param dependencies: Dependencies of the node
    :type dependencies: Sequence[GraphNode] | None
    :return: Newly created node
    :rtype: GraphNode
    """
    cuda_result, node = cuda_dialect.graph_add_kernel_node(
        graph.value,
        [] if dependencies is None else [dep.value for dep in dependencies],
        node_params.value,
        results=[cuda_dialect.ResultType.get(), GraphNode._get_mlir_type()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)
    return GraphNode(node)


@dsl_user_op
def instantiate(
    graph: Graph,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> GraphExec:
    """Creates an executable graph from a graph (``cudaGraphInstantiate``).

    :param graph: Graph to instantiate
    :type graph: Graph
    :return: Newly created executable graph
    :rtype: GraphExec
    """
    cuda_result, graph_exec = cuda_dialect.graph_instantiate(
        graph.value,
        results=[cuda_dialect.ResultType.get(), GraphExec._get_mlir_type()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)
    return GraphExec(graph_exec)


@dsl_user_op
def launch(
    graph_exec: GraphExec,
    stream: cuda_driver.CUstream | cuda_runtime.cudaStream_t,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Launches an executable graph in a stream (``cudaGraphLaunch``).

    :param graph_exec: Executable graph to launch
    :type graph_exec: GraphExec
    :param stream: Stream in which to launch the graph
    :type stream: cuda_driver.CUstream | cuda_runtime.cudaStream_t
    """
    cuda_result = cuda_dialect.graph_launch(
        graph_exec.value,
        stream,
        results=[cuda_dialect.ResultType.get()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)


@dsl_user_op
def destroy(
    graph: Graph,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Destroys a graph (``cudaGraphDestroy``).

    :param graph: Graph to destroy
    :type graph: Graph
    """
    cuda_result = cuda_dialect.graph_destroy(
        graph.value, results=[cuda_dialect.ResultType.get()], loc=loc, ip=ip
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)


@dsl_user_op
def exec_destroy(
    graph_exec: GraphExec,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Destroys an executable graph (``cudaGraphExecDestroy``).

    :param graph_exec: Executable graph to destroy
    :type graph_exec: GraphExec
    """
    cuda_result = cuda_dialect.graph_exec_destroy(
        graph_exec.value, results=[cuda_dialect.ResultType.get()], loc=loc, ip=ip
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)


@dsl_user_op
def kernel_node_get_params(
    node: GraphNode,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> KernelNodeParams:
    """Returns a kernel node's parameters (``cudaGraphKernelNodeGetParams``).

    :param node: Node to query
    :type node: GraphNode
    :return: Returned parameters
    :rtype: KernelNodeParams
    """
    cuda_result, node_params = cuda_dialect.graph_kernel_node_get_params(
        node.value,
        results=[cuda_dialect.ResultType.get(), KernelNodeParams._get_mlir_type()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)
    return KernelNodeParams(node_params)


@dsl_user_op
def kernel_node_set_params(
    node: GraphNode,
    node_params: KernelNodeParams,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> None:
    """Sets a kernel node's parameters (``cudaGraphKernelNodeSetParams``).

    :param node: Node to modify
    :type node: GraphNode
    :param node_params: Parameters to set
    :type node_params: KernelNodeParams
    """
    cuda_result = cuda_dialect.graph_kernel_node_set_params(
        node.value,
        node_params.value,
        results=[cuda_dialect.ResultType.get()],
        loc=loc,
        ip=ip,
    )
    cuda_dialect.result_assert_success(cuda_result, loc=loc, ip=ip)


@dsl_user_op
def create_kernel_node_params(
    kernel: Callable[..., Any],
    grid: Sequence[Int32 | int],
    block: Sequence[Int32 | int],
    args: Sequence[Any],
    *,
    smem: Int32 | int | None = None,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> KernelNodeParams:
    """Builds ``kernel``'s device function and creates graph node parameters
    (``cudaKernelNodeParams``), which can be used to manually construct a graph node
    (``cudaGraphNode_t``) and graph (``cudaGraph_t``). This operation will not launch the kernel.

    :param kernel: Kernel function to execute
    :type kernel: Callable
    :param grid: Grid dimensions for kernel launch
    :type grid: Sequence[Int32 | int]
    :param block: Block dimensions for kernel launch
    :type block: Sequence[Int32 | int]
    :param args: Kernel arguments, in signature order
    :type args: Sequence[Any]
    :param smem: Shared memory size in bytes; ``None`` infers the kernel's usage as ``.launch()``
        does
    :type smem: Int32 | int | None
    :return: Parameters for the kernel node
    :rtype: KernelNodeParams
    """

    _loc = loc

    def emit(
        kernel_sym: ir.Attribute,
        kernel_operands: list[ir.Value],
        *,
        loc: ir.Location | None = None,
    ) -> KernelNodeParams:
        # smem = None defaults to smem used by kernel, similar to .launch()
        smem_bytes = smem
        if smem_bytes is None:
            smem_bytes = _cute_ir.kernel_smem_size(
                kernel_name=kernel_sym, loc=_loc, ip=ip
            )

        null_ptr = cuda_dialect.cast(
            ir.Type.parse("!ptr.ptr<#ptr.generic_space>"),
            Int64(0).ir_value(loc=_loc, ip=ip),
            loc=_loc,
            ip=ip,
        )
        node_params = cuda_dialect.GraphCreateKernelNodeParamsOp(
            kernel_sym,
            [Int32(d).ir_value(loc=_loc, ip=ip) for d in grid],
            [Int32(d).ir_value(loc=_loc, ip=ip) for d in block],
            Int32(smem_bytes).ir_value(loc=_loc, ip=ip),
            kernel_operands,
            null_ptr,  # extra: unused
            # This is true for any DSL generated kernel
            assume_kernel_attr=ir.Attribute.parse("#cuda.assume_kernel_attr<true>"),
            ip=ip,
            loc=_loc,
        ).result
        return KernelNodeParams(node_params)

    return kernel(*args).launch(grid=grid, block=block, smem=smem, _launch_emitter=emit)


@dsl_user_op
def graph_node_as_i64(
    node: GraphNode,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Int64:
    """Reinterprets a graph node handle as a 64-bit integer, e.g. to store it for the host.

    :param node: Node to reinterpret
    :type node: GraphNode
    :return: The handle's address
    :rtype: Int64
    """
    return Int64(cuda_dialect.cast(Int64.mlir_type, node.value, loc=loc, ip=ip))
