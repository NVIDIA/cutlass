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

from typing import Optional, Tuple

from cutlass.cutlass_dsl import T, dsl_user_op

from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm, nvvm as _nvvm, vector

from ..typing import Int32, Pointer, Int128


@dsl_user_op
def issue_clc_query(
    mbar_ptr: Pointer,
    clc_response_ptr: Pointer,
    multicast: bool = True,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    The clusterlaunchcontrol.try_cancel instruction requests atomically cancelling the launch
    of a cluster that has not started running yet. It asynchronously writes an opaque response
    to shared memory indicating whether the operation succeeded or failed. On success, the
    opaque response contains the ctaid of the first CTA of the canceled cluster.

    :param mbar_ptr: A pointer to the mbarrier address in SMEM
    :type mbar_ptr:  Pointer
    :param clc_response_ptr: A pointer to the cluster launch control response address in SMEM
    :type clc_response_ptr:  Pointer
    :param multicast: Whether to use multicast variant (default: True)
    :type multicast:  bool
    """
    mbar_llvm_ptr = mbar_ptr.llvm_ptr
    clc_response_llvm_ptr = clc_response_ptr.llvm_ptr
    if multicast:
        _nvvm.clusterlaunchcontrol_try_cancel(
            smem_address=clc_response_llvm_ptr,
            mbarrier=mbar_llvm_ptr,
            multicast="multicast",
            loc=loc,
            ip=ip,
        )
    else:
        _nvvm.clusterlaunchcontrol_try_cancel(
            smem_address=clc_response_llvm_ptr,
            mbarrier=mbar_llvm_ptr,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def clc_response(
    result_addr: Pointer,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[Int32, Int32, Int32, Int32]:
    """
    After loading response from clusterlaunchcontrol.try_cancel instruction into 16-byte
    register, it can be further queried using clusterlaunchcontrol.query_cancel instruction.
    If the cluster is canceled successfully, predicate p is set to true; otherwise, it is
    set to false. If the request succeeded, clusterlaunchcontrol.query_cancel.get_first_ctaid
    extracts the CTA id of the first CTA in the canceled cluster. By default, the instruction
    returns a .v4 vector whose first three elements are the x, y and z coordinate of first CTA
    in canceled cluster.

    PTX leaves get_first_ctaid undefined when the request failed, so it is issued only under
    the is_canceled predicate, and the returned coordinates are 0 when the request failed.

    :param result_addr: A pointer to the cluster launch control response address in SMEM
    :type result_addr:  Pointer
    :return: The x, y and z coordinates of the first CTA in the canceled cluster (0 if the
        request failed), and 1 if the request succeeded, 0 otherwise
    :rtype: Tuple[Int32, Int32, Int32, Int32]
    """
    from cutlass.cute import recast_ptr, make_tensor, make_layout

    clc_ptr_i128 = recast_ptr(result_addr, dtype=Int128, loc=loc, ip=ip)
    clc_tensor = make_tensor(
        clc_ptr_i128, make_layout(1, loc=loc, ip=ip), loc=loc, ip=ip
    )

    # Load the 128-bit value from shared memory
    clc_result_vec = clc_tensor.load(loc=loc, ip=ip)

    # Extract the i128 scalar from the vector<1xi128>
    clc_result_i128 = vector.extract(
        clc_result_vec.ir_value(loc=loc, ip=ip),
        [],
        [0],
    )
    # Split it into two 64-bit halves for the inline PTX below
    clc_result_v2i64 = llvm.bitcast(
        ir.VectorType.get([2], T.i64()), clc_result_i128, loc=loc, ip=ip
    )
    clc_result_lo = vector.extract(clc_result_v2i64, [], [0], loc=loc, ip=ip)
    clc_result_hi = vector.extract(clc_result_v2i64, [], [1], loc=loc, ip=ip)

    # Query the response in one PTX block so that get_first_ctaid stays predicated on
    # is_canceled; LLVM treats the NVVM query intrinsics as speculatable and may hoist
    # them above a branch on is_canceled.
    result = llvm.inline_asm(
        llvm.StructType.get_literal([T.i32(), T.i32(), T.i32(), T.i32()]),
        [clc_result_lo, clc_result_hi],
        "{\n\t"
        ".reg .pred p;\n\t"
        ".reg .b128 clc_result;\n\t"
        "mov.b128 clc_result, {$4, $5};\n\t"
        "mov.b32 $0, 0;\n\t"
        "mov.b32 $1, 0;\n\t"
        "mov.b32 $2, 0;\n\t"
        "clusterlaunchcontrol.query_cancel.is_canceled.pred.b128 p, clc_result;\n\t"
        "selp.b32 $3, 1, 0, p;\n\t"
        "@p clusterlaunchcontrol.query_cancel.get_first_ctaid.v4.b32.b128 {$0, $1, $2, _}, clc_result;\n\t"
        "}",
        "=r,=r,=r,=r,l,l",
        has_side_effects=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )
    m_idx, n_idx, l_idx, is_valid = [
        Int32(llvm.extractvalue(T.i32(), result, [i], loc=loc, ip=ip))
        for i in range(4)
    ]

    return m_idx, n_idx, l_idx, is_valid


