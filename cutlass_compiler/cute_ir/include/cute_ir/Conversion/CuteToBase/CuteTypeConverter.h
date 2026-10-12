// clang-format off
/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
// clang-format on

//===----------------------------------------------------------------------===//
//

// Public type-converter configuration helper for the cute-to-base pass.

//===----------------------------------------------------------------------===//

#ifndef CUTE_IR_CONVERSION_CUTE_TO_BASE_CUTE_TYPE_CONVERTER_H
#define CUTE_IR_CONVERSION_CUTE_TO_BASE_CUTE_TYPE_CONVERTER_H

namespace mlir {
class TypeConverter;

namespace cutlass_compiler::cute {

/// Configures @p converter to map each cute type to its LLVM struct lowering.
/// Idempotent — safe to call multiple times.
///
/// Conversions installed:
///   - shape / stride / int_tuple / coord / tile → LLVM struct of dynamic
///     integer leaves (sparse_flat layout).
///   - layout → LLVM struct(shape_struct, stride_struct).
///   - composed_layout → LLVM struct(inner_struct, offset_struct,
///     outer_struct).
///   - swizzle → empty LLVM struct (compile-time-only).
///
/// The caller is responsible for adding source / target materializers if
/// boundary unrealized_conversion_cast ops are needed.
void configCuteToBaseTypeConverter(TypeConverter &converter);

} // namespace cutlass_compiler::cute
} // namespace mlir

#endif // CUTE_IR_CONVERSION_CUTE_TO_BASE_CUTE_TYPE_CONVERTER_H
