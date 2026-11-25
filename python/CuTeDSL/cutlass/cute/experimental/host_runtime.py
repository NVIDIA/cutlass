# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Host-side runtime helpers for querying and driving JIT-compiled kernels."""

import ctypes
from typing import Any

from cutlass.base_dsl.jit_executor import (
    AuxRuntimeFunc,
    DSLRuntimeError,
    ExecutionArgs,
)

__all__ = [
    "AllocationRequirement",
    "QueryDeviceWorkspaceFunc",
    "QueryWorkspaceRequirementsFunc",
]


class AllocationRequirement(ctypes.Structure):
    """Mirrors the allocation requirement returned by workspace query functions.

    .. code-block:: c

        struct AllocationRequirement { int64_t sizeInBytes; int64_t alignment; };
    """

    _fields_ = [
        ("size_in_bytes", ctypes.c_int64),
        ("alignment", ctypes.c_int64),
    ]

    def __repr__(self) -> str:
        return (
            f"AllocationRequirement(size_in_bytes={self.size_in_bytes}, "
            f"alignment={self.alignment})"
        )


class QueryDeviceWorkspaceFunc(AuxRuntimeFunc):
    """Callable wrapper for the ``queryDeviceWorkspace`` symbol of a single kernel.

    Usage::

        query = compiled_fn.get_aux_func(QueryDeviceWorkspaceFunc, kernel=my_kernel)
        req = query(*kernel_args)
        workspace = torch.empty(req.size_in_bytes, dtype=torch.uint8, device="cuda")
        compiled_fn(*kernel_args, from_dlpack(workspace))

    :param func_ptr: Raw integer address of the packed-args wrapper
        returned by ``engine.raw_lookup``.
    :param args_spec: The :class:`~cutlass.base_dsl.jit_executor.ExecutionArgs`
        instance used to build logical-arg arrays from Python tensors.
    """

    name = "queryDeviceWorkspace"

    def __init__(self, func_ptr: int, args_spec: ExecutionArgs) -> None:
        self._raw_fn = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(func_ptr)
        self._args_spec = args_spec

    def __call__(self, *args: Any, **kwargs: Any) -> AllocationRequirement:
        """Query workspace requirements for the given kernel arguments.

        Accepts the same positional/keyword arguments as the kernel call.
        Returns the :class:`AllocationRequirement` reported by the kernel.

        :raises DSLRuntimeError: If the host function returns a non-zero error code.
        """
        exe_args, adapted_args = self._args_spec.generate_execution_args(args, kwargs)
        logical_args = (ctypes.c_void_p * len(exe_args))(*exe_args)
        arg0 = ctypes.c_void_p(ctypes.addressof(logical_args))

        # MLIR packed-args calling convention: void f(void **all_args) where
        #   all_args[0] = &arg0  (logical_args_ptr value)
        #   all_args[1] = &arg1  (AllocationRequirement* value)
        #   all_args[2] = &retval (i32 return value storage)
        req = AllocationRequirement()
        arg1 = ctypes.c_void_p(ctypes.addressof(req))
        retval = ctypes.c_int32(0)
        all_args = (ctypes.c_void_p * 3)(
            ctypes.addressof(arg0),
            ctypes.addressof(arg1),
            ctypes.addressof(retval),
        )
        self._raw_fn(all_args)
        ret = retval.value
        if ret != 0:
            raise DSLRuntimeError(f"queryDeviceWorkspace failed with return code {ret}")

        del adapted_args  # keep alive until after the call
        return req


class QueryWorkspaceRequirementsFunc(AuxRuntimeFunc):
    """Queries all compiler-managed workspace requirements for a host function.

    Usage::

        query = compiled_fn.get_aux_func(QueryWorkspaceRequirementsFunc)
        requirements = query(*logical_runtime_args)

    Requirements are returned in the order of the trailing workspace arguments
    appended to the compiled host function.
    """

    name = "QueryWorkspaceRequirements"

    def __init__(self, func_ptr: int, args_spec: ExecutionArgs) -> None:
        self._raw_fn = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(func_ptr)
        self._args_spec = args_spec

    def _invoke(
        self,
        logical_args_address: int | None,
        requirements_address: int | None,
    ) -> int:
        logical_args = ctypes.c_void_p(logical_args_address)
        requirements = ctypes.c_void_p(requirements_address)
        result = ctypes.c_int64(0)
        packed_args = (ctypes.c_void_p * 3)(
            ctypes.addressof(logical_args),
            ctypes.addressof(requirements),
            ctypes.addressof(result),
        )
        self._raw_fn(packed_args)
        return result.value

    def get_workspace_argument_count(self) -> int:
        """Returns the number of trailing workspace arguments."""
        requirement_count = self._invoke(None, None)
        if requirement_count < 0:
            raise DSLRuntimeError(
                "QueryWorkspaceRequirements failed while querying workspace count"
            )
        return requirement_count

    def __call__(self, *args: Any, **kwargs: Any) -> tuple[AllocationRequirement, ...]:
        """Returns workspace requirements in compiled host argument order."""
        requirement_count = self.get_workspace_argument_count()
        if requirement_count == 0:
            return ()

        exe_args, adapted_args = self._args_spec.generate_execution_args(args, kwargs)
        logical_args = (ctypes.c_void_p * len(exe_args))(*exe_args)
        requirements = (AllocationRequirement * requirement_count)()
        result = self._invoke(
            ctypes.addressof(logical_args), ctypes.addressof(requirements)
        )
        if result < 0:
            raise DSLRuntimeError(
                "QueryWorkspaceRequirements failed while querying requirements"
            )
        if result != requirement_count:
            raise DSLRuntimeError(
                "QueryWorkspaceRequirements returned "
                f"{result} requirements after reporting {requirement_count}"
            )

        del adapted_args  # keep alive until after the call
        return tuple(
            AllocationRequirement(
                size_in_bytes=requirement.size_in_bytes,
                alignment=requirement.alignment,
            )
            for requirement in requirements
        )
