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

from typing import TYPE_CHECKING

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute

import cutlass.operators.utils.generate as generate
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
)
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    OperatorMetadata,
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

    gemm_op(a_tgv, b_tgv, c_tgv, stream)


@CuTeDSLProvider.register
class TgvGemmOperator(CuteDslOperator):
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

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        self.impl = TgvGemmKernel(
            acc_dtype=metadata.operands.accumulator_type,
            cta_m=metadata.design.tile_shape[0],
            cta_n=metadata.design.tile_shape[1],
            cta_k=metadata.design.tile_shape[2],
            num_ab_stage=metadata.design.num_smem_stages,
        )

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()

        compiled_kernel = self.cute_compile(
            _tgv_bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            target_sm=target_sm,
        )
        return compiled_kernel

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(
            compiled_gemm,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
        )

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
        if not TgvGemmOperator._valid_operands(metadata.operands):
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
            if tile[0] not in [64]:
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
    ) -> list[TgvGemmOperator]:
        if epilogue_args is not None:
            return []

        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [False],
            "tile_shape": [(64, n, 128) for n in [8, 16, 32]],
            "cluster_shape": [(1, 1, 1)],
            "use_tma_store": [False],
            "num_smem_stages": [8],
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
                    "cutedsl.TgvGemmOperator_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_tile{tile}"
                ).format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    acc=operands.accumulator_type,
                    tile=tuple_to_string(design.tile_shape),
                )

                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operator_name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )

                if TgvGemmOperator._valid_metadata(metadata) and metadata_filter(
                    metadata
                ):
                    operator_list.append(cls(metadata))

        return operator_list
