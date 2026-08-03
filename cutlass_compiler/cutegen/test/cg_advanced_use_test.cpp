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

#include "cutegen/composed_layout.hpp"
#include "cutegen/cutegen.hpp"
#include "cutegen/cutegen_base_dynamic.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/underscore.hpp"

#include "gtest/gtest.h"

namespace cg = cutegen;

TEST(AdvancedUsageTest, TwoLevelTiling)
{
    auto opt_prob_shape     = cg::from_string<cg::shape>("(512,513,512,2)");
    auto opt_cluster_tile_shape = cg::from_string<cg::shape>("(256,128,64,1)");
    auto opt_cluster_shape      = cg::from_string<cg::shape>("(2,2)");
    ASSERT_TRUE(opt_prob_shape.has_value() &&
                opt_cluster_tile_shape.has_value() &&
                opt_cluster_shape.has_value());

    // CLUSTER level tiling
    auto tiled_prob_cluster               = cg::zipped_divide(cg::layout(opt_prob_shape.value()),
                                            cg::shape_to_tile(opt_cluster_tile_shape.value()));
    auto opt_exp_tiled_prob_cluster_shape = cg::from_string<cg::shape>(
        "((256,128,64,1),(2,5,8,2))"); // (CLUSTER_TILE,REST)
    ASSERT_TRUE(opt_exp_tiled_prob_cluster_shape.has_value());
    EXPECT_EQ(tiled_prob_cluster.shape(), opt_exp_tiled_prob_cluster_shape.value());

    // CTA level tiling
    auto cluster_tile_shape = opt_cluster_tile_shape.value();
    auto cluster_shape      = opt_cluster_shape.value();
    auto cta_tile_shape = cluster_tile_shape;
    cta_tile_shape[0] = cg::scalar_div<cg::shape>(cluster_tile_shape[0], cluster_shape[0]);
    cta_tile_shape[1] = cg::scalar_div<cg::shape>(cluster_tile_shape[1], cluster_shape[1]);
    cg::tile cta_tiler;
    cta_tiler.append(cg::shape_to_tile(cta_tile_shape));
    auto opt_exp_cta_tiler = cg::from_string<cg::tile>("[[128:1;64:1;64:1;1:0]]");
    ASSERT_TRUE(opt_exp_cta_tiler.has_value());
    EXPECT_EQ(cta_tiler, opt_exp_cta_tiler.value());
    auto tiled_prob_cta               = cg::zipped_divide(tiled_prob_cluster, cta_tiler);
    auto opt_exp_tiled_prob_cta_shape = cg::from_string<cg::shape>(
        "(((128,64,64,1)),((2,2,1,1),(2,5,8,2)))"); // (CTA_TILE,REST)
    ASSERT_TRUE(opt_exp_tiled_prob_cta_shape.has_value());
    EXPECT_EQ(tiled_prob_cta.shape(), opt_exp_tiled_prob_cta_shape.value());
}

TEST(AdvancedUsageTest, WorkIndexToTileCoord)
{
    // We try to use CuTe algebra to map from a CTA-wide work index to the corresponding tile
    // coordinate while supporting several rasterization strategies. For instance, AlongM in CUTLASS
    // maps a work index to tiles as shown in the schematic below for the following problem:
    // - 2x2 CLUSTERs
    // - 3x5 CLUSTERs in the problem
    // - AlongM rasterization
    //
    // --------------
    // 0  1  | 12 13
    // 2  3  | 14 15
    // --------------
    // 4  5  | ...
    // 6  7  |
    // --------------
    // 8  9  | ...
    // 10 11 |
    // --------------
    //
    // A work index is obtained as col_major_linearization_of_work_coord + col_major_linearization_of_cta_coord_in_cluster.
    // For example, work index 5 is associated to a work coordinate of (2,0) (the work-coordinate feature returns
    // the base coordinate in the cluster) and a CTA coordinate of (1,0) within the CLUSTER.
    //
    // The goal is to construct a layout that maps 13 to (0,3).
    //
    // Note that the adopted strategy would also work with non-static pb_shape, cluster_in_pb, and
    // cta_in_cluster and that AlongN is trivially supported by changing the stride of cluster_in_pb and
    // cta_in_cluster.

    cg::shape  pb_shape(6, 10);
    cg::layout cta_in_cluster(cg::shape(2, 2), cg::gen_row_major{});

    cg::shape cluster_in_pb_shape = cg::zipped_divide(
                                    cg::layout(pb_shape), cg::shape_to_tile(cta_in_cluster.shape()))
                                    .shape()[1];
    cg::layout cluster_in_pb = cg::layout(cluster_in_pb_shape, cg::gen_col_major{});
    cg::layout pb        = cg::make_identity_layout(pb_shape);
    cg::layout cta_x_cluster = cg::blocked_product(cta_in_cluster, cluster_in_pb);
    cg::layout mapper    = cg::composition(pb, cg::layout(cta_x_cluster.shape()));

    EXPECT_EQ(mapper(cg::idx2crd(13, cta_x_cluster.shape(), cta_x_cluster.stride())), cg::int_tuple(0, 3));
}
