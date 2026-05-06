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
This module provides a main DSL class for any Dialect.
The DSL should be inherited as a new class, and its initialization requires dialects.
It handles most of the mechanics for the DSL in an agnostic way,
for example, it can handle various dialect-specific tasks.
"""

# Standard library imports
from dataclasses import dataclass, field
import atexit
import os
import io
import sys
import errno
import re
import inspect
import argparse
import hashlib
from functools import lru_cache, wraps
from collections import namedtuple, OrderedDict
from abc import ABC, abstractmethod
from typing import Annotated, Any, ClassVar, TYPE_CHECKING, get_args, get_origin
from collections.abc import Callable
from types import SimpleNamespace

if TYPE_CHECKING:
    import hashlib
    from .arch import Arch
import warnings
import threading

from . import typing as t
from .env_manager import EnvironmentVarManager, is_cutlass_family_dsl_prefix
from .compiler import CompileOptions, LinkLibraries
from .ast_helpers import DSLOptimizationWarning
from .common import register_env_manager

# =============================================================================
# Local module imports
# =============================================================================

from .cache_helpers import *
from .jit_executor import JitCompiledFunction, JitFunctionArtifacts
from .utils.timer import timer
from .utils.logger import log
from .utils.stacktrace import filter_exception, walk_to_top_module, filter_stackframe
from .runtime.jit_arg_adapters import (
    is_argument_constexpr,
    is_arg_annotation_constexpr,
    JitArgAdapterRegistry,
)

from .ast_preprocessor import DSLPreprocessor
from .common import *
from .typing import (
    get_c_pointers,
    get_mlir_types,
    Integer,
    implements_dynamic_expression,
    implements_jit_argument,
)
from ._mlir_helpers.op import _set_enable_frame_filtering

# =============================================================================
# MLIR modules
# =============================================================================

from .._mlir import ir
from .._mlir.dialects import func

# =============================================================================
# Global Variables
# =============================================================================

MLIR_DYNAMIC = -9223372036854775808

# =============================================================================
# Main DSL Class
# =============================================================================


def is_dynamic_expression(value: object) -> bool:
    """
    Given the `value`, check if itself is an IR value or recursively go through it to check if it contains IR value
    """
    if isinstance(value, (tuple, list)):
        for x in value:
            if is_dynamic_expression(x):
                return True
    elif isinstance(value, (ir.Value, ir.BlockArgumentList)) or hasattr(
        value, "__extract_mlir_values__"
    ):
        return True
    return False


def extract_mlir_values(obj: object, *, structured: bool = False) -> Any:
    """
    Given the `obj`, recursively go through it to extract all contained IR values.

    Args:
        obj: The object to extract MLIR values from
        structured: If False (default), returns a flat list of MLIR values.
                   If True, returns whatever __extract_mlir_values__ returns directly
                   (for tree-based debugging approach).

    Returns:
        If structured=False: list[ir.Value] - flat list of MLIR values
        If structured=True: the direct result of __extract_mlir_values__ (dict/list/ir.Value)
    """
    import dataclasses

    if structured:
        # Tree-structured mode: return __extract_mlir_values__ result directly
        if hasattr(obj, "__extract_mlir_values__"):
            return obj.__extract_mlir_values__()
        elif dataclasses.is_dataclass(obj) and not isinstance(obj, type):
            return {
                field.name: extract_mlir_values(
                    getattr(obj, field.name), structured=True
                )
                for field in dataclasses.fields(obj)
            }
        elif isinstance(obj, (tuple, list)):
            return [extract_mlir_values(x, structured=True) for x in obj]
        elif isinstance(obj, SimpleNamespace):
            return {
                k: extract_mlir_values(v, structured=True)
                for k, v in obj.__dict__.items()
            }
        elif isinstance(obj, ir.Value):
            return obj
        elif isinstance(obj, ir.BlockArgumentList):
            return list(obj)
        else:
            return None
    else:
        # Flat list mode (original behavior)
        res = []
        if hasattr(obj, "__extract_mlir_values__"):
            # Flatten whatever __extract_mlir_values__ returns to ensure we always get a flat list
            res = flatten_mlir_values(obj.__extract_mlir_values__())
        elif isinstance(obj, (tuple, list)):
            res = sum((extract_mlir_values(x) for x in obj), [])
        elif isinstance(obj, SimpleNamespace):
            res = []
            for k, v in obj.__dict__.items():
                res.extend(extract_mlir_values(v))
        elif isinstance(obj, set):
            raise DSLRuntimeError(
                "Sets are not supported in extract_mlir_values to ensure order preservation",
                context="The DSL attempted to generate JIT function argument(s) for an argument of type set but failed.",
                suggestion="Consider using a list or tuple instead",
            )
        elif isinstance(obj, ir.Value):
            res = [obj]
        elif isinstance(obj, ir.BlockArgumentList):
            res = list(obj)

        return res


def flatten_mlir_values(values: Any) -> list[ir.Value]:
    """
    Flatten a nested dict/list structure of MLIR values into a flat list.

    This is used when we need to pass values to MLIR operations that expect
    a flat list of values (e.g., function arguments, yield operands).

    Args:
        values: A nested structure (dict, list, ir.Value, or None)

    Returns:
        list[ir.Value]: A flat list of all MLIR values in depth-first order
    """
    if values is None:
        return []
    elif isinstance(values, ir.Value):
        return [values]
    elif isinstance(values, dict):
        result = []
        for v in values.values():
            result.extend(flatten_mlir_values(v))
        return result
    elif isinstance(values, list):
        result = []
        for v in values:
            result.extend(flatten_mlir_values(v))
        return result
    else:
        return []


def unflatten_mlir_values(flat_values: Any, template: Any) -> Any:
    """
    Reconstruct a nested dict/list structure from a flat list of MLIR values.

    This is the inverse of flatten_mlir_values. It uses a template structure
    to know how to rebuild the nested structure.

    Args:
        flat_values: Iterator or list of MLIR values
        template: A nested structure (dict, list, ir.Value, or None) that
                  defines the shape to reconstruct

    Returns:
        A nested structure matching the template shape, filled with values
        from flat_values
    """
    if not hasattr(flat_values, "__next__"):
        flat_values = iter(flat_values)

    if template is None:
        return None
    elif isinstance(template, ir.Value):
        return next(flat_values)
    elif isinstance(template, dict):
        return {k: unflatten_mlir_values(flat_values, v) for k, v in template.items()}
    elif isinstance(template, list):
        return [unflatten_mlir_values(flat_values, v) for v in template]
    else:
        return None


# =============================================================================
# Dynamic Debug Control
# =============================================================================


class _DynamicDebugState:
    """
    Global state for controlling dynamic loop debug output.
    """

    def __init__(self) -> None:
        self.enabled = False
        self.max_depth: int | None = None
        self.current_depth = 0

    def should_print(self) -> bool:
        if not self.enabled:
            return False
        if self.max_depth is None:
            return True
        return self.current_depth <= self.max_depth

    def enter_level(self) -> None:
        self.current_depth += 1

    def exit_level(self) -> None:
        self.current_depth = max(0, self.current_depth - 1)

    def reset_depth(self) -> None:
        self.current_depth = 0


_dynamic_debug = _DynamicDebugState()


def set_dynamic_debug(enabled: bool, max_depth: int | None = None) -> None:
    """
    Enable or disable dynamic loop debug output.

    Args:
        enabled: Whether to enable debug output
        max_depth: Maximum nesting depth to print. None means unlimited.
    """
    _dynamic_debug.enabled = enabled
    _dynamic_debug.max_depth = max_depth
    _dynamic_debug.current_depth = 0


def get_dynamic_debug() -> tuple[bool, int | None, int]:
    """
    Get the current dynamic debug state.

    Returns:
        Tuple of (enabled, max_depth, current_depth)
    """
    return (
        _dynamic_debug.enabled,
        _dynamic_debug.max_depth,
        _dynamic_debug.current_depth,
    )


def should_print_dynamic_debug() -> bool:
    """
    Check if dynamic debug output should be printed at the current level.

    Returns:
        True if debug output is enabled and within max_depth limit.
    """
    return _dynamic_debug.should_print()


def get_dynamic_debug_level() -> int:
    """
    Get the current dynamic debug nesting level.

    Returns:
        Current nesting depth.
    """
    return _dynamic_debug.current_depth


class dynamic_debug_level:
    """
    Context manager for tracking nesting depth in dynamic debug output.

    Usage:
        with dynamic_debug_level():
            # Code at increased nesting level
            if should_print_dynamic_debug():
                print(f"Level {get_dynamic_debug_level()}: ...")
    """

    def __enter__(self) -> None:
        _dynamic_debug.enter_level()

    def __exit__(self, *args: object) -> None:
        _dynamic_debug.exit_level()


def reset_dynamic_debug_depth() -> None:
    """Reset the dynamic debug depth counter to 0."""
    _dynamic_debug.reset_depth()


def debug_print_mlir_values(
    obj: object, indent: int = 0, name: str | None = None, types_only: bool = False
) -> str:
    """
    Print a structured tree of MLIR values for debugging.

    Args:
        obj: The object to print
        indent: Current indentation level
        name: Optional name to display for this node
        types_only: If True, show MLIR types instead of full values

    Returns:
        str: A formatted string representation of the MLIR values tree
    """
    lines = []
    prefix = "  " * indent

    if name:
        type_name = name
    elif hasattr(obj, "__class__"):
        type_name = obj.__class__.__name__
    else:
        type_name = str(type(obj).__name__)

    if obj is None:
        lines.append(f"{prefix}{type_name}: (none)")
    elif isinstance(obj, ir.Value):
        if types_only:
            lines.append(f"{prefix}{type_name}: {obj.type}")
        else:
            lines.append(f"{prefix}{type_name}: {obj} : {obj.type}")
    elif hasattr(obj, "__extract_mlir_values__"):
        values = obj.__extract_mlir_values__()
        lines.append(f"{prefix}{type_name}:")
        if isinstance(values, dict):
            for key, val in values.items():
                if val is None:
                    lines.append(f"{prefix}  {key}: (static/none)")
                elif isinstance(val, ir.Value):
                    if types_only:
                        lines.append(f"{prefix}  {key}: {val.type}")
                    else:
                        lines.append(f"{prefix}  {key}: {val} : {val.type}")
                elif isinstance(val, (dict, list)):
                    lines.append(
                        f"{prefix}  {key}: {type(val).__name__} with {len(val)} items"
                    )
                else:
                    lines.append(f"{prefix}  {key}: {val}")
        elif isinstance(values, ir.Value):
            if types_only:
                lines.append(f"{prefix}  value: {values.type}")
            else:
                lines.append(f"{prefix}  value: {values} : {values.type}")
        elif isinstance(values, list):
            lines.append(f"{prefix}  [{len(values)} values]")
        else:
            lines.append(f"{prefix}  {values}")
    elif isinstance(obj, dict):
        lines.append(f"{prefix}{type_name}: dict with {len(obj)} items")
    elif isinstance(obj, (list, tuple)):
        lines.append(f"{prefix}{type_name}: [{len(obj)} items]")
    else:
        lines.append(f"{prefix}{type_name}: {obj}")

    return "\n".join(filter(None, lines))


def extract_mlir_attributes(obj: object) -> list[Any]:
    """
    Given the `obj`, recursively go through it to extract all contained IR attributes as list of MLIR attributes.
    This is used for generating kernel function argument attributes.
    """
    res = []
    if hasattr(obj, "__extract_mlir_attributes__"):
        res = obj.__extract_mlir_attributes__()
    elif isinstance(obj, (tuple, list)):
        res = sum((extract_mlir_attributes(x) for x in obj), [])
    elif isinstance(obj, SimpleNamespace):
        res = []
        for k, v in obj.__dict__.items():
            res.extend(extract_mlir_attributes(v))
    # Can't call is_dynamic_expression as _is_dynamic_expression depends on extract_mlir_values
    elif isinstance(obj, set):
        raise DSLRuntimeError(
            "Sets are not supported in extract_mlir_values to ensure order preservation",
            context="The DSL attempted to generate JIT function argument(s) for an argument of type set but failed.",
            suggestion="Consider using a list or tuple instead",
        )
    elif isinstance(obj, ir.Value):
        res = [ir.DictAttr.get({})]
    elif isinstance(obj, ir.BlockArgumentList):
        res = [ir.DictAttr.get({})] * len(obj)
    else:
        # Unlike extract_mlir_values we expand in the default case that we do not have an __extract_mlir_attributes__
        res = [ir.DictAttr.get({})] * len(get_mlir_types(obj))

    return res


def new_from_mlir_values(obj: Any, values: Any, *, structured: bool = False) -> Any:
    """
    Create a new python object by populating containing MLIR values with new values.

    Args:
        obj: The original object to use as a template
        values: Either a flat list of MLIR values (structured=False) or
                a nested structure matching __extract_mlir_values__ output (structured=True)
        structured: If False (default), values is a flat list sliced by type counts.
                   If True, values is passed directly to __new_from_mlir_values__.

    Returns:
        A new object of the same type as obj, with MLIR values replaced
    """
    # Objects with __new_from_mlir_values__ always receive values directly
    if hasattr(obj, "__new_from_mlir_values__"):
        return obj.__new_from_mlir_values__(values)

    import dataclasses

    if structured:
        # Tree-structured mode
        if dataclasses.is_dataclass(obj) and not isinstance(obj, type):
            new_field_values = {
                field.name: new_from_mlir_values(
                    getattr(obj, field.name), values[field.name], structured=True
                )
                for field in dataclasses.fields(obj)
            }
            return type(obj)(**new_field_values)
        elif isinstance(obj, (tuple, list)):
            res = [
                new_from_mlir_values(x, v, structured=True) for x, v in zip(obj, values)
            ]
            obj_ty = type(obj)
            if hasattr(obj_ty, '_make'):
                return obj_ty._make(res)
            return obj_ty(res)
        elif isinstance(obj, SimpleNamespace):
            ns = SimpleNamespace()
            for k, v in obj.__dict__.items():
                ns.__dict__[k] = new_from_mlir_values(v, values[k], structured=True)
            return ns
        elif isinstance(obj, ir.Value):
            return values
        elif is_dynamic_expression(obj):
            return values
        else:
            return obj
    else:
        # Flat list mode (original behavior)
        if isinstance(obj, (tuple, list)):
            res = []
            for x in obj:
                n_items = len(get_mlir_types(x))
                res.append(new_from_mlir_values(x, values[:n_items]))
                values = values[n_items:]
            obj_ty = type(obj)
            if hasattr(obj_ty, '_make'):
                return obj_ty._make(res)
            return obj_ty(res)
        elif isinstance(obj, SimpleNamespace):
            ns = SimpleNamespace()
            for k, v in obj.__dict__.items():
                n_items = len(get_mlir_types(v))
                ns.__dict__[k] = new_from_mlir_values(v, values[:n_items])
                values = values[n_items:]
            return ns
        elif isinstance(obj, set):
            raise DSLRuntimeError(
                "Sets are not supported in new_from_mlir_values to ensure order preservation",
                context="The DSL attempted to generate JIT function argument(s) for an argument of type set but failed.",
                suggestion="Consider using a list or tuple instead",
            )
        elif is_dynamic_expression(obj):
            if len(values) == 0:
                return obj

            assert len(values) == 1
            return values[0]
        else:
            assert len(values) == 0, f"{obj} expects 0 values, but got {values}"
            return obj


class DSLSingletonMeta(type):
    """
    Metaclass implementing the Singleton pattern for DSL classes.

    The DSLSingletonMeta ensures that only one instance of a derived DSL class exists at any time.
    When a class is called, it checks if an instance already exists in the `_instances` dictionary.
    - If requesting `BaseDSL` itself, it asserts that a concrete subclass has been initialized,
      and returns the first available singleton instance among subclasses.
    - If requesting a concrete subclass, it creates a new instance if none exists, or returns
      the already created instance.

    This metaclass is useful for maintaining global state and configuration across the DSL system,
    ensuring that all parts of the application operate on the same DSL instance.

    Attributes:
        _instances (dict): Maps DSL classes to their singleton instances.

    Example:
        class MyDSL(BaseDSL): ...
        dsl1 = MyDSL()
        dsl2 = MyDSL()
        assert dsl1 is dsl2  # Singleton property
    """

    _instances: ClassVar[dict] = {}
    _lock: ClassVar[threading.Lock] = threading.Lock()

    def __call__(cls, *args: Any, **kwargs: Any) -> Any:
        with cls._lock:
            log().info(f"DSLSingletonMeta __call__ for {cls}")
            if cls is BaseDSL:
                # If one is querying a BaseDSL which is abstract, returns an arbitrary instance of a concrete subclass should be fine.
                # Here we just return the first instance of a concrete subclass.
                assert cls._instances, (
                    "Need to initialize a concrete subclass of BaseDSL first"
                )
                return next(iter(cls._instances.values()))
            elif cls not in cls._instances:
                instance = super().__call__(*args, **kwargs)
                cls._instances[cls] = instance
            log().info(f"Active DSL singleton instances: {cls._instances}")
            return cls._instances[cls]

    def clear_instances(cls) -> None:
        log().info(
            f"Clearing DSL singleton instances for {cls}, current instances: {cls._instances}"
        )
        if cls in cls._instances:
            del cls._instances[cls]
        log().info(f"DSL singleton instances after clearing: {cls._instances}")


@dataclass(frozen=True)
class DSLLocation:
    """
    Represents Python source location information for MLIR DSL code.

    Attributes:
        filename (str): Name of the Python source file.
        lineno (int): Line number in the source file.
        col_offset (int): Column offset in the source line.
        function_name (str): Name of the function in which the location occurs.

    This is used primarily to annotate or trace locations in generated MLIR IR
    back to the original Python code for better diagnostic and debugging.
    """

    filename: str
    lineno: int
    col_offset: int
    function_name: str


class BaseDSL(metaclass=DSLSingletonMeta):
    gpu_module: Any = None
    _env_class: type[EnvironmentVarManager] = EnvironmentVarManager

    def __init__(
        self,
        *,
        name: str,
        dsl_package_name: list[str],
        compiler_provider: Any,
        pass_sm_arch_name: str,
        device_compilation_only: bool = False,
        preprocess: bool = False,
    ) -> None:
        """
        Constructor for initializing the class with required providers and environment settings.

        Parameters:
        - name (str): Name of DSL, used for environment variables and logging.
        - package_name (str): Name of the package, used for the preprocessor.
        - compiler_provider (MLIR dialect): Provider for compiler.
        - pass_sm_arch_name (str): The keyword name of the SM.
        - device_compilation_only (bool) : Only device code, and call it via cuda driver
        - preprocess (bool): Enable AST transformation.

        This constructs a DSL instance and sets up environment management,
        warning configurations, and logging functionalities. It reads
        environment variables using `EnvironmentVarManager` and configures
        a logger with settings from the environment. If environment warnings
        are detected, they are escalated to errors to ensure strict handling.
        """
        # Enforcing initialization of instance variables
        if not all([name, compiler_provider, pass_sm_arch_name]):
            raise DSLRuntimeError(
                "All required parameters must be provided and non-empty"
            )

        self.name: str = name
        self.compiler_provider: Any = compiler_provider
        self.pass_sm_arch_name: str = pass_sm_arch_name
        self.decorator_location: DSLLocation | None = None
        self.no_cache: bool = False
        self.device_compilation_only: bool = device_compilation_only
        self.num_kernels: int = 0
        # Read environment variables
        self.envar: EnvironmentVarManager = self._env_class(self.name)
        register_env_manager(self.envar)
        self.enable_preprocessor: bool = preprocess
        # This cache uses hash of original ir and env as key, allows dump/load to/from file. Enabled by default
        self.jit_cache: JitCacheDict = JitCacheDict(
            max_elems=self.envar.jit_cache_max_elems
        )

        self.host_jit_decorator_name: str = f"@{BaseDSL.jit.__name__}"
        self.device_jit_decorator_name: str = f"@{BaseDSL.kernel.__name__}"

        # set warning
        if not self.envar.enable_optimization_warnings:
            # By default, optimization warnings are disabled
            warnings.filterwarnings("ignore", category=DSLOptimizationWarning)
        if self.envar.warnings_as_errors:
            warnings.filterwarnings("error")
        if self.envar.warnings_ignore:
            warnings.filterwarnings("ignore")

        # kernel info contains per kernel info including symbol string and CUfunction attributes to set
        # It's valid until the compilation is done.
        # {symbol_string: {CUfunction_attribute: value}}
        self.kernel_info: OrderedDict[str, Any] = OrderedDict()
        # used to generate unique name for gpu.launch
        self.launch_inner_count: int = 0
        # initialize default compile options
        self.compile_options: CompileOptions = CompileOptions()

        if preprocess:
            self.preprocessor: DSLPreprocessor = DSLPreprocessor(dsl_package_name)

        log().info(f"Initializing {name} DSL")
        log().debug(f"Logger initialized for {self.name}")

        if self.envar.jit_time_profiling:
            self.profiler: Any = timer(enable=True)
            self.cache_hits: int = 0
            self.cache_misses: int = 0

        # Hook excepthook
        if self.envar.filter_stacktrace:
            origin_excepthook = sys.excepthook
            module_dir = walk_to_top_module(os.path.dirname(os.path.abspath(__file__)))

            def excepthook(
                excep_type: type, value: BaseException, traceback: Any
            ) -> None:
                filter_exception(value, module_dir)  # type: ignore[arg-type]
                if hasattr(value, "__traceback__"):
                    origin_excepthook(excep_type, value, value.__traceback__)
                else:
                    origin_excepthook(
                        excep_type,
                        value,
                        filter_stackframe(traceback, module_dir),  # type: ignore[arg-type]
                    )

            sys.excepthook = excepthook

            # Restore original excepthook
            def restore_excepthook(hook: Any) -> None:
                sys.excepthook = hook

            atexit.register(restore_excepthook, origin_excepthook)

    @lru_cache(maxsize=1)
    def print_warning_once(self, message: str) -> None:
        log().warning(f"Warning: {message}")
        warnings.warn(message, UserWarning)

    def print_warning(self, message: str) -> None:
        log().warning(f"Warning: {message}")
        warnings.warn(message, UserWarning)

    @classmethod
    def _get_dsl(cls) -> "BaseDSL":
        # Instantiate the DSL Class once (singleton metaclass returns existing instance)
        main_dsl = cls()  # type: ignore[call-arg]
        return main_dsl

    @staticmethod
    def _can_preprocess(**dkwargs: Any) -> bool:
        """
        Check if AST transformation is enabled or not for `jit` and `kernel` decorators.
        """
        return dkwargs.pop("preprocess", True)

    @staticmethod
    def _lazy_initialize_dsl(func: Any) -> None:
        """
        Lazy initialization of DSL object if has not been initialized
        """
        if hasattr(func, "_dsl_cls"):
            func._dsl_object = func._dsl_cls._get_dsl()
            delattr(func, "_dsl_cls")

    @staticmethod
    def _preprocess_and_replace_code(func: Any) -> None:
        """
        Run ast transformation and return the materialized function pointer
        """
        # Ensure the DSL instance is materialized before touching _dsl_object
        BaseDSL._lazy_initialize_dsl(func)

        # Update the decorator location to the new function
        func._dsl_object.decorator_location = func._decorator_location

        if getattr(func, "_preprocessed", False) is True:
            # already preprocessed, skip
            return

        if not func._dsl_object.enable_preprocessor:
            func._preprocessed = True
            return

        fcn_ptr = func._dsl_object.run_preprocessor(func)
        if fcn_ptr:
            func.__code__ = (
                fcn_ptr.__code__
                if not isinstance(fcn_ptr, staticmethod)
                else fcn_ptr.__func__.__code__
            )

    @staticmethod
    def jit_runner(
        cls: type["BaseDSL"],
        executor_name: str,
        frame: Any,
        *dargs: Any,
        **dkwargs: Any,
    ) -> Any:
        """
        Decorator to mark a function for JIT compilation.
        """
        log().info("jit_runner")

        def jit_runner_decorator(func: Any) -> Any:
            # Run preprocessor that alters AST
            func._dsl_cls = cls
            func._decorator_location = BaseDSL.get_location_from_frame(frame)
            if not hasattr(func, "_preprocessed") and not BaseDSL._can_preprocess(
                **dkwargs
            ):
                func._preprocessed = True

            @wraps(func)
            def jit_wrapper(*args: Any, **kwargs: Any) -> Any:
                BaseDSL._preprocess_and_replace_code(func)

                custom_name = getattr(jit_wrapper, "_name_prefix", None)
                if custom_name:
                    return getattr(func._dsl_object, executor_name)(
                        func, *args, **kwargs, _name_prefix=custom_name
                    )
                else:
                    return getattr(func._dsl_object, executor_name)(
                        func, *args, **kwargs
                    )

            def set_name_prefix(name: str) -> None:
                jit_wrapper._name_prefix = name  # type: ignore[attr-defined]

            jit_wrapper.set_name_prefix = set_name_prefix  # type: ignore[attr-defined]

            return jit_wrapper

        if len(dargs) == 1 and callable(dargs[0]):
            return jit_runner_decorator(dargs[0])
        else:
            return jit_runner_decorator

    @classmethod
    def jit(cls, *dargs: Any, **dkwargs: Any) -> Any:
        """
        Decorator to mark a function for JIT compilation for Host code.
        """
        frame = inspect.currentframe().f_back  # type: ignore[union-attr]
        return BaseDSL.jit_runner(cls, "_func", frame, *dargs, **dkwargs)

    @classmethod
    def kernel(cls, *dargs: Any, **dkwargs: Any) -> Any:
        """
        Decorator to mark a function for JIT compilation for GPU.
        """
        frame = inspect.currentframe().f_back  # type: ignore[union-attr]
        return BaseDSL.jit_runner(cls, "_kernel_helper", frame, *dargs, **dkwargs)

    @abstractmethod
    def _kernel_helper(self, func: Any, *args: Any, **kwargs: Any) -> Any:
        """
        Helper function to handle kernel generation logic
        """
        pass

    @abstractmethod
    def _build_gpu_module(self, attrs: dict[str, Any], loc: Any = None) -> None:
        """
        Build the module op that contains the kernels.
        """
        log().info(f"[abstract] Building GPU module for {self.name}")
        pass

    @abstractmethod
    def _get_pipeline(self, pipeline: str | None) -> str | None:
        """
        Get the pipeline from the other configuration options.
        """
        if pipeline != None:
            return pipeline
        return None

    @staticmethod
    def log_additions(
        func_type: Any, operands: Any = None, types: Any = None, arg_attrs: Any = None
    ) -> None:
        if operands is not None and operands != []:
            log().debug(
                f"Added {func_type} operands: [%s]", ", ".join(map(str, operands))
            )
        if types is not None:
            log().debug(
                f"Added {func_type} arg_types: [%s]", ", ".join(map(str, types))
            )
        if arg_attrs is not None:
            log().debug(
                f"Added {func_type} arg_attrs: [%s]", ", ".join(map(str, arg_attrs))
            )

    def mangle_name(
        self, function_name: str, args: tuple[Any, ...], sig: inspect.Signature
    ) -> str:
        """Does simple name mangling"""

        # sig.parameters maybe longer than args, but since canonicalized_args
        # only contains positional arguments, we can rely on zip to truncate
        for param, arg in zip(sig.parameters.values(), args):
            spec_ty = param.annotation
            if spec_ty != inspect.Parameter.empty:
                if issubclass(type(spec_ty), (t.IRValue, t.IRVariadic)):
                    continue
                if isinstance(spec_ty, (ir.Type, ir.Value)):
                    continue
            if isinstance(arg, (ir.Type, ir.Value, ir.OpResult)):
                continue
            if isinstance(type(arg), (ir.Type, ir.Value, ir.OpResult)):
                continue
            if self._is_tensor_descriptor(arg):
                continue
            if spec_ty != inspect.Parameter.empty and inspect.isclass(spec_ty):
                class_name = str(arg).replace("class", "")
                class_name = class_name.replace(" ", "")
                function_name = f"{function_name}_{class_name}"
            elif isinstance(arg, (list, tuple)):
                function_name = f"{function_name}_{'_'.join(map(str, arg))}"
            else:
                function_name = f"{function_name}_{arg}"
        # we would need a dedicated MR to follow up
        unwanted_chars = r"'-![]#,.<>()\":{}=%?@;"
        translation_table = str.maketrans("", "", unwanted_chars)
        function_name = function_name.translate(translation_table)
        # identify address and drop
        function_name = re.sub(r"0x[a-f0-9]{8,16}", "", function_name)
        function_name = re.sub(r"\s+", " ", function_name)
        function_name = function_name.replace(" ", "_")
        function_name = function_name.replace("\n", "_")
        function_name = function_name.replace("/", "_")
        # max fname is 256 character, leave space
        function_name = function_name[:180]
        log().info(f"Final mangled function name: {function_name}")
        return function_name

    def _generate_execution_arguments_for_known_types(
        self,
        arg: Any,
        arg_spec: Any,
        arg_name: str,
        i: int,
        fop_args: list[Any],
        iv_block_args: int,
    ) -> tuple[list[Any], int]:
        """
        Generate MLIR arguments for known types.

        Sub-DSLs can override this method to handle types that are not
        natively supported by the Base DSL.
        """
        ir_arg = []
        if is_argument_constexpr(arg, arg_spec, arg_name, i, func):
            ir_arg.append(arg)

        return ir_arg, iv_block_args

    def generate_execution_arguments(
        self,
        args: tuple[Any, ...],
        kwonlyargs: dict[str, Any],
        fop: Any,
        sig: inspect.Signature,
    ) -> tuple[list[Any], dict[str, Any]]:
        """Create list of arguments that will be passed to MLIR's func.func op"""

        def gen_exec_arg(
            idx: int,
            arg: Any,
            parameter: inspect.Parameter,
            fop_args: list[Any],
            iv_block_args: int,
        ) -> tuple[Any, int]:
            arg_name = parameter.name
            arg_spec = parameter.annotation
            log().debug("Processing [%d] Argument [%s : %s]", idx, arg_name, arg_spec)

            # Implicit cast to NumericMeta
            if isinstance(arg_spec, t.NumericMeta) and not isinstance(arg, arg_spec):
                arg = t.cast(arg, arg_spec)  # type: ignore[arg-type]

            ir_arg, iv_block_args = self._generate_execution_arguments_for_known_types(
                arg, arg_spec, arg_name, idx, fop_args, iv_block_args
            )

            if not ir_arg:
                # If it's not a known type, try JIT argument adapter
                # to convert the argument if possible
                adapter = JitArgAdapterRegistry.get_registered_adapter(arg)
                arg = adapter(arg) if adapter else arg

                n_args = len(get_mlir_types(arg))
                blk_args = fop_args[iv_block_args : iv_block_args + n_args]
                ir_arg = new_from_mlir_values(arg, blk_args)
                iv_block_args += n_args
            else:
                ir_arg = ir_arg[0]

            self.log_additions(ir_arg)
            return ir_arg, iv_block_args

        fop_args = list(fop.regions[0].blocks[0].arguments)
        ir_args = []
        ir_kwargs = {}
        iv_block_args = 0
        for i, (arg, param) in enumerate(zip(args, sig.parameters.values())):
            ir_arg, iv_block_args = gen_exec_arg(i, arg, param, fop_args, iv_block_args)
            ir_args.append(ir_arg)

        for i, (name, arg) in enumerate(kwonlyargs.items()):
            ir_arg, iv_block_args = gen_exec_arg(
                i, arg, sig.parameters[name], fop_args, iv_block_args
            )
            ir_kwargs[name] = ir_arg

        log().debug("execution args: %s", ", ".join(map(str, ir_args)))
        log().debug("execution kwargs: %s", ", ".join(map(str, ir_kwargs)))
        return ir_args, ir_kwargs

    @abstractmethod
    def _generate_mlir_type_for_tensor_descriptor(self, tensor: Any) -> Any:
        """
        Generate MLIR type for the tensor descriptor.
        """
        pass

    @abstractmethod
    def _generate_executable_arg_for_tensor_descriptor(
        self, mlir_value: Any = None, ptr_tensor_ty: Any = None, tensor: Any = None
    ) -> Any:
        """
        Generates executable value for the given tensor descriptor.
        """
        pass

    @abstractmethod
    def _is_tensor_descriptor(self, maybe_tensor_descriptor: object) -> bool:
        pass

    @abstractmethod
    def _handle_tensor_descriptor(
        self, maybe_tensor: Any, arg_name: str, need_gpu_memory: bool
    ) -> Any:
        pass

    def _should_remove_empty_gpu_modules(self) -> bool:
        """
        Returns whether empty gpu.module instances should be removed from
        the final generated IR.
        """
        return True

    @staticmethod
    def __remove_empty_gpu_modules(module: ir.Module) -> None:
        """
        Removes empty gpu.module instances from the given module.
        """

        def delete_empty_gpu_module_op(op: Any) -> ir.WalkResult:
            if op.name != "gpu.module":
                return ir.WalkResult.ADVANCE
            if (
                len(op.regions) == 0
                or len(op.regions[0].blocks) == 0
                or len(op.regions[0].blocks[0].operations) == 0
            ):
                op.erase()
            return ir.WalkResult.ADVANCE

        module.operation.walk(delete_empty_gpu_module_op)

    def _validate_arg(
        self, arg: Any, arg_index: int, arg_name: str, arg_spec: Any
    ) -> Any:
        """
        Validates if the arg is really of the annotated type for type safety.

        The default implementation is empty. Subclasses can override this method to add more validation logic.
        Returns None if validation passes, otherwise returns an error derived from DSLBaseError.
        """
        pass

    def _generate_jit_func_args_for_known_types(
        self,
        func: Any,
        arg: Any,
        arg_name: str,
        arg_spec: Any,
        arg_index: int,
        *,
        is_host: bool = True,
    ) -> tuple[list[Any] | None, list[Any] | None, list[Any] | None]:
        """
        Generate JIT function arguments for known types.

        Sub-DSLs can override this method to handle types that are not
        natively supported by the Base DSL.
        """

        jit_arg_type: list[Any] | None = []
        jit_arg_attr: list[Any] | None = []
        jit_exec_arg: list[Any] | None = []

        if is_argument_constexpr(arg, arg_spec, arg_name, arg_index, func):
            jit_exec_arg = jit_arg_type = jit_arg_attr = None

        return jit_exec_arg, jit_arg_type, jit_arg_attr

    def _generate_jit_func_args(
        self,
        func: Any,
        function_name: str,
        args: tuple[Any, ...] | list[Any],
        kwonlyargs: dict[str, Any],
        sig: inspect.Signature,
        *,
        is_host: bool = True,
        compile_only: bool = False,
    ) -> tuple[list[Any], list[Any], list[Any], list[Any]]:
        """Generate JIT function arguments."""

        positional_names = []
        kwonly_names = []
        for name, param in sig.parameters.items():
            if param.kind == inspect.Parameter.KEYWORD_ONLY:
                kwonly_names.append(name)
            else:
                positional_names.append(name)

        assert len(args) == len(positional_names) and len(kwonlyargs) == len(
            kwonly_names
        ), (
            f"Input args {len(args)=} and kwonlyargs {len(kwonlyargs)=} must match positional params "
            f"{len(positional_names)=} and keyword-only params {len(kwonly_names)=}"
        )

        jit_arg_types: list[Any] = []
        jit_arg_attrs: list[Any] = []
        jit_exec_args: list[Any] = []
        jit_adapted_args = []
        default_attr = ir.DictAttr.get({})

        input_args = [*args, *kwonlyargs.values()]
        input_arg_names = [*positional_names, *kwonly_names]
        for i, (arg_name, arg) in enumerate(zip(input_arg_names, input_args)):
            spec_ty = sig.parameters[arg_name].annotation

            # Unwrap Annotated[T, marker1, ...] → base type T + markers.
            annotation_markers = ()
            if (
                spec_ty is not inspect.Parameter.empty
                and get_origin(spec_ty) is Annotated
            ):
                type_args = get_args(spec_ty)
                spec_ty = type_args[0]
                annotation_markers = type_args[1:]

            log().debug("Processing [%d] Argument [%s : %s]", i, arg_name, spec_ty)

            # Implicitly convert into Numeric type if possible
            if isinstance(spec_ty, t.NumericMeta) and not isinstance(arg, spec_ty):
                arg = t.cast(arg, spec_ty)  # type: ignore[arg-type]

            # Type safety check
            if spec_ty is not inspect.Parameter.empty:
                err = self._validate_arg(arg, i, arg_name, spec_ty)
                if err is not None:
                    raise err

            jit_exec_arg, jit_arg_type, jit_arg_attr = (
                self._generate_jit_func_args_for_known_types(
                    func,
                    arg,
                    arg_name,
                    spec_ty,
                    i,
                    is_host=is_host,
                )
            )

            if jit_arg_type is not None and len(jit_arg_type) == 0:
                # If not any known type, try JIT argument adapter
                # to convert the argument
                adapter = JitArgAdapterRegistry.get_registered_adapter(arg)
                if adapter:
                    arg = adapter(arg)
                    jit_adapted_args.append(arg)

                if is_host:
                    if self.envar.enable_tvm_ffi:
                        jit_exec_arg.extend([arg])  # type: ignore[union-attr]
                    else:
                        jit_exec_arg.extend(get_c_pointers(arg))  # type: ignore[union-attr]
                    jit_arg_type.extend(get_mlir_types(arg))
                    jit_arg_attr.extend([default_attr] * len(get_mlir_types(arg)))  # type: ignore[union-attr]
                else:
                    dyn_vals = extract_mlir_values(arg)
                    jit_exec_arg.extend(dyn_vals)  # type: ignore[union-attr]
                    jit_arg_type.extend([v.type for v in dyn_vals])
                    jit_arg_attr.extend(extract_mlir_attributes(arg))  # type: ignore[union-attr]

                if not jit_arg_type or not jit_exec_arg:
                    # when it is compile only, we don't have to prepare the executable arguments.
                    if (is_host and (compile_only or implements_jit_argument(arg))) or (
                        not is_host and implements_dynamic_expression(arg)
                    ):
                        pass
                    else:
                        raise DSLRuntimeError(
                            f"failed to generate argument #{i + 1} ({arg_name}) for JIT function '{function_name}'.",
                            context={
                                f"Argument {arg_name}": "The DSL attempted to convert it into Dynamic Expression (aka MLIR values) but failed.",
                                "Call-site argument value": arg,
                                "Call-site argument type": type(arg),
                            },
                            suggestion=f"Consider annotating the argument with `{arg_name} : Constexpr` "
                            "if it's a value known at compile-time. "
                            f"Otherwise, implement the {'`JitArgument`' if is_host else '`DynamicExpression`'} "
                            f"protocol or register a custom JIT argument adapter for type `{type(arg)}` to "
                            "enable dynamic value conversion at runtime.",
                        )

            if jit_arg_type is not None:
                jit_exec_args.extend(jit_exec_arg)  # type: ignore[arg-type]
                jit_arg_types.extend(jit_arg_type)
                jit_arg_attrs.extend(jit_arg_attr)  # type: ignore[arg-type]

        return jit_exec_args, jit_arg_types, jit_arg_attrs, jit_adapted_args

    def generate_mlir_function_types(
        self,
        func: Any,
        function_name: str,
        args: tuple[Any, ...] | list[Any],
        kwonlyargs: dict[str, Any],
        sig: inspect.Signature,
        compile_only: bool = False,
    ) -> tuple[list[Any], list[Any], list[Any]]:
        """Convert input arguments to MLIR function signature also convert numpy arrays to memref."""

        exe_args, types, attrs, adapted_args = self._generate_jit_func_args(
            func,
            function_name,
            args,
            kwonlyargs,
            sig,
            is_host=True,
            compile_only=compile_only,
        )

        log().debug("Execution Arguments: %s", ", ".join(map(str, exe_args)))
        log().debug("Types: %s", ", ".join(map(str, types)))

        assert (
            compile_only or self.envar.enable_tvm_ffi or len(exe_args) == len(types)
        ), "expects the same number of arguments and function parameters"

        return exe_args, types, adapted_args

    @dataclass
    class LaunchConfig:
        cluster: list[Any] | None = None
        fallback_cluster: list[Any] | None = None
        grid: list[Any] = field(default_factory=lambda: [1, 1, 1])
        block: list[Any] = field(default_factory=lambda: [1, 1, 1])
        max_number_threads: list[Any] = field(default_factory=lambda: [0, 0, 0])
        smem: int | None = None
        async_deps: list[Any] = field(default_factory=list)
        has_cluster: bool = False
        has_fallback_cluster: bool = False
        min_blocks_per_mp: int = 0
        use_pdl: bool = False
        auto_smem: bool = False
        cooperative: bool = False

        @staticmethod
        def _check_and_canonicalize_dim(dim: Any, name: str) -> list[Any]:
            if not isinstance(dim, (list, tuple)):
                dim = [dim]

            if len(dim) > 3:
                raise DSLRuntimeError(
                    f"Expected {name} dimension to be less than or equal to 3, but got {len(dim)}"
                )
            for idx, e in enumerate(dim):
                if not isinstance(e, (Integer, int)):
                    raise DSLRuntimeError(
                        f"Expected integer for {name} dimension at index {idx}, but got {type(e)}"
                    )

            # Pad with 1s to 3-dim vector for grid or block dimensions
            return list(dim) + [1] * (3 - len(dim))

        def __post_init__(self) -> None:
            self.grid = self._check_and_canonicalize_dim(self.grid, "grid")
            self.block = self._check_and_canonicalize_dim(self.block, "block")

            if self.smem is None:
                self.smem = 0
                self.auto_smem = True

            self.has_cluster = self.cluster is not None
            if self.cluster is None:
                self.cluster = [None, None, None]
            elif len(self.cluster) != 3:
                raise DSLRuntimeError("Expect 3d cluster!")

            self.has_fallback_cluster = self.fallback_cluster is not None
            if self.fallback_cluster is None:
                self.fallback_cluster = [None, None, None]
            elif len(self.fallback_cluster) != 3:
                raise DSLRuntimeError("Expect 3d fallback_cluster!")

        def has_max_number_threads(self) -> bool:
            """Check if max_number_threads is given by user"""
            return all(
                value == 0 if not is_dynamic_expression(value) else False
                for value in self.max_number_threads
            )

    def diagnostic(self) -> None:
        """Check command line parameters and enables diagnostic"""
        # Check command line arguments "-diagnostic"
        parser = argparse.ArgumentParser(description="Process diagnostic status.")
        parser.add_argument(
            "-diagnostic",
            nargs="?",
            const="all",
            choices=["all", "fail", "success", "info", "suggestion"],
            help="Set diagnostic status (fail, success, info, suggestion).",
        )

        args, _ = parser.parse_known_args()
        ctx = ir.Context.current

        def callback(d: Any) -> None:
            print(f"  [{self.name} Diagnostic] : {d.message}")

        ctx.attach_diagnostic_handler(callback)

        # Early return, don't enable diagnostics
        if args.diagnostic is None:
            return

        # Enable MLIR Flags
        ctx.emit_error_diagnostics = True
        ir._GlobalDebug.flag = True
        if args.diagnostic == "all":
            ir._GlobalDebug.set_types("diagnostic")
        else:
            ir._GlobalDebug.set_types(f"diagnostic-{args.diagnostic}")

    @staticmethod
    def get_location_from_frame(frame: Any) -> DSLLocation:
        return DSLLocation(
            filename=inspect.getsourcefile(frame),  # type: ignore[arg-type]
            lineno=frame.f_lineno,
            col_offset=0,
            function_name=frame.f_code.co_name,
        )

    def get_ir_location(self, location: DSLLocation | None = None) -> Any:
        """
        Get python location information and generate MLIR location
        """
        if location is None:
            if self.decorator_location:
                location = self.decorator_location

        if location is None:
            return ir.Location.unknown()

        file_loc = ir.Location.file(
            location.filename,
            location.lineno,
            location.col_offset,
        )
        loc = ir.Location.name(
            (location.function_name),
            childLoc=file_loc,
        )
        return loc

    def compile_and_jit(
        self,
        module: ir.Module,
        pipeline: str,
        shared_libs: list[str],
        function_name: str = "",
    ) -> Any:
        """
        Compile and JIT an MLIR module.
        """

        try:
            self.diagnostic()

            orig_stdout = sys.stdout
            orig_stderr = sys.stderr
            sys.stderr = redirect_stderr = io.StringIO()
            sys.stdout = redirect_stdout = io.StringIO()

            try:
                enable_debug_info = self.envar.lineinfo
                kernel = self.compiler_provider.compile_and_jit(
                    module,
                    pipeline,
                    shared_libs=shared_libs,
                    arch=self.envar.arch,
                    enable_debug_info=enable_debug_info,
                )

            finally:
                sys.stdout = orig_stdout
                sys.stderr = orig_stderr
                ir._GlobalDebug.flag = False

            # Print captured output.
            print(redirect_stdout.getvalue(), file=sys.stdout, end="")
            print(redirect_stderr.getvalue(), file=sys.stderr, end="")

            return kernel

        except Exception as e:
            raise DSLRuntimeError("🧊🧊🧊 ICE 🧊🧊🧊", cause=e)
        finally:
            pass

    def preprocess_pipeline(self, pipeline: str, arch: str) -> str:
        options = {
            self.pass_sm_arch_name: arch,
        }

        opt_str = ""
        for k, v in options.items():
            if v:
                opt_str += f"{k}={v} "

        if opt_str:
            # Automatically append the pipeline options if any is specified through env var
            pattern = re.compile(r"{(.+)}")
            match = pattern.search(pipeline)
            if match:
                opt_str = f"{{{match[1]} {opt_str}}}"
                pipeline = re.sub(r"{.+}", opt_str, pipeline)
            else:
                pipeline = pipeline.rstrip(")") + f"{{{opt_str}}})"
        return pipeline

    def get_shared_libs(self) -> list:
        shared_libs = []
        support_libs = self.envar.shared_libs
        if support_libs is not None:
            _libs = support_libs.split(":")
            for lib in _libs:
                if not os.path.exists(lib):
                    raise FileNotFoundError(
                        errno.ENOENT, os.strerror(errno.ENOENT), lib
                    )
                shared_libs.append(lib)
        else:
            if is_cutlass_family_dsl_prefix(self.name):
                self.print_warning(
                    f"{self.name}_LIBS environment variable is not set and "
                    "CuTe-family auto-discovery failed. Set "
                    f"{self.name}_LIBS to the path of libcute_dsl_runtime.so "
                    "(e.g. <build_dir>/lib/libcute_dsl_runtime.so). For pip "
                    "editable installs, setting CUTE_DSL_LIBS or ensuring "
                    "PYTHONPATH includes <build_dir>/cutlass_ir/python_packages "
                    "also works."
                )
            else:
                self.print_warning(
                    f"{self.name}_LIBS environment variable is not set and "
                    f"auto-discovery failed. Set {self.name}_LIBS explicitly "
                    "for this DSL runtime."
                )

        return shared_libs

    @lru_cache(maxsize=1)
    def get_version(self) -> "hashlib._Hash":
        version_hash = hashlib.sha256()

        return version_hash

    def get_module_hash(self, module: ir.Module, function_name: str) -> str:
        s = io.BytesIO()
        module.operation.write_bytecode(s)
        for attr, value in self.envar.__dict__.items():
            if value is not None:
                s.write(str(value).encode())
        # Add compile options to the hash
        s.write(self.compile_options.to_str().encode())
        hash_obj = self.get_version().copy()
        hash_obj.update(s.getvalue())
        module_hash = hash_obj.hexdigest()

        log().debug("Bytecode=[%s]", s.getvalue().hex())
        log().debug("Version=[%s]", self.get_version().hexdigest())
        log().info(
            "Function=[%s] Computed module_hash=[%s]", function_name, module_hash
        )
        return module_hash

    def build_module(self, module: ir.Module, function_name: str) -> ir.Module:
        """
        Build the MLIR module, verify and return the module
        """

        # Save IR in a file (raw, before any passes) — triggered by KEEP=ir-debug
        if self.envar.keep_ir:
            self.dump_mlir_path = save_ir(
                self.name,
                module,
                function_name,
                output_dir=self.envar.dump_dir,
                enable_debug_info=self.envar.lineinfo,
            )

        # Save clean IR (after canonicalize+cse) — triggered by KEEP=ir
        # Clone before compiling so the original module is not mutated.
        if self.envar.keep_ir_clean:
            module_clone = ir.Module.parse(str(module))
            self.compiler_provider.compile(
                module_clone, "builtin.module(canonicalize,cse)"
            )
            self.dump_mlir_path = save_ir(
                self.name,
                module_clone,
                f"{function_name}_clean",
                output_dir=self.envar.dump_dir,
                enable_debug_info=self.envar.lineinfo,
            )

        if self.envar.print_ir:
            print("\n//===--- ------ Generated IR ------ ---====\n")
            enable_debug_info = self.compile_options.generate_line_info
            module.operation.print(enable_debug_info=enable_debug_info)
            print("\n//===--- --- End of Generated IR -- ---====\n")

        # Verify the module
        try:
            module.operation.verify()
        except Exception as e:
            raise DSLRuntimeError("🧊🧊🧊 ICE IR Verification Failed 🧊🧊🧊", cause=e)

        return module

    def get_return_types(self) -> list[Any]:
        """
        Get the return types of the host function.
        """
        return []

    def generate_default_return_values(self, ip: Any = None) -> list[Any]:
        """
        Generate the default return values of the host function.
        """
        return []

    def generate_original_ir(
        self,
        ir: Any,
        func: Any,
        funcBody: Callable[..., Any],
        function_name: str,
        func_types: list[Any],
        gpu_module_attrs: dict[str, Any],
        args: tuple[Any, ...],
        kwonlyargs: dict[str, Any],
        sig: inspect.Signature,
        location: DSLLocation | None = None,
    ) -> tuple[ir.Module, str, Any]:
        def build_ir_module() -> tuple[ir.Module, Any]:
            loc = self.get_ir_location(location)
            module = ir.Module.create(loc=loc)
            unit_attr = ir.UnitAttr.get()
            module.operation.attributes["gpu.container_module"] = unit_attr

            with ir.InsertionPoint(module.body):
                # Always generate gpu module. We will remove it later if it is empty.
                self._build_gpu_module(gpu_module_attrs, loc=loc)

                ret_types = self.get_return_types()
                fop = func.FuncOp(function_name, (func_types, ret_types), loc=loc)
                fop.attributes["llvm.emit_c_interface"] = ir.UnitAttr.get()
                log().debug("Generated Function OP [%s]", fop)
                # Attach per-argument source locations if supported by the FuncOp binding.
                arg_locs = [loc for _ in range(len(func_types))]
                entry_block = fop.add_entry_block(arg_locs=arg_locs)
                with ir.InsertionPoint(entry_block):
                    ir_args, ir_kwargs = self.generate_execution_arguments(
                        args, kwonlyargs, fop, sig
                    )
                    # Call user function body
                    try:
                        result = funcBody(*ir_args, **ir_kwargs)
                        default_ret_values = self.generate_default_return_values(
                            ir.InsertionPoint.current
                        )
                        func.ReturnOp(default_ret_values, loc=loc)
                    except NameError as name_error:
                        raise DSLRuntimeError(
                            f"💥💥💥 Error during runtime code generation for function `{funcBody.__name__}` 💥💥💥",
                            cause=name_error,
                            suggestion="Using variables defined in dynamic control flow is not supported. Please give an initial value before control flow.",
                        )
                    except DSLRuntimeError as dsl_error:
                        # Throw it's already a DSL error
                        raise dsl_error

                if self._should_remove_empty_gpu_modules():
                    BaseDSL.__remove_empty_gpu_modules(module)

            return module, result

        # Build IR module
        if self.envar.jit_time_profiling:
            module, result = self.profiler(build_ir_module)()
        else:
            module, result = build_ir_module()
        module_hash = self.get_module_hash(module, function_name)

        module = self.build_module(module, function_name)

        return module, module_hash, result

    def compile_and_cache(
        self,
        module: ir.Module,
        module_hash: str,
        function_name: str,
        pipeline: str | None,
        sig: inspect.Signature,
        no_cache: bool,
        no_jit_engine: bool,
        func_type: type[JitCompiledFunction] = JitCompiledFunction,
        *,
        full_args: Any = None,
        full_kwargs: Any = None,
        dynamic_args: Any = None,
        dynamic_kwargs: Any = None,
        original_function_name: str | None = None,
        funcBody: Callable[..., Any] | None = None,
    ) -> JitCompiledFunction:
        # If `gpu-arch` is set by compile_options, use it. Otherwise, use the arch from the environment variable.
        compile_gpu_arch = (
            self.envar.arch
            if not self.compile_options.gpu_arch
            else self.compile_options.gpu_arch
        )
        # If no gpu kernels or compile_gpu_arch is same as the arch from the environment variable, generate a JIT engine. Otherwise, only do the compilation.
        gen_jit_engine = self.num_kernels == 0 or compile_gpu_arch == self.envar.arch
        if no_jit_engine:
            gen_jit_engine = False
        # Preprocess the pipeline.
        pipeline = self.preprocess_pipeline(
            self._get_pipeline(pipeline),  # type: ignore[arg-type]
            compile_gpu_arch,  # type: ignore[arg-type]
        )
        shared_libs = self.get_shared_libs()
        # try load the file cache
        load_from_file_cache = False
        if not no_cache:
            fn = load_cache_from_path(
                self.name, module_hash, bytecode_reader=read_bytecode_and_check_crc32
            )
            if fn is not None:
                load_from_file_cache = True
                self.jit_cache.set(module_hash, fn, funcBody=funcBody)

        cached_jit_func = None if no_cache else self.jit_cache.get(module_hash)

        if no_cache or cached_jit_func is None or cached_jit_func.ir_module is None:
            if self.envar.jit_time_profiling:
                self.cache_misses += 1
                log().info(
                    "Jit cache hit rate=[%f%%]",
                    self.cache_hits / (self.cache_hits + self.cache_misses) * 100,
                )
            log().info(
                "JIT cache miss function=[%s] module_hash=[%s]",
                function_name,
                module_hash,
            )
            # Compile and JIT MLIR module
            if gen_jit_engine:
                if self.envar.jit_time_profiling:
                    engine = self.profiler(self.compile_and_jit)(
                        module, pipeline, shared_libs, function_name=function_name
                    )
                else:
                    engine = self.compile_and_jit(
                        module, pipeline, shared_libs, function_name=function_name
                    )
            else:
                if self.envar.jit_time_profiling:
                    self.profiler(self.compiler_provider.compile)(
                        module,
                        pipeline,
                    )
                else:
                    self.compiler_provider.compile(module, pipeline)
                engine = None
        else:
            log().info(
                "JIT cache hit IN-FILE function=[%s] module_hash=[%s]",
                function_name,
                module_hash,
            )
            if self.envar.jit_time_profiling:
                self.cache_hits += 1
                log().info(
                    "JIT cache hit rate=[%f%%]",
                    self.cache_hits / (self.cache_hits + self.cache_misses) * 100,
                )
            module = cached_jit_func.ir_module
            engine = (
                self.compiler_provider.jit(module, shared_libs=shared_libs)
                if gen_jit_engine
                else None
            )
        if self.envar.jit_time_profiling:
            capi_func = self.profiler(engine.lookup)(function_name) if engine else None
        else:
            capi_func = engine.lookup(function_name) if engine else None

        fn = func_type(
            module,
            engine,
            capi_func,
            sig,
            function_name,
            self.kernel_info,
            jit_time_profiling=self.envar.jit_time_profiling,
            has_gpu_module=self.num_kernels > 0,
            jit_function_artifacts=JitFunctionArtifacts(
                PTX=self.compile_options.full_ptx_path,
                CUBIN=self.compile_options.full_cubin_path,
                MLIR=(
                    str(self.dump_mlir_path)
                    if (self.envar.keep_ir or self.envar.keep_ir_clean)
                    else None
                ),
            ),
            # set dynamic arguments if the jit_function is a JitCompiledFunction for AOT generation.
            dynamic_args=dynamic_args,
            dynamic_kwargs=dynamic_kwargs,
        )

        if not no_cache:
            # module stored in cache is compiled.
            self.jit_cache.set(module_hash, fn, funcBody=funcBody)
            # write through the file cache if enabled.
            if not self.envar.disable_file_caching and not load_from_file_cache:
                dump_cache_to_path(
                    self.name,
                    fn,
                    module_hash,
                    bytecode_writer=lambda f: write_bytecode_with_crc32(
                        f, fn.ir_module
                    ),
                )

        return fn

    def post_compilation_cleanup(self) -> None:
        """Clean up some internal state after one compilation is completed."""
        # clear the kernel info after the compilation is done.
        self.kernel_info = OrderedDict()
        self.launch_inner_count = 0
        # reset num_kernels to 0 for next compilation.
        self.num_kernels = 0
        # reset the compile options after the compilation is done.
        self.compile_options = CompileOptions()
        # reset decorator location after the compilation is done.
        self.decorator_location = None

    def extract_dynamic_args(
        self,
        funcBody: Callable[..., Any],
        args: tuple[Any, ...],
        kwonlyargs: dict[str, Any],
        sig: inspect.Signature,
    ) -> tuple[list[Any], OrderedDict[str, Any]]:
        """This function is used to extract the original dynamic arguments for AOT C header generation.
        The dynamic argument is the argument which is not marked as `Constexpr` in the function signature.
        """
        dynamic_args = []
        dynamic_kwonlyargs = OrderedDict()
        for i, (arg, param) in enumerate(zip(args, sig.parameters.values())):
            arg_name = param.name
            arg_annotation = param.annotation
            if not is_arg_annotation_constexpr(
                arg_annotation,
                arg_name,
                i,
                funcBody,
            ):
                dynamic_args.append(arg)
        for i, (arg_name, v) in enumerate(kwonlyargs.items()):
            arg_annotation = sig.parameters[arg_name].annotation
            if not is_arg_annotation_constexpr(
                arg_annotation,
                arg_name,
                i + len(args),
                funcBody,
            ):
                dynamic_kwonlyargs[arg_name] = v

        return dynamic_args, dynamic_kwonlyargs

    def generate_mlir(
        self,
        funcBody: Callable[..., Any],
        function_name: str,
        gpu_module_attrs: dict[str, Any],
        args: tuple[Any, ...],
        kwonlyargs: dict[str, Any],
        sig: inspect.Signature,
        pipeline: str | None,
        no_cache: bool,
        no_jit_engine: bool,
        compile_only: bool,
        location: DSLLocation | None = None,
    ) -> Any:
        """Generate MLIR module and compile iself.T_provider."""
        with ir.Context() as ctx, self.get_ir_location(location):
            # If threading is enabled, each MLIR context will keep alive a thread pool.
            # When we cache MLIR compilation results, we also cache its context thus accumulating #(compilations) * thread_pool_size threads.
            # Disable threading to avoid such excessive number of threads.
            ctx.enable_multithreading(False)
            # Optional: capture full Python call stacks on every MLIR op.
            # Enable via CUTE_DSL_LOC_TRACEBACKS=N (e.g. 128 for full stacks).
            # Default OFF — deep tracebacks + LINEINFO causes segfault.
            _loc_tb_depth = self.envar.loc_tracebacks
            _loc_tb_ctx = None
            if _loc_tb_depth:
                try:
                    _depth = int(_loc_tb_depth)
                    _loc_tb_ctx = ir.loc_tracebacks(max_depth=_depth)
                    _loc_tb_ctx.__enter__()
                except (ValueError, TypeError, AttributeError):
                    pass

            try:
                # Convert input arguments to MLIR arguments
                exe_args, func_types, adapted_args = self.generate_mlir_function_types(
                    funcBody, function_name, args, kwonlyargs, sig, compile_only
                )
                dynamic_args, dynamic_kwargs = self.extract_dynamic_args(
                    funcBody, args, kwonlyargs, sig
                )
                original_function_name = funcBody.__name__

                # Generate original ir module and its hash value.
                module, module_hash, result = self.generate_original_ir(
                    ir,
                    func,
                    funcBody,
                    function_name,
                    func_types,
                    gpu_module_attrs,
                    args,
                    kwonlyargs,
                    sig,
                    location=location,
                )

                # add ffi bitcode sources to link options
                for gpu_module in module.body.operations:
                    if gpu_module.name != "gpu.module":
                        continue
                    if gpu_module is not None:
                        link_libraries = self.compile_options.options[
                            LinkLibraries
                        ].value
                        try:
                            link_libraries_attributes = gpu_module.attributes[
                                "link-libraries"
                            ]
                        except KeyError:
                            link_libraries_attributes = set()
                        sources = set(x.value for x in link_libraries_attributes)
                        link_libraries = (
                            link_libraries
                            + ("," if len(link_libraries) > 0 else "")
                            + ",".join(sources)
                        )
                        self.compile_options.options[LinkLibraries] = LinkLibraries(
                            link_libraries
                        )

                # dryrun is used to only generate IR
                if self.envar.dryrun:
                    return result

                # Get a single reference to the cache since garbage collection
                cached_jit_func = None if no_cache else self.jit_cache.get(module_hash)

                if (
                    no_cache
                    or cached_jit_func is None
                    or cached_jit_func.capi_func is None
                ):
                    # no cache or cache miss, do ir generation/compilation/jit engine
                    jit_function = self.compile_and_cache(
                        module,
                        module_hash,
                        function_name,
                        pipeline,
                        sig,
                        no_cache,
                        no_jit_engine,
                        full_args=args,
                        full_kwargs=kwonlyargs,
                        dynamic_args=dynamic_args,
                        dynamic_kwargs=dynamic_kwargs,
                        original_function_name=original_function_name,
                        funcBody=funcBody,
                    )
                else:
                    # cache hit
                    log().info(
                        "JIT cache hit IN-MEMORY function=[%s] module_hash=[%s]",
                        function_name,
                        module_hash,
                    )
                    jit_function = cached_jit_func

            finally:
                if _loc_tb_ctx is not None:
                    try:
                        _loc_tb_ctx.__exit__(None, None, None)
                    except Exception:
                        pass
                self.post_compilation_cleanup()

        # If compile_only is set, bypass execution return the jit_executor directly
        if compile_only:
            return jit_function

        # Run the compiled program
        jit_function.run_compiled_program(exe_args)

        return result

    @staticmethod
    def _inject_closure_cells(
        original_function: Any, exec_globals: dict[str, Any]
    ) -> None:
        """Inject closure cell values into *exec_globals*.

        When a decorated function captures variables from an enclosing scope,
        those names are absent from ``__globals__``.  The AST preprocessor
        re-parses the source and ``exec()``s it, which requires those names
        to be resolvable in *exec_globals*.

        This mirrors the injection already done by
        ``function_compiler._rewrite_callee``.
        """
        if original_function.__closure__:
            for name, cell in zip(
                original_function.__code__.co_freevars,
                original_function.__closure__,
            ):
                try:
                    exec_globals[name] = cell.cell_contents
                except ValueError:
                    # Cell may be empty if the variable was never assigned
                    # in the enclosing scope; safe to skip.
                    pass

    def run_preprocessor(
        self, original_function: Any, callee_rewrite: bool = False
    ) -> Any:
        function_name = original_function.__name__
        self.funcBody = original_function
        log().info("Started preprocessing [%s]", function_name)
        exec_globals = {}
        if original_function.__globals__ is not None:
            exec_globals.update(original_function.__globals__)
        self._inject_closure_cells(original_function, exec_globals)
        with self.preprocessor.get_session() as preprocessor_session:
            transformed_ast = preprocessor_session.transform(
                original_function, exec_globals
            )
            if self.envar.print_after_preprocessor:
                log().info(
                    f"# Printing unparsed AST after preprocess of func=`{function_name}` id=`{id(original_function)}`"
                )
                DSLPreprocessor.print_ast(transformed_ast)
            file_name = inspect.getsourcefile(original_function)
            code_object = compile(
                transformed_ast,
                filename=file_name or "<unknown>",
                mode="exec",
            )

            original_function._preprocessed = True

            return preprocessor_session.exec(
                original_function.__name__,
                original_function,
                code_object,
                exec_globals,
            )

    def _get_function_bound_args(
        self, sig: inspect.Signature, func_name: str, *args: Any, **kwargs: Any
    ) -> inspect.BoundArguments:
        """
        Binds provided arguments to a function's signature and applies default values.

        E.g. given a function signature `def foo(a, b=2, c=3)`, and at call-site if we do
        `foo(a=1, c=4)`, the returned BoundArguments object will have args = `[1]`
        and kwargs = `{'b': 2, 'c': 4}`

        An exception will be raised if binding fails.
        """
        try:
            bound_args = sig.bind_partial(*args, **kwargs)
            bound_args.apply_defaults()
        except Exception as e:
            raise DSLRuntimeError(
                f"Failed to bind arguments to function `{func_name}` with signature `{sig}`",
                cause=e,
            )
        return bound_args

    def _canonicalize_args(
        self, bound_args: inspect.BoundArguments
    ) -> tuple[tuple[Any, ...], dict[str, Any]]:
        """
        Canonicalize the input arguments so that returned args only contain
        positional arguments and kwargs only contain keyword arguments.
        """
        canonicalized_args = bound_args.args
        canonicalized_kwonlyargs = bound_args.kwargs
        return canonicalized_args, canonicalized_kwonlyargs

    def _check_arg_count(
        self,
        sig: inspect.Signature,
        bound_args: inspect.BoundArguments,
        function_name: str,
    ) -> bool:
        # Check if all non-default arguments are provided
        has_varargs = False
        for param in sig.parameters.values():
            if param.kind in (
                inspect.Parameter.VAR_POSITIONAL,
                inspect.Parameter.VAR_KEYWORD,
            ):
                has_varargs = True
                continue
            if (
                param.default is inspect.Parameter.empty
                and param.name not in bound_args.arguments
            ):
                raise DSLRuntimeError(
                    f"Missing required argument in `{function_name}`: '{param.name}'"
                )
        return has_varargs

    def _get_signature(self, funcBody: Callable[..., Any]) -> inspect.Signature:
        """
        Returns the signature for a given function, handling PEP-563
        (postponed evaluation of type annotations) via eval_str=True.

        Parameters
        ----------
        funcBody : function
            The function whose signature is to be retrieved.

        Returns
        -------
        inspect.Signature
            The signature of the function with annotations properly resolved.
        """
        return inspect.signature(funcBody, eval_str=True)

    @staticmethod
    def _expand_varargs_varkw(
        canonicalized_args: tuple,
        canonicalized_kwargs: dict,
        signature: inspect.Signature,
    ) -> inspect.Signature:
        """
        Expands ``*args`` and ``**kwargs`` into concrete named parameters in the function's signature.

        This is used when a JIT function employs ``*args`` or ``**kwargs``. At the call site,
        concrete values are provided; thus, this method generates explicit parameter names
        so downstream components expecting fixed-arity signatures can function as usual.

        For ``*args``: additional positional arguments beyond those specified in the original
        parameters are given synthetic parameter names such as ``_vararg_0``, ``_vararg_1``, etc.

        For ``**kwargs``: extra keyword arguments beyond those already declared as keyword-only
        in the signature will be appended as new keyword-only parameters.

        Parameters
        ----------
        canonicalized_args : tuple
            The tuple of canonicalized positional arguments as passed to the function.
        canonicalized_kwargs : dict
            The dictionary of canonicalized keyword arguments as passed to the function.
        signature : inspect.Signature
            The function's signature object.

        Returns
        -------
        inspect.Signature
            A new signature with expanded ``*args`` and ``**kwargs`` into named parameters.

        Notes
        -----
        - Positional parameters are expanded first, followed by ``*args``, then keyword-only or default parameters,
          and finally expansion of ``**kwargs``.
        - This allows downstream function argument inspection and manipulation to treat all arguments as if they
          were declared explicitly by name.
        """

        # Signature order
        # positional → *args → keyword-only/default → **kwargs
        new_params = []
        visited_kwonly_args = set()
        for idx, (name, param) in enumerate(signature.parameters.items()):
            if param.kind in (
                inspect.Parameter.POSITIONAL_ONLY,
                inspect.Parameter.POSITIONAL_OR_KEYWORD,
            ):
                new_params.append(param)
            elif param.kind == inspect.Parameter.VAR_POSITIONAL:
                # Expand *args into concrete named parameters
                for vararg_idx in range(idx, len(canonicalized_args)):
                    new_params.append(
                        inspect.Parameter(
                            name=f"_vararg_{vararg_idx}",
                            kind=inspect.Parameter.POSITIONAL_OR_KEYWORD,
                        )
                    )
            elif param.kind == inspect.Parameter.KEYWORD_ONLY:
                new_params.append(param)
                visited_kwonly_args.add(name)
            elif param.kind == inspect.Parameter.VAR_KEYWORD:
                # Expand **kwargs into concrete named parameters
                for kwarg_name in canonicalized_kwargs:
                    if kwarg_name not in visited_kwonly_args:
                        new_params.append(
                            inspect.Parameter(
                                name=kwarg_name,
                                kind=inspect.Parameter.KEYWORD_ONLY,
                            )
                        )
            else:
                raise DSLRuntimeError(f"Invalid parameter kind: {param.kind}")

        return signature.replace(parameters=new_params)

    def _func(self, funcBody: Callable[..., Any], *args: Any, **kwargs: Any) -> Any:
        """Decorator for MLIR functions.
        It cuts the boilerplate code, does the following:
            1. Generates `func.func`
            2. Types translation (numpy arrays -> cute.memref, float -> <f32>, etc.)
            3. Compiles and JITs the MLIR module
            4. Invokes the generated function
            5. Operator overloading (a + b --> arith.addi a, b)
            6. Generates GPU kernel function with GPU module and kernel attributes baked
        """
        if ir.Context.current is None:
            pass
        elif ir.InsertionPoint.current is not None:
            return funcBody(*args, **kwargs)

        function_name = funcBody.__name__
        self.funcBody = funcBody

        pipeline = kwargs.pop("pipeline", None)
        gpu_module_attrs = kwargs.pop("gpu_module_attrs", {})

        # Disable cache
        no_cache = kwargs.pop("no_cache", False)

        # Disable JIT execution engine
        no_jit_engine = kwargs.pop("no_jit_engine", False)

        # Always compile(disable cache) and return the result jit_executor
        compile_only = kwargs.pop("compile_only", False)

        func_name_prefix = kwargs.pop("_name_prefix", None)

        if not no_cache and (
            self.envar.keep_ptx
            or self.envar.keep_cubin
        ):
            no_cache = True
            self.print_warning("Cache is disabled as user wants to generate PTX/ASM.")

        if not no_cache and compile_only:
            no_cache = True
            self.print_warning("Cache is disabled as user wants to compile only.")

        # Get signature of the function
        sig = self._get_signature(funcBody)

        # Get bound arguments
        bound_args = self._get_function_bound_args(sig, function_name, *args, **kwargs)

        # Check the number of arguments
        has_varargs = self._check_arg_count(sig, bound_args, function_name)

        # Canonicalize the input arguments
        canonicalized_args, canonicalized_kwonly_args = self._canonicalize_args(
            bound_args
        )

        # Expand *args/**kwargs into concrete named parameters
        if has_varargs:
            sig = self._expand_varargs_varkw(
                canonicalized_args, canonicalized_kwonly_args, sig
            )
        # Simple name mangling
        function_name = self.mangle_name(function_name, canonicalized_args, sig)
        if func_name_prefix:
            function_name = f"{func_name_prefix}_{function_name}"

        self.compile_options.apply_envar_settings(self.envar, function_name)
        if not self.compile_options.generate_line_info:
            self.decorator_location = None
        # Enable frame filtering if line info is enabled
        _set_enable_frame_filtering(self.compile_options.generate_line_info)

        # Generate MLIR Context and start generating IR
        log().debug(f"Generating MLIR for function '{function_name}'")
        result = self.generate_mlir(
            funcBody,
            function_name,
            gpu_module_attrs,
            canonicalized_args,
            canonicalized_kwonly_args,
            sig,
            pipeline,
            no_cache,
            no_jit_engine,
            compile_only,
            location=self.decorator_location,
        )
        return result

    class _KernelGenHelper(ABC):
        def __init__(self) -> None:
            self.func_op: Any = None
            self.func_type: Any = None

        @abstractmethod
        def generate_func_op(
            self,
            arg_types: list[Any],
            arg_attrs: list[Any],
            kernel_name: str,
            loc: Any = None,
        ) -> Any:
            assert arg_types is not None, "Invalid arg_types!"
            assert kernel_name is not None, "kernel name is empty"
            pass

        @abstractmethod
        def generate_func_ret_op(self) -> None:
            pass

        @abstractmethod
        def generate_launch_op(self, *args: Any, **kwargs: Any) -> Any:
            pass

        @abstractmethod
        def get_func_body_start(self) -> Any:
            pass

    @abstractmethod
    def enter_gpu_module(module: Any) -> Any:
        """Compute the insertion point into the given module."""
        pass

    @lru_cache(maxsize=1)
    def _get_default_stream(self) -> Any:
        """Returns the default stream 0"""
        from .runtime import cuda as cuda_helpers

        return cuda_helpers.stream_create()

    def _execute_cuda(
        self,
        fname_cubin: str,
        kernel_name: str,
        grid_size: Any,
        block_size: Any,
        smem_size: int,
        stream: Any = None,
    ) -> None:
        """
        Executes a specified CUDA kernel from a cubin file, handling module loading,
        kernel retrieval, stream creation, kernel launch, and synchronization.
        """
        from .runtime import cuda as cuda_helpers

        # Step 1. Load CUDA Module
        module = cuda_helpers.load_cubin_module(fname_cubin)
        # Step 2. Find CUDA function
        kernel_ptr = cuda_helpers.get_kernel_function(module, kernel_name)

        sync_execution_default = False
        if stream is None:
            stream = self._get_default_stream()
            sync_execution_default = True

        # Step 4. Launch the kernel
        cuda_helpers.launch_kernel(
            kernel_ptr,
            grid_size,
            block_size,
            stream,
            smem_size=smem_size,
            kernel_args=self.exe_args,
        )

        if sync_execution_default:
            # Step 5. Optional Sync cuda stream
            cuda_helpers.stream_sync(stream)

    def _execute_by_cuda_driver(
        self,
        kernel_generator: Callable[..., Any],
        generate_cubin: Callable[..., str],
        grid_size: Any,
        block_size: Any,
        smem_size: int,
        stream: Any = None,
    ) -> Any:
        """
        This function builds IR and execute the module using cuda driver.
        It doesn't use mlir's cuda runtime
        """
        ret, kernel_name, module = self._generate_kernel_module(kernel_generator)

        # dryrun is used to only generate IR
        if self.envar.dryrun:
            return ret

        # Generate cubin
        fname_cubin = generate_cubin(module, kernel_name)

        # Execute a cuda kernel from cubin
        self._execute_cuda(
            fname_cubin, kernel_name, grid_size, block_size, smem_size, stream
        )

        return ret

    def _generate_kernel_module(
        self, kernel_generator: Callable[..., Any]
    ) -> tuple[Any, str, ir.Module]:
        """
        Generates a module marked as GPU module which contains the kernel generated by :param kernel_generator:.

        :return: A named tuple containing the launch function and function return, the kernel name and the MLIR module.
        """
        ret = None

        with ir.Context(), self.get_ir_location() as loc:
            module = ir.Module.create(loc=loc)
            unit_attr = ir.UnitAttr.get()
            module.operation.attributes["gpu.container_module"] = unit_attr
            with ir.InsertionPoint(module.body):
                self._build_gpu_module({}, loc=loc)
                ret, kernel_name = kernel_generator()
                log().debug(
                    f"Kernel generator returned: ret={ret}, kernel_name={kernel_name}"
                )

        return ret, kernel_name, self.build_module(module, kernel_name)

    def generate_kernel_operands_and_types(
        self,
        kernel_func: Callable[..., Any],
        kernel_name: str,
        signature: inspect.Signature,
        args: tuple[Any, ...],
        kwargs: dict[str, Any],
    ) -> tuple[list[Any], list[Any], list[Any]]:
        """
        Generate the operands and types for the kernel function
        """

        kernel_operands: list[Any] = []
        kernel_arg_types: list[Any] = []
        kernel_arg_attrs: list[Any] = []

        log().debug(
            "Processing GPU kernel call in [%s] mode",
            (
                f"Only {self.device_jit_decorator_name}"
                if self.device_compilation_only
                else f"{self.host_jit_decorator_name} + {self.device_jit_decorator_name}"
            ),
        )

        if self.device_compilation_only:
            return kernel_operands, kernel_arg_types, kernel_arg_attrs

        kernel_operands, kernel_arg_types, kernel_arg_attrs, _ = (
            self._generate_jit_func_args(
                kernel_func, kernel_name, args, kwargs, signature, is_host=False
            )
        )

        log().debug("Final kernel_operands: %s", ", ".join(map(str, kernel_operands)))
        log().debug("Final kernel_arg_types: %s", ", ".join(map(str, kernel_arg_types)))
        log().debug("Final kernel_arg_attrs: %s", ", ".join(map(str, kernel_arg_attrs)))

        assert len(kernel_operands) == len(kernel_arg_types) == len(kernel_arg_attrs), (
            "Size of kernel_operands, kernel_arg_types and kernel_arg_attrs must be equal"
        )

        return kernel_operands, kernel_arg_types, kernel_arg_attrs

    def kernel_launcher(self, *dargs: Any, **dkwargs: Any) -> Any:
        def decorator(funcBody: Callable[..., Any]) -> Callable[..., Any]:
            @wraps(funcBody)
            def kernel_wrapper(*args: Any, **kwargs: Any) -> Any:
                """
                Base decorator for generating kernel function

                This decorator provides a template for kernel function generation
                including kernel function header/body and kernel launch op at call site

                Optional arguments (with default value in <>):
                  - requiredArgs <[]>:      specifies the mandatory arguments that must present in kernel function signature
                                            the args will be validated and collected as a namedtuple
                  - optionalArgs <[]>:      specifies the optional arguments that might present in kernel function signature
                                            the args will be collected (if present) as a namedtuple
                  - unitAttrNames <[]>:     specifies the name(s) of ir.UnitAttr to be set for kernel function op
                  - valueAttrDict <{}>:     specifies the name(s) and value(s) of ir.Attribute to be set for kernel function op
                  - kernelGenHelper <None>: specifies the mandatory customized kernel generation helper class (derived from _KernelGenHelper)

                Return value:
                  A namedtuple "KernelReturns" is returned with following fields:
                  - kernel_func_ret: the return of the kernel function
                  - launch_op_ret:   the return of the launch op
                """

                requiredArgs = dkwargs.get("requiredArgs", [])
                optionalArgs = dkwargs.get("optionalArgs", [])
                unitAttrNames = dkwargs.get("unitAttrNames", [])
                valueAttrDict = dkwargs.get("valueAttrDict", {})
                kernelGenHelper = dkwargs.get("kernelGenHelper", None)

                kernel_name = funcBody.__name__
                signature = self._get_signature(funcBody)
                self.funcBody = funcBody

                # Give each kernel a unique name. (The same kernel may be
                # called multiple times, resulting in multiple kernel traces.)
                # The mangled name of Python function is part of the name to
                # improve readability.
                kernel_name = f"kernel_{self.mangle_name(kernel_name, args, signature)}_{self.num_kernels}"
                if hasattr(self, "_name_prefix") and self._name_prefix:
                    kernel_name = f"{self._name_prefix}_{kernel_name}"
                self.num_kernels += 1

                # Step 0. Preprocess the arguments
                def extract_args(
                    argNames: list[str], assertIfNone: bool = False
                ) -> list[Any]:
                    extracted = []
                    for name in argNames:
                        value = kwargs.pop(name, None)
                        if assertIfNone and value is None:
                            raise DSLRuntimeError(
                                f"{name} is required for {kernel_name}"
                            )
                        extracted.append(value)

                    return extracted

                RequiredArgs = namedtuple("RequiredArgs", requiredArgs)  # type: ignore[misc]
                req_args = (
                    RequiredArgs._make(extract_args(requiredArgs, assertIfNone=True))
                    if requiredArgs
                    else None
                )
                OptionalArgs = namedtuple("OptionalArgs", optionalArgs)  # type: ignore[misc]
                opt_args = (
                    OptionalArgs._make(extract_args(optionalArgs))
                    if optionalArgs
                    else None
                )
                assert kernelGenHelper is not None, (
                    "kernelGenHelper should be explicitly specified!"
                )

                # Get bound arguments
                bound_args = self._get_function_bound_args(
                    signature, kernel_name, *args, **kwargs
                )

                # check arguments
                self._check_arg_count(signature, bound_args, kernel_name)

                # Canonicalize the input arguments
                canonicalized_args, canonicalized_kwargs = self._canonicalize_args(
                    bound_args
                )

                kernel_operands, kernel_types, kernel_arg_attrs = (
                    self.generate_kernel_operands_and_types(
                        funcBody,
                        kernel_name,
                        signature,
                        canonicalized_args,
                        canonicalized_kwargs,
                    )
                )

                loc = self.get_ir_location()
                with self._enter_gpu_module():  # type: ignore[attr-defined]
                    log().debug("Generating device kernel")
                    if self.device_compilation_only:
                        log().debug("Generating cuda-python arguments")
                        # Convert input arguments to MLIR arguments
                        self.exe_args, kernel_types, _ = (
                            self.generate_mlir_function_types(
                                funcBody,
                                kernel_name,
                                canonicalized_args,
                                canonicalized_kwargs,
                                signature,
                            )
                        )

                    helper = kernelGenHelper()
                    fop = helper.generate_func_op(
                        kernel_types, kernel_arg_attrs, kernel_name, loc
                    )
                    log().debug(f"Kernel function op: {fop}")
                    for attr in unitAttrNames:
                        fop.attributes[attr] = ir.UnitAttr.get()
                    for key, val in valueAttrDict.items():
                        fop.attributes[key] = val

                    fop.sym_visibility = ir.StringAttr.get("public")
                    with ir.InsertionPoint(helper.get_func_body_start()):
                        ir_args, ir_kwargs = self.generate_execution_arguments(
                            canonicalized_args, canonicalized_kwargs, fop, signature
                        )
                        log().debug(
                            f"IR arguments - args: {ir_args} ; kwargs: {ir_kwargs}"
                        )

                        kernel_ret = funcBody(*ir_args, **ir_kwargs)
                        if hasattr(helper, "set_kernel_ret"):
                            helper.set_kernel_ret(kernel_ret)
                        helper.generate_func_ret_op()

                # Step 3. Generate call site `launch_func`
                kernel_sym = ir.SymbolRefAttr.get(["kernels", kernel_name])
                setattr(funcBody, "_dsl_kernel_sym", kernel_sym)
                setattr(funcBody, "_dsl_kernel_name", kernel_name)
                launch_ret = helper.generate_launch_op(
                    kernelSym=kernel_sym,
                    kernelOperands=kernel_operands,
                    requiredArgs=req_args,
                    optionalArgs=opt_args,
                    loc=loc,
                )

                KernelReturns = namedtuple(
                    "KernelReturns", ["kernel_func_ret", "launch_op_ret"]
                )
                result = KernelReturns(
                    kernel_func_ret=kernel_ret, launch_op_ret=launch_ret
                )
                log().debug(f"Kernel result: {result}, kernel name: {kernel_name}")
                return result, kernel_name

            return kernel_wrapper

        if len(dargs) == 1 and callable(dargs[0]):
            return decorator(dargs[0])
        else:
            return decorator

    def get_arch_enum(self) -> "Arch":
        """
        Get the arch enum from the environment variable
        """
        from .arch import Arch

        arch_option: str | None = self.compile_options.gpu_arch
        return Arch.from_string(arch_option if arch_option else self.envar.arch)  # type: ignore[arg-type]

    def check_arch(self, criterion: Callable[["Arch"], bool]) -> None:
        """
        Check the arch enum by criterion, raise DSLRuntimeError if the arch enum does not satisfy the criterion
        """
        # Avoid circular dependency
        from .arch import Arch

        arch = self.get_arch_enum()
        if not criterion(arch):
            raise DSLRuntimeError(
                f"invalid arch, expected one of {Arch.filter(criterion)}, but got {arch}.",
                suggestion="Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            )
