# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from dataclasses import dataclass
from enum import Enum
from typing import Optional, Type, Union

from cutlass.cute.typing import (
    Numeric,
    Boolean,
    Float,
    Integer,
    TFloat32,
    Float8E4M3B11FNUZ,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Float4E2M1FN,
    Tensor,
)
from cutlass.cute.runtime import from_dlpack
import cutlass.cute as cute
import torch


def dtype(ty: Type[Numeric]):
    """
    Return the corresponding torch.dtype per the given DSL type
    """
    torch_dtype = getattr(torch, ty.__name__.lower(), None)

    torch_type_map = {
        Boolean: torch.bool,
        # TFloat32 is just alias of float32
        TFloat32: torch.float32,
        Float8E5M2: torch.float8_e5m2,
        Float8E4M3FN: torch.float8_e4m3fn,
        Float8E4M3B11FNUZ: torch.float8_e4m3fnuz,
    }
    if torch_dtype is None:
        torch_dtype = torch_type_map.get(ty)

    if torch_dtype is None:
        raise TypeError(f"{ty} is not supported by torch")
    return torch_dtype


@dataclass
class ScalarInitConfig:
    """Configuration for scalar initialization"""

    value: float = 0.0


@dataclass
class RandomInitConfig:
    """Configuration for random initialization"""

    min_val: int = -2
    max_val: int = 2


@dataclass
class GaussianInitConfig:
    """Configuration for Gaussian initialization"""

    mean: float = 0.0
    std: float = 1.0
    scale: float = 1.0


class TensorInitType(Enum):
    """Enumeration of tensor initialization types"""

    SKIP = "skip"
    SCALAR = "scalar"
    RANDOM = "random"
    GAUSSIAN = "gaussian"


def create_and_permute_torch_tensor(
    shape,
    dtype: "torch.dtype",
    permute_order=None,
    init_type: TensorInitType = TensorInitType.RANDOM,
    init_config: Optional[
        Union[RandomInitConfig, ScalarInitConfig, GaussianInitConfig]
    ] = None,
) -> "torch.Tensor":
    """
    Create a torch tensor with specified shape and dtype. Optionally permute it and initialize it with specified init type and config
    """
    init_dtype = torch.int32 if init_type == TensorInitType.RANDOM else torch.float32
    init_torch_tensor = torch.empty(*shape, dtype=init_dtype)
    if init_type == TensorInitType.SKIP:
        assert init_config is None
        f32_torch_tensor = init_torch_tensor
    elif init_type == TensorInitType.SCALAR:
        if init_config is None:
            init_config = ScalarInitConfig()
        else:
            if not isinstance(init_config, ScalarInitConfig):
                raise ValueError("init_config must be ScalarInitConfig()")
        f32_torch_tensor = init_torch_tensor.fill_(init_config.value)
    elif init_type == TensorInitType.RANDOM:
        if init_config is None:
            init_config = RandomInitConfig()
        else:
            if not isinstance(init_config, RandomInitConfig):
                raise ValueError("init_config must be RandomInitConfig()")
        f32_torch_tensor = init_torch_tensor.random_(
            init_config.min_val, init_config.max_val
        ).to(dtype=torch.float32)
    elif init_type == TensorInitType.GAUSSIAN:
        if init_config is None:
            init_config = GaussianInitConfig()
        else:
            if not isinstance(init_config, GaussianInitConfig):
                raise ValueError("init_config must be GaussianInitConfig()")
        f32_torch_tensor = init_torch_tensor.normal_(init_config.mean, init_config.std)
        f32_torch_tensor = f32_torch_tensor * (1 << init_config.scale)
    else:
        raise ValueError(f"Invalid init type: {init_type}")

    if permute_order is not None:
        f32_torch_tensor = f32_torch_tensor.permute(permute_order)

    dtype_torch_tensor = f32_torch_tensor.to(dtype=dtype)

    return dtype_torch_tensor


def convert_cute_tensor(
    f32_torch_tensor: "torch.Tensor",
    cute_tensor: Tensor,
    dtype: Type[Numeric],
    is_dynamic_layout: bool = True,
) -> Tensor:
    """
    Change the value of the cute tensor to make its value converted from a fp32 torch tensor.
    Used for fp8 types tensor creatation now.
    """
    # if torch_tensor is on cpu, create a gpu copy
    if f32_torch_tensor.device.type == "cpu":
        f32_torch_tensor = f32_torch_tensor.cuda()

    # Fp8 type need explicit type conversion
    if dtype in {
        Float8E5M2,
        Float8E4M3FN,
        Float8E8M0FNU,
        Float4E2M1FN,
    }:
        fp32_cute_tensor = from_dlpack(f32_torch_tensor)
        if is_dynamic_layout:
            fp32_cute_tensor = fp32_cute_tensor.mark_layout_dynamic(
                f32_torch_tensor.dim_order()[-1]
            )
        # Copy and convert from f32 cute tensor to dtype cute tensor
        cute.testing.convert(fp32_cute_tensor, cute_tensor)
    return cute_tensor
