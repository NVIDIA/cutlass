# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

"""Benchmark FP8 vs BF16 Flash Attention on SM120 (DGX Spark / GB10).

Compares three kernels across a sweep of configs:
  - FP8FlashAttentionSm120Opt (CpAsync, M=64 N=32)
  - FP8FlashAttentionSm120Tma (TMA + warp specialization, M=128 N=64)
  - FlashAttentionForwardSm120 (BF16 CpAsync, M=128 N=64)
"""
import argparse
import sys
import os
import torch
import cuda.bindings.driver as cuda

# Add parent path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cutlass
import cutlass.cute as cute


def compute_flops(B, H, Sq, Sk, D, is_causal):
    flops = 4 * B * H * Sq * Sk * D
    if is_causal:
        flops //= 2
    return flops


def run_fp8(B, Sq, Sk, H, D, is_causal, warmup, iters, skip_ref):
    from fp8_flash_attention import run_benchmark
    try:
        return run_benchmark(
            B, Sq, Sk, H, D,
            is_causal=is_causal,
            warmup_iterations=warmup,
            iterations=iters,
            skip_ref_check=skip_ref,
            use_opt=True,
        )
    except Exception as e:
        print(f"  FP8 failed: {e}")
        return None


def run_fp8_tma(B, Sq, Sk, H, D, is_causal, warmup, iters, skip_ref):
    from fp8_flash_attention_tma import run_benchmark as run_fp8_tma_impl
    try:
        return run_fp8_tma_impl(
            B, Sq, Sk, H, D,
            is_causal=is_causal,
            warmup_iterations=warmup,
            iterations=iters,
            skip_ref_check=skip_ref,
        )
    except Exception as e:
        print(f"  FP8 TMA failed: {e}")
        return None


def run_bf16(B, Sq, Sk, H, D, is_causal, warmup, iters, skip_ref):
    from flash_attention_v2 import run as run_bf16_impl
    try:
        return run_bf16_impl(
            cutlass.BFloat16, B, Sq, Sk, H, D,
            softmax_scale=1.0 / (D ** 0.5),
            m_block_size=128, n_block_size=64, num_threads=128,
            is_causal=is_causal,
            warmup_iterations=warmup,
            iterations=iters,
            skip_ref_check=skip_ref,
        )
    except Exception as e:
        print(f"  BF16 failed: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description="FP8 vs BF16 FA Benchmark")
    parser.add_argument("--warmup", type=int, default=10)
    parser.add_argument("--iters", type=int, default=50)
    parser.add_argument("--skip_ref", action="store_true",
                        help="Skip reference correctness check")
    parser.add_argument("--quick", action="store_true",
                        help="Run a small subset of configs")
    args = parser.parse_args()

    configs = [
        # (B, SeqLen, HeadDim, Causal)
        (1, 512, 64, False),
        (1, 512, 64, True),
        (1, 512, 128, False),
        (1, 512, 128, True),
        (1, 1024, 64, False),
        (1, 1024, 64, True),
        (1, 1024, 128, False),
        (1, 1024, 128, True),
        (1, 2048, 64, False),
        (1, 2048, 64, True),
        (1, 2048, 128, False),
        (1, 2048, 128, True),
        (4, 512, 64, False),
        (4, 512, 128, False),
        (4, 1024, 64, False),
        (4, 1024, 128, False),
    ]

    if args.quick:
        configs = [
            (1, 512, 128, False),
            (1, 1024, 128, False),
            (1, 2048, 128, False),
            (4, 1024, 128, False),
        ]

    H = 16  # Fixed heads across all configs

    results = []
    for B, S, D, causal in configs:
        label = f"B={B} S={S:4d} D={D:3d} {'causal' if causal else '      '}"
        print(f"\n{'='*60}")
        print(f"Config: {label}")
        print(f"{'='*60}")

        fp8_us = run_fp8(B, S, S, H, D, causal, args.warmup, args.iters, args.skip_ref)
        fp8_tma_us = run_fp8_tma(B, S, S, H, D, causal, args.warmup, args.iters, args.skip_ref)
        bf16_us = run_bf16(B, S, S, H, D, causal, args.warmup, args.iters, args.skip_ref)

        flops = compute_flops(B, H, S, S, D, causal)
        fp8_tflops = flops / (fp8_us * 1e-6) / 1e12 if fp8_us else None
        fp8_tma_tflops = flops / (fp8_tma_us * 1e-6) / 1e12 if fp8_tma_us else None
        bf16_tflops = flops / (bf16_us * 1e-6) / 1e12 if bf16_us else None
        # Speedup of FP8 TMA over the next-best of {FP8 Opt, BF16}
        speedup_vs_fp8 = fp8_us / fp8_tma_us if (fp8_us and fp8_tma_us) else None
        speedup_vs_bf16 = bf16_us / fp8_tma_us if (bf16_us and fp8_tma_us) else None

        results.append((
            B, S, D, causal, fp8_us, fp8_tma_us, bf16_us,
            fp8_tflops, fp8_tma_tflops, bf16_tflops,
            speedup_vs_fp8, speedup_vs_bf16,
        ))

    # Print summary table
    print(f"\n\n{'='*140}")
    print("BENCHMARK RESULTS: FP8 (kind::f8f6f4.m16n8k32) vs BF16 (mma.sync.m16n8k16)")
    print(f"FP8 Opt:   FP8FlashAttentionSm120Opt   (CpAsync, 4 warps, M=64, N=32)")
    print(f"FP8 TMA:   FP8FlashAttentionSm120Tma   (TMA + warp specialization, M=128, N=64)")
    print(f"BF16:      FlashAttentionForwardSm120  (CpAsync, tiled MMA, M=128, N=64)")
    print(f"Device: {torch.cuda.get_device_name(0)}")
    print(f"Heads: {H}, Warmup: {args.warmup}, Iterations: {args.iters}")
    print(f"{'='*140}")
    print(f"| {'B':>3} | {'S':>5} | {'D':>3} | {'Cau':>3} | "
          f"{'FP8 Opt μs':>10} | {'FP8 TMA μs':>10} | {'BF16 μs':>9} | "
          f"{'TMA TFLOPS':>10} | {'TMA/Opt':>7} | {'TMA/BF16':>8} |")
    print(f"|{'-'*5}|{'-'*7}|{'-'*5}|{'-'*5}|"
          f"{'-'*12}|{'-'*12}|{'-'*11}|{'-'*12}|{'-'*9}|{'-'*10}|")

    sum_opt = sum_tma = sum_bf16 = 0.0
    n_done = 0
    for (B, S, D, causal, fp8_us, fp8_tma_us, bf16_us,
         fp8_tf, fp8_tma_tf, bf16_tf, spd_opt, spd_bf16) in results:
        opt_s = f"{fp8_us:10.1f}" if fp8_us else "     FAIL"
        tma_s = f"{fp8_tma_us:10.1f}" if fp8_tma_us else "     FAIL"
        bf16_s = f"{bf16_us:9.1f}" if bf16_us else "    FAIL"
        tma_tf_s = f"{fp8_tma_tf:10.2f}" if fp8_tma_tf else "       N/A"
        spd_o_s = f"{spd_opt:.2f}x" if spd_opt is not None else "  N/A"
        spd_b_s = f"{spd_bf16:.2f}x" if spd_bf16 is not None else "   N/A"
        if fp8_us and fp8_tma_us and bf16_us:
            sum_opt += fp8_us; sum_tma += fp8_tma_us; sum_bf16 += bf16_us
            n_done += 1
        print(f"| {B:>3} | {S:>5} | {D:>3} | {'y' if causal else 'n':>3} | "
              f"{opt_s} | {tma_s} | {bf16_s} | {tma_tf_s} | "
              f"{spd_o_s:>7} | {spd_b_s:>8} |")
    if n_done:
        print(f"\nSum-time speedup (FP8 TMA vs FP8 Opt): {sum_opt/sum_tma:.2f}x")
        print(f"Sum-time speedup (FP8 TMA vs BF16):    {sum_bf16/sum_tma:.2f}x")

    # Print markdown table for PR comment
    print(f"\n\n### Markdown table for PR:")
    print(f"| Batch | SeqLen | HeadDim | Causal | FP8 Opt (μs) | FP8 TMA (μs) | BF16 (μs) | "
          f"TMA TFLOPS | TMA/Opt | TMA/BF16 |")
    print(f"|:-----:|:------:|:-------:|:------:|------------:|------------:|----------:|"
          f"-----------:|--------:|---------:|")
    for (B, S, D, causal, fp8_us, fp8_tma_us, bf16_us,
         fp8_tf, fp8_tma_tf, bf16_tf, spd_opt, spd_bf16) in results:
        opt_s = f"{fp8_us:.1f}" if fp8_us else "FAIL"
        tma_s = f"{fp8_tma_us:.1f}" if fp8_tma_us else "FAIL"
        bf16_s = f"{bf16_us:.1f}" if bf16_us else "FAIL"
        tma_tf_s = f"{fp8_tma_tf:.2f}" if fp8_tma_tf else "N/A"
        spd_o_s = f"{spd_opt:.2f}x" if spd_opt is not None else "N/A"
        spd_b_s = f"{spd_bf16:.2f}x" if spd_bf16 is not None else "N/A"
        print(f"| {B} | {S} | {D} | {'yes' if causal else 'no'} | "
              f"{opt_s} | {tma_s} | {bf16_s} | {tma_tf_s} | {spd_o_s} | {spd_b_s} |")


if __name__ == "__main__":
    main()
