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

#include <string>
#include <vector>

#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

////////////////////////////////////////////////////////////////////////
// CompareTest.Simple2D
TEST(CompareTest, Simple2D)
{
    // Simple 2D layout
    {
        cg::layout l0(cg::shape(3, 5), cg::gen_col_major{});
        EXPECT_EQ(cg::to_string(l0), "(3,5):(1,3)");
        EXPECT_EQ(cg::static_size(l0), 3 * 5);
        for(int i = 0; i < cg::static_size(l0); ++i)
        {
            auto coord_i = cg::idx2crd(i, l0.shape(), l0.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l0.shape()));
            for(int j = 0; j < cg::static_size(l0); ++j)
            {
                auto coord_j = cg::idx2crd(j, l0.shape(), l0.stride());
                //std::cout << "  " << j << ": " << coord_j << std::endl;
                EXPECT_TRUE(cg::elem_less(coord_j, l0.shape()));
                EXPECT_EQ((i < j), cg::colex_less(coord_i, coord_j));
            }
        }
    }
    {
        cg::layout l1(cg::shape(3, 5), cg::gen_row_major{});
        EXPECT_EQ(cg::to_string(l1), "(3,5):(5,1)");
        for(int i = 0; i < cg::static_size(l1); ++i)
        {
            auto coord_i = cg::idx2crd(i, l1.shape(), l1.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l1.shape()));
            for(int j = 0; j < cg::static_size(l1); ++j)
            {
                auto coord_j = cg::idx2crd(j, l1.shape(), l1.stride());
                EXPECT_TRUE(cg::elem_less(coord_j, l1.shape()));
                EXPECT_EQ((i < j), cg::lex_less(coord_i, coord_j));
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////
// CompareTest.Simple3D
TEST(CompareTest, Simple3D)
{
    // Simple 3D layout
    {
        cg::layout l0(cg::shape(2, 3, 5), cg::gen_col_major{});
        //std::cout << "Layout: " << layout << std::endl;
        for(int i = 0; i < cg::static_size(l0); ++i)
        {
            auto coord_i = cg::idx2crd(i, l0.shape(), l0.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l0.shape()));
            for(int j = 0; j < cg::static_size(l0); ++j)
            {
                auto coord_j = cg::idx2crd(j, l0.shape(), l0.stride());
                EXPECT_TRUE(cg::elem_less(coord_j, l0.shape()));
                EXPECT_EQ((i < j), cg::colex_less(coord_i, coord_j));
            }
        }
    }
    {
        cg::layout l1(cg::shape(2, 3, 5), cg::gen_row_major{});
        //std::cout << "Layout: " << layout << std::endl;
        for(int i = 0; i < cg::static_size(l1); ++i)
        {
            auto coord_i = cg::idx2crd(i, l1.shape(), l1.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l1.shape()));

            for(int j = 0; j < cg::static_size(l1); ++j)
            {
                auto coord_j = cg::idx2crd(j, l1.shape(), l1.stride());
                EXPECT_TRUE(cg::elem_less(coord_j, l1.shape()));
                EXPECT_EQ((i < j), cg::lex_less(coord_i, coord_j));
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////
// CompareTest.Hierarchical
TEST(CompareTest, Hierarchical)
{
    // Hierarchical 3D layout
    {
        cg::layout l0(cg::shape(cg::shape(3, 2), cg::shape(5, 2, 2)), cg::gen_col_major{});
        //std::cout << "Layout: " << layout << std::endl;

        for(int i = 0; i < cg::static_size(l0); ++i)
        {
            auto coord_i = cg::idx2crd(i, l0.shape(), l0.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l0.shape()));

            for(int j = 0; j < cg::static_size(l0); ++j)
            {
                auto coord_j = cg::idx2crd(j, l0.shape(), l0.stride());
                EXPECT_TRUE(cg::elem_less(coord_j, l0.shape()));
                EXPECT_EQ((i < j), cg::colex_less(coord_i, coord_j));
            }
        }
    }
    {
        cg::layout l1(cg::shape(cg::shape(3, 2), cg::shape(5, 2, 2)), cg::gen_row_major{});
        //std::cout << "Layout: " << layout << std::endl;

        for(int i = 0; i < cg::static_size(l1); ++i)
        {
            auto coord_i = cg::idx2crd(i, l1.shape(), l1.stride());
            //std::cout << i << ": " << coord_i << std::endl;
            EXPECT_TRUE(cg::elem_less(coord_i, l1.shape()));

            for(int j = 0; j < cg::static_size(l1); ++j)
            {
                auto coord_j = cg::idx2crd(j, l1.shape(), l1.stride());
                EXPECT_TRUE(cg::elem_less(coord_j, l1.shape()));
                EXPECT_EQ((i < j), cg::lex_less(coord_i, coord_j));
            }
        }
    }
}
