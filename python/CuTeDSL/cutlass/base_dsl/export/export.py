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

import io
import os

from ..common import DSLRuntimeError
from ..._mlir import ir
from ..._mlir.dialects import llvm

import json
import base64
import ctypes
from inspect import FullArgSpec

args_spec_suffix = "args_spec"
function_name_suffix = "function_name"
kernel_info_suffix = "kernel_info"
version_suffix = "version"
c_string_suffix = "\0"


def get_export_module(
    ir_module: ir.Module, symbol_prefix: str, *, preserve_symbols=None
):
    """Get the export module which is cloned from the original compiled ir module, and add the prefix
    to avoid the symbol conflict.

    @param ir_module: The original compiled ir module. Comes from the JitCompiledFunction.ir_module.
    @param symbol_prefix: The prefix name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
    @param preserve_symbols: Optional symbols to preserve in the export module.
    @return: The export module of the function.
    """
    # Add prefix for symbol names to avoid conflict with other functions
    defined_symbols = set()

    if preserve_symbols is None:
        preserve_symbols = set()

    def walk_llvm_func_op(op):
        # not a declaration
        if (
            op.name == "llvm.func"
            and len(op.opview.operation.regions) > 0
            and len(op.opview.operation.regions[0].blocks) > 0
        ):
            func_name = op.attributes["sym_name"].value
            # skip preserving symbols
            if func_name in preserve_symbols:
                return ir.WalkResult.ADVANCE
            defined_symbols.add(func_name)
            op.attributes["sym_name"] = ir.StringAttr.get(
                symbol_prefix + "_" + func_name
            )
        return ir.WalkResult.ADVANCE

    def walk_llvm_references(op):
        # Rename function calls
        if op.name == "llvm.call" and op.attributes["callee"].value in defined_symbols:
            op.attributes["callee"] = ir.FlatSymbolRefAttr.get(
                symbol_prefix + "_" + op.attributes["callee"].value
            )
        # Rename addressof references
        elif (
            op.name == "llvm.mlir.addressof"
            and op.attributes["global_name"].value in defined_symbols
        ):
            op.attributes["global_name"] = ir.FlatSymbolRefAttr.get(
                symbol_prefix + "_" + op.attributes["global_name"].value
            )
        # Rename global_ctors references
        elif op.name == "llvm.mlir.global_ctors" and "ctors" in op.attributes:
            ctors = list(op.attributes["ctors"])
            renamed_ctors = []
            for ctor in ctors:
                if ctor.value in defined_symbols:
                    renamed_ctors.append(
                        ir.FlatSymbolRefAttr.get(symbol_prefix + "_" + ctor.value)
                    )
                else:
                    renamed_ctors.append(ctor)
            if renamed_ctors:
                op.attributes["ctors"] = ir.ArrayAttr.get(renamed_ctors)
        # Rename global_dtors references
        elif op.name == "llvm.mlir.global_dtors" and "dtors" in op.attributes:
            dtors = list(op.attributes["dtors"])
            renamed_dtors = []
            for dtor in dtors:
                if dtor.value in defined_symbols:
                    renamed_dtors.append(
                        ir.FlatSymbolRefAttr.get(symbol_prefix + "_" + dtor.value)
                    )
                else:
                    renamed_dtors.append(dtor)
            if renamed_dtors:
                op.attributes["dtors"] = ir.ArrayAttr.get(renamed_dtors)
        return ir.WalkResult.ADVANCE

    with ir.Context():
        export_module = ir.Module.parse(str(ir_module))
        # First pass: collect and rename function definitions
        export_module.operation.walk(walk_llvm_func_op)
        # Second pass: rename call and addressof references
        export_module.operation.walk(walk_llvm_references)
    return export_module


class ArgsSpecProcessor:
    """The args spec processor. The args_spec may contain the dsl specific types. The base processor
    class is used to define an interface for dumping and loading the args_spec."""

    def dumps(self, args_spec: FullArgSpec) -> bytes:
        raise NotImplementedError("ArgsSpecProcessor does not support dumps")

    def loads(self, args_spec_bytes: bytes):
        raise NotImplementedError("ArgsSpecProcessor does not support loads")


def encode_metadata_into_ir_module(
    prefix: str,
    ir_module: ir.Module,
    args_spec: FullArgSpec,
    function_name: str,
    kernel_info: dict,
    args_spec_processor: ArgsSpecProcessor,
    object_file_version: str,
):
    """Encode the executor metadata into the ir module. The metadata includes:
    1. args_spec: The args_spec of the python function.
    2. function_name: The name mangling function_name of the python host function.
    3. kernel_info: The kernel_info of the jit-compiled function including the kernel name and attributes.
    4. version: The version of the object file.

    @param prefix: The prefix name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
    @param ir_module: The ir module to encode the metadata into.
    @param args_spec: The args_spec of the python function.
    @param function_name: The name mangling function_name of the python host function.
    @param kernel_info: The kernel_info of the jit-compiled function including the kernel name and attributes.
    @param args_spec_processor: The args spec processor. The args_spec may contain the dsl specific types. The processor will be used to dump and load the args_spec.
    @param object_file_version: The version of the object file.
    """
    if not args_spec:
        raise DSLRuntimeError(
            "args_spec is empty, please set the args_spec for the python jit function."
        )
    version = object_file_version + c_string_suffix

    args_spec_bytes = args_spec_processor.dumps(args_spec)
    args_spec_str = base64.b64encode(args_spec_bytes).decode("utf-8") + c_string_suffix
    packed_function_name = (
        "_mlir_" + prefix + "__mlir_ciface_" + function_name + c_string_suffix
    )
    with ir_module.context, ir.Location.unknown():
        with ir.InsertionPoint(ir_module.body):
            args_spec_op = llvm.GlobalOp(
                sym_name="_".join([prefix, args_spec_suffix]),
                global_type=ir.Type.parse(f"!llvm.array<{len(args_spec_str)} x i8>"),
                linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                value=ir.StringAttr.get(args_spec_str),
            )
            function_name_op = llvm.GlobalOp(
                sym_name="_".join([prefix, function_name_suffix]),
                global_type=ir.Type.parse(
                    f"!llvm.array<{len(packed_function_name)} x i8>"
                ),
                linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                value=ir.StringAttr.get(packed_function_name),
            )
            # pack the kernel_info from a dict to a global op.
            kernel_info = json.dumps(kernel_info) + c_string_suffix
            kernel_info_op = llvm.GlobalOp(
                sym_name="_".join([prefix, kernel_info_suffix]),
                global_type=ir.Type.parse(f"!llvm.array<{len(kernel_info)} x i8>"),
                linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                value=ir.StringAttr.get(kernel_info),
            )
            version_op = llvm.GlobalOp(
                sym_name="_".join([prefix, version_suffix]),
                global_type=ir.Type.parse(f"!llvm.array<{len(version)} x i8>"),
                linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                value=ir.StringAttr.get(version),
            )

    return ir_module


def decode_metadata_from_execution_engine(
    prefix: str,
    execution_engine: "BinaryExecutionEngine",
    args_spec_processor: ArgsSpecProcessor,
):
    """Decode the executor metadata from the execution engine. The metadata includes:
    1. args_spec: The args_spec of the python function.
    2. function_name: The name mangling function_name of the python host function.
    3. kernel_info: The kernel_info of the jit-compiled function including the kernel name and attributes.
    4. version: The version of the object file.

    @param prefix: The prefix name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
    @param execution_engine: The binary execution engine. This is the execution engine to load the cuda module.
    @param args_spec_processor: The args spec processor. The args_spec may contain the dsl specific types. The processor will be used to dump and load the args_spec.
    @return: The args_spec, function_name, and kernel_info.
    """
    args_spec_str_p = execution_engine.lookup("_".join([prefix, args_spec_suffix]))
    function_name_str_p = execution_engine.lookup(
        "_".join([prefix, function_name_suffix])
    )
    kernel_info_str_p = execution_engine.lookup("_".join([prefix, kernel_info_suffix]))
    version_str_p = execution_engine.lookup("_".join([prefix, version_suffix]))
    if args_spec_str_p:
        args_spec_str = ctypes.c_char_p(args_spec_str_p).value.decode("utf-8")
    else:
        args_spec_str = None
    # The StringAttr encodes the string as utf-8 format.
    if function_name_str_p:
        function_name_str = ctypes.c_char_p(function_name_str_p).value.decode("utf-8")
    else:
        function_name_str = None
    if kernel_info_str_p:
        kernel_info_str = ctypes.c_char_p(kernel_info_str_p).value.decode("utf-8")
    else:
        kernel_info_str = None
    if version_str_p:
        version_str = ctypes.c_char_p(version_str_p).value.decode("utf-8")
    else:
        version_str = None
    args_spec_bytes = base64.b64decode(args_spec_str)
    args_spec = args_spec_processor.loads(args_spec_bytes)
    function_name = function_name_str
    kernel_info = json.loads(kernel_info_str)

    return args_spec, function_name, kernel_info, version_str
