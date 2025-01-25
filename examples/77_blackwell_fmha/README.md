# FMHA for Blackwell: Forward

This sample provides code for fused multi-head attention forward, context, or generation phase.
It supports HeadDims of 32, 64, and 128, and fp8, fp16, and bf16 input data types.

For forward or context usage, use an M-blocking (Seqlen-Q) of 256 and an N-blocking (Seqlen-K) of 128.
For generation usage, use an M-blocking (Num-Groups) of 128 (although the limit is currently 32 for actual Num-Groups), and a N-blocking (Seqlen-K) of 64, 128 or 256.

Context loads are done via TMA, whereas generation usage utilized `cp.async` and is thus more amenable to complex load patterns.

For variable sequence lenght, the code requires a batch of valid (but never used) padding memory ahead of the first input batch. This is achieved with least overhead by leaving one batch free and then arranging QKV consecutively.

The approach of this implementation is to reuse the selection logic of the collective gemm builder and recombine the result into an FMHA kernel.
The kernel and collective layer are then formulated to be fmha-specific.
The design assigns two tiles to each threadblock, and pingpongs between them in terms of matrix-matrix multiplication and softmax.

The example builds four binaries, showcasing the context and generation usage for fp8 and fp16.
For detailed information on how to invoke them, check out either the tests in `CMakeLists.txt` or the `--help` for them.

To modify the code for fusions, `collective/fmha_fusion.hpp` provides the easiest customization point.
The `apply_mask` function is called with the accumulator of the first GEMM and the logical positions of those elements.
It is well-suited for applying masks or activations.
More complex fusions that require memory loads would require modifying the mainloop collective to orchestrate the load via TMA.
