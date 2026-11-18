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

"""Low-level CUTLASS experimental primitives.

Typed hardware MMA descriptors (SM90 ``wgmma`` / SM100 ``tcgen05``) are
flattened into this package so callers import them directly from
``cutlass.experimental.primitives`` and never need the ``descriptors`` submodule
path::

    from cutlass.experimental.primitives import Tcgen05SmemDesc, Tcgen05SmemSwizzle
    # or
    cutlass.experimental.primitives.Tcgen05SmemDesc.build(...)

Low-level NVVM primitive wrappers from :mod:`.nvvm_wrapper` are flattened the
same way, so callers use them as ``prims.<op>``::

    from cutlass.experimental import primitives as prims
    prims.tcgen05_mma(...)          # a wrapped op
    prims.CTAGroup.CTA_1            # an enum
    prims.dialect.<raw_op>(...)     # raw NVVM dialect escape hatch

"""

from .descriptors import *  # noqa: F403
from .descriptors import __all__ as _descriptors_all

from .nvvm_wrapper import *  # noqa: F403
from .nvvm_wrapper import __all__ as _nvvm_wrapper_all

from .hybrid_ops import *  # noqa: F403
from .hybrid_ops import __all__ as _hybrid_ops_all

__all__ = [*_descriptors_all, *_nvvm_wrapper_all, *_hybrid_ops_all]

