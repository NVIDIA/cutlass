This example extends Example 55 to support Grouped GEMMs in CUTLASS.

## High level overview

This example shows how to perform Grouped GEMMs on Hopper when A and B have different types. In the Grouped GEMM, multiple GEMMs with potentially different problem shapes can be excetued in a batch. The interface is similar to the standard mixed-input GEMM presented in Example 55, with a few noteworthy differences:
- inside the collective builder, replace the layout types with layout pointer types.
- in the arguments, pass the group size, array of the problem sizes, and the array of strides for matrix A and B.
- if scales and zero-points are included, also pass the array of their strides in the arguments.

Note that in Example 55, the argument `--g` is used to determine the block scale size. It is important not to confuse this with the `--groups` argument in this example, which specifies the number of GEMMs.

## Upcoming features

Currently, the Mixed-input Grouped GEMM only supports row-wise scaling. Please contact us if zero-points or block-wise scaling are needed.
