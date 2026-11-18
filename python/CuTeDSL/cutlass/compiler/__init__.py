# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Public Python API for compiling and executing CUTLASS IR artifacts.

The artifact and compiler classes are the primary compilation workflow.  The
executor and metadata classes are advanced interfaces for runtime integration,
artifact inspection, and serialization.  ``__all__`` is the compatibility
contract for this module; internal nanobind implementation details are not part
of the public API.
"""

from .._mlir._mlir_libs._cutlass_ir import (
    # Artifact and compiler surfaces.
    ArtifactType,
    TargetKind,
    CompilationArtifact,
    PreCompiledMlirArtifact,
    CompiledMlirArtifact,
    LlvmIrArtifact,
    PtxArtifact,
    LtoIrArtifact,
    ObjectArtifact,
    Compiler,
    CuteCompiler,
    Executor,
    ExecutableFunction,
    # Metadata enums.
    Abi,
    DTypeCode,
    BindingTypeId,
    AddressSpace,
    # Metadata value types.
    FunctionMetadata,
    Binding,
    DType,
    DimSymbol,
    SymbolId,
    Dim,
    Var,
    Const,
    Shape,
    Tensor,
    Stream,
    EnvStream,
    Pointer,
    Unit,
    Tuple,
    CustomType,
    # Bound list classes returned by metadata container properties. Shape tree
    # nodes stay entirely internal: Shape accepts nested tuple/list values and
    # exposes value-semantic snapshots through .dims and .leaves.
    DimList,
    DimSymbolList,
    BindingList,
    FunctionMetadataList,
    # Serialization helpers.
    deserialize_compilation_artifact,
    serialize_compilation_artifact,
)

__all__ = [
    # Primary artifact and compiler workflow.
    "ArtifactType",
    "TargetKind",
    "CompilationArtifact",
    "PreCompiledMlirArtifact",
    "CompiledMlirArtifact",
    "LlvmIrArtifact",
    "PtxArtifact",
    "LtoIrArtifact",
    "ObjectArtifact",
    "Compiler",
    "CuteCompiler",
    # Advanced runtime integration.
    "Executor",
    "ExecutableFunction",
    # Metadata enums.
    "Abi",
    "DTypeCode",
    "BindingTypeId",
    "AddressSpace",
    # Metadata value types.
    "FunctionMetadata",
    "Binding",
    "DType",
    "DimSymbol",
    "SymbolId",
    "Dim",
    "Var",
    "Const",
    "Shape",
    "Tensor",
    "Stream",
    "EnvStream",
    "Pointer",
    "Unit",
    "Tuple",
    "CustomType",
    # Live list wrappers returned by metadata properties.
    "DimList",
    "DimSymbolList",
    "BindingList",
    "FunctionMetadataList",
    # Artifact serialization.
    "serialize_compilation_artifact",
    "deserialize_compilation_artifact",
]
