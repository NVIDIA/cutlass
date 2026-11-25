# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Work strategies that hand tiles to CTAs, each owning a distinct index space.

- :class:`ClcDynamicPersistentWorkStrategy`: persistent CTAs that consume CLC
  (cluster launch control) responses; work is identified in cluster-linear
  space derived from those responses.
- :class:`StaticPersistentWorkStrategy`: persistent CTAs that stride through
  cluster-linear space per wave (a fixed number of clusters per wave).
- :class:`GridWorkStrategy`: non-persistent launch over tile/grid space, with
  one tile assigned per CTA.
"""

from cutlass.kernels.utils.tile_scheduler.work_strategies.clc import (
    ClcDynamicPersistentWorkStrategy,
)
from cutlass.kernels.utils.tile_scheduler.work_strategies.grid import GridWorkStrategy
from cutlass.kernels.utils.tile_scheduler.work_strategies.static_persistent import (
    StaticPersistentWorkStrategy,
)

__all__ = [
    "ClcDynamicPersistentWorkStrategy",
    "GridWorkStrategy",
    "StaticPersistentWorkStrategy",
]
