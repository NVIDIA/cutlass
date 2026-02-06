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
import operator
from functools import partial
from typing import List, Type

import cuda.bindings.driver as cuda
import cutlass
import cutlass.cute as cute

"""
An Elementwise Apply Example using CuTe DSL with cutlass.jax.cutlass_call

This example is similar to examples/ampere/elementwise_apply.py but demonstrates
how to run the code in a jax specific way using the cutlass_call primitive. It assumes
familiarity with basic CuTe DSL concepts as well as the cutlass_call primitive.

To run this example:

.. code-block:: bash

    # Run with addition operation
    python examples/jax/elementwise_apply_example.py --M 1024 --N 512 --op add

    # Run with multiplication operation
    python examples/ampere/elementwise_apply_example.py --M 1024 --N 512 --op mul

    # Run with subtraction operation
    python examples/ampere/elementwise_apply_example.py --M 1024 --N 512 --op sub
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
    frgPred = cute.make_fragment(thrCrd.shape, cutlass.Boolean)
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
    import jax.numpy as jnp

    return jnp.where(x > 0, x, alpha * x)


def run_and_verify(op, M, N, dtype, skip_ref_check=False):
    import jax
    import jax.numpy as jnp
    import cutlass.jax as cjax
    import cutlass.jax.testing as testing

    if op == "leaky_relu":
        op = partial(leaky_relu, alpha=0.01)
        ref_op = partial(leaky_relu_ref, alpha=0.01)
        num_inputs = 1
    else:
        op = getattr(operator, op)
        ref_op = op
        num_inputs = 2

    # This jax function is transformed using jax.jit to compile its contents
    # into an efficient HLO executable.
    @partial(jax.jit, static_argnums=[1])
    def jax_function(inputs, op):
        call = cjax.cutlass_call(
            # Bind jax arguments to kernel signature
            lambda stream, inputs, output, *, op: elementwise_apply(
                op, inputs, output, stream
            ),
            # Specify output shape/dtype of result
            output_shape_dtype=jax.ShapeDtypeStruct(inputs[0].shape, inputs[0].dtype),
            # Pass static/constexpr values as kwargs
            op=op,
        )

        # Call the kernel!
        return call(inputs)

    @partial(jax.jit, static_argnums=[1])
    def jax_ref_function(inputs, op):
        return op(*inputs)

    print("\nRunning Elementwise Apply test with:")
    print(f"Tensor dimensions: [{M}, {N}]")
    print(f"Input and Output Data type: {dtype}")

    jax_dtype = cjax.cutlass_to_jax_dtype(dtype)
    keys = jax.random.split(jax.random.key(1435), num_inputs)
    inputs = [testing.create_tensor((M, N), jax_dtype, key) for key in keys]

    print("Input tensor shapes:")
    for i in range(num_inputs):
        print(f"inputs[{i}]: {inputs[i].shape}, dtype: {inputs[i].dtype}")

    epsilon = 1.2
    if op in (operator.truediv, operator.floordiv):
        inputs[1] = jnp.where(inputs[1] == 0, epsilon, inputs[1])

    # Call the jax.jit function which will compile the kernel
    c = jax_function(inputs, op)

    if not skip_ref_check:
        print("Executing elementwise apply kernel...")
        c = jax_function(inputs, op)
        print("Verifying results...")
        assert jnp.allclose(ref_op(*inputs), c)
        print("Results verified successfully!")
        print(f"First few elements of result: \n{c[:3, :3]}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Demonstration of calling a kernel with cutlass_call"
    )
    parser.add_argument("--M", default=4096, type=int)
    parser.add_argument("--N", default=4096, type=int)
    parser.add_argument("--op", default="add", type=str)
    parser.add_argument("--skip_ref_check", action="store_true")

    args = parser.parse_args()
    run_and_verify(
        args.op,
        args.M,
        args.N,
        dtype=cutlass.Float32,
        skip_ref_check=args.skip_ref_check,
    )
    print("\nPASS")
