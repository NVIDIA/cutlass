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

"""Operand allocation for Operator API tests.

"""

import hashlib
import random
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Literal

import torch

import cutlass
import cutlass.torch
from cutlass.utils.gemm.tensor_utils import create_scale_factor_tensor

import cutlass.operators as ops
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    OperandConstraints,
    ScaledOperandConstraints,
)
from cutlass.operators.utils.dtype import (
    get_torch_to_cutlass_dtype_map,
)

from .common import reference_device


class RNGStateManager:
    """
    Helper for saving and restoring the RNG state. This is useful to make sure
    that an RNG state is set to a specific value for a given block of code and
    does not affect calling operations.
    """

    def __init__(self, seed: int = None):
        self._seed = seed
        self._rng_state = None
        self._cuda_rng_state = None

    def __enter__(self):
        if self._seed is not None:
            self._rng_state = torch.get_rng_state()
            self._cuda_rng_state = torch.cuda.get_rng_state()
            torch.manual_seed(self._seed)

    def __exit__(self, exc_type, exc_value, traceback):
        if self._seed is not None:
            torch.set_rng_state(self._rng_state)
            torch.cuda.set_rng_state(self._cuda_rng_state)


################################################################################
# Initialization modes
################################################################################


@dataclass
class InitializationMode(ABC):
    """
    An initialization mode for a tensor.
    """

    def create(
        self, dtype, shape: tuple[int, ...], seed: int = 2025, device="cuda"
    ) -> torch.Tensor:
        """
        Creates a tensor of the given datatype, shape, and device. Simple wrapper around the
        child-defined _create method that ensures that the RNG state is set to the given seed.

        :param dtype: The datatype of the tensor
        :type dtype: cutlass.Numeric
        :param shape: The shape of the tensor
        :type shape: tuple[int, ...]
        :param seed: The seed to use for the RNG state
        :type seed: int
        :param device: The device to use for the tensor
        :type device: str

        :return: A tensor of the given datatype, shape, and device
        :rtype: torch.Tensor
        """
        with RNGStateManager(seed):
            return self._create(dtype, shape, device)

    @abstractmethod
    def _create(self, dtype, shape: tuple[int, ...], device="cuda") -> torch.Tensor:
        """
        Creates a tensor of the given datatype, shape, and device.
        """


@dataclass
class RandomIntInitializationMode(InitializationMode):
    """
    An initialization mode for a tensor that is initialized with random integers
    in range [min_val, max_val] and scaled by the global scale factor.
    """

    min_val: int
    max_val: int
    global_scale: float = 1

    def _create(self, dtype, shape: tuple[int, ...], device="cuda") -> torch.Tensor:
        """
        Creates a tensor of the given datatype, shape, and device.
        Also scales the tensor by the global scale factor if provided.
        """
        if dtype == torch.float4_e2m1fn_x2:
            # Packed FP4: each byte holds 2 FP4 values (low + high nibble).
            # Use the same valid byte patterns as CuTe DSL's
            # create_gemm_tensor_torch — each byte encodes a pair from {0, 1, -1}.
            _FP4_BYTE_PATTERNS = torch.tensor(
                [0x00, 0x02, 0x0A, 0x20, 0x22, 0x2A, 0xA0, 0xA2, 0xAA],
                dtype=torch.uint8,
                device=device,
            )
            return _FP4_BYTE_PATTERNS[
                torch.randint(0, len(_FP4_BYTE_PATTERNS), shape, device=device)
            ].view(torch.float4_e2m1fn_x2)
        scaled_tensor = self.global_scale * torch.randint(
            self.min_val, self.max_val, shape, device=device
        )
        return scaled_tensor.to(dtype)

    @classmethod
    def from_dtypes(
        cls, dtype: cutlass.Numeric, out_dtype: cutlass.Numeric
    ) -> "RandomIntInitializationMode":
        """
        Creates a RandomIntInitializationMode from the given datatypes.

        Range is determined based on the bitwidth of the `dtype` and `out_dtype` --
        the lower the bitwidth of these types, the lower the range of values to avoid overflow
        and rounding error.

        Args:
            dtype (cutlass.Numeric): The datatype of the tensor
            out_dtype (cutlass.Numeric): The datatype of the output tensor

        Returns:
            A RandomIntInitializationMode

        Raises:
            ValueError: If the dtype is not supported
        """
        if dtype.is_float:
            # [-2, -1, 0, 1, 2]
            min_val = -2
            max_val = 3  # exclusive
            sf = 1

            if dtype.width <= 8 or out_dtype.width <= 8:
                # [-1, -0.5, 0, 0.5, 1]
                sf = 0.5

            return cls(min_val=min_val, max_val=max_val, global_scale=sf)
        elif dtype.is_integer:
            min_val = -2
            max_val = 3

            if dtype.width <= 8 or out_dtype.width <= 8:
                min_val = -1
                max_val = 2  # exclusive

            if dtype in {cutlass.Uint8, cutlass.Uint16, cutlass.Uint32, cutlass.Uint64}:
                min_val = 0

            return cls(min_val=min_val, max_val=max_val)
        else:
            raise ValueError(f"Unsupported dtype: {dtype}")


@dataclass
class EmptyInitializationMode(InitializationMode):
    """
    An initialization mode for a tensor that is initialized with empty values.
    """

    def _create(self, dtype, shape: tuple[int, ...], device="cuda") -> torch.Tensor:
        """
        Creates a tensor of the given datatype, shape, and device.
        """
        return torch.empty(shape, dtype=dtype, device=device)


################################################################################
# MemPool
################################################################################


# Upper bound, in elements, on the random offset a pooled tensor may start at.
#
# The offset exists to stress dependence on pointer alignments higher than the
# Operator declares it needs, which only depends on the offset's residues modulo
# those alignments -- not on its magnitude.
#
# 4096 keeps at least 4096/divisibility distinct offsets (256 at the common
# divisibility of 16), spanning every residue modulo the 256- and 1024-byte
# alignments worth stressing.
MAX_RANDOM_OFFSET = 4096


def _pool_seed(key: tuple[str, ...]) -> int:
    """
    Returns a stable RNG seed derived from a pool key.

    Two keys sharing a seed would hand their buffers the same sequence, which is
    exactly the operand correlation the per-name keying exists to prevent, so the
    seed uses the full width `torch.manual_seed` accepts -- 64 bits, from an
    8-byte digest. Across the tens of keys in play that puts a collision at ~1e-16
    rather than the ~1e-7 a 32-bit checksum would give, and it stays negligible as
    keys are added.

    Hashing the key, rather than drawing seeds from a parent generator, keeps the
    seed independent of the order keys are first requested -- which varies with
    test selection and xdist sharding, and would otherwise give one operand
    different data depending on which worker ran it. blake2b rather than `hash`,
    whose string salt varies per process.

    :param key: The pool key to derive a seed for
    :type key: tuple[str, ...]
    :return: A seed for the given pool key, in `[0, 2**64)`
    :rtype: int
    """
    # digest_size=8 gives 8 bytes, i.e. the 64 bits torch.manual_seed takes.
    seed = hashlib.blake2b(digest_size=8)
    # Terminate each part. A hash sees one flat byte stream -- successive
    # update() calls are equivalent to one update() of the concatenation -- so
    # without a delimiter ("A", "AB") and ("AA", "B") would hash alike. NUL
    # cannot occur in a dtype name or an InitializationMode repr.
    for part in key:
        seed.update(part.encode())
        seed.update(b"\0")
    return int(seed.hexdigest(), 16)


class MemPool:
    """
    A pool of tensors used for test cases. The goals of the pool are the following:
      - Reduce reallocations of tensors across test cases
      - Reduce reinitialization of tensors across test cases
      - Allow for returning tensors with arbitrary starting offsets (to stress pointer alignment)
      - Allow for returning non-compact tensors

    Toward these goals, the pool maintains a set of tensors, with one tensor corresponding to a
    combination of tensor name, datatype and InitializationMode.

    The tensor name is part of the key, and each key seeds its data independently
    (see `_pool_seed`), so that distinct operands never share a backing tensor nor
    the same sequence.

    Callers request a tensor of a given datatype, shape, and InitializationMode.

    If the pool contains a tensor that is at least as large as is needed by the caller and
    with the same datatype and InitializationMode, that tensor is returned by reusing
    the existing tensor. This is done only for InitializationModes that are position independent
    -- if a caller requests a tensor to be initialized sequentially starting from X, returning
    a subset of that tensor may not satisfy the caller's requirements. In these cases, a new
    tensor may be reinitialized.

    Tensors are intended to be under the ownership of the MemPool. Explicitly deallocating
    memory backing the pool is expected to lead to an error.
    """

    def __init__(self, device: Literal["cpu", "cuda"] = "cuda"):
        """
        :param device: The torch device to allocate pool tensors on. Defaults to "cuda".
        :type device: str
        """
        self.device = device
        self.tensors = {}
        # seed -> the key that claimed it, so a collision is caught rather than
        # silently handing two operands the same data.
        self._seed_owners = {}

    def get(
        self,
        dtype: cutlass.Numeric,
        shape: tuple[int, ...],
        stride: tuple[int, ...],
        initialization_mode: InitializationMode,
        random_offset_divisibility: int = None,
        name: str = "",
    ) -> torch.Tensor:
        """
        Gets a tensor of the given datatype, shape, and stride, and initialized with the given initialization mode.
        If `random_offset_divisibility` is provided, the tensor is offset by a random amount
        (divisible by `random_offset_divisibility`) to stress dependence on higher pointer alignments
        than stated as needed by the Operator.

        :param dtype: The datatype of the tensor
        :type dtype: cutlass.Numeric
        :param shape: The shape of the tensor
        :type shape: tuple[int, ...]
        :param stride: The stride of the tensor
        :type stride: tuple[int, ...]
        :param initialization_mode: The initialization mode of the tensor
        :type initialization_mode: InitializationMode
        :param random_offset_divisibility: The divisibility of the random offset
        :type random_offset_divisibility: int
        :param name: The operand name ("A", "B", "out", ...). Tensors with different names
            never share a backing tensor, and are seeded independently
        :type name: str
        :return: A tensor of the given datatype, shape, and stride, and initialized with the given initialization mode
        :rtype: torch.Tensor
        :raises ValueError: If `random_offset_divisibility` is not positive; if `shape`
            and `stride` differ in length; if any extent in `shape` is not positive; or
            if this key's seed is already claimed by a different key, which would give
            two operands the same data
        """
        if random_offset_divisibility is not None and random_offset_divisibility <= 0:
            raise ValueError(
                f"Expected random_offset_divisibility to be greater than 0, got {random_offset_divisibility}"
            )

        if len(shape) != len(stride):
            raise ValueError(
                f"Expected shape and stride to have the same length, got {len(shape)} and {len(stride)}"
            )

        if any(extent <= 0 for extent in shape):
            raise ValueError(
                f"Expected every extent in shape to be positive, got {shape}"
            )

        # Elements the view spans: its largest reachable index, plus one.
        size_required = 1 + sum((shape[i] - 1) * stride[i] for i in range(len(shape)))

        # The buffer holds the data plus room for the random offset.
        capacity_required = size_required + MAX_RANDOM_OFFSET

        # A tuple rather than a concatenated string: ("A", "AB") and ("AA", "B")
        # would otherwise spell the same key.
        key = (name, str(dtype), str(initialization_mode))
        torch_dtype = cutlass.torch.dtype(dtype)
        tensor = self.tensors.get(key, torch.tensor([], dtype=torch_dtype))

        if tensor.numel() < capacity_required:
            seed = _pool_seed(key)
            owner = self._seed_owners.setdefault(seed, key)
            if owner != key:
                raise ValueError(
                    f"Pool keys {owner} and {key} both derive seed {seed}. Distinct "
                    "operands must draw independent data: sharing a stream would give "
                    "their buffers the same sequence and recreate the correlation this "
                    "keying exists to prevent."
                )
            # The tensors generated by the mempool are always for self.device.
            # When reference_device is cpu, we also want initialization on cpu
            #
            #
            # We initialize on cpu and copy the contents to mempool's original device.
            # The copy is of the whole backing store, so that later when we take random offsets
            # below, we do it on the correct allocation.
            init_device = self.device if reference_device() == "cuda" else "cpu"
            tensor = initialization_mode.create(
                torch_dtype,
                (capacity_required,),
                seed=seed,
                device=init_device,
            )
            if init_device != self.device:
                tensor = tensor.to(self.device)
            self.tensors[key] = tensor

        if random_offset_divisibility is not None and (
            random_offset_divisibility < MAX_RANDOM_OFFSET
        ):
            offset = random.randrange(
                random_offset_divisibility,
                MAX_RANDOM_OFFSET,
                random_offset_divisibility,
            )
        else:
            offset = 0
        return torch.as_strided(tensor[offset : offset + size_required], shape, stride)


################################################################################
# Tensor creation from metadata
################################################################################


def dense_tensor_from_metadata(
    mempool: MemPool,
    attr: DenseTensorConstraints,
    shape: tuple[int, ...],
    tensor_name: str,
    initialization_mode: InitializationMode,
    randomly_offset: bool = True,
) -> ops.DenseTensor:
    """
    Creates a dense tensor from metadata.

    :param mempool: The memory pool to use
    :type mempool: MemPool
    :param attr: The constraints of the tensor
    :type attr: cutlass.operators.metadata.DenseTensorConstraints
    :param shape: The shape of the tensor
    :type shape: tuple[int, ...]
    :param tensor_name: The name of the tensor
    :type tensor_name: str
    :param initialization_mode: The initialization mode to use
    :type initialization_mode: InitializationMode
    :param randomly_offset: Whether to randomly offset the tensor by its divisibility factor
    :type randomly_offset: bool

    :return: A dense tensor
    :rtype: cutlass.operators.arguments.DenseTensor
    """
    if not isinstance(attr, DenseTensorConstraints):
        raise ValueError(f"Expected DenseTensorConstraints, got {type(attr)}")

    # Plan to allow for non-compact strides in the future.
    # For now, assume that one of the final two modes has stride 1,
    # that the other of the final two modes has the next lowest stride,
    # and that remaining modes have strides that increase in right-to-left
    # order (which matches the default in torch).
    if attr.stride is None or len(attr.stride) == 1:
        stride = [
            1,
        ]
        next_stride = shape[-1]
    else:
        # Build up stride starting from the final modes
        stride = [shape[-1], 1] if attr.stride[-2:][1] == 1 else [1, shape[-2]]
        next_stride = shape[-1] * shape[-2]

    remaining_modes = len(shape) - len(stride)
    for i in range(remaining_modes, 0, -1):
        stride.insert(0, next_stride)
        next_stride *= shape[i]

    stride = tuple(stride)

    tensor = mempool.get(
        attr.dtype,
        shape,
        stride,
        initialization_mode,
        attr.divisibility if randomly_offset else None,
        name=tensor_name,
    )
    return ops.DenseTensor(tensor)


def scaled_tensor_from_metadata(
    mempool: MemPool,
    attr: ScaledOperandConstraints,
    shape: tuple[int, int, int],
    tensor_name: str,
    initialization_mode: InitializationMode,
    randomly_offset: bool = True,
) -> ops.ScaledOperand:
    """
    Creates a scaled tensor from metadata.

    :param mempool: The memory pool to use
    :type mempool: MemPool
    :param attr: The constraints of the tensor
    :type attr: cutlass.operators.metadata.ScaledOperandConstraints
    :param shape: The shape of the tensor
    :type shape: tuple[int, int, int]
    :param tensor_name: The name of the tensor
    :type tensor_name: str
    :param initialization_mode: The initialization mode to use
    :type initialization_mode: InitializationMode
    :param randomly_offset: Whether to randomly offset the tensor by its divisibility factor
    :type randomly_offset: bool

    :return: A scaled tensor
    :rtype: cutlass.operators.arguments.ScaledOperand
    """
    if len(shape) != 3:
        raise ValueError(f"Expected shape to be of length 3, got {len(shape)}")

    if not isinstance(attr, ScaledOperandConstraints):
        raise ValueError(f"Expected ScaledOperandConstraints, got {type(attr)}")

    if tensor_name not in ["A", "B"]:
        raise ValueError(f"Expected tensor_name to be 'A' or 'B', got {tensor_name}")

    # Adjust shape for packed subbyte types: float4_e2m1fn_x2 packs 2 FP4 values
    # per byte, so the physical K dimension is K // 2.
    quantized_shape = shape
    if attr.quantized.dtype == cutlass.Float4E2M1FN:
        if tensor_name == "A":
            quantized_shape = (shape[0], shape[1], shape[2] // 2)
        else:
            quantized_shape = (shape[0], shape[1] // 2, shape[2])

    quantized = create(
        mempool,
        attr.quantized,
        quantized_shape,
        tensor_name,
        initialization_mode,
        randomly_offset,
    )

    # ScaledOperand.numel_scale takes the quantized shape as (L, outer, K), where
    # outer=M for an A-side scale and outer=N for a B-side scale. The B quantized
    # tensor is stored as (L, K, N), so we permute the inner dims to match.
    if tensor_name == "A":
        (L, outer, K) = shape
    else:
        (L, K, outer) = shape

    sf_vec_size = ops.ScaleMode.numel(attr.mode)

    if attr.swizzle == ops.ScaleSwizzleMode.Swizzle32x4x4:
        # Use CuTe DSL's create_scale_factor_tensor to produce the packed
        # on-device layout (sf_gpu).  The emulated reference in gemm.py
        # calls unpack_scale_factors directly on the scale tensor from args,
        # so no pre-unpacked data needs to be threaded through here.
        _sf_ref, sf_cute, sf_gpu = create_scale_factor_tensor(
            outer, K, L, sf_vec_size, attr.scale.dtype
        )
        # SF dtypes torch cannot represent (e.g. FloatNV8E5M3FNU) are backed by
        # uint8 storage, so the flat torch view would report Uint8 and no
        # operator would match. Pass the CuTe tensor for those.
        has_torch_dtype = attr.scale.dtype in get_torch_to_cutlass_dtype_map().values()
        scale = ops.DenseTensor(sf_gpu.flatten() if has_torch_dtype else sf_cute)
        return ops.ScaledOperand(quantized, scale, attr.mode, attr.swizzle)

    total_tensor_size = ops.ScaledOperand.numel_scale(
        (L, outer, K), attr.mode, attr.swizzle
    )

    # Block-scaled GEMM hardware treats scale factors as non-negative
    # magnitudes (consistent with CuTe DSL conventions).
    if (
        isinstance(initialization_mode, RandomIntInitializationMode)
        and initialization_mode.min_val < 0
    ):
        raise ValueError(
            f"Scale factor initialization requires non-negative min_val, "
            f"got {initialization_mode.min_val}. Block-scaled GEMM hardware "
            f"treats scale factors as non-negative magnitudes."
        )

    # Name the scale distinctly from its quantized tensor so the two never share a
    # pool buffer. They currently differ by dtype anyway, which keys them apart,
    # but relying on that is accidental rather than intended.
    scale = create(
        mempool,
        attr.scale,
        (total_tensor_size,),
        f"{tensor_name}_scale",
        initialization_mode,
        randomly_offset,
    )
    return ops.ScaledOperand(quantized, scale, attr.mode, attr.swizzle)


def create(
    mempool: MemPool,
    attr: OperandConstraints,
    shape: tuple[int, int, int],
    tensor_name: str,
    initialization_mode: InitializationMode,
    randomly_offset: bool = True,
) -> ops.Operand:
    """
    Creates a tensor from metadata.

    :param mempool: The memory pool to use
    :type mempool: MemPool
    :param attr: The constraints of the tensor
    :type attr: cutlass.operators.metadata.OperandConstraints
    :param shape: The shape of the tensor
    :type shape: tuple[int, int, int]
    :param tensor_name: The name of the tensor
    :type tensor_name: str
    :param initialization_mode: The initialization mode to use
    :type initialization_mode: InitializationMode
    :param randomly_offset: Whether to randomly offset the tensor by its divisibility factor
    :type randomly_offset: bool

    :return: A tensor
    :rtype: cutlass.operators.arguments.Operand
    """
    # Perform exact type matches to avoid issues in case of inheritance
    match attr:
        case DenseTensorConstraints():
            return dense_tensor_from_metadata(
                mempool, attr, shape, tensor_name, initialization_mode, randomly_offset
            )
        case ScaledOperandConstraints():
            return scaled_tensor_from_metadata(
                mempool, attr, shape, tensor_name, initialization_mode, randomly_offset
            )
        case _:
            raise ValueError(f"Unhandled operand constraints type: {type(attr)}")
