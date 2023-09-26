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
Low-level functionality tests for GEMM with F64 operands on SM90
"""

from functools import partial
import logging
import unittest

import cutlass
from cutlass.backend.utils.device import device_cc

from utils import LayoutCombination, add_test_gemm


cutlass.set_log_level(logging.WARNING)
cc = 90

@unittest.skipIf(device_cc() < cc, 'Device compute capability is insufficient for SM90 tests.')
class GemmF64Sm90(unittest.TestCase):
    """
    Wrapper class to which tests will be added dynamically in __main__
    """
    pass


add_test_specialized = partial(add_test_gemm, cls=GemmF64Sm90, alignments=[1, 1, 1], cluster_shape=[1, 1, 1],
                               element=cutlass.DataType.f64, element_output=cutlass.DataType.f64,
                               element_accumulator=cutlass.DataType.f64, compilation_modes=['nvcc'])

add_test_specialized(opclass=cutlass.OpcodeClass.TensorOp, layouts=LayoutCombination.NNT, threadblock_shape=[128, 128, 32], stages=3)
add_test_specialized(opclass=cutlass.OpcodeClass.TensorOp, layouts=LayoutCombination.TNN, threadblock_shape=[128, 128, 32], stages=3)
add_test_specialized(    opclass=cutlass.OpcodeClass.Simt, layouts=LayoutCombination.NNN, threadblock_shape=[128, 128,  8], stages=2)
add_test_specialized(    opclass=cutlass.OpcodeClass.Simt, layouts=LayoutCombination.TTT, threadblock_shape=[ 64, 128,  8], stages=2)


if __name__ == '__main__':
    unittest.main()
