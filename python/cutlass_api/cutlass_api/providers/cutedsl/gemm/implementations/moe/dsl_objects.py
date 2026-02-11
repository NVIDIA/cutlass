# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
Base classes for DSL kernel objects.

Provides:
- DeviceOnlyObj: Base class that ensures instantiation within @cute.kernel context
- UntracedPyObj: Base class for Python objects opaque to DSL tree-flatten/tracing
"""

import inspect
from dataclasses import dataclass

from cutlass._mlir import ir


def _is_in_kernel_context() -> bool:
    """
    Check if the current execution is within a @cute.kernel context.

    This verifies two conditions:
    1. MLIR InsertionPoint exists (we are in DSL compilation context)
    2. Call stack contains 'kernel_wrapper' (we are in kernel, not just jit)

    Returns:
        True if in @cute.kernel context, False otherwise
    """
    # Check 1: MLIR InsertionPoint must exist
    if ir.InsertionPoint.current is None:
        return False

    # Check 2: Call stack must contain kernel_wrapper
    for frame_info in inspect.stack():
        if frame_info.function == 'kernel_wrapper':
            return True

    return False


class DeviceOnlyObj:
    """
    Base class that ensures derived classes are only instantiated within
    a @cute.kernel context.

    Inherit from this class to enforce that your object can only be created
    inside device code (kernel), not in host code or @cute.jit functions.

    Example:
        class MyKernelHelper(DeviceOnlyObj):
            def __init__(self, config: dict):
                super().__init__()  # This will raise if not in kernel context
                self.config = config

        @cute.kernel
        def my_kernel(...):
            helper = MyKernelHelper(config)  # OK

        @cute.jit
        def my_jit_func(...):
            helper = MyKernelHelper(config)  # RuntimeError!

    Raises:
        RuntimeError: If instantiated outside of @cute.kernel context
    """

    def __init__(self) -> None:
        if not _is_in_kernel_context():
            raise RuntimeError(
                f"{self.__class__.__name__} must be instantiated within a @cute.kernel context. "
                f"It cannot be created in host code or @cute.jit functions."
            )


@dataclass(frozen=True)
class UntracedPyObj:
    """
    Base class for Python objects that are **opaque to the DSL's tree-flatten/tracing system**.

    Inherit from this class when you need a helper object inside a @cute.kernel or
    @cute.jit function that:
    - Holds IR values and/or codegen-time configuration as member variables
    - Provides @cute.jit methods that emit MLIR IR using those members
    - Should NOT be flattened, traced, or managed by the DSL's pytree mechanism

    Why @dataclass(frozen=True) with no fields?
        The DSL's tree_flatten recognizes dataclasses and tries to decompose them
        into MLIR-tracked leaves via dataclasses.fields(). By declaring zero fields,
        this class contributes nothing to the pytree -- the DSL has nothing to
        flatten or unflatten, effectively making instances invisible to the tracer.

    Safe usage discipline:

        UntracedPyObj works well when you follow these principles:

        1. Create the object at the **beginning of the kernel** (outermost
           region), so that IR values stored as members are defined in the
           kernel-level scope and remain valid everywhere inside the kernel.
        2. Treat IR-value members as **read-only after __init__**. Never
           reassign them inside an inner region (for/if/while). This avoids
           the two-lifetime mismatch between Python-level and MLIR-level values.
        3. Pure-Python members (dicts, ints, enums, layout objects, etc.)
           are always safe -- they are not MLIR values and have no
           region-scoping issue.

    Typical usage (often combined with DeviceOnlyObj):

        class MyTmaHelper(DeviceOnlyObj, UntracedPyObj):
            def __init__(self, tma_op, smem_layout, mma_tiler, workspace_ptr):
                super().__init__()           # DeviceOnlyObj: kernel-context check
                self.tma_op = tma_op         # codegen-time config (Python obj)
                self.smem_layout = smem_layout
                self.mma_tiler = mma_tiler
                self.workspace_ptr = workspace_ptr  # IR value, kernel-scope

            @cute.jit
            def build_and_write_tma(self, tensor, offset):
                # self.workspace_ptr is an IR value from kernel-scope -- safe here
                atom, _ = make_tiled_tma_atom(self.tma_op, tensor, self.smem_layout, ...)
                cpasync.copy_tensormap(atom, self.workspace_ptr + offset)

        @cute.kernel
        def my_kernel(workspace_ptr, ...):
            # Created at kernel top-level: all IR members live in kernel scope
            helper = MyTmaHelper(tma_op, smem_layout, mma_tiler, workspace_ptr)
            helper.build_and_write_tma(tensor_a, offset_a)  # OK
            helper.build_and_write_tma(tensor_b, offset_b)  # OK
    """
    pass


__all__ = ["DeviceOnlyObj", "UntracedPyObj"]
