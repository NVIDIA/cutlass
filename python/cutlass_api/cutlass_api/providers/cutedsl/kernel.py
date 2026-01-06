# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import cutlass.cute as cute

from cutlass_api.config import GlobalOptions
from cutlass_api.kernel import Kernel
from cutlass_api.utils import TensorWrapper


class CuteDslKernel(Kernel):
    """
    Base class for all CuTe DSL kernels
    """

    def cute_compile(self, entry_point_fn, *fn_args):
        """
        Compiles a kernel using CuTe DSL compile.

        This method is intended to provider a provider-wide consistent implementation of compile() for
        all CuTe DSL kernels, respecting GlobalOptions.

        :param entry_point_fn: The kernel function to compile
        :param fn_args: All arguments to pass to the kernel compilation
        :return: The compiled kernel object
        """
        options = None
        if GlobalOptions().use_tvm_ffi:
            options = "--enable-tvm-ffi"

        compile_args = [
            x.compile_time_tensor if isinstance(x, TensorWrapper) else x
            for x in fn_args
        ]
        return cute.compile(entry_point_fn, *compile_args, options=options)

    def cute_run(self, entry_point_fn, *fn_args):
        """
        Extracts runtime tensors from TensorWrappers and runs the kernel.

        :param entry_point_fn: The kernel function to run
        :param fn_args: All arguments to pass to the kernel run
        :return: The result of the kernel run
        """
        run_args = [
            x.runtime_tensor if isinstance(x, TensorWrapper) else x for x in fn_args
        ]
        return entry_point_fn(*run_args)
