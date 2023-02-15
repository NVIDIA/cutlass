#include <cutlass/core_io.h>
#include <cutlass/cutlass.h>
#include <cutlass/half.h>

#include <cutlass/gemm/device/gemm.h>
#include <cutlass/numeric_types.h>
#include <cutlass/util/host_tensor.h>
#include "cutlass/util/command_line.h"
#include "stdio.h"
#include "fpA_intB_gemm_template.h"


int main(int argc, const char** args){
    int M = 0;
    int N = 0;
    int K = 0;
    cutlass::CommandLine cmd(argc, args);

    cmd.get_cmd_line_argument("M", M, 1);
    cmd.get_cmd_line_argument("N", N, 1);
    cmd.get_cmd_line_argument("K", K, 1);
    
    half* input; 
    uint8_t* weight; 
    half* out;
    half* weight_scale; 

    cudaMalloc(&input, sizeof(half) * M * K); 
    cudaMalloc(&weight, sizeof(uint8_t) * K * N); 
    cudaMalloc(&out, sizeof(half) * M * N); 
    cudaMalloc(&weight_scale, sizeof(half) * K * N); 

    cudaStream_t stream; 
    cudaStreamCreate(&stream); 

    fastertransformer::CutlassFpAIntBGemmRunner<half, uint8_t> runner{}; 
    char* mixed_gemm_workspace_; 
    int mixed_gemm_ws_bytes_  = runner.getWorkspaceSize(M, N, K);
    cudaMalloc(&mixed_gemm_workspace_, mixed_gemm_ws_bytes_); 
    // mixed_gemm_workspace_ = (char*)allocator_->reMalloc(mixed_gemm_workspace_, mixed_gemm_ws_bytes_, false);

    runner.gemm(
        // reinterpret_cast<const cutlass::half_t*>(input), 
        input, 
        weight, 
        // reinterpret_cast<const cutlass::half_t*>(weight_scale), 
        // reinterpret_cast<cutlass::half_t*>(out), 
        weight_scale, 
        out, 
        M, 
        N, 
        K, 
        mixed_gemm_workspace_, 
        mixed_gemm_ws_bytes_, 
        stream
    ); 

    cudaFree(input); 
    cudaFree(weight); 
    cudaFree(out); 
    cudaFree(weight_scale); 
    cudaStreamDestroy(stream); 
    cudaFree(mixed_gemm_workspace_); 
}  
