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

"""
Back-to-Back GEMMs with Data-Driven Synchronization (TMA report_valid)

Runs a chain of N back-to-back GEMMs, where the
output of each GEMM feeds into the next as its B operand.

For user-supplied ``--nk n,k`` (shared N and the first GEMM's K) and
``--m_list m_0,m_1,...,m_{N-1}`` the kernels compute, for i = 0..N-1:

    z_i[m_i, n] = einsum("mk,kn->mn", w_i[m_i, k_i], b_i[k_i, n])

where b_0 = x and b_i = z_{i-1}, so k_0 = k and k_i = m_{i-1}. The GEMMs are
chained through each GEMM's M-dim (which is the next GEMM's K-dim), so each z_i
appears as the B operand of GEMM i+1.

All kernels fully overlap execution with PDL and synchronize using the
activation buffer data: each intermediate output buffer is initialized to a
sentinel value (-0.0), and the consuming GEMM speculatively loads the producer's tiles
via TMA report_valid.

See README_tma_report_valid.md for more details.

To run this example:
.. code-block:: bash
    python examples/rubin/run_b2b_gemms_tma_report_valid.py --nk 1024,1024 --m_list 1024,2048 --benchmark
    python examples/rubin/run_b2b_gemms_tma_report_valid.py --nk 1024,1024 --m_list 512,1024,2048 --benchmark
"""

import argparse
import math
import os
import sys
from typing import Tuple, Type

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.utils as utils
from cutlass import testing
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # Imported sibling kernels also need the CuTeDSL root to resolve helpers.
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from rubin.kernel.dense_gemm.dense_gemm_persistent_tma_report_valid import (
    compile_bmm,
)

acc_dtype = cutlass.Float32


def run_producer_consumer_gemms(
    nk: Tuple[int, int],
    m_list: Tuple[int, ...],
    tolerance: float,
    use_2cta_instrs: bool,
    use_graphs: bool,
    cluster_shape_mn: Tuple[int, int],
    use_report_valid: bool,
    use_pdl: bool,
    benchmark: bool = False,
    warmup_iterations: int = 10,
    iterations: int = 100,
    chunk_size: int = None,
    standalone: bool = False,
    mma_tiler_mn: Tuple[int, int] = None,
    check_samples: int = 1,
    raster_along: str = "m",
    eager_launch_next: bool = True,
    check_l2_camping: bool = True,
    producer_sentinel_init: bool = False,
    io_dtype: Type[cutlass.Numeric] = cutlass.Float16,
):
    if mma_tiler_mn is None:
        mma_tiler_mn = (256, 128) if use_2cta_instrs else (128, 128)

    m_list = tuple(int(x) for x in m_list)
    num_gemms = len(m_list)
    if num_gemms < 2:
        raise ValueError("m_list must contain at least 2 GEMMs")

    sm_count = utils.HardwareInfo().get_device_multiprocessor_count()

    n, k = nk
    l = 1  # batch size

    k_list = (k,) + m_list[:-1]
    mnkl_list = [(m_list[i], n, k_list[i], l) for i in range(num_gemms)]

    def b_name(i):
        return "x" if i == 0 else f"z{i - 1}"

    print(f"[DSL INFO] Running Rubin {io_dtype.__name__} back-to-back GEMMs with:")
    print(f"[DSL INFO]   num_gemms: {num_gemms}, n: {n}, k: {k}, m_list: {m_list}")
    print(f"[DSL INFO]   use_report_valid: {use_report_valid}, use_pdl: {use_pdl}")
    print(f"[DSL INFO]   use_2cta_instrs: {use_2cta_instrs}")
    print(
        f"[DSL INFO]   mma_tiler_mn: {mma_tiler_mn}, cluster_shape_mn: {cluster_shape_mn}"
    )
    print(f"[DSL INFO]   sm_count: {sm_count}, tolerance: {tolerance}")

    torch.manual_seed(1111)

    torch_dtype = cutlass_torch.dtype(io_dtype)
    c_major = "m"

    def rand(*shape, scale=1.0):
        t = (
            torch.empty(l, *shape, dtype=torch.int32, device="cuda")
            .random_(-1, 2)
            .to(torch_dtype)
        )
        return (t * scale).to(torch_dtype) if scale != 1.0 else t

    def make_z(i, fill):
        return torch.full(
            (l, n, m_list[i]), fill, dtype=torch_dtype, device="cuda"
        ).permute(0, 2, 1)

    def z_fill(i):
        # Last GEMM = real result (+0.0). Earlier GEMMs feed a data-driven consumer: host
        # pre-fills the -0.0 sentinel, unless producer_sentinel_init has the kernel write
        # it (host fills 1.0 to prove the sentinel came from the kernel, not the host).
        if i == num_gemms - 1:
            return 0.0
        return 1.0 if producer_sentinel_init else -0.0

    def alloc_tensors(mode="all"):
        """Allocate the full chain or one standalone GEMM.

        Standalone runs use random B input because a data-driven consumer would spin
        on sentinel-initialized input without a producer.
        """
        if mode != "all":
            i = int(mode)
            return {
                f"w{i}": rand(m_list[i], k_list[i], scale=1.0 / math.sqrt(k_list[i])),
                b_name(i): rand(n, k_list[i]).permute(0, 2, 1),
                f"z{i}": make_z(i, 0.0),
            }

        tensors = {"x": rand(n, k).permute(0, 2, 1)}
        for i in range(num_gemms):
            tensors[f"w{i}"] = rand(
                m_list[i], k_list[i], scale=1.0 / math.sqrt(k_list[i])
            )
        for i in range(num_gemms):
            tensors[f"z{i}"] = make_z(i, z_fill(i))
        return tensors

    def to_memrefs(tensors):
        """Convert tensors to memrefs, inferring the leading dim from the name."""
        memrefs = {}
        for name, tensor in tensors.items():
            if name == "x":
                leading_dim = 1
            elif name.startswith("w"):
                leading_dim = 2
            elif name.startswith("z"):
                leading_dim = 1
            else:
                raise ValueError(f"Unexpected tensor name: {name}")
            memrefs[name] = from_dlpack(tensor).mark_layout_dynamic(
                leading_dim=leading_dim
            )
        return memrefs

    torch_stream = torch.cuda.Stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Workaround: testing.benchmark()'s driver-API CUDA events must share the stream's
    # (primary) context, so swap to it for this call and restore afterwards.
    _saved_ctx = cuda.cuCtxGetCurrent()[1]

    def _sync_driver_ctx():
        """Set the driver-API context to match the stream's context so that
        cuEventCreate/cuEventRecord in testing.benchmark() use the same
        context as the stream (which lives in the primary context)."""
        err, ctx = cuda.cuStreamGetCtx(current_stream)
        if err == cuda.CUresult.CUDA_SUCCESS and ctx is not None:
            cuda.cuCtxSetCurrent(ctx)

    def _restore_driver_ctx():
        """Restore the driver-API context that was current before we switched."""
        if _saved_ctx is not None:
            cuda.cuCtxSetCurrent(_saved_ctx)

    _sync_driver_ctx()

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    tensors = alloc_tensors()
    memrefs = to_memrefs(tensors)

    print("Tensor shapes and memref leading dims:")
    for name, tensor in tensors.items():
        print(f"  {name}: shape={tuple(tensor.shape)}, strides={tensor.stride()}")
    for name, memref in memrefs.items():
        print(f"  {name} memref: {memref}")

    def compile_one(
        mnkl,
        a,
        b,
        c,
        pdl_early_launch_next,
        pdl_early_start,
        use_report_valid,
        eager_launch_next,
        epilogue_op=lambda x: x,
        producer_sentinel_init=False,
        positive_zero_only=False,
    ):
        return compile_bmm(
            mnkl,
            a,
            b,
            c,
            acc_dtype,
            a_major="k",
            b_major="k",
            c_major=c_major,
            mma_tiler=mma_tiler_mn,
            cluster_shape_mn=cluster_shape_mn,
            max_active_clusters=max_active_clusters,
            use_2cta_instrs=use_2cta_instrs,
            use_tma_store=True,
            pdl_early_launch_next=pdl_early_launch_next,
            pdl_early_start=pdl_early_start,
            check_b_valid=use_report_valid,
            eager_launch_next=eager_launch_next,
            raster_along=raster_along,
            epilogue_op=epilogue_op,
            producer_sentinel_init=producer_sentinel_init,
            positive_zero_only=positive_zero_only,
        )

    compiled = []
    for i in range(num_gemms):
        is_first = i == 0
        is_last = i == num_gemms - 1
        # First: launches successor early but is not itself started early.
        # Middle: launched early and launches its successor early.
        # Last: launched early but has no successor to launch.
        # With --no-use_pdl both PDL flags are False: sequential execution.
        pdl_early_launch_next = use_pdl and not is_last
        pdl_early_start = use_pdl and not is_first
        # First kernel has real B input; only subsequent kernels check B validity.
        kernel_use_report_valid = use_report_valid and not is_first
        # A GEMM whose output the next GEMM consumes via report_valid loads writes the sentinel
        # itself (instead of the host pre-filling it) when producer_sentinel_init.
        kernel_producer_sentinel_init = (
            producer_sentinel_init and use_report_valid and not is_last
        )
        print(
            f"[DSL INFO] Compiling GEMM {i}/{num_gemms - 1} "
            f"(pdl_early_launch_next={pdl_early_launch_next}, pdl_early_start={pdl_early_start}, "
            f"use_report_valid={kernel_use_report_valid}, "
            f"producer_sentinel_init={kernel_producer_sentinel_init})..."
        )

        # A producer must not store the -0.0 sentinel into a consumed
        # buffer (would hang the consumer); positive_zero_only makes the epilogue
        # convert -0.0 -> +0.0 before storing to gmem.
        compiled.append(
            compile_one(
                mnkl_list[i],
                memrefs[f"w{i}"],
                memrefs[b_name(i)],
                memrefs[f"z{i}"],
                pdl_early_launch_next,
                pdl_early_start,
                kernel_use_report_valid,
                eager_launch_next,
                producer_sentinel_init=kernel_producer_sentinel_init,
                positive_zero_only=use_report_valid,
            )
        )
        print("[DSL INFO] Done.")

    standalone_compiled = None
    if standalone:
        standalone_compiled = []
        for i in range(num_gemms):
            # Isolate each kernel (no PDL overlap) but keep the data-driven sync overhead:
            # report_valid loads, sentinel init, and pzo canonicalization.
            print(f"[DSL INFO] Compiling GEMM {i} standalone (no PDL)...")
            standalone_compiled.append(
                compile_one(
                    mnkl_list[i],
                    memrefs[f"w{i}"],
                    memrefs[b_name(i)],
                    memrefs[f"z{i}"],
                    False,
                    False,
                    use_report_valid,
                    True,  # eager_launch_next
                    producer_sentinel_init=producer_sentinel_init,
                    positive_zero_only=True,
                )
            )
            print("[DSL INFO] Done.")

    def check_reference(t):
        """Check each stage against fp32 using the previous stage's actual output."""
        x_f32 = t["x"][0].cpu().float()  # (k, n)
        for i in range(num_gemms):
            w_f32 = t[f"w{i}"][0].cpu().float()  # (m_i, k_i)
            b_f32 = x_f32 if i == 0 else t[f"z{i - 1}"][0].cpu().float()  # (k_i, n)
            fmax = torch.finfo(torch_dtype).max
            ref = (w_f32 @ b_f32).clamp(min=-fmax, max=fmax)

            z = t[f"z{i}"][0].cpu()
            assert not torch.isinf(z).any(), f"z{i} contains inf values"
            assert not torch.isnan(z).any(), f"z{i} contains nan values"
            torch.testing.assert_close(
                z,
                ref.to(torch_dtype),
                atol=tolerance,
                rtol=1e-05,
            )

    def to_bench(**kw):
        for i in range(num_gemms):
            compiled[i](kw[f"w{i}"], kw[b_name(i)], kw[f"z{i}"], current_stream)

    def make_standalone_bench(idx):
        def _bench(**kw):
            standalone_compiled[idx](
                kw[f"w{idx}"], kw[b_name(idx)], kw[f"z{idx}"], current_stream
            )

        return _bench

    def make_workspace_generator(mode="all"):
        def gen():
            t = alloc_tensors(mode)
            gen.captured.append(t)
            m = to_memrefs(t)
            return testing.JitArguments(**m)

        gen.captured = []
        return gen

    if not benchmark:
        warmup_iterations = 0
        iterations = 1

    warmup_iterations = min(warmup_iterations, iterations)

    flop_per_gemm = [2 * m_list[i] * n * k_list[i] for i in range(num_gemms)]
    total_flop = sum(flop_per_gemm)

    bytes_per_elem = io_dtype.width // 8
    # Per GEMM traffic: read A (m*k) + read B (k*n) + write C (m*n).
    bytes_per_gemm = [
        (m_list[i] * k_list[i] + n * k_list[i] + m_list[i] * n) * bytes_per_elem
        for i in range(num_gemms)
    ]
    total_bytes = sum(bytes_per_gemm)

    if standalone:

        def numbytes(tensor):
            return tensor.numel() * tensor.element_size()

        for i in range(num_gemms):
            bytes_i = sum(numbytes(v) for v in alloc_tensors(i).values())
            ws_count_i = testing.get_workspace_count(
                bytes_i, warmup_iterations, iterations
            )
            print(f"Benchmarking GEMM {i} standalone (use_pdl=False)...")
            print(
                f"Workspace count: {ws_count_i}, warmup: {warmup_iterations}, iterations: {iterations}"
            )
            exec_time_i = testing.benchmark(
                make_standalone_bench(i),
                workspace_generator=make_workspace_generator(i),
                workspace_count=ws_count_i,
                stream=current_stream,
                warmup_iterations=warmup_iterations,
                iterations=iterations,
                use_cuda_graphs=use_graphs,
            )
            exec_time_i = max(exec_time_i, 1e-12)
            print(
                f"Execution time GEMM {i} standalone: {exec_time_i:.1f} us per iteration"
            )
            print(
                f"Bandwidth GEMM {i} standalone: "
                f"{bytes_per_gemm[i] / (exec_time_i * 1e-6) * 1e-9:.1f} GB/s"
            )
            print(
                f"TFLOPS GEMM {i} standalone: "
                f"{flop_per_gemm[i] / (exec_time_i * 1e-6) * 1e-12:.1f}"
            )
            print("--------------------------------")

    if chunk_size is None or chunk_size > iterations:
        chunk_size = iterations
    num_chunks = (iterations + chunk_size - 1) // chunk_size
    warmup_replays = max(1, (warmup_iterations + chunk_size - 1) // chunk_size)
    total_iters = num_chunks * chunk_size

    print(f"Benchmarking {num_gemms}-GEMM chain (use_pdl={use_pdl})...")
    print(
        f"chunk_size: {chunk_size}, num_chunks: {num_chunks}, "
        f"warmup_replays: {warmup_replays}, total_iters: {total_iters}"
    )

    # Reuse one set of chunk_size chained-GEMM buffers across all chunks; each is
    # a full independent chain run, matching benchmark's workspace cycling.
    buffers = [alloc_tensors("all") for _ in range(chunk_size)]
    buffer_memrefs = [to_memrefs(t) for t in buffers]

    # Throw error if L2 camping detected
    if benchmark and num_chunks > 1 and check_l2_camping:
        chunk_bytes = sum(
            t.numel() * t.element_size() for buf in buffers for t in buf.values()
        )
        l2_bytes = utils.HardwareInfo().get_l2_cache_size_in_bytes()
        if chunk_bytes < l2_bytes:
            raise ValueError(
                f"Chunk working set {chunk_bytes} B < L2 cache {l2_bytes} B: "
                f"risks L2 camping. Increase --chunk_size (currently {chunk_size})."
            )

    def run_chunk_launches():
        for m in buffer_memrefs:
            to_bench(**m)

    def reset_buffers():
        # Data-driven sync needs a fresh sentinel buffer per run; restore z between chunks.
        with torch.cuda.stream(torch_stream):
            for t in buffers:
                for i in range(num_gemms):
                    t[f"z{i}"].fill_(z_fill(i))

    graph = None
    if use_graphs:
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(
            graph, stream=torch_stream, capture_error_mode="thread_local"
        ):
            run_chunk_launches()

    def replay():
        if use_graphs:
            with torch.cuda.stream(torch_stream):
                graph.replay()
        else:
            run_chunk_launches()

    for _ in range(warmup_replays):
        reset_buffers()
        replay()

    start_events = [torch.cuda.Event(enable_timing=True) for _ in range(num_chunks)]
    end_events = [torch.cuda.Event(enable_timing=True) for _ in range(num_chunks)]
    for c in range(num_chunks):
        reset_buffers()
        start_events[c].record(torch_stream)
        replay()
        end_events[c].record(torch_stream)

    end_events[-1].synchronize()
    total_ms = sum(s.elapsed_time(e) for s, e in zip(start_events, end_events))

    exec_time = max(total_ms * 1e3 / total_iters, 1e-12)
    flops = total_flop / (exec_time * 1e-6)
    bw = total_bytes / (exec_time * 1e-6)
    print(
        f"[DSL INFO] Execution time {num_gemms}-GEMM chain: {exec_time:.1f} us per iteration"
    )
    print(f"[DSL INFO] TFLOPS {num_gemms}-GEMM chain: {flops * 1e-12:.1f}")
    print(f"[DSL INFO] Bandwidth {num_gemms}-GEMM chain: {bw * 1e-9:.1f} GB/s")
    torch.cuda.synchronize()

    if check_samples > 0:
        import random

        n_samples = min(check_samples, len(buffers))
        samples = random.sample(buffers, n_samples)
        print(
            f"[DSL INFO] Checking {n_samples} sampled benchmark buffers for correctness..."
        )
        for i, t in enumerate(samples):
            check_reference(t)
            print(f"  Sample {i + 1}/{n_samples} passed.")
        print(f"[DSL INFO] All {n_samples} sampled buffers passed correctness check.")

    _restore_driver_ctx()

    return exec_time


def prepare_parser():
    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Rubin fp16 back-to-back GEMMs with data-based producer-consumer synchronization"
    )
    parser.add_argument(
        "--nk",
        type=parse_comma_separated_ints,
        default=(1024, 1024),
        help="Shared N and first GEMM's K (comma-separated). "
        "Per-GEMM M dims come from --m_list.",
    )
    parser.add_argument(
        "--m_list",
        type=parse_comma_separated_ints,
        default=(1024, 1024),
        help="Per-GEMM M dims (comma-separated), one per GEMM in the chain. "
        "N = len(m_list). If a single value is given, it is broadcast to "
        "--num_gemms GEMMs.",
    )
    parser.add_argument(
        "--num_gemms",
        type=int,
        default=None,
        help="Number of GEMMs in the chain. Used to broadcast a single-value "
        "--m_list to this many GEMMs. Cannot be combined with a multi-value "
        "--m_list (which already specifies the chain length).",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--io_dtype",
        choices=["fp16", "bf16"],
        default="fp16",
        help="A/B/C element type",
    )
    parser.add_argument(
        "--use_2cta",
        action="store_true",
        default=False,
        help="Use 2CTA MMA instructions feature",
    )
    parser.add_argument(
        "--use_graphs",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Use CUDA graphs",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument(
        "--benchmark",
        action="store_true",
        default=False,
        help="Benchmark the kernel",
    )
    parser.add_argument(
        "--use_report_valid",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Use data-driven synchronization (TMA report_valid loads). --no-use_report_valid keeps PDL "
        "launch ordering but waits for the predecessor before data loads.",
    )
    parser.add_argument(
        "--use_pdl",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Use PDL (Programmatic Dependent Launch)",
    )
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=10,
        help="Number of warmup iterations (default: 10)",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=100,
        help="Number of benchmark iterations (default: 100)",
    )
    parser.add_argument(
        "--chunk_size",
        type=int,
        default=None,
        help="Iterations per chunk. Buffers are preallocated once per chunk and "
        "reset to the sentinel between chunks, so peak memory scales with "
        "chunk_size, not --iterations. Default: chunk_size = iterations (one chunk).",
    )
    parser.add_argument(
        "--standalone",
        action="store_true",
        default=False,
        help="Also compile and benchmark each GEMM standalone",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=None,
        help="MMA tiler MN dimensions (comma-separated). Default: (128,128) for 1CTA, (256,128) for 2CTA",
    )
    parser.add_argument(
        "--raster_along",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Raster tiles along 'm' or 'n' axis",
    )
    parser.add_argument(
        "--check_samples",
        type=int,
        default=1,
        help="Number of sampled workspace buffers to verify for correctness. "
        "Set to 0 to skip all reference checks.",
    )
    parser.add_argument(
        "--eager_launch_next",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Fire griddepcontrol_launch_dependents at kernel start. "
        "--no-eager_launch_next defers it to after all TMA loads "
        "(ab_producer.tail()). Orthogonal to --use_report_valid; default True for both modes.",
    )
    parser.add_argument(
        "--check_l2_camping",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Error out when a chunk's working set fits in L2 (risks L2 camping "
        "and inflated TFLOPS). --no-check_l2_camping skips the check, e.g. for "
        "small shapes benchmarked only to stress a race rather than measure perf.",
    )
    parser.add_argument(
        "--producer_sentinel_init",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Have each producer GEMM in the data-driven chain write the -0.0 sentinel to its own "
        "output before preexit, instead of the caller pre-filling it. Trades some "
        "producer-side cost (often hidden) for a simpler caller.",
    )
    return parser


if __name__ == "__main__":
    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)
    err, device_count = cu_driver.cuDeviceGetCount()
    if err != cu_driver.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A GPU is required to run this example")

    parser = prepare_parser()
    args = parser.parse_args()

    if len(args.nk) != 2:
        parser.error("--nk must contain exactly 2 values")

    m_list = tuple(args.m_list)
    if len(m_list) > 1:
        if args.num_gemms is not None:
            parser.error("--num_gemms cannot be combined with a multi-value --m_list")
    else:
        if args.num_gemms is None:
            parser.error(
                "provide --num_gemms (>= 2) with a single-value --m_list, "
                "or pass a multi-value --m_list"
            )
        if args.num_gemms < 2:
            parser.error("--num_gemms must be >= 2")
        m_list = m_list * args.num_gemms

    run_producer_consumer_gemms(
        tuple(args.nk),
        m_list,
        args.tolerance,
        args.use_2cta,
        args.use_graphs,
        tuple(args.cluster_shape_mn),
        args.use_report_valid,
        args.use_pdl,
        benchmark=args.benchmark,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        chunk_size=args.chunk_size,
        standalone=args.standalone,
        mma_tiler_mn=tuple(args.mma_tiler_mn) if args.mma_tiler_mn else None,
        check_samples=args.check_samples,
        raster_along=args.raster_along,
        eager_launch_next=args.eager_launch_next,
        check_l2_camping=args.check_l2_camping,
        producer_sentinel_init=args.producer_sentinel_init,
        io_dtype={"fp16": cutlass.Float16, "bf16": cutlass.BFloat16}[args.io_dtype],
    )
    print("PASS")
