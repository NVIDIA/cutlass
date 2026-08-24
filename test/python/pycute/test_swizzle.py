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
Unit tests for pycute.Swizzle

Expected tables were cross-checked against cute::Swizzle in
include/cute/swizzle.hpp compiled host-side.
"""

import unittest

from pycute import *

PROBE_POINTS = [0, 1, 2, 7, 8, 9, 15, 16, 63, 64, 255, 256]


class TestSwizzle(unittest.TestCase):

  def test_shift_zero_is_identity(self):
    # A zero-shift swizzle is legal in C++ (Swizzle<0,4,0>) and must not
    # recurse; it applies as the identity.
    sw = Swizzle(0, 4, 0)
    for x in PROBE_POINTS:
      self.assertEqual(sw(x), x)

  def test_patterns_match_cpp(self):
    cases = [
      (Swizzle(2, 3, -3),  [0, 1, 2, 7, 72, 73, 79, 144, 255, 64, 63, 256]),
      (Swizzle(1, 0, 1),   [0, 1, 3, 6, 8, 9, 14, 16, 62, 64, 254, 256]),
      (Swizzle(3, 2, 3),   [0, 1, 2, 7, 8, 9, 15, 16, 59, 72, 227, 256]),
      (Swizzle(2, 1, -2),  [0, 1, 10, 31, 8, 9, 23, 16, 39, 64, 231, 256]),
    ]
    for sw, expected in cases:
      self.assertEqual([sw(x) for x in PROBE_POINTS], expected)

  def test_involutivity(self):
    # Every legal Swizzle is its own inverse on its whole domain; the
    # tested patterns have domain size at most 2**(B+M+abs(S)) <= 256.
    for sw in [Swizzle(0, 4, 0), Swizzle(2, 3, -3), Swizzle(1, 0, 1),
               Swizzle(3, 2, 3), Swizzle(2, 1, -2)]:
      domain = 1 << (sw.base + sw.bits + abs(sw.shift))
      for x in range(domain):
        self.assertEqual(sw(sw(x)), x)


if __name__ == "__main__":
  unittest.main()
