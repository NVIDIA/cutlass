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

"""Manual CUDA graph construction and launch with CuTe DSL.

This example demonstrates building CUDA graphs manually (as opposed to stream-capturing) in CuTeDSL.
It launches a producer-consumer pair of elementwise kernels, both in a stream and using graphs.

It also demonstrates Ahead-Of-Time (AOT) compilation both through raw ABI and TVM-FFI.

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/dsl_tutorials/cuda_graph.py --benchmark
    python examples/CuTeDSL/dsl_tutorials/cuda_graph.py --aot raw
    python examples/CuTeDSL/dsl_tutorials/cuda_graph.py --aot tvm-ffi
"""

import argparse
import functools
import operator
import os
import subprocess
import tempfile

import torch
import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

import cutlass
import cutlass.cute as cute
import cutlass.experimental.cuda as cuda
from cutlass import testing
from cutlass.cute.runtime import (
    from_dlpack,
    make_fake_compact_tensor,
    make_fake_stream,
    make_ptr,
)


@cute.kernel
def elementwise_kernel(
    op: cutlass.Constexpr,
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    cC: cute.Tensor,
    shape: cute.Shape,
    thr_layout: cute.Layout,
    val_layout: cute.Layout,
):
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

    cute.copy(copy_atom, thrA, frgA, pred=frgPred)
    cute.copy(copy_atom, thrB, frgB, pred=frgPred)
    frgC.store(op(frgA.load(), frgB.load()))
    cute.copy(copy_atom, frgC, thrC, pred=frgPred)


@cute.jit
def stream_launch_or_add_to_graph(
    kernel,
    grid,
    block,
    args,
    use_graph,
    graph,
    dependency,
    has_dependency,
    stream,
    ret_node,
):
    if use_graph:
        params = cuda.graph.create_kernel_node_params(kernel, grid, block, args)
        if has_dependency:
            node = cuda.graph.add_kernel_node(graph, params, [dependency])
            ret_node.store(cuda.graph.graph_node_as_i64(node))
        else:
            node = cuda.graph.add_kernel_node(graph, params)
            ret_node.store(cuda.graph.graph_node_as_i64(node))
    else:
        kernel(*args).launch(grid=grid, block=block, stream=stream)


@cute.jit
def elementwise(
    op: cutlass.Constexpr,
    a,
    b,
    c,
    use_graph,
    graph,
    dependency,
    has_dependency,
    stream,
    ret_node,
):
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
    stream_launch_or_add_to_graph(
        elementwise_kernel,
        [cute.size(gC, mode=[1]), 1, 1],
        [cute.size(tv_layout, mode=[0]), 1, 1],
        (op, gA, gB, gC, cC, c.shape, thr_layout, val_layout),
        use_graph,
        graph,
        dependency,
        has_dependency,
        stream,
        ret_node,
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


def main(
    M,
    N,
    aot=None,
    export_dir=None,
    benchmark=False,
    warmup_iterations=5,
    iterations=100,
):
    assert torch.cuda.is_available()
    torch.cuda.init()

    tvm_ffi = aot == "tvm-ffi"
    torch_stream = torch.cuda.current_stream()
    current_stream = cuda_driver.CUstream(torch_stream.cuda_stream)
    graph = cuda_runtime_check(cuda_runtime.cudaGraphCreate, 0)

    # c0 = a0 + b0, then c1 = a1 * b1 with a1 = c0
    a0, b0, b1 = (
        torch.randn(M, N, dtype=torch.float32, device="cuda") for _ in range(3)
    )
    c0, c1 = (torch.zeros(M, N, dtype=torch.float32, device="cuda") for _ in range(2))
    c1_ref = (a0 + b0) * b1
    # Host slots the jit functions write the created graph node handles into
    graph_node_handles = torch.zeros(2, dtype=torch.int64)

    # TVM-FFI takes torch tensors and integer handles; the raw ABI takes CuTe tensors
    # and cuda-python handles.
    a0_arg, b0_arg, b1_arg, c0_arg, c1_arg = [
        t if tvm_ffi else from_dlpack(t, assumed_align=16).mark_layout_dynamic()
        for t in (a0, b0, b1, c0, c1)
    ]
    graph_arg = int(graph) if tvm_ffi else graph
    null_node = 0 if tvm_ffi else cuda_runtime.cudaGraphNode_t(0)
    stream_arg = int(current_stream) if tvm_ffi else current_stream
    add_node_ptr, mul_node_ptr = [
        addr if tvm_ffi else make_ptr(cutlass.Int64, addr)
        for addr in (graph_node_handles[0].data_ptr(), graph_node_handles[1].data_ptr())
    ]

    print()
    print("============== 1. Compile ==============")
    print()
    if aot is None:
        print("JIT: compiling elementwise_add and elementwise_mul in-process")
        add_fn = cute.compile(
            elementwise,
            operator.add,
            a0_arg,
            b0_arg,
            c0_arg,
            use_graph=cutlass.Boolean(False),
            graph=graph_arg,
            dependency=null_node,
            has_dependency=cutlass.Boolean(False),
            stream=current_stream,
            ret_node=make_ptr(cutlass.Int64, 0),
        )
        mul_fn = cute.compile(
            elementwise,
            operator.mul,
            c0_arg,
            b1_arg,
            c1_arg,
            use_graph=cutlass.Boolean(False),
            graph=graph_arg,
            dependency=null_node,
            has_dependency=cutlass.Boolean(False),
            stream=current_stream,
            ret_node=make_ptr(cutlass.Int64, 0),
        )
    else:
        fake_a, fake_b, fake_c = (
            make_fake_compact_tensor(
                cutlass.Float32,
                (cute.sym_int(), cute.sym_int()),
                stride_order=(1, 0),
                assumed_align=16,
            )
            for _ in range(3)
        )
        options = "--enable-tvm-ffi" if tvm_ffi else None
        add_compiled = cute.compile(
            elementwise,
            operator.add,
            fake_a,
            fake_b,
            fake_c,
            use_graph=cute.sym_bool(),
            graph=cuda.graph.make_fake_graph(),
            dependency=cuda.graph.make_fake_graph_node(),
            has_dependency=cute.sym_bool(),
            stream=make_fake_stream(),
            ret_node=make_ptr(cutlass.Int64, 0),
            options=options,
        )
        mul_compiled = cute.compile(
            elementwise,
            operator.mul,
            fake_a,
            fake_b,
            fake_c,
            use_graph=cute.sym_bool(),
            graph=cuda.graph.make_fake_graph(),
            dependency=cuda.graph.make_fake_graph_node(),
            has_dependency=cute.sym_bool(),
            stream=make_fake_stream(),
            ret_node=make_ptr(cutlass.Int64, 0),
            options=options,
        )

        export_dir = export_dir or tempfile.mkdtemp()
        os.makedirs(export_dir, exist_ok=True)
        print(f"AOT ({aot}): exporting to {export_dir}")

        objects = []
        for name, compiled in (
            ("elementwise_add", add_compiled),
            ("elementwise_mul", mul_compiled),
        ):
            if tvm_ffi:
                compiled.export_to_c(
                    os.path.join(export_dir, f"{name}.o"), function_name=name
                )
            else:
                # Stores the header in export_dir/name.h, builds into export_dir/name.o
                compiled.export_to_c(file_path=export_dir, file_name=name)
            objects.append(os.path.join(export_dir, f"{name}.o"))
            print(f"  Built {name} into {objects[-1]}" + ("" if tvm_ffi else " (+ .h)"))

        lib_path = os.path.join(export_dir, "libcuda_graph.so")
        subprocess.run(
            [
                os.environ.get("CC", "cc"),
                "-shared",
                "-o",
                lib_path,
                *objects,
                *cute.runtime.find_runtime_libraries(enable_tvm_ffi=tvm_ffi),
            ],
            check=True,
        )
        print(f"  Linked into: {lib_path}")
        module = cutlass.runtime.load_module(lib_path, enable_tvm_ffi=tvm_ffi)
        add_fn_, mul_fn_ = module.elementwise_add, module.elementwise_mul

        def _aot_fn_wrapper(
            a, b, c, use_graph, graph, dependency, has_dependency, stream, ret_node, fn
        ):
            return fn(
                a, b, c, use_graph, graph, dependency, has_dependency, stream, ret_node
            )

        add_fn = functools.partial(_aot_fn_wrapper, fn=add_fn_)
        mul_fn = functools.partial(_aot_fn_wrapper, fn=mul_fn_)

    print()
    print("============== 2. Verification ==============")
    print()
    print(f"{M}x{N} fp32, exact match against torch")

    # 1. Stream launch
    def launch_stream():
        add_fn(
            a=a0_arg,
            b=b0_arg,
            c=c0_arg,
            use_graph=False,
            # only relevant when use_graph = True
            graph=graph_arg,
            dependency=null_node,
            has_dependency=False,
            #
            stream=stream_arg,
            ret_node=add_node_ptr,
        )
        mul_fn(
            a=c0_arg,
            b=b1_arg,
            c=c1_arg,
            use_graph=False,
            # only relevant when use_graph = True
            graph=graph_arg,
            dependency=null_node,
            has_dependency=False,
            #
            stream=stream_arg,
            ret_node=mul_node_ptr,
        )

    launch_stream()
    cutlass.cuda.stream_sync(current_stream)
    torch.testing.assert_close(c1, c1_ref, atol=0, rtol=0)
    assert (graph_node_handles == 0).all()
    print("Stream launch: PASS")

    # 2. Graph launch
    c0.zero_()
    c1.zero_()

    add_fn(
        a=a0_arg,
        b=b0_arg,
        c=c0_arg,
        use_graph=True,
        graph=graph_arg,
        dependency=null_node,
        has_dependency=False,
        stream=stream_arg,
        ret_node=add_node_ptr,
    )
    assert int(graph_node_handles[0]) != 0
    add_node = cuda_runtime.cudaGraphNode_t(int(graph_node_handles[0]))

    mul_fn(
        a=c0_arg,
        b=b1_arg,
        c=c1_arg,
        use_graph=True,
        graph=graph_arg,
        dependency=int(add_node) if tvm_ffi else add_node,
        has_dependency=True,
        stream=stream_arg,
        ret_node=mul_node_ptr,
    )
    assert int(graph_node_handles[1]) != 0
    graph_exec = cuda_runtime_check(cuda_runtime.cudaGraphInstantiate, graph, 0)

    def launch_graph():
        cuda_runtime_check(cuda_runtime.cudaGraphLaunch, graph_exec, current_stream)

    launch_graph()
    cutlass.cuda.stream_sync(current_stream)
    torch.testing.assert_close(c1, c1_ref, atol=0, rtol=0)
    print("Graph launch: PASS")

    # 3. Benchmark
    if benchmark:
        print()
        print("============== 3. Benchmark ==============")
        print()
        for name, fn, includes_graph_exec in (
            ("Stream launch", launch_stream, False),
            ("Graph launch", launch_graph, True),
        ):
            time_us = testing.benchmark(
                fn,
                kernel_arguments=testing.JitArguments(),
                warmup_iterations=warmup_iterations,
                iterations=iterations,
                stream=current_stream,
                includes_graph_exec=includes_graph_exec,
            )
            print(f"{name}: {time_us:.3f} us")

    cuda_runtime_check(cuda_runtime.cudaGraphExecDestroy, graph_exec)
    cuda_runtime_check(cuda_runtime.cudaGraphDestroy, graph)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Manual CUDA graph construction in CuTeDSL"
    )
    parser.add_argument("-m", default=256, type=int)
    parser.add_argument("-n", default=256, type=int)
    parser.add_argument(
        "-a",
        "--aot",
        choices=["raw", "tvm-ffi"],
        default=None,
        help="compile ahead of time and call the exported shared library; default is JIT",
    )
    parser.add_argument("--export-dir", default=None)
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--warmup-iterations", default=5, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    args = parser.parse_args()

    main(
        args.m,
        args.n,
        args.aot,
        args.export_dir,
        args.benchmark,
        args.warmup_iterations,
        args.iterations,
    )

    print()
    print("PASS")
    print()
    print()
