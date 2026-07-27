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


from collections.abc import Callable

from cutlass.operators.fusion.ir import DAGIR, LoadNode, StoreNode, TopoVisitorNode
from cutlass.operators.fusion.ir.load_nodes import (
    ColumnBroadcastImpl,
    RowBroadcastImpl,
    ScalarBroadcastImpl,
)
from cutlass.operators.fusion.ir.store_nodes import ReductionImplBase
from cutlass.operators.fusion.library import ActivationOp, FunctionalOp
from cutlass.operators.providers.cutedsl.evt import common_efc
from cutlass.operators.status import Status

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
    ActivationOp.ReLU: lambda efc_config, x: efc_config.relu(x),
    ActivationOp.Sigmoid: lambda efc_config, x: efc_config.sigmoid(x),
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


def remap_and_load(source_mode_map):
    """Return a closure that applies remap_modes with the given source_mode_map, then loads.

    Calls ``Configuration.remap_modes()`` directly with a ``source_mode_map``
    tuple containing ``True`` for broadcast dimensions and integer indices for
    real source dimensions.  This bypasses the ``_RemapModesAccessor``
    subscript helper (which converts ``slice(None)`` → ``True``) since we
    already have the canonical ``source_mode_map`` form.
    """

    def _op(efc_config, x):
        return efc_config.remap_modes(source=x, source_mode_map=source_mode_map).load()

    return _op


def get_val(x):
    return lambda efc_config: x


# The SM100 EFC kernel permutes supplemental epilogue tensors from the
# user-facing (L, M, N) order to the kernel-internal (M, N, L) order.
# This must match the ``cute.select(t.layout, ...)`` call in
# ``sm100_static_persistent_efc_impl.py``.
_EPILOGUE_PERMUTATION = (1, 2, 0)  # (L, M, N) → (M, N, L)


def _build_source_mode_map(broadcast_stride, original_rank: int) -> tuple:
    """Build an EFC ``source_mode_map`` for ``handle_remapping``.

    The ``source_mode_map`` is in kernel ``(M, N, L)`` order (matching
    ``output_shape``) and each entry either:

    - ``True``: this target dimension is broadcast.
    - An integer *i*: this target dimension maps to source dimension *i*
      in the **original** (untouched) user tensor.

    Broadcast source tensors are passed to the kernel **as-is** — no
    ``add_batch_mode``, no permute, no squeeze.  ``remap_modes`` inside
    the kernel does all the layout work.

    The DAGIR broadcast stride is in ``(L, M, N)`` order.  The
    ``_EPILOGUE_PERMUTATION`` maps DAGIR positions to kernel target
    positions: target[t] corresponds to DAGIR dim
    ``_EPILOGUE_PERMUTATION[t]``.

    Within the user tensor, NumPy broadcasting prepends dims from the left.
    So the user's original dims occupy the **trailing** positions of the
    DAGIR stride.  The source dim index for a DAGIR position is its offset
    from the first original dim.

    Args:
        broadcast_stride: The tensor stride from the DAGIR, in user-facing
            ``(L, M, N)`` order after broadcast propagation.  May be an
            ``int`` for rank-1 tensors.
        original_rank: The rank of the user-provided tensor (before DAGIR
            broadcast propagation expanded it).

    Examples (target is always ``(M, N, L)`` order)::

        # (N,) orig_rank=1 → (True, 0, True)
        _build_source_mode_map((0, 0, 1), 1)

        # (1, N) orig_rank=2 → (True, 1, 0)
        _build_source_mode_map((0, 0, 1), 2)

        # (M, 1) orig_rank=2 → (0, 1, True)
        _build_source_mode_map((0, 1, 0), 2)

        # (L, M, 1) orig_rank=3 → (1, 2, 0)
        _build_source_mode_map((5, 1, 0), 3)
    """
    # Normalize: the DAGIR Layout stores stride as a plain int for rank 1.
    if isinstance(broadcast_stride, int):
        broadcast_stride = (broadcast_stride,)

    dagir_rank = len(broadcast_stride)
    n_prepended = dagir_rank - original_rank

    # Build source_mode_map in DAGIR (L, M, N) order.
    # - Prepended dims (don't exist in source) → True.
    # - Original dims with stride 0 (size-1 broadcast dims) → True.
    #   These dims exist in the source tensor but carry no data;
    #   using True forces stride 0 in the target, avoiding the
    #   non-zero stride that PyTorch assigns to size-1 dims.
    # - Original dims with non-zero stride → source dim index.
    lmn_map = []
    source_dim = 0
    for i in range(dagir_rank):
        if i < n_prepended:
            # Dimension prepended by broadcast propagation.
            lmn_map.append(True)
        elif broadcast_stride[i] == 0:
            # Original dim with stride 0 — size-1 broadcast dim.
            # Use True to force stride 0, skipping this source dim.
            lmn_map.append(True)
            source_dim += 1  # Skip past this source dim.
        else:
            # Original dim with real data.
            lmn_map.append(source_dim)
            source_dim += 1

    # Permute from DAGIR (L, M, N) to kernel (M, N, L) target order.
    return tuple(lmn_map[i] for i in _EPILOGUE_PERMUTATION)


class EFCConverter:
    """Helper class to translate from DAGIR to the CuTe DSL epilogue visitor tree (EVT) structure

    The CuTe DSL EVT structure is as follows for a (alpha * accum + beta * C) epilogue:
        def epi(efc_config, C, alpha, beta, D):
            C_val = C.load()
            alpha_val = alpha.load()
            beta_val = beta.load()
            compute_0_val = alpha_val * efc_config.accum()
            compute_1_val = beta_val * C_val
            compute_2_val = compute_0_val + compute_1_val
            D.store(compute_2_val)
    """

    @staticmethod
    def convert(
        dag_ir: DAGIR,
        parameter_names: list[str],
        parameter_tensors: dict | None = None,
    ) -> Callable:
        """Converts the DAGIR to a callable epilogue function supported by CuTe DSL EFC.

        :param parameter_tensors: Optional dict mapping parameter names to
            their original user-provided tensor/scalar values.  Used to
            determine the original rank of broadcast tensors.

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

        Example:
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
        # Track which parameters are broadcast sources.
        broadcast_source_names = set()

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
                # This includes any non-scalar input parameters.
                is_scalar = isinstance(meta.underlying_impl, ScalarBroadcastImpl)
                is_param_scalar = is_scalar and meta.name in parameter_names
                is_broadcast = isinstance(
                    meta.underlying_impl, (RowBroadcastImpl, ColumnBroadcastImpl)
                )

                if meta.name != "accum" and not is_param_scalar:
                    if is_scalar:
                        ops.append((get_val(meta.tensor.value),))
                        add_name(meta.name)
                    elif is_broadcast:
                        # For broadcast tensors, use remap_modes to expand
                        # the tensor to the full output shape before loading.
                        #
                        # Broadcast parameters are passed to the kernel
                        # untouched — no add_batch_mode, no permute, no
                        # squeeze.  remap_modes inside the kernel does all
                        # the layout work.
                        stride = meta.tensor.stride
                        if isinstance(stride, int):
                            stride = (stride,)
                        # Get original tensor rank to determine how many
                        # dims were prepended by broadcast propagation.
                        orig_rank = len(stride)  # fallback
                        if parameter_tensors and meta.name in parameter_tensors:
                            t = parameter_tensors[meta.name]
                            if hasattr(t, "ndim"):
                                orig_rank = t.ndim
                            elif hasattr(t, "shape"):
                                orig_rank = len(t.shape)
                        source_mode_map = _build_source_mode_map(stride, orig_rank)
                        broadcast_source_names.add(meta.name)
                        ops.append((remap_and_load(source_mode_map), idx(meta.name)))
                        debug_string_ops.append(
                            f"{meta.name} = {meta.name}"
                            f".remap_modes[{source_mode_map}].load()"
                        )
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
                #   c0 = efc_config.accum() * x_val
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

        named_epi = common_efc.create_named_epilogue(
            ["efc_config", *parameter_names], epi
        )
        # Attach metadata about which parameters are broadcast sources so the
        # kernel can squeeze them before entering the JIT context.
        named_epi._broadcast_source_names = broadcast_source_names
        return named_epi

    @staticmethod
    def supports(dag_ir: DAGIR) -> Status:
        """Checks if the DAGIR is supported by CuTe DSL EFC.
        """
        # Currently do not support TopVisitorNode and reductions.
        for meta in dag_ir.node_metas_topological_order():
            if isinstance(meta, TopoVisitorNode):
                return Status.fail("TopoVisitorNode is not supported")
            if isinstance(meta.underlying_impl, ReductionImplBase):
                return Status.fail("ReductionImplBase is not supported")
        return Status.success()

    @staticmethod
    def identity_efc(efc_config, D):
        D.store(efc_config.accum())
