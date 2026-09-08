#!/usr/bin/env python3
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import os
import sys
import argparse
import json
import shlex
import subprocess
import shutil
import re
import signal
import time
import builtins
import contextlib
import glob
import hashlib
from importlib.metadata import PackageNotFoundError, distribution
from pathlib import Path
from urllib.parse import urlparse
import importlib.util
from itertools import product


def ensure_plugins_installed():
    """Install the CUTLASS 4.7 pytest plugins into the virtual environment."""
    plugins_src = (Path(__file__).resolve().parent / "plugins").resolve()

    if sys.prefix == sys.base_prefix:
        raise RuntimeError(
            "Refusing to install CUTLASS pytest plugins into a non-venv Python "
            f"({sys.executable})."
        )

    try:
        dist = distribution("cutlass-pytest-plugins")
        direct_url_path = Path(dist._path) / "direct_url.json"  # type: ignore[attr-defined]
        info = json.loads(direct_url_path.read_text() or "{}")
        pyproject = plugins_src / "pyproject.toml"
        pyproject_stale = pyproject.stat().st_mtime > direct_url_path.stat().st_mtime
        if (
            not pyproject_stale
            and info.get("dir_info", {}).get("editable", False)
            and Path(urlparse(info.get("url", "")).path).resolve() == plugins_src
        ):
            return
    except (PackageNotFoundError, json.JSONDecodeError, OSError, AttributeError):
        pass

    print(f"[run_pytest] installing CUTLASS pytest plugins from {plugins_src}")
    proc = subprocess.run(
        [
            sys.executable,
            "-m",
            "pip",
            "install",
            "--quiet",
            "--no-deps",
            "-e",
            str(plugins_src),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            "Failed to install CUTLASS pytest plugins "
            f"(exit {proc.returncode}):\n{proc.stderr}"
        )


def _xdist_args(workers, disabled):
    if disabled:
        return ["--numprocesses=0", "--dist=no"]

    workers = workers or "auto"
    xdist_args = ["--dist=worksteal", f"--numprocesses={workers}"]
    if not os.environ.get("CI"):
        xdist_args.append("--maxprocesses=16")
    return xdist_args


def run_pytest_cmd(args, runtime_arch, test_set):
    valid_test_sets = ["normal", "distributed-torch", "distributed-jax"]
    assert test_set in valid_test_sets, (
        f"Invalid test set: {test_set}. Valid test set should be in {valid_test_sets}"
    )

    perf_enabled = "--perf" in args.user_args
    disable_xdist = perf_enabled or test_set != "normal" or str(args.workers) == "0"

    # prepare the pytest command
    pytest_cmd = []
    pytest_cmd.extend(
        [
            sys.executable,
            "-m",
            "pytest",
            "-o",
            "junit_logging=all",
            "-o",
            "junit_log_passing_tests=True",
            "-o",
            "xfail_strict=True",
            "-o",
            "strict_markers=True",
            "-p",
            "no:cov",
            "-p",
            "no:rerunfailures",
            "--import-mode=importlib",
            "-rA",
            "--showlocals",
            "--durations=100",
            f"--test-level={args.test_level}",
            "--deselect-not-run",
            f"--rootdir={Path(args.env.get('CUTLASS_SOURCE_DIR', Path(__file__).parents[2])).resolve()}",
        ]
    )

    if runtime_arch:
        args.env["CUTE_DSL_ARCH"] = f"sm_{runtime_arch}"

        arch_info = f"[CUTE_DSL_ARCH={args.env['CUTE_DSL_ARCH']}]"
        pytest_cmd.extend(
            [
                f"--runtime-sm={runtime_arch}",
                f"--default-sm={args.default_sm}",
            ]
        )
    else:
        args.env["CUTE_DSL_ARCH"] = "sm_80"  # set a default arch
        args.env["CUTE_DSL_DRYRUN"] = "1"

        arch_info = "[CPU]"
        pytest_cmd.extend(
            [
                "--device=cpu",
                f"--default-sm={args.default_sm}",
            ]
        )

    if args.test_files:
        pytest_cmd.extend(["-o", f"python_files={args.test_files}"])

    pytest_cmd.extend(["--test-set", test_set])

    if args.partition:
        pytest_cmd.extend(["--partition", args.partition])

    warning_action = "error" if args.warning_as_error else "default"
    for warning_cls in ("FutureWarning",):
        pytest_cmd.append(f"-W{warning_action}::{warning_cls}")

    # Always enable warning-as-error for some warnings
    for warning_cls in (
        "pytest.PytestCollectionWarning",
        "pytest.PytestUnknownMarkWarning",
    ):
        pytest_cmd.append(f"-Werror::{warning_cls}")

    if importlib.util.find_spec("pytest_benchmark"):
        pytest_cmd.append("--benchmark-disable")

    pytest_cmd.extend(args.test_path)
    pytest_cmd.extend(args.user_args)

    # check if the pytest cases can be collected
    pytest_collect_cmd = list(pytest_cmd)
    if disable_xdist:
        pytest_collect_cmd.extend(_xdist_args(0, disabled=True))
    pytest_collect_cmd.extend(["--collect-only", "--quiet"])
    result_code = pytest_cmd_runner(pytest_collect_cmd, args.env, arch_info, True)
    if result_code == 5:
        print("No pytest cases collected.")
        return True

    pytest_cmd.extend(_xdist_args(args.workers, disable_xdist))

    if args.report_path:
        test_path_hash = hashlib.md5(":".join(args.test_path).encode()).hexdigest()[0:8]
        report_file = f"{args.report_path}/pytest_report_{runtime_arch}_{test_set}_{test_path_hash}.xml"
        if os.path.exists(report_file):
            print(
                f"The report file '{report_file}' already exists, it will be overwritten!",
                level="debug",
            )
        pytest_cmd.append(f"--junit-xml={report_file}")
        pytest_cmd.append(f"--junit-prefix={arch_info}")

    if test_set == "distributed-torch":
        for py_path in (sys.prefix, sys.base_prefix):
            torchrun_path = os.path.join(py_path, "bin", "torchrun")
            if os.path.exists(torchrun_path):
                break
        else:
            raise FileNotFoundError("torchrun not found in the system!")
        pytest_cmd = [
            sys.executable,
            torchrun_path,
            "--nproc_per_node=auto",
        ] + pytest_cmd[1:]
        args.env["OMP_NUM_THREADS"] = "1"
    elif test_set == "distributed-jax":
        pass
    else:
        if "OMP_NUM_THREADS" in args.env:
            del args.env["OMP_NUM_THREADS"]

    if strtobool(os.environ.get("VERBOSE", "0")):
        env_info = " ".join([f"{k}={shlex.quote(v)}" for k, v in args.env.items()])
        env_info = f"env {env_info}"
    else:
        env_info = ""

    print(f"Running pytest command {arch_info}: {env_info} {shlex.join(pytest_cmd)}")
    result_code = pytest_cmd_runner(pytest_cmd, args.env, arch_info)
    print(
        f"{arch_info} pytest is finished with exit code: {result_code}", level="debug"
    )
    return result_code == 0


def pytest_cmd_runner(cmd, env, arch_info, collect_only=False):
    process = None
    try:
        # Use Popen with new session to properly forward SIGINT to pytest
        # This allows pytest to handle the signal and coordinate with xdist workers
        if collect_only:
            out = subprocess.DEVNULL
            err = subprocess.DEVNULL
        else:
            out = None
            if shutil.which("addr2line"):
                err = subprocess.PIPE
            else:
                err = None

        process = subprocess.Popen(
            cmd,
            env=env,
            shell=False,
            text=True,
            bufsize=1,
            stdout=out,
            stderr=err,
            start_new_session=True,
        )

        try:
            if err == subprocess.PIPE:
                # post-process backtrace of crash log
                # to translate address to file:line
                xlate_bt = False
                frame_idx = 0
                for line in process.stderr:
                    line = line.rstrip("\n")
                    if xlate_bt:
                        if matched := re.search(
                            r"\s*(.+)\((.*\+\w+)\)\[(\w+)\]$", line
                        ):
                            binary_path = matched.group(1)
                            offset = matched.group(2)
                            addr = matched.group(3)
                            line = f"#{frame_idx:02d} {addr} {binary_path}({offset})"
                            frame_idx += 1
                            try:
                                a2l = (
                                    subprocess.check_output(
                                        [
                                            "addr2line",
                                            "-Cfipe",
                                            binary_path,
                                            offset,
                                        ],
                                        text=True,
                                    )
                                    .strip()
                                    .splitlines()
                                )
                                line += "".join(f"\n    {_}" for _ in a2l)
                            except subprocess.CalledProcessError as e:
                                line += f"\n    addr2line failed:\n{e}"
                        else:
                            xlate_bt = False
                    elif "C stack trace" in line:
                        xlate_bt = True
                        frame_idx = 0

                    sys.stderr.write(f"{line}\n")

            # Wait for pytest to complete
            result_code = process.wait()
        except KeyboardInterrupt:
            # Forward SIGINT to pytest process group so it can handle gracefully
            print("Interrupting pytest ...", level="fatal")
            try:
                os.killpg(process.pid, signal.SIGINT)
            except ProcessLookupError:
                # Process group already terminated
                pass
            except Exception as e:
                print(f"Error forwarding signal: {e}", level="fatal")

            try:
                # Give pytest some time to handle the signal gracefully
                curr = time.time()
                start = curr
                wait = 30  # seconds to wait for pytest to handle the signal
                while process.poll() is None and (curr - start) < wait:
                    try:
                        result_code = process.wait(timeout=1)
                        break
                    except subprocess.TimeoutExpired:
                        curr = time.time()
                        if curr - start < 2:
                            print(
                                "Please wait a moment for termination ...",
                                level="fatal",
                            )
                        continue
                    except KeyboardInterrupt:
                        print("Force killing pytest ...", level="fatal")
                        with contextlib.suppress(ProcessLookupError, OSError):
                            os.killpg(process.pid, signal.SIGKILL)
                        result_code = process.wait()
                        break
                else:
                    # Timeout reached, force kill
                    print(
                        "Pytest didn't respond to interrupt. Force killing ...",
                        level="fatal",
                    )
                    with contextlib.suppress(ProcessLookupError, OSError):
                        os.killpg(process.pid, signal.SIGKILL)
                    result_code = process.wait()
            except Exception as e:
                print(f"Error during cleanup: {e}", level="fatal")
                result_code = 1

            sys.exit(result_code)

        return result_code

    except Exception as e:
        print(f"Error when running pytest command {arch_info}: {e}", level="fatal")
        if process is not None:
            with contextlib.suppress(Exception):
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
        return 1


def strtobool(val):
    val = val.lower()
    if val in ("y", "yes", "t", "true", "on", "1"):
        return 1
    elif val in ("n", "no", "f", "false", "off", "0"):
        return 0
    else:
        raise ValueError("invalid truth value %r" % (val,))


def print(*args, level="info", **kwargs):
    if sys.stdout.isatty():
        args = list(args)
        if level == "info":
            color = "32"
        elif level == "debug":
            color = "33"
        elif level == "fatal":
            color = "31"
        else:
            color = "30"
        args[0] = f"\033[{color}m\033[1m{args[0]}"
        args[-1] = f"{args[-1]}\033[0m"

        if level == "fatal":
            args[0] = f"\n{args[0]}"
    builtins.print(*args, flush=True, **kwargs)


KnownTestRootPaths = [
    "test/examples/CuTeDSL",
]


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--arch", type=str, default=None, help="The arch of the device GPU."
    )
    parser.add_argument(
        "--device",
        type=str,
        choices=["gpu", "cpu"],
        default="gpu",
        help="The device to run the tests on. Default to 'gpu'.",
    )
    parser.add_argument(
        "--test-level",
        type=str,
        default="L2",
        choices=["L0", "L1", "L2"],
        help="The level of the test.",
    )
    parser.add_argument(
        "--package",
        type=str,
        default="",
        help="The package name or the path to the package.",
    )
    parser.add_argument(
        "--workers", type=str, default="", help="The number of workers."
    )
    parser.add_argument(
        "--report-path",
        type=str,
        default="",
        help="The path to save the JUnit XML report.",
    )
    parser.add_argument(
        "--test-path",
        type=str,
        nargs="+",
        default=[],
        help="The path to the test file/directory or test node id. "
        "The path can be a absolute path, a relative path to the current working directory, "
        "a relative path to the repository root, or a file/sub-path under the known test directories. "
        f"The known test directories: {KnownTestRootPaths}.",
    )
    parser.add_argument(
        "--test-set",
        type=str,
        default="normal",
        help="Comma-separated test sets to run. Valid values: normal, "
        "distributed-torch, distributed-jax.",
    )
    parser.add_argument(
        "--test-files",
        type=str,
        default=None,
        help="The python file name's pattern that pytest will recognize as test files.",
    )
    parser.add_argument(
        "--partition",
        type=str,
        default=None,
        help="Run one deterministic INDEX/TOTAL slice of the collected tests.",
    )
    parser.add_argument(
        "--warning-as-error",
        action="store_true",
        help="Treat deprecation and future warnings as errors.",
    )
    parser.add_argument(
        "--default-sm",
        type=str,
        default="auto",
        choices=["auto", "folder", "all", "none"],
        help="The default SMs for tests without explicit arch marks. "
        "See detailed description in test_sharding plugin.",
    )
    parser.add_argument(
        "--jit-cache-size",
        type=int,
        default=10,
        help="The JIT cache size in number of elements.",
    )

    args, unknown = parser.parse_known_args()
    args.user_args = unknown

    # override the arguments with the environment variables
    cast_env_vars = {
        "test_path": lambda v: v.split(","),
        "warning_as_error": lambda v: strtobool(v),
        "jit_cache_size": lambda v: int(v),
        "user_args": lambda v: re.split(r"\s+", v),
    }
    for arg_name in args.__dict__:
        env_name = arg_name.upper()
        if env_name in os.environ:
            setattr(
                args,
                arg_name,
                cast_env_vars.get(arg_name, lambda v: v)(os.environ[env_name]),
            )
            print(
                f"The value of the argument --{arg_name.replace('_', '-')} is overridden to "
                f"{getattr(args, arg_name)} by the environment variable '{env_name}'",
                level="debug",
            )

    if not args.test_path:
        raise ValueError("--test-path (or TEST_PATH environment variable) is required!")
    else:
        # formalize the test path
        cwd_path = Path.cwd()
        repo_root = Path(
            os.environ.get("CUTLASS_SOURCE_DIR", Path(__file__).parents[2])
        ).resolve()
        known_test_root_paths = [f"{repo_root}/{path}" for path in KnownTestRootPaths]

        known_test_paths = []
        for known_test_root_path in known_test_root_paths:
            test_dirs = glob.glob(f"{known_test_root_path}/**/", recursive=True)
            known_test_paths.extend(
                [d for d in test_dirs if not d.endswith("__pycache__/")]
            )
            tests = glob.glob(f"{known_test_root_path}/**/*.py", recursive=True)
            known_test_paths.extend(tests)

        formalized_paths = []
        for test_path in args.test_path:
            path_ingrs = test_path.split("::")
            test_file = Path(path_ingrs[0])
            test = None
            if not test_file.is_absolute():
                if Path(cwd_path / test_file).exists():
                    test = Path(cwd_path / test_file).resolve()
                elif Path(repo_root / test_file).exists():
                    test = Path(repo_root / test_file).resolve()
                else:
                    test_paths = []
                    test_paths.append(os.path.sep + str(test_file))
                    test_paths.append(str(test_file) + os.path.sep)
                    for known_test_path in known_test_paths:
                        if any(known_test_path.endswith(p) for p in test_paths):
                            test = known_test_path
                            break
            elif test_file.exists():
                test = test_file

            assert test, f"The test path '{test_path}' is not found!"
            path_ingrs[0] = str(test)
            formalized_path = "::".join(path_ingrs)
            formalized_paths.append(formalized_path)
            if test_path != formalized_path:
                print(
                    f"The test path '{test_path}' is formalized to '{formalized_path}'",
                    level="debug",
                )
        args.test_path = formalized_paths

    return args


if __name__ == "__main__":
    args = parse_args()

    ensure_plugins_installed()

    # set the environment variables:
    args.env = os.environ.copy()
    args.env["COLUMNS"] = "120"  # the line width of progress dots
    python_path = []
    plugin_path = Path(__file__).parent / "plugins"
    python_path.append(str(plugin_path))
    if args.package and os.path.sep in args.package:
        args.package = os.path.abspath(args.package)
        python_path.append(args.package)
        package_path = Path(args.package)
        package_base = (
            str(package_path)
            if (package_path / "cutlass").is_dir()
            else os.path.dirname(args.package)
        )
        if os.path.exists(f"{package_base}/third_party"):
            args.env["CUDA_TOOLKIT_PATH"] = f"{package_base}/third_party/cuda"
    else:
        # Handle wheel test case
        import sysconfig

        package_base = f"{sysconfig.get_path('purelib')}/nvidia_cutlass_dsl"
        assert os.path.exists(package_base), f"'{package_base}' does not exist!"
        args.package = f"{package_base}/python_packages"
        assert os.path.exists(args.package), f"'{args.package}' does not exist!"

    def cute_dsl_libs():
        libs = [
            "libcute_dsl_runtime.so",
        ]
        lib_path_hints = [
            f"{package_base}/lib",
            f"{package_base}/../lib",
        ]
        for lib_name in libs:
            for lib_path in lib_path_hints:
                lib_full_path = f"{lib_path}/{lib_name}"
                if os.path.exists(lib_full_path):
                    yield os.path.abspath(lib_full_path)
                    break

    args.env["CUTE_DSL_LIBS"] = ":".join(cute_dsl_libs())

    python_path.extend(os.environ.get("PYTHONPATH", "").split(":"))
    args.env["PYTHONPATH"] = ":".join(python_path)
    args.env["PYTHONUNBUFFERED"] = "1"
    # debugging issues caused by the async execution of the kernel
    args.env["CUDA_LAUNCH_BLOCKING"] = "1"
    # enable runtime assertions for all tests
    args.env["CUTE_DSL_ENABLE_ASSERTIONS"] = "1"
    # show full stack traces on failure
    args.env["CUTE_DSL_SHOW_STACKTRACE"] = "1"
    # enable cuda dialect by default
    args.env["CUTE_DSL_USE_CUDA_DIALECT"] = "1"
    # set the DSL cache to be very small to avoid OOM in long-running jobs
    args.env["CUTE_DSL_JIT_CACHE_MAX_ELEMS"] = str(args.jit_cache_size)
    # Disable caching by default for local runs to surface invalid memory accesses.
    if os.environ.get("CI"):
        args.env.pop("PYTORCH_NO_CUDA_MEMORY_CACHING", None)
    elif "PYTORCH_NO_CUDA_MEMORY_CACHING" not in os.environ:
        args.env["PYTORCH_NO_CUDA_MEMORY_CACHING"] = "1"

    if args.report_path:
        os.makedirs(args.report_path, exist_ok=True)

    if shutil.which("nvidia-smi") and "distributed-torch" not in args.test_set:
        output = subprocess.check_output(["nvidia-smi", "-L"], encoding="utf-8")
        gpu_count = len(
            [line for line in output.splitlines() if line.startswith("GPU")]
        )
        if gpu_count > 1:
            args.test_set += ",distributed-torch"

    if args.device == "gpu":
        if not args.arch:
            sys.path.append(str(plugin_path))
            from device_info import compute_capability

            if not compute_capability:
                raise ValueError(
                    "Failed to get CUDA compute capability! "
                    "Please ensure that cuda-python is installed and a CUDA device is available!"
                )
            args.arch = compute_capability

        if re.match(r"^\d+$", args.arch):
            args.arch = int(args.arch)
            if args.arch < 90:
                runtime_archs = [f"{args.arch}"]
            elif args.arch == 90:
                runtime_archs = [f"{args.arch}a", f"{args.arch}"]
            else:
                runtime_archs = [f"{args.arch}a", f"{args.arch}f", f"{args.arch}"]
        else:
            runtime_archs = args.arch.split(",")
            if any(not re.match(r"^\d+[af]?$", arch) for arch in runtime_archs):
                raise ValueError(
                    rf"Invalid arch: {args.arch}! Valid Pattern: '\d+[af]?'."
                )
    else:
        runtime_archs = [None]

    regressions = list(
        product(
            runtime_archs, [test_set.strip() for test_set in args.test_set.split(",")]
        )
    )

    passed = True
    for idx, (runtime_arch, test_set) in enumerate(regressions):
        arch_info = f"arch={runtime_arch}" if runtime_arch else "cpu"
        print(
            f"\nRegression ({idx + 1}/{len(regressions)}) for {arch_info}, {test_set}",
            level="debug",
        )
        status = run_pytest_cmd(
            args,
            runtime_arch,
            test_set=test_set,
        )
        passed = passed and status

    if not passed:
        sys.exit(1)
