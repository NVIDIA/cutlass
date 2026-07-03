# GEMM Performance Measurement Methodology Guidelines

## Introduction

As linear algebraic computation - particularly general matrix multiplication (GEMM) - forms the computational backbone of modern artificial intelligence and machine learning applications, the need for precise and robust performance measurement methodologies has never been greater. Rapid advances in NVIDIA GPU architectures continually push the boundaries of hardware and algorithmic efficiency, making it crucial to benchmark GEMM operations with rigorous, reproducible standards. Reliable measurement frameworks not only enable fair comparisons between devices and software stacks but also illuminate subtle bottlenecks, guide system optimizations, and ensure that performance gains reflect true progress rather than artifacts of measurement inconsistency.  This document outlines the methodology for measuring GEMM performance to ensure results are accurate, reproducible, and consistent across different NVIDIA devices, firmware, and software.

## Benchmark Requirements

When writing or using a benchmark to profile GEMM performance on a GPU, several techniques must be encoded into the benchmark to ensure stable and accurate measurements.

1. **Separate warmup and profiling iteration loops**

A user should be able to separately specify the number of warmup and profiling iterations. The warmup and profiling loops must be separated by calls to `cudaProfilerStart/Stop`, for use with external profilers, and/or calls to `cudaEventRecord`, for self-profiling benchmarks. See [Warm-ups and Iterations](#warm-ups-and-profiling-iterations) below for recommendations on configuring the number of warmup and profiling iterations.

2. **Minimal gaps between kernel launches**

There should be minimal overhead between kernel launches in both the warmup and profiling loops. All data buffers must be allocated and initialized before entering either loop. There must be no additional GPU work between kernel launches, this includes data allocations, deallocations, and copies as well as extraneous kernel launches. CPU work must be minimized so the CPU does not limit the kernel launch rate.

3. **Tensor buffer rotation**

Special care must be taken to ensure that all data caches are "cold" at the start of each kernel iteration. To achieve this without reallocating data between iterations and violating the "Minimal gaps between kernel launches" requirement, benchmarks must pre-allocate multiple buffers for every memory surface used by the kernel and change buffers each iteration. See [Buffer Rotation](#buffer-rotation) below for more details.

## Testing Methodology Overview

1. **Test Type Specification:**

There are two main types of tests that are commonly run when profiling GPU GEMM performance: fixed frequency tests and fixed power tests.

**Fixed frequency tests** run on the GPU at a predefined frequency and are useful to measure architectural and software efficiency characteristics. Precautions must be taken to ensure the chosen frequency can be sustained. When workloads run on the GPU, the computation and data movement to process the work encapsulated result in energy consumption and hence power. It is essential to adhere to the electrical and thermal constraints prescribed for the product, so power and thermal controllers may induce clock variability even when the user specifies a locked clock frequency. To mitigate this risk, a user should use zero-fill data to reduce power consumption and monitor the clock frequencies during testing to watch for variation. If clock frequency variation is observed, the user should select a lower frequency that can be sustained for their testing. Note this is not a set up for measuring the maximum performance of the product.

**Fixed power tests** run on the GPU with a given power limit and mimic real-world scenarios.

GPU products are regulated by power limits with dynamic voltage and frequency scaling (DVFS) enabled in real-world usage. On reaching the power limit, a throttling mechanism enables the clocks to adjust to operating points within the allowable power budget. This is the standard configuration for GPU products when they are operated as received from the factory. Fixed power tests are the most realistic, but they are also subject to a higher degree of run-to-run variation, device-to-device variation, and sensitivity to firmware versions. As such, fixed power tests must be meticulously controlled to ensure a stable testing environment (refer to [Matrix Fill Methodology](#matrix-fill-methodology), [Warmups and Iterations](#warm-ups-and-profiling-iterations), and [Input Buffer Rotation](#buffer-rotation) below).

2. **Data Collection:**

For all tests, it is recommended to collect kernel durations with nsight-systems or CUDA events to calculate the achieved FLOPS/s. The GPC frequency should be profiled with nvidia-smi or NVML to monitor for clock variation and to identify the settled frequency.

For **fixed frequency** tests, monitor the GPC frequency to ensure that the selected frequency is maintained throughout execution. It is also recommended to profile SM utilization, DRAM and L2 utilization and read/write bytes, and LRC multicast rate where applicable.

For **fixed power** tests, monitor the GPC frequency, GPU power, and GPU temperature and calculate the average frequency, power, and temperature during execution. Use the profiled GPC frequencies to ensure that the clocks reached a stable frequency before the profiling iterations (see [Warm-ups and Iterations](#warm-ups-and-profiling-iterations) below).

3. **Data Analysis:**

Before conducting any data analysis, please use profiled metrics to validate that the benchmark follows best practices: 1) Use the L2 hit rate per-iteration to ensure that buffers are rotated appropriately (with nsight-compute it is recommended to use `--cache-control none` to examine the cache behavior of the benchmark without additional cache flushes imposed by the profiler); 2) Examine the profiled GPC frequencies to ensure that clocks are stable during testing iterations; 3) Examine the kernel launch times to ensure that there are minimal gaps between kernel iterations.

Compare the measured average runtime against the SOL runtime at the locked frequency (for fixed frequency tests) or the settled average clock frequency (for power-constrained tests).

a. For **fixed frequency** tests, compare the hardware utilization metrics against the SOL for the given problem. Although increased DRAM and L2 utilization over SOL may not affect the runtime performance at fixed frequency, it will cause higher power consumption and lower performance at fixed power.

b. For **fixed power** tests, compare the achieved FLOPS/s against the SOL at the settled frequency. Also compare the achieved FLOPS/s, settled GPC frequency, and power consumption to the SOL expectations.

## Matrix Fill Methodology

Values used to fill GEMM matrices can significantly influence the level of power consumed during computation and hence the final performance achieved. This is because the data patterns present in these matrices directly affect activation patterns within the underlying hardware, such as switching activity in arithmetic units and memory subsystems. For instance, all-zero or low-entropy data may lead to decreased dynamic power draw, as fewer bits transition during operations, while random or high-entropy values typically result in more widespread switching and, consequently, higher power consumption. As a result, the choice of fill values not only shapes performance characteristics but also determines the representativeness and repeatability of power measurements in GEMM benchmarks.

While matrix fills can generally be generated from a variety of distributions, we prefer to use the following values for consistency and accuracy in the GEMM measurements:

Uniform Distribution:

For all data types, the range used is [-1, 1] floating point numbers

Scale factor types are unsigned, so the range used is [0, 1]

Fixed power tests are highly sensitive to the data fill pattern, particularly for narrow precisions. If possible, it is recommended to manually examine the tensor data to ensure that it matches the expected distribution.

Fixed frequency tests are *not* sensitive to the data fill pattern. It is recommended to use zero-fill which uses less power and makes it easier to sustain a locked frequency.

## Warm-ups and Profiling Iterations

Warm-up iterations play a crucial role in benchmarking by priming the system to a consistent runtime state before measurements commence. When a workload is executed, initial runs may encounter cold address caches, uninitialized architectural resources and thermal or power states that have not yet stabilized. This transience can result in inconsistent or artificially variable runtimes, as the hardware and software stack adjust from an idle to an active state. Warm-ups allow components such as caches to be populated, memory pages to be mapped, and device clocks to reach a stable operating point, thereby eliminating artifacts of system initialization. Only after these transient effects dissipate does the system reach a quiescent, stable operating point - ensuring that the measurements collected reflect real application performance under steady-state conditions rather than the idiosyncrasies of the initial ramp-up.

To ensure accurate and stable measurements, the following warm-up and iteration procedures should be applied:

1. **Warm-up Iterations:** a) Warm-up iterations are used to ensure that caches and TLBs are warm and to allow the power reading to stabilize. b) For fixed power tests, clock stabilization takes longer, so the benchmark should run warm-ups until power draw stabilizes.  When running GEMMs back-to-back, the GPC clocks were observed to oscillate for around the first 3 seconds of runtime before settling on a stable frequency.

2. **Profiling Iterations:** a) Profiling iterations were designed to be large enough to minimize run-to-run variation.  b) From previous GEMM studies, running greater than 1000 testing iterations provided stable results for large problem sizes (~4096x4096x4096). Smaller problems may have more variability, and the iteration count should be increased accordingly.

3. **Cool-down Cycles:** After completing the testing iterations for each GEMM problem, the GPU should be returned to an idle, inactive state to allow the power draw, temperature, and clock frequency to return to their idle values. These cool-down cycles prevent interference between subsequent tests.

For large GEMMs on Blackwell (~8192x8192x16384), we use 10,000 warmups, 4,000 profiling iterations, and 1 second of cool-down time between tests.

## Buffer Rotation

One critical step in designing reliable GEMM benchmarks is to address the influence of cache residency, particularly in the context of the L2 cache. If input matrices persist in cache across iterations, subsequent GEMM operations may benefit from artificially lowered memory access times. This distorts performance measurements, as the observed speed reflects cache effects rather than true DRAM memory access costs - a scenario that rarely matches real-world workloads, where data locality and reuse are not guaranteed to this extent.

To eliminate this anomalous observation, buffer rotation is employed. By allocating duplicate buffers for each input tensor, with a total size at least twice the L2 cache capacity (and using at least two buffers per tensor), we ensure that after each kernel iteration, the next computation accesses data not resident in the cache. The rotation of buffer pointers forces each iteration to read from new buffer regions, so that by the time a buffer is reused, its content has been evicted from the cache due to intervening memory traffic. This guarantees that GEMM computations consistently start with input matrices located in DRAM rather than cache, thereby reflecting realistic access latencies.

Through buffer rotation, we eliminate false performance gains that stem from prior cache residency, achieving greater determinism and accuracy in the measurements. This practice is essential for producing benchmarks that are representative, repeatable, and free from the confounding effects of temporal locality specific to tightly-looped microbenchmarks.

To ensure consistent, accurate results special care should be taken to prevent cross-iteration L2 hits:

1. Calculate the footprint of all input tensors and compare it to the L2 cache capacity for the target device.
2. Allocate duplicate buffers for all tensors such that the total footprint of all input buffers is >= 2x the L2 cache capacity.
   a. Some very large problems will have a total footprint that is >= 2x the L2 capacity without any buffer duplication. In such cases, 2 buffers should still be used to prevent data remaining resident in L2.
3. After each profiling iteration, update the buffer pointers for all tensors.
   a. Rotate through the buffers in a circular manner, by the time a buffer is reused, enough data should have been read in intervening iterations to cause the buffer to be evicted from cache.

## Conclusion

In summary, precise and reliable GEMM benchmarking requires careful attention to data fill strategies, system warm-up and iteration protocols, and memory management techniques such as buffer rotation. By adhering to consistent fill methodologies and evolving these recommendations based on real-world empirical distributions, we can ensure that performance measurements remain representative of actual workloads. Rigorous warm-up procedures are essential for eliminating transient effects, stabilizing system state, and achieving reproducible results. Buffer rotation, in turn, mitigates the confounding influence of L2 cache residency, guaranteeing that measured performance reflects realistic DRAM access latencies rather than idealized cache scenarios. Together, these practices create a robust framework for GEMM evaluation - one that balances accuracy, consistency, and relevance across diverse data types, problem sizes, and hardware configurations. As methodologies continue to evolve with ongoing research and observation, these principles provide a solid foundation for producing actionable and trustworthy benchmarking outcomes.
