# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

from collections.abc import Callable
from itertools import product
from typing import ClassVar

import cuda.bindings.driver as cuda

from cutlass_api.arguments import ElementwiseArguments, EpilogueArguments
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import (
    ElementwiseOperandsMetadata,
    KernelMetadata,
    TensorAttributes,
)
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.utils import to_cuda_stream

import cutlass
import cutlass.cute as cute

"""
An Elementwise Addition kernel using CuTe DSL:
   out = A + B
"""


@CuTeDSLProvider.register
class ElementwiseAddKernel(CuteDslKernel):
    _supported_dtypes: ClassVar[list[type[cutlass.Numeric]]] = [
        cutlass.Float32,
        cutlass.Float16,
    ]

    def __init__(self, metadata: KernelMetadata):
        self.metadata = metadata
        self.impl = ElementwiseAddKernelImpl()

    def compile(self, args: ElementwiseArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        compiled_kernel = self.cute_compile(self.impl, args.A, args.B, args.out, stream)
        return CompiledArtifact(compiled_kernel, self)

    def _run(
        self,
        args: ElementwiseArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_kernel = compiled_artifact.compiled_obj
        self.cute_run(compiled_kernel, args.A, args.B, args.out, stream)

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["ElementwiseAddKernel"]:
        if epilogue_args is not None:
            return []

        min_cc = 80
        if cc is not None and cc < min_cc:
            return []

        stride_names = {
            (0, 1): "t",  # row major
            (1, 0): "n",  # column major
        }

        kernel_list = []
        for dtype in ElementwiseAddKernel._supported_dtypes:
            alignment = 128 // dtype.width
            for stride_A, stride_B, stride_out in product(
                stride_names.keys(), repeat=3
            ):
                kernel_name = (
                    "cutedsl.ElementwiseAddKernel"
                    + f"_A{dtype}_{stride_names[stride_A]}"
                    + f"_B{dtype}_{stride_names[stride_B]}"
                    + f"_out{dtype}_{stride_names[stride_out]}"
                )

                operands = ElementwiseOperandsMetadata(
                    A=TensorAttributes(
                        dtype=dtype, stride=stride_A, alignment=alignment
                    ),
                    B=TensorAttributes(
                        dtype=dtype, stride=stride_B, alignment=alignment
                    ),
                    out=TensorAttributes(
                        dtype=dtype, stride=stride_out, alignment=alignment
                    ),
                )
                metadata = KernelMetadata(
                    operands=operands, kernel_name=kernel_name, kernel_class=ElementwiseAddKernel, min_cc=min_cc
                )
                if metadata_filter(metadata):
                    kernel_list.append(ElementwiseAddKernel(metadata))

        return kernel_list


class ElementwiseAddKernelImpl:
    @cute.jit
    def __call__(
        self, mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor, stream: cuda.CUstream
    ):
        copy_bits: cutlass.Constexpr = 128
        dtype = mA.element_type
        vector_size = copy_bits // dtype.width

        thr_layout = cute.make_ordered_layout((4, 32), order=(1, 0))
        val_layout = cute.make_ordered_layout((4, vector_size), order=(1, 0))
        tiler_mn, tv_layout = cute.make_layout_tv(thr_layout, val_layout)

        gA = cute.zipped_divide(mA, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
        gB = cute.zipped_divide(mB, tiler_mn)  # ((TileM,TileN),(RestM,RestN))
        gC = cute.zipped_divide(mC, tiler_mn)  # ((TileM,TileN),(RestM,RestN))

        idC = cute.make_identity_tensor(mC.shape)
        cC = cute.zipped_divide(idC, tiler=tiler_mn)

        self.kernel(gA, gB, gC, cC, mC.shape, thr_layout, val_layout).launch(
            grid=[cute.size(gC, mode=[1]), 1, 1],
            block=[cute.size(tv_layout, mode=[0]), 1, 1],
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        gA: cute.Tensor,
        gB: cute.Tensor,
        gC: cute.Tensor,
        cC: cute.Tensor,  # coordinate tensor
        shape: cute.Shape,
        thr_layout: cute.Layout,
        val_layout: cute.Layout,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()

        # slice for CTAs
        # logical id -> address
        blk_coord = ((None, None), bidx)
        blkA = gA[blk_coord]  # (TileM,TileN)
        blkB = gB[blk_coord]  # (TileM,TileN)
        blkC = gC[blk_coord]  # (TileM,TileN)
        blkCrd = cC[blk_coord]  # (TileM, TileN)

        # declare the atoms which will be used later for memory copy
        copy_atom_load = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), gA.element_type
        )
        copy_atom_store = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), gC.element_type
        )

        tiled_copy_A = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
        tiled_copy_B = cute.make_tiled_copy_tv(copy_atom_load, thr_layout, val_layout)
        tiled_copy_C = cute.make_tiled_copy_tv(copy_atom_store, thr_layout, val_layout)

        thr_copy_A = tiled_copy_A.get_slice(tidx)
        thr_copy_B = tiled_copy_B.get_slice(tidx)
        thr_copy_C = tiled_copy_C.get_slice(tidx)

        thrA = thr_copy_A.partition_S(blkA)
        thrB = thr_copy_B.partition_S(blkB)
        thrC = thr_copy_C.partition_S(blkC)

        # allocate fragments for gmem->rmem
        frgA = cute.make_fragment_like(thrA)
        frgB = cute.make_fragment_like(thrB)
        frgC = cute.make_fragment_like(thrC)

        thrCrd = thr_copy_C.partition_S(blkCrd)
        frgPred = cute.make_rmem_tensor(thrCrd.shape, cutlass.Boolean)

        for i in range(0, cute.size(frgPred), 1):
            val = cute.elem_less(thrCrd[i], shape)
            frgPred[i] = val

        # Print per thread predicate mask
        # if tidx == 0 and bidx == 0:
        #     cute.printf("block_dim = {}", cute.arch.grid_dim())
        #     cute.printf("shape = {}", shape)
        #     cute.print_tensor(thrA)
        #     cute.print_tensor(thrB)
        #     cute.print_tensor(frgPred)

        ##########################################################
        # Move data to reg address space
        ##########################################################

        cute.copy(copy_atom_load, thrA, frgA, pred=frgPred)
        cute.copy(copy_atom_load, thrB, frgB, pred=frgPred)

        # if tidx == 0 and bidx == 0:
        #     cute.print_tensor(frgA)
        #     cute.print_tensor(frgB)

        # Load data before use. The compiler will optimize the copy and load
        # operations to convert some memory ld/st into register uses.
        result = frgA.load() + frgB.load()

        # Save the results back to registers. Here we reuse b's registers.
        frgC.store(result)

        # Copy the results back to c
        cute.copy(copy_atom_store, frgC, thrC, pred=frgPred)
