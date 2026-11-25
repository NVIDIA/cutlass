# CuTe DSL Language Semantics

| | |
|---|---|
| **Authors** | All CuTe DSL developers... |
| **Date** | Aug 21, 2026 |
| **Status** | In Progress |

CuTe DSL is a DSL for writing fast GPU kernels, embedded in Python and targeting MLIR.

> **Scope.** This document assumes the **FrontendNext** engine (aka PyIR) is enabled:
>
> ```python
> compiled = cute.compile[cute.FrontendNext](fn, *args)
> ```
>
> FrontendNext enforces the rules in this document with the named diagnostics; the older legacy
> tracer enforces them only partially and may silently execute an **(M)** mutation once at trace
> time instead of diagnosing it.

## Design Philosophy

On the GPU, the only things that matter for performance are computation and control flow —
arithmetic, memory access, branching, and looping. Everything else that a language like Python
offers — object-oriented programming, polymorphic classes, virtual functions, dynamic typing,
exceptions — is non-performant on the GPU and a footgun for performance-critical code.

By design, CuTe DSL does not capture any of these high-level language features in the generated IR;
instead, it treats them as abstraction without regret \[6\], used purely for metaprogramming.
Dynamic typing makes it easy to compose code generators. Python's object system is perfect for
building abstractions over kernel configurations. The full expressiveness of Python is exactly what
you want when constructing a kernel — just not when executing one. CuTe DSL uses all of it at
compile time and discards it before generating IR.

> **CuTe DSL is designed for one purpose: writing fast GPU kernels. It allows using Python as a
> meta-program — abstraction does not leak into the IR.**

**Two phases:**

- **Meta phase (M):** Python. Runs at compile time. Dynamic typing. Full language. Configures and
  generates kernel code. Every Python value is meta by default.
- **Stage phase (S):** IR. Only computation and control flow. Static typing at join points. This is
  what runs at run time — mostly on the GPU; a small host-side part of the staged IR (the setup and
  kernel launches of a `@cute.jit` entry point) runs on the CPU.

The `cutlass.`/`cute.` namespaces are the boundary:

```python
import cutlass
import cutlass.cute as cute
```

As a first approximation, anything that touches these namespaces produces IR (`cutlass.Int32`,
`cute.arch.thread_idx()`, tensor ops), and everything else is Python metaprogramming that runs once
and disappears. Stagedness then propagates on its own: an operator applied to an **(S)** value, or
an `if`/`while` whose condition is an **(S)** value, also produces IR without an explicit namespace
call. Conversely, a few namespace APIs are deliberately meta-only and produce no IR
(`cutlass.const_expr()`, `cutlass.range_constexpr()`, and static layout helpers such as size/shape
queries on static layouts).

**Programming language concepts:**

- **Multi-stage programming (MSP) \[1\] \[2\]:** Python is the meta-language, staging is implicitly
  done in Python. The generated IR is the object language.
- **Partial evaluation \[3\] \[4\]:** All Python computation is evaluated on the CPU at meta-time.
  Only staged computation (the residual program) is emitted as IR — device code, plus the host-side
  launch/setup code of entry points.
- **Phase-driven typing \[5\]:** Python is dynamically typed. The generated IR is statically typed.
  The typing discipline switches based on phase.
- **Phase-based capture:** Staged values originate from the `cutlass.`/`cute.` namespaces. Branches
  (`if`/`while`) are captured when the condition is a staged value; `range()`/`cutlass.range()`
  loops are always captured, regardless of whether their bounds are staged.

**The support rule: all of Python that is zero-cost, and nothing that is not.**

FrontendNext supports every Python construct whose meaning is a fact the tracer knows when it
emits the IR, so that the construct costs nothing at run time: the generated IR is what a
programmer would have written by hand without the abstraction. Object identity, aliasing,
re-pointing a name, classes, containers, closures and helper calls are all supported on exactly
that condition. Where honouring Python's meaning would need run-time machinery the programmer did
not ask for -- a selector to remember which object a name denotes, memory to index objects by a
run-time value, allocation for a container that grows in a loop, code duplication to unroll a
swap -- the construct is **refused with a named diagnostic and a rewrite hint**, never compiled
silently different from Python, and never made "work" by giving it a cheaper semantics than
Python's. The residual program has three kinds of statements about a Python construct: it is
Python-exact and free, or it is refused, or it is a documented bug. A silent divergence from Python
is always a bug.

## Terminology

| Term | Definition |
|---|---|
| **Meta Phase (M)** | Python-phase. Executes at trace time. All Python values are meta by default. |
| **Stage Phase (S)** | IR-phase. Symbolically captured. Emitted for runtime execution. |
| **Captured region** | Body of `@cute.jit` or `@cute.kernel`. Both **(S)** and **(M)** values coexist. |
| **Staged control flow** | `range()`/`cutlass.range()` loops; `if`/`while` on an **(S)** condition. Not executed — captured as `scf.for`/`scf.if`/`scf.while`. |
| **Meta control flow** | `cutlass.range_constexpr()` loops; `if`/`while` on `cutlass.const_expr(...)`; iteration over Python containers. Executes at trace time. |
| **Join point** | Where branches merge or a loop's back edge repeats. Statically typed region. |
| **Slot** | Any assignable location: a bare local variable, an object attribute (`self.x`), or a container element (`d[k]`, `lst[i]`). |

### Diagnostic codes

`UPPER_SNAKE` names like `PHASE_AUTO_PROMOTED_TO_STAGED` are **diagnostic codes**: the identifier
FrontendNext prints in its `error[CODE]:` / `warning[CODE]:` header when it refuses or rescues a
construct. They appear throughout this document so that every rule is tied to the exact diagnostic
enforcing it — you can search compiler output for the code, and the spec stays testable against the
implementation. The prefix is the category: `PHASE_*` (phase rules), `TYPE_*` (type stability),
`SCOPE_*` (scoping), `CONTAINER_*` (container shape/keys), `MEMREF_*` (buffer aliasing), `UNSUP_*`
(unsupported constructs), `LAUNCH_*`/`BOUNDARY_*` (calls and launches). Code names are meant to be
stable identifiers — message wording may be improved over time, the codes are kept.

### Value Categories

Both meta and staged values have subcategories that determine how they behave inside staged control
flow:

**Meta values:**

| Category | Abbrev | Examples | Mutation in staged control flow |
|---|---|---|---|
| **Meta-primitive (Mp)** | Mp | `int`, `float`, `bool` | Auto-promoted to **Sp** (warning `PHASE_AUTO_PROMOTED_TO_STAGED`; see [Meta-to-staged promotion (M2S)](#meta-to-staged-promotion-m2s)). Non-promotable mutations error (`PHASE_MUTATE_PYTHON`). |
| **Meta-object (Mo)** | Mo | classes, containers, `str`, `None` | Same-type rebinds tolerated by default (`CUTE_DSL_TOLERATE_M2M` defaults to True); objects with decomposable staged fields become per-field carries. `str` and `set` rebinds always error. |

A `str` (or `set`) rebind is the canonical non-promotable mutation — there is no staged string type
to promote to, and carrying one per GPU iteration is deliberately unsupported:

```python
name = "hey"                         # (M) meta string
for i in range(N):                   # (S) staged loop
    name += "!"                      # ❌ PHASE_MUTATE_PYTHON — unpromotable; the mutation
                                     #    would run once at trace time, not per iteration
```

**Staged values:**

| Category | Abbrev | Examples | Mutation mechanism |
|---|---|---|---|
| **Staged-primitive (Sp)** | Sp | `cutlass.Int32`, `cutlass.Float32`, `cutlass.Boolean` | `pyir.ref` / `pyir.store` / `pyir.load`. Converted to `scf` iter_args by the compiler. |
| **Staged-extractable (Se)** | Se | `cute.Pointer`, `cutlass.Array` | Explicit iter_args via pytree flatten/unflatten (`__extract_mlir_values__` / `__new_from_mlir_values__`). Cannot round-trip through `Type(ir_value)`. |
| **Staged-opaque (So)** | So | TMA/TensorMap descriptor handles | No staged leaves at all. Read-only inside staged control flow. Cannot be mutated. |

**How the categories interact:**

- **Sp** types have `_pyir_ref_supported = True`. They round-trip cleanly through `Type(ir_value)`.
  The PyIR system tracks their mutations directly. The flag is the distinguishing marker — every
  **Sp** and **Se** type also carries the pytree hooks, and several compound types
  (`cute.TensorSSA`, `cute.Tensor`) set `_pyir_ref_supported = True` and are mutation-tracked like
  **Sp** scalars.
- **Se** types have `__extract_mlir_values__` and `__new_from_mlir_values__`. They carry metadata
  (dtype, shape, address space) that a bare `ir.Value` cannot represent, so they cannot be rebuilt
  by a `Type(ir_value)` round-trip. Rebinding a bare local holding an **Se** value inside staged
  control flow is still supported — the compiler threads the underlying IR value through the region.
- **So** types have neither, and no scalar-carryable leaf. They cannot be decomposed into IR values.
  They are passed by value and are immutable inside staged control flow.
- **Mp** mutations — bare locals, object attributes, dict entries — are auto-promoted to **Sp**
  (bare locals and dict entries warn with `PHASE_AUTO_PROMOTED_TO_STAGED`; in-body object attributes
  thread silently); the promoted binding is rebound, so post-region reads see the carried value.
- **Mo** compound objects with **Sp** or **Se** fields are auto-decomposed into per-field mutations;
  this tolerance is on by default, and `CUTE_DSL_TOLERATE_M2M=False` turns it off to surface the
  rebinds as errors for debugging.

*Note:* `CUTE_DSL_*` names are environment variables.

## Phase Rules

### The Four Rules

Every interaction between **(M)** and **(S)** values is governed by four rules. The rules are the
language contract, enforced by the FrontendNext engine with the diagnostics named below (see the
**Scope** note at the top).

Unless a decorator is shown, every code example in this document is assumed to be inside a
`@cute.jit` or `@cute.kernel` body — the *captured region* where staging happens. Outside a
decorated body everything is plain Python (see [When do you need
`@cute.jit`?](#when-do-you-need-cutejit)).

#### Rule 1: Read freely

You can read any variable **(M)** or **(S)** regardless of phase. **(M)** values become compile-time
constants in the IR.

#### Rule 2: Mutate only stage

Inside staged control flow, only **(S)** variables may be mutated. **(M)** mutation would execute
once at trace time, not per iteration, so it's disallowed. Where the mutated slot can be promoted
(e.g. a bare local holding an `int`), the compiler auto-promotes it to **(S)** and warns; same-type
rebinds of meta objects are tolerated by default (see [Value Categories](#value-categories)); the
rest are errors (`PHASE_MUTATE_PYTHON`).

```python
counter = 0                          # (M) — Python int
acc = cutlass.Int32(0)               # (S) — staged value

for i in range(N):                   # (S) staged loop — N may be (M) or (S); the loop
                                     #    is staged either way (see Control Flow)
    acc += 1                         # (S) mutation — 1 auto-promoted to Int32
    # counter += 1                   # ⚠️ (M) mutation — auto-promoted to (S) with a
    #                                #    warning (unpromoted, it would run once)
```

#### Rule 3: Flow forward only (M -> S, never S -> M)

**(M)** -> **(S)** is allowed (via the `cutlass.`/`cute.` namespaces).
**(S)** -> **(M)** is forbidden. Stage values don't exist at meta-time.

```python
x = 10                               # (M)
y = cutlass.Int32(x)                 # (M) --> (S) via the namespace

python_list = [1, 2, 3]
python_list[y]                       # ❌ (S) --> (M) staged value can't index list
python_list[0] = y                   # ✅ storing an (S) value INTO an (M) container is fine —
                                     #    the index is meta, and the entry becomes a tracked
                                     #    (S) slot (see Dict and list mutation)
```

#### Rule 4: Types are stable at staged join points

Inside staged control flow, variables must keep the same type across branches and loop iterations. A
mismatch is a trace-time error (`TYPE_UNSTABLE_JOIN`). This rule only applies inside staged control
flow; meta control flow has no type restrictions.

```python
x = cutlass.Int32(0)                # (S) x is Int32 — defined before the branch
for i in range(N):                  # (S) staged loop
    if cond:                        # (S) staged if — cond is a staged Boolean
        x = cutlass.Int32(1)        # (S) x stays Int32 — matches the pre-branch type
        # x = cutlass.Float32(2.0)  # ❌ x would be Float32 — TYPE_UNSTABLE_JOIN
```

---

That's it. Everything below is how these four rules apply.

---

## Variable Scoping

CuTe DSL follows **Python's function-level scoping** for meta code. There is no block scope: a
variable first assigned in meta control flow is visible throughout the rest of the function.

Staged control flow is the one exception. A staged region is captured, not executed, so a variable
**first defined inside** a staged `if`/`for`/`while` is local to that region and does not escape it.
Only variables bound **before** the region are threaded through it and remain visible after it.

This applies to both **(M)** and **(S)** variables, including bindings that hold objects — the
object (M2M) carry only threads objects bound *before* the region.

### First definition vs reassignment

The first assignment to a name creates a new variable. This is **not** mutation — it is creation.
Rule 2 (mutate only stage) does not apply to first definitions.

```python
for i in range(N):                      # (S) staged loop
    x = cutlass.Int32(0)                # First definition of x — allowed, local to the loop
    x = x + 1                           # Reassignment — this is mutation (Rule 2 and Rule 4 apply)
```

Reassignment of an **(S)** variable inside staged control flow is governed by Rule 2 and Rule 4.
First definition of a new **(S)** variable inside staged control flow is allowed — but the new
variable is visible only inside that region.

### Variables defined inside staged `if`

If a variable is defined before the `if`, reassigning it in a branch is allowed, and the branches
merge into an `scf.if` result:

```python
x = cutlass.Int32(0)                    # defined before the if
if cond:                                # (S) staged if — cond is a staged Boolean
    x = cutlass.Int32(42)               # reassignment in one branch — allowed
result = x + 1                          # x is Int32(42) if cond was true, Int32(0) otherwise
```

A variable **born inside** a staged `if` does not survive it — even when both branches assign it.
Because staged `if` is captured into IR (not executed), reading such a variable after the `if` is a
trace-time error at the read site (`SCOPE_UNBOUND_NAME_IN_TRACE`):

```python
if cond:                                # (S) staged if
    x = cutlass.Int32(42)               # x is local to the staged if
result = x + 1                          # ❌ trace-time error: x was never given a value on the traced path
```

This is stricter than Python (where the code would raise `NameError` at runtime only when `cond` is
false). The fix is always the same: define the variable before the `if`. The assignment inside a
single branch is itself legal as long as the variable is not read after the `if`.

Object attributes and dict entries follow a different mechanism: their place cells are seeded with a
poison placeholder, and a read on a path that the first-defining branch does not cover is refused at
trace time at that site (`SCOPE_READ_NEVER_SET`). Storing in both branches does not help — the fix
is the same as for locals: initialize the attribute or entry before the `if`.

```python
cfg = Config()                          # attribute cfg.flag not yet set
if cond:                                # (S) staged if — cond is a staged Boolean
    cfg.flag = cutlass.Int32(1)         # first definition of the attribute, in a branch
use(cfg.flag)                           # ❌ SCOPE_READ_NEVER_SET — assigning cfg.flag in the
                                        #    else branch too would not help; set it before the if
```

### Variables defined inside staged `for`

A variable defined before a staged `for` and reassigned inside it is threaded through the loop as a
loop-carried value — an `scf.for` *iter_arg*, MLIR's name for a loop-carried block argument (`last`
below is one) — and retains its final-iteration value after the loop exits:

```python
last = cutlass.Int32(0)                 # defined before the loop
for i in range(N):                      # (S) staged loop
    last = i + 1
result = last + 10                      # last has its final-iteration value
```

A variable first defined inside the loop body is local to the loop; reading it after the loop is the
same trace-time error as above.

At the loop back-edge (a join point), Rule 4 applies: the variable must have the same type on every
iteration.

### Loop induction variable

The loop counter of a staged `for` loop is an **(S)** value available inside the loop body:

```python
for i in range(N):                      # i is (S), available inside the body
    x = i + 1
```

The counter `i` is an SSA block argument in the generated IR — it is not a regular Python variable
with mutable storage. Reassigning `i` inside the body is allowed and follows Python semantics: it
rebinds a per-iteration local for the rest of that iteration and never changes the loop's trip count
or step.

---

## Assignment

```python
x = 10                               # (M) --> (M), fine

y = x + staged_val                   # (M) read + (S) --> (S), fine

x = cutlass.Int32(x)                 # (M) --> (S) via namespace, fine

python_list[staged_index]            # ❌ (S) --> (M) forbidden (Rule 3)
```

Assignment alone does not promote. `x = 42` keeps `x` as **(M)**. Users must use a
`cutlass.Float16/32/...()` constructor to create the first **(S)** value. However, once an **(S)**
value exists, Python literals auto-promote in expressions — see [Type Inference](#type-inference).
There is one exception inside staged control flow: assigning a Python scalar to a variable that
currently holds an **(S)** value lifts the scalar to that variable's staged type *when the kinds
match* — int into an integer-typed variable, float into a float-typed variable (after `x =
cutlass.Int32(5)`, a later `x = 0` in a staged loop keeps `x` an `Int32`). A cross-kind scalar (`x =
0` on a `Float32` variable) is refused (`PHASE_ASSIGN_PYTHON_TO_TRACKED`) — write `x = 0.0`.

## Control Flow

CuTe DSL control flow is **staged by default**: `range` loops are staged — even the builtin, even
with constant bounds — and an `if`/`while` is staged whenever its condition is an **(S)** value.
Meta control flow is opted into explicitly with `cutlass.range_constexpr()` and
`cutlass.const_expr()`.

| Construct | Phase | Captured as |
|---|---|---|
| `for i in range(N):` | **(S)** staged — *even with constant bounds* | `scf.for` |
| `for i in cutlass.range(N):` | **(S)** staged (accepts tuning options: `unroll`, `unroll_full`, `prefetch_stages`, ...) | `scf.for` |
| `for i in cutlass.range_constexpr(N):` | **(M)** meta — runs at trace time, unrolls | nothing |
| `if cond:` where `cond` is **(S)** | **(S)** staged, both branches captured | `scf.if` |
| `if cutlass.const_expr(cond):` | **(M)** meta — one branch executes, the other is never traced | nothing |
| `while cond:` where `cond` is **(S)** | **(S)** staged | `scf.while` |
| `while cond:` where `cond` is **(M)** | **(S)** staged unless written `while cutlass.const_expr(cond):` — Python state the body updates must then be staged (`PHASE_AUTO_PROMOTE_DISABLED` otherwise; see [Functions](#functions) for the decorated-body requirement) | `scf.while` |
| `for x in [a, b]:`, `zip(...)`, `enumerate(...)` | **(M)** meta | nothing |

### Meta control flow — just Python

No restrictions. `if` executes one branch (partial evaluation, the other is never traced). The `for`
runs at meta-time, each iteration may emit IR (meta-time unrolling).

```python
if cutlass.const_expr(python_flag):     # (M) Meta if
    ...

for i in cutlass.range_constexpr(n):    # (M) Meta loop — unrolled at trace time
    ...

a = [1, 2, 3]
b = [1, 2, 3]
for x, y in zip(a, b):                  # (M) Meta loop
    ...
```

`range_constexpr` is not an unrolling *hint* — the loop runs in the Python interpreter at trace
time: every iteration executes, and whatever staged ops the body contains are emitted once per
iteration, so no rolled loop remains in the IR (a pure-meta body emits no IR at all — see [M inside
S (pure)](#m-inside-s-pure)). For a large constant trip count that should stay rolled, write a
staged loop and use its options (`cutlass.range(N, unroll=...)`); the backend then decides how much to
unroll. What the meta loop buys is metaprogramming, not unrolling: the body is ordinary Python, so
under `const_expr` conditions `break`/`continue`/`raise` all work — everything staged control flow
rejects (`UNSUP_EARLY_EXIT`). A `break`/`continue` under a plain `if` in such a loop keeps that `if`
in Python too (it is never staged): a meta predicate follows Python, a **(S)** predicate is refused
(`PHASE_DYNAMIC_TO_STATIC_BOOL`).

To *guarantee* meta evaluation of a condition, wrap it in `cutlass.const_expr()`, which also errors
loudly (`PHASE_REQUIRES_CONSTANT`) if the condition turns out to be **(S)**. Without the marker, the
legacy tracer may capture even a plain Python `bool` condition as a constant `scf.if` and trace
*both* branches — trace-time side effects in the "dead" branch execute.

**Where is `const_expr` needed?** Only inside `@cute.jit`/`@cute.kernel` bodies (code that gets
captured). Outside them everything is plain Python — every branch is already meta and `const_expr`
adds nothing.

### Staged control flow — captured into IR

The `for` captures the loop body. The body is not executed, it is recorded. The `if` captures both
branches. Neither executes at meta-time. Inside staged control flow, **Rule 2** applies. A staged
region runs as a whole: `break`, `continue`, `return`, and `raise` inside staged control flow are
rejected at trace time (`UNSUP_EARLY_EXIT`).

```python
if cond:                            # (S) staged if — cond is a staged Boolean
    ...

while cond:                         # (S) staged while — cond is a staged Boolean
    ...

for i in range(N):                  # (S) staged loop
    ...

for i in cutlass.range(N, unroll=2):    # (S) staged loop with tuning options
    ...
```

*Remember:* a constant-bound `range(4)` still emits an `scf.for` — it does not unroll at trace time.
Write `cutlass.range_constexpr(4)` when you mean a meta loop.

### Assertions

A bare `assert` is a **compile-time** check: it runs while the code is traced, so its condition must
be **(M)**. On a Meta condition it behaves exactly like Python — `AssertionError` with the message,
nothing captured. On an **(S)** condition it is refused (`ASSERT_DYNAMIC_CONDITION`): the tracer
cannot decide a run-time value, and silently skipping the check or quietly turning it into a run-time
one would change the program's meaning. The rule is the same in a `@cute.jit`/`@cute.kernel` body and
in a plain helper called from one. `cutlass.assert_` is the run-time form.

| Construct | Phase | Captured as |
|---|---|---|
| `assert cond, msg` with `cond` **(M)** | **(M)** meta — a Python `assert`, Python parity | nothing |
| `assert cond, msg` with `cond` **(S)** | refused: `ASSERT_DYNAMIC_CONDITION` | — |
| `cutlass.assert_(cond, msg)` | **(S)** staged run-time check, emitted only in debug builds | `cf.assert` |

```python
assert cutlass.const_expr(tile_m % 16 == 0), "tile_m must be a multiple of 16"  # (M) compile-time
cutlass.assert_(problem_size > 0, "problem_size must be positive")              # (S) run-time, debug
```

`cutlass.assert_` is active only with `CUTE_DSL_COMPILER_OPT=debug` (or `debug{runtime-check}`,
`CUTE_DSL_ENABLE_ASSERTIONS=1`) and is erased otherwise; `cutlass.assume_true` is the variant whose
condition also informs the optimizer. How a failed run-time check surfaces (catchable
`RUNTIME_CONSTRAINT_FAILED` only with TVM-FFI, otherwise a process abort; a trap on the device) is
documented on `cutlass.assert_`.

## Mutation

Only **(S)** variables (subject to the **Mp** auto-promotion and **Mo** same-type-rebind tolerance
in [Value Categories](#value-categories)). Object identity is **(M)**, but fields can be **(S)**.
Only **(S)** fields can be mutated.

```python
class Acc:
    def __init__(self):
        self.sum = cutlass.Int32(0)  # (S) field
        self.name = "acc"            # (M) field

acc = Acc()
for i in range(N):                  # (S) staged loop
    acc.sum += 1                    # (S) field mutation — 1 auto-promoted
    # acc.name = "new"              # ❌ (M) mutation in (S) control flow, Rule 2
```

### Meta-to-staged promotion (M2S)

A Python primitive mutated inside staged control flow would run once at trace time (Rule 2). For
bare locals the compiler rescues the pattern by auto-promoting the variable to **(S)**, with a
warning:

```python
count = 0                            # (M) — Python int

for i in range(N):                   # (S) staged loop
    count += 1                       # ⚠️ (M) mutation — auto-promoted to (S) Int32,
                                     #    warning PHASE_AUTO_PROMOTED_TO_STAGED

use(count)                           # reads the promoted (S) value — the binding was rebound
                                     #    to the loop-carried Int32, holding the final loop result
```

- Promotion picks the staged default type: `bool` -> `Boolean`, `int` -> `Int32`/`Int64`, `float` ->
  `Float32`.
- Object-attribute and dict-entry slots auto-promote the same way (attributes thread silently; dict
  entries warn).
- Non-promotable mutations (e.g. on a `str`) are errors (`PHASE_MUTATE_PYTHON`).
- The idiomatic fix is to not need the rescue: write `count = cutlass.Int32(0)` before the loop — no
  warning, and the value is a real loop result readable after the region.

### Object rebinding (M2M)

Rebinding a variable to a **new object of the same type** inside staged control flow is tolerated by
default (`CUTE_DSL_TOLERATE_M2M` defaults to True): the object's fields are decomposed into
per-field carries — each field must be staged, a promotable meta primitive (carried with the
promotion warning), or an unchanged meta value. This is what makes the *advance pattern* work:

```python
class State:
    def __init__(self, idx):
        self.idx = idx               # (S) field — because an (S) value is passed below;
                                     #    State(0) would make it an (M) int field

    @cute.jit
    def advance(self):
        return State(self.idx + 1)   # returns a NEW same-type object

st = State(cutlass.Int32(0))
for i in range(N):                   # (S) staged loop
    st = st.advance()                # ✅ Mo same-type rebind — tolerated: the (S) field
                                     #    threads across iterations as a per-field carry
use(st.idx)                          # holds the final-iteration value
```

Three constraints:

- **The method must be `@cute.jit`-decorated, or the rebind written inline** (`st = State(st.idx +
  1)`). An undecorated method's *read* of `self.idx` is not instrumented — the call boundary replays
  stores, not reads — so it bakes the first-iteration constant and the loop silently produces `idx
  == 1`.
- **The old object must be dead.** If another binding still holds the pre-rebind object, reading a
  field through that stale alias is refused at the read site (`SCOPE_READ_OF_SUPERSEDED_GENERATION`)
  — there is one live carried cell per field; plain Python's two-objects-diverge semantics cannot be
  reproduced.
- **A re-point of a bare local to a pre-existing object is Python's re-point when its identity is
  trace-time static.** Inside a staged loop body, re-pointing a bare local to another object that
  already existed when the body started (`c = b`) makes the name alias that object, exactly as
  plain Python does, when three conditions hold: (1) no run-time `if` arm is open between the
  binding's scope and the statement (a `const_expr` if is not a region); (2) every enclosing staged
  loop provably runs at least once — a constant trip count or `at_least_once=True`; a `while` never
  qualifies; (3) the local is dead on entry of each of those loop bodies: its first occurrence in
  the body is the store, not a read (`c.inc()` or `c.value` before `c = b` is a read), and that
  store is a top-level statement of the body or nested only in staged `for`/`while` loops (not
  under a `const_expr` if or an unrolled loop). The local must not be a parameter of the jit
  function and must not be captured by a nested function, lambda or comprehension. The identity is
  then a trace-time fact, so this costs nothing: no selector is emitted, and a mutation through the
  alias (`c.inc()`, `c.f = v`) is the target's own field store. Only bare locals qualify: an
  attribute target (`self.cur = self.other`) or a container-entry target (`d[k] = d[j]`,
  `lst[0] = lst[1]`) re-pointing to a pre-existing object is refused, because any other holder of
  the owning object can read that place and the compiler cannot prove it dead on entry. Routing
  through a local (`cur = self.other; ...; self.cur = cur`) is NOT a fix; copy the fields or clone.
  When the identity would depend on a run-time fact — which arm ran, whether the loop ran, which
  iteration — the re-point is refused (`SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT`): a re-point
  inside a run-time `if`, under a `while` or a `for` whose bound may be zero, a local read earlier
  in the same body (`cur.advance(); cur = st1`), a swap or rotation (`a, b = b, a`), or a re-point
  to the merged result of a run-time `x if cond else y`. The rewrites: choose before the loop or
  mark the loop `at_least_once=True`; copy values, not objects (`cur.idx = st1.idx`); build the
  replacement in the body (`st = saved.clone()` — the reset-from-snapshot idiom is a body-born
  object, carried per field); swap through fresh clones (`a, b = b.clone(), a.clone()`); select
  values (`a.idx if cond else b.idx`) or select at trace time (`const_expr`). A select between the
  binding's own object and a body-born one (`st = nxt if cond else st`) is the advance pattern and
  is carried per field.
- **A loop-free run-time `if` that re-points a pre-bound name to a pre-existing object is
  refused too.** `cur = a; if flag: cur = b` is refused at the re-point
  (`SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT`, "inside a run-time if"): which object `cur` names
  after the `if` is a run-time fact, so neither reads nor writes through `cur` can follow. Select
  values instead (`x = b.value if flag else a.value`), or choose the object at trace time with
  `const_expr` before the `if`. One shape is joined instead of refused: a select between two
  value-tree objects whose compile-time fields differ (`active = params` /
  `active = params._fallback`) joins by value as the pytree frontend does — the runtime fields
  become `scf.if` results and the binding is rebuilt from the object it held before the `if`, so
  its compile-time fields read as that object's on every path, and neither object is written.
- **An identity that needs memory is refused.** An object chosen by a *staged* index from a
  container of objects (`objs[j]`, `j` an `Int32`) or a container of objects that grows inside a
  staged loop would need a run-time cell holding "which object"; one carried cell per field cannot
  express that, and the container rules refuse it.

```text
   a = Counter(Int32(0)); b = Counter(Int32(0)); c = a
   for i in cutlass.range(10):      # constant trip count; `c` is dead on entry
       c = b                        # re-point: `c` IS `b` from here on (a trace-time fact)
       c.inc()                      # lands in b's own cell -- the loop's ONE carried cell
   # a: 0, b: 10, c: 10 -- one scf.for, one i32 iter_arg, no select
```

```text
   st = State(cutlass.Int32(0))                 w = st  # keeps generation 0
        |                                       |
        v                                       |  (alias bypasses the
   ONE carried cell per (S) field: [.idx]       |   rebind; still holds
   (the cell is the scf.for iter_arg)           |   the gen-0 object)
   +-- staged loop iteration --------------+    |
   |  st = st.advance()  # NEW object      |    |
   |  every iteration; .idx lands in the   |    |
   |  SAME carried cell (gen 0 -> 1)       |    |
   +---------------------------------------+    |
        |                                       v
   st.idx --> live cell, final value: OK        w.idx --> gen 0 via the stale
                                                alias: X refused at the read,
                                          SCOPE_READ_OF_SUPERSEDED_GENERATION
```

*Advance pattern: a NEW object per iteration but ONE carried cell per (S) field — a stale alias to
an old generation refuses at its read.*

The full construction-inside-staged-control-flow picture:

| Constructing objects inside staged control flow | Verdict |
|---|---|
| Construct and use only within that iteration/branch (field reads/writes, helper calls, local rebinds) | ✅ trace-time object — meta fields freely mutable there |
| Advance pattern (rebind a pre-region binding to a new same-class object) — through bare locals, object attributes, or dict entries; fields may come from loop-carried values | ✅ carried per field |
| Read a field through a binding that still holds the pre-rebind object | ❌ `SCOPE_READ_OF_SUPERSEDED_GENERATION` |
| Re-point a BARE LOCAL (not a parameter, not captured by a nested function) to ANOTHER object that already existed at loop entry, inside a staged loop body, when the identity is trace-time static: no run-time `if` open, every enclosing loop provably runs (constant bound or `at_least_once=True`), the local dead on entry of each body with the store at the body's top level or only under staged loops (`c = b; c.inc()`) | ✅ Python identity: the name re-points, zero cost |
| The same re-point when the identity would be a run-time fact: inside a run-time `if`, under a `while` or a `for` that may run zero times, the local read earlier in the body (`cur.advance(); cur = st1`), a swap or rotation (`a, b = b, a`), or the merged result of a run-time `x if cond else y` | ❌ `SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT` |
| Re-point an attribute (`self.cur = self.other`) or a container entry (`d[k] = d[j]`, `lst[0] = lst[1]`) to a pre-existing object inside a staged loop body — another holder of the owner can read that place | ❌ `SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT` (copy the fields or clone) |
| Loop-free run-time `if` re-pointing a pre-bound name to a pre-existing object (`cur = a; if flag: cur = b`) — reads and writes through the name afterwards cannot follow | ❌ `SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT` (select values: `x = b.value if flag else a.value`, or `const_expr` before the `if`) |
| Loop-free run-time `if` selecting between two value-tree objects whose compile-time fields differ (`active = params` / `active = params._fallback`) | ✅ joined by value like the pytree frontend: runtime fields are `scf.if` results, compile-time fields read as the entry object's |
| An identity that needs memory: an object chosen by a staged index from a container (`objs[j]`), a container of objects grown inside a staged loop | ❌ refused by the container rules |
| Read a field through a run-time `x if cond else y` between two objects (`(a if cond else b).idx`) | ✅ the selected value (the result is a merged copy of the two candidates' values) |
| Write a field through such a selection (`(a if cond else b).advance()`) when a candidate is a pre-existing or otherwise observable object | ❌ `OWNER_STAGED_SELECTION_WRITE` — which object receives the write is a run-time fact |
| Write through a selection between two body-born temporaries (`s = mk_a() if cond else mk_b(); s.advance()`) | ✅ the write lands on the merged copy; a later field read of a candidate itself refuses (`OWNER_STAGED_SELECTION_CANDIDATE_READ`) |
| Rebind to a *different* class, or change a non-promotable meta field alongside staged fields | ❌ `PHASE_MUTATE_PYTHON` / `PHASE_META_FIELD_CHANGED_IN_CF` |
| Read a binding first defined inside the region after the region | ❌ `SCOPE_UNBOUND_NAME_IN_TRACE` |

Always refused, regardless of the flag: rebinding a `str` or a bare-local `set`
(`PHASE_MUTATE_PYTHON`); rebuilding a set *field* of an object (`CONTAINER_SET_REBUILT_IN_CF`);
mutating a set with staged values (`UNSUP_META_CONTAINER_MUTATION`). One deliberate exemption:
`set.add(...)` with meta-only values is tolerated (the membership-gated once-per-key idiom).

### Dict and list mutation

A Python dict or list is itself **(M)** — its identity and shape are fixed at trace time — but its
entries holding **(S)** values are tracked places, mutable like object fields:

```python
state = {"acc": cutlass.Float32(0.0), "step": cutlass.Int32(0)}   # (M) dict, (S) values
buf = [cutlass.Int32(0), cutlass.Int32(0)]                        # (M) list, (S) elements

for i in range(N):                   # (S) staged loop
    state["acc"] += 1.0              # ✅ entry mutation — the (S) leg threads across iterations
    state["step"] = i                # ✅ same
    buf[0] = buf[0] + i              # ✅ element mutation — allowed
    # state["new"] = i               # ⚠️ new key — tolerated as a region-local entry;
    #                                     reading it after the loop errors (SCOPE_READ_NEVER_SET)
    # del state["step"]              # ❌ key-set method — refused (CONTAINER_DICT_KEY_SET_MUTATED,
    #                                     same for update/pop/setdefault)
    # buf.append(i)                  # ❌ shape change — a per-iteration append would be
    #                                     silently discarded, so it is refused
    #                                     (UNSUP_META_CONTAINER_MUTATION; a list nested in a
    #                                     tracked dict fires CONTAINER_LIST_SHAPE_MUTATED)
```

The rule of thumb: build the container **before** the staged region and mutate its **elements**
inside it. Structural mutation (`del`, `update`, `pop`, `append`/`remove`/reorder) inside staged
control flow is refused regardless of where the container was created. The one tolerated structural
change is writing a *new dict key*, which becomes a region-local entry unreadable after the region.
Staged values as dict *keys* are a separate refusal — see [(S) values in Python
containers](#s-values-in-python-containers).

Containers do not have to be born inside the compiled function. A container can also enter as a
`cutlass.Constexpr` parameter — it is **(M)**: it specializes the function and keys the JIT cache,
so the key set, the list shape, and the (M) values themselves are baked into that specialization.
Calling again with a structurally different container is not an error — it compiles a new
specialization (see [When do you need `@cute.jit`?](#when-do-you-need-cutejit)).

## Indexing

**(S)** index into **(M)** container (e.g., `python_list[i]` where `i` comes from a staged loop) is
forbidden (Rule 3). **(S)** index into **(S)** container is fine.

```python
python_list = [10, 20, 30]
staged_array = cutlass.Array(...)

for i in range(3):                  # (S) staged loop
    val = staged_array[i]           # (S) index into (S) container
    # val = python_list[i]          # ❌ (S) index into (M) container. 'i' is (S), Rule 3
```

A meta index into a meta container is plain Python and always fine — including inside staged control
flow (that is the `buf[0]` case in [Dict and list mutation](#dict-and-list-mutation)). To *iterate*
a meta container inside staged code, use a meta loop so the index stays **(M)**:

```python
for k in cutlass.range_constexpr(len(python_list)):  # (M) meta loop
    val = python_list[k]                             # ✅ (M) index into (M) container
```

## Functions

All functions execute at trace time. A function that touches **(S)** values has those operations
emitted (inlined) into the caller's IR — the function itself never appears in the generated code.

```python
def meta_helper():
    return 42                        # returns (M)

def staged_helper(x):                # phase of x is decided at the call site
    return x + 1                     # returns (S) when x is (S), as in the call below

for i in range(N):                   # (S) staged loop
    a = meta_helper()               # runs at trace time — a = 42, an (M) constant
    b = staged_helper(i)            # traced once — emits b = i + 1 into the loop body
```

### When do you need `@cute.jit`?

Ordinary Python functions and methods can be called without any decorator — they execute at trace
time and their **(S)** operations inline into the caller. The decorator is needed in three
situations:

**1. Entry points — host code called from plain Python.** With no active trace, a `@cute.jit`
function compiles and executes via the DSL runtime, and repeat calls hit the JIT cache. A
`cute.compile(...)` target is an entry point too, though `cute.compile` bypasses the JIT cache and
recompiles on every call — hold on to the returned handle to reuse the binary. An undecorated
function called from Python is just Python. `cutlass.Constexpr` parameters are **(M)** — they
specialize the function and key the JIT cache; runtime **(S)** parameters don't retrigger
compilation.

```python
@cute.jit
def host(t: cutlass.Int32, a: cutlass.Constexpr):
    ...

host(100, 1)   # ordinary Python calls the DSL — JIT compiles and runs
host(200, 1)   # cache hit — t is a runtime (S) argument, reuses the existing binary
host(100, 2)   # JIT compiles again — the (M) value `a` changed, new specialization
```

**2. Capturing control flow.** Only decorated bodies are preprocessed for staging — so the decorator
decides what `for i in range(...)` *means*:

```python
def bar(n):                              # no decorator — body is plain Python
                                         # (the ❌ lines below assume n is (S), as in the
                                         #  call from `kernel` at the bottom)
    for i in range(4):                   # (M) meta loop: executed by the interpreter, unrolled
        ...
    # for i in range(n):                 # ❌ n is (S) — plain Python range() cannot iterate a staged bound
    # if staged_cond:                    # ❌ falls back to bool() — PHASE_DYNAMIC_TO_STATIC_BOOL

@cute.jit
def foo(n):                              # decorated — body is preprocessed for staging
    for i in range(n):                   # (S) runtime loop: captured as scf.for
        ...
    for i in cutlass.range_constexpr(4): # (M) explicit meta loop: unrolled at trace time
        ...

@cute.kernel
def kernel(n: cutlass.Int32):
    foo(n)                               # call is inlined
    bar(n)                               # call is inlined
```

The same `for i in range(...)` syntax is a **meta** loop in `bar` (`range(4)`) and a **staged** loop
in `foo` (`range(n)`) — the decorator is the unit of staging. Any staged `if`/`while`/`for` requires
the *containing* function to be `@cute.jit` (or `@cute.kernel`); in an undecorated helper, `if
staged_cond:` raises `PHASE_DYNAMIC_TO_STATIC_BOOL` — or worse, silently folds to a trace-time
constant if the value still carries a Python payload. This applies to methods exactly as to
functions.

**3. Split-compiling a device function.** By default `cute.compile` produces a host entry point plus
its GPU kernels. Selecting `DeviceTarget` instead compiles a `@cute.jit` function as a standalone
`__device__` function — its own GPU symbol, for separate compilation and linking; per-function
ABI/register options compose with it:

```python
@cute.jit
def my_func(a: cutlass.Float32, b: cutlass.Float32):
    return a + b

dev_fn = cute.compile[cute.DeviceTarget](my_func, cutlass.Float32, cutlass.Float32)
```

`DeviceTarget` is about the compile artifact, not call semantics: calling `my_func` during an active
trace still inlines it.

**Methods usually do *not* need the `@cute.jit` decorator.** Under FrontendNext, an undecorated
callee's stores on tracked places — its receiver `self`, arguments, closure cells — are observed
automatically at the call site (the call-boundary effect observer diffs the call's effects and
replays them), so plain-Python field mutations thread across iterations without any decorator:

```python
class Stats:
    def __init__(self):
        self.total = 0                   # plain Python int — observed and threaded

    def update(self, x):                 # no decorator needed
        self.total += x                  # store on self is observed at the call boundary

@cute.jit
def fn(n: cutlass.Int32):
    stats = Stats()
    for i in range(n):                   # (S) staged loop
        stats.update(2)
    return stats.total                   # final sum
```

The observer replays *stores*; it does not instrument the callee's *reads* or handle DSL-typed
state. So decorate a method when:

1. its own body contains staged control flow (case 2 applies to methods exactly as to functions);
2. it updates a **DSL-typed** field (e.g. `cutlass.Int32`) of `self` inside a staged loop —
   undecorated, that refuses loudly (`BOUNDARY_META_LOOP_CARRY`, whose message says to add the
   decorator);
3. it *reads* staged state to build its result (see the advance pattern in [Object rebinding
   (M2M)](#object-rebinding-m2m)) — undecorated, the read bakes a trace-time constant and the result
   is silently wrong.

A straight-line helper that only computes on **(S)** values passed as arguments works identically
with or without the decorator — it inlines either way.

## Aliasing

**Aliasing for meta variables:** a Rule 2 violation. The bare local is auto-promoted to **(S)** with
a warning; the legacy tracer performs the same promotion (the variable is threaded as a loop-carried
value) but silently, with no warning.

```python
x = 1                                # (M)
y = 2                                # (M)
for i in range(n):                   # (S)
    x = y                            # ⚠️ (M) mutation in (S) control flow (Rule 2) — auto-promoted with a warning
```

**Staged scalars or immutable values:** value semantics, so `x = y` stores `y`'s current SSA value
into `x` — no aliasing. Only the mutated binding `x` becomes a loop-carried iter_arg; `y` stays
loop-invariant.

```python
# Scalar Types
x = cutlass.Int32(1)                 # (S)
y = cutlass.Int32(2)                 # (S)
for i in range(n):                   # (S)
    x = y                            # allowed

# Immutable Types (e.g. TensorSSA)
x = cute.full((4,), 1.0, cutlass.Float32)      # (S)
y = cute.full((4,), 2.0, cutlass.Float32)      # (S)
for i in range(n):                   # (S)
    x = y                            # allowed
```

**Staged containers, tensors, and pointers (`cutlass.Array`, `cute.Tensor`, `cute.Pointer`):** the
*handle* rebinds like a scalar, but the *memory* is shared. These types are views onto a buffer: `x
= y` makes `x` refer to `y`'s buffer, and an element write through either binding is visible through
the other — Python's reference semantics, preserved.

- **Handle rebind inside staged control flow is supported** when the buffers come from outside the
  region: the handle is threaded as a loop-carried value (an iter_arg / pointer phi), and writes
  through the rebound handle work.
- **What errors out:** rebinding to a buffer **allocated inside** the region while another binding
  still holds the old handle (`MEMREF_INREGION_ALLOC_REBIND`), or a *superseded* handle to
  iteration-private scratch — an alias captured around the rebind, or a stash in a Python container
  — read after its iteration (`MEMREF_STALE_SCRATCH_CONSUMED`). Reading the rebound binding itself
  after the region is allowed for register-memref tensors: the carried phi serves it.
  `cutlass.Array` is stricter — its pointer carries no memory-space fact, so *any*
  in-region-allocation rebind of a pre-region `Array` binding refuses; a region-born `Array` that is
  a first definition (not a rebind) and stays within its iteration is fine.
- **Element writes are never aliasing hazards for the tracer** — `x[0] = v` and `t[i] = v` are
  ordinary staged memory writes, allowed anywhere in staged control flow.

```python
x = cutlass.Array(...)              # (S) container, allocated before the loop
y = cutlass.Array(...)              # (S) container, allocated before the loop
for i in range(N):                  # (S)
    x = y                           # allowed — handle threads as a loop-carried value
    x[0] = cutlass.Int32(99)        # write through the alias — allowed, visible via y

z = cutlass.Array(...)
w = z                               # another binding holds the old handle
for i in range(N):
    z = cutlass.Array(...)          # ❌ rebind to a region-born allocation while w aliases the old handle
```

## Nested Control Flow

Same four rules, recursively:

### (S) inside (S)

Nested IR structure (e.g., staged loop containing staged conditional).

```python
# v, x are (S), defined before the region
for i in range(N):                              # (S) staged loop (captured in IR)
    if use_fast_path:                            # (S) staged if — use_fast_path is (S)
        v += cute.fast_op(x)                     # (S) emitted into the then branch
    else:
        v += cute.slow_op(x)                     # (S) emitted into the else branch
```

### (M) outside (S)

Meta selects whether IR is emitted. Partial evaluation.

```python
# v is (S), x is (M) — defined before the region
for i in cutlass.range_constexpr(10):    # (M) - runs 10 times
    for j in range(N):                   # (S) - staged loop (captured in IR)
        v += cutlass.Int32(x)            # (S)
```

### M inside S (pure)

Meta computes a constant, stage uses it:

```python
# v is (S), defined before the region
for i in range(N):                           # (S)
    x = 0                                    # (M)
    for j in cutlass.range_constexpr(10):    # (M) — all 10 iterations run at trace time
        x += j                               # (M) mutation — allowed, resolves fully at trace time
    v += cutlass.Int32(x)                    # (S) — x=45 embedded as constant
```

Rule 2 targets mutations that would need per-GPU-iteration state. A meta variable born inside the
staged region and mutated only under meta control flow resolves entirely at trace time before any
staged op reads it, so it stays **(M)**.

### M inside S (branching)

```python
use_fast_path = True                 # (M)
# v, x are (S), defined before the region

for i in range(N):                              # (S) — Staged loop
    if cutlass.const_expr(use_fast_path):        # (M) — Evaluated once at trace time, not per iteration
        v += cute.fast_op(x)                     # (S) — Emitted to IR
    else:
        v += cute.slow_op(x)                     # Never traced
```

## Python Classes

The same four rules apply, no special class rules exist.

- The class itself is **(M)**, it's a Python object, created at trace time.
- `self` is **(M)**, always readable, never reassignable inside staged control flow. (Rebinding an
  ordinary variable that holds an object is a different case — same-type rebinds are tolerated by
  default, see **Mo** in [Value Categories](#value-categories).)
- Fields are **(M)** or **(S)** depending on what you assign to them.
- Methods are **(M)** therefore inlined by default — they execute at trace time, same as plain
  functions.
- Inside staged control-flow, only **(S)** fields can be mutated.

```python
class PipelineState:
    def __init__(self, num_stages):
        self.index = cutlass.Int32(0)          # (S) — mutable in staged control flow
        self.num_stages = num_stages           # (M) — Python int, read-only in staged control flow
        self.name = "main_pipe"                # (M) — Python str, read-only in staged control flow

    @cute.jit
    def advance(self):
        self.index += 1                        # (S) Mutation of a DSL-typed field — the method
                                               #    must be @cute.jit-decorated; undecorated it
                                               #    refuses (BOUNDARY_META_LOOP_CARRY, see point 2
                                               #    of "When do you need @cute.jit?")

    def get_stage_count(self):
        return self.num_stages                 # (M) Read

state = PipelineState(4)

for i in range(N):                             # (S) staged loop
    state.advance()                            # inlined (no call in the IR), mutates (S) index
    count = state.get_stage_count()            # (M) method inlined, returns (M) field | count = 4
    # state.name = "other"                     # ❌ (M) mutation in (S) control flow, Rule 2
    # state.num_stages = 8                     # ❌ (M) mutation in (S) control flow, Rule 2
```

Dataclasses (including `frozen=True`) follow the same rules: `__init__`/`__post_init__` re-run per
iteration when the object is constructed inside the staged region, and a frozen state object
advances with `st = dataclasses.replace(st, ...)` — the same per-field carry as a constructor rebind
(see [Object rebinding (M2M)](#object-rebinding-m2m)). Directly assigning a field of a frozen
instance raises Python's own `FrozenInstanceError` at trace time, exactly as in plain Python.

## Type Inference

**(M)** values have no type constraints — they're Python, dynamically typed. **(S)** values have
types determined at construction and propagated through operations:

- **Constructor-driven** — `cutlass.Int32(x)` is `Int32`, `cutlass.Float32(x)` is `Float32`. The
  type comes from which constructor you call. Constructors are needed to **create** the first staged
  value from a pure Python context.
- **Auto-promotion from Python** — when a Python scalar meets an **(S)** value in an expression, the
  scalar is first converted to a fixed default type — `bool` -> `Boolean`, `int` -> `Int32` (or
  `Int64` if it doesn't fit in signed 32 bits), `float` -> `Float32` — and then normal binary
  promotion runs on the pair. The literal does **not** adopt the staged operand's type. (This
  applies to literals in *expressions*; assigning a bare scalar to a variable that already holds an
  **(S)** value instead adopts that variable's staged type when the scalar's kind matches — see
  [Assignment](#assignment).)

```python
a = cutlass.Int32(5)
b = a + 3                           # 3 (Python int) auto-promoted to Int32
c = a & 31                          # 31 auto-promoted to Int32
if a < 32:                          # 32 auto-promoted to Int32
    ...
```

**Implication: do not redundantly wrap Python literals** when the staged operand is already
`Int32`/`Int64`/`Float32`. Once a staged value exists, Python literals auto-promote in any binary
expression. Wrapping them in constructors adds noise and can introduce unintended type casts:

```python
tidx, _, _ = cute.arch.thread_idx()     # (S) — constructor needed here

# ✅ Idiomatic — let auto-promotion work
lane = tidx & 31
val = lane + 100
if tidx < 32:
    out[tidx] = val

# ❌ Verbose — redundant constructors
lane = tidx & cutlass.Int32(31)         # unnecessary
val = lane + cutlass.Int32(100)         # unnecessary
if tidx < cutlass.Int32(32):            # unnecessary
    out[cutlass.Int64(tidx)] = val      # wrong: needless type cast
```

**But wrap literals to stay in narrow types.** Because the literal converts to `Float32`/`Int32`
*before* binary promotion, a sub-32-bit staged operand mixed with a bare literal silently widens:
`f16 + 1.0` is `Float32`, not `Float16` (same for `BFloat16` and the `Float8` family). To stay in
type, wrap: `f16 + cutlass.Float16(1.0)`.

**When constructors *are* needed:**
1. Creating the first staged value: `acc = cutlass.Float32(0.0)`
2. Intentional type conversion: `half = cutlass.Float16(float32_val)`
3. Establishing a type at a join point: `x = cutlass.Int32(0)` before a branch
4. Keeping narrow types narrow: `f16 + cutlass.Float16(1.0)`

- **Binary promotion** — when two **(S)** values of different types meet, the wider type wins:
  - `Int32 + Float32` -> `Float32` (int promotes to float; the float also widens to the integer's
    bitwidth, so `Int64 + Float32` -> `Float64`)
  - `Int16 + Int32` -> `Int32` (narrower promotes to wider)
  - `Boolean + Boolean` -> `Boolean` (computed in `Int32` internally, collapsed back); `Boolean`
    mixed with an integer type -> that integer type
  - `Int32 / Int32` (true division) -> `Float32`
  - Mixed signedness -> follows C-like rules (unsigned wins if wider or equal)
- **No implicit narrowing** — `Float32` does not silently become `Int32`. A narrow-precision float
  meeting a >=16-bit float *widens* implicitly (`Float8E4M3 + Float32` -> `Float32`); only two
  *different* narrow float types (e.g. `Float8E4M3 + Float8E5M2`) require an explicit cast.
- **Comparison results** — `a < b` always produces `Boolean`, regardless of operand types.

This is why type stability at join points matters — there's no unification pass that finds a common
type. If branches produce different types, it's a trace-time error (`TYPE_UNSTABLE_JOIN`). The user
controls types through constructors and the promotion rules are predictable.

### (S) values in Python containers

**(S)** values backed by IR make meaningless dict keys and set elements. Python's `__hash__` and
`__eq__` operate on the IR handle, not the runtime value — two **(S)** values representing the same
number are different IR handles and won't match. Building the container is not itself rejected —
identity semantics silently apply — but the compiler refuses as soon as it must reason about such a
key:

```python
x = staged_val + 0                  # (S) backed by IR
y = staged_val + 0                  # different IR handle, same runtime value
s = {x, y}                          # ⚠️ builds — but holds two elements despite equal values
d = {x: "hello"}                    # ⚠️ builds — keyed by IR handle identity
d[y]                                # ❌ staged key on a tracked dict — trace-time error
d[y] = "world"                      #    (CONTAINER_DICT_KEY_STAGED), read or write
```

Membership tests are the exception: `x in s` / `x not in s` over a set, frozenset, tuple or list with
an **(S)** operand — the left one, or any member — lower to a staged chain of `==` compares (an
order-insensitive OR), in a traced body and in an undecorated helper alike, so they answer by run-time
value: with `b == 2` at run time, `2 in {a, b, c}` and `(a + 1) in {a, b, c}` are both true, and
`2 in {cutlass.Int32(5), cutlass.Int32(2)}` is true although `2` and `cutlass.Int32(2)` are distinct
keys. A dict on the right is a key lookup, not a membership chain: a staged key refuses
(`CONTAINER_DICT_KEY_STAGED`, for `k in d` and `k in d.keys()` alike), and a mapping that is itself
staged -- a Staged operand against a dict view that is not a plain dict's -- refuses with
`UNSUP_IN_OPERATOR`.

Constructor-built constants like `cutlass.Int32(5)` still carry their Python payload at trace time,
so duplicates hash and compare by payload and collapse in sets/dicts (though they remain distinct
from the plain Python `5` as a key) — the identity trap applies once a value is computed from staged
inputs. A dict is *tracked* when the compiler instruments its accesses — every dict touched inside a
`@cute.jit`/`@cute.kernel` body is, and so is one built or used inside an undecorated helper called
from such a body (the helper is instrumented as it traces). A staged key on a tracked dict is
refused at every spelling — `d[k]`, `d[k] = v`, `del d[k]`, `d.get(k)`, `d.pop(k)`,
`d.setdefault(k, v)`, `d.update({k: v})`, `d |= {k: v}`, `k in d`, `k in d.keys()` — and so is a
key whose `__hash__` consumes a staged value (a tuple or object carrying one:
`CONTAINER_DICT_KEY_STAGED_HASH`). A staged index into a tracked Python list — `lst[i]`,
`lst[i] = v`, `del lst[i]`, `lst.pop(i)`, `lst.insert(i, v)` — or a slice with a staged bound, is
refused the same way (`CONTAINER_LIST_INDEX_STAGED`). Two spellings stay outside the wall: a tuple
subscript `d[(k, 0)]`, which both rewriters read as a tensor coordinate (the keyed methods and
`(k, 0) in d` still refuse), and a dict / list *subclass* (`defaultdict`, `OrderedDict`, a user
class), which keeps its own item protocol. Only code that never runs under a trace keeps Python's
identity semantics.

## Function Calls

By default, function calls are **(M)** therefore inlined. The function executes at trace time and
its **(S)** operations emit IR directly into the caller — no function call in the generated code.
This holds for `@cute.jit` callees too: a `@jit` function called during an active trace is inlined;
no `func.call` is emitted between `@jit` functions (the opt-in exception is `cute.instantiate`,
which emits a `@cute.jit` function as a standalone symbol). Whether a `@jit` function is a
compilation entry point or an inline expansion is decided dynamically — with no active trace it
compiles, inside one it inlines.

The only call-like operation in ordinary generated IR is a **kernel launch**: calling a
`@cute.kernel` builds a launcher (nothing is traced yet), and `.launch(grid=..., block=...)` traces
the kernel body into the GPU module and emits the launch op. A launcher that is created but never
launched is an error at the end of the trace (`LAUNCH_NEVER_ISSUED`).

```text
call f(args)
  |
  +- f is @cute.kernel --> builds a launcher (nothing traced yet);
  |    .launch(grid, block) inside a @jit trace puts the body in the
  |    GPU module and emits the launch op -- the ONLY call-like op in
  |    ordinary IR.  Never launched -> X LAUNCH_NEVER_ISSUED;
  |    .launch outside a @jit trace -> X LAUNCH_OUTSIDE_JIT
  +- active trace --> inlined: (S) ops emit into the caller's IR;
  |    no func.call emitted (@cute.jit and plain Python callees alike)
  +- no active trace: f is @cute.jit --> entry point: compile and
       JIT-execute (cached); anything else --> plain Python call
```

*What a call becomes: a launch op for kernels, inline expansion during a trace, a JIT entry point
outside one.*

```python
@cute.kernel
def scale_kernel(t: cute.Tensor, alpha: cutlass.Constexpr):    # alpha is (M)
    tidx, _, _ = cute.arch.thread_idx()                        # (S)
    t[tidx] = t[tidx] * alpha                                  # (S), alpha baked as a constant

@cute.jit
def host(t: cute.Tensor):
    scale_kernel(t, 2.0).launch(grid=(1, 1, 1), block=(128, 1, 1))
```

Annotate meta parameters with `cutlass.Constexpr`; they specialize the kernel and disappear from the
runtime signature.

### Calling Conventions

**`@cute.jit`** — Declares JIT-compiled functions that can be invoked from Python or from other
`@jit`/`@kernel` functions.

**`@cute.kernel`** — Defines GPU kernel functions, compiled as specialized GPU symbols through
dynamic compilation.

| Caller | Callee | Allowed | Compilation/Runtime |
|---|---|---|---|
| Python function | `@jit` | ✅ | DSL runtime (compile + JIT-execute) |
| Python function | `@kernel` | ❌ | Builds a launcher, but `.launch()` outside a `@jit` trace raises `LAUNCH_OUTSIDE_JIT` |
| `@jit` | `@jit` | ✅ | Compile-time call, inlined |
| `@jit` | Python function | ✅ | Compile-time call, inlined |
| `@jit` | `@kernel` | ✅ | Launch op via cuda dialect/gpu — requires `.launch(grid=..., block=...)` |
| `@kernel` | `@jit` | ✅ | Compile-time call, inlined |
| `@kernel` | Python function | ✅ | Compile-time call, inlined |
| `@kernel` | `@kernel` | ❌ | Rejected at compile time (IR verification) |

## Debugging

### (M) Meta Phase debugging

Standard Python debugging works because meta-time is real Python execution.

- `print()`
- `pdb`, `breakpoint()`
- `CUTE_DSL_DRYRUN=True` — trace and generate IR without a GPU
- `CUTE_DSL_PRINT_IR=True` — dump the generated MLIR (`CUTE_DSL_PRINT_IR_AFTER_PASSES=...` for a
  specific pass)

### (S) Stage Phase debugging

Stage-phase runs on the GPU or CPU:

- `cute.printf(...)` — staged print, executes on the device
- `gdb` (for host)
- `cuda-gdb` (for GPU) — compile with `CUTE_DSL_LINEINFO=1` so SASS maps back to Python source lines

## References

1. F. Nielson and H. R. Nielson, *Two-Level Functional Languages*, Cambridge University Press, 1992.
2. W. Taha and T. Sheard, "MetaML and multi-stage programming with explicit annotations,"
   *Theoretical Computer Science*, vol. 248, no. 1-2, pp. 211-242, 2000.
3. N. D. Jones, C. K. Gomard, and P. Sestoft, *Partial Evaluation and Automatic Program Generation*,
   Prentice-Hall, 1993.
4. J. Bradbury et al., "JAX: composable transformations of Python+NumPy programs,"
   <http://github.com/jax-ml/jax>, 2018.
5. R. Davies and F. Pfenning, "A modal analysis of staged computation," *Journal of the ACM*, vol.
   48, no. 3, pp. 555-604, 2001.
6. T. Rompf and M. Odersky, "Lightweight modular staging: a pragmatic approach to runtime code
   generation and compiled DSLs," *GPCE*, pp. 127-136, 2010.
