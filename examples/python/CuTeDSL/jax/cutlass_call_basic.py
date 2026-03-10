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
import jax
import jax.numpy as jnp

import cutlass
import cutlass.cute as cute
import cutlass.jax as cjax
import cuda.bindings.driver as cuda

"""
Examples of calling CuTe DSL from jax.jit function using cutlass_call.

cutlass_call is a Jax primitive the enables calling of CuTe DSL kernels within a
a jit-compiled Jax function. During the lowering process cutlass_call will
trigger compilation of the kernel and embed it into the HLO computation. It can
then be efficiently launched by XLA without callback to Python.

This example assumes familiarity with CuTe DSL concepts such as layouts and
dynamic shapes.

To run this example:

.. code-block:: bash

    # Run with addition operation
    python examples/jax/cutlass_call_basic.py
"""


# This is a typical CuTe DSL kernel function that accepts both tensor and scalar values.
@cute.jit
def launch(
    A: cute.Tensor,
    B: cute.Tensor,
    x: cute.Int32,
    y: cute.Int32,
    C: cute.Tensor,
    D: cute.Tensor,
    stream: cuda.CUstream,
):
    # Print layouts
    print("A layout: ", A.layout)
    print("B layout: ", B.layout)
    print("C layout: ", C.layout)
    print("D layout: ", D.layout)
    cute.printf("A layout: {}", A.layout)
    cute.printf("B layout: {}", B.layout)
    cute.printf("C layout: {}", C.layout)
    cute.printf("D layout: {}", D.layout)
    cute.printf("")

    # Print non-tensor values
    print("X is: ", x)
    print("Y is: ", y)
    cute.printf("X is: {}", x)
    cute.printf("Y is: {}", y)
    print()


# cutlass_call uses a fixed function signature to pass arguments between Jax and CuTeDSL kernel.
#
# Function Signature Requirement:
#   stream, inputs, outputs, *, kwargs...
#
# The first argument must be the CUstream that the kernel is run. This stream is managed by the XLA runtime
# and is necessary to schedule and synchronize launches with the rest of your computation.
#
# The second set of arguments are the Jax arrays for inputs and outputs. Inputs must be passed before
# outputs.
#
# Lastly static arguments (i.e. static_argnums or static_argnames) values are passed as keyword only arguments
# by name.
#
# The the kernel does not match this signature a wrapper functions like the one shown below can be written
# or an inline lambda function can be used to rebind the arguments into the appropriate order.
@cute.jit
def launch_jax_wrapper(
    stream: cuda.CUstream,
    A: cute.Tensor,
    B: cute.Tensor,
    C: cute.Tensor,
    D: cute.Tensor,
    *,
    x: cute.Int32,
    y: cute.Int32,
):
    launch(A, B, x, y, C, D, stream)


@cute.jit
def launch_aliased(
    A: cute.Tensor, B: cute.Tensor, x: cute.Int32, y: cute.Int32, stream: cuda.CUstream
):
    # Print layouts
    print("A layout: ", A.layout)
    print("B layout: ", B.layout)
    cute.printf("A layout: {}", A.layout)
    cute.printf("B layout: {}", B.layout)
    cute.printf("")

    # Print non-tensor values
    print("X is: ", x)
    print("Y is: ", y)
    cute.printf("X is: {}", x)
    cute.printf("Y is: {}", y)
    print()


if __name__ == "__main__":

    @partial(jax.jit, static_argnums=[2, 3])
    def run_cutlass_kernel(a, b, x, y):
        call = cjax.cutlass_call(
            launch_jax_wrapper,
            # Jax requires output shapes/dtype information for each output
            output_shape_dtype=(
                jax.ShapeDtypeStruct(a.shape, a.dtype),
                jax.ShapeDtypeStruct(b.shape, a.dtype),
            ),
            # Static jit arguments are passed via additional keyword arguments
            x=x,
            y=y,
        )

        # Returned value is a callable to invoke the kernel passing only jax arrays.
        return call(a, b)

    print("\nExample: example_basic_call_from_jit")
    A = jnp.zeros((512, 32, 64))
    B = jnp.zeros((1, 256, 64, 128))
    C, D = run_cutlass_kernel(A, B, 0, 1)

    @partial(jax.jit, static_argnums=[2, 3])
    def run_cutlass_kernel_lambda(a, b, x, y):
        call = cjax.cutlass_call(
            # A lambda function may be used to wrap and bind arguments passed by jax
            # to the kernel. Alternatively you can wrap using another separate cute.jit
            # function.
            lambda stream, a, b, c, d, *, x, y: launch(a, b, x, y, c, d, stream),
            # Jax requires output shapes/dtype information for each output
            output_shape_dtype=(
                jax.ShapeDtypeStruct(a.shape, a.dtype),
                jax.ShapeDtypeStruct(b.shape, a.dtype),
            ),
            # Static jit arguments are passed via additional keyword arguments
            x=x,
            y=y,
        )

        # Returned value is a callable to invoke the kernel passing only jax arrays.
        return call(a, b)

    print("\nExample: run_cutlass_kernel_lambda")
    A = jnp.zeros((512, 32, 64))
    B = jnp.zeros((1, 256, 64, 128))
    C, D = run_cutlass_kernel_lambda(A, B, 1, 2)

    @partial(jax.jit, static_argnums=[2, 3])
    def run_cutlass_kernel_static_shapes(a, b, x, y):
        call = cjax.cutlass_call(
            lambda stream, a, b, c, d, *, x, y: launch(a, b, x, y, c, d, stream),
            output_shape_dtype=(
                jax.ShapeDtypeStruct(a.shape, a.dtype),
                jax.ShapeDtypeStruct(b.shape, a.dtype),
            ),
            # By default cutlass_call will treat all tensors as dynamic shape.
            # Dynamic shapes are often expected for kernels so this default ensures
            # the broadest support. If you know that a kernel can accept fully static
            # tensors then you can enable this flag to pass all tensors shapes and
            # layouts known at compile time.
            use_static_tensors=True,
            x=x,
            y=y,
        )
        return call(a, b)

    print("\nExample: run_cutlass_kernel_static_shapes")
    A = jnp.zeros((512, 32, 64))
    B = jnp.zeros((1, 256, 64, 128))
    C, D = run_cutlass_kernel_static_shapes(A, B, 3, 4)

    @partial(jax.jit, static_argnums=[2, 3])
    def run_cutlass_kernel_with_modes(a, b, x, y):
        call = cjax.cutlass_call(
            lambda stream, a, b, c, d, *, x, y: launch(a, b, x, y, c, d, stream),
            output_shape_dtype=(
                jax.ShapeDtypeStruct(a.shape, a.dtype),
                jax.ShapeDtypeStruct(b.shape, a.dtype),
            ),
            # The modes of the layout for each tensor can be specified using the
            # TensorSpec. By default modes will align with the physical layout
            # but can be mapped to specific index position. If None is passed
            # then the default mode is assumed for that tensor.
            #
            # Individual static/dynamic settings may also be applied. For example
            # a specific tensor can be marked to have static shape.
            input_spec=(
                cjax.TensorSpec(mode=(1, 0, 2), static=True),
                cjax.TensorSpec(mode=(3, 1, 2, 0)),
            ),
            output_spec=(None, cjax.TensorSpec(mode=(0, 1, 3, 2))),
            x=x,
            y=y,
        )
        return call(a, b)

    print("\nExample: run_cutlass_kernel_with_modes")
    A = jnp.zeros((512, 32, 64))
    B = jnp.zeros((1, 256, 64, 128))
    C, D = run_cutlass_kernel_with_modes(A, B, 5, 6)

    @partial(jax.jit, static_argnums=[2, 3], donate_argnums=[0, 1])
    def run_cutlass_kernel_aliased_outputs(a, b, x, y):
        call = cjax.cutlass_call(
            lambda stream, a, b, *, x, y: launch_aliased(a, b, x, y, stream),
            output_shape_dtype=(
                jax.ShapeDtypeStruct(a.shape, a.dtype),
                jax.ShapeDtypeStruct(b.shape, b.dtype),
            ),
            # Can specify the input tensors that are aliasing outputs of this call.
            # To avoid allocating separate output buffers. This is useful for kernels
            # that update a tensor.
            input_output_aliases={0: 0, 1: 1},
            x=x,
            y=y,
        )
        return call(a, b)

    print("\nExample: run_cutlass_kernel_aliased_outputs")
    A = jnp.zeros((512, 32, 64))
    B = jnp.zeros((1, 256, 64, 128))
    A, B = run_cutlass_kernel_aliased_outputs(A, B, 7, 8)
