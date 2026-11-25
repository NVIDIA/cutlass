# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Deprecated names and signatures that cutlass.operators still accepts.

Each test pins one compatibility path used by PyTorch Inductor,
and checks that it warns. Does not need a device.
"""

import ast
import importlib.util
import types
import warnings
from pathlib import Path

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.device_properties import query_max_active_clusters
from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent import (
    Sm100BlockscaledStaticPersistentOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)
from cutlass.operators.utils.tensor import TensorWrapper
from cutlass.operators.workspace import Workspace

COMPILED = types.SimpleNamespace(compiled_for=ops.TargetSm("100a"))


def _operator_class(run):
    """Make a concrete ``Operator`` whose ``_run`` is ``run``."""
    return type(
        "RecordingOperator",
        (ops.Operator,),
        {
            "supported_args_type": ops.GemmArguments,
            "designed_for_min_cc": 100,
            "_compile": lambda self, args, target_sm=None: COMPILED,
            "_run": run,
            "_generate_operators": classmethod(lambda cls, *a, **k: []),
            "_get_workspace_size": lambda self, args: None,
        },
    )


def _run_once(operator, **kwargs):
    operator.run(
        None,
        compiled_artifact=COMPILED,
        stream=object(),
        assume_supported_args=True,
        **kwargs,
    )


def test_legacy_run_signature_warns_and_still_runs():
    """A ``_run`` without ``device_properties`` gets four arguments.

    Its workspace arrives exactly as the caller passed it, because such
    implementations predate ``Workspace`` wrapping.
    """
    calls = []

    def _run(self, args, compiled_artifact, stream, workspace=None):
        calls.append(workspace)

    with pytest.warns(DeprecationWarning, match="device_properties"):
        operator = _operator_class(_run)(metadata=None)
    workspace = torch.empty(16, dtype=torch.int8)
    _run_once(operator, workspace=workspace)
    assert calls == [workspace]


def test_legacy_run_signature_rejects_device_properties():
    """Device properties given to a ``_run`` that cannot take them fail loudly."""

    def _run(self, args, compiled_artifact, stream, workspace=None):
        pass

    with pytest.warns(DeprecationWarning):
        operator = _operator_class(_run)(metadata=None)
    with pytest.raises(TypeError, match="device_properties"):
        _run_once(operator, device_properties=ops.DeviceProperties())


def test_tensor_workspace_is_wrapped():
    """``run`` accepts a tensor as the workspace and wraps it in ``Workspace``.

    It also passes the shared default device properties when given none.
    """
    calls = []

    def _run(
        self, args, compiled_artifact, stream, workspace=None, *, device_properties
    ):
        calls.append(workspace)
        assert isinstance(device_properties, ops.DeviceProperties)

    with warnings.catch_warnings():
        warnings.simplefilter("error", DeprecationWarning)
        operator = _operator_class(_run)(metadata=None)
    tensor = torch.empty(16, dtype=torch.int8)
    _run_once(operator, workspace=tensor)
    given = Workspace(torch.empty(16, dtype=torch.int8))
    _run_once(operator, workspace=given)

    assert isinstance(calls[0], Workspace)
    assert calls[0].data.data_ptr == tensor.data_ptr()
    assert calls[1] is given


@pytest.mark.parametrize(
    "module, name, expected",
    [
        (
            "cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc",
            "PersistentDenseGemmEFCOperator",
            Sm100PersistentDenseGemmEFCOperator,
        ),
        (
            "cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc",
            "Operand",
            ops.arguments.Operand,
        ),
        (
            "cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc",
            "TensorWrapper",
            TensorWrapper,
        ),
        (
            "cutlass.operators.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent",
            "PersistentDenseBlockScaledGemmOperator",
            Sm100BlockscaledStaticPersistentOperator,
        ),
        (
            "cutlass.operators.providers.cutedsl.integration_utils.mma",
            "get_max_active_clusters",
            query_max_active_clusters,
        ),
    ],
    ids=lambda value: value if isinstance(value, str) else "",
)
def test_moved_name_warns_and_is_the_same_object(module, name, expected):
    """A moved name resolves to the current object, so ``is`` checks hold."""
    with pytest.warns(DeprecationWarning, match=name):
        value = getattr(__import__(module, fromlist=[name]), name)
    assert value is expected


def test_unknown_name_on_a_shim_module_is_an_attribute_error():
    """Only the moved names are served; ``hasattr`` stays accurate."""
    from cutlass.operators.providers.cutedsl.gemm import sm100_static_persistent_efc

    assert not hasattr(sm100_static_persistent_efc, "no_such_name")


def test_mma_is_reachable_as_a_package_attribute():
    """``integration_utils.mma`` resolves without importing the submodule first."""
    from cutlass.operators.providers.cutedsl import integration_utils

    with pytest.warns(DeprecationWarning):
        assert (
            integration_utils.mma.get_max_active_clusters is query_max_active_clusters
        )


@pytest.mark.parametrize(
    "operation_class, expected_layout",
    [
        pytest.param(
            "DenseGemmEFC",
            "((64,2),(32,1),3,2):((1,64),(128,0),8192,24576)",
            id="DenseGemmEFC",
        ),
        pytest.param(
            "other",
            "((64,32),2,1,3,2):((1,128),64,0,8192,24576)",
            id="other-operation",
        ),
    ],
)
def test_efc_partition_modes_follow_the_operation(
    monkeypatch, operation_class, expected_layout
):
    """In-tree EFC operations get the folded C/D partition modes.

    An operation class from outside ``cutlass.operators`` that binds the
    kernel companion gets the unfolded modes
    ``((ATOM_M, ATOM_N), MMA_M, MMA_N, ...)`` and a ``DeprecationWarning``.
    """
    import cutlass.cute as cute

    from cutlass.operators.providers.cutedsl.evt.efc.dense_gemm.sm100 import (
        _operation as sm100_operation,
    )

    class Other:
        pass

    operation = object.__new__(
        {
            "DenseGemmEFC": sm100_operation.DenseGemmEFC,
            "other": Other,
        }[operation_class]
    )
    # Make the tiling and ``partition_C`` identities, so that only the
    # regrouping acts.  The source below is in the ``thr_mma.partition_C``
    # order, and MMA_M == 2, so a wrong regrouping changes the layout.
    operation.mma_tiler = (128, 64, 16)
    operation.thr_mma = types.SimpleNamespace(partition_C=lambda tensor: tensor)
    monkeypatch.setattr(cute, "local_tile", lambda source, *_: source)
    kernel = object.__new__(sm100_operation._DenseGemmEFCKernel)
    kernel.efc = types.SimpleNamespace(
        parameter_attributes={"D": types.SimpleNamespace(accum_split_parts=None)}
    )
    kernel.operation = operation
    layouts = []

    @cute.jit
    def partition():
        coordinates = cute.make_identity_tensor((128, 64, 4, 3, 2))
        raw = cute.make_tensor(
            coordinates.iterator,
            cute.make_layout(
                ((64, 32), 2, 1, 3, 2), stride=((1, 128), 64, 0, 8192, 24576)
            ),
        )
        layouts.append(str(kernel.partition_global_tensor("D", raw).layout))

    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        partition()

    deprecations = [w for w in caught if issubclass(w.category, DeprecationWarning)]
    assert layouts == [expected_layout]
    if operation_class == "other":
        assert any("_folds_partition_modes" in str(w.message) for w in deprecations)
    else:
        assert not deprecations


def _moved_names(tree):
    """Keys of the mapping passed to ``deprecated_module_attributes``."""
    for call in ast.walk(tree):
        if (
            isinstance(call, ast.Call)
            and getattr(call.func, "id", None) == "deprecated_module_attributes"
        ):
            return {key.value for key in call.args[1].keys}
    raise AssertionError("no deprecated_module_attributes call")


def _deprecated_stubs(tree):
    """Names declared with ``@deprecated`` inside ``if TYPE_CHECKING:``."""
    names = set()
    for block in tree.body:
        if isinstance(block, ast.If) and getattr(block.test, "id", None) == (
            "TYPE_CHECKING"
        ):
            for node in block.body:
                if isinstance(node, (ast.ClassDef, ast.FunctionDef)) and any(
                    isinstance(d, ast.Call)
                    and getattr(d.func, "id", None) == "deprecated"
                    for d in node.decorator_list
                ):
                    names.add(node.name)
                elif (
                    isinstance(node, ast.Assign)
                    and isinstance(node.value, ast.Call)
                    and isinstance(node.value.func, ast.Call)
                    and getattr(node.value.func.func, "id", None) == "deprecated"
                ):
                    # ``name = deprecated("...")(function)``
                    names.update(target.id for target in node.targets)
    return names


SHIM_MODULES = [
    "cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc",
    "cutlass.operators.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent",
    "cutlass.operators.providers.cutedsl.integration_utils.mma",
]


@pytest.mark.parametrize("module", SHIM_MODULES, ids=lambda m: m.rsplit(".", 1)[-1])
def test_every_moved_name_has_a_type_checker_stub(module):
    """Static checkers see the same deprecated names that warn at runtime.

    The ``__getattr__`` mapping serves the names at runtime; the
    ``TYPE_CHECKING`` stubs mark them deprecated for pyrefly, mypy and
    pyright.  Both must list exactly the same names.
    """
    tree = ast.parse(Path(importlib.util.find_spec(module).origin).read_text())
    assert _deprecated_stubs(tree) == _moved_names(tree)
