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
import array
import tempfile

from ..common import DSLRuntimeError
from ..jit_executor import JitCompiledFunction, get_escaped_cubin_bytes
from ...base_dsl.dsl import BaseDSL
from ...base_dsl.typing import Int32, Int64, Float32, Float64
from ..._mlir import ir
from ..._mlir.dialects import llvm

from .c_header_generator import CHeaderGenerator

from typing import Union

cubin_suffix = "cubin"

def get_export_module(ir_module: ir.Module, symbol_prefix: str, *, preserve_symbols = None):
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
        elif op.name == "llvm.mlir.addressof" and op.attributes["global_name"].value in defined_symbols:
            op.attributes["global_name"] = ir.FlatSymbolRefAttr.get(
                symbol_prefix + "_" + op.attributes["global_name"].value
            )
        # Rename global_ctors references
        elif op.name == "llvm.mlir.global_ctors" and "ctors" in op.attributes:
            ctors = list(op.attributes["ctors"])
            renamed_ctors = []
            for ctor in ctors:
                if ctor.value in defined_symbols:
                    renamed_ctors.append(ir.FlatSymbolRefAttr.get(
                        symbol_prefix + "_" + ctor.value
                    ))
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
                    renamed_dtors.append(ir.FlatSymbolRefAttr.get(
                        symbol_prefix + "_" + dtor.value
                    ))
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



def dump_to_object(
    prefix_name: str,
    export_module: ir.Module,
    jit_function: Union[JitCompiledFunction, "CudaDialectJitCompiledFunction"],
    dsl: BaseDSL,
    use_gpu_dialect: bool,
) -> bytes:
    """Dump the compiled ir function to a bytes object with ELF format. The bytes object contains the host
    launch entry function and cubin inside.

    @param prefix_name: The prefix name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
    @param export_module: The export module of the function. This is the module that contains the function to be exported.
    @param jit_function: The jit-compiled function. To provided other metadata for the object file.
    @param dsl: The dsl object. This is the dsl object to get the compiler provider and shared libs.
    @return: The bytes object of the function.
    """
    if use_gpu_dialect:
        cubin_data = None

        def strip_gpu_binary_op(op):
            if op.name == "gpu.binary":
                s = io.BytesIO()
                op.operation.write_bytecode(s)
                nonlocal cubin_data
                cubin_data = s.getvalue()
                cubin_data = cubin_data.split(b'bin = "')[1].split(b'">')[0]
                cubin_data = get_escaped_cubin_bytes(cubin_data)
                op.erase()
                return ir.WalkResult.ADVANCE
            return ir.WalkResult.ADVANCE

        # Strip gpu related to avoid the object file generating builtin module load/unload functions
        export_module.operation.walk(strip_gpu_binary_op)

        cubin_array = array.array("b", cubin_data)
        with (
            export_module.context,
            ir.Location.unknown(),
            ir.InsertionPoint(export_module.body),
        ):
            new_binary_global_op = llvm.GlobalOp(
                sym_name="_".join([prefix_name, cubin_suffix]),
                global_type=ir.Type.parse(f"!llvm.array<{len(cubin_array)} x i8>"),
                linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                value=ir.DenseIntElementsAttr.get(cubin_array),
                constant=True,
            )
    if "gpu.container_module" in export_module.operation.attributes:
        del export_module.operation.attributes["gpu.container_module"]
    # Generate the object file
    export_engine = dsl.compiler_provider.jit(
        export_module, shared_libs=dsl.get_shared_libs()
    )
    # This lookup is necessary to make sure the compilation is done.
    entry_func = export_engine.raw_lookup(
        "_".join([prefix_name, jit_function.function_name])
    )
    if not entry_func:
        raise DSLRuntimeError(
            f"Execution engine cannot find the entry function {prefix_name}_{jit_function.function_name}"
        )
    try:
        with tempfile.NamedTemporaryFile() as tmp_object_file:
            export_engine.dump_to_object_file(tmp_object_file.name)
            with open(tmp_object_file.name, "rb") as f:
                ret = f.read()
            return ret
    except Exception as e:
        raise DSLRuntimeError(f"Error dumping object file: {e}") from e


def export_to_c(
    jit_function: Union[JitCompiledFunction, "CudaDialectJitCompiledFunction"],
    file_path: str,
    file_name: str,
    dsl: BaseDSL,
    c_header_generator: CHeaderGenerator,
    use_gpu_dialect: bool,
):
    """Exports the jit-compiled function to a C compatible files(header/library).
    This is used for c/cpp AOT support.
    The `file_name` will be used as the symbol prefix of the generated functions, it is guaranteed by
    the caller that the generated functions are unique. And the function will always overwrite the existing file.


    The c header file is generated with following components:
    1. The host launch entry function. And the structure definitions of the arguments.
    2. The device metadata load/unload functions.
    3. The cubin data array and len.

    The library contains the binary of the underlying host launch entry function.

    @param jit_function: The jit-compiled function from `cute.compile`.
    @param file_path: The path to the directory where the header and object files will be saved.
    @param file_name: The name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
    @param dsl: The dsl object. This is the dsl object to get the compiler provider and shared libs.
    @param c_header_generator: The c header generator. This is the c header generator to generate the c header file.
    """
    export_module = get_export_module(jit_function.ir_module, file_name)
    # Generate the c header file
    header_file_content = c_header_generator(
        file_name,
        export_module,
        jit_function.args_spec,
        jit_function.function_name,
        jit_function.kernel_info,
        jit_function.dynamic_args,
        jit_function.dynamic_kwargs,
        dsl.name,
    )
    try:
        with open(os.path.join(file_path, file_name + ".h"), "w") as f:
            f.write(header_file_content)
    except Exception as e:
        raise DSLRuntimeError(f"Error writing header file: {e}") from e

    # Generate the object file
    object_file_content = dump_to_object(
        file_name,
        export_module,
        jit_function,
        dsl,
        use_gpu_dialect,
    )
    try:
        with open(os.path.join(file_path, file_name + ".o"), "wb") as f:
            f.write(object_file_content)
    except Exception as e:
        raise DSLRuntimeError(f"Error writing object file: {e}") from e


