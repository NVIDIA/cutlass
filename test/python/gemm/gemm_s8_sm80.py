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
Low-level functionality tests for GEMM with S8 operands on SM80
"""

from functools import partial

import cutlass
from cutlass.utils.datatypes import binding_opclass, binding_type
from cutlass.backend.test.gemm_testbed import test_all_gemm
import unittest

from cutlass.backend.test.utils import LayoutCombination, get_name
from cutlass.backend.utils.device import device_cc

cc = 80

# Partial specialziation for naming tests
bound_type = binding_type(cutlass.DataType.s8)
name_fn = partial(get_name, element_a=bound_type, element_b=bound_type, arch=cc)


def add_test(cls, layouts, alignments, element_output, element_accumulator,
             threadblock_shape, warp_count, stages, opclass, swizzle=None):
    """
    Create a test-running function with the given specification and set it as a method of `cls`.

    :param cls: class to which the generated method will be added
    :type cls: type
    :param layouts: layouts of A, B, and C operands
    :type layouts: list or tuple
    :param alignments: alingments of A, B, and C operands
    :type alignments: list or tuple
    :param element_output: data type of the output element
    :type element_output: cutlass.DataType
    :param element_accumulator: data type used in accumulation
    :type element_accumulator: cutlass.DataType
    :param threadblock_shape: dimensions of threadblock tiles
    :type threadblock_shape: list or tuple
    :param warp_count: warps to be launched per threadblock dimension
    :type warp_count: list or tuple
    :param stages: number of pipeline stages to use in the kernel
    :type stages: int
    :param opclass: class of operation being performed (e.g., SIMT, Tensor Core)
    :type opclass: cutlass.OpClass
    :param swizzle: threadblock swizzling functor
    """

    cluster_shape = [1, 1, 1]

    def run(self):
        """
        Dynamically-generated function that constructs a GEMM operation and verifies it against
        multiple test cases.
        """
        element_A = cutlass.DataType.s8
        element_B = cutlass.DataType.s8
        layout_A, layout_B, layout_C = layouts
        alignment_A, alignment_B, alignment_C = alignments

        plan = cutlass.op.Gemm(element_A=element_A, element_B=element_B,
                               element_C=element_output, element_D=element_output,
                               layout_A=layout_A, layout_B=layout_B, layout_C=layout_C,
                               element_accumulator=element_accumulator,
                               kernel_cc=cc)

        plan.opclass = opclass
        if swizzle is not None:
            plan.swizzling_functor = swizzle
        td = plan.tile_descriptions()[0]
        td.threadblock_shape = threadblock_shape
        td.stages = stages
        td.warp_count = warp_count
        td.cluster_shape = cluster_shape
        op = plan.construct(tile_description=td, alignment_A=alignment_A, alignment_B=alignment_B, alignment_C=alignment_C)

        self.assertTrue(test_all_gemm(op, 'universal'))

    element_epilogue = element_accumulator
    name = name_fn(layouts, alignments, binding_type(element_output), binding_type(element_accumulator),
                   binding_type(element_epilogue), cluster_shape, threadblock_shape, stages, opclass=binding_opclass(opclass))
    setattr(cls, name, run)

    return run


@unittest.skipIf(device_cc() < cc, 'Device compute capability is insufficient for SM80 tests.')
class GemmS8Sm80(unittest.TestCase):
    """
    Wrapper class to which tests will be added dynamically in __main__
    """
    pass


@unittest.skipIf(device_cc() < cc, 'Device compute capability is insufficient for SM80 tests.')
class GemmS8Sm80StreamK(unittest.TestCase):
    """
    Wrapper class to which tests will be added dynamically in __main__
    """
    pass


# Tests using TensorOp
add_test_tensorop = partial(add_test, opclass=cutlass.OpcodeClass.TensorOp)

add_test_tensorop(GemmS8Sm80, LayoutCombination.TNN, [16, 16, 16], cutlass.DataType.s8, cutlass.DataType.s32, [256, 128, 64], [4, 2, 1], 3)
add_test_tensorop(GemmS8Sm80, LayoutCombination.TNT, [16, 16, 16], cutlass.DataType.s8, cutlass.DataType.s32, [128, 256, 64], [2, 4, 1], 3)
add_test_tensorop(GemmS8Sm80, LayoutCombination.TNN, [16, 16, 4], cutlass.DataType.s32, cutlass.DataType.s32, [64, 64, 64], [1, 1, 1], 4)

# Tests using SIMT
add_test_simt = partial(add_test, opclass=cutlass.OpcodeClass.Simt)

add_test_simt(GemmS8Sm80, LayoutCombination.NNN, [1, 1, 1], cutlass.DataType.s8, cutlass.DataType.s32, [128, 128, 8], [2, 2, 1], 2)
add_test_simt(GemmS8Sm80, LayoutCombination.TNN, [1, 1, 1], cutlass.DataType.s8, cutlass.DataType.s32, [64, 128, 8], [1, 2, 1], 2)
add_test_simt(GemmS8Sm80, LayoutCombination.NTN, [1, 1, 1], cutlass.DataType.s8, cutlass.DataType.s32, [128, 64, 8], [2, 1, 1], 2)
add_test_simt(GemmS8Sm80, LayoutCombination.TTN, [1, 1, 1], cutlass.DataType.s32, cutlass.DataType.s32, [64, 64, 8], [1, 1, 1], 2)
add_test_simt(GemmS8Sm80, LayoutCombination.NNT, [1, 1, 1], cutlass.DataType.s32, cutlass.DataType.s32, [128, 128, 8], [2, 2, 1], 2)

# Stream K tests
add_test_streamk = partial(add_test, opclass=cutlass.OpcodeClass.TensorOp, swizzle=cutlass.swizzle.ThreadblockSwizzleStreamK)
add_test_streamk(GemmS8Sm80StreamK, LayoutCombination.TNT, [16, 16, 16], cutlass.DataType.s8, cutlass.DataType.s32, [128, 256, 64], [2, 4, 1], 3)


if __name__ == '__main__':
    unittest.main()
