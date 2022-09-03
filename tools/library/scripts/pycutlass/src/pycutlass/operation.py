################################################################################
#
# Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved
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

import ctypes
from cuda import cuda

################################################################################
#
# Launch configuration
#
################################################################################


class LaunchConfiguration:
    def __init__(self, grid=[1, 1, 1], block=[1, 1, 1], smem=0):
        self.grid = grid
        self.block = block
        self.shared_memory_capacity = smem


################################################################################
#
# Base class for an executable operation
#
# ##############################################################################

class ExecutableOperation:
    '''
    '''

    def __init__(self, operation):
        self.operation = operation
        self.module = None
        self.kernel = None

    #
    def name(self):
        return self.operation.procedural_name()

    #
    def emit(self):
        return ''

    #
    def can_implement(self, configuration, arguments):
        raise NotImplementedError()

    #
    def get_host_workspace_size(self, arguments):
        raise NotImplementedError()

    #
    def get_device_workspace_size(self, arguments):
        raise NotImplementedError()

    #
    def plan(self, arguments):
        raise NotImplementedError()

    #
    def initialize(self, host_workspace, device_workspace, launch_config, arguments, stream=cuda.CUstream(0)):
        raise NotImplementedError()

    #
    def run(self, host_workspace, device_workspace, launch_config, stream=cuda.CUstream(0)):

        cArg = (ctypes.c_char * len(host_workspace)
                ).from_buffer(host_workspace)
        packed = (ctypes.c_void_p * 1)()
        packed[0] = ctypes.addressof(cArg)

        err, = cuda.cuLaunchKernel(
            self.kernel,
            launch_config.grid[0], launch_config.grid[1], launch_config.grid[2],
            launch_config.block[0], launch_config.block[1], launch_config.block[2],
            launch_config.shared_memory_capacity,
            stream,
            packed,
            0)

        return err
