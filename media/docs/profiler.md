![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "CUTLASS Profiler")

[README](/README.md#documentation) > **CUTLASS Profiler**

# CUTLASS Profiler

The CUTLASS Profiler is a command-line driven test and profiling environment for CUTLASS computations
defined in the CUTLASS Instance Library.

The CUTLASS Profiler may be compiled with:
```bash
$ make cutlass_profiler -j
```

To limit compilation time, only one tile size (128x128) is instantiated for each data type, math instruction, and layout.
To instantiate all sizes, set the following environment variable when running CMake from an empty `build/` directory.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS=75 -DCUTLASS_LIBRARY_KERNELS=all
...
$ make cutlass_profiler -j
```

The CUTLASS Profiler sources are stored in 
```bash
tools/
  profiler/
```

The CUTLASS Profiler usage statement may be obtained by executing `cutlass_profiler --help` and appears as follows.
```bash
CUTLASS Performance Tool
usage:
    cutlass_profiler [options]
  
  --help
  
  --mode={profile*,single,dry,enumerate}     Regular profiling, single kernel mode only, or no profiling.
  
  --device-info                              Prints information on all GPUs present in the system
  
  --operation=<operation_kind>               CUTLASS operation to profile.
  
  --kernels=<kernel names>                   Names of individual kernels to execute. All are executed if not specified.

Device:
  --device=<int>                             CUDA Device ID

Initialization:
  --initialization=<bool>                    Enables initialization (default: true). If false, device memory is
                                             not initialized after allocation.

  --initialization-provider=<provider>       Selects 'device' or 'host' initialization.

  --dist=<distribution>                      Data distribution of input tensors

  --seed=<int>                               Random number generator seed. Used to enforce deterministic
                                             initialization.

Library:
  --library-algo-mode=<mode>                 Indicates algorithm mode used to call libraries such as cuBLAS and cuDNN.
                                             mode={default*,matching,best}

  --library-algos=<range-list>               If --algorithm-mode=best, permits specifying a selection of algorithms.

Profiling:
  --profiling-iterations=<iterations>        Number of iterations to profile each kernel. If zero, kernels
                                             are launched up to the profiling duration.

  --warmup-iterations=<iterations>           Number of iterations to execute each kernel prior to profiling.
  
  --sleep-duration=<duration>                Number of ms to sleep between profiling periods (ms)
  
  --profiling-enabled=<bool>                 If true, profiling is actually conducted.
  
  --providers=<providers>                    List of providers to be profiled for performance

Verification:
  --verification-enabled=<bool>              Whether to perform verification checks.

  --epsilon=<error>                          Error threshold. Setting to zero (default) requires
                                             bit-level equivalence.

  --nonzero-floor=<floor>                    Results whose absolute value is less than this quantity
                                             are treated as zero for comparisons.

  --save-workspace={*never,incorrect,always} Specifies when to save the GEMM inputs and results to the filesystem.

  --verification-providers=<providers>       List of providers used to verify result. (default: cublas)

Report:
  --append=<bool>                            If true, result is appended to possibly existing file. Otherwise, 
                                             any existing file is overwritten.

  --output=<path>                            Path to output file for machine readable results.

  --report-not-run=<bool>                    If true, reports the status of all kernels including those that
                                             do not satisfy the given arguments.

  --tags=<column:tag,...>                    Inserts leading columns in output table and uniform values for each
                                             column. Useful for generating pivot tables.

  --verbose=<bool>                           If true (default), prints human-readable text to stdout.

About:
  --version                                  CUTLASS 2.0.0 built on Nov  19 2019 at 13:01:00

Operations:
  --operation=<operation_name>               Specifies a particular operation to run or print the usage statement.

     gemm                                    General matrix-matrix product. D = alpha * A*B + beta * C


For more details about a particular operation, specify the operation name with --help.

Example:
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --help

```

## GEMM Arguments

The complete set of arguments available to each operation may be viewed by specifying the operation name
in addition to `--help`. The argument flags and their aliases usable for GEMM appear as follows.

```bash
$ ./tools/profiler/cutlass_profiler --operation=gemm --help

GEMM

  [enum]      --Gemm_kind                                       Variant of GEMM (e.g. gemm, batched, ...)
  [int]       --m,--problem-size::m                             M dimension of the GEMM problem space
  [int]       --n,--problem-size::n                             N dimension of the GEMM problem space
  [int]       --k,--problem-size::k                             K dimension of the GEMM problem space
  [tensor]    --A                                               Tensor storing the A operand
  [tensor]    --B                                               Tensor storing the B operand
  [tensor]    --C                                               Tensor storing the C operand
  [scalar]    --alpha,--epilogue::alpha                         Epilogue scalar alpha
  [scalar]    --beta,--epilogue::beta                           Epilogue scalar beta
  [int]       --split_k_slices                                  Number of partitions of K dimension
  [int]       --batch_count                                     Number of GEMMs computed in one batch
  [enum]      --op_class,--opcode-class                         Class of math instruction (SIMT or TensorOp).
  [enum]      --accum,--accumulator-type                        Math instruction accumulator data type.
  [int]       --cta_m,--threadblock-shape::m                    Threadblock shape in the M dimension.
  [int]       --cta_n,--threadblock-shape::n                    Threadblock shape in the N dimension.
  [int]       --cta_k,--threadblock-shape::k                    Threadblock shape in the K dimension.
  [int]       --stages,--threadblock-stages                     Number of stages of threadblock-scoped matrix multiply.
  [int]       --warps_m,--warp-count::m                         Number of warps within threadblock along the M dimension.
  [int]       --warps_n,--warp-count::n                         Number of warps within threadblock along the N dimension.
  [int]       --warps_k,--warp-count::k                         Number of warps within threadblock along the K dimension.
  [int]       --inst_m,--instruction-shape::m                   Math instruction shape in the M dimension.
  [int]       --inst_n,--instruction-shape::n                   Math instruction shape in the N dimension.
  [int]       --inst_k,--instruction-shape::k                   Math instruction shape in the K dimension.
  [int]       --min_cc,--minimum-compute-capability             Minimum device compute capability.
  [int]       --max_cc,--maximum-compute-capability             Maximum device compute capability.

Examples:

Profile a particular problem size:
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --m=1024 --n=1024 --k=128

Schmoo over problem size and beta:
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --m=1024:4096:256 --n=1024:4096:256 --k=128:8192:128 --beta=0,1,2

Schmoo over accumulator types:
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --accumulator-type=f16,f32

Run when A is f16 with column-major and B is any datatype with row-major 
(For column major, use column, col, or n. For row major use, row or t):

  $ ./tools/profiler/cutlass_profiler --operation=Gemm --A=f16:column --B=*:row

Using various input value distribution:
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --dist=uniform,min:0,max:3
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --dist=gaussian,mean:0,stddev:3
  $ ./tools/profiler/cutlass_profiler --operation=Gemm --dist=sequential,start:0,delta:1

Run a kernel with cta tile size of 256x128x32 and save workspace if results are incorrect 
(note that --cta-tile::k=32 is default cta-tile size):
 $ ./tools/profiler/cutlass_profiler --operation=Gemm --cta_m=256 --cta_n=128  --cta_k=32 --save-workspace=incorrect

Test your changes to gemm kernels with a quick functional test and save results in functional-test.csv:
 $ ./tools/profiler/cutlass_profiler  --operation=Gemm \
   --m=8,56,120,136,256,264,512,520,1024,1032,4096,8192,16384 \
   --n=8,56,120,136,256,264,512,520,1024,1032,4096,8192,16384 \
   --k=8,16,32,64,128,256,288,384,504,512,520 \
   --beta=0,1,2 --profiling-iterations=1 \
   --providers=cutlass --output=functional-test.csv
```

## Example SGEMM

Example command line for profiling SGEMM kernels is as follows:
```bash
$ ./tools/profiler/cutlass_profiler --kernels=sgemm --m=4352 --n=4096 --k=4096

=============================
  Problem ID: 1

    Provider: CUTLASS
   Operation: cutlass_simt_sgemm_128x128_nn

 Disposition: Passed
      Status: Success

   Arguments:  --m=4352 --n=4096 --k=4096 --A=f32:column --B=f32:column --C=f32:column --alpha=1 --beta=0        \
               --split_k_slices=1 --batch_count=1 --op_class=simt --accum=f32 --cta_m=128 --cta_n=128 --cta_k=8  \
               --stages=2 --warps_m=2 --warps_n=2 --warps_k=1 --inst_m=1 --inst_n=1 --inst_k=1 --min_cc=50       \
               --max_cc=1024

       Bytes: 52428800  bytes
       FLOPs: 146064539648  flops

     Runtime: 10.5424  ms
      Memory: 4.63158 GiB/s

        Math: 13854.9 GFLOP/s
```

Note, the arguments which appear in the output may be used as command line parameters for subsequent invocations.


## Example Tensor Core Operations

To execute kernels targeting Tensor Core operations, supply the flag `--op_class=tensorop` in the command line.

```bash
$ ./tools/profiler/cutlass_profiler --op_class=tensorop

=============================
  Problem ID: 1

    Provider: CUTLASS
   Operation: cutlass_turing_h1688gemm_128x128_nt

 Disposition: Passed
      Status: Success

   Arguments:  --m=4352 --n=4096 --k=4096 --A=f16:column --B=f16:row --C=f16:column --alpha=1 --beta=0   \
               --op_class=tensorop --accum=f16 --cta_m=128 --cta_n=128 --cta_k=32 --stages=2             \
               --warps_m=2 --warps_n=2 --warps_k=1 --inst_m=16 --inst_n=8 --inst_k=8                     \
               --min_cc=75 --max_cc=1024


       Bytes: 52428800  bytes
       FLOPs: 146064539648  flops

     Runtime: 1.51255  ms
      Memory: 32.2821 GiB/s

        Math: 96568.7 GFLOP/s

```

## Covering the problem space

All arguments may have single values or comma-delimited set of values. Integers may also be specified
as an inclusive range with the following syntax `start:end:increment` or simply `start:end`. 

For example, the following sweeps over the range of the GEMM K dimension from 8 to 4096 in increments
of 8 elements.

```bash
$ ./tools/profiler/cutlass_profiler --kernels=cutlass_simt_sgemm_128x128_nn --m=4352 --n=4096 --k=8:4096:8
```

## Output

By default, runtime and computed GFLOP/s are reported for each operation and problem size. Additionally,
a table of comma separated values are reported at the end of the execution. This may be output to a file
with the `--output=<filename.csv>` command line option as shown:

```bash
$ ./tools/profiler/cutlass_profiler --kernels=cutlass_simt_sgemm_128x128_nn            \
                                    --m=4352 --n=4096 --k=8:4096:8 --output=report.csv
```

To faclitate generation of pivot tables and charts, additional columns may be prepended with the
`--tags=<column>:<value>` option. One or more tags may be specified using a comma-delimited list.

```bash
$ ./tools/profiler/cutlass_profiler --kernels=cutlass_simt_sgemm_128x128_nn            \
                                    --m=4352 --n=4096 --k=8:4096:8 --output=report.csv \
                                    --tags=cutlass:2.0,date:2019-11-19
```  

# Copyright

Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.

```
  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright notice, this list of
        conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice, this list of
        conditions and the following disclaimer in the documentation and/or other materials
        provided with the distribution.
      * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
        to endorse or promote products derived from this software without specific prior written
        permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
