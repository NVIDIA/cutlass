# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from math import log2, ceil
from typing import Optional, Type, Union, List
import inspect

from cutlass import const_expr
from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import (
    Numeric,
    Float32,
    Boolean,
    extract_mlir_values,
    new_from_mlir_values,
    dsl_user_op,
)
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cute.nvgpu.tcgen05 import find_tmem_tensor_col_offset
from cutlass.cute.arch import get_max_tmem_alloc_cols, get_min_tmem_alloc_cols


_TMEM_COL_MASK = 0x0000FFFF


@dsl_user_op
def compute_tmem_cols_from_layout(
    layout: cute.Layout,
    dtype: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> int:
    """Compute the number of TMEM columns required for a layout with a given dtype.

    This function calculates the column offset by recasting the layout to Int32
    and computing its cosize, similar to how find_tmem_tensor_col_offset works
    but without requiring a tensor.

    :param layout: The TMEM layout to compute columns for.
    :type layout: cute.Layout
    :param dtype: The data type of the elements in the layout.
    :type dtype: Type[Numeric]
    :return: The number of TMEM columns (always a Python int).
    :rtype: int

    :raises ValueError: If the layout size cannot be determined at compile time.
    """
    # Get source width from dtype
    if dtype is Boolean:
        src_width = 8
    else:
        src_width = dtype.width

    # Recast layout to Int32 (32-bit width) as done in find_tmem_tensor_col_offset
    dst_width = 32  # Int32.width
    recasted_layout = cute.recast_layout(dst_width, src_width, layout, loc=loc, ip=ip)

    # Compute cosize and mask
    offset = cute.cosize(recasted_layout, loc=loc, ip=ip) & _TMEM_COL_MASK

    # Ensure we return a Python int
    if isinstance(offset, int):
        return offset

    # Try to fold the DSL value to a Python int
    try:
        return const_expr(offset)
    except Exception:
        raise ValueError(
            "Dynamic TMEM layout size not supported; "
            "the layout size must be determinable at compile time."
        )


class TmemBufferPool:
    """A pool for sub-allocating from a reserved chunk of tensor memory.

    This class enables sub-allocation from a pre-reserved TMEM region,
    eliminating the need for manual offset calculations when allocating
    multiple tensors in TMEM.

    Example usage::

        tmem_pool = tmem_allocator.reserve(tmem_total_size)

        # Allocate and create tensors in one call
        tCtAcc = tmem_pool.allocate_tensor(tCtAcc_layout, cutlass.Float32)
        tCtSFA = tmem_pool.allocate_tensor(tCtSFA_layout, sf_dtype)

        # Or allocate pointer only, then create tensor manually
        sfb_ptr = tmem_pool.allocate(tCtSFB_layout, sf_dtype)
        tCtSFB = cute.make_tensor(sfb_ptr, tCtSFB_layout)

    :ivar _base_ptr: The base pointer to the reserved TMEM region.
    :type _base_ptr: cute.Pointer
    :ivar _total_cols: The total number of columns in the pool.
    :type _total_cols: int
    :ivar _current_offset: The current offset within the pool (in columns).
    :type _current_offset: int
    """

    def __init__(
        self,
        base_ptr: cute.Pointer,
        total_cols: int,
    ):
        """
        Initialize a TmemBufferPool instance.

        :param base_ptr: The base pointer to the reserved TMEM region.
        :type base_ptr: cute.Pointer
        :param total_cols: The total number of columns in the pool.
        :type total_cols: int
        """
        self._base_ptr = base_ptr
        self._total_cols = total_cols
        self._current_offset = 0

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return extract_mlir_values(self._base_ptr)

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "TmemBufferPool":
        assert len(values) == 1
        new_base_ptr = new_from_mlir_values(self._base_ptr, [values[0]])
        pool = TmemBufferPool(new_base_ptr, self._total_cols)
        pool._current_offset = self._current_offset
        return pool

    @property
    def base_ptr(self) -> cute.Pointer:
        """Return the base pointer of the pool."""
        return self._base_ptr

    @property
    def total_cols(self) -> int:
        """Return the total number of columns in the pool."""
        return self._total_cols

    @property
    def current_offset(self) -> int:
        """Return the current offset within the pool."""
        return self._current_offset

    @property
    def remaining_cols(self) -> int:
        """Return the number of remaining columns available for allocation."""
        return self._total_cols - self._current_offset

    @dsl_user_op
    def allocate(
        self,
        size: Union[int, cute.Layout],
        dtype: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        """Allocate a sub-region from the pool and return a pointer.

        This method allocates a contiguous region of TMEM columns from the pool
        and returns a pointer to the start of that region.

        :param size: The allocation size, which can be:
            - int: explicit number of columns to allocate
            - cute.Layout: a TMEM layout that, combined with dtype, determines the size
        :type size: Union[int, cute.Layout]
        :param dtype: The data type for the returned pointer and for computing
            layout size (when size is a Layout).
        :type dtype: Type[Numeric]
        :return: A pointer to the allocated region with the specified dtype.
        :rtype: cute.Pointer

        :raises AssertionError: If there are not enough columns remaining in the pool.

        Example usage::

            # Allocate with explicit column count
            acc_ptr = pool.allocate(64, cutlass.Float32)

            # Allocate based on layout and dtype
            sfa_ptr = pool.allocate(tCtSFA_layout, sf_dtype)
        """
        # Determine number of columns from size argument
        if isinstance(size, cute.Layout):
            num_cols = compute_tmem_cols_from_layout(size, dtype, loc=loc, ip=ip)
        else:
            num_cols = size

        assert self._current_offset + num_cols <= self._total_cols, (
            f"Cannot allocate {num_cols} columns, only {self.remaining_cols} remaining"
        )

        if self._current_offset == 0:
            # First allocation - return base pointer with recast
            ptr = cute.recast_ptr(self._base_ptr, dtype=dtype, loc=loc, ip=ip)
        else:
            # Subsequent allocations - offset from base
            ptr = cute.recast_ptr(
                self._base_ptr + self._current_offset,
                dtype=dtype,
                loc=loc,
                ip=ip,
            )

        self._current_offset += num_cols
        return ptr

    @dsl_user_op
    def allocate_tensor(
        self,
        layout: cute.Layout,
        dtype: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Tensor:
        """Allocate a sub-region from the pool and return a tensor.

        This is a convenience method that combines allocate() and cute.make_tensor()
        into a single call.

        :param layout: The TMEM layout for the tensor.
        :type layout: cute.Layout
        :param dtype: The data type for the tensor elements.
        :type dtype: Type[Numeric]
        :return: A tensor backed by the allocated TMEM region.
        :rtype: cute.Tensor

        :raises AssertionError: If there are not enough columns remaining in the pool.

        Example usage::

            tCtAcc = pool.allocate_tensor(tCtAcc_layout, cutlass.Float32)
            tCtSFA = pool.allocate_tensor(tCtSFA_layout, sf_dtype)
        """
        ptr = self.allocate(layout, dtype, loc=loc, ip=ip)
        return cute.make_tensor(ptr, layout, loc=loc, ip=ip)


class TmemAllocator:
    """A class for managing tensor memory allocation on GPUs.

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
    :ivar _arch: The architecture of the GPU.
    :type _arch: str
    """

    @dsl_user_op
    @cute.jit
    def _init_dealloc_mbarrier(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        assert self._two_cta_tmem_dealloc_mbar_ptr is not None, (
            "two_cta_tmem_dealloc_mbar_ptr is required for two cta"
        )
        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            num_tmem_dealloc_threads = 32
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.arch.mbarrier_init(
                    self._two_cta_tmem_dealloc_mbar_ptr,
                    num_tmem_dealloc_threads,
                    loc=loc,
                    ip=ip,
                )
        cute.arch.mbarrier_init_fence()

    @dsl_user_op
    def __init__(
        self,
        alloc_result_dst_smem_ptr: cute.Pointer,
        barrier_for_retrieve: pipeline.NamedBarrier,
        allocator_warp_id: int = 0,
        is_two_cta: bool = False,
        num_allocated_columns: int = 0,
        two_cta_tmem_dealloc_mbar_ptr: Optional[cute.Pointer] = None,
        *,
        arch: str = "sm_100",
        initialize_mbarrier: bool = True,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Initialize a TmemAllocator instance for managing tensor memory on Blackwell GPUs.

        This initializer sets up the allocator's state, including the shared memory (smem) pointer
        holding the base address of the allocated tensor memory, barrier synchronization for
        retrieving the tensor memory pointer, allocator warp ID, whether the allocator is being used
        for a 2-SM configuration, number of allocated columns in tensor
        memory, and the optional mbarrier pointer for deallocation in the 2-SM case.

        If `is_two_cta` is set to True, this will initialize the mbarrier pointer required for tensor
        memory deallocation across two CTAs.

        :param alloc_result_dst_smem_ptr: The shared memory pointer that holds the base address of allocated tensor memory.
        :type alloc_result_dst_smem_ptr: cute.Pointer
        :param barrier_for_retrieve: The named barrier for retrieving the tensor memory pointer.
        :type barrier_for_retrieve: pipeline.NamedBarrier
        :param allocator_warp_id: The warp ID of the allocator warp, defaults to 0.
        :type allocator_warp_id: int, optional
        :param is_two_cta: Whether the allocator should coordinate two CTAs, defaults to False.
        :type is_two_cta: bool, optional
        :param num_allocated_columns: The number of columns allocated in tensor memory, defaults to 0.
        :type num_allocated_columns: int, optional
        :param two_cta_tmem_dealloc_mbar_ptr: The mbarrier pointer required for two-CTA tensor memory deallocation, optional.
        :type two_cta_tmem_dealloc_mbar_ptr: cute.Pointer, optional
        :param initialize_mbarrier: Whether to initialize the mbarrier for two cta, defaults to True.
        :type initialize_mbarrier: bool, optional
        :param loc: Optional codegen location for debugging and error reporting.
        :type loc: Any, optional
        :param ip: Optional insertion point for codegen.
        :type ip: Any, optional

        :raises AssertionError: If two_cta_tmem_dealloc_mbar_ptr is None while is_two_cta is True.
        """
        # TODO: automatically maintain a smem address
        self._alloc_result_dst_smem_ptr = alloc_result_dst_smem_ptr
        self._allocator_warp_id = allocator_warp_id
        self._is_two_cta = is_two_cta
        self._num_allocated_columns = num_allocated_columns
        self._two_cta_tmem_dealloc_mbar_ptr = two_cta_tmem_dealloc_mbar_ptr
        self._barrier_for_retrieve = barrier_for_retrieve
        self._arch = arch
        self._max_tmem_columns = get_max_tmem_alloc_cols(arch)

        # Init tmem dealloc mbarrier if two cta
        if const_expr(self._is_two_cta and initialize_mbarrier):
            self._init_dealloc_mbarrier(loc=loc, ip=ip)

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
            arch=self._arch,  # Preserve the architecture parameter
            initialize_mbarrier=False,
        )

    @cute.jit
    def check_valid_num_columns(self, num_columns: int) -> bool:
        """Check if the number of columns is valid.

        This method checks if the number of columns is valid.
        It checks if the number of columns is larger than 0, smaller than max capacity, a multiple of 32, and a power of two.
        """
        # larger than 0
        if const_expr(num_columns < 0):
            return False
        # smaller than max capacity
        if const_expr(num_columns > self._max_tmem_columns):
            return False
        # multiple of 32
        if const_expr(num_columns % 32 != 0):
            return False
        # power of two
        if const_expr(
            (num_columns & (num_columns - 1) != 0)
        ):
            return False
        return True

    @dsl_user_op
    @cute.jit
    def allocate(
        self,
        num_columns: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Allocate a block of tensor memory.

        This method allocates a block of tensor memory from allocator warp and returns a handle to retrieve
        the allocated tensor memory address.
        """

        assert self.check_valid_num_columns(num_columns), (
            f"num_columns must be multiple of 32 and power of two, and between 0 and {self._max_tmem_columns}"
        )
        assert self._num_allocated_columns + num_columns <= self._max_tmem_columns, (
            f"total allocated columns must be less than or equal to {self._max_tmem_columns}"
        )

        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            cute.arch.alloc_tmem(
                num_columns,
                self._alloc_result_dst_smem_ptr,
                is_two_cta=self._is_two_cta,
                arch=self._arch,
                loc=loc,
                ip=ip,
            )
        self._num_allocated_columns += num_columns

    @dsl_user_op
    def wait_for_alloc(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Wait for the allocator warp to finish allocation.

        This method is used to synchronize the allocator warp with the other warps before retrieving tmem ptr.
        """
        self._barrier_for_retrieve.arrive_and_wait(loc=loc, ip=ip)

    @dsl_user_op
    def retrieve_ptr(
        self,
        dtype: Type[Numeric] = Float32,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        """Retrieve the pointer to the allocated tensor memory.

        This method can be called by all warps after allocation has been performed
        by the allocator warp.
        """
        return cute.arch.retrieve_tmem_ptr(
            dtype,
            alignment=16,
            ptr_to_buffer_holding_addr=self._alloc_result_dst_smem_ptr,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def reserve(
        self,
        num_columns: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> TmemBufferPool:
        """Reserve a block of tensor memory and return a pool for sub-allocation.

        This method allocates a block of tensor memory, waits for the allocation
        to complete, and returns a TmemBufferPool that can be used to sub-allocate
        regions within that block without manual offset calculations.

        Example usage::

            tmem_pool = tmem_allocator.reserve(tmem_total_size)

            # Allocate and create tensors in one call
            tCtAcc = tmem_pool.allocate_tensor(tCtAcc_layout, cutlass.Float32)
            tCtSFA = tmem_pool.allocate_tensor(tCtSFA_layout, sf_dtype)

            # Or allocate pointer only, then create tensor manually
            sfb_ptr = tmem_pool.allocate(tCtSFB_layout, sf_dtype)
            tCtSFB = cute.make_tensor(sfb_ptr, tCtSFB_layout)

        :param num_columns: The total number of columns to reserve.
        :type num_columns: int
        :return: A TmemBufferPool for sub-allocating within the reserved region.
        :rtype: TmemBufferPool
        """
        self.allocate(num_columns, loc=loc, ip=ip)
        self.wait_for_alloc(loc=loc, ip=ip)
        base_ptr = self.retrieve_ptr(loc=loc, ip=ip)
        return TmemBufferPool(base_ptr, num_columns)

    @dsl_user_op
    @cute.jit
    def relinquish_alloc_permit(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Relinquish the tensor memory allocation permit.

        This method relinquishes the tensor memory allocation permit for the allocator warp, promising
        the allocator warp will not allocate any more tensor memory.
        """
        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)
        _is_allocator_warp = warp_idx == self._allocator_warp_id
        if _is_allocator_warp:
            cute.arch.relinquish_tmem_alloc_permit(
                is_two_cta=self._is_two_cta, loc=loc, ip=ip
            )

    @dsl_user_op
    @cute.jit
    def free(
        self,
        tmem_ptr: cute.Pointer,
        num_columns: int = 0,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Deallocate the tensor memory.

        This method sync on mbarrier (for two cta use case) and deallocates the tensor memory from the allocator warp.
        User can optionally specify the number of columns to deallocate. If not specified, all allocated columns will be deallocated.
        """
        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)
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
                bid_in_cluster = cute.arch.block_idx_in_cluster(loc=loc, ip=ip)
                _cta_rank_in_cluster = cute.arch.make_warp_uniform(
                    bid_in_cluster, loc=loc, ip=ip
                )
                # Arrive and wait for dealloc signal from peer cta
                cute.arch.mbarrier_arrive(
                    self._two_cta_tmem_dealloc_mbar_ptr,
                    _cta_rank_in_cluster ^ 1,
                    loc=loc,
                    ip=ip,
                )
                cute.arch.mbarrier_wait(
                    self._two_cta_tmem_dealloc_mbar_ptr, 0, loc=loc, ip=ip
                )
            # Deallocate tmem
            cute.arch.dealloc_tmem(
                tmem_ptr,
                num_deallocate_columns,
                is_two_cta=self._is_two_cta,
                arch=self._arch,
                loc=loc,
                ip=ip,
            )


# Set explicit signature for Sphinx documentation to avoid issues with @dsl_user_op decorator
TmemAllocator.__init__.__signature__ = inspect.Signature(  # type: ignore[attr-defined]
    [
        inspect.Parameter("self", inspect.Parameter.POSITIONAL_OR_KEYWORD),
        inspect.Parameter(
            "alloc_result_dst_smem_ptr",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            annotation=cute.Pointer,
        ),
        inspect.Parameter(
            "barrier_for_retrieve",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            annotation=pipeline.NamedBarrier,
        ),
        inspect.Parameter(
            "allocator_warp_id",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            default=0,
            annotation=int,
        ),
        inspect.Parameter(
            "is_two_cta",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            default=False,
            annotation=bool,
        ),
        inspect.Parameter(
            "num_allocated_columns",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            default=0,
            annotation=int,
        ),
        inspect.Parameter(
            "two_cta_tmem_dealloc_mbar_ptr",
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            default=None,
            annotation=Optional[cute.Pointer],
        ),
    ]
)


def get_num_tmem_alloc_cols(
    tmem_tensors: Union[cute.Tensor, List[cute.Tensor]],
    rounding: bool = True,
    *,
    arch: str = "sm_100",
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> int:
    """Get the total number of TMEM allocation columns for the given TMEM tensors.

    :param tmem_tensors: The TMEM tensors to get the number of allocation columns for.
    :type tmem_tensors: Union[cute.Tensor, List[cute.Tensor]]
    :param rounding: Whether to round up the number of allocation columns to the nearest power of 2.
    :type rounding: bool
    :param arch: The architecture of the GPU.
    :type arch: str
    :return: The total number of TMEM allocation columns.
    :rtype: int

    :raises ValueError: If the number of TMEM allocation columns exceeds the maximum capacity or is less than 32.
    """
    # Turn tmem_tensors into a list
    if isinstance(tmem_tensors, cute.Tensor):
        tmem_tensors = [tmem_tensors]

    tmem_max_alloc_cols = get_max_tmem_alloc_cols(arch)
    tmem_min_alloc_cols = get_min_tmem_alloc_cols(arch)

    # For each tensor in tmem_tensors, find the tmem_tensor_col_offset
    num_tmem_alloc_cols_per_tensor = [
        find_tmem_tensor_col_offset(t) for t in tmem_tensors
    ]

    # Sum up the num_tmem_alloc_cols_per_tensor
    num_tmem_alloc_cols = sum(num_tmem_alloc_cols_per_tensor)

    # Round up num_tmem_cols_total to the nearest power of 2 and make sure it is at least 32
    if rounding:
        num_tmem_alloc_cols = max(
            1 << ceil(log2(num_tmem_alloc_cols)), tmem_min_alloc_cols
        )

    # Validate the number of TMEM allocation columns
    if (
        num_tmem_alloc_cols > tmem_max_alloc_cols
        or num_tmem_alloc_cols < tmem_min_alloc_cols
    ):
        raise ValueError(
            f"TMEM allocation columns {num_tmem_alloc_cols} exceeds the maximum capacity of {tmem_max_alloc_cols} or less than {tmem_min_alloc_cols}"
        )
    return num_tmem_alloc_cols
