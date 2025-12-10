.. _dsl_jit_compilation_options:
.. |DSL| replace:: CuTe DSL

.. _JIT_Compilation_Options:

JIT Compilation Options
=======================

JIT Compilation Options Overview
--------------------------------

When compiling a JIT function using |DSL|, you may want to control various aspects of the compilation process, such as optimization level, or debugging flags. |DSL| provides a flexible interface for specifying these compilation options when invoking ``cute.compile``.

Compilation options allow you to customize how your JIT-compiled functions are built and executed. This can be useful for:

* Enabling or disabling specific compiler optimizations
* Generating debug information for troubleshooting

These options can be passed as keyword arguments to ``cute.compile`` or set globally for all JIT compilations. The available options and their effects are described in the following sections, along with usage examples to help you get started.

The |DSL| provides multiple ways to specify compilation options - either by specifying additional arguments to ``cute.compile`` or by using a more Pythonic approach with separate Python types for ``cute.compile``.


``cute.compile`` Compilation Options as strings
-----------------------------------------------

You can provide additional compilation options as a string when calling ``cute.compile``. The |DSL| uses ``argparse`` to parse these options and will raise an error if any invalid options are specified.

.. list-table::
   :header-rows: 1
   :widths: 20 20 15 25

   * - **Option**
     - **Description**
     - **Default**
     - **Type**
   * - ``opt-level``
     - Optimization level of compilation. The higher the level, the more optimizations are applied. The valid value range is [0, 3].
     - 3 (highest level of optimization)
     - int
   * - ``enable-assertions``
     - Enable host and device code assertions.
     - False
     - bool
   * - ``keep-cubin``
     - Keep the generated CUBIN file.
     - False
     - bool
   * - ``keep-ptx``
     - Keep the generated PTX file.
     - False
     - bool
   * - ``ptxas-options``
     - The options to pass to the PTX Compiler library.
     - ""
     - str
   * - ``generate-line-info``
     - Generate line information for debugging.
     - False
     - bool
   * - ``gpu-arch``
     - The GPU architecture to compile for.
     - ""
     - str
   * - ``enable-tvm-ffi``
     - Enable Apache TVM FFI.
     - False
     - bool

You can use the following code to specify compilation options:

.. code-block:: python

   jit_executor_with_opt_level_2 = cute.compile(add, 1, 2, options="--opt-level 2")
   jit_executor_with_opt_level_1 = cute.compile(add, 1, 2, options="--opt-level 1")
   jit_executor_with_enable_device_assertions = cute.compile(add, 1, 2, options="--enable-assertions")
   jit_executor_with_keep_cubin = cute.compile(add, 1, 2, options="--keep-cubin")
   jit_executor_with_keep_ptx = cute.compile(add, 1, 2, options="--keep-ptx")
   jit_executor_with_ptxas_options = cute.compile(add, 1, 2, options="--ptxas-options '--opt-level=2'")


``cute.compile`` Compilation Options as separate Python types
-------------------------------------------------------------

Alternatively, you can also use a more Pythonic way to specify compilation options with separate Python types.
Compilation options can be programmatically composed using tuple and passed to ``cute.compile`` separately.

.. code-block:: python

  from cutlass.cute import OptLevel, EnableAssertions, GenerateLineInfo, KeepCUBIN, KeepPTX

  my_debugging_options = (OptLevel(1), EnableAssertions, GenerateLineInfo, KeepCUBIN, KeepPTX)
  compiled_kernel_1 = cute.compile[my_debugging_options](my_kernel_1, ...)
  compiled_kernel_2 = cute.compile[my_debugging_options](my_kernel_2, ...)

This approach causes invalid options to raise errors immediately, making it much easier to detect typos when specifying multiple options.
Notebly, boolean options are automatically converted to True instances of the option type for convenience.

.. code-block:: python

   jit_executor_with_opt_level_2 = cute.compile[OptLevel(2)](add, 1, 2)
   jit_executor_with_opt_level_1 = cute.compile[OptLevel(1)](add, 1, 2)
   jit_executor_with_enable_device_assertions = cute.compile[EnableAssertions](add, 1, 2)
   jit_executor_with_keep_cubin = cute.compile[KeepCUBIN](add, 1, 2)
   jit_executor_with_keep_ptx = cute.compile[KeepPTX](add, 1, 2)
   jit_executor_with_ptxas_options = cute.compile[PtxasOptions("--opt-level=2")](add, 1, 2)