# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
"""FP32 rounding, layout, ownership, and stream checks for residual fusion."""
from pathlib import Path
import sys
import unittest

import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] /
                      "examples/python/CuTeDSL/cute/ampere/kernel/elementwise"))
from residual_affine import ResidualFusion


def tensors(shape: tuple[int, int, int], token_major: bool):
    batch, tokens, channels = shape
    x = torch.randn((batch, channels, tokens), device="cuda").transpose(1, 2) if token_major else torch.randn(shape, device="cuda")
    y = torch.randn_like(x)
    scale = torch.randn(channels, device="cuda")
    alpha = torch.randn((1, 1, channels), device="cuda")
    beta = torch.randn_like(alpha)
    return x, y, scale, alpha, beta


@unittest.skipUnless(torch.cuda.is_available(), "requires CUDA")
class TestResidualAffine(unittest.TestCase):
    @torch.inference_mode()
    def test_layouts_tails_and_mixed_layout_residual(self):
        torch.manual_seed(3667)
        fusion = ResidualFusion()
        for shape in ((1, 3, 5), (1, 196, 384), (2, 196, 384), (8, 196, 384)):
            for token_major in (False, True):
                with self.subTest(shape=shape, token_major=token_major):
                    x, y, scale, alpha, beta = tensors(shape, token_major)
                    saved_x, saved_y = x.clone(), y.clone()
                    reference = x + scale * y
                    r, z = fusion(x, y, scale, alpha, beta, True)
                    self.assertTrue(torch.equal(r.view(torch.int32), reference.view(torch.int32)))
                    self.assertTrue(torch.equal(z.view(torch.int32), torch.addcmul(beta, alpha, reference).view(torch.int32)))
                    self.assertEqual(r.stride(), x.stride())
                    mixed = torch.randn(shape, device="cuda")
                    next_r, _ = fusion(x, mixed, scale, alpha, beta, False)
                    self.assertTrue(torch.equal(next_r.view(torch.int32), (x + scale * mixed).view(torch.int32)))
                    self.assertNotEqual(r.data_ptr(), next_r.data_ptr())
                    self.assertTrue(torch.equal(x, saved_x) and torch.equal(y, saved_y))

    @torch.inference_mode()
    def test_separate_residual_rounding(self):
        torch.manual_seed(303403)
        x, y, scale, alpha, beta = tensors((2, 7, 31), True)
        # Cancellation exposes accidental contraction of the residual mul/add.
        x.copy_(-(scale * y))
        x[:, :2] = torch.tensor([1e-38, -1e-38], device="cuda").view(1, 2, 1)
        r, z = ResidualFusion()(x, y, scale, alpha, beta, True)
        reference = x + scale * y
        self.assertTrue(torch.equal(r.view(torch.int32), reference.view(torch.int32)))
        self.assertTrue(torch.equal(z.view(torch.int32), torch.addcmul(beta, alpha, reference).view(torch.int32)))

    @torch.inference_mode()
    def test_current_stream_and_graph(self):
        fusion = ResidualFusion()
        stream = torch.cuda.Stream()
        with torch.cuda.stream(stream):
            x, y, scale, alpha, beta = tensors((2, 13, 17), True)
            expected = x + scale * y
            fusion(x, y, scale, alpha, beta, True)
            graph = torch.cuda.CUDAGraph()
            with torch.cuda.graph(graph, stream=stream):
                r, z = fusion(x, y, scale, alpha, beta, True)
            graph.replay()
        stream.synchronize()
        self.assertTrue(torch.equal(r.view(torch.int32), expected.view(torch.int32)))
        self.assertTrue(torch.equal(z.view(torch.int32), torch.addcmul(beta, alpha, expected).view(torch.int32)))

    def test_rejects_autograd(self):
        with torch.enable_grad(), self.assertRaisesRegex(ValueError, "inference-only"):
            ResidualFusion()(*tensors((1, 3, 5), False), True)


if __name__ == "__main__":
    unittest.main()
