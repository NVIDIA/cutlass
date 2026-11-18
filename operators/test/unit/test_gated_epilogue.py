# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Gated linear units, from the epilogue source down to the DAGIR.

Everything here runs on CPU tensors with no device: tracing an epilogue
reads shapes and strides only, so the whole path from the AST vocabulary
through shape propagation to the converter's op table is checkable
without a GPU.  The kernel behaviour these describe is covered by the
integration tests, which do need one.
"""

import pytest
import torch

import cutlass

import cutlass.operators as ops
from cutlass.operators.fusion import activation
from cutlass.operators.fusion.frontend.python_ast import PythonASTFrontend
from cutlass.operators.fusion.ir.compute_nodes import GatedComputeNode
from cutlass.operators.fusion.library import GATED_OP_NUM_PARTS, GatedOp
from cutlass.operators.providers.cutedsl.evt.converter import (
    OpToCuteImpl,
    OpToCuteImplStr,
)

#: Accumulator the epilogues below are traced against, in DAGIR (L, M, N)
#: order.  N is what a gated node halves.
ACCUM_SHAPE = (1, 256, 512)

GATES = [
    ("swiglu", GatedOp.SwiGLU, torch.nn.functional.silu),
    ("geglu", GatedOp.GeGLU, torch.nn.functional.gelu),
    ("reglu", GatedOp.ReGLU, torch.nn.functional.relu),
]


def trace(source, out_n=ACCUM_SHAPE[-1] // GATED_OP_NUM_PARTS, accum_shape=ACCUM_SHAPE):
    """Trace an epilogue whose single output D is ``out_n`` wide."""
    D = torch.empty(accum_shape[1], out_n, dtype=torch.float16)
    arguments = ops.EpilogueArguments(source, D=D)
    arguments.trace(accum_shape, cutlass.Float32)
    return arguments


def node(arguments, name):
    for meta in arguments.traced_epilogue.dag_ir.node_metas_topological_order():
        if meta.name == name:
            return meta
    raise AssertionError(f"no node named {name!r}")


@pytest.mark.parametrize("name, op, _torch_fn", GATES, ids=[g[0] for g in GATES])
def test_vocabulary_binds_the_gate_names(name, op, _torch_fn):
    """Each gate name is a parseable epilogue function bound to its op."""
    assert PythonASTFrontend.ast_op_to_bindings(name) is op


@pytest.mark.parametrize("name, _op, torch_fn", GATES, ids=[g[0] for g in GATES])
def test_activation_reference_gates_the_even_indices(name, _op, torch_fn):
    """The torch reference pairs even N indices with odd ones.

    Gate is part 0 and up is part 1, matching the ``[gate | up]``
    interleave the fused B operand is built with -- swapping them would
    still typecheck and still run.
    """
    x = torch.randn(4, 8)
    expected = x[..., 1::2] * torch_fn(x[..., 0::2])
    assert torch.equal(getattr(activation, name)(x), expected)


@pytest.mark.parametrize("name", [g[0] for g in GATES])
def test_gated_node_halves_n(name):
    """The gated node's output has half the accumulator's N."""
    arguments = trace(f"def epi(accum): D = {name}(accum); return D")
    gated = node(arguments, "compute_0")
    assert isinstance(gated, GatedComputeNode)
    assert gated.tensor.shape == (*ACCUM_SHAPE[:-1], ACCUM_SHAPE[-1] // 2)


def test_accumulator_keeps_its_full_width():
    """Backward propagation must not shrink the accumulator.

    ``NodeBase.broadcast_propagation`` would push the gated node's halved
    shape onto its input, silently shrinking the problem; the gated node
    overrides it for exactly this reason.
    """
    arguments = trace("def epi(accum): D = swiglu(accum); return D")
    assert node(arguments, "accum").tensor.shape == ACCUM_SHAPE


def test_factor_survives_intervening_arithmetic():
    """A consumer of a gated value stays marked as narrowed.

    The store has to know it is narrowed however much elementwise
    computation sits between it and the gate, which is what
    ``NodeBase.accum_split_factor`` carries forward.
    """
    arguments = trace("def epi(accum): D = swiglu(accum) * 2.0; return D")
    assert node(arguments, "D").accum_split_factor == GATED_OP_NUM_PARTS


def test_factor_is_one_without_a_gate():
    """An ordinary epilogue reports no narrowing."""
    arguments = trace(
        "def epi(accum): D = relu(accum); return D", out_n=ACCUM_SHAPE[-1]
    )
    assert node(arguments, "D").accum_split_factor == 1
    assert node(arguments, "D").tensor.shape == ACCUM_SHAPE


def test_narrowed_output_still_matches_store_d():
    """``D`` is recognised as the primary output at its narrowed width.

    ``StoreDImpl.match`` compares against the accumulator's N divided by
    the node's split factor; without that division a gated D falls
    through every store implementation and tracing fails outright.
    """
    arguments = trace("def epi(accum): D = swiglu(accum); return D")
    assert "StoreD" in type(node(arguments, "D").underlying_impl).__name__


def test_odd_accumulator_n_is_rejected():
    """A gate needs an even N to pair.

    Reported while tracing rather than as a wrong store width.
    """
    with pytest.raises(RuntimeError, match="divisible"):
        trace(
            "def epi(accum): D = swiglu(accum); return D",
            out_n=127,
            accum_shape=(1, 256, 255),
        )


@pytest.mark.parametrize(
    "source, out_n, message",
    [
        pytest.param(
            "def epi(accum): D = swiglu(accum); return D",
            ACCUM_SHAPE[-1],
            r"'D' has shape \(256, 512\).*\(1, 256, 256\), narrowed 2x along N "
            r"by a gated activation",
            id="gated-full-width",
        ),
        pytest.param(
            "def epi(accum): D = relu(accum); return D",
            ACCUM_SHAPE[-1] // GATED_OP_NUM_PARTS,
            r"'D' has shape \(256, 256\).*\(1, 256, 512\)\.$",
            id="plain-half-width",
        ),
    ],
)
def test_output_width_mismatch_names_both_shapes(source, out_n, message):
    """An output the epilogue cannot fill reports both shapes.

    Both widths pass the GEMM's pre-trace check, which cannot tell whether
    the epilogue gates; shape propagation is what rejects them.  The gated
    case also says why the computed N is narrower, since the user's tensor
    then has the accumulator's width and looks correct.
    """
    with pytest.raises(ValueError, match=message):
        trace(source, out_n=out_n)


@pytest.mark.parametrize("name, op, _torch_fn", GATES, ids=[g[0] for g in GATES])
def test_converter_calls_the_nullary_efc_method(name, op, _torch_fn):
    """The converter maps a gated op to ``efc_config.<gate>()``.

    The DAGIR hands the node one input -- the accumulator -- but the EFC
    method takes none: it splits the register fragment itself, before the
    accumulator is loaded.  So the value passed in is discarded, and this
    pins that.
    """

    class Config:
        def __getattr__(self, attribute):
            return lambda: f"{attribute}-result"

    assert OpToCuteImpl[op](Config(), "ignored-accumulator") == f"{name}-result"
    assert OpToCuteImplStr[op]("ignored-accumulator") == f"efc_config.{name}()"


def test_gated_rejects_nested_gating():
    """Tracing rejects a gated op over an already gated value.

    ``GatedComputeNode`` narrows N once; feeding its output to another
    gate would need the factors composed through the store matching,
    which nothing implements.  The rejection names the nesting instead
    of surfacing as a store-shape mismatch.
    """
    with pytest.raises(RuntimeError, match="nesting gated activations"):
        trace("def epi(accum): D = swiglu(swiglu(accum)); return D")


def test_gated_must_consume_accum_directly():
    """``supports`` rejects a gated node fed anything but ``accum``.

    The converter maps a gated node to a nullary ``efc_config`` method
    that splits the accumulator's register fragment itself, so it has no
    way to gate a computed value -- ``swiglu(accum * 2.0)`` would silently
    gate the raw accumulator instead.
    """
    from cutlass.operators.providers.cutedsl.evt.converter import EFCConverter

    direct = trace("def epi(accum): D = swiglu(accum); return D")
    assert EFCConverter.supports(direct.traced_epilogue.dag_ir)

    computed = trace("def epi(accum): D = swiglu(accum * 2.0); return D")
    status = EFCConverter.supports(computed.traced_epilogue.dag_ir)
    assert not status
    assert "accum directly" in str(status.error)


def test_analysis_result_preserves_the_split_mark():
    """Elementwise helpers keep a part's provenance during analysis.

    Without this, ``D.store(efc_config.relu(gate))`` loses the mark and
    the store is sized at the accumulator's full width.
    """
    from cutlass.operators.providers.cutedsl.evt.efc import (
        SplitPart,
        analysis_result_of,
    )

    assert analysis_result_of(1.0, 2) == 1
    marked = analysis_result_of(SplitPart(2), 0.5)
    assert isinstance(marked, SplitPart) and marked.num_parts == 2
    with pytest.raises(ValueError, match="Cannot combine"):
        analysis_result_of(SplitPart(2), SplitPart(4))
