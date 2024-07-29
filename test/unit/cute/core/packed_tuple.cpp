/***************************************************************************************************
 * Copyright (c) 2024 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass_unit_test.h"

#include <cutlass/trace.h>

#include <cassert>
#include <cstdint>

#include <tuple>
#include <cute/container/tuple.hpp>
#include <cute/container/packed_tuple.hpp>
#include <cute/algorithm/tuple_algorithms.hpp>
#include <cute/tensor.hpp>

namespace pt_test {

template <class T>
struct Nonempty {
  T datum;

  Nonempty(T const& t) : datum{t} {}

  friend bool operator==(Nonempty<T> const& lhs, Nonempty<T> const& rhs) {
    return lhs.datum == rhs.datum;
  }

  friend bool operator!=(Nonempty<T> const& lhs, Nonempty<T> const& rhs) {
    return !(lhs == rhs);
  }
};

template <int V>
struct Empty {
  template <int W>
  friend bool operator==(Empty<V> const&, Empty<W> const&) {
    return V == W;
  }

  template <int W>
  friend bool operator!=(Empty<V> const& lhs, Empty<W> const& rhs) {
    return !(lhs == rhs);
  }
};

// std::tuple
static_assert(cute::is_standard_layout_v<std::tuple<>>); // it happens to be
static_assert(cute::is_standard_layout_v<std::tuple<int>>); // it happens to be
static_assert(cute::is_standard_layout_v<std::tuple<double>>); // it happens to be
static_assert(not cute::is_standard_layout_v<std::tuple<int, double>>); // it's not

#if ! defined(CUTLASS_USE_PACKED_TUPLE)
// cute::tuple
static_assert(cute::is_standard_layout_v<cute::tuple<>>); // it happens to be
static_assert(cute::is_standard_layout_v<cute::tuple<int>>); // it happens to be
static_assert(cute::is_standard_layout_v<cute::tuple<double>>); // it happens to be
static_assert(not cute::is_standard_layout_v<cute::tuple<int, double>>); // it's not
#endif // CUTLASS_USE_PACKED_TUPLE

// cute::packed_tuple
static_assert(cute::is_standard_layout_v<cute::packed_tuple<>>);
static_assert(cute::is_standard_layout_v<cute::packed_tuple<int>>);
static_assert(cute::is_standard_layout_v<cute::packed_tuple<double>>);
static_assert(cute::is_standard_layout_v<cute::packed_tuple<int, double>>);  // it is
static_assert(cute::is_standard_layout_v<cute::packed_tuple<int, int, int, int>>);  // it is
static_assert(cute::is_standard_layout_v<cute::packed_tuple<int, cute::packed_tuple<int, int>, int>>);  // it is
static_assert(cute::is_standard_layout_v<cute::packed_tuple<int, cute::packed_tuple<Empty<0>, Empty<0>>, int>>);  // it is

//////////////////////////////////////////////////////////////////////
// packed_tuple test starts here
//////////////////////////////////////////////////////////////////////

template <
  class ExpectedPackedType,
  size_t ExpectedPackedSize,
  class ... Args>
constexpr void
test_packed_type_alias([[maybe_unused]] ExpectedPackedType packed, std::tuple<Args...> unpacked)
{
  using cute::packed_tuple;

  if constexpr ((cute::is_standard_layout_v<Args> && ...)) {
    static_assert(cute::is_standard_layout_v<packed_tuple<Args...>>);
  }

  if constexpr ((cute::is_empty_v<Args> && ...)) {
    static_assert(cute::is_empty_v<packed_tuple<Args...>>);
  }

  static_assert(cute::tuple_size_v<packed_tuple<Args...>> == sizeof...(Args));

  auto test_element = [unpacked] (auto index) {
    static_assert(cute::is_same_v<
      std::tuple_element_t<index, packed_tuple<Args...>>,
      std::tuple_element_t<index, std::tuple<Args...>>
    >);

    packed_tuple<Args...> sl = cute::apply(unpacked, [](auto... a){ return cute::make_packed_tuple(a...); });
    EXPECT_EQ(std::get<index>(unpacked), cute::get<index>(sl));
  };
  cute::for_each(std::make_index_sequence<sizeof...(Args)>(), test_element);
}

void test_packed_type_aliases() {
  using cute::packed_tuple;
  test_packed_type_alias<packed_tuple<>, 0>({}, {});

  test_packed_type_alias<packed_tuple<int>, 1, int>({7}, {7});
  test_packed_type_alias<packed_tuple<double>, 1, double>({1.5}, {1.5});

  // Make sure that class types are handled the same as scalar types
  test_packed_type_alias<packed_tuple<Nonempty<int>>, 1, Nonempty<int>>(
    {Nonempty{7}}, {Nonempty{7}});
  test_packed_type_alias<packed_tuple<Nonempty<double>>, 1, Nonempty<double>>(
    {Nonempty{1.5}}, {Nonempty{1.5}});

  test_packed_type_alias<packed_tuple<>, 0, Empty<0>>({}, {});
  test_packed_type_alias<packed_tuple<>, 0, Empty<0>, Empty<1>>(
    {}, {Empty<0>{}, Empty<1>{}});
  test_packed_type_alias<packed_tuple<>, 0, Empty<0>, Empty<1>, Empty<2>>(
    {}, {Empty<0>{}, Empty<1>{}, Empty<2>{}});

  test_packed_type_alias<packed_tuple<int>, 1, Empty<0>, int>(
    {7}, {Empty<0>{}, 7});
  test_packed_type_alias<packed_tuple<int>, 1, int, Empty<0>>(
    {7}, {7, Empty<0>{}});

  test_packed_type_alias<packed_tuple<int>, 1, int, Empty<0>, Empty<1>>(
    {7}, {7, Empty<0>{}, Empty<1>{}});
  test_packed_type_alias<packed_tuple<int>, 1, Empty<0>, int, Empty<1>>(
    {7}, {Empty<0>{}, 7, Empty<1>{}});
  test_packed_type_alias<packed_tuple<int>, 1, Empty<0>, Empty<1>, int>(
    {7}, {Empty<0>{}, Empty<1>{}, 7});

  test_packed_type_alias<packed_tuple<int, double>, 2, int, double, Empty<0>>(
    {7, 1.5}, {7, 1.5, Empty<0>{}});
  test_packed_type_alias<packed_tuple<int, double>, 2, int, Empty<0>, double>(
    {7, 1.5}, {7, Empty<0>{}, 1.5});
  test_packed_type_alias<packed_tuple<int, double>, 2, int, double, Empty<0>>(
    {7, 1.5}, {7, 1.5, Empty<0>{}});

  test_packed_type_alias<packed_tuple<int, double>, 2, int, double, Empty<0>, Empty<1>>(
    {7, 1.5}, {7, 1.5, Empty<0>{}, Empty<1>{}});
  test_packed_type_alias<packed_tuple<int, double>, 2, int, Empty<0>, double, Empty<1>>(
    {7, 1.5}, {7, Empty<0>{}, 1.5, Empty<1>{}});
  test_packed_type_alias<packed_tuple<int, double>, 2, int, Empty<0>, Empty<1>, double>(
    {7, 1.5}, {7, Empty<0>{}, Empty<1>{}, 1.5});
  test_packed_type_alias<packed_tuple<int, double>, 2, Empty<0>, int, Empty<1>, double>(
    {7, 1.5}, {Empty<0>{}, 7, Empty<1>{}, 1.5});
  test_packed_type_alias<packed_tuple<int, double>, 2, Empty<0>, Empty<1>, int, double>(
    {7, 1.5}, {Empty<0>{}, Empty<1>{}, 7, 1.5});

  test_packed_type_alias<packed_tuple<int, double, float>, 3, Empty<0>, int, double, float>(
    {7, 1.5, 2.5f}, {Empty<0>{}, 7, 1.5, 2.5f});
  test_packed_type_alias<packed_tuple<int, double, float>, 3, int, Empty<0>, double, float>(
    {7, 1.5, 2.5f}, {7, Empty<0>{}, 1.5, 2.5f});
  test_packed_type_alias<packed_tuple<int, double, float>, 3, int, double, Empty<0>, float>(
    {7, 1.5, 2.5f}, {7, 1.5, Empty<0>{}, 2.5f});
  test_packed_type_alias<packed_tuple<int, double, float>, 3, int, double, float, Empty<0>>(
    {7, 1.5, 2.5f}, {7, 1.5, 2.5f, Empty<0>{}});
}

template <class Tuple, size_t Which, class ExpectedElementType>
constexpr bool test_tuple_element() {
  return cute::is_same_v<std::tuple_element_t<Which, Tuple>, ExpectedElementType>;
}

void test_tuple_elements() {
  using cute::packed_tuple;

  static_assert(test_tuple_element<std::tuple<Empty<0>>, 0, Empty<0>>());
  static_assert(test_tuple_element<packed_tuple<Empty<0>>, 0, Empty<0>>());
}

// A default-constructible type.
template <size_t Value>
struct DefaultConstructible {};

void test_default_constructibility() {
  using cute::packed_tuple;
  {
    [[maybe_unused]] packed_tuple<> t_p_0;
    [[maybe_unused]] packed_tuple<DefaultConstructible<0>> t_p_1;
    [[maybe_unused]] packed_tuple<DefaultConstructible<0>, DefaultConstructible<1>> t_p_2;
    [[maybe_unused]] packed_tuple<DefaultConstructible<0>, int, DefaultConstructible<1>> t_p_3;
  }
}

void test_sizes_and_not_storing_empty_types() {
  using cute::packed_tuple;

  [[maybe_unused]] packed_tuple<
    int,
    pt_test::Empty<0>,
    double
  > pt{42, pt_test::Empty<0>{}, 1.5};
  static_assert(cute::is_standard_layout_v<decltype(pt)>);
  // packed_result_type must only store the packed tuple,
  // and not the integer_sequence(s) used to access it.
  // The latter can be represented entirely at compile time as types.
  struct { int i; double j; } IntDouble;
  static_assert(sizeof(pt) == sizeof(IntDouble));

  EXPECT_EQ(cute::get<0>(pt), 42);
  EXPECT_EQ(cute::get<1>(pt), pt_test::Empty<0>{});
  EXPECT_EQ(cute::get<2>(pt), 1.5);
  packed_tuple<
    pt_test::Empty<0>,
    pt_test::Empty<1>,
    packed_tuple<
      pt_test::Empty<0>,
      pt_test::Empty<1>,
      packed_tuple<pt_test::Empty<0>, packed_tuple<>>
    >
  > pt_empty{};
  static_assert(cute::is_empty_v<decltype(pt_empty)>);
  static_assert(cute::is_standard_layout_v<decltype(pt_empty)>);
  static_assert(sizeof(pt_empty) == 1);

  // Template arguments must be default constructible,
  // and packed_tuple itself needs a default constructor.
  [[maybe_unused]] packed_tuple<
    packed_tuple<int, pt_test::Empty<2>>,
    double,
    pt_test::Empty<3>> pt2;
  static_assert(cute::is_standard_layout_v<decltype(pt2)>);

  // cute::packed_tuple, like the original cute::tuple, does not
  // promise to have working CTAD (constructor template argument
  // deduction).
  [[maybe_unused]] packed_tuple<
    packed_tuple<int, pt_test::Empty<0>>,
    pt_test::Empty<1>
  > pt3{
    packed_tuple<int, pt_test::Empty<0>>{42, pt_test::Empty<0>{}},
    pt_test::Empty<1>{}
  };
  static_assert(cute::is_standard_layout_v<decltype(pt3)>);
  static_assert(cute::is_same_v<
    cute::tuple_element_t<0, decltype(pt3)>,
    packed_tuple<int, pt_test::Empty<0>>>);
  static_assert(cute::is_same_v<
    cute::tuple_element_t<1, decltype(pt3)>,
    pt_test::Empty<1>>);
  static_assert(cute::tuple_size_v<cute::tuple_element_t<0, decltype(pt3)>> == 2u);

  packed_tuple<int, pt_test::Empty<0>> pt3_0 = cute::get<0>(pt3);
  auto pt3_0_1 = cute::get<1>(pt3_0);
  static_assert(cute::is_same_v<decltype(pt3_0_1), pt_test::Empty<0>>);

  EXPECT_EQ(cute::get<0>(cute::get<0>(pt3)), 42);
  EXPECT_EQ(cute::get<1>(cute::get<0>(pt3)), pt_test::Empty<0>{});
}

} // namespace test

TEST(CuTe_core, PackedTuple2)
{
  CUTLASS_TRACE_HOST("-------------------------------");
  CUTLASS_TRACE_HOST("packed_tuple");
  CUTLASS_TRACE_HOST("-------------------------------");

  pt_test::test_packed_type_aliases();
  pt_test::test_tuple_elements();
  pt_test::test_default_constructibility();
  pt_test::test_sizes_and_not_storing_empty_types();
}

TEST(CuTe_core, PackedTuple2Get) {
  using cute::packed_tuple;
  using pt_test::Empty;
  using pt_test::Nonempty;

  {
    using tuple_type = packed_tuple<int>;
    tuple_type pt{42};
    static_assert(cute::tuple_size_v<tuple_type> == 1u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, int>);
    EXPECT_EQ(cute::get<0>(pt), 42);
    cute::get<0>(pt) = 43;
    EXPECT_EQ(cute::get<0>(pt), 43);
  }
  {
    using tuple_type = packed_tuple<int>;
    tuple_type const pt{42};
    EXPECT_EQ(cute::get<0>(pt), 42);
    static_assert(cute::is_same_v<decltype(cute::get<0>(pt)), int const&>);
  }
  {
    EXPECT_EQ(cute::get<0>(packed_tuple<int>{42}), 42);
  }

  {
    using tuple_type = packed_tuple<pt_test::Empty<0>>;
    tuple_type pt;
    static_assert(cute::tuple_size_v<tuple_type> == 1u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, pt_test::Empty<0>>);
    EXPECT_EQ(cute::get<0>(pt), pt_test::Empty<0>{});
  }
  {
    using tuple_type = packed_tuple<pt_test::Empty<0>>;
    tuple_type const pt;
    EXPECT_EQ(cute::get<0>(pt), pt_test::Empty<0>{});
  }
  {
    using tuple_type = packed_tuple<pt_test::Empty<0>>;
    EXPECT_EQ(cute::get<0>(tuple_type{}), pt_test::Empty<0>{});
  }

  {
    using tuple_type = packed_tuple<int, double>;
    tuple_type pt{1, 2.5};
    static_assert(cute::tuple_size_v<tuple_type> == 2u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, int>);
    static_assert(cute::is_same_v<cute::tuple_element_t<1, tuple_type>, double>);
    EXPECT_EQ(cute::get<0>(pt), 1);
    cute::get<0>(pt) = 2;
    EXPECT_EQ(cute::get<0>(pt), 2);
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    cute::get<1>(pt) = 3.5;
    EXPECT_EQ(cute::get<1>(pt), 3.5);
  }
  {
    using tuple_type = packed_tuple<int, double>;
    tuple_type const pt{1, 2.5};
    EXPECT_EQ(cute::get<0>(pt), 1);
    static_assert(cute::is_same_v<decltype(cute::get<0>(pt)), int const&>);
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    static_assert(cute::is_same_v<decltype(cute::get<1>(pt)), double const&>);
  }
  {
    using tuple_type = packed_tuple<int, double>;
    EXPECT_EQ(cute::get<0>(tuple_type{1, 2.5}), 1);
    EXPECT_EQ(cute::get<1>(tuple_type{1, 2.5}), 2.5);
  }

  {
    using tuple_type = packed_tuple<Empty<0>, double>;
    tuple_type pt{Empty<0>{}, 2.5};
    static_assert(cute::tuple_size_v<tuple_type> == 2u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, Empty<0>>);
    static_assert(cute::is_same_v<cute::tuple_element_t<1, tuple_type>, double>);
    EXPECT_EQ(cute::get<0>(pt), Empty<0>{});
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    cute::get<1>(pt) = 3.5;
    EXPECT_EQ(cute::get<1>(pt), 3.5);
  }
  {
    using tuple_type = packed_tuple<Empty<0>, double>;
    tuple_type const pt{Empty<0>{}, 2.5};
    EXPECT_EQ(cute::get<0>(pt), Empty<0>{});
    static_assert(cute::is_same_v<decltype(cute::get<0>(pt)), Empty<0>>);
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    static_assert(cute::is_same_v<decltype(cute::get<1>(pt)), double const&>);
  }
  {
    using tuple_type = packed_tuple<Empty<0>, double>;
    EXPECT_EQ(cute::get<0>(tuple_type{Empty<0>{}, 2.5}), Empty<0>{});
    EXPECT_EQ(cute::get<1>(tuple_type{Empty<0>{}, 2.5}), 2.5);
  }

  {
    using tuple_type = packed_tuple<int, double, Nonempty<float>>;
    tuple_type pt{1, 2.5, Nonempty{3.25f}};
    static_assert(cute::tuple_size_v<tuple_type> == 3u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, int>);
    static_assert(cute::is_same_v<cute::tuple_element_t<1, tuple_type>, double>);
    static_assert(cute::is_same_v<cute::tuple_element_t<2, tuple_type>, Nonempty<float>>);
    EXPECT_EQ(cute::get<0>(pt), 1);
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    EXPECT_EQ(cute::get<2>(pt), Nonempty{3.25f});

    cute::get<0>(pt) = 42;
    EXPECT_EQ(cute::get<0>(pt), 42);
    cute::get<1>(pt) = 4.5;
    EXPECT_EQ(cute::get<1>(pt), 4.5);
    cute::get<2>(pt) = Nonempty<float>{3.75f};
    EXPECT_EQ(cute::get<2>(pt), Nonempty<float>{3.75f});
  }
  {
    using tuple_type = packed_tuple<int, double, Nonempty<float>>;
    tuple_type const pt{1, 2.5, Nonempty{3.25f}};
    EXPECT_EQ(cute::get<0>(pt), 1);
    EXPECT_EQ(cute::get<1>(pt), 2.5);
    EXPECT_EQ(cute::get<2>(pt), Nonempty{3.25f});
  }
  {
    using tuple_type = packed_tuple<int, double, Nonempty<float>>;
    EXPECT_EQ((cute::get<0>(tuple_type{1, 2.5, Nonempty{3.25f}})), 1);
    EXPECT_EQ((cute::get<1>(tuple_type{1, 2.5, Nonempty{3.25f}})), 2.5);
    EXPECT_EQ((cute::get<2>(tuple_type{1, 2.5, Nonempty{3.25f}})), Nonempty{3.25f});
  }

  {
    using tuple_type = packed_tuple<int, Empty<0>, Nonempty<float>>;
    packed_tuple<int, Empty<0>, Nonempty<float>> pt{1, Empty<0>{}, Nonempty{3.25f}};
    static_assert(cute::tuple_size_v<tuple_type> == 3u);
    static_assert(cute::is_same_v<cute::tuple_element_t<0, tuple_type>, int>);
    static_assert(cute::is_same_v<cute::tuple_element_t<1, tuple_type>, Empty<0>>);
    static_assert(cute::is_same_v<cute::tuple_element_t<2, tuple_type>, Nonempty<float>>);
    EXPECT_EQ(cute::get<0>(pt), 1);
    EXPECT_EQ(cute::get<1>(pt), Empty<0>{});
    EXPECT_EQ(cute::get<2>(pt), Nonempty{3.25f});

    cute::get<0>(pt) = 42;
    EXPECT_EQ(cute::get<0>(pt), 42);
    cute::get<2>(pt) = Nonempty<float>{3.75f};
    EXPECT_EQ(cute::get<2>(pt), Nonempty<float>{3.75f});
  }
  {
    using tuple_type = packed_tuple<int, Empty<0>, Nonempty<float>>;
    tuple_type const pt{1, Empty<0>{}, Nonempty{3.25f}};
    EXPECT_EQ(cute::get<0>(pt), 1);
    EXPECT_EQ(cute::get<1>(pt), Empty<0>{});
    EXPECT_EQ(cute::get<2>(pt), Nonempty{3.25f});
  }
  {
    using tuple_type = packed_tuple<int, Empty<0>, Nonempty<float>>;
    EXPECT_EQ((cute::get<0>(tuple_type{1, Empty<0>{}, Nonempty{3.25f}})), 1);
    EXPECT_EQ((cute::get<1>(tuple_type{1, Empty<0>{}, Nonempty{3.25f}})), Empty<0>{});
    EXPECT_EQ((cute::get<2>(tuple_type{1, Empty<0>{}, Nonempty{3.25f}})), Nonempty{3.25f});
  }
}

namespace pt_test {

// An empty class type to which Empty is convertible.
template<int Value>
struct ConvertibleFromEmpty {
  constexpr ConvertibleFromEmpty() = default;
  constexpr ConvertibleFromEmpty(Empty<Value>) {}

  template <int OtherValue>
  friend constexpr bool operator==(ConvertibleFromEmpty<Value> const&, ConvertibleFromEmpty<OtherValue> const&) {
    return Value == OtherValue;
  }

  template <int OtherValue>
  friend constexpr bool operator!=(ConvertibleFromEmpty<Value> const& lhs, ConvertibleFromEmpty<OtherValue> const& rhs) {
    return !(lhs == rhs);
  }
};

} // end namespace pt_test

TEST(CuTe_core, PackedTupleConstexprDefaultConstruction) {
  // Make sure that packed_tuple's default constructor is constexpr.
  // MSVC makes this a bit more challenging than usual.

  using pt_test::Empty;
  {
    [[maybe_unused]] constexpr cute::detail::ESO_t<Empty<0>> eso1{};
    [[maybe_unused]] constexpr cute::detail::ESO_t<int64_t> eso2{};
  }
  {
    [[maybe_unused]] constexpr cute::detail::ESO_t<Empty<0>, Empty<1>> eso0{};
    [[maybe_unused]] constexpr cute::detail::ESO_t<int64_t, Empty<1>> eso1{};
    [[maybe_unused]] constexpr cute::detail::ESO_t<Empty<0>, int64_t> eso2{};
    [[maybe_unused]] constexpr cute::detail::ESO_t<int64_t, int64_t> eso3{};
  }
}

TEST(CuTe_core, PackedTupleConvertingConstruction) {
  using cute::packed_tuple;
  using pt_test::ConvertibleFromEmpty;
  using pt_test::Empty;
  using pt_test::Nonempty;  

  {
    using tuple_type = cute::tuple<Nonempty<int>>;
    [[maybe_unused]] tuple_type t(7);
    EXPECT_EQ(cute::get<0>(t), Nonempty<int>(7));
  }
  {
    using tuple_type = packed_tuple<Nonempty<int>>;
    [[maybe_unused]] tuple_type t(7);
    EXPECT_EQ(cute::get<0>(t), Nonempty<int>(7));
  }
  {
    using tuple_type = cute::tuple<ConvertibleFromEmpty<0>>;
    [[maybe_unused]] tuple_type t(Empty<0>{});
    EXPECT_EQ(cute::get<0>(t), ConvertibleFromEmpty<0>{});
  }
  {
    using tuple_type = packed_tuple<ConvertibleFromEmpty<0>>;
    [[maybe_unused]] tuple_type t(Empty<0>{});
    EXPECT_EQ(cute::get<0>(t), ConvertibleFromEmpty<0>{});
  }

  {
    using tuple_type = cute::tuple<float, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(1.5f, 7);
    EXPECT_EQ(cute::get<0>(t), 1.5f);
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }
  {
    using tuple_type = packed_tuple<float, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(1.5f, 7);
    EXPECT_EQ(cute::get<0>(t), 1.5f);
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }

  {
    using tuple_type = cute::tuple<Empty<0>, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(Empty<0>{}, 7);
    EXPECT_EQ(cute::get<0>(t), Empty<0>{});
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }
  {
    using tuple_type = packed_tuple<Empty<0>, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(Empty<0>{}, 7);
    EXPECT_EQ(cute::get<0>(t), Empty<0>{});
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }

  {
    using tuple_type = cute::tuple<ConvertibleFromEmpty<0>, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(Empty<0>{}, 7);
    EXPECT_EQ(cute::get<0>(t), ConvertibleFromEmpty<0>{});
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }
  {
    using tuple_type = packed_tuple<ConvertibleFromEmpty<0>, Nonempty<int>>;
    [[maybe_unused]] tuple_type t(Empty<0>{}, 7);
    EXPECT_EQ(cute::get<0>(t), ConvertibleFromEmpty<0>{});
    EXPECT_EQ(cute::get<1>(t), Nonempty<int>(7));
  }

  {
    using inner_tuple_type = cute::tuple<Empty<0>>;
    using outer_tuple_type = cute::tuple<inner_tuple_type>;
    [[maybe_unused]] outer_tuple_type t(inner_tuple_type{Empty<0>{}});
  }
  {
    using inner_tuple_type = packed_tuple<Empty<0>>;
    using outer_tuple_type = packed_tuple<inner_tuple_type>;
    [[maybe_unused]] outer_tuple_type t(inner_tuple_type{Empty<0>{}});
  }
  {
    using inner_tuple_type = cute::tuple<ConvertibleFromEmpty<0>>;
    using outer_tuple_type = cute::tuple<inner_tuple_type>;
    [[maybe_unused]] outer_tuple_type t(inner_tuple_type{Empty<0>{}});
  }
  {
    using inner_tuple_type = packed_tuple<ConvertibleFromEmpty<0>>;
    using outer_tuple_type = packed_tuple<inner_tuple_type>;
    [[maybe_unused]] outer_tuple_type t(inner_tuple_type{Empty<0>{}});
  }

}


