# Examples of using the CUTLASS Python interface

* [00_basic_gemm](/examples/python/00_basic_gemm.ipynb)

    Shows how declare, configure, compile, and run a CUTLASS GEMM using the Python interface

* [01_epilogue](/examples/python/01_epilogue.ipynb)

    Shows how to fuse elementwise activation functions to GEMMs via the Python interface

* [02_pytorch_extension_grouped_gemm](/examples/python/02_pytorch_extension_grouped_gemm.ipynb)

    Shows how to declare, compile, and run a grouped GEMM operation via the Python interface,
    along with how the emitted kernel can be easily exported to a PyTorch CUDA extension.
