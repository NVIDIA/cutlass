################################################################################
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
################################################################################
import numpy as np
import pycutlass
from pycutlass import *
import cutlass
from bfloat16 import bfloat16

import argparse


# parse the arguments
parser = argparse.ArgumentParser(
    description="Launch CUTLASS GEMM kernels from python: 'D = alpha * A * B + beta * C'")

# Operation description
# math instruction description
parser.add_argument("-i", "--instruction_shape",
                    default=[1, 1, 1], nargs=3, type=int, 
                    help="This option describes the size of MMA op")
parser.add_argument("-ta", "--element_a", default="float32", type=str,
                    choices=['float64', 'float32', 'float16', 'bfloat16', 'int32', 'int8'], 
                    help='Data type of elements in input tensor A')
parser.add_argument("-tb", "--element_b", default="float32", type=str,
                    choices=['float64', 'float32', 'float16', 'bfloat16', 'int32', 'int8'], 
                    help='Data type of elements in input tensor B')
parser.add_argument("-tc", "--element_c", default="float32", type=str,
                    choices=['float64', 'float32', 'float16', 'bfloat16', 'int32', 'int8'], 
                    help='Data type of elements in input tensor C and output tensor D')
parser.add_argument("-tacc", "--element_acc", default="float32", type=str,
                    choices=['float64', 'float32', 'float16', 'bfloat16', 'int32', 'int8'], 
                    help='Data type of accumulator')
parser.add_argument('-m', "--math", default="multiply_add",
                    type=str, choices=["multiply_add", "multiply_add_fast_bf16", "multiply_add_fast_f32"], help="math instruction")
parser.add_argument('-op', "--opcode", default="simt", type=str,
                    choices=["Simt", 'TensorOp'], 
                    help="This option describes whether you want to use tensor \
                        cores (TensorOp) or regular SIMT cores (Simt) on GPU SM")
# tile description
parser.add_argument("-b", "--threadblock_shape",
                    default=[128, 128, 8], nargs=3, type=int, 
                    help="This option describes the tile size a thread block with compute")
parser.add_argument("-s", "--stages", default=4,
                    type=int, help="Number of pipelines you want to use")
parser.add_argument("-w", "--warp_count", default=[4, 2, 1], nargs=3, type=int, 
                    help="This option describes the number of warps along M, N, and K of the threadblock")
parser.add_argument("-cc", "--compute_capability", default=80,
                    type=int, help="This option describes CUDA SM architecture number")
# A
parser.add_argument('-la', "--layout_a", default="RowMajor", type=str, choices=[
                    "RowMajor", "ColumnMajor", "RowMajorInterleaved32", "ColumnMajorInterleaved32"], 
                    help="Memory layout of input tensor A")
parser.add_argument('-aa', '--alignment_a', default=1,
                    type=int, help="Memory alignement of input tensor A")
# B
parser.add_argument('-lb', "--layout_b", default="RowMajor", type=str, choices=[
                    "RowMajor", "ColumnMajor", "RowMajorInterleaved32", "ColumnMajorInterleaved32"], 
                    help="Memory layout of input tensor B")
parser.add_argument('-ab', '--alignment_b', default=1,
                    type=int, help="Memory alignment of input tensor B")
# C
parser.add_argument('-lc', "--layout_c", default="RowMajor", type=str, choices=[
                    "RowMajor", "ColumnMajor", "RowMajorInterleaved32", "ColumnMajorInterleaved32"], 
                    help="Memory layout of input tensor C and output tensor D")
parser.add_argument('-ac', '--alignment_c', default=1,
                    type=int, help="Memory alignment of input tensor C and output tensor D")
# epilogue
parser.add_argument("-te", "--element_epilogue", default="float32", type=str,
                    choices=['float64', 'float32', 'float16', 'bfloat16'], help='Epilogue datatype')
parser.add_argument("-ep", "--epilogue_functor", default="LinearCombination",
                    type=str, choices=['LinearCombination', 'FastLinearCombinationClamp', 'LinearCombinationClamp'], 
                    help="This option describes the epilogue part of the kernel")
# swizzling
parser.add_argument("-sw", "--swizzling_functor", default="IdentitySwizzle1", type=str, choices=[
                    "IdentitySwizzle1", "IdentitySwizzle2", "IdentitySwizzle4", "IdentitySwizzle8", "HorizontalSwizzle"],
                    help="This option describes how thread blocks are scheduled on GPU")

# Argument
parser.add_argument("-p", "--problem_size",
                    default=[128, 128, 128], nargs=3, type=int, 
                    help="GEMM problem size M, N, K")
parser.add_argument("-alpha", "--alpha", default=1.0, type=float, 
                    help="Scaling factor of A * B")
parser.add_argument("-beta", "--beta", default=0.0, type=float, 
                    help="Scaling factor of C")
parser.add_argument("-gm", "--gemm_mode", default="Gemm", type=str,
                    choices=["Gemm", "GemmSplitKParallel"], 
                    help="GEMM mode. Gemm is used for non-splitK or serial-splitK. \
                        GemmSplitKParallel is used for parallel splitK")
parser.add_argument('-k', '--split_k_slices', default=1,
                    type=int, help="Number of split-k partitions. (default 1)")

parser.add_argument('--print_cuda', action="store_true",
                    help="print the underlying CUDA kernel")

# parser.add_argument('-h', '--help', action="store_true",
#                     help="print help information")

try:
    args = parser.parse_args()
except:
    sys.exit(0)

pycutlass.get_memory_pool(init_pool_size=2**30, max_pool_size=2**32)

element_a = getattr(cutlass, args.element_a)
element_b = getattr(cutlass, args.element_b)
element_c = getattr(cutlass, args.element_c)
element_acc = getattr(cutlass, args.element_acc)
math_operation = getattr(MathOperation, args.math)
opclass = getattr(cutlass.OpClass, args.opcode)

math_inst = MathInstruction(
    args.instruction_shape, element_a, element_b,
    element_acc, opclass, math_operation
)

tile_description = TileDescription(
    args.threadblock_shape, args.stages, args.warp_count,
    math_inst, args.compute_capability, args.compute_capability
)

layout_a = getattr(cutlass, args.layout_a)
layout_b = getattr(cutlass, args.layout_b)
layout_c = getattr(cutlass, args.layout_c)

A = TensorDescription(
    element_a, layout_a, args.alignment_a
)

B = TensorDescription(
    element_b, layout_b, args.alignment_b
)

C = TensorDescription(
    element_c, layout_c, args.alignment_c
)

element_epilogue = getattr(cutlass, args.element_epilogue)
epilogue_functor = getattr(EpilogueFunctor, args.epilogue_functor)
swizzling_functor = getattr(cutlass, args.swizzling_functor)

operation = GemmOperationUniversal(
    arch=args.compute_capability, tile_description=tile_description,
    A=A, B=B, C=C, element_epilogue=element_epilogue,
    epilogue_functor=epilogue_functor, swizzling_functor=swizzling_functor
)

if args.print_cuda:
    print(operation.rt_module.emit())

operations = [operation, ]

if args.gemm_mode == "GemmSplitKParallel":
    reduction_operation = ReductionOperation(
        shape=cutlass.MatrixCoord(4, 32 * C.alignment),
        C=C, element_accumulator=element_acc,
        element_compute=element_epilogue,
        count=C.alignment
    )
    operations.append(reduction_operation)

pycutlass.compiler.add_module(operations)

# User-provide inputs

problem_size = cutlass.gemm.GemmCoord(
    args.problem_size[0], args.problem_size[1], args.problem_size[2])

if args.element_a != "int8":
    if args.element_a == "bfloat16":
        tensor_A = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.m()
                                                                       * problem_size.k(),))).astype(bfloat16)
    else:
        tensor_A = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.m()
                                                                       * problem_size.k(),))).astype(getattr(np, args.element_a))
else:
    tensor_A = np.random.uniform(low=-2, high=2, size=(problem_size.m()
                                                       * problem_size.k(),)).astype(getattr(np, args.element_a))

if args.element_b != "int8":
    if args.element_b == "bfloat16":
        tensor_B = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.k()
                                                                       * problem_size.n(),))).astype(bfloat16)
    else:
        tensor_B = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.k()
                                                                       * problem_size.n(),))).astype(getattr(np, args.element_b))
else:
    tensor_B = np.random.uniform(low=-2, high=2, size=(problem_size.k()
                                                       * problem_size.n(),)).astype(getattr(np, args.element_b))

if args.element_c != "int8":
    if args.element_c == "bfloat16":
        tensor_C = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.m()
                                                                       * problem_size.n(),))).astype(bfloat16)
    else:
        tensor_C = np.ceil(np.random.uniform(low=-8.5, high=7.5, size=(problem_size.m()
                                                                       * problem_size.n(),))).astype(getattr(np, args.element_c))
else:
    tensor_C = np.random.uniform(low=-2, high=2, size=(problem_size.m()
                                                       * problem_size.n(),)).astype(getattr(np, args.element_c))

tensor_D = np.ones_like(tensor_C)

arguments = GemmArguments(
    operation=operation, problem_size=problem_size,
    A=tensor_A, B=tensor_B, C=tensor_C, D=tensor_D,
    output_op=LinearCombinationFunctorArguments(args.alpha, args.beta),
    gemm_mode=getattr(cutlass.gemm.Mode, args.gemm_mode),
    split_k_slices=args.split_k_slices
)

if args.gemm_mode == "GemmSplitKParallel":
    reduction_arguments = ReductionArguments(
        operation=reduction_operation,
        problem_size=[problem_size.m(), problem_size.n()],
        partitions=args.split_k_slices, workspace=arguments.ptr_D,
        destination=tensor_D, source=tensor_C,
        output_op=LinearCombinationFunctorArguments(args.alpha, args.beta)
    )

operation.run(arguments)

if args.gemm_mode == "GemmSplitKParallel":
    reduction_operation.run(reduction_arguments)
    reduction_arguments.sync()
else:
    arguments.sync()

# run the host reference module
reference = ReferenceModule(A, B, C)
tensor_D_ref = reference.run(
    tensor_A, tensor_B, tensor_C, problem_size, args.alpha, args.beta)

assert np.array_equal(tensor_D, tensor_D_ref)

print("Passed.")
