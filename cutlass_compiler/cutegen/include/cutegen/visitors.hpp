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

#if !defined(CUTEGEN_VISITORS_HPP_INCLUDED_)
#define CUTEGEN_VISITORS_HPP_INCLUDED_

#include "cutegen/rec_var.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/composed_layout.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// visitors.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class TContainer, class TAlgebra>
void collect_dynamics(TContainer& c, const TAlgebra& a);

template <class TContainer, class TAlgebra>
TContainer get_dynamics(const TAlgebra& a);

/// Resets the properties of all dynamic_t instances in the algebra instance `a` to their default
/// values.
template <class TAlgebra>
void reset_properties_to_default(TAlgebra& a);

/// Returns a pair with the min and max values of the scalars for a given value
/// (typically a recursive variant, int, or dynamic integer). This can be used
/// to, for example, verify that all elements of a shape can be represented by
/// a 32-bit quantity.
template <class TAlgebra>
int_range_t get_scalar_range(const TAlgebra& a);

template <class TAlgebra>
int_range_t get_static_scalar_range(const TAlgebra& a);

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// visitors.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{

template <class TContainer>
struct collect_dynamics_visitor
{
public:
    explicit collect_dynamics_visitor(TContainer& c_) :
        c(c_) {}

    template <class TIntegral, std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
    void operator()(TIntegral) {}
    void operator()(cg_error_t) {}
    void operator()(underscore_t) {}
    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& d) { c.push_back(d); }
    template <class... TValTypes>
    void operator()(const scaled_basis_t<TValTypes...>& sb)
    {
        if(!sb.is_static()) c.push_back(sb.dynamic_value());
    }

    template <class TVec>
    void operator()(const std::vector<TVec>& v)
    {
        for(const auto& e : v) this->operator()(e);
    }

    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& l)
    {
        this->operator()(l.shape());
        this->operator()(l.stride());
    }
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& l)
    {
        if(l.is_a_affine())
            this->operator()(l.layout_a());
        this->operator()(l.layout_b());
        this->operator()(l.offset());
    }

    template <class... Ts>
    void operator()(const rec_var_base<Ts...>& rv)
    {
        visit(*this, rv);
    }

private:
    TContainer& c;
};

struct reset_properties_to_default_visitor
{
public:
    template <class TIntegral, std::enable_if_t<std::is_integral<TIntegral>::value, bool> = true>
    void operator()(TIntegral) {}
    void operator()(cg_error_t) {}
    void operator()(underscore_t) {}
    void operator()(ratio) {}

    template <class TDynamic, std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(TDynamic& d)
    {
        d.properties = dynamic_int_properties_t{};
    }
    template <class TDynamic, std::enable_if_t<has_dynamic_ptr_t_base<TDynamic>::value, bool> = true>
    void operator()(TDynamic& d)
    {
        // reset the bitwidth doesn't make sense here, so we just reset the alignment
        d.properties.alignment_bytes = dynamic_ptr_properties_t::default_alignment_for_width(d.properties.value_width_bits);
    }
    template <class... TValTypes>
    void operator()(scaled_basis_t<TValTypes...>& sb)
    {
        this->operator()(sb.value());
    }

    template <class TVec>
    void operator()(std::vector<TVec>& v)
    {
        for(auto& e : v) this->operator()(e);
    }

    template <class TDynTraits>
    void operator()(layout_t<TDynTraits>& l)
    {
        this->operator()(l.shape());
        this->operator()(l.stride());
    }
    template <class TDynTraits>
    void operator()(composed_layout_t<TDynTraits>& l)
    {
        if(l.is_a_affine())
            this->operator()(l.layout_a());
        this->operator()(l.layout_b());
        this->operator()(l.offset());
    }

    template <class... Ts>
    void operator()(std::variant<Ts...>& v)
    {
        visit(*this, v);
    }
    template <class... Ts>
    void operator()(rec_var_base<Ts...>& rv)
    {
        visit(*this, rv);
    }
};

/**
 * @brief Callable object for either counting scalars (all scalars or only
 *        dynamic), or alternatively determining whether there is one or more
 *        dynamic values.
 *
 * Instances of this struct should be used as follows:
 * ```cpp
 * scalars_counter ctr(true, true);
 * ctr(my_value);
 * size_t num = ctr.get_count();
 * ```
 * A "scalar" in this context refers to a single value used as part of the
 * state of a type. This includes:
 * - static integers
 * - dynamic integers
 * - swizzle parameters
 * - scaled basis value (integer, ratio (num + denom), dynamic integer)
 * - scaled basis modes
 *
 * (Note that underscore values are NOT considered scalars, and are not counted.)
 *
 * The first constructor argument indicates whether only dynamic values should
 * be counted (true), or ALL values should be counted (false).
 * The second constructor argument indicates whether the counter should
 * terminate once the count becomes greater than zero. (This may be useful as a
 * performance optimization for an implementation of the is_static() method,
 * in conjunction with the dynamic_only constructor argument: the precise
 * number of dynamic values is not important, but we are only interested in
 * whether there is 1 or more.)
 */
struct scalar_counter
{
    scalar_counter(bool dynamic_only,
                   bool nonzero_only) :
        cnt_(0),
        dynamic_only_(dynamic_only),
        nonzero_only_(nonzero_only)
    {
    }
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    void operator()(TInt i)
    {
        if(!dynamic_only_)
            ++cnt_;
    }
    void operator()(cg_error_t)
    {
        // We don't expect error types in valid IR...
    }
    template <class TElem>
    void operator()(const std::vector<TElem>& v)
    {
        for(auto& e : v)
        {
            visit(*this, e);
            if(nonzero_only_ && (0 != cnt_))
            {
                return;
            }
        }
    }
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    void operator()(const TDynamic& d)
    {
        ++cnt_;
    }
    void operator()(underscore_t)
    {
        // Underscore is not represented by a scalar value
    }
    template <class... TValueTypes>
    void operator()(const scaled_basis_t<TValueTypes...>& sb)
    {
        // Dispatch based on the type of the value variant
        std::visit(*this, sb.value());
        if(!dynamic_only_)
        {
            cnt_ += sb.modes().size();
        }
    }
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        // Visit the shape recursive variant
        visit(*this, ly.shape());
        if(nonzero_only_ && (0 != cnt_))
        {
            return;
        }
        // Visit the stride recursive variant
        visit(*this, ly.stride());
    }
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& cly)
    {
        // Visit the a variant (swizzle or layout)
        visit(*this, cly.a());
        if(nonzero_only_ && (0 != cnt_))
        {
            return;
        }
        // Visit the offset recursive variant
        visit(*this, cly.offset());
        if(nonzero_only_ && (0 != cnt_))
        {
            return;
        }
        // Process the b layout
        this->operator()(cly.layout_b());
    }
    template <class TRecVar,
              std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
    void operator()(const TRecVar& rv)
    {
        // Dispatch based on the type held by the variant
        visit(*this, rv);
    }
    void operator()(const swizzle&)
    {
        if(!dynamic_only_)
        {
            cnt_ += 3;
        }
    }
    void operator()(const ratio&)
    {
        if(!dynamic_only_)
        {
            cnt_ += 2;
        }
    }
    size_t get_count() const { return cnt_; }

private:
    size_t cnt_;
    bool   dynamic_only_;
    bool   nonzero_only_;
};

/**
 * @brief Callable object for determining the min/max range of scalars for an
 *        input value.
 *
 */
template <bool IncludeDynamic = true>
struct scalar_range_visitor
{
public:
    scalar_range_visitor() :
        range_{std::numeric_limits<static_int_t>::max(),
               std::numeric_limits<static_int_t>::min()}
    {
    }
    // Visitor for integral types
    template <typename TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    void operator()(TInt i)
    {
        range_.first  = std::min(static_cast<static_int_t>(i), range_.first);
        range_.second = std::max(static_cast<static_int_t>(i), range_.second);
    }
    // Visitor for dynamic integer values. We use the base class here and query
    // the properties.
    void operator()(const dynamic_t& d)
    {
        if constexpr(IncludeDynamic)
        {
            range_.first  = d.get_properties().minimum();
            range_.second = d.get_properties().maximum();
        }
    }
    // Visitor for underscore values.
    void operator()(const underscore_t& d)
    {
    }
    // Visitor for ratio values.
    void operator()(const ratio& r)
    {
        this->operator()(r.num());
        this->operator()(r.denom());
    }
    // Visitor for variant types.
    template <class... TVarTypes>
    void operator()(const std::variant<TVarTypes...>& var)
    {
        // Invoke operator() for the type held by var
        std::visit(*this, var);
    }
    // Visitor for scaled_basis values.
    template <class... TValTypes>
    void operator()(const scaled_basis_t<TValTypes...>& sb)
    {
        this->operator()(sb.value());
    }
    // Visitor for swizzle values.
    void operator()(const swizzle& sw)
    {
        this->operator()(sw.num_bits());
        this->operator()(sw.num_base());
        this->operator()(sw.num_shift());
    }
    // Visitor for layout values (e.g. in cute_tile_t).
    template <class TDynTraits>
    void operator()(const layout_t<TDynTraits>& ly)
    {
        this->operator()(ly.shape());
        this->operator()(ly.stride());
    }
    // Visit the elements of the composed layout to collect their scalar range.
    template <class TDynTraits>
    void operator()(const composed_layout_t<TDynTraits>& cly)
    {
        this->operator()(cly.layout_b());
        this->operator()(cly.offset());
        this->operator()(cly.a());
    }
    // Visitor for vector types (as might be held by recursive variants)
    template <class TVecType>
    void operator()(const std::vector<TVecType>& v)
    {
        for(auto& e : v)
        {
            this->operator()(e);
        }
    }
    // Visitor for recursive variants
    template <class TRecVar,
              std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
    void operator()(const TRecVar& rv)
    {
        visit(*this, rv);
    }
    void operator()(cg_error_t)
    {
    }
    template <class TAlgebra>
    int_range_t get_range(const TAlgebra& a)
    {
        range_ = std::make_pair(std::numeric_limits<static_int_t>::max(),
                                std::numeric_limits<static_int_t>::min());
        this->operator()(a);
        return range_;
    }

private:
    int_range_t range_;
};

} // namespace detail

template <class TContainer, class TAlgebra>
void collect_dynamics(TContainer& c, const TAlgebra& a)
{
    detail::collect_dynamics_visitor{c}(a);
}

template <class TContainer, class TAlgebra>
TContainer get_dynamics(const TAlgebra& a)
{
    TContainer res;
    detail::collect_dynamics_visitor{res}(a);
    return res;
}

template <class TAlgebra>
void reset_properties_to_default(TAlgebra& a)
{
    detail::reset_properties_to_default_visitor{}(a);
}

template <class T>
bool is_static(const T& t)
{
    detail::scalar_counter ctr(/*dynamic_only=*/true, /*nonzero_only=*/true);
    ctr(t);
    return (0 == ctr.get_count());
}

template <class T>
auto scalar_count(const T& t, bool bDynamicOnly)
{
    detail::scalar_counter ctr(bDynamicOnly, /*nonzero_only=*/false);
    ctr(t);
    return ctr.get_count();
}

template <class TAlgebra>
int_range_t get_scalar_range(const TAlgebra& a)
{
    detail::scalar_range_visitor<true> srv{};
    return srv.get_range(a);
}

template <class TAlgebra>
int_range_t get_static_scalar_range(const TAlgebra& a)
{
    detail::scalar_range_visitor<false> srv{};
    return srv.get_range(a);
}

} // namespace cutegen
#endif
