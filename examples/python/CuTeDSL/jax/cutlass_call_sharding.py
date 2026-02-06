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

from functools import partial
import argparse

import jax
import jax.numpy as jnp
from jax.sharding import Mesh, NamedSharding, PartitionSpec as P
from jax.experimental.custom_partitioning import custom_partitioning

import cutlass
import cutlass.cute as cute
import cutlass.jax as cjax
from cutlass.jax.testing import create_tensor
import cuda.bindings.driver as cuda


"""
Examples of combining jax.jit and jax.shard_map for sharding and executing kernels
across multiple GPU devices.

To run this example:

.. code-block:: bash

    # Run with addition operation
    python examples/jax/cutlass_call_sharding.py
"""


@cute.kernel
def kernel(a: cute.Tensor, b: cute.Tensor, c: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    frgA = cute.make_rmem_tensor(cute.size(a, mode=[0]), a.element_type)
    frgB = cute.make_rmem_tensor(cute.size(b, mode=[0]), b.element_type)
    frgC = cute.make_rmem_tensor(cute.size(c, mode=[0]), c.element_type)

    cute.autovec_copy(a[None, tidx, bidx], frgA)
    cute.autovec_copy(b[None, tidx, bidx], frgB)
    frgC.store(frgA.load() + frgB.load())
    cute.autovec_copy(frgC, c[None, tidx, bidx])


@cute.jit
def launch(
    stream: cuda.CUstream,
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
):
    cute.printf("a: {}", a.layout)
    cute.printf("b: {}", b.layout)
    cute.printf("c: {}", c.layout)
    kernel(a, b, c).launch(
        grid=[a.shape[-1], 1, 1], block=[a.shape[-2], 1, 1], stream=stream
    )


def run_example():
    # Create a device mesh with one axis b
    ngpu = jax.device_count()
    mesh = jax.make_mesh((ngpu,), "b")

    if ngpu == 1:
        print("Note: only 1 GPU was detected.")

    # We will shard our 3D tensors over b
    sharding = P("b", None, None)

    @partial(jax.jit, static_argnums=[0, 1])
    def allocate_sharded_tensors(shape, dtype):
        key = jax.random.key(1123)
        a_key, b_keys = jax.random.split(key, 2)
        a = create_tensor(shape, dtype, a_key)
        b = create_tensor(shape, dtype, b_keys)
        a = jax.lax.with_sharding_constraint(a, NamedSharding(mesh, sharding))
        b = jax.lax.with_sharding_constraint(b, NamedSharding(mesh, sharding))
        return a, b

    @jax.jit
    def compute(a, b):
        # This jax.shard_map partitions the cutlass_call over the mesh.
        @partial(
            jax.shard_map,
            mesh=mesh,
            in_specs=(sharding, sharding),
            out_specs=(sharding, sharding),
        )
        def sharded_call(a_block, b_block):
            call = cjax.cutlass_call(
                launch,
                use_static_tensors=True,
                output_shape_dtype=jax.ShapeDtypeStruct(a_block.shape, a_block.dtype),
            )
            ref_result = a_block + b_block
            return call(a_block, b_block), ref_result

        return sharded_call(a, b)

    # Allocate (32, 16, 64) on each GPU
    shape = (32 * ngpu, 16, 64)
    dtype = jnp.float32

    a, b = allocate_sharded_tensors(shape, dtype)
    c, c_ref = compute(a, b)

    assert jnp.allclose(c, c_ref)


if __name__ == "__main__":
    run_example()
    print("PASS")
