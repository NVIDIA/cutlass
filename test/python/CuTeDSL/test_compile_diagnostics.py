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

import cutlass
from cutlass import cute
from cutlass.base_dsl.common import DSLUserCodeError


@cute.kernel
def kernel_for_compile_diagnostic(x: cutlass.Float32):
    del x


class TestCompileDiagnostics(unittest.TestCase):
    def test_compile_rejects_kernel_with_user_error(self):
        with self.assertRaises(DSLUserCodeError) as ctx:
            cute.compile(kernel_for_compile_diagnostic, 0.0)

        self.assertEqual(ctx.exception.code, "CALL_KERNEL_DIRECT_COMPILE_UNSUPPORTED")
        rendered = str(ctx.exception)
        self.assertNotIn("Internal Error", rendered)
        self.assertIn("@cute.jit", rendered)


if __name__ == "__main__":
    unittest.main()
