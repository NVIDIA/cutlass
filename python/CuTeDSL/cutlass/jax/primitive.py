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

from typing import Any, Sequence, Callable
import logging


import jax
import jax.extend
from jax.interpreters import mlir
from jax._src.interpreters import ad
from jax._src.interpreters import batching


from .compile import get_or_compile_kernel, build_function_spec
from .types import cutlass_to_jax_layout_order, default_tensor_spec, TensorSpec
from .ffi import get_cutlass_call_ffi_name, is_ffi_registered, register_ffi


logger = logging.getLogger(__name__)

cutlass_call_inner_p = jax.extend.core.Primitive("cutlass_call_inner")
cutlass_call_inner_p.multiple_results = True


def cutlass_call(
    fn: Callable[..., None],
    *,
    output_shape_dtype: Any = None,
    input_spec: Any = None,
    output_spec: Any = None,
    input_mode: Any = None,
    output_mode: Any = None,
    input_output_aliases=None,
    allow_cuda_graph=True,
    compile_options=None,
    use_static_tensors=False,
    **kwargs,
):
    """Create a callable that invokes a ``@cute.jit`` function from JAX.

    Returns a callable that accepts JAX arrays and dispatches to *fn* as part
    of a ``jax.jit``-compiled computation.  The kernel is compiled once on the
    first call and cached for subsequent invocations with the same shapes and
    specs.

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
            output buffer.
        input_spec: A :class:`TensorSpec` or list thereof providing
            layout/mode/divisibility hints for input tensors.  ``None`` infers
            defaults from each array.
        output_spec: Same as *input_spec* but applied to output tensors.
        input_output_aliases: ``{input_index: output_index}`` mapping that
            allows an input buffer to alias an output, avoiding an extra copy.
            Indices are into the flattened input and output pytrees.
        allow_cuda_graph: If ``False``, prevents XLA from capturing this call
            in a CUDA graph.  Defaults to ``True``.
        compile_options: Optional dict of compiler flags forwarded to
            ``cute.compile``.
        use_static_tensors: If ``True``, tensor shapes and strides are baked in
            as compile-time constants, improving performance when shapes are
            fixed across calls.  Defaults to ``False``.
        **kwargs: Additional keyword arguments forwarded to *fn* as compile-time
            constants.

    Returns:
        A callable ``(*arrays) -> output_pytree`` that can be used inside
        ``jax.jit``.

    Note:
        This API is experimental and subject to change.
    """
    if output_shape_dtype is None:
        raise ValueError("'output_shape_dtype' must be specified.")

    output_shape_dtype = jax.tree.map(
        lambda leaf: jax.ShapeDtypeStruct(leaf.shape, leaf.dtype), output_shape_dtype
    )

    if input_output_aliases is None:
        input_output_aliases = {}

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

    return _cutlass_call_impl(
        fn,
        output_shape_dtype=output_shape_dtype,
        input_spec=input_spec,
        output_spec=output_spec,
        input_output_aliases=input_output_aliases,
        allow_cuda_graph=allow_cuda_graph,
        compile_options=compile_options,
        use_static_tensors=use_static_tensors,
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


def _validate_specs(label: str, tensors: list, specs: tuple[TensorSpec, ...]) -> None:
    """Validate that each spec's rank-dependent fields match the corresponding tensor shape."""
    for idx, (tensor, spec) in enumerate(zip(tensors, specs)):
        ndim = len(tensor.shape)
        if spec.layout is not None and len(spec.layout) != ndim:
            raise ValueError(
                f"{label} #{idx} has invalid layout {spec.layout} for shape {tensor.shape}."
            )
        if spec.mode is not None and len(spec.mode) != ndim:
            raise ValueError(
                f"{label} #{idx} has invalid mode {spec.mode} for shape {tensor.shape}."
            )
        if (
            spec.divisibility is not None
            and not isinstance(spec.divisibility, int)
            and len(spec.divisibility) != ndim
        ):
            raise ValueError(
                f"{label} #{idx} has invalid divisibility {spec.divisibility} for shape {tensor.shape}."
            )


def _cutlass_call_impl(
    fn,
    *,
    output_shape_dtype: Any,
    input_spec: Any,
    output_spec: Any,
    input_output_aliases,
    allow_cuda_graph,
    compile_options,
    use_static_tensors,
    **kwargs,
):
    # A single ShapeDtypeStruct means one output; a sequence means multiple.
    multiple_results = isinstance(output_shape_dtype, Sequence)
    if not multiple_results:
        output_shape_dtype = (output_shape_dtype,)
    output_shape_dtype_flat, output_tree = jax.tree.flatten(output_shape_dtype)

    @jax.jit
    def call_wrapper(*args):
        args_flat, args_tree = jax.tree.flatten(args)

        input_spec_flat = _resolve_spec_flat(input_spec, args_flat)
        output_spec_flat = _resolve_spec_flat(output_spec, output_shape_dtype_flat)

        _validate_specs("Input", args_flat, input_spec_flat)
        _validate_specs("Output", output_shape_dtype_flat, output_spec_flat)

        output_flat = cutlass_call_inner_p.bind(
            *args_flat,
            fn=fn,
            args_tree=args_tree,
            output_shape_dtype_flat=tuple(output_shape_dtype_flat),
            output_tree=output_tree,
            input_spec_flat=input_spec_flat,
            output_spec_flat=output_spec_flat,
            input_output_aliases=tuple(input_output_aliases.items()),
            allow_cuda_graph=allow_cuda_graph,
            compile_options=compile_options,
            use_static_tensors=use_static_tensors,
            **kwargs,
        )

        output = jax.tree.unflatten(output_tree, output_flat)
        return output if multiple_results else output[0]

    return call_wrapper


@cutlass_call_inner_p.def_abstract_eval
def cutlass_call_inner_p_abstract(*_, output_shape_dtype_flat, **__):
    return [jax.core.ShapedArray(x.shape, x.dtype) for x in output_shape_dtype_flat]


def cutlass_call_inner_p_impl(
    *args_flat,
    fn,
    args_tree: Any,
    output_shape_dtype_flat: Any,
    output_tree: Any,
    input_spec_flat: Any,
    output_spec_flat: Any,
    input_output_aliases,
    allow_cuda_graph,
    compile_options,
    use_static_tensors,
    **kwargs,
):
    input_output_aliases = dict(input_output_aliases)
    spec = build_function_spec(
        args_flat,
        args_tree,
        output_shape_dtype_flat,
        output_tree,
        input_spec_flat,
        output_spec_flat,
        input_output_aliases,
        compile_options,
        use_static_tensors,
        kwargs,
    )

    kernel = get_or_compile_kernel(fn, spec)

    # Ensure our FFI target is registered. We do this lazily here
    # so that we only load the dependant library if needed.
    if not is_ffi_registered():
        register_ffi()

    call_name = get_cutlass_call_ffi_name(allow_cuda_graph)

    # Convert layout from CuTeDSL to JAX order as ffi_call expects this.
    input_layouts = [cutlass_to_jax_layout_order(s.layout) for s in input_spec_flat]
    output_layouts = [cutlass_to_jax_layout_order(s.layout) for s in output_spec_flat]

    fun = jax.ffi.ffi_call(
        call_name,
        result_shape_dtypes=output_shape_dtype_flat,
        input_output_aliases=dict(spec.input_output_aliases),
        input_layouts=input_layouts,
        output_layouts=output_layouts,
    )

    return fun(*args_flat, module=kernel.module, key=kernel.fingerprint)


def _cutlass_call_jvp_rule(*args, **kwargs):
    del args, kwargs
    raise NotImplementedError(
        "cutlass_call does not support VJP. Please use `jax.custom_jvp` for taking gradients."
    )


ad.primitive_jvps[cutlass_call_inner_p] = _cutlass_call_jvp_rule


def _cutlass_call_transpose_rule(*args, **kwargs):
    del args, kwargs
    raise NotImplementedError(
        "cutlass_call does not support transpose. Please use `jax.custom_vjp` for taking gradients."
    )


ad.primitive_transposes[cutlass_call_inner_p] = _cutlass_call_transpose_rule


def _cutlass_call_vmap_rule(*args, **kwargs):
    del args, kwargs
    raise NotImplementedError(
        "cutlass_call does not support batching with jax.vmap. Please "
        "use jax.custom_batching.custom_vmap for applying vmap. "
    )


batching.primitive_batchers[cutlass_call_inner_p] = _cutlass_call_vmap_rule

jax._src.dispatch.simple_impl(cutlass_call_inner_p)
jax._src.dispatch.prim_requires_devices_during_lowering.add(cutlass_call_inner_p)
lowering = mlir.lower_fun(cutlass_call_inner_p_impl, multiple_results=True)
mlir.register_lowering(cutlass_call_inner_p, lowering, platform="cuda")
