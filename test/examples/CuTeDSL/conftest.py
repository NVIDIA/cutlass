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
import logging
import sys
from pathlib import Path

import torch
import numpy as np


project_root = Path(__file__).resolve().parent.parent.parent.parent
example_path = project_root / "examples" / "python" / "CuTeDSL"
utils_path = project_root / "test" / "utils"
sys.path.append(str(example_path))
sys.path.append(str(utils_path))

# The helper class to prevent modification of sys.path from test files
# Only allow modification of sys.path from pytest monkeypatch API calls
class ImmutableSysPath(list):
    mutating_methods = {
        "append",
        "extend",
        "insert",
        "remove",
        "pop",
        "clear",
        "reverse",
        "sort",
        "__setitem__",
        "__delitem__",
    }

    for mtd in mutating_methods:
        def mutating_method(self, *args, mtd=mtd, **kwargs):
            frame = sys._getframe().f_back
            if (
                frame
                and hasattr(frame, "f_locals")
                and "__file__" in frame.f_locals
                and frame.f_locals["__file__"].startswith(str(project_root))
            ):
                err_msg = (
                    "Modification of sys.path is forbidden in test file! "
                    "Please use pytest monkeypatch.syspath_prepend(...) instead."
                )
                raise RuntimeError(err_msg)
            else:
                return getattr(super(), mtd)(*args, **kwargs)

        locals()[mtd] = mutating_method

    def __init__(self, initial=None):
        if initial is None:
            initial = []
        super().__init__(initial)


sys.path = ImmutableSysPath(list(sys.path))

pytest_plugins = ["test_sharding"]

def pytest_addoption(parser):
    parser.addoption(
        "--sample-interval",
        action="store",
        type=int,
        default=4,
        help="If value x is provided, then 1 / x of random picked tests will be run",
    )


@pytest.fixture
def sample_interval(request):
    return request.config.getoption("--sample-interval")


# Removes all StreamHandlers from loggers at the end of test session
# This prevents errors when atexit-registered functions try to use loggers
# whose handlers have already been closed during pytest teardown
@pytest.fixture(scope="session", autouse=True)
def cleanup_logging_handlers():
    try:
        yield
    finally:
        loggers = [logging.getLogger()] + list(
            logging.Logger.manager.loggerDict.values()
        )
        for logger in loggers:
            handlers = getattr(logger, "handlers", [])
            for handler in handlers:
                if isinstance(handler, logging.StreamHandler):
                    logger.removeHandler(handler)


@pytest.fixture(autouse=True, scope="module")
def torch_sanity_check():
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run example tests!")


@pytest.fixture(autouse=True)
def torch_empty_cache():
    """
    Automatically empty the torch CUDA cache at the end of each test, to reduce risk of OOM errors.
    """
    yield
    if torch.cuda.is_available():
        torch.cuda.empty_cache()


@pytest.fixture(autouse=True)
def torch_seed(request):
    if torch.cuda.is_available():
        seed = hash(request.node.nodeid) % 2**32
        torch.manual_seed(seed)


@pytest.fixture(autouse=True)
def numpy_seed(request):
    seed = hash(request.node.nodeid) % 2**32
    np.random.seed(seed)
