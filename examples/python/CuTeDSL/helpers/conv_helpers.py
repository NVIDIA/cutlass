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

"""Helpers shared by the conv fprop kernels.

The kernels differ in architecture and in numeric format, and agree on the work that
surrounds a launch: admitting or rejecting a geometry, boxing its runtime scalars and
computing its fprop im2col descriptor parameters, keying and tracing the compile,
building the tensors, giving the GEMM-shaped views their unit batch mode and laying out
the block-scaled scale factors, deriving the epilogue operand types and activations,
sizing the shared-memory staging, computing the persistent launch grid and checking its
swizzle, and parsing the example command line.
"""

import argparse
from typing import Literal, Tuple, Type

import torch

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass import testing
from cutlass.cute.runtime import from_dlpack, make_fake_tensor

from helpers.dynamic_persistent_tile_scheduler import (
    ClcDynamicPersistentTileScheduler,
    ClcDynamicPersistentTileSchedulerParams,
)


def compute_zpq(
    dhw: Tuple[int, int, int],
    trs: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    upper_pad_dhw: Tuple[int, int, int],
    lower_pad_dhw: Tuple[int, int, int],
    dil_dhw: Tuple[int, int, int],
) -> Tuple[int, int, int]:
    """Compute output spatial dimensions Z, P, and Q with asymmetric padding."""
    D, H, W = dhw
    T, R, S = trs
    Sd, Sh, Sw = stride_dhw
    UpperPadD, UpperPadH, UpperPadW = upper_pad_dhw
    LowerPadD, LowerPadH, LowerPadW = lower_pad_dhw
    DilD, DilH, DilW = dil_dhw
    Z = ((D + UpperPadD + LowerPadD - DilD * (T - 1) - 1) // Sd) + 1
    P = ((H + UpperPadH + LowerPadH - DilH * (R - 1) - 1) // Sh) + 1
    Q = ((W + UpperPadW + LowerPadW - DilW * (S - 1) - 1) // Sw) + 1
    return Z, P, Q


def frontend_cache_token() -> bool:
    """Cache-key component for the active DSL frontend.

    ``BaseDSL.enable_pyir()`` flips a process-global mode, so a compiled artifact is
    only valid for the frontend that produced it. Any cache around a compile must key
    on this token.

    Scans every DSL singleton: ``enable_pyir()`` pushes the mode onto each
    preprocessor-carrying singleton and skips a preprocess=False one, and
    ``BaseDSL._get_dsl()`` returns the first-registered instance, which may be such
    a preprocess=False DSL. ``any`` over all singletons sees the mode whichever DSL
    registered first.
    """
    from cutlass.base_dsl.dsl import DSLSingletonMeta

    return any(
        bool(getattr(getattr(dsl, "envar", None), "enable_pyir", False))
        for dsl in DSLSingletonMeta._instances.values()
    )


def make_fake_conv_tensor(
    dtype: Type[cutlass.Numeric],
    rank: int,
    leading_dim: int,
    zero_stride_modes: Tuple[int, ...] = (),
) -> cute.Tensor:
    """Build the compile-time stand-in for one of the conv tensors.

    Every tensor a conv ``run()`` launches with carries dynamic extents and dynamic
    strides apart from the unit stride on ``leading_dim``, so a compile takes
    nothing from a tensor but its element type, its rank, that mode, and any mode a
    broadcast view pins to a literal zero. Compiling against the stand-in is what
    lets a compile be keyed on scalars: a ``cute.Tensor`` hashes by identity, and
    ``run()`` builds a fresh one every call.

    The extents are 32-bit symbolic values.

    :param dtype: Element type
    :param rank: Number of modes
    :param leading_dim: The one mode at unit stride
    :param zero_stride_modes: Modes a broadcast view pins to stride 0. The compiled
        module carries those as literals, so the stand-in has to carry them too
    :return: A fake tensor the compile can trace against
    """
    stride = tuple(
        1
        if mode == leading_dim
        else (0 if mode in zero_stride_modes else cute.sym_int64())
        for mode in range(rank)
    )
    return make_fake_tensor(
        dtype,
        tuple(cute.sym_int32() for _ in range(rank)),
        stride,
        assumed_align=16,
    )


def create_cute_tensor(
    source_f32_tensor: torch.Tensor,
    dtype: Type[cutlass.Numeric],
    leading_dim: int = None,
) -> Tuple[cute.Tensor, torch.Tensor]:
    """Create a dynamic-layout cute tensor of ``dtype`` holding the source values.

    The tensor is always marked dynamic-layout: every extent, and every stride
    other than the leading mode's, lowers to runtime SSA, so nothing about this
    tensor pins the compiled kernel to a problem size.

    :param source_f32_tensor: Source f32 tensor whose values the result carries
    :param dtype: Element type of the tensor to build
    :param leading_dim: Mode the dynamic layout keeps at stride 1
    :return: Tuple of cute tensor and the torch tensor backing its storage
    :raises ValueError: If ``leading_dim`` is not a stride-1 mode of the source, or
        if FP4 packed storage cannot hold the source's trailing extent
    """
    # A dynamic layout keeps exactly one mode at stride 1, and that mode has to be
    # one the allocation already makes contiguous. Check the request against the
    # source's own strides, so a value that disagrees is rejected here.
    if leading_dim is not None:
        strides = tuple(source_f32_tensor.stride())
        if not 0 <= leading_dim < len(strides) or strides[leading_dim] != 1:
            raise ValueError(
                f"leading_dim={leading_dim} is not a stride-1 mode of a tensor with "
                f"shape {tuple(source_f32_tensor.shape)} and strides {strides}"
            )

    # FP4 needs packed storage: 2 elements per byte. Allocate an int8 buffer with
    # the trailing extent halved, view it as the packed fp4 type, and convert the
    # f32 source into it, so the buffer is exactly the bytes the elements occupy.
    # Callers size their cold-L2 workspaces from that buffer's byte count.
    if dtype == cutlass.Float4E2M1FN:
        shape = tuple(source_f32_tensor.shape)
        if shape[-1] % 2 != 0:
            raise ValueError(f"FP4 packed storage requires even trailing dim: {shape}")
        packed_shape = shape[:-1] + (shape[-1] // 2,)
        storage_int8 = torch.empty(packed_shape, dtype=torch.int8, device="cuda")
        storage_view = storage_int8.view(dtype=torch.float4_e2m1fn_x2)
        cute_tensor = from_dlpack(storage_view, assumed_align=16)
        cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
        if source_f32_tensor.numel() > 0:
            f32_tensor = from_dlpack(source_f32_tensor, assumed_align=16)
            f32_tensor = f32_tensor.mark_layout_dynamic(leading_dim=leading_dim)
            cute.testing.convert(f32_tensor, cute_tensor)
        return cute_tensor, storage_view

    return cutlass_torch.cute_tensor_like(
        source_f32_tensor,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )


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

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param stride_dhw: Convolution stride per spatial dimension
    :param upper_pad_dhw: Upper padding per spatial dimension
    :param lower_pad_dhw: Lower padding per spatial dimension
    :param dilation_dhw: Dilation per spatial dimension
    :raises ValueError: If a shape or spatial tuple does not hold its expected
        number of values, or if an extent, stride, or dilation is not positive
    :raises testing.CantImplementError: If the geometry leaves no output extent
    """
    # Every tuple here is consumed positionally, so a wrong length either unpacks
    # into the wrong geometry fields or fails to unpack at all. Name the offending
    # argument up front.
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
    # Stride and dilation must be positive: the output extents divide by each
    # stride and the address reconstruction scales by each dilation. Padding is
    # unconstrained in sign: a negative value crops, and what bounds it is the
    # im2col corner encoding.
    for name, values in (
        ("ncdhw", ncdhw),
        ("ktrs", ktrs),
        ("stride_dhw", stride_dhw),
        ("dilation_dhw", dilation_dhw),
    ):
        if any(v <= 0 for v in values):
            raise ValueError(f"{name} must contain only positive values, got {values}")

    zpq = compute_zpq(
        ncdhw[2:],
        ktrs[1:],
        stride_dhw,
        upper_pad_dhw,
        lower_pad_dhw,
        dilation_dhw,
    )
    # An output extent of zero or below covers no CTA tile, so the grid has nothing
    # to schedule. The arguments that produce it are themselves well formed, which
    # makes this an unsupported geometry.
    if any(v <= 0 for v in zpq):
        raise testing.CantImplementError(f"Invalid output spatial shape: {zpq}")


def rt_conv_scalars(
    *,
    upper_pad: Tuple[int, int, int],
    lower_pad: Tuple[int, int, int],
    stride: Tuple[int, int, int],
    dil: Tuple[int, int, int],
) -> list:
    """Box the runtime conv geometry as cutlass.Int32 in the kernel's argument order.

    The order (upper pad, lower pad, stride, dilation, each D/H/W) must match the
    kernel __call__ signature; keyword-only parameters keep the four groups from
    being swapped at a call site.
    """
    return [
        cutlass.Int32(v) for group in (upper_pad, lower_pad, stride, dil) for v in group
    ]


def trace_conv_scalars() -> list:
    """Box a placeholder runtime conv geometry for the trace.

    The twelve pad / stride / dilation scalars reach the kernel as runtime
    cutlass.Int32, so their values never enter the compiled module and the caller
    re-boxes the real ones when it launches. A compile therefore traces with any
    legal set, which is what lets the geometry stay out of the compile signature.
    """
    return rt_conv_scalars(
        upper_pad=(0, 0, 0), lower_pad=(0, 0, 0), stride=(1, 1, 1), dil=(1, 1, 1)
    )


def prepare_fprop_tensors(
    ncdhw: Tuple[int, int, int, int, int],
    ktrs: Tuple[int, int, int, int],
    zpq: Tuple[int, int, int],
    ab_dtype: Type[cutlass.Numeric],
) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Prepare f32 tensors for 3D convolution.

    :param ncdhw: Input tensor shape (N, C, D, H, W)
    :param ktrs: Filter tensor shape components (K, T, R, S)
    :param zpq: Output spatial dimensions (Z, P, Q)
    :param ab_dtype: Data type for A/B input tensors
    :return: Tuple of input, filter, and output tensors
    """
    N, C, D, H, W = ncdhw
    K, T, R, S = ktrs
    Z, P, Q = zpq

    # Initialize with small random values for numerical stability. The range is
    # half-open, and an unsigned input type has no negative half to draw from.
    if ab_dtype == cutlass.Uint8:
        input_range = (0, 2)
    else:
        input_range = (-1, 2)
    input_tensor = torch.randint(
        input_range[0],
        input_range[1],
        (N, D, H, W, C),
        dtype=torch.float32,
        device="cuda",
    )
    filter_tensor = torch.randint(
        input_range[0],
        input_range[1],
        (K, T, R, S, C),
        dtype=torch.float32,
        device="cuda",
    )
    output_tensor = torch.empty((N, Z, P, Q, K), dtype=torch.float32, device="cuda")

    return input_tensor, filter_tensor, output_tensor


# The epilogue arithmetic runs in FP32 and narrows to the output type once, at the
# end. Its fused operands are typed independently of the output.
def bias_dtype_for_output(d_dtype: Type[cutlass.Numeric]) -> Type[cutlass.Numeric]:
    """Bias element type for an output type.

    A bias value is one number per output channel, read once and broadcast over
    every spatial position, so its storage is negligible next to the output
    tensor's while its precision reaches every element of the result. It is
    therefore stored in a type that does not bound the accuracy of the result: an
    integer output takes FP32, a float output of 16 bits or wider keeps its own
    type, and a narrower float output takes BFloat16.

    :param d_dtype: Output element type.
    :type d_dtype: Type[cutlass.Numeric]
    :return: Element type the bias tensor is built and staged with.
    :rtype: Type[cutlass.Numeric]
    """
    if d_dtype.is_integer:
        return cutlass.Float32
    if d_dtype.width >= 16:
        return d_dtype
    return cutlass.BFloat16


# Compile-time epilogue activations, folded into the cubin as a Constexpr op (one
# activation per cubin). Each entry pairs the device-side op applied to the FP32
# output fragment with the torch op used to build the reference.
EPILOGUE_ACTIVATIONS = {
    "identity": {
        "device": lambda x: x,
        "ref": lambda x: x,
    },
    "relu": {
        "device": lambda x: cute.where(x > 0, x, cute.full_like(x, 0)),
        "ref": torch.nn.functional.relu,
    },
}


def check_tensor_alignment(
    c: int,
    k: int,
    ab_dtype: Type[cutlass.Numeric],
    d_dtype: Type[cutlass.Numeric],
):
    """Check if the tensor alignment is valid for convolution.

    :param c: The number of input channels
    :type c: int
    :param k: The number of output channels
    :type k: int
    :param ab_dtype: The data type of the A and B operands
    :type ab_dtype: Type[cutlass.Numeric]
    :param d_dtype: The data type of the output tensor
    :type d_dtype: Type[cutlass.Numeric]
    """

    def check_contiguous_16B_alignment(dtype, num_major_elements):
        num_contiguous_elements = 16 * 8 // dtype.width
        return num_major_elements % num_contiguous_elements == 0

    if not check_contiguous_16B_alignment(
        d_dtype, k
    ) or not check_contiguous_16B_alignment(ab_dtype, c):
        raise testing.CantImplementError(
            f"Invalid tensor alignment: C = {c}, K = {k}, ab_dtype = {ab_dtype}, d_dtype = {d_dtype}"
        )


# A 3D convolution always builds a 5D im2col tensor map, and several of that map's
# fields are narrower than the convolution parameters feeding them. A geometry is
# admitted or rejected on the host, before a descriptor is built.
def check_im2col_descriptor_limits(
    filter_trs: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> None:
    """Rejects a convolution geometry the im2col tensor map cannot encode.

    :param filter_trs: Filter extents (T, R, S)
    :param upper_padding_dhw: Upper padding per spatial dimension
    :param lower_padding_dhw: Lower padding per spatial dimension
    :param stride_dhw: Convolution stride per spatial dimension
    :param dilation_dhw: Dilation per spatial dimension

    :raises testing.CantImplementError: If a field cannot hold its value
    """
    # The im2col tensor map holds these parameters in narrow hardware fields, so
    # the bounds below come from the descriptor. A corner is not the padding
    # itself -- the lower one is -lower_pad and the upper one
    # upper_pad - (filter - 1) * dilation -- so padding and dilation trade against
    # each other.
    corner_lo = -16
    corner_hi = 15
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
        lower_corner = -pad_lo
        upper_corner = pad_up - (flt - 1) * dil
        if not corner_lo <= lower_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} lower im2col corner is -lower_pad = "
                f"{lower_corner}, outside the [{corner_lo}, {corner_hi}] the "
                f"im2col descriptor allows; lower_pad_"
                f"{dim.lower()} must be at most {-corner_lo}"
            )
        if not corner_lo <= upper_corner <= corner_hi:
            raise testing.CantImplementError(
                f"{dim} upper im2col corner is upper_pad - (filter - 1) * "
                f"dilation = {pad_up} - ({flt} - 1) * {dil} = {upper_corner}, "
                f"outside the [{corner_lo}, {corner_hi}] the im2col descriptor "
                f"allows"
            )
        if stride > max_element_stride:
            raise testing.CantImplementError(
                f"stride_{dim.lower()}={stride} exceeds the element stride of "
                f"{max_element_stride} a tensor map allows"
            )
        # A filter offset is dilation * tap index, so the largest one a dimension
        # reaches is (filter - 1) * dilation. The descriptor bounds it separately,
        # so it is checked even when both corners are in range.
        max_filter_offset = 31
        filter_offset = (flt - 1) * dil
        if filter_offset > max_filter_offset:
            raise testing.CantImplementError(
                f"{dim} filter offset is (filter - 1) * dilation = ({flt} - 1) * "
                f"{dil} = {filter_offset}, past the {max_filter_offset} the "
                f"im2col descriptor allows for {dim}"
            )


def compute_fprop_im2col_params(
    filter_trs: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
) -> Tuple[
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
    Tuple[int, int, int],
]:
    """Compute the im2col TMA descriptor parameters for an fprop input load.

    Converts convolution parameters (DHW order) to TMA descriptor parameters (WHD
    order).

    :returns: (lower_corner_whd, upper_corner_whd, lower_padding_whd,
               upper_padding_whd, stride_whd, lower_srt, stride_srt)
    """
    pad_upper_d, pad_upper_h, pad_upper_w = upper_padding_dhw
    pad_lower_d, pad_lower_h, pad_lower_w = lower_padding_dhw
    stride_d, stride_h, stride_w = stride_dhw
    dilation_d, dilation_h, dilation_w = dilation_dhw
    filter_t, filter_r, filter_s = filter_trs

    lower_corner_whd = (-pad_lower_w, -pad_lower_h, -pad_lower_d)
    upper_corner_whd = (
        pad_upper_w - ((filter_s - 1) * dilation_w),
        pad_upper_h - ((filter_r - 1) * dilation_h),
        pad_upper_d - ((filter_t - 1) * dilation_d),
    )
    lower_padding_whd = (pad_lower_w, pad_lower_h, pad_lower_d)
    upper_padding_whd = (pad_upper_w, pad_upper_h, pad_upper_d)
    stride_whd = (stride_w, stride_h, stride_d)
    lower_srt = (0, 0, 0)
    stride_srt = (dilation_w, dilation_h, dilation_d)

    return (
        lower_corner_whd,
        upper_corner_whd,
        lower_padding_whd,
        upper_padding_whd,
        stride_whd,
        lower_srt,
        stride_srt,
    )


def add_dummy_batch_dimension(tensor: cute.Tensor) -> cute.Tensor:
    """Append a size-1 batch mode to a tensor's layout.

    The kernels address every GEMM operand with a trailing batch mode L: (M, K, L),
    (N, K, L) and (M, N, L). A convolution lowers to a single implicit GEMM, so L has
    extent 1.
    """
    new_layout = cute.append(tensor.layout, cute.make_layout(1))
    return cute.make_tensor(tensor.iterator, new_layout)


# Shared-memory alignments, each the minimum its buffer's accesses require:
# tensor buffers take the first, a staged row vector the second.
SMEM_BUFFER_ALIGN_BYTES = 128
SMEM_VECTOR_ALIGN_BYTES = 16


def solve_max_smem_stages(make_storage, capacity, *, primary, start, deepen=()):
    """Largest stage counts whose exact shared-memory footprint fits capacity.

    make_storage(**counts) returns the kernel's SharedStorage struct for a
    candidate stage assignment. Its size_in_bytes() is the very number
    smem.allocate() will place -- cute.struct computes every field offset and
    the tail padding at Python compile time -- and it is monotonically
    non-decreasing in each count: the struct reports its own footprint.

    The scan's starting point is extrapolated from two points: the bytes one
    extra stage costs are taken as size(floor+1) - size(floor),
    which already includes the stage-scaled barrier arrays and whatever padding
    that step moves. The extrapolation deliberately undershoots by one stage
    and only decides where the scan begins; the answer comes from the two loops
    after it, so the result does not depend on how well the extrapolation
    guessed. primary is raised first from its floor start[primary]; each name
    in deepen is then raised greedily, in order, with the earlier counts fixed.

    :param make_storage: Factory returning the SharedStorage struct for a
        candidate stage assignment, keyed by the names in ``start``.
    :param capacity: Shared memory capacity in bytes for one CTA.
    :param primary: Stage count maximized first.
    :param start: Starting value for every stage count; ``start[primary]`` is
        its floor.
    :param deepen: Stage counts raised greedily after the primary, in order.
    :return: dict mapping every name in ``start`` to its chosen count.
    :raises testing.CantImplementError: If the floor assignment does not fit.
    """
    counts = dict(start)

    def size(**kw):
        return make_storage(**{**counts, **kw}).size_in_bytes()

    for name in (primary, *deepen):
        floor = counts[name]
        base = size(**{name: floor})
        if base > capacity:
            raise testing.CantImplementError(
                f"stage floors {start} need {base} B of shared memory, more "
                f"than the {capacity} B capacity"
            )
        per_stage = size(**{name: floor + 1}) - base
        assert per_stage > 0, f"stage count {name!r} adds no shared memory"

        # Undershoot by one stage; this only picks the scan's starting point.
        counts[name] = floor + max(0, (capacity - base - per_stage) // per_stage)
        # Retreat if the estimate overshot, which padding jitter can cause.
        while counts[name] > floor and size() > capacity:
            counts[name] -= 1
        # Advance to the last count that fits.
        while size(**{name: counts[name] + 1}) <= capacity:
            counts[name] += 1

    assert make_storage(**counts).size_in_bytes() <= capacity
    return counts


def check_cluster_shape(
    use_2cta_instrs: bool,
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    swizzle_size: int,
    raster_along: Literal["m", "n"],
) -> None:
    """Check the fallback and preferred cluster shapes and their multiple relation.

    The rules here depend only on whether the MMA spans two CTAs and on the tile
    scheduling order, not on which MMA instruction runs, so every conv kernel takes
    them as they are. The legal tiler M/N sets do vary per instruction and are
    checked by each kernel.
    """
    # Skip illegal cluster shape
    if fallback_cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
        raise testing.CantImplementError(
            f"Invalid cluster shape M: {fallback_cluster_shape_mn[0]}"
        )
    # Skip invalid cluster shape (total cluster size must be <= 16)
    is_power_of_2 = lambda x: x > 0 and (x & (x - 1)) == 0
    if (
        fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1] > 16
        or fallback_cluster_shape_mn[0] <= 0
        or fallback_cluster_shape_mn[1] <= 0
        or not is_power_of_2(fallback_cluster_shape_mn[0])
        or not is_power_of_2(fallback_cluster_shape_mn[1])
    ):
        raise testing.CantImplementError(
            f"Invalid cluster shape: {fallback_cluster_shape_mn}"
        )

    # Validate preferred cluster shape
    if preferred_cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
        raise testing.CantImplementError(
            f"Invalid preferred cluster shape M: {preferred_cluster_shape_mn[0]}"
        )

    if (
        preferred_cluster_shape_mn[0] * preferred_cluster_shape_mn[1] > 16
        or preferred_cluster_shape_mn[0] <= 0
        or preferred_cluster_shape_mn[1] <= 0
        or not is_power_of_2(preferred_cluster_shape_mn[0])
        or not is_power_of_2(preferred_cluster_shape_mn[1])
    ):
        raise testing.CantImplementError(
            f"Invalid preferred cluster shape: {preferred_cluster_shape_mn}"
        )

    # Check preferred is multiple of fallback
    if (
        preferred_cluster_shape_mn[0] % fallback_cluster_shape_mn[0] != 0
        or preferred_cluster_shape_mn[1] % fallback_cluster_shape_mn[1] != 0
    ):
        raise testing.CantImplementError(
            f"Preferred cluster shape {preferred_cluster_shape_mn} must be "
            f"integer multiple of fallback cluster shape {fallback_cluster_shape_mn}"
        )
    # Swizzling and N-major rasterization hand out work by cluster index, so every
    # launched cluster must have the shape the grid was built with.
    shapes_differ = tuple(preferred_cluster_shape_mn) != tuple(
        fallback_cluster_shape_mn
    )
    if (swizzle_size > 1 or raster_along == "n") and shapes_differ:
        raise testing.CantImplementError(
            f"swizzle_size {swizzle_size} with raster_along {raster_along!r} requires "
            f"the fallback cluster shape {fallback_cluster_shape_mn} to equal the "
            f"preferred cluster shape {preferred_cluster_shape_mn}"
        )


def check_preferred_cluster_problem_size(
    m: int,
    n: int,
    use_2cta_instrs: bool,
    mma_tiler_mn: Tuple[int, int],
    preferred_cluster_shape_mn: Tuple[int, int],
) -> None:
    """Require enough CTA tiles along each dimension to form one preferred cluster.

    The persistent scheduler tiles the problem into CTA tiles and then groups
    them into clusters. A preferred cluster of (pref_m, pref_n) CTAs needs at
    least that many tiles along the matching dimension, so below that the
    preferred cluster shape is unusable and the config is rejected early. The
    check is per dimension: a total tile count large enough for the whole
    cluster fails if one dimension alone is short.

    A trailing partial tile occupies a full CTA in the grid, so the tile count
    along each dimension is the problem extent divided by the CTA tile, rounded up.

    :param m: Implicit-GEMM M dimension (N*Z*P*Q)
    :param n: Implicit-GEMM N dimension (K)
    :param use_2cta_instrs: Whether one MMA spans a CTA pair
    :param mma_tiler_mn: MMA tiler (M, N)
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)

    :raises testing.CantImplementError: If either dimension has too few tiles
    """
    # This runs before any setup, so the CTA tile comes from the MMA tiler.
    cta_tile_m = mma_tiler_mn[0] // (2 if use_2cta_instrs else 1)
    cta_tile_n = mma_tiler_mn[1]
    m_tiles = -(-m // cta_tile_m)
    n_tiles = -(-n // cta_tile_n)
    pref_m, pref_n = preferred_cluster_shape_mn
    if m_tiles < pref_m or n_tiles < pref_n:
        raise testing.CantImplementError(
            f"CTA tile count ({m_tiles}, {n_tiles}) from problem ({m}, {n}) with "
            f"cta_tile=({cta_tile_m}, {cta_tile_n}) cannot form one preferred "
            f"cluster preferred_cluster_shape_mn={preferred_cluster_shape_mn}"
        )


def check_swizzle_size(
    m: int,
    n: int,
    mma_tiler_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    preferred_cluster_shape_mn: Tuple[int, int],
    fallback_cluster_shape_mn: Tuple[int, int],
    swizzle_size: int,
    raster_along: str,
) -> None:
    """Check that swizzle_size fits the cluster count in the swizzled dimension.

    :param m: GEMM M dimension (N*Z*P*Q for convolution)
    :param n: GEMM N dimension (K for convolution)
    :param mma_tiler_mn: MMA tiler shape (M, N)
    :param use_2cta_instrs: Whether 2-CTA instructions are used
    :param preferred_cluster_shape_mn: Preferred cluster shape (M, N)
    :param fallback_cluster_shape_mn: Fallback cluster shape (M, N)
    :param swizzle_size: Swizzle size to validate
    :param raster_along: Rasterization order ("m" or "n")
    """
    if swizzle_size <= 1:
        return

    cta_v = 2 if use_2cta_instrs else 1
    cta_tile_m = mma_tiler_mn[0] // cta_v
    cta_tile_n = mma_tiler_mn[1]
    m_tiles = -(-m // cta_tile_m)
    n_tiles = -(-n // cta_tile_n)

    for cs in [preferred_cluster_shape_mn, fallback_cluster_shape_mn]:
        if raster_along == "m":
            nclusters = -(-n_tiles // cs[1])
        else:
            nclusters = -(-m_tiles // cs[0])
        if nclusters < swizzle_size:
            dim_name = "N" if raster_along == "m" else "M"
            raise testing.CantImplementError(
                f"swizzle_size ({swizzle_size}) exceeds the number of "
                f"{dim_name} clusters ({nclusters}) for cluster shape "
                f"{cs}. Use a smaller swizzle_size or increase the "
                f"{dim_name} dimension."
            )


def compute_grid(
    d: cute.Tensor,
    cta_tile_shape_mnk: Tuple[int, int, int],
    cluster_shape_mn: Tuple[int, int],
    swizzle_size: int,
    raster_along: Literal["m", "n"],
) -> Tuple[ClcDynamicPersistentTileSchedulerParams, Tuple[int, int, int]]:
    """Use persistent tile scheduler to compute the grid size for the output tensor D.

    :param d: The output tensor D
    :type d: cute.Tensor
    :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
    :type cta_tile_shape_mnk: tuple[int, int, int]
    :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
    :type cluster_shape_mn: tuple[int, int]
    :param swizzle_size: Swizzling size in the unit of cluster. 1 means no swizzle
    :type swizzle_size: int
    :param raster_along: Rasterization order of clusters, "m" or "n". Only used when
        swizzle_size > 1
    :type raster_along: str

    :return: A tuple containing:
        - tile_sched_params: Parameters for the persistent tile scheduler.
        - grid: Grid shape for kernel launch.
    :rtype: Tuple[ClcDynamicPersistentTileSchedulerParams, tuple[int, int, int]]
    """
    d_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
    gd = cute.zipped_divide(d, tiler=d_shape)
    num_ctas_mnl = gd[(0, (None, None, None))].shape
    cluster_shape_mnl = (*cluster_shape_mn, 1)

    tile_sched_params = ClcDynamicPersistentTileSchedulerParams(
        num_ctas_mnl, cluster_shape_mnl, swizzle_size, raster_along == "m"
    )
    grid = ClcDynamicPersistentTileScheduler.get_grid_shape(tile_sched_params)

    return tile_sched_params, grid


@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
) -> None:
    """Convert a scale factor tensor from MKL to MMA M(32x4xrest_m)xK(4xrest_k)xL."""
    # sf_mma_tensor has flatten shape (32, 4, rest_m, 4, rest_k, l)
    # group to ((32, 4, rest_m), (4, rest_k), l)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def sf_k_tile_channels(cta_tile_k: int, sf_vec_size: int) -> int:
    """Channels one SF K tile spans.

    The SF SMEM atom holds 4 scale-factor blocks along K, so it covers
    4 * sf_vec_size channels and cannot be staged in part. A narrower A/B K tile
    therefore stages a whole atom, and several A/B tiles then share one SF
    tile.
    """
    return max(cta_tile_k, 4 * sf_vec_size)


def sfb_per_position_channels(c: int, cta_tile_k: int, sf_vec_size: int) -> int:
    """Channels of SFB one filter position spans: C rounded up to whole SF K tiles.

    SFB runs channels and filter positions together in one flat K mode, so a K tile
    that does not divide C would straddle two positions; rounding each position out
    to whole SF K tiles puts every position on a tile boundary, which keeps a tile
    inside one position and lets the consumer address it by its flat index. The
    bound is the SF tile, the width of the TMA box: a C that a 64-channel A/B tile
    divides straddles two positions once a 128-channel SF chunk serves two of
    those tiles.

    The padded channels pair with the B channels past C, which the TMA zero-fills,
    so their scale factors never reach the result.
    """
    span = sf_k_tile_channels(cta_tile_k, sf_vec_size)
    return -(-c // span) * span


def create_scale_factor_tensor_swizzled(
    l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
) -> Tuple[torch.Tensor, cute.Tensor, torch.Tensor]:
    """SFB gmem tensor in the swizzled BlockScaledBasicChunk MMA layout (TMA
    load). Returns (f32 reference in MKL layout, cute tensor, backing storage)."""

    def ceil_div(a, b):
        return (a + b - 1) // b

    sf_k = ceil_div(k, sf_vec_size)
    ref_shape = (l, mn, sf_k)
    atom_m = (32, 4)
    atom_k = 4
    mma_shape = (
        l,
        ceil_div(mn, atom_m[0] * atom_m[1]),
        ceil_div(sf_k, atom_k),
        atom_m[0],
        atom_m[1],
        atom_k,
    )

    ref_permute_order = (1, 2, 0)
    mma_permute_order = (3, 4, 1, 5, 2, 0)

    ref_f32_cpu = cutlass_torch.create_and_permute_torch_tensor(
        ref_shape,
        torch.float32,
        permute_order=ref_permute_order,
        init_type=cutlass_torch.TensorInitType.RANDOM,
        init_config=cutlass_torch.RandomInitConfig(min_val=0, max_val=3),
    )
    # The MMA layout rounds mn up to a whole chunk and the conversion below writes
    # only the rows the problem owns, so zero-fill here: the rows past mn are staged
    # as allocated and belong to output channels past the real count.
    cute_f32_cpu = cutlass_torch.create_and_permute_torch_tensor(
        mma_shape,
        torch.float32,
        permute_order=mma_permute_order,
        init_type=cutlass_torch.TensorInitType.SCALAR,
        init_config=cutlass_torch.ScalarInitConfig(value=0.0),
    )

    cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
        from_dlpack(ref_f32_cpu),
        from_dlpack(cute_f32_cpu),
    )

    # Round-trip the reference scale factors through the storage dtype so the
    # reference dequant uses the exact values the kernel reads. E8M0 (MXFP8)
    # snaps every scale to a power of two, so an un-rounded f32 reference would
    # disagree with the kernel on every non-pow2 block. The cast is elementwise,
    # so it runs on the small per-block tensor ahead of the expansion.
    ref_f32_cpu = ref_f32_cpu.to(cutlass_torch.dtype(dtype)).to(torch.float32)

    # Expand to the dense, operand-sized reference on the device, where the
    # reference convolution runs. reshape makes memory contiguous.
    ref_f32_cpu = (
        ref_f32_cpu.cuda()
        .permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(*ref_permute_order)
    )
    ref_f32_cpu = ref_f32_cpu[:, :k, :]

    cute_f32 = cute_f32_cpu.cuda()

    cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
        cute_f32_cpu,
        dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    cute_tensor = cutlass_torch.convert_cute_tensor(
        cute_f32,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
    )
    return ref_f32_cpu, cute_tensor, torch_tensor


def create_scale_factor_tensor_unswizzled(
    l: int,
    mn: int,
    k: int,
    sf_vec_size: int,
    dtype: Type[cutlass.Numeric],
) -> Tuple[torch.Tensor, cute.Tensor, torch.Tensor]:
    """SFA gmem tensor in natural (M, ceil(C/vec), L) unswizzled layout, read by
    the cp.async producer. Returns (f32 reference in MKL layout, cute tensor,
    backing storage)."""

    def ceil_div(a, b):
        return (a + b - 1) // b

    # The M-direction stride is sf_k and the 4-byte cp.async that walks it needs a
    # multiple of 4 factors. k is C here, which can_implement already requires to be
    # a whole number of scale-factor atoms, so the allocation carries no tail: the
    # caller's buffer is exactly the factors the problem owns.
    sf_k = ceil_div(k, sf_vec_size)

    # Build the raw scale-factor tensor in PyTorch.
    sf_raw = torch.randint(0, 3, (l, mn, sf_k), dtype=torch.uint8).permute(1, 2, 0)
    torch_tensor = sf_raw.to(dtype=cutlass_torch.dtype(dtype)).cuda()

    cute_tensor = from_dlpack(torch_tensor, assumed_align=16)
    cute_tensor.element_type = dtype
    # Mark the SFA gmem tensor layout dynamic (leading dim = the C/SF axis) so
    # its stride lowers to runtime SSA. Without it the static stride is baked
    # into the cubin, tying the compiled kernel to one C (the device reads mSFA
    # with this stride).
    cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=1)

    # Decode the scale factors through the storage dtype so the reference matches
    # the values the kernel reads: E8M0 (MXFP8) has no exact zero (0 stores as the
    # smallest exponent, ~5.9e-39) and only represents powers of two, so the raw
    # uint8 -> f32 cast would disagree with the kernel on those blocks. E4M3 decodes
    # the small integers losslessly.
    ref_f32_cpu = (
        sf_raw.to(dtype=cutlass_torch.dtype(dtype))
        .float()
        .permute(2, 0, 1)
        .unsqueeze(-1)
        .expand(l, mn, sf_k, sf_vec_size)
        .reshape(l, mn, sf_k * sf_vec_size)
        .permute(1, 2, 0)
    )
    ref_f32_cpu = ref_f32_cpu[:, :k, :]

    return ref_f32_cpu, cute_tensor, torch_tensor


def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
    """Parse a comma-separated list of integers for an argparse option."""
    try:
        return tuple(int(x.strip()) for x in s.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        )
