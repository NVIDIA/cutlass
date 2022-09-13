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

import ctypes
from pycutlass.library import *

# 12B


class GemmCoord_(ctypes.Structure):
    _fields_ = [
        ("m", ctypes.c_int),
        ("n", ctypes.c_int),
        ("k", ctypes.c_int)
    ]

    def __init__(self, gemm_coord) -> None:
        for field_name, _ in self._fields_:
            setattr(self, field_name, getattr(gemm_coord, field_name)())


class MatrixCoord_(ctypes.Structure):
    _fields_ = [
        ("row", ctypes.c_int),
        ("column", ctypes.c_int)
    ]


dtype2ctype = {
    cutlass.float16: ctypes.c_uint16,
    cutlass.float32: ctypes.c_float,
    cutlass.float64: ctypes.c_double,
    cutlass.int32: ctypes.c_int32
}


def get_gemm_arguments(epilogue_functor):

    _EpilogueOutputOpParams = epilogue_functor.epilogue_type

    class _GemmArguments(ctypes.Structure):
        _fields_ = [
            ("mode", ctypes.c_int),
            ("problem_size", GemmCoord_),
            ("batch_count", ctypes.c_int),
            ("epilogue", _EpilogueOutputOpParams),
            ("ptr_A", ctypes.c_void_p),
            ("ptr_B", ctypes.c_void_p),
            ("ptr_C", ctypes.c_void_p),
            ("ptr_D", ctypes.c_void_p),
            ("batch_stride_A", ctypes.c_longlong),
            ("batch_stride_B", ctypes.c_longlong),
            ("batch_stride_C", ctypes.c_longlong),
            ("batch_stride_D", ctypes.c_longlong),
            ("stride_a", ctypes.c_longlong),
            ("stride_b", ctypes.c_longlong),
            ("stride_c", ctypes.c_longlong),
            ("stride_d", ctypes.c_longlong),
            ("lda", ctypes.c_longlong),
            ("ldb", ctypes.c_longlong),
            ("ldc", ctypes.c_longlong),
            ("ldd", ctypes.c_longlong),
            ("ptr_gather_A_indices", ctypes.c_void_p),
            ("ptr_gether_B_indices", ctypes.c_void_p),
            ("ptr_scatter_D_indices", ctypes.c_void_p)
        ]

    return _GemmArguments, _EpilogueOutputOpParams


###########################################################################################
# GEMM Grouped
###########################################################################################

# include/cutlass/gemm/kernel/gemm_grouped.h

def get_gemm_grouped_arguments(epilogue_functor):
    _EpilogueOutputOpParams = epilogue_functor.epilogue_type

    class _GEMMGroupedArguments(ctypes.Structure):
        _fields_ = [
            ("problem_sizes", ctypes.c_void_p),
            ("problem_count", ctypes.c_int),
            ("threadblock_count", ctypes.c_int),
            ("output_op", _EpilogueOutputOpParams),
            ("ptr_A", ctypes.c_void_p),
            ("ptr_B", ctypes.c_void_p),
            ("ptr_C", ctypes.c_void_p),
            ("ptr_D", ctypes.c_void_p),
            ("lda", ctypes.c_void_p),
            ("ldb", ctypes.c_void_p),
            ("ldc", ctypes.c_void_p),
            ("ldd", ctypes.c_void_p),
            ("host_problem_sizes", ctypes.c_void_p)
        ]

    return _GEMMGroupedArguments, _EpilogueOutputOpParams

############################################################################################
# Convolution2D
############################################################################################


# We use the arguments as the interface


# include/cutlass/conv/conv2d_problem_size.h
# 64B
class Conv2DProblemSize(ctypes.Structure):
    _fields_ = [
        ("N", ctypes.c_int),
        ("H", ctypes.c_int),
        ("W", ctypes.c_int),
        ("C", ctypes.c_int),
        ("P", ctypes.c_int),
        ("Q", ctypes.c_int),
        ("K", ctypes.c_int),
        ("R", ctypes.c_int),
        ("S", ctypes.c_int),
        ("pad_h", ctypes.c_int),
        ("pad_w", ctypes.c_int),
        ("stride_h", ctypes.c_int),
        ("stride_w", ctypes.c_int),
        ("dilation_h", ctypes.c_int),
        ("dilation_w", ctypes.c_int),
        ("mode", ctypes.c_int),  # kCrossCorrelation: 0, kConvolution: 1
        ("split_k_slices", ctypes.c_int),
        ("groups", ctypes.c_int)
    ]

    def __init__(self, problem_size) -> None:
        for field_name, _ in self._fields_:
            setattr(self, field_name, getattr(problem_size, field_name))


# include/cutlass/layout/tensor.h
# 12B
class Layout4D(ctypes.Structure):
    _fields_ = [
        ("stride", ctypes.c_int * 3)
    ]

    def __init__(self, tensor_ref):
        stride = tensor_ref.stride()
        setattr(self, "stride", (stride.at(0), stride.at(1), stride.at(2)))

# TODO: Tensor 5-D takes ("stride", ctypes.c_int * 4)


# include/cutlass/conv/threadblock/conv2d_dgrad_filter_tile_access_iterator_optimized.h
# TensorRef is basically cutlass::TensorRef<Element, Layout>;
# include/cutlass/tensor_ref.h
# 24B
class TensorRef_(ctypes.Structure):
    _fields_ = [
        ("ptr", ctypes.c_void_p),
        ("layout", Layout4D)
    ]

    def __init__(self, tensor_ref):
        setattr(self, "ptr", tensor_ref.data())
        setattr(self, "layout", Layout4D(tensor_ref.layout()))


class TensorRef2D_(ctypes.Structure):
    _fields_ = [
        ("ptr", ctypes.c_void_p),
        ("stride", ctypes.c_int)
    ]


# include/cutlass/conv/kernel/implicit_gemm_convolution.h
# split_k_mode: kNone: 0, kSerial: 1, kParallel: 2, kParallelSerial: 3, kInvalid: 4

def get_conv2d_arguments(epilogue_functor):
    _EpilogueOutputOpParams = epilogue_functor.epilogue_type

    class _Conv2dArguments(ctypes.Structure):
        _fields_ = [
            ("problem_size", Conv2DProblemSize),  # 0
            ("ref_A", TensorRef_),  # 72
            ("ref_B", TensorRef_),  # 96
            ("ref_C", TensorRef_),  # 120
            ("ref_D", TensorRef_),  # 144
            ("output_op", _EpilogueOutputOpParams),  # 168
            ("split_k_mode", ctypes.c_int)  # 192
        ]

    return _Conv2dArguments, _EpilogueOutputOpParams


############################################################################################
# Reduction
############################################################################################


def get_reduction_params(epilogue_functor):
    _EpilogueOutputParams = epilogue_functor.epilogue_type

    class _ReductionParams(ctypes.Structure):
        _fields_ = [
            ("problem_size", MatrixCoord_),
            ("partitions", ctypes.c_int),
            ("partition_stride", ctypes.c_longlong),
            ("workspace", TensorRef2D_),
            ("destination", TensorRef2D_),
            ("source", TensorRef2D_),
            ("output_op", _EpilogueOutputParams)
        ]
    return _ReductionParams, _EpilogueOutputParams
