# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
import cuda.bindings.driver as cuda

import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack


def supports_pdl():
    return torch.cuda.get_device_capability()[0] >= 9


"""
This example demonstrates the use of Programmatic Dependent Launch (PDL) using
CuTe DSL.

PDL is a mechanism which allows for overlapping execution of back-to-back kernels
within the same stream.
For example, consider the following two elementwise add operations, where the second
operation's first operand is the result of the first operation. While performing
``w = u + v`` we will load u and v, add them, and then store the result. Once we
have finished loading data, we are no longer utilizing the read bandwidth.
To effectively utilize the read bandwidth, we can start loading ``x``
immediately upon finishing reading. This is what PDL enables us to do.

.. code-block:: bash

w = u + v
y = w + x

To enable PDL, we need to do two things:

1. Insert the ``griddepcontrol.launch_dependents`` and ``griddepcontrol.wait`` instructions in the kernel.
2. Set the PDL launch attribute when launching the kernel.

The ``griddepcontrol.launch_dependents`` and ``griddepcontrol.wait``
instructions enable fine-grained control over kernel execution in PDL.
Once all thread blocks execute the ``griddepcontrol.launch_dependents``
instruction, the dependent kernels can opportunistically be early-launched.
``griddepcontrol.wait`` functions as a synchronization barrier - any warp
executing this instruction will block until the previous kernel finishes
execution. This allows precise control over data dependencies between kernels.

The following diagram shows the overlapping execution of two dependent kernels.
We call the instructions before ``griddepcontrol.wait`` as prologue (``P0``),
which may include barrier initialization and loading of independent data, etc.
We call the instructions after ``griddepcontrol.launch_dependents`` as epilogue
(``P2``), which may include math operations, data stores, etc. PDL enables
these prologue and epilogue phases to execute concurrently across dependent
kernels, improving GPU resource utilization. This is particularly beneficial
when prologue and epilogue are bound by different resources (e.g., memory
bandwidth vs compute throughput).

      # P0: Prologue, P1: Main compute, P2: Epilogue

         P0    P1    P2
  K1: |=====|+++++|-----|

                  <-----> K2 can start early
                         (K1's P2 overlaps with K2's P0)

                     P0        P1    P2
  K2:             |=====|   |+++++|-----|
                          ^
                          |
                          wait for K1 to complete
Time ------------------------------------------------------>

We could run this example with and without PDL:

.. code-block:: bash

    python examples/blackwell/programmatic_dependent_launch.py --benchmark
    python examples/blackwell/programmatic_dependent_launch.py --benchmark --use_pdl

From the benchmark results, you can see some speedups for the PDL version in most cases, benefiting from
the overlapping execution of consecutive kernels. Moreover, you can use nsys to observe the overlapping execution.

.. code-block:: bash

    nsys profile python examples/blackwell/programmatic_dependent_launch.py --benchmark --use_pdl

Note, PDL feature is supported on Hopper and later GPUs.

See [the programming guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#programmatic-dependent-launch-and-synchronization)
and the [PTX documentation](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#parallel-synchronization-and-communication-instructions-griddepcontrol)
for more details.
"""


@cute.kernel
def elementwise_add_kernel(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    cC: cute.Tensor,  # coordinate tensor
    shape: cute.Shape,
    thr_layout: cute.Layout,
    val_layout: cute.Layout,
    use_pdl: cutlass.Constexpr = True,
    is_first_kernel: cutlass.Constexpr = True,
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    blk_coord = ((None, None), bidx)
    blkA = gA[blk_coord]  # (TileM,TileN)
    blkB = gB[blk_coord]  # (TileM,TileN)
    blkC = gC[blk_coord]  # (TileM,TileN)
    blkCrd = cC[blk_coord]  # (TileM, TileN)

    copy_atom_load = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), gA.element_type)
    copy_atom_store = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), gC.element_type)

    tiled_copy_A = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
    tiled_copy_B = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
    tiled_copy_C = cute.make_tiled_copy_tv(copy_atom_store, thr_layout, val_layout)

    thr_copy_A = tiled_copy_A.get_slice(tidx)
    thr_copy_B = tiled_copy_B.get_slice(tidx)
    thr_copy_C = tiled_copy_C.get_slice(tidx)

    thrA = thr_copy_A.partition_S(blkA)
    thrB = thr_copy_B.partition_S(blkB)
    thrC = thr_copy_C.partition_S(blkC)

    frgA = cute.make_fragment_like(thrA)
    frgB = cute.make_fragment_like(thrB)
    frgC = cute.make_fragment_like(thrC)

    thrCrd = thr_copy_C.partition_S(blkCrd)
    frgPred = cute.make_rmem_tensor(thrCrd.shape, cutlass.Boolean)

    for i in range(cute.size(frgPred)):
        val = cute.elem_less(thrCrd[i], shape)
        frgPred[i] = val

    # Note: when not using cuda-graph, the kernel execution may be blocked by the host overhead.
    # In this case we won't see overlapping even when pdl is enabled.
    # In this example, we add a loop (10 times) for all the copy and compute operations in the following code
    # to make kernel running longer and make pdl benefits observable for both cuda-graph enabled and disabled cases.
    if not use_pdl:
        for _ in range(10):
            cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)
            cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)
    else:
        if is_first_kernel:
            for _ in range(10):
                cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)
                cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)
            # Here we add the launch dependents instruction for the first kernel as a hint to the runtime to early-launch
            # the next kernel. If the next kernel becomes concurrent, we will have overlap where the second kernel
            # can start reading x to ensure an E2E speedup. Note the placement of launch dependents has no implication
            # on correctness, only performance.
            cute.arch.griddepcontrol_launch_dependents()
        else:
            # In this example, the second kernel's second operand ``gB`` has no dependencies, its loading can overlap
            # with the computation of ``gC`` from the first kernel.
            for _ in range(10):
                cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)

            # For the second kernel, its first operand ``gA`` is dependent on the previous kernel, we must call
            # griddepcontrol.wait to assure correctness. This instruction will block until the prior kernels finishes
            # and its memory operations are visible. Since gA is written by the prior kernel, this will block until gA
            # is visible to our kernel. Without it, we would have undefined behavior due to a race condition.
            cute.arch.griddepcontrol_wait()

            for _ in range(10):
                cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)

    for _ in range(10):
        result = frgA.load() + frgB.load()
        frgC.store(result)
        cute.copy(copy_atom_store, frgC, thrC, pred=frgPred)


@cute.jit
def elementwise_add(
    mA,
    mB,
    mC,
    stream: cuda.CUstream,
    use_pdl: cutlass.Constexpr = True,
    is_first_kernel: cutlass.Constexpr = True,
):
    dtype = mA.element_type
    # copy_bits for a thread is 128 bits, and we use 128 // dtype.width to get the vector size
    vector_size = 128 // dtype.width

    thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
    val_layout = cute.make_ordered_layout((4, vector_size), order=(1, 0))
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

    gA = cute.zipped_divide(mA, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
    gB = cute.zipped_divide(mB, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
    gC = cute.zipped_divide(mC, tiler_mn)  # ((TileM,TileN),(RestM,RestN))

    idC = cute.make_identity_tensor(mC.shape)
    cC = cute.zipped_divide(idC, tiler=tiler_mn)

    elementwise_add_kernel(
        gA, gB, gC, cC, mC.shape, thr_layout, val_layout, use_pdl, is_first_kernel
    ).launch(
        grid=[cute.size(gC, mode=[1]), 1, 1],
        block=[cute.size(tv_layout, mode=[0]), 1, 1],
        # set cluster to enable cuLaunchKernelEx API for additional launch attributes setting
        cluster=(1, 1, 1),
        stream=stream,
        # Currently, pdl launch attribute is set in compile phase,
        # so we need to recompile the function if we change the value of use_pdl for multiple runs.
        use_pdl=use_pdl,
    )


def run_pdl_example(
    M,
    N,
    skip_ref_check=False,
    benchmark=True,
    warmup_iterations=5,
    iterations=10,
    use_pdl=True,
):
    if not torch.cuda.is_available():
        raise RuntimeError("Blackwell/Hopper GPU is required to run this example!")

    print("\nRunning Elementwise Add test with:")
    print(f"Tensor dimensions: [{M}, {N}]")
    print(f"Use PDL: {use_pdl}")

    u = torch.randn(M, N, dtype=torch.float32, device="cuda")
    v = torch.randn(M, N, dtype=torch.float32, device="cuda")
    w = torch.randn(M, N, dtype=torch.float32, device="cuda")
    x = torch.randn(M, N, dtype=torch.float32, device="cuda")
    y = torch.empty(M, N, dtype=torch.float32, device="cuda")

    u_tensor = from_dlpack(u).mark_layout_dynamic()
    v_tensor = from_dlpack(v).mark_layout_dynamic()
    w_tensor = from_dlpack(w).mark_layout_dynamic()
    x_tensor = from_dlpack(x).mark_layout_dynamic()
    y_tensor = from_dlpack(y).mark_layout_dynamic()

    stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(stream.cuda_stream)
    # Since use_pdl and is_first_kernel are cutlass.Constexpr, we need to compile for
    # the first and second kernel separately.
    compiled_func_first_kernel = cute.compile(
        elementwise_add,
        u_tensor,
        v_tensor,
        w_tensor,
        current_stream,
        use_pdl,
        is_first_kernel=True,
    )
    compiled_func_second_kernel = cute.compile(
        elementwise_add,
        w_tensor,
        x_tensor,
        y_tensor,
        current_stream,
        use_pdl,
        is_first_kernel=False,
    )

    # launch and run the two consecutive kernels in a same stream.
    # Here, we simply use default stream.
    def run_func(current_stream, u_tensor, v_tensor, w_tensor, x_tensor, y_tensor):
        # Run first operation: w_tensor = u_tensor + v_tensor
        compiled_func_first_kernel(
            u_tensor,
            v_tensor,
            w_tensor,
            current_stream,
        )
        # Run second operation: y_tensor = w_tensor + x_tensor
        # its first operand ``w_tensor`` is the result of the first operation,
        # they use the same memory space.
        compiled_func_second_kernel(
            w_tensor,
            x_tensor,
            y_tensor,
            current_stream,
        )

    if not skip_ref_check:
        run_func(current_stream, u_tensor, v_tensor, w_tensor, x_tensor, y_tensor)
        print("Verifying results...")
        torch.testing.assert_close(u.cpu() + v.cpu() + x.cpu(), y.cpu())
        print("Results verified successfully!")

    if not benchmark:
        return

    def generate_kernel_arguments():
        u = torch.randn(M, N, dtype=torch.float32, device="cuda")
        v = torch.randn(M, N, dtype=torch.float32, device="cuda")
        w = torch.randn(M, N, dtype=torch.float32, device="cuda")
        x = torch.randn(M, N, dtype=torch.float32, device="cuda")
        y = torch.empty(M, N, dtype=torch.float32, device="cuda")

        u_tensor = from_dlpack(u).mark_layout_dynamic()
        v_tensor = from_dlpack(v).mark_layout_dynamic()
        w_tensor = from_dlpack(w).mark_layout_dynamic()
        x_tensor = from_dlpack(x).mark_layout_dynamic()
        y_tensor = from_dlpack(y).mark_layout_dynamic()
        return testing.JitArguments(
            current_stream, u_tensor, v_tensor, w_tensor, x_tensor, y_tensor
        )

    avg_time_us = testing.benchmark(
        run_func,
        workspace_generator=generate_kernel_arguments,
        workspace_count=10,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        stream=current_stream,
    )
    print(f"Execution time: {avg_time_us:.4f} us")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="example of Programmatic Dependent Launch (PDL) using CuTe DSL"
    )
    parser.add_argument("--M", default=512, type=int)
    parser.add_argument("--N", default=512, type=int)
    parser.add_argument("--warmup_iterations", default=3, type=int)
    parser.add_argument("--iterations", default=10, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--use_pdl", action="store_true")

    args = parser.parse_args()
    if supports_pdl():
        run_pdl_example(
            args.M,
            args.N,
            skip_ref_check=args.skip_ref_check,
            benchmark=args.benchmark,
            warmup_iterations=args.warmup_iterations,
            iterations=args.iterations,
            use_pdl=args.use_pdl,
        )
        print("\nPASS")
    else:
        print(
            "PDL is not supported on this device, it requires Hopper or newer generations"
        )
