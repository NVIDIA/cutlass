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

from __future__ import annotations

from typing import TYPE_CHECKING, Union

import cuda.bindings.driver as cuda
import cuda.bindings.runtime as cuda_runtime

import cutlass
import cutlass.cute as cute

import cutlass.operators.utils.generate as generate
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
    GemmPerformanceControls,
    PerformanceControls,
    ProgrammaticDependentLaunchControl,
)
from cutlass.operators.metadata import (
    EarlyStartMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    ProgrammaticDependentLaunchMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.sm100_tgv_gemm_impl import TgvGemmKernel

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


@cute.jit
def _tgv_bmm(
    gemm_op: cutlass.Constexpr,
    a_api: cute.Tensor,
    b_api: cute.Tensor,
    c_api: cute.Tensor,
    stream: cuda.CUstream,
    pdl_count: cutlass.Int32,
    pdl_stream_serialization: cutlass.Constexpr[bool] = False,
    programmatic_event: Union[cuda_runtime.cudaEvent_t, cuda.CUevent, None] = None,  # noqa: UP007
    programmatic_event_flags: cutlass.Constexpr[int] = 0,
    programmatic_event_trigger_at_block_start: cutlass.Constexpr[bool] = False,
):
    """Swap API operands to TGV convention and reorder batch-first to batch-last.

    cutlass.operators convention: C = A @ B
        A = activation (L, M, K) row-major (K-contiguous)
        B = weight     (L, K, N) col-major (K-contiguous)
        C = output     (L, M, N) row-major (N-contiguous)

    TGV convention: C = A * B  (where A=weight, B=activation)
        a = weight     (M_tgv, K, L) K-contiguous   [M_tgv = N_api]
        b = activation (N_tgv, K, L) K-contiguous   [N_tgv = M_api]
        c = output     (M_tgv, N_tgv, L) M_tgv-contiguous

    The mapping:
        B_api (L,K,N) -> select([2,1,0]) -> (N,K,L) = TGV a
        A_api (L,M,K) -> select([1,2,0]) -> (M,K,L) = TGV b
        C_api (L,M,N) -> select([2,1,0]) -> (N,M,L) = TGV c
    """

    # Promote rank-2 tensors to rank-3 by prepending batch dim of 1.
    # Same pattern as PersistentDenseGemmKernel.__call__.
    def add_batch_mode(tensor: cute.Tensor) -> cute.Tensor:
        return cute.make_tensor(
            tensor.iterator,
            cute.prepend(tensor.layout, cute.make_layout(1), up_to_rank=3),
        )

    a_api = add_batch_mode(a_api)  # (M, K) -> (1, M, K)
    b_api = add_batch_mode(b_api)  # (K, N) -> (1, K, N)
    c_api = add_batch_mode(c_api)  # (M, N) -> (1, M, N)

    # Swap + mode reorder: API (L-first) -> TGV (L-last) with operand swap
    a_tgv = cute.make_tensor(
        b_api.iterator, cute.select(b_api.layout, [2, 1, 0])
    )  # (L,K,N) -> (N,K,L) = TGV a
    b_tgv = cute.make_tensor(
        a_api.iterator, cute.select(a_api.layout, [1, 2, 0])
    )  # (L,M,K) -> (M,K,L) = TGV b
    c_tgv = cute.make_tensor(
        c_api.iterator, cute.select(c_api.layout, [2, 1, 0])
    )  # (L,M,N) -> (N,M,L) = TGV c

    gemm_op(
        a_tgv,
        b_tgv,
        c_tgv,
        stream,
        pdl_count,
        pdl_stream_serialization,
        programmatic_event,
        programmatic_event_flags,
        programmatic_event_trigger_at_block_start,
    )


@CuTeDSLProvider.register
class Sm100TgvGemmOperator(CuteDslOperator):
    """Low-latency Blackwell GEMM kernel (TGV) for narrow-batch inference.

    Computes C = A @ B where A=activation, B=weight through the standard
    cutlass.operators GemmArguments interface. Internally swaps operands to match
    TGV's native convention (weight @ activation).

    .. note:: Tile shape semantics with operand swap:

        TGV internally swaps A/B operands: TGV_A=weight (API's B),
        TGV_B=activation (API's A).

        - ``tile_shape[0]`` = CTA_M tiles TGV's M dim = API's N (out_features)
        - ``tile_shape[1]`` = CTA_N tiles TGV's N dim = API's M (batch/tokens)
        - ``tile_shape[2]`` = CTA_K tiles the shared K (contraction) dim

        This means ``tile_shape[0]=64`` tiles the weight output feature dim, and
        ``tile_shape[1]=8`` tiles the batch dim — which is why small CTA_N suits
        small batch.

    .. note:: Layout requirements:

        - A (activation): row-major, K-contiguous, stride (0,0,1)
        - B (weight): col-major, K-contiguous, stride (0,1,0)
        - C (output): row-major, N-contiguous, stride (0,0,1)

    .. note:: Only emitted for small M (batch) <= 64.

    .. note:: Features:

        - 1 SM mode (no 2CTA instructions), 1x1 cluster
        - TMA loads for A and B, non-TMA-store epilogue
        - 8-warp specialization: DMA_A, DMA_B, MMA, EPILOG
        - No epilogue fusion support
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100
    # PDL dependency placement controls only the two input-load paths.
    _PDL_EARLY_START_OPERAND_NAMES = frozenset(("A", "B"))

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        pdl = metadata.design.pdl
        use_pdl = pdl.early_launch_dependent
        pdl_wait_on_tgv_a_load, pdl_wait_on_tgv_b_load = (
            Sm100TgvGemmOperator._pdl_wait_on_tgv_loads_from_metadata(pdl)
        )
        self.impl = TgvGemmKernel(
            acc_dtype=metadata.operands.accumulator_type,
            cta_m=metadata.design.tile_shape[0],
            cta_n=metadata.design.tile_shape[1],
            cta_k=metadata.design.tile_shape[2],
            num_ab_stage=metadata.design.num_smem_stages,
            use_pdl=use_pdl,
            pdl_wait_on_tgv_a_load=pdl_wait_on_tgv_a_load,
            pdl_wait_on_tgv_b_load=pdl_wait_on_tgv_b_load,
        )

    @staticmethod
    def _pdl_name_suffix(
        pdl: ProgrammaticDependentLaunchMetadata,
    ) -> str:
        if not pdl.early_launch_dependent and pdl.early_start is None:
            return ""

        # Format: _pdl[_<independent operand>...]. Conservative or empty
        # independent operands add no operand suffix.
        suffix_parts = ["pdl"]
        if pdl.early_start and pdl.early_start.independent_operands:
            suffix_parts.extend(pdl.early_start.independent_operands)
        return "_" + "_".join(suffix_parts)

    @staticmethod
    def _pdl_wait_on_tgv_loads_from_metadata(
        pdl: ProgrammaticDependentLaunchMetadata,
    ) -> tuple[bool, bool]:
        if pdl.early_start is None:
            return False, False

        independent_operands = set(pdl.early_start.independent_operands)
        dependent_operands = {"A", "B"} - independent_operands
        return (
            "B" in dependent_operands,
            "A" in dependent_operands,
        )

    @staticmethod
    def _pdl_control_or_none(
        performance: PerformanceControls | None,
    ) -> ProgrammaticDependentLaunchControl | None:
        """Extract the composed PDL control from ``performance``, if any."""
        if isinstance(performance, GemmPerformanceControls):
            return performance.pdl
        return None

    @classmethod
    def _pdl_metadata_for_args(
        cls,
        args: GemmArguments | None,
    ) -> list[ProgrammaticDependentLaunchMetadata]:
        """Return the PDL variant matching the runtime dependency declaration.

        TGV is always compiled with PDL support. Without an explicit early-start
        declaration, select the conservative variant where every operand waits
        for the dependency. With one, require an exact match so discovery does
        not return kernels compiled with a different dependency placement.
        """
        independent_operands: tuple[str, ...] = ()
        pdl_control = (
            cls._pdl_control_or_none(args.performance) if args is not None else None
        )
        if pdl_control is not None:
            early_start = pdl_control.early_start
            if early_start is not None:
                independent_operands = tuple(early_start.independent_operands)

        if not set(independent_operands) <= cls._PDL_EARLY_START_OPERAND_NAMES:
            return []

        return [
            ProgrammaticDependentLaunchMetadata(
                early_launch_dependent=True,
                early_start=EarlyStartMetadata(
                    independent_operands=independent_operands
                ),
            )
        ]

    def _pdl_count_from_args(self, args: GemmArguments) -> int:
        pdl_control = self._pdl_control_or_none(args.performance)
        if pdl_control is None:
            return -1
        if pdl_control.early_launch_dependent is None:
            return -1

        return -1

    @classmethod
    def _compile_pdl_args(cls, args: GemmArguments) -> list:
        """Build CuTeDSL compile placeholders for the runtime PDL signature."""
        compile_args: list[object] = [cutlass.Int32(0)]
        pdl_control = cls._pdl_control_or_none(args.performance)
        if pdl_control is None:
            return [*compile_args, False]

        early_start = pdl_control.early_start
        compile_args.append(
            early_start.pdl_stream_serialization if early_start is not None else False
        )

        early_launch_dependent = pdl_control.early_launch_dependent
        if (
            early_launch_dependent is not None
            and early_launch_dependent.pdl_programmatic_event is not None
        ):
            programmatic_event = early_launch_dependent.pdl_programmatic_event
            compile_args.extend(
                [
                    programmatic_event.programmatic_event,
                    programmatic_event.programmatic_event_flags,
                    programmatic_event.programmatic_event_trigger_at_block_start,
                ]
            )

        return compile_args

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        return self.cute_compile(
            _tgv_bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            cutlass.cute.runtime.make_fake_stream(),
            *self._compile_pdl_args(args),
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
        device_properties=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj

        run_args = [
            compiled_gemm,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            self._pdl_count_from_args(args),
        ]
        pdl_control = self._pdl_control_or_none(args.performance)
        if (
            pdl_control is not None
            and pdl_control.early_launch_dependent is not None
            and pdl_control.early_launch_dependent.pdl_programmatic_event is not None
        ):
            run_args.append(
                pdl_control.early_launch_dependent.pdl_programmatic_event.programmatic_event,
            )

        self.cute_run(*run_args)

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        # A and B must have the same dtype
        if operands.A.dtype != operands.B.dtype:
            return False

        abtype = operands.A.dtype

        # Supported A/B dtypes: float16, bfloat16, fp8
        if abtype not in [
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ]:
            return False

        # Only Float32 accumulator for TGV
        if operands.accumulator_type != cutlass.Float32:
            return False

        if operands.out.dtype in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
            return False
        if operands.out.dtype not in [abtype, cutlass.Float32]:
            return False

        # Layout constraints:
        # A (activation) must be row-major (K-contiguous): stride (0, 0, 1)
        if operands.A.stride != (0, 0, 1):
            return False

        # B (weight) must be col-major (K-contiguous): stride (0, 1, 0)
        if operands.B.stride != (0, 1, 0):
            return False

        # C (output) must be row-major (N-contiguous): stride (0, 0, 1)
        if operands.out.stride != (0, 0, 1):
            return False

        return True

    @staticmethod
    def _metadata_operands_from_args(
        args: GemmArguments,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        if any(not isinstance(arg, DenseTensor) for arg in [args.A, args.B, args.out]):
            return

        if args.A.dtype != args.B.dtype:
            return

        A_stride = normalized_major_stride(
            args.A.shape, args.A.stride, prepend_zeros_to_rank=3
        )
        B_stride = normalized_major_stride(
            args.B.shape, args.B.stride, prepend_zeros_to_rank=3
        )
        out_stride = normalized_major_stride(
            args.out.shape, args.out.stride, prepend_zeros_to_rank=3
        )

        # TGV requires specific layouts
        if A_stride != (0, 0, 1):
            return
        if B_stride != (0, 1, 0):
            return
        if out_stride != (0, 0, 1):
            return

        operands = generate.construct_dense_gemm_operands(
            args.A.dtype,
            args.B.dtype,
            args.out.dtype,
            args.accumulator_type,
            A_stride,
            B_stride,
            out_stride,
            alignment_bytes=16,
        )

        yield operands

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        ab_dtypes = [
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ]

        # TGV requires fixed layouts
        a_stride = (0, 0, 1)  # row-major (K-contiguous)
        b_stride = (0, 1, 0)  # col-major (K-contiguous)
        out_stride = (0, 0, 1)  # row-major (N-contiguous)

        for ab_dtype in ab_dtypes:
            # Only Float32 accumulator
            acc_dtype = cutlass.Float32

            # Output: same as input (if not FP8) or Float32.
            valid_out_dtypes = [cutlass.Float32]
            if ab_dtype not in [cutlass.Float8E4M3FN, cutlass.Float8E5M2]:
                valid_out_dtypes.insert(0, ab_dtype)
            for out_dtype in valid_out_dtypes:
                operands = generate.construct_dense_gemm_operands(
                    ab_dtype,
                    ab_dtype,
                    out_dtype,
                    acc_dtype,
                    a_stride,
                    b_stride,
                    out_stride,
                    alignment_bytes=16,
                )
                yield operands

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not Sm100TgvGemmOperator._valid_operands(metadata.operands):
            return False

        design = metadata.design
        if not isinstance(design, Sm100DesignMetadata):
            return False

        # TGV is 1 SM mode, no 2CTA, no TMA store, 1x1 cluster
        if design.use_2cta_mma:
            return False
        if design.use_tma_store:
            return False
        if design.cluster_shape != (1, 1, 1):
            return False

        tile = design.tile_shape
        if tile is not None:
            # CTA_M (tiles API's N / out_features): 64 only for now
            if tile[0] != 64:
                return False
            # CTA_N (tiles API's M / batch): small values
            if tile[1] not in [8, 16, 32]:
                return False
            # CTA_K: 128 fixed
            if tile[2] != 128:
                return False

        if metadata.epilogue is not None:
            return False

        return True

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[Sm100TgvGemmOperator]:
        if epilogue_args is not None:
            return []

        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [False],
            "tile_shape": [(64, n, 128) for n in [8, 16, 32]],
            "cluster_shape": [(1, 1, 1)],
            "use_tma_store": [False],
            "num_smem_stages": [8],
            "pdl": cls._pdl_metadata_for_args(args),
        }

        from itertools import product

        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        operator_list = []

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operands_generator = cls._metadata_operand_combinations()

        for operands in operands_generator:
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                operator_name = (
                    "cutedsl.Sm100TgvGemmOperator_{layout}_A{A}_B{B}_out{out}_acc{acc}_tile{tile}{pdl}"
                ).format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    acc=operands.accumulator_type,
                    tile=tuple_to_string(design.tile_shape),
                    pdl=cls._pdl_name_suffix(design.pdl),
                )

                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operator_name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )

                if Sm100TgvGemmOperator._valid_metadata(metadata) and metadata_filter(
                    metadata
                ):
                    operator_list.append(cls(metadata))

        return operator_list
