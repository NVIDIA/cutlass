# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
CLI tool to help with AOT compilation configuration.

Similar to tvm-ffi-config or llvm-config, this tool provides compiler flags
for linking against CuTe DSL runtime libraries.

Usage:
    python -m cutlass.cute.export.aot_config --libdir    # Returns the library directory path
    python -m cutlass.cute.export.aot_config --ldflags   # Returns -L flags for linking
    python -m cutlass.cute.export.aot_config --libs      # Returns -l flags for linking

Examples:
    # Compile and link a shared library using shell substitution
    g++ -shared -o kernel.so kernel.o \\
        $(python -m cutlass.cute.export.aot_config --ldflags) \\
        $(python -m cutlass.cute.export.aot_config --libs)

    # Or using backticks
    g++ -shared -o kernel.so kernel.o `python -m cutlass.cute.export.aot_config --ldflags` `python -m cutlass.cute.export.aot_config --libs`
"""

import argparse
import sys
from pathlib import Path


def get_libdir() -> str:
    """
    Get the library directory path containing libcuda_dialect_runtime.so.

    :return: Path to the library directory
    :rtype: str
    """
    from ..runtime import find_runtime_libraries

    libs = find_runtime_libraries(enable_tvm_ffi=False)
    if libs:
        # Return the directory containing the first library found
        return str(Path(libs[0]).parent)

    return ""


def get_libs(enable_tvm_ffi: bool = False) -> str:
    """
    Get the -l flags needed for AOT compilation linking.

    Similar to `tvm-ffi-config --libs` which returns `-ltvm_ffi`,
    this returns `-lcuda_dialect_runtime` (and `-ltvm_ffi` if TVM-FFI is enabled).

    :param enable_tvm_ffi: Whether to include TVM-FFI library
    :return: Space-separated -l flags (e.g., "-lcuda_dialect_runtime -ltvm_ffi")
    :rtype: str
    """
    from ..runtime import find_runtime_libraries

    libs = find_runtime_libraries(enable_tvm_ffi=enable_tvm_ffi)
    # Convert full paths to -l flags
    # e.g., /path/to/libcuda_dialect_runtime.so -> -lcuda_dialect_runtime
    flags = []
    for lib in libs:
        lib_path = Path(lib)
        lib_name = lib_path.stem  # e.g., "libcuda_dialect_runtime"
        if lib_name.startswith("lib"):
            lib_name = lib_name[3:]
        flags.append(f"-l{lib_name}")
    return " ".join(flags)


def get_lib_paths(enable_tvm_ffi: bool = False) -> list[str]:
    """
    Get the full paths to runtime libraries.

    :param enable_tvm_ffi: Whether to include TVM-FFI library
    :return: List of full library paths
    :rtype: list[str]
    """
    from ..runtime import find_runtime_libraries

    return find_runtime_libraries(enable_tvm_ffi=enable_tvm_ffi)


def get_ldflags() -> str:
    """
    Get the -L flags for the linker.

    Similar to `tvm-ffi-config --ldflags` which returns `-L<libdir>`.

    :return: -L flag with library directory path
    :rtype: str
    """
    libdir = get_libdir()
    if libdir:
        return f"-L{libdir}"
    return ""


def main():
    parser = argparse.ArgumentParser(
        description="AOT configuration helper for CuTe DSL (similar to tvm-ffi-config)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Get library directory path
  python -m cutlass.cute.export.aot_config --libdir

  # Get -L flags for linking
  python -m cutlass.cute.export.aot_config --ldflags

  # Get -l flags for linking
  python -m cutlass.cute.export.aot_config --libs

  # Compile a shared library
  g++ -shared -o kernel.so kernel.o \\
      $(python -m cutlass.cute.export.aot_config --ldflags) \\
      $(python -m cutlass.cute.export.aot_config --libs)
        """,
    )

    parser.add_argument(
        "--libdir",
        action="store_true",
        help="Print the library directory path containing runtime libraries",
    )
    parser.add_argument(
        "--ldflags",
        action="store_true",
        help="Print -L flags for linking (e.g., -L/path/to/lib)",
    )
    parser.add_argument(
        "--libs",
        action="store_true",
        help="Print -l flags for linking (e.g., -lcuda_dialect_runtime)",
    )
    parser.add_argument(
        "--with-tvm-ffi",
        action="store_true",
        help="Include TVM-FFI library in --libs output (disabled by default)",
    )

    args = parser.parse_args()

    if not args.libdir and not args.ldflags and not args.libs:
        parser.print_help()
        sys.exit(1)

    enable_tvm_ffi = args.with_tvm_ffi

    if args.libdir:
        print(get_libdir())

    if args.ldflags:
        print(get_ldflags())

    if args.libs:
        print(get_libs(enable_tvm_ffi=enable_tvm_ffi))


if __name__ == "__main__":
    main()

