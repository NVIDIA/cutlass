Base Dialect Specification
==========================

Base facade over upstream MLIR (cutlass_compiler lowering target)


The ``base`` "dialect" is a curated subset of upstream MLIR — the
``arith``, ``scf``, ``cf``, ``ub``, ``func``, ``math``, ``gpu``,
``LLVM``, and ``NVVM`` dialects — that cutlass_compiler uses as its
lowering target.  It is not a real MLIR dialect with its own ops or
types; the only artifacts shipped under ``base`` are the conversion
and target-attach passes documented below, which take an
already-cute-free IR and lower it through standard MLIR to a GPU
binary.


.. contents::
   :local:
   :depth: 2

Passes
------

.. _pass-attach-nvvm-target:

``--attach-nvvm-target``
~~~~~~~~~~~~~~~~~~~~~~~~

*Attach an #nvvm.target attribute to each gpu.module*


Wraps the upstream `gpu-nvvm-attach-target` pass with cutlass_compiler-specific
defaults. After this pass each `gpu.module` carries an
`#nvvm.target<chip = ..., features = ...>` attribute that
downstream binary emission uses to drive ptxas. The `gpu.module`
body is unchanged.

Pair with `emit-gpu-binary` to compile the annotated module to a
`gpu.binary`. The two passes are intentionally separate so binary
emission can be skipped (e.g. JIT-execution paths).


**Options**

- ``--chip`` (``std::string``, default ``"sm_80"``) — Target GPU chip (passed to gpu-nvvm-attach-target).
- ``--features`` (``std::string``, default ``""``) — NVVM feature flags. Default is empty, which lets libNVVM pick the minimum required PTX version per chip and avoids the chip-vs-PTX-version floor errors that come from pinning. Set to e.g. `+ptx80` to lock the emitted PTX to a specific version (useful when shipping to older CUDA drivers with bounded PTX support).
- ``--opt-level`` (``unsigned``, default ``2``) — Optimization level for the NVVM compiler.

.. _pass-base-prepare:

``--base-prepare``
~~~~~~~~~~~~~~~~~~

*Canonicalize and normalize base-dialect IR before LLVM conversion*


Pipeline-driven simplification pass that runs the standard MLIR
cleanup passes on the base-dialect IR coming out of `cute-to-base`,
producing canonical post-cute IR ready for `OneShotConvertToLLVM`.

Composed of (in order):

  1. `canonicalize` — strength reduction (mul-by-pow2 → shli, etc.),
      poison + full insertvalue/extractvalue round-trip folding, dead
      arith elimination, constant dedup, GEP literal-index folding,
      and same-type `unrealized_conversion_cast` folding.
  2. `cse` — duplicate arith / constant elimination across siblings.
  3. `loop-invariant-code-motion` — pure arith hoisted out of
      `scf.for`.
  4. `reconcile-unrealized-casts` — defensive sweep for any leftover
      same-type casts canonicalize couldn't fold. Empirically a
      no-op on tested inputs but kept so users only need one
      second-invocation step (`| base-opt -base-prepare`) instead of
      two.

The sub-pipeline runs on the top-level `builtin.module` AND on each
`gpu.module` separately, so kernels are normalized in isolation
alongside host code.

.. code-block::

   cute-opt -cute-fold-static -cute-expand-ops -cute-to-base file.mlir \
     | base-opt -base-prepare



.. _pass-emit-gpu-binary:

``--emit-gpu-binary``
~~~~~~~~~~~~~~~~~~~~~

*Compile each annotated gpu.module into a gpu.binary*


Wraps the upstream `gpu-module-to-binary` pass with cutlass_compiler-specific
defaults. Each `gpu.module` carrying a `#nvvm.target<>` attribute
(typically attached by `attach-nvvm-target`) is serialized into a
`gpu.binary`.

Default `compilation-target` is `isa` — produces text PTX, which
is easy to inspect in LIT and does not require a working ptxas on
`$PATH`. Switch to `bin` (cubin) or `fatbin` for runtime use.


**Options**

- ``--compilation-target`` (``std::string``, default ``"isa"``) — gpu-module-to-binary mode: `isa` (text PTX, default), `bin` (cubin), or `fatbin` (multi-arch).

.. _pass-one-shot-convert-to-llvm:

``--one-shot-convert-to-llvm``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*Lower every remaining base-dialect op to LLVM (and NVVM, inside gpu.module)*


Final lowering pass between `base-prepare` and the target tails.
After this pass the only ops remaining are `LLVM::*`, `NVVM::*`,
and the preserved `gpu::GPUModuleOp` / `gpu::BinaryOp` shells
(their bodies are fully lowered to LLVM/NVVM; the shells stay so
the downstream binary-emission pass can compile them).

Architecture:

  1. Walk every `gpu.module` and run a partial conversion on each
     in isolation. Target: `LLVM` legal + NVVM legality via
     `configureGpuToNVVMConversionLegality`. Patterns:
     `populateGpuToNVVMConversionPatterns` plus the
     `ConvertToLLVMPatternInterface` hook (which auto-populates
     arith / scf / cf / math / ub / func patterns).
  2. Run the host partial conversion on the top-level module.
     Target: `LLVM` legal + `gpu.module` / `gpu.binary` /
     `gpu.launch_func` (dynamically) legal so the pre-converted
     GPU shells survive. Patterns: `populateGpuToLLVMConversionPatterns`
     for the host-side `gpu.launch_func` lowering plus the same
     interface hook.

SCF→CF lowering happens inline within the one-shot — the interface
hook brings SCF patterns in alongside CF, so a separate
`convert-scf-to-cf` preprocessing pass is not required.

Function-signature conversion is NOT this pass's job: cute-typed
signatures were already converted in `cute-to-base`. `func.func` →
`llvm.func` happens here structurally via the func-dialect
interface hook.

`applyPartialConversion` (not full) per scope — preserves the
gpu.module shells while still failing loudly on any unlowered op
via tight target legality.


