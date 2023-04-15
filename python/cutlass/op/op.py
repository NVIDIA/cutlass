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

"""
Base operation used for defining high-level CUTLASS operations (e.g., GEMM, Conv2d)
"""

from bisect import bisect_left

from cutlass import option_registry
from cutlass.backend.utils.device import device_cc
from cutlass.epilogue import get_activations
from cutlass.library_defaults import _generator_ccs
from cutlass.swizzle import get_swizzling_functors


class OperationBase:
    """
    Base operation used for defining high-level CUTLASS operations (e.g., GEMM, Conv2d)
    """

    def __init__(self, cc: int = None, kernel_cc: int = None):
        """
        :param cc: compute capability of device for which kernels should be compiled. For example, if running on H100, this should be set to 90
        :type cc: int
        :param kernel_cc: compute capability of kernels to generate. For example, if running on SM90, but desiring to use a CUTLASS 2.x-style Ampere kernel, this should be set to 80
        :type kernel_cc: int
        """
        self.cc = cc if cc is not None else device_cc()
        self.specified_kernel_cc = kernel_cc is not None
        self.current_cc = kernel_cc if kernel_cc is not None else self._find_closest_cc(self.cc)
        self.tile_description = None

        self.options = option_registry.options_for_cc(self.current_cc)

        if self.options is None:
            raise Exception(f"Invalid or unsupported compute capability: {self.current_cc}")

    def _find_closest_cc(self, cc: int) -> int:
        """
        Returns the closest CC in _generator_ccs less than or equal to `cc`

        :param cc: compute capability to query
        :type cc: int

        :returns: closest CC in _generator_ccs less than or equal to `cc`
        :rtype: int
        """
        if cc in _generator_ccs:
            return cc

        # Find closest CC lower than this CC
        idx = bisect_left(_generator_ccs, cc)
        if idx == 0:
            raise Exception(f'No valid CC to fall back to for {cc}')
        return _generator_ccs[idx-1]

    def activations(self) -> list:
        """
        Returns possible activation functions that can be used

        :return: list of activation functions that can be used
        :rtype: list
        """
        return get_activations()

    def swizzling_functors(self) -> list:
        """
        Returns possible swizzling functions that can be used

        :return: list of swizzling functions that can be used
        :rtype: list
        """
        return get_swizzling_functors()

    def _reset_options(self, cc: int):
        """
        Resets the kernel options based on cc

        :param cc: compute capability to reset to
        :type cc: int
        """
        if cc != self.current_cc:
            if cc not in _generator_ccs:
                raise Exception(f'Invalid CC for CUTLASS kernels: {cc}.')
            self.current_cc = cc
            self.options = option_registry.options_for_cc(self.current_cc)
