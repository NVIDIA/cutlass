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

"""Example demonstrating how to use TVM-FFI ABI with CuTe.

This example shows how to:
1. Compile a CuTe function with "--enable-tvm-ffi" option
2. Directly use the compiled function to work with JAX

To run this example:

.. code-block:: bash

    pip install jax-tvm-ffi
    pip install jax[cuda13]

    python cutlass_ir/compiler/python/examples/cute/tvm_ffi/jit_and_use_in_jax.py
"""

import jax
from jax import numpy as jnp
import jax_tvm_ffi
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def device_add_one(a: cute.Tensor, b: cute.Tensor):
    for i in range(a.shape[0]):
        b[i] = a[i] + 1


@cute.jit
def add_one(a: cute.Tensor, b: cute.Tensor):
    """b = a + 1"""
    device_add_one(a, b).launch(grid=(1, 1, 1), block=(1, 1, 1))


def main():
    # compile the kernel with "--enable-tvm-ffi" option
    a_jax = jnp.arange(
        10,
        dtype=jnp.float32,
    )
    b_jax = jnp.zeros(
        10,
        dtype=jnp.float32,
    )
    a_cute = from_dlpack(a_jax, enable_tvm_ffi=True).mark_layout_dynamic()
    b_cute = from_dlpack(b_jax, enable_tvm_ffi=True).mark_layout_dynamic()
    # compile the kernel with "--enable-tvm-ffi" option
    compiled_add_one = cute.compile(add_one, a_cute, b_cute, options="--enable-tvm-ffi")

    # register the compiled function to JAX as a FFI target
    jax_tvm_ffi.register_ffi_target("add_one_cute", compiled_add_one, platform="gpu")
    a_jax = jnp.arange(10, dtype=jnp.float32)
    # call the compiled function using JAX FFI
    b_jax = jax.ffi.ffi_call(
        "add_one_cute",
        jax.ShapeDtypeStruct(a_jax.shape, a_jax.dtype),
        vmap_method="broadcast_all",
    )(a_jax)
    print("result of b_jax after add_one_cute")
    print(b_jax)


if __name__ == "__main__":
    main()
