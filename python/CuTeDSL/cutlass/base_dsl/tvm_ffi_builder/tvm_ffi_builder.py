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

"""TVM-FFI builder for MLIR code generation."""

from collections.abc import Sequence
from enum import IntEnum
from typing import Callable, Optional, Union

try:
    import tvm_ffi
except ModuleNotFoundError:
    pass

from . import spec
from ..._mlir import ir
from ..._mlir.dialects import llvm
from .mlir_builder import MLIRBuilder
from dataclasses import dataclass


@dataclass
class ArgContext:
    """Context information for parameter decoding error messages.

    :ivar param_name: The name of the parameter.
    :vartype param_name: str
    :ivar arg_index: The index of the argument in the function call.
    :vartype arg_index: int
    :ivar tuple_indices: List of tuple indices for nested tuple access (e.g., [0, 1] for tuple[0][1]).
    :vartype tuple_indices: list[int]
    """
    param_name: str
    arg_index: int
    tuple_indices: list[int]

    def get(self) -> list[str]:
        """Get the context as a list of strings for error messages.

        :returns: Context strings like ["on argument ", "#0"] or ["on my_tuple[0][1] in argument ", "#0"].
        :rtype: list[str]
        """
        if not self.tuple_indices:
            # Top-level argument: "on argument #0"
            return ["on argument ", f"#{self.arg_index}"]
        else:
            # Nested tuple element: "on my_tuple[0][1] in argument #0"
            indices_str = "".join(f"[{i}]" for i in self.tuple_indices)
            return [f"on {self.param_name}{indices_str} in argument ", f"#{self.arg_index}"]

    def get_field_name(self, field_suffix: str) -> str:
        """Get the field name with tuple indices for shape/stride access.

        :param field_suffix: The field suffix (e.g., ".shape", ".strides").
        :type field_suffix: str
        :returns: Field name like "my_param.shape" or "my_tuple[0][1].shape".
        :rtype: str
        """
        if not self.tuple_indices:
            return f"{self.param_name}{field_suffix}"
        else:
            indices_str = "".join(f"[{i}]" for i in self.tuple_indices)
            return f"{self.param_name}{indices_str}{field_suffix}"

    def get_element_context(self, element_index: int) -> "ArgContext":
        """Create a nested context for a tuple element.

        :param element_index: The index within the tuple.
        :type element_index: int
        :returns: New context for the nested element.
        :rtype: ArgContext
        """
        return ArgContext(
            param_name=self.param_name,
            arg_index=self.arg_index,
            tuple_indices=self.tuple_indices + [element_index],
        )


@dataclass
class CallContext:
    """Call context that contains the information of the call."""

    # the function name
    fn_name: str
    # the module
    module: ir.Module
    # the function operation
    # can be used to insert llvm.alloca at beginning via
    # `with ir.InsertionPoint(entry_block.operations[0]):`
    entry_block: ir.Block
    # the parameters of the call
    params: list[spec.Param]
    # the current working stream through environment synced
    # with stream set in caller framework's stream context
    # this is queried by the tensor device type and id
    # useful for APIs where stream is not explicitly passed in
    env_stream: Optional[ir.Value]
    # the matched var binding
    matched_var_binding: dict[spec.Var, ir.Value]
    # raw arguments
    raw_args: list[ir.Value]
    # arg index
    raw_num_args: ir.Value
    # result
    raw_result: ir.Value
    # Keep a handle to the TVMFFIFunctionBuilder when building this context,
    # so call providers can access the builder to emit globals
    # (strings, helpers) in the same module as the call context.
    builder: Optional["TVMFFIFunctionBuilder"] = None


class CallProvider:
    """Call provider that implements a specific calling convention."""

    def __call__(self, current_block: ir.Block, context: CallContext) -> ir.Block:
        """Call the call provider.

        Parameters
        ----------
        current_block: ir.Block
            The current block to emit the call.

        context: CallContext
            The call context that contains the related information of the call.

        Returns
        -------
        ir.Block
            The new updated current block if any.
        """
        raise NotImplementedError("Call provider not implemented")


class TVMFFITypeIndex(IntEnum):
    """TVM-FFI type index, follow the same style as C naming for now."""

    kTVMFFINone = 0
    kTVMFFIInt = 1
    kTVMFFIBool = 2
    kTVMFFIFloat = 3
    kTVMFFIOpaquePtr = 4
    kTVMFFIDataType = 5
    kTVMFFIDevice = 6
    kTVMFFIDLTensorPtr = 7
    kTVMFFIRawStr = 8
    kTVMFFIByteArrayPtr = 9
    kTVMFFIObjectRValueRef = 10
    kTVMFFISmallStr = 11
    kTVMFFISmallBytes = 12
    kTVMFFIStaticObjectBegin = 64
    kTVMFFIObject = 64
    kTVMFFIStr = 65
    kTVMFFIBytes = 66
    kTVMFFIError = 67
    kTVMFFIFunction = 68
    kTVMFFIShape = 69
    kTVMFFITensor = 70
    kTVMFFIArray = 71
    kTVMFFIMap = 72
    kTVMFFIModule = 73
    kTVMFFIOpaquePyObject = 74


class TVMFFIBuilder(MLIRBuilder):
    """Base builder that provides common data structure related manipulations."""

    def __init__(self) -> None:
        super().__init__()
        # this is a number we can tune to minimize the register size
        # it is 6 by default to minimize the register size
        self.set_raised_from_cstr_parts_max_num_parts = 8
        self.set_raised_from_cstr_parts_cache: dict[int, str] = {}
        self.tvm_ffi_any_type = self.struct_type(
            name="TVMFFIAny",
            fields=[
                # type_index: i32
                self.i32_type,
                # padding: i32
                self.i32_type,
                # v_int64: i64
                self.i64_type,
            ],
        )
        self.tvm_ffi_object_type = self.struct_type(
            name="TVMFFIObject",
            fields=[
                # combined_ref_count: i64
                self.i64_type,
                # type_index: i32
                self.i32_type,
                # padding: i32
                self.i32_type,
                # deleter: i64 (use i64 to ensure 64-bit alignment)
                self.i64_type,
                # cell: i64 (this is a placeholder so we can get ptr of cell)
                self.i64_type,
            ],
        )
        self.dl_device_type = self.struct_type(
            name="DLDevice",
            fields=[
                # device_type: i32 (DLDeviceType enum)
                self.i32_type,
                # device_id: i32
                self.i32_type,
            ],
        )
        # DLDataType: {code: i8, bits: i8, lanes: i16}
        self.dl_data_type = self.struct_type(
            name="DLDataType",
            fields=[
                # code: i8 (DLDataTypeCode enum)
                self.i8_type,
                # bits: i8
                self.i8_type,
                # lanes: i16
                self.i16_type,
            ],
        )
        self.dltensor_type = self.struct_type(
            name="DLTensor",
            fields=[
                # 0 - data: void*
                self.ptr_type,
                # 1 - device: DLDevice
                self.dl_device_type,
                # 2 - ndim: i32
                self.i32_type,
                # 3 - dtype: DLDataType
                self.dl_data_type,
                # 4 - shape: i64*
                self.ptr_type,
                # 5 - strides: i64*
                self.ptr_type,
                # 6 - byte_offset: i64
                self.i64_type,
            ],
        )
        self.tvm_ffi_shape_cell_type = self.struct_type(
            name="TVMFFIShapeCell",
            fields=[
                # shape: i64*
                self.ptr_type,
                # size: usize -- we use ptr type as it is same as usize
                # we can load ptr then use ptrtoint to get usize
                self.ptr_type,
            ],
        )
        self.tvm_ffi_array_cell_type = self.struct_type(
            name="TVMFFIArrayCell",
            fields=[
                # data: void*
                self.ptr_type,
                # size: i64
                self.i64_type,
            ],
        )
        self.tvm_ffi_func_type = self.func_type(
            ret=self.i32_type,
            params=[self.ptr_type, self.ptr_type, self.i32_type, self.ptr_type],
        )

    def get_object_cell_ptr(self, obj: ir.Value) -> ir.Value:
        """Get the cell from the tvm_ffi_object struct.

        Parameters
        ----------
        obj : ir.Value
            The object ptr

        Returns
        -------
        ir.Value
            The pointer to the cell following the object header.

        """
        return self.getelementptr(
            obj,
            [0, 4],
            elem_type=self.tvm_ffi_object_type,
        )

    def load_ffi_any_array_item_type_index(self, args: ir.Value, index: int) -> ir.Value:
        """Get the type index from the index-th field of tvm_ffi_any_type struct.

        Semantics as follows:

        .. code-block:: c
            int32_t get_type_index(void* args, const int index) {
                return ((TVMFFIAny*)args)[index].type_index;
            }

        Parameters
        ----------
        args : ir.Value
            The args pointer.
        index : int
            The index of the args array.

        Returns
        -------
        ir.Value
            The type index.

        """
        # Single GEP: args[index].type_index
        # Indices: [index, 0] = access index-th element, then first field
        type_index_ptr = self.getelementptr(
            args,
            [index, 0],
            elem_type=self.tvm_ffi_any_type,
        )
        return llvm.load(self.i32_type, type_index_ptr)

    def load_ffi_any_array_item_v_int64(
        self,
        args: ir.Value,
        index: int
    ) -> ir.Value:
        """Get the v_int64 from the index-th field of tvm_ffi_any_type struct.

        Semantics as follows:

        .. code-block:: c

            int64_t get_v_int64(void* args, const int index) {
                return ((TVMFFIAny*)args)[index].v_int64;
            }
        """
        v_int64_ptr = self.getelementptr(
            args,
            [index, 2],
            elem_type=self.tvm_ffi_any_type,
        )
        return llvm.load(self.i64_type, v_int64_ptr)

    def load_ffi_any_array_item_v_float64(self, args: ir.Value, index: int) -> ir.Value:
        """Get the v_float64 from the index-th field of tvm_ffi_any_type struct.

        Semantics as follows:

        .. code-block:: c

            double get_v_float64(void* args, const int index) {
                return ((TVMFFIAny*)args)[index].v_float64;
            }
        """
        v_float64_ptr = self.getelementptr(
            args,
            [index, 2],
            elem_type=self.tvm_ffi_any_type,
        )
        return llvm.load(self.f64_type, v_float64_ptr)

    def load_ffi_any_array_item_v_ptr(
        self,
        args: ir.Value,
        index: int,
        address_space: Optional[int] = None
    ) -> ir.Value:
        """Get the v_ptr from the index-th field of tvm_ffi_any_type struct.

        Semantics as follows:

        .. code-block:: c

            void* get_v_ptr(void* args, const int index) {
                return ((TVMFFIAny*)args)[index].v_ptr;
            }
        """
        v_ptr_ptr = self.getelementptr(
            args,
            [index, 2],
            elem_type=self.tvm_ffi_any_type,
        )
        ptr_type = self.ptr_type_with_address_space(address_space)
        return llvm.load(ptr_type, v_ptr_ptr)

    def load_shape_cell_data_ptr(self, shape_cell: ir.Value) -> ir.Value:
        """Get the data pointer from the shape cell."""
        data_ptr = self.getelementptr(
            shape_cell,
            [0, 0],
            elem_type=self.tvm_ffi_shape_cell_type,
        )
        return llvm.load(self.ptr_type, data_ptr)

    def load_shape_cell_size_as_i64(self, shape_cell: ir.Value) -> ir.Value:
        """Get the size from the shape cell as i64."""
        size_ptr = self.getelementptr(
            shape_cell,
            [0, 1],
            elem_type=self.tvm_ffi_shape_cell_type,
        )
        size_as_ptr_type = llvm.load(self.ptr_type, size_ptr)
        return llvm.ptrtoint(self.i64_type, size_as_ptr_type)

    def load_array_cell_data_ptr(self, array_cell: ir.Value) -> ir.Value:
        """Get the data pointer from the array cell."""
        data_ptr = self.getelementptr(
            array_cell,
            [0, 0],
            elem_type=self.tvm_ffi_array_cell_type,
        )
        return llvm.load(self.ptr_type, data_ptr)

    def load_array_cell_size_as_i64(self, array_cell: ir.Value) -> ir.Value:
        """Get the size from the array cell as i64."""
        size_ptr = self.getelementptr(
            array_cell,
            [0, 1],
            elem_type=self.tvm_ffi_array_cell_type,
        )
        return llvm.load(self.i64_type, size_ptr)

    def load_i64_array_item(self, data: ir.Value, index: int) -> ir.Value:
        """Load a shape value at the given index from the shape pointer."""
        # Get pointer to the specific shape element at index
        shape_elem_ptr = self.getelementptr(
            data,
            [index],
            elem_type=self.i64_type,
        )
        # Load the actual strides value
        return llvm.load(self.i64_type, shape_elem_ptr)

    def load_dltensor_data_ptr(self, dltensor: ir.Value) -> ir.Value:
        """Get the data pointer from the DLTensor struct."""
        # Get pointer to the data field (first field at index 0)
        data_ptr = self.getelementptr(
            dltensor,
            [0, 0],
            elem_type=self.dltensor_type,
        )
        # Load the actual data pointer
        return llvm.load(self.ptr_type, data_ptr)

    def load_dltensor_device_type(self, dltensor: ir.Value) -> ir.Value:
        """Get the device type from the DLTensor struct."""
        # Get pointer to the device_type field (device at index 1, then device_type at index 0)
        device_type_ptr = self.getelementptr(
            dltensor,
            [0, 1, 0],
            elem_type=self.dltensor_type,
        )
        # Load the actual device type value
        return llvm.load(self.i32_type, device_type_ptr)

    def load_dltensor_device_id(self, dltensor: ir.Value) -> ir.Value:
        """Get the device id from the DLTensor struct."""
        # Get pointer to the device_id field (device field at index 1, then device_id at index 1)
        device_id_ptr = self.getelementptr(
            dltensor,
            [0, 1, 1],
            elem_type=self.dltensor_type,
        )
        # Load the actual device id value
        return llvm.load(self.i32_type, device_id_ptr)

    def load_dltensor_dtype_code(self, dltensor: ir.Value) -> ir.Value:
        """Get the dtype code from the DLTensor struct."""
        # Get pointer to the dtype code field (dtype field at index 3, then code at index 0)
        dtype_code_ptr = self.getelementptr(
            dltensor,
            [0, 3, 0],
            elem_type=self.dltensor_type,
        )
        # Load the actual dtype code value
        return llvm.load(self.i8_type, dtype_code_ptr)

    def load_dltensor_dtype_bits(self, dltensor: ir.Value) -> ir.Value:
        """Get the dtype bits from the DLTensor struct."""
        # Get pointer to the dtype bits field (dtype field at index 3, then bits at index 1)
        dtype_bits_ptr = self.getelementptr(
            dltensor,
            [0, 3, 1],
            elem_type=self.dltensor_type,
        )
        # Load the actual dtype bits value
        return llvm.load(self.i8_type, dtype_bits_ptr)

    def load_dltensor_dtype_lanes(self, dltensor: ir.Value) -> ir.Value:
        """Get the dtype lanes from the DLTensor struct."""
        # Get pointer to the dtype lanes field (dtype field at index 3, then lanes at index 2)
        dtype_lanes_ptr = self.getelementptr(
            dltensor,
            [0, 3, 2],
            elem_type=self.dltensor_type,
        )
        # Load the actual dtype lanes value
        return llvm.load(self.i16_type, dtype_lanes_ptr)

    def load_dltensor_ndim(self, dltensor: ir.Value) -> ir.Value:
        """Get the number of dimensions from the DLTensor struct."""
        # Get pointer to the ndim field (third field at index 2)
        ndim_ptr = self.getelementptr(
            dltensor,
            [0, 2],
            elem_type=self.dltensor_type,
        )
        # Load the actual ndim value
        return llvm.load(self.i32_type, ndim_ptr)

    def load_dltensor_shape(self, dltensor: ir.Value) -> ir.Value:
        """Get the shape value at the given index from the DLTensor struct."""
        # Get pointer to the shape array (fifth field at index 4)
        shape_ptr = self.getelementptr(
            dltensor,
            [0, 4],
            elem_type=self.dltensor_type,
        )
        return llvm.load(self.ptr_type, shape_ptr)

    def load_dltensor_strides(self, dltensor: ir.Value) -> ir.Value:
        """Get the strides value at the given index from the DLTensor struct."""
        # Get pointer to the strides array (sixth field at index 5)
        strides_ptr = self.getelementptr(
            dltensor,
            [0, 5],
            elem_type=self.dltensor_type,
        )
        return llvm.load(self.ptr_type, strides_ptr)

    def load_dltensor_byte_offset(self, dltensor: ir.Value) -> ir.Value:
        """Get the byte offset from the DLTensor struct."""
        # Get pointer to the byte_offset field (seventh field at index 6)
        byte_offset_ptr = self.getelementptr(
            dltensor,
            [0, 6],
            elem_type=self.dltensor_type,
        )
        # Load the actual byte offset value
        return llvm.load(self.i64_type, byte_offset_ptr)

    def downcast_i64_to_lower_bits(
        self, v_int64: ir.Value, target_dtype: "tvm_ffi.dtype"
    ) -> ir.Value:
        """Downcast i64 to lower bits."""
        overflow_flags = llvm.IntegerOverflowFlags.none
        if (hasattr(tvm_ffi._dtype.DataTypeCode, "BOOL") and
            target_dtype.type_code == tvm_ffi._dtype.DataTypeCode.BOOL):
            # LLVM use i1 (boolean) for boolean
            return llvm.icmp(llvm.ICmpPredicate.ne, v_int64, self.i64(0))
        if target_dtype.bits == 64:
            return v_int64
        if target_dtype.bits == 32:
            return llvm.trunc(
                res=self.i32_type, arg=v_int64, overflow_flags=overflow_flags
            )
        if target_dtype.bits == 16:
            return llvm.trunc(
                res=self.i16_type, arg=v_int64, overflow_flags=overflow_flags
            )
        if target_dtype.bits == 8:
            return llvm.trunc(
                res=self.i8_type, arg=v_int64, overflow_flags=overflow_flags
            )
        if target_dtype.bits == 1:
            # For i1 (boolean), convert i64 to boolean by checking if non-zero
            return llvm.icmp(llvm.ICmpPredicate.ne, v_int64, self.i64(0))
        raise ValueError(f"Unsupported Var dtype: {target_dtype}")

    def is_contiguous(
        self,
        expected_shape: list[Union[spec.Var, int]],
        loaded_shape: list[ir.Value],
        loaded_strides: list[ir.Value],
    ) -> ir.Value:
        """Check if the DLTensor is contiguous."""
        expected_stride: Union[int, ir.Value] = 1
        cond: ir.Value = self.i1(1)

        for index in reversed(range(len(loaded_shape))):
            # strides[i] == expected_stride or shape[i] == 1
            # still constant
            if isinstance(expected_stride, int):
                stride_cond = self.equal(
                    loaded_strides[index], self.i64(expected_stride)
                )
            else:
                stride_cond = self.equal(loaded_strides[index], expected_stride)

            cond = self.and_(
                cond,
                self.or_(
                    stride_cond,
                    self.equal(loaded_shape[index], self.i64(1)),
                ),
            )
            if index > 0:
                # try to stay in constant compute as much as possible
                if isinstance(expected_shape[index], int) and isinstance(
                    expected_stride, int
                ):
                    expected_stride = (
                        expected_shape[index] * expected_stride  # type: ignore[operator]
                    )
                else:
                    if isinstance(expected_stride, int):
                        expected_stride = self.i64(expected_stride)
                    # Handle case where expected_shape[index] might be a Var
                    if isinstance(expected_shape[index], int):
                        shape_as_i64 = self.i64(expected_shape[index])  # type: ignore[arg-type]
                        expected_stride = self.mul(shape_as_i64, expected_stride)
                    else:
                        # expected_shape[index] is a spec.Var, use loaded_shape[index]
                        expected_stride = self.mul(loaded_shape[index], expected_stride)
        return cond

    def get_or_create_set_raised_from_cstr_parts(self, num_parts: int) -> str:
        r"""Get or create a helper function to call TVMFFIErrorSetRaisedFromCStrParts.

        The expected generated function is as follows:

        .. code-block:: c

            void __tvm_ffi__set_error_from_parts_n(
                const char* kind,
                int32_t num_actual_parts,
                const char* p0,
                const char* p1,
                ...
                const char* pN-1
            ) {
                const char* message_parts[n];
                message_parts[0] = p0;
                message_parts[1] = p1;
                ...
                message_parts[n-1] = pN-1;
                TVMFFIErrorSetRaisedFromCStrParts(kind, message_parts, num_actual_parts);
            }

        Parameters
        ----------
        num_parts : int
            The number of string parts needed.

        Returns
        -------
        str
            The name of the helper function.

        """
        # Check cache first
        if num_parts in self.set_raised_from_cstr_parts_cache:
            return self.set_raised_from_cstr_parts_cache[num_parts]

        helper_name = f"__tvm_ffi__set_error_from_parts_{num_parts}"

        # Check if function already exists in the module
        if self.find_func_in_module(self.module, helper_name):
            self.set_raised_from_cstr_parts_cache[num_parts] = helper_name
            return helper_name

        # Build the parameter list: kind, num_actual_parts, p0, p1, ..., pN-1
        param_types = [self.ptr_type]  # kind
        param_types.append(self.i32_type)  # num_actual_parts
        for _ in range(num_parts):
            param_types.append(self.ptr_type)  # p0, p1, ..., pN-1

        # Create the helper function
        with ir.InsertionPoint(self.module.body):  # type: ignore[union-attr]
            params, entry_block = self.function(
                name=helper_name,
                params_type=param_types,
                ret_type=self.void_type,
                internal=True,
            )

            kind_param = params[0]
            num_actual_parts_param = params[1]
            part_params = params[2:]

            with ir.InsertionPoint(entry_block):
                # Allocate array of pointers to hold the message parts
                message_parts_array = llvm.alloca(
                    res=self.ptr_type,
                    elem_type=self.ptr_type,
                    array_size=self.i32(num_parts),
                    alignment=8,
                )

                # Store each part in the array
                for i, part_param in enumerate(part_params):
                    part_ptr = self.getelementptr(
                        message_parts_array,
                        [i],
                        elem_type=self.ptr_type,
                    )
                    llvm.store(value=part_param, addr=part_ptr)

                # Call TVMFFIErrorSetRaisedFromCStrParts(kind, message_parts, num_actual_parts)
                llvm.call(
                    result=None,
                    callee="TVMFFIErrorSetRaisedFromCStrParts",
                    callee_operands=[
                        kind_param,
                        message_parts_array,
                        num_actual_parts_param,
                    ],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )

                # Return void
                self.return_()

        self.set_raised_from_cstr_parts_cache[num_parts] = helper_name
        return helper_name

    def raise_error_and_return(
        self, error_kind: str, error_message_parts: list[Union[str, ir.Value]]
    ) -> None:
        """Raise an error and return -1.

        Instead of concatenating parts at compile time, we define each part as a global string
        and call a helper function that passes them to TVMFFIErrorSetRaisedFromCStrParts.
        This allows better string deduplication across the codebase.
        """
        error_kind_symbol = self.define_global_string(content=error_kind)

        # Calculate actual_num_parts (max(self.set_raised_from_cstr_parts_max_num_parts, num_parts))
        call_num_parts = max(
            self.set_raised_from_cstr_parts_max_num_parts, len(error_message_parts)
        )

        # Get or create the helper function for this number of parts
        helper_name = self.get_or_create_set_raised_from_cstr_parts(
            num_parts=call_num_parts
        )

        # Build the call operands: kind, num_actual_parts, p0, p1, ..., pN-1, (nulls...)
        call_operands = [self.address_of(error_kind_symbol, self.ptr_type)]
        call_operands.append(self.i32(len(error_message_parts)))  # num_actual_parts

        # Add non-null part pointers
        # Define global strings for each part, or forward ir.Values directly
        for part in error_message_parts:
            if isinstance(part, str):
                part_symbol = self.define_global_string(content=part)
                call_operands.append(self.address_of(part_symbol, self.ptr_type))
            else:
                call_operands.append(part)

        # Pad with null pointers for unused slots
        # Create null pointer constant once and reuse it
        if call_num_parts > len(error_message_parts):
            null_ptr = llvm.inttoptr(self.ptr_type, self.i64(0))
            for _ in range(call_num_parts - len(error_message_parts)):
                call_operands.append(null_ptr)

        # Call the helper function
        llvm.call(
            result=None,
            callee=helper_name,
            callee_operands=call_operands,
            op_bundle_sizes=[],
            op_bundle_operands=[],
        )

        self.return_(self.i32(-1))

    def check_condition(
        self,
        current_block: ir.Block,
        fcond: Callable[[], ir.Value],
        error_kind: str,
        error_message_parts: list[str],
    ) -> ir.Block:
        """Check a condition and throw an error if false.

        Parameters
        ----------
        current_block : ir.Block
            The current block.
        fcond : Callable[[], ir.Value]
            Function that returns the condition to check.
        error_kind : str
            The kind of the error.
        error_message_parts : list[str]
            The message of the error.

        Returns
        -------
        ir.Block
            The continuation block.

        """
        error_block = current_block.create_after()
        subsequent_block = error_block.create_after()
        with ir.InsertionPoint(current_block):
            self.cond_br(
                cond=fcond(),
                true_block=subsequent_block,
                false_block=error_block,
                # likely to be true
                branch_weights=self.BRANCH_WEIGHTS_LIKELY
            )
        with ir.InsertionPoint(error_block):
            self.raise_error_and_return(error_kind, error_message_parts)
        return subsequent_block


class TVMFFIFunctionBuilder(TVMFFIBuilder):
    """Builder that contains specific logic for function parameters decoding."""

    module: ir.Module
    current_fn_signature: str
    _fn_call_context: str
    matched_var_binding: dict[spec.Var, ir.Value]
    matched_var_source: dict[spec.Var, ir.Value]
    matched_var_arg_field_name: dict[spec.Var, str]

    def __init__(self, module: ir.Module) -> None:
        super().__init__()
        self.module = module
        self.current_fn_signature: str = ""
        self._fn_call_context: str = ""
        self.matched_var_binding = {}
        self.matched_var_source = {}
        self.matched_var_arg_field_name = {}

    def find_or_declare_extern_func(
        self, name: str, params: Sequence[ir.Type], ret: ir.Type
    ) -> None:
        """Find an existing extern function or declare it if it doesn't exist.

        This method checks if a function with the given name already exists in the module.
        If it does, the method returns without doing anything. Otherwise, it declares
        the function as an external function.

        Parameters
        ----------
        name : str
            The name of the extern function.
        params : Sequence[ir.Type]
            The parameter types of the function.
        ret : ir.Type
            The return type of the function.
        """
        # Check if the function already exists
        existing_func = self.find_func_in_module(self.module, name)
        if existing_func is not None:
            # Function already declared, nothing to do
            return

        # Function doesn't exist, declare it
        self.declare_extern_func(name, params, ret)

    def decode_param_int(
        self,
        current_block: ir.Block,
        param: spec.Var,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the integer parameter at the given index."""
        # read the type index
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            # Check if type is int or bool (both use v_int64, bool can be converted to int)
            is_int = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIInt))
            is_bool = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIBool))
            is_int_or_bool = self.or_(is_int, is_bool)

        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: is_int_or_bool,
            "TypeError",
            [
                "Mismatched type ",
                *arg_context.get(),
                self._fn_call_context,
                ", expected int",
            ],
        )
        with ir.InsertionPoint(current_block):
            v_int64: ir.Value = self.load_ffi_any_array_item_v_int64(args, arg_index)
            if param.dtype.lanes != 1:
                raise ValueError(f"Unsupported Var dtype: {param.dtype}")

        return self.set_or_check_matched_var_binding(
            current_block,
            param,
            v_int64,
            [
                "value ",
                *arg_context.get(),
                self._fn_call_context,
            ],
            arg_context.get_field_name(""),
        )

    def decode_param_float(
        self,
        current_block: ir.Block,
        param: spec.Var,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the float parameter at the given index."""
        # read the type index
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            # Check if type is float, int, or bool (int and bool can be converted to float)
            is_float = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIFloat))
            is_int = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIInt))
            is_bool = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIBool))
            is_int_or_bool = self.or_(is_int, is_bool)

        if param.dtype.lanes != 1:
            raise ValueError(f"Unsupported Var dtype: {param.dtype}")

        # Determine result type
        if param.dtype.bits == 64:
            result_type = self.f64_type
        elif param.dtype.bits == 32:
            result_type = self.f32_type
        else:
            raise ValueError(f"Unsupported Var dtype: {param.dtype}")

        # Create all blocks in the control flow
        error_block = current_block.create_after()
        float_block = error_block.create_after()
        int_bool_check_block = float_block.create_after()
        int_bool_block = int_bool_check_block.create_after()
        result_block = int_bool_block.create_after()

        # Add block arguments to the result block
        result_block.add_argument(result_type, ir.Location.unknown())

        # Branch directly to float or int/bool check
        with ir.InsertionPoint(current_block):
            # First check if it's float
            self.cond_br(
                cond=is_float,
                true_block=float_block,
                false_block=int_bool_check_block,
            )

        # Handle float type
        with ir.InsertionPoint(float_block):
            v_float64: ir.Value = self.load_ffi_any_array_item_v_float64(args, arg_index)
            if param.dtype.bits == 64:
                float_result = v_float64
            elif param.dtype.bits == 32:
                float_result = llvm.fptrunc(res=self.f32_type, arg=v_float64)
            else:
                raise ValueError(f"Unsupported Var dtype: {param.dtype}")
            self.br(result_block, args=[float_result])

        # In int/bool check block, verify it's actually int or bool
        with ir.InsertionPoint(int_bool_check_block):
            self.cond_br(
                cond=is_int_or_bool,
                true_block=int_bool_block,
                false_block=error_block,
                branch_weights=self.BRANCH_WEIGHTS_LIKELY,
            )

        # Handle int or bool type (convert to float)
        with ir.InsertionPoint(int_bool_block):
            v_int64: ir.Value = self.load_ffi_any_array_item_v_int64(args, arg_index)
            # Convert int64 to float64 first, then to target type
            v_float64_from_int = llvm.sitofp(res=self.f64_type, arg=v_int64)
            if param.dtype.bits == 64:
                int_bool_result = v_float64_from_int
            elif param.dtype.bits == 32:
                int_bool_result = llvm.fptrunc(
                    res=self.f32_type, arg=v_float64_from_int
                )
            else:
                raise ValueError(f"Unsupported Var dtype: {param.dtype}")
            self.br(result_block, args=[int_bool_result])

        # Error block
        with ir.InsertionPoint(error_block):
            # Break error message into reusable parts for better string deduplication
            self.raise_error_and_return(
                "TypeError",
                [
                    "Mismatched type ",
                    *arg_context.get(),
                    self._fn_call_context,
                    ", expected float",
                ],
            )

        # Merge the results using block argument
        with ir.InsertionPoint(result_block):
            result = result_block.arguments[0]
            self.matched_var_binding[param] = result
            self.matched_var_source[param] = v_float64
            self.matched_var_arg_field_name[param] = arg_context.get_field_name("")

        return result_block

    def decode_param_opaque_handle(
        self,
        current_block: ir.Block,
        param: spec.Var,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
        *,
        allow_int_as_ptr: bool = False,
        address_space: Optional[int] = None,
    ) -> ir.Block:
        """Decode the opaque handle parameter at the given index."""
        # read the type index
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            # Check if type is opaque pointer
            is_opaque_ptr = self.equal(
                type_index, self.i32(TVMFFITypeIndex.kTVMFFIOpaquePtr)
            )
            # Check if type is a nullptr
            is_nullptr = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFINone))
            is_opaque_ptr_or_nullptr = self.or_(is_opaque_ptr, is_nullptr)
            if allow_int_as_ptr:
                is_int = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIInt))
                is_opaque_ptr_or_nullptr = self.or_(is_opaque_ptr_or_nullptr, is_int)

        expect_message = ", expected handle"
        if allow_int_as_ptr:
            expect_message += " or int"

        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: is_opaque_ptr_or_nullptr,
            "TypeError",
            [
                "Mismatched type ",
                *arg_context.get(),
                self._fn_call_context,
                expect_message,
            ],
        )

        with ir.InsertionPoint(current_block):
            # Load the opaque handle (v_ptr field contains the void*)
            v_ptr: ir.Value = self.load_ffi_any_array_item_v_ptr(
                args, arg_index, address_space=address_space
            )
            # For opaque handles, we store the pointer directly
            self.matched_var_binding[param] = v_ptr
            self.matched_var_source[param] = v_ptr
            self.matched_var_arg_field_name[param] = arg_context.get_field_name("")

        return current_block

    def decode_param_const_none(
        self,
        current_block: ir.Block,
        param: spec.ConstNone,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the opaque handle parameter at the given index."""
        # read the type index
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            # Check if type is a nullptr
            is_nullptr = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFINone))

        expect_message = ", expected None"

        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: is_nullptr,
            "TypeError",
            [
                "Mismatched type ",
                *arg_context.get(),
                self._fn_call_context,
                expect_message,
            ],
        )
        return current_block

    def check_int_value_dtype_bound(
        self,
        current_block: ir.Block,
        value: ir.Value,
        dtype: "tvm_ffi.dtype",
        error_msg_context: list[str],
    ) -> ir.Block:
        """Check if the value is within the bounds."""
        if dtype.bits == 64:
            # skip check for 64-bit integers
            return current_block

        from tvm_ffi._dtype import DataTypeCode
        is_uint = dtype.type_code == DataTypeCode.UINT

        # compute out the upper and lower bounds
        if is_uint:
            lower_bound = 0
            upper_bound = (1 << dtype.bits) - 1
        else:
            lower_bound = -(1 << (dtype.bits - 1))
            upper_bound = (1 << (dtype.bits - 1)) - 1

        error_msg = [
            "Out of bound ",
            *error_msg_context,
            f", expected to be in {str(dtype)} range [{lower_bound}, {upper_bound}]"
        ]

        # Check bounds using appropriate comparison predicates
        with ir.InsertionPoint(current_block):
            lower_bound_value = self.i64(lower_bound)
            upper_bound_value = self.i64(upper_bound)
            if is_uint:
                is_above_lower = llvm.icmp(llvm.ICmpPredicate.uge, value, lower_bound_value)
                is_below_upper = llvm.icmp(llvm.ICmpPredicate.ule, value, upper_bound_value)
            else:
                is_above_lower = llvm.icmp(llvm.ICmpPredicate.sge, value, lower_bound_value)
                is_below_upper = llvm.icmp(llvm.ICmpPredicate.sle, value, upper_bound_value)

            in_bounds = self.and_(is_above_lower, is_below_upper)

        return self.check_condition(
            current_block,
            lambda: in_bounds,
            "ValueError",
            error_msg
        )

    def check_int_value_divisibility(
        self,
        current_block: ir.Block,
        value: ir.Value,
        divisibility: int,
        error_msg_context: list[str],
        *,
        skip_check_predicate: Optional[ir.Value] = None,
    ) -> ir.Block:
        """Check if the value is divisible by the specified divisibility.

        Parameters
        ----------
        current_block : ir.Block
            The current block to insert checks into.
        value : ir.Value
            The i64 value to check.
        divisibility : int
            The divisibility constraint.
        error_msg_context : list[str]
            Context for error messages.
        skip_check_predicate : Optional[ir.Value], optional
            The predicate to skip checking

        Returns
        -------
        ir.Block
            The updated block after checks.
        """
        def check_divisibility() -> ir.Value:
            cond = self.i64_divisible_const(value, divisibility)
            if skip_check_predicate is not None:
                cond = self.or_(skip_check_predicate, cond)
            return cond

        error_msg = [
            "Invalid ",
            *error_msg_context,
            f", expected to be divisible by {divisibility}"
        ]

        return self.check_condition(
            current_block,
            check_divisibility,
            "ValueError",
            error_msg
        )

    def set_or_check_matched_var_binding(
        self,
        current_block: ir.Block,
        var: Union[spec.Var, int],
        value: ir.Value,
        error_msg_context: list[str],
        arg_field_name: str,
        *,
        skip_check_predicate: Optional[ir.Value] = None,
        skip_cast_and_check: bool = False,
    ) -> ir.Block:
        """Set or check the matched var binding."""
        error_kind = "ValueError"
        expected_value: ir.Value
        error_prefix_mismatch = "Mismatched "

        if isinstance(var, spec.Var):
            # if var contains llvm_value and is not populated, populate it
            if var not in self.matched_var_binding:
                if not skip_cast_and_check:
                    current_block = self.check_int_value_dtype_bound(
                        current_block, value, var.dtype, error_msg_context
                    )
                    # check divisibility if specified
                    if var.divisibility is not None:
                        current_block = self.check_int_value_divisibility(
                            current_block, value, var.divisibility, error_msg_context,
                            skip_check_predicate=skip_check_predicate,
                        )
                    # store the source value with parameter info
                    with ir.InsertionPoint(current_block):
                        target_value = self.downcast_i64_to_lower_bits(
                            value, var.dtype
                        )
                else:
                    target_value = value
                # store the source value
                self.matched_var_source[var] = value
                # store the target value (casted to target dtype aleady)
                self.matched_var_binding[var] = target_value
                # store arg_field_name
                self.matched_var_arg_field_name[var] = arg_field_name
                return current_block
            # otherwise, it appears more than once, we need to check if the value matches
            expected_value = self.matched_var_source[var]
            prev_arg_field_name = self.matched_var_arg_field_name[var]
            error_msg_mismatch = [
                error_prefix_mismatch,
                *error_msg_context,
                f", expected to match {prev_arg_field_name}",
            ]
        else:
            assert isinstance(var, int)
            with ir.InsertionPoint(current_block):
                if not skip_cast_and_check:
                    expected_value = self.i64(var)
                else:
                    expected_value = self.downcast_i64_to_lower_bits(
                        self.i64(var), var.dtype
                    )

            error_msg_mismatch = [
                error_prefix_mismatch,
                *error_msg_context,
                f", expected to be {var}"
            ]

        def check_value_mismatch() -> ir.Value:
            cond = self.equal(value, expected_value)
            if skip_check_predicate is not None:
                cond = self.or_(skip_check_predicate, cond)
            return cond

        return self.check_condition(
            current_block,
            check_value_mismatch,
            error_kind,
            error_msg_mismatch
        )

    def set_or_check_matched_var_binding_from_shape(
        self,
        current_block: ir.Block,
        var: Union[spec.Var, int],
        value: ir.Value,
        field_suffix: str,
        shape_index: int,
        arg_context: ArgContext,
        *,
        skip_check_predicate: Optional[ir.Value] = None,
    ) -> ir.Block:
        """Load the shape value from the argument or match the shape value from the parameter."""
        field_name = arg_context.get_field_name(field_suffix)
        arg_field_name = f"{field_name}[{shape_index}]"
        error_msg = [
            field_name,
            f"[{shape_index}] ",
            *arg_context.get(),
            self._fn_call_context,
        ]
        return self.set_or_check_matched_var_binding(
            current_block, var, value, error_msg, arg_field_name,
            skip_check_predicate=skip_check_predicate
        )

    def decode_param_shape_from_ffi_array(
        self,
        current_block: ir.Block,
        param: spec.Shape,
        arg_context: ArgContext,
        array_cell: ir.Value,
    ) -> tuple[ir.Block, list[ir.Value]]:
        """Decode the shape parameter from the TVMFFIArrayCell."""
        with ir.InsertionPoint(current_block):
            array_data = self.load_array_cell_data_ptr(array_cell)
            array_size = self.load_array_cell_size_as_i64(array_cell)

        # Check that the array size matches the expected shape size
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(array_size, self.i64(len(param.shape))),
            "ValueError",
            [
                "Mismatched Shape ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected shape size={len(param.shape)}",
            ],
        )

        # Load and validate each element of the array
        load_shapes = []

        def validate_and_load_shape_element(
            block: ir.Block, index: int
        ) -> tuple[ir.Block, ir.Value]:
            """Validate and load a single shape element from the array."""
            with ir.InsertionPoint(block):
                type_index: ir.Value = self.load_ffi_any_array_item_type_index(array_data, index)
                # Check if type is int or bool (both use v_int64, bool can be converted to int)
                is_int_val = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIInt))

            # Check that the element is an integer
            field_name = arg_context.get_field_name("")
            block = self.check_condition(
                block,
                lambda: is_int_val,
                "TypeError",
                [
                    "Invalid shape element type ",
                    f"{field_name}[{index}]",
                    " ",
                    *arg_context.get(),
                    self._fn_call_context,
                    ", expected int",
                ],
            )

            with ir.InsertionPoint(block):
                v_int64: ir.Value = self.load_ffi_any_array_item_v_int64(array_data, index)

            return block, v_int64

        for i in range(len(param.shape)):
            current_block, v_int64 = validate_and_load_shape_element(current_block, i)
            load_shapes.append(v_int64)

        return (current_block, load_shapes)

    def decode_param_shape_from_ffi_shape(
        self,
        current_block: ir.Block,
        param: spec.Shape,
        arg_context: ArgContext,
        shape_cell: ir.Value,
    ) -> tuple[ir.Block, list[ir.Value]]:
        """Decode the shape parameter from the TVMFFIShapeCell."""
        with ir.InsertionPoint(current_block):
            shape_data = self.load_shape_cell_data_ptr(shape_cell)
            shape_size = self.load_shape_cell_size_as_i64(shape_cell)

        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(shape_size, self.i64(len(param.shape))),
            "ValueError",
            [
                "Mismatched Shape ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected shape size={len(param.shape)}",
            ],
        )

        with ir.InsertionPoint(current_block):
            load_shapes = [self.load_i64_array_item(shape_data, i) for i in range(len(param.shape))]

        return (current_block, load_shapes)

    def decode_param_shape(
        self,
        current_block: ir.Block,
        param: spec.Shape,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the shape parameter at the given index."""
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            # Check if type is ffi.Shape or ffi.Array
            is_ffi_shape = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIShape))
            is_ffi_array = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIArray))

        # Create error block and subsequent blocks
        error_block = current_block.create_after()
        ffi_shape_block = error_block.create_after()
        ffi_array_check_block = ffi_shape_block.create_after()
        ffi_array_block = ffi_array_check_block.create_after()
        # Create subsequent_block with i64 arguments for each shape dimension
        subsequent_block = ffi_array_block.create_after(*[self.i64_type] * len(param.shape))

        # Branch from current_block: check FFI shape first
        with ir.InsertionPoint(current_block):
            self.cond_br(is_ffi_shape, ffi_shape_block, ffi_array_check_block)

        # ffi shape block
        with ir.InsertionPoint(ffi_shape_block):
            shape_cell = self.get_object_cell_ptr(
                self.load_ffi_any_array_item_v_ptr(args, arg_index)
            )
        ffi_shape_block, load_shapes = self.decode_param_shape_from_ffi_shape(
            ffi_shape_block, param, arg_context, shape_cell
        )
        with ir.InsertionPoint(ffi_shape_block):
            self.br(subsequent_block, args=load_shapes)

        # ffi array check block: verify it's actually an Array
        with ir.InsertionPoint(ffi_array_check_block):
            self.cond_br(
                is_ffi_array, ffi_array_block, error_block,
                branch_weights=self.BRANCH_WEIGHTS_LIKELY
            )

        # ffi array block
        with ir.InsertionPoint(ffi_array_block):
            array_cell_ptr = self.get_object_cell_ptr(
                self.load_ffi_any_array_item_v_ptr(args, arg_index)
                )
        ffi_array_block, load_shapes = self.decode_param_shape_from_ffi_array(
            ffi_array_block, param, arg_context, array_cell_ptr
        )
        with ir.InsertionPoint(ffi_array_block):
            self.br(subsequent_block, args=load_shapes)

        # error block
        with ir.InsertionPoint(error_block):
            # Break error message into reusable parts for better string deduplication
            self.raise_error_and_return(
                "TypeError",
                [
                    "Mismatched type ",
                    *arg_context.get(),
                    self._fn_call_context,
                    ", expected ffi.Shape or ffi.Array",
                ],
            )

        # Set or check the matched variable bindings for each dimension
        with ir.InsertionPoint(subsequent_block):
            shape_values = list(subsequent_block.arguments)
            for i, dim in enumerate(param.shape):
                subsequent_block = self.set_or_check_matched_var_binding_from_shape(
                    subsequent_block, dim, shape_values[i], "", i, arg_context
                )

        return subsequent_block

    def decode_param_tensor_dltensor_ptr(
        self,
        current_block: ir.Block,
        param: spec.Tensor,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> tuple[ir.Block, ir.Value]:
        """Decode tensor step0: check index and find out DLTensor*."""
        # read the type index
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            is_ffi_tensor = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFITensor))
            is_dl_tensor = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIDLTensorPtr))

        # Create error block and subsequent block
        error_block = current_block.create_after()
        ffi_tensor_block = error_block.create_after()
        dl_tensor_check_block = ffi_tensor_block.create_after()
        dl_tensor_block = dl_tensor_check_block.create_after()
        subsequent_block = dl_tensor_block.create_after(self.ptr_type)

        # Branch from current_block: check FFI tensor first
        with ir.InsertionPoint(current_block):
            self.cond_br(is_ffi_tensor, ffi_tensor_block, dl_tensor_check_block)

        # ffi tensor block
        with ir.InsertionPoint(ffi_tensor_block):
            ffi_tensor_ptr: ir.Value = self.load_ffi_any_array_item_v_ptr(args, arg_index)
            dl_tensor_ptr = self.get_object_cell_ptr(ffi_tensor_ptr)
            self.br(subsequent_block, args=[dl_tensor_ptr])

        # dltensor check block: verify it's actually a DLTensor
        with ir.InsertionPoint(dl_tensor_check_block):
            self.cond_br(
                is_dl_tensor, dl_tensor_block, error_block,
                branch_weights=self.BRANCH_WEIGHTS_LIKELY
            )

        # dltensor block
        with ir.InsertionPoint(dl_tensor_block):
            dltensor_ptr: ir.Value = self.load_ffi_any_array_item_v_ptr(args, arg_index)
            self.br(subsequent_block, args=[dltensor_ptr])

        # error block
        with ir.InsertionPoint(error_block):
            # Break error message into reusable parts for better string deduplication
            self.raise_error_and_return(
                "TypeError",
                [
                    "Mismatched type ",
                    *arg_context.get(),
                    self._fn_call_context,
                    ", expected Tensor",
                ],
            )

        # subsequent block: receive DLTensor pointer and set it to parameter
        with ir.InsertionPoint(subsequent_block):
            dl_tensor_ptr = subsequent_block.arguments[0]

        return (subsequent_block, dl_tensor_ptr)

    def decode_param_tensor(
        self,
        current_block: ir.Block,
        param: spec.Tensor,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the tensor parameter at the given index."""
        current_block, dl_tensor_ptr = self.decode_param_tensor_dltensor_ptr(
            current_block, param, args, arg_index, arg_context
        )
        with ir.InsertionPoint(current_block):
            data = self.load_dltensor_data_ptr(dl_tensor_ptr)
            dtype_code = self.load_dltensor_dtype_code(dl_tensor_ptr)
            dtype_bits = self.load_dltensor_dtype_bits(dl_tensor_ptr)
            dtype_lanes = self.load_dltensor_dtype_lanes(dl_tensor_ptr)
            device_type = self.load_dltensor_device_type(dl_tensor_ptr)
            device_id = self.load_dltensor_device_id(dl_tensor_ptr)
            ndim = self.load_dltensor_ndim(dl_tensor_ptr)
            byte_offset = self.load_dltensor_byte_offset(dl_tensor_ptr)

        # check data alignment if specified
        if param.data_alignment is not None:
            def check_alignment() -> ir.Value:
                # Convert pointer to integer
                data_as_int = llvm.ptrtoint(self.i64_type, data)
                # Check if data pointer is divisible by alignment
                # (uses fast path for power-of-two alignments)
                return self.i64_divisible_const(data_as_int, param.data_alignment)

            current_block = self.check_condition(
                current_block,
                check_alignment,
                "ValueError",
                [
                    "Misaligned Tensor data ",
                    *arg_context.get(),
                    self._fn_call_context,
                    f", expected data alignment={param.data_alignment} bytes",
                ],
            )

        # store the matched values, these do not need constraint checks
        self.matched_var_binding[param.data] = data
        self.matched_var_source[param.data] = param.data
        self.matched_var_arg_field_name[param.data] = arg_context.get_field_name(".data")

        # check device_id constraint if user specifies a device_id variable
        current_block = self.set_or_check_matched_var_binding(
            current_block,
            param.device_id,
            device_id,
            [
                "device index ",
                *arg_context.get(),
                self._fn_call_context,
            ],
            arg_context.get_field_name(".device.index"),
            skip_cast_and_check=True,
        )

        # check ndim
        expected_ndim = len(param.shape)
        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(ndim, self.i32(expected_ndim)),
            "ValueError",
            [
                "Mismatched Tensor ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected ndim={expected_ndim}",
            ],
        )
        # check device_type
        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(device_type, self.i32(param.dlpack_device_type)),
            "ValueError",
            [
                "Mismatched Tensor ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected device_type={param.device_type_name}",
            ],
        )

        # check dtype
        def dtype_equal() -> ir.Value:
            # check dtype (code, bits, lanes)
            dtype_code_match = self.equal(dtype_code, self.i8(param.dtype.type_code))
            dtype_bits_match = self.equal(dtype_bits, self.i8(param.dtype.bits))
            dtype_lanes_match = self.equal(dtype_lanes, self.i16(param.dtype.lanes))
            return self.and_(
                dtype_code_match, self.and_(dtype_bits_match, dtype_lanes_match)
            )

        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            dtype_equal,
            "ValueError",
            [
                "Mismatched Tensor ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected dtype={param.dtype}",
            ],
        )
        # check byte_offset
        # Break error message into reusable parts for better string deduplication
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(byte_offset, self.i64(0)),
            "ValueError",
            [
                "Mismatched Tensor ",
                *arg_context.get(),
                self._fn_call_context,
                ", expected byte_offset=0",
            ],
        )

        with ir.InsertionPoint(current_block):
            shape = self.load_dltensor_shape(dl_tensor_ptr)
            load_shapes = [
                self.load_i64_array_item(shape, index) for index in range(expected_ndim)
            ]
            strides = self.load_dltensor_strides(dl_tensor_ptr)
            load_strides = [
                self.load_i64_array_item(strides, index)
                for index in range(expected_ndim)
            ]

        # check the shapes
        for index in range(expected_ndim):
            current_block = self.set_or_check_matched_var_binding_from_shape(
                current_block,
                param.shape[index],
                load_shapes[index],
                ".shape",
                index,
                arg_context,
            )

        if param.strides is not None:
            for index in range(expected_ndim):
                # if shape[index] == 1 then, stride value constraint does not matter
                # this is specifically to avoid some corner cases where pytorch normalizes
                # stride value to 1 when shape[index] == 1
                with ir.InsertionPoint(current_block):
                    skip_check_predicate = self.equal(load_shapes[index], self.i64(1))
                current_block = self.set_or_check_matched_var_binding_from_shape(
                    current_block,
                    param.strides[index],
                    load_strides[index],
                    ".strides",
                    index,
                    arg_context,
                    skip_check_predicate=skip_check_predicate,
                )
        else:
            # Break error message into reusable parts for better string deduplication
            current_block = self.check_condition(
                current_block,
                lambda: self.is_contiguous(param.shape, load_shapes, load_strides),
                "ValueError",
                [
                    "Mismatched Tensor ",
                    *arg_context.get(),
                    self._fn_call_context,
                    ", expected contiguous",
                ],
            )
        return current_block

    def decode_param_stream(
        self,
        current_block: ir.Block,
        param: spec.Stream,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the stream parameter at the given index."""
        # stream is decoded as opaque handle
        return self.decode_param_opaque_handle(
            current_block, param.var, args, arg_index, arg_context,
            allow_int_as_ptr=True
        )

    def decode_param_data_pointer(
        self,
        current_block: ir.Block,
        param: spec.DataPointer,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the data pointer parameter at the given index."""
        # data pointer is decoded as opaque handle
        return self.decode_param_opaque_handle(
            current_block,
            param.var,
            args,
            arg_index,
            arg_context,
            allow_int_as_ptr=True,
            address_space=param.address_space,
        )

    def find_env_stream(self, params: list[spec.Param]) -> Optional[ir.Value]:
        """Find the working stream from the environment Tensor that is not CPU.

        Parameters
        ----------
        params : list[spec.Param]
            The parameters to find the working stream from.

        Returns
        -------
        Optional[ir.Value]
            The working stream.
        """
        for param in params:
            if (
                isinstance(param, spec.Tensor)
                and param.dlpack_device_type != tvm_ffi.DLDeviceType.kDLCPU
            ):
                device_type = self.i32(param.dlpack_device_type)
                device_id = self.matched_var_binding[param.device_id]
                return llvm.call(
                    result=self.ptr_type,
                    callee="TVMFFIEnvGetStream",
                    callee_operands=[device_type, device_id],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )
        return None

    def get_expected_num_args(self, params: list[spec.Param]) -> int:
        """Get the expected number of arguments."""
        expected_num_args = 0
        for param in params:
            if not isinstance(param, spec.EnvStream):
                expected_num_args += 1
        return expected_num_args

    def decode_param_tuple(
        self,
        current_block: ir.Block,
        param: spec.TupleParam,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the tuple parameter at the given index."""
        # Check if type is kTVMFFIArray
        with ir.InsertionPoint(current_block):
            type_index: ir.Value = self.load_ffi_any_array_item_type_index(args, arg_index)
            is_ffi_array = self.equal(type_index, self.i32(TVMFFITypeIndex.kTVMFFIArray))

        # Check that the type is an array
        current_block = self.check_condition(
            current_block,
            lambda: is_ffi_array,
            "TypeError",
            [
                "Mismatched type ",
                *arg_context.get(),
                self._fn_call_context,
                ", expected ffi.Array for tuple",
            ],
        )

        # Load the array cell
        with ir.InsertionPoint(current_block):
            array_cell_ptr = self.get_object_cell_ptr(
                self.load_ffi_any_array_item_v_ptr(args, arg_index)
            )
            array_data = self.load_array_cell_data_ptr(array_cell_ptr)
            array_size = self.load_array_cell_size_as_i64(array_cell_ptr)

        # Check that the array size matches the expected tuple size
        current_block = self.check_condition(
            current_block,
            lambda: self.equal(array_size, self.i64(len(param.params))),
            "ValueError",
            [
                "Mismatched tuple size ",
                *arg_context.get(),
                self._fn_call_context,
                f", expected tuple size={len(param.params)}",
            ],
        )

        # Recursively decode each element of the tuple
        for i, tuple_param in enumerate(param.params):
            # Create nested context for the tuple element
            nested_context = arg_context.get_element_context(i)
            current_block = self.decode_param(current_block, tuple_param, array_data, i, nested_context)

        return current_block

    def decode_param(  # noqa: PLR0911
        self,
        current_block: ir.Block,
        param: spec.Param,
        args: ir.Value,
        arg_index: int,
        arg_context: ArgContext,
    ) -> ir.Block:
        """Decode the parameter at the given index.

        Parameters
        ----------
        current_block : ir.Block
            The current IR block.
        param : spec.Param
            The parameter specification to decode.
        args : ir.Value
            The FFI arguments array.
        arg_index : int
            The index in the args array.
        arg_context : ArgContext
            Context information for error messages.
        """
        if isinstance(param, spec.Var):
            if param.dtype.type_code == tvm_ffi._dtype.DataTypeCode.INT:
                return self.decode_param_int(current_block, param, args, arg_index, arg_context)
            elif param.dtype.type_code == tvm_ffi._dtype.DataTypeCode.UINT:
                # UINT uses the same logic as INT since both are stored in v_int64
                return self.decode_param_int(current_block, param, args, arg_index, arg_context)
            elif (hasattr(tvm_ffi._dtype.DataTypeCode, "BOOL") and
                  param.dtype.type_code == tvm_ffi._dtype.DataTypeCode.BOOL):
                return self.decode_param_int(current_block, param, args, arg_index, arg_context)
            elif param.dtype.type_code == tvm_ffi._dtype.DataTypeCode.FLOAT:
                return self.decode_param_float(current_block, param, args, arg_index, arg_context)
            elif param.dtype.type_code == tvm_ffi._dtype.DataTypeCode.HANDLE:
                return self.decode_param_opaque_handle(
                    current_block, param, args, arg_index, arg_context
                )
            else:
                raise ValueError(f"Unsupported parameter type: {param.dtype.type_code}")
        elif isinstance(param, spec.Shape):
            return self.decode_param_shape(current_block, param, args, arg_index, arg_context)
        elif isinstance(param, spec.Tensor):
            return self.decode_param_tensor(current_block, param, args, arg_index, arg_context)
        elif isinstance(param, spec.Stream):
            return self.decode_param_stream(current_block, param, args, arg_index, arg_context)
        elif isinstance(param, spec.EnvStream):
            # decode of env stream is deferred after we go through all parameters
            return current_block
        elif isinstance(param, spec.DataPointer):
            return self.decode_param_data_pointer(current_block, param, args, arg_index, arg_context)
        elif isinstance(param, spec.ConstNone):
            return self.decode_param_const_none(current_block, param, args, arg_index, arg_context)
        elif isinstance(param, spec.TupleParam):
            return self.decode_param_tuple(current_block, param, args, arg_index, arg_context)
        else:
            raise ValueError(f"Unsupported parameter type: {type(param)}")

    def setup_env_stream_params(
        self,
        current_block: ir.Block,
        params: list[spec.Param],
        env_stream: Optional[ir.Value],
    ) -> ir.Block:
        """Setup the env stream parameter."""
        for param in params:
            if isinstance(param, spec.EnvStream):
                if env_stream is None:
                    raise ValueError(
                        f"EnvStream cannot be detected in `{self.current_fn_signature}`"
                        " we need parameters to contain GPU Tensors"
                    )
                self.matched_var_binding[param.var] = env_stream
                self.matched_var_source[param.var] = env_stream
                self.matched_var_arg_field_name[param.var] = param.name

        return current_block

    def attach_ffi_func(
        self,
        symbol_name: str,
        params: Sequence[spec.Param],
        call_provider: CallProvider,
        fn_display_name: Optional[str] = None,
    ) -> None:
        """Add a LLVM function to the current MLIR module with the given `tvm_ffi_func_name`."""
        params_list: list[spec.Param] = list(params)
        # Generate the helper function to set the error from cstr parts
        self.get_or_create_set_raised_from_cstr_parts(
            num_parts=self.set_raised_from_cstr_parts_max_num_parts
        )
        fn_display_name = (
            fn_display_name if fn_display_name is not None else symbol_name
        )
        # Generate signature for error messages
        self.current_fn_signature = spec.signature(fn_display_name, params_list)
        self._fn_call_context = f" when calling: `{self.current_fn_signature}`"

        with ir.InsertionPoint(self.module.body):  # type: ignore[union-attr]
            # void TVMFFIErrorSetRaisedFromCStr(
            #    const char* error_kind, const char* message);
            self.find_or_declare_extern_func(
                "TVMFFIErrorSetRaisedFromCStr",
                [self.ptr_type, self.ptr_type],
                self.void_type,
            )
            # void TVMFFIErrorSetRaisedFromCStrParts(
            #    const char* error_kind, const char* messages, int32_t num_parts);
            self.find_or_declare_extern_func(
                "TVMFFIErrorSetRaisedFromCStrParts",
                [self.ptr_type, self.ptr_type, self.i32_type],
                self.void_type,
            )
            # void* TVMFFIEnvGetStream(int32_t device_type, int32_t device_id);
            self.find_or_declare_extern_func(
                "TVMFFIEnvGetStream",
                [self.i32_type, self.i32_type],
                self.ptr_type,
            )

            (handle, args, num_args, result), entry_block = self.function(
                name=f"__tvm_ffi_{symbol_name}",
                params_type=[
                    self.ptr_type,
                    self.ptr_type,
                    self.i32_type,
                    self.ptr_type,
                ],
                ret_type=self.i32_type,
            )
            expected_num_args = self.get_expected_num_args(params_list)

            # Break error message into reusable parts for better string deduplication
            current_block = entry_block
            current_block = self.check_condition(
                current_block,
                lambda: self.equal(num_args, self.i32(expected_num_args)),
                "TypeError",
                [
                    f"Expects {expected_num_args} parameters",
                    self._fn_call_context,
                ],
            )

            # decode parameters to populate the matched var binding
            for arg_index, param in enumerate(params_list):
                arg_context = ArgContext(
                    param_name=param.name,
                    arg_index=arg_index,
                    tuple_indices=[],
                )
                current_block = self.decode_param(current_block, param, args, arg_index, arg_context)

            with ir.InsertionPoint(current_block):
                env_stream = self.find_env_stream(params_list)

            current_block = self.setup_env_stream_params(
                current_block, params_list, env_stream
            )

            # Create call context and use call provider
            context = CallContext(
                fn_name=symbol_name,
                module=self.module,
                entry_block=entry_block,
                params=params_list,
                env_stream=env_stream,
                matched_var_binding=self.matched_var_binding,
                raw_args=args,
                raw_num_args=num_args,
                raw_result=result,
                builder=self,
            )

            # Use the call provider to process parameters
            current_block = call_provider(current_block, context)

            # Return 0 (success)
            with ir.InsertionPoint(current_block):
                self.return_(self.i32(0))


def attach_ffi_func(
    module: ir.Module,
    symbol_name: str,
    params: Sequence[spec.Param],
    call_provider: CallProvider,
    fn_display_name: Optional[str] = None,
) -> None:
    """Generate a TVM-FFI function with the given symbol name and call provider.

    Parameters
    ----------
    module: ir.Module
        The module to attach the function to.
    symbol_name: str
        The name of the function to attach.
    params: Sequence[spec.Param]
        The parameters of the function.
    fn_display_name: Optional[str] = None,
        The display name of the function to attach.

    call_provider: CallProvider
        The call provider that implements the calling convention.
    """
    builder = TVMFFIFunctionBuilder(module)
    builder.attach_ffi_func(symbol_name, params, call_provider, fn_display_name)


def rename_tvm_ffi_function(module: ir.Module, old_name: str, new_name: str) -> None:
    """Rename the TVM FFI function in the module.

    Parameters
    ----------
    module: ir.Module
        The module to rename the function in.
    old_name: str
        The old name of the function.
    new_name: str
        The new name of the function.

    Raises
    ------
    ValueError: If the function is not found in the module.
    """
    with module.context:
        builder = TVMFFIFunctionBuilder(module)
        fun = builder.find_func_in_module(module, f"__tvm_ffi_{old_name}")
        if fun is None:
            raise ValueError(
                f"Function '@{f'__tvm_ffi_{old_name}'}' not found in the module."
            )
        fun.attributes["sym_name"] = ir.StringAttr.get(f"__tvm_ffi_{new_name}")
