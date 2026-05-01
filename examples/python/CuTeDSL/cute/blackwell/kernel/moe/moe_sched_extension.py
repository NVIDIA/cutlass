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

"""
MoE Scheduler Extension.

Bridges the MoE tile scheduler (MoEStaticPersistentTileScheduler) with tensor-level
domain conversion and TMA descriptor selection. This is the "glue" layer between:

- Scheduler: produces MoEWorkTileInfo (expert_idx, tile_m, tile_n, k_tile_cnt)
- OnlineTensormapDescCreator: builds/retrieves TMA descriptors from workspace
- Kernel: orchestrates everything

Different kernel types (grouped_mm, scaled_grouped_mm, etc.) provide their own
MoESchedExtension subclass with kernel-specific domain conversion logic.

Key design principles:
- Unified interface: get_gmem_tensor() for all tensor types
- Free implementation: no role-based templates, each subclass writes its own logic
- Composable utilities: compute_expert_token_range, rewrite_tensor_shape, etc.
  are available as tools but not mandatory

Architecture:

    Scheduler ──(produces)──> MoEWorkTileInfo
                                    │
                           expert_idx, tile_m, tile_n, k_cnt
                                    │
                                    v
    Extension ──(uses)──> OnlineTensormapDescCreator
        │                         │
        │  get_gmem_tensor()      │  get_desc_ptr()
        │  prefetch_for_expert()  │  construct_and_write()
        │                         │
        └── internal calls ───────┘

    Kernel (caller): the only place that knows all three exist
"""

from abc import ABC, abstractmethod
from typing import Literal, Tuple, Union

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import Pointer
from cutlass.cutlass_dsl import Int32

from dataclasses import dataclass

from cutlass.utils.blockscaled_layout import tile_atom_to_shape_SF
from blackwell.kernel.moe.moe_utils import (
    OnlineTensormapDescCreator,
    tensormap_ptr_for_copy,
    compute_expert_token_range,
    rewrite_tensor_shape,
    prefetch_tma_descriptor,
)
from blackwell.kernel.moe.moe_persistent_scheduler import MoEWorkTileInfo


@dataclass(frozen=True)
class MoESchedExtension(ABC):
    """
    Abstract base class for MoE scheduler extensions.

    Bridges MoEWorkTileInfo with tensor-level domain conversion and TMA
    descriptor selection. Each kernel type (grouped_mm, scaled_grouped_mm, etc.)
    provides its own subclass with kernel-specific logic.

    The extension:
    - Holds a reference to an OnlineTensormapDescCreator for expert-wise desc retrieval
    - Implements get_gmem_tensor() to convert MoE-view tensors to per-expert tensors
    - Implements prefetch_for_expert() to prefetch expert-wise TMA descriptors

    Subclasses are free to add any additional attributes in __init__ (scenario,
    codegen configs, etc.) and implement get_gmem_tensor with arbitrary logic
    per tensor_name. No role-based templates or rigid patterns are imposed.

    Usage in kernel (caller):
        ext = ConcreteSchedExtension(tensormap_ctor, scenario=...)

        while work_tile_info.is_valid_tile:
            real_a, desc_a = ext.get_gmem_tensor("a", tma_tensor_a, offs, work_tile_info)
            real_b, desc_b = ext.get_gmem_tensor("b", tma_tensor_b, offs, work_tile_info)
            # Use real_a, desc_a in cute.copy ...
    """

    def __init__(self, tensormap_ctor: OnlineTensormapDescCreator):
        super().__init__()
        self.tensormap_ctor = tensormap_ctor

    @abstractmethod
    def get_gmem_tensor(
        self,
        tensor_name: str,
        gmem_tensor_in_moe_view: cute.Tensor,
        offs: Union[cute.Tensor, Tuple[cute.Tensor, cute.Tensor]],
        work_tile_info: MoEWorkTileInfo,
    ) -> Tuple[cute.Tensor, "Pointer | None"]:
        """
        Convert an MoE-view tensor to the real per-expert tensor for the
        current work tile, and return the appropriate TMA descriptor pointer.

        The MoE-view tensor uses "fake" GEMM domain dimensions that span all
        experts (e.g., fake_m = tokens_sum). This method slices/offsets it
        to the current expert's actual region.

        :param tensor_name: Identifies which tensor (e.g., "a", "b", "c", "sfa")
        :param gmem_tensor_in_moe_view: Tensor in fake GEMM MNKL domain
        :param offs: Either a single cumsum tensor (experts,), or a tuple of
                     (offs_token, offs_padded) where offs_padded provides
                     padded offsets for scale-factor domain conversion.
        :param work_tile_info: Current work tile from the scheduler
        :return: (real_tensor, tma_desc_ptr_or_none)
                 - real_tensor: domain-offset and shape-rewritten tensor for this expert
                 - tma_desc_ptr: expert-wise desc ptr (already converted for cute.copy),
                   or None if the caller should use the global TMA descriptor
        """
        ...

    @abstractmethod
    def prefetch_for_expert(self, expert_idx: Int32) -> None:
        """
        Prefetch expert-wise TMA descriptors for the given expert.

        Called when the scheduler advances to a new expert, allowing the TMA
        descriptor cache to be warmed up before the descriptors are needed.

        :param expert_idx: Index of the expert whose descriptors to prefetch
        """
        ...


# =============================================================================
# Grouped MM Extension
# =============================================================================


class GroupedMmSchedExtension(MoESchedExtension):
    """
    MoE scheduler extension for grouped_mm: handles tensors a, b, c.

    Domain conversion logic per scenario:

    2Dx3D:
        A: (fake_m, k, 1)  -> offset fake_m by token_offset, global desc
        B: (n, k, fake_l)  -> offset fake_l by expert_idx, global desc
        C: (fake_m, n, 1)  -> rewrite shape only, expert-wise desc

    2Dx2D:
        A: (m, fake_k, 1)  -> rewrite shape only, expert-wise desc
        B: (n, fake_k, 1)  -> rewrite shape only, expert-wise desc
        C: (m, n, fake_l)  -> offset fake_l by expert_idx, global desc
    """

    def __init__(
        self,
        scenario: Literal["2Dx3D", "2Dx2D"],
        tensormap_ctor: OnlineTensormapDescCreator,
    ):
        super().__init__(tensormap_ctor)
        self.scenario = scenario

    @cute.jit
    def get_gmem_tensor(
        self,
        tensor_name: str,
        gmem_tensor_in_moe_view: cute.Tensor,
        offs: cute.Tensor,
        work_tile_info: MoEWorkTileInfo,
    ):
        expert_idx = work_tile_info.expert_idx
        token_offset, tokens_i = compute_expert_token_range(offs, expert_idx)

        shape = gmem_tensor_in_moe_view.shape
        c1 = cutlass.Int32(1)

        if cutlass.const_expr(self.scenario == "2Dx3D"):
            if cutlass.const_expr(tensor_name == "a"):
                # A: (fake_m, k, 1) -> offset fake_m, global desc
                real = cute.domain_offset((token_offset, 0, 0), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (tokens_i, shape[1], c1))  # type: ignore[index]
                return (real, None)
            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, k, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset((0, 0, expert_idx), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))  # type: ignore[index]
                return (real, None)
            elif cutlass.const_expr(tensor_name == "c"):
                # C: (fake_m, n, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (tokens_i, shape[1], c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("c", expert_idx)
                )
                return (real, desc)

        elif cutlass.const_expr(self.scenario == "2Dx2D"):
            if cutlass.const_expr(tensor_name == "a"):
                # A: (m, fake_k, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (shape[0], tokens_i, c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("a", expert_idx)
                )
                return (real, desc)
            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, fake_k, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (shape[0], tokens_i, c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("b", expert_idx)
                )
                return (real, desc)
            elif cutlass.const_expr(tensor_name == "c"):
                # C: (m, n, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset((0, 0, expert_idx), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))  # type: ignore[index]
                return (real, None)
        
        raise ValueError("Invalid scenario or GEMM tensor name.")

    @cute.jit
    def prefetch_for_expert(self, expert_idx: Int32) -> None:
        if cutlass.const_expr(self.scenario == "2Dx3D"):
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("c", expert_idx))
        elif cutlass.const_expr(self.scenario == "2Dx2D"):
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("a", expert_idx))
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("b", expert_idx))
        else:
            raise ValueError("Invalid scenario.")
        


# =============================================================================
# Scaled Grouped MM Extension (block-scaled MoE)
# =============================================================================


class ScaledGroupedMmSchedExtension(MoESchedExtension):
    """
    MoE scheduler extension for scaled_grouped_mm: handles a, b, c, sfa, sfb.

    Extends GroupedMmSchedExtension with scale-factor tensor support.
    SFA/SFB are passed as flat GEMM-domain tensors and atom-tiled per expert
    via tile_atom_to_shape_SF.

    The offs parameter is always a tuple (offs_token, offs_padded):
    - offs_token: cumsum offsets in data (activation) domain
    - offs_padded: cumsum offsets in scale-factor domain (padded to atom granularity)

    sf_vec_size is obtained from self.tensormap_ctor.sf_vec_size.

    Domain conversion logic per scenario:

    2Dx3D:
        A:   (fake_m, k, 1)               -> offset fake_m by token_offset, global desc
        B:   (n, k, fake_l)               -> offset fake_l by expert_idx, global desc
        C:   (fake_m, n, 1)               -> rewrite shape, expert-wise desc
        SFA: (fake_m_pad, k_pad, 1)       -> offset fake_m_pad by padded_offset,
                                              atom-tile, global desc
        SFB: (n_pad, k_pad, fake_l)       -> offset fake_l by expert_idx,
                                              atom-tile, global desc

    2Dx2D:
        A:   (m, fake_k, 1)               -> rewrite shape, expert-wise desc
        B:   (n, fake_k, 1)               -> rewrite shape, expert-wise desc
        C:   (m, n, fake_l)               -> offset fake_l by expert_idx, global desc
        SFA: (m_pad, fake_k_pad, 1)       -> offset fake_k_pad by padded_offset,
                                              atom-tile, expert-wise desc
        SFB: (n_pad, fake_k_pad, 1)       -> offset fake_k_pad by padded_offset,
                                              atom-tile, expert-wise desc
    """

    def __init__(
        self,
        scenario: Literal["2Dx3D", "2Dx2D"],
        tensormap_ctor: OnlineTensormapDescCreator,
    ):
        super().__init__(tensormap_ctor)
        self.scenario = scenario

    @cute.jit
    def get_gmem_tensor(
        self,
        tensor_name: str,
        gmem_tensor_in_moe_view: cute.Tensor,
        offs: Tuple[cute.Tensor, cute.Tensor],
        work_tile_info: MoEWorkTileInfo,
    ):
        # Unpack the offs tuple
        offs_token, offs_padded = offs

        expert_idx = work_tile_info.expert_idx
        token_offset, tokens_i = compute_expert_token_range(offs_token, expert_idx)
        padded_offset, padded_size_i = compute_expert_token_range(
            offs_padded, expert_idx
        )

        shape = gmem_tensor_in_moe_view.shape
        stride = gmem_tensor_in_moe_view.stride
        c1 = cutlass.Int32(1)
        sf_vec_size = self.tensormap_ctor.sf_vec_size

        if cutlass.const_expr(self.scenario == "2Dx3D"):
            if cutlass.const_expr(tensor_name == "a"):
                # A: (fake_m, k, 1) -> offset fake_m, global desc
                real = cute.domain_offset((token_offset, 0, 0), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (tokens_i, shape[1], c1))  # type: ignore[index]
                return (real, None)

            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, k, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset((0, 0, expert_idx), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))  # type: ignore[index]
                return (real, None)

            elif cutlass.const_expr(tensor_name == "c"):
                # C: (fake_m, n, 1) -> expert-wise desc
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (tokens_i, shape[1], c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("c", expert_idx)
                )
                return (real, desc)

            elif cutlass.const_expr(tensor_name == "sfa"):
                # SFA: (fake_m_pad, k_pad, 1) -> offset fake_m_pad, atom-tile, global desc
                real = cute.domain_offset(
                    (padded_offset, 0, 0), gmem_tensor_in_moe_view
                )
                per_expert_shape = (padded_size_i, shape[1], c1)  # type: ignore[index]
                sf_layout = tile_atom_to_shape_SF(per_expert_shape, sf_vec_size)
                real = cute.make_tensor(
                    real.iterator, cute.make_layout(sf_layout.shape, stride=stride)
                )
                return (real, None)

            elif cutlass.const_expr(tensor_name == "sfb"):
                # SFB: (n_pad, k_pad, fake_l) -> offset fake_l, atom-tile, global desc
                real = cute.domain_offset((0, 0, expert_idx), gmem_tensor_in_moe_view)
                per_expert_shape = (shape[0], shape[1], c1)  # type: ignore[index]
                sf_layout = tile_atom_to_shape_SF(per_expert_shape, sf_vec_size)
                real = cute.make_tensor(
                    real.iterator, cute.make_layout(sf_layout.shape, stride=stride)
                )
                return (real, None)

        elif cutlass.const_expr(self.scenario == "2Dx2D"):
            if cutlass.const_expr(tensor_name == "a"):
                # A: (m, fake_k, 1) -> expert-wise desc
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (shape[0], tokens_i, c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("a", expert_idx)
                )
                return (real, desc)

            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, fake_k, 1) -> expert-wise desc
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view,
                    (shape[0], tokens_i, c1),  # type: ignore[index]
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("b", expert_idx)
                )
                return (real, desc)

            elif cutlass.const_expr(tensor_name == "c"):
                # C: (m, n, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset((0, 0, expert_idx), gmem_tensor_in_moe_view)
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))  # type: ignore[index]
                return (real, None)

            elif cutlass.const_expr(tensor_name == "sfa"):
                # SFA: (m_pad, fake_k_pad, 1) -> offset fake_k_pad, atom-tile, expert-wise desc
                per_expert_shape = (shape[0], padded_size_i, c1)  # type: ignore[index]
                sf_layout = tile_atom_to_shape_SF(per_expert_shape, sf_vec_size)
                real = rewrite_tensor_shape(gmem_tensor_in_moe_view, sf_layout.shape)
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("sfa", expert_idx)
                )
                return (real, desc)

            elif cutlass.const_expr(tensor_name == "sfb"):
                # SFB: (n_pad, fake_k_pad, 1) -> offset fake_k_pad, atom-tile, expert-wise desc
                per_expert_shape = (shape[0], padded_size_i, c1)  # type: ignore[index]
                sf_layout = tile_atom_to_shape_SF(per_expert_shape, sf_vec_size)
                real = rewrite_tensor_shape(gmem_tensor_in_moe_view, sf_layout.shape)
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("sfb", expert_idx)
                )
                return (real, desc)

        raise ValueError("Invalid scenario or tensor name.")

    @cute.jit
    def prefetch_for_expert(self, expert_idx: Int32) -> None:
        if cutlass.const_expr(self.scenario == "2Dx3D"):
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("c", expert_idx))
        elif cutlass.const_expr(self.scenario == "2Dx2D"):
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("a", expert_idx))
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("b", expert_idx))
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("sfa", expert_idx))
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("sfb", expert_idx))
        else:
            raise ValueError("Invalid scenario.")
