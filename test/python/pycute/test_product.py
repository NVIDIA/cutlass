#################################################################################################
#
# Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for pycute.logical_product
"""

import logging
import unittest

from pycute import *

_LOGGER = logging.getLogger(__name__)


class TestProduct(unittest.TestCase):
  def helper_test_logical_product(self, layoutA, layoutB):
    layoutR = logical_product(layoutA, layoutB)

    _LOGGER.debug(f"{layoutA} x {layoutB}  =>  {layoutR}")

    # Post-conditions of test/unit/cute/core/logical_product.cpp
    #   rank(layoutR) == 2
    #   layoutA == layout<0>(layoutR)
    #   compatible(layoutB, layout<1>(layoutR))
    self.assertEqual(len(layoutR), 2)
    self.assertEqual(layoutR[0], layoutA)
    self.assertEqual(size(layoutR[1]), size(layoutB))

  def test_logical_product(self):
    self.helper_test_logical_product(Layout(1,0), Layout(1,0))
    self.helper_test_logical_product(Layout(1,1), Layout(1,0))
    self.helper_test_logical_product(Layout(1,0), Layout(1,1))
    self.helper_test_logical_product(Layout(1,1), Layout(1,1))
    self.helper_test_logical_product(Layout(3,1), Layout(4,0))
    self.helper_test_logical_product(Layout(3,0), Layout(4,1))
    self.helper_test_logical_product(Layout(3,0), Layout(4,0))
    self.helper_test_logical_product(Layout(3,2), Layout(4,1))
    self.helper_test_logical_product(Layout(3),   Layout((2,4)))

  def test_logical_product_int_tiler(self):
    # An int tiler must behave exactly like Layout(tiler), as in C++ cute
    self.helper_test_logical_product(Layout((2,5),(5,1)), 4)
    self.helper_test_logical_product(Layout(3,2), 4)

    layoutA = Layout((2,5),(5,1))
    self.assertEqual(logical_product(layoutA, 4), logical_product(layoutA, Layout(4)))

  def test_logical_product_tuple_tiler(self):
    layoutA = Layout((2,5),(5,1))
    self.assertEqual(logical_product(layoutA, (4,2)),
                     logical_product(layoutA, (Layout(4),Layout(2))))

  def test_zipped_tiled_product_int_tiler(self):
    layoutA = Layout((2,5),(5,1))
    self.assertEqual(zipped_product(layoutA, 4), zipped_product(layoutA, Layout(4)))
    self.assertEqual(tiled_product(layoutA, 4),  tiled_product(layoutA, Layout(4)))


if __name__ == "__main__":
  unittest.main()
