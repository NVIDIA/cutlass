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

CuTe DSL can emit line information so NVIDIA developer tools can correlate
generated PTX/SASS back to the Python source that produced it. This is useful
when profiling generated kernels or debugging them with CUDA tools.

You can enable line information globally with ``CUTE_DSL_LINEINFO=1``.
Alternatively, use compilation options to enable it per kernel. Refer to
:doc:`../cute_dsl_general/dsl_jit_compilation_options` for more details.


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
    a production run. See :doc:`JIT caching <../cute_dsl_general/dsl_jit_caching>`
    for how the cache key is formed.

Compiler Diagnostics
--------------------

CuTe DSL also provides compiler diagnostic passes for catching invalid
primitive protocols and resource issues at compile time. These checks are useful
when a kernel fails before launch, when synchronization around primitives is
unclear, or when ``ptxas`` reports resource pressure that is hard to map back to
the generated kernel.

Enable diagnostics with ``CUTE_DSL_COMPILER_OPT`` or the ``options=`` argument
to ``cute.compile``. Diagnostic controls have two axes: the severity level to
show and the diagnostic category to collect. Bare ``warnings`` or ``remarks``
selects all available categories; selector braces restrict the request to one
category.

.. list-table:: Diagnostic levels
   :header-rows: 1

   * - Level
     - Enable with
     - Useful for
     - Fatal?
   * - Info (remark)
     - ``remarks`` or ``remarks{<category>}``
     - Performance-only findings, such as synchronization opportunities or
       register-spill and local-memory resource reports.
     - No
   * - Warning
     - ``warnings`` or ``warnings{<category>}``
     - Legal but questionable patterns that can hang, fault, or behave
       differently than intended.
     - No
   * - Error
     - No separate ``errors{...}`` option. Enable the relevant category with
       ``warnings{<category>}`` or ``remarks{<category>}``.
     - Proven defects reported by an enabled diagnostic category.
     - Yes

.. list-table:: Diagnostic categories
   :header-rows: 1

   * - Category
     - Enable with
     - Source
     - Useful levels
   * - ``nvvm``
     - ``warnings{nvvm}``, ``remarks{nvvm}``
     - NVVM-level primitive protocol diagnostics for operations such as
       ``mbarrier``, bulk copy, TMA multicast, and ``tcgen05``.
     - Error, warning, info (remark)
   * - ``ptxas`` (selector: ``ptx``)
     - ``remarks{ptx}``
     - ``ptxas`` resource diagnostics surfaced through the remark stream,
       including register spills and local-memory usage.
     - Info (remark)

For example, enable NVVM primitive diagnostics with:

.. code:: bash

    export CUTE_DSL_COMPILER_OPT='warnings{nvvm},remarks{nvvm}'

The ``warnings{nvvm}`` and ``remarks{nvvm}`` selectors enable NVVM-level
primitive diagnostics for protocol rules around primitives such as ``mbarrier``,
bulk copy, TMA multicast, and ``tcgen05`` operations. For example, these
diagnostics can report missing transaction completion for
``mbarrier.arrive.expect_tx``, ``tcgen05.commit`` calls that are not guarded by
``elect.sync``, missing ``tcgen05.fence::after_thread_sync`` before TMEM loads,
and CTA-pair restrictions for CTA_2 TMA multicast.

The diagnostic examples are compile-only negative cases under
``examples/python/CuTeDSL/experimental/compiler_diagnostic`` in the public
CUTLASS tree. From a built checkout, run all primitive diagnostic examples with:

.. code:: bash

    CUTE_DSL_COMPILER_OPT='warnings{nvvm},remarks{nvvm}' \
    python examples/python/CuTeDSL/experimental/compiler_diagnostic/prims_negative_cases.py

Run a single case by name when you want a small reproducer:

.. code:: bash

    CUTE_DSL_COMPILER_OPT='warnings{nvvm},remarks{nvvm}' \
    python examples/python/CuTeDSL/experimental/compiler_diagnostic/prims_negative_cases.py \
        --case expect_tx_without_complete_tx

The ``expect_tx_without_complete_tx`` case intentionally initializes a
transaction-counting barrier and calls ``mbarrier_arrive_expect_tx`` without a
matching completion source:

.. code:: python

    import cutlass
    import cutlass.cute as cute
    from cutlass.cute.runtime import make_fake_stream
    from cutlass.experimental import primitives as prims


    @cute.kernel
    def expect_tx_without_complete_tx_kernel() -> None:
        mbar = cutlass.Array(
            cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
        )

        if prims.elect_sync():
            prims.mbarrier_init(mbar, 1)
        prims.fence_mbarrier_init()
        prims.barrier_cta_sync(0)

        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(mbar, 16_384)
        prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000)


    @cute.jit
    def host_expect_tx_without_complete_tx(stream) -> None:
        expect_tx_without_complete_tx_kernel().launch(
            grid=(1, 1, 1), block=(32, 1, 1), stream=stream
        )


    cute.compile(
        host_expect_tx_without_complete_tx,
        make_fake_stream(),
        options="warnings{nvvm},remarks{nvvm}",
    )

The emitted diagnostic points back to the Python source and names the protocol
rule that failed:

.. code:: text

    ===== expect_tx_without_complete_tx =====
    error[E####]: mbarrier.arrive.expect_tx has no completion source for 16384 registered transaction bytes

      --> examples/python/CuTeDSL/experimental/compiler_diagnostic/prims_negative_cases.py:94:8
          in function `_expect_tx_without_complete_tx_kernel(...)`:
       |
      92 |
      93 |     if prims.elect_sync():
    > 94 |         prims.mbarrier_arrive_expect_tx(mbar, 16_384)
         |        ^
      95 |     prims.mbarrier_try_wait_parity(mbar, 0, time_limit=_WAIT_TICKS)
      96 |
      error: arrive.expect_tx increments the barrier transaction count, but no explicit
             mbarrier.complete_tx or TMA complete_tx source targets this barrier. The transaction count
             can never be retired.
      suggestion: add a matching nvvm.mbarrier_complete_tx(...) on this barrier, or issue a TMA
                  operation whose completion targets the same barrier
      note: PTX ISA mbarrier.arrive.expect_tx
            docs: https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#parallel-synchronization-and-communication-instructions-mbarrier-expect-tx-operation
    PASS expect_tx_without_complete_tx

For ``ptxas`` resource diagnostics, pass ``remarks{ptx}`` through the JIT
compile options. This selector surfaces resource remarks such as register spills
and local-memory usage:

.. code:: python

    cute.compile(my_host_fn, *args, options="remarks{ptx}")

If a kernel only spills under a tighter register budget, combine the selector
with ``--ptxas-options``. The DSL automatically enables verbose ``ptxas`` output
for ``remarks{ptx}``, so spill and local-memory remarks are available to the
diagnostic formatter:

.. code:: python

    cute.compile(
        my_host_fn,
        *args,
        options=(
            "remarks{ptx} "
            "--ptxas-options '--maxrregcount=128 --override-directive-values'"
        ),
    )

Keep ``--remark-output`` unset when you want terminal diagnostics with source
frames. The YAML remark-output path is intended for raw LLVM remark export and
does not use the Python source-frame renderer.

The companion ``ptxas_spill_cases.py`` helper in the same directory contains
compile-only examples for two common symptoms:

* ``dynamic_index_local_memory``: dynamic indexing of a register array forces
  local-memory accesses.
* ``global_reverse_register_spill``: high register pressure creates ptxas
  register spills when constrained with ``--maxrregcount``.

Run it from a built checkout to confirm the ptxas remark pipeline and inspect
the rendered source frames:

.. code:: bash

    python examples/python/CuTeDSL/experimental/compiler_diagnostic/ptxas_spill_cases.py

Use these helpers when a kernel's generated SASS shows unexpected local-memory
traffic, when ``ptxas`` reports spills, or when you need a minimal reproducer
for register-pressure regressions. Register-spill source frames are best-effort:
``ptxas`` reports spill totals at kernel granularity, so the frame identifies
the reported kernel / likely pressure region rather than an exact spill
instruction.

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

Similar to standard Python logging, different log levels provide varying
degrees of detail:

.. list-table::
   :header-rows: 1

   * - Level
     - Description
   * - 0
     - Disabled
   * - 1
     - All messages
   * - 10
     - Debug
   * - 20
     - Info
   * - 30
     - Warning
   * - 40
     - Error
   * - 50
     - Critical


Save generated artifacts to files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CuTe DSL can save generated artifacts (IR, PTX, CUBIN, …) to files for offline inspection.
Use ``CUTE_DSL_KEEP`` with a comma-separated list of artifact tokens. Prefer
this consolidated option over deprecated per-artifact variables such as
``CUTE_DSL_KEEP_PTX=1``.

.. code:: bash

    # Save clean IR (after canonicalize+cse, human-readable) to a .mlir file
    export CUTE_DSL_KEEP=ir

    # Save raw IR (before any passes) to a .mlir file
    export CUTE_DSL_KEEP=ir-debug

    # Save PTX assembly to a .ptx file
    export CUTE_DSL_KEEP=ptx

    # Save CUBIN binary to a .cubin file
    export CUTE_DSL_KEEP=cubin

    # Save SASS disassembly to a .sass file
    export CUTE_DSL_KEEP=sass

    # Save multiple artifacts at once
    export CUTE_DSL_KEEP=ir,ptx,cubin,sass

    # Save all supported artifacts
    export CUTE_DSL_KEEP=all

Files are written to the current working directory by default. Use
``CUTE_DSL_DUMP_DIR`` to redirect them (see `Change the dump directory`_
below).

.. note::

    The ``sass`` token disassembles the CUBIN with ``nvdisasm``. Starting
    with CUTLASS 4.7, ``nvdisasm`` is no longer installed by default. To
    dump SASS, do one of the following:

    - install the ``sass`` extra (recommended — its ``nvdisasm`` version
      is guaranteed to match the toolchain the DSL ships):
      ``pip install nvidia-cutlass-dsl[sass]``
    - install a local CUDA Toolkit and expose it via ``CUDA_HOME`` /
      ``CUDA_PATH``

    A locally-provided ``nvdisasm`` must come from a CUDA Toolkit at least
    as new as the toolchain that produced the CUBIN; an older one (e.g.
    from CUDA 12.x) may fail to disassemble it.

    SASS dumping can also be controlled per compilation with ``KeepSASS``
    and ``NvdisasmOptions``; see :ref:`JIT_Compilation_Options`.

Print the generated IR to the console
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To print the IR directly to the console (without writing a file):

.. code:: bash

    # Print generated IR to stdout (default: False)
    export CUTE_DSL_PRINT_IR=1


Access the dumped contents programmatically
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For compiled kernels, the generated PTX/CUBIN/IR can also be accessed
programmatically through the following attributes:

- ``__ptx__``: The generated PTX code of the compiled kernel.
- ``__cubin__``: The generated CUBIN data of the compiled kernel.
- ``__sass__``: The generated SASS disassembly of the compiled kernel, when
  SASS was requested.
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

CuTe DSL programs can use both Python's native ``print()`` and ``cute.printf()`` to
print debug information during kernel generation and execution. They differ in a few key ways:

- Python's ``print()`` executes during compile-time only (no effect on the generated kernel) and is
  typically used for printing static values, such as fully static layouts.
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

For detecting memory errors:

.. code:: bash

    compute-sanitizer --tool memcheck python your_dsl_code.py

For detecting race conditions:

.. code:: bash

    compute-sanitizer --tool racecheck python your_dsl_code.py

Please refer to the `compute-sanitizer documentation <https://developer.nvidia.com/compute-sanitizer>`_ for more details.

Set function name prefix
~~~~~~~~~~~~~~~~~~~~~~~~~

By default, the generated IR name of a host or kernel function is based on the
Python function name and its parameters. Call ``set_name_prefix`` on a JIT or
kernel function before invoking it to add runtime context or customize that IR
name.

``set_name_prefix`` also accepts two optional keyword-only parameters:

* ``remove_cutlass_symbol=False`` removes the ``cutlass`` component that CuTe
  DSL automatically inserts. It does not modify the user-provided prefix, the
  Python function name, or text derived from mangled arguments.
* ``keep_mangled_name=True`` retains the framework-generated function and
  argument components. When set to ``False``, those components are omitted,
  while the ``cutlass`` marker remains unless ``remove_cutlass_symbol=True``.
  The per-kernel numeric uniqueness suffix is always retained.

Calling ``set_name_prefix("")`` with the optional arguments left at their
defaults restores all default naming behavior. An empty prefix can also be
combined with non-default component options; for example,
``set_name_prefix("", remove_cutlass_symbol=True)`` removes the CuTe DSL marker
without adding a user prefix. A non-empty prefix is required when
``remove_cutlass_symbol=True`` and ``keep_mangled_name=False`` so that at least
one textual name component remains.

.. code:: python

    @cute.kernel
    def kernel(arg1, arg2, ...):
        ...

    @cute.jit
    def launch_kernel():
        kernel.set_name_prefix(
            "my_op",
            remove_cutlass_symbol=True,
            keep_mangled_name=False,
        )
        kernel(arg1, arg2, ...).launch(
            grid=[1, 1, 1], block=[1, 1, 1], ...
        )

For a first kernel trace whose default name resembles
``kernel_cutlass_kernel_<arguments>_0``, representative results are:

* ``set_name_prefix("my_op")``:
  ``my_op_kernel_cutlass_kernel_<arguments>_0``
* ``set_name_prefix("my_op", remove_cutlass_symbol=True)``:
  ``my_op_kernel_kernel_<arguments>_0``
* ``set_name_prefix("my_op", keep_mangled_name=False)``:
  ``my_op_cutlass_0``
* Enabling both options, as above: ``my_op_0``

The numeric suffix can differ when the same kernel is traced more than once.
Host JIT function names do not have the per-kernel numeric suffix.

To produce a generated IR name without ``cutlass``, use a prefix that does not
contain it. If ``keep_mangled_name=True``, also ensure that the Python function
name and mangled argument text do not contain it; setting
``keep_mangled_name=False`` omits those components.

The kernel suffix prevents collisions between traces in one generated module.
It does not make names unique across separately compiled modules, and host JIT
names have no such suffix. When ``keep_mangled_name=False``, use a prefix that
is unique in every final link or load scope where modules can be combined.

``set_name_prefix`` does not truncate the user prefix, so do not rely on
truncation to remove text from it. Keep the resulting name within the limits of
the tools that consume the generated artifact.

This API controls traced MLIR function names, not ABI wrappers added by later
export stages such as ``cutlass_call_<function-name>``.

Conclusion
----------

Effective CuTe DSL debugging typically combines source correlation, artifact
dumps, runtime prints, and CUDA tooling. When reporting an issue, include the
minimal reproducer, relevant generated artifacts, and logs collected with the
debugging options above, and share it with the CUTLASS team as a GitHub issue.
