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

"""
Unit tests for the lifetime of tensors wrapped by ``from_dlpack``.

Reading a property of the wrapper must not keep the wrapper, and so the
underlying tensor, alive after the caller drops it. The tests use CPU tensors,
so they run anywhere.
"""

import gc
import unittest
import weakref

import torch

from cutlass.cute.runtime import from_dlpack


class RuntimeTensorLifetimeTest(unittest.TestCase):
    def test_leading_dim_does_not_keep_tensor_alive(self):
        x = torch.empty(4, 8)
        t = from_dlpack(x)
        self.assertEqual(t.leading_dim, 1)
        ref = weakref.ref(t)
        del x, t
        gc.collect()
        self.assertIsNone(ref())


if __name__ == "__main__":
    unittest.main()
