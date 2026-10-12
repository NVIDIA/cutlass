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

import unittest
from types import SimpleNamespace
from unittest import mock

from cutlass.base_dsl import dsl as dsl_module
from cutlass.base_dsl.compiler import LinkLibraries


class _ReverseSet(set):
    def __iter__(self):
        return iter(sorted(super().__iter__(), reverse=True))


class TestLinkLibrariesOrder(unittest.TestCase):
    def test_preserves_attribute_order_and_deduplicates(self):
        paths = ["user.bc", "device.bc", "math.bc", "device.bc"]
        gpu_module = SimpleNamespace(
            name="gpu.module",
            attributes={
                "link-libraries": [SimpleNamespace(value=path) for path in paths]
            },
        )
        module = SimpleNamespace(body=SimpleNamespace(operations=[gpu_module]))
        compile_options = SimpleNamespace(
            options={LinkLibraries: LinkLibraries("existing.bc")}
        )
        owner = SimpleNamespace(compile_options=compile_options)

        # Make the old set-based path fail deterministically, independent of
        # the interpreter's hash seed. The fixed path does not use this name.
        with mock.patch.object(dsl_module, "set", _ReverseSet, create=True):
            dsl_module.BaseDSL._merge_gpu_link_libraries(owner, module)

        self.assertEqual(
            compile_options.options[LinkLibraries].value,
            "existing.bc,user.bc,device.bc,math.bc",
        )


if __name__ == "__main__":
    unittest.main()
