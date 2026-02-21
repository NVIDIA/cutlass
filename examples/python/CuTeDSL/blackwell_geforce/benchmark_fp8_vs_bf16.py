#!/usr/bin/env python3
"""Benchmark FP8 vs BF16 Flash Attention on SM120 (DGX Spark / GB10).

Runs both kernels across a sweep of configs and prints a comparison table.
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
        bf16_us = run_bf16(B, S, S, H, D, causal, args.warmup, args.iters, args.skip_ref)

        flops = compute_flops(B, H, S, S, D, causal)
        fp8_tflops = flops / (fp8_us * 1e-6) / 1e12 if fp8_us else None
        bf16_tflops = flops / (bf16_us * 1e-6) / 1e12 if bf16_us else None
        speedup = bf16_us / fp8_us if (fp8_us and bf16_us) else None

        results.append((B, S, D, causal, fp8_us, bf16_us, fp8_tflops, bf16_tflops, speedup))

    # Print summary table
    print(f"\n\n{'='*120}")
    print("BENCHMARK RESULTS: FP8 (kind::f8f6f4.m16n8k32) vs BF16 (mma.sync.m16n8k16)")
    print(f"FP8 kernel: FP8FlashAttentionSm120Opt (CpAsync, bank-conflict-free, 4 warps, M=64, N=32)")
    print(f"BF16 kernel: FlashAttentionForwardSm120 (CpAsync, tiled MMA, M=128, N=64)")
    print(f"Device: {torch.cuda.get_device_name(0)}")
    print(f"Heads: {H}, Warmup: {args.warmup}, Iterations: {args.iters}")
    print(f"{'='*120}")
    print(f"| {'Batch':>5} | {'SeqLen':>6} | {'HeadDim':>7} | {'Causal':>6} | "
          f"{'FP8 (μs)':>10} | {'BF16 (μs)':>10} | "
          f"{'FP8 TFLOPS':>10} | {'BF16 TFLOPS':>11} | {'Ratio':>8} |")
    print(f"|{'-'*7}|{'-'*8}|{'-'*9}|{'-'*8}|"
          f"{'-'*12}|{'-'*12}|{'-'*12}|{'-'*13}|{'-'*10}|")

    for B, S, D, causal, fp8_us, bf16_us, fp8_tf, bf16_tf, spd in results:
        fp8_str = f"{fp8_us:10.1f}" if fp8_us else "     FAIL"
        bf16_str = f"{bf16_us:10.1f}" if bf16_us else "     FAIL"
        fp8_tf_str = f"{fp8_tf:10.2f}" if fp8_tf else "       N/A"
        bf16_tf_str = f"{bf16_tf:11.2f}" if bf16_tf else "        N/A"
        if spd is not None:
            spd_str = f"{spd:.2f}x"
        else:
            spd_str = "     N/A"
        print(f"| {B:>5} | {S:>6} | {D:>7} | {'yes' if causal else 'no':>6} | "
              f"{fp8_str} | {bf16_str} | {fp8_tf_str} | {bf16_tf_str} | {spd_str:>8} |")

    # Print markdown table for PR comment
    print(f"\n\n### Markdown table for PR:")
    print(f"| Batch | SeqLen | HeadDim | Causal | FP8 (μs) | BF16 (μs) | "
          f"FP8 TFLOPS | BF16 TFLOPS | Ratio |")
    print(f"|:-----:|:------:|:-------:|:------:|----------:|----------:|"
          f"-----------:|------------:|:-----:|")
    for B, S, D, causal, fp8_us, bf16_us, fp8_tf, bf16_tf, spd in results:
        fp8_str = f"{fp8_us:.1f}" if fp8_us else "FAIL"
        bf16_str = f"{bf16_us:.1f}" if bf16_us else "FAIL"
        fp8_tf_str = f"{fp8_tf:.2f}" if fp8_tf else "N/A"
        bf16_tf_str = f"{bf16_tf:.2f}" if bf16_tf else "N/A"
        spd_str = f"{spd:.2f}x" if spd is not None else "N/A"
        print(f"| {B} | {S} | {D} | {'yes' if causal else 'no'} | "
              f"{fp8_str} | {bf16_str} | {fp8_tf_str} | {bf16_tf_str} | {spd_str} |")


if __name__ == "__main__":
    main()
