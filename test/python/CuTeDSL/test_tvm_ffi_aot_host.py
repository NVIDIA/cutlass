# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 Infinity Core Contributors.
"""Host-only AOT regression; compilation needs the CuTe toolchain, not a GPU."""
import platform
import tempfile
import unittest
from pathlib import Path

import cutlass
import cutlass.cute as cute


@cute.kernel
def kernel(value: cutlass.Int32):
    cute.printf("value=%d", value)


@cute.jit
def launch(value: cutlass.Int32):
    kernel(value).launch(grid=(1, 1, 1), block=(1, 1, 1))


@unittest.skipUnless(platform.machine() == "x86_64", "x86-64 host target")
class TestTVMFFIAOTHost(unittest.TestCase):
    def test_portable_host_export(self):
        compiled = cute.compile(
            launch, cutlass.Int32(1), options="--enable-tvm-ffi --gpu-arch sm_90a"
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            before = str(compiled.ir_module)
            compiled.export_to_c(str(root / "portable.ll"), "probe", host_cpu="x86-64")
            text = (root / "portable.ll").read_text()
            self.assertIn('"target-cpu"="x86-64"', text)
            self.assertNotIn("+avx", text)
            self.assertEqual(str(compiled.ir_module), before)



if __name__ == "__main__":
    unittest.main()
