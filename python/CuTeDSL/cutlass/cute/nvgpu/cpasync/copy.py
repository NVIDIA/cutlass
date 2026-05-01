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

import enum
from dataclasses import dataclass
from typing import Any, Optional, Type
from typing_extensions import deprecated

from cutlass.base_dsl.arch import Arch
from cutlass.cutlass_dsl import BaseDSL

import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir.dialects.nvvm import ReductionOp as ReductionOp
from cutlass._mlir import ir

from ...atom import CopyOp, Trait, make_atom
from ...typing import Int16, Int32, Int64, Pointer, Integer, Numeric
from ..common import OpError, LoadCacheMode as LoadCacheMode_

from ..tcgen05.mma import CtaGroup


####################################################################################################
#
# Asynchronous copies
#
####################################################################################################


@deprecated(
    "cute.nvgpu.cpasync.LoadCacheMode is deprecated, use cute.nvgpu.LoadCacheMode instead"
)
class LoadCacheMode(enum.Enum):
    """
    An enumeration for the possible cache modes of a non-bulk ``cp.async`` instruction.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#cache-operators>`__.
    """

    ALWAYS = _cute_nvgpu_ir.LoadCacheMode.always
    GLOBAL = _cute_nvgpu_ir.LoadCacheMode.global_
    STREAMING = _cute_nvgpu_ir.LoadCacheMode.streaming
    LAST_USE = _cute_nvgpu_ir.LoadCacheMode.last_use
    NONE = _cute_nvgpu_ir.LoadCacheMode.none

    def __str__(self) -> str:
        return f"{self.__class__.__name__}.{self.name}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}.{self.name}>"

    def _to_ir(self) -> _cute_nvgpu_ir.LoadCacheMode:
        return self.value


@dataclass(frozen=True)
class CopyG2SOp(CopyOp):
    """
    Non-bulk asynchronous GMEM to SMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-non-bulk-copy>`__.
    """

    cache_mode: LoadCacheMode_ = LoadCacheMode_.ALWAYS

    def __init__(
        self, cache_mode: LoadCacheMode_ | LoadCacheMode = LoadCacheMode_.ALWAYS
    ):
        super().__init__()
        object.__setattr__(
            self,
            "cache_mode",
            LoadCacheMode_(cache_mode.value)
            if isinstance(cache_mode, LoadCacheMode)
            else cache_mode,
        )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM copy Operation"
        if self.cache_mode != LoadCacheMode_.ALWAYS:
            res += f"\n  with cache mode = {self.cache_mode}"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyG2STrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", None)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy <= 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        # Verify that the user provided enum values
        if not isinstance(self.cache_mode, LoadCacheMode_):
            raise OpError(
                self,
                "expects the 'cache_mode' Op parameter to be a LoadCacheMode instance",
            )
        ty = _cute_nvgpu_ir.CopyAtomSIMTAsyncCopyType.get(
            copy_internal_type.mlir_type, self.cache_mode._to_ir(), num_bits_per_copy
        )
        return CopyG2STrait(make_atom(ty, loc=loc, ip=ip))


class CopyG2STrait(Trait):
    pass


####################################################################################################
#
# Bulk tensor copies a.k.a TMA copies
#
####################################################################################################

TMA_MBAR_PTR_FIELD_NAME = "tma_bar"
TMA_MCAST_MASK_FIELD_NAME = "mcast_mask"
TMA_DESC_PTR_FIELD_NAME = "tma_descriptor_ptr"
TMA_BYTE_MASK_FIELD_NAME = "byte_mask"
TMA_CTA_RANK_FIELD_NAME = "cta_rank"
TMA_CACHE_POLICY_FIELD_NAME = "cache_policy"


class TmaCopyOp(CopyOp):
    """
    Base class for all TMA copy operations.
    """

    pass


#
# TMA GMEM -> SMEM copies
#


@dataclass
class CopyBulkTensorTileG2SOp(TmaCopyOp):
    """
    Bulk tensor asynchronous GMEM to SMEM Copy Operation using the TMA unit.

    TMA copy operations are issued by a single thread within a warp, but the DSL **automatically handles this** by
    implicitly adding ``elect_one()`` around the copy operation.

    .. code-block:: python

        # CORRECT: TMA copy without elect_one
        cute.copy(
            tma_atom,
            gmem_tensor,  # TMA partition ensures single-thread automatically
            smem_tensor,
            tma_bar_ptr=barrier_ptr
        )

        # WRONG: Do NOT wrap in elect_one (can cause deadlock)
        with cute.arch.elect_one():  # INCORRECT
            cute.copy(tma_atom, gmem_tensor, smem_tensor, tma_bar_ptr=barrier_ptr)

    While the TMA copy itself does not need ``elect_one()``, barrier initialization and transaction byte setup **must** use ``elect_one()``:

    .. code-block:: python

        # Barrier setup requires elect_one
        with cute.arch.elect_one():
            cute.arch.mbarrier_init(barrier_ptr, arrival_count)
            cute.arch.mbarrier_expect_tx(barrier_ptr, num_tma_bytes)

        # TMA copy does NOT need elect_one
        cute.copy(tma_atom, gmem_tensor, smem_tensor, tma_bar_ptr=barrier_ptr)

    **PTX Programming Model**: In PTX, TMA operations (``cp.async.bulk.tensor``) must be issued
    by a single thread. The DSL automatically handles this.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.tile`` mode.

    .. seealso::
       - :func:`cute.arch.elect_one` - **NOT** needed for TMA copy, but needed for barrier setup
       - :func:`cute.arch.mbarrier_init` - Requires elect_one
       - :func:`cute.arch.mbarrier_expect_tx` - Requires elect_one
       - Tutorial example: ``examples/blackwell/tutorial_tma/tma_v0.py``
    """

    cta_group: CtaGroup = CtaGroup.ONE

    def __post_init__(self) -> None:
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self, "expects the 'cta_group' parameter to be a CtaGroup instance"
            )
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        if (self.cta_group == CtaGroup.TWO) and arch.major == Arch.sm_90.major:
            raise OpError(
                self,
                f"CTA group of 2 is tcgen05-specific and is not and is not compatible with {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM bulk tensor copy Operation"
        if self.cta_group == CtaGroup.TWO:
            res += "\n  CTA group = 2"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileG2SNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_tiled_tma_atom to obtain a copy Atom for TMA"
        )

    def _to_ir(self) -> _cute_nvgpu_ir.TiledTmaLoadEnum:
        if self.cta_group == CtaGroup.ONE:
            return _cute_nvgpu_ir.TiledTmaLoadEnum.sm_90
        elif self.cta_group == CtaGroup.TWO:
            return _cute_nvgpu_ir.TiledTmaLoadEnum.sm_100_2sm
        else:
            assert False, "unrecognized self.cta_group"


class CopyBulkTensorTileG2SNonExecTrait(Trait):
    # We allow kw args to be dropped so that the user can write common code for non-multicast
    # and multicast loads.

    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileG2STrait":
        return CopyBulkTensorTileG2STrait(self.unpack(loc=loc, ip=ip, **kwargs))

    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_bar_ptr: Optional[Pointer] = None,
        tma_desc_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.

        The non-multicast TMA load requires a `tma_bar_ptr` keyword argument to be provided when
        using `cute.copy`. `cache_policy` keyword argument to be provided to set the l2 cache eviction priority.
        Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(tma_bar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the tma_bar_ptr kw argument"
            )
        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(self.value, loc=loc, ip=ip)
        attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, tma_bar_ptr.value, loc=loc, ip=ip
        )
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_DESC_PTR_FIELD_NAME}>"
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return exec_value


class CopyBulkTensorTileG2STrait(Trait):
    pass


@dataclass
class CopyBulkTensorIm2ColG2SOp(TmaCopyOp):
    """
    Bulk tensor asynchrnous GMEM to SMEM Copy Operation using the TMA unit in im2col mode.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.im2col`` mode.
    """

    cta_group: CtaGroup = CtaGroup.ONE

    def __post_init__(self) -> None:
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self, "expects the 'cta_group' parameter to be a CtaGroup instance"
            )
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        if (self.cta_group == CtaGroup.TWO) and arch.major == Arch.sm_90.major:
            raise OpError(
                self,
                f"CTA group of 2 is tcgen05-specific and is not and is not compatible with {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM bulk tensor copy Operation"
        if self.cta_group == CtaGroup.TWO:
            res += "\n  CTA group = 2"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColG2SNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_im2col_tma_atom to obtain a copy Atom for TMA"
        )

    def _to_ir(self) -> _cute_nvgpu_ir.Im2ColTmaLoadEnum:
        if self.cta_group == CtaGroup.ONE:
            return _cute_nvgpu_ir.Im2ColTmaLoadEnum.sm_90
        elif self.cta_group == CtaGroup.TWO:
            return _cute_nvgpu_ir.Im2ColTmaLoadEnum.sm_100_2sm
        else:
            assert False, "unrecognized self.cta_group"


class CopyBulkTensorIm2ColG2SNonExecTrait(Trait):
    # We allow kw args to be dropped so that the user can write common code for non-multicast
    # and multicast loads.

    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColG2STrait":
        return CopyBulkTensorIm2ColG2STrait(self.unpack(loc=loc, ip=ip, **kwargs))

    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_bar_ptr: Optional[Pointer] = None,
        tma_desc_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.

        The non-multicast TMA load requires a `tma_bar_ptr` keyword argument to be provided when
        using `cute.copy`. `cache_policy` keyword argument to be provided to set the l2 cache eviction priority.
        Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(tma_bar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the tma_bar_ptr kw argument"
            )

        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(
            self.value,
            loc=loc,
            ip=ip,
        )
        attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, tma_bar_ptr.value, loc=loc, ip=ip
        )
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_DESC_PTR_FIELD_NAME}>"
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return exec_value


class CopyBulkTensorIm2ColG2STrait(Trait):
    pass


#
# TMA GMEM -> SMEM multicast copies
#


@dataclass
class CopyBulkTensorIm2ColG2SMulticastOp(TmaCopyOp):
    """
    Bulk tensor asynchrnous multicast GMEM to SMEM Copy Operation using the TMA unit.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.im2col`` mode.
    """

    cta_group: CtaGroup = CtaGroup.ONE

    def __post_init__(self) -> None:
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self, "expects the 'cta_group' parameter to be a CtaGroup instance"
            )
        # Arch verification
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        if (self.cta_group == CtaGroup.TWO) and arch.major == Arch.sm_90.major:
            raise OpError(
                self,
                f"CTA group of 2 is tcgen05-specific and is not and is not compatible with {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM bulk tensor multicast copy Operation"
        if self.cta_group == CtaGroup.TWO:
            res += "\n  CTA group = 2"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColG2SMulticastNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_im2col_tma_atom to obtain a copy Atom for TMA"
        )

    def _to_ir(self) -> _cute_nvgpu_ir.Im2ColTmaLoadEnum:
        if self.cta_group == CtaGroup.ONE:
            return _cute_nvgpu_ir.Im2ColTmaLoadEnum.sm_90_multicast
        elif self.cta_group == CtaGroup.TWO:
            return _cute_nvgpu_ir.Im2ColTmaLoadEnum.sm_100_2sm_multicast
        else:
            assert False, "unrecognized self.cta_group"


class CopyBulkTensorIm2ColG2SMulticastNonExecTrait(Trait):
    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColG2SMulticastTrait":
        return CopyBulkTensorIm2ColG2SMulticastTrait(
            self.unpack(loc=loc, ip=ip, **kwargs)
        )

    def unpack(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_bar_ptr: Optional[Pointer] = None,
        mcast_mask: Any = None,
        tma_desc_ptr: Any = None,
        cache_policy: Optional[Int64] = None,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.

        The multicast TMA load requires a `tma_bar_ptr`  and a `mcast_mask` keyword arguments to be
        provided when using `cute.copy`. `cache_policy` keyword argument to be provided to set the
        l2 cache eviction priority.
        """
        if not isinstance(tma_bar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the tma_bar_ptr kw argument"
            )
        if not isinstance(mcast_mask, Integer):
            raise ValueError(
                "expects a multicast mask to be provided via the mcast_mask kw argument"
            )

        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(
            self.value,
            loc=loc,
            ip=ip,
        )
        attr_str = "#cute_nvgpu.atom_copy_field_tmaload<mcast_mask>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, Int16(mcast_mask).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_DESC_PTR_FIELD_NAME}>"
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        # Set the tma_bar_ptr at last to ensure that the atom creation and setting
        # operations above can be moved outside the loop
        attr_str = "#cute_nvgpu.atom_copy_field_tmaload<tma_bar>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, tma_bar_ptr.value, loc=loc, ip=ip
        )
        return exec_value


class CopyBulkTensorIm2ColG2SMulticastTrait(Trait):
    pass


@dataclass
class CopyBulkTensorIm2ColS2GOp(TmaCopyOp):
    """
    Bulk tensor asynchrnous SMEM to GMEM Copy Operation using the TMA unit in im2col mode.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.im2col`` mode.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        return "cp.async SMEM -> GMEM bulk tensor copy Operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColS2GNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_im2col_tma_atom to obtain a copy Atom for TMA"
        )


class CopyBulkTensorIm2ColS2GNonExecTrait(Trait):
    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorIm2ColS2GTrait":
        return CopyBulkTensorIm2ColS2GTrait(self.unpack(loc=loc, ip=ip, **kwargs))

    def unpack(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_desc_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.
        """
        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(self.value, loc=loc, ip=ip)
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmastore<{TMA_DESC_PTR_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmastore<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return exec_value


class CopyBulkTensorIm2ColS2GTrait(Trait):
    pass


#
# TMA GMEM -> SMEM multicast copies
#


@dataclass
class CopyBulkTensorTileG2SMulticastOp(TmaCopyOp):
    """
    Bulk tensor asynchronous multicast GMEM to SMEM Copy Operation using the TMA unit.

    TMA multicast operations are issued by a single thread within a warp, but the DSL **automatically handles this** by
    implicitly adding ``elect_one()`` around the copy operation.

    .. code-block:: python

        # CORRECT: TMA multicast without elect_one
        cute.copy(
            tma_atom.with_(mcast_mask=cluster_mask),
            gmem_tensor,
            smem_tensor,
            tma_bar_ptr=barrier_ptr
        )

        # WRONG: Do NOT wrap in elect_one (can cause deadlock)
        with cute.arch.elect_one():  # INCORRECT
            cute.copy(tma_atom.with_(mcast_mask=mask), gmem_tensor, smem_tensor)

    **PTX Programming Model**: In PTX, TMA multicast operations (``cp.async.bulk.tensor.multicast``)
    must be issued by a single thread.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.tile`` mode.

    .. seealso::
       - :func:`cute.arch.elect_one` - **NOT** needed for TMA copy
       - :class:`CopyBulkTensorTileG2SOp` - Non-multicast TMA load
    """

    cta_group: CtaGroup = CtaGroup.ONE

    def __post_init__(self) -> None:
        if not isinstance(self.cta_group, CtaGroup):
            raise OpError(
                self, "expects the 'cta_group' parameter to be a CtaGroup instance"
            )
        # Arch verification
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
        if (self.cta_group == CtaGroup.TWO) and arch.major == Arch.sm_90.major:
            raise OpError(
                self,
                f"CTA group of 2 is tcgen05-specific and is not and is not compatible with {arch}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM bulk tensor multicast copy Operation"
        if self.cta_group == CtaGroup.TWO:
            res += "\n  CTA group = 2"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileG2SMulticastNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_tiled_tma_atom to obtain a copy Atom for TMA"
        )

    def _to_ir(self) -> _cute_nvgpu_ir.TiledTmaLoadEnum:
        if self.cta_group == CtaGroup.ONE:
            return _cute_nvgpu_ir.TiledTmaLoadEnum.sm_90_multicast
        elif self.cta_group == CtaGroup.TWO:
            return _cute_nvgpu_ir.TiledTmaLoadEnum.sm_100_2sm_multicast
        else:
            assert False, "unrecognized self.cta_group"


class CopyBulkTensorTileG2SMulticastNonExecTrait(Trait):
    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileG2SMulticastTrait":
        return CopyBulkTensorTileG2SMulticastTrait(
            self.unpack(loc=loc, ip=ip, **kwargs)
        )

    def unpack(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_bar_ptr: Optional[Pointer] = None,
        mcast_mask: Any = None,
        tma_desc_ptr: Any = None,
        cache_policy: Optional[Int64] = None,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.

        The multicast TMA load requires a `tma_bar_ptr`  and a `mcast_mask` keyword arguments to be
        provided when using `cute.copy`. `cache_policy` keyword argument to be provided to set the
        l2 cache eviction priority.
        """
        if not isinstance(tma_bar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the tma_bar_ptr kw argument"
            )
        if not isinstance(mcast_mask, Integer):
            raise ValueError(
                "expects a multicast mask to be provided via the mcast_mask kw argument"
            )
        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(self.value, loc=loc, ip=ip)
        attr_str = "#cute_nvgpu.atom_copy_field_tmaload<mcast_mask>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, Int16(mcast_mask).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_DESC_PTR_FIELD_NAME}>"
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmaload<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        # Set the tma_bar_ptr at last to ensure that the atom creation and setting
        # operations above can be moved outside the loop
        attr_str = "#cute_nvgpu.atom_copy_field_tmaload<tma_bar>"
        attr = ir.Attribute.parse(attr_str)
        exec_value = _cute_nvgpu_ir.atom_set_value(
            exec_value, attr, tma_bar_ptr.value, loc=loc, ip=ip
        )
        return exec_value


class CopyBulkTensorTileG2SMulticastTrait(Trait):
    pass


#
# TMA SMEM -> GMEM copies
#


@dataclass
class CopyBulkTensorTileS2GOp(TmaCopyOp):
    """
    Bulk tensor asynchronous SMEM to GMEM Copy Operation using the TMA unit.

    TMA store operations are issued by a single thread within a warp, but the DSL **automatically handles this** by
    implicitly adding ``elect_one()`` around the copy operation.

    .. code-block:: python

        # CORRECT: TMA store without elect_one
        cute.copy(
            tma_atom,
            smem_tensor,  # Source: shared memory
            gmem_tensor,  # Destination: global memory
        )

        # WRONG: Do NOT wrap in elect_one (causes deadlock)
        with cute.arch.elect_one():  # INCORRECT
            cute.copy(tma_atom, smem_tensor, gmem_tensor)

    **PTX Programming Model**: In PTX, TMA store operations must be issued by a single thread.
    The DSL automatically handles this.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk-tensor>`__.
    This Operation uses TMA in the ``.tile`` mode.

    .. seealso::
       - :func:`cute.arch.elect_one` - **NOT** needed for TMA store
       - :class:`CopyBulkTensorTileG2SOp` - TMA load operation
       - Tutorial example: ``examples/blackwell/tutorial_tma/tma_v0.py``
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        return "cp.async SMEM -> GMEM bulk tensor copy Operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileS2GNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_tiled_tma_atom to obtain a copy Atom for TMA"
        )


class CopyBulkTensorTileS2GNonExecTrait(Trait):
    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkTensorTileS2GTrait":
        return CopyBulkTensorTileS2GTrait(self.unpack(loc=loc, ip=ip, **kwargs))

    def unpack(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_desc_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.
        """
        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(self.value, loc=loc, ip=ip)
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmastore<{TMA_DESC_PTR_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )

            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmastore<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return exec_value


class CopyBulkTensorTileS2GTrait(Trait):
    pass


@dataclass
class CopyReduceBulkTensorTileS2GOp(TmaCopyOp):
    """
    Bulk tensor asynchronous SMEM to GMEM Reduction Operation using the TMA unit.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-reduce-async-bulk>`__.
    This Operation uses TMA in the ``.tile`` mode.
    """

    reduction_kind: ReductionOp = ReductionOp.ADD

    def __post_init__(self) -> None:
        # Arch verification
        arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        return "cp.async SMEM -> GMEM bulk tensor reduction Operation"

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyReduceBulkTensorTileS2GNonExecTrait":
        raise NotImplementedError(
            "Use cpasync.make_tiled_tma_atom to obtain a copy Atom for TMA"
        )

    def _to_ir(self) -> _cute_nvgpu_ir.ReductionKind:
        if self.reduction_kind == ReductionOp.ADD:
            return _cute_nvgpu_ir.ReductionKind.ADD
        elif self.reduction_kind == ReductionOp.MIN:
            return _cute_nvgpu_ir.ReductionKind.MIN
        elif self.reduction_kind == ReductionOp.MAX:
            return _cute_nvgpu_ir.ReductionKind.MAX
        elif self.reduction_kind == ReductionOp.INC:
            return _cute_nvgpu_ir.ReductionKind.INC
        elif self.reduction_kind == ReductionOp.DEC:
            return _cute_nvgpu_ir.ReductionKind.DEC
        elif self.reduction_kind == ReductionOp.AND:
            return _cute_nvgpu_ir.ReductionKind.AND
        elif self.reduction_kind == ReductionOp.OR:
            return _cute_nvgpu_ir.ReductionKind.OR
        elif self.reduction_kind == ReductionOp.XOR:
            return _cute_nvgpu_ir.ReductionKind.XOR
        else:
            assert False, "unrecognized self.reduction_kind"


class CopyReduceBulkTensorTileS2GNonExecTrait(Trait):
    def with_(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyReduceBulkTensorTileS2GTrait":
        return CopyReduceBulkTensorTileS2GTrait(self.unpack(loc=loc, ip=ip, **kwargs))

    def unpack(  # type: ignore[override]
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        tma_desc_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
    ) -> ir.Value:
        """
        Custom implementation of unpack for non-executable TMAs.
        """
        exec_value = _cute_nvgpu_ir.atom_make_exec_tma(self.value, loc=loc, ip=ip)
        if isinstance(tma_desc_ptr, Pointer):
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmareduce<{TMA_DESC_PTR_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, tma_desc_ptr.value, loc=loc, ip=ip
            )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_tmareduce<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            exec_value = _cute_nvgpu_ir.atom_set_value(
                exec_value, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return exec_value


class CopyReduceBulkTensorTileS2GTrait(Trait):
    pass


#
# Bulk GMEM -> SMEM copies
#


@dataclass(frozen=True)
class CopyBulkG2SOp(CopyOp):
    """
    Bulk copy asynchrnous GMEM to SMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM bulk copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkG2STrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomBulkCopyG2SType.get(
            copy_internal_type.mlir_type, num_bits_per_copy, False
        )
        return CopyBulkG2STrait(make_atom(ty, loc=loc, ip=ip))


class CopyBulkG2STrait(Trait):
    # We allow kw args to be dropped so that the user can write common code for non-multicast
    # and multicast loads.
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        mbar_ptr: Optional[Pointer] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for bulk copy load.

        The non-multicast bulk load requires a `mbar_ptr` keyword argument to be provided when
        using `cute.copy`. `cache_policy` keyword argument to be provided to set the l2 cache eviction priority.
        Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(mbar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the mbar_ptr kw argument"
            )
        attr_str = f"#cute_nvgpu.atom_copy_field_bulkg2s<{TMA_MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, mbar_ptr.value, loc=loc, ip=ip
        )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_bulkg2s<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            val = _cute_nvgpu_ir.atom_set_value(
                val, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return val


#
# Bulk GMEM -> SMEM Multicast copies
#


@dataclass(frozen=True)
class CopyBulkG2SMulticastOp(CopyOp):
    """
    Bulk multicast copy asynchrnous GMEM to SMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async GMEM -> SMEM multicast bulk copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkG2SMulticastTrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomBulkCopyG2SType.get(
            copy_internal_type.mlir_type, num_bits_per_copy, True
        )
        return CopyBulkG2SMulticastTrait(make_atom(ty, loc=loc, ip=ip))


class CopyBulkG2SMulticastTrait(Trait):
    # We allow kw args to be dropped so that the user can write common code for non-multicast
    # and multicast loads.
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        mbar_ptr: Optional[Pointer] = None,
        mcast_mask: Optional[Integer] = None,
        cache_policy: Optional[Int64] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for bulk copy load.

        The non-multicast bulk load requires a `mbar_ptr` keyword argument to be provided when
        using `cute.copy`. Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(mbar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the mbar_ptr kw argument"
            )
        if not isinstance(mcast_mask, Integer):
            raise ValueError(
                "expects a multicast mask to be provided via the mcast_mask kw argument"
            )
        attr_str = f"#cute_nvgpu.atom_copy_field_bulkg2s<{TMA_MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, mbar_ptr.value, loc=loc, ip=ip
        )
        attr_str = f"#cute_nvgpu.atom_copy_field_bulkg2s<{TMA_MCAST_MASK_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            val, attr, Int16(mcast_mask).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        if cache_policy is not None:
            if not isinstance(cache_policy, Int64):
                raise ValueError(
                    "expects `Int64` value to be provided via the cache_policy kw argument"
                )
            attr_str = (
                f"#cute_nvgpu.atom_copy_field_bulkg2s<{TMA_CACHE_POLICY_FIELD_NAME}>"
            )
            attr = ir.Attribute.parse(attr_str)
            val = _cute_nvgpu_ir.atom_set_value(
                val, attr, cache_policy.ir_value(), loc=loc, ip=ip
            )
        return val


#
# Bulk SMEM -> GMEM copies
#


@dataclass(frozen=True)
class CopyBulkS2GOp(CopyOp):
    """
    Bulk copy asynchrnous SMEM to GMEM Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async SMEM -> GMEM bulk copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkS2GTrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomBulkCopyS2GType.get(
            copy_internal_type.mlir_type, num_bits_per_copy, False
        )
        return CopyBulkS2GTrait(make_atom(ty, loc=loc, ip=ip))


class CopyBulkS2GTrait(Trait):
    pass


#
# Bulk SMEM -> GMEM mask copies
#


@dataclass(frozen=True)
class CopyBulkS2GByteMaskOp(CopyOp):
    """
    Bulk copy asynchrnous SMEM to GMEM Copy Operation with mask.
    The i-th bit in the 16-bit wide byteMask operand specifies whether
    the i-th byte of each 16-byte wide chunk of source data is copied to the destination.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_100:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_100.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async SMEM -> GMEM bulk copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkS2GByteMaskTrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomBulkCopyS2GType.get(
            copy_internal_type.mlir_type, num_bits_per_copy, True
        )
        return CopyBulkS2GByteMaskTrait(make_atom(ty, loc=loc, ip=ip))


class CopyBulkS2GByteMaskTrait(Trait):
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        byte_mask: Any = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for bulk copy store with mask.

        The bulk store with mask requires `byte_mask` keyword argument to be provided when
        using `copy`. Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(byte_mask, Integer):
            raise ValueError(
                "expects a byte mask to be provided via the byte_mask kw argument"
            )
        # Support for .cp_mask qualifier requires sm_100 or higher.
        attr_str = f"#cute_nvgpu.atom_copy_field_bulks2g<{TMA_BYTE_MASK_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value,
            attr,
            Int16(byte_mask).ir_value(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        return val


#
# Bulk SMEM CTA to Cluster copies
#


@dataclass(frozen=True)
class CopyBulkS2SOp(CopyOp):
    """
    Bulk copy asynchrnous SMEM CTA to Cluster Copy Operation.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#data-movement-and-conversion-instructions-cp-async-bulk>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "cp.async CTA -> Cluster bulk copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyBulkS2STrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is positive "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomBulkCopyS2SType.get(
            copy_internal_type.mlir_type, num_bits_per_copy
        )
        return CopyBulkS2STrait(make_atom(ty, loc=loc, ip=ip))


class CopyBulkS2STrait(Trait):
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        mbar_ptr: Optional[Pointer] = None,
        cta_rank: Optional[Integer] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for bulk copy cta to cluster.

        The bulk cta to cluster copy requires a `mbar_ptr` and `cta_rank` keyword argument to be provided
        when using `cute.copy`. Any other kw arguments will be ignored instead of triggering an error.
        """

        if not isinstance(mbar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the mbar_ptr kw argument"
            )
        if not isinstance(cta_rank, Integer):
            raise ValueError(
                "expects a cta rank of int32 to be provided via the cta_rank kw argument"
            )
        attr_str = f"#cute_nvgpu.atom_copy_field_bulks2s<{TMA_MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value, attr, mbar_ptr.value, loc=loc, ip=ip
        )
        attr_str = f"#cute_nvgpu.atom_copy_field_bulks2s<{TMA_CTA_RANK_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            val, attr, Int32(cta_rank).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )
        return val


####################################################################################################
#
# Aynchronous distributed shared memory stores
#
####################################################################################################

MBAR_PTR_FIELD_NAME = "mbar_ptr"


@dataclass(frozen=True)
class CopyDsmemStoreOp(CopyOp):
    """
    Asynchronous Store operation to DSMEM with explicit synchronization.

    See the `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#data-movement-and-conversion-instructions-st-async>`__.
    """

    def __post_init__(self) -> None:
        # Arch verification
        arch: Arch = BaseDSL._get_dsl().get_arch_enum()
        if not arch >= Arch.sm_90:
            raise OpError(
                self,
                f"expects arch to be at least {Arch.sm_90.name}, but got {arch.name}",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )

    def __str__(self) -> str:
        res = "st.async RMEM -> DSMEM copy Operation"
        return res

    def _make_trait(
        self,
        copy_internal_type: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        **kwargs: Any,
    ) -> "CopyDsmemStoreTrait":
        num_bits_per_copy = kwargs.get("num_bits_per_copy", 0)
        if not isinstance(num_bits_per_copy, int) or (num_bits_per_copy < 0):
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument of type int that is non-negative "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        if num_bits_per_copy not in [0, 32, 64, 128]:
            raise ValueError(
                "expects a 'num_bits_per_copy' kw argument that is one of {0, 32, 64, 128} "
                f"when creating a copy Atom for {self.__class__.__name__}"
            )
        ty = _cute_nvgpu_ir.CopyAtomDsmemStoreType.get(
            copy_internal_type.mlir_type, num_bits_per_copy
        )
        return CopyDsmemStoreTrait(make_atom(ty, loc=loc, ip=ip))


class CopyDsmemStoreTrait(Trait):
    def unpack(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
        mbar_ptr: Optional[Pointer] = None,
        **kwargs: Any,
    ) -> ir.Value:
        """
        Custom implementation of unpack for dsmem async copy.

        The dsmem async copy requires `mbar_ptr` keyword argument to be provided when using `cute.copy`.
        Any other kw arguments will be ignored instead of triggering an error.
        """
        if not isinstance(mbar_ptr, Pointer):
            raise ValueError(
                "expects a pointer to an mbarrier to be provided via the mbar_ptr kw argument",
            )
        attr_str = f"#cute_nvgpu.atom_copy_field_dsmem_store<{MBAR_PTR_FIELD_NAME}>"
        attr = ir.Attribute.parse(attr_str)
        val = _cute_nvgpu_ir.atom_set_value(
            self.value,
            attr,
            mbar_ptr.value,
            loc=loc,
            ip=ip,
        )
        return val


