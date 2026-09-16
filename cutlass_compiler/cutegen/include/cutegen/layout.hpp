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

#if !defined(CUTEGEN_LAYOUT_HPP_INCLUDED_)
#define CUTEGEN_LAYOUT_HPP_INCLUDED_

#include <algorithm>
#include <assert.h>
#include <functional>
#include <iosfwd>
#include <iterator>
#include <limits>
#include <numeric>
#include <optional>
#include <stdint.h>
#include <stdlib.h>
#include <string>
#include <system_error>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/charconv.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"

namespace cutegen
{
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// layout.hpp - Public API
//
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class TDynTraits>
struct cute_shape_t : public rec_var_base<cute_shape_t<TDynTraits>,
                                          static_int_t,
                                          typename TDynTraits::dynamic_int_t,
                                          cg_error_t>
{
    // dyn_traits_t currently needed by idx2crd_impl()
    using dyn_traits_t = TDynTraits;
    using base_rv_t    = rec_var_base<cute_shape_t<TDynTraits>,
                                   static_int_t,
                                   typename TDynTraits::dynamic_int_t,
                                   cg_error_t>;
    using base_rv_t::base_rv_t;
};

template <class TDynTraits>
struct cute_stride_t : public rec_var_base<cute_stride_t<TDynTraits>,
                                           static_int_t,
                                           typename TDynTraits::dynamic_int_t,
                                           scaled_basis_t<ratio,
                                                          static_int_t,
                                                          typename TDynTraits::dynamic_int_t>,
                                           cg_error_t>
{
    using base_rv_t = rec_var_base<cute_stride_t<TDynTraits>,
                                   static_int_t,
                                   typename TDynTraits::dynamic_int_t,
                                   scaled_basis_t<ratio,
                                                  static_int_t,
                                                  typename TDynTraits::dynamic_int_t>,
                                   cg_error_t>;
    using base_rv_t::base_rv_t;
};

template <class TDynTraits>
struct cute_int_tuple_t : public rec_var_base<cute_int_tuple_t<TDynTraits>,
                                              static_int_t,
                                              typename TDynTraits::dynamic_int_t,
                                              cg_error_t>
{
    using base_rv_t = rec_var_base<cute_int_tuple_t<TDynTraits>,
                                   static_int_t,
                                   typename TDynTraits::dynamic_int_t,
                                   cg_error_t>;
    using base_rv_t::base_rv_t;
};

template <class TDynTraits>
struct cute_coord_t : public rec_var_base<cute_coord_t<TDynTraits>,
                                          static_int_t,
                                          underscore_t,
                                          typename TDynTraits::dynamic_int_t,
                                          cg_error_t>
{
    using base_rv_t = rec_var_base<cute_coord_t<TDynTraits>,
                                   static_int_t,
                                   underscore_t,
                                   typename TDynTraits::dynamic_int_t,
                                   cg_error_t>;
    using base_rv_t::base_rv_t;
};

template <class TDynTraits>
struct is_rec_var<cute_shape_t<TDynTraits>> : std::true_type
{};

template <class TDynTraits>
struct is_rec_var<cute_stride_t<TDynTraits>> : std::true_type
{};

template <class TDynTraits>
struct is_rec_var<cute_int_tuple_t<TDynTraits>> : std::true_type
{};

template <class TDynTraits>
struct is_rec_var<cute_coord_t<TDynTraits>> : std::true_type
{};

/**
 * @brief Generates a compact column-major stride starting from a scalar stride.
 *
 * @p current defaults to the integer 1.
 *
 * @pre @p current is either an integer or a dynamic value
 */
template <class TShape, class TStride>
TStride compact_col_major(const TShape& shape, TStride current = 1);

/**
 * @brief Generates a compact row-major stride starting from a scalar stride.
 *
 * @p current defaults to the integer 1.
 *
 * @pre @p current is either an integer or a dynamic value
 */
template <class TShape, class TStride>
TStride compact_row_major(const TShape& shape, TStride current = 1);

/**
 * @brief Generates a compact stride following the order given by the elements of @p order.
 *
 * @pre All elements of @p order are integers.
 */
template <class TStride, class TShape, class TOrder>
TStride compact_order(const TShape& shape, const TOrder& order);

struct gen_col_major
{};

struct gen_row_major
{};

/**
 * @brief Splits an index to a coordinate within `<Shape,Stride>`.
 *
 * It transforms a scalar index into the natural coordinate such that:
 *
 * ```
 * shape:stride(idx2crd(index)) = index
 * ```
 *
 * It also wraps @p idx into a recursive variant if needed.
 *
 * Notes:
 *
 * - this only works for compact shape+stride layouts; a more general version would apply to all
 *   surjective layouts
 * - this function can handle the following cases
 *     - `[scalar,tuple,tuple]`
 *     - `[scalar,tuple,scalar]`
 *     - `[scalar,scalar,scalar]`
 * - CuTe-C++ can handle the case `[tuple,tuple,tuple]`
 *
 * @see idx2crd_impl()
 */
template <class TIndex, class TDynTraits>
cute_coord_t<TDynTraits> idx2crd(const TIndex&                    idx,
                                 const cute_shape_t<TDynTraits>&  shape,
                                 const cute_stride_t<TDynTraits>& stride);

/**
 * @brief Converts a linear index to a coordinate within a shape using compact column-major stride.
 *
 * This overload only requires the shape parameter and automatically generates
 * a compact column-major stride for the conversion. This is equivalent to:
 * ```
 * idx2crd(idx, shape, make_basis_like<stride_t>(shape))
 * ```
 *
 * @param idx The linear index to convert
 * @param shape The shape to convert the index into
 * @return The coordinate corresponding to the given index
 */
template <class TIndex, class TDynTraits>
cute_coord_t<TDynTraits> idx2crd(const TIndex&                   idx,
                                 const cute_shape_t<TDynTraits>& shape);

template <class TCoord, class TDynTraits>
cute_int_tuple_t<TDynTraits> layout_eval(const TCoord&                    coord,
                                         const cute_shape_t<TDynTraits>&  shape,
                                         const cute_stride_t<TDynTraits>& stride);

/**
 * @brief Pack a coordinate into a linear index using implicit
 *        column-major strides derived from @p shape.
 *
 * For shape `(s_0, s_1, ..., s_{n-1})` and coord
 * `(c_0, c_1, ..., c_{n-1})` the result is
 * `c_0 + c_1*s_0 + c_2*s_0*s_1 + ... + c_{n-1}*s_0*...*s_{n-2}`.
 *
 * Nested coords / shapes recurse mode-by-mode. The result is always
 * a scalar int_tuple.
 */
template <class TCoord, class TDynTraits>
cute_int_tuple_t<TDynTraits> crd2idx(const TCoord&                   coord,
                                     const cute_shape_t<TDynTraits>& shape);

struct prefix_product_tag
{
};

//
// Layout
//

template <class TDynTraits>
class layout_t
{
public:
    using shape_t      = cute_shape_t<TDynTraits>;
    using stride_t     = cute_stride_t<TDynTraits>;
    using int_t        = typename shape_t::int_t;
    using dyn_traits_t = TDynTraits;
    using dyn_t        = typename TDynTraits::dynamic_int_t;

    layout_t() = default;
    layout_t(shape_t sh, stride_t str);
    layout_t(shape_t sh, stride_t str, prefix_product_tag);
    layout_t(shape_t s);
    layout_t(shape_t s, gen_col_major);
    layout_t(shape_t s, gen_row_major);
    template <typename TInt, std::enable_if_t<std::is_integral<TInt>::value, bool> = true>
    layout_t(TInt s);
    layout_t(cg_error_t);
    template <class... TLayout>
    layout_t(layout_t l0, layout_t l1, TLayout... ln);

    bool operator==(const layout_t<TDynTraits>& other) const;
    bool operator!=(const layout_t<TDynTraits>& other) const;

    const shape_t&  shape() const;
    const stride_t& stride() const;
    shape_t&        shape();
    stride_t&       stride();
    auto            rank() const;
    void            append(const layout_t& other);

    /**
     * @brief Maps a logical coordinate to an index.
     *
     * `T` can be either an integral type or a recursive variant type.
     * For layouts with all-integer strides, the result is an int_tuple that
     * holds an integer value. For layouts with one or more scaled basis
     * strides, the result is an integer tuple with a profile that matches
     * the distinct basis vectors.
     */
    template <class TCoord>
    auto operator()(const TCoord& coord) const;
    //
    // Compose
    //

    template <class OtherLayout>
    layout_t
    compose(const OtherLayout& other) const;
    template <class OtherShape>
    layout_t with_shape(const OtherShape& shape) const;

    std::string to_string() const;

private:
    void validate();

private:
    shape_t  shape_;
    stride_t stride_;
};

//
// Type manipulation
//

template <class T>
struct is_layout : std::false_type
{};

template <class TDynTraits>
struct is_layout<layout_t<TDynTraits>> : std::true_type
{};

template <class TRecVar>
using find_layout_in_rec_var = detail::find_in_tuple<typename TRecVar::elem_types_t, is_layout>;

// Specialization of type_can_hold_dynamic_int<> for layouts
template <class TDynTraits>
struct type_can_hold_dynamic_int<layout_t<TDynTraits>>
{
    static constexpr bool value = true;
};

//
// Tile
//

/**
 * @brief Type trait to check whether a type is a tile.
 *
 * From CuTe-C++: "A Tile is not a Layout, it's a tuple of Layouts or Tiles or Underscores". Note
 * that CuTe-C++'s implementation makes `is_tile` equivalent to `is_tuple`. In cutegen, any
 * recursive variant that can hold any concrete layout_t is considered to be a tile. This is a
 * criterion weaker than the definition from CuTe algebra.
 */
template <class TRecVar>
struct is_tile<TRecVar, std::enable_if_t<is_rec_var_with_type_pred<TRecVar, is_layout>::value>>
    : std::true_type
{};

template <class TDynTraits>
struct cute_tile_t : public rec_var_base<cute_tile_t<TDynTraits>, layout_t<TDynTraits>, underscore_t>
{
    using base_rv_t = rec_var_base<cute_tile_t<TDynTraits>, layout_t<TDynTraits>, underscore_t>;
    using base_rv_t::base_rv_t;
    using layout_int_t = typename layout_t<TDynTraits>::int_t;
};

template <class TDynTraits>
struct is_rec_var<cute_tile_t<TDynTraits>> : std::true_type
{};

//
// Utilities
//

// Type trait to check if a type is tuple-like (shape, stride, coord, or
// int_tuple)
template <typename T>
struct is_tuple_like : std::false_type
{};

// Remove cv-qualifiers and references for the check
template <typename T>
struct is_tuple_like<const T> : is_tuple_like<T>
{};

template <typename T>
struct is_tuple_like<T&> : is_tuple_like<T>
{};

template <typename T>
struct is_tuple_like<T&&> : is_tuple_like<T>
{};

template <typename TDynamic>
struct is_tuple_like<cute_shape_t<TDynamic>> : std::true_type
{};

template <typename TDynamic>
struct is_tuple_like<cute_stride_t<TDynamic>> : std::true_type
{};

template <typename TDynamic>
struct is_tuple_like<cute_coord_t<TDynamic>> : std::true_type
{};

template <typename TDynamic>
struct is_tuple_like<cute_int_tuple_t<TDynamic>> : std::true_type
{};

template <typename TDynamic>
struct is_tuple_like<cute_tile_t<TDynamic>> : std::true_type
{};

template <typename T>
inline constexpr bool is_tuple_like_v = is_tuple_like<T>::value;

/**
 * @brief Checks whether a layout is valid.
 *
 * In CuTe algebra, any 0 modes in shape is considered as illegal because no valid input
 * coordinates. Negative modes in shape is not formalized.
 *
 * CuTe algebra should guarantee to not produce illegal modes (<= 0) in shape. The overhead
 * of check on creation of cutegen::layout is not necessary cost for user to pay everywhere.
 *
 * The expectation is users should call this API to verify layout.
 */
template <class TDynTraits>
bool is_valid(const layout_t<TDynTraits>& l);

template <class TCoord, class TDynTraits>
auto layout_eval(const TCoord& coord, const layout_t<TDynTraits>& l);

// layout stream insertion
template <class TDynTraits>
std::ostream& operator<<(std::ostream& os, const layout_t<TDynTraits>& ly);

/// Makes a layout out of a string if possible.
template <class TLayout,
          class TString,
          std::enable_if_t<std::is_base_of_v<layout_t<typename TLayout::dyn_traits_t>,
                                             TLayout>,
                           bool> = true>
std::optional<TLayout> make_layout(const TString& str);

/// Makes a tile out of a string if possible.
template <class TTile,
          class TString,
          std::enable_if_t<is_tile<TTile>::value, bool> = true>
std::optional<TTile> make_tile(const TString& str);

//
// Functions forwarding to recursive variants implementations
//

/// Checks if a layout has an error.
template <class TDynTraits>
bool has_error(const layout_t<TDynTraits>& l);

template <class TDynTraits, class TRange>
bool check_get_indices(const layout_t<TDynTraits>& l, const TRange& r);

/**
 * @brief Gets a direct sub-layout from layout `ly`.
 *
 * This function is typically used to get TLayout/VLayout from TVLayout.
 *
 * Example:
 * ```
 * l         : "((2,4),(3,7)):((1,2),(8,32))"
 * get(l, 0) : "(2,4):(1,2)"
 * get(l, 1) : "(3,7):(8,32)"
 * ```
 */
template <class TDynTraits>
auto get(const layout_t<TDynTraits>& ly, size_t mode);

/**
 * @brief Gets a potentially nested sub-layout from layout `ly`.
 *
 * Example:
 * ```
 * l                                   : "((2,4,6),(8,10)) : ((1,2,8),(48,384))"
 * get(l, std::array<size_t, 2>{0, 2}) : "6:8"
 * ```
 */
template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto get(const layout_t<TDynTraits>& ly, const TRange& range);

/// Gets a potentially nested sub-layout from layout `ly`.
template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
auto get(const layout_t<TDynTraits>& ly, TInt... idx);

/**
 * @brief Selects specific dimensions from `ly`.
 *
 * Example:
 * ```
 * l         : "((2,4),(3,7)):((1,2),(8,32))"
 * select(l, std::array<size_t, 2>{0,1}) : "((2,4),(3,7)):((1,2),(8,32))"
 * ```
 */
template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto select(const layout_t<TDynTraits>& ly, const TRange& range);

/// Selects specific dimensions from `ly`
template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool> = true>
auto select(const layout_t<TDynTraits>& ly, TInt... idx);

/**
 * @brief Checks whether two layouts are compatible.
 *
 * I believe two layouts are compatible if the respective shapes are,
 * see the implementation in int_tuple.hpp in CUTLASS-C++.
 */
template <class TDynTraits>
bool compatible(const layout_t<TDynTraits>& layoutA, const layout_t<TDynTraits>& layoutB);

/**
 * @brief Checks whether two layouts have the same profile
 *
 * @return false
 */
template <class TDynTraits>
bool is_congruent(const layout_t<TDynTraits>& layoutA, const layout_t<TDynTraits>& layoutB);

template <class... Ts, class TDynTraits>
bool weakly_congruent(const rec_var_base<Ts...>& lhs, const layout_t<TDynTraits>& rhs);

template <class TDynTraits>
size_t rank(const layout_t<TDynTraits>& l0);

template <class TDynTraits>
size_t rank(const layout_t<TDynTraits>& l0, int mode);

template <class TDynTraits>
size_t depth(const layout_t<TDynTraits>& l0);

/// Converts a shape-like type to a tile-like type.
template <class TDynTraits>
cute_tile_t<TDynTraits> shape_to_tile(const cute_shape_t<TDynTraits>& shape);

/// Converts a tile-like type to a shape-like type.
template <class TDynTraits>
cute_shape_t<TDynTraits> extract_shape_from_tile(const cute_tile_t<TDynTraits>& tile);

template <class TDynTraits>
auto is_static_with_integral_stride_elements(const layout_t<TDynTraits>& l);

/**
 * @brief Returns the size of a layout.
 *
 * The size of a layout is the size of its shape. In order to support dynamic elements, the return
 * type is the shape type (the stride type can hold unneeded types).
 */
template <class TDynTraits>
auto size(const layout_t<TDynTraits>& l);

template <class TDynTraits>
auto size(const layout_t<TDynTraits>& l, size_t idx);

/**
 * @brief Returns the size of a layout that is statically known.
 *
 * @see static_size(const rec_var<TRecVarElemTypes...>&)
 * @pre is_static(l.shape())
 */
template <class TDynTraits>
auto static_size(const layout_t<TDynTraits>& l);

template <class TDynTraits>
auto static_size(const layout_t<TDynTraits>& l, size_t idx);

/// Specialized size for tiles.
template <class TDynTraits>
auto size(const cute_tile_t<TDynTraits>& tile);

/// Specialized static_size for tiles.
template <class TDynTraits>
auto static_size(const cute_tile_t<TDynTraits>& tile);

/// append_to_rank_N overload for layouts.
template <class TDynTraits>
auto append_to_rank_N(size_t N, const layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e);

/// prepend_to_rank_N overload for layouts.
template <class TDynTraits>
auto prepend_to_rank_N(size_t N, const layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e);

/// prepend_to_rank_N overload for layouts.
template <class TDynTraits>
auto prepend_to_rank_N(size_t N, const layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e);

template <class TDynTraits>
auto group(int B, int E, const layout_t<TDynTraits>& l);

/// take overload for layouts.
template <class TDynTraits>
auto take(int B, int E, const layout_t<TDynTraits>& l);

template <class TDynTraits>
std::optional<bool> eq_op_can_fold(const layout_t<TDynTraits>& lhs, const layout_t<TDynTraits>& rhs);

//
// Layout specific
//

/**
 * @brief Returns the coprofile of a layout
 *
 * Return the coprofile of a layout as a tuple of zeros. The coprofile
 * is an int_tuple that is congruent with layout(i) for all integers i.
 */
template <class TDynTraits>
auto coprofile(const layout_t<TDynTraits>& l);

/**
 * @brief Returns the cosize of a layout.
 *
 * For a layout `l` with all-integer strides, `cosize(l) = l(size(l)-1)+1`.
 * For a layout with scaled basis stride elements,
 * - `l(size(l)-1)+1` is a (possibly hierarchical) coordinate `c = (c_0,...,c_{R-1})`
 * - the cosize is the product of `c + repeat_like(c, 1)`
 */
template <class TDynTraits>
auto cosize(const layout_t<TDynTraits>& l);

/**
 * @brief Returns the cosize of a layout in the hierarchical structure.
 * example:
 * ```
 * l                : "((2,4),(3,7)):((1,2),(8,32))"
 * cosize(l, 0)     : cosize("(2,4):(1,2)")
 * cosize(l, 0, 1)  : cosize("(4):(2)")
 * ```
 */
template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto cosize(const layout_t<TDynTraits>& l0, const TRange& idx);

/// Returns the cosize of a static layout.
template <class TDynTraits>
auto static_cosize(const layout_t<TDynTraits>& l0);

/// Returns the cosize of a static layout in the hierarchical structure.
template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool> = true>
auto static_cosize(const layout_t<TDynTraits>& l0, const TRange& idx);

/// Returns the shape of the co-domain of a layout.
template <class TDynTraits>
auto coshape(const layout_t<TDynTraits>& l);

/**
 * @brief Simplify a layout by combining modes where possible, such that the
 *        resulting layout is valid for all integers in the domain
 *
 * @post size(@a result) == size(@a layout)
 * @post depth(@a result) <= 1
 * @post for all i, 0 <= i < size(@a layout), @a layout(i) == @a result(i)
 */
template <class TDynTraits>
layout_t<TDynTraits> coalesce(const layout_t<TDynTraits>& l);

/**
 * @brief Simplify a shape by combining adjacent static and dynamic
          modes.
 */
template <class TDynTraits>
cute_shape_t<TDynTraits> coalesce(const cute_shape_t<TDynTraits>& sh);

/**
 * @brief Simplify a layout by combining modes where possible, such that the
 *        resulting layout is valid for all integers (not just those in the
 *        domain).
 *
 * "Simplify" the layout by combining all modes that are possible to combine
 * such that the layout as a function on all integers is unchanged.
 * This function does not respect the shape of the layout, but does preserve
 * total size.

 * @post size(@a result) == size(@a layout)
 * @post depth(@a result) <= 1
 * @post for all i >= 0, @a layout(i) == @a result(i)
 *
 */
template <class TDynTraits>
layout_t<TDynTraits> coalesce_z(const layout_t<TDynTraits>& l);

template <class TDynTraits, class TRecVar>
layout_t<TDynTraits> coalesce_z(const layout_t<TDynTraits>& layout, const TRecVar& trg_profile);

/**
 * @brief Coalesce a layout up to shape modes of extent x.
 *
 * This is a special version used in the logic of TMA descriptor creation. It walks the layout from
 * left to right which is opposite from the regular coalesce.
 */
template <class TDynTraits>
layout_t<TDynTraits> coalesce_up_with(const layout_t<TDynTraits>& l, uint32_t x);

/**
 * @brief Apply coalesce at the terminals of trg_profile
 *
 * see more details in TEST CoalesceTest.WithProfile
 *
 *   1                1
 *   -  +  1    ==>   -
 *   0                0
 *
 *   1                (1)
 *   -  + (1,)  ==>   ---
 *   0                (0)
 *
 *   ((2,2), (2, 2))                  (4, 4)
 *   ----------------  +  (1,2)  ==>  ------
 *   ((1,2), (16,32))                 (1,16)
 *
 * @tparam TShape   Shape type of layout
 * @tparam TStride  Stride type of layout
 * @tparam TRecVar  Int Tuple type of profile
 * @param l         input layout to coalesce
 * @param t         tuple as profile
 * @return layout_t<TDynTraits>
 */
template <class TDynTraits, class TRecVar>
layout_t<TDynTraits>
coalesce(const layout_t<TDynTraits>& layout, const TRecVar& trg_profile);

// Replace the modes in the shape of a layout that have a static 0-stride with a 1-size
template <class TDynTraits>
auto filter_zeros(const layout_t<TDynTraits>& l);

template <class TDynTraits, class TShape>
auto filter_zeros(const layout_t<TDynTraits>& l, const TShape& target_profile);

// Replace mode shapes that have a 0-stride with 1, flatten, and then coalesce
// adjacent modes that can be accessed as a single mode.
template <class TDynTraits>
auto filter(const layout_t<TDynTraits>& l);

template <class TDynTraits>
auto flatten(const layout_t<TDynTraits>& l);

template <class TDynTraits>
auto make_identity_layout(const cute_shape_t<TDynTraits>& shape);

// Compute a pointer offset and (potentially modified) layout from a coordinate
// This exists so it can be overloaded for ComposedLayout
template <class TCoord, class TDynTraits>
auto domain_offset(const TCoord& c, const layout_t<TDynTraits>& l);

template <class TCoord, class TDynTraits>
auto slice(const TCoord& crd, const layout_t<TDynTraits>& layout);

template <class TCoord, class TDynTraits>
auto dice(const TCoord& crd, const layout_t<TDynTraits>& layout);

template <class TCoord, class TLayout>
auto slice_and_offset(const TCoord& crd, const TLayout& layout);

//
// Concatenation
//

template <class TLayout>
auto make_layout(const std::vector<TLayout>& lys);

// Make a compact layout with the same shape as @a layout
//   and strides following the order induced by @a layout.stride().
// Static-0 strides in the input @a layout are preserved in the output.
// Example:
//   cg::make_layout_like(Layout<Shape<_2,_2,_2,_2>, Stride<_0,_2,_4,_1>>{})
//     ->  (_2,_2,_2,_2):(_0,_2,_4,_1)
//   cg::make_layout_like(make_layout(make_shape(2,3,4,5),
//   make_stride(Int<0>{},42,Int<1>{},Int<0>{})))
//     -> (2,3,4,5):(_0,4,_1,_0)
template <class TDynTraits>
layout_t<TDynTraits> make_layout_like(const layout_t<TDynTraits>& layout);

//
// Complement
//

template <class TDynTraits, class CoSizeHi>
layout_t<TDynTraits> complement(const layout_t<TDynTraits>& l, CoSizeHi cosize_hi);

template <class TDynTraits>
layout_t<TDynTraits> complement(const layout_t<TDynTraits>& l);

template <class TDynTraits, class TExtend>
layout_t<TDynTraits> complement_extend(const layout_t<TDynTraits>& l, TExtend extend);

//
// Composition
//

// layout / layout
template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const layout_t<TDynTraits>& rhs);

// layout / shape with shape interpreted as a tiler
template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const cute_shape_t<TDynTraits>& rhs);

// layout / tile
template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const cute_tile_t<TDynTraits>& rhs);

//
// Inverses
//

/**
 * @brief Builds the right inverse of a layout.
 *
 * Denoting `l^{-R}` the right inverse, we have the following properties:
 *
 * - `l o l^{-R} (i) = i` for all `i` in the domain of `l^{-R}`
 * - `l o l^{-R} = make_layout(shape(l^{-R}))`
 *
 * Note: these are not sufficient conditions for the uniqueness of the result. A bug was found
 * with this function returning `1:0` for layouts with modes of shape extent greater than 1 and 0
 * stride extent. `1:0` trivially satisfies the above conditions.
 *
 * @pre `layout` is static (cf. CuTe-C++)
 */
template <class TDynTraits>
layout_t<TDynTraits> right_inverse(const layout_t<TDynTraits>& layout);

template <class TDynTraits>
layout_t<TDynTraits> left_inverse(const layout_t<TDynTraits>& layout);

//
// Products and divides
//

// logical_divide() layout / layout
// Split a layout by the composition of B and the "rest"
template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b);

// logical_divide() layout / tile
template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>& a, const cute_tile_t<TDynTraits>& b);

// logical_divide() layout / shape with shape interpreted as a tiler
template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>& target, const cute_shape_t<TDynTraits>& tiler);

/**
 * @brief Performs a generalized ceil division for layout/layout.
 *
 * This is equivalent to taking the shape of mode 1 of a zipped divide.
 */
template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const layout_t<TDynTraits>& target,
                                  const layout_t<TDynTraits>& tiler);

/// Performs a generalized ceil division for shape/layout.
template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const cute_shape_t<TDynTraits>& target,
                                  const layout_t<TDynTraits>&     tiler);

/// Performs a generalized ceil division for shape/tile.
template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const cute_shape_t<TDynTraits>& target,
                                  const cute_tile_t<TDynTraits>&  tiler);

// zipped_divide(layout, layout) => a simple logical_divide
// See tile_unzip and zip2_by in CUTLASS-C++
template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const layout_t<TDynTraits>& tiler);

// zipped_divide(layout, tile)
template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const cute_tile_t<TDynTraits>& tiler);

// zipped_divide(layout, shape) with shape interpreted as a tiler
template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const cute_shape_t<TDynTraits>& tiler);

template <class TDynTraits, class TTiler>
layout_t<TDynTraits> tiled_divide(const layout_t<TDynTraits>& target, const TTiler& tiler);

template <class TDynTraits, class TTiler>
layout_t<TDynTraits> flat_divide(const layout_t<TDynTraits>& target, const TTiler& tiler);

// logical_product()
// reproduce a layout A over a layout B
// do not support this operation by-mode and no-op
template <class TDynTraits>
auto logical_product(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b);

// zipped_product() layout / layout
template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const layout_t<TDynTraits>& tiler);

// zipped_product() layout / tile
template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const cute_tile_t<TDynTraits>& tiler);

// zipped_product() layout / shape
template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const cute_shape_t<TDynTraits>& tiler);

template <class TDynTraits, class TTiler>
auto tiled_product(const layout_t<TDynTraits>& block, const TTiler& tiler);

template <class TDynTraits, class TTiler>
auto flat_product(const layout_t<TDynTraits>& block, const TTiler& tiler);

template <class TDynTraits>
auto blocked_product(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b);

template <class TDynTraits>
auto raked_product(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b);

//
// Others
//

template <class TDynTraits>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   gen_col_major = {});

template <class TDynTraits>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   gen_row_major);

template <class TDynTraits, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   const TRecVar&                  order);

/**
 * @brief For stride-1 mode, divide size by N. Divide all other strides by N.
 *
 * @tparam TLayout  template parameter of input layout type
 * @param N         divisor
 * @param layout    Input layout
 * @return auto     Output layout
 */
template <class TDynTraits>
layout_t<TDynTraits> upcast(typename layout_t<TDynTraits>::int_t N, const layout_t<TDynTraits>& layout);

/**
 * @brief For stride-1 mode, multiply size by N. Multiply all other strides by N.
 *
 * @tparam TDynTraits  template parameter of input layout type
 * @param N         multiplier
 * @param layout    Input layout
 * @return auto     Output layout
 */
template <class TDynTraits>
layout_t<TDynTraits> downcast(typename layout_t<TDynTraits>::int_t N, const layout_t<TDynTraits>& layout);

template <class TLayout>
TLayout recast(int new_type_bits, int old_type_bits, const TLayout& layout);

template <class OldType, class NewType, class TLayout>
TLayout recast(const TLayout& layout);

/**
 * @brief Determine the maximum alignment of a Layout.
 *
 *  The maximum alignment is the largest N for which upcast<N>(layout) will compile.
 *    upcast<N>(layout) compiles when the static shapes and strides pass divisibility checks.
 *    Therefore, upcast<M>(layout) will also compile for all divisors M of N.
 *  Note that this only considers the static shapes and strides of the Layout
 *    in symmetry with upcast<N> only checking against static shapes and strides and assuming all
 *    dynamic shapes and strides are large and multiples of N.
 *
 * @tparam TDynTraits
 * @param layout
 * @return int
 */
template <class TDynTraits>
inline typename layout_t<TDynTraits>::int_t max_alignment(const layout_t<TDynTraits>& layout);

// Builds a stride congruent to the shape of the given layout
template <class TStride,
          class TDynTraits>
auto make_basis_like(const layout_t<TDynTraits>& ly);

/**
 * Transform a "tiler" (an HTuple of Layout|Integer) to a Layout
 * that acts identically under composition.
 *
 * tiler_to_layout(3) = 3:1
 * tiler_to_layout((7,2):(3,1)) = (7,2):(3,1)
 * tiler_to_layout((4,5)) = (4,5):(1@0, 1@1)
 * tiler_to_layout([4:2;5:3]) = (4,5):(2@0, 3@1)
 */
template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const cute_shape_t<TDynTraits>&  sh,
                                     const cute_stride_t<TDynTraits>& e = cute_stride_t<TDynTraits>(1));

template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const layout_t<TDynTraits>&      ly,
                                     const cute_stride_t<TDynTraits>& e = cute_stride_t<TDynTraits>(1));

template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const cute_tile_t<TDynTraits>&   t,
                                     const cute_stride_t<TDynTraits>& e = cute_stride_t<TDynTraits>(1));

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// layout.hpp - Implementation and internals
//
////////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail
{
template <class TShape, class TStride>
TStride compact_col_major_scalar(const TShape& shape,
                                 TStride       current)
{
    // Handle static shape mode of extent 1
    if(shape == 1) return 0;
    if(holds_leaf(shape))
    {
        if(!holds_int_or_dynamic_int(current))
            return cg_error_t{};
        return current;
    }
    TStride rv;
    for(const auto& v : get_vector(shape))
    {
        rv.append(detail::compact_col_major_scalar(v, current));
        current = scalar_mul<TStride>(current, product(v));
    }
    return rv;
}

template <class TShape, class TStride>
TStride compact_row_major_scalar(const TShape& shape,
                                 TStride       current)
{
    if(holds_leaf(shape))
    {
        if(!holds_int_or_dynamic_int(current))
            return cg_error_t{};
        return current;
    }
    using vector_t = typename TStride::vector_t;
    vector_t v_cm;
    for(auto r_it = std::crbegin(get_vector(shape));
        r_it != std::crend(get_vector(shape));
        ++r_it)
    {
        v_cm.insert(v_cm.begin(),
                    detail::compact_row_major_scalar(*r_it, current));
        current = scalar_mul<TStride>(current, product(*r_it));
    }
    return TStride(v_cm);
}

/**
 * @brief A custom transform for compact_order that doesn't require @p shape and @p order to be
 *        congruent.
 *
 * In the context of this function, @p current_order is an integer from the original `order` used
 * in `compact_order` and is fixed. We recursively walk the original `shape` and `order` until we hit
 * an integer in the original `order`. At that point, if that integer is less than @p current_order,
 * we return the product of the associated mode (not necessarily a scalar) in the original `shape`.
 * Otherwise we return 1. Overall, this function returns a recursive variant congruent to the
 * original `order` with either 1 or the product of the associated mode in the original `shape`
 * for a given order element. The product of that recursive variant becomes the starting scalar
 * for forming a compact column-major stride for the associated mode of the original `shape`.
 *
 * @pre @p current_order is an integer
 */
template <class TShape, class TOrder>
TShape transform_order(const TOrder& current_order, const TShape& shape, const TOrder& order)
{
    assert(is_integral_only(order));
    assert(holds_int(current_order));
    if(holds_int(order))
    {
        return cond_assign(
            detail::scalar_cmp<TOrder, TOrder, comp_pred::lt>(order, current_order),
            [=]() -> TShape { return product(shape); },
            [=]() -> TShape { return 1; });
    }
    assert(holds_vector(shape));
    assert(rank(shape) == rank(order));
    TShape res;
    for(size_t i = 0; i < rank(order); i++)
        res.append(transform_order(current_order, shape[i], order[i]));
    return res;
}

template <class TShape, class TStride, class TOrder>
TStride compact_order(const TShape& shape,
                      const TOrder& order,
                      const TShape& orig_shape,
                      const TOrder& orig_order)
{
    assert(is_integral_only(order));
    assert(is_integral_only(orig_order));
    if(holds_int(order))
    {
        // We cannot use the current  generic transform because orig_shape and orig_order are not
        // necessarily congruent
        auto t = detail::transform_order(order, orig_shape, orig_order);
        auto p = product(t);
        assert(holds_int_or_dynamic_int(p));
        return compact_col_major<TShape, TStride>(shape, get_int_or_dynamic_int<TStride>(p));
    }
    TStride res;
    // shape is at least "as deep" as order
    assert(holds_vector(shape));
    assert(rank(shape) == rank(order));
    for(size_t i = 0; i < rank(order); i++)
    {
        res.append(detail::compact_order<TShape, TStride, TOrder>(shape[i],
                                                                  order[i],
                                                                  orig_shape,
                                                                  orig_order));
    }
    return res;
}

/**
 * @brief Implements idx2crd() for recursive variant inputs.
 *
 * This is computed as follows:
 *
 * - @p index, @p shape, and @p stride are all scalars, we determine the 1D coordinate as
 *   `op(i, s, d)  => (i / d) % s`
 * - @p index is a scalar, @p shape and @p stride are tuples, we determine the component for each mode as
 *   `op(i, (s,S), (d,D)) => (op(i, s, d), op(i, S, D)...)`
 * - @p index, @p shape, and @p stride are all tuples, we consider each mode independently
 *   `op((i,I), (s,S), (d,D)) => (op(i, s, d), op((I), (S), (D)))`
 *
 * @see idx2crd()
 */
template <class TRet, class TIndex, class TShape, class TStride>
TRet idx2crd_impl(const TIndex&  index,
                  const TShape&  shape,
                  const TStride& stride)
{
    if(holds_leaf(index))
    {
        if(holds_vector(shape))
        {
            if(holds_vector(stride))
            {
                // [index, shape, stride] = [int, tuple, tuple]
                return transform_leaf([&](const auto& s, const auto& d) //
                                      {
                                          return idx2crd_impl<TRet>(index, s, d);
                                      },
                                      shape,
                                      stride);
            }
            else
            {
                // [index, shape, stride] = [int, tuple, int]
                // (generate column-major stride from integer stride)
                return transform_leaf([&](const auto& s, const auto& d) //
                                      {
                                          return idx2crd_impl<TRet>(index, s, d);
                                      },
                                      shape,
                                      compact_col_major<TShape, TStride>(shape, stride.as_int()));
            }
        }
        // [index, shape, stride] = [int, int, int]
        if(!holds_int_or_dynamic_int(index)) return cg_error_t{};
        // General rule: (index/stride) % shape
        // Catch shape = static-0 (this shouldn't happen really)
        if(shape == 0) return cg_error_t{};
        // When the stride is dynamic but the index is static-0 or the shape is static-1, we
        // bypass code generation and return 0 for these mixed static/dynamic cases
        if(holds_dynamic_int(stride))
        {
            if((index == 0) || (shape == 1)) return 0;
        }
        // cond_assign requires both arguments to be int like
        if(!holds_int_like(stride)) return cg_error_t{};
        auto res = cond_assign(
            detail::scalar_cmp<TStride, TStride, comp_pred::ne>(stride, TStride(0)),
            [=]() -> TRet {
                // If the stride is not 0, perform a div-mod
                return scalar_mod<TRet>(scalar_div<TRet>(index, stride), shape);
            },
            [=]() -> TRet {
                // When stride = static-0 or runtime-0, the coord in that mode should be 0
                // This might happen in rare situations even when shape is not static-1, see
                // comments in composition that start with "in order to force divisibility..."
                return 0;
            });
        return res;
    }
    // Handle the case where index is a vector (tuple)
    if(holds_vector(index))
    {
        // [index, shape, stride] = [tuple, tuple, tuple]
        // Check that shape and stride are also vectors (tuples)
        if(!holds_vector(shape)) return cg_error_t{};
        if(!holds_vector(stride)) return cg_error_t{};

        // Check that all have the same rank
        if(rank(index) != rank(shape)) return cg_error_t{};
        if(rank(index) != rank(stride)) return cg_error_t{};

        // This matches the C++ version: transform(idx, shape, stride, [](i,s,d){ return idx2crd(i,s,d); })
        // Use for loop to apply idx2crd_impl to each element pair
        TRet res;
        for(size_t i = 0; i < rank(index); ++i)
        {
            res.append(idx2crd_impl<TRet>(index[i], shape[i], stride[i]));
        }
        return res;
    }
    // Unsupported case
    return cg_error_t{};
}

template <class TRet, class TIndex, class TShape>
TRet idx2crd_impl(const TIndex& index,
                  const TShape& shape)
{
    if(holds_leaf(index))
    {
        // int tuple
        if(holds_vector(shape))
        {
            if(!holds_int_or_dynamic_int(index)) return cg_error_t{};
            // Generate a compact column-major stride for the given shape
            auto stride = make_basis_like<cute_stride_t<typename TShape::dyn_traits_t>>(shape);

            auto coord_idx = layout_eval(index, shape, stride);
            // Transform the result back to coordinate format
            return rec_var_cast<TRet>(coord_idx);
        }
        else
        {
            // int int
            return rec_var_cast<TRet>(index);
        }
    }
    else if(holds_vector(shape))
    {
        // tuple tuple
        if(rank(index) != rank(shape))
        {
            return cg_error_t{};
        }
        TRet res;
        for(size_t i = 0; i < rank(index); ++i)
        {
            res.append(idx2crd_impl<TRet>(index[i], shape[i]));
        }
        return res;
    }
    return cg_error_t{};
}

// Implementation of layout_eval
// layout_eval_impl takes a "coordinate", a shape, and a stride and returns a tuple. We do not constrain
// coord to be a cute_coord_t because we want the output of another layout_eval (a tuple) to be a legal
// coordinate. When an integer or a dynamic int is provided to the layout_eval entry point, we wrap it
// into a cute_coord_t by convention.
//
// This is computed as follows:
//  [coord, shape, and stride are all integers => step forward by stride]
// op(c, s, d)             => c * d
//  [coord is integer, shape and stride are tuple => divmod coord for each mode]
// op(c, (s,S), (d,D))     => op(c % prod(s), s, d) + op(c / prod(s), (S), (D))
//  [coord, shape, and stride are all tuples => consider each mode independently]
// op((c,C), (s,S), (d,D)) => op(c, s, d) + op((C), (S), (D))
//  [coord contains `_` => `_` is interpreted as `0`]
// op((_,C), (s,S), (d,D)) => op(0, s, d) + op((C), (S), (D))
template <class TCoord, class TDynTraits>
cute_int_tuple_t<TDynTraits> layout_eval_impl(const TCoord&                    coord,
                                              const cute_shape_t<TDynTraits>&  shape,
                                              const cute_stride_t<TDynTraits>& stride)
{
    using tup_t = cute_int_tuple_t<TDynTraits>;
    using coo_t = TCoord;
    if(!is_congruent(shape, stride)) return cg_error_t{};
    // If the shape is empty, return an empty tuple
    if(is_empty(shape)) return {};
    // Handle the case where coord is underscore
    // constexpr is needed in case TCoord cannot hold underscore_t
    if constexpr(is_rec_var_and_can_hold_type<TCoord, underscore_t>::value)
    {
        // When coord holds an underscore, the purpose of layout_eval is to compute
        // an offset for constructing the new base (think pointer) after
        // slicing. Users would use the slice_and_offset function which returns
        // the offset and the sliced layout. Modes associated with underscores
        // must be fully retained in the sliced layout. For example,
        //
        // [sliced_layout, offset] = slice_and_offset( (_,2) , (4,4):(4,1) )
        // sliced_layout = 4:4, offset = 2 = 0x4 + 2x1
        // The offset is obtained by computing the inner-product of the
        // coordinate and the stride after replacing _ with 0.
        //
        // In order to support TMA layouts with scaled basis stride elements,
        // layout_eval's result is an arithmetic tuple which is a superset of
        // scalars.
        //
        // When shape and stride are scalars, in order to retain the entire mode
        // associated with an underscore, we could either return a 0 scalar or
        // an empty recursive variant. Indeed, the 0 scalar is also considered
        // to be "empty" for implementation reasons, see arith_tuple_sum_op.
        //
        // When shape and stride are not scalars, we still need to walk over each
        // stride mode in order to figure out the expected rank of the arithmetic
        // tuple result. This is relevant for TMA layouts. For example,
        //
        // layout = (5,5,(5,5)):(1@0,5@0,(1@1,1@2))
        // layout( (2,2,_) ) is expected to be of rank 3 because of 1@2
        //
        // Given all these reasons, the simplest thing to do is to replace coord
        // with 0 and call back to layout_eval.
        if(holds_underscore(coord))
        {
            return detail::layout_eval_impl(TCoord(0), shape, stride);
        }
    }
    // Trivial cases are handled, do some sanity checks
    assert(rank(shape) > 0);
    assert(is_congruent(shape, stride));
    // Handle the case where coord is a leaf
    if(holds_leaf(coord))
    {
        // A coordinate can hold an int, a dynamic value, or an underscore
        // The scalar underscore case was handled in the first case
        if(!holds_int_or_dynamic_int(coord)) return cg_error_t{};
        if(holds_leaf(shape))
        {
            // [coord, shape, stride] = [scalar, scalar, scalar]
            // We allow out of bound accesses in order to be consistent with composition which in
            // turn needs to support tiling with tile sizes that don't properly divide the tiled
            // shape. The user would need to use predication in such cases.
            return scalar_mul<tup_t>(coord, stride);
        }
        // [coord, shape, stride] = [scalar, tuple, tuple]
        tup_t  idx;
        coo_t  c = coord;
        size_t r = rank(shape);
        for(size_t i = 0; i < r - 1; i++)
        {
            auto  p = product(shape[i]);
            coo_t mod;
            std::tie(c, mod) = scalar_divmod<coo_t, coo_t>(c, p);
            idx              = arith_tuple_sum<tup_t>(idx, layout_eval_impl(mod, shape[i], stride[i]));
        }
        // For the last iteration, do not perform any div
        // Do not even perform a mod for consistent OOB access
        idx = arith_tuple_sum<tup_t>(idx, layout_eval_impl(c, shape[r - 1], stride[r - 1]));
        return idx;
    }
    // Handle the case where coord is a vector
    if(holds_vector(coord))
    {
        // [coord, shape, stride] = [tuple, tuple, tuple]
        // (1) is not compatible with 5 even though both are rank 1
        // => shape and stride must at least be of depth 1 (they hold a vector)
        if(!holds_vector(shape)) return cg_error_t{};
        // coord must be of the same rank for now (it clearly can't be of smaller rank)
        if(rank(coord) != rank(shape)) return cg_error_t{};
        tup_t idx;
        for(size_t i = 0; i < rank(shape); ++i)
        {
            idx = arith_tuple_sum<tup_t>(idx,
                                         detail::layout_eval_impl(get_vector_elem(coord, i),
                                                                  get_vector_elem(shape, i),
                                                                  get_vector_elem(stride, i)));
        }
        return idx;
    }
    // Handle any other case as an error
    return cg_error_t{};
}

//
// To/from string for layouts
//

/// Specialization of value_to_string for layout
template <class TDynTraits>
struct value_to_string<layout_t<TDynTraits>>
{
    using layout = layout_t<TDynTraits>;
    static std::string to_str(const layout& ly)
    {
        std::string str = to_string(ly.shape());
        str += ":";
        str += to_string(ly.stride());
        return str;
    }
};

// Specialization of detail::cg_from_chars for layout_t
template <class TDynTraits>
class cg_from_chars<layout_t<TDynTraits>>
{
public:
    using layout     = layout_t<TDynTraits>;
    using offset_t   = typename layout::int_t;
    using sha_t      = typename layout_t<TDynTraits>::shape_t;
    using str_t      = typename layout_t<TDynTraits>::stride_t;
    using optional_t = std::optional<layout>;
    cg_from_chars(const char* first, const char* last, bool must_consume_all)
    {
        auto cur       = find_non_whitespace(first, last);
        auto colon_sep = std::find(cur, last, ':');
        auto sh        = parse_from_chars_advance<sha_t>(cur, colon_sep);
        if(!sh.has_value())
        {
            // Failure parsing the layout shape
            result_ = from_chars_result{cur, std::errc::invalid_argument};
            return;
        }
        if(colon_sep == last)
        {
            cur     = detail::find_non_whitespace(cur, last);
            result_ = from_chars_result{cur,
                                        (must_consume_all && (cur != last)) ?
                                            std::errc::invalid_argument :
                                            std::errc{}};
            if(result_.ec == std::errc{})
            {
                // The layout string did not contain a colon separator that
                // would precede a stride region of the string, so we construct
                // a column-major layout.
                value_ = layout(std::move(sh.value()), gen_col_major{});
            }
            else
            {
                // Error: there were additional characters after the shape.
            }
        }
        else
        {
            // A colon was present, so we will parse the stride next.
            cur     = colon_sep + 1;
            auto st = parse_from_chars_advance<str_t>(cur, last);
            if(!st.has_value())
            {
                // Error: Parsing the stride failed.
                result_ = from_chars_result{cur, std::errc::invalid_argument};
                return;
            }
            cur     = detail::find_non_whitespace(cur, last);
            result_ = from_chars_result{cur,
                                        (must_consume_all && (cur != last)) ?
                                            std::errc::invalid_argument :
                                            std::errc{}};
            if(result_.ec == std::errc{})
            {
                // Success - assign to the std::optional member.
                value_ = layout(std::move(sh.value()),
                                std::move(st.value()));
            }
        }
    }
    const optional_t&        parse_value() { return value_; }
    const from_chars_result& parse_result() { return result_; }

private:
    from_chars_result result_;
    optional_t        value_;
};

//
// Encode/decode for layouts
//

// Generate a binary storage representation of a given layout.
// The encoded format has the following form:
// [shape_encoding] 0xFFFFFFFF [stride_encoding]
// For the shape and stride encoding, refer to the comments for the encode()
// function that operates on recursive variants.
template <class TDynTraits>
struct value_encoder<layout_t<TDynTraits>>
{
    template <class TBuffer>
    static void encode_value(const layout_t<TDynTraits>& ly, TBuffer& buffer)
    {
        encode(buffer, ly.shape());
        encode(buffer, std::numeric_limits<uint32_t>::max());
        encode(buffer, ly.stride());
    }
};

template <class TDynTraits>
struct value_decoder<layout_t<TDynTraits>>
{
    using layout   = layout_t<TDynTraits>;
    using offset_t = typename layout::int_t;
    using sha_t    = typename layout_t<TDynTraits>::shape_t;
    using str_t    = typename layout_t<TDynTraits>::stride_t;
    template <class TIterator>
    static std::optional<layout> decode_value(TIterator& it, const TIterator& end)
    {
        auto optShape = decode<sha_t>(it, end);
        if(!optShape.has_value())
        {
            return {};
        }
        auto optSep = decode<uint32_t>(it, end);
        if(!optSep.has_value() || (optSep.value() != std::numeric_limits<uint32_t>::max()))
        {
            return {};
        }
        auto optStride = decode<str_t>(it, end);
        if(!optStride.has_value())
        {
            return {};
        }
        return layout(optShape.value(), optStride.value());
    }
};

//
// Coalesce
//

// Returns an equivalent layout with potentially lower rank, by looking for
// modes that can be coalesced. Intuitively, a mode can be coalesced if the
// product of its size and its stride is equal to the stride of the mode on its
// right.
//
// Inputs to this function must be flattened (depth=1).
//
// Background:
//
// Consider a rank-2 layout with the following values:
// SHAPE:   (s0, s1)
// STRIDE:  (d0, d1)
// Can we traverse the elements with an equivalent rank-1 layout?
// SHAPE:   (sN)
// STRIDE:  (dN)
//
// Considering the rank-2 layout, the (1D) offset value for a pair of
// coordinates (c0, c1) is obtained via the inner product:
//
// offset = (c0 * d0) + (c1 * d1)     0 <= c0 < s0
//                                    0 <= c1 < s1
//
// If the stride d1 = s0 * d0, then this is equal to:
//
// offset = (c0 * d0) + (c1 * s0 * d0)
//        = d0 * [c0 + (c1 * s0)].
//
// If we consider a potential 1D mapping of (c0, c1), in colexicographical
// ordering, to cN:
// c0   c1       cN
//  0    0        0
//  1    0        1
//  2    0        2
// ..    0        ..
// s0-1  0        s0-1
//  0    1        s0
//  1    1        s0+1
//  2    1        s0+2
// ..   ..
//
// we can see that cN = c0 + (c1 * s0).
//
// Therefore, the original rank-2 layout corresponds to a 1D layout with shape
// sN = (s0 * s1) and stride dN = d0.
//
// In the example above, if the shape s0 = 1, the only valid coordinate for mode
// 0 is c0 = 0. As the stride d0 would always be multiplied by 0 when
// calculating the offset, the value of d0 is irrelevant. In that case, we can
// use sN = s1 and dN = d1 in place of (s0, s1) | (d0, d1).
//
// Similarly, if shape s1 = 1, the only valid coordinate for mode 1 is c1 = 0.
// In this case, we replace (s0, 1) | (d0, xx) with (s0, d0).
//
// If none of the cases above apply, we keep (s0, s1) | (d0, d1).
//
// To generalize the rank-2 case above to an arbitrary rank-N layout, we process
// the layout from right to left, merging modes or storing them in the result
// layout unmodified.
//
// @pre shp and str are flattened
template <class TDynTraits>
void coalesce_(cute_shape_t<TDynTraits>&  shp,
               cute_stride_t<TDynTraits>& str)
{
    using shape_t  = cute_shape_t<TDynTraits>;
    using stride_t = cute_stride_t<TDynTraits>;

    assert(rank(shp) == rank(str));
    // shp and str must already have been flattened
    assert(depth(shp) <= 1);
    assert(depth(str) <= 1);
    shape_t                     s;
    stride_t                    d;
    std::function<void(size_t)> coalesce_fold = [&](size_t i) {
        if(!is_empty(s)) // If accumulator has elements
        {
            if(s.back() == 1) // If last shape is 1, drop
            {
                s.pop_back();
                d.pop_back();
                coalesce_fold(i);
                return;
            }
            // If last mode coalesces, merge
            if(all_are_static(s.back(), shp[i], d.back(), str[i]) &&
               (str[i] == scalar_mul<stride_t>(s.back(), d.back())))
            {
                s.back() = scalar_mul<shape_t>(s.back(), shp[i]);
                return;
            }
        }
        // Else, Append
        s.append(shp[i]);
        d.append(str[i]);
    };
    for(size_t i = 0; i < rank(shp); ++i)
    {
        coalesce_fold(i);
    }
    shp.swap(s);
    str.swap(d);
}

//
// Composition
//

// 5 cases to consider for the visit-based dispatch when composing with a tile,
// implemented inside the detail namespace:
//   1. layout / layout
//   2. layout / int
//   3. layout / underscore
//   4. layout / dynamic
//   5. layout / tile

template <class TDynTraits>
layout_t<TDynTraits> composition_impl(const cute_shape_t<TDynTraits>&  lhs_shape,
                                      const cute_stride_t<TDynTraits>& lhs_stride,
                                      const cute_shape_t<TDynTraits>&  rhs_shape,
                                      const cute_stride_t<TDynTraits>& rhs_stride)
{
    using layout_t = layout_t<TDynTraits>;
    using shape_t  = cute_shape_t<TDynTraits>;
    using stride_t = cute_stride_t<TDynTraits>;

    // Right-distributivity of Layout composition for RHS tuple
    if(holds_vector(rhs_shape))
    {
        layout_t ly;
        // ly = (lhs o rhs[0], lhs o rhs[1], lhs o rhs[2], ...)
        assert(rank(rhs_shape) == rank(rhs_stride));
        for(size_t i = 0; i < rank(rhs_shape); ++i)
        {
            layout_t lyMode = composition_impl(lhs_shape,
                                               lhs_stride,
                                               rhs_shape[i],
                                               rhs_stride[i]);
            ly.shape().append(std::move(lyMode.shape()));
            ly.stride().append(std::move(lyMode.stride()));
        }
        return ly;
    }
    // Special case for a RHS ScaledBasis stride
    if(holds_scaled_basis(rhs_stride))
    {
        if(!holds_int(rhs_shape)) return cg_error_t{};
        using sb_t                 = typename find_scaled_basis_in_rec_var<stride_t>::value;
        const auto& sb             = std::get<sb_t>(rhs_stride);
        const auto& v              = sb.modes();
        auto        lhs_shape_ref  = std::cref(lhs_shape);
        auto        lhs_stride_ref = std::cref(lhs_stride);
        assert(v.size() > 0);
        for(const auto& mode : v)
        {
            // lhs_mode's shape (and stride) need to be a vector to grab a mode
            if(!holds_vector(lhs_shape_ref.get())) return cg_error_t{};
            // mode must be a valid index into the shape/stride
            if(rank(lhs_shape_ref.get()) <= static_cast<size_t>(mode)) return cg_error_t{};
            lhs_shape_ref  = lhs_shape_ref.get()[mode];
            lhs_stride_ref = lhs_stride_ref.get()[mode];
        }
        // Call composition again with a right layout with integer shape and stride
        return detail::composition_impl(lhs_shape_ref.get(),
                                        lhs_stride_ref.get(),
                                        rhs_shape,
                                        rec_var_cast<stride_t>(sb.value()));
    }
    // Special case shortcut for any RHS static stride-0
    if(rhs_stride == 0)
    {
        return layout_t(rhs_shape, rhs_stride);
    }
    // Special case shortcut for any LHS integral shape
    if(holds_int(lhs_shape))
    {
        return layout_t(rhs_shape, scalar_mul<stride_t>(rhs_stride, lhs_stride));
    }
    // General case: LHS tuple, RHS integral
    // rhs_stride is s:d with s and d static or dynamic integers
    if(!holds_int_or_dynamic_int(rhs_shape) || !holds_int_or_dynamic_int(rhs_stride)) return cg_error_t{};
    assert((depth(lhs_shape) <= 1) && "detail::composition_impl expects lhs to be flat");
    int32_t  R = static_cast<int32_t>(rank(lhs_shape));
    layout_t result;
    layout_t rest(rhs_shape, rhs_stride);
    for(int32_t i = 0; i < R - 1; ++i)
    {
        auto& curr_shape  = lhs_shape[i];
        auto& curr_stride = lhs_stride[i];

        // Strong divisibility condition -- requires composition to be statically verifiable.
        // This implies that RHS stride must not be dynamic and the LHS shape must not have dynamic multimodes,
        //   cases where composition could fail with certain dynamic values.
        // Unfortunately, these cases may already be used (inappropriately?) in certain implementations/kludges,
        // so this is too strict.
        // Weak divisibility condition -- verify the divisibility condition when
        // values are static.
        if(holds_int(curr_shape) && holds_int(rest.stride()))
        {
            if(0 != (rest.stride().as_int() % curr_shape.as_int()) && rest.stride().as_int() >= curr_shape.as_int())
            {
                // Weak Stride Divisibility Condition
                return layout_t(shape_t(cg_error_t{}), stride_t(cg_error_t{}));
            }
        }
        auto abs_rest_stride = scalar_abs(rest.stride());
        // next_shape:  ceil(exclusive_prefix_product<r>(lhs_shape) / rhs_stride)
        auto next_shape = ceil_div(curr_shape, abs_rest_stride);
        // next_stride: ceil(rhs_stride / exclusive_prefix_product<r>(lhs_shape))
        auto next_stride = scalar_mul<stride_t>(ceil_div(abs_rest_stride, curr_shape), signum(rest.stride()));

        if((next_shape == 1) || (rest.shape() == 1))
        {
            rest.stride() = next_stride;
            continue;
        }
        auto new_shape = scalar_min<shape_t>(next_shape, rest.shape());
        // Strong divisibility condition
        // Weak divisibility condition
        if(holds_int(new_shape) && holds_int(rest.shape()))
        {
            if(0 != (rest.shape().as_int() % new_shape.as_int()))
            {
                // Shape Divisibility Condition
                return layout_t(shape_t(cg_error_t{}), stride_t(cg_error_t{}));
            }
        }
        result.shape().append(new_shape);
        result.stride().append(scalar_mul<stride_t>(rest.stride(), curr_stride));
        rest.shape()  = scalar_div<shape_t>(rest.shape(), new_shape);
        rest.stride() = next_stride;
    }
    if(0 == rank(result.shape()))
    {
        return layout_t(rest.shape(), scalar_mul<stride_t>(rest.stride(), lhs_stride[R - 1]));
    }
    if(rest.shape() == 1)
    {
        return layout_t(unwrap(result.shape()), unwrap(result.stride()));
    }
    result.shape().append(rest.shape());
    result.stride().append(scalar_mul<stride_t>(rest.stride(), lhs_stride[R - 1]));
    // Note: coalesce() below is not in CuTe C++ as of this writing. Without it,
    // some modes are split. For example: ((8,?),?,?):((1,8),?,?) o (64,64)
    // without coalesce: ((8,8),64):((1,8),?)
    // with coalesce:    (   64,64):(    1,?)
    return coalesce(result);
    // Some remarks:
    // - the last mode might get extended, even without divisibility
    //   ex: 1:1 o 4:1          = 4:1           cosize(rhs) > size(lhs)
    //       (4,3):(3,1) o 24:1 = (4,6):(3,1)   cosize(rhs) > size(lhs)
    //       (4,3):(3,1) o 8:1  = (4,2):(3,1)   2=8/4 doesn't divide 3 and vice-versa
    //         at this point we would have rest_stride=1, rest_shape=2, flat_shape[R-1]=3
    //         rest_shape and flat_shape[R-1] do not satisfy the preconditions for shape_div
    // - in order to force divisibility, the user could extend the lhs layout with 1:0 before
    //   calling composition, in which case the mode that gets extended has a stride of 0 so it
    //   doesn't matter
    //   ex: (4,3,1):(3,1,0) o 24:1 = (4,3,2):(3,1,0)
    //         cosize(rhs) = 24 > size(lhs) = 12 but the last mode has 0 stride so the resulting
    //         layout maps coordinate 12 to the same index as coordinate 0 (it wraps around)
    //         11's natural coordinate is (3,2,0)
    //         12's natural coordinate is (0,0,1) -> 0
    //   Capping a Layout with 1:0 forces divisibility and extends in stride-0
    //   Note however that this creates a mode like 2:0 (stride=static-0 but shape!=static-1)
    //
    // The reason why the divisibility condition doesn't apply to the last mode is that CuTe
    // "rounds up" to allow tiling modes that are not perfectly divisible. We then use
    // predication tensors to mask out the part that is out of bound.
    // Note that, if rank(flat_shape) = 1, we simply use rhs_shape for this mode.
}

// layout / layout
template <class TDynTraits>
layout_t<TDynTraits> composition(const layout_t<TDynTraits>& lhs, const layout_t<TDynTraits>& rhs)
{
    // rhs(0) is used to get the coprofile of rhs without generating code
    auto coprof = rhs(0);
    // Verify the pre-conditions of coalesce_z before calling it
    if((depth(coprof) > 0) && (rank(coprof) > rank(lhs))) return cg_error_t{};
    auto lyc = coalesce_z(lhs, coprof);
    return detail::composition_impl(lyc.shape(), lyc.stride(), rhs.shape(), rhs.stride());
}

// layout / underscore
template <class TDynTraits>
layout_t<TDynTraits> composition(const layout_t<TDynTraits>& lhs,
                                 const underscore_t& /*rhs*/)
{
    return lhs;
}

// layout / vector
template <class TDynTraits>
layout_t<TDynTraits> composition(const layout_t<TDynTraits>&                 lhs,
                                 const std::vector<cute_tile_t<TDynTraits>>& rhs)
{
    using lay_t = layout_t<TDynTraits>;
    if(rhs.size() > rank(lhs))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("detail::composition got a RHS tile with too many modes");
#else
        return cg_error_t{};
#endif
    }
    assert(rank(lhs) >= rhs.size());
    std::vector<lay_t> lys;
    // Perform by-mode composition for modes 0 .. rhs.size()-1
    for(size_t i = 0; i < rhs.size(); i++)
    {
        // Call composition outside the detail namespace to visit rhs[i] again
        lys.push_back(composition(lay_t(lhs.shape()[i], lhs.stride()[i]), rhs[i]));
    }
    // Concatenate modes of lys
    return make_layout(lys);
}

//
// Inverses
//

template <class InputIt, class OutputIt, class T, class BinaryOp>
OutputIt exclusive_scan(InputIt  first,
                        InputIt  last,
                        OutputIt out,
                        T        init,
                        BinaryOp op)
{
#if !defined(__clang__) && !defined(__GNUC__) && !defined(_MSC_VER)
#error "Unexpected compiler! Only clang, GCC, and MSVC are supported."
#endif

// Check if std::exclusive_scan is available in the standard library
// Clang:
//   - use libc++ or libstdc++ from early 2020+ (20200312, corresponds to GCC 9.3)
// GCC:
//   - use libstdc++ from 9.3+ (std::exclusive_scan() was added to gcc libstdc++-v3 in commit
//     ed920373a5faece7ea0bfdfebbd615294165c01c on 18-Jun-2019, and
//     seems to have landed somewhere around v 9.3.
//     https://github.com/gcc-mirror/gcc/blob/releases/gcc-9.3.0/libstdc%2B%2B-v3/include/std/numeric)
// MSVC:
//   - TODO: Determine MSVC version requirements and handle any versions that
//     do not support std::exclusive_scan()
#if(defined(__clang__) &&                                               \
    (defined(_LIBCPP_VERSION) ||                                        \
     (defined(_GLIBCXX_RELEASE) && _GLIBCXX_RELEASE >= 9 &&             \
      defined(__GLIBCXX__) && __GLIBCXX__ >= 20200312))) ||             \
    (defined(__GNUC__) &&                                               \
     ((__GNUC__ > 9) || ((__GNUC__ == 9) && (__GNUC_MINOR__ >= 3)))) || \
    defined(_MSC_VER)
    return std::exclusive_scan(first, last, out, init, op);
#else
    // Manual implementation for older standard libraries
    while(first != last)
    {
        *out++    = init;
        auto next = first;
        // Avoid invoking op() if we won't need it for the next iteration
        if(++next != last)
        {
            init = op(init, *first);
        }
        ++first;
    }
    return out;
#endif
}

//
// Products/divides
//

struct divide_op
{};

struct product_op
{};

// Utility for partially specializing product_divide
template <class TDynTraits, class OpTag>
struct prod_div_operator;
// Partial specialization for logical divides
template <class TDynTraits>
struct prod_div_operator<TDynTraits, divide_op>
{
    layout_t<TDynTraits> operator()(const layout_t<TDynTraits>& a,
                                    const layout_t<TDynTraits>& b,
                                    const bool = false)
    {
        return detail::composition(a,
                                   layout_t<TDynTraits>(b,
                                                        complement_extend(b, a.shape())));
    }
};

// Partial specialization for logical products
template <class TDynTraits>
struct prod_div_operator<TDynTraits, product_op>
{
    layout_t<TDynTraits> operator()(const layout_t<TDynTraits>& a,
                                    const layout_t<TDynTraits>& b,
                                    const bool = false)
    {
        return layout_t<TDynTraits>(a, detail::composition(complement(a), b));
    }
};

// See the implementation of composition for the cases to consider for the
// visit-based dispatch when the rhs is a tile.
// The implementations in the detail namespace are generic and handle both
// products and divides. We also hide the use of zipping. The client's interface
// simply calls into the detail namespace. Thus, the followings are added:
//   - the layout / tile generic product_divide with an explicit zip boolean parameter
//     with this, logical and zipped products & divides are covered
//   - the layout / layout generic tiled product_divide
//   - the layout / tile generic tiled product_divide

// Forward declaration for layout / tile
// Seems needed because the layout / vector case can go back to the
// layout / tile case when the tile contains other tiles as elements
template <class TDynTraits,
          class TRecVar,
          std::enable_if_t<is_tile<TRecVar>::value, bool> = true,
          class OpTag>
auto product_divide(const layout_t<TDynTraits>& a,
                    const TRecVar&              b,
                    OpTag                       tag,
                    bool                        zip);
// layout / layout
template <class TDynTraits, class OpTag>
layout_t<TDynTraits> product_divide(const layout_t<TDynTraits>& a,
                                    const layout_t<TDynTraits>& b,
                                    const OpTag,
                                    const bool = false)
{
    return prod_div_operator<TDynTraits, OpTag>{}(a, b);
}

// layout / int
template <class TDynTraits,
          class OpTag,
          class T,
          std::enable_if_t<std::is_integral_v<T>, bool> = true>
layout_t<TDynTraits> product_divide(const layout_t<TDynTraits>& a,
                                    const T&                    b,
                                    const OpTag                 tag,
                                    const bool = false)
{
    return detail::product_divide(a, layout_t<TDynTraits>(LShape(b)), tag);
}

// layout / underscore
template <class TDynTraits, class OpTag>
layout_t<TDynTraits> product_divide(const layout_t<TDynTraits>& a,
                                    const underscore_t& /*b*/,
                                    const OpTag,
                                    const bool = false)
{
    return a;
}

// layout / vector
template <class TDynTraits,
          class TRecVar,
          std::enable_if_t<is_tile<TRecVar>::value, bool> = true,
          class OpTag>
typename find_layout_in_rec_var<TRecVar>::value product_divide(const layout_t<TDynTraits>& a,
                                                               const std::vector<TRecVar>& b,
                                                               const OpTag                 tag,
                                                               const bool                  zip)
{
    using LHSLayout = layout_t<TDynTraits>;
    using RHSLayout = typename find_layout_in_rec_var<TRecVar>::value;
    if(b.size() > rank(a))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("detail::logical_divide got a RHS tile with too many modes");
#else
        return RHSLayout(typename RHSLayout::shape_t(cg_error_t{}),
                         typename RHSLayout::stride_t(cg_error_t{}));
#endif
    }
    assert(rank(a) >= b.size());
    std::vector<RHSLayout> lys;
    // Perform by-mode divides for modes 0 .. b.size()-1
    lys.reserve(b.size());
    for(size_t i = 0; i < b.size(); i++)
    {
        lys.push_back(detail::product_divide(LHSLayout(a.shape()[i], a.stride()[i]), b[i], tag, zip));
    }
    // Append the remaining modes of a to lys
    for(size_t i = b.size(); i < rank(a); i++)
        lys.push_back(RHSLayout(a.shape()[i], a.stride()[i]));
    if(zip)
    {
        // Modes 0 .. b.size()-1 are rank-2, unzip them
        std::vector<RHSLayout> modes0, modes1;
        for(size_t i = 0; i < b.size(); i++)
        {
            if(rank(lys[i]) == 2)
            {
                modes0.push_back(RHSLayout(lys[i].shape()[0], lys[i].stride()[0]));
                modes1.push_back(RHSLayout(lys[i].shape()[1], lys[i].stride()[1]));
            }
            else
            {
                modes0.push_back(RHSLayout(cg_error_t{}));
                modes1.push_back(RHSLayout(cg_error_t{}));
            }
        }
        // Append the remaining modes to modes1
        for(size_t i = b.size(); i < rank(a); i++)
            modes1.push_back(lys[i]);
        // Concatenate modes of modes0 and modes1
        // Concatenate again to return a rank-2 layout
        return make_layout(std::vector<RHSLayout>{make_layout(modes0), make_layout(modes1)});
    }
    // Concatenate modes of lys
    return make_layout(lys);
}

// layout / tile
// If the rec_var holds a vector, it dispatches to a by-mode operation
// If the rec_var holds a layout, it dispatches to a standard logical operation between two layouts
// If the rec_var holds an underscore_t, it's a no-op and returns the LHS layout
// If the rec_var holds an integer, it wraps it into a layout
// If the rec_var holds a dynamic_t, NOT SUPPORTED
template <class TDynTraits,
          class TRecVar,
          std::enable_if_t<is_tile<TRecVar>::value, bool>,
          class OpTag>
auto product_divide(const layout_t<TDynTraits>& a,
                    const TRecVar&              b,
                    const OpTag                 tag,
                    const bool                  zip)
{
    return b.visit([&a, tag, zip](auto&& v) //
                   {
                       return detail::product_divide(a, std::forward<decltype(v)>(v), tag, zip);
                   });
}

/**
 * @brief tile the target shape `trg_shape` with respect to the layout `layout` in a mode-wise way and return the result layout.
 *
 * By default, sets tiling order to be column-major.
 * Assuming mode `i` of @p layout is `(layout_shape_i : layout_stride_i)` and mode `i` of @p trg_shape is `trg_shape_i`,
 * mode `i` of the result layout could be viewed as `(layout_shape_i, trg_shape_i/layout_shape_i) : (layout_stride_i, new_stride_i)`.
 * The return layout will be the result of `coalesce` on it.
 * Order @p ord_shape controls the order of determining the `new_stride_i` for each mode.
 * The difference could be seen by the follwoing example:
 * ```
 *  auto atom = layout_t(shape(8, 64), stride(64, 1));
 *  auto mn_shape = shape(64, 128, 2);
 *                                                 mode-wise tiling                                                    coalesce
 *  tile_to_shape(atom, mn_shape, int_tuple(0,1,2)) ================> ((8, 8), (64, 2), 2):((64, 512), (1, 4096), 8192) ========> (64, (64, 2), 2):(64, (1, 4096), 8192)
 *  tile_to_shape(atom, mn_shape, int_tuple(2,1,0)) ================> ((8, 8), (64, 2), 2):((64, 2048), (1, 1024), 512) ========> ((8, 8), (64, 2), 2):((64, 2048), (1, 1024), 512)
 * ```
 * Please note there are several requirements on given arguments. If not satisfied, layout `(error_t:error_t)` will be returned.
 * 1. `rank(trg_shape) >= rank(layout)`;
 * 2. Each mode in `product_each(trg_shape)` must be exactly multiple of corresponding mode in `product_each(layout.shape())`;
 * 3. @p layout must be static.
 *
 * @param layout       input layout to be tiled on
 * @param trg_shape    input shape to tile
 * @param ord          input order
 * @return layout_t<TDynTraits>
 */
template <class TDynTraits, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool> = true>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   const TRecVar&                  ord)
{
    using lay_t = layout_t<TDynTraits>;
    using str_t = typename lay_t::stride_t;

    if(rank(block) > rank(trg_shape)) return cg_error_t{};
    if(!is_integral_only(ord)) return cg_error_t{};

    size_t r            = rank(trg_shape);
    lay_t  padded_block = append_to_rank_N(r, block, lay_t(1));
    auto   block_shape  = product_each(padded_block.shape());
    auto   target_shape = product_each(trg_shape);

    auto  product_shape = ceil_div(target_shape, block_shape);
    lay_t product_ordered_layout(product_shape, compact_order<str_t>(product_shape, ord));
    return blocked_product(padded_block, product_ordered_layout);
}

template <class TDynTraits>
cute_coord_t<TDynTraits> increment_coord_impl(const cute_coord_t<TDynTraits>& coord, const cute_shape_t<TDynTraits>& shape)
{
    using coord_t     = cute_coord_t<TDynTraits>;
    using shape_t     = cute_shape_t<TDynTraits>;
    using int_tuple_t = cute_int_tuple_t<TDynTraits>;

    auto                         result = repeat_like<coord_t>(coord, 0);
    cute_int_tuple_t<TDynTraits> carry  = 1;
    // For all but last mode, increment with carry
    for(size_t i = 0; i < leaf_count(result) - 1; ++i)
    {
        auto& result_i = leaf_at_fpos(result, i);
        auto& coord_i  = leaf_at_fpos(coord, i);
        auto& shape_i  = leaf_at_fpos(shape, i);

        // If shape_i is statically 1, result_i will be 0 and carry will pass through unchanged.
        if(shape_i != 1)
        {
            auto sum = scalar_add<coord_t>(coord_i, carry);
            result_i = cond_assign(
                detail::scalar_cmp<coord_t, shape_t, comp_pred::lt>(sum, shape_i),
                [&sum]() -> coord_t { return sum; },
                []() -> coord_t { return 0; });
            carry = cond_assign(
                detail::scalar_cmp<coord_t, shape_t, comp_pred::lt>(sum, shape_i),
                []() -> int_tuple_t { return 0; },
                []() -> int_tuple_t { return 1; });
        }
    }

    // Last mode always increment with carry to be consistent with idx2crd
    auto& result_last = leaf_at_fpos(result, leaf_count(result) - 1);
    auto& coord_last  = leaf_at_fpos(coord, leaf_count(coord) - 1);
    result_last       = scalar_add<coord_t>(coord_last, carry);

    return result;
}

struct stride_lt_visitor
{
    // int, int
    template <class TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    bool operator()(TInt lhs, TInt rhs) const
    {
        return lhs < rhs;
    }
    // int, scaled_basis
    template <class TInt,
              class... TValueTypes,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    bool operator()(TInt lhs, const scaled_basis_t<TValueTypes...>& rhs) const
    {
        assert(0 == lhs);
        assert(rhs.value_holds_int());
        return lhs < rhs.static_integral_value();
    }
    // int, dynamic
    template <class TInt,
              class TDynamic,
              std::enable_if_t<std::is_integral_v<TInt> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    bool operator()(TInt lhs, const TDynamic& rhs) const
    {
        // We can't sort dynamic (unknown) values, but we support them as a
        // variant type for cases where there is a single dynamic value. By
        // convention, we will assume all dynamic values are greater than all
        // integers, but we don't expect the sort operation to actually use
        // this fact.
        assert(false);
        return true;
    }
    // scaled_basis, int
    template <class... TValueTypes,
              class TInt,
              std::enable_if_t<std::is_integral_v<TInt>, bool> = true>
    bool operator()(const scaled_basis_t<TValueTypes...>& lhs, TInt rhs) const
    {
        assert(0 == rhs);
        assert(lhs.value_holds_int());
        return (lhs.static_integral_value() < rhs);
    }
    // scaled_basis, dynamic
    template <class TDynamic,
              class... TValueTypes,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    bool operator()(const scaled_basis_t<TValueTypes...>& lhs, const TDynamic& rhs) const
    {
        // We can't sort dynamic (unknown) values, but we support them as a
        // variant type for cases where there is a single dynamic value. By
        // convention, we will assume all dynamic values are greater than all
        // integers, but we don't expect the sort operation to actually use
        // this fact.
        assert(false);
        return true;
    }
    // scaled_basis, scaled_basis
    template <class... TValueTypes>
    bool operator()(const scaled_basis_t<TValueTypes...>& lhs, const scaled_basis_t<TValueTypes...>& rhs) const
    {
        auto seq_lt = [](const std::vector<static_int_t>& lhs,
                         const std::vector<static_int_t>& rhs) -> bool {
            for(size_t i = 0; i < lhs.size(); ++i)
            {
                // The lhs sequence is longer. We assume that the rhs sequence
                // is padded with values less than any possible value present.
                if(i >= rhs.size())
                {
                    return false;
                }
                if(lhs[i] < rhs[i])
                {
                    return true;
                }
                if(rhs[i] < lhs[i])
                {
                    return false;
                }
                // Continue with the next element
            }
            if(rhs.size() > lhs.size())
            {
                return true;
            }
            // The sequences are identical
            return false;
        };
        // Scaled basis comparison uses the pycute approach of performing a
        // lexicographical comparison of the concatenated mode sequence and basis
        // scale value. (We are not currenly checking for identical starting
        // sequences as pycute does.)
        std::vector<static_int_t> lhs_vec, rhs_vec;
        for(auto m : lhs.modes()) { lhs_vec.push_back(m); }
        lhs_vec.push_back(lhs.static_integral_value());
        for(auto m : rhs.modes()) { rhs_vec.push_back(m); }
        rhs_vec.push_back(rhs.static_integral_value());
        return seq_lt(lhs_vec, rhs_vec);
    }
    // dynamic, int
    template <class TDynamic,
              class TInt,
              std::enable_if_t<std::is_integral_v<TInt> && has_dynamic_t_base<TDynamic>::value, bool> = true>
    bool operator()(const TDynamic& lhs, TInt rhs) const
    {
        // We can't sort dynamic (unknown) values, but we support them as a
        // variant type for cases where there is a single dynamic value. By
        // convention, we will assume all dynamic values are greater than all
        // integers, but we don't expect the sort operation to actually use
        // this fact.
        assert(false);
        return false;
    }
    // dynamic, scaled_basis
    template <class TDynamic,
              class... TValueTypes,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    bool operator()(const TDynamic& lhs, const scaled_basis_t<TValueTypes...>& rhs) const
    {
        // We can't sort dynamic (unknown) values, but we support them as a
        // variant type for cases where there is a single dynamic value. By
        // convention, we will assume all dynamic values are greater than all
        // integers, but we don't expect the sort operation to actually use
        // this fact.
        assert(false);
        return false;
    }
    // dynamic, scaled_basis
    template <class TDynamic,
              std::enable_if_t<has_dynamic_t_base<TDynamic>::value, bool> = true>
    bool operator()(const TDynamic& lhs, const TDynamic& rhs) const
    {
        // We can't sort dynamic (unknown) values, but we support them as a
        // variant type for cases where there is a single dynamic value.
        // We don't expect the sort operation to actually use this overload.
        assert(false);
        return false;
    }
};

// projector
// Struct to provide projection implementation, as used by CuTe functions
// (left_inverse(), right_inverse(), complement()).
// Current support for projection is limited to strides that contain either:
// - integer values (static or dynamic)
// - scaled basis values (for coordinate layouts)
// The TInt, TDynInt, and TScaledBasis template parameters provide the types
// for these values.
// Note that currently, scaled basis arguments must hold static or dynamic
// integer values. (Ratio values for scaled basis are not supported.) Callers
// must ensure that this condition holds.)
template <class TInt, class TDynInt, class TScaledBasis>
struct projector
{
    using src_var_t = std::variant<TInt, TDynInt, TScaledBasis>;
    // Special case: projecting the stride variant (int/scaled basis) with
    // itself, always returning an integer (static or dynamic).
    template <class TStride>
    static TStride proj(const src_var_t& src_trg)
    {
        if(std::holds_alternative<TScaledBasis>(src_trg))
        {
            const auto& trg_sb = std::get<TScaledBasis>(src_trg);
            // Not handling ratio values yet
            assert(trg_sb.value_holds_int() || trg_sb.value_holds_dynamic());
            // Return the scaled basis value.
            if(trg_sb.value_holds_int())
            {
                return TStride{trg_sb.static_integral_value()};
            }
            else
            {
                return TStride{trg_sb.dynamic_value()};
            }
        }
        else if(std::holds_alternative<TInt>(src_trg))
        {
            return TStride{std::get<TInt>(src_trg)};
        }
        else
        {
            return TStride{std::get<TDynInt>(src_trg)};
        }
    }
    // Projecting an HTuple (shape/stride/...) to an int or scaled basis target.
    // Projecting to an integer target returns the source value. Projecting
    // to a scaled basis target retrieves a value from the source using the
    // scaled basis modes as indices.
    template <class TRecVar>
    static TRecVar& proj(TRecVar& rv, const src_var_t& trg)
    {
        if(std::holds_alternative<TInt>(trg) ||
           std::holds_alternative<TDynInt>(trg))
        {
            return rv;
        }
        const auto& sb = std::get<TScaledBasis>(trg);
        assert(check_get_indices(rv, sb.modes()));
        return rv.get(sb.modes());
    }
};

// Utility function to replace any empty vector elements of recursive variant
// rv with a copy of value v. This internal function is used to "clean up"
// hierarchical tuples for some CuTe functions.
template <class TRecVar, class T>
void replace_empty_vector_with(TRecVar& rv, const T& v)
{
    if(holds_vector(rv))
    {
        auto& vec = get_vector(rv);
        if(vec.empty())
        {
            rv = v;
        }
        else
        {
            for(auto& e : vec)
            {
                replace_empty_vector_with(e, v);
            }
        }
    }
}

} // namespace detail

template <class TShape, class TStride>
TStride compact_col_major(const TShape& shape, TStride current)
{
    return detail::compact_col_major_scalar(shape, current);
}

template <class TShape, class TStride>
TStride compact_row_major(const TShape& shape, TStride current)
{
    return detail::compact_row_major_scalar(shape, current);
}

template <class TStride, class TShape, class TOrder>
TStride compact_order(const TShape& shape, const TOrder& order)
{
    if(!weakly_congruent(order, shape)) return cg_error_t{};
    if(!is_int_or_dynamic_int_only(shape)) return cg_error_t{};
    if(!is_int_or_dynamic_int_only(order)) return cg_error_t{};
    if(is_static(order))
    {
        return detail::compact_order<TShape, TStride, TOrder>(shape, order, shape, order);
    }

    // Find the max static integer in order
    auto max_elem = fold(order,
                         TOrder(std::numeric_limits<typename TOrder::int_t>::min()),
                         [](const TOrder& a, const TOrder& b) -> TOrder //
                         {
                             assert(holds_int(a));
                             if(!holds_int(b)) return a;
                             return std::max(a.as_int(), b.as_int());
                         })
                        .as_int();
    // Replace dynamic entries in order by large integers from left to right
    auto static_order = transform_leaf([&](const TOrder& rv) -> TOrder //
                                       {
                                           if(holds_dynamic_int(rv)) return ++max_elem;
                                           return rv;
                                       },
                                       order);
    return detail::compact_order<TShape, TStride, TOrder>(shape, static_order, shape, static_order);
}

template <class TIndex, class TDynTraits>
cute_coord_t<TDynTraits> idx2crd(const TIndex&                    idx,
                                 const cute_shape_t<TDynTraits>&  shape,
                                 const cute_stride_t<TDynTraits>& stride)
{
    if constexpr(std::is_integral<TIndex>::value || has_dynamic_t_base<TIndex>::value)
    {
        return detail::idx2crd_impl<cute_coord_t<TDynTraits>>(rec_var<TIndex>(idx), shape, stride);
    }
    else
    {
        return detail::idx2crd_impl<cute_coord_t<TDynTraits>>(idx, shape, stride);
    }

    CUTEGEN_GCC_UNREACHABLE;
}

template <class TIndex, class TDynTraits>
cute_coord_t<TDynTraits> idx2crd(const TIndex&                   idx,
                                 const cute_shape_t<TDynTraits>& shape)
{
    // Follow C++ CuTe style: use layout_eval with make_basis_like, then transform
    if constexpr(std::is_integral<TIndex>::value || has_dynamic_t_base<TIndex>::value)
    {
        return idx2crd(cute_int_tuple_t<TDynTraits>(idx), shape);
    }
    else
    {
        return detail::idx2crd_impl<cute_coord_t<TDynTraits>>(idx, shape);
    }
    CUTEGEN_GCC_UNREACHABLE;
}

template <class TCoord, class TDynTraits>
cute_int_tuple_t<TDynTraits> layout_eval(const TCoord&                    coord,
                                         const cute_shape_t<TDynTraits>&  shape,
                                         const cute_stride_t<TDynTraits>& stride)
{
    // Convenience constexpr branching to allow coord to be an integer or a dynamic.
    if constexpr(std::is_integral<TCoord>::value || has_dynamic_t_base<TCoord>::value)
    {
        using int_t = typename cute_coord_t<TDynTraits>::int_t;
        return layout_eval(cute_coord_t<TDynTraits>(static_cast<int_t>(coord)), shape, stride);
    }
    else
    {
        // Temporary workaround to allow layout evaluation of scaled basis values with
        // mode 0. These occur in cutegen as (1), but in PyCuTe these occur as
        // arithmetic tuples, which automatically expand to the rank of the
        // associated shape in layout_eval().
        if(holds_vector(coord) && (1 == rank(coord)) && (1 != rank(shape)))
        {
            auto coord_0 = append_to_rank_N(rank(shape), coord, TCoord{0});
            return detail::layout_eval_impl(coord_0, shape, stride);
        }
        return detail::layout_eval_impl(coord, shape, stride);
    }
    CUTEGEN_GCC_UNREACHABLE;
}

template <class TDynTraits>
cute_coord_t<TDynTraits> increment_coord(const cute_coord_t<TDynTraits>& coord, const cute_shape_t<TDynTraits>& shape)
{
    if(!is_congruent(coord, shape)) return cg_error_t{};
    if(has_underscore(coord)) return cg_error_t{};
    return detail::increment_coord_impl(coord, shape);
}

//
// Layout
//

template <class TDynTraits>
layout_t<TDynTraits>::layout_t(shape_t sh, stride_t str) :
    shape_(std::move(sh)), stride_(std::move(str))
{
    validate();
}

template <class TDynTraits>
layout_t<TDynTraits>::layout_t(shape_t sh, stride_t str, prefix_product_tag) :
    shape_(std::move(sh)),
    stride_(prefix_product(rec_var_cast<stride_t>(shape_), std::move(str)))
{
    validate();
}

template <class TDynTraits>
layout_t<TDynTraits>::layout_t(shape_t s) :
    shape_(std::move(s)),
    stride_(compact_col_major<shape_t, stride_t>(shape_))
{
    validate();
}

// Avoid delegating constructor for constructors that infer the stride from
// the shape. In other words, don't do this:
// layout_t(shape_t s, gen_col_major) :
//     layout_t(std::move(s), compact_col_major<shape_t, stride_t>(s)) {}
// Evaluation order of arguments is unspecified, and compact_col_major(s)
// will be incorrect after s has been moved. (Alternatively, we could change
// to pass-by-reference and then use the delegating constructor.)
template <class TDynTraits>
layout_t<TDynTraits>::layout_t(shape_t s, gen_col_major) :
    shape_(std::move(s)),
    stride_(compact_col_major<shape_t, stride_t>(shape_))
{
    validate();
}

template <class TDynTraits>
layout_t<TDynTraits>::layout_t(shape_t s, gen_row_major) :
    shape_(std::move(s)),
    stride_(compact_row_major<shape_t, stride_t>(shape_))
{
    validate();
}

template <class TDynTraits>
template <typename TIntegral,
          std::enable_if_t<std::is_integral<TIntegral>::value, bool>>
layout_t<TDynTraits>::layout_t(TIntegral s) :
    layout_t(shape_t(static_cast<typename shape_t::int_t>(s)), compact_col_major<shape_t, stride_t>(static_cast<typename shape_t::int_t>(s)))
{}

template <class TDynTraits>
layout_t<TDynTraits>::layout_t(cg_error_t) :
    layout_t(shape_t(cg_error_t{}), stride_t(cg_error_t{}))
{}

template <class TDynTraits>
template <class... TLayout>
layout_t<TDynTraits>::layout_t(layout_t l0, layout_t l1, TLayout... ln) :
    layout_t(shape_t(std::move(l0.shape()), std::move(l1.shape()), std::move(ln.shape())...),
             stride_t(std::move(l0.stride()), std::move(l1.stride()), std::move(ln.stride())...))
{}

template <class TDynTraits>
bool layout_t<TDynTraits>::operator==(const layout_t<TDynTraits>& other) const
{
    return (shape() == other.shape()) &&
           (stride() == other.stride());
}

template <class TDynTraits>
bool layout_t<TDynTraits>::operator!=(const layout_t<TDynTraits>& other) const
{
    return !(*this == other);
}

template <class TDynTraits>
const typename layout_t<TDynTraits>::shape_t& layout_t<TDynTraits>::shape() const { return shape_; }

template <class TDynTraits>
const typename layout_t<TDynTraits>::stride_t& layout_t<TDynTraits>::stride() const { return stride_; }

template <class TDynTraits>
typename layout_t<TDynTraits>::shape_t& layout_t<TDynTraits>::shape() { return shape_; }

template <class TDynTraits>
typename layout_t<TDynTraits>::stride_t& layout_t<TDynTraits>::stride() { return stride_; }

template <class TDynTraits>
auto layout_t<TDynTraits>::rank() const { return cutegen::rank(shape_); }

template <class TDynTraits>
void layout_t<TDynTraits>::append(const layout_t& other)
{
    this->shape_.append(other.shape());
    this->stride_.append(other.stride());
}

template <class TDynTraits>
template <class TCoord>
auto layout_t<TDynTraits>::operator()(const TCoord& coord) const
{
    if(is_empty(shape()))
    {
        return cute_int_tuple_t<TDynTraits>(0);
    }
    return layout_eval(coord, shape(), stride());
}

template <class TDynTraits>
template <class OtherLayout>
layout_t<TDynTraits> layout_t<TDynTraits>::compose(const OtherLayout& other) const
{
    return composition(*this, other);
}

template <class TDynTraits>
template <class OtherShape>
layout_t<TDynTraits> layout_t<TDynTraits>::with_shape(const OtherShape& shape) const
{
    return composition(*this, layout_t{shape});
}

template <class TDynTraits>
std::string layout_t<TDynTraits>::to_string() const
{
    return cutegen::to_string(*this);
}

template <class TDynTraits>
void layout_t<TDynTraits>::validate()
{
    if(!is_congruent(shape(), stride()))
    {
        shape_  = cg_error_t{};
        stride_ = cg_error_t{};
    }
}

//
// Utilities
//

template <class TDynTraits>
bool is_valid(const layout_t<TDynTraits>& l)
{
    bool is_valid_shape = is_valid(l.shape()) && !any_leaf_is(l.shape(), [](const auto& e) {
                              return holds_int(e) && get_int(e) <= 0;
                          });
    return (is_valid_shape && is_valid(l.stride()));
}

template <class TCoord, class TDynTraits>
auto layout_eval(const TCoord& coord, const layout_t<TDynTraits>& l)
{
    return layout_eval(coord, l.shape(), l.stride());
}

template <class TCoord, class TDynTraits>
cute_int_tuple_t<TDynTraits> crd2idx(const TCoord&                   coord,
                                     const cute_shape_t<TDynTraits>& shape)
{
    using shape_t  = cute_shape_t<TDynTraits>;
    using stride_t = cute_stride_t<TDynTraits>;
    // Pack the coord into a linear index using implicit column-major strides
    // derived from `shape`. The compact column-major strides are the running
    // prefix products of `shape`.
    return layout_eval(coord, shape, compact_col_major<shape_t, stride_t>(shape));
}

template <class TDynTraits>
std::ostream& operator<<(std::ostream& os, const layout_t<TDynTraits>& ly)
{
    os << to_string(ly);
    return os;
}

template <class TLayout,
          class TString,
          std::enable_if_t<std::is_base_of_v<layout_t<typename TLayout::dyn_traits_t>,
                                             TLayout>,
                           bool>>
std::optional<TLayout> make_layout(const TString& str)
{
    return from_string<TLayout>(str);
}

/// Makes a tile out of a string if possible.
template <class TTile,
          class TString,
          std::enable_if_t<is_tile<TTile>::value, bool>>
std::optional<TTile> make_tile(const TString& str)
{
    return from_string<TTile>(str);
}

//
// Functions forwarding to recursive variants implementations
//

template <class TDynTraits>
bool has_error(const layout_t<TDynTraits>& l)
{
    return has_error(l.shape()) || has_error(l.stride());
}

template <class TDynTraits, class TRange>
bool check_get_indices(const layout_t<TDynTraits>& l, const TRange& r)
{
    return check_get_indices(l.shape(), r);
}

template <class TDynTraits>
auto get(const layout_t<TDynTraits>& ly, size_t mode)
{
    assert(mode < rank(ly));
    return layout_t(ly.shape()[mode], ly.stride()[mode]);
}

template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto get(const layout_t<TDynTraits>& ly, const TRange& range)
{
    return layout_t(ly.shape().get(range),
                    ly.stride().get(range));
}

template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool>>
auto get(const layout_t<TDynTraits>& ly, TInt... idx)
{
    return layout_t(ly.shape().get(idx...),
                    ly.stride().get(idx...));
}

template <class TDynTraits,
          class TRange,
          std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto select(const layout_t<TDynTraits>& ly, const TRange& range)
{
    return layout_t(select(ly.shape(), range),
                    select(ly.stride(), range));
}

template <class TDynTraits,
          class... TInt,
          std::enable_if_t<(std::is_integral_v<TInt> && ...), bool>>
auto select(const layout_t<TDynTraits>& ly, TInt... idx)
{
    return layout_t(select(ly.shape(), idx...),
                    select(ly.stride(), idx...));
}

template <class TDynTraits>
bool compatible(const layout_t<TDynTraits>& layoutA,
                const layout_t<TDynTraits>& layoutB)
{
    return compatible(layoutA.shape(), layoutB.shape());
}

template <class TDynTraits>
bool is_congruent(const layout_t<TDynTraits>& layoutA,
                  const layout_t<TDynTraits>& layoutB)
{
    // Assume strides are congruent
    return is_congruent(layoutA.shape(), layoutB.shape());
}

template <class... Ts, class TDynTraits>
bool weakly_congruent(const rec_var_base<Ts...>& lhs, const layout_t<TDynTraits>& rhs)
{
    return weakly_congruent(lhs, rhs.shape());
}

template <class TDynTraits>
size_t rank(const layout_t<TDynTraits>& l0)
{
    return rank(l0.shape());
}

template <class TDynTraits>
size_t rank(const layout_t<TDynTraits>& l0, int mode)
{
    return rank(l0.shape()[mode]);
}

template <class TDynTraits>
size_t depth(const layout_t<TDynTraits>& l0)
{
    // Layout depth is that of its shape
    return depth(l0.shape());
}

template <class TDynTraits>
cute_tile_t<TDynTraits> shape_to_tile(const cute_shape_t<TDynTraits>& shape)
{
    using tile_t = cute_tile_t<TDynTraits>;
    // We cannot use transform: result_t needs to be lay_t for supporting
    // result_t(cg_error_t{}) when exceptions are disabled. But the append
    // method for layout_t doesn't do what we want...
    if(holds_leaf(shape)) return tile_t(layout_t<TDynTraits>(shape));

    cute_tile_t<TDynTraits> res;
    for(const auto& s : shape) res.append(shape_to_tile(s));
    return res;
}

template <class TDynTraits>
cute_shape_t<TDynTraits> extract_shape_from_tile(const cute_tile_t<TDynTraits>& tile)
{
    using lay_t = layout_t<TDynTraits>;
    if(!holds_vector(tile))
    {
        if(std::holds_alternative<lay_t>(tile))
            return std::get<lay_t>(tile).shape();
        else // cg::shape does not support underscore_t, but cg::tile does
            return cg_error_t{};
    }
    cute_shape_t<TDynTraits> res;
    for(const auto& t : tile)
        res.append(extract_shape_from_tile(t));
    return res;
}

template <class TDynTraits>
auto is_static(const layout_t<TDynTraits>& l)
{
    return (is_static(l.shape()) && is_static(l.stride()));
}

template <class TDynTraits>
auto is_static_with_integral_stride_elements(const layout_t<TDynTraits>& l)
{
    return (is_static(l.shape()) && is_integral_only(l.stride()));
}

template <class TDynTraits>
auto size(const layout_t<TDynTraits>& l)
{
    return size(l.shape());
}

template <class TDynTraits>
auto size(const layout_t<TDynTraits>& l, size_t idx)
{
    return size(l.shape(), idx);
}

template <class TDynTraits>
auto static_size(const layout_t<TDynTraits>& l)
{
    assert(is_static(l.shape()));
    auto res = size(l);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits>
auto static_size(const layout_t<TDynTraits>& l, size_t idx)
{
    auto res = size(l, idx);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits>
auto size(const cute_tile_t<TDynTraits>& tile)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename lay_t::shape_t;
    // Convention adopted by CuTe C++
    // scalar_mul chooses to return an error for underscores instead so that we don't blindly
    // make this assumption all the time
    if(holds_underscore(tile)) return sha_t(0);
    if(std::holds_alternative<lay_t>(tile)) return size(std::get<lay_t>(tile));
    sha_t  res = 1;
    size_t r   = rank(tile);
    for(size_t i = 0; i < r; i++)
    {
        res = scalar_mul<sha_t>(res, size(tile[i]));
    }
    return res;
}

template <class TDynTraits>
auto static_size(const cute_tile_t<TDynTraits>& tile)
{
    assert(is_static(tile));
    return size(tile).as_int();
}

template <class TDynTraits>
auto append_to_rank_N(size_t N, const layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e)
{
    using lay_t = layout_t<TDynTraits>;
    return lay_t(append_to_rank_N(N, l.shape(), e.shape()), append_to_rank_N(N, l.stride(), e.stride()));
}

template <class TDynTraits>
auto prepend_to_rank_N(size_t N, const layout_t<TDynTraits>& l, const layout_t<TDynTraits>& e)
{
    using lay_t = layout_t<TDynTraits>;
    return lay_t(prepend_to_rank_N(N, l.shape(), e.shape()), prepend_to_rank_N(N, l.stride(), e.stride()));
}

template <class TDynTraits>
auto group(int B, int E, const layout_t<TDynTraits>& l)
{
    using TLayout = layout_t<TDynTraits>;
    return TLayout(group(B, E, l.shape()),
                   group(B, E, l.stride()));
}

template <class TDynTraits>
auto take(int B, int E, const layout_t<TDynTraits>& l)
{
    using lay_t = layout_t<TDynTraits>;
    return lay_t(take(B, E, l.shape()), take(B, E, l.stride()));
}

template <class TDynTraits>
std::optional<bool> eq_op_can_fold(const layout_t<TDynTraits>& lhs, const layout_t<TDynTraits>& rhs)
{
    std::optional<bool> shape_can_fold = eq_op_can_fold(lhs.shape(), rhs.shape());
    if(!shape_can_fold.has_value())
        return std::nullopt;
    std::optional<bool> stride_can_fold = eq_op_can_fold(lhs.stride(), rhs.stride());
    if(!stride_can_fold.has_value())
        return std::nullopt;
    // Both shape and stride can fold
    return shape_can_fold.value() && stride_can_fold.value();
}

//
// Layout specific
//

template <class TDynTraits>
auto coprofile(const layout_t<TDynTraits>& ly)
{
    // A postcondition of right_inverse() is that the coprofile of layout x is
    // weakly compatible with right_inverse(x).
    // Therefore, we ensure that the coprofile of an empty layout has an
    // integer profile. (Without this, the coprofile might be ().)
    if(is_empty(ly.shape()))
    {
        return cute_int_tuple_t<TDynTraits>(0);
    }
    return ly(0);
}

template <class TDynTraits>
auto cosize(const layout_t<TDynTraits>& l)
{
    return size(coshape(l));
}

template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto cosize(const layout_t<TDynTraits>& l0, const TRange& idx)
{
    return cosize(get(l0, idx));
}

template <class TDynTraits>
auto static_cosize(const layout_t<TDynTraits>& l0)
{
    assert(is_static(l0));
    auto res = cosize(l0);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits, class TRange, std::enable_if_t<!std::is_integral_v<TRange>, bool>>
auto static_cosize(const layout_t<TDynTraits>& l0, const TRange& idx)
{
    auto res = cosize(l0, idx);
    assert(holds_int(res));
    return res.as_int();
}

template <class TDynTraits>
auto coshape(const layout_t<TDynTraits>& l)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename layout_t<TDynTraits>::shape_t;
    using str_t = typename layout_t<TDynTraits>::stride_t;
    using coo_t = cute_coord_t<TDynTraits>;
    lay_t labs(l.shape(),
               transform_leaf([](const str_t& s) //
                              {
                                  return scalar_abs<str_t>(s);
                              },
                              l.stride()));
    auto  co_coord = labs(scalar_add<coo_t>(size(l), cute_int_tuple_t<TDynTraits>(-1)));
    auto  co_shape = arith_tuple_sum<sha_t>(co_coord, repeat_like<sha_t>(co_coord, 1));
    return co_shape;
}

template <class TDynTraits>
layout_t<TDynTraits> coalesce(const layout_t<TDynTraits>& l)
{
    auto new_s = flatten(l.shape());
    auto new_d = flatten(l.stride());
    detail::coalesce_(new_s, new_d);
    // Guard against empty shape - just return ():().
    if(0 == rank(new_s))
    {
        return layout_t<TDynTraits>(std::move(new_s), std::move(new_d));
    }
    if((rank(new_s) > 1) && (new_s.back() == 1))
    {
        new_s.pop_back();
        new_d.pop_back();
    }
    return layout_t<TDynTraits>(unwrap(new_s), unwrap(new_d));
}

template <class TDynTraits>
cute_shape_t<TDynTraits> coalesce(const cute_shape_t<TDynTraits>& sh)
{
    using sh_t = cute_shape_t<TDynTraits>;
    sh_t sh_c  = flatten(sh);
    auto iter  = sh_c.begin();
    while(iter != sh_c.end())
    {
        auto iter_next = std::next(iter);
        if(iter_next != sh_c.end())
        {
            if(is_static(*iter) == is_static(*iter_next))
            {
                *iter = scalar_mul<sh_t>(*iter, *iter_next);
                sh_c.erase(iter_next);
                continue;
            }
        }
        ++iter;
    }
    return unwrap(sh_c);
}

template <class TDynTraits>
layout_t<TDynTraits> coalesce_z(const layout_t<TDynTraits>& l)
{
    auto f_shape  = flatten(l.shape());
    auto f_stride = flatten(l.stride());
    detail::coalesce_(f_shape, f_stride);
    return layout_t<TDynTraits>(unwrap(f_shape), unwrap(f_stride));
}

template <class TDynTraits, class TRecVar>
layout_t<TDynTraits> coalesce_z(const layout_t<TDynTraits>& layout, const TRecVar& trg_profile)
{
    if(holds_vector(trg_profile))
    {
        layout_t<TDynTraits> res;
        assert(rank(trg_profile) <= layout.rank() && "rank of profile must by less or equal to layout to coalesce");
        for(size_t i = 0; i < layout.rank(); i++)
        {
            layout_t<TDynTraits> l{layout.shape()[i], layout.stride()[i]};
            if(i < rank(trg_profile))
            {
                res.append(coalesce_z(l, trg_profile[i]));
            }
            else
            {
                res.append(std::move(l));
            }
        }
        return res;
    }
    return coalesce_z(layout);
}

template <class TDynTraits>
layout_t<TDynTraits> coalesce_up_with(const layout_t<TDynTraits>& l, uint32_t x)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename lay_t::shape_t;
    using str_t = typename lay_t::stride_t;
    if(rank(l) == 0) return l;

    auto   flat_shape  = flatten(l.shape());
    auto   flat_stride = flatten(l.stride());
    sha_t  res_s       = flat_shape[0];
    str_t  res_d       = flat_stride[0];
    size_t r           = rank(flat_shape);
    for(size_t i = 1; i < r; i++)
    {
        const sha_t& curr_s = flat_shape[i];
        const str_t& curr_d = flat_stride[i];
        sha_t&       back_s = res_s.back();
        str_t&       back_d = res_d.back();
        // Skip static-1 shape modes
        if(curr_s == 1) continue;
        // Replace the back element with anything if it's a static-1 shape mode
        if(back_s == 1)
        {
            back_s = curr_s;
            back_d = curr_d;
            continue;
        }
        if(all_are_static(back_s, back_d, curr_s, curr_d))
        {
            auto p0 = scalar_mul<sha_t>(back_s, curr_s);
            auto p1 = scalar_mul<str_t>(back_s, back_d);
            if(!holds_int(p0)) return cg_error_t{};
            // If it coalesces and the resulting shape mode's extent is <= x, do it
            if((p0.as_int() <= static_cast<int>(x)) && (p1 == curr_d))
            {
                back_s = back_s.as_int() * curr_s.as_int();
                continue;
            }
        }
        // Cannot coalesce, append and continue
        res_s.append(curr_s);
        res_d.append(curr_d);
    }
    if(res_s == 1) return lay_t(sha_t(1));
    return lay_t(res_s, res_d);
}

template <class TDynTraits, class TRecVar>
layout_t<TDynTraits>
coalesce(const layout_t<TDynTraits>& layout, const TRecVar& trg_profile)
{
    if(holds_vector(trg_profile))
    {
        layout_t<TDynTraits> res;
        if(rank(trg_profile) > layout.rank()) return cg_error_t{};
        for(size_t i = 0; i < layout.rank(); i++)
        {
            layout_t<TDynTraits> l{layout.shape()[i], layout.stride()[i]};
            if(i < rank(trg_profile))
            {
                res.append(coalesce(l, trg_profile[i]));
            }
            else
            {
                res.append(std::move(l));
            }
        }
        return res;
    }
    else
    {
        return coalesce(layout);
    }
}

template <class TDynTraits>
auto filter_zeros(const layout_t<TDynTraits>& l)
{
    return layout_t<TDynTraits>(filter_zeros(l.stride(), l.shape()), l.stride());
}

template <class TDynTraits, class TShape>
auto filter_zeros(const layout_t<TDynTraits>& l, const TShape& target_profile)
{
    return layout_t<TDynTraits>(filter_zeros(target_profile, l.shape()), l.stride());
}

template <class TDynTraits>
auto filter(const layout_t<TDynTraits>& l)
{
    return coalesce(filter_zeros(l));
}

template <class TDynTraits>
auto flatten(const layout_t<TDynTraits>& l)
{
    return layout_t(flatten(l.shape()), flatten(l.stride()));
}

template <class TDynTraits>
auto make_identity_layout(const cute_shape_t<TDynTraits>& shape)
{
    using str_t = typename layout_t<TDynTraits>::stride_t;
    return layout_t(shape, make_basis_like<str_t>(shape));
}

template <class TCoord, class TDynTraits>
auto domain_offset(const TCoord& c, const layout_t<TDynTraits>& l)
{
    return std::make_tuple(l, l(c));
}

template <class TCoord, class TDynTraits>
auto slice(const TCoord& crd, const layout_t<TDynTraits>& layout)
{
    using TLayout = layout_t<TDynTraits>;
    return TLayout(slice(crd, layout.shape()), slice(crd, layout.stride()));
}

template <class TCoord, class TDynTraits>
auto dice(const TCoord& crd, const layout_t<TDynTraits>& layout)
{
    return layout_t<TDynTraits>(dice(crd, layout.shape()), dice(crd, layout.stride()));
}

template <class TCoord, class TLayout>
auto slice_and_offset(const TCoord& crd, const TLayout& layout)
{
    auto t = std::make_tuple(slice(crd, layout), layout_eval(crd, layout));
    return t;
}

//
// Concatenation
//

template <class TLayout>
auto make_layout(const std::vector<TLayout>& lys)
{
    TLayout result;
    for(const auto& ly : lys)
    {
        // Filter out the empty layouts.
        if(is_empty(ly.shape()))
        {
            continue;
        }
        result.shape().append(ly.shape());
        result.stride().append(ly.stride());
    }
    return result;
}

//
// Make layout like
//
template <class TDynTraits>
layout_t<TDynTraits> make_layout_like(const layout_t<TDynTraits>& layout)
{
    return layout_t<TDynTraits>(
        layout.shape(),
        compact_order<typename layout_t<TDynTraits>::stride_t>(
            filter_zeros(layout.stride(), layout.shape()),
            layout.stride()));
}

//
// Complement
//
template <class TDynTraits, class CoSizeHi>
layout_t<TDynTraits> complement(const layout_t<TDynTraits>& l, CoSizeHi cosize_hi)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename lay_t::shape_t;
    using str_t = typename lay_t::stride_t;

    using int_t = typename lay_t::int_t;
    using sb_t  = scaled_basis_t<ratio, static_int_t, typename TDynTraits::dynamic_int_t>;

    // For scaled-basis strides, compute the un-extended complement using the
    // existing pycute-aligned complement(l) algorithm, then apply pycute's
    // extend step: for each per-basis bucket (a leaf of coprofile(l)), extend
    // the last shape so the bucket covers the matching sub-tree of cosize_hi.
    if(!is_int_or_dynamic_int_only(l.stride()))
    {
        using tuple_t = cute_int_tuple_t<TDynTraits>;

        lay_t base = complement(l);
        if(!is_valid(base))
        {
            return cg_error_t{};
        }

        sha_t   cosize_shape = sha_t(cosize_hi);
        tuple_t coprof       = coprofile(l);

        // Magnitude of the rightmost stride in a per-basis bucket.
        // strideC may be a leaf (the bucket has a single mode) or a vector.
        // Returns true on success and writes the magnitude to `out`.
        auto last_stride_magnitude = [](const str_t& strideC,
                                        int_t&       out) -> bool {
            const str_t& last = strideC.back();
            if(std::holds_alternative<sb_t>(last))
            {
                const sb_t& sb = std::get<sb_t>(last);
                // static_integral_value() asserts the value is static; if it
                // is dynamic, signal failure so the caller returns cg_error_t.
                if(!sb.is_static())
                {
                    return false;
                }
                out = sb.static_integral_value();
                return true;
            }
            if(std::holds_alternative<int_t>(last))
            {
                out = std::get<int_t>(last);
                return true;
            }
            return false;
        };

        // Pycute-style _coalesce: drop the trailing size-1 mode only when
        // the layout has rank > 1. Single-mode layouts keep their stride
        // (and thus their basis label) intact.
        auto pycute_coalesce = [](const lay_t& ly) -> lay_t {
            sha_t f_shape  = flatten(ly.shape());
            str_t f_stride = flatten(ly.stride());
            detail::coalesce_(f_shape, f_stride);
            if(rank(f_shape) == 0)
            {
                return lay_t{sha_t{int_t{1}}, str_t{int_t{0}}};
            }
            if(rank(f_shape) > 1 && f_shape.back() == int_t{1})
            {
                f_shape.erase(f_shape.begin() + rank(f_shape) - 1);
                f_stride.erase(f_stride.begin() + rank(f_stride) - 1);
            }
            return lay_t(unwrap(f_shape), unwrap(f_stride));
        };

        auto extend_fn = [&](const sha_t& shapeC,
                             const str_t& strideC,
                             const sha_t& shapeA) -> lay_t {
            int_t sizeC{};
            if(!last_stride_magnitude(strideC, sizeC) || sizeC == int_t{0})
            {
                return lay_t{cg_error_t{}};
            }
            int_t sizeA = static_size(shapeA);
            int_t sizeR = (sizeA + sizeC - int_t{1}) / sizeC;

            // Replace the back of shapeC with sizeR.
            sha_t new_shapeC = shapeC;
            if(holds_vector(new_shapeC))
            {
                auto& vec  = get_vector(new_shapeC);
                vec.back() = sha_t(sizeR);
            }
            else
            {
                new_shapeC = sha_t(sizeR);
            }

            return pycute_coalesce(lay_t(new_shapeC, strideC));
        };

        // Pycute walks coprof and the extend args in parallel via zip_longest
        // (transform_apply_leaf with rank-mismatched args). Two cases occur:
        //   - coprof has a mode at i: extend the corresponding bucket of base.
        //   - coprof exhausted at i: that basis dim was unused by the tiler,
        //     so the leftover is the full extent in basis_like[i].
        // We walk top-level modes manually (mirroring pycute's outer loop)
        // so we can support rank(coprof) != rank(cosize_shape).
        str_t basis_like = make_basis_like<str_t>(cosize_shape);

        size_t cp_rank = rank(coprof);
        size_t cs_rank = rank(cosize_shape);
        size_t total   = std::max(cp_rank, cs_rank);

        // get_mode below indexes cosize_shape/basis_like by i in [0, total).
        // When cosize_shape is a vector shorter than cp_rank, those reads
        // would be out of bounds; the case is also ill-formed (no shape_a
        // available to extend the extra coprof modes).
        if(holds_vector(cosize_shape) && (cs_rank < cp_rank))
        {
            return cg_error_t{};
        }

        // Index a recursive variant by mode i. If rv is a vector, returns rv[i].
        // If rv is a scalar (the layout has only a single top-level mode), the
        // scalar IS the mode, so return it as-is (broadcasting it across i).
        auto get_mode = [](const auto& rv, size_t i) -> const std::decay_t<decltype(rv)>& {
            if(holds_vector(rv))
            {
                return rv[i];
            }
            return rv;
        };

        std::vector<lay_t> modes;
        modes.reserve(total);
        for(size_t i = 0; i < total; ++i)
        {
            const sha_t& shape_a = get_mode(cosize_shape, i);
            const str_t& basis_a = get_mode(basis_like, i);
            if(i < cp_rank)
            {
                const sha_t& shape_c  = get_mode(base.shape(), i);
                const str_t& stride_c = get_mode(base.stride(), i);
                modes.push_back(extend_fn(shape_c, stride_c, shape_a));
            }
            else
            {
                // Coprof exhausted: full-extent leftover in basis_a.
                modes.push_back(lay_t(shape_a, basis_a));
            }
        }

        return make_layout(modes);
    }

    // complement only supports Static-Stride Or rank-1 Dynamic-Stride layouts
    if(!is_static(l.stride()) && (rank(l) > 1))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("complement only support Static-Stride Or rank-1 Dynamic-Stride layouts");
#else
        return lay_t(typename lay_t::shape_t(cg_error_t{}),
                     typename lay_t::stride_t(cg_error_t{}));
#endif
    }

    // For modes with 0-stride, set the shape to 1. Flatten, and then
    // coalesce adjacent modes that can be accessed as a single mode.
    auto flat_layout = filter(l);

    // Workaround to get this deprecated version of complement() to work with the new
    // new coalesce() implementation, which no longer makes this substitution.
    // (The call to filter() above has a coalesce() call internally.)
    if(is_integral_only(flat_layout.shape()) && (1 == static_size(flat_layout.shape())))
    {
        flat_layout = lay_t{sha_t{1}, str_t{0}};
    }

    // Special case for empty layouts (rank() == 0) or stride-0 layouts.
    // Empty layouts have an empty stride tuple rather than stride 0, so we
    // need both checks. Both cases map to a single codomain element.
    if(rank(flat_layout) == 0 || flat_layout.stride() == 0)
    {
        auto full = coalesce(layout_t<TDynTraits>(cosize_hi, gen_col_major()));
        // When the cotarget is fully covered by a single element (cosize_hi
        // coalesces to extent 1), gen_col_major assigns the extent-1 mode a
        // 0 stride, yielding the degenerate "1:0". PyCuTe keeps the size-1
        // identity "1:1" here, so match that for parity.
        if(is_integral_only(full.shape()) && (static_size(full.shape()) == 1))
        {
            return layout_t<TDynTraits>(sha_t{1}, str_t{1});
        }
        return full;
    }

    using ss_pair = std::pair<sha_t, str_t>; // shape stride pair
    std::vector<ss_pair> s_d;
    std::transform(flat_layout.shape().begin(),     // input A begin
                   flat_layout.shape().end(),       // input A end
                   flat_layout.stride().begin(),    // input B begin
                   std::back_inserter(s_d),         // output iterator
                   [](const auto& a, const auto& b) //
                   {
                       return ss_pair(a, b);
                   });

    if(rank(flat_layout) > 1)
    {
        std::sort(s_d.begin(),
                  s_d.end(),
                  [](const ss_pair& a, const ss_pair& b) {
                      return (a.second.as_int() < b.second.as_int());
                  });
    }

    layout_t<TDynTraits> lc;
    lc.stride().append(1);
    // Note: loop stops before end()-1 instead of end()
    for(auto it = s_d.begin(); it != s_d.end() - 1; ++it)
    {
        auto curr_shape  = (*it).first;
        auto curr_stride = (*it).second;
        auto prev_stride = lc.stride().back();
        lc.shape().append(scalar_div<sha_t>(curr_stride, prev_stride));
        lc.stride().append(scalar_mul<str_t>(curr_shape, curr_stride));
    }
    // Append the last shape mode
    auto curr_stride = s_d.back().second;
    auto prev_stride = lc.stride().back();
    // new shape  = min_stride / last_stride
    lc.shape().append(scalar_div<sha_t>(curr_stride, prev_stride));
    // Compute the rest_shape and rest_stride
    // new stride = min_stride * curr_shape
    auto new_stride  = scalar_mul<str_t>(curr_stride, s_d.back().first);
    auto rest_shape  = coalesce(ceil_div(sha_t(cosize_hi), rec_var_cast<sha_t>(new_stride)));
    auto rest_stride = compact_col_major(rest_shape, new_stride);
    // When the complement already fully covers the cotarget, the leftover
    // mode has extent 1. compact_col_major assigns extent-1 modes a 0 stride,
    // which would collapse the whole result to 1:0. PyCuTe
    // keeps the running cosize as the stride so a fully-covering complement is
    // "1:cosize"; preserve that here for parity.
    if(is_integral_only(rest_shape) && (static_size(rest_shape) == 1))
    {
        rest_stride = new_stride;
    }
    // Note that the CuTe C++ implementation appends and has nesting here,
    // but the coalesce() call will flatten first.
    flatten_into(rest_shape, lc.shape());
    flatten_into(rest_stride, lc.stride());
    return coalesce(lc);
}

template <class TDynTraits>
layout_t<TDynTraits> complement(const layout_t<TDynTraits>& layout)
{
    using layout_t    = layout_t<TDynTraits>;
    using shape_t     = typename layout_t::shape_t;
    using shape_vec_t = std::vector<shape_t>;
    using stride_t    = typename layout_t::stride_t;
    using tuple_t     = cute_int_tuple_t<TDynTraits>;
    using int_t       = typename layout_t::int_t;
    using sb_t        = scaled_basis_t<ratio, static_int_t, typename TDynTraits::dynamic_int_t>;
    using tile_t      = cute_tile_t<TDynTraits>;
    using dyn_t       = typename TDynTraits::dynamic_int_t;

    // Arithmetic operations performed on strides when calculating the complement
    // do not currently support ratio values.
    auto is_sb_with_ratio_value = [](const stride_t& l) {
        return std::holds_alternative<sb_t>(l) &&
               std::holds_alternative<ratio>(std::get<sb_t>(l).value());
    };

    // Shape and stride must be valid.
    // The stride must only have scaled basis and integer (static or dynamic)
    // values.
    if(!is_valid(layout.shape()) ||
       !is_valid(layout.stride()) ||
       !has_only_leaves_of_type<int_t, dyn_t, sb_t>(layout.stride()) ||
       any_leaf_is(layout.stride(), is_sb_with_ratio_value))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("complement input must be valid with integer or non-ratio scaled basis strides");
#else
        return cg_error_t{};
#endif
    }
    // The stride must be either static or rank-1 dynamic. (This comes from the
    // sort operation on stride values below - we cannot sort dynamic strides.)
    auto dyn_count = scalar_count(layout.stride(), /*dyn_only=*/true);
    auto scl_count = scalar_count(layout.stride(), /*dyn_only=*/false);
    if((dyn_count > 1) ||
       ((dyn_count == 1) && (scl_count != 1)))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("complement only supports static stride or rank-1 dynamic stride layouts");
#else
        return cg_error_t{};
#endif
    }

    // Furthermore, we require one of the following to be true for the stride:
    // - all leaf values are integers (dynamic or static)
    // - all leaf values are scaled basis values
    // - integers and scaled basis leaves are mixed, but all integer leaves are
    //   statically zero.
    if(has_leaf_with_type<sb_t>(layout.stride()))
    {
        if(!all_leaves(layout.stride(), [](const stride_t& d) {
               return std::holds_alternative<sb_t>(d) || (d == 0);
           }))
        {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
            throw std::runtime_error("complement input must not have mixed (scaled basis/nonzero integer) strides ");
#else
            return cg_error_t{};
#endif
        }
    }

    tuple_t  coprof   = coprofile(layout);
    shape_t  result_S = repeat_like<shape_t>(coprof, shape_vec_t{});
    stride_t result_D = repeat_like<stride_t>(coprof, 1);

    // We will only process stride values with int or scaled basis
    // types.
    using stride_leaf_t             = std::variant<int_t, dyn_t, sb_t>;
    using stride_leaf_vec_t         = std::vector<stride_leaf_t>;
    stride_leaf_vec_t stride_leaves = get_leaves_with_type<int_t, dyn_t, sb_t>(layout.stride());

    if(stride_leaves.empty())
    {
        return layout_t(cg_error_t{});
    }

    shape_t shape_f = flatten(layout.shape());

    if(stride_leaves.size() != rank(shape_f))
    {
        return layout_t{cg_error_t{}};
    }

    // Combine stride, shape, and prefix product into a single tuple.
    using str_s_t = std::tuple<stride_leaf_t, shape_t>;
    std::vector<str_s_t> str_s_vec;
    for(size_t i = 0; i < stride_leaves.size(); ++i)
    {
        str_s_vec.push_back(std::make_tuple(stride_leaves[i], shape_f[i]));
    }

    // Sort by stride. Note that we have checked above to make sure
    // that all strides have the same leaf type (i.e. either all integers
    // or all scaled basis), or that integers are statically zero if integers
    // and scaled basis values are mixed.
    std::sort(str_s_vec.begin(),
              str_s_vec.end(),
              [](const str_s_t& lhs, const str_s_t& rhs) {
                  detail::stride_lt_visitor vis;
                  return visit(vis, std::get<0>(lhs), std::get<0>(rhs));
              });

    using proj = detail::projector<int_t, dyn_t, sb_t>;
    for(const auto& [de, s] : str_s_vec)
    {
        auto  d        = proj::template proj<stride_t>(de);
        auto& result_s = proj::proj(result_S, de);
        auto& result_d = proj::proj(result_D, de);
        // We expect the single argument projection to return an integer.
        assert(holds_int_or_dynamic_int(d));
        if((d == 0) || (s == 1))
        {
            continue;
        }
        assert(!is_empty(result_d));
        // For the general case of dynamic strides, we cannot evaluate the
        // criteria for a non-injective layout (d < result_d.back(). However, we
        // are limiting inputs such that the flattened stride has a single value
        // (which is dynamic). As such, with a dynamic stride:
        // - this loop body executes only once
        // - result_d.back() will have a value of 1 during this single iteration
        // Therefore, the requirement on a dynamic stride is that its value must
        // not be less than 1. A zero stride value would result in a complement
        // of 0:0 using the calculations below.
        if(std::holds_alternative<int_t>(result_d.back()) &&
           std::holds_alternative<int_t>(d) &&
           (d.as_int() < result_d.back().as_int()))
        {
            // Non-injective layout in complement()
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
            throw std::runtime_error("complement input layout is non-injective");
#else
            return cg_error_t{};
#endif
        }
        result_s.append(scalar_div<shape_t>(d, result_d.back()));
        result_d.append(scalar_mul<stride_t>(d, s));
    }
    auto make_tile = [](const tuple_t& /*c*/,
                        const shape_t&  rs,
                        const stride_t& rd) -> tile_t {
        shape_t s = rs;
        if(is_empty(s))
        {
            s = 1;
        }
        else
        {
            s.append(1);
        }
        layout_t ly(s, rd);
        return tile_t{coalesce_z(ly)};
    };
    return tiler_to_layout(transform_leaf(make_tile, coprof, result_S, result_D));
}

template <class TDynTraits, class TExtend>
layout_t<TDynTraits> complement_extend(const layout_t<TDynTraits>& l, TExtend extend)
{
    using layout  = layout_t<TDynTraits>;
    using shape   = typename layout::shape_t;
    using stride  = typename layout::stride_t;
    using tuple_t = cute_int_tuple_t<TDynTraits>;
    using dyn_t   = typename TDynTraits::dynamic_int_t;

    // Take the complement of the input layout
    layout  c      = complement(l);
    tuple_t coprof = coprofile(l);
    // Extend the complement
    auto extend_complement = [](const tuple_t& /*inCoprof*/,
                                const shape&  shapeC,
                                const stride& strideC,
                                const shape&  shapeA,
                                const stride& strideA) -> layout {
        using sb_t  = typename find_scaled_basis_in_rec_var<stride>::value;
        using int_t = static_int_t;
        using proj  = detail::projector<int_t, dyn_t, sb_t>;
        if(is_empty(shapeC))
        {
            return layout(shapeA, strideA);
        }
        if(is_empty(strideC))
        {
            return layout(cg_error_t{});
        }
        assert(holds_leaf(strideC.back()));
        auto strideC_back_leaves_vec = get_leaves_with_type<int_t, dyn_t, sb_t>(strideC.back());
        if(strideC_back_leaves_vec.size() != 1)
        {
            return layout(cg_error_t{});
        }
        using stride_leaf_t         = std::variant<int_t, dyn_t, sb_t>;
        stride_leaf_t& last_strideC = strideC_back_leaves_vec[0];
        stride         sizeC        = proj::template proj<stride>(last_strideC);
        assert(holds_int_or_dynamic_int(sizeC));

        // sizeR = (size(shapeA) + sizeC - 1) / sizeC
        auto  shapeA_leaves = get_leaves_with_type<int_t, dyn_t>(shapeA);
        shape shapeR;
        get_vector(shapeR).reserve(shapeA_leaves.size());
        for(auto& s : shapeA_leaves)
        {
            // PyCuTe: shapeR.append((s + sizeC - 1) // sizeC)
            shapeR.append(scalar_ceil_div<shape>(s, sizeC));
            // PyCute: sizeC = (s + sizeC - 1) // s
            sizeC = scalar_ceil_div<stride>(sizeC, s);
        }
        shape newShapeC  = shapeC;
        newShapeC.back() = shapeR;
        // Choose the prefix product constructor so that the stride of the
        // created layout can be updated to match newShapeC.
        return coalesce(layout(newShapeC, strideC, prefix_product_tag{}));
    };
    auto make_layout_from_vec = [](const std::vector<layout>& vec) -> layout {
        return make_layout(vec);
    };
    return transform_apply_leaf(make_layout_from_vec,
                                extend_complement,
                                coprof,
                                c.shape(),
                                c.stride(),
                                extend,
                                make_basis_like<stride>(extend));
}

template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const layout_t<TDynTraits>& rhs)
{
    return detail::composition(lhs, rhs);
}

template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const cute_shape_t<TDynTraits>& rhs)
{
    return composition(lhs, shape_to_tile(rhs));
}

template <class TDynTraits>
auto composition(const layout_t<TDynTraits>& lhs, const cute_tile_t<TDynTraits>& rhs)
{
    return rhs.visit([&lhs](auto&& v) //
                     {
                         return detail::composition(lhs, std::forward<decltype(v)>(v));
                     });
}

template <class TDynTraits>
layout_t<TDynTraits> right_inverse(const layout_t<TDynTraits>& layout)
{
    using layout_t     = layout_t<TDynTraits>;
    using shape_t      = typename layout_t::shape_t;
    using shape_vec_t  = std::vector<shape_t>;
    using stride_t     = typename layout_t::stride_t;
    using stride_vec_t = std::vector<stride_t>;
    using tuple_t      = cute_int_tuple_t<TDynTraits>;
    using int_t        = typename layout_t::int_t;
    using dyn_t        = typename TDynTraits::dynamic_int_t;
    using sb_t         = scaled_basis_t<ratio, static_int_t, typename TDynTraits::dynamic_int_t>;

    // Arithmetic operations performed on strides when calculating the inverse
    // only currently support integers (static or dynamic) and scaled basis with
    // integer values. (Specifically, ratio values of scaled basis are not
    // supported.)
    auto is_sb_with_ratio_value = [](const stride_t& l) {
        return std::holds_alternative<sb_t>(l) &&
               std::holds_alternative<ratio>(std::get<sb_t>(l).value());
    };

    // Shape and stride must be static valid (no cg_error_t or dynamic values).
    // The stride must only have scaled basis and static integer values.
    if(!is_valid(layout.shape()) ||
       !is_static(layout.shape()) ||
       !is_valid(layout.stride()) ||
       !has_only_leaves_of_type<int_t, dyn_t, sb_t>(layout.stride()) ||
       any_leaf_is(layout.stride(), is_sb_with_ratio_value))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("right inverse input layout must be valid with static shapes and only integer or non-ratio scaled basis strides");
#else
        return cg_error_t{};
#endif
    }

    // Furthermore, we require one of the following to be true for the stride:
    // - all leaf values are integers
    // - all leaf values are scaled basis values
    // - integers and scaled basis leaves are mixed, but all integer leaves are
    //   statically zero.
    if(has_leaf_with_type<sb_t>(layout.stride()))
    {
        if(!all_leaves(layout.stride(), [](const stride_t& d) {
               return std::holds_alternative<sb_t>(d) || (d == 0);
           }))
        {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
            throw std::runtime_error("right inverse mixed (int/scaled basis) strides must have static 0 integer values");
#else
            return cg_error_t{};
#endif
        }
    }

    tuple_t  coprof   = coprofile(layout);
    shape_t  result_S = repeat_like<shape_t>(coprof, shape_vec_t{});
    stride_t result_D = repeat_like<stride_t>(coprof, stride_vec_t{});
    stride_t curr_D   = repeat_like<stride_t>(coprof, 1);

    shape_t  flat_s = flatten(layout.shape());
    stride_t flat_d = flatten(layout.stride());

    // We handle dynamic stride values in the right_inverse() function by
    // replacing them with static 0 values. Stride zero modes do not contribute
    // to the layout mapping, and can only truncate the right inverse, so this
    // is a convenient way to emulate truncating on finding a dynamic mode.
    for(auto& d : flat_d)
    {
        if(holds_dynamic_int(d))
        {
            d = 0;
        }
    }

    detail::coalesce_(flat_s, flat_d);

    shape_t pp_flat_s = prefix_product(flat_s);

    // We will only process stride values with int or scaled basis
    // types. Dynamic values will not factor in to the right
    // inverse.
    using stride_leaf_t             = std::variant<int_t, dyn_t, sb_t>;
    using stride_leaf_vec_t         = std::vector<stride_leaf_t>;
    stride_leaf_vec_t flat_d_leaves = get_leaves_with_type<int_t, dyn_t, sb_t>(flat_d);

    if(flat_d_leaves.empty())
    {
        return layout_t(shape_t(1), stride_t(0));
    }

    // Combine stride, shape, and prefix product into a single tuple.
    using str_s_pps_t = std::tuple<stride_leaf_t,
                                   shape_t,
                                   shape_t>;
    std::vector<str_s_pps_t> str_s_pps_vec;
    for(size_t i = 0; i < flat_d_leaves.size(); ++i)
    {
        str_s_pps_vec.push_back(std::make_tuple(flat_d_leaves[i],
                                                flat_s[i],
                                                pp_flat_s[i]));
    }
    // Sort by stride. Note that we have checked above to make sure
    // that all strides have the same leaf type (i.e. either all integers
    // or all scaled basis), or that integers are statically zero if integers
    // and scaled basis values are mixed.
    std::sort(str_s_pps_vec.begin(),
              str_s_pps_vec.end(),
              [](const str_s_pps_t& lhs, const str_s_pps_t& rhs) {
                  detail::stride_lt_visitor vis;
                  return visit(vis, std::get<0>(lhs), std::get<0>(rhs));
              });
    using proj = detail::projector<int_t, dyn_t, sb_t>;
    for(const auto& [de, s, pps] : str_s_pps_vec)
    {
        auto  d        = proj::template proj<stride_t>(de);
        auto& result_s = proj::proj(result_S, de);
        auto& result_d = proj::proj(result_D, de);
        auto& curr_d   = proj::proj(curr_D, de);

        if((0 == d) || (1 == s))
        {
            continue;
        }
        if(holds_int(curr_d) &&
           holds_int(d) &&
           (curr_d.as_int() != d.as_int()))
        {
            continue;
        }

        result_s.append(s);
        assert(holds_int_or_dynamic_int(pps));
        if(holds_dynamic_int(pps))
        {
            result_d.append(get_dynamic_int(pps));
        }
        else
        {
            result_d.append(pps.as_int());
        }
        curr_d = scalar_mul<stride_t>(s, d);
    }
    // Replace empty values. (This is done by the coalesce() function in
    // pycute, but as this is currently the only place these degenerate
    // vectors appear, we do it here for now.)
    detail::replace_empty_vector_with(result_S, 1);
    detail::replace_empty_vector_with(result_D, 0);
    return coalesce(layout_t(std::move(result_S), std::move(result_D)), coprof);
}

template <class TDynTraits>
layout_t<TDynTraits> left_inverse(const layout_t<TDynTraits>& layout)
{
    using layout_t = layout_t<TDynTraits>;
    using shape_t  = typename layout_t::shape_t;
    using stride_t = typename layout_t::stride_t;
    using tuple_t  = cute_int_tuple_t<TDynTraits>;
    using int_t    = typename layout_t::int_t;
    using sb_t     = scaled_basis_t<ratio, static_int_t, typename TDynTraits::dynamic_int_t>;
    using dyn_t    = typename TDynTraits::dynamic_int_t;

    // Arithmetic operations performed on strides when calculating the inverse
    // only currently support integers and scaled basis with integer values.
    // (Specifically, ratio values of scaled basis are not supported.)
    auto is_sb_with_ratio_value = [](const stride_t& l) {
        return std::holds_alternative<sb_t>(l) &&
               std::holds_alternative<ratio>(std::get<sb_t>(l).value());
    };

    // Shape and stride must be static valid (no cg_error_t or dynamic values).
    // The stride must only have scaled basis and static integer values.
    if(!is_valid(layout.shape()) ||
       !is_static(layout.shape()) ||
       !is_valid(layout.stride()) ||
       !has_only_leaves_of_type<int_t, dyn_t, sb_t>(layout.stride()) ||
       any_leaf_is(layout.stride(), is_sb_with_ratio_value))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("left inverse mixed (int/scaled basis) strides must have static 0 integer values");
#else
        return cg_error_t{};
#endif
    }
    // The stride must be either static or rank-1 dynamic. (This comes from the
    // sort operation on stride values below - we cannot sort dynamic strides.)
    auto dyn_count = scalar_count(layout.stride(), /*dyn_only=*/true);
    auto scl_count = scalar_count(layout.stride(), /*dyn_only=*/false);
    if((dyn_count > 1) ||
       ((dyn_count == 1) && (scl_count != 1)))
    {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        throw std::runtime_error("left inverse only supports static stride or rank-1 dynamic stride layouts");
#else
        return cg_error_t{};
#endif
    }

    // Furthermore, we require one of the following to be true for the stride:
    // - all leaf values are integers
    // - all leaf values are scaled basis values
    // - integers and scaled basis leaves are mixed, but all integer leaves are
    //   statically zero.
    if(has_leaf_with_type<sb_t>(layout.stride()))
    {
        if(!all_leaves(layout.stride(), [](const stride_t& d) {
               return std::holds_alternative<sb_t>(d) || (d == 0);
           }))
        {
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
            throw std::runtime_error("left inverse mixed (int/scaled basis) strides must have static 0 integer values");
#else
            return cg_error_t{};
#endif
        }
    }

    tuple_t  coprof   = coprofile(layout);
    shape_t  result_S = repeat_like<shape_t>(coprof, 1);
    stride_t result_D = repeat_like<stride_t>(coprof, 0);
    shape_t  curr_S   = repeat_like<shape_t>(coprof, 1);

    shape_t  flat_s = flatten(layout.shape());
    stride_t flat_d = flatten(layout.stride());
    detail::coalesce_(flat_s, flat_d);

    shape_t pp_flat_s = prefix_product(flat_s);

    using stride_leaf_t             = std::variant<int_t, dyn_t, sb_t>;
    using stride_leaf_vec_t         = std::vector<stride_leaf_t>;
    stride_leaf_vec_t flat_d_leaves = get_leaves_with_type<int_t, dyn_t, sb_t>(flat_d);

    if(flat_d_leaves.empty())
    {
        return layout_t(shape_t(1), stride_t(0));
    }
    assert(flat_d_leaves.size() == rank(flat_d));

    // Combine stride, shape, and prefix product into a single tuple.
    using str_s_pps_t = std::tuple<stride_leaf_t,
                                   shape_t,
                                   shape_t>;
    std::vector<str_s_pps_t> str_s_pps_vec;
    for(size_t i = 0; i < flat_d_leaves.size(); ++i)
    {
        str_s_pps_vec.push_back(std::make_tuple(flat_d_leaves[i],
                                                flat_s[i],
                                                pp_flat_s[i]));
    }
    // Sort by stride. Note that we have checked above to make sure
    // that all strides have the same leaf type (i.e. either all integers
    // or all scaled basis), or that integers are statically zero if integers
    // and scaled basis values are mixed.
    std::sort(str_s_pps_vec.begin(),
              str_s_pps_vec.end(),
              [](const str_s_pps_t& lhs, const str_s_pps_t& rhs) {
                  detail::stride_lt_visitor vis;
                  return visit(vis, std::get<0>(lhs), std::get<0>(rhs));
              });
    using proj = detail::projector<int_t, dyn_t, sb_t>;
    for(const auto& [de, s, pps] : str_s_pps_vec)
    {
        auto  d        = proj::template proj<stride_t>(de);
        auto& result_s = proj::proj(result_S, de);
        auto& result_d = proj::proj(result_D, de);
        auto& curr_s   = proj::proj(curr_S, de);
        if((0 == d) || (1 == s))
        {
            continue;
        }
        // Resolve properties of d % curr_s without actually generating any
        // code. If the modulo result cannot be statically verified to be
        // zero we fail the operation.
        shape_t d_mod_s = scalar_mod<shape_t>(without_codegen(d),
                                              without_codegen(curr_s));
        if(d_mod_s != 0)
        {
            // Non-injective layout in left_inverse()
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
            throw std::runtime_error("left inverse input layout is non-injective");
#else
            return cg_error_t{};
#endif
        }
        result_s.back() = scalar_div<shape_t>(d, curr_s);
        curr_s          = scalar_mul<shape_t>(curr_s, result_s.back());
        result_s.append(s);
        result_d.append(rec_var_cast<stride_t>(pps));
    }
    return coalesce_z(layout_t(std::move(result_S), std::move(result_D)), coprof);
}

template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b)
{
    return detail::product_divide(a, b, detail::divide_op{}, false /*zip*/);
}

template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>&    a,
                    const cute_tile_t<TDynTraits>& b)
{
    return detail::product_divide(a, b, detail::divide_op{}, false /*zip*/);
}

template <class TDynTraits>
auto logical_divide(const layout_t<TDynTraits>&     target,
                    const cute_shape_t<TDynTraits>& tiler)
{
    return detail::product_divide(
        target, shape_to_tile(tiler), detail::divide_op{}, false /*zip*/);
}

template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const layout_t<TDynTraits>& target,
                                  const layout_t<TDynTraits>& tiler)
{
    return std::move(complement(tiler, size(target)).shape());
}

template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const cute_shape_t<TDynTraits>& target,
                                  const layout_t<TDynTraits>&     tiler)
{
    return std::move(complement(tiler, size(target)).shape());
}

template <class TDynTraits>
cute_shape_t<TDynTraits> ceil_div(const cute_shape_t<TDynTraits>& target,
                                  const cute_tile_t<TDynTraits>&  tiler)
{
    if(holds_vector(target) && holds_vector(tiler))
    {
        // tuple/tuple
        if(rank(target) < rank(tiler)) return cg_error_t{};
        cute_shape_t<TDynTraits> res = target;
        // tiler[i] for i >= rank(tiler) is considered as `1` (short-cut as nop)
        for(size_t i = 0; i < std::min(rank(target), rank(tiler)); i++)
        {
            res[i] = ceil_div(target[i], tiler[i]);
        }
        return res;
    }
    if(holds_leaf(target) && holds_vector(tiler))
    {
        // scalar/tuple -> forward to the generic overload rec_var/rec_var
        return ceil_div(target, product(extract_shape_from_tile(tiler)));
    }
    if(std::holds_alternative<layout_t<TDynTraits>>(tiler))
    {
        // anything/layout -> forward to the overload shape/layout
        return ceil_div(target, std::get<layout_t<TDynTraits>>(tiler));
    }
    // Anything else is an error
    return cg_error_t{};
}

template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const layout_t<TDynTraits>& tiler)
{
    return logical_divide(target, tiler);
}

template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const cute_tile_t<TDynTraits>& tiler)
{
    return detail::product_divide(target, tiler, detail::divide_op{}, true /*zip*/);
}

template <class TDynTraits>
auto zipped_divide(const layout_t<TDynTraits>& target, const cute_shape_t<TDynTraits>& tiler)
{
    return zipped_divide(target, shape_to_tile(tiler));
}

template <class TDynTraits, class TTiler>
layout_t<TDynTraits> tiled_divide(const layout_t<TDynTraits>& target, const TTiler& tiler)
{
    using lay_t = layout_t<TDynTraits>;
    using coo_t = cute_coord_t<TDynTraits>;
    lay_t zd    = zipped_divide(target, tiler);
    coo_t c     = (depth(zd.shape()[1]) == 0) ? _ : repeat<coo_t>(rank(zd.shape()[1]), _);
    return slice(coo_t(_, c), zd);
}

template <class TDynTraits, class TTiler>
layout_t<TDynTraits> flat_divide(const layout_t<TDynTraits>& target, const TTiler& tiler)
{
    using lay_t = layout_t<TDynTraits>;
    using coo_t = cute_coord_t<TDynTraits>;
    lay_t zd    = zipped_divide(target, tiler);
    coo_t c0    = (depth(zd.shape()[0]) == 0) ? _ : repeat<coo_t>(rank(zd.shape()[0]), _);
    coo_t c1    = (depth(zd.shape()[1]) == 0) ? _ : repeat<coo_t>(rank(zd.shape()[1]), _);
    return slice(coo_t(c0, c1), zd);
}

template <class TDynTraits>
auto logical_product(const layout_t<TDynTraits>& a, const layout_t<TDynTraits>& b)
{
    return detail::product_divide(a, b, detail::product_op{}, false /*zip*/);
}

template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const layout_t<TDynTraits>& tiler)
{
    return logical_product(block, tiler);
}

template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const cute_tile_t<TDynTraits>& tiler)
{
    return detail::product_divide(block, tiler, detail::product_op{}, true /*zip*/);
}

template <class TDynTraits>
auto zipped_product(const layout_t<TDynTraits>& block, const cute_shape_t<TDynTraits>& tiler)
{
    return zipped_product(block, shape_to_tile(tiler));
}

template <class TDynTraits, class TTiler>
auto tiled_product(const layout_t<TDynTraits>& block, const TTiler& tiler)
{
    using lay_t = layout_t<TDynTraits>;
    using coo_t = cute_coord_t<TDynTraits>;
    lay_t zp    = zipped_product(block, tiler);
    coo_t c     = (depth(zp.shape()[1]) == 0) ? _ : repeat<coo_t>(rank(zp.shape()[1]), _);
    return slice(coo_t(_, c), zp);
}

template <class TDynTraits, class TTiler>
auto flat_product(const layout_t<TDynTraits>& block, const TTiler& tiler)
{
    using lay_t = layout_t<TDynTraits>;
    using coo_t = cute_coord_t<TDynTraits>;
    lay_t zp    = zipped_product(block, tiler);
    coo_t c0    = (depth(zp.shape()[0]) == 0) ? _ : repeat<coo_t>(rank(zp.shape()[0]), _);
    coo_t c1    = (depth(zp.shape()[1]) == 0) ? _ : repeat<coo_t>(rank(zp.shape()[1]), _);
    return slice(coo_t(c0, c1), zp);
}

template <class TDynTraits>
auto blocked_product(const layout_t<TDynTraits>& a,
                     const layout_t<TDynTraits>& b)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename lay_t::shape_t;
    size_t ra   = rank(a);
    size_t rb   = rank(b);
    size_t r    = std::max(ra, rb);
    lay_t  lp   = (ra == rb) ?
                      logical_product(a, b) :
                      logical_product(append_to_rank_N(r, a, lay_t(sha_t(1))),
                                   append_to_rank_N(r, b, lay_t(sha_t(1))));
    assert(rank(lp) == 2);
    auto res = lay_t(zip(lp.shape()), zip(lp.stride()));
    return res;
}

template <class TDynTraits>
auto raked_product(const layout_t<TDynTraits>& a,
                   const layout_t<TDynTraits>& b)
{
    using lay_t = layout_t<TDynTraits>;
    using sha_t = typename lay_t::shape_t;
    size_t ra   = rank(a);
    size_t rb   = rank(b);
    size_t r    = std::max(ra, rb);
    lay_t  lp   = (ra == rb) ?
                      logical_product(a, b) :
                      logical_product(append_to_rank_N(r, a, lay_t(sha_t(1))),
                                   append_to_rank_N(r, b, lay_t(sha_t(1))));
    assert(rank(lp) == 2);
    auto res = lay_t(zip(lp.shape()[1], lp.shape()[0]), zip(lp.stride()[1], lp.stride()[0]));
    return coalesce(res, repeat<sha_t>(r, 1));
}

//
// Others
//

template <class TDynTraits>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   gen_col_major)
{
    using tup_t = cute_int_tuple_t<TDynTraits>;
    tup_t order = typename tup_t::vector_t(rank(trg_shape));
    std::iota(order.begin(), order.end(), 0);
    return detail::tile_to_shape(block, trg_shape, order);
}

template <class TDynTraits>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   gen_row_major)
{
    using tup_t = cute_int_tuple_t<TDynTraits>;
    tup_t order = typename tup_t::vector_t(rank(trg_shape));
    std::iota(std::reverse_iterator(order.end()), std::reverse_iterator(order.begin()), 0);
    return detail::tile_to_shape(block, trg_shape, order);
}

template <class TDynTraits, class TRecVar, std::enable_if_t<is_rec_var<TRecVar>::value, bool>>
layout_t<TDynTraits> tile_to_shape(const layout_t<TDynTraits>&     block,
                                   const cute_shape_t<TDynTraits>& trg_shape,
                                   const TRecVar&                  order)
{
    return detail::tile_to_shape(block, trg_shape, order);
}

template <class TDynTraits>
layout_t<TDynTraits> upcast(typename layout_t<TDynTraits>::int_t N, const layout_t<TDynTraits>& layout)
{
    using lay_t        = layout_t<TDynTraits>;
    using sha_t        = typename lay_t::shape_t;
    using str_t        = typename lay_t::stride_t;
    const auto& shape  = layout.shape();
    const auto& stride = layout.stride();

    if((N <= 0) || !is_int_or_dynamic_int_only(stride))
    {
        // Return error if the cast factor is <=0, or if the stride has leaves
        // other than int or dynamic int. (We don't currently handle, for
        // example, scaled basis.)
        return cg_error_t{};
    }
    if(holds_vector(shape))
    { // tuple stride
        return transform_leaf([&](const auto& s, const auto& d) { lay_t l(s, d); return upcast(N, l); }, shape, stride);
    }
    else if(holds_dynamic_int(stride))
    { // dynamic stride
        return lay_t(shape, shape_div(stride, str_t(N)));
    }
    else if(stride == 0)
    { // static-0 stride
        return lay_t{shape, stride};
    }
    else
    { // static stride
        assert(holds_int(stride));
        static_int_t stride_signum = (stride.as_int() < 0) ? -1 : 1;
        return lay_t{ceil_div(shape, sha_t{ceil_div(N, std::abs(stride.as_int()))}),
                     str_t{stride_signum * ceil_div(std::abs(stride.as_int()), N)}};
    }
}

template <class TDynTraits>
layout_t<TDynTraits> downcast(typename layout_t<TDynTraits>::int_t N, const layout_t<TDynTraits>& layout)
{
    using lay_t        = layout_t<TDynTraits>;
    using sha_t        = typename lay_t::shape_t;
    using str_t        = typename lay_t::stride_t;
    const auto& shape  = layout.shape();
    const auto& stride = layout.stride();

    if((N <= 0) || !is_int_or_dynamic_int_only(stride))
    {
        // Return error if the cast factor is <=0, or if the stride has leaves
        // other than int or dynamic int. (We don't currently handle, for
        // example, scaled basis.)
        return cg_error_t{};
    }
    if(holds_vector(shape))
    {
        return transform_leaf([&](const auto& s, const auto& d) { lay_t l(s, d); return downcast(N, l); }, shape, stride);
    }
    else if((stride == 1) || (stride == -1))
    {
        return lay_t{scalar_mul<sha_t>(shape, sha_t{N}), stride};
    }
    else
    {
        return lay_t{shape, scalar_mul<str_t>(stride, str_t{N})};
    }
}

template <class TLayout>
TLayout recast(int new_type_bits, int old_type_bits, const TLayout& layout)
{
    if(new_type_bits == old_type_bits)
    {
        return layout;
    }
    else if(new_type_bits % old_type_bits == 0)
    {
        return upcast(new_type_bits / old_type_bits, layout);
    }
    else if(old_type_bits % new_type_bits == 0)
    {
        return downcast(old_type_bits / new_type_bits, layout);
    }

    // Handle cases when old/new bits are individable.
    int gcd            = std::gcd(new_type_bits, old_type_bits);
    int new_type_bits_ = new_type_bits / gcd;
    int old_type_bits_ = old_type_bits / gcd;
    return downcast(old_type_bits_, upcast(new_type_bits_, layout));
}

template <class OldType, class NewType, class TLayout>
TLayout recast(const TLayout& layout)
{
    return recast(sizeof(NewType), sizeof(OldType), layout);
}

template <class TDynTraits>
inline typename layout_t<TDynTraits>::int_t max_alignment(const layout_t<TDynTraits>& layout)
{
    if(has_scaled_basis(layout.stride()))
        return 1;

    using shape_t    = typename layout_t<TDynTraits>::shape_t;
    using stride_t   = typename layout_t<TDynTraits>::stride_t;
    auto flat_layout = coalesce(layout);

    shape_t static_shape;
    for(const auto& s : flat_layout.shape())
    {
        // Dynamic shapes contribute no alignment; static shapes contribute |value|.
        if(holds_dynamic_int(s))
            static_shape.append(1);
        else
            static_shape.append(std::abs(s.as_int()));
    }
    // Warn: for some operations, negative strides should be converted
    // to normal strides or else max_alignment value is 1
    stride_t static_stride;
    for(const auto& d : flat_layout.stride())
    {
        if(holds_dynamic_int(d))
            static_stride.append(0);
        else
            static_stride.append(d);
    }
    auto filter_layout = layout_t<TDynTraits>(static_shape, static_stride);
    auto permuted      = logical_divide(filter_layout, right_inverse(filter_layout));
    /// permuted layout contains (vect, rest_v):(1, rest_stride)
    /// alignment is considered as common divisor of vect size and stride on mode-1
    ///
    ///   E.g. max_alignment((8,16):(1,4)) ==> 4
    ///        max_alignment((8,16):(1,6)) ==> 2
    ///        max_alignment((8,16):(1,8)) ==> 8
    ///
    return std::gcd(size(permuted.shape()[0]).as_int(), gcd(permuted.stride()[1]));
}

template <class TStride,
          class TDynamicTraits>
auto make_basis_like(const layout_t<TDynamicTraits>& ly)
{
    // pycute behavior:
    // >>> make_basis_like(Layout(8,1))
    // 1
    return TStride{1};
}

template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const cute_shape_t<TDynTraits>&  sh,
                                     const cute_stride_t<TDynTraits>& e)
{
    using layout = layout_t<TDynTraits>;
    using shape  = typename layout::shape_t;
    using stride = typename layout::stride_t;

    if(holds_int_or_dynamic_int(sh))
    {
        return layout_t(sh, e);
    }
    if(!holds_vector(sh))
    {
        return layout{cg_error_t{}};
    }
    auto f = [](const shape& sh, const stride& str) -> layout {
        return tiler_to_layout(sh, str);
    };
    auto g = [](const std::vector<layout>& vec) -> layout {
        return make_layout(vec);
    };
    return transform_apply_leaf(g, f, sh, make_basis_like<stride>(sh));
}

template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const layout_t<TDynTraits>&      ly,
                                     const cute_stride_t<TDynTraits>& e)
{
    using layout = layout_t<TDynTraits>;
    using stride = typename layout::stride_t;

    auto scale_stride = [&](const stride& d) {
        return scalar_mul<stride>(d, e);
    };
    return layout(ly.shape(), transform_leaf(scale_stride, ly.stride()));
}

template <class TDynTraits>
layout_t<TDynTraits> tiler_to_layout(const cute_tile_t<TDynTraits>&   t,
                                     const cute_stride_t<TDynTraits>& e)
{
    using layout = layout_t<TDynTraits>;
    using stride = cute_stride_t<TDynTraits>;
    using tile   = cute_tile_t<TDynTraits>;

    // tile type can also hold underscores - we return an error for that case.
    if(!holds_vector(t) && !std::holds_alternative<layout>(t))
    {
        return layout{cg_error_t{}};
    }
    if(std::holds_alternative<layout>(t))
    {
        return tiler_to_layout(std::get<layout>(t), e);
    }
    auto f = [](const tile& t_, const stride& str) -> layout {
        return tiler_to_layout(t_, str);
    };
    auto g = [](const std::vector<layout>& vec) -> layout {
        return make_layout(vec);
    };
    return transform_apply_leaf(g, f, t, make_basis_like<stride>(t));
}

} // namespace cutegen
#endif // CUTEGEN_LAYOUT_HPP_INCLUDED_
