#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################################

import ctypes
import importlib
import json
import types
import unittest
from unittest import mock

from cutlass_cppgen.backend.gemm_operation import GemmRTGrouped

compiler = importlib.import_module("cutlass_cppgen.backend.compiler")


class FakeCursor:
    def __init__(self, record):
        self.record = record

    def execute(self, query, args):
        pass

    def fetchall(self):
        return [self.record]

    def close(self):
        pass


class FakeConnection:
    def __init__(self, record):
        self.record = record

    def cursor(self):
        return FakeCursor(self.record)


class FakeFunction:
    def __init__(self, result=None):
        self.result = result

    def __call__(self, *args):
        return self.result


class FakeHostLibrary:
    def __init__(self, operation_name, param_size):
        self.get_params = FakeFunction()
        self.shared_memory_size = FakeFunction(0)
        setattr(self, f"{operation_name}_get_params", self.get_params)
        setattr(self, f"{operation_name}_shared_memory_size", self.shared_memory_size)


class CtypesSignatureTest(unittest.TestCase):
    def test_load_operation_sets_get_params_argtypes(self):
        param_size = 32
        operation_name = "test_operation"
        cache_key = "cache-key"
        argtypes = [ctypes.POINTER(ctypes.c_int), ctypes.c_void_p]
        record = (
            cache_key,
            b"cubin",
            b"hostbin",
            operation_name,
            json.dumps([param_size]),
        )
        host_lib = FakeHostLibrary(operation_name, param_size)
        artifact_manager = compiler.ArtifactManager.__new__(compiler.ArtifactManager)
        artifact_manager.compiled_cache_device = {}
        artifact_manager.compiled_cache_host = {}

        fake_cuda = types.SimpleNamespace(
            CUresult=types.SimpleNamespace(CUDA_SUCCESS=0),
            cuModuleLoadData=lambda cubin: (0, object()),
            cuModuleGetFunction=lambda module, name: (0, object()),
        )

        with mock.patch.object(compiler, "cuda", fake_cuda), \
             mock.patch.object(compiler.sqlite3, "connect", return_value=FakeConnection(record)), \
             mock.patch.object(compiler, "CDLLBin", return_value=host_lib):
            loaded = artifact_manager.load_operation(cache_key, argtypes, {})

        self.assertTrue(loaded)
        self.assertEqual(host_lib.get_params.argtypes, argtypes)
        self.assertEqual(
            host_lib.get_params.restype,
            ctypes.POINTER(ctypes.c_char * param_size),
        )
        self.assertIs(
            artifact_manager.compiled_cache_host[cache_key]["get_args"],
            host_lib.get_params,
        )

    def test_grouped_host_precompute_uses_size_t_for_workspace_bytes(self):
        workspace_bytes = 16
        precompute_result = ctypes.pointer((ctypes.c_byte * workspace_bytes)())
        precompute = FakeFunction(precompute_result)
        rt_module = GemmRTGrouped.__new__(GemmRTGrouped)
        rt_module.argtype = [ctypes.POINTER(ctypes.c_int), ctypes.c_int, ctypes.c_void_p]
        rt_module.precompute = precompute
        arguments = types.SimpleNamespace(arguments=ctypes.c_int(), total_tiles=7)

        with mock.patch(
            "cutlass_cppgen.backend.gemm_operation.todevice",
            return_value=types.SimpleNamespace(ptr=1234),
        ):
            device_ptr = rt_module.host_precompute(arguments, workspace_bytes)

        self.assertEqual(device_ptr, 1234)
        self.assertEqual(
            precompute.argtypes,
            [ctypes.POINTER(ctypes.c_int), ctypes.c_int, ctypes.c_size_t],
        )
        self.assertEqual(
            precompute.restype,
            ctypes.POINTER(ctypes.c_byte * workspace_bytes),
        )


if __name__ == "__main__":
    unittest.main()
