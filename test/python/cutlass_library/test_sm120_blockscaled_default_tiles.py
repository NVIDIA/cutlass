#################################################################################################
#
# Copyright (c) 2026 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Regression test: the default kernel set (empty CUTLASS_LIBRARY_KERNELS) must
select the largest tile for the SM120/SM121 block-scaled GEMM generators.

With an empty kernel filter, CreateGemmUniversal3xOperator prunes each
family's tile list to tile_descriptions[0] ("only generate the largest
tile"). The SM120 block-scaled generators cross every tile with output
variants (e5m2, FP6, FP4 + block-scale-factor output) that only compile at
large tile N: the epilogue smem atom, the FP6 ElementD contiguous-extent
constraint, and the SFVecSize divisibility constraint all reject the small-N
tiles. If a small-N tile is first in the list, the default sm_120a/121a
library build fails with static asserts before a single kernel is usable.
"""

import unittest

from cutlass_library import generator
from cutlass_library.library import GemmKind


class _RecordingManifest:
  """Minimal manifest stub: empty kernel filter (the default-build path),
  records every generated operation."""

  def __init__(self):
    self.kernel_filter = ''
    self.operations = []

  def append(self, operation):
    self.operations.append(operation)


class TestSm120BlockScaledDefaultTiles(unittest.TestCase):

  GENERATORS = (
    generator.GenerateSM120_TensorOp_mixed_8bits_UMMA_gemm_with_block_scaled,
    generator.GenerateSM120_TensorOp_fp4_UMMA_gemm_with_block_scaled,
  )

  GEMM_KINDS = (
    GemmKind.BlockScaledUniversal3x,
    GemmKind.GroupedBlockScaledUniversal3x,
  )

  def _default_set_operations(self, generate_fn, gemm_kind):
    manifest = _RecordingManifest()
    generate_fn(manifest, cuda_version='12.8.0', gemm_kind=gemm_kind)
    return manifest.operations

  def test_default_set_uses_largest_tile(self):
    """Every op in the default set must use the family's largest tile:
    small-N tiles do not support all generated output variants."""
    for generate_fn in self.GENERATORS:
      for gemm_kind in self.GEMM_KINDS:
        with self.subTest(generator=generate_fn.__name__, gemm_kind=gemm_kind):
          operations = self._default_set_operations(generate_fn, gemm_kind)
          self.assertTrue(operations, 'generator emitted no operations')
          for op in operations:
            m, n, k = op.tile_description.threadblock_shape
            self.assertGreaterEqual(
              n, 128,
              f'{op.procedural_name()}: default set selected TileN={n}; '
              'small-N tiles do not compile for all of this family\'s '
              'output variants (see epilogue smem atom / FP6 ElementD / '
              'SFVecSize constraints)')

  def test_full_set_still_contains_small_n_tiles(self):
    """A non-empty kernel filter must still instantiate the small-N tiles;
    the fix reorders the tile lists, it must not remove entries."""
    for generate_fn in self.GENERATORS:
      manifest = _RecordingManifest()
      manifest.kernel_filter = '*'  # non-empty: full tile list
      generate_fn(manifest, cuda_version='12.8.0',
                  gemm_kind=GemmKind.BlockScaledUniversal3x)
      tile_ns = {op.tile_description.threadblock_shape[1]
                 for op in manifest.operations}
      with self.subTest(generator=generate_fn.__name__):
        self.assertIn(8, tile_ns)
        self.assertIn(16, tile_ns)
        self.assertIn(128, tile_ns)


if __name__ == '__main__':
  unittest.main()
