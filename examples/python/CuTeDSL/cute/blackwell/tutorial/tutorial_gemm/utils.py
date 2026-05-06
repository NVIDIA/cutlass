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

import argparse
from typing import Tuple

import torch

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_ptr


def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


def create_parser():
    parser = argparse.ArgumentParser(
        description="Example of Sm100 Dense BlockScaled GEMM."
    )
    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(8192, 8192, 8192, 8),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--do_benchmark", action="store_true", default=False, help="Do benchmark test"
    )
    return parser


def ceil_div(a, b):
    return (a + b - 1) // b


# Helper function to create scale factor tensor SFA/SFB
# for 1x16 block scaled wise use case and follow the layout requirement
# defined in https://docs.nvidia.com/cuda/cublas/index.html?highlight=fp4#d-block-scaling-factors-layout
@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_ptr: cute.Pointer,
    sf_mma_ptr: cute.Pointer,
    mn: int,
    sf_k: int,
    l: int,
    mma_shape: tuple,
):
    mma_permute_order = (3, 4, 1, 5, 2, 0)
    permuted_shape = tuple(mma_shape[i] for i in mma_permute_order)
    cute_layout = cute.make_ordered_layout(permuted_shape, order=(2, 1, 4, 0, 3, 5))

    sf_ref_tensor = cute.make_tensor(
        sf_ref_ptr, cute.make_layout((mn, sf_k, l), stride=(sf_k, 1, mn * sf_k))
    )
    sf_mma_tensor = cute.make_tensor(sf_mma_ptr, cute_layout)

    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]
    pass


def to_blocked(input_matrix):
    rows, cols = input_matrix.shape

    # Please ensure rows and cols are multiples of 128 and 4 respectively
    n_row_blocks = ceil_div(rows, 128)
    n_col_blocks = ceil_div(cols, 4)

    padded = input_matrix
    blocks = padded.view(n_row_blocks, 128, n_col_blocks, 4).permute(0, 2, 1, 3)
    rearranged = blocks.reshape(-1, 4, 32, 4).transpose(1, 2).reshape(-1, 32, 16)

    return rearranged.flatten()


def run(
    gemm_class,
    ab_dtype,
    sf_dtype,
    c_dtype,
    sf_vec_size,
    mma_tiler_mn,
    cluster_shape_mnk,
    mnkl: Tuple[int, int, int, int],
    tolerance: float,
    warmup_iterations: int = 10,
    iterations: int = 100,
    use_cold_l2: bool = True,
    do_benchmark: bool = False,
):
    """
    Prepare A/B/SFA/SFB/C tensors, launch GPU kernel, and reference checking.
    """
    print("=" * 60)
    print("Launching Blackwell Dense BlockScaled GEMM Test")
    print("-" * 60)
    print(f"Input dimensions (m, n, k, l): {mnkl}")
    print(f"    m (rows): {mnkl[0]}")
    print(f"    n (cols): {mnkl[1]}")
    print(f"    k (inner): {mnkl[2]}")
    print(f"    l (batch): {mnkl[3]}")
    print(f"Data Types & Precision:")
    print(f"    Input matrices (A, B): {ab_dtype}")
    print(f"    Scale factors (SFA, SFB): {sf_dtype}")
    print(f"    Output matrix (C): {c_dtype}")
    print(f"    Scale factor vector size: {sf_vec_size}")
    print("Tile and cluster configuration:")
    print(f"    MMA tiler (M, N, K): {mma_tiler_mn}")
    print(f"     Cluster shape (M, N, K): {cluster_shape_mnk}")
    print(f"Validation tolerance: {tolerance}")
    print(f"Do benchmark: {do_benchmark}")
    print("=" * 60)

    # Unpack parameters
    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    # Create tensor A/B/C
    a_ref = torch.randint(
        0, 2, (l, m, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)
    b_ref = torch.randint(
        0, 2, (l, n, k // 2), dtype=torch.uint8, device="cuda"
    ).permute(1, 2, 0)
    # a_ref = torch.ones((l, m, k // 2), dtype=torch.uint8, device="cuda").permute(1, 2, 0)
    # b_ref = torch.ones((l, n, k // 2), dtype=torch.uint8, device="cuda").permute(1, 2, 0)
    a_ref_f4 = a_ref.view(torch.float4_e2m1fn_x2)
    b_ref_f4 = b_ref.view(torch.float4_e2m1fn_x2)

    c_tensor = torch.randn((l, m, n), dtype=torch.float16, device="cuda").permute(
        1, 2, 0
    )

    # Create a torch tensor for scale factor tensor of A and B
    def create_ref_scale_factor_tensor(l, mn, sf_k):
        """
        Create the reference scale factor tensor on CPU.
        Returns the reshaped/pruned tensor ready for ref computation and its original permuted form.
        """
        ref_shape = (l, mn, sf_k)
        ref_permute_order = (1, 2, 0)
        ref_f8_random_int = torch.randint(1, 3, ref_shape, dtype=torch.int8)
        ref_f8_torch_tensor_cpu = ref_f8_random_int.to(dtype=torch.float8_e4m3fn)
        # permute to match ref_permute_order
        ref_f8_torch_tensor_cpu_permuted = ref_f8_torch_tensor_cpu.permute(
            *ref_permute_order
        )
        return ref_f8_torch_tensor_cpu_permuted

    # Copy the reference scale factor tensor to the CUTE-format scale factor tensor
    def create_cute_scale_factor_tensor(l, mn, sf_k, ref_f8_torch_tensor_cpu_permuted):
        """
        Create the CUTE-format scale factor tensor on CUDA based on the reference tensor.
        """
        atom_m = (32, 4)
        atom_k = 4
        mma_shape = (
            l,  # batch size
            ceil_div(mn, atom_m[0] * atom_m[1]),
            ceil_div(sf_k, atom_k),
            atom_m[0],
            atom_m[1],
            atom_k,
        )
        mma_permute_order = (3, 4, 1, 5, 2, 0)

        # Generate a random int8 tensor, then convert to float8_e4m3fn
        rand_int_tensor = torch.randint(0, 2, mma_shape, dtype=torch.int8)
        cute_f8_torch_tensor_cpu = rand_int_tensor.to(dtype=torch.float8_e4m3fn)
        # Permute according to mma_permute_order
        cute_f8_torch_tensor_cpu = cute_f8_torch_tensor_cpu.permute(*mma_permute_order)

        # Call the helper function to do layout conversion
        cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
            make_ptr(
                cutlass.Float8E4M3FN,
                ref_f8_torch_tensor_cpu_permuted.data_ptr(),
                cute.AddressSpace.gmem,
                assumed_align=32,
            ),
            make_ptr(
                cutlass.Float8E4M3FN,
                cute_f8_torch_tensor_cpu.data_ptr(),
                cute.AddressSpace.gmem,
                assumed_align=32,
            ),
            mn,
            sf_k,
            l,
            mma_shape,
        )
        return cute_f8_torch_tensor_cpu.cuda()

    sf_k = ceil_div(k, sf_vec_size)
    sfa_ref = create_ref_scale_factor_tensor(l, m, sf_k)
    sfb_ref = create_ref_scale_factor_tensor(l, n, sf_k)
    # sfa_ref.fill_(1)
    # sfb_ref.fill_(1)
    sfa_tensor = create_cute_scale_factor_tensor(l, m, sf_k, sfa_ref)
    sfb_tensor = create_cute_scale_factor_tensor(l, n, sf_k, sfb_ref)

    # Configure gemm kernel
    gemm = gemm_class()
    # Initialize Stream
    current_stream = cutlass_torch.default_stream()
    a_ptr = make_ptr(
        ab_dtype, a_ref_f4.data_ptr(), cute.AddressSpace.gmem, assumed_align=16
    )
    b_ptr = make_ptr(
        ab_dtype, b_ref_f4.data_ptr(), cute.AddressSpace.gmem, assumed_align=16
    )
    c_ptr = make_ptr(
        c_dtype, c_tensor.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    sfa_ptr = make_ptr(
        sf_dtype, sfa_tensor.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    sfb_ptr = make_ptr(
        sf_dtype, sfb_tensor.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
    )
    # Compile gemm kernel
    compiled_gemm = cute.compile(
        gemm,
        a_ptr,
        b_ptr,
        sfa_ptr,
        sfb_ptr,
        c_ptr,
        (m, n, k, l),
        current_stream,
    )
    # Launch GPU kernel
    compiled_gemm(a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, (m, n, k, l), current_stream)
    # For batch l, do (m, k, l) @ (n, k, l).T along k for each batch.
    # Result: (m, n, l)
    # Allocate ref as (l, m, n) with n-contiguous layout, then permute to (m, n, l)
    ref = torch.empty(
        (l, m, n),
        dtype=torch.float16,
        device="cuda",
    ).permute(1, 2, 0)
    for l_idx in range(l):
        # Convert the scale factor tensor to blocked format
        scale_a = to_blocked(sfa_ref[:, :, l_idx])
        scale_b = to_blocked(sfb_ref[:, :, l_idx])
        # (m, k) @ (n, k).T -> (m, n)
        res = torch._scaled_mm(
            a_ref_f4[:, :, l_idx],
            b_ref_f4[:, :, l_idx].transpose(0, 1),
            scale_a.cuda(),
            scale_b.cuda(),
            bias=None,
            out_dtype=torch.float16,
        )
        ref[:, :, l_idx] = res
    torch.testing.assert_close(c_tensor, ref, atol=tolerance, rtol=1e-02)

    if do_benchmark:

        def generate_tensors():
            a_ptr = make_ptr(
                ab_dtype, a_ref_f4.data_ptr(), cute.AddressSpace.gmem, assumed_align=16
            )
            b_ptr = make_ptr(
                ab_dtype, b_ref_f4.data_ptr(), cute.AddressSpace.gmem, assumed_align=16
            )
            c_ptr = make_ptr(
                c_dtype, c_tensor.data_ptr(), cute.AddressSpace.gmem, assumed_align=32
            )
            sfa_ptr = make_ptr(
                sf_dtype,
                sfa_tensor.data_ptr(),
                cute.AddressSpace.gmem,
                assumed_align=32,
            )
            sfb_ptr = make_ptr(
                sf_dtype,
                sfb_tensor.data_ptr(),
                cute.AddressSpace.gmem,
                assumed_align=32,
            )
            args = cute.testing.JitArguments(
                a_ptr, b_ptr, sfa_ptr, sfb_ptr, c_ptr, (m, n, k, l), current_stream
            )
            args.add_to_scope([a_ref_f4, b_ref_f4, sfa_tensor, sfb_tensor, c_tensor])
            return args

        workspace_count = 1
        if use_cold_l2:
            one_workspace_bytes = (
                a_ref_f4.numel() * a_ref_f4.element_size()
                + b_ref_f4.numel() * b_ref_f4.element_size()
                + sfa_tensor.numel() * sfa_tensor.element_size()
                + sfb_tensor.numel() * sfb_tensor.element_size()
                + c_tensor.numel() * c_tensor.element_size()
            )
            workspace_count = cute.testing.get_workspace_count(
                one_workspace_bytes, warmup_iterations, iterations
            )

        # Return execution time in microseconds
        time = cute.testing.benchmark(
            compiled_gemm,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
        )

        print(f"Execution time: {time} us")
        peta_flops = (4 * m * n * k * l) / (time * 1e-6) / 1e9 / 1000000
        print(f"FLOPS: {peta_flops} PFLOPS")
        bytes_transfer = (
            2 * m * k / 2 * l * a_ref_f4.element_size()
            + 2 * n * k / 2 * l * b_ref_f4.element_size()
            + 2 * m * n * l * c_tensor.element_size()
            + 2 * m * sf_k * l * sfa_tensor.element_size()
            + 2 * n * sf_k * l * sfb_tensor.element_size()
        )
        print(f"Bytes: {bytes_transfer} Bytes")
        bandwidth = bytes_transfer / time * 1e-3
        print(f"BW: {bandwidth} GB/s")
