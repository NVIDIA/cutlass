# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
Online TMA Descriptor Construction Utilities.

Provides utilities for dynamically creating TMA descriptors at kernel runtime
based on runtime-provided information (problem sizes, pointers, etc.).

Key components:
- OnlineTensormapDescCreator: Simplified ABC for TMA descriptor builders (2 abstract methods)
- TensormapWorkspace: Helper for linear workspace layout of TMA descriptors
- MoEGroupedGemmTensormapConstructor: TMA descriptor constructor for MoE Grouped GEMM
- Pointer utility functions (ptr_offset_bytes, gmem_ptr_to_generic, etc.)
- tensormap_ptr_for_copy: Convert raw desc ptr to cute.copy-compatible type
- compute_expert_token_range: Compute per-expert token offset and count from offs
- rewrite_tensor_shape: Debug-friendly tensor shape rewrite utility
"""

from abc import ABC, abstractmethod
from typing import Literal, Tuple

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import AddressSpace, Pointer
from cutlass.cute.nvgpu import cpasync
from cutlass.cutlass_dsl import dsl_user_op, Int32
from cutlass._mlir.dialects import nvvm, llvm
from cutlass._mlir.dialects import cute as _cute_ir
from cutlass._mlir.dialects import cute_nvgpu as _cute_nvgpu_ir
from .dsl_objects import DeviceOnlyObj, UntracedPyObj

TensormapDescBytes = 128


# =============================================================================
# Pointer Utilities
# =============================================================================

@dsl_user_op
@cute.jit
def spin_wait(
    ptr: Pointer,
    condition,
    fail_sleep_cycles: int = 100,
    *, loc=None, ip=None
) -> None:
    """
    Generic spin-wait.
    Example usage:
        # Wait until counter >= total_blocks
        spin_wait(counter_ptr, lambda x: x >= total_blocks, fail_sleep_cycles=100)

        # Wait until flag == 1
        spin_wait(flag_ptr, lambda x: x == 1)
    """
    current = cute.arch.load(ptr, ptr.dtype, cop="cg", loc=loc, ip=ip)
    while not condition(current):
        # Load with L1 cache bypass (ld.global.cg)
        if cutlass.const_expr(fail_sleep_cycles > 0):
            cute.arch.nanosleep(sleep_time=fail_sleep_cycles, loc=loc, ip=ip)
        current = cute.arch.load(ptr, ptr.dtype, cop="cg", loc=loc, ip=ip)


@dsl_user_op
def gmem_ptr_to_generic(gmem_ptr: Pointer, *, loc=None, ip=None) -> Pointer:
    if gmem_ptr.memspace != AddressSpace.gmem:
        raise ValueError(
            f"gmem_ptr_to_generic requires pointer in gmem address space, "
            f"got {gmem_ptr.memspace}"
        )
    # Get LLVM pointer and cast to generic address space
    llvm_ptr = gmem_ptr.to_llvm_ptr(loc=loc, ip=ip)
    generic_llvm_ptr = llvm.addrspacecast(
        llvm.PointerType.get(AddressSpace.generic), llvm_ptr, loc=loc, ip=ip
    )
    # Create a new cute.Pointer with generic address space, preserving alignment
    return cute.make_ptr(
        gmem_ptr.dtype, generic_llvm_ptr, AddressSpace.generic,
        assumed_align=gmem_ptr.alignment, loc=loc, ip=ip
    )

@dsl_user_op
def generic_ptr_to_gmem(generic_ptr: Pointer, *, loc=None, ip=None) -> Pointer:
    if generic_ptr.memspace != AddressSpace.generic:
        raise ValueError(
            f"generic_ptr_to_gmem requires pointer in generic address space, "
            f"got {generic_ptr.memspace}"
        )
    # Get LLVM pointer and cast to gmem address space
    llvm_ptr = generic_ptr.to_llvm_ptr(loc=loc, ip=ip)
    gmem_llvm_ptr = llvm.addrspacecast(
        llvm.PointerType.get(AddressSpace.gmem), llvm_ptr, loc=loc, ip=ip
    )
    # Create a new cute.Pointer with gmem address space, preserving alignment
    return cute.make_ptr(
        generic_ptr.dtype, gmem_llvm_ptr, AddressSpace.gmem,
        assumed_align=generic_ptr.alignment, loc=loc, ip=ip
    )


@dsl_user_op
def prefetch_tma_descriptor(tma_desc_ptr: Pointer, *, loc=None, ip=None) -> None:
    """
    Prefetch a TMA descriptor from global memory.

    This function prefetches the TMA descriptor pointed to by tma_desc_ptr
    into the TMA descriptor cache. The pointer must be in generic or global
    address space. If a gmem pointer is passed, it will be automatically
    converted to generic address space.

    :param tma_desc_ptr: Pointer to the TMA descriptor in global or generic memory
    :type tma_desc_ptr: Pointer
    :raises ValueError: If pointer is not in generic or global address space
    """
    if tma_desc_ptr.memspace not in (AddressSpace.gmem, AddressSpace.generic):
        raise ValueError(
            f"prefetch_tma_descriptor requires pointer in gmem or generic address space, "
            f"got {tma_desc_ptr.memspace}"
        )
    # Convert gmem pointer to generic if needed
    if tma_desc_ptr.memspace == AddressSpace.gmem:
        tma_desc_ptr = gmem_ptr_to_generic(tma_desc_ptr, loc=loc, ip=ip)
    # Convert cute.Pointer to LLVM pointer for nvvm.prefetch
    llvm_ptr = tma_desc_ptr.to_llvm_ptr(loc=loc, ip=ip)
    nvvm.prefetch(llvm_ptr, tensormap=True, loc=loc, ip=ip)


def ptr_offset_bytes(ptr: Pointer, byte_offset: int) -> Pointer:
    """Offset a pointer by a given number of bytes."""
    element_offset = byte_offset * 8 // ptr.dtype.width
    return ptr + element_offset


@dsl_user_op
def tensormap_ptr_for_copy(raw_ptr: Pointer, *, loc=None, ip=None) -> Pointer:
    """
    Convert a raw TMA descriptor gmem pointer to the type expected by cute.copy.

    cute.copy requires the tma_desc_ptr to be in generic address space and
    recast to TmaDescriptorTiledType. This utility performs both conversions.

    :param raw_ptr: Raw pointer to TMA descriptor in gmem
    :type raw_ptr: Pointer
    :return: Pointer compatible with cute.copy's tma_desc_ptr parameter
    :rtype: Pointer
    """
    generic_ptr = gmem_ptr_to_generic(raw_ptr, loc=loc, ip=ip)
    tma_desc_ptr_ty = _cute_ir.PtrType.get(
        _cute_nvgpu_ir.TmaDescriptorTiledType.get(),
        generic_ptr.memspace,
        generic_ptr.alignment,
    )
    return _cute_ir.recast_iter(tma_desc_ptr_ty, generic_ptr.value)


# =============================================================================
# MoE Utilities
# =============================================================================

@dsl_user_op
@cute.jit
def compute_expert_token_range(
    offs: cute.Tensor,
    expert_idx: Int32,
    *, loc=None, ip=None,
) -> Tuple[Int32, Int32]:
    """
    Compute token offset and count for a given expert from the cumsum offs tensor.

    :param offs: Cumulative sum tensor of token counts per expert, shape (experts,)
    :param expert_idx: Index of the expert
    :return: (token_offset, tokens_i) where token_offset is the start position
             and tokens_i is the number of tokens for this expert
    """
    token_offset = Int32(0)
    if expert_idx > Int32(0):
        token_offset = offs[expert_idx - 1]
    tokens_i = offs[expert_idx] - token_offset
    return token_offset, tokens_i


@dsl_user_op
def rewrite_tensor_shape(
    tensor: cute.Tensor,
    new_shape: Tuple,
    *,
    loc=None,
    ip=None,
) -> cute.Tensor:
    """
    Rewrite tensor shape while keeping the same stride and iterator.

    This is primarily for debug friendliness - shows the actual expert's shape
    instead of the fake global shape. No runtime overhead as it becomes
    dead code in non-debug builds.

    :param tensor: Source tensor whose stride and iterator to preserve
    :param new_shape: New shape to apply
    :return: New tensor with the given shape but original stride and iterator
    """
    new_layout = cute.make_layout(new_shape, stride=tensor.stride, loc=loc, ip=ip)
    return cute.make_tensor(tensor.iterator, new_layout, loc=loc, ip=ip)


# =============================================================================
# TMA Descriptor Workspace Helper
# =============================================================================

class TensormapWorkspace:
    """
    Helper for linear workspace layout of TMA descriptors.

    Manages address calculation for a workspace buffer containing TMA descriptors
    organized as: for each executor (e.g., expert or group), a fixed set of
    named descriptor slots.

    Layout: [slot_0_exec_0, slot_1_exec_0, ..., slot_0_exec_1, slot_1_exec_1, ...]

    Example:
        # 2Dx3D MoE: only C is expert-wise
        workspace = TensormapWorkspace(workspace_ptr, ["c"])

        # 2Dx2D MoE: A and B are expert-wise
        workspace = TensormapWorkspace(workspace_ptr, ["a", "b"])
    """

    def __init__(self, workspace_ptr: Pointer, slot_names: list):
        """
        :param workspace_ptr: Pointer to the beginning of the workspace buffer
        :param slot_names: Ordered list of tensor names, defining the slot layout
                           per executor. e.g., ["a", "b", "c"]
        """
        self.workspace_ptr = workspace_ptr
        self._name_to_slot = {name: i for i, name in enumerate(slot_names)}
        self._slots_per_executor = len(slot_names)

    @cute.jit
    def get_ptr(self, tensor_name: str, executor_idx: Int32) -> Pointer:
        """
        Get the workspace pointer for a specific TMA descriptor.

        :param tensor_name: Name of the tensor (must be one of the slot_names)
        :param executor_idx: Index of the executor (e.g., group_idx or expert_idx)
        :return: Aligned pointer to the TMA descriptor in workspace
        """
        slot = self._name_to_slot[tensor_name]  # codegen-time constant lookup
        byte_offset = (executor_idx * self._slots_per_executor + slot) * TensormapDescBytes
        return ptr_offset_bytes(self.workspace_ptr, byte_offset).align(TensormapDescBytes)

    @staticmethod
    def size_bytes(num_slots: int, num_executors: int) -> int:
        """
        Calculate workspace size in bytes.

        :param num_slots: Number of descriptor slots per executor
        :param num_executors: Total number of executors (e.g., expert_cnt or group_cnt)
        :return: Total workspace size in bytes
        """
        return num_slots * num_executors * TensormapDescBytes


# =============================================================================
# Online TMA Descriptor Creator (Abstract Base Class)
# =============================================================================

class OnlineTensormapDescCreator(ABC, DeviceOnlyObj, UntracedPyObj):
    """
    Abstract base class for building TMA descriptors online (at kernel runtime).

    Subclasses store all needed parameters (both codegen-time configs and runtime
    values) as explicit instance attributes in __init__. No dict-based APIs.

    Subclasses must implement exactly 2 abstract methods:
    - construct_and_write: Build TMA descriptor(s) for one executor and write to workspace
    - get_desc_ptr: Return raw gmem pointer to a specific descriptor in workspace

    To convert the raw pointer for use with cute.copy, callers should use the
    standalone tensormap_ptr_for_copy() utility.
    """

    @abstractmethod
    def construct_and_write(self, executor_idx: Int32) -> None:
        """
        Build TMA descriptor(s) for one executor and write to workspace.

        :param executor_idx: Index of the executor (e.g., group_idx or expert_idx)
        """
        ...

    @abstractmethod
    def get_desc_ptr(self, tensor_name: str, executor_idx: Int32) -> Pointer:
        """
        Get the raw gmem pointer to a specific TMA descriptor in workspace.

        :param tensor_name: Name identifying which tensor's descriptor
        :param executor_idx: Index of the executor (e.g., group_idx or expert_idx)
        :return: Raw pointer (gmem) to the TMA descriptor
        """
        ...


# =============================================================================
# MoE Grouped GEMM Tensormap Constructor
# =============================================================================

class MoEGroupedGemmTensormapConstructor(OnlineTensormapDescCreator):
    """
    Tensormap descriptor constructor for MoE Grouped GEMM (expert-wise descriptors only).

    Non-expert-wise descriptors are passed directly at kernel launch.
    This class only handles:
    - 2Dx3D: C descriptors (expert-wise, to avoid write conflicts)
    - 2Dx2D: A and B descriptors (expert-wise, tokens is reduction axis)

    All parameters are stored as explicit instance attributes (no dicts).

    Workspace layout:
    - 2Dx3D: [C_0, C_1, ..., C_{n-1}]
    - 2Dx2D: [A_0, A_1, ..., A_{n-1}, B_0, B_1, ..., B_{n-1}]
    """

    def __init__(
        self,
        scenario: Literal["2Dx3D", "2Dx2D"],
        # Codegen-time configs
        a_dtype, b_dtype, c_dtype,
        a_smem_layout, b_smem_layout, epi_smem_layout,
        a_tma_op, b_tma_op, c_tma_op,
        tiled_mma, mma_tiler, cluster_layout_vmnk_shape, epi_tile,
        # Runtime params
        a_tensor: cute.Tensor,  # fake GEMM domain A
        b_tensor: cute.Tensor,  # fake GEMM domain B
        c_tensor: cute.Tensor,  # fake GEMM domain C
        offs: cute.Tensor,      # (experts,) cumsum
        workspace_ptr: Pointer,
    ) -> None:
        super().__init__()
        self.scenario = scenario
        # Codegen-time configs
        self.a_dtype = a_dtype
        self.b_dtype = b_dtype
        self.c_dtype = c_dtype
        self.a_smem_layout = a_smem_layout
        self.b_smem_layout = b_smem_layout
        self.epi_smem_layout = epi_smem_layout
        self.a_tma_op = a_tma_op
        self.b_tma_op = b_tma_op
        self.c_tma_op = c_tma_op
        self.tiled_mma = tiled_mma
        self.mma_tiler = mma_tiler
        self.cluster_layout_vmnk_shape = cluster_layout_vmnk_shape
        self.epi_tile = epi_tile
        # Runtime params
        self.a_tensor = a_tensor
        self.b_tensor = b_tensor
        self.c_tensor = c_tensor
        self.offs = offs
        # Workspace with scenario-specific slot layout
        if scenario == "2Dx3D":
            self.workspace = TensormapWorkspace(workspace_ptr, ["c"])
        else:
            self.workspace = TensormapWorkspace(workspace_ptr, ["a", "b"])

    @staticmethod
    def get_workspace_size(scenario: Literal["2Dx3D", "2Dx2D"], expert_cnt: int) -> int:
        """Calculate workspace size in bytes for tensormap descriptors."""
        if scenario == "2Dx3D":
            return TensormapWorkspace.size_bytes(1, expert_cnt)   # only C
        else:
            return TensormapWorkspace.size_bytes(2, expert_cnt)   # A and B

    @cute.jit
    def get_desc_ptr(self, tensor_name: str, executor_idx: cutlass.Int32) -> Pointer:
        return self.workspace.get_ptr(tensor_name, executor_idx)

    @cute.jit
    def construct_and_write(self, executor_idx: cutlass.Int32) -> None:
        """
        Create expert-wise tensormap descriptors for the given expert.

        - 2Dx3D: Creates C descriptor for this expert
        - 2Dx2D: Creates A and B descriptors for this expert
        """
        if cutlass.const_expr(self.scenario == "2Dx3D"):
            self._construct_c_desc_2dx3d(executor_idx)
        else:  # 2Dx2D
            self._construct_ab_descs_2dx2d(executor_idx)

    @cute.jit
    def _construct_c_desc_2dx3d(self, expert_idx: cutlass.Int32) -> None:
        """
        2Dx3D: Create expert-wise C descriptor.
        C tensor: (fake_m, n, 1) = (tokens_sum, intermediate, 1)
        Slice fake_m -> (tokens_i, intermediate, 1) per expert.
        """
        token_offset, tokens_i = compute_expert_token_range(self.offs, expert_idx)

        c_ptr = self.c_tensor.iterator
        c_stride = self.c_tensor.stride
        intermediate = self.c_tensor.shape[1]

        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        c_ptr_i = c_ptr + token_offset * c_stride[0]
        c_layout_i = cute.make_layout(
            (tokens_i, intermediate, c1), stride=(c_stride[0], c_stride[1], c0)
        )
        c_tensor_i = cute.make_tensor(c_ptr_i, c_layout_i)

        tma_atom_c, _ = cpasync.make_tiled_tma_atom(
            self.c_tma_op, c_tensor_i, self.epi_smem_layout, self.epi_tile,
        )
        cpasync.copy_tensormap(tma_atom_c, self.get_desc_ptr("c", expert_idx))

    @cute.jit
    def _construct_ab_descs_2dx2d(self, expert_idx: cutlass.Int32) -> None:
        """
        2Dx2D: Create expert-wise A and B descriptors.
        A: (m, fake_k, 1) -> slice to (m, tokens_i, 1)
        B: (n, fake_k, 1) -> slice to (n, tokens_i, 1)
        """
        token_offset, tokens_i = compute_expert_token_range(self.offs, expert_idx)

        c1 = cutlass.Int32(1)
        c0 = cutlass.Int32(0)

        # A tensor: (m, fake_k, 1) -> (m, tokens_i, 1)
        a_ptr = self.a_tensor.iterator
        a_stride = self.a_tensor.stride
        a_m = self.a_tensor.shape[0]

        a_ptr_i = a_ptr + token_offset * a_stride[1]
        a_layout_i = cute.make_layout(
            (a_m, tokens_i, c1), stride=(a_stride[0], a_stride[1], c0)
        )
        a_tensor_i = cute.make_tensor(a_ptr_i, a_layout_i)

        tma_atom_a, _ = cute.nvgpu.make_tiled_tma_atom_A(
            self.a_tma_op, a_tensor_i, self.a_smem_layout,
            self.mma_tiler, self.tiled_mma, self.cluster_layout_vmnk_shape,
        )
        cpasync.copy_tensormap(tma_atom_a, self.get_desc_ptr("a", expert_idx))

        # B tensor: (n, fake_k, 1) -> (n, tokens_i, 1)
        b_ptr = self.b_tensor.iterator
        b_stride = self.b_tensor.stride
        b_n = self.b_tensor.shape[0]

        b_ptr_i = b_ptr + token_offset * b_stride[1]
        b_layout_i = cute.make_layout(
            (b_n, tokens_i, c1), stride=(b_stride[0], b_stride[1], c0)
        )
        b_tensor_i = cute.make_tensor(b_ptr_i, b_layout_i)

        tma_atom_b, _ = cute.nvgpu.make_tiled_tma_atom_B(
            self.b_tma_op, b_tensor_i, self.b_smem_layout,
            self.mma_tiler, self.tiled_mma, self.cluster_layout_vmnk_shape,
        )
        cpasync.copy_tensormap(tma_atom_b, self.get_desc_ptr("b", expert_idx))
