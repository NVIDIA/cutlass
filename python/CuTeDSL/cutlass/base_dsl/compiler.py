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
This module provides a class that compiles generated IR using MLIR's PassManager
and executes it using MLIR's ExecutionEngine.

"""

from typing import Any
import collections.abc
import os
import re
import sys
import inspect
import types
from .common import DSLRuntimeError
from .utils.logger import log
from .env_manager import EnvironmentVarManager

_SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))
sys.path.append(_SCRIPT_PATH)

from .._mlir import ir


# =============================================================================
# Compiler Class
# =============================================================================


class CompilationError(RuntimeError):
    """Custom error class for compilation failures"""

    # Add ANSI color codes
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    BOLD = "\033[1m"
    RESET = "\033[0m"

    def __init__(
        self,
        message: str,
        nvvm_error: str | None = None,
        ir_context: str | None = None,
        arch: str | None = None,
    ) -> None:
        self.nvvm_error = nvvm_error
        self.ir_context = ir_context
        self.arch = arch
        # Call parent with formatted error to avoid showing class name
        super().__init__("")  # Empty string to avoid class name

        # Store formatted error for str() representation
        self._formatted_error = self._format_error()

    def __str__(self) -> str:
        """Override string representation to avoid showing class name"""
        return self._formatted_error

    def __repr__(self) -> str:
        """Override repr representation to avoid showing class name"""
        return self._formatted_error

    def _format_error(self) -> str:
        if not self.nvvm_error:
            return str(self.args[0])

        return f"""NVVM Compilation Error:
----------------------

{self.BLUE}⚙️  Current Settings:{self.RESET}
{self.BOLD}- Target Architecture: {self.arch}{self.RESET}

IR Context (truncated):
{self.ir_context}

{self.YELLOW}💡 Possible Solutions:{self.RESET}
{self.GREEN}1. Check if CUDA_TOOLKIT_PATH is set correctly
2. Verify target architecture ({self.arch}) is supported by your CUDA toolkit
3. Make sure CUDA toolkit version matches the target architecture requirements{self.RESET}"""


class Compiler:
    """Compiler class for compiling and building MLIR modules."""

    def __init__(self, passmanager: Any, execution_engine: Any) -> None:
        self.passmanager = passmanager
        self.execution_engine = execution_engine
        self._post_compile_hook: collections.abc.Callable[[Any], None] | None = None

    def _process_error(self, error_msg: str) -> tuple[str | None, str | None]:
        """Process error message to extract NVVM error and IR context"""
        nvvm_error = None
        ir_msg = ""

        if "NVVM_ERROR" in error_msg:
            # Extract the specific NVVM error
            nvvm_error = (
                error_msg.split("libNVVM extra log:")[1].strip()
                if "libNVVM extra log:" in error_msg
                else error_msg
            )

            # Extract IR context
            if "see current operation:" in error_msg:
                # Get the IR section
                ir_section = error_msg.split("see current operation:")[1].strip()
                # Remove duplicate IR section
                ir_section = ir_section.split("error: unknown: Failed translating")[
                    0
                ].strip()

                # Get first few lines and last few lines of the IR
                ir_lines = ir_section.split("\n")
                if len(ir_lines) > 10:
                    ir_msg = "\n".join(ir_lines[:5] + ["  ..."] + ir_lines[-5:])
                else:
                    ir_msg = ir_section

        return nvvm_error, ir_msg

    def compile(
        self,
        module: ir.Module,
        pipeline: str,
        arch: str = "",
        enable_debug_info: bool = False,
        enable_verifier: bool = False,
    ) -> None:
        """Compiles the module by invoking the pipeline."""
        try:
            pm = self.passmanager.PassManager.parse(pipeline)
            pm.enable_verifier(enable_verifier)

            pm.run(module.operation)
        except Exception as e:
            error_msg = str(e)
            nvvm_error, ir_msg = self._process_error(error_msg)

            if nvvm_error:
                raise CompilationError(
                    error_msg,
                    nvvm_error=nvvm_error,
                    ir_context=ir_msg,
                    arch=arch,
                ) from e
            raise e
        finally:
            pass

        if self._post_compile_hook:
            self._post_compile_hook(module)

    def jit(
        self,
        module: ir.Module,
        opt_level: int = 2,
        shared_libs: collections.abc.Sequence[str] = (),
    ) -> Any:
        """Wraps the module in a JIT execution engine."""
        return self.execution_engine.ExecutionEngine(
            module, opt_level=opt_level, shared_libs=shared_libs
        )

    def compile_and_jit(
        self,
        module: ir.Module,
        pipeline: str,
        shared_libs: collections.abc.Sequence[str] = (),
        opt_level: int = 2,
        arch: str = "",
        enable_debug_info: bool = False,
        enable_verifier: bool = False,
    ) -> Any:
        """Compiles and jits the module."""
        self.compile(
            module,
            pipeline,
            arch,
            enable_debug_info=enable_debug_info,
            enable_verifier=enable_verifier,
        )

        return self.jit(module, opt_level, shared_libs)


class PostCompileHookContext:
    """Context manager for post-compile hook for a compiler."""

    def __init__(
        self,
        compiler: Compiler,
        hook: collections.abc.Callable[[Any], None],
    ) -> None:
        self.compiler = compiler
        self.hook = hook
        self.prev_post_compile_hook: collections.abc.Callable[[Any], None] | None = None

    def __enter__(self) -> "PostCompileHookContext":
        self.prev_post_compile_hook = self.compiler._post_compile_hook
        self.compiler._post_compile_hook = self.hook
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> None:
        self.compiler._post_compile_hook = self.prev_post_compile_hook


class CompileOption:
    """
    Base class for compile options.
    """

    option_name: str = ""

    def __init__(self, val: Any) -> None:
        self._value: Any = val

    def serialize(self) -> str:
        return f"{self.__class__.option_name}={self._value}"

    @property
    def value(self) -> Any:
        return self._value

    @value.setter
    def value(self, value: Any) -> None:
        self._value = value


class BooleanCompileOption(CompileOption):
    def __init__(self, val: bool = True) -> None:
        super().__init__(val)

    def serialize(self) -> str:
        return f"{self.__class__.option_name}={'true' if self._value else 'false'}"


class StringCompileOption(CompileOption):
    def serialize(self) -> str:
        if self._value:
            self._value = self._value.strip("'")
            return f"{self.__class__.option_name}='{self._value}'"
        return ""


class BooleanBasedFileDumpOption(CompileOption):
    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self._dump_path: str = ""

    @property
    def dump_path(self) -> str:
        return self._dump_path

    @dump_path.setter
    def dump_path(self, path: str) -> None:
        self._dump_path = path

    def serialize(self) -> str:
        if self._value:
            assert self._dump_path, (
                f"Dump path is not set for {self.__class__.__name__}"
            )
            return f"{self.__class__.option_name}='{self._dump_path}'"
        return ""


class EmptyCompileOption(CompileOption):
    def serialize(self) -> str:
        return ""


class OptLevel(CompileOption):
    option_name = "opt-level"

    def __init__(self, val: int) -> None:
        if val < 0 or val > 3:
            raise DSLRuntimeError(f"Invalid OPT_LEVEL: {val}, valid range is [0, 3]")
        super().__init__(val)



_NVVM_DIAG_SUB_ALIASES: dict[str, str] = {
}

_SR_DISABLE_PATTERNS: dict[str, str] = {
}


_PERF_ENABLE_OPTIONS: dict[str, str] = {
}


class ExtraCompilerOpts(CompileOption):
    """Raw MLIR pass options from CUTE_DSL_COMPILER_OPT, serialized verbatim."""

    def __init__(self, val: str = "") -> None:
        super().__init__(val)

    def serialize(self) -> str:
        return self._value


class PtxasOptions(StringCompileOption):
    option_name = "ptx-options"


class RDC(BooleanCompileOption):
    """Compile as relocatable device code (``ptxas -c``).

    Enabled automatically by ``DeviceTarget``.  In the future, can be
    used directly with kernel compilation to produce linkable objects.
    """

    option_name = "rdc"


class EnableAssertions(BooleanCompileOption):
    option_name = "enable-assertions"


class GenerateLineInfo(BooleanCompileOption):
    option_name = "preserve-line-info"


class KeepCUBIN(BooleanBasedFileDumpOption):
    option_name = "dump-cubin-path"

    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self.full_cubin_path: str = ""


class KeepPTX(BooleanBasedFileDumpOption):
    option_name = "dump-ptx-path"

    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self.full_ptx_path: str = ""




class FlattenLocsOutputJsonPath(StringCompileOption):
    """Path to the FlattenLocs JSON sidecar (vloc id -> original source chain).

    When set, the `flatten-locs` pass runs and writes the sidecar. Empty (the
    default) makes the pass a no-op — the original loc chain passes through
    to the LLVM backend unchanged.
    """

    option_name = "flatten-locs-output-json-path"


class LinkLibraries(StringCompileOption):
    option_name = "link-libraries"


class GPUArch(StringCompileOption):
    option_name = "cubin-chip"

    def __init__(self, val: str) -> None:
        if val == "":
            super().__init__(val)
        else:
            # Avoid circular dependency
            from .arch import Arch

            super().__init__(Arch.from_string(val).to_string())

    @property
    def value(self) -> str:
        return self._value

    @value.setter
    def value(self, value: str) -> None:
        if value == "":
            self._value = value
        else:
            # Avoid circular dependency
            from .arch import Arch

            self._value = Arch.from_string(value).to_string()


class EnableTVMFFI(EmptyCompileOption):
    pass


class DeviceTarget(BooleanCompileOption):
    """Compile a ``@cute.jit`` function as a ``device`` function.

    By default ``cute.compile`` compiles host and gpu kernel.
    Usage::

        cute.compile[DeviceTarget](my_func, Float32, Float32)
    """

    option_name = ""

    def serialize(self) -> str:
        return ""


class DumpDir(EmptyCompileOption):
    option_name = "dump-dir"


# AOT host cross-compile target presets. Tag → (triple, cpu, features).
# Keep this small. Power users go through the long form below.
_HOST_TARGET_PRESETS: dict[str, tuple[str, str, str]] = {
    "linux-aarch64": ("aarch64-unknown-linux-gnu", "", ""),
}


def _parse_host_target(spec: str) -> tuple[str, str, str]:
    """Parse a ``--host-target`` value into ``(triple, cpu, features)``.

    Accepts:
      * Empty string → all empty (native build-host behavior).
      * Preset tag in ``_HOST_TARGET_PRESETS``.
      * TVM-style long form ``llvm -mtriple=<t> [-mcpu=<c>] [-mattr=<f>]``.
    """
    spec = (spec or "").strip()
    if not spec:
        return "", "", ""
    if spec.startswith("llvm"):
        import shlex as _shlex

        tokens = _shlex.split(spec)
        if not tokens or tokens[0] != "llvm":
            raise ValueError(f"invalid host-target long form: {spec!r}")
        triple, cpu, features = "", "", ""
        for tok in tokens[1:]:
            if tok.startswith("-mtriple="):
                triple = tok[len("-mtriple=") :]
            elif tok.startswith("-mcpu="):
                cpu = tok[len("-mcpu=") :]
            elif tok.startswith("-mattr="):
                features = tok[len("-mattr=") :]
            else:
                raise ValueError(
                    f"unknown host-target flag {tok!r}; "
                    "supported: -mtriple=, -mcpu=, -mattr="
                )
        if not triple:
            raise ValueError(
                f"host-target long form requires -mtriple=<triple>; got: {spec!r}"
            )
        return triple, cpu, features
    if spec in _HOST_TARGET_PRESETS:
        return _HOST_TARGET_PRESETS[spec]
    raise ValueError(
        f"--host-target {spec!r}: not a known preset and does not start "
        f"with 'llvm '. Known presets: {sorted(_HOST_TARGET_PRESETS)}. "
        f"Long form: 'llvm -mtriple=<triple> [-mcpu=<cpu>] [-mattr=<features>]'."
    )


class HostTarget(EmptyCompileOption):
    """Target spec for AOT host cross-compile.

    Empty value (default) targets the build host via the native
    auto-detect path. A non-empty value cross-compiles the AOT host
    object for the requested target; cross-compile is currently
    exercised for AArch64 only, and other ISAs hit a "target not
    registered" error at codegen time.

    Accepts either a registered preset tag or a TVM-style long form
    (consumed by the AOT export path; not part of the MLIR pipeline
    string).

    Presets::

        linux-aarch64   → aarch64-unknown-linux-gnu

    Long form (explicit tuning / escape hatch)::

        llvm -mtriple=<triple> [-mcpu=<cpu>] [-mattr=<features>]

    Examples::

        cute.compile(fn, *args,
                     options="--gpu-arch sm_100a --host-target linux-aarch64")
        cute.compile(fn, *args,
                     options=(
                         "--gpu-arch sm_100a "
                         "--host-target 'llvm -mtriple=aarch64-unknown-linux-gnu "
                         "-mcpu=neoverse-n1 -mattr=+lse'"
                     ))
    """

    option_name = "host-target"

    def __init__(self, val: str = "") -> None:
        # Parse + validate eagerly so bad input fails at cute.compile()
        # parse time rather than later at AOT export time. The parsed
        # triple/cpu/features are cached and exposed as attributes; the
        # raw spec is the option's ``value``.
        self._parse_and_cache(val)
        super().__init__(val)

    def _parse_and_cache(self, val: str) -> None:
        try:
            self._triple, self._cpu, self._features = _parse_host_target(val)
        except ValueError as exc:
            raise DSLRuntimeError(str(exc)) from exc

    @property
    def value(self) -> str:
        return self._value

    @value.setter
    def value(self, new_value: str) -> None:
        self._parse_and_cache(new_value)
        self._value = new_value

    @property
    def triple(self) -> str:
        """LLVM target triple. Empty = native build host."""
        return self._triple

    @property
    def cpu(self) -> str:
        """LLVM CPU name. Empty = generic baseline for the triple."""
        return self._cpu

    @property
    def features(self) -> str:
        """Comma-separated LLVM feature list."""
        return self._features



class CompileOptions:
    """
    This class encapsulates compilation options to configure the JIT compilation.
    It provides a convenient way to manage and pass compilation options.
    By centralizing these options, it ensures consistent and flexible configuration of
    compilation parameters such as optimization level, debugging control, etc.
    """

    def __init__(
        self, options: "CompileOption | tuple[CompileOption, ...] | None" = None
    ) -> None:
        self.options: dict[type[CompileOption], CompileOption] = {
            # Compilation control options
            OptLevel: OptLevel(3),
            ExtraCompilerOpts: ExtraCompilerOpts(""),
            PtxasOptions: PtxasOptions(""),
            RDC: RDC(False),
            # Debugging options
            EnableAssertions: EnableAssertions(False),
            GenerateLineInfo: GenerateLineInfo(False),
            KeepCUBIN: KeepCUBIN(False),
            KeepPTX: KeepPTX(False),
            GPUArch: GPUArch(""),
            FlattenLocsOutputJsonPath: FlattenLocsOutputJsonPath(""),
            LinkLibraries: LinkLibraries(""),
            EnableTVMFFI: EnableTVMFFI(False),
            DeviceTarget: DeviceTarget(False),
            DumpDir: DumpDir(""),
            HostTarget: HostTarget(""),
        }

        if options is not None:
            self._update(options)

    def _update(self, options: "CompileOption | tuple[CompileOption, ...]") -> None:
        def _validate_and_update_option(option: CompileOption) -> None:
            if type(option) not in self.options:
                raise DSLRuntimeError(f"Invalid compile option: {option}")
            self.options[type(option)] = option

        if isinstance(options, tuple):
            for option in options:
                _validate_and_update_option(option)
        else:
            _validate_and_update_option(options)

    def _apply_opt_string(self, opt_str: str) -> None:
        """Apply a compact compiler option string in-place.

        Parses the same format as ``CUTE_DSL_COMPILER_OPT`` and updates this
        object's options accordingly.  Valid forms (comma- or space-separated,
        ``--`` prefix optional)::

            --iket                           # enable IKET (In-Kernel Event Tracing) instrumentation

        :param opt_str: Compact option string to parse.
        :raises ValueError: On malformed syntax:

            - **Unclosed brace** — a ``{`` immediately after a token that was
              not captured by the regex (e.g. ``name{``).
            - **Empty braces** — ``name{}`` is rejected unless *name* is a
              documented exception (currently ``strength-reduction``).
            - **Empty value** — ``name=`` (equals with no value) is rejected;
              use the bare name to enable boolean options.
        """
        import re

        # Alias map: short token → MLIR option name
        _ALIAS_MAP: dict[str, str] = {
        }

        # Tokens that map directly to a single boolean pipeline flag.
        _ENABLE_OPTIONS: dict[str, str] = {
            "iket": "enable-iket",
        }

        opt_name_map = {cls.option_name: cls for cls in self.options if cls.option_name}
        raw_opts: list[str] = []

        # Tokenize: each token is  name  or  name{sub-opts}  or  name=val
        for m in re.finditer(r"([\w][\w-]*)(?:\{([^}]*)\}|=([\S]+))?", opt_str):
            name = m.group(1)
            sub_str = m.group(2)  # braces content, or None
            val_str = m.group(3)  # =val content, or None

            # --- Malformed-syntax checks ---
            # (1) Unclosed brace: the regex skips a lone '{' that has no '}'.
            if m.end() < len(opt_str) and opt_str[m.end()] == "{":
                raise ValueError(
                    f"Unclosed '{{' after option '{name}'; "
                    f"braces must be closed (e.g. {name}{{...}})"
                )
            # (2) Empty braces: name{} is ambiguous — reject unless documented.
            if (
                sub_str is not None
                and sub_str == ""
            ):
                raise ValueError(
                    f"Empty braces for option '{name}'; "
                    f"provide sub-options (e.g. {name}{{key=val}}) "
                    f"or remove the braces"
                )
            # (3) Empty value: name= (equals with no RHS). The regex requires
            #     at least one \S after '=', so 'name=' leaves '=' uncaptured.
            if (
                val_str is None
                and sub_str is None
                and m.end() < len(opt_str)
                and opt_str[m.end()] == "="
            ):
                raise ValueError(
                    f"Empty value for option '{name}='; "
                    f"provide a value (e.g. {name}=<value>) "
                    f"or use the bare name to enable a boolean option"
                )

            if name == "nvvm-diag":
                pass
            elif name in _PERF_ENABLE_OPTIONS and sub_str is None:
                # Emit the MLIR flag for this pass enable token directly.
                raw_opts.append(f"{_PERF_ENABLE_OPTIONS[name]}=true")
            elif sub_str is not None:
                pass
            elif name in _ENABLE_OPTIONS and sub_str is None:
                # Emit the MLIR flag for this enable token directly.
                raw_opts.append(f"{_ENABLE_OPTIONS[name]}=true")
            else:
                # Form: name  or  name=val — enable/configure a named option.
                key = _ALIAS_MAP.get(name, name)
                val = val_str or ""
                if key in opt_name_map:
                    opt = self.options[opt_name_map[key]]
                    if isinstance(opt, BooleanCompileOption):
                        opt.value = (
                            True
                            if not val
                            else val.lower() in ("1", "true", "yes", "on")
                        )
                    else:
                        if not val:
                            raise DSLRuntimeError(
                                f"Option '{key}' requires a value (e.g. {key}=<value>)"
                            )
                        opt.value = val
                else:
                    raw_opts.append(f"{key}={'true' if not val else val}")

        if raw_opts:
            existing = self.options[ExtraCompilerOpts].value
            combined = (existing + " " + " ".join(raw_opts)).strip()
            self.options[ExtraCompilerOpts].value = combined

    def apply_envar_settings(
        self, envar: EnvironmentVarManager, function_name: str
    ) -> None:
        # Honor the settings from environment variables as well
        if envar.keep_ptx:
            self.options[KeepPTX].value = True
        if envar.keep_cubin:
            self.options[KeepCUBIN].value = True
        if envar.compiler_opt:
            self._apply_opt_string(envar.compiler_opt)
        if envar.enable_assertions:
            self.options[EnableAssertions].value = True
        if envar.lineinfo:
            self.options[GenerateLineInfo].value = True
        if envar.enable_tvm_ffi:
            self.options[EnableTVMFFI].value = True

        # Update the dump path if the option is set
        arch = (
            envar.arch
            if self.options[GPUArch].value == ""
            else self.options[GPUArch].value
        )
        dump_dir = (
            envar.dump_dir
            if self.options[DumpDir].value == ""
            else self.options[DumpDir].value
        )
        keep_ptx = self.options[KeepPTX]
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_ptx, KeepPTX)
        assert isinstance(keep_cubin, KeepCUBIN)
        if keep_ptx.value:
            assert dump_dir is not None
            keep_ptx.dump_path = os.path.join(dump_dir, f"{function_name}")
            keep_ptx.full_ptx_path = os.path.join(
                dump_dir,
                f"{function_name}.{arch}.ptx",
            )
        if keep_cubin.value:
            assert dump_dir is not None
            keep_cubin.dump_path = os.path.join(
                dump_dir,
                f"{function_name}",
            )
            keep_cubin.full_cubin_path = os.path.join(
                dump_dir,
                f"{function_name}.{arch}.cubin",
            )
    @property
    def generate_line_info(self) -> bool:
        return self.options[GenerateLineInfo].value

    @property
    def gpu_arch(self) -> str:
        return self.options[GPUArch].value

    @property
    def host_target(self) -> "HostTarget":
        """Host-target option object.

        ``.value`` is the raw user-facing spec (preset tag or ``llvm …``
        long form, empty = native build host). ``.triple`` / ``.cpu`` /
        ``.features`` are the parsed components.
        """
        return self.options[HostTarget]  # type: ignore[return-value]

    @property
    def dump_ptx_path(self) -> str | None:
        keep_ptx = self.options[KeepPTX]
        assert isinstance(keep_ptx, KeepPTX)
        return keep_ptx.dump_path if keep_ptx.value else None

    @property
    def full_ptx_path(self) -> str | None:
        keep_ptx = self.options[KeepPTX]
        assert isinstance(keep_ptx, KeepPTX)
        return keep_ptx.full_ptx_path if keep_ptx.value else None

    @property
    def dump_cubin_path(self) -> str | None:
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_cubin, KeepCUBIN)
        return keep_cubin.dump_path if keep_cubin.value else None

    @property
    def full_cubin_path(self) -> str | None:
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_cubin, KeepCUBIN)
        return keep_cubin.full_cubin_path if keep_cubin.value else None

    @property
    def enable_tvm_ffi(self) -> bool:
        ret = self.options[EnableTVMFFI].value
        if ret:
            try:
                import tvm_ffi
            except ModuleNotFoundError:
                raise DSLRuntimeError(
                    "TVM FFI is not installed, please install it via `pip install apache-tvm-ffi`"
                )
        return ret

    def to_str(self) -> str:
        """
        Generate a string representation of all compilation options
        which will be used in pipeline options.
        """
        flattend_options = ""
        for option in self.options.values():
            flattend_options += option.serialize() + " "

        log().info("`cute.compile` CompileOptions: options=" + flattend_options)
        return flattend_options


def _extract_compact_options(
    options: str,
) -> "tuple[CompileOptions | None, str]":
    """Split *options* into compact tokens and legacy tokens.

    Returns:
        (base_compile_options or None, remaining legacy options string).
        When the input is *pure* compact, the fully-configured CompileOptions
        is returned and the legacy string is empty.
    """
    import shlex

    _COMPACT_NAMES: frozenset[str] = frozenset(
        {
            "iket",
        }
        | set(_PERF_ENABLE_OPTIONS)
    )

    def _is_compact(token: str) -> bool:
        bare = (
            (token[2:] if token.startswith("--") else token).split(",")[0].split("{")[0]
        )
        return bare in _COMPACT_NAMES

    stripped = options.strip() if options else ""
    if not stripped:
        return None, options

    try:
        all_tokens = shlex.split(stripped)
    except ValueError as exc:
        raise ValueError(
            f"Failed to parse compiler options string: {exc}\n"
            f"  options string: {stripped!r}\n"
            "  Hint: unmatched quotes or backslashes are common causes."
        ) from exc

    _LEGACY_VALUE_KEYS: frozenset[str] = frozenset(
        {
            "--ptxas-options",
            "--link-libraries",
            "--gpu-arch",
            "--dump-dir",
            "--opt-level",
            "--host-target",
        }
    )
    compact_tokens: list[str] = []
    legacy_tokens: list[str] = []
    _prev_is_legacy_key = False
    for t in all_tokens:
        if _prev_is_legacy_key:
            legacy_tokens.append(t)
            _prev_is_legacy_key = False
        elif _is_compact(t):
            compact_tokens.append(t)
        else:
            legacy_tokens.append(t)
            _prev_is_legacy_key = t in _LEGACY_VALUE_KEYS

    if not compact_tokens:
        return None, options

    compact_str = " ".join(t[2:] if t.startswith("--") else t for t in compact_tokens)
    if not legacy_tokens:
        compile_options = CompileOptions()
        compile_options._apply_opt_string(compact_str)
        return compile_options, ""

    base = CompileOptions()
    base._apply_opt_string(compact_str)
    return base, " ".join(legacy_tokens)


# This is a temp function to preserve backward compatibility.
# To be removed in the future.
def _parse_compile_options_from_str(options: str) -> CompileOptions:
    """Parse the compile options from a string."""
    import shlex as _shlex

    _base_compile_options: "CompileOptions | None" = None
    _base_compile_options, options = _extract_compact_options(options)
    if isinstance(_base_compile_options, CompileOptions) and not options:
        return _base_compile_options

    def _get_compile_option_from_str(option_str: str) -> type[CompileOption]:
        mapping: dict[str, type[CompileOption]] = {
            "opt_level": OptLevel,
            "ptxas_options": PtxasOptions,
            "enable_assertions": EnableAssertions,
            "link_libraries": LinkLibraries,
            "generate_line_info": GenerateLineInfo,
            "keep_cubin": KeepCUBIN,
            "keep_ptx": KeepPTX,
            "gpu_arch": GPUArch,
            "enable_tvm_ffi": EnableTVMFFI,
            "dump_dir": DumpDir,
            "host_target": HostTarget,
        }
        return mapping[option_str]

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--opt-level", nargs="?", type=int, default=3)
    parser.add_argument("--enable-assertions", action="store_true", default=False)
    parser.add_argument("--link-libraries", type=str, default="")
    parser.add_argument("--generate-line-info", action="store_true", default=False)
    parser.add_argument("--keep-cubin", action="store_true", default=False)
    parser.add_argument("--keep-ptx", action="store_true", default=False)
    parser.add_argument("--ptxas-options", type=str, default="")
    parser.add_argument("--gpu-arch", type=str, default="")
    parser.add_argument("--enable-tvm-ffi", action="store_true", default=False)
    parser.add_argument("--dump-dir", type=str, default="")
    parser.add_argument("--host-target", type=str, default="")
    compile_options = (
        _base_compile_options if _base_compile_options is not None else CompileOptions()
    )
    try:
        # Use shlex to properly handle options with spaces
        parsed_options = _shlex.split(options) if options else []
        # Avoid parsing the ptxas-options value as a hyphen key
        for i in range(1, len(parsed_options)):
            if parsed_options[i - 1] in ["--ptxas-options"]:
                parsed_options[i] = f"'{parsed_options[i]}'"
        option_dict = vars(parser.parse_args(parsed_options))
        for option_name, value in option_dict.items():
            option_cls = _get_compile_option_from_str(option_name)
            compile_options.options[option_cls].value = value
    except SystemExit as e:
        # catch argparse error and raise as DSLRuntimeError
        raise DSLRuntimeError(
            f"Invalid compile options: '{options}'. Please check the option values and format."
        ) from e

    return compile_options


class CompileCallable:
    """Compile a ``@cute.jit`` callable into an executable host wrapper.

    The public ``cute.compile(...)`` entrypoint is an instance of this
    class. Call it with a ``@cute.jit`` function plus representative
    arguments describing the runtime signature:

    - fake tensors from
      :func:`cutlass.cute.runtime.make_fake_tensor` or
      :func:`cutlass.cute.runtime.make_fake_compact_tensor` for tensor
      arguments
    - plain scalars or :class:`cutlass.cute.typing.SymInt`-typed values
      for scalar parameters
    - :func:`cutlass.cute.runtime.make_fake_stream` when the host wrapper
      takes a stream

    The returned object is callable with real runtime arguments matching
    the fake signature used at compile time.

    Compile-time constants should be baked into the ``@cute.jit``
    function or exposed as default-valued parameters on the user's own
    ``compile()`` wrapper; runtime-varying symbolic quantities should be
    modeled with :class:`cutlass.cute.typing.SymInt` in fake tensor
    shapes / strides or host-function scalar arguments.

    ``cute.compile(..., options="...")`` accepts the same token string as
    ``CUTE_DSL_COMPILER_OPT``. Keep this docstring focused on the compile
    contract; use ``write-kernel/references/compiler-options.md`` as the
    authoritative catalog of option tokens and examples.
    """

    def __init__(self, options: Any = None) -> None:
        def preprocess_options(option: Any) -> Any:
            if type(option) is type and issubclass(
                option, (BooleanCompileOption, BooleanBasedFileDumpOption, EnableTVMFFI)
            ):
                # Automatically creates a True instance of the option
                return option(True)
            elif isinstance(option, tuple):
                return tuple(preprocess_options(opt) for opt in option)
            return option

        self._compile_options = CompileOptions(preprocess_options(options))

    def __getitem__(self, options: Any) -> "CompileCallable":
        """
        Get a new CompileCallable object with the specified options.
        """
        new_callable_with_options = CompileCallable(options)
        return new_callable_with_options

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        """Compile ``func`` for the signature described by ``args``.

        :param args: ``func`` followed by representative compile-time
            arguments. Tensor arguments are typically fake tensors;
            scalar arguments may be Python literals or SymInt-backed
            symbolic values.
        :param kwargs: Optional compile controls such as ``options=...``.
            See ``references/compiler-options.md`` for option tokens.
        :return: A compiled callable that accepts real runtime arguments
            matching the supplied signature.
        """
        return self._compile(*args, **kwargs)

    def to_precompiled_mlir(self, func: Any, *args: Any, **kwargs: Any) -> Any:
        """Return a PreCompiledMlirArtifact containing the pre-pass MLIR module."""
        kwargs["compile_to_precompiled_mlir"] = True
        return self._compile(func, *args, **kwargs)

    def compile_to(self, target: Any, func: Any, *args: Any, **kwargs: Any) -> Any:
        """Compile a @cute.jit function to the given artifact stage.

        Args:
            target: ``ArtifactType.PreCompiledMlir``.
        """
        from .._mlir._mlir_libs import _cutlass_ir

        if target != _cutlass_ir.ArtifactType.PreCompiledMlir:
            raise NotImplementedError(f"compile_to({target}) is not yet supported")
        return self.to_precompiled_mlir(func, *args, **kwargs)

    def _compile(self, func: Any, *args: Any, **kwargs: Any) -> Any:
        """
        Compile a ``@cute.jit`` function and return its executable wrapper.

        ``func`` may be a regular function, bound method, or callable
        instance, but it must ultimately resolve to a ``@cute.jit``
        definition. ``args`` describe the runtime signature seen by the
        compiled wrapper; for tensor arguments, prefer fake tensors over
        ad-hoc real tensors so shape / stride / SymInt constraints remain
        explicit and reproducible.

        ``kwargs`` may contain ``is_experimental: bool`` to assert that
        the function was decorated through the experimental DSL path
        (``@cute.jit(is_experimental=True)`` /
        ``@cute.kernel(is_experimental=True)``). This kwarg is consumed
        at the call site rather than forwarded into the executor: the
        actual DSL routing for the compile is already determined by the
        function's decorator (via ``func._dsl_object``). The kwarg
        exists as a migration aid away from
        ``cute.experimental.compile``: when set to True the call
        validates that the function is indeed routed through an
        experimental DSL (``BaseDSL._is_experimental_dsl is True``) and
        raises if not, so that mixing experimental host launchers with
        non-experimental compile entry points (or vice versa) fails
        loudly at the call site instead of producing a preprocessor
        free-vars mismatch deep inside ``_preprocess_and_replace_code``.

        :param func: The ``@cute.jit`` callable to compile.
        :param args: Representative compile-time arguments describing the
            callable's runtime signature.
        :param kwargs: Optional compile controls. ``options=...`` accepts
            the same token string as ``CUTE_DSL_COMPILER_OPT``. For the
            full option catalog, see
            ``write-kernel/references/compiler-options.md``.
        :return: A compiled callable.
        :raises DSLRuntimeError: If ``func`` is not callable or not
            decorated with ``@cute.jit``.
        """
        if func is None:
            raise DSLRuntimeError("Function is not set or invalid.")

        if not callable(func):
            raise DSLRuntimeError("Object is not callable.")

        # Pop the migration-aid kwarg before it leaks into the executor
        # call: the rest of the pipeline does not know about it.
        is_experimental_requested = kwargs.pop("is_experimental", False)

        kwargs["compile_only"] = True
        kwargs["no_cache"] = True

        if inspect.isfunction(func):
            # regular function
            pass
        elif inspect.ismethod(func):
            # if it's a method, add the instance to the first argument
            args = [func.__self__] + list(args)  # type: ignore[assignment]
            func = func.__func__
        elif (
            inspect.isclass(type(func))
            and hasattr(func, "__call__")
            and hasattr(func.__call__, "__func__")
        ):
            # If it's a class instance, get the class's __call__ method
            args = [func] + list(args)  # type: ignore[assignment]
            # Get the actual function from the class definition
            func = func.__call__.__func__
        else:
            raise DSLRuntimeError(
                "Invalid function type, only function, method and module are supported, but got",
                func,
            )

        func_name_prefix = getattr(func, "_name_prefix", None)
        if func_name_prefix:
            kwargs["_name_prefix"] = func_name_prefix

        # If it's a wrapped function created by decorators, get the original function
        while hasattr(func, "__wrapped__"):
            func = func.__wrapped__

        from .dsl import BaseDSL

        BaseDSL._lazy_initialize_dsl(func)

        if not hasattr(func, "_dsl_object"):
            raise DSLRuntimeError(
                f"Function {func} is not decorated with jit decorator."
            )

        # Validate the migration-aid ``is_experimental`` kwarg against
        # the routing already baked into the function by its jit/kernel
        # decorator. This is *not* a behavior switch: both
        # ``cute.compile`` and ``cute.experimental.compile`` are
        # functionally identical ``CompileCallable`` instances; the
        # actual experimental dispatch is driven by ``func._dsl_object``
        # (set by ``@cute.jit(is_experimental=True)``). Validating here
        # turns a silent mismatch (which would only manifest later as a
        # "code object with N free vars" preprocessor error) into a
        # clear call-site diagnostic.
        if is_experimental_requested and not getattr(
            func._dsl_object, "_is_experimental_dsl", False
        ):
            raise DSLRuntimeError(
                "cute.compile(is_experimental=True) was called on a function "
                f"routed through {type(func._dsl_object).__name__}, which is "
                "not an experimental DSL. Decorate the function with "
                "@cute.jit(is_experimental=True) (and any nested @cute.kernel "
                "with is_experimental=True) before compiling, or drop the "
                "is_experimental flag from the cute.compile call."
            )

        # process compile options, extract the options and remove them from the kwargs
        options = kwargs.pop("options", None)
        if isinstance(options, str) and len(options) == 0:
            options = None

        if options is not None and isinstance(options, str):
            compile_options = _parse_compile_options_from_str(options)
        else:
            compile_options = self._compile_options
        func._dsl_object.compile_options = compile_options

        # Preprocess the function if not already preprocessed
        func._dsl_object._preprocess_and_replace_code(func)

        # Route based on DeviceTarget option: compiles as __device__ function.
        if compile_options.options[DeviceTarget].value:
            # Device functions are always relocatable objects.
            compile_options.options[RDC].value = True
            # Force artifact dumping so .o and .ptx are available after compilation.
            compile_options.options[KeepPTX].value = True
            compile_options.options[KeepCUBIN].value = True
            return func._dsl_object._device_func(func, *args, **kwargs)

        # Default: host wrapper + kernel
        return func._dsl_object._func(func, *args, **kwargs)
