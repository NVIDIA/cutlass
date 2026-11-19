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

import argparse
import operator

import torch
import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

import cutlass
import cutlass.cute as cute
import cutlass.experimental.cuda as cuda
from cutlass import testing
from cutlass.cute.runtime import from_dlpack, make_ptr


@cute.kernel
def elementwise_kernel(
    op: cutlass.Constexpr,
    is_producer: cutlass.Constexpr,
    is_consumer: cutlass.Constexpr,
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    cC: cute.Tensor,
    shape: cute.Shape,
    thr_layout: cute.Layout,
    val_layout: cute.Layout,
):
    if is_producer:
        cute.arch.griddepcontrol_launch_dependents()

    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    blk_coord = ((None, None), bidx)

    copy_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), gA.element_type)
    thr_copy = cute.make_tiled_copy_tv(copy_atom, thr_layout, val_layout).get_slice(
        tidx
    )
    thrA = thr_copy.partition_S(gA[blk_coord])
    thrB = thr_copy.partition_S(gB[blk_coord])
    thrC = thr_copy.partition_S(gC[blk_coord])
    thrCrd = thr_copy.partition_S(cC[blk_coord])

    frgA = cute.make_fragment_like(thrA)
    frgB = cute.make_fragment_like(thrB)
    frgC = cute.make_fragment_like(thrC)
    frgPred = cute.make_rmem_tensor(thrCrd.shape, cutlass.Boolean)
    for i in range(cute.size(frgPred)):
        frgPred[i] = cute.elem_less(thrCrd[i], shape)

    if is_consumer:
        cute.arch.griddepcontrol_wait()

    cute.copy(copy_atom, thrA, frgA, pred=frgPred)
    cute.copy(copy_atom, thrB, frgB, pred=frgPred)
    frgC.store(op(frgA.load(), frgB.load()))
    cute.copy(copy_atom, frgC, thrC, pred=frgPred)


@cute.jit
def elementwise_launch_config(a, b, c):
    # 128 threads, 128-bit vectors along the contiguous mode
    thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
    val_layout = cute.make_ordered_layout(
        (4, 128 // a.element_type.width), order=(1, 0)
    )
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)
    gA = cute.zipped_divide(a, tiler_mn)
    gB = cute.zipped_divide(b, tiler_mn)
    gC = cute.zipped_divide(c, tiler_mn)
    cC = cute.zipped_divide(cute.make_identity_tensor(c.shape), tiler=tiler_mn)
    grid = [cute.size(gC, mode=[1]), 1, 1]
    block = [cute.size(tv_layout, mode=[0]), 1, 1]
    return grid, block, (gA, gB, gC, cC, c.shape, thr_layout, val_layout)


@cute.jit
def launch_stream(a0, b0, c0, b1, c1, stream: cuda_driver.CUstream):
    # c0 = a0 + b0: first kernel, producer only
    grid, block, args = elementwise_launch_config(a0, b0, c0)
    elementwise_kernel(operator.add, True, False, *args).launch(
        grid=grid, block=block, stream=stream
    )
    # c1 = c0 * b1: last kernel, consumer only, launched with the PDL attribute
    grid, block, args = elementwise_launch_config(c0, b1, c1)
    elementwise_kernel(operator.mul, False, True, *args).launch(
        grid=grid, block=block, stream=stream, use_pdl=True
    )


@cute.jit
def build_graph(a0, b0, c0, b1, c1, graph, add_node_ptr, mul_node_ptr):
    # Nodes are added without dependencies; the host adds the programmatic edge add -> mul.
    grid, block, args = elementwise_launch_config(a0, b0, c0)
    params = cuda.graph.create_kernel_node_params(
        elementwise_kernel, grid, block, (operator.add, True, False, *args)
    )
    add_node_ptr.store(
        cuda.graph.graph_node_as_i64(cuda.graph.add_kernel_node(graph, params))
    )
    grid, block, args = elementwise_launch_config(c0, b1, c1)
    params = cuda.graph.create_kernel_node_params(
        elementwise_kernel, grid, block, (operator.mul, False, True, *args)
    )
    mul_node_ptr.store(
        cuda.graph.graph_node_as_i64(cuda.graph.add_kernel_node(graph, params))
    )


def cuda_runtime_check(fn, *args, **kwargs):
    """Calls a cuda-python runtime API, raises on error, returns its non-error outputs."""
    err, *outputs = fn(*args, **kwargs)
    if err != cuda_runtime.cudaError_t.cudaSuccess:
        message = cuda_runtime.cudaGetErrorString(err)[1].decode()
        raise RuntimeError(f"{fn.__name__} failed: {message}")
    if not outputs:
        return None
    return outputs[0] if len(outputs) == 1 else tuple(outputs)


def add_dependency_rt(
    graph: cuda_runtime.cudaGraph_t,
    from_node: cuda_runtime.cudaGraphNode_t,
    to_node: cuda_runtime.cudaGraphNode_t,
    pdl: bool = False,
) -> None:
    """Adds the edge from_node -> to_node; with pdl, the edge is programmatic (PDL)."""
    edge = cuda_runtime.cudaGraphEdgeData()
    if pdl:
        edge.type = (
            cuda_runtime.cudaGraphDependencyType.cudaGraphDependencyTypeProgrammatic
        )
        edge.from_port = cuda_runtime.cudaGraphKernelNodePortProgrammatic

    # CUDA 13.0 renamed cudaGraphAddDependencies_v2 (12.3+, takes edgeData) to
    # cudaGraphAddDependencies; the 12.x base name has no edgeData parameter.
    add_dependencies = getattr(
        cuda_runtime,
        "cudaGraphAddDependencies_v2",
        cuda_runtime.cudaGraphAddDependencies,
    )
    cuda_runtime_check(add_dependencies, graph, [from_node], [to_node], [edge], 1)


def main(M, N, benchmark=False, warmup_iterations=5, iterations=100):
    assert torch.cuda.is_available()
    torch.cuda.init()
    torch.cuda.synchronize()

    current_stream = cutlass.cuda.stream_create()
    torch.cuda.set_stream(torch.cuda.ExternalStream(int(current_stream)))

    graph = cuda_runtime_check(cuda_runtime.cudaGraphCreate, 0)

    # c0 = a0 + b0, then c1 = a1 * b1 with a1 = c0
    a0, b0, b1 = (
        torch.randn(M, N, dtype=torch.float32, device="cuda") for _ in range(3)
    )
    c0, c1 = (torch.zeros(M, N, dtype=torch.float32, device="cuda") for _ in range(2))
    c1_ref = (a0 + b0) * b1
    # Host slots the jit function writes the created graph node handles into
    graph_node_handles = torch.zeros(2, dtype=torch.int64)

    a0_arg, b0_arg, b1_arg, c0_arg, c1_arg = [
        from_dlpack(t, assumed_align=16).mark_layout_dynamic()
        for t in (a0, b0, b1, c0, c1)
    ]
    add_node_ptr, mul_node_ptr = [
        make_ptr(cutlass.Int64, addr)
        for addr in (graph_node_handles[0].data_ptr(), graph_node_handles[1].data_ptr())
    ]
    tensor_args = (a0_arg, b0_arg, c0_arg, b1_arg, c1_arg)

    print()
    print("============== 1. Compile ==============")
    print()
    launch_stream_compiled = cute.compile(launch_stream, *tensor_args, current_stream)
    print("Compiled launch_stream")
    build_graph_compiled = cute.compile(
        build_graph, *tensor_args, graph, add_node_ptr, mul_node_ptr
    )
    print("Compiled build_graph")

    print()
    print("============== 2. Verification ==============")
    print()
    print(f"{M}x{N} fp32, exact match against torch")

    # 1. Stream launch
    c0.zero_()
    c1.zero_()
    launch_stream_compiled(*tensor_args, current_stream)
    cutlass.cuda.stream_sync(current_stream)
    torch.testing.assert_close(c1, c1_ref, atol=0, rtol=0)
    print("Stream launch: PASS")

    # 2. Stream-captured graph launch
    c0.zero_()
    c1.zero_()
    cuda_runtime_check(
        cuda_runtime.cudaStreamBeginCapture,
        current_stream,
        cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal,
    )
    launch_stream_compiled(*tensor_args, current_stream)
    captured_graph = cuda_runtime_check(
        cuda_runtime.cudaStreamEndCapture, current_stream
    )
    captured_graph_exec = cuda_runtime_check(
        cuda_runtime.cudaGraphInstantiate, captured_graph, 0
    )

    def launch_captured_graph():
        cuda_runtime_check(
            cuda_runtime.cudaGraphLaunch, captured_graph_exec, current_stream
        )

    launch_captured_graph()
    cutlass.cuda.stream_sync(current_stream)
    torch.testing.assert_close(c1, c1_ref, atol=0, rtol=0)
    print("Stream-captured graph launch: PASS")

    # 3. Manual graph launch
    c0.zero_()
    c1.zero_()
    build_graph_compiled(*tensor_args, graph, add_node_ptr, mul_node_ptr)
    assert (graph_node_handles != 0).all()
    add_node = cuda_runtime.cudaGraphNode_t(int(graph_node_handles[0]))
    mul_node = cuda_runtime.cudaGraphNode_t(int(graph_node_handles[1]))

    add_dependency_rt(graph, add_node, mul_node, pdl=True)

    graph_exec = cuda_runtime_check(cuda_runtime.cudaGraphInstantiate, graph, 0)

    def launch_graph():
        cuda_runtime_check(cuda_runtime.cudaGraphLaunch, graph_exec, current_stream)

    launch_graph()
    cutlass.cuda.stream_sync(current_stream)
    torch.testing.assert_close(c1, c1_ref, atol=0, rtol=0)
    print("Manual graph launch: PASS")

    # 4. Benchmark
    if benchmark:
        print()
        print("============== 3. Benchmark ==============")
        print()
        for name, fn, kernel_arguments, includes_graph_exec in (
            (
                "Stream launch",
                launch_stream_compiled,
                testing.JitArguments(*tensor_args, current_stream),
                False,
            ),
            (
                "Stream-captured graph launch",
                launch_captured_graph,
                testing.JitArguments(),
                True,
            ),
            ("Manual graph launch", launch_graph, testing.JitArguments(), True),
        ):
            time_us = testing.benchmark(
                fn,
                kernel_arguments=kernel_arguments,
                warmup_iterations=warmup_iterations,
                iterations=iterations,
                stream=current_stream,
                includes_graph_exec=includes_graph_exec,
            )
            print(f"{name}: {time_us:.3f} us")

    cuda_runtime_check(cuda_runtime.cudaGraphExecDestroy, graph_exec)
    cuda_runtime_check(cuda_runtime.cudaGraphDestroy, graph)
    cuda_runtime_check(cuda_runtime.cudaGraphExecDestroy, captured_graph_exec)
    cuda_runtime_check(cuda_runtime.cudaGraphDestroy, captured_graph)
    torch.cuda.set_stream(torch.cuda.default_stream())
    cutlass.cuda.stream_destroy(current_stream)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Manual CUDA graph construction with PDL in CuTeDSL"
    )
    parser.add_argument("-m", "--m", default=256, type=int)
    parser.add_argument("-n", "--n", default=256, type=int)
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--warmup-iterations", default=5, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    args = parser.parse_args()

    main(args.m, args.n, args.benchmark, args.warmup_iterations, args.iterations)

    print()
    print("PASS")
    print()
    print()
