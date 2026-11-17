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

import argparse
import math
import os
import sys
from typing import Optional, Tuple, Type, Union

import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import tcgen05
from cutlass.cute.runtime import from_dlpack
from cutlass.experimental import primitives as prims
from cutlass.cute.typing import Float32, Int32

# When run directly, expose the sibling example packages used by the Blackwell base.
if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../../"))
    sys.path.insert(0, os.path.join(current_dir, "../../../../../"))

from helpers import fmha_helpers as fmha_utils
from helpers.ragged_tma import (
    RAGGED_TMA_MAX_PACKED_ROWS,
    create_packed_o_ragged_tma_descriptor,
    get_packed_o_tma_config,
    transform_packed_o_ragged_coords,
)
from blackwell.kernel.attention.fmha.fmha import (
    _PAGED_KV_LAYOUTS,
    BlackwellFusedMultiHeadAttentionForward,
    FmhaRunExtension,
    run as blackwell_run,
)


"""
A fused multi-head attention (FMHA) example for the NVIDIA Rubin SM107 architecture using CUTE DSL.

This file reuses the Blackwell FMHA kernel body and specializes the SM107 MMA
construction and pipeline policy. It adds logical-D72/physical-D80 storage
and packed variable-length output through dense or ragged TMA descriptors;
paged KV is inherited from the Blackwell base. The output store (TMA versus
direct), launch path, raster order, and work scheduler are explicit
per-variant choices resolved at compile time (``run()`` only supplies
defaults); the dynamic work-index scheduler requires an exclusive ``Int32[2]``
counter workspace per in-flight launch.

To run this example:

.. code-block:: bash

    python examples/cute/rubin/kernel/attention/fmha/fmha.py        \\
      --in_dtype Float8E4M3FN --out_dtype Float8E4M3FN              \\
      --qk_acc_dtype Float32 --pv_acc_dtype Float32                 \\
      --q_shape '8,(65,129,17,96,33,191,7,130),16,72'              \\
      --k_shape '8,(97,193,31,129,65,257,11,191),16,72'            \\
      --packed_buffer_capacity 1024                                \\
      --enable_skip_correction --skip_correction_threshold 4

Add ``--enable_q_mixed_residency`` to cache Q K-phases in TMEM (head
dimension 32/64/128, or MLA ``(d, d_v) = (192, 128)``). The TMEM budget is
shared with the MMA row-sum accumulators: Q0 keeps up to two phases and
Q1 up to one.
"""


def _resolve_rescale_threshold(
    rescale_threshold: Optional[float],
    skip_correction_threshold: Optional[float],
) -> float:
    """Resolve the canonical correction threshold and its compatibility alias."""
    if rescale_threshold is None:
        rescale_threshold = skip_correction_threshold
    elif skip_correction_threshold is not None and float(rescale_threshold) != float(
        skip_correction_threshold
    ):
        raise ValueError(
            "rescale_threshold and skip_correction_threshold must match "
            "when both are specified"
        )
    return 8.0 if rescale_threshold is None else float(rescale_threshold)


def _validate_host_attention_shapes(
    q_shape: Tuple,
    k_shape: Tuple,
    packed_buffer_capacity: Optional[int],
) -> None:
    """Validate the public host-side FMHA shape and packed-capacity contract."""
    if len(q_shape) != 4 or len(k_shape) != 4:
        raise ValueError("q_shape and k_shape must each contain exactly 4 values")
    b, s_q, h_q, d = q_shape
    b_k, s_k, h_k, d_k = k_shape
    if not isinstance(b, int) or b <= 0 or b_k != b:
        raise ValueError("Q and K must have the same positive batch size")
    if not isinstance(h_q, int) or not isinstance(h_k, int) or h_q <= 0 or h_k <= 0:
        raise ValueError("Q and K head counts must be positive integers")
    if h_q % h_k != 0:
        raise ValueError("Q head count must be divisible by K/V head count")
    if not isinstance(d, int) or not isinstance(d_k, int) or d <= 0 or d != d_k:
        raise ValueError("Q and K must have the same positive logical head dimension")

    for name, lengths in (("Q", s_q), ("K", s_k)):
        if isinstance(lengths, tuple):
            if len(lengths) != b:
                raise ValueError(
                    f"{name} length tuple must contain one entry per batch"
                )
            if not all(isinstance(length, int) and length > 0 for length in lengths):
                raise ValueError(f"{name} lengths must be positive integers")
        elif not isinstance(lengths, int) or lengths <= 0:
            raise ValueError(f"{name} length must be a positive integer or tuple")
    if packed_buffer_capacity is not None:
        if not isinstance(packed_buffer_capacity, int) or packed_buffer_capacity <= 0:
            raise ValueError("packed_buffer_capacity must be a positive integer")
        if not (isinstance(s_q, tuple) and isinstance(s_k, tuple)):
            raise ValueError(
                "packed_buffer_capacity requires variable sequence lengths"
            )
        if packed_buffer_capacity < max(sum(s_q), sum(s_k)):
            raise ValueError("packed capacity is smaller than actual sequence data")


_DYNAMIC_WORK_WAVE_BOUNDARY = 2
_DYNAMIC_WORK_MIN_AVG_KV_LOOPS = 19
_RUBIN_D72_CLUSTER_MIN_SMS = 200


def _uniform_varlen_q_length(s_q: Union[int, Tuple[int, ...]]) -> Optional[int]:
    """Return the shared Q length for a non-trivial uniform packed batch."""
    if not isinstance(s_q, tuple) or len(s_q) <= 1 or s_q[0] <= 0:
        return None
    return s_q[0] if all(seqlen == s_q[0] for seqlen in s_q[1:]) else None


def _uniform_varlen_o_descriptor_length(
    s_q: Union[int, Tuple[int, ...]], mma_tiler_mn: Tuple[int, int]
) -> Optional[int]:
    """Return the uniform extent only when packed O needs per-batch bounds."""
    uniform_q_length = _uniform_varlen_q_length(s_q)
    if uniform_q_length is None:
        return None
    return uniform_q_length if uniform_q_length % (2 * mma_tiler_mn[0]) != 0 else None


def _needs_ragged_tma_output_store(
    s_q: Union[int, Tuple[int, ...]],
    mma_tiler_mn: Tuple[int, int],
    packed_buffer_capacity: Optional[int] = None,
) -> bool:
    """Return whether packed O needs the synthetic-dimension TMA descriptor.

    A partial final sequence is dense-TMA safe only when the physical output
    ends at ``sum(s_q)``. A larger packed capacity leaves writable padding
    after the logical output, so its final partial CTA also needs ragged OOB.
    """
    if not isinstance(s_q, tuple):
        return False

    query_rows_per_cta = 2 * mma_tiler_mn[0]
    output_ends_at_logical_q = (
        packed_buffer_capacity is None or packed_buffer_capacity == sum(s_q)
    )
    dense_tma_safe = _uniform_varlen_q_length(s_q) is not None or (
        all(seqlen % query_rows_per_cta == 0 for seqlen in s_q[:-1])
        and (s_q[-1] % query_rows_per_cta == 0 or output_ends_at_logical_q)
    )
    if not dense_tma_safe:
        output_capacity = (
            packed_buffer_capacity if packed_buffer_capacity is not None else sum(s_q)
        )
        if output_capacity >= RAGGED_TMA_MAX_PACKED_ROWS:
            raise ValueError(
                "ragged TMA output requires packed capacity below "
                f"{RAGGED_TMA_MAX_PACKED_ROWS} rows; pass use_tma_store=False "
                "for larger capacities"
            )
    return not dense_tma_safe


class RubinFmhaRunExtension(FmhaRunExtension):
    """Rubin frontend run options and driver steps for the example ``run()``.

    Accepted run options (beyond the baseline ``run()`` parameters):

    :param packed_buffer_capacity: Optional shared physical token capacity for
                                   packed rank-3 Q/K/V/O buffers.
    :type packed_buffer_capacity: Optional[int]
    :param max_seqlen_q: Optional Q sequence-length capacity/dispatch upper
                        bound. It must not be smaller than the longest actual
                        Q sequence, but does not enlarge the current launch's
                        scheduler problem size.
    :type max_seqlen_q: Optional[int]
    :param max_seqlen_k: Optional K/V sequence-length capacity/dispatch upper
                        bound. It must not be smaller than the longest actual
                        K/V sequence, but does not replace its current launch
                        value.
    :type max_seqlen_k: Optional[int]
    The output store is the caller's explicit ``use_tma_store`` choice (the
    Rubin ``run()`` wrapper defaults it to TMA). Packed variable-length Q
    dispatches between dense and ragged TMA descriptors by layout
    feasibility; an infeasible TMA layout raises instead of silently
    falling back to the bounds-checked direct store.
    Paged-KV run options (``use_paged_kv``, ``page_size``, ``paged_kv_layout``,
    ``page_table_order``) are inherited from ``FmhaRunExtension``.
    :param rescale_threshold: Canonical non-negative correction-skip threshold.
                              Defaults to 8.0.
    :type rescale_threshold: Optional[float]
    :param skip_correction_threshold: Compatibility alias for
                                      ``rescale_threshold``.
    :type skip_correction_threshold: Optional[float]
    :param use_cluster_launch: Whether to launch through the CUDA cluster
                               launch path; an explicit value wins.
    :type use_cluster_launch: Optional[bool] (``None`` = shape-tuned default)
    :param use_clc_scheduler: Whether to use Rubin hardware CLC work indices.
                              This path is mutually exclusive with
                              software-persistent scheduling.
    :type use_clc_scheduler: bool
    :param persistent_raster_order: Persistent work-index linearization:
                                    ``mhb`` (M fastest) or ``compact``
                                    (only valid ragged Q tiles).
    :type persistent_raster_order: Optional[str] (``None`` = shape-tuned default)
    :param persistent_work_scheduler: Compact persistent scheduling:
                                      ``static`` CTA-strided work indices or the
                                      ``dynamic`` one-stage global work-index
                                      queue; resolved before compilation, so
                                      integrations dispatch separate cubins.
    :type persistent_work_scheduler: Optional[str] (``None`` = shape-tuned default)
    """

    def __init__(
        self,
        fmha_class,
        *,
        q_shape,
        k_shape,
        qk_dtype,
        pv_dtype,
        out_dtype,
        mma_tiler_mn,
        is_persistent,
        is_causal,
        bottom_right_align,
        window_size,
        use_tma_store,
        skip_ref_check,
        packed_buffer_capacity=None,
        max_seqlen_q=None,
        max_seqlen_k=None,
        use_paged_kv=False,
        page_size=128,
        paged_kv_layout="separate_nhd",
        page_table_order="reverse",
        rescale_threshold=None,
        skip_correction_threshold=None,
        use_cluster_launch=None,
        use_clc_scheduler=False,
        persistent_raster_order=None,
        persistent_work_scheduler=None,
    ):
        """Resolve the Rubin run options on top of the shared baseline.

        Picks the shape-tuned scheduler, raster, and launch defaults, the
        packed variable-length output policy, and the logical-D72 /
        physical-D80 storage contract. Paged-KV options are validated and
        stored by the base ``FmhaRunExtension``.
        """
        super().__init__(
            fmha_class,
            q_shape=q_shape,
            k_shape=k_shape,
            qk_dtype=qk_dtype,
            pv_dtype=pv_dtype,
            out_dtype=out_dtype,
            mma_tiler_mn=mma_tiler_mn,
            is_persistent=is_persistent,
            is_causal=is_causal,
            bottom_right_align=bottom_right_align,
            window_size=window_size,
            use_tma_store=use_tma_store,
            skip_ref_check=skip_ref_check,
            use_paged_kv=use_paged_kv,
            page_size=page_size if use_paged_kv else None,
            paged_kv_layout=paged_kv_layout,
            page_table_order=page_table_order,
        )
        b, s_q, h_q, d = q_shape
        b_, s_k, h_k, d_ = k_shape
        if persistent_work_scheduler not in {None, "static", "dynamic"}:
            raise ValueError(
                "persistent_work_scheduler must be 'static' or 'dynamic', "
                f"got {persistent_work_scheduler!r}"
            )
        # Raster/layout membership and the persistent/contiguous-KV compact
        # legs are constructor-visible and validated there; only the
        # variable-length Q requirement is host-only.
        if persistent_raster_order == "compact" and not isinstance(s_q, tuple):
            raise ValueError(
                "compact persistent scheduling requires variable-length "
                "(tuple) Q sequence lengths"
            )
        # ``None`` selects the shape-tuned defaults below; explicit flags win.
        no_window_requested = len(window_size) == 2 and tuple(window_size) == (-1, -1)
        is_tuned_rubin_d72_mha = (
            fmha_class.arch_str == "sm_107"
            and is_persistent
            and not use_paged_kv
            and (s_q, h_q) == (s_k, h_k)
            and d == d_ == 72
            and tuple(mma_tiler_mn) == (128, 128)
            and not is_causal
            and not bottom_right_align
            and no_window_requested
        )
        nonuniform_tuple_q = isinstance(s_q, tuple) and len(set(s_q)) > 1
        if persistent_raster_order is None:
            persistent_raster_order = (
                "compact" if is_tuned_rubin_d72_mha and nonuniform_tuple_q else "mhb"
            )
        tuned_compact = is_tuned_rubin_d72_mha and persistent_raster_order == "compact"
        if use_cluster_launch is None:
            use_cluster_launch = bool(use_clc_scheduler or use_paged_kv)
            if not use_cluster_launch and tuned_compact:
                sm_count = torch.cuda.get_device_properties(
                    torch.cuda.current_device()
                ).multi_processor_count
                use_cluster_launch = sm_count >= _RUBIN_D72_CLUSTER_MIN_SMS
        _validate_host_attention_shapes(q_shape, k_shape, packed_buffer_capacity)
        requested_rescale_threshold = _resolve_rescale_threshold(
            rescale_threshold, skip_correction_threshold
        )
        # Constructor-visible CLC constraints (persistent exclusion, paged
        # P16, D128, TMA store) are validated by the kernel constructor; the
        # run options only gate what the constructor cannot see.
        if use_clc_scheduler:
            if not is_causal or not bottom_right_align:
                raise ValueError(
                    "hardware CLC FMHA currently supports bottom-right causal GQA only"
                )
            elif h_q <= h_k:
                raise ValueError("hardware CLC FMHA currently requires D128 GQA")
        dv = d if d != 192 else 128
        storage_d = fmha_class._storage_dim_from_logical(d)
        storage_dv = fmha_class._storage_dim_from_logical(dv)
        if use_paged_kv and packed_buffer_capacity is not None:
            raise ValueError("packed_buffer_capacity is not supported with paged KV")
        s_q_list = s_q if isinstance(s_q, tuple) else [s_q] * b
        use_ragged_tma_store = use_tma_store and _needs_ragged_tma_output_store(
            s_q, mma_tiler_mn, packed_buffer_capacity=packed_buffer_capacity
        )
        if (
            self.enable_nvfp4_output
            and (storage_dv * out_dtype.width) % 128 != 0
            and use_tma_store
        ):
            # D72 uses physical D80, so its packed FP4 head stride is 40 bytes.
            # The current output TMA descriptors require a 16-byte-divisible D
            # extent; only the bounds-checked direct epilogue can store it.
            raise ValueError(
                "NVFP4 D72/physical-D80 output has a 40-byte head stride and "
                "cannot use the current 16-byte-aligned TMA descriptor; pass "
                "use_tma_store=False (--use_direct_store)"
            )
        uniform_varlen_o_extent = (
            _uniform_varlen_o_descriptor_length(s_q, mma_tiler_mn)
            if isinstance(s_q, tuple) and use_tma_store and not use_ragged_tma_store
            else None
        )
        # Explicit dynamic eligibility (persistent compact SM107, contiguous
        # KV, ragged TMA output) is constructor-visible and validated there;
        # the ``None`` default engages the queue only for the tuned ViT-D72
        # family past the wave/KV-loop thresholds.
        if persistent_work_scheduler is None:
            persistent_work_scheduler = "static"
            # The tuned family guarantees s_q == s_k, and ragged TMA output
            # already implies use_tma_store.
            if tuned_compact and use_ragged_tma_store:
                q_tile_size = 2 * mma_tiler_mn[0]
                kv_tile_size = mma_tiler_mn[1]
                q_tile_counts = [
                    (seqlen_q + q_tile_size - 1) // q_tile_size for seqlen_q in s_q_list
                ]
                compact_q_tile_count = sum(q_tile_counts)
                weighted_kv_loop_count = sum(
                    q_tiles * ((seqlen_k + kv_tile_size - 1) // kv_tile_size)
                    for q_tiles, seqlen_k in zip(q_tile_counts, s_q_list)
                )
                sm_count = torch.cuda.get_device_properties(
                    torch.cuda.current_device()
                ).multi_processor_count
                if (
                    h_q * compact_q_tile_count > _DYNAMIC_WORK_WAVE_BOUNDARY * sm_count
                    and weighted_kv_loop_count
                    >= _DYNAMIC_WORK_MIN_AVG_KV_LOOPS * compact_q_tile_count
                ):
                    persistent_work_scheduler = "dynamic"
        compact_work_count = None
        if persistent_work_scheduler == "dynamic":
            # The exact compact work count seeds the queue counter workspace.
            q_tile_size = 2 * mma_tiler_mn[0]
            compact_work_count = h_q * sum(
                (seqlen_q + q_tile_size - 1) // q_tile_size for seqlen_q in s_q_list
            )
        actual_max_seqlen_q = max(s_q) if isinstance(s_q, tuple) else s_q
        actual_max_seqlen_k = max(s_k) if isinstance(s_k, tuple) else s_k
        if max_seqlen_q is not None and max_seqlen_q < actual_max_seqlen_q:
            raise ValueError(
                f"max_seqlen_q ({max_seqlen_q}) is smaller than the longest "
                f"actual Q sequence ({actual_max_seqlen_q})"
            )
        if max_seqlen_k is not None and max_seqlen_k < actual_max_seqlen_k:
            raise ValueError(
                f"max_seqlen_k ({max_seqlen_k}) is smaller than the longest "
                f"actual K/V sequence ({actual_max_seqlen_k})"
            )

        self.dv = dv
        self.packed_buffer_capacity = packed_buffer_capacity
        self.max_seqlen_q = max_seqlen_q
        self.max_seqlen_k = max_seqlen_k
        self.requested_rescale_threshold = requested_rescale_threshold
        self.use_cluster_launch = use_cluster_launch
        self.use_clc_scheduler = use_clc_scheduler
        self.persistent_raster_order = persistent_raster_order
        self.persistent_work_scheduler = persistent_work_scheduler
        self.compact_work_count = compact_work_count
        # Paged-KV constructor arguments are already in ctor_kwargs (base).
        self.ctor_kwargs.update(
            rescale_threshold=requested_rescale_threshold,
            use_ragged_tma_store=use_ragged_tma_store,
            uniform_varlen_o_extent=uniform_varlen_o_extent,
            num_q_heads=h_q,
            use_cluster_launch=use_cluster_launch,
            use_clc_scheduler=use_clc_scheduler,
            persistent_raster_order=persistent_raster_order,
            enable_dynamic_work_scheduler=persistent_work_scheduler == "dynamic",
        )
        # Keep the compiled capacity contract separate from the current
        # launch shape.  The persistent scheduler consumes s_q_max directly,
        # so passing a broad capacity such as 32768 here creates a mostly-
        # invalid rectangular work domain for ragged batches.  Explicit Int32
        # wrappers keep the first four values dynamic in the host ABI; plain
        # Python integers would instead specialize them into the generated
        # host wrapper.  H/D remain static kernel-variant properties.
        self.problem_size = (
            Int32(b),
            Int32(actual_max_seqlen_q),
            Int32(sum(s_q) if isinstance(s_q, tuple) else s_q),  # s_lse
            Int32(actual_max_seqlen_k),
            h_q,
            h_k,
            d,
            dv,
        )
        # Tensors and values created by the driver steps below.
        self.initial_o_padding = None

    def print_run_options(self):
        super().print_run_options()
        print(f"  rescale_threshold: {self.requested_rescale_threshold}")
        print(f"  persistent_raster_order: {self.persistent_raster_order}")
        print(f"  packed_buffer_capacity: {self.packed_buffer_capacity}")
        print(f"  max_seqlen_q: {self.max_seqlen_q}")
        print(f"  max_seqlen_k: {self.max_seqlen_k}")
        print(f"  use_cluster_launch: {self.use_cluster_launch}")
        print(f"  use_clc_scheduler: {self.use_clc_scheduler}")

    def prepare_output_tensors(self, o_tensor, o_torch, *, b, s_q, h_q, dv):
        super().prepare_output_tensors(o_tensor, o_torch, b=b, s_q=s_q, h_q=h_q, dv=dv)
        if (
            not self.enable_nvfp4_output
            and not self.skip_ref_check
            and self.storage_dv > dv
        ):
            # Poison padding after tensor creation so the correctness check proves
            # that valid rows are zeroed while unused packed capacity is untouched.
            o_torch[..., dv:].fill_(1)
            initial_o_fp32, initial_o_fp32_torch = cutlass_torch.cute_tensor_like(
                torch.empty(*o_torch.shape, dtype=torch.float32),
                Float32,
                is_dynamic_layout=True,
                assumed_align=16,
            )
            cute.testing.convert(o_tensor, initial_o_fp32)
            self.initial_o_padding = initial_o_fp32_torch.cpu()[..., dv:].clone()
        if self.persistent_work_scheduler == "dynamic":
            self.dynamic_work_counter_torch = torch.tensor(
                [0, self.compact_work_count],
                dtype=torch.int32,
                device="cuda",
            )
            self.dynamic_work_counter = from_dlpack(self.dynamic_work_counter_torch)

    def print_resolved_options(self, fmha):
        store_path = "TMA" if fmha.use_tma_store else "direct"
        if fmha.uniform_varlen_o_extent is not None:
            store_path += " (uniform per-batch descriptor)"
        # The correction epilogue explicitly zeroes the physical padding
        # columns of every valid output row on both store paths.
        padding = "zero" if self.storage_dv > self.dv else "none"
        scheduler = self.persistent_work_scheduler
        if self.compact_work_count is not None:
            scheduler += f" (compact_work: {self.compact_work_count})"
        print("  Q/K/V load path: TMA")
        print(f"  output store path: {store_path}")
        print(f"  output padding policy: {padding}")
        print(f"  persistent_work_scheduler: {scheduler}")

    def verify_output_padding(self, o_result_storage, s_q):
        initial_o_padding = self.initial_o_padding
        if initial_o_padding is None:
            return
        output_padding = o_result_storage[..., self.dv :]
        if o_result_storage.ndim == 3 and isinstance(s_q, tuple):
            initial_o_padding[: sum(s_q)].zero_()
        else:
            initial_o_padding = torch.zeros_like(output_padding)
        torch.testing.assert_close(
            output_padding,
            initial_o_padding,
            atol=0,
            rtol=0,
        )

    def build_workspaces(self, create_and_permute_tensor, kv_shape, v_shape):
        (
            k_tensor_workspace,
            v_tensor_workspace,
            extra_args,
            extra_scope,
        ) = super().build_workspaces(create_and_permute_tensor, kv_shape, v_shape)
        dynamic_work_counter_workspace = None
        if self.persistent_work_scheduler == "dynamic":
            dynamic_work_counter_workspace_torch = torch.tensor(
                [0, self.compact_work_count],
                dtype=torch.int32,
                device="cuda",
            )
            extra_scope.append(dynamic_work_counter_workspace_torch)
            dynamic_work_counter_workspace = from_dlpack(
                dynamic_work_counter_workspace_torch
            )
        extra_args = (*extra_args[:4], dynamic_work_counter_workspace)
        return k_tensor_workspace, v_tensor_workspace, extra_args, extra_scope


class RubinFusedMultiHeadAttentionForward(BlackwellFusedMultiHeadAttentionForward):
    """Rubin (SM107) specialization of the Blackwell FMHA forward kernel.

    Rubin-only performance features, implemented via the base class's
    architecture extension points:

    - **FP16 mixed softmax** (``enable_fp16_mixed_softmax``): packed FP16
      exp2 (Rubin's 4x MUFU throughput) while retaining FP32 accumulators
      and online row sums.
    - **MMA row sum** (off by default until the FP8 row-sum accuracy is
      validated; ``--enable_mma_rowsum`` opts in):
      accumulates the online row sum with an auxiliary P-times-ones MMA in
      TMEM instead of a packed-ALU chain.
    - **Q mixed residency** (``enable_q_mixed_residency``): caches Q K-phases
      in TMEM next to the row-sum accumulators; the budget fits up to two
      Q0 phases and one Q1 phase (head dimension 32/64/128 or MLA
      (192, 128)).
    """

    arch_str: str = "sm_107"
    arch_name: str = "Rubin SM107"
    # Ragged/bounded TMA descriptors make packed variable-length TMA output
    # stores safe on this frontend.
    _supports_packed_tma_o_store: bool = True
    # The alignment-annotated direct-store epilogue handles packed NVFP4
    # output (physical-D80 head strides forbid a TMA descriptor).
    _nvfp4_supports_direct_store: bool = True

    _MMA_INST_K: int = 64
    _HEAD_DIM_72: int = 72
    _HEAD_DIM_72_STORAGE: int = 80
    _supported_head_dims: frozenset[int] = (
        BlackwellFusedMultiHeadAttentionForward._supported_head_dims
        | frozenset({_HEAD_DIM_72})
    )

    run_extension_cls = RubinFmhaRunExtension

    @classmethod
    def _storage_dim_from_logical(cls, head_dim: int) -> int:
        return cls._HEAD_DIM_72_STORAGE if head_dim == cls._HEAD_DIM_72 else head_dim

    def __init__(
        self,
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        mma_tiler: Tuple[int, int],
        head_dim: Union[int, Tuple[int, int]],
        is_persistent: bool,
        mask_type: fmha_utils.MaskEnum,
        enable_ex2_emulation: bool,
        enable_skip_correction: bool,
        rescale_threshold: float = 8.0,
        use_tma_store: bool = True,
        merge_softmax_warp_groups: Optional[bool] = None,
        enable_q_mixed_residency: bool = False,
        enable_fp16_mixed_softmax: bool = False,
        enable_mma_rowsum: bool = False,
        use_ragged_tma_store: bool = False,
        uniform_varlen_o_extent: Optional[int] = None,
        page_size: Optional[int] = None,
        paged_kv_layout: str = "separate_nhd",
        num_q_heads: Optional[int] = None,
        use_cluster_launch: bool = False,
        use_clc_scheduler: bool = False,
        persistent_raster_order: str = "mhb",
        enable_dynamic_work_scheduler: bool = False,
        **base_kwargs,
    ):
        """Initialize the Rubin FMHA kernel configuration.

        ``enable_q_mixed_residency`` caches Q K-phases in TMEM. It is
        supported for FP8 E4M3 inputs with head dimension 32/64/128/192(MLA).
        ``enable_fp16_mixed_softmax`` uses packed FP16 exp2 while retaining
        FP32 accumulators and online row sums.
        ``enable_mma_rowsum`` accumulates the online row sum with a
        P-times-ones MMA where the hardware supports it; the default is off
        both here and in the example CLI (``--enable_mma_rowsum`` opts in)
        until the accuracy of the FP8 row sum is validated, and so derived
        kernels that do not wire the row-sum GEMMs and correction state stay
        on the packed-ALU row-sum chain.

        :param use_ragged_tma_store: Whether packed variable-length O uses a
                                     synthetic-dimension TMA descriptor so
                                     per-sequence tail rows become OOB no-ops.
        :type use_ragged_tma_store: bool
        :param uniform_varlen_o_extent: Shared positive Q extent for a packed
                                        uniform batch. When set, O uses a
                                        bounded per-batch TMA descriptor while
                                        Q and scheduling remain varlen.
        :type uniform_varlen_o_extent: Optional[int]
        ``page_size`` and ``paged_kv_layout`` are forwarded to the Blackwell
        base constructor, which owns the paged-KV contract.

        :param use_cluster_launch: Whether to launch the single-CTA kernel via
                                   CUDA cluster launch. ``False`` uses the
                                   legacy launch path.
        :type use_cluster_launch: bool
        :param use_clc_scheduler: Whether Rubin paged GQA uses hardware CLC
                                  work indices. ``False`` preserves the static or
                                  software-persistent scheduler.
        :type use_clc_scheduler: bool
        :param persistent_raster_order: Resolved persistent work-index
                                        linearization: ``mhb`` (M fastest),
                                        or ``compact`` for valid ragged tiles.
        :type persistent_raster_order: str
        :param enable_dynamic_work_scheduler: Whether eligible compact SM107
                                              kernels use a global work-index
                                              queue instead of static stride.
        :type enable_dynamic_work_scheduler: bool
        """
        if enable_fp16_mixed_softmax and enable_ex2_emulation:
            raise ValueError(
                "FP16 mixed softmax and FP32 exp2 emulation cannot be enabled together"
            )
        super().__init__(
            qk_acc_dtype=qk_acc_dtype,
            pv_acc_dtype=pv_acc_dtype,
            mma_tiler=mma_tiler,
            head_dim=head_dim,
            is_persistent=is_persistent,
            mask_type=mask_type,
            enable_ex2_emulation=enable_ex2_emulation,
            enable_skip_correction=enable_skip_correction,
            rescale_threshold=rescale_threshold,
            use_tma_store=use_tma_store,
            merge_softmax_warp_groups=merge_softmax_warp_groups,
            page_size=page_size,
            paged_kv_layout=paged_kv_layout,
            **base_kwargs,
        )
        if not math.isfinite(rescale_threshold) or rescale_threshold < 0.0:
            raise ValueError("rescale_threshold must be finite and non-negative")
        # Public compatibility alias for the canonical rescale threshold.
        self.skip_correction_threshold = rescale_threshold
        if persistent_raster_order not in ("mhb", "compact"):
            raise ValueError(
                "persistent_raster_order must be 'mhb' or 'compact', "
                f"got {persistent_raster_order!r}"
            )
        if persistent_raster_order == "compact" and (
            not is_persistent or page_size is not None
        ):
            raise ValueError(
                "compact persistent scheduling requires software-persistent "
                "contiguous-KV workloads"
            )
        self.persistent_raster_order = persistent_raster_order
        if use_clc_scheduler and is_persistent:
            raise ValueError(
                "hardware CLC and software-persistent scheduling are mutually exclusive"
            )
        self.use_cluster_launch = use_cluster_launch
        if use_clc_scheduler:
            if self.arch_str != "sm_107":
                raise ValueError("hardware CLC FMHA currently requires Rubin SM107")
            if page_size != 16:
                raise ValueError("hardware CLC FMHA currently requires paged KV P16")
            if not use_tma_store:
                raise ValueError(
                    "hardware CLC FMHA currently requires TMA output store"
                )
            if self.head_dim != 128 or self.head_dim_v != 128:
                raise ValueError("hardware CLC FMHA currently requires D=128")
        self.use_clc_scheduler = use_clc_scheduler
        # "compact" implies software-persistent contiguous KV (validated above).
        dynamic_work_scheduler_eligible = (
            self.arch_str == "sm_107"
            and persistent_raster_order == "compact"
            and use_tma_store
            and use_ragged_tma_store
        )
        if enable_dynamic_work_scheduler and not dynamic_work_scheduler_eligible:
            raise ValueError(
                "dynamic work-index scheduling requires persistent compact SM107 "
                "with contiguous KV and ragged TMA output"
            )
        self.use_dynamic_work_scheduler = enable_dynamic_work_scheduler
        if num_q_heads is not None and (
            not isinstance(num_q_heads, int)
            or isinstance(num_q_heads, bool)
            or num_q_heads <= 0
        ):
            raise ValueError("num_q_heads must be a positive integer when specified")
        self.num_q_heads = num_q_heads
        if use_ragged_tma_store and not use_tma_store:
            raise ValueError("ragged TMA output requires TMA output store")
        if use_ragged_tma_store and uniform_varlen_o_extent is not None:
            raise ValueError(
                "ragged TMA output and uniform per-batch descriptor are exclusive"
            )
        self.use_ragged_tma_store = use_ragged_tma_store
        if uniform_varlen_o_extent is not None and not use_tma_store:
            raise ValueError("uniform_varlen_o_extent requires TMA output store")
        if uniform_varlen_o_extent is not None and uniform_varlen_o_extent <= 0:
            raise ValueError("uniform_varlen_o_extent must be positive")
        self.uniform_varlen_o_extent = uniform_varlen_o_extent
        self.enable_fp16_mixed_softmax = enable_fp16_mixed_softmax
        self.enable_q_mixed_residency = enable_q_mixed_residency
        self.enable_mma_rowsum_requested = enable_mma_rowsum
        if enable_fp16_mixed_softmax:
            # The wider LdRed atom feeds the packed-FP16 exp pipeline.
            self.softmax_tmem_load_repetition = 64

    # TODO: utils.sm107.make_trivial_tiled_mma currently only supports FP8 inputs;
    # add FP16/BF16 variants (like the Blackwell kernel) in a follow-up MR.
    def _make_qk_tiled_mma(self, cta_group):
        return utils.sm107.make_trivial_tiled_mma(
            self.q_dtype,
            self.k_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            cta_group,
            (*self.qk_mma_tiler[:2], self.mma_inst_k),
        )

    def _make_qk_tmem_tiled_mma(self, cta_group):
        """Build the QK tiled MMA whose A operand reads Q from TMEM."""
        return utils.sm107.make_trivial_tiled_mma(
            self.q_dtype,
            self.k_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            cta_group,
            (*self.qk_mma_tiler[:2], self.mma_inst_k),
            a_source=tcgen05.OperandSource.TMEM,
        )

    def _make_pv_tiled_mma(self, cta_group, p_major_mode, p_source):
        return utils.sm107.make_trivial_tiled_mma(
            self.v_dtype,
            self.v_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            (*self.pv_mma_tiler[:2], self._MMA_INST_K),
            a_source=p_source,
        )

    def _make_rowsum_tiled_mma(self, cta_group):
        """Build the FP8 P-times-ones MMA used for the online row sum."""
        return utils.sm107.make_trivial_tiled_mma(
            self.v_dtype,
            self.v_dtype,
            cute.nvgpu.OperandMajorMode.K,
            cute.nvgpu.OperandMajorMode.K,
            self.pv_acc_dtype,
            cta_group,
            self.rowsum_mma_tiler,
            a_source=tcgen05.OperandSource.TMEM,
        )

    def _make_q_smem_layout_staged(self, qk_tiled_mma):
        if not self.enable_q_mixed_residency:
            return super()._make_q_smem_layout_staged(qk_tiled_mma)
        q_mixed_phase_tiler = (
            self.qk_mma_tiler[0],
            self.qk_mma_tiler[1],
            self.q_mixed_phase_dim,
        )
        phase_layout = sm100_utils.make_smem_layout_a(
            qk_tiled_mma, q_mixed_phase_tiler, self.q_dtype, 1
        )
        per_phase_cosize = cute.cosize(phase_layout)
        return cute.append(
            cute.append(
                cute.select(phase_layout, mode=[0, 1]),
                cute.make_layout(self.q_mixed_total_kphases, stride=per_phase_cosize),
            ),
            cute.make_layout(
                self.q_stage,
                stride=per_phase_cosize * self.q_mixed_total_kphases,
            ),
        )

    def _setup_attributes(self):
        super()._setup_attributes()
        self.kv_stage = 6
        self.mma_inst_k = 32 if self.head_dim == 32 else self._MMA_INST_K
        if self.head_dim == self._HEAD_DIM_72:
            # BMM1 keeps two K64 phases. BMM2 uses the smallest legal FP8
            # MN-major N tile, while cta_tiler[2] remains logical D72.
            self.qk_mma_tiler = (
                *self.qk_mma_tiler[:2],
                2 * self._MMA_INST_K,
            )
            self.pv_mma_tiler = (
                self.pv_mma_tiler[0],
                self.storage_head_dim_v,
                self.pv_mma_tiler[2],
            )
            # Traverse exactly the 72 valid accumulator columns. The final
            # physical D80 tile is defined separately as output padding.
            correction_tile_size = self.storage_head_dim_v - self.head_dim_v
            self.correction_rescale_tile_size = correction_tile_size
            self.correction_epilog_tile_size = correction_tile_size
        if self.o_dtype is cutlass.Float4E2M1FN:
            # NVFP4 emits one E4M3 scale per 16 contiguous values. Logical
            # D72 traverses physical D80 as five groups; the final eight
            # physical padding values are explicitly zeroed in the epilogue.
            self.correction_epilog_tile_size = 16
        # Rubin does not use ex2 emulation. (The sequence barrier stays on
        # unless the constructor's enable_sequence_barrier disabled it.)
        self.enable_ex2_emulation = False
        # Scalar setp/selp masking avoids an SM107 mask-lowering regression;
        # the asm's 32-register groups match the
        # 128-wide S fragment of every supported head dimension.
        self.use_causal_setp_selp_inline = True
        # Rolled epilogue: unrolling materializes every hoisted swizzled sO
        # store address at once (swizzle stage-offset hoist, 330ca74b873) and
        # spills the correction warps together with the x64 rescale vectors.
        # Padded D72 keeps the fully-unrolled epilogue validated in
        # MR !25546: its 8-column tiles hold few live addresses, and the
        # rolled loop costs more than the hoist saves.
        self.correction_epilog_unroll = (
            None if self.head_dim_v != self.storage_head_dim_v else 1
        )
        # Rescale four x16 TMEM vectors per group: independent FMUL2 work
        # instead of eight serialized x16 load/compute/store groups. Padded
        # logical widths (logical D72 / physical D80) keep the divisor-sized
        # tile chosen by the storage specialization above; a 64-wide tile
        # would leave the 72 % 64 tail columns without correction.
        if self.head_dim_v == self.storage_head_dim_v:
            self.correction_rescale_tile_size = min(64, self.head_dim_v)
        # The rebalanced 88/40 register split (MR !26350, tuned on MLA and
        # dense D128) makes the paged CLC work-index path and the padded-D72
        # families spill (39k dynamic LDL/STL on GQA P1, ~2-4% latency).
        # Those families keep the spill-free 96/32 split validated in
        # MR !25546; MLA and unpadded dense head dims keep 88/40.
        if self.page_size is not None or self.head_dim_v != self.storage_head_dim_v:
            self.num_regs_correction = 96
            self.num_regs_other = 32
        # The SM107 paged-FP8 schedule keeps 32 exp elements in flight before
        # consuming them in the FP8 conversion pipe.  The
        # inherited Blackwell default is eight, which exposes the MUFU->F2FP
        # dependency on Rubin.  Keep dense/ViT behavior unchanged.
        if self.page_size is not None:
            self.softmax_cvt_count = 32
            if self.head_dim_v == 128:
                # Full D128/BF16 epilogue expansion materializes 32 swizzled
                # sO addresses at once and spills 31 of them to local memory.
                # Four-way partial unrolling keeps the address fragment in
                # registers without paying the full runtime-loop overhead.
                self.correction_epilog_unroll = 4

        self.q_mixed_phase_dim = self.mma_inst_k
        self.q_mixed_total_kphases = (
            self.head_dim // self.q_mixed_phase_dim
            if self.enable_q_mixed_residency
            else 0
        )
        self.enable_mma_rowsum = (
            self.enable_mma_rowsum_requested
            and self.v_dtype is cutlass.Float8E4M3FN
            and self.qk_mma_tiler[:2] == (128, 128)
            and self.head_dim_v <= 128
        )
        if self.enable_mma_rowsum and not self.enable_fp16_mixed_softmax:
            # The MMA row sum adds correction-warp TMEM row-sum state; with
            # FP32 softmax the rebalanced 88/40 split spills (2M dynamic
            # LDL/STL on MLA b32/s4096, +5.6% latency), so keep the
            # spill-free 96/32 split. Under the packed-FP16 softmax the
            # measured optimum flips back to 88/40 on MLA (row-sum-on
            # A/B: 96/32 loses 5-6% on b32/s4096 and b16/s8192), so the
            # mixed path keeps the rebalanced split unless the paged or
            # padded-D72 family condition above already selected 96/32.
            self.num_regs_correction = 96
            self.num_regs_other = 32
        # Q mixed residency and the MMA row sum share a config envelope
        # (FP8 E4M3, 128x128 tile) but are functionally independent; either
        # may be enabled without the other.
        self.q0_mixed_tmem_kphases = min(2, self.q_mixed_total_kphases)
        # The Q1 budget is capped at one phase only because the two row-sum
        # accumulators occupy the last 16 TMEM columns; without the MMA row
        # sum those columns fit exactly one more cached phase
        # (512 + 4 * 16 = 576).
        self.q1_mixed_tmem_kphases = min(
            1 if self.enable_mma_rowsum else 2, self.q_mixed_total_kphases
        )
        self.q_mixed_tmem_kphases = max(
            self.q0_mixed_tmem_kphases, self.q1_mixed_tmem_kphases
        )
        if self.enable_mma_rowsum:
            # P[M,K] times an FP8 one-vector, accumulated in persistent FP32
            # TMEM; correction rescales C with the same factor as O.
            self.rowsum_mma_tiler = (
                self.pv_mma_tiler[0],
                8,
                self._MMA_INST_K,
            )
        # The Q-latent TMEM region holds the live phase slots followed by the
        # two M128N8 row-sum accumulators.
        self.tmem_q_latent_offset = self.tmem_o1_offset + self.qk_mma_tiler[1]
        q_mixed_live_slots = self.q0_mixed_tmem_kphases + self.q1_mixed_tmem_kphases
        self.tmem_q_latent_cols = (
            q_mixed_live_slots * self.q_mixed_phase_dim // 4
            if self.enable_q_mixed_residency
            else 0
        )
        if self.enable_mma_rowsum:
            self.tmem_rowsum0_offset = (
                self.tmem_q_latent_offset + self.tmem_q_latent_cols
            )
            self.tmem_rowsum1_offset = self.tmem_rowsum0_offset + 8
        if self.enable_q_mixed_residency and (
            self.head_dim not in (32, 64, 128, 192)
            or (self.head_dim == 192 and self.head_dim_v != 128)
            or (self.head_dim != 192 and self.head_dim_v != self.head_dim)
            or self.q_dtype is not cutlass.Float8E4M3FN
            or self.qk_mma_tiler[:2] != (128, 128)
        ):
            raise ValueError(
                "Q mixed residency requires Float8E4M3FN, mma_tiler_mn 128,128, "
                "and head dimension 32/64/128 or MLA (192, 128)"
            )
        if self.enable_q_mixed_residency and (
            self.tmem_q_latent_offset + self.tmem_q_latent_cols
            > self.num_tmem_alloc_cols
        ):
            raise ValueError(
                "Q mixed-residency TMEM buffer exceeds available TMEM columns"
            )
        if self.enable_mma_rowsum and (
            self.tmem_rowsum1_offset + 8 > self.num_tmem_alloc_cols
        ):
            raise ValueError("MMA row-sum accumulators exceed available TMEM columns")

    @cute.jit
    def _s2t_copy_and_partition(
        self,
        sQ: cute.Tensor,
        tQ: cute.Tensor,
    ):
        """Set up S2T copies for the mma_inst_k-wide Q slices cached in TMEM."""
        tCsQ_compact = cute.filter_zeros(sQ)
        tCtQ_compact_staged = cute.filter_zeros(tQ)
        tCtQ_compact = cute.filter_zeros(tQ[None, None, None, 0])

        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp128x128bOp(tcgen05.CtaGroup.ONE),
            self.q_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtQ_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        tCsQ_s2t_ = thr_copy_s2t.partition_S(tCsQ_compact)
        tCsQ_s2t = tcgen05.get_s2t_smem_desc_tensor(tiled_copy_s2t, tCsQ_s2t_)
        tCtQ_s2t = thr_copy_s2t.partition_D(tCtQ_compact_staged)
        return tiled_copy_s2t, tCsQ_s2t, tCtQ_s2t

    @cute.jit
    def _copy_q_latent_to_tmem(
        self,
        tiled_copy_q: cute.TiledCopy,
        tCsQ_s2t: cute.Tensor,
        tCtQ_s2t: cute.Tensor,
        q_stage_idx: Int32,
        num_cached_kphases: cutlass.Constexpr[int],
    ) -> None:
        """Copy the cached Q K-phases for one pipeline stage to TMEM."""
        for q_phase_idx in cutlass.range_constexpr(num_cached_kphases):
            for k_block in cutlass.range_constexpr(cute.size(tCtQ_s2t.shape[3])):
                cute.copy(
                    tiled_copy_q,
                    tCsQ_s2t[
                        None,
                        None,
                        None,
                        k_block,
                        (q_phase_idx, q_stage_idx),
                    ],
                    tCtQ_s2t[
                        None,
                        None,
                        None,
                        k_block,
                        (q_phase_idx, q_stage_idx),
                    ],
                )

    @cute.jit
    def mma_qk_mixed(
        self,
        tiled_mma_smem: cute.TiledMma,
        tiled_mma_tmem: cute.TiledMma,
        tensor_args: Tuple,
        pipeline_args: Tuple,
        num_cached_kphases: cutlass.Constexpr[int],
        pipeline_tokens: Tuple = (None, None),
    ) -> Tuple[
        pipeline.PipelineProducer,
        pipeline.PipelineProducer,
    ]:
        """Run QK with a caller-selected number of Q K-phases in TMEM."""
        tSrQi, tTrQ_tmem, q_stage_idx, tSrK, tStSi = tensor_args
        mma_si_producer, si_corr_producer = pipeline_args
        si_peek_status, veci_peek_status = pipeline_tokens

        si_handle = mma_si_producer.acquire_and_advance(si_peek_status)
        veci_handle = si_corr_producer.acquire_and_advance(veci_peek_status)
        veci_handle.commit()

        for kphase_idx in cutlass.range_constexpr(self.q_mixed_total_kphases):
            tiled_mma_smem.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
            if kphase_idx < num_cached_kphases:
                tiled_mma_tmem.set(tcgen05.Field.ACCUMULATE, kphase_idx != 0)
                cute.gemm(
                    tiled_mma_tmem,
                    tStSi,
                    tTrQ_tmem[None, None, 0, (kphase_idx, q_stage_idx)],
                    tSrK[None, None, kphase_idx],
                    tStSi,
                )
            else:
                kphase_coord = (None, None, kphase_idx)
                cute.gemm(
                    tiled_mma_smem,
                    tStSi,
                    tSrQi[kphase_coord],
                    tSrK[kphase_coord],
                    tStSi,
                )
        si_handle.commit()
        return mma_si_producer, si_corr_producer

    @cute.jit
    def apply_exp_and_cvt_fp16_mixed(
        self,
        tTMEM_LOADrS,
        exp_buf,
        exp_buf_cvt,
        tTMEM_STORErS_x4_e_cvt,
        stage,
        scale,
        minus_row_max_scale,
        local_row_sum,
        inplace_consumer,
        CVT_COUNT,
        CVT_PER_STEP,
        ARV_COUNT,
    ):
        """Packed-FP16 softmax exp/CVT schedule.

        Every main-loop step carries independent work from three different
        iterations - the structure of the dense-FP32 body, ported to the
        packed-FP16 path:

        * the packed MUFU.EX2 of pair ``i`` (its input was affine-scaled
          and packed to FP16 ``LOOKAHEAD`` elements earlier),
        * the FFMA2 affine + F2FP pack of pair ``i + LOOKAHEAD``,
        * the FP8 conversion of pair ``i - CVT_COUNT``.

        Nothing inside a scheduling window waits on a producer within the
        window, and the per-window port mix stays balanced (one packed-FMA,
        one convert and one MUFU stream per iteration), so the port
        interleave survives the per-group cfence that pins the rotation.
        The 2-cycle packed math and convert ports charge a WAIT2 stall for
        every same-port adjacent pair - the cost the staged-block schedule
        paid on softmax-bound shapes - while a completely unfenced stream
        lets the scheduler collapse the rotation on the skip-correction
        configurations; this shape avoids both.
        """
        total = cute.size(tTMEM_LOADrS)
        scale_pair = (scale, scale)
        offset_pair = (minus_row_max_scale, minus_row_max_scale)
        # Swept optima (fence strides 4-32, lookaheads 4-16 measured): wider
        # fence windows trade the anchoring for exposed packed-port bubbles,
        # and deeper lookahead only extends register live ranges. Under the
        # MMA row sum the FHADD2 retirement stream is gone, so the 3-deep
        # rotation keeps more packed pairs live than the allocator can place
        # without shuffle MOVs on the MUFU outputs; halving the lookahead
        # removes those copies (1-6% on row-sum kernels, off-arm unchanged).
        FENCE_STRIDE = 4
        LOOKAHEAD = 4 if self.enable_mma_rowsum else 8
        assert total % 4 == 0 and CVT_COUNT % 4 == 0
        assert total > LOOKAHEAD and total > CVT_COUNT
        NUM_ROW_SUM_ACCUMULATORS = 2 if self.page_size is not None else 4
        if cutlass.const_expr(not self.enable_mma_rowsum):
            local_row_sums = [local_row_sum] + [
                (Float32(0.0), Float32(0.0))
                for _ in range(NUM_ROW_SUM_ACCUMULATORS - 1)
            ]

        # Prologue: pack the first LOOKAHEAD elements (writes FP16 pair i
        # over consumed FP32 slot i//2 - the established aliasing contract).
        for i in cutlass.range_constexpr(0, LOOKAHEAD, 2):
            scaled_pair = cute.arch.fma_packed_f32x2(
                (tTMEM_LOADrS[i], tTMEM_LOADrS[i + 1]),
                scale_pair,
                offset_pair,
            )
            packed_pair = fmha_utils.cvt_packed_f16x2_f32x2(scaled_pair)
            exp_buf[i] = packed_pair[0]
            exp_buf[i + 1] = packed_pair[1]

        if cutlass.const_expr(self.enable_sequence_barrier):
            # Release the peer softmax stage before the loop; the fences
            # below cannot delay an arrive already first in program order.
            self._sequence_barrier(1 - stage).arrive()
        for i in cutlass.range_constexpr(0, total, 2):
            exp_pair = cute.math.exp2(
                (exp_buf.iterator.raw_ptr() + i).load(count=2, alignment=4),
                fastmath=True,
            )
            exp_buf[i] = exp_pair[0]
            exp_buf[i + 1] = exp_pair[1]
            if cutlass.const_expr(i + LOOKAHEAD < total):
                j = i + LOOKAHEAD
                scaled_pair = cute.arch.fma_packed_f32x2(
                    (tTMEM_LOADrS[j], tTMEM_LOADrS[j + 1]),
                    scale_pair,
                    offset_pair,
                )
                packed_pair = fmha_utils.cvt_packed_f16x2_f32x2(scaled_pair)
                exp_buf[j] = packed_pair[0]
                exp_buf[j + 1] = packed_pair[1]
            if cutlass.const_expr(i >= CVT_COUNT):
                k = i - CVT_COUNT
                if cutlass.const_expr(k % CVT_PER_STEP == 0):
                    fmha_utils.cvt_f16x4_to_f8x4(
                        exp_buf_cvt[None, k // CVT_PER_STEP],
                        tTMEM_STORErS_x4_e_cvt[None, k // CVT_PER_STEP],
                    )
                if cutlass.const_expr(not self.enable_mma_rowsum):
                    retired_pair = (exp_buf[k], exp_buf[k + 1])
                    sum_slot = (k // 2) % NUM_ROW_SUM_ACCUMULATORS
                    local_row_sums[sum_slot] = fmha_utils.add_packed_f32x2_f16x2_f32x2(
                        retired_pair, local_row_sums[sum_slot]
                    )
        for i in cutlass.range_constexpr(total - CVT_COUNT, total, 2):
            if cutlass.const_expr(i % CVT_PER_STEP == 0):
                fmha_utils.cvt_f16x4_to_f8x4(
                    exp_buf_cvt[None, i // CVT_PER_STEP],
                    tTMEM_STORErS_x4_e_cvt[None, i // CVT_PER_STEP],
                )
            if cutlass.const_expr(not self.enable_mma_rowsum):
                exp_pair = (exp_buf[i], exp_buf[i + 1])
                sum_slot = (i // 2) % NUM_ROW_SUM_ACCUMULATORS
                local_row_sums[sum_slot] = fmha_utils.add_packed_f32x2_f16x2_f32x2(
                    exp_pair, local_row_sums[sum_slot]
                )
        if cutlass.const_expr(self.enable_mma_rowsum):
            pass
        elif cutlass.const_expr(NUM_ROW_SUM_ACCUMULATORS == 2):
            local_row_sum = cute.arch.add_packed_f32x2(
                local_row_sums[0], local_row_sums[1]
            )
        else:
            local_row_sum = cute.arch.add_packed_f32x2(
                cute.arch.add_packed_f32x2(local_row_sums[0], local_row_sums[1]),
                cute.arch.add_packed_f32x2(local_row_sums[2], local_row_sums[3]),
            )
        inplace_peek_status = inplace_consumer.try_wait()
        inplace_consumer.wait_and_advance(inplace_peek_status)
        return local_row_sum, inplace_consumer

    def _validate_arch_call_operands(
        self,
        k_tensor,
        v_tensor,
        cum_seqlen_q,
        cum_seqlen_k,
        page_table,
        o_sf_tensor,
        o_sf_scale,
        o_sf_start_index,
        dynamic_work_counter,
    ):
        """Validate the paged-KV, NVFP4, and dynamic-scheduler operands."""
        super()._validate_arch_call_operands(
            k_tensor,
            v_tensor,
            cum_seqlen_q,
            cum_seqlen_k,
            page_table,
            o_sf_tensor,
            o_sf_scale,
            o_sf_start_index,
            dynamic_work_counter,
        )
        if cutlass.const_expr(self.use_dynamic_work_scheduler):
            if cutlass.const_expr(dynamic_work_counter is None):
                raise ValueError("dynamic work-index scheduling requires its counter")
            if cutlass.const_expr(
                cute.rank(dynamic_work_counter) != 1
                or dynamic_work_counter.element_type != Int32
                or cute.size(dynamic_work_counter) != 2
            ):
                raise TypeError(
                    "dynamic work-index state must contain two Int32 values"
                )

        if cutlass.const_expr(
            self.uniform_varlen_o_extent is not None and cum_seqlen_q is None
        ):
            raise ValueError("uniform per-batch O descriptor requires cum_seqlen_q")

    def _make_ragged_o_tma_descriptor(
        self, o_tensor, cum_seqlen_q, s_q, h_q, storage_dv
    ):
        """Build the synthetic-dimension TMA descriptor for packed ragged O."""
        if cutlass.const_expr(cum_seqlen_q is None):
            raise ValueError("ragged TMA output requires cumulative Q lengths")
        (
            self.ragged_tma_o_chunk_columns,
            self.ragged_tma_o_chunk_count,
            ragged_tma_o_swizzle,
        ) = get_packed_o_tma_config(storage_dv, self.o_dtype.width)
        self.ragged_tma_o_coordinate_divisor = 2 if self.o_dtype.width == 4 else 1
        packed_o = cute.make_tensor(
            o_tensor.iterator,
            cute.make_layout(
                (s_q, h_q, storage_dv),
                stride=(h_q * storage_dv, storage_dv, 1),
            ),
        )
        return create_packed_o_ragged_tma_descriptor(
            packed_o,
            row_box=self.epi_tile[0],
            column_box=self.ragged_tma_o_chunk_columns,
            swizzle=ragged_tma_o_swizzle,
        )

    @cute.jit
    def _prefetch_ragged_o_descriptor(self, ragged_tma_o_desc) -> None:
        prims.prefetch_tensormap(ragged_tma_o_desc.get_ptr())

    @cute.jit
    def _store_o_tile_ragged(
        self,
        ragged_tma_o_desc,
        sO_slot: cute.Tensor,
        flat_head_coord: Int32,
        o_row: Int32,
        seq_end: Int32,
    ) -> None:
        """Store one O tile through the ragged TMA-OOB descriptor."""
        o_tma_coords = transform_packed_o_ragged_coords(
            0,
            flat_head_coord,
            o_row,
            row_box=self.epi_tile[0],
            row_extent=seq_end - o_row,
        )
        for d_chunk in cutlass.range_constexpr(self.ragged_tma_o_chunk_count):
            d_offset = d_chunk * self.ragged_tma_o_chunk_columns
            chunk_coords = (
                Int32(d_offset // self.ragged_tma_o_coordinate_divisor),
                o_tma_coords[1],
                o_tma_coords[2],
                o_tma_coords[3],
                o_tma_coords[4],
            )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_global_shared_cta(
                    ragged_tma_o_desc.get_ptr(),
                    sO_slot.iterator
                    + d_chunk * self.epi_tile[0] * self.ragged_tma_o_chunk_columns,
                    chunk_coords,
                )

    @cute.jit
    def _produce_dynamic_work_idxs(
        self,
        dynamic_work_pipeline,
        dynamic_work_idx_ptr,
        dynamic_work_counter: cute.Tensor,
        tile_sched,
    ) -> None:
        """Serve compact work indices from the global software queue."""
        dynamic_work_producer = dynamic_work_pipeline.make_producer()
        keep_producing = cutlass.Boolean(True)
        next_work_idx = Int32(-1)
        while keep_producing:
            dynamic_handle = dynamic_work_producer.acquire_and_advance()
            dynamic_response_ptr = dynamic_work_idx_ptr + dynamic_handle.index * 4
            with cute.arch.elect_one():
                next_work_idx = cute.arch.atomic_add(
                    (dynamic_work_counter.iterator + 0).llvm_ptr,
                    Int32(1),
                    sem="relaxed",
                    scope="gpu",
                )
                cute.arch.store(dynamic_response_ptr, next_work_idx)
            cute.arch.sync_warp()
            next_work_idx = cute.arch.load(
                dynamic_response_ptr,
                Int32,
                ss="cta",
            )
            dynamic_m_idx = Int32(0)
            dynamic_h_idx = Int32(0)
            dynamic_b_idx = Int32(0)
            dynamic_is_valid = next_work_idx < dynamic_work_counter[1]
            if dynamic_is_valid:
                tile_sched.set_current_work_linear_idx(next_work_idx)
                dynamic_work_tile = tile_sched.get_current_work()
                dynamic_m_idx = Int32(dynamic_work_tile.tile_idx[0])
                dynamic_h_idx = Int32(dynamic_work_tile.tile_idx[2][0])
                dynamic_b_idx = Int32(dynamic_work_tile.tile_idx[2][1])
            with cute.arch.elect_one():
                cute.arch.store(
                    dynamic_response_ptr + 0,
                    dynamic_m_idx,
                )
                cute.arch.store(
                    dynamic_response_ptr + 1,
                    dynamic_h_idx,
                )
                cute.arch.store(
                    dynamic_response_ptr + 2,
                    dynamic_b_idx,
                )
                cute.arch.store(
                    dynamic_response_ptr + 3,
                    Int32(dynamic_is_valid),
                )
            cute.arch.sync_warp()
            dynamic_handle.commit()
            keep_producing = dynamic_is_valid
        dynamic_work_producer.tail()

        # Each CTA claims exactly one terminal ID. The highest terminal
        # claimant is therefore the final queue user and can reset the
        # counter for a later same-stream launch.
        last_terminal_work_idx = (
            dynamic_work_counter[1] + cute.size(cute.arch.grid_dim()) - 1
        )
        if next_work_idx == last_terminal_work_idx:
            with cute.arch.elect_one():
                cute.arch.store(
                    (dynamic_work_counter.iterator + 0).llvm_ptr,
                    Int32(0),
                    sem="release",
                    scope="gpu",
                )

    @cute.jit
    def _store_o_tile_direct(
        self,
        tTMrO: cute.Tensor,
        tTMEM_LOADdO_i: cute.Tensor,
        row_idx: Int32,
        seqlen_q: Int32,
    ) -> None:
        """Alignment-annotated direct store (enables wide st.global vectors).

        Every Rubin direct-store configuration benefits; packed NVFP4 on the
        physical-D80 layout *requires* it (sub-byte elements can only be
        stored as byte-aligned groups, never element-wise).
        """
        # Preserve the destination partition layout so the direct
        # register-to-global copy can lower to vector stores.
        tDMrO = cute.make_fragment_like(tTMEM_LOADdO_i, self.o_dtype)
        tDMrO.store(tTMrO.load().to(self.o_dtype))
        if row_idx < seqlen_q:
            # TMEM partitioning loses the alignment guaranteed by the
            # output base and correction-chunk stride. Reattach that
            # fact so autovec can select a wide global store.
            direct_store_alignment = min(
                32, self.correction_epilog_tile_size * self.o_dtype.width // 8
            )
            tDMrO_dst = cute.make_tensor(
                cute.make_ptr(
                    self.o_dtype,
                    tTMEM_LOADdO_i.iterator.toint(),
                    cutlass.AddressSpace.gmem,
                    assumed_align=direct_store_alignment,
                ),
                tTMEM_LOADdO_i.layout,
            )
            cute.autovec_copy(tDMrO, tDMrO_dst)

    @cute.jit
    def _store_o_d80_padding(
        self,
        tTMEM_LOADdO: cute.Tensor,
        tTMEM_LOADoO,
        tiled_smem_store,
        row_idx: Int32,
        seqlen_q: Int32,
    ) -> None:
        """Zero the physical output padding (storage D80 for logical D72)."""
        corr_tile_size = self.correction_epilog_tile_size
        direct_store_alignment = min(32, corr_tile_size * self.o_dtype.width // 8)
        # Define physical output padding instead of exposing stale memory.
        # A padded specialization must provide exactly one epilogue tile.
        assert self.storage_head_dim_v == self.pv_mma_tiler[1]
        assert self.storage_head_dim_v - self.head_dim_v == corr_tile_size
        padding_tile = self.head_dim_v // corr_tile_size
        tTMEM_LOADdO_padding = tTMEM_LOADdO[None, 0, 0, padding_tile]
        if cutlass.const_expr(self.use_tma_store):
            tDMrO_padding = cute.make_rmem_tensor(
                tTMEM_LOADoO[None, 0, 0, padding_tile].shape, self.o_dtype
            )
        else:
            tDMrO_padding = cute.make_fragment_like(tTMEM_LOADdO_padding, self.o_dtype)
        tDMrO_padding.fill(0)
        if cutlass.const_expr(self.use_tma_store):
            cute.copy(tiled_smem_store, tDMrO_padding, tTMEM_LOADdO_padding)
        else:
            if row_idx < seqlen_q:
                tDMrO_padding_dst = cute.make_tensor(
                    cute.make_ptr(
                        self.o_dtype,
                        tTMEM_LOADdO_padding.iterator.toint(),
                        cutlass.AddressSpace.gmem,
                        assumed_align=direct_store_alignment,
                    ),
                    tTMEM_LOADdO_padding.layout,
                )
                cute.autovec_copy(tDMrO_padding, tDMrO_padding_dst)

    @cute.jit
    def _consume_next_clc_work(
        self,
        clc_pipeline,
        clc_response_ptr,
        clc_consumer_state,
    ):
        clc_pipeline.consumer_wait(clc_consumer_state)
        work_tile = fmha_utils.fmha_work_tile_info_from_clc_response(
            clc_response_ptr + clc_consumer_state.index
        )
        clc_pipeline.consumer_release(clc_consumer_state)
        clc_consumer_state.advance()
        return work_tile, clc_consumer_state

    @cute.jit
    def _consume_next_dynamic_work(
        self,
        dynamic_work_pipeline,
        dynamic_work_idx_ptr,
        dynamic_work_consumer_state,
    ):
        dynamic_work_pipeline.consumer_wait(dynamic_work_consumer_state)
        work_tile = fmha_utils.fmha_work_tile_info_from_dynamic_response(
            dynamic_work_idx_ptr + dynamic_work_consumer_state.index * 4
        )
        dynamic_work_pipeline.consumer_release(dynamic_work_consumer_state)
        dynamic_work_consumer_state.advance()
        return work_tile, dynamic_work_consumer_state

    def _unpack_q_mixed_args(self, arch_args):
        """(qk_tiled_mma_tmem, q_mixed_smem_layout_staged, q_mixed_tmem_layout)."""
        return arch_args[0], arch_args[1], arch_args[2]

    def _unpack_rowsum_args(self, arch_args):
        """(rowsum_tiled_mma, rowsum_ones_smem_layout_staged)."""
        base = 3 if self.enable_q_mixed_residency else 0
        return arch_args[base], arch_args[base + 1]

    def _make_arch_kernel_spec(self, cta_group, qk_tiled_mma):
        kernel_args = ()
        scratch_cosize, scratch_align = 0, 1
        if self.enable_q_mixed_residency:
            qk_tiled_mma_tmem = self._make_qk_tmem_tiled_mma(cta_group)
            q_mixed_phase_tiler = (
                self.qk_mma_tiler[0],
                self.qk_mma_tiler[1],
                self.q_mixed_phase_dim,
            )
            q_mixed_smem_layout_staged = sm100_utils.make_smem_layout_a(
                qk_tiled_mma,
                q_mixed_phase_tiler,
                self.q_dtype,
                self.q_stage * self.q_mixed_total_kphases,
            )
            q_mixed_smem_layout_staged = cute.logical_divide(
                q_mixed_smem_layout_staged,
                (None, None, None, self.q_mixed_total_kphases),
            )
            q_mixed_tmem_layout_staged = sm100_utils.make_smem_layout_a(
                qk_tiled_mma_tmem,
                q_mixed_phase_tiler,
                self.q_dtype,
                self.q_stage * self.q_mixed_tmem_kphases,
            )
            q_mixed_tmem_layout_staged = cute.logical_divide(
                q_mixed_tmem_layout_staged,
                (None, None, None, self.q_mixed_tmem_kphases),
            )
            kernel_args += (
                qk_tiled_mma_tmem,
                q_mixed_smem_layout_staged,
                q_mixed_tmem_layout_staged.outer,
            )
        if self.enable_mma_rowsum:
            rowsum_tiled_mma = self._make_rowsum_tiled_mma(cta_group)
            rowsum_ones_smem_layout_staged = sm100_utils.make_smem_layout_b(
                rowsum_tiled_mma,
                self.rowsum_mma_tiler,
                self.v_dtype,
                1,
            )
            kernel_args += (rowsum_tiled_mma, rowsum_ones_smem_layout_staged)
            scratch_cosize = cute.cosize(rowsum_ones_smem_layout_staged)
            scratch_align = 128
        return kernel_args, scratch_cosize, scratch_align

    @cute.jit
    def _make_arch_smem_views(self, storage, arch_args):
        sQ_mixed = None
        sRowsumOnes = None
        if cutlass.const_expr(self.enable_q_mixed_residency):
            _, q_mixed_smem_layout_staged, _ = self._unpack_q_mixed_args(arch_args)
            sQ_mixed = storage.sQ.get_tensor(
                q_mixed_smem_layout_staged.outer,
                swizzle=q_mixed_smem_layout_staged.inner,
            )
        if cutlass.const_expr(self.enable_mma_rowsum):
            _, rowsum_ones_smem_layout_staged = self._unpack_rowsum_args(arch_args)
            sRowsumOnes = storage.sArchScratch.get_tensor(
                rowsum_ones_smem_layout_staged.outer,
                swizzle=rowsum_ones_smem_layout_staged.inner,
            )
        return (sQ_mixed, sRowsumOnes)

    @cute.jit
    def _init_arch_smem_operands(self, arch_smem, warp_idx, tidx):
        if cutlass.const_expr(self.enable_mma_rowsum):
            _, sRowsumOnes = arch_smem
            # N=8 is the minimum Rubin FP8 MMA shape. The hardware reads the
            # complete B operand even though only its first output column is
            # consumed, so every column must contain initialized data.
            lane_idx = tidx % self.threads_per_warp
            if warp_idx == self.empty_warp_id:
                vec_one = cute.make_rmem_tensor(
                    (32 // self.v_dtype.width,), self.v_dtype
                )
                vec_one.fill(self.v_dtype(1))
                for col_idx in cutlass.range_constexpr(self.rowsum_mma_tiler[1]):
                    ones_col = sRowsumOnes[(col_idx, None), 0, 0, 0]
                    ones_col = cute.zipped_divide(ones_col, vec_one.shape)
                    num_vec = cute.size(ones_col.shape[1])
                    for i in cutlass.range_constexpr(0, num_vec, self.threads_per_warp):
                        if i + lane_idx < num_vec:
                            ones_col[None, i + lane_idx].store(vec_one.load())
            # The pipeline-init barrier does not order ordinary shared-memory
            # stores. Publish the ones tile before the MMA warp can use it.
            cute.arch.sync_threads()

    @cute.jit
    def _make_rowsum_tmem_views(self, rowsum_tiled_mma, tmem_ptr):
        """Per-stage TMEM views of the persistent row-sum accumulators."""
        rowsum_thr_mma = rowsum_tiled_mma.get_slice(0)
        rowsum_acc_shape = rowsum_thr_mma.partition_shape_C(self.rowsum_mma_tiler[:2])
        tCtRowsum = rowsum_thr_mma.make_fragment_C(rowsum_acc_shape)
        tCtRowsum = tCtRowsum[None, 0, 0]
        tCtRowsum0 = cute.make_tensor(
            tmem_ptr + self.tmem_rowsum0_offset, tCtRowsum.layout
        )
        tCtRowsum1 = cute.make_tensor(
            tmem_ptr + self.tmem_rowsum1_offset, tCtRowsum.layout
        )
        return tCtRowsum0, tCtRowsum1

    @cute.jit
    def _make_mma_warp_arch_state(self, arch_smem, arch_args, tmem_ptr):
        tTrQ_tmem = None
        s2t_tiled_copy_q = None
        tCsQ_s2t = None
        tCtQ_s2t = None
        qk_tiled_mma_tmem = None
        if cutlass.const_expr(self.enable_q_mixed_residency):
            sQ_mixed, _ = arch_smem
            qk_tiled_mma_tmem, _, q_mixed_tmem_layout = self._unpack_q_mixed_args(
                arch_args
            )
            tQ_tmem = cute.make_tensor(
                cute.recast_ptr(
                    tmem_ptr + self.tmem_q_latent_offset,
                    dtype=self.q_dtype,
                ),
                q_mixed_tmem_layout,
            )
            tTrQ_fake = qk_tiled_mma_tmem.make_fragment_A(tQ_tmem)
            tTrQ_tmem = cute.make_tensor(tQ_tmem.iterator, tTrQ_fake.layout)
            s2t_tiled_copy_q, tCsQ_s2t, tCtQ_s2t = self._s2t_copy_and_partition(
                sQ_mixed, tTrQ_tmem
            )
        rowsum_tiled_mma = None
        tCtRowsum0 = None
        tCtRowsum1 = None
        tBsRowsum_desc = None
        if cutlass.const_expr(self.enable_mma_rowsum):
            _, sRowsumOnes = arch_smem
            rowsum_tiled_mma, _ = self._unpack_rowsum_args(arch_args)
            tCtRowsum0, tCtRowsum1 = self._make_rowsum_tmem_views(
                rowsum_tiled_mma, tmem_ptr
            )
            tBsRowsum_desc = rowsum_tiled_mma.make_fragment_B(sRowsumOnes)
            tBsRowsum_desc = tBsRowsum_desc[None, 0, 0, 0]
        return (
            tTrQ_tmem,
            s2t_tiled_copy_q,
            tCsQ_s2t,
            tCtQ_s2t,
            qk_tiled_mma_tmem,
            rowsum_tiled_mma,
            tCtRowsum0,
            tCtRowsum1,
            tBsRowsum_desc,
        )

    @cute.jit
    def _stage_arch_q_operand(self, arch_state, q_index, q_slot):
        if cutlass.const_expr(self.enable_q_mixed_residency):
            num_cached_kphases = (
                self.q0_mixed_tmem_kphases
                if q_slot == 0
                else self.q1_mixed_tmem_kphases
            )
            self._copy_q_latent_to_tmem(
                arch_state[1],  # s2t_tiled_copy_q
                arch_state[2],  # tCsQ_s2t
                arch_state[3],  # tCtQ_s2t
                q_index,
                num_cached_kphases,
            )

    @cute.jit
    def _mma_qk_step(
        self,
        tiled_mma,
        tensor_args,
        pipeline_args,
        arch_state,
        q_slot,
        q_index,
    ):
        if cutlass.const_expr(self.enable_q_mixed_residency):
            tSrQi, tSrKi, tStSi = tensor_args
            tTrQ_tmem = arch_state[0]
            qk_tiled_mma_tmem = arch_state[4]
            num_cached_kphases = (
                self.q0_mixed_tmem_kphases
                if q_slot == 0
                else self.q1_mixed_tmem_kphases
            )
            return self.mma_qk_mixed(
                tiled_mma,
                qk_tiled_mma_tmem,
                (tSrQi, tTrQ_tmem, q_index, tSrKi, tStSi),
                pipeline_args,
                num_cached_kphases,
            )
        return BlackwellFusedMultiHeadAttentionForward._mma_qk_step(
            self, tiled_mma, tensor_args, pipeline_args, arch_state, q_slot, q_index
        )

    @cute.jit
    def _mma_pv_step(
        self,
        tiled_mma,
        whether_acc,
        tensor_args,
        pipeline_args,
        skip_pv_args,
        arch_state,
        o_slot,
    ):
        if cutlass.const_expr(self.enable_mma_rowsum):
            tOrPi, tOrVi, tOtOi = tensor_args
            mma_corr_producer, pi_mma_consumer = pipeline_args
            (
                enable_skip_softmax,
                tiled_tmem_load_v,
                tTMEM_LOADtS_v,
                tTMEM_LOADrS_v,
            ) = skip_pv_args
            rowsum_tiled_mma = arch_state[5]
            tCtRowsum = arch_state[6] if o_slot == 0 else arch_state[7]
            tBsRowsum = arch_state[8]
            # 1. acquire Oi
            oi_handle = mma_corr_producer.acquire_and_advance()
            # 2. wait for Pi
            pi_handle = pi_mma_consumer.wait_and_advance()
            # 3. gemm: interleave PV and P-times-ones for each K64 phase.
            # Keeping P in the A collector across each pair avoids an extra
            # TMEM read.
            num_kphases = cute.size(tOrPi, mode=[2])
            assert num_kphases == 2
            pv_k0 = fmha_utils.with_collector_op(
                tiled_mma,
                tcgen05.CollectorOp.FILL,
                tcgen05.CollectorOp.DISCARD,
            )
            rowsum_k0 = fmha_utils.with_collector_op(
                rowsum_tiled_mma,
                tcgen05.CollectorOp.LASTUSE,
                tcgen05.CollectorOp.FILL,
            )
            rowsum_k1 = fmha_utils.with_collector_op(
                rowsum_tiled_mma,
                tcgen05.CollectorOp.FILL,
                tcgen05.CollectorOp.LASTUSE,
            )
            pv_k1 = fmha_utils.with_collector_op(
                tiled_mma,
                tcgen05.CollectorOp.LASTUSE,
                tcgen05.CollectorOp.DISCARD,
            )
            pv_k0.set(tcgen05.Field.ACCUMULATE, whether_acc)
            rowsum_k0.set(tcgen05.Field.ACCUMULATE, whether_acc)
            rowsum_k1.set(tcgen05.Field.ACCUMULATE, True)
            pv_k1.set(tcgen05.Field.ACCUMULATE, True)

            skip_pv = False
            if cutlass.const_expr(enable_skip_softmax):
                skip_pv = self.get_skip_softmax_flag(
                    tiled_tmem_load_v, tTMEM_LOADtS_v, tTMEM_LOADrS_v
                )
            if not skip_pv:
                cute.gemm(
                    pv_k0,
                    tOtOi,
                    tOrPi[None, None, 0],
                    tOrVi[None, None, 0],
                    tOtOi,
                )
                cute.gemm(
                    rowsum_k0,
                    tCtRowsum,
                    tOrPi[None, 0, 0],
                    tBsRowsum,
                    tCtRowsum,
                )
                cute.gemm(
                    rowsum_k1,
                    tCtRowsum,
                    tOrPi[None, 0, 1],
                    tBsRowsum,
                    tCtRowsum,
                )
                cute.gemm(
                    pv_k1,
                    tOtOi,
                    tOrPi[None, None, 1],
                    tOrVi[None, None, 1],
                    tOtOi,
                )
            # 4. commit Pi
            pi_handle.release()
            # 5. commit Oi
            oi_handle.commit()
            return mma_corr_producer, pi_mma_consumer
        return BlackwellFusedMultiHeadAttentionForward._mma_pv_step(
            self,
            tiled_mma,
            whether_acc,
            tensor_args,
            pipeline_args,
            skip_pv_args,
            arch_state,
            o_slot,
        )

    @cute.jit
    def _make_correction_arch_state(self, arch_args, tmem_ptr, thread_idx):
        if cutlass.const_expr(not self.enable_mma_rowsum):
            return None
        rowsum_tiled_mma, _ = self._unpack_rowsum_args(arch_args)
        tCtRowsum0, tCtRowsum1 = self._make_rowsum_tmem_views(
            rowsum_tiled_mma, tmem_ptr
        )
        cRowsum = cute.make_identity_tensor(tCtRowsum0.shape)
        rowsum_tmem_load_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(1)),
            self.pv_acc_dtype,
        )
        rowsum_tmem_store_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(1)),
            self.pv_acc_dtype,
        )
        tiled_tmem_load_rowsum = tcgen05.make_tmem_copy(
            rowsum_tmem_load_atom, tCtRowsum0
        )
        tiled_tmem_store_rowsum = tcgen05.make_tmem_copy(
            rowsum_tmem_store_atom, tCtRowsum0
        )
        thr_tmem_load_rowsum = tiled_tmem_load_rowsum.get_slice(thread_idx)
        thr_tmem_store_rowsum = tiled_tmem_store_rowsum.get_slice(thread_idx)
        return (
            tiled_tmem_load_rowsum,
            tiled_tmem_store_rowsum,
            thr_tmem_load_rowsum.partition_S(tCtRowsum0),
            thr_tmem_load_rowsum.partition_S(tCtRowsum1),
            thr_tmem_load_rowsum.partition_D(cRowsum),
            thr_tmem_store_rowsum.partition_D(tCtRowsum0),
            thr_tmem_store_rowsum.partition_D(tCtRowsum1),
        )

    def check_supported_dtypes(
        self,
        qk_dtype: Type[cutlass.Numeric],
        pv_dtype: Type[cutlass.Numeric],
        out_dtype: Type[cutlass.Numeric],
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
    ):
        if self.enable_fp16_mixed_softmax and (
            qk_dtype is not cutlass.Float8E4M3FN or pv_dtype is not cutlass.Float8E4M3FN
        ):
            raise testing.CantImplementError(
                "Rubin FP16 mixed softmax requires Float8E4M3FN Q/K and P/V"
            )
        # TODO: extend the input dtype set to Float16/BFloat16 (matching the
        # Blackwell kernel) once utils.sm107.make_trivial_tiled_mma supports them.
        supported_input_dtypes = {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        if qk_dtype not in supported_input_dtypes:
            raise testing.CantImplementError(
                f"Unsupported qk_dtype on Rubin SM107: {qk_dtype} "
                "(only Float8E4M3FN / Float8E5M2 are supported)"
            )
        if pv_dtype not in supported_input_dtypes:
            raise testing.CantImplementError(
                f"Unsupported pv_dtype on Rubin SM107: {pv_dtype} "
                "(only Float8E4M3FN / Float8E5M2 are supported)"
            )
        # The output is produced from the FP32 accumulator via the epilogue's
        # narrow-precision cast, so the out_dtype is independent of the MMA
        # atom and matches the Blackwell-supported set plus Float8E5M2.
        if out_dtype not in {
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float4E2M1FN,
            cutlass.Float16,
            cutlass.BFloat16,
        }:
            raise testing.CantImplementError(
                f"Unsupported out_dtype on Rubin SM107: {out_dtype}"
            )
        if qk_acc_dtype is not cutlass.Float32:
            raise testing.CantImplementError("Unsupported qk_acc_dtype on Rubin SM107")
        if pv_acc_dtype is not cutlass.Float32:
            raise testing.CantImplementError("Unsupported pv_acc_dtype on Rubin SM107")
        if self.enable_q_mixed_residency and qk_dtype is not cutlass.Float8E4M3FN:
            raise testing.CantImplementError(
                "Q mixed residency requires qk_dtype=Float8E4M3FN"
            )
        if self.head_dim == self._HEAD_DIM_72:
            if (
                qk_dtype is not cutlass.Float8E4M3FN
                or pv_dtype is not cutlass.Float8E4M3FN
            ):
                raise testing.CantImplementError(
                    "logical D72 currently supports Float8E4M3FN input only"
                )
            if out_dtype not in {
                cutlass.Float8E4M3FN,
                cutlass.Float4E2M1FN,
                cutlass.BFloat16,
            }:
                raise testing.CantImplementError(
                    "logical D72 currently supports Float8E4M3FN, "
                    "Float4E2M1FN, and BFloat16 output only"
                )

    def check_invalid_shape(
        self,
        qk_dtype: Type[cutlass.Numeric],
        q_shape: Tuple[int, int, int, int],
        k_shape: Tuple[int, int, int, int],
    ):
        super().check_invalid_shape(qk_dtype, q_shape, k_shape)
        if self.enable_q_mixed_residency and (
            q_shape[3] not in (32, 64, 128, 192)
            or (q_shape[3] == 192 and self.head_dim_v != 128)
            or (q_shape[3] != 192 and self.head_dim_v != q_shape[3])
        ):
            raise testing.CantImplementError(
                "Q mixed residency requires head dimension 32/64/128 or MLA (192, 128)"
            )
        if self.enable_q_mixed_residency and self.qk_mma_tiler[:2] != (128, 128):
            raise testing.CantImplementError(
                "Q mixed residency requires mma_tiler_mn 128,128"
            )


def run(
    *args,
    enable_q_mixed_residency: bool = False,
    enable_fp16_mixed_softmax: bool = False,
    enable_mma_rowsum: bool = False,
    **kwargs,
):
    """Execute FMHA on Rubin with Rubin-tuned frontend defaults."""
    kwargs.setdefault("fmha_class", RubinFusedMultiHeadAttentionForward)
    # Rubin's tuned schedules (merged softmax, MMA row sum, Q residency)
    # were validated with the TMA output store; keep it the default here.
    if kwargs.get("use_tma_store") is None:
        kwargs["use_tma_store"] = True
    kwargs.setdefault("merge_softmax_warp_groups", True)
    kwargs["fmha_arch_kwargs"] = dict(
        enable_q_mixed_residency=enable_q_mixed_residency,
        enable_fp16_mixed_softmax=enable_fp16_mixed_softmax,
        enable_mma_rowsum=enable_mma_rowsum,
    )
    return blackwell_run(*args, **kwargs)


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str):
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    def parse_nested_comma_separated_ints(s: str):
        try:
            s = s.strip()
            if "(" not in s:
                return tuple(int(x.strip()) for x in s.split(","))

            start = s.find("(")
            end = s.find(")")
            if start == -1 or end == -1:
                raise ValueError("Mismatched parentheses")

            before = s[:start].strip().rstrip(",")
            middle = s[start + 1 : end].strip()
            after = s[end + 1 :].strip().lstrip(",")

            result = []
            if before:
                result.extend(int(x.strip()) for x in before.split(","))
            if middle:
                result.append(tuple(int(x.strip()) for x in middle.split(",")))
            if after:
                result.extend(int(x.strip()) for x in after.split(","))
            return tuple(result)

        except ValueError as e:
            if str(e) == "Mismatched parentheses":
                raise argparse.ArgumentTypeError("Mismatched parentheses in input")
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers with optional parentheses for nested tuple."
            )

    parser = argparse.ArgumentParser(description="Example of FMHA on Rubin.")

    parser.add_argument(
        "--in_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Input data type for Q, K, and V (overridden per-operand by --qk_dtype/--pv_dtype)",
    )
    parser.add_argument(
        "--qk_dtype",
        type=cutlass.dtype,
        default=None,
        help="Input data type for Q and K (Bmm1); defaults to --in_dtype if not set",
    )
    parser.add_argument(
        "--pv_dtype",
        type=cutlass.dtype,
        default=None,
        help="Input data type for P and V (Bmm2); defaults to --in_dtype if not set",
    )
    parser.add_argument(
        "--out_dtype",
        type=cutlass.dtype,
        default=cutlass.Float8E4M3FN,
        help="Output data type",
    )
    parser.add_argument(
        "--qk_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="QK accumulator data type",
    )
    parser.add_argument(
        "--pv_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="PV accumulator data type",
    )
    parser.add_argument(
        "--mma_tiler_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="MMA tile shape (M, N)",
    )
    parser.add_argument(
        "--enable_skip_correction",
        action="store_true",
        default=False,
        help="Enable skip correction",
    )
    parser.add_argument(
        "--enable_q_mixed_residency",
        action="store_true",
        default=False,
        help=(
            "Cache Q K-phases in TMEM (requires FP8 E4M3 and head dimension "
            "32/64/128 or MLA 192; Q0 keeps up to two phases and Q1 one)"
        ),
    )
    parser.add_argument(
        "--enable_fp16_mixed_softmax",
        action="store_true",
        default=False,
        help=(
            "Use packed-FP16 exp2 while retaining FP32 QK/PV accumulators, "
            "online correction, and row sums"
        ),
    )
    parser.add_argument(
        "--enable_mma_rowsum",
        action="store_true",
        default=False,
        help=(
            "Accumulate the online row sum with a P-times-ones MMA in TMEM "
            "instead of the packed-ALU chain (FP8 E4M3, 128x128 tile, "
            "dv <= 128). Off by default until the FP8 row-sum accuracy is "
            "validated."
        ),
    )
    parser.add_argument(
        "--rescale_threshold",
        type=float,
        help="Canonical correction-skip threshold (default: 8)",
    )
    parser.add_argument(
        "--skip_correction_threshold",
        type=float,
        help="Compatibility alias for --rescale_threshold",
    )
    parser.add_argument("--is_persistent", action="store_true", help="Is persistent")
    parser.add_argument(
        "--persistent_raster_order",
        choices=("mhb", "compact"),
        help=(
            "Persistent work-index order: compact enumerates only valid ragged "
            "Q tiles; mhb preserves the historical M-fastest order "
            "(default: shape-tuned automatic choice)"
        ),
    )
    parser.add_argument(
        "--persistent_work_scheduler",
        choices=("static", "dynamic"),
        help=(
            "Compact persistent scheduler: static CTA-strided work indices or the "
            "dynamic one-stage global work-index queue "
            "(default: shape-tuned automatic choice)"
        ),
    )
    parser.add_argument(
        "--use_clc_scheduler",
        action="store_true",
        help="Use hardware CLC work indices for paged GQA",
    )
    parser.add_argument(
        "--is_causal", action="store_true", help="Whether to use causal mask"
    )
    parser.add_argument(
        "--bottom_right_align",
        action="store_true",
        help="Whether to use bottom right align (end of q is aligned with end of k).",
    )
    parser.add_argument(
        "--lse_calculation", action="store_true", help="Whether to calculate lse"
    )
    parser.add_argument(
        "--enable_sink",
        action="store_true",
        default=False,
        help="Enable sink token support, adding sink contribution to softmax denominator",
    )
    parser.add_argument(
        "--window_size",
        type=parse_comma_separated_ints,
        default=(-1, -1),
        help="Sliding window size (left, right) for attention masking.",
    )
    parser.add_argument(
        "--q_shape",
        type=parse_nested_comma_separated_ints,
        default=(4, 1024, 8, 192),
        help="Shape of Q (B, S_q, H, D)",
    )
    parser.add_argument(
        "--k_shape",
        type=parse_nested_comma_separated_ints,
        default=(4, 1024, 1, 192),
        help="Shape of K (B, S_k, H_k, D)",
    )
    parser.add_argument(
        "--packed_buffer_capacity",
        type=int,
        help="Physical token capacity shared by packed Q and K/V buffers",
    )
    output_store_group = parser.add_mutually_exclusive_group()
    output_store_group.add_argument(
        "--use_tma_store",
        action="store_true",
        help="Store O through TMA descriptors (the Rubin default)",
    )
    output_store_group.add_argument(
        "--use_direct_store",
        dest="use_tma_store",
        action="store_false",
        help="Store O through the bounds-checked direct epilogue",
    )
    parser.set_defaults(use_tma_store=None)
    parser.add_argument(
        "--max_seqlen_q",
        type=int,
        help=(
            "Optional Q sequence-length capacity/dispatch upper bound; "
            "must cover actual lengths but does not enlarge the current problem"
        ),
    )
    parser.add_argument(
        "--max_seqlen_k",
        type=int,
        help=(
            "Optional K/V sequence-length capacity/dispatch upper bound; "
            "must cover actual lengths but does not enlarge the current problem"
        ),
    )
    parser.add_argument(
        "--scale_q", type=float, default=1.0, help="Scaling factor to dequantize Q"
    )
    parser.add_argument(
        "--scale_k", type=float, default=1.0, help="Scaling factor to dequantize K"
    )
    parser.add_argument(
        "--scale_v", type=float, default=1.0, help="Scaling factor to dequantize V"
    )
    parser.add_argument(
        "--inv_scale_o", type=float, default=1.0, help="Scaling factor to quantize O"
    )
    parser.add_argument(
        "--scale_softmax",
        type=float,
        default=0.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
    )
    parser.add_argument(
        "--skip_softmax_threshold",
        type=float,
        default=None,
        help="Skip softmax and PV on a tile if e^(max(S tile) - old_max(S tile)) <= threshold",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of iterations for warmup",
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations after warmup"
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference check"
    )
    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )
    parser.add_argument(
        "--stats_skip_softmax_ratio",
        action="store_true",
        default=False,
        help="Stats skip softmax ratio, used to print the skip softmax ratio (debugging).",
    )
    parser.add_argument(
        "--use_pdl",
        action="store_true",
        default=False,
        help="Enable PDL (Programmatic Dependent Launch) for kernel launch",
    )
    launch_group = parser.add_mutually_exclusive_group()
    launch_group.add_argument(
        "--use_cluster_launch",
        action="store_true",
        help="Use the CUDA cluster launch path",
    )
    launch_group.add_argument(
        "--use_legacy_launch",
        dest="use_cluster_launch",
        action="store_false",
        help="Use the legacy CUDA kernel launch path",
    )
    # ``None`` selects the shape-tuned launch default in the run extension.
    parser.set_defaults(use_cluster_launch=None)
    parser.add_argument(
        "--use_paged_kv",
        action="store_true",
        help="Read K/V through a logical-to-physical page table",
    )
    parser.add_argument(
        "--page_size",
        type=int,
        default=128,
        help="Number of KV tokens in each physical page",
    )
    parser.add_argument(
        "--paged_kv_layout",
        choices=tuple(sorted(_PAGED_KV_LAYOUTS)),
        default="separate_nhd",
        help="Paged-KV storage contract (default: separate_nhd)",
    )
    parser.add_argument(
        "--o_sf_scale",
        type=float,
        help=(
            "NVFP4 output scale constant. Required when "
            "--out_dtype Float4E2M1FN; one E4M3 scale is emitted per 16 values"
        ),
    )
    parser.add_argument(
        "--o_sf_start_index",
        type=int,
        default=0,
        help="Starting token row in the NVFP4 Layout128x4 scale buffer",
    )

    parser.add_argument(
        "--page_table_order",
        choices=("reverse", "identity"),
        default="reverse",
        help="Generated paged-KV physical page assignment",
    )
    seq_barrier_group = parser.add_mutually_exclusive_group()
    seq_barrier_group.add_argument(
        "--enable_sequence_barrier",
        action="store_true",
        help="Build a Rubin variant with the softmax sequence barrier "
        "(architecture default)",
    )
    seq_barrier_group.add_argument(
        "--disable_sequence_barrier",
        dest="enable_sequence_barrier",
        action="store_false",
        help="Build a Rubin variant without the softmax sequence barrier",
    )
    parser.set_defaults(enable_sequence_barrier=None)

    softmax_wg_group = parser.add_mutually_exclusive_group()
    softmax_wg_group.add_argument(
        "--merge_softmax_warp_groups",
        dest="merge_softmax_warp_groups",
        action="store_true",
        help=(
            "Share one runtime-selected body between the two softmax warp "
            "groups (default)"
        ),
    )
    softmax_wg_group.add_argument(
        "--static_softmax_warp_groups",
        dest="merge_softmax_warp_groups",
        action="store_false",
        help="Keep two statically specialized softmax warp-group bodies",
    )
    # ``None`` selects the architecture default (merged on sm_103 and later).
    parser.set_defaults(merge_softmax_warp_groups=None)

    args = parser.parse_args()

    if len(args.q_shape) != 4:
        parser.error("--q_shape must contain exactly 4 values")
    if len(args.k_shape) != 4:
        parser.error("--k_shape must contain exactly 4 values")
    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    qk_dtype = args.qk_dtype if args.qk_dtype is not None else args.in_dtype
    pv_dtype = args.pv_dtype if args.pv_dtype is not None else args.in_dtype

    run(
        args.q_shape,
        args.k_shape,
        qk_dtype,
        pv_dtype,
        args.out_dtype,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.mma_tiler_mn,
        False,
        args.enable_skip_correction,
        args.is_persistent,
        args.is_causal,
        args.bottom_right_align,
        args.lse_calculation,
        args.window_size,
        args.scale_q,
        args.scale_k,
        args.scale_v,
        args.inv_scale_o,
        args.scale_softmax,
        args.skip_softmax_threshold,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
        args.stats_skip_softmax_ratio,
        args.enable_sink,
        args.use_pdl,
        enable_q_mixed_residency=args.enable_q_mixed_residency,
        enable_fp16_mixed_softmax=args.enable_fp16_mixed_softmax,
        enable_mma_rowsum=args.enable_mma_rowsum,
        merge_softmax_warp_groups=args.merge_softmax_warp_groups,
        packed_buffer_capacity=args.packed_buffer_capacity,
        use_tma_store=args.use_tma_store,
        use_paged_kv=args.use_paged_kv,
        page_size=args.page_size,
        paged_kv_layout=args.paged_kv_layout,
        page_table_order=args.page_table_order,
        max_seqlen_q=args.max_seqlen_q,
        max_seqlen_k=args.max_seqlen_k,
        rescale_threshold=args.rescale_threshold,
        skip_correction_threshold=args.skip_correction_threshold,
        use_cluster_launch=args.use_cluster_launch,
        use_clc_scheduler=args.use_clc_scheduler,
        persistent_raster_order=args.persistent_raster_order,
        persistent_work_scheduler=args.persistent_work_scheduler,
    )

    print("PASS")
