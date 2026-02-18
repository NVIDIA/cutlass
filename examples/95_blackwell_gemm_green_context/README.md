# Example 95: Blackwell GEMM with Green Context

[Green Context](https://docs.nvidia.com/cuda/cuda-driver-api/group__CUDA__GREEN__CONTEXTS.html) is a lightweight method to partition GPU SM resources.

This example contains two GEMM kernel variants, both with green context support:

1. **Dynamic Persistent CLC kernel** (`95_blackwell_dynamic_persistent_clc_gemm_green_context`): Uses `DynamicPersistentScheduler` (Cluster Launch Control based). No modification needed for green context -- simply launch kernel onto partition stream.
2. **Static Persistent kernel** (`95_blackwell_static_persistent_gemm_green_context`): Uses `StaticPersistentScheduler`. For green context, use partition stream to query max active cluster; modify launch grid based on partition stream max active cluster.

for sm90 hopper dynamic / static kernel, modify launch grid is required.

## Run

### Dynamic Persistent CLC kernel

#### Without green context (all SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_dynamic_persistent_clc_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (partitioned SMs)

Use `--max_num_sm` to specify the number of SMs for the primary partition (GEMM workload).
The remaining SMs are assigned to the remaining partition.

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_dynamic_persistent_clc_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```

### Static Persistent kernel

#### Without green context (all SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_static_persistent_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (partitioned SMs)

```shell
./examples/95_blackwell_gemm_green_context/95_blackwell_static_persistent_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```


## Nsight Systems Profiling

Use `nsys profile` to capture the kernel execution under green context partitioning.
In the Nsys UI, you should see the green context section on the left panel, and the GEMM kernel
launched onto that green context partition.

### Profile Dynamic Persistent CLC kernel

#### Without green context

```shell
nsys profile -o gemm_clc_all_sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_dynamic_persistent_clc_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (120 SMs for GEMM)

```shell
nsys profile -o gemm_clc_green_ctx_120sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_dynamic_persistent_clc_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```

### Profile Static Persistent kernel

#### Without green context

```shell
nsys profile -o gemm_static_all_sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_static_persistent_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --iterations=30
```

#### With green context (120 SMs for GEMM)

```shell
nsys profile -o gemm_static_green_ctx_120sm \
  ./examples/95_blackwell_gemm_green_context/95_blackwell_static_persistent_gemm_green_context \
  --m=8192 --n=8192 --k=8192 --max_num_sm=120 --iterations=30
```
