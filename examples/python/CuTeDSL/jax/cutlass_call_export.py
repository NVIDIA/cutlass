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

"""
Examples of using jax.export APIs with functions using cutlass_call.

This example demonstrates three export modes:

1. Concrete shapes  -- shapes are fixed constants baked into the export.
2. Unconstrained symbolic shapes ("a, b")
3. Constrained symbolic shapes ("32*M, 16*N")

The JAX function being exported is the same in all three cases; only the
shape specification passed to jax.export differs.

It assumes familiarity with CuTe DSL concepts such as layouts and dynamic shapes
as well as JAX's exporting and serialization features:
https://docs.jax.dev/en/latest/export/index.html#export

To run this example:

.. code-block:: bash

    python examples/jax/cutlass_call_export.py --M 512 --N 256

"""

import argparse

import cuda.bindings.driver as cuda

import cutlass.cute as cute

import jax
import jax.numpy as jnp
from jax import export

from cutlass.jax import cutlass_call, get_export_disabled_safety_checks, TensorSpec
from cutlass.jax.testing import create_tensor


# Simple element-wise addition kernel: gC[i,j] = gA[i,j] + gB[i,j]
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
    num_threads_per_block = 256
    m, n = mA.shape
    kernel(mA, mB, mC).launch(
        grid=((m * n) // num_threads_per_block, 1, 1),
        block=(num_threads_per_block, 1, 1),
        stream=stream,
    )


def _export_and_run(f, ref_f, input_shape_dtype, run_shapes):
    """Export f, serialize/deserialize, then run on each shape in run_shapes.

    Both inputs (a, b) are assumed to share the same input_shape_dtype.
    """
    print(f"Exporting with input signature: ({input_shape_dtype}, {input_shape_dtype})")

    # jax.export can be used to export a jit function containing cutlass_call.
    # CUTLASS custom call targets are not on JAX's built-in stable custom-call
    # allowlist, so we pass them via disabled_checks to suppress that safety check.
    exported = jax.export.export(f, disabled_checks=get_export_disabled_safety_checks())
    traced = exported(input_shape_dtype, input_shape_dtype)

    blob = traced.serialize()
    print(f"Serialized computation is {len(blob)} bytes.")

    rehydrated = export.deserialize(blob)

    key = jax.random.key(1123)
    a_key, b_key = jax.random.split(key, 2)
    for shape in run_shapes:
        a = create_tensor(shape, dtype=jnp.float32, key=a_key)
        b = create_tensor(shape, dtype=jnp.float32, key=b_key)
        c = rehydrated.call(a, b)
        assert jnp.allclose(c, ref_f(a, b)), f"Mismatch at shape {shape}"
        print(f"  shape {shape}: OK")


def run_example(M, N):
    @jax.jit
    def ref_f(a, b):
        return jax.nn.sigmoid(a + b)

    # The same JAX function is used in all three examples below. The export
    # mode is determined entirely by the shape spec passed to jax.export.
    @jax.jit
    def f(a, b):
        call = cutlass_call(launch, output_shape_dtype=a)
        return jax.nn.sigmoid(call(a, b))

    # ── 1. Concrete shapes ────────────────────────────────────────────────────
    # Shapes are fixed constants baked into the export. The deserialized
    # computation only accepts exactly these dimensions at runtime.
    print("\nConcrete shapes:")

    input_shape_dtype = jax.ShapeDtypeStruct((M, N), jnp.float32)
    _export_and_run(
        f,
        ref_f,
        input_shape_dtype,
        run_shapes=[(M, N)],  # concrete exports reject any other shape
    )

    # ── 2. Unconstrained symbolic shapes ─────────────────────────────────────
    # Both dimensions are fully dynamic. The exported computation accepts any
    # (M, N) at runtime without recompilation.
    print("\nUnconstrained symbolic shapes:")

    a_sym, b_sym = export.symbolic_shape("a, b")
    input_shape_dtype = jax.ShapeDtypeStruct((a_sym, b_sym), jnp.float32)
    _export_and_run(
        f,
        ref_f,
        input_shape_dtype,
        run_shapes=[(M, N), (M * 2, N * 4), (M * 4, N * 4)],
    )

    # ── 3. Constrained symbolic shapes (divisibility) ─────────────────────────
    # Shapes are declared as multiples of a tile size via TensorSpec.divisibility.
    # The symbolic expression "32*M, 16*N" tells jax.export that dim 0 is always
    # a multiple of 32 and dim 1 is always a multiple of 16. This lets the
    # compiler generate more efficient code (e.g. no remainder handling).
    # Runtime shapes must satisfy these divisibility constraints.
    print("\nConstrained symbolic shapes:")

    @jax.jit
    def f_divisible(a, b):
        spec = TensorSpec(divisibility=(32, 16))
        call = cutlass_call(
            launch,
            output_shape_dtype=a,
            input_spec=(spec, spec),
            output_spec=spec,
        )
        return jax.nn.sigmoid(call(a, b))

    m_sym, n_sym = export.symbolic_shape("32*M, 16*N")
    input_shape_dtype = jax.ShapeDtypeStruct((m_sym, n_sym), jnp.float32)
    _export_and_run(
        f_divisible,
        ref_f,
        input_shape_dtype,
        run_shapes=[(M, N), (M * 2, N * 2), (M * 4, N * 4)],
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Demonstration of using jax.export with functions with cutlass_call"
    )
    parser.add_argument("--M", default=512, type=int)
    parser.add_argument("--N", default=256, type=int)

    args = parser.parse_args()
    run_example(args.M, args.N)
    print("PASS")
