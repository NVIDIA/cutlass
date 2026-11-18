.. _deprecation:

Deprecation Policy
==================

Purpose
-------

The goal of this policy is to evolve the DSL and its APIs while keeping user
programs stable. Features or APIs are deprecated only when they are redundant,
unsafe, or block better designs.

Deprecation Process
-------------------

The warning grows louder as removal approaches, so you get notice early without
noise in the meantime:

#. ``silent`` - annotated, but nothing is emitted at runtime.
#. ``warn once`` - one warning per process.
#. ``warn once per call site`` - one warning for each place your code uses it.
#. ``warn every call`` - a warning on every use, in the release before removal.
#. ``removed`` - the feature is gone.

**Step 1 - Soft Deprecation**

When a feature is considered for removal, it is first annotated with the
``@deprecated`` decorator or ``DeprecationWarning`` and documented with a
suggested alternative. At this stage, the feature continues to work normally.

Users are encouraged to provide feedback and describe their use cases.
If there is strong justification, we may keep or redesign the feature.

**Step 2 - Removal**

If no valid use cases remain, the deprecated feature is removed, no earlier than
**four minor releases** after the deprecation was introduced. See
`Removal Window`_ for the rule and its qualifications.

Removal Window
--------------

An API is removed no earlier than **four minor releases** after the release
that introduced its deprecation. A deprecation introduced in 4.6 is therefore
removable in 4.10.

.. note::

   The release version follows the format ``<major>.<minor>.<patch>``. Only
   minor releases are counted: patch releases never remove an API.

Four releases is chosen so that even conservative upgraders see the warning in
their own code before they meet a breaking change.

These rules follow from that promise:

* An entry still in the ``silent`` stage has not started its window, since no
  warning has reached you yet. Those are clocked from the release that arms
  their warning rather than the release that introduced them.

Seeing the Warnings
-------------------

Deprecations are reported as ``cutlass.DSLDeprecationWarning``, a subclass of
``DeprecationWarning``, and are shown by default. Python itself shows
``DeprecationWarning`` only when the call site is in ``__main__``; CuTe DSL
shows its own deprecations wherever your code uses them, including kernels that
live in a package. Each warning names the line in your code that uses the
deprecated API, for example::

    my_kernels/gemm.py:42: DSLDeprecationWarning: cute.arch.exp is deprecated, use cute.math.exp with `fastmath=True` instead

How often a warning repeats follows its stage in `Deprecation Process`_.

Silencing the Warnings
----------------------

To silence only CuTe DSL deprecations, filter on their category after
``import cutlass``::

    import warnings

    import cutlass

    warnings.filterwarnings("ignore", category=cutlass.DSLDeprecationWarning)

Deprecations from other libraries are still shown. To fail at the first CuTe DSL
deprecation instead, use ``"error"`` in place of ``"ignore"``; the traceback
goes through the line that uses the deprecated API.

To turn off every warning CuTe DSL emits, deprecations included, set
``CUTE_DSL_WARNINGS_IGNORE``::

    CUTE_DSL_WARNINGS_IGNORE=1 python your_kernel.py

Warnings from other libraries are still shown. Every CuTe DSL warning derives
from ``cutlass.DSLWarning``, so the setting has the same effect as
``warnings.filterwarnings("ignore", category=cutlass.DSLWarning)``, except that
it takes effect during ``import cutlass`` and so also covers warnings the import
itself emits. Filters you install after the import take precedence over it.

To silence every deprecation, including those from other libraries, set
``PYTHONWARNINGS=ignore::DeprecationWarning`` or run
``python -W ignore::DeprecationWarning``. A ``DeprecationWarning`` filter
installed in code before ``import cutlass`` is overridden for CuTe DSL
deprecations, so install it after the import.

If you pass any ``-W`` option or set ``PYTHONWARNINGS``, CuTe DSL no longer
turns its deprecations on for you, and Python's default applies to whatever your
options do not cover, so deprecations used from a package are hidden again. Add
``-W default::DeprecationWarning`` to keep seeing them.

Communication
-------------

All deprecations are announced through this page and through the in-code
warning message.


Removed Features
----------------

*(None yet. Entries move here as they are removed.)*
