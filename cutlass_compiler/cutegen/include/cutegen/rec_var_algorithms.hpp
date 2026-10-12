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

/**
 * @file
 */

#if !defined(CUTEGEN_REC_VAR_ALGORITHMS_HPP_INCLUDED_)
#define CUTEGEN_REC_VAR_ALGORITHMS_HPP_INCLUDED_

#include <cassert>
#include <numeric>
#include <cstdlib>
#include <tuple>
#include <type_traits>
#include <variant>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/ratio.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/underscore.hpp"

#if defined(_WIN32)
#define ENABLE_INTSAFE_SIGNED_FUNCTIONS
#include <intsafe.h>
#endif

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// rec_var_algorithms.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//
// Scalar ops
//

/**
 * @brief Add a pair of scalar values (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding the sum of lhs and rhs (or error)
 *
 * The return type is typically a variant or recursive variant, and must be
 * capable of holding any values that can result from the sum operation on
 * values held by the two inputs.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_add(const TA& lhs, const TB& rhs);

/**
 * @brief Subtract a pair of scalar values (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding lhs minus rhs (or error)
 *
 * The return type is typically a variant or recursive variant, and must be
 * capable of holding any values that can result from the subtract operation on
 * values held by the two inputs.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_sub(const TA& lhs, const TB& rhs);

/**
 * @brief Multiply a pair of scalar values (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding lhs * rhs (or error)
 *
 * The return type is typically a variant or recursive variant, and must be
 * capable of holding any values that can result from a product operation on the
 * values held by the two inputs.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_mul(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate lhs modulo rhs (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding lhs % rhs (or error)
 *
 * The return type is typicall a variant or recursive variant, and must be
 * capable of holding any values that can result from a modulo operation on the
 * values held by the two inputs.
 *
 * Note that if `rhs` is a statically known value of 0, the return value will
 * hold an instance of `cg_error_t`.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_mod(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate lhs / rhs (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding lhs / rhs (or error)
 *
 * The return type is typically a variant or recursive variant, and must be
 * capable of holding any values that can result from a division operation on
 * the values held by the two inputs.
 *
 * Note that if `rhs` is a statically known value of 0, the return value will
 * hold an instance of `cg_error_t`.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_div(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate ceil_div(lhs, rhs) (or emit code to do so)
 *
 * @tparam TRecVarRet Type of return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding ceildiv(lhs, rhs) (or error)
 *
 * The return type is typically a variant or recursive variant, and must be
 * capable of holding any values that can result from a ceildiv() operation on
 * the values held by the two inputs.
 *
 * Note that if `rhs` is a statically known value of 0, the return value will
 * hold an instance of `cg_error_t`.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          bool forceUnsigned = false,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_ceil_div(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate a pair of values: `lhs / rhs` and `lhs % rhs` (or emit code
 *        to do so)
 *
 * @tparam TRecVarQ Type of quotient return value
 * @tparam TRecVarR Type of remainder return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return std::pair<TRecVarQ, TRecVarR> Value holding `lhs / rhs` and `lhs % rhs` (or error)
 *
 * The return types `TRecVarQ` and `TRecVarR` are typically variants or
 * recursive variant, and must be capable of holding any values that can result
 * from the division and modulo operations on the values held by the two inputs.
 *
 * Note that if `rhs` is a statically known value of 0, both return values will
 * hold an instance of `cg_error_t`.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarQ,
          class TRecVarR,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
std::pair<TRecVarQ, TRecVarR> scalar_divmod(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate the minimum of a pair of values (or emit code to do so)
 *
 * @tparam TRecVarRet Type of result/return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding `min(lhs, rhs)`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the min operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_min(const TA& lhs, const TB& rhs);

/**
 * @brief Calculate the maximum of a pair of values (or emit code to do so)
 *
 * @tparam TRecVarRet Type of result/return value
 * @tparam TA Type of the first operand (lhs)
 * @tparam TB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TRecVarRet Value holding `min(lhs, rhs)`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the min operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool> = true>
TRecVarRet scalar_max(const TA& lhs, const TB& rhs);
template <class TRecVarRet,
          class TA,
          class TInt,
          std::enable_if_t<is_visitable<TA>::value, bool>  = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRecVarRet scalar_max(const TA& lhs, TInt rhs);
template <class TRecVarRet,
          class TInt,
          class TB,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true,
          std::enable_if_t<is_visitable<TB>::value, bool>  = true>
TRecVarRet scalar_max(TInt lhs, const TB& rhs);

/**
 * @brief Calculate the absolute value (or emit code to do so)
 *
 * @tparam TRecVar Type of input and result/return value
 * @return TRecVar Value holding `abs(v)`
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * the input value holds a dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar scalar_abs(const TRecVar& v);

/**
 * @brief Calculate the bitwise and of a pair of values (or emit code to do so)
 *
 * @tparam TResult Type of result/return value
 * @tparam TRecVarA Type of the first operand (lhs)
 * @tparam TRecVarB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TResult Value holding `lhs & rhs`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the bitwise and operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool> = true>
TResult scalar_bitwise_and(const TRecVarA& lhs, const TRecVarB& rhs);
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true>
TResult scalar_bitwise_and(const TRecVar& lhs, TInt rhs);
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true>
TResult scalar_bitwise_and(TInt lhs, const TRecVar& rhs);

/**
 * @brief Calculate the bitwise or of a pair of values (or emit code to do so)
 *
 * @tparam TResult Type of result/return value
 * @tparam TRecVarA Type of the first operand (lhs)
 * @tparam TRecVarB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TResult Value holding `lhs | rhs`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the bitwise or operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool> = true>
TResult scalar_bitwise_or(const TRecVarA& lhs, const TRecVarB& rhs);
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true>
TResult scalar_bitwise_or(const TRecVar& lhs, TInt rhs);
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true>
TResult scalar_bitwise_or(TInt lhs, const TRecVar& rhs);

/**
 * @brief Calculate the bitwise xor of a pair of values (or emit code to do so)
 *
 * @tparam TResult Type of result/return value
 * @tparam TRecVarA Type of the first operand (lhs)
 * @tparam TRecVarB Type of the second operand (rhs)
 * @param lhs Input value (visitable, variant or recursive variant)
 * @param rhs Input value (visitable, variant or recursive variant)
 * @return TResult Value holding `lhs ^ rhs`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the bitwise xor operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool> = true>
TResult scalar_bitwise_xor(const TRecVarA& lhs, const TRecVarB& rhs);
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true>
TResult scalar_bitwise_xor(const TRecVar& lhs, TInt rhs);
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool> = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>  = true>
TResult scalar_bitwise_xor(TInt lhs, const TRecVar& rhs);

/**
 * @brief Calculate the bitwise not of a value (or emit code to do so)
 *
 * @tparam TResult Type of result/return value
 * @tparam T Type of the operand
 * @param lhs Input value (visitable, variant or recursive variant)
 * @return TResult Value holding `~value`
 *
 * The return type `TRecVarRet` is typically a variant or recursive variant,
 * and must be capable of holding the result of the bitwise not operation.
 *
 * Code will be emitted if the result cannot be statically determined, and if
 * input values hold dynamic values with context data structures that are
 * initialized to emit operations.
 */
template <class TResult,
          class T,
          std::enable_if_t<is_visitable<T>::value, bool> = true>
TResult scalar_bitwise_not(const T& value);

template <class TResult,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TResult scalar_lshr(const TRecVar& lhs, int32_t rhs);

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar scalar_shl(const TRecVar& lhs, int32_t rhs);

//
// General recursive variant functions
//

/**
 * @brief Cast from one recursive variant type to another (with type conversion).
 *
 * Return a copy of the given recursive variant, with a recursive variant type
 * that may be different than the input. Values of types that are also present
 * in the output recursive variant are copied unmodified, whereas values of
 * types that are NOT present in the output recursive variant are passed to a
 * type converter. Currently, the type converter used is the default: values
 * of types not represented in the output are converted to cg_error_t.
 *
 * The source type TSrc must be supported by the cutegen::visit() function (i.e.
 * it must be either a recursive variant or a std::variant).
 *
 * @see rec_var_cast_type_converter_error
 */
template <class TRecVarDst, class TSrc>
TRecVarDst rec_var_cast(const TSrc& rhs);

/**
 * @brief Cast from one variant type to another replacing dynamic values with
 *        values of the base dynamic_t type.
 *
 * Return a copy of the given variant/recursive variant, with a variant type
 * that may be different than the input. Values of types that are also present
 * in the output recursive variant are copied unmodified, whereas values that
 * have a type derived from dynamic_t will be converted to the base dynamic_t
 * type.
 *
 * Note: Currently only scalars derived from dynamic_t are supported for
 * conversion. Aggregate types that may contain a dynamic value (e.g. scaled
 * basis) are currently not supported, and a compile error will result.
 *
 * The source type TSrc must be supported by the cutegen::visit() function (i.e.
 * it must be either a recursive variant or a std::variant).
 *
 */
template <class TDst, class TSrc>
TDst cast_to_base_dynamic(const TSrc& rhs);

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_sum(const TRecVarA& lhs, const TRecVarB& rhs);

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_sub(const TRecVarA& lhs, const TRecVarB& rhs);

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_mul(const TRecVarA& lhs, const TRecVarB& rhs);

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_div(const TRecVarA& lhs, const TRecVarB& rhs);

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_mod(const TRecVarA& lhs, const TRecVarB& rhs);

/**
 * @brief Checks whether a value is static.
 *
 * A value is static if and only if it does not contain any dynamic information (i.e.
 * values that are not known at code generation time). The check is recursive - leaf
 * values of recursive variants are also checked, and aggregate types (e.g. layouts
 * and scaled bases) are also inspected for the presence of dynamic values.
 *
 * @see has_dynamic()
 * @see scaled_basis_t
 */
template <class T>
bool is_static(const T& t);

template <class... T>
bool all_are_static(const T&... t);

template <class T>
auto scalar_count(const T& t, bool bDynamicOnly = false);

// Keeps only the elements of tuple B that are paired with an underscore.
template <class A, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar slice(const A& a, const TRecVar& b);

// Keeps only the elements of tuple B that are paired with an int.
template <class A, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar dice(const A& a, const TRecVar& b);

/// Returns the product of all "leaf" recursive variant elements.
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto product(const TRecVar& rv);

/**
 * @brief Applies product() to each recursive variant element and returns the resulting depth-1
 *        recursive variant.
 *
 * If @p rv does not hold a vector, the function returns a copy of @p rv. Otherwise, it applies
 * product() to each recursive variant element and returns a depth-1 recursive variant.
 *
 * @see product()
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto product_each(const TRecVar& rv);

/**
 * @brief Returns the exclusive prefix product with output congruent to the input
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto prefix_product(const TRecVar& rv, const TRecVar& init = 1);

/// Returns the sum of all "leaf" recursive variant elements.
template <class TRecVar>
auto sum(const TRecVar& rv);

/// Returns the maximum "leaf" element value.
template <class TRecVar>
auto max(const TRecVar& rv);

/// Returns the minimum "leaf" element value.
template <class TRecVar>
auto min(const TRecVar& rv);

// Return a tuple the same profile as A scaled by corresponding elements in B
template <class TRecVarA, class TRecVarB>
TRecVarA scalar_scale(const TRecVarA& a, const TRecVarB& b);

template <class TRVRet, class TRV0, class TRV1>
TRVRet inner_product(const TRV0& t0, const TRV1& t1, const bool follow_profile = false);

template <class TShapeA, class TShapeB>
TShapeA shape_div(const TShapeA& a, const TShapeB& b);

/**
 * @brief Performs a generalized ceil division for recursive variants (IntTuples).
 *
 * This function recurisvely calls itself until one of the following base cases is reached:
 *
 * 1. scalar/scalar
 * 2. scalar/tuple which fowards to (1) by taking the product of the tiler
 */
template <class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_rec_var<TRecVarA>::value, bool> = true,
          std::enable_if_t<is_rec_var<TRecVarB>::value, bool> = true>
TRecVarA ceil_div(const TRecVarA& target, const TRecVarB& tiler);

/**
 * @brief Minimum of two scalar CuTe shapes.
 *
 * @pre @p a and @p b are scalars
 */
template <class TShapeA, class TShapeB>
TShapeA shape_min(const TShapeA& a, const TShapeB& b);

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto size(const TRecVar& rv);

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto size(const TRecVar& rv, size_t idx);

/**
 * @brief Returns the statically-known size of a recursive variant that only has integral elements.
 *
 * The size of such recursive variant is the product of all integral elements.
 *
 * @pre @p rv only has integral elements
 */
template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
typename TRecVar::int_t static_size(const TRecVar& rv);

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
auto static_size(const TRecVar& rv, size_t idx);

/**
 * @brief permute values according to the order. Container's element is
 * index.
 */
template <typename TRecVar, typename TContainer>
auto permute(const TRecVar& rv, const TContainer& order);

/**
 * @brief find greatest common divisor of modes in a tuple
 *
 * @tparam RecVar
 * @param a       input tuple (can be recursive)
 * @return RecVar::int_t
 */
template <class TRecVar>
typename TRecVar::int_t gcd(const TRecVar& a);

/**
 * @brief Check whether an equality check for a pair of CuTe algebra values
 * can be folded
 *
 * Checking for equality at code generation time can yield one of 3 results:
 * - the algebraic types are statically known, without dynamic types, and
 *   all elements are equal
 * - the algebraic types are known to be unequal - either because the
 *   profiles do not match, or because individual elements do not match
 * - one or both of the algebraic values has dynamic values, and equality
 *   cannot be determined until the dynamic values are populated at runtime.
 * For the first two cases, the equality comparison can be "folded" to a
 * boolean value. For the third case, code must be generated to determine
 * equality at runtime.
 * This function returns a std::optional<bool>, where the boolean value is
 * true (equal) or false (unequal) if the equality comparison can be folded.
 * Otherwise, the return value is std::nullopt, and the comparison cannot be
 * folded.
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
std::optional<bool> eq_op_can_fold(const TRecVar& lhs, const TRecVar& rhs);

/**
 * `@brief` Builds a stride congruent to `tup` with scaled basis stride elements.
 *
 * Given a recursive variant representing a shape or tile, constructs a stride with
 * scaled_basis_t elements that encode the hierarchical position of each mode.
 *
 * `@tparam` TStride The stride type to construct (must contain a scaled_basis_t variant)
 * `@tparam` TTuple  The input tuple type (typically a shape)
 * `@param` tup The input shape/tuple whose structure is mirrored
 * `@return` A stride with scaled basis elements encoding mode positions
 */
template <class TStride,
          class TTuple,
          std::enable_if_t<is_rec_var<TTuple>::value, bool> = true>
auto make_basis_like(const TTuple& tup);

/**
 * @brief Returns a copy of the input recursive variant, but with state used to
 *        perform code generation cleared.
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar without_codegen(const TRecVar& rv);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// rec_var_algorithms.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
#if defined(_WIN32)

inline bool mul_overflow(int32_t a, int32_t b, int32_t* presult)
{
    return FAILED(Int32Mult(a, b, presult));
}

inline bool mul_overflow(int64_t a, int64_t b, int64_t* presult)
{
    return FAILED(Int64Mult(a, b, presult));
}

inline bool add_overflow(int32_t a, int32_t b, int32_t* presult)
{
    return FAILED(Int32Add(a, b, presult));
}

inline bool add_overflow(int64_t a, int64_t b, int64_t* presult)
{
    return FAILED(Int64Add(a, b, presult));
}

inline bool sub_overflow(int32_t a, int32_t b, int32_t* presult)
{
    return FAILED(Int32Sub(a, b, presult));
}

inline bool sub_overflow(int64_t a, int64_t b, int64_t* presult)
{
    return FAILED(Int64Sub(a, b, presult));
}

#else // defined(_WIN32)

template <typename T>
bool mul_overflow(T a, T b, T* presult)
{
    return __builtin_mul_overflow(a, b, presult);
}
template <typename T>
bool add_overflow(T a, T b, T* presult)
{
    return __builtin_add_overflow(a, b, presult);
}
template <typename T>
bool sub_overflow(T a, T b, T* presult)
{
    return __builtin_sub_overflow(a, b, presult);
}

#endif // defined(_WIN32)

//
// Swizzle
//

template <class TRecVar>
struct swizzle_visitor
{
private:
    const swizzle& sw;

public:
    swizzle_visitor(const swizzle& sw_) :
        sw(sw_) {}
    template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
    TRecVar operator()(const T& a) { return sw(a); }
    TRecVar operator()(const std::vector<TRecVar>& /*a*/) { return cg_error_t{}; }
    TRecVar operator()(const cg_error_t& /*a*/) { return cg_error_t{}; }
    template <class TDynamic, std::enable_if_t<type_can_hold_dynamic_int<TDynamic>::value, bool> = true>
    TRecVar operator()(const TDynamic& d) { return sw(d); }
};

//
// Recursive variant cast
//

/**
 * @brief Convert a type to the cutegen error type.
 *
 * Type conversion structure used for casting recursive variants with
 * different variant types. The type converter class is used when the source
 * variant type does not exist as a valid type for the destination variant.
 * This converter returns the cutegen error type for all values with types
 * that don't exist in the destination variant.
 *
 * @see rec_var_cast_op
 */
struct rec_var_cast_type_converter_error
{
    template <class T>
    auto operator()(const T& /*rhs*/)
    {
        return cutegen::cg_error_t{};
    }
};

/**
 * @brief Convert a dynamic type to the dynamic_t base class type.
 *
 * Type conversion structure used for casting recursive variants with
 * different variant types. The type converter class is used when the source
 * variant type does not exist as a valid type for the destination variant.
 * This converter "slices" the derived class that inherits from dynamic_t
 * into a dynamic_t. Use of this converter requires:
 * - that the only difference between the source and destination variants
 *   is that the dynamic type differs
 * - that the destination type can hold dynamic_t
 *
 * @see rec_var_cast_op
 */
struct rec_var_cast_type_converter_slice_dynamic
{
    template <class T>
    auto operator()(const T& dyn)
    {
        static_assert(has_dynamic_t_base<T>::value);
        return dynamic_t(dyn);
    }
};

/**
 * @brief Callable object used for casting to disparate variant types.
 *
 * An alternative approach would be to use is_constructible<> instead of
 * matching types directly.
 *
 * @tparam TRecVarDst destination variant type
 * @tparam TDstElemTypes destination element types
 * @tparam TTypeConverter class to convert types that don't exist in the
 *         destination variant
 *
 * @see rec_var_cast
 */
template <class TRecVarDst,
          class TDstElemTypes,
          class TTypeConverter = rec_var_cast_type_converter_error>
class rec_var_cast_op
{
public:
    using dst_types_t      = TDstElemTypes;
    using type_converter_t = TTypeConverter;

    rec_var_cast_op(type_converter_t tc = type_converter_t{}) :
        converter_(tc)
    {}

    template <class TRecVarSrc>
    TRecVarDst cast_visit(const TRecVarSrc& rhs)
    {
        return visit(*this, rhs);
    }
    // Copy for the recursive variant vector type. Note that this function must
    // be "more specialized" than the overload for types that DO NOT exist in
    // the destination variant, as the destination variant will never have the
    // same vector type as the source (unless they are identical, in which case
    // we avoid using this visitor entirely).
    // https://en.cppreference.com/w/cpp/language/function_template#Function_template_overloading
    template <class T>
    TRecVarDst operator()(const std::vector<T>& rhs)
    {
        typename TRecVarDst::vector_t v;
        for(auto& e : rhs)
        {
            v.push_back(cast_visit(e));
        }
        return v;
    }
    // Copy for types that exist in the destination recursive variant.
    template <class T,
              std::enable_if_t<detail::tuple_has_type<dst_types_t, T>::value, bool> = true>
    TRecVarDst operator()(const T& rhs)
    {
        return rhs;
    }
    // Copy for types that DO NOT exist in the destination recursive variant.
    // Here we invoke the type converter to determine the value that is
    // returned.
    template <class T,
              std::enable_if_t<!detail::tuple_has_type<dst_types_t, T>::value, bool> = true>
    TRecVarDst operator()(const T& rhs)
    {
        return converter_(rhs);
    }

private:
    type_converter_t converter_;
};

//
// Scalar ops
//

/**
 * Definitions of structs for scalar visit-based type dispatch
 *
 * Several structs for seamless type-dispatch with recursive variants are defined below:
 * 1. scalar_xxx_op_static not supporting any dynamic value type
 * 2. declaration of scalar_xxx_op with an additional template parameter for the actual dynamic
 *    value type
 * 3. partial specialization of scalar_xxx_op for the base dynamic_t. The base dynamic_t tracks no
 *    state for individual instances and thus can only be used to track the propagation of dynamic
 *    values.
 *
 * Other partial specializations for other dynamic value type (e.g. mlir_dynamic_t) are
 * defined in backend-specific headers (e.g. cutegen_mlir.hpp).
 *
 * In addition, scalar_xxx functions are defined to wrap the visit-based dispatch. They
 * automatically use the right struct (static or actual specialization) based on the actual
 * dynamic value type that the input recursive variants can hold. As the name suggests, it is
 * illegal to call these functions on vector recursive variant elements.
 *
 * When the return type is a recursive variant type, we return cg_error_t{} for invalid cases.
 * When the return type is something else, we assert(false) for invalid cases.
 */

template <class Ret, class... Ts>
struct transform_non_error
{
    template <typename Fn>
    transform_non_error(Fn f) :
        transform_(f) {}

    Ret operator()(const cg_error_t&) { return cg_error_t{}; }
    template <typename T>
    Ret operator()(const T& t) { return transform_(t); }

private:
    std::function<Ret(const std::variant<Ts...>&)> transform_;
};

template <class TRet>
struct scalar_add_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;
        if(!in_range<int_t>(lhs) || !in_range<int_t>(rhs)) return cg_error_t{};
        int_t res;
        bool  overflows = detail::add_overflow(static_cast<int_t>(lhs), static_cast<int_t>(rhs), &res);
        if(overflows) return cg_error_t{};
        return res;
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(underscore_t, const TR&) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const ratio& a, const TR& b)
    {
        return scalar_add<TRet>(a, b);
    }
    template <class TR, class... TValueTypes, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(underscore_t /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const ratio& /*lhs*/, const std::vector<TVec>& /*lhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(underscore_t, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a ratio
    //
    TRet operator()(const ratio& a, const ratio& b)
    {
        return scalar_add<TRet>(a, b);
    }
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& a, const ratio& b)
    {
        return scalar_add<TRet>(a, b);
    }
    TRet operator()(underscore_t, const ratio& b) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is scaled basis
    //
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        if(lhs.modes() == rhs.modes())
        {
            using sb_variant_t = typename scaled_basis_t<TValueTypes..., cg_error_t>::value_variant_t;
            scalar_add_visitor<sb_variant_t> add_value;
            auto                             v = std::visit(add_value, lhs.value(), rhs.value());
            return std::visit(detail::transform_non_error<TRet, TValueTypes...>([&lhs](const auto& sbv) { return scaled_basis_t<TValueTypes...>(lhs.modes(), sbv); }), v);
        }
        else
        {
            return cg_error_t{};
        }
    }
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true, class... TValueTypes>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(underscore_t /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const ratio& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        if(rhs == 0) return lhs;
        return scalar_add<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        if(lhs == 0) return rhs;
        return scalar_add<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_add<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(underscore_t /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*rhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const ratio& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
};

template <class TRecVar,
          class TScaledBasis,
          std::enable_if_t<is_rec_var_with_type_pred<TRecVar, std::is_integral>::value, bool> = true>
TRecVar scaled_basis_to_rec_var(const TScaledBasis& sb)
{
    if constexpr(TScaledBasis::can_have_dynamic_value)
    {
        using value_types_t = typename TScaledBasis::value_types_t;
        // Make sure that TRecVar can hold a dynamic type and that it is actually the same as
        // the one in the scaled basis value's variant type list
        static_assert(rec_var_has_dynamic_type<TRecVar>::value);
        static_assert(
            std::is_same_v<typename find_dynamic_in_rec_var<TRecVar>::value,
                           typename detail::find_in_tuple<value_types_t, has_dynamic_t_base>::value>);
    }
    using vector_t = typename TRecVar::vector_t;
    using int_t    = typename TRecVar::int_t;

    TRecVar   res;
    vector_t* p = &get_vector(res);
    for(auto it = sb.modes().begin(); it != sb.modes().end(); ++it)
    {
        // Vector should be empty from construction
        assert(p->empty());
        // Resize the vector for the current mode, populating with zeros up to
        // the current mode (i.e. from 0 to m-1).
        auto m = *it;
        assert(m >= 0);
        p->resize(m, static_cast<int_t>(0));
        if((it + 1) == sb.modes().end())
        {
            // Cast the scaled basis variant to the destination rec_var
            p->push_back(rec_var_cast<TRecVar>(sb.value()));
        }
        else
        {
            // Add an empty vector to prepare for the next mode.
            p->push_back(vector_t{});
            p = &get_vector(p->back());
        }
    }
    return res;
};

/**
 * @brief Visitor class for performing arithmetic tuple binary operations
 *
 * Calculating the sum of a pair of recursive variants with identical profiles
 * has a straightforward implementation:
 *
 * (1, 3) + (4, 5) = (5, 8)
 *
 * Additional considerations are necessary when one of the input operands can hold
 * a scaled basis data type (as might exist in a CuTe stride). In an abstract form,
 * a scaled basis with a single mode can be thought of as an infinite rank tuple,
 * with a nonzero value in a single position:
 *
 * 6@1 = (0, 6, 0, 0, ...)
 *
 * When multiple modes are present, the nonzero value becomes nested:
 *
 * 3@2@1 = (0, 0, (0, 3, 0, 0, ...), 0, 0, 0, ...)
 *
 * In the general case, the sum of two scaled basis values cannot be represented as
 * a single nonzero value followed by a list of modes that indicate the position.
 * Furthermore, the conditions allowed to perform the sum operation must be relaxed:
 * for a tuple sum, adding recursive variants with different ranks may be considered
 * an error. But for arithmetic tuple sums, as the rank is (conceptually) infinite,
 * we would like the following case to be valid:
 *
 * 6@1 + 3@2 = (0, 6, 0, 0, ...) + (0, 0, 3, 0, 0, ...) = (0, 6, 3, 0, 0, ...)
 *
 * For recursive variants, we also need to accommodate the default-constructed recursive
 * variant value, which is represented as an "empty" vector in cutegen. Therefore, we
 * define the following arithmetic tuple sum rules:
 *
 * A     +  B    = sum(A, B)             where A and B are integers
 *
 * ()    +  0    = 0
 * 0     + ()    = 0
 *
 * (...) + ()    = (...)                 where (...) represents an arbitrary non-empty tuple
 * ()    + (...) = (...)
 *
 * N     + ()    = N                     where N is a nonzero integer
 * ()    + N     = N
 *
 * (...) + 0     = (...)
 * 0     + (...) = (...)
 *
 * (...) + N     = ERROR                 where N is a nonzero integer
 * N     + (...) = ERROR                 where N is a nonzero integer
 *
 * (...) + (...) = resize; transform(a, b, a + b)
 *
 * In order to allow defining strides like `(1@0,1@1,0)` for shape modes of extent 1, the `0`
 * integral value is considered empty. This might lead to making some ill-posed arithmetic tuple
 * operations valid. For example,
 * ```
 * (1,1,1) + (1,1,-1) + (1,1,(1,1))
 * ```
 * The first two tuples' profile is not compatible with the third tuple's profile. Not sure if this
 * is going to be an issue at any point.
 *
 * Notes:
 *
 * - negative tuple elements may be valid for convolutions
 * - CuTe-C++ considers the above operation to be valid as well
 * - with the current way we compute inner products (a transform_leaf() followed by a fold()), the
 *   behavior described above is needed, for example for the last stride mode of
 *   `(10,11,12,1):(1@0@0,1@0@1,1@1,x)` (it can neither be `{}` nor `0@0`)
 */
template <class TBinaryOp>
struct arith_tuple_binary_op_visitor
{
    using result_t = typename TBinaryOp::result_t;
    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    result_t operator()(const TL& lhs, const TR& rhs)
    {
        return TBinaryOp{}(lhs, rhs);
    }
    template <class TL, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    result_t operator()(const std::vector<TL>& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, result_t>::type;
        if(lhs.empty())
        {
            if(!in_range<int_t>(rhs)) return cg_error_t{};
            return static_cast<int_t>(rhs); // () + N = N
        }
        else if(0 == rhs)
        {
            // (x,y,...) + 0 = (x,y,...))
            // The result type may be different than the source type. Therefore,
            // we use rec_var_cast to perform the conversion/cast here.
            using vector_t = typename result_t::vector_t;
            vector_t v;
            for(auto& e : lhs)
            {
                v.push_back(rec_var_cast<result_t>(e));
            }
            return result_t(v);
        }
        // (x,y,...) + N ---> error (for nonzero N)
        return cg_error_t{};
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    result_t operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TR, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    result_t operator()(const TL& lhs, const std::vector<TR>& rhs)
    {
        // Arithmetic sum is commutative, so swap lhs and rhs and forward to vec + int
        return this->operator()(rhs, lhs);
    }
    template <class TL, class TR>
    result_t operator()(const std::vector<TL>& lhs, const std::vector<TR>& rhs)
    {
        result_t res;
        using vector_t = typename result_t::vector_t;
        vector_t v;
        for(size_t i = 0; i < std::max(lhs.size(), rhs.size()); ++i)
        {
            if(i >= lhs.size())
            {
                v.push_back(rec_var_cast<result_t>(rhs[i]));
            }
            else if(i >= rhs.size())
            {
                v.push_back(rec_var_cast<result_t>(lhs[i]));
            }
            else
            {
                result_t r = visit(*this, lhs[i], rhs[i]);
                v.push_back(r);
            }
        }
        return v;
    }
    template <class TR>
    result_t operator()(const cg_error_t& /*lhs*/, const std::vector<TR>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    result_t operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TL>
    result_t operator()(const std::vector<TL>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    result_t operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const TDynamic& lhs, const TR& rhs)
    {
        return TBinaryOp{}(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const TL& lhs, const TDynamic& rhs)
    {
        return TBinaryOp{}(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return TBinaryOp{}(lhs, rhs);
    }
    template <class T,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const std::vector<T>& lhs, const TDynamic& rhs)
    {
        if(lhs.empty())
        {
            return rhs;
        }
        // A non-empty vector added with a zero scalar is not an error, but we
        // don't know the dynamic value. Return an error until/unless we have
        // runtime support for error values.
        return cg_error_t{};
    }
    template <class T,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const TDynamic& lhs, const std::vector<T>& rhs)
    {
        // Addition is commutative - forward to the vec + dynamic operator
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    result_t operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is a scaled basis for which this visitor has special behavior
    //
    template <class... TValueTypes>
    result_t operator()(const scaled_basis_t<TValueTypes...>& lhs,
                        const scaled_basis_t<TValueTypes...>& rhs)
    {
        // Forward to the recursive variant implementation after generating them
        return (*this)(scaled_basis_to_rec_var<result_t>(lhs),
                       scaled_basis_to_rec_var<result_t>(rhs));
    }
    template <class TRecVar,
              class TScaledBasis,
              std::enable_if_t<is_rec_var<TRecVar>::value, bool>           = true,
              std::enable_if_t<is_scaled_basis<TScaledBasis>::value, bool> = true>
    result_t operator()(const TRecVar lhs, const TScaledBasis& rhs)
    {
        // Forward to the recursive variant implementation after generating them
        return (*this)(scaled_basis_to_rec_var<result_t>(rhs), lhs);
    }
    template <class TRecVar,
              class TScaledBasis,
              std::enable_if_t<is_rec_var<TRecVar>::value, bool>           = true,
              std::enable_if_t<is_scaled_basis<TScaledBasis>::value, bool> = true>
    result_t operator()(const TScaledBasis& lhs, const TRecVar& rhs)
    {
        // Forward to the recursive variant implementation after generating them
        return (*this)(scaled_basis_to_rec_var<TRecVar>(lhs), rhs);
    }

    //
    // LHS and RHS are recursive variants (arithmetic tuples)
    //
    template <class TRecVarL,
              class TRecVarR,
              std::enable_if_t<is_rec_var<TRecVarL>::value, bool> = true,
              std::enable_if_t<is_rec_var<TRecVarR>::value, bool> = true>
    result_t operator()(const TRecVarL& lhs, const TRecVarR& rhs)
    {
        return visit(*this, lhs, rhs);
    }
};

template <class TRet>
struct scalar_sub_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;
        if(!in_range<int_t>(lhs) || !in_range<int_t>(rhs)) return cg_error_t{};
        int_t res;
        bool  overflows = detail::sub_overflow(static_cast<int_t>(lhs), static_cast<int_t>(rhs), &res);
        if(overflows) return cg_error_t{};
        return res;
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t&, const TR&) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, class... TValueTypes, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const ratio& lhs, const TR& rhs)
    {
        return scalar_sub<TRet>(lhs, rhs);
    }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*lhs*/, underscore_t /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const ratio& /*lhs*/, const std::vector<TVec>& /*lhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a ratio
    //
    TRet operator()(const ratio& a, const ratio& b)
    {
        return scalar_sub<TRet>(a, b);
    }
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& a, const ratio& b)
    {
        return scalar_sub<TRet>(a, b);
    }
    TRet operator()(underscore_t /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is scaled basis
    //
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        if(lhs.modes() == rhs.modes())
        {
            using sb_variant_t = typename scaled_basis_t<TValueTypes..., cg_error_t>::value_variant_t;
            scalar_sub_visitor<sb_variant_t> sub_value;
            auto                             v = std::visit(sub_value, lhs.value(), rhs.value());
            return std::visit(detail::transform_non_error<TRet, TValueTypes...>([&lhs](const auto& sbv) { return scaled_basis_t<TValueTypes...>(lhs.modes(), sbv); }), v);
        }
        else
        {
            return cg_error_t{};
        }
    }
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true, class... TValueTypes>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(underscore_t /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const ratio& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        if(rhs == 0) return lhs;
        return scalar_sub<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return scalar_sub<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_sub<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(underscore_t /*lhs*/, const TDynamic&) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic&, underscore_t /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const ratio& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const ratio& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_mul_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;
        if(!in_range<int_t>(lhs) || !in_range<int_t>(rhs))
        {
            if constexpr(is_rec_var_and_can_hold_type<TRet, cg_error_t>::value)
            {
                return cg_error_t{};
            }
            assert(false);
        }
        int_t res;
        bool  overflows = detail::mul_overflow(static_cast<int_t>(lhs), static_cast<int_t>(rhs), &res);
        if(overflows)
        {
            if constexpr(is_rec_var_and_can_hold_type<TRet, cg_error_t>::value)
            {
                return cg_error_t{};
            }
            assert(false);
        }
        return res;
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    // If TRecVarC can hold a scaled_basis_t, return an instance holding a scaled_basis_t
    template <class... TValueTypes,
              class TR,
              class TResult                                                         = TRet,
              std::enable_if_t<std::is_integral_v<TR>, bool>                        = true,
              std::enable_if_t<rec_var_can_hold_scaled_basis<TResult>::value, bool> = true>
    TResult operator()(const scaled_basis_t<TValueTypes...>& lhs, const TR& rhs)
    {
        using sb_t         = scaled_basis_t<TValueTypes...>;
        using var_t        = typename sb_t::value_variant_t;
        auto unary_visitor = [&](auto&& v) { return scalar_mul_visitor<var_t>{}(v, rhs); };
        return sb_t(lhs.modes(), visit(unary_visitor, lhs.value()));
    }
    // If TRecVarC is a recursive variant type a scaled basis can be converted into, use a
    // conversion function to "unroll" the scaled_basis_t into the desired type, holding explicit
    // integer or dynamic values
    template <class... TValueTypes,
              class TR,
              class TResult                                                          = TRet,
              std::enable_if_t<std::is_integral_v<TR>, bool>                         = true,
              std::enable_if_t<!rec_var_can_hold_scaled_basis<TResult>::value, bool> = true>
    TResult operator()(const scaled_basis_t<TValueTypes...>& lhs, const TR& rhs)
    {
        using sb_t         = scaled_basis_t<TValueTypes...>;
        using var_t        = typename sb_t::value_variant_t;
        auto unary_visitor = [&](auto&& v) { return scalar_mul_visitor<var_t>{}(v, rhs); };
        auto s             = sb_t(lhs.modes(), visit(unary_visitor, lhs.value()));
        return scaled_basis_to_rec_var<TResult>(s);
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const ratio& lhs, const TR& rhs)
    {
        return scalar_mul<TRet>(lhs, rhs);
    }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              class TResult                                                         = TRet,
              std::enable_if_t<std::is_integral_v<TL>, bool>                        = true,
              std::enable_if_t<rec_var_can_hold_scaled_basis<TResult>::value, bool> = true>
    TResult operator()(const TL& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class... TValueTypes,
              class TL,
              class TResult                                                          = TRet,
              std::enable_if_t<std::is_integral_v<TL>, bool>                         = true,
              std::enable_if_t<!rec_var_can_hold_scaled_basis<TResult>::value, bool> = true>
    TResult operator()(const TL& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class... TValueTypes>
    TRet operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const ratio& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return cg_error_t{};
    }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        // Returning rhs in case lhs is empty doesn't work because, for example, layout_eval's  return
        // type cannot hold scaled_basis_t; thus, it's always an error to get to here
        return cg_error_t{};
    }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a ratio
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& lhs, const ratio& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    TRet operator()(const underscore_t&, const ratio&) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>&, const ratio&)
    {
        return cg_error_t{};
    }
    template <class TVec>
    TRet operator()(const std::vector<TVec>&, const ratio&) { return cg_error_t{}; }
    TRet operator()(const cg_error_t&, const ratio&) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes, class TVec>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        if(rhs == 0) return 0;
        if(rhs == 1) return lhs;
        return scalar_mul<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        // Swap operand order as multiplication is commutative
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_mul<TRet>(lhs, rhs);
    }
    template <class... TValueTypes,
              class TResult = TRet,
              class TDynamic,
              std::enable_if_t<rec_var_can_hold_scaled_basis<TResult>::value &&
                                   has_dynamic_t_base<TDynamic>::value,
                               bool> = true>
    TResult operator()(const scaled_basis_t<TValueTypes...>& lhs, const TDynamic& rhs)
    {
        using sb_t         = scaled_basis_t<TValueTypes...>;
        using var_t        = typename sb_t::value_variant_t;
        auto unary_visitor = [&](auto&& v) { return scalar_mul_visitor<var_t>{}(v, rhs); };
        return sb_t(lhs.modes(), visit(unary_visitor, lhs.value()));
    }
    template <class... TValueTypes,
              class TResult = TRet,
              class TDynamic,
              std::enable_if_t<rec_var_can_hold_scaled_basis<TResult>::value &&
                                   has_dynamic_t_base<TDynamic>::value,
                               bool> = true>
    TResult operator()(const TDynamic& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class... TValueTypes,
              class TResult = TRet,
              class TDynamic,
              std::enable_if_t<!rec_var_can_hold_scaled_basis<TResult>::value &&
                                   has_dynamic_t_base<TDynamic>::value,
                               bool> = true>
    TResult operator()(const scaled_basis_t<TValueTypes...>& lhs, const TDynamic& rhs)
    {
        using sb_t         = scaled_basis_t<TValueTypes...>;
        using var_t        = typename sb_t::value_variant_t;
        auto unary_visitor = [&](auto&& v) { return scalar_mul_visitor<var_t>{}(v, rhs); };
        auto s             = sb_t(lhs.modes(), visit(unary_visitor, lhs.value()));
        return scaled_basis_to_rec_var<TResult>(s);
    }
    template <class... TValueTypes,
              class TResult = TRet,
              class TDynamic,
              std::enable_if_t<!rec_var_can_hold_scaled_basis<TResult>::value &&
                                   has_dynamic_t_base<TDynamic>::value,
                               bool> = true>
    TResult
    operator()(const TDynamic& lhs, const scaled_basis_t<TValueTypes...>& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const ratio& rhs)
    {
        return scalar_mul<TRet>(lhs, rhs); // Forward to overload for TDynamic
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const ratio& lhs, const TDynamic& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_mod_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;
        if(rhs == 0) return cg_error_t{};
        if(!in_range<int_t>(lhs) || !in_range<int_t>(rhs)) return cg_error_t{};
        return static_cast<int_t>(lhs) % static_cast<int_t>(rhs);
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        assert(rhs != 0);
        if(rhs == 1) return 0;
        if constexpr(std::is_signed_v<TR>)
        {
            if(rhs == -1) return 0;
        }
        return scalar_mod<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        // CuTe C++ implement as: 0 % ? -> 0.
        // Even ? equals to zero.
        // However, the layout algebra won't rely on _0{}%0 = 0 result,
        // And this should not happen.
        if(lhs == 0) return 0;
        return scalar_mod<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_mod<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_div_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        return scalar_div<TRet>(lhs, rhs);
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    // RHS is an error
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return scalar_div<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        // CuTe C++ implement as: 0 / ? -> 0.
        // Even ? equals to zero.
        // However, the layout algebra won't rely on _0{}/0 = 0 result,
        // And this should not happen.
        if(lhs == 0) return 0;
        return scalar_div<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_div<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet, bool forceUnsigned = false>
struct scalar_ceil_div_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        using int_t = typename detail::find_type_or<void, std::is_integral, TRet>::type;
        // Do we need to worry about any sort of cast safety?
        if(rhs == 0) return cg_error_t{};
        if(!in_range<int_t>(lhs) || !in_range<int_t>(rhs)) return cg_error_t{};
        return scalar_ceil_div<result_t>(static_cast<int_t>(lhs), static_cast<int_t>(rhs));
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    // RHS is an error
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return scalar_ceil_div<TRet, forceUnsigned>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return scalar_ceil_div<TRet, forceUnsigned>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_ceil_div<TRet, forceUnsigned>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRetQ, class TRetR>
struct scalar_divmod_visitor
{
    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& lhs, const TR& rhs)
    {
        auto q = scalar_div_visitor<TRetQ>{}(lhs, rhs);
        auto r = scalar_mod_visitor<TRetR>{}(lhs, rhs);
        return {q, r};
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec, class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec>
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec, class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVecA, class TVecB>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec>
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& lhs, const TR& rhs)
    {
        auto q = scalar_div_visitor<TRetQ>{}(lhs, rhs);
        auto r = scalar_mod_visitor<TRetR>{}(lhs, rhs);
        return {q, r};
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TL& lhs, const TDynamic& rhs)
    {
        auto q = scalar_div_visitor<TRetQ>{}(lhs, rhs);
        auto r = scalar_mod_visitor<TRetR>{}(lhs, rhs);
        return {q, r};
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        auto q = scalar_div_visitor<TRetQ>{}(lhs, rhs);
        auto r = scalar_mod_visitor<TRetR>{}(lhs, rhs);
        return {q, r};
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    std::pair<TRetQ, TRetR> operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        return {cg_error_t{}, cg_error_t{}};
    }
};

/// Enum for bitwise operation kinds.
enum class bitwise_op
{
    bitwise_op_and,
    bitwise_op_or,
    bitwise_op_xor,
};

// XOR, OR
// These bitwise operations currently share the same folding rules (returning
// a constant for certain dynamic value properties), so we group them together
// in a single visitor.
template <class TRet, bitwise_op op>
struct scalar_bitwise_visitor_xor_or
{
    using result_t = TRet;

    template <class T, bitwise_op fwd_op>
    struct bitwise_op_fwd;

    template <class T>
    struct bitwise_op_fwd<T, bitwise_op::bitwise_op_or>
    {
        template <class TLHS, class TRHS>
        T operator()(const TLHS& lhs, const TRHS& rhs)
        {
            return scalar_bitwise_or<T>(lhs, rhs);
        }
    };
    template <class T>
    struct bitwise_op_fwd<T, bitwise_op::bitwise_op_xor>
    {
        template <class TLHS, class TRHS>
        T operator()(const TLHS& lhs, const TRHS& rhs)
        {
            return scalar_bitwise_xor<T>(lhs, rhs);
        }
    };

    //
    // RHS is an integer
    //
    template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
    TRet operator()(const T& lhs, const T& rhs) { return bitwise_op_fwd<T, op>{}(lhs, rhs); }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return bitwise_op_fwd<TRet, op>{}(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return bitwise_op_fwd<TRet, op>{}(lhs, rhs);
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

// AND
template <class TRet>
struct scalar_bitwise_visitor_and
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
    TRet operator()(const T& lhs, const T& rhs) { return scalar_bitwise_and<TRet>(lhs, rhs); }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return scalar_bitwise_and<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return scalar_bitwise_and<TRet>(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_bitwise_and<TRet>(lhs, rhs);
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_bitwise_visitor_not
{
    using result_t = TRet;

    //
    // value is an integer
    //
    template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
    TRet operator()(const T& value) { return scalar_bitwise_not<TRet>(value); }

    //
    // value is a vector
    //
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // value is an error
    //
    TRet operator()(const cg_error_t& /*lhs*/) { return cg_error_t{}; }

    //
    // value is dynamic
    //
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& value)
    {
        return scalar_bitwise_not<TRet>(value);
    }
};

template <class TRet>
struct scalar_lshr_visitor
{
    using result_t = TRet;

    scalar_lshr_visitor(int32_t s) :
        shift_(s)
    {
    }
    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    TRet operator()(TInt iv)
    {
        return scalar_lshr<TRet>(iv, shift_);
    }
    TRet operator()(const underscore_t& /*rv*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*rv*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*r*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec> /*rv*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*rv*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& dv)
    {
        return scalar_lshr<TRet>(dv, shift_);
    }

private:
    int32_t shift_;
};

template <class TRet>
struct scalar_shl_visitor
{
    using result_t = TRet;

    scalar_shl_visitor(int32_t s) :
        shift_(s)
    {
    }
    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    TRet operator()(TInt iv)
    {
        return scalar_shl<TRet>(iv, shift_);
    }
    TRet operator()(const underscore_t& /*rv*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*rv*/) { return cg_error_t{}; }
    TRet operator()(const ratio& /*r*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec> /*rv*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*rv*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& dv)
    {
        return scalar_shl<TRet>(dv, shift_);
    }

private:
    int32_t shift_;
};

template <class TRet>
struct scalar_min_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        return scalar_min<TRet>(lhs, rhs);
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an underscore
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const underscore_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const underscore_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const underscore_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return scalar_min<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_min<TRet>(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const underscore_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const underscore_t& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_max_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        return scalar_max<TRet>(lhs, rhs);
    }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec> /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec> /*rhs*/) { return cg_error_t{}; }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA> /*lhs*/, const std::vector<TVecB> /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec> /*rhs*/) { return cg_error_t{}; }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    template <class TVec>
    TRet operator()(const std::vector<TVec> /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return scalar_max<TRet>(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return this->operator()(rhs, lhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return scalar_max<TRet>(lhs, rhs);
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/) { return cg_error_t{}; }
};

template <class TRet>
struct scalar_abs_visitor
{
    using result_t = TRet;

    template <class T, std::enable_if_t<std::is_integral_v<T>, bool> = true>
    TRet operator()(const T& rv)
    {
        return std::abs(rv);
    }
    TRet operator()(const underscore_t& /*rv*/) { return cg_error_t{}; }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& rv)
    {
        using sb_t         = scaled_basis_t<TValueTypes...>;
        using var_t        = typename sb_t::value_variant_t;
        auto unary_visitor = [&](auto&& v) { return scalar_abs_visitor<var_t>{}(v); };
        return sb_t(rv.modes(), visit(unary_visitor, rv.value()));
    }
    TRet operator()(const ratio& r)
    {
        return TRet(ratio(std::abs(r.num()), std::abs(r.denom())));
    }
    template <class TVec>
    TRet operator()(const std::vector<TVec> /*rv*/) { return cg_error_t{}; }
    TRet operator()(const cg_error_t& /*rv*/) { return cg_error_t{}; }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& rv)
    {
        return abs(rv);
    }
};

template <class TRet, comp_pred predicate>
struct scalar_cmp_visitor
{
    using result_t = TRet;

    //
    // RHS is an integer
    //
    template <class TL,
              class TR,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const TL& lhs, const TR& rhs)
    {
        // Promote before doing the comparison
        using T = typename find_widest_integral_type<TL, TR>::type;
        return compare<T, predicate>{}(static_cast<T>(lhs), static_cast<T>(rhs));
    }
    template <class... TValueTypes,
              class TR,
              std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>, const TR& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec, class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TR& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TR& /*rhs*/)
    {
        assert(false);
        return false;
    }

    //
    // RHS is a scaled basis
    //
    template <class... TValueTypes,
              class TL,
              std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/,
                    const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec, class... TValueTypes>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class... TValueTypes>
    TRet operator()(const cg_error_t& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        assert(false);
        return false;
    }

    //
    // RHS is a vector
    //
    template <class TL, class TVec, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec, class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVecA, class TVecB>
    TRet operator()(const std::vector<TVecA>& /*lhs*/, const std::vector<TVecB>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec>
    TRet operator()(const cg_error_t& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        assert(false);
        return false;
    }

    //
    // RHS is an error
    //
    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    TRet operator()(const TL& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        assert(false);
        return false;
    }
    TRet operator()(const cg_error_t& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        assert(false);
        return false;
    }

    //
    // LHS or RHS is dynamic
    //
    template <class TR,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TR> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TR& rhs)
    {
        return compare<TDynamic, predicate>{}(lhs, rhs);
    }
    template <class TL,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TL> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TL& lhs, const TDynamic& rhs)
    {
        return compare<TDynamic, predicate>{}(lhs, rhs);
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        return compare<TDynamic, predicate>{}(lhs, rhs);
    }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const scaled_basis_t<TValueTypes...>& /*lhs*/, const TDynamic& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class... TValueTypes,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const scaled_basis_t<TValueTypes...>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const std::vector<TVec>& /*lhs*/, const TDynamic& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TVec,
              class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const std::vector<TVec>& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const cg_error_t& /*lhs*/, const TDynamic& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    TRet operator()(const TDynamic& /*lhs*/, const cg_error_t& /*rhs*/)
    {
        assert(false);
        return false;
    }

    //
    // LHS or RHS is an underscore
    //
    template <class TR>
    TRet operator()(const underscore_t& /*lhs*/, const TR& /*rhs*/)
    {
        assert(false);
        return false;
    }
    template <class TL>
    TRet operator()(const TL& /*lhs*/, const underscore_t& /*rhs*/)
    {
        assert(false);
        return false;
    }
    TRet operator()(const underscore_t& /*lhs*/, const underscore_t& /*rhs*/)
    {
        assert(false);
        return false;
    }
};

// Pre-conditions:
// LHS and RHS must satisfy holds_int_like.
// This API cannot return an error so the inputs must be sanitized by the caller.
template <class TRecVarA,
          class TRecVarB,
          comp_pred predicate,
          std::enable_if_t<is_rec_var<TRecVarA>::value, bool> = true,
          std::enable_if_t<is_rec_var<TRecVarB>::value, bool> = true>
auto scalar_cmp(const TRecVarA& lhs, const TRecVarB& rhs)
{
    using dyn_t    = typename find_dynamic_in_rec_var<TRecVarA>::value;
    using result_t = std::variant<bool, dyn_t>;
    return visit(scalar_cmp_visitor<result_t, predicate>{}, lhs, rhs);
}

template <class A, class TRecVar>
TRecVar lift_slice(const A& a, const TRecVar& b)
{
    if(holds_vector(a))
    {
        TRecVar ret;
        for(size_t i = 0; i < rank(a); ++i)
        {
            ret = cat_tuple(ret, lift_slice(get_vector_elem(a, i), get_vector_elem(b, i)));
        }
        return ret;
    }
    else if(holds_underscore(a))
    {
        TRecVar ret;
        ret.append(b);
        return ret;
    }
    else
    {
        return TRecVar{};
    }
}

template <class A, class TRecVar>
TRecVar lift_dice(const A& a, const TRecVar& b)
{
    if(holds_vector(a))
    {
        if(rank(a) != rank(b)) return cg_error_t{};
        TRecVar ret;
        for(size_t i = 0; i < rank(a); ++i)
        {
            ret = cat_tuple(ret,
                            lift_dice(get_vector_elem(a, i),
                                      get_vector_elem(b, i)));
        }
        return ret;
    }
    else if(holds_underscore(a))
    {
        return TRecVar{};
    }
    else
    {
        TRecVar ret;
        ret.append(b);
        return ret;
    }
}

template <typename TRV>
auto signum_impl(const TRV& t)
{
    return cond_assign(
        scalar_cmp<TRV, TRV, comp_pred::gt>(t, TRV(0)),
        [=]() -> TRV { return TRV(1); },
        [=]() -> TRV //
        {
            return cond_assign(
                scalar_cmp<TRV, TRV, comp_pred::eq>(t, TRV(0)),
                [=]() -> TRV { return TRV(0); },
                [=]() -> TRV //
                {
                    static_assert(std::is_signed_v<typename TRV::int_t>);
                    return TRV(-1);
                });
        });
}

/**
 * @brief Returns `1` if `x > 0`, `-1` if `x < 0`, and `0` otherwise.
 *
 * If called on an integral type, the argument will get wrapped into a recursive variant.
 *
 * @pre @p t is either a scalar recursive variant or an integral
 */
template <typename T>
auto signum(const T& t)
{
    if constexpr(std::is_integral_v<T>)
        return signum(rec_var<T>(t));
    else if constexpr(is_rec_var<T>::value)
    {
        if(!holds_int_or_dynamic_int(t)) return T(cg_error_t{});
        return signum_impl(t);
    }
}

/**
 * @brief Structure to represent the index of a dynamic value
 *
 * This structure identifies a dynamic value within an algebraic type assuming a
 * "left to right" ordering. (In other words, printing when printing an
 * algebraic type, the order of the dynamic values in the text output provides a
 * value for the dynamic index. (The first '?' represents index 0, the second '?'
 * has index 1, etc.)
 */
struct dynamic_index_t
{
    /* Make the constructor explicit to avoid inadvertently creating an instance
     * from a static constant integer.*/
    explicit dynamic_index_t(int v) :
        value(v) {}
    int value;
};

/// Comparison operator for dynamic indices
inline bool operator==(const dynamic_index_t& lhs, const dynamic_index_t& rhs)
{
    return lhs.value == rhs.value;
}
inline bool operator!=(const dynamic_index_t& lhs, const dynamic_index_t& rhs)
{
    return lhs.value != rhs.value;
}

/**
 * @brief Structure to represent an operand for a runtime comparison in equality
 * checks
 *
 * This structure provides information on a runtime comparison that is
 * required to determine equality between two recursive variant types.
 * Checking for equality at code generation time can yield one of 3 results:
 * - the recursive variants are statically known, without dynamic types, and
 *   all elements are equal
 * - the recursive variants are known to be unequal - either because the
 *   profiles do not match, or because individual static elements do not match
 * - one or both of the recursive variants has dynamic values, and equality
 *   cannot be determined until the dynamic values are populated at runtime.
 *
 * For the third scenario, comparisons need to be made at runtime. Comparisons
 * will be either:
 * - comparing a statically known integer to a dynamic value, or
 * - comparing two dynamic values
 *
 * This variant describes one of the values involved in a comparison: either:
 * - a statically known constant, or
 * - the index of a dynamic value within an algebraic value
 */
using eq_comp_value_t = std::variant<static_int_t, dynamic_index_t>;

/**
 * @brief Structure to represent the two operands required for a runtime
 * comparison for equality checks between recursive variants.
 *
 * This structure provides information on a runtime comparison that is
 * required to determine equality between two algebraic types.
 * Check for equality at code generation time can yield one of 3 results:
 * - the algebraic types are statically known, without dynamic types, and
 *   all elements are equal
 * - the algebraic types are known to be unequal - either because the
 *   profiles do not match, or because individual elements do not match
 * - one or both of the algebraic values has dynamic values, and equality
 *   cannot be determined until the dynamic values are populated at runtime.
 *
 * For the third scenario, comparisons need to be made at runtime. Comparisons
 * will be:
 * - comparing a statically known integer to a dynamic value, or
 * - comparing two dynamic values
 *
 * This variant describes a pair of values involved in a comparison. Each will
 * be either:
 * - a statically known constant, or
 * - the index of a dynamic value within an algebraic value
 */
using eq_comp_t = std::pair<eq_comp_value_t, eq_comp_value_t>;

/// Stream insertion operator for equality comparison pairs (for debugging)
inline std::ostream& operator<<(std::ostream&    os,
                                const eq_comp_t& cmp)
{
    auto stream_insert = [&](auto&& arg) {
        if(std::holds_alternative<static_int_t>(arg))
        {
            os << std::get<static_int_t>(arg);
        }
        else
        {
            os << "dyn[" << std::get<dynamic_index_t>(arg).value << "]";
        }
    };
    stream_insert(cmp.first);
    os << ", ";
    stream_insert(cmp.second);
    return os;
}

/**
 * @brief Type definiton for the result of an equality check at code generation time
 *
 * This type provides the result of a traversal to determine equality at code
 * generation time.
 * Check for equality at code generation time can yield one of 3 results:
 * - the algebraic types are statically known, without dynamic types, and
 *   all elements are equal
 * - the algebraic types are known to be unequal - either because the
 *   profiles do not match, or because individual elements do not match
 * - one or both of the algebraic values has dynamic values, and equality
 *   cannot be determined until the dynamic values are populated at runtime.
 *
 * For the first two scenarios, the eq_comp_result_t will hold a boolean
 * value, equal to true if the values are statically known to be equal,
 * or false if the values are statically known to be unequal.
 * For the third scenario, this type holds a container with runtime comparisons
 * that are necessary to determine equality. If any of the comparison pairs are
 * unequal, the two algebra types are unequal. Otherwise, the algebra types are
 * equal.
 * The container type is a template paramater. The container type must have
 * eq_comp_t as its value type, and it must support the push_back() method.
 * (Typical examples of types that can be used for the container are
 * std::vector<eq_comp_t> and llvm::SmallVector<eq_comp_t>.)
 */
template <class TContainer>
using eq_comp_result_t = std::variant<TContainer, bool>;

/**
 * @brief Visitor class for equality checks at code generation time
 */
template <class TContainer>
struct check_equality_visitor
{
    // The visitor allows customization of the container used to return the
    // collection of comparisons for cases in which equality cannot be
    // statically determined. Examples: std::vector, llvm::SmallVector
    using container_t       = TContainer;
    using prop_cmp_result_t = std::variant<bool, dynamic_t>;
    using prop_cmp_eq_t     = compare<dynamic_t, comp_pred::eq>;

    check_equality_visitor() :
        lhs_dynamic_count_(0), rhs_dynamic_count_(0) {}
    template <class TLHS, class TRHS>
    auto check(const TLHS& lhs, const TRHS& rhs)
    {
        // Initialize state in case the same visitor is reused.
        lhs_dynamic_count_ = rhs_dynamic_count_ = 0;
        comps_                                  = container_t{};
        this->operator()(lhs, rhs);
        // If no comparisons have yielded failure (which would assign false to comps_),
        // and no comparisons between elements have been added to the list, the types
        // must be equal. So we change the variant held type to bool, with value true.
        if(std::holds_alternative<container_t>(comps_) && std::get<container_t>(comps_).empty())
            comps_ = true;
        return comps_;
    }
    template <class... TLHSTypes, class... TRHSTypes>
    void operator()(const std::variant<TLHSTypes...>& lhs,
                    const std::variant<TRHSTypes...>& rhs)
    {
        // Use cutegen visit instead of std::visit to satisfy older compilers
        // that don't allow a class derived from std::variant to be used with
        // std::visit().
        //std::visit(*this, lhs, rhs);
        visit(*this, lhs, rhs);
    }
    //--------------------------------------------------------------------------
    // LHS = static_int_t
    void operator()(static_int_t lhs, static_int_t rhs)
    {
        if(lhs != rhs)
            comps_ = false;
    }
    void operator()(static_int_t lhs, cg_error_t rhs) { comps_ = false; }
    template <class TElement>
    void operator()(static_int_t lhs, const std::vector<TElement>& rhs) { comps_ = false; }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(static_int_t lhs, const TDynamic& rhs)
    {
        // Use dynamic properties to check whether equality is known statically.
        prop_cmp_result_t res = prop_cmp_eq_t{}(lhs, rhs);
        if(std::holds_alternative<bool>(res))
        {
            if(!std::get<bool>(res))
            {
                // The values cannot be equal so the aggregate equality is false.
                comps_ = false;
            }
        }
        else
        {
            assert(std::holds_alternative<dynamic_t>(res));
            assert(std::holds_alternative<container_t>(comps_));
            std::get<container_t>(comps_).push_back(eq_comp_t{lhs, dynamic_index_t(rhs_dynamic_count_++)});
        }
    }
    void operator()(static_int_t lhs, const underscore_t& rhs) { comps_ = false; }
    template <typename... TTypes>
    void operator()(static_int_t lhs, const scaled_basis_t<TTypes...>& rhs) { comps_ = false; }
    void operator()(static_int_t lhs, const ratio& rhs)
    {
        ratio::reduced_t r = rhs.reduced();
        if(std::holds_alternative<ratio::int_t>(r) && (std::get<ratio::int_t>(r) == lhs))
            return; // The static value is equal to the ratio (reduced) - continue checking

        comps_ = false;
    }

    //--------------------------------------------------------------------------
    // LHS = dynamic
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, static_int_t rhs)
    {
        // Use dynamic properties to check whether equality is known statically.
        prop_cmp_result_t res = prop_cmp_eq_t{}(lhs, rhs);
        if(std::holds_alternative<bool>(res))
        {
            if(!std::get<bool>(res))
            {
                // The values cannot be equal so the aggregate equality is false.
                comps_ = false;
            }
        }
        else
        {
            assert(std::holds_alternative<dynamic_t>(res));
            assert(std::holds_alternative<container_t>(comps_));
            std::get<container_t>(comps_).push_back(eq_comp_t{dynamic_index_t(lhs_dynamic_count_++), rhs});
        }
    }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, cg_error_t rhs) { comps_ = false; }
    template <class TDynamic,
              class TElement,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, const std::vector<TElement>& rhs) { comps_ = false; }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, const TDynamic& rhs)
    {
        // Use dynamic properties to check whether equality is known statically.
        prop_cmp_result_t res = prop_cmp_eq_t{}(lhs, rhs);
        if(std::holds_alternative<bool>(res))
        {
            if(!std::get<bool>(res))
            {
                // The values cannot be equal so the aggregate equality is false.
                comps_ = false;
            }
        }
        else
        {
            assert(std::holds_alternative<dynamic_t>(res));
            assert(std::holds_alternative<container_t>(comps_));
            std::get<container_t>(comps_).push_back(eq_comp_t{dynamic_index_t(lhs_dynamic_count_++),
                                                              dynamic_index_t(rhs_dynamic_count_++)});
        }
    }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, const underscore_t& rhs) { comps_ = false; }
    template <class TDynamic,
              typename... TTypes,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, const scaled_basis_t<TTypes...>& rhs) { comps_ = false; }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& lhs, const ratio& rhs)
    {
        ratio::reduced_t r = rhs.reduced();
        if(std::holds_alternative<ratio::int_t>(r))
        {
            assert(std::holds_alternative<container_t>(comps_));
            // Store a comparison for the dynamic value and the reduced integer value
            std::get<container_t>(comps_).push_back(eq_comp_t{dynamic_index_t(lhs_dynamic_count_++),
                                                              std::get<ratio::int_t>(r)});
            return;
        }
        // The ratio is non-integral, so an integer dynamic value cannot be equal.
        comps_ = false;
    }

    //--------------------------------------------------------------------------
    // LHS = vector
    template <class TElement>
    void operator()(const std::vector<TElement>& lhs, static_int_t rhs) { comps_ = false; }
    template <class TElement>
    void operator()(const std::vector<TElement>& lhs, cg_error_t rhs) { comps_ = false; }
    template <class TElementLHS, class TElementRHS>
    void operator()(const std::vector<TElementLHS>& lhs, const std::vector<TElementRHS>& rhs)
    {
        if(lhs.size() != rhs.size())
        {
            comps_ = false;
            return;
        }
        for(size_t i = 0; i < lhs.size(); ++i)
        {
            // Use cutegen visit instead of std::visit to satisfy older
            // compilers that don't allow a class derived from std::variant to
            // be used with std::visit().
            visit(*this, lhs[i], rhs[i]);
            // Exit early if any vector elements reach a hard decision of "not equal"
            if(std::holds_alternative<bool>(comps_))
                return;
        }
    }
    template <class TDynamic,
              class TElement,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const std::vector<TElement>& lhs, const TDynamic& rhs) { comps_ = false; }
    template <class TElement>
    void operator()(const std::vector<TElement>& lhs, const underscore_t& rhs) { comps_ = false; }
    template <class TElement,
              typename... TTypes>
    void operator()(const std::vector<TElement>& lhs, const scaled_basis_t<TTypes...>& rhs) { comps_ = false; }
    //--------------------------------------------------------------------------
    // LHS = error
    void operator()(cg_error_t lhs, static_int_t rhs) { comps_ = false; }
    void operator()(cg_error_t lhs, cg_error_t rhs) { comps_ = false; }
    template <class TElement>
    void operator()(cg_error_t lhs, const std::vector<TElement>& rhs) { comps_ = false; }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(cg_error_t lhs, const TDynamic& rhs) { comps_ = false; }
    void operator()(cg_error_t lhs, const underscore_t& rhs) { comps_ = false; }
    template <typename... TTypes>
    void operator()(cg_error_t lhs, const scaled_basis_t<TTypes...>& rhs) { comps_ = false; }

    //--------------------------------------------------------------------------
    // LHS = underscore
    void operator()(const underscore_t& lhs, static_int_t rhs) { comps_ = false; }
    void operator()(const underscore_t& lhs, cg_error_t rhs) { comps_ = false; }
    template <class TElement>
    void operator()(const underscore_t& lhs, const std::vector<TElement>& rhs) { comps_ = false; }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const underscore_t& lhs, const TDynamic& rhs) { comps_ = false; }
    void operator()(const underscore_t& lhs, const underscore_t& rhs) {}
    template <typename... TTypes>
    void operator()(const underscore_t& lhs, const scaled_basis_t<TTypes...>& rhs) { comps_ = false; }
    //--------------------------------------------------------------------------
    // LHS = scaled basis
    template <typename... TTypes>
    void operator()(const scaled_basis_t<TTypes...>& lhs, static_int_t rhs) { comps_ = false; }
    template <typename... TTypes>
    void operator()(const scaled_basis_t<TTypes...>& lhs, cg_error_t rhs) { comps_ = false; }
    template <class TElement, typename... TTypes>
    void operator()(const scaled_basis_t<TTypes...>& lhs, const std::vector<TElement>& rhs) { comps_ = false; }
    template <class TDynamic,
              typename... TTypes,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const scaled_basis_t<TTypes...>& lhs, const TDynamic& rhs) { comps_ = false; }
    template <typename... TTypes>
    void operator()(const scaled_basis_t<TTypes...>& lhs, const underscore_t& rhs) { comps_ = false; }
    template <typename... TLHSTypes, typename... TRHSTypes>
    void operator()(const scaled_basis_t<TLHSTypes...>& lhs, const scaled_basis_t<TRHSTypes...>& rhs)
    {
        if(lhs.modes() != rhs.modes())
        {
            comps_ = false;
            return;
        }
        std::visit(*this, lhs.value(), rhs.value());
    }
    //--------------------------------------------------------------------------
    // LHS = ratio
    // Ratios are only currently part of scaled basis values, so we only need
    // visitor operators for other types that can be scaled basis values (i.e.
    // int, dynamic).
    void operator()(const ratio& lhs, static_int_t rhs)
    {
        ratio::reduced_t r = lhs.reduced();
        if(std::holds_alternative<ratio::int_t>(r) && (std::get<ratio::int_t>(r) == rhs))
            return; // The static value is equal to the ratio (reduced) - continue checking

        comps_ = false;
    }
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const ratio& lhs, const TDynamic& rhs)
    {
        ratio::reduced_t r = lhs.reduced();
        if(std::holds_alternative<ratio::int_t>(r))
        {
            assert(std::holds_alternative<container_t>(comps_));
            // Store a comparison for the reduced integer value and the dynamic value
            std::get<container_t>(comps_).push_back(eq_comp_t{std::get<ratio::int_t>(r),
                                                              dynamic_index_t(rhs_dynamic_count_++)});
            return;
        }
        // The ratio is non-integral, so an integer dynamic value cannot be equal.
        comps_ = false;
    }
    void operator()(const ratio& lhs, const ratio& rhs)
    {
        if(lhs != rhs)
            comps_ = false;
    }

private:
    // Data
    // Variant that holds either a container of comparison objects or a boolean
    // value for statically known true/false.
    eq_comp_result_t<TContainer> comps_;
    // The counts below are incremented as we traverse the operands to keep
    // track of which dynamic "index" (or position within the algebra value) is
    // next.
    int lhs_dynamic_count_;
    int rhs_dynamic_count_;
};

/**
 * @brief Function to analyze a pair of algebra values for an equality check at
 * code generation time
 *
 * This type traverses a pair of algebra values to determine what is known about
 * equality at code generation time.
 * Checking for equality at code generation time can yield one of 3 results:
 * - the algebraic types are statically known, without dynamic types, and
 *   all elements are equal
 * - the algebraic types are known to be unequal - either because the
 *   profiles do not match, or because individual elements do not match
 * - one or both of the algebraic values has dynamic values, and equality
 *   cannot be determined until the dynamic values are populated at runtime.
 *
 * The return value is a variant that holds a boolean value if the algebra
 * values are statically known to be equal (true) or unequal (false). Otherwise,
 * the return value holds a container that describes the comparisons that need
 * to be made at runtime.
 * The container type is customizable, and it must support the push_back()
 * method. (Typical examples of container types that can be used are std::vector
 * and llvm::SmallVector.)
 *
 *  @see eq_comp_result_t
 */
template <class TContainer,
          class TLHS,
          class TRHS>
eq_comp_result_t<TContainer> check_equality(const TLHS& lhs, const TRHS& rhs)
{
    check_equality_visitor<TContainer> vis;
    return vis.check(lhs, rhs);
}

//
// Forward declaration of visitors that may contain layout elements and defined in visitors.hpp
//

template <class TVariant, typename TEnable = void>
struct cast_dst_variant_types;

template <class... TElemTypes>
struct cast_dst_variant_types<std::variant<TElemTypes...>>
{
    using types_t = std::tuple<TElemTypes...>;
};

template <class TRecVar>
struct cast_dst_variant_types<TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, void>>
{
    // We exclude the vector type because the visitor handles the source vector
    // type directly.
    using types_t = typename TRecVar::elem_types_t;
};

template <class TRecVar>
TRecVar prefix_product_impl(const TRecVar& a,
                            TRecVar&       init)
{
    if(holds_leaf(init))
    {
        if(holds_vector(a))
        {
            // a is a tuple of values
            TRecVar t;
            get_vector(t).reserve(rank(a));
            for(size_t i = 0; i < rank(a); ++i)
            {
                t.append(prefix_product_impl(a[i], init));
            }
            return t;
        }
        // a holds a scalar
        TRecVar r = init;
        init      = scalar_mul<TRecVar>(a, init);
        return r;
    }
    else
    {
        if(rank(a) != rank(init))
        {
            // Rank mismatch between source and initial value
            return TRecVar(cg_error_t{});
        }
        TRecVar t;
        get_vector(t).reserve(rank(a));
        for(size_t i = 0; i < rank(a); ++i)
        {
            t.append(prefix_product_impl(a[i], init[i]));
        }
        return t;
    }
}

template <class TStride, class TShape, class TVector>
TStride make_basis_like(const TShape& shape, TVector& modes)
{
    using sb_t = typename find_scaled_basis_in_rec_var<TStride>::value;
    if(!holds_vector(shape))
    {
        return sb_t(modes, 1);
    }
    TStride stride;
    for(size_t i = 0; i < rank(shape); i++)
    {
        modes.push_back(static_cast<typename TVector::value_type>(i));
        stride.append(detail::make_basis_like<TStride>(shape[i], modes));
        modes.pop_back();
    }
    return stride;
}

} // namespace detail

template <class TRecVarDst, class TSrc>
TRecVarDst rec_var_cast(const TSrc& rhs)
{
    if constexpr(std::is_same_v<TRecVarDst, TSrc>)
    {
        // For identical src/dst types, return a simple copy
        return rhs;
    }
    else
    {
        detail::rec_var_cast_op<TRecVarDst,
                                typename TRecVarDst::elem_types_t>
            op{};
        return op.cast_visit(rhs);
    }
}

template <class TDst, class TSrc>
TDst cast_to_base_dynamic(const TSrc& rhs)
{
    if constexpr(std::is_same_v<TDst, TSrc>)
    {
        // For identical src/dst types, return a simple copy
        return rhs;
    }
    else
    {
        using dst_var_types_t  = typename detail::cast_dst_variant_types<TDst>::types_t;
        using type_converter_t = detail::rec_var_cast_type_converter_slice_dynamic;
        detail::rec_var_cast_op<TDst,
                                dst_var_types_t,
                                type_converter_t>
            op{};
        return op.cast_visit(rhs);
    }
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_add(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_add_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_sub(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_sub_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_mul(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_mul_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_mod(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_mod_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_div(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_div_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          bool forceUnsigned,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_ceil_div(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_ceil_div_visitor<TRecVarRet, forceUnsigned>{}, lhs, rhs);
}

template <class TRecVarQ,
          class TRecVarR,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
std::pair<TRecVarQ, TRecVarR> scalar_divmod(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_divmod_visitor<TRecVarQ, TRecVarR>{}, lhs, rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool>,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool>>
TResult scalar_bitwise_and(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return visit(detail::scalar_bitwise_visitor_and<TResult>{}, lhs, rhs);
}
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>,
          std::enable_if_t<std::is_integral<TInt>::value, bool>>
TResult scalar_bitwise_and(const TRecVar& lhs, TInt rhs)
{
    using int_t = typename TRecVar::int_t;
    return visit(detail::scalar_bitwise_visitor_and<TResult>{}, lhs, TRecVar(static_cast<int_t>(rhs)));
}
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool>,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>>
TResult scalar_bitwise_and(TInt lhs, const TRecVar& rhs)
{
    return visit(detail::scalar_bitwise_visitor_and<TResult>{}, TRecVar(lhs), rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool>,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool>>
TResult scalar_bitwise_or(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return visit(detail::scalar_bitwise_visitor_xor_or<TResult, detail::bitwise_op::bitwise_op_or>{}, lhs, rhs);
}
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>,
          std::enable_if_t<std::is_integral<TInt>::value, bool>>
TResult scalar_bitwise_or(const TRecVar& lhs, TInt rhs)
{
    using int_t = typename TRecVar::int_t;
    return visit(detail::scalar_bitwise_visitor_xor_or<TResult, detail::bitwise_op::bitwise_op_or>{}, lhs, TRecVar(static_cast<int_t>(rhs)));
}
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool>,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>>
TResult scalar_bitwise_or(TInt lhs, const TRecVar& rhs)
{
    // Swap operand order
    return scalar_bitwise_or<TResult>(rhs, lhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_visitable<TRecVarA>::value, bool>,
          std::enable_if_t<is_visitable<TRecVarB>::value, bool>>
TResult scalar_bitwise_xor(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return visit(detail::scalar_bitwise_visitor_xor_or<TResult, detail::bitwise_op::bitwise_op_xor>{}, lhs, rhs);
}
template <class TResult,
          class TRecVar,
          class TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>,
          std::enable_if_t<std::is_integral<TInt>::value, bool>>
TResult scalar_bitwise_xor(const TRecVar& lhs, TInt rhs)
{
    using int_t = typename TRecVar::int_t;
    return visit(detail::scalar_bitwise_visitor_xor_or<TResult, detail::bitwise_op::bitwise_op_xor>{}, lhs, TRecVar(static_cast<int_t>(rhs)));
}
template <class TResult,
          class TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral<TInt>::value, bool>,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>>
TResult scalar_bitwise_xor(TInt lhs, const TRecVar& rhs)
{
    return scalar_bitwise_xor<TResult>(rhs, lhs);
}

template <class TResult,
          class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>>
TResult scalar_bitwise_not(const TRecVar& value)
{
    return visit(detail::scalar_bitwise_visitor_not<TResult>{}, value);
}

template <class TResult,
          class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TResult scalar_lshr(const TRecVar& lhs, int32_t shift_amount)
{
    return visit(detail::scalar_lshr_visitor<TResult>{shift_amount}, lhs);
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TRecVar scalar_shl(const TRecVar& lhs, int32_t shift_amount)
{
    return visit(detail::scalar_shl_visitor<TRecVar>{shift_amount}, lhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_min(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_min_visitor<TRecVarRet>{}, lhs, rhs);
}

template <class TRecVarRet,
          class TA,
          class TB,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_max(const TA& lhs, const TB& rhs)
{
    return visit(detail::scalar_max_visitor<TRecVarRet>{}, lhs, rhs);
}
template <class TRecVarRet,
          class TA,
          class TInt,
          std::enable_if_t<is_visitable<TA>::value, bool>,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRecVarRet scalar_max(const TA& lhs, TInt rhs)
{
    return scalar_max<TRecVarRet>(lhs, TA{rhs});
}
template <class TRecVarRet,
          class TInt,
          class TB,
          std::enable_if_t<std::is_integral_v<TInt>, bool>,
          std::enable_if_t<is_visitable<TB>::value, bool>>
TRecVarRet scalar_max(TInt lhs, const TB& rhs)
{
    return scalar_max<TRecVarRet>(TB{lhs}, rhs);
}

template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool>>
TRecVar scalar_abs(const TRecVar& rv)
{
    return visit(detail::scalar_abs_visitor<TRecVar>{}, rv);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_sum(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return detail::arith_tuple_binary_op_visitor<detail::scalar_add_visitor<TResult>>{}(lhs, rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_sub(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return detail::arith_tuple_binary_op_visitor<detail::scalar_sub_visitor<TResult>>{}(lhs, rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_mul(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return detail::arith_tuple_binary_op_visitor<detail::scalar_mul_visitor<TResult>>{}(lhs, rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_mod(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return detail::arith_tuple_binary_op_visitor<detail::scalar_mod_visitor<TResult>>{}(lhs, rhs);
}

template <class TResult,
          class TRecVarA,
          class TRecVarB>
TResult arith_tuple_div(const TRecVarA& lhs, const TRecVarB& rhs)
{
    return detail::arith_tuple_binary_op_visitor<detail::scalar_div_visitor<TResult>>{}(lhs, rhs);
}

// Operator overloads for arithmetic tuples
template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator+(const TRecVar& lhs, const TRecVar& rhs)
{
    return arith_tuple_sum<TRecVar>(lhs, rhs);
}

template <class TRecVar,
          typename TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true>
TRecVar operator+(const TRecVar& lhs, TInt rhs)
{
    return arith_tuple_sum<TRecVar>(lhs, TRecVar{rhs});
}

template <typename TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator+(TInt lhs, const TRecVar& rhs)
{
    return arith_tuple_sum<TRecVar>(TRecVar{lhs}, rhs);
}

template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator-(const TRecVar& lhs, const TRecVar& rhs)
{
    return arith_tuple_sub<TRecVar>(lhs, rhs);
}

template <class TRecVar,
          typename TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true>
TRecVar operator-(const TRecVar& lhs, TInt rhs)
{
    return arith_tuple_sub<TRecVar>(lhs, TRecVar{rhs});
}

template <typename TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator-(TInt lhs, const TRecVar& rhs)
{
    return arith_tuple_sub<TRecVar>(TRecVar{lhs}, rhs);
}

template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator*(const TRecVar& lhs, const TRecVar& rhs)
{
    return arith_tuple_mul<TRecVar>(lhs, rhs);
}

template <class TRecVar,
          typename TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true>
TRecVar operator*(const TRecVar& lhs, TInt rhs)
{
    return arith_tuple_mul<TRecVar>(lhs, TRecVar{rhs});
}

template <typename TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator*(TInt lhs, const TRecVar& rhs)
{
    return arith_tuple_mul<TRecVar>(TRecVar{lhs}, rhs);
}

template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator/(const TRecVar& lhs, const TRecVar& rhs)
{
    return arith_tuple_div<TRecVar>(lhs, rhs);
}

template <class TRecVar,
          typename TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true>
TRecVar operator/(const TRecVar& lhs, TInt rhs)
{
    return arith_tuple_div<TRecVar>(lhs, TRecVar{rhs});
}

template <typename TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator/(TInt lhs, const TRecVar& rhs)
{
    return arith_tuple_div<TRecVar>(TRecVar{lhs}, rhs);
}

template <class TRecVar,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator%(const TRecVar& lhs, const TRecVar& rhs)
{
    return arith_tuple_mod<TRecVar>(lhs, rhs);
}

template <class TRecVar,
          typename TInt,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true>
TRecVar operator%(const TRecVar& lhs, TInt rhs)
{
    return arith_tuple_mod<TRecVar>(lhs, TRecVar{rhs});
}

template <typename TInt,
          class TRecVar,
          std::enable_if_t<std::is_integral_v<TInt>, bool>     = true,
          std::enable_if_t<is_visitable<TRecVar>::value, bool> = true>
TRecVar operator%(TInt lhs, const TRecVar& rhs)
{
    return arith_tuple_mod<TRecVar>(TRecVar{lhs}, rhs);
}

template <class... T>
bool all_are_static(const T&... t)
{
    return (is_static(t) && ...);
}

template <class A, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TRecVar slice(const A& a, const TRecVar& b)
{
    if(holds_vector(a))
    {
        TRecVar ret;
        for(size_t i = 0; i < rank(a); ++i)
        {
            ret = cat_tuple(ret, detail::lift_slice(get_vector_elem(a, i), get_vector_elem(b, i)));
        }
        return ret;
    }
    else if(holds_underscore(a))
    {
        return b;
    }
    else
    {
        return TRecVar{};
    }
}

// Entry point overrides the lifting so that dice(1,b) == b
template <class A, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TRecVar dice(const A& a, const TRecVar& b)
{
    if(holds_vector(a))
    {
        if(rank(a) != rank(b)) return cg_error_t{};
        TRecVar ret;
        for(size_t i = 0; i < rank(a); ++i)
        {
            ret = cat_tuple(ret,
                            detail::lift_dice(get_vector_elem(a, i),
                                              get_vector_elem(b, i)));
        }
        return ret;
    }
    else if(holds_underscore(a))
    {
        return TRecVar{};
    }
    else
    {
        return b;
    }
}

template <class TRecVar>
TRecVar abs(const TRecVar& rv)
{
    return transform_leaf([](const TRecVar& x) {
        return scalar_abs<TRecVar>(x);
    },
                          rv);
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto product(const TRecVar& rv)
{
    return fold(
        rv,
        TRecVar(1),
        [](const TRecVar& lhs, const TRecVar& rhs) //
        {
            assert(holds_leaf(lhs));
            assert(holds_leaf(rhs));
            return scalar_mul<TRecVar, TRecVar, TRecVar>(lhs, rhs);
        });
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto product_each(const TRecVar& rv)
{
    return transform([](const TRecVar& x) { return product(x); }, wrap_if_leaf(rv));
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto prefix_product(const TRecVar& rv, const TRecVar& init)
{
    TRecVar accum(init);
    return detail::prefix_product_impl(rv, accum);
}

template <class TRecVar>
auto sum(const TRecVar& rv)
{
    return fold(rv,
                TRecVar(0),
                [](const TRecVar& lhs, const TRecVar& rhs) //
                {
                    return scalar_add<TRecVar, TRecVar, TRecVar>(lhs, rhs);
                });
}

template <class TRecVar>
auto max(const TRecVar& rv)
{
    TRecVar init(std::numeric_limits<typename TRecVar::int_t>::min());
    return fold(rv,
                init,
                [](const TRecVar& a, const TRecVar& b) //
                {
                    return scalar_max<TRecVar>(a, b);
                });
}

template <class TRecVar>
auto min(const TRecVar& rv)
{
    TRecVar init(std::numeric_limits<typename TRecVar::int_t>::max());
    return fold(rv,
                init,
                [](const TRecVar& a, const TRecVar& b) //
                {
                    return scalar_min<TRecVar, TRecVar>(a, b);
                });
}

template <class TRecVarA, class TRecVarB>
TRecVarA scalar_scale(const TRecVarA& a, const TRecVarB& b)
{
    if(holds_vector(a))
    {
        return transform_leaf([](const auto& x, const auto& y) //
                              {
                                  return scalar_scale(x, y);
                              },
                              a,
                              b);
    }
    else
    {
        return scalar_mul<TRecVarA, TRecVarA, TRecVarB>(a, product(b));
    }
}

template <class TRVRet, class TRV0, class TRV1>
TRVRet inner_product(const TRV0& t0, const TRV1& t1, const bool follow_profile)
{
    if(!follow_profile)
        // The return type is TRV0
        return sum(transform_leaf([](const TRV0& lhs, const TRV1& rhs) //
                                  {
                                      return scalar_mul<TRVRet, TRV0, TRV1>(lhs, rhs);
                                  },
                                  t0,
                                  t1));
    // For layout_eval for example, we need to follow t0's profile
    auto t         = transform_leaf([](const TRV0& lhs, const TRV1& rhs) //
                            {
                                return scalar_mul<TRVRet, TRV0, TRV1>(lhs, rhs);
                            },
                            t0,
                            t1);
    using result_t = decltype(t);
    return fold_with_profile(t,
                             t0,
                             result_t{},
                             [](const result_t& lhs, const result_t& rhs) //
                             {
                                 // lhs and rhs are not necessarily scalars here
                                 return arith_tuple_sum<result_t>(lhs, rhs);
                             });
}

template <class TShapeA, class TShapeB>
TShapeA shape_div(const TShapeA& a, const TShapeB& b)
{
    if(b == 0) return cg_error_t{};
    if(holds_vector(a))
    {
        if(holds_vector(b))
        {
            // (a, b) = (tuple, tuple)
            return transform_leaf([](const auto& x, const auto& y) //
                                  {
                                      return shape_div(x, y);
                                  },
                                  a,
                                  b);
        }
        else
        {
            // (a, b) = (tuple, int)
            auto    bval = b;
            TShapeA r;
            std::for_each(a.begin(),
                          a.end(),
                          [&](const auto& v) //
                          {
                              r.append(shape_div(v, bval));
                              bval = shape_div(bval, product(v));
                          });
            return r;
        }
    }
    else
    {
        if(holds_vector(b))
        {
            // (a, b) = (int, tuple)
            return shape_div(a, product(b));
        }
        else
        {
            // (a, b) = (int, int)
            if(!holds_int_like(a) || !holds_int_like(b)) return cg_error_t{};
            // Return (a / b), rounding away from zero for cases when abs(a) < abs(b)
            // Check in the static case that this shape_div is well-posed
            if(holds_int(a) && holds_int(b))
            {
                if((a.as_int() % b.as_int() != 0) && (b.as_int() % a.as_int() != 0))
                    return cg_error_t{};
            }
            const auto a_div_b = scalar_div<TShapeB>(a, b);
            return cond_assign(
                detail::scalar_cmp<TShapeA, TShapeA, comp_pred::ne>(a_div_b, 0),
                [=]() -> TShapeA { return a_div_b; },
                [=]() -> TShapeA { return scalar_mul<TShapeA, TShapeA, TShapeB>(detail::signum(a), detail::signum(b)); });
        }
    }
}

template <class TShapeA, class TShapeB>
TShapeA shape_min(const TShapeA& a, const TShapeB& b)
{
    if(!holds_leaf(a) || !holds_leaf(b)) return cg_error_t{};
    // For CuTe shapes, 1 is the minimal shape element so preserve any static 1
    if((a == 1) || (b == 1)) return 1;
    return scalar_min<TShapeA, TShapeA, TShapeB>(a, b);
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto size(const TRecVar& rv)
{
    if(!is_int_or_dynamic_int_only(rv)) return TRecVar(cg_error_t{});
    return product(rv);
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto size(const TRecVar& rv, size_t idx)
{
    assert(idx < rank(rv));
    return size(rv[idx]);
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
typename TRecVar::int_t static_size(const TRecVar& rv)
{
    assert(is_integral_only(rv));
    auto res = size(rv);
    assert(holds_int(res));
    return res.as_int();
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
auto static_size(const TRecVar& rv, size_t idx)
{
    assert(idx < rank(rv));
    assert(is_integral_only(rv[idx]));
    auto res = size(rv, idx);
    assert(holds_int(res));
    return res.as_int();
}

template <typename TRecVar, typename TContainer>
auto permute(const TRecVar& rv, const TContainer& order)
{
    if(holds_leaf(rv)) return rv;
    TRecVar rv_permute;
    for(auto i : order)
    {
        rv_permute.append(rv[i]);
    }
    return rv_permute;
}

template <class TRecVarA,
          class TRecVarB,
          std::enable_if_t<is_rec_var<TRecVarA>::value, bool>,
          std::enable_if_t<is_rec_var<TRecVarB>::value, bool>>
TRecVarA ceil_div(const TRecVarA& target, const TRecVarB& tiler)
{
    if(holds_vector(target))
    {
        if(holds_vector(tiler))
        {
            // tuple/tuple
            if(rank(target) < rank(tiler)) return cg_error_t{};
            TRecVarA res = target;
            // tiler[i] for i >= rank(tiler) is considered as `1` (short-cut as nop)
            for(size_t i = 0; i < std::min(rank(target), rank(tiler)); i++)
            {
                res[i] = ceil_div(target[i], tiler[i]);
            }
            return res;
        }
        // tuple/scalar
        TRecVarA res;
        auto     new_tiler = tiler;
        for(const auto& x : target)
        {
            res.append(ceil_div(x, new_tiler));
            new_tiler = ceil_div(new_tiler, x);
        }
        return res;
    }
    if(holds_vector(tiler))
    {
        // scalar/tuple
        return ceil_div(target, product(tiler));
    }
    // scalar/scalar
    return scalar_ceil_div<TRecVarA>(target, tiler);
}

template <class TRecVar>
typename TRecVar::int_t gcd(const TRecVar& a)
{
    if(holds_vector(a))
    {
        typename TRecVar::int_t res = 0;
        for(const auto& x : a)
            res = std::gcd(res, gcd(x));
        return res;
    }

    assert(is_int_or_dynamic_int_only(a));

    if(holds_int(a))
        return a.as_int();

    return 1;
}

template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
std::optional<bool> eq_op_can_fold(const TRecVar& lhs, const TRecVar& rhs)
{
    using eq_comp_container_t = std::vector<detail::eq_comp_t>;
    using eq_comp_res_t       = detail::eq_comp_result_t<eq_comp_container_t>;
    eq_comp_res_t cmp_check   = detail::check_equality<eq_comp_container_t>(lhs, rhs);
    if(std::holds_alternative<bool>(cmp_check))
        return std::get<bool>(cmp_check);
    return std::nullopt;
}

template <class TStride,
          class TTuple,
          std::enable_if_t<is_rec_var<TTuple>::value, bool>>
auto make_basis_like(const TTuple& tup)
{
    using sb_t     = typename find_scaled_basis_in_rec_var<TStride>::value;
    using vector_t = typename sb_t::vector_t;
    if(!holds_vector(tup)) return TStride(1);
    vector_t modes;
    return detail::make_basis_like<TStride>(tup, modes);
}

template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
TRecVar without_codegen(const TRecVar& rv)
{
    return transform_leaf([](const TRecVar& leaf) -> TRecVar {
        return leaf.visit(detail::without_codegen_leaf_visitor<TRecVar>{});
    },
                          rv);
}

} // namespace cutegen
#endif // CUTEGEN_REC_VAR_ALGORITHMS_HPP_INCLUDED_
