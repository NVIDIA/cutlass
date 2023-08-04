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
Util Functions for Conv2d Test
"""
import torch
import cutlass
import unittest
import cutlass_bindings
from cutlass.utils.datatypes import binding_type, binding_opclass
from cutlass.backend.test.conv2d_testbed import Conv2dLauncher, getTensorRef, getTensorView
from cutlass.backend.utils.device import device_cc
from cutlass.backend.test.utils import get_name_conv2d
import numpy as np

def conv2d_few_channel_problemsizes(channels):
    problem_sizes = [
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 8, 8, channels),
            cutlass_bindings.Tensor4DCoord(16, 3, 3, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(2, 2),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 16, 16, channels),
            cutlass_bindings.Tensor4DCoord(16, 3, 3, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(2, 2),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 16, 16, channels),
            cutlass_bindings.Tensor4DCoord(16, 7, 7, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 224, 224, channels),
            cutlass_bindings.Tensor4DCoord(32, 7, 7, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 224, 224, channels),
            cutlass_bindings.Tensor4DCoord(64, 7, 7, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(2, 2),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 224, 224, channels),
            cutlass_bindings.Tensor4DCoord(64, 5, 5, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 224, 224, channels),
            cutlass_bindings.Tensor4DCoord(64, 5, 5, channels),
            cutlass_bindings.Tensor4DCoord(1, 1, 1, 1),
            cutlass_bindings.MatrixCoord(2, 2),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
    ]

    return problem_sizes

torch_dtype = {
    cutlass.DataType.f16: torch.float16,
    cutlass.DataType.f32: torch.float32,
    cutlass.DataType.f64: torch.float64
}

numpy_dtype = {
    cutlass.DataType.f16: np.float16,
    cutlass.DataType.f32: np.float32,
    cutlass.DataType.f64: np.float64
}


def validate_problem_size(ps, conv_kind, split_k_slices):
    P = (ps.H + 2 * ps.pad_h - ps.dilation_h * (ps.R - 1) - 1) // ps.stride_h + 1
    Q = (ps.W + 2 * ps.pad_w - ps.dilation_w * (ps.S - 1) - 1) // ps.stride_w + 1
    if P != ps.P or Q != ps.Q:
        return False

    # Split-K (serial or parallel) is not supported for strided dgrad
    if conv_kind == "dgrad" and split_k_slices > 1 and (ps.stride_h > 1 or ps.stride_w > 1):
        return False
    return True


# Override the backend launcher
class Conv2dLauncherFrontend(Conv2dLauncher):
    def __init__(self, plan: cutlass.Conv2d, seed: int = 80, backend="numpy"):
        self.operation = plan
        self.conv_kind = plan.conv_kind
        self.seed = seed
        self.backend = backend
        
        self.dtype_A = plan._element_a
        self.dtype_B = plan._element_b
        self.dtype_C = plan._element_c
        self.dtype_acc = plan._element_accumulator
        
        self.layout_A = cutlass_bindings.TensorNHWC
        self.layout_B = cutlass_bindings.TensorNHWC
        self.layout_C = cutlass_bindings.TensorNHWC
        self.layout_D = cutlass_bindings.TensorNHWC
        
        self.element_compute = cutlass_bindings.float32
        self.enable_cached_results = True
        
        # Get randomization_max
        if self.dtype_A in [cutlass.DataType.f16, cutlass.DataType.bf16]:
            if self.dtype_acc in [cutlass.DataType.f16, cutlass.DataType.bf16]:
                self.randomization_max = 2
            else:
                self.randomization_max = 3
        else:
            self.randomization_max = 7
            
        self.activation = plan.activation
        
        self.host_conv2d = cutlass_bindings.test.conv.host.conv2d
            
    
    def set_seed(self):
        if self.backend == "numpy":
            np.random.seed(self.seed)
        else:
            torch.manual_seed(self.seed)
    
    def uniform_init(self, size, dtype):
        if self.backend == "numpy":
            return super().uniform_init(size, numpy_dtype[dtype])
        else:
            tensor = torch.ceil(
                torch.empty(size=size, dtype=torch_dtype[dtype], device="cuda").uniform_(-self.randomization_max - 0.5, self.randomization_max - 0.5)
            ).to(memory_format=torch.channels_last)
            return tensor
    
    def zeros_like(self, tensor):
        if self.backend == "numpy":
            return np.zeros_like(tensor)
        else:
            return torch.zeros_like(tensor).to(memory_format=torch.channels_last)
    
    def reference(self, ps, A, B, C, alpha, beta, activation):
        if self.backend == "numpy":
            numpy_result = self.host_reference(ps, A, B, C, alpha, beta, activation)
            return numpy_result
        else:
            if self.conv_kind == cutlass_bindings.conv.Operator.fprop:
                torch_result = alpha * torch.ops.aten.conv2d(
                    A,
                    B,
                    stride=(ps.stride_h, ps.stride_w),
                    padding=(ps.pad_h, ps.pad_w),
                    dilation=(ps.dilation_h, ps.dilation_w)
                ) + beta * C
            elif self.conv_kind == cutlass_bindings.conv.Operator.dgrad:
                torch_result = alpha * torch.nn.grad.conv2d_input(
                    (ps.N, ps.C, ps.H, ps.W),
                    B,
                    A,
                    padding=(ps.pad_h, ps.pad_w),
                    stride=(ps.stride_h, ps.stride_w)
                ) + beta * C
            elif self.conv_kind == cutlass_bindings.conv.Operator.wgrad:
                torch_result = alpha * torch.nn.grad.conv2d_weight(
                    B,
                    (ps.K, ps.C, ps.R, ps.S),
                    A,
                    padding=(ps.pad_h, ps.pad_w),
                    stride=(ps.stride_h, ps.stride_w)
                ) + beta * C
            else:
                raise Exception(f"Conv kind {self.conv_kind} is currently unsupported.")
            
            if activation == cutlass.backend.epilogue.relu:
                torch_result = torch.nn.functional.relu(torch_result)
            elif activation == cutlass.backend.epilogue.leaky_relu:
                torch_result = torch.nn.functional.leaky_relu(torch_result, 0.5)
            
            return torch_result
    
    def host_reference(self, problem_size, tensor_A, tensor_B, tensor_C, alpha, beta, activation):
        if self.element_compute == cutlass_bindings.float16:
            alpha = cutlass_bindings.float16(alpha)
            beta = cutlass_bindings.float16(beta)
        elif self.element_compute == cutlass_bindings.int32:
            alpha = int(alpha)
            beta = int(beta)
        else:
            alpha = alpha
            beta = beta

        # If cached result is loaded
        cached_result_loaded = False

        if self.enable_cached_results:
            # Get problem key
            cached_test_key = cutlass_bindings.test.conv.host.CreateCachedConv2dTestKey(
                self.conv_kind,
                problem_size,
                alpha,
                beta,
                getTensorView(
                    tensor_A, self.layout_A, self.conv_kind, problem_size, "a"
                ),
                getTensorView(
                    tensor_B, self.layout_B, self.conv_kind, problem_size, "b"
                ),
                getTensorView(
                    tensor_C, self.layout_C, self.conv_kind, problem_size, "c"
                ),
            )
            
            cached_test_key.problem = cached_test_key.problem + f"_{activation.tag.split('::')[-1]}"

            cached_test_result = cutlass_bindings.test.conv.host.CachedTestResult()

            conv2d_result_cache_name = "cached_results_SM%d_%d.txt" % (
                self.operation.arch,
                self.seed,
            )

            cached_results = cutlass_bindings.test.conv.host.CachedTestResultListing(
                conv2d_result_cache_name
            )
            # CachedTestResultListing cached_results(conv2d_result_cache_name);
            cached = cached_results.find(cached_test_key)
            cached_result_loaded = cached[0]
            if cached_result_loaded:
                cached_test_result = cached[1]

        if not cached_result_loaded:
            # Compute the conv2d on host
            tensor_D_ref = np.ones_like(tensor_C)
            tensor_ref_A = getTensorRef(
                tensor_A, self.layout_A, self.conv_kind, problem_size, "a"
            )
            tensor_ref_B = getTensorRef(
                tensor_B, self.layout_B, self.conv_kind, problem_size, "b"
            )
            tensor_ref_C = getTensorRef(
                tensor_C, self.layout_C, self.conv_kind, problem_size, "c"
            )
            tensor_ref_D_ref = getTensorRef(
                tensor_D_ref, self.layout_D, self.conv_kind, problem_size, "d"
            )

            self.host_conv2d(
                self.conv_kind,
                problem_size,
                tensor_ref_A,
                tensor_ref_B,
                tensor_ref_C,
                tensor_ref_D_ref,
                alpha,
                beta,
            )
            
            if activation == cutlass.backend.epilogue.leaky_relu:
                tensor_D_ref = activation.numpy(tensor_D_ref, 0.5)
            else:
                tensor_D_ref = activation.numpy(tensor_D_ref)

            tensor_view_D_ref = getTensorView(
                tensor_D_ref, self.layout_D, self.conv_kind, problem_size, "d"
            )

            if self.enable_cached_results:
                cached_test_result.D = cutlass_bindings.test.conv.host.TensorHash(
                    tensor_view_D_ref
                )
                cached_results = (
                    cutlass_bindings.test.conv.host.CachedTestResultListing(
                        conv2d_result_cache_name
                    )
                )
                cached_results.append(cached_test_key, cached_test_result)
                cached_results.write(conv2d_result_cache_name)
            else:
                return tensor_D_ref

        return cached_test_result.D
    
    def equal(self, tensor_D, tensor_D_ref, problem_size):
        if self.backend == "numpy":
            return super().equal(tensor_D, tensor_D_ref, problem_size)
        else:
            torch.cuda.synchronize()
            return torch.equal(tensor_D, tensor_D_ref)
                
    
    def run(self, ps, split_k_mode=cutlass_bindings.conv.SplitKMode.Serial, split_k_slices=1, alpha=1.0, beta=0.0):
        
        #
        # Initialize input and output tensors
        #
        if self.conv_kind == cutlass_bindings.conv.Operator.fprop:
            if self.backend == "torch":
                tensor_A_size = (ps.N, ps.C, ps.H, ps.W)
                tensor_B_size = (ps.K, ps.C, ps.R, ps.S)
                tensor_C_size = (ps.N, ps.K, ps.P, ps.Q)
            else:
                tensor_A_size = (ps.N, ps.H, ps.W, ps.C)
                tensor_B_size = (ps.K, ps.R, ps.S, ps.C)
                tensor_C_size = (ps.N, ps.P, ps.Q, ps.K)
        elif self.conv_kind == cutlass_bindings.conv.Operator.dgrad:
            if self.backend == "torch":
                tensor_A_size = (ps.N, ps.K, ps.P, ps.Q)
                tensor_B_size = (ps.K, ps.C, ps.R, ps.S)
                tensor_C_size = (ps.N, ps.C, ps.H, ps.W)
            else:
                tensor_A_size = (ps.N, ps.P, ps.Q, ps.K)
                tensor_B_size = (ps.K, ps.R, ps.S, ps.C)
                tensor_C_size = (ps.N, ps.H, ps.W, ps.C)
        elif self.conv_kind == cutlass_bindings.conv.Operator.wgrad:
            if self.backend == "torch":
                tensor_A_size = (ps.N, ps.K, ps.P, ps.Q)
                tensor_B_size = (ps.N, ps.C, ps.H, ps.W)
                tensor_C_size = (ps.K, ps.C, ps.R, ps.S)
            else:
                tensor_A_size = (ps.N, ps.P, ps.Q, ps.K)
                tensor_B_size = (ps.N, ps.H, ps.W, ps.C)
                tensor_C_size = (ps.K, ps.R, ps.S, ps.C)
        else:
            raise Exception(f"Conv kind {self.conv_kind} is not supported")

        self.set_seed()

        tensor_A = self.uniform_init(size=tensor_A_size, dtype=self.dtype_A)
        tensor_B = self.uniform_init(size=tensor_B_size, dtype=self.dtype_B)
        tensor_C = self.uniform_init(size=tensor_C_size, dtype=self.dtype_C)
        tensor_D = self.zeros_like(tensor_C)
        
        self.operation.run(tensor_A, tensor_B, tensor_C, tensor_D, 
            stride=(ps.stride_h, ps.stride_w),
            padding=(ps.pad_h, ps.pad_w),
            dilation=(ps.dilation_h, ps.dilation_w),
            alpha=alpha, beta=beta,
            split_k=(split_k_mode, split_k_slices))
        
        tensor_D_ref = self.reference(
            ps, tensor_A, tensor_B, tensor_C, alpha, beta, self.activation
        )
        
        return self.equal(tensor_D, tensor_D_ref, ps)


def add_test(
    cls, 
    cc, 
    conv_kind,
    problem_sizes,
    element,
    element_accumulator,
    element_output,
    opclass,
    threadblock_shape,
    warp_count,
    instruction_shape,
    stages,
    iterator_algorithm=None,
    swizzle=None,
    split_k_mode="serial",
    split_k_slices=1,
    activation = "identity"
):
    """Create a test-running function with the given specification"""
    test_name = get_name_conv2d(
        cc, conv_kind, element, element_accumulator,
        element_output, opclass, threadblock_shape, warp_count, instruction_shape, stages,
        iterator_algorithm, swizzle, split_k_mode, split_k_slices, activation)
    
    def run(self):
        # Create the plan
        plan = cutlass.Conv2d(
            kind=conv_kind,
            element=element,
            element_accumulator=element_accumulator,
            element_C=element_output,
            element_D=element_output
        )
        
        # Set the opclass
        plan.opclass = opclass
        # Set the tile description
        td = {
            "threadblock_shape": threadblock_shape,
            "warp_count": warp_count,
            "stages": stages,
            "instruction_shape": instruction_shape,
        }

        plan.tile_description = td
        # Set iterator algorithm
        if iterator_algorithm is not None:
            plan.iterator_algorithm = iterator_algorithm
        # Set swizzling functor
        if swizzle is not None:
            plan.swizzling_stride = swizzle
        
        if activation != "identity":
            if activation == "leaky_relu":
                plan.activation = (cutlass.epilogue.leaky_relu, 0.5)
            else:
                plan.activation = getattr(cutlass.epilogue, activation)
        
        conv2d_launcher = Conv2dLauncherFrontend(plan, 80, backend="numpy")
        
        for ps in problem_sizes:
            if not validate_problem_size(ps, conv_kind, split_k_slices): continue
            
            self.assertTrue(
                conv2d_launcher.run(ps, split_k_mode, split_k_slices, 1.0, 0.5)
            )
    
    setattr(cls, test_name, run)
    
    return run


def get_conv_problems():  
    # 64: minimum channel size
    conv_problems = list(cutlass_bindings.test.conv.TestbedConv2dProblemSizes(64).conv2d_default_sizes)
    # Insert alignment 4 & 2 tests
    conv_problems += [
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 4, 4, 12),
            cutlass_bindings.Tensor4DCoord(8, 3, 3, 12),
            cutlass_bindings.Tensor4DCoord(0, 0, 0, 0),
            cutlass_bindings.MatrixCoord(3, 3),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 4, 4, 14),
            cutlass_bindings.Tensor4DCoord(8, 3, 3, 14),
            cutlass_bindings.Tensor4DCoord(0, 0, 0, 0),
            cutlass_bindings.MatrixCoord(3, 3),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
        cutlass_bindings.conv.Conv2dProblemSize(
            cutlass_bindings.Tensor4DCoord(1, 23, 56, 98),
            cutlass_bindings.Tensor4DCoord(128, 3, 3, 98),
            cutlass_bindings.Tensor4DCoord(4, 0, 5, 0),
            cutlass_bindings.MatrixCoord(3, 3),
            cutlass_bindings.MatrixCoord(1, 1),
            cutlass_bindings.conv.Mode.cross_correlation,
            1, 1
        ),
    ]
    
    return conv_problems
