#
# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#


"""
Python registration for compute nodes in EVT
"""

from cutlass.operators.fusion.ir.node import NodeBase, ImplBase
from cutlass.operators.fusion.ir.tensor import Tensor
from cutlass.operators.fusion.library import (
    FloatRoundStyle,
    GATED_OP_NUM_PARTS,
    LayoutType,
)


class ComputeImplBase(ImplBase):
    """
    Base class for compute implementation
    """

    def __init__(self, node) -> None:
        super().__init__(node)


class ComputeImpl(ComputeImplBase):
    """
    Implementation for Compute Node
    """

    def __init__(self, node) -> None:
        super().__init__(node)

        self.fn = node.fn
        self.element_output = node.element_output
        self.element_compute = node.element_compute
        self.round_style = node.round_style

    @staticmethod
    def match(node, problem_size: tuple):
        return True


class ComputeNode(NodeBase):
    """
    Compute Node in DAG IR
    """

    possible_impls = [
        ComputeImpl,
    ]

    def __init__(
        self,
        name: str,
        fn,
        element_output,
        element_compute,
        round_style=FloatRoundStyle.ToNearest,
    ) -> None:
        super().__init__(name)
        self.op = "compute"
        self.fn = fn
        self.element_compute = element_compute
        self.round_style = round_style

    def type_propagation(self, *args, **kwargs):
        """
        Load node loads tensor under type `tensor.element` and returns an array of type `tensor.element`.
        """
        self.element = self.element_compute
        # In general, the compute nodes have element_output = element_compute
        # In certain cases like producer of D it is overwritten by other passes
        if not hasattr(self, "element_output"):
            self.element_output = self.element


class GatedComputeNode(ComputeNode):
    """Compute node for a gated linear unit (``fn`` is a ``GatedOp``).

    Every other compute node is elementwise, so ``NodeBase`` can infer its
    shape by NumPy broadcasting of the inputs.  A gated node consumes two
    N-interleaved parts and yields one value, so it needs its own rules in
    both directions:

    - forward, its output N is the input's divided by ``GATED_OP_NUM_PARTS``;
    - backward, its input keeps the *full* N.  The inherited
      ``broadcast_propagation`` would push the halved output shape onto the
      accumulator and silently shrink the problem.
    """

    #: A gated op is where the narrowing originates.
    accum_split_factor = GATED_OP_NUM_PARTS

    def shape_propagation(self, input_node_metas):
        if self._tensor is not None:
            return
        if len(input_node_metas) != 1:
            raise RuntimeError(
                f"Gated node {self.name} takes one input, got {len(input_node_metas)}."
            )
        if input_node_metas[0].accum_split_factor != 1:
            raise RuntimeError(
                f"Gated node {self.name} reads a value already narrowed by "
                f"a gated op; nesting gated activations is not supported."
            )
        shape = list(input_node_metas[0].tensor.shape)
        if shape[-1] % GATED_OP_NUM_PARTS != 0:
            raise RuntimeError(
                f"Gated node {self.name} needs an N divisible by "
                f"{GATED_OP_NUM_PARTS}, got {shape[-1]}."
            )
        shape[-1] //= GATED_OP_NUM_PARTS
        self._tensor = Tensor(
            element=self.element_output,
            shape=tuple(shape),
            layout_tag=LayoutType.RowMajor,
        )

    def broadcast_propagation(self, input_node_metas):
        # The input spans the full N, so re-broadcast it to its own shape
        # rather than to this node's halved one.
        for child in input_node_metas:
            child.tensor.broadcast(child.tensor.shape)
