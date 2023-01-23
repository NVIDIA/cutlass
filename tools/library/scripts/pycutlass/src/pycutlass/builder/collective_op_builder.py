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
Utilities for stamping out collective mainloops for SM90 kernels
"""

import cute
import cutlass
from pycutlass import SubstituteTemplate
import pycutlass.library as library


tma_alignment_bytes = 16
cp_async_min_alignment_bytes = 4


class RowColMajorToGMMAMajor:
    @staticmethod
    def A(layout, element):
        """
        Converts operand A's layout from row/column major format into CuTe's GMMA major format

        :param layout: layout of the A operand
        :type layout: cutlass.RowMajor or cutlass.ColumnMajor
        :param element: data type of the A operand

        :return: C++ CuTe GMMA major format
        :rtype: cute.GMMAMajor
        """
        type_requires_k_major = (element == cutlass.tfloat32) or (element == cutlass.int8)
        if layout == cutlass.ColumnMajor and not type_requires_k_major:
            return cute.GMMAMajor.MN
        else:
            return cute.GMMAMajor.K

    @staticmethod
    def B(layout, element):
        """
        Converts operand B's layout from row/column major format into CuTe's GMMA major format

        :param layout: layout of the B operand
        :type layout: cutlass.RowMajor or cutlass.ColumnMajor
        :param element: data type of the B operand

        :return: C++ CuTe GMMA major format
        :rtype: cute.GMMAMajor
        """
        type_requires_k_major = (element == cutlass.tfloat32) or (element == cutlass.int8)
        if layout == cutlass.RowMajor and not type_requires_k_major:
            return cute.GMMAMajor.MN
        else:
            return cute.GMMAMajor.K


def cluster_shape_to_tma(dim):
    """
    Returns the TMA copy type for a given cluster dimension

    :param dim: a given dimension of a cluster
    :type dim: layout

    :return: C++ TMA copy time
    :rtype: str
    """
    return 'cute::SM90_TMA_LOAD' if dim == 1 else 'cute::SM90_TMA_LOAD_MULTICAST'


def make_cpasync_gmem_tiled_copy(thread_count, element, alignment, gmma_layout, dim_mn, dim_k):
    """
    Returns a `make_tiled_copy` call for a given configuraiton

    :param thread_count: number of threads in the threadblock
    :type thread_count: int
    :param element: datatype of the operand in question
    :param alignment: byte alignment of the operand in question
    :type alignment: int
    :param gmma_layout: GMMA layout of the operand in question
    :type gmma_layout: cute.GMMAMajor
    :param dim_mn: extent of the M/N dimension of the tile
    :type dim_mn: int
    :param dim_k: extent of the reduction dimension of the tile
    :type dim_k: int

    :return: C++ call to `make_tiled_copy`
    :rtype: str
    """

    emission_str = """decltype(cute::make_tiled_copy(
        cute::Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS<cute::uint_byte_t<static_cast<int>(sizeof(${element})) * ${alignment}>>, ${element}>{},
        cute::Layout<cute::Shape<_${shape0_x}, _${shape0_y}>,
                    cute::Stride<_${stride_x}, _${stride_y}>>{},
        cute::Layout<cute::Shape<_${shape1_x}, _${shape1_y}>>{}))"""
    if gmma_layout == cute.GMMAMajor.K:
        threads_major = dim_k // alignment
        threads_minor = thread_count // threads_major
        values = {
            'shape0_x': str(threads_minor),
            'shape0_y': str(threads_major),
            'stride_x': str(threads_major),
            'stride_y': '1',
            'shape1_x': '1',
            'shape1_y': str(alignment)
        }
    elif gmma_layout == cute.GMMAMajor.MN:
        threads_major = dim_mn // alignment
        threads_minor = thread_count // threads_major
        values = {
            'shape0_x': str(threads_major),
            'shape0_y': str(threads_minor),
            'stride_x': '1',
            'stride_y': str(threads_major),
            'shape1_x': str(alignment),
            'shape1_y': '1'
        }
    else:
        raise Exception('Unexpected GMMA layout {}'.format(gmma_layout))

    # Add common values
    values['element'] = library.DataTypeTag[element]
    values['alignment'] = str(alignment)
    return SubstituteTemplate(emission_str, values)


def max_stages(op, arch):
    """
    Returns the maximum number pipeline stages that can be used for an operation.

    :param op: operation for which the maximum stages should be computed. If stages are
               set via the `op.tile_description.stages` parameter, this setting is ignored
               in the present calculation
    :type op: pycutlass.GemmOperation
    :param arch: compute capability of the device on which the operation will be run
    :type arch: int

    :return: maximum number of pipeline stages that can be used for an operation
    :rtype: int
    """
    smem_per_stage = library.CalculateSmemUsagePerStage(op)
    smem_capacity = library.SharedMemPerCC[arch]
    return int(smem_capacity // smem_per_stage)


class LayoutToStride:
    _variable_first = 'cute::Stride<int64_t, cute::Int<1>, int64_t>'
    _variable_last  = 'cute::Stride<cute::Int<1>, int64_t, int64_t>'

    @staticmethod
    def A(layout):
        """
        Returns the CuTe shape type corresponding to the layout of operand A

        :param layout: layout of the B operand
        :type layout: cutlass.RowMajor or cutlass.ColumnMajor

        :return: C++ declaration of CuTe stride
        :rtype: str
        """
        if layout == cutlass.RowMajor:
            return LayoutToStride._variable_first
        elif layout == cutlass.ColumnMajor:
            return LayoutToStride._variable_last
        else:
            raise Exception('Unsupported layout {}'.format(layout))

    @staticmethod
    def B(layout):
        """
        Returns the CuTe shape type corresponding to the layout of operand B

        :param layout: layout of the B operand
        :type layout: cutlass.RowMajor or cutlass.ColumnMajor

        :return: C++ declaration of CuTe stride
        :rtype: str
        """
        if layout == cutlass.RowMajor:
            return LayoutToStride._variable_last
        elif layout == cutlass.ColumnMajor:
            return LayoutToStride._variable_first
        else:
            raise Exception('Unsupported layout {}'.format(layout))


EMISSION_STR = """
using TileShape_MNK = cute::Shape<_${threadblock_shape_m}, _${threadblock_shape_n}, _${threadblock_shape_k}>;
using ClusterShape_MNK = cute::Shape<_${cluster_shape_m}, _${cluster_shape_n}, _${cluster_shape_k}>;
using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      ${internal_element_A}, ${internal_element_B}, ${element_accumulator}, TileShape_MNK, ${gmma_layout_A}, ${gmma_layout_B}>()));

using SmemLayoutAtomA = decltype(cute::GMMA::smem_selector<${gmma_layout_A}, ${internal_element_A}, _${threadblock_shape_m}, _${threadblock_shape_k}>());
using SmemLayoutAtomB = decltype(cute::GMMA::smem_selector<${gmma_layout_B}, ${internal_element_B}, _${threadblock_shape_n}, _${threadblock_shape_k}>());

using CollectiveOp = typename cutlass::gemm::collective::CollectiveMma<
    ${mainloop_type}<${stage_count}, ClusterShape_MNK${kernel_schedule}>,
    TileShape_MNK,
    ${element_A},
    ${stride_A},
    ${element_B},
    ${stride_B},
    TiledMma,
    ${gmem_tiled_copy_A},
    SmemLayoutAtomA,
    void, // GMMA_SS does not need an SmemCopyAtom
    ${transform_A},
    ${gmem_tiled_copy_B},
    SmemLayoutAtomB,
    void, // GMMA_SS does not need an SmemCopyAtom
    ${transform_B}
>;
"""


def internal_element(element):
    """
    Returns the data type internally used for `element`.

    :param element: data type

    :return: data type used internally
    """
    return cutlass.tfloat32 if element == cutlass.float32 else element


def common_values(op, stage_count, transform_A, transform_B):
    """
    Returns a dictionary containing common values to be substituted in the emission of the
    collective operation declaration. Values specific to a particular collective operation
    should be added to these.

    :param op: GEMM operation for which to build a collective operation
    :type op: pycutlass.GemmOperation
    :param stage_count: number of pipeline stages to use in the operation
    :type stage_count: int
    :param transform_A: transformation to perform on the A operand
    :type transform_A: str
    :param transform_B: transformation to perform on the B operand
    :type transform_B: str

    :return: dictionary containing values to substitute in emission string
    :rtype: dict
    """
    internal_element_a = internal_element(op.A.element)
    internal_element_b = internal_element(op.B.element)

    return {
        'threadblock_shape_m': str(op.tile_description.threadblock_shape[0]),
        'threadblock_shape_n': str(op.tile_description.threadblock_shape[1]),
        'threadblock_shape_k': str(op.tile_description.threadblock_shape[2]),
        'cluster_shape_m': str(op.tile_description.cluster_shape[0]),
        'cluster_shape_n': str(op.tile_description.cluster_shape[1]),
        'cluster_shape_k': str(op.tile_description.cluster_shape[2]),
        'element_A': library.DataTypeTag[op.A.element],
        'element_B': library.DataTypeTag[op.B.element],
        'internal_element_A': library.DataTypeTag[internal_element_a],
        'internal_element_B': library.DataTypeTag[internal_element_b],
        'element_accumulator': library.DataTypeTag[op.accumulator_type()],
        'gmma_layout_A': library.CuTeLayoutTag[RowColMajorToGMMAMajor.A(op.A.layout, internal_element_a)],
        'gmma_layout_B': library.CuTeLayoutTag[RowColMajorToGMMAMajor.B(op.B.layout, internal_element_b)],
        'stride_A': LayoutToStride.A(op.A.layout),
        'stride_B': LayoutToStride.B(op.B.layout),
        'stage_count': str(stage_count),
        'transform_A': transform_A,
        'transform_B': transform_B
    }


def build_gmma_tma(op):
    """
    Builds a collective operation declaration targetting TMA GMMA kernels

    :param op: GEMM operation for which to build a collective operation
    :type op: pycutlass.GemmOperation

    :return: string containing the C++ declaration of collective operation
    :rtype: str
    """
    A_tma_aligned = (library.DataTypeSizeBytes[op.A.element] * op.A.alignment) % tma_alignment_bytes == 0
    B_tma_aligned = (library.DataTypeSizeBytes[op.B.element] * op.B.alignment) % tma_alignment_bytes == 0
    if not A_tma_aligned or not B_tma_aligned:
        raise Exception('Each of the A or B operands must be aligned to {} bytes to use TMA'.format(tma_alignment_bytes))

    max_stage_count = max_stages(op, arch=90)
    if op.tile_description.stages is None:
        op.tile_description.stages = max_stage_count
    elif op.tile_description.stages > max_stage_count:
        raise Exception('Combination of threadblock shape, data types, and number of stages exceeds shared memory capacity.')

    kernel_schedule = 'cutlass::gemm::KernelTmaWarpSpecialized'
    if op.tile_description.persistent:
        kernel_schedule = 'cutlass::gemm::KernelTmaWarpSpecializedPersistent'

    transform_A = 'cute::identity'
    transform_B = 'cute::identity'
    values = common_values(op, op.tile_description.stages, transform_A, transform_B)
    specific_values = {
        'mainloop_type': 'cutlass::gemm::MainloopSm90TmaGmmaWarpSpecialized',
        'kernel_schedule': ', ' + kernel_schedule,
        'gmem_tiled_copy_A': cluster_shape_to_tma(op.tile_description.cluster_shape[1]),
        'gmem_tiled_copy_B': cluster_shape_to_tma(op.tile_description.cluster_shape[0])
    }
    values.update(specific_values)

    return SubstituteTemplate(EMISSION_STR, values)


def build_gmma_cpasync(op):
    """
    Builds a collective operation declaration targetting cp.async GMMA kernels

    :param op: GEMM operation for which to build a collective operation
    :type op: pycutlass.GemmOperation

    :return: string containing the C++ declaration of collective operation
    :rtype: str
    """
    A_cp_async_aligned = (library.DataTypeSizeBytes[op.A.element] * op.A.alignment) % cp_async_min_alignment_bytes == 0
    B_cp_async_aligned = (library.DataTypeSizeBytes[op.B.element] * op.B.alignment) % cp_async_min_alignment_bytes == 0
    if not A_cp_async_aligned or not B_cp_async_aligned:
        raise Exception('Each of the A or B operands must be aligned to {} bytes to use cp.async'.format(cp_async_min_alignment_bytes))

    max_stage_count = max_stages(op, arch=90)
    if op.tile_description.stages is None:
        op.tile_description.stages = max_stage_count
    elif op.tile_description.stages > max_stage_count:
        raise Exception('Combination of threadblock shape, data types, and number of stages exceeds shared memory capacity.')

    transform_A = 'cute::identity'
    transform_B = 'cute::identity'

    thread_count = 128
    cpasync_copy_A = make_cpasync_gmem_tiled_copy(thread_count, op.A.element, op.A.alignment, RowColMajorToGMMAMajor.A(op.A.layout, op.A.element),
                                                  op.tile_description.threadblock_shape[0], op.tile_description.threadblock_shape[2])
    cpasync_copy_B = make_cpasync_gmem_tiled_copy(thread_count, op.B.element, op.B.alignment, RowColMajorToGMMAMajor.B(op.B.layout, op.B.element),
                                                  op.tile_description.threadblock_shape[1], op.tile_description.threadblock_shape[2])

    values = common_values(op, op.tile_description.stages, transform_A, transform_B)
    specific_values = {
        'mainloop_type': 'cutlass::gemm::MainloopSm90CpAsyncGmma',
        'kernel_schedule': '',
        'gmem_tiled_copy_A': cpasync_copy_A,
        'gmem_tiled_copy_B': cpasync_copy_B
    }
    values.update(specific_values)

    return SubstituteTemplate(EMISSION_STR, values)


def build(operation):
    """
    Builds a collective operation declaration targetting cp.async or TMA for GMMA kernels

    :param operation: GEMM operation for which to build a collective operation
    :type operation: pycutlass.GemmOperation

    :return: string containing the C++ declaration of collective operation
    :rtype: str
    """
    A_tma_aligned = (library.DataTypeSizeBytes[operation.A.element] * operation.A.alignment) % tma_alignment_bytes == 0
    B_tma_aligned = (library.DataTypeSizeBytes[operation.B.element] * operation.B.alignment) % tma_alignment_bytes == 0
    tma_correct_size = (library.DataTypeSizeBytes[operation.A.element] == 2 and library.DataTypeSizeBytes[operation.B.element] == 2)
    tma_correct_layout = (operation.A.layout == cutlass.RowMajor or operation.B.layout == cutlass.ColumnMajor)
    if A_tma_aligned and B_tma_aligned and (tma_correct_size or tma_correct_layout):
        return build_gmma_tma(operation)
    else:
        return build_gmma_cpasync(operation)
