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
Cooperative Launch Example:

This module demonstrates CUDA Cooperative Launch functionality. It implements a
global barrier that synchronizes ALL threads across the entire GPU grid.

In traditional CUDA kernel launches, there is no guarantee that all thread blocks
will be resident on the GPU simultaneously. This means that thread blocks may
execute in waves (some finish before others start) and attempting to synchronize
across blocks can cause deadlock.

**Cooperative Launch** solves this by guaranteeing that all thread blocks launch
atomically and simultaneously.

For more details, see the CUDA Programming Guide official documentation:
https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cooperative-groups.html#when-to-use-cudalaunchcooperativekernel

Cooperative Launch Limitations:

Cooperative launch has strict grid size constraints.
If you exceed this limit, cudaLaunchCooperativeKernel returns
cudaErrorCooperativeLaunchTooLarge.

This example demonstrates both a successful cooperative launch with a small grid
and an expected failure when exceeding the grid size limit.

Usage:

Run directly:
    $ python cooperative_launch.py

This will:
    1. Demonstrate expected failure with too many thread blocks
    2. Successfully run a cooperative kernel with grid-wide barrier
    3. Print confirmation that all threads synchronized successfully

"""

from typing import List, Optional
import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import (
    dsl_user_op,  # Decorator for user-defined device operations
    DSLCudaRuntimeError,  # Exception type for CUDA runtime errors
    extract_mlir_values,  # Extract MLIR values from the object
    new_from_mlir_values,  # Create a new instance from MLIR values
)

# Function to check cuda errors
from cutlass.base_dsl.runtime.cuda import checkCudaErrors

# LLVM dialect for inline PTX assembly generation
from cutlass._mlir.dialects import llvm

# CUDA Python bindings for runtime API (memory allocation, synchronization, etc.)
import cuda.bindings.runtime as cuda_runtime


class GlobalBarrier:
    """
    A grid-wide barrier for synchronizing ALL thread blocks on the GPU.

    This class implements a cooperative barrier that enables grid-wide
    synchronization. It requires cooperative launch to function correctly.

    Design Overview:

    The barrier uses a single 32-bit integer in global memory with the
    following bit layout:

        ┌──────────────────────────────────────────────────────────────────┐
        │ Bit 31     │ Bits 30-0                                          │
        │ ────────── │ ───────────────────────────────────────────────────│
        │ Phase Bit  │ Arrival Counter (supports up to 2^31 - 1 blocks)   │
        └──────────────────────────────────────────────────────────────────┘

    Capacity:

    - Maximum thread blocks: 2^31 - 1 = 2,147,483,647 blocks

    Memory Ordering:

    The barrier uses specific memory ordering semantics:

    - Release semantics on arrival (atom.add.release.gpu)

    - Acquire semantics on wait (ld.global.acquire.gpu)

    Usage Example:

    Host-side setup:

        >>> barrier_ptr = GlobalBarrier.allocate()  # Allocate barrier memory

    Device-side usage (inside a kernel):

        >>> barrier = GlobalBarrier(barrier_ptr)
        >>>
        >>> # Do some work...
        >>>
        >>> barrier.arrive_and_wait()  # Synchronize all blocks
        >>>
        >>> # All blocks proceed together after this point

    Warning:

    This barrier requires cooperative launch! Using it with a regular launch
    can result in a deadlock because not all thread blocks may be resident
    simultaneously.
    """

    @staticmethod
    def allocate() -> cute.runtime.Pointer:
        """
        Allocate and initialize barrier memory on the GPU.

        This function allocates device memory for the barrier.
        It must be called before launching any kernel that uses the barrier.
        """
        ptr = checkCudaErrors(cuda_runtime.cudaMalloc(4))

        # This sets all 32 bits to 0:
        #   - Phase bit (bit 31) = 0
        #   - Counter (bits 30-0) = 0
        checkCudaErrors(cuda_runtime.cudaMemset(ptr, 0, 4))

        # Create a pointer with the following properties:
        #   - Type: Uint32 (32-bit unsigned integer)
        #   - Address: the allocated device pointer
        #   - Address Space: gmem (global memory)
        barrier_ptr = cute.runtime.make_ptr(
            cutlass.Uint32,  # Element type
            ptr,  # Raw CUDA pointer
            cute.AddressSpace.gmem,  # Memory address space
        )

        return barrier_ptr

    @staticmethod
    def free(barrier_ptr: cute.Pointer):
        """
        Free the barrier memory on the GPU.

        This function frees the device memory for the barrier.
        It must be called after the barrier is no longer needed.
        """
        checkCudaErrors(cuda_runtime.cudaFree(barrier_ptr._pointer))

    @dsl_user_op
    def __init__(
        self,
        barrier_ptr: cute.Pointer,
        *,
        phase: Optional[cutlass.Uint32] = None,
        is_leader: Optional[cutlass.Boolean] = None,
        number_of_thread_blocks: Optional[cutlass.Uint32] = None,
        loc=None,
        ip=None,
    ):
        """
        Initialize a GlobalBarrier instance on the device.

        This constructor is called by each thread when the kernel
        starts. It sets up the barrier state for this thread's participation
        in grid-wide synchronization.

        Each thread stores the following:

        - A reference to the shared barrier memory
        - Whether it's the leader thread of its block
        - The current phase for barrier tracking
        - The total number of thread blocks in the grid
        """
        # The barrier is shared across ALL thread blocks, so it must be in
        # global memory. Shared memory (smem) is block-local and wouldn't work.
        if barrier_ptr.memspace != cute.AddressSpace.gmem:
            raise ValueError(
                "GlobalBarrier requires barrier_ptr to be in global memory (gmem)"
            )

        # Store barrier pointer reference
        self.barrier_ptr = barrier_ptr

        # Initialize phase tracking
        # Phase starts at 0 for the first barrier, then alternates:
        #   First barrier:  wait for phase 1
        #   Second barrier: wait for phase 0
        #   Third barrier:  wait for phase 1
        #   ... and so on
        if phase is not None:
            self.phase = phase
        else:
            self.phase = cutlass.Uint32(0)

        if is_leader is not None:
            self.is_leader = is_leader
        else:
            # Determine if this thread is the block leader
            # Get this thread's position within its block
            tidx, tidy, tidz = cute.arch.thread_idx()

            # Leader is the thread at position (0, 0, 0) in the block
            # We use bitwise AND to combine the three conditions efficiently
            self.is_leader = (
                cutlass.Boolean(tidx == 0)  # First in X dimension
                & cutlass.Boolean(tidy == 0)  # First in Y dimension
                & cutlass.Boolean(tidz == 0)  # First in Z dimension
            )

        if number_of_thread_blocks is not None:
            self.number_of_thread_blocks = number_of_thread_blocks
        else:
            # Calculate total number of thread blocks in the grid
            # Get grid dimensions (how many blocks in each dimension)
            gidx, gidy, gidz = cute.arch.grid_dim()

            # Total blocks = gridDim.x × gridDim.y × gridDim.z
            # This is needed to know when ALL blocks have arrived
            self.number_of_thread_blocks = cutlass.Uint32(gidx * gidy * gidz)

    @dsl_user_op
    @cute.jit
    def arrive(self, *, loc=None, ip=None):
        """
        Arrive at the barrier without waiting.

        This signals that the calling thread block has reached the barrier
        point, but does not wait for other blocks. Use this when you want
        to overlap computation with barrier synchronization.

        This method must be called by ALL threads in the block,
        not just the leader. The internal block-level sync ensures all
        threads in the block agree before the leader signals arrival.
        """
        # Ensure ALL threads in this block have reached this point before
        # the leader signals arrival. This is critical for correctness!
        cute.arch.sync_threads(loc=loc, ip=ip)

        # Only the leader thread performs atomic operations to minimize
        # contention on the barrier memory location
        if self.is_leader:
            # Atomically increment the arrival counter by 1
            # The atomic add returns the value before the add, so we add 1
            # to get the current value after our arrival
            barrier_value = (
                self._increment_barrier(cutlass.Uint32(1), loc=loc, ip=ip) + 1
            )

            # Check if we're the last block to arrive
            # Mask out the phase bit (bit 31) to get just the counter value
            # Compare against total number of thread blocks
            if (barrier_value & ~(1 << 31)) == self.number_of_thread_blocks:
                # Flip phase and reset counter
                # We add a value that simultaneously:
                #   1. Flips bit 31 (adds 2^31)
                #   2. Resets counter to 0 (subtracts N, where N was the count)
                #
                # Example with 8 blocks:
                #   Current: 0x00000008 (phase=0, counter=8)
                #   Add:     0x80000000 - 8 = 0x7FFFFFF8
                #   Result:  0x80000000 (phase=1, counter=0) ✓
                #
                # This works because we're doing modular arithmetic and the
                # counter wraps correctly
                self._increment_barrier(
                    cutlass.Uint32((1 << 31) - self.number_of_thread_blocks),
                    loc=loc,
                    ip=ip,
                )

    def _read_barrier(self, *, loc=None, ip=None) -> cutlass.Uint32:
        """
        Read the barrier value with acquire memory semantics.

        This is an internal method that reads the 32-bit barrier value from
        global memory using GPU-scope acquire semantics.

        Notes
        -----
        PTX Instruction:
            Uses ld.global.acquire.gpu.b32 which is a:

            - Global memory load (ld.global)
            - With acquire semantics (.acquire)
            - At GPU scope (.gpu) - visible across all thread blocks
            - For 32-bit data (.b32)

        Inline Assembly:
            We use LLVM inline assembly because CuTe DSL may not have a direct
            high-level API for acquire loads. The assembly string format:

            - $0: Output operand (the loaded value)
            - $1: Input operand (the address to load from)

        """
        # Use inline PTX assembly for the acquire-semantics load
        return cutlass.Uint32(
            llvm.inline_asm(
                # Return type: 32-bit unsigned integer
                cutlass.Uint32.mlir_type,
                # Input arguments: barrier pointer address
                # We convert the pointer to an integer (64-bit address)
                [self.barrier_ptr.toint().ir_value(loc=loc, ip=ip)],
                # PTX instruction
                "ld.global.acquire.gpu.b32 $0, [$1];",
                # Constraint string
                # "=r" : Output is a 32-bit register (write-only)
                # "l"  : Input is a 64-bit register (pointer address)
                "=r,l",
                # Assembly attributes
                # Mark as having side effects
                has_side_effects=True,
                # No special stack alignment needed
                is_align_stack=False,
                # Use AT&T syntax (required for LLVM inline asm)
                asm_dialect=llvm.AsmDialect.AD_ATT,
                # MLIR location and insertion point
                loc=loc,
                ip=ip,
            )
        )

    def _increment_barrier(
        self, value: cutlass.Uint32, *, loc=None, ip=None
    ) -> cutlass.Uint32:
        """
        Atomically increment the barrier with release memory semantics.

        This is an internal method that performs an atomic add on the barrier
        value using GPU-scope release semantics.

        Notes
        -----
        PTX Instruction:
            Uses atom.add.release.gpu.u32 which is a:

            - Atomic operation (atom)
            - Addition (.add)
            - With release semantics (.release)
            - At GPU scope (.gpu)
            - For unsigned 32-bit integers (.u32)

        Atomicity:
            The atomic add is guaranteed to be indivisible - no other thread
            can see a partial update or interleave with this operation.

        Return Value:
            Atomic operations return the OLD value, not the new value.
            This is why the caller adds 1 to get the current count.
        """
        # Atomic add using inline PTX assembly with release semantics
        return cutlass.Uint32(
            llvm.inline_asm(
                # Return type: 32-bit unsigned integer (the old value)
                cutlass.Uint32.mlir_type,
                # Input arguments: (barrier address, value to add)
                [
                    self.barrier_ptr.toint().ir_value(
                        loc=loc, ip=ip
                    ),  # Barrier address
                    value.ir_value(loc=loc, ip=ip),  # Value to add
                ],
                # PTX  instruction
                "atom.add.release.gpu.u32 $0, [$1], $2;",
                # Constraint string
                # "=r" : Output is a 32-bit register
                # "l"  : First input is 64-bit (pointer)
                # "r"  : Second input is 32-bit (value)
                "=r,l,r",
                # Assembly attributes
                has_side_effects=True,
                is_align_stack=False,
                asm_dialect=llvm.AsmDialect.AD_ATT,
                # MLIR metadata
                loc=loc,
                ip=ip,
            )
        )

    @dsl_user_op
    @cute.jit
    def wait(self, *, loc=None, ip=None):
        """
        Wait for all thread blocks to arrive at the barrier.

        This method blocks (spins) until all thread blocks have called
        arrive() on the barrier. It does NOT signal arrival itself - use
        arrive_and_wait() if you need to both arrive and wait.

        IMPORTANT: This method MUST be called by ALL threads in the block.
        The internal sync_threads ensures all threads proceed together.

        Algorithm:
        - Leader thread spins, reading barrier with acquire semantics
        - Waits until phase bit matches expected value
        - Block-level sync ensures all threads proceed together
        - Update local phase tracking for next barrier

        """
        # Leader thread: spin-wait for phase flip
        if self.is_leader:
            # Calculate expected phase (opposite of current phase)
            # XOR with 1 flips: 0→1, 1→0
            expected = self.phase ^ 1

            # Initial read of barrier value
            barrier_value = self._read_barrier(loc=loc, ip=ip)

            # Spin loop: wait until phase matches expected
            # Extract phase bit (bit 31)
            # Compare against expected phase value
            while (barrier_value >> 31) != expected:
                # Keep reading barrier until phase flips
                # The acquire semantics ensure memory ordering
                barrier_value = self._read_barrier(loc=loc, ip=ip)

        # Block-level synchronization
        # Ensure all threads in the block wait for the leader to see the
        # phase flip before any thread proceeds
        cute.arch.sync_threads(loc=loc, ip=ip)

        # Update phase for next barrier
        # Flip local phase: 0→1 or 1→0
        # This prepares for the next barrier synchronization
        self.phase = self.phase ^ 1

    @dsl_user_op
    def arrive_and_wait(self, *, loc=None, ip=None):
        """
        Arrive at the barrier AND wait for all other thread blocks.

        This is the most common barrier operation - it combines arrive()
        and wait() into a single call. All thread blocks will be synchronized
        after this call returns.

        IMPORTANT: This method MUST be called by ALL threads in the block.

        Semantics
        ---------

        Logically equivalent to:

            >>> barrier.arrive()   # Signal we've reached this point
            >>> barrier.wait()     # Wait for everyone else
        """
        # Execute both phases: arrive then wait
        self.arrive(loc=loc, ip=ip)
        self.wait(loc=loc, ip=ip)

    def __extract_mlir_values__(self) -> List[ir.Value]:
        """
        Extract MLIR values from the GlobalBarrier instance.
        """

        assert len(extract_mlir_values(self.barrier_ptr)) == 1
        assert len(extract_mlir_values(self.is_leader)) == 1
        assert len(extract_mlir_values(self.phase)) == 1
        assert len(extract_mlir_values(self.number_of_thread_blocks)) == 1

        return (
            extract_mlir_values(self.barrier_ptr)
            + extract_mlir_values(self.is_leader)
            + extract_mlir_values(self.phase)
            + extract_mlir_values(self.number_of_thread_blocks)
        )

    def __new_from_mlir_values__(self, values: List[ir.Value]) -> "GlobalBarrier":
        """
        Create a new GlobalBarrier instance from MLIR values.
        """
        assert len(values) == 4, f"Expected 4 IR values, but got {len(values)}"
        return GlobalBarrier(
            barrier_ptr=new_from_mlir_values(self.barrier_ptr, [values[0]]),
            is_leader=new_from_mlir_values(self.is_leader, [values[1]]),
            phase=new_from_mlir_values(self.phase, [values[2]]),
            number_of_thread_blocks=new_from_mlir_values(
                self.number_of_thread_blocks, [values[3]]
            ),
        )


@cute.kernel
def cooperative_kernel(barrier_ptr: cute.Pointer):
    """
    Example kernel demonstrating cooperative launch with grid-wide barrier.

    This kernel shows how to use the GlobalBarrier class to synchronize all
    thread blocks in a grid. It performs 10 iterations, with a barrier
    synchronization after each iteration.

    Launch Requirements: This kernel MUST be launched with cooperative=True.

    """
    # Initialize the barrier for this thread
    # Each thread creates its own GlobalBarrier instance, all sharing the
    # same underlying barrier_ptr in global memory
    barrier = GlobalBarrier(barrier_ptr=barrier_ptr)

    for i in range(10):
        # Synchronize all thread blocks across the entire grid
        # After this call, ALL blocks have completed iterations 0..i
        barrier.arrive_and_wait()

        # Get block and thread indices
        bidx, bidy, bidz = cute.arch.block_idx()
        tidx, tidy, tidz = cute.arch.thread_idx()

        # Check if this is the leader block (first block in the grid)
        leader_cluster = bidx == 0 and bidy == 0 and bidz == 0

        # Check if this is the leader thread (first thread in the block)
        leader_thread = tidx == 0 and tidy == 0 and tidz == 0

        # Only the single leader thread of the leader block prints
        if leader_cluster and leader_thread:
            cute.printf("All threads arrived at barrier for the %dth iteration\n", i)


# =============================================================================
#                           KERNEL LAUNCH WRAPPERS
# =============================================================================


@cute.jit
def run_cooperative_kernel(barrier_ptr: cute.runtime.Pointer):
    """
    Launch the cooperative kernel with a reasonable grid size.

    This wrapper launches the cooperative_kernel with a grid of 8 thread blocks
    (2×2×2), where each block contains 128 threads (32×2×2).

    Notes: The cooperative=True flag is ESSENTIAL. It tells CUDA to:
    - Verify the grid fits within hardware limits
    - Launch all blocks atomically
    """
    cooperative_kernel(barrier_ptr).launch(
        grid=(2, 2, 2),  # 8 thread blocks
        block=(32, 2, 2),  # 128 threads per block
        cooperative=True,  # Enable cooperative launch semantics
    )


@cute.jit
def xfail_run_cooperative_kernel(barrier_ptr: cute.runtime.Pointer):
    """
    Demonstrate cooperative launch failure with an oversized grid.

    This wrapper intentionally launches with a grid that exceeds
    the limits, demonstrating how cooperative launch fails.

    This launch is expected to fail with cudaErrorCooperativeLaunchTooLarge.

    This demonstrates proper error handling for cooperative launch.

    See Also
    --------
    The main() function shows how to properly catch and handle this error.
    """
    # Attempt to launch with way too many blocks
    cooperative_kernel(barrier_ptr).launch(
        grid=(10000, 1, 1),  # 10,000 blocks
        block=(1024, 1, 1),  # 1,024 threads per block
        cooperative=True,  # Cooperative launch will reject this
    )


if __name__ == "__main__":
    # Initialize CUDA context
    cutlass.cuda.initialize_cuda_context()

    # Allocate barrier memory
    # Allocate 4 bytes in device global memory for the barrier state
    barrier_ptr = GlobalBarrier.allocate()

    # Demonstrate expected failure (grid too large)
    expectedly_failed = False
    try:
        # Attempt to launch with 10,000 blocks - this WILL fail
        xfail_run_cooperative_kernel(barrier_ptr)
    except DSLCudaRuntimeError as e:
        # Verify we got the expected error code
        assert (
            e.error_code == cuda_runtime.cudaError_t.cudaErrorCooperativeLaunchTooLarge
        )
        expectedly_failed = True
    finally:
        # Ensure the failure actually happened (test validation)
        assert expectedly_failed

    # Run successful cooperative kernel
    # Launch with a reasonable grid size that fits hardware constraints
    run_cooperative_kernel(barrier_ptr)

    # Synchronize and clean up
    checkCudaErrors(cuda_runtime.cudaDeviceSynchronize())

    # Free the barrier memory
    GlobalBarrier.free(barrier_ptr)
