# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Process-wide lock that serializes DSL compilation.

The DSL keeps per-compile state on a process-wide singleton and mutates the
user's function objects while tracing. None of that is safe when two Python
threads enter the DSL at once, which free-threaded CPython allows. Until that
state is made per-thread, every public compile entry point runs under this
one lock. That includes calling a ``@jit`` function directly: even on a cache
hit it re-traces the body to compute the cache key.

Launching a function returned by ``cute.compile`` does not take the lock.
Everything the launch path touches is per-thread, immutable after compilation,
or guarded on its own: the packed-argument buffer and CUDA status slot are
thread-local, the argument adapter registry is copy-on-write, a tensor builds
its descriptor once under a per-tensor lock, and the one-time executor setup
runs under the compiled function's own ``_executor_lock``. Launches therefore
run in parallel with each other and with compilation on other threads.

Design notes:

- One lock for compilation. A missed acquisition site on the compile path is a
  race, never a deadlock.
- The launch path must not take this lock, not even in ``to()``. The compile
  path holds it while performing a first launch, which takes
  ``_executor_lock``; a launch that took this lock after ``_executor_lock``
  would invert that order and could deadlock.
- Reentrant. Tracing a ``@jit`` body calls other ``@jit`` and ``@kernel``
  functions, ``cute.compile`` can be issued from inside a traced body, and the
  first call of a ``@jit`` function compiles and then launches in one go.
- Python code inside a traced body runs while the lock is held. Such code must
  not block on another thread that itself needs to compile.

The lock is private to the DSL and not part of the public API.
"""

from __future__ import annotations

import functools
import threading
from typing import Any, Callable, TypeVar

_F = TypeVar("_F", bound=Callable[..., Any])


# A single reentrant lock guards every DSL compile and launch entry point. The
# paths nest -- tracing a ``@jit`` body calls other ``@jit``/``@kernel``
# functions, and a first call compiles and then launches under the same lock --
# so the lock must be reentrant. threading.RLock is used directly rather than a
# hand-rolled wrapper so that acquire and release pair atomically with the
# ``with`` statement: a Python-level __enter__/__exit__ leaves a window where an
# async exception (e.g. KeyboardInterrupt) lands after acquire() but before the
# ``with`` arms its finally, holding the lock forever. Tests that need to know
# whether the current thread holds the lock use ``dsl_lock._is_owned()``.
dsl_lock = threading.RLock()


def with_dsl_lock(func: _F) -> _F:
    """Run ``func`` while holding :data:`dsl_lock`."""

    @functools.wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:  # noqa: ANN401
        with dsl_lock:
            return func(*args, **kwargs)

    return wrapper  # type: ignore[return-value]
