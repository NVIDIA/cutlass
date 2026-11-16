# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.


"""PyIR runtime facade -- re-exports the layered pyir_* split.

``pyir_assign`` / ``pyir_read`` / ``MutableValue`` and the full prior
``pyir_runtime`` surface are defined across the pyir_state -> ... ->
pyir_call_boundary chain; this module re-exports them so
``pyir_runtime.<name>`` keeps working.  No ``__all__`` here: nothing
star-imports this facade, and named imports resolve through the chain
modules' generated ``__all__`` lists (see scripts/gen_pyir_all.py).
"""

from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_corewalk import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_loop_carry import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_entrypoints import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_call_boundary import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_class_facts import *  # noqa: F401,F403  (class-facts leaf; not part of the layer chain)
from .pyir_spec import *  # noqa: F401,F403  (F-SPEC re-entry engine leaf; not part of the layer chain)
