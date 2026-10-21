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

import csv
import importlib
import json
import os
import tempfile
import unittest
from unittest import mock

from cutlass_library import heuristics
from cutlass_library.generator import define_parser
from cutlass_library.manifest import Manifest

# Importing the cutlass_library package loads heuristics while generator is
# still partially initialized, so heuristics misses helpers such as
# CreateGemmUniversal3xOperator. Reloading it once generator is complete gives
# the same namespace that generator.py sees when CMake runs it as a script.
importlib.reload(heuristics)


class FixedConfigHeuristics:
    """Stands in for nvMatmulHeuristics and suggests one fixed config per problem."""

    def __init__(self, gpu=None):
        pass

    def set_cta_div_n(self, n):
        pass

    def get_configs(self, m, n, k, batch_count, dtypes, layouts, align_a, align_b,
                    voidC=False, use_fast_acc=True, count=1):
        return [dict(
            estimated_runtime=1.0,
            cta_tile_m=128, cta_tile_n=128, cta_tile_k=64,
            instr_tile_m=64, instr_tile_n=128, instr_tile_k=16,
            warp_tile_m=0, warp_tile_n=0, warp_tile_k=0,
            cluster_m=1, cluster_n=1, cluster_k=1,
            layout_a=layouts[0], layout_b=layouts[1], layout_d=layouts[2],
            dtype_a=dtypes[0], dtype_b=dtypes[1], dtype_acc=dtypes[2],
            dtype_c=dtypes[3], dtype_d=dtypes[4],
            alignment_a=align_a, alignment_b=align_b,
            swizzle_size=1, raster_order='along_m', split_k_slices=1,
            use_fast_acc=use_fast_acc, voidC=voidC,
        )]


class TestFilterManifestAndWriteHeuristicsFile(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmpdir.cleanup)
        self.problems_file = os.path.join(self.tmpdir.name, 'problems.json')
        self.testlist_file = os.path.join(self.tmpdir.name, 'testlist.csv')
        with open(self.problems_file, 'w') as f:
            json.dump([{
                'm': 4096, 'n': 4096, 'k': 4096, 'batch_count': 1, 'layout': 'tnn',
                'dtype_a': 'f16', 'dtype_b': 'f16', 'dtype_c': 'f16',
                'dtype_acc': 'f32', 'dtype_d': 'f16', 'beta': 0.0,
            }], f)

    def run_heuristics(self, architectures):
        args = define_parser().parse_args([
            '--architectures', architectures,
            '--cuda-version', '12.9.0',
            '--heuristics-problems-file', self.problems_file,
            '--heuristics-testlist-file', self.testlist_file,
            '--heuristics-restrict-kernels',
        ])
        manifest = Manifest(args)
        with mock.patch.object(heuristics, 'MatmulHeuristics', FixedConfigHeuristics):
            heuristics.filter_manifest_and_write_heuristics_file(manifest, args)
        with open(self.testlist_file, newline='') as f:
            names = [row['operation_name'] for row in csv.DictReader(f)]
        filters = [f.pattern for f in manifest.kernel_filter_list]
        return names, filters

    def test_sm90_and_sm100_both_kept(self):
        names, filters = self.run_heuristics('90a;100a')
        for arch in ('_sm90_', '_sm100_'):
            self.assertTrue(any(arch in n for n in names), f'no {arch} kernels in testlist')
            self.assertTrue(any(arch in f for f in filters), f'no {arch} kernel filters')
        self.assertEqual(len(names), len(filters))

    def test_no_supported_arch_raises(self):
        with self.assertRaisesRegex(Exception, 'No valid configurations generated'):
            self.run_heuristics('80')


if __name__ == '__main__':
    unittest.main()
