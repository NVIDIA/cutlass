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

"""Deprecated location of ``get_max_active_clusters``.

.. deprecated::
    Use :meth:`cutlass.operators.DeviceProperties.max_active_clusters`.
    ``get_max_active_clusters`` here is
    :func:`cutlass.operators.device_properties.query_max_active_clusters` and
    warns on access.
"""

from typing import TYPE_CHECKING

from cutlass.operators.utils.deprecation import deprecated_module_attributes

__getattr__ = deprecated_module_attributes(
    __name__,
    {
        "get_max_active_clusters": (
            "cutlass.operators.device_properties.query_max_active_clusters"
        ),
    },
)

if TYPE_CHECKING:
    # Type-checker view of the moved name above (PEP 702), so pyrefly, mypy and
    # pyright can flag its use.  Runtime access goes through ``__getattr__``.
    from typing_extensions import deprecated

    from cutlass.operators.device_properties import query_max_active_clusters

    get_max_active_clusters = deprecated(
        "Use cutlass.operators.device_properties.query_max_active_clusters, or "
        "cutlass.operators.DeviceProperties().max_active_clusters(cluster_shape), "
        "instead."
    )(query_max_active_clusters)
