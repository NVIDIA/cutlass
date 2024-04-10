[README](../../README.md#documentation) > **CUTLASS 3: Building with Clang as host compiler**

# Building with Clang as host compiler

CUTLASS 3.2(.1) reintroduces support for building with
Clang as host compiler, and NVCC as device compiler.
This is NOT the same as building with
Clang as both host and device compiler ("CUDA Clang").

# Software prerequisites

1. Clang (regularly tested with Clang 14;
   occasionally tested with Clang 10 and greater)

2. CUDA Toolkit (tested with 12.2; other versions likely work)

3. CMake (at least 3.18)

4. git

5. Python (at least 3.6)

Experience with Ubuntu 22.04 LTS is that
clang requires the following packages to be installed.

```bash
$ sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

A symptom of not installing all needed dependencies
is the following error when attempting to use clang:
`"/usr/bin/ld: cannot find -lstdc++: No such file or directory"`.

# Running CMake

## Required CMake options

The Clang build requires specifying the following CMake options.
Replace `<path-to-clang++>` with the path to your `clang++` executable.
You may use `clang++` directly if it is in your `PATH`.

* `CMAKE_CXX_COMPILER=<path-to-clang++>`
* `CMAKE_CUDA_HOST_COMPILER=<path-to-clang++>`

One must set both!  It's not enough just to set the `CXX` environment
variable, for example.  Symptoms of only setting `CMAKE_CXX_COMPILER`
(or only setting the `CXX` environment variable) include `cc1plus`
(GCC's compiler executable) reporting build errors due to it not
understanding Clang's command-line options.

Users can also specify a particular CUDA Toolkit version
by setting the CMake option `CMAKE_CUDA_COMPILER`
to the path to the `nvcc` executable
that lives in the CUDA Toolkit's directory.  For example,
if `${PATH_TO_CUDA_TOOLKIT}` is the CUDA Toolkit directory,
then one can set `CMAKE_CUDA_COMPILER` as follows.

* `CMAKE_CUDA_COMPILER=${PATH_TO_CUDA_TOOLKIT}/bin/nvcc`

