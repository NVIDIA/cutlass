# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.


"""
PyIR-specific SCF (Structured Control Flow) generator.

This module contains the PyIRScfGenerator class that extends the base ScfGenerator
with PyIR-specific functionality for handling control flow operations with SSA form
maintenance through pyir.ref/store/load operations.
"""

import builtins
import types
from typing import Any, Callable, Dict, List, Optional

from cutlass._mlir import ir
from cutlass._mlir.dialects import scf

from ..base_dsl.common import (
    DSLUserCodeError,
    get_current_env_manager,
    is_auto_m2s_enabled,
)
from ..base_dsl.diagnostics import DiagId
from ..base_dsl.multi_stage_manager import enter_staged_cf, exit_staged_cf
from ..base_dsl.pyir_runtime import (
    CF_ATTR_FIRST_DEF,
    PYIR_REGION_ATTR_WRITES_ATTR,
    PYIR_REGION_FREE_CALLS_ATTR,
    PYIR_REGION_METHOD_CALLS_ATTR,
    _PyirScopeGuard,
    _implements_dynamic_expression,
    _instance_storage_items,
    _is_staged_value,
    _is_untracked_post_region_binding,
    _load_as_dsl,
    _make_slot_key,
    _meta_promote_slot,
    _op_has_enclosing_loop,
    _pyir_auto_load_arg,
    _pyir_boundary_bind_storage,
    _pyir_bump_region_epoch,
    _pyir_region_entry_pop,
    _pyir_region_entry_push,
    _pyir_gather_captured_leaf_holders,
    _pyir_lookup_slot_from_value,
    _pyir_loop_carried_meta_needs_rebind,
    _PYIR_LAST_NOTIN_COMPARE,
    _PYIR_CF_ATTR_FIRST_DEFS,
    _PYIR_FOLD_FIRSTDEF_STACK,
    _PYIR_GATE_ONCE_INIT_SLOTS,
    _slot_first_def_inside_cf,
    _pyir_pop_loop_body_scope,
    _pyir_push_loop_body_scope,
    _pyir_rebind_local_place_cells_post_region,
    _pyir_rebind_carried_leaves_post_loop,
    _pyir_rebind_unstored_scalar_carries_post_loop,
    _pyir_reload_stale_staged_attr_leaves,
    _pyir_repair_captured_escaped_leaves,
    _pyir_repair_region_escaped_leaves,
    _pyir_repair_region_escaped_tuple_leaves,
    _pyir_setattr_raw,
    _pyir_restore_meta_numeric_leaves,
    _pyir_restore_region_meta,
    _pyir_snapshot_meta_numeric_leaves,
    _pyir_snapshot_region_arg,
    _pyir_snapshot_region_meta,
    _pyir_snapshot_registry_meta_slots,
    _pyir_store_back_unstored_slot_carries_sweep,
    _pyir_carry_if_region_mutated_leaves,
    _pyir_carry_loop_body_mutated_leaves,
    _pyir_unwrap_meta_primitive,
    _pyir_verify_opaque_owner_audits,
    _pyir_verify_registry_meta_slots,
    _raw_backing_ir_value,
    _same_ir_value,
    _slot_refs,
    _stage_meta_compound_leaves,
)
from ..base_dsl.pyir_call_boundary import _pyir_boundary_module_is_user
from ..base_dsl.pyir_class_facts import (
    register_class_fact_modules,
    transitive_write_facts,
)
from ..base_dsl.typing import as_numeric
from ..base_dsl.utils.logger import log
from .cutlass_ast_decorators import ScfGenerator

# Sentinel distinguishing "constant-``if`` fold did not fire" from a real folded
# return of ``None`` (a folded arm with no write_args legitimately returns ``None``).
_NO_FOLD = object()

# ``arith.cmpi`` predicate mnemonics the constant folder models.
_CMPI_PREDICATES = frozenset(
    ("eq", "ne", "slt", "sle", "sgt", "sge", "ult", "ule", "ugt", "uge")
)


# Register modules whose holder classes mutate self-fields from jit bodies
# nested in plain methods, which decoration-time intake alone would miss.
register_class_fact_modules(
    "cutlass.cute.experimental",
    "cutlass.pipeline",
    "cutlass.utils",
)


class PyIRScfGenerator(ScfGenerator):
    """
    PyIR-specific SCF generator that handles control flow with SSA form maintenance.

    Extends the base ScfGenerator with functionality to generate PyIR-instrumented
    control flow operations (if/for/while) that use pyir.ref/store/load for state
    management instead of traditional iter_args.

    The PyIR path creates SCF operations with zero iter_args, relying on the
    AST-inserted pyir_assign/pyir_read calls to handle all mutable state through
    pyir.ref/store/load operations. The C++ PYIRToSCFPass later converts these
    into proper SCF operations with iter_args.
    """

    def __init__(self) -> None:
        super().__init__()
        # Publish the per-DSL constructor namespace for the M2S deprecation
        # message; other DSLs never build this generator and keep the default.
        env_manager = get_current_env_manager()
        if env_manager is not None:
            env_manager.dsl_constructor_namespace = "cute"

    def _resolve_declared_base(
        self,
        base: str,
        mix_iter_args: "List[object]",
        mix_iter_arg_names: "List[str]",
    ) -> Any:
        """The object the dotted receiver path *base* names at region entry:
        the root resolves as a loop write arg, else the staged body function's
        closure binding (a read-only captured receiver is a free variable of
        the body function), else its global binding; each further segment
        resolves through declared instance storage only (never getattr, so a
        property getter cannot execute here)."""
        root, _, rest = base.partition(".")
        obj = self._resolve_declared_root(root, mix_iter_args, mix_iter_arg_names)
        for seg in rest.split(".") if rest else ():
            if obj is None:
                return None
            storage = _instance_storage_items(obj)
            if storage is None or seg not in storage:
                return None
            obj = storage[seg]
        return obj

    def _resolve_declared_root(
        self,
        root: str,
        mix_iter_args: "List[object]",
        mix_iter_arg_names: "List[str]",
    ) -> Any:
        """The object the bare name *root* binds at region entry: a loop write
        arg, else the body function's closure cell, else its global binding (a
        free variable never falls through to a same-named global)."""
        try:
            bi = mix_iter_arg_names.index(root)
        except ValueError:
            bi = -1
        if 0 <= bi < len(mix_iter_args):
            return mix_iter_args[bi]
        fn = getattr(self, "region_body_func", None)
        code = getattr(fn, "__code__", None)
        if code is not None:
            free = code.co_freevars
            cells = getattr(fn, "__closure__", None) or ()
            if root in free and len(cells) == len(free):
                try:
                    return cells[free.index(root)].cell_contents
                except ValueError:
                    return None
        fglobals = getattr(fn, "__globals__", None)
        return fglobals.get(root) if fglobals is not None else None

    def scf_execute_dynamic(
        self,
        op_type_name: str,
        mix_iter_args: List[object],
        full_write_args_count: int,
        mix_iter_arg_names: List[str],
        create_op_func: Callable[[List[ir.Value]], ir.Operation],
        region_builders: List[Callable[..., Any]],
        block_term_op_builder: Dict[Callable[..., Any], Callable[..., Any]] = {},
    ) -> Any:
        """
        Override to route PyIR-enabled if/for/while ops to PyIR-specific path.

        IfExp (ternary) always uses the non-PyIR path since it requires result types
        to be hardcoded in create_op_func.
        """
        # PyIR path: for if/for/while ops from the AST preprocessor.
        # IfExp (ternary) always has results and its create_op hardcodes
        # result_types, so it must use the non-pyir path.
        if op_type_name in ("if", "for", "while"):
            return self._scf_execute_pyir(
                op_type_name,
                mix_iter_args,
                mix_iter_arg_names,
                create_op_func,
                region_builders,
                block_term_op_builder,
            )

        # For ifexp or any other op, delegate to base class
        return super().scf_execute_dynamic(
            op_type_name,
            mix_iter_args,
            full_write_args_count,
            mix_iter_arg_names,
            create_op_func,
            region_builders,
            block_term_op_builder,
        )

    @staticmethod
    def _int_from_const_attr(attr: Any) -> Optional[int]:
        """Extract the integer value of an ``arith.constant``'s ``value`` attribute, or
        ``None`` for a non-integer attribute."""
        # The binding exposes no ``isinstance`` on these attr classes; probe by name
        # then construct (guarded, since the wrong class raises): ``i1`` -> BoolAttr.
        tyname = type(attr).__name__
        if tyname == "BoolAttr":
            try:
                return 1 if ir.BoolAttr(attr).value else 0
            except Exception:
                return None
        try:
            return int(ir.IntegerAttr(attr).value)
        except Exception:
            return None

    @staticmethod
    def _integer_value_bit_width(val: "ir.Value") -> Optional[int]:
        """Return the bit width of an integer-typed ``ir.Value``, or ``None`` when the
        type is not a plain ``IntegerType`` (or is unavailable)."""
        try:
            ty = val.type
            if ir.IntegerType.isinstance(ty):
                return ir.IntegerType(ty).width
        except Exception:
            return None
        return None

    @staticmethod
    def _reinterpret_at_value_type(v: int, val: "ir.Value") -> Optional[int]:
        """Signed reinterpretation of *v* at *val*'s own integer width (the
        invariant every fold result maintains); ``i1`` normalizes to 0/1."""
        width = PyIRScfGenerator._integer_value_bit_width(val)
        if width is None:
            return None
        v &= (1 << width) - 1
        if width > 1 and v >= 1 << (width - 1):
            v -= 1 << width
        return v

    @staticmethod
    def _eval_constant_int(val: "ir.Value", _depth: int = 0) -> Optional[int]:
        """Constant-fold an integer ``ir.Value`` defined by a small tree of ``arith`` ops
        over compile-time constants; every result is the signed reinterpretation
        at its own type width (i1 as 0/1); return its int, else None."""
        if _depth > 64:
            return None
        wrap = PyIRScfGenerator._reinterpret_at_value_type
        try:
            owner = val.owner
            op = getattr(owner, "operation", owner)
            if op is None or not hasattr(op, "name"):
                return None
            name = op.name
            if name == "arith.constant":
                c = PyIRScfGenerator._int_from_const_attr(op.attributes["value"])
                return None if c is None else wrap(c, val)
            operands = list(op.operands)

            def ev(i: int) -> Optional[int]:
                return PyIRScfGenerator._eval_constant_int(operands[i], _depth + 1)

            if name == "arith.trunci":
                a = ev(0)
                return None if a is None else wrap(a, val)
            if name == "arith.extsi":
                # Sign-extension preserves the signed value (the invariant).
                return ev(0)
            if name == "arith.extui":
                # Zero-extension takes the operand's UNSIGNED reinterpretation.
                a = ev(0)
                if a is None:
                    return None
                opw = PyIRScfGenerator._integer_value_bit_width(operands[0])
                return None if opw is None else a & ((1 << opw) - 1)
            if name == "arith.andi":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a & b, val)
            if name == "arith.ori":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a | b, val)
            if name == "arith.xori":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a ^ b, val)
            if name == "arith.addi":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a + b, val)
            if name == "arith.subi":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a - b, val)
            if name == "arith.muli":
                a, b = ev(0), ev(1)
                return None if a is None or b is None else wrap(a * b, val)
            if name == "arith.cmpi":
                a, b = ev(0), ev(1)
                if a is None or b is None:
                    return None
                # Recover the comparison predicate mnemonic.
                pstr = str(op.attributes["predicate"]).strip().rstrip(">")
                mnem = pstr.split()[-1] if pstr else ""
                # Conservative decline: an unrecognized mnemonic leaves the
                # ``if`` as runtime control flow.
                if mnem not in _CMPI_PREDICATES:
                    return None
                # Unsigned predicates compare the operands' UNSIGNED
                # interpretation (a recovered int can be negative).
                ua, ub = a, b
                if mnem in ("ult", "ule", "ugt", "uge"):
                    width = PyIRScfGenerator._integer_value_bit_width(operands[0])
                    if width is not None:
                        mask = (1 << width) - 1
                        ua, ub = a & mask, b & mask
                table = {
                    "eq": a == b,
                    "ne": a != b,
                    "slt": a < b,
                    "sle": a <= b,
                    "sgt": a > b,
                    "sge": a >= b,
                    "ult": ua < ub,
                    "ule": ua <= ub,
                    "ugt": ua > ub,
                    "uge": ua >= ub,
                }
                if mnem not in table:
                    return None
                return 1 if table[mnem] else 0
            if name == "arith.select":
                c = ev(0)
                if c is None:
                    return None
                return ev(1) if c else ev(2)
            return None
        except Exception:
            return None

    @staticmethod
    def _constant_i1_value(cond: "ir.Value") -> Optional[bool]:
        """Return the Python bool of a statically-decidable ``i1`` *cond*, or ``None``
        when *cond* is not a compile-time constant."""
        v = PyIRScfGenerator._eval_constant_int(cond)
        return None if v is None else bool(v)

    def _maybe_fold_constant_if(
        self,
        op_type_name: str,
        op: "ir.Operation",
        region_builders: List[Callable[..., Any]],
        mix_iter_args: List[object],
    ) -> Any:
        """Fold a constant-condition ``scf.if`` to in-line execution."""
        if op_type_name != "if":
            return _NO_FOLD
        op_view = getattr(op, "operation", op)
        try:
            if len(op_view.operands) == 0:
                return _NO_FOLD
            cond = op_view.operands[0]
        except Exception:
            return _NO_FOLD
        const = self._constant_i1_value(cond)
        if const is None:
            return _NO_FOLD
        # Gate-once evidence (see pyir_state): the compare choke's one-slot
        # register describes THIS fold's predicate when it was a single compare.
        _gate_cand = _PYIR_LAST_NOTIN_COMPARE[0]
        _PYIR_LAST_NOTIN_COMPARE[0] = None
        if _gate_cand is not None and _gate_cand[2] is not bool(const):
            _gate_cand = None  # register predates this fold's predicate

        # then == region_builders[0]; else (if present) == region_builders[1].
        live_builder = None
        if const and len(region_builders) >= 1:
            live_builder = region_builders[0]
        elif (not const) and len(region_builders) >= 2:
            live_builder = region_builders[1]

        # Erase the empty scf.if shell BEFORE tracing the live arm so the arm
        # body is emitted at the outer scope (not after a dangling op).
        try:
            op_view.erase()
        except Exception:
            return _NO_FOLD

        log().info(
            "[pyir] constant-if folded (cond=%s); running %s arm in-line",
            const,
            "then" if const else "else",
        )

        if live_builder is None:
            # Constant-false ``if`` with no ``else``: nothing executes.
            if not mix_iter_args:
                return
            if len(mix_iter_args) == 1:
                return mix_iter_args[0]
            return mix_iter_args

        # Trace the live arm in place: ``pytree_def=None`` selects the PyIR builder
        # branch (shared objects), and the op handle is ``None`` (shell was erased).
        _collect_gate_once = bool(const) and _gate_cand is not None
        if _collect_gate_once:
            _PYIR_FOLD_FIRSTDEF_STACK.append([])
        try:
            region_result = live_builder(None, [], [], None, mix_iter_args, 0)
        finally:
            if _collect_gate_once:
                _fold_firstdefs = _PYIR_FOLD_FIRSTDEF_STACK.pop()
                try:
                    _gset, _gkey, _ = _gate_cand
                    if _gkey in _gset:  # the arm latched the gate
                        for _fd in _fold_firstdefs:
                            if (
                                isinstance(_fd, tuple)
                                and len(_fd) == 2
                                and _fd[0] == CF_ATTR_FIRST_DEF
                            ):
                                # Latched gate = once-per-key init: discharge
                                # the read-before-set record.
                                _PYIR_CF_ATTR_FIRST_DEFS.pop(_fd[1], None)
                                continue
                            _slot_first_def_inside_cf[_fd] = False
                            _PYIR_GATE_ONCE_INIT_SLOTS.add(_fd)
                except Exception:
                    pass
        if region_result is not None:
            result_list = (
                region_result
                if isinstance(region_result, (list, tuple))
                else [region_result]
            )
            for idx, val in enumerate(result_list):
                if idx < len(mix_iter_args) and val is not None:
                    mix_iter_args[idx] = val

        if not mix_iter_args:
            return
        if len(mix_iter_args) == 1:
            return mix_iter_args[0]
        return mix_iter_args

    def _scf_execute_pyir(
        self,
        op_type_name: str,
        mix_iter_args: List[object],
        mix_iter_arg_names: List[str],
        create_op_func: Callable[..., ir.Operation],
        region_builders: List[Callable[..., Any]],
        block_term_op_builder: Dict[Callable[..., Any], Callable[..., Any]],
    ) -> Any:
        """Pure PyIR path: zero iter_args, pyir.ref/store/load handles all state.

        AST-inserted ``pyir_assign`` / ``pyir_read`` calls create
        ``pyir.ref`` / ``pyir.store`` / ``pyir.load`` ops. The C++
        ``PYIRToSCFPass`` converts these into ``scf.for`` / ``scf.if`` /
        ``scf.while`` with proper ``iter_args``.
        """
        log().info(
            "[pyir] === _scf_execute_pyir: %s, %d mix_iter_args ===",
            op_type_name,
            len(mix_iter_args),
        )

        # Create SCF op with zero iter_args — pyir refs handle all state
        op = create_op_func([])
        # Meta-advance witness for LOOP bodies: snapshot the registered holders'
        # meta attrs so the close can refuse an un-instrumented advance.
        _meta_slot_snapshot = (
            _pyir_snapshot_registry_meta_slots()
            if op_type_name in ("for", "while")
            else None
        )
        log().debug("Generated scf.%s (pyir) \n[%s]", op_type_name, op)

        # Constant-condition ``if`` is META CF: run the single reachable arm IN-LINE and
        # erase the shell, else a staged ``scf.if %true`` traps a leaf mutation (miscompile).
        folded = self._maybe_fold_constant_if(
            op_type_name, op, region_builders, mix_iter_args
        )
        if folded is not _NO_FOLD:
            return folded

        # For multi-region ops (scf.if), save originals so the else-block
        # doesn't see MLIR values from inside the then-block's region.
        is_multi_region = op_type_name == "if" and len(region_builders) > 1
        original_mix_iter_args: Optional[List[object]] = (
            list(mix_iter_args) if is_multi_region else None
        )

        # Snapshot each iter_arg's value-tree leaves at the OUTER IP; bodies run on
        # shared objects, so the post-region repair reverts any region-trapped escapee.
        leaf_snapshots: List[Optional[List["ir.Value"]]] = [
            _pyir_snapshot_region_arg(arg) for arg in mix_iter_args
        ]

        # Snapshot each iter_arg's meta-scalar leaves at the OUTER scope so
        # ``_pyir_restore_region_meta`` reverts an in-place meta mutation that escapes.
        meta_snapshots: List[Optional[List[tuple]]] = [
            _pyir_snapshot_region_meta(arg) for arg in mix_iter_args
        ]

        # Also snapshot value-tree leaves of CAPTURED read-only objects (not in
        # ``mix_iter_args``); a shared sub-object leaf mutation else traps an SSA a sibling reads.
        captured_leaf_ids = {id(arg) for arg in mix_iter_args}
        captured_leaf_snapshot: Optional[List[tuple]] = (
            _pyir_gather_captured_leaf_holders(exclude_ids=captured_leaf_ids)
        )

        # Gate the Numeric-leaf region-escape revert to ``if`` only: in a loop a Numeric
        # leaf is a genuine carried iter_arg, so reverting it would drop the carry.
        allow_numeric_revert = op_type_name == "if"

        # Snapshot WRITE-ONLY literal-origin Numeric (uncarried counter) leaves so each
        # sibling re-bakes its own constant; ``if`` only (a loop legitimately carries it).
        meta_numeric_snapshots: List[Optional[List[tuple]]] = (
            [_pyir_snapshot_meta_numeric_leaves(arg) for arg in mix_iter_args]
            if allow_numeric_revert
            else [None] * len(mix_iter_args)
        )

        # For/while: carry an in-place-mutated raw leaf through a ``pyir.ref`` so it lifts
        # to an iter_arg (``while`` opaque-only, to not double-carry M2S scalar state).
        carries_loop_leaves = op_type_name in ("for", "while")
        loop_leaf_opaque_only = op_type_name == "while"
        loop_leaf_records: List[tuple] = []
        # An un-instrumented self-attr scalar mutation (``self.attr += step`` inside a
        # plain, non-jit method): stored back into the existing slot ref the body loads
        unstored_scalar_carry_records: List[tuple] = []

        # Region index of the loop BODY (for: 0; while after/body: 1; non-loop: -1).
        # Bounds the per-iteration-reset recording scope to the body only.
        loop_body_region_index = (
            0 if op_type_name == "for" else (1 if op_type_name == "while" else -1)
        )

        # Region-entry ledger adoption from the body's DECLARED write facts:
        # direct ``(base, attr)`` assign pairs, plus ``(base, method)`` call
        # pairs completed into receiver-attr writes through the callee's
        # class facts (a method-call mutation is syntactically invisible to
        # the direct-assign collector).
        declared_attr_write_records: List[tuple] = []
        # Unpromoted-write audit rows (holder, attr, entry value, label):
        # recorded at region entry, checked at region close.  Covers nested
        # direct writes, while-body direct writes, and jit-callee receiver
        # writes the call boundary never pre-stages (default mode only).
        deep_attr_write_audits: List[tuple] = []
        if op_type_name in ("for", "while"):

            def _adopt_declared_attr_write(
                _holder: Any,
                _attr: str,
                _plain_meta_only: bool = False,
                _stage_compound_only: bool = False,
            ) -> None:
                """Get-or-mint the ledger cell for ``(holder, attr)`` at the
                OUTER IP so the body's stores carry it as a loop carry."""
                # A value-protocol holder carries its state through its own
                # extract/reconstruct pair: the callee-fact call sites must
                # not stage (and so clone) its fields behind that protocol.
                if _stage_compound_only and _implements_dynamic_expression(
                    _holder
                ):
                    return
                # The declared pair names a ledger place only when it is an
                # INSTANCE-STORAGE slot of the holder.
                _storage = _instance_storage_items(_holder)
                if _storage is None or _attr not in _storage:
                    return
                _cur = _storage[_attr]
                # Method-completed pairs mutate in UN-CHOKED code, so nothing
                # stores into a cell minted over an already-STAGED value (the
                # staged value's own carry machinery owns it); a direct-assign
                # pair stores back through the assign choke, which serves
                # both cells, so staged current values stay admitted there.
                if _plain_meta_only and _is_staged_value(_cur):
                    return
                _py = _pyir_unwrap_meta_primitive(_cur)
                if _py is None or type(_py) not in (bool, int, float):
                    # Compound field (tuple/list/dict/object): stage each leaf
                    # so the per-leaf carry can thread the body's rebuild.
                    # AUTO_M2S only; the default mode refuses in pyir_assign.
                    # Not for the non-user callee domain: its writes reach no
                    # choke and no boundary replay, so staged leaves would
                    # never see the rebuild.
                    if not _plain_meta_only and is_auto_m2s_enabled():
                        _staged = _stage_meta_compound_leaves(_cur)
                        if _staged is not None:
                            _pyir_boundary_bind_storage(_holder, _attr, _staged)
                    return
                if _stage_compound_only:
                    return  # scalar: this call site never mints scalar cells
                try:
                    _place = _make_slot_key(None, _holder, _attr)
                except Exception:
                    _place = None
                if _place is None or _slot_refs.get(_place) is not None:
                    return  # get-or-mint anti-twin: an existing cell stands
                _ref = _meta_promote_slot(
                    _place,
                    _py,
                    promoted_value=_cur if _cur is not _py else None,
                    display_name=f"{type(_holder).__name__}.{_attr}",
                )
                if _ref is None:
                    return
                declared_attr_write_records.append((_holder, _attr, _ref, _place))

            _audit_seen: "set[tuple[int, str]]" = set()

            def _arm_unpromoted_write_audit(
                _holder: Any, _attr: str, _label: str
            ) -> None:
                """Record (holder, attr, entry value, label) for the close-time
                unpromoted-write audit; plain meta primitive leaves only (a
                staged leaf's own carry machinery owns it)."""
                if _holder is None:
                    return
                _key = (id(_holder), _attr)
                if _key in _audit_seen:
                    return
                _storage = _instance_storage_items(_holder)
                if _storage is None or _attr not in _storage:
                    return
                _cur = _storage[_attr]
                if _is_staged_value(_cur):
                    return
                _py = _pyir_unwrap_meta_primitive(_cur)
                if _py is None or type(_py) not in (bool, int, float):
                    return
                _audit_seen.add(_key)
                deep_attr_write_audits.append((_holder, _attr, _py, _label))

            def _callee_write_attrs(_callee: Any) -> "frozenset[str]":
                try:
                    _writes, _ = transitive_write_facts(_callee)
                except Exception:
                    return frozenset()
                return _writes

            facts = getattr(self, "region_attr_writes", None) or ()
            for _base, _attr in facts:
                if "." in _base or op_type_name == "while":
                    # Nested direct write (`c.sub.n = ...`), or any direct
                    # write in a while body (which has no adoption path):
                    # record the entry value and re-check it at region close;
                    # refusing here would break a leaf a staged consumption
                    # promotes mid-body, which is carried fine.  Under
                    # AUTO_M2S the read-side promotion rescues the shape.
                    if is_auto_m2s_enabled():
                        if "." not in _base:
                            # A COMPOUND field rebuilt in a while body has no
                            # read-side rescue: stage its leaves so the choke
                            # decomposition carries the rebuild, as in for.
                            _holder = self._resolve_declared_base(
                                _base, mix_iter_args, mix_iter_arg_names
                            )
                            if _holder is not None and not isinstance(
                                _holder, (bool, int, float, str)
                            ):
                                _adopt_declared_attr_write(
                                    _holder, _attr, _stage_compound_only=True
                                )
                        continue
                    _holder = self._resolve_declared_base(
                        _base, mix_iter_args, mix_iter_arg_names
                    )
                    _arm_unpromoted_write_audit(_holder, _attr, f"{_base}.{_attr}")
                    continue
                try:
                    _bi = mix_iter_arg_names.index(_base)
                except ValueError:
                    continue
                if _bi >= len(mix_iter_args):
                    continue
                _holder = mix_iter_args[_bi]
                if _holder is None or isinstance(_holder, (bool, int, float, str)):
                    continue
                _adopt_declared_attr_write(_holder, _attr)

            method_facts = getattr(self, "region_method_calls", None) or ()
            for _base, _method in method_facts:
                _holder = self._resolve_declared_base(
                    _base, mix_iter_args, mix_iter_arg_names
                )
                if _holder is None or isinstance(
                    _holder,
                    (bool, int, float, str, bytes, type, types.ModuleType),
                ):
                    continue
                # Resolve the named def through the class MRO -- no instance
                # getattr, so a property getter cannot execute here; a
                # staticmethod/classmethod first parameter is not the receiver.
                _target = None
                for _klass in type(_holder).__mro__:
                    _cand = _klass.__dict__.get(_method)
                    if _cand is not None:
                        _target = _cand
                        break
                if _target is None or isinstance(
                    _target, (staticmethod, classmethod, property)
                ):
                    continue
                _target = getattr(_target, "__func__", _target)
                if not callable(_target) or not hasattr(_target, "__code__"):
                    continue
                # USER-module defs are rewritten by the preprocessor, so their
                # receiver writes reach the chokes directly; the declared
                # completion imports write knowledge only for defs the
                # rewrite never sees (the boundary's non-user callee domain).
                if _pyir_boundary_module_is_user(getattr(_target, "__module__", None)):
                    # A jit-decorated callee traces inline, skipping the call
                    # boundary's imminent-write pre-stage, so in the default
                    # mode its choked receiver writes run on the plain Python
                    # value and bake: audit its write set at region close.
                    # (A plain callee's boundary pre-stage mints the cell, so
                    # the audit passes it untouched.)
                    if is_auto_m2s_enabled():
                        # A COMPOUND field the callee rebuilds reaches the
                        # choke (jit: directly; plain: boundary replay), but
                        # only staged leaves make the choke carry instead of
                        # refuse: stage them at entry, as for direct writes.
                        for _attr in _callee_write_attrs(
                            _target.__get__(_holder, type(_holder))
                        ):
                            _adopt_declared_attr_write(
                                _holder, _attr, _stage_compound_only=True
                            )
                    else:
                        for _attr in _callee_write_attrs(
                            _target.__get__(_holder, type(_holder))
                        ):
                            _arm_unpromoted_write_audit(
                                _holder, _attr, f"{_base}.{_attr}"
                            )
                    continue
                if op_type_name == "while":
                    # No adoption for while regions (facts newly reach them;
                    # adoption is a for-only behavior): audit-only.
                    if not is_auto_m2s_enabled():
                        for _attr in _callee_write_attrs(
                            _target.__get__(_holder, type(_holder))
                        ):
                            _arm_unpromoted_write_audit(
                                _holder, _attr, f"{_base}.{_attr}"
                            )
                    continue
                try:
                    _writes, _ = transitive_write_facts(
                        _target.__get__(_holder, type(_holder))
                    )
                except Exception:
                    continue
                for _attr in _writes:
                    _adopt_declared_attr_write(_holder, _attr, _plain_meta_only=True)

            free_facts = getattr(self, "region_free_calls", None) or ()
            for _fname, _base in free_facts:
                # Free call with a Name-rooted first argument (`step(c)`):
                # a jit-decorated callee traces inline (no boundary
                # pre-stage), so its first-parameter writes bake in the
                # default mode; audit them at region close.  Under AUTO_M2S
                # a USER callee's compound rebuild reaches the choke (jit:
                # directly; plain: boundary replay): stage its leaves at
                # entry so the choke decomposition carries it.
                _holder = self._resolve_declared_base(
                    _base, mix_iter_args, mix_iter_arg_names
                )
                if _holder is None or isinstance(
                    _holder,
                    (bool, int, float, str, bytes, type, types.ModuleType),
                ):
                    continue
                _fn = self._resolve_declared_root(
                    _fname, mix_iter_args, mix_iter_arg_names
                )
                _fn = getattr(_fn, "__func__", _fn)
                if (
                    _fn is None
                    or isinstance(_fn, type)
                    or not callable(_fn)
                    or not hasattr(_fn, "__code__")
                ):
                    continue
                if is_auto_m2s_enabled():
                    if _pyir_boundary_module_is_user(
                        getattr(_fn, "__module__", None)
                    ):
                        for _attr in _callee_write_attrs(_fn):
                            _adopt_declared_attr_write(
                                _holder, _attr, _stage_compound_only=True
                            )
                    continue
                for _attr in _callee_write_attrs(_fn):
                    _arm_unpromoted_write_audit(
                        _holder, _attr, f"{_base}.{_attr}"
                    )

        # If analogue: carry an opaque leaf advanced+trapped in an ``scf.if``
        # forward (yield, not revert) so a post-``if`` reader sees it; aliases
        # excluded below.
        carries_if_leaves = op_type_name == "if"
        if_leaf_records: List[tuple] = []
        if_leaf_ref_cache: dict = {}
        # STANDALONE ``scf.if`` only: leaf SSAs SHARED across aliases keep their revert
        # (forward-carry one strands the rest); ``None`` in a loop, which carries them.
        if_aliased_leaves: Optional[list] = None
        if carries_if_leaves and not _op_has_enclosing_loop(op):
            if_aliased_leaves = []
            if captured_leaf_snapshot:
                for _ch, _ca, _cv in captured_leaf_snapshot:
                    _craw = _raw_backing_ir_value(_cv)
                    if _craw is not None:
                        if_aliased_leaves.append(_craw)
            # Opaque leaf SSAs held by 2+ mix_iter_args objects (aliased sub-object):
            # collect per-slot, then keep those seen in more than one iter_arg slot.
            _per_arg_leaves: List[List[ir.Value]] = []
            for _li in builtins.range(len(leaf_snapshots)):
                _ls = leaf_snapshots[_li]
                _slot_leaves: List[ir.Value] = []
                if _ls:
                    for _h, _a, _v in _ls:
                        _raw = _raw_backing_ir_value(_v)
                        if isinstance(_raw, ir.Value):
                            _slot_leaves.append(_raw)
                _per_arg_leaves.append(_slot_leaves)
            for _li in builtins.range(len(_per_arg_leaves)):
                for _v in _per_arg_leaves[_li]:
                    _in_other = any(
                        any(_same_ir_value(_w, _v) for _w in _per_arg_leaves[_lj])
                        for _lj in builtins.range(len(_per_arg_leaves))
                        if _lj != _li
                    )
                    if _in_other:
                        if_aliased_leaves.append(_v)

        enter_staged_cf()
        try:
            for i, builder in enumerate(region_builders):
                # Reconcile escaped CAPTURED leaves at EVERY region's entry (not just the
                # ``i > 0`` reset) so a chained-branch shared leaf can't trap an SSA the next reads.
                _pyir_repair_captured_escaped_leaves(
                    captured_leaf_snapshot,
                    f"{op_type_name} captured (region {i} entry)",
                    allow_numeric_revert,
                )

                # Reset to original values before non-first regions (else-block) so they
                # don't see then-block region-local MLIR values (SSA dominance violation).
                if is_multi_region and i > 0:
                    assert original_mix_iter_args is not None
                    for idx in builtins.range(len(mix_iter_args)):
                        mix_iter_args[idx] = original_mix_iter_args[idx]
                        # The SHARED object's leaf still carries the prior branch's trapped
                        # SSA, so revert any leaf not dominating the outer IP (snapshot does).
                        _pyir_repair_region_escaped_leaves(
                            mix_iter_args[idx],
                            leaf_snapshots[idx],
                            f"{op_type_name} iter_arg #{idx} (pre-region {i})",
                            allow_numeric_revert,
                        )
                        # Restore meta-scalar leaves the then-block mutated so the else-block
                        # sees op-entry meta (both branches start equal, as in non-PyIR).
                        _pyir_restore_region_meta(
                            mix_iter_args[idx],
                            meta_snapshots[idx],
                            f"{op_type_name} iter_arg #{idx} (pre-region {i})",
                        )
                        # Restore a write-only literal-origin Numeric counter the prior
                        # branch baked in so this sibling re-bakes its own (non-carried only).
                        _pyir_restore_meta_numeric_leaves(
                            meta_numeric_snapshots[idx],
                            f"{op_type_name} iter_arg #{idx} (pre-region {i})",
                        )
                    # Captured objects were already reconciled by the region-entry repair
                    # above; the idempotent revert means a second repair here is a no-op.

                region = op.regions[i]
                block = region.blocks[0]
                with ir.InsertionPoint(block):
                    block_args = list(block.arguments)

                    # Bind each declared-attr-write adoption to a fresh region-
                    # entry load of its cell (pre-write in-body reads see it).
                    for _dh, _da, _dref, _dplace in declared_attr_write_records:
                        try:
                            _pyir_boundary_bind_storage(
                                _dh, _da, _load_as_dsl(_dref, place=_dplace)
                            )
                        except Exception:
                            pass

                    # Re-load any tracked object-attribute slot whose staged value
                    # escaped a sibling region, so an un-instrumented read in THIS
                    _pyir_reload_stale_staged_attr_leaves(
                        f"{op_type_name} region {i} entry"
                    )

                    # Declare the loop BODY block as the innermost open body scope
                    # (F-BIRTHPOS): first-defs traced inside it are region-born.
                    is_loop_body_region = i == loop_body_region_index
                    if is_loop_body_region:
                        _pyir_push_loop_body_scope(block)
                    else:
                        # Non-body region entry (if arm / while cond) is a region-epoch
                        # boundary; body regions bump inside the body-scope push.
                        _pyir_bump_region_epoch()
                        _pyir_region_entry_push()

                    # Execute body -- AST-inserted pyir_assign/pyir_read handle ref
                    # creation, load, store for all mutable values.
                    with _PyirScopeGuard(kind="region", inherit=True):
                        region_result = builder(
                            op,
                            block_args,
                            [],  # ir_values: empty (no iter_args)
                            None,  # pytree_def: not used (pyir handles everything)
                            mix_iter_args,
                            0,  # full_write_args_count: 0
                        )

                    # Update mix_iter_args from body result so slot-backed objects (and their
                    # ``_mutable_ref`` / load-version tags) survive to the post-loop bridge.
                    if region_result is not None:
                        result_list = (
                            region_result
                            if isinstance(region_result, (list, tuple))
                            else [region_result]
                        )
                        for idx, val in enumerate(result_list):
                            if idx < len(mix_iter_args) and val is not None:
                                mix_iter_args[idx] = val

                    # Post-body (still open): carry any in-place-mutated leaf through a
                    # ``pyir.ref`` so it lifts to an iter_arg instead of being reverted.
                    if carries_loop_leaves:
                        for idx in builtins.range(len(mix_iter_args)):
                            loop_leaf_records.extend(
                                _pyir_carry_loop_body_mutated_leaves(
                                    mix_iter_args[idx],
                                    leaf_snapshots[idx],
                                    op,
                                    block,
                                    f"{op_type_name} iter_arg #{idx}",
                                    opaque_only=loop_leaf_opaque_only,
                                    # The slot to re-point post-loop for a SELF-LEAF (a whole-object
                                    # bare ``ir.Value`` is immutable, so its carry re-binds the slot).
                                    arg_index=idx,
                                    # The slot's bare-name fact: a SELF-LEAF resolves its
                                    # LOCAL place so every region adopts ONE cell.
                                    arg_name=(
                                        mix_iter_arg_names[idx]
                                        if idx < len(mix_iter_arg_names)
                                        else None
                                    ),
                                )
                            )
                        # Same opaque-leaf carry for CAPTURED free-variable
                        # objects advanced in a nested loop inside this one.
                        _arg_covered_leaf_keys = {
                            (id(_h), _a)
                            for _ls in leaf_snapshots
                            if _ls
                            for (_h, _a, _v) in _ls
                        }
                        captured_carry_snapshot = (
                            [
                                rec
                                for rec in captured_leaf_snapshot
                                if (id(rec[0]), rec[1]) not in _arg_covered_leaf_keys
                            ]
                            if captured_leaf_snapshot
                            else None
                        )
                        loop_leaf_records.extend(
                            _pyir_carry_loop_body_mutated_leaves(
                                None,
                                captured_carry_snapshot,
                                op,
                                block,
                                f"{op_type_name} captured",
                                opaque_only=loop_leaf_opaque_only,
                            )
                        )
                        # Store back an un-instrumented self-attr scalar mutation (a
                        # plain-method ``self.attr += step`` or state advance): the body
                        unstored_scalar_carry_records.extend(
                            _pyir_store_back_unstored_slot_carries_sweep(
                                op,
                                block,
                                f"{op_type_name} registry-sweep (region {i})",
                            )
                        )

                    # Post-body (still open): close the loop-body scope declaration.
                    if is_loop_body_region:
                        _pyir_pop_loop_body_scope()
                    else:
                        # Non-body region close is a region-epoch boundary; body
                        # regions bump inside the body-scope pop.
                        _pyir_bump_region_epoch()
                        _pyir_region_entry_pop()

                    # Post-region (still open): carry this branch's mutated leaf
                    # forward (yield) so the enclosing loop carries it, instead
                    # of reverting it.
                    if carries_if_leaves:
                        for idx in builtins.range(len(mix_iter_args)):
                            if_leaf_records.extend(
                                _pyir_carry_if_region_mutated_leaves(
                                    mix_iter_args[idx],
                                    leaf_snapshots[idx],
                                    op,
                                    block,
                                    if_leaf_ref_cache,
                                    f"{op_type_name} region #{i} iter_arg #{idx}",
                                    arg_index=idx,
                                    exclude_aliased_leaves=if_aliased_leaves,
                                    arg_name=(
                                        mix_iter_arg_names[idx]
                                        if idx < len(mix_iter_arg_names)
                                        else None
                                    ),
                                )
                            )

                    # Terminator
                    if builder in block_term_op_builder:
                        block_term_op_builder[builder](region_result, 0)
                    else:
                        scf.YieldOp([])
        finally:
            exit_staged_cf()

        log().debug("Completed scf.%s (pyir) \n[%s]", op_type_name, op)

        # Rebind any loop-carried leaf to a dominating post-loop ``pyir.load`` so post-
        # loop reads observe the loop result (the repair below then skips it).
        if carries_loop_leaves and loop_leaf_records:
            rebuilt_by_index = _pyir_rebind_carried_leaves_post_loop(loop_leaf_records)
            for ai, obj in rebuilt_by_index.items():
                if 0 <= ai < len(mix_iter_args):
                    mix_iter_args[ai] = obj

        # Rebind each stored-back scalar carry to a dominating post-loop
        # ``pyir.load`` so later reads observe the carried value.
        if carries_loop_leaves and unstored_scalar_carry_records:
            _pyir_rebind_unstored_scalar_carries_post_loop(
                unstored_scalar_carry_records
            )

        # Rebind each declared-attr-write adoption to a dominating post-loop
        # load, so a post-loop reader observes the carried result.
        for _dh, _da, _dref, _dplace in declared_attr_write_records:
            try:
                _pyir_boundary_bind_storage(
                    _dh, _da, _load_as_dsl(_dref, place=_dplace)
                )
            except Exception:
                pass

        # Rebind any if-forward-carried leaf to a dominating post-``if`` load; a WHOLE-OBJECT
        # rebind re-points the slot to the object the empty-else reset had discarded.
        if carries_if_leaves and if_leaf_records:
            rebuilt_by_index = _pyir_rebind_carried_leaves_post_loop(if_leaf_records)
            for ai, obj in rebuilt_by_index.items():
                if 0 <= ai < len(mix_iter_args):
                    mix_iter_args[ai] = obj

        # Post-region rebind FROM the ledger cell (clause A, read half): a bare
        # LOCAL re-sources its binding from a dominating post-region load.
        _pyir_rebind_local_place_cells_post_region(
            mix_iter_args, mix_iter_arg_names, op
        )

        # Revert escaped leaves of CAPTURED objects to their pre-op value; ordered AFTER
        # the loop-leaf rebind so a now-dominating carried leaf is not reverted.
        _pyir_repair_captured_escaped_leaves(
            captured_leaf_snapshot, f"{op_type_name} captured", allow_numeric_revert
        )
        # After this scf op closes, re-load any tracked object-attribute slot whose
        # staged value was bound inside the just-closed region (now non-dominating at
        _pyir_reload_stale_staged_attr_leaves(f"{op_type_name} post-region")

        # Emit pyir.load for slot-backed values so returns are valid at the outer scope;
        # bridge the ``_mutable_ref`` marker onto the load so loads chain at CF exits.
        for idx in builtins.range(len(mix_iter_args)):
            arg = mix_iter_args[idx]
            # Repair value-tree leaves a region body mutated to an SSA from the now-closed
            # region, which would else fail ``module.verify()`` (operand does not dominate).
            arg = _pyir_repair_region_escaped_leaves(
                arg,
                leaf_snapshots[idx],
                f"{op_type_name} iter_arg #{idx}",
                allow_numeric_revert,
            )
            # Re-bind a TUPLE-contained scalar value-tree leaf the body trapped: the
            # value-tree walk above never collects a tuple-nested scalar, so a sibling
            if if_aliased_leaves is not None:
                _pyir_repair_region_escaped_tuple_leaves(
                    arg, op, f"{op_type_name} iter_arg #{idx}"
                )
            # Restore meta-scalar leaves a region body mutated to the op-entry value, so a
            # later op sharing the object observes entry meta (the non-PyIR post-op state).
            arg = _pyir_restore_region_meta(
                arg, meta_snapshots[idx], f"{op_type_name} iter_arg #{idx}"
            )
            # Restore a write-only literal-origin Numeric counter the closed region trapped,
            # so a later op sharing the object re-bakes its own constant.
            _pyir_restore_meta_numeric_leaves(
                meta_numeric_snapshots[idx], f"{op_type_name} iter_arg #{idx}"
            )
            mix_iter_args[idx] = arg
            mv = _pyir_lookup_slot_from_value(arg)
            if mv is None:
                # Slot-backed but never loaded in this scope: fall back
                # to ``_mutable_ref`` so the bridge below still fires.
                mv = getattr(arg, "_mutable_ref", None)
            loaded = _pyir_auto_load_arg(arg, row_authoritative=True)
            if loaded is not arg:
                if mv is not None and _pyir_lookup_slot_from_value(loaded) is None:
                    _pyir_setattr_raw(loaded, "_mutable_ref", mv)
                mix_iter_args[idx] = loaded
                arg = loaded

            # A slot promoted to a ref inside the region but whose binding lost its ref link
            # folds back stale; the ref is authoritative, so rebind to a dominating load.
            cur = mix_iter_args[idx]
            name = mix_iter_arg_names[idx] if idx < len(mix_iter_arg_names) else None
            slot_key = _make_slot_key(name, None, None) if name else None
            ref = _slot_refs.get(slot_key) if slot_key is not None else None
            # Re-bind to a fresh dominating ``pyir.load %ref`` of the published slot
            # when: (1) the binding lost its ref link (untracked first-def gate); or (2)
            needs_rebind = (
                _is_untracked_post_region_binding(cur)
                or (is_multi_region and ref is not None)
                # A ``while``/``for`` carried META scalar whose slot the body stored
                # into stays a meta wrapper post-loop (tracked, so the untracked gate
                or (
                    op_type_name in ("while", "for")
                    and ref is not None
                    and _pyir_loop_carried_meta_needs_rebind(cur, ref, op)
                )
            )
            if needs_rebind and ref is not None:
                # Row-authoritative reload: reconstruct from the row's store-time
                # template; attaches a ``_mutable_ref`` for downstream re-loads.
                mix_iter_args[idx] = _load_as_dsl(ref, place=slot_key)
                log().info(
                    "[pyir] post-region rebind of promoted slot "
                    "'%s' to pyir.load (was stale %r)",
                    name,
                    cur,
                )

        # Refuse (loudly) any registered holder attr still advanced outside the ledger
        # after every store-back / rebind above had its chance to cover it.
        if _meta_slot_snapshot is not None:
            _pyir_verify_registry_meta_slots(_meta_slot_snapshot)

        # Refuse (loudly) an audited write leaf still meta and moved at close:
        # nothing promoted it, so its updates ran on the plain Python value
        # and were baked at the trace value.
        for _dh, _da, _entry, _label in deep_attr_write_audits:
            _dstorage = _instance_storage_items(_dh)
            if _dstorage is None or _da not in _dstorage:
                continue
            _dcur = _dstorage[_da]
            if _is_staged_value(_dcur):
                continue
            _dpy = _pyir_unwrap_meta_primitive(_dcur)
            if _dpy is None:
                continue
            try:
                _dplace = _make_slot_key(None, _dh, _da)
            except Exception:
                _dplace = None
            if _dplace is not None and _slot_refs.get(_dplace) is not None:
                continue
            try:
                _changed = bool(_dpy != _entry)
            except Exception:
                _changed = True
            if _changed:
                raise DSLUserCodeError(
                    DiagId.PHASE_MUTATE_PYTHON,
                    var=_label,
                )

        # Refuse (loudly) any container key created through an opaque
        # ``__setitem__`` owner in this region's bodies; retires the audits.
        _pyir_verify_opaque_owner_audits()

        # Return in standard pattern
        if not mix_iter_args:
            return
        if len(mix_iter_args) == 1:
            return mix_iter_args[0]
        return mix_iter_args

    def create_while_op_pyir(
        self,
        while_before_block: Callable[..., Any],
        while_after_block: Optional[Callable[..., Any]],
        write_args: List[Any],
        full_write_args_count: int,
        write_args_names: List[str],
    ) -> Any:
        """
        Create PyIR-specific while loop with zero iter_args.

        Uses pyir.ref/store/load for all mutable state management.
        """
        log().debug("_while_execute_dynamic (PyIR path)")
        while_op_type_name = "while"

        # The while AFTER block carries the body's declared write facts
        # (preprocessor-tagged, same vocabulary as the for tag).
        self.region_attr_writes = getattr(
            while_after_block, PYIR_REGION_ATTR_WRITES_ATTR, None
        )
        self.region_method_calls = getattr(
            while_after_block, PYIR_REGION_METHOD_CALLS_ATTR, None
        )
        self.region_free_calls = getattr(
            while_after_block, PYIR_REGION_FREE_CALLS_ATTR, None
        )
        self.region_body_func = while_after_block

        _pyir_cond = [None]  # list for nonlocal mutation in closures

        def create_while_op_impl(dyn_yield_ops: List[ir.Value]) -> ir.Operation:
            while_op = scf.WhileOp([], [])
            while_op.before.blocks.append()
            while_op.after.blocks.append()
            return while_op

        def before_block_builder_pyir(
            op: ir.Operation,
            block_args: List[ir.Value],
            _: List[ir.Value],
            pytree_def: Any,
            mix_iter_args: List[Any],
            full_write_args_count: int,
        ) -> None:
            # Execute condition block with original Python objects.
            # AST-inserted pyir_read/pyir_assign handle ref loads/stores.
            flat_args = list(mix_iter_args)
            cond, _before_results = while_before_block(*flat_args)
            _pyir_cond[0] = cond
            # Return None: do not contaminate mix_iter_args with condition
            return None

        def before_block_terminator_pyir(
            region_result: Any, full_write_args_count: int
        ) -> None:
            # Auto-load the condition before reading its SSA, so an un-instrumented
            # getter's pre-loop value gets a ``pyir.load`` and carries as an iter_arg.
            # The condition cell is the row the before-block just wrote.
            cond = _pyir_auto_load_arg(_pyir_cond[0], row_authoritative=True)
            ir_cond = as_numeric(cond).ir_value()
            scf.ConditionOp(ir_cond, [])

        def after_block_builder_pyir(
            op: ir.Operation,
            block_args: List[ir.Value],
            _: List[ir.Value],
            pytree_def: Any,
            mix_iter_args: List[object],
            full_write_args_count: int,
        ) -> None:
            # Execute loop body. AST-inserted pyir_assign handles stores.
            flat_args = list(mix_iter_args)
            assert while_after_block is not None
            # Return the body's final write-arg bindings so ``_scf_execute_pyir``
            # refreshes ``mix_iter_args`` before it carries loop-carried leaves: a leaf
            return while_after_block(*flat_args)

        return self.scf_execute_dynamic(
            op_type_name=while_op_type_name,
            mix_iter_args=write_args,
            full_write_args_count=full_write_args_count,
            mix_iter_arg_names=write_args_names,
            create_op_func=create_while_op_impl,
            region_builders=[before_block_builder_pyir, after_block_builder_pyir],
            block_term_op_builder={
                before_block_builder_pyir: before_block_terminator_pyir,
            },
        )
