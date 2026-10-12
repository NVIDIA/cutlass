#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
SM107 UMMA instruction shapes for dense and blockscaled F8/F6/F4 GEMMs.

Shape format: (M, N, K)
  1SM tiles: M=128, K=64
  2SM tiles: M=256, K=64

Dict values are the minimum tcgen05 instantiation level required to include
a shape (0 = always included at the default level).
"""

# F8F6F4 dense 1SM: M=128, K=64, N multiples of 16
SM107_MMA_SHAPES_F8F6F4_DENSE_1SM = {
    (128,  16, 64): 4,
    (128,  32, 64): 3,
    (128,  48, 64): 5,
    (128,  64, 64): 2,
    (128,  80, 64): 5,
    (128,  96, 64): 5,
    (128, 112, 64): 5,
    (128, 128, 64): 0,
    (128, 144, 64): 5,
    (128, 160, 64): 5,
    (128, 176, 64): 5,
    (128, 192, 64): 5,
    (128, 208, 64): 5,
    (128, 224, 64): 5,
    (128, 240, 64): 5,
    (128, 256, 64): 0,
}

# F8F6F4 dense 2SM: M=256, K=64, N multiples of 32
SM107_MMA_SHAPES_F8F6F4_DENSE_2SM = {
    (256,  32, 64): 2,
    (256,  64, 64): 2,
    (256,  96, 64): 5,
    (256, 128, 64): 0,
    (256, 160, 64): 5,
    (256, 192, 64): 5,
    (256, 224, 64): 5,
    (256, 256, 64): 0,
}

# MXF8F6F4 blockscaled 1SM:
SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_1SM = {
    (128,  64, 64): 0,
    (128, 128, 64): 0,
    (128, 192, 64): 0,
    (128, 256, 64): 0,
}

# MXF8F6F4 blockscaled 2SM:
SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_2SM = {
    (256,  64, 64): 0,
    (256, 128, 64): 0,
    (256, 192, 64): 0,
    (256, 256, 64): 0,
}

# MXNVF4 blockscaled 1SM: M=128, K=128 (fp4 doubles the K instruction depth vs f8). Shared by
# both vector sizes (16 and 32) -- they instantiate the same instruction shapes.
SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_1SM = {
    (128,  64, 128): 0,
    (128, 128, 128): 0,
    (128, 192, 128): 0,
    (128, 256, 128): 0,
}

# MXNVF4 blockscaled 2SM: M=256, K=128. Shared by both vector sizes (16 and 32).
SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_2SM = {
    (256,  64, 128): 0,
    (256, 128, 128): 0,
    (256, 192, 128): 0,
    (256, 256, 128): 0,
}
