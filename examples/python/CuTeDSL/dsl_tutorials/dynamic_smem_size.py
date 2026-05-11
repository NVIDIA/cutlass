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


import cutlass.cute as cute
import cutlass


"""
Example of automatic shared memory size computation for configuring kernel launch

This example demonstrates how to let the DSL automatically set shared memory
  size for a kernel launch rather explicitly configuring it at launch time,
  provided that developers are using `SmemAllocator` for all allocations.

Usage:
    python dynamic_smem_size.py         # Show auto inference
"""


@cute.struct
class SharedData:
    """A struct to demonstrate shared memory allocation."""

    values: cute.struct.MemRange[cutlass.Float32, 64]  # 256 bytes
    counter: cutlass.Int32  # 4 bytes
    flag: cutlass.Int8  # 1 byte


@cute.kernel
def kernel_static():
    """
    Example kernel that allocates shared memory.
    The total allocation will be automatically calculated when smem=None.
    """
    tidx, _, _ = cute.arch.block_idx()
    if tidx == 0:
        cute.printf("Running kernel_static")

    allocator = cutlass.utils.SmemAllocator()

    # Allocate various types of shared memory
    shared_data = allocator.allocate(SharedData)
    raw_buffer = allocator.allocate(512, byte_alignment=64)
    int_array = allocator.allocate_array(element_type=cutlass.Int32, num_elems=128)
    tensor_smem = allocator.allocate_tensor(
        element_type=cutlass.Float16,
        layout=cute.make_layout((32, 16)),
        byte_alignment=16,
        swizzle=None,
    )

    cute.printf("Kernel launch smem size: {}", cute.arch.dynamic_smem_size())
    return


@cute.kernel
def kernel_no_smem():
    """
    Example kernel that does not allocates shared memory.
    The total allocation will be automatically calculated as 0 when smem=None.
    """
    tidx, _, _ = cute.arch.block_idx()
    if tidx == 0:
        cute.printf("Running kernel_no_smem")
    return


if __name__ == "__main__":
    # Initialize CUDA context
    cutlass.cuda.initialize_cuda_context()

    print("Launching kernel with auto smem size. (launch config `smem=None`)")

    # Compile the static example
    @cute.jit
    def launch_kernelno_smem():
        kernel_no_smem().launch(
            grid=(1, 1, 1),
            block=(1, 1, 1),
        )

    # --------
    print(f" > Run {kernel_no_smem.__name__}")
    func = cute.compile(launch_kernelno_smem)
    func()
    cutlass.cuda.stream_sync(cutlass.cuda.default_stream())

    @cute.jit
    def launch_kernel_static():
        kernel_static().launch(
            grid=(1, 1, 1),
            block=(1, 1, 1),
            # smem=None
            # auto infer launch kernel static smem usage
        )

    # --------
    print(f" > Run {kernel_static.__name__} with sufficient smem")
    func = cute.compile(launch_kernel_static)
    func()
    cutlass.cuda.stream_sync(cutlass.cuda.default_stream())

    @cute.jit
    def launch_kernel_static_insufficient():
        kernel_static().launch(
            grid=(1, 1, 1),
            block=(1, 1, 1),
            # launch kernel with static smem usage exceeds cfg
            # show warning
            smem=16,
        )

    # --------
    print(f" > Run {kernel_static.__name__} with insufficient smem, show warning:")
    func = cute.compile(launch_kernel_static_insufficient)
    func()
    cutlass.cuda.stream_sync(cutlass.cuda.default_stream())

    print("PASS")
