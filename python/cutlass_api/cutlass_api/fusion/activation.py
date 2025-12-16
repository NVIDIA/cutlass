#################################################################################################
#
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
#
#################################################################################################

"""
Helpers for common activation functions
"""

import ctypes

from cutlass_api.fusion.ir.c_types import dtype2ctype, to_ctype_value
from cutlass_api.fusion.library import ActivationOp
from cutlass_api.utils import (
    is_torch_available,
    is_numpy_available,
    is_numpy_tensor,
    is_torch_tensor,
)


if is_torch_available():
    import torch
    import torch.nn.functional as F


if is_numpy_available():
    import numpy as np


class ActivationFunctor:
    """
    Base class for frequently used activation functions
    """

    @staticmethod
    def numpy(x):
        raise NotImplementedError()

    @staticmethod
    def epilogue_output_op(element_epilogue):
        c_element_epilogue = dtype2ctype[element_epilogue]

        class _EpilogueOutputOpParams(ctypes.Structure):
            _fields_ = [
                ("alpha", c_element_epilogue),
                ("beta", c_element_epilogue),
                ("alpha_ptr", ctypes.c_void_p),
                ("beta_ptr", ctypes.c_void_p),
            ]

            def __init__(self, alpha, beta, *args) -> None:
                self.alpha = to_ctype_value(alpha, element_epilogue)
                self.beta = to_ctype_value(beta, element_epilogue)

        return _EpilogueOutputOpParams


class ActivationMeta(type):
    @classmethod
    def __call__(cls, x, *args):
        if is_numpy_tensor(x):
            return cls.numpy(x, *args)
        elif is_torch_tensor(x):
            return cls.torch(x, *args)
        else:
            raise NotImplementedError("Unsupported tensor type")

    @classmethod
    def numpy(cls, *args):
        raise NotImplementedError(
            f"Numpy reference for {cls.__name__[:-4]} is not implemented."
        )

    @classmethod
    def torch(cls, *args):
        raise NotImplementedError(
            f"PyTorch reference for {cls.__name__[:-4]} is not implemented."
        )


##############################################################################
# identity operator
class identityMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        return x

    @classmethod
    def torch(cls, x):
        return x


class identity(ActivationFunctor, metaclass=identityMeta):
    binding_type = ActivationOp.Identity


##############################################################################
# ReLu operator
class reluMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        return np.where(x > 0, x, 0)

    @classmethod
    def torch(cls, x):
        return F.relu(x)


class relu(ActivationFunctor, metaclass=reluMeta):
    binding_type = ActivationOp.ReLU


##############################################################################
# Leaky ReLu operator
class leakyReLUMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x, leaky_alpha):
        return np.maximum(x, 0) + np.minimum(x, 0) * leaky_alpha

    @classmethod
    def torch(cls, x, leaky_alpha):
        return F.leaky_relu(x, leaky_alpha)


class leaky_relu(ActivationFunctor, metaclass=leakyReLUMeta):
    binding_type = ActivationOp.LeakyReLU


##############################################################################
# Tanh operator
class tanhMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        return np.tanh(x)

    @classmethod
    def torch(cls, x):
        return torch.tanh(x)


class tanh(ActivationFunctor, metaclass=tanhMeta):
    binding_type = ActivationOp.Tanh


##############################################################################
# Sigmoid operator
class sigmoidMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        return 1.0 / (1.0 + np.exp(-x))

    @classmethod
    def torch(cls, x):
        return F.sigmoid(x)


class sigmoid(ActivationFunctor, metaclass=sigmoidMeta):
    binding_type = ActivationOp.Sigmoid


##############################################################################
# SiLu operator
class siluMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        return x * sigmoidMeta.numpy(x)

    @classmethod
    def torch(cls, x):
        return F.silu(x)


class silu(ActivationFunctor, metaclass=siluMeta):
    binding_type = ActivationOp.SiLU


##############################################################################
# Hardswish operator
class hardswishMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        relu6 = np.minimum(np.maximum(x + 3.0, 0), 6.0)
        return x * relu6 / 6.0

    @classmethod
    def torch(cls, x):
        return F.hardswish(x)


class hardswish(ActivationFunctor, metaclass=hardswishMeta):
    binding_type = ActivationOp.HardSwish


##############################################################################
# GELU operator
class geluMeta(ActivationMeta):
    @classmethod
    def numpy(cls, x):
        from scipy.special import erf

        return 0.5 * x * (1 + erf(x / np.sqrt(2.0)))

    @classmethod
    def torch(cls, x):
        return F.gelu(x)


class gelu(ActivationFunctor, metaclass=geluMeta):
    binding_type = ActivationOp.Gelu
