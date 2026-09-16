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


"""PyIR runtime facade -- re-exports the layered pyir_* split.

``pyir_assign`` / ``pyir_read`` / ``MutableValue`` and the full prior
``pyir_runtime`` surface are defined across the pyir_state -> ... -> pyir_cleanup
chain; this module re-exports them so ``pyir_runtime.<name>`` keeps working.
"""

from .pyir_cleanup import *  # noqa: F401,F403  (top of the layer chain -> pulls in everything)

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors the chain modules' module-level definitions, which reach this
# facade at runtime via the wildcard + each layer's dynamic ``__all__`` --
# constructs a static type checker cannot evaluate. Purely additive: the
# wildcard import above stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    _meta_uses as _meta_uses,
    _slot_refs as _slot_refs,
    _slot_first_def_inside_cf as _slot_first_def_inside_cf,
    _slot_first_def_depth as _slot_first_def_depth,
    _slot_first_def_block as _slot_first_def_block,
    _slot_first_def_depth_any as _slot_first_def_depth_any,
    _pinned_owners as _pinned_owners,
    _slot_mvs as _slot_mvs,
    _slot_pending_store as _slot_pending_store,
    _pyir_fn_id_stack as _pyir_fn_id_stack,
    pyir_function_scope as pyir_function_scope,
    _current_fn_id as _current_fn_id,
    _SCF_REGION_NAMES as _SCF_REGION_NAMES,
    _PYIR_SKIP as _PYIR_SKIP,
    _SLOT_STORE_ATTR as _SLOT_STORE_ATTR,
    _PYIR_SLOT_FALLBACK as _PYIR_SLOT_FALLBACK,
    _PYIR_LIST_MUTATORS as _PYIR_LIST_MUTATORS,
    _PYIR_DICT_MUTATORS as _PYIR_DICT_MUTATORS,
    _PYIR_SET_MUTATORS as _PYIR_SET_MUTATORS,
    _PYIR_READ_SIMPLE_SENTINEL as _PYIR_READ_SIMPLE_SENTINEL,
    _NON_DOT_FUNC_ENTRY_OPS as _NON_DOT_FUNC_ENTRY_OPS,
    _MODULE_OPS as _MODULE_OPS,
)
from .pyir_core import (  # noqa: F401
    _make_slot_key as _make_slot_key,
    _cached_ir_value_dominates_ip as _cached_ir_value_dominates_ip,
    _emit_constant_at_ip as _emit_constant_at_ip,
    _unwrap as _unwrap,
    _wrapper_slots as _wrapper_slots,
    _record_fold_witness as _record_fold_witness,
    _WatchedM as _WatchedM,
    _WatchedInt as _WatchedInt,
    _WatchedBool as _WatchedBool,
    _WatchedFloat as _WatchedFloat,
    _replace_value_uses as _replace_value_uses,
    _exit_function_trace as _exit_function_trace,
    _watched_to_dsl as _watched_to_dsl,
    _describe_value_origin as _describe_value_origin,
    _FUNC_OPS as _FUNC_OPS,
    _auto_promote_primitive as _auto_promote_primitive,
    _can_create_ref as _can_create_ref,
    _is_vector_like as _is_vector_like,
    _is_memref_like as _is_memref_like,
    _mlir_type_or_none as _mlir_type_or_none,
    _staged_type_changed as _staged_type_changed,
    _is_boolean_like as _is_boolean_like,
    _is_literal_backed as _is_literal_backed,
    _POISON_EMITTED as _POISON_EMITTED,
    _make_poison_like as _make_poison_like,
    _record_poison_source as _record_poison_source,
    _get_defining_operation as _get_defining_operation,
    _get_function_entry_block as _get_function_entry_block,
    _create_ref as _create_ref,
    _pyir_lookup_slot_from_value as _pyir_lookup_slot_from_value,
    _pyir_value_tracked_by_accessible_ref as _pyir_value_tracked_by_accessible_ref,
    _load_as_dsl as _load_as_dsl,
    _ancestor_op_in_block as _ancestor_op_in_block,
    _slot_store_for_tier1 as _slot_store_for_tier1,
    _slot_store_for_tier2 as _slot_store_for_tier2,
    _slot_storage_available as _slot_storage_available,
    _registry_owner as _registry_owner,
    _get_slot_mv as _get_slot_mv,
    _set_slot_mv as _set_slot_mv,
    _clear_slot_mv as _clear_slot_mv,
    _iter_slot_mvs_for_pyir_read as _iter_slot_mvs_for_pyir_read,
    _attach_mutable_ref as _attach_mutable_ref,
    _fresh_wrapper as _fresh_wrapper,
    MutableValue as MutableValue,
    _get_instance_attrs as _get_instance_attrs,
    _is_compound_single_leaf as _is_compound_single_leaf,
    _is_leaf_decomposable as _is_leaf_decomposable,
    _check_tuple_decomposable as _check_tuple_decomposable,
    _check_all_fields_decomposable as _check_all_fields_decomposable,
    _flatten_tuple as _flatten_tuple,
    _pyir_assign_simple as _pyir_assign_simple,
    _is_func_boundary_op as _is_func_boundary_op,
    _is_module_boundary_op as _is_module_boundary_op,
    _raw_backing_ir_value as _raw_backing_ir_value,
    _value_dominates_current_ip as _value_dominates_current_ip,
    _same_ir_value as _same_ir_value,
    _op_is_inside_op as _op_is_inside_op,
    _innermost_enclosing_loop_op_at_ip as _innermost_enclosing_loop_op_at_ip,
    _loop_free_enclosing_if_ops_at_ip as _loop_free_enclosing_if_ops_at_ip,
)
from .pyir_corewalk import (  # noqa: F401
    _pyir_auto_load_arg as _pyir_auto_load_arg,
    _raw_ir_value as _raw_ir_value,
    _arg_value_dominates_current_ip as _arg_value_dominates_current_ip,
    _has_decomposable_staged_fields as _has_decomposable_staged_fields,
    _has_any_staged_content as _has_any_staged_content,
)
from .pyir_threading import (  # noqa: F401
    _meta_promote_slot as _meta_promote_slot,
)
from .pyir_entrypoints import (  # noqa: F401
    _decompose_tuple as _decompose_tuple,
    _decompose_m2m_assign as _decompose_m2m_assign,
    _pyir_check_no_complex_m2m_call as _pyir_check_no_complex_m2m_call,
    pyir_tag_pending_writes as pyir_tag_pending_writes,
    pyir_promote_loop_body_arg as pyir_promote_loop_body_arg,
    pyir_assign as pyir_assign,
    pyir_read as pyir_read,
    _pyir_post_subscript_read as _pyir_post_subscript_read,
    _subscript_container_is_dsl_managed as _subscript_container_is_dsl_managed,
    _pyir_pre_subscript_assign as _pyir_pre_subscript_assign,
    with_ctxmgr_check as with_ctxmgr_check,
    _pyir_while_cond as _pyir_while_cond,
)
from .pyir_cleanup import (  # noqa: F401
    _verify_no_used_poison as _verify_no_used_poison,
)
# -- END explicit imports for the type checker


__all__ = [name for name in list(globals()) if not name.startswith("__")]
