#
# \file generator.py
#
# \brief Generates the CUTLASS Library's instances
#

import enum
import re

###################################################################################################

#
class GeneratorTarget(enum.Enum):
  Library = enum.auto()
#
GeneratorTargetNames = {
  GeneratorTarget.Library: 'library'
}
#

###################################################################################################

#
class DataType(enum.Enum):
  b1 = enum.auto()
  u4 = enum.auto()
  u8 = enum.auto()
  u16 = enum.auto()
  u32 = enum.auto()
  u64 = enum.auto()
  s4 = enum.auto()
  s8 = enum.auto()
  s16 = enum.auto()
  s32 = enum.auto()
  s64 = enum.auto()
  f16 = enum.auto()
  f32 = enum.auto()
  f64 = enum.auto()
  cf16 = enum.auto()
  cf32 = enum.auto()
  cf64 = enum.auto()
  cs4 = enum.auto()
  cs8 = enum.auto()
  cs16 = enum.auto()
  cs32 = enum.auto()
  cs64 = enum.auto()
  cu4 = enum.auto()
  cu8 = enum.auto()
  cu16 = enum.auto()
  cu32 = enum.auto()
  cu64 = enum.auto()

#
ShortDataTypeNames = {
  DataType.s32: 'i',
  DataType.f16: 'h',
  DataType.f32: 's',
  DataType.f64: 'd',
  DataType.cf32: 'c',
  DataType.cf64: 'z',
}

#
DataTypeNames = {
  DataType.b1: "b1",
  DataType.u4: "u4",
  DataType.u8: "u8",
  DataType.u16: "u16",
  DataType.u32: "u32",
  DataType.u64: "u64",
  DataType.s4: "s4",
  DataType.s8: "s8",
  DataType.s16: "s16",
  DataType.s32: "s32",
  DataType.s64: "s64",
  DataType.f16: "f16",
  DataType.f32: "f32",
  DataType.f64: "f64",
  DataType.cf16: "cf16",
  DataType.cf32: "cf32",
  DataType.cf64: "cf64",
  DataType.cu4: "cu4",
  DataType.cu8: "cu8",
  DataType.cu16: "cu16",
  DataType.cu32: "cu32",
  DataType.cu64: "cu64",
  DataType.cs4: "cs4",
  DataType.cs8: "cs8",
  DataType.cs16: "cs16",
  DataType.cs32: "cs32",
  DataType.cs64: "cs64", 
}

DataTypeTag = {
  DataType.b1: "cutlass::uint1b_t",
  DataType.u4: "cutlass::uint4b_t",
  DataType.u8: "uint8_t",
  DataType.u16: "uint16_t",
  DataType.u32: "uint32_t",
  DataType.u64: "uint64_t",
  DataType.s4: "cutlass::int4b_t",
  DataType.s8: "int8_t",
  DataType.s16: "int16_t",
  DataType.s32: "int32_t",
  DataType.s64: "int64_t",
  DataType.f16: "cutlass::half_t",
  DataType.f32: "float",
  DataType.f64: "double",
  DataType.cf16: "cutlass::complex<cutlass::half_t>",
  DataType.cf32: "cutlass::complex<float>",
  DataType.cf64: "cutlass::complex<double>",
  DataType.cu4: "cutlass::complex<cutlass::uint4b_t>",
  DataType.cu8: "cutlass::complex<cutlass::uint8_t>",
  DataType.cu16: "cutlass::complex<cutlass::uint16_t>",
  DataType.cu32: "cutlass::complex<cutlass::uint32_t>",
  DataType.cu64: "cutlass::complex<cutlass::uint64_t>",
  DataType.cs4: "cutlass::complex<cutlass::int4b_t>",
  DataType.cs8: "cutlass::complex<cutlass::int8_t>",
  DataType.cs16: "cutlass::complex<cutlass::int16_t>",
  DataType.cs32: "cutlass::complex<cutlass::int32_t>",
  DataType.cs64: "cutlass::complex<cutlass::int64_t>",
}

DataTypeSize = {
  DataType.b1: 1,
  DataType.u4: 4,
  DataType.u8: 4,
  DataType.u16: 16,
  DataType.u32: 32,
  DataType.u64: 64,
  DataType.s4: 4,
  DataType.s8: 8,
  DataType.s16: 16,
  DataType.s32: 32,
  DataType.s64: 64,
  DataType.f16: 16,
  DataType.f32: 32,
  DataType.f64: 64,
  DataType.cf16: 32,
  DataType.cf32: 64,
  DataType.cf64: 128,
  DataType.cu4: 8,
  DataType.cu8: 16,
  DataType.cu16: 32,
  DataType.cu32: 64,
  DataType.cu64: 128,
  DataType.cs4: 8,
  DataType.cs8: 16,
  DataType.cs16: 32,
  DataType.cs32: 64,
  DataType.cs64: 128,
}

###################################################################################################

#
class ComplexTransform(enum.Enum):
  none = enum.auto()
  conj = enum.auto()

#
ComplexTransformTag = {
  ComplexTransform.none: 'cutlass::ComplexTransform::kNone',
  ComplexTransform.conj: 'cutlass::ComplexTransform::kConjugate',
}

#
RealComplexBijection = [
  (DataType.f16, DataType.cf16),
  (DataType.f32, DataType.cf32),
  (DataType.f64, DataType.cf64),
]

#
def is_complex(data_type):
  for r, c in RealComplexBijection:
    if data_type == c:
      return True
  return False

#
def get_complex_from_real(real_type):
  for r, c in RealComplexBijection:
    if real_type == r:
      return c
  return DataType.invalid

#
def get_real_from_complex(complex_type):
  for r, c in RealComplexBijection:
    if complex_type == c:
      return r
  return DataType.invalid

#
class ComplexMultiplyOp(enum.Enum):
  multiply_add = enum.auto()
  gaussian = enum.auto()

###################################################################################################

#
class MathOperation(enum.Enum):
  multiply_add = enum.auto()
  multiply_add_saturate = enum.auto()
  xor_popc = enum.auto()
  multiply_add_complex = enum.auto()
#
MathOperationTag = {
  MathOperation.multiply_add: 'cutlass::arch::OpMultiplyAdd', 
  MathOperation.multiply_add_saturate: 'cutlass::arch::OpMultiplyAddSaturate',
  MathOperation.xor_popc: 'cutlass::arch::OpXorPopc',
  MathOperation.multiply_add_complex: 'cutlass::arch::OpMultiplyAddComplex',
}

###################################################################################################

#
class LayoutType(enum.Enum):
  ColumnMajor = enum.auto()
  RowMajor = enum.auto()
  ColumnMajorInterleaved32 = enum.auto()
  RowMajorInterleaved32 = enum.auto()
  ColumnMajorInterleaved64 = enum.auto()
  RowMajorInterleaved64 = enum.auto()
  TensorNHWC = enum.auto()
  TensorNCHW = enum.auto()
  TensorNGHWC = enum.auto()
  TensorNCxHW32 = enum.auto()
  TensorNCxHW64 = enum.auto()

#
LayoutTag = {
  LayoutType.ColumnMajor: 'cutlass::layout::ColumnMajor',
  LayoutType.RowMajor: 'cutlass::layout::RowMajor',
  LayoutType.ColumnMajorInterleaved32: 'cutlass::layout::ColumnMajorInterleaved<32>',
  LayoutType.RowMajorInterleaved32: 'cutlass::layout::RowMajorInterleaved<32>',
  LayoutType.ColumnMajorInterleaved64: 'cutlass::layout::ColumnMajorInterleaved<64>',
  LayoutType.RowMajorInterleaved64: 'cutlass::layout::RowMajorInterleaved<64>',
  LayoutType.TensorNHWC: 'cutlass::layout::TensorNHWC',
  LayoutType.TensorNCHW: 'cutlass::layout::TensorNCHW',
  LayoutType.TensorNGHWC: 'cutlass::layout::TensorNGHWC',
  LayoutType.TensorNCxHW32: 'cutlass::layout::TensorNCxHW32',
  LayoutType.TensorNCxHW64: 'cutlass::layout::TensorNCxHW64'
}

#
TransposedLayout = {
  LayoutType.ColumnMajor: LayoutType.RowMajor,
  LayoutType.RowMajor: LayoutType.ColumnMajor,
  LayoutType.ColumnMajorInterleaved32: LayoutType.RowMajorInterleaved32,
  LayoutType.RowMajorInterleaved32: LayoutType.ColumnMajorInterleaved32,
  LayoutType.ColumnMajorInterleaved64: LayoutType.RowMajorInterleaved64,
  LayoutType.RowMajorInterleaved64: LayoutType.ColumnMajorInterleaved64,
  LayoutType.TensorNHWC: LayoutType.TensorNHWC
}

#
ShortLayoutTypeNames = {
  LayoutType.ColumnMajor: 'n',
  LayoutType.ColumnMajorInterleaved32: 'n32',
  LayoutType.ColumnMajorInterleaved64: 'n64',
  LayoutType.RowMajor: 't',
  LayoutType.RowMajorInterleaved32: 't32',
  LayoutType.RowMajorInterleaved64: 't64',
  LayoutType.TensorNHWC: 'nhwc',
  LayoutType.TensorNCHW: 'nchw',
  LayoutType.TensorNGHWC: 'nghwc',
  LayoutType.TensorNCxHW32: 'ncxhw32',
  LayoutType.TensorNCxHW64: 'ncxhw64'
}

#
ShortComplexLayoutNames = {
  (LayoutType.ColumnMajor, ComplexTransform.none): 'n',
  (LayoutType.ColumnMajor, ComplexTransform.conj): 'c',
  (LayoutType.RowMajor, ComplexTransform.none): 't',
  (LayoutType.RowMajor, ComplexTransform.conj): 'h'
}

###################################################################################################

#
class OpcodeClass(enum.Enum):
  Simt = enum.auto()
  TensorOp = enum.auto()
  WmmaTensorOp = enum.auto()

OpcodeClassNames = {
  OpcodeClass.Simt: 'simt',
  OpcodeClass.TensorOp: 'tensorop',
  OpcodeClass.WmmaTensorOp: 'wmma_tensorop',
}

OpcodeClassTag = {
  OpcodeClass.Simt: 'cutlass::arch::OpClassSimt',
  OpcodeClass.TensorOp: 'cutlass::arch::OpClassTensorOp',
  OpcodeClass.WmmaTensorOp: 'cutlass::arch::OpClassWmmaTensorOp',
}

###################################################################################################

#
class OperationKind(enum.Enum):
  Gemm = enum.auto()
#
OperationKindNames = {
  OperationKind.Gemm: 'gemm'
}

# 
class Target(enum.Enum):
  library = enum.auto()

ArchitectureNames = {
  50: 'maxwell',
  60: 'pascal',
  61: 'pascal',
  70: 'volta',
  75: 'turing',
}

###################################################################################################

#
def SubstituteTemplate(template, values):
  text = template
  changed = True
  while changed:
    changed = False
    for key, value in values.items():
      regex = "\\$\\{%s\\}" % key
      newtext = re.sub(regex, value, text)
      if newtext != text:
        changed = True
      text = newtext
  return text

###################################################################################################

#
class GemmKind(enum.Enum):
  Gemm = enum.auto()
  Batched = enum.auto()
  Array = enum.auto()
  Universal = enum.auto()
  PlanarComplex = enum.auto()
  PlanarComplexArray = enum.auto()

#
GemmKindNames = {
  GemmKind.Gemm: "gemm",
  GemmKind.Batched: "gemm_batched",
  GemmKind.Array: "gemm_array",
  GemmKind.Universal: "gemm_universal",
  GemmKind.PlanarComplex: "gemm_planar_complex",
  GemmKind.PlanarComplexArray: "gemm_planar_complex_array",
}

#
class EpilogueFunctor(enum.Enum):
  LinearCombination = enum.auto()
  LinearCombinationClamp = enum.auto()

#
EpilogueFunctorTag = {
  EpilogueFunctor.LinearCombination: 'cutlass::epilogue::thread::LinearCombination',
  EpilogueFunctor.LinearCombinationClamp: 'cutlass::epilogue::thread::LinearCombinationClamp',
}

#
class SwizzlingFunctor(enum.Enum):
  Cohort = enum.auto()
  Identity = enum.auto()

#
SwizzlingFunctorTag = {
  SwizzlingFunctor.Cohort: 'cutlass::gemm::threadblock::GemmCohortThreadblockSwizzle<${layout_a}, ${layout_b}>',
  SwizzlingFunctor.Identity: 'cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle',
}
###################################################################################################

#
class MathInstruction:
  def __init__(self, instruction_shape, element_a, element_b, element_accumulator, opcode_class, math_operation = MathOperation.multiply_add):
    self.instruction_shape = instruction_shape
    self.element_a = element_a
    self.element_b = element_b
    self.element_accumulator = element_accumulator
    self.opcode_class = opcode_class
    self.math_operation = math_operation


#
class TileDescription:

  def __init__(self, threadblock_shape, stages, warp_count, math_instruction, min_compute, max_compute):
    self.threadblock_shape = threadblock_shape
    self.stages = stages
    self.warp_count = warp_count
    self.math_instruction = math_instruction
    self.minimum_compute_capability = min_compute
    self.maximum_compute_capability = max_compute

  def procedural_name(self):
    return "%dx%d_%dx%d" % (self.threadblock_shape[0], self.threadblock_shape[1], self.threadblock_shape[2], self.stages)

#
class TensorDescription:
  def __init__(self, element, layout, alignment = 1, complex_transform = ComplexTransform.none):
    self.element = element
    self.layout = layout
    self.alignment = alignment
    self.complex_transform = complex_transform

###################################################################################################
