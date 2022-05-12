#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <sys/time.h>
#include "utils.cuh"
#include <cuda_fp16.h>
#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/functional.h"
#include "customized_device_gemm.h"


#define DEBUG 1


cudaError_t CutlassHgemmNN(
  int M,
  int N,
  int K,
  half alpha,
  half const *A,
  int lda,
  half const *B,
  int ldb,
  half beta,
  half *C,
  int ldc) {

  using ColumnMajor = cutlass::layout::ColumnMajor;
  using RowMajor = cutlass::layout::RowMajor;
  using MMAOp = cutlass::arch::OpClassTensorOp;
  using SmArch = cutlass::arch::Sm80;
  using ShapeMMAThreadBlock = cutlass::gemm::GemmShape<128, 128, 32>;  // <- threadblock tile M = 128, N = 128, K = 32
  using ShapeMMAWarp = cutlass::gemm::GemmShape<64, 64, 32>;  // <- warp tile M = 64, N = 64, K = 32
  using ShapeMMAOp = cutlass::gemm::GemmShape<16, 8, 16>;  // <- MMA Op tile M = 16, N = 8, K = 8
  using SwizzleThreadBlock = cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>;  // <- ??
  using EpilogueOp = cutlass::epilogue::thread::LinearCombination<
      cutlass::half_t,                                     // <- data type of output matrix
      128 / cutlass::sizeof_bits<cutlass::half_t>::value,  // <- the number of elements per vectorized
                                                        // memory access. For a byte, it's 16
                                                        // elements. This becomes the vector width of
                                                        // math instructions in the epilogue too
      cutlass::half_t,                                            // <- data type of accumulator
      cutlass::half_t>;                                           // <- data type for alpha/beta in linear combination function
  constexpr int NumStages = 4;
  using CutlassGemm = cutlass::gemm::device::Gemm<cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  MMAOp,
                                                  SmArch,
                                                  ShapeMMAThreadBlock,
                                                  ShapeMMAWarp,
                                                  ShapeMMAOp,
                                                  EpilogueOp,
                                                  SwizzleThreadBlock,
                                                  NumStages>;

  CutlassGemm gemm_operator;
  cutlass::gemm::GemmCoord problem_size(M, N, K);
  typename CutlassGemm::Arguments args{problem_size,  // Gemm Problem dimensions
                              {(cutlass::half_t*)A, lda},    // Tensor-ref for source matrix A
                              {(cutlass::half_t*)B, ldb},    // Tensor-ref for source matrix B
                              {(cutlass::half_t*)C, ldc},    // Tensor-ref for source matrix C
                              {(cutlass::half_t*)C, ldc},    // Tensor-ref for destination matrix D (may be different memory than source C matrix)
                              {(cutlass::half_t)alpha, (cutlass::half_t)beta}, // Scalars used in the Epilogue
                              1};// split_k_slices
  cutlass::Status status = gemm_operator(args);
  if (status != cutlass::Status::kSuccess) {
    return cudaErrorUnknown;
  }
  return cudaSuccess;
}


cudaError_t CutlassHgemmWithFusedPrologue(
  int M,
  int N,
  int K,
  half alpha,
  half const *A,
  int lda,
  half const *B,
  int ldb,
  half beta,
  half *C,
  int ldc,
  half* gamma_vec,
  half* beta_vec) {

  using ColumnMajor = cutlass::layout::ColumnMajor;
  using RowMajor = cutlass::layout::RowMajor;
  using MMAOp = cutlass::arch::OpClassTensorOp;
  using SmArch = cutlass::arch::Sm80;
  using ShapeMMAThreadBlock = cutlass::gemm::GemmShape<128, 128, 32>;  // <- threadblock tile M = 128, N = 128, K = 32
  using ShapeMMAWarp = cutlass::gemm::GemmShape<64, 64, 32>;  // <- warp tile M = 64, N = 64, K = 32
  using ShapeMMAOp = cutlass::gemm::GemmShape<16, 8, 16>;  // <- MMA Op tile M = 16, N = 8, K = 8
  using SwizzleThreadBlock = cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>;  // <- ??
  using EpilogueOp = cutlass::epilogue::thread::LinearCombination<
      cutlass::half_t,                                     // <- data type of output matrix
      128 / cutlass::sizeof_bits<cutlass::half_t>::value,  // <- the number of elements per vectorized
                                                        // memory access. For a byte, it's 16
                                                        // elements. This becomes the vector width of
                                                        // math instructions in the epilogue too
      cutlass::half_t,                                            // <- data type of accumulator
      cutlass::half_t>;                                           // <- data type for alpha/beta in linear combination function
  constexpr int NumStages = 4;
  using CutlassGemm = cutlass::gemm::device::CustomizedGemm<cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  ColumnMajor,
                                                  cutlass::half_t,
                                                  MMAOp,
                                                  SmArch,
                                                  ShapeMMAThreadBlock,
                                                  ShapeMMAWarp,
                                                  ShapeMMAOp,
                                                  EpilogueOp,
                                                  SwizzleThreadBlock,
                                                  NumStages>;

  CutlassGemm gemm_operator;
  cutlass::gemm::GemmCoord problem_size(M, N, K);
  typename CutlassGemm::Arguments args{problem_size,  // Gemm Problem dimensions
                              {(cutlass::half_t*)A, lda},    // Tensor-ref for source matrix A
                              {(cutlass::half_t*)B, ldb},    // Tensor-ref for source matrix B
                              {(cutlass::half_t*)C, ldc},    // Tensor-ref for source matrix C
                              {(cutlass::half_t*)C, ldc},    // Tensor-ref for destination matrix D (may be different memory than source C matrix)
                              (cutlass::half_t*)gamma_vec,
                              (cutlass::half_t*)beta_vec,
                              {(cutlass::half_t)alpha, (cutlass::half_t)beta}, // Scalars used in the Epilogue
                              1};// split_k_slices
  cutlass::Status status = gemm_operator(args);
  if (status != cutlass::Status::kSuccess) {
    return cudaErrorUnknown;
  }
  return cudaSuccess;
}


/*

C(m*n) = A(m*k) * B(k*n);

m: batch number * seq len; {100:100:1000} x {32, 64}
n = k = feature size = 512 or 768

C layer norm on the feature dim.

E(m*4k) = C(m*k) * D(k*4k);

fused implementation - 
non fused implementation perf - 

*/

#define B(i, j) B[i + (j)*LDB]//colmajor

/*
 *
 * B = (B - mean) *rev_mean_sqr * gamma + beta
 *
 */

// void cpu_prologue_mat(int M, int N, int LDB, FLOAT *B, FLOAT *mean_vec, FLOAT *rev_mean_sqr_vec, FLOAT *beta, FLOAT *gamma) {
//   for (int i = 0; i < M; i++) {
//     for (int j = 0; j < N; j++) {
//       B(i, j) = (FLOAT)(((float)B(i, j) - (float)mean_vec[j])  * (float)rev_mean_sqr_vec[j] * (float)gamma[i] + (float)beta[i]  );
//     }
//   }
// }

void cpu_prologue_mat(int M, int N, int LDB, FLOAT *B, FLOAT *beta, FLOAT *gamma) {
  for (int i = 0; i < M; i++) {
    for (int j = 0; j < N; j++) {
      B(i, j) = (FLOAT)( (float)B(i, j) * (float)gamma[i] + (float)beta[i] );
    }
  }
}

int main(int argc, char **argv){
    int m, n, k;
    
    if (argc == 4) {
      m = atoi(argv[1]);n = atoi(argv[2]);k = atoi(argv[3]);
    }else if (argc == 2) {
      n = atoi(argv[1]); k = 768; m = k * 4; // leading_dim = 4 * hidden_dim
    }else {
      printf("adopt the default input.\n");
      m = 3072, n = 6144, k = 768;
    }

    int n_block = (n + 128 - 1) / 128;

    // ensure m/n/k are all divisible by warp-mma dims - 16 should be safe here.
    m = m & -15; n = n & -15; k = k & -15;

    printf("m = %d, n = %d, k = %d, n_block = %d.\n", m, n, k, n_block);
    FLOAT *A=NULL;
    FLOAT *B=NULL;
    FLOAT *C=NULL;
    FLOAT *C_ref = NULL;
    
    FLOAT *dA=NULL;
    FLOAT *dB=NULL;
    FLOAT *dB_fused=NULL;
    FLOAT *dC=NULL;
    FLOAT *dC_ref=NULL;
    FLOAT alpha = 1, beta = 0;
    FLOAT *mean_vec, *mean_square_vec;
    FLOAT *vec_gamma, *vec_beta;


    FLOAT *dtensor_Reduction, *dtensor_Reduction_Square;
    FLOAT *d_vec_gamma;
    FLOAT *d_vec_beta;

    float elapsed_time1, elapsed_time2;
    cudaEvent_t beg, end;
    cudaEventCreate(&beg);
    cudaEventCreate(&end);

    A=(FLOAT *)malloc(sizeof(FLOAT)*m*k);
    B=(FLOAT *)malloc(sizeof(FLOAT)*k*n);
    C=(FLOAT *)malloc(sizeof(FLOAT)*m*n);
    C_ref=(FLOAT *)malloc(sizeof(FLOAT)*m*n);
    
    int mn = (m < n) ? n : m;
    mn = (mn < k) ? k : mn;

    mean_vec=(FLOAT *)malloc(sizeof(FLOAT)*mn*n_block);
    mean_square_vec=(FLOAT *)malloc(sizeof(FLOAT)*mn*n_block);
    vec_gamma=(FLOAT *)malloc(sizeof(FLOAT)*mn*1);
    vec_beta=(FLOAT *)malloc(sizeof(FLOAT)*mn*1);
    randomize_matrix(A,m*k);
    randomize_matrix_plus_one(B,k*n);
    randomize_matrix(C,m*n);
    
    randomize_matrix(mean_vec, mn*1);
    randomize_matrix(mean_square_vec, mn*1);
    randomize_matrix_plus_one(vec_beta, mn*1);
    randomize_matrix_plus_one(vec_gamma, mn*1);
    
    copy_matrix(C, C_ref, m*n);

    CUDA_CALLER(cudaMalloc((void**) &dA, sizeof(FLOAT)*m*k));
    CUDA_CALLER(cudaMalloc((void**) &dB, sizeof(FLOAT)*k*n));
    CUDA_CALLER(cudaMalloc((void**) &dB_fused, sizeof(FLOAT)*k*n));
    CUDA_CALLER(cudaMalloc((void**) &dC, sizeof(FLOAT)*m*n));
    CUDA_CALLER(cudaMalloc((void**) &dC_ref, sizeof(FLOAT)*m*n));

    CUDA_CALLER(cudaMalloc((void**) &dtensor_Reduction, sizeof(FLOAT)*mn*n_block));
    CUDA_CALLER(cudaMalloc((void**) &dtensor_Reduction_Square, sizeof(FLOAT)*mn*n_block));
    CUDA_CALLER(cudaMalloc((void**) &d_vec_beta, sizeof(FLOAT)*mn*1));
    CUDA_CALLER(cudaMalloc((void**) &d_vec_gamma, sizeof(FLOAT)*mn*1));

    CUDA_CALLER(cudaMemcpy(dA, A, sizeof(FLOAT)*m*k, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(dB, B, sizeof(FLOAT)*k*n, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(dC, C, sizeof(FLOAT)*m*n, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(dC_ref, C_ref, sizeof(FLOAT)*m*n, cudaMemcpyHostToDevice));

    CUDA_CALLER(cudaMemcpy(d_vec_beta, vec_beta, sizeof(FLOAT)*mn*1, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(d_vec_gamma, vec_gamma, sizeof(FLOAT)*mn*1, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(dtensor_Reduction, mean_vec, sizeof(FLOAT)*mn*n_block, cudaMemcpyHostToDevice));
    CUDA_CALLER(cudaMemcpy(dtensor_Reduction_Square, mean_square_vec, sizeof(FLOAT)*mn*n_block, cudaMemcpyHostToDevice));


    // cpu_prologue_mat(k, n, k, B, mean_vec, mean_square_vec, vec_beta, vec_gamma);
    cpu_prologue_mat(k, n, k, B, vec_beta, vec_gamma);

    CUDA_CALLER(cudaMemcpy(dB_fused, B, sizeof(FLOAT)*k*n, cudaMemcpyHostToDevice));

    CUDA_CALLER(cudaEventRecord(beg));

    CUDA_CALLER(CutlassHgemmNN(
        m, n, k,
        alpha,
        dA, m,
        dB_fused, k,
        beta,
        dC, m
    ));

    cudaEventRecord(end);
    cudaEventSynchronize(beg);
    cudaEventSynchronize(end);
    cudaEventElapsedTime(&elapsed_time1, beg, end);
    printf("Average elasped original time: %f ms, performance: %f TFLOPS.\n", elapsed_time1,2.*1e-9*m*n*k/elapsed_time1);
    
    CUDA_CALLER(cudaEventRecord(beg));

    CUDA_CALLER(CutlassHgemmWithFusedPrologue(
      m, n, k,
      alpha,
      dA, m,
      dB, k,
      beta,
      dC_ref, m,
      d_vec_gamma,
      d_vec_beta
    ));

    CUDA_CALLER(cudaEventRecord(end));
    CUDA_CALLER(cudaEventSynchronize(beg));
    CUDA_CALLER(cudaEventSynchronize(end));
    cudaEventElapsedTime(&elapsed_time2, beg, end);

    printf("Average elasped fused time: %f ms, performance: %f TFLOPS.\n", elapsed_time2,2.*1e-9*m*n*k/elapsed_time2);

    printf("prologue fusion overhead = %5.2f %%.\n", (elapsed_time2 - elapsed_time1) / elapsed_time2 * 100);

    CUDA_CALLER(cudaMemcpy(C, dC, sizeof(FLOAT)*m*n, cudaMemcpyDeviceToHost));
    CUDA_CALLER(cudaMemcpy(C_ref, dC_ref, sizeof(FLOAT)*m*n, cudaMemcpyDeviceToHost));
    
    printf("******** validating C ********\n");
    if (verify_matrix(C, C_ref, m*n)) {
      printf("result is correct.\n");
    }

    cudaDeviceSynchronize();
    free(A);free(B);free(C);free(C_ref);free(vec_beta);free(vec_gamma);
    free(mean_vec);free(mean_square_vec);
    cudaFree(dA);cudaFree(dB);cudaFree(dC);cudaFree(dC_ref);
    cudaFree(dtensor_Reduction);cudaFree(dtensor_Reduction_Square);
    cudaFree(dB_fused);cudaFree(d_vec_beta);cudaFree(d_vec_gamma);

    cudaDeviceSynchronize();
    return 0;
}
