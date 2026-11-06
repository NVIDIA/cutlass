# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass.pipeline import PipelineState, PipelineUserType, make_pipeline_state


@cute.jit
def _advance_state(state: PipelineState) -> None:
    state.advance()


@cute.kernel
def _aliased_pipeline_state_kernel(out: cute.Tensor, n: cutlass.Int32):
    state0 = make_pipeline_state(PipelineUserType.Producer, 3)
    state1 = state0

    for _ in cutlass.range(n):
        state0.advance()

    out[0] = state0.count
    out[1] = state1.count


@cute.jit
def _aliased_pipeline_state_host(out: cute.Tensor, n: cutlass.Int32):
    _aliased_pipeline_state_kernel(out, n).launch(
        grid=[1, 1, 1],
        block=[1, 1, 1],
    )


@cute.kernel
def _sibling_pipeline_state_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    state0 = make_pipeline_state(PipelineUserType.Producer, 3)
    state1 = make_pipeline_state(PipelineUserType.Producer, 3)

    if tidx == cutlass.Int32(0):
        _advance_state(state0)

    out[0] = state0.count
    out[1] = state1.count


@cute.jit
def _sibling_pipeline_state_host(out: cute.Tensor):
    _sibling_pipeline_state_kernel(out).launch(
        grid=[1, 1, 1],
        block=[1, 1, 1],
    )


def _compile_output(entry, shape, *args):
    out = torch.zeros(shape, device="cuda", dtype=torch.int32)
    out_cute = from_dlpack(out).mark_layout_dynamic()
    compiled = cute.compile[cute.FrontendNext](entry, out_cute, *args)
    compiled(out_cute, *args)
    torch.cuda.synchronize()
    return out.cpu().tolist()


def test_pipeline_state_alias_survives_dynamic_range():
    n = cutlass.Int32(3)
    actual = _compile_output(_aliased_pipeline_state_host, 2, n)
    assert actual == [3, 3]


def test_pipeline_state_helper_does_not_mutate_sibling():
    actual = _compile_output(_sibling_pipeline_state_host, 2)
    assert actual == [1, 0]
