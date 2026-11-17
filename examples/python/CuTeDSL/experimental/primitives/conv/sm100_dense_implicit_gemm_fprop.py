# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from dataclasses import dataclass
from functools import lru_cache
from typing import Literal, Optional, Tuple, Type

import cutlass
import cutlass.experimental.cuda as cuda
from cutlass.experimental import primitives as prims
from cutlass import Numeric, testing
from cutlass._mlir.dialects import llvm as llvm
import cutlass.cute as cute
import cutlass.utils as utils
from pathlib import Path

import sys

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[3])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)
from cutlass.memory import get_smem_capacity_in_bytes


"""
A 3D implicit-GEMM based fprop convolution example for the NVIDIA Blackwell SM100 architecture, written against the CuTe DSL primitives layer.
- Input tensor A is NxDxHxWxC, must be C major.
- Filter tensor B is KxTxRxSxC, must be C major.
- Output tensor C is NxZxPxQxK, must be K major.

This kernel supports the following features:
    - Every device instruction goes through ``prims.*``; the SMEM A/B/C buffers and all
      mbarriers are flat ``cutlass.Array(space=smem)`` allocations.
    - Utilizes im2col TMA for the input tensor A and an im2col TMA store for the output
      tensor C. The filter tensor B is loaded through a tiled TMA descriptor.
    - Utilizes Blackwell's tcgen05 MMA for matrix multiply-accumulate (MMA) operations
      (including 2cta mma instructions), fed by ``prims.Tcgen05SmemDesc.build`` and
      ``prims.Tcgen05InstrDesc.build``.
    - Warp-specialized with explicit roles: 1 TMA producer warp, 1 MMA consumer warp and
      4 epilogue warps, with mbarrier-based producer/consumer synchronization and a
      tcgen05.mma + tcgen05.commit handshake for the TMEM accumulator.
    - A static cluster shape, with output tiles assigned by a persistent scheduler.

This implicit-GEMM based convolution works by converting the convolution into a GEMM problem with the following mapping:
- GEMM M dimension maps to NxZxPxQ
- GEMM N dimension maps to K
- GEMM K dimension maps to TxRxSxC
During the load of the input tensor to SMEM, the TMA operation performs the im2col transformation on the input tensor A, which may involve replication of the input elements.
The filter tensor is loaded to SMEM without any transformation.
The output tensor C is stored to GMEM via the im2col TMA store.

The A load takes a 5D coord list (c, w, h, d, n) together with an im2col-offset list (s, r, t).
The C store takes a 5D coord list (k_off, q, p, z, n); the output spatial offsets live in the C descriptor's zero corners.

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/experimental/primitives/conv/sm100_dense_implicit_gemm_fprop.py \
      --ncdhw 1,1024,1,44,80 --ktrs 1024,3,3,3                        \
      --ab_dtype Float16 --c_dtype Float16                            \
      --mma_tiler_mn 256,256 --cluster_shape_mn 2,1         \
      --upper_pad_dhw 0,1,1 --lower_pad_dhw 2,1,1                     \
      --stride_dhw 1,1,1 --dilation_dhw 1,1,1

Constraints:
* Supported A/B data types: fp16, bf16, fp32 (TF32 MMA kind), fp8 (e4m3fn, e5m2);
  A and B must have the same data type
* Accumulator data type: fp32
* Supported C data types: fp32, fp16, bf16, fp8 (e4m3fn, e5m2)
* int8/uint8 A/B are not supported
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* Mma tiler N must be 32-256, step 32; each epilogue warp's N band must hold whole
  epilogue subtiles, so N must be a multiple of 64 with use_2cta_instrs=True and mma
  tiler M=128, and with an fp8 output at mma tiler M=64 and use_2cta_instrs=False
* Cluster shape M/N must be positive and a power of 2, and cluster M * cluster N *
  split_k must be <= 16
* Cluster shape M must be a multiple of 2 if use_2cta_instrs=True
* Each stride and dilation must be positive, and every output spatial extent must be
  positive
* M and N must each hold enough CTA tiles to form one cluster
* The im2col descriptor field widths bound the geometry: -lower_padding and
  upper_padding - (filter - 1) * dilation each land in [-16, 15], stride is at most 8,
  and (filter - 1) * dilation is at most 31
* The contiguous dimension of A/B/C tensors must be at least 16 bytes aligned, i.e. the
  number of elements is a multiple of 4, 8, and 16 for Float32, Float16/BFloat16, and
  Float8, respectively
"""


def check_conv_geometry(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    stride_dhw: Tuple[int, int, int],
    upper_pad_dhw: Tuple[int, int, int],
    lower_pad_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> None:
    """Reject a malformed convolution geometry.

    Only the lower bounds are checked here; check_im2col_descriptor_limits covers
    the upper bounds a tensor map can encode.

    :raises ValueError: If a shape or spatial tuple does not hold its expected
        number of values, or if an extent, stride, or dilation is not positive
    :raises testing.CantImplementError: If the geometry leaves no output extent
    """
    for name, values, count in (
        ("ncdhw", ncdhw, 5),
        ("ktrs", ktrs, 4),
        ("stride_dhw", stride_dhw, 3),
        ("upper_pad_dhw", upper_pad_dhw, 3),
        ("lower_pad_dhw", lower_pad_dhw, 3),
        ("dilation_dhw", dilation_dhw, 3),
    ):
        if len(values) != count:
            raise ValueError(
                f"{name} must contain exactly {count} values, got {values}"
            )
    for name, values in (
        ("ncdhw", ncdhw),
        ("ktrs", ktrs),
        ("stride_dhw", stride_dhw),
        ("dilation_dhw", dilation_dhw),
    ):
        if any(v <= 0 for v in values):
            raise ValueError(f"{name} must contain only positive values, got {values}")
    zpq = compute_zpq(
        ncdhw[2:], ktrs[1:], stride_dhw, upper_pad_dhw, lower_pad_dhw, dilation_dhw
    )
    if any(v <= 0 for v in zpq):
        raise testing.CantImplementError(f"Invalid output spatial shape: {zpq}")


def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    """Parse a comma-separated list of integers for an argparse option."""
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )


def _mma_kind_for_dtype(ab_dtype: Type[Numeric]) -> "prims.Tcgen05MMAKind":
    """Select the tcgen05 MMA kind from the A/B operand dtype.

    BF16 shares the ``f16`` kind (the instruction descriptor's a_dtype/b_dtype
    disambiguates it). Any other dtype raises.
    """
    if ab_dtype in {cutlass.Float16, cutlass.BFloat16}:
        return prims.Tcgen05MMAKind.F16
    if ab_dtype is cutlass.Float32:
        return prims.Tcgen05MMAKind.TF32
    if ab_dtype in {cutlass.Float8E4M3FN, cutlass.Float8E5M2}:
        return prims.Tcgen05MMAKind.F8F6F4
    raise TypeError(f"Unsupported tcgen05 MMA dtype: {ab_dtype!r}")


def _c_smem_swizzle(c_dtype: Type[Numeric], subtile_n: int) -> "cutlass.Swizzle":
    """Select the epilogue C-SMEM swizzle from the output dtype and subtile width.

    The store packs ``subtile_n`` output channels per row, so the swizzled region
    spans ``subtile_n * c_dtype.width // 8`` bytes, and the tcgen05 SMEM swizzle
    family is named by that byte width: 32B/64B/128B. The host C TMA descriptor
    and the device ``store_swizzled`` both derive from this one value.
    """
    row_bytes = subtile_n * c_dtype.width // 8
    if row_bytes == 32:
        return cutlass.Swizzle(1, 4, 3)  # s32b
    if row_bytes == 64:
        return cutlass.Swizzle(2, 4, 3)  # s64b
    if row_bytes == 128:
        return cutlass.Swizzle(3, 4, 3)  # s128b
    raise TypeError(
        f"No SMEM swizzle for {row_bytes}B C row "
        f"(subtile_n={subtile_n}, dtype={c_dtype!r}); "
        "expected 32/64/128B."
    )


@dataclass(frozen=True)
class _EpiDatapath:
    """Single source of truth for the epilogue (TMEM->RMEM->SMEM) datapath.

    One place resolves the ``(m_per_cta, use_2cta, c_dtype.width)`` config into
    the concrete tcgen05.ld shape, store kind, subtile width, and epilogue-warp split.
    The four decision sites (device SMEM sizing, device epilogue, host attribute
    setup, host C-descriptor) all read this descriptor.

    store_kind selects the SMEM store path:
      - "stmatrix"  : M==64, 1cta, width>=16  -> stmatrix (16x256b/16x128b tcgen05.ld)
      - "fp8_simt"  : M==64, 1cta, width==8   -> SIMT store_swizzled (16x32bx2)
      - "swizzled"  : everything else (cfgA M==128, cfgC M==64+2cta) -> 32x32b
    """

    store_kind: Literal["stmatrix", "fp8_simt", "swizzled"]
    subtile_n: int
    c_tile_rows: int
    t2r_inst_shape: str
    t2r_inst_repx: int
    t2r_ld_offset: int
    warp_m_count: int
    warp_n_count: int

    @property
    def use_stmatrix(self) -> bool:
        return self.store_kind == "stmatrix"

    @property
    def use_fp8_simt(self) -> bool:
        return self.store_kind == "fp8_simt"


def _select_epi_datapath(
    m_per_cta: int,
    use_2cta_instrs: bool,
    c_dtype: Type[Numeric],
    *,
    num_epi_warps: int = 4,
) -> _EpiDatapath:
    """Resolve the epilogue datapath descriptor from the tile/dtype config.

    Every field is a Python constant resolved here, so each caller just reads the
    field it needs. ``num_epi_warps`` is the structural epilogue-warp count (the
    kernel uses warps 0-3).
    """
    is_cfgB = m_per_cta == 64 and not use_2cta_instrs
    if is_cfgB and c_dtype.width >= 16:
        return _EpiDatapath(
            store_kind="stmatrix",
            subtile_n=(128 // c_dtype.width) * 2,
            c_tile_rows=m_per_cta,
            t2r_inst_shape="16x256b" if c_dtype.width == 16 else "16x128b",
            t2r_inst_repx=2,
            t2r_ld_offset=0,
            warp_m_count=num_epi_warps,
            warp_n_count=1,
        )
    if is_cfgB and c_dtype.width == 8:
        return _EpiDatapath(
            store_kind="fp8_simt",
            subtile_n=64,
            c_tile_rows=m_per_cta,
            t2r_inst_shape="16x32bx2",
            t2r_inst_repx=32,
            t2r_ld_offset=32,
            warp_m_count=num_epi_warps,
            warp_n_count=1,
        )
    is_cfgC = m_per_cta == 64 and use_2cta_instrs
    return _EpiDatapath(
        store_kind="swizzled",
        subtile_n=32,
        c_tile_rows=32 * num_epi_warps,
        t2r_inst_shape="32x32b",
        t2r_inst_repx=32,
        t2r_ld_offset=0,
        warp_m_count=2 if is_cfgC else num_epi_warps,
        warp_n_count=2 if is_cfgC else 1,
    )


# ---------------------------------------------------------------------------
# Host wrapper class + compile() / verify()
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------------------------


def check_tensor_alignment(
    c: int,
    k: int,
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
):
    """Check if the tensor alignment is valid for convolution.

    :param c: The number of input channels
    :param k: The number of output channels
    :param ab_dtype: The data type of the A and B operands
    :param c_dtype: The data type of the output tensor
    """

    def check_contiguous_16B_alignment(dtype, num_major_elements):
        num_contiguous_elements = 16 * 8 // dtype.width
        return num_major_elements % num_contiguous_elements == 0

    if not check_contiguous_16B_alignment(
        c_dtype, k
    ) or not check_contiguous_16B_alignment(ab_dtype, c):
        raise testing.CantImplementError(
            f"Invalid tensor alignment: C = {c}, K = {k}, ab_dtype = {ab_dtype}, c_dtype = {c_dtype}"
        )


def compute_zpq(
    dhw: Tuple[int, int, int],
    trs: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> Tuple[int, int, int]:
    """Compute output spatial dimensions Z, P, and Q with asymmetric padding."""
    D, H, W = dhw
    T, R, S = trs
    Sd, Sh, Sw = stride_dhw
    UpperPadD, UpperPadH, UpperPadW = upper_padding_dhw
    LowerPadD, LowerPadH, LowerPadW = lower_padding_dhw
    DilD, DilH, DilW = dilation_dhw
    Z = ((D + UpperPadD + LowerPadD - DilD * (T - 1) - 1) // Sd) + 1
    P = ((H + UpperPadH + LowerPadH - DilH * (R - 1) - 1) // Sh) + 1
    Q = ((W + UpperPadW + LowerPadW - DilW * (S - 1) - 1) // Sw) + 1
    return Z, P, Q


# sA/sB/sC each request this alignment, so every span declared before them is
# padded up to the next boundary.
_SMEM_ARRAY_ALIGN_BYTES = 1024


def _round_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) // alignment * alignment


def _compute_stages(
    a_bytes_per_stage: int,
    b_bytes_per_stage: int,
    c_bytes_per_stage: int,
    smem_capacity: int,
) -> Tuple[int, int, int]:
    """Largest (ACC, A/B, C) stage counts whose exact SMEM footprint fits.

    SMEM is declared in order: the mbarrier arrays and the TMEM slot, then sA,
    sB and sC. Each data tile requests ``_SMEM_ARRAY_ALIGN_BYTES``, so the span
    before it is padded up to that boundary, and the mbarrier bytes scale with
    ``num_ab_stage``. ``smem_bytes`` returns that exact footprint.

    :raises testing.CantImplementError: If even one A/B stage does not fit.
    """
    num_acc_stage = 2
    min_num_c_stage = 2

    def mbar_bytes(num_ab_stage: int) -> int:
        # ab_full + ab_empty (num_ab_stage each), acc_full + acc_empty
        # (num_acc_stage each) and the dealloc barrier are Int64; the TMEM
        # holding slot is Int32.
        return (2 * num_ab_stage + 2 * num_acc_stage + 1) * 8 + 4

    def smem_bytes(num_ab_stage: int, num_c_stage: int) -> int:
        # sC is declared last, so it carries no tail padding.
        return (
            _round_up(mbar_bytes(num_ab_stage), _SMEM_ARRAY_ALIGN_BYTES)
            + _round_up(a_bytes_per_stage * num_ab_stage, _SMEM_ARRAY_ALIGN_BYTES)
            + _round_up(b_bytes_per_stage * num_ab_stage, _SMEM_ARRAY_ALIGN_BYTES)
            + c_bytes_per_stage * num_c_stage
        )

    # One A/B stage costs its A and B bytes plus the 16 B of mbarrier it adds.
    fixed_bytes = (2 * num_acc_stage + 1) * 8 + 4 + c_bytes_per_stage * min_num_c_stage
    num_ab_stage = (smem_capacity - fixed_bytes) // (
        16 + a_bytes_per_stage + b_bytes_per_stage
    )
    # The three alignment pads add under 3 * _SMEM_ARRAY_ALIGN_BYTES, one stage
    # at this granularity, so the exact footprint settles the count here.
    while (
        num_ab_stage > 0 and smem_bytes(num_ab_stage, min_num_c_stage) > smem_capacity
    ):
        num_ab_stage -= 1
    if num_ab_stage == 0:
        raise testing.CantImplementError(
            f"one A/B stage needs {smem_bytes(1, min_num_c_stage)} B of shared "
            f"memory, more than the {smem_capacity} B capacity"
        )
    # sC takes what is left, with no tail padding after it.
    num_c_stage = (
        smem_capacity
        - _round_up(mbar_bytes(num_ab_stage), _SMEM_ARRAY_ALIGN_BYTES)
        - _round_up(a_bytes_per_stage * num_ab_stage, _SMEM_ARRAY_ALIGN_BYTES)
        - _round_up(b_bytes_per_stage * num_ab_stage, _SMEM_ARRAY_ALIGN_BYTES)
    ) // c_bytes_per_stage
    assert smem_bytes(num_ab_stage, num_c_stage) <= smem_capacity
    return num_acc_stage, num_ab_stage, num_c_stage


def check_im2col_descriptor_limits(
    filter_trs: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> None:
    """Check the convolution geometry against the 5D im2col descriptor field widths.

    A signed 5-bit corner per spatial dimension holds [-16, 15], an unsigned 5-bit
    coordinate offset holds [0, 31], and a 3-bit traversal stride holds the stride
    minus one. The leading corner is -lower_padding and the trailing one is
    upper_padding - (filter - 1) * dilation, so padding and dilation bind together.

    :raises testing.CantImplementError: If the geometry overflows a field
    """
    corner_lo = -16
    corner_hi = 15
    max_filter_offset = 31
    max_element_stride = 8
    for dim, flt, dil, pad_up, pad_lo, stride in zip(
        ("D", "H", "W"),
        filter_trs,
        dilation_dhw,
        upper_padding_dhw,
        lower_padding_dhw,
        stride_dhw,
        strict=True,
    ):
        leading_corner = -pad_lo
        trailing_corner = pad_up - (flt - 1) * dil
        if not corner_lo <= leading_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} leading im2col corner is -lower_padding = {leading_corner}, "
                f"outside the [{corner_lo}, {corner_hi}] a signed 5-bit corner "
                f"encodes; lower_padding_{dim.lower()} must be at most {-corner_lo}"
            )
        if not corner_lo <= trailing_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} trailing im2col corner is upper_padding - (filter - 1) * "
                f"dilation = {pad_up} - ({flt} - 1) * {dil} = {trailing_corner}, "
                f"outside the [{corner_lo}, {corner_hi}] a signed 5-bit corner encodes"
            )
        if stride > max_element_stride:
            raise testing.CantImplementError(
                f"stride_{dim.lower()}={stride} exceeds the {max_element_stride} a "
                f"traversal stride encodes, holding the stride minus one in 3 bits"
            )
        filter_offset = (flt - 1) * dil
        if filter_offset > max_filter_offset:
            raise testing.CantImplementError(
                f"{dim} filter offset is (filter - 1) * dilation = ({flt} - 1) * "
                f"{dil} = {filter_offset}, past the {max_filter_offset} an unsigned "
                f"5-bit im2col coordinate offset encodes"
            )


class Sm100DenseImplicitGemmFprop:
    """Implicit-GEMM fprop convolution kernel (host entry point).

    Derives the integer configuration the device ``kernel`` consumes -- input
    attributes, mma/tile shapes, SMEM byte sizes and pipeline stage counts --
    then launches it with a persistent tile scheduler.

    A is NDHWC C-major, B is KTRSC C-major, C is NZPQK K-major.
    """

    def __init__(
        self,
        acc_dtype: Type[Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: Tuple[int, int],
        cluster_shape_mn: Tuple[int, int],
        filter_trs: Tuple[int, int, int],
        upper_padding_dhw: Tuple[int, int, int],
        lower_padding_dhw: Tuple[int, int, int],
        stride_dhw: Tuple[int, int, int],
        dilation_dhw: Tuple[int, int, int],
    ):
        self.acc_dtype: Type[Numeric] = acc_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        self.split_k = 1
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)
        self.arch = "sm_100"
        # CTA group (1 or 2) is selected via use_2cta_instrs at the device
        # tcgen05 call sites (prims.CTAGroup.CTA_2).
        self.epilogue_warp_id = (0, 1, 2, 3)
        self.mma_warp_id = 4
        self.tma_warp_id = 5
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                *self.epilogue_warp_id,
            )
        )
        self.filter_trs = filter_trs
        self.upper_padding_dhw = upper_padding_dhw
        self.lower_padding_dhw = lower_padding_dhw
        self.stride_dhw = stride_dhw
        self.dilation_dhw = dilation_dhw

    def _check_supported_dtypes(
        self,
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        c_dtype: Type[Numeric],
    ):
        """Check if the dtypes are valid.

        :raises testing.CantImplementError: If the dtypes are invalid
        """
        # int8/uint8 A/B are rejected.
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float32,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if a_dtype not in valid_ab_dtypes or b_dtype not in valid_ab_dtypes:
            raise testing.CantImplementError(
                f"Unsupported AB dtype: {a_dtype} and {b_dtype}"
            )

        # The epilogue reads the accumulator through an fp32 t2r datapath, so fp32
        # is the accumulator width.
        if self.acc_dtype is not cutlass.Float32:
            raise testing.CantImplementError(
                f"Unsupported accumulator dtype: {self.acc_dtype}"
            )

        valid_c_dtypes = {
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if c_dtype not in valid_c_dtypes:
            raise testing.CantImplementError(f"Unsupported C dtype: {c_dtype}")

    def _check_mma_tiler_and_cluster_shape(self):
        """Check if the mma tiler and cluster shape are valid.

        :raises testing.CantImplementError: If the mma tiler and cluster shape are invalid
        """
        if not (
            (not self.use_2cta_instrs and self.mma_tiler_mn[0] in [64, 128])
            or (self.use_2cta_instrs and self.mma_tiler_mn[0] in [128, 256])
        ):
            raise testing.CantImplementError(
                f"Invalid mma tiler & use_2cta_instrs: {self.mma_tiler_mn}, {self.use_2cta_instrs}"
            )
        if self.mma_tiler_mn[1] not in range(32, 257, 32):
            raise testing.CantImplementError(
                f"Invalid mma tiler N: {self.mma_tiler_mn[1]}"
            )
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            raise testing.CantImplementError(
                f"Invalid cluster shape M: {self.cluster_shape_mn[0]}"
            )

        # Skip invalid cluster shape (total cluster including split_k must be <= 16)
        def is_power_of_2(x: int) -> bool:
            return x > 0 and (x & (x - 1)) == 0

        total_cluster_size = (
            self.cluster_shape_mn[0] * self.cluster_shape_mn[1] * self.split_k
        )
        if (
            total_cluster_size > 16
            or self.cluster_shape_mn[0] <= 0
            or self.cluster_shape_mn[1] <= 0
            or not is_power_of_2(self.cluster_shape_mn[0])
            or not is_power_of_2(self.cluster_shape_mn[1])
        ):
            raise testing.CantImplementError(
                f"Invalid cluster shape: {self.cluster_shape_mn} with split_k={self.split_k}"
            )

    def _check_epilogue_subtile(self, c_dtype: Type[Numeric]) -> None:
        """Require each epilogue warp's N band to hold whole epilogue subtiles.

        The epilogue splits mma tiler N into ``warp_n_count`` bands and stores each
        band in ``subtile_n``-column subtiles.

        :raises testing.CantImplementError: If a band is not a multiple of subtile_n
        """
        m_per_cta = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        epi = _select_epi_datapath(m_per_cta, self.use_2cta_instrs, c_dtype)
        band_n = self.mma_tiler_mn[1] // epi.warp_n_count
        if band_n % epi.subtile_n != 0:
            raise testing.CantImplementError(
                f"mma tiler N {self.mma_tiler_mn[1]} splits into {epi.warp_n_count} "
                f"epilogue N bands of {band_n} columns, which is not a multiple of "
                f"the {epi.subtile_n}-column epilogue subtile for {c_dtype}"
            )

    def _setup_conv_input_attrs(self, a, b, c):
        """Set the input-dependent attributes.

        Sets a_dtype, b_dtype, c_dtype. The layouts are fixed by the conv contract
        (A/B channel-contiguous, C K-contiguous) and baked into the TMA
        descriptors' stride_order.

        :param a: Input tensor A - (N, D, H, W, C) layout
        :param b: Filter tensor B - (K, T, R, S, C) layout
        :param c: Output tensor C - (N, Z, P, Q, K) layout
        """
        self.a_dtype: Type[Numeric] = a.element_type
        self.b_dtype: Type[Numeric] = b.element_type
        self.c_dtype: Type[Numeric] = c.element_type

    def _setup_attributes(self):
        """Set up convolution-input-dependent configuration as plain integers
        (mma shapes, SMEM byte sizes, stage counts, multicast counts). The
        device kernel consumes only these scalars plus the TMA descriptors.
        """
        # Compute mma/cluster/tile shapes.
        # tcgen05 MMA K-instruction = 256 / dtype.width (FP16/BF16->16, FP8->32,
        # TF32->8).
        mma_inst_shape_k = 256 // self.a_dtype.width
        mma_inst_tile_k = 4
        # atom_thr_size = number of CTAs cooperating on one MMA atom along M;
        # 2 for 2-CTA MMA, else 1.
        atom_thr_size = 2 if self.use_2cta_instrs else 1
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            (mma_inst_shape_k * mma_inst_tile_k,),
        )
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // atom_thr_size,
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.smem_capacity = get_smem_capacity_in_bytes()

        # Per-CTA SMEM byte sizes per stage (K-tile = mma_tiler[2]).
        k_tile = mma_inst_shape_k * mma_inst_tile_k
        m_per_cta = self.mma_tiler[0] // atom_thr_size
        n_per_cta = self.mma_tiler[1] // atom_thr_size
        # Epilogue C sizing comes from the epilogue datapath descriptor.
        epi = _select_epi_datapath(m_per_cta, self.use_2cta_instrs, self.c_dtype)
        epi_subtile_n = epi.subtile_n
        c_tile_rows = epi.c_tile_rows
        a_bytes_per_stage = m_per_cta * k_tile * (self.a_dtype.width // 8)
        b_bytes_per_stage = n_per_cta * k_tile * (self.b_dtype.width // 8)
        c_bytes_per_stage = c_tile_rows * epi_subtile_n * (self.c_dtype.width // 8)

        # Setup A/B/C stage count in shared memory and ACC stage count in tensor memory
        self.num_acc_stage, self.num_ab_stage, self.num_c_stage = _compute_stages(
            a_bytes_per_stage,
            b_bytes_per_stage,
            c_bytes_per_stage,
            self.smem_capacity,
        )

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream,
        epilogue_op: cutlass.Constexpr = lambda x: x,
    ):
        """Materialise kernel arguments from setup attrs and launch the device kernel."""
        self._setup_conv_input_attrs(a, b, c)
        self._setup_attributes()

        # Host TMA descriptors, built directly from the raw input tensors via
        # cuda.create_tensor_map_*.
        T_filter, R_filter, S_filter = self.filter_trs
        upad_d, upad_h, upad_w = self.upper_padding_dhw
        lpad_d, lpad_h, lpad_w = self.lower_padding_dhw
        dil_d, dil_h, dil_w = self.dilation_dhw
        # Per-CTA M tile (use_2cta_instrs splits M between 2 CTAs along cluster_m).
        mma_tiler_per_cta_m = (
            self.mma_tiler[0] // 2 if self.use_2cta_instrs else self.mma_tiler[0]
        )
        # mma_tiler[2] is a sub-tuple (K_tile,) after _setup_attributes.
        k_tile = cute.size(self.mma_tiler, mode=[2])
        # Epilogue subtile width (K-mode of NZPQK), from the epilogue datapath
        # descriptor.
        subtile_n = _select_epi_datapath(
            mma_tiler_per_cta_m, self.use_2cta_instrs, self.c_dtype
        ).subtile_n

        # Activation A: NDHWC raw, im2col descriptor. stride_order=(4,3,2,1,0)
        # puts C innermost. lower/upper_corner are the stride-ascending spatial dims:
        # lower = -pad_lower, upper = pad_upper - (filter-1)*dilation. These corners
        # fix the window extent the hardware walks, so a wrong upper drifts every
        # wrapped row by (filter-1) pixels.
        tma_a_desc = cuda.create_tensor_map_im2col_from_view(
            a,
            lower_corner=[-lpad_w, -lpad_h, -lpad_d],
            upper_corner=[
                upad_w - (S_filter - 1) * dil_w,
                upad_h - (R_filter - 1) * dil_h,
                upad_d - (T_filter - 1) * dil_d,
            ],
            channels_per_pixel=k_tile,
            pixels_per_column=mma_tiler_per_cta_m,
            traversal_strides=[
                1,
                self.stride_dhw[2],
                self.stride_dhw[1],
                self.stride_dhw[0],
                1,
            ],
            stride_order=(4, 3, 2, 1, 0),
            swizzle=cuda.TensorMapSwizzle.s128b,
        )

        # Filter B: KTRSC raw, tiled descriptor.
        # box_dims is in tensor mode order (K, T, R, S, C). The GEMM-K tile is
        # drawn from C alone, so the (T, R, S) box dims are 1.
        n_per_cta = (
            self.mma_tiler[1] // 2 if self.use_2cta_instrs else self.mma_tiler[1]
        )
        tma_b_desc = cuda.create_tensor_map_tiled_from_view(
            b,
            box_dims=(n_per_cta, 1, 1, 1, k_tile),
            stride_order=(4, 3, 2, 1, 0),
            swizzle=cuda.TensorMapSwizzle.s128b,
        )

        # Output C: NZPQK raw, im2col store descriptor with zero corners.
        # channels_per_pixel = subtile_n K-cols per TMA call; the swizzle is the
        # epilogue C SMEM swizzle from _c_smem_swizzle.
        c_swizzle = _c_smem_swizzle(self.c_dtype, subtile_n).to(cuda.TensorMapSwizzle)
        tma_c_desc = cuda.create_tensor_map_im2col_from_view(
            c,
            lower_corner=[0, 0, 0],
            upper_corner=[0, 0, 0],
            channels_per_pixel=subtile_n,
            pixels_per_column=mma_tiler_per_cta_m,
            stride_order=(4, 3, 2, 1, 0),
            swizzle=c_swizzle,
        )

        # Persistent tile scheduler params — integer tile counts. Implicit-GEMM
        # mapping: M = N*Z*P*Q (rows of C), N(gemm) = K (channels of C).
        # c.shape = (N, Z, P, Q, K). cta tile = cta_tile_shape_mnk[:2].
        m_total = c.shape[0] * c.shape[1] * c.shape[2] * c.shape[3]
        n_total = c.shape[4]
        cta_m = self.cta_tile_shape_mnk[0]
        cta_n = self.cta_tile_shape_mnk[1]
        num_ctas_mnl = (
            (m_total + cta_m - 1) // cta_m,
            (n_total + cta_n - 1) // cta_n,
            1,
        )
        cluster_shape_mnl = (*self.cluster_shape_mn, 1)
        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        # mma_inst_shape_mnk — per-MMA atomic instruction shape, used by the
        # kernel for the SMEM-desc K-block stride. tcgen05 atomic shape is
        # (mma_tiler_M, mma_tiler_N, K_inst); K_inst = 256 // dtype.width
        # (FP16/BF16->16, FP8->32, TF32->8).
        mma_inst_shape_mnk = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            256 // self.a_dtype.width,
        )

        # GEMM-K tile count: one tile per (filter position, C chunk), matching the
        # coord the producer walks. The filter descriptor box is 1 along (T, R, S)
        # so a tile is drawn from C alone, and a C shorter than one chunk reads the
        # tail out of bounds, which the TMA zero-fills on both operands.
        mma_tiler_k = cute.size(self.mma_tiler, mode=[2])
        c_chunk_cnt = (a.shape[4] + mma_tiler_k - 1) // mma_tiler_k
        k_tile_cnt = T_filter * R_filter * S_filter * c_chunk_cnt

        # Output spatial dims for the im2col producer/epilogue coord decode:
        # c.shape = (N, Z, P, Q, K).
        zpq = (c.shape[1], c.shape[2], c.shape[3])

        # Launch the kernel (argument order matches the device kernel
        # signature).
        self.kernel(
            tile_sched_params,
            self.mma_tiler,
            mma_inst_shape_mnk,
            k_tile_cnt,
            self.num_ab_stage,
            self.num_acc_stage,
            self.num_c_stage,
            self.use_2cta_instrs,
            self.a_dtype,
            self.c_dtype,
            self.acc_dtype,
            self.lower_padding_dhw,
            self.stride_dhw,
            self.dilation_dhw,
            zpq,
            self.filter_trs,
            tma_a_desc,
            tma_b_desc,
            tma_c_desc,
            epilogue_op,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
        )
        return

    @cute.kernel
    def kernel(
        self,
        tile_sched_params: PersistentTileSchedulerParams,
        mma_tiler: cutlass.Constexpr[Tuple[int, int, int]],
        mma_inst_shape_mnk: cutlass.Constexpr[Tuple[int, int, int]],
        # GEMM-K tile count (= T*R*S * ceil_div(C, mma_tiler_k)), host-computed.
        k_tile_cnt: cutlass.Constexpr[int],
        num_ab_stage: cutlass.Constexpr[int],
        num_acc_stage: cutlass.Constexpr[int],
        num_c_stage: cutlass.Constexpr[int],
        use_2cta_instrs: cutlass.Constexpr[bool],
        ab_dtype: cutlass.Constexpr[Type[Numeric]],
        c_dtype: cutlass.Constexpr[Type[Numeric]],
        acc_dtype: cutlass.Constexpr[Type[Numeric]],
        # Conv geometry consumed by the im2col TMA producer / epilogue:
        # zpq      = output spatial dims (Z, P, Q) used to decompose linear M -> (n,z,p,q)
        # trs      = filter spatial dims (T, R, S) used to decompose K-tile index
        # lower_pad_dhw / stride_dhw / dilation_dhw = standard conv params
        lower_pad_dhw: cutlass.Constexpr[Tuple[int, int, int]],
        stride_dhw: cutlass.Constexpr[Tuple[int, int, int]],
        dilation_dhw: cutlass.Constexpr[Tuple[int, int, int]],
        zpq: cutlass.Constexpr[Tuple[int, int, int]],
        trs: cutlass.Constexpr[Tuple[int, int, int]],
        # Host-built TMA descriptors, consumed by the device-side
        # prims.cp_async_bulk_tensor_* / prims.prefetch_tensormap calls.
        tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
        tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
        tma_c_desc: cutlass.GridConstant[cuda.TensorMap],
        epilogue_op: cutlass.Constexpr,
    ) -> None:
        """Implicit-GEMM fprop kernel: TMA load + tcgen05 MMA + TMA store."""

        # Warp / thread / cluster identity
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        tidx, _, _ = cute.arch.thread_idx()
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )

        # CTA-group geometry, threaded through every tcgen05 call site below.
        # _atom_thr = MMA-atom CTA count (2 for the 2-CTA tcgen05 group, else 1).
        # Cluster ranks are M-fast (grid.x = cluster_m), so a 2-CTA group G spans
        # ranks {2G, 2G+1} with its leader at the even rank 2G. _cta_group is the
        # matching nvvm enum.
        _atom_thr = 2 if cutlass.const_expr(use_2cta_instrs) else 1
        _cta_group = (
            prims.CTAGroup.CTA_2
            if cutlass.const_expr(use_2cta_instrs)
            else prims.CTAGroup.CTA_1
        )
        if cutlass.const_expr(use_2cta_instrs):
            # 2-CTA group leader = even cluster rank (covers multi-group clusters,
            # e.g. cluster_m > 2, where group 1's leader sits at rank 2).
            is_leader_cta = (cta_rank_in_cluster % _atom_thr) == 0
            # tcgen05_commit multicast mask: 3 << rank covers the issuing group's
            # own pair {2G, 2G+1}. Only the leader (even rank) issues the commit.
            _commit_mask = cutlass.Int32(3) << cta_rank_in_cluster
        else:
            # 1-CTA path: every CTA owns its own accumulator => its own leader.
            # constexpr True so the leader-gated scf.if branches elide entirely.
            is_leader_cta = True
            # None selects the CTA_1 no-multicast commit path (arrive on own mbar).
            _commit_mask = None

        # Warp role assignment: epilogue 0-3, MMA 4, TMA producer 5.
        epilogue_warp_ids = (0, 1, 2, 3)
        mma_warp_id = 4
        tma_warp_id = 5

        # Prefetch the three TMA descriptors from the MMA warp; the descriptor cache
        # is shared across the cluster.
        if warp_idx == mma_warp_id:
            prims.prefetch_tensormap(tma_a_desc.get_ptr())
            prims.prefetch_tensormap(tma_b_desc.get_ptr())
            prims.prefetch_tensormap(tma_c_desc.get_ptr())

        # ===== Shared memory: data tiles + mbarriers + cluster init =====
        #
        # Every SMEM object is a flat cutlass.Array(space=smem) in declaration order.
        # Swizzle is expressed by the descriptors (cuda.TensorMapSwizzle.* on the host,
        # Tcgen05SmemDesc layout on device).
        ab_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
        )
        ab_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem
        )
        acc_full_mbar_ptr = cutlass.Array(
            cutlass.Int64, num_acc_stage, space=cutlass.AddressSpace.smem
        )
        acc_empty_mbar_ptr = cutlass.Array(
            cutlass.Int64, num_acc_stage, space=cutlass.AddressSpace.smem
        )
        tmem_dealloc_mbar_ptr = cutlass.Array(
            cutlass.Int64, 1, space=cutlass.AddressSpace.smem
        )
        tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

        # Per-CTA per-stage SMEM byte sizes (integer).
        _m_per_cta = mma_tiler[0] // _atom_thr
        _n_per_cta = mma_tiler[1] // _atom_thr
        _k_tile = cute.size(mma_tiler, mode=[2])
        _a_stage_bytes = _m_per_cta * _k_tile * (ab_dtype.width // 8)
        _b_stage_bytes = _n_per_cta * _k_tile * (ab_dtype.width // 8)
        # Epilogue C tile sizing from the epilogue datapath descriptor.
        _epi = _select_epi_datapath(
            _m_per_cta, use_2cta_instrs, c_dtype, num_epi_warps=len(epilogue_warp_ids)
        )
        _epi_subtile_n = _epi.subtile_n
        _c_tile_rows = _epi.c_tile_rows
        _c_stage_bytes = _c_tile_rows * _epi_subtile_n * (c_dtype.width // 8)

        # A/B/C data tiles as flat Int8 byte arrays (1024B aligned).
        sA = cutlass.Array(
            cutlass.Int8,
            _a_stage_bytes * num_ab_stage,
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        sB = cutlass.Array(
            cutlass.Int8,
            _b_stage_bytes * num_ab_stage,
            space=cutlass.AddressSpace.smem,
            alignment=1024,
        )
        # Epilogue C SMEM (only when TMA store is used; num_c_stage stages).
        sC = None
        if cutlass.const_expr(num_c_stage > 0):
            sC = cutlass.Array(
                c_dtype,
                (_c_stage_bytes // (c_dtype.width // 8)) * num_c_stage,
                space=cutlass.AddressSpace.smem,
                alignment=1024,
            )

        # mbarrier_init: one warp / one lane initializes every barrier.
        # arrive_count for acc_empty is (4 epilogue warps) × (2 CTAs if 2cta else 1).
        num_acc_empty_arrives = len(epilogue_warp_ids) * (2 if use_2cta_instrs else 1)
        if warp_idx == 0:
            if prims.elect_sync():
                prims.mbarrier_init(tmem_dealloc_mbar_ptr, cute.arch.WARP_SIZE)
                for i in cutlass.range_constexpr(num_acc_stage):
                    prims.mbarrier_init(
                        acc_empty_mbar_ptr.subview(i), num_acc_empty_arrives
                    )
                    prims.mbarrier_init(acc_full_mbar_ptr.subview(i), 1)
                for i in cutlass.range_constexpr(num_ab_stage):
                    prims.mbarrier_init(ab_full_mbar_ptr.subview(i), 1)
                    prims.mbarrier_init(ab_empty_mbar_ptr.subview(i), 1)

        # Cluster sync sandwich: fence_mbarrier_init publishes the mbarrier_init
        # writes to the cluster; barrier_cluster_arrive_relaxed signals this CTA is
        # done initializing; barrier_cluster_wait (later, after tile geometry is
        # set up) blocks until every CTA in the cluster arrives.
        prims.fence_mbarrier_init()
        prims.barrier_cluster_arrive_relaxed()

        # Initial pipeline phase bits — parity flips on stage wrap-around.
        ab_empty_phase_bit = 1
        ab_full_phase_bit = 0
        acc_empty_phase_bit = 1
        acc_full_phase_bit = 0

        # Pre-build the tcgen05 instruction descriptor (constexpr) so MMA / epilogue
        # warps can reference it without recomputing. mma_inst_shape_mnk encodes the
        # per-instruction (M, N, K) shape, e.g. (256, 32, 16) for FP16/2cta.
        idesc = prims.Tcgen05InstrDesc.build(
            a_dtype=ab_dtype,
            b_dtype=ab_dtype,
            c_dtype=acc_dtype,
            m_dim=mma_inst_shape_mnk[0],
            n_dim=mma_inst_shape_mnk[1],
        )
        # MMA kind is fixed by the operand dtype (constexpr) and shared by every
        # tcgen05.mma issued in the K-loop below.
        mma_kind = _mma_kind_for_dtype(ab_dtype)

        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        # tcgen05 TMEM allocation granularity (always 512 cols on Blackwell).
        num_tmem_cols = 512

        # Cluster wait — gates SMEM/mbarrier visibility before any warp loads/stores.
        prims.barrier_cluster_wait()

        # ===== Tile geometry (visible to all warps) =====
        #
        # The loads, the store and the MMA take descriptor pointers plus the
        # per-CTA tile scalars computed below.

        # Per-CTA tile sizes (used by raw TMA producer + tcgen05 desc strides).
        mma_tiler_per_cta_m = mma_tiler[0] // (2 if use_2cta_instrs else 1)
        n_per_cta = mma_tiler[1] // (2 if use_2cta_instrs else 1)
        k_tile_size = cute.size(mma_tiler, mode=[2])

        # Bytes-per-K-tile expectation. For the 2-CTA cluster the leader writes
        # expect_tx for both CTAs' loads (the peer slot is reached via the
        # mbarrier bit-24 clear inside the wrapper).
        a_bytes_per_stage = mma_tiler_per_cta_m * k_tile_size * (ab_dtype.width // 8)
        b_bytes_per_stage = n_per_cta * k_tile_size * (ab_dtype.width // 8)
        num_tma_copy_bytes = a_bytes_per_stage + b_bytes_per_stage
        if cutlass.const_expr(use_2cta_instrs):
            num_tma_copy_bytes = num_tma_copy_bytes * 2

        # ===== TMA producer warp =====
        # Per-CTA unicast prims.cp_async_bulk_tensor loads. Im2col coords decompose
        # from the linear M index (m_off_cta -> n, z, p, q). The filter coord (s, r, t)
        # is loop-carried and advanced by a colexicographic carry.
        if warp_idx == tma_warp_id:
            ab_stage_idx = 0
            Z_out, P_out, Q_out = zpq
            T_filt, R_filt, S_filt = trs
            pad_d, pad_h, pad_w = lower_pad_dhw
            str_d, str_h, str_w = stride_dhw
            dil_d, dil_h, dil_w = dilation_dhw
            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // (2 if use_2cta_instrs else 1),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                # M index for this CTA's portion of the M-tile.
                m_off_cta = (
                    mma_tile_coord_mnl[0] * mma_tiler[0]
                    + (cta_rank_in_cluster % _atom_thr if use_2cta_instrs else 0)
                    * mma_tiler_per_cta_m
                )
                # Output (n, z, p, q) from linear M (col-major Q-fastest).
                n_idx = m_off_cta // (Q_out * P_out * Z_out)
                rem = m_off_cta % (Q_out * P_out * Z_out)
                z_idx = rem // (Q_out * P_out)
                rem = rem % (Q_out * P_out)
                p_idx = rem // Q_out
                q_idx = rem % Q_out
                # Spatial anchors for im2col TMA: idx*stride - pad_lower.
                w_anchor = q_idx * str_w - pad_w
                h_anchor = p_idx * str_h - pad_h
                d_anchor = z_idx * str_d - pad_d
                # B side: per-CTA N offset (KTRSC tiled descriptor consumes this).
                n_off_cta = (
                    mma_tile_coord_mnl[1] * mma_tiler[1]
                    + (cta_rank_in_cluster % _atom_thr if use_2cta_instrs else 0)
                    * n_per_cta
                )

                # Filter coord (s, r, t) + C-chunk, carried across K-tiles and
                # advanced colexicographically (s fastest). Reset to origin per
                # work-tile since each tile sweeps GEMM-K from 0.
                s_idx = 0
                r_idx = 0
                t_idx = 0
                c_chunk_idx = 0
                for k in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    mbar_full = ab_full_mbar_ptr.subview(ab_stage_idx)
                    mbar_empty = ab_empty_mbar_ptr.subview(ab_stage_idx)

                    # Producer acquire: wait until consumer (MMA) released this stage.
                    # try_wait_parity issues a single non-blocking attempt that may
                    # hardware-suspend up to time_limit then return False; a blocking
                    # wait must retry in a loop.
                    while not prims.mbarrier_try_wait_parity(
                        mbar_empty, ab_empty_phase_bit, time_limit=10000000
                    ):
                        pass

                    # Filter/C offsets from the carried colex coord.
                    c_off = c_chunk_idx * k_tile_size
                    # Im2col offsets fold dilation in.
                    s_off = s_idx * dil_w
                    r_off = r_idx * dil_h
                    t_off = t_idx * dil_d

                    # Per-stage SMEM slices as cutlass.Array byte offsets: sA/sB are
                    # flat Int8 arrays, stage stride = bytes-per-stage.
                    sA_stage = sA.subview(ab_stage_idx * a_bytes_per_stage)
                    sB_stage = sB.subview(ab_stage_idx * b_bytes_per_stage)

                    if prims.elect_sync():
                        # Group leader sets the byte expectation. In 2cta the even-rank leader counts
                        # both pair members' loads (bytes doubled; bit-24 routing folds the peer's
                        # complete_tx onto the leader mbar). In 1cta is_leader_cta is constexpr-True,
                        # so every CTA counts its own bytes on its own mbar.
                        if is_leader_cta:
                            prims.mbarrier_arrive_expect_tx(
                                mbar_full, num_tma_copy_bytes
                            )
                        # Per-CTA unicast load; _cta_group selects the 1-/2-CTA
                        # tcgen05 group (identical coords/box on both paths).
                        prims.cp_async_bulk_tensor_shared_cluster_global(
                            sA_stage,
                            tma_a_desc.get_ptr(),
                            (c_off, w_anchor, h_anchor, d_anchor, n_idx),
                            mbar_full,
                            [s_off, r_off, t_off],
                            mode=prims.TMALoadMode.IM2COL,
                            group=_cta_group,
                        )
                        prims.cp_async_bulk_tensor_shared_cluster_global(
                            sB_stage,
                            tma_b_desc.get_ptr(),
                            (c_off, s_idx, r_idx, t_idx, n_off_cta),
                            mbar_full,
                            [],
                            group=_cta_group,
                        )

                    ab_stage_idx += 1
                    if ab_stage_idx == num_ab_stage:
                        ab_stage_idx = 0
                        ab_empty_phase_bit = ab_empty_phase_bit ^ 1

                    # Colex carry of (s, r, t, c_chunk): bump s, ripple right on wrap.
                    s_idx += 1
                    if s_idx == S_filt:
                        s_idx = 0
                        r_idx += 1
                        if r_idx == R_filt:
                            r_idx = 0
                            t_idx += 1
                            if t_idx == T_filt:
                                t_idx = 0
                                c_chunk_idx += 1

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Producer tail: wait until the MMA warp has released the last used AB
            # stage, so no ab_empty arrive is still in flight when this CTA exits.
            ab_tail_stage = ab_stage_idx
            ab_tail_phase = ab_empty_phase_bit
            for _ in cutlass.range_constexpr(num_ab_stage - 1):
                ab_tail_stage = ab_tail_stage + 1
                if ab_tail_stage == num_ab_stage:
                    ab_tail_stage = 0
                    ab_tail_phase = ab_tail_phase ^ 1
            if prims.elect_sync():
                while not prims.mbarrier_try_wait_parity(
                    ab_empty_mbar_ptr.subview(ab_tail_stage),
                    ab_tail_phase,
                    time_limit=10000000,
                ):
                    pass

        # ---- MMA consumer warp ----
        elif warp_idx == mma_warp_id:
            # MMA + 4 epilogue warps participate in this barrier so the MMA warp
            # can pick up the tmem_ptr written by the allocator (epilogue warp 0).
            # Non-aligned subset barrier — only 5 warps × 32 threads = 160 lanes.
            tmem_bar_id = 1
            tmem_bar_threads = 32 * (1 + len(epilogue_warp_ids))
            prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)
            tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), acc_dtype)

            # AB / acc pipeline consumer state — tracks the current MMA stage.
            ab_stage_idx = 0
            acc_stage_idx = 0

            # tcgen05 SMEM descriptors for stage 0. tcgen05_mma encodes SMEM addresses
            # in 16-byte units, so per-stage / per-K-block increments are bytes >> 4.
            # (leading=16, stride=1024, layout=2) is the 128B-swizzle K-major layout,
            # matching cuda.TensorMapSwizzle.s128b on the A/B descriptors.
            desc_a_base = prims.Tcgen05SmemDesc.build(
                sA,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )
            desc_b_base = prims.Tcgen05SmemDesc.build(
                sB,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                layout=2,
            )

            # Per-stage descriptor delta (one full AB stage in SMEM, in 16B units).
            sA_increment_per_stage = a_bytes_per_stage >> 4
            sB_increment_per_stage = b_bytes_per_stage >> 4

            desc_a_cur = desc_a_base
            desc_b_cur = desc_b_base

            # Per-K-block descriptor delta inside one AB stage.
            inc_bytes_per_iter = mma_inst_shape_mnk[2] * ab_dtype.width // 8
            increment = inc_bytes_per_iter >> 4
            # Conv K-dim is structured (C,S,R,T); flatten via cute.size before //.
            num_k_blocks = cute.size(mma_tiler, mode=[2]) // mma_inst_shape_mnk[2]

            # Persistent loop: outer = work tiles (acc stages); inner = K-tiles.
            while work_tile.is_valid_tile:
                current_acc_stage = acc_stage_idx
                acc_empty_mbar_ptr_stage = acc_empty_mbar_ptr.subview(current_acc_stage)
                acc_full_mbar_ptr_stage = acc_full_mbar_ptr.subview(current_acc_stage)
                current_empty_phase_bit = acc_empty_phase_bit

                acc_stage_idx += 1
                if acc_stage_idx == num_acc_stage:
                    acc_stage_idx = 0
                    acc_empty_phase_bit = acc_empty_phase_bit ^ 1

                if is_leader_cta:
                    # Wait until the epilogue released this acc stage.
                    # try_wait_parity is one non-blocking attempt; loop until it
                    # reports the phase advanced.
                    while not prims.mbarrier_try_wait_parity(
                        acc_empty_mbar_ptr_stage,
                        current_empty_phase_bit,
                        time_limit=10000000,
                    ):
                        pass
                    # Order the epilogue's TMEM reads, released through acc_empty,
                    # before this tile's MMAs.
                    prims.tcgen05_fence(prims.Tcgen05Fence.AFTER_THREAD_SYNC)

                    # Per-stage TMEM pointer. A TMEM Pointer holds a packed i32
                    # address token (col in bits [0:16), row in [16:32)); adding an
                    # int advances the raw column id directly, with no element/byte
                    # scaling. Each acc stage owns a full mma_tiler[1]-wide column
                    # band, so the per-stage stride is exactly mma_tiler[1] columns.
                    tmem_ptr_for_mma = (
                        tmem_ptr.data_ptr() + current_acc_stage * mma_tiler[1]
                    )
                    tmem_ptr_curr = cutlass.Array(
                        tmem_ptr_for_mma, dtype=cutlass.Int32, addrspace=6
                    )

                    # scale_d=False (overwrite) on the first MMA of this C-tile's K-loop,
                    # True (accumulate) afterwards. The predicate is a runtime expression
                    # on (k_idx, kb_idx).
                    for k_idx in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                        ab_full_mbar_ptr_stage = ab_full_mbar_ptr.subview(ab_stage_idx)
                        ab_empty_mbar_ptr_stage = ab_empty_mbar_ptr.subview(
                            ab_stage_idx
                        )

                        # Wait for producer (TMA warp) to fill this AB stage.
                        # try_wait_parity is one non-blocking attempt; loop until the
                        # producer's arrive advances the phase.
                        while not prims.mbarrier_try_wait_parity(
                            ab_full_mbar_ptr_stage,
                            ab_full_phase_bit,
                            time_limit=10000000,
                        ):
                            pass

                        # Issue all K-blocks for this AB stage.
                        desc_a_cur_ = desc_a_cur
                        desc_b_cur_ = desc_b_cur
                        for kb_idx in cutlass.range_constexpr(num_k_blocks):
                            scale_d_now = (k_idx > 0) | (kb_idx > 0)
                            if prims.elect_sync():
                                prims.tcgen05_mma(
                                    mma_kind,
                                    _cta_group,
                                    tmem_ptr_curr,
                                    desc_a_cur_,
                                    desc_b_cur_,
                                    idesc,
                                    scale_d_now,
                                )
                            desc_a_cur_ = desc_a_cur_ + increment
                            desc_b_cur_ = desc_b_cur_ + increment

                        ab_stage_idx += 1
                        desc_a_cur = desc_a_cur + sA_increment_per_stage
                        desc_b_cur = desc_b_cur + sB_increment_per_stage
                        if ab_stage_idx == num_ab_stage:
                            ab_stage_idx = 0
                            desc_a_cur = desc_a_base
                            desc_b_cur = desc_b_base
                            ab_full_phase_bit = ab_full_phase_bit ^ 1

                        if prims.elect_sync():
                            # Release this AB stage to the TMA producer. In 2cta
                            # _commit_mask = 3 << rank broadcasts to the issuing
                            # group's pair; in 1cta it is None (arrive on own mbar).
                            prims.tcgen05_commit(
                                ab_empty_mbar_ptr_stage,
                                multicast_mask=_commit_mask,
                                group=_cta_group,
                            )

                    if prims.elect_sync():
                        # K-tile loop done — signal accumulator full to epilogue
                        # warps (both CTAs of the group in 2cta; own CTA in 1cta).
                        prims.tcgen05_commit(
                            acc_full_mbar_ptr_stage,
                            multicast_mask=_commit_mask,
                            group=_cta_group,
                        )

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Tail: keep the leader CTA resident until the last tile's acc_empty
            # arrives land.
            tail_stage = acc_stage_idx
            tail_phase = acc_empty_phase_bit
            if is_leader_cta:
                for _ in cutlass.range_constexpr(num_acc_stage - 1):
                    tail_stage = tail_stage + 1
                    if tail_stage == num_acc_stage:
                        tail_stage = 0
                        tail_phase = tail_phase ^ 1
                if prims.elect_sync():
                    while not prims.mbarrier_try_wait_parity(
                        acc_empty_mbar_ptr.subview(tail_stage),
                        tail_phase,
                        time_limit=10000000,
                    ):
                        pass

        # ---- Epilogue warps (0-3) ----
        elif warp_idx < mma_warp_id:
            # Per-CTA M tile size — 2cta cluster halves mma_tiler[0] across the pair.
            mma_tiler_per_cta_m = (
                mma_tiler[0] // 2
                if cutlass.const_expr(use_2cta_instrs)
                else mma_tiler[0]
            )
            # Epilogue datapath descriptor, resolved once in the prologue and read
            # here, by the SMEM sizing and by the host C descriptor.
            use_stmatrix_epi = _epi.use_stmatrix
            use_fp8_simt_epi = _epi.use_fp8_simt
            warp_m_count = _epi.warp_m_count
            warp_n_count = _epi.warp_n_count
            # This warp's position in the (warp_m, warp_n) grid.
            warp_m_idx = warp_idx % warp_m_count
            warp_n_idx = warp_idx // warp_m_count
            # TMEM->RMEM load shape + SMEM N-subtile width + column half-split
            # offset (only 16x32bx2 fp8 uses a non-zero offset).
            t2r_inst_shape = _epi.t2r_inst_shape
            t2r_inst_repx = _epi.t2r_inst_repx
            t2r_ld_offset = _epi.t2r_ld_offset
            subtile_n = _epi.subtile_n
            # N-subtiles per warp = warp's N-band width (full N / warp_n) / subtile_n.
            #   cfgB fp16: 256/16=16.  cfgB fp32: 256/8=32.  cfgB fp8: 256/64=4.
            #   cfgA: 256/32=8.  cfgC: 128/32=4.
            subtile_cnt = (mma_tiler[1] // warp_n_count) // subtile_n

            # Sync ids: tmem_bar_id=1 is shared with the MMA warp; epilog_sync_bar_id=2
            # spans the 4 epilogue warps.
            threads_in_epilogue = 32 * len(epilogue_warp_ids)
            epilog_sync_bar_id = 2
            allocator_warp_id = epilogue_warp_ids[0]
            tmem_bar_id = 1
            tmem_bar_threads = 32 * (1 + len(epilogue_warp_ids))

            # 128-bit (16-byte) SMEM store width — store_swizzled vectorizes per lane,
            # and every per-lane store address is 16-byte aligned.
            vsize = 128 // c_dtype.width

            # per-CTA M=64 thread->SMEM placement (hoisted, CTA-invariant). Both cfgB
            # datapaths share one thread->(row, channel-half) map: thread (warp w,
            # lane_lo L, lane_hi H) owns SMEM M-row (w*16+L), channel-half H, so
            # final_offset = L*subtile_n + H*(subtile_n//2) + w*16*subtile_n. Offsets
            # scale with subtile_n, so the byte layout holds for every C dtype.
            if cutlass.const_expr(use_stmatrix_epi or use_fp8_simt_epi):
                t_div_16 = tidx // 16
                t_mod_16 = tidx % 16
                final_offset = (
                    t_mod_16 * subtile_n
                    + (t_div_16 % 2) * (subtile_n // 2)
                    + (t_div_16 // 2) * 16 * subtile_n
                )
            # stmatrix-only constants. stmatrix.8x8.x4 lays an 8x8 b16 fragment per
            # call (16 B/thread = 8 f16 or 4 f32) into SW32-swizzled C SMEM (s32b
            # descriptor), so the store address is XOR-permuted by hand: Swizzle(1,4,3)
            # => mask=128,shift=3.
            if cutlass.const_expr(use_stmatrix_epi):
                stmatrix_layout = prims.MMALayout.ROW
                stmatrix_shape = "m8n8"
                _swz_mask = cutlass.Int64(128)
                _swz_shift = cutlass.Int64(3)

            # C-side im2col store coords: the C descriptor uses zero corners, so
            # output spatial coords are bare pixels. The linear per-CTA M index
            # decomposes into (n, z, p, q) per work-tile in the loop.
            Z_out, P_out, Q_out = zpq

            # Allocator warp (epi 0) reserves 512 TMEM cols and stashes the pointer
            # in tmem_ptr_i32. Every CTA allocates from its own 512-col bank. The op
            # is warp-collective, so the whole warp issues it.
            if warp_idx == allocator_warp_id:
                prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols, group=_cta_group)

            # 5-warp barrier: the MMA consumer warp also waits on this id, so it
            # picks up the same tmem_ptr right after the allocator publishes it.
            prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

            tmem_ptr = prims.make_tmem_ptr(tmem_ptr_i32.load(), acc_dtype)
            tmem_raw_addr = tmem_ptr_i32.load()

            # Persistent loop: outer over work-tiles (one per acc stage), inner over
            # epilogue subtiles within each tile.
            acc_stage_idx = 0
            epi_stage_idx = 0
            while work_tile.is_valid_tile:
                current_acc_stage = acc_stage_idx
                acc_full_mbar_ptr_stage = acc_full_mbar_ptr.subview(current_acc_stage)
                acc_empty_mbar_ptr_stage = acc_empty_mbar_ptr.subview(current_acc_stage)
                current_full_phase_bit = acc_full_phase_bit

                acc_stage_idx += 1
                if acc_stage_idx == num_acc_stage:
                    acc_stage_idx = 0
                    acc_full_phase_bit = acc_full_phase_bit ^ 1

                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // (2 if use_2cta_instrs else 1),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Wait for MMA warp to commit acc_full for this stage.
                # try_wait_parity is one non-blocking attempt; loop until the MMA
                # warp's commit advances the phase.
                while not prims.mbarrier_try_wait_parity(
                    acc_full_mbar_ptr_stage, current_full_phase_bit, time_limit=10000000
                ):
                    pass
                # Order the MMA warp's accumulator writes before the TMEM reads below.
                prims.tcgen05_fence(prims.Tcgen05Fence.AFTER_THREAD_SYNC)

                # Per-stage TMEM column origin. Lower 16 bits of tmem_raw_addr is
                # the column id; upper 16 bits is the row id (always 0 for warp 0).
                base_col_id = (tmem_raw_addr & 0xFFFF) + (
                    current_acc_stage * mma_tiler[1]
                )

                # Per-tile output (im2col store) spatial coords. The 2CTA cluster
                # splits M (the NZPQ pixel axis) across the pair, so the spatial
                # coords carry cta_rank. Each CTA's accumulator holds its own M-row
                # band over the full N columns.
                m_off_cta = (
                    mma_tile_coord_mnl[0] * mma_tiler[0]
                    + (cta_rank_in_cluster % _atom_thr if use_2cta_instrs else 0)
                    * mma_tiler_per_cta_m
                )
                # Bare output pixels (col-major Q-fastest); the C descriptor uses
                # zero corners.
                n_out = m_off_cta // (Q_out * P_out * Z_out)
                rem_m = m_off_cta % (Q_out * P_out * Z_out)
                z_out = rem_m // (Q_out * P_out)
                rem_m = rem_m % (Q_out * P_out)
                p_out = rem_m // Q_out
                q_out = rem_m % Q_out
                # K-out channel base for this N-tile.
                k_off_base = mma_tile_coord_mnl[1] * mma_tiler[1]

                for subtile_idx in cutlass.range(subtile_cnt):
                    # Rotate through C SMEM stages so the previous TMA store can
                    # drain in parallel with the next t2r/r2s.
                    epi_stage_idx = (epi_stage_idx + 1) % num_c_stage

                    # TMEM -> RMEM: per-warp tcgen05.ld. The issuing warp's
                    # sub-partition (warp_idx % 4) selects the rows and, in the 2x2
                    # layout, the N half (ISA Layout B); the column origin advances
                    # by subtile_n only, and the store side applies the N-half offset.
                    tmem_subtile_ptr = prims.make_tmem_ptr_from_warp_row_col(
                        tmem_raw_addr,
                        warp_idx % 4,
                        base_col_id + subtile_idx * subtile_n,
                        cutlass.Float32,
                    )
                    # offset= is the 16x32bx2 column half-split, so pass it only for fp8.
                    t2r_rmem = prims.tcgen05_ld(
                        t2r_inst_shape,
                        tmem_subtile_ptr,
                        num=t2r_inst_repx,
                        offset=t2r_ld_offset
                        if cutlass.const_expr(use_fp8_simt_epi)
                        else None,
                    )
                    # The load is asynchronous; wait before the registers are consumed.
                    prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
                    # Apply the user-supplied epilogue_op (constexpr fn) on the FP32
                    # accumulator before casting to the output dtype (defaults to
                    # identity).
                    t2r_rmem = epilogue_op(t2r_rmem)

                    # RMEM -> SMEM. sC is a flat cutlass.Array (c_dtype elements);
                    # per-stage stride = _c_tile_rows * _epi_subtile_n elems
                    # (_c_tile_rows = 128 for store_swizzled, holding both cfgC
                    # N-bands; = m_per_cta for cfgB). Three paths, keyed on the
                    # datapath (constexpr):
                    smem_tile_base = sC.subview(
                        epi_stage_idx * (_c_tile_rows * _epi_subtile_n)
                    )
                    if cutlass.const_expr(use_fp8_simt_epi):
                        # fp8 cfgB SIMT store. This thread holds 32 contiguous
                        # channels of one M-row/half; final_offset is that row/half
                        # base in the C SMEM. Write them in vsize-wide store_swizzled
                        # chunks (fp8 vsize=16, so 2 stores).
                        for j in cutlass.range_constexpr(32 // vsize):
                            vec_f32 = t2r_rmem[j * vsize : j * vsize + vsize]
                            vec_io = vec_f32.to(c_dtype)
                            smem_thr_ptr = smem_tile_base.subview(
                                cutlass.Int32(final_offset) + j * vsize
                            )
                            smem_thr_ptr.data_ptr().store_swizzled(
                                vec_io,
                                alignment=16,
                                swizzle=_c_smem_swizzle(c_dtype, subtile_n),
                            )
                    elif cutlass.const_expr(not use_stmatrix_epi):
                        # 32x32b path: tcgen05.ld gives one contiguous row per thread;
                        # store_swizzled applies the C SMEM swizzle.
                        for i in cutlass.range_constexpr(t2r_inst_repx // 32):
                            for j in cutlass.range_constexpr(32 // vsize):
                                vec_f32 = t2r_rmem[
                                    i * 32 + j * vsize : i * 32 + j * vsize + vsize
                                ]
                                vec_io = vec_f32.to(c_dtype)
                                # offset by elements then take .data_ptr() for the
                                # cutlass.Pointer that exposes store_swizzled.
                                smem_thr_ptr = smem_tile_base.subview(
                                    (tidx + i * 128) * subtile_n + j * vsize
                                )
                                smem_thr_ptr.data_ptr().store_swizzled(
                                    vec_io,
                                    alignment=16,
                                    swizzle=_c_smem_swizzle(c_dtype, subtile_n),
                                )
                    else:
                        # per-CTA M=64 + 1cta: tcgen05.ld gives 2 interleaved rows/thread, the
                        # 8x8 fragment layout stmatrix takes. The C SMEM is SW32, so the
                        # destination address is XOR-permuted by hand.
                        _st_nelem = cutlass.const_expr(128 // c_dtype.width)
                        acc_f16 = cutlass.Array(c_dtype, _st_nelem, alignment=32)
                        acc_f16[0:_st_nelem] = t2r_rmem[0:_st_nelem].to(c_dtype)
                        smem_thr_ptr = smem_tile_base.subview(
                            cutlass.Int32(final_offset)
                        )
                        smem_ptr_raw = smem_thr_ptr.data_ptr()
                        smem_addr0 = cutlass.Int64(
                            llvm.ptrtoint(cutlass.Int64.mlir_type, smem_ptr_raw)
                        )
                        swz_addr0 = smem_addr0 ^ (
                            (smem_addr0 & _swz_mask) >> _swz_shift
                        )
                        dst0 = llvm.inttoptr(
                            llvm.PointerType.get(3), swz_addr0.ir_value()
                        )
                        tmp_i32_0 = cutlass.Array(
                            acc_f16.ir_value(),
                            dtype=cutlass.Int32,
                            shape=(4,),
                            addrspace=acc_f16.space,
                        )
                        regs0 = tmp_i32_0[0:4]
                        prims.stmatrix(
                            dst0,
                            [regs0[0], regs0[1], regs0[2], regs0[3]],
                            stmatrix_layout,
                            shape=stmatrix_shape,
                        )

                    # Make swizzled SMEM stores visible to the TMA proxy.
                    cute.arch.fence_view_async_shared()
                    prims.barrier_cta_sync(
                        epilog_sync_bar_id, thread_count=threads_in_epilogue
                    )

                    # Band-leader warps (warp_m_idx == 0, one per N-band) issue the im2col
                    # TMA store from one elected lane. Coord order is (k_off, q, p, z, n),
                    # the channel axis carrying the stride-1 dim; output spatial offsets
                    # live in the descriptor's zero corners. k_off advances by subtile_n
                    # per N-subtile.
                    if warp_m_idx == 0:
                        k_off = (
                            k_off_base
                            + warp_n_idx * (mma_tiler[1] // warp_n_count)
                            + subtile_idx * subtile_n
                        )
                        band_smem_base = smem_tile_base.subview(
                            warp_n_idx * mma_tiler_per_cta_m * subtile_n
                        )
                        if prims.elect_sync():
                            prims.cp_async_bulk_tensor_global_shared_cta(
                                tma_c_desc.get_ptr(),
                                band_smem_base,
                                (k_off, q_out, p_out, z_out, n_out),
                                mode=prims.TMAStoreMode.IM2COL,
                            )
                        # commit + wait run on the whole warp. At most num_c_stage-1
                        # groups stay inflight, so the next iteration reuses a drained
                        # SMEM stage.
                        prims.cp_async_bulk_commit_group()
                        prims.cp_async_bulk_wait_group(num_c_stage - 1, read=True)

                    prims.barrier_cta_sync(
                        epilog_sync_bar_id, thread_count=threads_in_epilogue
                    )

                # Order this warp's TMEM reads before the acc_empty release.
                prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
                # Signal acc_empty back to the group leader's mbarrier. In 2cta that mbar
                # lives in the even-rank leader's SMEM with arrive_count = 4 epi warps * 2
                # CTAs, and the leader rank is (rank // _atom_thr) * _atom_thr. In 1cta
                # _atom_thr=1, so this is the CTA's own rank and its own mbar.
                if prims.elect_sync():
                    leader_cta_rank = (cta_rank_in_cluster // _atom_thr) * _atom_thr
                    mbar_cluster_ptr = prims.mapa(
                        acc_empty_mbar_ptr_stage, leader_cta_rank
                    )
                    prims.mbarrier_arrive(
                        mbar_cluster_ptr,
                        count=1,
                        scope=prims.MemScope.CLUSTER,
                    )

                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # Drain the inflight TMA stores; a warp that issued none passes through.
            prims.cp_async_bulk_wait_group(0, read=True)

            # Order every epilogue warp's TMEM reads before the dealloc.
            prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
            prims.barrier_cta_sync(epilog_sync_bar_id, thread_count=threads_in_epilogue)

            # tcgen05 dealloc. In 2cta both CTAs of the group signal the pair partner's
            # tmem_dealloc_mbar through mapa (partner = rank ^ 1) and wait on their own
            # before freeing; in 1cta each CTA owns its TMEM.
            if warp_idx == allocator_warp_id:
                prims.tcgen05_relinquish_alloc_permit(group=_cta_group)

                if cutlass.const_expr(use_2cta_instrs):
                    peer_cta_rank = cute.arch.make_warp_uniform(cta_rank_in_cluster ^ 1)
                    peer_mbar = prims.mapa(tmem_dealloc_mbar_ptr, peer_cta_rank)
                    prims.mbarrier_arrive(
                        peer_mbar,
                        count=1,
                        scope=prims.MemScope.CLUSTER,
                    )

                    # Wait until peer also signalled, then physically free the TMEM.
                    # try_wait_parity is one non-blocking attempt; loop until the
                    # peer's arrive advances the phase.
                    while not prims.mbarrier_try_wait_parity(
                        tmem_dealloc_mbar_ptr, 0, time_limit=10000000
                    ):
                        pass

                prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols, group=_cta_group)

    def _check_cluster_problem_size(self, m: int, n: int) -> None:
        """Require enough CTA tiles along each dimension to form one cluster.

        The persistent scheduler tiles the problem into CTA tiles and groups them
        into clusters, so a cluster of (cluster_m, cluster_n) CTAs needs at least
        that many tiles along the matching dimension. A trailing partial tile
        still occupies a full CTA, so tiles are counted with a round-up.

        :raises testing.CantImplementError: If either dimension has too few tiles
        """
        cta_tile_m = self.mma_tiler_mn[0] // (2 if self.use_2cta_instrs else 1)
        cta_tile_n = self.mma_tiler_mn[1]
        m_tiles = -(-m // cta_tile_m)
        n_tiles = -(-n // cta_tile_n)
        cluster_m, cluster_n = self.cluster_shape_mn
        if m_tiles < cluster_m or n_tiles < cluster_n:
            raise testing.CantImplementError(
                f"CTA tile count ({m_tiles}, {n_tiles}) from problem ({m}, {n}) "
                f"with cta_tile=({cta_tile_m}, {cta_tile_n}) cannot form one "
                f"cluster {self.cluster_shape_mn}"
            )

    def can_implement(
        self,
        ncdhw: Tuple[int, int, int, int, int],
        k: int,
        ab_dtype: Type[Numeric],
        c_dtype: Type[Numeric],
    ) -> bool:
        """Run every host-side check and tell whether the configuration is supported.

        The checks go from the structural ones to the geometry-derived ones: dtypes,
        mma tiler and cluster shape, epilogue subtile, convolution geometry, tensor
        alignment, cluster problem size, im2col descriptor limits.
        """
        try:
            self._check_supported_dtypes(ab_dtype, ab_dtype, c_dtype)
            self._check_mma_tiler_and_cluster_shape()
            self._check_epilogue_subtile(c_dtype)
            check_conv_geometry(
                ncdhw,
                (k, *self.filter_trs),
                self.stride_dhw,
                self.upper_padding_dhw,
                self.lower_padding_dhw,
                self.dilation_dhw,
            )
            check_tensor_alignment(ncdhw[1], k, ab_dtype, c_dtype)
            z, p, q = compute_zpq(
                ncdhw[2:],
                self.filter_trs,
                self.stride_dhw,
                self.upper_padding_dhw,
                self.lower_padding_dhw,
                self.dilation_dhw,
            )
            self._check_cluster_problem_size(ncdhw[0] * z * p * q, k)
            check_im2col_descriptor_limits(
                self.filter_trs,
                self.upper_padding_dhw,
                self.lower_padding_dhw,
                self.stride_dhw,
                self.dilation_dhw,
            )
        except (testing.CantImplementError, ValueError):
            return False
        return True


# ---------------------------------------------------------------------------
# Compile factory — required by the kernel_lint / test_kernel_compiles contract.
# ---------------------------------------------------------------------------

_DEFAULT_NCDHW: Tuple[int, int, int, int, int] = (1, 1024, 1, 44, 80)
_DEFAULT_KTRS: Tuple[int, int, int, int] = (1024, 3, 3, 3)
_DEFAULT_UPPER_PAD: Tuple[int, int, int] = (0, 1, 1)
_DEFAULT_LOWER_PAD: Tuple[int, int, int] = (2, 1, 1)
_DEFAULT_STRIDE: Tuple[int, int, int] = (1, 1, 1)
_DEFAULT_DILATION: Tuple[int, int, int] = (1, 1, 1)
_DEFAULT_MMA_TILER: Tuple[int, int] = (256, 256)
_DEFAULT_CLUSTER: Tuple[int, int] = (2, 1)
_DEFAULT_DTYPE: Type[Numeric] = cutlass.Float16


@lru_cache(maxsize=None)
def compile(
    ncdhw: Tuple[int, int, int, int, int] = _DEFAULT_NCDHW,
    ktrs: Tuple[int, int, int, int] = _DEFAULT_KTRS,
    upper_pad_dhw: Tuple[int, int, int] = _DEFAULT_UPPER_PAD,
    lower_pad_dhw: Tuple[int, int, int] = _DEFAULT_LOWER_PAD,
    stride_dhw: Tuple[int, int, int] = _DEFAULT_STRIDE,
    dilation_dhw: Tuple[int, int, int] = _DEFAULT_DILATION,
    mma_tiler_mn: Tuple[int, int] = _DEFAULT_MMA_TILER,
    cluster_shape_mn: Tuple[int, int] = _DEFAULT_CLUSTER,
    use_2cta_instrs: bool = True,
    ab_dtype: Type[Numeric] = _DEFAULT_DTYPE,
    c_dtype: Type[Numeric] = _DEFAULT_DTYPE,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    max_active_clusters: Optional[int] = None,
    **_,
):  # noqa: A001
    """AOT-compile Sm100DenseImplicitGemmFprop.__call__ for the given conv config.

    Cached by the full config tuple; ``ncdhw``/``ktrs``/padding/stride
    must be concrete ints (im2col TMA descriptors bake DHW into the
    descriptor at compile time, so symbolic shapes are not supported).
    ``max_active_clusters`` sets the persistent grid size in clusters; by default
    the occupancy query of the current device supplies it.
    """
    from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream

    fprop_op = Sm100DenseImplicitGemmFprop(
        acc_dtype=acc_dtype,
        use_2cta_instrs=use_2cta_instrs,
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
        filter_trs=ktrs[1:],
        upper_padding_dhw=upper_pad_dhw,
        lower_padding_dhw=lower_pad_dhw,
        stride_dhw=stride_dhw,
        dilation_dhw=dilation_dhw,
    )
    # Every host-side check runs here, before any compile work.
    if not fprop_op.can_implement(ncdhw, ktrs[0], ab_dtype, c_dtype):
        raise testing.CantImplementError(
            f"Config not implementable: ncdhw={ncdhw}, ktrs={ktrs}, "
            f"stride={stride_dhw}, pad=({upper_pad_dhw}, {lower_pad_dhw}), "
            f"dilation={dilation_dhw}, mma_tiler={mma_tiler_mn}, "
            f"use_2cta_instrs={use_2cta_instrs}, cluster={cluster_shape_mn}, "
            f"dtypes=({ab_dtype}, {c_dtype})"
        )

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs
    Z, P, Q = compute_zpq(
        (D, H, W), (T, R, S), stride_dhw, upper_pad_dhw, lower_pad_dhw, dilation_dhw
    )
    # NDHWC + KTRSC + NZPQK fake tensors (channel/K-fastest, contiguous layout).
    fake_a = make_fake_compact_tensor(
        ab_dtype, (N, D, H, W, C), stride_order=(4, 3, 2, 1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        ab_dtype, (K, T, R, S, C), stride_order=(4, 3, 2, 1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        c_dtype, (N, Z, P, Q, K), stride_order=(4, 3, 2, 1, 0), assumed_align=16
    )

    if max_active_clusters is None:
        # The occupancy query runs on the current CUDA context.
        cutlass.cuda.initialize_cuda_context()
        max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
            cluster_shape_mn[0] * cluster_shape_mn[1]
        )

    return cute.compile(
        fprop_op,
        fake_a,
        fake_b,
        fake_c,
        max_active_clusters,
        make_fake_stream(),
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Verify — torch reference comparison via F.conv3d.
# ---------------------------------------------------------------------------


def _make_inputs(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    upper_pad_dhw: Tuple[int, int, int],
    lower_pad_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    *,
    zero_init: bool = False,
):
    """Allocate one config's device tensors and wrap them as CuTe views.

    Returns ``(cute_a, cute_b, cute_c, inp, flt, out)``: the three views the
    kernel takes, followed by the backing torch tensors a reference path reads.
    ``zero_init`` fills the operands with zeros, which a throughput sweep uses so
    that it does not pay for input generation on every spec.

    The views carry ``assumed_align=16`` and a dynamic layout on the contiguous
    channel axis (``leading_dim=4``), which is what the im2col TMA descriptors
    are built against.
    """
    import torch
    from cutlass.cute.runtime import from_dlpack
    from cutlass.torch import dtype as torch_dtype

    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs
    Z, P, Q = compute_zpq(
        (D, H, W), (T, R, S), stride_dhw, upper_pad_dhw, lower_pad_dhw, dilation_dhw
    )

    if zero_init:
        inp = torch.zeros((N, D, H, W, C), dtype=torch_dtype(ab_dtype), device="cuda")
        flt = torch.zeros((K, T, R, S, C), dtype=torch_dtype(ab_dtype), device="cuda")
    else:
        # Small randint values keep FP16 numerically stable.
        inp = torch.randint(
            -1, 2, (N, D, H, W, C), dtype=torch.float32, device="cuda"
        ).to(torch_dtype(ab_dtype))
        flt = torch.randint(
            -1, 2, (K, T, R, S, C), dtype=torch.float32, device="cuda"
        ).to(torch_dtype(ab_dtype))
    out = torch.zeros((N, Z, P, Q, K), dtype=torch_dtype(c_dtype), device="cuda")

    cute_a = from_dlpack(
        inp, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic(leading_dim=4)
    cute_b = from_dlpack(
        flt, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic(leading_dim=4)
    cute_c = from_dlpack(
        out, assumed_align=16, enable_tvm_ffi=True
    ).mark_layout_dynamic(leading_dim=4)
    return cute_a, cute_b, cute_c, inp, flt, out


def verify(
    ncdhw: Tuple[int, int, int, int, int] = _DEFAULT_NCDHW,
    ktrs: Tuple[int, int, int, int] = _DEFAULT_KTRS,
    upper_pad_dhw: Tuple[int, int, int] = _DEFAULT_UPPER_PAD,
    lower_pad_dhw: Tuple[int, int, int] = _DEFAULT_LOWER_PAD,
    stride_dhw: Tuple[int, int, int] = _DEFAULT_STRIDE,
    dilation_dhw: Tuple[int, int, int] = _DEFAULT_DILATION,
    mma_tiler_mn: Tuple[int, int] = _DEFAULT_MMA_TILER,
    cluster_shape_mn: Tuple[int, int] = _DEFAULT_CLUSTER,
    use_2cta_instrs: bool = True,
    ab_dtype: Type[Numeric] = _DEFAULT_DTYPE,
    c_dtype: Type[Numeric] = _DEFAULT_DTYPE,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    tolerance: float = 1e-2,
    max_active_clusters: Optional[int] = None,
    **_,
) -> None:
    """Compile, run on CUDA, compare against F.conv3d reference."""
    import torch
    import torch.nn.functional as F
    import cuda.bindings.driver as cuda
    from cutlass.torch import dtype as torch_dtype

    compiled_fn = compile(
        ncdhw=ncdhw,
        ktrs=ktrs,
        upper_pad_dhw=upper_pad_dhw,
        lower_pad_dhw=lower_pad_dhw,
        stride_dhw=stride_dhw,
        dilation_dhw=dilation_dhw,
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
        use_2cta_instrs=use_2cta_instrs,
        ab_dtype=ab_dtype,
        c_dtype=c_dtype,
        acc_dtype=acc_dtype,
        max_active_clusters=max_active_clusters,
    )
    print(
        f"Compile kernel (ncdhw={ncdhw}, ktrs={ktrs}, dtype={ab_dtype}) OK", flush=True
    )

    cute_a, cute_b, cute_c, inp, flt, out = _make_inputs(
        ncdhw,
        ktrs,
        upper_pad_dhw,
        lower_pad_dhw,
        stride_dhw,
        dilation_dhw,
        ab_dtype,
        c_dtype,
    )

    # A fresh non-default stream carries the kernel, and the reference read below
    # synchronizes that stream.
    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    # The inputs initialize on other streams; drain them so the kernel's stream
    # never reads a tensor mid-initialization.
    torch.cuda.synchronize()
    compiled_fn(cute_a, cute_b, cute_c, stream)
    torch_stream.synchronize()
    print(f"Run kernel (ncdhw={ncdhw}, ktrs={ktrs}) OK", flush=True)

    # F.conv3d expects NCDHW + KCTRS layout; transpose + manually pad for
    # asymmetric padding (F.pad takes pairs in reverse-dim order).
    inp_ncdhw = inp.permute(0, 4, 1, 2, 3).contiguous()
    if upper_pad_dhw != lower_pad_dhw:
        pad_arg = (
            lower_pad_dhw[2],
            upper_pad_dhw[2],
            lower_pad_dhw[1],
            upper_pad_dhw[1],
            lower_pad_dhw[0],
            upper_pad_dhw[0],
        )
        inp_padded = F.pad(inp_ncdhw, pad_arg)
        ref_pad = (0, 0, 0)
    else:
        inp_padded = inp_ncdhw
        ref_pad = upper_pad_dhw
    flt_kctrs = flt.permute(0, 4, 1, 2, 3).contiguous()
    # TF32 off: the cuDNN reference convolution runs in full FP32.
    with torch.backends.cudnn.flags(enabled=True, allow_tf32=False):
        ref = F.conv3d(
            inp_padded.to(torch.float32),
            flt_kctrs.to(torch.float32),
            stride=stride_dhw,
            padding=ref_pad,
            dilation=dilation_dhw,
        )
    ref_nzpqk = ref.permute(0, 2, 3, 4, 1).contiguous().to(torch_dtype(c_dtype))

    # Compare in fp32: torch.testing.assert_close refuses tolerance-based
    # comparison of low-dimensional float dtypes (fp8), and rounding both sides
    # to the same fp8 grid first keeps the tolerance meaningful for fp16/fp32.
    torch.testing.assert_close(
        out.to(torch.float32),
        ref_nzpqk.to(torch.float32),
        atol=tolerance,
        rtol=tolerance,
    )
    print(
        f"verify (ncdhw={ncdhw}, ktrs={ktrs}, dtype={ab_dtype}, "
        f"mma_tiler={mma_tiler_mn}, cluster={cluster_shape_mn}): PASS"
    )


# ---------------------------------------------------------------------------
# Perf-framework entry points. The profiler
# imports the perf test module, resolves these by name, and calls them directly
# under `--perf`; a config dict supplies the keyword arguments.
# ---------------------------------------------------------------------------


def _cfg_geometry(cfg: dict):
    """Pull the convolution geometry out of a perf config, defaulting omissions."""
    return (
        cfg["ncdhw"],
        cfg["ktrs"],
        cfg.get("upper_pad_dhw", _DEFAULT_UPPER_PAD),
        cfg.get("lower_pad_dhw", _DEFAULT_LOWER_PAD),
        cfg.get("stride_dhw", _DEFAULT_STRIDE),
        cfg.get("dilation_dhw", _DEFAULT_DILATION),
    )


def prepare_tensors(**cfg) -> dict:
    """Allocate one config's device operands for a throughput sweep.

    Zero-initialized, so a sweep does not pay for input generation on every
    spec; numerics are covered by :func:`verify`.
    """
    ncdhw, ktrs, upper, lower, stride, dilation = _cfg_geometry(cfg)
    cute_a, cute_b, cute_c, _inp, _flt, out = _make_inputs(
        ncdhw,
        ktrs,
        upper,
        lower,
        stride,
        dilation,
        cfg.get("ab_dtype", _DEFAULT_DTYPE),
        cfg.get("c_dtype", _DEFAULT_DTYPE),
        zero_init=True,
    )
    return {"a": cute_a, "b": cute_b, "c": cute_c, "out": out}


def run(executable, tensors: dict, stream) -> None:
    """Launch one kernel iteration on ``stream`` with the prepared operands."""
    executable(tensors["a"], tensors["b"], tensors["c"], stream)


def verify_output(tensors: dict, **cfg) -> None:
    """Check one config's numerics through the authoritative reference path.

    Delegates to :func:`verify`, which builds its own random operands and
    compares against ``F.conv3d``. The sweep's own operands are zero-filled and
    carry no reference, so they are not used here.
    """
    del tensors
    verify(**cfg)


def FLOPS_FORMULA(**cfg) -> float:
    """Implicit-GEMM FLOPs: 2 per MAC over M=N*Z*P*Q, N=K, K=C*T*R*S."""
    ncdhw, ktrs, upper, lower, stride, dilation = _cfg_geometry(cfg)
    n, c, d, h, w = ncdhw
    k, t, r, s = ktrs
    z, p, q = compute_zpq((d, h, w), (t, r, s), stride, upper, lower, dilation)
    return float(2 * (n * z * p * q) * k * (c * t * r * s))


def BYTES_FORMULA(**cfg) -> float:
    """Compulsory traffic: A and B read once, C written once.

    This is the roofline floor, not what the kernel issues: the im2col load
    re-reads each activation element once per filter tap it falls under, and that
    multiplier follows the padding and stride.
    """
    ncdhw, ktrs, upper, lower, stride, dilation = _cfg_geometry(cfg)
    n, c, d, h, w = ncdhw
    k, t, r, s = ktrs
    z, p, q = compute_zpq((d, h, w), (t, r, s), stride, upper, lower, dilation)
    ab_bytes = cfg.get("ab_dtype", _DEFAULT_DTYPE).width // 8
    c_bytes = cfg.get("c_dtype", _DEFAULT_DTYPE).width // 8
    return float(
        n * d * h * w * c * ab_bytes
        + k * t * r * s * c * ab_bytes
        + n * z * p * q * k * c_bytes
    )


# ---------------------------------------------------------------------------
# Entry point — argparse for ad-hoc test.
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="Implicit-GEMM fprop kernel — verify correctness",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--ncdhw", type=parse_comma_separated_ints, default=_DEFAULT_NCDHW)
    p.add_argument("--ktrs", type=parse_comma_separated_ints, default=_DEFAULT_KTRS)
    p.add_argument(
        "--upper_pad_dhw", type=parse_comma_separated_ints, default=_DEFAULT_UPPER_PAD
    )
    p.add_argument(
        "--lower_pad_dhw", type=parse_comma_separated_ints, default=_DEFAULT_LOWER_PAD
    )
    p.add_argument(
        "--stride_dhw", type=parse_comma_separated_ints, default=_DEFAULT_STRIDE
    )
    p.add_argument(
        "--dilation_dhw", type=parse_comma_separated_ints, default=_DEFAULT_DILATION
    )
    p.add_argument(
        "--mma_tiler_mn", type=parse_comma_separated_ints, default=_DEFAULT_MMA_TILER
    )
    p.add_argument(
        "--cluster_shape_mn", type=parse_comma_separated_ints, default=_DEFAULT_CLUSTER
    )
    p.add_argument("--use_2cta_instrs", action="store_true", default=True)
    p.add_argument("--ab_dtype", type=str, default="Float16")
    p.add_argument("--c_dtype", type=str, default="Float16")
    args = p.parse_args()

    _DTYPE_LOOKUP = {
        "Float16": cutlass.Float16,
        "BFloat16": cutlass.BFloat16,
        "Float32": cutlass.Float32,
        "Float8E4M3FN": cutlass.Float8E4M3FN,
        "Float8E5M2": cutlass.Float8E5M2,
    }

    verify(
        ncdhw=args.ncdhw,
        ktrs=args.ktrs,
        upper_pad_dhw=args.upper_pad_dhw,
        lower_pad_dhw=args.lower_pad_dhw,
        stride_dhw=args.stride_dhw,
        dilation_dhw=args.dilation_dhw,
        mma_tiler_mn=args.mma_tiler_mn,
        cluster_shape_mn=args.cluster_shape_mn,
        use_2cta_instrs=args.use_2cta_instrs,
        ab_dtype=_DTYPE_LOOKUP[args.ab_dtype],
        c_dtype=_DTYPE_LOOKUP[args.c_dtype],
    )
