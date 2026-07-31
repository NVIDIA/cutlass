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

#include <variant>
#include <vector>

#include "cutegen/cg_error.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

////////////////////////////////////////////////////////////////////////////////
// TileToShapeTest.Basic
TEST(TileToShapeTest, Basic)
{
    {
        auto block           = cg::from_string<cg::layout>("(64,8):(1,64)").value();
        auto trg_shape       = cg::from_string<cg::shape>("((128,1),(16,1),1)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((64,2),(8,2),(1,1)):((1,512),(64,1024),(0,0))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((64,2),(8,2),(1,1)):((1,1024),(64,512),(0,0))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(64,8):(1,64)").value();
        auto trg_shape       = cg::from_string<cg::shape>("((64,1),(16,1),1)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(8,64):(64,1)").value();
        auto trg_shape       = cg::from_string<cg::shape>("((128,1),(16,4),1)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(8,64):(64,1)").value();
        auto trg_shape       = cg::from_string<cg::shape>("((64,1),(16,4),1)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(8,64):(64,1)").value();
        auto trg_shape       = cg::from_string<cg::shape>("(64,128,2)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(8,64):(64,1)").value();
        auto trg_shape       = cg::from_string<cg::shape>("((16,4),(64,2),2)").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block           = cg::from_string<cg::layout>("(16,32):(1,16)").value();
        auto trg_shape       = cg::from_string<cg::shape>("(32,64,(2,1))").value();
        auto tiled_layout_cm = cg::from_string<cg::layout>("((16,2),(32,2),(1,2)):((1,512),(16,1024),(0,2048))").value();
        auto tiled_layout_rm = cg::from_string<cg::layout>("((16,2),(32,2),(1,2)):((1,2048),(16,1024),(0,512))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape), tiled_layout_cm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::gen_row_major{}), tiled_layout_rm);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout_rm);
    }
    {
        auto block            = cg::from_string<cg::layout>("((32,4),(32,4)):((16,4),(0,1))").value();
        auto trg_shape        = cg::from_string<cg::shape>("(1024,256,2)").value();
        auto tiled_layout_213 = cg::from_string<cg::layout>("(((32,4),8),((32,4),2),(1,2)):(((16,4),1024),((0,1),512),(0,8192))").value();
        auto tiled_layout_123 = cg::from_string<cg::layout>("(((32,4),8),((32,4),2),(1,2)):(((16,4),512),((0,1),4096),(0,8192))").value();
        auto tiled_layout_321 = cg::from_string<cg::layout>("(((32,4),8),((32,4),2),(1,2)):(((16,4),2048),((0,1),1024),(0,512))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 3)), tiled_layout_213);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(1, 2, 3)), tiled_layout_123);
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(3, 2, 1)), tiled_layout_321);
    }
    {
        // both target and tiler contain dynamic elements
        auto block        = cg::from_string<cg::layout>("((32,4),(?,4)):((16,4),(0,1))").value();
        auto trg_shape    = cg::from_string<cg::shape>("(256,?,2)").value();
        auto tiled_layout = cg::from_string<cg::layout>("(((32,4),2),((?,4),?),(1,2)):(((16,4),?),((0,1),1024),(0,512))").value();
        EXPECT_EQ(cg::tile_to_shape(block, trg_shape, cg::int_tuple(2, 1, 0)), tiled_layout);
    }
    {
        // expected error: insufficient modes
        auto block     = cg::from_string<cg::layout>("(8,64):(64,1)").value();
        auto trg_shape = cg::from_string<cg::shape>("((64,1))").value();
        EXPECT_TRUE(cg::has_error(cg::tile_to_shape(block, trg_shape)));
    }
}
