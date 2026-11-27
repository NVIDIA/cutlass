# Distributed GEMM

This example implements Tensor Parallel GEMMs for the Hopper architecture with the experimental
[Distributed GEMM](../../include/cutlass/experimental/distributed) API in CUTLASS.

This example requires Hopper GPUs with an any-to-any NVLink network.
Please refer to [REQUIREMENTS.md](REQUIREMENTS.md) for more information.

By default, the example assumes 8 GPUs (TP=8) and runs an All Gather + GEMM operation, which rotates
operand A. To run with a different number of GPUs or schedule, please refer to
[65_distributed_gemm.cu](65_distributed_gemm.cu).


## Getting started

Command line arguments are mostly similar to other examples:

```
--m=<int>                   Sets the M extent of the GEMM
--n=<int>                   Sets the N extent of the GEMM
--k=<int>                   Sets the K extent of the GEMM
--l=<int>                   Sets the L extent (batch) of the GEMM (default: 1)
--alpha=<f32>               Epilogue scalar alpha (default: 1.0)
--beta=<f32>                Epilogue scalar beta (default: 0.0)
--iterations=<int>          Number of profiling iterations to perform (default: 100)
--warmup-iterations=<int>   Number of warmup iterations prior to profiling (default: 10)
--eps=<f32>                 Threshold for error compared to reference GEMM (default: 0.0)
```

Sample run command:

```bash
./65_distributed_gemm --m=16384 --n=106496 --k=16384 --warmup-iterations=10 --iterations=100
```

This executes a GEMM with shape `<16384, 106496, 16384>`, and reports average runtime
over 100 iterations, with 10 warmup iterations.
A reference check with respect to a single-device GEMM is also performed by default.

## Trying out other schedules

Schedules that are currently supported are:

* All Gather + GEMM:
  * `AllGather1D_TilingCD_RotatingA`
  * `AllGather1D_TilingCD_RotatingB`

* GEMM + Reduce Scatter:
  * `ReduceScatter1D_TilingA_RotatingC`
  * `ReduceScatter1D_TilingB_RotatingC`

To try out different schedules, simply change this line in the example, and set your desired
schedule:

```cpp
using DistSchedule = cutlass::distributed::schedules::AllGather1D_TilingCD_RotatingA<TP>;
```

If you're interesting it trying out other TP values (run on a different number of GPUs), the
procedure is the same, simply modify the following line in the example:

```cpp
using TP = _8;
```
