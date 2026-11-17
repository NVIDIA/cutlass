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
import fnmatch

import cutlass.operators as ops

from .cli import GLOB_ALL


def inspect(args: argparse.Namespace) -> list[object]:
    """By default, dumps the names of all matching operators."""
    name_glob_pattern = args.operators or GLOB_ALL

    def _operation_class(
        operation_name: str,
    ) -> type[ops.metadata.operands.OperandsMetadata]:
        match operation_name:
            case "gemm":
                return ops.metadata.operands.GemmOperandsMetadata
            case "grouped_gemm":
                return ops.metadata.operands.GroupedGemmOperandsMetadata
            case _:
                raise ValueError(f"Invalid operation name: {operation_name}")

    def _combined_metadata_filter(metadata: ops.OperatorMetadata) -> bool:
        operation_matches: bool = args.operation == "all" or isinstance(
            metadata.operands, _operation_class(args.operation)
        )

        return (
            fnmatch.fnmatchcase(metadata.operator_name, name_glob_pattern)
            and operation_matches
            and args.metadata_filter(metadata)
        )

    providers: list[ops.Provider] | None = (
        [args.provider] if args.provider is not None else None
    )
    operators = ops.get_operators(
        args=None, metadata_filter=_combined_metadata_filter, providers=providers
    )

    return [operator.metadata.operator_name for operator in operators]
