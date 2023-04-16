#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################

"""
Registry of elementwise epilogues

Elementwise epilogues can be added to many CUTLASS kernels in the CUTLAS Python interface via
code like the following for GEMM:

.. highlight:: python
.. code-block:: python

    plan = cutlass.op.Gemm(element=cutlass.DataType.f32, layout=cutlass.LayoutType.RowMajor)
    plan.activation = cutlass.epilogue.relu
"""

from cutlass.backend import epilogue

gelu = epilogue.gelu
hardswish = epilogue.hardswish
identity = epilogue.identity
leaky_relu = epilogue.leaky_relu
relu = epilogue.relu
sigmoid = epilogue.sigmoid
silu = epilogue.silu
tanh = epilogue.tanh


_activations = [gelu, hardswish, identity, leaky_relu, relu, sigmoid, silu, tanh]


def get_activations() -> list:
    """
    Returns a list of available activation functions

    :return: list of available activation functions
    :rtype: list
    """
    return _activations


def get_activation_epilogue(
    activation,
    element_output,
    elements_per_access,
    element_accumulator,
    element_compute,
):
    """
    Return an epilogue corresponding to the activation function, data types, and alignment
    used in the kernel

    :param activation: elementwise activation function to use
    :param element_output: data type of the output
    :param elements_per_access: alignment of operand C of the kernel
    :type elements_per_access: int
    :param element_accumulator: data type of the accumulated output C
    :param element_compute: data type in which compute operations should be performed

    :return: epilogue functor
    """
    if activation not in _activations:
        raise Exception(
            f"Unsupported activation type {activation}. Available activations are: {_activations}"
        )

    if activation == identity:
        return epilogue.LinearCombination(
            element_output, elements_per_access, element_accumulator, element_compute
        )
    else:
        return epilogue.LinearCombinationGeneric(
            activation(element_compute),
            element_output,
            elements_per_access,
            element_accumulator,
            element_compute,
        )
