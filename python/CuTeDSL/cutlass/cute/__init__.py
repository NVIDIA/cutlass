# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

# Use the auto-generated enum AddressSpace
from cutlass._mlir.dialects.cute import AddressSpace, CacheEvictionPriority

# Explicitly import types that might be directly used by other modules.
# This is a fix for using Sphinx to generate documentation
# Because Sphinx processes each module in isolation, it won't be able to rely
# on re-exported symbols via wildcard imports (from .typing import *) in the
# same way that Python does at runtime.
from .typing import (
    Shape,
    Stride,
    IntTuple,
    Coord,
    Tile,
    XTuple,
    Tiler,
    Layout,
    ComposedLayout,
    Pointer,
    Tensor,
    SymInt,
)

# Import everything else
from .typing import *

from .core import (
    assume,
    is_static,
    size,
    static,
    get_leaves,
    has_underscore,
    slice_,
    make_ptr,
    make_layout,
    recast_layout,
    depth,
    rank,
    flatten,
    shape,
    size_in_bytes,
    make_identity_layout,
    make_ordered_layout,
    make_layout_like,
    make_composed_layout,
    make_layout_tv,
    make_swizzle,
    recast_ptr,
    get,
    select,
    front,
    is_major,
    leading_dim,
    coalesce,
    group_modes,
    cosize,
    dice,
    prepend,
    append,
    prepend_ones,
    append_ones,
    ceil_div,
    slice_and_offset,
    crd2idx,
    idx2crd,
    filter_zeros,
    filter,
    tile_to_shape,
    shape_div,
    composition,
    complement,
    right_inverse,
    left_inverse,
    max_common_layout,
    max_common_vector,
    logical_product,
    zipped_product,
    tiled_product,
    flat_product,
    raked_product,
    blocked_product,
    flat_divide,
    logical_divide,
    zipped_divide,
    tiled_divide,
    local_partition,
    local_tile,
    printf,
    get_nonswizzle_portion,
    get_swizzle_portion,
    # Wrapper classes
    Swizzle,
    E,
    # User defined struct
    struct,
    pretty_str,
    make_layout_image_mask,
    repeat,
    repeat_as_tuple,
    repeat_like,
    round_up,
    is_congruent,
    is_weakly_congruent,
    ScaledBasis,
    get_divisibility,
    Ratio,
    # FastDivmod operations
    FastDivmodDivisor,
    fast_divmod_create_divisor,
    basis_value,
    basis_get,
)

from .tuple import (
    transform_leaf,
    find_if,
    find,
    flatten_to_tuple,
    unflatten,
    product,
    product_like,
    product_each,
    elem_less,
    tuple_cat,
    transform_apply,
    filter_tuple,
)
from .tensor import (
    TensorSSA,
    ReductionOp,
    make_tensor,
    make_identity_tensor,
    make_fragment,
    make_fragment_like,
    make_rmem_tensor_like,
    make_rmem_tensor,
    recast_tensor,
    domain_offset,
    print_tensor,
    full,
    full_like,
    empty_like,
    ones_like,
    zeros_like,
    where,
    any_,
    all_,
)
from .atom import (
    Atom,
    MmaAtom,
    CopyAtom,
    TiledCopy,
    TiledMma,
    ThrMma,
    ThrCopy,
    make_atom,
    # tiled mma/tiled copy
    make_mma_atom,
    make_tiled_mma,
    make_copy_atom,
    make_tiled_copy_tv,
    make_tiled_copy,
    make_tiled_copy_S,
    make_tiled_copy_D,
    make_tiled_copy_A,
    make_tiled_copy_B,
    make_tiled_copy_C,
    make_tiled_copy_C_atom,
    make_cotiled_copy,
    copy_atom_call,
    mma_atom_call,
)
from .algorithm import gemm, copy, basic_copy, basic_copy_if, autovec_copy, prefetch

from . import typing as typing_module
from . import core
from . import arch
from . import export

from . import nvgpu
from . import testing
from . import runtime
from . import math


# Export all math ops without "math."
from .math import *

# Used as internal symbol
from .. import cutlass_dsl as _dsl

# Aliases
jit = _dsl.CuTeDSL.jit
kernel = _dsl.CuTeDSL.kernel
register_jit_arg_adapter = _dsl.JitArgAdapterRegistry.register_jit_arg_adapter
compile = _dsl.CompileCallable()
OptLevel = _dsl.OptLevel
PtxasOptions = _dsl.PtxasOptions
EnableAssertions = _dsl.EnableAssertions
GenerateLineInfo = _dsl.GenerateLineInfo
KeepCUBIN = _dsl.KeepCUBIN
KeepPTX = _dsl.KeepPTX
GPUArch = _dsl.GPUArch
EnableTVMFFI = _dsl.EnableTVMFFI

# attach the TVM FFI ABI interface postprocessor to the DSL
from . import _tvm_ffi_args_spec_converter

_tvm_ffi_args_spec_converter.attach_args_spec_converter(_dsl.CuTeDSL._get_dsl())

# Explicitly export all symbols for documentation generation
__all__ = [
    # ==================== cutlass._mlir.dialects.cute ====================
    "AddressSpace",
    "CacheEvictionPriority",
    # ==================== .typing ====================
    "Tensor",
    "Layout",
    "ComposedLayout",
    "SymInt",
    "is_integer",
    "is_int_tuple",
    # ==================== .core ====================
    *core.__all__,
    # ==================== .tuple ====================
    "transform_leaf",
    "find_if",
    "find",
    "flatten_to_tuple",
    "unflatten",
    "product",
    "product_like",
    "product_each",
    "elem_less",
    "tuple_cat",
    "transform_apply",
    "filter_tuple",
    # ==================== .tensor ====================
    "TensorSSA",
    "ReductionOp",
    "make_tensor",
    "make_identity_tensor",
    "make_fragment",
    "make_fragment_like",
    "make_rmem_tensor_like",
    "make_rmem_tensor",
    "recast_tensor",
    "domain_offset",
    "print_tensor",
    "full",
    "full_like",
    "empty_like",
    "ones_like",
    "zeros_like",
    "where",
    "any_",
    "all_",
    # ==================== .atom ====================
    "Atom",
    "MmaAtom",
    "CopyAtom",
    "TiledCopy",
    "TiledMma",
    "ThrMma",
    "ThrCopy",
    "make_atom",
    "make_mma_atom",
    "make_tiled_mma",
    "make_copy_atom",
    "make_tiled_copy_tv",
    "make_tiled_copy",
    "make_tiled_copy_S",
    "make_tiled_copy_D",
    "make_tiled_copy_A",
    "make_tiled_copy_B",
    "make_tiled_copy_C",
    "make_tiled_copy_C_atom",
    "make_cotiled_copy",
    "copy_atom_call",
    "mma_atom_call",
    # ==================== .algorithm ====================
    "gemm",
    "copy",
    "basic_copy",
    "basic_copy_if",
    "autovec_copy",
    "prefetch",
    # ==================== .extension ====================
    # ==================== .math ====================
    *math.__all__,
    # ==================== submodules ====================
    "arch",
    "export",
    "nvgpu",
    "testing",
    "runtime",
    # ==================== DSL (cutlass_dsl) ====================
    "jit",
    "kernel",
    "register_jit_arg_adapter",
    "compile",
]
