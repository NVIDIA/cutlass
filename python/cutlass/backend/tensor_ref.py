################################################################################
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
################################################################################

from cuda import cuda
import cutlass_bindings
import numpy as np

from cutlass.backend.utils.software import CheckPackages

cupy_available = CheckPackages().check_cupy()
if cupy_available:
    import cupy as cp

torch_available = CheckPackages().check_torch()
if torch_available:
    import torch


class TensorRef:
    """
    Python Wrapper for cutlass_bindings.TensorRef
    """

    def __init__(self, tensor, dtype, layout) -> None:
        if isinstance(tensor, np.ndarray):
            ptr = cuda.CUdeviceptr(tensor.__array_interface__["data"][0])
        elif torch_available and isinstance(tensor, torch.Tensor):
            ptr = cuda.CUdeviceptr(tensor.data_ptr())
        elif torch_available and isinstance(tensor, cp.ndarray):
            ptr = cuda.CUdeviceptr(int(tensor.data.ptr))
        elif isinstance(tensor, cuda.CUdeviceptr):
            ptr = tensor
        elif isinstance(tensor, int):
            ptr = cuda.CUdeviceptr(tensor)
        else:
            raise NotImplementedError(tensor)

        # the dtype(0) is used to overload between different data types
        # with the same layout
        self.tensor_ref = cutlass_bindings.get_tensor_ref(int(ptr), dtype(0), layout)
