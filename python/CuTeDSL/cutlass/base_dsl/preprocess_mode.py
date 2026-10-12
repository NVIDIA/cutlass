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

"""Private helper for mixed PyIR and non-PyIR preprocessing state."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from .ast_preprocessor import DSLPreprocessor
from .pyir_preprocessor import PyIRDSLPreprocessor

if TYPE_CHECKING:
    from .dsl import BaseDSL


class _PreprocessModeState:
    def __init__(self, dsl: "BaseDSL") -> None:
        self._dsl = dsl
        self._stack: list[tuple[bool, bool, DSLPreprocessor]] = []

    def current_signature(
        self,
    ) -> tuple[tuple[bool, bool, str | None]]:
        return (self.current_mode_key(),)

    def current_mode_key(self) -> tuple[bool, bool, str | None]:
        # The rewrite output is a pure function of (source, mode key): the
        # preprocessor class fixes the choke set, and the two flags fix its
        # parameters.  No history/epoch component — restoring an identical
        # mode MUST yield an identical key, or every cached rewrite in the
        # process is spuriously invalidated on each mode round trip.
        preprocessor = getattr(self._dsl, "preprocessor", None)
        preprocessor_cls = (
            type(preprocessor).__name__ if preprocessor is not None else None
        )
        return (
            bool(self._dsl.envar.enable_pyir),
            bool(self._dsl.envar.auto_m2s),
            preprocessor_cls,
        )

    def push_pyir(self) -> None:
        self._stack.append(
            (
                bool(self._dsl.envar.enable_pyir),
                bool(self._dsl.envar.auto_m2s),
                self._dsl.preprocessor,
            )
        )
        self._apply(
            enable_pyir=True,
            auto_m2s=True,
            preprocessor=PyIRDSLPreprocessor(self._dsl.package_name),
        )

    def pop(self) -> None:
        """Restore the previous preprocessing mode from the stack.

        Raises:
            RuntimeError: If no saved mode exists. This indicates an unmatched
                pop without a preceding push_pyir().
        """
        if not self._stack:
            raise RuntimeError(
                "Cannot pop preprocessing mode: no saved state on stack. "
                "Ensure push_pyir() was called before pop()."
            )
        enable_pyir, auto_m2s, preprocessor = self._stack.pop()
        self._apply(
            enable_pyir=enable_pyir,
            auto_m2s=auto_m2s,
            preprocessor=preprocessor,
        )

    def _apply(
        self,
        *,
        enable_pyir: bool,
        auto_m2s: bool,
        preprocessor: DSLPreprocessor,
    ) -> None:
        if enable_pyir:
            # Turning PyIR on here bypasses the environment manager, which is
            # where _pyir_register_mode_fact would otherwise bind the Numeric
            # write funnel. Without it the wrapper write funnel is undeclared
            # for this trace and no holder write is ever stamped.
            from .typing import _pyir_install_numeric_write_funnel

            _pyir_install_numeric_write_funnel()
        self._dsl.envar.enable_pyir = enable_pyir
        self._dsl.envar.auto_m2s = auto_m2s
        self._dsl.preprocessor = preprocessor
