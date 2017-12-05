/******************************************************************************
 * Copyright (c) 2011-2017, NVIDIA CORPORATION.  All rights reserved.
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

/**
 * \file gemm.cu
 * GEMM test driver
 *
 */

#include <iostream>
#include <typeinfo>
#include <random>
#include <stdint.h>

// CUBLAS GEMM API
#include <cublas_v2.h>

// Set Cutlass debug macro to enable console printing of library errors
#define DEBUG

#if defined(WMMA)
// Conditionally include WMMA headers (CUDA 9 Preview Feature)
#include <mma.h>
#endif

// Cutlass GEMM API
#include <cutlass/util/util.h>
#include <cutlass/gemm/dispatch.h>
#include <cutlass/gemm/epilogue_function.h>

// Test utilities
#include "util/command_line.h"
#include "util/half.h"
#include "util/matrix.h"
#include "util/timer.h"
#include "util/type_conversion.h"

// Dispatch routines to CUBLAS and CUTLASS
#include "cublas_dispatch.h"
#include "cutlass_dispatch.h"

/******************************************************************************
 * Globals, constants and typedefs
 ******************************************************************************/

using namespace cutlass;

/// CUBLAS handle
cublasHandle_t g_cublas_handle;

/// The device-id of the current device
int g_device_id = -1;

/// The number of timing iterations to invoke
int g_timing_iterations = -1;

/// The number of randomly-sized problems to schmoo
int g_schmoo = 0;


/******************************************************************************
 * Number generation
 ******************************************************************************/

/**
 * Simple low-integer generator
 */
struct simple_gen
{
    std::default_random_engine generator;
    std::uniform_int_distribution<int> distribution;

    /// Constructor
    simple_gen(int max) : distribution(max * -1, max)
    {}

    /// Functor
    int operator()()
    {
        return distribution(generator);
    }
};




/******************************************************************************
 * Test execution
 ******************************************************************************/


/**
 * Compute C = (alpha * A * B) + (beta * C)
 */
template <
    typename                    test_func_t,    ///< Test function type
    matrix_transform_t::kind_t  TransformA,     ///< Transformation op for matrix A
    matrix_transform_t::kind_t  TransformB,     ///< Transformation op for matrix B
    typename                    value_t,        ///< Multiplicand value type (matrices A and B)
    typename                    accum_t>        ///< Accumulator value type (matrix C and scalars)
bool test(
    int m,          ///< Height of C in rows
    int n,          ///< Width of C in columns
    int k,          ///< Width (height) of A (B)
    accum_t alpha,  ///< Multiplicand scalar
    accum_t beta)   ///< Addend scalar
{
    cudaStream_t stream = 0;

    //
    // Initialize matrices
    //

    matrix<value_t> A(
        (TransformA == matrix_transform_t::NonTranspose) ? m : k,
        (TransformA == matrix_transform_t::NonTranspose) ? k : m);

    matrix<value_t> B(
        (TransformB == matrix_transform_t::NonTranspose) ? k : n,
        (TransformB == matrix_transform_t::NonTranspose) ? n : k);

    matrix<accum_t> C(m, n);

    // initialized matrices with small values precisely representable as integers
    simple_gen a_gen(3);
    simple_gen b_gen(5);
    A.fill_random(a_gen);
    B.fill_random(b_gen);
    C.fill_ramp(0,0);

//    // Alternatively, initialize with procedural values to simplify debugging incorrect results
//    A.fill_ramp(1,2);
//    B.fill_ramp(1,1);

    // Sync to device
    A.sync_device();
    B.sync_device();
    C.sync_device();

    CUDA_PERROR(cudaPeekAtLastError());
    CUDA_PERROR(cudaDeviceSynchronize());

    //
    // Run test once with debug-synchronous enabled and check result
    //

    if (!g_schmoo) printf("\n");

    test_func_t test_func;

    C.fill_ramp(0, 0);
    C.sync_device();

    cudaError_t error = test_func(
        g_cublas_handle,
        m,
        n,
        k,
        A.d_data(),
        B.d_data(),
        C.d_data(),
        alpha,
        beta,
        stream,
        !g_schmoo).result;

    bool not_applicable = (error == cudaErrorInvalidValue);
    bool is_failed = false;
    if (not_applicable)
    {
        printf(", NA");
    }
    else
    {
        CUDA_PERROR(error);

        // Compute reference check if wont take too long on CPU
        if ((!g_schmoo) && (m * n <= 1024 * 1024))
        {
            matrix<accum_t> ref_C(m, n);
            ref_C.fill_ramp(0, 0);
            ref_C.gemm(TransformA, TransformB, alpha, A, B, beta);
            C.sync_host();

            is_failed = (C != ref_C);

            if (!g_schmoo)
            {
                if (is_failed)
                {
                    printf("FAIL, ");
                    std::ofstream file_a("a.csv");
                    A.write_matrix(file_a);
                    std::ofstream file_b("b.csv");
                    B.write_matrix(file_b);
                    std::ofstream file_d("gemm-REF.csv");
                    ref_C.write_matrix(file_d);
                    std::ofstream file_c("gemm-GPU.csv");
                    C.write_matrix(file_c);
                }
                else
                {
                    printf("PASS, ");
                }
            }
        }
        fflush(stdout);

        //
        // Warmup and timing iterations
        //

        if (g_timing_iterations > 0)
        {
            // Warmup for 1/100 of the timing iterations (minimum of 2)
            for (int i = 0; i < __NV_STD_MAX(2, (g_timing_iterations + 99) / 100); ++i)
            {
                CUDA_PERROR(test_func(
                    g_cublas_handle,
                    m,
                    n,
                    k,
                    A.d_data(),
                    B.d_data(),
                    C.d_data(),
                    alpha,
                    beta,
                    stream,
                    false).result);
            }
        }

        // Conduct timing iterations
        double elapsed_ms = 0;
        gpu_timer timer;
        timer.start();

        for (int i = 0; i < g_timing_iterations; i++)
        {
            CUDA_PERROR(test_func(
                g_cublas_handle,
                m,
                n,
                k,
                A.d_data(),
                B.d_data(),
                C.d_data(),
                alpha,
                beta,
                stream,
                false).result);
        }

        timer.stop();
        elapsed_ms += timer.elapsed_millis();
        double avg_ms = elapsed_ms / g_timing_iterations;

        // Display performance
        if (g_timing_iterations > 0)
        {
            int64_t num_flops      = (2 * int64_t(m) * int64_t(n) * int64_t(k)) + (2 * int64_t(m) * int64_t(n));
            double gflops_per_sec   = double(num_flops) / avg_ms / 1.0e6;

            if (g_schmoo)
            {
                if (is_failed)
                    printf("F");

                printf(", %.3f", gflops_per_sec);

                // Sleep for a few milliseconds to cool
                sleep_millis(10);
            }
            else
            {
                printf("Avg runtime: %.3f ms, total flops: %lld, GFLOP/s: %.2f\n",
                    avg_ms,
                    num_flops,
                    gflops_per_sec);
            }
            fflush(stdout);
        }
    }

    return is_failed;
}

/**
 * Compute C = (alpha * A * B) + (beta * C)
 */
template <
    math_operation_class_t     math_op,
    matrix_transform_t::kind_t TransformA,  ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB,  ///< Transformation op for matrix B
    typename value_t,                       ///< Multiplicand value type (matrices A and B)
    typename accum_t>                       ///< Accumulator value type (matrix C and scalars)
bool test(
    int m,          ///< Height of C in rows
    int n,          ///< Width of C in columns
    int k,          ///< Width (height) of A (B)
    accum_t alpha,  ///< Multiplicand scalar
    accum_t beta)   ///< Addend scalar
{
    uint64_t flop_base = 1ull << 41;
    int max_timing_iterations = 10000;
    int min_timing_iterations = 10;

    bool test_error = false;

    // Scale the number of timing iterations with respect to problem size (if not specified on commandline)
    if ((g_timing_iterations < 0) || g_schmoo)
    {
        uint64_t num_flops = (2 * uint64_t(m) * uint64_t(n) * uint64_t(k)) + (2 * uint64_t(m) * uint64_t(n));
        g_timing_iterations = (int) ((flop_base / sizeof(value_t)) / num_flops);

        g_timing_iterations = (int) __NV_STD_MIN(max_timing_iterations, g_timing_iterations);
        g_timing_iterations = (int) __NV_STD_MAX(min_timing_iterations, g_timing_iterations);
    }

    if (g_schmoo)
    {
        printf("%d, %d, %d, %c%c, %d, %d",
            m, n, k,
            (TransformA == matrix_transform_t::NonTranspose) ? 'n' : 't',
            (TransformB == matrix_transform_t::NonTranspose) ? 'n' : 't',
            m * n,
            g_timing_iterations);
    }
    else
    {
        printf("\n------------------------------------------------------------\n");
        printf("%dx%dx%d, GEMM_%c%c, %d C elements, %d timing iterations\n",
            m, n, k,
            (TransformA == matrix_transform_t::NonTranspose) ? 'n' : 't',
            (TransformB == matrix_transform_t::NonTranspose) ? 'n' : 't',
            m * n,
            g_timing_iterations);
    }
    fflush(stdout);

    // CUBLAS
    test_error |= test<
        cublas_gemm<gemm::tiling_strategy::Unknown, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    // CUTLASS
    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Small, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Medium, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Large, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Tall, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Wide, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    test_error |= test<
        cutlass_gemm_dispatch<gemm::tiling_strategy::Huge, math_op, TransformA, TransformB, value_t, accum_t>,
        TransformA,
        TransformB,
        value_t,
        accum_t>(m, n, k, accum_t(alpha), accum_t(beta));

    return test_error;
}




/******************************************************************************
 * Main
 ******************************************************************************/


/**
 * Main
 */
int main(int argc, const char **argv)
{
    //
    // Problem type (compiler-supplied so we don't compile everything)
    //

    // Define value_t and accum_t (multiplicand and accumulator types, respectively)
#if defined(TEST_SGEMM)
    typedef float       value_t;
    typedef float       accum_t;
    const math_operation_class_t math_op = math_operation_class_t::scalar;
#elif defined(TEST_DGEMM)
    typedef double      value_t;
    typedef double      accum_t;
    const math_operation_class_t math_op = math_operation_class_t::scalar;
#elif defined(TEST_HGEMM)
    typedef __half      value_t;
    typedef __half      accum_t;
    const math_operation_class_t math_op = math_operation_class_t::scalar;
#elif defined(TEST_IGEMM)
    typedef int8_t      value_t;
    typedef int32_t     accum_t;
    const math_operation_class_t math_op = math_operation_class_t::scalar;
#elif defined(TEST_WGEMM)
    typedef half        value_t;
    typedef float       accum_t;
    const math_operation_class_t math_op = math_operation_class_t::matrix;
#else
    #error Unknown GEMM type requested.
#endif


    // Define transpose constants
#ifdef TRANSPOSE_A
    static const matrix_transform_t::kind_t TransformA = matrix_transform_t::Transpose;
#else
    static const matrix_transform_t::kind_t TransformA = matrix_transform_t::NonTranspose;
#endif

#ifdef TRANSPOSE_B
    static const matrix_transform_t::kind_t TransformB = matrix_transform_t::Transpose;
#else
    static const matrix_transform_t::kind_t TransformB = matrix_transform_t::NonTranspose;
#endif


    //
    // Commandline parsing
    //

    // Initialize command line
    command_line args(argc, argv);

    int m_factor    = args.device_prop.multiProcessorCount * 128;
    int m           = round_nearest(4096, m_factor);
    int k           = 4096;
    int n           = 4096;
    float alpha     = 1.0;
    float beta      = 0.0;

    g_device_id = args.device_id;
    args.get_cmd_line_argument("m", m);
    args.get_cmd_line_argument("n", n);
    args.get_cmd_line_argument("k", k);
    args.get_cmd_line_argument("i", g_timing_iterations);
    args.get_cmd_line_argument("alpha", alpha);
    args.get_cmd_line_argument("beta", beta);
    args.get_cmd_line_argument("schmoo", g_schmoo);

    // Print usage
    if (args.check_cmd_line_flag("help"))
    {
        printf("%s "
            "[--help] "
            "[--i=<timing iterations>] "
            "[--device=<device-id>] "
            "[--alpha=<alpha> --beta=<beta>] "
            "[--schmoo=<samples> || --m=<height> --n=<width> --k=<depth>]"
            "\n", argv[0]);
        exit(0);
    }

    // Initialize cuBLAS
    if (cublasCreate(&g_cublas_handle) != CUBLAS_STATUS_SUCCESS)
    {
        fprintf(stderr, "cublasCreate() failed\n");
        exit(1);
    }

    bool test_error = false;

    if (g_schmoo)
    {
        // Run a schmoo of problem sizes
        printf("M, N, K, transpose, total_flops, timing_iterations, sol_flop/s, cublas_sol, cutlass_small_sol, cutlass_med_sol, cutlass_large_sol, cutlass_tall_sol, cutlass_wide_sol, cutlass_huge_sol\n");

        // Generate power-law distribution from [32, 16384)
        std::mt19937 gen(0);
        std::uniform_real_distribution<float> dis(5, 14);
        for (int i = 0; i < g_schmoo; ++i)
        {
        	int m = int(pow(float(2), dis(gen)));
        	int n = int(pow(float(2), dis(gen)));
        	int k = int(pow(float(2), dis(gen)));

        	// Round m and n to nearest multiple of 32 if < 128, otherwise to the nearest 128
        	m = (m < 128) ?
        			round_nearest(m, 32) :
        			round_nearest(m, 128);
        	n = (n < 128) ?
        			round_nearest(n, 32) :
        			round_nearest(n, 128);

        	// Round k to the nearest 16
            k = (sizeof(value_t) == 1) ?
                round_nearest(k, 32) :
                round_nearest(k, 16);

        	test_error |= test<math_op, TransformA, TransformB, value_t, accum_t>(
                m, n, k,
                from_float<accum_t>(alpha),
                from_float<accum_t>(beta));

        	printf("\n"); fflush(stdout);
        }
    }
    else
    {
        // Test a single GEMM problem size
        test_error |= test<math_op, TransformA, TransformB, value_t, accum_t>(
            m,
            n,
            k,
            from_float<accum_t>(alpha),
            from_float<accum_t>(beta));
    }

    // Cleanup
    cublasDestroy(g_cublas_handle);

    return test_error;
}

