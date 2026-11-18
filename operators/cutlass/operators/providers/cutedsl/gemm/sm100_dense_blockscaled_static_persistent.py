# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Deprecated location of the SM100 block-scaled persistent GEMM operator.

.. deprecated::
    Import ``Sm100BlockscaledStaticPersistentOperator`` from
    ``cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent``.
    ``PersistentDenseBlockScaledGemmOperator`` is a deprecated alias to that class.
"""

from typing import TYPE_CHECKING

from cutlass.operators.utils.deprecation import deprecated_module_attributes

__getattr__ = deprecated_module_attributes(
    __name__,
    {
        "PersistentDenseBlockScaledGemmOperator": (
            "cutlass.operators.providers.cutedsl.gemm."
            "sm100_blockscaled_static_persistent.Sm100BlockscaledStaticPersistentOperator"
        ),
    },
)

if TYPE_CHECKING:
    # Type-checker view of the moved name above (PEP 702), so pyrefly, mypy and
    # pyright can flag its use.  Runtime access goes through ``__getattr__``.
    from typing_extensions import deprecated

    from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent import (
        Sm100BlockscaledStaticPersistentOperator,
    )

    @deprecated(
        "Use cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent."
        "Sm100BlockscaledStaticPersistentOperator instead."
    )
    class PersistentDenseBlockScaledGemmOperator(
        Sm100BlockscaledStaticPersistentOperator
    ): ...
