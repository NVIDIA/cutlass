import os
from collections import defaultdict
import hashlib
import inspect
import re
import sys
from contextlib import contextmanager

import pytest
from _pytest.compat import running_on_ci
from _pytest.terminal import TerminalReporter


def _stable_hash_int(text: str) -> int:
    """Process-independent hash. Builtin hash() is PYTHONHASHSEED-salted and
    would give different assignments per worker/job, breaking partition
    disjointness/completeness."""
    return int.from_bytes(hashlib.sha1(text.encode("utf-8")).digest()[:8], "big")


def _partition_index(nodeid: str, total: int) -> int:
    """Deterministic slice assignment for a test nodeid, in [0, total)."""
    return _stable_hash_int(nodeid) % total


def _parse_partition(spec: str):
    """Parse 'INDEX/TOTAL' -> (index, total). Raise pytest.UsageError if malformed."""
    try:
        index_str, total_str = spec.split("/")
        index, total = int(index_str), int(total_str)
    except (ValueError, AttributeError):
        raise pytest.UsageError(f"--partition expects 'INDEX/TOTAL', got {spec!r}")
    if total < 1 or not (0 <= index < total):
        raise pytest.UsageError(
            f"--partition out of range: index={index}, total={total} "
            f"(require total>=1 and 0<=index<total)"
        )
    return index, total


def pytest_addoption(parser):
    group = parser.getgroup("test_sharding", "Test sharding for pytest.")

    group.addoption(
        "--test-level",
        type=str,
        default="L2",
        choices=["L0", "L1", "L2"],
        help="Test level to run",
    )

    group.addoption(
        "--runtime-sm",
        type=str,
        default=None,
        help="The runtime SM for current test session.",
    )

    group.addoption(
        "--default-sm",
        type=str,
        default="all",
        choices=["auto", "folder", "all", "none"],
        help="The default SMs for tests without explicit arch marks. The valid options: "
        "'auto': Use the sm_xxx folder name pattern in the parent path of a certain pytest file to determine the default SMs. "
        "If no folder pattern is found, checks ci_default_arch registered on config by conftest (only for CI environment). "
        "Falls back to 'all' available SMs if neither matches. "
        "'folder': This mode is same as 'auto', except that it defaults to 'none' if no such pattern is found. "
        "'all': Use all available SMs as default irrespective of the directory structure. "
        "'none': No default SM (i.e., skip tests without explicit arch marks).",
    )

    group.addoption(
        "--deselect-not-run",
        action="store_true",
        help="Deselect the skipped, invalid, excluded test cases.",
    )

    group.addoption(
        "--test-set",
        type=str,
        default="normal",
        help="Comma-separated test sets to select. Valid values: normal, distributed-torch, distributed-jax. "
        "Default: normal. Example: --test-set normal,distributed-jax. "
        "'normal' includes all tests except those with @pytest.mark.distributed. "
        "'distributed-torch' includes tests marked @pytest.mark.distributed('torch'). "
        "'distributed-jax' includes tests marked @pytest.mark.distributed('jax').",
    )

    group.addoption(
        "--device",
        type=str,
        default="gpu",
        choices=["cpu", "gpu"],
        help="Select tests targeting a specific device. "
        "'gpu': Only run tests marked as device('gpu'). "
        "'cpu': Only run tests marked as device('cpu'). "
        "If not specified, the default device is gpu.",
    )

    group.addoption(
        "--error-for-skips",
        action="store_true",
        default=False,
        help="Treat skipped tests as errors",
    )

    group.addoption(
        "--partition",
        type=str,
        default=None,
        help="Run only one slice of the collected tests: 'INDEX/TOTAL' (0-based "
        "INDEX). A test is assigned to a slice by a stable hash of its nodeid, so "
        "slices are disjoint and their union is the full selection. Used to split a "
        "long testlist across parallel CI jobs. Absent: run everything.",
    )


@pytest.hookimpl(tryfirst=True)
def pytest_configure(config):
    # Register custom markers
    config.addinivalue_line(
        "markers",
        "L0(filter: Union[bool, Callable]=True): mark test to run on test level 0.\n"
        "The 'filter' accepts a bool or callable. "
        "True includes the test; False excludes it. "
        "A callable should return a bool to indicate inclusion/exclusion. "
        "All the valid parameters of the test function will be automatically set in the callable's locals, "
        "so test writers can use them directly.\n"
        "The mark decorator used at lower-level can override the same mark used at higher-level. "
        "For example, 'pytest.mark.L0(False)' at parameter-level can override 'pytest.mark.L0(True)' at function-level.",
    )
    config.addinivalue_line(
        "markers",
        "L1(filter: Union[bool, Callable]=True): same as L0, but for test level 1.",
    )
    config.addinivalue_line(
        "markers",
        "L2(filter: Union[bool, Callable]=True): same as L0, but for test level 2.",
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
        "distributed(backend): marker to tag distributed multi-GPU tests. "
        "Requires a backend argument: 'torch' or 'jax'. "
        "Selected with '--test-set distributed-torch' or '--test-set distributed-jax'.",
    )
    config.addinivalue_line(
        "markers",
        "arch(sms: List[str]): mark test to run on specific architectures.",
    )
    config.addinivalue_line(
        "markers",
        "device(name: str): mark test to run on specific device:  'gpu' or 'cpu'. Always use 'gpu' as default if not specified.",
    )

    def _filter_formatter(x):
        if callable(x):
            return x
        return (lambda: True) if x else (lambda: False)

    config.lvl_mark_values = mark_values(
        ("filter", lambda: True, lambda x: isinstance(x, bool) or callable(x), _filter_formatter),
    )
    config.invalid_case_mark_values = mark_values(
        ("checker", lambda: True, lambda x: callable(x), None),
    )
    config.xfail_case_mark_values = mark_values(
        ("checker", lambda: "expected to fail", lambda x: callable(x), None),
    )
    sm_p = re.compile(r"^\d+[af]?$")
    config.sm_pattern = sm_p
    config.arch_mark_values = mark_values(
        (
            "sms",
            None,
            lambda x: all(sm_p.match(str(sm)) for sm in x),
            lambda x: [str(x)] if not isinstance(x, list) else [str(sm) for sm in x],
        ),
    )
    config.device_mark_values = mark_values(
        ("name", "gpu", lambda x: x in ("gpu", "cpu"), lambda x: x.lower()),
    )


def mark_values(*args_list):
    def gen_mark_value(mark):
        assert len(mark.args) + len(mark.kwargs) <= len(args_list), (
            f"The marker '{mark.name}' accepts at most {len(args_list)} argument(s) "
            f"({', '.join(a[0] for a in args_list)}), but got {len(mark.args)} positional "
            f"and {len(mark.kwargs)} keyword argument(s)."
        )
        for idx, (key, default_value, validator, formatter) in enumerate(args_list):
            if idx < len(mark.args):
                value = mark.args[idx]
            else:
                value = mark.kwargs.get(key, default_value)
            if formatter:
                value = formatter(value)
            assert validator(
                value
            ), f"The value '{value}' for 'pytest.mark.{mark.name}({key}=...)' is invalid!"
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


def _remove_callspec_level_marks(item, test_level):
    """Remove parameter-level tier marks from item.own_markers.

    Pytest copies parameter marks into both callspec.marks and own_markers, but
    other collection hooks may append more markers afterwards. Match by object
    identity instead of assuming callspec marks are still the list tail.
    """
    callspec_marks = list(item.callspec.marks)
    callspec_mark_ids = {id(mark) for mark in callspec_marks}
    item.own_markers[:] = [
        mark for mark in item.own_markers if id(mark) not in callspec_mark_ids
    ]
    return [mark for mark in callspec_marks if mark.name != test_level]


def pytest_collection_modifyitems(config, items):
    # Keep only current partition's tests
    partition_spec = config.getoption("--partition")
    if partition_spec:
        index, total = _parse_partition(partition_spec)
        kept, dropped = [], []
        for item in items:
            (kept if _partition_index(item.nodeid, total) == index else dropped).append(
                item
            )
        if dropped:
            items[:] = kept
            config.hook.pytest_deselected(items=dropped)

    test_level = config.getoption("--test-level")

    def cc2sm(cc, extra):
        if cc is None:
            # unknown target cc
            sms = [None]
        elif cc < 90:
            sms = [f"{cc}"]
        else:
            sms = [f"{cc}a"]
            if extra:
                if cc > 90:
                    sms.append(f"{cc}f")
                sms.append(f"{cc}")
        return sms

    runtime_device = config.getoption("--device")

    # The SMs compatible with the current runtime session
    compatible_SMs = [None]
    # The fallback SM for tests without explicit arch marks
    default_SMs = [None]

    if runtime_sm := config.getoption("--runtime-sm"):
        assert config.sm_pattern.match(runtime_sm), f"Invalid runtime SM: {runtime_sm}"
        compatible_SMs = [runtime_sm]
        target_cc = int(runtime_sm.rstrip("af"))
        default_SMs = cc2sm(target_cc, extra=False)
    elif runtime_device == "gpu":
        script_dir = os.path.dirname(os.path.abspath(__file__))
        if script_dir not in sys.path:
            sys.path.append(script_dir)

        from device_info import compute_capability

        if compute_capability:
            target_cc = int(compute_capability)
        else:
            target_cc = None
            print("Warning: Cannot determine the target compute capability!")

        compatible_SMs = cc2sm(target_cc, extra=True)
        default_SMs = cc2sm(target_cc, extra=False)
    elif runtime_device == "cpu":
        compatible_SMs = [None]
        default_SMs = ["80"]

    item_runnable_SMs = defaultdict(list)

    item_groups = {
        "invalid": [],  # [(item, reason), ...]
        "excluded": [],  # [(item, reason), ...]
        "selected": [],  # [item, ...]
    }

    def get_closest_level_mark(item_):
        if test_level and (lvl_ := item_.get_closest_marker(test_level)):
            (filter_,) = config.lvl_mark_values(lvl_)
        else:
            filter_ = lambda: True
        return filter_

    registered_sm_markers = set()

    def add_sm_marker(item_, tag):
        marker_name = f"sm_{tag}"
        if marker_name not in registered_sm_markers:
            config.addinivalue_line(
                "markers",
                f"{marker_name}: synthetic marker auto-derived from arch(...) "
                "by test_sharding.py",
            )
            registered_sm_markers.add(marker_name)
        item_.add_marker(getattr(pytest.mark, marker_name))

    rootdir = os.path.abspath(config.rootdir)
    sm_dir_pattern = re.compile(r"^sm_(\d+([af]?))$")
    default_sm_type = config.getoption("--default-sm")
    test_sets = [s.strip() for s in config.getoption("--test-set").split(",")]

    # Pre-compute ci_default_arch lookup table (CI only, used by "auto" mode).
    # Flat list of (rel_path_to_rootdir, sm) tuples, sorted longest-first.
    _ci_arch_table = None
    if default_sm_type == "auto" and running_on_ci():
        ci_map = getattr(config, "ci_default_arch", {})
        if ci_map:
            flat = {}
            for conftest_file, subdir_map in ci_map.items():
                scope_dir = os.path.dirname(os.path.abspath(conftest_file))
                if not os.path.isdir(scope_dir):
                    raise ValueError(
                        f"ci_default_arch: scope directory does not exist: {scope_dir} "
                        f"(from {conftest_file})"
                    )
                scope_rel = os.path.relpath(scope_dir, rootdir)
                for subdir, sm in subdir_map.items():
                    sm_str = str(sm)
                    if not config.sm_pattern.match(sm_str):
                        raise ValueError(
                            f"ci_default_arch: invalid SM value '{sm}' for "
                            f"subdir '{subdir}' (from {conftest_file})"
                        )
                    flat[os.path.join(scope_rel, subdir)] = sm_str
            _ci_arch_table = sorted(flat.items(), key=lambda x: len(x[0]), reverse=True)

    def get_closest_arch_mark(item_):
        if hasattr(item_, "callspec"):
            for mark in item_.callspec.marks:
                if mark.name == "arch":
                    sms, *_ = config.arch_mark_values(mark)
                    return sms
        if mark := item_.get_closest_marker("arch"):
            sms, *_ = config.arch_mark_values(mark)
            return sms

        if default_sm_type == "all":
            return default_SMs
        elif default_sm_type == "none":
            return [None]
        else:
            dir_path = os.path.dirname(os.path.abspath(item_.fspath))
            rel_path = os.path.relpath(dir_path, rootdir)
            for path_part in reversed(rel_path.split(os.sep)):
                if matched := sm_dir_pattern.match(path_part):
                    if matched.group(2):
                        return [matched.group(1)]
                    else:
                        return cc2sm(int(matched.group(1)), False)
            else:
                if default_sm_type == "auto":
                    if _ci_arch_table:
                        for prefix, sm in _ci_arch_table:
                            if rel_path == prefix or rel_path.startswith(
                                prefix + os.sep
                            ):
                                if sm[-1:] in ("a", "f"):
                                    return [sm]
                                else:
                                    return cc2sm(int(sm), False)
                    return default_SMs
                else:
                    return [None]

    def get_device_mark(item_):
        if hasattr(item_, "callspec"):
            for mark in item_.callspec.marks:
                if mark.name == "device":
                    name, *_ = config.device_mark_values(mark)
                    return name
        if mark := item_.get_closest_marker("device"):
            name, *_ = config.device_mark_values(mark)
            return name
        return "gpu"  # default device is gpu

    for item in items:
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
                item_groups["invalid"].append((item, invalid_reason))
                continue

        # check if the test case is compatible with the runtime device
        test_device = get_device_mark(item)
        if test_device != runtime_device:
            item_groups["excluded"].append((item, "device not matched"))
            continue

        # check if the test case is compatible with the target arch
        if sms := get_closest_arch_mark(item):
            if compatible_SMs == [None]:
                # If runtime SM is unknown, we assume it's compatible with all
                # test-declared SMs. This is a safe choice to avoid false exclusion.
                item_runnable_SMs[item.nodeid].extend(sms)
            else:
                for sm in sms:
                    if sm in compatible_SMs:
                        item_runnable_SMs[item.nodeid].append(sm)
        if not item_runnable_SMs[item.nodeid]:
            item_groups["excluded"].append((item, "arch not matched"))
            continue

        # check if the test case belongs to the selected test sets
        item_sets = set()
        dist_marker = item.get_closest_marker("distributed")
        if dist_marker:
            if not dist_marker.args:
                raise pytest.UsageError(
                    f"{item.nodeid}: @pytest.mark.distributed requires a backend "
                    f"argument ('torch' or 'jax')"
                )
            backend = dist_marker.args[0]
            if backend not in ("torch", "jax"):
                raise pytest.UsageError(
                    f"{item.nodeid}: @pytest.mark.distributed got invalid backend "
                    f"'{backend}', expected 'torch' or 'jax'"
                )
            item_sets.add(f"distributed-{backend}")
        if not item_sets:
            item_sets.add("normal")

        if not item_sets & set(test_sets):
            label = ",".join(sorted(item_sets))
            item_groups["excluded"].append((item, f"test set '{label}' not matched"))
            continue

        # check if the test case belongs to the selected test level
        if hasattr(item, "callspec"):
            param_args_cnt = 0
            for mark in item.own_markers:
                if mark.name == "parametrize":
                    param_args_cnt += 1

            # clean up the level marks from parameter-level
            if param_args_cnt > 0:
                item.own_markers.extend(_remove_callspec_level_marks(item, test_level))

            # get the function-level filter
            flt = get_closest_level_mark(item)

            # check the function-level filter
            flt_ = params_in_context(flt)
            included = flt_(params)

            # gather the parameter-level selection count and check the filter
            param_selection_cnt = 0
            for mark in item.callspec.marks:
                if test_level and mark.name == test_level:
                    (param_flt,) = config.lvl_mark_values(mark)
                    param_result = param_flt()
                    if not param_result:
                        # force deselect the test case
                        included = False
                    else:
                        param_selection_cnt += 1

            assert param_args_cnt >= param_selection_cnt
            # force select the test case at parameter-level
            if param_args_cnt != 0 and param_args_cnt == param_selection_cnt:
                included = True
        else:
            flt = get_closest_level_mark(item)
            included = flt()

        if included:
            item_groups["selected"].append(item)
        else:
            item_groups["excluded"].append((item, f"non-{test_level}"))

    # Assign markers to each subtest
    for item, invalid_reason in item_groups["invalid"]:
        item.add_marker(pytest.mark.skip(reason=invalid_reason), append=False)
    for item, excluded_reason in item_groups["excluded"]:
        item.add_marker(pytest.mark.skip(reason=excluded_reason), append=False)
    for item in item_groups["selected"]:
        item.add_marker(f"{test_level}", append=False)
        if item_runnable_SMs[item.nodeid]:
            item.add_marker(
                pytest.mark.arch(sms=item_runnable_SMs[item.nodeid]), append=False
            )
            for tag in item_runnable_SMs[item.nodeid]:
                if tag is not None:
                    add_sm_marker(item, tag)
        if not item.get_closest_marker("device"):
            item.add_marker(pytest.mark.device(name="gpu"), append=False)

    if config.getoption("--deselect-not-run"):
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

    if item.config.getoption("--error-for-skips"):
        if report.skipped and call.excinfo.errisinstance(pytest.skip.Exception):
            report.outcome = "failed"
            report.longrepr = (
                f"Error for skipped test - {call.excinfo._getreprcrash().message}"
            )


if hasattr(TerminalReporter, "_printcollecteditems"):
    _origin = TerminalReporter._printcollecteditems

    def _custom(self, items):
        sharding_infos = {}
        for item in items:
            info = ""
            if skip_mark := item.get_closest_marker("skip"):
                status = "SKIPPED"
                info = skip_mark.kwargs.get("reason", "")
                info = info.replace("\n", "\\n").strip()
            else:
                status = "SELECTED"
                parts = []
                if device_mark := item.get_closest_marker("device"):
                    name, *_ = item.config.device_mark_values(device_mark)
                    parts.append(f"device {name}")
                if arch_mark := item.get_closest_marker("arch"):
                    sms, *_ = item.config.arch_mark_values(arch_mark)
                    if sms == [None]:
                        sms = ["unknown"]
                    parts.append(f"SMs {','.join(sms)}")
                info = ";".join(parts)
            sharding_infos[item.nodeid] = f" ({status}:{info})"

        @contextmanager
        def augment_sharding_info():
            tw_line = type(self._tw).line

            def augmented_line(self, msg):
                if msg in sharding_infos:
                    msg += sharding_infos[msg]
                tw_line(self, msg)

            type(self._tw).line = augmented_line
            yield
            type(self._tw).line = tw_line

        with augment_sharding_info():
            _origin(self, items)

    TerminalReporter._printcollecteditems = _custom
