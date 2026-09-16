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

#include <ostream>
#include <variant>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

template <class TLayout, class TCoTarget>
void test_complement_with_cotarget(const TLayout& l, TCoTarget cotarget, const TLayout& expected)
{
    using shape = cg::shape;
    // Convert integral cotargets to a shape so that cutegen functions work...
    shape cotarget_sh(cotarget);

    auto result = cg::complement(l, cotarget);
    EXPECT_EQ(result, expected) << " from input " << l << " with cotarget " << cotarget << std::endl;

    // Uncomment to check whether the complement with cotarget is the same
    // as without.
    //auto check = cg::complement(l);
    //if((check != result) && (cotarget == cg::static_cosize(l)))
    //{
    //    std::cout << "input = " << l << ", complement(new) = " << check << ", complement_with_cotarget() = " << result << std::endl;
    //}

    // We cannot verify additional properties for non-static layouts/cotargets
    if(!is_static(l) || !is_static(cotarget_sh))
        return;

    // Uncomment to compare new complement_extend with deprecated complement
    // with cosize function.
    //auto cext = complement_extend(l, cotarget_sh);
    //if(cext != result)
    //{
    //    std::cout << "MISMATCH: complement_extend(" << l << ", " << cotarget
    //              << ") = " << cext << ", compare to " << result << std::endl;
    //}

    std::vector<cg::layout> layouts{l, result};
    auto                    completed = cg::make_layout(layouts);

    auto size_result      = cg::static_size(result);
    auto cosize_result    = cg::static_cosize(result);
    auto size_cotarget    = cg::static_size(cotarget_sh);
    auto size_layout      = cg::static_size(cg::filter(l));
    auto cosize_layout    = cg::static_cosize(l);
    auto cosize_completed = cg::static_cosize(completed);

    // Lower-bound on the codomain size of the layout ++ complement (1)
    EXPECT_GE(cosize_completed, size_cotarget);
    // Upper-bound on the codomain size of the complement (2)
    EXPECT_LE(cosize_result,
              cg::ceil_div(size_cotarget, cosize_layout) * cosize_layout)
        << "cosize_result = " << cosize_result << ", size_cotarget = " << size_cotarget
        << ", cosize_layout = " << cosize_layout;
    // Post-condition on the codomain of the complement
    for(int i = 1; i < size_result; ++i)
    {
        EXPECT_TRUE(colex_less(result(i - 1), result(i))) // Ordered (3)
            << "layout = " << l << ", cotarget = " << cotarget;

        for(int j = 0; j < size_layout; ++j)
        {
            EXPECT_NE(result(i), l(j)); // Disjoint (4)
        }
    }
    // Other observations
    EXPECT_LE(size_result, cosize_result); // As a result of the ordered condition (3)
    EXPECT_GE(size_result, size_cotarget / size_layout);
    EXPECT_LE(cosize_completed, cosize_result + cosize_layout);
    EXPECT_GE(cosize_result, size_cotarget / size_layout);
    if(cg::is_static(completed.stride()))
    {
        // If we can apply complement again, there's no more codomain left over
        EXPECT_EQ(cg::static_size(cg::complement(completed, cg::static_cosize(completed))), 1);
    }
    // Double-complement round-trip. This identity only holds for
    // non-degenerate complements. When the input already fully covers the
    // cotarget the complement collapses to a single element "1:d" whose
    // stride d is the mode-stride product and may exceed the cotarget (e.g.
    // complement((4,6):(1,6), 34) = 1:36, with 36 > 34). Complementing that
    // back clamps the stride to the cotarget, so the round-trip cannot
    // recover the original "1:d" (PyCuTe behaves identically). Restrict the
    // check to non-degenerate (size > 1) results.
    if(cg::is_static(result) && cg::is_static(l) && (size_result > 1))
    {
        EXPECT_EQ(cg::complement(cg::complement(result, cosize_layout), cotarget), result);
    }
}
template <class TLayout>
void test_complement_with_cotarget(const TLayout& l, int cosize_hi, const TLayout& expected)
{
    test_complement_with_cotarget(l, static_cast<cg::static_int_t>(cosize_hi), expected);
}

TEST(ComplementTest, BasicWithCoTarget)
{
    using dyn_t = cg::dynamic_t;
    {
        cg::layout l(cg::shape(1), cg::stride(0));
        // complement(1:0, 1) => 1:1
        // complement(1:0, 2) => 2:1
        // complement(1:0, 5) => 5:1
        // complement(1:0, (2,?)) => (2,?):(1,2)
        test_complement_with_cotarget(l, cg::static_cosize(l), cg::layout(cg::shape(1), cg::stride(1)));
        test_complement_with_cotarget(l, 2, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 5, cg::layout(cg::shape(5), cg::stride(1)));
        test_complement_with_cotarget(l,
                                      cg::shape(2, dyn_t{}),
                                      cg::layout(cg::shape(2, dyn_t{}), cg::stride(1, 2)));
    }
    {
        cg::layout l(cg::shape(1), cg::stride(1));
        // complement(1:1, 1) => 1:1
        // complement(1:1, 2) => 2:1
        // complement(1:1, 5) => 5:1
        // complement(1:1, (2,?)) => (2,?):(1,2)
        test_complement_with_cotarget(l, cg::static_cosize(l), cg::layout(cg::shape(1), cg::stride(1)));
        test_complement_with_cotarget(l, 2, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 5, cg::layout(cg::shape(5), cg::stride(1)));
        test_complement_with_cotarget(l,
                                      cg::shape(2, dyn_t{}),
                                      cg::layout(cg::shape(2, dyn_t{}), cg::stride(1, 2)));
    }
    {
        cg::layout l(cg::shape(1), cg::stride(2));
        // complement(1:2, 1) => 1:1
        // complement(1:2, 2) => 2:1
        // complement(1:2, 8) => 8:1
        // complement(1:2, 5) => 5:1
        // complement(1:2, (2,?)) => (2,?):(1,2)
        test_complement_with_cotarget(l, 1, cg::layout(cg::shape(1), cg::stride(1)));
        test_complement_with_cotarget(l, 2, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 8, cg::layout(cg::shape(8), cg::stride(1)));
        test_complement_with_cotarget(l, 5, cg::layout(cg::shape(5), cg::stride(1)));
        test_complement_with_cotarget(l,
                                      cg::shape(2, dyn_t{}),
                                      cg::layout(cg::shape(2, dyn_t{}), cg::stride(1, 2)));
    }
    {
        cg::layout l(cg::shape(4), cg::stride(0));
        // complement(4:0, 1) => 1:1
        // complement(4:0, 2) => 2:1
        // complement(4:0, 8) => 8:1
        test_complement_with_cotarget(l, 1, cg::layout(cg::shape(1), cg::stride(1)));
        test_complement_with_cotarget(l, 2, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 8, cg::layout(cg::shape(8), cg::stride(1)));
    }
    {
        cg::layout l(cg::shape(4), cg::stride(1));
        // complement(4:1, 1) => 1:4
        // complement(4:1, 2) => 1:4
        // complement(4:1, 8) => 2:4
        test_complement_with_cotarget(l, 1, cg::layout(cg::shape(1), cg::stride(4)));
        test_complement_with_cotarget(l, 2, cg::layout(cg::shape(1), cg::stride(4)));
        test_complement_with_cotarget(l, 8, cg::layout(cg::shape(2), cg::stride(4)));
    }
    {
        cg::layout l(cg::shape(4), cg::stride(2));
        // complement(4:2, 1) => 2:1
        // complement(4:2, 7) => 2:1
        // complement(4:2, 16) => (2,2):(1,8)
        // complement(4:2, 19) => (2,3):(1,8)
        // complement(4:2, (2,?)) => (2,?):(1,8)
        test_complement_with_cotarget(l, 1, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 7, cg::layout(cg::shape(2), cg::stride(1)));
        test_complement_with_cotarget(l, 16, cg::layout(cg::shape(2, 2), cg::stride(1, 8)));
        test_complement_with_cotarget(l, 19, cg::layout(cg::shape(2, 3), cg::stride(1, 8)));
        test_complement_with_cotarget(l,
                                      cg::shape(2, dyn_t{}),
                                      cg::layout(cg::shape(2, dyn_t{}), cg::stride(1, 8)));
    }
    {
        cg::layout l(cg::shape(4), cg::stride(4));
        // complement(4:4, 1) => 4:1
        // complement(4:4, 13) => 4:1
        // complement(4:4, 17) => (4,2):(1,16)
        // complement(4:4, (2,?)) => (4,?):(1,16)
        test_complement_with_cotarget(l, 1, cg::layout(cg::shape(4), cg::stride(1)));
        test_complement_with_cotarget(l, 13, cg::layout(cg::shape(4), cg::stride(1)));
        test_complement_with_cotarget(l, 17, cg::layout(cg::shape(4, 2), cg::stride(1, 16)));
        test_complement_with_cotarget(l,
                                      cg::shape(2, dyn_t{}),
                                      cg::layout(cg::shape(4, dyn_t{}), cg::stride(1, 16)));
    }
    {
        cg::layout l(cg::shape(2, 4));
        // complement((2,4):(1,2), 8) => 1:8
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(1), cg::stride(8)));
    }
    {
        cg::layout l(cg::shape(2, 3));
        // complement((2,3):(1,2), 6) => 1:6
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(1), cg::stride(6)));
    }
    {
        cg::layout l(cg::shape(2, 4), cg::stride(1, 4));
        // complement((2,4):(1,4), 14) => 2:2
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2), cg::stride(2)));
    }
    {
        cg::layout l(cg::shape(2, 4), cg::stride(1, 6));
        // complement((2,4):(1,6), 20) => 3:2
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(3), cg::stride(2)));
    }
    {
        cg::layout l(cg::shape(2, 4, 8), cg::stride(8, 1, 64));
        // complement((2,4,8):(8,1,64), 460) => (2,4):(4,16)
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2, 4), cg::stride(4, 16)));
    }
    {
        cg::layout l(cg::shape(2, 4, 8), cg::stride(8, 1, 0));
        // complement((2,4,8):(8,1,0), 460) => (2,29):(4,16)
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2), cg::stride(4)));
        test_complement_with_cotarget(l, 460, cg::layout(cg::shape(2, 29), cg::stride(4, 16)));
    }
    {
        cg::layout l(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                     cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        // complement(((2,2),(2,2)):((1,4),(8,32)), 46) => (2,2):(2,16)
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2, 2), cg::stride(2, 16)));
    }
    {
        cg::layout l(cg::shape(cg::shape(2, 2), cg::shape(2, 2)),
                     cg::stride(cg::stride(1, 32), cg::stride(8, 4)));
        // complement(((2,2),(2,2)):((1,32),(8,4)), 46) => (2,2):(2,16)
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2, 2), cg::stride(2, 16)));
    }
    {
        cg::layout l(cg::shape(4, 6), cg::stride(1, 6));
        // complement((4,6):(1,6), 34) => 1:36
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(1), cg::stride(36)));
    }
    {
        cg::layout l(cg::shape(4, 2), cg::stride(1, 10));
        // complement((4,2):(1,10), 14) => 2:4
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(2), cg::stride(4)));
    }
    {
        cg::layout l(cg::shape(4, 2), cg::stride(1, 16));
        // complement((4,2):(1,16), 20) => 4:4
        test_complement_with_cotarget(l,
                                      cg::static_cosize(l),
                                      cg::layout(cg::shape(4), cg::stride(4)));
    }
}

TEST(ComplementTest, CoordWithCoTarget)
{
    using sb_t = cg::scaled_basis;
    {
        // complement(l, cosize_hi): scaled_basis strides are supported and use the
        // pycute-style algorithm. The result is structured per-basis-bucket, so a
        // single-basis tiler against an int cosize yields a rank-1 result.
        cg::layout l(cg::shape(3), cg::stride(sb_t{0, 1}));
        auto       c = cg::complement_extend(l, cg::shape(6));
        EXPECT_EQ(c,
                  cg::layout(cg::shape(cg::wrap(2)),
                             cg::stride(cg::wrap(sb_t{0, 3}))));
    }
}

TEST(ComplementTest, Dynamic)
{
    // test rank-1 dynamic
    using dyn_t  = cg::dynamic_t;
    using shape  = cg::shape;
    using stride = cg::stride;
    using layout = cg::layout;

    {
        layout ly(shape(dyn_t{}), stride(1));
        auto   ly_res = cg::complement(ly, cg::cosize(ly));
        EXPECT_EQ(ly_res, layout(shape(dyn_t{}), stride(dyn_t{})));
    }

    {
        layout ly(shape(dyn_t{}), stride(dyn_t{}));
        auto   ly_res = cg::complement(ly, cg::cosize(ly));
        EXPECT_EQ(ly_res, layout(shape(dyn_t{}, dyn_t{}), stride(1, dyn_t{})));
    }

    {
        layout ly(shape(dyn_t{}, dyn_t{}), stride(1, 12));
        auto   ly_res = cg::complement(ly, cg::cosize(ly));
        EXPECT_EQ(ly_res, layout(shape(dyn_t{}, dyn_t{}), stride(dyn_t{}, dyn_t{})));
    }

    {
        layout ly(shape(shape(dyn_t{}, dyn_t{}), shape(dyn_t{}, dyn_t{})), stride(stride(1, 4), stride(8, 32)));
        auto   ly_res = cg::complement(ly, cg::cosize(ly));
        EXPECT_EQ(ly_res, layout(shape(dyn_t{}, dyn_t{}, dyn_t{}, dyn_t{}), stride(dyn_t{}, dyn_t{}, dyn_t{}, dyn_t{})));
    }
}

TEST(ComplementTest, ShapeCoSize)
{
    using dyn_t = cg::dynamic_t;
    {
        cg::layout l(cg::shape(1), cg::stride(1));
        cg::shape  t(1, 8);
        cg::layout res = cg::complement(l, t);
        EXPECT_EQ(res, cg::layout(cg::shape(8), cg::stride(1)));
    }

    {
        cg::layout ly(cg::shape(32), cg::stride(1));
        cg::shape  t(32, 4, dyn_t{});
        cg::layout res = cg::complement(ly, t);
        EXPECT_EQ(res, cg::layout(cg::shape(4, dyn_t{}), cg::stride(32, 128)));
    }
}

TEST(ComplementTest, EmptyLayout)
{
    // An empty (rank-0) layout: ():()
    cg::layout empty_layout;
    EXPECT_EQ(cg::rank(empty_layout), 0);

    // filter() on empty layout returns empty layout
    auto filtered = cg::filter(empty_layout);

    // Verify this is NOT the stride-0 case — stride is empty (), not scalar 0
    // This ensures complement() goes through the s_d.empty() path, not stride()==0 path
    EXPECT_FALSE(filtered.stride() == 0);
    EXPECT_EQ(cg::rank(filtered), 0);

    // complement() should handle empty layouts gracefully via rank(flat_layout) == 0
    auto result = cg::complement(empty_layout, 128);

    // Should return a layout covering the requested codomain
    EXPECT_EQ(cg::static_size(result), 128);
    EXPECT_EQ(cg::static_cosize(result), 128);
}

TEST(ComplementTest, AllStrideZeroLayout)
{
    // A layout with all stride-0 modes (broadcasts to all elements)
    cg::layout l(cg::shape(4, 8), cg::stride(0, 0));

    // filter() coalesces this to a single element with stride 0
    auto filtered = cg::filter(l);
    EXPECT_EQ(cg::static_size(filtered), 1);
    EXPECT_EQ(filtered.stride(), 0);

    // complement() should handle this case via the stride-0 check
    auto result = cg::complement(l, 64);
    EXPECT_EQ(cg::static_size(result), 64);
    EXPECT_EQ(cg::static_cosize(result), 64);
}

void test_complement(const cg::layout& ly, const cg::layout& expected, bool strong = true)
{
    auto layoutR = cg::complement(ly);
    // Verify that the complement is the same as PyCute
    EXPECT_EQ(layoutR, expected) << "layout = " << ly;

    // Post-condition: weak congruence with codomain
    EXPECT_TRUE(cg::weakly_congruent(cg::coprofile(ly), layoutR));

    // Post-condition: test orderedness and disjointness of the codomains
    if(cg::is_static(layoutR) && cg::is_static(ly))
    {
        using int_t = cg::layout::int_t;
        for(int_t i = 1; i < cg::static_size(layoutR); ++i)
        {
            EXPECT_TRUE(colex_less(layoutR(i - 1), layoutR(i))); // Ordered
            for(int_t j = 0; j < cg::static_size(ly); ++j)
            {
                EXPECT_NE(layoutR(i), ly(j)); // Disjoint
            }
        }
        if(strong)
        {
            // Generalized inverse conditions
            cg::layout completed  = cg::make_layout(std::vector<cg::layout>{ly, layoutR});
            cg::layout inv_layout = cg::right_inverse(completed);
            ASSERT_TRUE(cg::is_static(completed));
            // Right inverse condition
            for(int_t i = 0; i < cg::static_size(inv_layout); ++i)
            {
                EXPECT_EQ(inv_layout(completed(inv_layout(i))), inv_layout(i))
                    << "i = " << i
                    << ", layout = " << ly
                    << ", layoutR = " << layoutR
                    << ", inv_layout = " << inv_layout
                    << ", completed = " << completed;
            }
            // Left inverse condition
            for(int_t i = 0; i < cg::static_size(completed); ++i)
            {
                EXPECT_EQ(completed(inv_layout(completed(i))), completed(i))
                    << "i = " << i
                    << ", layout = " << ly
                    << ", layoutR = " << layoutR
                    << ", inv_layout = " << inv_layout
                    << ", completed = " << completed;
            }
        }
    }
}

TEST(ComplementTest, Basic)
{
    using sb_t = cg::scaled_basis;
    // 1:0  =>  1:1
    {
        cg::layout test(cg::shape(1), cg::stride(0));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // 1:1  =>  1:1
    {
        cg::layout test(cg::shape(1), cg::stride(1));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // 1:2  =>  1:1
    {
        cg::layout test(cg::shape(1), cg::stride(2));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // 1:4  =>  1:1
    {
        cg::layout test(cg::shape(1), cg::stride(4));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // (1, 1):(0, 0)  =>  1:1
    {
        cg::layout test(cg::shape(1, 1), cg::stride(0, 0));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // (3, 7):(0, 0)  =>  1:1
    {
        cg::layout test(cg::shape(1), cg::stride(2));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // 5:1  =>  1:5
    {
        cg::layout test(cg::shape(5), cg::stride(1));
        cg::layout expected(cg::shape(1), cg::stride(5));
        test_complement(test, expected);
    }
    // 5:3  =>  (3, 1):(1, 15)
    {
        cg::layout test(cg::shape(5), cg::stride(3));
        cg::layout expected(cg::shape(3, 1), cg::stride(1, 15));
        test_complement(test, expected);
    }
    // 4:0  =>  1:1
    {
        cg::layout test(cg::shape(4), cg::stride(0));
        cg::layout expected(cg::shape(1), cg::stride(1));
        test_complement(test, expected);
    }
    // 4:1  =>  1:4
    {
        cg::layout test(cg::shape(4), cg::stride(1));
        cg::layout expected(cg::shape(1), cg::stride(4));
        test_complement(test, expected);
    }
    // 4:2  =>  (2, 1):(1, 8)
    {
        cg::layout test(cg::shape(4), cg::stride(2));
        cg::layout expected(cg::shape(2, 1), cg::stride(1, 8));
        test_complement(test, expected);
    }
    // 4:4  =>  (4, 1):(1, 16)
    {
        cg::layout test(cg::shape(4), cg::stride(4));
        cg::layout expected(cg::shape(4, 1), cg::stride(1, 16));
        test_complement(test, expected);
    }
    // (2, 4):(1, 2)  =>  1:8
    {
        cg::layout test(cg::shape(2, 4), cg::stride(1, 2));
        cg::layout expected(cg::shape(1), cg::stride(8));
        test_complement(test, expected);
    }
    // (2, 3):(1, 2)  =>  1:6
    {
        cg::layout test(cg::shape(2, 3), cg::stride(1, 2));
        cg::layout expected(cg::shape(1), cg::stride(6));
        test_complement(test, expected);
    }
    // (2, 4):(1, 4)  =>  (2, 1):(2, 16)
    {
        cg::layout test(cg::shape(2, 4), cg::stride(1, 4));
        cg::layout expected(cg::shape(2, 1), cg::stride(2, 16));
        test_complement(test, expected);
    }
    // (8, 4):(1, 8)  =>  1:32
    {
        cg::layout test(cg::shape(8, 4), cg::stride(1, 8));
        cg::layout expected(cg::shape(1), cg::stride(32));
        test_complement(test, expected);
    }
    // (8, 4):(4, 1)  =>  1:32
    {
        cg::layout test(cg::shape(8, 4), cg::stride(4, 1));
        cg::layout expected(cg::shape(1), cg::stride(32));
        test_complement(test, expected);
    }
    // (2, 4, 6):(1, 2, 8)  =>  1:48
    {
        cg::layout test(cg::shape(2, 4, 6), cg::stride(1, 2, 8));
        cg::layout expected(cg::shape(1), cg::stride(48));
        test_complement(test, expected);
    }
    // (2, 4, 6):(4, 1, 8)  =>  1:48
    {
        cg::layout test(cg::shape(2, 4, 6), cg::stride(4, 1, 8));
        cg::layout expected(cg::shape(1), cg::stride(48));
        test_complement(test, expected);
    }
    // (2, 4, 8):(8, 1, 64)  =>  (2, 4, 1):(4, 16, 512)
    {
        cg::layout test(cg::shape(2, 4, 8), cg::stride(8, 1, 64));
        cg::layout expected(cg::shape(2, 4, 1), cg::stride(4, 16, 512));
        test_complement(test, expected);
    }
    // (2, 4, 8):(32, 0, 2)  =>  (2, 2, 1):(1, 16, 64)
    {
        cg::layout test(cg::shape(2, 4, 8), cg::stride(32, 0, 2));
        cg::layout expected(cg::shape(2, 2, 1), cg::stride(1, 16, 64));
        test_complement(test, expected);
    }
    // (2, 4, 8):(2, 0, 32)  =>  (2, 8, 1):(1, 4, 256)
    {
        cg::layout test(cg::shape(2, 4, 8), cg::stride(2, 0, 32));
        cg::layout expected(cg::shape(2, 8, 1), cg::stride(1, 4, 256));
        test_complement(test, expected);
    }
    // (2, 4, 4, 4, 2):(32, 0, 2, 0, 512)  =>  (2, 4, 8, 1):(1, 8, 64, 1024)
    {
        cg::layout test(cg::shape(2, 4, 4, 4, 2), cg::stride(32, 0, 2, 0, 512));
        cg::layout expected(cg::shape(2, 4, 8, 1), cg::stride(1, 8, 64, 1024));
        test_complement(test, expected);
    }
    // ((2, 2), (2, 2)):((1, 4), (8, 32))  =>  (2, 2, 1):(2, 16, 64)
    {
        cg::layout test(cg::shape(cg::shape(2, 2), cg::shape(2, 2)), cg::stride(cg::stride(1, 4), cg::stride(8, 32)));
        cg::layout expected(cg::shape(2, 2, 1), cg::stride(2, 16, 64));
        test_complement(test, expected);
    }
    // (2, (3, 4)):(3, (1, 6))  =>  1:24
    {
        cg::layout test(cg::shape(2, cg::shape(3, 4)), cg::stride(3, cg::stride(1, 6)));
        cg::layout expected(cg::shape(1), cg::stride(24));
        test_complement(test, expected);
    }
    // (4, 2):(1, 16)  =>  (4, 1):(4, 32)
    {
        cg::layout test(cg::shape(4, 2), cg::stride(1, 16));
        cg::layout expected(cg::shape(4, 1), cg::stride(4, 32));
        test_complement(test, expected);
    }
    // 3:1@0  =>  (1):(3@0)
    {
        cg::layout test(cg::shape(3), cg::stride(sb_t{0, 1}));
        cg::layout expected(cg::shape(cg::wrap(1)), cg::stride(cg::wrap(sb_t{0, 3})));
        test_complement(test, expected);
    }
    // 3:4@2  =>  (1, 1, (4, 1)):(1@0, 1@1, (1@2, 12@2))
    {
        cg::layout test(cg::shape(3), cg::stride(sb_t{2, 4}));
        cg::layout expected(cg::shape(1, 1, cg::shape(4, 1)),
                            cg::stride(sb_t{0, 1}, sb_t{1, 1}, cg::stride(sb_t{2, 1}, sb_t{2, 12})));
        test_complement(test, expected);
    }
    // (2, 5, 3):(4@1, 5@0, 16@1)  =>  ((5, 1), (4, 2, 1)):((1@0, 25@0), (1@1, 8@1, 48@1))
    {
        cg::layout test(cg::shape(2, 5, 3), cg::stride(sb_t{1, 4}, sb_t{0, 5}, sb_t{1, 16}));
        cg::layout expected(cg::shape(cg::shape(5, 1), cg::shape(4, 2, 1)),
                            cg::stride(cg::stride(sb_t{0, 1}, sb_t{0, 25}), cg::stride(sb_t{1, 1}, sb_t{1, 8}, sb_t{1, 48})));
        test_complement(test, expected);
    }
    // (2, 1, 5, 3):(4@1, 0, 5@0, 16@1)  =>  ((1, 5, 1), (4, 2, 1)):((1@0, 25@0), (1@1, 8@1, 48@1))
    // (mixing a static integer stride with scaled basis values)
    {
        cg::layout test(cg::shape(2, 1, 5, 3), cg::stride(sb_t{1, 4}, 0, sb_t{0, 5}, sb_t{1, 16}));
        cg::layout expected(cg::shape(cg::shape(5, 1), cg::shape(4, 2, 1)),
                            cg::stride(cg::stride(sb_t{0, 1}, sb_t{0, 25}), cg::stride(sb_t{1, 1}, sb_t{1, 8}, sb_t{1, 48})));
        test_complement(test, expected);
    }
    // (2, 3, 5):(4@1, 5@0, 7@1@2)  =>  ((5, 1), (4, 1), (1, (7, 1))):((1@0, 15@0), (1@1, 8@1), (1@0@2, (1@1@2, 35@1@2)))
    {
        cg::layout test(cg::shape(2, 3, 5), cg::stride(sb_t{1, 4}, sb_t{0, 5}, sb_t{{2, 1}, 7}));
        cg::layout expected(cg::shape(cg::shape(5, 1), cg::shape(4, 1), cg::shape(1, cg::shape(7, 1))),
                            cg::stride(cg::stride(sb_t{0, 1}, sb_t{0, 15}), cg::stride(sb_t{1, 1}, sb_t{1, 8}), cg::stride(sb_t{{2, 0}, 1}, cg::stride(sb_t{{2, 1}, 1}, sb_t{{2, 1}, 35}))));
        test_complement(test, expected);
    }
    // (2, 3, 5):(4@1, 0, 7@1@2)  =>  (1, (4, 1), (1, (7, 1))):(1@0, (1@1, 8@1), (1@0@2, (1@1@2, 35@1@2)))
    {
        cg::layout test(cg::shape(2, 3, 5), cg::stride(sb_t{1, 4}, 0, sb_t{{2, 1}, 7}));
        cg::layout expected(cg::shape(1, cg::shape(4, 1), cg::shape(1, cg::shape(7, 1))),
                            cg::stride(sb_t{0, 1}, cg::stride(sb_t{1, 1}, sb_t{1, 8}), cg::stride(sb_t{{2, 0}, 1}, cg::stride(sb_t{{2, 1}, 1}, sb_t{{2, 1}, 35}))));
        test_complement(test, expected);
    }
    // (4, 2):(1, 6)  =>  1:12 (weak)
    {
        cg::layout test(cg::shape(4, 2), cg::stride(1, 6));
        cg::layout expected(cg::shape(1), cg::stride(12));
        test_complement(test, expected, /*strong=*/false);
    }
    // (4, 2):(1, 5)  =>  1:10 (weak)
    {
        cg::layout test(cg::shape(4, 2), cg::stride(1, 5));
        cg::layout expected(cg::shape(1), cg::stride(10));
        test_complement(test, expected, /*strong=*/false);
    }
    // (4, 2):(1, 10)  =>  (2, 1):(4, 20) (weak)
    {
        cg::layout test(cg::shape(4, 2), cg::stride(1, 10));
        cg::layout expected(cg::shape(2, 1), cg::stride(4, 20));
        test_complement(test, expected, /*strong=*/false);
    }
    // (4, 2):(1, 11)  =>  (2, 1):(4, 22) (weak)
    {
        cg::layout test(cg::shape(4, 2), cg::stride(1, 11));
        cg::layout expected(cg::shape(2, 1), cg::stride(4, 22));
        test_complement(test, expected, /*strong=*/false);
    }
    // (2, 4):(11, 1)  =>  (2, 1):(4, 22) (weak)
    {
        cg::layout test(cg::shape(2, 4), cg::stride(11, 1));
        cg::layout expected(cg::shape(2, 1), cg::stride(4, 22));
        test_complement(test, expected, /*strong=*/false);
    }
}

////////////////////////////////////////////////////////////////////////
// ComplementTest.InvalidInputs
//
// Verify that complement() returns an error layout (is_valid() == false)
// when the input does not satisfy its preconditions.
// complement(l, cosize_hi) with a scaled_basis stride: the pycute-style
// algorithm structures the result per-basis-bucket, so a single-basis tiler
// against an int cosize yields a rank-1 result.
TEST(ComplementTest, ScaledBasisWithCoTarget)
{
    using sb_t = cg::scaled_basis;
    cg::layout l(cg::shape(3), cg::stride(sb_t{0, 1}));
    cg::layout result = cg::complement(l, 6);
    cg::layout expected(cg::shape(cg::wrap(2)), cg::stride(cg::wrap(sb_t{0, 3})));
    EXPECT_TRUE(cg::is_valid(result));
    EXPECT_EQ(result, expected);
}

TEST(ComplementTest, InvalidInputs)
{
    using dyn_t = cg::dynamic_t;
    using sb_t  = cg::scaled_basis;

    // complement(l): shape must be valid (no cg_error_t elements).
    {
        cg::layout l(cg::shape(cg::cg_error_t{}), cg::stride(1));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto result = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }

    // complement(l): stride must be valid (no cg_error_t elements).
    {
        cg::layout l(cg::shape(4), cg::stride(cg::cg_error_t{}));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto result = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }

    // complement(l): stride must have a single value when it is
    // dynamic.
    {
        cg::layout l(cg::shape(4, 8), cg::stride(dyn_t{}, 16));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto res = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }

    // complement(l): stride must have a single value when it is
    // dynamic.
    {
        cg::layout l(cg::shape(4, 8), cg::stride(dyn_t{}, dyn_t{}));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto res = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }

    // complement(l): non-injective layout. The layout (4, 2):(1, 2) is
    // non-injective because after sorting strides (already ordered here),
    // the second stride (2) is less than the accumulated stride (1*4=4).
    {
        cg::layout l(cg::shape(4, 2), cg::stride(1, 2));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto res = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }
    // stride elements must not mix nonzero integers and scaled basis values.
    {
        cg::layout l(cg::shape(4, 2), cg::stride(1, sb_t{1, 2}));
#if defined(__cpp_exceptions) && !defined(CUTEGEN_DISALLOW_EXCEPTIONS)
        EXPECT_ANY_THROW(auto res = cg::complement(l));
#else
        EXPECT_FALSE(cg::is_valid(cg::complement(l)));
#endif
    }
}
