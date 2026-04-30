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
from common_efc import ACTIVATION_FUNCTIONS

"""
A high-performance persistent batched dense GEMM with activation functions in custom epilogue fusion
for the NVIDIA Blackwell SM100 architecture using CUTE DSL and Epilogue Fusion Configuration (EFC).

This example demonstrates GEMMs with custom fused epilogues inspired by Ada FP8 GEMM epilogue
from https://github.com/NVIDIA/cutlass/blob/main/examples/58_ada_fp8_gemm/ada_fp8_gemm.cu :
  Aux = ((alpha * scale_a * scale_b) * accumulator) + ((beta * scale_c) * source) + bias
  D = activation(Aux)

The scale factors (scale_a, scale_b, scale_c) default to 1.0 but can be customized via CLI:

Tensor dimensions:
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL (read-only input, "source"), C can be row-major("N") or column-major("M")
- Matrix Aux is MxNxL (auxiliary output, pre-activation), same layout as C/D
- Matrix D is MxNxL (final output, post-activation), same layout as C
- alpha, beta are scalar scale factors
- scale_a, scale_b, scale_c are scalar scale factors for A, B, and C matrices
- bias is a scalar bias term

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Supports persistent tile scheduling to better overlap memory load/store with mma between tiles
    - Supports warp specialization to avoid explicit pipelining between mainloop load and mma
    - Uses Epilogue Fusion Configuration (EFC) to define custom epilogue operations with activation functions

Supported activation functions:
    - identity: f(x) = x
    - relu: f(x) = max(0, x)
    - leaky_relu: f(x) = max(0, x) + negative_slope * min(0, x)
    - tanh: f(x) = tanh(x)
    - sigmoid: f(x) = 1 / (1 + exp(-x))
    - silu: f(x) = x * sigmoid(x)
    - hardswish: f(x) = x * relu6(x + 3) / 6
    - gelu: f(x) = 0.5 * x * (1 + erf(x / sqrt(2)))

This GEMM works as follows:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp (defined via EFC):
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Load C (source) matrix from global memory (GMEM) to shared memory (SMEM) using TMA, then to registers (RMEM).
    - Compute Aux = (alpha * scale_a * scale_b) * accumulator + (beta * scale_c) * C + bias
    - Compute D = activation(Aux)
    - Type convert Aux and D matrices to output types.
    - Store Aux and D matrices from registers (RMEM) to shared memory (SMEM) to global memory (GMEM) with TMA operations

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Example usage:

.. code-block:: bash

    python activation_custom_epilogue_dense_gemm.py \
      --activation relu \
      --ab_dtype Float16 --c_dtype Float16 --aux_dtype Float16 --d_dtype Float16 \
      --acc_dtype Float32 --epi_dtype Float32 \
      --mma_tiler_mn 128,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 1.0 --beta 1.0 --bias 0.0 \
      --scale_a 1.0 --scale_b 1.0 --scale_c 1.0

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python activation_custom_epilogue_dense_gemm.py \
      --activation gelu \
      --ab_dtype Float16 --c_dtype Float16 --aux_dtype Float16 --d_dtype Float16 \
      --acc_dtype Float32 --epi_dtype Float32 \
      --mma_tiler_mn 128,128 --cluster_shape_mn 2,1 \
      --mnkl 8192,8192,8192,1 \
      --use_2cta_instrs --alpha 1.0 --beta 1.0 --bias 0.0 \
      --scale_a 1.0 --scale_b 1.0 --scale_c 1.0 \
      --warmup_iterations 1 --iterations 10 --skip_ref_check

Constraints:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2)
* A/B tensors must have the same data type
* C/D/Aux tensors must have the same major order
* MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* MMA tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of all tensors must be at least 16 bytes aligned,
  i.e, number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* OOB tiles are not allowed when TMA store is disabled
"""


class DenseGemmActivation(DenseGemmEFC):
    """Implements batched GEMM with activation function in epilogue using EFC.

    This class extends DenseGemmEFC to provide a fused epilogue inspired by
    Ada FP8 GEMM that:
    - Reads from input tensor C (source)
    - Writes to output tensors Aux (auxiliary, pre-activation) and D (final, post-activation)
    - Performs: Aux = alpha * accumulator + beta * C + bias
                D = activation(Aux)

    The class provides CLI argument parsing and tensor creation for the
    specific epilogue configuration with C, Aux, D tensors and alpha,
    beta, bias scalar parameters.
    """

    def __init__(
        self,
        acc_dtype,
        epi_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cluster_shape_mn,
        epilogue_fn,
        activation_name,
    ):
        """Initialize the GEMM with activation epilogue.

        :param acc_dtype: Accumulator data type
        :param epi_dtype: Epilogue computation data type
        :param use_2cta_instrs: Whether to use 2-CTA MMA instructions
        :param mma_tiler_mn: MMA tile shape (M, N)
        :param cluster_shape_mn: Cluster shape (M, N)
        :param epilogue_fn: Epilogue function to use
        :param activation_name: Name of the activation function
        """
        super().__init__(
            acc_dtype,
            epi_dtype,
            use_2cta_instrs,
            mma_tiler_mn,
            cluster_shape_mn,
            epilogue_fn,
        )
        self.activation_name = activation_name

    class CLIParser(DenseGemmEFC.CLIParser):
        @override
        def more_parsing(self):
            self.parser.add_argument(
                "--activation",
                type=str,
                default="relu",
                choices=ACTIVATION_FUNCTIONS,
                help="Activation function to use in epilogue",
            )
            self.parser.add_argument(
                "--alpha",
                type=float,
                default=1.0,
                help="alpha scale factor for accumulator",
            )
            self.parser.add_argument(
                "--beta", type=float, default=1.0, help="beta scale factor for source"
            )
            self.parser.add_argument(
                "--bias", type=float, default=0.0, help="bias term to add"
            )
            self.parser.add_argument(
                "--scale_a", type=float, default=1.0, help="scale factor for matrix A"
            )
            self.parser.add_argument(
                "--scale_b", type=float, default=1.0, help="scale factor for matrix B"
            )
            self.parser.add_argument(
                "--scale_c", type=float, default=1.0, help="scale factor for source C"
            )
            self.parser.add_argument(
                "--c_dtype",
                type=cutlass.dtype,
                default=cutlass.Float32,
                help="C tensor dtype",
            )
            self.parser.add_argument(
                "--aux_dtype",
                type=cutlass.dtype,
                default=cutlass.Float32,
                help="Aux tensor dtype",
            )
            self.parser.add_argument(
                "--d_dtype",
                type=cutlass.dtype,
                default=cutlass.Float32,
                help="D tensor dtype",
            )
            self.parser.add_argument(
                "--leaky_relu_alpha",
                type=float,
                default=0.01,
                help="negative slope for leaky_relu",
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
        aux_dtype,
        d_dtype,
    ):
        """Create arguments for GEMM operations with epilogue tensors.

        Creates tensors for A, B (from parent class) and epilogue-specific
        tensors C, Aux, D with appropriate data types and layouts.

        :return: Tuple of (a_tensor, b_tensor, a_torch_cpu, b_torch_cpu,
                           c_tensor, c_torch_cpu, c_torch_gpu,
                           aux_tensor, aux_torch_cpu, aux_torch_gpu,
                           d_tensor, d_torch_cpu, d_torch_gpu)
        """
        # Get standard arguments from parent class
        std_args = super().create_arguments(
            l, m, n, k, a_major, b_major, cd_major, ab_dtype
        )

        # Create C tensor (source for epilogue)
        c_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", c_dtype)
        c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )

        # Create Aux tensor (auxiliary/pre-activation output)
        aux_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", aux_dtype)
        aux_tensor, aux_torch_gpu = cutlass_torch.cute_tensor_like(
            aux_torch_cpu, aux_dtype, is_dynamic_layout=True, assumed_align=16
        )

        # Create D tensor (final/post-activation output)
        d_torch_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", d_dtype)
        d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
            d_torch_cpu, d_dtype, is_dynamic_layout=True, assumed_align=16
        )

        return (
            *std_args,
            c_tensor,
            c_torch_cpu,
            c_torch_gpu,
            aux_tensor,
            aux_torch_cpu,
            aux_torch_gpu,
            d_tensor,
            d_torch_cpu,
            d_torch_gpu,
        )

    def compare(
        self,
        a_torch_cpu,
        b_torch_cpu,
        epi_dtype,
        tolerance,
        # For the tensor check.
        c_torch_gpu,
        aux_torch_gpu,
        d_torch_gpu,
        # The EFC epilogue arguments.
        c_torch_cpu,
        aux_torch_cpu,
        alpha,
        beta,
        bias,
        scale_a,
        scale_b,
        scale_c,
        d_torch_cpu,
        leaky_relu_alpha=0.01,
    ):
        """Compare GPU results against CPU reference implementation.

        :param a_torch_cpu: Input tensor A on CPU
        :param b_torch_cpu: Input tensor B on CPU
        :param epi_dtype: Epilogue data type
        :param tolerance: Comparison tolerance
        :param c_torch_gpu: GPU result for C
        :param aux_torch_gpu: GPU result for Aux
        :param d_torch_gpu: GPU result for D
        :param c_torch_cpu: CPU reference for C
        :param aux_torch_cpu: CPU reference for Aux
        :param alpha: Alpha scale factor
        :param beta: Beta scale factor
        :param bias: Bias term
        :param scale_a: Scale factor for matrix A
        :param scale_b: Scale factor for matrix B
        :param scale_c: Scale factor for source C
        :param d_torch_cpu: CPU reference for D
        :param leaky_relu_alpha: Negative slope for leaky_relu
        """
        # Compute reference result
        self.evaluate_on_cpu(
            a_torch_cpu,
            b_torch_cpu,
            epi_dtype,
            c_torch_cpu,
            aux_torch_cpu,
            alpha,
            beta,
            bias,
            scale_a,
            scale_b,
            scale_c,
            d_torch_cpu,
            leaky_relu_alpha,
        )
        # Assert close results for output tensors
        torch.testing.assert_close(
            aux_torch_gpu.cpu(), aux_torch_cpu, atol=tolerance, rtol=1e-03
        )
        torch.testing.assert_close(
            d_torch_gpu.cpu(), d_torch_cpu, atol=tolerance, rtol=1e-03
        )
        # Assert that the read tensor has not been changed
        torch.testing.assert_close(
            c_torch_gpu.cpu(), c_torch_cpu, atol=tolerance, rtol=1e-03
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
        aux_dtype: typing.Type[cutlass.Numeric],
        d_dtype: typing.Type[cutlass.Numeric],
        alpha: float,
        beta: float,
        bias: float,
        scale_a: float,
        scale_b: float,
        scale_c: float,
        activation: str,
        leaky_relu_alpha: float,
        tolerance: float,
    ) -> str:
        """Format test parameters as CLI arguments for activation_custom_epilogue_dense_gemm.py

        Formats all test parameters into a CLI command that can be directly
        copy-pasted to reproduce the test case. Includes base parameters from
        DenseGemmEFC and epilogue-specific parameters (c_dtype, aux_dtype, d_dtype,
        alpha, beta, bias, activation).

        :return: Formatted CLI command string
        """
        # Get base command from parent class
        base_cmd = DenseGemmEFC.format_as_cli_args(
            "activation_custom_epilogue_dense_gemm.py",
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

        # Add epilogue-specific arguments
        epilogue_args = (
            f" --activation {activation}"
            f" --c_dtype {c_dtype.__name__}"
            f" --aux_dtype {aux_dtype.__name__}"
            f" --d_dtype {d_dtype.__name__}"
            f" --alpha {alpha}"
            f" --beta {beta}"
            f" --bias {bias}"
            f" --scale_a {scale_a}"
            f" --scale_b {scale_b}"
            f" --scale_c {scale_c}"
            f" --leaky_relu_alpha {leaky_relu_alpha}"
        )

        return base_cmd + epilogue_args


def create_epilogue_function(activation_name: str):
    """Create an epilogue function with the specified activation.

    :param activation_name: Name of the activation function to use
    :return: Epilogue function
    """
    # Validate activation name
    if activation_name not in ACTIVATION_FUNCTIONS:
        raise ValueError(f"Unsupported activation: {activation_name}")

    def epilogue(
        efc_config,
        C,
        Aux,
        alpha,
        beta,
        bias,
        scale_a,
        scale_b,
        scale_c,
        D,
        leaky_relu_alpha,
    ):
        # Aux = ((alpha * scale_a * scale_b) * accumulator) + ((beta * scale_c) * source) + bias
        # Following Ada FP8 GEMM epilogue pattern
        aux_val = (
            (alpha * scale_a * scale_b) * efc_config.accum()
            + (beta * scale_c) * C.load()
            + bias
        )
        Aux.store(aux_val)
        # D = activation(Aux)
        activation_fn = getattr(efc_config, activation_name)
        # leaky_relu needs an extra parameter, others don't
        if activation_name == "leaky_relu":
            D.store(activation_fn(aux_val, leaky_relu_alpha))
        else:
            D.store(activation_fn(aux_val))

    return epilogue


def run(
    mnkl: typing.Tuple[int, int, int, int],
    ab_dtype: typing.Type[cutlass.Numeric],
    acc_dtype: typing.Type[cutlass.Numeric],
    epi_dtype: typing.Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    cd_major: str,
    c_dtype: typing.Type[cutlass.Numeric],
    aux_dtype: typing.Type[cutlass.Numeric],
    d_dtype: typing.Type[cutlass.Numeric],
    alpha: float,
    beta: float,
    bias: float,
    scale_a: float,
    scale_b: float,
    scale_c: float,
    activation: str,
    leaky_relu_alpha: float,
    mma_tiler_mn: typing.Tuple[int, int],
    cluster_shape_mn: typing.Tuple[int, int],
    use_2cta_instrs: bool,
    tolerance: float,
    warmup_iterations: int = 3,
    iterations: int = 100,
    skip_ref_check: bool = False,
):
    """Run GEMM with activation function in epilogue.

    :param mnkl: Tuple of (M, N, K, L) dimensions
    :param ab_dtype: Data type for A and B tensors
    :param acc_dtype: Accumulator data type
    :param epi_dtype: Epilogue computation data type
    :param a_major: Major dimension for A ("m" or "k")
    :param b_major: Major dimension for B ("n" or "k")
    :param cd_major: Major dimension for C/D/Aux ("m" or "n")
    :param c_dtype: Data type for C tensor
    :param aux_dtype: Data type for Aux tensor
    :param d_dtype: Data type for D tensor
    :param alpha: Alpha scale factor
    :param beta: Beta scale factor
    :param bias: Bias term
    :param scale_a: Scale factor for matrix A
    :param scale_b: Scale factor for matrix B
    :param scale_c: Scale factor for source C
    :param activation: Activation function name
    :param leaky_relu_alpha: Negative slope for leaky_relu
    :param mma_tiler_mn: MMA tile shape (M, N)
    :param cluster_shape_mn: Cluster shape (M, N)
    :param use_2cta_instrs: Whether to use 2-CTA MMA instructions
    :param tolerance: Comparison tolerance
    :param warmup_iterations: Number of warmup iterations
    :param iterations: Number of benchmark iterations
    :param skip_ref_check: Whether to skip reference check
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
    print(f"\t{c_dtype = !s}, {aux_dtype = !s}, {d_dtype = !s}")
    print(f"\t{alpha = }, {beta = }, {bias = }")
    print(f"\t{scale_a = }, {scale_b = }, {scale_c = }")
    print(f"\t{activation = !s}")
    if activation == "leaky_relu":
        print(f"\t{leaky_relu_alpha = }")

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Create the epilogue function with the specified activation
    epilogue_fn = create_epilogue_function(activation)

    # Build GEMM object with EFC configuration
    gemm = DenseGemmActivation(
        acc_dtype,
        epi_dtype,
        use_2cta_instrs,
        mma_tiler_mn,
        cluster_shape_mn,
        epilogue_fn,
        activation,
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
        aux_tensor,
        aux_torch_cpu,
        aux_torch_gpu,
        d_tensor,
        d_torch_cpu,
        d_torch_gpu,
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
        aux_dtype,
        d_dtype,
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
        aux_tensor,
        alpha,
        beta,
        bias,
        scale_a,
        scale_b,
        scale_c,
        d_tensor,
        leaky_relu_alpha,
    )

    compiled_gemm(
        a_tensor,
        b_tensor,
        current_stream,
        # Here are the supplemental arguments in the same order as for the
        # epilogue configuration function.
        c_tensor,
        aux_tensor,
        alpha,
        beta,
        bias,
        scale_a,
        scale_b,
        scale_c,
        d_tensor,
        leaky_relu_alpha,
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
            aux_tensor,
            alpha,
            beta,
            bias,
            scale_a,
            scale_b,
            scale_c,
            d_tensor,
            leaky_relu_alpha,
        ),
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    print(f"Execution time: {exec_time} us")

    # Compute reference result
    if not skip_ref_check:
        print("Checking results against CPU reference...")
        gemm.compare(
            # The usual arguments.
            a_torch_cpu,
            b_torch_cpu,
            epi_dtype,
            tolerance,
            # For the tensor check.
            c_torch_gpu,
            aux_torch_gpu,
            d_torch_gpu,
            # The EFC epilogue arguments.
            c_torch_cpu,
            aux_torch_cpu,
            alpha,
            beta,
            bias,
            scale_a,
            scale_b,
            scale_c,
            d_torch_cpu,
            leaky_relu_alpha,
        )
        print("Results match CPU reference!")


if __name__ == "__main__":
    args = DenseGemmActivation.CLIParser().parse()

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
            args.aux_dtype,
            args.d_dtype,
            args.alpha,
            args.beta,
            args.bias,
            args.scale_a,
            args.scale_b,
            args.scale_c,
            args.activation,
            args.leaky_relu_alpha,
            args.mma_tiler_mn,
            args.cluster_shape_mn,
            args.use_2cta_instrs,
            args.tolerance,
            args.warmup_iterations,
            args.iterations,
            args.skip_ref_check,
        )
        print("\n" + "=" * 80)
        print(
            f"PASS - {args.activation.upper()} activation test completed successfully!"
        )
        print("=" * 80 + "\n")
    except Exception as exc:
        traceback.print_exception(exc)
        raise
