# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

from importlib.util import find_spec


class GlobalOptions:
    """
    Singleton class that configures global options for CUTLASS API.

    This can be used to enable or disable certain features of the API. For example,
    the user can enable TVM-FFI support to allow for the use of framework-level tensors
    at run time.

    Example:
    ```python
      GlobalOptions().use_tvm_ffi = True
    ```
    """

    _instance = None

    def __new__(cls):
        """
        Create a new singleton instance of the GlobalOptions class only once.
        """
        if cls._instance is None:
            cls._instance = super().__new__(cls)

            has_tvm_ffi = find_spec("tvm_ffi") is not None
            cls._instance._options = {
                "use_tvm_ffi": has_tvm_ffi,
            }
        return cls._instance

    @property
    def use_tvm_ffi(self) -> bool:
        """
        Check if TVM FFI support is enabled.
        Default: True if `tvm_ffi` is installed.

        When enabled, conversions from DLPack compatible tensors to cute.Tensor is via TVM FFI.
        Additionally, invoking the compiled kernel happens via TVM FFI.
        Both can offer significant (3x-10x) speedups.

        Dependencies:
        - Required: `tvm_ffi` (pip install apache-tvm-ffi)
        - Optional: `torch_c_dlpack_ext` (pip install torch-c-dlpack-ext)
        """
        return self._options["use_tvm_ffi"]

    @use_tvm_ffi.setter
    def use_tvm_ffi(self, value: bool) -> None:
        if value and not find_spec("tvm_ffi"):
            raise ImportError(
                "TVM FFI is not installed, please install it via `pip install apache-tvm-ffi`."
            )
        self._options["use_tvm_ffi"] = value
