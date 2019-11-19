#
# \file generator.py
#
# \brief Generates the CUTLASS Library's instances
#

import enum
import os.path
import shutil
import functools
import operator

from library import *


###################################################################################################
#
# Data structure modeling a GEMM operation
#
###################################################################################################

#
class GemmOperation:
  #
  def __init__(self, gemm_kind, arch, tile_description, A, B, C, element_epilogue):
    self.operation_kind = OperationKind.Gemm
    self.arch = arch
    self.tile_description = tile_description
    self.gemm_kind = gemm_kind
    self.A = A
    self.B = B
    self.C = C
    self.element_epilogue = element_epilogue

  #
  def core_name(self):
    ''' The basic operation kind is prefixed with a letter indicating the accumulation type. '''
    if self.tile_description.math_instruction.opcode_class == OpcodeClass.TensorOp or \
      self.tile_description.math_instruction.opcode_class == OpcodeClass.WmmaTensorOp:
      inst_shape = "%d%d%d" % tuple(self.tile_description.math_instruction.instruction_shape)
    else:
      inst_shape = ''

    return "%s%s%s" % (ShortDataTypeNames[self.tile_description.math_instruction.element_accumulator], inst_shape, GemmKindNames[self.gemm_kind])

  #
  def extended_name(self):
    ''' Append data types if they differ from compute type. '''
    if self.C.element != self.tile_description.math_instruction.element_accumulator and \
      self.A.element != self.tile_description.math_instruction.element_accumulator:
      extended_name = "${element_c}_${core_name}_${element_a}"
    elif self.C.element == self.tile_description.math_instruction.element_accumulator and  \
      self.A.element != self.tile_description.math_instruction.element_accumulator:
      extended_name = "${core_name}_${element_a}"
    else:
      extended_name = "${core_name}"

    extended_name = SubstituteTemplate(extended_name, {
      'element_a': DataTypeNames[self.A.element],
      'element_c': DataTypeNames[self.C.element],
      'core_name': self.core_name()
      })

    return extended_name

  #
  def procedural_name(self):
    ''' The full procedural name indicates architecture, extended name, tile size, and layout. '''
    if self.tile_description.stages > 2:
      threadblock = "%dx%d_%dx%d" % (
        self.tile_description.threadblock_shape[0], 
        self.tile_description.threadblock_shape[1],
        self.tile_description.threadblock_shape[2],
        self.tile_description.stages
      )
    else:
      threadblock = "%dx%d" % (self.tile_description.threadblock_shape[0], self.tile_description.threadblock_shape[1])

    opcode_class_name = OpcodeClassNames[self.tile_description.math_instruction.opcode_class]

    return SubstituteTemplate(
      "cutlass_${opcode_class}_${extended_name}_${threadblock}_${layout}",
      {
        'opcode_class': opcode_class_name,
        'extended_name': self.extended_name(),
        'threadblock': threadblock,
        'layout': "%s%s" % (ShortLayoutTypeNames[self.A.layout], ShortLayoutTypeNames[self.B.layout]),
      }
    )

  #
  def configuration_name(self):
    ''' The full procedural name indicates architecture, extended name, tile size, and layout. '''
    return self.procedural_name()

###################################################################################################
#
# Emits single instances of a CUTLASS device-wide operator
#
###################################################################################################

#
class EmitGemmInstance:
  ''' Responsible for emitting a CUTLASS template definition'''

  def __init__(self):
    self.template = """
  // Gemm operator ${operation_name}
  using Operation_${operation_name} = cutlass::gemm::device::Gemm<
    ${element_a}, ${layout_a},
    ${element_b}, ${layout_b},
    ${element_c}, ${layout_c},
    ${element_accumulator},
    ${opcode_class},
    ${arch},
    cutlass::gemm::GemmShape<${threadblock_shape_m}, ${threadblock_shape_n}, ${threadblock_shape_k}>,
    cutlass::gemm::GemmShape<${warp_shape_m}, ${warp_shape_n}, ${warp_shape_k}>,
    cutlass::gemm::GemmShape<${instruction_shape_m}, ${instruction_shape_n}, ${instruction_shape_k}>,
    cutlass::epilogue::thread::LinearCombination<
      ${element_c},
      ${epilogue_vector_length},
      ${element_accumulator},
      ${element_epilogue}
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle,
    ${stages}
  >;
"""

  def emit(self, operation):

    warp_shape = [operation.tile_description.threadblock_shape[idx] // operation.tile_description.warp_count[idx] for idx in range(3)]
    #warp_shape[2] = operation.tile_description.math_instruction.instruction_shape[2]
    warp_shape[2] = operation.tile_description.threadblock_shape[2] 

    epilogue_vector_length = int(min(operation.C.alignment * DataTypeSize[operation.C.element], 128) / DataTypeSize[operation.C.element])

    values = {
      'operation_name': operation.procedural_name(),
      'element_a': DataTypeTag[operation.A.element],
      'layout_a': LayoutTag[operation.A.layout],
      'element_b': DataTypeTag[operation.B.element],
      'layout_b': LayoutTag[operation.B.layout],
      'element_c': DataTypeTag[operation.C.element],
      'layout_c': LayoutTag[operation.C.layout],
      'element_accumulator': DataTypeTag[operation.tile_description.math_instruction.element_accumulator],
      'opcode_class': OpcodeClassTag[operation.tile_description.math_instruction.opcode_class],
      'arch': "cutlass::arch::Sm%d" % operation.arch,
      'threadblock_shape_m': str(operation.tile_description.threadblock_shape[0]),
      'threadblock_shape_n': str(operation.tile_description.threadblock_shape[1]),
      'threadblock_shape_k': str(operation.tile_description.threadblock_shape[2]),
      'warp_shape_m': str(warp_shape[0]),
      'warp_shape_n': str(warp_shape[1]),
      'warp_shape_k': str(warp_shape[2]),
      'instruction_shape_m': str(operation.tile_description.math_instruction.instruction_shape[0]),
      'instruction_shape_n': str(operation.tile_description.math_instruction.instruction_shape[1]),
      'instruction_shape_k': str(operation.tile_description.math_instruction.instruction_shape[2]),
      'epilogue_vector_length': str(epilogue_vector_length),
      'element_epilogue': str(DataTypeTag[operation.element_epilogue]),
      'stages': str(operation.tile_description.stages)
    }

    return SubstituteTemplate(self.template, values)

###################################################################################################

#
class EmitGemmBatchedInstance:
  ''' Responsible for emitting a CUTLASS template definition'''

  def __init__(self):
    self.template = """
  // Gemm operator ${operation_name}
  using Operation_${operation_name} = cutlass::gemm::device::GemmBatched<
    ${element_a}, ${layout_a},
    ${element_b}, ${layout_b},
    ${element_c}, ${layout_c},
    ${element_accumulator},
    ${opcode_class},
    ${arch},
    cutlass::gemm::GemmShape<${threadblock_shape_m}, ${threadblock_shape_n}, ${threadblock_shape_k}>,
    cutlass::gemm::GemmShape<${warp_shape_m}, ${warp_shape_n}, ${warp_shape_k}>,
    cutlass::gemm::GemmShape<${instruction_shape_m}, ${instruction_shape_n}, ${instruction_shape_k}>,
    cutlass::epilogue::thread::LinearCombination<
      ${element_c},
      ${epilogue_vector_length},
      ${element_accumulator},
      ${element_epilogue}
    >,
    cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle,
    ${stages},
    ${align_a},
    ${align_b}
  >;
"""

  def emit(self, operation):

    warp_shape = [operation.tile_description.threadblock_shape[idx] // operation.tile_description.warp_count[idx] for idx in range(3)]
    #warp_shape[2] = operation.tile_description.math_instruction.instruction_shape[2]
    warp_shape[2] = operation.tile_description.threadblock_shape[2]

    epilogue_vector_length = int(min(operation.C.alignment * DataTypeSize[operation.C.element], 128) / DataTypeSize[operation.C.element])

    values = {
      'operation_name': operation.procedural_name(),
      'element_a': DataTypeTag[operation.A.element],
      'layout_a': LayoutTag[operation.A.layout],
      'element_b': DataTypeTag[operation.B.element],
      'layout_b': LayoutTag[operation.B.layout],
      'element_c': DataTypeTag[operation.C.element],
      'layout_c': LayoutTag[operation.C.layout],
      'element_accumulator': DataTypeTag[operation.tile_description.math_instruction.element_accumulator],
      'opcode_class': OpcodeClassTag[operation.tile_description.math_instruction.opcode_class],
      'arch': "cutlass::arch::Sm%d" % operation.arch,
      'threadblock_shape_m': str(operation.tile_description.threadblock_shape[0]),
      'threadblock_shape_n': str(operation.tile_description.threadblock_shape[1]),
      'threadblock_shape_k': str(operation.tile_description.threadblock_shape[2]),
      'warp_shape_m': str(warp_shape[0]),
      'warp_shape_n': str(warp_shape[1]),
      'warp_shape_k': str(warp_shape[2]),
      'instruction_shape_m': str(operation.tile_description.math_instruction.instruction_shape[0]),
      'instruction_shape_n': str(operation.tile_description.math_instruction.instruction_shape[1]),
      'instruction_shape_k': str(operation.tile_description.math_instruction.instruction_shape[2]),
      'epilogue_vector_length': str(epilogue_vector_length),
      'element_epilogue': str(DataTypeTag[operation.element_epilogue]),
      'stages': str(operation.tile_description.stages),
      'align_a': str(operation.A.alignment),
      'align_b': str(operation.B.alignment),
    }

    return SubstituteTemplate(self.template, values)

###################################################################################################
#
# Generator functions for all layouts
#
###################################################################################################

#
def GenerateGemmSimt(gemm_kind, manifest, tile_descriptions, min_cc):
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  # for each tile configuration, emit a GEMM
  for tile in tile_descriptions:
    for layout in layouts:

      A = TensorDescription(tile.math_instruction.element_a, layout[0], 1)
      B = TensorDescription(tile.math_instruction.element_b, layout[1], 1)
      C = TensorDescription(tile.math_instruction.element_accumulator, layout[2], 1)

      manifest.append(GemmOperation(gemm_kind, 50, tile, A, B, C, tile.math_instruction.element_accumulator))

#
def GenerateGemmTensorOp(gemm_kind, manifest, tile_descriptions, min_cc, minimum_alignment = [128,]):

  # Canonical matrix layouts
  canonical_layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  # Interleaved matrix layouts
  interleaved_layouts = {
    8: [
      #(LayoutType.ColumnMajorInterleaved32, LayoutType.RowMajorInterleaved32, LayoutType.ColumnMajorInterleaved32),
      (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    ],
    4: [
      #(LayoutType.ColumnMajorInterleaved64, LayoutType.RowMajorInterleaved64, LayoutType.ColumnMajorInterleaved64),
      (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    ]
  }

  # for each tile configuration, emit a GEMM
  for align in minimum_alignment:
    for tile in tile_descriptions:

      min_input_size = min(DataTypeSize[tile.math_instruction.element_a], DataTypeSize[tile.math_instruction.element_a])

      # If the data type is large enough, use canonical layouts.
      if min_input_size >= 16:
        layouts = canonical_layouts
      else:
        layouts = interleaved_layouts[min_input_size]

      for layout in layouts:

        # 
        output_types = [tile.math_instruction.element_a, tile.math_instruction.element_accumulator] \
          if DataTypeSize[tile.math_instruction.element_accumulator] == 32 \
          else [tile.math_instruction.element_accumulator,]

        align_a = align // DataTypeSize[tile.math_instruction.element_a]
        align_b = align // DataTypeSize[tile.math_instruction.element_b]


        for output_type in output_types:

          rows_per_warp = 8 // tile.warp_count[1]
          align_c = min(int(align / DataTypeSize[output_type]), tile.threadblock_shape[1] * rows_per_warp // 32)

          A = TensorDescription(tile.math_instruction.element_a, layout[0], align_a)
          B = TensorDescription(tile.math_instruction.element_b, layout[1], align_b)
          C = TensorDescription(output_type, layout[2], max(1, align_c))

          element_epilogue = DataType.f32 if tile.math_instruction.element_accumulator == DataType.s32 \
            else tile.math_instruction.element_accumulator

          manifest.append(GemmOperation(gemm_kind, min_cc, tile, A, B, C, element_epilogue))


#
def GenerateGemmWmmaTensorOp(gemm_kind, manifest, tile_descriptions, min_cc, minimum_alignment = [128,]):

  # Wmma supported matrix layouts
  layouts = [
    (LayoutType.ColumnMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.ColumnMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.ColumnMajor, LayoutType.ColumnMajor),
    (LayoutType.RowMajor, LayoutType.RowMajor, LayoutType.ColumnMajor),
  ]

  # for each tile configuration, emit a GEMM
  for align in minimum_alignment:
    for tile in tile_descriptions:
      for layout in layouts:

        # 
        output_types = [tile.math_instruction.element_a, tile.math_instruction.element_accumulator] \
          if DataTypeSize[tile.math_instruction.element_accumulator] == 32 \
          else [tile.math_instruction.element_accumulator,]

        align_a = align // DataTypeSize[tile.math_instruction.element_a]
        align_b = align // DataTypeSize[tile.math_instruction.element_b]


        for output_type in output_types:

          rows_per_warp = 8 // tile.warp_count[1]
          align_c = min(int(align / DataTypeSize[output_type]), tile.threadblock_shape[1] * rows_per_warp // 32)

          A = TensorDescription(tile.math_instruction.element_a, layout[0], align_a)
          B = TensorDescription(tile.math_instruction.element_b, layout[1], align_b)
          C = TensorDescription(output_type, layout[2], max(1, align_c))

          element_epilogue = DataType.f32 if tile.math_instruction.element_accumulator == DataType.s32 \
            else tile.math_instruction.element_accumulator

          manifest.append(GemmOperation(gemm_kind, min_cc, tile, A, B, C, element_epilogue))

###################################################################################################
#
# Emitters functions for all targets
#
###################################################################################################

class EmitGemmConfigurationLibrary:
  def __init__(self, operation_path, configuration_name):
    self.configuration_name = configuration_name
    self.configuration_path = os.path.join(operation_path, "%s.cu" % configuration_name).replace('\\', '/')

    self.instance_emitter = {
      GemmKind.Gemm: EmitGemmInstance,
      GemmKind.Batched: EmitGemmBatchedInstance
    }

    self.gemm_kind_wrappers = {
      GemmKind.Gemm: 'GemmOperation',
      GemmKind.Batched: 'GemmBatchedOperation',
    }

    self.wmma_guard_start = "#if defined(CUTLASS_ARCH_WMMA_SM${sm_number}_ENABLED)"

    self.instance_template = """
${compile_guard_start}
  manifest.append(new ${gemm_kind}<Operation_${operation_name}>("${operation_name}"));
${compile_guard_end}
"""
    self.header_template = """
/*
  Generated by gemm_operation.py - Do not edit.
*/

///////////////////////////////////////////////////////////////////////////////////////////////////
#include "cutlass/arch/wmma.h"
#include "cutlass/cutlass.h"
#include "cutlass/library/library.h"
#include "cutlass/library/manifest.h"

#include "library_internal.h"
#include "gemm_operation.h"

namespace cutlass {
namespace library {

///////////////////////////////////////////////////////////////////////////////////////////////////

void initialize_${configuration_name}(Manifest &manifest) {

"""
    self.epilogue_template = """

}

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace library
} // namespace cutlass

///////////////////////////////////////////////////////////////////////////////////////////////////

"""

  def __enter__(self):
    self.configuration_file = open(self.configuration_path, "w")
    self.configuration_file.write(SubstituteTemplate(self.header_template, {
      'configuration_name': self.configuration_name
      }))
    self.operations = []
    return self

  def emit(self, operation):
    emitter = self.instance_emitter[operation.gemm_kind]()

    self.operations.append(operation)
    self.configuration_file.write(emitter.emit(operation))
    self.configuration_file.write(SubstituteTemplate(self.instance_template, {
      'configuration_name': self.configuration_name,
      'operation_name': operation.procedural_name(),
      'gemm_kind': self.gemm_kind_wrappers[operation.gemm_kind],
      'compile_guard_start': SubstituteTemplate(self.wmma_guard_start, {'sm_number': str(operation.arch)}) \
        if operation.tile_description.math_instruction.opcode_class == OpcodeClass.WmmaTensorOp else "",
      'compile_guard_end': "#endif" \
        if operation.tile_description.math_instruction.opcode_class == OpcodeClass.WmmaTensorOp else "" 
      }))

  def __exit__(self, exception_type, exception_value, traceback):
    self.configuration_file.write(self.epilogue_template)
    self.configuration_file.close()

###################################################################################################
###################################################################################################
