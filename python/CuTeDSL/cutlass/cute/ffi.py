# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from cutlass._mlir import ir
from cutlass._mlir.dialects import func
from cutlass.base_dsl.typing import get_mlir_types, NumericMeta, Numeric, as_numeric
from cutlass.base_dsl.dsl import extract_mlir_values

from cutlass import DSLRuntimeError


class ffi:
    """
    Foreign Function Interface (FFI) wrapper for external function invocation in the CUTLASS Python DSL.

    This class enables calling external MLIR function prototypes from Python code, handling type conversion,
    prototype registration, and dynamic insertion of function symbols into MLIR modules as needed.

    Parameters
    ----------
    name : str
        Name of the external function. This will be used as the symbol name when calling or registering a prototype in the MLIR module.
    params_types : list, optional
        List of argument types for the external function. These can be CUTLASS numeric types, numeric meta types, or types convertible via `get_mlir_types`.
    return_type : optional
        The return type of the external function. If not specified, the function is assumed to have no return value.

    Methods
    -------
    __call__(*args)
        Calls the external function with the given arguments, ensuring argument and result types match the prototype.
    """

    def __init__(self, *, name: str, params_types: list = [], return_type=None):
        self.name = name
        self.params_types = params_types
        self.return_type = [return_type] if return_type else []

    def _get_prototype_region(self, current_op):
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
    def _to_mlir_types(args):
        """
        Helper method to convert a list of arguments to their corresponding MLIR types.

        This method converts CUTLASS numeric types, numeric meta types, and types convertible via `get_mlir_types`
        to their corresponding MLIR types.
        :param args: The list of arguments to convert to MLIR types.
        :type args: list

        :returns:
            A list of MLIR types.
        :rtype: list
        """
        types = []
        for param in args:
            if isinstance(param, NumericMeta):
                types.append(param.mlir_type)
            elif isinstance(param, Numeric):
                types.append(param.mlir_type)
            else:
                types.extend(get_mlir_types(param))
        return types

    @staticmethod
    def _type_check(callee, exec_types, returns_types):
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
                f"External prototype types mismatch, trying to call with ({exec_types}) -> ({returns_types}), got {callee.type}"
            )

    def _create_prototype_in_region(self, op, region, exec_args):
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

        if self.name in symbol_table:
            callee = symbol_table[self.name]
        else:
            with ir.InsertionPoint(region):
                callee = func.FuncOp(
                    self.name,
                    (
                        ffi._to_mlir_types(self.params_types),
                        ffi._to_mlir_types(self.return_type),
                    ),
                )
                callee.sym_visibility = ir.StringAttr.get("private")

        # Sanity check the function prototype types match the expected types
        self._type_check(
            callee,
            ffi._to_mlir_types(exec_args),
            ffi._to_mlir_types(self.return_type),
        )

        return callee

    def __call__(self, *args, **kwargs):
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

        # Extract the arguments to MLIR values
        exec_args = []
        for arg in args:
            exec_arg = extract_mlir_values(arg)
            if not exec_arg:
                exec_arg = [as_numeric(arg).ir_value()]
            exec_args.extend(exec_arg)

        # Create the function prototype in module, so if it's under kernel function, prototype will be inserted into gpu.module
        # If it's under gpu.module, prototype will be inserted into builtin.module
        callee = self._create_prototype_in_region(
            module_op, insertion_region, exec_args
        )

        # Emit the call operation
        result = func.call(callee.type.results, self.name, exec_args)

        if self.return_type:
            return result
