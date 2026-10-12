.. _operators_api_reference_operator:

Operator interface
==================

The :class:`~cutlass.operators.Operator` class is the central interface of Operator API.
Each ``Operator`` wraps a single "kernel" written in DSL and exposes a uniform interface for
executing it, generating its instances, and metadata that describes the kernel's capabilities.

.. automodule:: cutlass.operators.base
   :members:
   :show-inheritance:


Compiled artifacts
------------------

:meth:`Operator.compile <cutlass.operators.Operator.compile>` returns a
:class:`~cutlass.operators.CompiledArtifact` that bundles the compiled kernel
with the originating Operator and the target it was compiled for. It can be
passed back to :meth:`Operator.run <cutlass.operators.Operator.run>` to skip
recompilation.

.. automodule:: cutlass.operators.artifact
   :members:
   :show-inheritance:


Workspace
---------

Some Operators need a scratch buffer to run.
:meth:`Operator.get_workspace_size <cutlass.operators.Operator.get_workspace_size>`
returns an :class:`~cutlass.operators.workspace.AllocationRequirement` that
the caller satisfies by passing a :class:`~cutlass.operators.workspace.Workspace`
to :meth:`Operator.run <cutlass.operators.Operator.run>`.

.. automodule:: cutlass.operators.workspace
   :members:
   :show-inheritance:
