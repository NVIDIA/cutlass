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

"""
Foreign Function Interface (FFI) for Base DSL.

This module provides infrastructure for calling external functions from DSL code,
with support for:
- Dynamic type dispatch via ExternCallHandler
- Multiple overload resolution (concrete types, TypeVars, Union types)
- Automatic MLIR prototype generation and caching
- Name mangling for overloaded functions
- Bitcode linking integration
- Implicit type conversions (e.g., ptr address space casts)

Architecture:
- `extern`: Decorator creating ExternCallHandler instances for dynamic dispatch
- ExternCallHandler: Resolves concrete types at call time, creates FFI instances
- FFI: Core class managing MLIR prototypes and call emission
- ConstValue: Represents compile-time constants in type signatures
- BitCode: Specifies external bitcode sources for linking

Usage:
    `@extern`(source=BitCode("mylib.bc"))
    def external_func(x: Int32) -> Float32:
        ...
"""

import typing
from types import UnionType
from typing import TypeVar, Any, Union
import inspect
from dataclasses import dataclass
import string

from .._mlir import ir
from .._mlir.dialects import func, gpu, llvm

from . import typing as t
from .typing import get_mlir_types, NumericMeta, as_numeric
from .dsl import extract_mlir_values
from .common import DSLRuntimeError


@dataclass(frozen=True)
class ConstValue:
    """Represents a constant value and its MLIR types"""

    types: tuple[ir.Type]
    value: Any


@dataclass(frozen=True)
class BitCode:
    """
    Specifies an external bitcode file to link when compiling.

    Attributes:
        path: Filesystem path to the .bc (LLVM bitcode) file.
    """

    path: str


ALLOWED = set(string.ascii_letters + string.digits + "_")


def mangle(name: str) -> str:
    """Mangle a string to be a valid function symbol"""
    return "".join((c if c in ALLOWED else f"_{ord(c):02X}") for c in name)


def to_types(t: Any) -> set[Any]:
    """Convert a generic type to a set of possible types"""
    if typing.get_origin(t) is None:
        return {t}
    if typing.get_origin(t) is UnionType or typing.get_origin(t) is Union:
        return set(typing.get_args(t))
    return {t}


def default_name_mangler(self: "FFI") -> str:
    """Given an ffi object, generate the mangled symbol name. Includes:
    - Function name
    - Types
    - Values of constexprs
    """
    parts = []
    for typ in self.params_types:
        if isinstance(typ, ConstValue):
            parts.append("_".join(mangle(str(x)) for x in typ.types))
            if not isinstance(typ.value.value, int):
                raise DSLRuntimeError(
                    f"constexpr of type {type(typ.value)} not supported for ffi"
                )
            parts.append(mangle(str(typ.value.value)))
        else:
            parts.append(mangle(str(typ)))
    return f"{self.name}_{'_'.join(parts)}"


def type_is_concrete(typ: Any) -> bool:
    """Determine if a type is concrete, i.e. equivalent to a single MLIR type"""
    if isinstance(typ, UnionType):
        return False
    if isinstance(typ, TypeVar):
        return False
    if typing.get_origin(typ) is not None:
        return False
    if hasattr(typ, "mlir_type"):
        return True
    if hasattr(typ, "__get_mlir_types__"):
        return True
    raise DSLRuntimeError(f"cannot determine if type is concrete: {typ}")


def is_concrete(func: Any) -> bool:
    signature = inspect.signature(func)
    params_types = [
        param.annotation if param.annotation is not inspect.Parameter.empty else Any
        for param in signature.parameters.values()
    ]

    if Any in params_types:
        return False

    for typ in params_types:
        if not type_is_concrete(typ):
            return False

    return True


def _arg_to_mlir_types(arg: Any) -> list[Any]:
    """
    Helper method to convert an argument to its corresponding MLIR types.

    This method converts numeric meta types and types convertible via `get_mlir_types`
    to their corresponding MLIR types.
    :param arg: The argument to convert to MLIR types.

    :returns:
        A list of MLIR types.
    :rtype: list
    """
    if isinstance(arg, ir.Type):
        return [arg]
    elif isinstance(arg, NumericMeta):
        return [arg.mlir_type]
    return get_mlir_types(arg)


def _args_to_mlir_types(args: list[Any]) -> list[Any]:
    """
    Helper method to convert an arguments list to its corresponding MLIR types.

    This method converts numeric meta types and types convertible via `get_mlir_types`
    to their corresponding MLIR types.
    :param args: The arguments list to convert to MLIR types.
    :type: list

    :returns:
        A list of MLIR types.
    :rtype: list
    """
    result = []
    for arg in args:
        result.extend(_arg_to_mlir_types(arg))
    return result


class ExternCallHandler:
    """
    Dynamic dispatcher for FFI calls with runtime type resolution.

    Resolves the concrete FFI overload at call time based on argument types.
    Supports:
    - Multiple `@overload` variants
    - TypeVar binding and unification
    - Union type matching (tries each alternative)
    - Constexpr parameters (compile-time constants in signatures)
    - Implicit conversions via custom callback

    Caches FFI instances per concrete type signature to avoid re-creating
    prototypes.
    """

    def __init__(
        self,
        func: Any,
        name: str,
        inline: bool,
        source: BitCode | None,
        name_mangler: Any,
        overloaded: bool | None,
        implicit_convert: Any,
    ) -> None:
        self.func = func
        self.name = name
        self.inline = inline
        self.source = source
        self.name_mangler = name_mangler
        self.ffis: dict[Any, Any] = {}

        self.inited = False
        self.overloads: list[Any] | None = None
        self.overloaded = overloaded
        self.implicit_convert = implicit_convert

    def _init(self) -> None:
        if self.inited:
            return
        self.inited = True

        # Note: don't do this in the constructor as MLIR context doesn't exist yet
        self.overloads = typing.get_overloads(self.func)  # type: ignore[attr-defined]
        assert isinstance(self.overloads, list)
        if len(self.overloads) == 0:
            self.overloads.append(self.func)

        if self.overloaded is None:
            self.overloaded = False
            if len(self.overloads) > 1:
                self.overloaded = True
            elif not is_concrete(self.overloads[0]):
                self.overloaded = True

    def try_match(
        self, args: tuple[Any, ...], overload: Any
    ) -> tuple[bool, list[Any] | None, list[Any] | None]:
        """
        Attempt to match runtime arguments against an overload signature.

        Args:
            args: Runtime argument values
            overload: Function overload to match against

        Returns:
            Tuple (matched: bool, params_types: list | None, return_types: list | None)

        Matching rules:
        - `Any` type always matches
        - TypeVar creates binding on first occurrence, checks equality on subsequent
        - Union types try each alternative
        - Constexpr wraps parameter as ConstValue (compile-time constant)
        - NumericMeta, types with .isinstance(), and Python types checked via isinstance

        Edge cases:
        - Returns (False, None, None) if any parameter fails to match
        - TypeVar bindings are per-call (not cached across calls)
        """
        signature = inspect.signature(overload)
        params_types = [
            param.annotation if param.annotation is not inspect.Parameter.empty else Any
            for param in signature.parameters.values()
        ]
        return_type = (
            signature.return_annotation
            if signature.return_annotation is not inspect.Parameter.empty
            else None
        )

        type_var_mapping = {}
        params_types_info = []

        if len(args) != len(params_types):
            return False, None, None

        for arg, typ in zip(args, params_types):
            # no type always matches, same as a free type variable
            if typ is Any:
                params_types_info.append((_arg_to_mlir_types(arg), arg, False))
                continue

            match = False
            type_set = to_types(typ)
            for typ in type_set:
                is_const_expr = False
                if typing.get_origin(typ) == t.Constexpr:
                    typ = typing.get_args(typ)[0]
                    is_const_expr = True

                if isinstance(typ, NumericMeta):
                    if typ.isinstance(arg):
                        if isinstance(arg, (int, float)):
                            arg = typ(arg)
                        params_types_info.append(
                            (_arg_to_mlir_types(arg), arg, is_const_expr)
                        )
                        match = True
                elif isinstance(typ, TypeVar):
                    if typ not in type_var_mapping:
                        type_var_mapping[typ] = _arg_to_mlir_types(arg)
                        params_types_info.append(
                            (type_var_mapping[typ], arg, is_const_expr)
                        )
                        match = True
                    else:
                        if type_var_mapping[typ] == _arg_to_mlir_types(arg):
                            params_types_info.append(
                                (type_var_mapping[typ], arg, is_const_expr)
                            )
                            match = True
                elif hasattr(typ, "isinstance"):
                    if typ.isinstance(arg):
                        params_types_info.append(
                            (_arg_to_mlir_types(arg), arg, is_const_expr)
                        )
                        match = True
                else:
                    if isinstance(arg, typ):
                        params_types_info.append(
                            (_arg_to_mlir_types(arg), arg, is_const_expr)
                        )
                        match = True
                if match:
                    break

            if not match:
                return False, None, None

        concrete_params_types = []
        for types, arg, is_const_expr in params_types_info:
            if not is_const_expr:
                concrete_params_types.extend(types)
            else:
                concrete_params_types.append(ConstValue(tuple(types), arg))

        if return_type in type_var_mapping:
            concrete_return_types = type_var_mapping[return_type]
        else:
            concrete_return_types = _arg_to_mlir_types(return_type)
        return True, concrete_params_types, concrete_return_types

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        self._init()
        assert self.overloads is not None

        matched = False
        params_types = None
        return_types = None
        for overload in self.overloads:
            result, params_types, return_types = self.try_match(args, overload)
            if result:
                matched = True
                break

        if not matched:
            raise DSLRuntimeError("failed to find matching overload for call to ffi")

        assert params_types is not None
        assert return_types is not None

        if len(return_types) == 1:
            return_type = return_types[0]
        elif len(return_types) == 0:
            return_type = None
        else:
            raise DSLRuntimeError("multiple return types not supported")

        key = tuple(params_types)
        if key not in self.ffis:
            self.ffis[key] = FFI(
                name=self.name,
                overloaded=self.overloaded,  # type: ignore[arg-type]
                params_types=params_types,
                return_type=return_type,
                inline=self.inline,
                source=self.source,
                name_mangler=self.name_mangler,
                implicit_convert=self.implicit_convert,
            )

        return self.ffis[key](*args, **kwargs)


def extern(
    func: Any = None,
    *,
    name: str | None = None,
    inline: bool = True,
    source: BitCode | None = None,
    name_mangler: Any = None,
    overloaded: bool | None = None,
    implicit_convert: Any = None,
) -> Any:
    """
    Decorator to mark a function as an external FFI call.

    Calls to the function dynamically resolve to a concrete extern function based on runtime
    argument types.

    Parameters
    ----------
    name : str, optional
        External symbol name. Defaults to Python function's name.
    inline : bool, default=True
        Whether to mark the function and call sites for inlining.
    source : BitCode, optional
        External bitcode file to link (e.g., BitCode("lib.bc")).
    name_mangler : callable, optional
        Custom name mangling function. Defaults to `default_name_mangler`.
    overloaded : bool, optional
        Whether to enable name mangling. Auto-detected if None (True if multiple
        `@overload` variants or non-concrete signature).
    implicit_convert : callable, optional
        Custom callback for implicit type conversions (signature: (arg, typ) -> arg).

    Returns
    -------
    A callable that dynamically dispatches to the correct FFI overload.

    Examples
    --------
    Basic usage:

    >>> `@extern`
    ... def my_func(x: Int32) -> Float32:
    ...     ...

    With bitcode linking:

    >>> `@extern`(source=BitCode("mylib.bc"))
    ... def external_sqrt(x: Float32) -> Float32:
    ...     ...

    Multiple overloads:

    >>> `@extern`
    ... `@overload`
    ... def compute(x: Int32) -> Int32:
    ...     ...
    >>> `@overload`
    ... def compute(x: Float32) -> Float32:
    ...     ...

    TypeVar-based generic:

    >>> T = TypeVar('T')
    >>> `@extern`
    ... def identity(x: T) -> T:
    ...     ...

    """

    def decorator(func: Any) -> ExternCallHandler:
        return ExternCallHandler(
            func,
            name or func.__name__,
            inline,
            source,
            name_mangler or default_name_mangler,
            overloaded,
            implicit_convert,
        )

    if func is None:
        return decorator
    return decorator(func)


class FFI:
    """
    Foreign Function Interface (FFI) wrapper for external function invocation.

    This class enables calling external MLIR function prototypes from Python code, handling type conversion,
    prototype registration, and dynamic insertion of function symbols into MLIR modules as needed.

    Parameters
    ----------
    name : str
        Name of the external function. This will be used as the symbol name when calling or registering a prototype in the MLIR module.
    params_types : list, optional
        List of argument types for the external function. These can be numeric types, numeric meta types, or types convertible via `get_mlir_types`.
    return_type : optional
        The return type of the external function. If not specified, the function is assumed to have no return value.
    inline : bool
        Whether the prototype in the MLIR module and all calls to it should be marked as inlined. Default is to inline.
    source : optional
        Optional source to link when compiling, that provides the implementation of the function.

    Methods
    -------
    __call__(*args)
        Calls the external function with the given arguments, ensuring argument and result types match the prototype.
    """

    def __init__(
        self,
        *,
        name: str | None,
        params_types: list[Any] | None = None,
        return_type: Any = None,
        inline: bool = True,
        source: Any = None,
        overloaded: bool = False,
        name_mangler: Any = None,
        implicit_convert: Any = None,
    ) -> None:
        self.name = name
        self.params_types = params_types or []
        self.return_type = [return_type] if return_type else []
        self.inline = inline
        self.source = source
        self.overloaded = overloaded
        self.name_mangler = name_mangler or default_name_mangler
        self.implicit_convert = implicit_convert

    def _get_prototype_region(self, current_op: Any) -> tuple[Any, Any]:
        """
        Helper method to determine the appropriate MLIR module and region for inserting a function prototype.

        This method recursively traverses the current operation's parent hierarchy to find the correct module
        and region where the function prototype should be inserted. It supports both builtin.module and gpu.module.
        :param current_op: The current operation to check.
        :type current_op: Operation

        :returns:
            A tuple containing the module operation and the insertion region.
        :rtype: tuple
        """
        if current_op is None:
            raise DSLRuntimeError("current operation is unknown")
        op_name = current_op.name
        if op_name in ["builtin.module", "gpu.module"]:
            return current_op, current_op.regions[0].blocks[0]
        else:
            return self._get_prototype_region(current_op.parent)

    @staticmethod
    def _type_check(
        callee: Any, exec_types: list[Any], returns_types: list[Any]
    ) -> None:
        """
        Helper method to check if the function prototype types match the expected types.

        This method compares the input and output types of the function prototype with the provided expected types.
        :param callee: The function prototype operation to check.
        :type callee: func.FuncOp
        :param exec_types: The expected input types.
        :type exec_types: list
        :param returns_types: The expected output types.
        :type returns_types: list
        """
        if callee.type.inputs != exec_types or callee.type.results != returns_types:
            raise DSLRuntimeError(
                f"External prototype types mismatch, trying to call with ({exec_types}) -> ({returns_types}), got {callee.type}\n{callee}"
            )

    @property
    def full_name(self) -> str | None:
        if not self.overloaded:
            return self.name
        return self.name_mangler(self)

    @property
    def dynamic_params_types(self) -> list[Any]:
        return [x for x in self.params_types if not isinstance(x, ConstValue)]

    def _create_prototype_in_region(
        self, op: Any, region: Any, exec_args: list[Any]
    ) -> Any:
        """
        Helper method to create or retrieve a function prototype in the current module.

        This method checks if a function prototype with the given name already exists in the symbol table of the current module.
        If it does, it checks if the prototype's types match the expected types. If it does not, it raises an error.
        If it does not exist, it creates a new function prototype and inserts it into the current region.
        :param op: The module operation to check.
        :type op: Operation
        :param region: The region to insert the function prototype into.
        :type region: Region
        :param exec_args: The arguments to pass to the function prototype.
        :type exec_args: list
        """
        symbol_table = ir.SymbolTable(op.operation)

        if self.full_name in symbol_table:
            callee = symbol_table[self.full_name]
        else:
            with ir.InsertionPoint(region):
                if self.source is not None and not isinstance(self.source, BitCode):
                    raise DSLRuntimeError(
                        "Linking this kind of source is not supported",
                    )

                if isinstance(self.source, BitCode):
                    # if extern function implementation is in bitcode file,
                    # add it to link-libraries list to be passed to compiler options later
                    sources = set()
                    if "link-libraries" in region.owner.attributes:
                        sources = set(
                            x.value for x in region.owner.attributes["link-libraries"]
                        )
                    sources.add(self.source.path)
                    region.owner.attributes["link-libraries"] = ir.ArrayAttr.get(
                        [ir.StringAttr.get(x) for x in sorted(sources)]
                    )

                callee = func.FuncOp(
                    self.full_name,
                    (
                        _args_to_mlir_types(self.dynamic_params_types),
                        _args_to_mlir_types(self.return_type),
                    ),
                )
                callee.sym_visibility = ir.StringAttr.get("private")
                callee.no_inline = not self.inline

        # Sanity check the function prototype types match the expected types
        self._type_check(
            callee,
            _args_to_mlir_types(exec_args),
            _args_to_mlir_types(self.return_type),
        )

        return callee

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        """
        Calls the FFI function prototype with the provided arguments.

        This method ensures that an IR-level function prototype (external declaration)
        with the given name and type signature exists in the current module. If it does not
        exist, it will be created and inserted into the module. A call operation to this
        function is then emitted using the arguments supplied by the caller.

        :param args:
            The runtime arguments to pass to the FFI function. These will be converted to
            their corresponding numeric types and lowered to MLIR values before being used as arguments.
        :type args: tuple

        :returns:
            The MLIR call operation created for this invocation.
        :rtype: func.CallOp

        :raises DSLRuntimeError:
            If there is no active MLIR insertion point or if the current operation
            context cannot be determined.
        """

        if kwargs:
            raise DSLRuntimeError(
                "Keyword arguments are not supported for FFI calls",
                suggestion="Use positional arguments only",
            )

        # Get the current insertion point and operation
        try:
            current_ip = ir.InsertionPoint.current
        except Exception:
            raise DSLRuntimeError(
                "Failed to determine current insertion point",
                suggestion="Make sure this is called under a jit context",
            )
        current_op = current_ip.block.owner
        module_op, insertion_region = self._get_prototype_region(current_op)

        if len(args) != len(self.params_types):
            raise DSLRuntimeError(
                f"Number of arguments mismatch, expected {len(self.params_types)}, got {len(args)}",
                suggestion="Make sure the number of arguments matches the number of parameters",
            )

        # Extract the arguments to MLIR values
        exec_args = []
        for arg, typ in zip(args, self.params_types):
            if isinstance(typ, ConstValue):
                continue
            exec_arg = extract_mlir_values(arg)
            if not exec_arg:
                exec_arg = [as_numeric(arg).ir_value()]
            exec_arg = self._do_implicit_conversion(exec_arg, _arg_to_mlir_types(typ))
            exec_args.extend(exec_arg)

        # Create the function prototype in module, so if it's under kernel function, prototype will be inserted into gpu.module
        # If it's under gpu.module, prototype will be inserted into builtin.module
        callee = self._create_prototype_in_region(
            module_op, insertion_region, exec_args
        )

        # Emit the call operation
        result = func.call(
            callee.type.results, self.full_name, exec_args, no_inline=not self.inline
        )

        if self.return_type:
            return result

    def _do_implicit_conversion(self, arg: list[Any], typ: list[Any]) -> list[Any]:
        if self.implicit_convert is not None:
            arg = self.implicit_convert(arg, typ)

        if len(arg) == 1 and len(typ) == 1:
            arg_type = arg[0].type
            typ_type = typ[0]
            # implicitly cast !llvm.ptr<n> -> !llvm.ptr<>
            if (
                isinstance(typ_type, llvm.PointerType)
                and isinstance(arg_type, llvm.PointerType)
                and typ_type.address_space != arg_type.address_space
                and typ_type.address_space == 0
            ):
                llvm_ptr_ty = llvm.PointerType.get(0)
                llvm_ptr = llvm.addrspacecast(llvm_ptr_ty, arg[0])
                arg = [llvm_ptr]

        return arg


__all__ = [
    "extern",
    "FFI",
    "BitCode",
    "mangle",
    "ConstValue",
]
