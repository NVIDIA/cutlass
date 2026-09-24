# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Fuse FP32 LayerScale + residual, optionally producing an Affine output too.

Residual mul/add retain separate roundings; Affine matches torch.addcmul's FMA.
Inputs are CUDA FP32 tensors with logical shape (batch, tokens, channels).
Token-major and channel-major dense layouts need no materialized transpose.
This example supports inference only. See resmlp_inference.py for a consumer.
"""
from collections.abc import Callable

import torch
import cutlass
import cutlass.cute as cute
from cuda.bindings.driver import CUstream
from cutlass._mlir.dialects import llvm
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.cute.runtime import from_dlpack, make_fake_stream


@dsl_user_op
def residual_add(x: cutlass.Float32, y: cutlass.Float32, scale: cutlass.Float32,
                 *, loc=None, ip=None) -> cutlass.Float32:
    # Separate torch mul/add round twice. Contracting them changes the model.
    value = llvm.inline_asm(
        cutlass.Float32.mlir_type,
        [x.ir_value(loc=loc, ip=ip), y.ir_value(loc=loc, ip=ip), scale.ir_value(loc=loc, ip=ip)],
        "{ .reg .f32 product; mul.rn.f32 product, $2, $3; add.rn.f32 $0, $1, product; }",
        "=f,f,f,f", has_side_effects=False, is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT, loc=loc, ip=ip,
    )
    return cutlass.Float32(value)


@dsl_user_op
def affine(x: cutlass.Float32, alpha: cutlass.Float32, beta: cutlass.Float32,
           *, loc=None, ip=None) -> cutlass.Float32:
    value = llvm.inline_asm(
        cutlass.Float32.mlir_type,
        [x.ir_value(loc=loc, ip=ip), alpha.ir_value(loc=loc, ip=ip), beta.ir_value(loc=loc, ip=ip)],
        "fma.rn.f32 $0, $1, $2, $3;", "=f,f,f,f",
        has_side_effects=False, is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT, loc=loc, ip=ip,
    )
    return cutlass.Float32(value)


@cute.kernel
def fused_kernel(x: cute.Tensor, y: cute.Tensor, scale: cute.Tensor,
                 alpha: cute.Tensor, beta: cute.Tensor, residual: cute.Tensor,
                 normalized: cute.Tensor, normalize: cutlass.Constexpr):
    tid = cute.arch.block_idx()[0] * 256 + cute.arch.thread_idx()[0]
    batch, tokens, channels = x.shape
    if tid < batch * tokens * channels:
        # Keep the native dense (B, N, C) view's physical token-major order.
        if cutlass.const_expr(x.stride[1] == 1):
            b, n, c = tid // (tokens * channels), tid % tokens, tid // tokens % channels
        else:
            b, n, c = tid // (tokens * channels), tid // channels % tokens, tid % channels
        value = residual_add(x[b, n, c], y[b, n, c], scale[c])
        residual[b, n, c] = value
        if cutlass.const_expr(normalize):
            normalized[b, n, c] = affine(value, alpha[0, 0, c], beta[0, 0, c])


@cute.jit
def launch(x: cute.Tensor, y: cute.Tensor, scale: cute.Tensor,
           alpha: cute.Tensor, beta: cute.Tensor, residual: cute.Tensor,
           normalized: cute.Tensor, normalize: cutlass.Constexpr, stream: CUstream):
    fused_kernel(x, y, scale, alpha, beta, residual, normalized, normalize).launch(
        grid=(cute.ceil_div(cute.size(x.shape), 256), 1, 1), block=(256, 1, 1), stream=stream
    )


class ResidualFusion:
    def __init__(self) -> None:
        self.compiled: dict[tuple, Callable[..., None]] = {}
        self.calls = 0

    def __call__(self, x: torch.Tensor, y: torch.Tensor, scale: torch.Tensor,
                 alpha: torch.Tensor, beta: torch.Tensor,
                 normalize: bool) -> tuple[torch.Tensor, torch.Tensor]:
        if torch.is_grad_enabled():
            raise ValueError("ResidualFusion is inference-only; disable autograd")
        key = (tuple(x.shape), x.stride(), y.stride(), x.device, normalize)
        if key not in self.compiled:
            if x.ndim != 3 or min(x.shape) == 0 or y.shape != x.shape:
                raise ValueError("x and y must have equal nonempty (B, N, C) shapes")
            if scale.shape != (x.shape[2],) or alpha.shape != (1, 1, x.shape[2]) or beta.shape != alpha.shape:
                raise ValueError("scale must have shape (C,) and Affine parameters (1, 1, C)")
            if any(t.dtype != torch.float32 or not t.is_cuda or t.device != x.device
                   for t in (x, y, scale, alpha, beta)):
                raise ValueError("all inputs must be FP32 CUDA tensors on the same device")
        residual = torch.empty_like(x)
        normalized = torch.empty_like(x) if normalize else residual
        tensors = (x, y, scale, alpha, beta, residual, normalized)
        if key not in self.compiled:
            arguments = [from_dlpack(t, enable_tvm_ffi=True) for t in tensors]
            self.compiled[key] = cute.compile(
                launch, *arguments, normalize,
                make_fake_stream(use_tvm_ffi_env_stream=True), options="--enable-tvm-ffi"
            )
        self.compiled[key](*tensors)
        self.calls += 1
        return residual, normalized
