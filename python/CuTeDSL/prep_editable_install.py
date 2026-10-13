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

"""Deprecated compatibility entry point for the old editable-install flow."""

import warnings


def prep_editable_install() -> None:
    """Warn callers that editable installs no longer need preparation."""
    warnings.warn(
        "prep_editable_install.py is deprecated and no longer performs setup; "
        "use `python -m pip install -e .` instead.",
        DeprecationWarning,
        stacklevel=2,
    )


if __name__ == "__main__":
    prep_editable_install()
