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

# Required for pre-Python 3.12 instead of typing.override.
from typing_extensions import override
import torch

import cutlass
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch

from common_dense_gemm_efc import DenseGemmEFC

"""
A high-performance persistent batched dense GEMM with custom epilogue fusion for the NVIDIA Blackwell SM100 architecture
using CUTE DSL and Epilogue Fusion Configuration (EFC).

This example demonstrates a GEMM with a custom fused epilogue that performs:
  Y = A * B (accumulator stored to Y)
  D = (A * B) * alpha + C * beta + X * x_factor

Tensor dimensions:
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL (read-only input), C can be row-major("N") or column-major("M")
- Matrix D is MxNxL (output), D can be row-major("N") or column-major("M")
- Matrix X is MxNxL (read-only input), same layout as C/D
- Matrix Y is MxNxL (output), same layout as C/D
- alpha, beta, and x_factor are scalar scale factors

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Supports persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Supports warp specialization to avoid explicit pipelining between mainloop load and mma
    - Uses Epilogue Fusion Configuration (EFC) to define custom epilogue operations

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp (defined via EFC):
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Load C and X matrices from global memory (GMEM) to shared memory (SMEM) using TMA, then to registers (RMEM).
    - Compute Y = accumulator (copy of A*B result)
    - Compute D = accumulator * alpha + C * beta + X * x_factor
    - Type convert D and Y matrices to output types.
    - Store D and Y matrices from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Example usage:

.. code-block:: bash

    python custom_epilogue_dense_gemm.py \
      --ab_dtype Float16 --c_dtype Float16 --d_dtype Float16 --acc_dtype Float32 --epi_dtype Float32 \
      --x_dtype Float16 --y_dtype Float16 \
      --mma_tiler_mn 128,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 2.0 --beta 1.0 --x_factor 3.0

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python custom_epilogue_dense_gemm.py \
      --ab_dtype Float16 --c_dtype Float16 --d_dtype Float16 --acc_dtype Float32 --epi_dtype Float32 \
      --x_dtype Float16 --y_dtype Float16 \
      --mma_tiler_mn 128,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 2.0 --beta 1.0 --x_factor 3.0 \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2)
* A/B tensors must have the same data type
* C/D/X/Y tensors must have the same major order
* MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* MMA tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of all tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* OOB tiles are not allowed when TMA store is disabled
"""


class DenseGemmAlphaBeta(DenseGemmEFC):
    """Implements batched GEMM with custom epilogue fusion using EFC.

    This class extends DenseGemmEFC to provide a fused epilogue that:
    - Reads from input tensors C and X
    - Writes to output tensors D and Y
    - Performs: Y = A*B and D = (A*B) * alpha + C * beta + X * x_factor

    The class provides CLI argument parsing and tensor creation for the
    specific epilogue configuration with C, D, X, Y tensors and alpha,
    beta, x_factor scalar parameters.
    """

    class CLIParser(DenseGemmEFC.CLIParser):
        @override
        def more_parsing(self):
            self.parser.add_argument(
                "--alpha", type=float, default=1.0, help="alpha scale factor"
            )
            self.parser.add_argument(
                "--beta", type=float, default=0.0, help="beta scale factor"
            )
            self.parser.add_argument(
                "--c_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--d_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--x_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--x_factor", type=float, default=3.0, help="x_factor scale factor"
            )
            self.parser.add_argument(
                "--y_dtype", type=cutlass.dtype, default=cutlass.Float32
            )

    @override
    def create_arguments(
        self,
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        cd_major,
        ab_dtype,
        # For the supplemental tensors.
        c_dtype,
        d_dtype,
        x_dtype,
        y_dtype,
    ):
        """Create arguments for GEMM operations with epilogue tensors.

        Creates tensors for A, B (from parent class) and epilogue-specific
        tensors C, D, X, Y with appropriate data types and layouts.

        :return: Tuple of (a_tensor, b_tensor, a_torch_cpu, b_torch_cpu,
                           c_tensor, c_torch_cpu, c_torch_gpu,
                           d_tensor, d_torch_cpu, d_torch_gpu,
                           x_tensor, x_torch_cpu, x_torch_gpu,
                           y_tensor, y_torch_cpu, y_torch_gpu)
        """
        # Get standard arguments from parent class
        std_args = super().create_arguments(
            l, m, n, k, a_major, b_major, cd_major, ab_dtype
        )

        # Add the auxiliary accumulator tensors
        c_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", c_dtype)
        c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )

        d_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", d_dtype)
        d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
            d_torch_cpu, d_dtype, is_dynamic_layout=True, assumed_align=16
        )

        x_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", x_dtype)
        x_tensor, x_torch_gpu = cutlass_torch.cute_tensor_like(
            x_torch_cpu, x_dtype, is_dynamic_layout=True, assumed_align=16
        )

        y_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", y_dtype)
        y_tensor, y_torch_gpu = cutlass_torch.cute_tensor_like(
            y_torch_cpu, y_dtype, is_dynamic_layout=True, assumed_align=16
        )

        return (
            *std_args,
            c_tensor,
            c_torch_cpu,
            c_torch_gpu,
            d_tensor,
            d_torch_cpu,
            d_torch_gpu,
            x_tensor,
            x_torch_cpu,
            x_torch_gpu,
            y_tensor,
            y_torch_cpu,
            y_torch_gpu,
        )

    def compare(
        self,
        a_torch_cpu,
        b_torch_cpu,
        epi_dtype,
        tolerance,
        # For the tensor check.
        c_torch_gpu,
        d_torch_gpu,
        x_torch_gpu,
        y_torch_gpu,
        # The EFC epilogue arguments.
        c_torch_cpu,
        d_torch_cpu,
        alpha,
        beta,
        x_torch_cpu,
        x_factor,
        y_torch_cpu,
    ):
        """Compare GPU results against CPU reference implementation.

        Evaluates the epilogue computation on CPU and validates that:
        - Output tensor D matches CPU computation
        - Output tensor Y matches CPU computation
        - Input tensors C and X remain unchanged (read-only)

        :param a_torch_cpu: Input matrix A on CPU
        :param b_torch_cpu: Input matrix B on CPU
        :param epi_dtype: Data type for epilogue computation
        :param tolerance: Tolerance for numerical comparison
        :param c_torch_gpu: Input matrix C on GPU (to verify unchanged)
        :param d_torch_gpu: Output matrix D on GPU (to compare)
        :param x_torch_gpu: Input matrix X on GPU (to verify unchanged)
        :param y_torch_gpu: Output matrix Y on GPU (to compare)
        :param c_torch_cpu: Input matrix C on CPU
        :param d_torch_cpu: Output matrix D on CPU (reference)
        :param alpha: Scale factor for accumulator
        :param beta: Scale factor for C
        :param x_torch_cpu: Input matrix X on CPU
        :param x_factor: Scale factor for X
        :param y_torch_cpu: Output matrix Y on CPU (reference)
        """
        # Compute reference result
        self.evaluate_on_cpu(
            a_torch_cpu,
            b_torch_cpu,
            epi_dtype,
            c_torch_cpu,
            d_torch_cpu,
            alpha,
            beta,
            x_torch_cpu,
            x_factor,
            y_torch_cpu,
        )
        # Assert close results.
        torch.testing.assert_close(
            d_torch_gpu.cpu(), d_torch_cpu, atol=tolerance, rtol=1e-05
        )
        torch.testing.assert_close(
            y_torch_gpu.cpu(), y_torch_cpu, atol=tolerance, rtol=1e-05
        )
        # Assert that the read tensors has not been changed.
        torch.testing.assert_close(
            c_torch_gpu.cpu(), c_torch_cpu, atol=tolerance, rtol=1e-05
        )
        torch.testing.assert_close(
            x_torch_gpu.cpu(), x_torch_cpu, atol=tolerance, rtol=1e-05
        )

    @staticmethod
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
        c_dtype: typing.Type[cutlass.Numeric],
        d_dtype: typing.Type[cutlass.Numeric],
        alpha: float,
        beta: float,
        x_dtype: typing.Type[cutlass.Numeric],
        x_factor: float,
        y_dtype: typing.Type[cutlass.Numeric],
        tolerance: float,
    ) -> str:
        """Format test parameters as CLI arguments for custom_epilogue_dense_gemm.py

        Formats all test parameters into a CLI command that can be directly
        copy-pasted to reproduce the test case. Includes base parameters from
        DenseGemmEFC and epilogue-specific parameters (c_dtype, d_dtype, x_dtype,
        y_dtype, x_factor).

        :return: Formatted CLI command string
        """
        # Get base command from parent class
        base_cmd = DenseGemmEFC.format_as_cli_args(
            "custom_epilogue_dense_gemm.py",
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

        # Add epilogue-specific parameters
        specific_args = (
            f" --alpha {alpha} "
            f"--beta {beta} "
            f"--c_dtype {DenseGemmEFC.dtype_name(c_dtype)} "
            f"--d_dtype {DenseGemmEFC.dtype_name(d_dtype)} "
            f"--x_dtype {DenseGemmEFC.dtype_name(x_dtype)} "
            f"--y_dtype {DenseGemmEFC.dtype_name(y_dtype)} "
            f"--x_factor {x_factor}"
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
    # Epilogue EFC arguments.
    c_dtype: typing.Type[cutlass.Numeric],
    d_dtype: typing.Type[cutlass.Numeric],
    alpha: float,
    beta: float,
    x_dtype: typing.Type[cutlass.Numeric],
    x_factor: float,
    y_dtype: typing.Type[cutlass.Numeric],
    # Common arguments.
    mma_tiler_mn: typing.Tuple[int, int],
    cluster_shape_mn: typing.Tuple[int, int],
    use_2cta_instrs: bool,
    tolerance: float,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
):
    """Execute batched GEMM with custom epilogue fusion.

    Performs:
        Y = A * B
        D = (A * B) * alpha + C * beta + X * x_factor

    :param mnkl: Matrix dimensions (M, N, K, L) where L is batch dimension
    :param ab_dtype: Data type for input matrices A and B
    :param acc_dtype: Data type for accumulator
    :param epi_dtype: Data type for epilogue computation
    :param a_major: Major order for A matrix ('k' or 'm')
    :param b_major: Major order for B matrix ('k' or 'n')
    :param cd_major: Major order for C/D/X/Y matrices ('n' or 'm')
    :param c_dtype: Data type for input matrix C
    :param d_dtype: Data type for output matrix D
    :param alpha: Scale factor for accumulator in D computation
    :param beta: Scale factor for C in D computation
    :param x_dtype: Data type for input matrix X
    :param x_factor: Scale factor for X in D computation
    :param y_dtype: Data type for output matrix Y
    :param mma_tiler_mn: MMA tiler dimensions (M, N)
    :param cluster_shape_mn: Cluster shape (M, N)
    :param use_2cta_instrs: Whether to use 2CTA instructions
    :param tolerance: Tolerance for validation
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of iterations to run
    :param skip_ref_check: Skip reference checking
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
    print(f"\t{c_dtype = !s}, {d_dtype = !s}")
    print(f"\t{alpha = }, {beta = }")
    print(f"\t{x_dtype = !s}, {x_factor = }")
    print(f"\t{y_dtype = !s}")

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # The order of the parameters here is defining the one to be used in all the
    # other API calls. The epilogue function does not return anything and at
    # least one tensor .store() is required to have a useful computation.
    # efc_config exposes many features to the programmer, like activation
    # functions or accessing some implementation details. See EFC.Configuration.
    def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
        # All the .load() happen before any .store().
        # Store the accumulator to Y
        Y.store(efc_config.accum())
        # Compute the result with alpha, beta scaling and X factor
        result = (
            efc_config.relu(efc_config.accum() * alpha + C.load() * beta)
            + X.load() * x_factor
        )
        D.store(result)

    # Build GEMM object with EFC configuration:
    # TODO: generalize acc_dtype and epi_dtype
    gemm = DenseGemmAlphaBeta(
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
        # The supplemental tensors.
        c_tensor,
        c_torch_cpu,
        c_torch_gpu,
        d_tensor,
        d_torch_cpu,
        d_torch_gpu,
        x_tensor,
        x_torch_cpu,
        x_torch_gpu,
        y_tensor,
        y_torch_cpu,
        y_torch_gpu,
    ) = gemm.create_arguments(
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        cd_major,
        ab_dtype,
        # For the supplemental tensors.
        c_dtype,
        d_dtype,
        x_dtype,
        y_dtype,
    )

    # Check if the configuration can be implemented. Raise a ValueError
    # otherwise.
    gemm.check_implementable(a_tensor, b_tensor, d_tensor)

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
        c_tensor,
        d_tensor,
        alpha,
        beta,
        x_tensor,
        x_factor,
        y_tensor,
        # Not really useful here but this is an example of how to pass CuTe
        # DSL compilation options.
        options="--opt-level=3 --enable-assertions --generate-line-info",
    )

    compiled_gemm(
        a_tensor,
        b_tensor,
        current_stream,
        # Here are the supplemental arguments in the same order as for the
        # epilogue configuration function.
        c_tensor,
        d_tensor,
        alpha,
        beta,
        x_tensor,
        x_factor,
        y_tensor,
    )

    # TODO: unify with modern way to do benchmarking.
    exec_time = testing.benchmark(
        compiled_gemm,
        kernel_arguments=testing.JitArguments(
            a_tensor,
            b_tensor,
            current_stream,
            # Here are the supplemental arguments in the same order as for the
            # epilogue configuration function.
            c_tensor,
            d_tensor,
            alpha,
            beta,
            x_tensor,
            x_factor,
            y_tensor,
        ),
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    print(f"Execution time: {exec_time} us")

    # Compute reference result
    if not skip_ref_check:
        gemm.compare(
            # The usual arguments.
            a_torch_cpu,
            b_torch_cpu,
            epi_dtype,
            tolerance,
            # For the tensor check.
            c_torch_gpu,
            d_torch_gpu,
            x_torch_gpu,
            y_torch_gpu,
            # The EFC epilogue arguments.
            c_torch_cpu,
            d_torch_cpu,
            alpha,
            beta,
            x_torch_cpu,
            x_factor,
            y_torch_cpu,
        )


if __name__ == "__main__":
    args = DenseGemmAlphaBeta.CLIParser().parse()

    try:
        run(
            args.mnkl,
            args.ab_dtype,
            args.acc_dtype,
            args.epi_dtype,
            args.a_major,
            args.b_major,
            args.cd_major,
            args.c_dtype,
            args.d_dtype,
            args.alpha,
            args.beta,
            args.x_dtype,
            args.x_factor,
            args.y_dtype,
            args.mma_tiler_mn,
            args.cluster_shape_mn,
            args.use_2cta_instrs,
            args.tolerance,
            args.warmup_iterations,
            args.iterations,
            args.skip_ref_check,
        )
        print("PASS")
    except Exception as exc:
        traceback.print_exception(exc)
        raise
