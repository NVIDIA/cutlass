#################################################################################################
#
# Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import re

###################################################################################################

import enum
import cutlass

# The following block implements enum.auto() for Python 3.5 variants that don't include it such
# as the default 3.5.2 on Ubuntu 16.04.
#
# https://codereview.stackexchange.com/questions/177309/reimplementing-pythons-enum-auto-for-compatibility

try:
    from enum import auto as enum_auto
except ImportError:
    __cutlass_library_auto_enum = 0

    def enum_auto() -> int:
        global __cutlass_library_auto_enum
        i = __cutlass_library_auto_enum
        __cutlass_library_auto_enum += 1
        return i

###################################################################################################

#


class GeneratorTarget(enum.Enum):
    Library = enum_auto()

#
GeneratorTargetNames = {
    GeneratorTarget.Library: 'library', 
}
#

###################################################################################################

#
ShortDataTypeNames = {
    cutlass.int32: 'i',
    cutlass.float16: 'h',
    cutlass.float32: 's',
    cutlass.float64: 'd',
    cutlass.dtype.cf32: 'c',
    cutlass.dtype.cf64: 'z',
}

#
DataTypeNames = {
    cutlass.dtype.b1: "b1",
    cutlass.dtype.u4: "u4",
    cutlass.dtype.u8: "u8",
    cutlass.dtype.u16: "u16",
    cutlass.dtype.u32: "u32",
    cutlass.dtype.u64: "u64",
    cutlass.dtype.s4: "s4",
    cutlass.int8: "s8",
    cutlass.dtype.s16: "s16",
    cutlass.int32: "s32",
    cutlass.dtype.s64: "s64",
    cutlass.float16: "f16",
    cutlass.bfloat16: "bf16",
    cutlass.float32: "f32",
    cutlass.tfloat32: "tf32",
    cutlass.float64: "f64",
    cutlass.dtype.cf16: "cf16",
    cutlass.dtype.cbf16: "cbf16",
    cutlass.dtype.cf32: "cf32",
    cutlass.dtype.ctf32: "ctf32",
    cutlass.dtype.cf64: "cf64",
    cutlass.dtype.cu4: "cu4",
    cutlass.dtype.cu8: "cu8",
    cutlass.dtype.cu16: "cu16",
    cutlass.dtype.cu32: "cu32",
    cutlass.dtype.cu64: "cu64",
    cutlass.dtype.cs4: "cs4",
    cutlass.dtype.cs8: "cs8",
    cutlass.dtype.cs16: "cs16",
    cutlass.dtype.cs32: "cs32",
    cutlass.dtype.cs64: "cs64",
}

DataTypeTag = {
    cutlass.dtype.b1: "cutlass::uint1b_t",
    cutlass.dtype.u2: "cutlass::uint2b_t",
    cutlass.dtype.u4: "cutlass::uint4b_t",
    cutlass.dtype.u8: "uint8_t",
    cutlass.dtype.u16: "uint16_t",
    cutlass.dtype.u32: "uint32_t",
    cutlass.dtype.u64: "uint64_t",
    cutlass.dtype.s2: "cutlass::int2b_t",
    cutlass.dtype.s4: "cutlass::int4b_t",
    cutlass.int8: "int8_t",
    cutlass.dtype.s16: "int16_t",
    cutlass.int32: "int32_t",
    cutlass.dtype.s64: "int64_t",
    cutlass.float16: "cutlass::half_t",
    cutlass.bfloat16: "cutlass::bfloat16_t",
    cutlass.float32: "float",
    cutlass.tfloat32: "cutlass::tfloat32_t",
    cutlass.float64: "double",
    cutlass.dtype.cf16: "cutlass::complex<cutlass::half_t>",
    cutlass.dtype.cbf16: "cutlass::complex<cutlass::bfloat16_t>",
    cutlass.dtype.cf32: "cutlass::complex<float>",
    cutlass.dtype.ctf32: "cutlass::complex<cutlass::tfloat32_t>",
    cutlass.dtype.cf64: "cutlass::complex<double>",
    cutlass.dtype.cu2: "cutlass::complex<cutlass::uint2b_t>",
    cutlass.dtype.cu4: "cutlass::complex<cutlass::uint4b_t>",
    cutlass.dtype.cu8: "cutlass::complex<cutlass::uint8_t>",
    cutlass.dtype.cu16: "cutlass::complex<cutlass::uint16_t>",
    cutlass.dtype.cu32: "cutlass::complex<cutlass::uint32_t>",
    cutlass.dtype.cu64: "cutlass::complex<cutlass::uint64_t>",
    cutlass.dtype.cs2: "cutlass::complex<cutlass::int2b_t>",
    cutlass.dtype.cs4: "cutlass::complex<cutlass::int4b_t>",
    cutlass.dtype.cs8: "cutlass::complex<cutlass::int8_t>",
    cutlass.dtype.cs16: "cutlass::complex<cutlass::int16_t>",
    cutlass.dtype.cs32: "cutlass::complex<cutlass::int32_t>",
    cutlass.dtype.cs64: "cutlass::complex<cutlass::int64_t>",
}

DataTypeSize = {
    cutlass.dtype.b1: 1,
    cutlass.dtype.u4: 4,
    cutlass.dtype.u8: 8,
    cutlass.dtype.u16: 16,
    cutlass.dtype.u32: 32,
    cutlass.dtype.u64: 64,
    cutlass.dtype.s4: 4,
    cutlass.int8: 8,
    cutlass.dtype.s16: 16,
    cutlass.int32: 32,
    cutlass.dtype.s64: 64,
    cutlass.float16: 16,
    cutlass.bfloat16: 16,
    cutlass.float32: 32,
    cutlass.tfloat32: 32,
    cutlass.float64: 64,
    cutlass.dtype.cf16: 32,
    cutlass.dtype.cbf16: 32,
    cutlass.dtype.cf32: 64,
    cutlass.dtype.ctf32: 32,
    cutlass.dtype.cf64: 128,
    cutlass.dtype.cu4: 8,
    cutlass.dtype.cu8: 16,
    cutlass.dtype.cu16: 32,
    cutlass.dtype.cu32: 64,
    cutlass.dtype.cu64: 128,
    cutlass.dtype.cs4: 8,
    cutlass.dtype.cs8: 16,
    cutlass.dtype.cs16: 32,
    cutlass.dtype.cs32: 64,
    cutlass.dtype.cs64: 128,
}

###################################################################################################
#


class BlasMode(enum.Enum):
    symmetric = enum_auto()
    hermitian = enum_auto()


#
BlasModeTag = {
    BlasMode.symmetric: 'cutlass::BlasMode::kSymmetric',
    BlasMode.hermitian: 'cutlass::BlasMode::kHermitian',
}

#
ComplexTransformTag = {
    cutlass.complex_transform.none: 'cutlass::ComplexTransform::kNone',
    cutlass.complex_transform.conj: 'cutlass::ComplexTransform::kConjugate',
}

#
RealComplexBijection = [
    (cutlass.float16, cutlass.dtype.cf16),
    (cutlass.float32, cutlass.dtype.cf32),
    (cutlass.float64, cutlass.dtype.cf64),
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
    return cutlass.dtype.invalid

#


def get_real_from_complex(complex_type):
    for r, c in RealComplexBijection:
        if complex_type == c:
            return r
    return cutlass.dtype.invalid

#


class ComplexMultiplyOp(enum.Enum):
    multiply_add = enum_auto()
    gaussian = enum_auto()

###################################################################################################

#


class MathOperation(enum.Enum):
    multiply_add = enum_auto()
    multiply_add_saturate = enum_auto()
    xor_popc = enum_auto()
    multiply_add_fast_bf16 = enum_auto()
    multiply_add_fast_f16 = enum_auto()
    multiply_add_fast_f32 = enum_auto()
    multiply_add_complex_fast_f32 = enum_auto()
    multiply_add_complex = enum_auto()
    multiply_add_complex_gaussian = enum_auto()


#
MathOperationNames = {
    MathOperation.multiply_add: 'multiply_add',
    MathOperation.multiply_add_saturate: 'multiply_add_saturate',
    MathOperation.xor_popc: 'xor_popc',
    MathOperation.multiply_add_fast_bf16: 'multiply_add_fast_bf16',
    MathOperation.multiply_add_fast_f16: 'multiply_add_fast_f16',
    MathOperation.multiply_add_fast_f32: 'multiply_add_fast_f32',
    MathOperation.multiply_add_complex_fast_f32: 'multiply_add_complex_fast_f32',
    MathOperation.multiply_add_complex: 'multiply_add_complex',
    MathOperation.multiply_add_complex_gaussian: 'multiply_add_complex_gaussian',
}

#
MathOperationTag = {
    MathOperation.multiply_add: 'cutlass::arch::OpMultiplyAdd',
    MathOperation.multiply_add_saturate: 'cutlass::arch::OpMultiplyAddSaturate',
    MathOperation.xor_popc: 'cutlass::arch::OpXorPopc',
    MathOperation.multiply_add_fast_bf16: 'cutlass::arch::OpMultiplyAddFastBF16',
    MathOperation.multiply_add_fast_f16: 'cutlass::arch::OpMultiplyAddFastF16',
    MathOperation.multiply_add_fast_f32: 'cutlass::arch::OpMultiplyAddFastF32',
    MathOperation.multiply_add_complex_fast_f32: 'cutlass::arch::OpMultiplyAddComplexFastF32',
    MathOperation.multiply_add_complex: 'cutlass::arch::OpMultiplyAddComplex',
    MathOperation.multiply_add_complex_gaussian: 'cutlass::arch::OpMultiplyAddGaussianComplex',
}

###################################################################################################

#
LayoutTag = {
    cutlass.ColumnMajor: 'cutlass::layout::ColumnMajor',
    cutlass.RowMajor: 'cutlass::layout::RowMajor',
    cutlass.layout.ColumnMajorInterleaved2: 'cutlass::layout::ColumnMajorInterleaved<2>',
    cutlass.layout.RowMajorInterleaved2: 'cutlass::layout::RowMajorInterleaved<2>',
    cutlass.ColumnMajorInterleaved32: 'cutlass::layout::ColumnMajorInterleaved<32>',
    cutlass.RowMajorInterleaved32: 'cutlass::layout::RowMajorInterleaved<32>',
    cutlass.layout.ColumnMajorInterleaved64: 'cutlass::layout::ColumnMajorInterleaved<64>',
    cutlass.layout.RowMajorInterleaved64: 'cutlass::layout::RowMajorInterleaved<64>',
    cutlass.TensorNHWC: 'cutlass::layout::TensorNHWC',
    cutlass.layout.TensorNDHWC: 'cutlass::layout::TensorNDHWC',
    cutlass.layout.TensorNCHW: 'cutlass::layout::TensorNCHW',
    cutlass.layout.TensorNGHWC: 'cutlass::layout::TensorNGHWC',
    cutlass.TensorNC32HW32: 'cutlass::layout::TensorNCxHWx<32>',
    cutlass.TensorC32RSK32: 'cutlass::layout::TensorCxRSKx<32>',
    cutlass.layout.TensorNC64HW64: 'cutlass::layout::TensorNCxHWx<64>',
    cutlass.layout.TensorC64RSK64: 'cutlass::layout::TensorCxRSKx<64>',
}

#
TransposedLayout = {
    cutlass.ColumnMajor: cutlass.RowMajor,
    cutlass.RowMajor: cutlass.ColumnMajor,
    cutlass.layout.ColumnMajorInterleaved2: cutlass.layout.RowMajorInterleaved2,
    cutlass.layout.RowMajorInterleaved2: cutlass.layout.ColumnMajorInterleaved2,
    cutlass.ColumnMajorInterleaved32: cutlass.RowMajorInterleaved32,
    cutlass.RowMajorInterleaved32: cutlass.ColumnMajorInterleaved32,
    cutlass.layout.ColumnMajorInterleaved64: cutlass.layout.RowMajorInterleaved64,
    cutlass.layout.RowMajorInterleaved64: cutlass.layout.ColumnMajorInterleaved64,
    cutlass.TensorNHWC: cutlass.TensorNHWC
}

#
ShortLayoutTypeNames = {
    cutlass.ColumnMajor: 'n',
    cutlass.layout.ColumnMajorInterleaved2: 'n2',
    cutlass.ColumnMajorInterleaved32: 'n32',
    cutlass.layout.ColumnMajorInterleaved64: 'n64',
    cutlass.RowMajor: 't',
    cutlass.layout.RowMajorInterleaved2: 't2',
    cutlass.RowMajorInterleaved32: 't32',
    cutlass.layout.RowMajorInterleaved64: 't64',
    cutlass.TensorNHWC: 'nhwc',
    cutlass.layout.TensorNDHWC: 'ndhwc',
    cutlass.layout.TensorNCHW: 'nchw',
    cutlass.layout.TensorNGHWC: 'nghwc',
    cutlass.TensorNC32HW32: 'nc32hw32',
    cutlass.layout.TensorNC64HW64: 'nc64hw64',
    cutlass.TensorC32RSK32: 'c32rsk32',
    cutlass.layout.TensorC64RSK64: 'c64rsk64'
}

#
ShortComplexLayoutNames = {
    (cutlass.ColumnMajor, cutlass.complex_transform.none): 'n',
    (cutlass.ColumnMajor, cutlass.complex_transform.conj): 'c',
    (cutlass.RowMajor, cutlass.complex_transform.none): 't',
    (cutlass.RowMajor, cutlass.complex_transform.conj): 'h'
}

###################################################################################################

#


class SideMode(enum.Enum):
    Left = enum_auto()
    Right = enum_auto()


#
SideModeTag = {
    SideMode.Left: 'cutlass::SideMode::kLeft',
    SideMode.Right: 'cutlass::SideMode::kRight'
}

#
ShortSideModeNames = {
    SideMode.Left: 'ls',
    SideMode.Right: 'rs'
}

###################################################################################################

#


class FillMode(enum.Enum):
    Lower = enum_auto()
    Upper = enum_auto()


#
FillModeTag = {
    FillMode.Lower: 'cutlass::FillMode::kLower',
    FillMode.Upper: 'cutlass::FillMode::kUpper'
}

#
ShortFillModeNames = {
    FillMode.Lower: 'l',
    FillMode.Upper: 'u'
}

###################################################################################################

#


class DiagType(enum.Enum):
    NonUnit = enum_auto()
    Unit = enum_auto()


#
DiagTypeTag = {
    DiagType.NonUnit: 'cutlass::DiagType::kNonUnit',
    DiagType.Unit: 'cutlass::DiagType::kUnit'
}

#
ShortDiagTypeNames = {
    DiagType.NonUnit: 'nu',
    DiagType.Unit: 'un'
}

###################################################################################################

OpcodeClassNames = {
    cutlass.OpClass.Simt: 'simt',
    cutlass.OpClass.TensorOp: 'tensorop',
    cutlass.OpClass.WmmaTensorOp: 'wmma_tensorop',
    cutlass.OpClass.SparseTensorOp: 'sptensorop'
}

OpcodeClassTag = {
    cutlass.OpClass.Simt: 'cutlass::arch::OpClassSimt',
    cutlass.OpClass.TensorOp: 'cutlass::arch::OpClassTensorOp',
    cutlass.OpClass.WmmaTensorOp: 'cutlass::arch::OpClassWmmaTensorOp',
    cutlass.OpClass.SparseTensorOp: 'cutlass::arch::OpClassSparseTensorOp'
}

###################################################################################################

#


class OperationKind(enum.Enum):
    Gemm = enum_auto()
    RankK = enum_auto()
    Rank2K = enum_auto()
    Trmm = enum_auto()
    Symm = enum_auto()
    Conv2d = enum_auto()
    Conv3d = enum_auto()


#
OperationKindNames = {
    OperationKind.Gemm: 'gemm', OperationKind.RankK: 'rank_k', OperationKind.Rank2K: 'rank_2k', OperationKind.Trmm: 'trmm', OperationKind.Symm: 'symm', OperationKind.Conv2d: 'conv2d', OperationKind.Conv3d: 'conv3d'
}

#
ArchitectureNames = {
    50: 'maxwell',
    60: 'pascal',
    61: 'pascal',
    70: 'volta',
    75: 'turing',
    80: 'ampere',
}

#
SharedMemPerCC = {
    70: 96,  # 96KB of SMEM
    72: 96,  # 96KB of SMEM
    75: 64,  # 64KB of SMEM
    80: 160,  # 164KB of SMEM - 4KB reserved for the driver
    86: 100,  # 100KB of SMEM
    87: 160,  # 164KB of SMEM - 4KB reserved for the driver
}

###################################################################################################

class GemmKind(enum.Enum):
    Gemm = enum_auto()
    Sparse = enum_auto()
    Universal = enum_auto()
    PlanarComplex = enum_auto()
    PlanarComplexArray = enum_auto()
    Grouped = enum_auto()


#
GemmKindNames = {
    GemmKind.Gemm: "gemm",
    GemmKind.Sparse: "spgemm",
    GemmKind.Universal: "gemm",
    GemmKind.PlanarComplex: "gemm_planar_complex",
    GemmKind.PlanarComplexArray: "gemm_planar_complex_array",
    GemmKind.Grouped: "gemm_grouped"
}

#


class RankKKind(enum.Enum):
    Universal = enum_auto()


#
RankKKindNames = {
    RankKKind.Universal: "rank_k"
}

#


class TrmmKind(enum.Enum):
    Universal = enum_auto()


#
TrmmKindNames = {
    TrmmKind.Universal: "trmm"
}

#


class SymmKind(enum.Enum):
    Universal = enum_auto()


#
SymmKindNames = {
    SymmKind.Universal: "symm"
}

#


class SwizzlingFunctor(enum.Enum):
    Identity1 = enum_auto()
    Identity2 = enum_auto()
    Identity4 = enum_auto()
    Identity8 = enum_auto()
    Horizontal = enum_auto()
    BatchedIdentity1 = enum_auto()
    StridedDgradIdentity1 = enum_auto()
    StridedDgradIdentity4 = enum_auto()
    StridedDgradHorizontal = enum_auto()


#
SwizzlingFunctorTag = {
    cutlass.IdentitySwizzle1: 'cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>',
    SwizzlingFunctor.Identity2: 'cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<2>',
    SwizzlingFunctor.Identity4: 'cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<4>',
    SwizzlingFunctor.Identity8: 'cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<8>',
    SwizzlingFunctor.Horizontal: 'cutlass::gemm::threadblock::GemmHorizontalThreadblockSwizzle',
    SwizzlingFunctor.BatchedIdentity1: "cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle",
    SwizzlingFunctor.StridedDgradIdentity1: 'cutlass::conv::threadblock::StridedDgradIdentityThreadblockSwizzle<1>',
    SwizzlingFunctor.StridedDgradIdentity4: 'cutlass::conv::threadblock::StridedDgradIdentityThreadblockSwizzle<4>',
    SwizzlingFunctor.StridedDgradHorizontal: 'cutlass::conv::threadblock::StridedDgradHorizontalThreadblockSwizzle',
}

#


class SchedulerMode(enum.Enum):
    Device = enum_auto(),
    Host = enum_auto()


#
SchedulerModeTag = {
    SchedulerMode.Device: 'cutlass::gemm::kernel::GroupScheduleMode::kDeviceOnly',
    SchedulerMode.Host: 'cutlass::gemm::kernel::GroupScheduleMode::kHostPrecompute'
}

#
ShortSchedulerModeNames = {
    SchedulerMode.Device: 'Device',
    SchedulerMode.Host: 'Host'
}

###################################################################################################


#
ConvKindTag = {
    cutlass.conv.Operator.fprop: 'cutlass::conv::Operator::kFprop',
    cutlass.conv.Operator.dgrad: 'cutlass::conv::Operator::kDgrad',
    cutlass.conv.Operator.wgrad: 'cutlass::conv::Operator::kWgrad'
}

ConvKindNames = {
    cutlass.conv.Operator.fprop: 'fprop',
    cutlass.conv.Operator.dgrad: 'dgrad',
    cutlass.conv.Operator.wgrad: 'wgrad',
}


#
IteratorAlgorithmTag = {
    cutlass.conv.IteratorAlgorithm.analytic: 'cutlass::conv::IteratorAlgorithm::kAnalytic',
    cutlass.conv.IteratorAlgorithm.optimized: 'cutlass::conv::IteratorAlgorithm::kOptimized',
    cutlass.conv.IteratorAlgorithm.fixed_channels: 'cutlass::conv::IteratorAlgorithm::kFixedChannels',
    cutlass.conv.IteratorAlgorithm.few_channels: 'cutlass::conv::IteratorAlgorithm::kFewChannels'
}

IteratorAlgorithmNames = {
    cutlass.conv.IteratorAlgorithm.analytic: 'analytic',
    cutlass.conv.IteratorAlgorithm.optimized: 'optimized',
    cutlass.conv.IteratorAlgorithm.fixed_channels: 'fixed_channels',
    cutlass.conv.IteratorAlgorithm.few_channels: 'few_channels'
}

#


class StrideSupport(enum.Enum):
    Strided = enum_auto()
    Unity = enum_auto()


#
StrideSupportTag = {
    StrideSupport.Strided: 'cutlass::conv::StrideSupport::kStrided',
    StrideSupport.Unity: 'cutlass::conv::StrideSupport::kUnity',
}

StrideSupportNames = {
    StrideSupport.Strided: '',
    StrideSupport.Unity: 'unity_stride',
}


class ConvMode(enum.Enum):
    CrossCorrelation = enum_auto()
    Convolution = enum_auto()


#
ConvModeTag = {
    ConvMode.CrossCorrelation: 'cutlass::conv::Mode::kCrossCorrelation',
    ConvMode.Convolution: 'cutlass::conv::Mode::kConvolution'
}

###################################################################################################

#


class MathInstruction:
    def __init__(self, instruction_shape, element_a, element_b, element_accumulator, opcode_class=cutlass.OpClass.Simt, math_operation=MathOperation.multiply_add):
        self.instruction_shape = instruction_shape
        self.element_a = element_a
        self.element_b = element_b
        self.element_accumulator = element_accumulator
        self.opcode_class = opcode_class
        self.math_operation = math_operation

#


class TileDescription:

    def __init__(self, threadblock_shape, stages, warp_count, math_instruction):
        self.threadblock_shape = threadblock_shape

        #: number of pipeline stages
        self.stages: int = stages

        #: number of warps along x, y, z directions
        self.warp_count: list[int] = warp_count
        self.math_instruction = math_instruction

        #: number threads per threadblock
        self.num_threads: int = 32
        for cnt in self.warp_count:
            self.num_threads *= cnt

    def procedural_name(self):
        return "%dx%d_%dx%d" % (self.threadblock_shape[0], self.threadblock_shape[1], self.threadblock_shape[2], self.stages)

#


class TensorDescription:
    def __init__(self, element, layout, alignment=1, complex_transform=cutlass.complex_transform.none):
        self.element = element
        self.layout = layout
        self.alignment = min(128 // DataTypeSize[self.element], alignment)
        self.complex_transform = complex_transform

#


class SymmetricTensorDescription:
    def __init__(self, element, layout, fill_mode, alignment=1, complex_transform=cutlass.complex_transform.none, side_mode=SideMode.Left):
        self.element = element
        self.layout = layout
        self.fill_mode = fill_mode
        self.alignment = alignment
        self.complex_transform = complex_transform
        self.side_mode = side_mode

#


class TriangularTensorDescription:
    def __init__(self, element, layout, side_mode, fill_mode, diag_type, alignment=1, complex_transform=cutlass.complex_transform.none):
        self.element = element
        self.layout = layout
        self.side_mode = side_mode
        self.fill_mode = fill_mode
        self.diag_type = diag_type
        self.alignment = alignment
        self.complex_transform = complex_transform

###################################################################################################

#


def CalculateSmemUsage(operation):
    cta_shape = operation.tile_description.threadblock_shape
    stages = operation.tile_description.stages

    if operation.operation_kind == OperationKind.Gemm and operation.gemm_kind == GemmKind.Sparse:
        # Elements represented by 8 bits of metadata (based on 4:8, 2:4 or 1:2 sparsity)
        if DataTypeSize[operation.A.element] == 32:
            elements_per_8b_md = 2
        elif DataTypeSize[operation.A.element] == 4:
            elements_per_8b_md = 8
        else:
            elements_per_8b_md = 4

        smem_per_stage = DataTypeSize[operation.A.element] * cta_shape[0] * (cta_shape[2] // 2) // 8 + \
            DataTypeSize[operation.B.element] * cta_shape[1] * cta_shape[2] // 8 + \
            cta_shape[0] * (cta_shape[2] // 2) // elements_per_8b_md
    else:
        # Few BLAS3 operations only have A tensor
        smem_per_stage = DataTypeSize[operation.A.element] * cta_shape[0] * cta_shape[2] // 8 + \
            DataTypeSize[operation.A.element] * \
            cta_shape[1] * cta_shape[2] // 8

    smem_usage = smem_per_stage * stages
    return (smem_usage >> 10)
###################################################################################################
