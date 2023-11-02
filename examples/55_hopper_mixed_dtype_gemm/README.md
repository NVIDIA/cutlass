This example shows how to do mixed types GEMMs in CUTLASS.

## High level overview 
This example shows how to perform GEMMs on Hopper when A and B have different types. This implementation always passes the type with fewer bits through the register file and upcasts to the type with the higher bit count.

When relying on `KernelScheduleAuto`, the main loop supporting different A and B types will be selected whenever the bit count of A is not equal to the bit count of B. Users can manually select the mixed type main loop and explicitly choose the scheduling policy by specifying one of the following schedules to the `CollectiveBuilder`:  `KernelTmaWarpSpecializedMixedInput`, `KernelTmaWarpSpecializedPingpongMixedInput` or `KernelTmaWarpSpecializedCooperativeMixedInput`.

This first version only supports mixed type GEMMs using TMA.

## Performance

While the example offers a harness for straightforward benchmarking, this initial implementation isn't optimized for performance in the majority of scenarios. We expect this implementation to be performant for `{fp16, bf16} x int8` for problems that are compute bound.

We are currently optimizing the following cases:
1. Memory bound cases for all types
1. Compute bound cases for `{16-bit, 8-bit} x {4-bit, 2-bit}`

As a result, we do not suggest using this example as a benchmarking reference until all of our optimizations are complete (this will be clearly stated in this README in a future release).

## Limitations

* The type that needs to be converted must go through the register file. This means that the collective will swap and transpose whenever the type with fewer bits is the B operand. The user must be aware of when these swaps happen to control the layout of the epilogue as shown in the example. Note that TMA epilogues currently do not support swap + transpose, so non-tma epilogues must be used in this case. We plan to relax this limitation in a future release.

* The layout of the narrow type must be K-major. This means the following:
  * Narrow type is the A operand: Must be Row-Major
  * Narrow type is the B operand: Must be Column-Major

* For 8-bit x 4-bit or 2-bit, both inputs must be K-major.

* TMA requires an alignment of 128 bits. As a result, for a type with `B` bits, `B x TILE_K` must be a multiple of 128 bits.

## Upcoming features

* Support for applying scales after conversion, but before issuing tensor core math (input scale fusion) is planned for v3.4.

* Many optimizations for SOL performance.
