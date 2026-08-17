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

#if !defined(CUTEGEN_COMPOSED_LAYOUT_HPP_INCLUDED_)
#define CUTEGEN_COMPOSED_LAYOUT_HPP_INCLUDED_

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iosfwd>
#include <limits>
#include <optional>
#include <cstdlib>
#include <string>
#include <tuple>
#include <type_traits>
#include <utility>
#include <variant>

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/cg_int.hpp"
#include "cutegen/swizzle.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/layout.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// composed_layout.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Composed layout class.
 *
 * The layout_t class implements CuTe's affine layouts. Given layouts
 * `lA : SA -> DA` and `lB : SB -> DB`,
 * assuming `SA` contains `DB`,
 * one can always formally write the functional composition `lA o lB`. When certain conditions are
 * verified (e.g. the so-called divisibility condition), `lA o lB` can also be written in the form
 * of an affine layout. The composition() function implements just that.
 *
 * Two use cases (at least) call for a more general abstraction:
 * 1. position-independent swizzling, which applies the swizzling function `sw` as
 *    `ptr_to_elem = base_ptr + sw(affine_layout_offset)` (in contrast to position-dependent
 *    swizzling which goes like `ptr_to_elem = sw(base_ptr + affine_layout_offset)`) cannot always
 *    be supported by affine layouts
 * 2. tiling convolution multi-modes with a single tile size in order to perform gemms as if the
 *    multi-mode were a single mode when the multi-mode is not divisible (in the sense of CuTe) by
 *    the tile size.
 *
 * Therefore, composed layouts are introduced. They are written as `A o off_func o B` and maps a
 * coordinate `c` in the domain of `B` as `A(off + B(c))`. `A` is either an affine layout or a
 * swizzle function. When `A` is a swizzle function, the object is referred to as a "swizzled
 * layout". Most operations in the algebra for affine layouts simply applies to `B` and `A` provides
 * another level of indirection that doesn't reduce overall to a single affine layout.
 */
template <class TDynTraits>
class composed_layout_t
{
public:
    using dyn_traits_t = TDynTraits;
    using layout_t     = cutegen::layout_t<dyn_traits_t>;
    using int_t        = typename layout_t::int_t;
    using a_variant_t  = std::variant<swizzle, layout_t>;
    using shape_t      = typename layout_t::shape_t;
    using stride_t     = typename layout_t::stride_t;
    using offset_t     = cute_int_tuple_t<dyn_traits_t>;
    using dyn_t        = typename dyn_traits_t::dynamic_int_t;

private:
    a_variant_t A;
    // If B is a normal layout, off should be an integer or a dynamic value
    // If B is a TMA layout, off should be a CuTe coordinate
    // All cases are handled by an off member of shape type
    offset_t off;
    layout_t B;

public:
    composed_layout_t() = default;
    composed_layout_t(layout_t A_, offset_t off_, layout_t B_);
    composed_layout_t(swizzle A_, offset_t off_, layout_t B_);
    composed_layout_t(a_variant_t A_, offset_t off_, layout_t B_);
    composed_layout_t(swizzle sw);
    // The offset defaults to 0
    composed_layout_t(swizzle sw, layout_t B_);
    // A composed layout constructed as an affine layout
    // CuTe uses S<0,4,3> for the identity swizzle
    composed_layout_t(layout_t l);
    // Constructor for an invalid composed layout
    composed_layout_t(cg_error_t);

    bool operator==(const composed_layout_t<dyn_traits_t>& other) const;
    bool operator!=(const composed_layout_t<dyn_traits_t>& other) const;

    // Accessors
    const a_variant_t& a() const;
    a_variant_t&       a();
    const layout_t&    layout_a() const;
    layout_t&          layout_a();
    const swizzle&     swizzle_a() const;
    swizzle&           swizzle_a();
    const offset_t&    offset() const;
    offset_t&          offset();
    const layout_t&    layout_b() const;
    layout_t&          layout_b();
    const shape_t&     shape() const;
    shape_t&           shape();
    const stride_t&    stride() const;
    stride_t&          stride();
    // Shortcut to a_affine layout's shape/stride
    const shape_t&  shape_a() const;
    shape_t&        shape_a();
    const stride_t& stride_a() const;
    stride_t&       stride_a();

    bool is_a_affine() const;
    bool is_a_swizzle() const;
    bool is_normal_layout() const;

    template <class TCoord>
    auto operator()(const TCoord& coord) const;

    template <class OtherLayout>
    composed_layout_t
    compose(const OtherLayout& other) const;
    template <class OtherShape>
    composed_layout_t with_shape(const OtherShape& shape) const;

    auto rank() const;
};

//
// Type manipulation
//

template <class T>
struct is_composed_layout : std::false_type
{};

template <class TDynTraits>
struct is_composed_layout<composed_layout_t<TDynTraits>> : std::true_type
{};

//
// Utilities
//

template <class TDynTraits>
std::ostream& operator<<(std::ostream& os, const composed_layout_t<TDynTraits>& ly);

//
// Core API
//

/// Checks if a composed layout has an error.
template <class TDynTraits>
bool has_error(const composed_layout_t<TDynTraits>& l);

template <class TDynTraits>
bool is_valid(const composed_layout_t<TDynTraits>& l);

template <class TDynTraits>
size_t rank(const composed_layout_t<TDynTraits>& lay);

template <class TDynTraits>
size_t rank(const composed_layout_t<TDynTraits>& lay, int mode);

/**
 * @brief Get depth of composed layout which is depth of layout_b
 *
 * @tparam TDynTraits
 * @param lay
 * @return size_t
 */
template <class TDynTraits>
size_t depth(const composed_layout_t<TDynTraits>& lay);

template <class TDynTraits, class TRange>
bool check_get_indices(const composed_layout_t<TDynTraits>& l, const TRange& r);

/// Gets a direct sub-layout from `l`.
template <class TDynTraits>
auto get(const composed_layout_t<TDynTraits>& l, size_t mode);

/// Gets a potentially nested sub-layout from `cly`.
template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto get(const composed_layout_t<TDynTraits>& cly, const TRange& modes);

/// Gets a potentially nested sub-layout from `cly`.
template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
auto get(const composed_layout_t<TDynTraits>& cly, TInt... idx);

/// Selects specific dimensions from `cly`
template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto select(const composed_layout_t<TDynTraits>& cly, const TRange& modes);

/// Selects specific dimensions from `cly`
template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
auto select(const composed_layout_t<TDynTraits>& cly, TInt... idx);

/**
 * @brief Checks whether two composed layouts have the same profile
 *
 * @return false
 */
template <class TDynTraits>
bool is_congruent(const composed_layout_t<TDynTraits>& layoutA,
                  const composed_layout_t<TDynTraits>& layoutB);

template <class... Ts, class TDynTraits>
bool weakly_congruent(const rec_var_base<Ts...>& lhs, const composed_layout_t<TDynTraits>& rhs);

template <class TDynTraits>
auto flatten(const composed_layout_t<TDynTraits>& l);

template <class TCoord, class TDynTraits>
auto slice(const TCoord& crd, const composed_layout_t<TDynTraits>& lay);

template <class TCoord, class TDynTraits>
auto dice(const TCoord& crd, const composed_layout_t<TDynTraits>& lay);

template <class TCoord, class TDynTraits>
auto slice_and_offset(const TCoord& crd, const composed_layout_t<TDynTraits>& lay);

// Compute a pointer offset and (potentially modified) layout from a coordinate
template <class TCoord, class TDynTraits>
auto domain_offset(const TCoord& c, const composed_layout_t<TDynTraits>& l);

template <class TDynTraits>
auto append_to_rank_N(size_t N, const composed_layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e);

template <class TDynTraits>
auto prepend_to_rank_N(size_t N, const composed_layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e);

template <class TDynTraits>
auto group(int B, int E, const composed_layout_t<TDynTraits>& l);

// Replace the modes in the shape of a layout that have a static 0-stride with a 1-size
template <class TDynTraits>
auto filter_zeros(const composed_layout_t<TDynTraits>& l);

template <class TDynTraits, class TShape>
auto filter_zeros(const composed_layout_t<TDynTraits>& l, const TShape& target_profile);

template <class TDynTraits>
auto filter(const composed_layout_t<TDynTraits>& l);

/**
 * @brief For stride-1 mode, divide size by N. Divide all other strides by N.
 *
 * @tparam TDynTraits  template parameter of input layout type
 * @param N         divisor
 * @param layout    Input layout
 * @return auto     Output layout
 */
template <class TDynTraits>
composed_layout_t<TDynTraits> upcast(typename composed_layout_t<TDynTraits>::int_t N,
                                     const composed_layout_t<TDynTraits>&          layout);

/**
 * @brief For stride-1 mode, multiply size by N. Multiply all other strides by N.
 *
 * @tparam TDynTraits  template parameter of input layout type
 * @param N         divisor
 * @param layout    Input layout
 * @return auto     Output layout
 */
template <class TDynTraits>
composed_layout_t<TDynTraits> downcast(typename composed_layout_t<TDynTraits>::int_t N,
                                       const composed_layout_t<TDynTraits>&          layout);

/**
 * @brief Determine the maximum alignment of a Composed Layout.
 *
 *   gcd(max_alignment(layout_a), max_alignment(offset), max_alignment(layout_b))
 *
 *   * For layout_b with scale basis, alignment is 1
 *   * For affine layout, alignment is 1
 *
 * @tparam TDynTraits
 * @param layout
 * @return int
 */
template <class TDynTraits>
inline typename composed_layout_t<TDynTraits>::layout_t::int_t
max_alignment(const composed_layout_t<TDynTraits>& layout);

template <class TDynTraits>
auto size(const composed_layout_t<TDynTraits>& l);

template <class TDynTraits>
auto static_size(const composed_layout_t<TDynTraits>& l);

/**
 * @brief Returns the cosize of a composed_layout.
 *
 * For a composed layout `l = a o b`, `cosize(l) = cosize(b) = b(size(b)-1)+1`.
 */
template <class TDynTraits>
auto cosize(const composed_layout_t<TDynTraits>& layout);

template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto cosize(const composed_layout_t<TDynTraits>& layout, const TRange& idx);

/**
 * @brief Returns the cosize of a composed_layout that is statically known.
 *
 * @pre is_static(layout.layout_b())
 */
template <class TDynTraits>
auto static_cosize(const composed_layout_t<TDynTraits>& layout);

template <class TDynTraits>
auto coalesce(const composed_layout_t<TDynTraits>& l);

template <class TDynTraits, class TRecVar>
auto coalesce(const composed_layout_t<TDynTraits>& l, const TRecVar& trg_profile);

// Builds the right inverse of a composed layout.
template <class TDynTraits>
auto right_inverse(const composed_layout_t<TDynTraits>& layout);

template <class TDynTraits, class TRhs>
auto composition(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto logical_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto zipped_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto tiled_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto flat_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto logical_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto zipped_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto tiled_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto flat_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto blocked_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits, class TRhs>
auto raked_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs);

template <class TDynTraits,
          class ModeOrder = gen_col_major>
auto tile_to_shape(const composed_layout_t<TDynTraits>& l,
                   const cute_shape_t<TDynTraits>&      trg_shape,
                   const ModeOrder&                     ord = {});

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// composed_layout.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
//
// To/From strings
//

template <class TDynTraits>
struct value_to_string<composed_layout_t<TDynTraits>>
{
    using clayout = composed_layout_t<TDynTraits>;
    static std::string to_str(const clayout& ly)
    {
        if(ly.is_normal_layout())
        {
            return to_string(ly.layout_b());
        }
        else
        {
            std::string str = to_string(ly.a());
            str += " o ";
            str += to_string(ly.offset());
            str += " o ";
            str += to_string(ly.layout_b());
            return str;
        }
    }
};

// Specialization of detail::cg_from_chars for composed_layout_t
template <class TDynTraits>
class cg_from_chars<composed_layout_t<TDynTraits>> : public cg_from_chars_base<composed_layout_t<TDynTraits>>
{
public:
    using clayout     = composed_layout_t<TDynTraits>;
    using a_variant_t = typename clayout::a_variant_t;
    using layout      = layout_t<TDynTraits>;
    using offset_t    = typename clayout::offset_t;
    cg_from_chars(const char* first, const char* last, bool must_consume_all) :
        cg_from_chars_base<clayout>(first, last, must_consume_all)
    {
        auto compose_sep_0 = std::find(first, last, 'o');
        if(compose_sep_0 == last)
        {
            auto b = this->template parse_type<layout>();
            if(!b.has_value())
            {
                // Error: could not parse b (layout)
                return;
            }
            // Success (pending check for must_consume_all).
            this->set_value_with_check(clayout(b.value()));
            return;
        }
        // Parse A (either a swizzle or a layout)
        // We need to constrain the recursive variant parser for the layout_a/swizzle,
        // as it will attempt to parse up before to the first 'o'.
        auto a = this->template parse_type_up_to<a_variant_t>(compose_sep_0);
        if(!a.has_value())
        {
            // Error: could not parse either a swizzle or a layout
            return;
        }
        auto sep_0 = this->template parse_type<token_composition>();
        if(!sep_0.has_value())
        {
            // Error: first composition token not found
            return;
        }
        // We need to constrain the recursive variant parser for the offset,
        // as it will attempt to parse up to the next ')' or ','.
        auto compose_sep_1 = std::find(this->get_ptr(), last, 'o');
        if(compose_sep_1 == last)
        {
            // Error: second composition token not found
            return;
        }
        // Attempt to parse the offset, updating offset_pos.
        auto off = this->template parse_type_up_to<offset_t>(compose_sep_1);
        if(!off.has_value())
        {
            // Error: could not parse an offset (shape)
            return;
        }
        auto sep_1 = this->template parse_type<token_composition>();
        if(!sep_1.has_value())
        {
            // Error: second composition token not found
            return;
        }
        auto b = this->template parse_type<layout>();
        if(!b.has_value())
        {
            // Error: could not parse b (layout)
            return;
        }
        // Success (pending check for must_consume_all).
        this->set_value_with_check(clayout(a.value(), off.value(), b.value()));
    }
};

//
// Encode/Decode
//

template <class TDynTraits>
struct value_encoder<composed_layout_t<TDynTraits>>
{
    template <class TBuffer>
    static void encode_value(const composed_layout_t<TDynTraits>& ly, TBuffer& buffer)
    {
        encode(buffer, ly.a());
        encode(buffer, std::numeric_limits<uint32_t>::max());
        encode(buffer, ly.offset());
        encode(buffer, std::numeric_limits<uint32_t>::max());
        encode(buffer, ly.layout_b());
    }
};

/// Specialization of value_decoder for composed layout types
template <class TCLayout>
struct value_decoder<TCLayout,
                     std::enable_if_t<is_composed_layout<TCLayout>::value>>
{
    template <class TIterator>
    static std::optional<TCLayout> decode_value(TIterator& it, const TIterator& end)
    {
        using lay_t       = typename TCLayout::layout_t;
        using a_variant_t = typename TCLayout::a_variant_t;

        std::optional<uint32_t> opt_sep;
        auto                    opt_a = decode<a_variant_t>(it, end);
        if(!opt_a.has_value())
            return {};

        // Decode separator
        opt_sep = decode<uint32_t>(it, end);
        if(!opt_sep.has_value() || (opt_sep.value() != std::numeric_limits<uint32_t>::max()))
            return {};
        // Decode offset
        auto opt_offset = decode<typename TCLayout::offset_t>(it, end);
        if(!opt_offset.has_value()) return {};
        // Decode separator
        opt_sep = decode<uint32_t>(it, end);
        if(!opt_sep.has_value() || (opt_sep.value() != std::numeric_limits<uint32_t>::max()))
            return {};
        // Decode B
        auto opt_layout_b = decode<lay_t>(it, end);
        if(!opt_layout_b.has_value()) return {};
        return TCLayout(opt_a.value(), opt_offset.value(), opt_layout_b.value());
    }
};

//
// slice_and_offset dispatch
//

template <class TCoord, class TDynTraits>
auto slice_and_offset(const TCoord&                       crd,
                      const layout_t<TDynTraits>&         lay_a,
                      const cute_int_tuple_t<TDynTraits>& off,
                      const layout_t<TDynTraits>&         lay_b)
{
    using comp_lay_t             = composed_layout_t<TDynTraits>;
    using off_t                  = typename comp_lay_t::offset_t;
    auto [sliced_layout, offset] = slice_and_offset(crd, lay_b);
    if(rank(sliced_layout) == 0)
    {
        // when sliced_layout is empty, we need to manually calculate the offset
        // lay_a(off + lay_b(offset))
        auto       calculated_offset = arith_tuple_sum<off_t>(off, offset);
        comp_lay_t l(lay_a,
                     calculated_offset,
                     std::move(sliced_layout));
        return std::make_tuple(std::move(l),
                               off_t(lay_a(calculated_offset)));
    }

    // When there wasn't any _ in crd, it's a regular layout_eval. A regular layout
    // would return ():() as the sliced layout. The current convention for composed layouts
    // is to return `lay_a o (off+offset) o ():()`
    // for the sliced layout. This matches what CuTe C++ does.
    comp_lay_t l(lay_a,
                 arith_tuple_sum<off_t>(off, offset),
                 std::move(sliced_layout));
    return std::make_tuple(std::move(l), off_t(0));
}

/**
 * @brief Computes a sliced layout and its offset for swizzled layouts.
 *
 * @pre @p lay_b is static, normal, with stride elements that are powers of 2
 * @pre @p off is a scalar
 * @pre @p crd is not empty and has at least one underscore
 *
 * When slicing into a swizzled layout, the result can be one of three things:
 * 1. another swizzled layout
 * 2. a non-static affine layout
 * 3. a static affine layout
 *
 * CuTe tracks all three cases with the `MixedBits` struct. Here, we only allow the decay into a
 * non-static affine layout. In such case, `get<0>(result).is_normal_layout()` is true and
 * `get<0>(result)` is actually equal to the affine layout `get<0>(result).layout_b()`.
 */
template <class TCoord, class TDynTraits>
auto slice_and_offset(const TCoord&                       crd,
                      const swizzle&                      sw_a,
                      const cute_int_tuple_t<TDynTraits>& off,
                      const layout_t<TDynTraits>&         lay_b)
{
    using composed_layout_t = composed_layout_t<TDynTraits>;
    using layout_t          = typename composed_layout_t::layout_t;
    using shape_t           = typename layout_t::shape_t;
    using stride_t          = typename layout_t::stride_t;
    using offset_t          = typename composed_layout_t::offset_t;
    // To disambiguate with the one in the detail namespace
    using ::cutegen::composition;

    // lay_b must be static, normal, with pow-2 stride elements
    if(!is_static(lay_b) || has_scaled_basis(lay_b.stride()))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    // The offset of the composed layout must be a (shape) scalar
    if(!holds_leaf(off))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    // Slice implies a non-empty coordinate which has at least one underscore
    if(is_empty(crd) || !has_underscore(crd))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    // If the coordinate only has underscores, don't attempt to decay into an affine layout
    if(is_underscore_only(crd))
        return std::make_tuple(composed_layout_t(sw_a, off, slice(crd, lay_b)), offset_t(0));

    const auto     M = sw_a.num_base();
    const auto     B = sw_a.num_bits();
    const auto     S = sw_a.num_shift();
    const layout_t projection_layout(shape_t(1 << M, 1 << B, 1 << (std::abs(S) - B), 1 << B, 1));
    const layout_t projection_layout_anti_zy(
        projection_layout.shape(),
        stride_t(projection_layout.stride()[0], 0, projection_layout.stride()[2], 0, rec_var_cast<stride_t>(size(projection_layout))));
    const layout_t projection_layout_only_zy(
        projection_layout.shape(),
        stride_t(0, projection_layout.stride()[1], 0, projection_layout.stride()[3], 0));

    const layout_t sliced_layout = slice(crd, lay_b);
    // A layout that is a slice of a static layout is also static
    if(!is_static(sliced_layout) || !is_valid(sliced_layout))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    // Composition with the swizzle Z/Y projection can fail (e.g. outer modes that
    // do not compose with the projection). Soft-error instead of static_size assert.
    // See NVIDIA/cutlass#3454: S<3,4,3> o 0 o (10,2):(2,1) + (_,0).
    const layout_t sliced_layout_only_zy = composition(projection_layout_only_zy, sliced_layout);
    if(!is_valid(sliced_layout_only_zy) || !holds_int(size(sliced_layout_only_zy)))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));

    const auto swizzle_active_bits = sliced_layout_only_zy(static_size(sliced_layout_only_zy) - 1);
    using index_t                  = decltype(swizzle_active_bits);
    // Some elements of the co-domain of sliced_layout are affected by sw_a if and only if they have
    // active Y-bits and Z-bits that would interact via sw_a. In order to determine if that's the
    // case, we take the bitwise AND between
    // 1. the largest element of the codomain of sliced_layout projected onto the Y and Z-bits, swizzle_active_bits
    // 2. the bitwise NOT of sw_a(swizzle_active_bits)
    // The result is non-zero if and only if some elements of the co-domain of lay_b are affected by
    // sw_a. We convert that to a boolean.
    const auto intersection = scalar_bitwise_and<index_t>(swizzle_active_bits,
                                                          scalar_bitwise_not<index_t>(sw_a(swizzle_active_bits)));
    if(!holds_int(intersection))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    //const bool z_and_y_collide = swizzle_active_bits & ~sw_a(swizzle_active_bits);
    const bool z_and_y_collide = (intersection != 0);

    const layout_t diced_layout         = dice(crd, lay_b);
    const TCoord   diced_crd            = dice(crd, crd);
    const layout_t diced_layout_only_zy = composition(projection_layout_only_zy, diced_layout);
    const layout_t diced_layout_anti_zy = composition(projection_layout_anti_zy, diced_layout);
    if(!is_valid(diced_layout_only_zy) || !is_valid(diced_layout_anti_zy))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));

    const auto idx_of_diced_coord_only_zy = diced_layout_only_zy(diced_crd);
    if(!holds_int_or_dynamic_int(idx_of_diced_coord_only_zy))
        return std::make_tuple(composed_layout_t(cg_error_t{}), offset_t(0));
    // Assuming that idx_of_diced_coord_only_zy is not static, the following bitwise XOR creates
    // a dynamic offset. In case we can degenerate the sliced swizzled layout into an affine layout,
    // the latter is doomed to be partially dynamic. CuTe-C++ further optimizes this by tracking
    // statically known bits with a statically known partition between static and dynamic bits,
    // making it possible to degenerate into a fully static affine layout. That optimization is not
    // implemented yet in cutegen. The performance benefits of such optimization is unknown.
    const auto offset_only_zy = scalar_bitwise_xor<offset_t>(off, idx_of_diced_coord_only_zy);
    const auto offset_anti_zy = diced_layout_anti_zy(diced_crd);

    // We cannot decay into an affine layout if there is some collision
    if(z_and_y_collide)
        return std::make_tuple(composed_layout_t(sw_a, offset_only_zy, sliced_layout), offset_anti_zy);

    // With two's complement, this retrieves the lowest bit in the mask
    // Ex: 0b0000111000
    //  -> 0b0000001000
    const auto lowest_z_bit = sw_a.z_mask() & -sw_a.z_mask();
    const auto lowest_y_bit = sw_a.y_mask() & -sw_a.y_mask();
    // At this point, we know that
    // 1. elements of the codomain of sliced_layout are not affected by sw_a
    // 2. pow-2 stride elements in lay_b implies that the set of bits to which each mode contributes
    //    are strictly disjoint with one another
    // 2 => elements of the codomain of sliced_layout and offset_only_zy/offset_anti_zy (stemming
    // from diced_layout) are disjoint bitwise.
    // Therefore,
    // sliced_composed_layout(c) = sw_a(composed_layout_off + slice_off + sliced_layout(c))
    //                           = sw_a(offset_only_zy + offset_anti_zy + sliced_layout(c))
    //                           = offset_anti_zy + sw_a(offset_only_zy + sliced_layout(c))
    //                             (no interaction between offset_anti_zy and sliced_layout(c))
    //
    // From now on, we denote offset_only_zy as off, the codomain of sliced layout as D,
    // lowest_z_bit as Z, and lowest_y_bit as Y for conciseness. Consider:
    // f: x in D -> sw_a(off + x)
    // We attempt to represent f as an affine layout that is valid on D (i.e. we don't care about
    // the result for x not in D).
    //
    // First case: What happens when we flip a Z-bit in x (i.e. what's the associated stride)?
    // x and x ^ (Z<<i) in D for some i in [0,sw_a.num_bits())
    // Disjointness implies off & (Z<<i) = 0
    // Absence of collision implies x & (Y<<i) = 0
    // Denote y0 = x & ~(Z<<i) and y1 = x | (Z<<i)
    // f(y0) - y0    = sw_a(off)
    // f(y1) - f(y0) =  (Z<<i) if and only if offset & (Y<<i) = 0
    //               = -(Z<<i) otherwise
    //
    // Second case: What happens when we flip a Y-bit in x?
    // x and x ^ (Y<<i) in D
    // Disjointness implies off & (Y<<i) = 0
    // Absence of collision implies x & (Z<<i) = 0
    // Denote y0 = x & ~(Y<<i) and y1 = x | (Y<<i)
    // f(y0) - y0    =  sw_a(off)
    // f(y1) - f(y0) = (Y+Z)<<i if and only if offset & (Z<<i) = 0
    //               = (Y-Z)<<i otherwise
    //
    // Third case: Flipping any other bit neither interacts with off, nor sw_a
    // f(x) = sw_a(off) + x
    //
    // We thus construct swizzle_layout which behaves like f on D.
    auto make_swizzle_stride_zbit = [=]() //
    {
        stride_t res;
        for(unsigned int i = 0; i < sw_a.num_bits(); i++)
        {
#ifndef NDEBUG
            const bool ok = detail::is_integral_cast_safe<unsigned, typename shape_t::int_t>(
                std::max(lowest_y_bit, lowest_z_bit) << i);
            assert(ok);
#endif
            const auto offset_ith_y_bit = scalar_bitwise_and<offset_t>(offset_only_zy, lowest_y_bit << i);
            const auto stride_elem      = cond_assign(
                detail::scalar_cmp<offset_t, offset_t, comp_pred::eq>(offset_ith_y_bit, 0),
                [=]() -> stride_t {
                    return static_cast<typename offset_t::int_t>(lowest_z_bit << i);
                },
                [=]() -> stride_t {
                    return -static_cast<typename offset_t::int_t>(lowest_z_bit << i);
                });
            res.append(stride_elem);
        }
        return res;
    };
    auto make_swizzle_stride_ybit = [=]() //
    {
        stride_t res;
        for(unsigned int i = 0; i < sw_a.num_bits(); i++)
        {
#ifndef NDEBUG
            const bool ok = detail::is_integral_cast_safe<unsigned, typename offset_t::int_t>(
                (lowest_y_bit + lowest_z_bit) << i);
            assert(ok);
#endif
            const auto offset_ith_z_bit = scalar_bitwise_and<offset_t>(offset_only_zy, lowest_z_bit << i);
            const auto stride_elem      = cond_assign(
                detail::scalar_cmp<offset_t, offset_t, comp_pred::eq>(offset_ith_z_bit, 0),
                [=]() -> stride_t {
                    return static_cast<typename offset_t::int_t>(lowest_y_bit << i) +
                           static_cast<typename offset_t::int_t>(lowest_z_bit << i);
                },
                [=]() -> stride_t {
                    return static_cast<typename offset_t::int_t>(lowest_y_bit << i) -
                           static_cast<typename offset_t::int_t>(lowest_z_bit << i);
                });
            res.append(stride_elem);
        }
        return res;
    };
    const stride_t stride_lo   = (lowest_z_bit < lowest_y_bit) ? make_swizzle_stride_zbit() : make_swizzle_stride_ybit();
    const stride_t stride_hi   = (lowest_z_bit < lowest_y_bit) ? make_swizzle_stride_ybit() : make_swizzle_stride_zbit();
    const shape_t  shape_lo_hi = repeat<shape_t, typename shape_t::int_t>(sw_a.num_bits(), 2);
    // clang-format off
    const layout_t   swizzle_layout(
        cat_tuple(shape_t(1 << M), shape_lo_hi, shape_t(1 << (std::abs(S) - B)), shape_lo_hi, shape_t(1)),
        cat_tuple(stride_t(1),     stride_lo,   stride_t(1 << (M + B)),          stride_hi,   stride_t(1 << (M + B + std::abs(S)))));
    // clang-format on
    return std::make_tuple(composed_layout_t(composition(swizzle_layout, sliced_layout)),
                           scalar_add<offset_t>(sw_a(offset_only_zy), offset_anti_zy));
}
} // namespace detail

template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(layout_t A_, offset_t off_, layout_t B_) :
    A(std::move(A_)), off(std::move(off_)), B(std::move(B_)){};

template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(swizzle A_, offset_t off_, layout_t B_) :
    A(std::move(A_)), off(std::move(off_)), B(std::move(B_)){};

template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(a_variant_t A_, offset_t off_, layout_t B_) :
    A(std::move(A_)), off(std::move(off_)), B(std::move(B_)){};

template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(swizzle sw) :
    A(std::move(sw)),
    off(0),
    B(layout_t(shape_t(sw.num_base() + sw.num_bits() + std::abs(sw.num_shift())))){};

// The offset defaults to 0
template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(swizzle sw, layout_t B_) :
    A(std::move(sw)), off(0), B(std::move(B)) {}

// A composed layout constructed as an affine layout
// CuTe uses S<0,4,3> for the identity swizzle
template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(layout_t l) :
    A(swizzle(0, 4, 3)), off(0), B(std::move(l)) {}

// Constructor for an invalid composed layout
template <class TDynTraits>
composed_layout_t<TDynTraits>::composed_layout_t(cg_error_t) :
    A(layout_t(cg_error_t{})), off(0), B(layout_t(cg_error_t{})) {}

template <class TDynTraits>
bool composed_layout_t<TDynTraits>::operator==(const composed_layout_t<TDynTraits>& other) const
{
    return (a() == other.a()) &&
           (offset() == other.offset()) &&
           (layout_b() == other.layout_b());
}

template <class TDynTraits>
bool composed_layout_t<TDynTraits>::operator!=(const composed_layout_t<TDynTraits>& other) const
{
    return !(*this == other);
}

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::a_variant_t&
composed_layout_t<TDynTraits>::a() const { return A; }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::a_variant_t&
composed_layout_t<TDynTraits>::a() { return A; }

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::layout_t&
composed_layout_t<TDynTraits>::layout_a() const
{
    assert(std::holds_alternative<layout_t>(A));
    return std::get<layout_t>(A);
}

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::layout_t&
composed_layout_t<TDynTraits>::layout_a()
{
    assert(std::holds_alternative<layout_t>(A));
    return std::get<layout_t>(A);
}

template <class TDynTraits>
const swizzle& composed_layout_t<TDynTraits>::swizzle_a() const
{
    assert(std::holds_alternative<swizzle>(A));
    return std::get<swizzle>(A);
}

template <class TDynTraits>
swizzle& composed_layout_t<TDynTraits>::swizzle_a()
{
    assert(std::holds_alternative<swizzle>(A));
    return std::get<swizzle>(A);
}

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::offset_t&
composed_layout_t<TDynTraits>::offset() const { return off; }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::offset_t&
composed_layout_t<TDynTraits>::offset() { return off; }

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::layout_t&
composed_layout_t<TDynTraits>::layout_b() const { return B; }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::layout_t&
composed_layout_t<TDynTraits>::layout_b() { return B; }

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::shape_t&
composed_layout_t<TDynTraits>::shape() const { return B.shape(); }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::shape_t&
composed_layout_t<TDynTraits>::shape() { return B.shape(); }

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::stride_t&
composed_layout_t<TDynTraits>::stride() const { return B.stride(); }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::stride_t&
composed_layout_t<TDynTraits>::stride() { return B.stride(); }

// Shortcut to a_affine layout's shape/stride
template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::shape_t&
composed_layout_t<TDynTraits>::shape_a() const { return layout_a().shape(); }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::shape_t&
composed_layout_t<TDynTraits>::shape_a() { return layout_a().shape(); }

template <class TDynTraits>
const typename composed_layout_t<TDynTraits>::stride_t&
composed_layout_t<TDynTraits>::stride_a() const { return layout_a().stride(); }

template <class TDynTraits>
typename composed_layout_t<TDynTraits>::stride_t&
composed_layout_t<TDynTraits>::stride_a() { return layout_a().stride(); }

template <class TDynTraits>
bool composed_layout_t<TDynTraits>::is_a_affine() const { return std::holds_alternative<layout_t>(A); }

template <class TDynTraits>
bool composed_layout_t<TDynTraits>::is_a_swizzle() const { return std::holds_alternative<swizzle>(A); }

template <class TDynTraits>
bool composed_layout_t<TDynTraits>::is_normal_layout() const
{
    // If true, (*this) is equivalent to layout_b()
    // Plan to use this to indicate when a sliced swizzled layout can decay to a static or
    // non-static normal layout
    return (offset() == 0) &&
           (std::holds_alternative<swizzle>(a())) &&
           (std::get<swizzle>(a()).num_bits() == 0);
}

template <class TDynTraits>
template <class TCoord>
auto composed_layout_t<TDynTraits>::operator()(const TCoord& coord) const
{
    const auto idx_b = B(coord);
    return std::visit([&idx_b = std::as_const(idx_b), this](auto&& v) //
                      {
                          return v(scalar_add<offset_t,
                                              remove_cvref_t<decltype(idx_b)>,
                                              offset_t>(idx_b, off));
                      },
                      a());
}

template <class TDynTraits>
template <class OtherLayout>
composed_layout_t<TDynTraits> composed_layout_t<TDynTraits>::compose(const OtherLayout& other) const
{
    return composition(*this, other);
}

template <class TDynTraits>
template <class OtherShape>
composed_layout_t<TDynTraits> composed_layout_t<TDynTraits>::with_shape(const OtherShape& shape) const
{
    return composition(*this, layout_t{shape});
}

template <class TDynTraits>
auto composed_layout_t<TDynTraits>::rank() const { return layout_b().rank(); }

//
// Utilities
//

template <class TDynTraits>
std::ostream& operator<<(std::ostream& os, const composed_layout_t<TDynTraits>& ly)
{
    os << to_string(ly);
    return os;
}

//
// Core API
//

template <class TDynTraits>
bool has_error(const composed_layout_t<TDynTraits>& l)
{
    return has_error(l.layout_b()) ||
           has_error(l.offset()) ||
           (l.is_a_affine() ? has_error(l.layout_a()) : false);
}

template <class TDynTraits>
bool is_valid(const composed_layout_t<TDynTraits>& l)
{
    return is_valid(l.layout_b()) &&
           is_valid(l.offset()) &&
           (l.is_a_affine() ? is_valid(l.layout_a()) : true);
}

template <class TDynTraits>
size_t rank(const composed_layout_t<TDynTraits>& lay)
{
    return rank(lay.layout_b().shape());
}

template <class TDynTraits>
size_t rank(const composed_layout_t<TDynTraits>& lay, int mode)
{
    return rank(lay.layout_b().shape()[mode]);
}

template <class TDynTraits>
size_t depth(const composed_layout_t<TDynTraits>& lay)
{
    // Layout depth is that of its shape
    return depth(lay.layout_b());
}

template <class TDynTraits, class TRange>
bool check_get_indices(const composed_layout_t<TDynTraits>& l, const TRange& r)
{
    return check_get_indices(l.shape(), r);
}

template <class TDynTraits>
auto get(const composed_layout_t<TDynTraits>& l, size_t mode)
{
    return composed_layout_t(l.a(), l.offset(), get(l.layout_b(), mode));
}

template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto get(const composed_layout_t<TDynTraits>& cly, const TRange& modes)
{
    return composed_layout_t(cly.a(), cly.offset(), get(cly.layout_b(), modes));
}

template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool>>
auto get(const composed_layout_t<TDynTraits>& cly, TInt... idx)
{
    return composed_layout_t(cly.a(), cly.offset(), get(cly.layout_b(), idx...));
}

template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto select(const composed_layout_t<TDynTraits>& cly, const TRange& modes)
{
    return composed_layout_t(cly.a(), cly.offset(), select(cly.layout_b(), modes));
}

template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool>>
auto select(const composed_layout_t<TDynTraits>& cly, TInt... idx)
{
    return composed_layout_t(cly.a(), cly.offset(), select(cly.layout_b(), idx...));
}

template <class TDynTraits>
bool is_congruent(const composed_layout_t<TDynTraits>& layoutA,
                  const composed_layout_t<TDynTraits>& layoutB)
{
    // Assume strides are congruent
    return is_congruent(layoutA.shape(), layoutB.shape());
}

template <class... Ts, class TDynTraits>
bool weakly_congruent(const rec_var_base<Ts...>& lhs, const composed_layout_t<TDynTraits>& rhs)
{
    return weakly_congruent(lhs, rhs.shape());
}

template <class TDynTraits>
auto flatten(const composed_layout_t<TDynTraits>& l)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), flatten(l.layout_b()));
}

template <class TCoord, class TDynTraits>
auto slice(const TCoord& crd, const composed_layout_t<TDynTraits>& lay)
{
    return std::get<0>(slice_and_offset(crd, lay));
}

template <class TCoord, class TDynTraits>
auto dice(const TCoord& crd, const composed_layout_t<TDynTraits>& lay)
{
    using clay_t = composed_layout_t<TDynTraits>;
    return clay_t(lay.a(), lay.offset(), dice(crd, lay.layout_b()));
}

template <class TCoord, class TDynTraits>
auto slice_and_offset(const TCoord& crd, const composed_layout_t<TDynTraits>& lay)
{
    using CLayout = composed_layout_t<TDynTraits>;

    if(lay.is_normal_layout())
    {
        auto [slice_res, offset_res] = slice_and_offset(crd, lay.layout_b());
        return std::make_tuple(CLayout(slice_res), offset_res);
    }

    return std::visit([&](auto&& v) //
                      {
                          return detail::slice_and_offset(crd, v, lay.offset(), lay.layout_b());
                      },
                      lay.a());
}

template <class TCoord, class TDynTraits>
auto domain_offset(const TCoord& c, const composed_layout_t<TDynTraits>& l)
{
    // We have this specialization due to the TypeInferTensor and LoweringTensor
    // uses composed_layout as the general backend layout implementation.
    if(l.is_normal_layout())
    {
        return std::make_tuple(l, l.layout_b()(c));
    }

    // For composed layout, accumulate the offset in the composed layout itself.
    // This follows the same logic as the cutlass C++ implementation.
    using comp_lay_t = composed_layout_t<TDynTraits>;
    using off_t      = typename comp_lay_t::offset_t;

    auto       new_offset = arith_tuple_sum<off_t>(l.offset(), l.layout_b()(c));
    comp_lay_t new_layout(l.a(), new_offset, l.layout_b());

    return std::make_tuple(new_layout, off_t(0));
}

template <class TDynTraits>
auto append_to_rank_N(size_t N, const composed_layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e)
{
    using clay_t = composed_layout_t<TDynTraits>;
    using lay_t  = typename clay_t::layout_t;
    lay_t new_b  = append_to_rank_N(N, l.layout_b(), e);
    return clay_t(l.a(), l.offset(), std::move(new_b));
}

template <class TDynTraits>
auto prepend_to_rank_N(size_t N, const composed_layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e)
{
    using clay_t = composed_layout_t<TDynTraits>;
    using lay_t  = typename clay_t::layout_t;
    lay_t new_b  = prepend_to_rank_N(N, l.layout_b(), e);
    return clay_t(l.a(), l.offset(), std::move(new_b));
}

template <class TDynTraits>
auto group(int B, int E, const composed_layout_t<TDynTraits>& l)
{
    auto grouped_layout_b = group(B, E, l.layout_b());
    using TLayout         = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), grouped_layout_b);
}

template <class TDynTraits>
auto filter_zeros(const composed_layout_t<TDynTraits>& l)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), filter_zeros(l.layout_b()));
}

template <class TDynTraits, class TShape>
auto filter_zeros(const composed_layout_t<TDynTraits>& l, const TShape& target_profile)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), filter_zeros(l.layout_b(), target_profile));
}

template <class TDynTraits>
auto filter(const composed_layout_t<TDynTraits>& l)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), filter(l.layout_b()));
}

template <class TDynTraits>
composed_layout_t<TDynTraits> upcast(typename composed_layout_t<TDynTraits>::int_t N,
                                     const composed_layout_t<TDynTraits>&          layout)
{
    using offset_t = typename composed_layout_t<TDynTraits>::offset_t;

    // Don't support dynamic offset
    if(holds_int(layout.offset()) && (layout.offset().as_int() % N == 0))
    {
        if(layout.is_a_swizzle())
        {
            return composed_layout_t(upcast(N, layout.swizzle_a()),
                                     offset_t(layout.offset().as_int() / N),
                                     upcast(N, layout.layout_b()));
        }
        else
        {
            return composed_layout_t(upcast(N, layout.layout_a()),
                                     offset_t(layout.offset().as_int() / N),
                                     upcast(N, layout.layout_b()));
        }
    }
    return cg_error_t{};
}

template <class TDynTraits>
composed_layout_t<TDynTraits> downcast(typename composed_layout_t<TDynTraits>::int_t N,
                                       const composed_layout_t<TDynTraits>&          layout)
{
    using offset_t = typename composed_layout_t<TDynTraits>::offset_t;

    // Don't support dynamic offset
    if(holds_int(layout.offset()))
    {
        if(layout.is_a_swizzle())
        {
            return composed_layout_t(downcast(N, layout.swizzle_a()),
                                     offset_t(layout.offset().as_int() * N),
                                     downcast(N, layout.layout_b()));
        }
        else
        {
            return composed_layout_t(downcast(N, layout.layout_a()),
                                     offset_t(layout.offset().as_int() * N),
                                     downcast(N, layout.layout_b()));
        }
    }
    return cg_error_t{};
}

template <class TDynTraits>
inline typename composed_layout_t<TDynTraits>::layout_t::int_t
max_alignment(const composed_layout_t<TDynTraits>& layout)
{
    auto alignment = max_alignment(layout.layout_b());
    if(layout.is_normal_layout())
        return alignment;

    // Can't compute max_alignment for tuple in general
    if(layout.is_a_affine())
        return 1;

    if(holds_dynamic_int(layout.offset()) || holds_vector(layout.offset()))
        return 1;

    alignment = std::gcd(alignment, layout.offset().as_int());
    return std::gcd(alignment, max_alignment(layout.swizzle_a()));
}

template <class TDynTraits>
auto size(const composed_layout_t<TDynTraits>& l)
{
    return size(l.layout_b());
}

template <class TDynTraits>
auto static_size(const composed_layout_t<TDynTraits>& l)
{
    assert(is_static(l.layout_b()));
    auto res = size(l);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits>
auto cosize(const composed_layout_t<TDynTraits>& layout)
{
    // cosize of composed layout with affine should be considered as illegal
    if(layout.is_a_affine())
        return typename composed_layout_t<TDynTraits>::shape_t{cg_error_t{}};
    return cosize(layout.layout_b());
}

template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto cosize(const composed_layout_t<TDynTraits>& layout, const TRange& idx)
{
    // cosize of composed layout with affine should be considered as illegal
    if(layout.is_a_affine())
        return typename composed_layout_t<TDynTraits>::shape_t{cg_error_t{}};
    return cosize(layout.layout_b(), idx);
}

template <class TDynTraits>
auto static_cosize(const composed_layout_t<TDynTraits>& layout)
{
    auto res = cosize(layout);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits>
auto coalesce(const composed_layout_t<TDynTraits>& l)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), coalesce(l.layout_b()));
}

template <class TDynTraits, class TRecVar>
auto coalesce(const composed_layout_t<TDynTraits>& l, const TRecVar& trg_profile)
{
    using TLayout = composed_layout_t<TDynTraits>;
    return TLayout(l.a(), l.offset(), coalesce(l.layout_b(), trg_profile));
}

template <class TDynTraits>
auto right_inverse(const composed_layout_t<TDynTraits>& layout)
{
    using comp_lay_t = composed_layout_t<TDynTraits>;
    if(layout.is_normal_layout())
        return comp_lay_t(right_inverse(layout.layout_b()));
    // Right inverse of a genuine composed layout not supported
    return comp_lay_t(cg_error_t{});
}

template <class TDynTraits, class TRhs>
auto composition(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), composition(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto logical_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), logical_divide(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto zipped_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), zipped_divide(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto tiled_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), tiled_divide(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto flat_divide(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), flat_divide(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto logical_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), logical_product(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto zipped_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), zipped_product(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto tiled_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), tiled_product(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto flat_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), flat_product(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto blocked_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), blocked_product(lhs.layout_b(), rhs));
}

template <class TDynTraits, class TRhs>
auto raked_product(const composed_layout_t<TDynTraits>& lhs, const TRhs& rhs)
{
    return composed_layout_t(lhs.a(), lhs.offset(), raked_product(lhs.layout_b(), rhs));
}

template <class TDynTraits,
          class ModeOrder>
auto tile_to_shape(const composed_layout_t<TDynTraits>& l,
                   const cute_shape_t<TDynTraits>&      trg_shape,
                   const ModeOrder&                     ord)
{
    return composed_layout_t(l.a(), l.offset(), tile_to_shape(l.layout_b(), trg_shape, ord));
}

template <class TDynTraits>
layout_t<TDynTraits> make_layout_like(const composed_layout_t<TDynTraits>& layout)
{
    if(!layout.is_a_swizzle())
    {
        using lay_t = layout_t<TDynTraits>;
        return lay_t(cg_error_t{});
    }
    return make_layout_like(layout.layout_b());
}

} // namespace cutegen

#endif // CUTEGEN_COMPOSED_LAYOUT_HPP_INCLUDED_
