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

import sys
from pathlib import Path

import pytest

import test_utils  # isort: skip


@pytest.mark.parametrize(
    "notebook_name, operator_targets",
    [
        ("000_gemm.ipynb", ["80", "90a", "100f"]),
        ("001_gemm_with_fused_epilogue.ipynb", ["100f"]),
        ("002_bring_your_own_kernel.ipynb", ["80"]),
        ("003_host_latency_best_practices.ipynb", ["80", "90a", "100f"]),
        ("004_fake_tensors.ipynb", ["80"]),
        ("005_grouped_gemm_contiguous_offset.ipynb", ["100a"]),
        ("006_block_scaled_gemm.ipynb", ["100f"]),
    ],
)
def test_notebooks(notebook_name, operator_targets, monkeypatch):
    test_utils.skip_if_unsupported_target(operator_targets)

    notebook_dir = Path(__file__).parent / ".." / ".." / "examples"
    full_notebook_path = notebook_dir / notebook_name

    import os
    import subprocess

    import nbformat
    from nbconvert.preprocessors import ExecutePreprocessor

    # Preload torch's libgomp and libc10 in the kernel subprocess so their
    # static TLS is allocated before jupyter/jaxlib exhaust the budget.
    # Without this the kernel's `import torch` fails with "cannot allocate
    # memory in static TLS block". libgomp is the heaviest TLS user so it
    # must come first.
    from cutlass.operators.utils.common import is_torch_available

    if sys.platform.startswith("linux") and is_torch_available():
        import torch

        torch_lib = Path(torch.__file__).parent / "lib"
        preload_libs = []
        for pattern in ("libgomp*.so*", "libc10.so"):
            preload_libs.extend(sorted(str(p) for p in torch_lib.glob(pattern)))
        if preload_libs:
            existing = os.environ.get("LD_PRELOAD", "")
            value = ":".join(preload_libs + ([existing] if existing else []))
            monkeypatch.setenv("LD_PRELOAD", value)

    # Register the current Python interpreter as the python3 kernel
    subprocess.run(
        [sys.executable, "-m", "ipykernel", "install", "--user", "--name", "python3"],
        check=True,
        capture_output=True,
    )

    with full_notebook_path.open() as file:
        notebook = nbformat.read(file, as_version=4)
    ep = ExecutePreprocessor(timeout=600, kernel_name="python3")

    # Execute the notebook. This call will error out on any assertions or errors in the
    # notebook itself. Allow these to propagate up so the test will fail on notebook failure.
    ep.preprocess(notebook, {"metadata": {"path": notebook_dir}})
