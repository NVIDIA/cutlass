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
Torch-style Grouped GEMM (MoE) kernel for cutlass_api.

This kernel implements `torch.nn.functional.grouped_mm` semantics, supporting
both forward (2Dx3D) and backward/weight-gradient (2Dx2D) scenarios for
Mixture of Experts (MoE) workloads on Blackwell (SM100) GPUs.

Scenarios:
- 2Dx3D (Forward):
    A: (tokens_sum, K)  x  B: (experts, K, N)  ->  out: (tokens_sum, N)
    offsets: (experts,) cumulative sum of token counts

- 2Dx2D (Backward / Weight Gradient):
    A: (hidden, tokens_sum)  x  B: (tokens_sum, intermediate)  ->  out: (experts, hidden, intermediate)
    offsets: (experts,) cumulative sum of token counts
"""

import itertools
from collections.abc import Callable, Generator

import cutlass
import cutlass.cute as cute

import cutlass_api
from cutlass_api.arguments import (
    EpilogueArguments,
    GroupedGemmArguments,
)
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import (
    DesignMetadata,
    EpilogueMetadata,
    GroupedGemmOperandsMetadata,
    KernelMetadata,
    TorchStyleGroupedMmDesignMetadata,
)
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.providers.cutedsl.utils import get_max_active_clusters
from cutlass_api.status import Status
from cutlass_api.utils import (
    TensorWrapper,
    strides_to_layout_string,
    to_cuda_stream,
    tuple_to_string,
)

from .implementations.moe.sm100_torch_style_grouped_mm_impl import (
    TorchStyleGroupedMmKernelImpl,
)
from .implementations.sm100_contiguous_offset_2d3d_dense_gemm_impl import (
    ContiguousOffset2D3DGemmDenseKernelImpl,
)

# Alias for reusing static validation methods from the contiguous offset impl
_Impl = ContiguousOffset2D3DGemmDenseKernelImpl


@CuTeDSLProvider.register
class TorchStyleGroupedMmKernel(CuteDslKernel):
    """
    CuTeDSL kernel for torch-style grouped GEMM (MoE).

    Supports two scenarios:
    - 2Dx3D (Forward):  A(tokens_sum, K) x B(experts, K, N) -> out(tokens_sum, N)
    - 2Dx2D (Backward): A(hidden, tokens_sum) x B(tokens_sum, intermediate) -> out(experts, hidden, intermediate)

    The scenario is specified via TorchStyleGroupedMmDesignMetadata.
    """

    def __init__(self, metadata: KernelMetadata):
        super().__init__(metadata)
        design: TorchStyleGroupedMmDesignMetadata = metadata.design

        self.impl = TorchStyleGroupedMmKernelImpl(
            scenario=design.scenario,
            out_dtype=metadata.operands.out.dtype,
            accumulate_on_output=design.accumulate_on_output,
            separate_tensormap_init=design.separate_tensormap_init,
            acc_dtype=metadata.operands.accumulator_type,
            mma_tiler_mnk=design.tile_shape,
            cluster_shape_mnk=design.cluster_shape,
            use_2cta_instrs=design.use_2cta_mma,
        )
        self._scenario = design.scenario

    def _get_expert_cnt(self, args: GroupedGemmArguments) -> int:
        """Extract expert count from arguments based on scenario."""
        if self._scenario == "2Dx3D":
            return args.B.shape[0]
        else:  # 2Dx2D
            return args.out.shape[0]

    def _supports(self, args: GroupedGemmArguments) -> Status:
        """Check if this kernel configuration supports the given arguments."""
        if len(args.offsets.shape) != 1:
            return Status.fail(f"offsets must be a 1D tensor. Got {args.offsets.shape}")

        if self._scenario == "2Dx3D":
            # A: (tokens_sum, K), B: (experts, K, N), out: (tokens_sum, N)
            if len(args.A.shape) != 2:
                return Status.fail(f"2Dx3D: A must be 2D. Got shape {args.A.shape}")
            if len(args.B.shape) != 3:
                return Status.fail(f"2Dx3D: B must be 3D. Got shape {args.B.shape}")
            if len(args.out.shape) != 2:
                return Status.fail(f"2Dx3D: out must be 2D. Got shape {args.out.shape}")

            tokens_sum, K = args.A.shape
            experts, K_b, N = args.B.shape
            tokens_out, N_out = args.out.shape

            if K != K_b:
                return Status.fail(f"K mismatch: A K={K}, B K={K_b}")
            if tokens_sum != tokens_out:
                return Status.fail(f"tokens_sum mismatch: A={tokens_sum}, out={tokens_out}")
            if N != N_out:
                return Status.fail(f"N mismatch: B N={N}, out N={N_out}")
            if args.offsets.numel() != experts:
                return Status.fail(
                    f"offsets must have {experts} elements. Got {args.offsets.numel()}"
                )
        else:  # 2Dx2D
            # A: (hidden, tokens_sum), B: (tokens_sum, intermediate), out: (experts, hidden, intermediate)
            if len(args.A.shape) != 2:
                return Status.fail(f"2Dx2D: A must be 2D. Got shape {args.A.shape}")
            if len(args.B.shape) != 2:
                return Status.fail(f"2Dx2D: B must be 2D. Got shape {args.B.shape}")
            if len(args.out.shape) != 3:
                return Status.fail(f"2Dx2D: out must be 3D. Got shape {args.out.shape}")

            hidden, tokens_sum = args.A.shape
            tokens_b, intermediate = args.B.shape
            experts, hidden_out, intermediate_out = args.out.shape

            if tokens_sum != tokens_b:
                return Status.fail(f"tokens_sum mismatch: A={tokens_sum}, B={tokens_b}")
            if hidden != hidden_out:
                return Status.fail(f"hidden mismatch: A={hidden}, out={hidden_out}")
            if intermediate != intermediate_out:
                return Status.fail(
                    f"intermediate mismatch: B={intermediate}, out={intermediate_out}"
                )
            if args.offsets.numel() != experts:
                return Status.fail(
                    f"offsets must have {experts} elements. Got {args.offsets.numel()}"
                )

        return Status.success()

    def get_workspace_size(self, args: GroupedGemmArguments) -> int:
        """Return workspace size in bytes for expert-wise TMA descriptors."""
        expert_cnt = self._get_expert_cnt(args)
        return self.impl.get_workspace_size(expert_cnt)

    def compile(self, args: GroupedGemmArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        # Create a fake workspace tensor for compilation tracing.
        # At compile time only the type signature matters, not actual memory.
        fake_workspace = cute.runtime.make_fake_compact_tensor(
            cutlass.Uint8,
            [cute.SymInt()],
            stride_order=(0,),
            assumed_align=128,
        )

        compiled_kernel = self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            None,  # bias
            TensorWrapper(fake_workspace, alignment_bytes=128),
            max_active_clusters,
            stream,
        )
        return CompiledArtifact(compiled_kernel, self)

    def _run(
        self,
        args: GroupedGemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        if workspace is None:
            raise ValueError(
                "TorchStyleGroupedMmKernel requires a workspace tensor. "
                "Call get_workspace_size(args) and allocate workspace before run()."
            )
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj

        workspace_wrapper = TensorWrapper(workspace, alignment_bytes=128)

        self.cute_run(
            compiled_gemm,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            None,  # bias
            workspace_wrapper,
            stream,
        )

    # =========================================================================
    # Validation (reuses ContiguousOffset2D3DGemmDenseKernelImpl statics)
    # =========================================================================

    @staticmethod
    def _valid_operands(operands: GroupedGemmOperandsMetadata) -> bool:
        return _Impl.is_valid_dtypes(
            operands.A.dtype, operands.accumulator_type, operands.out.dtype
        )

    @staticmethod
    def _valid_design_metadata(design: TorchStyleGroupedMmDesignMetadata) -> bool:
        if not isinstance(design, TorchStyleGroupedMmDesignMetadata):
            return False
        if not _Impl.is_valid_mma_tiler_and_cluster_shape(
            design.use_2cta_mma, design.tile_shape[:2], design.cluster_shape[:2]
        ):
            return False
        if design.scenario not in ("2Dx3D", "2Dx2D"):
            return False
        if design.accumulate_on_output and design.scenario != "2Dx2D":
            return False
        return True

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @staticmethod
    def _valid_metadata(metadata: KernelMetadata) -> bool:
        if not TorchStyleGroupedMmKernel._valid_operands(metadata.operands):
            return False
        if not TorchStyleGroupedMmKernel._valid_design_metadata(metadata.design):
            return False
        if not TorchStyleGroupedMmKernel._valid_epilogue_metadata(metadata.epilogue):
            return False
        return True

    # =========================================================================
    # Kernel generation
    # =========================================================================

    @staticmethod
    def _get_valid_tile_k_values(ab_dtype) -> list[int]:
        """
        Compute valid tile_k values based on element size.
        Targets 64B, 128B, 256B of K data per tile.
        """
        elem_bytes = ab_dtype.width // 8
        return [64 // elem_bytes, 128 // elem_bytes, 256 // elem_bytes]

    @staticmethod
    def _metadata_operand_combinations() -> Generator[
        GroupedGemmOperandsMetadata, None, None
    ]:
        """
        Generator that yields all valid GroupedGemmOperandsMetadata combinations.

        Layout constraints (dynamic token dim must NOT be stride-1):
        - 2Dx3D: A k-major, B any, C n-major
        - 2Dx2D: A m-major, B n-major, C any

        Since layout constraints differ by scenario, we yield operands for both
        scenarios. The scenario itself is in design metadata, not operands.
        We encode enough stride info here to distinguish them.
        """
        ab_dtypes = [
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
            cutlass.Float16,
            cutlass.BFloat16,
        ]

        out_dtypes = [
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
        ]

        alignment_bytes = 16
        offsets_alignment_bytes = 4
        acc_dtype = cutlass.Float32

        for ab_dtype, out_dtype in itertools.product(ab_dtypes, out_dtypes):
            if not _Impl.is_valid_dtypes(ab_dtype, acc_dtype, out_dtype):
                continue

            ab_div = alignment_bytes * 8 // ab_dtype.width
            out_div = alignment_bytes * 8 // out_dtype.width
            offs_div = offsets_alignment_bytes * 8 // cutlass.Int32.width

            offsets_attrs = cutlass_api.metadata.DenseTensorAttributes(
                dtype=cutlass.Int32, stride=(1,), divisibility=offs_div,
            )

            # Stride convention: 1 = stride-1 (contiguous), 0 = non-contiguous or batch
            #
            # 2Dx3D: token dim (dynamic) must NOT be stride-1
            #   A(tokens_sum, K): K stride-1 → (0, 1)
            #   B(experts, K, N): no dynamic dim → any layout
            #   C(tokens_sum, N): N stride-1 → (0, 1)
            k_stride1_2d = (0, 1)   # last dim is stride-1
            for b_stride in [(0, 0, 1), (0, 1, 0)]:  # B: N stride-1 or K stride-1
                yield GroupedGemmOperandsMetadata(
                    A=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=ab_dtype, stride=k_stride1_2d, divisibility=ab_div,
                    ),
                    B=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=ab_dtype, stride=b_stride, divisibility=ab_div,
                    ),
                    out=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=out_dtype, stride=k_stride1_2d, divisibility=out_div,
                    ),
                    offsets=offsets_attrs,
                    accumulator_type=acc_dtype,
                )

            # 2Dx2D: token dim (dynamic) must NOT be stride-1
            #   A(hidden, tokens_sum): hidden stride-1 → (1, 0)
            #   B(tokens_sum, inter):  inter stride-1  → (0, 1)
            #   C(experts, hidden, inter): no dynamic dim → any layout
            m_stride1_2d = (1, 0)   # first dim is stride-1
            n_stride1_2d = (0, 1)   # last dim is stride-1
            for c_stride in [(0, 0, 1), (0, 1, 0)]:  # C: inter stride-1 or hidden stride-1
                yield GroupedGemmOperandsMetadata(
                    A=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=ab_dtype, stride=m_stride1_2d, divisibility=ab_div,
                    ),
                    B=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=ab_dtype, stride=n_stride1_2d, divisibility=ab_div,
                    ),
                    out=cutlass_api.metadata.DenseTensorAttributes(
                        dtype=out_dtype, stride=c_stride, divisibility=out_div,
                    ),
                    offsets=offsets_attrs,
                    accumulator_type=acc_dtype,
                )

    @staticmethod
    def _infer_scenario_from_operands(operands: GroupedGemmOperandsMetadata) -> str:
        """
        Infer scenario from operand metadata.

        2Dx3D: B has 3D stride (experts, K, N)
        2Dx2D: out has 3D stride (experts, M, N) and B has 2D stride
        """
        if len(operands.B.stride) == 3:
            return "2Dx3D"
        elif len(operands.out.stride) == 3:
            return "2Dx2D"
        else:
            raise ValueError(
                f"Cannot infer scenario: B.stride={operands.B.stride}, "
                f"out.stride={operands.out.stride}"
            )

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["TorchStyleGroupedMmKernel"]:
        """
        Returns a list of all possible configurations of TorchStyleGroupedMmKernel
        that adhere to constraints passed in under kwargs.
        """
        if cc is not None and cc not in [100, 101, 103]:
            return []

        if epilogue_args is not None:
            return []

        # M, N tile dimensions to enumerate
        tile_m_values = [64, 128, 256]
        tile_n_values = [32, 64, 128, 256]
        use_2cta_values = [True, False]
        cluster_mn_values = [(M, N) for M in [1, 2, 4] for N in [1, 2, 4]]
        sep_tensormap_init_values = [True]  # Always separate for now
        scenario_grad_acc_combos = [
            ("2Dx3D", False),
            ("2Dx2D", False),
            ("2Dx2D", True),
        ]

        kernel_list = []

        for operands in TorchStyleGroupedMmKernel._metadata_operand_combinations():
            inferred_scenario = TorchStyleGroupedMmKernel._infer_scenario_from_operands(operands)
            ab_dtype = operands.A.dtype
            valid_tile_k_values = TorchStyleGroupedMmKernel._get_valid_tile_k_values(ab_dtype)

            for (
                use_2cta, tile_m, tile_n, tile_k, cluster_mn,
                sep_init, (scenario, grad_acc),
            ) in itertools.product(
                use_2cta_values,
                tile_m_values,
                tile_n_values,
                valid_tile_k_values,
                cluster_mn_values,
                sep_tensormap_init_values,
                scenario_grad_acc_combos,
            ):
                # Skip if operands don't match the scenario
                if scenario != inferred_scenario:
                    continue

                tile_shape = (tile_m, tile_n, tile_k)
                cluster_shape = (cluster_mn[0], cluster_mn[1], 1)

                design = TorchStyleGroupedMmDesignMetadata(
                    tile_shape=tile_shape,
                    cluster_shape=cluster_shape,
                    use_2cta_mma=use_2cta,
                    use_tma_store=True,  # Always True for MoE
                    scenario=scenario,
                    separate_tensormap_init=sep_init,
                    accumulate_on_output=grad_acc,
                )

                # Naming
                sep_tag = "sep_desc_init" if sep_init else "fused_desc_init"
                grad_tag = "_grad_acc" if grad_acc else ""
                kernel_name = (
                    f"cutedsl.TorchStyleGroupedMmKernel_sm100"
                    f"_{scenario}"
                    f"_{strides_to_layout_string(operands.A.stride, operands.B.stride, operands.out.stride)}"
                    f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}"
                    f"_acc{operands.accumulator_type}"
                    f"_{'2' if use_2cta else '1'}cta"
                    f"_cluster{tuple_to_string(cluster_shape)}"
                    f"_tile{tuple_to_string(tile_shape)}"
                    f"_{sep_tag}{grad_tag}"
                )

                metadata = KernelMetadata(
                    operands=operands,
                    design=design,
                    kernel_name=kernel_name,
                    kernel_class=TorchStyleGroupedMmKernel,
                    min_cc=100,
                    epilogue=None,
                )

                metadata_valid = TorchStyleGroupedMmKernel._valid_metadata(metadata)
                if metadata_valid and metadata_filter(metadata):
                    kernel_list.append(TorchStyleGroupedMmKernel(metadata))

        return kernel_list
