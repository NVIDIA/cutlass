# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
"""Pretrained ResMLP inference with fused residual/Affine pointwise operations.

Requires timm and safetensors in addition to CuTe DSL's TVM FFI dependencies.
Pass a local timm/resmlp_12_224.fb_in1k safetensors checkpoint. Download, model
loading, JIT compilation, and graph capture are excluded from steady-state time.
No weights are transformed; transpose views and GEMMs keep their native layout.

Run each arm in a separate process, for example in native/fused/fused/native order:
    python resmlp_inference.py --weights model.safetensors --arm native
    python resmlp_inference.py --weights model.safetensors --arm fused --graph
"""
import argparse
import json
from pathlib import Path
import statistics
import time
import types

import timm
from timm.models.mlp_mixer import ResBlock
import torch
from safetensors.torch import load_file

from residual_affine import ResidualFusion


def fused_forward(self: ResBlock, x: torch.Tensor) -> torch.Tensor:
    token_mix = self.linear_tokens(self.norm1(x).transpose(1, 2)).transpose(1, 2)
    residual, normalized = self.residual_fusion(
        x, token_mix, self.ls1, self.norm2.alpha, self.norm2.beta, True
    )
    channel_mix = self.mlp_channels(normalized)
    return self.residual_fusion(
        residual, channel_mix, self.ls2, self.norm2.alpha, self.norm2.beta, False
    )[0]


@torch.inference_mode()
def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--weights", type=Path, required=True)
    parser.add_argument("--arm", choices=("native", "fused"), required=True)
    parser.add_argument("--batch", type=int, default=2)
    parser.add_argument("--graph", action="store_true")
    args = parser.parse_args()
    torch.manual_seed(303401)
    torch.set_num_threads(4)
    torch.backends.cuda.matmul.allow_tf32 = False
    torch.backends.cudnn.allow_tf32 = False
    model = timm.create_model("resmlp_12_224.fb_in1k", pretrained=False).eval().cuda()
    model.load_state_dict(load_file(str(args.weights)))
    inputs = torch.randn(args.batch, 3, 224, 224, device="cuda")
    reference = model(inputs).clone()
    fusion = ResidualFusion()
    if args.arm == "fused":
        for block in model.blocks:
            block.residual_fusion = fusion
            block.forward = types.MethodType(fused_forward, block)
    output = model(inputs)
    assert torch.equal(output.view(torch.int32), reference.view(torch.int32))
    assert fusion.calls == (24 if args.arm == "fused" else 0)

    def eager() -> torch.Tensor:
        return model(inputs)

    run = eager
    if args.graph:
        stream = torch.cuda.Stream()
        stream.wait_stream(torch.cuda.current_stream())
        with torch.cuda.stream(stream):
            for _ in range(3):
                eager()
        torch.cuda.current_stream().wait_stream(stream)
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph):
            output = eager()
        graph.replay()
        torch.cuda.synchronize()
        assert torch.equal(output.view(torch.int32), reference.view(torch.int32))
        run = graph.replay

    samples = []
    cache_entries = len(fusion.compiled)
    for _ in range(6):
        for _ in range(10):
            run()
        torch.cuda.synchronize()
        start = time.perf_counter()
        for _ in range(30):
            run()
        torch.cuda.synchronize()
        samples.append((time.perf_counter() - start) * 1000 / 30)
    assert len(fusion.compiled) == cache_entries
    print(json.dumps({"arm": args.arm, "batch": args.batch,
                      "mode": "cuda-graph" if args.graph else "eager",
                      "bit_exact": True, "samples_ms": samples,
                      "median_ms": statistics.median(samples)}, indent=2))


if __name__ == "__main__":
    main()
