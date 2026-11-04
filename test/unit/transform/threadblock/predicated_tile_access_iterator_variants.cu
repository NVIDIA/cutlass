/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "../../common/cutlass_unit_test.h"

#include "cutlass/transform/pitch_linear_thread_map.h"
#include "cutlass/transform/threadblock/ell_predicated_tile_access_iterator.h"
#include "cutlass/transform/threadblock/predicated_tile_access_iterator.h"
#include "cutlass/transform/threadblock/predicated_tile_access_iterator_2dthreadtile.h"
#include "cutlass/transform/threadblock/predicated_tile_access_iterator_triangular_matrix.h"
#include "cutlass/util/device_memory.h"

#include <vector>

namespace {

static int const kThreads = 32;
static int const kCases = 24;

template <typename Iterator>
__global__ void check_tile_offsets(
    typename Iterator::Params params,
    typename Iterator::Layout layout,
    typename Iterator::Element *storage,
    int *results) {

  using TensorCoord = typename Iterator::TensorCoord;
  using Shape = typename Iterator::Shape;

  TensorCoord offsets[] = {
      cutlass::make_Coord(1, 1), cutlass::make_Coord(2, 3),
      cutlass::make_Coord(-1, 1), cutlass::make_Coord(1, -1),
      cutlass::make_Coord(0, 2), cutlass::make_Coord(2, 0)};
  TensorCoord extents[] = {
      cutlass::make_Coord(497, 65), cutlass::make_Coord(512, 64)};
  auto pointer = storage + layout(cutlass::make_Coord(128, 24));
  int case_idx = 0;

  for (auto extent : extents) {
    for (int steady_state = 0; steady_state < 2; ++steady_state) {
      for (auto offset : offsets) {
        TensorCoord advance_offset = offset;
        TensorCoord cross_offset = cutlass::make_Coord(0, 0);
        if (Iterator::kAdvanceRank) {
          advance_offset[0] = 0;
          cross_offset[0] = Shape::kContiguous * offset[0];
        }
        else {
          advance_offset[1] = 0;
          cross_offset[1] = Shape::kStrided * offset[1];
        }

        Iterator actual(params, pointer, extent, threadIdx.x);
        Iterator expected(params, pointer, extent, threadIdx.x);
        if (steady_state) {
          TensorCoord first_offset = cutlass::make_Coord(0, 0);
          first_offset[Iterator::kAdvanceRank] = 1;
          actual.add_tile_offset(first_offset);
          expected.add_tile_offset(first_offset);
        }

        actual.add_tile_offset(offset);
        expected.add_tile_offset(advance_offset);
        expected.add_pointer_offset(layout(cross_offset));
        results[case_idx * kThreads + threadIdx.x] =
            actual.get() == expected.get();
        ++case_idx;
      }
    }
  }
}

template <typename Iterator>
void test_tile_offsets(
    typename Iterator::Params const &params,
    typename Iterator::Layout const &layout) {

  cutlass::DeviceAllocation<typename Iterator::Element> storage(1 << 17);
  cutlass::DeviceAllocation<int> results(kCases * kThreads);

  check_tile_offsets<Iterator><<<1, kThreads>>>(
      params, layout, storage.get(), results.get());
  ASSERT_EQ(cudaGetLastError(), cudaSuccess);

  std::vector<int> host_results(kCases * kThreads);
  ASSERT_EQ(cudaMemcpy(
      host_results.data(), results.get(), host_results.size() * sizeof(int),
      cudaMemcpyDeviceToHost), cudaSuccess);

  for (int case_idx = 0; case_idx < kCases; ++case_idx) {
    for (int thread_id = 0; thread_id < kThreads; ++thread_id) {
      EXPECT_EQ(host_results[case_idx * kThreads + thread_id], 1)
          << "case: " << case_idx << ", thread: " << thread_id;
    }
  }
}

template <typename Element, int AdvanceRank>
void test_iterator_tile_offsets() {
  using Shape = cutlass::layout::PitchLinearShape<64, 4>;
  using Layout = cutlass::layout::PitchLinear;
  using ThreadMap =
      cutlass::transform::PitchLinearStripminedThreadMap<Shape, kThreads>;
  using AccessType = cutlass::AlignedArray<Element, 1>;
  Layout layout(1024);

  using EllIterator =
      cutlass::transform::threadblock::EllPredicatedTileAccessIterator<
          Shape, Element, Layout, AdvanceRank, ThreadMap, AccessType>;
  test_tile_offsets<EllIterator>(typename EllIterator::Params(layout), layout);

  using ThreadTileMap =
      cutlass::transform::PitchLinear2DThreadTileStripminedThreadMap<
          cutlass::layout::PitchLinearShape<64, 8>, kThreads,
          cutlass::layout::PitchLinearShape<4, 4>>;
  using ThreadTileIterator =
      cutlass::transform::threadblock::PredicatedTileAccessIterator2dThreadTile<
          cutlass::layout::PitchLinearShape<64, 8>, Element, Layout, AdvanceRank,
          ThreadTileMap, cutlass::AlignedArray<Element, 4>>;
  test_tile_offsets<ThreadTileIterator>(
      typename ThreadTileIterator::Params(layout), layout);

  using TriangularIterator = cutlass::transform::threadblock::
      PredicatedTileAccessIteratorTriangularMatrix<
          Shape, Element, Layout, AdvanceRank, ThreadMap,
          cutlass::SideMode::kLeft, cutlass::FillMode::kFull,
          cutlass::DiagType::kNonUnit, AccessType>;
  test_tile_offsets<TriangularIterator>(
      typename TriangularIterator::Params(layout, false, 0), layout);

  using AffineLayout = cutlass::layout::AffineRankN<2>;
  AffineLayout affine_layout(2, 1024);
  using AffineIterator =
      cutlass::transform::threadblock::PredicatedTileAccessIterator<
          Shape, Element, AffineLayout, AdvanceRank, ThreadMap, AccessType>;
  test_tile_offsets<AffineIterator>(
      typename AffineIterator::Params(affine_layout), affine_layout);
}

template <typename Element>
void test_iterator_tile_offsets() {
  test_iterator_tile_offsets<Element, 0>();
  test_iterator_tile_offsets<Element, 1>();
}

} // namespace

TEST(Transform_threadblock_PredicatedTileAccessIterator, TileOffsetInt8) {
  test_iterator_tile_offsets<int8_t>();
}

TEST(Transform_threadblock_PredicatedTileAccessIterator, TileOffsetInt16) {
  test_iterator_tile_offsets<int16_t>();
}

TEST(Transform_threadblock_PredicatedTileAccessIterator, TileOffsetInt32) {
  test_iterator_tile_offsets<int32_t>();
}

TEST(Transform_threadblock_PredicatedTileAccessIterator, TileOffsetDouble) {
  test_iterator_tile_offsets<double>();
}
