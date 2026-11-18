# Data-Driven Synchronization for Back-to-Back GEMMs on Rubin

The consumer GEMM synchronizes on the data it loads rather than on kernel
launch order, using Rubin's TMA `report_valid` load (PTX
`.mbarrier::report::validity`). Sometimes called fine-grained or Lamport
synchronization.

- Kernel: [`dense_gemm_persistent_tma_report_valid.py`](dense_gemm_persistent_tma_report_valid.py) (`SM107TmaReportValidGemmKernel`)
- Example/driver: [`run_b2b_gemms_tma_report_valid.py`](run_b2b_gemms_tma_report_valid.py)

## Overview

These kernels do not use launch ordering to decide whether input buffers are
ready. Instead, synchronization is data-driven: the producer writes
over sentinel values, and the consumer treats a tile as ready only after those
sentinels are gone. On Rubin, a new TMA load variant enables hardware-accelerated
sentinel checking during the load.

- The shared buffer is initialized to a dtype-specific sentinel: the negative-zero
  (`-0.0`) bit encoding of the buffer's float dtype (fp4/ fp8 / fp16 / fp32 / fp64).
  The producer must never legitimately emit this value, so it canonicalizes any
  `-0.0` output to `+0.0` before storing. If the sentinel ever leaked into real
  data, the consumer would treat that tile as "not ready", re-issue forever, and
  the kernel would hang.
- Producer and consumer are launched concurrently (PDL / multi-stream).
- The consumer speculatively TMA-loads the producer's output tiles and validates
  them against the sentinel. The TMA load checks for that dtype's sentinel
  representation and reports validity through a v1 mbarrier.

## Benefits

- Lower latency between the producer finishing and the consumer starting.
- Fine-grained overlap between producer and consumer CTAs: a consumer CTA can
  begin as soon as the producing CTA's tile is done, instead of waiting for the
  entire producer kernel.
- Less CTA skew at kernel boundaries: PDL waits for the slowest producer CTA to
  issue `griddepcontrol_launch_dependents`, while TMA report_valid lets early CTAs
  start the next kernel early on the same SM.

## Limitations

For most dtypes, the hardware checks one element per 16B, so the producer must write its
output in 16B chunks (the sentinel is that dtype's `-0.0` encoding). Scale-factor types are
the exception: their sentinel is `0xff` (NaN), and the hardware checks every element, so no
16B-chunk constraint applies.
## Hardware Validity Check

Hardware validity reporting is a new Rubin TMA feature. A TMA load with report_valid
completes the transaction normally, but a new mbarrier also records whether any
tracked 16B chunk still matched the dtype-specific sentinel.

The v1 mbarrier tracks two phases:

- **Primary phase** - advances when the TMA transaction completes (all expected
  arrivals + tx-count satisfied), as usual.
- **Conditional phase** - advances only if the primary phase advances and the
  payload report is zero, meaning no tracked async op reported sentinel data.

Either phase can be waited on independently via the
[`mbar.py`](../../../../../../cutlass/cute/arch/mbar.py) APIs:
`mbarrier_wait_conditional` / `mbarrier_try_wait_conditional` for the conditional
phase, and `mbarrier_wait_primary` / `mbarrier_try_wait_primary` /
`mbarrier_test_wait_primary` for the primary phase. MMA consumers wait on the
conditional phase, so they only proceed once data is valid. The retry warp tests
the primary phase to decide whether the TMA finished but needs re-issue.

## API summary

The main APIs map directly to the TMA report_valid mechanism:

- **`cute.copy(..., report_valid=True)`** issues a TMA load with the hardware
  validity report enabled, so the loaded data's validity is checked in hardware
  and folded into the conditional phase of the buffer's mbarrier.
- **`pipeline.PipelineTmaUmmaRetry`** wraps the v1 mbarrier for stage buffers
  with two consumers: the MMA warp waits on the conditional phase, the retry
  warp on the primary phase.
- **`consumer_test_valid()`** -> `(tma_done, data_valid)`: reads the primary phase
  (`tma_done`) and the validity bit (`data_valid`) of the buffer's mbarrier. The
  retry warp uses these two bits to decide whether to release the buffer or
  re-issue the TMA.
- **`retry_release(state)`**: releases a buffer whose data the retry warp found valid.
- **`retry_expect_tx(state, tx_count)`**: re-arms the full mbarrier (resets the
  expected tx count) before re-issuing a TMA on a stage whose data was invalid.
- **`pipeline.PerStagePipelineState`**: per-stage phase/count tracking, since
  different stages may need a different number of TMA re-issues before their data
  is valid.
  - `mark_valid()` - flip phase, increment processed count.
  - `mark_invalid()` - flip phase for re-issue, no increment.
  - `reset_count()`, `next()` - reset counts for a new tile, advance to next stage.

## Kernel Design

### Producer initialization

Every activation buffer must hold the `-0.0` sentinel before the producer
overwrites it. 2 methods are demonstrated:

- **External prefill (default).** The caller fills each buffer before the chain
  starts.
- **Producer-written (`--producer_sentinel_init`).** A dedicated init warp in the
  producer writes `-0.0` to its own output tiles, then fires the PDL launch. This
  can have some cost in the producer if it cannot be hidden, but requires no initialization
  by the caller.

### Sentinel canonicalization (-0.0 -> +0.0)

So that a kernel does not produce `-0.0` as part of its regular computation and
collide with the sentinel value, which would cause a hang, `-0.0` is canonicalized to `+0.0`
in the epilogue before storing to global memory. This is done via the .pzo (positive zero only)
modifier on Rubin which handles this in hardware as part of the conversion operation
from the accumulator type to the output type. 

### Sentinel canonicalization (-0.0 -> +0.0)

So that a kernel does not produce `-0.0` as part of its regular computation and
collide with the sentinel value, which would cause a hang, `-0.0` is canonicalized to `+0.0`
in the epilogue before storing to global memory. This is done via the .pzo (positive zero only)
modifier on Rubin which handles this in hardware as part of the conversion operation
from the accumulator type to the output type. 

### Warp specialization

- **TMA warp** - issues the initial loads.
- **Retry warp** - waits on the **primary** phase (transaction done).
  If the TMA is done but the data is invalid, it re-arms via `retry_expect_tx`
  and re-issues the TMA with `report_valid=True`.
- **MMA warp** - waits on the **conditional** phase (data valid). Unchanged, since
  `mbarrier_wait` already targets the conditional phase.

### 2CTA retry mechanism

The 2-CTA TMA load (the 2-CTA variant of `cp.async.bulk.tensor`) only updates the
leader CTA's local mbarrier in the primary phase, so the peer CTA cannot
independently detect that a re-issue is needed. The leader detects the retry and
forwards the re-issue coordinates to the peer over dsmem (a 1-stage
`PipelineAsync` coordinate pipeline); the peer then re-issues its half of the
collaborative copy. The leader signals exit by writing `-1` into the coordinate
pipeline.

The subtlety is that only the leader can see the failure, yet the retry TMA needs both
CTAs to issue. Walking one stage buffer through a single retry:

1. Leader and peer issue the 2CTA load together from TMA warp - each pulls its own half of the
   tile (not multicast).
2. The load lands, but only the **leader's** mbarrier advances its primary phase
   and carries the validity report (reports if data in **either** CTA was invalid).
   The peer's mbarrier sees nothing, so the peer has no idea whether the load even
   completed, let alone whether it was valid.
3. The report says the sentinel is still present - the producer has not written
   this tile yet. The leader (the only CTA that knows) must re-issue, but a 2CTA
   load only works if both halves fire again.
4. The leader pushes the tile's coordinates into the dsmem coordinate pipeline;
   the peer wakes on that pipeline, and re-issues its TMA.

Steps 2-4 repeat until the report comes back clean. The leader then pushes `-1`
into the coordinate pipeline to release the peer from its retry loop.

## Driver Setup

Kernel behavior is controlled by these compile-time flags:

- `check_b_valid`: enables TMA report_valid and the retry warp.
- `pdl_early_launch_next`: launches the successor kernel through PDL.
- `pdl_early_start`: allows the kernel to start early with PDL.
- `eager_launch_next`: fire successor launch at kernel start (default True); when
  False, defer it until TMA loads finish.
- `producer_sentinel_init`: the producer writes the `-0.0` sentinel to its own
  output (via the init warp) instead of the caller pre-filling it. See
  [Producer initialization](#producer-initialization).

## Benchmarking

Benchmark by running the same shape twice: once with TMA report_valid and once with
the PDL baseline.

```bash
python run_b2b_gemms_tma_report_valid.py \
  --nk 1792,7168 \
  --m_list 2048,2048 \
  --benchmark \
  --iterations=1000 \
  --chunk_size=100 \
  --use_report_valid

python run_b2b_gemms_tma_report_valid.py \
  --nk 1792,7168 \
  --m_list 2048,2048 \
  --benchmark \
  --iterations=1000 \
  --chunk_size=100 \
  --no-use_report_valid
```

### Results

Speedup = PDL-baseline latency / TMA report_valid latency, using the HW `.pzo`
canonicalization path (>1 means TMA report_valid wins). Measured with fp16 A/B/C.

|    n x k  |        m\_list | mode | speedup | case              |
|----------:|---------------:|------|--------:|-------------------|
|  32x1536  |     2880-2880  | 1CTA |    1.11 | sub-wave          |
|  32x1536  |     2880-2880  | 2CTA |    1.08 | sub-wave          |
| 1792x7168 |     2048-2048  | 1CTA |    1.24 | last wave sparse  |
| 1792x7168 |     2048-2048  | 2CTA |    1.15 | last wave sparse  |
| 1792x7168 |     3712-2048  | 1CTA |    1.25 | last wave partial |
| 1792x7168 |     3712-2048  | 2CTA |    1.25 | last wave partial |
|  32x4096  | (4096)x8 chain | 1CTA |    1.32 | 8-GEMM chain      |
|  32x4096  | (4096)x8 chain | 2CTA |    1.34 | 8-GEMM chain      |
| 1792x7168 |     3712-3712  | 1CTA |    1.10 | last wave partial |
| 1792x7168 |     3712-3712  | 2CTA |    1.08 | last wave partial |
| 1664x7168 |     2048-2048  | 1CTA |    1.17 | last wave full    |
| 1664x7168 |     2048-2048  | 2CTA |    1.12 | last wave full    |
