#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <stdbool.h>
#define FLOAT half
#define INT int

#define CUDA_CALLER(call) do{\
  cudaError_t cuda_ret = (call);\
  if(cuda_ret != cudaSuccess){\
    printf("CUDA Error at line %d in file %s\n", __LINE__, __FILE__);\
    printf("  Error message: %s\n", cudaGetErrorString(cuda_ret));\
    printf("  In the function call %s\n", #call);\
    exit(1);\
  }\
}while(0)
#define CUDA_KERNEL_CALLER(...) do{\
  if(cudaPeekAtLastError() != cudaSuccess){\
    printf("A CUDA error occurred prior to the kernel call %s at line %d\n", #__VA_ARGS__,  __LINE__); exit(1);\
  }\
  __VA_ARGS__;\
  cudaError_t cuda_ret = cudaPeekAtLastError();\
  if(cuda_ret != cudaSuccess){\
    printf("CUDA Error at line %d in file %s\n", __LINE__, __FILE__);\
    printf("  Error message: %s\n", cudaGetErrorString(cuda_ret));\
    printf("  In the kernel call %s\n", #__VA_ARGS__);\
    exit(1);\
  }\
}while(0)

void print_matrix(const FLOAT *A, int m, int n);
void print_matrix(const float *A, int m, int n);
void randomize_matrix(FLOAT* mat, int N);
void randomize_matrix(float* mat, int N);
void randomize_matrix_plus_one(FLOAT* mat, int N);
void randomize_matrix_plus_one(float* mat, int N);
void randomize_matrix_one(FLOAT* mat, int N);
void randomize_matrix_one(float* mat, int N);
void randomize_matrix_zero(float* mat, int N);
void randomize_matrix_zero(FLOAT* mat, int N);
double get_sec();
bool verify_matrix(FLOAT *mat1, FLOAT *mat2, int n);
bool verify_matrix(float *mat1, float *mat2, int n);
void copy_matrix(FLOAT *src, FLOAT *dest, int n);
