/******************************************************************************
* Copyright (c) 2018, NVIDIA CORPORATION.  All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are not permitted.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
******************************************************************************/

/*! \file
    \brief Tests for Host_tensor, Host_tensor_view, and Tensor_view
*/

//#include <gtest/gtest.h>
#include <cutlass_unit_test.h>
#include <tools/util/host_tensor.h>
#include <tools/util/tensor_view_io.h>

/// Random number generator
struct RandomGenerator {
    RandomGenerator(int seed = 17) {
        srand(seed);
    }

    float operator()() {
        return float(rand() % 64) / 8.0f;
    }
};

TEST(HostTensor, gemm) {

    int const M = 16;
    int const N = 16;
    int const K = 16;

    typedef cutlass::HostTensor<float, false> HostTensor;

    // allocate a host tensor
    HostTensor A(
        cutlass::make_Coord(1, K, M, 1)
    );

    HostTensor B(
        cutlass::make_Coord(1, N, K, 1)
    );

    HostTensor C(
        cutlass::make_Coord(1, N, M, 1)
    );

    A.fill_random(RandomGenerator());
    B.fill_random(RandomGenerator());

    C.gemm<float, float, float, float>(A, B, 1.0f, 0.0f);
}

