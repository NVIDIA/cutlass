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

from dataclasses import dataclass
from enum import Enum, auto
import ctypes
import ctypes.util
from typing import Optional, Tuple

from cutlass.base_dsl.common import CudaDriverDependencyError

try:
    from cuda.bindings import driver as _cuda_driver
except ImportError:
    _cuda_driver = None

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass.cutlass_dsl import dsl_user_op

import cutlass.cute as cute
from cutlass import const_expr
from cutlass.cute.core import AddressSpace as _CuteAddressSpace
from cutlass.cute.core import make_ptr as _cute_make_ptr


SM120_MXF4NVF4_TENSOR_MAP_BYTES = 128
SM120_MXF4NVF4_SCALE_K_GRANULARITY = 16


def _cuda_enum_value(enum_value) -> int:
    """Return the integer ABI value for a cuda.bindings Driver enum."""
    return int(enum_value.value if hasattr(enum_value, "value") else enum_value)


def _require_cuda_bindings_driver():
    if _cuda_driver is None:
        raise CudaDriverDependencyError(
            "SM120 MXF4/NVFP4 tensor-map helpers require cuda.bindings.driver"
        )
    return _cuda_driver


_CUDA_TENSORMAP_ENCODER = None


class _CUtensorMap(ctypes.Structure):
    _fields_ = [("opaque", ctypes.c_ulonglong * 16)]


def _make_aligned_cu_tensor_map():
    raw = (ctypes.c_ubyte * (ctypes.sizeof(_CUtensorMap) + 63))()
    base = ctypes.addressof(raw)
    aligned = (base + 63) & ~63
    tensor_map = ctypes.cast(aligned, ctypes.POINTER(_CUtensorMap)).contents
    return raw, tensor_map, aligned


def _cu_tensor_map_to_bytes(address: int) -> bytes:
    return bytes(ctypes.string_at(address, ctypes.sizeof(_CUtensorMap)))


def _get_cuda_tensormap_encoder():
    global _CUDA_TENSORMAP_ENCODER
    if _CUDA_TENSORMAP_ENCODER is not None:
        return _CUDA_TENSORMAP_ENCODER

    cuda_library = ctypes.util.find_library("cuda") or "libcuda.so.1"
    try:
        libcuda = ctypes.CDLL(cuda_library)
    except OSError as exc:
        raise CudaDriverDependencyError(
            "CUDA Driver API is required to build SM120 MXF4/NVFP4 tensor maps, "
            f"but {cuda_library!r} could not be loaded"
        ) from exc

    cu_init = libcuda.cuInit
    cu_init.argtypes = [ctypes.c_uint]
    cu_init.restype = ctypes.c_int
    result = cu_init(0)
    if result != 0:
        raise CudaDriverDependencyError(f"cuInit failed with status {result}")

    try:
        encode = libcuda.cuTensorMapEncodeTiled
    except AttributeError as exc:
        raise CudaDriverDependencyError(
            "CUDA Driver API cuTensorMapEncodeTiled is unavailable for SM120 "
            "MXF4/NVFP4 tensor maps"
        ) from exc
    encode.argtypes = [
        ctypes.POINTER(_CUtensorMap),
        ctypes.c_int,
        ctypes.c_uint,
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_ulonglong),
        ctypes.POINTER(ctypes.c_ulonglong),
        ctypes.POINTER(ctypes.c_uint),
        ctypes.POINTER(ctypes.c_uint),
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
    ]
    encode.restype = ctypes.c_int
    _CUDA_TENSORMAP_ENCODER = encode
    return encode


def sm120_mxf4nvf4_padded_scale_k_extent(logical_scale_k_extent: int) -> int:
    """Return the SM120 padded physical scale-K extent for the temporary descriptor path."""
    if logical_scale_k_extent <= 0:
        raise ValueError("logical_scale_k_extent must be positive")
    granularity = SM120_MXF4NVF4_SCALE_K_GRANULARITY
    return ((logical_scale_k_extent + granularity - 1) // granularity) * granularity


def validate_sm120_mxf4nvf4_tma_desc(
    *,
    base_ptr: int,
    desc_ptr: int | None = None,
    global_dim: tuple[int, int, int],
    global_strides_bytes: tuple[int, int],
    box_dim: tuple[int, int, int],
    element_strides: tuple[int, int, int] = (1, 1, 1),
    tx_count: int | None = None,
    align16: bool = True,
) -> None:
    """Validate the SM120 temporary Driver API descriptor path for NVFP4 A/B TMA."""
    if not align16:
        raise ValueError("SM120 MXF4NVF4 supports only 16U4_ALIGN16B descriptors")
    if base_ptr % 32 != 0:
        raise ValueError("SM120 MXF4NVF4 base pointer must be 32B aligned")
    if desc_ptr is not None and desc_ptr % 64 != 0:
        raise ValueError("SM120 MXF4NVF4 descriptor storage must be 64B aligned")
    if len(global_dim) != 3 or len(box_dim) != 3 or len(global_strides_bytes) != 2:
        raise ValueError("SM120 MXF4NVF4 tensor map expects rank 3")
    if element_strides != (1, 1, 1):
        raise ValueError("SM120 MXF4NVF4 element strides must be (1, 1, 1)")
    if any(dim <= 0 for dim in global_dim + box_dim):
        raise ValueError("SM120 MXF4NVF4 dimensions must be positive")
    if any(box > dim for box, dim in zip(box_dim, global_dim)):
        raise ValueError(
            "SM120 MXF4NVF4 box dimensions must not exceed global dimensions"
        )
    if global_dim[0] % 128 != 0:
        raise ValueError("SM120 MXF4NVF4 globalDim[0] must be a multiple of 128")
    if box_dim[0] != 128:
        raise ValueError("SM120 MXF4NVF4 boxDim[0] must equal 128")
    if any(stride <= 0 or stride % 32 != 0 for stride in global_strides_bytes):
        raise ValueError("SM120 MXF4NVF4 byte strides must be multiples of 32")
    min_major_stride = (global_dim[0] + 1) // 2
    if global_strides_bytes[0] < min_major_stride:
        raise ValueError("SM120 MXF4NVF4 major byte stride overlaps K dimension")
    min_l_stride = global_strides_bytes[0] * global_dim[1]
    if global_strides_bytes[1] < min_l_stride:
        raise ValueError("SM120 MXF4NVF4 L byte stride overlaps major dimension")
    if tx_count is not None:
        expected_tx = box_dim[0] * box_dim[1] * box_dim[2] // 2
        if tx_count != expected_tx:
            raise ValueError(f"SM120 MXF4NVF4 tx_count must be {expected_tx}")


def validate_sm120_mxf4nvf4_scale_tma_desc(
    *,
    base_ptr: int,
    desc_ptr: int | None = None,
    global_dim: tuple[int, int, int, int],
    global_strides_bytes: tuple[int, int, int],
    box_dim: tuple[int, int, int, int],
    element_strides: tuple[int, int, int, int] = (1, 1, 1, 1),
    tx_count: int | None = None,
) -> None:
    """Validate the SM120 temporary Driver API descriptor path for NVFP4 scale TMA."""
    if base_ptr % 16 != 0:
        raise ValueError("SM120 MXF4NVF4 scale base pointer must be 16B aligned")
    if desc_ptr is not None and desc_ptr % 64 != 0:
        raise ValueError("SM120 MXF4NVF4 descriptor storage must be 64B aligned")
    if len(global_dim) != 4 or len(box_dim) != 4 or len(global_strides_bytes) != 3:
        raise ValueError("SM120 MXF4NVF4 scale tensor map expects rank 4")
    if element_strides != (1, 1, 1, 1):
        raise ValueError("SM120 MXF4NVF4 scale element strides must be (1, 1, 1, 1)")
    if any(dim <= 0 for dim in global_dim + box_dim):
        raise ValueError("SM120 MXF4NVF4 scale dimensions must be positive")
    if any(box > dim for box, dim in zip(box_dim, global_dim)):
        raise ValueError(
            "SM120 MXF4NVF4 scale box dimensions must not exceed global dimensions"
        )
    if global_dim[1] % SM120_MXF4NVF4_SCALE_K_GRANULARITY != 0:
        raise ValueError("SM120 MXF4NVF4 scale-K extent must be padded to 16")
    if global_dim[1] < SM120_MXF4NVF4_SCALE_K_GRANULARITY:
        raise ValueError("SM120 MXF4NVF4 scale-K extent must be padded to 16")
    if box_dim[1] > global_dim[1]:
        raise ValueError("SM120 MXF4NVF4 logical scale-K box exceeds padded extent")
    if any(stride <= 0 or stride % 16 != 0 for stride in global_strides_bytes):
        raise ValueError("SM120 MXF4NVF4 scale byte strides must be multiples of 16")
    if global_strides_bytes[0] < global_dim[0]:
        raise ValueError("SM120 MXF4NVF4 scale K byte stride overlaps major dimension")
    if global_strides_bytes[1] < global_strides_bytes[0] * global_dim[1]:
        raise ValueError("SM120 MXF4NVF4 scale tile byte stride overlaps scale-K")
    if global_strides_bytes[2] < global_strides_bytes[1] * global_dim[2]:
        raise ValueError("SM120 MXF4NVF4 scale L byte stride overlaps tile dimension")
    if tx_count is not None:
        expected_tx = box_dim[0] * box_dim[1] * box_dim[2] * box_dim[3]
        if tx_count != expected_tx:
            raise ValueError(f"SM120 MXF4NVF4 scale tx_count must be {expected_tx}")


def _fp4_stride_elems_to_bytes(stride: int, name: str) -> int:
    if stride % 2 != 0:
        raise ValueError(f"{name} must be even for packed FP4")
    return stride // 2


def make_sm120_mxf4nvf4_tma_desc_bytes(
    global_address: int,
    *,
    major_extent: int = 128,
    k_extent: int = 128,
    l_extent: int = 1,
    box_major_extent: int | None = None,
    major_stride: int | None = None,
    l_stride: int | None = None,
    align16: bool = True,
    l2_promotion_128b: bool = True,
    swizzle_128b: bool = True,
) -> bytes:
    """Build experimental SM120 Driver API descriptor bytes for NVFP4 A/B TMA.

    This is an internal workaround until native CuTe descriptor lowering matches the
    required SM120 NVFP4 tensor-map encoding.
    """
    if any(extent <= 0 for extent in (major_extent, k_extent, l_extent)):
        raise ValueError("SM120 MXF4NVF4 extents must be positive")
    box_major_extent = major_extent if box_major_extent is None else box_major_extent
    if box_major_extent <= 0:
        raise ValueError("SM120 MXF4NVF4 box_major_extent must be positive")
    cuda_driver = _require_cuda_bindings_driver()
    major_stride_elems = k_extent if major_stride is None else major_stride
    l_stride_elems = (
        major_stride_elems * major_extent if l_stride is None else l_stride
    )
    global_dim = (k_extent, major_extent, l_extent)
    global_strides_bytes = (
        _fp4_stride_elems_to_bytes(major_stride_elems, "major_stride"),
        _fp4_stride_elems_to_bytes(l_stride_elems, "l_stride"),
    )
    box_dim = (128, box_major_extent, 1)
    element_strides = (1, 1, 1)
    raw, tensor_map, address = _make_aligned_cu_tensor_map()
    validate_sm120_mxf4nvf4_tma_desc(
        base_ptr=global_address,
        desc_ptr=address,
        global_dim=global_dim,
        global_strides_bytes=global_strides_bytes,
        box_dim=box_dim,
        element_strides=element_strides,
        tx_count=box_dim[0] * box_dim[1] * box_dim[2] // 2,
        align16=align16,
    )
    encode = _get_cuda_tensormap_encoder()
    result = encode(
        ctypes.pointer(tensor_map),
        _cuda_enum_value(
            cuda_driver.CUtensorMapDataType.CU_TENSOR_MAP_DATA_TYPE_16U4_ALIGN16B
        ),
        3,
        ctypes.c_void_p(global_address),
        (ctypes.c_ulonglong * 3)(*global_dim),
        (ctypes.c_ulonglong * 2)(*global_strides_bytes),
        (ctypes.c_uint * 3)(*box_dim),
        (ctypes.c_uint * 3)(*element_strides),
        _cuda_enum_value(
            cuda_driver.CUtensorMapInterleave.CU_TENSOR_MAP_INTERLEAVE_NONE
        ),
        _cuda_enum_value(cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_128B)
        if swizzle_128b
        else _cuda_enum_value(
            cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_NONE
        ),
        _cuda_enum_value(
            cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_L2_128B
        )
        if l2_promotion_128b
        else _cuda_enum_value(
            cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_NONE
        ),
        _cuda_enum_value(
            cuda_driver.CUtensorMapFloatOOBfill.CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE
        ),
    )
    if result != 0:
        raise RuntimeError(f"cuTensorMapEncodeTiled failed with status {result}")
    _ = raw
    return _cu_tensor_map_to_bytes(address)


def make_sm120_mxf4nvf4_scale_tma_desc_bytes(
    global_address: int,
    *,
    major_extent: int = 128,
    scale_k_extent: int = 16,
    logical_scale_k_extent: int = 8,
    tile_extent: int = 1,
    l_extent: int = 1,
    box_major_extent: int | None = None,
    major_stride: int | None = None,
    tile_stride: int | None = None,
    l_stride: int | None = None,
    l2_promotion_128b: bool = True,
) -> bytes:
    """Build experimental SM120 Driver API descriptor bytes for NVFP4 scale TMA.

    This is an internal workaround until native CuTe descriptor lowering matches the
    required SM120 NVFP4 tensor-map encoding.
    """
    if any(
        extent <= 0
        for extent in (
            major_extent,
            scale_k_extent,
            logical_scale_k_extent,
            tile_extent,
            l_extent,
        )
    ):
        raise ValueError("SM120 MXF4NVF4 scale extents must be positive")
    padded_scale_k_extent = sm120_mxf4nvf4_padded_scale_k_extent(
        logical_scale_k_extent
    )
    if scale_k_extent != padded_scale_k_extent:
        raise ValueError(
            "SM120 MXF4NVF4 scale_k_extent must be the padded physical extent"
        )
    box_major_extent = major_extent if box_major_extent is None else box_major_extent
    if box_major_extent <= 0:
        raise ValueError("SM120 MXF4NVF4 scale box_major_extent must be positive")
    cuda_driver = _require_cuda_bindings_driver()
    major_stride = major_extent if major_stride is None else major_stride
    tile_stride = major_stride * scale_k_extent if tile_stride is None else tile_stride
    l_stride = tile_stride * tile_extent if l_stride is None else l_stride
    global_dim = (major_extent, scale_k_extent, tile_extent, l_extent)
    global_strides_bytes = (major_stride, tile_stride, l_stride)
    box_dim = (box_major_extent, logical_scale_k_extent, 1, 1)
    element_strides = (1, 1, 1, 1)
    raw, tensor_map, address = _make_aligned_cu_tensor_map()
    validate_sm120_mxf4nvf4_scale_tma_desc(
        base_ptr=global_address,
        desc_ptr=address,
        global_dim=global_dim,
        global_strides_bytes=global_strides_bytes,
        box_dim=box_dim,
        element_strides=element_strides,
        tx_count=box_dim[0] * box_dim[1] * box_dim[2] * box_dim[3],
    )
    encode = _get_cuda_tensormap_encoder()
    result = encode(
        ctypes.pointer(tensor_map),
        _cuda_enum_value(cuda_driver.CUtensorMapDataType.CU_TENSOR_MAP_DATA_TYPE_UINT8),
        4,
        ctypes.c_void_p(global_address),
        (ctypes.c_ulonglong * 4)(*global_dim),
        (ctypes.c_ulonglong * 3)(*global_strides_bytes),
        (ctypes.c_uint * 4)(*box_dim),
        (ctypes.c_uint * 4)(*element_strides),
        _cuda_enum_value(
            cuda_driver.CUtensorMapInterleave.CU_TENSOR_MAP_INTERLEAVE_NONE
        ),
        _cuda_enum_value(cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_128B),
        _cuda_enum_value(
            cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_L2_128B
        )
        if l2_promotion_128b
        else _cuda_enum_value(
            cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_NONE
        ),
        _cuda_enum_value(
            cuda_driver.CUtensorMapFloatOOBfill.CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE
        ),
    )
    if result != 0:
        raise RuntimeError(f"cuTensorMapEncodeTiled failed with status {result}")
    _ = raw
    return _cu_tensor_map_to_bytes(address)


class TensorMapUpdateMode(Enum):
    """
    Enum class defining tensor map update modes.

    Modes:
    GMEM: Update tensormap in global memory
    SMEM: Load tensormap from global memory to shared memory,
    update it in shared memory, then store back to global memory
    """

    GMEM = auto()  # Update tensormap in global memory
    SMEM = auto()  # Update tensormap in shared memory


@dataclass(frozen=True)
class TensorMapManager:
    """
    Manages TensorMap operations including initialization and updates.
    Provides utilities to convert tensormap pointer to across different memory spaces.
    """

    tensormap_update_mode: TensorMapUpdateMode
    bytes_per_tensormap: int

    # convert given cute.Pointer or cutlass.Int64 to a cute.Pointer to tensormap.
    # address_space: the address space of the resulting tensormap pointer. It could be generic or gmem
    @dsl_user_op
    def get_tensormap_ptr(
        self,
        ptr: cute.Pointer,
        address_space: _cute_ir.AddressSpace = _cute_ir.AddressSpace.gmem,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        if address_space not in [
            _cute_ir.AddressSpace.gmem,
            _cute_ir.AddressSpace.generic,
        ]:
            raise ValueError(f"Invalid address space: {address_space} for tensormap")

        gmem_ptr_i64 = ptr.toint().ir_value(loc=loc, ip=ip)
        gmem_ptr_i64_align_ty = _cute_ir.ConstrainedIntType.get(
            self.bytes_per_tensormap, gmem_ptr_i64.type.width
        )
        gmem_ptr_i64_align = _cute_ir.assume(
            gmem_ptr_i64_align_ty, gmem_ptr_i64, loc=loc, ip=ip
        )
        gmem_ptr_ty = _cute_ir.PtrType.get(
            _cute_nvgpu_ir.TmaDescriptorTiledType.get(),
            address_space,
            self.bytes_per_tensormap,
        )
        return _cute_ir.inttoptr(gmem_ptr_ty, gmem_ptr_i64_align, loc=loc, ip=ip)

    # init tensormap pointed by dst_ptr with the one inside copy_atom.
    # dst_ptr should be pointing to a global memory location or a smem location
    # warp_id specifies which warp to perform the initialization
    @dsl_user_op
    @cute.jit
    def init_tensormap_from_atom(
        self,
        copy_atom: cute.CopyAtom,
        dst_ptr: cute.Pointer,
        warp_id: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        warp_idx = cute.arch.warp_idx(loc=loc, ip=ip)
        warp_idx = cute.arch.make_warp_uniform(warp_idx, loc=loc, ip=ip)
        if warp_idx == warp_id:
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.nvgpu.cpasync.copy_tensormap(copy_atom, dst_ptr, loc=loc, ip=ip)
        cute.arch.sync_warp(loc=loc, ip=ip)
        return

    # Perform a fence operation to ensure previous `init_tensormap_from_atom` calls have been completed
    @dsl_user_op
    def fence_tensormap_initialization(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if self.tensormap_update_mode == TensorMapUpdateMode.GMEM:
            cute.arch.fence_acq_rel_cta(loc=loc, ip=ip)
        return

    # Perform a fence operation to ensure previous `update_tensormap` calls have been completed
    @dsl_user_op
    def fence_tensormap_update(
        self,
        tensormap_ptr: cute.Pointer,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        cute.nvgpu.cpasync.fence_tma_desc_acquire(tensormap_ptr, loc=loc, ip=ip)
        return

    @dsl_user_op
    @cute.jit
    def update_tensormap(
        self,
        tensor_gmem: Tuple[cute.Tensor, ...],
        tma_copy_atom: Tuple[cute.CopyAtom, ...],
        tensormap_gmem_ptr: Tuple[cute.Pointer, ...],
        warp_id: int,
        tensormap_smem_ptr: Tuple[cute.Pointer, ...],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        warp_idx = cute.arch.make_warp_uniform(
            cute.arch.warp_idx(loc=loc, ip=ip), loc=loc, ip=ip
        )
        if const_expr(self.tensormap_update_mode == TensorMapUpdateMode.SMEM):
            # Hoist SMEM pointer integer values into warp-uniform registers before
            # entering predicated blocks. This avoids predicated R2UR lowering on sm_90a.
            uniform_smem_ptrs = tuple(
                _cute_make_ptr(
                    p.dtype,
                    cute.arch.make_warp_uniform(p.toint(), loc=loc, ip=ip),
                    mem_space=_CuteAddressSpace.smem,
                    assumed_align=p.alignment,  # type: ignore[attr-defined]
                )
                for p in tensormap_smem_ptr
            )
        else:
            uniform_smem_ptrs = tensormap_smem_ptr
        # updates before touching tensormap in global memory
        if warp_idx == warp_id:
            if const_expr(self.tensormap_update_mode == TensorMapUpdateMode.SMEM):
                for copy_atom, tensor, smem_ptr in zip(
                    tma_copy_atom, tensor_gmem, uniform_smem_ptrs
                ):
                    cute.nvgpu.cpasync.update_tma_descriptor(
                        copy_atom, tensor, smem_ptr, loc=loc, ip=ip
                    )
            # wait until it's safe to update tensormap in global memory
            with cute.arch.elect_one(loc=loc, ip=ip):
                cute.arch.cp_async_bulk_commit_group(loc=loc, ip=ip)
                cute.arch.cp_async_bulk_wait_group(0, read=True, loc=loc, ip=ip)
            cute.arch.sync_warp(loc=loc, ip=ip)
            # updates to tensormap in global memory
            if const_expr(self.tensormap_update_mode == TensorMapUpdateMode.SMEM):
                for gmem_ptr, smem_ptr in zip(tensormap_gmem_ptr, uniform_smem_ptrs):
                    cute.nvgpu.cpasync.cp_fence_tma_desc_release(
                        gmem_ptr, smem_ptr, loc=loc, ip=ip
                    )
            else:
                for copy_atom, tensor, gmem_ptr in zip(
                    tma_copy_atom, tensor_gmem, tensormap_gmem_ptr
                ):
                    cute.nvgpu.cpasync.update_tma_descriptor(
                        copy_atom, tensor, gmem_ptr, loc=loc, ip=ip
                    )
                cute.arch.sync_warp(loc=loc, ip=ip)
                cute.nvgpu.cpasync.fence_tma_desc_release(loc=loc, ip=ip)
