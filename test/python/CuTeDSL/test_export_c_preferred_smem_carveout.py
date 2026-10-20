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

"""Check the CUDA attributes applied by exported CuTe kernel loaders."""

import collections
import platform
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from cuda.bindings import driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_stream, make_fake_tensor
from cutlass.memory import SmemAllocator


@cute.kernel
def _rotate(x: cute.Tensor):
    tid = cute.arch.thread_idx()[0]
    shared = SmemAllocator().allocate_tensor(cutlass.Float32, cute.make_layout(128))
    shared[tid] = x[tid]
    cute.arch.sync_threads()
    x[tid] = shared[(tid + 1) % 128]


@cute.jit
def _launch_with_carveout(
    x: cute.Tensor, stream: cuda.CUstream, carveout: cutlass.Constexpr
):
    _rotate(x).launch(
        grid=(1, 1, 1),
        block=(128, 1, 1),
        stream=stream,
        min_blocks_per_mp=2,
        preferred_smem_carveout=carveout,
    )


@cute.jit
def _launch_default(x: cute.Tensor, stream: cuda.CUstream):
    _rotate(x).launch(grid=(1, 1, 1), block=(128, 1, 1), stream=stream)


# Run the generated host loaders without a GPU. The reported device capacity is
# synthetic; the assertions concern the CUDA attribute-setting calls.
_RECORD_LOADER_C = r"""
#include <stdio.h>

static const char *case_name;
static const char *loader_name;

int _cudaGetDevice(int *device) {
    *device = 0;
    return 0;
}

int _cudaDeviceGetAttribute(int *value, int attribute, int device) {
    *value = 65536;
    return 0;
}

int _cuKernelGetAttribute(int *value, int attribute, void *kernel, int device) {
    *value = 0;
    return 0;
}

int _cudaLibraryGetKernel(void **kernel, void *library, const char *name) {
    *kernel = (void *)2;
    return 0;
}

int _cudaFuncSetAttribute(void *kernel, int attribute, int value) {
    printf("%s,%s,%d,%d\n", case_name, loader_name, attribute, value);
    return 0;
}

int _cudaKernelSetAttributeForDevice(
    void *kernel, int attribute, int value, int device
) {
    printf("%s,%s,%d,%d\n", case_name, loader_name, attribute, value);
    return 0;
}

int _cudaLibraryLoadData(void *library, ...) { return 0; }
int _cudaLaunchKernelEx(void *config, void *kernel, void *arguments) { return 0; }

int carveout_0_cuda_load(void **library);
int carveout_0_cuda_load_to_device(void **library, int device);
int carveout_25_cuda_load(void **library);
int carveout_25_cuda_load_to_device(void **library, int device);
int carveout_75_cuda_load(void **library);
int carveout_75_cuda_load_to_device(void **library, int device);
int carveout_default_cuda_load(void **library);
int carveout_default_cuda_load_to_device(void **library, int device);

typedef int (*load_fn)(void **);
typedef int (*load_to_device_fn)(void **, int);

static void record_case(
    const char *name, load_fn load, load_to_device_fn load_device
) {
    void *library = (void *)1;
    case_name = name;
    loader_name = "load";
    load(&library);
    loader_name = "load_to_device";
    load_device(&library, 0);
}

int main(void) {
    record_case("0", carveout_0_cuda_load, carveout_0_cuda_load_to_device);
    record_case("25", carveout_25_cuda_load, carveout_25_cuda_load_to_device);
    record_case("75", carveout_75_cuda_load, carveout_75_cuda_load_to_device);
    record_case(
        "default", carveout_default_cuda_load, carveout_default_cuda_load_to_device
    );
    return 0;
}
"""


_COMPILE_OPTIONS = (
    "--gpu-arch sm_90a "
    "--host-target 'llvm -mtriple=x86_64-unknown-linux-gnu -mcpu=x86-64'"
)


@unittest.skipUnless(
    sys.platform == "linux" and platform.machine() == "x86_64" and shutil.which("cc"),
    "AOT loader test requires Linux x86-64 and a C compiler",
)
class TestExportCPreferredSmemCarveout(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._temp_dir = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls._temp_dir.cleanup)
        output_dir = Path(cls._temp_dir.name)
        x = make_fake_tensor(cutlass.Float32, (128,), (1,), assumed_align=16)

        for carveout in (0, 25, 75, None):
            name = f"carveout_{carveout if carveout is not None else 'default'}"
            if carveout is None:
                compiled = cute.compile(
                    _launch_default, x, make_fake_stream(), options=_COMPILE_OPTIONS
                )
            else:
                compiled = cute.compile(
                    _launch_with_carveout,
                    x,
                    make_fake_stream(),
                    carveout,
                    options=_COMPILE_OPTIONS,
                )
            compiled.export_to_c(str(output_dir), name, name)

        recorder = output_dir / "record_loader.c"
        recorder.write_text(_RECORD_LOADER_C)
        executable = output_dir / "record_loader"
        subprocess.run(
            [
                "cc",
                str(recorder),
                *(str(output_dir / f"carveout_{value}.o") for value in (0, 25, 75)),
                str(output_dir / "carveout_default.o"),
                "-o",
                str(executable),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        result = subprocess.run(
            [str(executable)], check=True, capture_output=True, text=True
        )
        cls.calls = collections.defaultdict(list)
        for line in result.stdout.splitlines():
            case, loader, attribute, value = line.split(",")
            cls.calls[case, loader].append((int(attribute), int(value)))

    def test_explicit_preferences_reach_both_loaders(self):
        for carveout in (0, 25, 75):
            for loader in ("load", "load_to_device"):
                with self.subTest(carveout=carveout, loader=loader):
                    attributes = self.calls[str(carveout), loader]
                    self.assertEqual(
                        [value for attr, value in attributes if attr == 9],
                        [carveout],
                    )
                    self.assertIn((14, 1), attributes)
                    self.assertTrue(any(attr == 8 for attr, _ in attributes))

    def test_default_does_not_add_a_carveout_preference(self):
        for loader in ("load", "load_to_device"):
            with self.subTest(loader=loader):
                attributes = self.calls["default", loader]
                self.assertFalse(any(attr == 9 for attr, _ in attributes))
                self.assertIn((14, 1), attributes)
                self.assertTrue(any(attr == 8 for attr, _ in attributes))


if __name__ == "__main__":
    unittest.main()
