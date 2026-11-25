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

"""Shared base of the Operator-API EFC GEMM operators.

``_PersistentDenseGemmEFCOperatorBase`` is the discovery / compile / run
plumbing every EFC GEMM operator shares: enumerating kernel configurations,
the design legality checks, converting the traced epilogue into an EFC
epilogue function via ``EFCConverter``, and packing/unpacking arguments
around ``cute_compile`` / ``cute_run``.  Concrete operators add the operand
rules of their mainloop: ``Sm100PersistentDenseGemmEFCOperator``
(``sm100_static_persistent_efc``) for dense operands, the block-scaled
operator for ``ScaledOperand`` A/B, and the Rubin subclasses for the K=64
fp8 instruction.

The actual GPU kernels are thin batch-layout adapters over the example
operations (``PersistentDenseGemmEFCKernel`` over ``DenseGemmEFC``); the
wrappers never touch GPU details, and the kernels never touch user-facing
types such as ``GemmArguments`` or ``TensorWrapper``.
"""

from __future__ import annotations

import itertools
from abc import abstractmethod
from typing import TYPE_CHECKING

import cutlass
from cutlass.cutlass_dsl import Int32

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    EpilogueArguments,
    GemmArguments,
    Operand,
)
from cutlass.operators.metadata import (
    EpilogueMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl.evt.converter import EFCConverter
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    TensorWrapper,
    strides_to_layout_string,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )

_MAX_CLUSTER_SIZE = 16


class _PersistentDenseGemmEFCOperatorBase(CuteDslOperator):
    """Shared plumbing of the EFC GEMM operators.

    Subclasses supply the mainloop's operand rules (``_valid_operands``,
    ``_metadata_operands_from_args``, ``_metadata_operand_combinations``,
    ``_operand_name_fragment``, ``_mainloop_tensors``), the arch's design
    rules (``_design_metadata_type``, ``_mma_instruction_type``,
    ``_valid_tile_shape``, ``_tile_m_candidates``, ``_mma_tiler_mn``,
    ``_design_suffix``) and the shim kernel (``_shim_kernel_type``); the
    tile-N menu (``_tile_n_menu``, legality) and the enumerated tile-N
    candidates (``_tile_n_candidates``) are mainloop rules too.  Abstract;
    concrete operators define ``supported_args_type`` and
    ``designed_for_min_cc``.
    """

    # Output dtypes offered per accumulator dtype (narrowing outputs pair
    # with the EFC epilogue's rounding).  Operand-agnostic: it describes
    # what the EFC epilogue can write.
    _valid_acc_out_combinations = {
        cutlass.Float32: (
            cutlass.Float32,
            cutlass.Int32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ),
        cutlass.Int32: (
            cutlass.Float32,
            cutlass.Int32,
            cutlass.Int8,
            cutlass.Uint8,
        ),
        cutlass.Float16: (cutlass.Float16, cutlass.BFloat16),
    }

    # Arch legality data consumed by the shared ``_valid_design``; arch
    # subclasses override.
    _design_metadata_type = Sm100DesignMetadata
    _mma_instruction_type = BlackwellTcgen05Mma
    # The batch-first shim kernel class this operator instantiates.
    _shim_kernel_type: type
    # Stem that follows ``cutedsl.`` in ``operator_name``.  ``None`` uses the class name.
    _operator_name_stem: str | None = None

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        if metadata.epilogue is not None:
            epilogue_op = EFCConverter.convert(
                metadata.epilogue.traced_epilogue.dag_ir,
                metadata.epilogue.parameter_names,
                parameter_tensors=metadata.epilogue.tensors,
                transports=metadata.epilogue.transports,
            )
        else:
            epilogue_op = EFCConverter.identity_efc

        self.impl = self._make_impl(metadata, epilogue_op)

    @classmethod
    def _mma_tiler_mn(cls, design) -> tuple[int, int]:
        """The operation's full MMA tiler for ``design`` (arch hook: sm100
        designs carry the full tiler, Rubin designs the per-CTA tile)."""
        return (design.tile_shape[0], design.tile_shape[1])

    def _make_impl(self, metadata: OperatorMetadata, epilogue_op):
        """Construct the shim kernel for ``metadata``."""
        return self._shim_kernel_type(
            metadata.operands.accumulator_type,
            metadata.operands.out.dtype,
            metadata.design.use_2cta_mma,
            self._mma_tiler_mn(metadata.design),
            (metadata.design.cluster_shape[0], metadata.design.cluster_shape[1]),
            epilogue_op,
        )

    @staticmethod
    def _valid_fusion(fusion: EpilogueMetadata) -> Status:
        if not isinstance(fusion, EpilogueMetadata):
            return Status.fail("Unsupported epilogue argument type.")
        if not (
            status := EFCConverter.supports(
                fusion.traced_epilogue.dag_ir, fusion.tensors
            )
        ):
            return status
        return Status.success()

    @classmethod
    @abstractmethod
    def _valid_operands(cls, operands: GemmOperandsMetadata) -> bool:
        """Mainloop hook: whether ``operands`` are supported."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _valid_tile_shape(cls, design) -> bool:
        """Arch hook for the tile-M law.

        Tile-shape conventions differ per arch (sm100 designs carry the
        full MMA tiler M, i.e. the instruction M; subclass designs may
        carry per-CTA tiles), so the law cannot be shared, only the
        surrounding checks.
        """
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _tile_n_menu(cls) -> tuple[int, ...]:
        """Mainloop hook: the legal tile-N values."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _tile_m_candidates(cls, use_2cta_mma: bool) -> tuple[int, ...]:
        """Arch/mainloop hook: the tile-M values legal under the given CTA
        mode, so ``_design_space`` never enumerates a design the tile-M law
        rejects."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _tile_n_candidates(cls) -> tuple[int, ...]:
        """Mainloop hook: tile-N values ``_design_space`` enumerates (a subset
        of the ``_tile_n_menu`` legality menu)."""
        raise NotImplementedError

    @classmethod
    def _valid_design(cls, design) -> bool:
        """Check whether one kernel design is *legal* for the EFC kernel.

        Legality only: perf ranking between legal designs is the
        heuristics layer's job, not the operator's.  The checks common to
        every arch live here; the arch-specific tile-M law is the
        ``_valid_tile_shape`` hook and the tile-N menu is ``_tile_n_menu``.
        """
        if type(design) is not cls._design_metadata_type:
            return False
        if design.mma_instruction_type is not cls._mma_instruction_type:
            return False
        if not design.use_tma_store:
            return False
        if design.tile_scheduler is not None:
            return False
        if design.fallback_cluster_shape is not None:
            return False
        if not cls._valid_tile_shape(design):
            return False
        if design.tile_shape[1] not in cls._tile_n_menu():
            return False

        def is_power_of_2(x):
            return x > 0 and (x & (x - 1)) == 0

        cluster_m, cluster_n, cluster_l = design.cluster_shape
        mma_ctas = 2 if design.use_2cta_mma else 1
        return (
            cluster_l == 1
            and cluster_m % mma_ctas == 0
            and cluster_m * cluster_n <= _MAX_CLUSTER_SIZE
            and is_power_of_2(cluster_m)
            and is_power_of_2(cluster_n)
        )

    @classmethod
    def _tile_shape_k(cls, operands: GemmOperandsMetadata) -> int:
        """Mainloop tile K for ``operands``: one 128-byte swizzle period
        of K per AB pipeline stage, however many MMA instructions of the
        arch's K that spans.
        """
        return 128 * 8 // operands.A.dtype.width

    @classmethod
    def _valid_metadata(cls, metadata: OperatorMetadata) -> bool:
        if not cls._valid_operands(metadata.operands):
            return False

        if not cls._valid_design(metadata.design):
            return False

        return metadata.design.tile_shape[2] == cls._tile_shape_k(metadata.operands)

    @classmethod
    @abstractmethod
    def _metadata_operands_from_args(
        cls,
        args: GemmArguments,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Mainloop hook: the GemmOperandsMetadata that correspond to
        ``args`` and that this operator supports."""
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _metadata_operand_combinations(
        cls,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Mainloop hook: every GemmOperandsMetadata this operator supports."""
        raise NotImplementedError

    @classmethod
    def _mainloop_tensors(cls, args: GemmArguments) -> tuple:
        """Mainloop hook: the kernel arguments that follow A and B (e.g. the
        scale-factor tensors of a block-scaled mainloop); none for dense."""
        return ()

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        if args.epilogue is not None:
            fusion_metadata = EpilogueMetadata.from_args(args.epilogue)
            if not self._valid_fusion(fusion_metadata):
                return Status.fail(
                    "Provided epilogue fusion is not supported by this Operator"
                )

        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()

        if args.epilogue is not None:
            epilogue_params = [
                e.compile_time_tensor if isinstance(e, TensorWrapper) else e
                for e in args.epilogue.parameters
            ]
        else:
            epilogue_params = [args.out.tensor.compile_time_tensor]

        self.impl.efc.compile(*epilogue_params)
        compiled_artifact = self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            *self._mainloop_tensors(args),
            Int32(0),
            stream,
            *epilogue_params,
            target_sm=target_sm,
        )

        return compiled_artifact

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        stream = to_cuda_stream(stream)

        epilogue_params = (
            args.epilogue.parameters if args.epilogue is not None else [args.out]
        )

        epilogue_params = [
            e.tensor if isinstance(e, Operand) else e for e in epilogue_params
        ]

        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(
            compiled_gemm,
            args.A.tensor,
            args.B.tensor,
            *self._mainloop_tensors(args),
            device_properties.max_active_clusters(self.impl.cluster_shape_mn),
            stream,
            *epilogue_params,
        )

    @staticmethod
    def _efc_cluster_shapes() -> tuple[tuple[int, int, int], ...]:
        """Cluster shapes within the EFC kernel's cap (see ``_valid_design``)."""
        return tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m, cluster_n in itertools.product((1, 2, 4, 8, 16), repeat=2)
            if cluster_m * cluster_n <= _MAX_CLUSTER_SIZE
        )

    @classmethod
    def _design_space(
        cls, operands: GemmOperandsMetadata
    ) -> Generator[Sm100DesignMetadata, None, None]:
        """Yield the candidate designs for ``operands`` (arch hook).

        Enumerates only designs ``_valid_design`` accepts: tile M comes
        from the CTA mode's own menu and the cluster M must hold whole MMA
        CTA pairs, so no metadata is built just to be rejected.
        """
        tile_k = cls._tile_shape_k(operands)
        for use_2cta_mma in (True, False):
            mma_ctas = 2 if use_2cta_mma else 1
            for tile_m, tile_n, cluster_shape in itertools.product(
                cls._tile_m_candidates(use_2cta_mma),
                cls._tile_n_candidates(),
                cls._efc_cluster_shapes(),
            ):
                if cluster_shape[0] % mma_ctas != 0:
                    continue
                yield Sm100DesignMetadata(
                    mma_instruction_type=cls._mma_instruction_type,
                    use_2cta_mma=use_2cta_mma,
                    tile_shape=(tile_m, tile_n, tile_k),
                    cluster_shape=cluster_shape,
                    use_tma_store=True,
                )

    @classmethod
    def _design_suffix(cls, design) -> str:
        """Design-dependent tail of the operator name (arch hook)."""
        return "_tma_store" if design.use_tma_store else ""

    @classmethod
    def _operand_name_fragment(cls, operands: GemmOperandsMetadata) -> str:
        """Operand-dependent middle of the operator name (mainloop hook)."""
        return f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}_acc{operands.accumulator_type}"

    @classmethod
    def _operator_name(cls, operands: GemmOperandsMetadata, design) -> str:
        """Build a unique descriptive name for one operator configuration."""
        return (
            "cutedsl.{name}_sm{cc}"
            "_{layout}"
            "{operands}"
            "_{num_cta}cta"
            "_cluster{cluster}"
            "_tile{tile}"
            "{suffix}"
        ).format(
            name=cls._operator_name_stem or cls.__name__,
            cc=cls.designed_for_min_cc,
            layout=strides_to_layout_string(
                operands.A.stride, operands.B.stride, operands.out.stride
            ),
            operands=cls._operand_name_fragment(operands),
            num_cta=("2" if design.use_2cta_mma else "1"),
            cluster=tuple_to_string(design.cluster_shape),
            tile=tuple_to_string(design.tile_shape),
            suffix=cls._design_suffix(design),
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[_PersistentDenseGemmEFCOperatorBase]:
        """Returns a list of all possible configurations of ``cls`` that
        adhere to constraints passed in under kwargs.
        """
        if epilogue_args is not None:
            if not isinstance(epilogue_args, EpilogueArguments):
                return []

            epilogue_metadata = EpilogueMetadata.from_args(epilogue_args)
            if not cls._valid_fusion(epilogue_metadata):
                return []
        else:
            epilogue_metadata = None

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operands_generator = cls._metadata_operand_combinations()

        operator_list = []
        for operands in operands_generator:
            if not cls._valid_operands(operands):
                continue

            for design in cls._design_space(operands):
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=cls._operator_name(operands, design),
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=epilogue_metadata,
                )

                if cls._valid_metadata(metadata) and metadata_filter(metadata):
                    operator_list.append(cls(metadata))

        return operator_list
