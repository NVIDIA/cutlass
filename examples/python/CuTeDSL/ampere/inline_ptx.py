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

from functools import partial
from typing import Union

import torch

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass._mlir.dialects import llvm
from cutlass.cute.typing import Boolean, Int32, Int, Constexpr
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass.cute.arch.nvvm_wrappers import FULL_MASK, WARP_SIZE

"""
A simple example to show how to wrap PTX instructions by using inline_asm op in llvm dialect.

Situations like:

1. Instructions that are not already exposed by CuTe DSL via `nvvm` module
2. Sequences of instructions that the compiler otherwise does not generate optimally 

motivate developers to inline PTX themselves.

In this example, we inline the vote.sync.ballot.b32, vote.sync.any.pred, vote.sync.all.pred,
vote.sync.uni.pred, and use the corresponding ops in nvvm_wrappers.py for the test.

You can refer to the documentation of `inline_asm op in llvm dialect <https://mlir.llvm.org/docs/Dialects/LLVM/#llvminline_asm-llvminlineasmop>`_
and `vote.sync <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-vote-sync>`_
for more details.

To run this example:

.. code-block:: bash

    python examples/ampere/inline_ptx.py

The example will run the vote kernel with inline PTX and nvvm dialect separately.
The results from inline PTX and nvvm dialect will be verified correspondingly.

"""


@dsl_user_op
def ptx_vote_sync_op(
    pred: Boolean, kind: str, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Union[Int32, Boolean]:
    return_type = Boolean
    return_type_str = "pred"
    return return_type(
        llvm.inline_asm(
            T.bool(),
            [
                Boolean(pred).ir_value(loc=loc, ip=ip),
                Int32(mask).ir_value(loc=loc, ip=ip),
            ],
            f"""{{\n\t
            .reg .pred ps;\n\t
            .reg .pred pd;\n\t
            setp.ne.b32 ps, $1, 0;\n\t
            vote.sync.{kind}.{return_type_str} pd, ps, $2;\n\t
            selp.b32 $0, 1, 0, pd;\n\t
            }}""",
            "=r,r,i",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


ptx_vote_any_sync = partial(ptx_vote_sync_op, kind="any")
ptx_vote_all_sync = partial(ptx_vote_sync_op, kind="all")
ptx_vote_uni_sync = partial(ptx_vote_sync_op, kind="uni")


@dsl_user_op
def ptx_vote_ballot_sync(
    pred: Boolean, mask: Int = FULL_MASK, *, loc=None, ip=None
) -> Union[Int32, Boolean]:
    return_type = Int32
    return_type_str = "b32"
    return return_type(
        llvm.inline_asm(
            T.i32(),
            [
                Boolean(pred).ir_value(loc=loc, ip=ip),
                Int32(mask).ir_value(loc=loc, ip=ip),
            ],
            f"""{{\n\t
            .reg .pred p;\n\t
            setp.ne.b32 p, $1, 0;\n\t
            vote.sync.ballot.{return_type_str} $0, p, $2;\n\t
            }}""",
            "=r,r,i",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
    )


@cute.kernel
def vote_kernel(
    mBallot: cute.Tensor,
    mAny: cute.Tensor,
    mAll: cute.Tensor,
    mUni: cute.Tensor,
    use_inline_ptx: Constexpr[bool],
):
    tidx, _, _ = cute.arch.thread_idx()

    vote_ballot = (
        ptx_vote_ballot_sync(tidx < 10)
        if use_inline_ptx
        else cute.arch.vote_ballot_sync(tidx < 10)
    )
    vote_any = (
        ptx_vote_any_sync(tidx < 10)
        if use_inline_ptx
        else cute.arch.vote_any_sync(tidx < 10)
    )
    vote_all = (
        ptx_vote_all_sync(tidx < 10)
        if use_inline_ptx
        else cute.arch.vote_all_sync(tidx < 10)
    )
    vote_uni = (
        ptx_vote_uni_sync(tidx < 10)
        if use_inline_ptx
        else cute.arch.vote_uni_sync(tidx < 10)
    )

    mBallot[tidx] = vote_ballot
    mAny[tidx] = vote_any
    mAll[tidx] = vote_all
    mUni[tidx] = vote_uni


@cute.jit
def vote(
    mBallot: cute.Tensor,
    mAny: cute.Tensor,
    mAll: cute.Tensor,
    mUni: cute.Tensor,
    use_inline_ptx: Constexpr[bool],
):
    vote_kernel(
        mBallot,
        mAny,
        mAll,
        mUni,
        use_inline_ptx,
    ).launch(
        grid=[1, 1, 1],
        block=[cute.size(WARP_SIZE, mode=[0]), 1, 1],
    )


def run():
    ballot_ptx = torch.randint(
        0, 100, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.int32
    )
    any_ptx = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )
    all_ptx = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )
    uni_ptx = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )

    mBallotPTX = from_dlpack(ballot_ptx).mark_layout_dynamic()
    mAnyPTX = from_dlpack(any_ptx).mark_layout_dynamic()
    mAllPTX = from_dlpack(all_ptx).mark_layout_dynamic()
    mUniPTX = from_dlpack(uni_ptx).mark_layout_dynamic()

    # get the results from ptx
    vote(mBallotPTX, mAnyPTX, mAllPTX, mUniPTX, use_inline_ptx=True)

    ballot_nvvm = torch.randint(
        0, 100, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.int32
    )
    any_nvvm = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )
    all_nvvm = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )
    uni_nvvm = torch.randint(
        0, 2, (WARP_SIZE,), device=torch.device("cuda"), dtype=torch.bool
    )

    mBallotNVVM = from_dlpack(ballot_nvvm).mark_layout_dynamic()
    mAnyNVVM = from_dlpack(any_nvvm).mark_layout_dynamic()
    mAllNVVM = from_dlpack(all_nvvm).mark_layout_dynamic()
    mUniNVVM = from_dlpack(uni_nvvm).mark_layout_dynamic()

    # get the results from nvvm
    vote(mBallotNVVM, mAnyNVVM, mAllNVVM, mUniNVVM, use_inline_ptx=False)

    print("Verifying ballot results...")
    torch.testing.assert_close(ballot_ptx, ballot_nvvm)
    print("Verifying any results...")
    torch.testing.assert_close(any_ptx, any_nvvm)
    print(torch.all(any_ptx == any(i < 10 for i in range(WARP_SIZE))))
    assert torch.all(any_ptx == any(i < 10 for i in range(WARP_SIZE)))
    print("Verifying all results...")
    torch.testing.assert_close(all_ptx, all_nvvm)
    assert torch.all(all_ptx == all(i < 10 for i in range(WARP_SIZE)))
    print("Verifying uni results...")
    torch.testing.assert_close(uni_ptx, uni_nvvm)
    assert torch.all(uni_ptx == (len(set(i < 10 for i in range(WARP_SIZE))) == 1))
    print("Results verified successfully!")


if __name__ == "__main__":
    run()
