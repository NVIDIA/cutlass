#################################################################################################
#
# Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Common data types and string names for them. This file is similar to /tools/library/scripts/library.py,
but uses the Pybind-bound CUTLASS data types as many keys to the dictionary.
"""

import enum

import cutlass_bindings
from cutlass import EpilogueScheduleType, KernelScheduleType, TileSchedulerType


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


ShortDataTypeNames = {
    cutlass_bindings.int32: "i",
    cutlass_bindings.float16: "h",
    cutlass_bindings.float32: "s",
    cutlass_bindings.float64: "d",
    cutlass_bindings.dtype.cf32: "c",
    cutlass_bindings.dtype.cf64: "z",
}


DataTypeNames = {
    cutlass_bindings.dtype.b1: "b1",
    cutlass_bindings.dtype.u4: "u4",
    cutlass_bindings.dtype.u8: "u8",
    cutlass_bindings.dtype.u16: "u16",
    cutlass_bindings.dtype.u32: "u32",
    cutlass_bindings.dtype.u64: "u64",
    cutlass_bindings.dtype.s4: "s4",
    cutlass_bindings.int8: "s8",
    cutlass_bindings.dtype.s16: "s16",
    cutlass_bindings.int32: "s32",
    cutlass_bindings.dtype.s64: "s64",
    cutlass_bindings.float16: "f16",
    cutlass_bindings.bfloat16: "bf16",
    cutlass_bindings.float32: "f32",
    cutlass_bindings.tfloat32: "tf32",
    cutlass_bindings.float64: "f64",
    cutlass_bindings.dtype.cf16: "cf16",
    cutlass_bindings.dtype.cbf16: "cbf16",
    cutlass_bindings.dtype.cf32: "cf32",
    cutlass_bindings.dtype.ctf32: "ctf32",
    cutlass_bindings.dtype.cf64: "cf64",
    cutlass_bindings.dtype.cu4: "cu4",
    cutlass_bindings.dtype.cu8: "cu8",
    cutlass_bindings.dtype.cu16: "cu16",
    cutlass_bindings.dtype.cu32: "cu32",
    cutlass_bindings.dtype.cu64: "cu64",
    cutlass_bindings.dtype.cs4: "cs4",
    cutlass_bindings.dtype.cs8: "cs8",
    cutlass_bindings.dtype.cs16: "cs16",
    cutlass_bindings.dtype.cs32: "cs32",
    cutlass_bindings.dtype.cs64: "cs64",
}


DataTypeTag = {
    cutlass_bindings.dtype.b1: "cutlass::uint1b_t",
    cutlass_bindings.dtype.u4: "cutlass::uint4b_t",
    cutlass_bindings.dtype.u8: "uint8_t",
    cutlass_bindings.dtype.u16: "uint16_t",
    cutlass_bindings.dtype.u32: "uint32_t",
    cutlass_bindings.dtype.u64: "uint64_t",
    cutlass_bindings.dtype.s4: "cutlass::int4b_t",
    cutlass_bindings.int8: "int8_t",
    cutlass_bindings.dtype.s16: "int16_t",
    cutlass_bindings.int32: "int32_t",
    cutlass_bindings.dtype.s64: "int64_t",
    cutlass_bindings.float16: "cutlass::half_t",
    cutlass_bindings.bfloat16: "cutlass::bfloat16_t",
    cutlass_bindings.float32: "float",
    cutlass_bindings.tfloat32: "cutlass::tfloat32_t",
    cutlass_bindings.float64: "double",
    cutlass_bindings.dtype.cf16: "cutlass::complex<cutlass::half_t>",
    cutlass_bindings.dtype.cbf16: "cutlass::complex<cutlass::bfloat16_t>",
    cutlass_bindings.dtype.cf32: "cutlass::complex<float>",
    cutlass_bindings.dtype.ctf32: "cutlass::complex<cutlass::tfloat32_t>",
    cutlass_bindings.dtype.cf64: "cutlass::complex<double>",
    cutlass_bindings.dtype.cu4: "cutlass::complex<cutlass::uint4b_t>",
    cutlass_bindings.dtype.cu8: "cutlass::complex<cutlass::uint8_t>",
    cutlass_bindings.dtype.cu16: "cutlass::complex<cutlass::uint16_t>",
    cutlass_bindings.dtype.cu32: "cutlass::complex<cutlass::uint32_t>",
    cutlass_bindings.dtype.cu64: "cutlass::complex<cutlass::uint64_t>",
    cutlass_bindings.dtype.cs4: "cutlass::complex<cutlass::int4b_t>",
    cutlass_bindings.dtype.cs8: "cutlass::complex<cutlass::int8_t>",
    cutlass_bindings.dtype.cs16: "cutlass::complex<cutlass::int16_t>",
    cutlass_bindings.dtype.cs32: "cutlass::complex<cutlass::int32_t>",
    cutlass_bindings.dtype.cs64: "cutlass::complex<cutlass::int64_t>",
}


DataTypeSize = {
    cutlass_bindings.dtype.b1: 1,
    cutlass_bindings.dtype.u4: 4,
    cutlass_bindings.dtype.u8: 8,
    cutlass_bindings.dtype.u16: 16,
    cutlass_bindings.dtype.u32: 32,
    cutlass_bindings.dtype.u64: 64,
    cutlass_bindings.dtype.s4: 4,
    cutlass_bindings.int8: 8,
    cutlass_bindings.dtype.s16: 16,
    cutlass_bindings.int32: 32,
    cutlass_bindings.dtype.s64: 64,
    cutlass_bindings.float16: 16,
    cutlass_bindings.bfloat16: 16,
    cutlass_bindings.float32: 32,
    cutlass_bindings.tfloat32: 32,
    cutlass_bindings.float64: 64,
    cutlass_bindings.dtype.cf16: 32,
    cutlass_bindings.dtype.cbf16: 32,
    cutlass_bindings.dtype.cf32: 64,
    cutlass_bindings.dtype.ctf32: 32,
    cutlass_bindings.dtype.cf64: 128,
    cutlass_bindings.dtype.cu4: 8,
    cutlass_bindings.dtype.cu8: 16,
    cutlass_bindings.dtype.cu16: 32,
    cutlass_bindings.dtype.cu32: 64,
    cutlass_bindings.dtype.cu64: 128,
    cutlass_bindings.dtype.cs4: 8,
    cutlass_bindings.dtype.cs8: 16,
    cutlass_bindings.dtype.cs16: 32,
    cutlass_bindings.dtype.cs32: 64,
    cutlass_bindings.dtype.cs64: 128,
}


class DataTypeSizeBytes:
    """
    Static class to mimic the `DataTypeSize` dictionary, but with checks for whether the
    data type key is less than a full byte or a non-integer number of bytes.
    """

    @staticmethod
    def __class_getitem__(datatype):
        """
        Returns the number of bytes in size the data type is. Raises an exception if the data type
        is either less than a full byte or a non-integer number of bytes in size.

        :param datatype: data type to query

        :return: number of bytes the data type occupies
        :rtype: int
        """
        bits = DataTypeSize[datatype]
        if bits < 8:
            raise Exception(
                "Data type {} is less than one byte in size.".format(datatype)
            )
        elif bits % 8 != 0:
            raise Exception(
                "Data type {} is not an integer number of bytes.".format(datatype)
            )
        return bits // 8


ComplexTransformTag = {
    cutlass_bindings.complex_transform.none: "cutlass::ComplexTransform::kNone",
    cutlass_bindings.complex_transform.conj: "cutlass::ComplexTransform::kConjugate",
}


RealComplexBijection = [
    (cutlass_bindings.float16, cutlass_bindings.dtype.cf16),
    (cutlass_bindings.float32, cutlass_bindings.dtype.cf32),
    (cutlass_bindings.float64, cutlass_bindings.dtype.cf64),
]


def is_complex(data_type):
    for r, c in RealComplexBijection:
        if data_type == c:
            return True
    return False


def get_complex_from_real(real_type):
    for r, c in RealComplexBijection:
        if real_type == r:
            return c
    return cutlass_bindings.dtype.invalid


def get_real_from_complex(complex_type):
    for r, c in RealComplexBijection:
        if complex_type == c:
            return r
    return cutlass_bindings.dtype.invalid


class ComplexMultiplyOp(enum.Enum):
    multiply_add = enum_auto()
    gaussian = enum_auto()


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


MathOperationNames = {
    MathOperation.multiply_add: "multiply_add",
    MathOperation.multiply_add_saturate: "multiply_add_saturate",
    MathOperation.xor_popc: "xor_popc",
    MathOperation.multiply_add_fast_bf16: "multiply_add_fast_bf16",
    MathOperation.multiply_add_fast_f16: "multiply_add_fast_f16",
    MathOperation.multiply_add_fast_f32: "multiply_add_fast_f32",
    MathOperation.multiply_add_complex_fast_f32: "multiply_add_complex_fast_f32",
    MathOperation.multiply_add_complex: "multiply_add_complex",
    MathOperation.multiply_add_complex_gaussian: "multiply_add_complex_gaussian",
}


MathOperationTag = {
    MathOperation.multiply_add: "cutlass::arch::OpMultiplyAdd",
    MathOperation.multiply_add_saturate: "cutlass::arch::OpMultiplyAddSaturate",
    MathOperation.xor_popc: "cutlass::arch::OpXorPopc",
    MathOperation.multiply_add_fast_bf16: "cutlass::arch::OpMultiplyAddFastBF16",
    MathOperation.multiply_add_fast_f16: "cutlass::arch::OpMultiplyAddFastF16",
    MathOperation.multiply_add_fast_f32: "cutlass::arch::OpMultiplyAddFastF32",
    MathOperation.multiply_add_complex_fast_f32: "cutlass::arch::OpMultiplyAddComplexFastF32",
    MathOperation.multiply_add_complex: "cutlass::arch::OpMultiplyAddComplex",
    MathOperation.multiply_add_complex_gaussian: "cutlass::arch::OpMultiplyAddGaussianComplex",
}


LayoutTag = {
    cutlass_bindings.ColumnMajor: "cutlass::layout::ColumnMajor",
    cutlass_bindings.RowMajor: "cutlass::layout::RowMajor",
    cutlass_bindings.layout.ColumnMajorInterleaved2: "cutlass::layout::ColumnMajorInterleaved<2>",
    cutlass_bindings.layout.RowMajorInterleaved2: "cutlass::layout::RowMajorInterleaved<2>",
    cutlass_bindings.ColumnMajorInterleaved32: "cutlass::layout::ColumnMajorInterleaved<32>",
    cutlass_bindings.RowMajorInterleaved32: "cutlass::layout::RowMajorInterleaved<32>",
    cutlass_bindings.layout.ColumnMajorInterleaved64: "cutlass::layout::ColumnMajorInterleaved<64>",
    cutlass_bindings.layout.RowMajorInterleaved64: "cutlass::layout::RowMajorInterleaved<64>",
    cutlass_bindings.TensorNHWC: "cutlass::layout::TensorNHWC",
    cutlass_bindings.layout.TensorNDHWC: "cutlass::layout::TensorNDHWC",
    cutlass_bindings.layout.TensorNCHW: "cutlass::layout::TensorNCHW",
    cutlass_bindings.layout.TensorNGHWC: "cutlass::layout::TensorNGHWC",
    cutlass_bindings.TensorNC32HW32: "cutlass::layout::TensorNCxHWx<32>",
    cutlass_bindings.TensorC32RSK32: "cutlass::layout::TensorCxRSKx<32>",
    cutlass_bindings.layout.TensorNC64HW64: "cutlass::layout::TensorNCxHWx<64>",
    cutlass_bindings.layout.TensorC64RSK64: "cutlass::layout::TensorCxRSKx<64>",
}


TransposedLayout = {
    cutlass_bindings.ColumnMajor: cutlass_bindings.RowMajor,
    cutlass_bindings.RowMajor: cutlass_bindings.ColumnMajor,
    cutlass_bindings.layout.ColumnMajorInterleaved2: cutlass_bindings.layout.RowMajorInterleaved2,
    cutlass_bindings.layout.RowMajorInterleaved2: cutlass_bindings.layout.ColumnMajorInterleaved2,
    cutlass_bindings.ColumnMajorInterleaved32: cutlass_bindings.RowMajorInterleaved32,
    cutlass_bindings.RowMajorInterleaved32: cutlass_bindings.ColumnMajorInterleaved32,
    cutlass_bindings.layout.ColumnMajorInterleaved64: cutlass_bindings.layout.RowMajorInterleaved64,
    cutlass_bindings.layout.RowMajorInterleaved64: cutlass_bindings.layout.ColumnMajorInterleaved64,
    cutlass_bindings.TensorNHWC: cutlass_bindings.TensorNHWC,
}


ShortLayoutTypeNames = {
    cutlass_bindings.ColumnMajor: "n",
    cutlass_bindings.layout.ColumnMajorInterleaved2: "n2",
    cutlass_bindings.ColumnMajorInterleaved32: "n32",
    cutlass_bindings.layout.ColumnMajorInterleaved64: "n64",
    cutlass_bindings.RowMajor: "t",
    cutlass_bindings.layout.RowMajorInterleaved2: "t2",
    cutlass_bindings.RowMajorInterleaved32: "t32",
    cutlass_bindings.layout.RowMajorInterleaved64: "t64",
    cutlass_bindings.TensorNHWC: "nhwc",
    cutlass_bindings.layout.TensorNDHWC: "ndhwc",
    cutlass_bindings.layout.TensorNCHW: "nchw",
    cutlass_bindings.layout.TensorNGHWC: "nghwc",
    cutlass_bindings.TensorNC32HW32: "nc32hw32",
    cutlass_bindings.layout.TensorNC64HW64: "nc64hw64",
    cutlass_bindings.TensorC32RSK32: "c32rsk32",
    cutlass_bindings.layout.TensorC64RSK64: "c64rsk64",
}


ShortComplexLayoutNames = {
    (cutlass_bindings.ColumnMajor, cutlass_bindings.complex_transform.none): "n",
    (cutlass_bindings.ColumnMajor, cutlass_bindings.complex_transform.conj): "c",
    (cutlass_bindings.RowMajor, cutlass_bindings.complex_transform.none): "t",
    (cutlass_bindings.RowMajor, cutlass_bindings.complex_transform.conj): "h",
}


OpcodeClassNames = {
    cutlass_bindings.OpClass.Simt: "simt",
    cutlass_bindings.OpClass.TensorOp: "tensorop",
    cutlass_bindings.OpClass.WmmaTensorOp: "wmma_tensorop",
    cutlass_bindings.OpClass.SparseTensorOp: "sptensorop",
}


OpcodeClassTag = {
    cutlass_bindings.OpClass.Simt: "cutlass::arch::OpClassSimt",
    cutlass_bindings.OpClass.TensorOp: "cutlass::arch::OpClassTensorOp",
    cutlass_bindings.OpClass.WmmaTensorOp: "cutlass::arch::OpClassWmmaTensorOp",
    cutlass_bindings.OpClass.SparseTensorOp: "cutlass::arch::OpClassSparseTensorOp",
}


class OperationKind(enum.Enum):
    Gemm = enum_auto()
    Conv2d = enum_auto()
    Conv3d = enum_auto()


OperationKindNames = {
    OperationKind.Gemm: "gemm",
    OperationKind.Conv2d: "conv2d",
    OperationKind.Conv3d: "conv3d",
}


ArchitectureNames = {
    50: "maxwell",
    60: "pascal",
    61: "pascal",
    70: "volta",
    75: "turing",
    80: "ampere",
    90: "hopper",
}


SharedMemPerCC = {
    70: 96 << 10,  # 96KB of SMEM
    72: 96 << 10,  # 96KB of SMEM
    75: 64 << 10,  # 64KB of SMEM
    80: 160 << 10,  # 164KB of SMEM - 4KB reserved for the driver
    86: 100 << 10,  # 100KB of SMEM
    87: 160 << 10,  # 164KB of SMEM - 4KB reserved for the driver
    89: 100 << 10,  # 100KB of SMEM
    90: 227 << 10,  # 228KB of SMEM - 1KB reserved for the driver
}


class GemmKind(enum.Enum):
    Gemm = enum_auto()
    Sparse = enum_auto()
    Universal = enum_auto()
    PlanarComplex = enum_auto()
    PlanarComplexArray = enum_auto()
    Grouped = enum_auto()


GemmKindNames = {
    GemmKind.Gemm: "gemm",
    GemmKind.Sparse: "spgemm",
    GemmKind.Universal: "gemm",
    GemmKind.PlanarComplex: "gemm_planar_complex",
    GemmKind.PlanarComplexArray: "gemm_planar_complex_array",
    GemmKind.Grouped: "gemm_grouped",
}


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


SwizzlingFunctorTag = {
    cutlass_bindings.IdentitySwizzle1: "cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>",
    SwizzlingFunctor.Identity2: "cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<2>",
    SwizzlingFunctor.Identity4: "cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<4>",
    SwizzlingFunctor.Identity8: "cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<8>",
    SwizzlingFunctor.Horizontal: "cutlass::gemm::threadblock::GemmHorizontalThreadblockSwizzle",
    SwizzlingFunctor.BatchedIdentity1: "cutlass::gemm::threadblock::GemmBatchedIdentityThreadblockSwizzle",
    SwizzlingFunctor.StridedDgradIdentity1: "cutlass::conv::threadblock::StridedDgradIdentityThreadblockSwizzle<1>",
    SwizzlingFunctor.StridedDgradIdentity4: "cutlass::conv::threadblock::StridedDgradIdentityThreadblockSwizzle<4>",
    SwizzlingFunctor.StridedDgradHorizontal: "cutlass::conv::threadblock::StridedDgradHorizontalThreadblockSwizzle",
}


class SchedulerMode(enum.Enum):
    Device = (enum_auto(),)
    Host = enum_auto()


SchedulerModeTag = {
    SchedulerMode.Device: "cutlass::gemm::kernel::GroupScheduleMode::kDeviceOnly",
    SchedulerMode.Host: "cutlass::gemm::kernel::GroupScheduleMode::kHostPrecompute",
}


ShortSchedulerModeNames = {SchedulerMode.Device: "Device", SchedulerMode.Host: "Host"}


ConvKindTag = {
    cutlass_bindings.conv.Operator.fprop: "cutlass::conv::Operator::kFprop",
    cutlass_bindings.conv.Operator.dgrad: "cutlass::conv::Operator::kDgrad",
    cutlass_bindings.conv.Operator.wgrad: "cutlass::conv::Operator::kWgrad",
}


ConvKindNames = {
    cutlass_bindings.conv.Operator.fprop: "fprop",
    cutlass_bindings.conv.Operator.dgrad: "dgrad",
    cutlass_bindings.conv.Operator.wgrad: "wgrad",
}


IteratorAlgorithmTag = {
    cutlass_bindings.conv.IteratorAlgorithm.analytic: "cutlass::conv::IteratorAlgorithm::kAnalytic",
    cutlass_bindings.conv.IteratorAlgorithm.optimized: "cutlass::conv::IteratorAlgorithm::kOptimized",
    cutlass_bindings.conv.IteratorAlgorithm.fixed_channels: "cutlass::conv::IteratorAlgorithm::kFixedChannels",
    cutlass_bindings.conv.IteratorAlgorithm.few_channels: "cutlass::conv::IteratorAlgorithm::kFewChannels",
}


IteratorAlgorithmNames = {
    cutlass_bindings.conv.IteratorAlgorithm.analytic: "analytic",
    cutlass_bindings.conv.IteratorAlgorithm.optimized: "optimized",
    cutlass_bindings.conv.IteratorAlgorithm.fixed_channels: "fixed_channels",
    cutlass_bindings.conv.IteratorAlgorithm.few_channels: "few_channels",
}


class StrideSupport(enum.Enum):
    Strided = enum_auto()
    Unity = enum_auto()


StrideSupportTag = {
    StrideSupport.Strided: "cutlass::conv::StrideSupport::kStrided",
    StrideSupport.Unity: "cutlass::conv::StrideSupport::kUnity",
}


StrideSupportNames = {
    StrideSupport.Strided: "",
    StrideSupport.Unity: "unity_stride",
}


class ConvMode(enum.Enum):
    CrossCorrelation = enum_auto()
    Convolution = enum_auto()


ConvModeTag = {
    ConvMode.CrossCorrelation: "cutlass::conv::Mode::kCrossCorrelation",
    ConvMode.Convolution: "cutlass::conv::Mode::kConvolution",
}


class MathInstruction:
    """
    Description of a the lowest-level matrix-multiply-accumulate operation to be used in a kernel
    """

    def __init__(
        self,
        instruction_shape,
        element_a,
        element_b,
        element_accumulator,
        opcode_class=cutlass_bindings.OpClass.Simt,
        math_operation=MathOperation.multiply_add,
    ):
        """
        :param instruction_shape: size of the [M, N, K] dimensions of the instruction
        :type instruction_shape: list or tuple
        :param element_a: data type of operand A
        :param element_b: data type of operand B
        :param element_accumulator: data type used in accumulation
        :param opcode_class: higher-level class of the instruction (e.g., SIMT or Tensor Core)
        :type opcode_class: cutlass_bindings.OpClass
        :param math_operation: the type of low-level operation to be performed (e.g., multiply accumulate)
        :type math_operation: MathOperation
        """
        self.instruction_shape = instruction_shape
        self.element_a = element_a
        self.element_b = element_b
        self.element_accumulator = element_accumulator
        self.opcode_class = opcode_class
        self.math_operation = math_operation


class TileDescription:
    """
    Description of a tile of computation to be performed in the kernel, encompassing threadblock, cluster, and warp shapes,
    stage count, and math instruction specification
    """

    def __init__(
        self,
        threadblock_shape,
        stages,
        warp_count,
        math_instruction,
        cluster_shape=[1, 1, 1],
        kernel_schedule: KernelScheduleType = None,
        epilogue_schedule: EpilogueScheduleType = None,
        tile_scheduler: TileSchedulerType = None,
    ):
        """
        :param threadblock_shape: shape of a threadblock tyle
        :type threadblock_shape: list or tuple
        :param stages: number of pipline stages in the operation. For SM90 kernels, this can be set to `None` and the maximum
                       number of stages that can be supported for an operation on a given architecture will be computed at a later time
        :type stages: int or None
        :param warp_count: number of warps in each [M, N, K] dimension of a threadblock tile
        :type warp_count: list, tuple, or None
        :param math_instruction: specification of the instruction type and shape to be performed and the types of its operands
        :type math_instruction: MathInstruction
        :param cluster_shape: number of threadblocks in the [X, Y, Z] dimensions of a threadblock cluster
        :param kernel_schedule: type of kernel schedule to use (only available for SM90+)
        :type kernel_schedule: cutlass.KernelScheduleType
        :param epilogue_schedule: type of epilogue schedule to use (only available for SM90+)
        :type epilogue_schedule: cutlass.EpilogueScheduleType
        :param tile_scheduler: type of tile scheduler to use (only available for SM90+)
        :type tile_scheduler: cutlass.TileSchedulerType
        """
        if ((kernel_schedule is None and epilogue_schedule is not None) or
            (kernel_schedule is not None and epilogue_schedule is None)):
            raise Exception("Kernel and epilogue schedule must either both be Auto or neither be Auto.")

        self.threadblock_shape = threadblock_shape
        self.cluster_shape = cluster_shape
        self.kernel_schedule = kernel_schedule
        self.epilogue_schedule = epilogue_schedule
        self.tile_scheduler = tile_scheduler
        self.stages = stages

        self.math_instruction = math_instruction
        self.instruction_shape = math_instruction.instruction_shape

        # Number of warps along x, y, z directions
        self.warp_count = warp_count

    def clone_and_update(self, td: dict):
        attrs = {
            "cluster_shape": None,
            "threadblock_shape": None,
            "warp_count": None,
            "stages": None,
            "instruction_shape": None,
            "kernel_schedule": None,
            "epilogue_schedule": None,
            "tile_scheduler": None
        }
        for key in attrs.keys():
            if key in td.keys():
                attrs[key] = td[key]
            else:
                attrs[key] = getattr(self, key)

        mi = MathInstruction(
            attrs["instruction_shape"],
            self.math_instruction.element_a,
            self.math_instruction.element_b,
            self.math_instruction.element_accumulator,
            self.math_instruction.opcode_class,
            self.math_instruction.math_operation
        )

        return TileDescription(
            attrs["threadblock_shape"], attrs["stages"],
            attrs["warp_count"], mi, attrs["cluster_shape"],
            attrs["kernel_schedule"], attrs["epilogue_schedule"]
        )

    @property
    def num_threads(self):
        """
        Returns the number of threads in the threadblock

        :return: number of threads in the threadblock
        :rtype: int or None (if warp count is None)
        """
        if self.warp_count is not None:
            threads = 32
            for cnt in self.warp_count:
                threads *= cnt
            return threads
        return None

    def procedural_name(self):
        """
        Returns a name identifying the tile description

        :return: name identifying the tile description
        :rtype: int
        """
        emit_stages = 0 if self.stages is None else self.stages
        name = "%dx%dx%d_%dx%d_%dx%d" % (
            self.cluster_shape[0],
            self.cluster_shape[1],
            self.cluster_shape[2],
            self.threadblock_shape[0],
            self.threadblock_shape[1],
            self.threadblock_shape[2],
            emit_stages
        )

        return name

    def __str__(self):
        """
        Returns a string with containing each of the tile description's values

        :return: contents of tile description
        :rtype: str
        """
        if self.kernel_schedule is not None:
            kschedule = self.kernel_schedule
        else:
            kschedule = KernelScheduleType.ScheduleAuto

        if self.epilogue_schedule is not None:
            eschedule = self.epilogue_schedule
        else:
            eschedule = EpilogueScheduleType.ScheduleAuto

        if self.tile_scheduler is not None:
            tschedule = self.tile_scheduler.name
        else:
            tschedule = "None"
        return f"""
{{
  ClusterShape: {self.cluster_shape}
  ThreadblockShape: {self.threadblock_shape}
  WarpCount: {self.warp_count}
  Stages: {self.stages if self.stages is not None else 'Auto'}
  InstructionShape: {self.math_instruction.instruction_shape}
  Kernel schedule: {kschedule.name}
  Epilogue schedule: {kschedule.name}
  TileScheduler: {tschedule}
}}"""


class TensorDescription:
    def __init__(self, element, layout, alignment=1,
                 complex_transform=cutlass_bindings.complex_transform.none):
        self.element = element
        self.layout = layout
        self.alignment = min(128 // DataTypeSize[self.element], alignment)
        self.complex_transform = complex_transform


def CalculateSmemUsagePerStage(operation):
    """
    Returns the amount of shared memory in bytes consumed in a single stage of a kernel.

    :param op: operation for which the maximum stages should be computed. If stages are
               set via the `op.tile_description.stages` parameter, this setting is ignored
               in the present calculation
    :type op: cutlass.backend.Operation

    :return: number of bytes of shared memory consumed by a single stage
    :rtype: int
    """
    m, n, k = operation.tile_description.threadblock_shape

    if operation.operation_kind == OperationKind.Gemm:
        stage_barrier_bytes = 32
        return (
            (DataTypeSize[operation.A.element] * m * k // 8)
            + (DataTypeSize[operation.B.element] * k * n // 8)
            + stage_barrier_bytes
        )
    else:
        raise Exception("Unsupported operation kind {}.".format(operation.operation_kind))


def CalculateSmemUsage(operation):
    """
    Returns the amount of shared memory in bytes consumed by a kernel.

    :param op: operation for which the maximum stages should be computed. If stages are
               set via the `op.tile_description.stages` parameter, this setting is ignored
               in the present calculation
    :type op: cutlass.backend.Operation

    :return: int
    """
    return operation.tile_description.stages * CalculateSmemUsagePerStage(operation)


class ApiVersion(enum.Enum):
    """
    Differentiate between CUTLASS 2.x and 3.x API versions
    """

    v2x = enum_auto()
    v3x = enum_auto()


def api_version(arch, opclass, datatype):
    """
    Returns whether the architecture, opcode class, and datatype in question require using CUTLASS 2.x
    or 3.x for code emission.

    :param arch: compute capability of device on which to run
    :type arch: int
    :param opclass: class of the operation being performed
    :type opclass: cutlass_bindings.OpClass
    :param datatype: data type to be used in operation (assumes that ElementA and ElementB are the same)

    :return: API version to be used in code emission
    :rtype: ApiVersion
    """
    if (arch >= 90 and
        opclass == cutlass_bindings.OpClass.TensorOp and
        (datatype != cutlass_bindings.float64)):
        return ApiVersion.v3x
    else:
        return ApiVersion.v2x


class EmissionType(enum.Enum):
    """
    Tags for whether to emit a kernel- or device-level operation
    """

    Kernel = enum_auto()
    Device = enum_auto()
