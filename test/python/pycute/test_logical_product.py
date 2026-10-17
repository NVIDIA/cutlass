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


class TestLogicalProduct(unittest.TestCase):
  def helper_test_int_tiler(self, layoutA, n):
    # An integer tiler n is shorthand for the tiler Layout(n,1)
    layoutR = logical_product(layoutA, n)
    layoutE = logical_product(layoutA, Layout(n,1))

    _LOGGER.debug(f"{layoutA} * {n}  =>  {layoutR}")

    self.assertEqual(layoutR, layoutE)
    self.assertEqual(zipped_product(layoutA, n), zipped_product(layoutA, Layout(n,1)))
    self.assertEqual(tiled_product(layoutA, n), tiled_product(layoutA, Layout(n,1)))

  def test_int_tiler(self):
    self.assertEqual(logical_product(Layout(2,1), 3), Layout((2,3),(1,2)))
    self.assertEqual(logical_product(Layout((8,6),(1,8)), 3), Layout(((8,6),3),((1,8),48)))

    self.helper_test_int_tiler(Layout(1,0), 4)
    self.helper_test_int_tiler(Layout(2,1), 1)
    self.helper_test_int_tiler(Layout(2,1), 3)
    self.helper_test_int_tiler(Layout(4,2), 3)
    self.helper_test_int_tiler(Layout((8,6),(1,8)), 3)
    self.helper_test_int_tiler(Layout((2,4),(4,1)), 5)

  def test_int_tiler_by_mode(self):
    layoutA = Layout((8,6),(1,8))
    self.assertEqual(logical_product(layoutA, (2,3)),
                     logical_product(layoutA, (Layout(2,1),Layout(3,1))))
    self.assertEqual(logical_product(layoutA, (None,3)),
                     logical_product(layoutA, (None,Layout(3,1))))
    self.assertEqual(zipped_product(layoutA, (2,3)),
                     zipped_product(layoutA, (Layout(2,1),Layout(3,1))))


if __name__ == "__main__":
  unittest.main()
