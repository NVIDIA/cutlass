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
This module provides a DSL for Cutlass Dialects. It also includes utils with
regarding to that dialect.
"""

# Local module imports
from types import GenericAlias, SimpleNamespace, UnionType
from typing_extensions import deprecated
from typing import (
    Callable,
    Generator,
    Optional,
    Union,
    List,
    Tuple,
    Sequence,
    Iterable,
    ForwardRef,
    Any,
    get_origin,
    get_args,
)
import functools
import inspect
import pkgutil
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import fields
from math import ceil
from itertools import chain
from pathlib import Path
import builtins
import ctypes
import hashlib
import os
import re

from ..base_dsl import *
from ..base_dsl import compiler
from ..base_dsl.dsl import (
    is_dynamic_expression,
    extract_mlir_values,
    BaseDSL,
    new_from_mlir_values,
    implements_dynamic_expression,
)
from ..base_dsl.typing import *
from ..base_dsl.typing import (
    DynamicExpression,
    get_mlir_types,
    Int32,
    Int64,
    Int8,
    Integer,
    Boolean,
    Numeric,
    NumericMeta,
    DslType,
    as_numeric,
    get_c_pointers,
    cast,
)
from ..base_dsl.common import DSLRuntimeError, DSLNotImplemented
from ..base_dsl.utils.logger import log
from ..base_dsl.utils.tree_utils import (
    Leaf,
    PyTreeDef,
    tree_flatten,
    tree_unflatten,
    DSLTreeFlattenError,
    is_constexpr_field,
)
from ..base_dsl.leaf_utils import is_frozen_dataclass
from ..base_dsl.runtime.jit_arg_adapters import is_arg_annotation_constexpr
from ..base_dsl.jit_executor import ExecutionArgs  # noqa: F401
from ..base_dsl.runtime import cuda as cuda_helpers
from .cuda_stream_adapter import CudaDialectStreamAdapter
from .cuda_jit_executor import CudaDialectJitCompiledFunction

# MLIR Imports
from cutlass._mlir import ir, execution_engine, passmanager
from cutlass._mlir.dialects import (
    arith,
    func,
    gpu,
    scf,
    cute,
    gpu as cutlass_gpu,
    cuda as cuda_dialect,
)
from cutlass._mlir.dialects._ods_common import (
    get_op_result_or_op_results as _get_op_result_or_op_results,
)

try:
    from cutlass._mlir.dialects import lir as cutlass_lir
except ImportError:
    cutlass_lir = None

from cutlass._mlir.extras import types as T

# Helpers
from ..base_dsl._mlir_helpers import arith as cutlass_arith
from ..base_dsl._mlir_helpers import lru_cache_ir
from ..base_dsl._mlir_helpers.op import dsl_user_op
from ..base_dsl._mlir_helpers.arith import const

from ..base_dsl.ast_helpers import (
    loop_selector,
    executor,
    if_selector,
    if_executor,
    while_selector,
    while_executor,
    assert_executor,
    const_expr,
    dynamic_expr,
    bool_cast,
    compare_executor,
    range_value_check,
    cf_symbol_check,
)

from .cutlass_ast_decorators import (
    _loop_execute_range_dynamic,
    _if_execute_dynamic,
    _while_execute_dynamic,
    _ifexp_execute_dynamic,
    LoopUnroll,
)

from ..base_dsl.runtime.jit_arg_adapters import JitArgAdapterRegistry

# =============================================================================
# Cutlass DSL Device Info
# =============================================================================

# Contains a map of SM architecture to shared memory capacity in bytes
SMEM_CAPACITY_MAP = {
    "sm_121": (100 - 1) * 1024,
    "sm_120": (100 - 1) * 1024,
    "sm_110": (228 - 1) * 1024,
    "sm_103": (228 - 1) * 1024,
    "sm_101": (228 - 1) * 1024,
    "sm_100": (228 - 1) * 1024,
    "sm_90": (228 - 1) * 1024,
    "sm_89": (100 - 1) * 1024,
    "sm_86": (100 - 1) * 1024,
    "sm_87": (164 - 1) * 1024,
    "sm_80": (164 - 1) * 1024,
}

# =============================================================================
# Cutlass DSL Base Abstract Class
# =============================================================================


def _get_max_cpu_threads() -> int:
    """Return a safe thread-pool size: half of CPU count, clamped to [1, 16]."""
    return max(1, min(16, (os.cpu_count() or 8) // 2))


# Return a ctype class that represents the in-memory layout expected
# for a CuTe hierarchical tuple type.
def get_sparse_tuple_ctype(dyn: Union[int, Sequence[object]]) -> type:
    # When there is a single dynamic value, the sparse CuTe
    # representation is a single integer.
    if isinstance(dyn, int):
        return ctypes.c_int32

    dyn_seq: Sequence[object] = dyn

    # For zero or greater than 1 dynamic values, the tuple
    # representation will be a struct with a field for each dynamic
    # value. The representation is flattened, even for hierarchical CuTe
    # profiles (although we are only dealing with depth 1 inputs here).
    class TupleDescriptor(ctypes.Structure):
        _fields_ = [(f"x{idx}", ctypes.c_int32) for idx in range(len(dyn_seq))]

        def __str__(self) -> str:
            return f"struct<{str(self._fields_)}>"

    return TupleDescriptor


def is_cute_algebra_type(arg_spec: object) -> bool:
    # Walk through the arg_spec to check if it's a cute algebra type
    _cute_algebra_type_aliases = (
        "Shape",
        "Stride",
        "Coord",
        "Tile",
        "IntTuple",
    )

    origin = get_origin(arg_spec)
    if origin is Union:
        for sub_ty in get_args(arg_spec):
            sub_origin = get_origin(sub_ty)
            if sub_origin is Tuple or (
                type(sub_origin) is type and issubclass(sub_origin, tuple)
            ):
                tuple_arg0 = get_args(sub_ty)[0]
                if isinstance(
                    tuple_arg0, ForwardRef
                ) and tuple_arg0.__forward_arg__ in (_cute_algebra_type_aliases):
                    return True
    return False


def _build_kernel_attrs(config: BaseDSL.LaunchConfig) -> dict:
    kernel_attrs = {}
    if config.min_blocks_per_mp > 1:
        assert config.smem is not None
        kernel_attrs = {
            cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_PREFERRED_SHARED_MEMORY_CARVEOUT: ceil(
                config.min_blocks_per_mp
                * config.smem
                / cuda_helpers.get_device_attribute(
                    cuda_helpers.cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_MULTIPROCESSOR
                )
                * 100
            )
        }
    return kernel_attrs


class CutlassBaseDSL(BaseDSL):
    """This abstract class provides a DSL for Cutlass."""

    _ALLOWED_EXTRA_KERNEL_VALUE_ATTRS: frozenset[str] = frozenset()
    _KERNEL_ATTR_SPEC_FIELD: Optional[str] = None

    def __init__(
        self,
        name: str,
        compiler_provider: compiler.Compiler,
        pass_sm_arch_name: str,
        device_compilation_only: bool = False,
        preprocess: bool = False,
    ):
        super().__init__(
            name=name,
            dsl_package_name=["cutlass"],
            compiler_provider=compiler_provider,
            pass_sm_arch_name=pass_sm_arch_name,
            device_compilation_only=device_compilation_only,
            preprocess=preprocess,
        )
        self._smem_usage_tracker: Optional[tuple] = None
        # extra function to convert cute arguments to tvm ffi spec params
        # this needs to be reverse registered because the arg convention
        # depends on the runtime type of the DSL arguments
        self._tvm_ffi_args_spec_converter = None

    def _set_smem_tracking(
        self, allocator: object, callback: Callable[[object], int]
    ) -> None:
        self._smem_usage_tracker = (allocator, callback)

    def _reset_smem_tracking(self) -> None:
        self._smem_usage_tracker = None

    def _get_smem_usage(self) -> int:
        if not self._smem_usage_tracker:
            return 0
        allocator, callback = self._smem_usage_tracker
        return callback(allocator)

    # this method is not useful for cutlass_dsl, so we only provide a dummy implementation.
    def _is_tensor_descriptor(self, maybe_tensor_descriptor: object) -> bool:
        return False

    # this method is not useful for cutlass_dsl, so we only provide a dummy implementation.
    def _handle_tensor_descriptor(
        self, maybe_tensor: object, arg_name: str, need_gpu_memory: bool
    ) -> bool:
        return False

    def _collect_raw_kernel_attrs_from_decorator(
        self, func_body: Callable[..., None], func_args: tuple
    ) -> dict:
        field = self._KERNEL_ATTR_SPEC_FIELD
        if field is None:
            return {}
        attr_spec = getattr(func_body, field, None)
        if attr_spec is None:
            return {}

        if isinstance(attr_spec, dict):
            return attr_spec
        if callable(attr_spec):
            # Resolver signature: (owner, kernel_name) -> dict | None
            # *owner* is the first argument passed to the kernel (typically
            # ``self``), or ``None`` for free-function kernels.
            owner = func_args[0] if func_args else None
            resolved = attr_spec(owner, func_body.__name__)
            if resolved is None:
                return {}
            if not isinstance(resolved, dict):
                raise DSLRuntimeError(
                    "Kernel attribute resolver must return a dict or None.",
                    suggestion="Return a dict[str, str | ir.Attribute], or None for no attributes.",
                )
            return resolved

        raise DSLRuntimeError(
            f"Unsupported kernel decorator attributes spec type: {type(attr_spec)}",
            suggestion="Use a dict or a callable returning dict[str, str | ir.Attribute].",
        )

    def _collect_extra_kernel_value_attrs(
        self, func_body: Callable[..., None], func_args: tuple, func_kwargs: dict
    ) -> dict[str, ir.Attribute]:
        del func_kwargs
        raw_attrs = self._collect_raw_kernel_attrs_from_decorator(func_body, func_args)
        if not raw_attrs:
            return {}

        converted_attrs: dict[str, ir.Attribute] = {}
        for key, value in raw_attrs.items():
            if key not in self._ALLOWED_EXTRA_KERNEL_VALUE_ATTRS:
                allowed_keys = ", ".join(sorted(self._ALLOWED_EXTRA_KERNEL_VALUE_ATTRS))
                if allowed_keys:
                    suggestion = f"Use one of the allowed keys: {allowed_keys}."
                else:
                    suggestion = f"No extra kernel function attributes are supported for '{self.name}'."
                raise DSLRuntimeError(
                    f"Unsupported kernel function attribute key '{key}'.",
                    suggestion=suggestion,
                )
            if isinstance(value, ir.Attribute):
                converted_attrs[key] = value
            elif isinstance(value, str):
                converted_attrs[key] = ir.StringAttr.get(value)
            else:
                raise DSLRuntimeError(
                    f"Unsupported kernel function attribute value type for '{key}': {type(value)}",
                    suggestion="Use str or ir.Attribute as the attribute value.",
                )
        return converted_attrs

    def _build_gpu_module(
        self, attrs: dict[str, str], loc: Optional[ir.Location] = None
    ) -> None:
        log().info(f"self : {self}")
        log().info(f"Building GPU module for {self.name}")
        self.gpu_module = gpu.GPUModuleOp(ir.StringAttr.get("kernels"), loc=loc)
        log().info(f"GPU module: {self.gpu_module}")
        with ir.InsertionPoint(self.gpu_module.bodyRegion.blocks.append(*[])):
            pass

        for attr_name in attrs:
            self.gpu_module.attributes[attr_name] = ir.Attribute.parse(attrs[attr_name])

    def _get_pipeline(self, pipeline: Optional[str]) -> str:
        pipeline = super()._get_pipeline(pipeline)
        if pipeline is None:
            # cubin format is required to be cubin as we launch cuda module at python level.
            return (
                "builtin.module(cute-to-nvvm{cubin-format=bin "
                + self.compile_options.to_str()
                + "})"
            )

        return pipeline

    def preprocess_pipeline(self, pipeline: str, arch: str) -> str:
        pipeline = super().preprocess_pipeline(pipeline, arch)
        pipeline = (
            pipeline.rstrip("})")
            + " enable-cuda-dialect=true cuda-dialect-external-module=true})"
        )
        return pipeline

    def _enter_gpu_module(self) -> ir.InsertionPoint:
        log().info(f"self: {self}")
        log().info(f"Entering GPU module for {self.name}")
        log().info(f"GPU module: {self.gpu_module}")
        return ir.InsertionPoint(self.gpu_module.bodyRegion.blocks[0])

    @staticmethod
    def generate_func_ret_op(
        loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
    ) -> None:
        raise NotImplementedError(
            "generate_func_ret_op() must be implemented by subclasses."
        )

    @staticmethod
    def generate_func_op(
        arg_types: List[ir.Type],
        arg_attrs: Optional[List[ir.Attribute]],
        kernel_name: str,
        loc: Optional[ir.Location] = None,
    ) -> ir.Operation:
        raise NotImplementedError(
            "generate_func_op() must be implemented by subclasses."
        )

    def _generate_kernel_attrs(self, config: BaseDSL.LaunchConfig) -> dict:
        assert isinstance(config, BaseDSL.LaunchConfig), (
            f"Expect LaunchConfig for @kernel, but got {type(config)}"
        )

        ret = {}
        if config.has_max_number_threads():
            block_str = ", ".join(map(str, config.block))
            has_dynamic = any(is_dynamic_expression(dim) for dim in config.block)
            if not has_dynamic:
                # Case 1. Auto-generate reqntid from block size
                ret["nvvm.reqntid"] = ir.Attribute.parse(f"array<i32 : {block_str}>")
            else:
                # Case 2. Don't auto-generate reqntid from block size
                self.print_warning_once(
                    f"Dynamic variable in block size {block_str}, cannot auto-generate `nvvm.reqntid`"
                )
        else:
            # Case 3. Use user-defined value for maxntid
            max_ntid_str = ", ".join(map(str, config.max_number_threads))
            for value in config.max_number_threads:
                if is_dynamic_expression(value):
                    raise DSLRuntimeError(
                        f"User defined max number threads `{max_ntid_str}` contains dynamic expression, cannot generate `nvvm.maxntid`",
                        suggestion="Consider using `Constexpr` annotation or Python constant",
                    )
            # Use user-defined maxntid
            ret["nvvm.maxntid"] = ir.Attribute.parse(f"array<i32 : {max_ntid_str}>")

        # Add optional minimum blocks per multiprocessor
        if config.min_blocks_per_mp > 0:
            ret["nvvm.minctasm"] = ir.Attribute.parse(
                f"{config.min_blocks_per_mp} : i32"
            )

        return ret

    @functools.lru_cache(maxsize=1)
    def get_version(self) -> Any:
        """
        Get the version of cutlass dsl, used for computing the hash key of the cache.
        Including source python files and the shared library.
        """

        def _hash_chunk(
            key: str, path: str, idx: int, start: int, size: int
        ) -> tuple[str, int, bytes]:
            """Hash one chunk of a file with SHA-256."""
            h = hashlib.sha256()
            if size > 0:
                try:
                    with open(path, "rb") as f:
                        f.seek(start)
                        h.update(f.read(size))
                except Exception as e:
                    raise DSLRuntimeError(
                        f"Failed to read module file {key}."
                        "The file may not exist or may not be readable."
                        "Please re-install the package."
                    ) from e
            return key, idx, h.digest()

        def _iter_jobs() -> Generator:
            """Chunk jobs generator to hash files in parallel"""
            for key, path, size in files:
                # empty files still get a deterministic hash from SHA-256 of zero bytes
                for i in range(max(1, -(-size // chunk_size))):  # ceil division
                    start = i * chunk_size
                    computed_size = min(chunk_size, max(size - start, 0))
                    yield (key, path, i, start, computed_size)

        dsl_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        files = []

        mlir_libs_candidates = [
            Path(dsl_path) / "_mlir" / "_mlir_libs",
        ]
        try:
            import cutlass._mlir as _mlir_module

            if hasattr(_mlir_module, "__path__"):
                for p in _mlir_module.__path__:
                    mlir_libs_candidates.append(Path(p) / "_mlir_libs")
        except (ImportError, AttributeError):
            pass
        mlir_libs_path = None
        for candidate in mlir_libs_candidates:
            if candidate.exists():
                mlir_libs_path = candidate
                break
        if mlir_libs_path is None:
            raise DSLRuntimeError(
                "Could not find _mlir/_mlir_libs directory. "
                "Please re-install the package."
            )
        giant_dso_name = str(next(mlir_libs_path.glob("_cutlass_ir.cpython*")).name)
        so_path = str(mlir_libs_path / giant_dso_name)
        try:
            # update the version hash of the cutlass shared library
            so_size = os.path.getsize(so_path)
        except Exception as e:
            raise DSLRuntimeError(
                f"Failed to read the shared library file {giant_dso_name}."
                "The file may not exist or may not be readable."
                "Please re-install the package."
            ) from e
        files.append((giant_dso_name, so_path, so_size))

        for lib in pkgutil.walk_packages([dsl_path], prefix="cutlass."):
            spec = lib.module_finder.find_spec(lib.name)  # type: ignore[call-arg]
            if not spec or not spec.origin:
                continue
            path = spec.origin
            try:
                size = os.path.getsize(path)
            except Exception as e:
                raise DSLRuntimeError(
                    f"Failed to read module file {lib.name}. The file may not exist or may not be readable."
                    "Please re-install the package."
                ) from e
            files.append((lib.name, path, size))

        # Submit chunks to a job queue
        chunk_size = 1 << 24  # 16 MB (tuned)
        per_file_chunks: dict[str, list] = {}
        max_workers = _get_max_cpu_threads()
        with ThreadPoolExecutor(max_workers=max_workers) as ex:
            futures = [ex.submit(_hash_chunk, *job) for job in _iter_jobs()]
            for fut in as_completed(futures):
                key, idx, digest = fut.result()
                per_file_chunks.setdefault(key, []).append((idx, digest))

        # update the version hash of the cutlass shared library using tree-hash
        version_hash = hashlib.sha256()
        # Since files list is in arbitrary order, we sort by key to get deterministic order
        for key, path, size in sorted(files, key=lambda t: t[0]):
            chunks = per_file_chunks.get(key)
            assert chunks is not None
            file_hash = hashlib.sha256(
                b"".join(
                    digest
                    for _, digest in sorted(
                        chunks
                    )  # Similarily, sort chunks by index to get deterministic order
                )
            )
            file_hash.update(key.encode("utf-8"))
            version_hash.update(file_hash.digest())

        return version_hash

    def get_return_types(self) -> List[ir.Type]:
        """
        Get the return types of the function.
        With cuda dialect, the return type is i32 to indicate cuda result.
        """
        i32_ty = ir.IntegerType.get_signless(32)
        return [i32_ty]

    def generate_default_return_values(
        self, ip: Optional[ir.InsertionPoint] = None
    ) -> List[ir.Value]:
        """
        Generate the default return values of the function.
        With cuda dialect, the default return value is 0 to indicate success.
        """
        if ip is None:
            raise DSLRuntimeError("ip is required to generate default return values")
        return_types = self.get_return_types()
        if len(return_types) != 1:
            raise DSLRuntimeError(
                f"Expected exactly one return type, but got {len(return_types)}"
            )
        return_type = return_types[0]
        with ip:
            zero = arith.ConstantOp(return_type, 0).result
        return [zero]

    def compile_and_cache(
        self,
        module: ir.Module,
        module_hash: str,
        function_name: str,
        pipeline: Optional[str],
        signature: inspect.Signature,
        no_cache: bool,
        no_jit_engine: bool,
        func_type: type = CudaDialectJitCompiledFunction,
        *,
        full_args: Optional[tuple] = None,
        full_kwargs: Optional[dict] = None,
        dynamic_args: Optional[list] = None,
        dynamic_kwargs: Optional[dict] = None,
        original_function_name: Optional[str] = None,
        funcBody: Optional[Callable[..., None]] = None,
    ) -> CudaDialectJitCompiledFunction:
        """
        Compile the module and cache the result.

        :param module: The MLIR module to compile.
        :param module_hash: The hash of the MLIR module.
        :param function_name: The name of the function to compile.
        :param pipeline: The pipeline to use for compilation.
        :param signature: The signature of the function to compile.
        :param no_cache: Whether to cache the result.
        :param no_jit_engine: Whether to create JIT execution engine.
        :param full_args: The full arguments to use for compilation.
        :param full_kwargs: The full keyword arguments to use for compilation.
        :param dynamic_args: The dynamic arguments to use for compilation.
        :param dynamic_kwargs: The dynamic keyword arguments to use for compilation.
        :param original_function_name: The name of the original function without mangling.
        :return: The compiled function.
        """
        if self.compile_options.enable_tvm_ffi:
            # TVM FFI post compile logic
            # attach extra ABI function to the MLIR module
            from .tvm_ffi_provider import (
                TVMFFIJitCompiledFunction,
                TVMFFIJitCompiledFunctionWithKwargs,
                TVMFFICuteCallProvider,
            )
            from cutlass.base_dsl.tvm_ffi_builder import attach_ffi_func

            assert self._tvm_ffi_args_spec_converter is not None
            tvm_ffi_spec_params, kwargs_wrapper_spec = (
                self._tvm_ffi_args_spec_converter(
                    function_name, signature, full_args, full_kwargs
                )
            )
            tvm_ffi_provider = TVMFFICuteCallProvider(
                function_name, has_gpu_module=self.num_kernels > 0
            )

            # ensure we run the postprocessor hook after the compiler has run its passes
            def post_compile_hook(module: ir.Module) -> None:
                with module.context, module.operation.location:
                    # attach the tvm ffi function to the mlir module
                    attach_ffi_func(
                        module,
                        function_name,
                        tvm_ffi_spec_params,
                        tvm_ffi_provider,
                        fn_display_name=original_function_name,
                    )
                module.operation.verify()

            def _make_compiled_func(*args: Any, **kwargs: Any) -> Any:
                if kwargs_wrapper_spec.kwonly_names or kwargs_wrapper_spec.arg_defaults:
                    return TVMFFIJitCompiledFunctionWithKwargs(
                        *args, **kwargs, kwargs_wrapper_spec=kwargs_wrapper_spec
                    )
                else:
                    return TVMFFIJitCompiledFunction(*args, **kwargs)

            # ensure the compiler can run post-compile hook after its passes
            # the context will restore the previous post-compile hook after it exits
            with compiler.PostCompileHookContext(
                self.compiler_provider, post_compile_hook
            ):
                return super().compile_and_cache(
                    module,
                    module_hash,
                    function_name,
                    pipeline,
                    signature,
                    no_cache,
                    no_jit_engine,
                    _make_compiled_func,
                    full_args=full_args,
                    full_kwargs=full_kwargs,
                    dynamic_args=dynamic_args,
                    dynamic_kwargs=dynamic_kwargs,
                    funcBody=funcBody,
                )

        return super().compile_and_cache(  # type: ignore[return-value]
            module,
            module_hash,
            function_name,
            pipeline,
            signature,
            no_cache,
            no_jit_engine,
            CudaDialectJitCompiledFunction,
            full_args=full_args,
            full_kwargs=full_kwargs,
            dynamic_args=dynamic_args,
            dynamic_kwargs=dynamic_kwargs,
            original_function_name=original_function_name,
            funcBody=funcBody,
        )

    @staticmethod
    def track_smem_allocator(
        allocator: object, callback: Callable[[object], int]
    ) -> None:
        """
        Tracks shared memory usage for kernel functions.
        Find and set allocator to its parent dsl object.
        """
        frame = inspect.currentframe().f_back  # type: ignore[union-attr]
        while frame:
            obj = frame.f_locals.get("self", None)
            if obj and isinstance(obj, CutlassBaseDSL):
                obj._set_smem_tracking(allocator, callback)
                return
            frame = frame.f_back
        warnings.warn("Cannot find parent dsl for allocator!", UserWarning)

    def _set_smem_tracking(  # type: ignore[no-redef]
        self, allocator: object, callback: Callable[[object], int]
    ) -> None:
        # Registers an allocator and callback for current dsl
        self._smem_usage_tracker = (allocator, callback)

    def _reset_smem_tracking(self) -> None:  # type: ignore[no-redef]
        # Clear an allocator and callback for current dsl
        self._smem_usage_tracker = None

    def _get_smem_usage(self) -> int:  # type: ignore[no-redef]
        # Treat final allocated bytes of allocator as smem usage
        if not self._smem_usage_tracker:
            return 0
        allocator, callback = self._smem_usage_tracker
        return callback(allocator)

    @staticmethod
    def cuda_launch_func(
        stream: Union[list, tuple],
        kernel: ir.Value,
        grid_size_x: Union[Int32, int],
        grid_size_y: Union[Int32, int],
        grid_size_z: Union[Int32, int],
        block_size_x: Union[Int32, int],
        block_size_y: Union[Int32, int],
        block_size_z: Union[Int32, int],
        kernel_operands: List[ir.Value],
        *,
        cluster_size_x: Optional[Union[Int32, int]] = None,
        cluster_size_y: Optional[Union[Int32, int]] = None,
        cluster_size_z: Optional[Union[Int32, int]] = None,
        preferred_cluster_size_x: Optional[Union[Int32, int]] = None,
        preferred_cluster_size_y: Optional[Union[Int32, int]] = None,
        preferred_cluster_size_z: Optional[Union[Int32, int]] = None,
        dynamic_shared_memory_size: Optional[Union[Int64, int]] = None,
        use_pdl: bool = False,
        cooperative: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        max_num_attributes = 17
        launch_config_type = cuda_dialect.LaunchConfigType.get(max_num_attributes)

        if len(stream) == 0:
            stream = cuda_dialect.CastOp(
                src=Int64(0).ir_value(),
                dst=cuda_dialect.StreamType.get(),
                loc=loc,
                ip=ip,
            )
        else:
            stream = stream[0]

        dynamic_shared_memory_size = Int64(dynamic_shared_memory_size).ir_value()
        block_size_x = Int32(block_size_x).ir_value()
        block_size_y = Int32(block_size_y).ir_value()
        block_size_z = Int32(block_size_z).ir_value()
        grid_size_x = Int32(grid_size_x).ir_value()
        grid_size_y = Int32(grid_size_y).ir_value()
        grid_size_z = Int32(grid_size_z).ir_value()

        cfg = cuda_dialect.launch_cfg_create(
            # Launch config type
            launch_config_type,
            ir.IntegerAttr.get(ir.IntegerType.get_signless(32), max_num_attributes),
            block_size_x,
            block_size_y,
            block_size_z,
            dynamic_shared_memory_size,
            grid_size_x,
            grid_size_y,
            grid_size_z,
            stream,
            loc=loc,
            ip=ip,
        )

        cuda_dialect.launch_cfg_programmatic_stream_serialization_allowed(
            cfg, Int32(use_pdl).ir_value(), loc=loc, ip=ip
        )

        if cluster_size_x is not None:
            if cluster_size_y is None:
                cluster_size_y = 1
            if cluster_size_z is None:
                cluster_size_z = 1
            cluster_size_x = Int32(cluster_size_x).ir_value(loc=loc, ip=ip)
            cluster_size_y = Int32(cluster_size_y).ir_value(loc=loc, ip=ip)
            cluster_size_z = Int32(cluster_size_z).ir_value(loc=loc, ip=ip)
            cuda_dialect.launch_cfg_cluster_dim(
                cfg, cluster_size_x, cluster_size_y, cluster_size_z, loc=loc, ip=ip
            )

        if preferred_cluster_size_x is not None:
            preferred_cluster_size_y = preferred_cluster_size_y or 1
            preferred_cluster_size_z = preferred_cluster_size_z or 1
            preferred_x = Int32(preferred_cluster_size_x).ir_value(loc=loc, ip=ip)
            preferred_y = Int32(preferred_cluster_size_y).ir_value(loc=loc, ip=ip)
            preferred_z = Int32(preferred_cluster_size_z).ir_value(loc=loc, ip=ip)
            cuda_dialect.launch_cfg_preferred_cluster_dim(
                cfg, preferred_x, preferred_y, preferred_z, loc=loc, ip=ip
            )

        cuda_dialect.launch_cfg_cooperative(
            cfg, Int32(cooperative).ir_value(loc=loc, ip=ip), loc=loc, ip=ip
        )

        op = cuda_dialect.launch_ex(
            cuda_dialect.ResultType.get(),
            kernel,
            cfg,
            kernel_operands,
            # This is true for any DSL generated kernel
            assume_kernel_attr=ir.Attribute.parse("#cuda.assume_kernel_attr<true>"),
            loc=loc,
            ip=ip,
        )

        res_i32 = cuda_dialect.CastOp(
            src=op,
            dst=cuda_dialect.IntegerType.get_signless(32),
            loc=loc,
            ip=ip,
        )

        cuda_dialect.return_if_error([res_i32], loc=loc, ip=ip)
        return None

    @staticmethod
    def gpu_launch_func(
        async_token: ir.Value,
        async_dependencies: List[ir.Value],
        kernel: ir.Value,
        grid_size_x: Union[Int32, int],
        grid_size_y: Union[Int32, int],
        grid_size_z: Union[Int32, int],
        block_size_x: Union[Int32, int],
        block_size_y: Union[Int32, int],
        block_size_z: Union[Int32, int],
        kernel_operands: List[ir.Value],
        *,
        cluster_size_x: Optional[Union[Int32, int]] = None,
        cluster_size_y: Optional[Union[Int32, int]] = None,
        cluster_size_z: Optional[Union[Int32, int]] = None,
        dynamic_shared_memory_size: Optional[Union[Int64, int]] = None,
        async_object: Optional[ir.Value] = None,
        use_pdl: Any = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        op = gpu.LaunchFuncOp(
            asyncToken=async_token,
            asyncDependencies=async_dependencies,
            kernel=kernel,
            gridSizeX=grid_size_x,
            gridSizeY=grid_size_y,
            gridSizeZ=grid_size_z,
            blockSizeX=block_size_x,
            blockSizeY=block_size_y,
            blockSizeZ=block_size_z,
            kernelOperands=kernel_operands,
            clusterSizeX=cluster_size_x,
            clusterSizeY=cluster_size_y,
            clusterSizeZ=cluster_size_z,
            dynamicSharedMemorySize=dynamic_shared_memory_size,
            asyncObject=async_object,
            loc=loc,
            ip=ip,
        )
        op.attributes["use_pdl"] = use_pdl.ir_value()
        return _get_op_result_or_op_results(op)

    def _kernel_helper(  # type: ignore[override]
        self, funcBody: Callable[..., None], *args: Any, **kwargs: Any
    ) -> "KernelLauncher":
        class _CutlassIrKernelGenHelper(BaseDSL._KernelGenHelper):
            def __init__(self, dsl: CutlassBaseDSL):
                super().__init__()
                self.dsl = dsl
                self.dsl._reset_smem_tracking()

            def generate_func_op(
                self,
                arg_types: List[ir.Type],
                arg_attrs: Optional[List[ir.Attribute]],
                kernel_name: str,
                loc: Optional[ir.Location] = None,
            ) -> ir.Operation:
                assert arg_attrs is not None
                super().generate_func_op(arg_types, arg_attrs, kernel_name)
                self.func_op = self.dsl.generate_func_op(
                    arg_types, arg_attrs, kernel_name, loc
                )
                self.arg_types = arg_types
                return self.func_op

            def generate_func_ret_op(
                self,
                loc: Optional[ir.Location] = None,
                ip: Optional[ir.InsertionPoint] = None,
            ) -> None:
                self.dsl.generate_func_ret_op(loc, ip)

            def get_func_body_start(self) -> ir.Block:
                assert self.func_op is not None, "Invalid func_op is not expected!"
                arg_locs = [self.func_op.operation.location for _ in self.arg_types]
                return self.func_op.add_entry_block(arg_locs=arg_locs)

            def generate_launch_op(self, *args: Any, **kwargs: Any) -> None:
                # Extract args and do validation
                kernelSym = kwargs.get("kernelSym", None)
                kernelOperands = kwargs.get("kernelOperands", None)
                requiredArgs = kwargs.get("requiredArgs", None)
                loc = kwargs.get("loc", None)
                assert kernelSym is not None, "kernelSym being None is not expected!"
                assert requiredArgs is not None, (
                    "requiredArgs being None is not expected!"
                )
                assert kernelOperands is not None, (
                    "kernelOperands being None is not expected!"
                )
                assert isinstance(requiredArgs.config, BaseDSL.LaunchConfig), (
                    f"Expect LaunchConfig for @kernel, but got {type(requiredArgs.config)}"
                )

                cfg = requiredArgs.config

                smem_usage = self.dsl._get_smem_usage()
                if any(not isinstance(x, int) for x in [cfg.smem, smem_usage]):
                    pass  # cannot compare dynamic value inside kernel to launch op in py
                elif cfg.auto_smem:
                    cfg.smem = smem_usage
                elif smem_usage > cfg.smem:  # type: ignore[operator]
                    warnings.warn(
                        f"Potential error: specified kernel launch smem bytes "
                        f"({cfg.smem}) is smaller than kernel usage ({smem_usage})!",
                        UserWarning,
                    )
                cfg.smem = const(cfg.smem)

                # Warn user if shared memory exceed arch max
                # Currently runtime only show 'CUDA_ERROR_INVALID_VALUE' error which is not useful
                arch = self.dsl.get_arch_enum()
                arch_str = f"sm_{arch.major}{arch.minor}"
                if arch_str in SMEM_CAPACITY_MAP:
                    arch_smem = SMEM_CAPACITY_MAP[arch_str]
                    smem_msg = (
                        f"\nError: kernel '{kernelSym}' launch shared memory "
                        f"exceeds current GPU arch {arch} allowed. "
                        f"Allocated: {{}} bytes. Max: {arch_smem} bytes.\n\n"
                    )
                    if_generate(
                        arch_smem < cfg.smem,
                        lambda: cute.print_([cfg.smem], fmt=smem_msg),
                        loc=loc,
                    )
                else:
                    raise DSLRuntimeError(
                        f"Lack smem capacity info for GPU arch {arch}."
                    )

                async_deps = cfg.async_deps
                if not isinstance(cfg.async_deps, (list, tuple)):
                    async_deps = [cfg.async_deps]

                launch_kwargs = {}

                if cfg.has_fallback_cluster:
                    assert cfg.fallback_cluster is not None
                    assert cfg.cluster is not None
                    launch_kwargs.update(
                        dict(
                            zip(
                                ("cluster_size_x", "cluster_size_y", "cluster_size_z"),
                                tuple(cfg.fallback_cluster),
                            )
                        )
                    )
                    launch_kwargs.update(
                        dict(
                            zip(
                                (
                                    "preferred_cluster_size_x",
                                    "preferred_cluster_size_y",
                                    "preferred_cluster_size_z",
                                ),
                                tuple(cfg.cluster),
                            )
                        )
                    )
                elif cfg.has_cluster:
                    assert cfg.cluster is not None
                    launch_kwargs.update(
                        dict(
                            zip(
                                ("cluster_size_x", "cluster_size_y", "cluster_size_z"),
                                tuple(cfg.cluster),
                            )
                        )
                    )

                CutlassBaseDSL.cuda_launch_func(  # type: ignore[misc]
                    async_deps,
                    kernelSym,
                    *cfg.grid,
                    *cfg.block,
                    kernelOperands,
                    **launch_kwargs,
                    dynamic_shared_memory_size=cfg.smem,
                    use_pdl=cfg.use_pdl,
                    cooperative=cfg.cooperative,
                    loc=loc,
                )
                return None

        custom_name = kwargs.pop("_name_prefix", None)
        if custom_name:
            return KernelLauncher(
                self,
                lambda: _CutlassIrKernelGenHelper(self),  # type: ignore[arg-type]
                funcBody,
                *args,
                **kwargs,
                _name_prefix=custom_name,
            )
        else:
            return KernelLauncher(
                self,
                lambda: _CutlassIrKernelGenHelper(self),  # type: ignore[arg-type]
                funcBody,
                *args,
                **kwargs,
            )

    def _preprocess_launch_config_args(self, args: tuple, kwargs: dict) -> None:
        """Helper to preprocess args and kwargs for LaunchConfig"""
        if "stream" in kwargs:
            kwargs["async_deps"] = kwargs.pop("stream")

    def mangle_name(
        self, function_name: str, args: tuple[Any, ...], signature: inspect.Signature
    ) -> str:
        """Mangle the name of the function to avoid conflicts with other functions"""
        function_name = "cutlass_" + function_name
        return super().mangle_name(function_name, args, signature)

    def _validate_arg(
        self,
        arg: object,
        arg_index: int,
        arg_name: str,
        arg_annotation: object,
    ) -> Optional[DSLRuntimeError]:
        """
        Validates if the arg is really of the annotated type.
        """

        if (
            is_arg_annotation_constexpr(arg_annotation, arg_name, arg_index, None)
            or arg_annotation is Any
        ):
            pass
        else:
            origin = get_origin(arg_annotation)
            # Handle special case where annotation is Type[X] but arg is an actual type
            if origin is type and isinstance(arg, type):
                # Get the expected base type from Type[X]
                expected_base = get_args(arg_annotation)[0]
                if not issubclass(arg, expected_base):
                    return DSLRuntimeError(
                        f"expects argument #{arg_index + 1} ({arg_name}) to be Type[{expected_base}], but got {arg}"
                    )
            # Handle Union types and generic types
            elif origin is Union or isinstance(arg_annotation, UnionType):
                # For Union types, check if arg matches any of the allowed types
                allowed_types = get_args(arg_annotation)
                if not any(
                    (ty is Any)
                    or (isinstance(ty, type) and isinstance(arg, ty))
                    or (get_origin(ty) is tuple and isinstance(arg, tuple))
                    for ty in allowed_types
                ):
                    return DSLRuntimeError(
                        f"expects argument #{arg_index + 1} ({arg_name}) to be one of {allowed_types}, but got {type(arg)}"
                    )
            elif isinstance(arg_annotation, GenericAlias):
                # skip generic types such as List[int], Tuple[int, int], etc. for performance consideration?
                pass

            elif (
                getattr(arg_annotation, "__name__", None) == "CUstream"
                and arg.__class__.__name__ == "_FakeStream"
            ):
                # allow FakeStream to be passed as CUDA stream
                pass

            elif isinstance(arg_annotation, type):
                # Handle simple type annotations
                if not isinstance(arg, arg_annotation) and arg is not None:
                    return DSLRuntimeError(
                        f"expects argument #{arg_index + 1} ({arg_name}) to be {arg_annotation}, but got {type(arg)}"
                    )
        # Everything looks good if we are here
        return None

    def _generate_jit_func_args_for_known_types(
        self,
        func: Callable[..., None],
        arg: Any,
        arg_name: str,
        arg_spec: object,
        arg_index: int,
        *,
        is_host: bool = True,
    ) -> Tuple[
        Optional[List[object]],
        Optional[List[ir.Type]],
        Optional[List[ir.Attribute]],
    ]:
        jit_arg_type: Optional[List[ir.Type]] = []
        jit_arg_attr: Optional[List[ir.Attribute]] = []
        jit_exec_arg: Optional[List[object]] = []
        default_attr = ir.DictAttr.get({})

        (
            jit_exec_arg,
            jit_arg_type,
            jit_arg_attr,
        ) = super()._generate_jit_func_args_for_known_types(
            func, arg, arg_name, arg_spec, arg_index, is_host=is_host
        )

        if jit_arg_type is not None and len(jit_arg_type) == 0:
            assert jit_arg_attr is not None
            assert jit_exec_arg is not None
            # Handle DSL specific types
            if is_cute_algebra_type(arg_spec):
                dyn_vals = extract_mlir_values(arg)
                if dyn_vals:
                    # Handle dynamic types
                    jit_arg_type.extend([v.type for v in dyn_vals])
                    jit_arg_attr.extend([default_attr] * len(dyn_vals))
                    if is_host and self.envar.enable_tvm_ffi:
                        import tvm_ffi

                        jit_exec_arg.extend(
                            [
                                tvm_ffi.Shape(
                                    [  # type: ignore[arg-type]
                                        v.value if isinstance(v, Numeric) else v
                                        for v in arg
                                    ]
                                )
                            ]
                        )
                    else:
                        jit_exec_arg.extend(
                            get_c_pointers(arg) if is_host else dyn_vals
                        )
                else:
                    return None, None, None
            elif not is_host and not implements_dynamic_expression(arg, partial=True):
                # Try tree_flatten
                try:
                    dyn_vals, attr_vals, _ = tree_flatten(arg)
                except DSLTreeFlattenError:
                    # If fails, just return the original arg
                    return jit_exec_arg, jit_arg_type, jit_arg_attr

                if dyn_vals:
                    jit_arg_type.extend([v.type for v in dyn_vals])
                    jit_arg_attr.extend(attr_vals)
                    jit_exec_arg.extend(dyn_vals)
                else:
                    return None, None, None
        return jit_exec_arg, jit_arg_type, jit_arg_attr

    def _generate_execution_arguments_for_known_types(
        self,
        arg: object,
        arg_spec: object,
        arg_name: str,
        i: int,
        fop_args: List[ir.Value],
        iv_block_args: int,
    ) -> Tuple[List[object], int]:
        ir_arg, iv_block_args = super()._generate_execution_arguments_for_known_types(
            arg, arg_spec, arg_name, i, fop_args, iv_block_args
        )
        if not ir_arg:
            # Handling DSL specific types
            if is_cute_algebra_type(arg_spec):
                n_args = len(get_mlir_types(arg))
                blk_args = fop_args[iv_block_args : iv_block_args + n_args]
                ir_arg.append(new_from_mlir_values(arg, blk_args))
                iv_block_args += n_args
            elif not implements_dynamic_expression(arg, partial=True):
                # Try tree_unflatten
                try:
                    # we just need the length of flattened values,
                    # and we don't expect to emit arith.constant ops
                    # to get ir values from python literals.
                    flat_vals, _, tree_def = tree_flatten(arg, return_ir_values=False)
                    block_args = fop_args[
                        iv_block_args : iv_block_args + len(flat_vals)
                    ]
                    ir_arg.append(tree_unflatten(tree_def, block_args))  # type: ignore[arg-type]
                    iv_block_args += len(flat_vals)
                except DSLTreeFlattenError:
                    return ir_arg, iv_block_args

        return ir_arg, iv_block_args


# =============================================================================
# Cute DSL Class
# =============================================================================


class CuTeDSL(CutlassBaseDSL):
    """
    This is a concrete DSL subclass for the CuTe dialect.
    """

    def __init__(self) -> None:
        name = "CUTE_DSL"
        compiler_provider = compiler.Compiler(passmanager, execution_engine)
        pass_sm_arch_name = "cubin-chip"

        super().__init__(name, compiler_provider, pass_sm_arch_name, preprocess=True)

    @staticmethod
    def generate_func_op(
        arg_types: List[ir.Type],
        arg_attrs: Optional[List[ir.Attribute]],
        kernel_name: str,
        loc: Optional[ir.Location] = None,
    ) -> ir.Operation:
        func_op = cuda_dialect.KernelOp(
            kernel_name, ir.FunctionType.get(arg_types, []), loc=loc
        )
        func_op.attributes["cu_attrs"] = ir.DictAttr.get(
            {
                str(
                    cuda_dialect.CUFunctionAttribute.non_portable_cluster_size_allowed
                ): ir.IntegerAttr.get(ir.IntegerType.get_signless(32), 1),
                str(
                    cuda_dialect.CUFunctionAttribute.max_dynamic_shared_size_bytes
                ): cuda_dialect.DevMaxSharedMemoryOptinAttr.get(),
            }
        )
        if arg_attrs is not None:
            log().debug(arg_attrs)
            func_op.arg_attrs = arg_attrs
        return func_op

    @staticmethod
    def generate_func_ret_op(
        loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
    ) -> Any:
        return cuda_dialect.ReturnOp([], loc=loc, ip=ip)


# =============================================================================
# CuteExperimentalJitCompiledFunction Class
# =============================================================================


class _CuteExperimentalJitCompiledFunction(CudaDialectJitCompiledFunction):
    """JitCompiledFunction subclass for CuteExperimentalDSL.

    Overrides ``__call__`` to validate that the caller supplies exactly
    ``total_added_arguments`` extra workspace pointer arguments beyond the
    original kernel signature.
    """

    def __call__(self, *args: Any, **kwargs: Any) -> int | None:
        n = self.execution_args._meta.arg_count
        n_extra = builtins.max(0, len(args) - n)
        if n_extra != self.total_added_arguments:
            raise DSLRuntimeError(
                "Wrong number of extra workspace arguments",
                context={
                    "expected": self.total_added_arguments,
                    "got": n_extra,
                },
            )
        return super().__call__(*args, **kwargs)


# =============================================================================
# CuteExperimental DSL Class
# =============================================================================


class CuteExperimentalDSL(CutlassBaseDSL):
    _ALLOWED_EXTRA_KERNEL_VALUE_ATTRS: frozenset[str] = frozenset(
        {"lir.tma_update_mode"}
    )
    _KERNEL_ATTR_SPEC_FIELD: Optional[str] = "_cute_experimental_kernel_attributes"
    JitCompiledFunction = _CuteExperimentalJitCompiledFunction

    def __init__(self) -> None:
        name = "CUTE_EXPERIMENTAL_DSL"
        compiler_provider = compiler.Compiler(passmanager, execution_engine)
        pass_sm_arch_name = "cubin-chip"

        super().__init__(name, compiler_provider, pass_sm_arch_name, preprocess=True)

    @classmethod
    def kernel(cls, *dargs: Any, **dkwargs: Any) -> Any:
        attr_spec = dkwargs.pop("attributes", None)
        # Capture the caller's frame here rather than delegating to
        # super().kernel(), which would record *this* frame instead of
        # the user's source location (f_back would land in this override
        # rather than in the user file).
        current_frame = inspect.currentframe()
        assert current_frame is not None
        frame = current_frame.f_back
        kernel_decorator = BaseDSL.jit_runner(
            cls, "_kernel_helper", frame, *dargs, **dkwargs
        )
        if attr_spec is None:
            return kernel_decorator

        def attach_and_decorate(func: Callable[..., None]) -> Callable[..., None]:
            assert cls._KERNEL_ATTR_SPEC_FIELD is not None
            setattr(func, cls._KERNEL_ATTR_SPEC_FIELD, attr_spec)
            return kernel_decorator(func)

        return attach_and_decorate

    def _generate_kernel_attrs(self, config: BaseDSL.LaunchConfig) -> dict:
        import re

        ret = super()._generate_kernel_attrs(config)

        # Add compute capability attribute from the target arch.
        # get_arch_enum() validates the arch string; strip the portability
        # suffix (a/f) since C++ GpuArchitecture only has base names.
        arch_enum = self.get_arch_enum()
        sm_match = re.match(r"(sm_\d+)", arch_enum.to_string())
        if sm_match:
            sm_name = sm_match.group(1)
            ret["cc_attr"] = ir.Attribute.parse(
                f"#core.compute_capability<arch = {sm_name}>"
            )

        return ret

    def _get_pipeline(self, pipeline: Optional[str]) -> str:
        if pipeline == None:
            return (
                "builtin.module(gpu.module(lir-to-cute{enable-cuda-dialect enable-lir-func-finalization=false}), lir-func-finalization{enable-cuda-dialect=true}, cute-to-nvvm{cubin-format=bin enable-cuda-dialect "
                + self.compile_options.to_str()
                + "})"
            )
        return pipeline

    @staticmethod
    def generate_func_op(
        arg_types: List[ir.Type],
        arg_attrs: Optional[List[ir.Attribute]],
        kernel_name: str,
        loc: Optional[ir.Location] = None,
    ) -> ir.Operation:
        func_op = cutlass_lir.FuncOp(
            ir.StringAttr.get(kernel_name),
            ir.TypeAttr.get(ir.FunctionType.get(arg_types, [])),
            loc=loc,
        )
        func_op.attributes["cu_attrs"] = ir.DictAttr.get(
            {
                str(
                    cuda_dialect.CUFunctionAttribute.non_portable_cluster_size_allowed
                ): ir.IntegerAttr.get(ir.IntegerType.get_signless(32), 1),
                str(
                    cuda_dialect.CUFunctionAttribute.max_dynamic_shared_size_bytes
                ): cuda_dialect.DevMaxSharedMemoryOptinAttr.get(),
            }
        )
        # Monkey patch FuncOp to add an add_entry_block method, if not already defined.
        if not hasattr(func_op, "add_entry_block"):

            def add_entry_block(arg_locs: List[ir.Location]) -> ir.Block:
                if len(func_op.body.blocks) != 0:
                    raise RuntimeError("The function already has an entry block.")
                func_op.body.blocks.append(*arg_types)
                return func_op.body.blocks[0]

            func_op.add_entry_block = add_entry_block
        return func_op

    @staticmethod
    def generate_func_ret_op(
        loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
    ) -> Any:
        return cutlass_lir.ReturnOp([])

    def compile_and_cache(
        self,
        module: ir.Module,
        module_hash: str,
        function_name: str,
        pipeline: Optional[str],
        signature: inspect.Signature,
        no_cache: bool,
        no_jit_engine: bool,
        func_type: type = CudaDialectJitCompiledFunction,
        *,
        full_args: Optional[tuple] = None,
        full_kwargs: Optional[dict] = None,
        dynamic_args: Optional[list] = None,
        dynamic_kwargs: Optional[dict] = None,
        original_function_name: Optional[str] = None,
        funcBody: Optional[Callable[..., None]] = None,
    ) -> CudaDialectJitCompiledFunction:
        fn = super().compile_and_cache(
            module,
            module_hash,
            function_name,
            pipeline,
            signature,
            no_cache,
            no_jit_engine,
            func_type,
            full_args=full_args,
            full_kwargs=full_kwargs,
            dynamic_args=dynamic_args,
            dynamic_kwargs=dynamic_kwargs,
            original_function_name=original_function_name,
            funcBody=funcBody,
        )
        # Extract the kernel_extra_args attribute written by FuncFinalizationPass
        # and store it on the compiled function for later retrieval.
        # Maps kernel name → number of extra workspace pointer args added to the
        # host entry point signature.
        fn.kernel_extra_args = {}
        fn.total_added_arguments = 0
        if fn.ir_module is not None:
            attrs = fn.ir_module.operation.attributes
            if "kernel_extra_args" in attrs:
                for named in ir.DictAttr(attrs["kernel_extra_args"]):
                    fn.kernel_extra_args[named.name] = ir.IntegerAttr(named.attr).value
                fn.total_added_arguments = fn.kernel_extra_args.pop(
                    "total_added_arguments", 0
                )
        fn.__class__ = CuteExperimentalDSL.JitCompiledFunction
        return fn


# =============================================================================
# KernelLauncher
# =============================================================================


class KernelLauncher:
    """
    This class is used to launch a kernel function.
    Usage:
        ```python
        @cute.kernel
        def kernel(arg1, arg2, ...):
            ...

        @cute.jit
        def launch_kernel():
            kernel(arg1, arg2, ...).launch(grid=[1, 1, 1], block=[1, 1, 1], ...)
            # or
            kernel(arg1, arg2, ...)(grid=[1, 1, 1], block=[1, 1, 1], ...)
        ```
    """

    def __init__(
        self,
        dsl: "CutlassBaseDSL",
        kernelGenHelper: BaseDSL._KernelGenHelper,
        funcBody: Callable[..., None],
        *func_args: Any,
        **func_kwargs: Any,
    ) -> None:
        self.dsl = dsl
        self.kernelGenHelper = kernelGenHelper
        self.funcBody = funcBody
        self.func_args = func_args
        self.func_kwargs = func_kwargs

        self._name_prefix = func_kwargs.pop("_name_prefix", None)
        self._launch_name = None

        self._check_func_args(funcBody, *func_args, **func_kwargs)

    def _check_func_args(
        self, funcBody: Any, *func_args: Any, **func_kwargs: Any
    ) -> None:
        # Get function signature
        sig = inspect.signature(funcBody)

        # func_args and func_kwargs should match funcBody's signature,
        # no extra or missing arguments.
        try:
            sig.bind(*func_args, **func_kwargs)
        except TypeError as e:
            raise DSLRuntimeError(
                f"Failed to bind arguments to function `{funcBody.__name__}` with signature `{sig}`",
                cause=e,
            )

    @deprecated(
        "`smem_usage()` is deprecated, use public API `arch.dynamic_smem_size()` instead."
    )
    def smem_usage(self) -> Int32:
        """
        Check smem usage for this kernel, only available after `launch`
        """
        return self.dsl._get_smem_usage()  # type: ignore[return-value]

    def launch(self, *args: Any, **kwargs: Any) -> Any:
        self.dsl._preprocess_launch_config_args(args, kwargs)
        config = self.dsl.LaunchConfig(*args, **kwargs)
        kernel_attrs = _build_kernel_attrs(config)
        value_attrs = self.dsl._generate_kernel_attrs(config)
        collector = getattr(self.dsl, "_collect_extra_kernel_value_attrs", None)
        if callable(collector):
            value_attrs.update(
                collector(self.funcBody, self.func_args, self.func_kwargs)
            )

        if hasattr(self, "_name_prefix") and self._name_prefix:
            self.dsl._name_prefix = self._name_prefix  # type: ignore[attr-defined]

        kernel_generator = self.dsl.kernel_launcher(
            requiredArgs=["config"],
            unitAttrNames=["gpu.kernel", "cute.kernel"],
            valueAttrDict=value_attrs,
            kernelGenHelper=self.kernelGenHelper,
        )(self.funcBody)

        ret, name = kernel_generator(*self.func_args, **self.func_kwargs, config=config)
        self.dsl.kernel_info[name] = kernel_attrs
        self._launch_name = name
        return ret.launch_op_ret

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        return self.launch(*args, **kwargs)


# =============================================================================
# Utils
# =============================================================================
def _filter_readonly_frozen_dataclass(
    iter_args: List[Any], items_to_filter: List[Any], full_write_args_count: int
) -> List[Any]:
    """
    Filter items based on whether corresponding iter_args are frozen dataclasses.

    This function filters items (which can be values or names) based on the same
    logic: keep items if they correspond to full-write arguments (index < full_write_args_count)
    or if the corresponding iter_arg is not a frozen dataclass.

    Args:
        iter_args: List of arguments to check for frozen dataclass status
        items_to_filter: List of items to filter (values or names)
        full_write_args_count: Number of arguments that are always written (not read-only)

    Returns:
        Filtered list of items

    Examples:
        # Filter values (original remove_read_only_frozen_dataclass behavior)
        filtered_values = _filter_readonly_frozen_dataclass(iter_args, iter_args, full_write_args_count)

        # Filter names (original filter_readonly_frozen_dataclass_names behavior)
        filtered_names = _filter_readonly_frozen_dataclass(iter_args, iter_args_names, full_write_args_count)
    """
    return [
        item
        for i, item in enumerate(items_to_filter)
        if i < full_write_args_count or not is_frozen_dataclass(iter_args[i])
    ]


def remove_read_only_frozen_dataclass(
    iter_args: List[Any], full_write_args_count: int
) -> List[Any]:
    """Filter out frozen dataclass arguments that are not full-write arguments."""
    return _filter_readonly_frozen_dataclass(
        iter_args, iter_args, full_write_args_count
    )


def filter_readonly_frozen_dataclass_names(
    iter_args: List[Any], iter_args_names: List[str], full_write_args_count: int
) -> List[str]:
    """Filter names based on whether corresponding iter_args are frozen dataclasses."""
    return _filter_readonly_frozen_dataclass(
        iter_args, iter_args_names, full_write_args_count
    )


def insert_read_only_frozen_dataclass(
    iter_args: List[Any], original_iter_args: List[Any], full_write_args_count: int
) -> List[Any]:
    """
    Insert read-only frozen dataclass arguments back into the iteration arguments.

    This function takes the new iteration arguments and the original arguments,
    and preserves frozen dataclass instances from the original arguments while
    using the new arguments for non-frozen dataclass instances.

    Args:
        iter_args: New iteration arguments to use for non-frozen dataclass instances
        original_iter_args: Original iteration arguments to preserve frozen dataclass instances from
        full_write_args_count: Number of arguments that are always written (not read-only)

    Returns:
        List of arguments with frozen dataclass instances preserved from original
    """
    # Take full-write arguments from new iter_args
    full_write_args = (
        iter_args[:full_write_args_count] if full_write_args_count > 0 else []
    )

    # Process remaining arguments: preserve frozen dataclass from original, use new for others
    remaining_original = original_iter_args[full_write_args_count:]
    remaining_new = iter_args[full_write_args_count:]

    def process_remaining_arg(original_arg: object, new_arg_iter: Any) -> object:
        """Process a single remaining argument, preserving frozen dataclass if present"""
        return original_arg if is_frozen_dataclass(original_arg) else next(new_arg_iter)

    # Use zip to pair original args with new args, then map the processing function
    new_arg_iter = iter(remaining_new)
    processed_remaining = [
        process_remaining_arg(orig_arg, new_arg_iter) for orig_arg in remaining_original
    ]

    return full_write_args + processed_remaining


def unpack_to_irvalue(
    mixed_values: List[Any], body_name: str, full_write_args_count: int
) -> Tuple[List[ir.Value], Union[PyTreeDef, Leaf]]:
    log().debug("===--- Values UNPack")
    for idx, packed in enumerate(mixed_values):
        log().debug("[%d]: will-unpacked: [type:%s] %s", idx, type(packed), packed)

    # DEBUG: Print input values before tree_flatten (only if enabled)
    from ..base_dsl.dsl import (
        debug_print_mlir_values,
        should_print_dynamic_debug,
        get_dynamic_debug_level,
    )

    if should_print_dynamic_debug():
        import traceback
        import re

        level = get_dynamic_debug_level()
        indent = "  " * level  # Indent based on level

        print("=" * 80)
        print(f"{indent}[Level {level}] DEBUG '{body_name}'")
        # Find the source location - look for generated DSL function names in stack
        # These are created by the AST transformer: loop_body_N, then_block_N, etc.
        generated_func_pattern = re.compile(
            r"^(loop_body|while_region|while_before_block|while_after_block|if_region|then_block|else_block|elif_region)_\d+$"
        )
        stack = traceback.extract_stack()
        for frame_info in reversed(stack):
            if generated_func_pattern.match(frame_info.name):
                print(f"{indent}  source: {frame_info.filename}:{frame_info.lineno}")
                if frame_info.line:
                    print(f"{indent}    {frame_info.line}")
                break
        print(f"{indent}  mixed_values count: {len(mixed_values)}")
        print(f"{indent}  full_write_args_count: {full_write_args_count}")
        for idx, packed in enumerate(mixed_values):
            print(f"{indent}  [{idx}] type: {type(packed).__name__}")
            if hasattr(packed, "__extract_mlir_values__"):
                # Add extra indentation for the tree print
                tree_str = debug_print_mlir_values(
                    packed, indent=3 + level, types_only=True
                )
                print(tree_str)
        print("=" * 80)

    try:
        unpacked_values, _, treedef = tree_flatten(
            remove_read_only_frozen_dataclass(mixed_values, full_write_args_count)
        )
    except DSLTreeFlattenError as e:
        raise DSLRuntimeError(
            f"The '{body_name}' statement encountered a user-defined Python object, which cannot be automatically converted into an dynamic expression.",
            context={
                e.message: (
                    f"All expressions within '{body_name}' must be dynamic expressions, "
                    "mixing Python objects and dynamic expressions is not supported. "
                    "The DSL failed to convert the Python object into dynamic expressions."
                )
            },
            suggestion=(
                f"Please ensure '{e.type_str}' implements the '{DynamicExpression.__name__}' or mark with `dataclass`, "
                f"so it can be treated as a valid dynamic expression or mark '{body_name}' as a constant expression if conditions are Python objects."
            ),
        )

    # DEBUG: Print unpacked values after tree_flatten
    if should_print_dynamic_debug():
        level = get_dynamic_debug_level()
        indent = "  " * level
        print(f"{indent}  => flattened to {len(unpacked_values)} ir.Values")
        print("=" * 80)

    log().debug("------------------ ")
    for idx, unpacked in enumerate(unpacked_values):
        log().debug("[%d]: unpacked values: %s", idx, unpacked)
    log().debug("treedef: %s", treedef)
    log().debug("------------------ ")

    return unpacked_values, treedef


def pack_from_irvalue(
    ir_values: List["ir.Value"],
    pytree_def: PyTreeDef,
    mixed_values: List[Any],
    full_write_args_count: int,
) -> List[Any]:
    """
    Packs MLIR values into a list of mixed values.
    """
    log().debug("===--- Values Pack (%d)", len(ir_values))
    for idx, value in enumerate(ir_values):
        log().debug("[%d]: will-packed: %s", idx, value)
    log().debug("treedef: %s", pytree_def)
    log().debug("------------------ ")

    unflattened = tree_unflatten(pytree_def, ir_values)
    return insert_read_only_frozen_dataclass(
        unflattened, mixed_values, full_write_args_count
    )


def to_index(value: Union[Numeric, ir.Value, int]) -> ir.Value:
    """Converts a value to an index, either by casting or coercing to int."""
    if is_dynamic_expression(value):
        if isinstance(value, Numeric):
            value = value.ir_value()
        assert isinstance(value, ir.Value)
        assert isinstance(value.type, ir.IntegerType), (
            f"expects integer type, but got {value.type}"
        )
        res = arith.index_cast(T.index(), value)
    else:
        res = const(int(value), ty=T.index())

    return res


def _validate_iter_args_structure(iter_args: object, ir_values: object) -> bool:
    """
    Validates that iter_args structure contains the same number of atomic values
    as there are IR values.

    Args:
        iter_args: Original iteration arguments, possibly nested sequences
        ir_values: Flattened MLIR values extracted from iter_args

    Returns:
        bool: True if the number of atomic values in iter_args matches
              the number of values in ir_values
    """
    # Handle non-sequence case
    if not isinstance(iter_args, (tuple, list, set)):
        return not isinstance(ir_values, (tuple, list, set)) or len(ir_values) == 1

    # If we have a sequence but ir_values isn't one, there's a mismatch
    if not isinstance(ir_values, (tuple, list, set)):
        return False

    # Count all non-sequence values recursively
    def count_values(args: object) -> int:
        if not isinstance(args, (tuple, list, set)):
            return 1
        else:
            return sum(count_values(arg) for arg in args)

    return count_values(iter_args) == len(ir_values)


# =============================================================================
# DSL implementation of Python Build-in Operators
# =============================================================================


def _minmax(
    op: Any,
    *args: Union[Numeric, ir.Value, int, float, bool],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, int, float]:
    """Computes the minimum or maximum value from the provided arguments."""
    from ..base_dsl.typing import _binary_op, _binary_op_type_promote

    # AST Traversal doesn't support early exit in if executor
    x = None
    res = None
    if len(args) == 1:
        # Handle case for min([a, b, c, d, ..])
        if hasattr(args[0], "__iter__"):
            x = op(*tuple(args[0]))
        # Handle case for min(a)
        else:
            x = args[0]
    # Handle case for min(a, b, c, ...) and min([x, y], [b]) and min(a, (x, y, z))
    elif len(args) > 1:
        res, *xs = tuple(args)

        for x in xs:
            emitter = getattr(cutlass_arith, f"_{op.__name__}")
            if not (is_dynamic_expression(res) or is_dynamic_expression(x)):
                res = emitter(op(res), op(x), loc=loc, ip=ip)
            elif (
                hasattr(res, "type")
                and hasattr(x, "type")
                and isinstance(res.type, T.VectorType)
                and isinstance(x.type, T.VectorType)
            ):
                lhs = op(res, loc=loc, ip=ip)
                rhs = op(x, loc=loc, ip=ip)
                return lhs.apply_op(emitter, rhs, loc=loc, ip=ip)
            else:
                lhs = as_numeric(op(res, loc=loc, ip=ip))
                rhs = as_numeric(op(x, loc=loc, ip=ip))
                lhs, rhs, res_type = _binary_op_type_promote(
                    lhs, rhs, promote_bool=True
                )

                lhs_val: Union[bool, int, float, ir.Value, cutlass_arith.ArithValue]
                if isinstance(lhs.value, cutlass_arith.ArithValue) and isinstance(
                    lhs, Integer
                ):
                    lhs_val = lhs.value.with_signedness(lhs.signed)  # type: ignore[attr-defined]
                else:
                    lhs_val = lhs.value

                rhs_val: Union[bool, int, float, ir.Value, cutlass_arith.ArithValue]
                if isinstance(rhs.value, cutlass_arith.ArithValue) and isinstance(
                    rhs, Integer
                ):
                    rhs_val = rhs.value.with_signedness(rhs.signed)  # type: ignore[attr-defined]
                else:
                    rhs_val = rhs.value
                res = res_type(
                    emitter(lhs_val, rhs_val, loc=loc, ip=ip), loc=loc, ip=ip
                )
        x = res
    else:
        raise DSLNotImplemented(f"{type(args)} is not supported")
    return x


@dsl_user_op
def min(
    *args: Union[Numeric, ir.Value, int, float, bool],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, int, float]:
    """Computes the minimum value from the provided arguments.

    This function differs from Python's built-in min() in that the return type
    is determined by the static types of the inputs, not their dynamic values.

    :param args: One or more values or iterables to find the minimum of
    :type args: tuple
    :param loc: Source location for MLIR operation tracking
    :type loc: object, optional
    :param ip: Insertion point for MLIR operation
    :type ip: object, optional
    :return: The minimum value among all inputs
    :rtype: Numeric
    :raises DSLNotImplemented: If the input type is not supported

    Supports multiple calling patterns:

    - min(a): Returns a
    - min([a, b, c, ...]): Returns minimum of all elements in the iterable
    - min(a, b, c, ...): Returns minimum of all arguments
    - min([x, y], [b]): Returns minimum across all elements in all iterables
    - min(a, (x, y, z)): Returns minimum across all elements

    Examples:

    .. code-block:: python

        # Find minimum of two values
        result = min(x, y)

        # Find minimum of multiple values
        result = min(a, b, c, d)

        # Find minimum of values in a list
        values = [a, b, c, d]
        result = min(values)

        # Find minimum across mixed arguments
        result = min(x, [y, z])

    Difference from Python's built-in min():

    .. code-block:: python

        # In Python, the return type depends on the dynamic values:
        a = 5
        b = 3.14
        result = min(a, b)  # Returns 3.14 (float)

        # In this DSL implementation, the return type is determined statically:
        a = Int32(5)
        b = Float32(3.14)
        result = min(a, b)  # Return type is determined by the type of operands, not values
    """
    return _minmax(min, *args, loc=loc, ip=ip)


@dsl_user_op
def max(
    *args: Union[Numeric, ir.Value, int, float, bool],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, int, float]:
    """Computes the maximum value from the provided arguments.

    This function differs from Python's built-in max() in that the return type
    is determined by the static types of the inputs, not their dynamic values.

    :param args: One or more values or iterables to find the maximum of
    :type args: tuple
    :param loc: Source location for MLIR operation tracking
    :type loc: object, optional
    :param ip: Insertion point for MLIR operation
    :type ip: object, optional
    :return: The maximum value among all inputs
    :rtype: Numeric
    :raises DSLNotImplemented: If the input type is not supported

    Supports multiple calling patterns:

    - max(a): Returns a
    - max([a, b, c, ...]): Returns maximum of all elements in the iterable
    - max(a, b, c, ...): Returns maximum of all arguments
    - max([x, y], [b]): Returns maximum across all elements in all iterables
    - max(a, (x, y, z)): Returns maximum across all elements

    Examples:

    .. code-block:: python

        # Find maximum of two values
        result = max(x, y)

        # Find maximum of multiple values
        result = max(a, b, c, d)

        # Find maximum of values in a list
        values = [a, b, c, d]
        result = max(values)

        # Find maximum across mixed arguments
        result = max(x, [y, z])

    Difference from Python's built-in max():

    .. code-block:: python

        # In Python, the return type depends on the dynamic values:
        a = 5
        b = 3.14
        result = max(a, b)  # Returns 5 (int)

        # In this DSL implementation, the return type is determined statically:
        a = Int32(5)
        b = Float32(3.14)
        result = max(a, b)  # Return type is determined by the type of operands, not values
    """
    return _minmax(max, *args, loc=loc, ip=ip)


def and_(
    *args: Union[Numeric, ir.Value, int, float, bool],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, int, float, bool]:
    """AND operation for value in DSL numeric types.

    :param *args: One or more numeric values to AND together
    :type *args: Numeric
    :param loc: Source location for MLIR operation tracking
    :type loc: object, optional
    :param ip: Insertion point for MLIR operation
    :type ip: object, optional
    :return: The result of the logical AND operation
    :rtype: Numeric
    :raises ValueError: If no arguments are provided

    Supports multiple calling patterns:

    - and_(a): Returns a
    - and_(a, b, c, ...): if a is truthy, returns and_(b, c, ...), otherwise returns a

    All arguments must be of the same type.

    Examples:

    .. code-block:: python

        # In Python, 'and' returns the second operand if the first is truthy,
        # otherwise it returns the first operand
        a = 5
        b = 3
        result = a and b  # Returns 3

        # In this DSL implementation, the behavior is similar but works with DSL types
        a = Int32(5)
        b = Int32(3)
        result = and_(a, b)  # Returns b
    """
    if len(args) == 0:
        raise ValueError("and_() requires at least one argument")

    if len(args) == 1:
        return args[0]

    def and_op(
        lhs: Union[Numeric, ir.Value, int, float, bool],
        rhs: Union[Numeric, ir.Value, int, float, bool],
    ) -> Union[Numeric, int, float, bool]:
        if not isinstance(lhs, (Numeric, cutlass_arith.ArithValue, int, float, bool)):
            raise DSLNotImplemented(f"{type(lhs)} is not supported")
        elif isinstance(lhs, (int, float, bool)) and isinstance(
            rhs, (int, float, bool)
        ):
            return lhs and rhs
        else:
            return as_numeric(lhs).__dsl_and__(as_numeric(rhs))

    return functools.reduce(and_op, args[1:], args[0])


def or_(
    *args: Union[Numeric, ir.Value, int, float, bool],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Numeric, int, float, bool]:
    """Logical OR operation for DSL numeric types.

    :param *args: One or more numeric values to OR together
    :type *args: Numeric
    :param loc: Source location for MLIR operation tracking
    :type loc: object, optional
    :param ip: Insertion point for MLIR operation
    :type ip: object, optional
    :return: The result of the logical OR operation
    :rtype: Numeric
    :raises ValueError: If no arguments are provided

    Supports multiple calling patterns:

    - or_(a): Returns a
    - or_(a, b, c, ...): if a is truthy, returns a, otherwise returns or_(b, c, ...)

    Examples:

    .. code-block:: python

        # In Python, 'or' returns the first operand if it's truthy,
        # otherwise it returns the second operand
        a = 5
        b = 3
        result = a or b  # Returns 5

        # In this DSL implementation, the behavior is similar but works with DSL types
        a = Int32(5)
        b = Int32(3)
        result = or_(a, b)  # Returns a
    """
    if len(args) == 0:
        raise ValueError("or_() requires at least one argument")

    if len(args) == 1:
        return args[0]

    def or_op(
        lhs: Union[Numeric, ir.Value, int, float, bool],
        rhs: Union[Numeric, ir.Value, int, float, bool],
    ) -> Union[Numeric, int, float, bool]:
        if not isinstance(lhs, (Numeric, cutlass_arith.ArithValue, int, float, bool)):
            raise DSLNotImplemented(f"{type(lhs)} is not supported")
        elif isinstance(lhs, (int, float, bool)) and isinstance(
            rhs, (int, float, bool)
        ):
            return lhs or rhs
        else:
            return as_numeric(lhs).__dsl_or__(as_numeric(rhs))

    return functools.reduce(or_op, args[1:], args[0])


def all_(iterable: Iterable[Union[Numeric, ir.Value, bool]]) -> Boolean:
    """Logical AND operation for all elements in an iterable.

    Returns True if all elements in the iterable are truthy, otherwise False.
    This is the DSL equivalent of Python's built-in all() function.

    :param iterable: An iterable containing values to check
    :type iterable: Iterable
    :return: True if all elements are truthy, False otherwise
    :rtype: Boolean

    Examples:

    .. code-block:: python

        # Check if all values are non-zero
        values = [Int32(1), Int32(2), Int32(3)]
        result = all_(values)  # Returns True

        # Check if all conditions are met
        conditions = [a > 0, b < 10, c != 0]
        result = all_(conditions)  # Returns True if all conditions are met
    """
    bool_iterable = [Boolean(i) for i in iterable]
    reducer = lambda lhs, rhs: (
        lhs.__dsl_and__(rhs) if hasattr(lhs, "__dsl_and__") else lhs
    )  # noqa: E731
    return functools.reduce(reducer, bool_iterable, Boolean(True))


def any_(iterable: Iterable[Union[Numeric, ir.Value, bool]]) -> Boolean:
    """Logical OR operation for any element in an iterable.

    Returns True if any element in the iterable is truthy, otherwise False.
    This is the DSL equivalent of Python's built-in any() function.

    :param iterable: An iterable containing values to check
    :type iterable: Iterable
    :return: True if any element is truthy, False otherwise
    :rtype: Boolean

    Examples:

    .. code-block:: python

        # Check if any value is non-zero
        values = [Int32(0), Int32(0), Int32(3)]
        result = any_(values)  # Returns True

        # Check if any condition is met
        conditions = [a > 10, b < 0, c != 0]
        result = any_(conditions)  # Returns True if any condition is met
    """
    bool_iterable = [Boolean(i) for i in iterable]
    reducer = lambda lhs, rhs: (
        lhs.__dsl_or__(rhs) if hasattr(lhs, "__dsl_or__") else lhs
    )  # noqa: E731
    return functools.reduce(reducer, bool_iterable, Boolean(False))


# =============================================================================
# Conditional Expression
# =============================================================================


def select_(
    cond: Union[Boolean, ir.Value, bool],
    if_value: Union[Numeric, ir.Value, int, float, bool],
    else_value: Union[Numeric, ir.Value, int, float, bool],
) -> ir.Value:
    def _as_scalar(
        value: Union[Numeric, ir.Value, int, float, List[ir.Value]],
    ) -> Union[ir.Value, Numeric]:
        if isinstance(value, list):
            if len(value) == 1:
                return value[0]
            else:
                raise DSLRuntimeError(
                    "Conditional expression must have exactly one value in all expressions"
                )
        return value

    if not is_dynamic_expression(cond):
        raise DSLRuntimeError("Conditional expression must be dynamic")

    # Extract MLIR values
    cond = extract_mlir_values(cond)
    if is_dynamic_expression(if_value):
        if_value = extract_mlir_values(if_value)
    else:
        if_value = const(if_value)
    if is_dynamic_expression(else_value):
        else_value = extract_mlir_values(else_value)
    else:
        else_value = const(else_value)

    return arith.SelectOp(
        _as_scalar(cond), _as_scalar(if_value), _as_scalar(else_value)
    ).result


# =============================================================================
# Terminator
# =============================================================================


def yield_out(
    args: Union[List[ir.Value], List[Numeric]] = [],
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Generate a yield operation. It it used to return values from a loop, if-else, or while region.
    """
    scf.yield_(extract_mlir_values(args), loc=loc, ip=ip)


# =============================================================================
# For Loop
# =============================================================================


def for_generate(
    start: Union[Int32, int],
    stop: Optional[Union[Int32, int]] = None,
    step: Optional[Union[Int32, int]] = None,
    iter_args: Optional[Sequence[ir.Value]] = None,
    *,
    unroll: Optional[LoopUnroll] = None,
    prefetch_stages: Optional[int] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Generator:
    """
    scf.for with yield support
    """

    if step is None:
        step = 1
    if stop is None:
        stop = start
        start = 0
    start = const(start)
    params = [start, stop, step]
    for i, p in enumerate(params):
        if isinstance(p, int):
            p = const(p)
        elif isinstance(p, float):
            raise DSLRuntimeError(f"{p=} must be int.")
        elif isinstance(p, Integer):
            p = p.ir_value()
        params[i] = p

    start, stop, step = params

    def _createI32Attr(value: Union[Int32, int]) -> ir.IntegerAttr:
        if not isinstance(value, int):
            raise DSLRuntimeError(f"value must be int.")
        return ir.IntegerAttr.get(ir.IntegerType.get_signless(32), value)

    ir_iter_args = extract_mlir_values(iter_args) if iter_args is not None else None
    if not _validate_iter_args_structure(iter_args, ir_iter_args):
        raise DSLRuntimeError("iter_args: Elements should be extractable as ir.Value.")
    for_op = scf.ForOp(start, stop, step, ir_iter_args, loc=loc, ip=ip)
    if unroll is not None:
        for_op.attributes["loop_annotation"] = unroll

    if prefetch_stages is not None:
        for_op.attributes["cutlass.pipelining"] = _createI32Attr(prefetch_stages)

    iv = for_op.induction_variable
    new_results = new_from_mlir_values(iter_args, for_op.results)
    new_iter_args = new_from_mlir_values(iter_args, for_op.inner_iter_args)
    new_iter_args = () if new_iter_args is None else tuple(new_iter_args)

    with ir.InsertionPoint(for_op.body):
        if len(new_iter_args) > 1:
            yield iv, new_iter_args, new_results
        elif len(new_iter_args) == 1:
            yield iv, new_iter_args[0], new_results[0]
        else:
            yield iv


# =============================================================================
# Logical Operators
# =============================================================================


def not_(
    lhs: Union[ir.Value, bool],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[Boolean, bool, ir.Value]:
    """
    Logical Not
    """
    res = None
    # Handle Python bool first to prevent infinite recursion
    if type(lhs) == bool:
        res = lhs ^ True
    elif hasattr(lhs, "__dsl_not__"):
        res = lhs.__dsl_not__(loc=loc, ip=ip)
    elif is_dynamic_expression(lhs):
        # If lhs is MLIR value, compute not using xor
        res = arith.XOrIOp(lhs, const(1, lhs.type)).result
    else:
        res = bool(lhs) ^ True

    return res


# =============================================================================
# If/Else
# =============================================================================


def if_generate(
    cond: Union[Boolean, ir.Value, bool],
    then_body: Callable,
    else_body: Optional[Callable] = None,
    input_args: Optional[List[DslType]] = None,
    return_types: Optional[List[DslType]] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[List[Numeric], Numeric]:
    """
    Generate an IfOp with optional else branch and return values.

    Args:
        cond: The condition expression
        then_body: Function to execute in then branch
        else_body: Optional function to execute in else branch
        input_args: Arguments to pass to branch bodies
        return_types: Expected return types for the operation
        loc: Optional location information
        ip: Optional insertion point

    Returns:
        List of DSL typed results
    """
    input_args = input_args or []
    mlir_return_types = []

    # Validate and collect MLIR return types (if provided).
    if return_types is not None:
        for t in return_types:
            if not isinstance(t, DslType):
                raise DSLRuntimeError(f"{t=} must be a DslType.")
            mlir_return_types.append(t.mlir_type)  # type: ignore[attr-defined]

    # Determine whether there's an else branch.
    has_else = else_body is not None

    # Create the IfOp.
    if_op = scf.IfOp(
        Boolean(cond).ir_value(), mlir_return_types, hasElse=has_else, loc=loc, ip=ip
    )

    def _execute_and_yield_out(body: Callable, input_args: List[DslType]) -> None:
        yield_vals = body(*input_args)
        if return_types is not None:
            if not isinstance(yield_vals, Iterable):
                # body only return single element
                yield_vals = [yield_vals]

            yield_vals = [t(r) for t, r in zip(return_types, yield_vals)]
        yield_out(yield_vals)

    # Generate the body for 'then'.
    with ir.InsertionPoint(if_op.then_block):
        _execute_and_yield_out(then_body, input_args)

    # Generate the body for 'else' if provided.
    if has_else:
        assert else_body is not None
        with ir.InsertionPoint(if_op.else_block):
            _execute_and_yield_out(else_body, input_args)

    # Collect MLIR results.
    mlir_results = _get_op_result_or_op_results(if_op)

    if not isinstance(mlir_results, list) and not isinstance(
        mlir_results, ir.OpResultList
    ):
        mlir_results = [mlir_results]

    # Wrap the results with their DSL types.
    if return_types is None:
        return []

    vals = [t(r) for t, r in zip(return_types, mlir_results)]

    if len(vals) == 1:
        return vals[0]

    return vals


# =============================================================================
# While Loop
# =============================================================================


class WhileLoopContext:
    """
    Context manager for a dynamic while loop.
    """

    def __init__(
        self,
        inputs: Sequence[Union[ir.Value, Numeric]],
        condition: Callable[[Sequence[ir.Value]], ir.Value],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        # Keep original inputs and allow recover original type information
        self.inputs = inputs

        self.input_ir_values = extract_mlir_values(inputs)

        if not _validate_iter_args_structure(inputs, self.input_ir_values):
            raise DSLRuntimeError("inputs: Elements should be extractable as ir.Value.")

        self.condition = condition
        self.input_ir_types = [i.type for i in self.input_ir_values]
        self.while_op = scf.WhileOp(
            self.input_ir_types, self.input_ir_values, loc=loc, ip=ip
        )

        self.before_region = self.while_op.before
        self.after_region = self.while_op.after

        self.before_region.blocks.append(*self.input_ir_types)
        self.before_block = self.before_region.blocks[0]

        self.after_region.blocks.append(*self.input_ir_types)
        self.after_block = self.after_region.blocks[0]

    def __enter__(self) -> List[Numeric]:
        with ir.InsertionPoint(self.before_block):
            args = new_from_mlir_values(self.inputs, self.before_block.arguments)
            cond = self.condition(*args)
            cond_ir_val = extract_mlir_values(cond)
            scf.ConditionOp(cond_ir_val[0], [*self.before_block.arguments])
        self.ipoint_op = ir.InsertionPoint(self.after_block)
        self.ipoint_op.__enter__()
        return new_from_mlir_values(self.inputs, self.after_block.arguments)

    def __exit__(
        self,
        exc_type: Optional[type],
        exc_value: Optional[BaseException],
        traceback: object,
    ) -> None:
        self.ipoint_op.__exit__(exc_type, exc_value, traceback)

    @property
    def results(self) -> List[Numeric]:
        return new_from_mlir_values(self.inputs, self.while_op.results_)


def while_generate(
    inputs: Sequence[Union[ir.Value, Numeric]],
    condition: Callable[[Sequence[Union[ir.Value, Numeric]]], Union[ir.Value, Numeric]],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> WhileLoopContext:
    """
    Generate a WhileLoopContext for a dynamic loop.
    """
    return WhileLoopContext(inputs, condition, loc=loc, ip=ip)


def equal(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    if not is_dynamic_expression(lhs) and not is_dynamic_expression(rhs):
        return lhs == rhs

    # Both sequence
    if isinstance(lhs, Sequence) and isinstance(rhs, Sequence):
        # Short-circuit for unequal length
        if len(lhs) != len(rhs):
            return False
        return all_(equal(l, r) for l, r in zip(lhs, rhs))
    return lhs == rhs


def not_equal(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    if not is_dynamic_expression(lhs) and not is_dynamic_expression(rhs):
        return lhs != rhs

    # Both sequence
    if isinstance(lhs, Sequence) and isinstance(rhs, Sequence):
        # Short-circuit for unequal length
        if len(lhs) != len(rhs):
            return True
        return any_(not_equal(l, r) for l, r in zip(lhs, rhs))

    if hasattr(lhs, "__ne__"):
        return lhs != rhs
    elif hasattr(rhs, "__ne__"):
        return rhs != lhs
    else:
        return not_(equal(lhs, rhs))


def in_(lhs: object, rhs: Any) -> Union[bool, Boolean]:
    if not is_dynamic_expression(lhs) and not is_dynamic_expression(rhs):
        return lhs in rhs

    if not isinstance(rhs, Sequence):
        raise DSLRuntimeError(
            f"'in' not supported between instances of {type(lhs)} and {type(rhs)}"
        )

    return any_(equal(lhs, r) for r in rhs)


def _lte_gte(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
    op: str,
) -> Union[Boolean, bool]:
    def native_lte_gte(
        lhs: Union[Numeric, ir.Value, int, float, bool],
        rhs: Union[Numeric, ir.Value, int, float, bool],
        op: str,
    ) -> Union[Boolean, bool]:
        if op == "<":
            return lhs < rhs
        elif op == "<=":
            if hasattr(lhs, "__le__"):
                return lhs <= rhs
            else:
                return not_(lhs > rhs)
        elif op == ">":
            return lhs > rhs
        elif op == ">=":
            if hasattr(lhs, "__ge__"):
                return lhs >= rhs
            else:
                return not_(lhs < rhs)
        else:
            raise DSLRuntimeError(f"Unsupported comparison operator: {op}")

    if not is_dynamic_expression(lhs) and not is_dynamic_expression(rhs):
        return native_lte_gte(lhs, rhs, op)

    # Both sequence, comparisons other than == and != do not allow mixing different types of sequences
    if (
        isinstance(lhs, Sequence)
        and isinstance(rhs, Sequence)
        and type(lhs) == type(rhs)
    ):
        unequal_found: Union[Numeric, bool] = False
        comp_results = []
        mask = []
        for l, r in zip(lhs, rhs):
            is_equal = equal(l, r)
            mask.append(not_(or_(is_equal, unequal_found)))
            unequal_found = not_(is_equal)
            comp_results.append(_lte_gte(l, r, op))

        result = any_(and_(r, m) for r, m in zip(comp_results, mask))

        if len(lhs) != len(rhs):
            # Ref https://docs.python.org/3/tutorial/datastructures.html#comparing-sequences-and-other-types
            # If one sequence is an initial sub-sequence of the other, the shorter sequence is the smaller (lesser) one
            has_valid_mask = any_(mask)
            if op == "<":
                length_result = len(lhs) < len(rhs)
            elif op == ">":
                length_result = len(lhs) > len(rhs)
            elif op == "<=":
                length_result = len(lhs) <= len(rhs)
            elif op == ">=":
                length_result = len(lhs) >= len(rhs)
            if type(has_valid_mask) == bool:
                return result if has_valid_mask else length_result
            else:
                return select_(has_valid_mask, result, length_result)
        else:
            if op in {"<=", ">="}:
                # If no unequal, return True
                return select_(unequal_found, result, True)
            else:
                return result
    else:
        return native_lte_gte(lhs, rhs, op)


def greater_than(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    return _lte_gte(lhs, rhs, ">")


def greater_equal(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    return _lte_gte(lhs, rhs, ">=")


def less_than(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    return _lte_gte(lhs, rhs, "<")


def less_equal(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
) -> Union[Boolean, bool]:
    return _lte_gte(lhs, rhs, "<=")


def _compare_dispatch(
    lhs: Union[Numeric, ir.Value, int, float, bool],
    rhs: Union[Numeric, ir.Value, int, float, bool],
    op: str,
) -> Union[Boolean, bool]:
    """
    Dispatches the comparison operation between lhs and rhs based on the given operator.

    :param lhs: The left-hand side operand for the comparison.
    :param rhs: The right-hand side operand for the comparison.
    :param op: The comparison operator as a string. Supported operators are:
        - "is", "is not": Python identity comparisons.
        - "in", "not in": Membership tests.
        - "==", "!=": Equality and inequality.
        - "<", ">", "<=", ">=": Relational comparisons.
    :return: The result of the comparison, which may be a boolean or a DSL-specific type.
    :raises DSLRuntimeError: If the operator is not supported.
    """
    # 'is' and 'is not' are pure python operators
    if op == "is":
        return lhs is rhs
    elif op == "is not":
        return lhs is not rhs
    elif op == "in":
        return in_(lhs, rhs)
    elif op == "not in":
        return not_(in_(lhs, rhs))
    elif op == "==":
        return equal(lhs, rhs)
    elif op == "!=":
        return not_equal(lhs, rhs)
    elif op == "<":
        return less_than(lhs, rhs)
    elif op == ">":
        return greater_than(lhs, rhs)
    elif op == ">=":
        return greater_equal(lhs, rhs)
    elif op == "<=":
        return less_equal(lhs, rhs)
    else:
        raise DSLRuntimeError(f"Unsupported comparison operator: {op}")


def _compare_executor(
    left: Union[Numeric, ir.Value, int, float, bool],
    comparators: List[Union[Numeric, ir.Value, int, float, bool]],
    ops: List[str],
) -> Union[Numeric, int, float, bool]:
    # Fast path for single comparison
    if len(comparators) == 1:
        return _compare_dispatch(left, comparators[0], ops[0])

    # Chain comparison, dispatch in a loop
    result: Union[Numeric, int, float, bool] = True
    current = left
    for comparator, op in zip(comparators, ops):
        cmp_result = _compare_dispatch(current, comparator, op)
        result = and_(result, cmp_result)
        current = comparator

    return result


def _builtin_redirector(fcn: Callable[..., object]) -> Callable[..., object]:
    def builtin_wrapper(fcn: Any, *args: Any, **kwargs: Any) -> Any:
        if is_dynamic_expression(args):
            if kwargs:
                # Redirected built-ins do not support keyword arguments
                raise DSLRuntimeError(
                    f"Unsupported keyword arguments for built-in function: {fcn}"
                )
            if fcn is builtins.max:
                return max(*args)
            elif fcn is builtins.min:
                return min(*args)
            elif fcn is builtins.any:
                return any_(*args)
            elif fcn is builtins.all:
                return all_(*args)
            else:
                raise DSLRuntimeError(f"Unsupported built-in function: {fcn}")
        else:
            return fcn(*args, **kwargs)

    return functools.partial(builtin_wrapper, fcn)


# =============================================================================
# Set the AST decorator
# =============================================================================

# Set the DSL specific functions
executor.set_functions(
    is_dynamic_expression=is_dynamic_expression,
    loop_execute_range_dynamic=_loop_execute_range_dynamic,
    if_dynamic=_if_execute_dynamic,
    while_dynamic=_while_execute_dynamic,
    compare_executor=_compare_executor,
    builtin_redirector=_builtin_redirector,
    ifexp_dynamic=_ifexp_execute_dynamic,
)


class DSLCudaVerNotImplemented(DSLNotImplemented):
    """
    Exception raised when a feature is not supported for DSL with CUDA version less than the required version.
    """

    def __init__(self, feature: str, required_version: str):
        super().__init__(
            message=f"{feature} is not supported for DSL with CUDA version less than {required_version}",
            suggestion=f"Consider upgrading to CUDA version {required_version}+ based DSL",
        )
