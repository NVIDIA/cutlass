# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Any, Union, Sequence, Callable
from functools import partial
import logging
import os

import cuda.bindings.driver as cuda

import jax, jax.numpy as jnp
import jax.extend
from jax.interpreters import mlir
from jax._src.interpreters import ad
from jax._src.interpreters import batching
from jax._src import ffi
from jax.tree import flatten, unflatten

import cutlass

from .compile import get_or_compile_kernel, build_function_spec
from .types import row_major_layout, default_tensor_spec, TensorSpec
from .ffi import get_cutlass_call_ffi_name, is_ffi_registered, register_ffi

logger = logging.getLogger(__name__)

cutlass_call_inner_p = jax.extend.core.Primitive("cutlass_call_inner")
cutlass_call_inner_p.multiple_results = True


def cutlass_call(
    fn: Callable[..., None],
    *,
    output_shape_dtype: Any,
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
    """Creates a callable that invokes a @cute.jit function.

    Args:
        fn: A @cute.jit decorated function that launches a cutlass kernel.
        output_shape_dtype: A pytree representing the shape and dtype of the output buffers.
        input_output_aliases: Optional mapping of input to output aliases. Positions are specified assuming
            a flattened input and output pytree.
        input_spec: Specifies a cute.Tensor dimension order for input tensors. If None then the order
            will assume the corresponding layout order.
        output_spec: Specifies a cute.Tensor dimension order for output tensors. If None then the order
            will assume the corresponding layout order.
        input_mode: Legacy alias for input_spec. This parameter may be removed in future versions.
        output_spec: Legacy alias for output_spec. This parameter may be removed in future versions.
        allow_cuda_graph: If false will prevent XLA from building a cuda graph of for this call.
        compile_options: Optional compiler arguments to pass into cute.compile.
        use_static_tensors: If True, tensor shapes and strides are treated as constexpr values by
        default. This can improve performance through compiler specialization but may not work
        properly with all kernels. Specific tensors may be marked static or dynamic using the mode
        and override this flag.
        kwargs: Optional constexpr parameters to pass into the kernel fn.

    Note: This API is experimental and subject to change!
    """
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


def _normalize_tensor_spec(value: Any):
    if value is None:
        return [None]
    elif isinstance(value, (tuple, list)):
        if isinstance(value[0], int):  # single tuple of modes
            return TensorSpec(mode=tuple(value))
        else:
            flat, _ = jax.tree.flatten(
                [_normalize_tensor_spec(x) for x in value],
                is_leaf=lambda x: x is None or isinstance(x, TensorSpec),
            )
            return flat
    elif isinstance(value, TensorSpec):
        return [value]
    else:
        raise TypeError(f"Unexpected value for TensorMode {value} {type(value)}")


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
    multiple_results = isinstance(output_shape_dtype, Sequence)
    if not multiple_results:
        output_shape_dtype = (output_shape_dtype,)
    output_shape_dtype_flat, output_tree = jax.tree.flatten(output_shape_dtype)

    @partial(jax.jit, inline=True)
    def call_wrapper(*args):
        args_flat, args_tree = jax.tree.flatten(args)

        if input_spec is None:
            input_spec_flat = tuple(default_tensor_spec(x) for x in args_flat)
        else:
            input_spec_flat = _normalize_tensor_spec(input_spec)
            for idx, (spec, arg) in enumerate(zip(input_spec_flat, args_flat)):
                if spec is None:
                    input_spec_flat[idx] = default_tensor_spec(arg)
            input_spec_flat = tuple(input_spec_flat)

        if output_spec is None:
            output_spec_flat = tuple(
                default_tensor_spec(x) for x in output_shape_dtype_flat
            )
        else:
            output_spec_flat = _normalize_tensor_spec(output_spec)
            for idx, (spec, arg) in enumerate(
                zip(output_spec_flat, output_shape_dtype_flat)
            ):
                if spec is None:
                    output_spec_flat[idx] = default_tensor_spec(arg)
            output_spec_flat = tuple(output_spec_flat)
        if len(input_spec_flat) != len(args_flat):
            raise ValueError(
                f"Must has same number of input modes ({len(input_spec_flat)}) as input arrays ({len(args_flat)})."
            )

        if len(output_spec_flat) != len(output_shape_dtype_flat):
            raise ValueError(
                f"Must has same number of output modes ({len(output_spec_flat)}) as output arrays ({len(output_shape_dtype_flat)})."
            )

        # Validate dynamic mode settings match whatever static shape
        # information we got as input.
        for idx, (arg, spec) in enumerate(zip(args_flat, input_spec_flat)):
            if spec.layout is not None and len(spec.layout) != len(arg.shape):
                raise ValueError(
                    f"Input #{idx} has invalid layout {spec.layout} for shape {arg.shape}."
                )
            if spec.mode is not None and len(spec.mode) != len(arg.shape):
                raise ValueError(
                    f"Input #{idx} has invalid mode {spec.mode} for shape {arg.shape}."
                )

        for idx, (arg, spec) in enumerate(
            zip(output_shape_dtype_flat, output_spec_flat)
        ):
            if spec.layout is not None and len(spec.layout) != len(arg.shape):
                raise ValueError(
                    f"Output #{idx} has invalid layout {spec.layout} for shape {arg.shape}."
                )

            if spec.mode is not None and len(spec.mode) != len(arg.shape):
                raise ValueError(
                    f"Output #{idx} has invalid mode {spec.mode} for shape {arg.shape}."
                )

        output_flat = cutlass_call_inner_p.bind(
            *args_flat,
            fn=fn,
            args_tree=args_tree,
            output_shape_dtype_flat=tuple(output_shape_dtype_flat),
            output_tree=output_tree,
            input_spec_flat=tuple(input_spec_flat),
            output_spec_flat=tuple(output_spec_flat),
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
    fun = jax.ffi.ffi_call(
        call_name,
        result_shape_dtypes=output_shape_dtype_flat,
        input_output_aliases=dict(spec.input_output_aliases),
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
