#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import re
import sys

from cutlass.backend.memory_manager import PoolMemoryManager


class CheckPackages:
    def __init__(self) -> None:
        pass

    def check_cupy(self):
        if "cupy" in sys.modules:
            return True
        else:
            try:
                import cupy

                cupy_available = True
            except ImportError:
                print("cupy is not loaded.")

    def check_numpy(self):
        if "numpy" in sys.modules:
            return True
        else:
            try:
                import numpy

                numpy_available = True
            except ImportError:
                print("numpy is not loaded.")

    def check_torch(self):
        if "torch" in sys.modules:
            return True
        else:
            try:
                import torch

                torch_available = True
            except ImportError:
                print("torch is not loaded.")


def SubstituteTemplate(template, values):
    text = template
    changed = True
    while changed:
        changed = False
        for key, value in values.items():
            regex = "\\$\\{%s\\}" % key
            newtext = re.sub(regex, value, text)
            if newtext != text:
                changed = True
            text = newtext
    return text


def device_sm_count():
    from cuda import cuda

    _device = 0
    err, _device_sm_count = cuda.cuDeviceGetAttribute(
        cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT, _device
    )
    if err != cuda.CUresult.CUDA_SUCCESS:
        raise Exception(
            "Failed to retireve SM count. "
            f"cuDeviceGetAttribute() failed with error: {cuda.cuGetErrorString(err)[1]}"
        )

    return _device_sm_count


def get_memory_pool(init_pool_size=0, max_pool_size=2 ** 34):
    memory_pool = PoolMemoryManager(
        init_pool_size=init_pool_size, max_pool_size=max_pool_size
    )
    return memory_pool
