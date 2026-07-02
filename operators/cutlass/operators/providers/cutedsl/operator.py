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

from __future__ import annotations

import cutlass.cute as cute
from cutlass.cutlass_dsl import CuTeDSL

from cutlass.operators.arch import TargetSm
from cutlass.operators.artifact import CompiledArtifact
from cutlass.operators.base import Operator
from cutlass.operators.config import GlobalOptions
from cutlass.operators.utils.tensor import TensorWrapper


class CuteDslOperator(Operator):
    """Base class for all CuTe DSL operators"""

    def cute_compile(self, entry_point_fn, *fn_args, target_sm: TargetSm | None = None):
        """Compiles an operator using CuTe DSL compile.

        This method is intended to provide a provider-wide consistent implementation of compile() for
        all CuTe DSL operators, respecting GlobalOptions.

        :param entry_point_fn: The operator's entry-point function to compile
        :param fn_args: All arguments to pass to the operator's compilation
        :param target_sm: Target compute capability to compile the operator for.
        If not provided, the operator will be compiled for the compute capability of the current device.
        :type target_sm: TargetSm | None
        :return: The compiled artifact
        """
        # If no target_sm specified, determine the same as what CuTe DSL does.
        # Explicitly set it as a compilation option so that the compiled_for sm
        # reported in CompiledArtifact is accurate.
        target_sm = target_sm or TargetSm(
            CuTeDSL._get_dsl().envar.arch.removeprefix("sm_")
        )

        compile_args = [
            x.compile_time_tensor if isinstance(x, TensorWrapper) else x
            for x in fn_args
        ]

        compiled_fn = cute.compile[
            cute.GPUArch(f"sm_{target_sm}"),
            cute.EnableTVMFFI(GlobalOptions().use_tvm_ffi),
        ](entry_point_fn, *compile_args)

        return CompiledArtifact(
            compiled_obj=compiled_fn,
            operator_obj=self,
            compiled_for=target_sm,
        )

    def cute_run(self, entry_point_fn, *fn_args):
        """Extracts runtime tensors from TensorWrappers and runs the operator.

        :param entry_point_fn: The operator's entry-point function to run
        :param fn_args: All arguments to pass to the operator
        :return: The result of running the operator
        """
        run_args = [
            x.runtime_tensor if isinstance(x, TensorWrapper) else x for x in fn_args
        ]
        return entry_point_fn(*run_args)
