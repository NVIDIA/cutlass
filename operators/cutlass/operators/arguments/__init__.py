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


from cutlass.operators.config import GlobalOptions

from .base import (
    Operand,
    PerformanceControls,
    RuntimeArguments,
)
from .data_driven_sync import (
    DataDrivenSyncConsumer,
    DataDrivenSyncControls,
    DataDrivenSyncProducer,
)
from .epilogue import (
    EpilogueArguments,
    EpilogueArgumentsBase,
    Load,
    PerGroupScaleEpilogueArguments,
    Store,
    Transport,
)
from .gemm import GemmArguments, GemmProblemSize
from .grouped_gemm import (
    GroupedGemmArguments,
    IndexPtrGroupedGemmArguments,
    IndexPtrGroupedGemmProblemSize,
)
from .operand import (
    DenseTensor,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from .pdl import (
    EarlyLaunchDependent,
    EarlyStart,
    PDLProgrammaticEvent,
    ProgrammaticDependentLaunchControl,
)
from .performance import GemmPerformanceControls, TileSchedulerControls
from .tile_scheduler_settings import (
    RasterizationStrategy,
    RasterOrder,
    ReductionStrategy,
)

__all__ = [
    # Top-level arguments & constituents
    "RuntimeArguments",
    "PerformanceControls",
    "GemmPerformanceControls",
    "TileSchedulerControls",
    "ReductionStrategy",
    "RasterizationStrategy",
    "RasterOrder",
    "EpilogueArgumentsBase",
    "EpilogueArguments",
    "PerGroupScaleEpilogueArguments",
    # Various RuntimeArguments subtypes
    "GemmArguments",
    "GemmProblemSize",
    "GroupedGemmArguments",
    "IndexPtrGroupedGemmArguments",
    "IndexPtrGroupedGemmProblemSize",
    # Operands & related classes
    "Operand",
    "DenseTensor",
    "ScaledOperand",
    "ScaleMode",
    "ScaleSwizzleMode",
    "Load",
    "Store",
    "Transport",
    # PDL
    "ProgrammaticDependentLaunchControl",
    "EarlyLaunchDependent",
    "EarlyStart",
    "PDLProgrammaticEvent",
    # Data-driven synchronization
    "DataDrivenSyncControls",
    "DataDrivenSyncProducer",
    "DataDrivenSyncConsumer",
]

