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

"""
The first launch of a compiled kernel must set the CUDA library up only for
the device it runs on.

Setting a device up (the device scoped kernel attributes) makes the driver
load the module into that device's context, which waits for the work already
running there. Doing it for every visible device makes the first launch on one
GPU wait for all the others, and deadlocks when a kernel on another GPU is
itself waiting for that launch (NVIDIA/cutlass#3928).

Each scenario runs in a subprocess: a regression leaves a thread blocked in
the driver, which only a process exit clears. Needs two GPUs and PyTorch.
"""

import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

try:
    import torch

    _NUM_GPUS = torch.cuda.device_count()
except Exception:  # pragma: no cover - PyTorch is optional for this suite
    _NUM_GPUS = 0

_COMMON = """
import os, sys, threading, time
import cutlass, cutlass.cute as cute, torch
from cuda.bindings import driver as cu
from cutlass.cute.runtime import from_dlpack
"""

# GPU 0 runs a kernel that spins until the first launch on GPU 1 returned.
_BUSY_OTHER_DEVICE = _COMMON + """
@cute.kernel
def spin_kernel(flag: cute.Tensor) -> None:
    tid, _, _ = cute.arch.thread_idx()
    if tid == 0:
        while cute.arch.load(flag.iterator, cutlass.Int32, sem="acquire", scope="sys") == 0:
            pass

@cute.jit
def spin_host(flag: cute.Tensor, stream: cu.CUstream) -> None:
    spin_kernel(flag).launch(grid=(1, 1, 1), block=(1, 1, 1), stream=stream)

@cute.kernel
def noop_kernel() -> None:
    pass

@cute.jit
def noop_host(stream: cu.CUstream) -> None:
    noop_kernel().launch(grid=(1, 1, 1), block=(1, 1, 1), stream=stream)

s0, s1 = torch.cuda.Stream(device="cuda:0"), torch.cuda.Stream(device="cuda:1")
cu_s0, cu_s1 = cu.CUstream(s0.cuda_stream), cu.CUstream(s1.cuda_stream)
flag = torch.ones(1, dtype=torch.int32, pin_memory=True)
flag_cute = from_dlpack(flag)
torch.cuda.set_device(0)
spin_fn = cute.compile(spin_host, flag_cute, cu_s0)
spin_fn(flag_cute, cu_s0)
s0.synchronize()
noop_fn = cute.compile(noop_host, cu_s1)

flag[0] = 0
spinning, done = threading.Event(), threading.Event()

def gpu0() -> None:
    torch.cuda.set_device(0)
    spin_fn(flag_cute, cu_s0)
    time.sleep(0.15)
    spinning.set()
    s0.synchronize()

def gpu1() -> None:
    spinning.wait()
    torch.cuda.set_device(1)
    noop_fn(cu_s1)          # first launch of this kernel, on GPU 1, while GPU 0 is busy
    flag[0] = 1
    s1.synchronize()
    done.set()

threading.Thread(target=gpu0, daemon=True).start()
threading.Thread(target=gpu1, daemon=True).start()
ok = done.wait(timeout=20.0)
print("PASS" if ok else "DEADLOCK", flush=True)
os._exit(0 if ok else 1)
"""

# 100 KB of dynamic shared memory is above the default limit: the launch needs
# the max-dynamic-shared-memory attribute set for the device it runs on.
_ATTRIBUTES_ON_EVERY_DEVICE = _COMMON + """
@cute.kernel
def k(out: cute.Tensor, val: cutlass.Int32) -> None:
    tid, _, _ = cute.arch.thread_idx()
    if tid == 0:
        out[0] = val

@cute.jit
def host(out: cute.Tensor, val: cutlass.Int32, stream: cu.CUstream) -> None:
    k(out, val).launch(grid=(1, 1, 1), block=(32, 1, 1), smem=100 * 1024, stream=stream)

order = [int(d) for d in sys.argv[1].split(",")]
outs = [torch.zeros(4, dtype=torch.int32, device=f"cuda:{d}") for d in range(2)]
streams = [torch.cuda.Stream(device=f"cuda:{d}") for d in range(2)]
torch.cuda.set_device(0)
fn = cute.compile(host, from_dlpack(outs[0]), 0, cu.CUstream(streams[0].cuda_stream))

def run(d: int) -> None:
    torch.cuda.set_device(d)
    fn(from_dlpack(outs[d]), 41 + d, cu.CUstream(streams[d].cuda_stream))
    streams[d].synchronize()

for _ in range(2):
    threads = [threading.Thread(target=run, args=(d,)) for d in order for _ in range(4)]
    [t.start() for t in threads]
    [t.join() for t in threads]
got = [int(o[0].item()) for o in outs]
ok = got == [41, 42]
print("PASS" if ok else f"FAIL {got}", flush=True)
os._exit(0 if ok else 1)
"""


def _run(script: str, *args: str, tvm_ffi: bool) -> subprocess.CompletedProcess:
    env = dict(os.environ)
    env.pop("CUTE_DSL_ENABLE_TVM_FFI", None)
    if tvm_ffi:
        env["CUTE_DSL_ENABLE_TVM_FFI"] = "1"
    # The DSL compiles from source, so the scenario has to live in a file.
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "scenario.py")
        with open(path, "w") as f:
            f.write(textwrap.dedent(script))
        return subprocess.run(
            [sys.executable, path, *args],
            env=env,
            capture_output=True,
            text=True,
            timeout=300,
        )


def _has_tvm_ffi() -> bool:
    try:
        import tvm_ffi  # noqa: F401
    except Exception:
        return False
    return True


@unittest.skipUnless(_NUM_GPUS >= 2, "needs two GPUs and PyTorch")
class TestMultiGpuFirstLaunch(unittest.TestCase):
    def _check(self, script: str, *args: str, tvm_ffi: bool) -> None:
        if tvm_ffi and not _has_tvm_ffi():
            self.skipTest("apache-tvm-ffi is not installed")
        result = _run(script, *args, tvm_ffi=tvm_ffi)
        self.assertEqual(
            result.returncode, 0, msg=(result.stdout + result.stderr)[-2000:]
        )

    def test_first_launch_does_not_wait_for_other_device(self) -> None:
        for tvm_ffi in (False, True):
            with self.subTest(tvm_ffi=tvm_ffi):
                self._check(_BUSY_OTHER_DEVICE, tvm_ffi=tvm_ffi)

    def test_device_attributes_set_on_every_device(self) -> None:
        for tvm_ffi in (False, True):
            for order in ("0,1", "1,0"):
                with self.subTest(tvm_ffi=tvm_ffi, order=order):
                    self._check(_ATTRIBUTES_ON_EVERY_DEVICE, order, tvm_ffi=tvm_ffi)


if __name__ == "__main__":
    unittest.main()
