/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
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
#include <cutlass_unit_tests.h>
#include <tools/util/host_tensor.h>
#include <tools/util/tensor_view_io.h>
#include <cutlass/gemm/gemm.h>
#include <cutlass/shape.h>
#include <cutlass/gemm/sgemm_traits.h>
#include <cutlass/gemm/dgemm_traits.h>
#include <cutlass/gemm/hgemm_traits.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace test {

    // M/N/K struct.
    struct GemmDesc { 
      int m, n, k; 
      inline __host__ __device__ GemmDesc(int m_, int n_, int k_) : m(m_), n(n_), k(k_) {} 
    };

 /// Simple test to load from global memory and store to shared memory

    // Loading from global memory and storing to shared memory for A
    template <typename Traits>
    __global__ void gemm_load_global_store_shared_a(
        typename Traits::GlobalLoadStreamA::Scalar *output,
        typename Traits::GlobalLoadStreamA::Scalar const *input,
        int M,
        int N,
        int K,
        int ldm,
        int skew) {

        //Create shared memory.
        __shared__ typename Traits::SharedStorage shared_storage;

        // Create those iterators.
        typedef typename Traits::GlobalLoadStreamA GlobalLoadStreamA;

        typename GlobalLoadStreamA::Params global_load_params;
        GemmDesc desc(M, N, K);
        global_load_params.initialize(desc, input, ldm);

        GlobalLoadStreamA stream_a(global_load_params, shared_storage.main_loop.stream_a.global, M, N, K, cutlass::make_Coord(0, 0, 0));
        stream_a.copy();
        stream_a.commit();

        // store barrier
        __syncthreads();

        // one thread writes everything out
        if (threadIdx.x == 0) {
            for (int i = 0; i < (M+skew)*K; ++i) {
                output[i] = shared_storage.main_loop.stream_a.shared.scalars[i];
            }
        }

    }

    // Loading from global memory and storing to shared memory for B
    template <typename Traits>
    __global__ void gemm_load_global_store_shared_b(
        typename Traits::GlobalLoadStreamB::Scalar *output,
        typename Traits::GlobalLoadStreamB::Scalar const *input,
        int M,
        int N,
        int K,
        int ldm,
        int skew) {

        //Create shared memory.
        __shared__ typename Traits::SharedStorage shared_storage;

        // Create those iterators.
        typedef typename Traits::GlobalLoadStreamB GlobalLoadStreamB;
        typename GlobalLoadStreamB::Params global_load_params;
        GemmDesc desc(M, N, K);
        global_load_params.initialize(desc, input, ldm);

        GlobalLoadStreamB stream_b(global_load_params, shared_storage.main_loop.stream_b.global, M, N, K, cutlass::make_Coord(0, 0, 0));
        stream_b.copy();
        stream_b.commit();

        // store barrier
        __syncthreads();

        // one thread writes everything out
        if (threadIdx.x == 0) {
            for (int i = 0; i < (N+skew)*K; ++i) {
                output[i] = shared_storage.main_loop.stream_b.shared.scalars[i];
            }
        }

    }

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, A_float_contiguous) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::SgemmTraits<cutlass::MatrixLayout::kColumnMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            SgemmTraits;

    
    cutlass::HostTensor<float> input;
    cutlass::HostTensor<float> output;
    int skew = 0;

    input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);
    output.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);


    input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kW, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_a< SgemmTraits ><<<
        dim3(1,1,1),
        dim3(SgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        M,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";


    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, A_float_crosswise) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::SgemmTraits<cutlass::MatrixLayout::kRowMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            SgemmTraits;

    
    cutlass::HostTensor<float> input;
    cutlass::HostTensor<float> output;
    int skew = 4;

    input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kRowMajor);
    output.resize_matrix(ThreadBlockTile::kW + skew, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);


    input.fill_linear(cutlass::make_Coord(1, ThreadBlockTile::kD, 1, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_a< SgemmTraits ><<<
        dim3(1,1,1),
        dim3(SgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));

}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, B_float_contiguous) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::SgemmTraits<cutlass::MatrixLayout::kColumnMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            SgemmTraits;

    
    cutlass::HostTensor<float> input;
    cutlass::HostTensor<float> output;
    int skew = 0;

    input.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);
    output.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);


    input.fill_linear(cutlass::make_Coord(1, ThreadBlockTile::kH, 1, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_b< SgemmTraits ><<<
        dim3(1,1,1),
        dim3(SgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        N,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";


    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, B_float_crosswise) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::SgemmTraits<cutlass::MatrixLayout::kColumnMajor,
            cutlass::MatrixLayout::kColumnMajor, ThreadBlockTile >
            SgemmTraits;

    
    cutlass::HostTensor<float> input;
    cutlass::HostTensor<float> output;
    int skew = 4;

    input.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kColumnMajor);
    output.resize_matrix(ThreadBlockTile::kD + skew, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);


    input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kD, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_b< SgemmTraits ><<<
        dim3(1,1,1),
        dim3(SgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, A_double_contiguous) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::DgemmTraits<cutlass::MatrixLayout::kColumnMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            DgemmTraits;

    
    cutlass::HostTensor<double> input;
    cutlass::HostTensor<double> output;
    int skew = 0;

    input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);
    output.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);


    input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kW, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_a< DgemmTraits ><<<
        dim3(1,1,1),
        dim3(DgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        M,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";


    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, A_double_crosswise) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::DgemmTraits<cutlass::MatrixLayout::kRowMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            DgemmTraits;

    
    cutlass::HostTensor<double> input;
    cutlass::HostTensor<double> output;
    int skew = 2;

    input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kRowMajor);
    output.resize_matrix(ThreadBlockTile::kW + skew, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);


    input.fill_linear(cutlass::make_Coord(1, ThreadBlockTile::kD, 1, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_a< DgemmTraits ><<<
        dim3(1,1,1),
        dim3(DgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));

}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, B_double_contiguous) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::DgemmTraits<cutlass::MatrixLayout::kColumnMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            DgemmTraits;

    
    cutlass::HostTensor<double> input;
    cutlass::HostTensor<double> output;
    int skew = 0;

    input.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);
    output.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);


    input.fill_linear(cutlass::make_Coord(1, ThreadBlockTile::kH, 1, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_b< DgemmTraits ><<<
        dim3(1,1,1),
        dim3(DgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        N,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";


    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, B_double_crosswise) {

    static int const M = 64;
    static int const N = 64;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::DgemmTraits<cutlass::MatrixLayout::kColumnMajor,
            cutlass::MatrixLayout::kColumnMajor, ThreadBlockTile >
            DgemmTraits;

    
    cutlass::HostTensor<double> input;
    cutlass::HostTensor<double> output;
    int skew = 2;

    input.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kColumnMajor);
    output.resize_matrix(ThreadBlockTile::kD + skew, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);


    input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kD, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_b< DgemmTraits ><<<
        dim3(1,1,1),
        dim3(DgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, A_half_crosswise) {

    static int const M = 128;
    static int const N = 128;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::HgemmTraits<cutlass::MatrixLayout::kRowMajor, cutlass::MatrixLayout::kRowMajor, ThreadBlockTile >
            HgemmTraits;

    
    cutlass::HostTensor<cutlass::half_t> input;
    cutlass::HostTensor<cutlass::half_t> output;
    int skew = 8;

    input.resize_matrix(ThreadBlockTile::kW, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kRowMajor);
    output.resize_matrix(ThreadBlockTile::kW + skew, ThreadBlockTile::kD,
            cutlass::MatrixLayout::kColumnMajor);


    input.fill_linear(cutlass::make_Coord(1, ThreadBlockTile::kD, 1, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_a< HgemmTraits ><<<
        dim3(1,1,1),
        dim3(HgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();
    
    EXPECT_TRUE(input.bit_equals(output));

}

////////////////////////////////////////////////////////////////////////////////////////////////////
TEST(GemmSharedMemLayout, B_half_crosswise) {

    static int const M = 128;
    static int const N = 128;
    static int const K = 8;

    typedef cutlass::Shape<K, N, M> ThreadBlockTile;

    typedef cutlass::gemm::HgemmTraits<cutlass::MatrixLayout::kColumnMajor,
            cutlass::MatrixLayout::kColumnMajor, ThreadBlockTile >
            HgemmTraits;

    
    cutlass::HostTensor<cutlass::half_t> input;
    cutlass::HostTensor<cutlass::half_t> output;
    int skew = 8;

    input.resize_matrix(ThreadBlockTile::kD, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kColumnMajor);
    output.resize_matrix(ThreadBlockTile::kD + skew, ThreadBlockTile::kH,
            cutlass::MatrixLayout::kRowMajor);


    input.fill_linear(cutlass::make_Coord(1, 1, ThreadBlockTile::kD, 1));

    output.fill(0);

    test::gemm_load_global_store_shared_b< HgemmTraits ><<<
        dim3(1,1,1),
        dim3(HgemmTraits::kThreads, 1)
    >>>(
        output.device_data(),
        input.device_data(),
        M,
        N,
        K,
        K,
        skew
    );

    cudaError_t result = cudaDeviceSynchronize();
    ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
                                 << "\n";

    output.sync_host();

    EXPECT_TRUE(input.bit_equals(output));
}

////////////////////////////////////////////////////////////////////////////////////////////////////
}

