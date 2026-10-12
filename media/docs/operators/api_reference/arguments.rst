.. _operators_api_reference_arguments:

Arguments and Operands
======================

An operation is expressed as a :class:`~cutlass.operators.RuntimeArguments`
object that describes both the operation kind (e.g. GEMM) and the operands it
runs on. Each operation has its own ``RuntimeArguments`` subclass. Operands are
described by :class:`~cutlass.operators.Operand` subclasses such as
:class:`~cutlass.operators.DenseTensor` and
:class:`~cutlass.operators.ScaledOperand`. Tensor- and numeric-typed fields
within Arguments and Operands accept any object matching the
:class:`~cutlass.operators.TensorLike` / :class:`~cutlass.operators.NumericLike`
protocols (e.g. ``torch.Tensor``, ``cute.Tensor``, ``cutlass.Numeric``,
``torch.dtype``).

RuntimeArguments
----------------

.. automodule:: cutlass.operators.arguments.base
   :members:
   :exclude-members: Operand
   :show-inheritance:

.. automodule:: cutlass.operators.arguments.gemm
   :members:
   :show-inheritance:

.. automodule:: cutlass.operators.arguments.grouped_gemm
   :members:
   :show-inheritance:

.. automodule:: cutlass.operators.arguments.epilogue
   :members:
   :show-inheritance:


Operands
--------

.. autoclass:: cutlass.operators.arguments.base.Operand
   :members:
   :show-inheritance:

.. automodule:: cutlass.operators.arguments.operand
   :members:
   :show-inheritance:


Type markers
------------

.. automodule:: cutlass.operators.typing
   :members:
   :show-inheritance:
