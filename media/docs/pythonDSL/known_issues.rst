.. _known_issues:

Known Issues
====================

This page lists behaviors of the CuTe DSL that are known to differ from what a
user might expect, together with the release in which the behavior changed and
how to work around it. Entries are removed once the underlying issue is fixed.
For unsupported features see :doc:`limitations`; for common questions see
:doc:`faqs`.


``tile_to_shape`` stride of a dynamic extent that folds to 1 differs between host and device
--------------------------------------------------------------------------------------------

**Affects:** ``cute.tile_to_shape`` (and any layout algebra that goes through
the same static re-inference) when a *dynamic* target extent folds to a single
tile inside a ``@cute.kernel``.

**Symptom.** Consider tiling an atom to a shape whose batch count is a dynamic
value that happens to be 1:

.. code-block:: python

    atom = cute.make_layout(((32, 4), (16, 4)), stride=((16, 4), (0, 1)))
    layout = cute.tile_to_shape(
        atom, (128, cutlass.Int32(256), cutlass.Int32(1)), order=(2, 1, 3)
    )

The resulting batch rest mode has shape ``1`` and a dynamic stride. Its value
depends on where the code runs:

.. list-table::
   :header-rows: 1
   :widths: 55 20

   * - Where the layout is built
     - Batch stride
   * - Host (``@cute.jit``), any compile route
     - ``2048``
   * - Device (``@cute.kernel``), CuTe extension compiler (default since 4.9)
     - ``0``
   * - Device (``@cute.kernel``), plain CuTe pipeline
     - ``2048``

Both results describe the same mapping, since a size-1 mode is only ever
indexed at coordinate 0. The difference becomes visible when the layout is
compared for equality against a reference layout, printed, or used to derive
other strides. In particular, a ``cute.testing.assert_(layout == expected)``
that passes on the host can fail on the device, or the other way round.

**History.**

* Up to and including 4.8, the CuTe extension compiler was an opt-in preview. 
  Kernels compiled with the default pipeline observed ``2048`` on both host 
  and device.
* Starting with 4.9, the CuTe extension compiler is the default route for
  ``@cute.kernel`` code. Kernels that compare or inspect the stride of a
  dynamic extent that folds to 1 now observe ``0`` on the device while the
  host still observes the running product.

**Workarounds.**

* Do not rely on the stride of a mode whose extent may fold to 1. Compare
  layouts on modes with extent greater than 1.
* Opt out of the CuTe extension compiler for the affected compilation. This
  restores the pre-4.9 device behavior. Per compile:

  .. code-block:: python

      compiled = cute.compile[cute.DisableCuteExtCompile](launch_fn, *args)

  Or globally for a process:

  .. code-block:: bash

      CUTE_DSL_USE_EXTENSION_COMPILER=0 python your_program.py

  Operations that require the CuTe extension compiler (``cute_ext`` APIs) are
  unavailable on the plain pipeline, so prefer the per-compile option and
  apply it only to the compilations that need it.
