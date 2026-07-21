# Example 95: Blackwell GEMM with Green Context

[Green Context](https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__GREEN__CONTEXTS.html) is a lightweight method to partition GPU SM resources.

This example demonstrates a Blackwell FP16 GEMM with green context support using two tile scheduler variants, selectable at runtime via `--scheduler`:

1. **Dynamic Persistent CLC** (`--scheduler=dynamic`, default): Uses `DynamicPersistentScheduler` (Cluster Launch Control based). No modification needed for green context -- simply launch kernel onto partition stream.
2. **Static Persistent** (`--scheduler=static`): Uses `StaticPersistentScheduler`. For green context, use partition stream to query max active cluster; modify launch grid based on partition stream max active cluster.

For SM90 Hopper dynamic / static kernels, modifying the launch grid is required.

## Build

From the CUTLASS build directory:

```shell
# Configure (only examples, SM100a)
cmake <cutlass_root> \
  -DCUTLASS_NVCC_ARCHS=100a \
  -DCUTLASS_ENABLE_EXAMPLES=ON \
  -DCUTLASS_ENABLE_TESTS=OFF \
  -DCUTLASS_ENABLE_LIBRARY=OFF \
  -DCUTLASS_ENABLE_PROFILER=OFF \
  -DCMAKE_BUILD_TYPE=Release

# Build only this example
make 95_blackwell_gemm_green_context -j$(nproc)
```

## Run

### Dynamic Persistent CLC scheduler

#### Without green context (all SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=dynamic --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (partitioned SMs)

Use `--max_num_sm` to specify the number of SMs for the primary partition (GEMM workload).
The remaining SMs are assigned to the remaining partition.

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=dynamic --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30 --raster_order=along_m

./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=dynamic --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30 --raster_order=along_n
```

### Static Persistent scheduler

#### Without green context (all SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=static --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (partitioned SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=static --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30 --raster_order=along_m

./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=static --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30 --raster_order=along_n
```


## Nsight Systems Profiling

Use `nsys profile` to capture the kernel execution under green context partitioning.
In the Nsys UI, you should see the green context section on the left panel, and the GEMM kernel
launched onto that green context partition.

### Profile Dynamic Persistent CLC scheduler

#### Without green context

```shell
nsys profile -o gemm_dynamic_all_sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=dynamic --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (120 SMs for GEMM)

```shell
nsys profile -o gemm_dynamic_green_ctx_120sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=dynamic --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```

### Profile Static Persistent scheduler

#### Without green context

```shell
nsys profile -o gemm_static_all_sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=static --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (120 SMs for GEMM)

```shell
nsys profile -o gemm_static_green_ctx_120sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_gemm_green_context \
  --scheduler=static --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```
