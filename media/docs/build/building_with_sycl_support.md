
[README](../../../README.md#documentation) > **CUTLASS 3: Building with Clang as Host Compiler**

# Building with SYCL Support

Cutlass 3 can be built with SYCL using the DPC++ compiler, enabling Cutlass
to support other SYCL-enabled devices. This enhancement allows for greater
flexibility and compatibility with diverse computational environments.

SYCL[1] is a royalty-free, cross-platform abstraction layer that enables
code for heterogeneous and offload processors to be written with modern
ISO C++. It provides APIs and abstractions to find devices and manage
resources for GPUs.

## Limitations

Currently, it's only possible to build five examples in the Cute
tutorial and a reduced number of Cute tests.

### Cute Tutorial Examples Supported

* `sgemm_1`, `sgemm_2` and `tiled_copy`: Generic examples that should run on any
  SYCL-enabled device. Tested on Nvidia SM80 devices and Intel PVC
  and Arc devices.
* `sgemm_sm70`: Nvidia SM70 specific example.
* `sgemm_sm80`: Nvidia SM80 specific example.

## Software Prerequisites

To build CUTLASS with SYCL support, you need the latest version of
the DPC++ compiler. You can either use a recent
[nightly build](https://github.com/intel/llvm/releases)
(see the [Setup DPC++ Nightly Build](#setup-dpc-nightly-build) section)
or build the compiler from source as described in the
[oneAPI DPC++ guideline](https://github.com/intel/llvm/blob/sycl/sycl/doc/GetStartedGuide.md#build-dpc-toolchain-with-support-for-nvidia-cuda).

If building for an Nvidia GPU, the CUDA Toolkit will be required
(tested with version 12.4).

CMake (at least version 3.18), Ninja, git, and Python
(at least version 3.6) are also required.

### Setup DPC++ Nightly Build

To install the nightly build, download DPC++ from the
[nightly build](https://github.com/intel/llvm/releases). The minimum version
required is nightly 2024-07-19.

```bash
$ export DPCPP_HOME=/opt/intel/dpcpp-nightly
$ mkdir -p $DPCPP_HOME
$ cd $DPCPP_HOME
$ wget https://github.com/intel/llvm/releases/download/nightly-2024-07-19/sycl_linux.tar.gz
$ tar -zxvf sycl_linux.tar.gz
$ export PATH=$DPCPP_HOME/bin:$PATH
$ export LD_LIBRARY_PATH=$DPCPP_HOME/lib:$LD_LIBRARY_PATH
$ export C_INCLUDE_PATH=$DPCPP_HOME/include:$C_INCLUDE_PATH
$ export CPLUS_INCLUDE_PATH=$DPCPP_HOME/include:$CPLUS_INCLUDE_PATH
$ export CC=clang
$ export CXX=clang++
```

# Running CMake

## Required CMake options

The SYCL build requires specifying the following CMake options and
environmental variables. Replace `<path-to-clang>` and `<path-to-clang++>`
with the path to your clang and clang++ executables. You may use `clang`
and `clang++` directly if they are in your `PATH`.

```bash
$ export CC=<path-to-clang>/clang
$ export CXX=<path-to-clang++>/clang++
```

### CMake options for Nvidia devices

* `DPCPP_SYCL_TARGET=nvptx64-nvidia-cuda` sets the triplet target for Nvidia GPUs.
* `DPCPP_SYCL_ARCH=sm_80` sets the device architecture to SM_80.

```bash
$ cmake -G Ninja .. \
    -DCUTLASS_ENABLE_SYCL=ON \
    -DDPCPP_SYCL_TARGET=nvptx64-nvidia-cuda \
    -DDPCPP_SYCL_ARCH=sm_80
```

Building Cutlass with SYCL support on Nvidia devices has been tested
on an A100 device with `DPCPP_SYCL_ARCH=sm_80`.

### CMake options for Intel devices

* `DPCPP_SYCL_TARGET=intel_gpu_pvc` sets the triplet target for Intel PVC GPUs.

```bash
$ cmake -G Ninja .. \
    -DCUTLASS_ENABLE_SYCL=ON \
    -DDPCPP_SYCL_TARGET=intel_gpu_pvc
```

# References

[1] https://www.khronos.org/sycl/