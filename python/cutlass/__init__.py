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

import logging
import os
import sys

import cutlass_library


def _cutlass_path_from_dir() -> str:
    cutlass_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), '../../')
    if not os.path.isdir(cutlass_path):
        raise Exception(f'Environment variable "CUTLASS_PATH" is not defined, '
                        f'and default path of {cutlass_path} does not exist.')
    return cutlass_path


def _cuda_install_path_from_nvcc() -> str:
    import subprocess
    # Attempt to detect CUDA_INSTALL_PATH based on location of NVCC
    result = subprocess.run(['which', 'nvcc'], capture_output=True)
    if result.returncode != 0:
        raise Exception(f'Unable to find nvcc via `which` utility.')

    cuda_install_path = result.stdout.decode('utf-8').split('/bin/nvcc')[0]
    if not os.path.isdir(cuda_install_path):
        raise Exception(f'Environment variable "CUDA_INSTALL_PATH" is not defined, '
                        f'and default path of {cuda_install_path} does not exist.')

    return cuda_install_path


CUTLASS_PATH = os.getenv("CUTLASS_PATH", _cutlass_path_from_dir())
CUDA_INSTALL_PATH = os.getenv("CUDA_INSTALL_PATH", _cuda_install_path_from_nvcc())
CACHE_FILE = "compiled_cache.db"

# Import types/methods from the CUTLASS utility libraries for profiler generation/emission under
from cutlass_library.library import (
    ArchitectureNames,
    ComplexTransform,
    ComplexTransformTag,
    ConvKind,
    ConvKindNames,
    ConvKindTag,
    ConvMode,
    DataType,
    DataTypeNames,
    DataTypeSize,
    DataTypeTag,
    EpilogueFunctor,
    EpilogueScheduleSuffixes,
    EpilogueScheduleTag,
    EpilogueScheduleType,
    GemmKind,
    GemmKindNames,
    GemmUniversalMode,
    IteratorAlgorithm,
    IteratorAlgorithmNames,
    IteratorAlgorithmTag,
    LayoutTag,
    LayoutType,
    KernelScheduleSuffixes,
    KernelScheduleTag,
    KernelScheduleType,
    MathInstruction,
    MathOperation,
    MathOperationTag,
    OpcodeClass,
    OpcodeClassNames,
    OpcodeClassTag,
    OperationKind,
    SharedMemPerCC,
    ShortComplexLayoutNames,
    ShortDataTypeNames,
    ShortLayoutTypeNames,
    SplitKMode,
    StrideSupport,
    StrideSupportNames,
    StrideSupportTag,
    SwizzlingFunctor,
    SwizzlingFunctorTag,
    TensorDescription,
    TileDescription,
    TileSchedulerSuffixes,
    TileSchedulerTag,
    TileSchedulerType,
    get_complex_from_real,
)

this = sys.modules[__name__]
this.logger = logging.getLogger(__name__)

def set_log_level(level: int):
    """
    Sets the log level

    :param log_level: severity of logging level to use. See https://docs.python.org/3/library/logging.html#logging-levels for options
    :type log_level: int
    """
    this.logger.setLevel(level)

set_log_level(logging.ERROR)

from cutlass.library_defaults import OptionRegistry
from cutlass.backend.utils.device import device_cc

this.option_registry = OptionRegistry(device_cc())

this.__version__ = '3.2.1'

from cutlass.backend import get_memory_pool
from cutlass.emit.pytorch import pytorch
from cutlass.op.gemm import Gemm
from cutlass.op.conv import Conv2d, Conv2dFprop, Conv2dDgrad, Conv2dWgrad
from cutlass.op.gemm_grouped import GroupedGemm
from cutlass.op.op import OperationBase
from cutlass.backend.evt.ir.tensor import Tensor

get_memory_pool(init_pool_size=2 ** 30, max_pool_size=2 ** 32)
