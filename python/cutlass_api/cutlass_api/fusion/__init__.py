#
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
#


import ast
import textwrap
from typing import Callable, Union

from cutlass_api.fusion.ir.tensor import Tensor as EmptyTensor
from cutlass_api.fusion.frontend import PythonASTFrontend, PythonASTInOutProcessor


def trace_in_out(fn: Union[Callable, str]) -> tuple[list[str], list[str]]:
    """
    Trace the input function and returns the names of inputs and outputs

    :param fn: The function to trace.
    :type fn: Union[Callable, str]
    :return: A tuple of lists of input and output names.
    :rtype: tuple[list[str], list[str]]
    """
    processor = PythonASTInOutProcessor()
    return processor.trace(fn)


def trace(fn, example_tensors, **kwargs):
    """
    Trace `fn(**example_tensors)` and generates epilogue visitor

    :param fn or str: Python callable or string of the epilogue function
    :param example_tensors: example inputs for fn
    :type example_tensors: dict

    .. hightlight:: python
    .. code-block:: python

        # Define epilogue function as Python callable
        def example_fn(accum, C, alpha, beta, gamma):
            D = ((accum + C) * alpha - gamma) / beta
            return D

        # Define the example tensors
        example_inputs = {
            "accum": torch.empty(size=(6, 512, 512), dtype=torch.float16, device="cuda"),
            "C": torch.empty(size=(6, 512, 512), dtype=torch.float16, device="cuda"),
            "alpha": 1.5,
            "beta": 0.5,
            "gamma": 2.5,
            "D": torch.empty(size=(6, 512, 512), dtype=torch.float16, device="cuda")
        }

        # Generate the epilogue functor
        epilogue_visitor = cutlass_api.fusion.trace(example_fn, example_inputs)
    """
    if callable(fn):

        class EpilogueFunctor(PythonASTFrontend):
            def __init__(self, cc=None, **kwargs):
                # Since we are currently only using the trace() method for generating an
                # intermiediate representation (which is not CC specific), we can hardcode the cc to 100
                if not cc:
                    cc = 100
                super().__init__(cc, **kwargs)

            pass

        setattr(EpilogueFunctor, "__call__", staticmethod(fn))

        epilogue_functor = EpilogueFunctor(**kwargs)
        epilogue_functor.trace(example_tensors)
        return epilogue_functor
    elif isinstance(fn, str):

        class EpilogueFunctor(PythonASTFrontend):
            def __init__(self, cc=None, **kwargs):
                self.source = textwrap.dedent(fn)
                # Since we are currently only using the trace() method for generating an
                # intermiediate representation (which is not CC specific), we can hardcode the cc to 100
                if not cc:
                    cc = 100
                super().__init__(cc, **kwargs)

            def parse(self, example_inputs) -> None:
                self.example_inputs = example_inputs
                self.ast = ast.parse(self.source)
                self.visit(self.ast)

        epilogue_functor = EpilogueFunctor(**kwargs)
        epilogue_functor.trace(example_tensors)
        return epilogue_functor
    else:
        raise NotImplementedError("Expect a callable Python function")


__all__ = [
    "EmptyTensor",
    "trace_in_out",
    "trace",
]
