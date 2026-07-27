.. _debugging:

Debugging
=========

This page provides an overview of debugging techniques and tools for CuTe DSL programs.


Getting Familiar with the Limitations
-------------------------------------

Before diving into comprehensive debugging capabilities, it's important to understand the limitations of CuTe DSL.
Understanding these limitations will help you avoid potential pitfalls from the start.

Please refer to :doc:`../limitations` for more details.


Source Code Correlation
-----------------------

CuTe DSL provides Python code to PTX/SASS correlation to enable the profiling/debugging of generated kernels with debug symbols by generating line info when compiling the kernel.

You can enable that globally via the environment variable CUTE_DSL_LINEINFO=1. Alternative, you can use compilation options to enable that per kernel. Please refer to :doc:`./dsl_jit_compilation_options` for more details.


Debug Mode
----------

To turn on a broad set of debugging aids at once, set the ``CUTE_DSL_DEBUG``
environment variable. It is a convenience switch for diagnosing problems and for
reporting issues to the CUTLASS team:

.. code:: bash

    # Enable debug mode (default: False)
    export CUTE_DSL_DEBUG=1

When debug mode is enabled, CuTe DSL raises the defaults of several individual
debugging settings so you get more diagnostics from a single switch:

- Line info is generated for Python-to-PTX/SASS correlation (same effect as
  ``CUTE_DSL_LINEINFO=1``).
- Full, unfiltered Python stack traces are shown on failure (internal DSL
  frames are no longer hidden).
- Optimization warnings that are normally suppressed are surfaced.
- Trace-time operation verification runs as operations are built, so malformed
  operations are reported earlier instead of late in compilation.
- Full per-launch argument validation is performed, so a mismatched or
  unsupported argument is reported with a clear error instead of failing later
  inside the compiled kernel.

Each of these behaviors is also controlled by its own environment variable, so
debug mode only changes their *defaults*, and setting a variable explicitly
takes precedence -- except trace-time operation verification, which stays on
while debug mode is enabled. For example, to enable debug mode but keep line
info off:

.. code:: bash

    export CUTE_DSL_DEBUG=1
    export CUTE_DSL_LINEINFO=0

.. note::

    Debug mode adds extra checks and diagnostics that increase compile time and
    may affect the generated code (for example, by embedding line info). Enable
    it while debugging, not for production runs.

.. note::

    The settings debug mode raises -- line info in particular -- change the
    emitted IR/PTX, and every one of these settings is folded into the JIT
    kernel cache key. A kernel compiled with debug mode on is therefore cached
    separately from the same kernel compiled with it off: toggling
    ``CUTE_DSL_DEBUG`` forces a recompile instead of reusing a cached kernel,
    and the kernel you inspect or profile under debug mode is not identical to
    the one produced for a normal (debug-off) run. Validate performance and
    generated-code conclusions with debug mode disabled. Because these settings
    are part of the cache key, a debug-built kernel is never silently reused for
    a production run. See :doc:`JIT caching <./dsl_jit_caching>` for how the
    cache key is formed.


DSL Debugging
-------------

CuTe DSL provides built-in logging mechanisms to help you understand the code execution flow and
some of the internal state.

Enabling Logging
~~~~~~~~~~~~~~~~

CuTe DSL provides environment variables to control logging level:

.. code:: bash

    # Enable console logging (default: False)
    export CUTE_DSL_LOG_TO_CONSOLE=1

    # Log to file instead of console (default: False).
    # Set to 1/True to enable; the log file path is chosen automatically by the DSL.
    export CUTE_DSL_LOG_TO_FILE=1

    # Control log verbosity (0=disabled, 1=all messages (debug and above), 10=debug, 20=info, 30=warning, 40=error, 50=critical; default: 1)
    export CUTE_DSL_LOG_LEVEL=20


Log Categories and Levels
~~~~~~~~~~~~~~~~~~~~~~~~~

Similar to standard Python logging, different log levels provide varying degrees of detail:

+--------+-------------+
| Level  | Description |
+========+=============+
| 0      | Disabled    |
+--------+-------------+
| 10     | Debug       |
+--------+-------------+
| 20     | Info        |
+--------+-------------+
| 30     | Warning     |
+--------+-------------+
| 40     | Error       |
+--------+-------------+
| 50     | Critical    |
+--------+-------------+


Save generated artifacts to files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CuTe DSL can save generated artifacts (IR, PTX, CUBIN, …) to files for offline inspection.
Use ``CUTE_DSL_KEEP`` with a comma-separated list of artifact tokens:

.. code:: bash

    # Save clean IR (after canonicalize+cse, human-readable) to a .mlir file
    export CUTE_DSL_KEEP=ir

    # Save raw IR (before any passes) to a .mlir file
    export CUTE_DSL_KEEP=ir-debug

    # Save PTX assembly to a .ptx file
    export CUTE_DSL_KEEP=ptx

    # Save CUBIN binary to a .cubin file
    export CUTE_DSL_KEEP=cubin

    # Save SASS disassembly to a file (requires nvdisasm in PATH)
    export CUTE_DSL_KEEP=sass

    # Save LLVM IR to a file
    export CUTE_DSL_KEEP=llvm

    # Save multiple artifacts at once
    export CUTE_DSL_KEEP=ir,ptx,cubin

    # Save all supported artifacts
    export CUTE_DSL_KEEP=all

Files are written to the current working directory by default. Use ``CUTE_DSL_DUMP_DIR``
to redirect them (see `Change the dump directory`_ below).

.. note::

    The ``sass`` token requires ``nvdisasm`` (or ``nvdisasm_internal``) to be available
    in your ``PATH``. It is usually installed with the CUDA toolkit.

Print the generated IR to the console
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To print the IR directly to the console (without writing a file):

.. code:: bash

    # Print generated IR to stdout (default: False)
    export CUTE_DSL_PRINT_IR=1


Access the dumped contents programmatically
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For compiled kernels, the generated PTX/CUBIN/IR can be accessed programmatically as well through following attributes:

- ``__ptx__``: The generated PTX code of the compiled kernel.
- ``__cubin__``: The generated CUBIN data of the compiled kernel.
- ``__mlir__``: The generated IR code of the compiled kernel.

.. code:: python
    
    compiled_foo = cute.compile(foo, ...)
    print(f"PTX: {compiled_foo.__ptx__}")
    with open("foo.cubin", "wb") as f:
        f.write(compiled_foo.__cubin__)


Change the dump directory
~~~~~~~~~~~~~~~~~~~~~~~~~

By default, all dumped files are saved in the current working directory. To specify a different directory for the dumped files, please set the environment variable CUTE_DSL_DUMP_DIR accordingly.


Kernel Functional Debugging
----------------------------

Using Python's ``print`` and CuTe's ``cute.printf``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CuTe DSL programs can use both Python's native ``print()`` as well as our own ``cute.printf()``  to
print debug information during kernel generation and execution. They differ in a few key ways:

- Python's ``print()`` executes during compile-time only (no effect on the generated kernel) and is
  typically used for printing static values (e.g. a fully static layouts).
- ``cute.printf()`` executes at runtime on the GPU itself and changes the PTX being generated. This
  can be used for printing values of tensors at runtime for diagnostics, but comes at a performance
  overhead similar to that of `printf()` in CUDA C.

For detailed examples of using these functions for debugging, please refer to the associated
notebook referenced in :doc:`notebooks`.

Handling Unresponsive/Hung Kernels
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When a kernel becomes unresponsive and ``SIGINT`` (``CTRL+C``) fails to terminate it,
you can follow these steps to forcefully terminate the process:

1. Use ``CTRL+Z`` to suspend the unresponsive kernel
2. Execute the following command to terminate the suspended process:

.. code:: bash

    # Terminate the most recently suspended process
    kill -9 $(jobs -p | tail -1)


CuTe DSL can also be debugged using standard NVIDIA CUDA tools.

Using Compute-Sanitizer
~~~~~~~~~~~~~~~~~~~~~~~

For detecting memory errors and race conditions:

.. code:: bash

    compute-sanitizer --some_options python your_dsl_code.py

Please refer to the `compute-sanitizer documentation <https://developer.nvidia.com/compute-sanitizer>`_ for more details.

Set function name prefix
~~~~~~~~~~~~~~~~~~~~~~~~~

By default, the function name (host function or kernel function) is automatically generated based on the function name and its parameters.
Sometimes you may want to attach some runtime information to the function name to make performance profiling and debugging easier,
e.g., the kernel configs or the rank ids. You can assign a name prefix to the name by calling the ``set_name_prefix`` 
method on the  host function or kernel function.

.. code:: python

    @cute.kernel
    def kernel(arg1, arg2, ...):
        ...
    @cute.jit
    def launch_kernel():
        kernel.set_name_prefix("your_custom_name_prefix")
        kernel(arg1, arg2, ...).launch(grid=[1, 1, 1], block=[1, 1, 1], ...)

For above example, the generated kernel name will be "your_custom_name_prefix_xxx".

Conclusion
----------

This page covered several key methods for debugging CuTe DSL programs. Effective debugging typically requires a combination of these approaches.
If you encounter issues with DSL, you can enable logging and share the logs with the CUTLASS team as a GitHub issue to report a bug.
