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

set(LLVM_TARGET_DEFINITIONS CuteDialect.td)
mlir_tablegen(CuteDialect.h.inc   -gen-dialect-decls -dialect=cute)
mlir_tablegen(CuteDialect.cpp.inc -gen-dialect-defs  -dialect=cute)
add_public_tablegen_target(MLIRCuteDialectIncGen)

set(LLVM_TARGET_DEFINITIONS CuteTypeInterfaces.td)
mlir_tablegen(CuteTypeInterfaces.h.inc   -gen-type-interface-decls)
mlir_tablegen(CuteTypeInterfaces.cpp.inc -gen-type-interface-defs)
add_public_tablegen_target(MLIRCuteTypeInterfacesIncGen)

set(LLVM_TARGET_DEFINITIONS CuteTypes.td)
mlir_tablegen(CuteTypes.h.inc   -gen-typedef-decls -typedefs-dialect=cute)
mlir_tablegen(CuteTypes.cpp.inc -gen-typedef-defs  -typedefs-dialect=cute)
add_public_tablegen_target(MLIRCuteTypesIncGen)

set(LLVM_TARGET_DEFINITIONS CuteAttrs.td)
mlir_tablegen(CuteAttrs.h.inc   -gen-attrdef-decls -attrdefs-dialect=cute)
mlir_tablegen(CuteAttrs.cpp.inc -gen-attrdef-defs  -attrdefs-dialect=cute)
add_public_tablegen_target(MLIRCuteAttrsIncGen)

set(LLVM_TARGET_DEFINITIONS CuteOps.td)
mlir_tablegen(CuteOps.h.inc   -gen-op-decls)
mlir_tablegen(CuteOps.cpp.inc -gen-op-defs)
add_public_tablegen_target(MLIRCuteOpsIncGen)
