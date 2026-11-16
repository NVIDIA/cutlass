.. _operators_api_reference_heuristics:

Heuristics
==========

Heuristics rank the Operators returned by
:func:`~cutlass.operators.get_operators` by estimated performance. Discovery
first filters candidates for correctness; a heuristic then orders and may
prune those candidates. A candidate's rank is its position in the returned
list. Ranking is an estimate, not a guarantee of the fastest Operator.

For a worked GEMM example, see the
:doc:`heuristics tutorial </media/docs/operators/tutorials/007_heuristics>`.

Selecting a heuristic
---------------------

Pass a :class:`~cutlass.operators.Heuristic` instance as ``heuristic=`` to
:func:`~cutlass.operators.get_operators`. For example, given
:class:`~cutlass.operators.GemmArguments` named ``args``:

.. code-block:: python

   import cutlass.operators as ops
   from cutlass.operators.heuristics import NvMatmulHeuristics

   heuristic = NvMatmulHeuristics(gpu="B200")
   # Equivalent construction through the registry:
   heuristic = ops.get_heuristic("nvmatmul")(gpu="B200")
   operators = ops.get_operators(
       args, target_sm="100a", heuristic=heuristic, limit=5
   )

:func:`~cutlass.operators.get_heuristic` returns a class; instantiate it before
passing it to ``get_operators``. ``limit`` must be positive when provided.
It is forwarded to the heuristic as a hint, and ``get_operators`` truncates
the ranked result afterward. Pruning may leave fewer than ``limit`` results.
Omitting ``heuristic`` preserves discovery order. Ranking errors propagate
to the caller.

Built-in nvMatmul heuristic
----------------------------

``NvMatmulHeuristics`` supports SM100 non-blockscaled dense GEMM. Its ``gpu``
argument selects the modeled GPU SKU: ``"B200"`` (the default),
``"GB200_NVL"``, or ``"GB300_NVL"``. Other values raise ``ValueError``.
The model is selected explicitly, without detecting the current GPU.

Only Operators designed for the modeled compute capability and matching a
recommended configuration are returned. Other generations and unmatched
Operators are excluded, including kernels designed for older generations
that can run on the target. ``target_sm`` filters discovery for compatibility;
it does not change the heuristic's GPU model.

With non-empty candidates, unsupported arguments or layouts, missing
dependencies, and failure to match any recommendation raise errors. Empty
candidates return an empty list.

Install the optional dependency with
``pip install 'nvidia-cutlass-operators[heuristics]'``. Registration does not
imply that this dependency is available: use
:func:`~cutlass.operators.heuristics.nvmatmul.is_available` to check package
compatibility. This check does not validate a particular GEMM or guarantee
that a candidate will match.

.. autoclass:: cutlass.operators.heuristics.NvMatmulHeuristics
   :class-doc-from: both
   :members: rank
   :show-inheritance:

.. autofunction:: cutlass.operators.heuristics.nvmatmul.is_available

.. py:data:: cutlass.operators.heuristics.nvmatmul.MIN_NVMMH_VERSION
   :type: str

   Minimum supported version of the optional ``nvidia-matmul-heuristics``
   package. Availability also requires a compatible package API.

Custom heuristics and registry
------------------------------

Subclass :class:`~cutlass.operators.Heuristic` and implement ``rank``. Return
an ordered subset of the input Operator objects; pruning is allowed.
``get_operators`` raises ``RuntimeError`` if ranking introduces an Operator
or duplicates one beyond its count in the input. ``limit`` is a hint to the
ranker; ``get_operators`` enforces the final result limit.

Pass an instance directly, or register the class for lookup with
:func:`~cutlass.operators.get_heuristic`. Lookup returns the class itself and
raises ``KeyError`` for an unknown name.

The symbols below are also exported by ``cutlass.operators.heuristics``.
The nvMatmul ``_mapping`` and ``_provider`` modules are implementation details;
their query, configuration, and matching helpers are not public APIs.

.. autoclass:: cutlass.operators.Heuristic
   :members: rank

.. autofunction:: cutlass.operators.register_heuristic

.. autofunction:: cutlass.operators.get_heuristic

.. py:data:: cutlass.operators.available_heuristics
   :type: dict[str, type[Heuristic]]

   Maps registered names to heuristic classes. The built-in ``"nvmatmul"``
   class registers even when its optional dependency is absent. Registering an
   existing name replaces its previous class.
