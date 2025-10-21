# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Optional, Type

from cutlass import const_expr
from cutlass.cutlass_dsl import (
    Numeric,
    Float32,
    extract_mlir_values,
    new_from_mlir_values,
)
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass._mlir import ir


class TmemAllocator:
    """A class for managing tensor memory allocation on Blackwell GPU.

    This class manages allocation/deallocation of tensor memory, including the mbarrier
    synchronization for two cta use case.

    :ivar _alloc_result_dst_smem_ptr: The smem pointer that holds the base address of allocated tensor memory.
    :type _alloc_result_dst_smem_ptr: cute.Pointer
    :ivar _barrier_for_retrieve: The barrier for retrieving tensor memory ptr.
    :type _barrier_for_retrieve: pipeline.NamedBarrier
    :ivar _allocator_warp_id: The warp id of the allocator warp.
    :type _allocator_warp_id: int
    :ivar _is_two_cta: Whether the allocator is for two cta.
    :type _is_two_cta: bool
    :ivar _num_allocated_columns: The number of columns allocated in the tensor memory.
    :type _num_allocated_columns: int
    :ivar _two_cta_tmem_dealloc_mbar_ptr: The mbarrier pointer required when deallocating tensor memory for two cta.
    :type _two_cta_tmem_dealloc_mbar_ptr: cute.Pointer
    """

    @cute.jit
    def _init_dealloc_mbarrier(self):
        assert self._two_cta_tmem_dealloc_mbar_ptr is not None, (
            "two_cta_tmem_dealloc_mbar_ptr is required for two cta"
        )
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            num_tmem_dealloc_threads = 32
            with cute.arch.elect_one():
                cute.arch.mbarrier_init(
                    self._two_cta_tmem_dealloc_mbar_ptr, num_tmem_dealloc_threads
                )
        cute.arch.mbarrier_init_fence()

    def __init__(
        self,
        alloc_result_dst_smem_ptr: cute.Pointer,
        barrier_for_retrieve: pipeline.NamedBarrier,
        allocator_warp_id: int = 0,
        is_two_cta: bool = False,
        num_allocated_columns: int = 0,
        two_cta_tmem_dealloc_mbar_ptr: Optional[cute.Pointer] = None,
    ):
        """Initialize the TmemAllocator instance.

        Sets up the allocator state by initializing smem pointer that holds the base address of allocated tensor memory, allocator warp id, whether it is for two cta, number of allocated columns, and barrier for retrieving tensor memory ptr.
        Meanwhile, it also initializes the mbarrier pointer for two cta deallocation case.
        """
        # TODO: automatically maintain a smem address
        self._alloc_result_dst_smem_ptr = alloc_result_dst_smem_ptr
        self._allocator_warp_id = allocator_warp_id
        self._is_two_cta = is_two_cta
        self._num_allocated_columns = num_allocated_columns
        self._two_cta_tmem_dealloc_mbar_ptr = two_cta_tmem_dealloc_mbar_ptr
        self._barrier_for_retrieve = barrier_for_retrieve

        # Init tmem dealloc mbarrier if two cta
        if const_expr(self._is_two_cta):
            self._init_dealloc_mbarrier()

    def __extract_mlir_values__(self) -> list[ir.Value]:
        values = extract_mlir_values(self._alloc_result_dst_smem_ptr)
        if self._is_two_cta:
            assert self._two_cta_tmem_dealloc_mbar_ptr is not None, (
                "2CTA mode requires the dealloc mbarrier"
            )
            values.extend(extract_mlir_values(self._two_cta_tmem_dealloc_mbar_ptr))
        return values

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "TmemAllocator":
        assert len(values) == 2 if self._is_two_cta else 1
        new_alloc_result_dst_smem_ptr = new_from_mlir_values(
            self._alloc_result_dst_smem_ptr, [values[0]]
        )
        new_two_cta_tmem_dealloc_mbar_ptr = (
            new_from_mlir_values(self._two_cta_tmem_dealloc_mbar_ptr, [values[1]])
            if self._is_two_cta
            else None
        )
        return TmemAllocator(
            new_alloc_result_dst_smem_ptr,
            pipeline.NamedBarrier(
                barrier_id=self._barrier_for_retrieve.barrier_id,
                num_threads=self._barrier_for_retrieve.num_threads,
            ),
            self._allocator_warp_id,
            self._is_two_cta,
            self._num_allocated_columns,
            new_two_cta_tmem_dealloc_mbar_ptr,
        )

    @cute.jit
    def check_valid_num_columns(self, num_columns: int):
        """Check if the number of columns is valid.

        This method checks if the number of columns is valid.
        It checks if the number of columns is larger than 0, smaller than 512, a multiple of 32, and a power of two.
        """
        # larger than 0
        if const_expr(num_columns < 0):
            return False
        # smaller than 512
        if const_expr(num_columns > 512):
            return False
        # multiple of 32
        if const_expr(num_columns % 32 != 0):
            return False
        # power of two
        if const_expr(num_columns & (num_columns - 1) != 0):
            return False
        return True

    @cute.jit
    def allocate(self, num_columns: int):
        """Allocate a block of tensor memory.

        This method allocates a block of tensor memory from allocator warp and returns a handle to retrieve
        the allocated tensor memory address.
        """

        assert self.check_valid_num_columns(num_columns), (
            "num_columns must be multiple of 32 and power of two, and between 0 and 512"
        )
        assert self._num_allocated_columns + num_columns <= 512, (
            "total allocated columns must be less than or equal to 512"
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            cute.arch.alloc_tmem(
                num_columns,
                self._alloc_result_dst_smem_ptr,
                is_two_cta=self._is_two_cta,
            )
        self._num_allocated_columns += num_columns

    @cute.jit
    def wait_for_alloc(self):
        """Wait for the allocator warp to finish allocation.

        This method is used to synchronize the allocator warp with the other warps before retrieving tmem ptr.
        """
        self._barrier_for_retrieve.arrive_and_wait()

    @cute.jit
    def retrieve_ptr(
        self,
        dtype: Type[Numeric] = Float32,
    ) -> cute.Pointer:
        """Retrieve the pointer to the allocated tensor memory.

        This method can be called by all warps after allocation has been performed
        by the allocator warp.
        """
        return cute.arch.retrieve_tmem_ptr(
            dtype,
            alignment=16,
            ptr_to_buffer_holding_addr=self._alloc_result_dst_smem_ptr,
        )

    @cute.jit
    def relinquish_alloc_permit(self):
        """Relinquish the tensor memory allocation permit.

        This method relinquishes the tensor memory allocation permit for the allocator warp, promising
        the allocator warp will not allocate any more tensor memory.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            cute.arch.relinquish_tmem_alloc_permit(is_two_cta=self._is_two_cta)

    @cute.jit
    def free(self, tmem_ptr: cute.Pointer, num_columns: int = 0):
        """Deallocate the tensor memory.

        This method sync on mbarrier (for two cta use case) and deallocates the tensor memory from the allocator warp.
        User can optionally specify the number of columns to deallocate. If not specified, all allocated columns will be deallocated.
        """
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        _is_allocator_warp = warp_idx == self._allocator_warp_id

        assert num_columns <= self._num_allocated_columns, (
            "num_columns must be less than or equal to num_allocated_columns"
        )
        if const_expr(num_columns != 0):
            assert self.check_valid_num_columns(num_columns), "num_columns is invalid"

        num_deallocate_columns = (
            self._num_allocated_columns if num_columns == 0 else num_columns
        )  # if num_columns is 0, deallocate all allocated columns
        self._num_allocated_columns -= num_deallocate_columns
        if _is_allocator_warp:
            if const_expr(self._is_two_cta):
                _cta_rank_in_cluster = cute.arch.make_warp_uniform(
                    cute.arch.block_idx_in_cluster()
                )
                # Arrive and wait for dealloc signal from peer cta
                cute.arch.mbarrier_arrive(
                    self._two_cta_tmem_dealloc_mbar_ptr, _cta_rank_in_cluster ^ 1
                )
                cute.arch.mbarrier_wait(self._two_cta_tmem_dealloc_mbar_ptr, 0)
            # Deallocate tmem
            cute.arch.dealloc_tmem(
                tmem_ptr, num_deallocate_columns, is_two_cta=self._is_two_cta
            )
