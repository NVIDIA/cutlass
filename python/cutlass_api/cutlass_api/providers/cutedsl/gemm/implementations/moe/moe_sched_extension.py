# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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

Bridges the MoE tile scheduler (MoEPersistentTileScheduler) with tensor-level
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

    Scheduler --(produces)--> MoEWorkTileInfo
                                    |
                           expert_idx, tile_m, tile_n, k_cnt
                                    |
                                    v
    Extension --(uses)--> OnlineTensormapDescCreator
        |                         |
        |  get_gmem_tensor()      |  get_desc_ptr()
        |  prefetch_for_expert()  |  construct_and_write()
        |                         |
        +-- internal calls -------+

    Kernel (caller): the only place that knows all three exist
"""

from abc import ABC, abstractmethod
from typing import Literal, Tuple

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import Pointer
from cutlass.cutlass_dsl import Int32

from .dsl_objects import DeviceOnlyObj, UntracedPyObj
from .moe_utils import (
    OnlineTensormapDescCreator,
    tensormap_ptr_for_copy,
    compute_expert_token_range,
    rewrite_tensor_shape,
    prefetch_tma_descriptor,
)
from .moe_persistent_scheduler import MoEWorkTileInfo


class MoESchedExtension(ABC, DeviceOnlyObj, UntracedPyObj):
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
        offs: cute.Tensor,
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
        :param offs: Cumulative sum tensor of token counts per expert, shape (experts,)
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

    def __init__(self, scenario: Literal["2Dx3D", "2Dx2D"], tensormap_ctor: OnlineTensormapDescCreator):
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
                real = cute.domain_offset(
                    (token_offset, 0, 0), gmem_tensor_in_moe_view
                )
                real = rewrite_tensor_shape(real, (tokens_i, shape[1], c1))
                return (real, None)
            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, k, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset(
                    (0, 0, expert_idx), gmem_tensor_in_moe_view
                )
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))
                return (real, None)
            else:  # "c"
                # C: (fake_m, n, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view, (tokens_i, shape[1], c1)
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("c", expert_idx)
                )
                return (real, desc)

        else:  # 2Dx2D
            if cutlass.const_expr(tensor_name == "a"):
                # A: (m, fake_k, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view, (shape[0], tokens_i, c1)
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("a", expert_idx)
                )
                return (real, desc)
            elif cutlass.const_expr(tensor_name == "b"):
                # B: (n, fake_k, 1) -> expert-wise desc, no offset
                real = rewrite_tensor_shape(
                    gmem_tensor_in_moe_view, (shape[0], tokens_i, c1)
                )
                desc = tensormap_ptr_for_copy(
                    self.tensormap_ctor.get_desc_ptr("b", expert_idx)
                )
                return (real, desc)
            else:  # "c"
                # C: (m, n, fake_l) -> offset fake_l, global desc
                real = cute.domain_offset(
                    (0, 0, expert_idx), gmem_tensor_in_moe_view
                )
                real = rewrite_tensor_shape(real, (shape[0], shape[1], c1))
                return (real, None)

    @cute.jit
    def prefetch_for_expert(self, expert_idx: cutlass.Int32) -> None:
        if cutlass.const_expr(self.scenario == "2Dx3D"):
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("c", expert_idx))
        else:
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("a", expert_idx))
            prefetch_tma_descriptor(self.tensormap_ctor.get_desc_ptr("b", expert_idx))
