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
import time
from functools import partial
from typing import List, Type

import cuda.bindings.driver as cuda
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
import torch
from cutlass.cute.runtime import from_dlpack

import cutlass

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
    mInputs: List[cute.Tensor],
    mC: cute.Tensor,
    cC: cute.Tensor,  # coordinate tensor
    shape: cute.Shape,
    tv_layout: cute.Layout,  # (tid, vid) -> logic coord
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    ###############################################################################
    # Slice to local tile of thread block
    ###############################################################################
    blk_crd = ((None, None), (bidx, bidy))

    # Leverage the meta-programming capability of the DSL to slice the tensors for each input
    # All for loops below on input tensors would be fully unrolled automatically at compile time
    # logical coord -> memory address
    gInputs = [t[blk_crd] for t in mInputs]  # (TileM, TileN)
    gC = mC[blk_crd]  # (TileM, TileN)
    gCrd = cC[blk_crd]  # (TileM, TileN)

    print("[DSL INFO] Sliced Tensors per thread block:")
    for i in cutlass.range_constexpr(len(gInputs)):
        print(f"[DSL INFO]   ctaInputs{i} = {gInputs[i].type}")
    print(f"[DSL INFO]   gC = {gC.type}")
    print(f"[DSL INFO]   gCrd = {gCrd.type}")

    ###############################################################################
    # Compose with thread block TV layout to map thread & value indices to memory address
    ###############################################################################
    # (tid, vid) -> memory address
    tidfrgInputs = [cute.composition(t, tv_layout) for t in gInputs]
    tidfrgC = cute.composition(gC, tv_layout)
    tidfrgCrd = cute.composition(gCrd, tv_layout)

    # repeat None like vid to remove hierarchy of layout
    thr_crd = (tidx, cute.repeat_like(None, tidfrgInputs[0][1]))

    ###############################################################################
    # Slice to local tile of thread
    ###############################################################################
    # vid -> address
    thrInputs = [t[thr_crd] for t in tidfrgInputs]  # (V)
    thrC = tidfrgC[thr_crd]  # (V)
    thrCrd = tidfrgCrd[thr_crd]

    print("[DSL INFO] Sliced Tensors per thread:")
    for i in cutlass.range_constexpr(len(thrInputs)):
        print(f"[DSL INFO]   thrInputs{i} = {thrInputs[i].type}")
    print(f"[DSL INFO]   thrC = {thrC.type}")
    print(f"[DSL INFO]   thrCrd = {thrCrd.type}")

    ###############################################################################
    # Compute predicate for out of boundary checks
    ###############################################################################
    frgPred = cute.make_rmem_tensor(thrCrd.shape, cutlass.Boolean)
    print(f"[DSL INFO]   frgPred = {frgPred.type}")

    for i in cutlass.range_constexpr(cute.size(frgPred)):
        frgPred[i] = cute.elem_less(thrCrd[i], shape)

    # if tidx == 0 and bidx == 0:
    #     cute.print_tensor(frgPred)

    ##########################################################
    # Load data and compute result
    ##########################################################

    # Load data before use. The compiler will optimize the copy and load
    # operations to convert some memory ld/st into register uses.
    result = op(*[thrInput.load() for thrInput in thrInputs])
    thrC.store(result)


@cute.jit
def elementwise_apply(
    op: cutlass.Constexpr, inputs, result: cute.Tensor, stream: cuda.CUstream
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
    #   * TV layout map to (64, 256) logical tile
    #   * tidx maps to mode-1 and input layout is contiguous on mode-1 for coalesced load-store

    # Use 128bit(16B) load as canonicalized form of val_layout then recast to target element-type
    coalesced_ldst_bytes = 16

    # Compile time validation: expect same element type for all input tensors
    assert all(t.element_type == inputs[0].element_type for t in inputs)
    dtype = inputs[0].element_type

    thr_layout = cute.make_ordered_layout((4, 64), order=(1, 0))
    val_layout = cute.make_ordered_layout((16, coalesced_ldst_bytes), order=(1, 0))
    val_layout = cute.recast_layout(dtype.width, 8, val_layout)
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

    print("[DSL INFO] Input Tensors:")
    for i, t in enumerate(inputs):
        print(f"[DSL INFO]   inputs{i} = {t}")
    print(f"[DSL INFO]   result = {result}")

    print("[DSL INFO] Tiling Parameters:")
    print(f"[DSL INFO]   tiler_mn = {tiler_mn} per thread block")
    print(f"[DSL INFO]   tv_layout = {tv_layout}")

    print("[DSL INFO] Tiled Tensors:")
    mInputs = [cute.zipped_divide(input, tiler_mn) for input in inputs]
    # ((TileM, TileN), (RestM, RestN))
    mC = cute.zipped_divide(result, tiler_mn)

    # (RestM, RestN) -> (RestN, RestM)
    remap_block = cute.make_ordered_layout(
        cute.select(mInputs[0].shape[1], mode=[1, 0]), order=(1, 0)
    )
    for i, t in enumerate(mInputs):
        print(f"[DSL INFO]   gInputs{i}            = {mInputs[i]}")
        mInputs[i] = cute.composition(t, (None, remap_block))
        print(f"[DSL INFO]   gInputs{i} (remapped) = {mInputs[i]}")

    mC = cute.composition(mC, (None, remap_block))
    print(f"[DSL INFO]   gC = {mC}")

    idC = cute.make_identity_tensor(result.shape)
    cC = cute.zipped_divide(idC, tiler=tiler_mn)
    print(f"[DSL INFO]   coord tensor = {cC}")

    # Launch the kernel asynchronously
    # Group input tensors into a list as a single argument
    elementwise_apply_kernel(op, mInputs, mC, cC, result.shape, tv_layout).launch(
        # Compute production at each mode of mC.shape[1] to get multi-dimensional grid size
        grid=cute.product_each(mC.shape[1]),
        block=[cute.size(tv_layout, mode=[0]), 1, 1],
        stream=stream,
    )


@cutlass.dsl_user_op
def leaky_relu(x, alpha, *, loc=None, ip=None):
    return cute.where(x > 0, x, alpha * x, loc=loc, ip=ip)


def leaky_relu_ref(x, alpha):
    return torch.where(x > 0, x, alpha * x)


def run_and_verify(
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
        raise RuntimeError("NVIDIA GPU is required to run this example!")

    if op == "leaky_relu":
        op = partial(leaky_relu, alpha=0.01)
        ref_op = partial(leaky_relu_ref, alpha=0.01)
        num_inputs = 1
    else:
        op = getattr(operator, op)
        ref_op = op
        num_inputs = 2

    # Create non default CUDA stream from PyTorch
    torch_stream = torch.cuda.Stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    print("\nRunning Elementwise Apply test with:")
    print(f"Tensor dimensions: [{M}, {N}]")
    print(f"Input and Output Data type: {dtype}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Measurement iterations: {iterations}\n")

    torch_dtype = cutlass_torch.dtype(dtype)

    # Allocate tensors with random values.
    inputs = [
        torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
        for _ in range(num_inputs)
    ]
    c = torch.zeros_like(inputs[0])

    print("Input tensor shapes:")
    for i in range(num_inputs):
        print(f"inputs[{i}]: {inputs[i].shape}, dtype: {inputs[i].dtype}")
    print(f"c: {c.shape}, dtype: {c.dtype}\n")

    epsilon = 1.2
    if op in (operator.truediv, operator.floordiv):
        inputs[1] = torch.where(inputs[1] == 0, torch.tensor(epsilon), inputs[1])

    inputs_ = [from_dlpack(t, assumed_align=16) for t in inputs]
    c_ = from_dlpack(c, assumed_align=16).mark_layout_dynamic()

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    compiled_fn = cute.compile[cute.GenerateLineInfo(True)](
        elementwise_apply, op, inputs_, c_, current_stream
    )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    if not skip_ref_check:
        print("Executing elementwise apply kernel...")
        compiled_fn(inputs_, c_, current_stream)
        print("Verifying results...")
        torch.testing.assert_close(ref_op(*inputs), c)
        print("Results verified successfully!")
        print(f"First few elements of result: \n{c[:3, :3]}")

    if not benchmark:
        return

    # When compiled we inlined op in the kernel, so we do not pass it when benchmarking

    print("Benchmarking elementwise apply kernel...")
    avg_time_us = testing.benchmark(
        compiled_fn,
        kernel_arguments=testing.JitArguments(inputs_, c_, current_stream),
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cuda_graphs=True,
        stream=current_stream,
    )

    num_elements = sum(input.numel() for input in inputs) + c.numel()

    # Print execution results
    print(f"Kernel execution time: {avg_time_us / 1e3:.4f} ms")
    print(
        f"Achieved memory throughput: {(num_elements * dtype.width // 8) / (avg_time_us * 1000):.2f} GB/s"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Demonstration of building customizable elementwise CUDA kernels using the CuTe DSL"
    )
    parser.add_argument("--M", default=4096, type=int)
    parser.add_argument("--N", default=4096, type=int)
    parser.add_argument("--op", default="add", type=str)
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--benchmark", action="store_true")
    args = parser.parse_args()
    run_and_verify(
        args.op,
        args.M,
        args.N,
        dtype=cutlass.Float32,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        benchmark=args.benchmark,
    )
    print("\nPASS")
