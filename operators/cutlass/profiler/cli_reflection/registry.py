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

"""Enumerates CLI Metadata categories and the choices of classes and fields for each.

Ex.
Category: design
Class: Sm100DesignMetadata
Field: cluster_shape

When creating a new Metadata class,
register it here for cutlass-profiler to automatically discover its fields.
"""

import types
from collections.abc import Sequence

import cutlass.operators as ops
from cutlass.operators import mma
from cutlass.operators.metadata import design

from .metadata import (
    MetadataCliCategory,
    MetadataCliClass,
)

DESIGN_REGISTRY: MetadataCliCategory = MetadataCliCategory(
    cli_category_name="--design",
    cli_category_help="Filters Operators by type(OperatorMetadata.design). If omitted, all designs are included.",
    argparse_dest_name="design",
    operator_metadata_attr="design",
    classes=[],
)
"""
Maps CLI Name to DesignMetadata class
Ex. --design blas -> BLASDesignMetadata
"""


def register_design(
    cli_name: str,
    cls: type[design.DesignMetadata],
    user_provided_modules: Sequence[types.ModuleType] = [mma],
) -> MetadataCliClass:
    """Register a design metadata class for profiler CLI filtering."""
    class_names = [cls.cli_name for cls in DESIGN_REGISTRY.classes]
    if cli_name in class_names:
        raise ValueError(f"design {cli_name} is already registered")

    metadata_class = MetadataCliClass.register(cli_name, cls, user_provided_modules)
    DESIGN_REGISTRY.register(metadata_class)
    return metadata_class


required_modules = [
    ops.arguments,
    ops.mma,
    ops.metadata.design.tile_scheduler,
]

_ = register_design("blas", design.BLASDesignMetadata, required_modules)
_ = register_design("sm100", design.Sm100DesignMetadata, required_modules)

CATEGORIES: tuple[MetadataCliCategory, ...] = (DESIGN_REGISTRY,)
