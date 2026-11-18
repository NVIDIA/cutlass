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

"""Which GEMM operators can be compiled on a host with no CUDA device.

Compilation should need only metadata, so that it works without a GPU and so
one artifact stays valid across devices with differing SM counts. Operators
that call ``get_max_active_clusters()`` from ``_compile()`` break both.

Fake tensors stand in for the operands, so no device memory is needed, and
``HardwareInfo`` is replaced by a bomb so that a device query is detected even
when the test host does have a GPU.

An operator keeps its side of the bargain by taking the value as a launch
operand and reading it in ``_run``; adding a query back to ``_compile`` fails
here. That covers the ``static`` work strategy of the universal tile
scheduler too: its one-wave grid is capped by the fallback-cluster occupancy,
but the cap is a launch-time argument of the kernel rather than a field of the
tile-scheduler template, so compiling it needs no device.

Each case names an operator class, which generates its own candidates, and
the operands to compile for: the sm107 operators take fp8 and MXFP8 inputs.

The remaining tests cover ``DeviceProperties`` against the same stub: which
device it queries, how it caches, and that the shared default is reused.
"""

import warnings

import pytest
import torch
from torch._subclasses.fake_tensor import FakeTensorMode

import cutlass
import cutlass.utils

import cutlass.operators as ops
from cutlass.operators import device_properties
from cutlass.operators.providers.cutedsl.gemm.sm80_tensorop_gemm import (
    Sm80TensorOpGemmOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm90_static_persistent import (
    Sm90StaticPersistentGemmOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_dense_gemm_universal import (
    Sm100DenseGemmUniversalOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_blockscaled_gemm_universal import (
    Sm107BlockScaledGemmUniversalOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_dense_gemm_universal import (
    Sm107DenseGemmUniversalOperator,
)

STATIC = ops.metadata.StaticPersistentMetadata
CLC = ops.metadata.CLCDynamicPersistentMetadata


def f16_operands():
    """Return f16 ``GemmArguments`` over fake tensors, which allocate nothing."""
    with FakeTensorMode():
        A = torch.empty((2, 128, 64), device="cuda", dtype=torch.float16)
        B = torch.empty((2, 64, 256), device="cuda", dtype=torch.float16)
        out = torch.empty((2, 128, 256), device="cuda", dtype=torch.float16)
    return ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)


def fp8_operands():
    """Return fp8-input ``GemmArguments`` over fake tensors, K-major A and B."""
    with FakeTensorMode():
        A = torch.empty((2, 128, 128), device="cuda", dtype=torch.float8_e4m3fn)
        B = torch.empty((2, 256, 128), device="cuda", dtype=torch.float8_e4m3fn)
        out = torch.empty((2, 128, 256), device="cuda", dtype=torch.float16)
    return ops.GemmArguments(
        A=A, B=B.transpose(1, 2), out=out, accumulator_type=torch.float32
    )


def mxfp8_operands():
    """Return MXFP8 block-scaled ``GemmArguments`` over fake tensors."""
    mode = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    shape_a, shape_b = (2, 128, 128), (2, 256, 128)
    with FakeTensorMode():
        A = torch.empty(shape_a, device="cuda", dtype=torch.float8_e4m3fn)
        B = torch.empty(shape_b, device="cuda", dtype=torch.float8_e4m3fn)
        SFA = torch.empty(
            ops.ScaledOperand.numel_scale(shape_a, mode, swizzle),
            device="cuda",
            dtype=torch.float8_e8m0fnu,
        )
        SFB = torch.empty(
            ops.ScaledOperand.numel_scale(shape_b, mode, swizzle),
            device="cuda",
            dtype=torch.float8_e8m0fnu,
        )
        out = torch.empty((2, 128, 256), device="cuda", dtype=torch.float16)
    return ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, mode, swizzle),
        B=ops.ScaledOperand(B.transpose(1, 2), SFB, mode, swizzle),
        out=out,
        accumulator_type=torch.float32,
    )


# (target_sm, operator class, tile scheduler to select or None, operands)
CASES = [
    ("80", Sm80TensorOpGemmOperator, None, f16_operands),
    ("90a", Sm90StaticPersistentGemmOperator, None, f16_operands),
    ("100a", Sm100DenseGemmUniversalOperator, STATIC, f16_operands),
    ("100a", Sm100DenseGemmUniversalOperator, CLC, f16_operands),
    ("100a", Sm100PersistentDenseGemmEFCOperator, None, f16_operands),
    ("107a", Sm107DenseGemmUniversalOperator, STATIC, fp8_operands),
    ("107a", Sm107BlockScaledGemmUniversalOperator, STATIC, mxfp8_operands),
]


class _StubHardwareInfo:
    """Records what it is asked instead of touching a GPU.

    ``HardwareInfo`` is constructed per query, so the log lives outside it.
    """

    def __init__(self, queries, device_id):
        self._queries = queries
        self._device_id = device_id

    def get_max_active_clusters(self, cluster_size):
        self._queries.append((self._device_id, cluster_size))
        return 16


class DeviceQueried(RuntimeError):
    """Raised in place of constructing ``HardwareInfo``."""


@pytest.fixture
def fixture_forbid_device_query(monkeypatch):
    """Make ``cutlass.utils.HardwareInfo()`` fail loudly.

    ``operators.device_properties`` resolves it off ``cutlass.utils``
    at call time, so patching the attribute intercepts it.
    """

    def bomb(*args, **kwargs):
        raise DeviceQueried("compile() queried the device via HardwareInfo")

    monkeypatch.setattr(cutlass.utils, "HardwareInfo", bomb)


@pytest.fixture
def fixture_stub_device_queries(monkeypatch):
    """Answer occupancy queries from a stub and return the log it appends to.

    Each entry is a ``(device_id, cluster_size)`` pair. The shared-instance
    cache is swapped out too, so stubbed values cannot outlive the test.
    """
    queries = []
    monkeypatch.setattr(
        cutlass.utils,
        "HardwareInfo",
        lambda device_id: _StubHardwareInfo(queries, device_id),
    )
    monkeypatch.setattr(device_properties, "_default_device_properties", {})
    return queries


def _select(args, target_sm, operator_class, scheduler):
    """Return the first ``operator_class`` operator for ``args`` using ``scheduler``.

    Only ``operator_class`` generates candidates, filtered the way
    ``ops.get_operators`` filters them: by metadata, then by the operator's
    own checks.
    """
    target = ops.TargetSm.ensure(target_sm)

    def matches(metadata: ops.OperatorMetadata) -> bool:
        if scheduler is not None:
            tile_scheduler = metadata.design.tile_scheduler
            if tile_scheduler is None or not isinstance(
                tile_scheduler.persistence, scheduler
            ):
                return False
        return bool(metadata.supports(args, target_sm=target))

    operators = [
        operator
        for operator in operator_class.generate_operators(
            matches, target_sm=target, args=args
        )
        if operator.supports(args, target_sm=target)
    ]
    assert operators, (
        f"no {operator_class.__name__} on sm{target_sm} for these arguments"
    )
    return operators[0]


@pytest.mark.parametrize(
    ("target_sm", "operator_class", "scheduler", "make_operands"),
    CASES,
    ids=lambda v: getattr(v, "__name__", str(v)),
)
def test_compile_without_device(
    target_sm,
    operator_class,
    scheduler,
    make_operands,
    fixture_forbid_device_query,
):
    """Compile one operator per class with the device query sabotaged."""
    args = make_operands()
    operator = _select(args, target_sm, operator_class, scheduler)

    operator.compile(args, target_sm=target_sm)


def test_get_max_active_clusters_is_deprecated(fixture_stub_device_queries):
    """The free function warns and delegates; the class path stays quiet."""
    with pytest.warns(DeprecationWarning, match="DeviceProperties"):
        assert device_properties.get_max_active_clusters((2, 1)) == 16

    with warnings.catch_warnings():
        warnings.simplefilter("error", DeprecationWarning)
        assert ops.DeviceProperties().max_active_clusters((2, 1)) == 16


def test_query_uses_and_caches_the_cluster_size(fixture_stub_device_queries):
    """Each cluster size reaches the device only once."""
    properties = ops.DeviceProperties()

    assert properties.max_active_clusters((2, 1)) == 16
    assert properties.max_active_clusters((1, 2, 3)) == 16
    assert properties.max_active_clusters((4, 2)) == 16

    # Shapes with the same M x N size share an entry in the query cache.
    assert fixture_stub_device_queries == [(0, 2), (0, 8)]


def test_properties_default_to_device_zero(fixture_stub_device_queries):
    """Naming no device describes device 0."""
    properties = ops.DeviceProperties()

    assert properties.device_id == 0
    assert properties.max_active_clusters((2, 1)) == 16
    assert fixture_stub_device_queries == [(0, 2)]


def test_queries_reach_the_bound_device(fixture_stub_device_queries):
    """Each instance queries its own device and caches the answer separately."""
    per_device = [ops.DeviceProperties(device_id) for device_id in (0, 1)]

    for device_id, properties in enumerate(per_device):
        assert properties.device_id == device_id
        assert properties.max_active_clusters((2, 1)) == 16

    # Same cluster size, but no cache is shared between the two devices.
    assert fixture_stub_device_queries == [(0, 2), (1, 2)]


def test_default_properties_are_shared_per_device(fixture_stub_device_queries):
    """One instance per device serves every caller, so a value is queried once."""
    shared = ops.get_default_device_properties()

    for _ in range(3):
        assert ops.get_default_device_properties() is shared
        assert shared.max_active_clusters((2, 1)) == 16

    assert ops.get_default_device_properties(1) is not shared
    assert fixture_stub_device_queries == [(0, 2)]


def test_negative_device_id_is_rejected(fixture_stub_device_queries):
    """An ID that cannot name a device fails before it is queried or cached."""
    with pytest.raises(ValueError, match="device_id"):
        ops.DeviceProperties(-1)

    with pytest.raises(ValueError, match="device_id"):
        ops.get_default_device_properties(-1)

    assert not device_properties._default_device_properties
    assert not fixture_stub_device_queries


def test_repr_names_the_device(fixture_stub_device_queries):
    """The device an instance describes is visible when debugging."""
    properties = ops.DeviceProperties(device_id=1)

    assert repr(properties) == "DeviceProperties(device_id=1, max_active_clusters={})"

    properties.max_active_clusters((2, 1))

    assert (
        repr(properties) == "DeviceProperties(device_id=1, max_active_clusters={2: 16})"
    )
