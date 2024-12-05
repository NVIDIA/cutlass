[README](../../README.md#documentation) > **Dependent kernel launch**

# Dependent kernel launches

The Hopper architecture supports a new feature through which two kernels in the same stream can
overlap their execution, named 
[Programmatic Dependent Launch (PDL)](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#programmatic-dependent-launch-and-synchronization).
This allows kernels with conflict in global memory to programmatically and safely overlap portions
of their execution. Primary kernel can signal it is about to finish execution, and the next kernel can
optionally wait on the previous kernel to finish flushing its memory.

For more information, we refer you to the [PDL section in the CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#programmatic-dependent-launch-and-synchronization).

## Using dependent launch in CUTLASS

When building CUTLASS, you can use the `CUTLASS_ENABLE_GDC_FOR_SM90` macro to 
enable PDL-related instructions in Hopper kernels:

```
cmake . -DCUTLASS_ENABLE_GDC_FOR_SM90=1
```

Note that this only adds PDL-related instructions to the _kernels_, but to actually allow a dependent
launch, you must also run your GEMM kernel with PDL:

```
gemm.run(
  /* stream = */ stream,
  /* cuda_adapter = */ nullptr,
  /* launch_with_pdl = */ true
);_
```
