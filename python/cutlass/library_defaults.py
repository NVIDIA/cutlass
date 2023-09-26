#################################################################################################
#
# Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

"""
Classes containing valid operations for a given compute capability and data types.
"""

import logging

from cuda import __version__
import cutlass_library
from cutlass_library.library import ConvKind, IteratorAlgorithm, StrideSupport, GroupMode

import cutlass
from cutlass.utils.check import valid_stage_count
from cutlass.utils.datatypes import td_from_profiler_td, td_from_profiler_op


_generator_ccs = [50, 60, 61, 70, 75, 80, 90]

# Strip any additional information from the CUDA version
_cuda_version = __version__.split("rc")[0]


class KernelsForDataType:
    """
    Container class for keeping track of kernels that correspond to a particular combination
    of data types for operands A, B, and accumulator
    """

    def __init__(self, datatype_comb: tuple, layout_comb: tuple):
        self.datatype_comb = datatype_comb
        self.layout_comb = layout_comb

        # Dictionary mapping from alignment (int) to a list of kernels that fit the alignment
        # constraint for the data type combination
        self.kernels_by_alignment = {}

    def add(self, operation):
        """
        Add an operation to the list of supported kernels
        """
        alignment = operation.A.alignment
        if alignment not in self.kernels_by_alignment:
            self.kernels_by_alignment[alignment] = []
        self.kernels_by_alignment[alignment].append(operation)

    @property
    def alignments(self):
        """
        Returns an unsorted list of alignments supported by this data type combination

        :return: unsorted list of alignments supported by this data type combination
        :rtype: list
        """
        return list(self.kernels_by_alignment.keys())

    @property
    def all_operations(self):
        """
        Returns a list of all operations supported by this data type combination

        :return: list of all operations supported by this data type combination
        :rtype: list
        """
        ops = []
        for _, alignment_ops in self.kernels_by_alignment.items():
            ops.extend(alignment_ops)
        return ops

    def operations(self, alignment: int):
        """
        Returns operations satisfying the alignment constraint indicated by `alignment`

        :param alignment: alignment constraint of operations to return
        :type alignment: int

        :return: list of operations
        :rtype: list
        """
        if alignment not in self.kernels_by_alignment:
            raise Exception(
                f"No operations of alignment {alignment} found for data type and layout "
                f"combination {self.datatype_comb} {self.layout_comb}"
            )
        return self.kernels_by_alignment[alignment]

    def find_alignment(self, shape: tuple, layout: cutlass.LayoutType) -> int:
        """
        Returns the most preferable alignment for a given shape and layout

        :param shape: extent of each dimension of the tensor
        :type shape: tuple
        :param layout: layout of the tensor
        :type layout: cutlass.LayoutType

        :return: maximum alignment supported by the data type combination and tensor size
        :rtype: int
        """
        # Determine the leading dimension of the shape
        if layout == cutlass.LayoutType.ColumnMajor:
            ld = shape[-2]
        elif layout == cutlass.LayoutType.RowMajor:
            ld = shape[-1]
        elif layout == cutlass.LayoutType.TensorNHWC:
            ld = shape[-1]
        else:
            raise Exception(f"Unexpected or unsupported layout {layout}")

        for alignment in sorted(list(self.kernels_by_alignment.keys()), reverse=True):
            if ld % alignment == 0:
                return alignment

        # Default to alignment of 1 if no others match
        return 1

    def sort(self):
        """
        Sorts each list of kernels in `kernels_by_alignment` in descending order of threadblock shape
        """
        key = lambda op: (
            op.tile_description.threadblock_shape[0]
            * op.tile_description.threadblock_shape[1]
            * op.tile_description.threadblock_shape[2]
        )
        for alignment in self.kernels_by_alignment.keys():
            self.kernels_by_alignment[alignment].sort(key=key, reverse=True)


class ArchOptions:
    """
    Structure for keeping track of kernels available on a given compute capability

    :param target_cc: compute capability of the device on which kernels will be run
    :type target_cc: int
    :param kernel_cc: compute capability of the kernels to generate
    :type kernel_cc: int
    :param operation_kind: type of operation to register
    :type operation_kind: cutlass.OperationKind
    :param gemm_kinds: types of GEMM operations that can be included
    :type gemm_kinds: list
    :param allowed_math_operations: types of primitive math operations allowed
    :type allowed_math_operations: list
    """

    def __init__(
        self,
        target_cc: int,
        kernel_cc: int,
        operation_kind: cutlass.OperationKind,
        gemm_kinds: list,
        allowed_math_operations: list = [
            cutlass.MathOperation.multiply_add,
            cutlass.MathOperation.multiply_add_saturate,
        ]
    ):
        self.cc = kernel_cc

        # Dictionary with following structure:
        #  Key: OpcodeClass
        #  Value: Dictionary with the following structure:
        #     Key: tuple of ((DataType, DataType, DataType), (LayoutType, LayoutType, LayoutType),
        #          representing ((element_a, element_b, element_accumulator), (layout_a, layout_b))
        #     Value: KernelsForDataType
        self.operations_by_opclass = {}
        self.op_class = None
        self.allowed_math_operations = allowed_math_operations

        # Identify the method within CUTLASS generator script that generates kernel
        # descriptions for the target CC
        generate_function_name = "GenerateSM" + str(kernel_cc)
        if not hasattr(cutlass_library.generator, generate_function_name):
            cutlass.logger.warning(f"No generator found for architecture {kernel_cc}")
            return
        generate_function = getattr(cutlass_library.generator, generate_function_name)

        # Initialize a default manifest and populate it with valid kernel descriptions
        # for the target CC
        args = [
            "--kernels=all",
            f"--log-level={logging.getLevelName(cutlass.logger.level)}"
        ]
        manifest_args = cutlass_library.generator.define_parser().parse_args(args)
        manifest = cutlass_library.manifest.Manifest(manifest_args)
        generate_function(manifest, _cuda_version)

        if operation_kind not in manifest.operations:
            # No kernels generated for this architecture, this could be because the CUDA
            # toolkit is insufficient to support operations in this CC
            cutlass.logger.warning(f"No operations of type {operation_kind} found for CC {kernel_cc}")
            return

        # Only one CC should be returned, given the setup above of calling only the generation scripts
        # for a given CC
        if len(manifest.operations[operation_kind].keys()) != 1 or kernel_cc not in manifest.operations[operation_kind]:
            raise Exception(f"Error finding kernels for SM{kernel_cc}. Check that your CUDA toolkit version "
                             "is sufficient for the architecture in question.")

        # Iterate through the available operations for this operation kind and
        # find available opclasses and data types
        for name, op_list in manifest.operations[operation_kind][kernel_cc].items():
            for op in op_list:
                if operation_kind == cutlass.OperationKind.Gemm:
                    if op.gemm_kind not in gemm_kinds:
                        continue

                mi = op.tile_description.math_instruction
                if mi.math_operation not in self.allowed_math_operations:
                    continue

                if op.C.element == cutlass.DataType.void:
                    # The CUTLASS Python interface currently does not support void-C kernels
                    continue

                datatype_comb = (mi.element_a, mi.element_b, mi.element_accumulator)

                # Prune operations that don't fit in shared memory
                td = td_from_profiler_op(op)
                if not valid_stage_count(target_cc, kernel_cc, td)[0]:
                    continue

                if mi.opcode_class not in self.operations_by_opclass:
                    self.operations_by_opclass[mi.opcode_class] = {}

                datatype_comb = (mi.element_a, mi.element_b, mi.element_accumulator)
                layout_comb = (op.A.layout, op.B.layout)

                # Register TF32 kernels as F32 to enable F32 -> TF32 conversion + TF32 Tensor Core operations
                if datatype_comb == (cutlass.DataType.tf32, cutlass.DataType.tf32, cutlass.DataType.f32):
                    # TF32 kernels only supported on SM80 and beyond
                    if self.cc < 80:
                        continue
                    elif self.cc == 90:
                        if (op.A.element != cutlass.DataType.f32
                            or op.B.element != cutlass.DataType.f32
                            or op.C.element != cutlass.DataType.f32):
                            continue

                    datatype_comb = (cutlass.DataType.f32, cutlass.DataType.f32, cutlass.DataType.f32)

                opclass_dict = self.operations_by_opclass[mi.opcode_class]
                key = (datatype_comb, layout_comb)
                if key not in opclass_dict:
                    opclass_dict[key] = KernelsForDataType(datatype_comb, layout_comb)
                opclass_dict[key].add(op)

        # Set the default opclass to TensorOp, if available. Otherwise default to SIMT
        if cutlass.OpcodeClass.TensorOp in self.operations_by_opclass:
            self.op_class = cutlass.OpcodeClass.TensorOp
        else:
            self.op_class = cutlass.OpcodeClass.Simt

        # The profiler's generator may generate only a limited set of combinations of operands for SIMT kernels.
        # Here, we generate additional versions via a generic TileDescription.
        if cutlass.OpcodeClass.Simt not in self.operations_by_opclass:
            self.operations_by_opclass[cutlass.OpcodeClass.Simt] = {}

        if operation_kind == cutlass.OperationKind.Gemm:
            types = [
                (cutlass.DataType.s8, cutlass.DataType.s8, cutlass.DataType.s8),
                (cutlass.DataType.s8, cutlass.DataType.s8, cutlass.DataType.s32),
                (cutlass.DataType.f16, cutlass.DataType.f16, cutlass.DataType.f16),
                (cutlass.DataType.f16, cutlass.DataType.f16, cutlass.DataType.f32),
                (cutlass.DataType.f32, cutlass.DataType.f32, cutlass.DataType.f32),
                (cutlass.DataType.f64, cutlass.DataType.f64, cutlass.DataType.f64),
            ]

            layouts = [
                (cutlass.LayoutType.RowMajor, cutlass.LayoutType.RowMajor),
                (cutlass.LayoutType.RowMajor, cutlass.LayoutType.ColumnMajor),
                (cutlass.LayoutType.ColumnMajor, cutlass.LayoutType.RowMajor),
                (cutlass.LayoutType.ColumnMajor, cutlass.LayoutType.ColumnMajor),
            ]
        elif operation_kind == cutlass.OperationKind.Conv2d:
            types = [
                (cutlass.DataType.f16, cutlass.DataType.f16, cutlass.DataType.f16),
                (cutlass.DataType.f16, cutlass.DataType.f16, cutlass.DataType.f32),
                (cutlass.DataType.f32, cutlass.DataType.f32, cutlass.DataType.f32),
                (cutlass.DataType.f64, cutlass.DataType.f64, cutlass.DataType.f64),
            ]

            layouts = [
                (cutlass.LayoutType.TensorNHWC, cutlass.LayoutType.TensorNHWC),
            ]
        else:
            raise NotImplementedError(f"Operation kind {operation_kind} is currently unsupported.")

        alignment = 1
        epilogue_functor = cutlass.EpilogueFunctor.LinearCombination
        swizzling_functor = cutlass.SwizzlingFunctor.Identity8
        for type_comb in types:
            for layout_comb in layouts:
                comb = (type_comb, layout_comb)
                if comb in self.operations_by_opclass[cutlass.OpcodeClass.Simt]:
                    continue

                A = cutlass.TensorDescription(type_comb[0], layout_comb[0], alignment)
                B = cutlass.TensorDescription(type_comb[1], layout_comb[1], alignment)
                C = cutlass.TensorDescription(type_comb[2], cutlass.LayoutType.ColumnMajor, alignment)
                math_inst = cutlass.MathInstruction(
                    [1, 1, 1],
                    type_comb[0],
                    type_comb[1],
                    type_comb[2],
                    cutlass.OpcodeClass.Simt,
                    cutlass.MathOperation.multiply_add
                )

                td = cutlass.TileDescription(
                    [128, 128, 8], 2, [4, 2, 1], math_inst, 50, 1024)

                # Prune operations that don't fit in shared memory
                if not valid_stage_count(target_cc, kernel_cc, td_from_profiler_td(td))[0]:
                    continue

                new_kernels = KernelsForDataType(type_comb, layout_comb)

                if operation_kind == cutlass.OperationKind.Gemm:
                    new_operation = cutlass_library.manifest.GemmOperation(
                        cutlass.GemmKind.Universal, td.minimum_compute_capability,
                        td, A, B, C, type_comb[2], epilogue_functor, swizzling_functor)
                    new_kernels.add(new_operation)
                elif operation_kind == cutlass.OperationKind.Conv2d:
                    for conv_kind in [ConvKind.Fprop, ConvKind.Dgrad, ConvKind.Wgrad]:
                        new_operation = cutlass_library.manifest.Conv2dOperation(
                            conv_kind, IteratorAlgorithm.Analytic, td.minimum_compute_capability, td,
                            A, B, C, type_comb[2], StrideSupport.Strided, epilogue_functor, swizzling_functor,
                            group_mode=GroupMode.SingleGroup
                        )
                        new_kernels.add(new_operation)

                self.operations_by_opclass[cutlass.OpcodeClass.Simt][comb] = new_kernels

        # Sort all operations
        for oc in self.operations_by_opclass.keys():
            for comb in self.operations_by_opclass[oc].keys():
                self.operations_by_opclass[oc][comb].sort()

    def opclass_supports_combination(
        self, op_class: cutlass.OpcodeClass, datatype_comb: tuple, layout_comb: tuple
    ) -> bool:
        """
        Returns whether the provided operation class supports the provided data type and layout combination

        :param op_class: operation class to consider
        :type op_class: cutlass.OpcodeClass
        :param datatype_comb: tuple of data types for (element_A, element_B, element_accumulator)
        :type datatype_comb: tuple[cutlass.DataType]
        :param layout_comb: tuple of data types for (layout_A, layout_B)
        :type layout_comb: tuple[cutlass.LayoutType]

        :return: set of operation classes that support the provided data type and layout combination
        :rtype: set
        """
        if op_class not in self.operations_by_opclass:
            raise Exception(f"Unexpected or unsupported operation class {op_class}")

        return (datatype_comb, layout_comb) in self.operations_by_opclass[op_class]

    def supporting_opclasses(
        self,
        element_a: cutlass.DataType,
        element_b: cutlass.DataType,
        element_accumulator: cutlass.DataType,
        layout_a: cutlass.LayoutType,
        layout_b: cutlass.LayoutType,
    ) -> set:
        """
        Returns a set of operation classes that support the provided data type combination

        :param element_a: data type of operand A
        :type element_a: cutlass.DataType
        :param element_b: data type of operand B
        :type element_b: cutlass.DataType
        :param element_accumulator: data type of accumulator
        :type element_accumulator: cutlass.DataType
        :param layout_a: layout of operand A
        :type layout_a: cutlass.LayoutType
        :param layout_b: layout of operand B
        :type layout_b: cutlass.LayoutType

        :return: set of operation classes that support the provided data type combination
        :rtype: set
        """
        supporting_op_classes = set()
        datatype_comb = (element_a, element_b, element_accumulator)
        layout_comb = (layout_a, layout_b)

        for op_class in self.operations_by_opclass.keys():
            if self.opclass_supports_combination(op_class, datatype_comb, layout_comb):
                supporting_op_classes.add(op_class)
        return supporting_op_classes

    def operations(
        self,
        op_class: cutlass.OpcodeClass,
        element_a: cutlass.DataType,
        element_b: cutlass.DataType,
        element_accumulator: cutlass.DataType,
        layout_a: cutlass.LayoutType,
        layout_b: cutlass.LayoutType,
    ) -> KernelsForDataType:
        """
        Returns whether the provided operation class supports the provided data type combination

        :param op_class: operation class to consider
        :type op_class: cutlass.OpcodeClass
        :param element_a: data type of operand A
        :type element_a: cutlass.DataType
        :param element_b: data type of operand B
        :type element_b: cutlass.DataType
        :param element_accumulator: data type of accumulator
        :type element_accumulator: cutlass.DataType
        :param layout_a: layout of operand A
        :type layout_a: cutlass.LayoutType
        :param layout_b: layout of operand B
        :type layout_b: cutlass.LayoutType

        :return: container of kernels by alignment supported by the provided combination of parameters
        :rtype: KernelsForDataType
        """
        datatype_comb = (element_a, element_b, element_accumulator)
        layout_comb = (layout_a, layout_b)
        if not self.opclass_supports_combination(op_class, datatype_comb, layout_comb):
            raise Exception(
                f"Data type layout combination {datatype_comb}, {layout_comb} "
                f"is not supported by opcode class {op_class} on CC {self.cc}."
            )
        return self.operations_by_opclass[op_class][(datatype_comb, layout_comb)]


class OptionRegistry:
    """
    Container of all architecture-specific options

    :param target_cc: compute capability of the device on which operations will be run
    :type target_cc: int
    """

    def __init__(self, target_cc: int):
        self.registry = {}

        gemm_kinds = [cutlass.GemmKind.Universal, cutlass.GemmKind.Universal3x]
        operation_kinds = [cutlass.OperationKind.Gemm, cutlass.OperationKind.Conv2d]
        # Construct options for each CC
        for kernel_cc in _generator_ccs:
            self.registry[kernel_cc] = {}
            for opkind in operation_kinds:
                self.registry[kernel_cc][opkind] = ArchOptions(target_cc, kernel_cc, opkind, gemm_kinds)

    def options_for_cc(self, cc: int, op_kind=cutlass.OperationKind.Gemm) -> ArchOptions:
        return self.registry.get(cc, None)[op_kind]
