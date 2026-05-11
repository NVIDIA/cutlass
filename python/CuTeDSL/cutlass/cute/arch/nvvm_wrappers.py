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

from functools import partial
from typing import Any, Optional, Tuple, Union, Callable, Literal, Type, overload
from typing_extensions import deprecated

from cutlass.cutlass_dsl import T, dsl_user_op

import cutlass.cutlass_dsl as cutlass_dsl

from cutlass._mlir import ir
from cutlass._mlir.dialects import arith, builtin, llvm, math, nvvm as _nvvm_raw, vector
from cutlass.base_dsl._mlir_helpers.dialect_proxy import DialectAutoConvertProxy

from ..core import size

from ..typing import (
    Int,
    Boolean,
    Integer,
    Int8,
    Int16,
    Uint16,
    Int32,
    Uint32,
    Int64,
    Float16,
    Float32,
    BFloat16,
    Numeric,
    Uint64,
    Pointer,
    as_numeric,
)

WARP_SIZE = 32
FULL_MASK = 0xFFFFFFFF

# Create the proxy instance to replace the raw nvvm module
nvvm = DialectAutoConvertProxy(_nvvm_raw)


# ============================================================================
# Helper
# ============================================================================


def _enhance_enum_with_str_mapping(enum_class: Any) -> Any:
    """
    Enhance an IntEnum class with automatic string-to-enum conversion.

    Builds a reverse mapping from __str__() output to enum members and adds
    a from_str() class method for conversion. Safe to call multiple times
    (idempotent - won't re-enhance if already enhanced).

    :param enum_class: The enum class to enhance
    :return: The enhanced enum class (for chaining)
    """
    # Skip if already enhanced
    if hasattr(enum_class, "from_str"):
        return enum_class

    # Build reverse mapping from string representation to enum member
    str_to_enum_map = {}
    for member in enum_class:
        str_repr = str(member)
        if str_repr in str_to_enum_map:
            raise ValueError(
                f"Duplicate string representation '{str_repr}' in {enum_class.__name__}"
            )
        str_to_enum_map[str_repr] = member

    # Add from_str class method
    @classmethod  # type: ignore[misc]
    def from_str(cls: Any, s: Any) -> Any:
        """
        Convert a string literal to the corresponding enum member.

        :param s: String representation of the enum member
        :return: The enum member (or None if s is None)
        :raises ValueError: If the string is not a valid enum member
        :raises TypeError: If an enum is passed instead of a string
        """

        if s is None:
            return None

        # Check if user passed an enum (should be a string literal instead)
        # This catches cases where user passes e.g., FPRoundingMode.RN instead of "rn"
        from enum import Enum

        if isinstance(s, Enum):
            if cutlass_dsl.target_version(exact_version="12.9"):
                import warnings

                warnings.warn(
                    f"Passing enum member directly to {cls.__name__}.from_str() is deprecated. "
                    f"Please use string literals instead (e.g., '{str(s)}' instead of {cls.__name__}.{s.name}).",
                    DeprecationWarning,
                    stacklevel=2,
                )
                return s
            else:
                raise TypeError(
                    f"Expected a string literal for {cls.__name__}, but got enum '{type(s).__name__}.{s.name}'. "
                    f"Please pass a string instead (e.g., '{str(s)}' instead of {type(s).__name__}.{s.name}). "
                    f"Valid string options are: {sorted(str_to_enum_map.keys())}"
                )

        if s not in str_to_enum_map:
            valid_options = sorted(str_to_enum_map.keys())
            raise ValueError(
                f"Invalid {cls.__name__} string: '{s}'. "
                f"Valid options are: {valid_options}"
            )
        return str_to_enum_map[s]

    enum_class.from_str = from_str
    return enum_class


def _cutlass_dtype_to_reduction_type_str(cutlass_dtype: type[Numeric]) -> str:
    """
    Convert cutlass data type to ReductionType string literal.

    :param cutlass_dtype: Cutlass data type (e.g., cutlass.Uint32, cutlass.Float32)
    :type cutlass_dtype: type[Numeric]
    :return: ReductionType string literal (e.g., "u32", "f32")
    :rtype: str
    :raises ValueError: If cutlass_dtype is not supported for reduction operations

    Supported conversions:
        cutlass.Uint32 -> "u32"
        cutlass.Uint64 -> "u64"
        cutlass.Int32 -> "s32"
        cutlass.Int64 -> "s64"
        cutlass.Float32 -> "f32"
        cutlass.Float64 -> "f64"
        cutlass.Float16 -> "f16"
        cutlass.BFloat16 -> "bf16"
    """
    import cutlass

    # Mapping from cutlass types to ReductionType string literals
    dtype_map = {
        cutlass.Uint32: "u32",
        cutlass.Uint64: "u64",
        cutlass.Int32: "s32",
        cutlass.Int64: "s64",
        cutlass.Float32: "f32",
        cutlass.Float64: "f64",
        cutlass.Float16: "f16",
        cutlass.BFloat16: "bf16",
    }

    if cutlass_dtype not in dtype_map:
        valid_types = ", ".join([t.__name__ for t in dtype_map.keys()])
        raise ValueError(
            f"Invalid cutlass dtype for reduction: '{cutlass_dtype.__name__}'. "
            f"Valid types are: {valid_types}"
        )

    return dtype_map[cutlass_dtype]


def _reduction_type_str_to_cutlass_dtype(dtype_str: str) -> type[Numeric]:
    """
    Convert ReductionType string literal to cutlass data type.

    :param dtype_str: ReductionType string literal (e.g., "u32", "f32")
    :type dtype_str: str
    :return: Cutlass data type (e.g., cutlass.Uint32, cutlass.Float32)
    :rtype: type[Numeric]
    :raises ValueError: If dtype_str is not supported for reduction operations

    Supported conversions:
        "b32" -> cutlass.Uint32 (bitwise operations use unsigned)
        "b64" -> cutlass.Uint64 (bitwise operations use unsigned)
        "u32" -> cutlass.Uint32
        "u64" -> cutlass.Uint64
        "s32" -> cutlass.Int32
        "s64" -> cutlass.Int64
        "f32" -> cutlass.Float32
        "f64" -> cutlass.Float64
        "f16" -> cutlass.Float16
        "bf16" -> cutlass.BFloat16
    """
    import cutlass

    # Mapping from ReductionType string literals to cutlass types
    str_to_dtype_map = {
        "b32": cutlass.Uint32,  # Bitwise operations use unsigned
        "b64": cutlass.Uint64,
        "u32": cutlass.Uint32,
        "u64": cutlass.Uint64,
        "s32": cutlass.Int32,
        "s64": cutlass.Int64,
        "f32": cutlass.Float32,
        "f64": cutlass.Float64,
        "f16": cutlass.Float16,
        "bf16": cutlass.BFloat16,
        # Vector types - map to base scalar type
        "f16x2": cutlass.Float16,
        "bf16x2": cutlass.BFloat16,
    }

    if dtype_str not in str_to_dtype_map:
        valid_options = sorted(str_to_dtype_map.keys())
        raise ValueError(
            f"Invalid ReductionType string: '{dtype_str}'. "
            f"Valid options are: {valid_options}"
        )

    return str_to_dtype_map[dtype_str]


# ============================================================================
# Function
# ============================================================================


@dsl_user_op
def lane_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the lane index of the current thread within the warp.
    """
    return Int32(nvvm.read_ptx_sreg_laneid(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def warp_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the warp index within a CTA.
    """
    warp_size = 32
    tid_x = Int32(nvvm.read_ptx_sreg_tid_x(T.i32(), loc=loc, ip=ip))
    tid_y = Int32(nvvm.read_ptx_sreg_tid_y(T.i32(), loc=loc, ip=ip))
    tid_z = Int32(nvvm.read_ptx_sreg_tid_z(T.i32(), loc=loc, ip=ip))
    ntid_x = Int32(nvvm.read_ptx_sreg_ntid_x(T.i32(), loc=loc, ip=ip))
    ntid_y = Int32(nvvm.read_ptx_sreg_ntid_y(T.i32(), loc=loc, ip=ip))
    tid = tid_x + tid_y * ntid_x + tid_z * ntid_x * ntid_y
    return tid // warp_size


@dsl_user_op
def physical_warp_id(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the warp identifier.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-warpid>`__.
    """
    return Int32(nvvm.read_ptx_sreg_warpid(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def thread_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the thread index within a CTA.
    """
    return (
        Int32(nvvm.read_ptx_sreg_tid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_tid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_tid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_dim(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of threads in each dimension of the CTA.
    """
    return (
        Int32(nvvm.read_ptx_sreg_ntid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ntid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ntid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the CTA identifier within a grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_ctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_ctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def grid_dim(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of CTAs in each dimension of the grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_nctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the cluster identifier within a grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_clusterid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_clusterid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_clusterid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_dim(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the number of clusters in each dimension of the grid.
    """
    return (
        Int32(nvvm.read_ptx_sreg_nclusterid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nclusterid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_nclusterid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_in_cluster_idx(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the CTA index within a cluster across all dimensions.
    """
    return (
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_ctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def block_in_cluster_dim(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Tuple[Int32, Int32, Int32]:
    """
    Returns the dimensions of the cluster.
    """
    return (
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_x(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_y(T.i32(), loc=loc, ip=ip)),
        Int32(nvvm.read_ptx_sreg_cluster_nctaid_z(T.i32(), loc=loc, ip=ip)),
    )


@dsl_user_op
def cluster_size(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the number of CTA within the cluster.
    """
    return Int32(nvvm.read_ptx_sreg_cluster_nctarank(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def block_idx_in_cluster(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the linearized identifier of the CTA within the cluster.
    """
    return Int32(nvvm.read_ptx_sreg_cluster_ctarank(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def dynamic_smem_size(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the launch dynamic smem size.
    """
    return Int32(
        llvm.inline_asm(
            Int32.mlir_type,
            [],
            "mov.u32 $0, %dynamic_smem_size;\n",
            "=r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def shuffle_sync_op(
    value: Union[Numeric, "TensorSSA"],  # type: ignore[name-defined]  # noqa: F821
    offset: Int,
    mask: Int = FULL_MASK,
    mask_and_clamp: Int = WARP_SIZE - 1,
    kind: nvvm.ShflKind = nvvm.ShflKind.idx,  # type: ignore[name-defined]
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, "TensorSSA"]:  # type: ignore[name-defined]  # noqa: F821
    """
    Shuffles a value within the threads of a warp.

    :param value:          The value to shuffle
    :type value:           Numeric or TensorSSA
    :param mask:           A mask describing the threads participating in this operation
    :type mask:            Int
    :param offset:         A source lane or a source lane offset depending on kind
    :type offset:          Int
    :param mask_and_clamp: An integer containing two packed values specifying a mask for logically
                           splitting warps into sub-segments and an upper bound for clamping the
                           source lane index.
    :type mask_and_clamp:  Int
    :param kind:           The kind of shuffle, can be idx, up, down, or bfly
    :type kind:            ShflKind
    :return:               The shuffled value
    :rtype:                Numeric
    """
    from ..tensor import TensorSSA

    if isinstance(value, TensorSSA):
        bit_width = value.dtype.width * size(value.shape)
        if bit_width == 32:
            i32_val = llvm.bitcast(
                T.i32(), value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip
            )
            i32_res = nvvm.shfl_sync(
                T.i32(),
                Int32(mask).ir_value(loc=loc, ip=ip),
                i32_val,
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
            result_vec = llvm.bitcast(value.type, i32_res, loc=loc, ip=ip)
            return TensorSSA(result_vec, value.shape, value.dtype)
        else:
            raise ValueError(f"shuffle_sync only supports 32 bit, but got {value.type}")

    if not isinstance(value, Numeric):
        value = as_numeric(value)

    if value.width > 64:  # type: ignore[attr-defined]
        raise ValueError("shuffle_sync only supports values up to 64 bits")

    orig_type = type(value)

    if value.width < 32:  # type: ignore[attr-defined]
        if value.dtype.is_float:
            value = value.to(Float32)
        else:
            if value.signed:  # type: ignore[attr-defined]
                value = value.to(Int32)
            else:
                value = value.to(Uint32)
        return orig_type(
            nvvm.shfl_sync(
                type(value).mlir_type,
                Int32(mask).ir_value(loc=loc, ip=ip),
                value.ir_value(loc=loc, ip=ip),
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
        )
    elif value.width == 32:  # type: ignore[attr-defined]
        return orig_type(
            nvvm.shfl_sync(
                type(value).mlir_type,
                Int32(mask).ir_value(loc=loc, ip=ip),
                value.ir_value(loc=loc, ip=ip),
                Int32(offset).ir_value(loc=loc, ip=ip),
                Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
                kind,
                loc=loc,
                ip=ip,
            )
        )
    else:
        if value.width != 64:  # type: ignore[attr-defined]
            raise ValueError(
                "shuffle_sync only supports 64 bits values when the bit width is larger than 32"
            )
        value = llvm.bitcast(
            T.i64(), value.to(ir.Value, loc=loc, ip=ip), loc=loc, ip=ip
        )
        # extract low 32 bits
        low_32_bits = arith.trunci(T.i32(), value, loc=loc, ip=ip)
        # extract high 32 bits
        high_32_bits = arith.shrui(
            value, Int64(32).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        high_32_bits = arith.trunci(T.i32(), high_32_bits, loc=loc, ip=ip)

        low_32_bits_shfl = nvvm.shfl_sync(
            T.i32(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            low_32_bits,
            Int32(offset).ir_value(loc=loc, ip=ip),
            Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
            kind,
            loc=loc,
            ip=ip,
        )
        high_32_bits_shfl = nvvm.shfl_sync(
            T.i32(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            high_32_bits,
            Int32(offset).ir_value(loc=loc, ip=ip),
            Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
            kind,
            loc=loc,
            ip=ip,
        )

        # combine low and high 32 bits
        low_64_bit = arith.extui(T.i64(), low_32_bits_shfl, loc=loc, ip=ip)
        high_64_bit = arith.extui(T.i64(), high_32_bits_shfl, loc=loc, ip=ip)
        shlf_res = arith.shli(
            high_64_bit, Int64(32).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        shlf_res = arith.ori(shlf_res, low_64_bit, loc=loc, ip=ip)
        shlf_res = llvm.bitcast(orig_type.mlir_type, shlf_res, loc=loc, ip=ip)
        return orig_type(shlf_res)


shuffle_sync = partial(shuffle_sync_op, kind=nvvm.ShflKind.idx)
shuffle_sync_up = partial(shuffle_sync_op, kind=nvvm.ShflKind.up)
shuffle_sync_down = partial(shuffle_sync_op, kind=nvvm.ShflKind.down)
shuffle_sync_bfly = partial(shuffle_sync_op, kind=nvvm.ShflKind.bfly)


@dsl_user_op
def warp_reduction(
    val: Numeric,
    op: Callable,
    *,
    threads_in_group: int = 32,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """warp reduction of a Numeric value(e.g.Float32) by shuffle_sync_bfly, accepts custom binary operator.
    The threads_in_group is the number of threads reduction group in a warp.
    E.g. 32 means the whole warp reduced in one group. 8 means the warp is divided into 4 thread groups, each group has 8 threads in reduction.


    :param val: register value
    :type val: cutlass.Numeric
    :param op: binary operator
    :type op: Callable
    :param threads_in_group: the number of threads reduction group in a warp
    :type threads_in_group: int
    :return: reduced value
    :rtype: cutlass.Numeric
    """
    offset = threads_in_group // 2

    while offset > 0:
        val = op(
            val,
            shuffle_sync_bfly(
                val, offset=offset, mask=-1, mask_and_clamp=31, loc=loc, ip=ip
            ),
        )
        offset = offset // 2
    return val


warp_reduction_max = partial(
    warp_reduction,
    op=lambda x, y: fmax(x, y) if isinstance(x, Float32) else cutlass_dsl.max(x, y),
)
warp_reduction_sum = partial(warp_reduction, op=lambda x, y: x + y)


@dsl_user_op
def barrier(
    *,
    barrier_id: Optional[Int] = None,
    number_of_threads: Optional[Int] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Creates a barrier, optionally named.
    """
    if barrier_id is not None:
        barrier_id = Int32(barrier_id).ir_value(loc=loc, ip=ip)

    if number_of_threads is not None:
        number_of_threads = Int32(number_of_threads).ir_value(loc=loc, ip=ip)

    if cutlass_dsl.target_version(exact_version="12.9"):
        if barrier_id is None:
            barrier_id = Int32(0).ir_value(loc=loc, ip=ip)
        has_count = number_of_threads is not None
        operands = [barrier_id, number_of_threads] if has_count else [barrier_id]
        llvm.inline_asm(
            None,
            operands,
            f"bar.sync {'$0, $1' if has_count else '$0'};",
            "r,r" if has_count else "r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
    else:
        # TODO: support barrier with reduction result
        nvvm.barrier(
            barrier_id=barrier_id,
            number_of_threads=number_of_threads,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def barrier_arrive(
    *,
    barrier_id: Optional[Int] = None,
    number_of_threads: Optional[Int] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    if barrier_id is not None:
        barrier_id = Int32(barrier_id).ir_value(loc=loc, ip=ip)
    else:
        barrier_id = Int32(0).ir_value(loc=loc, ip=ip)

    if number_of_threads is None:
        raise ValueError(
            "barrier_arrive needs pass number_of_threads to arrive the barrier",
        )
    number_of_threads = Int32(number_of_threads).ir_value(loc=loc, ip=ip)

    if cutlass_dsl.target_version(exact_version="12.9"):
        llvm.inline_asm(
            None,
            [barrier_id, number_of_threads],
            "bar.arrive $0, $1;",
            "r,r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
            loc=loc,
            ip=ip,
        )
    else:
        nvvm.barrier_arrive(
            barrier_id=barrier_id,
            number_of_threads=number_of_threads,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def sync_threads(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Synchronizes all threads within a CTA.
    """
    nvvm.barrier(loc=loc, ip=ip)


@dsl_user_op
def sync_warp(
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Performs a warp-wide sync with an optional mask.
    """
    nvvm.bar_warp_sync(Int32(mask).ir_value(loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_cta(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Fence operation with acquire-release semantics at CTA (block) scope.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_cta(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_cluster(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Fence operation with acquire-release semantics at cluster scope.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_cluster(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_gpu(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Fence operation with acquire-release semantics at GPU (device) scope.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_gpu(loc=loc, ip=ip)


@dsl_user_op
def fence_acq_rel_sys(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Fence operation with acquire-release semantics at system scope.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-membar>`__.
    """
    nvvm.fence_acq_rel_sys(loc=loc, ip=ip)


@dsl_user_op
def cp_async_commit_group(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Commits all prior initiated but uncommitted cp.async instructions.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-commit-group>`__.
    """
    nvvm.cp_async_commit_group(loc=loc, ip=ip)


@dsl_user_op
def cp_async_wait_group(
    n: Int, *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Waits till only a specified numbers of cp.async groups are pending.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-wait-group-cp-async-wait-all>`__.
    """
    nvvm.cp_async_wait_group(n, loc=loc, ip=ip)


@dsl_user_op
def cp_async_bulk_commit_group(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Commits all prior initiated but uncommitted cp.async.bulk instructions.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-commit-group>`__.
    """
    nvvm.cp_async_bulk_commit_group(loc=loc, ip=ip)


@dsl_user_op
def cp_async_bulk_wait_group(
    group: Int,
    *,
    read: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Waits till only a specified numbers of cp.async.bulk groups are pending.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-wait-group>`__.
    """
    nvvm.cp_async_bulk_wait_group(group, read=read, loc=loc, ip=ip)


@dsl_user_op
def cluster_wait(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    A cluster-wide wait operation.
    """
    nvvm.cluster_wait(loc=loc, ip=ip)


@dsl_user_op
def cluster_arrive(
    *,
    aligned: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    A cluster-wide arrive operation.
    """
    nvvm.cluster_arrive(aligned=aligned, loc=loc, ip=ip)


@dsl_user_op
def cluster_arrive_relaxed(
    *,
    aligned: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    A cluster-wide arrive operation with relaxed semantics.
    """
    nvvm.cluster_arrive_relaxed(aligned=aligned, loc=loc, ip=ip)


@dsl_user_op
def fence_proxy(
    kind: Literal[
        "alias", "async", "async.global", "async.shared", "tensormap", "generic"
    ],
    *,
    space: Optional[Literal["cta", "cluster"]] = None,
    use_intrinsic: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Fence operation to ensure memory consistency between proxies.

    :param kind: Proxy kind string literal:
        - "alias" : Alias proxy
        - "async" : Async proxy
        - "async.global" : Async global proxy
        - "async.shared" : Async shared proxy
        - "tensormap" : Tensormap proxy
        - "generic" : Generic proxy
    :type kind: Literal["alias", "async", "async.global", "async.shared", "tensormap", "generic"]
    :param space: Shared memory space scope string literal (optional):
        - "cta" : CTA (Cooperative Thread Array) scope
        - "cluster" : Cluster scope
    :type space: Optional[Literal["cta", "cluster"]]
    :param use_intrinsic: Whether to use intrinsic version
    """
    from cutlass._mlir.dialects.nvvm import (
        SharedSpace,
        ProxyKind,
    )

    # Enhance enum with str mapping
    SharedSpace = _enhance_enum_with_str_mapping(SharedSpace)
    ProxyKind = _enhance_enum_with_str_mapping(ProxyKind)

    kind = ProxyKind.from_str(kind)
    space = SharedSpace.from_str(space)

    nvvm.fence_proxy(
        kind=kind,
        space=space,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def vote_sync_op(
    pred: Boolean,
    kind: Literal["any", "all", "uni", "ballot"],
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Boolean]:
    """
    Performs a vote operation across the warp.
    """
    return_type = Int32 if kind == "ballot" else Boolean
    if cutlass_dsl.target_version(exact_version="12.9"):
        if kind == "ballot":
            return return_type(
                nvvm.vote_ballot_sync(
                    T.i32(),
                    Int32(mask).ir_value(loc=loc, ip=ip),
                    Boolean(pred).ir_value(loc=loc, ip=ip),
                    loc=loc,
                    ip=ip,
                )
            )
        else:
            return return_type(
                llvm.inline_asm(
                    T.bool(),
                    [
                        Boolean(pred).ir_value(loc=loc, ip=ip),
                        Int32(mask).ir_value(loc=loc, ip=ip),
                    ],
                    f"""{{\n\t
                    .reg .pred ps;\n\t
                    .reg .pred pd;\n\t
                    setp.ne.b32 ps, $1, 0;\n\t
                    vote.sync.{kind}.pred pd, ps, $2;\n\t
                    selp.b32 $0, 1, 0, pd;\n\t
                    }}""",
                    "=r,r,r",
                    has_side_effects=True,
                    is_align_stack=False,
                    asm_dialect=llvm.AsmDialect.AD_ATT,
                    loc=loc,
                    ip=ip,
                )
            )
    from cutlass._mlir.dialects.nvvm import VoteSyncKind

    VoteSyncKind = _enhance_enum_with_str_mapping(VoteSyncKind)

    return return_type(
        nvvm.vote_sync(
            T.i32() if kind == "ballot" else T.bool(),
            Int32(mask).ir_value(loc=loc, ip=ip),
            Boolean(pred).ir_value(loc=loc, ip=ip),
            VoteSyncKind.from_str(kind),
            loc=loc,
            ip=ip,
        )
    )


def vote_ballot_sync(
    pred: Boolean,
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    """Performs a ballot operation across the warp.

    It copies the predicate from each thread in mask into the corresponding bit position of
    destination register d, where the bit position corresponds to the thread's lane id.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A 32-bit integer where each bit represents a thread's predicate value
    :rtype: Int32

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return vote_sync_op(pred, "ballot", mask, loc=loc, ip=ip)


@dsl_user_op
def vote_any_sync(
    pred: Boolean,
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """True if source predicate is True for any non-exited threads in mask. Negate the source
    predicate to compute .none.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return vote_sync_op(pred, "any", mask, loc=loc, ip=ip)


@dsl_user_op
def vote_all_sync(
    pred: Boolean,
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """True if source predicate is True for all non-exited threads in mask. Negate the source
    predicate to compute .none.

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`__.
    """
    return vote_sync_op(pred, "all", mask, loc=loc, ip=ip)


@dsl_user_op
def vote_uni_sync(
    pred: Boolean,
    mask: Int = FULL_MASK,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """True f source predicate has the same value in all non-exited threads in mask. Negating
    the source predicate also computes .uni

    :param pred: The predicate value for the current thread
    :type pred: Boolean
    :param mask: A 32-bit integer mask specifying which threads participate, defaults to all
                threads (0xFFFFFFFF)
    :type mask: Int, optional
    :return: A boolean value indicating if the source predicate is True for all non-exited
            threads in mask
    :rtype: Boolean
    """
    return vote_sync_op(pred, "uni", mask, loc=loc, ip=ip)


@dsl_user_op
def popc(
    value: Numeric,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs a population count operation.
    """
    if not isinstance(value, Numeric):
        value = as_numeric(value)
    return type(value)(math.ctpop(value.ir_value(loc=loc, ip=ip), loc=loc, ip=ip))


@dsl_user_op
def fence_view_async_tmem_op(
    kind: Literal["load", "store"],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Perform a fence operation on the async TMEM load or store.

    .. note::
        This function is only available on sm_100a and above.
        The fence is required to synchronize the TMEM load/store
        and let the pipeline release or commit the buffer.

        Take a mma2acc pipeline as an example of LOAD fence, the ACC tensor is from TMEM.
        ```
        # Start to copy ACC from TMEM to register
        cute.copy(tmem_load, tACC, rACC)
        fence_view_async_tmem_load()
        # After fence, we can ensure the TMEM buffer is consumed totally.
        # Release the buffer to let the MMA know it can overwrite the buffer.
        mma2accum_pipeline.consumer_release(curr_consumer_state)
        ```
        Take a TS GEMM kernel as an example of STORE fence, the A tensor is from TMEM.
        ```
        # Start to copy A from register to TMEM
        cute.copy(tmem_store, rA, tA)
        fence_view_async_tmem_store()
        # After fence, we can ensure the TMEM buffer is ready.
        # Commit the buffer to let the MMA know it can start to load A.
        tmem_mma_pipeline.producer_commit(curr_producer_state)
        ```


    :param kind: The kind of fence operation to perform ("load", "store").
    :type kind: Literal["load", "store"]
    """
    from cutlass._mlir.dialects.nvvm import Tcgen05WaitKind

    # Enhance enum and convert string literal to enum type
    Tcgen05WaitKind = _enhance_enum_with_str_mapping(Tcgen05WaitKind)
    kind = Tcgen05WaitKind.from_str(kind)

    nvvm.tcgen05_wait(kind=kind, loc=loc, ip=ip)


fence_view_async_tmem_load = partial(fence_view_async_tmem_op, kind="load")
fence_view_async_tmem_store = partial(fence_view_async_tmem_op, kind="store")


@dsl_user_op
def fence_view_async_shared(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Perform a fence operation on the async shared memory load or store.

    .. note::
        This function is only available on sm_90 or higher.
        The fence is required to synchronize the shared memory load/store
        and let the pipeline release or commit the buffer.

        This function is usually used for async execution unit (like TMA, UMMA) after the load/store operations.
    """
    # Use the fence_proxy wrapper function with string literals
    fence_proxy(kind="async.shared", space="cta", loc=loc, ip=ip)


@dsl_user_op
def setmaxregister_increase(
    reg_count: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    from cutlass._mlir.dialects.nvvm import SetMaxRegisterAction

    return nvvm.setmaxregister(reg_count, SetMaxRegisterAction.increase, loc=loc, ip=ip)


@dsl_user_op
def setmaxregister_decrease(
    reg_count: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    from cutlass._mlir.dialects.nvvm import SetMaxRegisterAction

    return nvvm.setmaxregister(reg_count, SetMaxRegisterAction.decrease, loc=loc, ip=ip)


@dsl_user_op
@deprecated("API is deprecated, use setmaxregister_increase instead")
def warpgroup_reg_alloc(
    reg_count: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    from cutlass._mlir.dialects.nvvm import SetMaxRegisterAction

    nvvm.setmaxregister(reg_count, SetMaxRegisterAction.increase, loc=loc, ip=ip)


@dsl_user_op
@deprecated("API is deprecated, use setmaxregister_decrease instead")
def warpgroup_reg_dealloc(
    reg_count: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    from cutlass._mlir.dialects.nvvm import SetMaxRegisterAction

    nvvm.setmaxregister(reg_count, SetMaxRegisterAction.decrease, loc=loc, ip=ip)


@dsl_user_op
def calc_packed_f32x2_op(
    src_a: Tuple[Float32, Float32],
    src_b: Tuple[Float32, Float32],
    src_c: Optional[Tuple[Float32, Float32]],
    calc_func: Callable,
    *,
    rnd: Optional[Literal["rn", "rz", "rm", "rp", "none"]] = "rn",
    ftz: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32]:
    from cutlass._mlir.dialects.nvvm import FPRoundingMode

    # Enhance enum and convert string literal to enum type
    FPRoundingMode = _enhance_enum_with_str_mapping(FPRoundingMode)
    rnd = FPRoundingMode.from_str(rnd)

    vec_type = ir.VectorType.get([2], Float32.mlir_type, loc=loc)
    vec_src_a = vector.from_elements(
        vec_type,
        tuple(as_numeric(a).ir_value(loc=loc, ip=ip) for a in src_a),
        loc=loc,
        ip=ip,
    )
    vec_src_b = vector.from_elements(
        vec_type,
        tuple(as_numeric(b).ir_value(loc=loc, ip=ip) for b in src_b),
        loc=loc,
        ip=ip,
    )
    if src_c is not None:
        vec_src_c = vector.from_elements(
            vec_type,
            tuple(as_numeric(c).ir_value(loc=loc, ip=ip) for c in src_c),
            loc=loc,
            ip=ip,
        )
        vec_res = calc_func(
            vec_type, vec_src_a, vec_src_b, vec_src_c, rnd=rnd, ftz=ftz, loc=loc, ip=ip
        )
    else:
        vec_res = calc_func(
            vec_type, vec_src_a, vec_src_b, rnd=rnd, ftz=ftz, loc=loc, ip=ip
        )

    res0 = Float32(
        vector.extract(
            vec_res, dynamic_position=[], static_position=[0], loc=loc, ip=ip
        )
    )
    res1 = Float32(
        vector.extract(
            vec_res, dynamic_position=[], static_position=[1], loc=loc, ip=ip
        )
    )
    return res0, res1


fma_packed_f32x2 = partial(calc_packed_f32x2_op, calc_func=nvvm.fma_packed_f32x2)
mul_packed_f32x2 = partial(
    calc_packed_f32x2_op, src_c=None, calc_func=nvvm.mul_packed_f32x2
)
add_packed_f32x2 = partial(
    calc_packed_f32x2_op, src_c=None, calc_func=nvvm.add_packed_f32x2
)
sub_packed_f32x2 = partial(
    calc_packed_f32x2_op, src_c=None, calc_func=nvvm.sub_packed_f32x2
)


@dsl_user_op
def fmax(
    a: Union[float, Float32],
    b: Union[float, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    if cutlass_dsl.target_version(exact_version="12.9"):
        return Float32(
            nvvm.fmax(
                T.f32(),
                Float32(a).ir_value(loc=loc, ip=ip),
                Float32(b).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )
    else:
        return Float32(
            nvvm.fmax(
                Float32(a).ir_value(loc=loc, ip=ip),
                Float32(b).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


@dsl_user_op
def fmin(
    a: Union[float, Float32],
    b: Union[float, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    if cutlass_dsl.target_version(exact_version="12.9"):
        return Float32(
            nvvm.fmin(
                T.f32(),
                Float32(a).ir_value(loc=loc, ip=ip),
                Float32(b).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )
    else:
        return Float32(
            nvvm.fmin(
                Float32(a).ir_value(loc=loc, ip=ip),
                Float32(b).ir_value(loc=loc, ip=ip),
                loc=loc,
                ip=ip,
            )
        )


@dsl_user_op
def rcp_approx(
    a: Union[float, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    return Float32(
        nvvm.rcp_approx_ftz_f(Float32(a).ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    )


@dsl_user_op
@deprecated(
    "cute.arch.exp2 is deprecated, use cute.math.exp2 with `fastmath=True` instead"
)
def exp2(
    a: Union[float, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    return Float32(
        llvm.inline_asm(
            T.f32(),
            [Float32(a).ir_value(loc=loc, ip=ip)],
            "ex2.approx.ftz.f32 $0, $1;",
            "=f,f",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


# Convert 1 int8 value to 1 bfloat16 value
@dsl_user_op
def cvt_i8_bf16(
    src_i8: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    src_i16 = arith.extui(Int16.mlir_type, src_i8, loc=loc, ip=ip)
    val_i16 = llvm.inline_asm(
        Uint16.mlir_type,
        [
            src_i16,
        ],
        """{\n\t
            .reg .b16 r;\n\t
            .reg .b8 s;\n\t
            mov.b16 {s,_}, $1;\n\t
            cvt.rn.bf16.s8 r, s;\n\t
            mov.b16 $0, r;\n\t
        }""",
        "=h,h",
    )
    val_bf16 = llvm.bitcast(BFloat16.mlir_type, val_i16, loc=loc, ip=ip)
    return val_bf16


@dsl_user_op
def cvt_i8x2_to_bf16x2(
    src_vec2: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # pack 2 int8 into 1 int16 value
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec2, loc=loc, ip=ip)
    val_i32 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i16,
        ],
        """{\n\t
            .reg .b16 scale;\n\t
            mov.b16 scale, 0x8585;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, $1, scale;\n\t
        }""",
        "=r,h",
    )

    vec_bf16x2_type = ir.VectorType.get([2], BFloat16.mlir_type, loc=loc)
    vec_bf16x2 = llvm.bitcast(vec_bf16x2_type, val_i32, loc=loc, ip=ip)
    return vec_bf16x2


@dsl_user_op
def cvt_i8x4_to_bf16x4(
    src_vec4: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # pack 4 int8 into 1 int32 value
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec4, loc=loc, ip=ip)
    rst01 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            mov.b16 scale, 0x8585;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair0, scale;\n\t
        }""",
        "=r,r",
    )

    rst23 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            mov.b16 scale, 0x8585;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair1, scale;\n\t
        }""",
        "=r,r",
    )
    vec_type = ir.VectorType.get([2], Int32.mlir_type, loc=loc)
    rst_i32 = vector.from_elements(vec_type, [rst01, rst23], loc=loc, ip=ip)
    vec_bf16x4_type = ir.VectorType.get([4], BFloat16.mlir_type, loc=loc)
    vec_bf16x4 = llvm.bitcast(vec_bf16x4_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x4


# Convert vector of 2 float values to vector of 2 bfloat16 values with satfinite rounding
@dsl_user_op
def cvt_f32x2_bf16x2(
    src_vec2: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    src0 = vector.extractelement(
        src_vec2, position=arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    )
    src1 = vector.extractelement(
        src_vec2, position=arith.constant(Int32.mlir_type, 1, loc=loc, ip=ip)
    )
    rst = llvm.inline_asm(
        T.i32(),
        [
            Float32(src1).ir_value(loc=loc, ip=ip),
            Float32(src0).ir_value(loc=loc, ip=ip),
        ],
        "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;",
        "=r,f,f",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_type = ir.VectorType.get([2], BFloat16.mlir_type, loc=loc)
    vec_bf16x2 = llvm.bitcast(vec_type, rst, loc=loc, ip=ip)
    return vec_bf16x2


# Convert 1 float32 value to 1 bfloat16 value
@dsl_user_op
def cvt_f32_bf16(
    src_f32: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    bf16_val = llvm.inline_asm(
        BFloat16.mlir_type,
        [
            src_f32,
        ],
        "cvt.rn.bf16.f32 $0, $1;",
        "=h,f",
    )
    return bf16_val


# Convert vector of 4 int8 values to vector of 4 float32 values
@dsl_user_op
def cvt_i8x4_to_f32x4(
    src_vec4: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    zero = arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    mask4 = (
        arith.constant(Int32.mlir_type, 0x00000001, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00000100, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00010000, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x01000000, loc=loc, ip=ip),
    )
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec4, loc=loc, ip=ip)
    rst0 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[0],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst1 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[1],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst2 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[2],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst3 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            mask4[3],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res0 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst0,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res1 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst1,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res2 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst2,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res3 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst3,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_f32x4_type = ir.VectorType.get([4], Float32.mlir_type, loc=loc)
    vec_f32x4 = vector.from_elements(
        vec_f32x4_type, [res0, res1, res2, res3], loc=loc, ip=ip
    )
    return vec_f32x4


# Convert vector of 2 int8 values to vector of 2 float32 values
@dsl_user_op
def cvt_i8x2_to_f32x2(
    src_vec2: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    zero = arith.constant(Int32.mlir_type, 0, loc=loc, ip=ip)
    mask2 = (
        arith.constant(Int32.mlir_type, 0x00000001, loc=loc, ip=ip),
        arith.constant(Int32.mlir_type, 0x00000100, loc=loc, ip=ip),
    )
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i32_pad16b = arith.extui(Int32.mlir_type, src_i16, loc=loc, ip=ip)
    rst0 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32_pad16b,
            mask2[0],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    rst1 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32_pad16b,
            mask2[1],
            zero,
        ],
        "dp4a.s32.s32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res0 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst0,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    res1 = llvm.inline_asm(
        Float32.mlir_type,
        [
            rst1,
        ],
        "cvt.rn.f32.s32 $0, $1;",
        "=f,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    vec_f32x2_type = ir.VectorType.get([2], Float32.mlir_type, loc=loc)
    vec_f32x2 = vector.from_elements(vec_f32x2_type, [res0, res1], loc=loc, ip=ip)
    return vec_f32x2


# Permute bytes from register pair.
@dsl_user_op
def prmt(
    src: Int,
    src_reg_shifted: Int,
    prmt_indices: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    return llvm.inline_asm(
        T.i32(),
        [
            Int32(src).ir_value(loc=loc, ip=ip),
            Int32(src_reg_shifted).ir_value(loc=loc, ip=ip),
            Int32(prmt_indices).ir_value(loc=loc, ip=ip),
        ],
        "prmt.b32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )


# Convert 1 int4 value to 1 bfloat16 value
@dsl_user_op
def cvt_i4_bf16(
    src_i4: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # i4 -> i32 -> f32 -> bf
    src_i32 = arith.extsi(Int32.mlir_type, src_i4, loc=loc, ip=ip)
    src_f32 = arith.sitofp(Float32.mlir_type, src_i32, loc=loc, ip=ip)
    bf16_val = cvt_f32_bf16(src_f32, loc=loc, ip=ip)
    return bf16_val


# Convert multiple shuffled int4 values to bfloat16 values.
# The input elements are assumed to be already shuffled following a specific shuffle pattern.
# Specifically, for consecutive 8 int4 values with indices of (0, 1, 2, 3, 4, 5, 6, 7),
# they are shuffled to (0, 2, 1, 3, 4, 6, 5, 7).  For tailing elements less than 8, the
# shuffle pattern is (0, 2, 1, 3) for 4 elements. No shuffle is needed for less than 4 elements.
# Shuffle could help to produce converted bf16 values in the natural order of (0, 1, 2 ,3 ,4 ,5 ,6 ,7)
# without extra prmt instructions and thus better performance.
# The number of elements to be converted must be be even as specified by num_elts.
# Int4 values are packed into int32 values with upper bits filled with 0 if there are less than 4 int4 values.
# Results bfloat16 values are also packed into int32 values.
@dsl_user_op
def cvt_i4_to_bf16_with_shuffle_impl(
    src_i32: ir.Value,
    num_elts: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    if not cutlass_dsl.target_version(min_version="13.1"):
        raise cutlass_dsl.DSLCudaVerNotImplemented(
            feature="cvt_i4_to_bf16_with_shuffle_impl", required_version="13.1"
        )

    num_i32_elts = num_elts // 2
    mask_odd = arith.constant(Int32.mlir_type, 0xF0F0F0F0, loc=loc, ip=ip)
    mask_even = arith.constant(Int32.mlir_type, 0x0F0F0F0F, loc=loc, ip=ip)
    src_odd = arith.andi(src_i32, mask_odd, loc=loc, ip=ip)
    src_even = arith.andi(src_i32, mask_even, loc=loc, ip=ip)
    c4 = arith.constant(Int32.mlir_type, 4, loc=loc, ip=ip)
    src_even = arith.shli(src_even, c4, loc=loc, ip=ip)
    rst13 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_odd,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            mov.b16 scale, 0x8181;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair0, scale;\n\t
        }""",
        "=r,r",
    )
    rst57 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_odd,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            mov.b16 scale, 0x8181;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair1, scale;\n\t
        }""",
        "=r,r",
    )
    rst02 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_even,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b16 scale, 0x8181;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair0, scale;\n\t
        }""",
        "=r,r",
    )
    rst46 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_even,
        ],
        """{\n\t
            .reg .b16 pair<2>;\n\t
            .reg .b16 scale;\n\t
            mov.b16 scale, 0x8181;\n\t
            mov.b32 {pair0, pair1}, $1;\n\t
            cvt.rn.satfinite.scaled::n2::ue8m0.bf16x2.s2f6x2 $0, pair1, scale;\n\t
        }""",
        "=r,r",
    )
    vec_type = ir.VectorType.get([num_i32_elts], Int32.mlir_type, loc=loc)
    if num_elts == 2:
        prmt_index = arith.constant(Int32.mlir_type, 0x00005410, loc=loc, ip=ip)
        rst = llvm.inline_asm(
            Int32.mlir_type,
            [
                rst02,
                rst13,
                prmt_index,
            ],
            "prmt.b32 $0, $1, $2, $3;",
            "=r,r,r,r",
        )
        vec_rsts = vector.from_elements(vec_type, [rst], loc=loc, ip=ip)
    elif num_elts == 4:
        vec_rsts = vector.from_elements(vec_type, [rst02, rst13], loc=loc, ip=ip)
    else:
        vec_rsts = vector.from_elements(
            vec_type, [rst02, rst13, rst46, rst57], loc=loc, ip=ip
        )
    return vec_rsts


# Convert multiple int4 values to bfloat16 values.
# The number of elements to be converted must be be even as specified by num_elts.
# Int4 values are packed into int32 values with upper bits filled with 0 if there are less than 4 int4 values.
# Results bfloat16 values are also packed into int32 values.
@dsl_user_op
def cvt_i4_to_bf16_impl(
    src_i32: ir.Value,
    num_elts: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    c4 = arith.constant(Int32.mlir_type, 4, loc=loc, ip=ip)
    src_shr4 = arith.shrui(src_i32, c4, loc=loc, ip=ip)
    xor_mask0 = arith.constant(Int32.mlir_type, 0x08080808, loc=loc, ip=ip)
    and_mask = arith.constant(Int32.mlir_type, 0x0F0F0F0F, loc=loc, ip=ip)
    imm_lut = arith.constant(Int32.mlir_type, 0x0000006A, loc=loc, ip=ip)
    src_i32 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_i32,
            and_mask,
            xor_mask0,
            imm_lut,
        ],
        "lop3.b32 $0, $1, $2, $3, $4;",
        "=r,r,n,n,n",
    )
    xor_mask1 = arith.constant(Int32.mlir_type, 0x88080808, loc=loc, ip=ip)
    src_shr4 = llvm.inline_asm(
        Int32.mlir_type,
        [
            src_shr4,
            and_mask,
            xor_mask1,
            imm_lut,
        ],
        "lop3.b32 $0, $1, $2, $3, $4;",
        "=r,r,n,n,n",
    )
    prmt_indices = [
        arith.constant(Int32.mlir_type, imme, loc=loc, ip=ip)
        for imme in [
            0x0000F4F0,
            0x0000F5F1,
            0x0000F6F2,
            0x0000F7F3,
        ]
    ]
    num_i32_elts = num_elts // 2
    rsts = []
    for i in range(num_i32_elts):
        rst = llvm.inline_asm(
            Int32.mlir_type,
            [
                src_i32,
                src_shr4,
                prmt_indices[i],
            ],
            "prmt.b32 $0, $1, $2, $3;",
            "=r,r,r,r",
        )
        rsts.append(rst)
    mask_clear_top_bit = arith.constant(Int32.mlir_type, 0xFF7FFFFF, loc=loc, ip=ip)
    rsts[-1] = llvm.inline_asm(
        Int32.mlir_type,
        [
            rsts[-1],
            mask_clear_top_bit,
        ],
        "and.b32 $0, $1, $2;",
        "=r,r,r",
    )
    mul = arith.constant(Int32.mlir_type, 0x83808380, loc=loc, ip=ip)
    bias = arith.constant(Int32.mlir_type, 0xC308C308, loc=loc, ip=ip)
    for i in range(num_i32_elts):
        rsts[i] = llvm.inline_asm(
            Int32.mlir_type,
            [
                rsts[i],
                mul,
                bias,
            ],
            "fma.rn.bf16x2 $0, $1, $2, $3;",
            "=r,r,r,r",
        )
    # pack rsts into a vector
    vec_type = ir.VectorType.get([num_i32_elts], Int32.mlir_type, loc=loc)
    vec_rsts = vector.from_elements(vec_type, rsts, loc=loc, ip=ip)
    return vec_rsts


# Convert 2 int4 values to 2 bfloat16 values
@dsl_user_op
def cvt_i4x2_to_bf16x2(
    src_vec2: ir.Value,
    *,
    with_shuffle: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    cvt_func = cvt_i4_to_bf16_with_shuffle_impl if with_shuffle else cvt_i4_to_bf16_impl
    # pack 2 int4 into 1 int32 value and fill upper bits with 0
    src_i8 = llvm.bitcast(Int8.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i32 = arith.extui(Int32.mlir_type, src_i8, loc=loc, ip=ip)
    rst_i32 = cvt_func(src_i32, 2, loc=loc, ip=ip)
    vec_bf16x2_type = ir.VectorType.get([2], BFloat16.mlir_type, loc=loc)
    vec_bf16x2 = llvm.bitcast(vec_bf16x2_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x2


# Convert 4 int4 values to 4 bfloat16 values
@dsl_user_op
def cvt_i4x4_to_bf16x4(
    src_vec4: ir.Value,
    *,
    with_shuffle: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    cvt_func = cvt_i4_to_bf16_with_shuffle_impl if with_shuffle else cvt_i4_to_bf16_impl
    # pack 4 int4 into 1 int32 value and fill upper bits with 0
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec4, loc=loc, ip=ip)
    src_i32 = arith.extui(Int32.mlir_type, src_i16, loc=loc, ip=ip)
    rst_i32 = cvt_func(src_i32, 4, loc=loc, ip=ip)
    vec_bf16x4_type = ir.VectorType.get([4], BFloat16.mlir_type, loc=loc)
    vec_bf16x4 = llvm.bitcast(vec_bf16x4_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x4


# Convert 8 int4 values to 8 bfloat16 values
@dsl_user_op
def cvt_i4x8_to_bf16x8(
    src_vec8: ir.Value,
    *,
    with_shuffle: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    cvt_func = cvt_i4_to_bf16_with_shuffle_impl if with_shuffle else cvt_i4_to_bf16_impl
    # pack 8 int4 into 1 int32 value and fill upper bits with 0
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec8, loc=loc, ip=ip)
    rst_i32 = cvt_func(src_i32, 8, loc=loc, ip=ip)
    vec_bf16x8_type = ir.VectorType.get([8], BFloat16.mlir_type, loc=loc)
    vec_bf16x8 = llvm.bitcast(vec_bf16x8_type, rst_i32, loc=loc, ip=ip)
    return vec_bf16x8


# Sign extend 4 int4 unpacked in 8b containers
@dsl_user_op
def sext_unpacked_i4x4_to_i8x4(
    src_vec4: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    imm_u32 = arith.constant(Uint32.mlir_type, 0x78787878, loc=loc, ip=ip)
    src_u32 = llvm.bitcast(Uint32.mlir_type, src_vec4, loc=loc, ip=ip)
    dst_u32 = arith.addi(src_u32, imm_u32, loc=loc, ip=ip)
    dst_u32 = arith.xori(dst_u32, imm_u32, loc=loc, ip=ip)
    return llvm.bitcast(src_vec4.type, dst_u32, loc=loc, ip=ip)


@dsl_user_op
def log2_of_pow2_int(
    a: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    tmp = llvm.inline_asm(
        Int32.mlir_type,
        [a.ir_value(loc=loc, ip=ip)],
        "brev.b32 $0, $1;",
        "=r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
    )
    return Int32(
        llvm.inline_asm(
            Int32.mlir_type,
            [tmp],
            "bfind.shiftamt.u32 $0, $1;",
            "=r,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


@dsl_user_op
@deprecated(
    "cute.arch.exp is deprecated, use cute.math.exp with `fastmath=True` instead"
)
def exp(
    a: Union[float, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    LOG2_E = 1.4426950408889634
    return exp2(a * LOG2_E, loc=loc, ip=ip)


@dsl_user_op
@deprecated(
    "cute.arch.exp_packed_f32x2 is deprecated, use cute.arch.mul_packed_f32x2 and cute.math.exp2 with `fastmath=True` instead"
)
def exp_packed_f32x2(
    a: Tuple[Float32, Float32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Float32, Float32]:
    LOG2_E = Float32(1.4426950408889634)
    b = mul_packed_f32x2(a, (LOG2_E, LOG2_E), loc=loc, ip=ip)
    return exp2(b[0], loc=loc, ip=ip), exp2(b[1], loc=loc, ip=ip)


@dsl_user_op
def griddepcontrol_wait(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    This instruction is used to wait for the previous kernel's grid ending
    (all blocks of the previous kernel have finished and memflushed), i.e.,
    the instruction after this instruction will not be issued until the previous
    grid has finished.
    """
    llvm.inline_asm(
        res=None,
        operands_=[],
        asm_string="griddepcontrol.wait;",
        constraints="",
        has_side_effects=True,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def griddepcontrol_launch_dependents(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> None:
    """
    Issuing the launch_dependents instruction hints a dependent kernel to launch earlier.
    launch_dependents doesn't impact the functionality but the performance:
    Launching a dependent kernel too early can compete with current kernels,
    while launching too late can lead to a long latency.
    """
    llvm.inline_asm(
        res=None,
        operands_=[],
        asm_string="griddepcontrol.launch_dependents;",
        constraints="",
        has_side_effects=True,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )



@dsl_user_op
def _warp_redux_sync_nvvm(
    value: Numeric,
    kind: Literal[
        "fmax",
        "fmin",
        "max",
        "min",
        "umax",
        "umin",
        "add",
        "xor",
        "or",
        "and",
    ],
    mask_and_clamp: Int = FULL_MASK,
    abs: bool = False,
    nan: Optional[bool] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    from cutlass._mlir.dialects.nvvm import ReduxKind

    # Enhance enum and convert string literal to enum type
    ReduxKind = _enhance_enum_with_str_mapping(ReduxKind)
    kind = ReduxKind.from_str(kind)

    value_type = type(value)
    if value_type.is_integer and not value_type.signed:  # type: ignore[attr-defined]
        if kind == ReduxKind.MAX:
            kind = ReduxKind.UMAX
        elif kind == ReduxKind.MIN:
            kind = ReduxKind.UMIN

    value_ir = value.ir_value(loc=loc, ip=ip)

    return value_type(
        nvvm.redux_sync(
            res=value_ir.type,
            val=value_ir,
            kind=kind,
            mask_and_clamp=Int32(mask_and_clamp).ir_value(loc=loc, ip=ip),
            abs=abs,
            nan=nan,
            loc=loc,
            ip=ip,
        )
    )


@dsl_user_op
def _warp_redux_sync_ptx(
    value: Numeric,
    kind: Literal[
        "fmax",
        "fmin",
        "max",
        "min",
    ],
    mask_and_clamp: Int = FULL_MASK,
    abs: Optional[bool] = None,
    nan: Optional[bool] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    **ONLY** support f32 as nvvm compatability
    """
    value_type = type(value)
    value_ir = value.ir_value(loc=loc, ip=ip)
    mlir_type = value_type.mlir_type
    mask_ir = Int32(mask_and_clamp).ir_value(loc=loc, ip=ip)

    kind_ptx_str = kind
    if kind == "fmax":
        kind_ptx_str = "max"
    elif kind == "fmin":
        kind_ptx_str = "min"

    modifiers = []
    if nan is True:
        modifiers.append("NaN")
    if abs is True:
        modifiers.append("abs")

    modifier_str = "." + ".".join(modifiers) if modifiers else ""
    ptx_instr = f"redux.sync.{kind_ptx_str}{modifier_str}.f32 $0, $1, $2;"

    return value_type(
        llvm.inline_asm(
            mlir_type,
            [value_ir, mask_ir],
            f"{ptx_instr}",
            "=f,f,i",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


@dsl_user_op
def warp_redux_sync(
    value: Numeric,
    kind: Literal[
        "fmax",
        "fmin",
        "max",
        "min",
        "umax",
        "umin",
        "add",
        "xor",
        "or",
        "and",
    ],
    mask_and_clamp: Int = FULL_MASK,
    *,
    abs: Optional[bool] = None,
    nan: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Perform warp-level reduction operation across threads.

    Reduces values from participating threads in a warp according to the specified operation.
    All threads in the mask receive the same result.

    :param value: Input value to reduce
    :type value: Numeric
    :param kind: Reduction operation. Supported operations:

        - Integer types (Int32/Uint32): "add", "and", "max", "min", "umax", "umin", "or", "xor"
          "max"/"min" auto-promote to "umax"/"umin" for unsigned types (Uint32/Uint64).
        - Float types (Float32): "fmax", "fmin" (or "max"/"min" which auto-convert to "fmax"/"fmin")
    :type kind: Literal["add", "and", "max", "min", "umax", "umin", "or", "xor", "fmin", "fmax"]
    :param mask_and_clamp: Warp participation mask (default: FULL_MASK = 0xFFFFFFFF)
    :type mask_and_clamp: Int
    :param abs: Apply absolute value before reduction (float types only)
    :type abs: bool
    :param nan: Enable NaN propagation for fmax/fmin operations (float types only)
    :type nan: Optional[bool]
    :return: Reduced value (same for all participating threads)
    :rtype: Numeric
    """
    # Convert value to Numeric type if needed
    if not isinstance(value, Numeric):
        value = as_numeric(value)

    # Determine value type and choose appropriate implementation
    value_type = type(value)
    mlir_type = value_type.mlir_type

    # Use inline PTX for float types, NVVM for integer types
    if mlir_type == T.f32():
        return _warp_redux_sync_ptx(
            value, kind, mask_and_clamp, abs, nan, loc=loc, ip=ip
        )
    else:
        return _warp_redux_sync_nvvm(
            value, kind, mask_and_clamp, abs, nan, loc=loc, ip=ip
        )


def _normalize_ptr(
    addr: Union[ir.Value, Pointer],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Helper function to normalize pointer types to MLIR ir.Value.

    Supports:
    - ir.Value (LLVM pointer): returned as-is
    - cute.ptr (_Pointer instance): converted via to_llvm_ptr()

    :param addr: Address in various pointer formats
    :return: Normalized MLIR pointer value
    :rtype: ir.Value
    """
    # If it's already an MLIR ir.Value, return as-is
    if isinstance(addr, ir.Value):
        return addr

    # If it has to_llvm_ptr method (cute._Pointer instances)
    if hasattr(addr, "to_llvm_ptr") and callable(addr.to_llvm_ptr):
        return addr.to_llvm_ptr(loc=loc, ip=ip)

    # If none of the above, return as-is and let NVVM handle it
    # This allows for future pointer types without breaking existing code
    return addr


def _atomic(
    ptr: Union[ir.Value, Pointer],
    val: Union[Numeric, ir.Value],
    *,
    op: Literal[
        "add",
        "fadd",
        "max",
        "min",
        "umax",
        "umin",
        "and",
        "or",
        "xor",
        "exch",
    ],
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, ir.Value]:
    """
    General atomic operation function.

    Atomically adds `val` to the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location. Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param val: Value to add (scalar Numeric or vector ir.Value)
    :type val: Union[Numeric, ir.Value]
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :param op: Atomic operation ("add", "fadd", "max", "min", "umax", "umin", "and", "or", "xor", "exch").
        "max"/"min" auto-promote to "umax"/"umin" for unsigned types (Uint32/Uint64).
    :type op: Literal["add", "fadd", "max", "min", "umax", "umin", "and", "or", "xor", "exch"]
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Union[Numeric, ir.Value]
    """
    from cutlass._mlir.dialects.nvvm import AtomicOpKind, MemOrderKind, MemScopeKind

    # Enhance enums and convert string literals to enum types
    AtomicOpKind = _enhance_enum_with_str_mapping(AtomicOpKind)
    MemOrderKind = _enhance_enum_with_str_mapping(MemOrderKind)
    MemScopeKind = _enhance_enum_with_str_mapping(MemScopeKind)

    op = AtomicOpKind.from_str(op)
    sem = MemOrderKind.from_str(sem)
    scope = MemScopeKind.from_str(scope)

    # Normalize pointer type to MLIR ir.Value
    ptr = _normalize_ptr(ptr, loc=loc, ip=ip)

    # * Handle `val` Type - scalar Numeric or vector ir.Value
    is_vector = isinstance(val, ir.Value) and isinstance(val.type, ir.VectorType)

    if is_vector:
        # Vector type atomic - val is already an ir.Value
        val_ir = val
        val_type = val.type  # type: ignore[union-attr]
        # Check if it's a floating-point vector type
        elem_type = val.type.element_type  # type: ignore[union-attr]
        is_float_vector = (
            elem_type == Float16.mlir_type
            or elem_type == BFloat16.mlir_type
            or elem_type == Float32.mlir_type
        )

        # Vector atomics for f16/bf16/f32 only support ADD (FADD)
        if is_float_vector and op == AtomicOpKind.ADD:
            op = AtomicOpKind.FADD
    else:
        # Scalar type atomic - convert to Numeric
        if not isinstance(val, Numeric):
            val = as_numeric(val)
        val_type = type(val)
        val_ir = val.ir_value(loc=loc, ip=ip)

        # * Float
        # For .f32, .f64, .f16, .bf16, .f16x2, .bf16x2, only .add (FADD) is supported
        # For .u32 .u64, .s32, .s64, .add .and .or .xor .cas .exch .min .max are supported
        if val_type.is_float:
            if op == AtomicOpKind.ADD:
                op = AtomicOpKind.FADD
        elif val_type.is_integer and not val_type.signed:  # type: ignore[attr-defined]
            if op == AtomicOpKind.MAX:
                op = AtomicOpKind.UMAX
            elif op == AtomicOpKind.MIN:
                op = AtomicOpKind.UMIN

    # * NVVM call based on nvvm version
    if cutlass_dsl.target_version(exact_version="12.9"):
        # Old API: requires explicit result type as first positional argument
        # For vectors: pass val_type (ir.VectorType), for scalars: pass val_type.mlir_type
        result_type = val_type if is_vector else val_type.mlir_type
        result = nvvm.atomicrmw(
            result_type,
            op=op,
            ptr=ptr,
            a=val_ir,
            mem_order=sem,
            syncscope=scope,
            loc=loc,
            ip=ip,
        )
    else:
        # New API: infers result type automatically
        result = nvvm.atomicrmw(
            op=op,
            ptr=ptr,
            a=val_ir,
            mem_order=sem,
            syncscope=scope,
            loc=loc,
            ip=ip,
        )
    # Return raw result for vectors, wrapped for scalars
    return result if is_vector else val_type(result)


def atomic_add(
    ptr: Union[ir.Value, Pointer],
    val: Union[Numeric, ir.Value],
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, ir.Value]:
    """
    Performs an atomic addition operation.

    Atomically adds `val` to the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value to add (scalar Numeric or vector ir.Value)
    :type val: Union[Numeric, ir.Value]
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Union[Numeric, ir.Value]
    """
    return _atomic(ptr, val, op="add", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_and(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic bitwise AND operation.

    Atomically computes bitwise AND of `val` with the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value for AND operation
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="and", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_or(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic bitwise OR operation.

    Atomically computes bitwise OR of `val` with the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value for OR operation
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="or", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_xor(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic bitwise XOR operation.

    Atomically computes bitwise XOR of `val` with the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value for XOR operation
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="xor", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_max(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic maximum operation.

    Atomically computes maximum of `val` and the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value for MAX operation
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="max", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_min(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic minimum operation.

    Atomically computes minimum of `val` and the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value for MIN operation
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "cluster", "sys")
    :type scope: Optional[Literal["gpu", "cta", "cluster", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="min", sem=sem, scope=scope, loc=loc, ip=ip)


def atomic_exch(
    ptr: Union[ir.Value, Pointer],
    val: Numeric,
    *,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "cluster", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic exchange operation.

    Atomically exchanges `val` with the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location
    :param val: Value to exchange
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    return _atomic(ptr, val, op="exch", sem=sem, scope=scope, loc=loc, ip=ip)  # type: ignore[arg-type]


@dsl_user_op
def atomic_fmax(
    ptr: Union[ir.Value, Pointer],
    val: Float32,
    *,
    sign_bit: Optional[bool] = None,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "cluster", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    """
    Implementation of atomic fmax using integer bitcast.

    Works for +inf, -inf, and signbit-0 nans including canonical nan.
    Atomically maxes `val` to the value at memory location `ptr` and returns the old value.

    :param ptr: Pointer to memory location. Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param val: value to max
    :type val: Float32
    :param sign_bit: Indicates the sign bit of `val` if known beforehand, e.g. abs vals
    :type sign_bit: Optional[bool]
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "cluster", "sys")
    :type scope: Optional[Literal["gpu", "cta", "cluster", "sys"]]
    :return: Old value at memory location
    :rtype: Float32
    """
    intval = llvm.bitcast(T.i32(), val.ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    then_body = lambda: atomic_min(
        ptr,
        Uint32(intval),
        sem=sem,
        scope=scope,  # type: ignore[arg-type]
        loc=loc,
        ip=ip,
    )
    else_body = lambda: atomic_max(
        ptr,
        Int32(intval),
        sem=sem,
        scope=scope,  # type: ignore[arg-type]
        loc=loc,
        ip=ip,
    )

    if sign_bit is None:
        old_intval = cutlass_dsl.if_generate(
            Int32(intval) < 0,
            then_body,
            else_body,
            [],
            [Int32],
            loc=loc,
            ip=ip,
        )
    elif sign_bit:
        old_intval = then_body()
    else:
        old_intval = else_body()

    assert not isinstance(old_intval, list)
    return Float32(
        llvm.bitcast(T.f32(), old_intval.ir_value(loc=loc, ip=ip), loc=loc, ip=ip)
    )


@deprecated("atomic_max_float32 is deprecated, use atomic_fmax instead")
def atomic_max_float32(
    ptr: Union[ir.Value, Pointer],
    value: Float32,
    *,
    positive_only: bool = True,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Float32:
    """Deprecated: use atomic_fmax instead."""
    return atomic_fmax(
        ptr, value, sign_bit=False if positive_only else None, loc=loc, ip=ip
    )


@dsl_user_op
def atomic_cas(
    ptr: Union[ir.Value, Pointer],
    *,
    cmp: Numeric,
    val: Numeric,
    sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]] = None,
    scope: Optional[Literal["gpu", "cta", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Numeric:
    """
    Performs an atomic compare-and-swap (CAS) operation.

    Atomically compares the value at the memory location with `cmp`. If they are equal,
    stores `val` at the memory location and returns the old value.

    :param ptr: Pointer to memory location. Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param cmp: Value to compare against current memory value
    :type cmp: Numeric
    :param val: Value to store if comparison succeeds
    :type val: Numeric
    :param sem: Memory semantic ("relaxed", "release", "acquire", "acq_rel")
    :type sem: Optional[Literal["relaxed", "release", "acquire", "acq_rel"]]
    :param scope: Memory scope ("gpu", "cta", "sys")
    :type scope: Optional[Literal["gpu", "cta", "sys"]]
    :return: Old value at memory location
    :rtype: Numeric
    """
    from cutlass._mlir.dialects.nvvm import AtomicOpKind, MemOrderKind, MemScopeKind

    # Enhance enums and convert string literals to enum types
    MemOrderKind = _enhance_enum_with_str_mapping(MemOrderKind)
    MemScopeKind = _enhance_enum_with_str_mapping(MemScopeKind)

    sem = MemOrderKind.from_str(sem)
    scope = MemScopeKind.from_str(scope)

    # Normalize pointer type to MLIR ir.Value
    ptr = _normalize_ptr(ptr, loc=loc, ip=ip)

    # * Hanldle `val`, `cmp` Numeric Type
    if not isinstance(cmp, Numeric):
        cmp = as_numeric(cmp)
    if not isinstance(val, Numeric):
        val = as_numeric(val)
    cmp_type = type(cmp)
    cmp_ir = cmp.ir_value(loc=loc, ip=ip)
    val_ir = val.ir_value(loc=loc, ip=ip)

    # * NVVM call based on nvvm version
    if cutlass_dsl.target_version(exact_version="12.9"):
        result = nvvm.atomicrmw(
            cmp_type.mlir_type,
            op=AtomicOpKind.CAS,
            ptr=ptr,
            a=val_ir,
            b=cmp_ir,
            mem_order=sem,
            syncscope=scope,
            loc=loc,
            ip=ip,
        )
    else:
        result = nvvm.atomicrmw(
            op=AtomicOpKind.CAS,
            ptr=ptr,
            a=val_ir,
            b=cmp_ir,
            mem_order=sem,
            syncscope=scope,
            loc=loc,
            ip=ip,
        )
    return cmp_type(result)


@dsl_user_op
def store(
    ptr: Union[ir.Value, Pointer],
    val: Union[Numeric, ir.Value],
    *,
    level1_eviction_priority: Optional[
        Literal[
            "evict_normal",
            "evict_first",
            "evict_last",
            "evict_no_allocate",
            "evict_unchanged",
        ]
    ] = None,
    cop: Optional[Literal["wb", "cg", "cs", "wt"]] = None,
    ss: Optional[Literal["cta", "cluster"]] = None,
    sem: Optional[Literal["relaxed", "release"]] = None,
    scope: Optional[Literal["gpu", "cta", "cluster", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Store a value to a memory location.

    :param ptr: Pointer to store to. Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param val: Value to store (scalar Numeric or vector ir.Value)
    :type val: Union[Numeric, ir.Value]
    :param level1_eviction_priority: L1 cache eviction policy string literal:
        "evict_normal" : .level1::eviction_priority = .L1::evict_normal
        "evict_first" : .level1::eviction_priority = .L1::evict_first
        "evict_last" : .level1::eviction_priority = .L1::evict_last
        "evict_no_allocate" : .level1::eviction_priority = .L1::no_allocate
        "evict_unchanged" : .level1::eviction_priority = .L1::evict_unchanged
    :param cop: Store cache modifier string literal:
    :param ss: Shared memory space string literal:
        "cta" : .ss = .shared::cta
        "cluster" : .ss = .shared::cluster
        None : .ss = .global
    :param sem: Memory semantic string literal:
    :param scope: Memory scope string literal:

    """
    from cutlass._mlir.dialects.nvvm import (
        MemOrderKind,
        MemScopeKind,
        StoreCacheModifierKind,
        EvictKind,
        SharedSpace,
    )

    # Enhance enums and convert string literals to enum types
    MemOrderKind = _enhance_enum_with_str_mapping(MemOrderKind)
    MemScopeKind = _enhance_enum_with_str_mapping(MemScopeKind)
    StoreCacheModifierKind = _enhance_enum_with_str_mapping(StoreCacheModifierKind)
    EvictKind = _enhance_enum_with_str_mapping(EvictKind)
    SharedSpace = _enhance_enum_with_str_mapping(SharedSpace)

    sem = MemOrderKind.from_str(sem)
    scope = MemScopeKind.from_str(scope)
    cop = StoreCacheModifierKind.from_str(cop)
    level1_eviction_priority = EvictKind.from_str(level1_eviction_priority)
    ss = SharedSpace.from_str(ss)

    # Normalize pointer type to MLIR ir.Value
    ptr = _normalize_ptr(ptr, loc=loc, ip=ip)

    # Handle both scalar Numeric and vector ir.Value
    is_vector = isinstance(val, ir.Value) and isinstance(val.type, ir.VectorType)

    if is_vector:
        # Vector type store - val is already an ir.Value
        val_ir = val
    else:
        # Scalar type store - ensure val is a Numeric and convert to MLIR Value
        if not isinstance(val, Numeric):
            val = as_numeric(val)
        val_ir = val.ir_value(loc=loc, ip=ip)

    nvvm.store_ext(
        val_ir,
        ptr,
        order=sem,
        scope=scope,
        evict=level1_eviction_priority,
        cache_modifier=cop,
        shared_space=ss,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def load(
    ptr: Union[ir.Value, Pointer],
    dtype: Union[type[Numeric], ir.VectorType],
    *,
    sem: Optional[Literal["relaxed", "acquire"]] = None,
    scope: Optional[Literal["gpu", "cta", "cluster", "sys"]] = None,
    level1_eviction_priority: Optional[
        Literal[
            "evict_normal",
            "evict_first",
            "evict_last",
            "evict_no_allocate",
            "evict_unchanged",
        ]
    ] = None,
    cop: Optional[Literal["ca", "cg", "cs", "lu", "cv"]] = None,
    ss: Optional[Literal["cta", "cluster"]] = None,
    level_prefetch_size: Optional[Literal["size_64b", "size_128b", "size_256b"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, ir.Value]:
    """
    Load a value from a memory location.

    :param ptr: Pointer to load from. Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param dtype: Data type to load. Can be:
        - Scalar: Numeric type class (Int8, Uint8, Int32, Float32, etc.)
        - Vector: ir.VectorType for vectorized load (e.g., ir.VectorType.get([4], Int64.mlir_type))
    :type dtype: Union[type[Numeric], ir.VectorType]
    :param sem: Memory semantic string literal:
    :param scope: Memory scope string literal:
    :param level1_eviction_priority: L1 cache eviction policy string literal:
        "evict_normal" : .level1::eviction_priority = .L1::evict_normal
        "evict_first" : .level1::eviction_priority = .L1::evict_first
        "evict_last" : .level1::eviction_priority = .L1::evict_last
        "evict_no_allocate" : .level1::eviction_priority = .L1::no_allocate
        "evict_unchanged" : .level1::eviction_priority = .L1::evict_unchanged
    :param cop: Load cache modifier string literal:
    :param ss: Shared memory space string literal:
        "cta" : .ss = .shared::cta
        "cluster" : .ss = .shared::cluster
        None : .ss = .global
    :param level_prefetch_size: L2 cache prefetch size hint string literal:
        "size_64b" : .level::prefetch_size = .L2::64B
        "size_128b" : .level::prefetch_size = .L2::128B
        "size_256b" : .level::prefetch_size = .L2::256B
    :return: Loaded value (scalar Numeric or vector ir.Value)
    :rtype: Union[Numeric, ir.Value]
    """
    from cutlass._mlir.dialects.nvvm import (
        MemOrderKind,
        MemScopeKind,
        LoadCacheModifierKind,
        EvictKind,
        SharedSpace,
        L2PrefetchSize,
    )

    # Enhance enums and convert string literals to enum types
    MemOrderKind = _enhance_enum_with_str_mapping(MemOrderKind)
    MemScopeKind = _enhance_enum_with_str_mapping(MemScopeKind)
    LoadCacheModifierKind = _enhance_enum_with_str_mapping(LoadCacheModifierKind)
    EvictKind = _enhance_enum_with_str_mapping(EvictKind)
    SharedSpace = _enhance_enum_with_str_mapping(SharedSpace)
    L2PrefetchSize = _enhance_enum_with_str_mapping(L2PrefetchSize)

    sem = MemOrderKind.from_str(sem)
    scope = MemScopeKind.from_str(scope)
    cop = LoadCacheModifierKind.from_str(cop)
    level1_eviction_priority = EvictKind.from_str(level1_eviction_priority)
    ss = SharedSpace.from_str(ss)
    level_prefetch_size = L2PrefetchSize.from_str(level_prefetch_size)

    # Normalize pointer type to MLIR ir.Value
    ptr = _normalize_ptr(ptr, loc=loc, ip=ip)

    # Determine if dtype is a vector type or scalar type
    is_vector = isinstance(dtype, ir.VectorType) and isinstance(dtype, ir.VectorType)

    if is_vector:
        # Vector load: dtype is already an ir.VectorType
        mlir_type = dtype
        scalar_dtype = None  # We don't need to wrap the result
    else:
        # Scalar load: dtype is a Numeric type class
        mlir_type = dtype.mlir_type
        scalar_dtype = dtype

    result = nvvm.load_ext(
        res=mlir_type,
        addr=ptr,
        order=sem,
        scope=scope,
        evict=level1_eviction_priority,
        cache_modifier=cop,
        shared_space=ss,
        prefetch=level_prefetch_size,
        loc=loc,
        ip=ip,
    )

    # Return raw ir.Value for vectors, wrapped Numeric for scalars
    if is_vector:
        return result
    else:
        assert scalar_dtype is not None
        return scalar_dtype(result)


@dsl_user_op
def red(
    ptr: Union[ir.Value, Pointer],
    val: Union[Numeric, ir.Value],
    *,
    op: Literal["add", "min", "max", "umin", "umax", "and", "or", "xor"],
    dtype: Union[
        Literal[
            "b32",
            "b64",
            "u32",
            "u64",
            "s32",
            "s64",
            "f32",
            "f64",
            "f16",
            "f16x2",
            "bf16",
            "bf16x2",
        ],
        type[Numeric],
    ],
    sem: Optional[Literal["relaxed", "release"]] = None,
    scope: Optional[Literal["gpu", "cta", "cluster", "sys"]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Perform an atomic reduction operation on a memory location.

    Atomically computes: ptr = ptr x val, where x is the reduction operation.

    :param ptr: Pointer to memory location (global or shared). Supports:
        - ir.Value (LLVM pointer)
        - cute.ptr (_Pointer instance)
    :param val: Value to reduce with the memory location (scalar Numeric or vector ir.Value)
    :type val: Union[Numeric, ir.Value]
    :param op: Reduction operation string literal:
        "add"  : Addition
        "min"  : Minimum (signedness determined by dtype)
        "max"  : Maximum (signedness determined by dtype)
        "umin" : Unsigned minimum (alias for "min", forces dtype to unsigned)
        "umax" : Unsigned maximum (alias for "max", forces dtype to unsigned)
        "and"  : Bitwise AND
        "or"   : Bitwise OR
        "xor"  : Bitwise XOR
    :type op: Literal["add", "min", "max", "umin", "umax", "and", "or", "xor"]
    :param dtype: Data type. Supports string literals ("b32", "b64", "u32", "u64", "s32", "s64",
        "f32", "f64", "f16", "f16x2", "bf16", "bf16x2") or cutlass types (Uint32, Uint64,
        Int32, Int64, Float32, Float64, Float16, BFloat16)
    :type dtype: Union[str, type[Numeric]]
    :param sem: Memory ordering semantics string literal:
        "relaxed" : Relaxed memory ordering
        "release" : Release memory ordering
        None : No memory ordering specified
    :type sem: Optional[Literal["relaxed", "release"]]
    :param scope: Memory scope string literal:
        "gpu" : GPU scope
        "cta" : CTA/block scope
        "cluster" : Cluster scope
        "sys" : System scope
        None : No scope specified
    :type scope: Optional[Literal["gpu", "cta", "cluster", "sys"]]
    :return: None (operation modifies memory in-place)
    :rtype: None

    .. note::
        This operation modifies memory in-place and returns None.
        The old value is NOT returned (unlike atomic_add, atomic_max, etc.).
        For operations that need the old value, use the atomic_* functions instead.
    """
    from cutlass._mlir.dialects.nvvm import (
        ReductionOp,
        ReductionType,
        MemOrderKind,
        MemScopeKind,
    )

    # Enhance enums and convert string literals to enum types
    ReductionOp = _enhance_enum_with_str_mapping(ReductionOp)
    ReductionType = _enhance_enum_with_str_mapping(ReductionType)
    MemOrderKind = _enhance_enum_with_str_mapping(MemOrderKind)
    MemScopeKind = _enhance_enum_with_str_mapping(MemScopeKind)

    # Handle "umax"/"umin" aliases: map to "max"/"min" and ensure unsigned dtype
    _unsigned_op_aliases: dict[str, Literal["max", "min"]] = {
        "umax": "max",
        "umin": "min",
    }
    if op in _unsigned_op_aliases:
        op = _unsigned_op_aliases[op]
        # If dtype is a cutlass signed type, promote to its unsigned counterpart
        _signed_to_unsigned: dict[type[Numeric], type[Numeric]] = {
            Int32: Uint32,
            Int64: Uint64,
        }
        if not isinstance(dtype, str) and dtype in _signed_to_unsigned:
            dtype = _signed_to_unsigned[dtype]
        # If dtype is a signed string literal, promote to unsigned
        _signed_str_to_unsigned: dict[str, Literal["u32", "u64"]] = {
            "s32": "u32",
            "s64": "u64",
        }
        if isinstance(dtype, str) and dtype in _signed_str_to_unsigned:
            dtype = _signed_str_to_unsigned[dtype]

    # Process dtype parameter: normalize to string literal and numeric type
    dtype_str: str
    if isinstance(dtype, str):
        # dtype is already a string literal (e.g., "u32")
        dtype_str = dtype
        dtype_numeric = _reduction_type_str_to_cutlass_dtype(dtype_str)
    else:
        # dtype is a cutlass numeric type (e.g., cutlass.Uint32)
        dtype_numeric = dtype
        dtype_str = _cutlass_dtype_to_reduction_type_str(dtype_numeric)

    # Convert string literals to enum types
    op_enum = ReductionOp.from_str(op)
    dtype_enum = ReductionType.from_str(dtype_str)
    sem = MemOrderKind.from_str(sem)
    scope = MemScopeKind.from_str(scope)

    # Normalize pointer type to MLIR ir.Value
    ptr = _normalize_ptr(ptr, loc=loc, ip=ip)

    # Determine if val is a vector type or scalar type
    is_vector = isinstance(val, ir.Value) and isinstance(val.type, ir.VectorType)

    if is_vector:
        val_ir = val
    else:
        if not isinstance(val, Numeric):
            # Use dtype_numeric to convert the value to the specified type
            val = dtype_numeric(val)
        val_ir = val.ir_value(loc=loc, ip=ip)

    nvvm.red(
        op=op_enum,
        type_=dtype_enum,
        a=ptr,
        b=val_ir,
        mem_order=sem,
        mem_scope=scope,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def cvt_f4e2m1_f16(
    src: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # 0 padding for upper 4 bits
    zero = arith.constant(src.type, 0, loc=loc, ip=ip)
    vec2 = vector.from_elements(
        ir.VectorType.get([2], src.type, loc=loc), [src, zero], loc=loc, ip=ip
    )
    rst_vec2 = cvt_f4e2m1x2_to_f16x2(vec2, loc=loc, ip=ip)
    # only the 1st element is valid
    rst = vector.extract(
        rst_vec2, dynamic_position=[], static_position=[0], loc=loc, ip=ip
    )
    return rst


# Convert 2 float4e2m1 values to 2 float16 values
@dsl_user_op
def cvt_f4e2m1x2_to_f16x2(
    src_vec2: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # pack 2 float4e2m1 into 1 int8 value and fill upper bits with 0
    src_i8 = llvm.bitcast(Int8.mlir_type, src_vec2, loc=loc, ip=ip)
    src_i16 = arith.extui(Int16.mlir_type, src_i8, loc=loc, ip=ip)
    rst_i32 = llvm.inline_asm(
        Int32.mlir_type,
        [src_i16],
        """{\n\t
            .reg .b8 b;\n\t
            mov.b16 {b,_}, $1;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b;\n\t
        }""",
        "=r,h",
    )
    vec_f16x2_type = ir.VectorType.get([2], Float16.mlir_type, loc=loc)
    vec_f16x2 = llvm.bitcast(vec_f16x2_type, rst_i32, loc=loc, ip=ip)
    return vec_f16x2


# Convert 4 float4e2m1 values to 4 float16 values
@dsl_user_op
def cvt_f4e2m1x4_to_f16x4(
    src_vec4: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # pack 4 float4e2m1 into 1 int16 value
    src_i16 = llvm.bitcast(Int16.mlir_type, src_vec4, loc=loc, ip=ip)
    rst_i32x2 = llvm.inline_asm(
        llvm.StructType.get_literal([T.i32(), T.i32()]),
        [src_i16],
        """{\n\t
            .reg .b8 b0, b1;\n\t
            mov.b16 {b0, b1}, $2;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b0;\n\t
            cvt.rn.f16x2.e2m1x2 $1, b1;\n\t
        }""",
        "=r,=r,h",
    )
    res0 = llvm.extractvalue(T.i32(), rst_i32x2, [0])
    res1 = llvm.extractvalue(T.i32(), rst_i32x2, [1])
    vec_f32x2_type = ir.VectorType.get([2], Int32.mlir_type, loc=loc)
    vec_f32x2 = vector.from_elements(vec_f32x2_type, [res0, res1], loc=loc, ip=ip)
    vec_f16x4_type = ir.VectorType.get([4], Float16.mlir_type, loc=loc)
    vec_f16x4 = llvm.bitcast(vec_f16x4_type, vec_f32x2, loc=loc, ip=ip)
    return vec_f16x4


# Convert 8 float4e2m1 values to 8 float16 values
@dsl_user_op
def cvt_f4e2m1x8_to_f16x8(
    src_vec8: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    # pack 8 float4e2m1 into 1 int32 value and fill upper bits with 0
    src_i32 = llvm.bitcast(Int32.mlir_type, src_vec8, loc=loc, ip=ip)
    rst_i32x4 = llvm.inline_asm(
        llvm.StructType.get_literal([T.i32(), T.i32(), T.i32(), T.i32()]),
        [src_i32],
        """{\n\t
            .reg .b8 b0, b1, b2, b3;\n\t
            mov.b32 {b0, b1, b2, b3}, $4;\n\t
            cvt.rn.f16x2.e2m1x2 $0, b0;\n\t
            cvt.rn.f16x2.e2m1x2 $1, b1;\n\t
            cvt.rn.f16x2.e2m1x2 $2, b2;\n\t
            cvt.rn.f16x2.e2m1x2 $3, b3;\n\t
        }""",
        "=r,=r,=r,=r,r",
    )
    res0 = llvm.extractvalue(T.i32(), rst_i32x4, [0])
    res1 = llvm.extractvalue(T.i32(), rst_i32x4, [1])
    res2 = llvm.extractvalue(T.i32(), rst_i32x4, [2])
    res3 = llvm.extractvalue(T.i32(), rst_i32x4, [3])
    vec_f32x4_type = ir.VectorType.get([4], Int32.mlir_type, loc=loc)
    vec_f32x4 = vector.from_elements(
        vec_f32x4_type, [res0, res1, res2, res3], loc=loc, ip=ip
    )
    vec_f16x8_type = ir.VectorType.get([8], Float16.mlir_type, loc=loc)
    vec_f16x8 = llvm.bitcast(vec_f16x8_type, vec_f32x4, loc=loc, ip=ip)
    return vec_f16x8



@dsl_user_op
def smid(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the SM (Streaming Multiprocessor) ID of the current thread.

    The SM ID is a unique identifier for the streaming multiprocessor executing
    the current thread. Valid range is 0 to nsmid() - 1.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-smid

    :return: SM ID of the current thread
    :rtype: Int32
    """
    return Int32(nvvm.read_ptx_sreg_smid(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def nsmid(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns the number of SMs (Streaming Multiprocessors) on the device.

    This returns the total count of SMs available on the GPU, which defines
    the valid range for smid() as [0, nsmid() - 1].

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-nsmid

    :return: Total number of SMs on the device
    :rtype: Int32
    """
    return Int32(nvvm.read_ptx_sreg_nsmid(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def clock(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int32:
    """
    Returns a 32-bit clock counter value.

    Reads the per-SM clock counter, which can be used for timing and profiling.
    The counter wraps around on overflow. For extended range, use clock64().

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-clock

    :return: 32-bit clock counter value
    :rtype: Int32
    """
    return Int32(nvvm.read_ptx_sreg_clock(T.i32(), loc=loc, ip=ip))


@dsl_user_op
def clock64(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Int64:
    """
    Returns a 64-bit clock counter value.

    Reads the per-SM 64-bit clock counter, providing extended range compared
    to the 32-bit clock(). Useful for timing longer operations without overflow.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-clock64

    :return: 64-bit clock counter value
    :rtype: Int64
    """
    return Int64(nvvm.read_ptx_sreg_clock64(T.i64(), loc=loc, ip=ip))


@dsl_user_op
def match_sync(
    mask: Union[int, Int32, Uint32, Int64, Uint64],
    value: Union[int, Int32, Uint32, Int64, Uint64],
    kind: Literal["any", "all"] = "any",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32:
    """
    Finds threads in a warp with matching values using warp-synchronous matching.

    Performs a broadcast and compare of the operand value across threads specified
    by the mask. Returns a mask indicating which threads have matching values.

    - "any" mode: Returns mask of threads that have the same value as any other thread
    - "all" mode: Returns mask of threads where all active threads have the same value

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-match-sync

    :param mask: Mask of participating threads (typically 0xFFFFFFFF for full warp)
    :type mask: Union[int, Int32, Uint32]
    :param value: Value to match across threads
    :type value: Union[int, Int32, Uint32]
    :param kind: Match mode - "any" or "all"
    :type kind: Literal["any", "all"]
    :return: Mask of threads with matching values
    :rtype: Uint32
    """
    # Convert kind string to MatchSyncKind enum
    if kind == "any":
        kind_enum = nvvm.MatchSyncKind.any
    elif kind == "all":
        kind_enum = nvvm.MatchSyncKind.all
    else:
        raise ValueError(f"Invalid kind '{kind}', must be 'any' or 'all'")

    mask_ir = Int32(mask).ir_value(loc=loc, ip=ip)
    if isinstance(value, (Int64, Uint64)):
        value_ir = value.ir_value(loc=loc, ip=ip)
    else:
        value_ir = Int32(value).ir_value(loc=loc, ip=ip)

    if kind_enum == nvvm.MatchSyncKind.all:
        result = nvvm.match_sync(
            llvm.StructType.get_literal([T.i32(), Boolean.mlir_type]),
            mask_ir,
            value_ir,
            kind_enum,
            loc=loc,
            ip=ip,
        )
        return Uint32(llvm.extractvalue(T.i32(), result, [0], loc=loc, ip=ip))
    else:
        result = nvvm.match_sync(
            T.i32(),
            mask_ir,
            value_ir,
            kind_enum,
            loc=loc,
            ip=ip,
        )
        return Uint32(result)


@dsl_user_op
def clz(
    value: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32:
    """
    Counts the number of leading zero bits (count leading zeros).

    https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-clz

    Returns the number of consecutive zero bits starting from the most significant bit.
    For a 32-bit value, returns a value in range [0, 32]. For 64-bit, range is [0, 64].

    :param value: Input value (32-bit or 64-bit integer)
    :type value: Union[Int32, Uint32, Int64, Uint64]
    :return: Count of leading zero bits (same bit width as input)
    :rtype: Union[Int32, Int64]
    """

    # Determine instruction and result type based on input type
    if isinstance(value, (Int32, Uint32)):
        asm_str = "clz.b32 $0, $1;"
        constraints = "=r,r"
    elif isinstance(value, (Int64, Uint64)):  # Int64 or Uint64
        asm_str = "clz.b64 $0, $1;"
        constraints = "=r,l"
    else:
        raise TypeError(f"Invalid value type for clz: {type(value)}")

    value_ir = value.ir_value(loc=loc, ip=ip)

    result = llvm.inline_asm(
        T.i32(),
        [value_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def bfind(
    value: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32:
    """
    Finds the bit position of the most significant non-sign bit.

    For unsigned, finds the most significant 1 bit. For signed, finds the most
    significant bit that differs from the sign bit. Returns 0xFFFFFFFF if not found.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-bfind

    :param value: Input value (32-bit or 64-bit integer)
    :type value: Union[Int32, Uint32, Int64, Uint64]
    :return: Bit position (0-31 or 0-63) or 0xFFFFFFFF if not found
    :rtype: Union[Int32, Int64]
    """

    if not isinstance(value, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(f"Invalid value type for bfind: {type(value)}")

    value_ir = value.ir_value(loc=loc, ip=ip)

    if isinstance(value, Int32):
        asm_str = "bfind.s32 $0, $1;"
        constraints = "=r,r"
        result_type = T.i32()
        return_type = Uint32
    elif isinstance(value, Int64):
        asm_str = "bfind.s64 $0, $1;"
        constraints = "=r,l"
        result_type = T.i32()
        return_type = Uint32
    elif isinstance(value, Uint32):
        asm_str = "bfind.u32 $0, $1;"
        constraints = "=r,r"
        result_type = T.i32()
        return_type = Int32  # type: ignore[assignment]
    elif isinstance(value, Uint64):  # Uint64
        asm_str = "bfind.u64 $0, $1;"
        constraints = "=r,l"
        result_type = T.i32()
        return_type = Uint32

    result = llvm.inline_asm(
        result_type,
        [value_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return return_type(result)


@overload
def brev(
    value: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def brev(
    value: Uint32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@overload
def brev(
    value: Int64,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int64: ...


@overload
def brev(
    value: Uint64,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint64: ...


@dsl_user_op
def brev(
    value: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Reverses the bits in the value.

    Returns the input value with bits reversed. Bit 0 becomes bit 31 (or 63),
    bit 1 becomes bit 30 (or 62), etc.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-brev

    :param value: Input value (32-bit or 64-bit integer)
    :type value: Union[Int32, Uint32, Int64, Uint64]
    :return: Bit-reversed value (same type as input)
    :rtype: Union[Int32, Uint32, Int64, Uint64]

    """
    if not isinstance(value, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(f"Invalid value type for brev: {type(value)}")

    value_ir = value.ir_value(loc=loc, ip=ip)
    value_type = type(value)

    # Determine instruction based on input type
    if isinstance(value, (Int32, Uint32)):
        asm_str = "brev.b32 $0, $1;"
        constraints = "=r,r"
        result_type = T.i32()
    else:  # Int64 or Uint64
        asm_str = "brev.b64 $0, $1;"
        constraints = "=l,l"
        result_type = T.i64()

    result = llvm.inline_asm(
        result_type,
        [value_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@overload
def bfe(
    value: Int32,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def bfe(
    value: Uint32,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@overload
def bfe(
    value: Int64,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int64: ...


@overload
def bfe(
    value: Uint64,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint64: ...


@dsl_user_op
def bfe(
    value: Union[Int32, Uint32, Int64, Uint64],
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """

    Extract bit field from value and place the zero or sign-extended result.
    Source start gives the bit field starting bit position, and source length gives the
    bit field length in bits.

    The result and value must have the same type.

    Start and length are 32 bits, but are restricted to the 8-bit value range 0..255.

    The sign bit of the extracted field is defined as:

    Uint32 or Uint64 value: zero

    Int32 or Int64 value:
    Most significant bit (msb) of input value if the extracted field extends beyond the
    msb of the input value, otherwise if the bit field length is zero, the result is zero.

    The result is padded with the sign bit of the extracted field.
    If the start position is beyond the msb of the input, the result is filled with the
    replicated sign bit of the extracted field.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-bfe

    :param value: Source value to extract from
    :type value: Union[Int32, Uint32]
    :param start: Starting bit position (0-31)
    :type start: Union[int, Int32, Uint32]
    :param length: Number of bits to extract (0-32)
    :type length: Union[int, Int32, Uint32]
    :return: Extracted bit field (right-justified)
    :rtype: Union[Int32, Uint32]
    """

    if not isinstance(value, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(f"Invalid value type for bfe: {type(value)}")

    value_ir = value.ir_value(loc=loc, ip=ip)
    start_ir = Int32(start).ir_value(loc=loc, ip=ip)
    length_ir = Int32(length).ir_value(loc=loc, ip=ip)

    return_type: Type[Integer]
    if isinstance(value, (Int32, Uint32)):
        result_type = T.i32()
        constraints = "=r,r,r,r"
        if isinstance(value, Int32):
            asm_str = "bfe.s32 $0, $1, $2, $3;"
            return_type = Int32
        else:
            asm_str = "bfe.u32 $0, $1, $2, $3;"
            return_type = Uint32
    else:  # Int64 or Uint64
        result_type = T.i64()
        constraints = "=l,l,r,r"
        if isinstance(value, Int64):
            asm_str = "bfe.s64 $0, $1, $2, $3;"
            return_type = Int64
        else:
            asm_str = "bfe.u64 $0, $1, $2, $3;"
            return_type = Uint64

    result = llvm.inline_asm(
        result_type,
        [value_ir, start_ir, length_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return return_type(result)


@overload
def bfi(
    replacement: Int32,
    value: Int32,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def bfi(
    replacement: Uint32,
    value: Uint32,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@overload
def bfi(
    replacement: Int64,
    value: Int64,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int64: ...


@overload
def bfi(
    replacement: Uint64,
    value: Uint64,
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint64: ...


@dsl_user_op
def bfi(
    replacement: Union[Int32, Uint32, Int64, Uint64],
    value: Union[Int32, Uint32, Int64, Uint64],
    start: Union[int, Int32, Uint32],
    length: Union[int, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Inserts a bit field into a value (bit field insert).

    Replaces a contiguous sequence of bits in the value with bits from the
    replacement operand. Bits outside the specified field are preserved from
    the original value.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-bfi

    :param value: Original value to insert into
    :type value: Union[Int32, Uint32]
    :param replacement: Value containing bits to insert
    :type replacement: Union[Int32, Uint32]
    :param start: Starting bit position (0-31)
    :type start: Union[int, Int32, Uint32]
    :param length: Number of bits to insert (0-32)
    :type length: Union[int, Int32, Uint32]
    :return: Value with bit field replaced
    :rtype: Union[Int32, Uint32]

    **Architecture**: SM 20+

    **Example**::

        # Insert 0xF into bits [11:8] of 0x12345678
        result = bfi(Uint32(0x12345678), Uint32(0xF), start=8, length=4)
        # Returns 0x12345F78
    """
    if type(value) is not type(replacement):
        raise TypeError(
            "bfi requires value and replacement to have the same integer type"
        )

    if isinstance(value, (Int32, Uint32)):
        result_type = T.i32()
        asm_str = "bfi.b32 $0, $1, $2, $3, $4;"
        constraints = "=r,r,r,r,r"
    elif isinstance(value, (Int64, Uint64)):
        result_type = T.i64()
        asm_str = "bfi.b64 $0, $1, $2, $3, $4;"
        constraints = "=l,l,l,r,r"
    else:
        raise TypeError(f"Invalid value type for bfi: {type(value)}")

    replacement_ir = replacement.ir_value(loc=loc, ip=ip)
    value_ir = value.ir_value(loc=loc, ip=ip)
    start_ir = Int32(start).ir_value(loc=loc, ip=ip)
    length_ir = Int32(length).ir_value(loc=loc, ip=ip)

    result = llvm.inline_asm(
        result_type,
        [replacement_ir, value_ir, start_ir, length_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return type(value)(result)


@overload
def mul_hi(
    a: Int32,
    b: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def mul_hi(
    a: Uint32,
    b: Uint32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@overload
def mul_hi(
    a: Int64,
    b: Int64,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int64: ...


@overload
def mul_hi(
    a: Uint64,
    b: Uint64,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint64: ...


@dsl_user_op
def mul_hi(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Multiplies two values and returns the high-order bits of the result.

    Performs a full-width multiplication and returns the upper half of the result.
    For 32-bit inputs, returns bits [63:32]. For 64-bit inputs, returns bits [127:64].

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-mul-hi

    :param a: First multiplicand
    :type a: Union[Int32, Uint32, Int64, Uint64]
    :param b: Second multiplicand
    :type b: Union[Int32, Uint32, Int64, Uint64]
    :return: High-order bits of the product (same type as inputs)
    :rtype: Union[Int32, Uint32, Int64, Uint64]
    """

    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(
            "Invalid value types for mul_hi: a and b must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Determine instruction based on type
    if isinstance(a, Int32):
        asm_str = "mul.hi.s32 $0, $1, $2;"
        constraints = "=r,r,r"
        result_type = T.i32()
    elif isinstance(a, Uint32):
        asm_str = "mul.hi.u32 $0, $1, $2;"
        constraints = "=r,r,r"
        result_type = T.i32()
    elif isinstance(a, Int64):
        asm_str = "mul.hi.s64 $0, $1, $2;"
        constraints = "=l,l,l"
        result_type = T.i64()
    else:  # Uint64
        asm_str = "mul.hi.u64 $0, $1, $2;"
        constraints = "=l,l,l"
        result_type = T.i64()

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@overload
def mul_wide(
    a: Int16,
    b: Int16,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def mul_wide(
    a: Uint16,
    b: Uint16,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@overload
def mul_wide(
    a: Int32,
    b: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int64: ...


@overload
def mul_wide(
    a: Uint32,
    b: Uint32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint64: ...


@dsl_user_op
def mul_wide(
    a: Union[Int16, Uint16, Int32, Uint32],
    b: Union[Int16, Uint16, Int32, Uint32],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Multiplies two narrow values and returns a wide result.

    Performs multiplication with automatic widening of the result type.
    16-bit inputs produce 32-bit result. 32-bit inputs produce 64-bit result.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-mul

    :param a: First multiplicand (16-bit or 32-bit)
    :type a: Union[Int16, Uint16, Int32, Uint32]
    :param b: Second multiplicand (must match signedness of a)
    :type b: Union[Int16, Uint16, Int32, Uint32]
    :return: Wide product (32-bit for 16-bit inputs, 64-bit for 32-bit inputs)
    :rtype: Union[Int32, Uint32, Int64, Uint64]
    """
    if type(a) is not type(b) or not isinstance(a, (Int16, Uint16, Int32, Uint32)):
        raise TypeError(
            "Invalid value types for mul_wide: a and b must be the same type "
            f"(both Int16, Uint16, Int32, or Uint32), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)

    # Determine instruction and return type based on input type
    return_type: Type[Integer]
    if isinstance(a, Int16):
        asm_str = "mul.wide.s16 $0, $1, $2;"
        constraints = "=r,h,h"
        result_type = T.i32()
        return_type = Int32
    elif isinstance(a, Uint16):
        asm_str = "mul.wide.u16 $0, $1, $2;"
        constraints = "=r,h,h"
        result_type = T.i32()
        return_type = Uint32
    elif isinstance(a, Int32):
        asm_str = "mul.wide.s32 $0, $1, $2;"
        constraints = "=l,r,r"
        result_type = T.i64()
        return_type = Int64
    else:  # Uint32
        asm_str = "mul.wide.u32 $0, $1, $2;"
        constraints = "=l,r,r"
        result_type = T.i64()
        return_type = Uint64

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return return_type(result)


@overload
def mul24(
    a: Int32,
    b: Int32,
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def mul24(
    a: Uint32,
    b: Uint32,
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@dsl_user_op
def mul24(
    a: Union[Int32, Uint32],
    b: Union[Int32, Uint32],
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32]:
    """
    Fast 24-bit integer multiplication.

    Multiplies the low 24 bits of each operand. Bits [31:24] are ignored.
    Result can be either low 32 bits (hi=False) or high 32 bits (hi=True).

    t = a * b;
    d = t<47..16>    # for .hi variant (if hi is True)
    d = t<31..0>     # for .lo variant (if hi is False)

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-mul24

    :param a: First operand (only low 24 bits used)
    :type a: Union[Int32, Uint32]
    :param b: Second operand (only low 24 bits used)
    :type b: Union[Int32, Uint32]
    :param hi: If True, return high 32 bits; if False, return low 32 bits
    :type hi: bool
    :return: Product of low 24 bits
    :rtype: Union[Int32, Uint32]
    """

    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32)):
        raise TypeError(
            "Invalid value types for mul24: a and b must be the same type "
            f"(both Int32, Uint32), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Build instruction string
    lohi = "hi" if hi else "lo"
    if isinstance(a, Int32):
        asm_str = f"mul24.{lohi}.s32 $0, $1, $2;"
    else:  # Uint32
        asm_str = f"mul24.{lohi}.u32 $0, $1, $2;"

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir],
        asm_str,
        "=r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@overload
def mad24(
    a: Int32,
    b: Int32,
    c: Int32,
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def mad24(
    a: Uint32,
    b: Uint32,
    c: Uint32,
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@dsl_user_op
def mad24(
    a: Union[Int32, Uint32],
    b: Union[Int32, Uint32],
    c: Union[Int32, Uint32],
    hi: bool = False,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32]:
    """
    Fast 24-bit integer multiply-add.

    Computes (a * b) + c using only the low 24 bits of a and b.
    Result can be either low 32 bits (hi=False) or high 32 bits (hi=True).

    t = a * b
    d = t<47..16> + c   # for .hi variant (if hi is True)
    d = t<31..0> + c    # for .lo variant (if hi is False)

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-mad24

    :param a: First multiplicand (only low 24 bits used)
    :type a: Union[Int32, Uint32]
    :param b: Second multiplicand (only low 24 bits used)
    :type b: Union[Int32, Uint32]
    :param c: Addend (all 32 bits used)
    :type c: Union[Int32, Uint32]
    :param hi: If True, return high 32 bits; if False, return low 32 bits
    :type hi: bool
    :return: (a * b) + c
    :rtype: Union[Int32, Uint32]
    """
    if not isinstance(a, (Int32, Uint32)):
        raise TypeError("mad24 requires a to be an Int32 or Uint32")

    if type(a) is not type(b) or type(a) is not type(c):
        raise TypeError("mad24 requires a, b, and c to have the same integer type")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    c_ir = c.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Build instruction string
    lohi = "hi" if hi else "lo"
    if isinstance(a, Int32):
        asm_str = f"mad24.{lohi}.s32 $0, $1, $2, $3;"
    else:  # Uint32
        asm_str = f"mad24.{lohi}.u32 $0, $1, $2, $3;"

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir, c_ir],
        asm_str,
        "=r,r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def add_cc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Addition with carry-out (sets carry flag).

    Performs addition and sets the carry flag for use by subsequent addc() operations.
    This is the first operation in a multi-precision addition chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-add-cc

    :param a: First operand
    :type a: Union[Int32, Uint32]
    :param b: Second operand
    :type b: Union[Int32, Uint32]
    :return: Sum (a + b)
    :rtype: Union[Int32, Uint32]
    """
    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(
            "Invalid value types for add_cc: a and b must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    if isinstance(a, (Int32, Uint32)):
        result_type = T.i32()
        asm_str = "add.cc.u32 $0, $1, $2;"
        constraints = "=r,r,r"
    else:  # Int64 or Uint64
        result_type = T.i64()
        asm_str = "add.cc.u64 $0, $1, $2;"
        constraints = "=l,l,l"

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Modifies carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def addc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Addition with carry-in (reads carry flag).

    Performs addition including the carry flag set by add_cc() or previous addc().
    This continues a multi-precision addition chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-addc

    :param a: First operand
    :type a: Union[Int32, Uint32]
    :param b: Second operand
    :type b: Union[Int32, Uint32]
    :return: Sum (a + b + carry_flag)
    :rtype: Union[Int32, Uint32]
    """
    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(
            "Invalid value types for addc: a and b must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    if isinstance(a, (Int32, Uint32)):
        result_type = T.i32()
        asm_str = "addc.u32 $0, $1, $2;"
        constraints = "=r,r,r"
    else:  # Int64 or Uint64
        result_type = T.i64()
        asm_str = "addc.u64 $0, $1, $2;"
        constraints = "=l,l,l"

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Reads and may modify carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def sub_cc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Subtraction with carry-out (sets carry/borrow flag).

    Performs subtraction and sets the carry flag for use by subsequent subc() operations.
    This is the first operation in a multi-precision subtraction chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-sub-cc

    :param a: Value to subtract from
    :type a: Union[Int32, Uint32]
    :param b: Value to subtract
    :type b: Union[Int32, Uint32]
    :return: Difference (a - b)
    :rtype: Union[Int32, Uint32]
    """
    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(
            "Invalid value types for sub_cc: a and b must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    if isinstance(a, (Int32, Uint32)):
        result_type = T.i32()
        asm_str = "sub.cc.u32 $0, $1, $2;"
        constraints = "=r,r,r"
    else:  # Int64 or Uint64
        result_type = T.i64()
        asm_str = "sub.cc.u64 $0, $1, $2;"
        constraints = "=l,l,l"

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Modifies carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def subc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Subtraction with carry-in (reads carry/borrow flag).

    Performs subtraction including the carry flag set by sub_cc() or previous subc().
    This continues a multi-precision subtraction chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-subc

    :param a: Value to subtract from
    :type a: Union[Int32, Uint32]
    :param b: Value to subtract
    :type b: Union[Int32, Uint32]
    :return: Difference (a - b - carry_flag)
    :rtype: Union[Int32, Uint32]
    """
    if type(a) is not type(b) or not isinstance(a, (Int32, Uint32, Int64, Uint64)):
        raise TypeError(
            "Invalid value types for subc: a and b must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)} and {type(b)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    if isinstance(a, (Int32, Uint32)):
        result_type = T.i32()
        asm_str = "subc.u32 $0, $1, $2;"
        constraints = "=r,r,r"
    else:  # Int64 or Uint64
        result_type = T.i64()
        asm_str = "subc.u64 $0, $1, $2;"
        constraints = "=l,l,l"

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Reads and may modify carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def mad_cc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    c: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Multiply-add with carry-out (sets carry flag).

    Performs (a * b) + c and sets the carry flag for use by subsequent madc() operations.
    This starts a multi-precision multiply-add chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-mad-cc

    :param a: First multiplicand
    :type a: Union[Int32, Uint32]
    :param b: Second multiplicand
    :type b: Union[Int32, Uint32]
    :param c: Addend
    :type c: Union[Int32, Uint32]
    :return: Low 32 bits of (a * b) + c
    :rtype: Union[Int32, Uint32]
    """
    if (
        not isinstance(a, (Int32, Uint32, Int64, Uint64))
        or not isinstance(b, (Int32, Uint32, Int64, Uint64))
        or not isinstance(c, (Int32, Uint32, Int64, Uint64))
    ):
        raise TypeError(
            "mad_cc requires Int32/Uint32/Int64/Uint64 operands for a, b, and c"
        )

    if type(a) is not type(b) or type(a) is not type(c):
        raise TypeError("mad_cc requires a, b, and c to have the same integer type")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    c_ir = c.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Use .lo variant for low half of the product.
    if isinstance(a, Int32):
        asm_str = "mad.lo.cc.s32 $0, $1, $2, $3;"
        constraints = "=r,r,r,r"
        result_type = T.i32()
    elif isinstance(a, Uint32):
        asm_str = "mad.lo.cc.u32 $0, $1, $2, $3;"
        constraints = "=r,r,r,r"
        result_type = T.i32()
    elif isinstance(a, Int64):
        asm_str = "mad.lo.cc.s64 $0, $1, $2, $3;"
        constraints = "=l,l,l,l"
        result_type = T.i64()
    else:  # Uint64
        asm_str = "mad.lo.cc.u64 $0, $1, $2, $3;"
        constraints = "=l,l,l,l"
        result_type = T.i64()

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir, c_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Modifies carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def madc(
    a: Union[Int32, Uint32, Int64, Uint64],
    b: Union[Int32, Uint32, Int64, Uint64],
    c: Union[Int32, Uint32, Int64, Uint64],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32, Int64, Uint64]:
    """
    Multiply-add with carry-in (reads carry flag).

    Performs (a * b) + c + carry_flag. This continues a multi-precision multiply-add chain.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#extended-precision-arithmetic-instructions-madc
    :param a: First multiplicand
    :type a: Union[Int32, Uint32]
    :param b: Second multiplicand
    :type b: Union[Int32, Uint32]
    :param c: Addend
    :type c: Union[Int32, Uint32]
    :return: Low 32 bits of (a * b) + c + carry_flag
    :rtype: Union[Int32, Uint32]
    """
    if (
        type(a) is not type(b)
        or type(a) is not type(c)
        or not isinstance(a, (Int32, Uint32, Int64, Uint64))
    ):
        raise TypeError(
            "Invalid value types for madc: a, b, and c must be the same type "
            f"(both Int32, Uint32, Int64, or Uint64), got {type(a)}, {type(b)}, and {type(c)}"
        )

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    c_ir = c.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Use .lo variant for low half of the product.
    if isinstance(a, Int32):
        asm_str = "madc.lo.s32 $0, $1, $2, $3;"
        constraints = "=r,r,r,r"
        result_type = T.i32()
    elif isinstance(a, Uint32):
        asm_str = "madc.lo.u32 $0, $1, $2, $3;"
        constraints = "=r,r,r,r"
        result_type = T.i32()
    elif isinstance(a, Int64):
        asm_str = "madc.lo.s64 $0, $1, $2, $3;"
        constraints = "=l,l,l,l"
        result_type = T.i64()
    else:  # Uint64
        asm_str = "madc.lo.u64 $0, $1, $2, $3;"
        constraints = "=l,l,l,l"
        result_type = T.i64()

    result = llvm.inline_asm(
        result_type,
        [a_ir, b_ir, c_ir],
        asm_str,
        constraints,
        has_side_effects=True,  # Reads and may modify carry flag
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def activemask(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns the mask of currently active threads in the warp.

    Returns a 32-bit mask where bit N is set if thread N in the warp is active
    (not exited or diverged away). This reflects the current execution state.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-activemask

    :return: Mask of active threads in warp
    :rtype: Uint32
    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "activemask.b32 $0;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def lanemask_lt(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns mask of lanes with ID less than current lane.

    Returns a 32-bit mask where bit N is set if N < current_lane_id.
    For lane 0, returns 0x00000000. For lane 31, returns 0x7FFFFFFF.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-lanemask-lt

    :return: Mask of lanes with index < current lane
    :rtype: Uint32

    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "mov.u32 $0, %lanemask_lt;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def lanemask_le(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns mask of lanes with ID less than or equal to current lane.

    Returns a 32-bit mask where bit N is set if N <= current_lane_id.
    For lane 0, returns 0x00000001. For lane 31, returns 0xFFFFFFFF.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-lanemask-le

    :return: Mask of lanes with index <= current lane
    :rtype: Uint32

    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "mov.u32 $0, %lanemask_le;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def lanemask_eq(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns mask with only the current lane's bit set.

    Returns a 32-bit mask where only bit current_lane_id is set.
    Equivalent to (1 << lane_idx()).

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-lanemask-eq

    :return: Mask with only current lane bit set
    :rtype: Uint32

    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "mov.u32 $0, %lanemask_eq;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def lanemask_ge(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns mask of lanes with ID greater than or equal to current lane.

    Returns a 32-bit mask where bit N is set if N >= current_lane_id.
    For lane 0, returns 0xFFFFFFFF. For lane 31, returns 0x80000000.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-lanemask-ge

    :return: Mask of lanes with index >= current lane
    :rtype: Uint32

    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "mov.u32 $0, %lanemask_ge;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def lanemask_gt(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> Uint32:
    """
    Returns mask of lanes with ID greater than current lane.

    Returns a 32-bit mask where bit N is set if N > current_lane_id.
    For lane 0, returns 0xFFFFFFFE. For lane 31, returns 0x00000000.

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#special-registers-lanemask-gt

    :return: Mask of lanes with index > current lane
    :rtype: Uint32

    """
    result = llvm.inline_asm(
        T.i32(),
        [],
        "mov.u32 $0, %lanemask_gt;",
        "=r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Uint32(result)


@dsl_user_op
def add_sat_int(
    a: Int32,
    b: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    """
    Saturating signed 32-bit addition.

    Performs addition with saturation. If the result overflows, it saturates to
    INT32_MAX (0x7FFFFFFF). If it underflows, saturates to INT32_MIN (0x80000000).

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-add

    :param a: First operand
    :type a: Int32
    :param b: Second operand
    :type b: Int32
    :return: Saturated sum
    :rtype: Int32
    """
    if not isinstance(a, Int32) or not isinstance(b, Int32):
        raise TypeError("add_sat expects Int32 operands")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir],
        "add.sat.s32 $0, $1, $2;",
        "=r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Int32(result)


@dsl_user_op
def sub_sat_int(
    a: Int32,
    b: Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32:
    """
    Saturating signed 32-bit subtraction.

    Performs subtraction with saturation. If the result overflows, it saturates to
    INT32_MAX (0x7FFFFFFF). If it underflows, saturates to INT32_MIN (0x80000000).

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#integer-arithmetic-instructions-sub

    :param a: Minuend
    :type a: Int32
    :param b: Subtrahend
    :type b: Int32
    :return: Saturated difference
    :rtype: Int32
    """
    if not isinstance(a, Int32) or not isinstance(b, Int32):
        raise TypeError("sub_sat expects Int32 operands")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir],
        "sub.sat.s32 $0, $1, $2;",
        "=r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return Int32(result)


@overload
def lop3(
    a: Int32,
    b: Int32,
    c: Int32,
    lut: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def lop3(
    a: Uint32,
    b: Uint32,
    c: Uint32,
    lut: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@dsl_user_op
def lop3(
    a: Union[Int32, Uint32],
    b: Union[Int32, Uint32],
    c: Union[Int32, Uint32],
    lut: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32]:
    """
    Three-input logic operation with lookup table.

    Performs an arbitrary 3-input boolean function defined by an 8-bit lookup table.
    Each bit of the LUT corresponds to one combination of input bits (a, b, c).

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#logic-and-shift-instructions-lop3

    :param a: First input
    :type a: Union[Int32, Uint32]
    :param b: Second input
    :type b: Union[Int32, Uint32]
    :param c: Third input
    :type c: Union[Int32, Uint32]
    :param lut: 8-bit lookup table defining the boolean function
    :type lut: Union[int, Int32, Uint32]
    :return: Result of the 3-input logic operation
    :rtype: Union[Int32, Uint32]

    """
    if not isinstance(a, (Int32, Uint32)):
        raise TypeError("lop3 expects Int32/Uint32 operands")
    if type(a) is not type(b) or type(a) is not type(c):
        raise TypeError("lop3 requires a, b, and c to have the same integer type")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    c_ir = c.ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # LUT must be a constant
    if not isinstance(lut, int):
        raise TypeError("lut parameter must be an integer constant")

    lut = lut & 0xFF

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir, c_ir],
        f"lop3.b32 $0, $1, $2, $3, {lut};",
        "=r,r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@overload
def shf(
    a: Int32,
    b: Int32,
    shift: Union[int, Int32, Uint32],
    kind: Literal["l", "r", "clamp"] = "l",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Int32: ...


@overload
def shf(
    a: Uint32,
    b: Uint32,
    shift: Union[int, Int32, Uint32],
    kind: Literal["l", "r", "clamp"] = "l",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Uint32: ...


@dsl_user_op
def shf(
    a: Union[Int32, Uint32],
    b: Union[Int32, Uint32],
    shift: Union[int, Int32, Uint32],
    kind: Literal["l", "r", "clamp_left", "clamp_right"] = "l",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Int32, Uint32]:
    """
    Funnel shift operation.

    Concatenates two 32-bit values into a 64-bit value and shifts/extracts a 32-bit result.

    - "l" (left): Shift left, extract high 32 bits
    - "r" (right): Shift right, extract low 32 bits
    - "clamp_left": Clamp shift left amount to [0, 32]
    - "clamp_right": Clamp shift right amount to [0, 32]

    See https://docs.nvidia.com/cuda/parallel-thread-execution/#logic-and-shift-instructions-shf

    :param a: First 32-bit value (high part of concatenation)
    :type a: Union[Int32, Uint32]
    :param b: Second 32-bit value (low part of concatenation)
    :type b: Union[Int32, Uint32]
    :param shift: Shift amount
    :type shift: Union[int, Int32, Uint32]
    :param kind: Shift direction - "l" (left), "r" (right), or "clamp"
    :type kind: Literal["l", "r", "clamp"]
    :return: 32-bit result after funnel shift
    :rtype: Union[Int32, Uint32]
    """
    if not isinstance(a, (Int32, Uint32)) or not isinstance(b, (Int32, Uint32)):
        raise TypeError("shf expects Int32/Uint32 inputs for a and b")
    if type(a) is not type(b):
        raise TypeError("shf requires a and b to have the same integer type")

    a_ir = a.ir_value(loc=loc, ip=ip)
    b_ir = b.ir_value(loc=loc, ip=ip)
    shift_ir = Int32(shift).ir_value(loc=loc, ip=ip)
    value_type = type(a)

    # Build instruction string
    if kind == "l":
        direction = "l"
        wrap_mode = "wrap"
    elif kind == "r":
        direction = "r"
        wrap_mode = "wrap"
    elif kind == "clamp_left":
        direction = "l"
        wrap_mode = "clamp"
    elif kind == "clamp_right":
        direction = "r"
        wrap_mode = "clamp"
    else:
        raise ValueError(
            f"Invalid kind '{kind}', must be 'l', 'r', 'clamp_left', or 'clamp_right'"
        )

    asm_str = f"shf.{direction}.{wrap_mode}.b32 $0, $1, $2, $3;"

    result = llvm.inline_asm(
        T.i32(),
        [a_ir, b_ir, shift_ir],
        asm_str,
        "=r,r,r,r",
        has_side_effects=False,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )

    return value_type(result)


@dsl_user_op
def prefetch(
    addr: Any,
    *,
    cache_level: Optional[Literal["L1", "L2"]] = None,
    evict_priority: Optional[Any] = None,
    predicate: Optional[Any] = None,
    tensormap: Optional[bool] = None,
    uniform: Optional[bool] = None,
    in_param_space: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Prefetch data or TMA descriptor to cache.

    :param addr: LLVM pointer to prefetch.
    :param cache_level: Prefetch cache level string ("L1", "L2"). Mutually exclusive with tensormap.
    :param evict_priority: Cache eviction priority.
    :param predicate: Optional predicate for conditional execution.
    :param tensormap: If True, prefetch a tensormap descriptor.
    :param uniform: If True, use uniform prefetch.
    :param in_param_space: If True, address is in parameter space.
    """
    if cache_level is not None and tensormap is not None:
        raise ValueError("prefetch: cache_level and tensormap are mutually exclusive")

    # Default to L1 when neither cache_level nor tensormap is specified
    if cache_level is None and tensormap is None:
        cache_level = "L1"

    if cache_level is not None:
        PrefetchCacheLevel = _enhance_enum_with_str_mapping(nvvm.PrefetchCacheLevel)
        cache_level = PrefetchCacheLevel.from_str(cache_level)

    if cutlass_dsl.target_version(min_version="13.2"):
        nvvm.prefetch(
            addr,
            cache_level=cache_level,
            evict_priority=evict_priority,
            predicate=predicate,
            tensormap=tensormap,
            uniform=uniform,
            in_param_space=in_param_space,
            loc=loc,
            ip=ip,
        )
    else:
        # Fallback: inline PTX for builds without nvvm.prefetch op
        if tensormap:
            ptr_as_i64 = llvm.ptrtoint(T.i64(), addr, loc=loc, ip=ip)
            llvm.inline_asm(
                None,
                [ptr_as_i64],
                "prefetch.tensormap [$0];",
                "l",
                has_side_effects=True,
                is_align_stack=False,
                asm_dialect=llvm.AsmDialect.AD_ATT,
                loc=loc,
                ip=ip,
            )
        else:
            level = "L1"
            if cache_level is not None:
                level = str(cache_level)
            ptr_as_i64 = llvm.ptrtoint(T.i64(), addr, loc=loc, ip=ip)
            llvm.inline_asm(
                None,
                [ptr_as_i64],
                f"prefetch.global.{level} [$0];",
                "l",
                has_side_effects=True,
                is_align_stack=False,
                asm_dialect=llvm.AsmDialect.AD_ATT,
                loc=loc,
                ip=ip,
            )
