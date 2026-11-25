# EFC (Epilogue Fusion Configuration) Design Document

## Table of Contents

1. [Introduction & Motivation](#1-introduction--motivation)
2. [Quick Start / User-Facing API](#2-quick-start--user-facing-api)
3. [Architecture Overview](#3-architecture-overview)
4. [The Three-Phase Execution Model](#4-the-three-phase-execution-model)
5. [Memory Hierarchy & Data Movement](#5-memory-hierarchy--data-movement)
6. [Warp Specialization Model](#6-warp-specialization-model)
7. [EFC Framework Internals](#7-efc-framework-internals)
8. [Broadcasting and Mode Remapping](#8-broadcasting-and-mode-remapping)
9. [Reduction](#9-reduction)
10. [Accumulator Splitting (Gated Activations)](#10-accumulator-splitting-gated-activations)
11. [Built-in Activation Functions](#11-built-in-activation-functions)
12. [Concrete Examples Walkthrough](#12-concrete-examples-walkthrough)
13. [EFC vs EVT Comparison](#13-efc-vs-evt-comparison)
14. [Constraints and Limitations](#14-constraints-and-limitations)
15. [Debugging & Logging](#15-debugging--logging)
16. [Block-Scaled (MX) Operands](#16-block-scaled-mx-operands)

---

## 1. Introduction & Motivation

### What is EFC?

The **Epilogue Fusion Configuration (EFC)** framework allows users to define
custom fused epilogue operations for CUTLASS GEMM kernels targeting NVIDIA
Blackwell (SM100) GPUs. An "epilogue" is the post-processing that runs after a
GEMM computes its accumulator `Acc = A x B` -- operations like scaling,
bias addition, activation functions, and storing results to multiple output
tensors.

### The Problem

In a typical deep learning workflow, a GEMM is followed by element-wise
operations:

```python
D = activation(Acc * alpha + C * beta + bias)
```

Without fusion, each operation requires a separate kernel launch and full
round-trip through global memory (GMEM). For Blackwell GPUs with high
arithmetic throughput, these memory round-trips become the bottleneck.

### The EFC Solution

EFC lets users write the epilogue as a **plain Python function** that the
framework automatically compiles and fuses into the GEMM kernel:

```python
def epilogue(efc_config, C, D, alpha, beta):
    D.store(efc_config.accum() * alpha + C.load() * beta)
```

The same function code runs in three different contexts: parameter analysis
(introspection), GPU execution (inside a CUDA kernel), and CPU validation
(with PyTorch). This "write once, run everywhere" approach eliminates the need
for users to understand the GPU memory hierarchy, warp specialization, or TMA
operations.

---

## 2. Quick Start / User-Facing API

### Minimal Example

From `custom_epilogue_dense_gemm.py`:

```python
def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
    # Store the accumulator to Y
    Y.store(efc_config.accum())
    # Compute the result with alpha, beta scaling and X factor
    result = (
        efc_config.relu(efc_config.accum() * alpha + C.load() * beta)
        + X.load() * x_factor
    )
    D.store(result)
```

### Key Conventions

| Convention | Meaning |
|-----------|---------|
| `efc_config` | **Must** be the first parameter name (enforced by the framework) |
| `efc_config.accum()` | Access the MMA accumulator (`A x B` result) |
| `efc_config.accum_split(num_parts)` | Split the accumulator into `num_parts` N-interleaved parts, for gated activations fused onto a single MMA. See [Accumulator Splitting (Gated Activations)](#10-accumulator-splitting-gated-activations) |
| `efc_config.swiglu()` / `geglu()` / `reglu()` / `gated(gate_activation)` | A gated linear unit `up * activation(gate)` from a two-way split, without naming the halves. See [Gate Shorthands](#gate-shorthands) |
| `tensor.load()` | Read a supplemental tensor from global memory |
| `tensor.load(via=...)` | Read through an explicit data transport. See [Per-Tensor Transport](#per-tensor-transport) |
| `tensor.store(value)` | Write a value to a supplemental tensor in global memory |
| `tensor.store(value, via=...)` | Write through an explicit data transport. See [Per-Tensor Transport](#per-tensor-transport) |
| `tensor.reduce(value, op=...)` | Atomically combine the per-tile fold of `value` into a low-rank destination — a single element (all-`:` subscript) or a kept-axis vector (e.g. `[:, 0, :]`).  See [Reduction](#9-reduction) |
| `efc_config.ADD` / `MAX` / `MIN` / `MUL` | Reduction-op aliases for `cute.ReductionOp.{ADD,MAX,MIN,MUL}` so epilogues don't need to import `cutlass.cute` |
| `efc_config.relu(x)` | Apply a built-in activation function |
| `efc_config.full_like(x, v)` | Create a tensor filled with value `v` (dispatches to CuTe or PyTorch) |
| `tensor.remap_modes[...]` | Broadcast (via `.load()`) or fold (via `.reduce()`) a tensor relative to the output layout using subscript syntax (`:` for broadcast / folded, integers for mode indices). See [Broadcasting and Mode Remapping](#8-broadcasting-and-mode-remapping) and [Reduction](#9-reduction) |

### Broadcast Example

From `broadcast_custom_epilogue_dense_gemm.py`:

```python
def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
    # Y is (N, M, L), transposed relative to output (M, N, L): read-modify-write
    Y.remap_modes[1, 0, 2].store(efc_config.accum() + Y.remap_modes[1, 0, 2].load())
    # C is (N, L): broadcast along M.  X is (M, L): broadcast along N.
    # x_factor is 0-d: broadcast to all dimensions of the output.
    result = (
        efc_config.relu(
            efc_config.accum() * alpha
            + C.remap_modes[:, 0, 1].load() * beta
        )
        + X.remap_modes[0, :, 1].load()
        * x_factor.remap_modes[:, :, :].load()
    )
    D.store(result)
```

### Per-Tensor Transport

By default each supplemental tensor is moved between global memory
and the kernel through the TMA bulk-tensor copy engine.  This is the
fastest path on Hopper/Blackwell but it imposes alignment, vector
width and dimensionality constraints that some tensors cannot meet.
For those cases `Tensor.load` and `Tensor.store` accept an explicit
`via=` kwarg drawn from the `Transport` enum:

| `Transport` member | Direction | SMEM staging | Implementation |
|--------------------|-----------|--------------|----------------|
| `TMA` (default) | read & write | yes | TMA descriptor + bulk-tensor copy engine |
| `SYNC_GMEM_LOAD` | read | no | per-thread `cute.copy` register&lt;-GMEM |
| `SYNC_GMEM_STORE` | write | no | per-thread `cute.copy` register-&gt;GMEM |
| `ASYNC_GMEM_LOAD` | read | yes | per-thread `cp.async` G2S |

```python
def epilogue(efc_config, bias, D):
    v = efc_config.accum()
    # Bias does not meet TMA's descriptor constraints -- read it
    # synchronously, straight from GMEM into the per-thread fragment:
    v = v + bias.load(via=efc_config.SYNC_GMEM_LOAD)
    # D's layout cannot be expressed as a TMA descriptor either --
    # drain the per-thread fragment straight to GMEM:
    D.store(v, via=efc_config.SYNC_GMEM_STORE)
```

The `Transport` members are also re-exported at module level for the
qualified form:

```python
from helpers.efc import Transport

def epilogue(efc_config, bias, D):
    v = efc_config.accum()
    v = v + bias.load(via=Transport.SYNC_GMEM_LOAD)
    D.store(v, via=Transport.SYNC_GMEM_STORE)
```

Both forms select the same path; pick whichever reads better in
context.  An optional `num_bits_per_copy=<int>` kwarg forces the
transaction width; the default (`None`) auto-derives the widest
width that the per-thread fragment's alignment permits, capped at
256 bits.

A given tensor must use the same `via` on every access -- accessing
the same tensor with conflicting `via` values raises `ValueError`
at the parameter-analysis phase.

### Wiring into a GEMM

```python
from helpers.efc.dense_gemm.sm100 import DenseGemmEFC

# Build GEMM with EFC configuration
gemm = DenseGemmEFC(
    acc_dtype=cutlass.Float32,
    epi_dtype=cutlass.Float32,
    use_2cta_instrs=True,
    mma_tiler_mn=(128, 128),
    cluster_shape_mn=(2, 1),
    epilogue_function_configuration=epilogue,
)

# Compile with actual tensors (triggers parameter analysis)
compiled_gemm = gemm.compile(
    a_tensor, b_tensor, max_active_clusters, stream,
    # Supplemental arguments in the same order as the epilogue parameters
    c_tensor, d_tensor, alpha, beta, x_tensor, x_factor, y_tensor,
)

# Execute
compiled_gemm(a_tensor, b_tensor, stream,
              c_tensor, d_tensor, alpha, beta, x_tensor, x_factor, y_tensor)
```

Parameter names in the epilogue function signature determine how tensors are
tracked through the framework. The EFC uses `inspect.signature()` to extract
these names and uses them as dictionary keys throughout the compilation and
execution pipeline.

---

## 3. Architecture Overview

### Three-Layer Architecture

```text
+------------------------------------------------------------------+
|                        USER LAYER                                |
|                                                                  |
|   def epilogue(efc_config, C, D, alpha, beta):                   |
|       D.store(efc_config.accum() * alpha + C.load() * beta)      |
|                                                                  |
+-------------------------------+----------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                     EFC FRAMEWORK LAYER                          |
|             helpers/efc/{_helpers, _phase, _remap, _tensor,      |
|                                _configuration, _base}.py         |
|                                                                  |
|   EFC class: analysis, phase dispatch, tensor tracking           |
|   +-- EFC.Configuration: phase-specialized epilogue caller       |
|   +-- EFC.Tensor: proxy object with load()/store()/reduce()      |
|   +-- EFC.Phase: ParameterAnalysis | ThreadOperation |           |
|   |              PyTorchEvaluation                               |
|   +-- EFC.JIT: operation-neutral host-side base (helpers,        |
|   |            remapping, dtype tracking)                        |
|   +-- EFC.Kernel: operation-neutral device-side base (foreach    |
|   |               iterators)                                     |
|   +-- VariadicParameters: argument packing across boundaries     |
|                                                                  |
|   EFC.Phase / EFC.Tensor / EFC._RemapModesAccessor /             |
|   EFC.Configuration are class-body ClassVar aliases pointing     |
|   at the sibling-module definitions; EFC.JIT / EFC.Kernel are    |
|   ClassVar aliases pointing at the in-file base classes.         |
|                                                                  |
+-------------------------------+----------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|             ARCH-NEUTRAL OPERATOR LAYER (per-operation)          |
|             helpers/efc/dense_gemm/_operation.py                 |
|                                                                  |
|   _DenseGemmEFCKernelBase(EFC.Kernel): GEMM-epilogue logic       |
|   shared across architectures, e.g.:                             |
|   +-- partition_global_tensors_for_tiled_mma                     |
|   +-- slice_written_tensors_per_mma_tile_index                   |
|   +-- prepare_tensor_load_for_subtiles                           |
|   +-- load_tensors_from_smem_to_register                         |
|   +-- epilogue_computation                                       |
|   +-- store_written_tensors_to_smem                              |
|                                                                  |
+-------------------------------+----------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|              ARCH-SPECIFIC OPERATOR LAYER (sm100)                |
|         helpers/efc/dense_gemm/sm100/_operation.py               |
|         helpers/efc/dense_gemm/sm100/_helpers.py                 |
|                                                                  |
|   DenseGemmEFC class: warp specialization, TMA, pipelines        |
|   +-- @cute.jit __call__: setup TMA, grid, launch kernel         |
|   +-- @cute.kernel kernel: 4 specialized warp roles              |
|   +-- Pipeline management: ab_pipeline, acc_pipeline,            |
|   |                        c_pipeline, d_pipeline                |
|   +-- Persistent tile scheduling                                 |
|                                                                  |
|   _DenseGemmEFCJIT(EFC.JIT): sm100 host-side specifics:          |
|   compute_stage(), smem_layout(), create_tma_arguments(),        |
|   create_supplemental_arguments_for_kernel().                    |
|                                                                  |
|   _DenseGemmEFCKernel(_DenseGemmEFCKernelBase):                  |
|   sm100 device-side specifics: prefetch_tma_descriptors(),       |
|   allocate_smem(), copy_and_partition_supplemental_rmem_tensors, |
|   create_epilogue_subtile_tensors(), load_tensor_subtiles(),     |
|   tma_store_written_tensors_to_gmem().                           |
|                                                                  |
+------------------------------------------------------------------+
```

The framework layer is **operation-agnostic**: nothing in `_base.py` knows
about GEMM, TMA, or any specific accelerator architecture. Operation-specific
behaviour is added by *subclassing* `EFC.JIT` and `EFC.Kernel` — that
specialization happens in the operation's own files. Splitting between an
arch-neutral operation layer (`dense_gemm/_operation.py`) and an arch-specific
one (`dense_gemm/sm100/_operation.py`) keeps the GEMM-shared logic available
for any future architecture port (Hopper, future Blackwells, ...).

### EFC Class Hierarchy

```text
EFC (`_base.py`)
 |
 +-- EFC.Phase (enum, defined in   -- ParameterAnalysis, ThreadOperation,
 |   `_phase.py`; exposed on EFC      PyTorchEvaluation
 |   as a class-body ClassVar
 |   alias for the public-API
 |   spelling)
 |
 +-- EFC.Tensor                    -- Proxy for tensor arguments
 |    +-- ParameterAttributes      -- Tracks is_tensor, is_read, is_written,
 |    |                               mapped_source, source_mode_map,
 |    |                               degenerate_to_scalar, reduce_op
 |    +-- .load() / .store()       -- Phase-dispatched read/write
 |    +-- .reduce(value, op=...)   -- Cross-CTA atomic fold into a 1-elt dest
 |    +-- .remap_modes[...]        -- Subscript syntax for broadcast/fold
 |
 +-- EFC.Configuration             -- Specializes epilogue for a phase
 |    +-- .accum()                 -- Returns accumulator (phase-aware)
 |    +-- .relu(), .gelu(), etc.   -- Built-in activation functions
 |    +-- .remap_modes()           -- Broadcast/transpose tensor modes
 |    +-- .__getattr__()           -- "Chameleon" dispatch for helpers
 |    +-- .__call__()              -- Executes user's epilogue function
 |
 +-- EFC.JIT (VariadicParameters)  -- Host-side (@cute.jit) BASE class
 |    |                              with operation-neutral helpers only
 |    +-- record_tensor_dtypes()
 |    +-- handle_remapping()     -- Applies remap_modes() to CuTe tensors
 |    +-- foreach_tensor() / foreach_remapped_tensor() / ... iterators
 |    +-- read/written_tensor_name_with_bigger_element_type()
 |
 +-- EFC.Kernel (VariadicParameters) -- Device-side (@cute.kernel) BASE
      |                                 class with operation-neutral helpers
      +-- foreach_tensor() / foreach_read_tensor() / foreach_written_tensor()

Operation-specific subclasses live OUTSIDE the framework. For dense GEMM:

_DenseGemmEFCKernelBase(EFC.Kernel)            -- arch-neutral GEMM logic
 |   (`dense_gemm/_operation.py`)
 +-- partition_global_tensors_for_tiled_mma()
 +-- slice_written_tensors_per_mma_tile_index()
 +-- prepare_tensor_load_for_subtiles()         (epilogue load warp)
 +-- load_tensors_from_smem_to_register()
 +-- epilogue_computation()
 +-- store_written_tensors_to_smem()

_DenseGemmEFCJIT(EFC.JIT)                       -- sm100-specific host setup
 |   (`dense_gemm/sm100/_operation.py`)
 +-- compute_stage()
 +-- smem_layout()
 +-- create_tma_arguments()
 +-- create_supplemental_arguments_for_kernel()

_DenseGemmEFCKernel(_DenseGemmEFCKernelBase)    -- sm100-specific device exec
 |   (`dense_gemm/sm100/_operation.py`)
 +-- prefetch_tma_descriptors()
 +-- allocate_smem()
 +-- copy_and_partition_supplemental_rmem_tensors()
 +-- tma_store_written_tensors_to_gmem()
 +-- create_epilogue_subtile_tensors()           (epilogue load warp)
 +-- load_tensor_subtiles()                      (epilogue load warp)

The DenseGemmEFC operation class wires these subclasses to the framework via
class attributes:

class DenseGemmEFC:
    JIT    = _DenseGemmEFCJIT       # subclass of EFC.JIT
    Kernel = _DenseGemmEFCKernel    # subclass of EFC.Kernel (via Base)
```

### Data Flow Diagram

```text
  User writes:
  epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y)
          |
          v
  EFC.__init__()                  # inspect.signature() -> parameter names
          |
          v
  EFC.compile()                   # With actual tensors
          |
          +-- analyze_epilogue_with_arguments()
          |       |
          |       +-- Run ParameterAnalysis phase (dummy execution)
          |       |       .load() -> marks tensor as "read"
          |       |       .store() -> marks tensor as "written"
          |       |       .remap_modes[...] -> registers remapped tensor with
          |       |           mapped_source, source_mode_map,
          |       |           degenerate_to_scalar
          |       |
          |       +-- Produces: read_tensor_names, written_tensor_names,
          |                     remapped_tensor_names
          |
          +-- EFC.JIT.__init__()  # Create host-side infrastructure
                  |
                  v
  DenseGemmEFC.__call__()         # @cute.jit entry point
          |
          +-- JIT.record_tensor_dtypes()
          +-- JIT.compute_stage()        # smem budget calculation
          +-- JIT.smem_layout()          # per-tensor smem layouts
          +-- JIT.create_tma_arguments() # TMA descriptors
          +-- JIT.create_supplemental_arguments_for_kernel()
          |
          v
  DenseGemmEFC.kernel()           # @cute.kernel GPU execution
          |
          +-- Kernel.prefetch_tma_descriptors()
          +-- Kernel.allocate_smem()
          +-- [Per tile, per subtile:]
          |     +-- Kernel.load_tensors_from_smem_to_register()
          |     +-- Kernel.epilogue_computation()   # calls user's epilogue
          |     +-- Kernel.store_written_tensors_to_smem()
          |     +-- Kernel.tma_store_written_tensors_to_gmem()
          v
  Results in GMEM
```

---

## 4. The Three-Phase Execution Model

The central design insight of EFC is that the **same epilogue function** runs in
three completely different contexts. The `EFC.Phase` enum
(defined in `_phase.py`, aliased as `EFC.Phase` via a class-body
`ClassVar` in `_base.py`) defines these contexts:

### Phase 1: `ParameterAnalysis`

**Purpose**: Discover which tensors are read vs. written by introspecting
`.load()` and `.store()` side-effects.

**How it works**: The framework calls the user's epilogue function with
`EFC.Tensor` proxy objects. When the user calls `C.load()`, the proxy records
`is_read = True` in `ParameterAttributes`. When the user calls `D.store(...)`,
it records `is_written = True`. Scalar parameters receive a dummy value of
`Float32(42)`. The accumulator (`efc_config.accum()`) also returns `Float32(42)`.

**When it runs**: During `EFC.compile()` -> `analyze_epilogue_with_arguments()`.

### Phase 2: `ThreadOperation`

**Purpose**: Execute the actual epilogue computation on GPU inside a CUDA kernel.

**How it works**: Tensors have already been loaded from SMEM to registers.
`tensor.load()` returns the register tensor cast to `epi_dtype`.
`tensor.store(value)` writes into the destination register tensor.
`efc_config.accum()` returns the real accumulator vector from TMEM.

**When it runs**: Inside `EFC.Kernel.epilogue_computation()`, which is called
from the epilogue warps in the `@cute.kernel` function.

### Phase 3: `PyTorchEvaluation`

**Purpose**: Execute the same epilogue on CPU with PyTorch tensors for reference
validation.

**How it works**: `tensor.load()` returns a PyTorch CPU tensor.
`tensor.store(value)` calls `torch_tensor.copy_(value)`.
`efc_config.accum()` returns the CPU-computed `A @ B` result.

**When it runs**: During `DenseGemmEFC.evaluate_on_cpu()` for correctness
checking.

### The "Chameleon" Pattern

Helper functions like `full_like()`, `where()`, and `exp()` need to dispatch to
different backends depending on the phase. The `EFC.Configuration.__getattr__`
method (`_configuration.py`) intercepts any unknown method call and creates a
"chameleon" function:

```python
def __getattr__(self, name):
    def chameleon(self, *args, **kwargs):
        match self.phase:
            case EFC.Phase.ParameterAnalysis:
                return 1  # Dummy value
            case EFC.Phase.ThreadOperation:
                return getattr(cutlass.cute, name)(*args, **kwargs)
            case EFC.Phase.PyTorchEvaluation:
                return getattr(torch, name)(*args, **kwargs)
    return types.MethodType(chameleon, self)
```

This means `efc_config.full_like(x, 0)` automatically calls
`cutlass.cute.full_like(x, 0)` on GPU or `torch.full_like(x, 0)` on CPU, and
the user does not need to know the difference.

---

## 5. Memory Hierarchy & Data Movement

### Data Path for Supplemental Tensors

```text
              GLOBAL MEMORY (GMEM)
   +--------------------------------------------+
   |  C (read)   X (read)   D (write)  Y (write)|
   +------+------+------+------+------+---------+
          |      |             ^      ^
          | TMA  | TMA         | TMA  | TMA
          | G2S  | G2S         | S2G  | S2G
          v      v             |      |
   +------+------+------+------+------+---------+
   |         SHARED MEMORY (SMEM)               |
   |  sC_read    sX_read    sD_write  sY_write  |
   |  (staged)   (staged)   (staged)  (staged)  |
   +------+------+------+------+------+---------+
          |      |             ^      ^
          | S2R  | S2R         | R2S  | R2S
          | copy | copy        | copy | copy
          v      v             |      |
   +------+------+------+------+------+---------+
   |          REGISTER MEMORY (RMEM)             |
   |  tSR_rC    tSR_rX                           |
   |                     tRS_rD     tRS_rY       |
   |         +-- epilogue computation --+        |
   |         |  acc_vec (from TMEM)     |        |
   |         |  result = relu(acc*a     |        |
   |         |    + C*b) + X*x_f        |        |
   |         +--------------------------+        |
   +---------------------------------------------+

   Also: Accumulator flows TMEM -> RMEM via tcgen05.ld
```

The diagram above shows the default TMA path.  When a tensor is
configured with a non-default `Transport` (see
[Per-Tensor Transport](#per-tensor-transport) in "Quick Start / User-Facing API"), its
data path differs:

- `SYNC_GMEM_LOAD` / `SYNC_GMEM_STORE`: bypass SMEM entirely.  The
  consumer warp issues a per-thread `cute.copy` between GMEM and
  the register fragment, inline in the EFC body.  No SMEM stage,
  no pipeline arrival for that tensor.
- `ASYNC_GMEM_LOAD`: reuses the same SMEM staging buffer and
  `c_pipeline` slots as the TMA path, but the producer warp emits
  per-thread `cp.async` ops in place of the TMA descriptor copy.
  Each load-warp thread fences its own copies on the stage barrier
  via a no-increment `cp.async.mbarrier.arrive`, so the full-barrier
  arrival count is one per load thread plus the producer's
  end-of-stage arrive.  Because TMA's byte-counted `expect_tx` and
  the cp.async arrivals compose on the same barrier, a single
  `c_pipeline` serves pure-TMA, pure-cp.async, and mixed read sets
  alike -- no separate cp.async pipeline is needed.  This is also
  what lets cp.async reads work under a 2-CTA MMA: the barrier stays
  CTA-local, so it never needs the cluster-scoped arrival that TMA
  multicast relies on.

### Pipeline Stages

The framework manages two epilogue pipelines:

| Pipeline | Direction | Managed by | Stages |
|----------|-----------|------------|--------|
| `c_pipeline` | GMEM -> SMEM (read tensors) | `PipelineTmaAsync` | `num_c_stage` (default 2) |
| `d_pipeline` | SMEM -> GMEM (written tensors) | `PipelineTmaStore` | `num_d_stage` (default 2+) |

The `compute_stages()` method (`dense_gemm/sm100/_operation.py`) calculates how
many pipeline stages fit in shared memory after accounting for A/B mainloop
buffers and barrier storage:

```text
Available SMEM = smem_capacity - (A/B stages * ab_bytes) - barrier_bytes
c_bytes = sum(smem_per_stage for each read tensor) * num_c_stage
d_bytes = sum(smem_per_stage for each written tensor) * num_d_stage
```

Any leftover SMEM is allocated to additional `d_pipeline` stages to hide store
latency.

### Subtile Loop

Each MMA tile is further divided into epilogue subtiles (`epi_tile`). The
epilogue warps iterate over these subtiles:

```text
for subtile_idx in range(subtile_cnt):
    1. Load accumulator from TMEM to registers (tcgen05.ld)
    2. Wait for c_pipeline (supplemental tensor loads)
    3. Copy supplemental tensors from SMEM to registers (S2R)
    4. Execute user's epilogue function
    5. Copy results from registers to SMEM (R2S)
    6. TMA store from SMEM to GMEM (S2G)
```

---

## 6. Warp Specialization Model

The Blackwell SM100 persistent GEMM uses **7 warps** with fixed roles, assigned
in `DenseGemmEFC.__init__()` (`dense_gemm/sm100/_operation.py`):

```text
 Warp ID   Role                  Description
 -------   --------------------  ------------------------------------------
 0, 1,     Epilogue Warps        Load accumulator from TMEM, execute EFC
 2, 3                            epilogue, store results to SMEM, first
                                 warp (0) also does TMA store SMEM->GMEM

 4         MMA Warp              Performs tcgen05.mma, writes accumulator
                                 to TMEM

 5         TMA Warp              Loads A and B matrices GMEM->SMEM via TMA

 6         Epilogue Load Warp    Asynchronously loads supplemental tensors
                                 (read inputs) GMEM->SMEM via TMA
```

### How EFC Plugs In

```text
  Warp 5 (TMA):      Load A, B via TMA ──────────────────────> (A/B in SMEM)
                                                                   |
  Warp 4 (MMA):      tcgen05.mma(A_smem, B_smem) ──> Acc in TMEM   |
                                                           |       |
  Warp 6 (Epi Load): TMA load C, X to SMEM ──────>  (C,X in SMEM)  |
                                                           |       |
  Warps 0-3 (Epi):   tcgen05.ld: TMEM -> RMEM              |       |
                      S2R copy: SMEM -> RMEM    <──────────+       |
                      >>> EFC epilogue function <<<                |
                      R2S copy: RMEM -> SMEM                       |
                      TMA store: SMEM -> GMEM  ──> D, Y in GMEM    |
```

The warp specialization is implemented with `if warp_idx == ...` branches in
the `@cute.kernel` function (`dense_gemm/sm100/_operation.py`). Each warp
runs its own persistent tile scheduling loop, synchronized via pipelines:

- `ab_pipeline` (PipelineTmaUmma): TMA warp <-> MMA warp
- `acc_pipeline` (PipelineUmmaAsync): MMA warp <-> Epilogue warps
- `c_pipeline` (PipelineTmaAsync): Epilogue load warp <-> Epilogue warps
- `d_pipeline` (PipelineTmaStore): Epilogue warps internal store pipelining

---

## 7. EFC Framework Internals

### 7.1 `EFC.__init__` / `analyze_epilogue`

(`_base.py`)

When an `EFC` instance is created, it immediately introspects the user's
epilogue function:

```python
def analyze_epilogue(self, epilogue_function_configuration):
    sig = inspect.signature(epilogue_function_configuration)
    names = [name for name in sig.parameters.keys()]
    if names[0] != "efc_config":
        raise RuntimeError(
            "The epilogue configuration function must take efc_config as an argument"
        )
    self.epilogue_parameter_names = names[1:]
```

This extracts parameter names (e.g., `["C", "D", "alpha", "beta"]`) which
become the keys used throughout the framework for tensor tracking, argument
packing, and TMA descriptor management.

### 7.2 `EFC.compile` / `analyze_epilogue_with_arguments`

(`_base.py`)

Called with actual tensor/scalar arguments to determine types and read/write
patterns:

1. For each argument, creates a `ParameterAttributes` recording whether it is a
   `cutlass.cute.Tensor` or a scalar.
2. Runs the `ParameterAnalysis` phase: the epilogue function executes with proxy
   `EFC.Tensor` objects. `.load()` side-effects set `is_read = True`;
   `.store()` side-effects set `is_written = True`.
3. Produces three lists: `used_tensor_names`, `read_tensor_names`,
   `written_tensor_names`.
4. Validates at least one written tensor exists.
5. Creates `EFC.JIT` for host-side infrastructure.

### 7.3 `EFC.JIT` (Host-Side Setup)

(`_base.py`)

Extends `VariadicParameters` and runs inside `@cute.jit`. The framework
class itself only provides operation-neutral helpers; GEMM-specific host
methods live on the `_DenseGemmEFCJIT` subclass in
`dense_gemm/sm100/_operation.py`.

**Operation-neutral methods (in `EFC.JIT`):**

| Method | Purpose |
|--------|---------|
| `record_tensor_dtypes()` | Stores `element_type` for each tensor (TMA atoms don't preserve it) |
| `handle_remapping()` | Applies `remap_modes()` on CuTe tensors for broadcast/transpose views |
| `foreach_tensor()` / `foreach_argument()` / etc. | Iteration helpers reused by operation-specific methods |

**GEMM-specific methods (added by `_DenseGemmEFCJIT(EFC.JIT)` —
`dense_gemm/sm100/_operation.py`):**

| Method | Purpose |
|--------|---------|
| `compute_stage()` | Validates layouts match C/D, computes per-tensor SMEM sizes |
| `smem_layout()` | Creates staged SMEM layouts for read and written tensors |
| `create_tma_arguments()` | Builds G2S (read) and S2G (write) TMA atoms and tensors |
| `create_supplemental_arguments_for_kernel()` | Packs TMA atoms, tensors, and layouts into the `Kernel` instance |

The TMA argument creation expands each user tensor into multiple kernel
arguments:
- Read tensor `C` becomes: `C_tma_atom_read`, `C_tma_tensor_read`,
  `C_smem_layout_staged_read`
- Written tensor `D` becomes: `D_tma_atom_written`, `D_tma_tensor_written`,
  `D_smem_layout_staged_written`
- Scalar `alpha` passes through unchanged.
- Degenerate scalar broadcast tensor `x_factor` is passed as a single scalar
  (the source tensor pointer), bypassing TMA/SMEM entirely.

### 7.4 `EFC.Kernel` (Device-Side Execution)

(`_base.py`)

Extends `VariadicParameters` and runs inside `@cute.kernel`. Like
`EFC.JIT`, the framework base class itself only carries operation-neutral
iteration helpers (`foreach_tensor`, `foreach_read_tensor`,
`foreach_written_tensor`). GEMM-specific behaviour is added in two
subclassing layers:

* `_DenseGemmEFCKernelBase(EFC.Kernel)` —
  `dense_gemm/_operation.py` — arch-neutral GEMM-epilogue logic.
* `_DenseGemmEFCKernel(_DenseGemmEFCKernelBase)` —
  `dense_gemm/sm100/_operation.py` — sm100-specific Blackwell logic.

**Initialization (called once per kernel launch):**

| Method | Defined on | Purpose |
|--------|-----------|---------|
| `prefetch_tma_descriptors()` | `_DenseGemmEFCKernel` (sm100) | Prefetch TMA descriptors for all tensors |
| `allocate_smem()` | `_DenseGemmEFCKernel` (sm100) | Allocate staged SMEM buffers for all tensors |
| `partition_global_tensors_for_tiled_mma()` | `_DenseGemmEFCKernelBase` (arch-neutral) | Partition global tensors for the MMA layout |
| `copy_and_partition_supplemental_rmem_tensors()` | `_DenseGemmEFCKernel` (sm100) | Create S2R/R2S copy atoms, register tensors, SMEM partitions |

**Per-subtile execution (inner loop):**

| Method | Defined on | Called by | Purpose |
|--------|-----------|-----------|---------|
| `load_tensors_from_smem_to_register()` | `_DenseGemmEFCKernelBase` | Epilogue warps | S2R copy for all read tensors |
| `epilogue_computation()` | `_DenseGemmEFCKernelBase` | Epilogue warps | Build load/store context, call user's epilogue |
| `store_written_tensors_to_smem()` | `_DenseGemmEFCKernelBase` | Epilogue warps | R2S copy for all written tensors |
| `tma_store_written_tensors_to_gmem()` | `_DenseGemmEFCKernel` (sm100) | Warp 0 only | TMA S2G for all written tensors |

**Epilogue load warp methods:**

| Method | Defined on | Purpose |
|--------|-----------|---------|
| `create_epilogue_subtile_tensors()` | `_DenseGemmEFCKernel` (sm100) | Setup TMA partitions for reading supplemental tensors |
| `prepare_tensor_load_for_subtiles()` | `_DenseGemmEFCKernelBase` | Slice tensors for current MMA tile, compute subtile count |
| `load_tensor_subtiles()` | `_DenseGemmEFCKernel` (sm100) | Execute TMA G2S loads for each subtile |

### 7.5 `VariadicParameters`

(`_base.py`)

Solves the problem of passing a variable number of arguments across
`@cute.jit`/`@cute.kernel` boundaries, which only accept fixed signatures.

It dynamically creates a `dataclass` from parameter names, then:
- `pack_arguments()`: converts the dataclass into a tuple (the DSL handles
  recursive tuples/lists)
- `unpack_parameters()`: reconstructs the dataclass from a tuple inside the
  kernel

```python
class VariadicParameters:
    def __init__(self, efc, parameter_names):
        fields = [(name, typing.Any) for name in parameter_names]
        self._parameter_class = dataclasses.make_dataclass(
            "Parameter", fields, slots=True
        )
```

### 7.6 `create_named_epilogue()`

(`_base.py`)

A safe alternative to `exec()`/`eval()` for programmatic function generation.
Uses `inspect.Parameter` and `inspect.Signature` to create a wrapper function
with specific parameter names:

```python
def create_named_epilogue(param_names, func):
    parameters = [
        inspect.Parameter(name, inspect.Parameter.POSITIONAL_OR_KEYWORD)
        for name in param_names
    ]
    new_signature = inspect.Signature(parameters)

    def wrapper(*args, **kwargs):
        bound = new_signature.bind(*args, **kwargs)
        bound.apply_defaults()
        ordered_args = [bound.arguments[name] for name in param_names]
        return func(*ordered_args)

    wrapper.__signature__ = new_signature
    return wrapper
```

This is used by `synthetic_custom_epilogue_dense_gemm.py` to generate epilogue
functions with dynamically determined parameter names.

---

## 8. Broadcasting and Mode Remapping

### Motivation

Supplemental tensors in an epilogue do not always have the same shape as the
output tensor `D` (M×N×L). Common cases include:

- A **bias vector** of shape (N, L) that should broadcast along the M dimension.
- A **row-scaling vector** of shape (M, L) that should broadcast along N.
- A **scalar factor** stored as a 0-d tensor that broadcasts to all dimensions.
- An **output tensor** `Y` with **transposed modes** (N, M, L) relative to `D`
  (M, N, L).

EFC supports all these patterns through the `tensor.remap_modes[...]` subscript
syntax, which creates a remapped tensor view with zero-stride broadcasting
and/or reordered modes.

### The `remap_modes` API

```python
tensor.remap_modes[<subscript>]
```

The subscript uses Python's `__getitem__` syntax where `:` means broadcast
(`True`) and integers are source mode indices. The target shape is implicitly
the output shape `(m, n, l)` derived from the GEMM inputs `A(m, k, l)` and
`B(n, k, l)`.

The subscript has the same length as the **output** rank. Each element is
either:

- An **integer** — the index of the source mode to place at this position.
- **`:`** — broadcast the source along this dimension (stride set to 0).

**Invariant**: `len(source.shape) + count(: in subscript) == len(subscript)`

The returned object is a remapped tensor proxy that supports `.load()` and
`.store()`, just like a regular tensor parameter. It can even be used for
read-modify-write by calling both `.load()` and `.store()` on the same
remapped view.

### Remap Patterns

```text
Output shape:  (M, N, L)

Source        Source shape    remap_modes syntax     Effect
----------   ------------    -------------------    ----------------------------
C             (N, L)         C.remap_modes[:,0,1]   Broadcast C along M
X             (M, L)         X.remap_modes[0,:,1]   Broadcast X along N
x_factor      ()   (0-d)     x_factor.remap_modes[:,:,:]  Scalar broadcast to all dims
Y             (N, M, L)      Y.remap_modes[1,0,2]   Transpose M↔N (no broadcast)
bias          (N,)           bias.remap_modes[:,0,:] Broadcast along M and L
```

### How it Works Internally

#### Phase 1: ParameterAnalysis

When `.remap_modes[...]` is used during the analysis phase, the framework:

1. Constructs a mangled name encoding the remapping:
   `"{source}__remapped__{mode_0}__{mode_1}__..."`.
2. Registers a new `ParameterAttributes` entry with `mapped_source`,
   `source_mode_map`, and `degenerate_to_scalar` fields.
3. If all elements of `source_mode_map` are `True`, the tensor degenerates to
   a scalar — `degenerate_to_scalar` is set to `True`.
4. Returns an `EFC.Tensor` proxy for the remapped view, which can be
   `.load()`-ed and `.store()`-ed like any other tensor.
5. Results are cached per mangled name, so repeated calls with the same
   arguments (e.g. for both `.load()` and `.store()`) return the same proxy
   without overwriting `is_read`/`is_written` flags.

After analysis, the framework knows four lists:
`used_tensor_names`, `read_tensor_names`, `written_tensor_names`, and
`remapped_tensor_names`.

#### Phase 2: ThreadOperation (GPU kernel)

In the JIT host-side setup (`EFC.JIT.handle_remapping()`):

- For each non-degenerate remapped tensor, `remap_modes()` is called on the
  actual `cutlass.cute.Tensor` to produce a new CuTe tensor with rewritten
  strides (zero for broadcast dimensions). The resulting tensor is stored in
  `self.remapped_tensors[mangled_name]`.
- These remapped tensors participate in TMA, SMEM allocation, and the
  standard load/store pipeline, just like regular supplemental tensors.

For **degenerate scalar broadcast** tensors (all modes are `True`):

- The source tensor is passed to the kernel as a single scalar value instead
  of going through TMA/SMEM.
- Inside `Kernel.epilogue_computation()`, the scalar is dereferenced at index
  0 and broadcast to a full register tensor via `cutlass.cute.full_like()`,
  matching the accumulator's shape and the epilogue data type.

#### Phase 3: PyTorchEvaluation (CPU validation)

`torch_tensor_remap_modes()` uses `torch.as_strided()` to create a view of the
source PyTorch tensor with the same stride rewriting (zeros for broadcast
dimensions), matching the target tensor's shape. This gives identical semantics
to the GPU path, enabling automatic correctness validation.

### Read-Modify-Write with Remapped Tensors

A remapped tensor can be both loaded and stored, enabling read-modify-write on
tensors with different layouts:

```python
# Y is (N, M, L), output is (M, N, L)
remapped_Y = Y.remap_modes[1, 0, 2]
remapped_Y.store(efc_config.accum() + remapped_Y.load())
```

The framework caches remapped tensor proxies by their mangled name, so calling
`.remap_modes[...]` twice with the same arguments returns the same proxy and
correctly accumulates both `is_read=True` and `is_written=True`.

### Tensor Creation for Broadcast

When creating tensors for broadcast epilogues, the source tensors must have
fewer dimensions than the target. Examples from
`broadcast_custom_epilogue_dense_gemm.py`:

```python
# C is (N, L) — will be broadcast along M
c_torch_cpu = create_and_permute_torch_tensor((l, n), ...)   # shape (N, L)
c_tensor, _ = cute_tensor_like(c_torch_cpu, c_dtype, is_dynamic_layout=True)

# x_factor is a 0-d tensor — will be broadcast to all dimensions
x_factor_torch_cpu = torch.tensor(x_factor, dtype=...)        # shape ()
x_factor_tensor, _ = cute_tensor_like(x_factor_torch_cpu, epi_dtype,
                                       is_dynamic_layout=False)  # 0-d: no dynamic layout

# Y is (N, M, L) — transposed relative to D (M, N, L)
# Created with swapped major order so strides differ from D
y_torch_cpu = matrix(l, m, n, cd_major == "n", y_dtype)       # shape (M, N, L)
```

**Note**: 0-d tensors must use `is_dynamic_layout=False` because
`mark_layout_dynamic` would fail on an empty stride tuple.

---

## 9. Reduction

### Motivation

Some epilogue use cases collapse the output tile into a lower-rank
destination: a single scalar (per-tensor amax for FP8 quantisation,
L2 norm, global sum-of-squares for loss tracking), or a vector along
one kept axis (per-column / per-row bias gradients, per-channel
statistics).  Reduction is the categorical dual of broadcast — where
broadcast expands a low-rank source into a tile-shaped view by giving
the missing modes a zero stride, reduction collapses a tile-shaped
expression into a low-rank destination by folding the same modes away.

The remap subscript selects which output modes are folded (`:`) and
which are kept (an integer source-mode index).  Folding *every* mode
(`[:, :, :]`) is the **scalar** case; keeping one within-tile mode
(`[0, :, :]` keeps M, a row reduction; `[:, 0, :]` keeps N, a column
reduction) is the **kept-axis** case.  The two share the API and the
compose-on-top semantic but use different device-side emitters (a
warpgroup fold for the scalar case, an atomic scatter for the
kept-axis case); both are detailed below.

### The `tensor.reduce` API

```python
def epilogue(efc_config, D, sum_sq):
    acc = efc_config.accum()
    D.store(acc)
    sum_sq.remap_modes[:, :, :].reduce(acc * acc, op=efc_config.ADD)
```

The same `remap_modes` subscript syntax used for broadcast describes
which output modes are folded.  An all-`:` subscript marks every
output mode as folded, which corresponds to the scalar-reduction case
(single-element destination).

| Component | Meaning |
|-----------|---------|
| `dest` | A 1-element `cute.Tensor` (rank-0; `is_dynamic_layout=False` is required when wrapping a rank-0 torch tensor) |
| `.remap_modes[:, :, :]` | Marks every output mode as folded away |
| `.reduce(value, op=...)` | Combines the per-tile fold of `value` with the destination's existing content via atomic ops on the destination address |
| `op=efc_config.ADD` | Alias for `cute.ReductionOp.ADD`; the same accessors expose `MUL`, `MAX`, `MIN`.  The actually-implemented subset is gated by `_SUPPORTED_REDUCE_OPS` (unsupported ops like `MUL` raise a clear `ValueError`).  Users can still pass `cute.ReductionOp.ADD` directly if they prefer importing `cutlass.cute` explicitly. |

### Compose on Top of Existing Content

The kernel does **not** zero the destination before accumulating.
Each CTA's atomic adds (or maxes, in future ops) onto whatever
content the buffer already holds.  This is exposed as a feature, not
a workaround for the absence of a workspace-init pass:

- Pre-load the destination with a calibration bias before launch.
- Accumulate across multiple GEMM launches into the same buffer
  (cumulative amax, running sum).
- Skip a separate framework-side init pass when the buffer is
  already known to hold the op's identity (e.g. via a deliberate
  `cudaMemset` to zero / `±inf` / etc.).  CUDA does *not*
  zero-initialise freshly allocated device memory, so an explicit
  fill is still required for a "from zero" run -- the user must
  perform it themselves rather than rely on `cudaMalloc` semantics.

The user owns the initial value.  The PyTorch reference path in
`Tensor.reduce` mirrors the same semantic via
`dest.copy_(dest + value.sum().view_as(dest))` so CPU/GPU comparisons
agree.

### How It Works Internally

#### Phase 1: ParameterAnalysis

When `.remap_modes[...].reduce(...)` is used:

1. The `remap_modes` accessor follows its broadcast path, registering
   a remapped tensor with `mapped_source`, `source_mode_map`, and
   (for the all-`:` subscript) `degenerate_to_scalar=True`.
2. `.reduce(value, op)` stamps `reduce_op=op` and `is_written=True`
   on the remapped tensor's `ParameterAttributes`.
3. The proxy validates that it is a remapped view, that the remap
   is degenerate-to-scalar, that the destination is not also being
   loaded, and that multiple `.reduce(...)` calls on the same
   destination agree on `op`.
4. After analysis completes, `analyze_epilogue_with_arguments` checks
   that the actual source tensor has total element count 1 — so a
   multi-element buffer cannot silently land in the atomic-write
   path.

#### Phase 2: ThreadOperation (GPU kernel) — scalar case

The `ThreadOperation` phase dispatches on `degenerate_to_scalar`:
the scalar (all-`:`) case uses the warpgroup fold described here; the
kept-axis case uses the atomic scatter described in *Kept-Axis
Reduction* below.

A scalar reduce destination is passed to the kernel as a raw pointer
through the same `degenerate_to_scalar` argument-passing path that
the broadcast-source path uses; no TMA descriptor, no staged SMEM
buffer.  The kernel allocates a tiny per-destination SMEM scratch
(one slot per epilogue warp in the epi dtype) in
`Kernel.allocate_smem`, alongside the staged `smem_read` /
`smem_written` pools.

The device-side fold runs once per subtile from inside the user's
epilogue body via the `_emit_warpgroup_reduce` `@cute.jit` helper.
Op-specific pieces are factored into four small plain-Python
helpers (`_op_identity`, `_op_warp_reduce`, `_op_combine`,
`_op_atomic`) that the skeleton consults — these dispatch on `op`
at JIT-compile time, emitting only the chosen branch's IR:

1. `TensorSSA.reduce(op, identity, profile=0)` folds each thread's
   register fragment to a per-thread scalar.  ``identity`` comes
   from `_op_identity` (e.g. `0` for ADD, `-inf` for float MAX,
   `MIN_INT32` for signed-int MAX, etc.).
2. `_op_warp_reduce` folds across the 32 lanes of each warp
   (`cute.arch.warp_reduction_sum` for ADD,
   `cute.arch.warp_reduction_max` for MAX,
   `cute.arch.warp_reduction(op=fmin)` for MIN).
3. Lane 0 of each epi warp writes its per-warp partial to its slot
   in the SMEM scratch.
4. The existing `epilogue_sync_barrier` synchronises the 128 epi
   threads so all four slots are visible before any read.
5. Warp 0 lane 0 reads the four slots, folds them via
   `_op_combine`, and emits a single atomic via `_op_atomic`
   (`atomic_add` for ADD, `atomic_fmax` / `_atomic_fmin` for float
   MAX / MIN, `atomic_max` / `atomic_min` for integer MAX / MIN).

The reduce-scratch SMEM is non-staged (one buffer per destination
for the whole kernel, not per pipeline stage) and is accounted for
in `compute_stages()` alongside `mbar_helpers_bytes` so the AB-stage
budget knows about it.

#### Phase 3: PyTorchEvaluation (CPU validation)

`Tensor.reduce` looks up the original (un-remapped) destination
tensor via `mapped_source`, reduces `value` in PyTorch, and composes
the result onto the destination's current content:

```python
dest.copy_(dest + value.sum().view_as(dest))
```

The destination's pre-evaluation content is folded into the result,
matching the GPU path's atomic-on-top semantic.  For a kept-axis
reduction the reference folds only the folded torch dims
(`value.sum(dim=folded)` / `amax` / `amin`) and reorders the kept
modes into source order before composing — the scalar case is the
degenerate "all dims folded" of the same expression.

### Kept-Axis (Row / Column) Reduction

A reduce subscript that keeps one within-tile output axis —
`[0, :, :]` (keep M, a row reduction) or `[:, 0, :]` (keep N, a column
reduction) — collapses the folded axes into a low-rank vector rather
than a single scalar.  The API and the compose-on-top semantic are
identical to the scalar case; only the device-side emission differs.

```python
def epilogue(efc_config, D, col):
    acc = efc_config.accum()
    D.store(acc)
    # col[n] += sum over m (and any batch l) of acc[m, n, l]
    col.remap_modes[:, 0, :].reduce(acc, op=efc_config.ADD)
```

**Device mechanism (`_emit_axis_reduce`).**  The kept-axis destination
is passed to the kernel as the `remap_modes` zero-stride-on-folded
-axes view (folded output axes get stride 0, the kept axis keeps the
source stride) — a genuine kernel parameter, since a host-region view
cannot cross into the isolated `@cute.kernel` region.  It is
partitioned to the per-thread per-subtile fragment through the *same*
`partition_C` + `partition_D` chain that produces the accumulator
fragment, so the destination fragment is congruent to the value the
user reduces.  Fragment positions are grouped by destination address
and each group is folded in registers before a single atomic-combine
into that address.  Because the folded axes carry stride 0, fragment
elements that differ only in a folded axis resolve to the *same*
address and the hardware atomics fold them — across threads, warps and
CTAs alike — while elements differing in the kept axis resolve to
distinct addresses.  This is the exact dual of the broadcast read (one
source element fanned out into many fragment positions through a
zero-stride view); here many fragment positions atomic-combine into
one destination element.  The direct path needs no SMEM scratch and no
TV-layout inspection — correctness follows from the zero-stride layout
alone — and an optional SMEM-staged path (below) folds the cross-thread
duplicates first when that lowers the global-atomic traffic.

Keeping M or N works for any batch count L: each batch's tiles fold
into the same kept-axis vector through the same address aliasing.

The grouping happens at JIT-trace time: `crd2idx` of a position over
the static destination layout is a compile-time constant, so positions
are bucketed in a plain Python dict over a `range_constexpr` unroll (a
dynamic `range` would instead lower to an `scf.for`, making the offset
— and the dict — dynamic).  How much the register fold saves is set
entirely by the accumulator's TV layout:

- When the folded axis lives in the per-thread *value* dimension, every
  position of a thread shares one address, so the whole fragment
  collapses to a single atomic (measured 32 → 1 per thread for a row
  reduction on a 128×128 tile).
- When the folded axis lives in the *thread* dimension, each position
  is a distinct kept coordinate, so nothing aliases intra-thread and
  the fold is a no-op (32 → 32 for a column reduction on the same
  tile); the duplicates that still need folding live in *other*
  threads.

The register fold is therefore a free win in the first case and never a
regression in the second.  The second case's surviving cross-thread
duplicates are folded by an **SMEM-staged** path (`_emit_axis_reduce_smem`):
a per-CTA SMEM buffer of `kept_extent` slots — a mirror of the
destination's zero-stride view, partitioned through the *same*
`partition_C → flat_divide → partition_D` chain — receives one
*shared*-memory atomic per distinct slot, folding the cross-thread
duplicates within the CTA (cheap, per-SM); a cooperative flush then
emits one *global* atomic per kept coordinate.  Which path runs is a
compile-time, layout-derived choice (`_count_distinct_offsets`): SMEM
staging is used only when the direct scatter's global-atomic count
(`distinct_offsets × epilogue_threads`) would exceed the flush count
(`kept_extent`) — i.e. the folded axis lives in the thread dimension.
Measured on a 128×128 tile: a column reduction drops from **32 to 1**
global atomic per thread (the 32 fold atomics move to shared memory),
while a row reduction keeps the direct scatter (1 global atomic, no SMEM
round-trip).

The fold accumulates **across subtiles** in one per-CTA buffer: the
operation runs `reduce_smem_init` before the subtile loop and
`reduce_smem_flush` after it (`_emit_axis_reduce_smem_init` /
`_fold` / `_flush`), so the per-subtile folds (emitted from
`Tensor.reduce`) atomic-accumulate into the persistent buffer and only
one flush drains it.  This cuts both the global-atomic count and the
warpgroup barriers by `subtile_cnt` versus flushing per subtile (for a
128×128 tile, `subtile_cnt = 4`: the flush's global atomics drop from
`kept_extent × 4` to `kept_extent`, and the three reduce barriers move
out of the subtile loop — none remain between the per-subtile folds,
since the buffer persists and the atomics are associative).  Because the
buffer is per-CTA and the scheduler is persistent, each flush re-bases to
the *current* output tile's kept-axis slice of the destination vector
(`view.iterator + tile_offset`, recovered by slicing the per-CTA
`local_tile` with `mma_tile_coord_mnl`); a CTA that visits several tiles
drains each to its own kept coordinates rather than always to
`[0, kept_extent)`.  A distributed-SMEM (cluster) fold tier — folding
across the CTAs of a cluster before the global flush — is left as future
work.

### Constraints

- `op` must be in `_SUPPORTED_REDUCE_OPS`: `ADD`, `MAX`, `MIN`.
  One `_emit_warpgroup_reduce` `@cute.jit` skeleton handles all
  ops; the per-op pieces are factored into four small Python
  helpers (`_op_identity`, `_op_warp_reduce`, `_op_combine`,
  `_op_atomic`) that dispatch on `op` and `value.dtype` at
  JIT-compile time.  For floats: `-inf` / `+inf` identities,
  `cute.arch.fmax` / `fmin` combiners, `cute.arch.atomic_fmax` for
  MAX and a file-local `_atomic_fmin` (bitcast-trick wrapper
  modelled on `cute.arch.atomic_fmax`, using only the documented
  `cute.arch.atomic_min` / `cute.arch.atomic_max` public wrappers)
  for MIN.  For integers: dtype-specific signed / unsigned
  identities, `cutlass_dsl.max` / `min` combiners, and direct
  `cute.arch.atomic_max` / `atomic_min` atomics (auto-promoted to
  UMAX / UMIN for unsigned types inside `_atomic`).  Float
  destinations are fully covered by the integration test (ADD,
  MAX, MIN); integer destinations are tested for ADD only because
  the DSL's `TensorSSA.reduce` currently lowers MAX / MIN to the
  MLIR `vector.reduction` kinds `maximumf` / `minimumf`, which the
  verifier refuses for integer element types — when the DSL
  dispatches those to `MAXSI` / `MINSI` (and `MAXUI` / `MINUI`)
  for integers, the EFC int branch lights up with no code change.
  `MUL` is not supported: there is no `atomicrmw` encoding for
  float-mul, so it would require an `atomic_cas` retry loop with
  delicate NaN / denormal handling, and has no realistic
  GEMM-epilogue use case.
- The kept axis (the integer entries of the remap subscript) must be
  a within-tile output mode: M (`[0, :, :]`, row) or N (`[:, 0, :]`,
  column), optionally with any number of batches (L).  The all-`:`
  subscript is the scalar case.  Keeping the batch axis L itself
  (`[:, :, 0]`, per-batch reduction) is **not** supported: it yields a
  batch-major destination view (leading mode 2), which the dense-GEMM
  `LayoutEnum.from_tensor` rejects (it classifies only M-major /
  N-major tensors).  Supporting it needs batch-major layout handling
  and is left as future work.
- For the scalar case the source tensor must have total element
  count 1 (checked at compile time); the kept-axis case accepts a
  source whose length matches the kept extent.
- A destination cannot be both read (`.load()`) and reduced into in
  the same epilogue — the cross-CTA atomic would race against any
  reader.  The check is centralised in
  `_ensure_no_reduce_read_conflict` (called from both `Tensor.load`
  and `Tensor.reduce`) so the invariant is order-independent:
  `load` → `reduce` and `reduce` → `load` both raise on the second
  call, regardless of which side appeared first in the epilogue
  function.

---

## 10. Accumulator Splitting (Gated Activations)

### Motivation

A gated linear unit computes `D = up * gate_activation(gate)`, where `up`
and `gate` are two halves of a wider projection.  Producing them with a
single MMA means running the GEMM against a `[gate | up]`-interleaved `B`,
so the two halves land in the *same* accumulator, adjacent along N.  The
epilogue then has to pair elements rather than transform them one by one,
which the rest of the framework's element-wise model does not express.

`accum_split` is the primitive for that pairing.  It is the third member
of the mode calculus alongside broadcast ("Broadcasting and Mode Remapping"), which expands modes
with zero strides, and reduction ("Reduction"), which folds modes away.

### The `accum_split` API

```python
def epilogue(efc_config, D, alpha):
    gate, up = efc_config.accum_split(2)
    D.store(up * efc_config.silu(gate) * alpha)
```

A part may be combined with another part or with a scalar.  It may not be
combined with a tensor read, which spans the output's full N.

`accum_split(num_parts)` returns a `num_parts`-tuple.  Part `i` holds the accumulator
elements whose N index is congruent to `i` modulo `num_parts`, so each part has
`1 / num_parts` of the accumulator's elements and a tensor written from them is
`num_parts` times narrower along N than the accumulator tile.

### Gate Shorthands

A plain gate never looks at the halves separately, so it needs no names for
them:

```python
def epilogue(efc_config, D):
    D.store(efc_config.swiglu())
```

`swiglu`, `geglu` and `reglu` are `gated("silu")`, `gated("gelu")` and
`gated("relu")`; `gated(name)` takes any activation of "Built-in Activation Functions" and
returns `up * activation(gate)` from a two-way split.

Anything that reaches past the plain gate -- a clamp such as gpt-oss's
`swiglu_oai`, or a per-half scale -- needs the halves as values, so it goes
through `accum_split`.

### Why the Split Is Taken on the Fragment

The cut happens on the register fragment, *before* the `.load()` that
produces the value the epilogue body computes on:

```python
# dense_gemm/sm100/_operation.py, per-subtile
epilogue_context.acc_frag = retile_t2r_fragment(tTR_rAcc)
epilogue_context.acc_vec = epilogue_context.acc_frag.load().to(self.epi_dtype)
```

Two reasons:

- `TensorSSA` is a flat vector with a CuTe profile attached and has no
  `__getitem__`, so `acc_vec` cannot be sliced at all.  Splitting a loaded
  value would mean `to_vector()` / shuffle / `from_vector()` surgery.
- Re-viewing the fragment is pure layout algebra and emits no
  instructions.  It only changes which registers the subsequent `.load()`
  reads.

This is also why the split is offered on the accumulator rather than as a
general `split(value, num_parts)` helper: a general form would be free on the
accumulator and costly on any other expression, with nothing at the call
site to distinguish the two.  Since epilogue arithmetic is element-wise,
splitting first and computing afterwards is equivalent anyway.

### Fragment Layout and Constraints

`_accum_split_fragment` re-views the per-thread run of `n` elements as
`(num_parts, n // num_parts)` with stride `(1, num_parts)`, putting
part `i` at `[i, None]`.  That is valid because the epilogue
warps split M, so each lane owns one M row across the subtile's N as a
compact run.

`epi_tile` comes from `compute_epilogue_tile_shape`, which reads the CTA
tile shape, `use_2cta_instrs`, and the C/D layouts and element types --
not any tensor's extent.  It therefore varies with configuration, and the
N mode is hierarchical whenever the epilogue warps split N as well as M
(`tmem_warp_shape_mn = (2, 2)`, which is the 2-CTA M64 case).  Measured,
with MMA tiler (128,256), f32 accumulator and epilogue, row-major D:

| Configuration | `epi_tile` | Per-thread fragment |
|---|---|---|
| 1 CTA, cluster (1,1) | `(128:1, 32:1)` | `((32,1),1,1):((1,0),0,0)` |
| 2 CTA, cluster (2,1), with a C tensor | `(64:1, (16,2):(1,128))` | `((16,1),1,1):((1,0),0,0)` |
| 2 CTA, cluster (2,1), no C tensor | `(64:1, (32,2):(1,128))` | `((32,1),1,1):((1,0),0,0)` |

Every run is compact and even, so `num_parts = 2` is valid for all three.
`check_accum_split_fragment`, called once per kernel by
`accum_split_across_lanes` and again by `_accum_split_fragment`, rejects
anything else at trace time:

- the fragment must coalesce to `n:1`, contiguous and in address order,
  since a strided re-view over a padded, swizzled or permuted fragment
  would address elements that are not the neighbours the interleaving
  means;
- the run length must be a multiple of `num_parts`.

Only adjacent-element interleaving is supported.  A coarser "split the
tile's N in half" would straddle the stride gap of a hierarchical N mode
and not select the columns it appears to.

### The Full-Width Extended View

A tensor written from split parts spans `1 / num_parts` of the output's
N.  `extend_split_n` re-views it at the output's full width by extending
the N mode with a stride-0 sub-mode, fastest first:

```text
narrowed (M, NN, L)              : (sm, sn, sl)
extended (M, (num_parts, NN), L) : (sm, (0, sn), sl)
```

Accumulator column `n` then addresses the narrowed tensor's column
`n // num_parts` -- the `accum_split` correspondence -- so every
computation phrased at the output's full width applies to the extended
view unchanged: `local_tile` with the MMA tiler, `thr_mma.partition_C`
and the work-tile count.  The view supports dual addressing, `(m, n, l)`
at full width or `(m, (part, nn), l)` by part, because the sub-mode
keeps both decompositions in layout space.

The extension is not injective -- `num_parts` columns alias one element
-- so it is removed at the interfaces that cannot encode a stride-0
mode:

| Boundary | Narrow form | How |
|---|---|---|
| SMEM staging and TMA descriptor | `narrow_epi_tile_n(epi_tile, num_parts)`, via `JIT.epi_tile_of` | scales every N extent and stride by `1 / num_parts`, which is exactly `cute.recast_layout(num_parts, 1)` on the N mode |
| the kernel's GMEM tiling | `partition_global_tensor` | slices the sub-mode at 0 right after `thr_mma.partition_C` and regroups the `(MMA, MMA_M, MMA_N, ...)` profile |

The slice sits right after `partition_C` because the tile's N mode is
the flat pair `(num_parts, bN / num_parts)` there, with nothing left to
preserve.  One step later the epilogue-tile division nests the
extension inside every divided N mode (`(2, 16)` for a flat epilogue
tile, `((2, 16), 2)` for a hierarchical one), and coordinate slicing
would flatten the surviving nesting into separate modes, breaking the
`(EPI_TILE_M, EPI_TILE_N)` grouping the TMA partition compares against
SMEM.  From the slice on, the tensor is narrow and the kernel divides it
by the narrow epilogue tile from `JIT.epi_tile_of`, exactly as it
divides the SMEM stage.

`JIT.epi_tile_of(tensor_name, epi_tile)` returns the narrow tiler for
SMEM sizing, the staged layouts and the TMA descriptors; the narrowing
factor it applies is a plain integer settled during `ParameterAnalysis`.

### Store Addressing

The narrowed store has no thread-to-value map of its own.  The
accumulator's tiled copy partitions an `extend_split_n` view of the
SMEM stage, and `cute.filter_zeros` keeps one slot per narrow column:

```text
per-thread partition of the extended SMEM  ((1,(2,16)),1,1):((0,(0,1)),0,0)
filtered                                   ((1,(1,16)),1,1):((0,(0,1)),0,0)
```

The register fragment holds those unique slots.  The part arithmetic
and the store are then ordered by the same map, so element `j` of
`up * silu(gate)` and the address of the thread's `j`-th narrow column
agree by construction -- there is no second map to compare.

### Cross-Lane Pairing

Some tilings give each thread only one part's columns -- at an MMA
tiler M of 64 the fragment's innermost register pair steps along M, and
every N step is even.  `accum_split_across_lanes` decides the placement
once per kernel.  It first checks the register fragment
(`check_accum_split_fragment`), then reads the accumulator's coordinate
fragment and probes the TMEM-to-register copy's thread-to-coordinate
map: threads 1, 2, 4, ... each partition an identity tensor of the
epilogue tile, and since thread 0 sits at the tile origin a probe's
first coordinate is its delta from thread 0.  A CuTe layout is linear in
the digits of its coordinate and the copy's thread count is a power of
two, so those probes determine every thread's coordinate:

* **In thread** (returns `False`): the innermost run steps along N by 1
  with a size a multiple of `num_parts`, and every other N step is a
  multiple of `num_parts`.  The split is a register re-view.
* **Across lanes** (returns `True`): every fragment N step is a multiple
  of `num_parts` -- each thread holds only one part's columns -- and
  each aligned run of `num_parts` lanes (those sharing
  `lane // num_parts`) holds the parts in order: each probed thread `t`
  below `num_parts` sits at `(0, t)`, on the same row `t` columns to the
  right, and every other probed thread's N delta is a multiple of
  `num_parts`; `num_parts` is a power of two no larger than a warp, since
  the exchange shuffles by lane index.  A thread's part is then
  `lane % num_parts` and the lane holding `part` at the same slots is
  `lane - lane % num_parts + part`.  One index shuffle per part and slot
  gathers all the parts; the fetched value is that part by construction,
  with no re-ordering and no blending.  The lanes of a run gather the
  same values, compute the same results, and store them through the
  extended view, whose addresses alias for the whole run -- the
  duplicate writes carry the same bytes.  The parts keep the fragment's
  full width, and so does the store fragment: in this placement
  `filter_zeros` finds nothing to drop, so the sizes agree without a
  mode switch in the store path.

A tiling that fits neither placement, or a copy whose thread count is
not a power of two, is rejected there, once per kernel.

### Identifying the Narrowed Tensors

Which tensors are narrowed cannot be read off their extents: EFC tensors
carry dynamic shapes into the JIT, so comparing a tensor's N against the
output's N is a runtime test, while the tiler it selects is compile-time
structure.

It is instead discovered the same way `is_read` and `is_written` are: by
running the epilogue over dummy values and watching what happens.
`accum_split` returns `SplitPart` marks that propagate through arithmetic
and through the built-in activations (`analysis_result_of` keeps the mark
across any elementwise helper), and `Tensor.store` records the factor off
the stored value, so

```python
gate, up = efc_config.accum_split(2)
D.store(up * efc_config.silu(gate))   # D narrows by 2
Y.store(efc_config.accum())           # Y does not
```

needs nothing declared.  Marks survive the operators an epilogue applies,
including the reflected forms, and the built-in activations return
`analysis_result_of(...)` in that phase, so `silu(gate)` is itself a
`SplitPart` and `up * silu(gate)` combines two marks of the same factor.

A mark can still be lost, by a path that builds a fresh value rather than
operating on a marked one.  `Tensor.store` therefore checks in
`ThreadOperation` that the stored value fills the destination fragment
exactly, where both widths are statically known.

### Phase Behaviour

| Phase | Behaviour |
|-------|-----------|
| `ParameterAnalysis` | Returns `num_parts` `SplitPart` marks and records `EFC.accum_split_factor`.  A store of any expression built from them stamps `accum_split_parts` on that tensor. |
| `ThreadOperation` | Returns the `num_parts` parts of `acc_frag`, each cast to `epi_dtype`: strided views in the in-thread placement, index-shuffle gathers from the lanes of the run otherwise (`Kernel.accum_split_across_lanes`).  Stores check the value against the destination fragment. |
| `PyTorchEvaluation` | Returns `accum_value[:, i::num_parts, :]`.  The reference accumulator is built as `torch.einsum("mkl,nkl->mnl", ...)`, so **the n mode is mode 1, not the last one**. |

### Scope

Verified for a narrowed write alone, beside a full-width write, and with
either of the two carrying the wider element type -- on both a flat and a
hierarchical N mode, at split factors 2 and 4, across several N tiles,
through the TMA store path, including a 2-CTA MMA with a tiler N of 64
and the cross-lane gather at an MMA tiler M of 64.

Not supported: a split coarser than adjacent elements, and a factor the
per-thread run does not divide.  Both are rejected where the fragment is
first known, once per kernel rather than per subtile.

Rejected: a tiling that fits neither placement of `accum_split_across_lanes`
-- a factor that is not a power of two or larger than a warp, or a flat
order that spreads a thread's columns over the parts without
grouping them (an eight-way split at an MMA tiler M of 64: the columns
step by 4 along N).

Rejected: more than one split factor in an epilogue, since the factor
is a single per-kernel attribute.

Rejected where the split provenance is recorded, before any kernel
trace: storing a split part through a direct (non-TMA) transport --
the direct paths drain the T2R-shaped fragment at the accumulator's
full width, so a narrowed store is TMA-only -- and reading a narrowed
tensor, whose register fragment and subtile count come from a
`thr_mma.partition_C` view that re-expands to the accumulator's shape,
so the epilogue load warp would drive more subtiles than the consumer
waits for.

Rejected: reducing a split part onto kept axes, which are partitioned
at the accumulator's width.  The scalar (all-`:`) fold is
width-agnostic and supported.

---

## 11. Built-in Activation Functions

The `EFC.Configuration` class (`_configuration.py`) provides 8 built-in
activation functions, all phase-aware:

| Function | Formula | GPU Implementation | CPU Implementation |
|----------|---------|--------------------|--------------------|
| `identity(x)` | `x` | pass-through | pass-through |
| `relu(x)` | `max(0, x)` | `EFC.maximum(x, full_like(x, 0))` | `torch.nn.functional.relu(x)` |
| `leaky_relu(x, s)` | `max(0,x) + s*min(0,x)` | `maximum + s*minimum` | `torch.nn.functional.leaky_relu(x, s)` |
| `tanh(x)` | `tanh(x)` | `cutlass.cute.tanh(x)` | `torch.tanh(x)` |
| `sigmoid(x)` | `1 / (1 + exp(-x))` | `1 / (1 + cute.exp(-x))` | `torch.sigmoid(x)` |
| `silu(x)` | `x * sigmoid(x)` | `x * self.sigmoid(x)` | `torch.nn.functional.silu(x)` |
| `hardswish(x)` | `x * min(max(x+3,0),6) / 6` | CuTe min/max ops | `torch.nn.functional.hardswish(x)` |
| `gelu(x)` | `0.5x(1 + erf(x / sqrt(2)))` | `cute.math.erf` | `torch.nn.functional.gelu(x)` |

All GPU implementations use `self.full_like(x, value)` to create constant
tensors matching the element type of `x`, ensuring type-consistent computation.

During `ParameterAnalysis`, every activation returns
`analysis_result_of(x)`, a dummy that carries an `accum_split` mark
through the call (see "Identifying the Narrowed Tensors").

---

## 12. Concrete Examples Walkthrough

### 12.1 `custom_epilogue_dense_gemm.py`

**Computation**:
```python
Y = A * B                                    # accumulator copy
D = relu(A*B * alpha + C * beta) + X * x_factor   # fused epilogue
```

**Tensor roles**:
- Read: `C`, `X` (loaded via TMA)
- Written: `D`, `Y` (stored via TMA)
- Scalars: `alpha`, `beta`, `x_factor`

**Epilogue function**:
```python
def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
    Y.store(efc_config.accum())
    result = (
        efc_config.relu(efc_config.accum() * alpha + C.load() * beta)
        + X.load() * x_factor
    )
    D.store(result)
```

**What the framework discovers during `ParameterAnalysis`**:
- `C`: `is_tensor=True, is_read=True`
- `D`: `is_tensor=True, is_written=True`
- `alpha`: `is_tensor=False` (scalar)
- `beta`: `is_tensor=False` (scalar)
- `X`: `is_tensor=True, is_read=True`
- `x_factor`: `is_tensor=False` (scalar)
- `Y`: `is_tensor=True, is_written=True`

The class `DenseGemmAlphaBeta` extends `DenseGemmEFC` with CLI argument parsing
for `--alpha`, `--beta`, `--c_dtype`, `--d_dtype`, `--x_dtype`, `--x_factor`,
`--y_dtype`.

### 12.2 `activation_custom_epilogue_dense_gemm.py`

**Computation** (Ada FP8 GEMM inspired):
```python
Aux = (alpha * scale_a * scale_b) * Acc + (beta * scale_c) * C + bias
D   = activation(Aux)
```

**Dynamic epilogue creation**:
```python
def create_epilogue_function(activation_name: str):
    def epilogue(efc_config, C, Aux, alpha, beta, bias,
                 scale_a, scale_b, scale_c, D, leaky_relu_alpha):
        aux_val = (
            (alpha * scale_a * scale_b) * efc_config.accum()
            + (beta * scale_c) * C.load()
            + bias
        )
        Aux.store(aux_val)
        activation_fn = getattr(efc_config, activation_name)
        if activation_name == "leaky_relu":
            D.store(activation_fn(aux_val, leaky_relu_alpha))
        else:
            D.store(activation_fn(aux_val))
    return epilogue
```

The activation function is selected by name (e.g., `"relu"`, `"gelu"`) and
resolved at runtime via `getattr(efc_config, activation_name)`. This
demonstrates how EFC's phase-aware dispatch enables configurable epilogues.

### 12.3 `broadcast_custom_epilogue_dense_gemm.py`

**Computation** (with broadcasting and mode remapping):
```python
Y = A * B + Y_initial      # read-modify-write via remap_modes (Y is transposed)
D = relu(A*B * alpha + C.broadcast * beta) + X.broadcast * x_factor.broadcast
```

**Tensor roles and shapes** (for output `D` of shape M×N×L):

| Tensor | Shape | Role | Remapping |
|--------|-------|------|-----------|
| `C` | (N, L) | Read | Broadcast along M: `(True, 0, 1)` |
| `D` | (M, N, L) | Write | None (target layout) |
| `X` | (M, L) | Read | Broadcast along N: `(0, True, 1)` |
| `x_factor` | () (0-d) | Read | Scalar broadcast: `(True, True, True)` |
| `Y` | (N, M, L) | Read+Write | Transpose M↔N: `(1, 0, 2)` |
| `alpha`, `beta` | scalar | — | Direct arithmetic |

**Epilogue function**:
```python
def epilogue(efc_config, C, D, alpha, beta, X, x_factor, Y):
    # Read-modify-write Y with transposed layout relative to output
    Y.remap_modes[1, 0, 2].store(efc_config.accum() + Y.remap_modes[1, 0, 2].load())
    # C is (N, L) broadcast along M, X is (M, L) broadcast along N,
    # x_factor is 0-d broadcast to all dimensions of the output
    result = (
        efc_config.relu(
            efc_config.accum() * alpha
            + C.remap_modes[:, 0, 1].load() * beta
        )
        + X.remap_modes[0, :, 1].load()
        * x_factor.remap_modes[:, :, :].load()
    )
    D.store(result)
```

**What the framework discovers during `ParameterAnalysis`**:
- `C`: `is_tensor=True` (not directly read/written — used only via `remap_modes`)
- `D`: `is_tensor=True, is_written=True`
- `alpha`: `is_tensor=False` (scalar)
- `beta`: `is_tensor=False` (scalar)
- `X`: `is_tensor=True` (not directly read/written — used only via `remap_modes`)
- `x_factor`: `is_tensor=True` (not directly read/written — used only via `remap_modes`)
- `Y`: `is_tensor=True` (not directly read/written — used only via `remap_modes`)
- `C__remapped__True__0__1`: `is_tensor=True, is_read=True, mapped_source="C", degenerate_to_scalar=False`
- `X__remapped__0__True__1`: `is_tensor=True, is_read=True, mapped_source="X", degenerate_to_scalar=False`
- `x_factor__remapped__True__True__True`: `is_tensor=True, is_read=True, mapped_source="x_factor", degenerate_to_scalar=True`
- `Y__remapped__1__0__2`: `is_tensor=True, is_read=True, is_written=True, mapped_source="Y", degenerate_to_scalar=False`

The `x_factor` remapping degenerates to a scalar because all modes are `True`,
so the framework passes only a single element to the kernel and broadcasts it
via `cutlass.cute.full_like()` instead of going through TMA/SMEM.

The class `DenseGemmAlphaBetaBroadcast` extends `DenseGemmEFC` with CLI argument
parsing for `--alpha`, `--beta`, `--c_dtype`, `--d_dtype`, `--x_dtype`,
`--x_factor`, `--y_dtype`.

### 12.4 `synthetic_custom_epilogue_dense_gemm.py`

**Computation**: Programmatically generated epilogue with variable numbers of
read/write tensors.

**Key technique**: Uses `create_named_epilogue()` to generate functions with
dynamic parameter names:

```python
def meta_epilogue(read_tensors, written_tensors):
    param_names = (
        ["efc_config", "alpha", "beta"]
        + [f"read_t{i}" for i in range(read_tensors)]
        + [f"written_t{i}" for i in range(written_tensors)]
    )

    def computation_impl(efc_config, alpha, beta, *tensors):
        read = beta
        for tensor in tensors[:read_tensors]:
            read += tensor.load() * alpha
        if read_tensors > 0:
            read = efc_config.where(
                read < 1, read, read * efc_config.full_like(read, 2)
            )
        t = efc_config.accum()
        for tensor in tensors[read_tensors:]:
            t = t * alpha + read + 5000
            tensor.store(t)

    return common_efc.create_named_epilogue(param_names, computation_impl)
```

CLI: `--read_tensors 2 --written_tensors 3` creates an epilogue reading 2
tensors and writing 3. This approach avoids `exec()`/`eval()` while producing
functions that EFC's `inspect.signature()` can introspect.

---

## 13. EFC vs EVT Comparison

### EVT (Epilogue Visitor Tree)

The older approach uses a **DAG intermediate representation** (DAGIR) with typed
nodes:

| Component | File | Purpose |
|-----------|------|---------|
| `DAGIR` | `cutlass/operators/fusion/ir/dag_ir.py` | NetworkX-based directed graph with typed nodes |
| `EFCConverter` | `cutlass/operators/providers/cutedsl/evt/converter.py` | Translates DAGIR to stack-based EFC functions |

**DAGIR node types**: `LoadNode`, `StoreNode`, `ComputeNode` (with operations
like `Multiplies`, `Plus`, `ReLU`, `Sigmoid`, etc.)

**Conversion path**:
```text
User code                           (high-level API)
    |
    v
Python AST Frontend                 (parses user expression)
    |
    v
DAGIR (NetworkX DiGraph)            (intermediate representation)
    |
    v
EVT Pass Manager                    (optimization passes)
    |
    v
EFCConverter.convert()              (DAGIR -> stack-based operations)
    |
    v
EFC epilogue function               (callable with efc_config, params...)
```

The `EFCConverter` traverses nodes in topological order, building a stack of
operations:
- `LoadNode` -> push `tensor.load()` result onto stack
- `ComputeNode` -> pop operands, apply operation, push result
- `StoreNode` -> pop value, call `tensor.store(value)`

### EFC (Direct)

The user writes the epilogue function directly -- no IR, no compilation passes:

```text
User code (Python function)
    |
    v
EFC.analyze_epilogue()              (inspect.signature)
    |
    v
EFC.compile()                       (ParameterAnalysis phase)
    |
    v
Fused into GEMM kernel             (ThreadOperation phase)
```

### When to Use Each

| Criterion | EVT | EFC (Direct) |
|-----------|-----|--------------|
| **Use case** | Programmatic epilogue generation from higher-level specs | Hand-written epilogues |
| **Complexity** | Higher (DAG IR, passes, converter) | Lower (just a Python function) |
| **Flexibility** | Enables automatic optimization passes | User has full control |
| **Debugging** | Harder (indirection through DAG) | Easier (direct Python code) |
| **Code generation** | From expression trees or compiler frontends | Manual or via `create_named_epilogue()` |

---

## 14. Constraints and Limitations

### Tensor Constraints

- **At least one written tensor** is required (`_base.py`):
  ```text
  "The epilogue requires at least one written tensor to do something useful."
  ```
- **All supplemental tensors must match the C/D layout** (row-major or
  column-major). Checked in `EFC.JIT.compute_stage()` (`dense_gemm/sm100/_operation.py`).
- **All read tensors must have the same subtile count**. Checked in
  `EFC.Kernel.prepare_tensor_load_for_subtiles()` (`dense_gemm/_operation.py`).

### Broadcast / Remap Constraints

- The `remap_modes` subscript must have the same length as the **output**
  rank.
- The number of integer entries must not exceed the **source** tensor's
  rank. Some source dimensions may be unused — this allows skipping
  size-1 broadcast dimensions in the source tensor. For example, a
  ``(1, N)`` tensor can use ``remap_modes[:, 1, :]`` to broadcast along
  M and L while skipping the unused size-1 dim 0.
  The remaining entries must be `:` (broadcast).
- 0-d tensors (rank 0) must use `is_dynamic_layout=False` when created, since
  `mark_layout_dynamic` fails on empty stride tuples.
- A degenerate scalar broadcast (all-`:` subscript) is optimized:
  the source tensor is passed as a single scalar to the kernel, bypassing
  TMA/SMEM entirely.
- Read-modify-write on a remapped tensor is supported: calling both `.load()`
  and `.store()` on the same `.remap_modes[...]` result works correctly.
- Remapped tensor proxies are cached by mangled name. Using `.remap_modes[...]`
  multiple times with the same subscript returns the same proxy, preserving
  accumulated `is_read`/`is_written` flags.

### Data Type Constraints

Supported A/B input types:

- `Float16`, `BFloat16`, `TFloat32`
- `Int8`, `Uint8`
- `Float8E4M3FN`, `Float8E5M2`

Accumulator type compatibility:

| Accumulator | Compatible A/B Types |
|-------------|---------------------|
| `Float32` | `Float16`, `BFloat16`, `TFloat32`, `Float8E4M3FN`, `Float8E5M2` |
| `Float16` | `Float16`, `Float8E4M3FN`, `Float8E5M2` |
| `Int32` | `Uint8`, `Int8` |

### MMA Tiler and Cluster Constraints

- MMA tiler M: `64` or `128` (1-CTA), `128` or `256` (2-CTA)
- MMA tiler N: `32` to `256`, step `32`
- Cluster shape M/N: positive, power of 2, product <= 16
- Cluster shape M: must be multiple of 2 when `use_2cta_instrs=True`
- Contiguous dimension must be 16-byte aligned
- Block-scaled operations (section 16) narrow the menu: fp8 A/B with E8M0
  scales, `Float32` accumulator, MMA tiler M = the block-scaled instruction M
  (Rubin Bkeep-Breuse doubles it), tile N in `{64, 128, 192, 256}`

---

## 15. Debugging & Logging

### Environment Variable

Set `CUTE_DSL_EFC_LOG_LEVEL` before launching:

```bash
# Detailed framework logs
CUTE_DSL_EFC_LOG_LEVEL=DEBUG python custom_epilogue_dense_gemm.py ...

# Informational logs only
CUTE_DSL_EFC_LOG_LEVEL=INFO python custom_epilogue_dense_gemm.py ...
```

This configures Python's `logging` module (`_base.py`). Debug output
includes tensor shapes, layouts, and SMEM sizes at every step.

### `@trace_in_mlir` Decorator

(`_base.py`)

Wraps functions with MLIR-level entry/exit markers (only active in DEBUG mode):

```python
@trace_in_mlir
def load_tensors_from_smem_to_register(self, index):
    ...
```

Produces markers like `mark_mlir: entering load_tensors_from_smem_to_register`
and `mark_mlir: leaving load_tensors_from_smem_to_register` in the generated
MLIR assembly.

### `mark_mlir()` Function

(`_base.py`)

Insert arbitrary markers in generated MLIR for debugging:

```python
mark_mlir("about to execute epilogue computation")
```

Only emits `cute.printf` calls when `CUTE_DSL_EFC_LOG_LEVEL=DEBUG`.

---

## 16. Block-Scaled (MX) Operands

`DenseGemmEFCBlockScaled` (`dense_gemm/sm100/_blockscaled.py`) is `DenseGemmEFC`
with the block-scaled `tcgen05` MMA: fp8 A/B are dequantized inside the tensor
core by E8M0 scale factors, one per 32 K elements (MXF8, OCP MXFP8).
`DenseGemmEFCBlockScaledSm107` (`dense_gemm/sm107/_operation.py`) is the Rubin
delta: the K=64 instruction and Bkeep-Breuse, shared with the dense Rubin
operation through `_Sm107K64Mixin`.  The scale factors are mainloop inputs and
the epilogue sees the dequantized accumulator, so everything in sections 2
through 11 applies unchanged.

### Entry Points

`__call__` and `compile` take the SFA and SFB tensors after A and B, in the
atom-reordered buffer order that `create_scale_factor_tensor` produces.  The
`(MN, K, L)`-indexable canonical view (`blockscaled_utils.tile_atom_to_shape_SF`)
is built in-region from A's / B's shape, since its nested layout cannot cross
the dlpack boundary.  `compile` checks each buffer against the canonical
atom-padded element count of its operand (`check_valid_scale_factor_sizes`):
the kernel's TMA reads that whole extent, so a short buffer would otherwise be
read out of bounds silently.

### Data Path

Every scale-factor code path in the shared kernel body sits under
`const_expr(self.has_scale_factors)` and is pruned for the dense operation.

```text
GMEM SFA / SFB  --TMA, on the A/B pipeline stage and barrier-->  SMEM (staged)
SMEM            --tcgen05.cp 4x32x128b, MMA warp, per stage-->  TMEM
MMA: [A_smem, SFA_tmem] x [B_smem, SFB_tmem]  ->  accumulator (TMEM, f32)
```

TMEM per CTA holds the accumulator stages first, then SFA, then SFB (four
32-bit columns per 128-row atom, replicated across the four warp quadrants).
`compute_stages` fits the accumulator stages to the architecture's column
budget next to the scale-factor columns (`_fit_acc_stages_to_tmem`): SM100 at
N=256 and Rubin Bkeep-Breuse at N=192 and N=256 run one stage.

### Tile N and the Shared SFB Window

The scale factors come in fixed atoms of 128 rows (M for SFA, N for SFB) by 4
scales along K.  SFA always covers whole atoms: every legal tiler M (the
instruction M, or twice it under Rubin Bkeep-Breuse) is a multiple of 128, and
each 128-row half of a Bkeep-Breuse tile loads its own SFA atoms.  SFB is
staged in whole atoms too, so tile N=128 and N=256 load their own, while tile
N=64 and N=192 share one atom-aligned window between two neighbouring N tiles:

```text
N=64:   tiles 2j, 2j+1  ->  atom j             (128 rows staged, 64 consumed)
N=192:  tile 2j         ->  atoms [3j, 3j+2)   (256 rows staged, 192 consumed)
        tile 2j+1       ->  atoms [3j+1, 3j+3)
```

The TMA warp picks the window (for N=192 by re-tiling a 128-row-shifted view
of SFB per tile), and the MMA warp offsets the odd tile's SFB TMEM view by 64
rows, two 32-bit columns.  Any other tile N is rejected at trace time.

### Subclass Seams

| Hook | SM100 (`_blockscaled.py`) | Rubin (`sm107/_operation.py`) |
|------|---------------------------|-------------------------------|
| `_create_tiled_mma` | `utils.sm100.make_blockscaled_trivial_tiled_mma` (fp8 instruction K=32) | `utils.sm107...` (K=64, Bkeep-Breuse M-permutation) |
| `_create_tiled_mma_sfb` | CTA-group-ONE tiled MMA with N rounded up to 128 | same, K=64 |
| `issue_k_tile_gemm` | `[data, scale]` operand pairs per K block | keep/reuse halves with per-half A/SFA, one shared B/SFB slice |

---

## Key Source Files Reference

All framework files are under `examples/CuTeDSL/helpers/efc/`
and example files under
`examples/CuTeDSL/cute/blackwell/efc/`.

### Framework files (operation-agnostic)

| File | Role |
|------|------|
| `_helpers.py` | Leaf utility module (no sibling imports): logging (`log`, `if_debug`, `if_info`, `mark_mlir`, `trace_in_mlir`), naming (`create_named_epilogue`, `NEWLINE_AND_TAB`, `TAB`, `ACTIVATION_FUNCTIONS`), element-wise CuTe helpers (`maximum`, `minimum`), and the `accum_split` support (`check_accum_split_fragment`, `accum_split_across_lanes`, `extend_split_n`, `narrow_epi_tile_n`, `SplitPart`, `analysis_result_of`, `split_factor_of`) |
| `_phase.py` | The `Phase` enum (`ParameterAnalysis` / `ThreadOperation` / `PyTorchEvaluation`), exposed on the `EFC` class as `EFC.Phase` via a class-body `ClassVar` alias |
| `_remap.py` | Tensor mode-remapping helpers (CuTe and PyTorch) used by both phases |
| `_tensor.py` | `Tensor` proxy with `.load()` / `.store()` / `.reduce()` / `.remap_modes[...]`, the `_RemapModesAccessor` subscript helper, the `_ensure_no_reduce_read_conflict` invariant called from both `load()` and `reduce()`, and the `_emit_warpgroup_reduce` `@cute.jit` skeleton (plus the four `_op_*` Python helpers it consults for per-op identity / warp-reduce / cross-warp combine / final atomic) that emits the cross-warp fold for scalar reductions, and `_emit_axis_reduce` that emits the per-element atomic scatter for kept-axis (row / column) reductions; exposed as `EFC.Tensor` / `EFC._RemapModesAccessor` via class-body `ClassVar` aliases |
| `_configuration.py` | `Configuration`: phase-specialized epilogue dispatcher, `accum()`, `accum_split()` with its in-thread re-view and cross-lane gather, `gated()` and the `swiglu` / `geglu` / `reglu` shorthands, built-in activation functions, `__getattr__` chameleon dispatch; exposed as `EFC.Configuration` via a class-body `ClassVar` alias |
| `_base.py` | Core framework: `VariadicParameters`, `JIT` / `Kernel` companion base classes, `_OperationProtocol`, the outer `EFC` class. `EFC.Phase` / `EFC.Tensor` / `EFC._RemapModesAccessor` / `EFC.Configuration` / `EFC.JIT` / `EFC.Kernel` are class-body `ClassVar` aliases reachable through normal class-attribute lookup |
| `DESIGN.md` | This document |

### Operation files (dense GEMM)

| File | Role |
|------|------|
| `dense_gemm/_operation.py` | Arch-neutral GEMM-epilogue Kernel base class `_DenseGemmEFCKernelBase` |
| `dense_gemm/sm100/_operation.py` | sm100-specific `DenseGemmEFC` operation class plus `_DenseGemmEFCJIT` and `_DenseGemmEFCKernel` subclasses, warp specialization, TMA, pipelines, persistent tile scheduling |
| `dense_gemm/sm100/_helpers.py` | sm100 copy/partition helpers (TMEM, SMEM-load, GMEM TMA-store) |
| `dense_gemm/sm100/_blockscaled.py` | `DenseGemmEFCBlockScaled`: the block-scaled (MX) operation on the base's scale-factor machinery (section 16) |
| `dense_gemm/sm107/_operation.py` | Rubin `DenseGemmEFCSm107` and `DenseGemmEFCBlockScaledSm107`: K=64 MMA builders, Bkeep-Breuse issue loops, shared `_Sm107K64Mixin` |

### Example files

| File | Role |
|------|------|
| `custom_epilogue_dense_gemm.py` | Example: multi-tensor epilogue with alpha/beta scaling and ReLU activation |
| `broadcast_custom_epilogue_dense_gemm.py` | Example: broadcasting, mode remapping, transposed tensors, 0-d scalar broadcast, and read-modify-write on remapped tensors |
| `scalar_reduction_dense_gemm.py` | Example: scalar reduction via `Tensor.reduce` — accumulates sum-of-squares of the GEMM accumulator into a single-element destination on top of any pre-existing content |
| `activation_custom_epilogue_dense_gemm.py` | Example: Ada FP8-style epilogue with configurable activation functions |
| `synthetic_custom_epilogue_dense_gemm.py` | Example: programmatic epilogue with variable read/write tensor counts |

### EVT-to-EFC bridge (separate subsystem)

| File | Role |
|------|------|
| `cutlass/operators/providers/cutedsl/evt/converter.py` | EVT-to-EFC conversion: `EFCConverter` translating DAGIR to stack-based EFC functions |
| `cutlass/operators/fusion/ir/dag_ir.py` | DAGIR: NetworkX-based epilogue intermediate representation |
