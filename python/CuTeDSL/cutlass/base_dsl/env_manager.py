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
This module provides utilities for the environment variables setup.

It provides an EnvironmentVarManager, which reads environment variables for the DSL
and caches them for efficient access.

It also provides utilities to automatically setup a subset of environment variables
based on heuristics.
"""

import os
import sys
import shutil
import glob
import warnings
from pathlib import Path
from functools import lru_cache

from ..base_dsl.runtime.cuda import get_compute_capability_major_minor
from .common import DSLRuntimeError
from .utils.logger import log
from .cache_helpers import get_default_file_dump_root

IS_WINDOWS = sys.platform == "win32"
CLIB_EXT = ".dll" if IS_WINDOWS else ".so"

# =============================================================================
# [DSL]_KEEP token definitions
# =============================================================================

# All individual artifact tokens accepted by [DSL]_KEEP.
_KEEP_ALL_TOKENS: frozenset[str] = frozenset(
    {
        "ir",
        "ir-debug",
        "ptx",
        "cubin",
    }
)
# "all" is a convenience alias that expands to every token above.
_KEEP_VALID_TOKENS: frozenset[str] = _KEEP_ALL_TOKENS | {"all"}

CUTLASS_FAMILY_DSL_PREFIXES: frozenset[str] = frozenset(
    {
        "CUTE_DSL",
        "CUTE_EXPERIMENTAL_DSL",
    }
)


def is_cutlass_family_dsl_prefix(prefix: str) -> bool:
    """Return whether the prefix uses the shared CuTe DSL runtime."""
    return prefix in CUTLASS_FAMILY_DSL_PREFIXES


def _parse_keep_tokens(raw: str, prefix: str = "") -> frozenset[str]:
    """
    Parse the value of [DSL]_KEEP into a frozenset of canonical artifact tokens.

    Accepts a comma-separated list of tokens (case-insensitive).
    The special value ``all`` expands to every token in ``_KEEP_ALL_TOKENS``.
    Unknown tokens are logged as warnings and ignored.

    Token semantics:
      ir               — IR after canonicalize+cse (clean, human-readable)
      ir-debug         — Raw IR before any passes (old KEEP_IR=1 behaviour)
      ptx              — PTX assembly
      cubin            — CUBIN binary
    """
    tokens = frozenset(t.strip().lower() for t in raw.split(",") if t.strip())
    if "all" in tokens:
        return _KEEP_ALL_TOKENS
    unknown = tokens - _KEEP_VALID_TOKENS
    if unknown:
        message = f"{prefix}_KEEP" if prefix else "[DSL]_KEEP"
        log().warning(
            "%s: unknown token(s) %s will be ignored. Valid tokens: %s",
            message,
            sorted(unknown),
            sorted(_KEEP_VALID_TOKENS),
        )
    return tokens - unknown


# =============================================================================
# Environment Variable Helpers
# =============================================================================


@lru_cache(maxsize=None)
def get_str_env_var(var_name: str, default_value: str | None = None) -> str | None:
    """
    Get the string value of an environment variable.
    Note that the value is cached after the first call.
    """
    value = os.getenv(var_name)
    return value if value is not None else default_value


@lru_cache(maxsize=None)
def get_bool_env_var(var_name: str, default_value: bool = False) -> bool:
    """
    Get the value of a boolean environment variable.
    If the value it not in False, 0, or empty string, it is considered True.
    Note that the value is cached after the first call.
    """
    value = get_str_env_var(var_name)
    if value is None:
        return default_value
    return value not in {"False", "0", ""}


@lru_cache(maxsize=None)
def get_int_env_var(var_name: str, default_value: int = 0) -> int:
    """
    Get the value of an integer environment variable.
    If the value is not a valid integer, the default value 0 is returned.
    Note that the value is cached after the first call.
    """
    value = get_str_env_var(var_name)
    return int(value) if value and value.isdigit() else default_value


@lru_cache(maxsize=None)
def get_int_or_none_env_var(
    var_name: str, default_value: int | None = None
) -> int | None:
    """
    Get the value of an integer or None union environment variable.
    If the value is not a valid integer, the default value 0 is returned.
    Note that the value is cached after the first call.
    """
    raw = get_str_env_var(var_name)
    if raw is None:
        return default_value

    value = raw.strip().lower()
    if value == "none":
        return None

    try:
        return int(value)
    except ValueError:
        return default_value


@lru_cache(maxsize=None)
def has_env_var(var_name: str) -> bool:
    """
    Check if an environment variable is set.
    Note that the value is cached after the first call.
    """
    return os.getenv(var_name) is not None


def detect_gpu_arch(prefix: str) -> str:
    """
    Attempts to detect the machine's GPU architecture.

    Returns:
        A string representing the GPU architecture (e.g. "70" for compute capability 7.0),
        or a default value(e.g. "sm_100") if the GPU architecture cannot be determined.
    """
    arch: tuple[int | None, int | None] = (None, None)
    try:
        arch = get_compute_capability_major_minor()
    except Exception as e:
        log().info("Failed to get CUDA compute capability: %s", e)

    if arch == (None, None):
        # default to sm_100
        arch = (10, 0)

    major, minor = arch
    suffix = ""
    if major >= 9:  # type: ignore[operator]
        suffix = "a"

    return f"sm_{major}{minor}{suffix}"


def find_libs_in_ancestors(
    start: str | Path, target_libs: set[str], lib_folder_guesses: list[str]
) -> list[str] | None:
    """
    Search ancestor directories for a candidate library folder containing all required libraries.

    Starting from the given path, this function traverses up through each parent directory.
    For every ancestor, it checks candidate subdirectories (specified by lib_folder_guesses)
    for files that match the required library extension (CLIB_EXT). Library file names are
    canonicalized by removing the "lib" prefix from their stem. If a candidate directory contains
    all of the required libraries (as specified in target_libs), the function returns a list of
    absolute paths to these library files.

    Parameters:
        start (str or Path): The starting directory from which to begin the search.
        target_libs (iterable of str): A collection of required library names (without the "lib" prefix).
        lib_folder_guesses (iterable of str): Relative paths from an ancestor directory that may contain the libraries.

    Returns:
        list[str] or None: A list of resolved paths to the required library files if found; otherwise, None.
    """
    # Traverse through all parent directories of the resolved starting path.
    for ancestor in Path(start).resolve().parents:
        # Iterate over each candidate relative directory path.
        for rel_path in lib_folder_guesses:
            target_dir = ancestor / rel_path
            # Skip if the candidate directory does not exist.
            if not target_dir.is_dir():
                continue

            # Initialize a list to hold the resolved paths of matching library files.
            libs_cand = []
            # Create a set of the remaining libraries we need to find.
            remaining_libs = set(target_libs)

            # Iterate over all items in the candidate directory.
            for p in target_dir.iterdir():
                # Consider only files with the expected library extension.
                if p.suffix == CLIB_EXT:
                    # Canonicalize the library name by removing the "lib" prefix.
                    lib_name = p.stem.removeprefix("lib")
                    # If this library is required, add its resolved path and mark it as found.
                    if lib_name in remaining_libs:
                        libs_cand.append(str(p.resolve()))
                        remaining_libs.remove(lib_name)

            # If all required libraries have been found, return the list of library paths.
            if len(remaining_libs) == 0:
                return libs_cand

    # Return None if no candidate directory contains all required libraries.
    return None


def _find_cuda_home() -> str | None:
    """Find the CUDA installation path using a series of heuristic methods.
    Methods below are checked in order, and the function returns on first match:
    1. Checking the environment variables CUDA_HOME and CUDA_PATH.
    2. Searching for the 'nvcc' compiler in the system PATH and deriving the path of cuda.
    3. Scanning common installation directories based on the operating system.
       - On Windows systems (when IS_WINDOWS is True), it searches in:
             C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v*.*
       - On Unix-like systems, it searches in:
             /usr/local/cuda*

    Returns:
        Optional[str]: The absolute CUDA installation path if found; otherwise, None.

    Note:
        The variable IS_WINDOWS is defined in the module scope.
    """
    # Guess #1
    cuda_home = get_str_env_var("CUDA_HOME") or get_str_env_var("CUDA_PATH")
    if cuda_home is None:
        # Guess #2
        nvcc_path = shutil.which("nvcc")
        if nvcc_path is not None:
            cuda_home = os.path.dirname(os.path.dirname(nvcc_path))
        else:
            # Guess #3
            if IS_WINDOWS:
                glob_pat = "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v*.*"
            else:
                glob_pat = "/usr/local/cuda*"
            cuda_homes = glob.glob(glob_pat)
            if len(cuda_homes) == 0:
                cuda_home = ""
            else:
                cuda_home = cuda_homes[0]
            if not os.path.exists(cuda_home):
                cuda_home = None
    return cuda_home


def get_prefix_dsl_libs(prefix: str) -> str | None:
    """
    Returns get_str_env_var('{prefix}_LIBS') if set.
    Otherwise, attempts to discover libs based on heuristics and return
    If not found, return None.
    """
    # Check if the environment variable is already set, if so, return it immediately.
    try:
        prefix_libs_existing = get_str_env_var(f"{prefix}_LIBS")
        if prefix_libs_existing:
            return prefix_libs_existing

        def get_libs_cand(start: str | Path) -> str | None:
            target_dsl_runtime_libs = {
                "cute_dsl_runtime",
            }
            lib_folder_guesses = [
                "lib",
            ]

            for target_libs in [
                target_dsl_runtime_libs,
            ]:
                libs_cand = find_libs_in_ancestors(
                    start, target_libs, lib_folder_guesses
                )
                if libs_cand:
                    dsl_libs = ":".join(libs_cand)
                    return dsl_libs
            return None

        # find from install folder
        dsl_libs = get_libs_cand(__file__)

        if not dsl_libs:
            # try to find from build folder structure
            dsl_libs = get_libs_cand(Path(__file__).parent.parent.resolve())

        if dsl_libs:
            return dsl_libs

        # Known CuTe-family DSLs share libcute_dsl_runtime.so. With pip
        # editable installs (`pip install -e`), the startup hook in
        # cutlass/_pth_hook.py sets CUTE_DSL_LIBS but not the per-prefix
        # variants, and the ancestor walk from the source tree cannot reach
        # the build/vendored lib directory. Fall back to CUTE_DSL_LIBS for
        # those aliases when their prefix-specific lookup fails.
        if is_cutlass_family_dsl_prefix(prefix) and prefix != "CUTE_DSL":
            fallback = os.getenv("CUTE_DSL_LIBS")
            if fallback:
                return fallback

        return None

    except Exception as e:
        log().info("default_env: exception on get_prefix_dsl_libs", e)
    return None


class LogEnvironmentManager:
    def __init__(self, prefix: str = "DSL") -> None:
        self.prefix = prefix

        # Logging options
        self.jit_time_profiling = get_bool_env_var(
            f"{prefix}_JIT_TIME_PROFILING", False
        )
        self.log_to_console = get_bool_env_var(f"{prefix}_LOG_TO_CONSOLE", False)
        self.log_to_file = get_bool_env_var(f"{prefix}_LOG_TO_FILE", False)
        if (
            has_env_var(f"{prefix}_LOG_LEVEL")
            and not self.log_to_console
            and not self.log_to_file
        ):
            log().warning(
                "Log level was set, but neither logging to file (%s_LOG_TO_FILE) nor"
                " logging to console (%s_LOG_TO_CONSOLE) is enabled!",
                prefix,
                prefix,
            )
        self.log_level = get_int_env_var(f"{prefix}_LOG_LEVEL", 1)


class EnvironmentVarManager(LogEnvironmentManager):
    """Manages environment variables for configuration options.

    Printing options:
    - [DSL_NAME]_LOG_TO_CONSOLE: Print logging to stderr (default: False)
    - [DSL_NAME]_PRINT_AFTER_PREPROCESSOR: Print after preprocess (default: False)
    - [DSL_NAME]_PRINT_IR: Print generated IR (default: False)
    - [DSL_NAME]_FILTER_STACKTRACE: Filter internal stacktrace (default: True)
    File options:
    - [DSL_NAME]_DUMP_DIR: Directory to dump the generated files (default: current working directory)
    - [DSL_NAME]_CACHE_DIR: Cache directory (default: /tmp/{dsl_name}_python_cache_{tmpfile_suffix})
    - [DSL_NAME]_LOG_TO_FILE: Store all logging into a file, excluding COMPILE_LOGS (default: False)
    - [DSL_NAME]_KEEP: Comma-separated list of artifacts to save to DUMP_DIR (default: "").
        Tokens:
          ir           — IR after canonicalize+cse (clean, human-readable)
          ir-debug     — Raw IR before any passes
          ptx          — PTX assembly
          cubin        — CUBIN binary
          all          — all of the above
        Example: CUTE_DSL_KEEP=ir,ptx
    # Deprecated — use [DSL_NAME]_KEEP instead:
    - [DSL_NAME]_KEEP_IR: (deprecated) use KEEP=ir-debug
    - [DSL_NAME]_KEEP_PTX: (deprecated) use KEEP=ptx
    - [DSL_NAME]_KEEP_CUBIN: (deprecated) use KEEP=cubin
    Other options:
    - [DSL_NAME]_SHOW_STACKTRACE: Show full stack traces on failure (default: False)
    - [DSL_NAME]_LINEINFO: Compile with `--lineinfo` enabling developer tools such as the profiler and debugger (default: False)
    - [DSL_NAME]_LOG_LEVEL: Logging level to set, for LOG_TO_CONSOLE or LOG_TO_FILE (default: 1).
    - [DSL_NAME]_DRYRUN: Generates IR only (default: False)
    - [DSL_NAME]_ARCH: GPU architecture (default: "sm_100")
    - [DSL_NAME]_WARNINGS_AS_ERRORS: Enable warnings as error (default: False)
    - [DSL_NAME]_WARNINGS_IGNORE: Ignore warnings (default: False)
    - [DSL_NAME]_ENABLE_OPTIMIZATION_WARNINGS: Enable warnings of optimization warnings (default: False)
    - [DSL_NAME]_JIT_TIME_PROFILING: Whether or not to profile the IR generation/compilation/execution time (default: False)
    - [DSL_NAME]_JIT_CACHE_MAX_ELEMS: Maximum number of JIT compiled functions to cache in memory (default: None). If None, the cache is unbounded.
    - [DSL_NAME]_NO_CACHE: Disable JIT cache (default: False)
    - [DSL_NAME]_DISABLE_FILE_CACHING: Disable file caching (default: False)
    - [DSL_NAME]_LIBS: Path to dependent shared libraries (default: None)
    - [DSL_NAME]_ENABLE_TVM_FFI: Enable TVM-FFI or not (default: False)
    - [DSL_NAME]_LOC_TRACEBACKS: Maximum depth of location tracebacks (default: 0)
    """

    def __init__(self, prefix: str = "DSL") -> None:
        super().__init__(prefix)

        # Printing options
        self.print_after_preprocessor = get_bool_env_var(
            f"{prefix}_PRINT_AFTER_PREPROCESSOR", False
        )
        self.print_ir = get_bool_env_var(f"{prefix}_PRINT_IR", False)
        self.filter_stacktrace = get_bool_env_var(f"{prefix}_FILTER_STACKTRACE", True)
        self.show_stacktrace = get_bool_env_var(f"{prefix}_SHOW_STACKTRACE", False)
        self.lineinfo = get_bool_env_var(f"{prefix}_LINEINFO", False)
        self.no_cache = get_bool_env_var(f"{prefix}_NO_CACHE", False)
        self.jit_cache_max_elems = get_int_or_none_env_var(
            f"{prefix}_JIT_CACHE_MAX_ELEMS", None
        )
        if self.no_cache:
            self.jit_cache_max_elems = 0
        self.dump_dir = get_str_env_var(
            f"{prefix}_DUMP_DIR", get_default_file_dump_root()
        )
        # File options
        self.cache_dir = get_str_env_var(f"{prefix}_CACHE_DIR", None)

        # ------------------------------------------------------------------ #
        # Artifact keep — [DSL]_KEEP=<comma-list>                            #
        # ------------------------------------------------------------------ #
        _keep_raw = get_str_env_var(f"{prefix}_KEEP", "")
        _keep_tokens: set[str] = set(
            _parse_keep_tokens(_keep_raw, prefix) if _keep_raw else frozenset()
        )

        if get_bool_env_var(f"{prefix}_KEEP_IR", False):
            warnings.warn(
                f"{prefix}_KEEP_IR is deprecated; use {prefix}_KEEP=ir-debug instead.",
                DeprecationWarning,
                stacklevel=2,
            )
            _keep_tokens.add("ir-debug")
        if get_bool_env_var(f"{prefix}_KEEP_PTX", False):
            warnings.warn(
                f"{prefix}_KEEP_PTX is deprecated; use {prefix}_KEEP=ptx instead.",
                DeprecationWarning,
                stacklevel=2,
            )
            _keep_tokens.add("ptx")
        if get_bool_env_var(f"{prefix}_KEEP_CUBIN", False):
            warnings.warn(
                f"{prefix}_KEEP_CUBIN is deprecated; use {prefix}_KEEP=cubin instead.",
                DeprecationWarning,
                stacklevel=2,
            )
            _keep_tokens.add("cubin")

        self.keep_tokens: frozenset[str] = frozenset(_keep_tokens)

        # Derived boolean attributes — used by compiler.py and dsl.py.
        # keep_ir_clean: save IR after canonicalize+cse (the readable form).
        self.keep_ir_clean: bool = "ir" in self.keep_tokens
        # keep_ir: save raw IR before any passes (old KEEP_IR=1 semantics).
        self.keep_ir: bool = "ir-debug" in self.keep_tokens
        self.keep_ptx: bool = "ptx" in self.keep_tokens
        self.keep_cubin: bool = "cubin" in self.keep_tokens
        # Other options
        self.dryrun = get_bool_env_var(f"{prefix}_DRYRUN", False)
        self.arch = get_str_env_var(f"{prefix}_ARCH", detect_gpu_arch(prefix))
        self.warnings_as_errors = get_bool_env_var(
            f"{prefix}_WARNINGS_AS_ERRORS", False
        )
        self.warnings_ignore = get_bool_env_var(f"{prefix}_WARNINGS_IGNORE", False)
        self.enable_optimization_warnings = get_bool_env_var(
            f"{prefix}_ENABLE_OPTIMIZATION_WARNINGS", False
        )
        self.disable_file_caching = get_bool_env_var(
            f"{prefix}_DISABLE_FILE_CACHING", False
        )
        # set mlir shared libraries
        self.shared_libs = get_prefix_dsl_libs(prefix)

        # whether to enable assert in host and device code
        self.enable_assertions = get_bool_env_var(f"{prefix}_ENABLE_ASSERTIONS", False)

        self.enable_tvm_ffi = get_bool_env_var(f"{prefix}_ENABLE_TVM_FFI", False)

        self.loc_tracebacks = get_int_env_var(f"{prefix}_LOC_TRACEBACKS", 0)
