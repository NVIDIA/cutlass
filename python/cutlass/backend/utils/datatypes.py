#################################################################################################
#
# Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#################################################################################################

"""
Utility functions for converting between frontend datatypes and CUTLASS datatypes
"""

import cutlass_bindings

from cutlass.backend.utils.software import CheckPackages

numpy_available = CheckPackages().check_numpy()
if numpy_available:
    import numpy as np

    numpy_to_cutlass_dict = {
        np.float16: cutlass_bindings.float16,
        np.float32: cutlass_bindings.float32,
        np.float64: cutlass_bindings.float64,
        np.int8: cutlass_bindings.int8,
        np.int32: cutlass_bindings.int32,
        np.dtype('float16'): cutlass_bindings.float16,
        np.dtype('float32'): cutlass_bindings.float32,
        np.dtype('float64'): cutlass_bindings.float64,
        np.dtype('int8'): cutlass_bindings.int8,
        np.dtype('int32'): cutlass_bindings.int32,
    }


def numpy_to_cutlass(inp):
    numpy_available = CheckPackages().check_numpy()
    if numpy_available:
        return numpy_to_cutlass_dict.get(inp, None)


cupy_available = CheckPackages().check_cupy()
if cupy_available:
    import cupy as cp

    cupy_to_cutlass_dict = {
        cp.float16: cutlass_bindings.float16,
        cp.float32: cutlass_bindings.float32,
        cp.float64: cutlass_bindings.float64,
    }


def cupy_to_cutlass(inp):
    cupy_available = CheckPackages().check_cupy()
    if cupy_available:
        return cupy_to_cutlass_dict.get(inp, None)


torch_available = CheckPackages().check_torch()
if torch_available:
    import torch

    torch_to_cutlass_dict = {
        torch.half: cutlass_bindings.float16,
        torch.float16: cutlass_bindings.float16,
        torch.float: cutlass_bindings.float32,
        torch.float32: cutlass_bindings.float32,
        torch.double: cutlass_bindings.float64,
        torch.float64: cutlass_bindings.float64,
    }


def torch_to_cutlass(inp):
    if torch_available:
        return torch_to_cutlass_dict.get(inp, None)


try:
    import bfloat16

    bfloat16_available = True
    numpy_to_cutlass_dict[np.dtype(bfloat16.bfloat16)] = cutlass_bindings.bfloat16
except ImportError:
    bfloat16_available = False


def bfloat16_to_cutlass(inp):
    if bfloat16_available:
        if inp == bfloat16.bfloat16:
            return cutlass_bindings.bfloat16


def to_cutlass(inp):
    for cvt_fn in [
        bfloat16_to_cutlass,
        cupy_to_cutlass,
        numpy_to_cutlass,
        torch_to_cutlass,
    ]:
        out = cvt_fn(inp)
        if out is not None:
            return out

    raise Exception(
        "No available conversion from type {} to a CUTLASS type.".format(inp)
    )
