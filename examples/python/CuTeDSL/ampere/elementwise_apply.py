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
import operator
import torch
from typing import Type
import time

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack

"""
An Elementwise Apply Example using CuTe DSL.

This example kernel demonstrates the meta-programming capability of the CuTe DSL by allowing
customization of elementwise operations through lambda functions. The kernel copies data from
global memory to register memory (rmem), applies a user-defined operation to the elements,
and stores the result back to global memory.

Primary goals of this example:
1. Demonstrate meta-programming capability by passing lambda functions to customize elementwise operations
2. Show how to apply different operations (add, multiply, etc.) using the same kernel structure
3. Illustrate how to parameterize CUDA kernels with operation types at compile time

To run this example:

.. code-block:: bash

    # Run with addition operation
    python examples/ampere/elementwise_apply.py --M 1024 --N 512 --op add

    # Run with multiplication operation
    python examples/ampere/elementwise_apply.py --M 1024 --N 512 --op mul

    # Run with subtraction operation
    python examples/ampere/elementwise_apply.py --M 1024 --N 512 --op sub

    # Benchmark performance
    python examples/ampere/elementwise_apply.py --M 2048 --N 2048 --op add --benchmark --warmup_iterations 2 --iterations 10

The example demonstrates how to express complex CUDA kernels with customizable operations
while maintaining high performance through efficient memory access patterns.
"""


@cute.kernel
def elementwise_apply_kernel(
    op: cutlass.Constexpr,
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    cC: cute.Tensor,  # coordinate tensor
    shape: cute.Shape,
    tv_layout: cute.Layout,  # (tid, vid) -> logic coord
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    # slice for CTAs
    cta_coord = ((None, None), bidx)
    # logical coord -> address
    ctaA = gA[cta_coord]  # (TileM, TileN)
    ctaB = gB[cta_coord]  # (TileM, TileN)
    ctaC = gC[cta_coord]  # (TileM, TileN)
    ctaCrd = cC[cta_coord]  # (TileM, TileN)

    print(f"[DSL INFO] Sliced Tensors per thread block:")
    print(f"[DSL INFO]   ctaA = {ctaA.type}")
    print(f"[DSL INFO]   ctaB = {ctaB.type}")
    print(f"[DSL INFO]   ctaC = {ctaC.type}")
    print(f"[DSL INFO]   ctaCrd = {ctaCrd.type}")

    # compose with CTA TV layout
    # (tid, vid) -> address
    tidfrgA = cute.composition(ctaA, tv_layout)
    tidfrgB = cute.composition(ctaB, tv_layout)
    tidfrgC = cute.composition(ctaC, tv_layout)
    tidfrgCrd = cute.composition(ctaCrd, tv_layout)
    # print(f"{tv_layout = }")
    # print(f"{tidfrgA = }")

    thr_coord = (tidx, (None, None))

    # slice for threads
    # vid -> address
    thrA = tidfrgA[thr_coord]  # (V)
    thrB = tidfrgB[thr_coord]  # (V)
    thrC = tidfrgC[thr_coord]  # (V)
    thrCrd = tidfrgCrd[thr_coord]

    print(f"[DSL INFO] Sliced Tensors per thread:")
    print(f"[DSL INFO]   thrA = {thrA.type}")
    print(f"[DSL INFO]   thrB = {thrB.type}")
    print(f"[DSL INFO]   thrC = {thrC.type}")
    print(f"[DSL INFO]   thrCrd = {thrCrd.type}")

    # allocate fragments for gmem->rmem
    frgA = cute.make_fragment_like(thrA, gA.element_type)
    frgB = cute.make_fragment_like(thrB, gB.element_type)
    frgC = cute.make_fragment_like(thrC, gC.element_type)
    frgPred = cute.make_fragment(thrCrd.shape, cutlass.Boolean)

    for i in cutlass.range_dynamic(cute.size(frgPred), unroll=1):
        frgPred[i] = cute.elem_less(thrCrd[i], shape)

    # if tidx == 0 and bidx == 0:
    #     cute.print_tensor(frgPred)

    ##########################################################
    # Move data to reg address space
    ##########################################################

    # declare the atoms which will be used later for memory copy
    copy_atom_load = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        gA.element_type,
        num_bits_per_copy=gA.element_type.width,
    )
    copy_atom_store = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        gC.element_type,
        num_bits_per_copy=gC.element_type.width,
    )

    cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)
    cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)

    # Load data before use. The compiler will optimize the copy and load
    # operations to convert some memory ld/st into register uses.
    result = op(frgA.load(), frgB.load())

    # Save the results back to registers. Here we reuse b's registers.
    frgC.store(result)

    # Copy the results back to c
    cute.copy(copy_atom_store, frgC, thrC, pred=frgPred)


@cute.jit
def elementwise_apply(
    op: cutlass.Constexpr,
    a: cute.Tensor,
    b: cute.Tensor,
    result: cute.Tensor,
):
    """CUDA kernel applying binary operator on each element of two n-D input tensors in
    CuTe Python and store to result tensor.

    :param op: Binary operator or lambda function to apply element-wise
    :type op: cutlass.Constexpr
    :param a: First input tensor
    :type a: cute.Tensor
    :param b: Second input tensor
    :type b: cute.Tensor
    :param result: Output tensor to store the results of op(a, b)
    :type result: cute.Tensor
    :return: None
    :rtype: None

    .. code-block:: python

        # Example 1: Adding two tensors
        x = torch.tensor([[1, 2], [3, 4]], dtype=torch.float32, device="cuda")
        y = torch.tensor([[5, 6], [7, 8]], dtype=torch.float32, device="cuda")
        result = torch.empty_like(x)
        elementwise_apply(operator.add, from_dlpack(x), from_dlpack(y), from_dlpack(result))
        # result:
        # tensor([[6.0, 8.0],
        #         [10.0, 12.0]], device='cuda:0')

        # Example 2: Using a lambda function
        elementwise_apply(lambda a, b: a * a + b * b, from_dlpack(x), from_dlpack(y), from_dlpack(result))
        # result:
        # tensor([[  2.,   8.],
        #         [ 54., 512.]], device='cuda:0')
    """

    # Baseline: naive TV layout
    #   * mA layout: (4096, 4096):(4096, 1)
    #   * TV layout map to (512, 4) tile
    #   * tidx maps to mode-0 but input layout is contiguous on mode-1, performance will be bad
    # tv_layout = cute.make_layout((128, (4, 4)), stride=(4, (512, 1)))
    # cta_tiler = (512, 4)

    # Opt-1: better TV layout with better 1D thread layout (SOL with 1D thread layout)
    #   * mA layout: (4096, 4096):(4096, 1)
    #   * TV layout map to (4, 512) tile
    #   * tidx maps to mode-1 which is leading mode of input tensor for coalesced load
    # tv_layout = cute.make_layout((128, (4, 4)), stride=(16, (4, 1)))
    # cta_tiler = (4, 512)

    # Opt-2: 2D tile but worse
    #   * mA layout: (4096, 4096):(4096, 1)
    #   * TV layout map to (128, 16) logical tile
    #   * V layout is bad as contiguous mode is not on right-most
    #     * `cute.copy` only supports vectorize when stride-1 of v-layout on right-most )
    # tv_layout = cute.make_layout(((32, 4), (4, 4)), stride=((4, 512), (1, 128)))
    # cta_tiler = (128, 16)

    # Opt-3: SOL with 2D thread tile
    #   * mA layout: (4096, 4096):(4096, 1)
    #   * TV layout map to (16, 128) logical tile
    #   * tidx maps to mode-1 and input layout is contiguous on mode-1 for coalesced load-store
    thr_layout = cute.make_layout((4, 32), stride=(32, 1))
    val_layout = cute.make_layout((4, 4), stride=(4, 1))
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

    print(f"[DSL INFO] Input Tensors:")
    print(f"[DSL INFO]   a = {a.type}")
    print(f"[DSL INFO]   b = {b.type}")
    print(f"[DSL INFO]   result = {result.type}")

    print(f"[DSL INFO] Tiling Parameters:")
    print(f"[DSL INFO]   tiler_mn = {tiler_mn} per thread block")
    print(f"[DSL INFO]   tv_layout = {tv_layout}")

    gA = cute.zipped_divide(a, tiler_mn)  # ((TileM, TileN), (RestM, RestN))
    gB = cute.zipped_divide(b, tiler_mn)  # ((TileM, TileN), (RestM, RestN))
    gC = cute.zipped_divide(result, tiler_mn)  # ((TileM, TileN), (RestM, RestN))

    print(f"[DSL INFO] Tiled Tensors:")
    print(f"[DSL INFO]   gA = {gA.type}")
    print(f"[DSL INFO]   gB = {gB.type}")
    print(f"[DSL INFO]   gC = {gC.type}")

    idC = cute.make_identity_tensor(result.shape)
    cC = cute.zipped_divide(idC, tiler=tiler_mn)
    print(f"[DSL INFO]   coord tensor = {cC.type}")

    # Launch the kernel asynchronously
    # Async token(s) can also be specified as dependencies
    elementwise_apply_kernel(
        op,
        gA,
        gB,
        gC,
        cC,
        result.shape,
        tv_layout,
    ).launch(
        grid=[cute.size(gC, mode=[1]), 1, 1],
        block=[cute.size(tv_layout, mode=[0]), 1, 1],
    )


def run_elementwise_apply_and_verify(
    op,
    M,
    N,
    dtype: Type[cutlass.Numeric],
    skip_ref_check=False,
    benchmark=True,
    warmup_iterations=2,
    iterations=100,
):
    if not torch.cuda.is_available():
        raise RuntimeError(f"Ampere GPU is required to run this example!")

    print(f"\nRunning Elementwise Apply test with:")
    print(f"Tensor dimensions: [{M}, {N}]")
    print(f"Input and Output Data type: {dtype}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Measurement iterations: {iterations}\n")

    torch_dtype = cutlass_torch.dtype(dtype)

    # Allocate tensors with random values.
    a = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
    b = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
    c = torch.zeros_like(a)

    print(f"Input tensor shapes:")
    print(f"a: {a.shape}, dtype: {a.dtype}")
    print(f"b: {b.shape}, dtype: {b.dtype}")
    print(f"c: {c.shape}, dtype: {c.dtype}\n")

    epsilon = 1.2
    if op in (operator.truediv, operator.floordiv):
        b = torch.where(b == 0, torch.tensor(epsilon), b)

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    compiled_func = cute.compile(elementwise_apply, op, from_dlpack(a), from_dlpack(b), from_dlpack(c).mark_layout_dynamic())
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    print("Executing elementwise apply kernel...")
    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    if not skip_ref_check:
        compiled_func(from_dlpack(a), from_dlpack(b), from_dlpack(c).mark_layout_dynamic())
        print("Verifying results...")
        torch.testing.assert_close(op(a, b), c)
        print("Results verified successfully!")

    if not benchmark:
        return

    # Create CUDA events for timing
    start_event = cuda.cuEventCreate(cuda.CUevent_flags.CU_EVENT_DEFAULT)[1]
    end_event = cuda.cuEventCreate(cuda.CUevent_flags.CU_EVENT_DEFAULT)[1]

    # Warmup
    for _ in range(warmup_iterations):
        compiled_func(from_dlpack(a), from_dlpack(b), from_dlpack(c).mark_layout_dynamic())

    # Record start event
    cuda.cuEventRecord(start_event, current_stream)

    # Execute the kernel
    for _ in range(iterations):
        compiled_func(from_dlpack(a), from_dlpack(b), from_dlpack(c).mark_layout_dynamic())

    # Record end event
    cuda.cuEventRecord(end_event, current_stream)
    cuda.cuEventSynchronize(end_event)

    # Calculate elapsed time
    err, elapsed_time = cuda.cuEventElapsedTime(start_event, end_event)
    avg_time = elapsed_time / iterations

    # Print execution results
    print(f"Kernel execution time: {avg_time:.4f} ms")
    print(
        f"Achieved memory throughput: {(3 * a.numel() * dtype.width // 8) / (avg_time / 1000) / 1e9:.2f} GB/s"
    )
    print(f"First few elements of result: \n{c[:3, :3]}")

    # Destroy events
    cuda.cuEventDestroy(start_event)
    cuda.cuEventDestroy(end_event)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="example of elementwise apply to demonstrate building elementwise kernels"
    )
    parser.add_argument("--M", default=128, type=int)
    parser.add_argument("--N", default=128, type=int)
    parser.add_argument("--op", default="add", type=str)
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--benchmark", action="store_true")
    args = parser.parse_args()
    run_elementwise_apply_and_verify(
        getattr(operator, args.op),
        args.M,
        args.N,
        dtype=cutlass.Float32,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        benchmark=args.benchmark,
    )
    print("\nPASS")
