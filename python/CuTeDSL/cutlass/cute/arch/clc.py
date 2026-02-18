# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Tuple

from cutlass.cutlass_dsl import T, dsl_user_op

from cutlass._mlir import ir
from cutlass._mlir.dialects import nvvm, llvm, vector, arith

from ..typing import Int32, Pointer, Int128


@dsl_user_op
def issue_clc_query(
    mbar_ptr: Pointer,
    clc_response_ptr: Pointer,
    multicast: bool = True,
    loc=None,
    ip=None,
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
    """
    mbar_llvm_ptr = mbar_ptr.llvm_ptr
    clc_response_llvm_ptr = clc_response_ptr.llvm_ptr
    if multicast:
        nvvm.clusterlaunchcontrol_try_cancel_multicast(
            clc_response_llvm_ptr,
            mbar_llvm_ptr,
            loc=loc,
            ip=ip,
        )
    else:
        nvvm.clusterlaunchcontrol_try_cancel(
            clc_response_llvm_ptr,
            mbar_llvm_ptr,
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def clc_response(
    result_addr: Pointer, loc=None, ip=None
) -> Tuple[Int32, Int32, Int32, Int32]:
    """
    After loading response from clusterlaunchcontrol.try_cancel instruction into 16-byte
    register, it can be further queried using clusterlaunchcontrol.query_cancel instruction.
    If the cluster is canceled successfully, predicate p is set to true; otherwise, it is
    set to false. If the request succeeded, clusterlaunchcontrol.query_cancel.get_first_ctaid
    extracts the CTA id of the first CTA in the canceled cluster. By default, the instruction
    returns a .v4 vector whose first three elements are the x, y and z coordinate of first CTA
    in canceled cluster.

    :param result_addr: A pointer to the cluster launch control response address in SMEM
    :type result_addr:  Pointer
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
    # Query if the cluster was canceled
    pred = nvvm.clusterlaunchcontrol_query_cancel_is_canceled(
        clc_result_i128,
        loc=loc,
        ip=ip,
    )
    is_valid = Int32(pred)

    # Get first CTA ID x component
    m_idx_i32 = nvvm.clusterlaunchcontrol_query_cancel_get_first_ctaid_x(
        clc_result_i128,
        loc=loc,
        ip=ip,
    )

    # Get first CTA ID y component
    n_idx_i32 = nvvm.clusterlaunchcontrol_query_cancel_get_first_ctaid_y(
        clc_result_i128,
        loc=loc,
        ip=ip,
    )

    # Get first CTA ID z component
    l_idx_i32 = nvvm.clusterlaunchcontrol_query_cancel_get_first_ctaid_z(
        clc_result_i128,
        loc=loc,
        ip=ip,
    )

    m_idx = Int32(m_idx_i32)
    n_idx = Int32(n_idx_i32)
    l_idx = Int32(l_idx_i32)

    return m_idx, n_idx, l_idx, is_valid
