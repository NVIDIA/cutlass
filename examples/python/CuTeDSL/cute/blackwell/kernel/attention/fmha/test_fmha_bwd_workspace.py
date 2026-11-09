# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import unittest

import torch

from fmha_bwd import BlackwellFusedMultiHeadAttentionBackward


@unittest.skipUnless(torch.cuda.is_available(), "requires a CUDA device")
class WorkspaceDescriptorTest(unittest.TestCase):
    def check_workspace(self, nbytes):
        owner, workspace = BlackwellFusedMultiHeadAttentionBackward._allocate_workspace(
            nbytes
        )
        try:
            self.assertEqual(owner.dtype, torch.uint8)
            self.assertEqual(owner.numel(), nbytes)
            self.assertEqual(owner.device.type, "cuda")
            self.assertTrue(workspace.__c_pointers__())
        finally:
            del workspace, owner
            torch.cuda.empty_cache()

    def test_below_int32_boundary(self):
        self.check_workspace(2**31 - 1)

    def test_at_int32_boundary(self):
        self.check_workspace(2**31)

    def test_large_fmha_workspace(self):
        self.check_workspace(5697536000)


if __name__ == "__main__":
    unittest.main()
