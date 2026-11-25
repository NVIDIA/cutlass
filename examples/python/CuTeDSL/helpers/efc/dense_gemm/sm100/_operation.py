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

import types
import typing

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
import cutlass.utils as utils
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
from cutlass.utils.gemm.sm100 import transform_partitioned_tensor_layout
from cutlass.cute.nvgpu import cpasync, tcgen05

import helpers.efc as common_efc
from helpers.efc import (
    Transport,
    if_debug,
    log,
    mark_mlir,
    trace_in_mlir,
)
from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)

from . import _helpers
from .._operation import _DenseGemmEFCKernelBase

"""
Common base infrastructure for high-performance persistent batched dense GEMM with custom epilogue fusion
for the NVIDIA Blackwell SM100 architecture using CUTE DSL and Epilogue Fusion Configuration (EFC).

This module provides the DenseGemmEFC base class that implements the core GEMM functionality with
support for custom epilogue operations. Subclasses define specific epilogue configurations by
providing an epilogue function that operates on the accumulator and supplemental tensors.

Key Features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations (including 2CTA MMA instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Supports persistent tile scheduling to better overlap memory load/store with MMA across tiles
    - Supports warp specialization to avoid explicit pipelining between mainloop load and MMA
    - Uses Epilogue Fusion Configuration (EFC) to define custom epilogue operations

GEMM Execution Flow:
1. DMA warp: Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp: Perform matrix multiply-accumulate (MMA) operations using tcgen05.mma instruction.
3. EPILOGUE warp (customizable via EFC):
    - Load completed accumulator from tensor memory (TMEM) to registers (RMEM) using tcgen05.ld.
    - Load supplemental input tensors from GMEM to SMEM using TMA, then to RMEM.
    - Execute custom epilogue function (defined by subclass) that:
      * Accesses the accumulator via efc_config.accum()
      * Reads from supplemental input tensors via tensor.load()
      * Writes to supplemental output tensors via tensor.store()
      * Can apply arbitrary element-wise operations, scaling, and fusion
    - Store result tensors from RMEM to SMEM to GMEM with TMA operations.

SM100 tcgen05.mma instructions operate as follows:
- Read matrix A from SMEM
- Read matrix B from SMEM
- Write accumulator to TMEM
The accumulator in TMEM must then be loaded to registers before writing back to GMEM.

Base Tensor Dimensions:
- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Supplemental tensors are MxNxL with layout matching the epilogue configuration

Block-Scaled (MX) Operands:
- ``DenseGemmEFCBlockScaled`` (``_blockscaled.py``) turns on ``has_scale_factors``:
  A/B are fp8 and each comes with an E8M0 scale-factor tensor (SFA for A, SFB
  for B; one scale per ``sf_vec_size`` K elements) in the tcgen05 scale-factor
  atom layout (``blockscaled_utils.tile_atom_to_shape_SF``).  The TMA warp
  stages SFA/SFB with A/B on the same pipeline stage and barrier, the MMA warp
  copies them SMEM->TMEM (``tcgen05.cp``) right before the MMAs that read them,
  and the block-scaled MMA dequantizes while accumulating.  The epilogue sees
  the dequantized accumulator, so the EFC surface is unchanged.  TMEM holds the
  accumulator stages first, then SFA, then SFB; ``compute_stages`` fits the
  accumulator stages next to those columns.  SFB is staged in whole 128-row
  atoms, so tile N=64 and N=192 share one staged window between neighbouring N
  tiles (see the TMA and MMA warps).  Every scale-factor code path is pruned by
  ``const_expr(self.has_scale_factors)`` when the flag is off.

Common Constraints:
* Supported input data types: fp16, bf16, tf32, int8, uint8, fp8 (e4m3fn, e5m2)
* A/B tensors must have the same data type
* MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* MMA tiler N must be 32-256, step 32
* Block-scaled operations (``_blockscaled.py``) narrow this: fp8 A/B only, tiler
  M = the instruction M (2x under Rubin Bkeep-Breuse), tile N in {64, 128, 192, 256}
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of all tensors must be at least 16 bytes aligned,
  i.e., number of elements is a multiple of 4, 8, and 16 for TFloat32,
  Float16/BFloat16, and Int8/Uint8/Float8, respectively.
* Partial tiles are supported: TMA clips the staged tensors and the direct
  tensors are predicated against the output shape

Subclass Examples:
- custom_epilogue_dense_gemm.py: Custom fused epilogue with multiple read/write tensors
- broadcast_custom_epilogue_dense_gemm.py: Broadcasting and mode remapping with transposed tensors
- activation_custom_epilogue_dense_gemm.py: Activation functions with Ada FP8 GEMM epilogue pattern
- synthetic_custom_epilogue_dense_gemm.py: Synthetic epilogue for testing with configurable tensor counts

Writing an Epilogue Function (EFC User Guide)
==============================================

The Epilogue Fusion Configuration (EFC) lets you define custom epilogue
operations as a plain Python function. The framework analyzes the
function signature, JIT-compiles it for the GPU kernel, and also
executes it on the CPU with PyTorch for automatic verification.

Function Signature
------------------

The epilogue function must follow this contract:

    def epilogue(efc_config, <parameter_1>, <parameter_2>, ...):
        ...

- The first parameter **must** be named ``efc_config``. It is an
  ``EFC.Configuration`` instance that provides access to the GEMM
  accumulator, activation functions, and mode remapping.
- The remaining parameters are user-defined. Their names must match
  the supplemental arguments passed to the GEMM ``compile()`` call.
- **Tensor** parameters correspond to ``cutlass.cute.Tensor`` values
  and support ``.load()`` / ``.store()`` operations.
- **Scalar** parameters (``float``, ``int``, etc.) are used directly
  in arithmetic expressions without ``.load()``.
- The function does **not** return a value. Results are written via
  ``.store()`` on tensor parameters.  At least one ``.store()`` call
  is required for a useful computation.

Accessing the Accumulator
~~~~~~~~~~~~~~~~~~~~~~~~~

``efc_config.accum()`` returns the GEMM accumulator (the result of
A * B). It can be called multiple times within the same epilogue::

    def epilogue(efc_config, D):
        D.store(efc_config.accum())

Loading and Storing Tensors
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Tensor parameters expose two operations:

- ``tensor.load()`` — reads the tensor value (marks it as an input).
- ``tensor.store(value)`` — writes a computed value (marks it as an output).

A tensor can be both loaded and stored (read-modify-write). When
using multiple tensors, all ``.load()`` calls should be issued before
any ``.store()`` calls::

    def epilogue(efc_config, C, D, alpha, beta):
        D.store(efc_config.accum() * alpha + C.load() * beta)

Activation Functions
~~~~~~~~~~~~~~~~~~~~

The ``efc_config`` object provides built-in activation functions:

- ``efc_config.identity(x)`` — f(x) = x
- ``efc_config.relu(x)`` — f(x) = max(0, x)
- ``efc_config.leaky_relu(x, negative_slope=0.01)``
- ``efc_config.tanh(x)``
- ``efc_config.sigmoid(x)`` — f(x) = 1 / (1 + exp(-x))
- ``efc_config.silu(x)`` — f(x) = x * sigmoid(x) (Swish)
- ``efc_config.hardswish(x)`` — f(x) = x * relu6(x + 3) / 6
- ``efc_config.gelu(x)``

Example::

    def epilogue(efc_config, C, D, alpha, beta):
        D.store(efc_config.relu(efc_config.accum() * alpha + C.load() * beta))

Element-wise Utilities
~~~~~~~~~~~~~~~~~~~~~~

- ``efc_config.maximum(x, y)`` — element-wise maximum
- ``efc_config.minimum(x, y)`` — element-wise minimum

Additionally, any method called on ``efc_config`` that is not
explicitly defined is dispatched to ``cutlass.cute.<name>()`` on GPU
and ``torch.<name>()`` during PyTorch verification. This gives access
to functions like ``efc_config.abs(x)``, ``efc_config.exp(x)``,
``efc_config.sqrt(x)``, ``efc_config.clamp(x, min, max)``,
``efc_config.full_like(x, value)``, etc.

Broadcasting and Mode Remapping
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When supplemental tensors have fewer dimensions or a different mode
ordering than the output tensor, use ``tensor.remap_modes[...]`` to
broadcast or transpose them::

    tensor.remap_modes[<subscript>]

The target shape is implicitly the output shape ``(m, n, l)`` derived
from the GEMM input matrices ``A(m, k, l)`` and ``B(n, k, l)``.

The subscript uses Python's ``__getitem__`` syntax where each element
is either:

- An **integer** — the index of the source mode to place at this
  position.
- ``:`` — broadcast the source along this dimension (stride 0).

The returned remapped tensor proxy supports ``.load()`` and
``.store()`` just like regular tensor parameters.

Examples (output is (M, N, L)):

- **Broadcast along M** — ``C`` is (N, L)::

    C.remap_modes[:, 0, 1].load()

- **Broadcast along N** — ``X`` is (M, L)::

    X.remap_modes[0, :, 1].load()

- **Scalar broadcast** — ``x_factor`` is a 0-d tensor::

    x_factor.remap_modes[:, :, :].load()

- **Transpose** — ``Y`` is (N, M, L)::

    Y.remap_modes[1, 0, 2].store(value)

A remapped tensor can also be both loaded and stored for
read-modify-write on a transposed layout::

    remapped_Y = Y.remap_modes[1, 0, 2]
    remapped_Y.store(efc_config.accum() + remapped_Y.load())

Complete Examples
~~~~~~~~~~~~~~~~~

**Alpha-beta scaling** (simplest useful epilogue)::

    def epilogue(efc_config, C, D, alpha, beta):
        D.store(efc_config.accum() * alpha + C.load() * beta)

**Multi-tensor with activation**::

    def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
        Y.store(efc_config.accum())
        result = (
            efc_config.relu(efc_config.accum() * alpha + C.load() * beta)
            + X.load() * x_factor
        )
        D.store(result)

**Ada FP8 GEMM pattern with dynamic activation**::

    def epilogue(efc_config, C, Aux, alpha, beta, bias,
                 scale_a, scale_b, scale_c, D, leaky_relu_alpha):
        aux_val = (
            (alpha * scale_a * scale_b) * efc_config.accum()
            + (beta * scale_c) * C.load()
            + bias
        )
        Aux.store(aux_val)
        D.store(efc_config.relu(aux_val))

**Broadcasting with mode remapping**::

    def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
        # Y is (N, M, L), output is (M, N, L): transpose via [1, 0, 2]
        Y.remap_modes[1, 0, 2].store(efc_config.accum())
        # C is (N, L): broadcast along M via [:, 0, 1]
        # X is (M, L): broadcast along N via [0, :, 1]
        result = (
            efc_config.relu(
                efc_config.accum() * alpha
                + C.remap_modes[:, 0, 1].load() * beta
            )
            + X.remap_modes[0, :, 1].load()
            * x_factor.remap_modes[:, :, :].load()
        )
        D.store(result)
"""


# The f8f6f4 MMA kind decodes A's and B's formats independently, so fp8 A/B
# dtypes may differ (e.g. e4m3 weights x e5m2 activations).  The f16 kind
# requires A and B to share one type (both f16 or both bf16).  The i8 kind
# also decodes signedness per operand, but the DSL's MmaI8Op takes a single
# dtype, so this kernel rejects mixed int8/uint8 A/B.
_FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)


class _S2TCopyBundle(typing.NamedTuple):
    """Tiled copy plus partitioned source/destination for one scale-factor
    tensor's SMEM->TMEM staging (see ``_mainloop_s2t_copy_and_partition``)."""

    tiled_copy: cute.TiledCopy
    sSF_compact: cute.Tensor  # partitioned source (SMEM descriptor tensor)
    tSF_compact: cute.Tensor  # partitioned destination (TMEM)


class _DenseGemmEFCJIT(common_efc.EFC.JIT):
    """The DenseGemmEFC operation's host-side companion.

    Holds the GEMM-pipeline-shaped methods (`compute_stage`,
    `smem_layout`, `create_tma_arguments`,
    `create_supplemental_arguments_for_kernel`) that were extracted
    from the EFC framework's `EFC.JIT`.  The framework now only
    contains the truly operation-agnostic parts of JIT (the
    `foreach_*` family, `get_*`, `record_tensor_dtypes`, etc.).
    """

    def epi_tile_of(self, tensor_name, epi_tile):
        """The epilogue tiler for one supplemental tensor.

        A tensor written from ``accum_split`` parts spans ``1 / num_parts``
        of the output's N, so it tiles that much narrower; every other
        tensor uses ``epi_tile`` unchanged.

        :param tensor_name: Name of the epilogue parameter.
        :param epi_tile: The accumulator's tiler, from the caller's region.
        :return: The tiler to partition that tensor with.
        """
        num_parts = self.efc.parameter_attributes[tensor_name].accum_split_parts
        if num_parts is None:
            return epi_tile
        return common_efc.narrow_epi_tile_n(epi_tile, num_parts)

    @trace_in_mlir
    def compute_stage(self):
        """Get the contribution from the tensors used in the EFC to the
        pipeline stage numbers."""
        self.smem_size_of_read_tensors = 0
        self.smem_size_of_written_tensors = 0
        # Fixed (non-staged) reduce-scratch SMEM: one slot per epi
        # warp per reduce destination.  Accumulated separately from
        # the per-stage read / written totals because it does not
        # multiply by a pipeline stage count -- see
        # ``compute_stages`` for how it folds into the budget.
        self.smem_size_of_reduce_tensors = 0
        self.tensor_dtype = {}

        def f(tensor, tensor_name, attributes):
            # It does not seem that the tma_tensor and tma_atom carry over
            # the element type, so, store it here for later use.
            self.tensor_dtype[tensor_name] = tensor.element_type

            smem_size_in_bytes_of_a_pipeline_stage = cutlass.cute.size_in_bytes(
                tensor.element_type,
                cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                    tensor.element_type,
                    self.operation.d_layout,
                    self.epi_tile_of(tensor_name, self.operation.epi_tile),
                    1,
                ),
            )
            # Prepare the information to be asked soon, to memoize this
            # loop.
            if attributes.is_read:
                self.smem_size_of_read_tensors += smem_size_in_bytes_of_a_pipeline_stage
                log(
                    f"JIT.compute_stage smem storage to read tensor {tensor_name}: {smem_size_in_bytes_of_a_pipeline_stage} bytes"
                )

            if attributes.is_written:
                self.smem_size_of_written_tensors += (
                    smem_size_in_bytes_of_a_pipeline_stage
                )
                log(
                    f"JIT.compute_stage smem storage to write tensor {tensor_name}: {smem_size_in_bytes_of_a_pipeline_stage} bytes"
                )

        self.foreach_non_degenerate_tensor(f)

        # Reduce destinations are degenerate-scalar remapped tensors,
        # which ``foreach_non_degenerate_tensor`` skips; account for
        # their tiny SMEM scratch here via a direct iteration.
        num_epi_warps = len(self.operation.epilogue_warp_id)

        # The per-buffer ``byte_alignment`` passed to
        # ``allocate_smem`` (see the matching ``f_reduce`` there)
        # has to be mirrored here so the budget does not undercount.
        # Each reduce destination's scratch is rounded up to this
        # alignment by the allocator; the planner must reserve the
        # same rounded-up size or the AB-stage count can come out
        # one stage too generous in tight-SMEM configurations.
        reduce_byte_alignment = 16

        def f_reduce(tensor_name, attributes):
            if attributes.reduce_op is None:
                return
            if attributes.degenerate_to_scalar:
                fold_layout = cutlass.cute.make_layout(num_epi_warps)
            else:
                # Exact kept-axis extent, shared with ``allocate_smem`` via
                # ``DenseGemmEFC.reduce_fold_extent`` -- the planner and the
                # allocator must agree or the AB-stage budget miscounts.
                fold_layout = cutlass.cute.make_layout(
                    self.operation.reduce_fold_extent(attributes)
                )
            # Sized in the destination's dtype, matching ``allocate_smem``
            # (the fold runs at the destination's precision).  The remapped
            # pseudo-name is not a JIT parameter; the source tensor is.
            raw_size = cutlass.cute.size_in_bytes(
                self.parameter[attributes.mapped_source].element_type,
                fold_layout,
            )
            size = (
                (raw_size + reduce_byte_alignment - 1)
                // reduce_byte_alignment
                * reduce_byte_alignment
            )
            self.smem_size_of_reduce_tensors += size
            log(
                f"JIT.compute_stage smem storage to reduce tensor {tensor_name}: "
                f"{size} bytes ({raw_size} raw, rounded to "
                f"{reduce_byte_alignment}-byte alignment)"
            )

        self.efc.foreach_remapped_tensor(f_reduce)

    @trace_in_mlir
    def smem_layout(self):
        """Get the smem_layout for the tensors used in the EFC."""
        self.smem_layout_staged_read = {}
        self.smem_layout_staged_written = {}

        def f(tensor, tensor_name, attributes):
            if attributes.is_direct:
                # Direct (sync register<->GMEM) tensors do not stage through SMEM.
                return
            log(f"JIT.smem_layout {tensor_name} = {tensor!s}")
            ref_tensor = self.get_argument_or_remapped_tensor(tensor_name)
            tensor_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(ref_tensor)
            log(f"JIT.smem_layout tensor_layout[{tensor_name}] = {tensor_layout!s}")

            if attributes.is_read:
                self.smem_layout_staged_read[tensor_name] = (
                    cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                        tensor.element_type,
                        tensor_layout,
                        self.epi_tile_of(tensor_name, self.operation.epi_tile),
                        self.operation.num_c_stage,
                    )
                )
                log(f"JIT.smem_layout read {self.operation.num_c_stage = }")
                log(
                    f"JIT.smem_layout read self.smem_layout_staged_read[{tensor_name}] = {self.smem_layout_staged_read[tensor_name]!s}"
                )
            if attributes.is_written:
                self.smem_layout_staged_written[tensor_name] = (
                    cutlass.utils.blackwell_helpers.make_smem_layout_epi(
                        tensor.element_type,
                        tensor_layout,
                        self.epi_tile_of(tensor_name, self.operation.epi_tile),
                        self.operation.num_d_stage,
                    )
                )
                log(f"JIT.smem_layout written {self.operation.num_d_stage = }")
                log(
                    f"JIT.smem_layout written self.smem_layout_staged_written[{tensor_name}] = {self.smem_layout_staged_written[tensor_name]!s}"
                )

        self.foreach_non_degenerate_tensor(f)

    @trace_in_mlir
    def create_tma_arguments(self):
        """Set the TMA arguments for TMA tensors and save the raw GMEM
        tensor for direct (non-TMA) tensors.  The ``CopyUniversalOp``
        atom for direct tensors is built kernel-side in
        ``copy_and_partition_supplemental_rmem_tensors`` so it can use
        the auto-derived ``num_bits_per_copy`` (max-common-layout based)
        when the user did not supply an explicit width.
        """
        # Make the difference for read/written to handle the case a tensor
        # is both read and written.
        self.total_tma_load_bytes = 0  # Used by the PipelineTmaAsync
        self.tma_atom_read = {}
        self.tma_tensor_read = {}
        self.tma_atom_written = {}
        self.tma_tensor_written = {}
        # Raw GMEM tensors for non-TMA tensors (sync direct *and*
        # async cp.async).  For the sync modes the atom is built
        # kernel-side once the per-thread fragment is known; for
        # ``ASYNC_GMEM_LOAD`` the atom is built here at JIT time
        # because it does not depend on the per-thread partition.
        self.gmem_tensor_read = {}
        self.gmem_tensor_written = {}
        # Async cp.async read atoms.  Populated for tensors whose
        # ``mode`` is ``Transport.ASYNC_GMEM_LOAD``.
        self.async_load_atom = {}

        def f(tensor, tensor_name, attributes):
            if attributes.is_direct:
                # Direct (sync) tensors bypass the TMA descriptor.
                # Save the raw GMEM tensor so the kernel can partition
                # it via ``self.operation.epilogue_gmem_copy_and_partition_non_tma``.
                if attributes.is_read:
                    self.gmem_tensor_read[tensor_name] = tensor
                if attributes.is_written:
                    self.gmem_tensor_written[tensor_name] = tensor
                return
            if attributes.transport is Transport.ASYNC_GMEM_LOAD:
                # ``ASYNC_GMEM_LOAD`` reads are SMEM-staged like TMA
                # but use a CopyG2SOp atom with explicit cp.async
                # producer arrival.  Build the atom now (it does not
                # depend on per-thread partition) and save the raw
                # GMEM tensor for the load warp's cp.async to source
                # from.  No contribution to ``total_tma_load_bytes``
                # -- cp.async arrivals carry zero tx_count and signal
                # via ``mbarrier.arrive`` rather than byte completion.
                # ``ASYNC_GMEM_LOAD`` is read-only by construction.
                # Width: an explicit ``num_bits_per_copy`` wins, else 128 bits
                # (the ``cp.async`` per-thread maximum).  The atom is built here
                # at JIT time, when the supplemental tensor is still dynamically
                # shaped, so -- unlike the synchronous in-kernel paths -- the
                # width cannot be auto-derived from a max-common-layout; 128 is
                # safe because a dynamic supplemental tensor's contiguous extent
                # is divisibility-constrained to a multiple of 128 bits.  See
                # ``Tensor.ParameterAttributes.num_bits_per_copy`` for the full
                # rationale and the statically-narrow-tensor caveat.
                width = (
                    attributes.num_bits_per_copy
                    if attributes.num_bits_per_copy is not None
                    else 128
                )
                self.async_load_atom[tensor_name] = cutlass.cute.make_copy_atom(
                    cutlass.cute.nvgpu.cpasync.CopyG2SOp(),
                    tensor.element_type,
                    num_bits_per_copy=width,
                )
                self.gmem_tensor_read[tensor_name] = tensor
                log(
                    f"JIT.create_tma_arguments async_load_atom[{tensor_name}] = {self.async_load_atom[tensor_name]!s}"
                )
                return
            if attributes.is_read:
                smem_layout = cutlass.cute.slice_(
                    self.smem_layout_staged_read[tensor_name], (None, None, 0)
                )
                self.total_tma_load_bytes += cutlass.cute.size_in_bytes(
                    tensor.element_type, smem_layout
                )
                (
                    self.tma_atom_read[tensor_name],
                    self.tma_tensor_read[tensor_name],
                ) = cutlass.cute.nvgpu.cpasync.make_tiled_tma_atom(
                    cutlass.cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(),
                    tensor,
                    smem_layout,
                    self.epi_tile_of(tensor_name, self.operation.epi_tile),
                )
                log(
                    f"JIT.create_tma_arguments tma_atom_read[{tensor_name}] = {self.tma_atom_read[tensor_name]!s}"
                )
                log(
                    f"JIT.create_tma_arguments tma_tensor_read[{tensor_name}] = {self.tma_tensor_read[tensor_name]!s}"
                )

            if attributes.is_written:
                smem_layout = cutlass.cute.slice_(
                    self.smem_layout_staged_written[tensor_name], (None, None, 0)
                )
                (
                    self.tma_atom_written[tensor_name],
                    self.tma_tensor_written[tensor_name],
                ) = cutlass.cute.nvgpu.cpasync.make_tiled_tma_atom(
                    cutlass.cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
                    tensor,
                    smem_layout,
                    self.epi_tile_of(tensor_name, self.operation.epi_tile),
                )
                log(
                    f"JIT.create_tma_arguments tma_atom_written[{tensor_name}] = {self.tma_atom_written[tensor_name]!s}"
                )
                log(
                    f"JIT.create_tma_arguments tma_tensor_written[{tensor_name}] = {self.tma_tensor_written[tensor_name]!s}"
                )

        self.foreach_non_degenerate_tensor(f)

    @trace_in_mlir
    def create_supplemental_arguments_for_kernel(self):
        """Executed before launching the @cute.kernel function to set up the
        supplemental arguments to pass to the @cute.kernel function.

        In the @cute.kernel example, the parameters like `X_tma_tensor_read`
        or `Y_tma_tensor_written` correspond to `mX_mnl` and `mY_mnl`."""
        argument_names = []

        def compute_argument_names(value, name, attributes):
            if (
                not attributes.is_tensor
                or attributes.degenerate_to_scalar
                or attributes.reduce_op is not None
            ):
                # Single argument under ``name`` for: dynamic scalars,
                # degenerate scalar broadcasts, and non-scalar reduce
                # destinations.  A non-scalar reduce target passes its
                # zero-stride (M, N, L) view (no TMA atoms); the kernel
                # partitions it like a written tensor and atomic-scatters
                # into it.
                argument_names.append(name)
            elif attributes.is_direct:
                # Direct (sync) tensors: pass only the raw GMEM tensor.
                # The synchronous copy atom is built kernel-side once
                # the per-thread fragment shape is known (so it can
                # use the auto-derived ``num_bits_per_copy``).
                if attributes.is_read:
                    argument_names.append(f"{name}_gmem_tensor_read")
                if attributes.is_written:
                    argument_names.append(f"{name}_gmem_tensor_written")
            elif attributes.transport is Transport.ASYNC_GMEM_LOAD:
                # ``ASYNC_GMEM_LOAD`` read tensors: pass the raw GMEM
                # tensor (the load warp's cp.async sources from it),
                # the ``CopyG2SOp`` atom built at JIT time, and the
                # same SMEM-staged layout TMA would have used.
                argument_names.append(f"{name}_gmem_tensor_read")
                argument_names.append(f"{name}_async_load_atom")
                argument_names.append(f"{name}_smem_layout_staged_read")
            else:
                if attributes.is_read:
                    argument_names.append(f"{name}_tma_atom_read")
                    argument_names.append(f"{name}_tma_tensor_read")
                    argument_names.append(f"{name}_smem_layout_staged_read")
                if attributes.is_written:
                    argument_names.append(f"{name}_tma_atom_written")
                    argument_names.append(f"{name}_tma_tensor_written")
                    argument_names.append(f"{name}_smem_layout_staged_written")

        self.foreach_argument(compute_argument_names)
        # Create the @cute.kernel-side meta-programming infrastructure
        # handling also the supplemental argument handling.
        self.efc.kernel = self.efc.operation.Kernel(self.efc, argument_names)

        arg = self.efc.kernel.arg

        def populate_the_kernel_arguments(value, name, attributes):
            if not attributes.is_tensor:
                # Just propagate the dynamic scalar with the same name.
                arg[name] = value
            elif attributes.degenerate_to_scalar:
                # The tensor broadcast is optimized out as a single scalar
                # from the tensor source which is implicitly broadcast when
                # used but since it might be in device memory, pass it
                # unchanged so it can be dereferenced inside the kernel.
                arg[name] = self.efc.jit.parameter[attributes.mapped_source]
            elif attributes.reduce_op is not None:
                # Non-scalar reduce destination: pass the zero-stride
                # (M, N, L) view built in ``handle_remapping`` as a
                # single kernel arg.  As a genuine kernel parameter it is
                # usable inside the isolated ``@cute.kernel`` region (a
                # host-region view would violate region isolation), so
                # the kernel can ``local_tile`` + ``partition_C`` it and
                # atomic-scatter into it.
                arg[name] = self.efc.jit.remapped_tensors[name]
            elif attributes.is_direct:
                # Mirror compute_argument_names.
                if attributes.is_read:
                    arg[f"{name}_gmem_tensor_read"] = self.gmem_tensor_read[name]
                if attributes.is_written:
                    arg[f"{name}_gmem_tensor_written"] = self.gmem_tensor_written[name]
            elif attributes.transport is Transport.ASYNC_GMEM_LOAD:
                arg[f"{name}_gmem_tensor_read"] = self.gmem_tensor_read[name]
                arg[f"{name}_async_load_atom"] = self.async_load_atom[name]
                arg[f"{name}_smem_layout_staged_read"] = self.smem_layout_staged_read[
                    name
                ]
            else:
                if attributes.is_read:
                    arg[f"{name}_tma_atom_read"] = self.tma_atom_read[name]
                    arg[f"{name}_tma_tensor_read"] = self.tma_tensor_read[name]
                    arg[f"{name}_smem_layout_staged_read"] = (
                        self.smem_layout_staged_read[name]
                    )
                if attributes.is_written:
                    arg[f"{name}_tma_atom_written"] = self.tma_atom_written[name]
                    arg[f"{name}_tma_tensor_written"] = self.tma_tensor_written[name]
                    arg[f"{name}_smem_layout_staged_written"] = (
                        self.smem_layout_staged_written[name]
                    )

        self.foreach_argument(populate_the_kernel_arguments)


class _DenseGemmEFCKernel(_DenseGemmEFCKernelBase):
    """The DenseGemmEFC operation's device-side companion.

    Holds the GEMM-pipeline-shaped methods (allocate_smem,
    partition_global_tensors_for_tiled_mma, the TMA store steps,
    the subtile-load orchestration, etc.) that were extracted from
    the EFC framework's `EFC.Kernel`.  The framework now only
    contains the iteration-scaffolding `foreach_*` family.
    """

    @trace_in_mlir
    def prefetch_tma_descriptors(self):
        """Prefetch the TMA descriptors for the tensors used in the EFC."""

        def f(tensor_name, attributes):
            # Only TMA-mode tensors have a descriptor to prefetch.
            # ``SYNC_GMEM_LOAD`` / ``SYNC_GMEM_STORE`` bypass the
            # staged pipeline entirely; ``ASYNC_GMEM_LOAD`` stages
            # through SMEM but uses cp.async, not a descriptor.
            # ``mode is Transport.TMA`` is the precise predicate
            # (``is_direct`` alone would let ``ASYNC_GMEM_LOAD``
            # through).
            if attributes.transport is not Transport.TMA:
                return
            if attributes.is_read:
                cutlass.cute.nvgpu.cpasync.prefetch_descriptor(
                    self.parameter[f"{tensor_name}_tma_atom_read"]
                )

            if attributes.is_written:
                cutlass.cute.nvgpu.cpasync.prefetch_descriptor(
                    self.parameter[f"{tensor_name}_tma_atom_written"]
                )

        self.foreach_tensor(f)

    @trace_in_mlir
    def allocate_smem(self):
        """Allocate the shared memory for all the supplemental tensors."""
        self.smem_read = {}
        self.smem_written = {}
        # Per-reduce-destination SMEM scratch for the cross-warp fold.
        # One ``epi_dtype`` slot per epilogue warp, filled by lane 0 of
        # each warp during ``Tensor.reduce`` and read by warp 0 lane 0
        # to do the final CTA-level fold before the global atomic.
        self.smem_reduce = {}

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # Direct tensors do not need staged SMEM allocation.
                return
            element_type = self.efc.jit.tensor_dtype[tensor_name]
            if attributes.is_read:
                smem_layout_staged = self.parameter[
                    f"{tensor_name}_smem_layout_staged_read"
                ]
                self.smem_read[tensor_name] = self.operation.smem.allocate_tensor(
                    element_type=element_type,
                    layout=smem_layout_staged.outer,
                    byte_alignment=self.operation.buffer_align_bytes,
                    swizzle=smem_layout_staged.inner,
                )
            if attributes.is_written:
                smem_layout_staged = self.parameter[
                    f"{tensor_name}_smem_layout_staged_written"
                ]
                self.smem_written[tensor_name] = self.operation.smem.allocate_tensor(
                    element_type=element_type,
                    layout=smem_layout_staged.outer,
                    byte_alignment=self.operation.buffer_align_bytes,
                    swizzle=smem_layout_staged.inner,
                )

        self.foreach_tensor(f)

        # Tiny scratch SMEM for each reduce destination: one slot per
        # epi warp, sized in the destination's dtype.  The reduce-target
        # iteration skips ``foreach_tensor`` (which filters out
        # degenerate scalars) and goes through ``foreach_remapped_tensor``
        # directly because reduce destinations are degenerate scalars.
        num_epi_warps = len(self.operation.epilogue_warp_id)

        def f_reduce(tensor_name, attributes):
            if attributes.reduce_op is None:
                return
            if attributes.degenerate_to_scalar:
                # Scalar: one cross-warp fold slot per epilogue warp.
                fold_layout = cute.make_layout(num_epi_warps)
            else:
                # Non-scalar (kept-axis): one slot per distinct kept
                # coordinate a CTA touches, so the cross-thread fold runs
                # in SMEM (cheap, per-SM) and only one global atomic per
                # kept coordinate reaches the L2 atomic units.  The exact
                # extent comes from ``DenseGemmEFC.reduce_fold_extent``,
                # matching the runtime buffer view's cosize.
                fold_layout = cute.make_layout(
                    self.operation.reduce_fold_extent(attributes)
                )
            # Sized in the *destination's* dtype: the whole fold runs at
            # the destination's precision (``Tensor.reduce`` converts the
            # epilogue fragment at the boundary).
            self.smem_reduce[tensor_name] = self.operation.smem.allocate_tensor(
                element_type=self.parameter[tensor_name].element_type,
                layout=fold_layout,
                byte_alignment=16,
            )

        self.efc.foreach_remapped_tensor(f_reduce)

    @trace_in_mlir
    def copy_and_partition_supplemental_rmem_tensors(
        self,
        tiled_copy_t2r,
        tTR_rAcc,
        epi_tidx,
        epi_tile,
        tTR_cAcc=None,
    ):
        # Whether an ``accum_split`` gathers its parts from other lanes
        # rather than re-viewing this thread's registers; decided below.
        self.accum_split_across_lanes = False
        # Load tensor.
        self.tiled_copy_s2r = {}
        self.tSR_rC = {}
        self.tTR_rC = {}  # the T2R register behind each ``tSR_rC`` view
        self.tSR_sC = {}

        # Store tensor.
        self.tiled_copy_r2s = {}
        self.tRS_rD = {}
        self.tRS_sD = {}
        self.bSG_sD = {}  # ((ATOM_V, REST_V), EPI_M, EPI_N)
        self.bSG_gD_partitioned = {}  # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)

        # Direct (non-TMA) tensors: per-thread per-subtile partition +
        # register fragment + the synchronous CopyUniversalOp atom
        # built kernel-side.
        self.direct_load_atom = {}
        self.direct_store_atom = {}
        self.tTR_rC_direct = {}  # (T2R, T2R_M, T2R_N)
        self.tTR_rD_direct = {}  # (T2R, T2R_M, T2R_N)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        self.tTR_gC_direct_partitioned = {}
        self.tTR_gD_direct_partitioned = {}
        # Elements moved by one direct copy atom, per tensor and direction.
        self.direct_load_vector_elements = {}
        self.direct_store_vector_elements = {}

        # Save ``tiled_copy_t2r`` so the EFC body can fall back to it
        # when no TMA D exists (all-direct-store kernels).
        self.tiled_copy_t2r = tiled_copy_t2r

        log(
            f"Kernel.copy_and_partition_supplemental_rmem_tensors: tiled_copy_t2r = {tiled_copy_t2r!s}"
        )
        log(
            f"Kernel.copy_and_partition_supplemental_rmem_tensors: tTR_rAcc = {tTR_rAcc!s}"
        )
        log(
            f"Kernel.copy_and_partition_supplemental_rmem_tensors: epi_tile = {epi_tile!s}"
        )
        log(
            f"Kernel.copy_and_partition_supplemental_rmem_tensors: epi_tidx = {epi_tidx!s}"
        )

        def f(tensor_name, attributes):
            element_type = self.efc.jit.tensor_dtype[tensor_name]
            if attributes.is_direct:
                # Direct tensors bypass the SMEM-staged S2R/R2S setup
                # entirely: a per-thread per-subtile partition of the
                # GMEM tensor goes straight to a register fragment
                # (read) or vice versa (write).  See _helpers for the
                # partition shape and the auto-derive of
                # ``num_bits_per_copy``.
                if attributes.is_read:
                    (
                        self.direct_load_atom[tensor_name],
                        self.tTR_rC_direct[tensor_name],
                        self.tTR_gC_direct_partitioned[tensor_name],
                        self.direct_load_vector_elements[tensor_name],
                    ) = self.operation.epilogue_gmem_copy_and_partition_non_tma(
                        epi_tidx,
                        tiled_copy_t2r,
                        self.tCgC_read[tensor_name],
                        self.efc.jit.epi_tile_of(tensor_name, epi_tile),
                        element_type,
                        num_bits_per_copy=attributes.num_bits_per_copy,
                    )
                if attributes.is_written:
                    (
                        self.direct_store_atom[tensor_name],
                        self.tTR_rD_direct[tensor_name],
                        self.tTR_gD_direct_partitioned[tensor_name],
                        self.direct_store_vector_elements[tensor_name],
                    ) = self.operation.epilogue_gmem_copy_and_partition_non_tma(
                        epi_tidx,
                        tiled_copy_t2r,
                        self.tCgD_written[tensor_name],
                        self.efc.jit.epi_tile_of(tensor_name, epi_tile),
                        element_type,
                        num_bits_per_copy=attributes.num_bits_per_copy,
                    )
                return
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors: element_type[{tensor_name}] = {element_type!s}"
            )

            if attributes.is_read:
                tTR_rC = cutlass.cute.make_rmem_tensor(tTR_rAcc.shape, element_type)
                # ``tSR_rC`` below is an S2R-shaped view of this register; the
                # epilogue body reads the register itself (``load_setup``).
                self.tTR_rC[tensor_name] = tTR_rC
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors read: tTR_rC[{tensor_name}] = {tTR_rC!s}"
                )

                (
                    self.tiled_copy_s2r[tensor_name],
                    self.tSR_rC[tensor_name],
                    self.tSR_sC[tensor_name],
                ) = self.operation.epilogue_smem_copy_and_partition_load(
                    tiled_copy_t2r,
                    tTR_rC,
                    epi_tidx,
                    self.smem_read[tensor_name],
                )

                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tiled_copy_s2r[{tensor_name}] = {self.tiled_copy_s2r[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tSR_rC[{tensor_name}] = {self.tSR_rC[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors read: self.tSR_sC[{tensor_name}] = {self.tSR_sC[tensor_name]!s}"
                )

            if attributes.is_written:
                num_parts = attributes.accum_split_parts

                # utils.gemm.sm100.epilogue_smem_copy_and_partition uses
                # explicitly "C" as the output matrix and introspects the
                # gemm object while in this kernel "C" is used for read but
                # "D" is for output according to the BLAS convention.
                # So construct a minimal mock-up with the required
                # information.
                faux_gemm = types.SimpleNamespace()
                faux_gemm.c_layout = self.operation.d_layout
                faux_gemm.c_dtype = self.operation.d_dtype
                faux_gemm.acc_dtype = self.operation.acc_dtype
                if cutlass.const_expr(num_parts is None):
                    # (T2R, T2R_M, T2R_N)
                    tTR_rD = cutlass.cute.make_rmem_tensor(tTR_rAcc.shape, element_type)
                    (
                        self.tiled_copy_r2s[tensor_name],
                        self.tRS_rD[tensor_name],  # (R2S, R2S_M, R2S_N)
                        self.tRS_sD[tensor_name],  # (R2S, R2S_M, R2S_N)
                    ) = cutlass.utils.gemm.sm100.epilogue_smem_copy_and_partition(
                        faux_gemm,
                        tiled_copy_t2r,  # (EPI_TILE_M, EPI_TILE_N)
                        tTR_rD,
                        epi_tidx,
                        self.smem_written[tensor_name],
                    )
                else:
                    # A tensor written from ``accum_split`` parts stages
                    # through SMEM addressed by the accumulator's own
                    # thread->value map: the map partitions an
                    # ``extend_split_n`` view of the SMEM stage, where
                    # accumulator column n aliases narrow column
                    # n // num_parts, and ``filter_zeros`` keeps one slot
                    # per narrow column.  The register fragment holds
                    # those unique slots, so the part arithmetic and the
                    # store agree on element order by construction --
                    # both sides are ordered by ``tiled_copy_t2r``.
                    copy_atom_r2s = cutlass.cute.make_copy_atom(
                        cutlass.cute.nvgpu.CopyUniversalOp(), element_type
                    )
                    self.tiled_copy_r2s[tensor_name] = cutlass.cute.make_tiled_copy_D(
                        copy_atom_r2s, tiled_copy_t2r
                    )
                    smem_ext = common_efc.extend_split_n(
                        self.smem_written[tensor_name], num_parts
                    )
                    # (R2S, R2S_M, R2S_N, STAGE)
                    self.tRS_sD[tensor_name] = cutlass.cute.filter_zeros(
                        self.tiled_copy_r2s[tensor_name]
                        .get_slice(epi_tidx)
                        .partition_D(smem_ext)
                    )
                    # (R2S, R2S_M, R2S_N)
                    self.tRS_rD[tensor_name] = cutlass.cute.make_rmem_tensor(
                        cutlass.cute.shape(self.tRS_sD[tensor_name])[:3],
                        element_type,
                    )
                # TV map of this tensor's register->SMEM store copy.
                _helpers.maybe_dump_tv_latex(
                    self.tiled_copy_r2s[tensor_name],
                    f"r2s_write_{tensor_name}_{element_type.__name__}",
                    context=(
                        f"{type(self.operation).__module__}."
                        f"{type(self.operation).__qualname__}\n"
                        "Kernel.copy_and_partition_supplemental_rmem_tensors\n"
                        f"R2S: reg->SMEM staged write, tensor={tensor_name}, "
                        f"{element_type.__name__}"
                    ),
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.smem_written[{tensor_name}] = {self.smem_written[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tiled_copy_r2s[{tensor_name}] = {self.tiled_copy_r2s[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tRS_rD[{tensor_name}] = {self.tRS_rD[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tRS_sD[{tensor_name}] = {self.tRS_sD[tensor_name]!s}"
                )
                (
                    _,
                    self.bSG_sD[tensor_name],  # ((ATOM_V, REST_V), EPI_M, EPI_N)
                    self.bSG_gD_partitioned[
                        tensor_name
                    ],  # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
                ) = self.operation.epilogue_gmem_copy_and_partition(
                    epi_tidx,
                    self.parameter[f"{tensor_name}_tma_atom_written"],
                    self.tCgD_written[tensor_name],
                    self.efc.jit.epi_tile_of(tensor_name, epi_tile),
                    self.smem_written[tensor_name],
                )

                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.parameter[{tensor_name}_tma_atom_written] = {self.parameter[f'{tensor_name}_tma_atom_written']!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.tCgD_written[{tensor_name}] = {self.tCgD_written[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.smem_written[{tensor_name}] = {self.smem_written[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: element_type = {element_type!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.bSG_sD[{tensor_name}] = {self.bSG_sD[tensor_name]!s}"
                )
                log(
                    f"Kernel.copy_and_partition_supplemental_rmem_tensors written: self.bSG_gD_partitioned[{tensor_name}] = {self.bSG_gD_partitioned[tensor_name]!s}"
                )

        self.foreach_tensor(f)

        # Per-thread per-subtile coordinates of the output tile, congruent
        # to the direct partitions above, to predicate the direct GMEM
        # accesses of partial tiles.
        self.tTR_cC_direct_partitioned = None
        if any(
            attributes.is_tensor and attributes.is_direct
            for attributes in self.efc.parameter_attributes.values()
        ):
            cC_epi = cute.flat_divide(self.tCcC, epi_tile)
            # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
            self.tTR_cC_direct_partitioned = tiled_copy_t2r.get_slice(
                epi_tidx
            ).partition_D(cC_epi)

        # Per-thread per-subtile partition of each non-scalar reduce
        # destination, congruent to the accumulator fragment.  Built
        # like a direct-store output (partition_C -> partition_D) but on
        # the ``remap_modes`` zero-stride view of the kept-axis source
        # vector: the folded output axes carry stride 0, so the
        # per-element atomic scatter in ``_emit_axis_reduce`` aliases
        # folded coordinates onto a single destination address (the
        # categorical dual of the broadcast read).  Only the GMEM
        # address partition is kept -- the copy atom is unused -- so the
        # partition steps are inlined rather than reusing
        # ``epilogue_gmem_copy_and_partition_non_tma``.
        self.tTR_gReduce_partitioned = {}
        # SMEM-fold companions (kept-axis reduce): the per-thread SMEM
        # mirror fragment, the per-CTA destination tile (keeping the
        # ``(RestM, RestN, RestL)`` modes so the flush can slice this
        # CTA's kept-axis base by ``mma_tile_coord_mnl``), and the kept
        # extent -- used by the SMEM-staged emit (fold in SMEM, then one
        # global atomic per kept coordinate during the cooperative flush).
        self.tTR_sReduce_partitioned = {}
        self.reduce_gReduce_mnl = {}
        self.reduce_kept_extent = {}
        # Per-target selector (computed here, before the subtile loop, so
        # the init/flush hooks and the per-subtile fold dispatch all agree):
        # stage the fold through SMEM only when it lowers the global-atomic
        # count.  Subtile-independent -- it is a property of the fragment
        # layout, not the data.
        self.reduce_use_smem = {}

        def f_reduce(tensor_name, attributes):
            # Scalar reduce uses the warpgroup-fold path (a single
            # destination address); only non-scalar (kept-axis)
            # destinations need a partitioned scatter target.
            if attributes.reduce_op is None or attributes.degenerate_to_scalar:
                return
            # Zero-stride (M, N, L) view, passed in as a kernel
            # parameter (``populate_the_kernel_arguments``) so it is
            # usable inside this isolated kernel region.
            view = self.parameter[tensor_name]
            # (bM, bN, loopM, loopN, loopL)
            gReduce_mnl = cutlass.cute.local_tile(
                view,
                cutlass.cute.slice_(self.operation.mma_tiler, (None, None, 0)),
                (None, None, None),
            )
            # ((ATOM_M, MMA_M), (ATOM_N, MMA_N), loopM, loopN, loopL)
            tCgReduce = transform_partitioned_tensor_layout(
                self.operation.thr_mma.partition_C(gReduce_mnl)
            )
            # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN, RestL)
            gReduce_epi = cutlass.cute.flat_divide(tCgReduce, epi_tile)
            thr_copy_t2r = tiled_copy_t2r.get_slice(epi_tidx)
            self.tTR_gReduce_partitioned[tensor_name] = thr_copy_t2r.partition_D(
                gReduce_epi
            )
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors reduce: "
                f"self.tTR_gReduce_partitioned[{tensor_name}] = "
                f"{self.tTR_gReduce_partitioned[tensor_name]!s}"
            )
            # SMEM mirror: the same per-CTA zero-stride tile layout backed
            # by the kept-extent SMEM scratch, partitioned through the same
            # ``partition_C`` -> ``flat_divide`` -> ``partition_D`` chain.
            # The buffer already represents this CTA's tile, so there are
            # no loop/Rest dims (no ``local_tile`` and no ``mma_tile_coord``
            # slice).  Atomics into this fragment fold the cross-thread
            # duplicates in SMEM via the same zero-stride aliasing.
            cta_tile_layout = gReduce_mnl[(None, None, 0, 0, 0)].layout
            sReduce_tile = cutlass.cute.make_tensor(
                self.smem_reduce[tensor_name].iterator, cta_tile_layout
            )
            tCsReduce = transform_partitioned_tensor_layout(
                self.operation.thr_mma.partition_C(sReduce_tile)
            )
            sReduce_epi = cutlass.cute.flat_divide(tCsReduce, epi_tile)
            self.tTR_sReduce_partitioned[tensor_name] = thr_copy_t2r.partition_D(
                sReduce_epi
            )
            # Cooperative init/flush handles.  Keep the full per-CTA tile
            # (with the ``(RestM, RestN, RestL)`` loop modes) so the flush
            # can slice this CTA's tile by ``mma_tile_coord_mnl`` and read
            # its kept-axis base: with the persistent scheduler a single
            # CTA visits several output tiles, so the destination base is
            # ``view.iterator + (tile offset)``, *not* the whole-vector
            # base -- using the latter sends every kept-axis tile to
            # columns ``[0, kept_extent)`` and drops the rest.  The kept
            # extent is the per-CTA tile's cosize (folded axes carry
            # stride 0, so the tile spans exactly the kept coordinates).
            self.reduce_gReduce_mnl[tensor_name] = gReduce_mnl
            self.reduce_kept_extent[tensor_name] = cutlass.cute.cosize(cta_tile_layout)
            # Selector: the direct scatter emits ``distinct_offsets`` global
            # atomics per thread (so ``distinct_offsets * epilogue_threads``
            # across the warpgroup); the SMEM-staged path flushes only
            # ``kept_extent``.  Stage through SMEM only when the former
            # exceeds the latter (thread-dimension fold, column-style).  The
            # distinct-offset count comes from a per-subtile slice of the
            # SMEM mirror -- its layout is the same for every subtile.
            num_epi_threads = len(self.operation.epilogue_warp_id) * 32
            smem_frag0 = cutlass.cute.group_modes(
                self.tTR_sReduce_partitioned[tensor_name],
                3,
                cutlass.cute.rank(self.tTR_sReduce_partitioned[tensor_name]),
            )[(None, None, None, 0)]
            distinct = common_efc._tensor._count_distinct_offsets(smem_frag0)
            self.reduce_use_smem[tensor_name] = (
                distinct * num_epi_threads > self.reduce_kept_extent[tensor_name]
            )
            log(
                f"Kernel.copy_and_partition_supplemental_rmem_tensors reduce SMEM: "
                f"self.tTR_sReduce_partitioned[{tensor_name}] = "
                f"{self.tTR_sReduce_partitioned[tensor_name]!s}, "
                f"use_smem={self.reduce_use_smem[tensor_name]}"
            )

        self.efc.foreach_remapped_tensor(f_reduce)

        # Every register fragment the epilogue body touches is brought
        # into one per-subtile layout, so per-element arithmetic between
        # the accumulator, the supplemental reads and the supplemental
        # writes is well-formed whichever load/store paths are in play.
        # All of those fragments are partitioned by ``tiled_copy_t2r``
        # (``tTR_rAcc``, ``tTR_cAcc``, ``tTR_rC``, ``tTR_rC_direct``,
        # ``tTR_rD_direct``; a TMA-read tensor's ``tSR_rC`` is only an
        # S2R-shaped view of its ``tTR_rC``), so one conversion serves
        # them all, ``retile_t2r_fragment``:
        #
        # * R2S when at least one D is TMA-stored, so the body's values
        #   match ``tRS_rD`` of the TMA store path;
        # * the identity when every D is direct-stored.  Not
        #   ``tiled_copy_t2r.retile``: applied to a fragment that is
        #   already in its own layout it is *not* a no-op, it re-tiles
        #   the per-thread values by the atom's thread count and yields a
        #   stride-0 view that aliases every register ``threads_per_atom``
        #   times (32 for the 32dp32bit atom).  Computing on that view
        #   multiplies the work of every direct store, breaks the
        #   kept-axis SMEM fold (its fragment keeps the T2R shape) and
        #   makes a scalar ``reduce`` sum each value 32 times.
        #
        # Reduce destinations are ``is_written`` but go through the
        # atomic reduce path, not a store, so they do not constrain the
        # layout choice -- exclude them here.
        all_direct = all(
            self.efc.parameter_attributes[name].is_direct
            for name in self.efc.written_tensor_names
            if self.efc.parameter_attributes[name].reduce_op is None
        )
        if all_direct:
            self.retile_t2r_fragment = lambda fragment: fragment
        else:
            # At least one written tensor is TMA-stored, so the accumulator
            # and the read fragments are reshaped into the R2S layout those
            # stores expect.  Each written tensor's own destination fragment
            # comes from its own R2S copy, so a narrowed write does not
            # constrain this choice.  Key it on the bigger-element
            # *TMA-stored* write: ``d_name_bigger`` may be direct-stored -- a
            # bigger-element direct D alongside a smaller TMA D -- and a
            # direct write has no R2S copy.  The keys of ``tiled_copy_r2s``
            # are exactly the TMA-stored writes, and this branch runs only
            # when at least one exists.
            r2s_name = max(
                self.tiled_copy_r2s,
                key=lambda name: self.efc.jit.tensor_dtype[name].width,
            )
            self.retile_t2r_fragment = self.tiled_copy_r2s[r2s_name].retile
        # The retiled fragment is now known, so an epilogue splitting the
        # accumulator can be rejected here -- once per kernel, before the
        # subtile loop -- rather than from inside the user body.
        if cutlass.const_expr(self.efc.accum_split_factor is not None):
            # Where a thread finds the columns to pair: its own registers,
            # or the lanes next to it.  ``Configuration._accum_split_fragment``
            # reads this flag through the epilogue context.
            self.accum_split_across_lanes = common_efc.accum_split_across_lanes(
                self.retile_t2r_fragment(tTR_rAcc),
                self.retile_t2r_fragment(tTR_cAcc),
                self.efc.accum_split_factor,
                tiled_copy_t2r,
                epi_tile,
            )

    @trace_in_mlir
    def tma_store_written_tensors_to_gmem(self, d_buffer, subtile_idx):
        """Store with TMA the written EFC tensors to global memory."""

        def f(tensor_name, attributes):
            if attributes.is_direct:
                # Direct-write tensors are stored inline by the EFC
                # body (``Tensor.store`` with
                # ``via=Transport.SYNC_GMEM_STORE``), not by this TMA path.
                return
            cutlass.cute.copy(
                self.parameter[f"{tensor_name}_tma_atom_written"],
                self.bSG_sD[tensor_name][(None, d_buffer)],
                self.bSG_gD[tensor_name][(None, subtile_idx)],
            )
            log(
                f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.parameter[{tensor_name}_tma_atom_written] = {self.parameter[f'{tensor_name}_tma_atom_written']!s}"
            )
            log(
                f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_sD[{tensor_name}] = {self.bSG_sD[tensor_name]!s}"
            )
            log(
                f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_sD[{tensor_name}][(None, d_buffer)] = {self.bSG_sD[tensor_name][(None, d_buffer)]!s}"
            )
            log(
                f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_gD[{tensor_name}] = {self.bSG_gD[tensor_name]!s}"
            )
            log(
                f"Kernel.tma_store_written_tensors_to_gmem cutlass.cute.copy: self.bSG_gD[{tensor_name}][(None, subtile_idx)] = {self.bSG_gD[tensor_name][(None, subtile_idx)]!s}"
            )

        self.foreach_written_tensor(f)

    # The following functions are executed by the specialized warp for the
    # epilogue load.

    @trace_in_mlir
    def create_epilogue_subtile_tensors(self, tidx, epi_tile):
        """Setup the pipelines reading the EFC supplemental tensors."""
        self.bGS_sC = {}
        self.bGS_gC_partitioned = {}
        # cp.async TiledCopy per ``ASYNC_GMEM_LOAD`` tensor; consumed
        # in ``load_tensor_subtiles`` to issue the per-subtile copies.
        self.tiled_copy_g2s = {}

        def f(tensor_name, attributes):
            # Three-way dispatch: direct sync (no staging),
            # ``ASYNC_GMEM_LOAD`` (cp.async-staged), TMA
            # (descriptor-staged).
            if attributes.is_direct:
                # No staged-pipeline setup for direct reads -- the load
                # fires inline in the consumer warp's body.
                return
            if attributes.transport is Transport.ASYNC_GMEM_LOAD:
                # Resolve ``num_bits_per_copy`` the same way the JIT
                # side did when it built ``async_load_atom``: user
                # override if any, else the 128-bit default.
                width = (
                    attributes.num_bits_per_copy
                    if attributes.num_bits_per_copy is not None
                    else 128
                )
                # The cp.async load runs on a single warp (its own load
                # agent), so its copy is partitioned by the warp-local
                # lane index rather than the CTA-wide ``tidx``.
                lane_idx = cute.arch.lane_idx()
                # Pass the RAW ``(M, N, L)`` gmem tensor (not
                # ``tCgC_read``, which is ``thr_mma.partition_C(...)``
                # -- a nested-tuple shape that hides M-stride info from
                # the cp.async alignment verifier).  The helper does
                # its own ``local_tile`` after injecting alignment.
                (
                    self.tiled_copy_g2s[tensor_name],
                    self.bGS_sC[tensor_name],
                    self.bGS_gC_partitioned[tensor_name],
                ) = self.operation.epilogue_gmem_copy_and_partition_async(
                    lane_idx,
                    self.parameter[f"{tensor_name}_async_load_atom"],
                    self.parameter[f"{tensor_name}_gmem_tensor_read"],
                    self.efc.jit.epi_tile_of(tensor_name, epi_tile),
                    self.smem_read[tensor_name],
                    self.efc.jit.tensor_dtype[tensor_name],
                    num_bits_per_copy=width,
                    num_load_warp_threads=32,
                )
                return
            # TMA-staged read: descriptor-driven partition built from
            # the ``_tma_atom_read`` JIT parameter.
            (
                _,
                self.bGS_sC[tensor_name],
                self.bGS_gC_partitioned[tensor_name],
            ) = self.operation.epilogue_gmem_copy_and_partition(
                tidx,
                self.parameter[f"{tensor_name}_tma_atom_read"],
                self.tCgC_read[tensor_name],
                self.efc.jit.epi_tile_of(tensor_name, epi_tile),
                self.smem_read[tensor_name],
            )

        self.foreach_read_tensor(f)

    @trace_in_mlir
    def load_tensor_subtiles(self, subtile_idx, c_pipeline, c_pipeline_producer_state):
        """Load the subtiles of the EFC tensors."""

        def f(tensor_name, attributes):
            # Three-way dispatch mirrors ``create_epilogue_subtile_tensors``:
            # direct sync (no-op here; the consumer warp's body issues
            # the direct load inline), ``ASYNC_GMEM_LOAD`` (cp.async
            # G2S), TMA (descriptor G2S).
            if attributes.is_direct:
                # Direct-read tensors are loaded inline by the EFC body
                # (``Tensor.load(via=Transport.SYNC_GMEM_LOAD)``),
                # bypassing the staged-load pipeline entirely.
                return
            if attributes.transport is Transport.ASYNC_GMEM_LOAD:
                # cp.async GMEM -> SMEM: every thread in the load warp
                # issues its own copies; each thread fences them on the
                # stage barrier via ``cp_async_mbarrier_arrive_noinc`` in
                # the caller (the per-thread cp.async arrival).
                src = self.bGS_gC[tensor_name][(None, subtile_idx)]
                # The cp.async atom verifier reads the *pointer's*
                # ``align`` annotation directly (CuteNvGPU
                # ``CopyAtomSIMTAsyncCopyType::verify``), not the
                # layout/strides; and the chain of slices from the JIT
                # tensor down to this per-subtile view drops that
                # annotation, leaving the gmem ptr at element (32-bit)
                # alignment.  Re-assert it here on the fully-offset
                # source: the per-thread + per-subtile base is a
                # multiple of ``num_bits_per_copy`` bits, because the
                # tensor base is 16B-aligned (``cute_tensor_like``
                # ``assumed_align``), the M stride was ``cute.assume``d
                # divisible by the copy width, and the N / subtile
                # offsets are copy-width multiples by construction.
                align_bytes = (attributes.num_bits_per_copy or 128) // 8
                src = cutlass.cute.make_tensor(
                    cutlass.cute.make_ptr(
                        src.iterator.dtype,
                        src.iterator.toint(),
                        src.iterator.memspace,
                        assumed_align=align_bytes,
                    ),
                    src.layout,
                )
                cutlass.cute.copy(
                    self.tiled_copy_g2s[tensor_name],
                    src,
                    self.bGS_sC[tensor_name][(None, c_pipeline_producer_state.index)],
                )
                return
            # TMA-staged read: hardware-async GMEM -> SMEM through the
            # descriptor.  The TMA copy's hardware completion drives
            # the mbarrier's tx_count side; the +1 arrival slot is
            # satisfied by the elected-thread ``mbarrier_arrive`` in
            # the caller.
            cutlass.cute.copy(
                self.parameter[f"{tensor_name}_tma_atom_read"],
                self.bGS_gC[tensor_name][(None, subtile_idx)],
                self.bGS_sC[tensor_name][(None, c_pipeline_producer_state.index)],
                tma_bar_ptr=c_pipeline.producer_get_barrier(c_pipeline_producer_state),
            )

        self.foreach_read_tensor(f)


class _EFC(common_efc.EFC[_DenseGemmEFCJIT, _DenseGemmEFCKernel]):
    """Type-narrowed ``common_efc.EFC`` for the ``DenseGemmEFC`` operation.

    The framework's ``EFC`` is generic over its host- and device-side
    companion classes.  Static analysers vary in how completely they
    propagate ``Generic[JITT, KernelT]`` parameters through attribute
    accesses; subclassing here with the concrete companion classes
    spelled out as plain class-level annotations gives every analyser
    a direct attribute-to-type mapping, so ``self.efc.jit.<method>``
    and ``self.efc.kernel.<method>`` resolve to this operation's
    concrete companions regardless of how the analyser handles
    ``TypeVar`` substitution.

    The class body is otherwise empty: at runtime this is a thin
    alias whose ``__init__`` is inherited from ``common_efc.EFC``.
    """

    # Restate the base class's ``jit: JITT`` / ``kernel: KernelT``
    # annotations with the concrete companion types so analysers that
    # do not propagate ``Generic`` parameters still see the right type.
    jit: _DenseGemmEFCJIT
    kernel: _DenseGemmEFCKernel


class DenseGemmEFC:
    """Base class for batched GEMM with custom epilogue fusion using EFC.

    This class provides the core infrastructure for persistent batched GEMM operations
    with customizable epilogue fusion. Subclasses define specific epilogue behaviors
    by providing an epilogue configuration function that describes operations on the
    accumulator and supplemental tensors.

    The class handles:
    - GEMM mainloop (A * B computation)
    - TMA-based memory operations
    - Warp specialization
    - Persistent tile scheduling
    - EFC (Epilogue Fusion Configuration) integration
    - CLI argument parsing (extensible via CLIParser.more_parsing())
    - Tensor creation and validation

    :param acc_dtype: Data type for accumulation during computation
    :type acc_dtype: type[cutlass.Numeric]
    :param epi_dtype: Data type for epilogue operation
    :type epi_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for advanced thread cooperation
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: tuple[int, int]
    :param swizzle_size: Number of clusters visited along ``raster_along`` before
        moving to the next row or column of clusters, to improve L2 reuse. 1 disables swizzling
    :type swizzle_size: int
    :param raster_along: Rasterization order of clusters, "m" or "n"
    :type raster_along: str
    :param epilogue_function_configuration: Function defining the epilogue behavior via EFC
    :type epilogue_function_configuration: Callable

    :note: Supported A/B data types:
        - TFloat32
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2
        (A and B must share a data type, except the two fp8 formats may mix)

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported supplemental tensor data types (epilogue-dependent):
        - Float32 (for float32 and int32 accumulator data types)
        - Int32 (for float32 and int32 accumulator data types)
        - Float16/BFloat16 (for fp16 and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16

    Example:
        >>> def my_epilogue(efc_config, alpha, beta, output_tensor, input_tensor):
        ...     result = efc_config.accum() * alpha + input_tensor.load() * beta
        ...     output_tensor.store(result)
        ...
        >>> gemm = DenseGemmEFC(
        ...     acc_dtype=cutlass.Float32,
        ...     epi_dtype=cutlass.Float32,
        ...     use_2cta_instrs=True,
        ...     mma_tiler_mn=(128, 128),
        ...     cluster_shape_mn=(2, 2),
        ...     epilogue_function_configuration=my_epilogue
        ... )
    """

    # ----- Companion-class hookup for the EFC framework -----
    # When EFC instantiates its host- and device-side companions it
    # looks them up as `self.operation.JIT(...)` and
    # `self.efc.operation.Kernel(...)` respectively.  We expose our
    # subclasses (with the GEMM-pipeline-shaped methods that used
    # to live in the framework) as class attributes here.
    JIT = _DenseGemmEFCJIT
    Kernel = _DenseGemmEFCKernel

    # Target architecture for the TMEM budget (``compute_num_tmem_alloc_cols``
    # and subclass ``compute_stages``); arch subclasses override it.  SMEM
    # capacity is queried from the compilation target instead.
    arch = "sm_100"

    def __init__(
        self,
        acc_dtype: type[cutlass.Numeric],
        epi_dtype: type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        epilogue_function_configuration: typing.Callable,
        swizzle_size: int = 1,
        raster_along: typing.Literal["m", "n"] = "m",
    ):
        """Initializes the configuration for a Blackwell dense GEMM kernel with EFC.

        This configuration includes several key aspects:

        1.  MMA Instruction Settings (tcgen05):
            - acc_dtype: Data type for MMA accumulator.
            - mma_tiler_mn: The (M, N) shape of the MMA instruction tiler.
            - use_2cta_instrs: Boolean indicating if the tcgen05 MMA variant
              with cta_group=2 should be used.

        2.  Cluster Shape:
            - cluster_shape_mn: The (ClusterM, ClusterN) shape of the CTA cluster.

        3.  Epilogue Configuration:
            - epilogue_function_configuration: Defines custom epilogue behavior
              that operates on accumulator and supplemental tensors.

        :param acc_dtype: Data type of the accumulator.
        :type acc_dtype: type[cutlass.Numeric]
        :param epi_dtype: Data type of the epilogue.
        :type epi_dtype: type[cutlass.Numeric]
        :param use_2cta_instrs: Boolean, True to use cta_group=2 MMA variant.
        :type use_2cta_instrs: bool
        :param mma_tiler_mn: tuple (M, N) shape of the MMA instruction.
        :type mma_tiler_mn: tuple[int, int]
        :param cluster_shape_mn: tuple (ClusterM, ClusterN) shape of the cluster.
        :type cluster_shape_mn: tuple[int, int]
        :param epilogue_function_configuration: Function defining epilogue behavior via EFC.
        :type epilogue_function_configuration: Callable
        :param swizzle_size: Number of clusters visited along ``raster_along``
            before moving to the next row or column of clusters. 1 disables swizzling.
        :type swizzle_size: int
        :param raster_along: Rasterization order of clusters, "m" or "n".
        :type raster_along: str
        """

        self.acc_dtype: type[cutlass.Numeric] = acc_dtype
        self.epi_dtype: type[cutlass.Numeric] = epi_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.cluster_shape_mn = cluster_shape_mn
        if raster_along not in ("m", "n"):
            raise ValueError(
                f'Invalid raster_along={raster_along!r}. Expected "m" or "n".'
            )
        # swizzle_size is validated by PersistentTileSchedulerParams.
        self.swizzle_size = swizzle_size
        self.raster_along = raster_along
        # K dimension is deferred in _setup_attributes
        self.mma_tiler_mn = mma_tiler_mn
        self.mma_tiler = (*mma_tiler_mn, 1)

        # The accumulator's epilogue view uses the epilogue dtype.
        self.c_dtype = self.epi_dtype

        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.occupancy = 1
        # Block-scaled (MX) mainloop support.  When an arch subclass turns
        # this on it must also provide ``sf_vec_size`` and an SF-aware
        # ``_create_tiled_mma`` / ``_create_tiled_mma_sfb``; every SF code
        # path below is const_expr-pruned when the flag is off.
        self.has_scale_factors = False
        self.sf_dtype: type[cutlass.Numeric] | None = None
        self.sf_vec_size: int | None = None
        # Set specialized warp ids:

        # The warps responsible for computing the epilogue function and storing
        # the results.
        self.epilogue_warp_id = (0, 1, 2, 3)
        # The warp responsible for computing the matrix multiplication.
        self.mma_warp_id = 4
        # The warp responsible for loading the tensors A & B to feed the MMA.
        self.tma_warp_id = 5
        # The warp responsible for loading the auxiliary tensors used in the epilogue.
        self.epilogue_load_warp_id = 6
        # Load-warp thread count, used for the per-thread cp.async arrival count.
        self.num_epilogue_load_threads = 32
        self.threads_per_cta = 32 * len(
            (
                self.mma_warp_id,
                self.tma_warp_id,
                *self.epilogue_warp_id,
                self.epilogue_load_warp_id,
            )
        )
        # Barrier ids for cta sync, epilogue sync and tmem ptr sync.
        self.epilogue_sync_bar_id = 1
        self.tmem_alloc_sync_bar_id = 2
        self.tmem_dealloc_sync_bar_id = 3

        # Setup the EFC from the given function representing the epilogue
        # configuration.  Construct the local ``_EFC`` subclass rather
        # than ``common_efc.EFC`` directly: ``_EFC`` carries explicit
        # ``jit`` / ``kernel`` annotations to this operation's concrete
        # companion classes, so every static analyser resolves
        # ``self.efc.jit`` / ``self.efc.kernel`` correctly without
        # depending on its handling of generic-parameter propagation.
        self.efc = _EFC(self, epilogue_function_configuration)

    def _create_tiled_mma(self):
        """Make a tiled MMA atom with given data type, leading dimension, CTA
        group and MMA tile shape. Use SMEM operand source for A."""
        return utils.sm100.make_trivial_tiled_mma(
            self.a_dtype,
            self.b_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            self.mma_tiler[:2],
        )

    def _setup_attributes(self):
        """Set up configurations that are dependent on GEMM inputs

        This method configures various attributes based on the input tensor properties
        (data types, leading dimensions) and kernel settings:
        - Configuring tiled MMA
        - Computing MMA/cluster/tile shapes
        - Computing cluster layout
        - Computing multicast CTAs for A/B
        - Computing epilogue subtile
        - Setting up A/B/C/D stage counts in shared memory
        - Computing A/B/C/D shared memory layout
        - Computing tensor memory allocation columns
        """
        # Get the right tiled MMA.
        self._tiled_mma = self._create_tiled_mma()
        log(f"{self._tiled_mma = !s}")

        # Compute mma/cluster/tile shapes
        mma_inst_shape_k = cute.size(self._tiled_mma.shape_mnk, mode=[2])
        # Selected-configuration record (like mma_tiler): the instruction K
        # as a plain int -- the tiled-MMA value itself is region-bound and
        # unusable after compilation.
        self.mma_inst_shape_k = mma_inst_shape_k
        # K instructions per A/B pipeline stage: as many as fill one
        # 128-byte swizzle period of K, keeping stage boundaries on swizzle
        # periods (4 on SM100's 32B-of-K instructions, 2 on Rubin's fp8
        # K=64).
        mma_inst_tile_k = 128 // (mma_inst_shape_k * self.a_dtype.width // 8)
        # Extend mma_tiler with k-dimension (MMA_M, MMA_N, MMA_K)
        self.mma_tiler = (
            self.mma_tiler[0],
            self.mma_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        log(f"{self.mma_tiler = !s}")
        # CTA tiler with the 2CTA instruction correction.
        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // cute.size(self._tiled_mma.thr_id.shape),
            self.mma_tiler[1],
            self.mma_tiler[2],
        )
        log(f"{self.cta_tile_shape_mnk = !s}")
        # Compute cluster layout, V for the 2CTA instructions.
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (self._tiled_mma.thr_id.shape,),
        )
        log(f"{cute.make_layout((*self.cluster_shape_mn, 1)) = !s}")
        log(f"{self.cluster_layout_vmnk = !s}")
        # Compute number of multicast CTAs for A/B
        self.num_mcast_ctas_a = cute.size(self.cluster_layout_vmnk.shape[2])
        self.num_mcast_ctas_b = cute.size(self.cluster_layout_vmnk.shape[1])
        self.is_a_mcast = self.num_mcast_ctas_a > 1
        self.is_b_mcast = self.num_mcast_ctas_b > 1
        log(f"{self.num_mcast_ctas_a = }, {self.num_mcast_ctas_b = }")
        log(f"{self.is_a_mcast = }, {self.is_b_mcast = }")

        # Compute epilogue (EPI_TILE_M, EPI_TILE_N) subtile of cta_tile_shape_mnk
        # according to some heuristics.
        self.epi_tile = sm100_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            layout_d=self.d_layout,
            elem_ty_d=self.d_dtype,
            layout_c=self.c_layout,
            elem_ty_c=self.c_dtype,
        )
        log(f"{self.epi_tile = !s}")

        # Shared memory capacity of the compilation target.
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()

        # Setup A/B/C/D pipeline stage count in shared memory and ACC stage
        # count in tensor memory.
        # Blockscaled mainloop: SF TMEM footprint first, since compute_stages
        # fits the accumulator stages around it.
        if self.has_scale_factors:
            self._setup_sf_tmem_attributes()

        self.compute_stages()
        log(f"{self.num_acc_stage = }, {self.num_ab_stage = }, {self.num_c_stage = }")
        # Compute A/B shared memory layout
        self.a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            self._tiled_mma,
            self.mma_tiler,
            self.a_dtype,
            self.num_ab_stage,
        )
        log(f"{self.a_smem_layout_staged = !s}")
        self.b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            self._tiled_mma,
            self.mma_tiler,
            self.b_dtype,
            self.num_ab_stage,
        )
        log(f"{self.b_smem_layout_staged = !s}")
        # Get the smem_layout for the tensors used in the EFC.
        self.efc.jit.smem_layout()

        # Blockscaled mainloop: staged SF SMEM layouts (need num_ab_stage).
        if self.has_scale_factors:
            self._setup_sf_smem_layouts()

        # Compute the number of tensor memory allocation columns
        self.compute_num_tmem_alloc_cols()

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        *supplemental_parameters,
    ):
        """Execute the GEMM operation in steps:
        - Setup static attributes before smem/grid/tma computation
        - Setup TMA load/store atoms and tensors
        - Compute grid size with regard to hardware constraints
        - Define shared storage for kernel
        - Launch the kernel synchronously

        :param a: Input tensor A.
        :type a: cute.Tensor
        :param b: Input tensor B.
        :type b: cute.Tensor
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr
        :param stream: CUDA stream for asynchronous execution.
        :type stream: cuda.CUstream
        :param supplemental_parameters: Variadic epilogue parameters (tensors and scalars).
        :raises TypeError: If input data types are incompatible with the MMA instruction.
        """
        self._call_impl(
            a, b, None, None, max_active_clusters, stream, supplemental_parameters
        )

    @cute.jit
    def _call_impl(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        sfa: typing.Optional[cute.Tensor],
        sfb: typing.Optional[cute.Tensor],
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
        supplemental_parameters: tuple,
    ):
        """Shared body of ``__call__``: trace-time setup plus kernel launch.

        Both jit entry points delegate here: the dense ``__call__`` and the
        block-scaled subclass's, which adds the SFA/SFB parameters that
        ``__call__``'s variadic tail leaves no slot for.  A nested jit
        function, inlined at trace time, so the body stays a preprocessed
        frame under the PyIR frontend and the launch's specialization record
        holds the entry's own arguments and receiver facts.  ``sfa``/``sfb``
        are the scale-factor tensors in the canonical atom layout
        (``blockscaled_utils.tile_atom_to_shape_SF``); they are ``None``
        exactly when ``has_scale_factors`` is off.
        """
        # Process the variadic parameters.
        self.efc.jit.unpack_parameters(supplemental_parameters)

        # - Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
        # - Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
        # - Supplemental tensors are MxNxL with layout matching the epilogue configuration

        # The output shape (m, n, l) is derived from A(m, k, l) and B(n, k, l).
        self.efc.output_shape = (a.shape[0], b.shape[0], a.shape[2])
        self.efc.jit.handle_remapping()

        # Setup static attributes before smem/grid/tma computation
        self.a_dtype: type[cutlass.Numeric] = a.element_type
        self.b_dtype: type[cutlass.Numeric] = b.element_type
        self.a_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            a
        ).mma_major_mode()
        self.b_major_mode = cutlass.tensor_utils.LayoutEnum.from_tensor(
            b
        ).mma_major_mode()
        if cutlass.const_expr(self.has_scale_factors):
            if cutlass.const_expr(sfa.element_type != sfb.element_type):
                raise TypeError(
                    f"Scale-factor dtypes must match: "
                    f"{sfa.element_type} != {sfb.element_type}"
                )
            self.sf_dtype = sfa.element_type

        # Gather all the auxiliary tensor element data types.
        self.efc.jit.record_tensor_dtypes()

        # There is no D tensor to be used as a returned tensor. In the
        # following, D is used more like a "store" concept. So use the
        # written tensor with the biggest element_type to set up all the tiling
        # heuristics and epilogue store pipeline.
        self.d_name_bigger = self.efc.jit.written_tensor_name_with_bigger_element_type()
        d = self.efc.jit.parameter[self.d_name_bigger]
        self.d_dtype: type[cutlass.Numeric] = d.element_type
        self.d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(d)
        log(f"d{self.d_name_bigger} = {d!s}")

        # C is the read tensor with the biggest element_type, if any, used by
        # some heuristics for tiling.
        self.c_dtype = None
        self.c_layout = None
        self.c_name_bigger = self.efc.jit.read_tensor_name_with_bigger_element_type()
        if cutlass.const_expr(self.c_name_bigger):
            # The tensor with the biggest data type might be a broadcast vector.
            c = self.efc.jit.get_remapped_tensor_or_itself(self.c_name_bigger)
            log(f"{self.c_name_bigger = } -> {c = !s}")
            self.c_dtype = c.element_type
            # If only broadcast tensors are read, there is no leading dimension
            # defined, so use the same as the output.
            try:
                self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)
            except ValueError:
                self.c_layout = self.d_layout

        # Check if input data types are compatible with MMA instruction.
        # fp8 A/B may differ (the f8f6f4 kinds decode operand formats
        # independently); every other pair is rejected (see _FP8_DTYPES).
        if cutlass.const_expr(
            self.a_dtype != self.b_dtype
            and not (self.a_dtype in _FP8_DTYPES and self.b_dtype in _FP8_DTYPES)
        ):
            raise TypeError(f"Types must match: {self.a_dtype} != {self.b_dtype}")

        # Setup attributes that depend on gemm inputs
        self._setup_attributes()

        atom_thr_size = cute.size(self._tiled_mma.thr_id.shape)

        # Setup TMA load for A
        a_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        log(f"{a_op = !s}")
        # Get rid of the pipeline dimension.
        a_smem_layout = cute.select(
            self.a_smem_layout_staged,
            mode=list(range(cute.rank(self.a_smem_layout_staged) - 1)),
        )
        log(f"{a_smem_layout = !s}")
        tma_atom_a, tma_tensor_a = cute.nvgpu.make_tiled_tma_atom_A(
            a_op,
            a,
            a_smem_layout,
            self.mma_tiler,
            self._tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if a.element_type is cutlass.Float32 else None
            ),
        )
        log(f"{tma_atom_a = !s}")
        log(f"{tma_tensor_a = !s}")
        # Setup TMA load for B
        b_op = utils.sm100.cluster_shape_to_tma_atom_B(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        log(f"{b_op = !s}")
        # Get rid of the pipeline dimension.
        b_smem_layout = cute.select(
            self.b_smem_layout_staged,
            mode=list(range(cute.rank(self.b_smem_layout_staged) - 1)),
        )
        log(f"{b_smem_layout = !s}")
        tma_atom_b, tma_tensor_b = cute.nvgpu.make_tiled_tma_atom_B(
            b_op,
            b,
            b_smem_layout,
            self.mma_tiler,
            self._tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=(
                cutlass.TFloat32 if b.element_type is cutlass.Float32 else None
            ),
        )
        log(f"{tma_atom_b = !s}")
        log(f"{tma_tensor_b = !s}")
        a_copy_size = cute.size_in_bytes(self.a_dtype, a_smem_layout)
        b_copy_size = cute.size_in_bytes(self.b_dtype, b_smem_layout)
        self.num_tma_load_bytes = (a_copy_size + b_copy_size) * atom_thr_size

        # Blockscaled mainloop: TMA machinery for the scale-factor operands
        # (also adds the SF copy bytes to ``num_tma_load_bytes``).
        mainloop_sf_parameters = None
        if cutlass.const_expr(self.has_scale_factors):
            mainloop_sf_parameters = self._create_sf_tma_arguments(sfa, sfb)
        log(f"{self.num_tma_load_bytes = }")

        # Set the TMA related arguments for the tensors used in the EFC.
        self.efc.jit.create_tma_arguments()

        # Compute grid size
        # ``d`` stands in for the problem's MN extent; a narrowed ``d`` is
        # re-viewed at full width so the plain CTA tiler counts the same
        # work tiles the accumulator covers.
        d_num_parts = self.efc.parameter_attributes[
            self.d_name_bigger
        ].accum_split_parts
        if cutlass.const_expr(d_num_parts is not None):
            d = common_efc.extend_split_n(d, d_num_parts)
        self.tile_sched_params, grid = self._compute_grid(
            d,
            self.cta_tile_shape_mnk,
            self.cluster_shape_mn,
            self.swizzle_size,
            self.raster_along,
            max_active_clusters,
        )

        self.efc.jit.create_supplemental_arguments_for_kernel()

        # Launch the kernel synchronously
        self.kernel(
            self._tiled_mma,
            tma_atom_a,
            tma_tensor_a,
            tma_atom_b,
            tma_tensor_b,
            self.cluster_layout_vmnk,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
            self.efc.kernel.pack_arguments(),
            mainloop_sf_parameters,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=(*self.cluster_shape_mn, 1),
            stream=stream,
        )

    def issue_k_tile_gemm(
        self, tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, k_tile, sf_views=None
    ):
        """Issue the MMAs that accumulate one K tile into the output tile.

        Override point for architecture subclasses that change the
        per-K-tile issue pattern (e.g. Bkeep-Breuse dual accumulators)
        without touching the mainloop pipeline machinery.  Straight-line
        trace-time code only: dynamic control flow must stay in
        ``kernel()``, whose body the DSL preprocessor transforms.
        Returns the tiled MMA so its updated ACCUMULATE state is visible to
        the caller's loop-carry analysis.

        ``sf_views`` is the ``(tCtSFA, tCtSFB)`` TMEM view pair, passed
        exactly when ``has_scale_factors`` is on; a block-scaled subclass
        must override this method to consume it.
        """
        assert sf_views is None, (
            "block-scaled MMA issue requires an arch-subclass "
            "issue_k_tile_gemm override"
        )
        tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
        cute.gemm(tiled_mma, tCtAcc, tCrA_blk, tCrB_blk, tCtAcc)
        return tiled_mma

    # ----- Block-scaled (MX) mainloop machinery -----
    #
    # Everything below runs under ``const_expr(self.has_scale_factors)``
    # and follows the reference blockscaled kernel
    # (cute/rubin/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent.py):
    # SFA/SFB are staged GMEM->SMEM by the TMA warp on the A/B pipeline,
    # then SMEM->TMEM (UTCCP) by the MMA warp, and consumed as the
    # ``[operand, sf]`` pairs of the block-scaled MMA, which apply them while
    # accumulating; the epilogue sees the dequantized accumulator.  SFB is
    # staged in whole 128-row scale-factor atoms, so tile N=64 and N=192
    # share one staged window between two neighbouring N tiles: the TMA warp
    # picks the window and the MMA warp offsets its SFB TMEM view (the
    # reference's ``mma_inst_shape_mn[1] in (64, 192)`` branches).

    def _create_tiled_mma_sfb(self):
        """Build the CTA-group-ONE tiled MMA used to partition/load SFB
        (its N is padded to the 128-column SF datapath).  Arch subclasses
        with ``has_scale_factors`` must override."""
        raise NotImplementedError(
            "block-scaled EFC requires an arch-subclass _create_tiled_mma_sfb"
        )

    def _setup_sf_tmem_attributes(self):
        """SF instruction/cluster geometry, TMEM layouts and column counts
        (host side, before compute_stages, which fits the accumulator
        stages around the SF columns).

        Requires ``self._sf_mma_inst_shape`` -- the block-scaled MMA
        instruction (M, N, K) -- recorded by the subclass's
        ``_create_tiled_mma``.
        """
        inst_m, inst_n, inst_k = self._sf_mma_inst_shape
        # SFB is partitioned by a CTA-group-ONE tiled MMA at CTA granularity
        # with N padded to the 128-column SF datapath (reference convention);
        # for 2-CTA MMAs SFB is replicated across the peer CTAs.
        self.mma_inst_shape_sfb = (
            inst_m // (2 if self.use_2cta_instrs else 1),
            cute.round_up(inst_n, 128),
            inst_k,
        )
        self.mma_tiler_sfb = (
            self.mma_inst_shape_sfb[0],
            self.mma_inst_shape_sfb[1],
            self.mma_tiler[2],
        )
        tiled_mma_sfb = self._create_tiled_mma_sfb()
        self.cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma_sfb.thr_id.shape,),
        )
        # TMEM layouts derive from the per-stage SMEM atom (the stage mode
        # is dropped), so a single-stage layout serves before the stage
        # count is known.
        sfa_smem_layout = blockscaled_utils.make_smem_layout_sfa(
            self._tiled_mma, self.mma_tiler, self.sf_vec_size, 1
        )
        sfb_smem_layout = blockscaled_utils.make_smem_layout_sfb(
            self._tiled_mma, self.mma_tiler, self.sf_vec_size, 1
        )
        self.tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
            self._tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                sfa_smem_layout, mode=list(range(cute.rank(sfa_smem_layout) - 1))
            ),
        )
        self.tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
            self._tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.select(
                sfb_smem_layout, mode=list(range(cute.rank(sfb_smem_layout) - 1))
            ),
        )
        # One TMEM column is 32 bits wide and TMEM addresses are affine
        # (row << 16) | col values: recast the layout to 32-bit and mask the
        # cosize to the low 16 bits to count columns.
        self.num_sfa_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFA_layout))
            & 0xFFFF
        )
        self.num_sfb_tmem_cols = (
            cute.cosize(cute.recast_layout(32, self.sf_dtype.width, self.tCtSFB_layout))
            & 0xFFFF
        )
        self.num_sf_tmem_cols = self.num_sfa_tmem_cols + self.num_sfb_tmem_cols
        log(
            f"SF attrs: {self.mma_tiler_sfb = }, {self.num_sfa_tmem_cols = }, "
            f"{self.num_sfb_tmem_cols = }"
        )

    def _setup_sf_smem_layouts(self):
        """Staged SFA/SFB SMEM layouts (host side, after compute_stages:
        they ride the A/B pipeline, so they use its stage count)."""
        self.sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            self._tiled_mma, self.mma_tiler, self.sf_vec_size, self.num_ab_stage
        )
        self.sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            self._tiled_mma, self.mma_tiler, self.sf_vec_size, self.num_ab_stage
        )

    def _create_sf_tma_arguments(self, sfa, sfb):
        """TMA atoms/tensors for SFA/SFB, packed as the kernel's
        ``mainloop_sf_parameters`` tuple.  Also adds the SF stage bytes to
        ``num_tma_load_bytes`` -- the SF copies ride the A/B pipeline's
        transaction count."""
        tiled_mma_sfb = self._create_tiled_mma_sfb()
        sfa_op = utils.sm100.cluster_shape_to_tma_atom_A(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        sfa_smem_layout = cute.slice_(
            self.sfa_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfa, tma_tensor_sfa = cute.nvgpu.make_tiled_tma_atom_A(
            sfa_op,
            sfa,
            sfa_smem_layout,
            self.mma_tiler,
            self._tiled_mma,
            self.cluster_layout_vmnk.shape,
            internal_type=cutlass.Int16,
        )
        sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(
            self.cluster_shape_mn, self._tiled_mma.thr_id
        )
        sfb_smem_layout = cute.slice_(
            self.sfb_smem_layout_staged, (None, None, None, 0)
        )
        tma_atom_sfb, tma_tensor_sfb = cute.nvgpu.make_tiled_tma_atom_B(
            sfb_op,
            sfb,
            sfb_smem_layout,
            self.mma_tiler_sfb,
            tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk.shape,
            internal_type=cutlass.Int16,
        )
        sfa_copy_size = cute.size_in_bytes(self.sf_dtype, sfa_smem_layout)
        sfb_copy_size = cute.size_in_bytes(self.sf_dtype, sfb_smem_layout)
        atom_thr_size = cute.size(self._tiled_mma.thr_id.shape)
        self.num_tma_load_bytes += (sfa_copy_size + sfb_copy_size) * atom_thr_size
        # The layouts ride the kernel-argument tuple: layout values are
        # region-bound, so the kernel takes them as arguments.
        return (
            tma_atom_sfa,
            tma_tensor_sfa,
            tma_atom_sfb,
            tma_tensor_sfb,
            tiled_mma_sfb,
            self.cluster_layout_sfb_vmnk,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.tCtSFA_layout,
            self.tCtSFB_layout,
        )

    def _mainloop_s2t_copy_and_partition(self, sSF, tSF):
        """Make the SMEM->TMEM (UTCCP) tiled copy for one scale-factor
        tensor and partition its source/destination.

        :param sSF: (MMA, MMA_MN, MMA_K, STAGE) scale factors in SMEM
        :param tSF: (MMA, MMA_MN, MMA_K) scale factors in TMEM
        """
        # (MMA, MMA_MN, MMA_K, STAGE)
        tCsSF_compact = cute.filter_zeros(sSF)
        # (MMA, MMA_MN, MMA_K)
        tCtSF_compact = cute.filter_zeros(tSF)

        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )
        tiled_copy_s2t = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSF_compact)
        thr_copy_s2t = tiled_copy_s2t.get_slice(0)

        # A 4x32dp128bit copy replicates one SMEM core matrix across four
        # TMEM ones, and the tiled copy takes its tiler from TMEM, so the
        # source has to spell the replication out before it can be
        # partitioned with that tiler.
        tCsSF_compact_bcast = tcgen05.append_s2t_broadcast_mode(
            copy_atom_s2t.op, tCsSF_compact
        )
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        tCsSF_compact_s2t_ = thr_copy_s2t.partition_S(tCsSF_compact_bcast)
        tCsSF_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
            tiled_copy_s2t, tCsSF_compact_s2t_
        )
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K)
        tCtSF_compact_s2t = thr_copy_s2t.partition_D(tCtSF_compact)

        return _S2TCopyBundle(tiled_copy_s2t, tCsSF_compact_s2t, tCtSF_compact_s2t)

    # A jit frame, so the preprocessor stages the `if` on the runtime slot count.
    @cute.jit
    def _zero_sf_padding(self, sf_ptr, stage_bytes, stage, valid_slots, lane_idx):
        """Zero the scale slots past K in one stage of one scale buffer.

        A stage is a row of 512-byte atoms, one per 128 rows (M for SFA, N
        for SFB) by 4 K slots; when a K tile spans several atoms along K
        (fp4), the K atoms of one 128-row block are stored back to back.
        Inside an atom, row r keeps its 4 slots in one 4-byte group::

            byte(r, slot) = 16 * (r % 32) + 4 * (r // 32) + slot

                        bytes +0..3  | +4..7   | +8..11  | +12..15
            lane  0 @   0: row   0   | row  32 | row  64 | row  96
            lane  1 @  16: row   1   | row  33 | row  65 | row  97
            ...
            lane 31 @ 496: row  31   | row  63 | row  95 | row 127

        so lane t of the MMA warp (``cute.arch.lane_idx()``) owns the 16
        bytes at 16t: slots 0..3 of rows t, t+32, t+64 and t+96.  Slot j of
        the tile's K atom kb is padding when ``4 * kb + j >= valid_slots``;
        the lane stores a zero byte over it in each of its four rows.  Byte
        stores through a pointer, so the same code zeroes the peer CTA's
        stage via a DSMEM pointer (tensor stores reject that address space).
        """
        k_atoms = self.mma_tiler[2] // (4 * self.sf_vec_size)
        base = sf_ptr + (stage * stage_bytes + lane_idx * 16)
        for atom in cutlass.range_constexpr(stage_bytes // 512):
            kb = atom % k_atoms
            for j in cutlass.range_constexpr(4):
                if valid_slots <= 4 * kb + j:
                    for row_group in cutlass.range_constexpr(4):
                        (base + (atom * 512 + row_group * 4 + j)).store(
                            cutlass.Uint8(0)
                        )

    def _zero_sf_padding_stage(
        self, stage, sSFA, sSFB, valid_slots, cta_rank_in_cluster
    ):
        """Zero the scale slots past K in one stage of SFA and SFB right
        before the stage is copied SMEM->TMEM.  Under 2-CTA the leader (the
        CTA running this loop; its barrier covers both CTAs' TMA loads) also
        zeroes the peer's stage through distributed SMEM; the peer is the
        next cluster rank since V is the stride-1 cluster mode.  The proxy
        fence orders the stores before the tcgen05.cp that reads them."""
        lane_idx = cute.arch.lane_idx()
        for sSF in (sSFA, sSFB):
            stage_bytes = cute.cosize(sSF.layout) // self.num_ab_stage
            sf_ptr = cute.recast_ptr(sSF.iterator, dtype=cutlass.Uint8)
            self._zero_sf_padding(sf_ptr, stage_bytes, stage, valid_slots, lane_idx)
            if cutlass.const_expr(self.use_2cta_instrs):
                peer_ptr = cute.arch.map_dsmem_ptr(sf_ptr, cta_rank_in_cluster + 1)
                self._zero_sf_padding(
                    peer_ptr, stage_bytes, stage, valid_slots, lane_idx
                )
        if cutlass.const_expr(self.use_2cta_instrs):
            cute.arch.fence_proxy("async.shared", space="cluster")
        else:
            cute.arch.fence_proxy("async.shared", space="cta")

    def _mainloop_s2t_copies(self, stage_idx, sfa_s2t_bundle, sfb_s2t_bundle):
        """Stage one pipeline stage's SFA/SFB from SMEM into TMEM."""
        # ((ATOM_V, REST_V), Rest_Tiler, MMA_MN, MMA_K, STAGE)
        s2t_stage_coord = (None, None, None, None, stage_idx)
        cute.copy(
            sfa_s2t_bundle.tiled_copy,
            sfa_s2t_bundle.sSF_compact[s2t_stage_coord],
            sfa_s2t_bundle.tSF_compact,
        )
        cute.copy(
            sfb_s2t_bundle.tiled_copy,
            sfb_s2t_bundle.sSF_compact[s2t_stage_coord],
            sfb_s2t_bundle.tSF_compact,
        )

    # GPU device kernel
    @cute.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        tma_atom_a: cute.CopyAtom,
        mA_mkl: cute.Tensor,
        tma_atom_b: cute.CopyAtom,
        mB_nkl: cute.Tensor,
        cluster_layout_vmnk: cute.Layout,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        epi_tile: cute.Tile,
        tile_sched_params: PersistentTileSchedulerParams,
        supplemental_parameters: tuple,
        mainloop_sf_parameters: tuple,
    ):
        """
        GPU device kernel performing the Persistent batched GEMM computation.
        """
        # Process the variadic parameters.
        self.efc.kernel.unpack_parameters(supplemental_parameters)
        # Block-scaled mainloop dynamic values (None when has_scale_factors
        # is off; the static SF layouts are read from self).
        if cutlass.const_expr(self.has_scale_factors):
            (
                tma_atom_sfa,
                mSFA_mkl,
                tma_atom_sfb,
                mSFB_nkl,
                tiled_mma_sfb,
                cluster_layout_sfb_vmnk,
                sfa_smem_layout_staged,
                sfb_smem_layout_staged,
                tCtSFA_layout,
                tCtSFB_layout,
            ) = mainloop_sf_parameters

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        #
        # Prefetch TMA descriptors
        #
        if warp_idx == self.tma_warp_id:
            cpasync.prefetch_descriptor(tma_atom_a)
            cpasync.prefetch_descriptor(tma_atom_b)
            if cutlass.const_expr(self.has_scale_factors):
                cpasync.prefetch_descriptor(tma_atom_sfa)
                cpasync.prefetch_descriptor(tma_atom_sfb)
            # Prefetch the TMA descriptors for all the supplemental tensors.
            self.efc.kernel.prefetch_tma_descriptors()

        #
        # Setup cta/thread coordinates
        #
        # Coords inside cluster
        bidx, bidy, bidz = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Coord inside cta
        tidx, _, _ = cute.arch.thread_idx()

        #
        # Alloc and init: a+b full/empty, accumulator full/empty, tensor memory dealloc barrier
        #
        self.buffer_align_bytes = 1024

        # Define shared storage for kernel
        @cute.struct
        class SharedStorage:
            ab_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            ab_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_ab_stage]
            acc_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            acc_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_acc_stage]
            # Barriers used by the supplemental load tensor pipeline.
            c_full_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_c_stage]
            c_empty_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self.num_c_stage]
            tmem_dealloc_mbar: cutlass.Int64
            tmem_holding_buf: cutlass.Int32
            # (MMA, MMA_M, MMA_K, STAGE)
            sA: cute.struct.Align[
                cute.struct.MemRange[
                    self.a_dtype, cute.cosize(a_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]
            # (MMA, MMA_N, MMA_K, STAGE)
            sB: cute.struct.Align[
                cute.struct.MemRange[
                    self.b_dtype, cute.cosize(b_smem_layout_staged.outer)
                ],
                self.buffer_align_bytes,
            ]

        self.shared_storage = SharedStorage

        self.smem = cutlass.memory.SmemAllocator()
        storage = self.smem.allocate(self.shared_storage)

        # Blockscaled mainloop: staged SFA/SFB buffers, adjacent to A/B.
        # (MMA, MMA_M, MMA_K, STAGE) / (MMA, MMA_N, MMA_K, STAGE)
        if cutlass.const_expr(self.has_scale_factors):
            sSFA = self.smem.allocate_tensor(
                element_type=self.sf_dtype,
                layout=sfa_smem_layout_staged,
                byte_alignment=self.buffer_align_bytes,
            )
            sSFB = self.smem.allocate_tensor(
                element_type=self.sf_dtype,
                layout=sfb_smem_layout_staged,
                byte_alignment=self.buffer_align_bytes,
            )

        # Allocate the shared memory for all the supplemental tensors.
        self.efc.kernel.allocate_smem()

        # Initialize mainloop ab_pipeline (barrier) and states
        ab_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        ab_pipeline_consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Warp)
        ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
            barrier_storage=storage.ab_full_mbar_ptr.data_ptr(),
            num_stages=self.num_ab_stage,
            producer_group=ab_pipeline_producer_group,
            consumer_group=ab_pipeline_consumer_group,
            tx_count=self.num_tma_load_bytes,
            cta_layout_vmnk=cluster_layout_vmnk,
            enable_multicast_signaling=True,
            defer_sync=True,
        ).make_participants()

        # Initialize acc_pipeline (barrier) and states
        acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        num_acc_consumer_threads = len(self.epilogue_warp_id) * (
            2 if self.use_2cta_instrs else 1
        )
        acc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_acc_consumer_threads
        )
        acc_pipeline = pipeline.PipelineUmmaAsync.create(
            barrier_storage=storage.acc_full_mbar_ptr.data_ptr(),
            num_stages=self.num_acc_stage,
            producer_group=acc_pipeline_producer_group,
            consumer_group=acc_pipeline_consumer_group,
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        )

        # Single load pipeline for every staged supplemental read, TMA and/or
        # cp.async.  The full-barrier arrival count is the producer's
        # end-of-stage arrival plus, when cp.async is present, one per load-warp
        # thread -- each cp.async thread fences its own copies via
        # ``cp_async_mbarrier_arrive_noinc`` while TMA byte completion drives the
        # tx-count side.  A pure-TMA read keeps the 2-arrival count
        # (``arrive_and_expect_tx`` plus an elected end-of-stage arrive that lets
        # the consumer wait unconditionally even on zero-byte stages).
        c_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            1 + self.num_epilogue_load_threads
            if cutlass.const_expr(self.efc.jit.async_load_atom)
            else 2,
        )
        c_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            len(self.epilogue_warp_id),
        )
        c_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.c_full_mbar_ptr.data_ptr(),
            num_stages=self.num_c_stage,
            producer_group=c_producer_group,
            consumer_group=c_consumer_group,
            # Unlock the barrier when all the tensor bytes have been loaded.
            tx_count=self.efc.jit.total_tma_load_bytes,
            defer_sync=True,
        )

        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=32 * len((self.mma_warp_id, *self.epilogue_warp_id)),
        )
        # Tensor memory dealloc barrier init
        tmem = cutlass.memory.TmemAllocator(
            storage.tmem_holding_buf.ptr,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.epilogue_warp_id[0],
            is_two_cta=self.use_2cta_instrs,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
            # Validate against this operation's arch (sm107: 576 columns,
            # needed by the block-scaled SF carve); default is sm_100.
            arch=self.arch,
        )

        # Cluster arrive after barrier init
        pipeline.pipeline_init_arrive(
            cluster_shape_mn=self.cluster_shape_mn, is_relaxed=True
        )

        #
        # Setup smem tensor A/B
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        sA = storage.sA.get_tensor(
            a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
        )
        # (MMA, MMA_N, MMA_K, STAGE)
        sB = storage.sB.get_tensor(
            b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
        )

        #
        # Compute multicast mask for A/B buffer full
        #
        a_full_mcast_mask = None
        b_full_mcast_mask = None
        if cutlass.const_expr(
            self.is_a_mcast or self.is_b_mcast or self.use_2cta_instrs
        ):
            a_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
            )
            b_full_mcast_mask = cpasync.create_tma_multicast_mask(
                cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=1
            )
        if cutlass.const_expr(self.has_scale_factors):
            # SFA multicasts with A; SFB has its own (CTA-group-ONE) cluster
            # layout because it is replicated across peer CTAs.
            sfa_full_mcast_mask = None
            sfb_full_mcast_mask = None
            block_in_cluster_coord_sfb_vmnk = cluster_layout_sfb_vmnk.get_flat_coord(
                cta_rank_in_cluster
            )
            if cutlass.const_expr(
                self.is_a_mcast or self.is_b_mcast or self.use_2cta_instrs
            ):
                sfa_full_mcast_mask = cpasync.create_tma_multicast_mask(
                    cluster_layout_vmnk, block_in_cluster_coord_vmnk, mcast_mode=2
                )
                sfb_full_mcast_mask = cpasync.create_tma_multicast_mask(
                    cluster_layout_sfb_vmnk,
                    block_in_cluster_coord_sfb_vmnk,
                    mcast_mode=1,
                )

        #
        # Local_tile partition global tensors
        #
        # (bM, bK, loopM, loopK, loopL)
        gA_mkl = cute.local_tile(
            mA_mkl, cute.slice_(self.mma_tiler, (None, 0, None)), (None, None, None)
        )
        # (bN, bK, loopN, loopK, loopL)
        gB_nkl = cute.local_tile(
            mB_nkl, cute.slice_(self.mma_tiler, (0, None, None)), (None, None, None)
        )

        k_tile_cnt = cute.size(gA_mkl, mode=[3])

        #
        # Partition global tensor for TiledMMA_A/B/D
        #
        self.thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
        # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
        tCgA = self.thr_mma.partition_A(gA_mkl)
        log(f"{tCgA = !s}")
        # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
        tCgB = self.thr_mma.partition_B(gB_nkl)
        log(f"{tCgB = !s}")
        # Create the local_tile gX_mnl for all the EFC supplemental tensors.
        self.efc.kernel.partition_global_tensors_for_tiled_mma()
        # Output coordinates (M, N, L) to predicate the direct GMEM accesses.
        self.efc.kernel.partition_output_coordinates(
            (mA_mkl.shape[0], mB_nkl.shape[0], mA_mkl.shape[2])
        )
        if cutlass.const_expr(self.has_scale_factors):
            # (bM, bK, loopM, loopK, loopL)
            gSFA_mkl = cute.local_tile(
                mSFA_mkl,
                cute.slice_(self.mma_tiler, (None, 0, None)),
                (None, None, None),
            )
            # (bN, bK, loopN, loopK, loopL)
            gSFB_nkl = cute.local_tile(
                mSFB_nkl,
                cute.slice_(self.mma_tiler_sfb, (0, None, None)),
                (None, None, None),
            )
            thr_mma_sfb = tiled_mma_sfb.get_slice(mma_tile_coord_v)
            # (MMA, MMA_M, MMA_K, loopM, loopK, loopL)
            tCgSFA = self.thr_mma.partition_A(gSFA_mkl)
            # (MMA, MMA_N, MMA_K, loopN, loopK, loopL)
            tCgSFB = thr_mma_sfb.partition_B(gSFB_nkl)

        #
        # Partition global/shared tensor for TMA load A/B
        #
        # TMA load A partition_S/D
        a_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), tiles_m, tiles_k, tiles_l)
        tAsA, tAgA = cpasync.tma_partition(
            tma_atom_a,
            block_in_cluster_coord_vmnk[2],
            a_cta_layout,
            cute.group_modes(sA, 0, 3),
            cute.group_modes(tCgA, 0, 3),
        )
        # TMA load B partition_S/D
        b_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # ((atom_v, rest_v), STAGE)
        # ((atom_v, rest_v), tiles_n, tiles_k, tiles_l)
        tBsB, tBgB = cpasync.tma_partition(
            tma_atom_b,
            block_in_cluster_coord_vmnk[1],
            b_cta_layout,
            cute.group_modes(sB, 0, 3),
            cute.group_modes(tCgB, 0, 3),
        )
        if cutlass.const_expr(self.has_scale_factors):
            # TMA load SFA partition_S/D: same cluster placement as A.  The
            # SF atom layouts are zero-strided in the replicated modes, so
            # compact both sides with filter_zeros.
            # ((atom_v, rest_v), STAGE) / ((atom_v, rest_v), tiles, tiles_k, tiles_l)
            tAsSFA, tAgSFA = cpasync.tma_partition(
                tma_atom_sfa,
                block_in_cluster_coord_vmnk[2],
                a_cta_layout,
                cute.group_modes(sSFA, 0, 3),
                cute.group_modes(tCgSFA, 0, 3),
            )
            tAsSFA = cute.filter_zeros(tAsSFA)
            tAgSFA = cute.filter_zeros(tAgSFA)
            # TMA load SFB partition_S/D on SFB's own cluster layout.
            sfb_cta_layout = cute.make_layout(
                cute.slice_(cluster_layout_sfb_vmnk, (0, None, 0, 0)).shape
            )
            tBsSFB, tBgSFB = cpasync.tma_partition(
                tma_atom_sfb,
                block_in_cluster_coord_sfb_vmnk[1],
                sfb_cta_layout,
                cute.group_modes(sSFB, 0, 3),
                cute.group_modes(tCgSFB, 0, 3),
            )
            tBsSFB = cute.filter_zeros(tBsSFB)
            tBgSFB = cute.filter_zeros(tBgSFB)

        #
        # Partition shared/tensor memory tensor for TiledMMA_A/B/C/D
        #
        # (MMA, MMA_M, MMA_K, STAGE)
        tCrA = tiled_mma.make_fragment_A(sA)
        log(f"{tCrA = !s}")
        # (MMA, MMA_N, MMA_K, STAGE)
        tCrB = tiled_mma.make_fragment_B(sB)
        log(f"{tCrB = !s}")
        # (MMA, MMA_M, MMA_N)
        acc_shape = tiled_mma.partition_shape_C(self.mma_tiler[:2])
        log(f"{acc_shape = !s}")
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_fake = tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        log(f"{tCtAcc_fake = !s}")

        # Named barriers
        #
        epilogue_sync_barrier = pipeline.NamedBarrier(
            self.epilogue_sync_bar_id, 32 * len(self.epilogue_warp_id)
        )

        #
        # Cluster wait before tensor memory alloc
        #
        pipeline.pipeline_init_wait(cluster_shape_mn=self.cluster_shape_mn)

        #
        # Construct the scheduler, shared by all the specialized warps.
        #
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        #
        # Specialized TMA load warp
        #

        if warp_idx == self.tma_warp_id:
            #
            # Persistent tile scheduling loop
            #
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                #
                # Slice to per mma tile index
                #
                # ((atom_v, rest_v), loopK)
                tAgA_slice = tAgA[
                    (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                ]
                # ((atom_v, rest_v), loopK)
                tBgB_slice = tBgB[
                    (None, mma_tile_coord_mnl[1], None, mma_tile_coord_mnl[2])
                ]
                if cutlass.const_expr(self.has_scale_factors):
                    # ((atom_v, rest_v), loopK)
                    tAgSFA_slice = tAgSFA[
                        (None, mma_tile_coord_mnl[0], None, mma_tile_coord_mnl[2])
                    ]
                    # ((atom_v, rest_v), loopK).  SFB is staged in whole
                    # 128-row scale-factor atoms (``mma_tiler_sfb``), so a
                    # tile N that is not a multiple of 128 shares its staged
                    # window with the neighbouring N tile:
                    #   N=64:  tiles 2j and 2j+1 both load atom j;
                    #   N=192: tile 2j loads atoms [3j, 3j+2), tile 2j+1
                    #          loads [3j+1, 3j+3): a 128-row-shifted 256-row
                    #          window, re-tiled per tile from a shifted view.
                    # The odd tile's data starts 64 rows into the window;
                    # the MMA warp offsets its SFB TMEM view accordingly.
                    if cutlass.const_expr(self.mma_tiler[1] == 192):
                        sfb_atom = 3 * (mma_tile_coord_mnl[1] // 2) + (
                            mma_tile_coord_mnl[1] % 2
                        )
                        mSFB_shifted = cute.domain_offset(
                            (cute.assume(sfb_atom * 128, divby=128), 0, 0),
                            mSFB_nkl,
                        )
                        # (bN, bK, loopK)
                        gSFB_shifted = cute.local_tile(
                            mSFB_shifted,
                            cute.slice_(self.mma_tiler_sfb, (0, None, None)),
                            (0, None, mma_tile_coord_mnl[2]),
                        )
                        # (MMA, MMA_N, MMA_K, loopK)
                        tCgSFB_shifted = thr_mma_sfb.partition_B(gSFB_shifted)
                        _, tBgSFB_slice = cpasync.tma_partition(
                            tma_atom_sfb,
                            block_in_cluster_coord_sfb_vmnk[1],
                            sfb_cta_layout,
                            cute.group_modes(sSFB, 0, 3),
                            cute.group_modes(tCgSFB_shifted, 0, 3),
                        )
                        tBgSFB_slice = cute.filter_zeros(tBgSFB_slice)
                    else:
                        sfb_tile_n = mma_tile_coord_mnl[1]
                        if cutlass.const_expr(self.mma_tiler[1] == 64):
                            sfb_tile_n = mma_tile_coord_mnl[1] // 2
                        tBgSFB_slice = tBgSFB[
                            (None, sfb_tile_n, None, mma_tile_coord_mnl[2])
                        ]

                # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt
                ab_producer.reset()
                peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Tma load loop
                #
                for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                    # Conditionally wait for AB buffer empty
                    handle = ab_producer.acquire_and_advance(peek_ab_empty_status)

                    # TMA load A/B
                    cute.copy(
                        tma_atom_a,
                        tAgA_slice[(None, handle.count)],
                        tAsA[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=a_full_mcast_mask,
                    )
                    cute.copy(
                        tma_atom_b,
                        tBgB_slice[(None, handle.count)],
                        tBsB[(None, handle.index)],
                        tma_bar_ptr=handle.barrier,
                        mcast_mask=b_full_mcast_mask,
                    )
                    if cutlass.const_expr(self.has_scale_factors):
                        # SFA/SFB ride the same stage barrier; their bytes
                        # are part of the pipeline's tx count.
                        cute.copy(
                            tma_atom_sfa,
                            tAgSFA_slice[(None, handle.count)],
                            tAsSFA[(None, handle.index)],
                            tma_bar_ptr=handle.barrier,
                            mcast_mask=sfa_full_mcast_mask,
                        )
                        cute.copy(
                            tma_atom_sfb,
                            tBgSFB_slice[(None, handle.count)],
                            tBsSFB[(None, handle.index)],
                            tma_bar_ptr=handle.barrier,
                            mcast_mask=sfb_full_mcast_mask,
                        )

                    # Peek (try_wait) AB buffer empty for k_tile = prefetch_k_tile_cnt + k_tile + 1
                    peek_ab_empty_status = cutlass.Boolean(1)
                    if handle.count + 1 < k_tile_cnt:
                        peek_ab_empty_status = ab_producer.try_acquire()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait A/B buffer empty
            #
            ab_producer.tail()

        #
        # Specialized MMA warp
        #
        if warp_idx == self.mma_warp_id:
            #
            # Bar sync to retrieve tensor memory ptr from shared mem
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

            if cutlass.const_expr(self.has_scale_factors):
                # SFA/SFB TMEM views, carved right after the accumulator
                # stages (32-bit accumulator columns, asserted in
                # compute_num_tmem_alloc_cols).
                sfa_tmem_ptr = cute.recast_ptr(
                    tmem_ptr + self.num_accumulator_tmem_cols, dtype=self.sf_dtype
                )
                # (MMA, MMA_M, MMA_K)
                tCtSFA = cute.make_tensor(sfa_tmem_ptr, tCtSFA_layout)
                sfb_tmem_ptr = cute.recast_ptr(
                    tmem_ptr + self.num_accumulator_tmem_cols + self.num_sfa_tmem_cols,
                    dtype=self.sf_dtype,
                )
                # (MMA, MMA_N, MMA_K)
                tCtSFB = cute.make_tensor(sfb_tmem_ptr, tCtSFB_layout)
                sfa_s2t_bundle = self._mainloop_s2t_copy_and_partition(sSFA, tCtSFA)
                sfb_s2t_bundle = self._mainloop_s2t_copy_and_partition(sSFB, tCtSFB)
                # Scale slots past K when K is not a tile multiple: the
                # last K tile zeroes them in SMEM (_zero_sf_padding_stage).
                sf_k_rem = cute.size(mA_mkl, mode=[1]) % self.mma_tiler[2]
                sf_valid_slots = cute.ceil_div(sf_k_rem, self.sf_vec_size)
                has_sf_k_pad = sf_k_rem != 0

            #
            # Persistent tile scheduling loop
            #
            acc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_acc_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_producer_state.index)]

                if cutlass.const_expr(self.has_scale_factors):
                    # SFB TMEM view for this tile.  Under the shared N=64 /
                    # N=192 staging (see the TMA warp) the odd N tile's data
                    # starts 64 rows into the staged window: two 32-bit TMEM
                    # columns later, a 128-row atom spanning four.
                    tCtSFB_tile = tCtSFB
                    if cutlass.const_expr(self.mma_tiler[1] in (64, 192)):
                        sfb_tmem_col_offset = (mma_tile_coord_mnl[1] % 2) * 2
                        tCtSFB_tile = cute.make_tensor(
                            cute.recast_ptr(
                                cute.recast_ptr(tCtSFB.iterator, dtype=cutlass.Int32)
                                + sfb_tmem_col_offset,
                                dtype=self.sf_dtype,
                            ),
                            tCtSFB.layout,
                        )

                # Peek (try_wait) AB buffer full for k_tile = 0
                ab_consumer.reset()
                peek_ab_full_status = cutlass.Boolean(1)
                if is_leader_cta:
                    peek_ab_full_status = ab_consumer.try_wait()

                #
                # Wait for accumulator buffer empty
                #
                if is_leader_cta:
                    acc_pipeline.producer_acquire(acc_producer_state)

                #
                # Reset the ACCUMULATE field for each tile
                #
                tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

                #
                # Mma mainloop
                #
                for k_tile in range(k_tile_cnt):
                    if is_leader_cta:
                        # Conditionally wait for AB buffer full
                        handle = ab_consumer.wait_and_advance(peek_ab_full_status)

                        # tCtAcc += tCrA * tCrB (overridable: Bkeep-Breuse changes this).
                        tile_crd = (None, None, None, handle.index)
                        if cutlass.const_expr(self.has_scale_factors):
                            # Last K tile of a ragged K: zero the scale slots past K
                            # (TMA zero-fills A/B there; the slots hold the buffer's
                            # padding) before the stage is copied to TMEM.
                            if k_tile == k_tile_cnt - 1:
                                if has_sf_k_pad:
                                    self._zero_sf_padding_stage(
                                        handle.index,
                                        sSFA,
                                        sSFB,
                                        sf_valid_slots,
                                        cta_rank_in_cluster,
                                    )
                            # Stage this stage's scale factors SMEM->TMEM
                            # before the MMAs that read them.
                            self._mainloop_s2t_copies(
                                handle.index, sfa_s2t_bundle, sfb_s2t_bundle
                            )
                            tiled_mma = self.issue_k_tile_gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[tile_crd],
                                tCrB[tile_crd],
                                k_tile,
                                sf_views=(tCtSFA, tCtSFB_tile),
                            )
                        else:
                            tiled_mma = self.issue_k_tile_gemm(
                                tiled_mma,
                                tCtAcc,
                                tCrA[tile_crd],
                                tCrB[tile_crd],
                                k_tile,
                            )
                        # Async arrive AB buffer empty
                        handle.release()

                        # Peek (try_wait) AB buffer full for k_tile = k_tile + 1
                        peek_ab_full_status = cutlass.Boolean(1)
                        if handle.count + 1 < k_tile_cnt:
                            peek_ab_full_status = ab_consumer.try_wait()

                #
                # Async arrive accumulator buffer full
                #
                if is_leader_cta:
                    acc_pipeline.producer_commit(acc_producer_state)
                acc_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for accumulator buffer empty
            #
            acc_pipeline.producer_tail(acc_producer_state)
        #
        # Specialized epilogue warps
        #
        if warp_idx < self.mma_warp_id:
            #
            # Alloc tensor memory buffer
            #
            tmem.allocate(self.num_tmem_alloc_cols)

            #
            # Bar sync to retrieve tensor memory ptr from shared memory
            #
            tmem.wait_for_alloc()

            #
            # Retrieving tensor memory ptr and make accumulator tensor
            #
            tmem_ptr = tmem.retrieve_ptr(self.acc_dtype)
            log(f"tmem_ptr = {tmem_ptr!s}")
            # (MMA, MMA_M, MMA_N, STAGE)
            tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)
            log(f"tCtAcc_base = {tCtAcc_base!s}")
            #
            # Partition for epilogue
            #
            epi_tidx = tidx
            (
                tiled_copy_t2r,  # (EPI_TILE_M, EPI_TILE_N)
                tTR_tAcc_base,  # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
                tTR_rAcc,  # (T2R, T2R_M, T2R_N)
                tTR_cAcc,  # (T2R, T2R_M, T2R_N), holding (m, n) coordinates
            ) = self.epilogue_tmem_copy_and_partition(epi_tidx, tCtAcc_base, epi_tile)
            log(f"{tiled_copy_t2r = !s}")
            log(f"{tTR_tAcc_base = !s}")
            log(f"{tTR_rAcc = !s}")
            # Copy and partition for the supplemental EFC tensors.
            self.efc.kernel.copy_and_partition_supplemental_rmem_tensors(
                tiled_copy_t2r,
                tTR_rAcc,
                epi_tidx,
                epi_tile,
                tTR_cAcc,
            )

            #
            # Persistent tile scheduling loop
            #
            acc_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_acc_stage
            )

            # Store D pipeline used for all the written tensors in the epilogue.
            d_producer_group = pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                32 * len(self.epilogue_warp_id),
            )
            d_pipeline = pipeline.PipelineTmaStore.create(
                num_stages=self.num_d_stage,
                producer_group=d_producer_group,
            )

            c_pipeline_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.num_c_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # Slice the supplemental written tensors per MMA tile index.
                self.efc.kernel.slice_written_tensors_per_mma_tile_index(
                    mma_tile_coord_mnl
                )

                # Set tensor memory buffer for current tile
                # (T2R, T2R_M, T2R_N, EPI_M, EPI_M)
                tTR_tAcc = tTR_tAcc_base[
                    (None, None, None, None, None, acc_consumer_state.index)
                ]
                log(f"tTR_tAcc = {tTR_tAcc!s}")
                #
                # Wait for accumulator buffer full
                #
                acc_pipeline.consumer_wait(acc_consumer_state)

                # Group together the EPI_M, EPI_M which are starting at group 3.
                # (T2R, T2R_M, T2R_N, (EPI_M, EPI_M))
                tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))
                log(f"group_modes tTR_tAcc = {tTR_tAcc!s}")
                #
                # Store accumulator to global memory in subtiles
                #
                # Use EPI_M*EPI_M to iterate using the 1-D coordinate.
                subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])
                if_debug(
                    lambda: cute.printf("cpasync cons subtile_cnt={}\n", subtile_cnt)
                )
                num_prev_subtiles = tile_sched.num_tiles_executed * subtile_cnt
                # Init the per-CTA SMEM fold buffers (column-style reduce
                # targets) before the subtile loop; the per-subtile folds
                # accumulate into them and ``reduce_smem_flush`` drains
                # them once after the loop.
                self.efc.kernel.reduce_smem_init(epilogue_sync_barrier)
                for subtile_idx in cutlass.range(subtile_cnt):
                    #
                    # Load accumulator from tensor memory buffer to register
                    #
                    tTR_tAcc_mn = tTR_tAcc[(None, None, None, subtile_idx)]
                    cute.copy(tiled_copy_t2r, tTR_tAcc_mn, tTR_rAcc)
                    log(f"cute.copy tiled_copy_t2r = {tiled_copy_t2r!s}")
                    log(f"cute.copy tTR_tAcc_mn = {tTR_tAcc_mn!s}")
                    log(f"cute.copy tTR_rAcc = {tTR_rAcc!s}")

                    # Wait for the staged supplemental loads (TMA and/or
                    # cp.async) on the single load pipeline.
                    if cutlass.const_expr(self.efc.kernel.smem_read):
                        c_pipeline.consumer_wait(c_pipeline_consumer_state)
                        mark_mlir("cpasync cons: waited")

                    # Load supplemental tensors from shared memory to register.
                    self.efc.kernel.load_tensors_from_smem_to_register(
                        c_pipeline_consumer_state.index
                    )

                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    if cutlass.const_expr(self.efc.kernel.smem_read):
                        c_pipeline.consumer_release(c_pipeline_consumer_state)
                        mark_mlir("cpasync cons: released")

                    # Advance pipeline states
                    c_pipeline_consumer_state.advance()

                    #
                    # Perform epilogue op on accumulator.
                    #
                    retile_t2r_fragment = self.efc.kernel.retile_t2r_fragment
                    log(f"retile_t2r_fragment = {retile_t2r_fragment!s}")
                    # Use a SimpleNamespace to pass easily some local content as
                    # an extensible class compatible with CuTe DSL
                    # implementation.
                    epilogue_context = types.SimpleNamespace()
                    # Surface the cross-warp sync barrier so
                    # ``Tensor.reduce`` (called from the user
                    # epilogue body) can use it for the
                    # warpgroup-wide fold step.  Reusing the
                    # already-allocated ``epilogue_sync_barrier``
                    # (128-thread cooperative barrier across the 4
                    # epi warps) avoids spending a second hardware
                    # barrier slot for the reduce path.
                    epilogue_context.reduce_barrier = epilogue_sync_barrier
                    # Load the accumulator cast to the epi_dtype used to do all
                    # the computations in the epilogue.  Retile to the
                    # per-subtile layout the store path expects (R2S when there
                    # is a TMA D, T2R when all D are direct -- see
                    # ``copy_and_partition_supplemental_rmem_tensors`` for the
                    # selection logic).
                    # Surface the retiled register fragment before the
                    # ``.load()`` so ``Configuration.accum_split`` can take a
                    # strided view of it in layout space.
                    epilogue_context.acc_frag = retile_t2r_fragment(tTR_rAcc)
                    epilogue_context.accum_split_across_lanes = (
                        self.efc.kernel.accum_split_across_lanes
                    )
                    epilogue_context.acc_vec = epilogue_context.acc_frag.load().to(
                        self.epi_dtype
                    )
                    # Surface the current subtile coordinates so a
                    # non-scalar ``Tensor.reduce`` can slice its
                    # per-subtile destination partition (the kept-axis
                    # addresses differ per subtile, unlike the scalar
                    # case's single address).
                    epilogue_context.subtile_idx = subtile_idx
                    epilogue_context.mma_tile_coord_mnl = mma_tile_coord_mnl
                    log(f"before retile_t2r_fragment, tTR_rAcc = {tTR_rAcc!s}")
                    log(
                        f"retile_t2r_fragment(tTR_rAcc) = {retile_t2r_fragment(tTR_rAcc)!s}"
                    )
                    log(
                        f"retile_t2r_fragment(tTR_rAcc).load() = {retile_t2r_fragment(tTR_rAcc).load()!s}"
                    )
                    log(f"epilogue_context.acc_vec = {epilogue_context.acc_vec!s}")

                    # For direct-read tensors, fire the per-subtile
                    # GMEM->register copy that fills the register fragment
                    # ``load_setup`` will hand to the body via
                    # ``epilogue_context.load[name]``.
                    self.efc.kernel.load_direct_read_tensors_per_subtile(
                        mma_tile_coord_mnl, subtile_idx
                    )

                    # Execute the EFC epilogue.
                    self.efc.kernel.epilogue_computation(epilogue_context)
                    d_buffer = (num_prev_subtiles + subtile_idx) % self.num_d_stage

                    # For direct-write tensors, drain the register
                    # fragment the body just wrote into to GMEM.  This
                    # runs on every epilogue warp (each thread writes its
                    # own slice), independently of the TMA-store warp gate
                    # below.
                    self.efc.kernel.store_direct_written_tensors_per_subtile(
                        mma_tile_coord_mnl, subtile_idx
                    )

                    # Store the EFC written tensors to shared memory.
                    self.efc.kernel.store_written_tensors_to_smem(d_buffer)

                    # Fence and barrier to make sure shared memory store is visible to TMA store
                    cute.arch.fence_proxy(
                        "async.shared",
                        space="cta",
                    )
                    epilogue_sync_barrier.arrive_and_wait()

                    #
                    # TMA store D to global memory
                    #
                    if warp_idx == self.epilogue_warp_id[0]:
                        # Store with TMA the written EFC tensors to global memory.
                        self.efc.kernel.tma_store_written_tensors_to_gmem(
                            d_buffer, subtile_idx
                        )
                        # Fence and barrier to make sure shared memory store is visible to TMA store
                        d_pipeline.producer_commit()
                        d_pipeline.producer_acquire()

                    epilogue_sync_barrier.arrive_and_wait()

                # Flush the per-CTA SMEM fold buffers (accumulated across
                # all subtiles) to global memory -- one global atomic per
                # kept coordinate -- after the subtile loop and before the
                # persistent scheduler advances, so the next tile's
                # ``reduce_smem_init`` does not race this drain.
                self.efc.kernel.reduce_smem_flush(
                    epilogue_sync_barrier, mma_tile_coord_mnl
                )

                #
                # Async arrive accumulator buffer empty
                #
                with cute.arch.elect_one():
                    acc_pipeline.consumer_release(acc_consumer_state)
                acc_consumer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Dealloc the tensor memory buffer
            #
            tmem.relinquish_alloc_permit()
            epilogue_sync_barrier.arrive_and_wait()
            tmem.free(tmem_ptr)
            #
            # Wait for D store complete
            #
            d_pipeline.producer_tail()

        #
        # Specialized epilogue load warp
        #
        if warp_idx == self.epilogue_load_warp_id:
            # Create the tiled tensors to be loaded in the epilogue.
            self.efc.kernel.create_epilogue_subtile_tensors(tidx, epi_tile)

            c_pipeline_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.num_c_stage
            )

            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_mnl = (
                    cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )
                # Prepare the EFC tensors to be loaded by the subtiles.
                subtile_cnt = self.efc.kernel.prepare_tensor_load_for_subtiles(
                    mma_tile_coord_mnl,
                )
                if_debug(
                    lambda: cute.printf("cpasync prod subtile_cnt={}\n", subtile_cnt)
                )

                # Assume the pipeline can work even in the case there is no
                # tensor to load and so subtile_cnt is 0.
                for subtile_idx in cutlass.range(subtile_cnt):
                    # Acquire an empty stage on the single load pipeline.
                    if cutlass.const_expr(self.efc.kernel.smem_read):
                        c_pipeline.producer_acquire(c_pipeline_producer_state)

                    # Issue the loads.  TMA copies tie their byte completion to
                    # the stage barrier; cp.async copies are fenced per-thread
                    # just below.
                    self.efc.kernel.load_tensor_subtiles(
                        subtile_idx, c_pipeline, c_pipeline_producer_state
                    )
                    mark_mlir("cpasync prod: loaded")

                    # End-of-stage producer arrival on the same barrier.  With
                    # cp.async every load-warp thread fences its own copies via
                    # ``cp_async_mbarrier_arrive_noinc`` (matching the
                    # ``1 + threads`` count); otherwise an elected plain arrive
                    # pairs with ``producer_acquire``'s ``arrive_and_expect_tx``
                    # (TMA hardware completion drives the tx-count side).
                    if cutlass.const_expr(self.efc.kernel.smem_read):
                        if cutlass.const_expr(self.efc.jit.async_load_atom):
                            cute.arch.cp_async_mbarrier_arrive_noinc(
                                c_pipeline.producer_get_barrier(
                                    c_pipeline_producer_state
                                )
                            )
                        else:
                            with cute.arch.elect_one():
                                cute.arch.mbarrier_arrive(
                                    c_pipeline.producer_get_barrier(
                                        c_pipeline_producer_state
                                    )
                                )

                    c_pipeline_producer_state.advance()

                #
                # Advance to next tile
                #
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            #
            # Wait for the load buffer to be empty.
            #
            c_pipeline.producer_tail(c_pipeline_producer_state)

    # The copy/partition helpers live in `_helpers.py` and are
    # bound here as class attributes; Python's descriptor protocol
    # auto-binds them to instances, so call sites continue to use
    # `self.epilogue_X(...)` exactly as before.
    epilogue_tmem_copy_and_partition = _helpers.epilogue_tmem_copy_and_partition
    epilogue_smem_copy_and_partition_load = (
        _helpers.epilogue_smem_copy_and_partition_load
    )
    epilogue_gmem_copy_and_partition = _helpers.epilogue_gmem_copy_and_partition
    epilogue_gmem_copy_and_partition_async = (
        _helpers.epilogue_gmem_copy_and_partition_async
    )
    epilogue_gmem_copy_and_partition_non_tma = (
        _helpers.epilogue_gmem_copy_and_partition_non_tma
    )

    def reduce_fold_extent(self, attributes) -> int:
        """Exact SMEM fold-buffer extent for a kept-axis reduce destination.

        The kernel's buffer view is the ``mma_tiler`` output tile with the
        folded axes zero-strided, so its cosize is exactly the kept axis's
        tile extent -- also under 2-CTA MMA, where the tile is the whole
        (2m, n) instruction tile.  The kept axis is recorded in the remap
        subscript at ``ParameterAnalysis`` time
        (``attributes.reduce_kept_axes``, output-mode indices; batch modes
        do not contribute to the tile).  The planner's SMEM budget
        (``compute_stages``) and the allocator (``allocate_smem``) must
        agree on this size, so both call this single helper.
        """
        kept_tile_axes = [a for a in attributes.reduce_kept_axes if a in (0, 1)]
        assert len(kept_tile_axes) == 1, (
            "kept-axis reduce expects exactly one within-tile kept axis, "
            f"got {attributes.reduce_kept_axes}"
        )
        return self.mma_tiler[kept_tile_axes[0]]

    def compute_stages(self) -> None:
        """Compute and set the number of stages for A/B/C/D operands.

        Uses instance attributes to compute and assign:
        `self.num_acc_stage`, `self.num_ab_stage`, `self.num_c_stage`,
        and `self.num_d_stage`.
        """
        # Defaults
        self.num_acc_stage = 2
        # To read the tensors needed for the epilogue:
        self.num_c_stage = 2
        # To write the tensors produced by the epilogue:
        self.num_d_stage = 2
        self._fit_acc_stages_to_tmem()

        # Calculate smem layout and size for one stage of A, B, C, and D
        a_smem_layout_stage_one = sm100_utils.make_smem_layout_a(
            self._tiled_mma, self.mma_tiler, self.a_dtype, 1
        )
        b_smem_layout_staged_one = sm100_utils.make_smem_layout_b(
            self._tiled_mma, self.mma_tiler, self.b_dtype, 1
        )

        # Get the contribution from the tensors used in the EFC.
        self.efc.jit.compute_stage()

        ab_bytes_per_stage = cute.size_in_bytes(
            self.a_dtype, a_smem_layout_stage_one
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout_staged_one)
        if self.has_scale_factors:
            # SFA/SFB ride the A/B pipeline: one staged buffer each.
            ab_bytes_per_stage += cute.size_in_bytes(
                self.sf_dtype,
                blockscaled_utils.make_smem_layout_sfa(
                    self._tiled_mma, self.mma_tiler, self.sf_vec_size, 1
                ),
            ) + cute.size_in_bytes(
                self.sf_dtype,
                blockscaled_utils.make_smem_layout_sfb(
                    self._tiled_mma, self.mma_tiler, self.sf_vec_size, 1
                ),
            )
        mbar_helpers_bytes = 1024
        # Contribution from the tensors loaded in the EFC.
        c_bytes_per_stage = self.efc.jit.smem_size_in_bytes_of_read_tensors()
        c_bytes = c_bytes_per_stage * self.num_c_stage
        # Contribution from the tensors stored in the EFC. There is at least 1
        # written tensor, so the following is strictly positive.
        d_bytes_per_stage = self.efc.jit.smem_size_in_bytes_of_written_tensors()
        d_bytes = d_bytes_per_stage * self.num_d_stage
        # Fixed SMEM scratch for ``Tensor.reduce`` destinations,
        # allocated once per kernel (not per pipeline stage).
        reduce_bytes = self.efc.jit.smem_size_in_bytes_of_reduce_tensors()

        # Calculate A/B stages
        self.num_ab_stage = (
            self.smem_capacity // self.occupancy
            - (mbar_helpers_bytes + c_bytes + d_bytes + reduce_bytes)
        ) // ab_bytes_per_stage
        log(f"{common_efc.TAB}{self.num_ab_stage = }")

        if self.num_ab_stage <= 0:
            raise MemoryError("Not enough smem capacity to allocate all the tensors.")

        # Refine epilogue stages:
        # Calculate remaining smem after allocating for A/B stages and reserved bytes.
        # Add remaining unused smem to epilogue.
        self.num_d_stage += (
            self.smem_capacity
            - self.occupancy * ab_bytes_per_stage * self.num_ab_stage
            - self.occupancy * (mbar_helpers_bytes + c_bytes + d_bytes + reduce_bytes)
        ) // (self.occupancy * d_bytes_per_stage)
        log(f"{common_efc.TAB}new {self.num_d_stage = }")

    @staticmethod
    def _compute_grid(
        d: cute.Tensor,
        cta_tile_shape_mnk: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        swizzle_size: int,
        raster_along: typing.Literal["m", "n"],
        max_active_clusters: cutlass.Constexpr,
    ) -> tuple[PersistentTileSchedulerParams, tuple[int, int, int]]:
        """Use persistent tile scheduler to compute the grid size for the output tensor D.

        :param d: The output tensor D
        :type d: cute.Tensor
        :param cta_tile_shape_mnk: The shape (M, N, K) of the CTA tile.
        :type cta_tile_shape_mnk: tuple[int, int, int]
        :param cluster_shape_mn: Shape of each cluster in M, N dimensions.
        :type cluster_shape_mn: tuple[int, int]
        :param swizzle_size: Number of clusters per swizzle group, 1 for none.
        :type swizzle_size: int
        :param raster_along: Rasterization order of clusters, "m" or "n".
        :type raster_along: str
        :param max_active_clusters: Maximum number of active clusters.
        :type max_active_clusters: cutlass.Constexpr

        :return: A tuple containing:
            - tile_sched_params: Parameters for the persistent tile scheduler.
            - grid: Grid shape for kernel launch.
        :rtype: tuple[PersistentTileSchedulerParams, tuple[int, int, int]]
        """
        log(f"compute_grid: {max_active_clusters = }")
        d_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gd = cute.zipped_divide(d, tiler=d_shape)
        num_ctas_mnl = gd[(0, (None, None, None))].shape
        common_efc.if_debug(
            lambda: cute.printf("compute_grid: num_ctas_mnl = {}", num_ctas_mnl)
        )
        cluster_shape_mnl = (*cluster_shape_mn, 1)

        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl, cluster_shape_mnl, swizzle_size, raster_along == "m"
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )
        common_efc.if_debug(lambda: cute.printf("compute_grid: grid = {}", grid))
        return tile_sched_params, grid

    def _fit_acc_stages_to_tmem(self) -> None:
        """Clamp ``num_acc_stage`` so the accumulator stages fit the arch's
        TMEM budget next to the scale-factor columns (zero without scale
        factors).  Measured from the accumulator fragment, so a doubled
        (Bkeep-Breuse) tiler counts its 2x columns.  A configuration whose
        two stages exceed the budget runs with one (SM100 block-scaled
        N=256; Rubin Bkeep-Breuse at N=192 and N=256).
        """
        acc_shape = self._tiled_mma.partition_shape_C(self.mma_tiler[:2])
        tCtAcc_one_stage = self._tiled_mma.make_fragment_C(cute.append(acc_shape, 1))
        # TMEM addresses are (row << 16) | col affine values: the low 16
        # bits of the fragment's cosize are its column extent.  Count in
        # 32-bit columns: a 16-bit accumulator's layout is in 16-bit units
        # and would otherwise read as twice its columns.
        acc_cols_per_stage = (
            cute.cosize(
                cute.recast_layout(32, self.acc_dtype.width, tCtAcc_one_stage.layout)
            )
            & 0xFFFF
        )
        sf_cols = self.num_sf_tmem_cols if self.has_scale_factors else 0
        max_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)
        self.num_acc_stage = min(
            self.num_acc_stage, (max_cols - sf_cols) // acc_cols_per_stage
        )
        if self.num_acc_stage < 1:
            raise ValueError(
                f"Accumulator does not fit in TMEM: {acc_cols_per_stage} columns "
                f"per stage + {sf_cols} scale-factor columns > {max_cols}."
            )
        log(
            f"{common_efc.TAB}{self.num_acc_stage = } ({acc_cols_per_stage} acc "
            f"cols/stage, {sf_cols} SF cols, {max_cols} budget)"
        )

    def compute_num_tmem_alloc_cols(self) -> None:
        """Compute and set the number of tensor memory allocation columns.

        This method uses the instance attributes computed during setup to
        determine the number of tensor memory allocation columns and stores
        the result in `self.num_tmem_alloc_cols`.
        """
        acc_shape = self._tiled_mma.partition_shape_C(self.mma_tiler[:2])
        log(f"compute_num_tmem_alloc_cols: {acc_shape = !s}")
        tCtAcc_fake = self._tiled_mma.make_fragment_C(
            cute.append(acc_shape, self.num_acc_stage)
        )
        log(f"compute_num_tmem_alloc_cols: {tCtAcc_fake = !s}")
        # Size against this operation's arch: the helper's default budget is
        # sm_100's 512 columns, but compute_stages fits the accumulator
        # stages against this arch's budget (sm107: 576), and the two must
        # agree.
        self.num_tmem_alloc_cols = cutlass.memory.get_num_tmem_alloc_cols(
            tCtAcc_fake, arch=self.arch
        )
        if self.has_scale_factors:
            # SFA/SFB TMEM sits right after the accumulator stages.  TMEM
            # addresses are (row << 16) | col affine values, so masking the
            # fragment layout's cosize to the low 16 bits yields the column
            # extent (also under Bkeep-Breuse doubled tiles).
            assert self.acc_dtype.width == 32, (
                "the SF TMEM carve assumes 32-bit accumulator columns"
            )
            self.num_accumulator_tmem_cols = cute.cosize(tCtAcc_fake.layout) & 0xFFFF
            max_cols = cute.arch.get_max_tmem_alloc_cols(self.arch)
            total_cols = self.num_accumulator_tmem_cols + self.num_sf_tmem_cols
            if total_cols > max_cols:
                raise ValueError(
                    f"Accumulator + scale-factor TMEM does not fit: "
                    f"{self.num_accumulator_tmem_cols} + {self.num_sf_tmem_cols} "
                    f"> {max_cols} columns."
                )
            # Allocate the full TMEM budget, as the reference blockscaled
            # kernel does.
            self.num_tmem_alloc_cols = max_cols
        log(f"compute_num_tmem_alloc_cols: {self.num_tmem_alloc_cols = }")

    def check_valid_dtypes(
        self,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
    ):
        """
        Check if the dtypes are valid

        :param a_dtype: The data type of the A operand
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: type[cutlass.Numeric]

        :raises ValueError: If the dtypes are invalid or incompatible
        """
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.TFloat32,
            cutlass.Uint8,
            cutlass.Int8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        for operand_name, operand_dtype in (("A", a_dtype), ("B", b_dtype)):
            if operand_dtype not in valid_ab_dtypes:
                raise ValueError(
                    f"Invalid {operand_name} dtype: {operand_dtype}. "
                    f"Supported dtypes: {', '.join(str(dt) for dt in valid_ab_dtypes)}"
                )
        if a_dtype != b_dtype and not (
            a_dtype in _FP8_DTYPES and b_dtype in _FP8_DTYPES
        ):
            raise ValueError(
                f"A/B dtypes must match (only fp8 pairs may mix): "
                f"{a_dtype} != {b_dtype}"
            )

        valid_acc_dtypes = {cutlass.Float32, cutlass.Float16, cutlass.Int32}
        if self.acc_dtype not in valid_acc_dtypes:
            raise ValueError(
                f"Invalid accumulator dtype: {self.acc_dtype}. "
                f"Supported dtypes: {', '.join(str(dt) for dt in valid_acc_dtypes)}"
            )

        # Define compatibility mapping between accumulator type and AB type
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.TFloat32,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },  # Float32 accumulator supports floating point AB types only
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {cutlass.Uint8, cutlass.Int8},
        }
        # Check compatibility between accumulator type and AB types
        for operand_dtype in (a_dtype, b_dtype):
            if operand_dtype not in acc_ab_compatibility[self.acc_dtype]:
                compatible_types = acc_ab_compatibility[self.acc_dtype]
                raise ValueError(
                    f"Incompatible dtype combination: A/B dtype {operand_dtype} "
                    f"is not compatible with accumulator dtype {self.acc_dtype}. "
                    f"Compatible A/B dtypes for {self.acc_dtype}: "
                    f"{', '.join(str(dt) for dt in compatible_types)}"
                )

    def check_valid_mma_tiler_and_cluster_shape(
        self, a_dtype, b_dtype, *, mma_tiler_mn=None
    ):
        """Check if the mma tiler and cluster shape are valid.

        :param a_dtype: A's dtype; arch subclasses whose tiler menu is
            dtype-dependent use it
        :param b_dtype: B's dtype
        :param mma_tiler_mn: The (M, N) tiler to validate; defaults to
            ``self.mma_tiler_mn``.  Arch subclasses pass a derived tiler
            (e.g. the per-instruction M of a doubled tile) so the check
            stays free of instance-state side effects.
        :raises ValueError: If the mma tiler or cluster shape is invalid
        """
        if mma_tiler_mn is None:
            mma_tiler_mn = self.mma_tiler_mn
        # Check invalid mma tile shape M dimension
        if not (
            (not self.use_2cta_instrs and mma_tiler_mn[0] in [64, 128])
            or (self.use_2cta_instrs and mma_tiler_mn[0] in [128, 256])
        ):
            expected = [128, 256] if self.use_2cta_instrs else [64, 128]
            raise ValueError(
                f"Invalid MMA tile M dimension: {mma_tiler_mn[0]}. "
                f"Expected one of {expected} (use_2cta_instrs={self.use_2cta_instrs})"
            )

        # Check invalid mma tile shape N dimension
        if mma_tiler_mn[1] not in range(32, 257, 32):
            raise ValueError(
                f"Invalid MMA tile N dimension: {mma_tiler_mn[1]}. "
                f"Expected a multiple of 32 in range [32, 256]"
            )
        # Check illegal cluster shape M dimension
        if self.cluster_shape_mn[0] % (2 if self.use_2cta_instrs else 1) != 0:
            divisor = 2 if self.use_2cta_instrs else 1
            raise ValueError(
                f"Invalid cluster shape M dimension: {self.cluster_shape_mn[0]}. "
                f"Must be divisible by {divisor} (use_2cta_instrs={self.use_2cta_instrs})"
            )

        def is_power_of_2(x):
            return x > 0 and (x & (x - 1)) == 0

        # Check invalid cluster shape constraints
        if self.cluster_shape_mn[0] * self.cluster_shape_mn[1] > 16:
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Product {self.cluster_shape_mn[0]} * {self.cluster_shape_mn[1]} = "
                f"{self.cluster_shape_mn[0] * self.cluster_shape_mn[1]} exceeds maximum of 16"
            )
        if self.cluster_shape_mn[0] <= 0 or self.cluster_shape_mn[1] <= 0:
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Both dimensions must be positive"
            )
        if not is_power_of_2(self.cluster_shape_mn[0]) or not is_power_of_2(
            self.cluster_shape_mn[1]
        ):
            raise ValueError(
                f"Invalid cluster shape: {self.cluster_shape_mn}. "
                f"Both dimensions must be powers of 2"
            )

    def check_valid_tensor_alignment(
        self,
        m: int,
        n: int,
        k: int,
        l: int,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        d_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        cd_major: str,
    ):
        """
        Check if the tensor alignment is valid

        :param m: The number of rows in the A tensor
        :type m: int
        :param n: The number of columns in the B tensor
        :type n: int
        :param k: The number of columns in the A tensor
        :type k: int
        :param l: The number of columns in the C tensor
        :type l: int
        :param a_dtype: The data type of the A operand
        :type a_dtype: type[cutlass.Numeric]
        :param b_dtype: The data type of the B operand
        :type b_dtype: type[cutlass.Numeric]
        :param d_dtype: The data type of the D tensor
        :type d_dtype: type[cutlass.Numeric]
        :param a_major: The major axis of the A tensor
        :type a_major: str
        :param b_major: The major axis of the B tensor
        :type b_major: str
        :param cd_major: The major axis of the C/D tensor
        :type cd_major: str

        :raises ValueError: If the tensor alignment is invalid
        """

        def check_contiguous_16B_alignment(
            dtype, is_mode0_major, tensor_shape, tensor_name
        ):
            major_mode_idx = 0 if is_mode0_major else 1
            num_major_elements = tensor_shape[major_mode_idx]
            num_contiguous_elements = 16 * 8 // dtype.width
            if num_major_elements % num_contiguous_elements != 0:
                raise ValueError(
                    f"Invalid alignment for tensor {tensor_name}. "
                    f"Major dimension has {num_major_elements} elements, "
                    f"but requires alignment to {num_contiguous_elements} elements (16 bytes). "
                    f"Dtype: {dtype}, width: {dtype.width} bits"
                )

        check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k, l), "A")
        check_contiguous_16B_alignment(b_dtype, b_major == "n", (n, k, l), "B")
        check_contiguous_16B_alignment(d_dtype, cd_major == "m", (m, n, l), "D")

    def check_implementable(self, a: cute.Tensor, b: cute.Tensor, d: cute.Tensor):
        """Check if the given tensors can be implemented by this kernel.

        :param a: Input tensor A
        :type a: cute.Tensor
        :param b: Input tensor B
        :type b: cute.Tensor
        :param d: One of the tensor used as some output
        :type d: cute.Tensor

        :raises CantImplementError: If the configuration is not implementable
        """
        m, n, k, l = a.shape[0], b.shape[0], a.shape[1], a.shape[2]

        # infer a_major, b_major, cd_major
        is_m_major_a = cutlass.tensor_utils.LayoutEnum.from_tensor(a).is_m_major_a()
        is_n_major_b = cutlass.tensor_utils.LayoutEnum.from_tensor(b).is_n_major_b()
        is_m_major_d = cutlass.tensor_utils.LayoutEnum.from_tensor(d).is_m_major_c()
        a_major = "m" if is_m_major_a else "k"
        b_major = "n" if is_n_major_b else "k"
        cd_major = "m" if is_m_major_d else "n"

        try:
            sm100_utils.check_int8_mma_arch(a.element_type)
            sm100_utils.check_int8_mma_arch(b.element_type)

            # Check dtypes (raises ValueError if invalid; A/B must match
            # except that the two fp8 formats may mix)
            self.check_valid_dtypes(a.element_type, b.element_type)

            # Check mma tile shape and cluster shape (raises ValueError if invalid)
            self.check_valid_mma_tiler_and_cluster_shape(a.element_type, b.element_type)

            # Check problem shape for load/store alignment (raises ValueError if invalid)
            self.check_valid_tensor_alignment(
                m,
                n,
                k,
                l,
                a.element_type,
                b.element_type,
                d.element_type,
                a_major,
                b_major,
                cd_major,
            )
        except (ValueError, cutlass.testing.CantImplementError) as e:
            raise cutlass.testing.CantImplementError(f"Configuration error: {e}")

    class CLIParser:
        """Parse command-line arguments for the Blackwell Dense GEMM example."""

        def __init__(self):
            # Load argparse only if the CLIParser is used.
            import argparse

            self.parser = argparse.ArgumentParser(
                description="Example of Dense Persistent GEMM on Blackwell."
            )
            self.parser.add_argument(
                "--mnkl",
                type=self.parse_comma_separated_ints,
                default=(256, 256, 512, 1),
                help="mnkl dimensions (comma-separated)",
            )
            self.parser.add_argument(
                "--mma_tiler_mn",
                type=self.parse_comma_separated_ints,
                default=(128, 128),
                help="MMA tile shape (comma-separated)",
            )
            self.parser.add_argument(
                "--cluster_shape_mn",
                type=self.parse_comma_separated_ints,
                default=(1, 1),
                help="Cluster shape (comma-separated)",
            )
            self.parser.add_argument(
                "--ab_dtype", type=cutlass.dtype, default=cutlass.TFloat32
            )
            self.parser.add_argument(
                "--acc_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--epi_dtype", type=cutlass.dtype, default=cutlass.Float32
            )
            self.parser.add_argument(
                "--use_2cta_instrs",
                action="store_true",
                help="Enable 2CTA MMA instructions feature",
            )
            self.parser.add_argument(
                "--a_major", choices=["k", "m"], type=str, default="k"
            )
            self.parser.add_argument(
                "--b_major", choices=["k", "n"], type=str, default="k"
            )
            self.parser.add_argument(
                "--cd_major", choices=["n", "m"], type=str, default="n"
            )
            self.parser.add_argument(
                "--tolerance",
                type=float,
                default=1e-01,
                help="Tolerance for validation",
            )
            self.parser.add_argument(
                "--warmup_iterations", type=int, default=0, help="Warmup iterations"
            )
            self.parser.add_argument(
                "--iterations",
                type=int,
                default=1,
                help="Number of iterations to run the kernel",
            )
            self.parser.add_argument(
                "--skip_ref_check", action="store_true", help="Skip reference checking"
            )
            self.parser.add_argument(
                "--use_cold_l2",
                action="store_true",
                default=False,
                help="Use circular buffer tensor sets to ensure L2 cold cache",
            )
            self.parser.add_argument(
                "--swizzle_size",
                type=int,
                default=1,
                help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
            )
            self.parser.add_argument(
                "--raster_order",
                type=str,
                choices=["m", "n"],
                default="m",
                help="Rasterization order of clusters",
            )

            # A child class may add more things to parse.
            self.more_parsing()

        def parse(self):
            """Parse the command-line arguments."""
            args = self.parser.parse_args()

            if len(args.mnkl) != 4:
                self.parser.error("--mnkl must contain exactly 4 values")

            if len(args.mma_tiler_mn) != 2:
                self.parser.error("--mma_tiler_mn must contain exactly 2 values")

            if len(args.cluster_shape_mn) != 2:
                self.parser.error("--cluster_shape_mn must contain exactly 2 values")

            return args

        @staticmethod
        def parse_comma_separated_ints(s: str) -> tuple[int, ...]:
            try:
                return tuple(int(x.strip()) for x in s.split(","))
            except ValueError as err:
                import argparse

                raise argparse.ArgumentTypeError(
                    "Invalid format. Expected comma-separated integers."
                ) from err

        def more_parsing(self):
            """Override to add more arguments to self.parser."""

    @staticmethod
    def dtype_name(dtype: type[cutlass.Numeric]) -> str:
        """Convert a CUTLASS dtype object to its clean string name.

        This is needed to format dtype objects into CLI arguments without
        full module paths. CUTLASS dtype objects have different representations:
        some have a __name__ attribute while others need string parsing.

        We want "Float16" not "cutlass.Float16" or "<class 'cutlass.Float16'>".

        :param dtype: CUTLASS numeric data type
        :return: Clean type name string (e.g., "Float16", "BFloat16")

        Example:
            >>> DenseGemmEFC.dtype_name(cutlass.Float16)
            'Float16'
        """
        return (
            dtype.__name__ if hasattr(dtype, "__name__") else str(dtype).split(".")[-1]
        )

    @staticmethod
    def format_as_cli_args(
        script_name: str,
        mnkl: tuple[int, int, int, int],
        ab_dtype: type[cutlass.Numeric],
        acc_dtype: type[cutlass.Numeric],
        epi_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        cd_major: str,
        mma_tiler_mn: tuple[int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
        tolerance: float,
        warmup_iterations: int = 0,
        iterations: int = 1,
        skip_ref_check: bool = False,
        use_cold_l2: bool = False,
        swizzle_size: int = 1,
        raster_along: str = "m",
    ) -> str:
        """Format common test parameters as CLI arguments base.

        This method formats the common parameters shared across different GEMM examples.
        Subclass-specific parameters (like alpha, beta, etc.) should be added by overriding methods.

        :param script_name: Name of the Python script
        :param mnkl: Matrix dimensions (M, N, K, L)
        :param ab_dtype: Data type for A and B matrices
        :param acc_dtype: Data type for accumulation
        :param epi_dtype: Data type for epilogue
        :param a_major: Major order for matrix A
        :param b_major: Major order for matrix B
        :param cd_major: Major order for matrices C and D
        :param mma_tiler_mn: MMA tiler dimensions (M, N)
        :param cluster_shape_mn: Cluster shape (M, N)
        :param use_2cta_instrs: Whether to use 2CTA instructions
        :param tolerance: Tolerance for validation
        :param warmup_iterations: Number of warmup iterations
        :param iterations: Number of benchmark iterations
        :param skip_ref_check: Whether to skip reference checking
        :param use_cold_l2: Use circular buffer tensor sets to ensure L2 cold cache
        :param swizzle_size: Number of clusters per swizzle group, 1 for none
        :param raster_along: Rasterization order of clusters, "m" or "n"
        :return: Formatted CLI command string
        """
        # Format tuples as comma-separated values
        mnkl_str = ",".join(map(str, mnkl))
        mma_tiler_str = ",".join(map(str, mma_tiler_mn))
        cluster_shape_str = ",".join(map(str, cluster_shape_mn))

        cmd = (
            f"python {script_name} "
            f"--mnkl {mnkl_str} "
            f"--ab_dtype {DenseGemmEFC.dtype_name(ab_dtype)} "
            f"--acc_dtype {DenseGemmEFC.dtype_name(acc_dtype)} "
            f"--epi_dtype {DenseGemmEFC.dtype_name(epi_dtype)} "
            f"--a_major {a_major} "
            f"--b_major {b_major} "
            f"--cd_major {cd_major} "
            f"--mma_tiler_mn {mma_tiler_str} "
            f"--cluster_shape_mn {cluster_shape_str} "
            f"{'--use_2cta_instrs ' if use_2cta_instrs else ''}"
            f"--tolerance {tolerance} "
            f"--warmup_iterations {warmup_iterations} "
            f"--iterations {iterations}"
            f"{' --skip_ref_check' if skip_ref_check else ''}"
            f"{' --use_cold_l2' if use_cold_l2 else ''}"
            f"{f' --swizzle_size {swizzle_size}' if swizzle_size != 1 else ''}"
            f"{f' --raster_order {raster_along}' if raster_along != 'm' else ''}"
        )
        return cmd

    def create_arguments(
        self, l, m, n, k, a_major, b_major, cd_major, ab_dtype, b_dtype=None
    ):
        """Create base GEMM input tensors A and B.

        This method creates the input matrices for GEMM computation. Subclasses
        typically override this method to create additional supplemental tensors
        for the epilogue.

        :param l: Batch dimension
        :param m: M dimension (rows of A and output)
        :param n: N dimension (columns of B and output)
        :param k: K dimension (inner dimension)
        :param a_major: Major order for A matrix ('m' or 'k')
        :param b_major: Major order for B matrix ('n' or 'k')
        :param cd_major: Major order for supplemental tensors ('m' or 'n')
        :param ab_dtype: Data type for A and B matrices
        :param b_dtype: Data type for B, when it differs from A (fp8 pairs
            may mix); defaults to ``ab_dtype``
        :return: tuple of (a_tensor, b_tensor, a_torch_cpu, b_torch_cpu)
        """
        # Only load PyTorch support if it is used.
        import torch
        import cutlass.torch as cutlass_torch

        if b_dtype is None:
            b_dtype = ab_dtype
        torch.manual_seed(1111)

        a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
        b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", b_dtype)

        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, b_dtype, is_dynamic_layout=True, assumed_align=16
        )

        return (
            a_tensor,
            b_tensor,
            a_torch_cpu,
            b_torch_cpu,
        )

    def evaluate_on_cpu(self, a_torch_cpu, b_torch_cpu, epi_dtype, *epilogue_args):
        """Evaluate the GEMM and epilogue computation on CPU for validation.

        Computes the reference result by performing A*B using einsum, then
        evaluates the epilogue function with the accumulator and supplemental
        arguments. This updates any output tensors in epilogue_args.

        :param a_torch_cpu: Input matrix A on CPU
        :param b_torch_cpu: Input matrix B on CPU
        :param epi_dtype: Data type for epilogue computation
        :param epilogue_args: Supplemental arguments for the epilogue (tensors and scalars)
        """
        # Only load PyTorch support if it is used.
        import torch

        # Compute reference result
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch_cpu.to(dtype=torch.float32),
            b_torch_cpu.to(dtype=torch.float32),
        )

        self.efc.evaluate_on_cpu(ref, epilogue_args)

    def compile(
        self,
        a_tensor,
        b_tensor,
        max_active_clusters,
        current_stream,
        *supplemental_arguments,
        **compiler_options,
    ):
        """Compile the GEMM kernel with epilogue fusion.

        Compiles the kernel using CUTE DSL compilation, incorporating the EFC
        (Epilogue Fusion Configuration) with all supplemental arguments. Returns
        a compiled callable that accepts (a, b, stream, *supplemental_arguments)
        directly.

        :param a_tensor: Input tensor A.
        :param b_tensor: Input tensor B.
        :param max_active_clusters: Maximum number of active clusters.
        :param current_stream: CUDA stream for execution.
        :param supplemental_arguments: Additional arguments for the epilogue (tensors and scalars).
        :param compiler_options: Keyword arguments passed to the CuTe DSL compiler. Only "options" is supported for now.
        :return: Compiled callable function that executes the GEMM with the same signature.
        """
        self.efc.compile(*supplemental_arguments)
        compiled = cutlass.cute.compile(
            self,
            a_tensor,
            b_tensor,
            max_active_clusters,
            current_stream,
            *supplemental_arguments,
            **compiler_options,
        )
        return compiled
