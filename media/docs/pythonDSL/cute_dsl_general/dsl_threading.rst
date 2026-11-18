.. |DSL| replace:: CuTe DSL

.. _dsl_threading:

Multithreading and Free-Threaded Python
=======================================

.. warning::

   Multithreaded use of |DSL| is **experimental and a work in progress**.
   Support is partial and currently focused on correctness rather
   than performance.

Free-threaded CPython (PEP 703, the ``python3.14t`` interpreter) runs Python
threads without a global interpreter lock. |DSL| can be imported on such an
interpreter without re-enabling the GIL, and its compile and launch entry points
can be called from several threads at once.


What Is Supported
-----------------

- Importing ``cutlass`` and ``cutlass.cute`` keeps the GIL disabled. You can
  check this with ``sys._is_gil_enabled()``, which should return ``False``
  after the import.
- Calling ``@cute.jit`` functions, ``cute.compile``, and compiled functions
  from multiple threads produces correct results. This covers compiling
  different functions concurrently, compiling the same function concurrently,
  and launching one compiled function from several threads on separate CUDA streams.
- Launching functions returned by ``cute.compile`` runs in parallel: launches
  on different threads do not block each other, and they do not block on, or
  wait for, a compilation running on another thread.


Rules to Follow
---------------

- Python code inside a ``@cute.jit`` or ``@cute.kernel`` body runs while the
  internal compilation lock is held. It must not wait on another thread that
  also compiles |DSL| code, or both threads deadlock.
- A read-only ``cute.Tensor`` can be passed to compiled functions from several
  threads at once, as can framework tensors such as ``torch.Tensor``. Do not
  modify a ``cute.Tensor`` (for example with ``mark_layout_dynamic``) while
  another thread may be launching a compiled function with it: finish all
  modifications before sharing it, or create tensors per thread.
- Compiled functions can be shared between threads. Use a separate CUDA stream
  per thread if you want the launched kernels to overlap.
- Do not unload a compiled function's module while any thread may still be
  calling it, and do not call it after it has been unloaded. As with
  ``cuLibraryUnload`` in the CUDA driver, |DSL| does not check for calls in
  flight: it is the caller's responsibility to make sure every call has
  returned before unloading. Kernels that were already enqueued keep running;
  the driver releases the code once they finish.


Known Limitations
-----------------

- Compilation is serialized by a coarse-grained lock, so compiling on several
  threads is not expected to be faster than compiling serially. Calling a
  ``@cute.jit`` function directly takes that lock even when the result is
  cached, because the call re-traces the body to look up the cache. To launch
  in parallel, call the object returned by ``cute.compile``.
- During a compile, |DSL| temporarily captures ``sys.stdout`` and
  ``sys.stderr`` to group compiler output. Output printed by unrelated threads
  during that window is captured too and appears when the compile finishes.
- Only the compile and launch entry points have been made safe. Helpers such as
  autotuning, profiling, and AOT export have not been reviewed for concurrent
  use.
