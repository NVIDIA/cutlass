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

#if !defined(CUTEGEN_LITERALS_HPP_INCLUDED_)
#define CUTEGEN_LITERALS_HPP_INCLUDED_

// This file must be included AFTER a file that defines types for int_tuple,
// coord, shape, stride, and layout, based on a specific dynamic value type.

namespace cutegen
{

inline auto operator""_tup(const char* lit, size_t)
{
    return cutegen::from_string<cutegen::int_tuple>(std::string(lit)).value();
}

inline auto operator""_crd(const char* lit, size_t)
{
    return cutegen::from_string<cutegen::coord>(std::string(lit)).value();
}

inline auto operator""_shp(const char* lit, size_t)
{
    return cutegen::from_string<cutegen::shape>(std::string(lit)).value();
}

inline auto operator""_str(const char* lit, size_t)
{
    return cutegen::from_string<cutegen::stride>(std::string(lit)).value();
}

inline auto operator""_lay(const char* lit, size_t)
{
    return cutegen::from_string<cutegen::layout>(std::string(lit)).value();
}

} // namespace cutegen

#endif // CUTEGEN_LITERALS_HPP_INCLUDED_
