# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
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

Cross-compile (e.g. linking an AOT object built for AArch64 Linux):
    python -m cutlass.cute.export.aot_config --ldflags --target aarch64-unknown-linux-gnu
    python -m cutlass.cute.export.aot_config --libs    --target aarch64-unknown-linux-gnu

When a --target triple is given, the search looks first in
``<libdir>/<triple>/`` (per-triple subtree, GCC/Clang multilib convention),
then in ``<libdir>/stubs/<triple>/`` (AOT cross-compile link-time stub —
empty-body libcute_dsl_runtime.so with the same SONAME, resolved against
the real lib at runtime on the target). If no per-triple runtime library
is found, a clear error is reported to stderr. Empty ``--target`` falls
back to ``<libdir>/`` for the build host.

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


def _resolve_target_libdir(default_dir: str, target: str) -> tuple[str, str]:
    """Resolve the runtime library directory for a given target triple.

    Returns ``(resolved_dir, error_msg)``. ``error_msg`` is non-empty when
    a target was requested but no per-triple subtree exists for it.

    Lookup order:
      1. ``<default_dir>/<target>/`` — per-target multilib subtree, used
         when a real cross-built runtime ships for ``target``.
      2. ``<default_dir>/stubs/<target>/`` — AOT cross-compile link-time
         stub (libcute_dsl_runtime.so with empty bodies, same SONAME as
         the native lib). At runtime on the target the dynamic loader
         resolves against the real lib.
      3. ``<default_dir>/`` only when ``target`` is empty (native host).
    """
    if not target:
        return default_dir, ""
    if not default_dir:
        return "", (
            f"No CuTe DSL runtime library directory available; "
            f"cannot resolve --target={target}."
        )
    candidate = Path(default_dir) / target
    if candidate.is_dir() and any(candidate.iterdir()):
        return str(candidate), ""
    stub_candidate = Path(default_dir) / "stubs" / target
    if stub_candidate.is_dir() and any(stub_candidate.iterdir()):
        return str(stub_candidate), ""
    return "", (
        f"No CuTe DSL runtime library available for --target={target}. "
        f"Looked in {candidate} and {stub_candidate}. Cross-target "
        f"runtime builds are not shipped; supply your own cross-built "
        f"libcute_dsl_runtime via -L/<your-sysroot>/lib at link time."
    )


def get_libdir(target: str = "") -> str:
    """
    Get the library directory path containing libcuda_dialect_runtime.so.

    :param target: Optional LLVM triple for a cross target. When non-empty,
        looks in ``<default-libdir>/<target>/`` first.
    :return: Path to the library directory. Empty string only when ``target``
        is also empty and no runtime library is installed on the host.
    :rtype: str
    :raises RuntimeError: when ``target`` is set but no per-triple runtime
        library subtree exists, so callers (and the CLI) surface a non-zero
        exit instead of silently returning ``""``.
    """
    from cutlass.runtime import find_runtime_libraries

    libs = find_runtime_libraries(enable_tvm_ffi=False)
    default_dir = str(Path(libs[0]).parent) if libs else ""
    resolved, err = _resolve_target_libdir(default_dir, target)
    if err:
        raise RuntimeError(err)
    return resolved


def get_libs(enable_tvm_ffi: bool = False, target: str = "") -> str:
    """
    Get the -l flags needed for AOT compilation linking.

    Similar to `tvm-ffi-config --libs` which returns `-ltvm_ffi`,
    this returns `-lcuda_dialect_runtime` (and `-ltvm_ffi` if TVM-FFI is enabled).

    :param enable_tvm_ffi: Whether to include TVM-FFI library
    :param target: Optional LLVM triple for a cross target. The set of
        ``-l`` flags is independent of the target (the linker resolves
        them against the search path), so this is informational; the value
        is accepted for symmetry with :func:`get_ldflags`.
    :return: Space-separated -l flags (e.g., "-lcuda_dialect_runtime -ltvm_ffi")
    :rtype: str
    """
    from cutlass.runtime import find_runtime_libraries

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
    from cutlass.runtime import find_runtime_libraries

    return find_runtime_libraries(enable_tvm_ffi=enable_tvm_ffi)


def get_ldflags(target: str = "") -> str:
    """
    Get the -L flags for the linker.

    Similar to `tvm-ffi-config --ldflags` which returns `-L<libdir>`.

    :param target: Optional LLVM triple for a cross target. When non-empty,
        emits ``-L<libdir>/<target>`` if that subtree exists; otherwise
        raises ``RuntimeError`` so the CLI fails non-zero.
    :return: -L flag with library directory path, or ``""`` when no runtime
        is installed on the host (only possible with ``target=""``).
    :rtype: str
    :raises RuntimeError: when ``target`` is set but no per-triple runtime
        library subtree exists.
    """
    libdir = get_libdir(target=target)
    if libdir:
        return f"-L{libdir}"
    return ""


def main() -> None:
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
    parser.add_argument(
        "--target",
        type=str,
        default="",
        metavar="TRIPLE",
        help=(
            "LLVM target triple for a cross-compile linking step "
            "(e.g. aarch64-unknown-linux-gnu). When set, library "
            "discovery searches <libdir>/<triple>/ for the per-target "
            "runtime build. Empty (default) = build-host runtime."
        ),
    )

    args = parser.parse_args()

    if not args.libdir and not args.ldflags and not args.libs:
        parser.print_help()
        sys.exit(1)

    enable_tvm_ffi = args.with_tvm_ffi
    target = args.target

    try:
        if args.libdir:
            print(get_libdir(target=target))

        if args.ldflags:
            print(get_ldflags(target=target))

        if args.libs:
            print(get_libs(enable_tvm_ffi=enable_tvm_ffi, target=target))
    except RuntimeError as e:
        print(e, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
