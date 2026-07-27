# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import os
import random
import sys
from pathlib import Path

import pytest
import torch

import cutlass.operators as ops

from test_utils.common import _TEST_LEVEL_ENV_VAR



# The ``--test-level`` CLI option is provided by the ``test_sharding``
# plugin registered above.  This hook bridges the CLI value to the
# ``CUTLASS_OPERATORS_TEST_LEVEL`` env var.
#
# Priority:
#   1. Explicit ``--test-level`` on the command line (wins if passed; note
#      ``test_sharding`` sets its own default).
#   2. Pre-existing ``CUTLASS_OPERATORS_TEST_LEVEL`` env var (manual override).
#   3. Default ``"L0"``.
def pytest_configure(config):
    cli_explicit = any(
        arg == "--test-level" or arg.startswith("--test-level=") for arg in sys.argv
    )
    test_level = (
        config.getoption("--test-level")
        if cli_explicit
        else os.environ.get(_TEST_LEVEL_ENV_VAR, "L0")
    )
    os.environ[_TEST_LEVEL_ENV_VAR] = test_level
    config.option.test_level = test_level


#
# Before each test, save the GlobalOptions dict
# After each test, restore the GlobalOptions dict
#
@pytest.fixture(autouse=True)
def save_restore_global_options():
    saved = ops.GlobalOptions().save()
    yield
    ops.GlobalOptions().restore(saved)


#
# Fixtures for toggling the TVM FFI global option and forcing its enablement or disablement
#
@pytest.fixture(
    params=[True, False], ids=["use_tvm_ffi=True", "use_tvm_ffi=False"], autouse=False
)
def fixture_toggle_tvm_ffi(request):
    ops.GlobalOptions().use_tvm_ffi = request.param


@pytest.fixture(autouse=False)
def fixture_enable_tvm_ffi():
    ops.GlobalOptions().use_tvm_ffi = True


@pytest.fixture(autouse=False)
def fixture_disable_tvm_ffi():
    ops.GlobalOptions().use_tvm_ffi = False


#
# Fixture for setting random seed
#
@pytest.fixture(autouse=True)
def fixture_random_seed():
    random.seed(2025)
    torch.manual_seed(2025)


