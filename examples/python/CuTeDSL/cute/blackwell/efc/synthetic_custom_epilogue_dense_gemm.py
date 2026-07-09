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

import traceback
import typing

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch

from common_dense_gemm_efc import DenseGemmEFC
import common_efc

"""
A high-performance persistent batched dense GEMM (D = alpha * A * B + beta * C) example for the NVIDIA Blackwell SM100 architecture
using CUTE DSL.
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")
- Matrix D is MxNxL, L is batch dimension, D can be row-major("N") or column-major("M")
- alpha and beta are float scalars

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Support warp specialization to avoid explicit pipelining between mainloop load and mma

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp:
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Load C matrix from global memory (GMEM) to shared memory (SMEM) using TMA operations and then copied to registers (RMEM).
    - Compute D = alpha * accumulator + beta * C.
    - Type convert D matrix to output type.
    - Store D matrix from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations,
    - Optionally accept an elementwise lambda function epilogue_op to apply to the output tensor:
      e.g., relu can set epilogue_op = lambda x: cute.where(x > 0, x, cute.full_like(x, 0))

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Input arguments to this example is same as dense_gemm.py.

.. code-block:: bash

    python examples/internal/blackwell/epilogue/synthetic_custom_epilogue_dense_gemm.py \
      --ab_dtype Float16 --c_dtype Float16 --d_dtype Float16 --acc_dtype Float32 --epi_dtype Float32 \
      --mma_tiler_mn 256,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 2.0 --beta 1.0 --t_dtype Float32 --read_tensors 2 --written_tensors 3

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/internal/blackwell/epilogue/synthetic_custom_epilogue_dense_gemm.py \
      --ab_dtype Float16 --c_dtype Float16 --d_dtype Float16 --acc_dtype Float32 --epi_dtype Float32 \
      --mma_tiler_mn 256,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 2.0 --beta 1.0 --t_dtype Float32 --read_tensors 2 --written_tensors 3 \
      --warmup_iterations 1 --iterations 10 --skip_ref_check


Constraints are same as dense_gemm.py:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2),
  see detailed valid dtype combinations in below SM100PersistentDenseGemmAlphaBetaKernel class documentation
* A/B tensor must have the same data type
* C/D tensor must have the same major order
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* Mma tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of A/B/C/D tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* OOB tiles are not allowed when TMA store is disabled
"""


def format_as_cli_args(
    mnkl: typing.Tuple[int, int, int, int],
    ab_dtype: typing.Type[cutlass.Numeric],
    acc_dtype: typing.Type[cutlass.Numeric],
    epi_dtype: typing.Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    cd_major: str,
    mma_tiler_mn: typing.Tuple[int, int],
    cluster_shape_mn: typing.Tuple[int, int],
    use_2cta_instrs: bool,
    t_dtype: typing.Type[cutlass.Numeric],
    alpha: float,
    beta: float,
    read_tensors: int,
    written_tensors: int,
    tolerance: float,
) -> str:
    """Format test parameters as CLI arguments for synthetic_custom_epilogue_dense_gemm.py"""

    # Get base command from DenseGemmEFC class
    base_cmd = DenseGemmEFC.format_as_cli_args(
        "synthetic_custom_epilogue_dense_gemm.py",
        mnkl,
        ab_dtype,
        acc_dtype,
        epi_dtype,
        a_major,
        b_major,
        cd_major,
        mma_tiler_mn,
        cluster_shape_mn,
        use_2cta_instrs,
        tolerance,
    )

    # Add synthetic epilogue-specific parameters
    specific_args = (
        f" --alpha {alpha} "
        f"--beta {beta} "
        f"--t_dtype {DenseGemmEFC.dtype_name(t_dtype)} "
        f"--read_tensors {read_tensors} "
        f"--written_tensors {written_tensors}"
    )

    return base_cmd + specific_args


def run(
    mnkl: typing.Tuple[int, int, int, int],
    ab_dtype: typing.Type[cutlass.Numeric],
    acc_dtype: typing.Type[cutlass.Numeric],
    epi_dtype: typing.Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    cd_major: str,
    alpha: float,
    beta: float,
    t_dtype: typing.Type[cutlass.Numeric],
    mma_tiler_mn: typing.Tuple[int, int],
    cluster_shape_mn: typing.Tuple[int, int],
    use_2cta_instrs: bool,
    tolerance: float,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    read_tensors: int = 1,
    written_tensors: int = 1,
    verbose: bool = False,
):
    """
    Prepare A/B/C/D tensors, launch GPU kernel, and reference checking.
    """
    print("Running Blackwell Persistent Dense GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, Acc dtype: {acc_dtype}, Epi dtype: {epi_dtype}")
    print(
        f"Matrix majors - A: {a_major}, B: {b_major}, loaded: {cd_major}, stored: {cd_major}"
    )
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"2CTA MMA instructions: {'True' if use_2cta_instrs else 'False'}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")
    print("Epilogue:")
    print(f"\t{alpha = }, {beta = }")
    print(f"\t{t_dtype = !s}")
    print(f"\t{read_tensors = }, {written_tensors = }")

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    def meta_epilogue(read_tensors, written_tensors):
        """Build a synthetic epilogue function with parameters
        (self, alpha, beta, read_t0, read_t1,..., read_t{read__tensors-1}, written_t0, written_t1,..., written_t{written_tensors-1}"""

        param_names = (
            ["efc_config", "alpha", "beta"]
            + [f"read_t{i}" for i in range(read_tensors)]
            + [f"written_t{i}" for i in range(written_tensors)]
        )

        assert written_tensors > 0, (
            "At least one tensor must be written in the epilogue."
        )

        def computation_impl(efc_config, alpha, beta, *tensors):
            """Implementation of the epilogue computation."""
            read = beta
            for tensor in tensors[:read_tensors]:
                read += tensor.load() * alpha
            if read_tensors > 0:
                # Can use some CuTe/PyTorch-like functions exposed under
                # efc_config namespace for portability:
                read = efc_config.where(
                    read < 1, read, read * efc_config.full_like(read, 2)
                )

            t = efc_config.accum()
            for tensor in tensors[read_tensors:]:
                t = t * alpha + read + 5000
                tensor.store(t)

        # Wrap the implementation with a function with the correct parameter
        # names.
        return common_efc.create_named_epilogue(param_names, computation_impl)

    epilogue = meta_epilogue(read_tensors, written_tensors)

    # Build GEMM object with EFC configuration:
    # TODO: generalize acc_dtype and epi_dtype
    gemm = DenseGemmEFC(
        acc_dtype,
        epi_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cluster_shape_mn,
        epilogue,
    )
    (
        a_tensor,
        b_tensor,
        a_torch_cpu,
        b_torch_cpu,
    ) = gemm.create_arguments(l, m, n, k, a_major, b_major, cd_major, ab_dtype)

    # Create all the supplemental tensors.
    t_torch_cpu, t_torch_gpu, t_tensor = ([], [], [])
    for i in range(read_tensors + written_tensors):
        t_torch_cpu.append(cutlass_torch.matrix(l, m, n, cd_major == "m", t_dtype))
        tensor, torch_gpu = cutlass_torch.cute_tensor_like(
            t_torch_cpu[i], t_dtype, is_dynamic_layout=True, assumed_align=16
        )
        t_tensor.append(tensor)
        t_torch_gpu.append(torch_gpu)

    # Check if configuration can be implemented
    gemm.check_implementable(a_tensor, b_tensor, t_tensor[0])

    max_active_clusters = cutlass.utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    compiled_gemm = gemm.compile(
        a_tensor,
        b_tensor,
        max_active_clusters,
        current_stream,
        # Here are the supplemental arguments in the same order as for the
        # epilogue configuration function.
        alpha,
        beta,
        *t_tensor,
    )
    torch.cuda.synchronize()

    # TODO: unify with modern way to do benchmarking.
    exec_time = testing.benchmark(
        compiled_gemm,
        kernel_arguments=testing.JitArguments(
            a_tensor,
            b_tensor,
            current_stream,
            # Here are the supplemental arguments in the same order as for the
            # epilogue configuration function.
            alpha,
            beta,
            *t_tensor,
        ),
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    print(f"Execution time: {exec_time} us")

    # Evaluate the epilogue on the host:
    gemm.evaluate_on_cpu(
        a_torch_cpu,
        b_torch_cpu,
        epi_dtype,
        # The EFC arguments:
        alpha,
        beta,
        *t_torch_cpu,
    )

    # Print tensors if verbose mode is enabled
    if verbose:
        print("\n=== Read Tensors ===")
        for i in range(read_tensors):
            print(f"\nRead Tensor {i} (GPU):")
            print(t_torch_gpu[i].cpu())

        print("\n=== Written Tensors ===")
        for i in range(written_tensors):
            idx = read_tensors + i
            print(f"\nWritten Tensor {i} (GPU):")
            print(t_torch_gpu[idx].cpu())
        print()

    # Assert close results between the values computed on GPU and CPU.
    for torch_gpu, torch_cpu in zip(t_torch_gpu, t_torch_cpu):
        torch.testing.assert_close(
            torch_gpu.cpu(), torch_cpu, atol=tolerance, rtol=1e-03
        )


if __name__ == "__main__":
    cli = DenseGemmEFC.CLIParser()
    cli.parser.add_argument(
        "--alpha", type=float, default=1.0, help="alpha scale factor"
    )
    cli.parser.add_argument("--beta", type=float, default=0.0, help="beta scale factor")
    cli.parser.add_argument("--t_dtype", type=cutlass.dtype, default=cutlass.Float32)
    cli.parser.add_argument(
        "--read_tensors",
        type=int,
        default=1,
        help="number of tensors to read inside the epilogue",
    )
    cli.parser.add_argument(
        "--written_tensors",
        type=int,
        default=1,
        help="number of tensors to write inside the epilogue",
    )
    cli.parser.add_argument(
        "--verbose",
        action="store_true",
        help="print read and written tensors",
    )
    args = cli.parse()

    try:
        run(
            args.mnkl,
            args.ab_dtype,
            args.acc_dtype,
            args.epi_dtype,
            args.a_major,
            args.b_major,
            args.cd_major,
            args.alpha,
            args.beta,
            args.t_dtype,
            args.mma_tiler_mn,
            args.cluster_shape_mn,
            args.use_2cta_instrs,
            args.tolerance,
            args.warmup_iterations,
            args.iterations,
            args.skip_ref_check,
            args.read_tensors,
            args.written_tensors,
            args.verbose,
        )
        print("PASS")
    except Exception as exc:
        traceback.print_exception(exc)
        raise
