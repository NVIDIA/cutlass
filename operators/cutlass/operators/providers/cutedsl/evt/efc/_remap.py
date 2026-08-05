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

"""Standalone tensor-mode-remap helpers used by EFC.

Pure functions with no dependency on EFC's class machinery — kept
in their own module so the Tensor proxy (in `_tensor.py`) and
downstream kernels can call them without pulling in the outer
`class EFC:` definition.
"""

# This is not to use module annotations from a future version but to change the type system to postpone the evaluation of annotations,
# about forward declaration and lazy type checking.
# See https://docs.python.org/3/library/__future__.html#future__.annotations and https://peps.python.org/pep-0563/.
from __future__ import annotations

import typing

import cutlass

from ._helpers import if_info, log

if typing.TYPE_CHECKING:
    # Annotation-only ``torch`` import for the ``source: torch.Tensor``
    # parameter on ``torch_tensor_remap_modes`` below.  The runtime
    # ``import torch`` lives inside the function body so the framework
    # itself does not depend on PyTorch at import time -- only at
    # PyTorch-evaluation phase.
    import torch  # noqa: F401 — referenced only in annotations.


def _validate_source_mode_map(source_mode_map, source_rank, target_rank):
    """Validate the source_mode_map for remap_modes() and torch_tensor_remap_modes().

    Checks that:
    - Every element is either ``True`` (broadcast) or an ``int`` (source mode index).
    - The map length matches the target rank.
    - The number of non-broadcast entries does not exceed the source rank
      (some source dims may be unused, e.g. size-1 dims that are implicitly
      broadcast).
    - No integer index exceeds the source rank.
    - No integer index is negative.
    - No integer index appears more than once.
    """
    for i, v in enumerate(source_mode_map):
        if v is not True and not isinstance(v, int):
            raise TypeError(
                f"source_mode_map[{i}] must be an int or True, got {type(v).__name__}: {v!r}"
            )
    if target_rank != len(source_mode_map):
        raise ValueError(
            f"The target layout rank ({target_rank}) and the source_mode_map "
            f"length ({len(source_mode_map)}) should be the same."
        )
    # The number of non-True entries must not exceed source_rank — but can be
    # less, allowing some source dims to be unused (e.g. size-1 broadcast dims
    # in a tensor like (1, N) where dim 0 is ignored).
    num_true = sum(v is True for v in source_mode_map)
    num_used = len(source_mode_map) - num_true
    if num_used > source_rank:
        raise ValueError(
            f"source_mode_map references {num_used} source dimensions but "
            f"the source only has {source_rank}. "
            f"The number of non-True entries must not exceed the source rank."
        )
    int_indices = [v for v in source_mode_map if v is not True]
    for v in int_indices:
        if v < 0:
            raise ValueError(
                f"source_mode_map contains a negative index ({v}). "
                f"All mode indices must be non-negative."
            )
        if v >= source_rank:
            raise ValueError(
                f"source_mode_map contains index {v} which exceeds the source "
                f"rank ({source_rank}). Valid indices are 0..{source_rank - 1}."
            )
    if len(int_indices) != len(set(int_indices)):
        duplicates = [v for v in int_indices if int_indices.count(v) > 1]
        raise ValueError(
            f"source_mode_map contains duplicate source mode indices: "
            f"{sorted(set(duplicates))}. Each source mode should appear at most once."
        )


def remap_modes(
    source: cutlass.cute.Tensor,
    target_shape: tuple,
    source_mode_map: tuple,
    info_tensor_name="",
    info_source_name="",
):
    """Remap modes of a source tensor to match a target shape.

    The source_mode_map is a sequence with a length matching the rank of
    the target shape.

    Each element is either an integer defining the mode of the source
    tensor to map at this place or ``True`` to express that the source
    tensor is broadcast for this mode.
    """
    ss = source.stride
    _validate_source_mode_map(source_mode_map, len(ss), len(target_shape))
    stride = tuple([0 if v is True else ss[v] for v in source_mode_map])
    log(f"remap_modes {stride = }")
    if_info(
        lambda: cutlass.cute.printf(
            f"cute remap_modes stride {info_tensor_name} from {info_source_name} {{}} to {{}} (target_shape {target_shape})",
            source.stride,
            stride,
        )
    )
    log(
        f"remap_modes shape {info_tensor_name} from {info_source_name} {source.shape} to {target_shape = }"
    )
    if_info(
        lambda: cutlass.cute.printf(
            f"cute remap_modes shape {info_tensor_name} from {info_source_name} {{}} to {target_shape = }",
            source.shape,
        )
    )
    broadcast_layout = cutlass.cute.make_layout(shape=target_shape, stride=stride)
    return cutlass.cute.make_tensor(source.iterator, broadcast_layout)


def torch_tensor_remap_modes(
    source: torch.Tensor, target_shape: tuple, source_mode_map: tuple
):
    """Remap modes of a source tensor to match a target shape.

    This is the PyTorch equivalent of remap_modes() for cutlass.cute.Tensor.

    The source_mode_map is a sequence with a length matching the rank of
    the target shape.

    Each element is either an integer defining the mode of the source
    tensor to map at this place or ``True`` to express that the source
    tensor is broadcast for this mode.
    """
    import torch

    ss = source.stride()
    _validate_source_mode_map(source_mode_map, len(ss), len(target_shape))
    stride = tuple([0 if v is True else ss[v] for v in source_mode_map])
    log(f"torch_tensor_remap_modes {stride = }")
    log(f"torch_tensor_remap_modes {target_shape = }")
    return torch.as_strided(source, size=target_shape, stride=stride)
