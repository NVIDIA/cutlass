# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


from pathlib import Path

import pytest

pytest_plugins = ["pytester"]


@pytest.fixture
def run_sharded(pytester):
    pytester.syspathinsert(Path(__file__).resolve().parents[1])

    def run():
        recorder = pytester.inline_run(
            "-p", "test_sharding", "--runtime-sm", "80", "--test-level", "L0"
        )
        reports = recorder.getreports("pytest_runtest_logreport")
        passed = [report.nodeid for report in reports if report.when == "call" and report.passed]
        skipped = [report.nodeid for report in reports if report.skipped]
        assert len(passed) == len(set(passed))
        assert len(skipped) == len(set(skipped))
        assert set(passed).isdisjoint(skipped)
        return recorder, set(passed), set(skipped)

    return run


def test_plain_functions_have_independent_ratios(pytester, run_sharded):
    pytester.makepyfile(test_plain="""
        import pytest

        @pytest.mark.L0(0.25)
        def test_first():
            pass

        @pytest.mark.L0(0.75)
        def test_second():
            pass
    """)
    recorder, passed, skipped = run_sharded()
    recorder.assertoutcome(passed=2)
    assert passed == {"test_plain.py::test_first", "test_plain.py::test_second"}
    assert not skipped


def test_plain_functions_in_different_modules_are_independent(pytester, run_sharded):
    source = """
        import pytest

        @pytest.mark.L0(0.5)
        def test_case():
            pass
    """
    pytester.makepyfile(test_first=source, test_second=source)
    recorder, passed, skipped = run_sharded()
    recorder.assertoutcome(passed=2)
    assert passed == {"test_first.py::test_case", "test_second.py::test_case"}
    assert not skipped


def test_parameterized_methods_keep_separate_class_groups(pytester, run_sharded):
    pytester.makepyfile(test_parameterized="""
        import pytest

        class TestFirst:
            @pytest.mark.L0(0.5)
            @pytest.mark.parametrize("value", range(4))
            def test_case(self, value):
                pass

        class TestSecond:
            @pytest.mark.L0(0.5)
            @pytest.mark.parametrize("value", range(4))
            def test_case(self, value):
                pass
    """)
    recorder, passed, skipped = run_sharded()
    recorder.assertoutcome(passed=4, skipped=4)
    for class_name in ["TestFirst", "TestSecond"]:
        group = {
            f"test_parameterized.py::{class_name}::test_case[{value}]"
            for value in range(4)
        }
        assert len(passed & group) == 2
        assert len(skipped & group) == 2
        assert group <= passed | skipped
