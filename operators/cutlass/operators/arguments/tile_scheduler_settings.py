# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

"""Values accepted by GEMM tile-scheduler performance controls.

The enums describe user intent independently of a particular operator. Operator
metadata decides whether each requested value is available and whether it is
bound at compile time or runtime.
"""

from enum import Enum


class TokenEnum(Enum):
    """A base class for enums that have string representations."""

    def __str__(self) -> str:
        # explicitly specify string behavior
        return self.value


class ReductionStrategy(TokenEnum):
    """Select how GEMM combines partial K-dimension results."""

    NO_REDUCTION = "no_reduction"
    """Does not use split with reduction over K dimension."""

    SPLIT_K = "split_k"
    """Split the K extent across CTAs and reduce their partials in global memory."""

    CLUSTER_SPLIT_K = "cluster_split_k"
    """Split the K extent within a cluster and reduce in distributed shared memory."""


class RasterizationStrategy(TokenEnum):
    """Select how the scheduler traverses output tiles."""

    NO_RASTERIZATION = "no_rasterization"
    """No change applied to the traversal order of output tiles."""

    TILE_SWIZZLE = "tile_swizzle"
    """Allow reordering of output tiles by swizzling and changing major axis of traversal."""


class RasterOrder(TokenEnum):
    """Select the major dimension used to traverse output tiles."""

    ALONG_M = "AlongM"
    """Set the rasterizated dimension to be the M dimension."""

    ALONG_N = "AlongN"
    """Set the rasterizated dimension to be the N dimension."""

    HEURISTIC = "Heuristic"
    """Let the scheduler pick the rasterized dimension."""
