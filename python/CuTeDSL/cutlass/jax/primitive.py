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

from collections.abc import Hashable, Mapping
from dataclasses import dataclass, replace
import logging
import operator
from typing import Any, Callable, Literal, Sequence

import jax
import jax.extend
import jax.numpy as jnp
from jax.interpreters import mlir
from jax._src import core as jax_core, effects
from jax._src.interpreters import ad
from jax._src.interpreters import batching


from .compile import (
    Arg,
    _KernelLoweringTarget,
    _normalize_input_output_aliases,
    FunctionSpec,
    build_function_spec,
    get_or_compile_kernel,
)
from .types import (
    _get_memory_space,
    _is_value_cast,
    _normalize_divisibility,
    _validate_permutation,
    cutlass_to_jax_layout_order,
    default_tensor_spec,
    row_major_layout,
    TensorSpec,
)
from .ffi import (
    _get_cutlass_call_target_version,
    _register_and_get_default_ffi_call_target,
    _validate_cutlass_call_ffi_abi_version,
    get_cutlass_call_ffi_version,
)


logger = logging.getLogger(__name__)

_VmapMethod = (
    Literal["sequential", "sequential_unrolled", "expand_dims", "broadcast_all"] | None
)
_VMAP_METHODS = (
    "sequential",
    "sequential_unrolled",
    "expand_dims",
    "broadcast_all",
)

cutlass_call_inner_p = jax.extend.core.Primitive("cutlass_call_inner")
cutlass_call_inner_p.multiple_results = True


@dataclass(frozen=True)
class _CutlassCallEffect(jax_core.Effect):
    """Marks externally visible effects that must survive JAX dead-code removal."""


_CUTLASS_CALL_EFFECT = _CutlassCallEffect()
effects.lowerable_effects.add_type(_CutlassCallEffect)
effects.control_flow_allowed_effects.add_type(_CutlassCallEffect)


def cutlass_call(
    fn: Callable[..., None],
    *,
    output_shape_dtype: Any = None,
    input_spec: Any = None,
    output_spec: Any = None,
    input_mode: Any = None,
    output_mode: Any = None,
    input_output_aliases: (
        Mapping[int | jax.tree_util.KeyPath, int | jax.tree_util.KeyPath] | None
    ) = None,
    has_side_effect: bool = False,
    allow_cuda_graph: bool | None = None,
    ffi_call_target: str | None = None,
    ffi_abi_version: int | None = None,
    compile_options: str | None = None,
    compile_key: Hashable | None = None,
    use_static_tensors: bool = False,
    vmap_method: _VmapMethod = None,
    **kwargs: Any,
) -> Callable[..., Any]:
    """Create a callable that invokes a ``@cute.jit`` function from JAX.

    Returns a callable that accepts JAX arrays and dispatches to *fn* as part
    of a ``jax.jit``-compiled computation. The backend kernel is compiled once
    and cached for subsequent invocations with the same shapes and specs, but
    automatic cache lookup may still generate frontend IR. Inputs may be
    ``None``; absent tensors consume no FFI buffer and each distinct input
    pytree structure is compiled and cached independently.

    Example::

        @cute.jit
        def my_kernel(stream, A, B, C, D):
            ...

        @jax.jit
        def run(a, b):
            return cutlass_call(
                my_kernel,
                output_shape_dtype=(
                    jax.ShapeDtypeStruct(a.shape, a.dtype),
                    jax.ShapeDtypeStruct(b.shape, b.dtype),
                ),
            )(a, b)

        c, d = run(a, b)

    Args:
        fn: A ``@cute.jit``-decorated function with the signature
            ``(stream, *inputs, *outputs, **kwargs)``.
        output_shape_dtype: A pytree of :class:`jax.ShapeDtypeStruct` (or
            objects with ``.shape`` and ``.dtype`` attributes) describing each
            output buffer. A sequence at the root describes the outer output
            sequence. Wrap a tuple-like pytree in a one-element tuple when it
            should be treated as one top-level output.
        input_spec: A :class:`TensorSpec` or list thereof providing
            layout/mode/divisibility hints for input tensors. ``None`` infers
            defaults from each array. Specs may either describe only present
            tensors or mirror the input pytree, using ``None`` for absent
            tensors. For a single positional pytree argument, the spec may
            mirror that argument directly. A ``TensorSpec`` with
            ``layout=None`` uses and constrains row-major physical layout; use
            ``mode`` to remap physical dimensions to the kernel's logical modes.
            ``TensorSpec(cast=...)`` can instead pass the data pointer or load
            a scalar from host memory, optionally converting it with an adapter
            function. The adapter receives the loaded scalar and emits host DSL
            operations to construct the launcher argument. Passing pointers or
            handle values does not track mutations of referenced allocations;
            pass modified payload arrays explicitly with input/output aliases.
        output_spec: Same as *input_spec* but applied to output tensors.
            Only tensor and pointer casts provide writable output views.
        input_output_aliases: Mapping from inputs to outputs that should share
            storage. Integer mappings select complete top-level input and output
            pytrees. Key-path mappings select individual tensor leaves.

            Input key paths are rooted at the tuple of positional arguments
            passed to the returned callable. Output key paths are rooted at the
            outer output sequence derived from ``output_shape_dtype``. A path
            therefore usually starts with ``SequenceKey(index)`` to select a
            positional input or output. For example, given one input state and
            one output state::

                state_path = (
                    jax.tree_util.SequenceKey(0),
                    jax.tree_util.GetAttrKey("persistent"),
                )
                aliases = {state_path: state_path}

            Input and output paths need not be identical; each must resolve to
            a tensor leaf in its respective pytree. Selected leaves must have
            matching shapes, dtypes, and physical layouts. Sibling leaves
            remain ordinary outputs.

            Aliasing does not donate the caller's buffers. To permit reuse of
            the original input storage, configure ``donate_argnums`` on the
            caller's ``jax.jit`` and use the returned arrays afterward.
        has_side_effect: Preserve the call even when its results are unused,
            for example when it updates external state. Defaults to ``False``.
            This does not order otherwise independent calls; express ordering
            through data dependencies.
        allow_cuda_graph: Whether XLA may capture this call in a CUDA graph.
            Defaults to ``None``, which permits capture only when all inputs
            and outputs are known to be device-resident. Host, pinned-host,
            and unknown placement disable capture by default, including on
            older JAX versions without traced memory-space metadata.
            ``False`` disables capture; ``True`` opts in regardless of placement.
            Opting in asserts that the launcher supports capture, values it
            reads are initialized at capture and stable across replay, and
            referenced resources outlive the graph. This does not freeze tensor
            contents read by GPU kernels or force XLA to use graphs.
        ffi_call_target: Exact FFI target name to call without automatic
            registration or default-target selection.
            The target must implement the CuTeDSL call ABI, and the caller is
            responsible for registering it with JAX and setting its capture
            traits. *allow_cuda_graph* does not modify an explicit target name.
            When exporting, the caller must also allow the custom target with
            :meth:`jax.export.DisabledSafetyCheck.custom_call`. Defaults to
            ``None``.
        ffi_abi_version: CuTeDSL call ABI implemented by *ffi_call_target*.
            This is distinct from XLA's FFI API version. Supported values are
            1, 2, and 3; see :mod:`cutlass.jax.ffi` for their contracts.
            Defaults to :func:`cutlass.jax.get_cutlass_call_ffi_version`. An
            explicitly named built-in target must match this version.
        compile_options: Optional string of compiler flags forwarded to
            ``cute.compile``.
        compile_key: Optional hashable component of the compilation cache key
            that skips IR generation during cache lookup. The value must
            uniquely identify the kernel body, captured state, and relevant
            global state; reusing it for incompatible calls can return an
            incorrect cached binary. A stable function object or
            application-defined identifier may be used.
            Input/output pytrees, shapes, dtypes, tensor specifications,
            aliases, the FFI target and ABI version, compile-time arguments,
            compiler options, and environment are included automatically.
        use_static_tensors: If ``True``, tensor shapes and strides are baked in
            as compile-time constants, improving performance when shapes are
            fixed across calls.  Defaults to ``False``.
        vmap_method: Method used to batch this call under :func:`jax.vmap`,
            following :func:`jax.pure_callback` conventions. ``"sequential"``
            maps the existing unbatched kernel over the mapped axis, issuing one
            kernel invocation per element.
            ``"sequential_unrolled"`` has the same semantics but fully unrolls
            the loop, increasing compiled-program size and requiring a concrete
            mapped axis size. ``"expand_dims"`` and ``"broadcast_all"`` compile
            one batch-aware kernel invocation: mapped axes become leading axes,
            while unmapped inputs receive a leading dimension of size one or the
            mapped axis size, respectively. ``None`` rejects batching. Defaults
            to ``None``.
        **kwargs: Additional keyword arguments forwarded to *fn* as compile-time
            constants.

    Returns:
        A callable ``(*arrays) -> output_pytree`` that can be used inside
        ``jax.jit``.

    Note:
        This API is experimental and subject to change.

        Kernels that require compiler-managed device workspace must have concrete
        input and output shapes. Symbolic ``jax.export`` dimensions are rejected
        for these kernels. Calls with host-resident inputs do not support
        compiler-managed workspace because its compile-time size query cannot
        read runtime buffer contents.

        Sequential methods preserve the unbatched input and output shapes and
        tensor specifications. Native methods prepend a physical and logical
        batch dimension to every tensor specification and output shape. The
        kernel must handle those leading dimensions, including size-one
        broadcasting for ``"expand_dims"``; nested ``vmap`` calls add one
        leading dimension per level. Native methods also invoke *fn* once for
        a zero-size mapped axis, so the kernel must tolerate a zero leading
        extent. ``"broadcast_all"`` may materialize broadcasted copies of
        unmapped inputs. Compiler-managed workspace remains private to the
        single custom call and is not batched. With ``"expand_dims"``, every
        input aliased to an output must be mapped unless the mapped axis has a
        statically known size of one.

        Without ``compile_key``, each cache lookup that reaches Cutlass
        lowering generates precompiled IR to derive a content key. On a cache
        miss, object compilation traces ``fn`` again, so both traces must generate
        identical IR for identical compile-time arguments.
    """
    if output_shape_dtype is None:
        raise ValueError("'output_shape_dtype' must be specified.")
    if vmap_method is not None and vmap_method not in _VMAP_METHODS:
        raise ValueError(
            f"'vmap_method' must be None or one of {_VMAP_METHODS}; "
            f"got {vmap_method!r}."
        )
    input_output_aliases = _normalize_input_output_aliases(input_output_aliases)
    if ffi_abi_version is None:
        ffi_abi_version = get_cutlass_call_ffi_version()
    _validate_cutlass_call_ffi_abi_version(ffi_abi_version)
    if ffi_call_target is None:
        # Resolve the process default before binding so the target participates
        # in JAX's compilation cache key.
        ffi_call_target = _register_and_get_default_ffi_call_target(
            allow_cuda_graph is not False, ffi_abi_version
        )
        no_cuda_graph_ffi_call_target = (
            _register_and_get_default_ffi_call_target(False, ffi_abi_version)
            if allow_cuda_graph is None
            else ffi_call_target
        )
    else:
        no_cuda_graph_ffi_call_target = ffi_call_target
    for target in (ffi_call_target, no_cuda_graph_ffi_call_target):
        target_version = _get_cutlass_call_target_version(target)
        if target_version is not None and target_version != ffi_abi_version:
            raise ValueError(
                f"Built-in FFI target '{target}' implements CuTeDSL "
                f"call ABI v{target_version}, not requested v{ffi_abi_version}"
            )
    if compile_key is not None and getattr(type(compile_key), "__hash__", None) is None:
        raise TypeError("'compile_key' must be hashable or None.")

    if input_spec and input_mode:
        raise ValueError(
            "input_spec and input_mode can not both be set. Use input_spec only as input_mode is deprecated."
        )
    if input_mode:
        input_spec = input_mode

    if output_spec and output_mode:
        raise ValueError(
            "input_spec and input_mode can not both be set. Use input_spec only as input_mode is deprecated."
        )
    if output_mode:
        output_spec = output_mode

    # Output sharding informs capture policy, not FFI output placement.
    if allow_cuda_graph is None and not all(
        _is_device_tensor(
            jax.ShapeDtypeStruct(
                value.shape, value.dtype, sharding=getattr(value, "sharding", None)
            )
        )
        for value in jax.tree.leaves(output_shape_dtype)
    ):
        allow_cuda_graph = False
    output_shape_dtype = jax.tree.map(
        lambda leaf: jax.ShapeDtypeStruct(leaf.shape, leaf.dtype), output_shape_dtype
    )

    return _cutlass_call_impl(
        fn,
        output_shape_dtype=output_shape_dtype,
        input_spec=input_spec,
        output_spec=output_spec,
        input_output_aliases=input_output_aliases,
        has_side_effect=has_side_effect,
        allow_cuda_graph=allow_cuda_graph,
        ffi_call_target=ffi_call_target,
        no_cuda_graph_ffi_call_target=no_cuda_graph_ffi_call_target,
        ffi_abi_version=ffi_abi_version,
        compile_options=compile_options,
        compile_key=compile_key,
        use_static_tensors=use_static_tensors,
        vmap_method=vmap_method,
        **kwargs,
    )


def _is_spec_leaf(x: Any) -> bool:
    """Return True if *x* should be treated as a leaf when traversing a spec pytree.

    Stops traversal at ``TensorSpec`` and ``None`` (both are valid leaf specs) and at
    bare integer sequences (the legacy mode-spec shorthand).  Everything else is
    treated as a pytree container and recursed into by ``jax.tree.leaves``.
    """
    if x is None or isinstance(x, TensorSpec):
        return True
    # Legacy: a bare sequence of ints represents a single TensorSpec(mode=...).
    # Check *all* elements so that mixed sequences like (1, TensorSpec()) are NOT
    # mistaken for a mode spec and instead cause a TypeError below.
    if isinstance(x, (list, tuple)) and bool(x) and all(isinstance(i, int) for i in x):
        return True
    return False


def _normalize_tensor_spec(value: Any) -> list[TensorSpec | None]:
    """Normalize a spec pytree into a flat list of ``TensorSpec | None`` entries.

    *value* may be any JAX pytree whose leaves are ``TensorSpec``, ``None``, or a
    bare integer sequence (legacy shorthand for ``TensorSpec(mode=...)``).  Dict and
    other non-list/tuple pytree containers are supported via ``jax.tree.leaves``.

    Note: ``TensorSpec`` is itself a JAX-registered dataclass with all-static fields,
    so traversal *must* use the ``is_leaf`` predicate to stop at ``TensorSpec`` nodes
    rather than recursing into them (which would yield no children and silently drop
    the spec).
    """
    leaves = jax.tree.leaves(value, is_leaf=_is_spec_leaf)
    result = []
    for leaf in leaves:
        if leaf is None or isinstance(leaf, TensorSpec):
            result.append(leaf)
        elif isinstance(leaf, (list, tuple)):
            # Legacy: bare int sequence → TensorSpec(mode=...)
            result.append(TensorSpec(mode=tuple(leaf)))
        else:
            raise TypeError(
                f"Unexpected value for TensorSpec: {leaf!r} ({type(leaf).__name__})"
            )
    return result


def _resolve_spec_flat(spec: Any, tensors: list) -> tuple[TensorSpec, ...]:
    """Normalize *spec* and fill any ``None`` slots with defaults inferred from *tensors*."""
    if spec is None:
        return tuple(default_tensor_spec(t) for t in tensors)
    specs = list(_normalize_tensor_spec(spec))
    if len(specs) != len(tensors):
        raise ValueError(
            f"Must have the same number of specs ({len(specs)}) as tensors ({len(tensors)})."
        )
    return tuple(
        default_tensor_spec(t) if s is None else s for s, t in zip(specs, tensors)
    )


def _resolve_input_spec_flat(
    spec: Any, inputs: Any, tensors: list
) -> tuple[TensorSpec, ...]:
    """Resolve specs for present tensors while preserving optional input structure."""
    specs = _normalize_tensor_spec(spec) if spec is not None else []
    if spec is None or len(specs) == len(tensors):
        return _resolve_spec_flat(spec, tensors)

    _, spec_tree = jax.tree.flatten(spec, is_leaf=_is_spec_leaf)
    structured_inputs = inputs
    _, input_tree = jax.tree.flatten(structured_inputs, is_leaf=lambda x: x is None)
    if input_tree != spec_tree and isinstance(inputs, tuple) and len(inputs) == 1:
        structured_inputs = inputs[0]
        _, input_tree = jax.tree.flatten(structured_inputs, is_leaf=lambda x: x is None)
    if input_tree != spec_tree:
        raise ValueError(
            f"Must have the same number of specs ({len(specs)}) as tensors "
            f"({len(tensors)}), or an input_spec pytree matching the inputs."
        )

    def resolve(input_value: Any, input_spec: Any) -> TensorSpec | None:
        if input_value is None:
            if input_spec is not None:
                raise ValueError("An absent tensor input must have a None input_spec.")
            return None
        if input_spec is None:
            return default_tensor_spec(input_value)
        if isinstance(input_spec, TensorSpec):
            return input_spec
        if isinstance(input_spec, (list, tuple)):
            return TensorSpec(mode=tuple(input_spec))
        raise TypeError(
            f"Unexpected value for TensorSpec: {input_spec!r} "
            f"({type(input_spec).__name__})"
        )

    resolved = jax.tree.map(resolve, structured_inputs, spec, is_leaf=_is_spec_leaf)
    return tuple(jax.tree.leaves(resolved, is_leaf=lambda x: isinstance(x, TensorSpec)))


def _validate_specs(label: str, tensors: list, specs: tuple[TensorSpec, ...]) -> None:
    """Validate that each spec's rank-dependent fields match the corresponding tensor shape."""
    for idx, (tensor, spec) in enumerate(zip(tensors, specs)):
        if spec.layout is not None:
            try:
                _validate_permutation("layout", spec.layout, tensor.shape)
            except ValueError as e:
                raise ValueError(
                    f"{label} #{idx} has invalid layout {spec.layout} for shape {tensor.shape}."
                ) from e
        if spec.mode is not None:
            try:
                _validate_permutation("mode", spec.mode, tensor.shape)
            except ValueError as e:
                raise ValueError(
                    f"{label} #{idx} has invalid mode {spec.mode} for shape {tensor.shape}."
                ) from e

        order = spec.layout if spec.layout is not None else row_major_layout(tensor)
        try:
            _normalize_divisibility(spec.divisibility, order, tensor.shape)
        except ValueError as e:
            raise ValueError(
                f"{label} #{idx} has invalid divisibility {spec.divisibility} for shape {tensor.shape}."
            ) from e


def _is_device_tensor(value: Any) -> bool:
    """Returns whether an operand is known to reside in device memory."""
    return _get_memory_space(value) == "device"


def _cutlass_call_impl(
    fn: Callable[..., None],
    *,
    output_shape_dtype: Any,
    input_spec: Any,
    output_spec: Any,
    input_output_aliases: tuple[
        tuple[int | jax.tree_util.KeyPath, int | jax.tree_util.KeyPath], ...
    ],
    has_side_effect: bool,
    allow_cuda_graph: bool | None,
    ffi_call_target: str,
    no_cuda_graph_ffi_call_target: str,
    ffi_abi_version: int,
    compile_options: str | None,
    compile_key: Hashable | None,
    use_static_tensors: bool,
    vmap_method: _VmapMethod,
    **kwargs: Any,
) -> Callable[..., Any]:
    # A single ShapeDtypeStruct means one output; a sequence means multiple.
    multiple_results = isinstance(output_shape_dtype, Sequence)
    if not multiple_results:
        output_shape_dtype = (output_shape_dtype,)
    output_shape_dtype_flat, output_tree = jax.tree.flatten(output_shape_dtype)
    lowering_target = _KernelLoweringTarget(fn, compile_key)

    @jax.jit
    def call_wrapper(*args: Any) -> Any:
        args_flat, args_tree = jax.tree.flatten(args)

        input_spec_flat = _resolve_input_spec_flat(input_spec, args, args_flat)
        output_spec_flat = _resolve_spec_flat(output_spec, output_shape_dtype_flat)

        _validate_specs("Input", args_flat, input_spec_flat)
        _validate_specs("Output", output_shape_dtype_flat, output_spec_flat)
        capture = (
            all(_is_device_tensor(value) for value in args_flat)
            if allow_cuda_graph is None
            else allow_cuda_graph
        )
        spec = build_function_spec(
            args_flat,
            args_tree,
            output_shape_dtype_flat,
            output_tree,
            input_spec_flat,
            output_spec_flat,
            dict(input_output_aliases),
            compile_options,
            use_static_tensors,
            kwargs,
            ffi_call_target=(
                ffi_call_target if capture else no_cuda_graph_ffi_call_target
            ),
            ffi_abi_version=ffi_abi_version,
            has_side_effect=has_side_effect,
        )

        output_flat = cutlass_call_inner_p.bind(
            *args_flat,
            lowering_target=lowering_target,
            spec=spec,
            output_shape_dtype_flat=tuple(output_shape_dtype_flat),
            vmap_method=vmap_method,
        )

        output = jax.tree.unflatten(output_tree, output_flat)
        return output if multiple_results else output[0]

    return call_wrapper


@cutlass_call_inner_p.def_effectful_abstract_eval
def cutlass_call_inner_p_abstract(
    *_: Any, output_shape_dtype_flat: Any, spec: FunctionSpec, **__: Any
) -> tuple[list[Any], set[jax_core.Effect]]:
    outputs = [jax.core.ShapedArray(x.shape, x.dtype) for x in output_shape_dtype_flat]
    return outputs, {_CUTLASS_CALL_EFFECT} if spec.has_side_effect else set()


def _cutlass_call_inner_p_impl(
    *args_flat: Any,
    lowering_target: _KernelLoweringTarget,
    spec: FunctionSpec,
    output_shape_dtype_flat: tuple[Any, ...],
    vmap_method: _VmapMethod,
) -> Any:
    del vmap_method
    kernel = get_or_compile_kernel(
        lowering_target.fn,
        spec,
        compile_key=lowering_target.user_compile_key,
    )

    # Convert explicit layout constraints from CuTeDSL to JAX order. ``None`` is
    # passed through intentionally: jax.ffi.ffi_call treats it as default
    # row-major layout.
    input_layouts = [cutlass_to_jax_layout_order(s.layout) for s in spec.input_spec]
    output_layouts = [cutlass_to_jax_layout_order(s.layout) for s in spec.output_spec]

    workspace_shape_dtypes = tuple(
        jax.ShapeDtypeStruct((max(requirement.size_in_bytes, 1),), jnp.uint8)
        for requirement in kernel.workspace_requirements
    )
    ffi_result_shape_dtypes = output_shape_dtype_flat + workspace_shape_dtypes
    ffi_output_layouts = output_layouts + [(0,)] * len(workspace_shape_dtypes)

    if workspace_shape_dtypes and spec.ffi_abi_version < 3:
        raise ValueError(
            "Compiler-managed device workspace requires the CuTeDSL v3 FFI "
            f"call ABI; got v{spec.ffi_abi_version}"
        )

    ffi_attributes = {"module": kernel.module, "key": kernel.fingerprint}
    if spec.ffi_abi_version >= 3:
        ffi_attributes["ffi_abi_version"] = spec.ffi_abi_version
        ffi_attributes["num_workspace_outputs"] = len(workspace_shape_dtypes)

    fun = jax.ffi.ffi_call(
        spec.ffi_call_target,
        result_shape_dtypes=ffi_result_shape_dtypes,
        input_output_aliases=dict(spec.input_output_aliases),
        input_layouts=input_layouts,
        output_layouts=ffi_output_layouts,
        has_side_effect=spec.has_side_effect,
    )

    results = fun(*args_flat, **ffi_attributes)
    if not workspace_shape_dtypes:
        return results
    return results[: len(output_shape_dtype_flat)]


def _cutlass_call_jvp_rule(*args: Any, **kwargs: Any) -> None:
    del args, kwargs
    raise NotImplementedError(
        "cutlass_call does not support VJP. Please use `jax.custom_jvp` for taking gradients."
    )


ad.primitive_jvps[cutlass_call_inner_p] = _cutlass_call_jvp_rule


def _cutlass_call_transpose_rule(*args: Any, **kwargs: Any) -> None:
    del args, kwargs
    raise NotImplementedError(
        "cutlass_call does not support transpose. Please use `jax.custom_vjp` for taking gradients."
    )


ad.primitive_transposes[cutlass_call_inner_p] = _cutlass_call_transpose_rule


def _prepend_vmap_axis_to_spec(spec: TensorSpec, rank: int) -> TensorSpec:
    """Prepend a major physical dimension and leading logical mode to a spec."""
    if _is_value_cast(spec.cast):
        raise ValueError(
            "Scalar casts cannot acquire a native vmap dimension; "
            "use vmap_method='sequential' or 'sequential_unrolled'"
        )
    layout = None if spec.layout is None else (rank, *spec.layout)
    mode = None if spec.mode is None else (0, *(axis + 1 for axis in spec.mode))
    divisibility = spec.divisibility
    if isinstance(divisibility, tuple):
        divisibility = (None, *divisibility)
    return replace(spec, layout=layout, mode=mode, divisibility=divisibility)


def _concrete_axis_size(axis_size: Any) -> int | None:
    try:
        return operator.index(axis_size)
    except TypeError:
        return None


def _prepend_vmap_axis_to_arg(arg: Arg, axis_size: Any) -> Arg:
    """Return an argument descriptor with a leading batch dimension."""
    return replace(
        arg,
        shape=(axis_size, *arg.shape),
        spec=_prepend_vmap_axis_to_spec(arg.spec, len(arg.shape)),
    )


def _batch_function_spec(
    spec: FunctionSpec,
    input_axis_sizes: Sequence[Any],
    output_axis_size: Any,
) -> FunctionSpec:
    """Lift a kernel specification for one native batching dimension."""
    if len(input_axis_sizes) != len(spec.in_args):
        raise ValueError(
            "Expected one vmap axis size per input; got "
            f"{len(input_axis_sizes)} sizes for {len(spec.in_args)} inputs."
        )
    in_args = tuple(
        _prepend_vmap_axis_to_arg(arg, axis_size)
        for arg, axis_size in zip(spec.in_args, input_axis_sizes)
    )
    out_args = tuple(
        _prepend_vmap_axis_to_arg(arg, output_axis_size) for arg in spec.out_args
    )
    return replace(
        spec,
        in_args=in_args,
        out_args=out_args,
        input_spec=tuple(arg.spec for arg in in_args),
        output_spec=tuple(arg.spec for arg in out_args),
    )


def _bind_cutlass_call_inner(
    args: Sequence[Any],
    *,
    lowering_target: _KernelLoweringTarget,
    spec: FunctionSpec,
    output_shape_dtype_flat: tuple[Any, ...],
    vmap_method: _VmapMethod,
) -> list[Any]:
    """Bind the inner primitive while preserving all lowering parameters."""
    return cutlass_call_inner_p.bind(
        *args,
        lowering_target=lowering_target,
        spec=spec,
        output_shape_dtype_flat=output_shape_dtype_flat,
        vmap_method=vmap_method,
    )


def _sequential_vmap(
    args: Sequence[Any],
    dims: Sequence[int | None],
    *,
    unroll: bool,
    lowering_target: _KernelLoweringTarget,
    spec: FunctionSpec,
    output_shape_dtype_flat: tuple[Any, ...],
    vmap_method: _VmapMethod,
) -> tuple[list[Any], tuple[int, ...]]:
    """Batch by scanning the unchanged kernel over mapped input slices."""
    mapped = tuple(dim is not None for dim in dims)
    mapped_args = tuple(arg for arg, is_mapped in zip(args, mapped) if is_mapped)
    unmapped_args = tuple(arg for arg, is_mapped in zip(args, mapped) if not is_mapped)

    def scan_body(_: None, mapped_values: Sequence[Any]) -> tuple[None, list[Any]]:
        mapped_values = iter(mapped_values)
        unmapped_values = iter(unmapped_args)
        call_args = tuple(
            next(mapped_values) if is_mapped else next(unmapped_values)
            for is_mapped in mapped
        )
        return None, _bind_cutlass_call_inner(
            call_args,
            lowering_target=lowering_target,
            spec=spec,
            output_shape_dtype_flat=output_shape_dtype_flat,
            vmap_method=vmap_method,
        )

    _, outputs = jax.lax.scan(scan_body, None, mapped_args, unroll=unroll)
    return outputs, (0,) * len(output_shape_dtype_flat)


def _native_vmap(
    args: Sequence[Any],
    dims: Sequence[int | None],
    axis_size: Any,
    *,
    broadcast_unmapped: bool,
    lowering_target: _KernelLoweringTarget,
    spec: FunctionSpec,
    output_shape_dtype_flat: tuple[Any, ...],
    vmap_method: _VmapMethod,
) -> tuple[list[Any], tuple[int, ...]]:
    """Batch with one kernel whose public tensors gain a leading dimension."""
    if not broadcast_unmapped and _concrete_axis_size(axis_size) != 1:
        for input_index, _ in spec.input_output_aliases:
            if dims[input_index] is None:
                raise ValueError(
                    "vmap_method='expand_dims': unmapped input "
                    f"#{input_index} cannot be aliased to a batched output unless "
                    "the mapped axis size is statically 1."
                )

    input_axis_sizes = tuple(
        axis_size if dim is not None or broadcast_unmapped else 1 for dim in dims
    )
    batched_args = tuple(
        arg
        if dim is not None
        else (
            jnp.broadcast_to(arg, (axis_size, *arg.shape))
            if broadcast_unmapped
            else jnp.expand_dims(arg, 0)
        )
        for arg, dim in zip(args, dims)
    )
    batched_spec = _batch_function_spec(spec, input_axis_sizes, axis_size)
    batched_outputs = tuple(
        jax.ShapeDtypeStruct((axis_size, *output.shape), output.dtype)
        for output in output_shape_dtype_flat
    )
    outputs = _bind_cutlass_call_inner(
        batched_args,
        lowering_target=lowering_target,
        spec=batched_spec,
        output_shape_dtype_flat=batched_outputs,
        vmap_method=vmap_method,
    )
    return outputs, (0,) * len(batched_outputs)


def _cutlass_call_vmap_rule(
    args: Sequence[Any],
    dims: Sequence[int | None],
    *,
    lowering_target: _KernelLoweringTarget,
    spec: FunctionSpec,
    output_shape_dtype_flat: tuple[Any, ...],
    vmap_method: _VmapMethod,
) -> tuple[list[Any], tuple[int, ...]]:
    """Apply the explicitly selected batching semantics to ``cutlass_call``."""
    mapped_axis_sizes = {
        arg.shape[dim] for arg, dim in zip(args, dims) if dim is not None
    }
    if len(mapped_axis_sizes) != 1:
        raise ValueError(
            "All mapped cutlass_call inputs must have the same vmap axis size; "
            f"got {tuple(mapped_axis_sizes)}."
        )
    axis_size = next(iter(mapped_axis_sizes))
    args = tuple(
        arg if dim is None or dim == 0 else jnp.moveaxis(arg, dim, 0)
        for arg, dim in zip(args, dims)
    )

    if vmap_method is None:
        raise NotImplementedError(
            "cutlass_call does not support batching with jax.vmap unless "
            f"'vmap_method' is one of {_VMAP_METHODS}."
        )
    if vmap_method in ("sequential", "sequential_unrolled"):
        if (
            vmap_method == "sequential_unrolled"
            and _concrete_axis_size(axis_size) is None
        ):
            raise ValueError(
                "vmap_method='sequential_unrolled' requires a concrete mapped "
                f"axis size; got {axis_size}."
            )
        return _sequential_vmap(
            args,
            dims,
            unroll=vmap_method == "sequential_unrolled",
            lowering_target=lowering_target,
            spec=spec,
            output_shape_dtype_flat=output_shape_dtype_flat,
            vmap_method=vmap_method,
        )
    if vmap_method in ("expand_dims", "broadcast_all"):
        return _native_vmap(
            args,
            dims,
            axis_size,
            broadcast_unmapped=vmap_method == "broadcast_all",
            lowering_target=lowering_target,
            spec=spec,
            output_shape_dtype_flat=output_shape_dtype_flat,
            vmap_method=vmap_method,
        )
    raise AssertionError(f"Unexpected vmap method: {vmap_method!r}")


batching.primitive_batchers[cutlass_call_inner_p] = _cutlass_call_vmap_rule

jax._src.dispatch.simple_impl(cutlass_call_inner_p)
jax._src.dispatch.prim_requires_devices_during_lowering.add(cutlass_call_inner_p)
_cutlass_call_inner_p_lowering = mlir.lower_fun(
    _cutlass_call_inner_p_impl, multiple_results=True
)
if jax.version.__version_info__ >= (0, 7, 0):
    mlir.register_lowering(
        cutlass_call_inner_p,
        _cutlass_call_inner_p_lowering,
        platform="cuda",
        inline=False,
    )
else:
    # JAX 0.7 added cached out-of-line primitive lowerings.
    mlir.register_lowering(
        cutlass_call_inner_p,
        _cutlass_call_inner_p_lowering,
        platform="cuda",
    )
