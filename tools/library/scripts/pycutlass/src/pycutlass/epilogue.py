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

import struct


def MaxAlignment(fmt):
    align = 1
    for x in fmt:
        align = max(align, struct.calcsize(x))
    return align


def AlignedOffset(offset, align):
    remainder = (offset % align)
    if remainder:
        offset += (align - remainder)
    return offset

#################################################################################################
#
# Functors
#
#################################################################################################

#


class Functor:
    def __init__(self):
        self.decl = ''
        self.definition = ''
        self.fmt = ''
        self.identifier = ''

    #
    def emit_declaration(self):
        return self.decl

    #
    def emit_definition(self):
        return self.definition

    #
    def size(self):
        '''
        Size of the packed Params structure
        '''
        return struct.calcsize(self.fmt)

    #
    def alignment(self):
        return MaxAlignment(self.fmt)

    #
    def initialize(self, host_workspace, offset, arguments):
        return offset + self.size()

#################################################################################################

#


class LinearCombinationFunctorArguments:
    def __init__(self, alpha=1.0, beta=0.0):
        self.alpha = alpha
        self.beta = beta
        self.alpha_ptr = 0
        self.beta_ptr = 0

#


class LinearCombinationFunctor(Functor):
    def __init__(self):
        super().__init__()

        self.decl = """
    cutlass::epilogue::thread::LinearCombination<
      float,
      1,
      float,
      float
    >"""
        self.identifier = 'linear_combination'
        self.fmt = "ffPP"

    #
    def size(self):
        '''
        Size of the packed Params structure
        '''
        return struct.calcsize(self.fmt)

    #
    def alignment(self):
        return MaxAlignment(self.fmt)

    #
    def initialize(self, host_workspace, offset, arguments):

        offset = AlignedOffset(offset, self.alignment())

        struct.pack_into(
            self.fmt,
            host_workspace, offset,
            arguments.alpha, arguments.beta, arguments.alpha_ptr, arguments.beta_ptr)

        return offset + self.size()
