################################################################################
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
################################################################################
"""
Unit test for compute node in SM90
"""

import logging
import unittest

import cutlass
from cutlass.backend import *
from cutlass.epilogue import *
from cutlass import swizzle

from utils.evt_testbed import EVTTestBed, EVTTestCaseBase

cutlass.set_log_level(logging.WARNING)


@unittest.skipIf(device_cc() not in [80, 90], "This unittest is for Sm80 and Sm90 only")
class TestEVTComputeSM90(EVTTestCaseBase):

    def test_arith(self):
        """
        Test Arithmatic op
        """
        def evt_arith_compute(accum, C, alpha, beta, gamma):
            D = ((accum + C) * alpha - gamma) / beta
            return D

        for m, n, k, l in self.get_problem_sizes(8):
            example_inputs = {
                "accum": self.fake_tensor(self.element, (l, m, n)),
                "C": self.fake_tensor(self.element, (l, m, n)),
                "alpha": 1.5,
                "beta": 0.5,
                "gamma": 2.5,
                "D": self.fake_tensor(self.element, (l, m, n))
            }

            launcher = EVTTestBed(self.element, evt_arith_compute, example_inputs)
            input_keys = ["C", "alpha", "beta", "gamma"]
            result_keys = ["D"]
            launcher.verify((m, n, k), input_keys, result_keys, l)

    def test_func_call(self):
        """
        Test Function call
        """
        def evt_func_call(accum, C, alpha, beta, gamma):
            D = multiply_add(relu(accum + alpha) + C, beta, gamma)
            return D

        for m, n, k, l in self.get_problem_sizes(8):
            example_inputs = {
                "accum": self.fake_tensor(self.element, (l, m, n)),
                "C": self.fake_tensor(self.element, (l, m, n)),
                "alpha": 1.5,
                "beta": 0.5,
                "gamma": 2.5,
                "D": self.fake_tensor(self.element, (l, m, n))
            }

            launcher = EVTTestBed(self.element, evt_func_call, example_inputs)
            input_keys = ["C", "alpha", "beta", "gamma"]
            result_keys = ["D"]
            launcher.verify((m, n, k), input_keys, result_keys, l)


if __name__ == '__main__':
    unittest.main()
