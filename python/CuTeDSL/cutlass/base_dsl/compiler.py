# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
This module provides a class that compiles generated IR using MLIR's PassManager
and executes it using MLIR's ExecutionEngine.

"""

from typing import Sequence, Optional, Tuple, Callable
import os
import sys
import inspect
from .common import DSLRuntimeError, CudaDriverDependencyError
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
        nvvm_error: Optional[str] = None,
        ir_context: Optional[str] = None,
        cuda_toolkit: Optional[str] = None,
        arch: Optional[str] = None,
    ):
        self.nvvm_error = nvvm_error
        self.ir_context = ir_context
        self.cuda_toolkit = cuda_toolkit
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
{self.BOLD}- CUDA Toolkit Path: {self.cuda_toolkit or "Not Set"}
- Target Architecture: {self.arch}{self.RESET}

IR Context (truncated):
{self.ir_context}

{self.YELLOW}💡 Possible Solutions:{self.RESET}
{self.GREEN}1. Check if CUDA_TOOLKIT_PATH is set correctly
2. Verify target architecture ({self.arch}) is supported by your CUDA toolkit
3. Make sure CUDA toolkit version matches the target architecture requirements{self.RESET}"""


class Compiler:
    """Compiler class for compiling and building MLIR modules."""

    def __init__(self, passmanager, execution_engine):
        self.passmanager = passmanager
        self.execution_engine = execution_engine
        # Flag to track if CUDA dependencies have been checked once in this process
        self._cuda_dependencies_checked = False
        # Post-compile hook to run on Module
        self._post_compile_hook: Optional[Callable[[ir.Module], None]] = None

    def _process_error(self, error_msg: str) -> Tuple[Optional[str], Optional[str]]:
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
        module,
        pipeline: str,
        cuda_toolkit: str = "",
        arch: str = "",
        enable_verifier=False,
    ):
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
                    cuda_toolkit=cuda_toolkit,
                    arch=arch,
                ) from e
            raise e

        if self._post_compile_hook:
            self._post_compile_hook(module)

    def jit(self, module, opt_level: int = 2, shared_libs: Sequence[str] = ()):
        """Wraps the module in a JIT execution engine."""
        # Check CUDA driver and GPU dependencies before JIT execution (once per process)
        self._check_cuda_dependencies_once(shared_libs)
        # If pre-checks passed, attempt to create ExecutionEngine
        # Any failures at this point are likely non-CUDA related
        return self.execution_engine.ExecutionEngine(
            module, opt_level=opt_level, shared_libs=shared_libs
        )

    def compile_and_jit(
        self,
        module,
        pipeline: str,
        shared_libs: Sequence[str] = (),
        opt_level: int = 2,
        cuda_toolkit: str = "",
        arch: str = "",
    ):
        """Compiles and jits the module."""
        self.compile(
            module,
            pipeline,
            cuda_toolkit,
            arch,
        )

        return self.jit(module, opt_level, shared_libs)

    def _check_cuda_dependencies_once(self, shared_libs: Sequence[str]) -> None:
        """
        Check CUDA dependencies only once per process lifecycle.
        After the first check (success or failure), skip all subsequent checks
        as the runtime environment doesn't change during process execution.
        """
        if self._cuda_dependencies_checked:
            return  # Already checked in this process, skip

        # Mark as checked to skip all future validations
        self._cuda_dependencies_checked = True

        # Simple CUDA driver check - just call cuInit(0)
        try:
            import cuda.bindings.driver as cuda

            cuda.cuInit(0)
        except Exception as e:
            # Create a comprehensive error message for CUDA driver issues
            error_message = (
                "CUDA runtime initialization failed during dependency check."
            )

            raise CudaDriverDependencyError(
                message=error_message,
            )


class PostCompileHookContext:
    """Context manager for post-compile hook for a compiler."""

    def __init__(self, compiler: Compiler, hook: Callable[[ir.Module], None]):
        self.compiler = compiler
        self.hook = hook
        self.prev_post_compile_hook = None

    def __enter__(self):
        self.prev_post_compile_hook = self.compiler._post_compile_hook
        self.compiler._post_compile_hook = self.hook
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.compiler._post_compile_hook = self.prev_post_compile_hook


class CompileOption:
    """
    Base class for compile options.
    """

    option_name = ""  # name of the compile option in the pipeline

    def __init__(self, val):
        self._value = val

    def serialize(self):
        return f"{self.__class__.option_name}={self._value}"

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        self._value = value


class BooleanCompileOption(CompileOption):
    def __init__(self, val: bool = True):
        super().__init__(val)

    def serialize(self):
        return f"{self.__class__.option_name}={'true' if self._value else 'false'}"


class StringCompileOption(CompileOption):
    def serialize(self):
        if self._value:
            self._value = self._value.strip("'")
            return f"{self.__class__.option_name}='{self._value}'"
        return ""


class BooleanBasedFileDumpOption(CompileOption):
    def __init__(self, val: bool = True):
        super().__init__(val)
        self._dump_path = ""

    @property
    def dump_path(self):
        return self._dump_path

    @dump_path.setter
    def dump_path(self, path):
        self._dump_path = path

    def serialize(self):
        if self._value:
            assert self._dump_path, (
                f"Dump path is not set for {self.__class__.__name__}"
            )
            return f"{self.__class__.option_name}='{self._dump_path}'"
        return ""


class EmptyCompileOption(CompileOption):
    def serialize(self):
        return ""


class OptLevel(CompileOption):
    option_name = "opt-level"

    def __init__(self, val: int):
        if val < 0 or val > 3:
            raise DSLRuntimeError(f"Invalid OPT_LEVEL: {val}, valid range is [0, 3]")
        super().__init__(val)



class PtxasOptions(StringCompileOption):
    option_name = "ptx-options"


class EnableAssertions(BooleanCompileOption):
    option_name = "enable-assertions"


class GenerateLineInfo(BooleanCompileOption):
    option_name = "preserve-line-info"


class KeepCUBIN(BooleanBasedFileDumpOption):
    option_name = "dump-cubin-path"


class KeepPTX(BooleanBasedFileDumpOption):
    option_name = "dump-ptx-path"


class LinkLibraries(StringCompileOption):
    option_name = "link-libraries"


class GPUArch(StringCompileOption):
    option_name = "cubin-chip"

    def __init__(self, val):
        if isinstance(val, str) and val.startswith("sm_110"):
            val = val.replace("sm_110", "sm_101")
        super().__init__(val)

    @property
    def value(self) -> bool:
        return self._value

    @value.setter
    def value(self, value: bool):
        if isinstance(value, str) and value.startswith("sm_110"):
            value = value.replace("sm_110", "sm_101")
        self._value = value


class EnableTVMFFI(EmptyCompileOption):
    pass


class DumpDir(EmptyCompileOption):
    option_name = "dump-dir"


class CompileOptions:
    """
    This class encapsulates compilation options to configure the JIT compilation.
    It provides a convenient way to manage and pass compilation options.
    By centralizing these options, it ensures consistent and flexible configuration of
    compilation parameters such as optimization level, debugging control, etc.
    """

    def __init__(self, options=None):
        self.options = {
            # Compilation control options
            OptLevel: OptLevel(3),
            PtxasOptions: PtxasOptions(""),
            # Debugging options
            EnableAssertions: EnableAssertions(False),
            GenerateLineInfo: GenerateLineInfo(False),
            KeepCUBIN: KeepCUBIN(False),
            KeepPTX: KeepPTX(False),
            GPUArch: GPUArch(""),
            LinkLibraries: LinkLibraries(""),
            EnableTVMFFI: EnableTVMFFI(False),
            DumpDir: DumpDir(""),
        }

        if options is not None:
            self._update(options)

    def _update(self, options):
        def _validate_and_update_option(option):
            if type(option) not in self.options:
                raise DSLRuntimeError(f"Invalid compile option: {option}")
            self.options[type(option)] = option

        if isinstance(options, tuple):
            for option in options:
                _validate_and_update_option(option)
        else:
            _validate_and_update_option(options)

    def apply_envar_settings(self, envar: EnvironmentVarManager, function_name: str):
        # Honor the settings from environment variables as well
        if envar.keep_ptx:
            self.options[KeepPTX].value = True
        if envar.keep_cubin:
            self.options[KeepCUBIN].value = True
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
        if self.options[KeepPTX].value:
            self.options[KeepPTX].dump_path = os.path.join(
                dump_dir, f"{function_name}"
            )
            self.options[KeepPTX].full_ptx_path = os.path.join(
                dump_dir, f"{function_name}.{arch}.ptx"
            )
        if self.options[KeepCUBIN].value:
            self.options[KeepCUBIN].dump_path = os.path.join(
                dump_dir, f"{function_name}"
            )
            self.options[KeepCUBIN].full_cubin_path = os.path.join(
                dump_dir, f"{function_name}.{arch}.cubin"
            )

    @property
    def generate_line_info(self) -> bool:
        return self.options[GenerateLineInfo].value

    @property
    def gpu_arch(self) -> str:
        return self.options[GPUArch].value

    @property
    def dump_ptx_path(self) -> str | None:
        return self.options[KeepPTX].dump_path if self.options[KeepPTX].value else None

    @property
    def full_ptx_path(self) -> str | None:
        return (
            self.options[KeepPTX].full_ptx_path if self.options[KeepPTX].value else None
        )

    @property
    def dump_cubin_path(self) -> str | None:
        return (
            self.options[KeepCUBIN].dump_path if self.options[KeepCUBIN].value else None
        )

    @property
    def full_cubin_path(self) -> str | None:
        return (
            self.options[KeepCUBIN].full_cubin_path
            if self.options[KeepCUBIN].value
            else None
        )

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


def _parse_compile_options_from_str(options: str) -> CompileOptions:
    """
    Parse the compile options from a string.
    """

    def _get_compile_option_from_str(option_str: str):
        mapping = {
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
        }
        return mapping[option_str]

    import argparse
    import shlex

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
    compile_options = CompileOptions()
    try:
        # Use shlex to properly handle options with spaces
        parsed_options = shlex.split(options) if options else []
        # Avoid parsing the ptxas-options value as a hyphen key
        for i in range(1, len(parsed_options)):
            if parsed_options[i - 1] in ["--ptxas-options"]:
                parsed_options[i] = f"'{parsed_options[i]}'"
        option_dict = vars(parser.parse_args(parsed_options))
        for option, value in option_dict.items():
            option = _get_compile_option_from_str(option)
            compile_options.options[option].value = value
    except SystemExit as e:
        # catch argparse error and raise as DSLRuntimeError
        raise DSLRuntimeError(
            f"Invalid compile options: '{options}'. Please check the option values and format."
        ) from e

    return compile_options


class CompileCallable:
    def __init__(self, options=None):
        def preprocess_options(option):
            if type(option) is type and issubclass(
                option, (BooleanCompileOption, BooleanBasedFileDumpOption, EnableTVMFFI)
            ):
                # Automatically creates a True instance of the option
                return option(True)
            elif isinstance(option, tuple):
                return tuple(preprocess_options(opt) for opt in option)
            return option

        self._compile_options = CompileOptions(preprocess_options(options))

    def __getitem__(self, options):
        """
        Get a new CompileCallable object with the specified options.
        """
        new_callable_with_options = CompileCallable(options)
        return new_callable_with_options

    def __call__(self, *args, **kwargs):
        return self._compile(*args, **kwargs)

    def _compile(self, func, *args, **kwargs):
        """
        This function is used to compile a `cute.jit` decorated function.
        It will process the compile options and input parameters, do explicit compilation and return  the jit executor.

        :param func: The function to compile. It can be a regular function, a method or a class instance.
        :param args: The arguments to pass to the function.
        :param kwargs: The keyword arguments to pass to the function. It can contain `options` like
        `opt_level` to control the compilation flags.

        :return: The jit executor.

        :raises: DSLRuntimeError if the function is not decorated with `cute.jit` or is not callable.
        """
        if func is None:
            raise DSLRuntimeError("Function is not set or invalid.")

        if not callable(func):
            raise DSLRuntimeError("Object is not callable.")

        kwargs["compile_only"] = True
        kwargs["no_cache"] = True

        if inspect.isfunction(func):
            # regular function
            pass
        elif inspect.ismethod(func):
            # if it's a method, add the instance to the first argument
            args = [func.__self__] + list(args)
            func = func.__func__
        elif (
            inspect.isclass(type(func))
            and hasattr(func, "__call__")
            and hasattr(func.__call__, "__func__")
        ):
            # If it's a class instance, get the class's __call__ method
            args = [func] + list(args)
            # Get the actual function from the class definition
            func = func.__call__.__func__
        else:
            raise DSLRuntimeError(
                "Invalid function type, only function, method and module are supported, but got",
                func,
            )

        # If it's a wrapped function created by jit decorator, get the original function
        if hasattr(func, "__wrapped__"):
            func = func.__wrapped__

        # Lazy initialization of DSL object if has not been initialized
        # Use local import to avoid circular import
        from .dsl import BaseDSL

        BaseDSL._lazy_initialize_dsl(func)

        if not hasattr(func, "_dsl_object"):
            raise DSLRuntimeError("Function is not decorated with jit decorator.")

        # process compile options, extract the options and remove them from the kwargs
        options = kwargs.pop("options", None)
        if isinstance(options, str) and len(options) == 0:
            options = None

        if options is not None and isinstance(options, str):
            compile_options = _parse_compile_options_from_str(options)
        else:
            compile_options = self._compile_options
        func._dsl_object.compile_options = compile_options
        fcn_ptr = func._dsl_object._preprocess_and_execute(func)

        if hasattr(func, "_decorator_frame"):
            kwargs["_decorator_frame"] = func._decorator_frame
        result = func._dsl_object._func(fcn_ptr, *args, **kwargs)
        # Drop the decorator frame to avoid holding onto the caller's locals
        # (e.g., tensors) longer than necessary once compilation is done.
        if hasattr(func, "_decorator_frame"):
            func._decorator_frame = None
        return result
