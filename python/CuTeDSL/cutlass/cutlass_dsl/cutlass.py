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
    Annotated,
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
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import fields
from math import ceil
from numbers import Integral
from itertools import chain
import sys
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
    get_mlir_types,
    Pointer,
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
from ..base_dsl.common import (
    DSLRuntimeError,
    DSLUserCodeError,
    DSLNotImplemented,
    active_env_manager,
)
from ..base_dsl.diagnostics import DiagId
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
from ..base_dsl.jit_executor import ExecutionArgs, _is_pointer_annotation  # noqa: F401
from ..base_dsl.runtime import cuda as cuda_helpers
from .cuda_stream_adapter import CudaDriverStreamAdapter, CudaRuntimeStreamAdapter  # noqa: F401
from .cuda_library_adapter import CudaDialectLibraryAdapter  # noqa: F401
from .cuda_event_adapter import CudaDriverEventAdapter, CudaRuntimeEventAdapter  # noqa: F401
from .cuda_jit_executor import CudaDialectJitCompiledFunction

# MLIR Imports
from cutlass._mlir import ir, execution_engine, passmanager
from cutlass._mlir.dialects import (
    arith,
    func,  # noqa: F401
    gpu,  # noqa: F401
    scf,
    cute,
    gpu as cutlass_gpu,  # noqa: F401
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
from .._mlir_helpers import arith as cutlass_arith
from .._mlir_helpers.op import dsl_user_op
from .._mlir_helpers.arith import const

from ..base_dsl.ast_helpers import (
    executor,
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


def _is_cutlass_pointer_annotation(annotation: object) -> bool:
    if get_origin(annotation) is Annotated:
        annotation = get_args(annotation)[0]
    return type(annotation).__name__ == "TypedPointer" or (
        getattr(annotation, "__name__", None) == "Pointer"
        and getattr(annotation, "__module__", "").endswith("cutlass.base_dsl.typing")
    )


def _is_cute_pointer_like(arg: object) -> bool:
    module = type(arg).__module__
    return (
        module.startswith("cutlass.cute")
        and hasattr(arg, "dtype")
        and hasattr(arg, "memspace")
        and (
            hasattr(arg, "__get_mlir_types__")
            or hasattr(arg, "__extract_mlir_values__")
        )
    )


def _cutlass_pointer_dtype_addrspace(
    annotation: object,
    arg: object,
) -> tuple[type[Numeric], int]:
    if type(annotation).__name__ == "TypedPointer":
        dtype = annotation.dtype  # type: ignore[attr-defined]
        space = annotation.space  # type: ignore[attr-defined]
    else:
        dtype = getattr(arg, "dtype", Int8)
        space = getattr(arg, "memspace", 0)
    addrspace = getattr(space, "value", space)
    return dtype, int(addrspace)


def _build_kernel_attrs(config: BaseDSL.LaunchConfig) -> dict:
    """Build launch-time CUDA function attrs that are known before compilation."""
    ATTR_SMEM_CARVEOUT = cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_PREFERRED_SHARED_MEMORY_CARVEOUT
    kernel_attrs = {}
    if config.preferred_smem_carveout is not None:
        assert isinstance(config.preferred_smem_carveout, int)
        kernel_attrs = {ATTR_SMEM_CARVEOUT: config.preferred_smem_carveout}

    return kernel_attrs


class CutlassBaseDSL(BaseDSL):
    """This abstract class provides a DSL for Cutlass."""

    _ALLOWED_EXTRA_KERNEL_VALUE_ATTRS: frozenset[str] = frozenset()
    _KERNEL_ATTR_SPEC_FIELD: Optional[str] = None

    @staticmethod
    def _make_kernel_decorator(
        target_cls: type["CutlassBaseDSL"],
        frame: Any,
        *dargs: Any,
        **dkwargs: Any,
    ) -> Any:
        """Build a ``@kernel`` decorator that dispatches through ``target_cls``.

        Centralises the ``attributes=...`` kwarg handling shared between
        ``CuTeDSL.kernel`` (with ``is_experimental=True``) and
        ``CuteExperimentalDSL.kernel``: when ``attributes`` is supplied,
        the resulting decorator stamps the spec onto the function via
        ``target_cls._KERNEL_ATTR_SPEC_FIELD`` before running the normal
        jit wrapping logic. The caller is responsible for capturing the
        user's source frame so source locations point to the call site
        rather than this helper.
        """
        attr_spec = dkwargs.pop("attributes", None)
        kernel_decorator = BaseDSL.jit_runner(
            target_cls, "_kernel_helper", frame, *dargs, **dkwargs
        )
        if attr_spec is None:
            return kernel_decorator

        def attach_and_decorate(func: Callable[..., None]) -> Callable[..., None]:
            if target_cls._KERNEL_ATTR_SPEC_FIELD is None:
                raise DSLUserCodeError(
                    DiagId.CONFIG_ATTRIBUTES_UNSUPPORTED,
                )
            setattr(func, target_cls._KERNEL_ATTR_SPEC_FIELD, attr_spec)
            return kernel_decorator(func)

        return attach_and_decorate

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
        self._smem_partition_num: Optional[int] = 2
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
                raise DSLUserCodeError(
                    DiagId.CONFIG_RESOLVER_INVALID_RETURN,
                )
            return resolved

        raise DSLUserCodeError(
            DiagId.CONFIG_ATTRIBUTES_INVALID_TYPE,
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
                raise DSLUserCodeError(
                    DiagId.CONFIG_ATTR_KEY_UNSUPPORTED,
                    key=key,
                    suggestion=suggestion,
                )
            if isinstance(value, ir.Attribute):
                converted_attrs[key] = value
            elif isinstance(value, str):
                converted_attrs[key] = ir.StringAttr.get(value)
            else:
                raise DSLUserCodeError(
                    DiagId.CONFIG_ATTR_VALUE_TYPE_INVALID,
                    key=key,
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
                    raise DSLUserCodeError(
                        DiagId.CONFIG_MAX_THREADS_DYNAMIC,
                    )
            # Use user-defined maxntid
            ret["nvvm.maxntid"] = ir.Attribute.parse(f"array<i32 : {max_ntid_str}>")

        # Add optional minimum blocks per multiprocessor
        if config.min_blocks_per_mp > 0:
            ret["nvvm.minctasm"] = ir.Attribute.parse(
                f"{config.min_blocks_per_mp} : i32"
            )
        # Add optional maximum shared memory per multiprocessor
        # to support preferred shared memory carveout calculation
        if config.preferred_smem_carveout is None and config.min_blocks_per_mp > 1:
            max_smem_per_mp = cuda_helpers.get_device_attribute(
                cuda_helpers.cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_MULTIPROCESSOR
            )
            ret["smem.max_smem_per_mp"] = ir.Attribute.parse(f"{max_smem_per_mp} : i64")

        # Pass user config specified smem size to support calculation
        if config.smem is not None and isinstance(config.smem, int):
            ret["smem.config_smem_size"] = ir.Attribute.parse(f"{config.smem} : i64")

        # Allow mutually exclusive code paths to reuse shared memory
        if config.smem_merge_branch_allocs:
            ret["smem.merge_branch_allocs"] = ir.UnitAttr.get()

        # Set smem partition num
        if self._smem_partition_num is not None:
            ret["smem.partition_num"] = ir.IntegerAttr.get(
                ir.IntegerType.get_signless(32), self._smem_partition_num
            )

        return ret

    @staticmethod
    def _normalize_static_cluster_dim(dim: Any, config_name: str) -> int:
        if is_dynamic_expression(dim):
            raise DSLUserCodeError(
                DiagId.CONFIG_CLUSTER_DYNAMIC,
                config_name=config_name,
            )

        value = dim.value if isinstance(dim, Integer) else dim
        if isinstance(value, bool) or not isinstance(value, Integral):
            raise DSLUserCodeError(
                DiagId.TYPE_CLUSTER_NOT_INT,
                config_name=config_name,
            )

        return int(value)

    @classmethod
    def _materialize_cluster_shape_attr(
        cls, dims: Sequence[Any], config_name: str
    ) -> ir.Attribute:
        normalized_dims = [
            cls._normalize_static_cluster_dim(dim, config_name) for dim in dims
        ]
        dims_str = ",".join(map(str, normalized_dims))
        return ir.Attribute.parse(f'#cute.shape<"({dims_str})">')

    @classmethod
    def _get_cluster_kernel_attrs(
        cls, config: BaseDSL.LaunchConfig
    ) -> dict[str, ir.Attribute]:
        if config.has_fallback_cluster and not config.has_cluster:
            raise DSLUserCodeError(
                DiagId.CONFIG_FALLBACK_CLUSTER_REQUIRES_CLUSTER,
            )

        if config.has_fallback_cluster:
            assert config.cluster is not None
            assert config.fallback_cluster is not None
            # Mirror the existing runtime launch convention for mixed cluster:
            # LaunchConfig.cluster is the preferred shape, while
            # LaunchConfig.fallback_cluster becomes the IR's cluster_shape attr.
            return {
                "preferred_cluster_shape": cls._materialize_cluster_shape_attr(
                    config.cluster, "cluster"
                ),
                "cluster_shape": cls._materialize_cluster_shape_attr(
                    config.fallback_cluster, "fallback_cluster"
                ),
            }

        if config.has_cluster:
            assert config.cluster is not None
            return {
                "cluster_shape": cls._materialize_cluster_shape_attr(
                    config.cluster, "cluster"
                )
            }

        return {}

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
        # The pybind module file may be CTK-tagged (`_cutlass_ir.cu12.cpython-…so`
        # or `_cutlass_ir.cu13.cpython-…so`) when multiple CTK flavors coexist in
        # the same `_mlir_libs/` directory. The CTK-aware loader has already
        # picked one and bound it as `cutlass._mlir._mlir_libs._cutlass_ir`, so
        # the loaded module's path is authoritative — use it unconditionally
        # rather than re-scanning the candidate dirs (which can resolve to a
        # different `_mlir_libs/` than the loader actually consulted, e.g. when
        # `cutlass._mlir.__path__` is a CI/PYTHONPATH overlay).
        loaded = sys.modules.get("cutlass._mlir._mlir_libs._cutlass_ir")
        loaded_file = getattr(loaded, "__file__", None) if loaded is not None else None
        if not loaded_file:
            # Loader hasn't run (very early import path, or someone deleted
            # the sys.modules entry). Force it to run via import_module —
            # this is idempotent if the module is already loaded, and
            # otherwise routes through the CTK-aware loader in
            # _mlir_libs/__init__.py so we hash exactly the binary the
            # runtime would. Avoids a non-deterministic glob fallback
            # (which could pick the wrong flavor when both cu12 and cu13
            # .so files coexist) and a bare StopIteration when no match
            # is found.
            from importlib import import_module

            try:
                loaded = import_module("cutlass._mlir._mlir_libs._cutlass_ir")
            except ImportError as e:
                raise DSLRuntimeError(
                    "Could not load cutlass._mlir._mlir_libs._cutlass_ir. "
                    "Please re-install the package."
                ) from e
            loaded_file = getattr(loaded, "__file__", None)
            if not loaded_file:
                raise DSLRuntimeError(
                    "Loaded cutlass._mlir._mlir_libs._cutlass_ir has no "
                    "__file__ attribute. Please re-install the package."
                )
        so_path = loaded_file
        giant_dso_name = Path(loaded_file).name
        # Re-anchor `mlir_libs_path` to where the loaded binary actually
        # lives so any subsequent path-derived state stays consistent.
        mlir_libs_path = Path(loaded_file).parent
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

        # Walk the filesystem to collect .py files for hashing. We deliberately
        # avoid pkgutil.walk_packages here because it imports every module it
        # discovers — and modules with top-level decorator side effects (e.g.
        # _mlir_helpers/arith.py's @ir.register_value_caster) blow up if they
        # end up reachable via two import paths in the same process. The hash
        # only needs file contents, not importability.
        for entry in sorted(os.listdir(dsl_path)):
            sub = os.path.join(dsl_path, entry)
            if not os.path.isdir(sub):
                continue
            if not os.path.isfile(os.path.join(sub, "__init__.py")):
                # Skip non-package directories (build/, examples/, doc/, ...).
                # This matches pkgutil.walk_packages, which only descends into
                # regular packages found on the given path list.
                continue
            for root, dirs, fnames in os.walk(sub):
                # Only descend into subdirectories that are themselves
                # regular packages — matches pkgutil.walk_packages, which
                # treats dirs without __init__.py as outside the import
                # namespace and skips them.
                dirs[:] = [
                    d
                    for d in dirs
                    if d != "__pycache__"
                    and os.path.isfile(os.path.join(root, d, "__init__.py"))
                ]
                for fname in fnames:
                    if not fname.endswith(".py"):
                        continue
                    path = os.path.join(root, fname)
                    rel = os.path.relpath(path, dsl_path)
                    no_ext = rel[: -len(".py")]
                    init_suffix = os.sep + "__init__"
                    if no_ext.endswith(init_suffix):
                        no_ext = no_ext[: -len(init_suffix)]
                    key = "cutlass." + no_ext.replace(os.sep, ".")
                    try:
                        size = os.path.getsize(path)
                    except OSError as e:
                        raise DSLRuntimeError(
                            f"Failed to read module file {key}. "
                            "The file may not exist or may not be readable. "
                            "Please re-install the package."
                        ) from e
                    files.append((key, path, size))

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

    def _runtime_can_run_compiled(
        self, runtime_arch: Optional[str], compiled_arch: Optional[str]
    ) -> bool:
        """Allow a family-portable target (e.g. sm_100f) to run on its family
        hardware (e.g. sm_100a), in addition to an exact arch match."""
        if runtime_arch == compiled_arch:
            return True
        if runtime_arch is None or compiled_arch is None:
            return False
        from ..base_dsl.arch import Arch

        try:
            return Arch.from_string(runtime_arch).can_run_binary_built_for(
                Arch.from_string(compiled_arch)
            )
        except KeyError:
            return False

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
            (
                tvm_ffi_spec_params,
                kwargs_wrapper_spec,
                map_dataclass_to_tuple,
            ) = self._tvm_ffi_args_spec_converter(
                function_name, signature, full_args, full_kwargs
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
                # Route through the kwargs-capable compiled class whenever
                # the signature has kwonly/defaults OR any positional arg
                # carries a dataclass instance (detected by the spec
                # converter, including Union[...] over dataclasses). The
                # kwargs wrapper is the only place tvm-ffi's
                # ``map_dataclass_to_tuple`` unpack hook fires.
                if (
                    kwargs_wrapper_spec.kwonly_names
                    or kwargs_wrapper_spec.arg_defaults
                    or kwargs_wrapper_spec.arg_names
                    or map_dataclass_to_tuple
                ):
                    return TVMFFIJitCompiledFunctionWithKwargs(
                        *args,
                        **kwargs,
                        kwargs_wrapper_spec=kwargs_wrapper_spec,
                        map_dataclass_to_tuple=map_dataclass_to_tuple,
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
        launch_completion_event: Optional[ir.Value] = None,
        launch_completion_event_flags: Optional[int | Int32] = None,
        programmatic_event: Optional[ir.Value] = None,
        programmatic_event_flags: Optional[int | Int32] = None,
        programmatic_event_trigger_at_block_start: Optional[int | Int32] = None,
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

        if launch_completion_event is not None:
            event = launch_completion_event
            if launch_completion_event_flags is None:
                launch_completion_event_flags = 0
            flags = Int32(launch_completion_event_flags).ir_value(loc=loc, ip=ip)
            cuda_dialect.launch_cfg_launch_completion_event(
                cfg, event, flags, loc=loc, ip=ip
            )

        if programmatic_event is not None:
            event = programmatic_event
            if programmatic_event_flags is None:
                programmatic_event_flags = 0
            flags = Int32(programmatic_event_flags).ir_value(loc=loc, ip=ip)
            if programmatic_event_trigger_at_block_start is None:
                programmatic_event_trigger_at_block_start = 0
            trigger_at_block_start = Int32(
                programmatic_event_trigger_at_block_start
            ).ir_value(loc=loc, ip=ip)
            cuda_dialect.launch_cfg_programmatic_event(
                cfg, event, flags, trigger_at_block_start, loc=loc, ip=ip
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
                # kernel_smem_size to auto infer smem size
                smem_usage = cute.kernel_smem_size(kernel_name=kernelSym, loc=loc)
                # Use auto inferred smem size when user not specify
                if cfg.smem is None:
                    cfg.smem = smem_usage
                else:
                    # Warn user if specified launch cfg.smem size is insufficient
                    cfg.smem = const(cfg.smem)
                    smem_msg = (
                        f"\nError: shared memory usage in '{kernelSym}' "
                        "may exceed available memory set in kernel launch. "
                        "Allocated: {} bytes. Used: {} bytes.\n\n"
                    )
                    if_generate(
                        Int64(cfg.smem) < smem_usage,
                        lambda: cute.print_([cfg.smem, smem_usage], fmt=smem_msg),
                        loc=loc,
                    )

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
                    launch_completion_event=cfg.launch_completion_event,
                    launch_completion_event_flags=cfg.launch_completion_event_flags,
                    programmatic_event=cfg.programmatic_event,
                    programmatic_event_flags=cfg.programmatic_event_flags,
                    programmatic_event_trigger_at_block_start=cfg.programmatic_event_trigger_at_block_start,
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
            # Ignore metadata for annotated types
            if get_origin(arg_annotation) is Annotated:
                arg_annotation = get_args(arg_annotation)[0]

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
                    or (
                        _is_cutlass_pointer_annotation(ty)
                        and _is_cute_pointer_like(arg)
                    )
                    or (get_origin(ty) is tuple and isinstance(arg, tuple))
                    or (
                        get_origin(ty) is Annotated and isinstance(arg, get_args(ty)[0])
                    )
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

            elif getattr(
                arg, "_python_pointer_address_arg", False
            ) is True and _is_pointer_annotation(arg_annotation):
                pass

            elif _is_cutlass_pointer_annotation(
                arg_annotation
            ) and _is_cute_pointer_like(arg):
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
            if _is_cutlass_pointer_annotation(arg_spec) and _is_cute_pointer_like(arg):
                _dtype, addrspace = _cutlass_pointer_dtype_addrspace(arg_spec, arg)
                from cutlass._mlir.dialects import llvm as llvm_dialect

                jit_arg_type.append(llvm_dialect.PointerType.get(addrspace))
                jit_arg_attr.append(default_attr)
                if is_host:
                    jit_exec_arg.extend(get_c_pointers(arg))
                else:
                    jit_exec_arg.append(arg.to_llvm_ptr())
            elif is_cute_algebra_type(arg_spec):
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
            if _is_cutlass_pointer_annotation(arg_spec) and _is_cute_pointer_like(arg):
                dtype, addrspace = _cutlass_pointer_dtype_addrspace(arg_spec, arg)
                blk_args = fop_args[iv_block_args : iv_block_args + 1]
                ir_arg.append(Pointer(blk_args[0], dtype=dtype, space=addrspace))
                iv_block_args += 1
            elif is_cute_algebra_type(arg_spec):
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

    @classmethod
    def jit(cls, *dargs: Any, **dkwargs: Any) -> Any:
        """
        Decorator to mark a function for JIT compilation for Host code.

        Parameters
        ----------
        is_experimental : bool, optional
            When True, route compilation through the experimental CuTe DSL
            path (equivalent to ``cute.experimental.jit``). Defaults to
            False.

            This option exists to ease the migration of users away from
            ``cute.experimental`` toward the unified ``cute`` decorator;
            ``cute.experimental`` is deprecated and will be removed once
            its functionality has been folded into ``cute``.
        """
        # Pop before forwarding so jit_runner does not see the alias kwarg.
        is_experimental = dkwargs.pop("is_experimental", False)
        # CuteExperimentalDSL is defined later in this module; it is
        # resolved lazily here at call time, so the forward reference is
        # safe.
        target_cls: type[BaseDSL] = CuteExperimentalDSL if is_experimental else cls
        # Capture the user's call site (mirroring BaseDSL.jit) so that
        # decorator source locations are reported relative to the caller,
        # not this override.
        frame = inspect.currentframe().f_back  # type: ignore[union-attr]
        return BaseDSL.jit_runner(target_cls, "_func", frame, *dargs, **dkwargs)

    @classmethod
    def kernel(cls, *dargs: Any, **dkwargs: Any) -> Any:
        """
        Decorator to mark a function for JIT compilation for GPU device code.

        Parameters
        ----------
        is_experimental : bool, optional
            When True, route compilation through the experimental CuTe DSL
            path (equivalent to ``cute.experimental.kernel``). Defaults to
            False.

            This option exists to ease the migration of users away from
            ``cute.experimental`` toward the unified ``cute`` decorator;
            ``cute.experimental`` is deprecated and will be removed once
            its functionality has been folded into ``cute``. Pair this
            flag with ``cute.jit(is_experimental=True)`` and
            ``cute.compile(..., is_experimental=True)`` so that the host
            launcher, the device kernel, and the explicit compile entry
            point all dispatch through the same DSL; mixing experimental
            and non-experimental decorations on the same kernel triggers
            preprocessor mismatches.
        attributes : optional
            Kernel-level attribute spec, only supported when routing to
            ``CuteExperimentalDSL`` (i.e. ``is_experimental=True``).
            Stamped onto the wrapped function via
            ``CuteExperimentalDSL._KERNEL_ATTR_SPEC_FIELD``.
        """
        is_experimental = dkwargs.pop("is_experimental", False)
        # CuteExperimentalDSL is defined later in this module; the
        # forward reference is resolved lazily at call time.
        target_cls: type[CutlassBaseDSL] = (
            CuteExperimentalDSL if is_experimental else cls
        )
        # Capture the user's call site here rather than relying on a
        # nested method, so source locations point at the caller rather
        # than this override.
        current_frame = inspect.currentframe()
        assert current_frame is not None
        frame = current_frame.f_back
        return CutlassBaseDSL._make_kernel_decorator(
            target_cls, frame, *dargs, **dkwargs
        )

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

    @staticmethod
    def generate_device_func_op(
        arg_types: List[Any],
        ret_types: List[Any],
        func_name: str,
        arg_attrs: Any = None,
        loc: Optional[ir.Location] = None,
    ) -> Any:
        """Generate a cuda.func op (__device__ function) with optional return types."""
        func_op = cuda_dialect.FuncOp(
            func_name, ir.FunctionType.get(arg_types, ret_types), loc=loc
        )
        if arg_attrs is not None:
            func_op.arg_attrs = arg_attrs
        return func_op

    def _device_func(
        self, funcBody: Callable[..., Any], *args: Any, **kwargs: Any
    ) -> Any:
        """Generate a __device__ function (cuda.func inside gpu.module).

        Unlike _func (host wrapper) or _kernel_helper (__global__ kernel),
        this generates only a gpu.module containing a cuda.func with no
        host-side wrapper and no launch op. Supports return values.
        """
        # Device compilation can be invoked directly by cute.compile.
        with active_env_manager(self.envar):
            return self._device_func_impl(funcBody, *args, **kwargs)

    def _device_func_impl(
        self, funcBody: Callable[..., Any], *args: Any, **kwargs: Any
    ) -> Any:
        if ir.Context.current is not None and ir.InsertionPoint.current is not None:
            return funcBody(*args, **kwargs)

        # Device functions have no host entry point — never create a JIT engine.
        kwargs.pop("no_jit_engine", None)
        setup = self._prepare_compilation(funcBody, *args, **kwargs)

        # Extract return type from Python annotation (e.g. -> Float32)
        ret_annotation = setup.sig.return_annotation
        if ret_annotation is inspect.Signature.empty:
            ret_annotation = None

        log().debug(f"Generating MLIR for device function '{setup.function_name}'")

        # Generate MLIR
        with ir.Context() as ctx, self.get_ir_location(setup.location):
            ctx.enable_multithreading(False)
            try:
                from cutlass._mlir.dialects import llvm as llvm_dialect
                from ..base_dsl.typing import NumericMeta

                # Auto-instantiate bare types (e.g. Int32, MyStruct) into
                # zero-valued instances. Struct construction creates MLIR ops,
                # so we build them in a temporary module then discard it.
                def _instantiate_bare(arg: Any) -> Any:
                    if isinstance(arg, NumericMeta):
                        return arg(0)
                    if isinstance(arg, type) and hasattr(arg, "_field_names"):
                        kw = {}
                        for fn in arg._field_names:
                            kw[fn] = _instantiate_bare(arg._field_annotations[fn])  # type: ignore[attr-defined]
                        return arg(**kw)
                    return arg

                needs_instantiation = any(
                    isinstance(a, (type, NumericMeta)) for a in setup.canonicalized_args
                )
                if needs_instantiation:
                    from .._mlir.dialects import func as func_dialect

                    tmp = ir.Module.create()
                    with ir.InsertionPoint(tmp.body):
                        tmp_fop = func_dialect.FuncOp(
                            "_bare_type_init", ir.FunctionType.get([], [])
                        )
                        with ir.InsertionPoint(tmp_fop.add_entry_block()):
                            setup.canonicalized_args = tuple(
                                _instantiate_bare(a) for a in setup.canonicalized_args
                            )
                            func_dialect.ReturnOp([])

                OpaquePointer: Optional[type] = None
                # For device functions, opaque pointer annotations mean
                # "pointer in generic address space".  Create a copy of the
                # annotations with those replaced so the type-generation
                # path doesn't reject them, but keep the originals intact for
                # header generation.
                pointer_arg_indices = set()
                typegen_sig = setup.sig
                if OpaquePointer is not None:
                    typegen_params = []
                    for idx, (name, param) in enumerate(setup.sig.parameters.items()):
                        if param.annotation is OpaquePointer:
                            pointer_arg_indices.add(idx)
                            typegen_params.append(
                                param.replace(annotation=inspect.Parameter.empty)
                            )
                        else:
                            typegen_params.append(param)
                    if pointer_arg_indices:
                        typegen_sig = setup.sig.replace(parameters=typegen_params)

                exe_args, func_types, adapted_args = self.generate_mlir_function_types(
                    funcBody,
                    setup.function_name,
                    setup.canonicalized_args,
                    setup.canonicalized_kwargs,
                    typegen_sig,
                    compile_only=setup.compile_only,
                )

                # Device function pointers use generic address space (0).
                generic_ptr = llvm_dialect.PointerType.get(0)
                for i, ty in enumerate(func_types):
                    if i in pointer_arg_indices:
                        func_types[i] = generic_ptr
                        continue
                    try:
                        ptr_ty = llvm_dialect.PointerType(ty)
                        if ptr_ty.address_space != 0:
                            func_types[i] = generic_ptr
                    except Exception:
                        pass

                # Resolve return types from annotation.
                # Mirrors _annotation_to_mlir_type: handles callable mlir_type
                # (some DSL types) and the _struct_type fallback (@native_struct).
                ret_types = []
                if ret_annotation is not None:
                    if hasattr(ret_annotation, "mlir_type"):
                        mt = ret_annotation.mlir_type
                        ret_types = [mt() if callable(mt) else mt]
                    elif hasattr(ret_annotation, "_struct_type"):
                        ret_types = [ret_annotation._struct_type]
                    else:
                        raise DSLUserCodeError(
                            DiagId.TYPE_DEVICE_FUNC_RETURN_INVALID,
                        )

                loc = self.get_ir_location(setup.location)
                module = ir.Module.create(loc=loc)
                module.operation.attributes["gpu.container_module"] = ir.UnitAttr.get()

                with ir.InsertionPoint(module.body):
                    self._build_gpu_module(setup.gpu_module_attrs, loc=loc)

                    with self._enter_gpu_module():
                        fop = self.generate_device_func_op(
                            func_types,
                            ret_types,
                            setup.function_name,
                            loc=loc,
                        )
                        fop.sym_visibility = ir.StringAttr.get("public")

                        arg_locs = [fop.operation.location for _ in func_types]
                        entry_block = fop.add_entry_block(arg_locs=arg_locs)

                        with ir.InsertionPoint(entry_block):
                            ir_args, ir_kwargs = self.generate_execution_arguments(
                                setup.canonicalized_args,
                                setup.canonicalized_kwargs,
                                fop,
                                setup.sig,
                            )

                            result = funcBody(*ir_args, **ir_kwargs)

                            # Generate return op
                            if ret_types:
                                if result is None:
                                    raise DSLUserCodeError(
                                        DiagId.TYPE_DEVICE_FUNC_RETURN_NONE,
                                    )
                                if hasattr(result, "ir_value"):
                                    ret_val = result.ir_value()
                                elif hasattr(result, "__extract_mlir_values__"):
                                    extracted_vals = result.__extract_mlir_values__()
                                    if len(extracted_vals) != 1:
                                        raise DSLUserCodeError(
                                            DiagId.TYPE_DEVICE_FUNC_RETURN_COUNT,
                                            count=len(extracted_vals),
                                        )
                                    ret_val = extracted_vals[0]
                                else:
                                    ret_val = result
                                cuda_dialect.ReturnOp([ret_val], loc=loc)
                            else:
                                cuda_dialect.ReturnOp([], loc=loc)

                # Increment kernel count so the gpu.module is not removed
                self.num_kernels += 1

                from ..base_dsl.export.c_header_generator import CHeaderGenerator

                ptr_types = (OpaquePointer,) if OpaquePointer is not None else ()
                device_header = CHeaderGenerator.generate_device_header(
                    setup.function_name,
                    setup.sig,
                    ret_annotation=ret_annotation,
                    pointer_types=ptr_types,
                )

                self._run_trace_finalize_hooks(module, setup.function_name)
                module = self.build_module(module, setup.function_name)

                # dryrun: generate IR and header, skip compilation
                if self.envar.dryrun:
                    print(device_header)
                    return result

                module_hash = self.get_module_hash(module, setup.function_name)
                jit_function = self.compile_and_cache(
                    module,
                    module_hash,
                    setup.function_name,
                    setup.pipeline,
                    setup.sig,
                    setup.no_cache,
                    no_jit_engine=True,
                )

                # Attach device compilation artifacts.
                # The pipeline always dumps .cubin; with --compile-only it's a
                # relocatable object, so rename to .o for clarity.
                cubin_path = self.compile_options.full_cubin_path
                obj_path = None
                if cubin_path:
                    obj_path = cubin_path.rsplit(".cubin", 1)[0] + ".o"
                    try:
                        os.rename(cubin_path, obj_path)
                    except FileNotFoundError:
                        # Already renamed or not produced.
                        if not os.path.exists(obj_path):
                            obj_path = None

                jit_function.device_header = device_header
                jit_function.device_object_path = obj_path

                ptx_path = self.compile_options.full_ptx_path
                jit_function.device_ptx_path = (
                    ptx_path if ptx_path and os.path.exists(ptx_path) else None
                )
            finally:
                self.post_compilation_cleanup()

        if setup.compile_only:
            return jit_function

        return result


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
            raise DSLUserCodeError(
                DiagId.ARG_WORKSPACE_COUNT_MISMATCH,
                expected=self.total_added_arguments,
                got=n_extra,
            )
        return super().__call__(*args, **kwargs)


# =============================================================================
# CuteExperimental DSL Class
# =============================================================================


class CuteExperimentalDSL(CutlassBaseDSL):
    _KERNEL_EXTRA_ARGS_ATTR = "lir.kernel_extra_args"
    _ALLOWED_EXTRA_KERNEL_VALUE_ATTRS: frozenset[str] = frozenset(
        {"lir.tma_update_mode", "lir.tma_override_mode"}
    )
    _KERNEL_ATTR_SPEC_FIELD: Optional[str] = "_cute_experimental_kernel_attributes"
    # Marks this class as the deprecated "experimental" CuTe DSL so
    # ``cute.compile(..., is_experimental=True)`` can validate that the
    # function being compiled was actually decorated through the
    # experimental path (``@cute.jit(is_experimental=True)`` /
    # ``@cute.kernel(is_experimental=True)``).
    _is_experimental_dsl: bool = True
    JitCompiledFunction = _CuteExperimentalJitCompiledFunction

    def __init__(self) -> None:
        name = "CUTE_EXPERIMENTAL_DSL"
        compiler_provider = compiler.Compiler(passmanager, execution_engine)
        pass_sm_arch_name = "cubin-chip"

        super().__init__(name, compiler_provider, pass_sm_arch_name, preprocess=True)

    @classmethod
    def kernel(cls, *dargs: Any, **dkwargs: Any) -> Any:
        # Capture the caller's frame here rather than delegating to a
        # nested helper that uses ``inspect.currentframe().f_back``,
        # which would record *this* frame instead of the user's source
        # location (f_back would land in this override rather than in
        # the user file).
        current_frame = inspect.currentframe()
        assert current_frame is not None
        frame = current_frame.f_back
        return CutlassBaseDSL._make_kernel_decorator(cls, frame, *dargs, **dkwargs)

    def _generate_kernel_attrs(self, config: BaseDSL.LaunchConfig) -> dict:
        import re

        ret = super()._generate_kernel_attrs(config)
        ret.update(self._get_cluster_kernel_attrs(config))

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
            # Build the `lir-to-cute{...}` brace. Separate from
            # ``compile_options.to_str()`` -- which targets
            # ``cute-to-nvvm{...}`` -- because the two live on
            # different pipelines.
            lir_to_cute_opts = "enable-cuda-dialect enable-lir-func-finalization=false"
            return (
                "builtin.module(gpu.module(lir-to-cute{"
                + lir_to_cute_opts
                + "}), lir-func-finalization{enable-cuda-dialect=true require-configure-launch=false}, cute-to-nvvm{cubin-format=bin enable-cuda-dialect "
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
        return cutlass_lir.ReturnOp([], loc=loc, ip=ip)

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
        # Extract the lir.kernel_extra_args attribute written by FuncFinalizationPass
        # and store it on the compiled function for later retrieval.
        # Maps kernel name → number of extra workspace pointer args added to the
        # host entry point signature.
        fn.kernel_extra_args = {}
        fn.total_added_arguments = 0
        if fn.ir_module is not None:
            attrs = fn.ir_module.operation.attributes
            attr_name = self._KERNEL_EXTRA_ARGS_ATTR
            if attr_name in attrs:
                for named in ir.DictAttr(attrs[attr_name]):
                    fn.kernel_extra_args[named.name] = ir.IntegerAttr(named.attr).value
                fn.total_added_arguments = fn.kernel_extra_args.pop(
                    "total_added_arguments", 0
                )
        if type(fn) is CudaDialectJitCompiledFunction:
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
            raise DSLUserCodeError(
                DiagId.ARG_BIND_FAILED,
                cause=e,
            )

    @deprecated(
        "`smem_usage()` is deprecated, use public API `arch.dynamic_smem_size()` instead."
    )
    def smem_usage(self) -> Int32:
        """
        Check smem usage for this kernel, only available after `launch`
        """
        if self._launch_name is None:
            raise ValueError("kernel smem usage only available after `launch`")
        kernel_sym = ir.SymbolRefAttr.get(["kernels", self._launch_name])
        smem_usage = cute.kernel_smem_size(kernel_name=kernel_sym)
        return Int32(smem_usage)

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
        # Strip the "builtins." prefix so the author sees a plain type name.
        py_type = str(e.type_str).rsplit(".", 1)[-1]
        # Keep a specific reason (e.g. "`MyClass(...)` has extra field `a`") as a
        # note, but drop the generic internal "Flatten Error" marker.
        detail = str(e.message) if e.message else ""
        raise DSLUserCodeError(
            DiagId.TYPE_DYNAMIC_EXPR_UNSUPPORTED,
            body_name=body_name,
            py_type=py_type,
            context=detail if detail and "Flatten Error" not in detail else None,
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
    from ..base_dsl.typing import _binary_op_type_promote

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
                    lhs_val = lhs.value.with_signedness(lhs.signed)
                else:
                    lhs_val = lhs.value

                rhs_val: Union[bool, int, float, ir.Value, cutlass_arith.ArithValue]
                if isinstance(rhs.value, cutlass_arith.ArithValue) and isinstance(
                    rhs, Integer
                ):
                    rhs_val = rhs.value.with_signedness(rhs.signed)
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
    from .._mlir_helpers.vector import Vector, all_ as vector_all_

    if isinstance(iterable, Vector):
        return vector_all_(iterable)

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
    from .._mlir_helpers.vector import Vector, any_ as vector_any_

    if isinstance(iterable, Vector):
        return vector_any_(iterable)

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
                raise DSLUserCodeError(
                    DiagId.TYPE_CONDITIONAL_VALUE_COUNT,
                )
        return value

    if not is_dynamic_expression(cond):
        raise DSLUserCodeError(DiagId.PHASE_CONDITIONAL_NOT_DYNAMIC)

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
            raise DSLUserCodeError(DiagId.TYPE_LOOP_PARAM_NOT_INT)
        elif isinstance(p, Integer):
            p = p.ir_value()
        params[i] = p

    start, stop, step = params

    def _createI32Attr(value: Union[Int32, int]) -> ir.IntegerAttr:
        if not isinstance(value, int):
            raise DSLUserCodeError(DiagId.TYPE_PARAM_NOT_INT)
        return ir.IntegerAttr.get(ir.IntegerType.get_signless(32), value)

    ir_iter_args = extract_mlir_values(iter_args) if iter_args is not None else None
    if not _validate_iter_args_structure(iter_args, ir_iter_args):
        raise DSLUserCodeError(DiagId.TYPE_ITER_ARGS_INVALID)
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
                raise DSLUserCodeError(DiagId.TYPE_RETURN_TYPE_NOT_DSL)
            mlir_return_types.append(t.mlir_type)  # type: ignore[attr-defined]

    # Determine whether there's an else branch.
    # When return_types are specified but else_body is None, synthesize a
    # passthrough else that yields the input_args unchanged.  Without this,
    # scf.if with results would lack an else block, which is invalid MLIR.
    if else_body is None and return_types is not None:
        else_body = lambda *args: args if len(args) > 1 else args[0]
    has_else = else_body is not None

    # Create the IfOp.
    if_op = scf.IfOp(
        Boolean(cond).ir_value(), mlir_return_types, has_else=has_else, loc=loc, ip=ip
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
            raise DSLUserCodeError(DiagId.TYPE_WHILE_INPUTS_INVALID)

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
        raise DSLUserCodeError(DiagId.UNSUP_IN_OPERATOR)

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
            raise DSLUserCodeError(DiagId.UNSUP_COMPARISON_OPERATOR, op=op)

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
        raise DSLUserCodeError(DiagId.UNSUP_COMPARISON_OPERATOR, op=op)


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
                raise DSLUserCodeError(
                    DiagId.CALL_BUILTIN_KWARGS_UNSUPPORTED,
                    fcn=fcn,
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
                raise DSLUserCodeError(DiagId.UNSUP_BUILTIN_FUNCTION, fcn=fcn)
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
