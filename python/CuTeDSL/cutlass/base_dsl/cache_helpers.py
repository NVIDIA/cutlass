# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
import io
import sys
import uuid
import random
import tempfile
import pwd
import time
from pathlib import Path
import hashlib
from functools import lru_cache
import zlib

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


def write_bytecode_with_crc32(f, module):
    """Write the bytecode to the file and calculate the crc32 checksum.

    :param f: The file to write the bytecode to.
    :type f: file
    :param module: The IR module to write the bytecode to.
    :type module: object
    """
    s = io.BytesIO()
    module.operation.write_bytecode(s)
    content = s.getvalue()
    crc = zlib.crc32(content)
    s.write(crc.to_bytes(4, sys.byteorder))
    f.write(s.getvalue())
    return


def read_bytecode_and_check_crc32(f):
    """
    Read the bytecode from the file and check the crc32 checksum.

    :param f: The file to read the bytecode with appended CRC32 from.
    :type f: file
    :return: The bytecode content if checksum matches.
    :rtype: bytes
    :raises DSLRuntimeError: If checksum does not match.
    """
    content = f.read()
    if len(content) < 4:
        raise DSLRuntimeError(
            f"File {f.name} does not contain enough data for CRC32 checksum."
        )
    bytecode = content[:-4]
    crc_appended = content[-4:]
    crc_appended_int = int.from_bytes(crc_appended, sys.byteorder)
    crc_computed = zlib.crc32(bytecode)
    if crc_appended_int != crc_computed:
        raise DSLRuntimeError(
            f"CRC32 checksum mismatch! Expected {crc_computed}, got {crc_appended_int}"
        )
    return ir.Module.parse(bytecode)


def load_ir(file, asBytecode=False, bytecode_reader=None):
    """Load generated IR from a file.

    :param file: The path to the file to load.
    :type file: str
    :param asBytecode: Whether to load the IR as bytecode, defaults to False
    :type asBytecode: bool, optional
    :param bytecode_reader: The bytecode reader to use, defaults to None
    :type bytecode_reader: callable, optional
    :return: The function name and the IR module
    :rtype: tuple[str, ir.Module]
    """
    assert "mlir" in file
    func_name = file.split(".mlir")[0].split("dsl_")[-1]
    with ir.Context() as ctx:
        with open(file, "rb" if asBytecode else "r") as f:
            if bytecode_reader:
                module = bytecode_reader(f)
            else:
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
    :param output_dir: The path to the output directory, defaults to None
    :type output_dir: str, optional
    :param as_bytecode: Whether to save the IR as bytecode, defaults to False
    :type as_bytecode: bool, optional
    :param bytecode_writer: The bytecode writer to use, defaults to None
    :type bytecode_writer: callable, optional
    :return: The path to the saved file
    :rtype: str
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


def load_cache_from_path(
    dsl_name, file, path=default_generated_ir_path, bytecode_reader=None
):
    """Load cache from a directory path.

    :param dsl_name: The name of the DSL.
    :type dsl_name: str
    :param file: The name of the file to load.
    :type file: str
    :param path: The path to the cache directory, defaults to default_generated_ir_path
    :type path: str, optional
    :param bytecode_reader: The bytecode reader to use, defaults to None
    :type bytecode_reader: callable, optional
    :return: The cache
    :rtype: dict
    """
    if not os.path.exists(path):
        return None
    ret = None
    try:
        file = f"{dsl_name.lower()}_{file}.mlir"
        if os.path.exists(os.path.join(path, file)):
            _, module = load_ir(
                os.path.join(path, file),
                asBytecode=True,
                bytecode_reader=bytecode_reader,
            )
            ret = JitCompiledFunction(module, None, None, None, None, [], False, None)
    except Exception as e:
        log().warning(
            f"{dsl_name} failed with loading generated IR cache for {file}.", e
        )
    return ret


def dump_cache_to_path(
    dsl_name,
    jit_function,
    file,
    path=default_generated_ir_path,
    bytecode_writer=None,
):
    """Dump the cache to a directory path.

    :param dsl_name: The name of the DSL.
    :type dsl_name: str
    :param jit_function: The JitCompiledFunction to dump.
    :type jit_function: JitCompiledFunction
    :param file: The name of the file to dump.
    :type file: str
    :param path: The path to the cache directory, defaults to default_generated_ir_path
    :type path: str, optional
    :param bytecode_writer: The bytecode writer to use, defaults to None
    :type bytecode_writer: callable, optional
    """
    log().info("JIT cache : dumping [%s] file=[%s]", dsl_name, file)
    if not path:
        path = default_generated_ir_path
    os.makedirs(path, exist_ok=True)
    try:
        save_ir(
            dsl_name,
            jit_function.ir_module,
            file,
            output_dir=path,
            as_bytecode=True,
            bytecode_writer=bytecode_writer,
        )
    except Exception as e:
        log().warning(
            f"{dsl_name} failed with dumping generated IR cache for {file}: {e}"
        )
