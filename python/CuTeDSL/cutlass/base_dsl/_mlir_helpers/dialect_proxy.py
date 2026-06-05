# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import enum
import types
from collections.abc import Callable
from typing import Any


class DialectAutoConvertProxy:
    """
    Proxy that wraps a raw MLIR dialect module, auto-converting DSL types
    (anything with an ``.ir_value()`` method) to ``ir.Value`` when calling
    dialect operations.

    This enables users to write cleaner code without explicit
    ``.ir_value()`` calls::

        # Before (raw dialect module):
        nvvm.shfl_sync(T.i32(), Int32(mask).ir_value(), ...)

        # After (proxied):
        nvvm.shfl_sync(T.i32(), Int32(mask), ...)

    Non-callable attributes and enum classes are passed through unchanged
    so that attribute access like ``nvvm.ShflKind.idx`` still works.

    Parameters
    ----------
    dialect_module
        The raw MLIR dialect module to wrap
        (e.g. ``cutlass._mlir.dialects.nvvm``).
    """

    def __init__(self, dialect_module: types.ModuleType) -> None:
        self._module = dialect_module
        self._wrapped_cache: dict[str, Callable[..., object]] = {}

    @staticmethod
    def _convert_arg(
        arg: object,
        loc: object | None,
        ip: object | None,
    ) -> object:
        """Recursively convert DSL objects to ir.Value."""
        if hasattr(arg, "ir_value") and callable(arg.ir_value):
            try:
                return arg.ir_value(loc=loc, ip=ip)
            except TypeError:
                # Some ir_value() methods (e.g. Array) don't accept loc/ip.
                return arg.ir_value()
        if isinstance(arg, (list, tuple)):
            converted = [
                DialectAutoConvertProxy._convert_arg(item, loc, ip) for item in arg
            ]
            return type(arg)(converted)
        return arg

    def __getattr__(self, name: str) -> Any:
        attr = getattr(self._module, name)

        # Non-callable attributes and enum classes pass through
        # unchanged.  Enum classes need attribute access (e.g.
        # ShflKind.idx), but MLIR operation classes should be
        # wrapped for argument conversion.
        if not callable(attr) or isinstance(attr, enum.EnumMeta):
            return attr

        # Use cache for wrapped callables
        if name not in self._wrapped_cache:

            def _make_wrapper(
                func: Callable[..., object],
            ) -> Callable[..., object]:
                def wrapped(
                    *args: object,
                    loc: object | None = None,
                    ip: object | None = None,
                    **kwargs: object,
                ) -> object:
                    converted_args = tuple(
                        DialectAutoConvertProxy._convert_arg(arg, loc, ip)
                        for arg in args
                    )
                    converted_kwargs = {
                        k: DialectAutoConvertProxy._convert_arg(v, loc, ip)
                        for k, v in kwargs.items()
                    }
                    return func(
                        *converted_args,
                        loc=loc,
                        ip=ip,
                        **converted_kwargs,
                    )

                return wrapped

            self._wrapped_cache[name] = _make_wrapper(attr)

        return self._wrapped_cache[name]

    def __dir__(self) -> list[str]:
        return dir(self._module)
