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

#if !defined(CUTEGEN_MLIR_HPP_INCLUDED_)
#define CUTEGEN_MLIR_HPP_INCLUDED_

#include <iostream>

#include "llvm/ADT/TypeSwitch.h"
#include "llvm/ADT/Hashing.h"

#include "mlir/IR/Builders.h"                // mlir::OpBuilder
#include "mlir/IR/ImplicitLocOpBuilder.h"    // mlir::ImplicitLocOpBuilder
#include "mlir/IR/Value.h"                   // mlir::Value
#include "mlir/Dialect/Math/IR/Math.h"       // mlir::math::AbsIOp
#include "mlir/Dialect/Arith/IR/Arith.h"     // mlir::arith::ConstantOp
#include "mlir/Dialect/LLVMIR/LLVMTypes.h"   // mlir::LLVM::LLVMStructType
#include "mlir/Dialect/SCF/IR/SCF.h"         // dynamic conditional support
#include "mlir/Dialect/LLVMIR/NVVMDialect.h" // mlir::NVVM::MulOp
#include "mlir/Dialect/UB/IR/UBOps.h"        // mlir::ub::PoisonOp

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/cg_int.hpp"
#include "cutegen/underscore.hpp"
#include "cutegen/mlir_dynamic.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/composed_layout.hpp"
#include "cutegen/visitors.hpp"

#include "cutegen/swizzle.hpp"

namespace cutegen
{
struct mlir_dynamic_traits_t
{
    using dynamic_int_t     = mlir_dynamic_t;
    using dynamic_pointer_t = mlir_dynamic_ptr_t;
};

/**
 * @brief Create an MLIR Type that represents the default static integer type in cutegen.
 *
 * This function returns an MLIR Type for an integer with a bitwidth that matches the
 * the default static integer size in cutegen.
 * Note that in cutegen static integer sizes are constant, but dynamic integer sizes
 * (used in generated code) may not have a fixed bit width, if (for example) an
 * analysis can prove that a smaller bit width can be used.
 */
inline mlir::IntegerType create_static_int_type(mlir::Builder& builder)
{
    return builder.getIntegerType(static_int_bitwidth());
}

/**
 * @brief Create an LLVM generic pointer type (currenrtly only used for indexed stride element).
 */
inline mlir::LLVM::LLVMPointerType create_llvm_pointer_type(mlir::MLIRContext* ctx)
{
    return mlir::LLVM::LLVMPointerType::get(ctx, /* AddressSpace::generic */ 0);
}

template <class TInt,
          std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
mlir_dynamic_t dynamic_from_int(TInt i, const dynamic_listener* lis, int32_t width)
{
    assert(in_range_of_width(i, width));
    assert(lis);
    mlir::Value v = lis->emit_constant_with_width(i, width);
    return mlir_dynamic_t(v, lis);
}

////////////////////////////////////////////////////////////////////////////////
// abs()
/// abs() function for mlir_dynamic_t
inline mlir_dynamic_t abs(const mlir_dynamic_t& x)
{
    return mlir_dynamic_t(abs(static_cast<const dynamic_t&>(x)),
                          dynamic_listener::do_abs(x),
                          x.listener);
}

namespace detail
{

////////////////////////////////////////////////////////////////////////////////
// get_value_with_width()
// Overload for recursive variant types
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
inline mlir::Value get_value_with_width(mlir::OpBuilder* builder,
                                        mlir::Location   loc,
                                        const TRecVar&   rv,
                                        int32_t          width)
{
    assert(holds_int_or_dynamic_int(rv));
    if(holds_int(rv))
    {
        return get_value_with_width(builder, loc, rv.as_int(), width);
    }
    else if(holds_dynamic_int(rv))
    {
        return get_value_with_width(builder, loc, std::get<mlir_dynamic_t>(rv), width);
    }
    else
    {
        return get_value_with_width(builder, loc, -1, width);
    }
}

struct get_or_build_scalar_mlir_value_visitor
{
private:
    mlir::OpBuilder& builder;
    mlir::Location   loc;

    using property_policy = dynamic_t::property_policy_t;

public:
    get_or_build_scalar_mlir_value_visitor(mlir::OpBuilder& builder_, mlir::Location loc_) :
        builder(builder_), loc(loc_) {}
    mlir::Value operator()(int64_t i)
    {
        arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
        return get_value_with_width(&builder,
                                    loc,
                                    i,
                                    op_desc.result_prop.width);
    }
    mlir::Value operator()(int32_t i)
    {
        arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
        return get_value_with_width(&builder,
                                    loc,
                                    i,
                                    op_desc.result_prop.width);
    }
    mlir::Value operator()(uint32_t i)
    {
        // By convention, cutegen adopts signless semantics hence getI32IntegerAttr instead of
        // getSII32IntegerAttr or getUII32IntegerAttr
        return mlir::arith::ConstantOp::create(builder, loc, builder.getI32IntegerAttr(i));
    }
    mlir::Value operator()(const underscore_t& /*rv*/)
    {
        // We currently set underscore to zero, as some arithmetic operations in CuTe C++ do this.
        // However, it may not be necessary or always desired.
        return mlir::arith::ConstantOp::create(builder, loc, builder.getI32IntegerAttr(0));
    }
    mlir::Value operator()(const mlir_dynamic_t& rv)
    {
        return rv.value;
    }
    template <class... TValueTypes>
    mlir::Value operator()(const scaled_basis_t<TValueTypes...>& rv)
    {
        return this->operator()(rv.value());
    }
    mlir::Value operator()(const ratio& /*rv*/)
    {
        // Same reason to below function (two values...).
        assert(false);
        return {};
    }
    template <class TVec>
    mlir::Value operator()(const std::vector<TVec>&)
    {
        assert(false);
        return {};
    }
    mlir::Value operator()(const cg_error_t& /*rv*/)
    {
        assert(false);
        return {};
    }

    template <class... TVarTypes>
    mlir::Value operator()(const std::variant<TVarTypes...>& var)
    {
        return visit(*this, var);
    }
    template <class... Ts>
    mlir::Value operator()(const rec_var_base<Ts...>& rv)
    {
        // Additional check to verify that the recursive variant holds a scalar
        assert(holds_leaf(rv));
        return visit(*this, rv);
    }
};

template <class TRet>
struct get_mlir_values_from_dynamics_visitor
{
private:
    TRet& res;

public:
    get_mlir_values_from_dynamics_visitor(TRet& res_) :
        res(res_) {}

    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    void operator()(TInt) {}
    void operator()(const mlir_dynamic_t& rv)
    {
        res.push_back(rv.value);
    }
    void operator()(const mlir_dynamic_ptr_t& rv)
    {
        res.push_back(rv.value);
    }
    void operator()(const underscore_t&) {}
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& rv)
    {
        if(rv.is_static()) return;
        this->operator()(rv.value());
    }
    void operator()(const ratio&) {}
    void operator()(const cg_error_t&) {}
    template <class TVec>
    void operator()(const std::vector<TVec>& rv)
    {
        for(const auto& x : rv) this->operator()(x);
    }

    void operator()(const layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.shape());
        this->operator()(l.stride());
    }
    void operator()(const composed_layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.layout_b().shape());
        this->operator()(l.layout_b().stride());
        this->operator()(l.offset());
        if(l.is_a_affine())
        {
            this->operator()(l.layout_a().shape());
            this->operator()(l.layout_a().stride());
        }
    }

    template <class... TVarTypes>
    void operator()(const std::variant<TVarTypes...>& var)
    {
        visit(*this, var);
    }
    template <class... Ts>
    void operator()(const rec_var_base<Ts...>& rv)
    {
        visit(*this, rv);
    }
};

struct set_with_mlir_values_visitor
{
private:
    size_t            curr_idx = 0;
    dynamic_listener* lis;
    mlir::ValueRange  values;

public:
    set_with_mlir_values_visitor(dynamic_listener* lis_, mlir::ValueRange values_) :
        lis(lis_), values(values_) {}

    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    void operator()(TInt&) {}
    void operator()(underscore_t&) {}
    void operator()(mlir_dynamic_t& d)
    {
        d = mlir_dynamic_t(static_cast<const dynamic_t&>(d), values[curr_idx], lis);
        curr_idx++;
    }
    void operator()(mlir_dynamic_ptr_t& d)
    {
        d = mlir_dynamic_ptr_t(static_cast<const dynamic_ptr_t&>(d), values[curr_idx], lis);
        curr_idx++;
    }
    template <class... TValueTypes>
    void operator()(scaled_basis_t<TValueTypes...>& sb)
    {
        if(sb.is_static()) return;
        this->operator()(sb.value());
    }
    void operator()(const ratio&) {}
    void operator()(const cg_error_t&) {}
    template <class TVec>
    void operator()(std::vector<TVec>& v)
    {
        for(auto& x : v) this->operator()(x);
    }

    void operator()(layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.shape());
        this->operator()(l.stride());
    }
    void operator()(composed_layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.layout_b().shape());
        this->operator()(l.layout_b().stride());
        this->operator()(l.offset());
        if(l.is_a_affine())
        {
            this->operator()(l.layout_a().shape());
            this->operator()(l.layout_a().stride());
        }
    }

    template <class... TVarTypes>
    void operator()(std::variant<TVarTypes...>& var)
    {
        visit(*this, var);
    }
    template <class... Ts>
    void operator()(rec_var_base<Ts...>& rv)
    {
        visit(*this, rv);
    }
};

struct are_dynamics_null_visitor
{
    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    bool operator()(const TInt&) { return true; }
    bool operator()(const underscore_t&) { return true; }
    bool operator()(const mlir_dynamic_t& d)
    {
        return d.is_null();
    }
    bool operator()(const mlir_dynamic_ptr_t& d)
    {
        return d.is_null();
    }
    template <class... TValueTypes>
    bool operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        if(sb.is_static()) return true;
        return this->operator()(sb.value());
    }
    bool operator()(const ratio&) { return true; }
    bool operator()(const cg_error_t&) { return true; }
    bool operator()(const swizzle&) { return true; }

    template <class TVec>
    bool operator()(const std::vector<TVec>& v)
    {
        for(auto& x : v)
        {
            if(!this->operator()(x)) return false;
        }
        return true;
    }

    bool operator()(const layout_t<mlir_dynamic_traits_t>& l)
    {
        return this->operator()(l.shape()) && this->operator()(l.stride());
    }
    bool operator()(const composed_layout_t<mlir_dynamic_traits_t>& l)
    {
        bool res = this->operator()(l.layout_b().shape()) &&
                   this->operator()(l.layout_b().stride()) &&
                   this->operator()(l.offset());
        if(l.is_a_affine())
        {
            res = res &&
                  this->operator()(l.layout_a().shape()) &&
                  this->operator()(l.layout_a().stride());
        }
        return res;
    }

    template <class... TVarTypes>
    bool operator()(const std::variant<TVarTypes...>& var)
    {
        return visit(*this, var);
    }
    template <class... Ts>
    bool operator()(const rec_var_base<Ts...>& rv)
    {
        return visit(*this, rv);
    }
};

struct nullify_dynamics_visitor
{
public:
    template <class TInt, std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    void operator()(TInt&) {}
    void operator()(underscore_t&) {}
    void operator()(mlir_dynamic_t& d)
    {
        d.nullify();
    }
    void operator()(mlir_dynamic_ptr_t& d)
    {
        d.nullify();
    }
    template <class... TValueTypes>
    void operator()(scaled_basis_t<TValueTypes...>& sb)
    {
        if(sb.is_static()) return;
        this->operator()(sb.value());
    }
    void operator()(const ratio&) {}
    void operator()(const cg_error_t&) {}
    void operator()(const swizzle& sw) {}

    template <class TVec>
    void operator()(std::vector<TVec>& v)
    {
        for(auto& x : v) this->operator()(x);
    }

    void operator()(layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.shape());
        this->operator()(l.stride());
    }
    void operator()(composed_layout_t<mlir_dynamic_traits_t>& l)
    {
        this->operator()(l.layout_b().shape());
        this->operator()(l.layout_b().stride());
        this->operator()(l.offset());
        if(l.is_a_affine())
        {
            this->operator()(l.layout_a().shape());
            this->operator()(l.layout_a().stride());
        }
    }

    template <class... TVarTypes>
    void operator()(std::variant<TVarTypes...>& var)
    {
        visit(*this, var);
    }
    template <class... Ts>
    void operator()(rec_var_base<Ts...>& rv)
    {
        visit(*this, rv);
    }
};

template <class TRet>
struct make_fully_dynamic_visitor
{
private:
    dynamic_listener* lis;

public:
    make_fully_dynamic_visitor(dynamic_listener* lis_) :
        lis(lis_) {}
    TRet operator()(int32_t i)
    {
        return dynamic_from_integer(i);
    }
    TRet operator()(int64_t i)
    {
        return dynamic_from_integer(i);
    }
    TRet operator()(const mlir_dynamic_t& d)
    {
        return mlir_dynamic_t(d.value, d.listener);
    }
    template <class... TValueTypes>
    TRet operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        if(!sb.value_holds_int() && !sb.value_holds_dynamic())
        {
            // Only integers or mlir_dynamic_ts can be transformed
            return cg_error_t{};
        }
        using sb_t  = scaled_basis_t<TValueTypes...>;
        using var_t = typename sb_t::value_variant_t;
        return sb_t(sb.modes(), visit(make_fully_dynamic_visitor<var_t>(lis), sb.value()));
    }
    TRet operator()(const ratio& r)
    {
        // We cannot return cg_error_t{} because the scaled basis value variant type cannot hold an
        // error and we would like to reuse this visitor to walk the value variant types. The only
        // downside with this is that we wouldn't return cg_error_t{} when the top-level recursive
        // variant holds a ratio. This currently never happens.
        assert(false);
        return 0;
    }
    TRet operator()(const underscore_t&)
    {
        return cg_error_t{};
    }
    TRet operator()(const cg_error_t&)
    {
        return cg_error_t{};
    }
    TRet operator()(const std::vector<TRet>& vec)
    {
        TRet res;
        for(auto& e : vec) res.append(this->operator()(e));
        return res;
    }

    TRet operator()(const TRet& rv)
    {
        return visit(*this, rv);
    }

private:
    using ConstantOp = mlir::arith::ConstantOp;

    mlir_dynamic_t dynamic_from_integer(int32_t i)
    {
        if(lis->get_builder() == nullptr)
            return mlir_dynamic_t{};
        mlir::OpBuilder* b   = lis->get_builder();
        mlir::Location   loc = lis->get_loc();
        mlir::Value      v   = ConstantOp::create(*b, loc, b->getI32IntegerAttr(i));
        return mlir_dynamic_t(v, lis);
    }
    mlir_dynamic_t dynamic_from_integer(int64_t i)
    {
        if(lis->get_builder() == nullptr)
            return mlir_dynamic_t{};
        mlir::OpBuilder* b   = lis->get_builder();
        mlir::Location   loc = lis->get_loc();
        // Use i32 for values that fit; fall back to i64 to avoid truncation.
        assert(32 == default_dynamic_int_bitwidth());
        mlir::Value v = in_range<int32_t>(i) ?
                            ConstantOp::create(*b, loc, b->getI32IntegerAttr(static_cast<int32_t>(i))) :
                            ConstantOp::create(*b, loc, b->getI64IntegerAttr(i));
        return mlir_dynamic_t(v, lis);
    }
};
} // namespace detail

/// Conditional assignment for a `std::variant<bool, mlir_dynamic_t>` conditional result.
template <class TFunctorThen, class TFunctorElse>
auto cond_assign(std::variant<bool, mlir_dynamic_t> cond_result,
                 TFunctorThen&&                     then_func,
                 TFunctorElse&&                     else_func)
{
    using result_t        = std::invoke_result_t<TFunctorElse>;
    using property_policy = dynamic_t::property_policy_t;
    using InsertPoint     = mlir::OpBuilder::InsertPoint;
    //--------------------------------------------------------------------------
    // If the conditional result can be statically evaluated, invoke the lambda
    // for the appropriate clause ('then' or 'else').
    if(std::holds_alternative<bool>(cond_result))
    {
        if(std::get<bool>(cond_result))
            return then_func();
        return else_func();
    }
    //--------------------------------------------------------------------------
    // For the dynamic conditional result case, we need to resolve the return
    // type of the IfOp, as the 'then' and 'else' regions may return
    // different integer types. We accomplish this by creating separate
    // temporary blocks for the 'then' and 'else' clauses and examining the
    // result type of each clause before creating the final IfOp.
    auto                         cond_dyn   = std::get<mlir_dynamic_t>(cond_result);
    std::unique_ptr<mlir::Block> then_block = nullptr;
    InsertPoint                  ins_point;
    // Create a block for the then clause if there is a dynamic listener.
    if(cond_dyn.listener)
    {
        mlir::OpBuilder& b = *(cond_dyn.listener->get_builder());
        ins_point          = b.saveInsertionPoint();
        // We create the block without a parent, as it will be used only as
        // a temporary container for operations. Since it has no parent, the
        // block erase() method should not be called.
        //then_block         = b.createBlock(b.getBlock()->getParent());
        then_block.reset(new mlir::Block);
        b.setInsertionPoint(then_block.get(), then_block->begin());
    }
    // Evaluate the then clause. If a listener is present, emitted operations
    // will be placed in the 'then' block. A YieldOp will be appended later.
    auto then_result = then_func();
    // Create a block for the else clause.
    std::unique_ptr<mlir::Block> else_block = nullptr;
    if(cond_dyn.listener)
    {
        mlir::OpBuilder& b = *(cond_dyn.listener->get_builder());
        // We create the block without a parent, as it will be used only as
        // a temporary container for operations. Since it has no parent, the
        // block erase() method should not be called.
        //else_block         = b.createBlock(b.getBlock()->getParent());
        else_block.reset(new mlir::Block);
        b.setInsertionPoint(else_block.get(), else_block->begin());
    }
    // Evaluate the then clause. If a listener is present, emitted operations
    // will be placed in the 'else' block. A YieldOp will be appended later.
    auto else_result = else_func();
    // Resolve the return type of the IfOp by combining the types of the results
    // of the 'then' and 'else' clauses.
    using arith_op_desc_t = detail::arith_op_desc_t;
    using opt_arith_desc  = std::optional<arith_op_desc_t>;

    // Changed from named variable get_arith_desc to temporary object here because the previous would cause stack corruption because MSVC 2019 compiler issue.
    // details in  https://stackoverflow.com/questions/77437655/msvc-throws-run-time-check-failure-2-corrupted-stack-for-this-use-of-the-ov
    //     and  https://developercommunity.visualstudio.com/t/Runtime-stack-corruption-using-std::visi/346200
    // Resolve the type of the if operation by merging the then/else types.
    opt_arith_desc result_desc = visit(detail::overload{
                                           [](const mlir_dynamic_t& lhs, const mlir_dynamic_t& rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](const mlir_dynamic_t& lhs, static_int_t rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](static_int_t lhs, const mlir_dynamic_t& rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(rhs, lhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](static_int_t lhs, static_int_t rhs) -> opt_arith_desc {
                                               arith_op_desc_t op_desc = property_policy::resolve_if_else(lhs, rhs);
                                               return opt_arith_desc{op_desc};
                                           },
                                           [](auto, auto) -> opt_arith_desc {
                                               return std::nullopt;
                                           }},
                                       then_result,
                                       else_result);

    if(!result_desc.has_value())
    {
        // One or more of the then/else blocks returned a type that was neither a
        // static nor a dynamic integer. Therefore, resolution of the if return
        // type failed.
        return result_t{cg_error_t{}};
    }

    mlir::Value if_result{};
    if(cond_dyn.listener)
    {
        mlir::OpBuilder& b         = *(cond_dyn.listener->get_builder());
        mlir::Location   loc       = cond_dyn.listener->get_loc();
        int32_t          res_width = result_desc.value().result_prop.width;
        mlir::Type       if_type   = b.getIntegerType(res_width);
        dynamic_listener dl(&b, loc);
        // Restore the saved insertion point, which is right before the
        // temporary blocks that were created.
        b.restoreInsertionPoint(ins_point);
        // Create an If operation using the resolved result type
        auto if_op = mlir::scf::IfOp::create(b, loc,
                                             if_type,              // result type
                                             cond_dyn.get_value(), // cond value
                                             true,                 // add_then_block
                                             true);                // add_else_block
        // Splice the temporary 'then' and 'else' blocks into the newly created
        // if operation.
        assert(then_block);
        if_op.thenBlock()->getOperations().splice(if_op.thenBlock()->end(),
                                                  then_block->getOperations());
        assert(then_block->empty());
        b.setInsertionPointToEnd(if_op.thenBlock());
        mlir::Value then_res = detail::get_value_with_width(&b, loc, then_result, res_width);
        mlir::scf::YieldOp::create(b, loc, then_res);

        if_op.elseBlock()->getOperations().splice(if_op.elseBlock()->end(),
                                                  else_block->getOperations());
        assert(else_block->empty());
        b.setInsertionPointToEnd(if_op.elseBlock());
        mlir::Value else_res = detail::get_value_with_width(&b, loc, else_result, res_width);
        mlir::scf::YieldOp::create(b, loc, else_res);

        if_result = if_op.getResults()[0];

        // Set the insertion point after the If operation
        b.setInsertionPointAfter(if_op);
    }
    return result_t{mlir_dynamic_t{dynamic_t{result_desc.value().result_prop},
                                   if_result,
                                   cond_dyn.listener}};
}

/**
 * @brief Returns the associated MLIR `Value` for a scalar-like input value `val`.
 *
 * This function returns an MLIR `Value` of integer type that represents the provided scalar-like
 * input. `TVal` can be `rec_var`, `std::variant`, or a scalar-like type directly like
 * `mlir_dynamic_t`.
 *
 * For example, when a recursive variant holding a scaled basis is provided as an input, a `Value`
 * representing that scaled basis' value is returned. By "representing", we mean that, when the
 * scalar-like input holds an mlir_dynamic_t, we simply return the value member. When the
 * scalar-like input holds an integer, we build an mlir::arith::ConstantOp with that integer.
 *
 * The way scalar types are mapped to a single `Value` is detailed below for cases that are not
 * trivial
 *
 * - for scaled bases, their value is returned
 * - for underscores, a constant `Value` of 0 is returned
 *
 * The following cases are invalid:
 *
 * - ratios because they don't have a single value naturally associated with them
 * - errors
 * - vectors
 */
template <class TVal>
mlir::Value get_or_build_scalar_mlir_value(mlir::OpBuilder& builder, mlir::Location loc, const TVal& val)
{
    return detail::get_or_build_scalar_mlir_value_visitor(builder, loc)(val);
}

/// Overload taking a dynamic_listener pointer.
template <class TVal>
mlir::Value get_or_build_scalar_mlir_value(dynamic_listener& lis, const TVal& val)
{
    assert(lis.get_builder());
    return get_or_build_scalar_mlir_value(*lis.get_builder(), lis.get_loc(), val);
}

/**
 * @brief Returns a vector-like instance holding MLIR `Value`s collected from `x` from left to
 *        right.
 *
 * This functions walks `x` from left to right and collect MLIR `Value`'s held by mlir_dynamic_t
 * instances. Those instances can be nested within other scalar-like types, e.g. for scaled bases'
 * value.
 */
template <class TRet, class TAlgebra>
TRet get_mlir_values_from_dynamics(const TAlgebra& x)
{
    TRet res;
    detail::get_mlir_values_from_dynamics_visitor<TRet>{res}(x);
    return res;
}

template <class TVec, class TAlgebra>
void get_mlir_values_from_dynamics(const TAlgebra& x,
                                   TVec&           vec)
{
    detail::get_mlir_values_from_dynamics_visitor<TVec> vis(vec);
    vis(x);
}

/**
 * @brief Initializes mlir_dynamic_t instances in `t` with `listener` and MLIR `Value`s in `values`.
 *
 * This function initializes mlir_dynamic_t instances in `t` with `listener` and MLIR `Value`s found
 * in `values`. A pointer to a dynamic listener must be provided as an input because it must stay
 * in scope for the caller to then use cutegen's code generation capabilities.
 *
 * @pre listener->get_builder()
 * @pre scalar_count(t, dynamicOnly=true) == values.size()
 */
template <class TAlgebra>
void set_with_mlir_values(dynamic_listener* listener,
                          TAlgebra&         t,
                          mlir::ValueRange  values)
{
    assert(listener->get_builder());
    assert(scalar_count(t, /*dynamicOnly=*/true) == values.size());
    if(values.empty()) return;
    detail::set_with_mlir_values_visitor{listener, values}(t);
}

/**
 * @brief Creates a cutegen algebra type populated with MLIR `Value`s.
 *
 * This function is the non in-place version of `set_with_mlir_values`.
 *
 * When cutegen algebra types (e.g. shape, stride, layout, ...) are stored in data structures
 * associated with an MLIR context (e.g. as part of uniqued type or attribute storage), the MLIR
 * Value of the dynamic types are NULL Values.
 *
 * When lowering cutegen functions, it is common to:
 * 1. make a copy of the algebra type that has NULL MLIR Values
 * 2. modify the copy so that the MLIR Values are non-NULL
 * 3. call a cutegen function that will emit MLIR code using these MLIR Values as operands
 *
 * This function performs steps 1 and 2, returning the copy. Callers can then perform step 3 on the
 * returned result.
 *
 * Note that instances of mlir_dynamic_t will store a pointer to the dynamic_listener instance
 * provided to this function. Therefore, the scope of that dynamic_listener (as well as its
 * associated OpBuilder) must extend beyond step 3 above.
 */
template <class TAlgebra>
TAlgebra make_with_mlir_values(dynamic_listener* listener,
                               const TAlgebra&   src,
                               mlir::ValueRange  values)
{
    assert(listener->get_builder());
    assert(scalar_count(src, /*dynamicOnly=*/true) == values.size());
    if(values.empty()) return src;
    TAlgebra dst = src;
    set_with_mlir_values(listener, dst, values);
    return dst;
}

/// Returns whether mlir_dynamic_t instances in `t` are null.
template <class TAlgebra>
bool are_dynamics_null(const TAlgebra& t)
{
    return detail::are_dynamics_null_visitor{}(t);
}

/// Nullifies mlir_dynamic_t instances in `t`.
template <class TAlgebra>
void nullify_dynamics(TAlgebra& t)
{
    detail::nullify_dynamics_visitor{}(t);
}

/**
 * @brief Constructs a recursive variant replacing integers by mlir_dynamic_t instances without
 *        properties and removing properties from mlir_dynamic_t instances.
 *
 * Context: (2,2) and (?,?) are different cute::ShapeType. Sometimes, it
 * is desirable to store in another type a field that has a uniquely defined cute::ShapeType. For
 * example, the tile scheduler params type could store the cluster shape which could be static or
 * dynamic depending on the operand provided to the operation that creates it. The function allows
 * us to transform any of the shape mentioned above to (?,?).
 *
 * The following transformations are performed:
 * - integers are converted to mlir_dynamic_t holding a Value created using arith::ConstantOp
 * - properties are removed from mlir_dynamic_t elements
 * - the same holds for the value held by a scaled_basis_t when it's an integer
 *
 * The following element types are transformed to a cg_error_t:
 * - ratios which are never dynamic
 * - underscores which cannot be transformed to a dynamic element
 */
template <class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
TRecVar make_fully_dynamic(dynamic_listener* lis, const TRecVar& rv)
{
    return detail::make_fully_dynamic_visitor<TRecVar>(lis)(rv);
}

//
// Utilities for interacting with Values of type LLVM::LLVMStructType
//

/**
 * @brief Empty struct used to identify that lowering to LLVM should use the
 *        "sparse flat" representation.
 *
 * The "sparse flat" LLVM representation of cutegen types does NOT have explicit
 * storage of "static" constant values (i.e. integer values known at code
 * generation time). Only dynamic values are stored in the LLVM struct. (This is
 * the "sparse" aspect.)
 * The "flat" aspect of this representation indicates that the hierarchical
 * profile of the CuTe algebra type is not present. Dynamic values are stored
 * in a top-level struct, regardless of the CuTe algebra type profile.
 *
 * Example LLVM representations with llvm_type_sparse_flat_t:
 * 4               struct<()>                                        (bare integer constant is empty struct)
 * ?               i32
 * ?{i64}          i64
 * (?,8)           i32                                               (static values are not stored, single values are not nested)
 * (_,8)           struct<()>                                        (underscore has no storage)
 * (?,?)           struct<(i32, i32)>
 * (?,4,?)         struct<(i32, i32)>                                (static values are not stored)
 * (((?)))         i32                                               (flattened representation does not represent depth)
 * (?,?):(1,?)     struct<(struct<(i32,i32)>, i32)>                  (layout is struct with two types (shape + stride)
 * [?:?;?:?]       struct<(struct<(i32, i32)>, struct<(i32, i32)>)>  (tile with two layouts)
 * [(?,?):(?,?)]   struct<(struct<(i32, i32)>, struct<(i32, i32)>)>  (tile with one layouts)
 * [?:?;[?:?]]     struct<(struct<(i32, i32)>, struct<(i32, i32)>)>  (tile layouts are flattened)
 */
struct llvm_type_sparse_flat_t
{};
/**
 * @brief Default type used for cutegen functions that work with the lowered
 *        LLVM type representation.
 */
using llvm_type_default_t = llvm_type_sparse_flat_t;

inline constexpr llvm_type_sparse_flat_t llvm_type_sparse_flat;

namespace detail
{

template <class T>
struct llvm_type_generator;

template <>
struct llvm_type_generator<llvm_type_sparse_flat_t>
{
    llvm_type_generator(mlir::Builder& b) :
        builder_(b) {}
    // No LLVM storage representation for static 32-bit integers
    void operator()(int32_t /*i*/)
    {
    }
    // No LLVM storage representation for static 64-bit integers
    void operator()(int64_t /*i*/)
    {
    }
    // LLVM type representation for a std::variant, where we assume that the
    // current value held by the variant represents the desired type.
    template <class... TVarTypes>
    void operator()(const std::variant<TVarTypes...>& v)
    {
        std::visit(*this, v);
    }
    // LLVM type representation for cutegen recursive variants. (We assume that
    // the current "profile" or hierarchy of the rec_var is the desired type.)
    template <class... TRecVarTypes>
    void operator()(const rec_var_base<TRecVarTypes...>& v)
    {
        v.visit(*this);
    }
    // LLVM type representation for a std::vector<> of any type. The LLVM type
    // mapping is a struct with one member for each vector element.
    template <class TVecElem>
    void operator()(const std::vector<TVecElem>& v)
    {
        std::for_each(v.begin(),
                      v.end(),
                      [this](auto& e) {
                          this->operator()(e);
                      });
    }
    // LLVM type representation for cutegen dynamic values.
    void operator()(const mlir_dynamic_t& d)
    {
        types_.push_back(builder_.getIntegerType(d.get_width()));
    }
    // LLVM type representation for cutegen underscore (used for coords).
    // No current storage associated with underscore type.
    void operator()(const underscore_t& /*d*/)
    {
    }
    // LLVM type representation for the cutegen error type. Note: the error type
    // is currently intended to be used at code generation time, and the actual
    // generated code does not currently use the error value.
    void operator()(const cg_error_t& /*v*/)
    {
    }
    // LLVM type representation for the cutegen ratio type.
    void operator()(const ratio& r)
    {
        this->operator()(r.num());
        this->operator()(r.denom());
    }
    // LLVM type representation for scaled basis.
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        // We currently assume that the modes of a scaled basis are statically
        // known, and thus only the value needs to be represented in the type.
        // The value() method returns a variant, so we rely on the variant
        // dispatch of this class to determine the correct type.
        this->operator()(sb.value());
    }
    // Although swizzles do not currently support dynamic values, they
    // are sometimes used for the outer layout in composed layouts. Therefore,
    // we represent a swizzle as an empty struct to maintain a consistent
    // LLVM type representation of composed layouts (i.e. a struct with
    // 3 values).
    void operator()(const swizzle& sw)
    {
        types_.push_back(mlir::LLVM::LLVMStructType::getLiteral(
            builder_.getContext(), {}));
    }
    // LLVM type representation for a layout.
    // Note that cutegen tiles are recursive variants with layouts as a variant
    // type, so this may be invoked indirectly via the recursive variant
    // operator() above.
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        auto shType  = llvm_type_generator::get_type(builder_, ly.shape());
        auto stType  = llvm_type_generator::get_type(builder_, ly.stride());
        auto layType = mlir::LLVM::LLVMStructType::getLiteral(builder_.getContext(),
                                                              {shType, stType});

        types_.push_back(layType);
    }
    // LLVM type representation for a composed layout.
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& cly)
    {
        auto bType   = llvm_type_generator::get_type(builder_, cly.layout_b());
        auto oType   = llvm_type_generator::get_type(builder_, cly.offset());
        auto aType   = llvm_type_generator::get_type(builder_, cly.a());
        auto layType = mlir::LLVM::LLVMStructType::getLiteral(builder_.getContext(),
                                                              {bType, oType, aType});
        types_.push_back(layType);
    }
    // Utility function to allow type retrieval without invoking visit() on a
    // variant type.
    template <class T>
    mlir::Type get_type(const T& t)
    {
        // Visit the input argument, collecting types for dynamic values only
        this->operator()(t);
        // If there is 1 dynamic value, return the "bare" value. Otherwise,
        // return a struct with one element for each dynamic value. (Note that
        // this includes the "0 dynamic values" case: an empty struct will be
        // returned.)
        if(1 == types_.size())
            return types_[0];
        else
            return mlir::LLVM::LLVMStructType::getLiteral(builder_.getContext(),
                                                          types_);
    }
    template <class T>
    static mlir::Type get_type(mlir::Builder& b, const T& t)
    {
        llvm_type_generator vis(b);
        return vis.get_type(t);
    }
    template <class T>
    static mlir::Value make_poison_value(mlir::OpBuilder& b,
                                         mlir::Location   loc,
                                         const T&         t)
    {
        llvm_type_generator vis(b);
        return mlir::ub::PoisonOp::create(b, loc, vis.get_type(t)).getResult();
    }

private:
    mlir::Builder&                builder_;
    llvm::SmallVector<mlir::Type> types_;
};

template <class TLLVMType>
class llvm_scalar_value_collector;

template <>
class llvm_scalar_value_collector<llvm_type_sparse_flat_t>
{
private:
    using property_policy = dynamic_t::property_policy_t;
    using arith_op_desc_t = detail::arith_op_desc_t;

public:
    using type_generator_t = llvm_type_generator<llvm_type_sparse_flat_t>;
    llvm_scalar_value_collector(mlir::OpBuilder& b) :
        builder_(b),
        loc_(b.getUnknownLoc())
    {
    }
    template <typename T>
    void collect(mlir::Value                     root_value,
                 mlir::Location                  loc,
                 llvm::SmallVector<mlir::Value>& values,
                 const T&                        algebra_value,
                 bool                            dynamic_only)
    {
        assert(type_generator_t::get_type(builder_, algebra_value) == root_value.getType());
        loc_               = loc;
        root_value_        = root_value;
        values_            = &values;
        tile_layout_count_ = std::numeric_limits<size_t>::max();
        dynamic_only_      = dynamic_only;
        indices_.resize(0);
        src_types_.resize(0);
        src_types_.push_back(root_value.getType());
        this->operator()(algebra_value);
    }
    template <class T>
    void operator()(const std::vector<T>& vec)
    {
        for(auto& e : vec)
        {
            //this->operator()(e);
            // Using visit() here requres the vector element type to be a
            // variant/recursive variant.
            // We use the cutegen visit() implementation instead of std::visit()
            // to accommodate older compilers (gcc8.5) that don't support
            // std::visit() on types derived from std::variant.
            //std::visit(*this, e);
            visit(*this, e);
        }
    }
    // Collect the Value from a vector of tiles
    template <class TDynTraits>
    void operator()(const std::vector<cute_tile_t<TDynTraits>>& vec)
    {
        for(auto& e : vec)
        {
            // Forward to the special handler for cute_tile_t instances
            this->operator()(e);
        }
    }
    // Collect a static (constant) integer Value
    void operator()(int32_t i)
    {
        if(!dynamic_only_)
        {
            arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
            values_->push_back(get_value_with_width(&builder_,
                                                    loc_,
                                                    i,
                                                    op_desc.result_prop.width));
        }
    }
    // Collect a static (constant) integer Value
    void operator()(int64_t i)
    {
        if(!dynamic_only_)
        {
            arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
            values_->push_back(get_value_with_width(&builder_,
                                                    loc_,
                                                    i,
                                                    op_desc.result_prop.width));
        }
    }
    // Collect ratio numerator and denominator
    void operator()(const ratio& r)
    {
        this->operator()(r.num());
        this->operator()(r.denom());
    }
    // Collect Value(s) from the type held by a recursive variant
    template <class... TRecVarTypes>
    void operator()(const rec_var_base<TRecVarTypes...>& rv)
    {
        indices_.push_back(0); // increase the depth
        // Invoke operator() for the type held by rv
        rv.visit(*this);
        indices_.pop_back(); // decrease the depth
    }
    // Collect Value(s) from the tile type
    // Collecting values from a tile instance requires special handling. The
    // LLVM representation is identical for different tile profiles. For
    // example, the following two tiles:
    // [?:?;?:?]           rank-2 tile (2 layouts)
    // [(?,?):(?,?)]       rank-1 tile (1 layout)
    // both have the same LLVM representation: struct<(struct<(i32, i32)>, struct<(i32, i32)>)>
    // tiles contain an underscore, a layout, or a vector of tiles. An
    // underscore has no LLVM representation. Layouts contained into the LLVM
    // representation will be "flattened" the same way that recursive variants
    // are. Therefore, a tile in LLVM will be either:
    // - a single layout, or
    // - a struct containing 2 or more layouts
    template <class TDynTraits>
    void operator()(const cute_tile_t<TDynTraits>& t)
    {
        using lay_t          = layout_t<TDynTraits>;
        using LLVMStructType = mlir::LLVM::LLVMStructType;
        assert(!src_types_.empty());
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Count layouts for the root tile (i.e. the first one encountered)
        if(std::numeric_limits<size_t>::max() == tile_layout_count_)
        {
            tile_layout_count_ = tile_count_layouts(t);
        }
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // For tiles holding a layout, we need to extract the layout struct
        // before dispatching to the layout operator.
        bool tileHoldsLayout = std::holds_alternative<lay_t>(t);
        if(tileHoldsLayout)
        {
            assert(tile_layout_count_ > 0);
            if(tile_layout_count_ > 1)
            {
                LLVMStructType tileType = llvm::cast<LLVMStructType>(src_types_.back());
                if(indices_.empty())
                {
                    indices_.push_back(0); // increase the depth
                }
                // Add the layout type to the source stack
                src_types_.push_back(get_struct_elem_type(tileType, indices_.back()));
            }
            else
            {
                // For a tile with a single layout, the src_types_ array should
                // hold the root value type.
                assert(src_types_.back() == root_value_.getType());
            }
        }
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Dispatch to either the vector, layout, or underscore method
        t.visit(*this);
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Restore the src_types_ and struct indices stacks.
        if(tileHoldsLayout && (tile_layout_count_ > 1))
        {
            // Remove the current layout struct
            src_types_.pop_back();
            // Advance the extraction index for any future layouts
            ++indices_.back();
        }
    }
    // Collect Value(s) from a layout
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        using LLVMStructType = mlir::LLVM::LLVMStructType;

        assert(!src_types_.empty());
        assert(type_is_layout(src_types_.back()));

        LLVMStructType lyType = llvm::cast<LLVMStructType>(src_types_.back());

        indices_.push_back(0); // increase the depth
        src_types_.push_back(get_struct_elem_type(lyType, 0));
        this->operator()(ly.shape());
        src_types_.pop_back();

        ++indices_.back(); // increment the index
        src_types_.push_back(get_struct_elem_type(lyType, 1));
        this->operator()(ly.stride());
        src_types_.pop_back();
        indices_.pop_back(); // decrease the depth
    }

    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& ly)
    {
        using LLVMStructType = mlir::LLVM::LLVMStructType;

        assert(!src_types_.empty());
        assert(llvm::isa<LLVMStructType>(src_types_.back()));
        assert(3 == llvm::cast<LLVMStructType>(src_types_.back()).getBody().size());

        LLVMStructType lyType = llvm::cast<LLVMStructType>(src_types_.back());

        indices_.push_back(0); // increase the depth
        src_types_.push_back(get_struct_elem_type(lyType, 0));
        this->operator()(ly.layout_b());
        src_types_.pop_back();

        ++indices_.back(); // increment the index
        src_types_.push_back(get_struct_elem_type(lyType, 1));
        this->operator()(ly.offset());
        src_types_.pop_back();

        ++indices_.back(); // increment the index
        src_types_.push_back(get_struct_elem_type(lyType, 2));
        std::visit(*this, ly.a());
        src_types_.pop_back();
        indices_.pop_back(); // decrease the depth
    }

    // Collect the Value from a scaled basis
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        // Dispatch to the type held by the scaled basis value (typically a
        // static integer, ratio, or a dynamic value if the scaled basis
        // supports dynamic values).
        std::visit(*this, sb.value());
        if(!dynamic_only_)
        {
            for(auto& m : sb.modes())
            {
                this->operator()(m);
            }
        }
    }
    void operator()(const mlir_dynamic_t& d)
    {
        extract_value_impl();
    }
    void operator()(const mlir_dynamic_ptr_t& d)
    {
        extract_value_impl();
    }
    void operator()(const underscore_t& /*u*/)
    {
        // No scalar value collected for underscore
    }
    void operator()(const cg_error_t& /*u*/) const
    {
        // No value currently collected for error types, as we don't expect
        // this type held in valid IR.
    }
    void operator()(const swizzle& sw) const
    {
        using ConstantOp = mlir::arith::ConstantOp;
        if(!dynamic_only_)
        {
            values_->push_back(ConstantOp::create(builder_, loc_, builder_.getI32IntegerAttr(sw.num_bits())));
            values_->push_back(ConstantOp::create(builder_, loc_, builder_.getI32IntegerAttr(sw.num_base())));
            values_->push_back(ConstantOp::create(builder_, loc_, builder_.getI32IntegerAttr(sw.num_shift())));
        }
    }

private:
    static mlir::Type get_struct_elem_type(mlir::LLVM::LLVMStructType ty, size_t idx)
    {
        return ty.getBody()[idx];
    }
    void extract_value_impl()
    {
        using ExtractValueOp = mlir::LLVM::ExtractValueOp;
        using LLVMStructType = mlir::LLVM::LLVMStructType;
        assert(!src_types_.empty());
        // If the root value is not a struct type, we are collecting from a bare
        // value with no nesting, and value extraction is unnecessary/incorrect.
        if(!llvm::isa<LLVMStructType>(src_types_[0]))
            values_->push_back(root_value_);
        else
        {
            llvm::ArrayRef<int64_t> idx(indices_);
            // The LLVM representation of a recursive variant (which may itself
            // be part of a layout/composed layout) in the sparse flat mode can
            // be:
            // - a struct with 2 or more values, or
            // - a "bare" integral value.
            // Which of these is used depends on the number of dynamic values.
            // We check the top of the src_types stack here and drop the last
            // index if that type is not a struct.
            if(!llvm::isa<LLVMStructType>(src_types_.back()))
                idx = idx.drop_back();
            assert(!idx.empty());
            // Create an instance of the LLVM extractvalue instruction and place
            // the result in the collection vector.
            values_->push_back(ExtractValueOp::create(builder_, loc_, root_value_, idx));
            // Increment the last index so that we extract the next value from
            // the struct (if there is one).
            ++indices_.back();
        }
    }
    template <class TDynTraits>
    static size_t tile_count_layouts(const cute_tile_t<TDynTraits>& t)
    {
        using tile_t = cute_tile_t<TDynTraits>;
        using lay_t  = layout_t<TDynTraits>;
        return leaf_count_if(t,
                             [](const tile_t& t) {
                                 return std::holds_alternative<lay_t>(t);
                             });
    }
    static bool type_is_layout(mlir::Type ty)
    {
        using LLVMStructType = mlir::LLVM::LLVMStructType;
        return llvm::isa<LLVMStructType>(ty) &&
               (2 == llvm::cast<LLVMStructType>(ty).getBody().size());
    }
    mlir::OpBuilder&                builder_;
    mlir::Location                  loc_;
    mlir::Value                     root_value_;
    llvm::SmallVector<mlir::Type>   src_types_;
    llvm::SmallVector<mlir::Value>* values_;
    llvm::SmallVector<int64_t, 16>  indices_;
    // Special handling required/used only for tile types
    size_t tile_layout_count_;
    bool   dynamic_only_;
};

class scalar_type_collector
{
private:
    using property_policy = dynamic_t::property_policy_t;

public:
    scalar_type_collector(mlir::MLIRContext* ctx) :
        ctx_(ctx)
    {
        assert(ctx_);
    }
    template <typename T>
    void collect(llvm::SmallVector<mlir::Type>& types,
                 const T&                       algebra_value,
                 bool                           dynamic_only)
    {
        types_        = &types;
        dynamic_only_ = dynamic_only;
        this->operator()(algebra_value);
    }
    template <class T>
    void operator()(const std::vector<T>& vec)
    {
        for(auto& e : vec)
        {
            visit(*this, e);
        }
    }
    // Collect a static (constant) integer Value
    void operator()(int32_t i)
    {
        if(!dynamic_only_)
        {
            // Use the property policy to determine the type representation of the
            // specific static value.
            detail::arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
            types_->push_back(mlir::IntegerType::get(ctx_, op_desc.result_prop.width));
        }
    }
    // Collect a static (constant) integer Value
    void operator()(int64_t i)
    {
        if(!dynamic_only_)
        {
            // Use the property policy to determine the type representation of the
            // specific static value.
            detail::arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
            types_->push_back(mlir::IntegerType::get(ctx_, op_desc.result_prop.width));
        }
    }
    // Collect ratio numerator and denominator
    void operator()(const ratio& r)
    {
        this->operator()(r.num());
        this->operator()(r.denom());
    }
    // Collect Value(s) from the type held by a recursive variant
    template <class... TRecVarTypes>
    void operator()(const rec_var_base<TRecVarTypes...>& rv)
    {
        rv.visit(*this);
    }
    // Collect Value(s) from a layout
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        this->operator()(ly.shape());
        this->operator()(ly.stride());
    }

    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& ly)
    {
        this->operator()(ly.layout_b());
        this->operator()(ly.offset());
        std::visit(*this, ly.a());
    }

    // Collect the Value from a scaled basis
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        // Dispatch to the type held by the scaled basis value (typically a
        // static integer, ratio, or a dynamic value if the scaled basis
        // supports dynamic values).
        std::visit(*this, sb.value());
        if(!dynamic_only_)
        {
            for(auto& m : sb.modes())
            {
                this->operator()(m);
            }
        }
    }
    void operator()(const mlir_dynamic_t& d)
    {
        types_->push_back(mlir::IntegerType::get(ctx_, d.get_width()));
    }
    void operator()(const underscore_t& /*u*/)
    {
        // No value/type collected for underscore
    }
    void operator()(const cg_error_t& /*u*/)
    {
        // No value currently collected for error types, as we don't expect
        // this type held in valid IR.
    }
    void operator()(const swizzle& sw)
    {
        if(!dynamic_only_)
        {
            types_->append(3, mlir::IntegerType::get(ctx_, 32));
        }
    }

private:
    mlir::MLIRContext*             ctx_;
    llvm::SmallVector<mlir::Type>* types_;
    bool                           dynamic_only_;
};

template <class TLLVMType>
struct llvm_value_inserter;

template <>
struct llvm_value_inserter<llvm_type_sparse_flat_t>
{
    using type_generator_t = llvm_type_generator<llvm_type_sparse_flat_t>;
    llvm_value_inserter(mlir::OpBuilder& b) :
        builder_(b),
        loc_(b.getUnknownLoc())
    {
    }
    template <typename T>
    mlir::Value insert(mlir::Value      init_value,
                       mlir::Location   loc,
                       mlir::ValueRange dyn_values,
                       const T&         algebra_value)
    {
        assert(type_generator_t::get_type(builder_, algebra_value) == init_value.getType());
        loc_        = loc;
        cur_value_  = init_value;
        dyn_values_ = dyn_values;
        indices_.resize(0);
        this->operator()(algebra_value);
        return cur_value_;
    }
    template <class... TTypes>
    void operator()(const std::variant<TTypes...>& v)
    {
        insert_from_value_type(cur_value_.getType());
    }
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        insert_from_value_type(cur_value_.getType());
    }
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& cly)
    {
        insert_from_value_type(cur_value_.getType());
    }
    void operator()(const swizzle& /*sw*/) const
    {
        // No value currently inserted for swizzle
    }

private:
    void insert_from_value_type(mlir::Type t)
    {
        using LLVMStructType = mlir::LLVM::LLVMStructType;
        llvm::TypeSwitch<mlir::Type, void>(t)
            .Case<LLVMStructType>([&](LLVMStructType structTy) {
                indices_.push_back(0);
                for(auto [idx, ty] : llvm::enumerate(structTy.getBody()))
                {
                    indices_.back() = idx;
                    insert_from_value_type(ty);
                }
                indices_.pop_back();
            })
            .Case<mlir::IntegerType>([&](auto intTy) {
                if(!llvm::isa<LLVMStructType>(cur_value_.getType()))
                {
                    cur_value_ = dyn_values_.front();
                }
                else
                {
                    cur_value_ = mlir::LLVM::InsertValueOp::create(builder_, loc_, cur_value_, dyn_values_.front(), indices_);
                }
                dyn_values_ = dyn_values_.drop_front();
            })
            .Default([&](auto t) {
                assert(false && "Unexpected type in cutegen LLVM lowering");
            });
    }
    mlir::OpBuilder&               builder_;
    mlir::Location                 loc_;
    mlir::Value                    cur_value_;  // resulting value with insertions
    mlir::ValueRange               dyn_values_; // caller-provided dynamic values
    llvm::SmallVector<int64_t, 16> indices_;    // indices for LLVM::InsertValue instruction
};

// Helper for insert_scalar, see there for documentation
struct scalar_to_llvm_value_inserter
{
private:
    mlir::OpBuilder&        builder_;
    mlir::Location          loc_;
    mlir::Value             cur_value_;
    llvm::ArrayRef<int64_t> indices_;

    using property_policy = dynamic_t::property_policy_t;

private:
    void insert(mlir::Value val)
    {
        cur_value_ = mlir::LLVM::InsertValueOp::create(builder_, loc_, cur_value_, val, indices_);
    }

public:
    scalar_to_llvm_value_inserter(mlir::OpBuilder& b) :
        builder_(b),
        loc_(b.getUnknownLoc())
    {}
    template <class... TRecVarElemTypes, class TIndex>
    mlir::Value insert(mlir::Location                           loc,
                       const rec_var_base<TRecVarElemTypes...>& scalar,
                       mlir::Value                              v,
                       const TIndex&                            indices)
    {
        assert(holds_leaf(scalar));
        loc_       = loc;
        cur_value_ = v;
        indices_   = llvm::ArrayRef(indices);
        this->operator()(scalar);
        return cur_value_;
    }

public:
    // Visitor pattern for recursive variants
    template <class... TRecVarTypes>
    void operator()(const rec_var_base<TRecVarTypes...>& rv)
    {
        rv.visit(*this);
    }
    // Visitor pattern for std variants
    template <class... TVarTypes>
    void operator()(const std::variant<TVarTypes...>& var)
    {
        std::visit(*this, var);
    }

    // Invalid non-scalar cases
    template <class T>
    void operator()(const std::vector<T>& vec)
    {
        assert(false);
    }
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        assert(false);
    }
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& cly)
    {
        assert(false);
    }

    void operator()(int32_t i)
    {
        // Determine the integer type width for the specific static constant
        // value.
        arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
        insert(get_value_with_width(&builder_,
                                    loc_,
                                    i,
                                    op_desc.result_prop.width));
    }
    void operator()(int64_t i)
    {
        // Determine the integer type width for the specific static constant
        // value.
        arith_op_desc_t op_desc = property_policy::resolve_from_static(i);
        insert(get_value_with_width(&builder_,
                                    loc_,
                                    i,
                                    op_desc.result_prop.width));
    }
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        // Dispatch to the type held by the scaled basis value (typically a
        // static integer or a dynamic value if the scaled basis supports
        // dynamic values).
        this->operator()(sb.value());
    }
    void operator()(const mlir_dynamic_t& d)
    {
        insert(d.value);
    }
    void operator()(const mlir_dynamic_ptr_t& d)
    {
        insert(d.value);
    }
    void operator()(const underscore_t& /*u*/)
    {
        // Note: We currently set underscore to zero, as some arithmetic
        // operations in CuTe C++ do this. However, it may not be necessary or
        // always desired.
        insert(mlir::arith::ConstantOp::create(builder_, loc_, builder_.getI32IntegerAttr(0)));
    }
    void operator()(const cg_error_t& /*u*/) const
    {
        // No value currently inserted for error types
    }
};
} // namespace detail

/**
 * @brief Collect scalar values for a cutegen algebra type
 *
 * This function collects scalar MLIR values from an aggregate MLIR Value
 * root_value by generating operations. The MLIR values are typically generated
 * by constant operations (in the case of static cutegen constants) or by
 * extract_value operations (in the case of dynamic values that were stored in
 * the LLVM representation of the input MLIR Value). The collected values are
 * appended to the values vector argument. The dynamic_only argument specifies
 * whether all scalars are collected, or only the dynamic scalars are
 * collected.
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
void collect_scalar_values(mlir::OpBuilder&                builder,
                           mlir::Location                  loc,
                           const TAlgebra&                 algebra_value,
                           mlir::Value                     root_value,
                           llvm::SmallVector<mlir::Value>& values,
                           bool                            dynamic_only,
                           TLLVMType                       llvm_type = TLLVMType{})
{
    detail::llvm_scalar_value_collector<TLLVMType> coll(builder);
    // Collect MLIR Values from shValue, with a "profile" defined by the
    // cutegen value.
    coll.collect(root_value, loc, values, algebra_value, dynamic_only);
}

/**
 * @brief Collect scalar values for a cutegen algebra type
 *
 * This function collects scalar MLIR values from an aggregate MLIR Value
 * root_value by generating operations. The MLIR values are typically generated
 * by constant operations (in the case of static cutegen constants) or by
 * extract_value operations (in the case of dynamic values that were stored in
 * the LLVM representation of the input MLIR Value). The collected values are
 * appended to the values vector argument. The dynamic_only argument specifies
 * whether all scalars are collected, or only the dynamic scalars are
 * collected.
 */
template <class TAlgebra>
void collect_scalar_types(mlir::MLIRContext*             ctx,
                          const TAlgebra&                algebra_value,
                          llvm::SmallVector<mlir::Type>& types,
                          bool                           dynamic_only)
{
    detail::scalar_type_collector coll(ctx);
    // Collect MLIR Types for scalars in algebra_value
    coll.collect(types, algebra_value, dynamic_only);
}

/**
 * @brief Emit instructions to generate a poison Value for a cutegen type and return it
 *
 * This function emits a ub.poison operation using the provided builder. The
 * LLVM type of the poison value is specified by the cutegen algebra argument.
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
mlir::Value make_poison(mlir::OpBuilder& builder,
                        mlir::Location   loc,
                        const TAlgebra&  algebra_value,
                        TLLVMType        llvm_type = TLLVMType{})
{
    return detail::llvm_type_generator<TLLVMType>::make_poison_value(builder, loc, algebra_value);
}

/**
 * @brief Emit instructions to generate and return an MLIR Value for a cutegen algebra type
 *
 * This function can be used to generate MLIR operations that will create a new
 * composite MLIR Value that represents a cutegen algebra type, containing
 * correctly initialized values. The initialized values will be:
 * - static constant integers (from the algebra type), or
 * - dynamic values (via an array provided by the caller)
 *
 * Internally, the function generates an LLVM type that represents the cutegen
 * algebra value, and then emits instructions (via the given builder). The
 * generated LLVM instruction would typically be insertvalue.
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
mlir::Value build_value(mlir::OpBuilder& builder,
                        mlir::Location   loc,
                        TAlgebra&&       algebra_value,
                        mlir::ValueRange dynamic_values,
                        TLLVMType        llvm_type = TLLVMType{})
{
    using LLVMStructType = mlir::LLVM::LLVMStructType;
    using type_generator = detail::llvm_type_generator<TLLVMType>;
    using value_inserter = detail::llvm_value_inserter<TLLVMType>;
    using PoisonOp       = mlir::ub::PoisonOp;
    // In some cases, the type for a CuTe algebraic type may be a bare integer.
    // In those cases, we will avoid emitting a ub.poison and just return
    // the caller-provided value.
    mlir::Type ty = type_generator::get_type(builder, algebra_value);
    if(auto structTy = llvm::dyn_cast<LLVMStructType>(ty))
    {
        mlir::Value    poison_val = PoisonOp::create(builder, loc, ty).getResult();
        value_inserter ins(builder);
        return ins.insert(poison_val, loc, dynamic_values, algebra_value);
    }
    else
    {
        assert(1 == dynamic_values.size());
        return dynamic_values[0];
    }
}

template <class TAlgebra, class TLLVMType = llvm_type_default_t>
mlir::Value build_value_from_populated(mlir::OpBuilder& builder,
                                       mlir::Location   loc,
                                       TAlgebra&&       algebra_value,
                                       TLLVMType        llvm_type = TLLVMType{})
{
    using ValuesVec      = llvm::SmallVector<mlir::Value>;
    ValuesVec dyn_values = get_mlir_values_from_dynamics<ValuesVec>(algebra_value);
    return build_value(builder, loc, algebra_value, dyn_values, llvm_type);
}

/**
 * @brief Inserts a cutegen scalar into an LLVMStruct Value.
 *
 * @pre @p scalar is an integer or a recursive variant that satisfies `holds_leaf(scalar)`
 *
 * Inserts a cutegen scalar into the LLVMStruct Value @p v at position @p idx. In particular:
 * - scaled basis elements only insert their value
 * - an underscore inserts 0
 * - a cg_error_t doesn't insert anything
 */
template <class TAlgebra, class TIndex>
mlir::Value insert_scalar(mlir::OpBuilder& builder,
                          mlir::Location   loc,
                          const TAlgebra&  scalar,
                          mlir::Value      v,
                          const TIndex&    idx)
{
    if constexpr(std::is_integral_v<TAlgebra>)
    {
        return insert_scalar(builder, loc, rec_var<TAlgebra>(scalar), v, idx);
    }
    else if constexpr(std::is_integral_v<TIndex>)
    {
        return insert_scalar(builder, loc, scalar, v, mlir::SmallVector<int64_t>{idx});
    }
    else
    {
        assert(holds_leaf(scalar));
        detail::scalar_to_llvm_value_inserter ins(builder);
        return ins.insert(loc, scalar, v, idx);
    }
}

/**
 * @brief Return the LLVM type representation for a given cutegen algebra type
 *
 * This function returns the LLVM type representation for a given cutegen value.
 * In most cases, the returned type will be an aggregate LLVM struct type.
 * However, recursive variants that hold "bare" scalars (i.e. rank 1 and depth
 * 0) are represented by a non aggregate integer type.
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
mlir::Type get_llvm_type(mlir::Builder&  builder,
                         const TAlgebra& algebra_value,
                         TLLVMType       llvm_type = TLLVMType{})
{
    return detail::llvm_type_generator<TLLVMType>::get_type(builder, algebra_value);
}

/**
 * @brief Populate the dynamic values of a cutegen algebra value
 *
 * This function sets the dynamic_listener and MLIR Value for each scalar of
 * type mlir_dynamic_t in the given cutegen algebra type. The scalar MLIR
 * values are obtained from the value argument, typically via a series of
 * extractvalue operations/instructions. This function might be called before
 * calling a cutegen function that performs an algebraic operation that is
 * expected to emit MLIR operations. (This function sets the MLIR Value of
 * the dynamic values so that the emitted operations reference the correct
 * values.)
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
void populate_dynamic_values(dynamic_listener& lis,
                             mlir::Value       value,
                             TAlgebra&         algebra_value,
                             TLLVMType         llvm_type = TLLVMType{})
{
    assert(lis.get_builder());
    assert(get_llvm_type(*(lis.get_builder()), algebra_value, llvm_type) == value.getType());
    llvm::SmallVector<mlir::Value> dyn_values;
    collect_scalar_values(*lis.get_builder(),
                          lis.get_loc(),
                          algebra_value,
                          value,
                          dyn_values,
                          true, // dynamic_only
                          llvm_type);
    set_with_mlir_values(&lis, algebra_value, dyn_values);
}

/**
 * @brief Create a cutegen algebra type populated with MLIR Values
 *
 * When cutegen algebra types (e.g. shape, stride, layout, ...) are
 * stored in data structures associated with an MLIR context (e.g.
 * as part of uniqued type or attribute storage), the MLIR Value of
 * the dynamic types are NULL Values.
 *
 * When lowering cutegen functions, it is common to:
 * 1. make a copy of the algebra type that has NULL MLIR Values
 * 2. modify the copy so that the MLIR Values are non-NULL
 * 3. call a cutegen function that will emit MLIR code using these
 *    MLIR Values as operands
 *
 * This function performs steps 1 and 2, returning the copy. Callers
 * can then perform step 3 on the returned result.
 *
 * Note that instances of mlir_dynamic_t will store a pointer to the
 * dynamic_listener instance provided to this function. Therefore, the
 * scope of that dynamic_listener (as well as its associated OpBuilder)
 * must extend beyond step 3 above.
 *
 * @tparam TAlgebra type of cutegen algebra type
 * @param src input cutegen value
 * @param lis dynamic_listener, initialized with a builder and location
 * @param value MLIR Value (scalar or aggregate) used to populate dynamic
 *        values of the result
 * @return TAlgebra copy of src with dynamic values populated
 */
template <class TAlgebra, class TLLVMType = llvm_type_default_t>
TAlgebra make_with_dynamic_values(const TAlgebra&   src,
                                  dynamic_listener& lis,
                                  mlir::Value       value,
                                  TLLVMType         llvm_type = TLLVMType{})
{
    assert(lis.get_builder());
    assert(get_llvm_type(*(lis.get_builder()), src, llvm_type) == value.getType());
    llvm::SmallVector<mlir::Value> dyn_values;
    collect_scalar_values(*lis.get_builder(),
                          lis.get_loc(),
                          src,
                          value,
                          dyn_values,
                          true, // dynamic_only
                          llvm_type);
    TAlgebra dst = src;
    set_with_mlir_values(&lis, dst, dyn_values);
    return dst;
}

inline mlir::Value set_layout_shape(mlir::OpBuilder& builder,
                                    mlir::Location   loc,
                                    mlir::Value      layout_value,
                                    mlir::Value      shape_value)
{
    // All layout values must be LLVMStructType, and must have 2 members (shape
    // and stride).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 2);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody()[0] == shape_value.getType());
    return mlir::LLVM::InsertValueOp::create(builder, loc, layout_value, shape_value, llvm::ArrayRef<int64_t>{0});
}

inline mlir::Value set_layout_stride(mlir::OpBuilder& builder,
                                     mlir::Location   loc,
                                     mlir::Value      layout_value,
                                     mlir::Value      stride_value)
{
    // All layout values must be LLVMStructType, and must have 2 members (shape
    // and stride).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 2);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody()[1] == stride_value.getType());
    return mlir::LLVM::InsertValueOp::create(builder, loc, layout_value, stride_value, 1);
}

inline mlir::Value make_layout_from_values(mlir::OpBuilder& builder,
                                           mlir::Location   loc,
                                           mlir::Value      shape_value,
                                           mlir::Value      stride_value)
{
    using LLVMStructType = mlir::LLVM::LLVMStructType;
    // Layout values must be LLVMStructType, and must have 2 members (shape
    // and stride).
    llvm::SmallVector<mlir::Type> types;
    auto                          lyType = LLVMStructType::getLiteral(builder.getContext(),
                                                                      {shape_value.getType(), stride_value.getType()});
    mlir::Value                   value  = mlir::ub::PoisonOp::create(builder, loc, lyType).getResult();
    value                                = mlir::LLVM::InsertValueOp::create(builder, loc, value, shape_value, llvm::ArrayRef<int64_t>{0});
    return mlir::LLVM::InsertValueOp::create(builder, loc, value, stride_value, llvm::ArrayRef<int64_t>{1});
}

inline mlir::Value get_layout_shape_value(mlir::OpBuilder& builder,
                                          mlir::Location   loc,
                                          mlir::Value      layout_value)
{
    // All layout values must be LLVMStructType, and must have 2 members (shape
    // and stride).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 2);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, layout_value, 0);
}

inline mlir::Value get_layout_stride_value(mlir::OpBuilder& builder,
                                           mlir::Location   loc,
                                           mlir::Value      layout_value)
{
    // All layout values must be LLVMStructType, and must have 2 members (shape
    // and stride).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 2);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, layout_value, 1);
}

inline mlir::Value set_composed_layout_outer(mlir::OpBuilder& builder,
                                             mlir::Location   loc,
                                             mlir::Value      layout_value,
                                             mlir::Value      outer_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody()[0] == outer_value.getType());
    return mlir::LLVM::InsertValueOp::create(builder, loc, layout_value, outer_value, llvm::ArrayRef<int64_t>{0});
}

inline mlir::Value set_composed_layout_offset(mlir::OpBuilder& builder,
                                              mlir::Location   loc,
                                              mlir::Value      layout_value,
                                              mlir::Value      offset_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody()[1] == offset_value.getType());
    return mlir::LLVM::InsertValueOp::create(builder, loc, layout_value, offset_value, 1);
}

inline mlir::Value set_composed_layout_inner(mlir::OpBuilder& builder,
                                             mlir::Location   loc,
                                             mlir::Value      layout_value,
                                             mlir::Value      inner_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody()[2] == inner_value.getType());
    return mlir::LLVM::InsertValueOp::create(builder, loc, layout_value, inner_value, 2);
}

inline mlir::Value make_composed_layout_from_values(mlir::OpBuilder& builder,
                                                    mlir::Location   loc,
                                                    mlir::Value      outer_value,
                                                    mlir::Value      offset_value,
                                                    mlir::Value      inner_value)
{
    using LLVMStructType = mlir::LLVM::LLVMStructType;
    // Layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    llvm::SmallVector<mlir::Type> types;
    auto                          lyType = LLVMStructType::getLiteral(builder.getContext(),
                                                                      {outer_value.getType(),
                                                                       offset_value.getType(),
                                                                       inner_value.getType()});
    mlir::Value                   value  = mlir::ub::PoisonOp::create(builder, loc, lyType).getResult();
    value                                = mlir::LLVM::InsertValueOp::create(builder, loc, value, outer_value, llvm::ArrayRef<int64_t>{0});
    value                                = mlir::LLVM::InsertValueOp::create(builder, loc, value, offset_value, llvm::ArrayRef<int64_t>{1});
    return mlir::LLVM::InsertValueOp::create(builder, loc, value, inner_value, llvm::ArrayRef<int64_t>{2});
}

inline mlir::Value get_composed_layout_outer_value(mlir::OpBuilder& builder,
                                                   mlir::Location   loc,
                                                   mlir::Value      layout_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, layout_value, 0);
}

inline mlir::Value get_composed_layout_offset_value(mlir::OpBuilder& builder,
                                                    mlir::Location   loc,
                                                    mlir::Value      layout_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, layout_value, 1);
}

inline mlir::Value get_composed_layout_inner_value(mlir::OpBuilder& builder,
                                                   mlir::Location   loc,
                                                   mlir::Value      layout_value)
{
    // All composed layout values must be LLVMStructType, and must have 3 members (outer,
    // offset, and inner).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(layout_value.getType()));
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(layout_value.getType()).getBody().size() == 3);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, layout_value, 2);
}

inline mlir::Value get_composed_layout_shape_value(mlir::OpBuilder& builder,
                                                   mlir::Location   loc,
                                                   mlir::Value      composed_layout_value)
{
    // All composed layout (with format "<inner> o <offset> o <outer>") values must be LLVMStructType,
    // and must have 3 members (outer, offset, and inner). All layout values must be LLVMStructType,
    // and must have 2 members (shape and stride).
    assert(llvm::isa<mlir::LLVM::LLVMStructType>(composed_layout_value.getType()));
    [[maybe_unused]] const auto& composed_layout = llvm::cast<mlir::LLVM::LLVMStructType>(composed_layout_value.getType());
    assert(composed_layout.getBody().size() == 3);
    // check that outer exists
    assert(composed_layout.getBody()[0]);
    assert(llvm::cast<mlir::LLVM::LLVMStructType>(composed_layout.getBody()[0]).getBody().size() == 2);
    return mlir::LLVM::ExtractValueOp::create(builder, loc, composed_layout_value, mlir::DenseI64ArrayAttr::get(builder.getContext(), {0, 0}));
}

// no get_composed_layout_stride_value due to ambiguity regarding stride in composed layout

/**
 * @brief Create an MLIR Value with a "derefined" representation of a source
 * type/value
 *
 * Type refinement refers to the process of changing the type of a value from
 * "less specific" to "more specific." Conversely, derefining changes the type
 * to a less specific type. A simple example would be a value with a static
 * constant integer "5". Derefining might represent the same value as "?".
 * This might be done during code generation to accommodate an MLIR operation
 * that does not support type refinement during code transformations. Such an
 * operation, created with an argument of type "?", might not be able to be
 * changed to accept "5". When this is the case, a derefine operation can be
 * added to "convert" from "5" to "?".
 *
 * This function builds a derefined MLIR Value to represent the result type
 * (resultType) from the given source (operand) type srcType and the associated
 * MLIR Value srcVal.
 * A NULL Value is returned if the result type cannot be obtained via
 * derefining. (This might occur if static values in the source and result are
 * different, or if the has a static value where the source had a dynamic
 * value.)
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
mlir::Value build_derefined_value(mlir::OpBuilder& b,
                                  mlir::Location   loc,
                                  const TRecVar&   resultType,
                                  const TRecVar&   srcType,
                                  mlir::Value      srcVal)
{
    using eq_comp_container_t = llvm::SmallVector<detail::eq_comp_t>;
    using eq_comp_res_t       = detail::eq_comp_result_t<eq_comp_container_t>;
    using dyn_vector_t        = llvm::SmallVector<mlir_dynamic_t>;

    // We "repurpose" the equality comparison function to support derefining.
    // Equality comparison traverses a pair of recursive variants and stores
    // records that describes the comparisons that would be needed at runtime.
    // Each record is a pair, with each element holding either a static integer
    // or the index of a dynamic value (where the index is into the set of
    // dynamic values held by the recursive variant). In this case, we are
    // comparing the derefine result type to the operand type.
    eq_comp_res_t cmp_check = detail::check_equality<eq_comp_container_t>(resultType, srcType);
    // The lowered LLVM type holds only the dynamic values. In some cases,
    // the derefine result may have the same number of dynamic values as the
    // input operand. (The result dynamic values may have different constraints.
    // Or we may just have an "identity" derefine. In those cases, we do not
    // need to populate a new struct instance. We can use the source Value.)
    auto requires_new = [](const detail::eq_comp_t& cmp) {
        assert(std::holds_alternative<detail::dynamic_index_t>(cmp.first));
        return !std::holds_alternative<detail::dynamic_index_t>(cmp.second);
    };
    return std::visit(detail::overload{
                          // A bool result indicates equality can be determined at codegen time.
                          // If the comparison indicates a codegen-time false result, derefine
                          // functionality is not valid and the function will return a NULL
                          /// Value.
                          [&](bool cmp) { return cmp ? srcVal : mlir::Value{}; },
                          [&](const eq_comp_container_t& cmpVec) {
                              // See if there are any "new" dynamic values in the result.
                              if(llvm::none_of(cmpVec, requires_new))
                                  return srcVal;
                              // Get the instances of dynamic integers from the destination
                              // type. The properties of these will be used to perform any
                              // potential conversion of source constants or extracted values.
                              auto                           dstDynamics = get_dynamics<dyn_vector_t>(resultType);
                              llvm::SmallVector<mlir::Value> dynValues;
                              for(auto& eq : cmpVec)
                              {
                                  // The result type must always have a dynamic value. (We can't
                                  // derefine from a source dynamic value to a static constant.)
                                  assert(std::holds_alternative<detail::dynamic_index_t>(eq.first));
                                  int first_index = std::get<detail::dynamic_index_t>(eq.first).value;
                                  // The dynamic index must not be greater than the number of
                                  // dynamic values in the destination type.
                                  assert(first_index < static_cast<int>(dstDynamics.size()));
                                  const mlir_dynamic_t& d = dstDynamics[first_index];
                                  // Dispatch on the type held by the source type.
                                  mlir::Value v = std::visit(detail::overload{
                                                                 [&](static_int_t i) {
                                                                     // We will insert a constant into the result struct. Obtain a value
                                                                     // with a bit width that matches the destination type.
                                                                     mlir::Value c = detail::get_value_with_width(&b, loc, i, d.get_width());
                                                                     return c;
                                                                 },
                                                                 [&](detail::dynamic_index_t di) {
                                                                     // We will extract a value to insert into the result.
                                                                     using LLVMStructType = mlir::LLVM::LLVMStructType;
                                                                     mlir::Value val{};
                                                                     // Tuple-like types with a single dynamic value are
                                                                     // represented by a "bare" integer (not a struct).
                                                                     if(llvm::isa<LLVMStructType>(srcVal.getType()))
                                                                     {
                                                                         assert(static_cast<size_t>(di.value) < llvm::cast<LLVMStructType>(srcVal.getType()).getBody().size());
                                                                         val = mlir::LLVM::ExtractValueOp::create(b, loc, srcVal, di.value);
                                                                     }
                                                                     else
                                                                     {
                                                                         assert(0 == di.value);
                                                                         val = srcVal;
                                                                     }
                                                                     // Convert the value to the destination width (if necessary).
                                                                     return detail::get_value_with_width(&b, loc, val, d.get_width());
                                                                 }},
                                                             eq.second);
                                  dynValues.push_back(v);
                              }
                              return build_value(b, loc, resultType, dynValues);
                          }},
                      cmp_check);
}

template <class TDynTraits>
mlir::Value build_derefined_value(mlir::OpBuilder&            b,
                                  mlir::Location              loc,
                                  const layout_t<TDynTraits>& resultType,
                                  const layout_t<TDynTraits>& srcType,
                                  mlir::Value                 srcVal)
{
    // Extract shape and stride values from the input layout operand
    mlir::Value src_shape  = get_layout_shape_value(b, loc, srcVal);
    mlir::Value src_stride = get_layout_stride_value(b, loc, srcVal);
    // Build new derefined values for the shape and stride
    mlir::Value res_shape  = build_derefined_value(b, loc, resultType.shape(), srcType.shape(), src_shape);
    mlir::Value res_stride = build_derefined_value(b, loc, resultType.stride(), srcType.stride(), src_stride);
    if(!res_shape || !res_stride)
        return mlir::Value{};
    return make_layout_from_values(b, loc, res_shape, res_stride);
}

template <class TDynTraits>
mlir::Value build_derefined_value(mlir::OpBuilder&                     b,
                                  mlir::Location                       loc,
                                  const composed_layout_t<TDynTraits>& resultType,
                                  const composed_layout_t<TDynTraits>& srcType,
                                  mlir::Value                          srcVal)
{
    mlir::Value src_outer  = get_composed_layout_outer_value(b, loc, srcVal);
    mlir::Value src_offset = get_composed_layout_offset_value(b, loc, srcVal);
    mlir::Value src_inner  = get_composed_layout_inner_value(b, loc, srcVal);
    mlir::Value res_outer  = build_derefined_value(b,
                                                  loc,
                                                  resultType.layout_b /*outer*/ (),
                                                  srcType.layout_b /*outer*/ (),
                                                  src_outer);
    mlir::Value res_offset = build_derefined_value(b,
                                                   loc,
                                                   resultType.offset(),
                                                   srcType.offset(),
                                                   src_offset);
    mlir::Value res_inner;
    if(resultType.is_a_swizzle())
        res_inner = build_value(b, loc, resultType.swizzle_a(), mlir::ValueRange{});
    else
        res_inner = build_derefined_value(b,
                                          loc,
                                          resultType.layout_a /*inner*/ (),
                                          srcType.layout_a /*inner*/ (),
                                          src_inner);
    if(!res_outer || !res_inner || !res_offset)
        return mlir::Value{};
    return make_composed_layout_from_values(b, loc, res_outer, res_offset, res_inner);
}

namespace detail
{

using eq_comp_result_smallvec_t = eq_comp_result_t<llvm::SmallVector<detail::eq_comp_t>>;

// Internal function to accumulate comparison results for recursive variant
// algebra inputs. The cmp_res Value can be NULL, or it can be the result
// of calling this function for a different pair of recursive variant inputs (as
// might be the case when comparing composite types like layouts).
template <class TRecVar>
mlir::Value chain_rec_var_eq_cmp(mlir::OpBuilder&                 b,
                                 mlir::Location                   loc,
                                 const TRecVar&                   lhs_type,
                                 mlir::Value                      lhs_value,
                                 const TRecVar&                   rhs_type,
                                 mlir::Value                      rhs_value,
                                 mlir::Value                      cmp_res,
                                 const eq_comp_result_smallvec_t& cmp_check)
{
    using eq_comp_container_t = llvm::SmallVector<detail::eq_comp_t>;

    if(std::holds_alternative<bool>(cmp_check))
    {
        auto bValue = std::get<bool>(cmp_check);
        // If the equality check is statically true or false, and there is no
        // input value to combine with, emit a constant value.
        if(!cmp_res || !bValue)
        {
            return mlir::arith::ConstantOp::create(b, loc, mlir::IntegerAttr::get(b.getI1Type(), bValue));
        }
        // If the comparison yielded a "true" result and there was a previous
        // value, return that previous value. (No need to and with "true".)
        return cmp_res;
    }
    else
    {
        // One or more runtime comparisons are necessary to determine equality.
        using int_or_dynamic_int = std::variant<static_int_t, mlir_dynamic_t>;
        using vec_dynamic_t      = llvm::SmallVector<mlir_dynamic_t>;
        using cmp_eq_t           = compare<mlir_dynamic_t, comp_pred::eq>;
        using bool_or_dynamic_t  = std::variant<bool, mlir_dynamic_t>;
        assert(!std::get<eq_comp_container_t>(cmp_check).empty());

        dynamic_listener dl(&b, loc);
        // Create copies of the algebra type populated MLIR Values extracted
        // from the input MLIR Value.
        TRecVar lhs_pop = make_with_dynamic_values(lhs_type, dl, lhs_value);
        TRecVar rhs_pop = make_with_dynamic_values(rhs_type, dl, rhs_value);

        // Collect dynamic values. The equality comparison generated dynamic
        // indices that can be used to index into these vectors.
        auto lhs_dynamics = get_dynamics<vec_dynamic_t>(lhs_pop);
        auto rhs_dynamics = get_dynamics<vec_dynamic_t>(rhs_pop);

        // Each operand to the comparison operation will be either a constant or a
        // dynamic value. This lambda returns a static int or a dynamic int.
        auto get_value = [&](const eq_comp_value_t& cmp,
                             const vec_dynamic_t&   dynValues) -> int_or_dynamic_int {
            if(std::holds_alternative<static_int_t>(cmp))
                return std::get<static_int_t>(cmp);
            else
            {
                assert(std::holds_alternative<detail::dynamic_index_t>(cmp));
                return dynValues[std::get<detail::dynamic_index_t>(cmp).value];
            }
        };
        // Combine individual integer comparisons into a single boolean result using
        // AndOp.
        for(auto& cmp : std::get<eq_comp_container_t>(cmp_check))
        {
            int_or_dynamic_int lhs        = get_value(cmp.first, lhs_dynamics);
            int_or_dynamic_int rhs        = get_value(cmp.second, rhs_dynamics);
            bool_or_dynamic_t  cmp_result = std::visit(detail::overload{
                                                          // Forward all int/mlir_dynamic_t pairings to compare<>
                                                          [](auto lhs, auto rhs) {
                                                              return cmp_eq_t{}(lhs, rhs);
                                                          }},
                                                      lhs,
                                                      rhs);
            mlir::Value        cmp_value{};
            if(std::holds_alternative<bool>(cmp_result))
            {
                bool bResult = std::get<bool>(cmp_result);
                auto intAttr = mlir::IntegerAttr::get(b.getI1Type(), bResult);
                cmp_value    = mlir::arith::ConstantOp::create(b, loc, intAttr);
            }
            else
            {
                assert(std::holds_alternative<mlir_dynamic_t>(cmp_result));
                cmp_value = std::get<mlir_dynamic_t>(cmp_result).get_value();
                assert(b.getI1Type() == cmp_value.getType());
            }
            // Return the value or the and of the value with the previous one
            if(!cmp_res)
                cmp_res = cmp_value;
            else
                cmp_res = mlir::arith::AndIOp::create(b, loc, cmp_res, cmp_value);
        }
        return cmp_res;
    }
}

} // namespace detail

/**
 * @brief Emit operations to perform equality comparison between two values
 * given their cutegen type and MLIR Value
 *
 * This function emits operations and returns an MLIR Value that indicates
 * whether the two CuTe algebra values are equal.
 * For some CuTe algebra values, equality can be determined at code generation
 * time. Specifically, for CuTe algebra values that are static (i.e. no dynamic
 * values), equality can be determined by comparing the profile and static
 * cutegen values of the two operands. In those cases, the MLIR Value returned
 * from this function will be the result of an arith.constant operation with the
 * True or False Value.
 * For other pairs of operands, equality cannot be determined until runtime.
 * For those cases, this function will emit integer comparisons and boolean
 * "and" operations to combine the results of those comparions. The returned
 * MLIR Value will be the Value obtained by performing pairwise and operations
 * on the individual integer operations.
 */
template <class TRecVar,
          std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
mlir::Value build_eq_cmp_value(mlir::OpBuilder& b,
                               mlir::Location   loc,
                               const TRecVar&   lhs_type,
                               mlir::Value      lhs_value,
                               const TRecVar&   rhs_type,
                               mlir::Value      rhs_value)
{
    using eq_comp_container_t = llvm::SmallVector<detail::eq_comp_t>;
    using eq_comp_res_t       = detail::eq_comp_result_t<eq_comp_container_t>;

    // Perform an equality comparison on the cutegen tuple types.
    eq_comp_res_t cmp_check = detail::check_equality<eq_comp_container_t>(lhs_type, rhs_type);

    return detail::chain_rec_var_eq_cmp(b,
                                        loc,
                                        lhs_type,
                                        lhs_value,
                                        rhs_type,
                                        rhs_value,
                                        mlir::Value{}, // No previous value to accumulate
                                        cmp_check);
}

template <class TDynTraits>
mlir::Value build_eq_cmp_value(mlir::OpBuilder&            b,
                               mlir::Location              loc,
                               const layout_t<TDynTraits>& lhs_type,
                               mlir::Value                 lhs_value,
                               const layout_t<TDynTraits>& rhs_type,
                               mlir::Value                 rhs_value)
{
    using eq_comp_container_t = llvm::SmallVector<detail::eq_comp_t>;
    using eq_comp_res_t       = detail::eq_comp_result_t<eq_comp_container_t>;

    // Perform an equality comparison on the layout shapes
    eq_comp_res_t cmp_check_sh = detail::check_equality<eq_comp_container_t>(lhs_type.shape(),
                                                                             rhs_type.shape());
    if(std::holds_alternative<bool>(cmp_check_sh) && !std::get<bool>(cmp_check_sh))
    {
        auto intAttr = mlir::IntegerAttr::get(b.getI1Type(), false);
        return mlir::arith::ConstantOp::create(b, loc, intAttr);
    }

    // Perform an equality comparison on the layout strides
    eq_comp_res_t cmp_check_str = detail::check_equality<eq_comp_container_t>(lhs_type.stride(),
                                                                              rhs_type.stride());
    if(std::holds_alternative<bool>(cmp_check_str) && !std::get<bool>(cmp_check_str))
    {
        auto intAttr = mlir::IntegerAttr::get(b.getI1Type(), false);
        return mlir::arith::ConstantOp::create(b, loc, intAttr);
    }

    mlir::Value cmp_res{};
    if(!std::holds_alternative<bool>(cmp_check_sh))
    {
        mlir::Value lhs_shape = get_layout_shape_value(b, loc, lhs_value);
        mlir::Value rhs_shape = get_layout_shape_value(b, loc, rhs_value);
        cmp_res               = detail::chain_rec_var_eq_cmp(b,
                                               loc,
                                               lhs_type.shape(),
                                               lhs_shape,
                                               rhs_type.shape(),
                                               rhs_shape,
                                               cmp_res,
                                               cmp_check_sh);
    }
    if(!std::holds_alternative<bool>(cmp_check_str))
    {
        mlir::Value lhs_stride = get_layout_stride_value(b, loc, lhs_value);
        mlir::Value rhs_stride = get_layout_stride_value(b, loc, rhs_value);
        cmp_res                = detail::chain_rec_var_eq_cmp(b,
                                               loc,
                                               lhs_type.stride(),
                                               lhs_stride,
                                               rhs_type.stride(),
                                               rhs_stride,
                                               cmp_res,
                                               cmp_check_str);
    }

    return cmp_res;
}

template <class TAlgebra,
          class TValueContainer>
bool mlir_value_types_are_valid(const TAlgebra&        a,
                                const TValueContainer& values)
{
    // Note: We may be able to expand this to TypedValues or something else
    // that inherits from Value.
    static_assert(std::is_same_v<mlir::Value, typename TValueContainer::value_type>);
    if(is_static(a))
    {
        // Return false if MLIR Values are provided for a fully static algebra
        // value.
        return values.empty();
    }
    if(values.empty())
    {
        // Return false if no MLIR Values were provided for a non-static algebra
        // value.
        return false;
    }
    mlir::MLIRContext* ctx = values[0].getContext();
    assert(ctx);
    llvm::SmallVector<mlir::Type> scalar_types;
    collect_scalar_types(ctx, a, scalar_types, /*dynamic_only=*/true);
    for(size_t i = 0; i < scalar_types.size(); ++i)
    {
        if(scalar_types[i] != values[i].getType())
        {
            return false;
        }
    }
    return true;
}

template <class TAlgebra,
          class TValueContainer>
void convert_int_values(mlir::OpBuilder& builder,
                        mlir::Location   loc,
                        const TAlgebra&  a,
                        TValueContainer& values)
{
    // Note: We may be able to expand this to TypedValues or something else
    // that inherits from Value.
    static_assert(std::is_same_v<mlir::Value, typename TValueContainer::value_type>);
    if(values.empty())
    {
        return;
    }
    mlir::MLIRContext* ctx = builder.getContext();
    assert(ctx);
    llvm::SmallVector<mlir::Type> scalar_types;
    collect_scalar_types(ctx, a, scalar_types, /*dynamic_only=*/true);
    for(size_t i = 0; i < scalar_types.size(); ++i)
    {
        if(scalar_types[i] != values[i].getType())
        {
            // Some scalars may have pointer types, so we only try to convert
            // integral types.
            if(llvm::isa<mlir::IntegerType>(scalar_types[i]) &&
               llvm::isa<mlir::IntegerType>(values[i].getType()))
            {
                values[i] = cast_integral_value_to_type(builder,
                                                        loc,
                                                        values[i],
                                                        llvm::cast<mlir::IntegerType>(scalar_types[i]));
            }
        }
    }
}

template <class TAlgebra,
          class TValueContainer>
void convert_int_values(mlir::ImplicitLocOpBuilder& builder,
                        const TAlgebra&             a,
                        TValueContainer&            values)
{
    convert_int_values(builder, builder.getLoc(), a, values);
}

/// Enable hashing for certain cutegen types
inline llvm::hash_code hash_value(const swizzle& sw)
{
    return ::llvm::hash_value(sw.get_hash_tuple());
}

//
// Type aliases
//

// Type aliases for common CuTe types used in MLIR
// DO NOT USE OUTSIDE DEFAULT TYPE TEMPLATE ARGUMENTS
using scaled_basis    = scaled_basis_t<ratio, static_int_t, mlir_dynamic_t>;
using layout          = layout_t<mlir_dynamic_traits_t>;
using shape           = layout::shape_t;
using stride          = layout::stride_t;
using int_tuple       = cute_int_tuple_t<mlir_dynamic_traits_t>;
using coord           = cute_coord_t<mlir_dynamic_traits_t>;
using tile            = cute_tile_t<mlir_dynamic_traits_t>;
using composed_layout = composed_layout_t<mlir_dynamic_traits_t>;

/// Unit basis element, this is repeated for the scaled_basis alias in cutegen_base_dynamic.hpp and this header
template <class... AdditionalModes>
scaled_basis E(scaled_basis::mode_value_t mode0, AdditionalModes... modes)
{
    return scaled_basis::E(mode0, modes...);
}
} // namespace cutegen

#endif // !defined(CUTEGEN_MLIR_HPP_INCLUDED_)
