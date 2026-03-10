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

**Step 1 — Soft Deprecation**

When a feature is considered for removal, it is first annotated with the
``@deprecated`` decorator or ``DeprecationWarning`` and documented with a
suggested alternative. At this stage, the feature continues to work normally.

Users are encouraged to provide feedback and describe their use cases.
If there is strong justification, we may keep or redesign the feature.

**Step 2 — Removal (the subsequent release)**

If no valid use cases remain, the deprecated feature will be removed in the
following **minor** release.

.. note::

   The release version follows the format ``<major>.<minor>.<patch>``.

Communication
-------------

All deprecations are announced through:

* This page
* In-code warning messages

Soft Deprecations
-----------------

**Version 4.2.1**

* ``cute.arch.warpgroup_reg_alloc`` and ``cute.arch.warpgroup_reg_dealloc``
  → Scheduled for deprecation. Use ``cute.arch.setmaxregister_increase`` and ``cute.arch.setmaxregister_decrease`` instead.

* ``alignment`` argument in ``CooperativeGroup`` constructor
  → Scheduled for deprecation. It was unused; no replacement is suggested.

Deprecated Features
-------------------

*(None currently.)*
