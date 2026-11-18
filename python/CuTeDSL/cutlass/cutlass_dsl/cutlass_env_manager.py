# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Environment-variable management for the CuTe DSL family."""

import os
import sys
from enum import Enum
from functools import lru_cache
from pathlib import Path

from ..base_dsl.env_manager import (
    EnvironmentVarManager,
    env_var,
    get_str_env_var,
)
from ..base_dsl.utils.logger import log


_CLIB_EXT = ".dll" if sys.platform == "win32" else ".so"
_CUTE_DSL_RUNTIME_LIBRARY_NAME = (
    "cute_dsl_runtime.dll" if sys.platform == "win32" else "libcute_dsl_runtime.so"
)


class CutlassFamilyDSL(Enum):
    """CuTe-family DSL kinds and their environment-variable prefixes."""

    CUTE = "CUTE_DSL"
    CUTE_EXPERIMENTAL = "CUTE_EXPERIMENTAL_DSL"
    def __str__(self) -> str:
        """Return the environment-variable prefix for this DSL kind."""
        return self.value


def find_libs_in_ancestors(
    start: str | Path, target_libs: set[str], lib_folder_guesses: list[str]
) -> list[str] | None:
    """Find one ancestor library directory containing every requested library.

    Library names are matched without the platform's ``lib`` prefix and must
    have the platform's shared-library extension.
    """
    for ancestor in Path(start).resolve().parents:
        for relative_path in lib_folder_guesses:
            candidate_dir = ancestor / relative_path
            if not candidate_dir.is_dir():
                continue

            candidate_libs: list[str] = []
            remaining_libs = set(target_libs)
            for candidate in candidate_dir.iterdir():
                if candidate.suffix != _CLIB_EXT:
                    continue
                library_name = candidate.stem.removeprefix("lib")
                if library_name in remaining_libs:
                    candidate_libs.append(str(candidate.resolve()))
                    remaining_libs.remove(library_name)

            if not remaining_libs:
                return candidate_libs

    return None


@lru_cache(maxsize=5)
def _get_libs_cand(start: str | Path) -> str | None:
    """Find the CuTe DSL runtime library above ``start``."""
    lib_folder_guesses = ["lib"]

    from ..base_dsl.version_info import CUDA_VERSION

    lib_folder_guesses.append(f"cu{CUDA_VERSION.major}/lib")

    candidate_libs = find_libs_in_ancestors(
        start, {"cute_dsl_runtime"}, lib_folder_guesses
    )
    if candidate_libs:
        # ``os.pathsep`` preserves Windows drive-letter colons.
        return os.pathsep.join(candidate_libs)
    return None



def get_prefix_dsl_libs(
    dsl_kind: CutlassFamilyDSL = CutlassFamilyDSL.CUTE,
) -> str | None:
    """Resolve the runtime libraries for a CuTe-family DSL kind.

    An explicit ``{prefix}_LIBS`` wins. Other CuTe-family kinds then reuse
    ``CUTE_DSL_LIBS`` so every alias uses the native loader's selected CUDA
    toolkit flavor. Filesystem discovery is the final fallback.
    """
    if not isinstance(dsl_kind, CutlassFamilyDSL):
        raise TypeError(
            "dsl_kind must be a CutlassFamilyDSL enum value, got "
            f"{type(dsl_kind).__name__}"
        )
    prefix = str(dsl_kind)

    try:
        prefix_libs = get_str_env_var(f"{prefix}_LIBS")
        if prefix_libs:
            return prefix_libs

        if dsl_kind is not CutlassFamilyDSL.CUTE:
            cute_dsl_libs = get_str_env_var(f"{CutlassFamilyDSL.CUTE}_LIBS")
            if cute_dsl_libs:
                return cute_dsl_libs

        search_starts = (__file__, Path(__file__).parent.parent.resolve())
        for search_start in search_starts:
            dsl_libs = _get_libs_cand(search_start)
            if dsl_libs:
                return dsl_libs
        return None
    except Exception as error:
        log().info("default_env: exception on get_prefix_dsl_libs: %s", error)
        return None


def find_cute_dsl_runtime_library() -> str | None:
    """Find the CuTe DSL runtime selected by environment configuration."""
    cute_dsl_libs = get_prefix_dsl_libs()
    if cute_dsl_libs is not None:
        for library_path in cute_dsl_libs.split(os.pathsep):
            if Path(library_path).name == _CUTE_DSL_RUNTIME_LIBRARY_NAME:
                return library_path
    return None


class CuTeDSLEnvironmentManager(EnvironmentVarManager):
    """Manage environment options shared by the CuTe DSL implementations.

    ``dsl_kind`` selects a known CuTe-family namespace; callers cannot provide
    an arbitrary environment-variable prefix.

    Options:
    - [DSL_NAME]_MANGLE_SCALAR_BY_TYPE: Mangle bare Python scalars bound to
      runtime Numeric-annotated JIT parameters by type instead of by value
      (default: False).
    - CUTE_DSL_USE_EXTENSION_COMPILER: Use extension compilation by default
      for programs without an explicit per-compile opt-out (default: True).
    """

    mangle_scalar_by_type: bool = env_var(
        "MANGLE_SCALAR_BY_TYPE", affects_compile=True, default=False
    )
    use_extension_compiler: bool = env_var(
        "USE_EXTENSION_COMPILER", affects_compile=True, default=True
    )

    def __init__(self, dsl_kind: CutlassFamilyDSL) -> None:
        if not isinstance(dsl_kind, CutlassFamilyDSL):
            raise TypeError(
                "dsl_kind must be a CutlassFamilyDSL enum value, got "
                f"{type(dsl_kind).__name__}"
            )
        self.dsl_kind = dsl_kind
        prefix = str(dsl_kind)

        super().__init__(prefix)

        self.shared_libs = get_prefix_dsl_libs(dsl_kind)

    @property
    def missing_shared_libs_message(self) -> str:
        """Explain CuTe runtime discovery and its explicit override."""
        return (
            f"{self.prefix}_LIBS environment variable is not set and "
            "CuTe-family auto-discovery failed. Set "
            f"{self.prefix}_LIBS to the path of libcute_dsl_runtime.so "
            "(e.g. <build_dir>/lib/libcute_dsl_runtime.so)."
        )
