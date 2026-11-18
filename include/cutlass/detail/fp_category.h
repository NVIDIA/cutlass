/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*!
    \file
    \brief Floating-point number categories, independent of the <cmath> FP_* macros.

    The category constants are a scoped enum, not the <cmath> FP_* object-like
    macros. Device translation units pull cuda::std's <cmath> in, where those
    macros are live and would clobber an enumerator named FP_NAN.

    This lives in its own header, under a filename no third-party bundled CUTLASS
    ships, so that `#include "cutlass/detail/fp_category.h"` always resolves to
    this tree rather than to an older copy earlier on the compiler include path.
*/

#pragma once

// Leaf header on purpose: it includes only helper_macros.hpp (for the cutlass
// namespace macro), never cutlass/platform/platform.h. platform.h includes
// cutlass/tfloat32.h, which includes this header, so pulling platform.h in here
// would form a cycle that leaves fp_category undefined when tfloat32.h is the
// translation unit's entry point.
#include <cutlass/detail/helper_macros.hpp>

namespace cutlass {

///////////////////////////////////////////////////////////////////////////////////////////////////

// All floating-point numbers can be put in one of these categories.
// A scoped enum rather than the <cmath> FP_* macros, which would be clobbered
// by any <cmath> already in the translation unit. Classifying a plain float is
// left to std::fpclassify, so this header declares no fpclassify(float) of its
// own to collide with the C library's on platforms where that is a function.
enum class fp_category {
  nan,
  infinite,
  zero,
  subnormal,
  normal
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

///////////////////////////////////////////////////////////////////////////////////////////////////
