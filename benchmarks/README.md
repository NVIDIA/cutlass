# Benchmarks

```
cd cutlass-fork/build/
```

## Compiling GEMM benchmarks with CUDA backend
```
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=OFF -DDPCPP_SYCL_TARGET=nvptx64_nvidia_cuda -DDPCPP_SYCL_ARCH=sm_80 -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja cutlass_benchmarks_gemm_cuda
./benchmarks/gemm/cutlass_benchmarks_gemm_cuda --config_file=../benchmarks/device/ampere/input_files/input_gemm.in
```

## Compiling and Running GEMM benchmarks with default configurations with CUDA backend
```
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=OFF -DDPCPP_SYCL_TARGET=nvptx64_nvidia_cuda -DDPCPP_SYCL_ARCH=sm_80 -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja benchmarks_gemm_cuda
```

## Compiling GEMM benchmarks with Intel Xe backend
```
# Choose DPCPP_SYCL_TARGET from 
# target = intel_gpu_pvc | intel_gpu_bmg_g21
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=$target -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja cutlass_benchmarks_gemm_sycl
./benchmarks/gemm/cutlass_benchmarks_gemm --config_file=../benchmarks/device/pvc/input_files/input_gemm.in
```

## Compiling and Running GEMM benchmarks with default configurations with Intel Xe backend
```
# Choose DPCPP_SYCL_TARGET from 
# target = intel_gpu_pvc | intel_gpu_bmg_g21
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=$target -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja benchmarks_gemm_sycl
```

## Compiling Flash Attention v2 benchmarks with Intel Xe backend
```
# Choose DPCPP_SYCL_TARGET from 
# target = intel_gpu_pvc | intel_gpu_bmg_g21
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=$target -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja cutlass_benchmarks_flash_attention_prefill
./benchmarks/flash_attention/flash_attention_prefill/cutlass_benchmarks_flash_attention_prefill_xe --config_file=../benchmarks/device/pvc/input_files/input_flash_attention_prefill.in
```

## Compiling and Running Flash Attention v2 benchmarks with default configurations with Intel Xe backend
```
# Choose DPCPP_SYCL_TARGET from 
# target = intel_gpu_pvc | intel_gpu_bmg_g21
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=$target -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja benchmarks_flash_attention_prefill
```

## Compiling and Running all benchmarks with default configurations with Intel Xe backend
```
# Choose DPCPP_SYCL_TARGET from 
# target = intel_gpu_pvc | intel_gpu_bmg_g21
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DDPCPP_SYCL_TARGET=$target -DCUTLASS_ENABLE_BENCHMARKS=ON -DCUTLASS_ENABLE_TESTS=ON

ninja benchmarks
```