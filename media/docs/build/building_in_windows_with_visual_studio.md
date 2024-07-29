[README](../../README.md#documentation) > **CUTLASS 3.0: Building on Windows with Visual Studio**

# Building on Windows with Visual Studio

CUTLASS 3.2 reintroduces support for the Microsoft Visual Studio compiler on Windows.
Users and developers may build either
in Visual Studio's graphical integrated development environment,
or on the command line with `cmake --build`.

# Software prerequisites

1. Windows 10 or 11

2. Visual Studio 2019 version 16.11.27, or Visual Studio 2022

3. CUDA Toolkit (at least 12.2; earlier 12.x versions may work)

4. CMake (at least 3.18)

5. git

6. Python (at least 3.6)

Visual Studio must be installed *before* the CUDA Toolkit.
Otherwise, Visual Studio's build system won't know about CUDA.

# Operating system settings

By default, Windows restricts the maximum file path length (`MAX_PATH`) to 260 characters.
CUTLASS has many files and directory paths that challenge this requirement.
As a result, CUTLASS is unlikely to build with this default setting.
The choice of source and build directories affect path lengths,
so the kinds of errors and whether they occur may depend on this.
Symptoms may vary, from errors when running `cmake`
(e.g., during the "generating library instances" step) to build failures.

CUTLASS recommends changing the maximum file path length setting
and rebooting the computer before attempting to clone or build CUTLASS.
Windows 10 (as of version 1607) and 11 permit changing this setting
by making sure that the following registry key exists,
and that its value is set to 1.

```
Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled
```

After changing the registry key's value, reboot the computer first
before attempting to clone or build CUTLASS.

[This Microsoft help article](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry)
explains different ways to change the registry setting.

# Set up build environment

1. Run "git bash" to get a familiar command-line interface

2. Edit `~/.profile` and set the environment variables as needed to access the CUTLASS repository

3. Clone the CUTLASS repository

4. Create the `build` subdirectory in the CUTLASS clone directory, and run CMake in it,
    specifying whatever CMake options are desired, e.g.,
    `cmake .. -DCUTLASS_NVCC_ARCHS=90a`

Alternate approaches may rely on the CMake GUI and/or Windows' native command line.

# Building

A successful CMake run will create a `CUTLASS.sln` Visual Studio "solution" file in the build directory.
One can open this in Visual Studio and build the entire solution or any subset of projects as desired.
It may be necessary to limit maximum build parallelism by setting the appropriate Visual Studio option.

Alternately, one can run `cmake --build . --config Release -j 4` in the build directory.
Replace 4 with the desired maximum build parallelism.
It's important to put the `--build` option before the period that signifies the build directory.
The `--config` option specifies the kind of build;
`--config Release` builds a Release build, while `--config Debug` builds a Debug build.
Unlike with CMake's Makefile or Ninja generators,
`CMAKE_BUILD_TYPE` has no effect on the Visual Studio generator,
because the Visual Studio generator creates all build configurations.

# Tips

With Windows builds, one may find that CMake reruns unnecessarily.
For example, cancelling a build and starting it again may rerun CMake.
This will in turn touch build files that result in unnecessary rebuilds.
One work-around is to set the CMake option `CMAKE_SUPPRESS_REGENERATION=ON`.
However, this turns off CMake's ability to detect on its own when it needs to rerun.
As a result, one will need to know when to rerun CMake by hand.

