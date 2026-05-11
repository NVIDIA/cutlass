# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import dataclasses
from types import SimpleNamespace
from typing import Any

from cutlass._mlir import ir


# =============================================================================
# Helper functions
# =============================================================================


def is_frozen_dataclass(obj_or_cls: Any) -> bool:
    """Check if an object or class is a frozen dataclass."""
    cls = obj_or_cls if isinstance(obj_or_cls, type) else type(obj_or_cls)
    if not dataclasses.is_dataclass(cls):
        return False
    params = getattr(cls, "__dataclass_params__", None)
    if params is not None:
        return getattr(params, "frozen", False)
    return False


def _is_dynamic_expression(obj: Any) -> bool:
    """Check if object implements the DynamicExpression protocol."""
    if isinstance(obj, type):
        return False
    return hasattr(obj, "__extract_mlir_values__") and hasattr(
        obj, "__new_from_mlir_values__"
    )


def _is_assignable_leaf(obj: Any) -> bool:
    """
    Check if object is an assignable leaf.

    Assignable leaves are things the language allows us to assign to:
    - ir.Value: directly assignable
    - DynamicExpression: use __extract_mlir_values__ / __new_from_mlir_values__
    - DSL types with .value that is ir.Value: can update .value

    Objects whose class sets __cls_traversable_dict__ = True are always
    treated as containers (not leaves), even if they implement the
    DynamicExpression protocol.  This allows gather_leaves to recurse
    into their __dict__ while the class still provides
    __extract_mlir_values__ / __new_from_mlir_values__ to the framework.
    """
    # If the class declares itself as dict-traversable, treat as container, not leaf
    if getattr(type(obj), "__cls_traversable_dict__", False):
        return False

    if isinstance(obj, ir.Value):
        return True

    if _is_dynamic_expression(obj):
        return True

    if hasattr(obj, "value") and isinstance(getattr(obj, "value", None), ir.Value):
        return True

    return False


def _flatten_to_ir_values(values_dict: Any) -> list[ir.Value]:
    """Flatten a values_dict from __extract_mlir_values__ to list of ir.Values."""
    result = []

    if isinstance(values_dict, ir.Value):
        result.append(values_dict)
    elif isinstance(values_dict, dict):
        for v in values_dict.values():
            result.extend(_flatten_to_ir_values(v))
    elif isinstance(values_dict, (list, tuple)):
        for v in values_dict:
            result.extend(_flatten_to_ir_values(v))

    return result


def _unflatten_ir_values(
    template: Any, values: list[ir.Value], idx: list[int] | None = None
) -> Any:
    """Unflatten ir.Values back into a values_dict structure matching template."""
    if idx is None:
        idx = [0]

    if isinstance(template, ir.Value):
        result = values[idx[0]] if idx[0] < len(values) else template
        idx[0] += 1
        return result
    elif isinstance(template, dict):
        return {k: _unflatten_ir_values(v, values, idx) for k, v in template.items()}
    elif isinstance(template, list):
        return [_unflatten_ir_values(v, values, idx) for v in template]
    elif isinstance(template, tuple):
        return tuple(_unflatten_ir_values(v, values, idx) for v in template)
    else:
        return template


def _get_all_attrs(obj: Any) -> dict[str, Any]:
    """Get all attributes from an object via __dict__ and __slots__."""
    attrs = {}
    if hasattr(obj, "__dict__"):
        attrs.update(obj.__dict__)
    for cls in type(obj).__mro__:
        if hasattr(cls, "__slots__"):
            for slot in cls.__slots__:
                if hasattr(obj, slot) and slot not in attrs:
                    try:
                        attrs[slot] = getattr(obj, slot)
                    except AttributeError:
                        pass
    return attrs


def _unwrap_ir_value(val: Any) -> ir.Value | None:
    """
    Extract the ir.Value from a value, handling value casters.

    MLIR Python bindings auto-cast certain types (like PtrType -> _Pointer).
    These wrapped types store the ir.Value in .value attribute.
    """
    if isinstance(val, ir.Value):
        return val
    if hasattr(val, "value") and isinstance(val.value, ir.Value):
        return val.value
    return None


# =============================================================================
# LeafInfo
# =============================================================================


class LeafInfo:
    """
    Information about an assignable leaf and its location.

    A "leaf" is something the language allows us to assign to:
    - ir.Value: can be replaced in parent container
    - DynamicExpression: use __extract_mlir_values__ / __new_from_mlir_values__
    - DSL types with .value (Int32, _Pointer, etc.): can update .value

    We track where each leaf lives so we can update it after a loop/branch.

    Attributes:
        obj: The leaf object itself (DSL type or ir.Value)
        parent: The parent object containing this leaf (can be None for DSL types)
        key: The field name or index to access this leaf from parent
        key_type: 'attr', 'list', 'dict', 'root'
        path: Human-readable path from root (for debugging)
    """

    def __init__(self, obj: Any, parent: Any, key: Any, key_type: str, path: str):
        self.obj = obj
        self.parent = parent
        self.key = key
        self.key_type = key_type
        self.path = path
        self._extracted_values = None

    def get_ir_values(self) -> list[ir.Value]:
        """Get all ir.Values from this leaf (may be multiple for DynamicExpression)."""
        if isinstance(self.obj, ir.Value):
            return [self.obj]

        if _is_dynamic_expression(self.obj):
            values_dict = self.obj.__extract_mlir_values__()
            return _flatten_to_ir_values(values_dict)

        if hasattr(self.obj, "value") and isinstance(self.obj.value, ir.Value):
            return [self.obj.value]

        return []

    def get_ir_value(self) -> ir.Value | None:
        """Get single ir.Value (for backward compat - returns first value)."""
        values = self.get_ir_values()
        return values[0] if values else None

    def set_ir_values(self, new_vals: list[ir.Value]) -> None:
        """Set ir.Values at this location (may be multiple for DynamicExpression).

        With the mutable proxy pattern, the parent is always mutable (the capture
        list, a proxy list for tuples, or a proxy SimpleNamespace for frozen DCs).
        So replacement in parent always succeeds for leaves.
        """
        # Case 1: DynamicExpression -> use protocol to reconstruct and replace
        if _is_dynamic_expression(self.obj):
            old_values_dict = self.obj.__extract_mlir_values__()
            new_values_dict = _unflatten_ir_values(old_values_dict, new_vals)
            new_obj = self.obj.__new_from_mlir_values__(new_values_dict)

            replaced = False
            if self.parent is not None:
                if self.key_type == "attr":
                    setattr(self.parent, self.key, new_obj)
                    replaced = True
                elif self.key_type == "list" or self.key_type == "dict":
                    self.parent[self.key] = new_obj
                    replaced = True

            if replaced:
                self.obj = new_obj
                return

            # Fallback: try in-place update
            if hasattr(self.obj, "__dict__") and hasattr(new_obj, "__dict__"):
                self.obj.__dict__.update(new_obj.__dict__)
                return
            if hasattr(self.obj, "value") and len(new_vals) >= 1:
                self.obj.value = new_vals[0]
                return

            raise RuntimeError(
                f"Cannot update DynamicExpression at '{self.path}'.\n"
                f"  Object type: {type(self.obj).__name__}\n"
                f"  Parent type: {type(self.parent).__name__ if self.parent else 'None'}\n"
                f"  Key type: {self.key_type}"
            )

        # Case 2: Simple .value attribute (Int32, Float32, Pointer wrappers)
        if hasattr(self.obj, "value") and isinstance(
            getattr(self.obj, "value", None), ir.Value
        ):
            if len(new_vals) >= 1:
                self.obj.value = new_vals[0]
            return

        # Case 3: raw ir.Value (including subclasses like ArithValue, ctm.Pointer)
        if isinstance(self.obj, ir.Value):
            if len(new_vals) >= 1:
                self._replace_in_parent(new_vals[0])
            return

        print(
            f"WARNING: Cannot set ir.Values at {self.path}: "
            f"got {type(self.obj).__name__}"
        )

    def set_ir_value(self, new_val: ir.Value) -> None:
        """Set single ir.Value (for backward compat)."""
        self.set_ir_values([new_val])

    def _replace_in_parent(self, new_val: ir.Value) -> None:
        """Replace this object in its parent container."""
        if self.parent is None:
            print(f"WARNING: Cannot replace root-level ir.Value at {self.path}")
            return
        if self.key_type == "attr":
            setattr(self.parent, self.key, new_val)
        elif self.key_type == "list" or self.key_type == "dict":
            self.parent[self.key] = new_val

    def __repr__(self) -> str:
        return f"LeafInfo({self.path}, {type(self.obj).__name__})"


# =============================================================================
# gather_leaves
# =============================================================================


def gather_leaves(
    objects: list[Any],
) -> tuple[list[ir.Value], list[LeafInfo], list[tuple[Any, ...]]]:
    """
    Recursively traverse the object graph and gather assignable leaves.

    Leaves are atomic values (ir.Value, Int32, DynamicExpression, etc.) that
    carry ir.Values. Containers (list, dict, class, tuple, frozen dataclass)
    hold leaves and other containers -- we recurse into them.

    The `objects` list itself serves as the root mutable parent, so every leaf
    is always addressable via its parent container. For immutable containers
    (tuples, frozen dataclasses), we create mutable proxies during gather and
    reconstruct the immutables during inject_leaves.

    Args:
        objects: List of Python objects to traverse (the capture container)

    Returns:
        Tuple of:
        - ir_values: Flat list of ir.Values from leaves
        - leaf_infos: List of LeafInfo describing each leaf's location
        - immutable_proxies: List of (original_obj, proxy, parent, key, key_type)
          for each immutable container encountered, in DFS order.
          Used by inject_leaves for bottom-up reconstruction.
    """
    ir_values: list[ir.Value] = []
    leaf_infos: list[LeafInfo] = []
    immutable_proxies: list[tuple[Any, ...]] = []

    visited = set()

    def _gather_recursive(
        obj: Any, parent: Any, key: Any, key_type: str, path: str
    ) -> None:
        """Recursively find assignable leaves."""
        if obj is None:
            return

        obj_id = id(obj)

        # Check if this is an assignable leaf
        if _is_assignable_leaf(obj):
            info = LeafInfo(obj, parent, key, key_type, path)
            leaf_infos.append(info)
            leaf_values = info.get_ir_values()
            ir_values.extend(leaf_values)
            return

        # Not a leaf - recurse into containers
        if obj_id in visited:
            return
        visited.add(obj_id)

        # List (mutable container)
        if isinstance(obj, list):
            for i, item in enumerate(obj):
                item_path = f"{path}[{i}]" if path else f"[{i}]"
                _gather_recursive(item, obj, i, "list", item_path)
            return

        # Dict (mutable container)
        if isinstance(obj, dict):
            for k, v in obj.items():
                key_str = repr(k) if not isinstance(k, str) else k
                item_path = f"{path}[{key_str}]" if path else f"[{key_str}]"
                _gather_recursive(v, obj, k, "dict", item_path)
            return

        # Tuple (IMMUTABLE container -- create mutable proxy list)
        if isinstance(obj, tuple):
            proxy_list = list(obj)
            immutable_proxies.append((obj, proxy_list, parent, key, key_type))
            if parent is not None:
                if key_type == "list" or key_type == "dict":
                    parent[key] = proxy_list
                elif key_type == "attr":
                    setattr(parent, key, proxy_list)
            for i, item in enumerate(proxy_list):
                item_path = f"{path}({i})" if path else f"({i})"
                _gather_recursive(item, proxy_list, i, "list", item_path)
            return

        # Frozen dataclass (IMMUTABLE container -- create mutable proxy)
        if is_frozen_dataclass(obj):
            fields = dataclasses.fields(obj)
            proxy = SimpleNamespace(**{f.name: getattr(obj, f.name) for f in fields})
            immutable_proxies.append((obj, proxy, parent, key, key_type))
            if parent is not None:
                if key_type == "list" or key_type == "dict":
                    parent[key] = proxy
                elif key_type == "attr":
                    setattr(parent, key, proxy)
            for f in fields:
                attr_val = getattr(proxy, f.name)
                if f.name.startswith("__") or callable(attr_val):
                    continue
                attr_path = f"{path}.{f.name}" if path else f.name
                _gather_recursive(attr_val, proxy, f.name, "attr", attr_path)
            return

        # Object with __dict__ or __slots__ (mutable container)
        if hasattr(obj, "__dict__") or hasattr(type(obj), "__slots__"):
            attrs = _get_all_attrs(obj)
            for attr_name, attr_val in attrs.items():
                if attr_name.startswith("__") or callable(attr_val):
                    continue
                attr_path = f"{path}.{attr_name}" if path else attr_name
                _gather_recursive(attr_val, obj, attr_name, "attr", attr_path)
            return

    # Process each top-level object
    for i, obj in enumerate(objects):
        root_path = f"arg{i}"
        _gather_recursive(obj, objects, i, "list", root_path)

    return ir_values, leaf_infos, immutable_proxies


# =============================================================================
# inject_leaves
# =============================================================================


def inject_leaves(
    leaf_infos: list[LeafInfo],
    new_values: list[Any],
    immutable_proxies: list[tuple[Any, ...]] | None = None,
) -> None:
    """
    Inject new ir.Values into the leaves, then reconstruct immutable containers.

    Two-phase injection:
      Phase 1: Direct mutations into leaf parents (which are always mutable --
               either a real mutable container or a proxy list/SimpleNamespace).
      Phase 2: Bottom-up reconstruction of immutable containers (tuples, frozen
               dataclasses) from their proxies, replacing the proxy in its parent.

    Args:
        leaf_infos: List of LeafInfo from gather_leaves
        new_values: New values to inject (ir.Value or wrapped types)
        immutable_proxies: List of (original_obj, proxy, parent, key, key_type)
            from gather_leaves. If None, skip Phase 2 (backward compat).
    """
    # Calculate expected total values
    expected_count = sum(len(info.get_ir_values()) for info in leaf_infos)
    if len(new_values) != expected_count:
        print(
            f"WARNING: inject_leaves: value count mismatch - "
            f"expected {expected_count}, got {len(new_values)}"
        )

    # Unwrap all values first
    unwrapped = []
    for v in new_values:
        ir_val = _unwrap_ir_value(v)
        if ir_val is not None:
            unwrapped.append(ir_val)
        else:
            print(f"WARNING: inject_leaves: cannot unwrap {type(v).__name__}")
            unwrapped.append(v)

    # Phase 1: Inject values into each leaf
    idx = 0
    for info in leaf_infos:
        num_values = len(info.get_ir_values())
        if num_values == 0:
            continue

        leaf_values = unwrapped[idx : idx + num_values]
        idx += num_values

        if len(leaf_values) != num_values:
            print(
                f"ERROR: inject_leaves: not enough values for {info.path} "
                f"(need {num_values}, have {len(leaf_values)})"
            )
            continue

        info.set_ir_values(leaf_values)

    # Phase 2: Reconstruct immutable containers bottom-up
    if immutable_proxies:
        for original_obj, proxy, parent, key, key_type in reversed(immutable_proxies):
            new_obj: Any
            if isinstance(original_obj, tuple):
                new_obj = type(original_obj)(proxy)
            elif dataclasses.is_dataclass(original_obj) and not isinstance(
                original_obj, type
            ):
                fields = dataclasses.fields(original_obj)
                field_vals = {f.name: getattr(proxy, f.name) for f in fields}
                new_obj = type(original_obj)(**field_vals)
            else:
                continue

            if parent is not None:
                if key_type == "list" or key_type == "dict":
                    parent[key] = new_obj
                elif key_type == "attr":
                    setattr(parent, key, new_obj)


# =============================================================================
# Debug utility
# =============================================================================


def print_leaves_debug(
    leaf_infos: list[LeafInfo], label: str = "", prefix: str = "CUTE_DSL"
) -> None:
    """
    Print debug info about gathered assignable leaves.

    Enable with environment variable: {prefix}_DEBUG_LEAVES=1
    (e.g. CUTE_DSL_DEBUG_LEAVES=1 for the CuTe DSL)
    """
    import os

    if os.environ.get(f"{prefix}_DEBUG_LEAVES", "0") != "1":
        return

    print(f"\n{'=' * 80}")
    print(f"LEAVES: {label}")
    print(f"{'=' * 80}")
    print(f"{'#':<5} {'TYPE':<20} {'#V':<4} {'IR_TYPES':<25} {'PATH'}")
    print(f"{'-' * 5} {'-' * 20} {'-' * 4} {'-' * 25} {'-' * 40}")

    total_values = 0
    for i, info in enumerate(leaf_infos):
        obj_type = type(info.obj).__name__
        ir_vals = info.get_ir_values()
        num_vals = len(ir_vals)
        total_values += num_vals

        if num_vals == 0:
            ir_types_str = "None"
        elif num_vals == 1:
            ir_types_str = str(ir_vals[0].type)[:23]
        else:
            ir_types_str = f"{str(ir_vals[0].type)[:15]}..({num_vals})"

        print(f"{i:<5} {obj_type:<20} {num_vals:<4} {ir_types_str:<25} {info.path}")

    print(f"{'=' * 80}")
    print(f"Total: {len(leaf_infos)} leaves, {total_values} ir.Values")
    print(f"{'=' * 80}\n")


# =============================================================================
# TraversableLeafMixin – generic DynamicExpression via gather/inject leaves
# =============================================================================


class TraversableLeafMixin:
    """
    Mixin that auto-implements the DynamicExpression protocol
    (__extract_mlir_values__ / __new_from_mlir_values__) using
    gather_leaves / inject_leaves.

    When gather_leaves encounters an object whose class has
    ``__cls_traversable_dict__ = True``, it treats the object as a
    **container** (recurses into ``__dict__``) rather than as a
    DynamicExpression leaf — even if ``__extract_mlir_values__`` is
    present.  This eliminates the need to manually implement the
    extract/new protocol for classes that simply need all their
    ``ir.Values`` gathered and injected.

    The gather state is stored on the instance under dunder keys
    (``__gather_infos``, ``__gather_proxies``) which ``gather_leaves``
    automatically skips (it ignores ``__``-prefixed attributes).

    Usage — zero boilerplate::

        @dataclass
        class MyTask(TraversableLeafMixin):
            src_resources: List[MemoryResource]
            dst_resources: List[MemoryResource]
            # No manual __extract_mlir_values__ needed!

    If extra fixups are needed after inject (e.g. re-aliasing)::

        class MyTask(TraversableLeafMixin):
            ...
            def __new_from_mlir_values__(self, values):
                super().__new_from_mlir_values__(values)
                # custom fixup
                self.work_queue = self.src_resources[self.work_queue_idx]
                return self
    """

    __cls_traversable_dict__ = True

    def __extract_mlir_values__(self) -> dict:
        ir_vals, infos, proxies = gather_leaves([self])
        # Store with __ prefix so gather_leaves skips them on next call
        self.__dict__["__gather_infos"] = infos
        self.__dict__["__gather_proxies"] = proxies

        # Return a flat dict keyed by the full leaf path.
        # This makes framework error messages immediately show which
        # attribute changed structure, e.g.:
        #   "src_resources[0].buf"  -> i32
        #   "dst_resources[0].ptr"  -> !llvm.ptr
        # Multi-value leaves (DynamicExpression) get indexed sub-keys.
        result = {}
        val_idx = 0
        for info in infos:
            n_vals = len(info.get_ir_values())
            if n_vals == 1:
                result[info.path] = ir_vals[val_idx]
            else:
                for i in range(n_vals):
                    result[f"{info.path}#{i}"] = ir_vals[val_idx + i]
            val_idx += n_vals
        return result

    def __new_from_mlir_values__(
        self, values: dict[str, Any]
    ) -> "TraversableLeafMixin":
        infos = self.__dict__.pop("__gather_infos")
        proxies = self.__dict__.pop("__gather_proxies")
        # values is a flat {path: ir.Value} dict; just take values in order
        new_vals = list(values.values())
        inject_leaves(infos, new_vals, proxies)
        return self
