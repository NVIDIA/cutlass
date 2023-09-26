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

from math import prod
from typing import Union

from cuda import cuda, cudart
import numpy as np

from cutlass.backend.frontend import CupyFrontend, NumpyFrontend, TorchFrontend
from cutlass.backend.utils.software import CheckPackages

torch_available = CheckPackages().check_torch()
if torch_available:
    import torch

cupy_available = CheckPackages().check_cupy()
if cupy_available:
    import cupy as cp


class ArgumentBase:
    """
    Base class for operation arguments
    """

    def __init__(
        self,
        A: "Union[cuda.CUdeviceptr, np.ndarray, torch.Tensor, cp.ndarray]",
        B: "Union[cuda.CUdeviceptr, np.ndarray, torch.Tensor, cp.ndarray]",
        C: "Union[cuda.CUdeviceptr, np.ndarray, torch.Tensor, cp.ndarray]",
        D: "Union[cuda.CUdeviceptr, np.ndarray, torch.Tensor, cp.ndarray]",
        **kwargs,
    ) -> None:
        # tensor_C can be interpreted as the bias with bias=True in keyword args
        if "bias" in kwargs.keys():
            self.bias = kwargs["bias"]
        else:
            # by default, tensor_C is not bias
            self.bias = False

        # RMM buffers used to track tensor lifetime
        self.buffers = {}
        # Host tensor to copy the computed result back
        self.host_tensors = {}

        self.ptr_A = self.tensor_to_ptr(A, "A")
        self.ptr_B = self.tensor_to_ptr(B, "B")
        self.ptr_C = self.tensor_to_ptr(C, "C")
        self.ptr_D = self.tensor_to_ptr(D, "D", True)
        if C is not None:
            if not isinstance(C, cuda.CUdeviceptr):
                self.tensor_c_numel = prod(C.shape)

    def tensor_to_ptr(self, tensor, name, is_output=False):
        """
        Convert and remember the input tensor to cuda.CUdeviceptr used by cuda python
        For numpy.ndarray, it also remembers the host buffer for synchronization
        """
        if tensor is None:
            return cuda.CUdeviceptr(0)
        if isinstance(tensor, np.ndarray):
            if is_output:
                assert name
            self.buffers[name] = NumpyFrontend.argument(tensor, is_output)
            if is_output:
                self.host_tensors[name] = tensor
            return self.buffers[name].ptr
        elif torch_available and isinstance(tensor, torch.Tensor):
            return TorchFrontend.argument(tensor)
        elif isinstance(tensor, cuda.CUdeviceptr):
            return tensor
        elif cupy_available and isinstance(tensor, cp.ndarray):
            return CupyFrontend.argument(tensor)
        else:
            raise TypeError("Unsupported Frontend. Only support numpy and torch")

    def sync(self, stream_sync=True):
        if stream_sync:
            (err,) = cudart.cudaDeviceSynchronize()
            if err != cuda.CUresult.CUDA_SUCCESS:
                raise RuntimeError("CUDA Error %s" % str(err))

        for key in self.host_tensors.keys():
            host_tensor = self.host_tensors[key]
            (err,) = cuda.cuMemcpyDtoH(
                host_tensor,
                self.buffers[key].ptr,
                host_tensor.size * host_tensor.itemsize,
            )
            if err != cuda.CUresult.CUDA_SUCCESS:
                raise RuntimeError("CUDA Error %s" % str(err))
