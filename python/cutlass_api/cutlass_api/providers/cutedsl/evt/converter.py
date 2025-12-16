#################################################################################################
#
# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#################################################################################################

from collections.abc import Callable

from cutlass_api.fusion.ir import DAGIR, LoadNode, StoreNode, TopoVisitorNode
from cutlass_api.fusion.ir.load_nodes import (
    ColumnBroadcastImpl,
    RowBroadcastImpl,
    ScalarBroadcastImpl,
)
from cutlass_api.fusion.ir.store_nodes import ReductionImplBase
from cutlass_api.fusion.library import ActivationOp, FunctionalOp
from cutlass_api.providers.cutedsl.evt import common_efc
from cutlass_api.status import Status

OpToCuteImplStr = {
    FunctionalOp.Exp: lambda x: f"exp({x})",
    ActivationOp.ReLU: lambda x: f"relu({x})",
    ActivationOp.Sigmoid: lambda x: f"sigmoid({x})",
    ActivationOp.Tanh: lambda x: f"tanh({x})",
    FunctionalOp.Divides: lambda x, y: f"({x} / {y})",
    FunctionalOp.Multiplies: lambda x, y: f"({x} * {y})",
    FunctionalOp.Plus: lambda x, y: f"({x} + {y})",
    FunctionalOp.Minus: lambda x, y: f"({x} - {y})",
}


# Functions to eventually be run as part of the EFC function.
# Every function takes in `efc_config` as the first argument (even if it
# is not used).  This is necssary for running analysis
# passes on the EFC function absent an MLIR context (which would be
# needed is we used `cute.exp` directly).

OpToCuteImpl = {
    FunctionalOp.Exp: lambda efc_config, x: efc_config.exp(x),
    ActivationOp.ReLU: lambda efc_config, x: efc_config.where(
        x > 0, x, efc_config.full_like(x, 0)
    ),
    ActivationOp.Sigmoid: lambda efc_config, x: 1.0 / (1.0 + efc_config.exp(-x)),
    ActivationOp.Tanh: lambda efc_config, x: efc_config.tanh(x),
    FunctionalOp.Divides: lambda efc_config, x, y: x / y,
    FunctionalOp.Multiplies: lambda efc_config, x, y: x * y,
    FunctionalOp.Plus: lambda efc_config, x, y: x + y,
    FunctionalOp.Minus: lambda efc_config, x, y: x - y,
}


def store(efc_config, x, y):
    x.store(y)


def load(efc_config, x):
    return x.load()


def get_val(x):
    return lambda efc_config: x


class EFCConverter:
    """
    Helper class to translate from DAGIR to the CuTe DSL epilogue visitor tree (EVT) structure

    The CuTe DSL EVT structure is as follows for a (alpha * accum + beta * C) epilogue:
        def epi(self, C, alpha, beta, D):
            C_val = C.load()
            alpha_val = alpha.load()
            beta_val = beta.load()
            compute_0_val = alpha_val * self.accum()
            compute_1_val = beta_val * C_val
            compute_2_val = compute_0_val + compute_1_val
            D.store(compute_2_val)
    """

    @staticmethod
    def convert(dag_ir: DAGIR, parameter_names: list[str]) -> Callable:
        """
        Converts the DAGIR to a callable epilogue function supported by CuTe DSL EFC.

        The simplest way to do this would be to convert the DAGIR into the equivalent
        string representation of the EFC function and call `exec` on it to get the callable.
        However, this is generally not considered safe as it can potentially open avenues
        for allowing arbitrary code execution.

        Instead, we define a generic configurable epilogue that we specialize based
        on the DAGIR itself. The generic epilogue takes in a list of parameters
        and executes a predefined sequence of operations. Each operation is executed
        in order and places its result on a stack.

        Outside this generic epilogue, we define the sequence of operations that
        are to be executed and determine where the sources for such operations live
        (either their index in the parameter list or on the stack).

        Example
        =======
        Suppose we have the following epilogue:
        ```
          def epi(accum, alpha):
            D = accum * alpha
            return D
        ```
        A simple string representation of the epilogue in EFC format would be:

        ```
          def efc_epi(efc_config, alpha, D):
            accum_val = efc_config.accum()
            alpha_val = alpha.load()
            temp = accum_val * alpha_val
            D.store(temp)
        ```

        We would like to generalize this to a function with signature:
        ```
          def efc_epi(efc_config, *parameters):
        ```
        that can perform arbitrary operations.

        We would know from `parameter_names` that the list of parameters provided to the EFC epilogue
        will be [alpha, D]. We then traverse the DAGIR and see the following operations in order:

        LoadNode(accum)
        LoadNode(alpha)
        ComputeNode(mul, alpha, accum) -> temp
        StoreNode(temp, D)

        We can convert this into a series of corresponding operations that operate on variables
        corresponding to indices. Indices represent either a position in the parameter list
        or a position on the stack (index < len(parameters) implying a position in the parameter list).
        In this example, [alpha, D] correspond to indices 0 and 1, respectively.

        Traversing each DAGIR node above, we get:
          LoadNode(accum) -> efc_config.accum(), result is in stack[0] (index 2)
          LoadNode(alpha) -> alpha.load()
                          -> parameter[0].load(), result is in stack[1] (index 3)
          ComputeNode(mul, alpha, accum) -> stack[1] * stack[0] (index 3 * index 2), result is in stack[2] (index 4)
          StoreNode(temp, D) -> D.store(stack[2])
                             -> paramter[1].store(stack[2])

        This is encoded as the following tuples:
          ```
          ops = [
            # Load of accum omitted because it is performed automatically in the generic epilogue
            (load, 0),
            (mul, 3, 2),
            (store, 1, 2),
          ]
          ```

        The generic epilogue then simply performs:
        ```
          def efc_epi(efc_config, *parameters):
            stack = [efc_config.accum()]
            for op in ops:
              fn = op[0]
              inputs = [get(idx) for idx in op[1:]]
              stack.append(fn(efc_config, *inputs))
        ```
        Where the `get()` function is a helper that returns either a value from the parameter list or the stack,
        depending on the index.
        """
        # Provide a unique identifier for cases in which `accum` is also being written out
        # We use an integer since parameter_names is a list of strings -- -1 is guaranteed
        # not to be in the parameter_names list, but can still be used as a key in the dictionary.
        accum_out_name = -1

        # If 'accum' is in parameter_names, we know that it must be because
        # the accumulator is also being written out
        accum_out_loc = -1
        if "accum" in parameter_names:
            # Rename the output version temporarily so as not to confuse with the
            # input accumulator
            accum_out_loc = parameter_names.index("accum")
            parameter_names[accum_out_loc] = accum_out_name

        name_to_idx = {}
        for idx, name in enumerate(parameter_names):
            name_to_idx[name] = idx

        cur_idx = len(name_to_idx)

        def add_name(name: str):
            nonlocal cur_idx
            name_to_idx[name] = cur_idx
            cur_idx += 1

        def idx(name: str):
            val = name_to_idx[name]
            if isinstance(val, str):
                return idx(val)
            return val

        add_name("accum")

        # Each entry is a tuple containing a load/store/compute op and operands needed for it.
        ops = []
        debug_string_ops = []

        for meta in dag_ir.node_metas_topological_order():
            if isinstance(meta, LoadNode) and getattr(meta, "is_output", False):
                assert meta.name == "accum"
                # Handle the special case where the accumulator is also being written out
                # This occurs in DAG IR as a load node with is_output = True
                ops.append((store, idx(accum_out_name), idx("accum")))
                debug_string_ops.append("accum_out_name.store(accum)")
                cur_idx += 1
            if isinstance(meta, LoadNode):
                # Add new values to the stack for any operations that need to be .load'ed.
                # This includes any non-scalar input parameters
                is_scalar = isinstance(meta.underlying_impl, ScalarBroadcastImpl)
                is_param_scalar = is_scalar and meta.name in parameter_names

                if meta.name != "accum" and not is_param_scalar:
                    if is_scalar:
                        ops.append((get_val(meta.tensor.value),))
                        add_name(meta.name)
                    else:
                        ops.append((load, idx(meta.name)))
                        debug_string_ops.append(f"{meta.name} = {meta.name}.load()")

                        # Update the entry in name_to_idx to the index of the loaded value
                        add_name(meta.name)
            elif isinstance(meta, StoreNode):
                children = dag_ir.get_all_inputs(meta.name)
                if len(children) != 1:
                    raise ValueError(
                        f"Store node {meta.name} has {len(children)} children, but only one is supported"
                    )
                child = children[0]
                ops.append((store, idx(meta.name), idx(child)))
                debug_string_ops.append(f"{meta.name}.store({child})")

                # We want to map the following sequence:
                #   def epi(accum, x, y):
                #     out0 = accum * x
                #     out1 = out0 * y
                #     return out0, out1
                # To:
                #   x_val = x.load()
                #   y_val = y.load()
                #   c0 = self.Acc() * x_val
                #   out0.store(c0)
                #   c1 = c0 * y_val
                #   out1.store(c1)
                # To support computation on top of out0, we need to remap it to c0 so that the next computation can use it.
                name_to_idx[meta.name] = child
                cur_idx += 1
            elif isinstance(meta, TopoVisitorNode):
                raise ValueError(f"TopoVisitorNode {meta.name} is not supported")
            else:
                if dag_ir.in_degree(meta.name) == 0:
                    continue

                sorted_children = [
                    idx(child_name) for child_name in dag_ir.get_all_inputs(meta.name)
                ]
                entry = (OpToCuteImpl[meta.fn], *sorted_children)
                ops.append(entry)
                debug_string_ops.append(
                    f"{meta.name} = {OpToCuteImplStr[meta.fn](*dag_ir.get_all_inputs(meta.name))}"
                )
                add_name(meta.name)

        def epi(efc_config, *parameters):
            stack = [efc_config.accum()]

            def get(idx: int):
                if idx < len(parameters):
                    return parameters[idx]
                else:
                    return stack[idx - len(parameters)]

            for i, op in enumerate(ops):
                fn = op[0]
                inputs = [get(idx) for idx in op[1:]]
                stack.append(fn(efc_config, *inputs))

        if accum_out_loc != -1:
            # Restore the original name of the accumulator
            parameter_names[accum_out_loc] = "accum"

        named_epi = common_efc.create_named_epilogue(["self", *parameter_names], epi)
        return named_epi

    @staticmethod
    def supports(dag_ir: DAGIR) -> Status:
        """
        Checks if the DAGIR is supported by CuTe DSL EFC.
        """
        # Currently do not support TopVisitorNode, row/col broadcasts, and reductions
        for meta in dag_ir.node_metas_topological_order():
            if isinstance(meta, TopoVisitorNode):
                return Status.fail("TopoVisitorNode is not supported")
            if isinstance(meta.underlying_impl, RowBroadcastImpl):
                return Status.fail("RowBroadcastImpl is not supported")
            if isinstance(meta.underlying_impl, ColumnBroadcastImpl):
                return Status.fail("ColumnBroadcastImpl is not supported")
            if isinstance(meta.underlying_impl, ReductionImplBase):
                return Status.fail("ReductionImplBase is not supported")
        return Status.success()

    @staticmethod
    def identity_efc(self, D):
        D.store(self.accum())
