

import argparse
import torch
import time
import math
from typing import Type, Optional


import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack

"""
CTA-level LayerNorm / RMSNorm Example using CuTe DSL.

This example implements a CTA-level normalization kernel (LayerNorm or RMSNorm)
using the CuTe DSL. Each CTA processes one row of the input tensor and performs
the full normalization pipeline, including global memory loads, reduction,
normalization, and global memory stores.

In this kernel:

- Threads are arranged linearly within a CTA.
- Vectorized 128-bit loads/stores are used to maximize memory bandwidth.

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/hopper/cta_norm.py
    python examples/python/CuTeDSL/hopper/cta_norm.py \
        --M 4096 --N 8192 --dtype fp16 --threads 256 \
        --norm_type rms --benchmark

To collect performance with NCU profiler:

.. code-block:: bash
    ncu -k regex:".*cutlass.*" python examples/python/CuTeDSL/hopper/cta_norm.py
"""

DTYPE_MAP = {
    "fp16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "fp32": cutlass.Float32,
}

class CtaNorm:
    def __init__(
        self, N: int,
        norm_type: str,
        threads_per_cta: Optional[int] = None,
    ):
        self.N = N # hidden_size
        self.norm_type = norm_type # "layer" or "rms"
        self.elems_per_thread = 8
        self.warp_size = 32
        self.threads_per_cta = threads_per_cta or self.heuristic_threads()
        self.warps_per_cta = (self.threads_per_cta + 31) // self.warp_size
    
    def heuristic_threads(self):
        elems_per_warp = self.elems_per_thread * self.warp_size
        heu_warps = (self.N + elems_per_warp - 1) // elems_per_warp // 4
        heu_warps = max(heu_warps, 1) # at least one warp
        heu_warps = (heu_warps + 1) // 2 * 2 # be multiple of 2
        heu_threads = heu_warps * 32
        return heu_threads

    @cute.jit
    def __call__(
        self,
        mY,
        mX,
        mWeight,
        mBias,
        eps: cutlass.Float32 = 1e-6,
    ):
        print("[DSL INFO] Input Tensors:")
        print(f"[DSL INFO]   mY = {mY.type}")
        print(f"[DSL INFO]   mX = {mX.type}")
        print(f"[DSL INFO]   mWeight = {mWeight.type}")
        if cutlass.const_expr(self.norm_type == "layer"):
            print(f"[DSL INFO]   mBias = {mBias.type}")
        M, _ = mX.shape
        atom_copy = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            mX.element_type,
            num_bits_per_copy=128,
        )
        t_layout = cute.make_layout(self.threads_per_cta)  # thread layout within a CTA
        v_layout = cute.make_layout(self.elems_per_thread)  # per-thread vector layout
        tiled_copy = cute.make_tiled_copy_tv(atom_copy, t_layout, v_layout)
        print("[DSL INFO] Tiling Parameters:")
        print(f"[DSL INFO]   tiled_copy = {tiled_copy}")
        self.kernel(mY, mX, mWeight, mBias, tiled_copy, eps).launch(
            grid=[M, 1, 1],
            block=[self.warps_per_cta * self.warp_size, 1, 1],
        )

    @cute.kernel
    def kernel(
        self,
        mY: cute.Tensor,
        mX: cute.Tensor,
        mWeight: Optional[cute.Tensor],
        mBias: Optional[cute.Tensor],
        tiled_copy: cute.TiledCopy,
        eps: cute.Float,
    ):
        tidx, _, _ = cute.arch.thread_idx()  # thread index
        bidx, _, _ = cute.arch.block_idx()  # cta index
        thr_copy = tiled_copy.get_slice(tidx)

        gY = cute.local_tile(mY, tiler=(1, self.N), coord=(bidx, 0))
        gX = cute.local_tile(mX, tiler=(1, self.N), coord=(bidx, 0))
        gY, gX = gY[0, None], gX[0, None]
        print("[DSL INFO] Tiled Tensors:")
        print(f"[DSL INFO]   gY = {gY.type}")
        print(f"[DSL INFO]   gX = {gX.type}")
        tYgY = thr_copy.partition_S(gY)
        pred = cute.make_rmem_tensor(
            cute.size(tYgY, mode=[1]), cutlass.Boolean,
        )
        for i in range(cute.size(pred)):
            offset = (i * self.threads_per_cta + tidx) * self.elems_per_thread
            pred[i] = offset < self.N
        tXgX = thr_copy.partition_S(gX)
        tWgW = thr_copy.partition_S(mWeight)
        if cutlass.const_expr(self.norm_type == "layer"):
            tBgB = thr_copy.partition_S(mBias)
        tXrX = cute.make_fragment_like(tXgX)
        tXrX.fill(0)  # initialize rmem fragment to zero to simplify reduction code
        tWrW = cute.make_fragment_like(tWgW)
        if cutlass.const_expr(self.norm_type == "layer"):
            tBrB = cute.make_fragment_like(tBgB)
        print("[DSL INFO] Sliced Tensors per thread:")
        print(f"[DSL INFO]   tYgY = {tYgY.type}")
        print(f"[DSL INFO]   tXgX = {tXgX.type}")
        print(f"[DSL INFO]   tWgW = {tWgW.type}")
        if cutlass.const_expr(self.norm_type == "layer"):
            print(f"[DSL INFO]   tBgB = {tBgB.type}")
        print(f"[DSL INFO]   pred = {pred.type}")
        for i in range(cute.size(tXrX, mode=[1])):
            if pred[i]:
                cute.autovec_copy(tXgX[None, i], tXrX[None, i])  # LDG.128
                cute.autovec_copy(tWgW[None, i], tWrW[None, i])  # LDG.128
                if cutlass.const_expr(self.norm_type == "layer"):
                    cute.autovec_copy(tBgB[None, i], tBrB[None, i])  # LDG.128
        if cutlass.const_expr(self.norm_type == "layer"):
            tYrY = self.apply_layernorm(tXrX, tWrW, tBrB, eps, tidx, pred)
        elif cutlass.const_expr(self.norm_type == "rms"):
            tYrY = self.apply_rmsnorm(tXrX, tWrW, eps, tidx, pred)
        else:
            raise ValueError("norm_type must be 'layer' or 'rms'.")
        for i in range(cute.size(tXrX, mode=[1])):
            if pred[i]:
                cute.autovec_copy(tYrY[None, i], tYgY[None, i])  # STG.128
    

    @cute.jit
    def warp_reduce(self, val, reduce_size = 32):
        iters = int(math.log2(reduce_size))
        for i in range(iters):
            val = val + cute.arch.shuffle_sync_bfly(val, offset=1<<i)
        return val

    @cute.jit
    def cta_reduce(self, val, acc, tidx):
        warp_id = tidx >> 5
        lane_id = tidx & 31
        if lane_id == 0:
            acc[warp_id] = val
        cute.arch.sync_threads()
        if warp_id == 0:
            val = acc[lane_id] if lane_id < self.warps_per_cta else cutlass.Float32(0)
            val = self.warp_reduce(val)
            acc[self.warps_per_cta] = val
        cute.arch.sync_threads()
        val = acc[self.warps_per_cta]
        return val

    @cute.jit
    def apply_layernorm(
        self,
        x: cute.Tensor,
        weight: cute.Tensor,
        bias: cute.Tensor,
        eps: cute.Float,
        tidx: cutlass.Int32,
        pred: cute.Tensor,
    ):
        """
        mean = sum(x) / D
        var  = sum((x - mean) ^ 2) / D
        y[i] = (x[i] - mean) / sqrt(var + eps) * weight[i] + bias[i]
        """
        smem = cutlass.utils.SmemAllocator()
        acc = smem.allocate_tensor(cutlass.Float32, self.warps_per_cta + 1)
        # Reduce x
        val = cute.Float32(0.0)
        for idx in range(cute.size(x)):
            # Accumulate in FP32 to improve numerical precision.
            val += x[idx].to(cutlass.Float32)
        val = self.warp_reduce(val)
        val = self.cta_reduce(val, acc, tidx)
        mean = val / self.N
        # Reduce (x - mean) ^ 2
        val = cute.Float32(0.0)
        for i in range(cute.size(x, mode=[1])):
            if pred[i]:
                for idx in range(cute.size(x[None, i])):
                    # Accumulate in FP32 to improve numerical precision.
                    x_fp32 = x[None, i][idx].to(cutlass.Float32)
                    val += (x_fp32 - mean) * (x_fp32 - mean)
        val = self.warp_reduce(val)
        val = self.cta_reduce(val, acc, tidx)
        factor = cute.rsqrt(val / self.N + eps)
        # Normalize
        normed = cute.make_fragment_like(x)
        value = (x.load() - mean) * factor * weight.load() + bias.load()
        normed.store(value.to(normed.element_type))
        return normed

    
    @cute.jit
    def apply_rmsnorm(
        self,
        x: cute.Tensor,
        weight: cute.Tensor,
        eps: cute.Float,
        tidx: cutlass.Int32,
        pred: cute.Tensor,
    ):
        """
        y[i] = x[i] / sqrt(sum(x ^ 2) / D + eps) * w[i]
        """
        smem = cutlass.utils.SmemAllocator()
        acc = smem.allocate_tensor(cutlass.Float32, self.warps_per_cta + 1)
        val = cute.Float32(0.0)
        for i in range(cute.size(x, mode=[1])):
            if pred[i]:
                for idx in range(cute.size(x[None, i])):
                    # Accumulate in FP32 to improve numerical precision.
                    x_fp32 = x[None, i][idx].to(cutlass.Float32)
                    val += x_fp32 * x_fp32
        val = self.warp_reduce(val)
        acc_sq = self.cta_reduce(val, acc, tidx)
        factor = cute.rsqrt(acc_sq / self.N + eps)
        tNrN = cute.make_fragment_like(x)
        tNrN.store((x.load() * factor * weight.load()).to(tNrN.element_type))
        return tNrN


def run_layernorm(
    M: int,
    N: int,
    threads_per_cta: int,
    norm_type: str,
    dtype: Type[cutlass.Numeric],
    skip_ref_check=False,
    benchmark=True,
    warmup_iterations=2,
    iterations=200,
    eps=1e-6,
):
    if N % 8 > 0:
        raise ValueError(f"N = {N} must be a multiple of 8 for this example.")
    if threads_per_cta is not None:
        if threads_per_cta % 32 != 0 or not (0 < threads_per_cta <= 1024):
            raise ValueError(f"Invalid threads_per_cta = {threads_per_cta}")

    print("Running CtaNorm test with:")
    print(f"Tensor dimensions: [{M}, {N}]")
    print(f"Input and Output Data type: {dtype}")

    torch_dtype = cutlass_torch.dtype(dtype)
    x = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
    weight = torch.randn(N, device=torch.device("cuda"), dtype=torch_dtype)
    bias = None
    if norm_type == "layer":
        bias = torch.randn(N, device=torch.device("cuda"), dtype=torch_dtype)
    y = torch.empty_like(x)

    print("Input tensor shapes:")
    print(f"x: {x.shape}, dtype: {x.dtype}")
    print(f"weight: {weight.shape}, dtype: {weight.dtype}")
    if norm_type == "layer":
        print(f"bias: {bias.shape}, dtype: {bias.dtype}")
    print(f"y: {y.shape}, dtype: {y.dtype}\n")

    _x = from_dlpack(x, assumed_align=16, enable_tvm_ffi=True)
    _weight = from_dlpack(weight, assumed_align=16, enable_tvm_ffi=True)
    _bias = None
    if norm_type == "layer":
        _bias = from_dlpack(bias, assumed_align=16, enable_tvm_ffi=True)
    _y = from_dlpack(y, assumed_align=16, enable_tvm_ffi=True)

    print("Compiling kernel with cute.compile ...")
    start_time = time.time()
    layernorm = CtaNorm(N, norm_type, threads_per_cta)
    if norm_type == "layer":
        compiled_func = cute.compile(
            layernorm, _y, _x, _weight, _bias, options="--generate-line-info --enable-tvm-ffi",
        )
    else:
        compiled_func = cute.compile(
            layernorm, _y, _x, _weight, _bias, options="--generate-line-info --enable-tvm-ffi",
        )
    compilation_time = time.time() - start_time
    print(f"Compilation time: {compilation_time:.4f} seconds")

    print("Executing vector add kernel...")
    if not skip_ref_check:
        compiled_func(y, x, weight, bias, eps)
        print("Verifying results...")
        if norm_type == "layer":
            ref = torch.layer_norm(x, (N,), weight, bias, eps)
        else:
            ref = torch.rms_norm(x, (N,), weight, eps)
        torch.testing.assert_close(y, ref, atol=1e-3, rtol=1e-3)
        print("Results verified successfully!")

    if not benchmark:
        return

    def generate_tensors():
        x = torch.randn(M, N, device=torch.device("cuda"), dtype=torch_dtype)
        weight = torch.randn(N, device=torch.device("cuda"), dtype=torch_dtype)
        bias = None
        if norm_type == "layer":
            bias = torch.randn(N, device=torch.device("cuda"), dtype=torch_dtype)
        y = torch.empty_like(x)
        return testing.JitArguments(y, x, weight, bias, eps)

    def torch_ref(y, x, weight, bias, eps):
        if norm_type == "layer":
            y = torch.layer_norm(x, (N,), weight, bias, eps)
        else:
            y = torch.rms_norm(x, (N,), weight, eps)

    def eval(func, name):
        avg_time_us = testing.benchmark(
            func,
            workspace_generator=generate_tensors,
            workspace_count=10,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
        )

        # Print execution results
        print(f"\n{name}")
        print(f"Kernel execution time: {avg_time_us / 1e3:.4f} ms")
        print(
            f"Achieved memory throughput: {(2 * (x.numel() + weight.numel()) * dtype.width // 8) / (avg_time_us / 1e6) / 1e9:.2f} GB/s"
        )

    eval(compiled_func, f"CuTe {norm_type}norm kernel")
    eval(torch_ref, f"PyTorch {norm_type}norm reference")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="example of elementwise add to demonstrate the numpy/pytorch as input for kernels"
    )
    parser.add_argument("--M", default=4096, type=int)
    parser.add_argument("--N", default=4096, type=int)
    parser.add_argument(
        "--dtype",
        default="fp16",
        choices=DTYPE_MAP.keys(),
        help="Data type for input/output tensors (e.g. float16, bf16, float32)",
    )
    parser.add_argument("--norm_type", choices=["layer", "rms"], default="layer", type=str)
    parser.add_argument("--threads", default=None, type=int)
    parser.add_argument("--warmup_iterations", default=2, type=int)
    parser.add_argument("--iterations", default=100, type=int)
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument("--benchmark", action="store_true")

    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    run_layernorm(
        args.M,
        args.N,
        args.threads,
        args.norm_type,
        dtype=cutlass.Float16,
        skip_ref_check=args.skip_ref_check,
        benchmark=args.benchmark,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
    )
    print("\nPASS")