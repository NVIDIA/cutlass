# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Pass a CUDA library handle (``cudaLibrary_t``) into a ``@cute.jit`` body
as a typed MLIR ``!cuda.library`` argument.

This is the bridge the in-trace symbol-store path needs:

* The user has a compiled kernel cubin (its loaded ``cudaLibrary_t`` is on
  ``compiled.library``).
* They want to store into a device global *inside* another ``@cute.jit`` body
  — emitting ``cuda.runtime.library.get_global`` + ``cuda.memory.copy``
  against ``target``.

Without this adapter ``cute.compile`` rejects the library handle because
it doesn't know how to marshal it through the ABI or what MLIR type to
use for the corresponding block argument.  The adapter mirrors the
existing ``CudaDialectStreamAdapter`` (``cuda.stream``) one-for-one — it
exposes ``getPtr()`` to the C ABI and ``!cuda.library`` to MLIR.
"""

from typing import List

import cuda.bindings.runtime as cuda_runtime

# MLIR imports
from .._mlir import ir
from .._mlir.dialects import cuda

# Local module imports
from ..base_dsl.runtime.cuda_handle_adapter import CudaHandleAdapter
from ..base_dsl.runtime.jit_arg_adapters import JitArgAdapterRegistry


@JitArgAdapterRegistry.register_jit_arg_adapter(
    cuda_runtime.cudaLibrary_t, scope=JitArgAdapterRegistry.CUDA_DIALECT_SCOPE
)
class CudaDialectLibraryAdapter(CudaHandleAdapter):
    """Convert a ``cudaLibrary_t`` into a ``!cuda.library`` JIT argument.

    Same shape as :class:`CudaDialectStreamAdapter` — the runtime handle
    is a void pointer; the MLIR type is the dialect's opaque
    ``!cuda.library``.  Lifetime is the caller's responsibility — we do
    not own the library, ``cuda.compile``/the user does.
    """

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [cuda.LibraryType.get()]
