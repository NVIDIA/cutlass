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
import inspect
import warnings
from dataclasses import dataclass, field
from pathlib import Path
from functools import cache, lru_cache
from typing import Any, Callable, get_args

from ..base_dsl.runtime.cuda import get_compute_capability_major_minor
from .common import DSLRuntimeError, DSLUserCodeError
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
        "sass",
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
      sass             — SASS disassembly
    """
    tokens = frozenset(t.strip().lower() for t in raw.split(",") if t.strip())
    if "all" in tokens:
        return _KEEP_ALL_TOKENS
    unknown = tokens - _KEEP_VALID_TOKENS
    return tokens - unknown


#: Superseded per-artifact switches, paired with the [DSL]_KEEP token each one
#: now folds into. Kept so existing scripts keep working for a release.
_DEPRECATED_KEEP_SWITCHES: tuple[tuple[str, str], ...] = (
    ("KEEP_IR", "ir-debug"),
    ("KEEP_PTX", "ptx"),
    ("KEEP_CUBIN", "cubin"),
    ("KEEP_SASS", "sass"),
)


def _default_dump_dir() -> str:
    """Directory artifacts land in when ``[DSL]_DUMP_DIR`` is unset."""
    return str(get_default_file_dump_root())


def _resolve_keep_tokens(prefix: str) -> frozenset[str]:
    """Artifacts requested by ``[DSL]_KEEP``, with the deprecated switches folded in.

    Each superseded switch warns and contributes its token, so the rest of the
    DSL only ever consults the token set.
    """
    raw = get_str_env_var(f"{prefix}_KEEP", "")
    tokens: set[str] = set(_parse_keep_tokens(raw, prefix) if raw else frozenset())
    for switch, token in _DEPRECATED_KEEP_SWITCHES:
        if get_bool_env_var(f"{prefix}_{switch}", False):
            warnings.warn(
                f"{prefix}_{switch} is deprecated; use {prefix}_KEEP={token} instead.",
                DeprecationWarning,
                stacklevel=2,
            )
            tokens.add(token)
    return frozenset(tokens)



@dataclass(frozen=True)
class EnvVar:
    """One setting on an :class:`EnvironmentVarManager`.

    Written in the class body as ``attribute: type = env_var(...)``, so the
    attribute, its type and where its value comes from are stated together and
    exactly once. ``source`` is either the environment variable's suffix -- the
    value is read from ``{prefix}_{source}`` -- or a function of the manager
    that computes it, for a setting with no variable of its own. How to read
    the environment follows from the annotation.

    ``affects_compile`` says whether the setting is part of the JIT cache key;
    it is required, so a setting cannot be added without answering.
    """

    source: str | Callable[[Any], Any]
    affects_compile: bool = field(kw_only=True)
    default: Any = None
    read_as: str | None = None
    attribute: str = field(default="", init=False)

    def __post_init__(self) -> None:
        if not isinstance(self.source, str) and (
            self.default is not None or self.read_as is not None
        ):
            raise DSLRuntimeError(
                "A computed setting takes neither `default` nor `read_as`: it has no "
                "environment variable to fall back from or to be read under."
            )

    def __set_name__(self, owner: type, name: str) -> None:
        object.__setattr__(self, "attribute", name)

    @property
    def key_name(self) -> str:
        return self.read_as or self.attribute

    def resolve(
        self, manager: Any, prefix: str, parser: Callable[..., Any] | None
    ) -> Any:
        """Value this setting takes for ``manager``."""
        if not isinstance(self.source, str):
            return self.source(manager)
        assert parser is not None
        # A default that reads other settings is written as a function of the
        # manager. There is no ambiguity to resolve: parser_for_type admits only
        # bool, int and str, so a callable is never itself a legitimate default.
        default = self.default(manager) if callable(self.default) else self.default
        return parser(f"{prefix}_{self.source}", default)


def env_var(
    source: str | Callable[[Any], Any],
    *,
    affects_compile: bool,
    default: Any = None,
    read_as: str | None = None,
) -> Any:
    """Declare a setting, as the default of an annotated class attribute.

    ``source`` is the variable's suffix -- the value is read from
    ``{prefix}_{source}`` -- or a function of the manager, for a setting
    computed rather than read. Either way it may use anything declared above.

    Returns ``Any``, the way :func:`dataclasses.field` does, so the declaration
    can carry the attribute's real type. ``default`` may itself be a function
    of the manager when it depends on a setting declared above.
    """
    return EnvVar(
        source,
        affects_compile=affects_compile,
        default=default,
        read_as=read_as,
    )


def _annotated_type(owner: type, attr: str) -> Any:
    """Declared type of ``attr``, searched up ``owner``'s MRO."""
    for klass in owner.__mro__:
        annotation = inspect.get_annotations(klass).get(attr)
        if annotation is not None:
            return annotation
    raise DSLRuntimeError(
        f"{owner.__name__}.{attr} has no type annotation, so the parser for its "
        f"environment variable cannot be determined. Annotate it on the class."
    )


def parser_for_type(annotation: Any) -> Callable[..., Any]:
    args = get_args(annotation)
    optional = type(None) in args
    base = next((a for a in args if a is not type(None)), annotation)
    if base is bool:
        return get_bool_env_var
    if base is int:
        return get_int_or_none_env_var if optional else get_int_env_var
    if base is str:
        return get_str_env_var
    raise DSLRuntimeError(
        f"No environment-variable reader for {annotation!r}. Give the setting a "
        f"bool, int or str annotation, or compute it from the manager instead."
    )


class EnvVarSpec:
    """Turns the settings declared in a class body into a spec.

    ``_ENV_VAR_SPEC`` is what a class declares plus everything it inherits, in
    declaration order. A subclass redeclaring an attribute replaces the
    inherited declaration and keeps its position.
    """

    _ENV_VAR_SPEC: tuple[EnvVar, ...] = ()

    def __init_subclass__(cls, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        composed = {entry.attribute: entry for entry in cls._ENV_VAR_SPEC}
        composed.update(
            {v.attribute: v for v in vars(cls).values() if isinstance(v, EnvVar)}
        )
        cls._ENV_VAR_SPEC = tuple(composed.values())

    def _apply_env_var_spec(self, prefix: str) -> None:
        for entry in type(self)._ENV_VAR_SPEC:
            parser = (
                parser_for_type(_annotated_type(type(self), entry.attribute))
                if isinstance(entry.source, str)
                else None
            )
            setattr(self, entry.attribute, entry.resolve(self, prefix, parser))

    def cache_key_str(self) -> str:
        """Return the settings that are part of the JIT cache key."""
        rendered = []
        for entry in sorted(self._ENV_VAR_SPEC, key=lambda e: e.key_name):
            if not entry.affects_compile:
                continue
            value = getattr(self, entry.key_name)
            if value is None:
                continue
            rendered.append(f"{entry.key_name}={_render_cache_key_value(value)};")
        return "".join(rendered)


def _render_cache_key_value(value: object) -> str:
    # Sorted, because frozenset iteration order is randomized per process.
    if isinstance(value, (set, frozenset)):
        return repr(tuple(sorted(value, key=repr)))
    return repr(value)


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


_BOOL_TRUE_VALUES = frozenset({"1", "true", "yes", "on"})
_BOOL_FALSE_VALUES = frozenset({"0", "false", "no", "off"})


@lru_cache(maxsize=None)
def get_bool_env_var(var_name: str, default_value: bool = False) -> bool:
    """
    Get the value of a boolean environment variable.

    Recognized values (case-insensitive, surrounding whitespace ignored):
      * Truthy:   ``1``, ``true``, ``yes``, ``on``
      * Falsy:    ``0``, ``false``, ``no``, ``off``

    An unset variable, or one whose value is empty (or whitespace only),
    returns ``default_value``.

    The parsed value is cached after the first call (per ``var_name`` /
    ``default_value`` pair).

    Raises:
        ValueError: if the variable is set to any other value.
    """
    raw = get_str_env_var(var_name)
    if raw is None:
        return default_value
    normalized = raw.strip().lower()
    if normalized == "":
        return default_value
    if normalized in _BOOL_TRUE_VALUES:
        return True
    if normalized in _BOOL_FALSE_VALUES:
        return False
    raise ValueError(
        f"Invalid value for environment variable {var_name}={raw!r}. "
        f"Expected a boolean (case-insensitive): "
        f"{sorted(_BOOL_TRUE_VALUES) + sorted(_BOOL_FALSE_VALUES)} "
        f"or empty/unset to use the default ({default_value!r})."
    )


@lru_cache(maxsize=None)
def get_int_env_var(var_name: str, default_value: int = 0) -> int:
    """
    Get the value of an integer environment variable.

    Surrounding whitespace is ignored. An unset variable or one with an
    empty value returns ``default_value``. Negative integers (e.g.
    ``-5``) are accepted.

    Raises:
        ValueError: if the variable is set to a value that is not a
            valid base-10 integer.

    The parsed value is cached after the first call (per ``var_name`` /
    ``default_value`` pair).
    """
    raw = get_str_env_var(var_name)
    if raw is None:
        return default_value
    stripped = raw.strip()
    if stripped == "":
        return default_value
    try:
        return int(stripped)
    except ValueError:
        raise ValueError(
            f"Invalid value for environment variable {var_name}={raw!r}. "
            f"Expected a base-10 integer, or empty/unset to use the "
            f"default ({default_value!r})."
        ) from None


@lru_cache(maxsize=None)
def get_int_or_none_env_var(
    var_name: str, default_value: int | None = None
) -> int | None:
    """
    Get the value of an integer-or-``None`` environment variable.

    Recognized values (case-insensitive, surrounding whitespace ignored):
      * ``"none"``                       returns ``None``
      * any base-10 integer literal      returns that integer (negatives accepted)

    An unset variable or one with an empty value returns ``default_value``.

    Raises:
        ValueError: if the variable is set to anything else.

    The parsed value is cached after the first call (per ``var_name`` /
    ``default_value`` pair).
    """
    raw = get_str_env_var(var_name)
    if raw is None:
        return default_value
    normalized = raw.strip().lower()
    if normalized == "":
        return default_value
    if normalized == "none":
        return None
    try:
        return int(normalized)
    except ValueError:
        raise ValueError(
            f"Invalid value for environment variable {var_name}={raw!r}. "
            f"Expected a base-10 integer, the literal 'none', or "
            f"empty/unset to use the default ({default_value!r})."
        ) from None


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
    assert major is not None and minor is not None
    suffix = ""
    if major >= 9:
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



# Fallback minimum nvdisasm (CUDA Toolkit) version for SASS dumping, as
# (major, minor). Used only when the build-time CUDA version is unavailable
# (see _min_nvdisasm_version).
MIN_NVDISASM_VERSION: tuple[int, int] = (13, 3)


def _min_nvdisasm_version() -> tuple[int, int]:
    """Minimum supported nvdisasm version for SASS dumping.

    The floor is the CUDA version the DSL was built with — the bundled
    toolchain that produces the CUBIN. nvdisasm is versioned with the CUDA
    Toolkit it ships in, so the two are directly comparable; an older
    nvdisasm may not understand the CUBINs this toolchain emits, while a
    newer one can always read them. There is deliberately no upper bound:
    the cu12-built DSL, for example, ships with the 13.3 nvdisasm wheel
    (the first version published on PyPI), which disassembles its CUBINs
    fine. Falls back to the hardcoded pin floor when the build-time version
    is unavailable (e.g. a DSL client that does not implement
    _get_cuda_version).
    """
    try:
        from .version_info import CUDA_VERSION
    except Exception:
        return MIN_NVDISASM_VERSION
    return (CUDA_VERSION.major, CUDA_VERSION.minor)



def _nvdisasm_suggestion() -> str:
    floor = _min_nvdisasm_version()
    return "\n".join(
        [
            f"SASS dumping requires nvdisasm >= {floor[0]}.{floor[1]}."
            " Any of the following works:",
            "  • pip install nvidia-cutlass-dsl[sass]",
            "  • install or upgrade a local CUDA Toolkit and expose it via"
            " CUDA_HOME/CUDA_PATH",
        ]
    )



def _nvdisasm_from_wheel() -> str | None:
    from importlib import metadata

    try:
        dist = metadata.distribution("nvidia-cuda-nvdisasm")
    except metadata.PackageNotFoundError:
        return None
    if dist.files is None:
        return None
    for entry in dist.files:
        if entry.name == "nvdisasm":
            binpath = Path(str(dist.locate_file(entry)))
            if binpath.is_file():
                return str(binpath)
    return None


def _nvdisasm_from_cuda_toolkit() -> str | None:
    """Probe the CUDA Toolkit discovered by ``_find_cuda_home`` (CUDA_HOME /
    CUDA_PATH, the root derived from nvcc on PATH, or a common install
    location such as /usr/local/cuda*).

    Returns None when no toolkit is found or the toolkit has no nvdisasm.
    """
    root = _find_cuda_home()
    if not root:
        return None
    name = "nvdisasm.exe" if IS_WINDOWS else "nvdisasm"
    binpath = Path(root) / "bin" / name
    return str(binpath) if binpath.is_file() else None


def _get_nvdisasm_version(binary: str) -> tuple[int, int] | None:
    """Return the (major, minor) CUDA version reported by ``nvdisasm --version``."""
    import re
    import subprocess

    try:
        result = subprocess.run(
            [binary, "--version"], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    # e.g. "Cuda compilation tools, release 13.5, V13.5.0"
    match = re.search(r"release (\d+)\.(\d+)", result.stdout)
    if match is None:
        return None
    return (int(match.group(1)), int(match.group(2)))


@cache
def _find_nvdisasm_binary() -> str:
    """Locate a compatible nvdisasm binary for SASS dumping.

    Probe order (first hit wins):
      1. the nvidia-cuda-nvdisasm pip wheel (installed via the [sass] extra)
      2. the CUDA Toolkit located by _find_cuda_home (CUDA_HOME / CUDA_PATH,
         the root derived from nvcc on PATH, or /usr/local/cuda*)

    The wheel is probed before the local toolkit so that users who installed
    the [sass] extra get a predictable version regardless of local CTK state.

    The minimum supported version is derived from the CUDA version the DSL
    was built with (see _min_nvdisasm_version); an incompatible version is a
    hard error.
    """
    binary = None
    from_env_var = False
    if binary is None:
        binary = _nvdisasm_from_wheel() or _nvdisasm_from_cuda_toolkit()
    if binary is None:
        raise DSLUserCodeError(
            "SASS dumping requires the nvdisasm tool, but it was not found.",
            suggestion=_nvdisasm_suggestion(),
        )
    version = _get_nvdisasm_version(binary)
    floor = _min_nvdisasm_version()
    if version is None or version < floor:
        found = (
            "an unknown version"
            if version is None
            else f"version {version[0]}.{version[1]}"
        )
        raise DSLUserCodeError(
            f"nvdisasm at {binary!r} reports {found}, which is not supported"
            " for SASS dumping.",
            suggestion=_nvdisasm_suggestion(),
        )
    return binary


def dump_sass(
    cubin_path: str,
    sass_path: str | None,
    flags: str,
) -> None:
    """Disassemble a CUBIN file into SASS.

    If sass_path is None, the SASS is written to stderr.
    Otherwise it is written to the given file path.
    """
    import shlex
    import subprocess

    if not cubin_path or not os.path.exists(cubin_path):
        raise DSLUserCodeError(
            f"Cannot dump SASS: CUBIN file does not exist at {cubin_path!r}."
        )

    nvdisasm = _find_nvdisasm_binary()
    tokens = [nvdisasm, *shlex.split(flags), cubin_path]

    if sass_path:
        with open(sass_path, "w") as sass_file:
            subprocess.run(tokens, stdout=sass_file, check=True)
    else:
        subprocess.run(tokens, stdout=sys.stderr, check=True)


# Cache the result to avoid re-searching the same directory multiple times
@lru_cache(maxsize=5)
def _get_libs_cand(start: str | Path) -> str | None:
    target_dsl_runtime_libs = {
        "cute_dsl_runtime",
    }
    lib_folder_guesses = [
        "lib",
    ]

    try:
        from .version_info import CUDA_VERSION

        major = CUDA_VERSION.major
        lib_folder_guesses.append(f"cu{major}/lib")
    except Exception:
        lib_folder_guesses.extend(["cu12/lib", "cu13/lib"])

    for target_libs in [
        target_dsl_runtime_libs,
    ]:
        libs_cand = find_libs_in_ancestors(start, target_libs, lib_folder_guesses)
        if libs_cand:
            # Consumers split this on os.pathsep, which is ";" on
            # Windows -- ":" would tear the "C:\..." drive letters.
            dsl_libs = os.pathsep.join(libs_cand)
            return dsl_libs
    return None


def get_prefix_dsl_libs(prefix: str) -> str | None:
    """
    Return ``{prefix}_LIBS`` when set, then the runtime selected for CuTeDSL
    when ``prefix`` is another CuTe-family DSL, and finally try filesystem
    discovery. Return ``None`` if no runtime libraries can be found.
    """
    # Check if the environment variable is already set, if so, return it immediately.
    try:
        prefix_libs_existing = get_str_env_var(f"{prefix}_LIBS")
        if prefix_libs_existing:
            return prefix_libs_existing

        # The startup hook selects the CuTeDSL runtime through CUTE_DSL_LIBS.
        # CuTe-family aliases share that runtime and must not independently
        # discover a different CTK flavor first.
        if is_cutlass_family_dsl_prefix(prefix) and prefix != "CUTE_DSL":
            cute_dsl_libs = os.getenv("CUTE_DSL_LIBS")
            if cute_dsl_libs:
                return cute_dsl_libs

        # find from install folder
        dsl_libs = _get_libs_cand(__file__)

        if not dsl_libs:
            # try to find from build folder structure
            dsl_libs = _get_libs_cand(Path(__file__).parent.parent.resolve())

        if dsl_libs:
            return dsl_libs

        return None

    except Exception as e:
        log().info("default_env: exception on get_prefix_dsl_libs", e)
    return None


class LogEnvironmentManager(EnvVarSpec):
    jit_time_profiling: bool = env_var(
        "JIT_TIME_PROFILING", affects_compile=False, default=False
    )
    log_to_console: bool = env_var(
        "LOG_TO_CONSOLE", affects_compile=False, default=False
    )
    log_to_file: bool = env_var("LOG_TO_FILE", affects_compile=False, default=False)
    log_level: int = env_var("LOG_LEVEL", affects_compile=False, default=1)

    def __init__(self, prefix: str = "DSL") -> None:
        self.prefix = prefix

        self._apply_env_var_spec(prefix)

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
          sass         — SASS disassembly
          all          — all of the above
        Example: CUTE_DSL_KEEP=ir,ptx
    # Deprecated — use [DSL_NAME]_KEEP instead:
    - [DSL_NAME]_KEEP_IR: (deprecated) use KEEP=ir-debug
    - [DSL_NAME]_KEEP_PTX: (deprecated) use KEEP=ptx
    - [DSL_NAME]_KEEP_CUBIN: (deprecated) use KEEP=cubin
    - [DSL_NAME]_KEEP_SASS: (deprecated) use KEEP=sass
    Other options:
    - [DSL_NAME]_DEBUG: Master debug switch for DSL developers (default: False).
      When True, raises the default of LINEINFO, SHOW_STACKTRACE (and disables
      FILTER_STACKTRACE) and ENABLE_OPTIMIZATION_WARNINGS;
      attributes MLIR ops to the closest (library) frame; and runs full
      per-launch argument validation. These defaults remain independently
      overridable by their own env vars. Trace-time MLIR op verification
      (CUTE_DSL_VERIFY_TRACE) is always enabled while debug mode is on.
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
    - [DSL_NAME]_ENABLE_PYIR: Enable PYIR to SCF conversion pass (default: False)
    - [DSL_NAME]_COMPILER_OPT: Compact compiler option string (default: "").
      Errors always show and fail compilation (no flag needed); warnings and
      remarks are opt-in and non-fatal. A {<cat>} selector shows only that
      category; bare shows all categories. Forms accepted:
        warnings                    — show all warnings
        warnings{nvvm}              — show only nvvm-category warnings
        remarks                     — show all remarks
        remarks{nvvm}               — show only nvvm (sync) remarks
        remarks{ptx}                — show ptxas perf remarks (spills, local mem)
        iket                        — enable IKET (In-Kernel Event Tracing) instrumentation
      Examples:
        CUTE_DSL_COMPILER_OPT="warnings{nvvm}"
        CUTE_DSL_COMPILER_OPT="remarks{ptx}"
        CUTE_DSL_COMPILER_OPT="iket"
      The same option strings are accepted by cute.compile(..., options=...).

    """

    # Master switch for DSL developers: raises the default of a curated set of
    # diagnostic settings below, each still overridable by its own variable. One of
    # those is lineinfo, which reaches GenerateLineInfo; it also injects
    # warnings{nvvm} and alters MLIR locations.
    debug: bool = env_var("DEBUG", affects_compile=True, default=False)
    print_after_preprocessor: bool = env_var(
        "PRINT_AFTER_PREPROCESSOR", affects_compile=False, default=False
    )
    print_ir: bool = env_var("PRINT_IR", affects_compile=False, default=False)
    # Selects between a full traceback and the formatted message on the exception
    # path. Supplies the default of filter_stacktrace, never of lineinfo -- that
    # coupling runs through debug.
    show_stacktrace: bool = env_var(
        "SHOW_STACKTRACE", affects_compile=False, default=lambda mgr: mgr.debug
    )
    # Decides whether the frame-filtering excepthook is installed. Defaulted off
    # under debug or show_stacktrace so internal DSL frames stay visible.
    filter_stacktrace: bool = env_var(
        "FILTER_STACKTRACE",
        affects_compile=False,
        default=lambda mgr: not (mgr.debug or mgr.show_stacktrace),
    )
    enable_pyir: bool = env_var("ENABLE_PYIR", affects_compile=True, default=False)
    auto_m2s: bool = env_var("AUTO_M2S", affects_compile=True, default=False)
    tolerate_m2m: bool = env_var("TOLERATE_M2M", affects_compile=True, default=True)
    lineinfo: bool = env_var(
        "LINEINFO", affects_compile=True, default=lambda mgr: mgr.debug
    )
    # Governs whether results are cached, not what is compiled.
    no_cache: bool = env_var("NO_CACHE", affects_compile=False, default=False)
    jit_cache_max_elems: int | None = env_var(
        "JIT_CACHE_MAX_ELEMS", affects_compile=False, default=None
    )
    # Chooses where artifacts are written. Reaches the compiler only through the
    # keep_* dump paths, and those force caching off.
    dump_dir: str = env_var(
        "DUMP_DIR",
        affects_compile=False,
        default=lambda mgr: _default_dump_dir(),
    )
    # Unread; the cache root is resolved separately from the environment by
    # get_default_generated_ir_path.
    cache_dir: str | None = env_var("CACHE_DIR", affects_compile=False, default=None)
    # Every artifact the tokens below request is dumped either from build_module,
    # which runs before the cache is consulted, or from a path that forces
    # no_cache -- so none of them can be served stale, and the raw token set does
    # not belong in the key either. A token wired up later answers for itself:
    # the flag deriving it has to state its own affects_compile.
    keep_tokens: frozenset[str] = env_var(
        lambda mgr: _resolve_keep_tokens(mgr.prefix), affects_compile=False
    )
    # Saves IR after canonicalize+cse, the readable form.
    keep_ir_clean: bool = env_var(
        lambda mgr: "ir" in mgr.keep_tokens, affects_compile=False
    )
    # Saves raw IR before any passes, the old KEEP_IR=1 semantics.
    keep_ir: bool = env_var(
        lambda mgr: "ir-debug" in mgr.keep_tokens, affects_compile=False
    )
    keep_ptx: bool = env_var(
        lambda mgr: "ptx" in mgr.keep_tokens, affects_compile=False
    )
    keep_cubin: bool = env_var(
        lambda mgr: "cubin" in mgr.keep_tokens, affects_compile=False
    )
    keep_sass: bool = env_var(
        lambda mgr: "sass" in mgr.keep_tokens, affects_compile=False
    )
    dryrun: bool = env_var("DRYRUN", affects_compile=True, default=False)
    # Stored under _arch because the public spelling belongs to the arch property,
    # which detects lazily; read_as sends the key through that property so a
    # not-yet-detected architecture cannot drop out of it.
    _arch: str | None = env_var(
        "ARCH", affects_compile=True, default=None, read_as="arch"
    )
    # Installs a warnings.filterwarnings("error") that turns a warning raised
    # during compilation into an exception. Keyed because an artifact compiled
    # while warnings were tolerated may be one that this setting is meant to
    # reject, and a cache hit skips the compile that would have rejected it.
    warnings_as_errors: bool = env_var(
        "WARNINGS_AS_ERRORS", affects_compile=True, default=False
    )
    warnings_ignore: bool = env_var(
        "WARNINGS_IGNORE", affects_compile=False, default=False
    )
    enable_optimization_warnings: bool = env_var(
        "ENABLE_OPTIMIZATION_WARNINGS",
        affects_compile=False,
        default=lambda mgr: mgr.debug,
    )
    # Governs whether results are cached, not what is compiled.
    disable_file_caching: bool = env_var(
        "DISABLE_FILE_CACHING", affects_compile=False, default=False
    )
    compiler_opt: str = env_var("COMPILER_OPT", affects_compile=True, default="")
    compiler_backend: str = env_var(
        "COMPILER_BACKEND", affects_compile=True, default="legacy"
    )
    # MLIR runtime libraries linked by the JIT.
    shared_libs: str | None = env_var(
        lambda mgr: get_prefix_dsl_libs(mgr.prefix), affects_compile=True
    )
    # Enables asserts in host and device code.
    enable_assertions: bool = env_var(
        "ENABLE_ASSERTIONS", affects_compile=True, default=False
    )
    enable_tvm_ffi: bool = env_var(
        "ENABLE_TVM_FFI", affects_compile=True, default=False
    )
    loc_tracebacks: int = env_var("LOC_TRACEBACKS", affects_compile=True, default=0)

    def __init__(self, prefix: str = "DSL") -> None:
        super().__init__(prefix)

        # PyIR-mode fact per DSL prefix: the verify-failure funnel names a
        # mixed-flag configuration when a cross-DSL compile trips dominance.
        try:
            from .pyir_state import _pyir_register_mode_fact

            _pyir_register_mode_fact(prefix, self.enable_pyir)
        except ImportError:
            pass

        if self.no_cache:
            self.jit_cache_max_elems = 0

        # Fail at construction (rather than after a long compile) when the
        # user asked for SASS dumping but no usable nvdisasm is available.
        _check_nvdisasm = True
        if _check_nvdisasm and self.keep_sass:
            _find_nvdisasm_binary()

    def configured_arch(self) -> str | None:
        """Return a known architecture without probing the CUDA driver.

        ``arch`` detects on first access. Error formatting must not do that,
        because a failed probe raises ``DSLCudaRuntimeError`` whose constructor
        reads the architecture again.
        """
        return self._arch

    @property
    def arch(self) -> str:
        """GPU architecture, from ``{prefix}_ARCH`` or detected on first access.

        Detection probes the CUDA driver, so it is deferred out of
        construction (and thus out of importing the DSL, which builds the
        singletons eagerly) to the first read that actually needs an arch.
        """
        if self._arch is None:
            self._arch = detect_gpu_arch(self.prefix)
        return self._arch

    @arch.setter
    def arch(self, value: str) -> None:
        self._arch = value

    @arch.deleter
    def arch(self) -> None:
        """Reset to the construction-time state (``{prefix}_ARCH`` or lazy
        detection), so ``mock.patch.object`` teardown restores the default."""
        self._arch = get_str_env_var(f"{self.prefix}_ARCH")
