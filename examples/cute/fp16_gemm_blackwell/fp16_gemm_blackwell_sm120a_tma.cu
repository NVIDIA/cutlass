/*
 * fp16_gemm_blackwell_tma.cu
 * 
 * High-performance FP16 x FP16 GEMM using CUTE with Tensor Memory Accelerator (TMA)
 * Using RTX5070 SM120a Compilation(RTX5090 has also been tested and can be run.)
 * Kernel features:
 * - Tensor Memory Accelerator (TMA) for efficient data movement
 * - TMA Store for efficient result writeback
 * - Ping-pong double buffering for pipeline overlap
 * - Arbitrary matrix size support via padding
 * 
 * Design patterns adapted from CUTLASS library:
 * https://github.com/NVIDIA/cutlass
 * 
 * Author: Junfei Shi (@FY-26)
 * Date: 2026
 * GPU: NVIDIA Blackwell (SM120a)
 */
#include "cute/arch/copy_sm75.hpp"
#include "cute/arch/copy_sm90_desc.hpp"
#include <cstddef>
#include <cstdlib>
#include <cuda.h>
#include <cuda_runtime.h>
#include <random>
#include <stdlib.h>
#include "cute/arch/copy_sm90_desc.hpp"
#include "cute/arch/mma_sm80.hpp"
#include "cute/int_tuple.hpp"
#include "cute/layout.hpp"
#include "cute/layout_composed.hpp"
#include "cute/tensor_impl.hpp"
#include <cutlass/numeric_types.h>
#include <cute/atom/mma_traits_sm90_gmma.hpp>
#include <cute/tensor.hpp>
// TMA
#include <cute/arch/copy_sm90.hpp> 
// Make_tma_copy 
#include <cute/arch/copy_sm90_tma.hpp> 
#include <cute/arch/mma_sm90.hpp>
#include <cute/arch/mma_sm90_gmma.hpp>
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <cuda_fp16.h>
#include <iomanip>
#include <iostream>
#include <cmath>
#include <algorithm>

//High-performance FP16 GEMM CUTE kernel with TMA for Blackwell(SM120a)

///Shared memory layout structure inspired by CUTLASS examples
///Reference:https://github.com/NVIDIA/cutlass/blob/main/examples/cute/tutorial/blackwell/04_mma_tma_2sm_sm100.cu
template <class TypeA,           // Tensor A data type
          class TypeB,           // Tensor B data type
          class ASmemLayout,     // (MmaA, NumMma_M, NumMma_K, ...)
          class BSmemLayout,     // (MmaB, NumMma_N, NumMma_K, ...)
          class CSmemLayout,     // output C reuse sharememory to store
          int Stages>            //add share stages
struct SharedStorage
{
    //Added reuse of output matrix C write back to sharememory
    union {
        struct {
            alignas(128) cute::ArrayEngine<TypeA, cute::cosize_v<ASmemLayout>> A;
            alignas(128) cute::ArrayEngine<TypeB, cute::cosize_v<BSmemLayout>> B;
        };
        alignas(128) cute::ArrayEngine<TypeA, cute::cosize_v<CSmemLayout>> C;
    };
    alignas(16) cute::uint64_t mma_barrier;  // Barrier to track MMA computation on SMEM
    alignas(16) cute::uint64_t tma_barrier[Stages];  // Barrier to track TMA data transfers to SMEM
    alignas(16) cute::uint32_t tmem_base_ptr; // Base pointer for TMEM allocation

    CUTE_DEVICE constexpr auto tensor_sA() { return make_tensor(cute::make_smem_ptr(A.begin()), ASmemLayout{}); }
    CUTE_DEVICE constexpr auto tensor_sB() { return make_tensor(cute::make_smem_ptr(B.begin()), BSmemLayout{}); }
    CUTE_DEVICE constexpr auto tensor_sC() { return make_tensor(cute::make_smem_ptr(C.begin()), CSmemLayout{}); }
};

template <typename T>
__host__ __device__ constexpr int ceil_div(T x, T y) {
    return (x + y - 1) / y;
}

template <class Typea,const int TileM,const int TileN,const int TileK,typename TileMMA,typename Tma_A,typename Tma_B,typename Tma_C,typename S2R_A,typename S2R_B,class Sharedstorage,int Stages>
__global__ void Gemm_TMA(Typea* A,Typea* B,Typea* C,int M,int N,int K,int lda,int ldb,int ldc,__grid_constant__ const Tma_A tma_load_a,__grid_constant__ const Tma_B tma_load_b,__grid_constant__ const Tma_C tma_store_c,S2R_A s2r_A_atom,S2R_B s2r_B_atom){
    using namespace cute;
    int tx = threadIdx.x;
    int bx = blockIdx.x;
    int by = blockIdx.y;
    Tensor tC = make_tensor(make_gmem_ptr(C),make_shape(M,N),make_stride(ldc,Int<1>{}));
    Tensor gC = local_tile(tC,make_tile(Int<TileM>{},Int<TileN>{}),make_coord(by,bx)); 
    //TMA share
    extern __shared__ char share_memory[];  //Allocate SMEM and use char type is easy to cut Allocate SMEM
    Sharedstorage& share_storage =  *reinterpret_cast<Sharedstorage*>(share_memory); 
    Tensor sA = share_storage.tensor_sA();
    Tensor sB = share_storage.tensor_sB();
    Tensor sC = share_storage.tensor_sC();
    //TMA tensor
    Tensor tma_tensor_a = tma_load_a.get_tma_tensor(make_shape(M,K));
    Tensor tma_tensor_b = tma_load_b.get_tma_tensor(make_shape(N,K));
    Tensor tma_tensor_c = tma_store_c.get_tma_tensor(make_shape(M, N));
    Tensor gA = local_tile(tma_tensor_a,make_tile(Int<TileM>{},Int<TileK>{}),make_coord(by,_));//()
    Tensor gB = local_tile(tma_tensor_b,make_tile(Int<TileN>{},Int<TileK>{}),make_coord(bx,_));//
    Tensor tma_gC = local_tile(tma_tensor_c, make_tile(Int<128>{},Int<64>{}), make_coord(by, bx));//(row,collum)
    constexpr uint32_t SA_byte = sizeof(Typea)*size(sA);
    constexpr uint32_t SB_byte = sizeof(Typea)*size(sB);
    //Initialize TMAbarrier
    if(tx == 0){
        for(int i=0;i<Stages;++i){
            initialize_barrier(share_storage.tma_barrier[i],1);
        }
    }
    __syncthreads();
    //Set phase bit，compare it with the phase of TMAbarrier. If they are the same, it means blocking.
    int set_tma_barrier_phase[Stages] = {0}; 
    auto thr_tma_a = tma_load_a.get_thread_slice(tx);
    auto thr_tma_b = tma_load_b.get_thread_slice(tx);
    auto thr_tma_c = tma_store_c.get_thread_slice(tx);

    //MMA
    TileMMA tilemma;
    auto thr_mma = tilemma.get_thread_slice(tx);
    Tensor sA_dummy = sA(_,_,0);
    Tensor sB_dummy = sB(_,_,0);
    auto thr_gc = thr_mma.partition_C(gC);
    auto thr_sa = thr_mma.partition_A(sA_dummy);
    auto thr_sb = thr_mma.partition_B(sB_dummy);
    auto thr_sc = thr_mma.partition_C(sC);
    auto thr_ra = thr_mma.make_fragment_A(thr_sa);
    auto thr_rb = thr_mma.make_fragment_B(thr_sb);
    auto thr_rc = thr_mma.make_fragment_C(thr_gc);
    clear(thr_rc);

    //S2R copy
    TiledCopy s2r_a = make_tiled_copy_A(s2r_A_atom,tilemma);
    ThrCopy thr_s2r_a = s2r_a.get_slice(tx);
    Tensor txda = thr_s2r_a.retile_D(thr_ra);
    TiledCopy s2r_b = make_tiled_copy_B(s2r_B_atom,tilemma);
    ThrCopy thr_s2r_b = s2r_b.get_slice(tx);
    Tensor txdb = thr_s2r_b.retile_D(thr_rb);

    int count_k = size<2>(gA); //TileK_nums
    Tensor txsa_temp = thr_s2r_a.partition_S(sA(_,_,0));
    uint32_t total_bytes = (uint32_t)(size(sA(_,_,0)) * sizeof(Typea) + size(sB(_,_,0)) * sizeof(Typea));//Determine whether the data is fully transmitted
    //In order to reduce the running consumption, the tiles required by different stages are pre-segmented during the re-compilation process.
    //Use Int<0> and Int<1> to split SA 3Dlayout into a static 2D Tensor
    Tensor sA_0 = sA(_,_,Int<0>{}); //0,1 is stage1 and stage2
    Tensor sA_1 = sA(_,_,Int<1>{});
    Tensor sB_0 = sB(_,_,Int<0>{});
    Tensor sB_1 = sB(_,_,Int<1>{});
    // TMA partititon: G2S S2R
    Tensor tAsA_0 = thr_tma_a.partition_D(sA_0);
    Tensor tBsB_0 = thr_tma_b.partition_D(sB_0);
    Tensor txsa_0 = thr_s2r_a.partition_S(sA_0);
    Tensor txsb_0 = thr_s2r_b.partition_S(sB_0);
    Tensor tAsA_1 = thr_tma_a.partition_D(sA_1);
    Tensor tBsB_1 = thr_tma_b.partition_D(sB_1);
    Tensor txsa_1 = thr_s2r_a.partition_S(sA_1);
    Tensor txsb_1 = thr_s2r_b.partition_S(sB_1);

    //Prefetching stage0
    if(tx == 0) {
        cute::set_barrier_transaction_bytes(share_storage.tma_barrier[0], total_bytes);
        cute::copy(tma_load_a.with(share_storage.tma_barrier[0]), thr_tma_a.partition_S(gA(_,_,0)), tAsA_0);
        cute::copy(tma_load_b.with(share_storage.tma_barrier[0]), thr_tma_b.partition_S(gB(_,_,0)), tBsB_0);
    }
    // Wait for Stage 0 copy to be successful, and load the data of the first S2R(stage0)into the register.
    cute::wait_barrier(share_storage.tma_barrier[0], set_tma_barrier_phase[0]);
    set_tma_barrier_phase[0] ^= 1;
    cute::copy(s2r_a, txsa_0(_,_,0), txda(_,_,0));
    cute::copy(s2r_b, txsb_0(_,_,0), txdb(_,_,0));
    // ==========================================
    // Mainloop (Ping-Pong double stages)
    // Due to the impact of the space occupied by the shares of 5070 and 5090,only when there are two stages can good performance be achieved.
    // Forcing an increase in the stage number will significantly reduce the occupancy rate.
    // ==========================================
    for(int i = 0; i < count_k; i += 2) {
        //PING：prefetching Stage 1
        if(i + 1 < count_k && tx == 0) {
            cute::set_barrier_transaction_bytes(share_storage.tma_barrier[1], total_bytes);
            cute::copy(tma_load_a.with(share_storage.tma_barrier[1]), thr_tma_a.partition_S(gA(_,_,i+1)), tAsA_1);
            cute::copy(tma_load_b.with(share_storage.tma_barrier[1]), thr_tma_b.partition_S(gB(_,_,i+1)), tBsB_1);
        }
        //Compute Stage 0，
        #pragma unroll
        for(int j = 0; j < size<2>(txsa_temp); ++j) {
            if (j < size<2>(txsa_temp) - 1) {
                cute::copy(s2r_a, txsa_0(_,_,j+1), txda(_,_,j+1));
                cute::copy(s2r_b, txsb_0(_,_,j+1), txdb(_,_,j+1));
            } else {
                if (i + 1 < count_k) {
                    cute::wait_barrier(share_storage.tma_barrier[1], set_tma_barrier_phase[1]);
                    set_tma_barrier_phase[1] ^= 1;
                    cute::copy(s2r_a, txsa_1(_,_,0), txda(_,_,0)); //At last MMA_k_numbers load stage1 to register
                    cute::copy(s2r_b, txsb_1(_,_,0), txdb(_,_,0));
                }
            }
            cute::gemm(tilemma, thr_ra(_,_,j), thr_rb(_,_,j), thr_rc);
        }
        __syncthreads();

        if(i + 1 >= count_k) break;

        //PONG：prefetching Stage 0
        if(i + 2 < count_k && tx == 0) {
            cute::set_barrier_transaction_bytes(share_storage.tma_barrier[0], total_bytes);
            cute::copy(tma_load_a.with(share_storage.tma_barrier[0]), thr_tma_a.partition_S(gA(_,_,i+2)), tAsA_0);
            cute::copy(tma_load_b.with(share_storage.tma_barrier[0]), thr_tma_b.partition_S(gB(_,_,i+2)), tBsB_0);
        }
        //Compute Stage1
        #pragma unroll
        for(int j = 0; j < size<2>(txsa_temp); ++j) {
            if (j < size<2>(txsa_temp) - 1) {
                cute::copy(s2r_a, txsa_1(_,_,j+1), txda(_,_,j+1));
                cute::copy(s2r_b, txsb_1(_,_,j+1), txdb(_,_,j+1));
            } else {
                if (i + 2 < count_k) {
                    cute::wait_barrier(share_storage.tma_barrier[0], set_tma_barrier_phase[0]);
                    set_tma_barrier_phase[0] ^= 1;
                    cute::copy(s2r_a, txsa_0(_,_,0), txda(_,_,0));//At last MMA_k_numbers load stage0 to register
                    cute::copy(s2r_b, txsb_0(_,_,0), txdb(_,_,0));
                }
            }
            cute::gemm(tilemma, thr_ra(_,_,j), thr_rb(_,_,j), thr_rc);
        }
        __syncthreads();
    }
    //Epilogue store:R2S and S2G，S2R use TMA store，which enables faster write-back.
    cute::copy(thr_rc, thr_sc);
    __syncthreads();
    cute::tma_store_fence();
    Tensor tCsC = thr_tma_c.partition_S(sC);
    Tensor tCgC = thr_tma_c.partition_D(tma_gC);
    if(tx==0){
        cute::copy(tma_store_c,tCsC,tCgC);
        cute::tma_store_arrive();
        cute::tma_store_wait<0>();
    }
    __syncthreads();
}

/// \param A Input matrix A (M×K)
/// \param B Input matrix B (N×K)
/// \param C Output matrix C (M×N)
/// \param M Number of rows in A and C
/// \param N Number of columns in B and C
/// \param K Number of columns in A / rows in B
template<class Typea,int Stages>
void run_kernel(Typea* A,Typea* B,Typea* C,int M,int N,int K){
    using namespace cute;               //Don't forget using cute！！！
    using typeA = cutlass::half_t;      //Using FP16
    using typeB = cutlass::half_t;
    constexpr int TileM = 128;
    constexpr int TileN = 64;
    constexpr int TileK = 64;
    int lda = K;    //Stride
    int ldb = K;
    int ldc = N;

    //MMA descriptor
    TiledMMA MMA = make_tiled_mma(SM80_16x8x16_F16F16F16F16_TN{}, Layout<Shape<_2,_2>>{},Tile<_32,_32,_16>{});
    using mma = decltype(MMA);
    Tensor TA = make_tensor(make_gmem_ptr(A),make_shape(M,K),make_stride(lda,Int<1>{}));
    Tensor TB = make_tensor(make_gmem_ptr(B), make_shape(N,K), make_stride(ldb,Int<1>{})); //Row-major
    Tensor TC = make_tensor(make_gmem_ptr(C), make_shape(M,N), make_stride(ldc,Int<1>{})); 
    using SmemLayoutAtom = cute::GMMA::Layout_K_SW128_Atom<Typea>;
    //Using SmemLayoutAtom to avoid bankflict,so TMA transport 128 bytes at a time,we need to ensure row is 128byte
    auto SMEM_layout_A = tile_to_shape(SmemLayoutAtom{}, make_shape(Int<128>{},Int<64>{}));
    auto SMEM_layout_B = tile_to_shape(SmemLayoutAtom{}, make_shape(Int<64>{},Int<64>{}));
    auto SMEM_layout_C = tile_to_shape(SmemLayoutAtom{}, make_shape(Int<128>{}, Int<64>{}));
    //Using the layout to set  sharememory size
    auto SMEM_layout_A_pip = tile_to_shape(SmemLayoutAtom{}, make_shape(Int<128>{}, Int<64>{},Int<Stages>{}));
    auto SMEM_layout_B_pip = tile_to_shape(SmemLayoutAtom{}, make_shape(Int<64>{}, Int<64>{},Int<Stages>{}));
    //TMA descriptor
    auto TMA_load_A = cute::make_tma_copy(SM90_TMA_LOAD{},TA,SMEM_layout_A);
    auto TMA_load_B = cute::make_tma_copy(SM90_TMA_LOAD{},TB,SMEM_layout_B);
    auto TMA_store_C = cute::make_tma_copy(SM90_TMA_STORE{},TC,SMEM_layout_C);
    using TMA_load_A_type = decltype(TMA_load_A);
    using TMA_load_B_type = decltype(TMA_load_B);
    using TMA_store_C_type = decltype(TMA_store_C);
    using ShareStorage_type = SharedStorage<typeA, typeB, decltype(SMEM_layout_A_pip), decltype(SMEM_layout_B_pip),decltype(SMEM_layout_C),Stages>;
    //Copy s2r
    Copy_Atom<SM75_U32x4_LDSM_N,half_t> Copy_s2r_A;
    Copy_Atom<SM75_U32x4_LDSM_N,half_t> copy_s2r_B;
    using S2R_A_type = decltype(Copy_s2r_A);
    using S2R_B_type = decltype(copy_s2r_B);
    //Kernal parameters
    int smem_size = int(sizeof(ShareStorage_type));
    dim3 grid(N / TileN, M / TileM); //(x,y)  
    dim3 block(128);
    
    //Get template Kernel pointer inspired by CUTLASS examples
    auto kernel_ptr = Gemm_TMA<half_t, TileM, TileN, TileK, mma, TMA_load_A_type, TMA_load_B_type,TMA_store_C_type, S2R_A_type, S2R_B_type, ShareStorage_type, Stages>;
    //Unlock the 48KB limit on dynamic Shared Memory!
    cudaError_t attr_err = cudaFuncSetAttribute(
        (const void*)kernel_ptr, 
        cudaFuncAttributeMaxDynamicSharedMemorySize, 
        smem_size
    );
    if (attr_err != cudaSuccess) {
        std::cerr << "Unlock SMEM momory restrict fault: " << cudaGetErrorString(attr_err) << std::endl;
        return; // Exit
    }
    kernel_ptr<<<grid,block,smem_size>>>(A, B, C, M, N, K, lda, ldb, ldc,
                                         TMA_load_A, TMA_load_B, TMA_store_C,
                                         Copy_s2r_A, copy_s2r_B);
}

int main() {
    //After testing and considering the space limitations of shared memory, this type of tile can achieve better performance.
    constexpr int TileM = 128;
    constexpr int TileN = 64;
    constexpr int TileK = 64;
    using typea = cutlass::half_t;
    
    // CPU create
    int M = 81920;
    int N = 512;
    int K = 256;
    //If the matrix cannot be evenly divided by the set tile，use padding 0.
    int M_pad = ceil_div(M, TileM) * TileM;
    int N_pad = ceil_div(N, TileN) * TileN;
    int K_pad = ceil_div(K, TileK) * TileK;
    size_t size_A = M * K * sizeof(typea);
    size_t size_B = N * K * sizeof(typea);
    size_t size_C = M * N * sizeof(typea);
    size_t size_A_pad = size_t(M_pad) * K_pad * sizeof(typea);
    size_t size_B_pad = size_t(N_pad) * K_pad * sizeof(typea);
    size_t size_C_pad = size_t(M_pad) * N_pad * sizeof(typea);
    
    typea* h_A = (typea*)malloc(size_A);
    typea* h_B = (typea*)malloc(size_B);
    typea* h_C_custom = (typea*)malloc(size_C); // Store my Kernel results
    typea* h_C_cublas = (typea*)malloc(size_C); // Store cuBLAS results
    typea* CPU_C = (typea*)malloc(size_C);      // Store CPU run verification results(only compute output 128x128 matrix result)

    //Create Matrix(using gen 42)
    std::mt19937 gen(42);
    std::uniform_real_distribution<float> dist(-1.0f, 1.0f);
    for(int i = 0; i < M * K; ++i) h_A[i] = static_cast<typea>(dist(gen));
    for(int i = 0; i < N * K; ++i) h_B[i] = static_cast<typea>(dist(gen));
    memset(h_C_custom, 0, size_C);
    memset(h_C_cublas, 0, size_C);
    memset(CPU_C, 0, size_C);

    // Device create
    typea *d_A, *d_B, *d_C_custom, *d_C_cublas;
    cudaMalloc(&d_A, size_A_pad);
    cudaMalloc(&d_B, size_B_pad);
    cudaMalloc(&d_C_custom, size_C_pad);
    cudaMalloc(&d_C_cublas, size_C);
    cudaMemset(d_A, 0, size_A_pad);
    cudaMemset(d_B, 0, size_B_pad);
    cudaMemset(d_C_custom, 0, size_C_pad);
    cudaMemset(d_C_cublas, 0, size_C);
    cudaMemcpy2D(d_A, K_pad * sizeof(typea), h_A, K * sizeof(typea),
                 K * sizeof(typea), M, cudaMemcpyHostToDevice);
    cudaMemcpy2D(d_B, K_pad * sizeof(typea), h_B, K * sizeof(typea),
                 K * sizeof(typea), N, cudaMemcpyHostToDevice);

    // ==========================================
    // 1.Initialize cuBLAS & timer
    // ==========================================
    cublasHandle_t handle;
    cublasCreate(&handle);
    __half alpha = __float2half(1.0f);
    __half beta  = __float2half(0.0f);
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    int warmup_iters = 3;
    int test_iters = 10;
    float ms = 0.0f;
    double flops_custom = 2.0 * M_pad * N_pad * K_pad; 
    double flops_cublas = 2.0 * M * N * K;

    // ==========================================
    // 2.Testing Custom TMA GEMM Kernel
    // ==========================================
    std::cout << "------------------------------------------\n";
    std::cout << "[1] Testing Custom TMA GEMM Kernel...\n";
    for (int i = 0; i < warmup_iters; ++i) {
        run_kernel<typea, 2>(d_A, d_B, d_C_custom, M_pad, N_pad, K_pad);
    }
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    for (int i = 0; i < test_iters; ++i) {
        run_kernel<typea, 2>(d_A, d_B, d_C_custom, M_pad, N_pad, K_pad);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::cerr << "Kernel Launch Error: " << cudaGetErrorString(err) << std::endl;
        return -1;
    }
    
    cudaEventElapsedTime(&ms, start, stop);
    float custom_ms_per_iter = ms / test_iters;
    double custom_tflops = (flops_custom / (custom_ms_per_iter / 1000.0)) / 1e12;
    std::cout << "Custom time: " << custom_ms_per_iter << " ms, Performance: " << custom_tflops << " TFLOPS\n";

    // ==========================================
    // 3. Testing NVIDIA cuBLAS
    // ==========================================
    std::cout << "------------------------------------------\n";
    std::cout << "[2] Testing NVIDIA cuBLAS...\n";
    for (int i = 0; i < warmup_iters; ++i) {
        cublasHgemm(handle, CUBLAS_OP_T, CUBLAS_OP_N, N, M, K, &alpha,
                    reinterpret_cast<const __half*>(d_B), K_pad,
                    reinterpret_cast<const __half*>(d_A), K_pad, &beta,
                    reinterpret_cast<__half*>(d_C_cublas), N);
    }
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    for (int i = 0; i < test_iters; ++i) {
        cublasHgemm(handle, CUBLAS_OP_T, CUBLAS_OP_N, N, M, K, &alpha,
                    reinterpret_cast<const __half*>(d_B), K_pad,
                    reinterpret_cast<const __half*>(d_A), K_pad, &beta,
                    reinterpret_cast<__half*>(d_C_cublas), N);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&ms, start, stop);
    float cublas_ms_per_iter = ms / test_iters;
    double cublas_tflops = (flops_cublas / (cublas_ms_per_iter / 1000.0)) / 1e12;
    std::cout << "cuBLAS time: " << cublas_ms_per_iter << " ms, Performance: " << cublas_tflops << " TFLOPS\n";
    std::cout << "Performance compliance rate: " << (custom_tflops / cublas_tflops) * 100.0 << "%\n";

    // Get GPU datas(D2H)
    cudaMemcpy2D(h_C_custom, N * sizeof(typea), d_C_custom, N_pad * sizeof(typea),
                 N * sizeof(typea), M, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_C_cublas, d_C_cublas, size_C, cudaMemcpyDeviceToHost);

    // ==========================================
    // 4. testing CPU compute (Part verification 128x128)
    // ==========================================
    std::cout << "------------------------------------------\n";
    std::cout << "[3] Verification CPU float compute(128x128)...\n";
    for (int i = 0; i < 128; ++i) {
        for (int j = 0; j < 128; ++j) {
            float sum = 0.0f;
            for (int offsetk = 0; offsetk < K; ++offsetk) {
                sum += static_cast<float>(h_A[i * K + offsetk]) * static_cast<float>(h_B[j * K + offsetk]);
            }
            CPU_C[i * N + j] = static_cast<cutlass::half_t>(sum);
        }
    }
    // ==========================================
    // 5. Precision verification and Data printing
    // ==========================================
    std::cout << "------------------------------------------\n";
    std::cout << "[4] Precision verification and Data printing \n";
    // Global cuBLAS Error of accuracy
    float max_err_cublas = 0.0f;
    for (int i = 0; i < M * N; ++i) {
        float val_custom = static_cast<float>(h_C_custom[i]);
        float val_cublas = static_cast<float>(h_C_cublas[i]);
        max_err_cublas = std::max(max_err_cublas, std::abs(val_custom - val_cublas));
    }
    std::cout << "-> Global max error accurancy (Custom vs cuBLAS): " << max_err_cublas << "\n";

    // part CPU error of accuracy
    double max_err_cpu = 0.0;
    for (int i = 0; i < 128; ++i) {
        for (int j = 0; j < 128; ++j) {
            max_err_cpu = std::max(max_err_cpu, (double)std::abs(static_cast<float>(h_C_custom[i * N + j]) - static_cast<float>(CPU_C[i * N + j])));
        }
    }
    std::cout << "-> Part max error accurancy (Custom vs CPU): " << max_err_cpu << "\n\n";
    std::cout << ">>> Printing the initial 15 output values (Custom vs cuBLAS vs CPU):\n";
    std::cout << std::fixed << std::setprecision(6);
    std::cout << std::left
              << std::setw(8)  << "Index"
              << std::setw(16) << "Custom"
              << std::setw(16) << "CuBLAS"
              << std::setw(16) << "CPU"
              << std::setw(16) << "Abs Error(my-cpu)"
              << "\n";
    for (int i = 0; i < 15; i++) {
        float val_custom = static_cast<float>(h_C_custom[i]);
        float val_cublas = static_cast<float>(h_C_cublas[i]);
        float val_cpu    = static_cast<float>(CPU_C[i]);
        std::cout << std::left
                  << std::setw(8)  << i
                  << std::setw(16) << val_custom
                  << std::setw(16) << val_cublas
                  << std::setw(16) << val_cpu
                  << std::setw(16) << std::abs(val_custom - val_cpu)
                  << "\n";
    }
    //Clear
    cublasDestroy(handle);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C_custom); cudaFree(d_C_cublas);
    free(h_A); free(h_B); free(h_C_custom); free(h_C_cublas); free(CPU_C);
    return 0;
}
