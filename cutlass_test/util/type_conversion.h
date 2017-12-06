/******************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#pragma once

/**
 * \file
 * \brief Utilities for converting between types and assessing traits
 */

#include "half.h"

namespace cutlass {

/******************************************************************************
 * Float conversion utilities
 ******************************************************************************/

/// Convert float to value type
template <typename value_t>
value_t from_float(float val)
{
    return value_t(val);
}

/// Convert float to value type (__half specialization)
template <>
__half from_float<__half>(float val)
{
    return half_t(val);
}


/******************************************************************************
 * Type conversion utilities
 ******************************************************************************/

/// Member \p type is defined as the signed integer type having the same size as \p T
template <typename T>
struct integer_alias;

template <>
struct integer_alias<int8_t> {
    using type = int8_t;
};

template <>
struct integer_alias<half_t> {
    using type = int16_t;
};

template <>
struct integer_alias<__half> {
    using type = int16_t;
};

template <>
struct integer_alias<float> {
    using type = int32_t;
};

template <>
struct integer_alias<int> {
    using type = int32_t;
};

template <>
struct integer_alias<double> {
    using type = int64_t;
};



/******************************************************************************
 * Type-info utilities
 ******************************************************************************/

/// Returns a string to prefix 'gemm' to construct CUBLAS-like kernel names
template <math_operation_class_t math_op, typename value_t, typename accum_t> char const *to_prefix_string();

template <> char const *to_prefix_string<math_operation_class_t::scalar, half_t, half_t>() {
    return "H";
}

template <> char const *to_prefix_string<math_operation_class_t::scalar, __half, __half>() {
    return "H";
}

template <> char const *to_prefix_string<math_operation_class_t::scalar, float, float>() {
    return "S";
}

template <> char const *to_prefix_string<math_operation_class_t::matrix, __half, __half>() {
    return "WmmaH";
}

template <> char const *to_prefix_string<math_operation_class_t::matrix, __half, float>() {
    return "WmmaS";
}

template <> char const *to_prefix_string<math_operation_class_t::scalar, double, double>() {
    return "D";
}

template <> char const *to_prefix_string<math_operation_class_t::scalar, int8_t, int32_t>() {
    return "I";
}


/******************************************************************************
 * Maps value_t to the minimum vector size used to load operand
 ******************************************************************************/

template <typename T>
struct operand_load_type;

template <>
struct operand_load_type<int8_t> { using type = int32_t; };

template <typename T>
struct operand_load_type { using type = T; };


/******************************************************************************
 * Minimum alignment requirement, if any, determined from value_t.
 ******************************************************************************/

template <typename value_t>
struct gemm_alignment_requirement;

template <>
struct gemm_alignment_requirement<uint8_t> { static const int value = 4; };

template <typename value_t>
struct gemm_alignment_requirement { static const int value = 0; };



} // namespace cutlass
