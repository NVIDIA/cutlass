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

import pytest
from functools import partial
import argparse

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute

import jax
import jax.numpy as jnp
from jax import export

from cutlass.jax import cutlass_call, get_export_disabled_safety_checks
from cutlass.jax.testing import create_tensor

"""
Examples of using jax.export APIs with functions using cutlass_call.

This example demonstrates the use of jax.export with CuTe DSL kernel. It assumes
familiarity with CuTe DSL concepts such as layouts and dynamic shapes as well as
Jax's exporting and serialization features:
https://docs.jax.dev/en/latest/export/index.html#export

To run this example:

.. code-block:: bash

    # Run with defaults
    python examples/jax/cutlass_call_export.py

    # Run with shape (1024, 512)
    python examples/jax/cutlass_call_export.py --M 1024 --N 512

    # Export with symbolic shapes.
    python examples/jax/cutlass_call_export.py --export_symbolic
"""


@cute.kernel
def kernel(gA: cute.Tensor, gB: cute.Tensor, gC: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    bdim, _, _ = cute.arch.block_dim()

    thread_idx = bidx * bdim + tidx

    m, n = gA.shape
    ni = thread_idx % n
    mi = thread_idx // n

    a_val = gA[mi, ni]
    b_val = gB[mi, ni]
    gC[mi, ni] = a_val + b_val


@cute.jit
def launch(stream: cuda.CUstream, mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor):
    print("mA: ", mA.layout)
    print("mB: ", mB.layout)
    print("mC: ", mC.layout)
    num_threads_per_block = 256
    m, n = mA.shape
    kernel(mA, mB, mC).launch(
        grid=((m * n) // num_threads_per_block, 1, 1),
        block=(num_threads_per_block, 1, 1),
        stream=stream,
    )


def run_example(M, N, export_symbolic_shapes):
    @jax.jit
    def f(a, b):
        call = cutlass_call(launch, output_shape_dtype=a)
        return jax.nn.sigmoid(call(a, b))

    @jax.jit
    def ref_f(a, b):
        return jax.nn.sigmoid(a + b)

    # Symbolic or partially shapes are supported by cutlass_call and cute.Tensor
    # This allows export of functions calling Cut eDSL kernels w/o having to re-compile
    # the kernel for each new shape.
    if export_symbolic_shapes:
        a, b = export.symbolic_shape("a, b")
        export_shape_dtype = jax.ShapeDtypeStruct((a, b), jnp.float32)
    else:
        export_shape_dtype = jax.ShapeDtypeStruct((M, N), jnp.float32)

    print("Exporting with input signature: ")
    print(f"({export_shape_dtype}, {export_shape_dtype})")

    # jax.export can be used to export a jit function containing cutlass_call.
    # The function get_export_disabled_safety_checks() returns a list of custom
    # call targets that are used by cutlass_call not part of Jax's built-in
    # list of stable custom calls.
    exported = jax.export.export(f, disabled_checks=get_export_disabled_safety_checks())
    traced = exported(export_shape_dtype, export_shape_dtype)

    # Serialize the computation to a byte blob.
    blob = traced.serialize()
    print(f"Serialized computation is {len(blob)} bytes.")

    # Deserialize and run
    rehydrated = export.deserialize(blob)

    key = jax.random.key(1123)
    a_key, b_key = jax.random.split(key, 2)

    a = create_tensor((M, N), dtype=jnp.float32, key=a_key)
    b = create_tensor((M, N), dtype=jnp.float32, key=b_key)
    c = rehydrated.call(a, b)
    assert jnp.allclose(c, ref_f(a, b))

    # If the computation was exported with dynamic shapes then we can also
    # call it with different shapes. The kernel will not be re-compiled
    # even though the shapes are changing.
    if export_symbolic_shapes:
        a = create_tensor((M * 2, N * 4), dtype=jnp.float32, key=a_key)
        b = create_tensor((M * 2, N * 4), dtype=jnp.float32, key=b_key)
        c = rehydrated.call(a, b)
        assert jnp.allclose(c, ref_f(a, b))

        a = create_tensor((M * 4, N * 4), dtype=jnp.float32, key=a_key)
        b = create_tensor((M * 4, N * 4), dtype=jnp.float32, key=b_key)
        c = rehydrated.call(a, b)
        assert jnp.allclose(c, ref_f(a, b))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Demonstration of using jax.export with functions with cutlass_call"
    )
    parser.add_argument("--M", default=512, type=int)
    parser.add_argument("--N", default=256, type=int)
    parser.add_argument("--export_symbolic", action="store_true")

    args = parser.parse_args()
    run_example(args.M, args.N, args.export_symbolic)
    print("PASS")
