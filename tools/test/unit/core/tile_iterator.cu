/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright notice, this list of
 *     conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice, this list of
 *     conditions and the following disclaimer in the documentation and/or other materials
 *     provided with the distribution.
 *   * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *     to endorse or promote products derived from this software without specific prior written
 *     permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#include <cutlass_unit_test.h>
#include <tools/util/host_tensor.h>
#include <tools/util/tensor_view_io.h>
#include <cutlass/shape.h>
#include <cutlass/predicate_vector.h>
#include <cutlass/tile_iterator.h>
#include <cutlass/tile_traits_standard.h>
#include <cutlass/iterator_access.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace test {

  template <typename Traits, typename Scalar>
  __global__ void load_store_global(
        typename cutlass::TileLoadIterator<Traits, Scalar, cutlass::IteratorAdvance::kH,
        cutlass::MemorySpace::kGlobal>::Scalar const *input,
        typename cutlass::TileStoreIterator<Traits, Scalar, cutlass::IteratorAdvance::kH,
        cutlass::MemorySpace::kGlobal>::Scalar *output
      ) {

    typedef cutlass::TileLoadIterator<Traits, Scalar, cutlass::IteratorAdvance::kH, cutlass::MemorySpace::kGlobal> LoadIterator;
    typedef cutlass::TileStoreIterator<Traits, Scalar, cutlass::IteratorAdvance::kH, cutlass::MemorySpace::kGlobal> StoreIterator;

    typename LoadIterator::Params load_params;
    typename StoreIterator::Params store_params;

    typedef typename Traits::Tile Tile;

    load_params.initialize(input, Tile::kH*Tile::kW, Tile::kW, 1);
    store_params.initialize(output, Tile::kH*Tile::kW, Tile::kW, 1);

    LoadIterator load_iterator(load_params);
    StoreIterator store_iterator(store_params);

    typename LoadIterator::Fragment fragment;

    load_iterator.load(fragment);
    store_iterator.store(fragment);
  }

////////////////////////////////////////////////////////////////////////////////////////////////////

TEST(TileIterator, tile_128x8_contiguous) {

  static int const M = 128;
  static int const N = 1;
  static int const K = 8;

  static int const kThreads = M;

  typedef cutlass::Shape<K, N, M> ThreadBlockTile;

  typedef cutlass::TileTraitsStandard<cutlass::Shape<N, K, M>, kThreads> Traits;

  cutlass::HostTensor<float> input;
  cutlass::HostTensor<float> output;

  input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
      cutlass::MatrixLayout::kColumnMajor);

  output.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
      cutlass::MatrixLayout::kColumnMajor);

  input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kW, 1));
  output.fill(0);

  test::load_store_global< Traits, float ><<<
    dim3(1,1,1),
    dim3(kThreads, 1)
  >>>(
    input.device_data(),
    output.device_data()
  );

  cudaError_t result = cudaDeviceSynchronize();
  ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                 << "\n";
  output.sync_host();

  EXPECT_TRUE(input.bit_equals(output));

}
////////////////////////////////////////////////////////////////////////////////////////////////////

TEST(TileIterator, tile_128x8_rake) {

  static int const M = 128;
  static int const N = 1;
  static int const K = 8;

  static int const kThreads = 32;

  typedef cutlass::Shape<K, N, M> ThreadBlockTile;

  typedef cutlass::TileTraitsStandard<cutlass::Shape<N, K, M>, kThreads> Traits;

  cutlass::HostTensor<float> input;
  cutlass::HostTensor<float> output;

  input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
      cutlass::MatrixLayout::kColumnMajor);

  output.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
      cutlass::MatrixLayout::kColumnMajor);

  input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kW, 1));
  output.fill(0);

  test::load_store_global< Traits, float ><<<
    dim3(1,1,1),
    dim3(kThreads, 1)
  >>>(
    input.device_data(),
    output.device_data()
  );

  cudaError_t result = cudaDeviceSynchronize();
  ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                 << "\n";

  output.sync_host();

  EXPECT_TRUE(input.bit_equals(output));

}
////////////////////////////////////////////////////////////////////////////////////////////////////
}

