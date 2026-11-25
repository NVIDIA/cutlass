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

"""CLI reflection: build argparse flags and metadata filter predicates from dataclasses.

Package structure:
  cli_builder.py    - Entry point for the creation of CLI arguments and Metadata Filter predicates.
  metadata.py       - MetadataCliCategory and cli class. Stores MetadataCliField's with additional binding information to CLI.
  command_line.py   - MetadataCliField as bridge between metadata and CLI.
  fields.py         - Walks dataclass type hints to produce MetadataCliField objects.
  registry.py       - Contains the different categories exposed by the CLI (e.g. design, operand)
                      and includes new dataclasses for CLI/metadata filtering.

Metadata Type Hierarchy:
    - MetadataCliCategory -> MetadataCliClass -> MetadataCliField
    - Category: DesignMetadata (design), OperandsMetadata (operand)
    - Class: Sm100DesignMetadata (sm100), BLASDesignMetadata (blas), GemmOperandsMetadata (gemm)
    - Field: use_2cta_mma, use_tma_store, cluster_shape

Typical usage:
  1. Register a metadata class via register_design() in registry.py.
  2. Call add_cli_arguments(parser, DESIGN_REGISTRY) when building your parser.
  3. After parsing, call is_metadata_filter_identity() / build_metadata_filter()
     to get a Callable[[OperatorMetadata], bool] for get_operators().
"""

from .cli_builder import (
    add_cli_arguments,
    build_metadata_filter,
    is_metadata_filter_identity,
)
from .command_line import MetadataCliField
from .metadata import MetadataCliCategory, MetadataCliClass
from .registry import CATEGORIES, DESIGN_REGISTRY, register_design

__all__ = [
    "add_cli_arguments",
    "build_metadata_filter",
    "is_metadata_filter_identity",
    "MetadataCliCategory",
    "MetadataCliClass",
    "MetadataCliField",
    "CATEGORIES",
    "DESIGN_REGISTRY",
    "register_design",
]
