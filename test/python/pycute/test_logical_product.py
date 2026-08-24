#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for pycute.logical_product and its derived forms
"""

import logging
import unittest

from pycute import *

_LOGGER = logging.getLogger(__name__)


class TestLogicalProduct(unittest.TestCase):

  def helper_layouts_equal(self, layoutA, layoutB):
    return tuple(flatten(layoutA.shape)) == tuple(flatten(layoutB.shape)) and \
           tuple(flatten(layoutA.stride)) == tuple(flatten(layoutB.stride))

  def helper_test_product(self, layout, tiler):
    layoutR = logical_product(layout, tiler)

    _LOGGER.debug(f"{layout} x {tiler}  =>  {layoutR}")

    # Post-condition: an integer tiler and its Layout spelling agree
    if is_int(tiler):
      self.assertTrue(self.helper_layouts_equal(layoutR, logical_product(layout, Layout(tiler))))
    # Post-condition: the product covers size(block)*size(tiler)
    self.assertEqual(size(layoutR), size(layout) * size(tiler))

    return layoutR

  def test_logical_product(self):
    A = Layout((2,5),(5,1))
    R = self.helper_test_product(A, 4)
    self.assertTrue(R == Layout(((2,5),4),((5,1),10)))

    A = Layout(4,1)
    self.helper_test_product(A, 3)

    A = Layout((4,8),(1,4))
    self.helper_test_product(A, 16)

    A = Layout(((2,2),(2,2)),((1,4),(8,32)))
    self.helper_test_product(A, 4)

  def test_logical_product_none(self):
    A = Layout((2,5),(5,1))
    self.assertTrue(logical_product(A, None) is A)

  def test_logical_product_tuple(self):
    A = Layout((2,5),(5,1))
    R_int = logical_product(A, (4,2))
    R_lay = make_layout(logical_product(A[0], Layout(4)),
                        logical_product(A[1], Layout(2)))
    _LOGGER.debug(f"{A} x (4,2)  =>  {R_int}")
    self.assertEqual(size(R_int), size(A) * 8)
    self.assertTrue(self.helper_layouts_equal(R_int, R_lay))

  def test_zipped_and_tiled_product(self):
    A = Layout((2,5),(5,1))

    R = zipped_product(A, 4)
    _LOGGER.debug(f"zipped_product({A}, 4)  =>  {R}")
    self.assertEqual(size(R), size(A) * 4)

    R = tiled_product(A, 4)
    _LOGGER.debug(f"tiled_product({A}, 4)  =>  {R}")
    self.assertEqual(size(R), size(A) * 4)


if __name__ == "__main__":
  unittest.main()
