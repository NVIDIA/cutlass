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

from cutlass.base_dsl.enums import Arch


class TestArchAliases(unittest.TestCase):
    def test_sm101_aliases_preserve_enum_values(self):
        for suffix in ("", "a", "f"):
            with self.subTest(suffix=suffix):
                canonical = getattr(Arch, "sm_110" + suffix)
                legacy = getattr(Arch, "sm_101" + suffix)
                self.assertIs(legacy, canonical)
                self.assertEqual(legacy.value, (11, 0, suffix))
                self.assertIs(Arch(legacy.value), canonical)
                self.assertEqual(
                    (legacy.major, legacy.minor, legacy.suffix), legacy.value
                )

    def test_alias_string_round_trip_is_canonical(self):
        for suffix in ("", "a", "f"):
            with self.subTest(suffix=suffix):
                canonical = getattr(Arch, "sm_110" + suffix)
                legacy = Arch.from_string("sm_101" + suffix)
                self.assertIs(legacy, canonical)
                self.assertEqual(legacy.name, "sm_110" + suffix)
                self.assertEqual(legacy.to_string(), "sm_110" + suffix)
                self.assertIs(Arch.from_string(legacy.to_string()), canonical)

    def test_alias_does_not_join_the_sm100_family(self):
        for suffix in ("a", "f"):
            with self.subTest(suffix=suffix):
                arch = getattr(Arch, "sm_101" + suffix)
                self.assertTrue(arch.is_family_of(Arch.sm_110f))
                self.assertFalse(arch.is_family_of(Arch.sm_100f))
                self.assertFalse(Arch.sm_100f.is_family_of(arch))
        self.assertFalse(Arch.sm_101.is_family_of(Arch.sm_110f))


if __name__ == "__main__":
    unittest.main()
