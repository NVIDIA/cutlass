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

import os

import pytest

import cutlass_api


@pytest.mark.parametrize(
    "notebook_name, supported_ccs",
    [
        ("000_gemm.ipynb", [100, 103]),
        ("001_gemm_with_fused_epilogue.ipynb", [100, 103]),
        ("002_bring_your_own_kernel.ipynb", [80, 89, 90, 100, 103, 120, 121]),
        ("003_host_latency_best_practices.ipynb", [100, 103]),
    ],
)
def test_notebooks(notebook_name, supported_ccs):
    possible_cc_strs = []
    for cc in supported_ccs:
        arch_conditional_ccs = [90, 100, 101, 103, 120, 121]
        family_conditional_ccs = [100, 103]

        if cc in family_conditional_ccs:
            possible_cc_strs.extend([f"sm_{cc}f", f"sm_{cc}a"])
        elif cc in arch_conditional_ccs:
            possible_cc_strs.append(f"sm_{cc}a")
        else:
            possible_cc_strs.append(f"sm_{cc}")

    cute_dsl_arch = os.environ.get("CUTE_DSL_ARCH", "")

    # Add empty string to allow running without macro set
    possible_cc_strs.append("")

    if (
        cutlass_api.utils.device_cc() not in supported_ccs
        or cute_dsl_arch not in possible_cc_strs
    ):
        # Each test should gracefully exit(0) for CCs that are not supported, but
        # the nbconvert-based runner below has issues with this. Thus, we manually
        # skip here.
        pytest.skip(
            f"This notebook requires a GPU with compute capability {supported_ccs}"
        )

    notebook_dir = os.path.join(os.path.dirname(__file__), "..", "..", "examples")
    full_notebook_path = os.path.join(notebook_dir, notebook_name)

    import nbconvert
    import nbformat

    with open(full_notebook_path, "r") as file:
        notebook = nbformat.read(file, as_version=4)
    ep = nbconvert.preprocessors.ExecutePreprocessor(timeout=600, kernel_name="python3")

    # Execute the notebook. This call will error out on any assertions or errors in the
    # notebook itself. Allow these to propagate up so the test will fail on notebook failure.
    ep.preprocess(notebook, {"metadata": {"path": notebook_dir}})
