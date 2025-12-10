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
import math
import random
from collections import defaultdict, UserDict
from pathlib import Path
import inspect
import re
import sys

import pytest
from _pytest.assertion.util import running_on_ci


# The dict class to record the default SMs for all subtests under certain directory.
class DefaultSMs(UserDict):
    def __init__(self, config):
        super().__init__()
        self.rootdir = os.path.abspath(config.rootdir)

    def __setitem__(self, conftest_file, sms):
        dir_path = os.path.dirname(os.path.abspath(conftest_file))
        rel_path = os.path.relpath(dir_path, self.rootdir)
        if isinstance(sms, (list, set)):
            sms = [str(sm) for sm in sms]
        else:
            sms = [str(sms)]
        self.data[rel_path] = sms

    def __getitem__(self, test_file):
        dir_path = os.path.dirname(os.path.abspath(test_file))
        rel_path = os.path.relpath(dir_path, self.rootdir)
        sms = None
        if rel_path in self.data:
            sms = self.data[rel_path]
        else:
            for parent in Path(rel_path).parents:
                if str(parent) in self.data:
                    sms = self.data[str(parent)]
                    break
        return sms


def pytest_addoption(parser):
    group = parser.getgroup(
        "test_sharding",
        "Test sharding for pytest. ",
    )

    group.addoption(
        "--test-level",
        type=str,
        default="L2",
        choices=["L0", "L1", "L2"],
        help="Test level to run",
    )

    group.addoption(
        "--random-seed", type=int, default=0, help="Seed for random subtest selection"
    )

    group.addoption(
        "--target-cc",
        type=int,
        default=None,
        help="The target device compute capability to run on",
    )

    group.addoption(
        "--runtime-sm",
        type=str,
        default=None,
        help="The runtime SM for current test session.",
    )

    group.addoption(
        "--deselect-not-run",
        action="store_true",
        help="Deselect the skipped, invalid, excluded test cases.",
    )

    group.addoption(
        "--only-large-case",
        action="store_true",
        help="Only select the test cases marked by @pytest.mark.large_case(...). This option implies --deselect-not-run.",
    )


@pytest.hookimpl(tryfirst=True)
def pytest_configure(config):
    seed = config.getoption("--random-seed")
    random.seed(seed)

    config.default_SMs = DefaultSMs(config)

    # Register custom markers
    config.addinivalue_line(
        "markers",
        "L0(ratio: float=1.0, filter: Callable=lambda: True): mark test to run on test level 0.\n"
        "The 'ratio' value stands for the probability of each test case being selected from all subtests of a certain test function. "
        "The valid range of 'ratio' is [0, 1.0]. '0' means explicitly exclude the test case(s). "
        "'1' means explicitly select the test case(s). The default value is 1. "
        "If a test case isn't explicitly marked, then it is implicitly tagged with 'pytest.mark.L0(1)'.\n"
        "The 'filter' argument should be a callable that returns a boolean to indicate "
        "if the current test case is included(True)/excluded(False). All the valid parameters of the test function "
        "will be automatically set in its locals, so test writers can use them directly. "
        "By using the filter function, more flexible test case selections can be applied.\n"
        "The mark decorator used at lower-level can override the same mark used at higher-level. "
        "For example, 'pytest.mark.L0(0)' at parameter-level can override 'pytest.mark.L0(ratio=1)' at function-level.\n"
        "Note that when the mark is used at parameter-level, the ratio value other than 0 or 1 is meaningless.\n"
    )
    config.addinivalue_line(
        "markers",
        "L1(ratio: float=1.0, filter: Callable=lambda: True): same as L0, but for test level 1.",
    )
    config.addinivalue_line(
        "markers",
        "L2(ratio: float=1.0, filter: Callable=lambda: True): same as L0, but for test level 2.",
    )
    config.addinivalue_line(
        "markers",
        "invalid_case(checker: Callable=lambda: True): marker to indicate certain test cases as invalid, and skip them when pytest collects test cases.\n"
        "The 'checker' argument should be a callable that returns True or a string to describe the invalid reason if it's an invalid case. "
        "Otherwise, return False, empty string or None. The test case parameters will be automatically set in the checker's locals, test writers can use them directly. ",
    )
    config.addinivalue_line(
        "markers",
        "xfail_case(checker: Callable=lambda: 'expected to fail'): marker to mark a test case as xfail given the parameters of the test function.\n"
        "The test function parameters will be automatically set in the checker's locals, so test writers can use them directly. "
        "If it's an xfail case, return a string to describe the xfail reason. Otherwise return None. This is similar to pytest.xfail(reason='xfail reason'). "
        "If you want to be more specific as to why the test is failing, the checker can return a single exception like TypeError, "
        "or a tuple of exception along with the regex string that matches the string representation of the exception, i.e. (RuntimeError, 'error string'). "
        "This is similar to pytest.raises(expected_exception, match='error string').",
    )
    config.addinivalue_line(
        "markers",
        "large_case(checker: Callable=lambda: True): marker to tag certain test cases that will occupy a large chunk of memory.\n"
        "The 'checker' argument should be a callable that returns True if it's a large case. Otherwise, return False. "
        "The test function parameters will be automatically set in the checker's locals, so test writers can use them directly. "
        "Note that the large cases are skipped by default. They will only be selected when the command line option '--only-large-case' is specified.",
    )
    config.addinivalue_line(
        "markers",
        "arch(sms: List[str]): mark test to run on specific architectures.",
    )

    config.lvl_mark_values = mark_values(
        ("ratio", 1.0, lambda x: 0 <= x <= 1.0, None),
        ("filter", lambda: True, lambda x: callable(x), None),
    )
    config.shard_mark_values = mark_values(
        ("size", None, lambda x: type(x) is int and x > 0, None),
    )
    config.invalid_case_mark_values = mark_values(
        ("checker", lambda: True, lambda x: callable(x), None),
    )
    config.xfail_case_mark_values = mark_values(
        ("checker", lambda: "expected to fail", lambda x: callable(x), None),
    )
    config.large_case_mark_values = mark_values(
        ("checker", lambda: True, lambda x: callable(x), None),
    )
    config.arch_mark_values = mark_values(
        (
            "sms",
            None,
            lambda x: isinstance(x, (list, str, int)),
            lambda x: [str(x)] if not isinstance(x, list) else [str(sm) for sm in x],
        ),
    )


def mark_values(*args_list):
    def gen_mark_value(mark):
        assert len(mark.args) <= len(
            args_list
        ), f"The marker '{mark.name}' specifies more arguments than expected!"
        for idx, (key, default_value, validator, formatter) in enumerate(args_list):
            if idx < len(mark.args):
                value = mark.args[idx]
            else:
                value = mark.kwargs.get(key, default_value)
            assert validator(
                value
            ), f"The value '{value}' for 'pytest.mark.{mark.name}({key}=...)' is invalid!"
            if formatter:
                value = formatter(value)
            yield value

    supported_args = set(arg[0] for arg in args_list)

    def get_mark_values(mark):
        assert (
            set(mark.kwargs.keys()) <= supported_args
        ), f"The marker '{mark.name}' used unknown arguments: {set(mark.kwargs.keys()) - supported_args}.\n"
        return tuple(gen_mark_value(mark))

    return get_mark_values


def params_in_context(func):
    if defined_params := inspect.signature(func).parameters.keys():

        def wrapper(full_params):
            return func(*[full_params[k] for k in defined_params])

    else:

        def wrapper(full_params):
            context = func.__globals__.copy()
            context.update(full_params)
            return eval(func.__code__, context)

    return wrapper


def pytest_collection_modifyitems(config, items):
    test_level = config.getoption("--test-level")

    if runtime_sm := config.getoption("--runtime-sm"):
        assert re.match(r"^\d+[af]?$", runtime_sm), f"Invalid runtime SM: {runtime_sm}"
        compatible_SMs = [runtime_sm]
    elif target_cc := config.getoption("--target-cc"):
        if target_cc < 90:
            compatible_SMs = {f"{target_cc}"}
        elif target_cc == 90:
            compatible_SMs = {f"{target_cc}a", f"{target_cc}"}
        else:
            compatible_SMs = {f"{target_cc}a", f"{target_cc}f", f"{target_cc}"}
    else:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        if script_dir not in sys.path:
            sys.path.append(script_dir)

        from device_info import compute_capability

        if compute_capability:
            target_cc = int(compute_capability)
        else:
            raise SystemError("Failed to get CUDA compute capability!")

        if target_cc < 90:
            compatible_SMs = {f"{target_cc}"}
        else:
            compatible_SMs = {f"{target_cc}a"}

    item_runnable_SMs = defaultdict(list)

    item_groups = defaultdict(
        lambda: {
            "ratio": None,  # random selection ratio of test function
            "candidates": [],  # candidates of test function
            "invalid": [],  # marked by invalid_case
            "excluded": [],  # marked by skip or L0(ratio=0)
            "arch_excluded": [],  # arch not matched
            "force_selected": [],  # marked by L0(ratio=1.0)
            "rand_selected": [],  # randomly selected
            "rand_skipped": [],  # randomly skipped
        }
    )

    def get_closest_level_mark(item_):
        if test_level and (lvl_ := item_.get_closest_marker(test_level)):
            ratio_, filter_ = config.lvl_mark_values(lvl_)
        else:
            ratio_ = 1.0
            filter_ = lambda: True
        return ratio_, filter_

    def get_closest_arch_mark(item_):
        if hasattr(item_, "callspec"):
            for mark in item_.callspec.marks:
                if mark.name == "arch":
                    sms, *_ = config.arch_mark_values(mark)
                    return sms
        if mark := item_.get_closest_marker("arch"):
            sms, *_ = config.arch_mark_values(mark)
            return sms
        if running_on_ci():
            return config.default_SMs[item_.fspath]
        else:
            return None

    for item in items:
        func_name = item.nodeid[: len(item.originalname) - len(item.name)]
        params = item.callspec.params if hasattr(item, "callspec") else {}

        if item.get_closest_marker("skip"):
            continue

        # check if the test case is valid
        if invalid_case := item.get_closest_marker("invalid_case"):
            checker, *_ = config.invalid_case_mark_values(invalid_case)
            checker_ = params_in_context(checker)
            if msg := checker_(params):
                invalid_reason = (
                    msg if isinstance(msg, str) else "invalid params combination"
                )
                item_groups[func_name]["invalid"].append((item, invalid_reason))
                continue

        # check if the test case is compatible with the target arch
        sms = get_closest_arch_mark(item)
        if sms is None:
            # assume compatible if no arch mark found
            item_runnable_SMs[item.nodeid].extend(compatible_SMs)
        else:
            for sm in sms:
                if sm in compatible_SMs:
                    item_runnable_SMs[item.nodeid].append(sm)
        if not item_runnable_SMs[item.nodeid]:
            item_groups[func_name]["arch_excluded"].append(item)
            continue

        if hasattr(item, "callspec"):
            param_args_cnt = 0
            for mark in item.own_markers:
                if mark.name == "parametrize":
                    param_args_cnt += 1

            # clean up the level marks from parameter-level
            if param_args_cnt > 0:
                refined_marks = []
                for mark in reversed(item.callspec.marks):
                    if mark.name != test_level:
                        refined_marks.append(mark)
                    assert mark is item.own_markers[-1]
                    item.own_markers.pop()
                item.own_markers.extend(reversed(refined_marks))

            # get the function-level ratio and filter
            ratio, flt = get_closest_level_mark(item)

            # check the function-level filter
            flt_ = params_in_context(flt)
            if not flt_(params):
                ratio = 0

            # gather the parameter-level selection count and check the malformed usage
            param_selection_cnt = 0
            for mark in item.callspec.marks:
                if test_level and mark.name == test_level:
                    param_ratio, *_ = config.lvl_mark_values(mark)
                    assert param_ratio in [0, 1], (
                        f"The 'ratio' parameter can only be 1/True or 0/False (but now it's {param_ratio}) to denote mandatorily selecting or excluding current test case "
                        f"for testing when the marker '{test_level}' is used at the parameter-level.\n"
                        f'Irregular subtest: "{item.nodeid}"'
                    )
                    if param_ratio == 0:
                        # force deselect the test case
                        ratio = 0
                    else:
                        param_selection_cnt += 1

            assert param_args_cnt >= param_selection_cnt
            # force select the test case at parameter-level
            if param_args_cnt != 0 and param_args_cnt == param_selection_cnt:
                ratio = 1.0
        else:
            ratio, _ = get_closest_level_mark(item)

        # check if the test case is large
        if large_case := item.get_closest_marker("large_case"):
            checker, *_ = config.large_case_mark_values(large_case)
            checker_ = params_in_context(checker)
            if bool(checker_(params)) ^ bool(config.getoption("--only-large-case")):
                item_groups[func_name]["excluded"].append(item)
                continue
        else:
            if config.getoption("--only-large-case"):
                item_groups[func_name]["excluded"].append(item)
                continue

        if ratio > 0:
            if ratio == 1.0:
                item_groups[func_name]["force_selected"].append(item)
            else:
                item_groups[func_name]["candidates"].append(item)

                if item_groups[func_name]["ratio"] is None:
                    item_groups[func_name]["ratio"] = ratio
                assert item_groups[func_name]["ratio"] == ratio, (
                    f"The ratio of subtests for {func_name} is not consistent.\n"
                    f'First occurrence: {item_groups[func_name]["candidates"][0].nodeid} -> {item_groups[func_name]["ratio"]}\n'
                    f"Current: {item.nodeid} -> {ratio}"
                )
        else:
            item_groups[func_name]["excluded"].append(item)

    # Randomly select subtests
    for func_name, test_info in item_groups.items():
        if test_info["candidates"]:
            if test_info["ratio"] <= 0 or test_info["ratio"] > 1.0:
                raise ValueError("Split ratio must be between (0, 1.0]")

            random.shuffle(test_info["candidates"])
            split_point = math.ceil(test_info["ratio"] * len(test_info["candidates"]))
            test_info["rand_selected"] += test_info["candidates"][:split_point]
            test_info["rand_skipped"] += test_info["candidates"][split_point:]

    # Assign markers to each subtest
    for test_info in item_groups.values():
        for item, invalid_reason in test_info["invalid"]:
            item.add_marker(pytest.mark.skip(reason=invalid_reason), append=False)
        for item in test_info["excluded"]:
            item.add_marker(pytest.mark.skip(reason=f"non-{test_level}"), append=False)
        for item in test_info["arch_excluded"]:
            item.add_marker(pytest.mark.skip(reason=f"arch not matched"), append=False)
        for item in test_info["rand_skipped"]:
            item.add_marker(pytest.mark.skip(reason=f"randomly"), append=False)
        for item in test_info["force_selected"] + test_info["rand_selected"]:
            item.add_marker(f"{test_level}", append=False)
            item.add_marker(
                pytest.mark.arch(sms=item_runnable_SMs[item.nodeid]), append=False
            )
            if any(
                "report_resource_usage" == name
                for name, _ in config.pluginmanager.list_name_plugin()
            ):
                # item.add_marker(pytest.mark.report_uss(interval=0.1), append=False)
                # item.add_marker(pytest.mark.report_duration, append=False)
                ...

    if config.getoption("--deselect-not-run") or config.getoption("--only-large-case"):
        selected = []
        deselected = []
        for item in items:
            if item.get_closest_marker("skip"):
                deselected.append(item)
            else:
                selected.append(item)
        items[:] = selected
        config.hook.pytest_deselected(items=deselected)


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()

    if report.outcome != "skipped" and call.when == "call":
        if xfail_case := item.get_closest_marker("xfail_case"):
            params = item.callspec.params if hasattr(item, "callspec") else {}
            checker, *_ = item.config.xfail_case_mark_values(xfail_case)
            checker_ = params_in_context(checker)
            if xfail_info := checker_(params):
                if report.outcome == "passed":
                    report.wasxfail = "expected to fail, but passed"
                else:
                    if isinstance(xfail_info, str):
                        report.outcome = "skipped"
                        report.wasxfail = xfail_info
                    elif isinstance(xfail_info, tuple):
                        if isinstance(call.excinfo.value, xfail_info[0]):
                            if re.search(xfail_info[1], str(call.excinfo.value)):
                                report.outcome = "skipped"
                                report.wasxfail = str(call.excinfo.value)
                            else:
                                report.longrepr = f"Expect '{xfail_info[1]}', but got '{call.excinfo.value}'"
                        else:
                            report.longrepr = f"Expect '{xfail_info[0]}', but got '{type(call.excinfo.value)}'"
                    else:
                        if isinstance(call.excinfo.value, xfail_info):
                            report.outcome = "skipped"
                            report.wasxfail = str(call.excinfo.value)
                        else:
                            report.longrepr = f"Expect exception '{xfail_info}', but got '{type(call.excinfo.value)}'"


def pytest_report_collectionfinish(config, start_path, startdir, items):
    if not config.getoption("--collect-only"):
        return

    report = []
    selected_count = 0
    for item in items:
        additional_info = ""
        if skip_mark := item.get_closest_marker("skip"):
            status = "SKIPPED"
            additional_info = skip_mark.kwargs.get("reason", "")
        else:
            status = "SELECTED"
            if sms := item.get_closest_marker("arch").kwargs.get("sms"):
                additional_info += f"SMs {','.join(sms)}"
            selected_count += 1

        line = f"SHARDING {item.nodeid} ({status}:{additional_info})"
        report.append(line)

    report.append(
        f"\n{len(items)} tests collected, {selected_count} tests selected, {len(items) - selected_count} tests skipped."
    )

    if report:
        return [
            "\n============= Sharding Report Start =============\n",
            *report,
            "\n=============  Sharding Report End  =============\n",
        ]
