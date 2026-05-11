# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from typing import Any, Callable, Type

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing

"""
In this example we revisit the elementwise add example and use the autotune_jit decorator to
autotune the kernel.

To run this example:

.. code-block:: bash

    python examples/ampere/elementwise_add_autotune.py --M 3 --N 12
    python examples/ampere/elementwise_add_autotune.py --M 1024 --N 512
    python examples/ampere/elementwise_add_autotune.py --M 1024 --N 1024 --benchmark --warmup_iterations 2 --iterations 1000

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
):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    # slice for CTAs
    # logical id -> address
    blk_coord = ((None, None), bidx)
    blkA = gA[blk_coord]  # (TileM,TileN)
    blkB = gB[blk_coord]  # (TileM,TileN)
    blkC = gC[blk_coord]  # (TileM,TileN)
    blkCrd = cC[blk_coord]  # (TileM, TileN)

    # # declare the atoms which will be used later for memory copy
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

    # allocate fragments for gmem->rmem
    frgA = cute.make_rmem_tensor_like(thrA)
    frgB = cute.make_rmem_tensor_like(thrB)
    frgC = cute.make_rmem_tensor_like(thrC)

    thrCrd = thr_copy_C.partition_S(blkCrd)
    frgPred = cute.make_rmem_tensor(thrCrd.shape, cutlass.Boolean)

    for i in range(0, cute.size(frgPred), 1):
        val = cute.elem_less(thrCrd[i], shape)
        frgPred[i] = val

    # Print per thread predicate mask
    # if tidx == 0 and bidx == 0:
    #     cute.printf("block_dim = {}", cute.arch.grid_dim())
    #     cute.printf("shape = {}", shape)
    #     cute.print_tensor(thrA)
    #     cute.print_tensor(thrB)
    #     cute.print_tensor(frgPred)

    ##########################################################
    # Move data to reg address space
    ##########################################################

    cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)
    cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)

    # if tidx == 0 and bidx == 0:
    #     cute.print_tensor(frgA)
    #     cute.print_tensor(frgB)

    # Load data before use. The compiler will optimize the copy and load
    # operations to convert some memory ld/st into register uses.
    result = frgA.load() + frgB.load()

    # Save the results back to registers. Here we reuse b's registers.
    frgC.store(result)

    # Copy the results back to c
    cute.copy(copy_atom_store, frgC, thrC, pred=frgPred)


@testing.autotune_jit(
    params_dict={"copy_bits": [64, 128]},
    update_on_change=["M", "N"],
    warmup_iterations=100,
    iterations=100,
)
@cute.jit
def elementwise_add_autotune(mA, mB, mC, M, N, copy_bits: cutlass.Constexpr = 128):
    dtype = mA.element_type
    vector_size = copy_bits // dtype.width

    thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
    val_layout = cute.make_ordered_layout((4, vector_size), order=(1, 0))
    tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

    gA = cute.zipped_divide(mA, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
    gB = cute.zipped_divide(mB, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
    gC = cute.zipped_divide(mC, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
    idC = cute.make_identity_tensor(mC.shape)
    cC = cute.zipped_divide(idC, tiler=tiler_mn)

    elementwise_add_kernel(gA, gB, gC, cC, mC.shape, thr_layout, val_layout).launch(
        grid=[cute.size(gC, mode=[1]), 1, 1],
        block=[cute.size(tv_layout, mode=[0]), 1, 1],
    )


class ElementwiseAddWrapper:
    """
    This class mimics more advanced kernel development, where a class encapsulates
    pieces of the kernel implementation.

    The can_implement method can be used to check if the kernel can be implemented
    for the given arguments.

    The __call__ method is the actual cute.jit function.

    """

    def __init__(self, copy_bits: cutlass.Constexpr = 128):
        self.copy_bits = copy_bits

    def can_implement(self, mA, mB, mC, M, N):
        return self.copy_bits in [64, 128]

    @cute.jit
    def __call__(self, mA, mB, mC, M, N):
        dtype = mA.element_type
        vector_size = self.copy_bits // dtype.width

        thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
        val_layout = cute.make_ordered_layout((4, vector_size), order=(1, 0))
        tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

        gA = cute.zipped_divide(mA, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
        gB = cute.zipped_divide(mB, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
        gC = cute.zipped_divide(mC, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
        idC = cute.make_identity_tensor(mC.shape)
        cC = cute.zipped_divide(idC, tiler=tiler_mn)

        elementwise_add_kernel(gA, gB, gC, cC, mC.shape, thr_layout, val_layout).launch(
            grid=[cute.size(gC, mode=[1]), 1, 1],
            block=[cute.size(tv_layout, mode=[0]), 1, 1],
        )


def tune_class(mA, mB, mC, M, N):
    """
    This function is used to autotune the elementwise add kernel which is wrapped in a class.
    An internal function is defined to compile the class with the given arguments.
    The internal function is then passed to the benchmarking.tune function to autotune.
    The best parameters are then used to instantiate the class.

    :param mA: Input tensor A
    :type mA: cute.Tensor
    :param mB: Input tensor B
    :type mB: cute.Tensor
    :param mC: Output tensor C
    :type mC: cute.Tensor
    :param M: Number of rows in the input tensors
    :type M: int
    :param N: Number of columns in the input tensors
    :type N: int
    :return: An instance of the ElementwiseAddWrapper class with the best parameters
    :rtype: ElementwiseAddWrapper
    """

    def compile_class(a, b, c, M, N, copy_bits=128) -> Callable[[], Any]:
        kernel = ElementwiseAddWrapper(copy_bits)
        if not kernel.can_implement(a, b, c, M, N):
            raise ValueError(f"Cannot implement kernel for copy_bits={copy_bits}")
        compiled_kernel = cute.compile(kernel, a, b, c, M, N)
        return lambda: compiled_kernel(a, b, c, M, N)

    params = testing.tune(
        compile_class,
        params_dict={"copy_bits": [1, 64, 128]},
        kernel_arguments=testing.JitArguments(mA, mB, mC, M, N),
    )
    return ElementwiseAddWrapper(**params)


def run_elementwise_add(
    M_start,
    M_range,
    M_step,
    N_start,
    N_range,
    N_step,
    dtype: Type[cutlass.Numeric],
    skip_ref_check=False,
    warmup_iterations=2,
    iterations=200,
):
    import torch
    import cutlass.torch as cutlass_torch

    if not torch.cuda.is_available():
        raise RuntimeError("Ampere GPU is required to run this example!")

    for M in range(M_start, M_start + M_range + 1, M_step):
        for N in range(N_start, N_start + N_range + 1, N_step):
            print("\nRunning Elementwise Add test with:")
            print(f"Tensor dimensions: [{M}, {N}]")
            print(f"Input and Output Data type: {dtype}")

            torch_dtype = cutlass_torch.dtype(dtype)
            if dtype.is_integer:
                a = torch.randint(
                    0, 10, (M, N), device=torch.device("cuda"), dtype=torch_dtype
                )
                b = torch.randint(
                    0, 10, (M, N), device=torch.device("cuda"), dtype=torch_dtype
                )
            else:
                a = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
                b = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)

            c = torch.zeros_like(a)

            print("Input tensor shapes:")
            print(f"a: {a.shape}, dtype: {a.dtype}")
            print(f"b: {b.shape}, dtype: {b.dtype}")
            print(f"c: {c.shape}, dtype: {c.dtype}\n")

            elementwise_class = tune_class(a, b, c, M, N)

            if not skip_ref_check:
                print("Verifying results for class ...")
                torch.testing.assert_close(a + b, c)
                print("Results verified successfully!")
                c = torch.zeros_like(a)

            elementwise_add_autotune(a, b, c, M, N)

            if not skip_ref_check:
                print("Verifying results for autotuned function ...")
                torch.testing.assert_close(a + b, c)
                print("Results verified successfully!")

            def generate_kernel_arguments():
                if dtype.is_integer:
                    a = torch.randint(
                        0, 10, (M, N), device=torch.device("cuda"), dtype=torch_dtype
                    )
                    b = torch.randint(
                        0, 10, (M, N), device=torch.device("cuda"), dtype=torch_dtype
                    )
                else:
                    a = torch.randn(
                        M, N, device=torch.device("cuda"), dtype=torch_dtype
                    )
                    b = torch.randn(
                        M, N, device=torch.device("cuda"), dtype=torch_dtype
                    )

                c = torch.zeros_like(a)

                return testing.JitArguments(a, b, c, M, N)

            avg_time_us = testing.benchmark(
                elementwise_add_autotune,
                workspace_generator=generate_kernel_arguments,
                workspace_count=10,
                warmup_iterations=warmup_iterations,
                iterations=iterations,
            )

            # Print execution results
            print(
                f"Kernel execution time for cute.jit kernel with M={M}, N={N}: {avg_time_us / 1e3:.4f} ms"
            )
            print(
                f"Achieved memory throughput for M={M}, N={N}: {(3 * a.numel() * dtype.width // 8) / (avg_time_us / 1e6) / 1e9:.2f} GB/s"
            )

            compiled_class = cute.compile(elementwise_class, a, b, c, M, N)

            avg_time_us = testing.benchmark(
                compiled_class,
                workspace_generator=generate_kernel_arguments,
                workspace_count=10,
                warmup_iterations=warmup_iterations,
                iterations=iterations,
            )

            print(
                f"Kernel execution time for Class Wrapper with M={M}, N={N}: {avg_time_us / 1e3:.4f} ms"
            )
            print(
                f"Achieved memory throughput for M={M}, N={N}: {(3 * a.numel() * dtype.width // 8) / (avg_time_us / 1e6) / 1e9:.2f} GB/s"
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="example of elementwise add to demonstrate the numpy/pytorch as input for kernels"
    )
    parser.add_argument("--M", default=1024, type=int)
    parser.add_argument("--M_range", default=0, type=int)
    parser.add_argument("--M_step", default=1024, type=int)
    parser.add_argument("--N", default=1024, type=int)
    parser.add_argument("--N_range", default=0, type=int)
    parser.add_argument("--N_step", default=1024, type=int)
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")

    args = parser.parse_args()
    run_elementwise_add(
        args.M,
        args.M_range,
        args.M_step,
        args.N,
        args.N_range,
        args.N_step,
        dtype=cutlass.Float32,
        skip_ref_check=args.skip_ref_check,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
    )
    print("\nPASS")
