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


# ``cutlass.Array(space=smem/tmem/...)`` allocation is provided by the allocation
# backend in ``.gpu_ops`` (``base_dsl`` only holds the ``Array`` facade plus a
# runtime hook).  Register a bridge here so callers can allocate via
# ``cutlass.Array`` after only importing this package.
#
# The bridge imports ``.gpu_ops`` lazily — at allocation time, never at import
# time — to avoid any import-ordering cycle during package init.
from cutlass.base_dsl.array import register_array_factory as _register_array_factory


def _array_factory(dtype: object, shape: object, space: object, kwargs: dict) -> object:
    from cutlass.experimental.primitives.gpu_ops import _Array_factory_dispatch

    return _Array_factory_dispatch(dtype, shape, space, kwargs)


_register_array_factory(_array_factory)
