# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
This module provides logging helper functions
"""

import logging

logger: logging.Logger

LOG_DISABLED_LEVEL = logging.CRITICAL + 1


def log() -> logging.Logger:
    return logger


def _resolve_log_level(log_level: int) -> int:
    if log_level == 0:
        return LOG_DISABLED_LEVEL
    return log_level


def setup_log(
    name: str,
    log_to_console: bool = False,
    log_to_file: bool = False,
    log_file_path: str | None = None,
    log_level: int = 1,
) -> logging.Logger:
    """Set up and configure a logger with console and/or file handlers.

    :param name: Name of the logger to create
    :type name: str
    :param log_to_console: Whether to enable logging to console, defaults to False
    :type log_to_console: bool, optional
    :param log_to_file: Whether to enable logging to file, defaults to False
    :type log_to_file: bool, optional
    :param log_file_path: Path to the log file, required if log_to_file is True
    :type log_file_path: str, optional
    :param log_level: Logging verbosity: 0=disabled, 1=all messages
        (debug and above, the default), or a standard ``logging`` level
        (10=debug, 20=info, 30=warning, 40=error, 50=critical)
    :type log_level: int, optional
    :raises ValueError: If log_to_file is True but log_file_path is not provided
    :return: Configured logger instance
    :rtype: logging.Logger
    """
    log_level = _resolve_log_level(log_level)
    # Create a custom logger
    global logger
    logger = logging.getLogger(name)
    if log_to_console or log_to_file:
        logger.setLevel(log_level)
    else:
        # Makes sure logging is OFF
        logger.setLevel(LOG_DISABLED_LEVEL)

    # Clear existing handlers to prevent duplicate logs
    if logger.hasHandlers():
        logger.handlers.clear()

    # Define formatter
    formatter = logging.Formatter(
        f"%(asctime)s - %(name)s - %(levelname)s - [%(funcName)s] - %(message)s"
    )

    # Add console handler if enabled
    if log_to_console:
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

    # Add file handler if enabled
    if log_to_file:
        if not log_file_path:
            raise ValueError("log_file_path must be provided when enable_file is True")
        file_handler = logging.FileHandler(log_file_path)
        file_handler.setLevel(log_level)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger


class _ProfilingConsoleFilter(logging.Filter):
    """Drop the PyIR frontend's per-op INFO records (one line per assign or
    read) from a console that was opened only for JIT time profiling, so the
    measured times do not include writing tens of thousands of log lines.
    Warnings and every other module's records pass unchanged."""

    def filter(self, record: logging.LogRecord) -> bool:
        return record.levelno >= logging.WARNING or not record.module.startswith(
            "pyir_"
        )


def _init_logger_with_client_name(prefix: str) -> None:
    from ..env_manager import LogEnvironmentManager

    log_env = LogEnvironmentManager(prefix)

    # Profiling opens the console on its own only when the user did not.
    console_for_profiling = not log_env.log_to_console and log_env.jit_time_profiling
    if console_for_profiling:
        log_env.log_to_console = True
        log_env.log_level = 20  # info level

    dsl_logger = setup_log(
        prefix,
        log_env.log_to_console,
        log_env.log_to_file,
        f"{prefix}.log",
        log_env.log_level,
    )

    if console_for_profiling:
        # Only the console handler; a CUTE_DSL_LOG_TO_FILE file keeps every record.
        for handler in dsl_logger.handlers:
            if type(handler) is logging.StreamHandler:
                handler.addFilter(_ProfilingConsoleFilter())


logger = setup_log("generic")
