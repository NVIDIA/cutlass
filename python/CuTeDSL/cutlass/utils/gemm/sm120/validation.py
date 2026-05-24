# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Validation helpers for SM120 MXF4/NVFP4 GEMM support."""

from typing import Type

import cutlass
from cutlass.base_dsl.typing import Numeric

from .constants import (
    MXF4NVF4_CTA_SHAPE_MNK,
    MXF4NVF4_SCALE_VEC_SIZE,
)


def _check_positive(name: str, value: int) -> None:
    if value <= 0:
        raise ValueError(f"`{name}` must be positive, but got {value}")


def _check_default_tile(tile_mn: int, tile_k: int, sf_vec_size: int) -> None:
    _check_positive("tile_mn", tile_mn)
    _check_positive("tile_k", tile_k)
    _check_positive("sf_vec_size", sf_vec_size)
    if tile_k != MXF4NVF4_CTA_SHAPE_MNK[2]:
        raise ValueError("SM120 MXF4NVF4 helpers currently support tile_k=128")
    if sf_vec_size != MXF4NVF4_SCALE_VEC_SIZE:
        raise ValueError("SM120 MXF4NVF4 helpers currently support sf_vec_size=16")


def _check_tuple(name: str, value: tuple[int, ...], rank: int) -> None:
    if len(value) != rank:
        raise ValueError(f"`{name}` must have rank {rank}, but got {value}")


def _contiguous_alignment(dtype: Type[Numeric]) -> int:
    return 16 * 8 // dtype.width


def _mxf4nvf4_gemm_config_errors(
    *,
    m: int = 128,
    n: int = 128,
    k: int = 128,
    l_extent: int = 1,
    a_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    b_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: Type[Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    c_dtype: Type[Numeric] = cutlass.BFloat16,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    tile_shape_mnk: tuple[int, int, int] = MXF4NVF4_CTA_SHAPE_MNK,
    cluster_shape_mnk: tuple[int, int, int] = (1, 1, 1),
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
) -> list[str]:
    errors: list[str] = []
    for name, value in (("m", m), ("n", n), ("k", k), ("l_extent", l_extent)):
        if value <= 0:
            errors.append(f"`{name}` must be positive")

    try:
        _check_tuple("tile_shape_mnk", tile_shape_mnk, 3)
    except ValueError as exc:
        errors.append(str(exc))
    try:
        _check_tuple("cluster_shape_mnk", cluster_shape_mnk, 3)
    except ValueError as exc:
        errors.append(str(exc))

    if a_dtype != cutlass.Float4E2M1FN:
        errors.append("A dtype must be Float4E2M1FN")
    if b_dtype != cutlass.Float4E2M1FN:
        errors.append("B dtype must be Float4E2M1FN")
    if sf_dtype != cutlass.Float8E4M3FN:
        errors.append("scale dtype must be Float8E4M3FN")
    if sf_vec_size != MXF4NVF4_SCALE_VEC_SIZE:
        errors.append(f"sf_vec_size must be {MXF4NVF4_SCALE_VEC_SIZE}")
    if acc_dtype != cutlass.Float32:
        errors.append("accumulator dtype must be Float32")
    if c_dtype not in {cutlass.Float32, cutlass.Float16, cutlass.BFloat16}:
        errors.append("output dtype must be Float32, Float16, or BFloat16")

    if tile_shape_mnk != MXF4NVF4_CTA_SHAPE_MNK:
        errors.append(f"tile_shape_mnk must be {MXF4NVF4_CTA_SHAPE_MNK}")
    if cluster_shape_mnk != (1, 1, 1):
        errors.append("cluster_shape_mnk must be (1, 1, 1)")
    if a_major != "k":
        errors.append("A layout must be K-major")
    if b_major != "k":
        errors.append("B layout must be K-major")
    if c_major not in {"n", "m"}:
        errors.append("output layout must be N-major or M-major")

    if len(tile_shape_mnk) == 3:
        tile_m, tile_n, tile_k = tile_shape_mnk
        if m % tile_m != 0:
            errors.append("m must be divisible by tile_shape_mnk[0]")
        if n % tile_n != 0:
            errors.append("n must be divisible by tile_shape_mnk[1]")
        if k % tile_k != 0:
            errors.append("k must be divisible by tile_shape_mnk[2]")

    if a_dtype == cutlass.Float4E2M1FN and k % _contiguous_alignment(a_dtype):
        errors.append("K-major A requires k to be 16-byte aligned")
    if b_dtype == cutlass.Float4E2M1FN and k % _contiguous_alignment(b_dtype):
        errors.append("K-major B requires k to be 16-byte aligned")
    if c_dtype in {cutlass.Float32, cutlass.Float16, cutlass.BFloat16}:
        c_contiguous_extent = m if c_major == "m" else n
        if c_contiguous_extent % _contiguous_alignment(c_dtype):
            errors.append("output contiguous dimension must be 16-byte aligned")

    return errors


def mxf4nvf4_can_implement(
    *,
    m: int = 128,
    n: int = 128,
    k: int = 128,
    l_extent: int = 1,
    a_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    b_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: Type[Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    c_dtype: Type[Numeric] = cutlass.BFloat16,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    tile_shape_mnk: tuple[int, int, int] = MXF4NVF4_CTA_SHAPE_MNK,
    cluster_shape_mnk: tuple[int, int, int] = (1, 1, 1),
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
) -> bool:
    """Return whether the narrow SM120 MXF4/NVFP4 GEMM helper supports a config."""
    return not _mxf4nvf4_gemm_config_errors(
        m=m,
        n=n,
        k=k,
        l_extent=l_extent,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        tile_shape_mnk=tile_shape_mnk,
        cluster_shape_mnk=cluster_shape_mnk,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
    )


def validate_mxf4nvf4_gemm_config(
    *,
    m: int = 128,
    n: int = 128,
    k: int = 128,
    l_extent: int = 1,
    a_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    b_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    sf_dtype: Type[Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    c_dtype: Type[Numeric] = cutlass.BFloat16,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    tile_shape_mnk: tuple[int, int, int] = MXF4NVF4_CTA_SHAPE_MNK,
    cluster_shape_mnk: tuple[int, int, int] = (1, 1, 1),
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
) -> None:
    """Raise ``ValueError`` if a config is outside the narrow SM120 NVFP4 path."""
    errors = _mxf4nvf4_gemm_config_errors(
        m=m,
        n=n,
        k=k,
        l_extent=l_extent,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        tile_shape_mnk=tile_shape_mnk,
        cluster_shape_mnk=cluster_shape_mnk,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
    )
    if errors:
        raise ValueError("unsupported SM120 MXF4NVF4 GEMM config: " + "; ".join(errors))


__all__ = [
    "mxf4nvf4_can_implement",
    "validate_mxf4nvf4_gemm_config",
]
