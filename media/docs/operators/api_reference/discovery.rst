.. _operators_api_reference_discovery:

Kernel discovery
================

:func:`~cutlass.operators.get_operators` is the entry point for finding
Operators that support a given operation, operands, and target. It returns
:class:`Operators <cutlass.operators.Operator>` drawn from the
:class:`~cutlass.operators.Manifest` of registered kernels.

Operators can be additionally discovered or filtered by target compute
capability, which is described by :class:`~cutlass.operators.TargetSm`.

.. autofunction:: cutlass.operators.get_operators

.. automodule:: cutlass.operators.manifest
   :members:
   :show-inheritance:

.. automodule:: cutlass.operators.arch
   :members:
   :show-inheritance:
