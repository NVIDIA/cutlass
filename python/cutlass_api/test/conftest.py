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


import pytest

import cutlass_api
from cutlass_api.config import GlobalOptions

#
# Before each test, save the GlobalOptions dict
# After each test, restore the GlobalOptions dict
#

global_options = {}


def setup_function():
    global global_options
    GlobalOptions().save(global_options)


def teardown_function():
    global global_options
    GlobalOptions().restore(global_options)


#
# Fixtures for toggling the TVM FFI global option and forcing its enablement or disablement
#


@pytest.fixture(
    params=[True, False], ids=["use_tvm_ffi=True", f"use_tvm_ffi=False"], autouse=False
)
def fixture_toggle_tvm_ffi(request):
    GlobalOptions().use_tvm_ffi = request.param


@pytest.fixture(autouse=False)
def fixture_enable_tvm_ffi(request):
    GlobalOptions().use_tvm_ffi = True


@pytest.fixture(autouse=False)
def fixture_disable_tvm_ffi(request):
    GlobalOptions().use_tvm_ffi = False
