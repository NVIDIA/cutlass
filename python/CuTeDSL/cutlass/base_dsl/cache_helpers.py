# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
This module provides jit cache load/dump helper functions
"""

import os
import uuid
import random
import tempfile
import pwd
import time
from pathlib import Path
import hashlib
from functools import lru_cache
import tempfile

from .utils.logger import log
from .jit_executor import JitCompiledFunction

from .._mlir import ir

# =============================================================================
# Jit Cache Helper functions
# =============================================================================


def get_current_user():
    """
    Get the current user. This is used to determine the path to the cache directory.
    """
    # Try to get the user from the environment variable first
    user = os.getenv("USER") or os.getenv("USERNAME")
    if not user:
        # Fallback for Unix-like systems
        user = pwd.getpwuid(os.getuid()).pw_name
    return user


# default_generated_ir_path is the path to the cache directory.
# If `CUTE_DSL_CACHE_DIR` is set, it is used as the cache directory.
# Otherwise, it is set to a directory controled by TMPDIR defaulting
# to /tmp/${USER}/cutlass_python_cache.
if not (default_generated_ir_path := os.getenv("CUTE_DSL_CACHE_DIR", None)):

    tmp_dir = Path(os.environ.get("TMPDIR", tempfile.gettempdir()))

    def get_reusable_temp_dir(name):
        path = tmp_dir / f"{get_current_user()}/{name}"
        path.mkdir(parents=True, exist_ok=True)
        return str(path)

    try:
        default_generated_ir_path = get_reusable_temp_dir("cutlass_python_cache")
    except Exception as e:
        default_generated_ir_path = str(tmp_dir / "cutlass_python_cache")
        print(f"Could not determine user, using default path. Error: {e}")

@lru_cache(maxsize=1)
def get_default_file_dump_root():
    """
    Get the default file dump root.
    """
    dump_root = Path.cwd()
    return dump_root


def load_ir(file, asBytecode=False):
    """Load generated IR from a file.

    :param file: The path to the file to load.
    :type file: str
    :param asBytecode: Whether to load the IR as bytecode, defaults to False
    :type asBytecode: bool, optional
    :return: The function name and the IR module
    :rtype: tuple[str, ir.Module]
    """
    assert "mlir" in file
    func_name = file.split(".mlir")[0].split("dsl_")[-1]
    with ir.Context() as ctx:
        with open(file, "rb" if asBytecode else "r") as f:
            module = ir.Module.parse(f.read())

    return func_name, module


def make_unique_filename(fpath: Path, new_ext: str = None) -> Path:
    """
    Generate a unique filename with an optional new extension.

    :param fpath: The path to the file to generate a unique filename for.
    :type fpath: Path
    :param new_ext: The new extension to add to the filename, defaults to None
    :type new_ext: str, optional
    :return: The unique filename
    :rtype: Path
    """
    random_part = random.randint(0, 999999)
    timestamp = time.time()
    hash_input = f"{fpath}_{timestamp}_{random_part}".encode()
    hash_code = hashlib.md5(hash_input).hexdigest()[:16]  # Shorter hash for readability
    stem_with_hash = f"{fpath.stem}_{hash_code}"
    return fpath.with_name(stem_with_hash).with_suffix(new_ext or fpath.suffix)


def save_ir(
    dsl_name: str,
    module: object,
    fname: str,
    output_dir: str | None = None,
    as_bytecode: bool = False,
    bytecode_writer: callable = None,
) -> str:
    """Save generated IR to a file.

    :param dsl_name: The name of the DSL.
    :type dsl_name: str
    :param module: The IR module to save.
    :type module: object
    :param fname: The name of the file to save.
    :type fname: str
    """
    initial_name = f"{dsl_name.lower()}_{fname}.mlir"
    save_path = Path(output_dir if output_dir else tempfile.gettempdir())
    save_fname = save_path / initial_name
    # Random ID to avoid any collisions
    rnd_id = str(uuid.uuid4())
    pid = os.getpid()
    # use temp dir to be robust against program interruptions
    temp_dir = os.path.join(save_path, f"tmp.pid_{pid}_{rnd_id}")
    # If the process exits abnormally, may leave a temporary folder. Needs to be removed manually.
    os.makedirs(temp_dir, exist_ok=False)
    temp_fname = os.path.join(temp_dir, initial_name)

    if as_bytecode:
        with open(temp_fname, "wb") as f:
            if bytecode_writer:
                bytecode_writer(f)
            else:
                module.operation.write_bytecode(f)
    else:
        with open(temp_fname, "w") as f:
            print(module, file=f)
    # os.replace is guaranteed to be atomic on POSIX systems if it succeeds
    # so filepath cannot see a partial write
    os.replace(temp_fname, save_fname)
    os.removedirs(temp_dir)
    log().debug("Generated IR saved into %s", save_fname)
    return save_fname


def check_func_name(jit_cache, func_name):
    """Check if the function name is in the cache.
    If not, create a new JitCompiledFunction object and add it to the cache.

    :param jit_cache: The cache to check.
    :type jit_cache: dict
    :param func_name: The name of the function to check.
    :type func_name: str
    :return: The cache
    :rtype: dict
    """
    if not func_name in jit_cache:
        jit_cache[func_name] = JitCompiledFunction(
            None, None, None, None, None, [], False, None
        )
    return jit_cache


def load_cache_from_path(dsl_name, cache_limit, path=default_generated_ir_path):
    """Load cache from a directory path.

    :param dsl_name: The name of the DSL.
    :type dsl_name: str
    :param cache_limit: The limit of the cache.
    :type cache_limit: int
    :param path: The path to the cache directory, defaults to default_generated_ir_path
    :type path: str, optional
    :return: The cache
    :rtype: dict
    """
    if not os.path.exists(path):
        return dict()
    files = os.listdir(path)
    jit_cache = dict()
    try:
        for idx, file in enumerate(files):
            if idx >= int(cache_limit):
                break
            # identify dsl prefix
            if not file.startswith(f"{dsl_name.lower()}"):
                continue
            if ".mlir" in file:
                func_name, ir_module = load_ir(
                    os.path.join(path, file), asBytecode=True
                )
                jit_cache = check_func_name(jit_cache, func_name)
                jit_cache[func_name].ir_module = ir_module
    except Exception as e:
        print(f"{dsl_name} failed with loading generated IR cache.", e)
        jit_cache = dict()
    return jit_cache


def dump_cache_to_path(
    dsl_name,
    jit_cache,
    cache_limit,
    path=default_generated_ir_path,
    bytecode_writer=None,
):
    """Dump the cache to a directory path.

    :param dsl_name: The name of the DSL.
    :type dsl_name: str
    :param jit_cache: The cache to dump.
    :type jit_cache: dict
    :param cache_limit: The limit of the cache.
    :type cache_limit: int
    :param path: The path to the cache directory, defaults to default_generated_ir_path
    :type path: str, optional
    :param bytecode_writer: The bytecode writer to use, defaults to None
    :type bytecode_writer: callable, optional
    """
    log().info("JIT cache : dumping [%s] items=[%s]", dsl_name, len(jit_cache))
    if not path:
        path = default_generated_ir_path
    os.makedirs(path, exist_ok=True)
    try:
        for idx, [key, value] in enumerate(jit_cache.items()):
            if idx >= int(cache_limit):
                break
            save_ir(
                dsl_name,
                value.ir_module,
                key,
                output_dir=path,
                as_bytecode=True,
                bytecode_writer=bytecode_writer,
            )
    except Exception as e:
        print(f"{dsl_name} failed with caching generated IR", e)
