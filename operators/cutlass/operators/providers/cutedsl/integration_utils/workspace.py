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

"""GMEM workspace handling for tile-scheduler operators.

Only the two-kernel (GMEM) split-K reduction needs a workspace; every other
strategy runs on a null pointer. An operator uses :func:`null_gmem_pointer` as
the workspace argument when compiling, :func:`check_workspace_size` and
:func:`view_workspace_as_bytes` before handing a workspace to the kernel's
``initialize_workspace``, and :func:`get_gmem_workspace_pointer` to validate
it and build the pointer each launch receives.
"""

from __future__ import annotations

import math
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute

from cutlass.operators.utils.tensor import (
    is_numpy_tensor,
    is_torch_tensor,
)

if TYPE_CHECKING:
    from cutlass.operators.workspace import Workspace


def null_gmem_pointer(assumed_align_bytes=16) -> cute.Pointer:
    """Return a pointer to an empty GMEM workspace with alignment requirement."""
    return cute.runtime.nullptr(
        cutlass.Int8, cute.AddressSpace.gmem, assumed_align=assumed_align_bytes
    )


def _check_workspace_contiguous(buffer) -> None:
    """Reject a torch or NumPy workspace buffer that is not contiguous.

    :param buffer: A workspace's runtime buffer. Buffers that are neither torch
        nor NumPy tensors are not checked.
    :raises ValueError: If a torch or NumPy buffer is not contiguous, since
        its memory would not be covered in order from its base pointer.
    """
    if is_torch_tensor(buffer) and not buffer.is_contiguous():
        raise ValueError("workspace must be a contiguous tensor")
    if is_numpy_tensor(buffer) and not buffer.flags.c_contiguous:
        raise ValueError("workspace must be a contiguous array")


def view_workspace_as_bytes(workspace: Workspace):
    """Return a flat view of a caller's workspace with one element per byte.

    Torch and NumPy buffers of any element type are reinterpreted in
    place; any other buffer must already hold one-byte elements.

    :param workspace: The caller's workspace.
    :return: A one-dimensional byte view sharing the workspace's memory.
    :raises ValueError: If a torch or NumPy buffer is not contiguous, since a
        byte view of it would not cover its memory in order.
    :raises TypeError: If the buffer cannot be viewed as bytes.
    """
    buffer = workspace.data.runtime_tensor
    _check_workspace_contiguous(buffer)

    if is_torch_tensor(buffer):
        import torch

        return buffer.view(-1).view(torch.uint8)

    if is_numpy_tensor(buffer):
        import numpy as np

        return buffer.reshape(-1).view(np.uint8)

    if isinstance(buffer, cute.Tensor):
        element_bits = buffer.element_type.width
    else:
        element_bits = getattr(getattr(buffer, "dtype", None), "itemsize", 0) * 8
    if element_bits != 8:
        raise TypeError(
            f"cannot view a {type(buffer).__name__} workspace as bytes; "
            "pass a torch or NumPy tensor, or a buffer of 8-bit elements"
        )
    return buffer


def check_workspace_size(workspace: Workspace, required_bytes: int) -> None:
    """Checks workspace buffer's sizing requirements.

    :param workspace: The caller's workspace, backed by a ``cute.Tensor`` or
        any framework tensor exposing ``nbytes`` (torch, JAX, NumPy).
    :param required_bytes: Bytes this launch needs.
    :type required_bytes: int
    :raises ValueError: If the buffer is too small.
    :raises TypeError: If the backing tensor's size cannot be determined.
    """
    workspace_tensor = workspace.data.runtime_tensor

    if isinstance(workspace_tensor, cute.Tensor):
        provided_bytes = (
            math.prod(workspace_tensor.shape) * workspace_tensor.element_type.width // 8
        )
    else:
        # nbytes exist for JAX and torch and numpy tensors
        provided_bytes = getattr(workspace_tensor, "nbytes", None)
        # Fail on unknown tensor types
        if provided_bytes is None:
            raise TypeError("tensor type not supported")

    if provided_bytes < required_bytes:
        raise ValueError(
            f"workspace is {provided_bytes} bytes but this launch needs "
            f"{required_bytes} bytes"
        )


def get_gmem_workspace_pointer(
    workspace: Workspace | None, required_bytes: int
) -> cute.Pointer:
    """Validate a caller-owned workspace and return the pointer to launch with.

    ``None`` is accepted only by a schedule that needs no workspace, in which
    case the launch gets :func:`null_gmem_pointer`.

    :param workspace: The caller's workspace, or ``None``.
    :param required_bytes: Bytes this launch needs, from
        ``get_gmem_workspace_size``.
    :type required_bytes: int

    :return: The 16-byte-aligned global ``int8*`` to pass to the kernel.
    :rtype: cute.Pointer
    :raises ValueError: If no workspace was given but one is needed, if a
        torch or NumPy buffer is not contiguous, if the buffer does not live
        in global device memory, if it is not 16-byte aligned, or if it is
        too small.
    """
    if workspace is None:
        if required_bytes > 0:
            raise ValueError(
                f"this launch needs a workspace of {required_bytes} bytes "
                "but none was provided"
            )
        return null_gmem_pointer()

    workspace_tensor = workspace.data.runtime_tensor
    _check_workspace_contiguous(workspace_tensor)
    # Workspace may already hold cute.Tensor, which from_dlpack does not
    # consume; otherwise, such as with TVM-FFI, the buffer can be
    # an external tensor.
    workspace_cute = (
        workspace_tensor
        if isinstance(workspace_tensor, cute.Tensor)
        else cute.runtime.from_dlpack(workspace_tensor)
    )

    if workspace_cute.memspace != cute.AddressSpace.gmem:
        raise ValueError(
            f"workspace must be in global device memory, got {workspace_cute.memspace}"
        )

    if workspace_cute.data_ptr % 16 != 0:
        raise ValueError(
            f"workspace must be 16-byte aligned, got address "
            f"{workspace_cute.data_ptr:#x}"
        )
    check_workspace_size(workspace, required_bytes)

    return cute.runtime.make_ptr(
        cutlass.Int8,
        workspace_cute.data_ptr,
        cute.AddressSpace.gmem,
        assumed_align=16,
    )
