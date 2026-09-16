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

#if !defined(MLIR_DYNAMIC_HPP_INCLUDED_)
#define MLIR_DYNAMIC_HPP_INCLUDED_

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/dynamic.hpp"

namespace cutegen
{
// Forward declaration of dynamic_listener
class dynamic_listener;

/**
 * @brief Dynamic integer MLIR values.
 *
 * This struct implements a CuTe element (shape, stride, layout,...) not known at compile-time, i.e.
 * at kernel generation time. It holds an MLIR value and a pointer to a dynamic_listener. Note that,
 * if cutegen's layouts are used as MLIR types, the @a value member is not tracked, i.e. it is not
 * in the def-use chains.
 */
struct mlir_dynamic_t : dynamic_t
{
public:
    using value_t = mlir::Value;

    constexpr mlir_dynamic_t();
    explicit mlir_dynamic_t(int32_t width_);
    mlir_dynamic_t(const dynamic_int_properties_t& prop);
    mlir_dynamic_t(const mlir::Value value_, const dynamic_listener* listener_);
    mlir_dynamic_t(const dynamic_t&        d,
                   const mlir::Value       value_,
                   const dynamic_listener* listener_);
    mlir_dynamic_t(const dynamic_int_properties_t& prop,
                   const mlir::Value               value_,
                   const dynamic_listener*         listener_);
    explicit mlir_dynamic_t(dynamic_t d);
    /**
     * @brief Equality operator.
     *
     * @param b The `mlir_dynamic_t` compared to
     * @return  True
     */
    bool        operator==(const mlir_dynamic_t& b) const;
    bool        operator!=(const mlir_dynamic_t& b) const;
    bool        is_null() const;
    mlir::Value get_value() const;
    void        nullify();
    /**
     * @brief Return a copy of this instance, but with code generation state
     *        cleared, so that traced functions do not generate code.
     */
    mlir_dynamic_t without_codegen() const;

public:
    mlir::Value             value;
    const dynamic_listener* listener;
};

/**
 * @brief Dynamic pointer MLIR values.
 *
 * This struct implements a pointer not known at compile-time, i.e. at kernel
 * generation time. It holds an MLIR value and a pointer to a dynamic_listener.
 */
struct mlir_dynamic_ptr_t : dynamic_ptr_t
{
public:
    using value_t = mlir::Value;
    using width_t = dynamic_ptr_t::width_t;
    using align_t = dynamic_ptr_t::align_t;

    constexpr mlir_dynamic_ptr_t();
    explicit mlir_dynamic_ptr_t(width_t w);
    mlir_dynamic_ptr_t(width_t w, align_t a);
    mlir_dynamic_ptr_t(const dynamic_ptr_t&    d,
                       mlir::Value             value_,
                       const dynamic_listener* listener_);
    mlir_dynamic_ptr_t(dynamic_ptr_t p);

    /**
     * @brief Equality operator.
     *
     * @param b The `mlir_dynamic_ptr_t` compared to
     * @return  true if rhs has same width, alignment
     */
    bool        operator==(const mlir_dynamic_ptr_t& b) const;
    bool        operator!=(const mlir_dynamic_ptr_t& b) const;
    bool        is_null() const;
    mlir::Value get_value() const;
    void        nullify();
    /**
     * @brief Return a copy of this instance, but with code generation state
     *        cleared, so that traced functions do not generate code.
     */
    mlir_dynamic_ptr_t without_codegen() const;

public:
    mlir::Value             value;
    const dynamic_listener* listener;
};

/**
 * @brief Dynamic MLIR listener.
 *
 * This class holds a pointer to an MLIR Op builder. During transformation or lowering phases,
 * layouts holding dynamic elements must be initialized first. The `value` member of each dynamic_t
 * must be set to the appropriate one and the `listener` member to a single dynamic_listener. The
 * dynamic_listener in turn has a @a builder member pointing to the Op builder available during the
 * transformation or conversion pass. When performing scalar operations involving at least one
 * dynamic element, the latter uses its `listener` which in turn invokes the builder to emit MLIR.
 * The resulting code is evaluated at runtime to perform the required layout computations.
 *
 * Currently, the `arith` dialect is used because the tests rely on constant folding which is not
 * implemented by the `llvm` dialect.
 */
class dynamic_listener
{
public:
    dynamic_listener();
    // Here `loc` is an optional param. When it is not set, using loc of parent region of builder insert point of block.
    // While sometimes loc of parent region is uninitialized when an op with region inside(e.g. scf::IfOp, scf::WhileOp,
    // cutlass::AsyncExecOp) is creating(at OpTy::build). In that case, caller must explicitly pass a valid loc param.
    dynamic_listener(mlir::OpBuilder* builder_, std::optional<mlir::Location> loc_ = std::nullopt);
    dynamic_listener(mlir::ImplicitLocOpBuilder& b);

    mlir::MLIRContext* get_ctx() const;
    mlir::Location     get_loc() const;
    mlir::OpBuilder*   get_builder() const;
    template <class TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    mlir::Value emit_constant(TInt i) const;
    template <class TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    mlir::Value emit_constant_with_width(TInt i, int32_t width) const;

    // do_abs()
    static mlir::Value do_abs(const mlir_dynamic_t& x);

private:
    // For each binary operation, three cases to consider:
    //   1. dynamic  / integral
    //   2. integral / dynamic
    //   3. dynamic  / dynamic
    // 1 and 2 are redundant for commutative operations.

    // emit_generic_unary()
    template <class Op>
    mlir::Value emit_generic_unary(const mlir_dynamic_t& d) const;

    mlir::OpBuilder*              builder;
    std::optional<mlir::Location> loc;
};

/**
 * @brief Return an MLIR Value with an integer type of the given width,
 *        emitting trunc/sign extension operations as necessary.
 *
 * This function returns an MLIR Value with an integer type of the width
 * argument. If the input Value already has the required width, it is
 * returned. Otherwise, operations are emitted to convert the value to
 * the given bit width. No bounds checking is performed.
 */
mlir::Value cast_integral_value(mlir::Location    loc,
                                mlir::OpBuilder*  builder,
                                const mlir::Value val,
                                const int         width);

////////////////////////////////////////////////////////////////////////
// scalar_add()
template <class TRet>
TRet scalar_add(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_add(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_sub()
template <class TRet>
TRet scalar_sub(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_sub(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_mod()
template <class TRet>
TRet scalar_mod(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mod(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mod(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_div()
template <class TRet>
TRet scalar_div(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_div(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_div(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_mul()
template <class TRet>
TRet scalar_mul(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_mul(TInt lhs, const mlir_dynamic_t& rhs);
template <class TRet>
TRet scalar_mul(const ratio& lhs, const mlir_dynamic_t& rhs);
template <class TRet>
TRet scalar_mul(const mlir_dynamic_t& lhs, const ratio& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_min()
template <class TRet>
TRet scalar_min(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_min(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_min(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_max()
template <class TRet>
TRet scalar_max(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_max(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_max(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_ceil_div()
template <class TRet, bool forceUnsigned = false>
TRet scalar_ceil_div(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          bool forceUnsigned = false,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_ceil_div(const mlir_dynamic_t& lhs, TInt rhs);
template <class TRet,
          bool forceUnsigned = false,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
TRet scalar_ceil_div(TInt lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_lshr()
template <class TRet>
TRet scalar_lshr(const mlir_dynamic_t& value, int32_t sh);

////////////////////////////////////////////////////////////////////////
// scalar_shl()
template <class TRet>
TRet scalar_shl(const mlir_dynamic_t& value, int32_t sh);

////////////////////////////////////////////////////////////////////////
// scalar_bitwise_and()
template <class TRet>
TRet scalar_bitwise_and(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_and(const mlir_dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_and(T lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_bitwise_or()
template <class TRet>
TRet scalar_bitwise_or(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_or(const mlir_dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_or(T lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_bitwise_xor()
template <class TRet>
TRet scalar_bitwise_xor(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_xor(const mlir_dynamic_t& lhs, T rhs);
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
TRet scalar_bitwise_xor(T lhs, const mlir_dynamic_t& rhs);

////////////////////////////////////////////////////////////////////////
// scalar_bitwise_not()
template <class TRet>
TRet scalar_bitwise_not(const mlir_dynamic_t& d);

namespace detail
{
// Mappings from the cutegen comp_pred enum to MLIR enum values
template <comp_pred pred>
mlir::arith::CmpIPredicate to_arith_cmpi_predicate();
template <>
inline constexpr mlir::arith::CmpIPredicate to_arith_cmpi_predicate<comp_pred::eq>() { return mlir::arith::CmpIPredicate::eq; }
template <>
inline constexpr mlir::arith::CmpIPredicate to_arith_cmpi_predicate<comp_pred::ne>() { return mlir::arith::CmpIPredicate::ne; }
template <>
inline constexpr mlir::arith::CmpIPredicate to_arith_cmpi_predicate<comp_pred::lt>() { return mlir::arith::CmpIPredicate::slt; }
template <>
inline constexpr mlir::arith::CmpIPredicate to_arith_cmpi_predicate<comp_pred::gt>() { return mlir::arith::CmpIPredicate::sgt; }

// Template function to extract the dynamic listener from a dynamic
// value when the first argument is an instance of mlir_dynamic_t.
template <class T>
const dynamic_listener* get_listener(const mlir_dynamic_t& d, const T&)
{
    return d.listener;
}
// Template function to extract the dynamic listener from a dynamic
// value when the first argument is an integer and the second argument
// is an instance of mlir_dynamic_t.
template <class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
const dynamic_listener* get_listener(TInt, const mlir_dynamic_t& d)
{
    return d.listener;
}

/// Specialization of value_to_string for mlir_dynamic_t
template <>
struct value_to_string<mlir_dynamic_t>
{
    static std::string to_str(const mlir_dynamic_t& d)
    {
        return value_to_string<dynamic_t>::to_str(d);
    }
};

/// Specialization of value_to_string for mlir_dynamic_ptr_t.
template <>
struct value_to_string<mlir_dynamic_ptr_t>
{
    static std::string to_str(const mlir_dynamic_ptr_t& d)
    {
        return value_to_string<dynamic_ptr_t>::to_str(d);
    }
};

/// Specialization of from_chars<> for mlir_dynamic_t and mlir_dynamic_ptr_t types using a common implementation.
template <typename T, typename BaseT>
class cg_from_chars_dynamic_impl
{
public:
    using optional_t = std::optional<T>;
    cg_from_chars_dynamic_impl(const char* first, const char* last, bool must_consume_all)
    {
        cg_from_chars<BaseT> fc(first, last, must_consume_all);
        result_ = fc.parse_result();
        // If the base class parse was successful, initialize a derived class
        // instance using the results.
        if(fc.parse_value().has_value())
            value_ = T(fc.parse_value().value());
    }
    const optional_t&        parse_value() { return value_; }
    const from_chars_result& parse_result() { return result_; }

private:
    from_chars_result result_;
    optional_t        value_;
};

template <>
class cg_from_chars<mlir_dynamic_t> : public cg_from_chars_dynamic_impl<mlir_dynamic_t, dynamic_t>
{
public:
    using cg_from_chars_dynamic_impl<mlir_dynamic_t, cutegen::dynamic_t>::cg_from_chars_dynamic_impl;
};

template <>
class cg_from_chars<mlir_dynamic_ptr_t> : public cg_from_chars_dynamic_impl<mlir_dynamic_ptr_t, dynamic_ptr_t>
{
public:
    using cg_from_chars_dynamic_impl<mlir_dynamic_ptr_t, cutegen::dynamic_ptr_t>::cg_from_chars_dynamic_impl;
};

// Specialization of value_encoder<> for mlir_dynamic_t and mlir_dynamic_ptr_t.
// Encoding is used in MLIR to convert data to an array of bytes, for use with
// hashing to efficiently "unique" types and attributes. For dynamic t types in
// MLIR, we don't expect the MLIR-specific dynamic state (the MLIR Value and the
// dynamic listener) to be set for hashing. (This state is only used for
// lowering.) As such, we do not encode any MLIR state data for mlir_dynamic_t -
// we only store the base class dynamic_t data.
template <typename T, typename BaseT>
struct value_encoder_dynamic_impl
{
    template <class TBuffer>
    static void encode_value(const T& d, TBuffer& buffer)
    {
        // Use the base class (dynamic_t or dynamic_ptr_t) encoder
        value_encoder<BaseT>::encode_value(static_cast<const BaseT&>(d), buffer);
    }
};

template <>
struct value_encoder<mlir_dynamic_t> : value_encoder_dynamic_impl<mlir_dynamic_t, dynamic_t>
{};

template <>
struct value_encoder<mlir_dynamic_ptr_t> : value_encoder_dynamic_impl<mlir_dynamic_ptr_t, dynamic_ptr_t>
{};

// Specialization of value_decoder<> for mlir_dynamic_t.
template <typename T, typename BaseT>
struct value_decoder_dynamic_impl
{
    template <class TIterator>
    static std::optional<T> decode_value(TIterator& it, const TIterator& end)
    {
        // Use the base class (dynamic_t or dynamic_ptr_t) decoder
        auto opt_dyn = decode<BaseT>(it, end);
        if(opt_dyn.has_value())
            return T(opt_dyn.value());
        else
            return std::nullopt;
    }
};

template <>
struct value_decoder<mlir_dynamic_t> : value_decoder_dynamic_impl<mlir_dynamic_t, dynamic_t>
{};

template <>
struct value_decoder<mlir_dynamic_ptr_t> : value_decoder_dynamic_impl<mlir_dynamic_ptr_t, dynamic_ptr_t>
{};

////////////////////////////////////////////////////////////////////////////////
// get_value_with_width()
// Overload for integral types
template <class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
mlir::Value get_value_with_width(mlir::OpBuilder* builder,
                                 mlir::Location   loc,
                                 TInt             c,
                                 int32_t          width)
{
    assert(builder);
    auto intType = mlir::IntegerType::get(builder->getContext(), width);
    auto intAttr = mlir::IntegerAttr::get(intType, c);
    return mlir::arith::ConstantOp::create(*builder, loc, intAttr);
}

////////////////////////////////////////////////////////////////////////////////
// get_value_with_width()
// Overload for mlir_dynamic_t type
inline mlir::Value get_value_with_width(mlir::OpBuilder*      builder,
                                        mlir::Location        loc,
                                        const mlir_dynamic_t& d,
                                        int32_t               width)
{
    mlir::Value v = d.get_value();
    if(d.get_width() != width)
    {
        v = cast_integral_value(loc, builder, v, width);
    }
    return v;
}

////////////////////////////////////////////////////////////////////////////////
// get_value_with_width()
// Overload for MLIR Value type
inline mlir::Value get_value_with_width(mlir::OpBuilder* builder,
                                        mlir::Location   loc,
                                        mlir::Value      v,
                                        int32_t          width)
{
    assert(llvm::isa<mlir::IntegerType>(v.getType()));
    return cast_integral_value(loc, builder, v, width);
}

////////////////////////////////////////////////////////////////////////////////
// do_binary_op()
// Common method used to emit integer operations. This function performs the
// following steps:
// - casts input operands to the operation width (as provided by op_desc)
// - emits the operation
// - casts the operation result to the output width (as provided by op_desc)
//
// TLHS and TRHS must each be one of:
// - mlir_dynamic_t
// - an integral type
// - an MLIR Value
//
// No verification/validation of the correctness of the cast operations is
// performed, as that is expected to be done when generating the op_desc
// structure.
template <class TOp,
          class TLHS,
          class TRHS,
          class... TBuilderArgs>
mlir::Value do_binary_op(mlir::OpBuilder*               builder,
                         mlir::Location                 loc,
                         const detail::arith_op_desc_t& op_desc,
                         const TLHS&                    lhs,
                         const TRHS&                    rhs,
                         TBuilderArgs&&... b_args)
{
    assert(builder);
    // Get MLIR Values for LHS and RHS with the appropriate width, extending/
    // truncating if necessary.
    mlir::Value lhs_value = get_value_with_width(builder, loc, lhs, op_desc.op_width);
    mlir::Value rhs_value = get_value_with_width(builder, loc, rhs, op_desc.op_width);
    assert(lhs_value.getType() == rhs_value.getType());
    // Emit the operation

    mlir::Value result = TOp::create(*builder,
                                     loc,
                                     lhs_value,
                                     rhs_value,
                                     std::forward<TBuilderArgs>(b_args)...);
    // Convert the result if necessary.
    return cast_integral_value(loc, builder, result, op_desc.result_prop.width);
}

template <class TOp,
          class TLHS,
          class TRHS,
          class... TBuilderArgs>
mlir::Value do_binary_op(const detail::arith_op_desc_t op_desc,
                         const TLHS&                   lhs,
                         const TRHS&                   rhs,
                         TBuilderArgs&&... b_args)
{
    // Use the overload for get_listener() to retrieve the listener from either
    // lhs or rhs. (Doing so allows this function to be called with either the
    // first or second argument as an integral value.)
    const dynamic_listener* dl = detail::get_listener(lhs, rhs);
    if(!dl)
    {
        // No listener is attached - return a NULL Value.
        return mlir::Value{};
    }
    // Emit the operation using the listener's builder/loc and return the
    // result.
    return detail::do_binary_op<TOp>(dl->get_builder(),
                                     dl->get_loc(),
                                     op_desc,
                                     lhs,
                                     rhs,
                                     std::forward<TBuilderArgs>(b_args)...);
}

////////////////////////////////////////////////////////////////////////////////
// do_cmp_op()
// Common method used to emit integer comparison operations. This function
// performs the following steps:
// - casts input operands to the operation width (as provided by op_desc)
// - emits the operation
//
// (Unlike do_binary_op, no conversion/casting will be performed on the result
// as the result is expected to have type i1.)
//
// TLHS and TRHS must each be one of:
// - mlir_dynamic_t
// - an integral type
// - an MLIR Value
//
// No verification/validation of the correctness of the cast operations is
// performed, as that is expected to be done when generating the op_desc
// structure.
template <typename TLHS, typename TRHS>
mlir::Value do_cmp_op(mlir::OpBuilder*               builder,
                      mlir::Location                 loc,
                      const detail::arith_op_desc_t& op_desc,
                      mlir::arith::CmpIPredicate     arith_pred,
                      const TLHS&                    lhs,
                      const TRHS&                    rhs)
{
    using CmpIOp = mlir::arith::CmpIOp;

    assert(builder);
    // Get an MLIR Values for LHS and RHS with the appropriate width,
    // extending/truncating if necessary.
    mlir::Value lhs_value = get_value_with_width(builder, loc, lhs, op_desc.op_width);
    mlir::Value rhs_value = get_value_with_width(builder, loc, rhs, op_desc.op_width);
    assert(lhs_value.getType() == rhs_value.getType());
    // Emit the CmpIOp operation
    mlir::Value result = CmpIOp::create(*builder, loc, arith_pred, lhs_value, rhs_value);
    return result;
}

template <typename TLHS, typename TRHS>
mlir::Value do_cmp_op(const detail::arith_op_desc_t& op_desc,
                      mlir::arith::CmpIPredicate     arith_pred,
                      const TLHS&                    lhs,
                      const TRHS&                    rhs)
{
    // Use the overload for get_listener() to retrieve the listener from either
    // lhs or rhs. (Doing so allows this function to be called with either the
    // first or second argument as an integral value.)
    const dynamic_listener* dl = detail::get_listener(lhs, rhs);
    if(!dl)
    {
        // No listener is attached - return a NULL Value.
        return mlir::Value{};
    }
    // Emit the operation using the listener's builder/loc and return the
    // result.
    return detail::do_cmp_op(dl->get_builder(),
                             dl->get_loc(),
                             op_desc,
                             arith_pred,
                             lhs,
                             rhs);
}

} // namespace detail

constexpr mlir_dynamic_t::mlir_dynamic_t() :
    listener(nullptr)
{
}

// explicit
inline mlir_dynamic_t::mlir_dynamic_t(int32_t width_) :
    dynamic_t(width_), listener(nullptr)
{
}

inline mlir_dynamic_t::mlir_dynamic_t(const dynamic_int_properties_t& prop) :
    dynamic_t(prop),
    value{},
    listener{}
{
}

inline mlir_dynamic_t::mlir_dynamic_t(const mlir::Value       value_,
                                      const dynamic_listener* listener_) :
    dynamic_t(),
    value(value_),
    listener(listener_)
{
    if(value)
    {
        auto valueType = llvm::cast<mlir::IntegerType>(value.getType());
        properties     = properties.with_width(valueType.getWidth());
    }
}

inline mlir_dynamic_t::mlir_dynamic_t(const dynamic_t&        d,
                                      const mlir::Value       value_,
                                      const dynamic_listener* listener_) :
    dynamic_t(d),
    value(value_),
    listener(listener_)
{
    if(value)
    {
        assert(llvm::isa<mlir::IntegerType>(value.getType()));
        assert(properties.width == static_cast<int32_t>(llvm::cast<mlir::IntegerType>(value.getType()).getWidth()));
    }
}

inline mlir_dynamic_t::mlir_dynamic_t(const dynamic_int_properties_t& prop,
                                      const mlir::Value               value_,
                                      const dynamic_listener*         listener_) :
    dynamic_t(prop),
    value(value_),
    listener(listener_)
{
    if(value)
    {
        assert(llvm::isa<mlir::IntegerType>(value.getType()));
        assert(properties.width == static_cast<int32_t>(llvm::cast<mlir::IntegerType>(value.getType()).getWidth()));
    }
}

// explicit
inline mlir_dynamic_t::mlir_dynamic_t(dynamic_t d) :
    dynamic_t(d),
    value{},
    listener{nullptr}
{
}

inline bool mlir_dynamic_t::operator==(const mlir_dynamic_t& b) const
{
    // Check value only will lead to unexpected hash collision.
    return ((dynamic_t::operator==(b)) && (value == b.value));
}

inline bool mlir_dynamic_t::operator!=(const mlir_dynamic_t& b) const
{
    return !(*this == b);
}

inline bool mlir_dynamic_t::is_null() const
{
    return (!value && (listener == nullptr));
}

inline mlir::Value mlir_dynamic_t::get_value() const
{
    return value;
}

inline void mlir_dynamic_t::nullify()
{
    this->value    = mlir::Value();
    this->listener = nullptr;
}

inline mlir_dynamic_t mlir_dynamic_t::without_codegen() const
{
    return mlir_dynamic_t{get_properties()};
}

constexpr mlir_dynamic_ptr_t::mlir_dynamic_ptr_t() :
    listener(nullptr)
{
}

// explicit
inline mlir_dynamic_ptr_t::mlir_dynamic_ptr_t(width_t w) :
    dynamic_ptr_t(w),
    listener(nullptr)
{
}

inline mlir_dynamic_ptr_t::mlir_dynamic_ptr_t(width_t w,
                                              align_t a) :
    dynamic_ptr_t(w, a),
    value{},
    listener{nullptr}
{
}

inline mlir_dynamic_ptr_t::mlir_dynamic_ptr_t(const dynamic_ptr_t&    d,
                                              mlir::Value             value_,
                                              const dynamic_listener* listener_) :
    dynamic_ptr_t(d),
    value(value_),
    listener(listener_)
{
}

inline mlir_dynamic_ptr_t::mlir_dynamic_ptr_t(dynamic_ptr_t p) :
    dynamic_ptr_t(p),
    value{},
    listener{nullptr}
{
}

inline bool mlir_dynamic_ptr_t::operator==(const mlir_dynamic_ptr_t& b) const
{
    // Check value only will lead to unexpected hash collision.
    return ((dynamic_ptr_t::operator==(b)) && (value == b.value));
}

inline bool mlir_dynamic_ptr_t::operator!=(const mlir_dynamic_ptr_t& b) const
{
    return !(*this == b);
}

inline bool mlir_dynamic_ptr_t::is_null() const
{
    return (!value && (listener == nullptr));
}

inline mlir::Value mlir_dynamic_ptr_t::get_value() const
{
    return value;
}

inline void mlir_dynamic_ptr_t::nullify()
{
    this->value    = mlir::Value();
    this->listener = nullptr;
}

inline mlir_dynamic_ptr_t mlir_dynamic_ptr_t::without_codegen() const
{
    return mlir_dynamic_ptr_t{get_properties()};
}

inline auto get_integral_value_bitwidth(const mlir::Value val)
{
    assert(llvm::isa<mlir::IntegerType>(val.getType()));
    return llvm::cast<mlir::IntegerType>(val.getType()).getWidth();
}

/**
 * @brief Return an MLIR Value with an integer type of the given width,
 *        emitting trunc/sign extension operations as necessary.
 *
 * This function returns an MLIR Value with an integer type of the width
 * argument. If the input Value already has the required width, it is
 * returned. Otherwise, operations are emitted to convert the value to
 * the given bit width. No bounds checking is performed.
 */
inline mlir::Value cast_integral_value(mlir::Location    loc,
                                       mlir::OpBuilder*  builder,
                                       const mlir::Value val,
                                       const int         width)
{
    const auto val_width = static_cast<int>(get_integral_value_bitwidth(val));
    if(val_width == width) return val;

    auto intTy = builder->getIntegerType(width);
    if(val_width < width)
    {
        return mlir::arith::ExtSIOp::create(*builder, loc, intTy, val);
    }
    return mlir::arith::TruncIOp::create(*builder, loc, intTy, val);
}

inline mlir::Value cast_integral_value(mlir::ImplicitLocOpBuilder& b,
                                       const mlir::Value           val,
                                       const int                   width)
{
    return cast_integral_value(b.getLoc(), &b, val, width);
}

/**
 * @brief Return an MLIR Value with the given integer type, emitting operations
 *        to truncate or sign extend as necessary.
 *
 * This function returns an MLIR Value with the given integer type. If the input
 * Value already has the desired Type, it is returned. Otherwise, operations are
 * emitted to convert the value to the given bit width. No bounds checking is
 * performed.
 */
inline mlir::Value cast_integral_value_to_type(mlir::OpBuilder&  builder,
                                               mlir::Location    loc,
                                               const mlir::Value val,
                                               mlir::IntegerType dstType)
{
    assert(val.getType().isSignlessInteger());
    assert(dstType.isSignlessInteger());
    if(val.getType() == dstType)
        return val;

    assert(llvm::cast<mlir::IntegerType>(val.getType()).getWidth() != dstType.getWidth());

    if(llvm::cast<mlir::IntegerType>(val.getType()).getWidth() < dstType.getWidth())
    {
        return mlir::arith::ExtSIOp::create(builder, loc, dstType, val);
    }
    return mlir::arith::TruncIOp::create(builder, loc, dstType, val);
}

inline mlir::Value cast_integral_value_to_type(mlir::ImplicitLocOpBuilder& builder,
                                               const mlir::Value           val,
                                               mlir::IntegerType           dstType)
{
    return cast_integral_value_to_type(builder, builder.getLoc(), val, dstType);
}

// Constructor
inline dynamic_listener::dynamic_listener() :
    builder(nullptr)
{
}

// Constructor
inline dynamic_listener::dynamic_listener(mlir::OpBuilder*              builder_,
                                          std::optional<mlir::Location> loc_) :
    builder(builder_),
    loc(loc_)
{
}

// Constructor
inline dynamic_listener::dynamic_listener(mlir::ImplicitLocOpBuilder& b) :
    builder(&b),
    loc(b.getLoc())
{
}

inline mlir::MLIRContext* dynamic_listener::get_ctx() const
{
    return builder->getContext();
}

inline mlir::Location dynamic_listener::get_loc() const
{
    if(loc)
    {
        return loc.value();
    }
    assert(builder);
    mlir::Region* parent = builder->getInsertionBlock()->getParent();
    if(parent)
    {
        return parent->getLoc();
    }
    return builder->getUnknownLoc();
}

inline mlir::OpBuilder* dynamic_listener::get_builder() const
{
    return builder;
}

template <class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
mlir::Value dynamic_listener::emit_constant(TInt i) const
{
    auto int_type = mlir::IntegerType::get(get_ctx(),
                                           std::numeric_limits<static_int_t>::digits + 1);
    auto int_attr = mlir::IntegerAttr::get(int_type, i);
    return mlir::arith::ConstantOp::create(*builder, get_loc(), int_attr);
}

template <class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
mlir::Value dynamic_listener::emit_constant_with_width(TInt i, int32_t width) const
{
    assert(in_range_of_width(i, width));
    auto int_type = mlir::IntegerType::get(get_ctx(), width);
    auto int_attr = mlir::IntegerAttr::get(int_type, i);
    return mlir::arith::ConstantOp::create(*builder, get_loc(), int_attr);
}

inline mlir::Value dynamic_listener::do_abs(const mlir_dynamic_t& x)
{
    using op_t = mlir::math::AbsIOp;
    return x.listener ? x.listener->emit_generic_unary<op_t>(x) : mlir::Value{};
}

template <class Op>
mlir::Value dynamic_listener::emit_generic_unary(const mlir_dynamic_t& d) const
{
    return Op::create(*builder, get_loc(), d.value);
}

template <class TRet>
TRet scalar_add(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using AddIOp                          = mlir::arith::AddIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_add(lhs, rhs);

    // No known/expected error conditions for add operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<AddIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(const mlir_dynamic_t& lhs, TInt rhs)
{
    using AddIOp                          = mlir::arith::AddIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_add(lhs, rhs);
    // No known/expected error conditions for add operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<AddIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_add(TInt lhs, const mlir_dynamic_t& rhs)
{
    using AddIOp                          = mlir::arith::AddIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_add(rhs, lhs);
    // No known/expected error conditions for add operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<AddIOp>(op_desc, lhs, rhs, oflags),
                          rhs.listener);
}

template <class TRet>
TRet scalar_sub(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using SubIOp                          = mlir::arith::SubIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_sub(lhs, rhs);
    // No known/expected error conditions for sub operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<SubIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(const mlir_dynamic_t& lhs, TInt rhs)
{
    using SubIOp                          = mlir::arith::SubIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_sub(lhs, rhs);
    // No known/expected error conditions for sub operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<SubIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_sub(TInt lhs, const mlir_dynamic_t& rhs)
{
    using SubIOp                          = mlir::arith::SubIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_sub(lhs, rhs);
    // No known/expected error conditions for sub operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<SubIOp>(op_desc, lhs, rhs, oflags),
                          rhs.listener);
}

template <class TRet>
TRet scalar_mod(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using RemSIOp                         = mlir::arith::RemSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<RemSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mod(const mlir_dynamic_t& lhs, TInt rhs)
{
    using RemSIOp                         = mlir::arith::RemSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<RemSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mod(TInt lhs, const mlir_dynamic_t& rhs)
{
    using RemSIOp                         = mlir::arith::RemSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_mod(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<RemSIOp>(op_desc, lhs, rhs),
                          rhs.listener);
}

template <class TRet>
TRet scalar_div(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using DivSIOp                         = mlir::arith::DivSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<DivSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_div(const mlir_dynamic_t& lhs, TInt rhs)
{
    using DivSIOp                         = mlir::arith::DivSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<DivSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_div(TInt lhs, const mlir_dynamic_t& rhs)
{
    using DivSIOp                         = mlir::arith::DivSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 1);
        return rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<DivSIOp>(op_desc, lhs, rhs),
                          rhs.listener);
}

template <class TRet>
TRet scalar_mul(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using MulIOp                          = mlir::arith::MulIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_mul(lhs, rhs);

    // No known/expected error conditions for mul operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<MulIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(const mlir_dynamic_t& lhs, TInt rhs)
{
    using MulIOp                          = mlir::arith::MulIOp;
    using IntegerOverflowFlags            = mlir::arith::IntegerOverflowFlags;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_mul(lhs, rhs);
    // No known/expected error conditions for mul operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    // Return a static integer if possible
    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    // Until/unless we incorporate range analysis/annotation, we simply assume
    // that cutegen behavior is undefined if integer operations overflow.
    IntegerOverflowFlags oflags = IntegerOverflowFlags::nsw;
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<MulIOp>(op_desc, lhs, rhs, oflags),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_mul(TInt lhs, const mlir_dynamic_t& rhs)
{
    // Swap order of operands as multiplication is symmetric
    return scalar_mul<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_mul(const ratio& lhs, const mlir_dynamic_t& rhs)
{
    auto lhs_red = lhs.reduced();
    if(std::holds_alternative<ratio::int_t>(lhs_red))
    {
        return scalar_mul<TRet>(std::get<ratio::int_t>(lhs_red), rhs);
    }
    assert(std::holds_alternative<ratio>(lhs_red));
    auto& lhs_ratio = std::get<ratio>(lhs_red);
    using var_t     = std::variant<static_int_t, mlir_dynamic_t, cg_error_t>;
    auto prod       = scalar_mul<var_t>(lhs_ratio.num(), rhs);
    // If the product is a static integer, perform integer division directly
    if(std::holds_alternative<static_int_t>(prod))
    {
        // See comments below about using the return type here.
        //return scalar_div<TRet>(std::get<static_int_t>(prod), lhs_ratio.denom());
        return std::get<static_int_t>(prod) / lhs_ratio.denom();
    }
    // The ratio type is currently limited to static numerator/denominator
    // values, so we return a dynamic value here that is the result of a
    // (truncating) division.
    // Note: We can't use the return type TRet directly as scaled basis values
    // do not support the error type, and scalar_div can return an error (if,
    // for example, lhs.denom() is zero).
    assert(std::holds_alternative<mlir_dynamic_t>(prod));
    auto quot = scalar_div<var_t>(std::get<mlir_dynamic_t>(prod), lhs.denom());
    if(std::holds_alternative<cg_error_t>(quot))
    {
        assert(false);
        return 0;
    }
    if(std::holds_alternative<static_int_t>(quot))
    {
        return std::get<static_int_t>(quot);
    }
    return std::get<mlir_dynamic_t>(quot);
}

template <class TRet>
TRet scalar_mul(const mlir_dynamic_t& lhs, const ratio& rhs)
{
    // Multiplication is symmetric
    return scalar_mul<TRet>(rhs, lhs);
}

template <class TRet>
TRet scalar_min(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using MinSIOp                         = mlir::arith::MinSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_min(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<MinSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_min(const mlir_dynamic_t& lhs, TInt rhs)
{
    using MinSIOp                         = mlir::arith::MinSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_min(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<MinSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_min(TInt lhs, const mlir_dynamic_t& rhs)
{
    return scalar_min(rhs, lhs);
}

template <class TRet>
TRet scalar_max(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using MaxSIOp                         = mlir::arith::MaxSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_max(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<MaxSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_max(const mlir_dynamic_t& lhs, TInt rhs)
{
    using MaxSIOp                         = mlir::arith::MaxSIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_max(lhs, rhs);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    auto& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<MaxSIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_max(TInt lhs, const mlir_dynamic_t& rhs)
{
    return scalar_max<TRet>(rhs, lhs);
}

template <class TRet, bool forceUnsigned>
TRet scalar_ceil_div(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using CeilDivOp    = std::conditional_t<forceUnsigned, mlir::arith::CeilDivUIOp, mlir::arith::CeilDivSIOp>;
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<CeilDivOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          bool forceUnsigned,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_ceil_div(const mlir_dynamic_t& lhs, TInt rhs)
{
    using CeilDivOp    = std::conditional_t<forceUnsigned, mlir::arith::CeilDivUIOp, mlir::arith::CeilDivSIOp>;
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<CeilDivOp>(op_desc, lhs, rhs),
                          lhs.listener);
}

template <class TRet,
          bool forceUnsigned,
          typename TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool>>
TRet scalar_ceil_div(TInt lhs, const mlir_dynamic_t& rhs)
{
    using CeilDivOp    = std::conditional_t<forceUnsigned, mlir::arith::CeilDivUIOp, mlir::arith::CeilDivSIOp>;
    using prop_policy  = dynamic_t::property_policy_t;
    auto arith_resolve = prop_policy::resolve_ceil_div(lhs, rhs);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Not checking for arith_resolve holding src_operand_index_t here,
    // as we don't expect ceil_div() to ever return the divisor...

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(op_desc.result_prop,
                          detail::do_binary_op<CeilDivOp>(op_desc, lhs, rhs),
                          rhs.listener);
}

/**
 * @brief Logical shift right for dynamic values
 *
 * Shifting a number of bits greater than or equal to the value width results in
 * an error.
 */
template <class TRet>
TRet scalar_lshr(const mlir_dynamic_t& value, int32_t sh)
{
    // Follow the behavior of LLVM here: shifting a number of bits greater than
    // or equal to the number of bits in the value is an error.
    if(safe_abs(sh) >= static_cast<uint32_t>(value.get_width()))
        return cg_error_t{};

    if(sh < 0)
    {
        return scalar_shl<TRet>(value, -sh);
    }
    // We emit the unsigned shift right operation, as it reflects the behavior
    // of lshr (logical shift right). In contrast, ShrSIOp lowers to an LLVM
    // arithmetic shift, which will sign extend the input operand.
    using property_policy                 = dynamic_t::property_policy_t;
    using ShRUIOp                         = mlir::arith::ShRUIOp;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_lshr(value, sh);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        assert(0 == std::get<detail::src_operand_index_t>(arith_resolve).index);
        return value;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    mlir::Value              result{};
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    if(value.listener)
    {
        assert(value.get_value()); // expect non-null Value with non-null listener
        auto b        = value.listener->get_builder();
        auto loc      = value.listener->get_loc();
        auto shiftVal = detail::get_value_with_width(b, loc, sh, op_desc.op_width);
        result = ShRUIOp::create(*b, loc, value.get_value(), shiftVal);
    }
    return mlir_dynamic_t(op_desc.result_prop,
                          result,
                          value.listener);
}

/**
 * @brief Shift left for dynamic values
 *
 * Shifting a number of bits greater than or equal to the value width results in
 * an error.
 */
template <class TRet>
TRet scalar_shl(const mlir_dynamic_t& value, int32_t sh)
{
    // Follow the behavior of LLVM here: shifting a number of bits greater than
    // or equal to the number of bits in the value is an error.
    if(safe_abs(sh) >= static_cast<uint32_t>(value.get_width()))
        return cg_error_t{};

    if(sh < 0)
    {
        return scalar_lshr<TRet>(value, -sh);
    }

    using property_policy                 = dynamic_t::property_policy_t;
    using ShLIOp                          = mlir::arith::ShLIOp;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_shl(value, sh);

    if(std::holds_alternative<cg_error_t>(arith_resolve))
        return cg_error_t{};

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        assert(0 == std::get<detail::src_operand_index_t>(arith_resolve).index);
        return value;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    mlir::Value              result{};
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    if(value.listener)
    {
        assert(value.get_value()); // expect non-null Value with non-null listener
        auto b        = value.listener->get_builder();
        auto loc      = value.listener->get_loc();
        auto shiftVal = detail::get_value_with_width(b, loc, sh, op_desc.op_width);
        result = ShLIOp::create(*b, loc, value.get_value(), shiftVal);
    }
    return mlir_dynamic_t(op_desc.result_prop,
                          result,
                          value.listener);
}

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_and(const mlir_dynamic_t& lhs, T rhs)
{
    using AndIOp                          = mlir::arith::AndIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_and(lhs, rhs);
    // No known/expected error conditions for bitwise and operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<AndIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_and(T lhs, const mlir_dynamic_t& rhs)
{
    // Swap operand order as bitwise and is symmetric
    return scalar_bitwise_and(rhs, lhs);
}
template <class TRet>
TRet scalar_bitwise_and(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using AndIOp                          = mlir::arith::AndIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_and(lhs, rhs);
    // No known/expected error conditions for bitwise and operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<AndIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}

template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_or(const mlir_dynamic_t& lhs, T rhs)
{
    using OrIOp                           = mlir::arith::OrIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_or(lhs, rhs);
    // No known/expected error conditions for bitwise or operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<OrIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_or(T lhs, const mlir_dynamic_t& rhs)
{
    // Swap operands to reuse function above, as bitwise operation is symmetric
    return scalar_bitwise_or(rhs, lhs);
}
template <class TRet>
TRet scalar_bitwise_or(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using OrIOp                           = mlir::arith::OrIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_or(lhs, rhs);
    // No known/expected error conditions for bitwise or operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<OrIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_xor(const mlir_dynamic_t& lhs, T rhs)
{
    using XOrIOp                          = mlir::arith::XOrIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_xor(lhs, rhs);
    // No known/expected error conditions for bitwise xor operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        [[maybe_unused]] auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert(src_op.index == 0);
        return lhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<XOrIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}
template <class TRet,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool>>
TRet scalar_bitwise_xor(T lhs, const mlir_dynamic_t& rhs)
{
    // Swap operand order as xor operation is symmetric
    return scalar_bitwise_xor(rhs, lhs);
}
template <class TRet>
TRet scalar_bitwise_xor(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
{
    using XOrIOp                          = mlir::arith::XOrIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_xor(lhs, rhs);
    // No known/expected error conditions for bitwise xor operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Return one of the source operands
    if(std::holds_alternative<detail::src_operand_index_t>(arith_resolve))
    {
        auto src_op = std::get<detail::src_operand_index_t>(arith_resolve);
        assert((src_op.index == 0) || (src_op.index == 1));
        return (0 == src_op.index) ? lhs : rhs;
    }

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<XOrIOp>(op_desc, lhs, rhs),
                          lhs.listener);
}

template <class TRet>
TRet scalar_bitwise_not(const mlir_dynamic_t& d)
{
    // Perform bitwise not by emitting an xor operation with an "all ones"
    // constant value.
    using XOrIOp                          = mlir::arith::XOrIOp;
    using property_policy                 = dynamic_t::property_policy_t;
    detail::arith_resolve_t arith_resolve = property_policy::resolve_bitwise_not(d);
    // No known/expected error conditions for bitwise not operation
    assert(!std::holds_alternative<cg_error_t>(arith_resolve));

    if(std::holds_alternative<static_int_t>(arith_resolve))
        return std::get<static_int_t>(arith_resolve);

    // Not expecting to return the source operand directory for bitwise not
    assert(!std::holds_alternative<detail::src_operand_index_t>(arith_resolve));

    assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
    detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);

    // Determine the "all ones" static constant corresponding to the width
    // of the result
    static_int_t all_ones = (static_int_bitwidth() == op_desc.op_width) ?
                                std::numeric_limits<static_int_t>::max() :
                                ((static_cast<static_int_t>(1) << op_desc.op_width) - 1);
    return mlir_dynamic_t(dynamic_t{op_desc.result_prop},
                          detail::do_binary_op<XOrIOp>(op_desc, d, all_ones),
                          d.listener);
}

////////////////////////////////////////////////////////////////////////////////
// specialization of comparison operations for mlir_dynamic_t
template <comp_pred pred>
struct compare<mlir_dynamic_t, pred>
{
private:
    template <class TLHS, class TRHS>
    static detail::arith_resolve_t resolve_pred_dispatch(const TLHS& lhs, const TRHS& rhs)
    {
        using prop_policy = dynamic_t::property_policy_t;
        if constexpr(pred == comp_pred::eq)
        {
            return prop_policy::resolve_cmp_eq(lhs, rhs);
        }
        else
            // Currently no other comparison operators have resolve
            // implementations.
            return prop_policy::resolve_cmp_default(lhs, rhs);
    }

public:
    static constexpr mlir::arith::CmpIPredicate arith_pred = detail::to_arith_cmpi_predicate<pred>();
    using property_policy                                  = dynamic_t::property_policy_t;
    using base_result_t                                    = std::variant<bool, dynamic_t>;
    using result_t                                         = std::variant<bool, mlir_dynamic_t>;

    // Forward operator() with integral arguments to the integral template
    // specialization so that this struct can also be used for int/int operand
    // pairs.
    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    result_t operator()(const TInt lhs, TInt rhs)
    {
        return compare<TInt, pred>{}(lhs, rhs);
    }
    template <class TR, std::enable_if_t<std::is_integral_v<TR>, bool> = true>
    result_t operator()(const mlir_dynamic_t& lhs, TR rhs)
    {
        // Check for a static result based on dynamic properties
        detail::arith_resolve_t arith_resolve = resolve_pred_dispatch(lhs, rhs);

        // No known/expected error conditions for compariton operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return mlir_dynamic_t(op_desc.result_prop,
                              detail::do_cmp_op(op_desc, arith_pred, lhs, rhs),
                              lhs.listener);
    }

    template <class TL, std::enable_if_t<std::is_integral_v<TL>, bool> = true>
    result_t operator()(TL lhs, const mlir_dynamic_t& rhs)
    {
        // Check for a static result based on dynamic properties
        detail::arith_resolve_t arith_resolve = resolve_pred_dispatch(lhs, rhs);

        // No known/expected error conditions for compariton operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return mlir_dynamic_t(op_desc.result_prop,
                              detail::do_cmp_op(op_desc, arith_pred, lhs, rhs),
                              rhs.listener);
    }

    result_t operator()(const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs)
    {
        // Check for a static result based on dynamic properties
        detail::arith_resolve_t arith_resolve = resolve_pred_dispatch(lhs, rhs);

        // No known/expected error conditions for compariton operators
        assert(!std::holds_alternative<cg_error_t>(arith_resolve));

        // Interpret static 0 as false and any other value (typically 1) as true
        if(std::holds_alternative<static_int_t>(arith_resolve))
            return (0 != std::get<static_int_t>(arith_resolve)) ? true : false;

        assert(std::holds_alternative<detail::arith_op_desc_t>(arith_resolve));
        detail::arith_op_desc_t& op_desc = std::get<detail::arith_op_desc_t>(arith_resolve);
        return mlir_dynamic_t(op_desc.result_prop,
                              detail::do_cmp_op(op_desc, arith_pred, lhs, rhs),
                              lhs.listener);
    }
};

////////////////////////////////////////////////////////////////////////////////
// get_compare_value()
// Returns an MLIR Value that represents the result of the comparison, even if
// the comparison is statically known to be true or false. Either lhs or rhs
// must be an instance of mlir_dynamic_t. One of lhs or rhs may be an integral
// value. Operands of type mlir_dynamic_t must have non-NULL dynamic listeners.
//
// This is useful when calling code does not wish to handle the statically known
// case.
template <comp_pred pred, class TLHS, class TRHS>
mlir::Value get_compare_value(const TLHS& lhs, const TRHS& rhs)
{
    const dynamic_listener* dl = detail::get_listener(lhs, rhs);
    assert(dl);
    using result_t = std::variant<bool, mlir_dynamic_t>;
    compare<mlir_dynamic_t, pred> cmp;
    result_t                      r = cmp(lhs, rhs);

    if(std::holds_alternative<bool>(r))
    {
        mlir::OpBuilder* b       = dl->get_builder();
        mlir::Location   loc     = dl->get_loc();
        bool             bResult = std::get<bool>(r);
        auto             intAttr = mlir::IntegerAttr::get(b->getI1Type(), bResult);
        return mlir::arith::ConstantOp::create(*b, loc, intAttr);
    }
    else
    {
        assert(std::holds_alternative<mlir_dynamic_t>(r));
        assert(dl->get_builder()->getI1Type() == std::get<mlir_dynamic_t>(r).get_value().getType());
        return std::get<mlir_dynamic_t>(r).get_value();
    }
}

inline std::ostream& operator<<(std::ostream& os, const mlir_dynamic_t& u)
{
    os << to_string(u);
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const mlir_dynamic_ptr_t& u)
{
    os << to_string(u);
    return os;
}

} // namespace cutegen

#endif // !defined(MLIR_DYNAMIC_HPP_INCLUDED_)
